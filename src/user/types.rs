use serde::{Deserialize, Serialize};
use sqlx::prelude::{FromRow, Type};
use sqlx::types::chrono::{DateTime, Utc};
use std::fmt::Debug;
use std::fmt::Display;
use std::ops::Deref;

pub trait Wrapped<Inner>: Deref + Sized + Validate {
    type Error;
    #[allow(dead_code)]
    fn new(inner: Inner) -> Result<Self, Self::Error>;

    /// Creates a new instance without validation.
    ///
    /// # Safety
    ///
    /// This method bypasses validation and should only be used when the caller
    /// can guarantee that the input is valid or when working with trusted data sources.
    fn raw(inner: Inner) -> Self;
}

pub trait Validate {
    fn validate(&self) -> Result<(), crate::types::Error>;
}

#[derive(Debug, Clone, Serialize, Deserialize, Type)]
#[sqlx(transparent)]
pub struct Email(String);

impl Deref for Email {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<Inner> Wrapped<Inner> for Email
where
    Inner: Display + ToString + Debug,
{
    type Error = crate::types::Error;

    fn new(inner: Inner) -> Result<Self, Self::Error>
where {
        let email_str = inner.to_string();
        let email = Self(email_str);

        email.validate().map(|_| email)
    }

    fn raw(inner: Inner) -> Self {
        Self(inner.to_string())
    }
}

impl Validate for Email {
    fn validate(&self) -> Result<(), crate::types::Error> {
        // Simple email validation
        // Check for @ symbol, at least one character before @, and at least one dot after @
        let email_str = self.0.as_str();

        if email_str.is_empty() || email_str.len() > 254 {
            return Err(crate::types::Error::Validation {
                field: "email".to_string(),
                message: "Email must not be empty and under 254 characters".to_string(),
            });
        }

        let at_position = match email_str.find('@') {
            Some(pos) => pos,
            None => {
                return Err(crate::types::Error::Validation {
                    field: "email".to_string(),
                    message: "Email must contain @ symbol".to_string(),
                })
            }
        };

        // Must have at least one character before @
        if at_position == 0 {
            return Err(crate::types::Error::Validation {
                field: "email".to_string(),
                message: "Email must have at least one character before @".to_string(),
            });
        }

        // Check domain part (after @)
        let domain = &email_str[at_position + 1..];

        // Domain must contain at least one dot and not start/end with dot
        if domain.is_empty() {
            return Err(crate::types::Error::Validation {
                field: "email".to_string(),
                message: "Email domain cannot be empty".to_string(),
            });
        }

        if !domain.contains('.') {
            return Err(crate::types::Error::Validation {
                field: "email".to_string(),
                message: "Email domain must contain at least one dot".to_string(),
            });
        }

        if domain.starts_with('.') || domain.ends_with('.') {
            return Err(crate::types::Error::Validation {
                field: "email".to_string(),
                message: "Email domain cannot start or end with a dot".to_string(),
            });
        }

        if !domain
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '.' || c == '-')
        {
            return Err(crate::types::Error::Validation {
                field: "email".to_string(),
                message: "Email domain can only contain alphanumeric characters, dots, and hyphens"
                    .to_string(),
            });
        }

        Ok(())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Type)]
#[sqlx(transparent)]
pub struct Url(String);

impl Deref for Url {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<Inner> Wrapped<Inner> for Url
where
    Inner: Display + ToString + Debug,
{
    type Error = crate::types::Error;

    fn new(inner: Inner) -> Result<Self, Self::Error>
where {
        let url_str = inner.to_string();
        let url = Self(url_str);

        url.validate().map(|_| url)
    }

    fn raw(inner: Inner) -> Self {
        Self(inner.to_string())
    }
}

impl Validate for Url {
    fn validate(&self) -> Result<(), crate::types::Error> {
        // Simple URL validation
        // Check for http:// or https://
        let url_str = self.0.as_str();

        if url_str.is_empty() {
            return Err(crate::types::Error::Validation {
                field: "url".to_string(),
                message: "URL cannot be empty".to_string(),
            });
        }

        if url_str.len() > 2048 {
            return Err(crate::types::Error::Validation {
                field: "url".to_string(),
                message: "URL length exceeds 2048 characters".to_string(),
            });
        }

        if !url_str.starts_with("http://") && !url_str.starts_with("https://") {
            return Err(crate::types::Error::Validation {
                field: "url".to_string(),
                message: "URL must start with http:// or https://".to_string(),
            });
        }

        Ok(())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Type)]
#[sqlx(transparent)]
pub struct TagName(String);

impl Deref for TagName {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<Inner> Wrapped<Inner> for TagName
where
    Inner: Display + ToString + Debug,
{
    type Error = crate::types::Error;

    fn new(inner: Inner) -> Result<Self, Self::Error> {
        let tag_name = Self(inner.to_string());

        tag_name.validate().map(|_| tag_name)
    }

    fn raw(inner: Inner) -> Self {
        Self(inner.to_string())
    }
}

impl Validate for TagName {
    fn validate(&self) -> Result<(), crate::types::Error> {
        // Simple tag name validation
        // Check for alphanumeric characters and dashes
        let tag_name = self.0.as_str();

        if tag_name.is_empty() {
            return Err(crate::types::Error::Validation {
                field: "tag_name".to_string(),
                message: "Tag name cannot be empty".to_string(),
            });
        }

        if tag_name.len() > 64 {
            return Err(crate::types::Error::Validation {
                field: "tag_name".to_string(),
                message: "Tag name length exceeds 64 characters".to_string(),
            });
        }

        if !tag_name
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-')
        {
            return Err(crate::types::Error::Validation {
                field: "tag_name".to_string(),
                message: "Tag name can only contain alphanumeric characters and hyphens"
                    .to_string(),
            });
        }

        Ok(())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, Type)]
pub struct User {
    pub id: String,
    pub username: String,
    pub display_name: Option<String>,
    pub avatar_url: Url,
    pub bio: String,
    pub embedding: Option<Vec<f32>>, // pgvector type as Vec<f32>
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CreateUserRequest {
    pub id: String,
    pub username: String,
    pub display_name: Option<String>,
    pub avatar_url: Option<Url>,
    pub bio: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UpdateUserRequest {
    pub username: Option<String>,
    pub display_name: Option<String>,
    pub avatar_url: Option<Url>,
    pub bio: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserTag {
    pub id: i32,
    pub user_id: String,
    pub tag_name: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserLike {
    pub id: i32,
    pub user_id: String,
    pub target_user_id: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserDislike {
    pub id: i32,
    pub user_id: String,
    pub target_user_id: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserDislikeTag {
    pub id: i32,
    pub user_id: String,
    pub target_user_id: String,
    pub tag_name: TagName,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Tag {
    pub name: String,
    pub embedding: Option<Vec<f32>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct TagCount {
    pub tag_name: TagName,
    pub user_count: i64,
}
