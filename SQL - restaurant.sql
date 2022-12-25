-- You're an restaurant owner. Create at least 5 tables (1x fact and 4x dimension)
-- and write SQL 3 queries and 1 subquery/WITH clause to analyze the data.

-- enable foreign key constraint
PRAGMA foreign_keys = ON;

/*
  Dimension table
*/

CREATE TABLE employees (
  employee_id INT PRIMARY KEY,
  name TEXT,
  position TEXT
);

INSERT INTO employees VALUES
  (1, 'Arun', 'Manager'),
  (2, 'Anong', 'chef'),
  (3, 'Somchai', 'chef'),
  (4, 'Ti', 'waiter'),
  (5, 'Rung', 'waiter');

------------------------------------

CREATE TABLE menus (
  menu_id INT PRIMARY KEY,
  name TEXT,
  price INT
);

INSERT INTO menus VALUES
  (1, 'Pork noodle', 50),
  (2, 'Chicken noodle', 45),
  (3, 'Duck noodle', 50);

------------------------------------

CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  name TEXT,
  location TEXT
);

INSERT INTO customers VALUES
  (1, 'Wattana', 'Bangkok'),
  (2, 'Mongkut', 'Nonthaburi'),
  (3, 'Ubon', 'Bangkok'),
  (4, 'Samut', 'Bangkok'),
  (5, 'Fai', 'Nonthaburi');

------------------------------------

CREATE TABLE orderTypes (
  order_type_id INT PRIMARY KEY,
  name TEXT
);

INSERT INTO orderTypes VALUES
  (1, 'Restaurant'),
  (2, 'Takeout'),
  (3, 'Delivery');

/*
  Fact table
*/

CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  order_date TEXT,
  order_type_id INT REFERENCES orderTypes (order_type_id),
  waiter_id INT REFERENCES employees (employee_id),
  customer_id INT REFERENCES customers (customer_id),
  menu_id INT REFERENCES menus (menu_id),
  amount INT
);

INSERT INTO orders VALUES
  (1, '2022-08-01', 1, 4, 1, 1, 1),
  (2, '2022-08-01', 1, 5, 1, 2, 1),
  (3, '2022-08-02', 1, 4, 2, 2, 1),
  (4, '2022-08-02', 3, NULL, 1, 3, 2),
  (5, '2022-08-02', 2, NULL, 3, 1, 1),
  (6, '2022-08-02', 2, NULL, 4, 2, 1),
  (7, '2022-08-03', 3, NULL, 2, 3, 1),
  (8, '2022-08-03', 3, NULL, 2, 2, 2),
  (9, '2022-08-03', 1, 5, 5, 2, 2),
  (10, '2022-08-03', 1, 4, 3, 1, 1),
  (11, '2022-08-03', 2, NULL, 3, 2, 1);

/*
  SQLite command
*/
.mode markdown
.header on

/*
  Querying data
*/

CREATE VIEW orderValues AS
  SELECT
    *,
    m.price * ord.amount AS 'order_value'
  FROM orders AS ord
  JOIN menus AS m USING(menu_id);

-- What is the best selling menu?
SELECT
  m.name AS menu,
  SUM(ord.amount) AS total_amount,
  ROUND(AVG(ord.amount), 2) AS 'avg. amount per order'
FROM orderValues AS ord
JOIN menus AS m USING(menu_id)
GROUP BY m.name
ORDER BY SUM(ord.amount) DESC;

-- What is the popular channel of distribution?
SELECT
  ort.name AS type,
  COUNT(*) AS total_order,
  ROUND(AVG(ord.order_value), 2) AS 'avg. value per order'
FROM orderValues AS ord
JOIN orderTypes AS ort USING(order_type_id)
JOIN menus AS m USING(menu_id)
GROUP BY 1
ORDER BY 2 DESC;

-- What is the popular menu of customers in Bangkok?
SELECT
  m.name AS menu,
  SUM(ord.amount) AS total_amount
FROM orderValues AS ord
JOIN menus AS m USING(menu_id)
JOIN customers AS cust USING(customer_id)
WHERE cust.location = 'Bangkok'
GROUP BY 1
ORDER BY 2 DESC;

-- What is the selling trend of each menu?
WITH allDates AS (
  SELECT
    ord.order_date
  FROM orders AS ord
  GROUP BY 1
)

SELECT
  m.name AS menu,
  dt.order_date AS 'date',
  COALESCE(SUM(ord.amount), 0) AS amount
FROM menus AS m, allDates AS dt
LEFT JOIN orders AS ord
  ON m.menu_id = ord.menu_id
    AND dt.order_date = ord.order_date
GROUP BY 1, 2
ORDER BY 1, 2;
