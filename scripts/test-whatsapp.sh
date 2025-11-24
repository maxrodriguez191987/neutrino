#!/bin/bash

# Script de prueba para WhatsApp Cloud API
# Uso: ./scripts/test-whatsapp.sh

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📱 Probando WhatsApp Cloud API...${NC}\n"

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

if [ -z "$WHATSAPP_PHONE_NUMBER_ID" ] || [ -z "$WHATSAPP_ACCESS_TOKEN" ]; then
    echo -e "${RED}❌ Variables WHATSAPP_PHONE_NUMBER_ID o WHATSAPP_ACCESS_TOKEN no configuradas${NC}"
    exit 1
fi

# Test 1: Verificar información del número
echo -e "${YELLOW}Test 1: Verificar Phone Number ID...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $WHATSAPP_ACCESS_TOKEN" \
    "https://graph.facebook.com/v21.0/$WHATSAPP_PHONE_NUMBER_ID")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Phone Number ID válido${NC}"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Error (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    exit 1
fi

# Test 2: Enviar mensaje de prueba
echo -e "\n${YELLOW}Test 2: Enviar mensaje de prueba...${NC}"
echo -e "${YELLOW}⚠️  Ingresa el número de teléfono de destino (formato: 5491122334455):${NC}"
read -r TEST_PHONE

if [ -z "$TEST_PHONE" ]; then
    echo -e "${RED}❌ Número no proporcionado${NC}"
    exit 1
fi

echo -e "${YELLOW}Enviando mensaje a $TEST_PHONE...${NC}"

RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $WHATSAPP_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"messaging_product\": \"whatsapp\",
        \"recipient_type\": \"individual\",
        \"to\": \"$TEST_PHONE\",
        \"type\": \"text\",
        \"text\": {
            \"preview_url\": false,
            \"body\": \"🧪 Mensaje de prueba del sistema de automatización\"
        }
    }" \
    "https://graph.facebook.com/v21.0/$WHATSAPP_PHONE_NUMBER_ID/messages")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Mensaje enviado exitosamente${NC}"
    MESSAGE_ID=$(echo "$BODY" | jq -r '.messages[0].id' 2>/dev/null || echo "N/A")
    echo "   Message ID: $MESSAGE_ID"
    echo -e "\n${YELLOW}📱 Verifica que recibiste el mensaje en WhatsApp${NC}"
else
    echo -e "${RED}❌ Error al enviar mensaje (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    
    # Verificar errores comunes
    if echo "$BODY" | grep -q "invalid phone number"; then
        echo -e "\n${YELLOW}💡 El número debe estar en formato internacional sin +${NC}"
    elif echo "$BODY" | grep -q "rate limit"; then
        echo -e "\n${YELLOW}💡 Límite de rate alcanzado. Espera unos minutos.${NC}"
    elif echo "$BODY" | grep -q "expired"; then
        echo -e "\n${YELLOW}💡 El Access Token ha expirado. Genera uno nuevo.${NC}"
    fi
fi

# Resumen
echo -e "\n${GREEN}✅ Pruebas completadas${NC}"

