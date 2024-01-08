
/* Task 1

Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels and 
regions: 'Americas,' 'Asia,' and 'Europe.' 
The resulting report should contain the following columns:
AMOUNT_SOLD: This column should show the total sales amount for each sales channel
% BY CHANNELS: In this column, we should display the percentage of total sales for each channel (e.g. 100% - total sales 
	for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
% PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column but for the pre-
	vious year
% DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating the 
	change in sales percentage from the previous year.
The final result should be sorted in ascending order based on three criteria: first by 'country_region,' then by 
	'calendar_year,' and finally by 'channel_desc'*/

WITH total_sales AS 
   (SELECT 	cn.country_region AS region,
        	t.calendar_year AS year,
        	ch.channel_desc AS channel,
        	sum(amount_sold) AS total_amount,
        	round(sum(amount_sold)*100.0/sum(sum(amount_sold)) 
        				OVER (PARTITION BY cn.country_region, t.calendar_year), 2) AS percchannel
    FROM 	sh.countries cn 
    INNER JOIN sh.customers cu ON cu.country_id = cn.country_id 
    INNER JOIN sh.sales s ON s.cust_id = cu.cust_id 
    INNER JOIN sh.times t ON t.time_id = s.time_id 
    INNER JOIN sh.channels ch ON ch.channel_id = s.channel_id 
    WHERE cn.country_region IN ('Americas', 'Asia', 'Europe')
    AND t.calendar_year IN (1999, 2000, 2001)
    AND ch.channel_desc IN ('Internet', 'Direct Sales', 'Partners')
    GROUP BY cn.country_region, t.calendar_year, ch.channel_desc),
total_sales_prev AS 
    (SELECT cn.country_region AS region,
        	t.calendar_year AS year,
        	ch.channel_desc AS channel,
        	sum(amount_sold) AS total_amount_prev,
        	round(sum(amount_sold)*100.0/sum(sum(amount_sold)) 
        				OVER (PARTITION BY cn.country_region, t.calendar_year), 2) AS percchannel_prev
    FROM sh.countries cn 
    INNER JOIN sh.customers cu ON cu.country_id = cn.country_id 
    INNER JOIN sh.sales s ON s.cust_id = cu.cust_id 
    INNER JOIN sh.times t ON t.time_id = s.time_id 
    INNER JOIN sh.channels ch ON ch.channel_id = s.channel_id 
    WHERE cn.country_region IN ('Americas', 'Asia', 'Europe')
    AND t.calendar_year IN (1998, 1999, 2000)
    AND ch.channel_desc IN ('Internet', 'Direct Sales', 'Partners')
    GROUP BY cn.country_region, t.calendar_year, ch.channel_desc)
SELECT 	ts.region,
    	ts.year,
    	ts.channel,
    	to_char(round(ts.total_amount), '9,999,999,999') || ' $' AS amount_sold,
    	to_char(ts.percchannel, '9,999,999.00') || ' %' AS "% BY CHANNEL",
    	to_char(tsv.percchannel_prev, '9,999,999.00') || ' %' AS "PREVIOUS PERIOD",
    	to_char((ts.percchannel-tsv.percchannel_prev), '9,999,999.00') || ' %'  AS "% DIFF"
FROM total_sales ts
INNER JOIN total_sales_prev tsv ON ts.region = tsv.region AND ts.year = tsv.year + 1 AND ts.channel = tsv.channel
GROUP BY ts.region, ts.year, ts.channel, ts.total_amount, tsv.total_amount_prev, ts.percchannel, tsv.percchannel_prev;

/* Task 2

You need to create a query that meets the following requirements:
Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
Include a column named CUM_SUM to display the amounts accumulated during each week.
Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days using a 
centered moving average.
For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
For Friday, calculate the average sales on Thursday, Friday, and the weekend.
Ensure that your calculations are accurate for the beginning of week 49 and the end of week 51.
 */

-- Unfortunately, I could not solve the average calculation for the first and last value. I tried using CTE to account 
-- for week 48 and week 52 values ​​with no success.
WITH full_sales_report AS 
	(SELECT t.calendar_week_number,
			s.time_id,
			t.day_name,
			sum(amount_sold) AS sales,
			sum(sum(amount_sold)) OVER (PARTITION BY t.calendar_week_number ORDER BY s.time_id
									RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "CUM_SUM"
	FROM 	sh.times t
	INNER JOIN sh.sales s ON s.time_id = t.time_id 
	WHERE 	t.calendar_week_number IN (48, 49, 50, 51, 52)
	AND 	EXTRACT (YEAR FROM s.time_id) = 1999
	GROUP BY t.calendar_week_number, s.time_id, t.day_name
	ORDER BY t.calendar_week_number, s.time_id, t.day_name)
SELECT 	fsr.calendar_week_number,
		fsr.time_id,
		t.day_name,
		to_char((fsr.sales), '99 999 999 999.99') AS totalsales,
		to_char(sum(fsr.sales) OVER (PARTITION BY fsr.calendar_week_number ORDER BY fsr.time_id
									RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), '99 999 999 999.99') AS "CUM_SUM",
		CASE WHEN t.day_name = 'Monday' THEN round(sum(fsr.sales) OVER (PARTITION BY fsr.calendar_week_number 
			ORDER BY fsr.time_id RANGE BETWEEN INTERVAL '2' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING)/3.0, 2)
			WHEN t.day_name = 'Friday' THEN round(sum(fsr.sales) OVER (PARTITION BY fsr.calendar_week_number 
			ORDER BY fsr.time_id RANGE BETWEEN INTERVAL '1' DAY PRECEDING AND INTERVAL '2' DAY FOLLOWING)/3.0, 2)
			ELSE round(avg(fsr.sales) OVER (ORDER BY fsr.time_id RANGE BETWEEN 
			INTERVAL '1' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING), 2) END "CENTERED_3_DAY_AVG"
FROM 	sh.times t
INNER JOIN sh.sales s ON s.time_id = t.time_id 
INNER JOIN full_sales_report fsr ON fsr.time_id = s.time_id 
WHERE 	fsr.calendar_week_number IN (49, 50, 51)
AND 	EXTRACT (YEAR FROM s.time_id) = 1999
GROUP BY fsr.calendar_week_number, fsr.time_id, t.day_name, fsr.sales
ORDER BY fsr.calendar_week_number, fsr.time_id, t.day_name;

/*
 * Inga Tomasevic (Guest) Tuesday 12:18
 * 1) Should the sum of (Sat+Sun) sales be used in CENTERED_3_DAY_AVG as single sum of single (Weekend) unit? Or should 
 * we display it as single unit (Weekend), but still take into account that there are 2 days inside.
For instance different results:
a) (10 + (15 + 7) + 20) /  3 = avg 17.33 (3 sums, 3 days as Fri, Weekend, Mon)
b) (10 + (15 + 7) + 20) /  4 = avg 13.00 (3 sums, but 4 days as Fri, Sat, Sun, Mon)
...

[Tuesday 13:24] Hanna Petrashka
1 - a
...
 */

WITH full_sales_report AS 
	(SELECT t.calendar_week_number,
			s.time_id,
			t.day_name,
			sum(amount_sold) AS sales,
			sum(sum(amount_sold)) OVER (PARTITION BY t.calendar_week_number ORDER BY s.time_id
									RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "CUM_SUM"
	FROM 	sh.times t
	INNER JOIN sh.sales s ON s.time_id = t.time_id 
	WHERE 	t.calendar_week_number IN (48, 49, 50, 51, 52)
	AND 	EXTRACT (YEAR FROM s.time_id) = 1999
	GROUP BY t.calendar_week_number, s.time_id, t.day_name
	ORDER BY t.calendar_week_number, s.time_id, t.day_name)
SELECT 	fsr.calendar_week_number,
		fsr.time_id,
		t.day_name,
		to_char((fsr.sales), '99 999 999 999.99') AS totalsales,
		to_char(sum(fsr.sales) OVER (PARTITION BY fsr.calendar_week_number ORDER BY fsr.time_id
									RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), '99 999 999 999.99') AS "CUM_SUM",
		CASE WHEN t.day_name = 'Monday' THEN round(avg(fsr.sales) OVER (PARTITION BY fsr.calendar_week_number 
			ORDER BY fsr.time_id RANGE BETWEEN INTERVAL '2' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING), 2)
			WHEN t.day_name = 'Friday' THEN round(avg(fsr.sales) OVER (PARTITION BY fsr.calendar_week_number 
			ORDER BY fsr.time_id RANGE BETWEEN INTERVAL '1' DAY PRECEDING AND INTERVAL '2' DAY FOLLOWING), 2)
			ELSE round(avg(fsr.sales) OVER (ORDER BY fsr.time_id RANGE BETWEEN 
			INTERVAL '1' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING), 2) END "CENTERED_3_DAY_AVG"
FROM 	sh.times t
INNER JOIN sh.sales s ON s.time_id = t.time_id 
INNER JOIN full_sales_report fsr ON fsr.time_id = s.time_id 
WHERE 	fsr.calendar_week_number IN (49, 50, 51)
AND 	EXTRACT (YEAR FROM s.time_id) = 1999
GROUP BY fsr.calendar_week_number, fsr.time_id, t.day_name, fsr.sales
ORDER BY fsr.calendar_week_number, fsr.time_id, t.day_name;

/* Task 3

Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. 
Additionally, explain the reason for choosing a specific frame type for each example. 
This can be presented as a single query or as three distinct queries.
*/

SELECT	s.prod_id AS product,
    	s.time_id AS period,
    	s.amount_sold AS amount,
    	sum(s.amount_sold) OVER (ORDER BY s.time_id 
    		RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount,
    	round(AVG(s.amount_sold) OVER (PARTITION BY s.prod_id ORDER BY s.time_id 
    		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS avg_3_day,
    	sum(s.amount_sold) OVER (ORDER BY s.amount_sold
    		GROUPS 3 PRECEDING) AS sum_3_day
FROM 	sh.sales s
WHERE EXTRACT (YEAR FROM s.time_id) = 2000
AND EXTRACT (MONTH FROM s.time_id) IN (04, 05, 06)
AND s.prod_id = 23
GROUP BY s.time_id, s.prod_id, s.amount_sold, s.channel_id;

-- RANGE Mode: calculates a cumulative summary (running total summary) of the amount_sold from the first row to the 
-- last row. 
-- ROWS Mode: calculates the average amount_sold based on the previous 2 rows and the current row.
-- GROUPS Mode: calculates the sum of the amount_sold values for the current row and the 3 preceding rows based on the 
-- order of amount_sold. 

