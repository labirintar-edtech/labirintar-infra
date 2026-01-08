#!/bin/bash

# Script para corrigir URLs do WordPress em subpath

set -e

echo "🔧 Corrigindo configuração do WordPress para subpath /blog"
echo ""

# Verifica se o container está rodando
if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    echo "Execute: docker compose up -d"
    exit 1
fi

echo "📝 Atualizando URLs no banco de dados..."

# Atualiza URLs no banco de dados
docker compose exec -T db mysql -u wpuser -p${WORDPRESS_DB_PASSWORD:-wppassword} wordpress << 'EOF'
UPDATE wp_options SET option_value = 'https://labirintar.com.br/blog' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'https://labirintar.com.br/blog' WHERE option_name = 'home';
EOF

echo "✅ URLs atualizadas no banco de dados"
echo ""

echo "📝 Verificando wp-config.php..."

# Verifica se já tem a configuração
if docker compose exec wordpress grep -q "WP_HOME" /var/www/html/wp-config.php 2>/dev/null; then
    echo "✅ wp-config.php já tem configuração de URLs"
else
    echo "⚠️  wp-config.php precisa ser configurado manualmente"
    echo ""
    echo "Execute:"
    echo "  docker compose exec wordpress bash"
    echo "  apt-get update && apt-get install -y nano"
    echo "  nano /var/www/html/wp-config.php"
    echo ""
    echo "E adicione após <?php:"
    echo ""
    cat << 'WPCONFIG'
define('WP_HOME', 'https://labirintar.com.br/blog');
define('WP_SITEURL', 'https://labirintar.com.br/blog');

if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Corrige redirecionamentos em subpath
if (!empty($_SERVER['HTTP_X_SCRIPT_NAME'])) {
    $_SERVER['PHP_SELF'] = $_SERVER['HTTP_X_SCRIPT_NAME'] . $_SERVER['PHP_SELF'];
    $_SERVER['REQUEST_URI'] = $_SERVER['HTTP_X_SCRIPT_NAME'] . $_SERVER['REQUEST_URI'];
}
WPCONFIG
fi

echo ""
echo "🔄 Reiniciando serviços..."
docker compose restart caddy wordpress

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "📋 Próximos passos:"
echo "  1. Limpe os cookies do navegador para labirintar.com.br"
echo "  2. Acesse: https://labirintar.com.br/blog/wp-admin"
echo "  3. Faça login"
echo ""
echo "Se ainda houver problemas, edite manualmente o wp-config.php"
