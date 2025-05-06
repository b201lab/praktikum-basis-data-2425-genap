-- Functions dan procedures untuk praktikum

-- Function untuk transfer uang (digunakan di praktikum transaksi)
CREATE OR REPLACE FUNCTION transfer_money(
    sender_id INTEGER,
    receiver_id INTEGER,
    amount DECIMAL(15, 2)
) RETURNS BOOLEAN AS $$
DECLARE
    sender_balance DECIMAL(15, 2);
BEGIN
    -- Cek saldo pengirim
    SELECT balance INTO sender_balance
    FROM bank_accounts
    WHERE account_id = sender_id;
    
    IF sender_balance < amount THEN
        RAISE EXCEPTION 'Saldo tidak mencukupi';
        RETURN FALSE;
    END IF;
    
    -- Kurangi saldo pengirim
    UPDATE bank_accounts
    SET balance = balance - amount,
        last_transaction = CURRENT_TIMESTAMP
    WHERE account_id = sender_id;
    
    -- Tambah saldo penerima
    UPDATE bank_accounts
    SET balance = balance + amount,
        last_transaction = CURRENT_TIMESTAMP
    WHERE account_id = receiver_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function untuk mencatat log transaksi
CREATE OR REPLACE FUNCTION log_transaction()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO transaction_logs (
            table_name, operation, record_id, new_data, user_id
        ) VALUES (
            TG_TABLE_NAME, 'INSERT', NEW.order_id, row_to_json(NEW), current_user
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO transaction_logs (
            table_name, operation, record_id, old_data, new_data, user_id
        ) VALUES (
            TG_TABLE_NAME, 'UPDATE', OLD.order_id, row_to_json(OLD), row_to_json(NEW), current_user
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO transaction_logs (
            table_name, operation, record_id, old_data, user_id
        ) VALUES (
            TG_TABLE_NAME, 'DELETE', OLD.order_id, row_to_json(OLD), current_user
        );
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk log transaksi
CREATE TRIGGER orders_audit
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW EXECUTE FUNCTION log_transaction();

-- Function untuk update total pesanan
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT SUM(subtotal)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk update total pesanan
CREATE TRIGGER update_order_total_trigger
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW EXECUTE FUNCTION update_order_total();

-- Function untuk simulasi konkurensi tinggi
CREATE OR REPLACE FUNCTION process_concurrent_orders(
    num_orders INTEGER,
    products_per_order INTEGER
) RETURNS void AS $$
DECLARE
    i INTEGER;
    j INTEGER;
    new_order_id INTEGER;
    random_customer_id INTEGER;
    random_product_id INTEGER;
    random_quantity INTEGER;
BEGIN
    FOR i IN 1..num_orders LOOP
        -- Pilih customer acak
        SELECT customer_id INTO random_customer_id
        FROM customers
        ORDER BY RANDOM()
        LIMIT 1;
        
        -- Buat order baru
        INSERT INTO orders (customer_id, status)
        VALUES (random_customer_id, 'pending')
        RETURNING order_id INTO new_order_id;
        
        -- Tambahkan produk ke order
        FOR j IN 1..products_per_order LOOP
            -- Pilih produk acak
            SELECT product_id INTO random_product_id
            FROM products
            ORDER BY RANDOM()
            LIMIT 1;
            
            -- Tentukan jumlah acak antara 1-5
            random_quantity := floor(random() * 5) + 1;
            
            -- Masukkan ke order_items
            INSERT INTO order_items (order_id, product_id, quantity, price)
            SELECT 
                new_order_id, 
                random_product_id, 
                random_quantity, 
                price
            FROM products
            WHERE product_id = random_product_id;
            
            -- Update stok produk
            UPDATE products
            SET stock_quantity = stock_quantity - random_quantity
            WHERE product_id = random_product_id;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
