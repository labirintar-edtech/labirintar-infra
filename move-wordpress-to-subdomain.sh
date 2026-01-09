#!/bin/bash

# Script para mover WordPress de subpath para subdomínio

set -e

echo "🔧 Movendo WordPress para subdomínio blog.labirintar.com.br"
echo ""

if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    exit 1
fi

echo "📝 Atualizando wp-config.php..."

# Remove defines antigas e adiciona novas
docker compose exec wordpress bash -c 'cat > /tmp/wp-config-new-defines.php << "WPEOF"
<?php
// Configuração para WordPress em subdomínio
define("WP_HOME", "https://blog.labirintar.com.br");
define("WP_SITEURL", "https://blog.labirintar.com.br");

// Corrige HTTPS quando atrás de proxy
if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {
    $_SERVER["HTTPS"] = "on";
}

WPEOF
'

# Remove defines antigas e filtros
docker compose exec wordpress bash -c '
# Remove linhas antigas
grep -v "WP_HOME\|WP_SITEURL\|HTTP_X_FORWARDED_PROTO\|add_filter.*option_home\|add_filter.*option_siteurl\|add_filter.*admin_url\|add_filter.*site_url\|add_filter.*home_url" /var/www/html/wp-config.php > /tmp/wp-config-clean.php

# Adiciona novas defines no topo
tail -n +2 /tmp/wp-config-clean.php > /tmp/wp-config-sem-php.php
cat /tmp/wp-config-new-defines.php /tmp/wp-config-sem-php.php > /var/www/html/wp-config.php

chown www-data:www-data /var/www/html/wp-config.php
chmod 644 /var/www/html/wp-config.php
'

echo "✅ wp-config.php atualizado"
echo ""

echo "📝 Criando .htaccess padrão..."

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

docker compose exec wordpress chown www-data:www-data /var/www/html/.htaccess
docker compose exec wordpress chmod 644 /var/www/html/.htaccess

echo "✅ .htaccess criado"
echo ""

echo "📝 Atualizando URLs no banco de dados..."

DB_PASS=$(grep WORDPRESS_DB_PASSWORD .env | cut -d '=' -f2 2>/dev/null || echo "wppassword")

docker compose exec -T db mysql -u wpuser -p${DB_PASS} wordpress << 'EOF'
-- Atualiza URLs principais
UPDATE wp_options SET option_value = 'https://blog.labirintar.com.br' WHERE option_name IN ('siteurl', 'home');

-- Atualiza conteúdo dos posts
UPDATE wp_posts SET post_content = REPLACE(post_content, 'https://labirintar.com.br/blog', 'https://blog.labirintar.com.br');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://labirintar.com.br/blog', 'https://blog.labirintar.com.br');

-- Atualiza GUIDs
UPDATE wp_posts SET guid = REPLACE(guid, 'https://labirintar.com.br/blog', 'https://blog.labirintar.com.br');
UPDATE wp_posts SET guid = REPLACE(guid, 'http://labirintar.com.br/blog', 'https://blog.labirintar.com.br');

-- Verifica
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF

echo ""
echo "✅ Banco de dados atualizado"
echo ""

echo "🔄 Reiniciando serviços..."
docker compose restart caddy wordpress

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "✅ Migração concluída!"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Configure o DNS:"
echo "   Tipo: A"
echo "   Nome: blog.labirintar.com.br"
echo "   Valor: IP_DA_VPS"
echo ""
echo "2. Aguarde propagação do DNS (5-30 minutos)"
echo ""
echo "3. Acesse:"
echo "   https://blog.labirintar.com.br"
echo "   https://blog.labirintar.com.br/wp-admin"
echo ""
echo "4. O Caddy vai obter certificado SSL automaticamente!"
echo ""
echo "🎉 MUITO MAIS SIMPLES que subpath! 🎉"
