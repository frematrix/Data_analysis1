-- 1. Top-3 most selling movie categories of all time and total dvd rental income for each category. 
-- Only consider dvd rental customers from the USA.

-- I used JOIN clause for retrieving datas, because I need columns from payment and category tables
-- which are connected by another 4 tables
SELECT     c.name,
           SUM(p.amount) AS rental_income
FROM       PUBLIC.category c
INNER JOIN PUBLIC.film_category fc
ON         c.category_id = fc.category_id
INNER JOIN PUBLIC.film f
ON         fc.film_id = f.film_id
INNER JOIN PUBLIC.inventory i
ON         f.film_id = i.film_id
INNER JOIN PUBLIC.rental r
ON         i.inventory_id = r.inventory_id
INNER JOIN PUBLIC.payment p
ON         p.rental_id = r.rental_id
GROUP BY   c.name
ORDER BY   rental_income desc
FETCH first 3 ROWS with ties;


-- 2. For each client, display a list of horrors that he had ever rented (in one column, separated 
-- by commas), and the amount of money that he paid for it

-- Similarly to the query above, i used JOIN clause due to usage of the many tables
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer,
       STRING_AGG(DISTINCT f.title, ', ')     AS rented_horrors,
       SUM(p.amount)
FROM   PUBLIC.customer c
       LEFT JOIN PUBLIC.rental r
              ON c.customer_id = r.customer_id
       LEFT JOIN PUBLIC.inventory i
              ON r.inventory_id = i.inventory_id
       LEFT JOIN PUBLIC.film f
              ON i.film_id = f.film_id
       LEFT JOIN PUBLIC.film_category fc
              ON f.film_id = fc.film_id
       LEFT JOIN PUBLIC.category cat
              ON fc.category_id = cat.category_id
       LEFT JOIN PUBLIC.payment p
              ON r.rental_id = p.rental_id
WHERE  cat.name = 'Horror'
GROUP  BY customer
ORDER  BY customer; 