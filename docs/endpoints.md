# Endpoints y APIs

## 📡 WhatsApp Cloud API

### Base URL
```
https://graph.facebook.com/v21.0
```

### Autenticación
```
Authorization: Bearer {ACCESS_TOKEN}
```

### Endpoints Principales

#### 1. Enviar Mensaje de Texto

**Endpoint:**
```
POST /{PHONE_NUMBER_ID}/messages
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {ACCESS_TOKEN}
```

**Body:**
```json
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "5491122334455",
  "type": "text",
  "text": {
    "preview_url": false,
    "body": "Mensaje de texto aquí"
  }
}
```

**Response:**
```json
{
  "messaging_product": "whatsapp",
  "contacts": [{
    "input": "5491122334455",
    "wa_id": "123456789"
  }],
  "messages": [{
    "id": "wamid.xxx"
  }]
}
```

#### 2. Enviar Mensaje con Template

**Endpoint:**
```
POST /{PHONE_NUMBER_ID}/messages
```

**Body:**
```json
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "5491122334455",
  "type": "template",
  "template": {
    "name": "weekly_offer",
    "language": {
      "code": "es"
    },
    "components": [{
      "type": "body",
      "parameters": [{
        "type": "text",
        "text": "iPhone 15 Pro"
      }, {
        "type": "text",
        "text": "10"
      }]
    }]
  }
}
```

#### 3. Verificar Webhook

**Endpoint:**
```
GET /webhook
```

**Query Parameters:**
- `hub.mode`: "subscribe"
- `hub.verify_token`: {VERIFY_TOKEN}
- `hub.challenge`: {CHALLENGE}

**Response:**
```
{CHALLENGE}  // Debe retornar el challenge
```

#### 4. Recibir Webhook (POST)

**Endpoint:**
```
POST /webhook
```

**Body (Ejemplo):**
```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
    "changes": [{
      "value": {
        "messaging_product": "whatsapp",
        "metadata": {
          "display_phone_number": "1234567890",
          "phone_number_id": "PHONE_NUMBER_ID"
        },
        "contacts": [{
          "profile": {
            "name": "Juan Pérez"
          },
          "wa_id": "5491122334455"
        }],
        "messages": [{
          "from": "5491122334455",
          "id": "wamid.xxx",
          "timestamp": "1234567890",
          "text": {
            "body": "Hola"
          },
          "type": "text"
        }]
      },
      "field": "messages"
    }]
  }]
}
```

### Límites y Rate Limits

- **Gratis:** 1000 conversaciones/día
- **Pago:** Según plan contratado
- **Rate Limit:** 80 requests/segundo por número

### Códigos de Error Comunes

| Código | Descripción |
|--------|-------------|
| 100 | Parámetros inválidos |
| 131047 | Template no aprobado |
| 190 | Token expirado |
| 80007 | Número no válido |

## 🗄️ Supabase REST API

### Base URL
```
https://{PROJECT_ID}.supabase.co/rest/v1
```

### Autenticación
```
apikey: {ANON_KEY}
Authorization: Bearer {ANON_KEY}
```

### Headers Comunes
```
apikey: {ANON_KEY}
Authorization: Bearer {ANON_KEY}
Content-Type: application/json
Prefer: return=representation
```

### Endpoints Principales

#### 1. Obtener Cliente por Teléfono

**Endpoint:**
```
GET /customers?phone=eq.{PHONE}
```

**Headers:**
```
apikey: {ANON_KEY}
Authorization: Bearer {ANON_KEY}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "phone": "5491122334455",
    "name": "Juan Pérez",
    "plan": "pro",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### 2. Crear Cliente

**Endpoint:**
```
POST /customers
```

**Body:**
```json
{
  "phone": "5491122334455",
  "name": "Juan Pérez",
  "plan": "basic",
  "wa_id": "123456789"
}
```

**Response:**
```json
{
  "id": "uuid",
  "phone": "5491122334455",
  "name": "Juan Pérez",
  "plan": "basic",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### 3. Buscar Productos

**Endpoint:**
```
GET /products?name=ilike.*{QUERY}*&limit=10
```

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "iPhone 15 Pro",
    "price": 1299.99,
    "stock": 10,
    "image_url": "https://...",
    "description": "..."
  }
]
```

#### 4. Obtener Carrito

**Endpoint:**
```
GET /carts?customer_id=eq.{CUSTOMER_ID}&select=*
```

**Response:**
```json
[
  {
    "id": "uuid",
    "customer_id": "uuid",
    "items": [
      {
        "product_id": "uuid",
        "name": "iPhone 15 Pro",
        "price": 1299.99,
        "quantity": 1
      }
    ],
    "updated_at": "2024-01-01T00:00:00Z"
  }
]
```

#### 5. Actualizar Carrito

**Endpoint:**
```
PATCH /carts?id=eq.{CART_ID}
```

**Body:**
```json
{
  "items": [
    {
      "product_id": "uuid",
      "name": "iPhone 15 Pro",
      "price": 1299.99,
      "quantity": 2
    }
  ],
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### 6. Crear Pedido

**Endpoint:**
```
POST /orders
```

**Body:**
```json
{
  "customer_id": "uuid",
  "items": [
    {
      "product_id": "uuid",
      "name": "iPhone 15 Pro",
      "price": 1299.99,
      "quantity": 1
    }
  ],
  "total": 1299.99,
  "status": "pending",
  "payment_status": "pending"
}
```

#### 7. Funciones RPC

**Endpoint:**
```
POST /rpc/{function_name}
```

**Ejemplo: `add_to_cart`**
```
POST /rpc/add_to_cart
```

**Body:**
```json
{
  "p_customer_id": "uuid",
  "p_product_id": "uuid",
  "p_quantity": 1
}
```

**Ejemplo: `create_order_from_cart`**
```
POST /rpc/create_order_from_cart
```

**Body:**
```json
{
  "p_customer_id": "uuid"
}
```

#### 8. Obtener Carritos Abandonados

**Endpoint:**
```
GET /carts?updated_at=lt.{ISO_DATE}&items=neq.[]&select=*,customers!inner(*)
```

**Query Parameters:**
- `updated_at=lt.{DATE}`: Menor que fecha
- `items=neq.[]`: Items no vacío
- `select=*,customers!inner(*)`: Incluir datos de cliente

### Filtros Comunes

| Operador | Descripción | Ejemplo |
|----------|-------------|---------|
| `eq` | Igual | `?phone=eq.5491122334455` |
| `neq` | No igual | `?status=neq.cancelled` |
| `gt` | Mayor que | `?price=gt.100` |
| `lt` | Menor que | `?updated_at=lt.2024-01-01` |
| `ilike` | Case-insensitive like | `?name=ilike.*iphone*` |
| `in` | En lista | `?id=in.(uuid1,uuid2)` |

### Paginación

```
GET /products?limit=10&offset=0
```

### Ordenamiento

```
GET /orders?order=created_at.desc
```

## 🤖 OpenAI API

### Base URL
```
https://api.openai.com/v1
```

### Autenticación
```
Authorization: Bearer {API_KEY}
```

### Endpoint Principal

#### Chat Completions

**Endpoint:**
```
POST /chat/completions
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {API_KEY}
```

**Body:**
```json
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "Eres un asistente de ventas..."
    },
    {
      "role": "user",
      "content": "text:\"hola\"\nfrom:\"5491122334455\""
    }
  ],
  "temperature": 0.3,
  "max_tokens": 200
}
```

**Response:**
```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-4o-mini",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "intent:\"saludo\"\nresponse:\"¡Hola! 👋 Bienvenido...\""
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 50,
    "completion_tokens": 30,
    "total_tokens": 80
  }
}
```

### Modelos Recomendados

- **gpt-4o-mini**: Económico, rápido, suficiente para la mayoría de casos
- **gpt-4o**: Más preciso, mayor costo
- **gpt-3.5-turbo**: Alternativa económica

### Rate Limits

- **Tier 1:** 500 requests/minuto, 40K tokens/minuto
- **Tier 2+:** Según plan

## 🔗 n8n Webhooks

### Webhook de Entrada

**URL:**
```
https://{N8N_INSTANCE}/webhook/{WEBHOOK_ID}
```

**Método:** POST

**Body:** Payload de WhatsApp Cloud API

**Response:**
```json
{
  "success": true,
  "message": "Message processed"
}
```

### Configuración en n8n

1. Crear nodo Webhook
2. Configurar método POST
3. Copiar URL del webhook
4. Configurar en Meta Business Manager

## 📝 Ejemplos de Integración

### Ejemplo 1: Flujo Completo (n8n)

```javascript
// 1. Recibir webhook
const webhook = $input.item.json;

// 2. Extraer mensaje
const message = webhook.body.entry[0].changes[0].value.messages[0];
const text = message.text.body;
const from = message.from;

// 3. Normalizar a TON
const tonInput = `text:"${text.toLowerCase()}"\nfrom:"${from}"`;

// 4. Llamar OpenAI
const aiResponse = await $http.post('https://api.openai.com/v1/chat/completions', {
  model: 'gpt-4o-mini',
  messages: [
    { role: 'system', content: '...' },
    { role: 'user', content: tonInput }
  ]
});

// 5. Parsear respuesta
const tonOutput = aiResponse.choices[0].message.content;
const intent = tonOutput.match(/intent:"([^"]+)"/)?.[1];
const response = tonOutput.match(/response:"([^"]+)"/)?.[1];

// 6. Enviar WhatsApp
await $http.post(`https://graph.facebook.com/v21.0/${PHONE_NUMBER_ID}/messages`, {
  messaging_product: 'whatsapp',
  to: from,
  type: 'text',
  text: { body: response }
});
```

## 🔐 Seguridad

### Validación de Webhooks

**WhatsApp:**
```javascript
const crypto = require('crypto');

function verifySignature(payload, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return hash === signature;
}
```

### Rate Limiting

Implementar en n8n o servidor:
- Límite de requests por minuto
- Cola de mensajes
- Retry logic

## 📚 Referencias

- [WhatsApp Cloud API Docs](https://developers.facebook.com/docs/whatsapp/cloud-api)
- [Supabase REST API](https://supabase.com/docs/reference/javascript/introduction)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [n8n Webhooks](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)

