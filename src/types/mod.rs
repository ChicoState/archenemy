use axum::{http::StatusCode, response::IntoResponse};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
#[non_exhaustive]
pub enum Error {
    Unauthenticated,
    S3 { msg: String },
    MultipartParse { msg: String },
    Unknown,
}

impl IntoResponse for Error {
    fn into_response(self) -> axum::response::Response {
        let status_code = match self {
            Self::Unauthenticated => StatusCode::UNAUTHORIZED,
            Self::S3 { msg: _ } => StatusCode::INTERNAL_SERVER_ERROR,
            Self::MultipartParse { msg: _ } => StatusCode::BAD_REQUEST,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        };

        (status_code, self).into_response()
    }
}
