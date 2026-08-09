-- ============================================================
-- PAGE 2: PRODUCT & FEATURE ENGAGEMENT
-- Dashboard: Canvas Pulse - ImagineArt Analytics
-- Tables used: imagineart_generations, imagineart_sessions_events
-- Filters: Date Range, Feature, AI Model, Plan Tier
-- ============================================================


-- ------------------------------------------------------------
-- KPI 1: Total Generations
-- Visualization: Number
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_generations
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{feature_filter}}]]
[[AND {{model_filter}}]]
[[AND {{plan_tier_filter}}]];

-- Field Filter mapping:
--   date_filter       -> imagineart_generations.event_date
--   feature_filter    -> imagineart_generations.feature
--   model_filter      -> imagineart_generations.ai_model_used
--   plan_tier_filter  -> imagineart_generations.plan_tier


-- ------------------------------------------------------------
-- KPI 2: Success Rate (%)
-- Visualization: Number (percentage)
-- Note: do NOT multiply by 100 in SQL -- Metabase's Percentage
-- formatting handles that conversion. Multiplying here as well
-- causes a doubled result (e.g. 1625% instead of 16.25%).
-- ------------------------------------------------------------
SELECT
    ROUND(
        1.0 * SUM(CASE WHEN generation_status = 'success' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
    , 4) AS success_rate
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{feature_filter}}]]
[[AND {{model_filter}}]]
[[AND {{plan_tier_filter}}]];

-- Field Filter mapping: same as KPI 1


-- ------------------------------------------------------------
-- KPI 3: Average Generation Time (seconds)
-- Visualization: Number (suffix: "sec")
-- ------------------------------------------------------------
SELECT ROUND(AVG(generation_time_seconds), 2) AS avg_generation_time_seconds
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{feature_filter}}]]
[[AND {{model_filter}}]]
[[AND {{plan_tier_filter}}]];

-- Field Filter mapping: same as KPI 1


-- ------------------------------------------------------------
-- KPI 4: Export Rate (%)
-- Visualization: Number (percentage)
-- ------------------------------------------------------------
SELECT
    ROUND(
        1.0 * SUM(CASE WHEN exported = TRUE THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
    , 4) AS export_rate
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{feature_filter}}]]
[[AND {{model_filter}}]]
[[AND {{plan_tier_filter}}]];

-- Field Filter mapping: same as KPI 1


-- ------------------------------------------------------------
-- CHART 1: Generations by Feature
-- Visualization: Horizontal bar chart
-- ------------------------------------------------------------
SELECT
    feature,
    COUNT(*) AS generation_count
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{model_filter}}]]
[[AND {{plan_tier_filter}}]]
GROUP BY feature
ORDER BY generation_count DESC;

-- Field Filter mapping:
--   date_filter       -> imagineart_generations.event_date
--   model_filter      -> imagineart_generations.ai_model_used
--   plan_tier_filter  -> imagineart_generations.plan_tier
-- Note: feature_filter intentionally excluded -- this chart's purpose
-- is to break results down BY feature.


-- ------------------------------------------------------------
-- CHART 2: AI Model Usage Share
-- Visualization: Pie / Donut chart
-- ------------------------------------------------------------
SELECT
    ai_model_used,
    COUNT(*) AS usage_count
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{feature_filter}}]]
[[AND {{plan_tier_filter}}]]
GROUP BY ai_model_used
ORDER BY usage_count DESC;

-- Field Filter mapping:
--   date_filter       -> imagineart_generations.event_date
--   feature_filter    -> imagineart_generations.feature
--   plan_tier_filter  -> imagineart_generations.plan_tier
-- Note: model_filter intentionally excluded -- same reasoning as Chart 1.


-- ------------------------------------------------------------
-- CHART 3: Generation Status by Feature (Failure Breakdown)
-- Visualization: Stacked bar chart
-- ------------------------------------------------------------
SELECT
    feature,
    generation_status,
    COUNT(*) AS event_count
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{model_filter}}]]
[[AND {{plan_tier_filter}}]]
GROUP BY feature, generation_status
ORDER BY feature;

-- Field Filter mapping: same as Chart 1
-- Chart settings: X = feature, Stack/Series = generation_status, Y = event_count


-- ------------------------------------------------------------
-- CHART 4: Daily Active Users Overview (DAU Trend)
-- Visualization: Line chart
-- ------------------------------------------------------------
SELECT
    event_date,
    COUNT(DISTINCT user_id) AS daily_active_users
FROM imagineart_sessions_events
WHERE event_type = 'app_open'
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
GROUP BY event_date
ORDER BY event_date;

-- Field Filter mapping:
--   date_filter       -> imagineart_sessions_events.event_date
--   plan_tier_filter  -> imagineart_sessions_events.plan_tier
-- Note: feature_filter and model_filter do not apply -- sessions_events
-- has no feature or ai_model_used columns.


-- ------------------------------------------------------------
-- CHART 5: Average Session Duration by Plan Tier
-- Visualization: Bar chart
-- ------------------------------------------------------------
SELECT
    plan_tier,
    ROUND(AVG(session_duration_seconds), 2) AS avg_duration_seconds
FROM imagineart_sessions_events
WHERE 1=1
[[AND {{date_filter}}]]
GROUP BY plan_tier
ORDER BY avg_duration_seconds DESC;

-- Field Filter mapping:
--   date_filter -> imagineart_sessions_events.event_date
-- Note: plan_tier_filter intentionally excluded -- this chart's purpose
-- is to break results down BY plan tier. feature_filter / model_filter
-- do not apply (no such columns on this table).
