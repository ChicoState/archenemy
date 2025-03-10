-- Drop vector extension (only if not used elsewhere)
-- Note: Uncomment if you want to completely remove the extension
-- DROP EXTENSION IF EXISTS vector;

-- Drop indexes first
DROP INDEX IF EXISTS users_embedding_idx;
DROP INDEX IF EXISTS idx_userdisliketags_tag_name;
DROP INDEX IF EXISTS idx_userdisliketags_target_user_id;
DROP INDEX IF EXISTS idx_userdisliketags_user_id;
DROP INDEX IF EXISTS idx_userdislikes_target_user_id;
DROP INDEX IF EXISTS idx_userdislikes_user_id;
DROP INDEX IF EXISTS idx_userlikes_target_user_id;
DROP INDEX IF EXISTS idx_userlikes_user_id;
DROP INDEX IF EXISTS idx_usertags_user_id;

-- Drop the materialized view
DROP MATERIALIZED VIEW IF EXISTS tag_counts;

-- Drop UserDislikeTags table
DROP TABLE IF EXISTS UserDislikeTags;

-- Remove columns added to Users table
ALTER TABLE Users 
    DROP COLUMN IF EXISTS embedding,
    DROP COLUMN IF EXISTS created_at,
    DROP COLUMN IF EXISTS updated_at,
    DROP COLUMN IF EXISTS display_name;

-- Remove timestamp columns from other tables
ALTER TABLE UserTags DROP COLUMN IF EXISTS created_at;
ALTER TABLE UserLikes DROP COLUMN IF EXISTS created_at;
ALTER TABLE UserDislikes DROP COLUMN IF EXISTS created_at;

-- Rename columns back to original names
ALTER TABLE Users RENAME COLUMN username TO name;
ALTER TABLE Users RENAME COLUMN avatar_url TO profile_picture;
ALTER TABLE Users RENAME COLUMN bio TO profile_desc;

-- Drop foreign key constraints
ALTER TABLE UserTags DROP CONSTRAINT IF EXISTS usertags_user_id_fkey;
ALTER TABLE UserLikes DROP CONSTRAINT IF EXISTS userlikes_user_id_fkey;
ALTER TABLE UserLikes DROP CONSTRAINT IF EXISTS userlikes_target_user_id_fkey;
ALTER TABLE UserDislikes DROP CONSTRAINT IF EXISTS userdislikes_user_id_fkey;
ALTER TABLE UserDislikes DROP CONSTRAINT IF EXISTS userdislikes_target_user_id_fkey;

-- Change column types back to INT
ALTER TABLE Users ALTER COLUMN id TYPE INT USING (id::integer);
ALTER TABLE UserTags ALTER COLUMN user_id TYPE INT USING (user_id::integer);
ALTER TABLE UserLikes ALTER COLUMN user_id TYPE INT USING (user_id::integer);
ALTER TABLE UserLikes ALTER COLUMN target_user_id TYPE INT USING (target_user_id::integer);
ALTER TABLE UserDislikes ALTER COLUMN user_id TYPE INT USING (user_id::integer);
ALTER TABLE UserDislikes ALTER COLUMN target_user_id TYPE INT USING (target_user_id::integer);

-- Re-add foreign key constraints (even though they're incorrect - this is a rollback to original state)
ALTER TABLE UserTags 
    ADD CONSTRAINT usertags_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE;

ALTER TABLE UserLikes 
    ADD CONSTRAINT userlikes_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE;

ALTER TABLE UserLikes 
    ADD CONSTRAINT userlikes_target_user_id_fkey 
    FOREIGN KEY (target_user_id) REFERENCES Users(id) ON DELETE CASCADE;

ALTER TABLE UserDislikes 
    ADD CONSTRAINT userdislikes_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE;

ALTER TABLE UserDislikes 
    ADD CONSTRAINT userdislikes_target_user_id_fkey 
    FOREIGN KEY (target_user_id) REFERENCES Users(id) ON DELETE CASCADE;

-- Recreate indexes
CREATE INDEX idx_usertags_user_id ON UserTags(user_id);
CREATE INDEX idx_userlikes_user_id ON UserLikes(user_id);
CREATE INDEX idx_userlikes_target_user_id ON UserLikes(target_user_id);
CREATE INDEX idx_userdislikes_user_id ON UserDislikes(user_id);
CREATE INDEX idx_userdislikes_target_user_id ON UserDislikes(target_user_id);

