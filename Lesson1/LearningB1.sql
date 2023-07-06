-- LESSON 1: SIMPLE QUERY

-- 1. Hien thi ket qua
SELECT 'Lop chung minh la k21', 
        'Ngay khia giang la hom nay'
-- 2. Hien thi data tu bang database
SELECT CustomerID, LastName, MiddleName,
        MiddleName + LastName AS FullName
FROM SalesLT.Customer
ORDER BY FullName DESC, CustomerID DESC;
--> chung ta co 3 cach dat ten
-- camel: HoVaTen
-- snake: ho_va_ten
-- pascal: HoVaTen

--> SQL: case insensitive

--3. Sắp xếp kết quả
-- thu tu SQL thuc hien FROM --> SELECT --> ORDER BY
--4. chon loc du lieu
SELECT *
FROM SalesLT.Product
WHERE Color = 'Black' AND ListPrice > 1000
-- so sanh voi IN
SELECT *
FROM SalesLT.Product
WHERE Color IN ('Black', 'Red', 'White') 
     AND SellStartDate BETWEEN '2005-01-01' AND '2005-12-31'
-- so sanh voi LIKE
SELECT *
FROM SalesLT.Product
WHERE Name LIKE '%Bike%'

SELECT *
FROM SalesLT.Product
WHERE ProductNumber LIKE 'SO-%L'

SELECT *
FROM SalesLT.Product
WHERE ProductNumber LIKE 'SO-___%'

SELECT *
FROM SalesLT.Product
WHERE ProductNumber LIKE 'SO-[B-T]%' -- bắt đầu bằng chữ "SO-", kí tự thứ 4 là chữ B->T

SELECT DISTINCT Color -- HIEN THI va loai bo nhung dong bi trung
FROM SalesLT.Product

