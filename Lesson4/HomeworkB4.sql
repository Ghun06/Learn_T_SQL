/*
1.1. Paytm has a wide variety of transaction types in its business.
Your manager wants to know the contribution (by percentage) of each transaction type to total transactions. Retrieve a report that includes the following information: transaction type, number of transactions and proportion of each type in total. These transactions must meet the following conditions: 
●	Were created in 2019 
●	Were paid successfully
*/
WITH joined_table AS (
SELECT fact19.*
   , dscen.transaction_type
FROM fact_transaction_2019 AS fact19
LEFT JOIN dim_status AS dsta
   ON fact19.status_id = dsta.status_id
LEFT JOIN dim_scenario AS dscen
   ON fact19.scenario_id = dscen.scenario_id
WHERE dsta.status_description = 'success'
)
, total_table AS (
SELECT transaction_type
   , COUNT(*) AS number_trans
   ,(SELECT COUNT(*) FROM joined_table) AS total_trans 
FROM joined_table
GROUP BY transaction_type
)
SELECT TOP 5 *
   , FORMAT((number_trans * 1.0/ total_trans), 'p') AS pct 
FROM total_table
ORDER BY number_trans DESC

WITH joined_table AS (
  SELECT COALESCE(scen.transaction_type, 'NULL') AS transaction_type, COALESCE(scen.category, 'NULL') AS category, COUNT(*) AS transaction_count
  FROM fact_transaction_2019 AS fact_19
  LEFT JOIN dim_scenario AS scen ON fact_19.scenario_id = scen.scenario_id
  INNER JOIN dim_status AS stat ON fact_19.status_id = stat.status_id
  WHERE stat.status_description = 'success'
  GROUP BY transaction_type, category
),
total_table AS (
  SELECT transaction_type, SUM(transaction_count) AS total_count
  FROM joined_table
  GROUP BY transaction_type
)
SELECT jt.transaction_type, jt.category, jt.transaction_count,
  FORMAT((jt.transaction_count * 1.0 / tt.total_count), 'p') AS pct
FROM joined_table AS jt
JOIN total_table AS tt ON jt.transaction_type = tt.transaction_type
ORDER BY jt.transaction_type, jt.transaction_count DESC

SELECT customer_id
    , COUNT(*) AS number_trans
    , COUNT(DISTINCT dscen.transaction_type) AS number_scenarios
    , COUNT(DISTINCT dscen.category) AS number_categories
    , SUM(fact19.charged_amount) AS total_amount
FROM fact_transaction_2019 AS fact19
LEFT JOIN dim_scenario AS dscen
ON fact19.scenario_id = dscen.scenario_id
LEFT JOIN dim_status AS dsta 
ON fact19.status_id = dsta.status_id
WHERE dsta.status_description = 'success'
    AND dscen.transaction_type = 'payment'
GROUP BY customer_id
ORDER BY number_trans DESC


-- Bước 1: CTE thoả mãn yêu cầu thành công và giao dịch trong 3 tháng đầu tiên
WITH joined_table AS (
SELECT fact_19.*
   , snar.transaction_type
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_status AS stat
   ON fact_19.status_id = stat.status_id
LEFT JOIN dim_scenario AS snar
   ON fact_19.scenario_id = snar.scenario_id
WHERE stat.status_description = 'success'
   AND MONTH(fact_19.transaction_time) <= 3
)


-- Bước 2: CTE gom nhóm và tính toán theo từng loại giao dịch.
, total_table AS (
SELECT transaction_type
   , COUNT(*) AS number_trans
   ,(SELECT COUNT(*) FROM joined_table) AS total_trans -- subquery lấy ra total trans
FROM joined_table
GROUP BY transaction_type
)


-- Bước 3: Hiển thị vừa đủ thông tin đề yêu cầu
SELECT TOP 5 *
   , FORMAT(number_trans*1.0/total_trans, 'p') AS pct 
FROM total_table
ORDER BY number_trans DESC

WITH trans_table AS (
   SELECT transaction_id
       ,customer_id
       ,charged_amount
       ,platform_id
   FROM fact_transaction_2019 AS fact_19
   JOIN dim_payment_channel AS chan
   ON fact_19.payment_channel_id = chan.payment_channel_id
   JOIN dim_status AS stat
   ON fact_19.status_id = stat.status_id
   WHERE status_description = 'success' AND chan.payment_method = 'Bank account'
)
SELECT transaction_id
   ,customer_id
   ,charged_amount
   ,payment_platform
FROM trans_table
JOIN dim_platform AS plat
ON trans_table.platform_id = plat.platform_id
WHERE plat.payment_platform = 'Android'


SELECT snar.category
   ,COUNT(*) as number_trans
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS snar
   ON fact_19.scenario_id = snar.scenario_id
LEFT JOIN dim_status AS sta
   ON fact_19.status_id = sta.status_id
WHERE status_description = 'success'
GROUP BY snar.category
ORDER BY number_trans DESC


WITH joined_table AS (
  SELECT COALESCE(scen.transaction_type, 'NULL') AS transaction_type, 
  COALESCE(scen.category, 'NULL') AS category, COUNT(*) AS number_trans_category
  FROM fact_transaction_2019 AS fact_19
  LEFT JOIN dim_scenario AS scen ON fact_19.scenario_id = scen.scenario_id
  INNER JOIN dim_status AS stat ON fact_19.status_id = stat.status_id
  WHERE stat.status_description = 'success'
  GROUP BY transaction_type, category
),
    total_table AS (
    SELECT transaction_type,
    SUM(number_trans_category) AS number_trans_type
    FROM joined_table
    GROUP BY transaction_type
    )

SELECT jt.transaction_type, jt.category, jt.number_trans_category, tt.number_trans_type,
  FORMAT((jt.number_trans_category * 1.0 / tt.number_trans_type), 'p') AS pct
FROM joined_table AS jt
JOIN total_table AS tt ON jt.transaction_type = tt.transaction_type
ORDER BY jt.transaction_type, jt.number_trans_category DESC

