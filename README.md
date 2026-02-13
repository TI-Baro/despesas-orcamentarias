# Controle Orcamentario TI

Sistema de controle orcamentario e acompanhamento de investimentos para a area de TI.

## Stack

- Frontend: HTML/CSS/JS (arquivo unico, sem build)
- Backend: [Supabase](https://supabase.com) (autenticacao + banco de dados)
- Deploy: Docker com nginx:alpine

## Pre-requisitos

- [Docker](https://docs.docker.com/get-docker/) e Docker Compose instalados
- Projeto criado no [Supabase](https://supabase.com/dashboard)

## Passo a passo para deploy

### 1. Configurar o Supabase

1. Acesse https://supabase.com/dashboard e crie um novo projeto
2. Anote o **Project URL** e a **anon public key** (Settings > API)
3. Abra o **SQL Editor** no painel do Supabase e execute todo o conteudo do arquivo `schema.sql` para criar as tabelas e politicas de seguranca
4. Em **Authentication > URL Configuration**, defina o **Site URL** para a URL onde a aplicacao ficara hospedada (ex: `http://seu-servidor:8080`)

### 2. Configurar credenciais

Edite o arquivo `config.js` com as credenciais do seu projeto Supabase:

```js
const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_ANON_KEY = 'sua-anon-key-aqui';
```

### 3. Configurar emails autorizados

No mesmo `config.js`, defina quais emails podem criar conta:

```js
const ALLOWED_EMAILS = [
  'usuario@empresa.com',
  'outro@empresa.com',
];
```

Somente emails nesta lista conseguirao se registrar. Deixe a lista vazia (`[]`) para permitir qualquer email.

### 4. Build e deploy com Docker

```bash
# Clonar o repositorio
git clone <url-do-repositorio>
cd controle-orcamentario

# Subir o container
docker compose up -d --build
```

A aplicacao estara disponivel em `http://localhost:8080`.

Para alterar a porta, edite o `docker-compose.yml`:

```yaml
ports:
  - "3000:80"   # mude 8080 para a porta desejada
```

### 5. Comandos uteis

```bash
# Ver logs
docker compose logs -f

# Parar
docker compose down

# Rebuild apos alteracoes
docker compose up -d --build

# Verificar se esta rodando
docker compose ps
```

## Atualizando a aplicacao em producao

Apos fazer alteracoes e enviar para o repositorio (`git push`), acesse a VPS e execute:

```bash
cd /caminho/do/projeto
git pull
docker compose up -d --build
```

- `git pull` sincroniza o codigo da VPS com o repositorio remoto
- `docker compose up -d --build` reconstroi a imagem e reinicia o container com os arquivos atualizados

### Quando o `config.js` e alterado

O `config.js` e copiado para dentro da imagem Docker durante o build. Por isso, ao alterar credenciais, emails permitidos ou qualquer configuracao nesse arquivo, o procedimento e o mesmo: `git pull` + rebuild.

> **Importante:** apenas editar o `config.js` direto no servidor nao surte efeito, pois o nginx serve a copia que esta dentro da imagem Docker. Sempre execute o rebuild.

### Resumo rapido

| O que mudou | Comando na VPS |
|---|---|
| `index.html` | `git pull && docker compose up -d --build` |
| `config.js` | `git pull && docker compose up -d --build` |
| `docker-compose.yml` | `git pull && docker compose up -d` |
| `nginx.conf` | `git pull && docker compose up -d --build` |

## Estrutura de arquivos

```
├── index.html          # Aplicacao completa (HTML + CSS + JS)
├── config.js           # Credenciais Supabase e emails permitidos
├── schema.sql          # SQL para criar tabelas no Supabase
├── Dockerfile          # Imagem Docker (nginx:alpine)
├── nginx.conf          # Configuracao do nginx
├── docker-compose.yml  # Orquestracao do container
├── .dockerignore       # Arquivos excluidos do build
├── .env                # Referencia de credenciais (nao commitado)
└── .gitignore          # Arquivos ignorados pelo git
```

## Seguranca

- **RLS (Row Level Security)**: cada usuario so acessa seus proprios dados no Supabase
- **Lista de emails**: restringe quem pode criar conta na aplicacao
- **Headers HTTP**: nginx configurado com X-Frame-Options, X-Content-Type-Options e Referrer-Policy
- O `config.js` contem a **anon key** do Supabase, que e uma chave publica (segura para expor no frontend). A protecao dos dados e feita pelo RLS no servidor
