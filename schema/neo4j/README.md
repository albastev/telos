# TELOS Neo4j Concrete Schema

This directory provides a concrete Neo4j implementation of the TELOS abstract schema.

## Files

- `schema.cypher` - Data model mapping (labels, relationship semantics, and canonical write patterns)
- `constraints.cypher` - Uniqueness and existence constraints
- `indexes.cypher` - Performance indexes aligned with TELOS query patterns
- `Dockerfile` - Schema test runner image (Neo4j 5.26.21 Enterprise)
- `docker-compose.yml` - Local/CI orchestration for Neo4j + schema test runner
- `run-schema-test.sh` - Waits for Neo4j readiness and applies schema files in required order

## Apply Order

Run files in this order on an empty (or compatible) Neo4j database:

1. `constraints.cypher`
2. `indexes.cypher`

`schema.cypher` documents canonical graph patterns for ingestion and querying.

## Docker-Based Schema Validation

This package includes a Dockerized validation flow that verifies:

1. Neo4j system database starts successfully
2. The target test database is created (if needed) and becomes available
3. `constraints.cypher` applies cleanly
4. `indexes.cypher` applies cleanly

The test runner exits non-zero on any failure, making it suitable for local checks and CI pipelines.

### Neo4j Edition / License Note

The current schema uses property existence constraints in [`constraints.cypher`](./constraints.cypher), which require **Neo4j Enterprise**.
The compose file is therefore pinned to `neo4j:5.26.21-enterprise` and sets `NEO4J_ACCEPT_LICENSE_AGREEMENT=yes` for local/CI validation.

Use this setup only in a way that complies with Neo4j's licensing terms for your environment.

By default, the runner targets database `neo4j` and will create it if it does not exist.

### Local Run (from `schema/neo4j`)

```bash
docker compose up --build --abort-on-container-exit --exit-code-from schema-test
```

Expected behavior:

- **Pass**: `schema-test` logs `SUCCESS: constraints and indexes applied cleanly.` and exits `0`
- **Fail**: `schema-test` exits non-zero if Neo4j readiness fails or either Cypher file errors

### Cleanup

```bash
docker compose down -v
```

### CI-Friendly Invocation (from repository root)

```bash
docker compose -f schema/neo4j/docker-compose.yml up --build --abort-on-container-exit --exit-code-from schema-test
```

```bash
docker compose -f schema/neo4j/docker-compose.yml down -v
```

## Future Extension

This initial validation intentionally focuses on clean schema application (`constraints` + `indexes`).
Scenario-based tests (e.g., applying representative TELOS write/query workflows) can be added later as a separate test stage that runs after this baseline schema validation.

## Design Notes

- TELOS write-only semantics are enforced at the application layer (append-only inserts).
- Connections are modeled as **nodes** (not relationship properties) so they can be observed as first-class entities.
- Foreign-key style UUID properties are preserved for interoperability, while graph relationships support traversal.
