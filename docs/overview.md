# Low-Level Data Ontology for Systems, Assets, and Decisions

## Overview

This project defines a write-only, agent-centric ontology for modeling physical and computational systems, their purposes, observations, and decision-making processes. The ontology is designed to capture reality as it unfolds—including uncertainty, conflicting observations, and evolving understanding—without erasing historical context.

## Core Philosophy

### Write-Only by Design
- All data is append-only; corrections are made by adding new observations rather than editing existing records
- Historical context is preserved completely, enabling full audit trails and analysis of how understanding evolved
- "Ship of Theseus" scenarios (component replacement, evolving definitions) are handled naturally

### Agent-Centric
- Every assertion (observation, purpose, connection) is made by an identifiable Agent
- Multiple Agents can have different perspectives on the same entities
- No forced consensus—conflicting observations coexist with their provenance intact

### Purpose-Driven
- Things exist to fulfill Purposes
- Purposes compose and decompose based on need
- The "why" is as important as the "what"

### Flexible but Structured
- Base ontology provides constrained vocabulary for interoperability
- Agents can extend via namespaced parameters for domain-specific needs
- Balance between standardization (for ETL/integration) and flexibility (for domain requirements)

## Core Entities

### Thing
The base entity representing physical objects, data structures, or any entity that can be observed or fulfill a purpose.

**Key characteristics:**
- Composable and decomposable (mediated through Purpose systems)
- Can fulfill multiple Purposes at different times
- All properties attached via ObservationEvents, not directly

### Agent
Entities that create observations, purposes, and connections. Can represent humans, organizations, systems, or algorithms.

**Key characteristics:**
- Identified by UUID
- Claims ownership of all assertions they make
- Can have different perspectives and namespaces

### Purpose
Goals, functions, or reasons that Things fulfill. The teleological foundation of the ontology.

**Key characteristics:**
- Composable (parent-child relationships)
- Templatable (manufacturer templates, operator instances)
- Specialized subtypes: Algorithm (computational purposes), Port (data flow purposes)

### Event
Temporal assertions about the world, made by Agents.

**Key characteristics:**
- Start and stop times with uncertainty representation
- Recorded time (when the Event was logged) separate from when it occurred
- Predictions: recorded_time < start_time
- Retrospective records: recorded_time > stop_time

**Event Types:**
- **ObservationEvent**: Properties, measurements, or assertions about Things/Purposes/Events
- **Action**: Activities performed, can implement Recommendations or create new Purposes/Connections
- **HealthAssessment**: Evaluation of Thing suitability for a Purpose
- **Recommendation**: Suggested actions for a Thing-Purpose pair
- **Contingency**: Alternatives with logical constraints (exactly-one, at-least-one, etc.)
- **ResultSet**: Groups outputs from Algorithm execution

## Connections

Connections are event-like entities (temporal, agent-asserted) but maintained in separate tables for query efficiency.

### ThingPurposeConnection
Links Things to the Purposes they fulfill.

**Key features:**
- Temporal validity (start/stop times)
- effective_stop_time computed from ObservationEvents (for query performance)
- Multiple Things can fulfill same Purpose; single Thing can fulfill multiple Purposes

### PurposePurposeConnection
Relationships between Purposes.

**Connection types:**
- **decomposition**: Parent purpose breaks into sub-purposes
- **derivation**: Purpose derived from template (e.g., operator from manufacturer)
- **succession**: One purpose replaces another
- **equivalence**: Different purposes are functionally equivalent
- **other**: Agent-defined in namespace

### EventEventConnection
Relationships between Events.

**Connection types:**
- **causal**: One event caused another
- **enables**: One event made another possible
- **contradicts**: Events are mutually exclusive
- **supersedes**: Newer event replaces older
- **correlation**: Events co-occurred
- **evidence_for**: One event supports another (can also use simple evidence array in parameters)
- **other**: Agent-defined in namespace

## Specialized Concepts

### Algorithms and Computational Flow
Algorithms are Purposes that represent computational processes.

**Components:**
- **Port**: Specialized Purpose representing input/output data points
- **PortSet**: Collections of Ports forming input or output signatures
- **in_port_set**: Defines inputs required by Algorithm
- **out_port_set**: Defines outputs produced by Algorithm

**Execution model:**
- Action executes Algorithm with input Things connected to input Ports
- ResultSet groups output Things produced
- All traceable: which data, which Algorithm version, which outputs

### Decision Chains
The ontology captures complete decision-making workflows:
```
ObservationEvent (sensor reading)
  ↓ evidence
HealthAssessment (Thing unsuitable for Purpose)
  ↓ evidence
Recommendation (replace component)
  ↓ implements
Action (technician replaces component)
  ↓ generates
ObservationEvent (new component installed)
  ↓ evidence
HealthAssessment (Thing now suitable)
```

### Contingency (Uncertainty Management)
Represents decision spaces with logical constraints on alternatives.

**Use cases:**
- Diagnostic uncertainty: "fault is A, B, or C—exactly one"
- Resource constraints: "can repair unit 1, 2, or 3—exactly one (limited staff)"
- Sequential decisions: "try calibration; if fails, replace sensor"

**Resolution:**
- Action can resolve Contingency by selecting alternative(s)
- Unresolved Contingencies remain in history (legitimate uncertainty)

### Engineering Units
Standardized representation of measurements with automatic conversion.

**Structure:**
- Base unit reference (SI or agent-defined)
- Multiplication factor and offset for conversion
- Namespaced for different unit systems

## Key Patterns

### Evidence Chains
Simple case: `"base:evidence": [event_uuid1, event_uuid2]` in Event parameters

Complex case: EventEventConnection with connection_type = "evidence_for" when relationship semantics matter

### Corrections and Retractions
Never delete or edit. Instead:
```
ObservationEvent (original, incorrect):
  parameters: {"temperature": 100}

ObservationEvent (correction):
  thing_observed: <original_observation_uuid>
  parameters: {
    "base:confidence": 0.0,
    "base:reason": "sensor_calibration_error",
    "base:corrected_value": 75
  }
```

### Connection Lifecycle
```
1. Create ThingPurposeConnection with stop_time = null
2. When replaced, ObservationEvent asserts effective_stop_time
3. Application updates effective_stop_time field (cached)
4. New ThingPurposeConnection created for replacement
5. Old connection remains in history
```

### Namespace Convention
`agent_uuid:namespace:parameter_name`

**Examples:**
- `base:confidence` (core ontology)
- `uuid_123:iso14224:equipment_class` (ISO standard)
- `uuid_456:predictive:remaining_useful_life_hours` (custom analytics)

## Use Cases

### Asset Management
- Track component installation, replacement, maintenance
- Manufacturer templates → operator instances
- Multiple organizations' perspectives on same assets

### Predictive Maintenance
- Algorithms process sensor observations
- Health assessments based on predictions
- Recommendations with confidence levels
- Decision chains from detection to action

### Digital Twins
- Purpose hierarchies represent system design
- Things map to physical components
- Observations capture real-time state
- Algorithms model behavior

### Regulatory Compliance
- Complete audit trail (write-only)
- Multi-agent perspectives (operator, inspector, regulator)
- Evidence chains for decisions
- Temporal provenance

### Cross-Organization Integration
- Low-level ontology as translation layer
- Higher-level domain ontologies map down
- Namespaces preserve domain semantics
- Lossless round-tripping

## Design Trade-offs

### Purity vs Pragmatism

**Where we chose purity:**
- Write-only enforcement (no edits/deletes)
- Agent namespaces (maximum flexibility)
- Parameters in jsonb (no predefined schema)

**Where we chose pragmatism:**
- Connections as separate tables (not in Event table)
- effective_stop_time caching (query performance)
- Constrained enums with "other" option (standard vocabulary + extensibility)
- Evidence as simple arrays (complex relationships use EventEventConnection)

### Query Complexity
Finding "current state" requires:
1. Temporal filtering (start/stop times)
2. Effective end time computation (ObservationEvents)
3. Conflict resolution (multiple Agents)
4. Evidence chain traversal

**Mitigation strategies:**
- Materialized views for common queries
- Cached effective_stop_time
- Domain-specific indexes
- Query time window limiting

## Implementation Considerations

### Database Options
- **Neo4j**: Native graph, good for traversals, temporal support
- **XTDB**: Immutable-first, bi-temporal, Datalog queries
- **PostgreSQL**: With careful indexing (GIN on jsonb), recursive CTEs for graphs
- **RDF/Triple Stores**: Semantic web native, SPARQL queries

### Indexing Strategy
- Temporal fields (start_time, stop_time, effective_stop_time, recorded_time)
- Foreign keys (agent, thing, purpose, event references)
- GIN indexes on jsonb parameters for frequent query patterns
- Composite indexes for common join patterns

### Application Layer Responsibilities
- Namespace validation and conventions
- effective_stop_time computation from ObservationEvents
- Conflict resolution logic for multiple Agents
- Evidence chain traversal
- Unit conversion

## Inspirations

- **OSA-EAI**: Segment/asset model, template-instance pattern
- **OSA-CBM**: Computational flow representation
- **Ship of Theseus**: Part replacement and identity over time
- **Epistemic humility**: Multiple perspectives, uncertainty, evolving understanding

## Future Extensions

Potential areas for expansion (deferred to higher-level ontologies):
- Agent capabilities and permissions
- Spatial/location modeling
- Complex state machines
- Real-time streaming patterns
- Federated query across organizations

## Repository Structure

The following is the intended project layout for TELOS documentation, schemas, examples, tools, mappings, and research artifacts:

```text
telos/
├── README.md                          # Project overview, quick start
├── LICENSE
├── CONTRIBUTING.md
├── .gitignore
│
├── docs/
│   ├── overview.md                    # The project overview we just created
│   ├── ontology-specification.md     # Formal ontology definition
│   ├── design-rationale.md           # Why we made key decisions
│   ├── use-cases.md                  # Concrete examples and scenarios
│   ├── migration-guide.md            # For adopting TELOS
│   └── api/                          # If you build API specs
│       └── reference.md
│
├── schema/
│   ├── abstract/
│   │   ├── README.md                 # Canonical modular abstract schema entrypoint
│   │   ├── specification.md          # Compatibility shim
│   │   └── specification.full.md     # Single-file snapshot of the full abstract schema
│   ├── neo4j/
│   │   ├── schema.cypher             # Neo4j-specific implementation
│   │   ├── indexes.cypher            # Index definitions
│   │   └── constraints.cypher        # Constraint definitions
│   ├── postgresql/
│   │   ├── schema.sql                # PostgreSQL implementation
│   │   ├── indexes.sql
│   │   └── migrations/               # Schema evolution
│   │       ├── 001_initial.sql
│   │       └── 002_add_feature.sql
│   ├── xtdb/
│   │   └── schema.edn                # XTDB/Datalog schema
│   └── rdf/
│       └── telos.ttl                 # RDF/OWL representation
│
├── examples/
│   ├── asset-management/
│   │   ├── scenario.md               # Narrative description
│   │   ├── data.json                 # Sample data
│   │   └── queries.md                # Common queries for this scenario
│   ├── predictive-maintenance/
│   ├── digital-twin/
│   └── regulatory-compliance/
│
├── reference-implementation/         # If you build one
│   ├── python/
│   │   ├── telos/
│   │   │   ├── __init__.py
│   │   │   ├── models.py             # Entity classes
│   │   │   ├── connections.py
│   │   │   ├── queries.py
│   │   │   └── validation.py
│   │   ├── tests/
│   │   ├── setup.py
│   │   └── requirements.txt
│   └── javascript/                   # Alternative implementation
│
├── tools/
│   ├── validators/                   # Schema validation tools
│   ├── converters/                   # Between database formats
│   └── visualization/                # Graph visualization, etc.
│
├── mappings/                         # Higher-level ontology mappings
│   ├── iso14224/
│   │   ├── mapping.md
│   │   └── examples.json
│   ├── opc-ua/
│   ├── mimosa/
│   └── custom-domain/
│
└── research/
    ├── related-work.md               # Comparison to other ontologies
    ├── bibliography.md
    └── future-directions.md
```

## Getting Started

[To be added: Links to schema files, example implementations, migration guides]

## Contributing

[To be added: Contribution guidelines, discussion forums]

## License

MIT

---

**Version:** 1.0  
**Last Updated:** [Current Date]  
**Maintainers:** [To be added]