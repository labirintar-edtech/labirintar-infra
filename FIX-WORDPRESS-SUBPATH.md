# 🔧 Correção: WordPress em Subpath - ERR_TOO_MANY_REDIRECTS

## 🚨 Problema

Ao acessar `https://labirintar.com.br/blog/wp-admin/` ocorre erro:
```
ERR_TOO_MANY_REDIRECTS
```

## ✅ Solução

### Método 1: Configurar via wp-config.php (Recomendado)

#### Passo 1: Acesse o container do WordPress

```bash
docker compose exec wordpress bash
```

#### Passo 2: Instale um editor de texto

```bash
apt-get update && apt-get install -y nano
```

#### Passo 3: Edite o wp-config.php

```bash
nano /var/www/html/wp-config.php
```

#### Passo 4: Adicione estas linhas LOGO APÓS `<?php`

```php
<?php

// Configuração para WordPress em subpath
define('WP_HOME', 'https://labirintar.com.br/blog');
define('WP_SITEURL', 'https://labirintar.com.br/blog');

// Corrige HTTPS quando atrás de proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Resto do arquivo wp-config.php continua aqui...
```

#### Passo 5: Salve e saia

- Pressione `Ctrl + X`
- Pressione `Y` para confirmar
- Pressione `Enter`

#### Passo 6: Saia do container

```bash
exit
```

#### Passo 7: Reinicie o WordPress

```bash
docker compose restart wordpress
```

#### Passo 8: Limpe o cache do navegador

- Abra o DevTools (F12)
- Clique com botão direito no ícone de recarregar
- Selecione "Esvaziar cache e recarregar forçadamente"

Ou simplesmente:
- Chrome/Edge: `Ctrl + Shift + Delete` → Limpar cookies e cache
- Firefox: `Ctrl + Shift + Delete` → Limpar cookies e cache

---

### Método 2: Via Banco de Dados (Se o Método 1 não funcionar)

#### Passo 1: Acesse o MySQL

```bash
docker compose exec db mysql -u wpuser -p${WORDPRESS_DB_PASSWORD} wordpress
```

#### Passo 2: Atualize as URLs no banco

```sql
UPDATE wp_options SET option_value = 'https://labirintar.com.br/blog' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'https://labirintar.com.br/blog' WHERE option_name = 'home';
```

#### Passo 3: Verifique

```sql
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
```

Deve mostrar:
```
+-------------+----------------------------------+
| option_name | option_value                     |
+-------------+----------------------------------+
| home        | https://labirintar.com.br/blog   |
| siteurl     | https://labirintar.com.br/blog   |
+-------------+----------------------------------+
```

#### Passo 4: Saia do MySQL

```sql
exit;
```

#### Passo 5: Siga os passos 1-7 do Método 1 para editar wp-config.php

---

### Método 3: Reinstalar WordPress (Última opção)

Se nada funcionar, pode ser necessário reinstalar:

```bash
# Backup do banco (importante!)
docker compose exec db mysqldump -u wpuser -p${WORDPRESS_DB_PASSWORD} wordpress > backup-wordpress.sql

# Remove o volume do WordPress
docker compose down
docker volume rm labirintar-infra_wp_data

# Sobe novamente
docker compose up -d

# Acesse e reinstale
# https://labirintar.com.br/blog/wp-admin/install.php
```

---

## 🧪 Testando

Após aplicar a correção:

1. **Limpe cookies do navegador** para `labirintar.com.br`
2. Acesse: `https://labirintar.com.br/blog`
3. Acesse: `https://labirintar.com.br/blog/wp-admin`
4. Faça login

Deve funcionar sem redirecionamentos infinitos! ✅

---

## 🔍 Verificando Configuração

### Ver configuração atual do WordPress

```bash
docker compose exec wordpress cat /var/www/html/wp-config.php | head -20
```

### Ver logs do WordPress

```bash
docker compose logs wordpress --tail=50 -f
```

### Ver logs do Caddy

```bash
docker compose logs caddy --tail=50 -f
```

### Testar acesso direto ao container

```bash
# Dentro do servidor
curl -I http://localhost:80/
```

---

## 📋 Checklist de Verificação

- [ ] wp-config.php tem `WP_HOME` e `WP_SITEURL` definidos
- [ ] wp-config.php tem código para detectar HTTPS
- [ ] Banco de dados tem URLs corretas em `wp_options`
- [ ] Cookies do navegador foram limpos
- [ ] Caddy está rodando: `docker ps | grep caddy`
- [ ] WordPress está rodando: `docker ps | grep wordpress`
- [ ] Não há erros nos logs: `docker compose logs`

---

## ⚠️ Notas Importantes

1. **Sempre faça backup** antes de editar wp-config.php ou banco de dados
2. **Limpe o cache do navegador** após qualquer mudança
3. **Use modo anônimo** para testar (evita cache)
4. Se usar plugins de cache no WordPress, **limpe o cache** deles também

---

## 🆘 Ainda não funciona?

Se após todos os métodos ainda não funcionar:

1. Verifique se o Caddyfile está correto:
```bash
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
```

2. Recarregue a configuração do Caddy:
```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

3. Reinicie tudo:
```bash
docker compose restart
```

4. Verifique os logs em tempo real:
```bash
docker compose logs -f
```
