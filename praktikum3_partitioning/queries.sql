-- File: queries.sql untuk Praktikum 3 - Partitioning
-- Berisi query-query untuk implementasi dan pengujian partitioning

-- ===== IMPLEMENTASI RANGE PARTITIONING =====

-- Buat tabel partisi berdasarkan tanggal order
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

-- Verifikasi distribusi data
SELECT 
    tableoid::regclass AS partition_name,
    count(*) AS row_count
FROM orders_partitioned
GROUP BY tableoid
ORDER BY partition_name;

-- ===== IMPLEMENTASI LIST PARTITIONING =====

-- Buat tabel partisi berdasarkan status order
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

-- Verifikasi distribusi data
SELECT 
    tableoid::regclass AS partition_name,
    count(*) AS row_count
FROM orders_by_status
GROUP BY tableoid
ORDER BY partition_name;

-- ===== IMPLEMENTASI HASH PARTITIONING =====

-- Buat tabel partisi berdasarkan hash dari customer_id
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

-- Verifikasi distribusi data
SELECT 
    tableoid::regclass AS partition_name,
    count(*) AS row_count
FROM orders_by_customer
GROUP BY tableoid
ORDER BY partition_name;

-- ===== IMPLEMENTASI SUBPARTITIONING =====

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

-- Import data untuk Q1 2023
INSERT INTO orders_multi_level
SELECT * FROM orders 
WHERE order_date BETWEEN '2023-01-01' AND '2023-03-31';

-- Buat partisi untuk Q2 2023 dengan subpartisi
CREATE TABLE orders_q2_2023_multi PARTITION OF orders_multi_level
    FOR VALUES FROM ('2023-04-01') TO ('2023-07-01')
    PARTITION BY LIST (status);

-- Subpartisi berdasarkan status untuk Q2 2023
CREATE TABLE orders_q2_2023_pending PARTITION OF orders_q2_2023_multi
    FOR VALUES IN ('pending');

CREATE TABLE orders_q2_2023_processing PARTITION OF orders_q2_2023_multi
    FOR VALUES IN ('processing');

CREATE TABLE orders_q2_2023_shipped PARTITION OF orders_q2_2023_multi
    FOR VALUES IN ('shipped');

CREATE TABLE orders_q2_2023_delivered PARTITION OF orders_q2_2023_multi
    FOR VALUES IN ('delivered');

CREATE TABLE orders_q2_2023_cancelled PARTITION OF orders_q2_2023_multi
    FOR VALUES IN ('cancelled');

-- Import data untuk Q2 2023
INSERT INTO orders_multi_level
SELECT * FROM orders 
WHERE order_date BETWEEN '2023-04-01' AND '2023-06-30';

-- Verifikasi distribusi data
SELECT 
    tableoid::regclass AS partition_name,
    count(*) AS row_count
FROM orders_multi_level
GROUP BY tableoid
ORDER BY partition_name;

-- ===== PENGUJIAN PERFORMA =====

-- Benchmark query pada tabel non-partisi
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30';

-- Benchmark query pada tabel dengan range partitioning
EXPLAIN ANALYZE
SELECT *
FROM orders_partitioned
WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30';

-- Benchmark query pada tabel dengan list partitioning
EXPLAIN ANALYZE
SELECT *
FROM orders_by_status
WHERE status = 'delivered' AND order_date BETWEEN '2023-06-01' AND '2023-06-30';

-- Benchmark query pada tabel dengan subpartitioning
EXPLAIN ANALYZE
SELECT *
FROM orders_multi_level
WHERE status = 'delivered' AND order_date BETWEEN '2023-04-01' AND '2023-06-30';

-- ===== OPERASI MAINTENANCE PARTISI =====

-- Menambahkan partisi baru
CREATE TABLE orders_q1_2024 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

-- Insert data baru ke partisi 2024
INSERT INTO orders_partitioned (customer_id, order_date, status, total_amount, shipping_address, payment_method)
VALUES (1, '2024-01-15', 'pending', 1500000, 'Jl. Contoh No. 123', 'credit_card');

-- Verifikasi data masuk ke partisi yang tepat
SELECT 
    tableoid::regclass AS partition_name,
    count(*) AS row_count
FROM orders_partitioned
GROUP BY tableoid
ORDER BY partition_name;

-- Menghapus data lama dari partisi tertentu
TRUNCATE TABLE orders_q1_2023;

-- Memisahkan (detach) partisi untuk diarsipkan
ALTER TABLE orders_partitioned DETACH PARTITION orders_q1_2023;

-- Verifikasi partisi yang tersisa
SELECT 
    tableoid::regclass AS partition_name,
    count(*) AS row_count
FROM orders_partitioned
GROUP BY tableoid
ORDER BY partition_name;

-- ===== CONTOH FUNCTION UNTUK MAINTENANCE OTOMATIS =====

-- Function untuk membuat partisi baru secara otomatis
CREATE OR REPLACE FUNCTION create_new_quarter_partition()
RETURNS void AS $$
DECLARE
    next_quarter_start DATE;
    next_quarter_end DATE;
    partition_name TEXT;
BEGIN
    -- Tentukan tanggal awal dan akhir kuartal berikutnya
    SELECT 
        DATE_TRUNC('quarter', NOW()) + INTERVAL '3 months' INTO next_quarter_start;
    
    SELECT 
        DATE_TRUNC('quarter', NOW()) + INTERVAL '6 months' INTO next_quarter_end;
    
    partition_name := 'orders_q' || 
                     EXTRACT(QUARTER FROM next_quarter_start) || 
                     '_' || 
                     EXTRACT(YEAR FROM next_quarter_start);
    
    -- Buat statement SQL untuk membuat partisi baru
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I PARTITION OF orders_partitioned
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, next_quarter_start, next_quarter_end);
    
    RAISE NOTICE 'Created new partition % for quarter starting % and ending %', 
                 partition_name, next_quarter_start, next_quarter_end;
END;
$$ LANGUAGE plpgsql;

-- Function untuk mengarsipkan partisi lama
CREATE OR REPLACE FUNCTION archive_old_quarter_partition()
RETURNS void AS $$
DECLARE
    old_quarter_start DATE;
    old_quarter_end DATE;
    partition_name TEXT;
BEGIN
    -- Tentukan tanggal awal dan akhir kuartal yang sudah lama (1 tahun ke belakang)
    SELECT 
        DATE_TRUNC('quarter', NOW() - INTERVAL '1 year') INTO old_quarter_start;
    
    SELECT 
        DATE_TRUNC('quarter', NOW() - INTERVAL '1 year') + INTERVAL '3 months' INTO old_quarter_end;
    
    partition_name := 'orders_q' || 
                     EXTRACT(QUARTER FROM old_quarter_start) || 
                     '_' || 
                     EXTRACT(YEAR FROM old_quarter_start);
    
    -- Detach partisi lama
    EXECUTE format('
        ALTER TABLE orders_partitioned DETACH PARTITION IF EXISTS %I
    ', partition_name);
    
    RAISE NOTICE 'Detached old partition % for quarter starting % and ending %', 
                 partition_name, old_quarter_start, old_quarter_end;
    
    -- Disini bisa ditambahkan kode untuk memindahkan data ke archive storage
END;
$$ LANGUAGE plpgsql;

-- Jalankan function untuk membuat partisi baru
SELECT create_new_quarter_partition();

-- Jalankan function untuk mengarsipkan partisi lama
SELECT archive_old_quarter_partition();
