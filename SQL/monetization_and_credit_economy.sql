-- ============================================================
-- PAGE 3: MONETIZATION & CREDIT ECONOMY
-- Dashboard: Canvas Pulse - ImagineArt Analytics
-- Tables used: imagineart_sessions_events, imagineart_subscriptions,
--              imagineart_credit_transactions, imagineart_users
-- Filters: Date (Retention... no -- Date, Plan Tier (Monetization),
--          Acquisition Channel (Monetization)
--
-- IMPORTANT SYNTAX NOTE:
-- Metabase Field Filter variables inject their WHERE condition using
-- the FULL table name, not a table alias. Any query that uses a Field
-- Filter must therefore avoid table aliases entirely (e.g. write
-- imagineart_users.plan_tier, not u.plan_tier) or Postgres throws:
-- "invalid reference to FROM-clause entry for table ..."
-- Every query below is written alias-free for this reason.
-- ============================================================


-- ------------------------------------------------------------
-- KPI 1: Total Revenue (subscriptions + credit purchases)
-- Visualization: Number (currency)
-- ------------------------------------------------------------
SELECT
    (SELECT COALESCE(SUM(imagineart_subscriptions.price_usd), 0)
     FROM imagineart_subscriptions
     JOIN imagineart_users ON imagineart_subscriptions.user_id = imagineart_users.user_id
     WHERE imagineart_subscriptions.event_type = 'upgrade'
     [[AND {{date_filter}}]]
     [[AND {{plan_tier_filter}}]]
     [[AND {{channel_filter}}]])
    +
    (SELECT COALESCE(SUM(imagineart_credit_transactions.cost_usd), 0)
     FROM imagineart_credit_transactions
     WHERE imagineart_credit_transactions.transaction_type = 'purchase')
    AS total_revenue;

-- Field Filter mapping:
--   date_filter       -> imagineart_subscriptions.event_date
--   plan_tier_filter  -> imagineart_users.plan_tier
--   channel_filter    -> imagineart_users.acquisition_channel


-- ------------------------------------------------------------
-- KPI 2: Paywall Conversion Rate (%)
-- Visualization: Number (percentage)
-- ------------------------------------------------------------
SELECT
    ROUND(100.0 *
        SUM(CASE WHEN imagineart_sessions_events.event_type = 'paywall_outcome:converted' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN imagineart_sessions_events.event_type = 'paywall_view' THEN 1 ELSE 0 END), 0)
    , 2) AS paywall_conversion_rate_percent
FROM imagineart_sessions_events
JOIN imagineart_users ON imagineart_sessions_events.user_id = imagineart_users.user_id
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{channel_filter}}]];

-- Field Filter mapping:
--   date_filter       -> imagineart_sessions_events.event_date
--   plan_tier_filter  -> imagineart_sessions_events.plan_tier
--   channel_filter    -> imagineart_users.acquisition_channel


-- ------------------------------------------------------------
-- KPI 3: Average Credits Consumed per Generation
-- Visualization: Number
-- ------------------------------------------------------------
SELECT ROUND(AVG(credits_consumed), 2) AS avg_credits_per_generation
FROM imagineart_generations
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{channel_filter}}]];

-- Field Filter mapping:
--   date_filter       -> imagineart_generations.event_date
--   plan_tier_filter  -> imagineart_generations.plan_tier
--   channel_filter    -> imagineart_generations.acquisition_channel
-- Note: no join needed -- imagineart_generations has all 3 columns natively.


-- ------------------------------------------------------------
-- KPI 4: Refund Rate (%)
-- Visualization: Number (percentage)
-- ------------------------------------------------------------
SELECT
    ROUND(100.0 *
        SUM(CASE WHEN imagineart_credit_transactions.transaction_type = 'refund' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN imagineart_credit_transactions.transaction_type = 'purchase' THEN 1 ELSE 0 END), 0)
    , 2) AS refund_rate_percent
FROM imagineart_credit_transactions
JOIN imagineart_users ON imagineart_credit_transactions.user_id = imagineart_users.user_id
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{channel_filter}}]];

-- Field Filter mapping:
--   date_filter       -> imagineart_credit_transactions.transaction_date
--   plan_tier_filter  -> imagineart_users.plan_tier
--   channel_filter    -> imagineart_users.acquisition_channel


-- ------------------------------------------------------------
-- CHART 1: Paywall Conversion Funnel
-- Visualization: Bar chart (funnel-style step comparison)
-- ------------------------------------------------------------
SELECT 'App Open' AS step,
       SUM(CASE WHEN imagineart_sessions_events.event_type = 'app_open' THEN 1 ELSE 0 END) AS user_count,
       1 AS step_order
FROM imagineart_sessions_events
JOIN imagineart_users ON imagineart_sessions_events.user_id = imagineart_users.user_id
WHERE 1=1 [[AND {{date_filter}}]] [[AND {{plan_tier_filter}}]] [[AND {{channel_filter}}]]

UNION ALL

SELECT 'Paywall View',
       SUM(CASE WHEN imagineart_sessions_events.event_type = 'paywall_view' THEN 1 ELSE 0 END),
       2
FROM imagineart_sessions_events
JOIN imagineart_users ON imagineart_sessions_events.user_id = imagineart_users.user_id
WHERE 1=1 [[AND {{date_filter}}]] [[AND {{plan_tier_filter}}]] [[AND {{channel_filter}}]]

UNION ALL

SELECT 'Converted',
       SUM(CASE WHEN imagineart_sessions_events.event_type = 'paywall_outcome:converted' THEN 1 ELSE 0 END),
       3
FROM imagineart_sessions_events
JOIN imagineart_users ON imagineart_sessions_events.user_id = imagineart_users.user_id
WHERE 1=1 [[AND {{date_filter}}]] [[AND {{plan_tier_filter}}]] [[AND {{channel_filter}}]]

ORDER BY step_order;

-- Field Filter mapping: same as KPI 2
-- Chart settings: X = step (sorted by step_order), Y = user_count


-- ------------------------------------------------------------
-- CHART 2: Revenue by Plan Tier
-- Visualization: Bar chart
-- ------------------------------------------------------------
SELECT
    imagineart_subscriptions.plan_name,
    SUM(imagineart_subscriptions.price_usd) AS revenue
FROM imagineart_subscriptions
JOIN imagineart_users ON imagineart_subscriptions.user_id = imagineart_users.user_id
WHERE imagineart_subscriptions.event_type = 'upgrade'
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{channel_filter}}]]
GROUP BY imagineart_subscriptions.plan_name
ORDER BY revenue DESC;

-- Field Filter mapping:
--   date_filter       -> imagineart_subscriptions.event_date
--   plan_tier_filter  -> imagineart_users.plan_tier
--   channel_filter    -> imagineart_users.acquisition_channel


-- ------------------------------------------------------------
-- CHART 3: Upgrades vs Cancellations Over Time
-- Visualization: Line chart (2 series)
-- ------------------------------------------------------------
SELECT
    imagineart_subscriptions.event_date,
    imagineart_subscriptions.event_type,
    COUNT(*) AS event_count
FROM imagineart_subscriptions
JOIN imagineart_users ON imagineart_subscriptions.user_id = imagineart_users.user_id
WHERE imagineart_subscriptions.event_type IN ('upgrade', 'cancellation')
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{channel_filter}}]]
GROUP BY imagineart_subscriptions.event_date, imagineart_subscriptions.event_type
ORDER BY imagineart_subscriptions.event_date;

-- Field Filter mapping: same as Chart 2
-- Chart settings: X = event_date, Series = event_type, Y = event_count


-- ------------------------------------------------------------
-- CHART 4: Credit Purchases vs Refunds
-- Visualization: Bar chart
-- ------------------------------------------------------------
SELECT
    imagineart_credit_transactions.transaction_type,
    SUM(imagineart_credit_transactions.credits) AS total_credits,
    SUM(imagineart_credit_transactions.cost_usd) AS total_cost
FROM imagineart_credit_transactions
JOIN imagineart_users ON imagineart_credit_transactions.user_id = imagineart_users.user_id
WHERE 1=1
[[AND {{date_filter}}]]
[[AND {{plan_tier_filter}}]]
[[AND {{channel_filter}}]]
GROUP BY imagineart_credit_transactions.transaction_type;

-- Field Filter mapping:
--   date_filter       -> imagineart_credit_transactions.transaction_date
--   plan_tier_filter  -> imagineart_users.plan_tier
--   channel_filter    -> imagineart_users.acquisition_channel
