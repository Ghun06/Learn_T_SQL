/*
●	Task 1: Cho biết xu hướng của lượng giao dịch thanh toán thành công có hưởng khuyến mãi (promtion_trans) 
theo từng tuần và chiếm tỷ trọng bao nhiêu trên tổng số giao dịch thanh toán thành công (promotion_ratio) ? 

●	Task 2: Trong tổng số khách hàng thanh toán thành công có hưởng khuyến mãi, 
có bao nhiêu % khách hàng đã phát sinh thêm bất kỳ giao dịch thanh toán thành công khác mà không phải là giao dịch khuyến mãi ?
*/
-- Task 1: 
WITH fact_table AS (
    SELECT YEAR(transaction_time) Year, DATEPART(week, transaction_time) AS week_number
            ,  COUNT (customer_id) AS number_customer
    FROM fact_transaction_2020 fact_20 
    JOIN dim_scenario AS scena ON fact_20.scenario_id = scena.scenario_id
    WHERE status_id = 1 AND sub_category = 'Electricity' AND promotion_id <> '0'
    GROUP BY YEAR(transaction_time), DATEPART(week, transaction_time)
), 
total_nb AS (
    SELECT [Year], SUM (number_customer) total_nb_customer
    FROM fact_table
    GROUP BY Year
)
SELECT fact_table.year, week_number, number_customer, total_nb_customer
    , FORMAT(1.0*number_customer/total_nb_customer, 'p') AS pct_customer
FROM fact_table 
JOIN total_nb ON fact_table.year = total_nb.year;

-- Task 2 :
WITH promotion AS (
    SELECT YEAR(transaction_time) year , COUNT(DISTINCT customer_id) AS total_customer
    FROM fact_transaction_2020 fact_20
    JOIN dim_scenario AS scena ON fact_20.scenario_id = scena.scenario_id
    WHERE status_id = 1 AND promotion_id <> '0' AND sub_category = 'Electricity'
    GROUP BY YEAR(transaction_time)
),
no_promotion AS (
    SELECT YEAR(transaction_time) year, COUNT(DISTINCT customer_id) AS nb_customer
    FROM fact_transaction_2020 fact_20
    JOIN dim_scenario AS scena ON fact_20.scenario_id = scena.scenario_id
    WHERE status_id = 1 AND promotion_id = '0' 
    AND customer_id IN (
        SELECT customer_id
        FROM fact_transaction_2020 fact_20 
        JOIN dim_scenario AS scena ON fact_20.scenario_id = scena.scenario_id
        WHERE status_id = 1 AND promotion_id <> '0' AND sub_category = 'Electricity'
        -- GROUP BY customer_id
        )
    GROUP BY YEAR(transaction_time)
)

SELECT no_promotion.year, nb_customer, total_customer
    , FORMAT(1.0*nb_customer/total_customer, 'p') AS pct_customer
FROM no_promotion
JOIN promotion ON no_promotion.year = promotion.year;

-- chua bai Task 2 :
WITH electric_table AS (
    SELECT customer_id
    , transaction_id
    , promotion_id
    , IIF ( promotion_id <> '0' , 'is_promo', 'non_promo') AS trans_type
    FROM fact_transaction_2020 as fact_2020
    LEFT JOIN dim_scenario as scena
    ON fact_2020.scenario_id = scena.scenario_id
    WHERE sub_category = 'Electricity'
    AND status_id = 1
)
, previous_table AS (
SELECT *
, LAG (trans_type, 1) OVER ( PARTITION BY customer_id ORDER BY transaction_id ASC ) AS check_previous_tran
FROM electric_table
)
SELECT COUNT (DISTINCT customer_id) AS customer_make_non_promotion
, ( SELECT COUNT (DISTINCT customer_id) FROM previous_table WHERE trans_type = 'is_promo') AS total_promotion_customer
FROM previous_table
WHERE trans_type = 'non_promo' AND check_previous_tran = 'is_promo'

-- Task 1.1 B:
-- Tìm ra tỉ lệ ở lại của nhóm khách hàng “Telco Card” sau từng tháng kể từ khi khách hàng đó sử dụng dịch vụ lần đầu tiên là tháng 1
WITH customer_list AS (
    SELECT DISTINCT customer_id
    FROM fact_transaction_2019 fact 
    JOIN dim_scenario sce ON fact.scenario_id = sce.scenario_id
    WHERE sub_category = 'Telco Card' AND status_id = 1 AND MONTH(transaction_time) = 1
)
, full_trans AS ( -- b2 
    SELECT fact.*
    FROM customer_list 
    JOIN fact_transaction_2019 fact 
        ON customer_list.customer_id = fact.customer_id
    JOIN dim_scenario sce 
        ON fact.scenario_id = sce.scenario_id
    WHERE sub_category = 'Telco Card' AND status_id = 1
), total AS ( -- b3: Đếm xem từng tháng có bao nhiêu khách hàng
    SELECT MONTH(transaction_time) - 1 AS subsequent_month
        , COUNT( DISTINCT customer_id) AS retained_users
    FROM full_trans 
    GROUP BY MONTH(transaction_time) - 1 
    -- ORDER BY subsequent_month 
)
SELECT *, FIRST_VALUE(retained_users) OVER( ORDER BY subsequent_month) AS original_users
    , FORMAT(1.0*retained_users/FIRST_VALUE(retained_users) OVER(ORDER BY subsequent_month) , 'p') AS pct_retained
FROM total;

-- 1.1 B: You realize that the number of retained customers has decreased over time. Let’s calculate retention =  number of retained customers / total users of the first month. 
WITH total_table AS (
    SELECT customer_id, transaction_id, transaction_time
        , MIN(transaction_time) OVER( PARTITION BY customer_id) AS first_time
        , DATEDIFF(month, MIN(transaction_time) OVER( PARTITION BY customer_id), transaction_time) AS subsequent_month
    FROM fact_transaction_2019 fact 
    JOIN dim_scenario sce ON fact.scenario_id = sce.scenario_id
    WHERE sub_category = 'Telco Card' AND status_id = 1
)
, retained_user AS (
    SELECT subsequent_month
        , COUNT( DISTINCT customer_id) AS retained_users
    FROM total_table
    WHERE MONTH(first_time) = 1
    GROUP BY subsequent_month
    -- ORDER BY subsequent_month
)
SELECT *
    -- , FIRST_VALUE(retained_users) OVER( ORDER BY subsequent_month) AS original_users
    , MAX(retained_users) OVER() AS original_users
    -- , (SELECT COUNT(DISTINCT customer_id)
    --     FROM period_table 
    --     WHERE MONTH(first_time) = 1) AS original_users_3
    , FORMAT(1.0*retained_users/FIRST_VALUE(retained_users) OVER( ORDER BY subsequent_month) , 'p') AS pct_retained_users
FROM retained_user;

-- 5.	Task A: Expand your previous query to calculate retention for multi attributes from the acquisition month (first month) (from Jan to December). 
-- find first_month using MIN(.....) OVER (PARTITION BY …)
-- find subsequence_month using DATEDIFF(....) OVER (PARTITION BY …)
WITH period_table AS (
    SELECT customer_id, transaction_id, transaction_time
        , MIN(transaction_time) OVER( PARTITION BY customer_id) AS first_time
        , DATEDIFF(month, MIN(transaction_time) OVER( PARTITION BY customer_id), transaction_time) AS subsequent_month
    FROM fact_transaction_2019 fact 
    JOIN dim_scenario sce ON fact.scenario_id = sce.scenario_id
    WHERE sub_category = 'Telco Card' AND status_id = 1
)
, retained_user AS (
SELECT MONTH(first_time) AS acquisition_month
    , subsequent_month
    , COUNT( DISTINCT customer_id) AS retained_users
FROM period_table
GROUP BY MONTH(first_time) , subsequent_month
-- ORDER BY acquisition_month, subsequent_month
)
SELECT *
    , FIRST_VALUE(retained_users) OVER( PARTITION BY acquisition_month ORDER BY subsequent_month ASC) AS original_users
    , FORMAT(1.0*retained_users/FIRST_VALUE(retained_users) OVER( PARTITION BY acquisition_month ORDER BY subsequent_month ASC), 'p') AS pct_retained_users
FROM retained_user;


-- Task B: Then modify the result as the following table: 
WITH period_table AS (
    SELECT customer_id, transaction_id, transaction_time
        , MIN(transaction_time) OVER( PARTITION BY customer_id) AS first_time
        , DATEDIFF(month, MIN(transaction_time) OVER( PARTITION BY customer_id), transaction_time) AS subsequent_month
    FROM fact_transaction_2019 fact 
    JOIN dim_scenario sce ON fact.scenario_id = sce.scenario_id
    WHERE sub_category = 'Telco Card' AND status_id = 1
)
, retained_user AS (
    SELECT MONTH(first_time) AS acquisition_month
        , subsequent_month
        , COUNT( DISTINCT customer_id) AS retained_users
    FROM period_table
    GROUP BY MONTH(first_time) , subsequent_month
    -- ORDER BY acquisition_month, subsequent_month
)
, acquisition_table AS (
SELECT *
    , FIRST_VALUE(retained_users) OVER( PARTITION BY acquisition_month ORDER BY subsequent_month ASC) AS original_users
    -- , MAX(retained_users) OVER() AS original_users
    , FORMAT(1.0*retained_users/FIRST_VALUE(retained_users) OVER( PARTITION BY acquisition_month ORDER BY subsequent_month ASC), 'p') AS pct_retained_users
FROM retained_user)

SELECT acquisition_month, original_users
    , "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"
FROM (
    SELECT acquisition_month, original_users, subsequent_month, pct_retained_users 
    FROM acquisition_table
) AS table_source
PIVOT (
    MIN(pct_retained_users)
    FOR subsequent_month IN ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11")
) AS pivot_table
ORDER BY acquisition_month;

/*
RFM Segmentation

The first step in building an RFM model is to assign Recency, Frequency and Monetary values to each customer.
Let’s calculate these metrics for all successful paying customer of ‘Telco Card’ in 2019 and 2020
*/

WITH fact_table AS (
    SELECT fact_19.*
    FROM fact_transaction_2019 fact_19 
    JOIN dim_scenario sce ON fact_19.scenario_id = sce.scenario_id
    WHERE sub_category = 'Telco Card' AND status_id = 1
UNION
    SELECT fact_20.*
    FROM fact_transaction_2020 fact_20 
    JOIN dim_scenario sce ON fact_20.scenario_id = sce.scenario_id
    WHERE sub_category = 'Telco Card' AND status_id = 1
)

SELECT customer_id
    , DATEDIFF(DAY, MAX (transaction_time), '2020-12-31') AS Recency 
    , COUNT( DISTINCT FORMAT(transaction_time, 'yy.mm.dd')) AS Frequency
    , SUM (charged_amount) AS Monetary
FROM fact_table
GROUP BY customer_id;





