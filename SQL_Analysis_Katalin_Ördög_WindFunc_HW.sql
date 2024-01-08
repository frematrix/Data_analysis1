/*SELECT count(*)
FROM sh.sh.costs c

-- In the list of the least-expensive (cheapest) products within its product category, which product obtained the third 
-- position among all product categories in 2001?

SELECT 	prod_name, 
		prod_category,
		prod_list_price
FROM 
(SELECT 	p.prod_name,
		p.prod_category,
		p.prod_list_price, 
		RANK () OVER (PARTITION BY p.prod_category ORDER BY p.prod_list_price) AS rankcheap
FROM sh.products p) rc
WHERE rankcheap = 1
ORDER BY prod_list_price;
*/

-----------------------------------------------------------------------------------------------------------
-- 
/* Task 1
 
Create a query to produce a sales report highlighting the top customers with the highest sales across different sales 
channels. This report should list the top 5 customers for each channel. Additionally, calculate a key performance indi-
cator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales 
within their respective channel.
Please format the columns as follows:
Display the total sales amount with two decimal places
Display the sales percentage with four decimal places and include the percent sign (%) at the end
Display the result for each channel in descending order of sales
*/

WITH customer_sales AS 
(SELECT 	cust_id,
			channel_id,
			sum(amount_sold) AS cust_total_sales
			FROM sh.sales
			GROUP BY cust_id, channel_id),
customer_ranks AS 
	(SELECT cust_id,
			channel_id,
			cust_total_sales,  
			ROW_NUMBER() OVER (PARTITION BY channel_id ORDER BY cust_total_sales DESC) AS channel_rank,
			sum(cust_total_sales) OVER (PARTITION BY channel_id) AS channel_sales
	FROM 	customer_sales
	)
SELECT 	cr.channel_id AS channel,
		cr.cust_id AS customer,
		to_char(cr.cust_total_sales, '9,999,999,999.99') AS customer_total_sales,
		concat(round((cr.cust_total_sales /cr.channel_sales) * 100, 4),'%') AS sales_percentage
FROM 	customer_ranks cr 
WHERE 	cr.channel_rank <= 5
ORDER BY cr.channel_id, customer_total_sales DESC;

-- id replaced by name
WITH customer_sales AS 
(SELECT 	cust_id,
			channel_desc,
			sum(amount_sold) AS cust_total_sales
			FROM sh.sales s
			INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id 
			GROUP BY cust_id, channel_desc),
customer_ranks AS 
	(SELECT cust_id,
			channel_desc,
			cust_total_sales,  
			ROW_NUMBER() OVER (PARTITION BY channel_desc ORDER BY cust_total_sales DESC) AS channel_rank,
			sum(cust_total_sales) OVER (PARTITION BY channel_desc) AS channel_sales
	FROM 	customer_sales
	)
SELECT 	cr.channel_desc AS channel,
		--cr.cust_id AS customer_id,
		c.cust_first_name || ' ' || c.cust_last_name AS customer_name,
		to_char(cr.cust_total_sales, '9,999,999,999.99') AS customer_total_sales,
		concat(round((cr.cust_total_sales /cr.channel_sales) * 100, 4),'%') AS sales_percentage
FROM 	customer_ranks cr 
INNER JOIN sh.customers c ON cr.cust_id = c.cust_id 
WHERE 	cr.channel_rank <= 5
ORDER BY cr.channel_desc, customer_total_sales DESC;

/* Task 2

Create a query to retrieve data for a report that displays the total sales for all products in the Photo category in the 
Asian region for the year 2000. Calculate the overall report total and name it 'YEAR_SUM'
Display the sales amount with two decimal places
Display the result in descending order of 'YEAR_SUM'
For this report, consider exploring the use of the crosstab function. Additional details and guidance can be found at this 
link
 */

WITH photo_prod_sales AS 
	(SELECT s.prod_id,
			sum(s.amount_sold) AS prod_total_sales,
			p.prod_category 
	FROM sh.sales s
	INNER JOIN sh.products p ON s.prod_id = p.prod_id 
	INNER JOIN sh.customers c ON c.cust_id = s.cust_id 
	INNER JOIN sh.countries co ON c.country_id = co.country_id 
	INNER JOIN sh.times t ON t.time_id = s.time_id 
	WHERE p.prod_category = 'Photo'
	AND co.country_region = 'Asia'
	AND t.calendar_year = 2000
	GROUP BY s.prod_id, prod_category 
	)
SELECT 	prod_id,
		to_char(prod_total_sales, '9,999,999,999.99') AS year_sum,
		sum(prod_total_sales) OVER (PARTITION BY prod_category)AS total_year_sum
FROM 	photo_prod_sales
GROUP BY prod_id, prod_total_sales, prod_category
ORDER BY year_sum DESC;

--corrected with two versions:
SELECT 	p.prod_name AS product,
		t.calendar_quarter_desc AS quarter,
		round(sum(s.amount_sold), 2) AS sum_quarter,
		sum(sum(s.amount_sold)) OVER (PARTITION BY p.prod_name) AS YEAR_SUM
FROM sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id 
INNER JOIN sh.customers c ON c.cust_id = s.cust_id 
INNER JOIN sh.countries co ON c.country_id = co.country_id 
INNER JOIN sh.times t ON t.time_id = s.time_id 
WHERE p.prod_category = 'Photo'
AND co.country_region = 'Asia'
AND t.calendar_quarter_desc IN ('2000-01', '2000-02', '2000-03', '2000-04')
GROUP BY p.prod_name, t.calendar_quarter_desc
ORDER BY YEAR_SUM DESC, t.calendar_quarter_desc;

SELECT 	prod_name, 
		COALESCE(to_char(q1, '999999D99'), ' ') AS q1, 
		COALESCE(to_char(q2, '999999D99'), ' ') AS q2, 
		COALESCE(to_char(q3, '999999D99'), ' ') AS q3, 
		COALESCE(to_char(q4, '999999D99'), ' ') AS q4, 
		to_char(COALESCE(q1,0)+COALESCE(q2,0)+COALESCE(q3,0)+COALESCE(q4,0), '9999999999D99') AS year_sum
FROM crosstab
($$SELECT
		p.prod_name,
		t.calendar_quarter_desc,
		(sum(s.amount_sold))
FROM sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id 
INNER JOIN sh.customers c ON c.cust_id = s.cust_id 
INNER JOIN sh.countries co ON c.country_id = co.country_id 
INNER JOIN sh.times t ON t.time_id = s.time_id 
WHERE p.prod_category = 'Photo'
AND co.country_region = 'Asia'
AND t.calendar_quarter_desc IN ('2000-01', '2000-02', '2000-03', '2000-04')
GROUP BY p.prod_name, t.calendar_quarter_desc
ORDER BY p.prod_name ASC, t.calendar_quarter_desc ASC$$)
AS ct (prod_name varchar(50), q1 numeric(10,2), q2 numeric(10,2), q3 numeric(10,2), q4 numeric(10,2))
ORDER BY year_sum desc;
		
/* Task 3
 
Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 1998, 
1999, and 2001. The report should be categorized based on sales channels, and separate calculations should be performed 
for each channel.
Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
Categorize the customers based on their sales channels
Perform separate calculations for each sales channel
Include in the report only purchases made on the channel specified
Format the column so that total sales are displayed with two decimal places
 */


SELECT channel_desc, customer, customer_name, to_char(SUM(cust_sum_sales), '9,999,999,999.99') AS total_sales
FROM
	(SELECT EXTRACT(YEAR FROM time_id) AS yea,
			channel_desc,
			cu.cust_id AS customer,
			cust_first_name || ' ' || cust_last_name AS customer_name,
			SUM(amount_sold) AS cust_sum_sales,
			RANK () OVER (PARTITION BY EXTRACT(YEAR FROM time_id), channel_desc ORDER BY SUM(amount_sold) DESC) AS ranking
	FROM 	sh.sales s
	INNER JOIN sh.channels c ON s.channel_id = c.channel_id 
	INNER JOIN sh.customers cu ON s.cust_id = cu.cust_id 
	WHERE EXTRACT(YEAR FROM time_id) IN ('1998', '1999', '2001')
	GROUP BY EXTRACT(YEAR FROM time_id), channel_desc, cu.cust_id
	) AS temptable
WHERE ranking<= 300
GROUP BY channel_desc, customer, customer_name
HAVING count(cust_sum_sales) = 3;

/* Task 4

Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and 
Americas regions.
Display the result by months and by product in alphabetical order.
 */
WITH product_sale_month AS (
  SELECT
    p.prod_category,
    EXTRACT(MONTH FROM s.time_id) AS month_nr,
    SUM(s.amount_sold) AS monthly_total_sales,
    SUM(SUM(s.amount_sold)) OVER (PARTITION BY p.prod_category ORDER BY EXTRACT(MONTH FROM s.time_id)) AS cum_sales
  FROM
    sh.sales s
    INNER JOIN sh.products p ON s.prod_id = p.prod_id
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.countries co ON c.country_id = co.country_id
  	WHERE EXTRACT(YEAR FROM s.time_id) = 2000
    AND EXTRACT(MONTH FROM s.time_id) IN (1, 2, 3)
    AND co.country_region IN ('Europe', 'Americas')
  	GROUP BY p.prod_category, EXTRACT(MONTH FROM s.time_id)
)
SELECT
  prod_category,	
  month_nr,
  monthly_total_sales,
  cum_sales
FROM product_sale_month
ORDER BY month_nr, prod_category;

--corrected but without window function. Is this an acceptable version?
SELECT
    --p.prod_id AS productid,
    p.prod_name AS product,
    '2000-' || to_char(EXTRACT(MONTH FROM s.time_id), '00') AS month_nr,
    SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END) AS total_sales_americas,
    SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) AS total_sales_europe
FROM
sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
INNER JOIN sh.countries co ON c.country_id = co.country_id
WHERE EXTRACT(YEAR FROM s.time_id) = 2000
AND EXTRACT(MONTH FROM s.time_id) IN (1, 2, 3)
AND (co.country_region = 'Europe' OR co.country_region = 'Americas')
GROUP BY p.prod_id, p.prod_name, EXTRACT(MONTH FROM s.time_id);
