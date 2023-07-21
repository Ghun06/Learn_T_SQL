-- LessonB6: Window Functions

-- 1. chức năng ranking
-- RANK(): 
-- DENSE_RANK():
-- ROW_NUMBER():
-- NTILE(): chia nhóm theo số lượng mà mình mong muốn

SELECT customer_id, transaction_id, transaction_id
     , ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY transaction_id) AS row_number
     , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY transaction_id) AS dense_rank
FROM fact_transaction_2019
WHERE MONTH(transaction_time) = 1
ORDER BY customer_id

-- tìm ra top 3 khách hàng chia nhiều tiền nhất mỗi tháng

WITH table_month AS (
SELECT customer_id, transaction_id, charged_amount, transaction_time
, MONTH (transaction_time) AS [month]
FROM fact_transaction_2019
WHERE status_id = 1 AND MONTH (transaction_time) < 4
)
, table_amount AS (
SELECT DISTINCT customer_id, [month]
, SUM (charged_amount) OVER ( PARTITION BY customer_id, [month] ) total_amount
FROM table_month
-- ORDER BY [month], total_amount DESC
)
, table_rank AS (
SELECT *
, RANK () OVER ( PARTITION BY [month] ORDER BY total_amount DESC ) AS rank
FROM table_amount
)
SELECT *
FROM table_rank
WHERE rank < 4
ORDER BY [month], rank

-- cách 2: group by và window function
WITH table_month AS (
SELECT MONTH (transaction_time) AS [month]
, customer_id
, SUM (charged_amount) AS total_amount
FROM fact_transaction_2019
WHERE status_id = 1 AND MONTH (transaction_time) < 4
GROUP BY MONTH (transaction_time), customer_id
)
, table_rank AS (
SELECT *
, RANK () OVER ( PARTITION BY [month] ORDER BY total_amount DESC ) AS rank
FROM table_month
)
SELECT *
FROM table_rank
WHERE rank < 4
ORDER BY [month], rank
-- TH1 đối tượng gom nhóm giống nhau cho tất cả các metrics (đối tượng)
--TH2 đối tượng gom nhóm khác nhau cho mỗi metrics (đối tượng) khác nhau 

WITH table_month AS (
SELECT customer_id, transaction_id, transaction_time
, MONTH (transaction_time) AS [month]
FROM fact_transaction_2019
WHERE status_id = 1 AND MONTH (transaction_time) < 4
)
SELECT DISTINCT customer_id, month
, COUNT (transaction_id) OVER ( PARTITION BY customer_id, [month]) AS number_trans_month
, COUNT (transaction_id) OVER ( PARTITION BY customer_id ) AS number_trans_3months
FROM table_month
ORDER BY customer_id, month

-- tinh total_year_trans, total_year_amount

WITH fact_table AS (
SELECT transaction_id, transaction_time, charged_amount, scenario_id
FROM fact_transaction_2019
WHERE status_id = 1
UNION
SELECT transaction_id, transaction_time, charged_amount, scenario_id
FROM fact_transaction_2020
WHERE status_id = 1
)
, table_month AS (
SELECT YEAR (transaction_time) [year], MONTH (transaction_time) [month]
, COUNT (transaction_id) AS number_trans
, SUM (charged_amount *1.0) AS total_amount
FROM fact_table
JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Telco'
GROUP BY YEAR (transaction_time), MONTH (transaction_time)
-- ORDER BY [year], [month]
)
SELECT *
, SUM (number_trans) OVER ( PARTITION BY [year] ) total_trans_year
, SUM (total_amount) OVER ( PARTITION BY [year] ) total_amount_year
, SUM (number_trans) OVER ( ) total_trans_2year
FROM table_month;



--> Ví dụ : tốc độ tăng trưởng chỉ total_amount theo từng tháng (chỉ tính giao dịch thành công) của sản phẩm telecom

WITH fact_table AS (
SELECT transaction_id, transaction_time, charged_amount, scenario_id
FROM fact_transaction_2019
WHERE status_id = 1
UNION
SELECT transaction_id, transaction_time, charged_amount, scenario_id
FROM fact_transaction_2020
WHERE status_id = 1
)
, table_month AS (
SELECT YEAR (transaction_time) [year], MONTH (transaction_time) [month]
, COUNT (transaction_id) AS number_trans
, SUM (charged_amount *1.0) AS total_amount
FROM fact_table
JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Telco'
GROUP BY YEAR (transaction_time), MONTH (transaction_time)
-- ORDER BY [year], [month]
)
SELECT *
    , SUM(total_amount) OVER (ORDER BY [year], [month]) AS accumulating_amount
FROM table_month;

-- ví dụ 6: Hãy đánh giá yếu tố số lượng khách hàng theo từng tháng của năm 2020 tăng hay giảm bao nhiêu %
--- so với cùng kì năm trước (telecom). (Tức tháng 1/2020 tăng trưởng bao nhiêu % so với tháng 1 năm 2019)


WITH fact_table AS (
SELECT transaction_id, transaction_time, customer_id, scenario_id
FROM fact_transaction_2019
WHERE status_id = 1
UNION
SELECT transaction_id, transaction_time, customer_id, scenario_id
FROM fact_transaction_2020
WHERE status_id = 1
)
, table_month AS (
SELECT YEAR (transaction_time) [year], MONTH (transaction_time) [month]
, COUNT (distinct customer_id) AS number_customer_current
FROM fact_table
JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Telco'
GROUP BY YEAR (transaction_time), MONTH (transaction_time)
-- ORDER BY [year], [month]
)
, table_lag AS (
SELECT *
, LAG (number_customer_current, 12) OVER ( ORDER BY [year], [month] ) AS number_customer_last_year
FROM table_month
)
SELECT *
,( number_customer_current - number_customer_last_year )*100.0 / number_customer_last_year AS pct
FROM table_lag
WHERE [year] = 2020