-- ============================================================
-- PAGE 1: ACQUISITION & GROWTH
-- Dashboard: Canvas Pulse - ImagineArt Analytics
-- Tables used: imagineart_users, imagineart_ad_campaigns
-- Filters: Date Range, Acquisition Channel, Country
-- ============================================================


-- ------------------------------------------------------------
-- KPI 1: Total Users
-- Visualization: Number
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_users
FROM imagineart_users
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{channel_filter}}]]
[[AND {{country_filter}}]];

-- Field Filter mapping:
--   date_filter    -> imagineart_users.signup_date
--   channel_filter -> imagineart_users.acquisition_channel
--   country_filter -> imagineart_users.country


-- ------------------------------------------------------------
-- KPI 2: Total Ad Spend
-- Visualization: Number (currency)
-- ------------------------------------------------------------
SELECT SUM(spend_usd) AS total_ad_spend
FROM imagineart_ad_campaigns
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{channel_filter}}]];

-- Field Filter mapping:
--   date_filter    -> imagineart_ad_campaigns.week_start
--   channel_filter -> imagineart_ad_campaigns.acquisition_channel
-- Note: no country column exists on this table, so country_filter does not apply here.


-- ------------------------------------------------------------
-- KPI 3: Blended CPA (Cost Per Acquisition)
-- Visualization: Number (currency)
-- ------------------------------------------------------------
SELECT ROUND(SUM(spend_usd) / NULLIF(SUM(installs), 0), 2) AS blended_cpa
FROM imagineart_ad_campaigns
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{channel_filter}}]];

-- Field Filter mapping: same as KPI 2


-- ------------------------------------------------------------
-- KPI 4: Average CTR (%)
-- Visualization: Number (percentage)
-- ------------------------------------------------------------
SELECT ROUND(100.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 2) AS avg_ctr_percent
FROM imagineart_ad_campaigns
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{channel_filter}}]];

-- Field Filter mapping: same as KPI 2


-- ------------------------------------------------------------
-- CHART 1: Weekly New User Signups
-- Visualization: Line chart
-- ------------------------------------------------------------
SELECT
    DATE_TRUNC('week', signup_date) AS signup_week,
    COUNT(*) AS new_signups
FROM imagineart_users
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{channel_filter}}]]
[[AND {{country_filter}}]]
GROUP BY signup_week
ORDER BY signup_week;

-- Field Filter mapping: same as KPI 1
-- Chart settings: X = signup_week, Y = new_signups


-- ------------------------------------------------------------
-- CHART 2: User Signups by Acquisition Channel
-- Visualization: Bar chart
-- ------------------------------------------------------------
SELECT
    acquisition_channel,
    COUNT(*) AS signups
FROM imagineart_users
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{country_filter}}]]
GROUP BY acquisition_channel
ORDER BY signups DESC;

-- Field Filter mapping:
--   date_filter    -> imagineart_users.signup_date
--   country_filter -> imagineart_users.country
-- Note: channel_filter intentionally excluded -- this chart's whole
-- purpose is to break results down BY channel.


-- ------------------------------------------------------------
-- CHART 3: Cost Per Acquisition (CPA) by Channel, Ranked
-- Visualization: Bar chart (sorted ascending = most efficient first)
-- ------------------------------------------------------------
SELECT
    acquisition_channel,
    ROUND(SUM(spend_usd) / NULLIF(SUM(installs), 0), 2) AS cpa
FROM imagineart_ad_campaigns
WHERE 1=1
[[AND {{date_filter}}]]
GROUP BY acquisition_channel
ORDER BY cpa ASC;

-- Field Filter mapping:
--   date_filter -> imagineart_ad_campaigns.week_start
-- Note: channel_filter intentionally excluded -- same reasoning as Chart 2.


-- ------------------------------------------------------------
-- CHART 4: Users by Country
-- Visualization: Bar chart (or Map)
-- ------------------------------------------------------------
SELECT
    country,
    COUNT(*) AS user_count
FROM imagineart_users
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{channel_filter}}]]
GROUP BY country
ORDER BY user_count DESC;

-- Field Filter mapping:
--   date_filter    -> imagineart_users.signup_date
--   channel_filter -> imagineart_users.acquisition_channel
-- Note: country_filter intentionally excluded -- same reasoning as above.
