-- File: queries.sql untuk Praktikum 2 - Transaction
-- Berisi query-query untuk pengujian transaksi dan konkurensi

-- ===== TRANSAKSI DASAR =====

-- Transaksi sederhana
BEGIN;
UPDATE products SET stock_quantity = stock_quantity - 5 WHERE product_id = 1;
INSERT INTO orders (customer_id, status) VALUES (1, 'pending') RETURNING order_id;
-- Asumsikan order_id yang dikembalikan = 20001
INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT 20001, 1, 5, price FROM products WHERE product_id = 1;
COMMIT;

-- Transaksi dengan rollback
BEGIN;
UPDATE products SET stock_quantity = stock_quantity - 1000 WHERE product_id = 1;
-- Cek stok setelah update
SELECT stock_quantity FROM products WHERE product_id = 1;
-- Misalkan stok menjadi negatif, kita rollback
ROLLBACK;
-- Verifikasi stok kembali seperti semula
SELECT stock_quantity FROM products WHERE product_id = 1;

-- ===== PENGUJIAN TINGKAT ISOLASI =====

-- READ COMMITTED (default PostgreSQL)
-- Terminal 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM bank_accounts WHERE account_id = 1;
UPDATE bank_accounts SET balance = balance - 1000000 WHERE account_id = 1;
-- Tunggu 30 detik dengan pg_sleep atau pindah ke Terminal 2
SELECT pg_sleep(30);
COMMIT;

-- Terminal 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Baca saldo sebelum Terminal 1 commit
SELECT balance FROM bank_accounts WHERE account_id = 1;
-- Tunggu Terminal 1 commit
SELECT pg_sleep(35);
-- Baca saldo setelah Terminal 1 commit - akan melihat perubahan
SELECT balance FROM bank_accounts WHERE account_id = 1;
COMMIT;

-- REPEATABLE READ
-- Terminal 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM bank_accounts WHERE account_id = 1;
-- Tunggu Terminal 2 update dan commit
SELECT pg_sleep(30);
-- Tetap melihat saldo awal karena repeatable read
SELECT balance FROM bank_accounts WHERE account_id = 1;
COMMIT;

-- Terminal 2:
BEGIN;
UPDATE bank_accounts SET balance = balance - 1000000 WHERE account_id = 1;
COMMIT;
-- Cek saldo setelah commit
SELECT balance FROM bank_accounts WHERE account_id = 1;

-- SERIALIZABLE
-- Terminal 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT SUM(balance) FROM bank_accounts WHERE customer_id = 1;
-- Tunggu Terminal 2 menambahkan rekening baru
SELECT pg_sleep(30);
-- Ini tetap tidak melihat rekening baru
SELECT SUM(balance) FROM bank_accounts WHERE customer_id = 1;
COMMIT;

-- Terminal 2:
BEGIN;
INSERT INTO bank_accounts (customer_id, balance) 
VALUES (1, 5000000);
COMMIT;
-- Verifikasi rekening baru
SELECT * FROM bank_accounts WHERE customer_id = 1;

-- ===== PENANGANAN KONKURENSI =====

-- Row-level lock
BEGIN;
-- Lock baris dengan FOR UPDATE
SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
-- Sekarang baris ini dikunci hingga transaksi selesai
UPDATE products SET stock_quantity = stock_quantity - 5 WHERE product_id = 1;
COMMIT;

-- Table lock
BEGIN;
-- Lock seluruh tabel
LOCK TABLE products IN EXCLUSIVE MODE;
-- Operasi pada tabel products
UPDATE products SET last_updated = CURRENT_TIMESTAMP;
COMMIT;

-- Optimistic concurrency control
BEGIN;
-- Ambil data produk beserta timestamp terakhir
SELECT product_id, stock_quantity, last_updated 
FROM products WHERE product_id = 1;
-- Misalnya kita mendapatkan last_updated = '2023-07-15 10:00:00'
-- Lakukan update dengan kondisi timestamp
UPDATE products 
SET stock_quantity = stock_quantity - 5,
    last_updated = CURRENT_TIMESTAMP
WHERE product_id = 1 
  AND last_updated = '2023-07-15 10:00:00';
  
-- Cek apakah update berhasil (affected rows > 0)
-- Jika tidak berhasil, berarti data sudah berubah dan perlu retry
GET DIAGNOSTICS affected_rows = ROW_COUNT;
IF affected_rows = 0 THEN
    ROLLBACK;
    -- Logic untuk retry atau error handling
ELSE
    COMMIT;
END IF;

-- ===== STUDI KASUS: TRANSFER UANG =====

-- Function transfer_money sudah dibuat di 02-functions.sql
-- Pengujian dari dua terminal berbeda

-- Terminal 1:
BEGIN;
-- Cek saldo sebelum transfer
SELECT * FROM bank_accounts WHERE account_id IN (1, 2);
-- Transfer 1 juta dari rekening 1 ke rekening 2
SELECT transfer_money(1, 2, 1000000);
-- Cek saldo setelah transfer
SELECT * FROM bank_accounts WHERE account_id IN (1, 2);
COMMIT;

-- Terminal 2 (jalankan bersamaan):
BEGIN;
-- Transfer 500 ribu dari rekening 2 ke rekening 3
SELECT transfer_money(2, 3, 500000);
COMMIT;

-- ===== STUDI KASUS: PEMESANAN PRODUK =====

-- Prosedur pemesanan produk dengan transaksi
CREATE OR REPLACE FUNCTION create_order(
    p_customer_id INT,
    p_product_id INT,
    p_quantity INT
) RETURNS INT AS $$
DECLARE
    v_order_id INT;
    v_available_stock INT;
    v_product_price DECIMAL(10, 2);
BEGIN
    -- Cek stok produk
    SELECT stock_quantity, price INTO v_available_stock, v_product_price
    FROM products
    WHERE product_id = p_product_id
    FOR UPDATE; -- Lock baris untuk menghindari race condition
    
    IF v_available_stock < p_quantity THEN
        RAISE EXCEPTION 'Stok tidak mencukupi: tersedia % unit, diminta % unit',
                        v_available_stock, p_quantity;
    END IF;
    
    -- Kurangi stok
    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity,
        last_updated = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    -- Buat order baru
    INSERT INTO orders (customer_id, status, total_amount)
    VALUES (p_customer_id, 'pending', p_quantity * v_product_price)
    RETURNING order_id INTO v_order_id;
    
    -- Tambahkan item pesanan
    INSERT INTO order_items (order_id, product_id, quantity, price)
    VALUES (v_order_id, p_product_id, p_quantity, v_product_price);
    
    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- Pengujian fungsi create_order
BEGIN;
SELECT create_order(1, 5, 3);
COMMIT;

-- ===== CONTOH DEADLOCK =====

-- Buat tabel untuk demonstrasi deadlock
CREATE TABLE IF NOT EXISTS accounts_test (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    balance DECIMAL(15, 2)
);

-- Isi dengan data dummy
INSERT INTO accounts_test VALUES 
(1, 'Account A', 1000000),
(2, 'Account B', 2000000);

-- Terminal 1:
BEGIN;
UPDATE accounts_test SET balance = balance - 500000 WHERE id = 1;
-- Tunggu sebentar
SELECT pg_sleep(5);
-- Update baris kedua - potensi deadlock
UPDATE accounts_test SET balance = balance + 500000 WHERE id = 2;
COMMIT;

-- Terminal 2:
BEGIN;
UPDATE accounts_test SET balance = balance - 300000 WHERE id = 2;
-- Tunggu sebentar
SELECT pg_sleep(5);
-- Update baris pertama - akan menyebabkan deadlock
UPDATE accounts_test SET balance = balance + 300000 WHERE id = 1;
COMMIT;

-- ===== PENCEGAHAN DEADLOCK =====

-- Menggunakan urutan update yang konsisten
-- Terminal 1:
BEGIN;
-- Selalu update ID yang lebih kecil dulu
SELECT * FROM accounts_test ORDER BY id FOR UPDATE;
UPDATE accounts_test SET balance = balance - 500000 WHERE id = 1;
UPDATE accounts_test SET balance = balance + 500000 WHERE id = 2;
COMMIT;

-- Terminal 2:
BEGIN;
-- Juga update ID yang lebih kecil dulu
SELECT * FROM accounts_test ORDER BY id FOR UPDATE;
UPDATE accounts_test SET balance = balance - 300000 WHERE id = 2;
UPDATE accounts_test SET balance = balance + 300000 WHERE id = 1;
COMMIT;
