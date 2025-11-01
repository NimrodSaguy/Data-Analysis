GO

USE master

GO

--Creating a fresh database:
IF EXISTS (SELECT * from sysdatabases WHERE name='Golan')
	DROP DATABASE Golan

GO

CREATE DATABASE Golan

GO

USE Golan

GO

CREATE TABLE Employees
(EmployeeID INT IDENTITY(1000,10), EmployeeName VARCHAR(50) NOT NULL,
AuthorizationLevel INT, HireDate DATE NOT NULL, ManagerID INT,
CONSTRAINT EmployeeAuthorizations CHECK (AuthorizationLevel IN (0, 1, 2, 3)),
--Each employee has authorization to sell different packages
CONSTRAINT EmployeePK PRIMARY KEY(EmployeeID),
CONSTRAINT EmployeeFKManager FOREIGN KEY(ManagerID) REFERENCES Employees(EmployeeID))
--Each employee reports to one direct manager, except in the case of the CEO

GO

CREATE TABLE Customers
(CustomerID INT IDENTITY(10000,1), FirstName VARCHAR(30) NOT NULL, LastName VARCHAR(60) NOT NULL, 
Email VARCHAR(60), ContactNumber VARCHAR(15), JoinDate DATE DEFAULT GETDATE(),
PaymentMethod VARCHAR(30), LastFourDigits VARCHAR(4),
CONSTRAINT CustomerEmailFormat CHECK (Email IS NULL OR Email LIKE '%@%.%'),
CONSTRAINT CustomerContactFormat CHECK (ContactNumber IS NULL
OR ContactNumber LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
CONSTRAINT CustomerPaymentDigits CHECK (LastFourDigits IS NULL
OR LastFourDigits LIKE '[0-9][0-9][0-9][0-9]'),
--In the case of payment methods without numbers like PayPal, the last four digits remain Null
CONSTRAINT CustomerPK PRIMARY KEY(CustomerID))

GO

CREATE TABLE Phones
(PhoneNumber VARCHAR(15), CustomerID INT, DeviceCompany VARCHAR(20),
--The type of device and its company are relevant information, whether the device can access 5G or not
CONSTRAINT PhoneFormat CHECK (PhoneNumber LIKE '05[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
CONSTRAINT PhonePK PRIMARY KEY(PhoneNumber),
CONSTRAINT PhoneFKCustomer FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID))
--One customer may have multiple phones in their account

GO

CREATE TABLE Packages
(PackageID INT IDENTITY(100,10), PackageName VARCHAR(30), Price INT, RequiredAuthorization INT,
DurationInMonths INT, CallsAmount INT, SMSAmount INT, InternetGBAmount INT,
AbroadCallsAmount INT, AbroadSMSAmount INT, Includes5G BIT,
CONSTRAINT PackagePK PRIMARY KEY(PackageID), CONSTRAINT PackageNameUniqueness UNIQUE(PackageName))

GO

CREATE TABLE Purchases
(PurchaseID INT IDENTITY (100000, 1), PhoneNumber VARCHAR(15),
PackageID INT, PurchaseTime DATETIME, EmployeeID INT, 
CONSTRAINT PurchasePK PRIMARY KEY(PurchaseID),
CONSTRAINT PurchaseFKPhone FOREIGN KEY(PhoneNumber) REFERENCES Phones(PhoneNumber),
CONSTRAINT PurchaseFKPackage FOREIGN KEY(PackageID) REFERENCES Packages(PackageID),
CONSTRAINT PurchaseFKEmployee FOREIGN KEY(EmployeeID) REFERENCES Employees(EmployeeID))
--Each customer can purchase a package for a phone in their account from one employee at a time

GO


INSERT INTO Employees (EmployeeName, AuthorizationLevel, HireDate, ManagerID) VALUES
('Golan Golanchik', 3, '01-01-2020', NULL),
('John Bryce', 3, '01-01-2022', 1000),
('Nimrod Saguy', 2, '01-01-2025', 1010),
('Ovadiah Oved', 2, '01-01-2024', 1000),
('Adam Hadash', 2, '06-06-2024', 1000),
('Ned Ludd', 2, '05-05-2025', 1010)

GO

INSERT INTO Customers (FirstName, LastName, Email, ContactNumber, JoinDate, PaymentMethod, LastFourDigits) VALUES
('Golan', 'Golanchik', 'golanchik@golan.co.il', '0580585858', '02-01-2020', 'Card', '0058'),
('John', 'Bryce', 'jb@golan.co.il', '0587777777', '01-04-2022', 'Card', '1234'),
('Nimrod', 'Saguy', 'nimrod@gmail.com', '0549999999', '12-01-2024', 'Card', '9999'),
('Ovadiah', 'Oved', 'oved@gmail.com', '0520000000', '06-06-2023', 'Standing Order', '0000'),
('Ned', 'Ludd', NULL, '0770000077', '05-05-2025', NULL, NULL),
('Dina', 'Barzilay', '496351@idf.co.il', NULL, '12-31-2022', 'Card', '4963'),
('Metushelach', 'Zaken', NULL, '0501234567', '03-03-2020', 'Standing Order', '7777'),
('Avi', 'Avivi', 'avivi@gmail.com', '0501111111', '01-01-2021', 'Card', '1111'),
('Benny', 'Binyamini', 'benben@hotmail.com', '0520000001', '02-02-2021', 'Card', '2222'),
('Gadi', 'Gadasi', 'ohmygad@gmail.com', '0530000001', '03-03-2021', 'Card', '3333'),
('Danny', 'Danieli', NULL, '0540000001', '04-04-2021', 'Card', '4444'),
('Israela', 'Israeli', NULL, '0514051948', '05-14-2023', 'Card', '1948'),
('Alexander Graham', 'Bell', NULL, '0501010101', '01-01-2021', NULL, NULL),
('Barack', 'Obama', 'potus@gov.us', '0504071776', '07-04-2022', 'PayPal', NULL),
('Angela', 'Merkel', 'merkel@gov.de', '0580008888', '01-01-2023', 'Card', '8888'),
('Zehava', 'Dov', 'eyfo@daysa.com', '0500607213', '03-03-2023', 'PayPal', NULL)

GO

INSERT INTO Phones (PhoneNumber, CustomerID, DeviceCompany) VALUES
('0580585858', 10000, 'Apple'),
('0587777777', 10001, 'Samsung'),
('0549999999', 10002, 'Samsung'),
('0520000000', 10003, 'Xiaomi'),
('0500496351', 10005, 'Samsung'),
('0501234567', 10006, 'Nokia'),
('0507654321', 10006, 'Nokia'),
('0501111111', 10007, 'Samsung'),
('0520000001', 10008, 'Samsung'),
('0520000002', 10008, 'Samsung'),
('0530000001', 10009, 'Apple'),
('0530000002', 10009, 'Apple'),
('0530000003', 10009, 'Apple'),
('0540000001', 10010, 'Samsung'),
('0540000002', 10010, 'Xiaomi'),
('0540000003', 10010, 'Nokia'),
('0540000004', 10010, 'Samsung'),
('0514051948', 10011, 'Nokia'),
('0505061967', 10011, 'Nokia'),
('0504071776', 10013, 'Apple'),
('0580001111', 10014, 'Apple'),
('0580002222', 10014, 'Samsung'),
('0510607213', 10015, 'Samsung'),
('0520607213', 10015, 'Samsung'),
('0530607213', 10015, 'Samsung')

GO

INSERT INTO Packages (PackageName, Price, RequiredAuthorization, DurationInMonths, CallsAmount, SMSAmount,
					  InternetGBAmount, AbroadCallsAmount, AbroadSMSAmount, Includes5G) VALUES
('Basic', 35, 1, 24, 3000, 3000, 200, 0, 0, 0),
('Kosher', 25, 1, 12, 5000, 5000, 0, 0, 0, 0),
('Shimur', 30, 3, NULL, 2500, 2500, 150, 0, 0, 0),
('Normal 5G', 45, 1, NULL, 4000, 4000, 500, 100, 100, 1),
('5G Extra', 55, 1, NULL, 7000, 7000, 700, 200, 200, 1),
('Abroad Included', 40, 1, 24, 5000, 5000, 300, 100, 100, 0),
('Cheap Triple', 33, 2, 12, 4000, 4000, 300, 0, 0, 0),
('Triple Extra', 50, 2, 24, 10000, 10000, 500, 100, 100, 1),
('Employee Cheap', 20, 3, NULL, 4000, 4000, 500, 0, 0, 0),
('Employee 5G', 30, 3, NULL, 7000, 7000, 700, 100, 100, 1)

GO

INSERT INTO Purchases (PhoneNumber, PackageID, PurchaseTime, EmployeeID) VALUES
('0580585858', 190, '02-01-2020', 1000),
('0501234567', 100, '03-03-2020', 1000),
('0501234567', 110, '03-03-2022', 1010),
('0501234567', 110, '03-03-2023', 1010),
('0501234567', 110, '03-03-2024', 1010),
('0501234567', 110, '03-03-2025', 1020),
('0507654321', 100, '03-03-2020', 1000),
('0507654321', 110, '03-03-2022', 1010),
('0507654321', 110, '03-03-2023', 1010),
('0507654321', 110, '03-03-2024', 1010),
('0507654321', 110, '03-03-2025', 1020),
('0501111111', 100, '01-01-2021', 1000),
('0501111111', 100, '01-01-2023', 1000),
('0501111111', 100, '01-01-2025', 1040),
('0520000001', 100, '02-02-2021', 1000),
('0520000001', 130, '02-02-2023', 1010),
('0520000002', 100, '02-02-2021', 1000),
('0520000002', 130, '02-02-2023', 1010),
('0530000001', 170, '03-03-2021', 1000),
('0530000001', 170, '03-03-2022', 1010),
('0530000001', 170, '03-03-2025', 1040),
('0530000002', 170, '03-03-2021', 1000),
('0530000002', 170, '03-03-2022', 1010),
('0530000002', 170, '03-03-2025', 1040),
('0530000003', 170, '03-03-2021', 1000),
('0530000003', 170, '03-03-2022', 1010),
('0530000003', 170, '03-03-2025', 1040),
('0540000001', 140, '04-04-2021', 1000),
('0540000002', 160, '04-04-2023', 1000),
('0540000003', 160, '04-04-2023', 1000),
('0540000004', 160, '04-04-2023', 1000),
('0540000002', 160, '04-04-2024', 1000),
('0540000003', 160, '04-04-2024', 1000),
('0540000004', 160, '04-04-2024', 1000),
('0540000002', 160, '04-04-2025', 1000),
('0540000003', 160, '04-04-2025', 1000),
('0540000004', 160, '04-04-2025', 1000),
('0587777777', 190, '01-04-2022', 1000),
('0504071776', 150, '07-04-2024', 1010),
('0500496351', 100, '12-31-2022', 1000),
('0500496351', 100, '12-31-2024', 1000),
('0580001111', 150, '01-01-2023', 1010),
('0580001111', 150, '08-08-2024', 1010),
('0580002222', 150, '01-01-2023', 1010),
('0580002222', 150, '08-08-2024', 1010),
('0510607213', 160, '03-03-2023', 1010),
('0510607213', 160, '03-03-2024', 1010),
('0510607213', 160, '03-03-2025', 1020),
('0520607213', 160, '03-03-2023', 1010),
('0520607213', 160, '03-03-2024', 1010),
('0520607213', 160, '03-03-2025', 1020),
('0530607213', 160, '03-03-2023', 1010),
('0530607213', 160, '03-03-2024', 1010),
('0530607213', 160, '03-03-2025', 1020),
('0514051948', 100, '05-14-2023', 1000),
('0505061967', 100, '05-14-2023', 1000),
('0514051948', 120, '01-01-2024', 1010),
('0505061967', 120, '01-01-2024', 1010),
('0520000000', 100, '06-06-2023', 1000),
('0520000000', 180, '03-03-2024', 1000),
('0549999999', 130, '01-12-2024', 1010),
('0549999999', 180, '02-01-2025', 1010)


GO


--Showing that no packages were purchased without using the appropriate authorization:
SELECT prc.PurchaseID, prc.PurchaseTime, prc.PackageID, pkg.RequiredAuthorization,
emp.EmployeeID, emp.AuthorizationLevel FROM Employees emp
JOIN Purchases prc ON prc.EmployeeID = emp.EmployeeID
JOIN Packages pkg ON prc.PackageID = pkg.PackageID
WHERE emp.AuthorizationLevel < pkg.RequiredAuthorization

GO

--All managers compared to their employees:
SELECT mng.EmployeeName ManagerName, emp.EmployeeName,
mng.AuthorizationLevel - emp.AuthorizationLevel AS AuthorizationSeniority,
DATEDIFF(MM, mng.HireDate, emp.HireDate) AS SeniorityInMonths FROM Employees mng
JOIN Employees emp ON mng.EmployeeID = emp.ManagerID
ORDER BY mng.EmployeeID

GO

--All non-employee customers with 5G packages:
SELECT cus.FirstName + ' ' + cus.LastName AS FullName,
phn.PhoneNumber, phn.DeviceCompany, pkg.PackageName, pkg.Price
FROM Customers cus
JOIN Phones phn ON phn.CustomerID = cus.CustomerID
JOIN Purchases prc ON prc.PhoneNumber = phn.PhoneNumber
JOIN Packages pkg ON prc.PackageID = pkg.PackageID
WHERE cus.FirstName + ' ' + cus.LastName NOT IN
(SELECT EmployeeName from Employees)
AND pkg.Includes5G = 1
ORDER BY cus.LastName

GO

--Creating a helpful View:

CREATE VIEW LatestPackages AS
SELECT *, ROW_NUMBER() OVER(PARTITION BY Purchases.PhoneNumber
ORDER BY Purchases.PurchaseTime DESC) PurchaseOrder FROM Purchases

GO

--All customers' total up-to-date monthly invoice costs:
SELECT cus.CustomerID, cus.FirstName + ' ' + cus.LastName FullName,
SUM(pkg.Price) TotalMonthlyPayment FROM LatestPackages
JOIN Phones phn ON LatestPackages.PhoneNumber = phn.PhoneNumber
JOIN Customers cus ON phn.CustomerID = cus.CustomerID
JOIN Packages pkg ON LatestPackages.PackageID = pkg.PackageID
WHERE PurchaseOrder = 1
GROUP BY cus.CustomerID, cus.FirstName + ' ' + cus.LastName
ORDER BY TotalMonthlyPayment DESC

GO

--The number of phones owned by customers whose own phone is registered in Golan:
SELECT cus.CustomerID, cus.FirstName + ' ' + cus.LastName FullName,
COUNT(*) NumberOfPhones FROM Customers cus JOIN Phones phn ON phn.CustomerID = cus.CustomerID
WHERE cus.ContactNumber IN
(SELECT Phones.PhoneNumber FROM Phones WHERE Phones.CustomerID = cus.CustomerID)
GROUP BY cus.CustomerID, cus.FirstName + ' ' + cus.LastName
ORDER BY NumberOfPhones DESC

GO

--The next upcoming package expiries for each phone:
SELECT cus.CustomerID, cus.FirstName + ' ' + cus.LastName FullName, phn.PhoneNumber, pkg.PackageName, pkg.Price,
ISNULL(FORMAT(DATEADD(MM, pkg.DurationInMonths, LatestPackages.PurchaseTime), 'd', 'he-IL'), 'No expiry date') ExpiryDate
FROM Customers cus
JOIN Phones phn ON phn.CustomerID = cus.CustomerID
JOIN LatestPackages ON LatestPackages.PhoneNumber = phn.PhoneNumber
JOIN Packages pkg ON LatestPackages.PackageID = pkg.PackageID
WHERE PurchaseOrder = 1
ORDER BY ISNULL(DATEADD(MM, pkg.DurationInMonths, LatestPackages.PurchaseTime), GETDATE() + 99999)

GO

--All phones with below average, non-shimur packages:
WITH RelevantCustomers AS
(
SELECT cus.CustomerID, LatestPackages.PurchaseID, pkg.PackageID, pkg.Price
FROM Customers cus JOIN Phones phn ON phn.CustomerID = cus.CustomerID
JOIN LatestPackages ON LatestPackages.PhoneNumber = phn.PhoneNumber
JOIN Packages pkg ON LatestPackages.PackageID = pkg.PackageID
WHERE PurchaseOrder = 1
AND NOT EXISTS(SELECT * FROM Packages WHERE Packages.PackageName = 'Shimur' AND Packages.PackageID = pkg.PackageID)
GROUP BY cus.CustomerID, LatestPackages.PurchaseID, pkg.PackageID, pkg.Price
HAVING SUM(pkg.Price) < (SELECT AVG(Packages.Price) FROM Packages)
)
SELECT LatestPackages.PhoneNumber, RelevantCustomers.*,
SUM(RelevantCustomers.Price) OVER(PARTITION BY RelevantCustomers.CustomerID) TotalForCustomer
FROM RelevantCustomers JOIN LatestPackages ON LatestPackages.PurchaseID = RelevantCustomers.PurchaseID
ORDER BY TotalForCustomer DESC, RelevantCustomers.CustomerID

GO
