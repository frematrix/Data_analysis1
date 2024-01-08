-- 3.1 Retrieve the total sales amount for each product category for a specific time period

SELECT * FROM sh.total_sales_category (2001);

CREATE OR REPLACE FUNCTION sh.total_sales_category (IN cal_year int)
RETURNS TABLE (product_category varchar(20), calender_year int, total_sales_amount decimal(12,2))
AS
$$
	SELECT	p.prod_category AS product_category,
			t.calendar_year,
			SUM(s.amount_sold) AS total_sales_amount
	FROM sh.sales s
	INNER JOIN sh.products p ON s.prod_id = p.prod_id
	INNER JOIN sh.times t ON s.time_id = t.time_id
	WHERE t.calendar_year = cal_year
	GROUP BY p.prod_category, t.calendar_year
	ORDER BY p.prod_category, t.calendar_year
$$
LANGUAGE sql;

--corr:
SELECT	p.prod_category AS product_category,
		t.calendar_year,
		SUM(s.amount_sold) AS total_sales_amount
FROM sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.times t ON s.time_id = t.time_id
WHERE t.calendar_year = 2001
GROUP BY p.prod_category, t.calendar_year
ORDER BY p.prod_category;

--3.2 Calculate the average sales quantity by region for a particular product

SELECT * FROM sh.average_sales_by_product (123);

CREATE OR REPLACE FUNCTION sh.average_sales_by_product (IN product_id int4)
RETURNS TABLE (region varchar(20), avg_sales_qty decimal(9,2))
AS
$$
	SELECT
	    c.country_region AS region,
	    AVG(s.quantity_sold) AS avg_sales_qty
	FROM sh.sales s
	INNER JOIN sh.products p ON s.prod_id = p.prod_id
	INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id
	INNER JOIN sh.customers cust ON s.cust_id = cust.cust_id
	INNER JOIN sh.countries c ON cust.country_id = c.country_id
	WHERE p.prod_id = product_id
	GROUP BY c.country_region
	ORDER BY c.country_region
$$
LANGUAGE sql;

--corr:
SELECT 	c.country_region AS region,
	    AVG(s.quantity_sold) AS avg_sales_qty
FROM sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id
INNER JOIN sh.customers cust ON s.cust_id = cust.cust_id
INNER JOIN sh.countries c ON cust.country_id = c.country_id
WHERE p.prod_id = 123
GROUP BY c.country_region
ORDER BY c.country_region;

-- 3.3 Find the top five customers with the highest total sales amount

SELECT * FROM sh.top_five_customers;

CREATE OR REPLACE VIEW sh.top_five_customers AS
SELECT 	c.cust_id,
    	c.cust_first_name || ' ' || c.cust_last_name AS customer_name,
    	SUM(s.amount_sold) AS total_sales_amount
FROM sh.sales s
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
GROUP BY c.cust_id, customer_name
ORDER BY total_sales_amount DESC
FETCH FIRST 5 ROWS WITH TIES;

--corr:
SELECT 	c.cust_id,
    	c.cust_first_name || ' ' || c.cust_last_name AS customer_name,
    	SUM(s.amount_sold) AS total_sales_amount
FROM sh.sales s
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
GROUP BY c.cust_id, customer_name
ORDER BY total_sales_amount DESC
FETCH FIRST 5 ROWS WITH TIES;
