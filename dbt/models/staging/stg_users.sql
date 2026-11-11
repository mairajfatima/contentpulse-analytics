select
    user_id,
    signup_date,
    lower(trim(acquisition_channel)) as acquisition_channel,
    country,
    platform,
    plan_tier,
    age_bucket,
    app_version,
    os_version
from {{ source('contentpulse_raw', 'imagineart_users') }}