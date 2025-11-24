#!/bin/bash

# Script para configurar WhatsApp Cloud API
# Uso: ./scripts/setup-whatsapp.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📱 Configuración de WhatsApp Cloud API${NC}\n"

# Verificar .env
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Información que necesitas de Meta Business:${NC}\n"
echo "1. Phone Number ID: 921340014388774 (ya configurado)"
echo "2. Business Account ID: 5934072063556302 (ya configurado)"
echo "3. Access Token: (necesitas generarlo)"
echo "4. Verify Token: (puedes crear uno personalizado)"
echo ""

# Pedir Access Token
echo -e "${YELLOW}🔑 Ingresa tu Access Token de WhatsApp:${NC}"
echo -e "${YELLOW}(Puedes generarlo en Meta Business → 'Generar token de acceso')${NC}"
read -p "Access Token: " access_token

if [ -z "$access_token" ]; then
    echo -e "${RED}❌ Access Token no puede estar vacío${NC}"
    exit 1
fi

# Pedir Verify Token (opcional, con default)
echo ""
echo -e "${YELLOW}🔐 Ingresa Verify Token para webhook (o presiona Enter para usar default):${NC}"
read -p "Verify Token [mi_token_secreto_123]: " verify_token
verify_token=${verify_token:-mi_token_secreto_123}

# Actualizar .env
echo ""
echo -e "${YELLOW}📝 Actualizando .env...${NC}"

# Usar sed para actualizar (compatible con macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|WHATSAPP_ACCESS_TOKEN=.*|WHATSAPP_ACCESS_TOKEN=$access_token|" .env
    sed -i '' "s|WHATSAPP_VERIFY_TOKEN=.*|WHATSAPP_VERIFY_TOKEN=$verify_token|" .env
else
    # Linux
    sed -i "s|WHATSAPP_ACCESS_TOKEN=.*|WHATSAPP_ACCESS_TOKEN=$access_token|" .env
    sed -i "s|WHATSAPP_VERIFY_TOKEN=.*|WHATSAPP_VERIFY_TOKEN=$verify_token|" .env
fi

echo -e "${GREEN}✅ .env actualizado${NC}\n"

# Probar conexión
echo -e "${YELLOW}🧪 Probando conexión con WhatsApp...${NC}\n"

PHONE_NUMBER_ID=$(grep WHATSAPP_PHONE_NUMBER_ID .env | cut -d '=' -f2)

response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $access_token" \
    "https://graph.facebook.com/v22.0/$PHONE_NUMBER_ID")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✅ Conexión exitosa con WhatsApp Cloud API${NC}"
    echo "$body" | head -5
else
    echo -e "${RED}❌ Error de conexión (HTTP $http_code)${NC}"
    echo "$body"
    echo ""
    echo -e "${YELLOW}💡 Verifica:${NC}"
    echo "   - El Access Token es correcto"
    echo "   - El Phone Number ID es correcto"
    echo "   - Tienes permisos en Meta Business"
fi

echo ""
echo -e "${BLUE}📝 Próximos pasos:${NC}"
echo "1. ✅ Credenciales configuradas"
echo "2. ⏭️  Configurar webhook en Meta Business"
echo "3. ⏭️  Probar envío de mensaje: ./scripts/test-whatsapp.sh"
echo ""
echo -e "${YELLOW}💡 Para configurar el webhook:${NC}"
echo "   - Ve a Meta Business → WhatsApp → Configuration → Webhooks"
echo "   - URL: https://tu-n8n.com/webhook/{id} (o URL de ngrok si es local)"
echo "   - Verify Token: $verify_token"
echo "   - Suscríbete a: messages"

