use axum::extract::FromRef;
use axum::{http::StatusCode, response::IntoResponse};
use firebase_auth::FirebaseAuthState;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

#[derive(Clone, FromRef)]
pub struct ArchenemyState {
    pub pool: PgPool,
    pub auth: FirebaseAuthState,
}

#[derive(Serialize, Deserialize, Debug)]
#[non_exhaustive]
pub enum Error {
    Unauthenticated,
    NotFound { resource: String },
    Validation { field: String, message: String },
    Duplicate { resource: String },
    Database { message: String },
    S3 { msg: String },
    MultipartParse { msg: String },
    Unknown { msg: String },
}

impl std::error::Error for Error {}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Unauthenticated => write!(f, "Authentication failed or token missing"),
            Self::NotFound { resource } => write!(f, "Resource not found: {}", resource),
            Self::Validation { field, message } => {
                write!(f, "Validation error in {}: {}", field, message)
            }
            Self::Duplicate { resource } => write!(f, "Resource already exists: {}", resource),
            Self::Database { message } => write!(f, "Database error: {}", message),
            Self::S3 { msg } => write!(f, "S3 error: {}", msg),
            Self::MultipartParse { msg } => write!(f, "Multipart parse error: {}", msg),
            Self::Unknown { msg } => write!(f, "Unknown error: {}", msg),
        }
    }
}

impl From<sqlx::Error> for Error {
    fn from(error: sqlx::Error) -> Self {
        match error {
            sqlx::Error::RowNotFound => Error::NotFound {
                resource: "database record".to_string(),
            },
            _ => Error::Database {
                message: error.to_string(),
            },
        }
    }
}

impl IntoResponse for Error {
    fn into_response(self) -> axum::response::Response {
        let status_code = match &self {
            Self::Unauthenticated => StatusCode::UNAUTHORIZED,
            Self::NotFound { .. } => StatusCode::NOT_FOUND,
            Self::Validation { .. } => StatusCode::BAD_REQUEST,
            Self::Duplicate { .. } => StatusCode::CONFLICT,
            Self::Database { .. } => StatusCode::INTERNAL_SERVER_ERROR,
            Self::S3 { .. } => StatusCode::INTERNAL_SERVER_ERROR,
            Self::MultipartParse { .. } => StatusCode::BAD_REQUEST,
            Self::Unknown { .. } => StatusCode::INTERNAL_SERVER_ERROR,
        };

        (status_code, self).into_response()
    }
}
