SELECT 'Toi ten la ' + ' Neil ' --> ghép


SELECT 'Toi ten la ' + 100 --> phép tính cộng


SELECT CustomerID , FirstName, MiddleName, LastName
, FirstName + MiddleName + LastName AS full_name --?
FROM SalesLT.Customer

--> NULL là giá trị rỗng (không có gì cả ) --> Thiếu data


--> Thay thế giá trị NULL : ISNULL (column, new_value)


SELECT CustomerID , FirstName, MiddleName, LastName
, ISNULL (MiddleName, '-') AS new_mn
, FirstName + ISNULL (MiddleName, '-') + LastName AS full_name --?
FROM SalesLT.Customer


--> tại sao bị lỗi ?
--> FROM --> SELECT


-- NULL không xử lý tính toán được


--> CHUYỂN ĐỔI KIỂU DỮ LIỆU : CAST (column AS new_data_type)


--> chuyển data dạng INT --> Varchar


SELECT CustomerID , FirstName, MiddleName, LastName
, CAST ( customerID AS varchar(10) ) + ' ' + LastName AS customer_name
FROM SalesLT.Customer


-- CONVERT ( new_data_type, column , [style] ) --> dùng CONVERT cho data dạng DATETIME --> STRING


SELECT CustomerID , FirstName, MiddleName, LastName
, CAST ( customerID AS varchar(10) ) + ' ' + LastName AS customer_name
, CONVERT ( varchar(10), customerID ) + ' ' + LastName AS customer_name
FROM SalesLT.Customer


SELECT CustomerID , ModifiedDate
, CAST ( ModifiedDate AS varchar ) AS new_date
, CONVERT ( varchar , ModifiedDate, 102 ) new_date
FROM SalesLT.Customer


-- YYYY-MM-DD
SELECT CustomerID , FirstName, MiddleName, LastName
, CONCAT ( FirstName, ' ' , MiddleName, ' ' , LastName ) AS full_name
FROM SalesLT.Customer


--> sau này muốn ghép chuỗi thì cứ dùng CONCAT nhe !


-- 2. Các FUNCTION xử lý THỜI GIAN


SELECT ProductID , SellStartDate
, YEAR (SellStartDate )
, MONTH (SellStartDate)
, DAY (SellStartDate)
, DATEPART ( week, SellStartDate )
, GETDATE () --> return current time
, DATEADD (hour, 7, GETDATE ())
, DATEDIFF (year, SellStartDate, GETDATE () )
FROM SalesLT.Product
-- 3. CÁC FUNCTIONS XỬ LÝ STRING


SELECT CustomerID , CompanyName
, LEN (CompanyName) AS lenght
, LEFT (CompanyName, 6) AS l_6
, RIGHT (CompanyName, 6) AS r_6
, CHARINDEX ('b', CompanyName) AS b_index --> nếu tìm vị trí chữ thứ 2 ?
, SUBSTRING (CompanyName, 3, 4) AS sub_string
, REPLACE (CompanyName, 'Bike', 'Car') AS replace_string
FROM SalesLT.Customer

--> Bài tập: Tìm cho mình tên của Saleman trong cột SalesPerson (pamela0, david8, )

-- Kiều Anh Lê
SELECT CustomerID, SalesPerson
, RIGHT(SalesPerson, LEN(SalesPerson)-CHARINDEX('\',SalesPerson)) AS sales_man
FROM SalesLT.Customer

-- Mark - Luan Nguyen
SELECT CustomerID, SalesPerson,
SUBSTRING(SalesPerson,CHARINDEX('\', SalesPerson)+1,len(SalesPerson))
From SalesLT.Customer

SELECT CustomerID, SalesPerson
, REPLACE (SalesPerson, 'adventure-works\', '') AS saleman
FROM SalesLT.Customer

-- 4.1 CASE WHEN (giống IF ELSE trong Excel)
-- CASE WHEN condition_1 THEN value_1
-- WHEN condition_2 THEN value_2
-- WHEN condition_3 THEN value_3
-- ...
-- ELSE 'value_còn_lại'
-- END
SELECT ProductID, ListPrice
, price_segment =
CASE WHEN ListPrice < 100 THEN N'thấp'
WHEN ListPrice < 1000 THEN N'trung bình'
ELSE 'cao'
END
FROM SalesLT.Product

-- IIF (mệnh đề, value_1, value_2):


SELECT IIF (2 > 5, 'yes', 'no')

SELECT ProductID, ListPrice
, price_segment = IIF (ListPrice < 100 , N'thấp', 'cao')
FROM SalesLT.Product

--> BUILT IN functions: hàm có sẵn
--> biến đổi data


--> 1. Ghép chuỗi : CONCAT (), CONCAT_WS ()
SELECT FirstName, MiddleName, LastName
, CONCAT_WS (' ', FirstName, MiddleName, LastName )
FROM SalesLT.Customer
--> 2. Chuyển đổi data type : CAST (), CONVERT ()

--> 3. Biến đổi data dạng thời gian : DAY(), YEAR(), DATEPART(), DATEADD(), DATEDIFF()

--> 4. Biến đổi data dạng STRING: LEN(), LEFT(), RIGHT(), SUBSTRING (), CHARINDEX (), REPLACE ()

--> 5. Xử lý nhiều logic: CASE WHEN , IIF

