# Bouncer

[![CI](https://github.com/freelogicbr/bouncer/actions/workflows/lint.yml/badge.svg)](https://github.com/freelogicbr/bouncer/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/freelogicbr/bouncer/blob/main/LICENSE)
[![Python 3.12+](https://img.shields.io/badge/Python-3.12+-blue.svg)](https://www.python.org/)

> **Status**: Proof of Concept / Pre-Alpha. Infrastructure only. Core functionality is not yet implemented.

## PT-BR / Português

Filtro de contexto local-first para busca de código. Concebido para reduzir o uso de tokens em LLMs sem perder relevância.

Será construído com Python, PostgreSQL e pgvector para manter o custo de API sob controle enquanto permite análise profunda do código.

**Nota**: Este repositório contém apenas a infraestrutura base e configuração. A funcionalidade central ainda está sendo desenvolvida.

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

Local-first context filter for code search. Designed to reduce LLM token usage without losing relevance.

Will be built with Python, PostgreSQL, and pgvector to keep API costs under control while enabling deep code analysis.

**Note**: This repository contains only base infrastructure and configuration. Core functionality is still being developed.

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
