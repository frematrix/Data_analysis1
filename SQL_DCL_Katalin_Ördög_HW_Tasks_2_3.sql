
-- Task 2. Implement role-based authentication model for dvd_rental database
 
/*2.1. Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to 
 * connect to the database but no other permissions.*/
CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';

--ALTER USER rentaluser WITH LOGIN; 
/* The LOGIN privilege is automatically included when you use CREATE ROLE ... LOGIN. There is no need to explicitly use 
 * ALTER USER ... WITH LOGIN after creating the role with the LOGIN option.
 */

-- Grant "rentaluser" SELECT permission for the "customer" table. 
GRANT SELECT ON public.customer TO rentaluser;

-- 2.2. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
SELECT current_role;--postgres
SET ROLE rentaluser;

SELECT *
FROM public.customer c;
/* Test: 
SELECT *
FROM public.actor a;--ERROR: permission denied for table actor*/

-- 2.3. Create a new user group called "rental" and add "rentaluser" to the group. 
SET ROLE postgres;
CREATE ROLE rental;
GRANT rental TO rentaluser;


--magamnak: https://docs.starrocks.io/en-us/3.0/sql-reference/sql-statements/account-management/SET%20ROLE
-- Typically a role being used as a group would not have the LOGIN attribute, though you can set it if you wish.
-- Once the group role exists, you can add and remove members using the GRANT and REVOKE commands:
-- GRANT group_role TO role1, ... ;
-- REVOKE group_role FROM role1, ... ;


/* 2.4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one 
 * existing row in the "rental" table under that role.*/
GRANT SELECT, INSERT, UPDATE ON TABLE public.rental TO rental;
GRANT SELECT ON public.inventory, public.customer, public.staff TO rental;
GRANT USAGE ON SEQUENCE rental_rental_id_seq TO rental;

-- Here I used the INSERT INTO ... SELECT statement, but to avoid hard-coding (using the inventory_id from inventory table)
-- I used the film_id from inventory table but I got 4 new inserted rows because there are 4 inventory_id for 40 film_id.
SET ROLE rental;
INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT new_rental.rental_date, i.inventory_id, c.customer_id, s.staff_id
FROM (SELECT '2005-05-24 12:05:21.000 +0200'::timestamptz AS rental_date, 40 AS rent_inv_filmid, 'BONNIE.HUGHES@sakilacustomer.org'
		AS rent_cust_mail, 'Lockyard' AS rent_staff_lastn) AS new_rental
INNER JOIN public.inventory i
ON new_rental.rent_inv_filmid = i.film_id
INNER JOIN public.customer c
ON new_rental.rent_cust_mail = c.email 
INNER JOIN public.staff s
ON new_rental.rent_staff_lastn = s.last_name 
WHERE new_rental.rental_date NOT IN (SELECT rental_date FROM public.rental)
RETURNING *;

UPDATE public.rental 
SET inventory_id = 42,
	customer_id = 48
WHERE rental_id = 32296;

-- 2.5. Revoke the "rental" group's INSERT permission for the "rental" table.
SET ROLE postgres;
REVOKE INSERT ON public.rental FROM rental;

-- 2.6. Try to insert new rows into the "rental" table make sure this action is denied.
-- SQL Error [42501]: ERROR: permission denied for table rental
INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT new_rental.rental_date, i.inventory_id, c.customer_id, s.staff_id
FROM (SELECT '2005-05-24 12:05:21.000 +0200'::timestamptz AS rental_date, 40 AS rent_inv_filmid, 'BONNIE.HUGHES@sakilacustomer.org'
		AS rent_cust_mail, 'Lockyard' AS rent_staff_lastn) AS new_rental
INNER JOIN public.inventory i
ON new_rental.rent_inv_filmid = i.film_id
INNER JOIN public.customer c
ON new_rental.rent_cust_mail = c.email 
INNER JOIN public.staff s
ON new_rental.rent_staff_lastn = s.last_name 
WHERE new_rental.rental_date NOT IN (SELECT rental_date FROM public.rental)
RETURNING *;

/*2.7. Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name 
 * must be client_{first_name}_{last_name} (omit curly brackets). 
The customer's payment and rental history must not be empty.*/

SET ROLE postgres;

SELECT public.create_customer_role();

CREATE OR REPLACE FUNCTION public.create_customer_role ()
RETURNS void 
LANGUAGE plpgsql
AS $$
DECLARE firstn TEXT;
		lastn TEXT;
		rolename TEXT;
BEGIN
	SELECT first_name, last_name INTO firstn, lastn
	FROM public.customer
	WHERE customer_id IN (SELECT customer_id FROM public.payment)
	AND customer_id IN (SELECT customer_id FROM public.rental)
	AND last_name LIKE '%R%'
	LIMIT 1;

	IF FOUND THEN
		rolename := 'client_' || replace(firstn, ' ', '_') || '_' || replace(lastn, ' ', '_');
	
		IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = rolename) THEN
		EXECUTE 'CREATE ROLE ' || quote_ident(rolename) || ' LOGIN';
	
	    RAISE NOTICE 'Role % created for client % %', rolename, firstn, lastn;
	  ELSE
	    RAISE NOTICE 'Role % is already exists', rolename;
	  END IF;
	ELSE 
		RAISE NOTICE 'Client with R letter and payment, rental history does not exist in the customer table.';
	END IF;
END;
$$;


-- with explanation, to create role for all of the customers who has rental and payment history:
DO $$ 
DECLARE
	customerid int;
    firstname VARCHAR;
    lastname VARCHAR;
    new_role_name VARCHAR;
BEGIN
    -- Declare a cursor for fetching customer_ids:
    FOR customerid IN (SELECT customer_id FROM public.customer) 
    LOOP
	    SELECT first_name, last_name INTO firstname, lastname
	    FROM public.customer
	    WHERE customerid = customer_id;
        -- Check if the customer has payment and rental history
        IF EXISTS (
            SELECT 1
            FROM public.payment
            WHERE customerid = customer_id
        ) AND EXISTS (
            SELECT 1
            FROM public.rental
            WHERE customerid = customer_id
        ) THEN
            -- Create a new role name
            new_role_name := 'client_' || replace(firstname, ' ', '_') || '_' || replace(lastname, ' ', '_');

            -- Create a new role
            EXECUTE 'CREATE ROLE ' || quote_ident(new_role_name) || ' LOGIN';

            RAISE NOTICE 'Role % created for client % %', new_role_name, firstname, lastname;
        ELSE
            RAISE NOTICE 'Skipped creating role for client % % as payment or rental history is empty', firstname, lastname;
        END IF;
    END LOOP;
END $$;


/* Task 3. Implement row-level security
Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. Write a 
query to make sure this user sees only their own data.
 */
SET ROLE postgres;

ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY; 

CREATE VIEW pay_client AS
SELECT *
FROM public.customer c
WHERE c.last_name LIKE '%RIVERA%'
AND c.first_name LIKE '%KATHERINE%';

CREATE POLICY client_KATHERINE_RIVERA ON public.customer USING (true);

GRANT SELECT ON TABLE pay_client TO "client_KATHERINE_RIVERA";

SET ROLE "client_KATHERINE_RIVERA";
SELECT * FROM pay_client;

SET ROLE postgres;
CREATE VIEW rent_client AS
SELECT *
FROM public.rental r 
WHERE r.customer_id IN (SELECT c.customer_id 
						FROM public.customer c 
						WHERE c.last_name LIKE '%RIVERA%'
						AND c.first_name LIKE '%KATHERINE%');
					
CREATE POLICY client_KATHERINE_RIVERA ON public.rental USING (true);

GRANT SELECT ON TABLE rent_client TO "client_KATHERINE_RIVERA";

SET ROLE "client_KATHERINE_RIVERA";

SELECT * FROM rent_client;

SET ROLE postgres;
CREATE VIEW cust_client AS
SELECT *
FROM public.payment p  
WHERE p.customer_id IN (SELECT c.customer_id 
						FROM public.customer c 
						WHERE c.last_name LIKE '%RIVERA%'
						AND c.first_name LIKE '%KATHERINE%');
					
CREATE POLICY client_KATHERINE_RIVERA ON public.payment USING (true);

GRANT SELECT ON TABLE cust_client TO "client_KATHERINE_RIVERA";

SET ROLE "client_KATHERINE_RIVERA";

SELECT * FROM cust_client;

