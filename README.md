# 🚀 WhatsApp Sales Automation SaaS

Sistema completo de automatización de ventas por WhatsApp usando n8n, WhatsApp Cloud API, OpenAI y Supabase.

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Cómo Funciona el Sistema (End-to-End)](#-cómo-funciona-el-sistema-end-to-end)
- [Arquitectura](#-arquitectura)
- [Planes](#-planes)
- [Tecnologías](#-tecnologías)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Uso](#-uso)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Documentación](#-documentación)
- [Contribuir](#-contribuir)

## ✨ Características

- 🤖 **Automatización Inteligente**: Respuestas automáticas usando IA (OpenAI)
- 💬 **WhatsApp Cloud API**: Integración completa con Meta
- 🛒 **Gestión de Carrito**: Agregar, consultar y gestionar carritos
- 📦 **Gestión de Pedidos**: Crear y rastrear pedidos
- 📊 **Base de Datos**: Supabase PostgreSQL con API REST
- 🔄 **Workflows n8n**: Automatización visual sin código
- 📱 **Mensajes Salientes**: Campañas automáticas (plan Full)
- 🎯 **TON Notation**: Formato eficiente para reducir tokens
- 🔧 **Webhook Profesional**: Edge Function de Supabase para recepción de mensajes

## 🔄 Cómo Funciona el Sistema (End-to-End)

### Visión General del Flujo Completo

El sistema funciona como un SaaS completo que automatiza completamente la comunicación por WhatsApp, desde la recepción de mensajes hasta la respuesta inteligente y el almacenamiento de datos.

```
┌─────────────┐
│   Cliente   │
│  WhatsApp   │
└──────┬──────┘
       │
       │ 1. Envía mensaje
       │    "Hola, quiero ver productos"
       ↓
┌─────────────────────────────────────┐
│   WhatsApp Cloud API (Meta)         │
│   - Recibe mensaje del cliente     │
│   - Valida número y permisos       │
└──────┬──────────────────────────────┘
       │
       │ 2. Webhook POST
       │    (con payload del mensaje)
       ↓
┌─────────────────────────────────────┐
│   Supabase Edge Function            │
│   (whatsapp-webhook)                │
│   - Verifica webhook (GET)          │
│   - Recibe mensajes (POST)          │
│   - Guarda en Supabase              │
│   - Responde automáticamente        │
└──────┬──────────────────────────────┘
       │
       │ 3. Guarda datos
       ↓
┌─────────────────────────────────────┐
│   Supabase Database                 │
│   - customers (crea/actualiza)       │
│   - messages (guarda mensaje)       │
│   - carts (si aplica)               │
└─────────────────────────────────────┘
       │
       │ 4. (Opcional) Integración n8n
       │    Para procesamiento avanzado
       ↓
┌─────────────────────────────────────┐
│   n8n Workflow (Opcional)           │
│   - Normaliza a TON                 │
│   - Consulta OpenAI                  │
│   - Procesa intención               │
│   - Consulta Supabase               │
│   - Genera respuesta inteligente    │
└──────┬──────────────────────────────┘
       │
       │ 5. Envía respuesta
       ↓
┌─────────────────────────────────────┐
│   WhatsApp Cloud API                │
│   - Envía mensaje al cliente        │
└──────┬──────────────────────────────┘
       │
       │ 6. Cliente recibe respuesta
       ↓
┌─────────────┐
│   Cliente   │
│  WhatsApp   │
└─────────────┘
```

### Flujo Detallado Paso a Paso

#### **Paso 1: Cliente Envía Mensaje**

El cliente envía un mensaje desde su WhatsApp al número de negocio (ej: `+1 555 165 1361`).

**Ejemplo:**
```
Cliente: "Hola, quiero ver productos"
```

#### **Paso 2: WhatsApp Cloud API Recibe el Mensaje**

Meta (WhatsApp Cloud API) recibe el mensaje y lo procesa:
- Valida que el número esté autorizado
- Verifica permisos del negocio
- Prepara el webhook para enviar a tu servidor

**Payload del Webhook:**
```json
{
  "entry": [{
    "changes": [{
      "value": {
        "messages": [{
          "from": "5491165820938",
          "id": "wamid.xxx",
          "timestamp": "1234567890",
          "text": {
            "body": "Hola, quiero ver productos"
          },
          "type": "text"
        }],
        "contacts": [{
          "profile": {
            "name": "Juan Pérez"
          },
          "wa_id": "5491165820938"
        }]
      }
    }]
  }]
}
```

#### **Paso 3: Supabase Edge Function Procesa el Webhook**

La Edge Function `whatsapp-webhook` en Supabase recibe el webhook:

**3.1. Verificación (GET) - Solo la primera vez:**
```
Meta → GET /functions/v1/whatsapp-webhook?hub.mode=subscribe&hub.verify_token=xxx&hub.challenge=123
Edge Function → Responde con el challenge (123)
Meta → ✅ Webhook verificado
```

**3.2. Recepción de Mensaje (POST):**
```typescript
// supabase/functions/whatsapp-webhook/index.ts

1. Recibe el payload del webhook
2. Extrae información:
   - from: "5491165820938"
   - text: "Hola, quiero ver productos"
   - name: "Juan Pérez"
   - wa_id: "5491165820938"

3. Conecta a Supabase:
   - Busca cliente por teléfono
   - Si no existe, crea nuevo cliente (plan: "basic")
   - Guarda mensaje en tabla `messages`

4. Genera respuesta automática:
   - Analiza el texto
   - Responde según palabras clave:
     * "hola" → "¡Hola! 👋 Bienvenido..."
     * "precio" → "Nuestros precios..."
     * "comprar" → "Perfecto! ¿Qué producto..."
     * "producto" → "Tenemos varios productos..."

5. Envía respuesta usando WhatsApp Cloud API:
   - POST https://graph.facebook.com/v21.0/{PHONE_ID}/messages
   - Con Access Token y payload del mensaje
```

#### **Paso 4: Almacenamiento en Supabase**

Los datos se guardan automáticamente:

**Tabla `customers`:**
```sql
INSERT INTO customers (phone, name, wa_id, plan)
VALUES ('5491165820938', 'Juan Pérez', '5491165820938', 'basic')
ON CONFLICT (phone) DO UPDATE SET name = EXCLUDED.name;
```

**Tabla `messages`:**
```sql
INSERT INTO messages (customer_id, phone, direction, message_type, content, ton_data)
VALUES (
  'uuid-del-cliente',
  '5491165820938',
  'inbound',
  'text',
  'Hola, quiero ver productos',
  '{"text": "hola quiero ver productos", "from": "5491165820938", "wa_id": "5491165820938"}'
);
```

#### **Paso 5: (Opcional) Procesamiento Avanzado con n8n**

Si tienes n8n configurado, puedes agregar procesamiento avanzado:

**5.1. Webhook de n8n recibe notificación:**
- n8n puede escuchar eventos de Supabase (Database Webhooks)
- O puede ser llamado directamente desde la Edge Function

**5.2. Normalización a TON:**
```typescript
// Convierte mensaje a formato TON
text:"hola quiero ver productos"
from:"5491165820938"
wa_id:"5491165820938"
```

**5.3. Consulta a OpenAI:**
```typescript
// Envía TON a OpenAI con prompt del plan
const response = await openai.chat.completions.create({
  model: "gpt-4o-mini",
  messages: [
    { role: "system", content: promptPro }, // Prompt del plan Pro
    { role: "user", content: tonInput }
  ]
});

// Respuesta TON:
intent:"pregunta_producto"
product_query:"productos"
response:"Tenemos varios productos disponibles..."
```

**5.4. Procesamiento según Intención:**
- `saludo` → Respuesta de bienvenida
- `pregunta_producto` → Consulta productos en Supabase
- `agregar_carrito` → Agrega producto al carrito
- `consultar_carrito` → Muestra carrito del cliente
- `confirmar_pedido` → Crea pedido desde carrito

**5.5. Consulta a Supabase (si necesario):**
```sql
-- Ejemplo: Buscar productos
SELECT * FROM products 
WHERE name ILIKE '%producto%' 
LIMIT 5;

-- Ejemplo: Agregar al carrito
SELECT add_to_cart(
  p_customer_id := 'uuid',
  p_product_id := 'uuid',
  p_quantity := 1
);
```

**5.6. Genera Respuesta Final:**
- Combina datos de Supabase con respuesta de IA
- Formatea mensaje para WhatsApp
- Envía respuesta al cliente

#### **Paso 6: Cliente Recibe Respuesta**

El cliente recibe la respuesta en su WhatsApp:

```
Sistema: "¡Hola! 👋 Bienvenido. ¿Qué estás buscando?"
```

### Flujo de Mensajes Salientes (Solo Plan Full)

Para mensajes salientes (campañas, carritos abandonados, ofertas):

```
┌─────────────────────┐
│  Cron Job (n8n)     │
│  - Diario: Carritos │
│  - Semanal: Ofertas │
└──────────┬──────────┘
           │
           │ 1. Consulta Supabase
           ↓
┌─────────────────────┐
│  Supabase Query     │
│  - Carritos         │
│  - Clientes Full    │
└──────────┬──────────┘
           │
           │ 2. Genera mensaje (OpenAI)
           ↓
┌─────────────────────┐
│  OpenAI             │
│  - Personaliza      │
│  - Genera texto     │
└──────────┬──────────┘
           │
           │ 3. Envía por WhatsApp
           ↓
┌─────────────────────┐
│  WhatsApp Template  │
│  - Mensaje masivo   │
└──────────┬──────────┘
           │
           │ 4. Cliente recibe
           ↓
┌─────────────────────┐
│  Cliente WhatsApp   │
└─────────────────────┘
```

### Ejemplo Completo: Cliente Agrega Producto al Carrito

**1. Cliente envía:**
```
"Quiero agregar iPhone al carrito"
```

**2. Webhook llega a Edge Function:**
- Guarda mensaje en Supabase
- Detecta palabra "comprar" o "agregar"
- Responde automáticamente: "Perfecto! ¿Qué producto..."

**3. (Si n8n está activo) n8n procesa:**
- Normaliza a TON: `text:"quiero agregar iphone al carrito"`
- OpenAI interpreta: `intent:"agregar_carrito"`, `product_query:"iphone"`
- Busca producto en Supabase: `SELECT * FROM products WHERE name ILIKE '%iphone%'`
- Agrega al carrito: `SELECT add_to_cart(...)`
- Genera respuesta: "✅ iPhone 15 Pro agregado a tu carrito..."

**4. Cliente recibe:**
```
"✅ iPhone 15 Pro agregado a tu carrito. 
¿Quieres ver tu carrito o agregar algo más?"
```

### Componentes Clave del Sistema

#### **1. Supabase Edge Function (whatsapp-webhook)**
- **Ubicación**: `supabase/functions/whatsapp-webhook/index.ts`
- **Responsabilidades**:
  - Verificar webhook de Meta (GET)
  - Recibir mensajes entrantes (POST)
  - Guardar clientes y mensajes en Supabase
  - Responder automáticamente (básico)
  - Preparar datos para n8n (opcional)

#### **2. Supabase Database**
- **Tablas principales**:
  - `customers`: Información de clientes
  - `messages`: Historial de mensajes
  - `products`: Catálogo de productos
  - `carts`: Carritos de compra
  - `orders`: Pedidos confirmados
  - `campaigns`: Campañas de marketing

#### **3. n8n Workflows (Opcional pero Recomendado)**
- **Ubicación**: `workflows/basic.json`, `pro.json`, `full.json`
- **Funcionalidades**:
  - Normalización a TON
  - Integración con OpenAI
  - Lógica de negocio avanzada
  - Cron jobs para mensajes salientes

#### **4. WhatsApp Cloud API**
- **Endpoints usados**:
  - `POST /v21.0/{PHONE_ID}/messages`: Enviar mensajes
  - Webhook: Recibir mensajes entrantes

#### **5. OpenAI API**
- **Uso**: Interpretación de intenciones y generación de respuestas
- **Modelo**: GPT-4o-mini (eficiente y económico)
- **Formato**: TON (Tree Object Notation) para reducir tokens

## 🏗️ Arquitectura

```
WhatsApp Cloud API → Supabase Edge Function → Supabase DB
         ↑                    ↓
         │              (Opcional) n8n → OpenAI
         └────────── Respuesta ─────────┘
```

### Componentes Principales

1. **WhatsApp Cloud API**: Recepción y envío de mensajes
2. **Supabase Edge Function**: Webhook profesional para recibir mensajes
3. **Supabase Database**: Almacenamiento de datos
4. **n8n**: Motor de workflows y automatización (opcional)
5. **OpenAI**: Interpretación de intenciones y generación de respuestas
6. **TON**: Formato de normalización para comunicación eficiente

Ver [docs/architecture.md](docs/architecture.md) para más detalles.

## 📦 Planes

### 🟢 Plan Básico
- Respuestas automáticas a saludos
- Consultas de productos
- Respuestas genéricas
- Guardado básico en Supabase

### 🟡 Plan Pro
- ✅ Todo lo del plan Básico
- ✅ Gestión de carrito
- ✅ Consultar carrito
- ✅ Confirmar pedidos
- ✅ Integración completa con Supabase

### 🔴 Plan Full
- ✅ Todo lo del plan Pro
- ✅ Mensajes salientes automáticos
- ✅ Carritos abandonados (cron diario)
- ✅ Ofertas semanales (cron semanal)
- ✅ Mensajes de marketing personalizados
- ✅ Plantillas de WhatsApp

## 🛠️ Tecnologías

- **Supabase Edge Functions**: Webhook profesional (Deno)
- **WhatsApp Cloud API**: Comunicación por WhatsApp
- **n8n**: Automatización y workflows (opcional)
- **OpenAI (GPT-4o-mini)**: Inteligencia artificial
- **Supabase**: Base de datos PostgreSQL + API REST
- **TypeScript/Node.js**: Servicios y utilidades
- **TON (Tree Object Notation)**: Formato de normalización

## ⚡ Inicio Rápido

### Levantar el Proyecto

```bash
# 1. Configurar variables de entorno
./scripts/setup-env.sh

# 2. Configurar Supabase
# Ejecutar schema.sql y functions.sql en Supabase SQL Editor

# 3. Deployar Edge Function
supabase functions deploy whatsapp-webhook --no-verify-jwt

# 4. Configurar secrets
supabase secrets set WHATSAPP_ACCESS_TOKEN=xxx WHATSAPP_PHONE_NUMBER_ID=xxx WHATSAPP_VERIFY_TOKEN=xxx

# 5. Configurar webhook en Meta Business
# URL: https://{PROJECT_ID}.supabase.co/functions/v1/whatsapp-webhook
# Verify Token: (el configurado en secrets)
```

### Guías Disponibles

- **[SETUP.md](SETUP.md)** - Guía completa para levantar el proyecto
- **[QUICK_START.md](QUICK_START.md)** - Inicio rápido (5 pasos)
- **[TESTING.md](TESTING.md)** - Guía de pruebas detallada
- **[WHATSAPP_SETUP.md](WHATSAPP_SETUP.md)** - Configuración de WhatsApp

## 🚀 Instalación

### Prerrequisitos

- Node.js 20+ (requerido por Supabase, ver [NODE_VERSION.md](NODE_VERSION.md))
- Cuenta de Meta Business (WhatsApp Cloud API)
- Cuenta de Supabase
- Cuenta de OpenAI (opcional, para IA avanzada)
- Instancia de n8n (opcional, para workflows avanzados)

### 1. Clonar Repositorio

```bash
git clone https://github.com/tu-usuario/whatsapp-sales-automation.git
cd whatsapp-sales-automation
```

### 2. Configurar Supabase

```bash
# Ejecutar schema en Supabase SQL Editor
# Archivo: supabase/schema.sql

# Ejecutar functions (opcional, para funcionalidades avanzadas)
# Archivo: supabase/functions.sql

# O usar el SQL Editor en el dashboard de Supabase
```

### 3. Deployar Edge Function

```bash
# Deployar webhook
supabase functions deploy whatsapp-webhook --no-verify-jwt

# Configurar secrets
supabase secrets set \
  WHATSAPP_ACCESS_TOKEN=tu_token \
  WHATSAPP_PHONE_NUMBER_ID=tu_phone_id \
  WHATSAPP_VERIFY_TOKEN=tu_verify_token
```

### 4. Configurar WhatsApp Cloud API

1. Crear app en [Meta for Developers](https://developers.facebook.com/)
2. Configurar WhatsApp Business API
3. Obtener Phone Number ID y Access Token
4. Configurar webhook en Meta Business:
   - URL: `https://{PROJECT_ID}.supabase.co/functions/v1/whatsapp-webhook`
   - Verify Token: (el configurado en secrets)
   - Suscribirse a eventos: `messages`

### 5. (Opcional) Configurar n8n

1. Importar workflows:
   - `workflows/basic.json`
   - `workflows/pro.json`
   - `workflows/full.json`

2. Configurar variables de entorno en n8n:
   ```bash
   WHATSAPP_PHONE_NUMBER_ID=xxx
   WHATSAPP_ACCESS_TOKEN=xxx
   SUPABASE_URL=https://xxx.supabase.co
   SUPABASE_ANON_KEY=xxx
   OPENAI_API_KEY=sk-xxx
   ```

## ⚙️ Configuración

### Variables de Entorno

Crear archivo `.env`:

```bash
# WhatsApp
WHATSAPP_PHONE_NUMBER_ID=123456789
WHATSAPP_ACCESS_TOKEN=xxx
WHATSAPP_VERIFY_TOKEN=xxx
WHATSAPP_BUSINESS_ACCOUNT_ID=xxx

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx

# OpenAI (opcional)
OPENAI_API_KEY=sk-xxx

# n8n (si self-hosted)
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=xxx
```

### Configurar Webhooks

1. Obtener URL del webhook de Supabase:
   ```
   https://{PROJECT_ID}.supabase.co/functions/v1/whatsapp-webhook
   ```

2. Configurar en Meta Business Manager:
   - Settings → WhatsApp → Configuration
   - Webhook URL: (la URL de arriba)
   - Verify Token: (el configurado en secrets)

### Configurar Templates (Solo Plan Full)

1. Crear templates en Meta Business Manager
2. Esperar aprobación (puede tardar horas)
3. Actualizar nombres en workflows n8n

## 📖 Uso

### Activar Sistema

1. **Edge Function ya está activa** (se deploya automáticamente)
2. **Verificar webhook en Meta Business** (debe estar verificado)
3. **(Opcional) Activar workflows en n8n**

### Flujo Básico

1. Cliente envía mensaje por WhatsApp
2. Webhook recibe en Supabase Edge Function
3. Mensaje se guarda en Supabase
4. Cliente se crea/actualiza automáticamente
5. Respuesta automática se envía (básica)
6. (Opcional) n8n procesa para respuesta avanzada con IA

### Ejemplos de Mensajes

**Saludo:**
```
Cliente: "Hola"
Sistema: "¡Hola! 👋 Bienvenido. ¿Qué estás buscando?"
```

**Agregar al Carrito (con n8n):**
```
Cliente: "Quiero agregar iPhone al carrito"
Sistema: "✅ iPhone 15 Pro agregado a tu carrito..."
```

**Consultar Carrito (con n8n):**
```
Cliente: "Ver mi carrito"
Sistema: "🛒 Tu carrito: ..."
```

## 📁 Estructura del Proyecto

```
whatsapp-sales-automation/
├── supabase/
│   ├── functions/
│   │   └── whatsapp-webhook/
│   │       └── index.ts          # Edge Function principal
│   ├── schema.sql                 # Esquema de base de datos
│   ├── seed.sql                   # Datos de ejemplo
│   └── functions.sql              # Funciones RPC
├── workflows/                     # Workflows n8n (opcional)
│   ├── basic.json
│   ├── pro.json
│   └── full.json
├── src/                           # Código TypeScript (opcional)
│   ├── utils/
│   │   ├── ton.ts
│   │   ├── whatsapp.ts
│   │   └── supabase.ts
│   └── services/
│       ├── ai.service.ts
│       ├── whatsapp.service.ts
│       ├── cart.service.ts
│       └── orders.service.ts
├── prompts/                       # Prompts para IA
│   ├── ia_basic.ton.txt
│   ├── ia_pro.ton.txt
│   └── ia_full.ton.txt
├── docs/                          # Documentación
│   ├── architecture.md
│   ├── flow_basic.md
│   ├── flow_pro.md
│   ├── flow_full.md
│   └── endpoints.md
├── scripts/                       # Scripts de utilidad
│   ├── setup-env.sh
│   ├── test-webhook.sh
│   ├── quick-test-whatsapp.sh
│   └── deploy-whatsapp-webhook.sh
├── dashboard/                     # Dashboard Next.js (opcional)
└── README.md
```

## 📚 Documentación

- [Arquitectura](docs/architecture.md): Visión general del sistema
- [Flujo Básico](docs/flow_basic.md): Plan Básico detallado
- [Flujo Pro](docs/flow_pro.md): Plan Pro detallado
- [Flujo Full](docs/flow_full.md): Plan Full detallado
- [Endpoints](docs/endpoints.md): Documentación de APIs
- [WhatsApp Setup](WHATSAPP_SETUP.md): Guía de configuración de WhatsApp

## 🧪 Testing

### Probar Webhook

```bash
# Probar verificación
./scripts/test-webhook.sh

# Probar envío de mensaje
./scripts/quick-test-whatsapp.sh TU_NUMERO

# Probar recepción
# Envía un mensaje desde tu WhatsApp al número de prueba
```

### Verificar en Supabase

```sql
-- Ver mensajes recibidos
SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;

-- Ver clientes creados
SELECT * FROM customers ORDER BY created_at DESC LIMIT 10;
```

## 🚨 Troubleshooting

### Webhook no recibe mensajes

- Verificar URL en Meta Business Manager
- Verificar Verify Token en secrets
- Revisar logs de Supabase Edge Functions
- Verificar que el webhook esté verificado en Meta

### Mensajes no se guardan en Supabase

- Verificar SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en secrets
- Revisar logs de Edge Function
- Verificar que las tablas existan (ejecutar schema.sql)

### Respuestas automáticas no funcionan

- Verificar WHATSAPP_ACCESS_TOKEN y WHATSAPP_PHONE_NUMBER_ID en secrets
- Revisar logs de Edge Function
- Verificar que el token no haya expirado

### OpenAI no responde (si usas n8n)

- Verificar API Key
- Revisar límites de rate
- Verificar formato TON

## 📝 Licencia

MIT License - ver [LICENSE](LICENSE) para más detalles.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/tu-usuario/whatsapp-sales-automation/issues)
- **Documentación**: Ver carpeta `docs/`
- **Email**: soporte@ejemplo.com

## 🎯 Roadmap

- [x] Webhook profesional con Supabase Edge Functions
- [x] Respuestas automáticas básicas
- [x] Integración completa con Supabase
- [ ] Dashboard web para gestión
- [ ] Analytics y métricas
- [ ] Integración con pasarelas de pago
- [ ] Multi-idioma
- [ ] Integración con otros canales (Telegram, etc.)

## 🙏 Agradecimientos

- Supabase por la infraestructura de Edge Functions
- Meta por WhatsApp Cloud API
- n8n por la plataforma de automatización
- OpenAI por la API de IA

---

**Hecho con ❤️ para automatizar ventas por WhatsApp**
