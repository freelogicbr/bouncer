# Bouncer

## PT-BR / Português

Bootstrap minimalista para uma ferramenta open-source de busca de código local-first com Python, MCP e uma instância externa de PostgreSQL com pgvector.

### Status

Este repositório contém a configuração inicial segura para publicação.

### Requisitos

- Docker e Docker Compose
- Instância PostgreSQL com pgvector habilitado

### Configuração Local

1. Copie `.env.example` para `.env`.
2. Substitua os placeholders pelos valores do seu ambiente.
3. Garanta que `DOCKER_EXTERNAL_NETWORK` corresponda à rede do PostgreSQL.

### Execução

```bash
docker compose up --build
```

---

## EN / English

Minimal bootstrap for an open-source, local-first code search tool built with Python, MCP, and an external PostgreSQL instance with pgvector.

### Status

This repository contains the initial safe public bootstrap.

### Requirements

- Docker and Docker Compose
- PostgreSQL instance with pgvector enabled

### Local Configuration

1. Copy `.env.example` to `.env`.
2. Replace placeholders with your local environment values.
3. Ensure `DOCKER_EXTERNAL_NETWORK` matches the PostgreSQL network.

### Run

```bash
docker compose up --build
```
