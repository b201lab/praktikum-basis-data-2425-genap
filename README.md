# Praktikum Basis Data: ACID dan High Concurrency dengan PostgreSQL

Praktikum ini bertujuan untuk memahami konsep ACID (Atomicity, Consistency, Isolation, Durability) dan High Concurrency pada database PostgreSQL melalui empat skenario praktis.

## Persiapan Environment

### Menggunakan Docker

1. Install Docker dan Docker Compose di komputer Anda
2. Clone repositori ini
3. Jalankan container dengan perintah:

```bash
docker-compose up -d
```

4. Generate data dummy:

```bash
cd scripts
pip install faker
python generate_data.py
```

5. Import data ke PostgreSQL:

```bash
cd scripts
bash import_data.sh
```

6. Akses pgAdmin di browser:
   - URL: http://localhost:5050
   - Email: admin@example.com
   - Password: p4ssw0rd

7. Tambahkan server di pgAdmin:
   - Name: PostgreSQL Praktikum
   - Host: postgres
   - Port: 5432
   - Username: praktikan
   - Password: p4ssw0rd

## Cara Menggunakan Modul Praktikum

Modul praktikum memiliki:
- README.md dengan penjelasan konsep dan langkah-langkah
- File SQL dengan query untuk latihan
- Tugas Modul

Ikuti langkah-langkah dalam README.md setiap modul praktikum secara berurutan.

## Petunjuk Pengerjaan

1. Praktikum dikerjakan dalam kelompok (4 orang per kelompok)
2. Setiap kelompok mengerjakan semua modul praktikum
4. Setiap kelompok membuat laporan akhir berisi:
   - Modul
   - Dasar Teori
   - Analisis
   - Tugas Modul
   - Tugas Asistensi
   - Kesimpulan 

## Tentang Data

Dataset yang digunakan adalah data e-commerce dummy yang berisi:
- 10.000 produk
- 5.000 pelanggan
- 20.000 pesanan
- 50.000 item pesanan

Data ini memungkinkan pengujian performa dan konkurensi yang realistis.

## Referensi

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Concurrency](https://www.postgresql.org/docs/current/mvcc.html)
- [PostgreSQL Indexing](https://www.postgresql.org/docs/current/indexes.html)
- [PostgreSQL Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)
- [PostgreSQL Backup and Restore](https://www.postgresql.org/docs/current/backup.html)

## Modul Author
Arta Kusuma Hernanda

## Asisten praktikum
<details>
  <summary>2025/2024 Genap</summary>
  
  1. 5024211001 - Reza Ali Nirwansyah
  2. 5024211004 - Kenanya Keandra Adriel Prasetyo
  3. 5024211005 - Sulthan Daffa Arif Mahmudi
  4. 5024211013 - Annafi Nur Jayani
  5. 5024221001 - Rezky Dwisantika Pujiastuti
  6. 5024221011 - Farrell Rafee Sudjatmiko
  7. 5024221023 - Hendrich Ardthian Breshman Panjaitan
  8. 5024221052 - Pranaditya Tri Jyotista Vavitram Putra Sudana
  9. 5024221058 - Rigel Ramadhani Waloni
  10. 5024221064 - Ahmad Wildan Syahputra
  11. 5024221066 - Imanuel Daulat Satrio Utomo Siahaan
  12. 5024221067 - Adhitya Raufarhan Sukmana
</details>

## Peserta
- [2025/2024 Genap](https://docs.google.com/spreadsheets/d/1laOQjuMvkfZmDMm7riRumSdqZqGLElz9pLVCdqsBnwo/edit?gid=0#gid=0)