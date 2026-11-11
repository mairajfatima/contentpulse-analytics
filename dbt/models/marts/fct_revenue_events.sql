{{ config(materialized='table') }}

with revenue_events as (

    select
        'subscription_' || subscription_event_id as revenue_event_id,
        user_id,
        event_date as revenue_date,
        'subscription_upgrade' as revenue_type,
        price_usd as revenue_usd
    from {{ ref('stg_subscriptions') }}
    where event_type = 'upgrade'

    union all

    select
        'credit_' || transaction_id as revenue_event_id,
        user_id,
        transaction_date as revenue_date,
        'credit_purchase' as revenue_type,
        cost_usd as revenue_usd
    from {{ ref('stg_credit_transactions') }}
    where transaction_type = 'purchase'

)

select
    revenue_events.revenue_event_id,
    revenue_events.user_id,
    revenue_events.revenue_date,
    revenue_events.revenue_type,
    revenue_events.revenue_usd,
    users.acquisition_channel
from revenue_events
left join {{ ref('stg_users') }} as users
    on revenue_events.user_id = users.user_id