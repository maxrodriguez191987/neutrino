# ⚠️ Requisito de Versión de Node.js

## 📋 Requisito

Este proyecto requiere **Node.js 20.0.0 o superior** debido a las dependencias de Supabase.

## 🔍 Verificar Tu Versión

```bash
node --version
```

Si ves `v18.x.x` o menor, necesitas actualizar.

## 🔄 Actualizar Node.js

### Opción 1: Usando nvm (Recomendado)

```bash
# Instalar nvm si no lo tienes
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reiniciar terminal o ejecutar:
source ~/.zshrc  # o ~/.bashrc

# Instalar Node.js 20
nvm install 20

# Usar Node.js 20
nvm use 20

# Verificar
node --version  # Debe mostrar v20.x.x
```

### Opción 2: Usando Homebrew (macOS)

```bash
# Actualizar Homebrew
brew update

# Instalar Node.js 20
brew install node@20

# O actualizar si ya tienes Node
brew upgrade node
```

### Opción 3: Descargar desde nodejs.org

1. Ve a [nodejs.org](https://nodejs.org/)
2. Descarga la versión LTS (20.x)
3. Instala el paquete
4. Reinicia la terminal

## ✅ Verificar Instalación

```bash
node --version  # Debe ser v20.x.x o superior
npm --version   # Debe ser 10.x.x o superior
```

## 🚀 Después de Actualizar

```bash
# Limpiar node_modules y reinstalar
rm -rf node_modules package-lock.json
npm install

# Compilar
npm run build
```

## 📝 Nota

Si no puedes actualizar Node.js, puedes:
- Usar una versión anterior de Supabase (no recomendado)
- Usar Docker para ejecutar con Node 20
- Usar solo n8n cloud (no requiere Node.js local)

