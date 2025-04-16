pub mod storage;
pub mod types;
pub mod user;
pub mod utils;

#[cfg(feature = "dummy-auth")]
pub mod auth;

pub mod tags {
    pub static USER: &str = "User";
    pub static TAGS: &str = "Tags";
    pub static STORAGE: &str = "Storage";
}
