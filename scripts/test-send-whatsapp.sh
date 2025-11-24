#!/bin/bash

# Script para enviar mensaje de prueba a WhatsApp
# Uso: ./scripts/test-send-whatsapp.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📱 Enviar Mensaje de Prueba por WhatsApp${NC}\n"

# Cargar variables de entorno
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

export $(cat .env | grep -v '^#' | xargs)

if [ -z "$WHATSAPP_PHONE_NUMBER_ID" ] || [ -z "$WHATSAPP_ACCESS_TOKEN" ]; then
    echo -e "${RED}❌ Variables WHATSAPP_PHONE_NUMBER_ID o WHATSAPP_ACCESS_TOKEN no configuradas${NC}"
    echo -e "${YELLOW}Configura estas variables en .env:${NC}"
    echo "   WHATSAPP_PHONE_NUMBER_ID=15551651361"
    echo "   WHATSAPP_ACCESS_TOKEN=tu_token_aqui"
    exit 1
fi

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "   El número de destino debe estar agregado como 'Destinatario de prueba' en Meta Business"
echo "   Solo puedes enviar a números que hayas agregado manualmente"
echo ""

echo -e "${YELLOW}Ingresa el número de teléfono de destino (formato: 5491122334455):${NC}"
read -r TO_NUMBER

if [ -z "$TO_NUMBER" ]; then
    echo -e "${RED}❌ Número no proporcionado${NC}"
    exit 1
fi

echo -e "${YELLOW}Ingresa el mensaje a enviar:${NC}"
read -r MESSAGE

if [ -z "$MESSAGE" ]; then
    MESSAGE="🧪 Mensaje de prueba del sistema de automatización"
    echo -e "${YELLOW}Usando mensaje por defecto: ${MESSAGE}${NC}"
fi

echo ""
echo -e "${YELLOW}Enviando mensaje...${NC}"

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
    MESSAGE_ID=$(echo "$BODY" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || echo "N/A")
    echo "   Message ID: $MESSAGE_ID"
    echo -e "\n${YELLOW}📱 Verifica que recibiste el mensaje en WhatsApp${NC}"
else
    echo -e "${RED}❌ Error al enviar mensaje (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    
    # Verificar errores comunes
    if echo "$BODY" | grep -q "invalid phone number"; then
        echo -e "\n${YELLOW}💡 El número debe estar agregado como 'Destinatario de prueba' en Meta Business${NC}"
    elif echo "$BODY" | grep -q "rate limit"; then
        echo -e "\n${YELLOW}💡 Límite de rate alcanzado. Espera unos minutos.${NC}"
    elif echo "$BODY" | grep -q "expired"; then
        echo -e "\n${YELLOW}💡 El Access Token ha expirado. Genera uno nuevo.${NC}"
    fi
fi

