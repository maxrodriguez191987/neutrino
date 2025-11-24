#!/bin/bash

# Script para levantar el proyecto completo
# Uso: ./scripts/start.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Levantando WhatsApp Sales Automation...${NC}\n"

# Verificar que .env existe
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    echo -e "${YELLOW}Ejecuta: ./scripts/setup-env.sh${NC}"
    exit 1
fi

# Cargar variables de entorno
export $(cat .env | grep -v '^#' | xargs)

echo -e "${YELLOW}📋 Verificando configuración...${NC}\n"

# Verificar variables críticas
MISSING_VARS=()

if [ -z "$SUPABASE_URL" ]; then
    MISSING_VARS+=("SUPABASE_URL")
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    MISSING_VARS+=("SUPABASE_ANON_KEY")
fi

if [ -z "$OPENAI_API_KEY" ]; then
    MISSING_VARS+=("OPENAI_API_KEY")
fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo -e "${RED}❌ Variables faltantes en .env:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

echo -e "${GREEN}✅ Variables de entorno configuradas${NC}\n"

# Opciones
echo -e "${YELLOW}¿Cómo quieres levantar n8n?${NC}"
echo "1) Docker Compose (recomendado)"
echo "2) Docker directo"
echo "3) npm global"
echo "4) Solo verificar (no levantar)"
read -p "Opción [1-4]: " option

case $option in
    1)
        echo -e "\n${YELLOW}🐳 Levantando con Docker Compose...${NC}"
        if [ ! -f docker-compose.yml ]; then
            echo -e "${RED}❌ docker-compose.yml no encontrado${NC}"
            exit 1
        fi
        docker-compose up -d
        echo -e "${GREEN}✅ n8n levantado en http://localhost:5678${NC}"
        echo -e "${YELLOW}📝 Usuario: ${N8N_BASIC_AUTH_USER:-admin}${NC}"
        echo -e "${YELLOW}📝 Password: ${N8N_BASIC_AUTH_PASSWORD:-changeme}${NC}"
        ;;
    2)
        echo -e "\n${YELLOW}🐳 Levantando con Docker...${NC}"
        docker run -d \
            --name n8n \
            -p 5678:5678 \
            -v ~/.n8n:/home/node/.n8n \
            -e N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER:-admin} \
            -e N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD:-changeme} \
            -e WHATSAPP_PHONE_NUMBER_ID=${WHATSAPP_PHONE_NUMBER_ID} \
            -e WHATSAPP_ACCESS_TOKEN=${WHATSAPP_ACCESS_TOKEN} \
            -e SUPABASE_URL=${SUPABASE_URL} \
            -e SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
            -e OPENAI_API_KEY=${OPENAI_API_KEY} \
            n8nio/n8n
        echo -e "${GREEN}✅ n8n levantado en http://localhost:5678${NC}"
        ;;
    3)
        echo -e "\n${YELLOW}📦 Verificando n8n instalado...${NC}"
        if ! command -v n8n &> /dev/null; then
            echo -e "${YELLOW}Instalando n8n...${NC}"
            npm install -g n8n
        fi
        echo -e "${GREEN}✅ Iniciando n8n...${NC}"
        echo -e "${YELLOW}⚠️  n8n se ejecutará en esta terminal${NC}"
        echo -e "${YELLOW}Presiona Ctrl+C para detener${NC}\n"
        n8n start
        ;;
    4)
        echo -e "\n${YELLOW}✅ Verificación completada${NC}"
        echo -e "${GREEN}Todo está configurado correctamente${NC}"
        echo -e "\n${YELLOW}Próximos pasos:${NC}"
        echo "1. Levanta n8n manualmente"
        echo "2. Importa workflows desde workflows/"
        echo "3. Configura credenciales en n8n"
        echo "4. Activa los workflows"
        ;;
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}✅ Setup completado${NC}\n"
echo -e "${YELLOW}📝 Próximos pasos:${NC}"
echo "1. Accede a n8n: http://localhost:5678"
echo "2. Importa workflows desde workflows/"
echo "3. Configura credenciales (OpenAI, WhatsApp, Supabase)"
echo "4. Configura variables de entorno en n8n"
echo "5. Activa el workflow"
echo "6. Configura webhook en Meta Business Manager"
echo -e "\n${YELLOW}📚 Lee SETUP.md para más detalles${NC}"

