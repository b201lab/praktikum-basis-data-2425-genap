# Praktikum 3: Implementasi Partitioning

Pada praktikum ini, kita akan mempelajari implementasi partitioning pada PostgreSQL dan bagaimana teknik ini mempengaruhi performa dan skalabilitas database.

## Tujuan

1. Memahami konsep partitioning pada database
2. Mengimplementasikan berbagai tipe partitioning pada PostgreSQL
3. Menganalisis dampak partitioning terhadap performa query
4. Mempelajari strategi partitioning yang tepat untuk berbagai jenis data

## Tahapan Praktikum

### 1. Persiapan

1. Pastikan container Docker PostgreSQL sudah berjalan
2. Gunakan pgAdmin atau PSQL untuk mengakses database
3. Pastikan data sudah diimpor menggunakan script yang disediakan

### 2. Konsep Partitioning

Partitioning adalah teknik untuk membagi tabel besar menjadi beberapa bagian yang lebih kecil secara fisik, tetapi tetap terlihat sebagai satu tabel secara logis. Manfaat partitioning:

- Meningkatkan performa query yang hanya mengakses subset data
- Mempermudah maintenance (backup, restore, delete) data yang jarang diakses
- Mendistribusikan beban I/O ke beberapa disk fisik

PostgreSQL mendukung beberapa tipe partitioning:
- Range Partitioning: Berdasarkan rentang nilai
- List Partitioning: Berdasarkan daftar nilai diskrit
- Hash Partitioning: Berdasarkan hasil fungsi hash

### 3. Implementasi Range Partitioning

Membuat tabel partisi berdasarkan tanggal pada tabel orders:

```sql
-- Buat tabel induk dengan deklarasi partisi
CREATE TABLE orders_partitioned (
    order_id SERIAL,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(12, 2),
    shipping_address TEXT,
    payment_method VARCHAR(50),
    PRIMARY KEY (order_id, order_date),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
) PARTITION BY RANGE (order_date);

-- Buat partisi untuk setiap kuartal tahun 2023
CREATE TABLE orders_q1_2023 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2023-04-01');

CREATE TABLE orders_q2_2023 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2023-04-01') TO ('2023-07-01');

CREATE TABLE orders_q3_2023 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2023-07-01') TO ('2023-10-01');

CREATE TABLE orders_q4_2023 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2023-10-01') TO ('2024-01-01');

-- Import data dari tabel orders asli
INSERT INTO orders_partitioned
SELECT * FROM orders;
```

### 4. Implementasi List Partitioning

Membuat tabel partisi berdasarkan status pesanan:

```sql
-- Buat tabel induk dengan deklarasi partisi
CREATE TABLE orders_by_status (
    order_id SERIAL,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL,
    total_amount DECIMAL(12, 2),
    shipping_address TEXT,
    payment_method VARCHAR(50),
    PRIMARY KEY (order_id, status)
) PARTITION BY LIST (status);

-- Buat partisi untuk setiap status
CREATE TABLE orders_pending PARTITION OF orders_by_status
    FOR VALUES IN ('pending');

CREATE TABLE orders_processing PARTITION OF orders_by_status
    FOR VALUES IN ('processing');

CREATE TABLE orders_shipped PARTITION OF orders_by_status
    FOR VALUES IN ('shipped');

CREATE TABLE orders_delivered PARTITION OF orders_by_status
    FOR VALUES IN ('delivered');

CREATE TABLE orders_cancelled PARTITION OF orders_by_status
    FOR VALUES IN ('cancelled');

-- Import data dari tabel orders asli
INSERT INTO orders_by_status
SELECT * FROM orders;
```

### 5. Implementasi Hash Partitioning

Membuat tabel partisi berdasarkan hash dari customer_id:

```sql
-- Buat tabel induk dengan deklarasi partisi
CREATE TABLE orders_by_customer (
    order_id SERIAL,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(12, 2),
    shipping_address TEXT,
    payment_method VARCHAR(50),
    PRIMARY KEY (order_id, customer_id),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
) PARTITION BY HASH (customer_id);

-- Buat 4 partisi
CREATE TABLE orders_by_customer_0 PARTITION OF orders_by_customer
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE orders_by_customer_1 PARTITION OF orders_by_customer
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE orders_by_customer_2 PARTITION OF orders_by_customer
    FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE orders_by_customer_3 PARTITION OF orders_by_customer
    FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- Import data dari tabel orders asli
INSERT INTO orders_by_customer
SELECT * FROM orders;
```

### 6. Menganalisis Performa Partitioning

#### 6.1 Query pada Tabel Non-Partisi vs Partisi

```sql
-- Query pada tabel non-partisi
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30';

-- Query pada tabel dengan partisi range
EXPLAIN ANALYZE
SELECT *
FROM orders_partitioned
WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30';
```

#### 6.2 Maintenance Partisi

```sql
-- Menambahkan partisi baru untuk tahun 2024
CREATE TABLE orders_q1_2024 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

-- Menghapus data lama dari partisi tertentu
TRUNCATE TABLE orders_q1_2023;

-- Mengarsipkan partisi lama
ALTER TABLE orders_partitioned DETACH PARTITION orders_q1_2023;
-- Sekarang orders_q1_2023 adalah tabel mandiri yang dapat diarchive
```

### 7. Subpartitioning (Multi-level Partitioning)

```sql
-- Buat tabel induk dengan deklarasi partisi bertingkat
CREATE TABLE orders_multi_level (
    order_id SERIAL,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL,
    total_amount DECIMAL(12, 2),
    shipping_address TEXT,
    payment_method VARCHAR(50),
    PRIMARY KEY (order_id, order_date, status)
) PARTITION BY RANGE (order_date);

-- Buat partisi kuartal, yang juga akan dipartisi lagi
CREATE TABLE orders_q1_2023_multi PARTITION OF orders_multi_level
    FOR VALUES FROM ('2023-01-01') TO ('2023-04-01')
    PARTITION BY LIST (status);

-- Subpartisi berdasarkan status untuk Q1 2023
CREATE TABLE orders_q1_2023_pending PARTITION OF orders_q1_2023_multi
    FOR VALUES IN ('pending');

CREATE TABLE orders_q1_2023_processing PARTITION OF orders_q1_2023_multi
    FOR VALUES IN ('processing');

CREATE TABLE orders_q1_2023_shipped PARTITION OF orders_q1_2023_multi
    FOR VALUES IN ('shipped');

CREATE TABLE orders_q1_2023_delivered PARTITION OF orders_q1_2023_multi
    FOR VALUES IN ('delivered');

CREATE TABLE orders_q1_2023_cancelled PARTITION OF orders_q1_2023_multi
    FOR VALUES IN ('cancelled');

-- Import data
INSERT INTO orders_multi_level
SELECT * FROM orders 
WHERE order_date BETWEEN '2023-01-01' AND '2023-03-31';
```

## Tugas Modul

1. Implementasikan partitioning pada salah satu tabel besar (orders atau products)
2. Bandingkan performa query antara tabel non-partisi dan tabel dengan partisi untuk:
   - Query yang mengakses satu partisi
   - Query yang mengakses beberapa partisi
   - Query yang mengakses seluruh tabel

3. Implementasikan minimal dua tipe partitioning berbeda (Range, List, atau Hash)
4. Buat script untuk maintenance partisi secara otomatis:
   - Menambahkan partisi baru secara otomatis
   - Mengarsipkan partisi lama

5. Lakukan benchmark konkuren dan bandingkan throughput pada tabel dengan dan tanpa partisi

## Referensi

- [PostgreSQL Documentation: Table Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)
- [PostgreSQL: Declarative Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITIONING-DECLARATIVE)
- [PostgreSQL Wiki: Partitioning](https://wiki.postgresql.org/wiki/Table_partitioning)
