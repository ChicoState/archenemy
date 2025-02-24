# Archenemy API Documentation

## Overview
This document describes the API endpoints for the Archenemy application. The server uses Firebase Authentication for user authentication and DigitalOcean Spaces for file storage.

## Base URL
TBD

## Authentication
All protected endpoints require a Firebase Authentication token in the Authorization header:
```
Authorization: Bearer <firebase_token>
```

## Storage API Endpoints

### Upload File
Upload a file to the storage service.

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
    "filename": "123e4567-e89b-12d3-a456-426614174000"
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
- `S3`: Storage service-related errors
- `MultipartParse`: File upload parsing errors
- `Unknown`: Unexpected errors

## Environment Variables
The following environment variables are required (it should be loaded by rocket):
- `FIREBASE_AUTH_PROJECT_ID`: Firebase project ID
- `STORAGE_ACCESS_ID`: DigitalOcean Spaces access ID
- `STORAGE_ACCESS_TOKEN`: DigitalOcean Spaces access token

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

## Future Enhancements
- [ ] Implement file type validation
- [ ] Add file size limits
- [ ] Support multiple file uploads
- [ ] Add file deletion endpoint
- [ ] Implement proper authentication checks
- [ ] Add file metadata support
