#!/bin/bash

# Prueba rápida de envío de WhatsApp
# Uso: ./scripts/quick-test-whatsapp.sh TU_NUMERO

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${YELLOW}Uso: ./scripts/quick-test-whatsapp.sh TU_NUMERO${NC}"
    echo -e "${YELLOW}Ejemplo: ./scripts/quick-test-whatsapp.sh 5491122334455${NC}"
    exit 1
fi

TO_NUMBER="$1"
MESSAGE="🧪 Mensaje de prueba del sistema de automatización"

export $(cat .env | grep -v '^#' | xargs)

if [ -z "$WHATSAPP_PHONE_NUMBER_ID" ] || [ -z "$WHATSAPP_ACCESS_TOKEN" ]; then
    echo -e "${RED}❌ Variables no configuradas${NC}"
    exit 1
fi

echo -e "${YELLOW}Enviando mensaje a $TO_NUMBER...${NC}"

RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $WHATSAPP_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"messaging_product\": \"whatsapp\",
        \"recipient_type\": \"individual\",
        \"to\": \"$TO_NUMBER\",
        \"type\": \"text\",
        \"text\": {
            \"preview_url\": false,
            \"body\": \"$MESSAGE\"
        }
    }" \
    "https://graph.facebook.com/v21.0/$WHATSAPP_PHONE_NUMBER_ID/messages")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Mensaje enviado exitosamente${NC}"
    echo "$BODY" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 | sed 's/^/   Message ID: /'
    echo -e "\n${YELLOW}📱 Verifica que recibiste el mensaje en WhatsApp${NC}"
else
    echo -e "${RED}❌ Error (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
fi

