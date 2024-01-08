
/* Task 1. Window Functions

Create a query to generate a report that identifies for each channel and throughout the entire period, the regions with 
the highest quantity of products sold (quantity_sold). 
The resulting report should include the following columns:
CHANNEL_DESC
COUNTRY_REGION
SALES: This column will display the number of products sold (quantity_sold) with two decimal places.
SALES %: This column will show the percentage of maximum sales in the region (as displayed in the SALES column) compared to 
the total sales for that channel. The sales percentage should be displayed with two decimal places and include the percent 
sign (%) at the end.
Display the result in descending order of SALES
 */

SELECT 	channel_desc, 
		country_region, 
		to_char(sales,'999,999,999.00') AS sales,
		concat(round(max_sales/total_sales * 100, 2),'%') AS "SALES %"
FROM
	(SELECT ch.channel_desc,
			co.country_region,
			sum(s.quantity_sold) AS sales,
			max(sum(s.quantity_sold)) OVER (PARTITION BY ch.channel_desc) AS max_sales,
			sum(sum(s.quantity_sold)) OVER (PARTITION BY ch.channel_desc) AS total_sales
	FROM sh.sales s
	INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id 
	INNER JOIN sh.customers cu ON s.cust_id = cu.cust_id 
	INNER JOIN sh.countries co ON cu.country_id = co.country_id
	GROUP BY ch.channel_desc, co.country_region) tab
WHERE sales = max_sales
GROUP BY channel_desc, country_region, sales, max_sales, total_sales
ORDER BY sales DESC;

/* Task 2. Window Functions

Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year. 
Determine the sales for each subcategory from 1998 to 2001.
Calculate the sales for the previous year for each subcategory.
Identify subcategories where the sales from 1998 to 2001 are consistently higher than the previous year.
Generate a dataset with a single column containing the identified prod_subcategory values.
*/
WITH subcategory_sales AS (
	SELECT 	p.prod_subcategory_desc,
			t.calendar_year,
			sum(s.amount_sold),
			LAG (sum(s.amount_sold)) OVER(PARTITION BY p.prod_subcategory_desc ORDER BY t.calendar_year ASC) AS prev_year,
			sum(s.amount_sold)-LAG (sum(s.amount_sold)) OVER(PARTITION BY p.prod_subcategory_desc ORDER BY t.calendar_year ASC) AS diff
	FROM 	sh.sales s
	INNER JOIN sh.products p ON p.prod_id = s.prod_id 
	INNER JOIN sh.times t ON t.time_id = s.time_id 
	WHERE t.calendar_year IN (1998, 1999, 2000, 2001)
	GROUP BY p.prod_subcategory_desc, calendar_year)
SELECT 		prod_subcategory_desc
FROM 		subcategory_sales
GROUP BY 	prod_subcategory_desc
HAVING 		COUNT(CASE WHEN diff < 0 THEN 1 ELSE NULL END) = 0;

/* Task 3. Window Frames

Create a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories. In the 
sales of products from the categories 'Electronics,' 'Hardware,' and 'Software/Other,' across the distribution channels 
'Partners' and 'Internet'.
The resulting report should include the following columns:
CALENDAR_YEAR: The calendar year
CALENDAR_QUARTER_DESC: The quarter of the year
PROD_CATEGORY: The product category
SALES$: The sum of sales (amount_sold) for the product category and quarter with two decimal places
DIFF_PERCENT: Indicates the percentage by which sales increased or decreased compared to the first quarter of the year. 
For the first quarter, the column value is 'N/A.' The percentage should be displayed with two decimal places and include 
the percent sign (%) at the end.
CUM_SUM$: The cumulative sum of sales by quarters with two decimal places
The final result should be sorted in ascending order based on two criteria: first by 'calendar_year,' then by 
'calendar_quarter_desc'; and finally by 'sales' descending
 */

SELECT 	calendar_year,
		calendar_quarter_desc,
		prod_category,
		sales$,
		CASE WHEN DIFF_PERCENT='0' THEN 'N/A'
			ELSE to_char(DIFF_PERCENT, '999,999.99') || '%' 
			END AS diff_percent,
		to_char(CUM_SUM$, '999,999,999.99')  AS CUM_SUM$
FROM 
(SELECT t.calendar_year,
		t.calendar_quarter_desc,
		p.prod_category,
		sum(s.amount_sold) AS sales$,
		((SUM(s.amount_sold) - FIRST_VALUE(SUM(s.amount_sold)) OVER w) * 100) /
    	FIRST_VALUE(SUM(s.amount_sold)) OVER w AS DIFF_PERCENT,	
    	sum(sum(s.amount_sold)) OVER (PARTITION BY t.calendar_year ORDER BY t.calendar_quarter_desc) AS CUM_SUM$
FROM sh.sales s
INNER JOIN sh.products p ON p.prod_id = s.prod_id 
INNER JOIN sh.times t ON t.time_id = s.time_id 
INNER JOIN sh.channels ch ON ch.channel_id = s.channel_id 
WHERE p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')
AND ch.channel_desc IN ('Partners', 'Internet')
AND t.calendar_year IN (1999, 2000)
GROUP BY t.calendar_year, t.calendar_quarter_desc, p.prod_category
WINDOW w AS (PARTITION BY t.calendar_year, p.prod_category ORDER BY t.calendar_quarter_desc)
ORDER BY calendar_year, calendar_quarter_desc ASC, sales$ DESC) tabl;

