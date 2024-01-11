CREATE SCHEMA dannys_diner;
use dannys_diner;

CREATE TABLE sales (
customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
select * from  sales;

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id AS customer,
    SUM(m.price) AS price
FROM
    sales AS s
INNER JOIN
    menu AS m ON s.product_id = m.product_id
GROUP BY
    customer; 
-- 2. How many days has each customer visited the restaurant?
SELECT
    customer_id AS customer,
    COUNT(DISTINCT order_date) AS date
FROM
    sales
GROUP BY
    customer;
-- 3. What was the first item from the menu purchased by each customer?
SELECT
    s.customer_id AS customer,
    m.product_name AS first_item,
    s.order_date AS order_date
FROM
    sales AS s
JOIN
    menu AS m ON s.product_id = m.product_id
WHERE
    s.order_date = (SELECT MIN(order_date) FROM sales)
GROUP BY
    s.customer_id;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name as most_purchased , count(s.product_id) as no_of_times_purchased
FROM
    sales AS s
JOIN
    menu AS m ON s.product_id = m.product_id
group by most_purchased
order by no_of_times_purchased desc
limit 1;
    
-- 5. Which item was the most popular for each customer?
-- method 1
select customer_id ,product_name, count(s.product_id) as no_of_times_purchased
FROM
    sales AS s
JOIN
    menu AS m ON s.product_id = m.product_id
    wHERE (
    SELECT COUNT(s.product_id)
    FROM sales AS s2
    WHERE s2.customer_id = s.customer_id
    GROUP BY s2.product_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
) = COUNT(s.product_id)
group by customer_id,product_name;

SELECT
    s.customer_id,
    m.product_name,
    COUNT(s.product_id) AS no_of_times_purchased
FROM
    sales AS s
JOIN
    menu AS m ON s.product_id = m.product_id
GROUP BY
    s.customer_id,
    m.product_name
HAVING
    COUNT(s.product_id) = (
        SELECT COUNT(*)
        FROM sales AS s2
        WHERE s2.customer_id = s.customer_id
        GROUP BY s2.product_id
        ORDER BY COUNT(*) DESC
        LIMIT 1
    );

-- method 2
SELECT customer, product_name, purchase_count
FROM (
    SELECT
        s.customer_id AS customer,
        m.product_name,
        COUNT(*) AS purchase_count,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank_s
    FROM
        sales AS s
    JOIN
        menu AS m ON s.product_id = m.product_id
    GROUP BY
        s.customer_id,
        m.product_name
) AS ranked_data
WHERE rank_s = 1;


-- 6. Which item was purchased first by the customer after they became a member?
-- method 1
SELECT
    s.customer_id,
    m.product_name,
    s.order_date, 
    mem.join_date
FROM
    sales AS s
JOIN
    menu AS m ON s.product_id = m.product_id
JOIN
    members AS mem ON s.customer_id = mem.customer_id
WHERE
    s.order_date >= mem.join_date
    AND s.order_date = (
        SELECT MIN(s2.order_date)
        FROM sales AS s2
        WHERE s2.customer_id = s.customer_id
        AND s2.order_date >= mem.join_date
    )
    order by customer_id;

-- method 2
SELECT
    *
FROM (
    SELECT
        mem.customer_id,
        m.product_name,
        s.order_date,
        mem.join_date,
        RANK() OVER (PARTITION BY mem.customer_id ORDER BY s.order_date) AS purchase_rank
    FROM
        sales AS s
    JOIN
        menu AS m ON s.product_id = m.product_id
    JOIN
        members AS mem ON s.customer_id = mem.customer_id
    WHERE
        s.order_date >= mem.join_date
) AS ranked_purchases
WHERE
    purchase_rank = 1;

-- 7. Which item was purchased just before the customer became a member?

 SELECT *
FROM (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        dense_rank() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS purchase_rank
    FROM
        sales AS s
    JOIN
        menu AS m ON s.product_id = m.product_id
    JOIN
        members AS mem ON s.customer_id = mem.customer_id
    WHERE
        s.order_date < mem.join_date
) AS ranked_purchases
WHERE
    purchase_rank = 1;
   
-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id,
	count( m.product_name) as total_item, 
    sum(m.price) as total_price
 FROM
        sales AS s
    JOIN
        menu AS m ON s.product_id = m.product_id
	JOIN 
		members AS mem ON s.customer_id = mem.customer_id
	where
    s.order_date < mem.join_date
	group by customer_id
    order by customer_id;
    

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id AS customer,
    SUM(CASE
               WHEN product_name = 'sushi' THEN price*20
               ELSE price*10
           END) AS customer_points
FROM
    sales AS s
JOIN
    menu AS m ON s.product_id = m.product_id
GROUP BY
    customer;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH date_cte AS
(
  SELECT *,
 DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date, -- adds 6 days to the join date to make it 1 week
  last_day('2021-01-31') AS month_end
  FROM members
)

  SELECT 
    s.customer_id,
    d.join_date,
    d.valid_date,
    SUM(m.price) AS total_spent,
    SUM(CASE 
      WHEN s.order_date <= d.valid_date THEN (2 * 10 * m.price)
      ELSE 10 * m.price
      END) AS points

  FROM date_cte as d
  JOIN sales as s
  ON d.customer_id = s.customer_id
  JOIN menu as m
  ON s.product_id = m.product_id
  WHERE s.order_date < d.month_end
  GROUP BY s.customer_id, d.join_date, d.valid_date;


 


