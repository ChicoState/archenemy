-- Install pgvector extension if not already installed
CREATE EXTENSION IF NOT EXISTS vector;

-- Create tables with correct types from the beginning
CREATE TABLE Users (
    id VARCHAR(128) PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255) NOT NULL DEFAULT 'https://archenemy.nyc3.digitaloceanspaces.com/default.jpeg',
    bio TEXT NOT NULL,
    display_name VARCHAR(255),
    embedding vector(384),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE Tags (
    name VARCHAR(255) PRIMARY KEY,
    embedding vector(384)
);

CREATE TABLE UserTags (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    tag_name VARCHAR(255) NOT NULL REFERENCES Tags(name) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, tag_name)
);

CREATE TABLE UserLikes (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    target_user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, target_user_id),
    CHECK (user_id::text != target_user_id::text)
);

CREATE TABLE UserDislikes (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    target_user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, target_user_id),
    CHECK (user_id::text != target_user_id::text)
);

-- Create UserDislikeTags table for more granular dislike feedback
CREATE TABLE UserDislikeTags (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    target_user_id VARCHAR(128) NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    tag_name VARCHAR(255) NOT NULL REFERENCES Tags(name) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, target_user_id, tag_name),
    CHECK (user_id::text != target_user_id::text)
);

-- Create a tags count materialized view for quick access to popular tags
CREATE MATERIALIZED VIEW tag_counts AS
SELECT tag_name, COUNT(*) as user_count
FROM UserTags
GROUP BY tag_name
ORDER BY user_count DESC;

-- Create index for tag_counts
CREATE UNIQUE INDEX ON tag_counts(tag_name);

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