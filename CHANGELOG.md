# Changelog

[Leia em Português](./CHANGELOG.pt-BR.md)

---

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial project bootstrap with Python 3.12 and PostgreSQL/pgvector support.
- GitHub Actions CI workflow for linting and smoke tests.
- Pre-commit hooks via Ruff for code quality enforcement.
- `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `LICENSE` (MIT).
- Bilingual PRD (EN/PT-BR) defining MVP scope and MCP tools.
- Bilingual architecture document (EN/PT-BR) consolidating all design decisions.

### Changed

- Removed Docker as the primary execution path; MVP runs natively on the host OS.
- Updated READMEs to reflect native execution, editable install, TOML config, and Git requirement.
- Updated PRD: AST-based parsing without textual fallback, `post-commit` driven refresh, `dirty` as derived file state, `remove_file` added to tool set.
- Makefile `install` target now uses editable install (`pip install -e`).
