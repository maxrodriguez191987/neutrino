#!/bin/bash

# Script para crear archivo .env de ejemplo
# Uso: ./scripts/setup-env.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⚙️  Configurando archivo .env...${NC}\n"

if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  El archivo .env ya existe. ¿Sobrescribir? (y/n)${NC}"
    read -r response
    if [ "$response" != "y" ]; then
        echo "Cancelado."
        exit 0
    fi
fi

cat > .env << 'EOF'
# ============================================
# WhatsApp Sales Automation - Variables de Entorno
# ============================================

# WhatsApp Cloud API
WHATSAPP_PHONE_NUMBER_ID=tu_phone_number_id
WHATSAPP_ACCESS_TOKEN=tu_access_token
WHATSAPP_VERIFY_TOKEN=tu_verify_token_personalizado

# Supabase
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key

# OpenAI
OPENAI_API_KEY=sk-tu_api_key

# n8n (si self-hosted)
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=tu_password_seguro
EOF

echo -e "${GREEN}✅ Archivo .env creado${NC}"
echo -e "\n${YELLOW}📝 Edita el archivo .env y completa con tus credenciales:${NC}"
echo "   1. WhatsApp Cloud API (Meta Business)"
echo "   2. Supabase (URL y keys)"
echo "   3. OpenAI (API key)"
echo "   4. n8n (si aplica)"
echo -e "\n${YELLOW}💡 Puedes usar los scripts de prueba:${NC}"
echo "   ./scripts/test-supabase.sh"
echo "   ./scripts/test-whatsapp.sh"
echo "   ./scripts/test-openai.sh"

