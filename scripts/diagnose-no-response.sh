#!/bin/bash

# Script de diagnóstico para cuando no responde

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Diagnóstico: Webhook No Responde${NC}\n"

echo "1. Verificando webhook URL..."
WEBHOOK_URL="https://synwylrcxggklbpstawy.supabase.co/functions/v1/whatsapp-webhook"
VERIFY_TOKEN="mi_token_secreto_123"

RESPONSE=$(curl -s "$WEBHOOK_URL?hub.mode=subscribe&hub.verify_token=$VERIFY_TOKEN&hub.challenge=test123" 2>&1)
if [ "$RESPONSE" == "test123" ]; then
    echo -e "${GREEN}✅ Webhook verifica correctamente${NC}"
else
    echo -e "${RED}❌ Webhook no verifica (respuesta: $RESPONSE)${NC}"
fi

echo ""
echo "2. Verificando .env..."
if [ -f .env ]; then
    source .env
    if [ -n "$WHATSAPP_ACCESS_TOKEN" ] && [ -n "$WHATSAPP_PHONE_NUMBER_ID" ]; then
        echo -e "${GREEN}✅ Variables en .env configuradas${NC}"
        echo "   Access Token: ${WHATSAPP_ACCESS_TOKEN:0:20}..."
        echo "   Phone ID: $WHATSAPP_PHONE_NUMBER_ID"
    else
        echo -e "${RED}❌ Faltan variables en .env${NC}"
    fi
else
    echo -e "${RED}❌ Archivo .env no existe${NC}"
fi

echo ""
echo "3. Verificando secrets en Supabase..."
# Nota: Los secrets no se pueden leer, solo verificar que existan

echo ""
echo -e "${YELLOW}📋 CHECKLIST MANUAL:${NC}"
echo ""
echo "En Meta Business Manager:"
echo "  [ ] Webhook está 'Verificado y guardado'"
echo "  [ ] Webhook está suscrito a 'messages' (MUY IMPORTANTE)"
echo "  [ ] URL del webhook: $WEBHOOK_URL"
echo "  [ ] Verify Token: $VERIFY_TOKEN"
echo ""
echo "En Destinatarios de Prueba:"
echo "  [ ] El número está agregado"
echo "  [ ] El número está verificado con código"
echo ""
echo "Para verificar suscripción a 'messages':"
echo "  1. Meta Business → WhatsApp → Configuration → Webhooks"
echo "  2. Haz clic en 'Configurar' o 'Manage' del webhook"
echo "  3. Verifica que 'messages' esté seleccionado ✅"
echo ""
echo -e "${YELLOW}📝 Para ver logs en tiempo real:${NC}"
echo "  1. Ve a Supabase Dashboard"
echo "  2. Edge Functions → whatsapp-webhook → Logs"
echo "  3. Envía un mensaje desde tu WhatsApp"
echo "  4. Observa los logs en tiempo real"
echo ""

