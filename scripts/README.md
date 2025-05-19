# Scripts untuk Praktikum Basis Data

Direktori ini berisi script untuk membantu praktikum basis data dengan studi kasus ACID dan High Concurrency di PostgreSQL.

## Daftar Script

1. **generate_data.py**: Script untuk menghasilkan data dummy
2. **import_data.sh**: Script untuk mengimpor data CSV ke PostgreSQL
3. **benchmark.sh**: Script untuk benchmark performa query

## Cara Penggunaan

### 1. Generate Data

Menghasilkan data dummy dalam format CSV untuk database e-commerce.

```bash
# Pastikan Python 3 dan pip telah terinstall
pip install faker
python generate_data.py
```

Ini akan membuat file CSV di direktori `../data/`:
- products.csv (10.000 produk)
- customers.csv (5.000 pelanggan)
- orders.csv (20.000 pesanan)
- order_items.csv (50.000 item pesanan)
- bank_accounts.csv (5.000 rekening bank)

### 2. Import Data

Mengimpor data CSV ke dalam database PostgreSQL.

```bash
# Pastikan PostgreSQL client terinstall
# Untuk Windows, gunakan Git Bash atau WSL
bash import_data.sh
```

### 3. Benchmark Performa

Menjalankan benchmark performa untuk query tertentu.

```bash
# Untuk penggunaan di Windows, gunakan Git Bash atau WSL
bash benchmark.sh <file_query> [jumlah_koneksi] [jumlah_transaksi] [jumlah_thread]

# Contoh:
bash benchmark.sh ../praktikum/praktikum1_indexing/query_before.sql 20 1000 8
```

Parameter:
- `file_query`: Path ke file SQL yang berisi query untuk benchmark
- `jumlah_koneksi`: Jumlah koneksi simultan (default: 10)
- `jumlah_transaksi`: Jumlah transaksi per koneksi (default: 1000)
- `jumlah_thread`: Jumlah thread client (default: 10)

## Catatan

- Pastikan container PostgreSQL sudah berjalan sebelum menjalankan script import atau benchmark
- Script ini didesain untuk berjalan di lingkungan Linux/Unix. Untuk Windows, gunakan Git Bash, WSL, atau Docker
- Ketika anda menjalankan bash script perhatikan format enter pada editor anda
- Akses container postgres anda, copy file yang diperlukan kedalam container anda sehingga anda bisa eksekusi command dan menjalankan script benchmark.

## Dependensi

- Python 3.6+ dengan modul Faker
- PostgreSQL client (psql, pgbench)
- Bash shell