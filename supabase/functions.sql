-- ============================================
-- FUNCIONES RPC: Funciones almacenadas para n8n
-- ============================================

-- Función para agregar producto al carrito
CREATE OR REPLACE FUNCTION add_to_cart(
    p_customer_id UUID,
    p_product_id UUID,
    p_quantity INTEGER DEFAULT 1
)
RETURNS carts AS $$
DECLARE
    v_product products;
    v_cart carts;
    v_items JSONB;
    v_item JSONB;
    v_existing_index INTEGER;
BEGIN
    -- Validar que el producto existe
    SELECT * INTO v_product FROM products WHERE id = p_product_id;
    
    IF v_product IS NULL THEN
        RAISE EXCEPTION 'Product not found: %', p_product_id;
    END IF;
    
    -- Validar stock
    IF v_product.stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock. Available: %', v_product.stock;
    END IF;
    
    -- Obtener o crear carrito
    SELECT * INTO v_cart FROM carts 
    WHERE customer_id = p_customer_id;
    
    IF v_cart IS NULL THEN
        INSERT INTO carts (customer_id, items, expires_at)
        VALUES (
            p_customer_id, 
            '[]'::jsonb, 
            NOW() + INTERVAL '7 days'
        )
        RETURNING * INTO v_cart;
    END IF;
    
    -- Preparar nuevo item
    v_item := jsonb_build_object(
        'product_id', p_product_id,
        'name', v_product.name,
        'price', v_product.price,
        'quantity', p_quantity
    );
    
    -- Buscar si el producto ya está en el carrito
    v_items := v_cart.items;
    v_existing_index := -1;
    
    FOR i IN 0..jsonb_array_length(v_items) - 1 LOOP
        IF (v_items->i->>'product_id')::UUID = p_product_id THEN
            v_existing_index := i;
            EXIT;
        END IF;
    END LOOP;
    
    -- Actualizar o agregar item
    IF v_existing_index >= 0 THEN
        -- Actualizar cantidad existente
        v_items := jsonb_set(
            v_items,
            ARRAY[v_existing_index::text, 'quantity'],
            to_jsonb(((v_items->v_existing_index->>'quantity')::INTEGER + p_quantity)::TEXT)
        );
    ELSE
        -- Agregar nuevo item
        v_items := v_items || v_item;
    END IF;
    
    -- Actualizar carrito
    UPDATE carts 
    SET 
        items = v_items,
        updated_at = NOW()
    WHERE id = v_cart.id
    RETURNING * INTO v_cart;
    
    RETURN v_cart;
END;
$$ LANGUAGE plpgsql;

-- Función para crear pedido desde carrito
CREATE OR REPLACE FUNCTION create_order_from_cart(
    p_customer_id UUID
)
RETURNS orders AS $$
DECLARE
    v_cart carts;
    v_total DECIMAL(10, 2);
    v_order orders;
    v_item JSONB;
    v_product products;
BEGIN
    -- Obtener carrito
    SELECT * INTO v_cart FROM carts 
    WHERE customer_id = p_customer_id;
    
    IF v_cart IS NULL OR jsonb_array_length(v_cart.items) = 0 THEN
        RAISE EXCEPTION 'Cart is empty or not found';
    END IF;
    
    -- Validar stock y calcular total
    v_total := 0;
    
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_cart.items) LOOP
        -- Validar stock
        SELECT * INTO v_product FROM products 
        WHERE id = (v_item->>'product_id')::UUID;
        
        IF v_product IS NULL THEN
            RAISE EXCEPTION 'Product not found: %', v_item->>'product_id';
        END IF;
        
        IF v_product.stock < (v_item->>'quantity')::INTEGER THEN
            RAISE EXCEPTION 'Insufficient stock for product: %', v_product.name;
        END IF;
        
        -- Calcular total
        v_total := v_total + 
            ((v_item->>'price')::DECIMAL * (v_item->>'quantity')::INTEGER);
    END LOOP;
    
    -- Crear orden
    INSERT INTO orders (
        customer_id, 
        items, 
        total, 
        status, 
        payment_status
    )
    VALUES (
        p_customer_id,
        v_cart.items,
        v_total,
        'pending',
        'pending'
    )
    RETURNING * INTO v_order;
    
    -- Actualizar stock de productos
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_cart.items) LOOP
        UPDATE products
        SET stock = stock - (v_item->>'quantity')::INTEGER
        WHERE id = (v_item->>'product_id')::UUID;
    END LOOP;
    
    -- Limpiar carrito
    UPDATE carts 
    SET items = '[]'::jsonb
    WHERE id = v_cart.id;
    
    RETURN v_order;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener o crear cliente por teléfono
CREATE OR REPLACE FUNCTION get_or_create_customer(
    p_phone VARCHAR(20),
    p_name VARCHAR(255) DEFAULT NULL,
    p_wa_id VARCHAR(50) DEFAULT NULL,
    p_plan VARCHAR(20) DEFAULT 'basic'
)
RETURNS customers AS $$
DECLARE
    v_customer customers;
BEGIN
    -- Intentar obtener cliente existente
    SELECT * INTO v_customer FROM customers WHERE phone = p_phone;
    
    -- Si no existe, crearlo
    IF v_customer IS NULL THEN
        INSERT INTO customers (phone, name, wa_id, plan)
        VALUES (p_phone, p_name, p_wa_id, p_plan)
        RETURNING * INTO v_customer;
    ELSE
        -- Actualizar información si se proporciona
        IF p_name IS NOT NULL OR p_wa_id IS NOT NULL THEN
            UPDATE customers
            SET 
                name = COALESCE(p_name, name),
                wa_id = COALESCE(p_wa_id, wa_id),
                updated_at = NOW()
            WHERE id = v_customer.id
            RETURNING * INTO v_customer;
        END IF;
    END IF;
    
    RETURN v_customer;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener carritos abandonados
CREATE OR REPLACE FUNCTION get_abandoned_carts(
    p_days INTEGER DEFAULT 3
)
RETURNS TABLE (
    cart_id UUID,
    customer_id UUID,
    customer_phone VARCHAR(20),
    customer_name VARCHAR(255),
    items JSONB,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS cart_id,
        c.customer_id,
        cu.phone AS customer_phone,
        cu.name AS customer_name,
        c.items,
        c.updated_at
    FROM carts c
    INNER JOIN customers cu ON c.customer_id = cu.id
    WHERE c.updated_at < NOW() - (p_days || ' days')::INTERVAL
      AND jsonb_array_length(c.items) > 0
      AND cu.plan IN ('pro', 'full')
    ORDER BY c.updated_at ASC;
END;
$$ LANGUAGE plpgsql;

-- Función para limpiar carritos expirados (ejecutar periódicamente)
CREATE OR REPLACE FUNCTION cleanup_expired_carts()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM carts 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de pedidos
CREATE OR REPLACE FUNCTION get_order_stats(
    p_customer_id UUID DEFAULT NULL
)
RETURNS TABLE (
    total_orders BIGINT,
    total_revenue DECIMAL(10, 2),
    pending_count BIGINT,
    confirmed_count BIGINT,
    processing_count BIGINT,
    shipped_count BIGINT,
    delivered_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT AS total_orders,
        COALESCE(SUM(total), 0) AS total_revenue,
        COUNT(*) FILTER (WHERE status = 'pending')::BIGINT AS pending_count,
        COUNT(*) FILTER (WHERE status = 'confirmed')::BIGINT AS confirmed_count,
        COUNT(*) FILTER (WHERE status = 'processing')::BIGINT AS processing_count,
        COUNT(*) FILTER (WHERE status = 'shipped')::BIGINT AS shipped_count,
        COUNT(*) FILTER (WHERE status = 'delivered')::BIGINT AS delivered_count
    FROM orders
    WHERE (p_customer_id IS NULL OR customer_id = p_customer_id);
END;
$$ LANGUAGE plpgsql;

