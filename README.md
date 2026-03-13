# Bouncer

[![CI](https://github.com/freelogicbr/bouncer/actions/workflows/lint.yml/badge.svg)](https://github.com/freelogicbr/bouncer/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/freelogicbr/bouncer/blob/main/LICENSE)
[![Python 3.12+](https://img.shields.io/badge/Python-3.12+-blue.svg)](https://www.python.org/)

[Leia em Portugues](./README.pt-BR.md)

---

> **Status**: Proof of Concept / Pre-Alpha. Infrastructure only. Core functionality is not yet implemented.

Local-first code search and navigation tool for MCP agents. Designed to reduce LLM token usage by pointing agents to the right reference before they scan entire files.

### Requirements

- Python 3.12+
- Git
- PostgreSQL with pgvector enabled
- A local Git workspace with Python code

### Setup

```bash
python3 -m pip install -e .[dev]
```

### Configuration

Bouncer uses a TOML configuration file at `~/.config/bouncer/config.toml` to map workspace aliases to root paths. This path can be overridden via environment variable.

### Run

```bash
bouncer
```

### Development

```bash
make lint      # run ruff linter
make format    # auto-format with ruff
make test      # run tests
```

---

## Acknowledgments

This project benefited from the collaboration of Gemini, Claude, and GPT in assisting with algorithm structuring and code review.
