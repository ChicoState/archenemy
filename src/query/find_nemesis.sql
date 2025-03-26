WITH user_tags AS (
    SELECT tag_name FROM UserTags WHERE user_id = $1
),
user_likes AS (
    SELECT target_user_id FROM UserLikes WHERE user_id = $1
),
user_dislikes AS (
    SELECT target_user_id FROM UserDislikes WHERE user_id = $1
),
-- Get user's tags with embeddings
user_tag_embeddings AS (
    SELECT t.name, t.embedding
    FROM Tags t
    JOIN UserTags ut ON t.name = ut.tag_name
    WHERE ut.user_id = $1 AND t.embedding IS NOT NULL
),
-- Get potential nemesis users' tags with embeddings
nemesis_tag_embeddings AS (
    SELECT ut.user_id, t.name, t.embedding
    FROM Tags t
    JOIN UserTags ut ON t.name = ut.tag_name
    WHERE ut.user_id != $1 
        AND ut.user_id NOT IN (SELECT target_user_id FROM user_likes)
        AND ut.user_id NOT IN (SELECT target_user_id FROM user_dislikes)
        AND t.embedding IS NOT NULL
),
-- Calculate tag embedding similarity scores for each potential nemesis
tag_similarity_scores AS (
    SELECT 
        nte.user_id,
        -- For each user, calculate average similarity between their tags and opposite of user's tags
        -- Higher score = more opposite tags (better nemesis match)
        AVG(
            CASE 
                WHEN ute.embedding IS NOT NULL AND nte.embedding IS NOT NULL THEN
                    -- Invert user tag embedding for opposite comparison
                    -- Scale to 0-1 range where 1 = perfect opposite
                    (1 - ((ute.embedding <=> nte.embedding) / 2))
                ELSE 0.5
            END
        ) AS tag_embedding_score
    FROM 
        nemesis_tag_embeddings nte
    CROSS JOIN 
        user_tag_embeddings ute
    GROUP BY 
        nte.user_id
),
-- Calculate combined score based on embedding similarity and tag overlap
user_scores AS (
    SELECT 
        u.id,
        (
            -- 1. User embedding similarity component (50%)
            -- Higher score = better nemesis match (more opposite)
            CASE
                WHEN u.embedding IS NOT NULL THEN 
                    -- Compare with negative embedding to find semantic opposites
                    -- Scale to 0-1 range where 1 = perfect nemesis
                    (1 - (u.embedding <=> $4::vector) / 2)
                ELSE 0.5 -- Default middle value if no embedding
            END * 0.5 -- 50% weight for user embedding
            
            +
            
            -- 2. Tag embedding similarity component (30%)
            -- Use the tag similarity scores calculated above
            COALESCE((
                SELECT tag_embedding_score 
                FROM tag_similarity_scores 
                WHERE user_id = u.id
            ), 0.5) * 0.3 -- 30% weight for tag embeddings
            
            +
            
            -- 3. Tag overlap component (20%)
            -- Lower = more overlap, we want the opposite
            -- Count percentage of non-matching tags
            (1 - COALESCE((
                SELECT COUNT(*)::float 
                FROM UserTags ut
                WHERE ut.user_id = u.id AND ut.tag_name IN (SELECT tag_name FROM user_tags)
            ), 0) / 
            NULLIF((
                SELECT COUNT(*)::float 
                FROM UserTags 
                WHERE user_id = u.id
            ), 1)) * 0.2 -- 20% weight for tag name overlap
        ) AS nemesis_score
    FROM 
        Users u
    WHERE 
        u.id != $1
        AND u.id NOT IN (SELECT target_user_id FROM user_likes)
        AND u.id NOT IN (SELECT target_user_id FROM user_dislikes)
)

SELECT 
    u.id, u.username, u.display_name, u.avatar_url as "avatar_url: Url", u.bio, u.created_at, u.updated_at, u.embedding as "embedding: Vector", 
    COALESCE(us.nemesis_score, 0.5) AS compatibility_score
FROM 
    Users u
LEFT JOIN 
    user_scores us ON u.id = us.id
WHERE 
    u.id != $1
    AND u.id NOT IN (SELECT target_user_id FROM user_likes)
    AND u.id NOT IN (SELECT target_user_id FROM user_dislikes)
ORDER BY 
    -- Order by nemesis score (highest first = most incompatible)
    compatibility_score DESC
LIMIT $2
OFFSET $3

