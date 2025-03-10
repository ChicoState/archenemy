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
    let avatar_url = user.avatar_url.clone().unwrap_or(
        Url::raw("https://archenemy.nyc3.digitaloceanspaces.com/default.jpeg".to_string())
    );
    
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
    // This query finds users with the least tag overlap and who aren't already liked/disliked
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
        tag_match_scores AS (
            SELECT 
                u.id,
                (
                    -- Calculate a compatibility score where lower means more incompatible
                    -- Count the number of matching tags (negative impact on score)
                    -COALESCE((
                        SELECT COUNT(*)::float 
                        FROM UserTags ut
                        WHERE ut.user_id = u.id AND ut.tag_name IN (SELECT tag_name FROM user_tags)
                    ), 0) / 
                    -- Normalize by total tags
                    NULLIF((
                        SELECT COUNT(*)::float 
                        FROM UserTags 
                        WHERE user_id = u.id
                    ), 0)
                ) AS compatibility_score
            FROM 
                Users u
            WHERE 
                u.id != $1
                AND u.id NOT IN (SELECT target_user_id FROM user_likes)
                AND u.id NOT IN (SELECT target_user_id FROM user_dislikes)
        )
        SELECT 
            u.*, 
            COALESCE(tms.compatibility_score, 0) AS compatibility_score
        FROM 
            Users u
        LEFT JOIN 
            tag_match_scores tms ON u.id = tms.id
        WHERE 
            u.id != $1
            AND u.id NOT IN (SELECT target_user_id FROM user_likes)
            AND u.id NOT IN (SELECT target_user_id FROM user_dislikes)
        ORDER BY 
            -- Order by compatibility score (lowest first = most incompatible)
            compatibility_score ASC
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

// Helper functions
pub fn generate_random_username() -> String {
    let uuid = Uuid::new_v4();
    format!("user_{}", uuid.simple())
}

// Generate a random embedding vector for MVP purposes
// This simulates a 384-dimensional embedding from all-MiniLM-L6-v2
pub fn generate_random_embedding() -> Vec<f32> {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    
    // Create a 384-dimensional embedding vector with random values between -1.0 and 1.0
    const EMBEDDING_DIM: usize = 384;
    (0..EMBEDDING_DIM).map(|_| rng.gen_range(-1.0..1.0)).collect()
}

// Update a user's embedding
// For MVP purposes this just generates a new random embedding
// In a production app, this would use the user's profile data and tags
// to generate a more meaningful embedding
pub async fn update_user_embedding(pool: &PgPool, user_id: &str) -> Result<()> {
    // Generate a new random embedding
    let embedding = generate_random_embedding();
    
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
