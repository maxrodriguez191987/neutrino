# 🧪 Guía de Pruebas - WhatsApp Sales Automation

Guía completa para probar el sistema paso a paso.

## 📋 Índice

1. [Prerrequisitos](#prerrequisitos)
2. [Configuración Inicial](#configuración-inicial)
3. [Probar Base de Datos](#probar-base-de-datos)
4. [Probar n8n Workflows](#probar-n8n-workflows)
5. [Probar WhatsApp Webhook](#probar-whatsapp-webhook)
6. [Probar Flujo Completo](#probar-flujo-completo)
7. [Troubleshooting](#troubleshooting)

## ✅ Prerrequisitos

Antes de empezar, asegúrate de tener:

- [ ] Cuenta de Supabase creada
- [ ] Cuenta de OpenAI con API key
- [ ] Meta Business Account configurado
- [ ] n8n instalado (cloud o self-hosted)
- [ ] Número de teléfono de prueba en Meta

## 🔧 Configuración Inicial

### 1. Configurar Supabase

#### Paso 1: Crear Proyecto
1. Ve a [supabase.com](https://supabase.com)
2. Crea un nuevo proyecto
3. Anota la URL y API keys

#### Paso 2: Ejecutar Schema
1. Ve a SQL Editor en Supabase
2. Copia y pega el contenido de `supabase/schema.sql`
3. Ejecuta el script
4. Verifica que las tablas se crearon:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public';
   ```

#### Paso 3: Ejecutar Funciones
1. En SQL Editor, copia y pega `supabase/functions.sql`
2. Ejecuta el script
3. Verifica las funciones:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_schema = 'public';
   ```

#### Paso 4: Ejecutar Seeds (Opcional)
1. Copia y pega `supabase/seed.sql`
2. Ejecuta para tener datos de prueba
3. Verifica:
   ```sql
   SELECT * FROM products LIMIT 5;
   SELECT * FROM customers LIMIT 5;
   ```

### 2. Configurar Meta Business (WhatsApp)

#### Paso 1: Crear App
1. Ve a [developers.facebook.com](https://developers.facebook.com)
2. Crea una nueva app
3. Agrega producto "WhatsApp"
4. Configura WhatsApp Business API

#### Paso 2: Obtener Credenciales
1. Ve a WhatsApp → API Setup
2. Anota:
   - **Phone Number ID**
   - **Access Token** (temporal o permanente)
   - **Verify Token** (crea uno tú mismo)

#### Paso 3: Agregar Número de Prueba
1. En WhatsApp → API Setup
2. Agrega tu número de teléfono como número de prueba
3. Envía el código de verificación

### 3. Configurar n8n

#### Opción A: n8n Cloud
1. Ve a [n8n.io](https://n8n.io) y crea cuenta
2. Crea un nuevo workflow

#### Opción B: n8n Self-Hosted
```bash
# Con Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# O con npm
npm install n8n -g
n8n start
```

Accede a: `http://localhost:5678`

## 🗄️ Probar Base de Datos

### Test 1: Verificar Conexión

```bash
# Usar curl o Postman
curl -X GET \
  'https://TU_PROYECTO.supabase.co/rest/v1/products?limit=5' \
  -H "apikey: TU_ANON_KEY" \
  -H "Authorization: Bearer TU_ANON_KEY"
```

**Resultado esperado:** Lista de productos en JSON

### Test 2: Crear Cliente

```bash
curl -X POST \
  'https://TU_PROYECTO.supabase.co/rest/v1/customers' \
  -H "apikey: TU_ANON_KEY" \
  -H "Authorization: Bearer TU_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "phone": "5491122334455",
    "name": "Cliente Test",
    "plan": "basic"
  }'
```

### Test 3: Probar Función RPC

```bash
curl -X POST \
  'https://TU_PROYECTO.supabase.co/rest/v1/rpc/add_to_cart' \
  -H "apikey: TU_ANON_KEY" \
  -H "Authorization: Bearer TU_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "p_customer_id": "UUID_DEL_CLIENTE",
    "p_product_id": "UUID_DEL_PRODUCTO",
    "p_quantity": 1
  }'
```

## 🔄 Probar n8n Workflows

### Paso 1: Importar Workflow

1. En n8n, haz clic en "Import from File"
2. Selecciona `workflows/basic.json`
3. El workflow se importará con todos los nodos

### Paso 2: Configurar Credenciales

#### OpenAI Credentials
1. Ve a Credentials → Add Credential
2. Selecciona "OpenAI"
3. Ingresa tu API Key
4. Guarda como "OpenAI API"

#### WhatsApp Credentials
1. Ve a Credentials → Add Credential
2. Selecciona "HTTP Header Auth"
3. Configura:
   - **Name**: Authorization
   - **Value**: Bearer {TU_ACCESS_TOKEN}
4. Guarda como "WhatsApp Cloud API"

#### Supabase Credentials
1. Ve a Credentials → Add Credential
2. Selecciona "HTTP Header Auth"
3. Configura:
   - **Name**: apikey
   - **Value**: {TU_SUPABASE_ANON_KEY}
4. Guarda como "Supabase API"

### Paso 3: Configurar Variables de Entorno

En n8n, ve a Settings → Environment Variables y agrega:

```bash
WHATSAPP_PHONE_NUMBER_ID=123456789
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
OPENAI_API_KEY=sk-xxx
```

### Paso 4: Configurar Nodos

1. **Webhook Node**: 
   - Copia la URL del webhook (ej: `https://tu-n8n.com/webhook/abc123`)
   - Método: POST
   - Response Mode: "Respond to Webhook"

2. **OpenAI Node**:
   - Selecciona credencial "OpenAI API"
   - Model: `gpt-4o-mini`
   - Temperature: 0.3

3. **HTTP Request Nodes**:
   - Configura URLs con variables de entorno
   - Asigna credenciales correspondientes

### Paso 5: Activar Workflow

1. Haz clic en "Active" toggle en la esquina superior derecha
2. El workflow ahora está escuchando webhooks

## 📱 Probar WhatsApp Webhook

### Opción 1: Usar ngrok (Local)

Si n8n está corriendo localmente:

```bash
# Instalar ngrok
npm install -g ngrok
# O descargar de ngrok.com

# Exponer n8n
ngrok http 5678

# Copia la URL (ej: https://abc123.ngrok.io)
```

### Opción 2: Configurar en Meta

1. Ve a Meta Business Manager
2. WhatsApp → Configuration → Webhooks
3. Configura:
   - **Callback URL**: `https://tu-n8n.com/webhook/abc123`
   - **Verify Token**: El que configuraste en n8n
4. Haz clic en "Verify and Save"
5. Suscríbete a eventos: `messages`

### Test: Verificar Webhook

Meta enviará un GET request para verificar. n8n debe responder con el challenge.

**En n8n, agrega un nodo IF antes del webhook:**
- Si `$json.query['hub.verify_token']` == tu token
- Retorna `$json.query['hub.challenge']`

## 🧪 Probar Flujo Completo

### Test 1: Plan Básico - Saludo

1. Envía mensaje desde WhatsApp: `"Hola"`
2. Verifica en n8n:
   - Webhook recibe el mensaje
   - TON se normaliza correctamente
   - OpenAI interpreta como "saludo"
   - Respuesta se envía por WhatsApp

**Resultado esperado:** Recibes respuesta automática tipo "¡Hola! 👋 Bienvenido..."

### Test 2: Plan Básico - Pregunta Producto

1. Envía: `"Tienen iPhone?"`
2. Verifica que OpenAI identifica `pregunta_producto`
3. Verifica respuesta menciona productos

### Test 3: Plan Pro - Agregar al Carrito

**Requisito:** Tener cliente y producto en Supabase

1. Envía: `"Quiero agregar iPhone al carrito"`
2. Verifica:
   - Cliente se obtiene de Supabase
   - Producto se busca
   - Se agrega al carrito
   - Respuesta confirma agregado

**Verificar en Supabase:**
```sql
SELECT * FROM carts WHERE customer_id = 'UUID';
```

### Test 4: Plan Pro - Consultar Carrito

1. Envía: `"Ver mi carrito"`
2. Verifica respuesta muestra items y total

### Test 5: Plan Pro - Confirmar Pedido

1. Envía: `"Confirmo el pedido"`
2. Verifica:
   - Se crea orden en `orders`
   - Carrito se limpia
   - Respuesta confirma pedido

**Verificar en Supabase:**
```sql
SELECT * FROM orders ORDER BY created_at DESC LIMIT 1;
```

### Test 6: Plan Full - Carrito Abandonado

1. Crea carrito con items
2. Espera 3 días (o modifica fecha en DB para testing)
3. Activa workflow de cron manualmente
4. Verifica que se envía mensaje

**Para testing rápido, modifica fecha:**
```sql
UPDATE carts 
SET updated_at = NOW() - INTERVAL '4 days'
WHERE customer_id = 'UUID';
```

Luego ejecuta el workflow de cron manualmente.

## 🔍 Verificar Logs

### En n8n

1. Ve a "Executions" en el menú lateral
2. Revisa cada ejecución
3. Haz clic en un nodo para ver datos de entrada/salida

### En Supabase

```sql
-- Ver mensajes recibidos
SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;

-- Ver carritos activos
SELECT * FROM carts WHERE items != '[]'::jsonb;

-- Ver pedidos recientes
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;
```

## 🐛 Troubleshooting

### Webhook no recibe mensajes

**Solución:**
1. Verifica URL en Meta Business Manager
2. Verifica que n8n está activo
3. Revisa logs de Meta
4. Usa ngrok si es local

### OpenAI no responde

**Solución:**
1. Verifica API Key
2. Revisa límites de rate
3. Verifica formato TON
4. Revisa logs de OpenAI en n8n

### Supabase no conecta

**Solución:**
1. Verifica URL y API Key
2. Revisa políticas RLS (Row Level Security)
3. Desactiva RLS temporalmente para testing:
   ```sql
   ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
   ```

### Mensaje no se envía por WhatsApp

**Solución:**
1. Verifica Access Token
2. Verifica Phone Number ID
3. Revisa formato del request
4. Verifica que el número esté en modo prueba

### TON parsing falla

**Solución:**
1. Verifica formato de salida de OpenAI
2. Revisa regex en nodo de parsing
3. Agrega logging para ver output de OpenAI

## 📊 Checklist de Pruebas

- [ ] Supabase conecta correctamente
- [ ] Tablas creadas
- [ ] Funciones RPC funcionan
- [ ] n8n workflow importado
- [ ] Credenciales configuradas
- [ ] Webhook verificado en Meta
- [ ] Mensaje entrante se recibe
- [ ] TON se normaliza
- [ ] OpenAI interpreta correctamente
- [ ] Respuesta se envía por WhatsApp
- [ ] Carrito funciona (Plan Pro)
- [ ] Pedidos se crean (Plan Pro)
- [ ] Cron jobs funcionan (Plan Full)

## 🚀 Próximos Pasos

Una vez que todo funciona:

1. **Producción**: Configurar variables de entorno en producción
2. **Monitoreo**: Configurar alertas y logs
3. **Optimización**: Ajustar prompts y workflows
4. **Escalado**: Configurar múltiples instancias si es necesario

## 📝 Notas

- Usa números de prueba de Meta para evitar costos
- Los templates de WhatsApp requieren aprobación (puede tardar)
- Revisa límites de rate de cada servicio
- Guarda backups de workflows antes de modificar

