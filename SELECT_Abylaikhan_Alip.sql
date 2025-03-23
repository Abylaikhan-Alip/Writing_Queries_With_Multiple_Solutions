-- Task 1: Staff with highest revenue per store in 2017
-- Solution 1: Subquery
SELECT 
    s.store_id,
    st.staff_id,
    st.first_name || ' ' || st.last_name AS staff_name,
    SUM(p.amount) AS total_revenue
FROM 
    store s
JOIN 
    staff st ON s.store_id = st.store_id
JOIN 
    payment p ON st.staff_id = p.staff_id
WHERE 
    EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY 
    s.store_id, st.staff_id, st.first_name, st.last_name
HAVING 
    SUM(p.amount) = (
        SELECT SUM(p2.amount)
        FROM payment p2
        JOIN staff st2 ON p2.staff_id = st2.staff_id
        WHERE st2.store_id = s.store_id
        AND EXTRACT(YEAR FROM p2.payment_date) = 2017
        GROUP BY st2.staff_id
        ORDER BY SUM(p2.amount) DESC
        LIMIT 1
    );

-- Solution 2: Window Function
WITH ranked_staff AS (
    SELECT 
        s.store_id,
        st.staff_id,
        st.first_name || ' ' || st.last_name AS staff_name,
        SUM(p.amount) AS total_revenue,
        RANK() OVER (PARTITION BY s.store_id ORDER BY SUM(p.amount) DESC) AS revenue_rank
    FROM 
        store s
    JOIN 
        staff st ON s.store_id = st.store_id
    JOIN 
        payment p ON st.staff_id = p.staff_id
    WHERE 
        EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY 
        s.store_id, st.staff_id, st.first_name, st.last_name
)
SELECT 
    store_id,
    staff_id,
    staff_name,
    total_revenue
FROM 
    ranked_staff
WHERE 
    revenue_rank = 1;

-- Task 2: Top 5 most-rented movies and audience age
-- Solution 1: COUNT
SELECT 
    f.film_id,
    f.title,
    COUNT(r.rental_id) AS rental_count,
    f.rating AS expected_audience_rating
FROM 
    film f
JOIN 
    inventory i ON f.film_id = i.film_id
JOIN 
    rental r ON i.inventory_id = r.inventory_id
GROUP BY 
    f.film_id, f.title, f.rating
ORDER BY 
    rental_count DESC
LIMIT 5;

-- Solution 2: Window Function
WITH ranked_films AS (
    SELECT 
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count,
        f.rating AS expected_audience_rating,
        ROW_NUMBER() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rn
    FROM 
        film f
    JOIN 
        inventory i ON f.film_id = i.film_id
    JOIN 
        rental r ON i.inventory_id = r.inventory_id
    GROUP BY 
        f.film_id, f.title, f.rating
)
SELECT 
    film_id,
    title,
    rental_count,
    expected_audience_rating
FROM 
    ranked_films
WHERE 
    rn <= 5;

-- Task 3: Actors with longest gap between films
-- Solution 1: Self-Join (all pairs)
WITH film_gaps AS (
    SELECT 
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        f1.release_year AS year1,
        f2.release_year AS year2,
        f2.release_year - f1.release_year AS gap
    FROM 
        actor a
    JOIN 
        film_actor fa1 ON a.actor_id = fa1.actor_id
    JOIN 
        film f1 ON fa1.film_id = f1.film_id
    JOIN 
        film_actor fa2 ON a.actor_id = fa2.actor_id
    JOIN 
        film f2 ON fa2.film_id = f2.film_id
    WHERE 
        f2.release_year > f1.release_year
),
max_gaps AS (
    SELECT 
        actor_id,
        actor_name,
        MAX(gap) AS longest_gap
    FROM 
        film_gaps
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    actor_id,
    actor_name,
    longest_gap
FROM 
    max_gaps
WHERE 
    longest_gap = (SELECT MAX(longest_gap) FROM max_gaps);

-- Solution 2: Min/Max Span (adjusted to match Solution 1)
WITH actor_years AS (
    SELECT 
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        MIN(f.release_year) AS first_year,
        MAX(f.release_year) AS last_year
    FROM 
        actor a
    JOIN 
        film_actor fa ON a.actor_id = fa.actor_id
    JOIN 
        film f ON fa.film_id = f.film_id
    GROUP BY 
        a.actor_id, a.first_name, a.last_name
    HAVING 
        COUNT(f.film_id) > 1
),
gaps AS (
    SELECT 
        actor_id,
        actor_name,
        last_year - first_year AS gap
    FROM 
        actor_years
)
SELECT 
    actor_id,
    actor_name,
    gap AS longest_gap
FROM 
    gaps
WHERE 
    gap = (SELECT MAX(gap) FROM gaps);