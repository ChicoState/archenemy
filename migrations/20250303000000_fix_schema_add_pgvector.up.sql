-- Install pgvector extension if not already installed
CREATE EXTENSION IF NOT EXISTS vector;

-- Fix the type mismatch in foreign keys by modifying tables 
-- First, drop foreign key constraints
ALTER TABLE UserTags DROP CONSTRAINT IF EXISTS usertags_user_id_fkey;
ALTER TABLE UserLikes DROP CONSTRAINT IF EXISTS userlikes_user_id_fkey;
ALTER TABLE UserLikes DROP CONSTRAINT IF EXISTS userlikes_target_user_id_fkey;
ALTER TABLE UserDislikes DROP CONSTRAINT IF EXISTS userdislikes_user_id_fkey;
ALTER TABLE UserDislikes DROP CONSTRAINT IF EXISTS userdislikes_target_user_id_fkey;

-- Drop indexes since we'll be changing column types
DROP INDEX IF EXISTS idx_usertags_user_id;
DROP INDEX IF EXISTS idx_userlikes_user_id;
DROP INDEX IF EXISTS idx_userlikes_target_user_id;
DROP INDEX IF EXISTS idx_userdislikes_user_id;
DROP INDEX IF EXISTS idx_userdislikes_target_user_id;

-- Change column types to match Users.id (VARCHAR)
ALTER TABLE Users ALTER COLUMN id TYPE VARCHAR(128);
ALTER TABLE UserTags ALTER COLUMN user_id TYPE VARCHAR(128);
ALTER TABLE UserLikes ALTER COLUMN user_id TYPE VARCHAR(128);
ALTER TABLE UserLikes ALTER COLUMN target_user_id TYPE VARCHAR(128);
ALTER TABLE UserDislikes ALTER COLUMN user_id TYPE VARCHAR(128);
ALTER TABLE UserDislikes ALTER COLUMN target_user_id TYPE VARCHAR(128);

-- Re-add foreign key constraints
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

-- Add embedding vector to Users table for recommendation system
ALTER TABLE Users ADD COLUMN IF NOT EXISTS embedding vector(384);

-- Add embedding vector to Tags table for semantic tag matching
ALTER TABLE Tags ADD COLUMN IF NOT EXISTS embedding vector(384);

-- Add timestamps to track when records were created and updated
ALTER TABLE Users 
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE UserTags 
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE UserLikes 
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE UserDislikes 
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Rename some columns in Users table for clarity
ALTER TABLE Users RENAME COLUMN name TO username;
ALTER TABLE Users RENAME COLUMN profile_picture TO avatar_url;
ALTER TABLE Users RENAME COLUMN profile_desc TO bio;

-- Set default for avatar_url column
ALTER TABLE Users ALTER COLUMN avatar_url SET DEFAULT 'https://archenemy.nyc3.digitaloceanspaces.com/default.jpeg';

-- Add display_name column which can be different from username
ALTER TABLE Users ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);

-- Update existing null avatar_url values to use default
UPDATE Users SET avatar_url = 'https://archenemy.nyc3.digitaloceanspaces.com/default.jpeg' WHERE avatar_url IS NULL OR avatar_url = '';

-- Create a tags count materialized view for quick access to popular tags
CREATE MATERIALIZED VIEW tag_counts AS
SELECT tag_name, COUNT(*) as user_count
FROM UserTags
GROUP BY tag_name
ORDER BY user_count DESC;

-- Create index for tag_counts
CREATE UNIQUE INDEX ON tag_counts(tag_name);

-- Create UserDislikeTags table for more granular dislike feedback
CREATE TABLE IF NOT EXISTS UserDislikeTags (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    target_user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    tag_name VARCHAR(255) NOT NULL REFERENCES Tags(name) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, target_user_id, tag_name),
    CHECK (user_id != target_user_id)
);

-- Create indexes for performance
CREATE INDEX idx_usertags_user_id ON UserTags(user_id);
CREATE INDEX idx_usertags_tag_name ON UserTags(tag_name);
CREATE INDEX idx_userlikes_user_id ON UserLikes(user_id);
CREATE INDEX idx_userlikes_target_user_id ON UserLikes(target_user_id);
CREATE INDEX idx_userdislikes_user_id ON UserDislikes(user_id);
CREATE INDEX idx_userdislikes_target_user_id ON UserDislikes(target_user_id);
CREATE INDEX idx_userdisliketags_user_id ON UserDislikeTags(user_id);
CREATE INDEX idx_userdisliketags_target_user_id ON UserDislikeTags(target_user_id);
CREATE INDEX idx_userdisliketags_tag_name ON UserDislikeTags(tag_name);

-- Create indexes for vector similarity search
CREATE INDEX users_embedding_idx ON Users USING hnsw (embedding vector_cosine_ops);
CREATE INDEX tags_embedding_idx ON Tags USING hnsw (embedding vector_cosine_ops);

