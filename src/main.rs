use axum::Router;
use firebase_auth::{FirebaseAuth, FirebaseAuthState};
use shuttle_runtime::SecretStore;
use sqlx::PgPool;
use std::sync::Arc;

#[shuttle_runtime::main]
async fn main(
    #[shuttle_shared_db::Postgres] pool: PgPool,
    #[shuttle_runtime::Secrets] secrets: SecretStore,
) -> shuttle_axum::ShuttleAxum {
    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("Migrations failed :(");

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
        .with_state(FirebaseAuthState { firebase_auth });

    Ok(router.into())
}
