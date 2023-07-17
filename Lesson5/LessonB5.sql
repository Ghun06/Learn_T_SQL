-- Sửa bài buổi 4:


-- PART 1:


-- 1.1 Đếm xem mỗi category có bao nhiêu successful transactions


SELECT category
,COUNT(transaction_id) as number_trans
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario as scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat
ON fact_19.status_id = stat.status_id
WHERE status_description = 'success'
GROUP BY category;


--> Category bị NULL tức là k JOIN được


-- 1.2


WITH trans_table AS (
SELECT transaction_id
,customer_id
,charged_amount
,platform_id
FROM fact_transaction_2019 as fact_19
JOIN dim_payment_channel AS chan
ON fact_19.payment_channel_id = chan.payment_channel_id
WHERE payment_method = 'bank account'
AND status_id = 1
)
SELECT transaction_id
,customer_id
,charged_amount
,payment_platform
FROM trans_table
JOIN dim_platform as plat
ON trans_table.platform_id = plat.platform_id
WHERE payment_platform = 'android'


-- 1.3


WITH joined_table AS (
SELECT fact_19.*
, transaction_type
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario as scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat
ON fact_19.status_id = stat.status_id
WHERE status_description = 'success'
AND MONTH (transaction_time) <= 3
)
, total_table AS (
SELECT transaction_type
, count (transaction_id) AS number_trans
, ( SELECT COUNT(transaction_id) FROM joined_table ) AS total_trans -- subquery tìm total_trans
FROM joined_table
GROUP BY transaction_type
)
SELECT top 5 *
, FORMAT ( number_trans*1.0/total_trans, 'p') as pct
FROM total_table
ORDER BY number_trans DESC


-- PART 2:


-- 1.1 Y chang bài 1.3 ở trên part 1


WITH joined_table AS (
SELECT fact_19.*
, transaction_type, category
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario as scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat
ON fact_19.status_id = stat.status_id
WHERE status_description = 'success'
)
, total_table AS (
SELECT transaction_type
, count (transaction_id) AS number_trans
,(SELECT COUNT( transaction_id) FROM joined_table ) AS total_trans
FROM joined_table
GROUP BY transaction_type
)
SELECT top 5 *
, FORMAT ( number_trans*1.0/total_trans, 'p') as pct
FROM total_table
ORDER BY number_trans DESC

-- Bài 1.2 

-- b1: đếm mỗi category có bao nhiu giao dịch


WITH joined_table AS (
SELECT fact_19.*
, transaction_type
, category
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario as scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat
ON fact_19.status_id = stat.status_id
WHERE status_description = 'success'
)
, count_category AS ( -- b1:
    SELECT transaction_type
    , category
    , count (transaction_id) AS number_trans_category
    FROM joined_table
    GROUP BY transaction_type , category
)
, count_type AS ( -- b2:
    SELECT transaction_type
    , count (transaction_id) AS number_trans_type
    FROM joined_table
    GROUP BY transaction_type
)
SELECT count_category.*
, number_trans_type
, FORMAT ( number_trans_category*1.0 / number_trans_type , 'p') AS pct
FROM count_category
FULL JOIN count_type
ON count_category.transaction_type = count_type.transaction_type

-- COUNT (): đếm dòng
--> COUNT (*) : đếm hết tất cả dòng của bảng (10 cột)
--> COUNT (transaction_id): trong Fact19 --> số dòng của bảng
--> COUNT (category): đếm dòng, nhưng nếu dòng bị NULL thì nó k đếm dòng đó


-- 2. 
select customer_id
, count (transaction_id) as number_trans
, count (distinct fact_19.scenario_id) as number_scenarios
, count (distinct category) as number_categories
, sum (charged_amount) as total_amount
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario as scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat
ON fact_19.status_id = stat.status_id
WHERE status_description = 'success'
and transaction_type = 'payment'
group by customer_id
ORDER BY number_trans DESC


-- 2.2 Hãy đánh giá cho mình sự phân bổ của chỉ số "tổng số giao dịch của từng KH" đang như thế nào?


--> Áp dụng Statistics --> Thống kê sẽ áp dụng ntn vào data analysis
--> 1. Mô tả thống kê (descriptive statistics)
--> A. estimate location (mean, max, min, median)
--> B. estimate range (variance, standard deviation, percentile)
--> C. Distribution (histogram, box plot, scatter plot)


--> hướng giải quyết vẽ Histogram --> đếm xem giá trị number_trans nó xuất hiện bao nhiu lần


WITH count_trans AS (
select customer_id
, count (transaction_id) as number_trans
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario as scena
ON fact_19.scenario_id = scena.scenario_id
WHERE status_id = 1
and transaction_type = 'payment'
group by customer_id
)
SELECT number_trans
, COUNT (customer_id) AS number_customers
FROM count_trans
GROUP BY number_trans
ORDER By number_trans

-- use binning count(case when ...)

WITH total_table AS (
select customer_id
, sum (charged_amount) as total_money
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario as scena
ON fact_19.scenario_id = scena.scenario_id
WHERE status_id = 1
and transaction_type = 'payment'
group by customer_id
),
money_rank as (
    SELECT customer_id, total_money
    , CASE WHEN total_money < 1000000 then '0-1M'
        when total_money < 2000000 then '1M-2M'
        when total_money < 3000000 then '2M-3M'
        when total_money < 4000000 then '3M-4M'
        when total_money < 5000000 then '4M-5M'
        when total_money < 6000000 then '5M-6M'
        when total_money < 7000000 then '6M-7M'
        when total_money < 8000000 then '7M-8M'
        when total_money < 9000000 then '8M-9M'
        when total_money < 10000000 then '9M-10M'
        else '10M+' end as total_money_bin
FROM total_table
)

SELECT total_money_bin, count(customer_id) as number_customers
FROM money_rank
GROUP BY total_money_bin







