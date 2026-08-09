-- ============================================================
-- PAGE 4: RETENTION, SENTIMENT & COMMUNITY
-- Dashboard: Canvas Pulse - ImagineArt Analytics
-- Tables used: imagineart_ratings_reviews, imagineart_community_engagement
-- Filters: Date (Retention), Plan Tier (Retention), Platform (Retention)
-- ============================================================


-- ------------------------------------------------------------
-- KPI 1: Average Rating
-- Visualization: Number (gauge optional)
-- ------------------------------------------------------------
SELECT ROUND(AVG(imagineart_ratings_reviews.rating), 2) AS average_rating
FROM imagineart_ratings_reviews
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{platform_filter}}]];

-- Field Filter mapping:
--   date_filter       -> imagineart_ratings_reviews.review_date
--   plan_tier_filter  -> imagineart_ratings_reviews.plan_tier
--   platform_filter   -> imagineart_ratings_reviews.platform


-- ------------------------------------------------------------
-- KPI 2: Negative Review Rate (%) -- rating <= 2
-- Visualization: Number (percentage)
-- ------------------------------------------------------------
SELECT
    ROUND(100.0 * SUM(CASE WHEN imagineart_ratings_reviews.rating <= 2 THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 2) AS negative_review_rate_percent
FROM imagineart_ratings_reviews
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{platform_filter}}]];

-- Field Filter mapping: same as KPI 1


-- ------------------------------------------------------------
-- KPI 3: Total Community Posts
-- Visualization: Number
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_community_posts
FROM imagineart_community_engagement
WHERE 1=1
[[AND {{date_filter}}]];

-- Field Filter mapping:
--   date_filter -> imagineart_community_engagement.post_date
-- Note: plan_tier_filter / platform_filter do not apply -- this table
-- has no such columns.


-- ------------------------------------------------------------
-- KPI 4: Total Follows Gained
-- Visualization: Number
-- ------------------------------------------------------------
SELECT SUM(imagineart_community_engagement.follows_gained) AS total_follows_gained
FROM imagineart_community_engagement
WHERE 1=1
[[AND {{date_filter}}]];

-- Field Filter mapping: same as KPI 3


-- ------------------------------------------------------------
-- CHART 1: Rating Distribution
-- Visualization: Bar chart
-- ------------------------------------------------------------
SELECT
    imagineart_ratings_reviews.rating,
    COUNT(*) AS review_count
FROM imagineart_ratings_reviews
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{platform_filter}}]]
GROUP BY imagineart_ratings_reviews.rating
ORDER BY imagineart_ratings_reviews.rating;

-- Field Filter mapping: same as KPI 1


-- ------------------------------------------------------------
-- CHART 2: Negative Sentiment Themes
-- Visualization: Horizontal bar chart
-- ------------------------------------------------------------
SELECT
    imagineart_ratings_reviews.sentiment_theme,
    COUNT(*) AS theme_count
FROM imagineart_ratings_reviews
WHERE imagineart_ratings_reviews.rating <= 2
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{platform_filter}}]]
GROUP BY imagineart_ratings_reviews.sentiment_theme
ORDER BY theme_count DESC;

-- Field Filter mapping: same as KPI 1


-- ------------------------------------------------------------
-- CHART 3: Rating by Plan Tier
-- Visualization: Bar chart
-- ------------------------------------------------------------
SELECT
    imagineart_ratings_reviews.plan_tier,
    ROUND(AVG(imagineart_ratings_reviews.rating), 2) AS avg_rating
FROM imagineart_ratings_reviews
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{platform_filter}}]]
GROUP BY imagineart_ratings_reviews.plan_tier
ORDER BY avg_rating DESC;

-- Field Filter mapping:
--   date_filter     -> imagineart_ratings_reviews.review_date
--   platform_filter -> imagineart_ratings_reviews.platform
-- Note: plan_tier_filter intentionally excluded -- this chart's purpose
-- is to break results down BY plan tier.


-- ------------------------------------------------------------
-- CHART 4: Community Posts Over Time
-- Visualization: Line chart
-- ------------------------------------------------------------
SELECT
    imagineart_community_engagement.post_date,
    COUNT(*) AS post_count
FROM imagineart_community_engagement
WHERE 1=1
[[AND {{date_filter}}]]
GROUP BY imagineart_community_engagement.post_date
ORDER BY imagineart_community_engagement.post_date;

-- Field Filter mapping:
--   date_filter -> imagineart_community_engagement.post_date


-- ------------------------------------------------------------
-- CHART 5: Top Features by Likes
-- Visualization: Bar chart
-- ------------------------------------------------------------
SELECT
    imagineart_community_engagement.feature,
    SUM(imagineart_community_engagement.likes) AS total_likes
FROM imagineart_community_engagement
WHERE 1=1
[[AND {{date_filter}}]]
GROUP BY imagineart_community_engagement.feature
ORDER BY total_likes DESC;

-- Field Filter mapping:
--   date_filter -> imagineart_community_engagement.post_date
