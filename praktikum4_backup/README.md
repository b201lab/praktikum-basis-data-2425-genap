# Praktikum 4: Backup dan Recovery

Pada praktikum ini, kita akan mempelajari implementasi backup dan recovery pada PostgreSQL untuk menjamin ketersediaan dan integritas data.

## Tujuan

1. Memahami konsep backup dan recovery pada database
2. Mengimplementasikan berbagai tipe backup di PostgreSQL
3. Melakukan recovery data dari backup
4. Menerapkan strategi backup yang tepat sesuai kebutuhan

## Tahapan Praktikum

### 1. Persiapan

1. Pastikan container Docker PostgreSQL sudah berjalan
2. Gunakan pgAdmin atau PSQL untuk mengakses database
3. Pastikan data sudah diimpor menggunakan script yang disediakan

### 2. Konsep Backup dan Recovery

Ada beberapa tipe backup di PostgreSQL:
- **Logical Backup**: Menggunakan `pg_dump` dan `pg_dumpall` untuk mengekspor data dalam format SQL atau custom
- **Physical Backup**: Mengambil salinan langsung dari file data PostgreSQL
- **Continuous Archiving**: Menggunakan Write-Ahead Logs (WAL) untuk Point-in-Time Recovery (PITR)

### 3. Logical Backup dengan pg_dump

#### 3.1 Backup Database Lengkap

```bash
# Format SQL
pg_dump -h localhost -p 5432 -U praktikan -d ecommerce -f ecommerce_full.sql

# Format Custom (untuk restore selektif)
pg_dump -h localhost -p 5432 -U praktikan -d ecommerce -Fc -f ecommerce_full.dump

# Format Directory (paralel backup)
pg_dump -h localhost -p 5432 -U praktikan -d ecommerce -Fd -j 4 -f ecommerce_backup_dir
```

#### 3.2 Backup Tabel Tertentu

```bash
# Backup hanya tabel orders dan order_items
pg_dump -h localhost -p 5432 -U praktikan -d ecommerce -t orders -t order_items -f orders_backup.sql
```

#### 3.3 Backup Schema Saja

```bash
# Backup struktur tanpa data
pg_dump -h localhost -p 5432 -U praktikan -d ecommerce --schema-only -f ecommerce_schema.sql
```

#### 3.4 Backup Data Saja

```bash
# Backup data tanpa struktur
pg_dump -h localhost -p 5432 -U praktikan -d ecommerce --data-only -f ecommerce_data.sql
```

### 4. Restore dari Logical Backup

#### 4.1 Restore Database Lengkap

```bash
# Restore dari format SQL
psql -h localhost -p 5432 -U praktikan -d ecommerce_restore -f ecommerce_full.sql

# Restore dari format Custom
pg_restore -h localhost -p 5432 -U praktikan -d ecommerce_restore -v ecommerce_full.dump
```

#### 4.2 Restore Tabel Tertentu

```bash
# Restore hanya tabel orders dari backup custom
pg_restore -h localhost -p 5432 -U praktikan -d ecommerce_restore -t orders -v ecommerce_full.dump
```

### 5. Physical Backup

Physical backup melibatkan penyalinan langsung file data PostgreSQL. Dalam container Docker, kita bisa menggunakan volume untuk menyimpan data:

```bash
# Stop container
docker-compose stop postgres

# Backup volume
docker run --rm -v postgres_praktikum_postgres_data:/source -v $(pwd)/backup:/backup ubuntu tar -czf /backup/postgres_data_backup.tar.gz -C /source .

# Start container kembali
docker-compose start postgres
```

### 6. Continuous Archiving dan Point-in-Time Recovery (PITR)

Untuk mengimplementasikan Continuous Archiving, kita perlu mengkonfigurasi PostgreSQL untuk menyimpan Write-Ahead Logs (WAL):

#### 6.1 Konfigurasi WAL Archiving

Edit file `postgresql.conf`:

```
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/data/archive/%f'
```

#### 6.2 Point-in-Time Recovery

```bash
# Buat base backup
pg_basebackup -h localhost -p 5432 -U praktikan -D /backup/base -Fp -Xs -P

# Restore ke titik waktu tertentu
# (Memerlukan recovery.conf)
```

### 7. Demonstrasi Skenario Disaster

#### 7.1 Simulasi Kehilangan Data

```sql
-- Buat tabel untuk demonstrasi
CREATE TABLE important_data (
    id SERIAL PRIMARY KEY,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert data penting
INSERT INTO important_data (description) VALUES ('Data sangat penting #1');
INSERT INTO important_data (description) VALUES ('Data sangat penting #2');
INSERT INTO important_data (description) VALUES ('Data sangat penting #3');

-- Backup
-- (Jalankan pg_dump seperti di atas)

-- Simulasi kesalahan
DROP TABLE important_data;

-- Restore
-- (Jalankan pg_restore seperti di atas)
```

#### 7.2 Simulasi Corrupt Database

```bash
# Backup terlebih dahulu
# (Jalankan backup)

# Simulasi korupsi (hati-hati!)
docker-compose exec postgres bash -c "dd if=/dev/urandom of=/var/lib/postgresql/data/base/16384/1234 bs=8192 count=1 conv=notrunc"

# Restart PostgreSQL (kemungkinan akan gagal start)
docker-compose restart postgres

# Restore dari backup
# (Jalankan restore)
```

### 8. Strategi Backup yang Baik

Strategi yang direkomendasikan:
1. Full backup setiap minggu
2. Differential backup setiap hari
3. Continuous archiving untuk recovery point-in-time
4. Replikasi untuk high availability

### 9. Implementasi High Availability dengan Replikasi

Meskipun bukan bagian dari backup/recovery secara tradisional, replikasi membantu memastikan ketersediaan data:

```
# Primary server (postgresql.conf)
wal_level = replica
max_wal_senders = 10
wal_keep_segments = 64

# Standby server (postgresql.conf)
hot_standby = on

# Standby server (recovery.conf)
standby_mode = 'on'
primary_conninfo = 'host=primary port=5432 user=replicator password=password'
trigger_file = '/tmp/postgresql.trigger'
```

## Tugas

1. Lakukan backup database dengan minimal 3 metode berbeda:
   - Full database backup dengan pg_dump
   - Backup tabel tertentu
   - Backup struktur saja

2. Simulasikan skenario kehilangan data dan lakukan recovery dari backup:
   - Menghapus tabel penting secara tidak sengaja
   - Menghapus beberapa baris data
   - Menghapus database

3. Buat script otomatisasi backup yang berjalan terjadwal:
   - Menggunakan cron job atau scheduled tasks
   - Menyimpan backup dengan timestamp
   - Menghapus backup lama secara otomatis

4. Buat laporan yang menjelaskan strategi backup dan recovery yang tepat untuk database dengan karakteristik:
   - Data transaksi finansial yang kritikal
   - Data logging dengan volume tinggi
   - Data referensi yang jarang berubah

## Referensi

- [PostgreSQL Documentation: Backup and Restore](https://www.postgresql.org/docs/current/backup.html)
- [PostgreSQL: Continuous Archiving and PITR](https://www.postgresql.org/docs/current/continuous-archiving.html)
- [PostgreSQL: High Availability](https://www.postgresql.org/docs/current/high-availability.html)
- [PostgreSQL Wiki: Backup in Practice](https://wiki.postgresql.org/wiki/Backup_in_practice)