/* 1. Choose your top-3 favorite movies and add them to the 'film' table. Fill in rental rates with 4.99, 9.99 and 19.99 and 
 * rental durations with 1, 2 and 3 weeks respectively.
 */

-- corrected version by Aliaksei:
INSERT INTO public.film (title, language_id, rental_duration, rental_rate)
SELECT new_films.title, l.language_id, new_films.rental_duration, new_films.rental_rate
FROM
(SELECT 'Matrix' AS title, 'English' AS language_name, 1 AS rental_duration, 4.99 AS rental_rate
UNION ALL
SELECT 'Gran turismo', 'English', 2, 9.99
UNION ALL 
SELECT 'Free Guy', 'English', 3, 19.99) AS new_films
INNER JOIN public.language l
ON new_films.language_name = l.name
WHERE new_films.title NOT IN (SELECT title FROM public.film)
RETURNING *;


/* 2. Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors 
 * in total). Add your favorite movies to any store's inventory.
 */

-- corrected vesrion:
INSERT INTO public.actor (first_name, last_name)
SELECT new_actor.first_name, new_actor.last_name
FROM 
(SELECT 'Keanu' AS first_name, 'Reeves' AS last_name
UNION ALL 
SELECT 'Carrie-Anne', 'Moss'
UNION ALL 
SELECT 'Laurence', 'Fishburne'
UNION ALL
SELECT 'Archie', 'Madekwe'
UNION ALL
SELECT 'Orlando', 'Bloom'
UNION ALL
SELECT 'David', 'Harbour'
UNION ALL
SELECT 'Ryan', 'Reynolds'
UNION ALL
SELECT 'Jodie', 'Comer'
UNION ALL
SELECT 'Joe', 'Keery') AS new_actor
WHERE new_actor.last_name NOT IN (SELECT last_name FROM actor) 
AND new_actor.first_name NOT IN (SELECT first_name FROM actor) 
RETURNING *;

-- Sorry, I tried to solve to insert into film_actor table, but I don't understand how to correct, because I have insert 
-- values from 2 tables. If I don't refer to film_id with the film title, with witch film_id will the data be inserted into 
-- the film_actor table?
-- I tried to write another query, but here I used again the film title as a reference:
INSERT INTO public.film_actor (actor_id, film_id)
SELECT names.lastname, film.film_id 
FROM film
CROSS JOIN (
    SELECT 'Reeves' AS lastname UNION ALL
    SELECT 'Moss' UNION ALL
    SELECT 'Fishburne'
) AS names
WHERE film.title = 'Matrix'

INSERT INTO public.inventory (film_id, store_id)
SELECT f.film_id, 2
FROM public.film f
WHERE f.title = 'Matrix'
UNION ALL
SELECT f.film_id, 2
FROM public.film f
WHERE f.title = 'Gran turismo'
UNION ALL 
SELECT f.film_id, 2
FROM public.film f
WHERE f.title = 'Free Guy';

/* 3. Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data 
 * to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. Please do 
 * not perform any updates on the "address" table, as this can impact multiple records with the same address.
 */

/* I have a question here. I changed a lot of data in the original solution, so I want to restore the original database. 
 * I deleted it in pgadmin, restored it, replaced the file at the source location, and also deleted the database in dbeaver, 
 * reconnected, but still the data I modified is in the customer table. I looked everywhere for the answer but 
 * couldn't restore that table.*/

-- Corrected solution:
-- I separated this task in 2 parts. First part: search for a customer_id with the condition above written.
-- Then I updated that customer_id with my values.

SELECT c.customer_id, c.last_name, count(p.payment_id) 
FROM public.customer c
INNER JOIN public.payment p 
ON c.customer_id = p.customer_id 
GROUP BY c.customer_id 
HAVING count(p.payment_id) >= 43
ORDER BY count(p.payment_id) DESC;

-- id: 552

UPDATE public.customer
SET store_id = 2,
	first_name = 'Katalin',
	last_name = 'Ordog',
	email = 'catherine.devil@gmail.com',
	address_id = 3
WHERE customer_id = 552;


/* 4. Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
 */

-- Deleting datas from multiple table, DELETE command cannot be used in a single query.
-- I used DELETE in separate query, in the first query I used the customer table for the same-reference data to delete
DELETE FROM public.payment
USING public.customer
WHERE payment.customer_id = customer.customer_id
AND payment.customer_id IN (SELECT customer_id 
							FROM public.customer c 
							WHERE c.email LIKE 'catherine.devil@gmail.com');
						
DELETE FROM public.rental
WHERE rental.customer_id IN (SELECT customer_id 
							FROM public.customer c 
							WHERE c.email LIKE 'catherine.devil@gmail.com');

/* 5. Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to 
 * represent this activity) (Note: to insert the payment_date into the table payment, you can create a new partition 
 * (see the scripts to install the training database ) or add records for the first half of 2017)
 */

-- I created partitions for dates in the payment table:
CREATE TABLE public.payment_p2023_02 
PARTITION OF public.payment					
FOR VALUES FROM ('2023-07-01 00:00:00+02') TO ('2023-12-31 22:59:59+02')
PARTITION BY RANGE (payment_date);

CREATE TABLE public.payment_p2017_02_2023_01 
PARTITION OF public.payment					
FOR VALUES FROM ('2017-06-30 23:00:00+02') TO ('2023-07-01 00:00:00+02');
PARTITION BY RANGE (payment_date);

-- I could insert my rental values into the rental tables with separate "INSERT INTO... SELECT" statement

-- Question: if I have to insert multiple values from multiple tables (like in case of rental table), but the source tables
-- are not in direct connection with each other, joining tables is not a good idea, so how could I solve this without 
-- hard-coding values?
-- Can I use the formula above which you've written (the first task with inserting values into the film table), but here 
-- the values are not new but are from another table. I'm stuck with this.

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT '2023-10-30 09:05:21.000 +0200', inventory_id, customer_id, staff_id 
FROM public.inventory, public.customer, public.staff
WHERE inventory.film_id = 3001 AND customer.customer_id = 21 AND staff.last_name LIKE 'Lockyard'
RETURNING rental.rental_id;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT '2023-10-30 09:05:21.000 +0200', inventory_id, customer_id, staff_id 
FROM public.inventory, public.customer, public.staff
WHERE inventory.film_id = 3002 AND customer.customer_id = 21 AND staff.last_name LIKE 'Lockyard'
RETURNING rental.rental_id;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT '2023-10-30 09:05:21.000 +0200', inventory_id, customer_id, staff_id 
FROM public.inventory, public.customer, public.staff
WHERE inventory.film_id = 3003 AND customer.customer_id = 21 AND staff.last_name LIKE 'Lockyard'
RETURNING rental.rental_id;

INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer.customer_id, staff.staff_id, rental_id, 8.99, NOW()
FROM public.customer, public.staff, public.rental
WHERE customer.customer_id = 21 AND staff.last_name LIKE 'Lockyard' AND rental.inventory_id = 4582
RETURNING payment.payment_id;

-- I tried to insert datas into the payment table with a single query, It was successful.
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer.customer_id, staff.staff_id, rental_id, 9.99, NOW()
FROM public.customer, public.staff, public.rental
WHERE customer.customer_id = 21 AND staff.last_name LIKE 'Lockyard' AND rental.inventory_id = 4583
UNION ALL 
SELECT customer.customer_id, staff.staff_id, rental_id, 6.99, NOW()
FROM public.customer, public.staff, public.rental
WHERE customer.customer_id = 21 AND staff.last_name LIKE 'Lockyard' AND rental.inventory_id = 4584
RETURNING payment.payment_id;

-- committed