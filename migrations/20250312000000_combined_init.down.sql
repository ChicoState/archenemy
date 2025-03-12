-- Drop indexes first
DROP INDEX IF EXISTS users_embedding_idx;
DROP INDEX IF EXISTS tags_embedding_idx;
DROP INDEX IF EXISTS idx_userdisliketags_tag_name;
DROP INDEX IF EXISTS idx_userdisliketags_target_user_id;
DROP INDEX IF EXISTS idx_userdisliketags_user_id;
DROP INDEX IF EXISTS idx_userdislikes_target_user_id;
DROP INDEX IF EXISTS idx_userdislikes_user_id;
DROP INDEX IF EXISTS idx_userlikes_target_user_id;
DROP INDEX IF EXISTS idx_userlikes_user_id;
DROP INDEX IF EXISTS idx_usertags_tag_name;
DROP INDEX IF EXISTS idx_usertags_user_id;

-- Drop the materialized view
DROP MATERIALIZED VIEW IF EXISTS tag_counts;

-- Drop tables in correct order to respect foreign key constraints
DROP TABLE IF EXISTS UserDislikeTags;
DROP TABLE IF EXISTS UserDislikes;
DROP TABLE IF EXISTS UserLikes;
DROP TABLE IF EXISTS UserTags;
DROP TABLE IF EXISTS Tags;
DROP TABLE IF EXISTS Users;

-- Drop vector extension (only if not used elsewhere)
-- Note: Uncomment if you want to completely remove the extension
-- DROP EXTENSION IF EXISTS vector;