# 📱 Configuración de WhatsApp - Guía Completa

## ✅ Estado Actual

- ✅ Número de prueba obtenido: `15551651361`
- ✅ Webhook deployado y funcionando
- ✅ Token de verificación configurado

## 🔧 Pasos para Completar la Configuración

### 1. Agregar Destinatarios de Prueba

**IMPORTANTE:** Solo puedes enviar mensajes a números que agregues como "Destinatarios de prueba".

1. Ve a Meta Business → WhatsApp → API Setup
2. Busca la sección "Destinatarios de prueba" o "Test recipients"
3. Deberías ver algo como: "0 de 5 destinatarios agregados"
4. Haz clic en "Agregar" o "Add"
5. Ingresa tu número de WhatsApp personal (formato: +5491122334455)
6. Meta te enviará un código de verificación por WhatsApp
7. Ingresa el código para confirmar

**Nota:** Puedes agregar hasta 5 números de prueba.

### 2. Obtener Access Token

1. En la misma página de API Setup
2. Busca "Temporary access token" o "Token temporal"
3. Copia el token (o genera uno nuevo si expiró)
4. Agrega al `.env`:
   ```bash
   WHATSAPP_ACCESS_TOKEN=tu_token_aqui
   ```

### 3. Configurar Variables en .env

Edita tu `.env` y asegúrate de tener:

```bash
# WhatsApp
WHATSAPP_PHONE_NUMBER_ID=15551651361
WHATSAPP_ACCESS_TOKEN=tu_token_temporal
WHATSAPP_VERIFY_TOKEN=mi_token_secreto_123
```

### 4. Probar Envío de Mensajes

```bash
./scripts/test-send-whatsapp.sh
```

El script te pedirá:
- Número de destino (debe estar en la lista de destinatarios de prueba)
- Mensaje a enviar

### 5. Probar Recepción de Mensajes

1. Envía un mensaje desde tu WhatsApp personal al número de prueba: `+1 555 165 1361`
2. El webhook debería recibirlo automáticamente
3. Verifica en Supabase:
   ```sql
   SELECT * FROM messages ORDER BY created_at DESC LIMIT 5;
   SELECT * FROM customers ORDER BY created_at DESC LIMIT 5;
   ```

## 🧪 Pruebas Completas

### Test 1: Verificar Webhook
```bash
./scripts/test-webhook.sh
```

### Test 2: Enviar Mensaje
```bash
./scripts/test-send-whatsapp.sh
```

### Test 3: Verificar en Supabase
```bash
npx ts-node scripts/test-supabase-integration.ts
```

## 📋 Checklist

- [ ] Número de prueba obtenido: `15551651361`
- [ ] Agregado al menos 1 destinatario de prueba
- [ ] Access Token configurado en `.env`
- [ ] Phone Number ID configurado: `15551651361`
- [ ] Webhook verificado en Meta Business
- [ ] Prueba de envío exitosa
- [ ] Prueba de recepción exitosa

## 🔗 URLs Importantes

- **Webhook URL:** `https://synwylrcxggklbpstawy.supabase.co/functions/v1/whatsapp-webhook`
- **API Endpoint:** `https://graph.facebook.com/v21.0/15551651361/messages`
- **Dashboard Supabase:** `https://supabase.com/dashboard/project/synwylrcxggklbpstawy`

## ⚠️ Limitaciones del Número de Prueba

- ✅ Válido por 90 días
- ✅ Gratis (sin costo)
- ✅ Solo puedes enviar a números agregados como destinatarios de prueba
- ⚠️ Máximo 5 destinatarios de prueba
- ⚠️ Token temporal expira (necesitas generar uno permanente para producción)

## 🚀 Próximos Pasos

1. **Probar flujo completo:**
   - Envía mensaje desde tu WhatsApp al número de prueba
   - Verifica que se guarda en Supabase
   - Conecta con n8n para procesar con IA

2. **Para producción:**
   - Solicitar número de producción en Meta Business
   - Crear token permanente
   - Configurar templates aprobados (para plan Full)

