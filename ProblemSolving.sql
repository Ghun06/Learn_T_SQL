-- 1 Task: Analyze these factors of Internal issues 
-- 1.1 Is there any difference in success rate and volume ratio between scenario IDs?
SELECT
    FORMAT(COUNT(CASE WHEN transaction_type LIKE 'Payment' THEN 1 END)*1.0/COUNT(transaction_type), 'p') as payment,
    FORMAT(COUNT(CASE WHEN transaction_type LIKE 'Inter Bank Transfer' THEN 1 END)*1.0/COUNT(transaction_type), 'p') as Inter_Bank_Transfer,
    FORMAT(COUNT(CASE WHEN transaction_type LIKE 'Credit Card Billing' THEN 1 END)*1.0/COUNT(transaction_type), 'p') as Credit_Card_Billing,
    FORMAT(COUNT(CASE WHEN transaction_type LIKE 'Withdraw' THEN 1 END)*1.0/COUNT(transaction_type), 'p') as Withdraw,
    FORMAT(COUNT(CASE WHEN transaction_type LIKE 'Top-up account' THEN 1 END)*1.0/COUNT(transaction_type), 'p') as Top_up_account
FROM fact_transaction_2020 fact_20
LEFT JOIN dim_scenario sce 
ON fact_20.scenario_id = sce.scenario_id
WHERE status_id = 1

-- The difference is the Top-up account has the 2nd highest number of transactions but the lowest success rate.

-- 1.2 Is there any difference in success rate and volume ratio between payment platforms? Are there any changes over time (by month/ by week)?

SELECT
     FORMAT(COUNT(CASE WHEN platform_id LIKE 'P1' THEN 1 END)*1.0/COUNT(platform_id), 'p') as android,
     FORMAT(COUNT(CASE WHEN platform_id LIKE 'P2' THEN 1 END)*1.0/COUNT(platform_id), 'p') as ios,
     FORMAT(COUNT(CASE WHEN platform_id LIKE 'P3' THEN 1 END)*1.0/COUNT(platform_id), 'p') as web
FROM fact_transaction_2020 fact_20
LEFT JOIN dim_scenario sce 
ON fact_20.scenario_id = sce.scenario_id
WHERE status_id = 1

-- Group by MONTH

with t1 as (
SELECT
    transaction_id,
    platform_id,
     month(transaction_time) as month
FROM fact_transaction_2020 fact_20
LEFT JOIN dim_scenario sce 
ON fact_20.scenario_id = sce.scenario_id
WHERE status_id = 1
)

SELECT
    month,
    FORMAT(COUNT(CASE WHEN platform_id LIKE 'P1' THEN 1 END)*1.0/COUNT(platform_id), 'p') as android,
    FORMAT(COUNT(CASE WHEN platform_id LIKE 'P2' THEN 1 END)*1.0/COUNT(platform_id), 'p') as ios,
    FORMAT(COUNT(CASE WHEN platform_id LIKE 'P3' THEN 1 END)*1.0/COUNT(platform_id), 'p') as web
FROM t1
group by month

-- 1.3 Is there any difference in success rate and volume ratio between payment channels? Are there any changes over time (by month/ by week)?

SELECT
    FORMAT(COUNT(CASE WHEN fact_20.payment_channel_id LIKE '11' THEN 1 END)*1.0/COUNT(fact_20.payment_channel_id), 'p') as Credit,
    FORMAT(COUNT(CASE WHEN fact_20.payment_channel_id LIKE '12' THEN 1 END)*1.0/COUNT(fact_20.payment_channel_id), 'p') as 'Bank account',
    FORMAT(COUNT(CASE WHEN fact_20.payment_channel_id LIKE '13' THEN 1 END)*1.0/COUNT(fact_20.payment_channel_id), 'p') as Balance,
    FORMAT(COUNT(CASE WHEN fact_20.payment_channel_id LIKE '14' THEN 1 END)*1.0/COUNT(fact_20.payment_channel_id), 'p') as 'Local card',
    FORMAT(COUNT(CASE WHEN fact_20.payment_channel_id LIKE '15' THEN 1 END)*1.0/COUNT(fact_20.payment_channel_id), 'p') as Debit
FROM fact_transaction_2020 fact_20
LEFT JOIN dim_payment_channel sce 
ON fact_20.payment_channel_id = sce.payment_channel_id

with t1 as (
SELECT
    transaction_id,
    fact_20.payment_channel_id,
     month(transaction_time) as month
FROM fact_transaction_2020 fact_20
LEFT JOIN dim_payment_channel sce 
ON fact_20.payment_channel_id = sce.payment_channel_id
WHERE status_id = 1
)

SELECT
    month,
    FORMAT(COUNT(CASE WHEN payment_channel_id LIKE '11' THEN 1 END)*1.0/COUNT(payment_channel_id), 'p') as Credit,
    FORMAT(COUNT(CASE WHEN payment_channel_id LIKE '12' THEN 1 END)*1.0/COUNT(payment_channel_id), 'p') as 'Bank account',
    FORMAT(COUNT(CASE WHEN payment_channel_id LIKE '13' THEN 1 END)*1.0/COUNT(payment_channel_id), 'p') as Balance,
    FORMAT(COUNT(CASE WHEN payment_channel_id LIKE '14' THEN 1 END)*1.0/COUNT(payment_channel_id), 'p') as 'Local card',
    FORMAT(COUNT(CASE WHEN payment_channel_id LIKE '15' THEN 1 END)*1.0/COUNT(payment_channel_id), 'p') as Debit
FROM t1
group by month;

-- 1.4 Which are the main errors of failed transactions? Are there any changes over time (by month)?
with t1 as (
SELECT
    status_id ,
    month(transaction_time) as month
FROM fact_transaction_2020
)

SELECT
    month,
    FORMAT(COUNT(CASE WHEN status_id LIKE '-2' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Payment expired transaction',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-3' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'The account does not have enough funds for payment.',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-4' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Transaction failed due to duplicate order ID',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-5' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Payment password is incorrect',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-6' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Exceeded the allowed amount for the day',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-7' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Wrong password to pay more than limit number of times',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-8' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Wrong OTP',
    FORMAT(COUNT(CASE WHEN (status_id LIKE '-9') or (status_id LIKE '-11') THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Payment failed',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-12' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'The bank transaction processing time has expired',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-13' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Unknown error from the bank',
    FORMAT(COUNT(CASE WHEN (status_id LIKE '-14') or (status_id LIKE '-10') THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Transactions suspected to be fraudulent',
    FORMAT(COUNT(CASE WHEN status_id LIKE '-15' THEN 1 END)*1.0/COUNT(status_id), 'p') as 'Your account is temporarily locked'
FROM t1
group by month;

-- The main error were Payment failed and The account does not have enough funds for payment.

with t1 as (
select 
    transaction_id,
    status_description
from fact_transaction_2020 fact_20
left join dim_status sta 
on fact_20.status_id = sta.status_id 
where fact_20.status_id !=1
)
, t2 as (
select 
    status_description,
    count(transaction_id) as num_trans,
    (select 
        count(transaction_id)
    from fact_transaction_2020) as total
from t1
group by status_description
)

SELECT
    status_description,
    FORMAT(num_trans*1.0/total, 'p') as pct 
FROM t2

-- Task 2: Analyze these factors of External issues 
-- What percentage of the total number of failed transactions were the transactions that occurred before the customer’s first successful Top-up time? (Hard) 
-- Percentage of error reasons coming from customers in the total error messages? 
-- Does the promotion factor affect the success rate result?

