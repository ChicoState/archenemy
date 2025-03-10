use crate::user::types::Url;
use crate::user::types::Wrapped;
use sqlx::{self, postgres::PgPool};
use uuid::Uuid;

use crate::types::Error;
use crate::user::types::{
    CreateUserRequest, TagCount, UpdateUserRequest, User, UserDislike, UserDislikeTag, UserLike,
    UserTag,
};

type Result<T> = std::result::Result<T, Error>;

// User queries
pub async fn get_user_by_id(pool: &PgPool, id: &str) -> Result<Option<User>> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM Users WHERE id = $1")
        .bind(id)
        .fetch_optional(pool)
        .await?;

    Ok(user)
}

pub async fn create_user(pool: &PgPool, user: &CreateUserRequest) -> Result<User> {
    let avatar_url = user.avatar_url.clone().unwrap_or(Url::raw(
        "https://archenemy.nyc3.digitaloceanspaces.com/default.jpeg".to_string(),
    ));

    // Generate a random embedding for the user
    let embedding = generate_random_embedding();

    let result = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO Users (id, username, display_name, avatar_url, bio, embedding)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
        "#,
    )
    .bind(&user.id)
    .bind(&user.username)
    .bind(&user.display_name)
    .bind(&avatar_url)
    .bind(&user.bio)
    .bind(&embedding)
    .fetch_one(pool)
    .await?;

    Ok(result)
}

pub async fn update_user(pool: &PgPool, id: &str, update: &UpdateUserRequest) -> Result<User> {
    use sqlx::QueryBuilder;

    let mut builder: QueryBuilder<sqlx::Postgres> =
        QueryBuilder::new("UPDATE Users SET updated_at = NOW()");

    if let Some(ref username) = update.username {
        builder.push(", username = ").push_bind(username);
    }

    if let Some(ref display_name) = update.display_name {
        builder.push(", display_name = ").push_bind(display_name);
    }

    if let Some(ref avatar_url) = update.avatar_url {
        builder.push(", avatar_url = ").push_bind(avatar_url);
    }

    if let Some(ref bio) = update.bio {
        builder.push(", bio = ").push_bind(bio);
    }

    builder.push(" WHERE id = ");
    builder.push_bind(id);
    builder.push(" RETURNING *");

    let query = builder.build_query_as();
    let result = query.fetch_one(pool).await?;

    // Update user's embedding after profile changes
    let _ = update_user_embedding(pool, id).await;

    Ok(result)
}

// Tag queries
pub async fn get_all_tags(pool: &PgPool) -> Result<Vec<TagCount>> {
    let tags = sqlx::query_as::<_, TagCount>(
        "SELECT tag_name, user_count FROM tag_counts ORDER BY user_count DESC",
    )
    .fetch_all(pool)
    .await?;

    Ok(tags)
}

// Get semantically opposite tags (nemesis tags) based on embedding similarity
pub async fn get_nemesis_tags(
    pool: &PgPool,
    tag_name: &str,
    limit: i64,
) -> Result<Vec<(String, f32)>> {
    // Get the embedding for the specified tag
    let tag_embedding = sqlx::query_as::<_, (Vec<f32>,)>(
        r#"
        SELECT embedding FROM Tags WHERE name = $1
        "#,
    )
    .bind(tag_name)
    .fetch_optional(pool)
    .await?;

    // If the tag exists and has an embedding
    if let Some((embedding,)) = tag_embedding {
        // Create opposite embedding by negating each value
        let opposite_embedding: Vec<f32> = embedding.iter().map(|&val| -val).collect();

        // Find opposite tags using cosine similarity with the negated embedding
        // The closer to 1.0, the more opposite the tag is semantically
        let results = sqlx::query_as::<_, (String, f32)>(
            r#"
                SELECT 
                    name, 
                    embedding <=> $1 as nemesis_score
                FROM 
                    Tags
                WHERE 
                    name != $2 AND embedding IS NOT NULL
                ORDER BY 
                    embedding <=> $1
                LIMIT $3
                "#,
        )
        .bind(&opposite_embedding as &[f32])
        .bind(tag_name)
        .bind(limit)
        .fetch_all(pool)
        .await?;

        // Convert to (String, f32) tuples
        let nemesis_tags = results
            .into_iter()
            .map(|record| (record.0, record.1))
            .collect();

        return Ok(nemesis_tags);
    }

    // Tag doesn't exist or has no embedding
    Ok(Vec::new())
}

pub async fn get_user_tags(pool: &PgPool, user_id: &str) -> Result<Vec<UserTag>> {
    let tags = sqlx::query_as::<_, UserTag>(
        "SELECT * FROM UserTags WHERE user_id = $1 ORDER BY created_at DESC",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await?;

    Ok(tags)
}

pub async fn add_user_tag(pool: &PgPool, user_id: &str, tag_name: &str) -> Result<UserTag> {
    // Generate tag embedding
    let tag_embedding = generate_tag_embedding(tag_name);

    // First ensure the tag exists in the Tags table with embedding
    sqlx::query(
        r#"
        INSERT INTO Tags (name, embedding)
        VALUES ($1, $2)
        ON CONFLICT (name) DO UPDATE SET embedding = $2 WHERE Tags.embedding IS NULL
        "#,
    )
    .bind(tag_name)
    .bind(&tag_embedding)
    .execute(pool)
    .await?;

    // Then add the user-tag relationship
    let result = sqlx::query_as::<_, UserTag>(
        r#"
        INSERT INTO UserTags (user_id, tag_name)
        VALUES ($1, $2)
        ON CONFLICT (user_id, tag_name) DO NOTHING
        RETURNING *
        "#,
    )
    .bind(user_id)
    .bind(tag_name)
    .fetch_one(pool)
    .await?;

    // Refresh the materialized view
    sqlx::query("REFRESH MATERIALIZED VIEW tag_counts")
        .execute(pool)
        .await?;

    // Update user's embedding after adding tag
    let _ = update_user_embedding(pool, user_id).await;

    Ok(result)
}

pub async fn remove_user_tag(pool: &PgPool, user_id: &str, tag_name: &str) -> Result<()> {
    sqlx::query(
        r#"
        DELETE FROM UserTags
        WHERE user_id = $1 AND tag_name = $2
        "#,
    )
    .bind(user_id)
    .bind(tag_name)
    .execute(pool)
    .await?;

    // Refresh the materialized view
    sqlx::query("REFRESH MATERIALIZED VIEW tag_counts")
        .execute(pool)
        .await?;

    // Update user's embedding after tag change
    let _ = update_user_embedding(pool, user_id).await;

    Ok(())
}

// Relationship queries
pub async fn add_like(pool: &PgPool, user_id: &str, target_user_id: &str) -> Result<UserLike> {
    let result = sqlx::query_as::<_, UserLike>(
        r#"
        INSERT INTO UserLikes (user_id, target_user_id)
        VALUES ($1, $2)
        ON CONFLICT (user_id, target_user_id) DO NOTHING
        RETURNING *
        "#,
    )
    .bind(user_id)
    .bind(target_user_id)
    .fetch_one(pool)
    .await?;

    Ok(result)
}

pub async fn add_dislike(
    pool: &PgPool,
    user_id: &str,
    target_user_id: &str,
) -> Result<UserDislike> {
    let result = sqlx::query_as::<_, UserDislike>(
        r#"
        INSERT INTO UserDislikes (user_id, target_user_id)
        VALUES ($1, $2)
        ON CONFLICT (user_id, target_user_id) DO NOTHING
        RETURNING *
        "#,
    )
    .bind(user_id)
    .bind(target_user_id)
    .fetch_one(pool)
    .await?;

    Ok(result)
}

pub async fn add_dislike_tag(
    pool: &PgPool,
    user_id: &str,
    target_user_id: &str,
    tag_name: &str,
) -> Result<UserDislikeTag> {
    // First ensure the tag exists in the Tags table
    sqlx::query(
        r#"
        INSERT INTO Tags (name)
        VALUES ($1)
        ON CONFLICT (name) DO NOTHING
        "#,
    )
    .bind(tag_name)
    .execute(pool)
    .await?;

    // Then add the dislike tag
    let result = sqlx::query_as::<_, UserDislikeTag>(
        r#"
        INSERT INTO UserDislikeTags (user_id, target_user_id, tag_name)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, target_user_id, tag_name) DO NOTHING
        RETURNING *
        "#,
    )
    .bind(user_id)
    .bind(target_user_id)
    .bind(tag_name)
    .fetch_one(pool)
    .await?;

    Ok(result)
}

pub async fn get_liked_users(
    pool: &PgPool,
    user_id: &str,
    limit: i64,
    offset: i64,
) -> Result<
    Vec<(
        User,
        sqlx::types::chrono::DateTime<sqlx::types::chrono::Utc>,
    )>,
> {
    let results = sqlx::query_as::<
        _,
        (
            User,
            sqlx::types::chrono::DateTime<sqlx::types::chrono::Utc>,
        ),
    >(
        r#"
        SELECT u.*, l.created_at as liked_at
        FROM Users u
        JOIN UserLikes l ON u.id = l.target_user_id
        WHERE l.user_id = $1
        ORDER BY l.created_at DESC
        LIMIT $2
        OFFSET $3
        "#,
    )
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await?;

    Ok(results)
}

pub async fn get_disliked_users(
    pool: &PgPool,
    user_id: &str,
    limit: i64,
    offset: i64,
) -> Result<
    Vec<(
        User,
        sqlx::types::chrono::DateTime<sqlx::types::chrono::Utc>,
    )>,
> {
    let results = sqlx::query_as::<
        _,
        (
            User,
            sqlx::types::chrono::DateTime<sqlx::types::chrono::Utc>,
        ),
    >(
        r#"
        SELECT u.*, d.created_at as disliked_at
        FROM Users u
        JOIN UserDislikes d ON u.id = d.target_user_id
        WHERE d.user_id = $1
        ORDER BY d.created_at DESC
        LIMIT $2
        OFFSET $3
        "#,
    )
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await?;

    Ok(results)
}

pub async fn get_dislike_tags(
    pool: &PgPool,
    user_id: &str,
    target_user_id: &str,
) -> Result<Vec<UserDislikeTag>> {
    let tags = sqlx::query_as::<_, UserDislikeTag>(
        r#"
        SELECT *
        FROM UserDislikeTags
        WHERE user_id = $1 AND target_user_id = $2
        ORDER BY created_at DESC
        "#,
    )
    .bind(user_id)
    .bind(target_user_id)
    .fetch_all(pool)
    .await?;

    Ok(tags)
}

// Discovery queries
pub async fn get_potential_nemeses(
    pool: &PgPool,
    user_id: &str,
    limit: i64,
    offset: i64,
) -> Result<Vec<(User, f32)>> {
    // First, get the current user's embedding
    let current_user = get_user_by_id(pool, user_id)
        .await?
        .ok_or_else(|| Error::NotFound {
            resource: format!("User with ID {}", user_id),
        })?;

    // If the user doesn't have an embedding, generate one
    let current_embedding = match current_user.embedding {
        Some(embed) => embed,
        None => {
            // Generate and update embedding
            let embedding = generate_random_embedding();
            update_user_embedding(pool, user_id).await?;
            embedding
        }
    };

    // Create the opposite embedding for nemesis matching
    let opposite_embedding: Vec<f32> = current_embedding.iter().map(|&val| -val).collect();

    // Get the user's tags
    let user_tags = get_user_tags(pool, user_id).await?;
    
    // Get tag embeddings for the user's tags
    let mut tag_embeddings = Vec::new();
    for tag in &user_tags {
        let tag_embedding = sqlx::query_as::<_, (Option<Vec<f32>>,)>(
            "SELECT embedding FROM Tags WHERE name = $1"
        )
        .bind(&tag.tag_name)
        .fetch_one(pool)
        .await?;
        
        if let (Some(embedding),) = tag_embedding {
            tag_embeddings.push(embedding);
        }
    }

    // This query finds users based on user embedding similarity, tag embedding similarity, and tag overlap
    // Higher score = better nemesis match (more opposite)
    let results = sqlx::query_as::<_, (User, f32)>(
        r#"
        WITH user_tags AS (
            SELECT tag_name FROM UserTags WHERE user_id = $1
        ),
        user_likes AS (
            SELECT target_user_id FROM UserLikes WHERE user_id = $1
        ),
        user_dislikes AS (
            SELECT target_user_id FROM UserDislikes WHERE user_id = $1
        ),
        -- Get user's tags with embeddings
        user_tag_embeddings AS (
            SELECT t.name, t.embedding
            FROM Tags t
            JOIN UserTags ut ON t.name = ut.tag_name
            WHERE ut.user_id = $1 AND t.embedding IS NOT NULL
        ),
        -- Get potential nemesis users' tags with embeddings
        nemesis_tag_embeddings AS (
            SELECT ut.user_id, t.name, t.embedding
            FROM Tags t
            JOIN UserTags ut ON t.name = ut.tag_name
            WHERE ut.user_id != $1 
              AND ut.user_id NOT IN (SELECT target_user_id FROM user_likes)
              AND ut.user_id NOT IN (SELECT target_user_id FROM user_dislikes)
              AND t.embedding IS NOT NULL
        ),
        -- Calculate tag embedding similarity scores for each potential nemesis
        tag_similarity_scores AS (
            SELECT 
                nte.user_id,
                -- For each user, calculate average similarity between their tags and opposite of user's tags
                -- Higher score = more opposite tags (better nemesis match)
                AVG(
                    CASE 
                        WHEN ute.embedding IS NOT NULL AND nte.embedding IS NOT NULL THEN
                            -- Invert user tag embedding for opposite comparison
                            -- Scale to 0-1 range where 1 = perfect opposite
                            (1 - ((ute.embedding <=> nte.embedding) / 2))
                        ELSE 0.5
                    END
                ) AS tag_embedding_score
            FROM 
                nemesis_tag_embeddings nte
            CROSS JOIN 
                user_tag_embeddings ute
            GROUP BY 
                nte.user_id
        ),
        -- Calculate combined score based on embedding similarity and tag overlap
        user_scores AS (
            SELECT 
                u.id,
                (
                    -- 1. User embedding similarity component (50%)
                    -- Higher score = better nemesis match (more opposite)
                    CASE
                        WHEN u.embedding IS NOT NULL THEN 
                            -- Compare with negative embedding to find semantic opposites
                            -- Scale to 0-1 range where 1 = perfect nemesis
                            (1 - (u.embedding <=> $4::vector) / 2)
                        ELSE 0.5 -- Default middle value if no embedding
                    END * 0.5 -- 50% weight for user embedding
                    
                    +
                    
                    -- 2. Tag embedding similarity component (30%)
                    -- Use the tag similarity scores calculated above
                    COALESCE((
                        SELECT tag_embedding_score 
                        FROM tag_similarity_scores 
                        WHERE user_id = u.id
                    ), 0.5) * 0.3 -- 30% weight for tag embeddings
                    
                    +
                    
                    -- 3. Tag overlap component (20%)
                    -- Lower = more overlap, we want the opposite
                    -- Count percentage of non-matching tags
                    (1 - COALESCE((
                        SELECT COUNT(*)::float 
                        FROM UserTags ut
                        WHERE ut.user_id = u.id AND ut.tag_name IN (SELECT tag_name FROM user_tags)
                    ), 0) / 
                    NULLIF((
                        SELECT COUNT(*)::float 
                        FROM UserTags 
                        WHERE user_id = u.id
                    ), 1)) * 0.2 -- 20% weight for tag name overlap
                ) AS nemesis_score
            FROM 
                Users u
            WHERE 
                u.id != $1
                AND u.id NOT IN (SELECT target_user_id FROM user_likes)
                AND u.id NOT IN (SELECT target_user_id FROM user_dislikes)
        )
        
        SELECT 
            u.*, 
            COALESCE(us.nemesis_score, 0.5) AS compatibility_score
        FROM 
            Users u
        LEFT JOIN 
            user_scores us ON u.id = us.id
        WHERE 
            u.id != $1
            AND u.id NOT IN (SELECT target_user_id FROM user_likes)
            AND u.id NOT IN (SELECT target_user_id FROM user_dislikes)
        ORDER BY 
            -- Order by nemesis score (highest first = most incompatible)
            compatibility_score DESC
        LIMIT $2
        OFFSET $3
        "#,
    )
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .bind(&opposite_embedding)  // Using opposite embedding for nemesis matching
    .fetch_all(pool)
    .await?;

    Ok(results)
}

// Helper functions
pub fn generate_random_username() -> String {
    let uuid = Uuid::new_v4();
    format!("user_{}", uuid.simple())
}

// Constants
const EMBEDDING_DIM: usize = 384;

// Generate a random embedding vector for MVP purposes
// This simulates a 384-dimensional embedding from all-MiniLM-L6-v2
pub fn generate_random_embedding() -> Vec<f32> {
    use rand::Rng;
    let mut rng = rand::rng();

    // Create a 384-dimensional embedding vector with random values between -1.0 and 1.0
    // This must match the dimension in the database (vector(384))

    // Generate random values and normalize to unit vector (required for cosine similarity)
    let random_values: Vec<f32> = (0..EMBEDDING_DIM)
        .map(|_| rng.random_range(-1.0..1.0))
        .collect();

    // Calculate the magnitude of the vector
    let magnitude: f32 = random_values
        .iter()
        .map(|&val| val * val)
        .sum::<f32>()
        .sqrt();

    // Normalize the vector (divide each element by the magnitude)
    if magnitude > 0.0 {
        random_values.iter().map(|&val| val / magnitude).collect()
    } else {
        // Fallback in case of zero magnitude (shouldn't happen with random values)
        random_values
    }
}

// Generate a tag embedding based on the tag name
// In a real implementation, this would use a text embedding model
pub fn generate_tag_embedding(tag_name: &str) -> Vec<f32> {
    use rand::rngs::StdRng;
    use rand::{Rng, SeedableRng};
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};

    // Create a deterministic seed from the tag name so the same tag
    // always gets the same embedding (this is important for consistency)
    let mut hasher = DefaultHasher::new();
    tag_name.hash(&mut hasher);
    let seed = hasher.finish();

    // Create a deterministic random number generator
    let mut rng = StdRng::seed_from_u64(seed);

    // Generate deterministic random values
    let random_values: Vec<f32> = (0..EMBEDDING_DIM)
        .map(|_| rng.random_range(-1.0..1.0))
        .collect();

    // Normalize the vector
    let magnitude: f32 = random_values
        .iter()
        .map(|&val| val * val)
        .sum::<f32>()
        .sqrt();

    if magnitude > 0.0 {
        random_values.iter().map(|&val| val / magnitude).collect()
    } else {
        random_values
    }
}

// Update a user's embedding
// This creates an embedding based on the user's tags
pub async fn update_user_embedding(pool: &PgPool, user_id: &str) -> Result<()> {
    // Get all of the user's tags
    let user_tags = get_user_tags(pool, user_id).await?;

    let embedding = if user_tags.is_empty() {
        // If user has no tags, use a random embedding
        generate_random_embedding()
    } else {
        // Get tag embeddings
        let mut tag_embeddings = Vec::new();

        for tag in &user_tags {
            // Get or generate tag embedding
            let tag_embedding = sqlx::query_as::<_, (Option<Vec<f32>>,)>(
                "SELECT embedding FROM Tags WHERE name = $1",
            )
            .bind(&tag.tag_name)
            .fetch_one(pool)
            .await?;

            if let (Some(embedding),) = tag_embedding {
                tag_embeddings.push(embedding);
            } else {
                // If tag doesn't have an embedding, generate one
                let generated = generate_tag_embedding(&tag.tag_name);
                tag_embeddings.push(generated.clone());

                // Update tag with embedding
                sqlx::query("UPDATE Tags SET embedding = $1 WHERE name = $2")
                    .bind(&generated)
                    .bind(&tag.tag_name)
                    .execute(pool)
                    .await?;
            }
        }

        // Average the tag embeddings
        let mut avg_embedding = vec![0.0; EMBEDDING_DIM];
        for tag_embedding in &tag_embeddings {
            for (i, &val) in tag_embedding.iter().enumerate() {
                avg_embedding[i] += val / tag_embeddings.len() as f32;
            }
        }

        // Normalize the embedding
        let magnitude: f32 = avg_embedding
            .iter()
            .map(|&val| val * val)
            .sum::<f32>()
            .sqrt();

        if magnitude > 0.0 {
            avg_embedding.iter().map(|&val| val / magnitude).collect()
        } else {
            avg_embedding
        }
    };

    // Update the user's embedding in the database
    sqlx::query(
        r#"
        UPDATE Users 
        SET embedding = $1, updated_at = NOW()
        WHERE id = $2
        "#,
    )
    .bind(&embedding)
    .bind(user_id)
    .execute(pool)
    .await?;

    Ok(())
}
