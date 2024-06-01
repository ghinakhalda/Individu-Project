show databases;
use gdb023;
show tables;

-- Test
SELECT market FROM dim_customer;
SELECT region FROM dim_customer;
SELECT customer FROM dim_customer;

-- Number 1
SELECT DISTINCT market FROM dim_customer WHERE region = 'APAC' AND customer = 'Atliq Exclusive';

-- Number 2
SELECT fiscal_year FROM fact_gross_price;

SELECT 
  COUNT(DISTINCT CASE WHEN a.fiscal_year = 2020 THEN a.product_code END) AS 'unique_products_2020',
  COUNT(DISTINCT CASE WHEN a.fiscal_year = 2021 THEN a.product_code END) AS 'unique_products_2021',
  ROUND((COUNT(DISTINCT CASE WHEN a.fiscal_year = 2021 THEN a.product_code END) -
     COUNT(DISTINCT CASE WHEN a.fiscal_year = 2020 THEN a.product_code END)) 
     * 100 / (COUNT(DISTINCT CASE WHEN a.fiscal_year = 2020 THEN a.product_code END)), 2) AS 'percentage_chg'
FROM 
  fact_gross_price a;
  
-- Number 3
SELECT segment, COUNT(product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY COUNT(product_code) DESC;

-- Number 4
SELECT 
	b.segment, COUNT(DISTINCT CASE WHEN a.fiscal_year = 2020 THEN a.product_code END) AS product_count_2020,
    COUNT(DISTINCT CASE WHEN a.fiscal_year = 2021 THEN a.product_code END) AS product_count_2021,
    ABS(COUNT(DISTINCT CASE WHEN a.fiscal_year = 2020 THEN a.product_code END) -
	COUNT(DISTINCT CASE WHEN a.fiscal_year = 2021 THEN a.product_code END)) AS difference
FROM dim_product b JOIN fact_gross_price a ON a.product_code = b.product_code
GROUP BY segment
ORDER BY difference DESC;

-- Number 5
SELECT a.product_code, b.product, a.manufacturing_cost 
FROM fact_manufacturing_cost a JOIN dim_product b ON a.product_code = b.product_code
WHERE
   a.manufacturing_cost IN (
    (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost),
    (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
  );

-- Number 6
SELECT a.customer_code, b.customer, AVG(pre_invoice_discount_pct) AS average_discount_percentage
FROM fact_pre_invoice_deductions a JOIN dim_customer b ON a.customer_code = b.customer_code
WHERE a.fiscal_year = 2021 AND market = 'India'
GROUP BY a.customer_code, b.customer
ORDER BY AVG(pre_invoice_discount_pct) DESC
LIMIT 5;

-- Number 7: Gross sales = unit sold * sales price
SELECT 
	MONTH(a.date) as month, 
    a.fiscal_year as year,
    SUM(b.gross_price*a.sold_quantity) as Gross_sales_Amount
FROM fact_sales_monthly a 
	JOIN fact_gross_price b ON a.product_code = b.product_code
    JOIN dim_customer c ON c.customer_code = a.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY MONTH(a.date), a.fiscal_year
ORDER BY a.fiscal_year ASC, MONTH(a.date) ASC;

-- Number 8
SELECT 
	CEILING(MONTH(date)/4) as Quarter, 
    SUM(sold_quantity) as total_sold_quantity
FROM fact_Sales_monthly
WHERE fiscal_year = 2020
GROUP BY CEILING(MONTH(date)/4)
ORDER BY SUM(sold_quantity) DESC
LIMIT 1;

-- Number 9
SELECT
  a.channel,
  SUM(b.gross_price * c.sold_quantity) AS gross_sales_mln,
  ROUND(SUM(b.gross_price * c.sold_quantity) * 100 / (
    SELECT SUM(b1.gross_price * c1.sold_quantity)
    FROM fact_gross_price b1
    JOIN fact_sales_monthly c1 ON c1.product_code = b1.product_code
    WHERE c1.fiscal_year = 2021
  ), 2) AS percentage
FROM fact_sales_monthly c
JOIN fact_gross_price b ON c.product_code = b.product_code
JOIN dim_customer a ON c.customer_code = a.customer_code
WHERE c.fiscal_year = 2021
GROUP BY a.channel
ORDER BY gross_sales_mln DESC;

-- Number 10
SELECT 
	a.division, a.product_code, a.product, 
    SUM(b.sold_quantity) as total_sold_quantity, 
    RANK() OVER (ORDER BY SUM(b.sold_quantity) DESC) AS rank_order
FROM 
	dim_product a JOIN fact_sales_monthly b ON a.product_code = b.product_code
WHERE b.fiscal_year = 2021
GROUP BY a.division, a.product_code
HAVING RANK() OVER (ORDER BY SUM(b.sold_quantity) DESC) <= 3
ORDER BY  a.division DESC, a.product_code DESC, rank_order ASC;