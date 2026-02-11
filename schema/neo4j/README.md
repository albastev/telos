# TELOS Neo4j Concrete Schema

This directory provides a concrete Neo4j implementation of the TELOS abstract schema.

## Files

- `schema.cypher` - Data model mapping (labels, relationship semantics, and canonical write patterns)
- `constraints.cypher` - Uniqueness and existence constraints
- `indexes.cypher` - Performance indexes aligned with TELOS query patterns

## Apply Order

Run files in this order on an empty (or compatible) Neo4j database:

1. `constraints.cypher`
2. `indexes.cypher`

`schema.cypher` documents canonical graph patterns for ingestion and querying.

## Design Notes

- TELOS write-only semantics are enforced at the application layer (append-only inserts).
- Connections are modeled as **nodes** (not relationship properties) so they can be observed as first-class entities.
- Foreign-key style UUID properties are preserved for interoperability, while graph relationships support traversal.
