-- select * from public.actor

--1. All comedy movies released between 2000 and 2004, alphabetical

-- with JOIN:
SELECT 	f.film_id, 
		f.title, c.name AS category_name, 
		f.release_year 
FROM film f 
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE c.category_id = (SELECT c.category_id FROM category c WHERE c.name LIKE 'Comedy') 
AND f.release_year BETWEEN 2000 AND 2004
ORDER by f.title;

-- also with SELECT statements - because we need columns from only one table:
SELECT 	f.film_id, 
		f.title, 
		f.release_year
FROM 	film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE c.name = 'Comedy' -- advice from mentor
AND f.release_year BETWEEN 2000 AND 2004
ORDER BY f.title;

--2. Revenue of every rental store for year 2017 (columns: address and address2 – as one column, revenue)

-- Here we have to get columns from multiple tables, thus we can do it with only JOIN clause
SELECT 	i.store_id, 
		CONCAT(a.address, a.address2) AS store_address, -- advice from mentor 
		SUM(p.amount) 
FROM inventory i  
LEFT JOIN store s ON s.store_id = i.store_id 
LEFT JOIN address a ON s.address_id = a.address_id
INNER JOIN rental r ON r.inventory_id = i.inventory_id
INNER JOIN payment p ON p.rental_id = r.rental_id 
WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31' -- corrected with period
GROUP BY i.store_id, a.address, address2;

-- in this version the tables' key columns have the same names, we can use the USING keyword
SELECT 	i.store_id, 
		COALESCE(a.address, '') || ' ' || COALESCE(a.address2,'') AS store_address, 
		SUM(p.amount)
FROM payment p 
INNER JOIN rental r 
USING (rental_id)
INNER JOIN inventory i 
USING (inventory_id)
INNER JOIN store s
USING (store_id)
INNER JOIN address a 
USING (address_id)
GROUP BY i.store_id, a.address, address2;
WHERE p.payment_date >= '2017-01-01' AND p.payment_date < '2018-01-01' -- corrected with period, other solution

-- I tried to solve this query with SEMI JOIN, but after 2 minutes of waiting for the query 
-- I figured it out that's not working:
/*SELECT COALESCE(a.address, '') || ' ' || COALESCE(a.address2,'') AS store_address, 
 * 		SUM(p.amount)
FROM 	payment p, 
		inventory i, 
		address a
WHERE rental_id IN 
				(SELECT rental_id 
				FROM rental r
				WHERE inventory_id IN
									(SELECT inventory_id
									FROM inventory i
									WHERE store_id IN 
													(SELECT store_id
													FROM store s
													WHERE address_id IN
																		(SELECT address_id
																		FROM address a))))
GROUP BY i.store_id, a.address, address2;*/

-- 3. Top-3 actors by number of movies they took part in (columns: first_name, last_name, 
-- number_of_movies, sorted by number_of_movies in descending order)

-- Here I could solve the query with JOIN clause, it's a bit easier than the below SELECT-JOIN combination
SELECT 	a.first_name, 
		a.last_name, 
		count(fa.actor_id) AS acting_qty
FROM film_actor fa
INNER JOIN actor a 
USING (actor_id)
GROUP BY fa.actor_id, a.first_name, a.last_name 
ORDER BY acting_qty DESC
FETCH FIRST 3 ROWS WITH TIES -- corrected leaving the LIMIT clause

-- Here I combined the SELECT statement with JOIN clause:
SELECT 	a.first_name, 
		a.last_name, 
		top_3_actors.acting_qty
FROM 
	(SELECT fa.actor_id, count(fa.actor_id) AS acting_qty
	FROM film_actor fa 
	GROUP BY actor_id 
	ORDER BY acting_qty DESC
	FETCH FIRST 3 ROWS WITH TIES) AS top_3_actors -- corrected
INNER JOIN actor a ON top_3_actors.actor_id = a.actor_id 
ORDER BY top_3_actors.acting_qty DESC;

--4. Number of comedy, horror and action movies per year (columns: release_year, number_of_action_movies, 
 -- number_of_horror_movies, number_of_comedy_movies), sorted by release year in descending order*/

-- Unfortunately I found just one solution. When I have to count multiple values in one column, 
-- this CASE-WHEN expression is good for it.
SELECT 	f.release_year,
		SUM(CASE WHEN fc.category_id IN 
										(SELECT c.category_id 
										FROM category c 
										WHERE c.name LIKE 'Horror') 
										THEN 1 ELSE 0 END) AS number_of_horror_movies,
		SUM(CASE WHEN fc.category_id IN 
										(SELECT c.category_id 
										FROM category c 
										WHERE c.name LIKE 'Action') 
										THEN 1 ELSE 0 END) AS number_of_action_movies,
		SUM(CASE WHEN fc.category_id IN 
										(SELECT c.category_id 
										FROM category c 
										WHERE c.name LIKE 'Comedy') 
										THEN 1 ELSE 0 END) AS number_of_comedy_movies
FROM film_category fc 
INNER JOIN film f ON f.film_id = fc.film_id 
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- solution by mentor:
SELECT 	f.release_year,
		SUM(CASE WHEN c.name = 'Horror'
		THEN 1 ELSE 0 END) AS number_of_horror_movies,
		SUM(CASE WHEN c.name = 'Action'
		THEN 1 ELSE 0 END) AS number_of_action_movies,
		SUM(CASE WHEN c.name = 'Comedy' 
		THEN 1 ELSE 0 END) AS number_of_comedy_movies
FROM film_category fc 
INNER JOIN film f ON f.film_id = fc.film_id 
INNER JOIN category c ON fc.category_id = c.category_id 
GROUP BY f.release_year
ORDER BY f.release_year DESC;

--5. Which staff members made the highest revenue for each store and deserve a bonus for 2017 year?

-- I would solve this question by joining the staff, store and payment tables, then grouping by columns 
-- which are without aggregate function and ordering by revenue

-- Another solution: here I didn't limited any values. This could be a good method for the exact result?
SELECT 	DISTINCT ON(s.store_id)
		p.staff_id,
		CONCAT(s.first_name, ' ', s.last_name) AS staff_member, 
		SUM(p.amount) AS revenue, 
		s.store_id
FROM payment p
INNER JOIN staff s ON s.staff_id = p.staff_id 
INNER JOIN store st ON st.store_id = s.store_id
GROUP BY s.store_id, p.staff_id, staff_member
ORDER BY s.store_id, revenue DESC 

-- 6. Which 5 movies were rented more than others, and what's the expected age of the audience for these movies?

-- I would solve this with a subquery that gives result of the five most rented films 
-- then with the given film id-s I filter the columns of the film table 

-- Corrected solution:
SELECT 	i.film_id, 
		count(*) AS rent_nr,
		f.title, 
		f.rating  
FROM inventory i
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN film f  ON f.film_id = i.film_id 
GROUP BY i.film_id, f.title, f.rating 
ORDER BY rent_nr DESC
FETCH FIRST 5 ROWS WITH TIES;

-- 7. Which actors/actresses didn't act for a longer period of time than the others?

WITH actor_film_release_year AS 
(SELECT a.first_name, a.last_name, f.release_year, fa.actor_id 
FROM public.film f
INNER JOIN public.film_actor fa
ON f.film_id = fa.film_id
INNER JOIN public.actor a ON a.actor_id = fa.actor_id)
SELECT a1.actor_id, concat(a1.first_name, ' ', a1.last_name), a1.release_year, min(a2.release_year - a1.release_year)
FROM actor_film_release_year a1
LEFT JOIN actor_film_release_year a2
ON a1.actor_id = a2.actor_id
AND a1.release_year < a2.release_year
GROUP BY a1.actor_id, a1.release_year, a1.first_name, a1.last_name
HAVING min(a2.release_year - a1.release_year) > 1
ORDER BY min(a2.release_year - a1.release_year) DESC, a1.actor_id, a1.release_year
FETCH FIRST 10 ROWS WITH TIES;
