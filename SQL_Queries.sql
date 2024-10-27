
USE WideWorldImporters;

/* Exploring the DataBase */

--Application Schema

SELECT * FROM Application.Cities
SELECT * FROM Application.Cities_Archive
SELECT * FROM Application.Countries
SELECT * FROM Application.Countries_Archive
SELECT * FROM Application.DeliveryMethods
SELECT * FROM Application.DeliveryMethods_Archive
SELECT * FROM Application.PaymentMethods
SELECT * FROM Application.PaymentMethods_Archive
SELECT * FROM Application.People
SELECT * FROM Application.People_Archive
SELECT * FROM Application.StateProvinces
SELECT * FROM Application.StateProvinces_Archive
SELECT * FROM Application.SystemParameters
SELECT * FROM Application.TransactionTypes
SELECT * FROM Application.TransactionTypes_Archive

-- Purchasing Schema

SELECT * FROM Purchasing.PurchaseOrderLines
SELECT * FROM Purchasing.PurchaseOrders
SELECT * FROM Purchasing.SupplierCategories
SELECT * FROM Purchasing.SupplierCategories_Archive
SELECT * FROM Purchasing.Suppliers
SELECT * FROM Purchasing.Suppliers_Archive
SELECT * FROM Purchasing.SupplierTransactions

-- Sales Schema

SELECT * FROM Sales.BuyingGroups
SELECT * FROM Sales.BuyingGroups_Archive --empty
SELECT * FROM Sales.CustomerCategories
SELECT * FROM Sales.Customers
SELECT * FROM Sales.Customers_Archive
SELECT * FROM Sales.CustomerTransactions
SELECT * FROM Sales.InvoiceLines
SELECT * FROM Sales.Invoices
SELECT * FROM Sales.OrderLines
SELECT * FROM Sales.Orders
SELECT * FROM Sales.SpecialDeals

-- Warehouse Schema

SELECT * FROM Warehouse.ColdRoomTemperatures
SELECT * FROM Warehouse.ColdRoomTemperatures_Archive
SELECT * FROM Warehouse.Colors
SELECT * FROM Warehouse.PackageTypes
SELECT * FROM Warehouse.PackageTypes_Archive --empty
SELECT * FROM Warehouse.StockGroups
SELECT * FROM Warehouse.StockGroups_Archive
SELECT * FROM Warehouse.StockItemHoldings
SELECT * FROM Warehouse.StockItems
SELECT * FROM Warehouse.StockItems_Archive
SELECT * FROM Warehouse.StockItemStockGroups
SELECT * FROM Warehouse.StockItemTransactions
SELECT * FROM Warehouse.VehicleTemperatures

--************************************************************************

/*Detection of the Null Values across the whole database*/

declare @sql nvarchar(max)=N'';
select @sql = @sql + 'select ''' + Table_Name + ''' AS TableName ,
''' + Column_Name +  ''' As ColumnName , 
count (*) as nullcount
from ' + QUOTENAME( Table_Schema) + '.'
+ QUOTENAME( Table_Name) + 'where' + QUOTENAME( column_Name) + ' IS NULL  
having count(*) >0
UNION ALL '
/*QUOTENAME() was used to avoid syntax errors if the names of the columns and tables
 contain spaces or special characters like Order Details will become [Order Details]*/
from INFORMATION_SCHEMA.COLUMNS
where IS_NULLABLE='yes';
set @sql =LEFT ( @sql, len(@sql)-10);
set @sql =@sql + 'order by nullcount desc';
PRINT @sql
exec (@sql)

--************************************************************************

SELECT * FROM Warehouse.StockItemTransactions;

-- Due to the Transaction Type, when CustomerID and InvoiceID are empty,
-- the SupplierID and the PurchaseID are present

SELECT * 
FROM Warehouse.StockItemTransactions 
WHERE CustomerID IS NOT NULL AND SupplierID IS NULL;

SELECT * 
FROM Warehouse.StockItemTransactions 
WHERE CustomerID IS NULL AND SupplierID IS NOT NULL;

-- We have 44 records with the CustomerID, InvoiceID, SupplierID and the PurchaseID are empty
-- when the Transaction is Stock Adjustment at Stocktake

SELECT * 
FROM Warehouse.StockItemTransactions 
WHERE CustomerID IS NULL AND SupplierID IS NULL;

--************************************************************************

SELECT * FROM Application.Cities
SELECT * FROM Application.Cities_Archive

-- Are there records in the Cities_Archive that are not present in the current table?
-- No.
SELECT 
    CA.*
FROM 
    Application.Cities_Archive CA
LEFT JOIN 
    Application.Cities C
    ON CA.CityID = C.CityID
WHERE 
    C.CityID IS NULL;  -- Filters for records in Cities_Archive without a match in Cities

--************************************************************************

/* Understanding the customer transactions */
-- Here, we can see that the Transaction Types are Invoice and Payment Received. That's why the InvoiceID
-- and the PaymentMethodID may become null

-- Customer Transactions
SELECT * 
FROM Sales.CustomerTransactions
WHERE CustomerID = 832
AND TransactionDate = '2013-01-02 07:05:00.0000000';

-- Invoices
SELECT * 
FROM Sales.Invoices
WHERE CustomerID = 832
AND ConfirmedDeliveryTime = '2013-01-02 07:05:00.0000000';

-- Transaction Types
SELECT TransactionTypeID, TransactionTypeName
FROM Application.TransactionTypes
WHERE TransactionTypeID IN (1,3)

--************************************************************************

SELECT * FROM Warehouse.ColdRoomTemperatures_Archive;

-- Here we can see that every sensor has the same number of rooms responsible for.
SELECT 
    ColdRoomSensorNumber, 
    COUNT(DISTINCT ColdRoomTemperatureID) AS RoomCount 
FROM 
    Warehouse.ColdRoomTemperatures_Archive
GROUP BY 
    ColdRoomSensorNumber;

--************************************************************************

-- Checking archived stock groups
SELECT * FROM Warehouse.StockGroups;
SELECT * FROM Warehouse.StockGroups_Archive;

-- Note: When ID is 8, the name is slightly different in the archive. 
-- Using the current name and maybe analyzing the impact of changing the name in sales and marketing.

--************************************************************************

SELECT * FROM Warehouse.StockItems;
SELECT * FROM Warehouse.StockItems_Archive;

-- Retrieving stock items where ColorID is null and ordering by StockItemID
-- We can see that the name already has a color within it so we will use Python to solve this issue.

SELECT StockItemName, ColorID 
FROM Warehouse.StockItems 
WHERE ColorID is null
ORDER BY StockItemID;

-- Note: In the StockItems_Archive, even though the ID is duplicated, it wasn't detected using Python 
-- because the custom field is not repeated. 
-- One ID has value in that column and the same ID has null value before or after it.
-- Using the custom field to determine the manufacturing country and using the archive if the current has null values.

SELECT StockItemID, CustomFields FROM Warehouse.StockItems_Archive
ORDER BY StockItemID

--************************************************************************

/* The Quries written for Power BI */

--************************************************************************

-- Using JSON_VALUE and JSON_QUERY to extract information from VehicleTemperatureS and StockItems Tables


-- Warehouse VehicleTemperatures

SELECT
    VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature,
    JSON_VALUE(FullSensorData, '$.Recordings[0].geometry.coordinates[0]') AS Longitude,
    JSON_VALUE(FullSensorData, '$.Recordings[0].geometry.coordinates[1]') AS Latitude
FROM Warehouse.VehicleTemperatures

--************************************************************************

-- Extracting the Important Columns of StockItems Table for Python Cleaning

SELECT 
    SI.StockItemID, 
    SI.StockItemName,
    C.ColorName,
    SI.Size,
    SI.SupplierID, 
    SI.UnitPackageID,
    SI.OuterPackageID,
    SI.LeadTimeDays,
    SI.QuantityPerOuter,
    SI.IsChillerStock,
    SI.TaxRate,
    SI.UnitPrice,
    SI.RecommendedRetailPrice,
    SI.TypicalWeightPerUnit,
    SI.MarketingComments, 
    JSON_VALUE(SI.CustomFields, '$.CountryOfManufacture') AS ManufacturingCountry,
    JSON_QUERY(SI.CustomFields, '$.Tags') AS Tags,
    JSON_VALUE(SI.CustomFields, '$.Range') AS AgeGroup,
    JSON_VALUE(SI.CustomFields, '$.MinimumAge') AS MinimumAge,
    JSON_VALUE(SI.CustomFields, '$.ShelfLife') AS ShelfLife
FROM Warehouse.StockItems SI
LEFT JOIN
    Warehouse.Colors C ON C.ColorID = SI.ColorID;

--************************************************************************

-- Sales BackOrders

SELECT 
    o.BackorderOrderID,  
    o.OrderID, 
    ol.OrderLineID, 
    o.OrderDate 
FROM 
    Sales.Orders o 
LEFT JOIN 
    Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE 
    o.BackorderOrderID IS NOT NULL
ORDER BY 
    o.BackorderOrderID;
	
--************************************************************************

-- Understanding the Negative Values of Quantity in StockItemTransactions

SELECT * FROM Warehouse.StockItemTransactions

-- Note: From comparing the dates associated with each quantity:
--With Sales or some Stock Adjustment, the Quantity in the Stock will become negative and
-- positive when there is Supplier Receipts.

-- Stock Movements

SELECT 
    COALESCE(SIT.TransactionOccurredWhen, IL.LastEditedWhen) AS TransactionDate,
    SIT.StockItemID,
    SI.StockItemName,
    COALESCE(SIT.TransactionTypeID, 0) AS TransactionTypeID,
    TT.TransactionTypeName,
    COALESCE(SUM(SIT.Quantity), 0) AS StockQuantity, -- Total stock quantity
    COALESCE(SUM(CASE WHEN SIT.TransactionTypeID = 11 THEN SIT.Quantity ELSE 0 END), 0) AS TotalReceipts, -- Total received from suppliers
    COALESCE(SUM(CASE WHEN SIT.TransactionTypeID = 10 THEN SIT.Quantity ELSE 0 END), 0) AS TotalSales -- Total sales as positive
FROM 
    Warehouse.StockItemTransactions SIT
LEFT JOIN Sales.InvoiceLines IL
    ON SIT.StockItemID = IL.StockItemID
    AND SIT.TransactionOccurredWhen = IL.LastEditedWhen -- Match dates only for other transaction types
LEFT JOIN Warehouse.StockItems SI 
    ON SIT.StockItemID = SI.StockItemID
LEFT JOIN Application.TransactionTypes TT 
    ON TT.TransactionTypeID = SIT.TransactionTypeID
WHERE 
    TT.TransactionTypeID IN (10, 11)  -- Only include relevant transaction types (Sales and Receipts)
GROUP BY 
    SIT.StockItemID,
    SI.StockItemName,
    COALESCE(SIT.TransactionTypeID, 0),
    TT.TransactionTypeName,
    COALESCE(SIT.TransactionOccurredWhen, IL.LastEditedWhen) -- Include the date in GROUP BY
ORDER BY 
    SIT.StockItemID, 
    COALESCE(SIT.TransactionTypeID, 0);

--************************************************************************

--The location should be converted to be imported in Power BI

-- Sales Customers

SELECT 
    CustomerID, 
    CustomerName, 
    CustomerCategoryID, 
    BuyingGroupID,
    DeliveryMethodID, 
    DeliveryCityID, 
    Cities.CityName, 
    Cities.StateProvinceID,
    C.CreditLimit, 
    AccountOpenedDate, 
    PaymentDays, 
    CAST(DeliveryLocation AS VARCHAR(MAX)) AS DeliveryLocation
FROM 
    Sales.Customers C
LEFT JOIN 
    Application.Cities ON Cities.CityID = C.DeliveryCityID;

--************************************************************************

-- Purchasing Suppliers

SELECT 
    S.SupplierID, 
    SupplierName, 
    SupplierCategoryID, 
    DeliveryCityID, 
    Cities.CityName,
    Cities.StateProvinceID, 
    S.SupplierReference, 
    PaymentDays, 
    CAST(DeliveryLocation AS VARCHAR(MAX)) AS DeliveryLocation,
    DeliveryMethodID
FROM     
    Purchasing.Suppliers S
LEFT JOIN     
    Application.Cities ON Cities.CityID = S.DeliveryCityID;

--************************************************************************

-- Sales Invoices


SELECT
    InvoiceID,
    InvoiceDate,
    CustomerPurchaseOrderNumber,
    TotalDryItems,
    TotalChillerItems,
    ContactPersonID,
    AccountsPersonID,
    SalespersonPersonID,
    PackedByPersonID,
    DeliveryMethodID,
    JSON_VALUE(event.value, '$.Event') AS EventType,
    JSON_VALUE(event.value, '$.EventTime') AS EventTime,
    JSON_VALUE(event.value, '$.ConNote') AS ConsignmentNote,
    JSON_VALUE(event.value, '$.DriverID') AS DriverID,
    JSON_VALUE(event.value, '$.Latitude') AS Latitude,
    JSON_VALUE(event.value, '$.Longitude') AS Longitude,
    JSON_VALUE(event.value, '$.Status') AS Status,
    JSON_VALUE(ReturnedDeliveryData, '$.DeliveredWhen') AS DeliveredWhen,
    JSON_VALUE(ReturnedDeliveryData, '$.ReceivedBy') AS ReceivedBy

FROM Sales.Invoices
CROSS APPLY 
    OPENJSON(JSON_QUERY(ReturnedDeliveryData, '$.Events')) AS event
WHERE 
    JSON_VALUE(event.value, '$.Event') != 'Ready for collection';

--************************************************************************

/* Some Analysis */

-- Customer Last Order Date
SELECT 
    c.CustomerID,
    c.CustomerName,
    MAX(o.OrderDate) AS LastOrderDate
FROM 
    Sales.Customers c
JOIN 
    Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY 
    c.CustomerID, c.CustomerName
ORDER BY 
    LastOrderDate DESC;

--************************************************************************

-- Customer Order Count

SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM 
    Sales.Customers c
JOIN 
    Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY 
    c.CustomerID, c.CustomerName
ORDER BY 
    OrderCount DESC;

--************************************************************************

-- Monthly Average Order Value

SELECT 
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    AVG(ol.Quantity * ol.UnitPrice) AS AverageOrderValue
FROM 
    Sales.Orders o
JOIN 
    Sales.OrderLines ol ON o.OrderID = ol.OrderID
GROUP BY 
    YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY 
    Year, Month;

--************************************************************************

-- Monthly Sales Summary

SELECT 
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalSales
FROM 
    Sales.Orders o
JOIN 
    Sales.OrderLines ol ON o.OrderID = ol.OrderID
GROUP BY 
    YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY 
    Year, Month;

--************************************************************************

-- Recent Orders and Top Customers by Purchase Amount

SELECT TOP 10 * 
FROM Sales.Orders 
ORDER BY OrderDate DESC;

SELECT TOP 10
    c.CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalPurchaseAmount
FROM 
    Sales.Orders o
JOIN 
    Sales.OrderLines ol ON o.OrderID = ol.OrderID
JOIN 
    Sales.Customers c ON o.CustomerID = c.CustomerID
GROUP BY 
    c.CustomerName
ORDER BY 
    TotalPurchaseAmount DESC;

--************************************************************************

-- Supplier Product Count and Total Sales Analysis

SELECT 
    s.SupplierName,
    COUNT(DISTINCT p.StockItemID) AS NumberOfProducts,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalSales
FROM 
    Purchasing.Suppliers s
JOIN 
    Warehouse.StockItems p ON s.SupplierID = p.SupplierID
JOIN 
    Sales.OrderLines ol ON p.StockItemID = ol.StockItemID
GROUP BY 
    s.SupplierName
ORDER BY 
    TotalSales DESC;

--************************************************************************

-- Top 15 Cities by Total Sales and Orders

SELECT TOP 15
    countries.CountryName, 
	sp.StateProvinceName,
    c.CityName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalSales
FROM 
    Sales.Orders o
JOIN 
    Sales.OrderLines ol ON o.OrderID = ol.OrderID
JOIN 
    Sales.Customers cust ON o.CustomerID = cust.CustomerID
JOIN 
    Application.Cities c ON cust.DeliveryCityID = c.CityID
JOIN Application.StateProvinces sp on sp.StateProvinceID =c.StateProvinceID
JOIN Application.Countries on Countries.CountryID = sp.CountryID
GROUP BY 
    countries.CountryName, 
	sp.StateProvinceName,
	c.CityName
ORDER BY 
    TotalSales DESC;

--************************************************************************

-- Top 20 Best-Selling Stock Items by Total Revenue

SELECT TOP 20
    si.StockItemName,
    SUM(ol.Quantity) AS TotalQuantitySold,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalRevenue
FROM 
    Sales.OrderLines ol
JOIN 
    Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
GROUP BY 
    si.StockItemName
ORDER BY 
    TotalRevenue DESC;

--************************************************************************

-- Top Selling Stock Items by Quantity

SELECT 
    p.StockItemName,
    SUM(ol.Quantity) AS TotalQuantitySold
FROM 
    Warehouse.StockItems p
JOIN 
    Sales.OrderLines ol ON p.StockItemID = ol.StockItemID
GROUP BY 
    p.StockItemName
ORDER BY 
    TotalQuantitySold DESC;

--************************************************************************

-- Total Orders, Average Lead Time, and Total Items Received.sql

SELECT 
    s.SupplierName,
    COUNT(DISTINCT po.PurchaseOrderID) AS TotalOrders,
    AVG(DATEDIFF(day, po.OrderDate, po.ExpectedDeliveryDate)) AS AvgLeadTime,
    SUM(pol.ReceivedOuters) AS TotalItemsReceived
FROM 
    Purchasing.PurchaseOrders po
JOIN 
    Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN 
    Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
GROUP BY 
    s.SupplierName
ORDER BY 
    TotalOrders DESC;

--************************************************************************

