<?php
/**
 * Arquivo para corrigir WordPress em subpath
 * Adicione este código no wp-config.php do WordPress
 */

// Define as URLs corretas
define('WP_HOME', 'https://labirintar.com.br/blog');
define('WP_SITEURL', 'https://labirintar.com.br/blog');

// Corrige HTTPS quando atrás de proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Corrige o REQUEST_URI para WordPress funcionar em subpath
if (isset($_SERVER['HTTP_X_FORWARDED_PREFIX'])) {
    $_SERVER['REQUEST_URI'] = $_SERVER['HTTP_X_FORWARDED_PREFIX'] . $_SERVER['REQUEST_URI'];
}
