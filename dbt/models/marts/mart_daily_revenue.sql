{{ config(materialized='table') }}

select
    revenue_date,
    acquisition_channel,

    count(*) as revenue_event_count,

    sum(
        case when revenue_type = 'subscription_upgrade'
            then revenue_usd else 0
        end
    ) as subscription_revenue_usd,

    sum(
        case when revenue_type = 'credit_purchase'
            then revenue_usd else 0
        end
    ) as credit_purchase_revenue_usd,

    sum(revenue_usd) as gross_revenue_usd

from {{ ref('fct_revenue_events') }}

group by
    revenue_date,
    acquisition_channel