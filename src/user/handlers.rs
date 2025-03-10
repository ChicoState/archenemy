use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use firebase_auth::FirebaseUser;
use serde::{Deserialize, Serialize};
use sqlx::types::chrono::{DateTime, Utc};

use crate::types::{ArchenemyState, Error};
use crate::user::types::{
    CreateUserRequest, TagCount, UpdateUserRequest, User, UserDislike, UserDislikeTag, UserLike,
    UserTag,
};
use crate::user::utils;

// Query parameter structs
#[derive(Debug, Deserialize)]
pub struct PaginationParams {
    limit: Option<i64>,
    offset: Option<i64>,
}

// Response structs
#[derive(Debug, Serialize)]
pub struct UserWithTags {
    #[serde(flatten)]
    user: User,
    tags: Vec<UserTag>,
    compatibility_score: Option<f32>,
}

#[derive(Debug, Serialize)]
pub struct UserWithLikedAt {
    #[serde(flatten)]
    user: User,
    liked_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct UserWithDislikedAt {
    #[serde(flatten)]
    user: User,
    disliked_at: DateTime<Utc>,
    dislike_tags: Vec<UserDislikeTag>,
}

#[derive(Debug, Deserialize)]
pub struct AddTagRequest {
    tag_name: String,
}

#[derive(Debug, Deserialize)]
pub struct AddTagsRequest {
    tag_names: Vec<String>,
}

// User Handlers
#[axum::debug_handler]
pub async fn get_current_user(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
) -> Result<Json<User>, Error> {
    let user_id = user.user_id;

    // Try to get the user
    let maybe_user = utils::get_user_by_id(&state.pool, &user_id).await?;

    // If user doesn't exist, create one
    let user = match maybe_user {
        Some(user) => user,
        None => {
            // Create a new user with defaults
            let random_username = utils::generate_random_username();
            let create_request = CreateUserRequest {
                id: user_id.clone(),
                username: random_username,
                display_name: None,
                avatar_url: None,
                bio: "".to_string(),
            };

            utils::create_user(&state.pool, &create_request).await?
        }
    };

    Ok(Json(user))
}

pub async fn get_user(
    State(state): State<ArchenemyState>,
    Path(user_id): Path<String>,
    _user: FirebaseUser, // Ensure authenticated
) -> Result<Json<User>, Error> {
    let maybe_user = utils::get_user_by_id(&state.pool, &user_id).await?;

    let user = maybe_user.ok_or_else(|| Error::NotFound {
        resource: format!("User with ID {}", user_id),
    })?;

    Ok(Json(user))
}

pub async fn update_current_user(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Json(update): Json<UpdateUserRequest>,
) -> Result<Json<User>, Error> {
    let user_id = user.user_id;

    // Validate input
    if let Some(ref username) = update.username {
        if username.is_empty() {
            return Err(Error::Validation {
                field: "username".to_string(),
                message: "Username cannot be empty".to_string(),
            });
        }
    }

    let updated_user = utils::update_user(&state.pool, &user_id, &update).await?;

    Ok(Json(updated_user))
}

// Tag Handlers
pub async fn get_all_tags(
    State(state): State<ArchenemyState>,
    _user: FirebaseUser, // Ensure authenticated
) -> Result<Json<Vec<TagCount>>, Error> {
    let tags = utils::get_all_tags(&state.pool).await?;
    Ok(Json(tags))
}

pub async fn get_user_tags(
    State(state): State<ArchenemyState>,
    Path(user_id): Path<String>,
    _user: FirebaseUser, // Ensure authenticated
) -> Result<Json<Vec<UserTag>>, Error> {
    // Verify user exists
    let maybe_user = utils::get_user_by_id(&state.pool, &user_id).await?;
    if maybe_user.is_none() {
        return Err(Error::NotFound {
            resource: format!("User with ID {}", user_id),
        });
    }

    let tags = utils::get_user_tags(&state.pool, &user_id).await?;
    Ok(Json(tags))
}

pub async fn add_user_tag(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Json(request): Json<AddTagRequest>,
) -> Result<Json<UserTag>, Error> {
    let user_id = user.user_id;

    // Validate tag name
    if request.tag_name.is_empty() {
        return Err(Error::Validation {
            field: "tag_name".to_string(),
            message: "Tag name cannot be empty".to_string(),
        });
    }

    let tag = utils::add_user_tag(&state.pool, &user_id, &request.tag_name).await?;
    Ok(Json(tag))
}

pub async fn remove_user_tag(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Path(tag_name): Path<String>,
) -> Result<StatusCode, Error> {
    let user_id = user.user_id;

    utils::remove_user_tag(&state.pool, &user_id, &tag_name).await?;
    Ok(StatusCode::NO_CONTENT)
}

// Enemy Handlers
pub async fn get_potential_enemies(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Query(pagination): Query<PaginationParams>,
) -> Result<Json<Vec<UserWithTags>>, Error> {
    let user_id = user.user_id;
    let limit = pagination.limit.unwrap_or(10);
    let offset = pagination.offset.unwrap_or(0);

    let potential_enemies =
        utils::get_potential_enemies(&state.pool, &user_id, limit, offset).await?;

    // For each potential enemy, get their tags
    let mut result = Vec::new();
    for (user, score) in potential_enemies {
        let tags = utils::get_user_tags(&state.pool, &user.id).await?;

        result.push(UserWithTags {
            user,
            tags,
            compatibility_score: Some(score),
        });
    }

    Ok(Json(result))
}

pub async fn like_user(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Path(target_user_id): Path<String>,
) -> Result<Json<UserLike>, Error> {
    let user_id = user.user_id;

    // Verify target user exists
    let maybe_target = utils::get_user_by_id(&state.pool, &target_user_id).await?;
    if maybe_target.is_none() {
        return Err(Error::NotFound {
            resource: format!("User with ID {}", target_user_id),
        });
    }

    // Prevent liking oneself
    if user_id == target_user_id {
        return Err(Error::Validation {
            field: "target_user_id".to_string(),
            message: "Cannot like yourself".to_string(),
        });
    }

    let like = utils::add_like(&state.pool, &user_id, &target_user_id).await?;
    Ok(Json(like))
}

pub async fn dislike_user(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Path(target_user_id): Path<String>,
) -> Result<Json<UserDislike>, Error> {
    let user_id = user.user_id;

    // Verify target user exists
    let maybe_target = utils::get_user_by_id(&state.pool, &target_user_id).await?;
    if maybe_target.is_none() {
        return Err(Error::NotFound {
            resource: format!("User with ID {}", target_user_id),
        });
    }

    // Prevent disliking oneself
    if user_id == target_user_id {
        return Err(Error::Validation {
            field: "target_user_id".to_string(),
            message: "Cannot dislike yourself".to_string(),
        });
    }

    let dislike = utils::add_dislike(&state.pool, &user_id, &target_user_id).await?;
    Ok(Json(dislike))
}

pub async fn dislike_user_with_tags(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Path(target_user_id): Path<String>,
    Json(request): Json<AddTagsRequest>,
) -> Result<Json<Vec<UserDislikeTag>>, Error> {
    let user_id = user.user_id;

    // Verify target user exists
    let maybe_target = utils::get_user_by_id(&state.pool, &target_user_id).await?;
    if maybe_target.is_none() {
        return Err(Error::NotFound {
            resource: format!("User with ID {}", target_user_id),
        });
    }

    // Prevent disliking oneself
    if user_id == target_user_id {
        return Err(Error::Validation {
            field: "target_user_id".to_string(),
            message: "Cannot dislike yourself".to_string(),
        });
    }

    // Add a dislike record first (if it doesn't already exist)
    let _ = utils::add_dislike(&state.pool, &user_id, &target_user_id).await?;

    // Add dislike tags
    let mut dislike_tags = Vec::new();
    for tag_name in request.tag_names {
        if !tag_name.is_empty() {
            let tag =
                utils::add_dislike_tag(&state.pool, &user_id, &target_user_id, &tag_name).await?;
            dislike_tags.push(tag);
        }
    }

    Ok(Json(dislike_tags))
}

pub async fn get_liked_users(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Query(pagination): Query<PaginationParams>,
) -> Result<Json<Vec<UserWithLikedAt>>, Error> {
    let user_id = user.user_id;
    let limit = pagination.limit.unwrap_or(10);
    let offset = pagination.offset.unwrap_or(0);

    let liked_users = utils::get_liked_users(&state.pool, &user_id, limit, offset).await?;

    let result = liked_users
        .into_iter()
        .map(|(user, liked_at)| UserWithLikedAt { user, liked_at })
        .collect();

    Ok(Json(result))
}

pub async fn get_disliked_users(
    State(state): State<ArchenemyState>,
    user: FirebaseUser,
    Query(pagination): Query<PaginationParams>,
) -> Result<Json<Vec<UserWithDislikedAt>>, Error> {
    let user_id = user.user_id;
    let limit = pagination.limit.unwrap_or(10);
    let offset = pagination.offset.unwrap_or(0);

    let disliked_users = utils::get_disliked_users(&state.pool, &user_id, limit, offset).await?;

    // For each disliked user, get the dislike tags
    let mut result = Vec::new();
    for (user, disliked_at) in disliked_users {
        let dislike_tags = utils::get_dislike_tags(&state.pool, &user_id, &user.id).await?;

        result.push(UserWithDislikedAt {
            user,
            disliked_at,
            dislike_tags,
        });
    }

    Ok(Json(result))
}
