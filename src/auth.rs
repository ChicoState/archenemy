use axum::{
    extract::FromRequestParts,
    http::{header, request::Parts, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use tracing::error;

/// Represents an authenticated user, extracted from the Authentication header.
#[derive(Debug, Clone)]
pub struct AuthUser {
    /// The ID of the authenticated user.
    pub user_id: String, // Or Uuid if you prefer and add the uuid crate
}

/// Custom rejection type for authentication errors.
#[derive(Debug, Serialize)]
pub struct AuthError {
    message: String,
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        (StatusCode::UNAUTHORIZED, Json(self)).into_response()
    }
}

impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = AuthError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        // Extract the Authentication header
        let auth_header = parts
            .headers
            .get(header::AUTHORIZATION) // Using standard AUTHORIZATION header for convention
            .and_then(|value| value.to_str().ok());

        match auth_header {
            Some(header_value) => {
                // Check if the header starts with "Bearer "
                if let Some(token) = header_value.strip_prefix("Bearer ") {
                    let token = token.trim();
                    if token.is_empty() {
                        error!("Bearer token is empty");
                        Err(AuthError {
                            message: "Invalid Bearer token".to_string(),
                        })
                    } else {
                        // In a real scenario, you'd validate this token.
                        // For this dummy implementation, the token itself is the user_id.
                        Ok(AuthUser {
                            user_id: token.to_string(),
                        })
                    }
                } else {
                    error!("Invalid authentication header format. Expected Bearer token.");
                    Err(AuthError {
                        message: "Invalid authentication header format. Expected Bearer token."
                            .to_string(),
                    })
                }
            }
            None => {
                error!("Authorization header missing");
                Err(AuthError {
                    message: "Authorization header required".to_string(),
                })
            }
        }
    }
}
