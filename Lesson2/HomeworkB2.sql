/*
o	Each customer has an assigned salesperson. You must write a query to create a call sheet that lists:
	The salesperson
	A column named CustomerName that displays how the customer contact should be greeted (for example, Mr Smith)
	The customer’s phone number.
*/
SELECT RIGHT(SalesPerson, LEN(SalesPerson)-CHARINDEX('\',SalesPerson)) AS SalesPerson
       , CONCAT(Title, ' ', FirstName) AS CustomerName
       , Phone
FROM SalesLT.Customer

-- 1.2
/*
Transportation costs are increasing and you need to identify the heaviest products. Retrieve the names, weight of the top ten percent of products by weight. 
Then, add new column named Number of sell days (caculated from SellStartDate and SellEndDate) of these products (if sell end date isn't defined then get Today date) 
*/
SELECT TOP 10 PERCENT Name, Weight
       , DATEDIFF(DAY, SellStartDate, ISNULL(SellEndDate, GETDATE())) AS NumberOfSellDays
FROM SalesLT.Product
ORDER BY Weight DESC

-- Task 2:
-- 2.1 Retrieve a list of customer companies
--You have been asked to provide a list of all customer companies in the format Customer ID : Company Name - for example, 78: Preferred Bikes

SELECT CONCAT(CustomerID, ' ', CompanyName) AS CustomerCompanies
FROM SalesLT.Customer

-- 2.2 oThe SalesLT.SalesOrderHeader table contains records of sales orders. You have been asked to retrieve data for a report that shows:
--The sales order number and revision number in the format () – for example SO71774 (2).
--The order date converted to ANSI standard 102 format (yyyy.mm.dd – for example 2015.01.31).

SELECT CONCAT(SalesOrderNumber, '(' , RevisionNumber, ')') AS SalesOrderNumber
       , CONVERT ( varchar , OrderDate, 102 ) OrderDate
FROM SalesLT.SalesOrderHeader

-- Task 3:
-- 3.1
SELECT CONCAT_WS(' ', FirstName, MiddleName, LastName) AS CustomerFullName
FROM SalesLT.Customer
-- 3.2
SELECT CustomerID,
       CASE WHEN EmailAddress IS NULL THEN Phone
            ELSE EmailAddress
       END AS PrimaryContact
FROM SalesLT.Customer

-- c2 ISNULL(EmailAddress, Phone) AS PrimaryContact
-- c3 COALESCE(EmailAddress, Phone) AS PrimaryContact --> COALESCE trả về giá trị đầu tiên khác NULL
-- c4 IIF(EmailAddress IS NULL, Phone, EmailAddress) AS PrimaryContact

-- 3.3
SELECT CustomerID, CompanyName
       , CONCAT(' ', FirstName, ' ', LastName) AS ContactNames
       , Phone
FROM SalesLT.Customer
WHERE CustomerID NOT IN (SELECT CustomerID FROM SalesLT.CustomerAddress)
/*
returns phone numbers for customers with no address stored in the database.
*/
SELECT ProductID, Name, SellStartDate
      , ISNULL(Size, 'None') AS Size
      , ISNULL(Weight, 0) AS Weight
FROM SalesLT.Product
WHERE Name LIKE '%mountain%' AND SellStartDate BETWEEN '2005-07-01' AND '2007-07-01'

SELECT ProductID, Name, StandardCost, ListPrice, ListPrice - StandardCost AS Profit
FROM SalesLT.Product


SELECT COUNT(CustomerID)
FROM SalesLT.Customer

SELECT CustomerID FROM SalesLT.CustomerAddress

SELECT SalesOrderID, CONVERT(varchar, DueDate, 34) AS DueDate
       , CONVERT(varchar, ShipDate, 34) AS ShipDate
       , Status
FROM SalesLT.SalesOrderHeader

SELECT SalesOrderID
    ,CONVERT(nvarchar,DueDate,103) AS DueDate
    ,CONVERT(nvarchar,ShipDate,103) AS ShipDate         -- Tuỳ vào mọi người lấy mốc chuẩn để trừ như thế nào mà kết quả 
    ,DATEDIFF(DAY,ShipDate,DueDate) AS DoneBeforeDue    -- sẽ âm hoặc dương từ đó mình sẽ hiểu theo tham chiếu đó nhé
FROM SalesLT.SalesOrderHeader

SELECT DISTINCT sp.ProductID, sp.Name, sp.Size, sp.ListPrice, spc.ProductCategoryID
FROM SalesLT.Product sp
JOIN SalesLT.SalesOrderDetail sod 
ON sp.ProductID = sod.ProductID AND sod.OrderQty > 2
JOIN SalesLT.ProductCategory spc
ON sp.ProductCategoryID = spc.ProductCategoryID
WHERE spc.Name IN ('Road Frames', 'Touring Frames')

SELECT ProductID
    ,Name
    ,[Size]
    ,ListPrice
    ,ProductCategoryID
FROM SalesLT.Product
WHERE ProductID IN (SELECT DISTINCT ProductID FROM SalesLT.SalesOrderDetail
                    WHERE OrderQty > 2 )
    AND ProductCategoryID IN (SELECT DISTINCT ProductCategoryID FROM SalesLT.ProductCategory 
                    WHERE Name IN ('Road Frames','Touring Frames'))
