use axum::{
    body::Body,
    extract::Request,
    middleware::Next,
    response::{IntoResponse, Response},
};
use firebase_auth::FirebaseUser;

/// The middleware that checks if the user is authenticated.
pub async fn authenticated(_: FirebaseUser, req: Request<Body>, next: Next) -> Response {
    next.run(req).await.into_response()
}
