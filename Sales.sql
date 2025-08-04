CREATE DATABASE SalesDB;
GO
USE SalesDB;

ALTER TABLE Cities
ALTER COLUMN ZipCode DECIMAL(5, 0);

ALTER TABLE Cities
ADD CONSTRAINT FK_Cities_Countries
FOREIGN KEY (CountryID) REFERENCES Countries(CountryID);

ALTER TABLE Countries
ALTER COLUMN CountryCode VARCHAR(2);

ALTER TABLE Customers
ALTER COLUMN Address VARCHAR(90);

ALTER TABLE Customers
ADD CONSTRAINT FK_Customers_Cities
FOREIGN KEY (CityID) REFERENCES Cities(CityID);

ALTER TABLE Employees
ALTER COLUMN Gender VARCHAR(10);

ALTER TABLE Employees
ADD CONSTRAINT FK_Employees_Cities
FOREIGN KEY (CityID) REFERENCES Cities(CityID);

ALTER TABLE Products
ALTER COLUMN Price DECIMAL(4, 0);

ALTER TABLE Products
ALTER COLUMN Class VARCHAR(15);

ALTER TABLE Products
ALTER COLUMN Resistant VARCHAR(15);

ALTER TABLE Products
ALTER COLUMN VitalityDays DECIMAL(3, 0);

ALTER TABLE Products
ADD CONSTRAINT FK_Products_Categories
FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID);


ALTER TABLE Sales
ALTER COLUMN SalesID INT NOT NULL;

ALTER TABLE Sales
ADD CONSTRAINT PK_Sales_SalesID PRIMARY KEY (SalesID);

ALTER TABLE Sales
ALTER COLUMN SalesPersonID INT;
ALTER TABLE Sales
ALTER COLUMN CustomerID INT;
ALTER TABLE Sales
ALTER COLUMN ProductID INT;

ALTER TABLE Sales
ALTER COLUMN Quantity INT;

ALTER TABLE Sales
ALTER COLUMN Discount DECIMAL(10, 2);

ALTER TABLE Sales
ALTER COLUMN TotalPrice DECIMAL(10, 2);

ALTER TABLE Sales
ALTER COLUMN TransactionNumber VARCHAR(25);
ALTER TABLE Sales
ALTER COLUMN SalesDate DATETIME;


ALTER TABLE Sales
ADD CONSTRAINT FK_Sales_SalesPerson
FOREIGN KEY (SalesPersonID) REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_Sales_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    CONSTRAINT FK_Sales_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID);

--All TotalPrice column values has zero so we drop the column 
 Alter Table Sales
 Drop column TotalPrice;

 ALTER TABLE Sales
 ADD Revenue DECIMAL(12,2);

 UPDATE s
 SET Revenue = s.Quantity * p.Price
 FROM Sales s
 JOIN Products p ON s.ProductID = p.ProductID;

--creating indexes to faster the execution
CREATE NONCLUSTERED INDEX idx_sales_productid ON sales(ProductID);
CREATE NONCLUSTERED INDEX idx_sales_customerid ON sales(CustomerID);
CREATE NONCLUSTERED INDEX idx_sales_salespersonid ON sales(SalesPersonID);
CREATE NONCLUSTERED INDEX idx_sales_salesdate ON sales(SalesDate);

CREATE NONCLUSTERED INDEX idx_products_productid ON products(ProductID);
CREATE NONCLUSTERED INDEX idx_products_categoryid ON products(CategoryID);
CREATE NONCLUSTERED INDEX idx_products_class ON products(Class);

CREATE NONCLUSTERED INDEX idx_customers_customerid ON customers(CustomerID);  
CREATE NONCLUSTERED INDEX idx_customers_cityid ON customers(CityID);

CREATE NONCLUSTERED INDEX idx_employees_employeeid ON employees(EmployeeID);  
CREATE NONCLUSTERED INDEX idx_employees_cityid ON employees(CityID);

CREATE NONCLUSTERED INDEX idx_categories_categoryid ON categories(CategoryID);

CREATE NONCLUSTERED INDEX idx_cities_cityid ON cities(CityID);
CREATE NONCLUSTERED INDEX idx_cities_countryid ON cities(CountryID);

CREATE NONCLUSTERED INDEX idx_countries_countryid ON countries(CountryID);

--Queries

--Total number of customers
select count(*) As NumberofCustomers from customers

--Total number of Products
select count(*) As NumberofProducts from products

--Total Sales of Products
Select Sum(Revenue) as TotalSales from sales 

--Which city has the most customers?
select Top 1 CityName ,count(CustomerID) as NumberofCustomers from cities ci
join customers cu
on ci.CityID = cu.CityID
group by CityName 
order by NumberofCustomers DESC
 
 --Top 3 cities in terms of TotalSales
 select ci.CityName ,sum(revenue) as TotalSales from sales s
 join customers c on s.CustomerID=c.CustomerID 
 join cities ci on c.CityID =ci.CityID
 group by ci.CityName
 order by TotalSales Desc

--Top 10 Most Purchased Products
select Top 10 p.ProductName ,count(s.ProductID) as NumberofPurchases from products p
join sales s
on p.ProductID=s.ProductID
group by ProductName
order by NumberofPurchases Desc

--Number of unique products sold from each category
select c.CategoryName,count(ProductID) as Uniqueproducts from products p 
join categories c
on p.CategoryID=c.CategoryID
group by c.CategoryName
order by Uniqueproducts DESC

--How many unique customers has each salesperson dealt with?
 select s.SalesPersonID ,count(Distinct(c.CustomerID)) AS numberofcustomers from sales s 
 join customers c on s.CustomerID =c.CustomerID
 group by SalesPersonID

 --Which gender sold 'CornFlakes' more often and earned more revenue?
 select e.Gender,count(e.Gender) as beerbluepurchases,
 Sum(s.Revenue) as beerbluesales from employees e
  join sales s on e.EmployeeID=s.SalesPersonID
  join products p on s.ProductID=p.ProductID
  where p.ProductName= 'CornFlakes'
  group by Gender
  order by beerbluepurchases desc;

 --Product Classification by Shelf Life (Vitality Days)
SELECT 
  ProductName,
  VitalityDays,
  CASE
    WHEN VitalityDays = 0 THEN 'Non-perishable / Unknown'
    WHEN VitalityDays BETWEEN 1 AND 7 THEN 'Short-life'
    WHEN VitalityDays BETWEEN 8 AND 30 THEN 'Medium-life'
    WHEN VitalityDays BETWEEN 31 AND 90 THEN 'Long-life'
    ELSE 'Extended-life'
  END AS ShelfLifeCategory
FROM products
ORDER BY VitalityDays;

--Customers who did more that 200 purchases
select CONCAT(c.FirstName,' ',c.LastName) as CustomerName,
count(s.CustomerID) as NumberofPurchases from customers c
join sales s on c.CustomerID = s.CustomerID
group by CONCAT(c.FirstName,' ',c.LastName)
having count(s.CustomerID) > 200
order by NumberofPurchases Desc

--Total revenue for each product category
select c.CategoryName,sum(s.Revenue) as TotalRevenue from categories c
join products p on c.CategoryID = p.CategoryID
join sales s on p.ProductID =s.ProductID
group by CategoryName

--Total Quantity per Product Class
select p.Class, sum(s.Quantity) as TotalQuantity from sales s
join products p on s.ProductID =p.ProductID
group by Class
order by TotalQuantity

--How many products belong to each resistant category
select Resistant,count(ProductID) AS numbofproducts from products 
group by Resistant

--Which products that have never been sold
select ProductID, ProductName from products P
where P.ProductID NOT IN (
select Distinct(s.ProductID) from sales s join products p on 
s.ProductID =p.ProductID);

--Average Vitality per Category
SELECT 
  c.CategoryName, 
   CAST(ROUND(AVG(p.VitalityDays),0) AS INT) AS AvgVitality
FROM products p
JOIN categories c ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
ORDER BY AvgVitality;

--High-Priced Allergenic Products
select TOP 10 ProductName ,Price from products 
where IsAllergic ='True'
order by Price DESC

--Average Age of employees at Hiring
SELECT 
  AVG(
    DATEDIFF(YEAR, BirthDate, HireDate) 
    - CASE 
        WHEN DATEADD(YEAR, DATEDIFF(YEAR, BirthDate, HireDate), BirthDate) > HireDate 
        THEN 1 ELSE 0 
      END
  ) AS AvgAgeAtHire
FROM employees;

--How many employees were hired each year 
SELECT 
  YEAR(HireDate) AS HireYear, 
  COUNT(*) AS NumberOfHires
FROM employees
GROUP BY YEAR(HireDate)
ORDER BY HireYear;

--Employees Who Sold to Customers in Their Own City
select CONCAT(e.FirstName,' ',e.LastName) as EmployeeName,c.CustomerID ,ci.CityID from sales s
join employees e on e.EmployeeID=s.SalesPersonID
join customers c on s.CustomerID=c.CustomerID
join cities ci on e.CityID=ci.CityID
where e.CityID=c.CityID
order by EmployeeID

--Same-City Sales by Employee Bernard Moody
SELECT DISTINCT 
  e.EmployeeID,
  CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
  ce.CityName AS EmployeeCity,
  c.CustomerID,
  CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
  cc.CityName AS CustomerCity
FROM sales s
JOIN employees e ON s.SalesPersonID = e.EmployeeID
JOIN customers c ON s.CustomerID = c.CustomerID
JOIN cities ce ON e.CityID = ce.CityID
JOIN cities cc ON c.CityID = cc.CityID
WHERE e.CityID = c.CityID
  AND e.FirstName = 'Bernard'
  AND e.LastName = 'Moody'
ORDER BY c.CustomerID;


--Optimized Sales Transaction Query for Power BI Import 
SELECT 
  s.SalesID,
  s.SalesPersonID,
  CONCAT(e.FirstName, ' ', e.LastName) AS SalesPersonName,
  s.CustomerID,
  s.ProductID,
  s.Quantity,
  s.Revenue,
  CAST(s.SalesDate AS DATE) AS SaleDate
FROM sales s
JOIN employees e ON s.SalesPersonID = e.EmployeeID
JOIN products p ON s.ProductID = p.ProductID
WHERE s.SalesDate >= '2018-03-01'
  AND s.SalesDate < '2018-06-01'
  AND p.VitalityDays > 0 

