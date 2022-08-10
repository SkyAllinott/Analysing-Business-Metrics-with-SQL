USE classicmodels;

# Return all employees and their office info
SELECT e.employeeNumber, e.lastName, e.firstName, e.email, e.reportsTo, o.city, o.addressLine1, o.addressLine2 FROM employees e 
	JOIN offices o ON o.officeCode = e.officeCode
    ORDER BY e.employeeNumber;

# What coutries are our employees and customers in?
SELECT city FROM offices
	UNION
		SELECT city from customers;
    
# How many people report to employeeNumber 1143?
SELECT COUNT(DISTINCT lastName) as underlingsof1143 FROM employees
	WHERE reportsTo = 1143;
    
# Who are the biggest customers? How much do they pay, where are they located, and which sales representative do they use?
SELECT c.customerNumber, c.customerName, c.phone, c.country, c.salesRepEmployeeNumber, SUM(p.amount) as TotalPayments FROM customers c
	JOIN payments p ON c.customerNumber = p.customerNumber
    GROUP BY customerNumber
    ORDER BY SUM(p.amount) DESC;
    
# Which sales rep brings in the most money? What's their name and what office are they in?
SELECT c.salesRepEmployeeNumber, e.lastName, e.firstName, o.city, o.country, SUM(p.amount) as totalSales FROM customers c
	JOIN payments p on c.customerNumber = p.customerNumber
    JOIN employees e on c.salesRepEmployeeNumber = e.employeeNumber
    JOIN offices o on e.officeCode = o.officeCode
    GROUP BY c.salesRepEmployeeNumber
    ORDER BY SUM(p.amount) DESC;

# Which sales reps earn more than _____? Utilises subqueries and stored procedures
DELIMITER //
CREATE PROCEDURE BetterThanX (IN RepNumber VARCHAR(4))
BEGIN
SELECT c.salesRepEmployeeNumber, e.lastName, e.firstName, o.city, o.country, SUM(p.amount) as totalSales FROM customers c
	JOIN payments p on c.customerNumber = p.customerNumber
    JOIN employees e on c.salesRepEmployeeNumber = e.employeeNumber
    JOIN offices o on e.officeCode = o.officeCode
    GROUP BY salesRepEmployeeNumber
	HAVING SUM(p.amount) >=
		(SELECT SUM(p.amount) FROM customers c
			JOIN payments p on c.customerNumber = p.customerNumber
            JOIN employees e on c.salesRepEmployeeNumber = e.employeeNumber
			JOIN offices o on e.officeCode = o.officeCode
            WHERE salesRepEmployeeNumber= RepNumber);
END //

# Call the stored procedure from above
CALL BetterThanX('1702');

	
		
    
# Best seller in the London Office?
SELECT c.salesRepEmployeeNumber, e.lastName, e.firstName, o.city, o.country, SUM(p.amount) as totalSales FROM customers c
	JOIN payments p on c.customerNumber = p.customerNumber
    JOIN employees e on c.salesRepEmployeeNumber = e.employeeNumber
    JOIN offices o on e.officeCode = o.officeCode
    WHERE o.city= "London"
    GROUP BY c.salesRepEmployeeNumber
    ORDER BY SUM(p.amount) DESC;
    
# What are our three most profitable products?
SELECT o.productCode, p.productName, p.productDescription, p.buyPrice, p.MSRP, SUM(o.quantityOrdered) as QuantitySold, p.MSRP-p.buyPrice as ProfitMargin, (p.MSRP-p.buyPrice) * SUM(o.quantityOrdered) as Profit FROM orderdetails o
	JOIN products p on o.productCode = p.productCode
    GROUP BY productCode
    ORDER BY Profit DESC
    LIMIT 3;
    
# What are our 5 most profitable countries?
SELECT c.country, (p.MSRP-p.buyPrice)*SUM(d.quantityOrdered) as Profit FROM customers c
	JOIN orders o on o.customerNumber = c.customerNumber
    JOIN orderdetails d on d.orderNumber = o.orderNumber
    JOIN products p on p.productCode = d.productCode
    GROUP BY country
    ORDER BY Profit DESC
    LIMIT 5;
    
# What's our 5 most profitable country, adjusting for customers?
SELECT c.country, COUNT(DISTINCT c.customerNumber) as customers, 
	(p.MSRP-p.buyPrice)*SUM(d.quantityOrdered) as Profit, 
	ROUND(((p.MSRP-p.buyPrice)*SUM(d.quantityOrdered)/COUNT(DISTINCT c.customerNumber)), 2) as AvgProfitPerCompany FROM customers c
		JOIN orders o on o.customerNumber = c.customerNumber
		JOIN orderdetails d on d.orderNumber = o.orderNumber
		JOIN products p on p.productCode = d.productCode
			GROUP BY country
			ORDER BY AvgProfitPerCompany DESC
			LIMIT 5;

# What are our most profitable product lines?
SELECT RANK() OVER (ORDER BY (p.MSRP-p.buyPrice)*SUM(d.quantityOrdered) DESC) AS profitRank, 
	l.productLine, 
    (p.MSRP-p.buyPrice)*SUM(d.quantityOrdered) as Profit FROM customers c
		JOIN orders o on o.customerNumber = c.customerNumber
		JOIN orderdetails d on d.orderNumber = o.orderNumber
		JOIN products p on p.productCode = d.productCode
		JOIN productlines l on l.productLine = p.productLine
		GROUP BY productLine;

# What are our top 3 items in stock? Who should we sell them to?
SELECT p.productCode, p.quantityInStock, c.customerName as BestProspectiveCustomer, 
	SUM(d.quantityOrdered) as QuantitySoldPreviously FROM products p
		JOIN orderdetails d on d.productCode = p.productCode
		JOIN orders o on d.orderNumber = o.orderNumber
		JOIN customers c on c.customerNumber = o.customerNumber
		GROUP BY productCode
		ORDER BY quantityInStock DESC
		LIMIT 3;
    
# Are we losing money on any products? 
SELECT o.productCode, p.productName, p.productDescription, p.buyPrice, p.MSRP, SUM(o.quantityOrdered) as QuantitySold, p.MSRP-p.buyPrice as ProfitMargin, (p.MSRP-p.buyPrice) * SUM(o.quantityOrdered) as Profit FROM orderdetails o
	JOIN products p on o.productCode = p.productCode
    HAVING Profit < 0;
    
# Which company has most orders? What's their contact info?
SELECT c.customerName, c.country, c.phone, COUNT(DISTINCT o.orderNumber) as totalOrders FROM customers c
	LEFT JOIN orders o on o.customerNumber = c.customerNumber
    GROUP BY customerName
    ORDER BY totalOrders DESC;
    
# Running bill for biggest customer, customerNumber=141, along with days between orders, and rankings
SELECT p.paymentDate as date, c.customerName, p.amount as amountPaid, 
	RANK() OVER (ORDER BY p.amount DESC) as amountPaidRank,
	SUM(p.amount) OVER (PARTITION BY c.customerName ORDER BY p.paymentDate) as runningTotal, 
    datediff(p.paymentDate, lag(p.paymentDate) over (partition by c.customername order by p.paymentDate)) as daysBetweenOrders
    FROM payments p
		LEFT JOIN customers c on p.customerNumber = c.customerNumber
		WHERE c.customerNumber=141
		GROUP BY date
		ORDER BY paymentDate;

# Most ordered product lines by country, with subtotals
SELECT c.country, p.productLine, SUM(d.quantityOrdered) as quantityOrdered FROM orderdetails d
	LEFT JOIN orders o on o.orderNumber = d.orderNumber
    LEFT JOIN customers c on c.customerNumber = o.customerNumber
    LEFT JOIN products p on p.productCode=d.productCode
    GROUP BY c.country, p.productLine WITH ROLLUP;
    
# Cases for days between order and payment, with labelled bins.
SELECT c.customerName, o.orderDate, p.paymentDate,
	CASE WHEN DATEDIFF(p.paymentDate, o.orderDate) <= 30 THEN '0-30 days'
    WHEN DATEDIFF(p.paymentDate, o.orderDate) > 30 AND DATEDIFF(p.paymentDate, o.orderDate) <= 60 THEN '30-60 days'
    WHEN DATEDIFF(p.paymentDate, o.orderDate) > 60 AND DATEDIFF(p.paymentDate, o.orderDate) <= 120 THEN '60-120 days'
    ELSE '>120 days' END AS paymentTimeBin
	FROM orders o
		LEFT JOIN customers c on c.customerNumber = o.customerNumber
		LEFT JOIN payments p on p.customerNumber = c.customerNumber;
        
# Average days between order and payment, by company
SELECT RANK() OVER (ORDER BY AVG(CASE WHEN DATEDIFF(p.paymentDate, o.orderDate) < 0 THEN 0 ELSE DATEDIFF(p.paymentDate, o.orderDate) END)) as speedRanking,
	c.customerName,
    ROUND(AVG(CASE WHEN DATEDIFF(p.paymentDate, o.orderDate) < 0 THEN 0 ELSE DATEDIFF(p.paymentDate, o.orderDate) END), 0) as averageDaysBetween 
    FROM orders o
		LEFT JOIN customers c on c.customerNumber = o.customerNumber
		LEFT JOIN payments p on p.customerNumber = c.customerNumber
        GROUP BY customerName
        ORDER BY averageDaysBetween;
        
# Which countries are fastest?
SELECT RANK() OVER (ORDER BY AVG(CASE WHEN DATEDIFF(p.paymentDate, o.orderDate) < 0 THEN 0 ELSE DATEDIFF(p.paymentDate, o.orderDate) END)) as speedRanking,
	c.country,
    ROUND(AVG(CASE WHEN DATEDIFF(p.paymentDate, o.orderDate) < 0 THEN 0 ELSE DATEDIFF(p.paymentDate, o.orderDate) END), 0) as averageDaysBetween 
    FROM orders o
		LEFT JOIN customers c on c.customerNumber = o.customerNumber
		LEFT JOIN payments p on p.customerNumber = c.customerNumber
        GROUP BY country
        ORDER BY averageDaysBetween;





    
