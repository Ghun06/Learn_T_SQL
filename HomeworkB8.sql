-- Task 1:
WITH fact_table AS (
SELECT customer_id, transaction_id, ft20.scenario_id, transaction_type, sub_category, category, status_description
FROM fact_transaction_2020 ft20
JOIN dim_scenario scen ON ft20.scenario_id = scen.scenario_id
JOIN dim_status sta ON ft20.status_id = sta.status_id
WHERE MONTH(transaction_time) = 1 AND ft20.status_id = 1
-- ORDER BY ft20.scenario_id, transaction_type, sub_category, category, status_description
)
SELECT transaction_type 
    , COUNT (transaction_id) AS nb_success_trans
FROM fact_table
GROUP BY transaction_type;

WITH success_table AS (
SELECT transaction_type, COUNT (transaction_id) AS nb_success_trans
FROM fact_transaction_2020 ft20
JOIN dim_scenario scen ON ft20.scenario_id = scen.scenario_id
JOIN dim_status sta ON ft20.status_id = sta.status_id
WHERE MONTH(transaction_time) = 1 AND ft20.status_id = 1
GROUP BY transaction_type
), 
total_table AS (
SELECT transaction_type, COUNT (transaction_id) AS nb_trans
FROM fact_transaction_2020 ft20
JOIN dim_scenario scen ON ft20.scenario_id = scen.scenario_id
JOIN dim_status sta ON ft20.status_id = sta.status_id
WHERE MONTH(transaction_time) = 1 
GROUP BY transaction_type
)
SELECT total_table.transaction_type, nb_trans, nb_success_trans
    , nb_success_trans * 1.0 / nb_trans AS success_rate
FROM total_table
JOIN success_table ON total_table.transaction_type = success_table.transaction_type
ORDER BY nb_trans DESC;

-- Task 2:
SELECT transaction_type
, COUNT (transaction_id) AS total_trans
, COUNT ( CASE WHEN status_description = 'Success' THEN transaction_id END ) AS number_success_trans
, COUNT ( CASE WHEN status_description = 'Success' THEN transaction_id END ) *1.0 / COUNT (transaction_id) AS success_rate
FROM fact_transaction_2020 as fact_2020
left join dim_scenario on dim_scenario.scenario_id = fact_2020.scenario_id
left join dim_status on dim_status.status_id = fact_2020.status_id
where month (transaction_time)= 1
GROUP BY transaction_type;


-- Task 2.1:

WITH fact_table AS (
    SELECT customer_id, transaction_time, charged_amount , transaction_id
    FROM fact_transaction_2019 fact_19 
    JOIN dim_scenario sce ON fact_19.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = '1'
UNION
    SELECT customer_id, transaction_time, charged_amount, transaction_id
    FROM fact_transaction_2020 fact_20 
    JOIN dim_scenario sce ON fact_20.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = '1'
)
, t_rfm AS (
SELECT customer_id
    , DATEDIFF(DAY, MAX (transaction_time), '2020-12-31') AS Recency 
    , COUNT(transaction_id) AS Frequency
    , SUM (charged_amount) AS Monetary
FROM fact_table
GROUP BY customer_id
)
, t_rank AS (
SELECT *
, PERCENT_RANK() OVER ( order by recency ASC ) AS r_rank
, PERCENT_RANK() OVER ( order by frequency DESC ) AS f_rank
, PERCENT_RANK() OVER ( order by monetary DESC ) AS m_rank
FROM t_rfm
)
, t_tier AS (
SELECT *
, CASE WHEN r_rank > 0.75 THEN 4
WHEN r_rank > 0.5 THEN 3
WHEN r_rank > 0.25 THEN 2
ELSE 1
END AS r_tier
, CASE WHEN f_rank > 0.75 THEN 4
WHEN f_rank > 0.5 THEN 3
WHEN f_rank > 0.25 THEN 2
ELSE 1
END AS f_tier
, CASE WHEN m_rank > 0.75 THEN 4
WHEN m_rank > 0.5 THEN 3
WHEN m_rank > 0.25 THEN 2
ELSE 1
END AS m_tier
FROM t_rank
)
, t_score AS (
SELECT *
, CONCAT (r_tier, f_tier, m_tier) AS rfm_score
FROM t_tier
)
SELECT *
, CASE
WHEN rfm_score = 111 THEN 'Best Customers' -- KH tốt nhất
WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer' -- KH rời bỏ mà còn siêu tệ (F <= 2)
WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' -- KH cũng rời bỏ nhưng có valued (F = 3,4,5)
WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost' -- sắp lost những KH này
WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' -- chi nhiều tiền
WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' -- KH mới nên là giao dịch ít
WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' -- ngủ đông (trc đó từng rất là tốt )
WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' -- có tiềm năng
ELSE 'unknown'
END segment_label
FROM t_score;

WITH fact_table AS (
    SELECT fact_19.*
    FROM fact_transaction_2019 fact_19 
    JOIN dim_scenario sce ON fact_19.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1
UNION
    SELECT fact_20.*
    FROM fact_transaction_2020 fact_20 
    JOIN dim_scenario sce ON fact_20.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1
)

SELECT customer_id
    , DATEDIFF(DAY, MAX (transaction_time), '2020-12-31') AS Recency 
    , COUNT( DISTINCT FORMAT(transaction_time, 'yy.mm.dd')) AS Frequency
    , SUM (charged_amount * 1.0) AS Monetary
FROM fact_table
GROUP BY customer_id;

select * from dim_scenario;

WITH temp_table AS(
SELECT transaction_id 
    , customer_id 
    , transaction_time
    , charged_amount
FROM (SELECT * FROM fact_transaction_2019
    UNION 
    SELECT * FROM fact_transaction_2020) AS fact_trans 
LEFT JOIN dim_status sta ON fact_trans.status_id = sta.status_id 
LEFT JOIN dim_scenario sce ON fact_trans.scenario_id = sce.scenario_id 
WHERE status_description = 'Success'
    AND category = 'Billing'
)
,rfm_metric AS(
    SELECT customer_id 
        , DATEDIFF(day, MAX(transaction_time), '2020-12-31') AS recency
        , COUNT(transaction_id) AS frequency
        , SUM(charged_amount*1.0) AS monetary
    FROM temp_table
    GROUP BY customer_id
)
,rfm_rank_percent AS(
    SELECT *
        , PERCENT_RANK() OVER(ORDER BY recency) AS r_percent_rank
        , PERCENT_RANK() OVER(ORDER BY frequency DESC) AS f_percent_rank
        , PERCENT_RANK() OVER(ORDER BY monetary DESC) AS m_percent_rank
    FROM rfm_metric
)
,rfm_tier AS (
    SELECT *
        , CASE WHEN r_percent_rank > 0.75 THEN 4
            WHEN r_percent_rank > 0.5 THEN 3
            WHEN r_percent_rank > 0.25 THEN 2
            ELSE 1 END AS r_tier
        , CASE WHEN f_percent_rank > 0.75 THEN 4
            WHEN f_percent_rank > 0.5 THEN 3
            WHEN f_percent_rank > 0.25 THEN 2
            ELSE 1 END AS f_tier
        , CASE WHEN m_percent_rank > 0.75 THEN 4
            WHEN m_percent_rank > 0.5 THEN 3
            WHEN m_percent_rank > 0.25 THEN 2
            ELSE 1 END m_tier
    FROM rfm_rank_percent
)
,rfm_group AS (
    SELECT *
        , CONCAT(r_tier,f_tier,m_tier) AS rfm_score 
    FROM rfm_tier
)
, segment_table AS(
    SELECT *
        , CASE WHEN rfm_score = 111 THEN 'Best customers'
            WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Best customers' 
            WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost customers' 
            WHEN rfm_score LIKE '21[1-4]' THEN 'Almost lost' 
            WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal customers' 
            WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spender' 
            WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New customers'
            WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating'
            WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalist'   
            ELSE 'unknown' END AS segment
    FROM rfm_group
)
SELECT segment 
    , COUNT(customer_id) AS nb_customer
    , SUM(COUNT(customer_id)) OVER() AS total_customer
    , FORMAT( COUNT(customer_id)*1.0 / SUM(COUNT(customer_id)) OVER() , 'p') AS pct_segment
FROM segment_table
GROUP BY segment;


