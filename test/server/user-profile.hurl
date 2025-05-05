# Check authorization
GET {{host}}/api/v1/user/me

HTTP 401

# Check create user profile if not exists
GET {{host}}/api/v1/user/me
Authorization: Bearer user-profile-test-user1
HTTP 200
[Captures]
response: body
[Asserts]
jsonpath "$.id" == "user-profile-test-user1"

# Check not found user profile
GET {{host}}/api/v1/user/user-profile-test-user2
Authorization: Bearer user-profile-test-user2
HTTP 404

# Check created user profile
GET {{host}}/api/v1/user/user-profile-test-user1
Authorization: Bearer user-profile-test-user2
HTTP 200
[Asserts]
body == {{response}}

# Update user profile
PUT {{host}}/api/v1/user/me
Authorization: Bearer user-profile-test-user1
{
    "username": "user-profile-test-user1",
    "display_name": "user1",
    "bio": "This is a test bio for user1"
}
HTTP 200
[Asserts]
jsonpath "$.id" == "user-profile-test-user1"
jsonpath "$.display_name" == "user1"
jsonpath "$.username" == "user-profile-test-user1"
jsonpath "$.bio" == "This is a test bio for user1"

# Update user avatar (without changing username)
PUT {{host}}/api/v1/user/me
Authorization: Bearer user-profile-test-user1
{
    "avatar_url": "https://example.com/avatar.jpg"
}
HTTP 200
[Asserts]
jsonpath "$.id" == "user-profile-test-user1"
jsonpath "$.avatar_url" == "https://example.com/avatar.jpg"

# Test updating user profile with invalid data (empty username)
PUT {{host}}/api/v1/user/me
Authorization: Bearer user-profile-test-user1
{
    "username": "",
    "display_name": "user1"
}
HTTP 400
[Asserts]
jsonpath "$.Validation.field" == "username"

# Test clearing display_name with null (null wouldn't change anything, acting same as undefined)
PUT {{host}}/api/v1/user/me
Authorization: Bearer user-profile-test-user1
{
    "display_name": null
}
HTTP 200
[Asserts]
jsonpath "$.id" == "user-profile-test-user1"
jsonpath "$.display_name" == "user1"
