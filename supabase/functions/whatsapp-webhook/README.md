# WhatsApp Webhook - Supabase Edge Function

Edge Function para recibir y procesar webhooks de WhatsApp Cloud API.

## 🚀 Deploy

### 1. Instalar Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# O con npm
npm install -g supabase
```

### 2. Iniciar sesión en Supabase

```bash
supabase login
```

### 3. Linkear proyecto

```bash
supabase link --project-ref synwylrcxggklbpstawy
```

### 4. Configurar secrets

```bash
supabase secrets set WHATSAPP_VERIFY_TOKEN=mi_token_webhook_123
supabase secrets set SUPABASE_URL=https://synwylrcxggklbpstawy.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key
```

### 5. Deploy

```bash
supabase functions deploy whatsapp-webhook
```

### 6. Obtener URL pública

```bash
supabase functions list
```

O ve a: Dashboard → Edge Functions → whatsapp-webhook

La URL será algo como:
```
https://synwylrcxggklbpstawy.supabase.co/functions/v1/whatsapp-webhook
```

## 📝 Configurar en Meta Business

1. Ve a Meta Business → WhatsApp → Configuration → Webhooks
2. **Callback URL**: `https://synwylrcxggklbpstawy.supabase.co/functions/v1/whatsapp-webhook`
3. **Verify Token**: `mi_token_webhook_123` (o el que configuraste)
4. Suscríbete a: `messages`

## ✅ Funcionalidades

- ✅ Verificación de webhook (GET)
- ✅ Recepción de mensajes (POST)
- ✅ Registro automático de clientes
- ✅ Guardado de mensajes en BD
- ✅ Preparado para integración con n8n

## 🔧 Variables de Entorno

- `WHATSAPP_VERIFY_TOKEN`: Token para verificar webhook
- `SUPABASE_URL`: URL de tu proyecto Supabase
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key (para escribir en BD)

