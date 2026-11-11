-- Fail if a date/channel combination appears more than once.
select revenue_date, acquisition_channel
from {{ ref('mart_daily_revenue') }}
group by revenue_date, acquisition_channel
having count(*) > 1

union all

-- Fail if the revenue components do not equal the total,
-- or required numeric values are missing.
select revenue_date, acquisition_channel
from {{ ref('mart_daily_revenue') }}
where subscription_revenue_usd is null
   or credit_purchase_revenue_usd is null
   or gross_revenue_usd is null
   or revenue_event_count is null
   or revenue_event_count <= 0
   or gross_revenue_usd <>
      subscription_revenue_usd + credit_purchase_revenue_usd