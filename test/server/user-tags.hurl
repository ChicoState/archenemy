# First, ensure we have access to the API
GET {{host}}/api-docs/openapi.json
HTTP 200

# 1. Test authenticating as a test user
# We'll use dummy auth for testing

# Create or get current user
GET {{host}}/api/v1/user/me
Authorization: Bearer user-profile-test-user1
HTTP 200
[Captures]
user_id: jsonpath "$.id"
username: jsonpath "$.username"

# 2. Test getting all tags (should work even if empty at first)
GET {{host}}/api/v1/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$[*]" isCollection 

# 3. Test getting current user's tags (should be empty initially)
GET {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$" count == 0

# 4. Test adding a tag to the current user
POST {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
{
    "tag_name": "introvert"
}
HTTP 200
[Asserts]
jsonpath "$.tag_name" == "introvert"
jsonpath "$.user_id" == {{user_id}}
[Captures]
first_tag_id: jsonpath "$.id"

# 5. Add another tag
POST {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
{
    "tag_name": "coffee-lover"
}
HTTP 200
[Asserts]
jsonpath "$.tag_name" == "coffee-lover"
jsonpath "$.user_id" == {{user_id}}
[Captures]
second_tag_id: jsonpath "$.id"

# 6. Verify both tags appear in user's tags list
GET {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[*].tag_name" contains "introvert"
jsonpath "$[*].tag_name" contains "coffee-lover"

# 7. Verify tags are in the global tags list
GET {{host}}/api/v1/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$[*].tag_name" contains "introvert"
jsonpath "$[*].tag_name" contains "coffee-lover"

# 8. Try to add an empty tag (should fail)
POST {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
{
    "tag_name": ""
}
HTTP 400
[Asserts]
jsonpath "$.field" == "tag_name"

# 9. Find nemesis tags for "introvert"
GET {{host}}/api/v1/tags/introvert/nemesis
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$[*]" isCollection 

# 10. Test getting another user's tags
# First, get our user ID
GET {{host}}/api/v1/user/{{user_id}}/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$[*]" isCollection 
jsonpath "$" count == 2

# 11. Remove one tag
DELETE {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
["introvert"]
HTTP 204

# 12. Verify one tag was removed
GET {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$[*]" isCollection 
jsonpath "$" count == 2
jsonpath "$[0].tag_name" == "coffee-lover"
jsonpath "$[*].tag_name" not contains "introvert"

# 13. Add a tag that already exists (should work, but be idempotent)
POST {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
{
    "tag_name": "coffee-lover"
}
HTTP 200
[Asserts]
jsonpath "$.tag_name" == "coffee-lover"

# 14. Verify we still have only one tag (no duplication)
GET {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$[*]" isCollection 
jsonpath "$" count == 2

# 15. Remove all remaining tags
DELETE {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
["coffee-lover"]
HTTP 204

# 16. Verify all tags are removed
GET {{host}}/api/v1/user/me/tags
Authorization: Bearer user-profile-test-user1
HTTP 200
[Asserts]
jsonpath "$[*]" isCollection 
jsonpath "$" count == 0
