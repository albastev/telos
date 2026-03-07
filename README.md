# TELOS

Temporal Event Ledger of Observations and Systems (TELOS) is a low-level, write-only ontology for modeling systems, assets, observations, and decisions over time.

TELOS is designed for environments where:

- historical truth must be preserved (no destructive edits)
- multiple agents may disagree
- decisions must be traceable back to evidence
- temporal context matters as much as current state

## Core Principles

- **Write-only by design**: corrections are represented as new events, not updates/deletes.
- **Agent-centric assertions**: every claim is attributable to an `Agent`.
- **Temporal-first modeling**: explicit occurrence and recording times support replay and audit.
- **Purpose-driven structure**: `Thing` entities are interpreted through the `Purpose` they fulfill.
- **Constrained + extensible**: core vocabulary for interoperability, namespaced fields for domain-specific needs.

## Project Structure

```text
telos/
├── docs/
│   └── overview.md                        # Full conceptual overview
├── schema/
│   ├── abstract/                          # Database-agnostic TELOS schema
│   │   ├── README.md                      # Canonical abstract schema entrypoint
│   │   ├── specification.md               # Compatibility shim
│   │   └── specification.full.md          # Single-file snapshot
│   └── neo4j/                             # Concrete Neo4j schema package
│       ├── README.md
│       ├── schema.cypher
│       ├── constraints.cypher
│       ├── indexes.cypher
│       └── docker-compose.yml
├── examples/
│   └── predictive-maintenance/            # End-to-end scenario, data, and queries
└── memory-bank/                           # Project continuity + planning context
```

## Start Here

1. Read the conceptual overview: [`docs/overview.md`](./docs/overview.md)
2. Read the abstract schema entrypoint: [`schema/abstract/README.md`](./schema/abstract/README.md)
3. Explore a complete scenario: [`examples/predictive-maintenance/scenario.md`](./examples/predictive-maintenance/scenario.md)
4. Review sample data and query patterns:
   - [`examples/predictive-maintenance/data.json`](./examples/predictive-maintenance/data.json)
   - [`examples/predictive-maintenance/queries.md`](./examples/predictive-maintenance/queries.md)

## Neo4j Concrete Schema (Optional)

If you want to validate a concrete implementation, TELOS currently includes a Neo4j schema package.

- Usage and apply order: [`schema/neo4j/README.md`](./schema/neo4j/README.md)
- Core files:
  - [`schema/neo4j/constraints.cypher`](./schema/neo4j/constraints.cypher)
  - [`schema/neo4j/indexes.cypher`](./schema/neo4j/indexes.cypher)
  - [`schema/neo4j/schema.cypher`](./schema/neo4j/schema.cypher)

To run the Docker-based schema validation from repository root:

```bash
docker compose -f schema/neo4j/docker-compose.yml up --build --abort-on-container-exit --exit-code-from schema-test
```

Then cleanup:

```bash
docker compose -f schema/neo4j/docker-compose.yml down -v
```

## Current Status

This repository is currently **documentation-first** with:

- a modular abstract schema specification
- a concrete Neo4j schema implementation package
- a predictive maintenance example scenario

Additional concrete implementations (e.g., PostgreSQL, XTDB, RDF) can be added over time.

## License

MIT — see [`LICENSE`](./LICENSE).
