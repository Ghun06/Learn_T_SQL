SELECT MONTH(transaction_time) AS month
    , COUNT(transaction_id) as number_success_trans
FROM fact_transaction_2019
WHERE status_id = 1
GROUP BY MONTH(transaction_time);

-- 2.1 
WITH fact_table AS (
SELECT transaction_id, transaction_time
FROM fact_transaction_2019
WHERE status_id = 1
UNION
SELECT transaction_id, transaction_time
FROM fact_transaction_2020
WHERE status_id = 1
)
, table_month AS (
SELECT YEAR (transaction_time) [year], MONTH (transaction_time) [month]
    , COUNT (transaction_id) AS number_success_trans
FROM fact_table
GROUP BY YEAR (transaction_time), MONTH (transaction_time)
-- ORDER BY [year], [month]
)
, table_lag AS (
SELECT *
    , SUM(number_success_trans) OVER(PARTITION BY [year]) AS total_trans_year
FROM table_month
)
SELECT *
    ,FORMAT(number_success_trans * 1.0 / total_trans_year, 'p') AS pct
FROM table_lag
ORDER BY [year], [month]

-- task 2.2
WITH fact_table AS (
SELECT TOP 3 YEAR (transaction_time) [year], MONTH (transaction_time) [month]
    , COUNT (transaction_id) AS number_failed_trans
FROM fact_transaction_2019
WHERE status_id <> 1
GROUP BY YEAR (transaction_time), MONTH (transaction_time)
ORDER BY [year], COUNT (transaction_id) DESC
UNION
SELECT TOP 3 YEAR (transaction_time) [year], MONTH (transaction_time) [month]
    , COUNT (transaction_id) AS number_failed_trans
FROM fact_transaction_2020
WHERE status_id <> 1
GROUP BY YEAR (transaction_time), MONTH (transaction_time)
ORDER BY [year], COUNT (transaction_id) DESC
)
SELECT *
    , RANK() OVER (PARTITION BY [year] ORDER BY number_failed_trans DESC) AS rank
FROM fact_table
ORDER BY [year], number_failed_trans DESC;

--task 2.3
-- Tính khoảng cách trung bình giữa các lần thanh toán thành công theo từng khách hàng trong nhóm Telecom năm 2019.
--  Gợi ý: Sử dụng hàm LAG() kết hợp với Window Function
WITH fact_table AS (
SELECT customer_id, transaction_time
FROM fact_transaction_2019
JOIN dim_scenario AS scena
ON fact_transaction_2019.scenario_id = scena.scenario_id
WHERE status_id = 1 AND category = 'Telco'
)
, table_lag AS (
SELECT customer_id
    , transaction_time
    , LAG(transaction_time) OVER(PARTITION BY customer_id ORDER BY transaction_time) AS lag_transaction_time
    , DATEDIFF(DAY, LAG(transaction_time) OVER(PARTITION BY customer_id ORDER BY transaction_time), transaction_time) AS diff_day
FROM fact_table
)

SELECT customer_id, ROUND(AVG(diff_day), 0) AS avg_gap_day
    -- ROUND(AVG(diff_day) OVER(PARTITION BY customer_id), 2) AS avg_gap_day
FROM table_lag
GROUP BY customer_id;

-- PART 2: Time Series Analysis
WITH fact_table AS (
SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
    , COUNT(transaction_id) AS number_trans
FROM fact_transaction_2019 as fact19
JOIN dim_scenario AS scena
ON fact19.scenario_id = scena.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time)
UNION 
SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
    , COUNT(transaction_id) AS number_trans
FROM fact_transaction_2020 as fact20
JOIN dim_scenario AS scena
ON fact20.scenario_id = scena.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time)
)

SELECT [year], [month]
    , CASE WHEN [month] < 10 THEN CONCAT([year], '0', [month])
      ELSE CONCAT([year], [month]) END AS time_calender
    , number_trans
FROM fact_table

-- 2.2 : You know that there are many sub-categories of the Billing group. After reviewing the above result,
-- you should break down the trend into each sub-categories.
SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
    , sub_category
    , COUNT(transaction_id) AS number_trans
FROM fact_transaction_2019 as fact19
JOIN dim_scenario AS scena
ON fact19.scenario_id = scena.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category
UNION 
SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
    , sub_category
    , COUNT(transaction_id) AS number_trans
FROM fact_transaction_2020 AS fact20
JOIN dim_scenario AS scena
ON fact20.scenario_id = scena.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category

-- TASK B : Then modify the result as the following table: Only select the sub-categories belong to list (Electricity, Internet and Water)
-- Cach 1: Sử dụng SUM kết hợp với CASE WHEN Ví dụ:  SUM( CASE WHEN … THEN … ELSE …)

SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
    , SUM(IIF(sub_category = 'Electricity', 1, 0)) AS electricity_trans
    , SUM(IIF(sub_category = 'Internet', 1, 0)) AS internet_trans
    , SUM(IIF(sub_category = 'Water', 1, 0)) AS water_trans
FROM fact_transaction_2019 as fact19
JOIN dim_scenario AS scena
ON fact19.scenario_id = scena.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time)
UNION
SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
    , SUM(IIF(sub_category = 'Electricity', 1, 0)) AS electricity_trans
    , SUM(IIF(sub_category = 'Internet', 1, 0)) AS internet_trans
    , SUM(IIF(sub_category = 'Water', 1, 0)) AS water_trans
FROM fact_transaction_2020 as fact20
JOIN dim_scenario AS scena
ON fact20.scenario_id = scena.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time);

-- Cach 2 : Sử dụng function Pivot
WITH sub_table AS (
    SELECT * FROM fact_transaction_2019
    UNION
    SELECT * FROM fact_transaction_2020
)
SELECT * FROM (
    SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
        , sub_category
        , COUNT(transaction_id) AS number_trans
    FROM sub_table as sub
    JOIN dim_scenario AS scena
    ON sub.scenario_id = scena.scenario_id
    WHERE status_id = 1 AND category = 'Billing'
    AND sub_category IN ('Electricity', 'Internet', 'Water')
    GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category) AS fact_table
    PIVOT (
        SUM(number_trans)
        FOR sub_category IN (Electricity, Internet, Water)
    ) AS PivotTable
ORDER BY [year], [month]


-- task 2.3 Based on the previous query, you need to calculate the proportion of each sub-category (Electricity, Internet and Water) in the total for each month
WITH fact_table AS (
    SELECT * FROM fact_transaction_2019 
    UNION 
    SELECT * FROM fact_transaction_2020 
)
, sub_count AS (
    SELECT 
        YEAR(transaction_time) year, MONTH(transaction_time) month
        , sub_category
        , COUNT(transaction_id) AS number_trans
    FROM fact_table 
    JOIN dim_scenario AS sce ON fact_table.scenario_id = sce.scenario_id
    WHERE status_id = 1 AND category = 'Billing'
    GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category
)
, sub_month AS (
    SELECT Year 
        , month 
        , SUM( CASE WHEN sub_category = 'Electricity' THEN number_trans ELSE 0 END ) AS electricity_trans
        , SUM( CASE WHEN sub_category = 'Internet' THEN number_trans ELSE 0 END ) AS internet_trans
        , SUM( CASE WHEN sub_category = 'Water' THEN number_trans ELSE 0 END ) AS water_trans
    FROM sub_count
    GROUP BY year, month
)
, total_month AS ( 
    SELECT * 
    , electricity_trans + internet_trans + water_trans  AS total_trans_month
    FROM sub_month
)
SELECT *
    , FORMAT(1.0*electricity_trans/total_trans_month, 'p') AS elec_pct
    , FORMAT(1.0*internet_trans/total_trans_month, 'p') AS iternet_pct
    , FORMAT(1.0*water_trans/total_trans_month, 'p') AS water_pct
FROM total_month;

-- Cach 2 : Sử dụng function Pivot
WITH sub_table AS (
    SELECT * FROM fact_transaction_2019
    UNION
    SELECT * FROM fact_transaction_2020
), 
total_month AS (
    SELECT *,
        electricity + internet + water  AS total_trans_month 
    FROM (
        SELECT YEAR(transaction_time) AS [year], MONTH(transaction_time) AS [month]
            , sub_category
            , COUNT(transaction_id) AS number_trans
        FROM sub_table as sub
        JOIN dim_scenario AS scena
        ON sub.scenario_id = scena.scenario_id
        WHERE status_id = 1 AND category = 'Billing'
        AND sub_category IN ('Electricity', 'Internet', 'Water')
        GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category) AS fact_table
        PIVOT (
            SUM(number_trans)
            FOR sub_category IN (Electricity, Internet, Water)
        ) AS PivotTable
    -- ORDER BY [year], [month]
)
SELECT *
    , FORMAT(1.0*electricity/total_trans_month, 'p') AS elec_pct
    , FORMAT(1.0*internet/total_trans_month, 'p') AS iternet_pct
    , FORMAT(1.0*water/total_trans_month, 'p') AS water_pct
FROM total_month
ORDER BY [year], [month]
