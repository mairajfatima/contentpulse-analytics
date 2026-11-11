select
    subscription_event_id,
    user_id,
    event_date,
    lower(trim(event_type)) as event_type,
    lower(trim(plan_name)) as plan_name,
    price_usd
from {{ source('contentpulse_raw', 'imagineart_subscriptions') }}