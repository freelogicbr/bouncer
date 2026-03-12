# PRD - Bouncer MVP

[Leia em Português](./prd.pt-BR.md)

## 1. Overview

Bouncer is a local-first code search and navigation tool for agents through MCP.

Its purpose is to reduce the amount of code an LLM needs to read before locating the correct point for analysis or modification. Instead of scanning entire files, the agent should be able to query Bouncer to find relevant references in the code and direct dependency relationships around those references.

Bouncer does not replace direct code reading. It acts as a context filter and a navigation shortcut.

## 2. Problem

When an agent needs to locate or change a behavior in a codebase, it tends to scan entire files and dependency relationships manually. This consumes context and tokens unnecessarily, especially in long files where the useful point represents only a small fraction of the content.

Bouncer should reduce this waste by pointing, at low cost, to where the agent should look first.

## 3. Product Goal

Allow MCP agents to query an intent in natural language or a direct identifier and receive as a response:

- the most likely indexed references
- the location of those references in the workspace
- direct call relationships to support incremental exploration

The business goal of the MVP is to reduce unnecessary context and token consumption during LLM-assisted engineering tasks.

## 4. Primary User

The primary user of the MVP is MCP development agents.

Secondary users, such as code review assistants or humans through a CLI, may exist in the future, but they do not drive the initial scope.

## 5. Scope Principles

- Bouncer is a local navigation index for agents.
- Bouncer does not explain the code and does not try to solve the task for the agent.
- Bouncer does not replace direct reading of files in the workspace.
- Bouncer should prioritize low operational cost and simplicity.
- Bouncer should not evolve in the MVP into a deep architectural indexer or a complete code understanding system.

## 6. MVP Scope

The MVP must operate on the current state of the local workspace.

The initial pilot will be implemented and validated in Bouncer's own repository, in Python.

In the MVP, the only language with explicitly planned support is Python. Support for other languages is deferred to later phases.

In the MVP, Bouncer must offer four main capabilities:

- semantic search by natural language intent
- exact search by identifiers, symbols, or file
- structural neighborhood lookup for an indexed reference
- file-level index refresh

### 6.1 Basic Technical Assumptions

The MVP will use PostgreSQL with pgvector as the external storage for vectors and indexed metadata.

Embeddings will be generated locally, without external APIs, by a model small enough to run on CPU in a typical development environment.

The initial implementation will adopt the `all-MiniLM-L6-v2` model, which may be revised after pilot validation.

## 7. MVP Use Cases

### 7.1 Initial location

An agent asks a question such as:

`where is this behavior validated?`

Bouncer returns the most likely references for initial reading.

### 7.2 Symbol navigation

An agent already knows the name of a function, method, or file and needs to quickly locate its current position in the workspace.

### 7.3 Incremental exploration

After reading a reference, the agent identifies the need to understand another related function or call. Instead of continuing to scan the file manually, it makes a new query to Bouncer.

### 7.4 Index synchronization

An external deterministic process identifies that a file has changed and triggers either an update or a staleness mark without depending on LLM interpretation.

## 8. Inputs and Outputs

### 8.1 Main input

The main system input in the MVP is a natural language query made by an MCP agent about where to find, understand, or change a behavior in the codebase.

### 8.2 Additional inputs

The system must also accept direct queries by:

- function name
- method name
- symbol
- file path

### 8.3 Minimum required output

For each query, Bouncer must return:

- relevant references from the index
- file path
- symbol, when available
- start and end line
- relevance or confidence score
- which references call the returned reference, when detectable
- which references are called by it, when detectable

Files marked as changed remain eligible for search, but must be returned with reduced confidence and an explicit warning about possible positional staleness.

## 9. Indexing Unit

In the MVP, the main indexable unit will be a function or method when that structure can be identified through lightweight heuristics.

When that is not reliable, the system may use simple textual segmentation as a fallback. Deep multi-language AST parsing is out of scope for the initial version.

## 10. Dependencies and Neighborhood

In the MVP, dependency means a direct call relationship between indexed references, especially functions and methods.

The system must report:

- which references call the queried reference
- which references are called by it

Dynamic, ambiguous, or undetectable cases under lightweight heuristics may be omitted or returned with lower confidence.

## 11. MVP MCP Tools

The MVP must expose a minimal set of tools:

- `search_code`: semantic search by intent
- `find_symbol`: exact location by name, symbol, or file
- `get_neighbors`: structural context and direct call relationships
- `refresh_index`: rebuild the index for a file
- `mark_file_dirty`: mark a file as potentially outdated

## 12. Index Updates

In the MVP, index updates will be file-oriented.

An external process, such as a script or local watcher, will be responsible for detecting changes, building the queue, and calling Bouncer one file at a time.

This update process must not depend on LLM interpretation.

### 12.1 `refresh_index`

When a file changes, its indexed references and associated embeddings may be rebuilt entirely to preserve positional consistency and metadata integrity.

The minimum response for each call must include:

- processed file
- status
- number of generated references
- number of generated embeddings
- number of extracted dependencies
- errors or warnings, when present

### 12.2 `mark_file_dirty`

Bouncer must accept marking a file as changed before reindexing.

While a file is marked as potentially outdated:

- its results remain available
- positional confidence must be reduced
- the agent must receive a warning that lines and offsets may not reflect the current file state

This mechanism exists to extend the time window between reindexing runs without fully invalidating the usefulness of the index.

Files marked as `dirty` represent a degraded state that is acceptable for a limited time, but not a desired persistent operating condition.

## 13. Storage

Bouncer must not act as a mirror of the codebase.

In the MVP, it will store only:

- vectors
- indexing metadata
- derived relationships needed for search and neighborhood lookup

The source content remains in the workspace and should be read directly when necessary.

## 14. Minimum Metadata

Each indexed reference must contain, at minimum:

- project or workspace identifier
- file path
- language
- symbol name, when available
- symbol type
- start line
- end line
- hash or fingerprint for change detection
- outgoing call references, when detectable
- incoming call references derived from the index, when detectable

## 15. Success Criteria

The main success criterion for the MVP is to reduce full file scans by agents by at least 40%.

Operationally, the target is that, for every 10 location or modification queries sent to Bouncer, at least 4 should allow the agent to locate the needed point without scanning the entire file.

For the pilot, this measurement must be made through test workflow instrumentation, correlating the use of Bouncer MCP tools with directly observable file reads in the same execution scenario.

Quantitative latency and reindexing targets will not be fixed in the initial PRD. They should be observed in the real pilot environment and converted into targets after baseline collection.

## 16. Main Hypothesis

Even with lightweight embeddings, simple heuristics, and indexing without storing source code, it is possible to materially reduce file scanning by agents in real development tasks.

## 17. Main Risk

The main product risk in the MVP is keeping the index synchronized with the workspace without losing the advantage of low cost and simplicity.

More specifically, Bouncer's effectiveness depends on triggering reindexing at the right time without requiring excessive reading by the agent and without generating unnecessary processing.

## 18. Out of Scope for the MVP

- internal LLM for interpretation, synthesis, or routing
- universal support for any language
- deep AST parsing for all languages
- complete code storage in the database
- ultra-fine incremental updates below file level
- analysis of Git history, branches, and diffs
- any attempt to replace direct code reading by the agent

## 19. Executive Summary

The Bouncer MVP is a local and minimal navigation index for MCP agents.

It must answer two fundamental questions at low cost:

- where is the most likely reference I need to read now
- which direct calls go in and out of that reference

If the product does this consistently, it will have validated its main value proposition.
