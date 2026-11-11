select
    transaction_id,
    user_id,
    transaction_date,
    lower(trim(transaction_type)) as transaction_type,
    credits,
    cost_usd
from {{ source('contentpulse_raw', 'imagineart_credit_transactions') }}