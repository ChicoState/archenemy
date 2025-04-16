use pgvector::Vector;
use sqlx::{self, postgres::PgPool};
use uuid::Uuid;

use crate::types::Error;
use crate::user::types::{
    CreateUserRequest, TagCount, TagName, UpdateUserRequest, Url, User, UserDislike,
    UserDislikeTag, UserLike, UserTag, Wrapped,
};

type Result<T> = std::result::Result<T, Error>;

// User queries
pub async fn get_user_by_id(pool: &PgPool, id: &str) -> Result<Option<User>> {
    let user = sqlx::query_as!(User, r#"SELECT id, username, avatar_url as "avatar_url: Url", bio, display_name, embedding as "embedding: Vector", created_at, updated_at FROM Users WHERE id = $1"#, id)
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

    let result = sqlx::query_as!(
        User,
        r#"
        INSERT INTO Users (id, username, display_name, avatar_url, bio, embedding)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, username, avatar_url as "avatar_url: Url", bio, display_name, embedding as "embedding: Vector", created_at, updated_at
        "#,
        &user.id,
        &user.username,
        user.display_name.clone(),
        &avatar_url,
        &user.bio,
        &embedding as &Vector
    )
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
    let tags =
        sqlx::query!("SELECT tag_name, user_count FROM tag_counts ORDER BY user_count DESC",)
            .fetch_all(pool)
            .await?;

    let tags = tags
        .iter()
        .filter_map(|v| {
            if v.tag_name.is_none() {
                None
            } else {
                Some(TagCount {
                    tag_name: TagName::from(v.tag_name.clone().unwrap()),
                    user_count: v.user_count.unwrap_or(0),
                })
            }
        })
        .collect();

    Ok(tags)
}

// Get semantically opposite tags (nemesis tags) based on embedding similarity
pub async fn get_nemesis_tags(
    pool: &PgPool,
    tag_name: &str,
    limit: i64,
) -> Result<Vec<(String, f64)>> {
    // Get the embedding for the specified tag
    let tag_embedding = sqlx::query!(
        r#"
        SELECT embedding as "embedding: Vector" FROM Tags WHERE name = $1
        "#,
        tag_name
    )
    .fetch_optional(pool)
    .await?;

    // If the tag exists and has an embedding
    if let Some(embedding) = tag_embedding.and_then(|v| v.embedding) {
        // Create opposite embedding by negating each value
        let opposite_embedding: Vec<f32> = embedding.as_slice().iter().map(|&val| -val).collect();

        // Find opposite tags using cosine similarity with the negated embedding
        // The closer to 1.0, the more opposite the tag is semantically
        let results = sqlx::query!(
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
            Vector::from(opposite_embedding) as Vector,
            tag_name,
            limit
        )
        .fetch_all(pool)
        .await?;

        // Convert to (String, f32) tuples
        let nemesis_tags = results
            .into_iter()
            .map(|record| (record.name, record.nemesis_score.unwrap_or(f64::NAN)))
            .collect();

        return Ok(nemesis_tags);
    }

    // Tag doesn't exist or has no embedding
    Ok(Vec::new())
}

pub async fn get_user_tags(pool: &PgPool, user_id: &str) -> Result<Vec<UserTag>> {
    let tags = sqlx::query_as!(
        UserTag,
        "SELECT * FROM UserTags WHERE user_id = $1 ORDER BY created_at DESC",
        user_id
    )
    .fetch_all(pool)
    .await?;

    Ok(tags)
}

pub async fn add_user_tag(pool: &PgPool, user_id: &str, tag_name: &str) -> Result<UserTag> {
    // Generate tag embedding
    let tag_embedding = generate_tag_embedding(tag_name);

    // First ensure the tag exists in the Tags table with embedding
    sqlx::query!(
        r#"
        INSERT INTO Tags (name, embedding)
        VALUES ($1, $2)
        ON CONFLICT (name) DO UPDATE SET embedding = $2 WHERE Tags.embedding IS NULL
        "#,
        tag_name,
        tag_embedding as Vector
    )
    .execute(pool)
    .await?;

    // Then add the user-tag relationship
    let result = sqlx::query_as!(
        UserTag,
        r#"
        INSERT INTO UserTags (user_id, tag_name)
        VALUES ($1, $2)
        ON CONFLICT (user_id, tag_name) DO NOTHING
        RETURNING *
        "#,
        user_id,
        tag_name
    )
    .fetch_one(pool)
    .await?;

    // Refresh the materialized view
    sqlx::query!("REFRESH MATERIALIZED VIEW tag_counts")
        .execute(pool)
        .await?;

    // Update user's embedding after adding tag
    let _ = update_user_embedding(pool, user_id).await;

    Ok(result)
}

pub async fn remove_user_tag(pool: &PgPool, user_id: &str, names: &[String]) -> Result<()> {
    sqlx::query!(
        r#"
        DELETE FROM UserTags
        WHERE user_id = $1 AND tag_name = ANY($2)
        "#,
        user_id,
        names
    )
    .execute(pool)
    .await?;

    // Refresh the materialized view
    sqlx::query!("REFRESH MATERIALIZED VIEW tag_counts")
        .execute(pool)
        .await?;

    // Update user's embedding after tag change
    let _ = update_user_embedding(pool, user_id).await;

    Ok(())
}

// Relationship queries
pub async fn add_like(pool: &PgPool, user_id: &str, target_user_id: &str) -> Result<UserLike> {
    let result = sqlx::query_as!(
        UserLike,
        r#"
        INSERT INTO UserLikes (user_id, target_user_id)
        VALUES ($1, $2)
        ON CONFLICT (user_id, target_user_id) DO NOTHING
        RETURNING *
        "#,
        user_id,
        target_user_id
    )
    .fetch_one(pool)
    .await?;

    Ok(result)
}

pub async fn add_dislike(
    pool: &PgPool,
    user_id: &str,
    target_user_id: &str,
) -> Result<UserDislike> {
    let result = sqlx::query_as!(
        UserDislike,
        r#"
        INSERT INTO UserDislikes (user_id, target_user_id)
        VALUES ($1, $2)
        ON CONFLICT (user_id, target_user_id) DO NOTHING
        RETURNING *
        "#,
        user_id,
        target_user_id
    )
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
    sqlx::query!(
        r#"
        INSERT INTO Tags (name)
        VALUES ($1)
        ON CONFLICT (name) DO NOTHING
        "#,
        tag_name,
    )
    .execute(pool)
    .await?;

    // Then add the dislike tag
    let result = sqlx::query_as!(
        UserDislikeTag,
        r#"
        INSERT INTO UserDislikeTags (user_id, target_user_id, tag_name)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, target_user_id, tag_name) DO NOTHING
        RETURNING *
        "#,
        user_id,
        target_user_id,
        tag_name
    )
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
    let results = sqlx::query!(
        r#"
        SELECT u.id, u.username, u.display_name, u.avatar_url as "avatar_url: Url", u.bio, u.created_at, u.updated_at, u.embedding as "embedding: Vector", l.created_at as liked_at
        FROM Users u
        JOIN UserLikes l ON u.id = l.target_user_id
        WHERE l.user_id = $1
        ORDER BY l.created_at DESC
        LIMIT $2
        OFFSET $3
        "#,
        user_id,
        limit,
        offset,
    )
    .fetch_all(pool)
    .await?;

    Ok(results
        .into_iter()
        .map(|v| {
            (
                User {
                    id: v.id,
                    username: v.username,
                    display_name: v.display_name,
                    avatar_url: v.avatar_url,
                    bio: v.bio,
                    embedding: v.embedding,
                    created_at: v.created_at,
                    updated_at: v.updated_at,
                },
                v.liked_at,
            )
        })
        .collect())
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
    let results = sqlx::query!(
        r#"
        SELECT u.id, u.username, u.display_name, u.avatar_url as "avatar_url: Url", u.bio, u.created_at, u.updated_at, u.embedding as "embedding: Vector", d.created_at as disliked_at
        FROM Users u
        JOIN UserDislikes d ON u.id = d.target_user_id
        WHERE d.user_id = $1
        ORDER BY d.created_at DESC
        LIMIT $2
        OFFSET $3
        "#,
        user_id,
        limit,
        offset
    )
    .fetch_all(pool)
    .await?;

    Ok(results
        .into_iter()
        .map(|v| {
            (
                User {
                    id: v.id,
                    username: v.username,
                    display_name: v.display_name,
                    avatar_url: v.avatar_url,
                    bio: v.bio,
                    embedding: v.embedding,
                    created_at: v.created_at,
                    updated_at: v.updated_at,
                },
                v.disliked_at,
            )
        })
        .collect())
}

pub async fn get_dislike_tags(
    pool: &PgPool,
    user_id: &str,
    target_user_id: &str,
) -> Result<Vec<UserDislikeTag>> {
    let tags = sqlx::query_as!(
        UserDislikeTag,
        r#"
        SELECT *
        FROM UserDislikeTags
        WHERE user_id = $1 AND target_user_id = $2
        ORDER BY created_at DESC
        "#,
        user_id,
        target_user_id
    )
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
) -> Result<Vec<(User, f64)>> {
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

    let current_embedding = current_embedding.to_vec();

    // Create the opposite embedding for nemesis matching
    let opposite_embedding: Vec<f32> = current_embedding.iter().map(|&val| -val).collect();

    // Get the user's tags
    let user_tags = get_user_tags(pool, user_id).await?;

    // Get tag embeddings for the user's tags
    let mut tag_embeddings = Vec::new();
    for tag in &user_tags {
        let tag_embedding = sqlx::query!(
            r#"SELECT embedding as "embedding: Vector" FROM Tags WHERE name = $1"#,
            &tag.tag_name
        )
        .fetch_one(pool)
        .await?;

        if let Some(embedding) = tag_embedding.embedding {
            tag_embeddings.push(embedding);
        }
    }

    // This query finds users based on user embedding similarity, tag embedding similarity, and tag overlap
    // Higher score = better nemesis match (more opposite)
    let results = sqlx::query_file!(
        "src/query/find_nemesis.sql",
        user_id,
        limit,
        offset,
        Vector::from(opposite_embedding) as Vector
    )
    .fetch_all(pool)
    .await?;

    Ok(results
        .into_iter()
        .map(|v| {
            (
                User {
                    id: v.id,
                    username: v.username,
                    display_name: v.display_name,
                    avatar_url: v.avatar_url,
                    bio: v.bio,
                    embedding: v.embedding,
                    created_at: v.created_at,
                    updated_at: v.updated_at,
                },
                v.compatibility_score.unwrap_or(0.0),
            )
        })
        .collect())
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
pub fn generate_random_embedding() -> Vector {
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
        Vector::from(
            random_values
                .iter()
                .map(|&val| val / magnitude)
                .collect::<Vec<_>>(),
        )
    } else {
        // Fallback in case of zero magnitude (shouldn't happen with random values)
        Vector::from(random_values)
    }
}

// Generate a tag embedding based on the tag name
// In a real implementation, this would use a text embedding model
pub fn generate_tag_embedding(tag_name: &str) -> Vector {
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
        Vector::from(
            random_values
                .iter()
                .map(|&val| val / magnitude)
                .collect::<Vec<_>>(),
        )
    } else {
        Vector::from(random_values)
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
            let tag_embedding = sqlx::query_as::<_, (Option<Vector>,)>(
                "SELECT embedding FROM Tags WHERE name = $1",
            )
            .bind(&tag.tag_name)
            .fetch_one(pool)
            .await?;

            if let (Some(embedding),) = tag_embedding {
                tag_embeddings.push(embedding.to_vec());
            } else {
                // If tag doesn't have an embedding, generate one
                let generated = generate_tag_embedding(&tag.tag_name);
                tag_embeddings.push(generated.to_vec());

                // Update tag with embedding
                sqlx::query!(
                    "UPDATE Tags SET embedding = $1 WHERE name = $2",
                    &generated as &Vector,
                    &tag.tag_name
                )
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
            Vector::from(
                avg_embedding
                    .iter()
                    .map(|&val| val / magnitude)
                    .collect::<Vec<_>>(),
            )
        } else {
            Vector::from(avg_embedding)
        }
    };

    // Update the user's embedding in the database
    sqlx::query!(
        r#"
        UPDATE Users 
        SET embedding = $1, updated_at = NOW()
        WHERE id = $2
        "#,
        &embedding as &Vector,
        user_id
    )
    .execute(pool)
    .await?;

    Ok(())
}
