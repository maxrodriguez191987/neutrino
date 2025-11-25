# 🔧 Configurar Webhook de n8n con Meta Business

## 📋 Información del Webhook

**Callback URL:**
```
https://n8nlucafacu.app.n8n.cloud/webhook/webhook
```

## ✅ Pasos para Configurar

### 1. Verificar Workflow en n8n

1. Accede a tu n8n: [https://n8nlucafacu.app.n8n.cloud](https://n8nlucafacu.app.n8n.cloud)
2. Asegúrate de que el workflow esté **importado y activo**
3. Verifica que el nodo **Webhook** esté configurado con:
   - **Method**: POST
   - **Path**: `webhook`
   - **Response Mode**: Response Node o Last Node

### 2. Activar el Webhook

1. En n8n, haz clic en el nodo **Webhook**
2. Haz clic en **"Listen for test event"** o **"Active"** para activar el webhook
3. Copia la URL del webhook (debería ser la que tienes arriba)

### 3. Configurar en Meta Business

1. Ve a [Meta Business Manager](https://business.facebook.com/)
2. Selecciona tu App → **WhatsApp** → **Configuration**
3. En la sección **Webhooks**:
   - Haz clic en **"Configurar"** o **"Manage"**
   - Si ya tienes un webhook configurado, haz clic en **"Editar"** o **"Edit"**

4. **Actualiza la URL:**
   ```
   URL: https://n8nlucafacu.app.n8n.cloud/webhook/webhook
   ```

5. **Configure el Verify Token:**
   - Puedes usar: `mi_token_secreto_123` (o cualquier token que configures)
   - **IMPORTANTE:** Debes configurar el mismo token en n8n si es necesario

6. **Suscríbete a eventos:**
   - Selecciona **"messages"** ✅
   - Guarda

7. **Verifica el webhook:**
   - Haz clic en **"Verificar y guardar"** o **"Verify and Save"**
   - Debe mostrar ✅ "Webhook verificado"

### 4. Configurar n8n para Recibir Webhooks

En n8n, el workflow debe tener un nodo Webhook que:

1. **Recibe el payload de WhatsApp:**
   ```json
   {
     "entry": [{
       "changes": [{
         "value": {
           "messages": [...],
           "contacts": [...]
         }
       }]
     }]
   }
   ```

2. **Procesa el mensaje:**
   - Extrae el mensaje del payload
   - Normaliza a TON (si usas IA)
   - Procesa según tu lógica

3. **Responde a Meta:**
   - Meta espera una respuesta rápida (menos de 20 segundos)
   - Responde con `200 OK` inmediatamente
   - Luego procesa y envía la respuesta por WhatsApp

### 5. Verificar que Funciona

1. **Envía un mensaje desde tu WhatsApp** al número de prueba: `+1 555 165 1361`
2. **Mensaje:** `"hola"`
3. **Verifica en n8n:**
   - Ve a **Executions** en n8n
   - Deberías ver una ejecución nueva
   - Revisa que el workflow se ejecutó correctamente
4. **Deberías recibir respuesta** en tu WhatsApp

## 🔐 Configurar Variables de Entorno en n8n

En n8n, configura estas variables (Settings → Variables):

```bash
WHATSAPP_PHONE_NUMBER_ID=921340014388774
WHATSAPP_ACCESS_TOKEN=tu_token_aqui
SUPABASE_URL=https://synwylrcxggklbpstawy.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
OPENAI_API_KEY=sk-tu_key_aqui (si usas IA)
```

## 🔄 Verificar Token de Verificación

Si n8n requiere verificación del webhook (para Meta Business):

1. En el nodo Webhook de n8n, puedes agregar validación:
   ```javascript
   // En n8n Code Node (opcional)
   const verifyToken = $env.WHATSAPP_VERIFY_TOKEN;
   const hubMode = $input.first().json.query['hub.mode'];
   const token = $input.first().json.query['hub.verify_token'];
   const challenge = $input.first().json.query['hub.challenge'];

   if (hubMode === 'subscribe' && token === verifyToken) {
     return { challenge: challenge };
   }
   ```

2. O configurar el webhook para manejar GET requests para verificación

## 🐛 Troubleshooting

### Webhook No Recibe Mensajes

1. Verifica que el workflow esté **activo** en n8n
2. Verifica que el webhook esté **suscrito a "messages"** en Meta Business
3. Verifica que la URL sea exactamente: `https://n8nlucafacu.app.n8n.cloud/webhook/webhook`
4. Revisa las ejecuciones en n8n para ver si llegan mensajes

### Error al Verificar Webhook

1. Verifica que el Verify Token coincida
2. Si n8n no maneja GET requests para verificación, puede que necesites:
   - Configurar el webhook para aceptar GET
   - O mantener la Edge Function solo para verificación

### No Responde

1. Verifica que las credenciales estén configuradas en n8n
2. Verifica que el workflow complete sin errores
3. Revisa logs en n8n Executions

## 📝 Nota Importante

**Opción 1: Solo n8n (Recomendado si usas IA)**
- Webhook de Meta → n8n
- n8n procesa todo
- Más flexible y potente

**Opción 2: Híbrido (Actual)**
- Webhook de Meta → Supabase Edge Function
- Edge Function guarda en DB
- Puede llamar a n8n después

Para usar solo n8n, cambia la URL del webhook en Meta Business a la de n8n.

