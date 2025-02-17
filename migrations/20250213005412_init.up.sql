-- Add up migration script here

CREATE TABLE Users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(255) NOT NULL,
    profile_desc TEXT NOT NULL
);

CREATE TABLE Tags (
    name VARCHAR(255) PRIMARY KEY
);

CREATE TABLE UserTags (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    tag_name VARCHAR(255) NOT NULL REFERENCES Tags(name) ON DELETE CASCADE,
    UNIQUE(user_id, tag_name)
);

CREATE TABLE UserLikes (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    target_user_id INT NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    UNIQUE(user_id, target_user_id),
    CHECK (user_id != target_user_id)
);

CREATE TABLE UserDislikes (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    target_user_id INT NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    UNIQUE(user_id, target_user_id),
    CHECK (user_id != target_user_id)
);

-- Create indexes for foreign keys to improve query performance
CREATE INDEX idx_usertags_user_id ON UserTags(user_id);
CREATE INDEX idx_usertags_tag_name ON UserTags(tag_name);
CREATE INDEX idx_userlikes_user_id ON UserLikes(user_id);
CREATE INDEX idx_userlikes_target_user_id ON UserLikes(target_user_id);
CREATE INDEX idx_userdislikes_user_id ON UserDislikes(user_id);
CREATE INDEX idx_userdislikes_target_user_id ON UserDislikes(target_user_id);
