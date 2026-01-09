#!/bin/bash

# Script para corrigir .htaccess do WordPress em subpath

set -e

echo "🔧 Corrigindo .htaccess do WordPress"
echo ""

# Verifica se o container está rodando
if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    exit 1
fi

echo "📝 Verificando .htaccess atual..."
docker compose exec wordpress cat /var/www/html/.htaccess 2>/dev/null || echo "Arquivo não existe"

echo ""
echo "📝 Criando .htaccess correto..."

# Cria .htaccess correto
docker compose exec wordpress bash -c 'cat > /var/www/html/.htaccess << "EOF"
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF'

echo "✅ .htaccess criado"
echo ""

echo "📝 Verificando permissões..."
docker compose exec wordpress chown www-data:www-data /var/www/html/.htaccess
docker compose exec wordpress chmod 644 /var/www/html/.htaccess

echo "✅ Permissões corrigidas"
echo ""

echo "🔄 Reiniciando WordPress..."
docker compose restart wordpress

echo ""
echo "✅ Correção concluída!"
echo ""
echo "Teste agora: https://labirintar.com.br/blog/pagina-exemplo/"
