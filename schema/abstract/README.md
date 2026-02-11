# TELOS Abstract Schema Specification

This directory contains the modularized abstract schema specification for TELOS.

## Canonical Entry Points

- Modular index: `schema/abstract/README.md`
- Compatibility shim: `schema/abstract/specification.md`
- Full monolith snapshot: `schema/abstract/specification.full.md`

## Table of Contents

1. [Core Entities](./01-core-entities.md)
2. [Events](./02-events.md)
3. [Connections](./03-connections.md)
4. [Algorithm Support Structures](./04-algorithm-structures.md)
5. [Contingency Support Structures](./05-contingency-structures.md)
6. [Engineering Units and Namespaces](./06-engineering-units-and-namespaces.md)
7. [Query Patterns and Validation](./07-query-patterns-and-validation.md)
8. [Implementation, Extension, and Versioning](./08-implementation-and-versioning.md)
9. [Complete Example](./examples/temperature-to-recommendation.md)

## Preamble

# TELOS Abstract Schema Specification

**Version:** 1.0  
**Status:** Draft  
**Last Updated:** 2024-02-10

## Overview

This document defines the database-agnostic schema for TELOS (Temporal Event Ledger of Observations and Systems). The schema is intentionally abstract to support multiple database implementations (relational, graph, document, RDF) while maintaining semantic consistency.

## Notation Conventions

- **Primary Key**: Denoted with `(primary key)` 
- **Foreign Key**: Denoted with `(foreign key -> TargetEntity)`
- **Nullable**: Denoted with `(nullable)` - fields without this are required
- **Enum**: Fixed set of allowed values shown in brackets `["value1", "value2"]`
- **jsonb**: JSON-structured data with flexible schema
- **UUID**: Universally unique identifier
- **timestamp**: ISO 8601 datetime with timezone

## Design Principles

1. **Write-Only**: No updates or deletes; corrections via new observations
2. **Agent-Centric**: All assertions attributed to identifiable Agents
3. **Temporal**: All entities and relationships have time bounds with uncertainty
4. **Namespaced Flexibility**: Core ontology provides structure; agents extend via namespaces
5. **Evidence-Based**: Claims link to supporting observations

---
