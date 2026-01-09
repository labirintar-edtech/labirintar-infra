#!/bin/bash

# Script para mover defines do WordPress para o topo do wp-config.php

set -e

echo "🔧 Reorganizando wp-config.php"
echo ""

# Verifica se o container está rodando
if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    exit 1
fi

echo "📝 Verificando localização atual das defines..."
docker compose exec wordpress grep -n "WP_HOME\|WP_SITEURL" /var/www/html/wp-config.php || echo "Defines não encontradas"

echo ""
echo "📝 Fazendo backup do wp-config.php..."
docker compose exec wordpress cp /var/www/html/wp-config.php /var/www/html/wp-config.php.backup.$(date +%Y%m%d-%H%M%S)

echo "✅ Backup criado"
echo ""

echo "📝 Removendo defines antigas e criando arquivo limpo..."

# Remove as linhas antigas de WP_HOME, WP_SITEURL e código relacionado
docker compose exec wordpress bash -c '
# Remove linhas com WP_HOME, WP_SITEURL e código de HTTPS/REQUEST_URI
grep -v "WP_HOME\|WP_SITEURL\|HTTP_X_FORWARDED_PROTO\|HTTP_X_SCRIPT_NAME\|PHP_SELF.*HTTP_X_SCRIPT_NAME\|REQUEST_URI.*HTTP_X_SCRIPT_NAME" /var/www/html/wp-config.php > /tmp/wp-config-clean.php

# Cria arquivo com defines corretas no topo
cat > /tmp/wp-config-final.php << "WPEOF"
<?php
// Configuração para WordPress em subpath - DEVE ESTAR NO TOPO!
define("WP_HOME", "https://labirintar.com.br/blog");
define("WP_SITEURL", "https://labirintar.com.br/blog");

// Corrige HTTPS quando atrás de proxy
if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {
    $_SERVER["HTTPS"] = "on";
}

WPEOF

# Remove a primeira linha <?php do arquivo limpo e concatena
tail -n +2 /tmp/wp-config-clean.php >> /tmp/wp-config-final.php

# Substitui o arquivo original
mv /tmp/wp-config-final.php /var/www/html/wp-config.php
chown www-data:www-data /var/www/html/wp-config.php
chmod 644 /var/www/html/wp-config.php
'

echo "✅ Arquivo reorganizado!"
echo ""

echo "📝 Verificando as primeiras 20 linhas do novo arquivo..."
docker compose exec wordpress head -20 /var/www/html/wp-config.php

echo ""
echo "🔄 Reiniciando WordPress..."
docker compose restart wordpress

echo ""
echo "✅ Concluído!"
echo ""
echo "🧪 Teste agora:"
echo "   1. Limpe o cache do navegador (Ctrl+Shift+Delete)"
echo "   2. Acesse: https://labirintar.com.br/blog/wp-admin/"
echo "   3. Clique nos menus laterais (Posts, Páginas, etc)"
echo ""
echo "Todos os links devem ter /blog agora! 🎯"
