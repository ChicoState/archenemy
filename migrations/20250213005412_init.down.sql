-- Add down migration script here

-- Drop indexes first
DROP INDEX IF EXISTS idx_userdislikes_target_user_id;
DROP INDEX IF EXISTS idx_userdislikes_user_id;
DROP INDEX IF EXISTS idx_userlikes_target_user_id;
DROP INDEX IF EXISTS idx_userlikes_user_id;
DROP INDEX IF EXISTS idx_usertags_tag_name;
DROP INDEX IF EXISTS idx_usertags_user_id;

-- Drop tables in reverse order (to handle foreign key dependencies)
DROP TABLE IF EXISTS UserDislikes;
DROP TABLE IF EXISTS UserLikes;
DROP TABLE IF EXISTS UserTags;
DROP TABLE IF EXISTS Tags;
DROP TABLE IF EXISTS Users;
-- Add down migration script here
