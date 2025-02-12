use axum::{http::StatusCode, response::IntoResponse};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub enum Error {
    Unauthenticated,
}

impl IntoResponse for Error {
    fn into_response(self) -> axum::response::Response {
        let status_code = match self {
            Self::Unauthenticated => StatusCode::UNAUTHORIZED,
            // TODO: Add a new branch for every error variant
        };

        (status_code, self).into_response()
    }
}
