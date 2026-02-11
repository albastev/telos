# Core Entities

## Core Entities

### Thing

Represents physical objects, data structures, or any observable entity.

```
Thing:
  uuid: UUID (primary key)
  created_at: timestamp
```

**Notes:**
- Things are composable/decomposable via Purpose systems
- Properties are never set directly on Things; use ObservationEvents
- Things can fulfill multiple Purposes over time

---

### Agent

Entities that create observations, purposes, and connections. Represents humans, organizations, systems, or algorithms.

```
Agent:
  uuid: UUID (primary key)
  created_at: timestamp
```

**Notes:**
- All Events, Purposes, and Connections must reference an Agent
- Agents own their namespaces: `agent_uuid:namespace:parameter`
- Multiple Agents can observe the same entities with different perspectives

---

### Purpose

Goals, functions, or reasons that Things fulfill. The teleological foundation of TELOS.

```
Purpose:
  uuid: UUID (primary key)
  purpose_type: enum ["base", "algorithm", "port"]
  created_at: timestamp
  created_by_agent: UUID (foreign key -> Agent)
```

**Purpose Types:**
- **base**: Standard purpose (default)
- **algorithm**: Computational purpose (see Algorithm extension)
- **port**: Data flow purpose (see Port extension)

**Notes:**
- Purposes compose via PurposePurposeConnection
- Purposes can be templated (manufacturer) and instantiated (operator)
- Things fulfill Purposes via ThingPurposeConnection

---

### Port

Specialized Purpose representing input/output data points for Algorithms.

```
Port (extends Purpose where purpose_type = "port"):
  // Inherits: uuid, purpose_type, created_at, created_by_agent
  data_type: string (nullable, agent-defined)
```

**Notes:**
- Direction (input/output) determined by PortSet membership context
- Ports can be reused across multiple input PortSets
- Each Port should belong to only one output PortSet (ownership/traceability)

---

### Algorithm

Specialized Purpose representing computational processes.

```
Algorithm (extends Purpose where purpose_type = "algorithm"):
  // Inherits: uuid, purpose_type, created_at, created_by_agent
  application_reference: string (external service/script identifier)
  version: string
```

**Notes:**
- `application_reference` can be URL, service name, script path, etc.
- Version tracking enables reproducibility
- Inputs/outputs defined via PortSets

---
