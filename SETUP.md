# 🚀 Guía de Setup - Levantar el Proyecto

Guía completa para levantar y ejecutar el proyecto desde cero.

## 📋 Índice

1. [Prerrequisitos](#prerrequisitos)
2. [Configuración Inicial](#configuración-inicial)
3. [Levantar Supabase](#levantar-supabase)
4. [Levantar n8n](#levantar-n8n)
5. [Configurar Servicios Externos](#configurar-servicios-externos)
6. [Verificar Instalación](#verificar-instalación)
7. [Iniciar el Sistema](#iniciar-el-sistema)

## ✅ Prerrequisitos

Antes de empezar, necesitas:

- [ ] Node.js 20+ instalado (requerido por Supabase)
- [ ] Cuenta de GitHub (para clonar)
- [ ] Cuenta de Supabase (gratis)
- [ ] Cuenta de OpenAI (con API key)
- [ ] Meta Business Account (para WhatsApp)
- [ ] Docker (opcional, para n8n local)

Verifica Node.js:
```bash
node --version  # Debe ser 18 o superior
npm --version
```

## 🔧 Configuración Inicial

### 1. Clonar o Navegar al Proyecto

```bash
# Si clonas desde GitHub
git clone https://github.com/tu-usuario/whatsapp-sales-automation.git
cd whatsapp-sales-automation

# O si ya tienes el proyecto
cd /Users/ripio/repos/neutrino
```

### 2. Instalar Dependencias

```bash
# Instalar dependencias del proyecto
npm install

# (Opcional) Si quieres usar los servicios TypeScript directamente
npm run build
```

### 3. Configurar Variables de Entorno

```bash
# Crear archivo .env automáticamente
./scripts/setup-env.sh

# O crear manualmente
cp .env.example .env  # Si existe
# Edita .env con tus credenciales
```

Edita `.env` con tus credenciales reales.

## 🗄️ Levantar Supabase

### Opción 1: Supabase Cloud (Recomendado)

1. **Crear Proyecto**:
   - Ve a [supabase.com](https://supabase.com)
   - Crea cuenta (gratis)
   - Crea nuevo proyecto
   - Anota: URL y API Keys

2. **Ejecutar Schema**:
   - Ve a SQL Editor en Supabase
   - Abre `supabase/schema.sql`
   - Copia y pega todo el contenido
   - Ejecuta (Run)
   - Verifica que no hay errores

3. **Ejecutar Funciones**:
   - En SQL Editor, abre `supabase/functions.sql`
   - Copia y pega todo
   - Ejecuta

4. **Ejecutar Seeds (Opcional)**:
   - Abre `supabase/seed.sql`
   - Copia y pega
   - Ejecuta para tener datos de prueba

5. **Verificar**:
   ```sql
   -- En SQL Editor de Supabase
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public';
   -- Debe mostrar: products, customers, carts, orders, messages, campaigns
   ```

6. **Obtener Credenciales**:
   - Settings → API
   - Copia:
     - Project URL
     - anon/public key
     - service_role key (opcional)

### Opción 2: Supabase Local (Docker)

```bash
# Instalar Supabase CLI
npm install -g supabase

# Inicializar proyecto
supabase init

# Iniciar Supabase local
supabase start

# Aplicar migraciones
supabase db reset
```

## 🔄 Levantar n8n

### Opción 1: n8n Cloud (Más Fácil)

1. **Crear Cuenta**:
   - Ve a [n8n.io](https://n8n.io)
   - Crea cuenta gratuita
   - Tienes 2 workflows gratis

2. **Importar Workflows**:
   - Crea nuevo workflow
   - Click en "..." → Import from File
   - Selecciona `workflows/basic.json`
   - Repite para `pro.json` y `full.json` si los necesitas

3. **Configurar Credenciales**:
   - Ve a Credentials
   - Agrega:
     - **OpenAI**: API Key
     - **HTTP Header Auth** (WhatsApp): `Authorization: Bearer {TOKEN}`
     - **HTTP Header Auth** (Supabase): `apikey: {KEY}`

4. **Configurar Variables**:
   - Settings → Environment Variables
   - Agrega todas las variables de `.env`

5. **Activar Workflow**:
   - Toggle "Active" en la esquina superior derecha

### Opción 2: n8n Local con Docker

```bash
# Crear directorio para datos
mkdir -p ~/.n8n

# Levantar n8n
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=tu_password \
  n8nio/n8n

# Accede a http://localhost:5678
```

### Opción 3: n8n Local con npm

```bash
# Instalar n8n globalmente
npm install -g n8n

# Iniciar n8n
n8n start

# O con configuración
N8N_BASIC_AUTH_USER=admin \
N8N_BASIC_AUTH_PASSWORD=password \
n8n start

# Accede a http://localhost:5678
```

### Exponer n8n Local (ngrok)

Si n8n está local y necesitas webhook público:

```bash
# Instalar ngrok
npm install -g ngrok
# O descargar de ngrok.com

# Exponer n8n
ngrok http 5678

# Copia la URL (ej: https://abc123.ngrok.io)
# Úsala para configurar webhook de WhatsApp
```

## 📱 Configurar Servicios Externos

### 1. WhatsApp Cloud API

1. **Crear App en Meta**:
   - Ve a [developers.facebook.com](https://developers.facebook.com)
   - Crea nueva app
   - Agrega producto "WhatsApp"

2. **Configurar WhatsApp**:
   - Ve a WhatsApp → API Setup
   - Anota:
     - **Phone Number ID**
     - **Access Token** (temporal o permanente)
   - Crea un **Verify Token** (cualquier string)

3. **Agregar Número de Prueba**:
   - En API Setup → Add phone number
   - Agrega tu número
   - Verifica con código SMS

4. **Configurar Webhook**:
   - Ve a Configuration → Webhooks
   - **Callback URL**: `https://tu-n8n.com/webhook/{id}` (o URL de ngrok)
   - **Verify Token**: El que creaste
   - Click "Verify and Save"
   - Suscríbete a: `messages`

### 2. OpenAI

1. **Crear API Key**:
   - Ve a [platform.openai.com](https://platform.openai.com)
   - Crea cuenta o inicia sesión
   - Ve a API Keys
   - Crea nueva key
   - Copia y guarda (solo se muestra una vez)

2. **Verificar Límites**:
   - Revisa tu plan y límites de rate
   - Plan gratuito tiene límites bajos

## ✅ Verificar Instalación

### Test 1: Supabase

```bash
./scripts/test-supabase.sh
```

Debe mostrar: ✅ Conexión exitosa

### Test 2: WhatsApp

```bash
./scripts/test-whatsapp.sh
```

Sigue las instrucciones para enviar mensaje de prueba.

### Test 3: OpenAI

```bash
./scripts/test-openai.sh
```

Debe mostrar: ✅ API Key válida

## 🚀 Iniciar el Sistema

### Paso 1: Verificar Todo Está Configurado

```bash
# Verificar archivo .env
cat .env | grep -v "^#" | grep -v "^$"

# Debe mostrar todas las variables configuradas
```

### Paso 2: Activar n8n Workflow

1. Abre n8n (cloud o local)
2. Selecciona workflow `basic.json` (o el que quieras)
3. Verifica que todos los nodos tienen credenciales
4. Toggle "Active" para activar

### Paso 3: Verificar Webhook

1. En n8n, ve al nodo Webhook
2. Copia la URL del webhook
3. Verifica que está configurada en Meta Business Manager

### Paso 4: Probar Flujo Completo

1. **Envía mensaje por WhatsApp**: `"Hola"`
2. **Verifica en n8n**:
   - Ve a "Executions"
   - Debe aparecer nueva ejecución
   - Revisa que todos los nodos pasaron
3. **Recibe respuesta**: Deberías recibir mensaje automático

## 📊 Verificar que Todo Funciona

### Dashboard de n8n

- Ve a "Executions"
- Debe mostrar ejecuciones exitosas
- Click en una ejecución para ver detalles

### Supabase Dashboard

- Ve a Table Editor
- Verifica que hay datos en:
  - `messages` (mensajes recibidos)
  - `customers` (si se crearon)

### WhatsApp

- Debes recibir respuestas automáticas
- Verifica que los mensajes llegan

## 🔧 Comandos Útiles

### Iniciar Todo (si usas Docker)

```bash
# Crear docker-compose.yml (opcional)
# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f n8n
```

### Ver Logs de n8n

```bash
# Si está en Docker
docker logs -f n8n

# Si está local
# Los logs aparecen en la terminal donde ejecutaste n8n
```

### Reiniciar n8n

```bash
# Docker
docker restart n8n

# Local
# Ctrl+C y luego: n8n start
```

## 🐛 Troubleshooting

### n8n no inicia

```bash
# Verificar puerto
lsof -i :5678

# Cambiar puerto
N8N_PORT=5679 n8n start
```

### Webhook no recibe mensajes

1. Verifica que n8n está activo
2. Verifica URL en Meta Business Manager
3. Usa ngrok si es local
4. Revisa logs de n8n

### Supabase no conecta

1. Verifica URL y API Key en `.env`
2. Prueba con `test-supabase.sh`
3. Revisa políticas RLS

### OpenAI no responde

1. Verifica API Key
2. Revisa límites de rate
3. Prueba con `test-openai.sh`

## 📝 Checklist Final

- [ ] Node.js instalado
- [ ] Dependencias instaladas (`npm install`)
- [ ] Archivo `.env` configurado
- [ ] Supabase configurado y probado
- [ ] n8n levantado (cloud o local)
- [ ] Workflows importados
- [ ] Credenciales configuradas en n8n
- [ ] WhatsApp Cloud API configurado
- [ ] Webhook configurado en Meta
- [ ] OpenAI API Key configurada
- [ ] Todos los tests pasan
- [ ] Mensaje de prueba funciona

## 🎯 Próximos Pasos

Una vez que todo funciona:

1. **Personalizar**: Ajusta prompts y respuestas
2. **Escalar**: Configura múltiples workflows
3. **Monitorear**: Revisa métricas y logs
4. **Optimizar**: Ajusta según uso real

## 📚 Documentación Adicional

- [QUICK_START.md](QUICK_START.md) - Inicio rápido
- [TESTING.md](TESTING.md) - Guía de pruebas
- [README.md](README.md) - Documentación principal

---

**¿Problemas?** Revisa [TESTING.md](TESTING.md) para troubleshooting detallado.

