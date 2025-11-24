-- ============================================
-- SEED DATA: Datos de ejemplo para desarrollo
-- ============================================

-- Productos de ejemplo
INSERT INTO products (name, price, stock, image_url, description, category) VALUES
('iPhone 15 Pro', 1299.99, 10, 'https://example.com/iphone15.jpg', 'Último modelo de iPhone con chip A17 Pro', 'smartphones'),
('Samsung Galaxy S24', 999.99, 15, 'https://example.com/galaxy-s24.jpg', 'Pantalla AMOLED 6.2 pulgadas', 'smartphones'),
('MacBook Pro M3', 1999.99, 5, 'https://example.com/macbook-pro.jpg', 'Laptop profesional con chip M3', 'laptops'),
('AirPods Pro 2', 249.99, 30, 'https://example.com/airpods-pro.jpg', 'Auriculares inalámbricos con cancelación de ruido', 'audio'),
('iPad Air', 599.99, 12, 'https://example.com/ipad-air.jpg', 'Tablet versátil para trabajo y entretenimiento', 'tablets'),
('Apple Watch Series 9', 399.99, 20, 'https://example.com/watch-s9.jpg', 'Reloj inteligente con GPS y monitor de salud', 'wearables'),
('Sony WH-1000XM5', 399.99, 8, 'https://example.com/sony-headphones.jpg', 'Auriculares con cancelación de ruido líder', 'audio'),
('Logitech MX Master 3S', 99.99, 25, 'https://example.com/logitech-mouse.jpg', 'Mouse inalámbrico ergonómico para productividad', 'accesorios')
ON CONFLICT DO NOTHING;

-- Clientes de ejemplo
INSERT INTO customers (phone, name, email, plan, wa_id) VALUES
('5491122334455', 'Juan Pérez', 'juan@example.com', 'basic', '123456789'),
('5491122334456', 'María García', 'maria@example.com', 'pro', '123456790'),
('5491122334457', 'Carlos López', 'carlos@example.com', 'full', '123456791'),
('5491122334458', 'Ana Martínez', 'ana@example.com', 'basic', '123456792'),
('5491122334459', 'Pedro Rodríguez', 'pedro@example.com', 'full', '123456793')
ON CONFLICT (phone) DO NOTHING;

-- Carritos de ejemplo (algunos expirados para testing)
INSERT INTO carts (customer_id, items, expires_at) VALUES
(
    (SELECT id FROM customers WHERE phone = '5491122334455'),
    '[
        {"product_id": "1", "name": "iPhone 15 Pro", "price": 1299.99, "quantity": 1},
        {"product_id": "4", "name": "AirPods Pro 2", "price": 249.99, "quantity": 1}
    ]'::jsonb,
    NOW() + INTERVAL '7 days'
),
(
    (SELECT id FROM customers WHERE phone = '5491122334456'),
    '[
        {"product_id": "3", "name": "MacBook Pro M3", "price": 1999.99, "quantity": 1}
    ]'::jsonb,
    NOW() + INTERVAL '5 days'
),
(
    (SELECT id FROM customers WHERE phone = '5491122334457'),
    '[
        {"product_id": "2", "name": "Samsung Galaxy S24", "price": 999.99, "quantity": 1},
        {"product_id": "6", "name": "Apple Watch Series 9", "price": 399.99, "quantity": 1}
    ]'::jsonb,
    NOW() - INTERVAL '1 day'  -- Carrito expirado para testing
)
ON CONFLICT DO NOTHING;

-- Pedidos de ejemplo
INSERT INTO orders (customer_id, items, total, status, payment_status) VALUES
(
    (SELECT id FROM customers WHERE phone = '5491122334455'),
    '[
        {"product_id": "1", "name": "iPhone 15 Pro", "price": 1299.99, "quantity": 1}
    ]'::jsonb,
    1299.99,
    'confirmed',
    'paid'
),
(
    (SELECT id FROM customers WHERE phone = '5491122334456'),
    '[
        {"product_id": "4", "name": "AirPods Pro 2", "price": 249.99, "quantity": 2}
    ]'::jsonb,
    499.98,
    'processing',
    'paid'
),
(
    (SELECT id FROM customers WHERE phone = '5491122334457'),
    '[
        {"product_id": "3", "name": "MacBook Pro M3", "price": 1999.99, "quantity": 1},
        {"product_id": "7", "name": "Sony WH-1000XM5", "price": 399.99, "quantity": 1}
    ]'::jsonb,
    2399.98,
    'shipped',
    'paid'
)
ON CONFLICT DO NOTHING;

-- Mensajes de ejemplo
INSERT INTO messages (customer_id, phone, direction, message_type, content, intent) VALUES
(
    (SELECT id FROM customers WHERE phone = '5491122334455'),
    '5491122334455',
    'inbound',
    'text',
    'Hola, quiero ver productos',
    'saludo'
),
(
    (SELECT id FROM customers WHERE phone = '5491122334456'),
    '5491122334456',
    'inbound',
    'text',
    'Quiero agregar iPhone al carrito',
    'agregar_carrito'
),
(
    (SELECT id FROM customers WHERE phone = '5491122334457'),
    '5491122334457',
    'inbound',
    'text',
    'Ver mi carrito',
    'consultar_carrito'
)
ON CONFLICT DO NOTHING;

