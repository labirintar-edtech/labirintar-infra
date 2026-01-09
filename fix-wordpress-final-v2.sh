#!/bin/bash

# Script FINAL v2 - WordPress em subpath com handle_path

set -e

echo "🔧 Configuração WordPress em /blog (versão 2)"
echo ""

if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    exit 1
fi

echo "📝 Criando .htaccess para raiz (sem /blog)..."

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

echo "✅ .htaccess criado (RewriteBase /)"
echo ""

echo "📝 Atualizando wp-config.php com filtros do WordPress..."

docker compose exec wordpress bash -c 'cat > /tmp/wp-filters.php << "WPEOF"
// Força WordPress a usar URLs com /blog em todas as situações
add_filter("option_home", function($url) { return "https://labirintar.com.br/blog"; });
add_filter("option_siteurl", function($url) { return "https://labirintar.com.br/blog"; });
add_filter("admin_url", function($url) { return str_replace("https://labirintar.com.br/", "https://labirintar.com.br/blog/", $url); });
add_filter("site_url", function($url) { return str_replace("https://labirintar.com.br/", "https://labirintar.com.br/blog/", $url); });
add_filter("home_url", function($url) { return str_replace("https://labirintar.com.br/", "https://labirintar.com.br/blog/", $url); });

WPEOF
'

# Verifica se os filtros já existem
if ! docker compose exec wordpress grep -q "add_filter.*option_home" /var/www/html/wp-config.php; then
    echo "📝 Adicionando filtros ao wp-config.php..."
    
    # Adiciona os filtros antes da linha "That's all"
    docker compose exec wordpress bash -c '
    # Encontra a linha "That'"'"'s all" e adiciona os filtros antes
    sed -i "/That'"'"'s all, stop editing/i $(cat /tmp/wp-filters.php)" /var/www/html/wp-config.php
    '
    
    echo "✅ Filtros adicionados"
else
    echo "✅ Filtros já existem no wp-config.php"
fi

echo ""
echo "📝 Ajustando permissões..."
docker compose exec wordpress chown www-data:www-data /var/www/html/.htaccess
docker compose exec wordpress chmod 644 /var/www/html/.htaccess

echo ""
echo "🔄 Reiniciando serviços..."
docker compose restart caddy wordpress

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "🧪 TESTE:"
echo "   1. LIMPE TODO O CACHE DO NAVEGADOR"
echo "   2. Ou use MODO ANÔNIMO"
echo "   3. Acesse: https://labirintar.com.br/blog/wp-admin/"
echo ""
echo "Agora deve funcionar! 🎯"
