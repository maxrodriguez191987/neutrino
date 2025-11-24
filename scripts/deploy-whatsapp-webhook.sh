#!/bin/bash

# Script para deployar WhatsApp Webhook en Supabase
# Uso: ./scripts/deploy-whatsapp-webhook.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploy de WhatsApp Webhook a Supabase${NC}\n"

# Verificar Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI no está instalado${NC}"
    echo -e "${YELLOW}Instala con:${NC}"
    echo "   brew install supabase/tap/supabase"
    echo "   # o"
    echo "   npm install -g supabase"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI encontrado${NC}\n"

# Verificar si está logueado
echo -e "${YELLOW}Verificando sesión de Supabase...${NC}"
if ! supabase projects list &> /dev/null; then
    echo -e "${YELLOW}Necesitas iniciar sesión en Supabase${NC}"
    supabase login
fi

# Verificar .env
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

# Cargar variables
export $(cat .env | grep -v '^#' | xargs)

# Verificar variables necesarias
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo -e "${RED}❌ Variables SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY no configuradas${NC}"
    exit 1
fi

# Linkear proyecto si no está linkeado
if [ ! -f supabase/.temp/project-ref ]; then
    echo -e "${YELLOW}Linkeando proyecto...${NC}"
    supabase link --project-ref synwylrcxggklbpstawy
fi

# Configurar secrets
echo -e "${YELLOW}Configurando secrets...${NC}"
supabase secrets set WHATSAPP_VERIFY_TOKEN="${WHATSAPP_VERIFY_TOKEN:-mi_token_webhook_123}"
supabase secrets set SUPABASE_URL="$SUPABASE_URL"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY"

# Deploy
echo -e "${YELLOW}Deployando función...${NC}"
supabase functions deploy whatsapp-webhook

# Obtener URL
echo -e "\n${GREEN}✅ Deploy completado${NC}\n"
echo -e "${BLUE}📋 URL del webhook:${NC}"
supabase functions list | grep whatsapp-webhook || echo "https://synwylrcxggklbpstawy.supabase.co/functions/v1/whatsapp-webhook"

echo -e "\n${YELLOW}📝 Próximos pasos:${NC}"
echo "1. Copia la URL del webhook"
echo "2. Ve a Meta Business → WhatsApp → Configuration → Webhooks"
echo "3. Pega la URL en 'Callback URL'"
echo "4. Verify Token: ${WHATSAPP_VERIFY_TOKEN:-mi_token_webhook_123}"
echo "5. Suscríbete a: messages"

