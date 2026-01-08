# Sites Estáticos

Esta pasta contém os builds de sites estáticos (React, Vue, Angular, etc) que serão servidos pelo Caddy.

## 📁 Estrutura

Cada subpasta representa um site diferente:

```
sites/
├── site1/          # exemplo: app.labirintar.com.br
│   ├── index.html
│   ├── assets/
│   └── ...
├── site2/          # exemplo: painel.labirintar.com.br
│   ├── index.html
│   └── ...
```

## 🚀 Como adicionar um novo site React

### 1. Build do seu projeto React

```bash
cd /caminho/do/seu/projeto-react
npm run build
# ou
yarn build
```

### 2. Copie o build para esta pasta

```bash
# Crie uma pasta com o nome do site
mkdir -p sites/meu-site

# Copie o conteúdo da pasta build/dist
cp -r build/* sites/meu-site/
# ou se usar Vite:
cp -r dist/* sites/meu-site/
```

### 3. Configure no Caddyfile

Adicione no `conf/Caddyfile`:

```caddy
meu-dominio.com.br {
    root * /var/www/sites/meu-site
    encode gzip zstd
    file_server
    
    # SPA: redireciona todas as rotas para index.html
    try_files {path} /index.html
    
    # Cache de assets
    @static {
        path *.css *.js *.ico *.gif *.jpg *.jpeg *.png *.svg *.woff *.woff2 *.ttf *.eot *.webp
    }
    header @static Cache-Control "public, max-age=31536000, immutable"
}
```

### 4. Atualize o docker-compose.yml

Adicione o volume no serviço Caddy:

```yaml
caddy:
  volumes:
    - ./conf:/etc/caddy
    - caddy_data:/data
    - caddy_config:/config
    - ./sites:/var/www/sites  # <-- Adicione esta linha
```

### 5. Reinicie o Caddy

```bash
docker compose restart caddy
```

## 🔄 Atualizando um site

```bash
# 1. Faça o build do projeto atualizado
cd /caminho/do/projeto
npm run build

# 2. Substitua os arquivos
rm -rf sites/meu-site/*
cp -r build/* sites/meu-site/

# 3. Não precisa reiniciar! Caddy serve automaticamente os novos arquivos
```

## 📝 Exemplos de configuração

### Site React/Vue/Angular (SPA)
```caddy
app.labirintar.com.br {
    root * /var/www/sites/app
    encode gzip zstd
    file_server
    try_files {path} /index.html
}
```

### Site estático simples (sem SPA)
```caddy
landing.labirintar.com.br {
    root * /var/www/sites/landing
    encode gzip zstd
    file_server
}
```

### Site com API proxy
```caddy
painel.labirintar.com.br {
    root * /var/www/sites/painel
    encode gzip zstd
    
    # Proxy para API
    handle /api/* {
        reverse_proxy backend:3000
    }
    
    # Serve arquivos estáticos
    file_server
    try_files {path} /index.html
}
```
