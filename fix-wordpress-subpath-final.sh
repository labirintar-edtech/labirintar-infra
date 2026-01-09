#!/bin/bash

# Script final para corrigir WordPress em subpath

set -e

echo "🔧 Configuração FINAL do WordPress em /blog"
echo ""

# Verifica se o container está rodando
if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    exit 1
fi

echo "📝 Criando .htaccess correto para subpath..."

docker compose exec wordpress bash -c 'cat > /var/www/html/.htaccess << "EOF"
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /blog/
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /blog/index.php [L]
</IfModule>
# END WordPress
EOF'

echo "✅ .htaccess criado com RewriteBase /blog/"
echo ""

echo "📝 Ajustando permissões..."
docker compose exec wordpress chown www-data:www-data /var/www/html/.htaccess
docker compose exec wordpress chmod 644 /var/www/html/.htaccess

echo "✅ Permissões ajustadas"
echo ""

echo "📝 Verificando wp-config.php..."
docker compose exec wordpress head -15 /var/www/html/wp-config.php

echo ""
echo "🔄 Reiniciando Caddy e WordPress..."
docker compose restart caddy wordpress

echo ""
echo "⏳ Aguardando serviços iniciarem..."
sleep 5

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "🧪 TESTE AGORA:"
echo "   1. Limpe TODO o cache do navegador (Ctrl+Shift+Delete)"
echo "   2. Ou use modo anônimo/privado"
echo "   3. Acesse: https://labirintar.com.br/blog/wp-admin/"
echo "   4. Faça login"
echo "   5. Clique em Posts, Páginas, Plugins, etc"
echo ""
echo "Todos os links devem ter /blog agora! 🎯"
