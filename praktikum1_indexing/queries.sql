-- File: queries.sql untuk Praktikum 1 - Indexing
-- Berisi query-query untuk mengukur performa dengan dan tanpa index

-- Query 1: Filter berdasarkan kategori
SELECT COUNT(*) FROM products WHERE category = 'Elektronik';

-- Query 2: Filter berdasarkan range harga
SELECT * FROM products 
WHERE price BETWEEN 1000000 AND 5000000
LIMIT 100;

-- Query 3: Filter berdasarkan tanggal pesanan
SELECT o.order_id, o.customer_id, o.order_date 
FROM orders o 
WHERE o.order_date BETWEEN '2023-06-01' AND '2023-06-30';

-- Query 4: Join tanpa index
SELECT c.first_name, c.last_name, o.order_id, o.order_date, o.total_amount
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
WHERE c.city = 'Jakarta'
LIMIT 100;

-- Query 5: Aggregate yang berat
SELECT p.category, COUNT(*) as total_products, AVG(p.price) as avg_price
FROM products p
GROUP BY p.category
ORDER BY total_products DESC;
