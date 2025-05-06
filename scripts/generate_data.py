#!/usr/bin/env python3
# Script untuk menghasilkan data dummy untuk praktikum
import csv
import random
import datetime
import os
from faker import Faker

# Inisialisasi Faker
fake = Faker('id_ID')  # Menggunakan locale Indonesia

# Konfigurasi
NUM_PRODUCTS = 10000
NUM_CUSTOMERS = 5000
NUM_ORDERS = 20000
NUM_ORDER_ITEMS = 50000
OUTPUT_DIR = "../data"

# Pastikan direktori output ada
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Fungsi helper untuk mengenerate tanggal acak
def random_date(start_date, end_date):
    time_between_dates = end_date - start_date
    days_between_dates = time_between_dates.days
    random_number_of_days = random.randrange(days_between_dates)
    return start_date + datetime.timedelta(days=random_number_of_days)

# Tanggal untuk data
start_date = datetime.datetime(2023, 1, 1)
end_date = datetime.datetime(2023, 12, 31)

# Kategori produk
categories = ["Elektronik", "Pakaian", "Makanan", "Minuman", "Kesehatan", 
              "Kecantikan", "Olahraga", "Otomotif", "Buku", "Mainan", 
              "Perabotan Rumah", "Alat Tulis", "Perhiasan", "Bayi", "Hewan Peliharaan"]

# 1. Generate produk
print("Generating products data...")
with open(os.path.join(OUTPUT_DIR, "products.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["product_id", "name", "description", "price", "stock_quantity", 
                    "category", "created_at", "last_updated"])
    
    for i in range(1, NUM_PRODUCTS + 1):
        product_id = i
        name = fake.word().capitalize() + " " + fake.word()
        description = fake.text(max_nb_chars=200)
        price = round(random.uniform(10000, 10000000), 2)
        stock_quantity = random.randint(0, 1000)
        category = random.choice(categories)
        created_at = random_date(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S")
        last_updated = random_date(datetime.datetime.strptime(created_at, "%Y-%m-%d %H:%M:%S"), 
                                  end_date).strftime("%Y-%m-%d %H:%M:%S")
        
        writer.writerow([product_id, name, description, price, stock_quantity, 
                        category, created_at, last_updated])

# 2. Generate pelanggan
print("Generating customers data...")
with open(os.path.join(OUTPUT_DIR, "customers.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["customer_id", "first_name", "last_name", "email", "phone", 
                    "address", "city", "country", "postal_code", "created_at"])
    
    # Set untuk melacak email yang sudah digunakan
    used_emails = set()
    
    for i in range(1, NUM_CUSTOMERS + 1):
        customer_id = i
        first_name = fake.first_name()
        last_name = fake.last_name()
        
        # Pastikan email unik
        while True:
            email = f"{first_name.lower()}.{last_name.lower()}{i}@{fake.domain_name()}"
            if email not in used_emails:
                used_emails.add(email)
                break
        
        phone = fake.phone_number()
        address = fake.street_address()
        city = fake.city()
        country = "Indonesia"
        postal_code = fake.postcode()
        created_at = random_date(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S")
        
        writer.writerow([customer_id, first_name, last_name, email, phone, 
                        address, city, country, postal_code, created_at])

# 3. Generate pesanan
print("Generating orders data...")
orders = []
with open(os.path.join(OUTPUT_DIR, "orders.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["order_id", "customer_id", "order_date", "status", 
                    "total_amount", "shipping_address", "payment_method"])
    
    statuses = ["pending", "processing", "shipped", "delivered", "cancelled"]
    payment_methods = ["credit_card", "debit_card", "bank_transfer", "e-wallet", "cash_on_delivery"]
    
    for i in range(1, NUM_ORDERS + 1):
        order_id = i
        customer_id = random.randint(1, NUM_CUSTOMERS)
        order_date = random_date(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S")
        status = random.choice(statuses)
        # total_amount akan diupdate nanti
        total_amount = 0
        shipping_address = fake.address()
        payment_method = random.choice(payment_methods)
        
        orders.append((order_id, order_date))
        writer.writerow([order_id, customer_id, order_date, status, 
                        total_amount, shipping_address, payment_method])

# 4. Generate item pesanan
print("Generating order items data...")
with open(os.path.join(OUTPUT_DIR, "order_items.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["order_item_id", "order_id", "product_id", "quantity", "price"])
    
    # Mapping untuk menghitung total per order
    order_totals = {}
    
    for i in range(1, NUM_ORDER_ITEMS + 1):
        order_item_id = i
        # Pastikan setiap order memiliki setidaknya satu item
        if i <= NUM_ORDERS:
            order_id = i
        else:
            order_id = random.randint(1, NUM_ORDERS)
        
        product_id = random.randint(1, NUM_PRODUCTS)
        quantity = random.randint(1, 10)
        price = round(random.uniform(10000, 1000000), 2)
        
        # Akumulasi total per order
        if order_id not in order_totals:
            order_totals[order_id] = 0
        order_totals[order_id] += quantity * price
        
        writer.writerow([order_item_id, order_id, product_id, quantity, price])

# 5. Update total amount di orders
print("Updating order totals...")
orders_with_totals = []
with open(os.path.join(OUTPUT_DIR, "orders.csv"), "r", newline="", encoding="utf-8") as f_read:
    reader = csv.reader(f_read)
    headers = next(reader)
    for row in reader:
        order_id = int(row[0])
        if order_id in order_totals:
            row[4] = str(round(order_totals[order_id], 2))
        orders_with_totals.append(row)

with open(os.path.join(OUTPUT_DIR, "orders.csv"), "w", newline="", encoding="utf-8") as f_write:
    writer = csv.writer(f_write)
    writer.writerow(headers)
    writer.writerows(orders_with_totals)

# 6. Generate bank accounts untuk praktikum transaksi
print("Generating bank accounts data...")
with open(os.path.join(OUTPUT_DIR, "bank_accounts.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["account_id", "customer_id", "balance", "last_transaction"])
    
    for i in range(1, NUM_CUSTOMERS + 1):
        account_id = i
        customer_id = i  # Satu customer satu account
        balance = round(random.uniform(1000000, 100000000), 2)
        last_transaction = random_date(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S")
        
        writer.writerow([account_id, customer_id, balance, last_transaction])

print("Data generation complete!")
print(f"Generated:")
print(f"- {NUM_PRODUCTS} products")
print(f"- {NUM_CUSTOMERS} customers")
print(f"- {NUM_ORDERS} orders")
print(f"- {NUM_ORDER_ITEMS} order items")
print(f"- {NUM_CUSTOMERS} bank accounts")
