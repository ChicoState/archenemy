use crate::types::ArchenemyState;
use axum::{
    routing::{delete, get, patch, post},
    Router,
};

mod handlers;
mod types;
mod utils;

pub fn routes() -> Router<ArchenemyState> {
    Router::<ArchenemyState>::new()
        // User routes
        .route("/user/me", get(handlers::get_current_user))
        .route("/user/:user_id", get(handlers::get_user))
        .route("/user/me", patch(handlers::update_current_user))
        // Tag routes
        .route("/tags", get(handlers::get_all_tags))
        .route("/user/:user_id/tags", get(handlers::get_user_tags))
        .route("/user/me/tags", post(handlers::add_user_tag))
        .route("/user/me/tags/:tag_name", delete(handlers::remove_user_tag))
        // Enemy routes
        .route("/enemies/discover", get(handlers::get_potential_enemies))
        .route("/enemies/like/:user_id", post(handlers::like_user))
        .route("/enemies/dislike/:user_id", post(handlers::dislike_user))
        .route(
            "/enemies/dislike/:user_id/tags",
            post(handlers::dislike_user_with_tags),
        )
        .route("/enemies/likes", get(handlers::get_liked_users))
        .route("/enemies/dislikes", get(handlers::get_disliked_users))
}
