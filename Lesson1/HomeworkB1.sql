SELECT DISTINCT City, StateProvince
FROM SalesLT.Address
ORDER BY StateProvince ASC, City DESC


SELECT TOP 10 PERCENT Name, Weight
FROM SalesLT.Product
ORDER BY Weight DESC

--> FROM -> SELECT -> ORDER BY -> TOP N [PERSENT]

SELECT ProductNumber, Name, Color, Size 
FROM SalesLT.Product
WHERE Color IN ('Red', 'Black', 'White') AND Size IN ('S', 'M')

SELECT ProductNumber, Name, Color, Size 
FROM SalesLT.Product
WHERE  ProductNumber LIKE 'BK-%[^T]-[0-9][0-9]'  
       AND (Color IN ('Red', 'Black', 'White') 
       OR Size IN ('S', 'M'))

/*
Retrieve the product ID, product number, name, and list price of products whose product name contains "HL " or "Mountain", product number is at least 8 characters and never have been ordered.
*/
SELECT ProductID, ProductNumber, Name, ListPrice
FROM SalesLT.Product
Where ( Name LIKE '%HL%' OR Name LIKE '%mountain%' )
AND ProductNumber LIKE '________%'
AND ProductID NOT IN (SELECT DISTINCT ProductID FROM SalesLT.SalesOrderDetail)

SELECT DISTINCT ProductID FROM SalesLT.SalesOrderDetail

SELECT * 
FROM SalesLT.Product

-- (trường hợp giá trị NULL đối với ký tự dạng số thay bằng 0, ký tự dạng chuỗi thay bằng ‘None’)

