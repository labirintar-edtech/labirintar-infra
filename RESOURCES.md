# Alocação de Recursos - VPS 2 CPU / 8GB RAM

## 📊 Distribuição de Recursos

### Recursos Totais da VPS
- **CPU**: 2 núcleos
- **RAM**: 8 GB
- **Disco**: 100 GB

### Alocação por Serviço

#### 🌐 Caddy (Reverse Proxy)
- **CPU Limite**: 0.5 core (25% do total)
- **CPU Reserva**: 0.25 core
- **RAM Limite**: 512 MB (6% do total)
- **RAM Reserva**: 256 MB
- **Justificativa**: Caddy é leve e eficiente, não precisa de muitos recursos

#### 🌍 WordPress (Aplicação)
- **CPU Limite**: 1.0 core (50% do total)
- **CPU Reserva**: 0.5 core
- **RAM Limite**: 3 GB (37.5% do total)
- **RAM Reserva**: 1 GB
- **Justificativa**: WordPress + PHP + Apache precisam de recursos consideráveis para processar requisições

#### 🗄️ MySQL (Banco de Dados)
- **CPU Limite**: 1.0 core (50% do total)
- **CPU Reserva**: 0.5 core
- **RAM Limite**: 3 GB (37.5% do total)
- **RAM Reserva**: 1 GB
- **Justificativa**: MySQL precisa de RAM para cache e CPU para queries

#### 💾 Sistema Operacional
- **RAM Reservada**: ~1.5 GB
- **Justificativa**: Sistema operacional, Docker daemon, buffers, cache

### Total Alocado
- **CPU Total**: 2.5 cores (permite burst, mas limita cada serviço)
- **RAM Total**: 6.5 GB (deixa 1.5GB para o SO)

## 🏥 Healthchecks Implementados

### Caddy
- **Teste**: Verifica endpoint `/health`
- **Intervalo**: 30s
- **Timeout**: 10s
- **Retries**: 3
- **Start Period**: 40s

### WordPress
- **Teste**: Verifica página de instalação do WP
- **Intervalo**: 30s
- **Timeout**: 10s
- **Retries**: 3
- **Start Period**: 60s (mais tempo para inicializar)

### MySQL
- **Teste**: Ping no MySQL com mysqladmin
- **Intervalo**: 30s
- **Timeout**: 10s
- **Retries**: 3
- **Start Period**: 60s (mais tempo para inicializar)

## 🔒 Segurança de Rede

### Rede `web` (Pública)
- **Serviços**: Caddy, WordPress
- **Acesso**: Internet → Caddy → WordPress
- **Portas Expostas**: 80, 443

### Rede `db_network` (Privada/Interna)
- **Serviços**: WordPress, MySQL
- **Acesso**: Apenas WordPress pode acessar MySQL
- **Portas Expostas**: Nenhuma (rede interna)
- **Flag**: `internal: true` - MySQL não tem acesso à internet

### Benefícios
✅ MySQL isolado da internet
✅ Apenas WordPress pode conectar ao banco
✅ Caddy não tem acesso direto ao banco
✅ Reduz superfície de ataque

## 🚀 Comandos Úteis

### Verificar saúde dos containers
```bash
docker ps
docker inspect --format='{{.State.Health.Status}}' caddy
docker inspect --format='{{.State.Health.Status}}' wordpress
docker inspect --format='{{.State.Health.Status}}' mysql
```

### Verificar uso de recursos
```bash
docker stats
```

### Ver logs de healthcheck
```bash
docker inspect --format='{{json .State.Health}}' caddy | jq
```

## ⚠️ Observações

1. **Limites são soft**: Docker permite burst temporário acima dos limites se houver recursos disponíveis
2. **Reservas são garantidas**: Cada serviço tem garantia mínima de recursos
3. **OOM Killer**: Se um container exceder muito a memória, pode ser morto pelo sistema
4. **Monitoramento**: Use `docker stats` para monitorar uso real

## 📈 Ajustes Futuros

Se o site crescer, considere:
- Aumentar RAM do WordPress (mais cache)
- Adicionar Redis para cache de objetos
- Aumentar RAM do MySQL (melhor performance de queries)
- Separar banco em servidor dedicado

