# 🚀 Guía de Inicio Rápido

Guía paso a paso para probar el sistema en 15 minutos.

## ⚡ Inicio Rápido (5 pasos)

### 1️⃣ Configurar Variables de Entorno

```bash
# Crear archivo .env
./scripts/setup-env.sh

# Editar .env con tus credenciales
nano .env  # o usa tu editor favorito
```

### 2️⃣ Probar Conexiones

```bash
# Probar Supabase
./scripts/test-supabase.sh

# Probar WhatsApp
./scripts/test-whatsapp.sh

# Probar OpenAI
./scripts/test-openai.sh
```

### 3️⃣ Configurar Supabase

1. Ve a [supabase.com](https://supabase.com) y crea proyecto
2. En SQL Editor, ejecuta:
   - `supabase/schema.sql`
   - `supabase/functions.sql`
   - `supabase/seed.sql` (opcional)

### 4️⃣ Configurar n8n

#### Opción A: n8n Cloud (Recomendado para pruebas)
1. Ve a [n8n.io](https://n8n.io)
2. Crea cuenta gratuita
3. Importa `workflows/basic.json`
4. Configura credenciales:
   - OpenAI API
   - WhatsApp Cloud API (HTTP Header Auth)
   - Supabase API (HTTP Header Auth)
5. Configura variables de entorno en Settings
6. Activa el workflow

#### Opción B: n8n Local
```bash
# Con Docker
docker run -it --rm --name n8n -p 5678:5678 n8nio/n8n

# Accede a http://localhost:5678
# Usa ngrok para exponer: ngrok http 5678
```

### 5️⃣ Configurar WhatsApp Webhook

1. Ve a [Meta Business Manager](https://business.facebook.com)
2. WhatsApp → Configuration → Webhooks
3. URL: `https://tu-n8n.com/webhook/abc123` (o URL de ngrok)
4. Verify Token: El que configuraste
5. Suscríbete a: `messages`

## 🧪 Probar el Sistema

### Test Básico

1. **Envía mensaje por WhatsApp**: `"Hola"`
2. **Verifica en n8n**: Ve a "Executions" y revisa el flujo
3. **Recibe respuesta**: Deberías recibir respuesta automática

### Test Avanzado (Plan Pro)

1. **Agrega cliente en Supabase**:
   ```sql
   INSERT INTO customers (phone, name, plan) 
   VALUES ('5491122334455', 'Test User', 'pro');
   ```

2. **Envía**: `"Quiero agregar iPhone al carrito"`
3. **Verifica**: Deberías recibir confirmación

## 📋 Checklist Rápido

- [ ] Archivo .env configurado
- [ ] Supabase conecta (test-supabase.sh ✅)
- [ ] WhatsApp funciona (test-whatsapp.sh ✅)
- [ ] OpenAI funciona (test-openai.sh ✅)
- [ ] n8n workflow importado y activo
- [ ] Webhook configurado en Meta
- [ ] Mensaje de prueba enviado y recibido

## 🐛 Problemas Comunes

### "Webhook no recibe mensajes"
- Verifica que n8n está activo
- Verifica URL en Meta Business Manager
- Usa ngrok si es local

### "OpenAI no responde"
- Verifica API Key
- Revisa límites de rate
- Verifica formato TON

### "Supabase error 401"
- Verifica API Key
- Revisa políticas RLS (desactiva temporalmente)

## 📚 Documentación Completa

- [TESTING.md](TESTING.md) - Guía completa de pruebas
- [README.md](README.md) - Documentación principal
- [docs/](docs/) - Documentación técnica

## 🎯 Próximos Pasos

1. ✅ Sistema básico funcionando
2. 🔄 Probar plan Pro (carrito y pedidos)
3. 🚀 Probar plan Full (mensajes salientes)
4. 📊 Configurar monitoreo y métricas
5. 🎨 Personalizar prompts y respuestas

---

**¿Necesitas ayuda?** Revisa [TESTING.md](TESTING.md) para guía detallada.

