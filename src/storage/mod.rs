pub mod types;
use crate::types::{ArchenemyState, Error};
use axum::{
    body::Bytes,
    extract::{Multipart, Path},
    routing::{get, put},
    Extension, Json, Router,
};
use s3::{creds::Credentials, Bucket};
use std::sync::Arc;
use uuid::Uuid;

type BucketExtension = Arc<Bucket>;

pub fn routes(access_id: &str, secret_access_key: &str) -> Router<ArchenemyState> {
    let bucket = Bucket::new(
        "archenemy",
        "https://archenemy.nyc3.digitaloceanspaces.com"
            .parse()
            .expect("Unable to create region for digital ocean"),
        Credentials::new(Some(access_id), Some(secret_access_key), None, None, None)
            .expect("Unable to create credentials"),
    )
    .expect("Failed to create bucket");

    Router::new()
        .route("/{object}", get(get_object))
        .route("/", put(put_object))
        .layer(Extension(Arc::new(*bucket)))
}

async fn get_object(
    Extension(bucket): Extension<BucketExtension>,
    Path(object): Path<String>,
) -> Result<Bytes, Error> {
    let object = bucket.get_object(object).await.map_err(|e| Error::S3 {
        msg: format!("{:?}", e),
    })?;

    let bytes = object.into_bytes();

    Ok(bytes)
}

#[axum::debug_handler]
async fn put_object(
    Extension(bucket): Extension<BucketExtension>,
    mut multipart: Multipart,
) -> Result<Json<types::PutResponse>, Error> {
    let file_name = Uuid::new_v4();
    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| Error::MultipartParse {
            msg: format!("{:?}", e),
        })?
    {
        if let Some(name) = field.name() {
            if name == "file" {
                bucket
                    .put_object(format!("{}", file_name), &field.bytes().await.unwrap())
                    .await
                    .map_err(|e| Error::S3 {
                        msg: format!("{:?}", e),
                    })?;
                break;
            }
        }
    }

    Ok(Json(types::PutResponse {
        filename: file_name,
    }))
}
