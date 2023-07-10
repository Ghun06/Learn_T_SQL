-- LESSON 4: SUBQUERY - CTE - GROUP BY


-- 1. SUBQUERY (Truy vấn lồng)


--> Mục đích: truy vấn data từ một câu lệnh khách (từ bảng khác, bảng đó)


--> 1.1 Nằm SELECT : phải return về duy nhất 1 giá trị


--> Hàm tính tổng: COUNT (), MAX (), MIN (), AVG (), SUM ()


--> yêu cầu, show thêm 1 column thứ tư: giá trị số tiền lớn nhất trong tháng 1/2020
SELECT customer_id, transaction_id, charged_amount
, ( SELECT MAX (charged_amount)
FROM fact_transaction_2020
WHERE MONTH (transaction_time) = 1 ) AS max_value_jan_2020
, ( SELECT COUNT (DISTINCT customer_id)
FROM fact_transaction_2020
WHERE MONTH (transaction_time) = 1) AS number_customer_jan_2020
, ( SELECT SUM (CAST (charged_amount AS decimal))
FROM fact_transaction_2020
WHERE MONTH (transaction_time) = 1) AS total_money_jan_2020
FROM fact_transaction_2019
WHERE MONTH (transaction_time) = 1

-- 1.2 Nằm FROM --> tạo ra 1 bảng trung gian --> mình dùng cái bảng này để làm tiếp bước khác
-- hãy gộp data tháng 1/2019 và tháng 1/2020 lại --> JOIN với bảng scenario

SELECT *
FROM (
SELECT *
FROM fact_transaction_2019
WHERE MONTH (transaction_time) = 1
UNION
SELECT *
FROM fact_transaction_2020
WHERE MONTH (transaction_time) = 1
) AS fact_table
JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id

-- 1.3 Nằm ở WHERE --> dùng để so sánh


SELECT *
FROM fact_transaction_2020
WHERE promotion_id = '0'
AND customer_id IN ( SELECT DISTINCT customer_id
FROM fact_transaction_2019 AS fact_19
JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
WHERE promotion_id <> '0'
AND sub_category = 'electricity'
AND MONTH (transaction_time) = 1 ) ;




-- 2. CTE: tạo bảng tạm bằng câu truy vấn


SELECT *
FROM (
SELECT *
FROM fact_transaction_2019
WHERE MONTH (transaction_time) = 1
UNION
SELECT *
FROM fact_transaction_2020
WHERE MONTH (transaction_time) = 1
) AS fact_table --> Subquery
JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id


-- CTE:
WITH fact_table AS ( -- step 1
SELECT *
FROM fact_transaction_2019
WHERE MONTH (transaction_time) = 1
UNION
SELECT *
FROM fact_transaction_2020
WHERE MONTH (transaction_time) = 1
)
, joined_table AS ( -- step 2
SELECT fact_table.*
FROM fact_table
JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id
)
SELECT joined_table.* -- step 3
FROM joined_table
JOIN dim_payment_channel AS channel
ON joined_table.payment_channel_id = channel.payment_channel_id


--> tại sao cần CTE?
--- > làm logic xử lý dễ dàng hơn : step 1, step 2, step 3 , ... (chúng ta có thể tạo nhiều CTE)
--- > dễ dàng sửa lỗi
--- > Các kết quả CTE không cần phải phụ thuộc lẫn nhau

--> example 1: hãy thống kê xem mỗi khách hàng trong năm 2019 ở từng tháng từ tháng 1 đến tháng 3, có bao nhiêu giao dịch thành công, và thanh toán bao nhiêu tiền, sử dụng bao nhiêu loại giao dịch (scenario_id)

SELECT customer_id
, COUNT (transaction_id) AS number_success_transactions
, SUM (charged_amount) AS total_money
, COUNT (DISTINCT scenario_id) AS number_of_scena
, MONTH (transaction_time) AS month
FROM fact_transaction_2019 fact_19
JOIN dim_status sta
ON fact_19.status_id = sta.status_id
WHERE status_description = 'success'
AND MONTH (transaction_time) < 4
GROUP BY customer_id, MONTH (transaction_time)
ORDER BY MONTH (transaction_time)

SELECT
MONTH (transaction_time) AS [month]
, customer_id
, COUNT (transaction_id) AS number_success_transactions
, SUM (charged_amount) AS total_money
, COUNT (DISTINCT scenario_id) AS number_of_scena
FROM fact_transaction_2019 fact_19
JOIN dim_status sta
ON fact_19.status_id = sta.status_id
WHERE status_description = 'success'
AND MONTH (transaction_time) < 4
GROUP BY MONTH (transaction_time), customer_id
HAVING COUNT (transaction_id) > 50
ORDER BY number_success_transactions ASC


--> THỨ SQL: from --> join --> where --> group by --> having --> select --> ORDER BY --> top N ...

-- Subquery --> truy vấn lồng --> tính toán xử lý thêm 1 bước (SELECT, FROM, WHERE)
-- CTE --> tạo bảng tạm trong câu truy vấn
-- GROUP BY : Gom nhóm những dòng cùng đối tượng, tính toán theo yêu (COUNT, MIN, MAX, SUM, AVG)


-- Tính xem mỗi tháng có bao nhiêu KH (2019)? Tính tỷ lệ % số KH của từng trên tổng số KH cả năm
WITH month_table AS (
SELECT MONTH (transaction_time) AS [month]
, COUNT (DISTINCT customer_id) AS number_customer
, ( SELECT COUNT (DISTINCT customer_id) FROM fact_transaction_2019 ) AS total_customer_year
FROM fact_transaction_2019
GROUP BY MONTH (transaction_time)
-- ORDER BY [month]
)
SELECT *
, number_customer *1.0 / total_customer_year AS percentage_month
FROM month_table


SELECT COUNT (DISTINCT customer_id) FROM fact_transaction_2019 --> 30,130 KH cả năm




