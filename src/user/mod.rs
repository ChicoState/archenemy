use crate::types::ArchenemyState;
use utoipa_axum::{router::OpenApiRouter, routes};

/// User-related API handlers
mod handlers;
/// User data structures and type definitions
mod types;
/// User business logic and database operations
mod utils;

// TODO: Implement endpoint to check whether user exists (GET /user/{username}/exists)
/// Configure and return the router for all user-related API endpoints
///
/// This function sets up the OpenApiRouter with all user-related routes including:
/// - User profile management (get/update)
/// - Tag management (get/add/remove)
/// - Nemesis interaction (discover/like/dislike)
/// - Relationship management (likes/dislikes)
///
/// All routes require authentication via Firebase Auth.
pub fn routes() -> OpenApiRouter<ArchenemyState> {
    OpenApiRouter::<ArchenemyState>::new()
        // User profile routes
        // GET/PUT /user/me - Get or update current user profile
        .routes(routes!(
            handlers::get_current_user,
            handlers::update_current_user
        ))
        // GET /user/{user_id} - Get another user's profile
        .routes(routes!(handlers::get_user))
        // Tag system routes
        // GET /tags - Get all tags in the system
        .routes(routes!(handlers::get_all_tags))
        // GET /tags/{tag_name}/nemesis - Get semantically opposite tags
        .routes(routes!(handlers::get_nemesis_tags))
        // GET /user/{user_id}/tags - Get tags for a specific user
        .routes(routes!(handlers::get_user_tags))
        // Current user tag management
        // GET/POST/DELETE /user/me/tags - Manage current user's tags
        .routes(routes!(
            handlers::add_current_user_tag,
            handlers::get_current_user_tags,
            handlers::remove_current_user_tags
        ))
        // Nemesis discovery and interaction
        // GET /nemeses - Get potential nemeses
        .routes(routes!(handlers::get_potential_nemeses))
        // POST /user/{user_id}/like - Like a potential nemesis
        .routes(routes!(handlers::like_user))
        // POST /user/{user_id}/dislike - Dislike a potential nemesis
        .routes(routes!(handlers::dislike_user))
        // POST /user/{user_id}/dislike/tags - Dislike with specific tags
        .routes(routes!(handlers::dislike_user_with_tags))
        // Relationship history
        // GET /user/me/likes - Get users the current user has liked
        .routes(routes!(handlers::get_liked_users))
        // GET /user/me/dislikes - Get users the current user has disliked
        .routes(routes!(handlers::get_disliked_users))
}
