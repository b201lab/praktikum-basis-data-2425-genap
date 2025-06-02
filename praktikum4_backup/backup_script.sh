#!/bin/bash
# Script otomatisasi backup untuk PostgreSQL
# Dapat dijadwalkan melalui cron job

# Konfigurasi
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="ecommerce"
DB_USER="praktikan"
DB_PASS="p4ssw0rd"
BACKUP_DIR="../backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7  # Berapa lama backup disimpan (dalam hari)

# Pastikan direktori backup ada
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/full"
mkdir -p "$BACKUP_DIR/schema"
mkdir -p "$BACKUP_DIR/tables"

# Log function
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$BACKUP_DIR/backup.log"
}

# Error handling
handle_error() {
    log_message "ERROR: $1"
    exit 1
}

# 1. Full database backup (SQL format)
log_message "Starting full database backup (SQL format)..."
PGPASSWORD=$DB_PASS pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$BACKUP_DIR/full/ecommerce_full_$DATE.sql"
if [ $? -ne 0 ]; then
    handle_error "Full database backup (SQL format) failed"
fi
log_message "Full database backup (SQL format) completed: $BACKUP_DIR/full/ecommerce_full_$DATE.sql"

# 2. Full database backup (Custom format)
log_message "Starting full database backup (Custom format)..."
PGPASSWORD=$DB_PASS pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -Fc -f "$BACKUP_DIR/full/ecommerce_full_$DATE.dump"
if [ $? -ne 0 ]; then
    handle_error "Full database backup (Custom format) failed"
fi
log_message "Full database backup (Custom format) completed: $BACKUP_DIR/full/ecommerce_full_$DATE.dump"

# 3. Schema-only backup
log_message "Starting schema-only backup..."
PGPASSWORD=$DB_PASS pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --schema-only -f "$BACKUP_DIR/schema/ecommerce_schema_$DATE.sql"
if [ $? -ne 0 ]; then
    handle_error "Schema-only backup failed"
fi
log_message "Schema-only backup completed: $BACKUP_DIR/schema/ecommerce_schema_$DATE.sql"

# 4. Backup tabel tertentu (orders dan order_items)
log_message "Starting table-specific backup (orders and order_items)..."
PGPASSWORD=$DB_PASS pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t orders -t order_items -f "$BACKUP_DIR/tables/orders_$DATE.sql"
if [ $? -ne 0 ]; then
    handle_error "Table-specific backup failed"
fi
log_message "Table-specific backup completed: $BACKUP_DIR/tables/orders_$DATE.sql"

# 5. Compress backup untuk menghemat ruang
log_message "Compressing backups..."
find "$BACKUP_DIR" -name "*.sql" -type f -mmin -10 | xargs gzip
find "$BACKUP_DIR" -name "*.dump" -type f -mmin -10 | xargs gzip
log_message "Compression completed"

# 6. Cleanup: Hapus backup lama untuk menghemat ruang
log_message "Cleaning up old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -type f -name "*.sql" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -type f -name "*.dump" -mtime +$RETENTION_DAYS -delete
log_message "Cleanup completed"

# 7. Verifikasi backup terakhir
LAST_BACKUP=$(ls -t "$BACKUP_DIR/full" | head -n1)
log_message "Last backup file: $LAST_BACKUP"
log_message "Total backup files: $(find "$BACKUP_DIR" -type f | wc -l)"
log_message "Backup script completed successfully"

# Catatan: untuk mengotomatisasi dengan cron, tambahkan entry seperti:
# 0 2 * * * /path/to/scripts/backup_script.sh > /dev/null 2>&1
