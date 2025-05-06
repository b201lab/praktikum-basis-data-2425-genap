# Praktikum 1: Implementasi Indexing

Pada praktikum ini, kita akan mempelajari implementasi indexing pada PostgreSQL dan dampaknya pada performa query, terutama dalam lingkungan konkuren.

## Tujuan

1. Memahami konsep indexing pada database
2. Mempelajari tipe-tipe index di PostgreSQL
3. Mengimplementasikan index yang tepat untuk berbagai skenario query
4. Menganalisis dampak index terhadap performa query konkuren

## Tahapan Praktikum

### 1. Persiapan

1. Pastikan container Docker PostgreSQL sudah berjalan
2. Pastikan data sudah diimpor menggunakan script yang disediakan
3. Anda perlu akses shell container untuk dan copy script serta file .sql kedalam container.

Berikut docker command yang diperlukan.

```bash
# Mencari ID / nama container PostgreSQL
docker ps

#Akses Shell container
docker exec -it [container_id_atau_nama] bash

# Akses PostgreSQL CLI (psql)
psql -U [username] -d [database_name]

#Salin file ke docker
docker cp /path/to/your/local/yourFile [container_id_atau_nama]:/pathDiContainer/
```

### 2. Mengeksplorasi Execution Plan

Pertama, Anda akan mempelajari cara melihat execution plan query menggunakan EXPLAIN dan EXPLAIN ANALYZE:

```sql
-- Menampilkan execution plan
EXPLAIN SELECT * FROM products WHERE category = 'Elektronik';

-- Menampilkan execution plan beserta runtime
EXPLAIN ANALYZE SELECT * FROM products WHERE category = 'Elektronik';
```

### 3. Mengukur Performa Query Tanpa Index

1. Jalankan query berikut tanpa index dan catat waktu eksekusinya:

```sql
-- Query 1: Filter berdasarkan kategori
SELECT COUNT(*) FROM products WHERE category = 'Elektronik';

-- Query 2: Filter berdasarkan range harga
SELECT * FROM products WHERE price BETWEEN 1000000 AND 5000000;

-- Query 3: Filter berdasarkan tanggal pesanan
SELECT o.order_id, o.customer_id, o.order_date
FROM orders o
WHERE o.order_date BETWEEN '2023-06-01' AND '2023-06-30';

-- Query 4: Join tanpa index
SELECT c.first_name, c.last_name, o.order_id, o.order_date, o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.city = 'Jakarta';

-- Query 5: Aggregate yang berat
SELECT p.category, COUNT(*) as total_products, AVG(p.price) as avg_price
FROM products p
GROUP BY p.category
ORDER BY total_products DESC;
```

2. Lakukan benchmark konkuren tanpa index:

```bash
# Command
cd toYourPath
bash benchmark.sh queries.sql 20 100 10
```

### 4. Implementasi Drop and Create Index yang Tepat

```sql
-- Hapus index yang sudah ada (untuk tujuan menguji kembali tanpa index)
DROP INDEX IF EXISTS idx_products_category;
DROP INDEX IF EXISTS idx_products_price;
DROP INDEX IF EXISTS idx_orders_date;
DROP INDEX IF EXISTS idx_customers_city;
```

Menambahkan index yang sesuai untuk setiap query:

```sql
-- Index 1: B-Tree index untuk kategori produk
CREATE INDEX idx_products_category ON products(category);

-- Index 2: B-Tree index untuk range harga
CREATE INDEX idx_products_price ON products(price);

-- Index 3: B-Tree index untuk tanggal pesanan
CREATE INDEX idx_orders_date ON orders(order_date);

-- Index 4: Index untuk city pada tabel customers
CREATE INDEX idx_customers_city ON customers(city);

-- Index 5: Composite index untuk JOIN operation
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
```

### 5. Mengukur Performa Setelah Indexing

1. Jalankan kembali query EXPLAIN yang sama dan bandingkan waktu eksekusinya:

```sql
-- Menampilkan execution plan
EXPLAIN SELECT * FROM products WHERE category = 'Elektronik';

-- Menampilkan execution plan beserta runtime
EXPLAIN ANALYZE SELECT * FROM products WHERE category = 'Elektronik';

-- bisa uji coba query lainnya
```

2. Lakukan benchmark konkuren dengan index:

```bash
# Di terminal
cd toYourPath
bash benchmark.sh queries.sql 20 100 10
```

### 6. Mempelajari Tipe Index Lain

PostgreSQL mendukung beberapa tipe index. Cobalah implementasi berikut:

```sql
-- Index Partial untuk produk dengan stok rendah
CREATE INDEX idx_products_low_stock ON products(product_id, stock_quantity)
WHERE stock_quantity < 10;

-- Index menggunakan ekspresi untuk pencarian case-insensitive
CREATE INDEX idx_products_name_lower ON products(LOWER(name));

-- BRIN Index untuk data berurutan (seperti timestamp)
CREATE INDEX idx_orders_date_brin ON orders USING BRIN(order_date);

-- GIN Index untuk pencarian full-text (jika menggunakan PostgreSQL >= 9.6)
CREATE INDEX idx_products_description_gin ON products
USING GIN(to_tsvector('english', description));
```

## Tugas

1. Bandingkan performa dengan dan tanpa index untuk setiap query
2. Analisis execution plan dan jelaskan perbedaannya
3. Implementasikan minimal 2 tipe index berbeda dan bandingkan performanya
4. Lakukan benchmark konkuren dan bandingkan throughput (transactions per second)
5. Buat laporan yang menjelaskan dampak index terhadap performa, terutama dalam lingkungan konkuren

## Pertanyaan Diskusi

1. Apakah selalu lebih baik menggunakan index? Jelaskan kelebihan dan kekurangannya!
2. Tipe index apa yang paling cocok untuk kolom yang sering diupdate?
3. Bagaimana strategi indexing yang tepat untuk database dengan operasi insert yang sangat tinggi?
4. Apakah komposit index selalu lebih baik daripada multiple single-column index? Jelaskan alasannya!
5. Bagaimana index mempengaruhi konkurensi pada database?

## Referensi

- [PostgreSQL Documentation: Indexes](https://www.postgresql.org/docs/current/indexes.html)
- [Use The Index, Luke!](https://use-the-index-luke.com/)
- [PostgreSQL: Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
