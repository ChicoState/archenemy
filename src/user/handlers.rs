#[cfg(feature = "dummy-auth")]
use crate::auth::AuthUser;
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
#[cfg(not(feature = "dummy-auth"))]
use firebase_auth::FirebaseUser as AuthUser;
use serde::{Deserialize, Serialize};
use sqlx::types::chrono::{DateTime, Utc};
use utoipa::{IntoParams, ToSchema};

use crate::types::{ArchenemyState, Error};
use crate::user::types::{
    CreateUserRequest, TagCount, UpdateUserRequest, User, UserDislike, UserDislikeTag, UserLike,
    UserTag,
};
use crate::user::utils;

/// Parameters for pagination in API requests.
///
/// Used to control the number of items returned and the starting position
/// in list-based API endpoints.
#[derive(Debug, Deserialize, ToSchema, IntoParams)]
pub struct PaginationParams {
    /// Maximum number of items to return. Defaults to endpoint-specific values if not provided.
    limit: Option<i64>,
    /// Number of items to skip before starting to return items. Defaults to 0 if not provided.
    offset: Option<i64>,
}

/// User information with their associated tags and optional compatibility score.
///
/// Used in responses that need to provide both user data and their associated tags,
/// particularly in nemesis matching endpoints.
#[derive(Debug, Serialize, ToSchema)]
pub struct UserWithTags {
    /// The base user information flattened into this structure
    #[serde(flatten)]
    user: User,
    /// Tags associated with this user
    tags: Vec<UserTag>,
    /// Optional compatibility score with the requesting user (higher indicates greater incompatibility)
    compatibility_score: Option<f64>,
}

/// User information with timestamp indicating when they were liked by the current user.
///
/// Used in responses for liked user listings.
#[derive(Debug, Serialize, ToSchema)]
pub struct UserWithLikedAt {
    /// The base user information flattened into this structure
    #[serde(flatten)]
    user: User,
    /// Timestamp when the current user liked this user
    liked_at: DateTime<Utc>,
}

/// User information with timestamp and tags indicating why they were disliked by the current user.
///
/// Used in responses for disliked user listings.
#[derive(Debug, Serialize, ToSchema)]
pub struct UserWithDislikedAt {
    /// The base user information flattened into this structure
    #[serde(flatten)]
    user: User,
    /// Timestamp when the current user disliked this user
    disliked_at: DateTime<Utc>,
    /// Tags associated with the dislike, indicating reasons for disliking
    dislike_tags: Vec<UserDislikeTag>,
}

/// Request to add a single tag to a user.
#[derive(Debug, Deserialize, ToSchema)]
pub struct AddTagRequest {
    /// Name of the tag to add
    tag_name: String,
}

/// Request to add multiple tags at once.
#[derive(Debug, Deserialize, ToSchema)]
pub struct AddTagsRequest {
    /// List of tag names to add
    tag_names: Vec<String>,
}

/// Tag representing a potential nemesis relationship with a score indicating strength.
///
/// Higher nemesis scores indicate stronger semantic opposition between tags.
#[derive(Debug, Serialize, ToSchema)]
pub struct NemesisTag {
    /// Name of the tag
    tag_name: String,
    /// Score indicating how strongly this tag opposes another tag (higher = more opposed)
    nemesis_score: f64,
}

/// Get the current authenticated user or create a new user if one doesn't exist.
///
/// This is the primary endpoint for user initialization. When a new user signs up
/// via Firebase authentication, this endpoint will automatically create a corresponding
/// user record in our database with default values including a randomly generated username.
///
/// Example:
/// ```
/// GET /user/me
/// ```
///
/// <div class="info">
/// If the user already exists, their profile information is returned.
/// If the user doesn't exist yet, a new profile is created and returned.
/// </div>
#[utoipa::path(
    get,
    path="/user/me",
    tag=crate::tags::USER,
    responses(
        (status = 200, description = "Get current user, create new if not exists", body = User),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn get_current_user(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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

/// Get a specific user by their ID.
///
/// Retrieves public profile information for any user in the system.
/// The requesting user must be authenticated but can view any other user's profile.
///
/// Example:
/// ```
/// GET /user/abc123def456
/// ```
#[utoipa::path(
    get,
    path="/user/{user_id}",
    tag=crate::tags::USER,
    responses(
        (status = 200, description = "Get user of id `user_id`", body = User),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "User not found", body = Error, example = json!(Error::NotFound { resource: "User with ID abc123def456".to_string() })),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn get_user(
    State(state): State<ArchenemyState>,
    Path(user_id): Path<String>,
    _user: AuthUser, // Ensure authenticated
) -> Result<Json<User>, Error> {
    let maybe_user = utils::get_user_by_id(&state.pool, &user_id).await?;

    let user = maybe_user.ok_or_else(|| Error::NotFound {
        resource: format!("User with ID {}", user_id),
    })?;

    Ok(Json(user))
}

/// Update the current user's profile information.
///
/// Allows users to modify their profile information such as username,
/// display name, avatar URL, and bio. Performs validation on inputs.
///
/// Example:
/// ```
/// PUT /user/me
/// {
///   "username": "new_username",
///   "display_name": "New Display Name",
///   "avatar_url": "https://example.com/avatar.jpg",
///   "bio": "My new bio text"
/// }
/// ```
///
/// <div class="warning">
/// Username cannot be empty if provided. All fields are optional - only provided
/// fields will be updated.
/// </div>
#[utoipa::path(
    put,
    path="/user/me",
    tag=crate::tags::USER,
    responses(
        (status = 200, description = "Update current user, return the updated version", body = User),
        (status = 400, description = "Validation error, in other words, bad request", body = Error, example = json!(Error::Validation { field: "username".to_string(), message: "Username cannot be empty".to_string() })),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "User not found", body = Error, example = json!(Error::NotFound { resource: "User with ID abc123def456".to_string() })),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn update_current_user(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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

/// Get all tags in the system with their usage counts.
///
/// Returns a list of all tags that have been created by users in the system,
/// along with a count of how many users have each tag. Tags are sorted by
/// popularity (count) in descending order.
///
/// Example:
/// ```
/// GET /tags
/// ```
#[utoipa::path(
    get,
    path="/tags",
    tag=crate::tags::TAGS,
    responses(
        (status = 200, description = "Return a list of tags with their corresponding counts", body = Vec<TagCount>),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn get_all_tags(
    State(state): State<ArchenemyState>,
    _user: AuthUser, // Ensure authenticated
) -> Result<Json<Vec<TagCount>>, Error> {
    let tags = utils::get_all_tags(&state.pool).await?;
    Ok(Json(tags))
}

/// Find semantically opposite tags to a given tag.
///
/// This endpoint returns a list of tags that are considered "nemesis" tags
/// to the specified tag. A nemesis tag is one that is semantically opposite
/// or strongly conflicting with the given tag. Each returned tag includes a
/// nemesis score indicating the strength of opposition.
///
/// Example:
/// ```
/// GET /tags/introvert/nemesis?limit=5
/// ```
///
/// <div class="info">
/// Higher nemesis scores indicate stronger semantic opposition between tags.
/// Results are sorted by nemesis score in descending order.
/// </div>
#[utoipa::path(
    get,
    path="/tags/{tag_id}/nemesis",
    tag=crate::tags::TAGS,
    params(PaginationParams),
    responses(
        (status = 200, description = "Return a list of tags that is nemesis of the given tag id semantically, with a given score", body = Vec<NemesisTag>),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )

)]
pub async fn get_nemesis_tags(
    State(state): State<ArchenemyState>,
    _user: AuthUser, // Ensure authenticated
    Path(tag_name): Path<String>,
    Query(pagination): Query<PaginationParams>,
) -> Result<Json<Vec<NemesisTag>>, Error> {
    let limit = pagination.limit.unwrap_or(10);
    let nemesis_tags = utils::get_nemesis_tags(&state.pool, &tag_name, limit).await?;

    // Convert to NemesisTag format
    let formatted_tags = nemesis_tags
        .into_iter()
        .map(|(tag_name, nemesis_score)| NemesisTag {
            tag_name,
            nemesis_score,
        })
        .collect();

    Ok(Json(formatted_tags))
}

/// Get all tags associated with a specific user.
///
/// Retrieves the list of tags that a user has added to their profile.
/// These tags represent the user's interests, personality traits, or other characteristics.
///
/// Example:
/// ```
/// GET /user/abc123def456/tags
/// ```
#[utoipa::path(
    get,
    path="/user/{user_id}/tags",
    tags=[crate::tags::USER, crate::tags::TAGS],
    responses(
        (status = 200, description = "Get a list of tags thats attributed to user of id `user_id`", body = Vec<UserTag>),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "User not found", body = Error, example = json!(Error::NotFound { resource: "User with ID abc123def456".to_string() })),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )

)]
pub async fn get_user_tags(
    State(state): State<ArchenemyState>,
    Path(user_id): Path<String>,
    _user: AuthUser, // Ensure authenticated
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

/// Get all tags associated with the current authenticated user.
///
/// Retrieves the list of tags that the current user has added to their profile.
/// These tags represent the user's interests, personality traits, or other characteristics.
///
/// Example:
/// ```
/// GET /user/me/tags
/// ```
#[utoipa::path(
    get,
    path="/user/me/tags",
    tags=[crate::tags::USER, crate::tags::TAGS],
    responses(
        (status = 200, description = "Get tags of the current user", body = Vec<UserTag>),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "User not found", body = Error, example = json!(Error::NotFound { resource: "User with ID abc123def456".to_string() })),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )

)]
pub async fn get_current_user_tags(
    State(state): State<ArchenemyState>,
    user: AuthUser, // Ensure authenticated
) -> Result<Json<Vec<UserTag>>, Error> {
    // Verify user exists
    let maybe_user = utils::get_user_by_id(&state.pool, &user.user_id).await?;
    if maybe_user.is_none() {
        return Err(Error::NotFound {
            resource: format!("User with ID {}", &user.user_id),
        });
    }

    let tags = utils::get_user_tags(&state.pool, &user.user_id).await?;
    Ok(Json(tags))
}

/// Add a new tag to the current user's profile.
///
/// This endpoint allows users to add a single tag to their profile. Tags can represent
/// interests, personality traits, or other characteristics. If the tag doesn't already
/// exist in the system, it will be created.
///
/// Example:
/// ```
/// POST /user/me/tags
/// {
///   "tag_name": "introvert"
/// }
/// ```
///
/// <div class="warning">
/// Tag name cannot be empty. Tags are case-sensitive.
/// </div>
#[utoipa::path(
    post,
    path="/user/me/tags",
    tags=[crate::tags::USER, crate::tags::TAGS],
    request_body = AddTagRequest,
    responses(
        (status = 200, description = "Add a tag to the current user", body = UserTag),
        (status = 400, description = "Validation error, tag name cannot be empty", body = Error, example = json!(Error::Validation { field: "tag_name".to_string(), message: "Tag name cannot be empty".to_string() })),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn add_current_user_tag(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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

/// Remove one or more tags from the current user's profile.
///
/// This endpoint allows users to remove tags from their profile by providing
/// a list of tag names to be removed.
///
/// Example:
/// ```
/// DELETE /user/me/tags
/// ["introvert", "coffee-lover"]
/// ```
///
/// <div class="info">
/// If any tags in the list are not found on the user's profile, they will be
/// silently ignored. Returns a 204 No Content status on success.
/// </div>
#[utoipa::path(
    delete,
    path="/user/me/tags",
    tags=[crate::tags::USER, crate::tags::TAGS],
    request_body = Vec<String>,
    responses(
        (status = 204, description = "Tags successfully removed"),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn remove_current_user_tags(
    State(state): State<ArchenemyState>,
    user: AuthUser,
    Json(names): Json<Vec<String>>,
) -> Result<StatusCode, Error> {
    let user_id = user.user_id;

    utils::remove_user_tag(&state.pool, &user_id, &names).await?;
    Ok(StatusCode::NO_CONTENT)
}

/// Get a list of potential nemeses for the current user.
///
/// This endpoint returns users who are potentially compatible as "nemeses" based on
/// having opposing interests, personality traits, or characteristics. Results are sorted
/// by a compatibility score, with higher scores indicating users who would make better nemeses.
///
/// Example:
/// ```
/// GET /nemeses?limit=10&offset=0
/// ```
///
/// <div class="info">
/// The compatibility score is calculated based on how strongly a user's tags oppose the
/// current user's tags. Users who have already been liked or disliked will not appear in results.
/// </div>
#[utoipa::path(
    get,
    path="/nemeses",
    tag=crate::tags::USER,
    params(PaginationParams),
    responses(
        (status = 200, description = "Get potential nemeses for the current user", body = Vec<UserWithTags>),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn get_potential_nemeses(
    State(state): State<ArchenemyState>,
    user: AuthUser,
    Query(pagination): Query<PaginationParams>,
) -> Result<Json<Vec<UserWithTags>>, Error> {
    let user_id = user.user_id;
    let limit = pagination.limit.unwrap_or(10);
    let offset = pagination.offset.unwrap_or(0);

    let potential_nemeses =
        utils::get_potential_nemeses(&state.pool, &user_id, limit, offset).await?;

    // For each potential nemesis, get their tags
    let mut result = Vec::new();
    for (user, score) in potential_nemeses {
        let tags = utils::get_user_tags(&state.pool, &user.id).await?;

        result.push(UserWithTags {
            user,
            tags,
            compatibility_score: Some(score),
        });
    }

    Ok(Json(result))
}

/// Like a user to indicate interest in establishing a nemesis relationship.
///
/// This endpoint allows the current user to express interest in another user as a potential
/// nemesis. If both users like each other, they become matched nemeses.
///
/// Example:
/// ```
/// POST /user/abc123def456/like
/// ```
///
/// <div class="warning">
/// Users cannot like themselves. If the target user has already liked the current user,
/// this will create a match.
/// </div>
#[utoipa::path(
    post,
    path="/user/{target_user_id}/like",
    tag=crate::tags::USER,
    params(
        ("target_user_id" = String, Path, description = "ID of the user to like")
    ),
    responses(
        (status = 200, description = "User successfully liked", body = UserLike),
        (status = 400, description = "Cannot like yourself", body = Error, example = json!(Error::Validation { field: "target_user_id".to_string(), message: "Cannot like yourself".to_string() })),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "Target user not found", body = Error, example = json!(Error::NotFound { resource: "User with ID abc123def456".to_string() })),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn like_user(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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

/// Dislike a user to indicate lack of interest in establishing a nemesis relationship.
///
/// This endpoint allows the current user to express that they are not interested in
/// another user as a potential nemesis. Disliked users will not appear in future
/// potential nemesis suggestions.
///
/// Example:
/// ```
/// POST /user/abc123def456/dislike
/// ```
///
/// <div class="warning">
/// Users cannot dislike themselves. Disliking is permanent and cannot be undone.
/// </div>
#[utoipa::path(
    post,
    path="/user/{target_user_id}/dislike",
    tag=crate::tags::USER,
    params(
        ("target_user_id" = String, Path, description = "ID of the user to dislike")
    ),
    responses(
        (status = 200, description = "User successfully disliked", body = UserDislike),
        (status = 400, description = "Cannot dislike yourself", body = Error, example = json!(Error::Validation { field: "target_user_id".to_string(), message: "Cannot dislike yourself".to_string() })),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "Target user not found", body = Error, example = json!(Error::NotFound { resource: "User with ID abc123def456".to_string() })),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )
)]
pub async fn dislike_user(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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

/// Dislike tags so more simmilar tags will show up.
///
/// This endpoint allows the current user to express that they are not interested in
/// list of tags as a potential nemesis.
///
/// Example:
/// ```
/// POST /user/abc123def456/dislike/tags
/// {
///   "tag_names": ["boring", "argumentative"]
/// }
/// ```
///
/// <div class="warning">
/// We need to decide whether to recommend more or less in this scenario.
/// </div>
#[utoipa::path(
    post,
    path="/user/{target_user_id}/dislike/tags",
    tags=[crate::tags::USER, crate::tags::TAGS],
    params(
        ("target_user_id" = String, Path, description = "ID of the user to dislike with tags")
    ),
    request_body = AddTagsRequest,
    responses(
        (status = 200, description = "User successfully disliked with tags", body = Vec<UserDislikeTag>),
        (status = 400, description = "Cannot dislike yourself", body = Error, example = json!(Error::Validation { field: "target_user_id".to_string(), message: "Cannot dislike yourself".to_string() })),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "Target user not found", body = Error, example = json!(Error::NotFound { resource: "User with ID abc123def456".to_string() })),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )

)]
pub async fn dislike_user_with_tags(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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

/// Get a list of users that the current user has liked.
///
/// Returns a paginated list of users that the current user has expressed interest in
/// as potential nemeses, including when they were liked.
///
/// Example:
/// ```
/// GET /user/me/likes?limit=10&offset=0
/// ```
///
/// <div class="info">
/// Results are sorted by most recent likes first. Each user includes a timestamp
#[utoipa::path(
    get,
    path="/user/me/likes",
    tag=crate::tags::USER,
    params(PaginationParams),
    responses(
        (status = 200, description = "Get users liked by the current user", body = Vec<UserWithLikedAt>),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )

)]
pub async fn get_liked_users(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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

/// Get a list of users that the current user has disliked.
///
/// Returns a paginated list of users that the current user has expressed no interest in
/// as potential nemeses, including when they were disliked and any tags associated with
/// the dislike.
///
/// Example:
/// ```
/// GET /user/me/dislikes?limit=10&offset=0
/// ```
///
/// <div class="info">
/// Results are sorted by most recent dislikes first. Each user includes a timestamp
/// indicating when they were disliked and any tags that were associated with the dislike.
/// </div>
#[utoipa::path(
    get,
    path="/user/me/dislikes",
    tag=crate::tags::USER,
    params(PaginationParams),
    responses(
        (status = 200, description = "Get users disliked by the current user", body = Vec<UserWithDislikedAt>),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error, this usually indicates something wrong with the database", body = Error, example = json!(Error::Database { message: "Database connection failed".to_string() }))
    ),
    security(
        ("firebase_auth_token" = [])
    )

)]
pub async fn get_disliked_users(
    State(state): State<ArchenemyState>,
    user: AuthUser,
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
