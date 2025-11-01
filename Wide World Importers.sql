
USE WideWorldImporters

GO

WITH TBL1 AS
(
SELECT YEAR(i.InvoiceDate) InvoiceYear,
SUM(il.ExtendedPrice - il.TaxAmount) IncomePerYear,
COUNT(DISTINCT MONTH(i.InvoiceDate)) NumberOfDistinctMonths
FROM Sales.Invoices i JOIN Sales.InvoiceLines il
ON i.InvoiceID = il.InvoiceID
GROUP BY  YEAR(i.InvoiceDate)
),
TBL2 AS
(
SELECT *, TBL1.IncomePerYear * 12 / TBL1.NumberOfDistinctMonths YearlyLinearIncome
FROM TBL1
)
SELECT TBL2.InvoiceYear, TBL2.IncomePerYear, TBL2.NumberOfDistinctMonths,
FORMAT(CAST(TBL2.YearlyLinearIncome AS MONEY), '#,#.00') YearlyLinearIncome,
FORMAT(CAST(100 * TBL2.YearlyLinearIncome / LAG(TBL2.YearlyLinearIncome)
OVER(ORDER BY TBL2.InvoiceYear) - 100 AS MONEY), '#,#.00') GrowthRate
FROM TBL2
ORDER BY InvoiceYear

GO

WITH TBL AS
(
SELECT YEAR(i.InvoiceDate) TheYear, DATEPART(Q, i.InvoiceDate) TheQuarter, c.CustomerName,
SUM(il.ExtendedPrice - il.TaxAmount) IncomePerYear,
ROW_NUMBER() OVER(PARTITION BY YEAR(i.InvoiceDate), DATEPART(Q, i.InvoiceDate)
ORDER BY SUM(il.ExtendedPrice - il.TaxAmount) DESC) DNR
FROM Sales.Invoices i JOIN Sales.Orders o
ON  i.OrderID = o.OrderID
JOIN Sales.Customers c
ON o.CustomerID = c.CustomerID
JOIN Sales.InvoiceLines il
ON i.InvoiceID = il.InvoiceID
GROUP BY YEAR(i.InvoiceDate), DATEPART(Q, i.InvoiceDate) , c.CustomerName
)
SELECT * FROM TBL
WHERE DNR <= 5
ORDER BY TheYear, TheQuarter, IncomePerYear DESC

GO

SELECT TOP 10 wsi.StockItemID, wsi.StockItemName,
SUM(il.ExtendedPrice - il.TaxAmount) AS TotalProfit
FROM Sales.InvoiceLines il JOIN Warehouse.StockItems wsi
ON il.StockItemID = wsi.StockItemID
GROUP BY  wsi.StockItemID, wsi.StockItemName
ORDER BY TotalProfit DESC

GO

SELECT ROW_NUMBER() OVER(ORDER BY wsi.RecommendedRetailPrice - wsi.UnitPrice DESC) Rn,
wsi.StockItemID, wsi.StockItemName, wsi.UnitPrice, wsi.RecommendedRetailPrice,
wsi.RecommendedRetailPrice - wsi.UnitPrice NominalProductProfit,
DENSE_RANK() OVER(ORDER BY wsi.RecommendedRetailPrice - wsi.UnitPrice DESC) DNR
FROM Warehouse.StockItems wsi
WHERE wsi.ValidTo > GETDATE()
ORDER BY Rn

GO

WITH TBL AS
(
SELECT sup.SupplierID, CONCAT(sup.SupplierID, ' - ', sup.SupplierName) SupplierDetails,
STRING_AGG(CONCAT(StockItemID, ' ', StockItemName), ' /, ') ProductDetails
FROM Purchasing.Suppliers sup
JOIN Warehouse.StockItems wsi ON sup.SupplierID = wsi.SupplierID
GROUP BY CONCAT(sup.SupplierID, ' - ', sup.SupplierName), sup.SupplierID
)
SELECT SupplierDetails, ProductDetails
FROM TBL
ORDER BY SupplierID

GO

WITH TBL AS
(
SELECT cus.CustomerID, cit.CityName, coun.CountryName, coun.Continent, coun.Region,
SUM(il.ExtendedPrice) AS TotalPrice
FROM Sales.InvoiceLines il JOIN Sales.Invoices i
ON il.InvoiceID = i.InvoiceID
JOIN Sales.Customers cus
ON cus.CustomerID = i.CustomerID
JOIN Application.Cities cit
ON cus.PostalCityID = cit.CityID
JOIN Application.StateProvinces prov
ON prov.StateProvinceID = cit.StateProvinceID
JOIN Application.Countries coun
ON coun.CountryID = prov.CountryID
GROUP BY cus.CustomerID, cit.CityName, coun.CountryName, coun.Continent, coun.Region
)
SELECT TOP 5 CustomerID, CityName, CountryName, Continent, Region,
FORMAT(TotalPrice, '#,#.00') TotalExtendedPrice
FROM TBL
ORDER BY TotalPrice DESC

GO

WITH Monthly AS
(
SELECT YEAR(i.InvoiceDate) OrderYear, MONTH(i.InvoiceDate) OrderMonth,
SUM(il.ExtendedPrice - il.TaxAmount) SumTotal
FROM Sales.InvoiceLines il
JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
),
Calculated AS
(
SELECT Monthly.OrderYear, Monthly.OrderMonth IntMonth,
CAST(Monthly.OrderMonth AS VARCHAR) OrderMonth,
Monthly.SumTotal MonthlyTotal,
SUM(Monthly.SumTotal) OVER(PARTITION BY Monthly.OrderYear ORDER BY Monthly.OrderMonth) CumulativeTotal
FROM Monthly
UNION
SELECT Monthly.OrderYear, 13, 'Grand Total',
SUM(Monthly.SumTotal) OVER(PARTITION BY Monthly.OrderYear),
SUM(Monthly.SumTotal) OVER(PARTITION BY Monthly.OrderYear)
FROM Monthly
)
SELECT Calculated.OrderYear, Calculated.OrderMonth,
FORMAT(Calculated.MonthlyTotal, '#,#.00') MonthlyTotal,
FORMAT(Calculated.CumulativeTotal, '#,#.00') CumulativeTotal
FROM Calculated
ORDER BY Calculated.OrderYear, Calculated.IntMonth

GO

SELECT OrderMonth, [2013], [2014], [2015], ISNULL([2016], 0) "2016"
FROM
(
SELECT YEAR(o.OrderDate) OrderYear,
MONTH(o.OrderDate) OrderMonth,
COUNT(o.OrderID) OrderCount
FROM Sales.Orders o
GROUP BY Year(o.OrderDate), Month(o.OrderDate)
) Dates
PIVOT (SUM(Dates.OrderCount) FOR OrderYear IN ([2013],[2014],[2015],[2016])) PVT
ORDER BY OrderMonth

GO

WITH AllOrders AS
(
SELECT c.CustomerID, c.CustomerName, o.OrderDate,
LAG(OrderDate) OVER(PARTITION BY c.CustomerID ORDER BY o.OrderDate) PreviousOrderDate
FROM Sales.Customers c
JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
),
OrderDifferences AS
(
SELECT *,
AVG(DATEDIFF(D, PreviousOrderDate, OrderDate)) OVER(PARTITION BY CustomerID) AvgDaysBetweenOrders,
MAX(OrderDate) OVER(PARTITION BY CustomerID) LastCustOrderDate,
MAX(OrderDate) OVER() LastOrderDateAll,
DATEDIFF(D, MAX(OrderDate) OVER(PARTITION BY CustomerID), MAX(OrderDate) OVER() ) DaysSinceLastOrder
FROM AllOrders
)
SELECT *, CASE WHEN DaysSinceLastOrder > 2 * AvgDaysBetweenOrders
THEN 'Potential Churn'
ELSE 'Active' END CustomerStatus
FROM OrderDifferences

GO

WITH TBL AS
(
SELECT cat.CustomerCategoryName,
COUNT(DISTINCT CASE WHEN cus.Customername LIKE '%wingtip%' THEN 'Wingtip'
WHEN cus.Customername LIKE '%tailspin%' THEN 'Tailspin' 
ELSE cus.Customername END) CustomerCOUNT
FROM Sales.CustomerCategories cat JOIN Sales.Customers cus
ON cat.CustomerCategoryID = cus.CustomerCategoryID
GROUP BY cat.CustomerCategoryName
)
SELECT *, SUM(CustomerCOUNT) OVER() TotalCustCount, 
FORMAT(CAST(CustomerCount AS Money) / CAST(SUM(CustomerCount) OVER() AS Money),'P') DistributionFactor
FROM TBL
ORDER BY CustomerCategoryName

GO