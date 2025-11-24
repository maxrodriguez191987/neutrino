# 🚀 WhatsApp Sales Automation SaaS

Sistema completo de automatización de ventas por WhatsApp usando n8n, WhatsApp Cloud API, OpenAI y Supabase.

## 📋 Tabla de Contenidos

- [Características](#-características)
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

## 🏗️ Arquitectura

```
WhatsApp Cloud API → n8n → OpenAI → Supabase
         ↑                              ↓
         └────────── Respuesta ─────────┘
```

### Componentes Principales

1. **WhatsApp Cloud API**: Recepción y envío de mensajes
2. **n8n**: Motor de workflows y automatización
3. **OpenAI**: Interpretación de intenciones y generación de respuestas
4. **Supabase**: Base de datos y API REST
5. **TON**: Formato de normalización para comunicación eficiente

Ver [docs/architecture.md](docs/architecture.md) para más detalles.

## 📦 Planes

### 🟢 Plan Básico
- Respuestas automáticas a saludos
- Consultas de productos
- Respuestas genéricas
- **Sin base de datos**

### 🟡 Plan Pro
- ✅ Todo lo del plan Básico
- ✅ Gestión de carrito
- ✅ Consultar carrito
- ✅ Confirmar pedidos
- ✅ Integración con Supabase

### 🔴 Plan Full
- ✅ Todo lo del plan Pro
- ✅ Mensajes salientes automáticos
- ✅ Carritos abandonados (cron diario)
- ✅ Ofertas semanales (cron semanal)
- ✅ Mensajes de marketing personalizados
- ✅ Plantillas de WhatsApp

## 🛠️ Tecnologías

- **n8n**: Automatización y workflows
- **WhatsApp Cloud API**: Comunicación por WhatsApp
- **OpenAI (GPT-4o-mini)**: Inteligencia artificial
- **Supabase**: Base de datos PostgreSQL + API REST
- **TypeScript/Node.js**: Servicios y utilidades
- **TON (Tree Object Notation)**: Formato de normalización

## ⚡ Inicio Rápido

### Levantar el Proyecto

```bash
# 1. Configurar variables de entorno
./scripts/setup-env.sh

# 2. Levantar todo (elige opción)
./scripts/start.sh

# 3. O seguir guía detallada
# Lee SETUP.md para instrucciones completas
```

### Guías Disponibles

- **[SETUP.md](SETUP.md)** - Guía completa para levantar el proyecto
- **[QUICK_START.md](QUICK_START.md)** - Inicio rápido (5 pasos)
- **[TESTING.md](TESTING.md)** - Guía de pruebas detallada

## 🚀 Instalación

### Prerrequisitos

- Node.js 20+ (requerido por Supabase, ver [NODE_VERSION.md](NODE_VERSION.md))
- Cuenta de Meta Business (WhatsApp Cloud API)
- Cuenta de Supabase
- Cuenta de OpenAI
- Instancia de n8n (cloud o self-hosted)

### 1. Clonar Repositorio

```bash
git clone https://github.com/tu-usuario/whatsapp-sales-automation.git
cd whatsapp-sales-automation
```

### 2. Configurar Supabase

```bash
# Ejecutar schema
psql -h {SUPABASE_HOST} -U postgres -d postgres -f supabase/schema.sql

# Ejecutar seeds (opcional)
psql -h {SUPABASE_HOST} -U postgres -d postgres -f supabase/seed.sql
```

O usar el SQL Editor en el dashboard de Supabase.

### 3. Configurar n8n

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

3. Configurar credenciales:
   - **OpenAI API**: API Key
   - **WhatsApp Cloud API**: HTTP Header Auth (Bearer token)
   - **Supabase**: HTTP Header Auth (apikey header)

### 4. Configurar WhatsApp Cloud API

1. Crear app en [Meta for Developers](https://developers.facebook.com/)
2. Configurar WhatsApp Business API
3. Obtener Phone Number ID y Access Token
4. Configurar webhook en n8n:
   - URL: `https://{n8n-instance}/webhook/{webhook-id}`
   - Verify Token: (configurar en n8n)
   - Suscribirse a eventos: `messages`

### 5. Instalar Dependencias (Opcional)

Si usas los servicios TypeScript:

```bash
npm install
```

## ⚙️ Configuración

### Variables de Entorno

Crear archivo `.env`:

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

# n8n (si self-hosted)
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=xxx
```

### Configurar Webhooks

1. Obtener URL del webhook de n8n
2. Configurar en Meta Business Manager:
   - Settings → WhatsApp → Configuration
   - Webhook URL: `https://{n8n}/webhook/{id}`
   - Verify Token: (el configurado en n8n)

### Configurar Templates (Solo Plan Full)

1. Crear templates en Meta Business Manager
2. Esperar aprobación (puede tardar horas)
3. Actualizar nombres en workflows n8n

## 📖 Uso

### Activar Workflow

1. Abrir n8n
2. Seleccionar workflow según plan
3. Activar workflow
4. Probar enviando mensaje por WhatsApp

### Flujo Básico

1. Cliente envía mensaje por WhatsApp
2. Webhook recibe en n8n
3. Mensaje se normaliza a TON
4. OpenAI interpreta intención
5. Se consulta Supabase (si necesario)
6. Se genera respuesta
7. Se envía por WhatsApp

### Ejemplos de Mensajes

**Saludo:**
```
Cliente: "Hola"
Sistema: "¡Hola! 👋 Bienvenido a nuestra tienda..."
```

**Agregar al Carrito:**
```
Cliente: "Quiero agregar iPhone al carrito"
Sistema: "✅ iPhone 15 Pro agregado a tu carrito..."
```

**Consultar Carrito:**
```
Cliente: "Ver mi carrito"
Sistema: "🛒 Tu carrito: ..."
```

## 📁 Estructura del Proyecto

```
whatsapp-sales-automation/
├── workflows/              # Workflows n8n
│   ├── basic.json
│   ├── pro.json
│   └── full.json
├── supabase/              # Base de datos
│   ├── schema.sql
│   └── seed.sql
├── src/                   # Código TypeScript
│   ├── utils/
│   │   ├── ton.ts
│   │   ├── whatsapp.ts
│   │   └── supabase.ts
│   └── services/
│       ├── ai.service.ts
│       ├── whatsapp.service.ts
│       ├── cart.service.ts
│       └── orders.service.ts
├── prompts/               # Prompts para IA
│   ├── ia_basic.ton.txt
│   ├── ia_pro.ton.txt
│   └── ia_full.ton.txt
├── docs/                  # Documentación
│   ├── architecture.md
│   ├── flow_basic.md
│   ├── flow_pro.md
│   ├── flow_full.md
│   └── endpoints.md
├── dashboard/             # Dashboard Next.js (opcional)
└── README.md
```

## 📚 Documentación

- [Arquitectura](docs/architecture.md): Visión general del sistema
- [Flujo Básico](docs/flow_basic.md): Plan Básico detallado
- [Flujo Pro](docs/flow_pro.md): Plan Pro detallado
- [Flujo Full](docs/flow_full.md): Plan Full detallado
- [Endpoints](docs/endpoints.md): Documentación de APIs

## 🔧 Desarrollo

### Servicios TypeScript

Los servicios en `src/` son opcionales y pueden usarse como referencia o para extender funcionalidades.

```typescript
import { AIService } from './services/ai.service';
import { WhatsAppService } from './services/whatsapp.service';
import { CartService } from './services/cart.service';

// Ejemplo de uso
const aiService = new AIService({ apiKey: process.env.OPENAI_API_KEY });
const result = await aiService.interpretIntent(tonInput, prompt, 'pro');
```

### Agregar Nuevas Intenciones

1. Actualizar prompt en `prompts/`
2. Agregar caso en switch de n8n
3. Implementar lógica en workflow
4. Actualizar documentación

## 🧪 Testing

### Probar Webhook Localmente

Usar [ngrok](https://ngrok.com/) para exponer n8n local:

```bash
ngrok http 5678
# Usar URL de ngrok en Meta Business Manager
```

### Probar con Número de Prueba

1. Agregar número de prueba en Meta Business Manager
2. Enviar mensajes de prueba
3. Verificar logs en n8n

## 🚨 Troubleshooting

### Webhook no recibe mensajes

- Verificar URL en Meta Business Manager
- Verificar Verify Token
- Revisar logs de n8n

### OpenAI no responde

- Verificar API Key
- Revisar límites de rate
- Verificar formato TON

### Supabase no conecta

- Verificar URL y API Key
- Revisar políticas RLS (Row Level Security)
- Verificar funciones RPC creadas

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

- [ ] Dashboard web para gestión
- [ ] Analytics y métricas
- [ ] Integración con pasarelas de pago
- [ ] Multi-idioma
- [ ] Integración con otros canales (Telegram, etc.)

## 🙏 Agradecimientos

- n8n por la plataforma de automatización
- Meta por WhatsApp Cloud API
- OpenAI por la API de IA
- Supabase por la infraestructura de backend

---

**Hecho con ❤️ para automatizar ventas por WhatsApp**
