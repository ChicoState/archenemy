pub mod types;
use crate::types::{ArchenemyState, Error};
use axum::{
    body::Bytes,
    extract::{Multipart, Path},
    Extension, Json,
};
use s3::{creds::Credentials, Bucket};
use serde::Deserialize;
use std::sync::Arc;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

type BucketExtension = Arc<Bucket>;

pub fn routes(access_id: &str, secret_access_key: &str) -> OpenApiRouter<ArchenemyState> {
    let bucket = Bucket::new(
        "archenemy",
        "https://archenemy.nyc3.digitaloceanspaces.com"
            .parse()
            .expect("Unable to create region for digital ocean"),
        Credentials::new(Some(access_id), Some(secret_access_key), None, None, None)
            .expect("Unable to create credentials"),
    )
    .expect("Failed to create bucket");

    OpenApiRouter::new()
        .routes(routes!(get_object))
        .routes(routes!(put_object))
        .layer(Extension(Arc::new(*bucket)))
}

/// Get an object from the bucket.
///
/// This api will get path from uri and query it against the s3 backend server.
///
/// <div class="warning">
///
/// I haven't figured out what is the behavior when file not found
///
/// </div>
///
/// Example:
/// ```
/// GET /api/v1/storage/some_file
/// ```
#[utoipa::path(get, path="/{object}", tag=crate::tags::STORAGE, responses(
    (status = 200, description = "File found and returned", body = [u8]),
    (status = 500, description = "Internal server error", body = Error, example=json!(Error::Database { message: "S3 bucket error".to_string() })),
))]
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

/// Dummy data represent the form data
///
/// Its a form with just one field, `file`, with the value as the file content.
#[derive(Deserialize, ToSchema)]
#[allow(unused)]
struct UploadForm {
    #[schema(format = Binary, content_media_type = "application/octet-stream")]
    file: String,
}

/// Upload file to the bucket.
///
/// This api will take a multipart form data and upload the file to the s3 backend server. File
/// name will be randomly generated and returned in the response. See [`UploadForm`] for form
/// schema.
///
/// (I dont have an example because I don't event know how this looks like, it should be like a
/// html form with input of type file)
#[utoipa::path(
    put,
    path = "/",
    tag = crate::tags::STORAGE,
    request_body(content = UploadForm, content_type = "multipart/form-data"),
    responses(
        (status = 200, description = "File uploaded successfully", body = types::PutResponse),
        (status = 500, description = "Internal server error", body = Error, example=json!(Error::Database { message: "S3 bucket error".to_string() })),
    ),
)]
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
