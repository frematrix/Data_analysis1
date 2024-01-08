/* Task 1. Create a view
 * Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the 
 * current quarter. The view should only display categories with at least one sale in the current quarter. The current 
 * quarter should be determined dynamically.*/

SELECT * FROM sales_revenue_by_category_qtr;

CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS   
SELECT
        c.name AS film_category,
        SUM(p.amount) AS revenue_per_quarter
    FROM
        public.payment p
        INNER JOIN public.rental r ON p.rental_id = r.rental_id
        INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN public.film f ON i.film_id = f.film_id
        INNER JOIN public.film_category fc ON f.film_id = fc.film_id
        INNER JOIN public.category c ON fc.category_id = c.category_id 
    WHERE
        EXTRACT(quarter FROM p.payment_date) = EXTRACT(quarter FROM CURRENT_DATE)
    GROUP BY
        c.name
    HAVING SUM(p.amount) > 0;
   
/* Task 2. Create a query language functions
 * Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing the 
 * current quarter and returns the same result as the 'sales_revenue_by_category_qtr' view.
 */

SELECT * FROM public.get_sales_revenue_by_category_qtr ('2017-01-01'::date);
   
CREATE FUNCTION public.get_sales_revenue_by_category_qtr (IN curr_quarter date)
RETURNS TABLE (category_name varchar(20), revenue_per_quarter NUMERIC(7,2))
AS $$
SELECT
        c.name AS film_category,
        SUM(p.amount) AS revenue_per_quarter
    FROM
        public.payment p
        INNER JOIN public.rental r ON p.rental_id = r.rental_id
        INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN public.film f ON i.film_id = f.film_id
        INNER JOIN public.film_category fc ON f.film_id = fc.film_id
        INNER JOIN public.category c ON fc.category_id = c.category_id 
    WHERE
        p.payment_date >= DATE_TRUNC('quarter', curr_quarter)
        AND p.payment_date < DATE_TRUNC('quarter', curr_quarter) + INTERVAL '3 months'
    GROUP BY
        c.name
    HAVING SUM(p.amount) > 0
$$
LANGUAGE sql;

-- Task 3. Create procedure language functions

/* Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
The function should format the result set as follows:
Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);
 */

SELECT * FROM public.most_popular_films_by_countries(array['Afghanistan', 'Brazil', 'United States']);

CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries (country_names text[])
RETURNS TABLE 	(countryname TEXT,
				film TEXT,
				rating mpaa_rating,
				LANGUAGE bpchar(20),
				length int2,
				release_year year)
LANGUAGE plpgsql
AS	
$$
DECLARE 
country_name TEXT;
BEGIN
FOREACH country_name IN ARRAY country_names
LOOP
RETURN query
WITH 
fav_film_per_country AS (
	SELECT  
		co.country,
        f.title AS fav_film,
        COUNT(*) AS rental_count
    FROM
        public.film f
        INNER JOIN public.inventory i ON f.film_id = i.film_id
        INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
        INNER JOIN public.payment p ON r.rental_id = p.rental_id
        INNER JOIN public.customer c ON p.customer_id = c.customer_id
        INNER JOIN public.address a ON c.address_id = a.address_id
        INNER JOIN public.city ci ON a.city_id = ci.city_id
        INNER JOIN public.country co ON ci.country_id = co.country_id
    GROUP BY
        co.country, f.title  
    ORDER BY
        rental_count DESC
)
SELECT 
	country,
	fav_film,
	f.rating,
	l.name,
	f.length,
	f.release_year
FROM
fav_film_per_country ffpc
INNER JOIN public.film f ON ffpc.fav_film = f.title
INNER JOIN public.language l ON f.language_id = l.language_id
WHERE country = country_name
ORDER BY rental_count DESC 
FETCH FIRST 1 ROWS WITH TIES;
END LOOP;
END;
$$;

-- Task 4. Create procedure language functions

/* Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies 
containing the word 'love' in their title). 
The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a 
message indicating that it was not found.
The function should produce the result set in the following format (note: the 'row_num' field is an automatically generated 
counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
Query (example):select * from core.films_in_stock_by_title('%love%’);*/

SELECT * FROM public.films_in_stock_by_title('%LOVE%');

CREATE OR REPLACE FUNCTION public.films_in_stock_by_title (filmtitle TEXT)
RETURNS TABLE 	(row_num bigint,
				title_of_film TEXT,
				LANGUAGE bpchar(20),
				customer_name TEXT,
				rental_date timestamptz)
LANGUAGE plpgsql
AS	
$$
DECLARE 
row_counter bigint :=0;
lovefilm_record record;	
BEGIN	
FOR	
lovefilm_record IN (SELECT 	f.film_id,
									f.language_id,
									f.title AS lovefilmtitle, 
									r.rental_date loverentaldate,
									r.customer_id 
									FROM public.film f
									INNER JOIN public.inventory i ON f.film_id = i.film_id
									INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
									INNER JOIN (SELECT i.film_id, max(r.rental_date) AS xdate
									FROM public.inventory i
									INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
									GROUP BY i.film_id) boo  
									ON boo.film_id = f.film_id AND r.rental_date = boo.xdate
									WHERE f.title LIKE filmtitle
									AND inventory_in_stock(i.inventory_id)
									ORDER BY f.film_id, f.title, r.rental_date) 
									LOOP row_counter := row_counter+1;
row_num := 	row_counter;
title_of_film := lovefilm_record.lovefilmtitle;
LANGUAGE := (SELECT l.name FROM public."language" l WHERE l.language_id = lovefilm_record.language_id);
customer_name := (SELECT c.first_name || ' ' || c.last_name FROM public.customer c WHERE c.customer_id = lovefilm_record.customer_id);
rental_date := lovefilm_record.loverentaldate;
RETURN NEXT;
END LOOP;
IF row_counter = 0 THEN	
	RAISE NOTICE 'No films with % title', filmtitle;
END IF;
RETURN;
END;
$$;

-- Task 5. Create procedure language functions

/* Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new 
 * movie with the given title in the film table. The function should generate a new unique film ID, set the rental rate 
 * to 4.99, the rental duration to three days, the replacement cost to 19.99. The release year and language are optional 
 * and by default should be current year and Klingon respectively. The function should also verify that the language 
 * exists in the 'language' table. Then, ensure that no such function has been created before; if so, replace it.
 */

SELECT public.new_movie('New movie in november');
SELECT public.new_movie('New movie in november1', 2021, 'Italian');
SELECT public.new_movie('New movie in november2', 2021);
SELECT public.new_movie('New movie in november3', neworlang_name=> 'Italian');

CREATE OR REPLACE FUNCTION public.new_movie (IN newtitle TEXT, 
													newrelease_year integer DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
													neworlang_name TEXT DEFAULT 'Klingon')
RETURNS TEXT	
LANGUAGE plpgsql
AS $$
DECLARE 
	v_film_id BIGINT;
BEGIN
	
	IF EXISTS (SELECT 1 FROM public.film WHERE title = newtitle) THEN
        RAISE NOTICE 'The film "%" is already in the database.', newtitle;
        RETURN 'Film already exists';
    END IF;
   
INSERT INTO public.film (title,
						release_year,
						language_id,
						original_language_id,
						rental_duration, 
						rental_rate, 
						replacement_cost)
SELECT 	new_films.title, 
		new_films.release_year, 
		l.language_id AS language_id, 
		ol.language_id AS original_language_id,
		new_films.rental_duration, 
		new_films.rental_rate, 
		new_films.replacement_cost
FROM
(SELECT newtitle AS title, newrelease_year AS release_year, 'English' AS language_name, neworlang_name AS orlang_name,
3 AS rental_duration, 4.99 AS rental_rate, 19.99 AS replacement_cost) AS new_films
INNER JOIN public.language l
ON new_films.language_name = l.name
INNER JOIN public."language" ol
ON new_films.orlang_name = ol.name
WHERE new_films.title NOT IN (SELECT title FROM public.film)
RETURNING film_id INTO v_film_id;
RAISE NOTICE 'New film: "%" added, ID = %',newtitle, v_film_id;
RETURN v_film_id;
END;
$$;
