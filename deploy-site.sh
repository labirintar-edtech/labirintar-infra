#!/bin/bash

# Script para fazer deploy de sites estáticos
# Uso: ./deploy-site.sh <nome-do-site> <caminho-do-build>

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica argumentos
if [ "$#" -ne 2 ]; then
    echo -e "${RED}Erro: Número incorreto de argumentos${NC}"
    echo "Uso: $0 <nome-do-site> <caminho-do-build>"
    echo ""
    echo "Exemplos:"
    echo "  $0 app /caminho/do/projeto/build"
    echo "  $0 landing /caminho/do/projeto/dist"
    exit 1
fi

SITE_NAME=$1
BUILD_PATH=$2
DEST_PATH="./sites/$SITE_NAME"

# Verifica se o caminho do build existe
if [ ! -d "$BUILD_PATH" ]; then
    echo -e "${RED}Erro: Caminho do build não encontrado: $BUILD_PATH${NC}"
    exit 1
fi

# Verifica se existe index.html no build
if [ ! -f "$BUILD_PATH/index.html" ]; then
    echo -e "${YELLOW}Aviso: index.html não encontrado em $BUILD_PATH${NC}"
    read -p "Deseja continuar mesmo assim? (s/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}🚀 Iniciando deploy do site: $SITE_NAME${NC}"
echo ""

# Cria pasta de destino se não existir
mkdir -p "$DEST_PATH"

# Backup do site atual (se existir)
if [ "$(ls -A $DEST_PATH)" ]; then
    BACKUP_PATH="./sites/.backups/$SITE_NAME-$(date +%Y%m%d-%H%M%S)"
    echo -e "${YELLOW}📦 Fazendo backup do site atual...${NC}"
    mkdir -p "./sites/.backups"
    cp -r "$DEST_PATH" "$BACKUP_PATH"
    echo -e "${GREEN}✓ Backup salvo em: $BACKUP_PATH${NC}"
    echo ""
fi

# Remove arquivos antigos
echo -e "${YELLOW}🗑️  Removendo arquivos antigos...${NC}"
rm -rf "$DEST_PATH"/*

# Copia novos arquivos
echo -e "${YELLOW}📁 Copiando novos arquivos...${NC}"
cp -r "$BUILD_PATH"/* "$DEST_PATH"/

# Conta arquivos copiados
FILE_COUNT=$(find "$DEST_PATH" -type f | wc -l)
echo -e "${GREEN}✓ $FILE_COUNT arquivos copiados${NC}"
echo ""

# Verifica se Caddy está rodando
if docker ps | grep -q caddy; then
    echo -e "${GREEN}✓ Caddy está rodando - site já está disponível!${NC}"
else
    echo -e "${YELLOW}⚠️  Caddy não está rodando. Inicie com: docker compose up -d${NC}"
fi

echo ""
echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
echo ""
echo "📝 Próximos passos:"
echo "  1. Configure o domínio no Caddyfile (conf/Caddyfile)"
echo "  2. Reinicie o Caddy: docker compose restart caddy"
echo "  3. Configure o DNS apontando para o IP da VPS"
echo ""
echo "📊 Tamanho total: $(du -sh "$DEST_PATH" | cut -f1)"
