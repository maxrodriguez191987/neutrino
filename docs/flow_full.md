# Flujo Plan Full

## 📋 Descripción

El plan Full incluye todas las funcionalidades de los planes Básico y Pro, más mensajes salientes automáticos, campañas de marketing y gestión avanzada de carritos abandonados.

## 🎯 Funcionalidades

- ✅ Todas las del plan Pro
- ✅ Mensajes salientes automáticos
- ✅ Carritos abandonados (cron diario)
- ✅ Ofertas semanales (cron semanal)
- ✅ Mensajes de marketing personalizados
- ✅ Plantillas de WhatsApp

## 🔄 Flujos Detallados

### Flujo 1: Mensajes Entrantes (Igual que Pro)

Similar al plan Pro, pero con intenciones adicionales:
- `carrito_abandonado`
- `oferta_personalizada`
- `mensaje_marketing`

### Flujo 2: Carritos Abandonados (Cron Diario)

```
Cron Trigger (9:00 AM diario)
    ↓
Obtener Carritos Abandonados (Supabase)
    ↓
Para cada carrito:
    ↓
Generar Mensaje Personalizado (OpenAI)
    ↓
Enviar WhatsApp Template
```

**Consulta de Carritos Abandonados:**
```sql
SELECT c.*, cu.phone, cu.name
FROM carts c
INNER JOIN customers cu ON c.customer_id = cu.id
WHERE c.updated_at < NOW() - INTERVAL '3 days'
  AND c.items != '[]'::jsonb
  AND cu.plan = 'full'
ORDER BY c.updated_at ASC;
```

**Mensaje Generado:**
```
👋 ¡Hola {nombre}! Notamos que tienes productos 
en tu carrito esperando. ¿Te gustaría completar 
tu compra? Tenemos ofertas especiales disponibles.
```

**Envío con Template:**
```json
{
  "messaging_product": "whatsapp",
  "to": "5491122334455",
  "type": "template",
  "template": {
    "name": "abandoned_cart_reminder",
    "language": { "code": "es" },
    "components": [{
      "type": "body",
      "parameters": [{
        "type": "text",
        "text": "iPhone 15 Pro, AirPods Pro 2"
      }]
    }]
  }
}
```

### Flujo 3: Ofertas Semanales (Cron Semanal)

```
Cron Trigger (Lunes 10:00 AM)
    ↓
Obtener Clientes Full (Supabase)
    ↓
Obtener Productos en Oferta
    ↓
Para cada cliente:
    ↓
Generar Oferta Personalizada (OpenAI)
    ↓
Enviar WhatsApp Template
```

**Consulta de Clientes:**
```sql
SELECT id, phone, name
FROM customers
WHERE plan = 'full'
ORDER BY created_at DESC;
```

**Mensaje Generado:**
```
🎁 ¡Oferta especial de la semana! 
iPhone 15 Pro con 10% de descuento. 
Solo por tiempo limitado. ¿Te interesa?
```

### Flujo 4: Mensajes de Marketing

Similar a ofertas semanales, pero con productos destacados o nuevos lanzamientos.

## 📊 Diagrama de Flujos

### Flujo Entrante
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
[Proceso igual que Pro]
```

### Flujo Saliente - Carritos Abandonados
```
┌─────────────┐
│ Cron Diario │
│  (9:00 AM)  │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Obtener     │
│ Carritos    │
│ Abandonados │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Loop      │
│  (Split)    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   OpenAI    │
│  Generar    │
│  Mensaje    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Enviar    │
│  Template   │
│  WhatsApp   │
└─────────────┘
```

### Flujo Saliente - Ofertas Semanales
```
┌─────────────┐
│ Cron Semanal│
│ (Lun 10 AM) │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Obtener     │
│ Clientes    │
│   Full      │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Obtener     │
│ Productos   │
│  Oferta     │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Loop      │
│  (Split)    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   OpenAI    │
│  Generar    │
│  Oferta     │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Enviar    │
│  Template   │
│  WhatsApp   │
└─────────────┘
```

## 🗄️ Tabla de Campañas

```sql
CREATE TABLE campaigns (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    campaign_type VARCHAR(50),  -- 'abandoned_cart', 'weekly_offer', 'marketing'
    template_name VARCHAR(255),
    target_customers JSONB,
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    status VARCHAR(50),  -- 'draft', 'scheduled', 'sent', 'failed'
    metadata JSONB
);
```

## 📱 Plantillas de WhatsApp

### Requisitos
- Las plantillas deben estar aprobadas por Meta
- Formato específico requerido
- Límites de envío según plan de WhatsApp

### Ejemplo de Template: `abandoned_cart_reminder`

**Categoría:** UTILITY

**Cuerpo:**
```
Hola {{1}}, notamos que tienes productos en tu carrito: {{2}}
¿Te gustaría completar tu compra?
```

**Parámetros:**
1. Nombre del cliente
2. Lista de productos

### Ejemplo de Template: `weekly_offer`

**Categoría:** MARKETING

**Cuerpo:**
```
🎁 ¡Oferta especial de la semana!
{{1}} con {{2}}% de descuento.
Solo por tiempo limitado.
```

**Parámetros:**
1. Nombre del producto
2. Porcentaje de descuento

## 🤖 Generación de Mensajes con IA

### Para Carritos Abandonados

**Prompt:**
```
Genera un mensaje para {nombre} recordándole que tiene 
productos en su carrito:
- iPhone 15 Pro ($1299.99)
- AirPods Pro 2 ($249.99)

Mensaje amigable y con sentido de urgencia.
```

**Output:**
```
👋 ¡Hola Juan! Notamos que tienes productos en tu carrito 
esperando. ¿Te gustaría completar tu compra? 
Tenemos ofertas especiales disponibles.
```

### Para Ofertas Semanales

**Prompt:**
```
Genera un mensaje de oferta semanal para {nombre} con 
estos productos:
- iPhone 15 Pro ($1299.99)
- MacBook Pro M3 ($1999.99)

Mensaje promocional atractivo.
```

**Output:**
```
🎁 ¡Oferta especial de la semana, Juan! 
iPhone 15 Pro y MacBook Pro M3 con descuentos exclusivos. 
¡No te lo pierdas!
```

## ⚙️ Configuración de Cron Jobs

### Cron Diario (Carritos Abandonados)

**Configuración n8n:**
```json
{
  "rule": {
    "interval": [{
      "field": "days",
      "hours": {
        "hour": 9,
        "minute": 0
      }
    }]
  }
}
```

**Horario:** Todos los días a las 9:00 AM

### Cron Semanal (Ofertas)

**Configuración n8n:**
```json
{
  "rule": {
    "interval": [{
      "field": "weeks",
      "weeks": {
        "weekday": 1,  // Lunes
        "hour": 10,
        "minute": 0
      }
    }]
  }
}
```

**Horario:** Todos los lunes a las 10:00 AM

## 📊 Métricas y Seguimiento

### Tabla de Mensajes (Log)

```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY,
    customer_id UUID,
    phone VARCHAR(20),
    direction VARCHAR(10),  -- 'inbound', 'outbound'
    message_type VARCHAR(20),
    content TEXT,
    ton_data JSONB,
    intent VARCHAR(100),
    response_sent BOOLEAN,
    created_at TIMESTAMP
);
```

### Consultas Útiles

**Mensajes enviados hoy:**
```sql
SELECT COUNT(*) 
FROM messages 
WHERE direction = 'outbound' 
  AND DATE(created_at) = CURRENT_DATE;
```

**Tasa de respuesta a carritos abandonados:**
```sql
SELECT 
  COUNT(DISTINCT m.customer_id) as sent,
  COUNT(DISTINCT o.customer_id) as converted
FROM messages m
LEFT JOIN orders o ON m.customer_id = o.customer_id
WHERE m.intent = 'carrito_abandonado'
  AND m.created_at >= NOW() - INTERVAL '7 days'
  AND o.created_at >= m.created_at;
```

## 🎨 Ejemplos de Campañas

### Campaña 1: Carrito Abandonado

**Trigger:** 3 días sin actividad
**Target:** Clientes con carrito no vacío
**Mensaje:** Recordatorio amigable
**Template:** `abandoned_cart_reminder`

### Campaña 2: Oferta Semanal

**Trigger:** Lunes 10:00 AM
**Target:** Todos los clientes Full
**Mensaje:** Productos destacados con descuento
**Template:** `weekly_offer`

### Campaña 3: Nuevo Lanzamiento

**Trigger:** Manual o programado
**Target:** Clientes Full interesados en categoría
**Mensaje:** Anuncio de nuevo producto
**Template:** `new_product_announcement`

## ⚙️ Configuración Completa

### Variables de Entorno

```bash
# WhatsApp
WHATSAPP_PHONE_NUMBER_ID=123456789
WHATSAPP_ACCESS_TOKEN=xxx
WHATSAPP_VERIFY_TOKEN=xxx

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx

# OpenAI
OPENAI_API_KEY=sk-xxx

# n8n
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=xxx
```

### Configuración de Templates

1. Crear templates en Meta Business Manager
2. Esperar aprobación (puede tardar horas/días)
3. Configurar nombres en workflows n8n
4. Probar con número de prueba

## 📝 Notas Importantes

- ⚠️ Los mensajes salientes requieren templates aprobados
- ⚠️ Límites de envío según plan de WhatsApp
- ✅ Personalización con IA para cada cliente
- ✅ Seguimiento completo de campañas
- ✅ Métricas de conversión

## 🚀 Optimizaciones

### Rate Limiting
- Limitar envíos a X por minuto
- Usar cola de mensajes
- Implementar retry logic

### Personalización
- Usar historial de compras
- Segmentar por categorías de interés
- A/B testing de mensajes

### Monitoreo
- Alertas de fallos
- Dashboard de métricas
- Logs detallados

