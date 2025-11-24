# Flujo Plan Básico

## 📋 Descripción

El plan Básico permite automatización de respuestas entrantes con intenciones simples. Ideal para negocios que quieren responder automáticamente a consultas básicas.

## 🎯 Funcionalidades

- ✅ Respuestas automáticas a saludos
- ✅ Consultas de productos
- ✅ Respuestas genéricas para otras intenciones

## 🔄 Flujo Detallado

### 1. Recepción del Mensaje

```
Cliente envía mensaje por WhatsApp
    ↓
WhatsApp Cloud API recibe mensaje
    ↓
Webhook POST a n8n
```

**Webhook Payload:**
```json
{
  "entry": [{
    "changes": [{
      "value": {
        "messages": [{
          "from": "5491122334455",
          "text": { "body": "Hola" },
          "type": "text"
        }]
      }
    }]
  }]
}
```

### 2. Normalización a TON

El nodo "Normalizar a TON" extrae:
- `ton_text`: Texto del mensaje
- `ton_from`: Número de teléfono
- `ton_wa_id`: WhatsApp ID

**Resultado:**
```
ton_text: "hola"
ton_from: "5491122334455"
ton_wa_id: "123456789"
```

### 3. Formateo TON Input

Se crea el string TON para enviar a OpenAI:

```
text:"hola"
from:"5491122334455"
wa_id:"123456789"
```

### 4. Interpretación con OpenAI

**Prompt System:**
```
Eres un asistente de ventas por WhatsApp. 
Interpreta mensajes y responde en formato TON.

Intenciones: saludo, pregunta_producto, otro

Responde SOLO en formato TON:
intent:"..."
response:"..."
```

**Input:**
```
text:"hola"
from:"5491122334455"
wa_id:"123456789"
```

**Output:**
```
intent:"saludo"
response:"¡Hola! 👋 Bienvenido a nuestra tienda. ¿En qué puedo ayudarte hoy?"
```

### 5. Parseo de Respuesta

Se extraen:
- `intent`: Tipo de intención
- `response`: Respuesta generada

### 6. Switch por Intención

El nodo Switch dirige el flujo según la intención:
- `saludo` → Enviar respuesta
- `pregunta_producto` → Enviar respuesta
- `otro` → Enviar respuesta

**Nota**: En el plan Básico, todas las intenciones solo envían la respuesta sin consultar base de datos.

### 7. Envío de Respuesta

**Request a WhatsApp Cloud API:**
```json
POST https://graph.facebook.com/v21.0/{PHONE_NUMBER_ID}/messages
{
  "messaging_product": "whatsapp",
  "to": "5491122334455",
  "type": "text",
  "text": {
    "body": "¡Hola! 👋 Bienvenido a nuestra tienda. ¿En qué puedo ayudarte hoy?"
  }
}
```

### 8. Respuesta al Webhook

Se responde al webhook de WhatsApp con:
```json
{
  "success": true,
  "message": "Message processed"
}
```

## 📊 Diagrama de Flujo

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │ Mensaje
       ↓
┌─────────────┐
│  WhatsApp   │
│  Cloud API  │
└──────┬──────┘
       │ Webhook
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
│ Formatear   │
│ TON Input   │
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
│   Parsear   │
│ Respuesta   │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Switch    │
│  Intención  │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Enviar    │
│  WhatsApp   │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Responder  │
│  Webhook    │
└─────────────┘
```

## 🎨 Intenciones Soportadas

### 1. `saludo`
**Ejemplos de entrada:**
- "Hola"
- "Buenos días"
- "Hola, necesito ayuda"

**Respuesta típica:**
```
¡Hola! 👋 Bienvenido a nuestra tienda. 
¿En qué puedo ayudarte hoy?
```

### 2. `pregunta_producto`
**Ejemplos de entrada:**
- "Tienen iPhone?"
- "Quiero ver productos"
- "Qué productos tienen?"

**Respuesta típica:**
```
¡Sí! Tenemos iPhone 15 Pro disponible. 
Precio: $1299.99. ¿Te interesa?
```

### 3. `otro`
**Ejemplos de entrada:**
- "Cuánto cuesta"
- "Información"
- Cualquier mensaje no reconocido

**Respuesta típica:**
```
Para darte el precio exacto, necesito saber 
qué producto te interesa. ¿Podrías decirme cuál?
```

## ⚙️ Configuración

### Variables de Entorno Requeridas

```bash
WHATSAPP_PHONE_NUMBER_ID=123456789
WHATSAPP_ACCESS_TOKEN=xxx
OPENAI_API_KEY=sk-xxx
```

### Credenciales n8n

1. **OpenAI API**: Configurar credencial con API key
2. **WhatsApp Cloud API**: Configurar HTTP Header Auth con token

## 📝 Notas Importantes

- ⚠️ El plan Básico **NO** consulta la base de datos
- ⚠️ Las respuestas son **genéricas** (no personalizadas)
- ⚠️ **NO** hay gestión de carrito ni pedidos
- ✅ Ideal para respuestas automáticas básicas
- ✅ Bajo costo de operación

## 🔄 Ejemplo Completo

**Mensaje del Cliente:**
```
"Hola, quiero ver productos"
```

**Procesamiento:**
1. Webhook recibe mensaje
2. Normaliza: `text:"hola quiero ver productos"`
3. OpenAI interpreta: `intent:"pregunta_producto"`
4. Genera respuesta: "¡Sí! Tenemos varios productos disponibles..."
5. Envía por WhatsApp
6. Cliente recibe respuesta automática

## 🚀 Próximos Pasos

Para funcionalidades avanzadas, considera:
- **Plan Pro**: Carrito y pedidos
- **Plan Full**: Mensajes salientes y marketing

