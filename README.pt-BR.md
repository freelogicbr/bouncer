# Bouncer

[![CI](https://github.com/freelogicbr/bouncer/actions/workflows/lint.yml/badge.svg)](https://github.com/freelogicbr/bouncer/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/freelogicbr/bouncer/blob/main/LICENSE)
[![Python 3.12+](https://img.shields.io/badge/Python-3.12+-blue.svg)](https://www.python.org/)

[Read in English](./README.md)

---

> **Status**: Prova de Conceito / Pré-Alpha. Apenas infraestrutura. A funcionalidade central ainda não foi implementada.

Filtro de contexto local-first para busca de código. Concebido para reduzir o uso de tokens em LLMs sem perder relevância.

Será construído com Python, PostgreSQL e pgvector para manter o custo de API sob controle enquanto permite análise profunda do código.

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

## Agradecimentos

Este projeto contou com a colaboração do Gemini, Claude e GPT no auxílio à estruturação de algoritmos e revisão de código.
