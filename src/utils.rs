use axum::{
    body::Body,
    debug_middleware,
    extract::{Request, State},
    middleware::Next,
    response::{IntoResponse, Response},
};
use firebase_auth::FirebaseUser;

use crate::types::ArchenemyState;

/// The middleware that checks if the user is authenticated.
#[allow(dead_code)]
#[debug_middleware]
pub async fn authenticated(
    _: FirebaseUser,
    _: State<ArchenemyState>,
    req: Request<Body>,
    next: Next,
) -> Response {
    next.run(req).await.into_response()
}
