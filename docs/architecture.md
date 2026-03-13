# Architecture - Bouncer MVP

[Leia em Portugues](./architecture.pt-BR.md)

This document describes the Bouncer MVP architecture. It consolidates the design decisions and serves as the implementation reference.

## 1. Overview

Bouncer is a Python MCP service that indexes functions and methods from a local workspace and provides semantic search, exact search, neighborhood navigation, and file-level index refresh.

The service is stateless in-process. All persistence is in PostgreSQL with pgvector.

Execution is native on the operating system. Docker is not part of the MVP's primary path.

## 2. Language Scope

- The MVP supports Python only.
- Language detection by file extension (`.py -> python`).
- Unsupported languages return `unsupported_language`.

## 3. Parsing

- Pluggable internal parser interface.
- Only `PythonParser` implemented in the MVP.
- The Python parser uses `ast` from the standard library.
- Indexed units: `function` and `method`.
- Out of scope: nested functions, classes as standalone units, properties, lambdas, textual segmentation.

## 4. File Reading

Bouncer reads workspace files directly. There is no intermediate client that sends content to the core.

## 5. Workspace and Configuration

- `workspace_id` is required in all tools.
- `workspace_id` is a stable alias defined in configuration, not the folder name.
- Mapping `workspace_id -> root_path` in a TOML file.
- Default path: `~/.config/bouncer/config.toml`.
- Override via environment variable.
- Each workspace in the MVP requires only `root_path`.
- Every workspace is assumed to be a Git workspace.

## 6. Paths

- `file_path` is always relative to the workspace's `root_path`.
- Absolute paths are rejected.
- Paths that escape the workspace (`..`) are rejected.
- Validation: `file_path` resolves within `root_path`.
- Git membership validation is not performed in the core.

## 7. Index Updates

### 7.1 refresh_index

- Refresh is always per file. No batch refresh operation.
- Receives `workspace_id` and `file_path`.
- Flow: read file, detect language, parse, extract references and calls, generate embeddings, replace file records.
- Assumes syntactically valid content.
- If parsing fails, returns an explicit error and does not update the index.

### 7.2 Automation via post-commit

Reindexing automation is outside the core. An external script, triggered by a `post-commit` hook:

1. Discovers affected files in the last commit.
2. Marks files as `dirty`.
3. Calls `refresh_index` file by file.
4. Calls `remove_file` for deleted files.
5. If `refresh_index` fails, the file remains `dirty`.

Retry logic, attempt limits, and alerting are the script's responsibility. MVP alerting can be logging and a non-zero exit code.

### 7.3 Dirty State

- Dirty state is per file, not per reference.
- `mark_file_dirty` is kept in the MVP.
- Dirty reduces confidence but does not remove the file from results.
- If the update fails, the file remains `dirty`.

### 7.4 Removal

- Explicit `remove_file` operation.
- Removes references, call relationships, and dirty state for the file.

## 8. Embedding Text

Embedding text is composed by Bouncer. Composition:

1. Optional short technical comment immediately before the definition.
2. Function/method definition line.
3. Function/method body.

Structured comments help but are not required. Recommendation: limit to 1-2 technical lines.

`qualified_name` and other metadata exist separately, not as part of the embedded text.

## 9. Search

### 9.1 search_code

Lightweight hybrid search combining:

- Vector similarity
- Symbol name match
- Partial file path match
- Penalty for dirty files

Searches the entire workspace by default. Optional filters:

- `path_prefix`
- `file_path`
- `symbol_kind`

### 9.2 find_symbol

- Exact/deterministic search.
- Requires explicit language in input.
- Accepts simple name, qualified name, or file path.
- Multiple results return a ranked list.

## 10. Search Results

Fields returned by `search_code` and `find_symbol`:

- `reference_id`
- `file_path`
- `symbol_name`
- `start_line`
- `end_line`
- `symbol_kind`
- `qualified_name` (when available)
- `score` or `confidence`
- `is_dirty`

### 10.1 Reference Identification

- `reference_id`: sequential integer from the database in the MVP.
- Human identification: `file_path + symbol_name + start_line`.
- `qualified_name` is optional metadata, not the identification center.

## 11. Call Relationships

- Graph modeled in a separate edge table.
- An edge means `A calls B`.
- Unresolved calls do not become phantom nodes.
- Only resolved relationships to known workspace references enter the index.

### 11.1 Call Resolution

During `refresh_index`:

1. Extract all references from the file.
2. Build a local map of the file itself.
3. Resolve local calls first.
4. Attempt to resolve external calls already known in the workspace.

Detection coverage for Python in the MVP:

- Direct calls to simple names: `foo()`
- Attribute calls: `obj.method()`
- Dynamic cases are out of scope for the MVP.

## 12. Neighborhood (get_neighbors)

- Operates by `reference_id`.
- Default depth: `1`. Maximum in the MVP: `2`.
- Ordering: same file first, higher confidence, stable tiebreak.
- Simple pagination to avoid large responses.

## 13. Response Limits

Small responses by default to preserve the context advantage. Low limits with pagination for controlled expansion.

Suggested defaults (to be validated during implementation):

- `search_code`: `top_k=10`
- `find_symbol`: `top_k=5`
- `get_neighbors`: `page_size=10`

## 14. Module Structure

Code must be modular from the start to support agent-driven development. Minimum logical separation:

- MCP interface (transport and routing)
- Search services
- Indexing services
- Embedding module
- Ranking module
- Per-language parsers
- Repository layer (data access)
- Models, schemas, and configuration

## 15. MVP MCP Tools

| Tool | Type | Description |
|---|---|---|
| `search_code` | Search | Hybrid semantic search by intent |
| `find_symbol` | Search | Exact location by name, symbol, or file path |
| `get_neighbors` | Navigation | Structural context and call relationships |
| `refresh_index` | Indexing | Rebuild the index for a file |
| `mark_file_dirty` | Indexing | Mark a file as potentially outdated |
| `remove_file` | Indexing | Remove a file and its data from the index |

## 16. Open Points for Implementation

- Final table and column names.
- Exact `top_k` values and pagination limits.
- Concrete source code directory structure.
- Exact JSON schema for each MCP tool.
- Final weight policy for hybrid ranking.
