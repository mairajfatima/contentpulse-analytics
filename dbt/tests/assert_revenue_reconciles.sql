with expected as (
    select
        (
            select coalesce(sum(price_usd), 0)
            from {{ source('contentpulse_raw', 'imagineart_subscriptions') }}
            where lower(trim(event_type)) = 'upgrade'
        )
        +
        (
            select coalesce(sum(cost_usd), 0)
            from {{ source('contentpulse_raw', 'imagineart_credit_transactions') }}
            where lower(trim(transaction_type)) = 'purchase'
        ) as revenue_usd,

        (
            select count(*)
            from {{ source('contentpulse_raw', 'imagineart_subscriptions') }}
            where lower(trim(event_type)) = 'upgrade'
        )
        +
        (
            select count(*)
            from {{ source('contentpulse_raw', 'imagineart_credit_transactions') }}
            where lower(trim(transaction_type)) = 'purchase'
        ) as event_count
),

actual as (
    select
        'revenue_events' as model_name,
        coalesce(sum(revenue_usd), 0) as revenue_usd,
        count(*) as event_count
    from {{ ref('fct_revenue_events') }}

    union all

    select
        'daily_mart',
        coalesce(sum(gross_revenue_usd), 0),
        coalesce(sum(revenue_event_count), 0)
    from {{ ref('mart_daily_revenue') }}
)

select actual.*
from actual
cross join expected
where actual.revenue_usd <> expected.revenue_usd
   or actual.event_count <> expected.event_count