# Bouncer

[![CI](https://github.com/freelogicbr/bouncer/actions/workflows/lint.yml/badge.svg)](https://github.com/freelogicbr/bouncer/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/freelogicbr/bouncer/blob/main/LICENSE)
[![Python 3.12+](https://img.shields.io/badge/Python-3.12+-blue.svg)](https://www.python.org/)

[Read in English](./README.md)

---

> **Status**: Prova de Conceito / Pre-Alpha. Apenas infraestrutura. A funcionalidade central ainda nao foi implementada.

Ferramenta local-first de busca e navegacao de codigo para agentes MCP. Concebida para reduzir o uso de tokens em LLMs apontando agentes para a referencia correta antes de varrer arquivos inteiros.

### Requisitos

- Python 3.12+
- Git
- PostgreSQL com pgvector habilitado
- Um workspace Git local com codigo Python

### Instalacao

```bash
python3 -m pip install -e .[dev]
```

### Configuracao

O Bouncer usa um arquivo de configuracao TOML em `~/.config/bouncer/config.toml` para mapear aliases de workspace para caminhos raiz. Esse caminho pode ser sobrescrito via variavel de ambiente.

### Execucao

```bash
bouncer
```

### Desenvolvimento

```bash
make lint      # executar linter ruff
make format    # formatar com ruff
make test      # executar testes
```

---

## Agradecimentos

Este projeto contou com a colaboracao do Gemini, Claude e GPT no auxilio a estruturacao de algoritmos e revisao de codigo.
