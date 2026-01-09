#!/bin/bash

# Script para adicionar defines do WordPress no wp-config.php

set -e

echo "🔧 Adicionando defines no wp-config.php"
echo ""

# Verifica se o container está rodando
if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    exit 1
fi

echo "📝 Fazendo backup do wp-config.php..."
docker compose exec wordpress cp /var/www/html/wp-config.php /var/www/html/wp-config.php.backup

echo "✅ Backup criado: wp-config.php.backup"
echo ""

echo "📝 Adicionando defines no início do arquivo..."

# Cria arquivo temporário com as defines
docker compose exec wordpress bash -c 'cat > /tmp/wp-defines.php << "WPEOF"
<?php
// Configuração para WordPress em subpath
define("WP_HOME", "https://labirintar.com.br/blog");
define("WP_SITEURL", "https://labirintar.com.br/blog");

// Corrige HTTPS quando atrás de proxy
if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {
    $_SERVER["HTTPS"] = "on";
}

WPEOF
'

# Remove a primeira linha <?php do wp-config.php original e adiciona as defines
docker compose exec wordpress bash -c '
tail -n +2 /var/www/html/wp-config.php > /tmp/wp-config-sem-php-tag.php
cat /tmp/wp-defines.php /tmp/wp-config-sem-php-tag.php > /var/www/html/wp-config.php
chown www-data:www-data /var/www/html/wp-config.php
chmod 644 /var/www/html/wp-config.php
'

echo "✅ Defines adicionadas!"
echo ""

echo "📝 Verificando as primeiras linhas do arquivo..."
docker compose exec wordpress head -15 /var/www/html/wp-config.php

echo ""
echo "🔄 Reiniciando WordPress..."
docker compose restart wordpress

echo ""
echo "✅ Concluído!"
echo ""
echo "🧪 Teste agora:"
echo "   1. Limpe o cache do navegador"
echo "   2. Acesse: https://labirintar.com.br/blog/wp-admin/"
echo "   3. Clique em qualquer menu lateral"
echo ""
echo "Os links devem estar corretos agora! 🎯"
