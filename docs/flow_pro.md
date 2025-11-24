# Flujo Plan Pro

## 📋 Descripción

El plan Pro incluye todas las funcionalidades del plan Básico, más gestión de carrito y pedidos. Permite a los clientes agregar productos al carrito, consultarlo y confirmar pedidos.

## 🎯 Funcionalidades

- ✅ Todas las del plan Básico
- ✅ Agregar productos al carrito
- ✅ Consultar carrito
- ✅ Confirmar pedido
- ✅ Consultas a base de datos (Supabase)

## 🔄 Flujo Detallado

### 1. Recepción y Normalización

Similar al plan Básico, pero con paso adicional:

```
Cliente envía mensaje
    ↓
Webhook recibe
    ↓
Normalizar a TON
    ↓
Obtener Cliente (Supabase)
```

**Consulta a Supabase:**
```sql
SELECT id, plan FROM customers 
WHERE phone = '5491122334455'
```

### 2. Verificación de Plan

Se verifica que el cliente tenga plan `pro` o `full`. Si no existe, se crea con plan `basic` (puede actualizarse después).

### 3. Interpretación con OpenAI

**Prompt System (Plan Pro):**
```
Intenciones: saludo, pregunta_producto, agregar_carrito, 
consultar_carrito, confirmar_pedido, otro
```

**Ejemplo Input:**
```
text:"quiero agregar iphone al carrito"
```

**Ejemplo Output:**
```
intent:"agregar_carrito"
product_query:"iphone"
quantity:"1"
response:"✅ iPhone 15 Pro agregado a tu carrito..."
```

### 4. Switch por Intención

El flujo se divide según la intención:

#### A. `agregar_carrito`

```
Parsear Respuesta TON
    ↓
Buscar Producto (Supabase)
    ↓
Agregar al Carrito (Supabase RPC)
    ↓
Enviar Respuesta WhatsApp
```

**1. Buscar Producto:**
```sql
SELECT * FROM products 
WHERE name ILIKE '%iphone%' 
LIMIT 1
```

**2. Agregar al Carrito:**
```sql
-- Función RPC en Supabase
CALL add_to_cart(
  p_customer_id := 'uuid',
  p_product_id := 'uuid',
  p_quantity := 1
)
```

**Respuesta:**
```
✅ iPhone 15 Pro agregado a tu carrito. 
¿Quieres ver tu carrito o agregar algo más?
```

#### B. `consultar_carrito`

```
Parsear Respuesta TON
    ↓
Obtener Carrito (Supabase)
    ↓
Formatear Mensaje
    ↓
Enviar Respuesta WhatsApp
```

**Consulta:**
```sql
SELECT * FROM carts 
WHERE customer_id = 'uuid'
```

**Respuesta Formateada:**
```
🛒 Tu carrito:

• iPhone 15 Pro x1 - $1299.99
• AirPods Pro 2 x1 - $249.99

Total: $1549.98

¿Quieres confirmar tu pedido?
```

#### C. `confirmar_pedido`

```
Parsear Respuesta TON
    ↓
Crear Pedido desde Carrito (Supabase RPC)
    ↓
Limpiar Carrito
    ↓
Enviar Confirmación WhatsApp
```

**Proceso:**
1. Validar stock de productos
2. Calcular total
3. Crear orden en `orders`
4. Limpiar carrito
5. Enviar confirmación

**Respuesta:**
```
🎉 ¡Pedido confirmado! 
Tu orden #12345678 está siendo procesada. 
Te enviaremos los detalles por email.
```

## 📊 Diagrama de Flujo

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  WhatsApp   │
│  Cloud API  │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   n8n       │
│  Webhook    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Normalizar  │
│   a TON     │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Obtener     │
│  Cliente    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   OpenAI    │
│ Interpretar │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Switch    │
│  Intención  │
└──┬──┬──┬────┘
   │  │  │
   │  │  └─→ Crear Pedido
   │  │      └─→ Enviar WhatsApp
   │  │
   │  └─→ Consultar Carrito
   │      └─→ Enviar WhatsApp
   │
   └─→ Buscar Producto
       └─→ Agregar al Carrito
           └─→ Enviar WhatsApp
```

## 🗄️ Estructura de Base de Datos

### Tabla `carts`
```sql
CREATE TABLE carts (
    id UUID PRIMARY KEY,
    customer_id UUID REFERENCES customers(id),
    items JSONB,  -- [{product_id, name, price, quantity}]
    updated_at TIMESTAMP,
    expires_at TIMESTAMP
);
```

### Tabla `orders`
```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    customer_id UUID REFERENCES customers(id),
    items JSONB,
    total DECIMAL(10,2),
    status VARCHAR(50),
    payment_status VARCHAR(50),
    created_at TIMESTAMP
);
```

## 🔧 Funciones RPC de Supabase

### `add_to_cart(p_customer_id, p_product_id, p_quantity)`

```sql
CREATE OR REPLACE FUNCTION add_to_cart(
    p_customer_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS carts AS $$
DECLARE
    v_product products;
    v_cart carts;
    v_items JSONB;
BEGIN
    -- Obtener producto
    SELECT * INTO v_product FROM products WHERE id = p_product_id;
    
    -- Obtener o crear carrito
    SELECT * INTO v_cart FROM carts 
    WHERE customer_id = p_customer_id;
    
    IF v_cart IS NULL THEN
        INSERT INTO carts (customer_id, items, expires_at)
        VALUES (p_customer_id, '[]'::jsonb, NOW() + INTERVAL '7 days')
        RETURNING * INTO v_cart;
    END IF;
    
    -- Agregar item
    v_items := v_cart.items;
    -- Lógica de agregar/actualizar item...
    
    UPDATE carts SET items = v_items WHERE id = v_cart.id;
    RETURN v_cart;
END;
$$ LANGUAGE plpgsql;
```

### `create_order_from_cart(p_customer_id)`

```sql
CREATE OR REPLACE FUNCTION create_order_from_cart(
    p_customer_id UUID
)
RETURNS orders AS $$
DECLARE
    v_cart carts;
    v_total DECIMAL(10,2);
    v_order orders;
BEGIN
    -- Obtener carrito
    SELECT * INTO v_cart FROM carts 
    WHERE customer_id = p_customer_id;
    
    -- Calcular total
    SELECT SUM((item->>'price')::DECIMAL * (item->>'quantity')::INTEGER)
    INTO v_total
    FROM jsonb_array_elements(v_cart.items) AS item;
    
    -- Crear orden
    INSERT INTO orders (customer_id, items, total, status)
    VALUES (p_customer_id, v_cart.items, v_total, 'pending')
    RETURNING * INTO v_order;
    
    -- Limpiar carrito
    UPDATE carts SET items = '[]'::jsonb WHERE id = v_cart.id;
    
    RETURN v_order;
END;
$$ LANGUAGE plpgsql;
```

## 🎨 Ejemplos de Conversación

### Ejemplo 1: Agregar al Carrito

**Cliente:**
```
"Quiero agregar iPhone al carrito"
```

**Sistema:**
1. Interpreta: `agregar_carrito`, `product_query: "iphone"`
2. Busca producto en Supabase
3. Agrega al carrito
4. Responde: "✅ iPhone 15 Pro agregado a tu carrito..."

### Ejemplo 2: Consultar Carrito

**Cliente:**
```
"Ver mi carrito"
```

**Sistema:**
1. Interpreta: `consultar_carrito`
2. Obtiene carrito de Supabase
3. Formatea mensaje con items
4. Responde: "🛒 Tu carrito: ..."

### Ejemplo 3: Confirmar Pedido

**Cliente:**
```
"Confirmo el pedido"
```

**Sistema:**
1. Interpreta: `confirmar_pedido`
2. Crea orden desde carrito
3. Limpia carrito
4. Responde: "🎉 ¡Pedido confirmado!..."

## ⚙️ Configuración

### Variables de Entorno Adicionales

```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
```

### Credenciales n8n

1. **Supabase API**: HTTP Header Auth
   - Header: `apikey`
   - Value: `SUPABASE_ANON_KEY`

## 📝 Notas Importantes

- ✅ Requiere configuración de Supabase
- ✅ Necesita funciones RPC creadas
- ✅ Los carritos expiran en 7 días
- ✅ Validación de stock antes de agregar
- ⚠️ No incluye mensajes salientes (solo Full)

## 🚀 Próximos Pasos

Para mensajes salientes y marketing, actualiza a:
- **Plan Full**: Carritos abandonados, ofertas semanales, marketing

