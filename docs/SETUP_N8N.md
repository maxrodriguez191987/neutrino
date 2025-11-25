# 🚀 Configuración de n8n + OpenAI para Respuestas Automáticas

## 📋 Resumen

Para que el sistema responda automáticamente a los mensajes de WhatsApp, necesitas configurar n8n + OpenAI. Esto es más robusto que las respuestas básicas de la Edge Function.

## 🎯 Flujo con n8n + OpenAI

```
WhatsApp → Meta Business → n8n Webhook → OpenAI → Supabase → WhatsApp
```

## ⚙️ Opción 1: n8n Cloud (Recomendado - Más Fácil)

### 1. Crear Cuenta en n8n Cloud

1. Ve a [n8n.io/cloud](https://n8n.io/cloud/)
2. Crea una cuenta gratuita (o paga)
3. Accede al dashboard

### 2. Importar Workflow

1. En n8n Cloud, haz clic en **"Workflows"** → **"Import from File"**
2. Selecciona `workflows/basic.json` (o `pro.json` para más funcionalidades)
3. El workflow se importará automáticamente

### 3. Configurar Credenciales

**A. OpenAI:**
1. Ve a **Credentials** → **Add Credential**
2. Busca **"OpenAI"**
3. Ingresa tu API Key:
   - Obtén una en [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
   - Si no tienes, créala ahora
4. Guarda como **"OpenAI API"**

**B. WhatsApp Cloud API:**
1. Ve a **Credentials** → **Add Credential**
2. Busca **"HTTP Header Auth"** o **"Custom API"**
3. Configura:
   - **Header Name**: `Authorization`
   - **Header Value**: `Bearer {TU_ACCESS_TOKEN}`
   - Reemplaza `{TU_ACCESS_TOKEN}` con tu token de WhatsApp
4. Guarda como **"WhatsApp API"**

**C. Supabase:**
1. Ve a **Credentials** → **Add Credential**
2. Busca **"HTTP Header Auth"**
3. Configura:
   - **Header Name**: `apikey`
   - **Header Value**: `{TU_SUPABASE_ANON_KEY}`
   - También agrega: `Authorization: Bearer {TU_SUPABASE_ANON_KEY}`
4. Guarda como **"Supabase API"**

### 4. Configurar Variables de Entorno

1. Ve a **Settings** → **Variables**
2. Agrega:
   ```
   WHATSAPP_PHONE_NUMBER_ID=921340014388774
   WHATSAPP_ACCESS_TOKEN=tu_token_aqui
   SUPABASE_URL=https://synwylrcxggklbpstawy.supabase.co
   SUPABASE_ANON_KEY=tu_anon_key_aqui
   OPENAI_API_KEY=sk-tu_key_aqui
   ```

### 5. Configurar Webhook de n8n

1. En el workflow importado, encuentra el nodo **"Webhook"**
2. Haz clic en él
3. Haz clic en **"Listen for test event"** para activar el webhook
4. Copia la **URL del webhook** (ej: `https://tu-instancia.n8n.cloud/webhook/abc123`)

### 6. Actualizar Meta Business

1. Ve a [Meta Business Manager](https://business.facebook.com/)
2. Selecciona tu App → **WhatsApp** → **Configuration**
3. En **Webhooks**, haz clic en **"Edit"** o **"Configurar"**
4. Cambia la URL a la de n8n:
   ```
   https://tu-instancia.n8n.cloud/webhook/abc123
   ```
5. **Verify Token**: Usa el mismo que tienes (o crea uno nuevo)
6. Haz clic en **"Verify and Save"**
7. Asegúrate de que esté suscrito a **"messages"**
8. Guarda

### 7. Activar Workflow

1. En n8n, haz clic en el botón **"Active"** en la esquina superior derecha
2. El workflow ahora está activo y recibirá mensajes

### 8. Probar

1. Envía un mensaje desde tu WhatsApp al `+1 555 165 1361`
2. Verifica en n8n que el workflow se ejecutó
3. Deberías recibir una respuesta en tu WhatsApp

## ⚙️ Opción 2: n8n Self-Hosted (Más Control)

### 1. Instalar n8n con Docker

```bash
# Ya tienes docker-compose.yml en el proyecto
docker-compose up -d
```

O instalar n8n directamente:

```bash
npm install n8n -g
n8n start
```

### 2. Acceder a n8n

Abre tu navegador en:
- **Docker**: `http://localhost:5678`
- **NPM**: `http://localhost:5678`

### 3. Seguir pasos 2-8 de la Opción 1

Igual que n8n Cloud, pero:
- El webhook será: `http://tu-ip:5678/webhook/abc123`
- Necesitarás usar **ngrok** para exponerlo públicamente

### 4. Exponer con ngrok

```bash
# Instalar ngrok
brew install ngrok  # macOS
# o descargar de ngrok.com

# Exponer n8n
ngrok http 5678

# Copia la URL (ej: https://abc123.ngrok.io)
# Usa esta URL en Meta Business: https://abc123.ngrok.io/webhook/abc123
```

## 🔑 Obtener OpenAI API Key

Si no tienes OpenAI API Key:

1. Ve a [platform.openai.com](https://platform.openai.com/)
2. Crea una cuenta (gratis)
3. Ve a [API Keys](https://platform.openai.com/api-keys)
4. Haz clic en **"Create new secret key"**
5. Copia la key (empieza con `sk-`)
6. Úsala en n8n

**Costo:** ~$0.15 por millón de tokens (muy económico)
**Crédito inicial:** $5 gratis al registrarse

## 📊 Estructura del Workflow

El workflow `basic.json` incluye:

1. **Webhook Node**: Recibe mensajes de WhatsApp
2. **Set Node**: Normaliza mensaje a formato TON
3. **OpenAI Node**: Interpreta intención del mensaje
4. **Switch Node**: Direcciona según intención
5. **HTTP Request Node**: Envía respuesta por WhatsApp
6. **Supabase Nodes**: Guarda datos (opcional)

## 🧪 Probar Workflow

### Test Local (antes de conectar Meta)

1. En n8n, haz clic en el nodo **"Webhook"**
2. Haz clic en **"Listen for test event"**
3. Copia la URL de test
4. En otra terminal:
   ```bash
   curl -X POST "URL_DEL_WEBHOOK" \
     -H "Content-Type: application/json" \
     -d '{
       "entry":[{
         "changes":[{
           "value":{
             "messages":[{
               "from":"5491165820938",
               "text":{"body":"hola"},
               "type":"text"
             }]
           }
         }]
       }]
     }'
   ```
5. Verifica que el workflow se ejecute y genere una respuesta

### Test Real (con Meta)

1. Asegúrate de que el webhook esté configurado en Meta Business
2. Asegúrate de que el workflow esté activo
3. Envía mensaje desde tu WhatsApp
4. Verifica en n8n → **Executions** que se ejecutó
5. Deberías recibir respuesta en WhatsApp

## 🐛 Troubleshooting

### Workflow no recibe mensajes

- Verifica que el webhook esté activo en n8n
- Verifica que Meta Business apunte a la URL correcta
- Verifica que esté suscrito a "messages"
- Verifica ngrok si usas self-hosted

### OpenAI no responde

- Verifica que la API Key sea correcta
- Verifica que tengas crédito en OpenAI
- Revisa los logs del nodo OpenAI en n8n

### No se envía respuesta

- Verifica credenciales de WhatsApp en n8n
- Verifica que el Access Token sea válido
- Verifica que el Phone Number ID sea correcto
- Revisa los logs del nodo HTTP Request

## ✅ Checklist

- [ ] n8n instalado/configurado
- [ ] Workflow importado
- [ ] OpenAI API Key configurada
- [ ] WhatsApp API configurada
- [ ] Supabase configurada (opcional)
- [ ] Variables de entorno configuradas
- [ ] Webhook de n8n activo
- [ ] Meta Business apunta a n8n
- [ ] Workflow activo
- [ ] Prueba exitosa

## 📚 Recursos

- [n8n Documentation](https://docs.n8n.io/)
- [OpenAI API Docs](https://platform.openai.com/docs)
- [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api)

