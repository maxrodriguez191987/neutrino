#!/bin/bash

# Script para probar el webhook de WhatsApp
# Uso: ./scripts/test-webhook.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

WEBHOOK_URL="https://synwylrcxggklbpstawy.supabase.co/functions/v1/whatsapp-webhook"

# Cargar token desde .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi
VERIFY_TOKEN="${WHATSAPP_VERIFY_TOKEN:-mi_token_webhook_123}"

echo -e "${BLUE}🧪 Probando Webhook de WhatsApp${NC}\n"

# Test 1: Verificación GET (como Meta lo hace)
echo -e "${YELLOW}Test 1: Verificación GET (hub.mode=subscribe)${NC}"
CHALLENGE="test_challenge_123"
response=$(curl -s -w "\n%{http_code}" \
    "$WEBHOOK_URL?hub.mode=subscribe&hub.verify_token=$VERIFY_TOKEN&hub.challenge=$CHALLENGE")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ] && [ "$body" == "$CHALLENGE" ]; then
    echo -e "${GREEN}✅ Verificación exitosa${NC}"
    echo "   Respuesta: $body"
else
    echo -e "${RED}❌ Error en verificación (HTTP $http_code)${NC}"
    echo "   Respuesta: $body"
    echo ""
    echo -e "${YELLOW}💡 Posibles causas:${NC}"
    echo "   - La función no está deployada"
    echo "   - El token no coincide"
    echo "   - La función tiene un error"
fi

echo ""

# Test 2: Verificación con token incorrecto
echo -e "${YELLOW}Test 2: Verificación con token incorrecto (debe fallar)${NC}"
response=$(curl -s -w "\n%{http_code}" \
    "$WEBHOOK_URL?hub.mode=subscribe&hub.verify_token=token_incorrecto&hub.challenge=$CHALLENGE")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 403 ]; then
    echo -e "${GREEN}✅ Rechazo correcto de token inválido${NC}"
else
    echo -e "${YELLOW}⚠️  Respuesta inesperada (HTTP $http_code)${NC}"
    echo "   Respuesta: $body"
fi

echo ""

# Test 3: POST request (simulando mensaje)
echo -e "${YELLOW}Test 3: POST request (simulando mensaje)${NC}"
response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "entry": [{
            "changes": [{
                "value": {
                    "messages": [{
                        "from": "5491122334455",
                        "id": "wamid.test",
                        "text": {
                            "body": "Hola"
                        },
                        "type": "text"
                    }],
                    "contacts": [{
                        "profile": {
                            "name": "Test User"
                        },
                        "wa_id": "5491122334455"
                    }]
                }
            }]
        }]
    }' \
    "$WEBHOOK_URL")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✅ Mensaje procesado correctamente${NC}"
    echo "   Respuesta: $body"
else
    echo -e "${RED}❌ Error procesando mensaje (HTTP $http_code)${NC}"
    echo "   Respuesta: $body"
fi

echo ""
echo -e "${BLUE}📝 Resumen:${NC}"
echo "   Si todos los tests pasan, el webhook está listo para Meta Business"
echo "   Si fallan, verifica que la función esté deployada:"
echo "   ./scripts/deploy-whatsapp-webhook.sh"

