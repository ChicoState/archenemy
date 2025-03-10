# Archenemy API Documentation

## Overview
This document describes the API endpoints for the Archenemy application, a platform for finding nemeses rather than matches. The server uses Firebase Authentication for user authentication and DigitalOcean Spaces for file storage.

## Base URL
TBD

## Authentication
All protected endpoints require a Firebase Authentication token in the Authorization header:
```
Authorization: Bearer <firebase_token>
```

## User API Endpoints

### Get Current User Profile
Retrieves the current user's profile based on authentication information. Creates a new profile if one doesn't exist. (Authentication required)

```http
GET /user/me
```

#### Response
```json
{
  "id": "string",
  "username": "string",
  "display_name": "string|null",
  "avatar_url": "string",
  "bio": "string",
  "embedding": "float[]|null",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Get User Profile
Get a user profile based on their ID. (Authentication required)

```http
GET /user/{userID}
```

#### Parameters
- `userID`: The ID of the user to retrieve

#### Response
```json
{
  "id": "string",
  "username": "string",
  "display_name": "string|null",
  "avatar_url": "string",
  "bio": "string",
  "embedding": "float[]|null",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Update Current User Profile
Update the current user's profile. (Authentication required)

```http
PATCH /user/me
Content-Type: application/json

{
  "username": "string?",
  "display_name": "string?",
  "avatar_url": "string?",
  "bio": "string?"
}
```

#### Response
```json
{
  "id": "string",
  "username": "string",
  "display_name": "string|null",
  "avatar_url": "string",
  "bio": "string",
  "embedding": "float[]|null",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## Tag API Endpoints

### Get All Tags
Get a list of all available tags with usage counts. (Authentication required)

```http
GET /tags
```

#### Response
```json
[
  {
    "tag_name": "string",
    "user_count": "integer"
  }
]
```

### Get User Tags
Get all tags associated with a user. (Authentication required)

```http
GET /user/{userID}/tags
```

#### Parameters
- `userID`: The ID of the user whose tags to retrieve

#### Response
```json
[
  {
    "id": "integer",
    "user_id": "string",
    "tag_name": "string",
    "created_at": "timestamp"
  }
]
```

### Add User Tag
Add a tag to the current user's profile. (Authentication required)

```http
POST /user/me/tags
Content-Type: application/json

{
  "tag_name": "string"
}
```

#### Response
```json
{
  "id": "integer",
  "user_id": "string",
  "tag_name": "string",
  "created_at": "timestamp"
}
```

### Remove User Tag
Remove a tag from the current user's profile. (Authentication required)

```http
DELETE /user/me/tags/{tagName}
```

#### Parameters
- `tagName`: The name of the tag to remove

#### Response
Status code 204 (No Content) if successful

## Nemesis API Endpoints

### Get Potential Nemeses
Get a list of potential nemeses based on tag mismatches or similarity scoring. (Authentication required)

```http
GET /nemeses/discover
```

#### Query Parameters
- `limit`: Maximum number of results to return (default: 10)
- `offset`: Number of results to skip (default: 0)

#### Response
```json
[
  {
    "id": "string",
    "username": "string",
    "display_name": "string",
    "avatar_url": "string",
    "bio": "string",
    "tags": [
      {
        "id": "integer",
        "user_id": "string",
        "tag_name": "string",
        "created_at": "timestamp"
      }
    ],
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "compatibility_score": "float"
  }
]
```

### Like a User
Mark a user as someone you dislike. (Authentication required)

```http
POST /nemeses/like/{userID}
```

#### Parameters
- `userID`: The ID of the user to like

#### Response
```json
{
  "id": "integer",
  "user_id": "string",
  "target_user_id": "string",
  "created_at": "timestamp"
}
```

### Dislike a User
Mark a user as someone you dislike. (Authentication required)

```http
POST /nemeses/dislike/{userID}
```

#### Parameters
- `userID`: The ID of the user to dislike

#### Response
```json
{
  "id": "integer",
  "user_id": "string",
  "target_user_id": "string",
  "created_at": "timestamp"
}
```

### Dislike a User with Tags
Mark a user as someone you dislike for specific reasons (tags). (Authentication required)

```http
POST /nemeses/dislike/{userID}/tags
Content-Type: application/json

{
  "tag_names": ["string", "string"]
}
```

#### Parameters
- `userID`: The ID of the user to dislike
- `tag_names`: Array of tag names representing reasons for disliking

#### Response
```json
[
  {
    "id": "integer",
    "user_id": "string",
    "target_user_id": "string",
    "tag_name": "string",
    "created_at": "timestamp"
  }
]
```

### Get Liked Users
Get a list of users the current user has liked. (Authentication required)

```http
GET /nemeses/likes
```

#### Query Parameters
- `limit`: Maximum number of results to return (default: 10)
- `offset`: Number of results to skip (default: 0)

#### Response
```json
[
  {
    "id": "string",
    "username": "string",
    "display_name": "string",
    "avatar_url": "string",
    "bio": "string",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "liked_at": "timestamp"
  }
]
```

### Get Disliked Users
Get a list of users the current user has disliked. (Authentication required)

```http
GET /nemeses/dislikes
```

#### Query Parameters
- `limit`: Maximum number of results to return (default: 10)
- `offset`: Number of results to skip (default: 0)

#### Response
```json
[
  {
    "id": "string",
    "username": "string",
    "display_name": "string",
    "avatar_url": "string",
    "bio": "string",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "disliked_at": "timestamp",
    "dislike_tags": [
      {
        "id": "integer",
        "user_id": "string",
        "target_user_id": "string",
        "tag_name": "string",
        "created_at": "timestamp"
      }
    ]
  }
]
```

## Storage API Endpoints

### Upload File
Upload a file to the storage service. (Authentication required)

```http
PUT /storage
Content-Type: multipart/form-data
```

#### Request
- **Method**: PUT
- **Content-Type**: multipart/form-data
- **Body Parameters**:
  - `file`: The file to upload (required)

#### Response
```json
{
  "filename": "string",
  "url": "string"
}
```

#### Status Codes
- `200 OK`: File uploaded successfully
- `400 Bad Request`: Invalid multipart form data
- `401 Unauthorized`: Missing or invalid authentication
- `500 Internal Server Error`: Storage service error

### Get File
Retrieve a file from the storage service.

```http
GET /storage/{object}
```

#### Parameters
- `object`: The UUID of the file to retrieve (required)

#### Response
- **Content-Type**: Based on the file type
- **Body**: Raw file contents

#### Status Codes
- `200 OK`: File retrieved successfully
- `401 Unauthorized`: Missing or invalid authentication
- `404 Not Found`: File not found
- `500 Internal Server Error`: Storage service error

## Error Responses
All error responses follow this format:
```json
{
  "type": "error_type",
  "msg": "Error message details"
}
```

### Error Types
- `Unauthenticated`: Authentication failed or token missing
- `NotFound`: Requested resource not found
- `Validation`: Invalid input data
- `Duplicate`: Resource already exists
- `S3`: Storage service-related errors
- `MultipartParse`: File upload parsing errors
- `Database`: Database-related errors
- `Unknown`: Unexpected errors

## Types

### User
```json
{
  "id": "string",
  "username": "string",
  "display_name": "string|null",
  "avatar_url": "string",
  "bio": "string",
  "embedding": "float[]|null",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Tag
```json
{
  "tag_name": "string",
  "user_count": "integer"
}
```

### UserTag
```json
{
  "id": "integer",
  "user_id": "string",
  "tag_name": "string", 
  "created_at": "timestamp"
}
```

### UserLike
```json
{
  "id": "integer",
  "user_id": "string",
  "target_user_id": "string",
  "created_at": "timestamp"
}
```

### UserDislike
```json
{
  "id": "integer",
  "user_id": "string",
  "target_user_id": "string",
  "created_at": "timestamp"
}
```

### UserDislikeTag
```json
{
  "id": "integer",
  "user_id": "string",
  "target_user_id": "string",
  "tag_name": "string",
  "created_at": "timestamp"
}
```

## Environment Variables
The following environment variables are required (it should be loaded by rocket):
- `FIREBASE_AUTH_PROJECT_ID`: Firebase project ID
- `STORAGE_ACCESS_ID`: DigitalOcean Spaces access ID
- `STORAGE_ACCESS_TOKEN`: DigitalOcean Spaces access token
- `DATABASE_URL`: PostgreSQL database connection string

## Storage Details
- Storage Provider: DigitalOcean Spaces
- Bucket Name: archenemy
- Region: nyc3
- Base URL: https://archenemy.nyc3.digitaloceanspaces.com

## Notes
- File uploads generate a UUID v4 for the filename
- Currently, only single file uploads are supported
- All files are stored in the root of the storage bucket
- Authentication middleware is in place but currently passes all requests (placeholder for future implementation)
- User embeddings are 1536-dimensional vectors used for similarity matching

## Tag Embeddings API

### Get Nemesis Tags
Get tags that are semantically opposite to a given tag (using vector embeddings). (Authentication required)

```http
GET /tags/{tagName}/nemesis
```

#### Parameters
- `tagName`: The name of the tag to find semantic opposites for

#### Query Parameters
- `limit`: Maximum number of results to return (default: 10)

#### Response
```json
[
  {
    "tag_name": "string",
    "nemesis_score": "float"
  }
]
```

## Future Enhancements
- [ ] Implement file type validation
- [ ] Add file size limits
- [ ] Support multiple file uploads
- [ ] Add file deletion endpoint
- [ ] Implement proper authentication checks
- [ ] Add file metadata support
- [ ] Add mutual nemesis discovery
- [x] Implement recommendation system based on embeddings
- [ ] Add pagination for list endpoints
- [ ] Create admin endpoints for moderation
- [ ] Improve nemesis tag discovery algorithm
