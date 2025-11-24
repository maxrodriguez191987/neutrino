#!/bin/bash

# Script de prueba para OpenAI
# Uso: ./scripts/test-openai.sh

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🤖 Probando OpenAI API...${NC}\n"

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}❌ Variable OPENAI_API_KEY no configurada${NC}"
    exit 1
fi

# Test 1: Verificar API Key
echo -e "${YELLOW}Test 1: Verificar API Key...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    "https://api.openai.com/v1/models")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ API Key válida${NC}"
    MODEL_COUNT=$(echo "$BODY" | jq '.data | length' 2>/dev/null || echo "N/A")
    echo "   Modelos disponibles: $MODEL_COUNT"
else
    echo -e "${RED}❌ Error (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    exit 1
fi

# Test 2: Probar interpretación de intención (simulando TON)
echo -e "\n${YELLOW}Test 2: Probar interpretación de intención...${NC}"

TON_INPUT='text:"hola quiero ver productos"
from:"5491122334455"
wa_id:"123456789"'

SYSTEM_PROMPT='Eres un asistente de ventas por WhatsApp. Interpreta mensajes y responde en formato TON.

Intenciones: saludo, pregunta_producto, otro

Responde SOLO en formato TON:
intent:"..."
response:"..."'

echo -e "${YELLOW}Enviando mensaje de prueba...${NC}"

RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"gpt-4o-mini\",
        \"messages\": [
            {
                \"role\": \"system\",
                \"content\": \"$SYSTEM_PROMPT\"
            },
            {
                \"role\": \"user\",
                \"content\": \"$TON_INPUT\"
            }
        ],
        \"temperature\": 0.3,
        \"max_tokens\": 200
    }" \
    "https://api.openai.com/v1/chat/completions")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Respuesta recibida${NC}"
    CONTENT=$(echo "$BODY" | jq -r '.choices[0].message.content' 2>/dev/null || echo "N/A")
    TOKENS=$(echo "$BODY" | jq -r '.usage.total_tokens' 2>/dev/null || echo "N/A")
    
    echo -e "\n${YELLOW}Respuesta:${NC}"
    echo "$CONTENT"
    echo -e "\n${YELLOW}Tokens usados: $TOKENS${NC}"
    
    # Verificar formato TON
    if echo "$CONTENT" | grep -q 'intent:'; then
        echo -e "${GREEN}✅ Formato TON válido${NC}"
        INTENT=$(echo "$CONTENT" | grep -o 'intent:"[^"]*' | cut -d'"' -f2)
        echo "   Intención detectada: $INTENT"
    else
        echo -e "${YELLOW}⚠️  Formato TON no detectado${NC}"
    fi
else
    echo -e "${RED}❌ Error (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    
    if echo "$BODY" | grep -q "insufficient_quota"; then
        echo -e "\n${YELLOW}💡 Cuota de API insuficiente. Verifica tu plan de OpenAI.${NC}"
    elif echo "$BODY" | grep -q "invalid_api_key"; then
        echo -e "\n${YELLOW}💡 API Key inválida. Verifica tu clave.${NC}"
    fi
fi

# Resumen
echo -e "\n${GREEN}✅ Pruebas completadas${NC}"

