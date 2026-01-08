# 🚀 Guia de Deploy - Sites Estáticos

## 📋 Passo a Passo Completo

### 1️⃣ Preparar o Build do seu projeto React

```bash
# No diretório do seu projeto React
cd /caminho/do/seu-projeto-react

# Instalar dependências (se necessário)
npm install

# Criar build de produção
npm run build
# ou com Vite:
npm run build

# Isso cria uma pasta 'build' ou 'dist' com os arquivos otimizados
```

### 2️⃣ Fazer Deploy usando o script

```bash
# No diretório labirintar-infra
cd /caminho/para/labirintar-infra

# Deploy do site
./deploy-site.sh nome-do-site /caminho/do/projeto/build

# Exemplo real:
./deploy-site.sh app ~/projetos/meu-app-react/build
```

### 3️⃣ Configurar domínio no Caddyfile

Edite `conf/Caddyfile` e adicione:

```caddy
app.labirintar.com.br {
    root * /var/www/sites/app
    encode gzip zstd
    
    log {
        output file /var/log/caddy/app-access.log
        format json
    }
    
    # Para SPAs (React Router, Vue Router, etc)
    try_files {path} /index.html
    
    file_server
    
    # Cache de assets
    @static {
        path *.css *.js *.ico *.gif *.jpg *.jpeg *.png *.svg *.woff *.woff2 *.ttf *.eot *.webp
    }
    header @static Cache-Control "public, max-age=31536000, immutable"
    
    # Headers de segurança
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }
}
```

### 4️⃣ Reiniciar Caddy

```bash
docker compose restart caddy

# Ou se for a primeira vez:
docker compose up -d
```

### 5️⃣ Configurar DNS

No seu provedor de domínio (Registro.br, Cloudflare, etc):

```
Tipo: A
Nome: app.labirintar.com.br
Valor: IP_DA_SUA_VPS
TTL: 3600
```

### 6️⃣ Aguardar e Testar

- Aguarde propagação DNS (pode levar até 24h, geralmente 5-30 minutos)
- Acesse: `https://app.labirintar.com.br`
- O Caddy vai automaticamente obter certificado SSL!

---

## 🔄 Atualizando um Site Existente

```bash
# 1. Faça novo build do projeto
cd /caminho/do/projeto
npm run build

# 2. Deploy (sobrescreve o anterior, faz backup automático)
cd /caminho/para/labirintar-infra
./deploy-site.sh app /caminho/do/projeto/build

# 3. Pronto! Não precisa reiniciar nada
```

---

## 🎯 Exemplos de Configuração

### React com React Router

```caddy
app.labirintar.com.br {
    root * /var/www/sites/app
    encode gzip zstd
    file_server
    try_files {path} /index.html  # ← Importante para rotas funcionarem
}
```

### Site com API Backend

```caddy
painel.labirintar.com.br {
    root * /var/www/sites/painel
    encode gzip zstd
    
    # Proxy requisições /api para backend
    handle /api/* {
        reverse_proxy backend:3000
    }
    
    # Serve arquivos estáticos
    file_server
    try_files {path} /index.html
}
```

### Site com variáveis de ambiente

Se seu React precisa de variáveis de ambiente em build time:

```bash
# Crie arquivo .env.production no projeto React
REACT_APP_API_URL=https://api.labirintar.com.br
REACT_APP_ENV=production

# Build com as variáveis
npm run build

# Deploy normal
./deploy-site.sh app ./build
```

### Múltiplos sites

```caddy
# Site 1
app.labirintar.com.br {
    root * /var/www/sites/app
    encode gzip zstd
    file_server
    try_files {path} /index.html
}

# Site 2
landing.labirintar.com.br {
    root * /var/www/sites/landing
    encode gzip zstd
    file_server
}

# Site 3
painel.labirintar.com.br {
    root * /var/www/sites/painel
    encode gzip zstd
    file_server
    try_files {path} /index.html
}
```

---

## 🛠️ Comandos Úteis

```bash
# Ver sites deployados
ls -lh sites/

# Ver tamanho dos sites
du -sh sites/*

# Ver backups
ls -lh sites/.backups/

# Restaurar backup
cp -r sites/.backups/app-20260108-143000/* sites/app/

# Ver logs do Caddy
docker compose logs caddy -f

# Verificar configuração do Caddy
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Recarregar configuração sem downtime
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## 📊 Estrutura Final

```
labirintar-infra/
├── docker-compose.yml
├── .env
├── conf/
│   └── Caddyfile
├── sites/
│   ├── README.md
│   ├── app/              # Site React 1
│   │   ├── index.html
│   │   ├── assets/
│   │   └── ...
│   ├── landing/          # Site React 2
│   │   ├── index.html
│   │   └── ...
│   └── .backups/         # Backups automáticos
│       ├── app-20260108-143000/
│       └── landing-20260108-150000/
├── deploy-site.sh        # Script de deploy
└── DEPLOY-GUIDE.md       # Este arquivo
```

---

## ❓ Troubleshooting

### Site não carrega (404)

1. Verifique se os arquivos estão em `sites/nome-do-site/`
2. Verifique se existe `index.html` na pasta
3. Verifique configuração no Caddyfile
4. Reinicie Caddy: `docker compose restart caddy`

### Rotas do React não funcionam (404)

Adicione `try_files {path} /index.html` no Caddyfile

### CSS/JS não carrega

Verifique se o `homepage` no `package.json` está correto:

```json
{
  "homepage": "/"
}
```

### Certificado SSL não é gerado

1. Verifique se DNS está apontando corretamente
2. Verifique se portas 80 e 443 estão abertas
3. Veja logs: `docker compose logs caddy`

---

## 🎉 Pronto!

Agora você pode hospedar quantos sites React quiser na mesma VPS! 🚀
