
--Lesson 3 -- JOIN & UNION
-- 1. JOIN: Ghép bảng
--> why? mở rộng data, tối ưu query

/*
Write a query using SalesLT.ProductCategory and SalesLT.Product,
display ProductID, ProductName, Color and ProductCategoryID of product
which ProductCategoryName contains 'Mountain'
*/
-- Bai 12:
SELECT p.ProductID, p.Name, Color, pc.ProductCategoryID
FROM SalesLT.Product p
JOIN SalesLT.ProductCategory pc
ON p.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name LIKE '%Mountain%'

-- BAI 13:
SELECT sh.SalesOrderID, SalesOrderDetailID, sp.ProductID, Name, OrderDate, LineTotal, Subtotal
FROM SalesLT.SalesOrderHeader sh
JOIN SalesLT.SalesOrderDetail sd
ON sh.SalesOrderID = sd.SalesOrderID
JOIN SalesLT.Product sp
ON sd.ProductID = sp.ProductID

-- BAI 11:
/*
Retrieve customer orders:
As an initial step towards generating the invoice report, write a query that returns the
company name from the SalesLT.Customer table, and the sales order ID and total due from
the SalesLT.SalesOrderHeader table.
*/
SELECT c.CompanyName, sh.SalesOrderID, sh.TotalDue
FROM SalesLT.Customer c
JOIN SalesLT.SalesOrderHeader sh
ON c.CustomerID = sh.CustomerID

-- join voi loai nao thi dung scenario_id


--> GIỚI THIỆU BỘ DATABASE MỚI : PAYTM


SELECT TOP 3 * FROM fact_transaction_2019 -- 400k dòng


SELECT TOP 3 * FROM fact_transaction_2020 -- 800k dòng


SELECT COUNT (*) FROM fact_transaction_2019


SELECT * FROM dim_scenario


SELECT *
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
-- WHERE transaction_time BETWEEN '2019-02-01' AND '2019-03-01' -- lấy giao dịch của tháng 2
WHERE MONTH (transaction_time) = 2
-- 21,567 dòng
SELECT * FROM dim_status


SELECT *
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta
ON fact_19.status_id = sta.status_id
-- WHERE transaction_time BETWEEN '2019-02-01' AND '2019-03-01' -- lấy giao dịch của tháng 2
WHERE MONTH (transaction_time) = 2
AND status_description = 'success'


SELECT * FROM dim_payment_channel
SELECT * FROM dim_platform




-- 2. UNION : Gộp data, gộp kết quả


SELECT 'Hieu' AS name , 'Nam' AS gender
UNION ALL
SELECT 'Hieu', 'Nam'


SELECT 'Hieu' AS name , 'Nam' AS gender
UNION
SELECT 'Hieu', 'Nam'
UNION
SELECT 'Chau', 'Nu'


--> lấy cho mình tất cả các giao dịch trong tháng 1 2019 và tháng 3 năm 2020


SELECT transaction_id, customer_id, transaction_time, scenario_id
FROM fact_transaction_2019
WHERE MONTH (transaction_time ) = 1 -- 21,712 dòng
UNION
SELECT transaction_id, customer_id, transaction_time, scenario_id
FROM fact_transaction_2020
WHERE MONTH (transaction_time ) = 3 -- 49,858 dòng


--> 71,570 dòng --> sau đó hãy JOIN với bảng scenario để biết thông tin laọi giao dịch là gì


SELECT fact_table.* -- lấy tất cả các column trong fact_table
, transaction_type
, category
, sub_category
FROM (
SELECT transaction_id, customer_id, transaction_time, scenario_id
FROM fact_transaction_2019
WHERE MONTH (transaction_time ) = 1 -- 21,712 dòng
UNION
SELECT transaction_id, customer_id, transaction_time, scenario_id
FROM fact_transaction_2020
WHERE MONTH (transaction_time ) = 3 -- 49,858 dòng
) AS fact_table
LEFT JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id
WHERE transaction_type IS NULL


--> có 9,280 giao dịch không tìm dc thông tin scenario


