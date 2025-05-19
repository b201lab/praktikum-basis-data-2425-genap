#!/bin/bash
# Script untuk benchmark performa database

# Variabel koneksi
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="ecommerce"
DB_USER="praktikan"
DB_PASS="p4ssw0rd"
QUERY_FILE=$1
NUM_CONNECTIONS=${2:-10}
NUM_TRANSACTIONS=${3:-1000}
CLIENT_THREADS=${4:-10}

if [ -z "$QUERY_FILE" ]; then
    echo "Usage: $0 <query_file> [num_connections] [num_transactions] [client_threads]"
    exit 1
fi

if [ ! -f "$QUERY_FILE" ]; then
    echo "Error: Query file $QUERY_FILE not found!"
    exit 1
fi

echo "Starting benchmark with:"
echo "- Query file: $QUERY_FILE"
echo "- Connections: $NUM_CONNECTIONS"
echo "- Transactions: $NUM_TRANSACTIONS"
echo "- Client threads: $CLIENT_THREADS"
echo

# Menjalankan pgbench
PGPASSWORD=$DB_PASS pgbench -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
    -c $NUM_CONNECTIONS \
    -t $NUM_TRANSACTIONS \
    -j $CLIENT_THREADS \
    -f $QUERY_FILE \
    -P 1 \
    -r

echo "Benchmark completed!"
