#!/bin/bash

# Script de prueba para Supabase
# Uso: ./scripts/test-supabase.sh

set -e

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧪 Probando conexión con Supabase...${NC}\n"

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    echo "Crea un archivo .env con:"
    echo "SUPABASE_URL=https://xxx.supabase.co"
    echo "SUPABASE_ANON_KEY=xxx"
    exit 1
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}❌ Variables SUPABASE_URL o SUPABASE_ANON_KEY no configuradas${NC}"
    exit 1
fi

# Test 1: Verificar conexión
echo -e "${YELLOW}Test 1: Verificar conexión...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    "$SUPABASE_URL/rest/v1/products?limit=1")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Conexión exitosa${NC}"
else
    echo -e "${RED}❌ Error de conexión (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    exit 1
fi

# Test 2: Verificar tablas
echo -e "\n${YELLOW}Test 2: Verificar tablas...${NC}"
TABLES=("products" "customers" "carts" "orders")

for TABLE in "${TABLES[@]}"; do
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -H "apikey: $SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        "$SUPABASE_URL/rest/v1/$TABLE?limit=1")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✅ Tabla '$TABLE' existe${NC}"
    else
        echo -e "${RED}❌ Tabla '$TABLE' no encontrada (HTTP $HTTP_CODE)${NC}"
    fi
done

# Test 3: Crear cliente de prueba
echo -e "\n${YELLOW}Test 3: Crear cliente de prueba...${NC}"
TEST_PHONE="549999999999"
TEST_CUSTOMER=$(curl -s -X POST \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{\"phone\":\"$TEST_PHONE\",\"name\":\"Test User\",\"plan\":\"basic\"}" \
    "$SUPABASE_URL/rest/v1/customers")

if echo "$TEST_CUSTOMER" | grep -q "$TEST_PHONE"; then
    echo -e "${GREEN}✅ Cliente creado exitosamente${NC}"
    CUSTOMER_ID=$(echo "$TEST_CUSTOMER" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
    echo "   ID: $CUSTOMER_ID"
else
    echo -e "${YELLOW}⚠️  Cliente ya existe o error al crear${NC}"
    # Intentar obtener cliente existente
    EXISTING=$(curl -s \
        -H "apikey: $SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        "$SUPABASE_URL/rest/v1/customers?phone=eq.$TEST_PHONE")
    CUSTOMER_ID=$(echo "$EXISTING" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
fi

# Test 4: Verificar funciones RPC
echo -e "\n${YELLOW}Test 4: Verificar funciones RPC...${NC}"
FUNCTIONS=("add_to_cart" "create_order_from_cart" "get_or_create_customer")

for FUNC in "${FUNCTIONS[@]}"; do
    # Intentar llamar función (puede fallar pero verifica que existe)
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "apikey: $SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        -H "Content-Type: application/json" \
        -d "{}" \
        "$SUPABASE_URL/rest/v1/rpc/$FUNC" 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 400 ]; then
        # 400 significa que la función existe pero los parámetros son incorrectos
        echo -e "${GREEN}✅ Función '$FUNC' existe${NC}"
    else
        echo -e "${RED}❌ Función '$FUNC' no encontrada (HTTP $HTTP_CODE)${NC}"
    fi
done

# Resumen
echo -e "\n${GREEN}✅ Pruebas completadas${NC}"
echo -e "\n${YELLOW}📝 Próximos pasos:${NC}"
echo "1. Configura n8n con estas credenciales"
echo "2. Importa los workflows"
echo "3. Configura WhatsApp Cloud API"
echo "4. Prueba el flujo completo"

