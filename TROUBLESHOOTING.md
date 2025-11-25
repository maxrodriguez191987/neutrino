# 🔧 Troubleshooting

Guía completa para solucionar problemas comunes del sistema.

## 📋 Tabla de Contenidos

- [Webhook No Responde](#-webhook-no-responde)
- [No Recibe Mensajes desde Otro Número](#-no-recibe-mensajes-desde-otro-número)
- [Access Token Expirado](#-access-token-expirado)
- [Secrets No Configurados](#-secrets-no-configurados)

## ❌ Webhook No Responde

### Síntoma
Envías mensajes desde tu WhatsApp pero no recibes respuesta automática.

### Solución: Verificar Suscripción a "messages"

**CRÍTICO:** Este es el problema más común (95% de los casos).

1. Ve a [Meta Business Manager](https://business.facebook.com/)
2. Selecciona tu App → **WhatsApp** → **Configuration**
3. En la sección **Webhooks**:
   - Verifica que esté **"Verificado y guardado"** ✅
   - Haz clic en **"Configurar"** o **"Manage"**
   - **VERIFICA que "messages" esté seleccionado** ✅
   - Si NO está, selecciónalo y guarda

### Verificar en Logs

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. **Edge Functions** → **whatsapp-webhook** → **Logs**
3. Envía un mensaje desde tu WhatsApp
4. **Si ves logs:** El webhook recibe mensajes ✅
5. **Si NO ves logs:** El webhook NO está suscrito a "messages" ⚠️

## 📱 No Recibe Mensajes desde Otro Número

### Síntoma
Agregaste un número como destinatario de prueba pero no funciona.

### Solución

1. **Verificar que el número esté agregado:**
   - Meta Business → WhatsApp → API Setup → Test recipients
   - Debe aparecer en la lista ✅

2. **Verificar que esté verificado:**
   - Meta debe haber enviado un código por WhatsApp
   - El código debe haberse ingresado correctamente

3. **Formato del número:**
   - Correcto: `+5491165820938` o `5491165820938`
   - Incorrecto: `(54) 911 6582-0938` (con espacios/guiones)

4. **Límite de destinatarios:**
   - Máximo 5 números de prueba
   - Si alcanzaste el límite, elimina uno y agrega el nuevo

### Cómo Probar desde Otro Número

1. **Agregar número:**
   - Meta Business → WhatsApp → API Setup
   - Test recipients → Add → Ingresar número → Verificar

2. **Probar envío:**
   - Desde el nuevo número: Envía "hola" al `+1 555 165 1361`
   - Al nuevo número: `./scripts/quick-test-whatsapp.sh NUMERO`

3. **Verificar en Supabase:**
   ```sql
   SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;
   SELECT * FROM customers ORDER BY created_at DESC LIMIT 10;
   ```

## 🔑 Access Token Expirado

### Síntoma
Logs muestran `401 Unauthorized` o `Error enviando respuesta: 401`

### Solución

1. Ve a Meta Business → WhatsApp → API Setup
2. Genera un nuevo Access Token
3. Actualiza en `.env`:
   ```bash
   WHATSAPP_ACCESS_TOKEN=nuevo_token
   ```
4. Configura en Supabase secrets:
   ```bash
   source .env
   supabase secrets set WHATSAPP_ACCESS_TOKEN="${WHATSAPP_ACCESS_TOKEN}"
   ```

## 🔐 Secrets No Configurados

### Síntoma
Logs muestran `❌ Faltan credenciales` o `ACCESS_TOKEN: ❌ Faltante`

### Solución

```bash
source .env
supabase secrets set \
  WHATSAPP_ACCESS_TOKEN="${WHATSAPP_ACCESS_TOKEN}" \
  WHATSAPP_PHONE_NUMBER_ID="${WHATSAPP_PHONE_NUMBER_ID}" \
  WHATSAPP_VERIFY_TOKEN="${WHATSAPP_VERIFY_TOKEN}"
```

### Verificar Secrets

```bash
supabase secrets list
```

Deberías ver:
- `WHATSAPP_ACCESS_TOKEN` ✅
- `WHATSAPP_PHONE_NUMBER_ID` ✅
- `WHATSAPP_VERIFY_TOKEN` ✅

## 🐛 Otros Problemas

### Problema: Webhook No Verificado

**Síntoma:** Error al verificar webhook en Meta Business

**Solución:**
1. Verifica que el Verify Token sea: `mi_token_secreto_123`
2. Verifica que la URL sea correcta
3. Haz clic en "Verificar y guardar" nuevamente

### Problema: Edge Function No Responde

**Síntoma:** Webhook verifica pero no procesa mensajes

**Solución:**
1. Re-deploy la Edge Function:
   ```bash
   supabase functions deploy whatsapp-webhook --no-verify-jwt
   ```
2. Verifica logs en Supabase Dashboard
3. Verifica que los secrets estén configurados

### Problema: Mensajes No Se Guardan en Supabase

**Síntoma:** Recibe mensajes pero no aparecen en la base de datos

**Solución:**
1. Verifica que `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` estén en secrets
2. Verifica que las tablas existan (ejecuta `schema.sql`)
3. Verifica logs para errores de Supabase

## ✅ Checklist de Diagnóstico

- [ ] Webhook verificado en Meta Business
- [ ] Webhook suscrito a "messages" ⚠️ CRÍTICO
- [ ] Número agregado como destinatario de prueba
- [ ] Número verificado con código de Meta
- [ ] Secrets configurados en Supabase
- [ ] Access Token válido (no expirado)
- [ ] Edge Function deployada
- [ ] Logs muestran mensajes recibidos
- [ ] Logs muestran respuestas enviadas

## 🔍 Script de Diagnóstico

Ejecuta el script de diagnóstico:

```bash
./scripts/diagnose-no-response.sh
```

Este script verifica:
- ✅ Webhook verifica correctamente
- ✅ Variables en .env configuradas
- ✅ Checklist manual de verificación

## 📞 Si Nada Funciona

1. **Ejecuta diagnóstico completo:**
   ```bash
   ./scripts/diagnose-no-response.sh
   ```

2. **Revisa logs completos en Supabase Dashboard**

3. **Verifica manualmente cada paso del checklist**

4. **Prueba el webhook manualmente:**
   ```bash
   curl -X POST https://synwylrcxggklbpstawy.supabase.co/functions/v1/whatsapp-webhook \
     -H "Content-Type: application/json" \
     -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"5491165820938","text":{"body":"test"},"type":"text"}]}}]}]}'
   ```
