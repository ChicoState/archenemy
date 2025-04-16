use archenemy::types::ArchenemyState;
use axum::Router;
use firebase_auth::{FirebaseAuth, FirebaseAuthState};

use sqlx::postgres::PgPoolOptions;
use std::sync::Arc;
use utoipa::{
    openapi::security::{ApiKey, ApiKeyValue, SecurityScheme},
    Modify, OpenApi,
};
use utoipa_axum::router::OpenApiRouter;
use utoipa_swagger_ui::SwaggerUi;

#[cfg(not(feature = "local"))]
use shuttle_runtime::SecretStore;

#[cfg(feature = "local")]
mod local {
    use std::env;

    pub struct Secrets {
        values: std::collections::HashMap<String, String>,
    }

    impl Secrets {
        pub fn new() -> Self {
            dotenv::dotenv().ok();
            let mut values = std::collections::HashMap::new();

            for (key, value) in env::vars() {
                values.insert(key, value);
            }

            Self { values }
        }

        pub fn get(&self, key: &str) -> Option<String> {
            self.values.get(key).cloned()
        }
    }
}

#[derive(OpenApi)]
#[openapi(
    modifiers(&SecurityAddon),
    tags(
        (name = archenemy::tags::USER, description = "User related endpoints"),
        (name = archenemy::tags::TAGS, description = "Tag related endpoints"),
        (name = archenemy::tags::STORAGE, description = "Storage related endpoints")
    ),
)]
struct ApiDoc;

struct SecurityAddon;

impl Modify for SecurityAddon {
    fn modify(&self, openapi: &mut utoipa::openapi::OpenApi) {
        if let Some(components) = openapi.components.as_mut() {
            components.add_security_scheme(
                "firebase_auth_token",
                SecurityScheme::ApiKey(ApiKey::Header(ApiKeyValue::new("Authorization"))),
            )
        }
    }
}

// Create common setup function to be used by both local and shuttle
async fn setup_app(
    db_url: &str,
    firebase_auth_id: &str,
    storage_access_id: &str,
    storage_access_token: &str,
) -> Router {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(db_url)
        .await
        .expect("Failed to connect to Postgres");

    match sqlx::migrate!().run(&pool).await {
        Ok(_) => println!("Database migrations completed successfully!"),
        Err(e) => {
            eprintln!("Migration error: {:?}", e);
            panic!("Database migrations failed");
        }
    };

    let firebase_auth = Arc::new(FirebaseAuth::new(firebase_auth_id).await);

    let (router, api) = OpenApiRouter::with_openapi(ApiDoc::openapi())
        .nest(
            "/api/v1",
            OpenApiRouter::new()
                .nest(
                    "/storage",
                    archenemy::storage::routes(storage_access_id, storage_access_token),
                )
                .merge(archenemy::user::routes())
                .with_state(ArchenemyState {
                    auth: FirebaseAuthState { firebase_auth },
                    pool: pool.clone(),
                }),
        )
        .split_for_parts();

    router.merge(SwaggerUi::new("/swagger-ui").url("/api-docs/openapi.json", api))
}

#[cfg(not(feature = "local"))]
#[shuttle_runtime::main]
async fn main(#[shuttle_runtime::Secrets] secrets: SecretStore) -> shuttle_axum::ShuttleAxum {
    let db_url = secrets
        .get("NEON_POSTGRES_URL")
        .expect("NEON_POSTGRES_URL not found");

    let firebase_auth_id = secrets
        .get("FIREBASE_AUTH_PROJECT_ID")
        .expect("Secret not found");

    let storage_access_id = secrets
        .get("STORAGE_ACCESS_ID")
        .expect("STORAGE_ACCESS_ID not found");

    let storage_access_token = secrets
        .get("STORAGE_ACCESS_TOKEN")
        .expect("STORAGE_ACCESS_TOKEN not found");

    let router = setup_app(
        &db_url,
        &firebase_auth_id,
        &storage_access_id,
        &storage_access_token,
    )
    .await;

    Ok(router.into())
}

#[cfg(feature = "local")]
#[tokio::main]
async fn main() {
    let secrets = local::Secrets::new();

    let db_url = secrets
        .get("NEON_POSTGRES_URL")
        .expect("NEON_POSTGRES_URL not found");

    let firebase_auth_id = secrets
        .get("FIREBASE_AUTH_PROJECT_ID")
        .expect("Secret not found");

    let storage_access_id = secrets
        .get("STORAGE_ACCESS_ID")
        .expect("STORAGE_ACCESS_ID not found");

    let storage_access_token = secrets
        .get("STORAGE_ACCESS_TOKEN")
        .expect("STORAGE_ACCESS_TOKEN not found");

    let app = setup_app(
        &db_url,
        &firebase_auth_id,
        &storage_access_id,
        &storage_access_token,
    )
    .await;

    let host = secrets.get("HOST").unwrap_or_else(|| "0.0.0.0".to_string());
    let port: u16 = secrets
        .get("PORT")
        .unwrap_or_else(|| "3000".to_string())
        .parse()
        .expect("PORT must be a number");

    let listener = tokio::net::TcpListener::bind(format!("{}:{}", host, port))
        .await
        .unwrap();

    println!("🚀 Server started on http://{}:{}", host, port);

    axum::serve(listener, app).await.unwrap();
}
