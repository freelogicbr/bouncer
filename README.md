# Bouncer

[![CI](https://github.com/freelogicbr/bouncer/actions/workflows/lint.yml/badge.svg)](https://github.com/freelogicbr/bouncer/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/freelogicbr/bouncer/blob/main/LICENSE)
[![Python 3.12+](https://img.shields.io/badge/Python-3.12+-blue.svg)](https://www.python.org/)

[Leia em Português](./README.pt-BR.md)

---

> **Status**: Proof of Concept / Pre-Alpha. Infrastructure only. Core functionality is not yet implemented.

Local-first context filter for code search. Designed to reduce LLM token usage without losing relevance.

Will be built with Python, PostgreSQL, and pgvector to keep API costs under control while enabling deep code analysis.

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

---

## Acknowledgments

This project benefited from the collaboration of Gemini, Claude, and GPT in assisting with algorithm structuring and code review.
