# 📁 Configuração de Upload do WordPress (PHP)

## 🎯 Configuração Atual

O arquivo `php-custom.ini` está configurado com:

```ini
upload_max_filesize = 100M    # Tamanho máximo de arquivo individual
post_max_size = 100M          # Tamanho máximo do POST (deve ser >= upload_max_filesize)
max_execution_time = 300      # 5 minutos de timeout
memory_limit = 256M           # Memória máxima do PHP
```

## 🔧 Como Ajustar os Limites

### Método 1: Editar php-custom.ini (Recomendado)

1. **Edite o arquivo:**
```bash
nano php-custom.ini
```

2. **Ajuste os valores conforme necessário:**
```ini
upload_max_filesize = 200M    # Aumentar para 200MB
post_max_size = 200M          # Deve ser >= upload_max_filesize
```

3. **Reinicie o WordPress:**
```bash
docker compose restart wordpress
```

### Método 2: Via Variáveis de Ambiente

Adicione no `docker-compose.yml`:

```yaml
wordpress:
  environment:
    PHP_UPLOAD_MAX_FILESIZE: 200M
    PHP_POST_MAX_SIZE: 200M
    PHP_MAX_EXECUTION_TIME: 300
    PHP_MEMORY_LIMIT: 256M
```

## 📊 Limites Recomendados por Tipo de Site

### Blog Simples
```ini
upload_max_filesize = 50M
post_max_size = 50M
memory_limit = 128M
max_execution_time = 120
```

### Site com Muitas Imagens
```ini
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 256M
max_execution_time = 300
```

### Site com Vídeos/Arquivos Grandes
```ini
upload_max_filesize = 500M
post_max_size = 500M
memory_limit = 512M
max_execution_time = 600
```

### E-commerce (WooCommerce)
```ini
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 512M
max_execution_time = 300
```

## ⚠️ Importante: Caddy também tem limite!

O Caddyfile já está configurado com:

```caddy
request_body {
    max_size 100MB
}
```

**Se aumentar o PHP, aumente o Caddy também!**

Edite `conf/Caddyfile`:

```caddy
request_body {
    max_size 200MB    # Ajuste aqui
}
```

E recarregue:
```bash
docker compose restart caddy
```

## 🧪 Verificar Configuração Atual

### Via WordPress Admin

1. Acesse: **Mídia → Adicionar nova**
2. Veja o limite mostrado: "Tamanho máximo do arquivo: XXX MB"

### Via PHP Info

1. Crie arquivo `info.php` no WordPress:
```bash
docker compose exec wordpress bash -c 'echo "<?php phpinfo(); ?>" > /var/www/html/info.php'
```

2. Acesse: `https://labirintar.com.br/blog/info.php`

3. Procure por:
   - `upload_max_filesize`
   - `post_max_size`
   - `memory_limit`

4. **IMPORTANTE: Delete o arquivo depois:**
```bash
docker compose exec wordpress rm /var/www/html/info.php
```

### Via Linha de Comando

```bash
docker compose exec wordpress php -i | grep -E "upload_max_filesize|post_max_size|memory_limit"
```

## 🔄 Aplicar Mudanças

Sempre que alterar `php-custom.ini`:

```bash
# Reinicia apenas o WordPress
docker compose restart wordpress

# Verifica se aplicou
docker compose exec wordpress php -i | grep upload_max_filesize
```

## 📋 Checklist de Configuração

Para upload de arquivos grandes funcionar, verifique:

- [ ] `php-custom.ini` tem `upload_max_filesize` configurado
- [ ] `php-custom.ini` tem `post_max_size` >= `upload_max_filesize`
- [ ] `php-custom.ini` está montado no container (volume no docker-compose.yml)
- [ ] Caddyfile tem `request_body.max_size` >= `upload_max_filesize`
- [ ] WordPress foi reiniciado após mudanças
- [ ] Caddy foi reiniciado após mudanças no Caddyfile
- [ ] Testado upload no WordPress admin

## 🐛 Troubleshooting

### Upload falha mesmo com configuração correta

1. **Verifique se o arquivo está montado:**
```bash
docker compose exec wordpress cat /usr/local/etc/php/conf.d/custom.ini
```

2. **Verifique se o PHP leu o arquivo:**
```bash
docker compose exec wordpress php -i | grep "Configuration File"
```

3. **Verifique logs:**
```bash
docker compose logs wordpress --tail=50
```

### Erro "413 Request Entity Too Large"

Significa que o **Caddy** está bloqueando. Aumente o limite no Caddyfile:

```caddy
request_body {
    max_size 500MB    # Aumente conforme necessário
}
```

### Erro "The uploaded file exceeds the upload_max_filesize directive"

Significa que o **PHP** está bloqueando. Aumente no `php-custom.ini`.

### Upload para e não completa

Aumente o `max_execution_time` e `max_input_time`:

```ini
max_execution_time = 600    # 10 minutos
max_input_time = 600
```

## 💡 Dicas

1. **Sempre deixe `post_max_size` >= `upload_max_filesize`**
2. **Sempre deixe Caddy `max_size` >= PHP `upload_max_filesize`**
3. **Para vídeos grandes, considere usar serviços externos** (YouTube, Vimeo, S3)
4. **Monitore uso de disco** - arquivos grandes enchem o volume rapidamente
5. **Configure backup automático** antes de permitir uploads grandes

## 📊 Monitorar Uso de Disco

```bash
# Ver tamanho do volume do WordPress
docker system df -v | grep wp_data

# Ver arquivos maiores no WordPress
docker compose exec wordpress du -sh /var/www/html/wp-content/uploads/*
```

## 🔐 Segurança

Adicione no `wp-config.php` para restringir tipos de arquivo:

```php
define('ALLOW_UNFILTERED_UPLOADS', false);
```

E use plugin de segurança para escanear uploads maliciosos.
