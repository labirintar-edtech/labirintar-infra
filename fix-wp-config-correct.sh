#!/bin/bash

# Script para corrigir wp-config.php com a configuração correta

set -e

echo "🔧 Corrigindo wp-config.php do WordPress"
echo ""

# Verifica se o container está rodando
if ! docker ps | grep -q wordpress; then
    echo "❌ Container WordPress não está rodando!"
    echo "Execute: docker compose up -d"
    exit 1
fi

echo "📝 Criando wp-config.php correto..."

# Cria arquivo temporário com a configuração correta
cat > /tmp/wp-config-fix.php << 'EOF'
<?php

// Configuração para WordPress em subpath
define('WP_HOME', 'https://labirintar.com.br/blog');
define('WP_SITEURL', 'https://labirintar.com.br/blog');

// Corrige HTTPS quando atrás de proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// NÃO ADICIONE MAIS NADA AQUI - o código de REQUEST_URI causa loop!
EOF

echo "✅ Arquivo de configuração criado"
echo ""
echo "📋 INSTRUÇÕES MANUAIS:"
echo ""
echo "1. Acesse o container:"
echo "   docker compose exec wordpress bash"
echo ""
echo "2. Instale o nano:"
echo "   apt-get update && apt-get install -y nano"
echo ""
echo "3. Edite o wp-config.php:"
echo "   nano /var/www/html/wp-config.php"
echo ""
echo "4. REMOVA estas linhas se existirem (causam o erro!):"
echo "   if (!empty(\$_SERVER['HTTP_X_SCRIPT_NAME'])) {"
echo "       \$_SERVER['PHP_SELF'] = \$_SERVER['HTTP_X_SCRIPT_NAME'] . \$_SERVER['PHP_SELF'];"
echo "       \$_SERVER['REQUEST_URI'] = \$_SERVER['HTTP_X_SCRIPT_NAME'] . \$_SERVER['REQUEST_URI'];"
echo "   }"
echo ""
echo "5. Deixe APENAS estas linhas logo após <?php:"
echo ""
cat /tmp/wp-config-fix.php
echo ""
echo "6. Salve: Ctrl+X, Y, Enter"
echo ""
echo "7. Saia: exit"
echo ""
echo "8. Reinicie: docker compose restart wordpress"
echo ""

rm /tmp/wp-config-fix.php
