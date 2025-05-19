# Praktikum 2: Implementasi Transaction

Pada praktikum ini, kita akan mempelajari implementasi transaksi (transaction) pada PostgreSQL dan bagaimana transaksi mempengaruhi konkurensi tinggi.

## Tujuan

1. Memahami konsep ACID dalam transaksi database
2. Mengimplementasikan transaksi pada PostgreSQL
3. Mempelajari tingkat isolasi transaksi
4. Menganalisis fenomena konkurensi seperti dirty read, non-repeatable read, dan phantom read
5. Mengimplementasikan strategi penanganan konkurensi tinggi

## Troubleshoot

1. Jika anda mengalami error duplicate key, anda bisa cek sequence id pada tabel tersebut kemudian reset ke max dari id tabel tersebut

```sql
-- tableName_columnName_seq
SELECT currval('orders_order_id_seq');
-- untuk reset
SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));
```

## Tahapan Praktikum

### 1. Persiapan

1. Pastikan container Docker PostgreSQL sudah berjalan
2. Gunakan pgAdmin atau PSQL untuk mengakses database
3. Pastikan data sudah diimpor menggunakan script yang disediakan

### 2. Memahami Konsep Transaksi

Transaksi adalah unit kerja yang mengubah data dari satu state ke state lainnya. Semua perubahan dalam transaksi harus berhasil secara lengkap, atau tidak ada yang dilakukan (all-or-nothing).

Empat properti ACID:

- **Atomicity** (Atomisitas): Transaksi harus dijalankan sepenuhnya atau dibatalkan sepenuhnya
- **Consistency** (Konsistensi): Transaksi harus menjaga integritas data
- **Isolation** (Isolasi): Transaksi tidak boleh saling mempengaruhi
- **Durability** (Durabilitas): Perubahan yang berhasil harus permanen

### 3. Implementasi Transaksi Dasar

```sql
-- Transaksi dasar
BEGIN;
UPDATE products SET stock_quantity = stock_quantity - 5 WHERE product_id = 1;
INSERT INTO orders (customer_id, status) VALUES (1, 'pending');
COMMIT;

-- Transaksi dengan ROLLBACK
BEGIN;
UPDATE products SET stock_quantity = stock_quantity - 100 WHERE product_id = 1;
-- Oops, stok tidak cukup!
ROLLBACK;
```

### 4. Demonstrasi Tingkat Isolasi Transaksi

PostgreSQL mendukung tingkat isolasi berikut:

- READ UNCOMMITTED (sama dengan READ COMMITTED di PostgreSQL)
- READ COMMITTED (default)
- REPEATABLE READ
- SERIALIZABLE

#### 4.1 READ COMMITTED

Terminal 1:

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE bank_accounts SET balance = balance - 1000000 WHERE account_id = 1;
-- Tunggu beberapa saat sebelum commit
SELECT pg_sleep(30);
COMMIT;
```

Terminal 2:

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Ini akan menampilkan nilai sebelum update di Terminal 1
SELECT * FROM bank_accounts WHERE account_id = 1;
-- Tunggu Terminal 1 commit
SELECT pg_sleep(35);
-- Ini akan menampilkan nilai setelah update di Terminal 1
SELECT * FROM bank_accounts WHERE account_id = 1;
COMMIT;
```

#### 4.2 REPEATABLE READ

Terminal 1:

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM bank_accounts WHERE account_id = 1;
-- Tunggu Terminal 2 melakukan update dan commit
SELECT pg_sleep(30);
-- Ini masih akan menampilkan nilai asli meskipun Terminal 2 sudah commit
SELECT * FROM bank_accounts WHERE account_id = 1;
COMMIT;
```

Terminal 2:

```sql
BEGIN;
UPDATE bank_accounts SET balance = balance - 1000000 WHERE account_id = 1;
COMMIT;
```

#### 4.3 SERIALIZABLE

Terminal 1:

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT SUM(balance) FROM bank_accounts WHERE customer_id = 1;
-- Tunggu Terminal 2 menambahkan account baru
SELECT pg_sleep(30);
-- Ini tidak akan melihat account baru karena isolasi serializable
SELECT SUM(balance) FROM bank_accounts WHERE customer_id = 1;
COMMIT;
```

Terminal 2:

```sql
BEGIN;
INSERT INTO bank_accounts (customer_id, balance)
VALUES (1, 5000000);
COMMIT;
```

### 5. Mengatasi Kondisi Konkurensi Tinggi

#### 5.1 Menggunakan Lock

```sql
-- Row-level lock
BEGIN;
SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
-- Sekarang row ini terkunci hingga transaksi selesai
UPDATE products SET stock_quantity = stock_quantity - 5 WHERE product_id = 1;
COMMIT;

-- Lock pada tingkat tabel
BEGIN;
LOCK TABLE products IN EXCLUSIVE MODE;
-- Operasi pada tabel products
COMMIT;
```

#### 5.2 Optimistic Concurrency Control

```sql
-- Menggunakan last_updated sebagai version control
BEGIN;
SELECT product_id, stock_quantity, last_updated
FROM products WHERE product_id = 1;

-- Asumsikan kita mendapatkan last_updated = '2023-07-15 10:00:00'
UPDATE products
SET stock_quantity = stock_quantity - 5,
    last_updated = CURRENT_TIMESTAMP
WHERE product_id = 1 AND last_updated = '2023-07-15 10:00:00';

-- Jika tidak ada baris yang terupdate, berarti data sudah berubah
-- dan kita harus mengulang transaksi
COMMIT;
```

### 6. Implementasi Function Transfer Uang

```sql
-- Function sudah dibuat di 02-functions.sql
-- Cobalah dari dua terminal berbeda
BEGIN;
SELECT * FROM bank_accounts WHERE account_id IN (1, 2);
SELECT transfer_money(1, 2, 500000);
SELECT * FROM bank_accounts WHERE account_id IN (1, 2);
COMMIT;
```

### 7. Pengujian Konkurensi Tinggi

Menggunakan script benchmark:

```bash
# Di terminal
cd scripts
bash benchmark.sh ../praktikum/praktikum2_transaction/transfer_money.sql 20 100 10
```

## Tugas

1. Implementasikan sistem pemesanan produk dengan transaksi yang:

   - Mengurangi stok produk
   - Membuat pesanan baru
   - Menambahkan item pesanan
   - Memastikan stok mencukupi
   - Harus ACID-compliant

2. Implementasikan dua strategi konkurensi berbeda dan bandingkan performanya:

   - Row-level locking (pessimistic)
   - Optimistic concurrency control

3. Lakukan pengujian konkurensi tinggi (minimal 20 koneksi simultan) dan analisis:

   - Throughput (transactions per second)
   - Deadlock yang terjadi (jika ada)
   - Kesalahan konkurensi lainnya

4. Buat laporan yang menjelaskan bagaimana implementasi transaksi mempengaruhi konkurensi tinggi

## Referensi

- [PostgreSQL Documentation: Transactions](https://www.postgresql.org/docs/current/transaction-iso.html)
- [PostgreSQL: Concurrency Control](https://www.postgresql.org/docs/current/mvcc.html)
- [PostgreSQL: Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
