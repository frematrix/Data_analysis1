/* Task. Create one function that reports all information for a particular client and timeframe

Customer's name, surname and email address;
Number of films rented during specified timeframe;
Comma-separated list of rented films at the end of specified time period;
Total number of payments made during specified time period;
Total amount paid during specified time period;

Function's input arguments: client_id, left_boundary, right_boundary.
The function must analyze specified timeframe [left_boundary, right_boundary] and output specified information for this 
timeframe.
Function's result format: table with 2 columns ‘metric_name’ and ‘metric_value’.
 */

SELECT * FROM public.customer_rental_info_by_period (413, '2005-05-25'::date, '2005-05-28'::date);

CREATE OR REPLACE FUNCTION public.customer_rental_info_by_period (IN clientid int, 
																	left_boundary date, 
																	right_boundary date)
RETURNS TABLE 	(metric_name TEXT, 
				metric_value TEXT)
AS $$
SELECT 'customer info' AS metric_name, 
		concat(c.first_name, ' ', c.last_name, ', ', c.email) AS metric_value
FROM public.customer c 
WHERE c.customer_id = clientid
UNION ALL	
SELECT 'num. of films rented' AS metric_name, 
		CAST(count(i.film_id) AS TEXT)
FROM public.inventory i 
INNER JOIN public.rental r ON r.inventory_id = i.inventory_id
WHERE customer_id = clientid
AND r.rental_date BETWEEN left_boundary AND right_boundary
UNION ALL 
SELECT 'rented film title' AS metric_name, 
		STRING_AGG(f.title, ', ')
FROM public.film f 
INNER JOIN public.inventory i ON i.film_id = f.film_id 
INNER JOIN public.rental r ON r.inventory_id = i.inventory_id 
WHERE r.customer_id = clientid
AND r.rental_date BETWEEN left_boundary AND right_boundary
UNION ALL 
SELECT 'num. of payments' AS metric_name, 
		CAST(count(DISTINCT p.payment_id) AS TEXT)
FROM public.payment p 
INNER JOIN public.rental r ON p.rental_id = r.rental_id 
WHERE p.customer_id = clientid
AND r.rental_date BETWEEN left_boundary AND right_boundary
UNION ALL 
SELECT 'payment amount' AS metric_name, 
		CAST(COALESCE(sum(DISTINCT p.amount), NULL) AS TEXT)
FROM public.payment p 
INNER JOIN public.rental r ON p.rental_id = r.rental_id 
WHERE p.customer_id = clientid
AND r.rental_date BETWEEN left_boundary AND right_boundary;
$$
LANGUAGE SQL;
