# Changelog

[Read in English](./CHANGELOG.md)

---

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
e este projeto segue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Bootstrap inicial do projeto com suporte a Python 3.12 e PostgreSQL/pgvector.
- GitHub Actions workflow de CI para linting e smoke tests.
- Pre-commit hooks via Ruff para garantir qualidade de código.
- `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` e `LICENSE` (MIT).
- PRD bilingue (EN/PT-BR) definindo escopo do MVP e ferramentas MCP.
- Documento de arquitetura bilingue (EN/PT-BR) consolidando todas as decisoes de design.

### Changed

- Removido Docker como caminho principal de execucao; MVP roda nativamente no sistema operacional.
- READMEs atualizados para execucao nativa, instalacao editavel, config TOML e requisito de Git.
- PRD atualizado: parsing via AST sem fallback textual, refresh via `post-commit`, `dirty` como estado derivado do arquivo, `remove_file` adicionado as tools.
- Target `install` do Makefile agora usa instalacao editavel (`pip install -e`).
