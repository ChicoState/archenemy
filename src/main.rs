use archenemy::types::ArchenemyState;
use axum::Router;
use firebase_auth::{FirebaseAuth, FirebaseAuthState};
use shuttle_runtime::SecretStore;
use sqlx::postgres::PgPoolOptions;
use std::sync::Arc;

#[shuttle_runtime::main]
async fn main(#[shuttle_runtime::Secrets] secrets: SecretStore) -> shuttle_axum::ShuttleAxum {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(
            &secrets
                .get("NEON_POSTGRES_URL")
                .expect("NEON_POSTGRES_URL not found"),
        )
        .await
        .expect("Failed to connect to Postgres");
    match sqlx::migrate!().run(&pool).await {
        Ok(_) => println!("Database migrations completed successfully!"),
        Err(e) => {
            eprintln!("Migration error: {:?}", e);
            panic!("Database migrations failed");
        }
    };

    let firebase_auth_id = secrets
        .get("FIREBASE_AUTH_PROJECT_ID")
        .expect("Secret not found");
    let firebase_auth = Arc::new(FirebaseAuth::new(&firebase_auth_id).await);

    let router = Router::new()
        .nest(
            "/storage",
            archenemy::storage::routes(
                &secrets
                    .get("STORAGE_ACCESS_ID")
                    .expect("STORAGE_ACCESS_ID not found"),
                &secrets
                    .get("STORAGE_ACCESS_TOKEN")
                    .expect("STORAGE_ACCESS_TOKEN not found"),
            ),
        )
        .merge(archenemy::user::routes())
        .with_state(ArchenemyState {
            auth: FirebaseAuthState { firebase_auth },
            pool,
        });

    Ok(router.into())
}
