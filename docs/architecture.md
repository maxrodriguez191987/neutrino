# Arquitectura del Sistema

## 📐 Visión General

Este SaaS de automatización de ventas por WhatsApp utiliza una arquitectura modular basada en microservicios, diseñada para escalar horizontalmente y mantener una separación clara de responsabilidades.

## 🏗️ Componentes Principales

### 1. **WhatsApp Cloud API (Meta)**
- **Rol**: Punto de entrada y salida de mensajes
- **Funcionalidad**:
  - Recibe webhooks de mensajes entrantes
  - Envía mensajes de texto y plantillas
  - Gestiona la comunicación bidireccional

### 2. **n8n (Motor de Automatización)**
- **Rol**: Orquestador principal de workflows
- **Funcionalidad**:
  - Procesa mensajes entrantes
  - Ejecuta lógica de negocio
  - Coordina llamadas a servicios externos
  - Gestiona tareas programadas (cron jobs)

### 3. **OpenAI (IA)**
- **Rol**: Interpretación de intenciones y generación de respuestas
- **Funcionalidad**:
  - Analiza mensajes usando TON
  - Identifica intenciones del cliente
  - Genera respuestas contextuales
  - Crea mensajes de marketing personalizados

### 4. **Supabase (Backend y Base de Datos)**
- **Rol**: Almacenamiento y lógica de datos
- **Funcionalidad**:
  - Base de datos PostgreSQL
  - API REST automática
  - Autenticación (opcional)
  - Funciones almacenadas (RPC)

### 5. **TON (Tree Object Notation)**
- **Rol**: Formato de normalización y comunicación
- **Funcionalidad**:
  - Normaliza mensajes de WhatsApp
  - Reduce tokens en llamadas a IA
  - Facilita parsing y procesamiento

## 🔄 Flujo de Datos

### Flujo Entrante (Mensajes del Cliente)

```
WhatsApp Cloud API
    ↓ (Webhook POST)
n8n Webhook Node
    ↓ (Normalización)
TON Converter
    ↓ (Formato TON)
OpenAI API
    ↓ (Interpretación)
Intent Parser
    ↓ (Switch por Intención)
Supabase (Consultas/Updates)
    ↓ (Respuesta Generada)
WhatsApp Cloud API
    ↓ (Mensaje al Cliente)
Cliente
```

### Flujo Saliente (Solo Plan Full)

```
Cron Trigger (n8n)
    ↓
Supabase Query
    ↓ (Carritos Abandonados / Clientes Full)
OpenAI (Generación de Mensaje)
    ↓ (Mensaje Personalizado)
WhatsApp Template API
    ↓ (Envío Masivo)
Clientes
```

## 📊 Diagrama de Arquitectura

```
┌─────────────────┐
│  WhatsApp Cloud │
│      API        │
└────────┬────────┘
         │
         │ Webhook
         ↓
┌─────────────────┐
│   n8n Workflow  │
│                 │
│  ┌───────────┐  │
│  │ Normalizar│  │
│  │   a TON   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │  OpenAI   │  │
│  │  (GPT-4o) │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │  Supabase │  │
│  │   Query   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │  Respuesta│  │
│  │  WhatsApp │  │
│  └───────────┘  │
└─────────────────┘
         │
         │ HTTP Request
         ↓
┌─────────────────┐
│  Supabase DB    │
│  (PostgreSQL)   │
└─────────────────┘
```

## 🧩 Módulos del Sistema

### 1. **Módulo de Normalización (TON)**
- **Ubicación**: `src/utils/ton.ts`
- **Responsabilidad**: Convertir mensajes de WhatsApp a formato TON
- **Funciones clave**:
  - `whatsappToTON()`: Convierte webhook a TON
  - `normalizeText()`: Normaliza texto (minúsculas, sin tildes)
  - `parseTON()`: Parsea respuesta TON de IA

### 2. **Módulo de WhatsApp**
- **Ubicación**: `src/utils/whatsapp.ts`, `src/services/whatsapp.service.ts`
- **Responsabilidad**: Comunicación con WhatsApp Cloud API
- **Funciones clave**:
  - `extractMessage()`: Extrae mensaje del webhook
  - `sendTextMessage()`: Envía mensaje de texto
  - `sendTemplateMessage()`: Envía plantilla (solo Full)

### 3. **Módulo de IA**
- **Ubicación**: `src/services/ai.service.ts`
- **Responsabilidad**: Interpretación de intenciones
- **Funciones clave**:
  - `interpretIntent()`: Interpreta mensaje usando OpenAI
  - `generateMarketingMessage()`: Genera mensajes de marketing

### 4. **Módulo de Carrito**
- **Ubicación**: `src/services/cart.service.ts`
- **Responsabilidad**: Gestión de carritos de compra
- **Funciones clave**:
  - `getOrCreateCart()`: Obtiene o crea carrito
  - `addToCart()`: Agrega producto
  - `getAbandonedCarts()`: Obtiene carritos abandonados

### 5. **Módulo de Pedidos**
- **Ubicación**: `src/services/orders.service.ts`
- **Responsabilidad**: Gestión de pedidos
- **Funciones clave**:
  - `createOrderFromCart()`: Crea pedido desde carrito
  - `updateOrderStatus()`: Actualiza estado
  - `getCustomerOrders()`: Obtiene pedidos del cliente

## 🔐 Seguridad

### Autenticación
- **WhatsApp Cloud API**: Token de acceso (Bearer)
- **Supabase**: API Key (anon key para lectura, service role para escritura)
- **OpenAI**: API Key

### Validación
- Verificación de firma de webhook (WhatsApp)
- Validación de formato de teléfono
- Sanitización de inputs

## 📈 Escalabilidad

### Estrategias
1. **Horizontal**: Múltiples instancias de n8n
2. **Base de Datos**: Supabase escala automáticamente
3. **Caché**: Implementar Redis para consultas frecuentes (futuro)
4. **Rate Limiting**: Controlar llamadas a APIs externas

### Límites
- **WhatsApp Cloud API**: 1000 mensajes/día (gratis), más en planes pagos
- **OpenAI**: Límites según plan (tokens/minuto)
- **Supabase**: Límites según plan

## 🔧 Configuración

### Variables de Entorno Requeridas

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

## 🚀 Deployment

### Opciones Recomendadas
1. **Render**: Deploy rápido de n8n y servicios
2. **Railway**: Alternativa simple
3. **Docker**: Para entornos controlados
4. **Vercel/Netlify**: Para dashboard Next.js

### Pasos de Deploy
1. Configurar Supabase (DB + API)
2. Desplegar n8n (workflows)
3. Configurar webhooks de WhatsApp
4. Configurar variables de entorno
5. Importar workflows JSON
6. Activar workflows

## 📝 TON Notation - Explicación

TON (Tree Object Notation) es un formato ligero diseñado para reducir tokens en llamadas a IA.

### Ventajas
- **Menos tokens**: Reduce costos de OpenAI
- **Fácil parsing**: Formato estructurado simple
- **Legible**: Fácil de debuggear

### Ejemplo

**Input TON:**
```
text:"hola quiero ver productos"
from:"5491122334455"
wa_id:"123456789"
```

**Output TON:**
```
intent:"saludo"
response:"¡Hola! 👋 Bienvenido. ¿En qué puedo ayudarte?"
```

### Normalización
- Texto a minúsculas
- Eliminación de tildes
- Eliminación de caracteres especiales
- Solo letras, números y espacios

## 🔄 Roles de Componentes

| Componente | Rol Principal | Responsabilidad |
|------------|---------------|------------------|
| **WhatsApp Cloud API** | Gateway | Recepción y envío de mensajes |
| **n8n** | Orquestador | Lógica de negocio y workflows |
| **OpenAI** | Inteligencia | Interpretación y generación |
| **Supabase** | Persistencia | Almacenamiento y consultas |
| **TON** | Normalización | Formato de comunicación |

## 📚 Referencias

- [WhatsApp Cloud API Docs](https://developers.facebook.com/docs/whatsapp/cloud-api)
- [n8n Documentation](https://docs.n8n.io/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Supabase Documentation](https://supabase.com/docs)
- [TON Specification](https://github.com/TON-Notation/TON)

