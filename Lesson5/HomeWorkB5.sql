-- task 2.1
SELECT customer_id, transaction_id, fact_19.scenario_id, transaction_type, sub_category, category
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS snar
    ON fact_19.scenario_id = snar.scenario_id
WHERE MONTH(transaction_time) = 2
AND transaction_type IS NOT NULL

-- task 2.2 -- sai
SELECT customer_id, charged_amount AS total_charged_amount
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS snar
    ON fact_19.scenario_id = snar.scenario_id
LEFT JOIN dim_status AS stat
    ON fact_19.status_id = stat.status_id
WHERE MONTH(transaction_time) = 2 
      AND transaction_type = 'Payment'
      AND status_description LIKE '%failed '
GROUP BY customer_id, charged_amount
ORDER BY SUM(charged_amount) DESC

SELECT * from fact_transaction_2020
-- task 3.1
SELECT TOP(10) customer_id, 
       COUNT(transaction_id) AS number_trans,
       COUNT(DISTINCT fact20.scenario_id) AS number_scenario,
       COUNT(DISTINCT category) AS number_category,
       SUM(charged_amount) AS total_amount
FROM fact_transaction_2020 AS fact20
LEFT JOIN dim_scenario AS snar
    ON fact20.scenario_id = snar.scenario_id
LEFT JOIN dim_status AS stat
    ON fact20.status_id = stat.status_id
WHERE MONTH(transaction_time) < 4
      AND transaction_type = 'Payment'
      AND stat.status_id = 1
GROUP BY customer_id
ORDER BY total_amount DESC;

-- task 3.2
WITH total_table AS (
    SELECT customer_id,
       COUNT(transaction_id) AS number_trans,
    --    COUNT(DISTINCT fact20.scenario_id) AS number_scenario,
    --    COUNT(DISTINCT category) AS number_category,
       SUM(CAST(charged_amount AS BIGINT)) AS total_amount
    FROM fact_transaction_2020 AS fact20
    LEFT JOIN dim_scenario AS snar
        ON fact20.scenario_id = snar.scenario_id
    LEFT JOIN dim_status AS stat
        ON fact20.status_id = stat.status_id
    WHERE MONTH(transaction_time) < 4
        AND transaction_type = 'Payment'
        AND stat.status_id = 1
    GROUP BY customer_id
),
    avg_table AS (
    SELECT customer_id, total_amount, 
        (SELECT SUM(CAST(total_amount AS BIGINT)) * 1.0 / COUNT(customer_id) FROM total_table) AS avg_amount
    FROM total_table
)
SELECT avg_table.*, CASE WHEN total_amount > avg_amount THEN 'greater_than_avg'
          ELSE 'Lower_than_avg'
          END AS group_customer
FROM avg_table;

WITH total_table AS (
    SELECT customer_id,
       COUNT(transaction_id) AS number_trans,
       SUM(CAST(charged_amount AS BIGINT)) AS total_amount
    FROM fact_transaction_2020 AS fact20
    LEFT JOIN dim_scenario AS snar
        ON fact20.scenario_id = snar.scenario_id
    LEFT JOIN dim_status AS stat
        ON fact20.status_id = stat.status_id
    WHERE MONTH(transaction_time) < 4
        AND transaction_type = 'Payment'
        AND stat.status_id = 1
    GROUP BY customer_id
),
    avg_table AS (
        SELECT customer_id, total_amount,
            (SELECT SUM(CAST(total_amount AS BIGINT)) * 1.0 / COUNT(customer_id) FROM total_table) AS avg_amount
        FROM total_table
    ),
    level_table as (SELECT avg_table.*, CASE WHEN total_amount > avg_amount THEN 'greater_than_avg'
            ELSE 'Lower_than_avg'
            END AS group_customer
    FROM avg_table)

SELECT COUNT(avg_amount) AS customer_more_than_avg,
         FORMAT(COUNT(avg_amount) * 1.0 / (SELECT COUNT(customer_id) FROM total_table), 'p') AS pct
FROM level_table
WHERE group_customer = 'greater_than_avg'
-- 2704 and 18.44%

--task 2.x
SELECT TOP 10 PERCENT transaction_type, status_description, charged_amount
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS snar
    ON fact_19.scenario_id = snar.scenario_id
LEFT JOIN dim_status AS stat
    ON fact_19.status_id = stat.status_id
WHERE MONTH(transaction_time) = 2
AND transaction_type = 'Payment'
AND stat.status_id <> 1
ORDER BY charged_amount DESC

SELECT * FROM dim_status

