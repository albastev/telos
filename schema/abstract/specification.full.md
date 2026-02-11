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

## Events

All temporal assertions about the world, made by Agents.

### Event (Base)

```
Event:
  uuid: UUID (primary key)
  event_type: enum ["observation", "action", "health_assessment", 
                    "recommendation", "contingency", "result_set"]
  agent: UUID (foreign key -> Agent)
  start_time: timestamp
  start_time_uncertainty: jsonb (nullable, agent-defined representation)
  stop_time: timestamp (nullable)
  stop_time_uncertainty: jsonb (nullable)
  recorded_time: timestamp (when Event was created/logged)
  parameters: jsonb (namespace:key -> value pairs)
  
  // Polymorphic fields (populated based on event_type):
  
  // For event_type = "observation":
  thing_observed: UUID (nullable, polymorphic FK -> Thing | Purpose | Event | Connection)
  
  // For event_type = "health_assessment":
  assessment_thing: UUID (nullable, foreign key -> Thing)
  assessment_purpose: UUID (nullable, foreign key -> Purpose)
  
  // For event_type = "recommendation":
  recommendation_thing: UUID (nullable, foreign key -> Thing)
  recommendation_purpose: UUID (nullable, foreign key -> Purpose)
  
  // For event_type = "contingency":
  logic_type: string (nullable, agent-defined: "exactly_one", "at_least_one", etc.)
  
  // For event_type = "result_set":
  result_set_algorithm: UUID (nullable, foreign key -> Algorithm)
  result_set_action: UUID (nullable, foreign key -> Event where event_type = "action")
```

**Temporal Semantics:**
- `recorded_time < start_time`: Prediction/planned event
- `recorded_time ≈ start_time`: Real-time observation
- `recorded_time > stop_time`: Retrospective record

**Common Event.parameters Patterns:**
- Evidence: `"base:evidence": [uuid1, uuid2, ...]`
- Confidence: `"base:confidence": 0.85`
- Engineering units: `"base:unit": "celsius"`, `"base:value": 23.5`
- Namespace extension: `"agent_uuid:domain:parameter": value`

---

### Event Type: ObservationEvent

Records properties, measurements, or assertions about Things, Purposes, Events, or Connections.

**Specific fields:**
- `thing_observed`: Entity being observed

**Common parameter patterns:**
```json
{
  "base:property_name": "temperature",
  "base:value": 75.3,
  "base:unit": "celsius",
  "base:confidence": 0.95,
  "agent_uuid:sensor:id": "temp_sensor_23",
  "agent_uuid:calibration:date": "2024-01-15"
}
```

**Use cases:**
- Sensor readings on Things
- Assertions about connection validity (effective_stop_time)
- Corrections to previous observations (confidence = 0.0)
- Meta-observations (observations about observations)

---

### Event Type: Action

Activities performed by Agents, can implement Recommendations or create Purposes/Connections.

**Common parameter patterns:**
```json
{
  "base:action_type": "replace_component",
  "base:implements_recommendation": "recommendation_uuid",
  "base:rejects_recommendation": "other_recommendation_uuid",
  "base:justification": "mission_critical_timeline",
  "maintenance:downtime_hours": 4.5,
  "maintenance:parts_used": ["part_123", "part_456"]
}
```

**Use cases:**
- Maintenance activities
- Component replacement
- Configuration changes
- Algorithm execution
- Decision implementation/rejection

---

### Event Type: HealthAssessment

Evaluation of a Thing's suitability for a Purpose.

**Specific fields:**
- `assessment_thing`: Thing being assessed
- `assessment_purpose`: Purpose being evaluated against

**Common parameter patterns:**
```json
{
  "base:suitability_score": 0.75,
  "base:limiting_factor": "bearing_wear",
  "base:evidence": ["observation_uuid1", "observation_uuid2"],
  "predictive:remaining_useful_life_hours": 2400,
  "predictive:failure_probability_30day": 0.15,
  "inspector:visual_condition": "moderate_wear",
  "inspector:certification": "Level_II_VT"
}
```

**Notes:**
- No ThingPurposeConnection required (can assess potential suitability)
- Multiple Agents can provide different assessments of same Thing-Purpose pair
- Suitability representation is agent-defined (scores, categories, narratives)

---

### Event Type: Recommendation

Suggested action for a Thing-Purpose pair.

**Specific fields:**
- `recommendation_thing`: Thing the recommendation concerns
- `recommendation_purpose`: Purpose context

**Common parameter patterns:**
```json
{
  "base:action": "replace",
  "base:priority": "high",
  "base:target_date": "2024-04-30",
  "base:evidence": ["health_assessment_uuid"],
  "maintenance:estimated_downtime_hours": 4,
  "maintenance:parts_required": ["bearing_assembly_xyz"],
  "cost:estimated_total": 15000
}
```

**Notes:**
- Can recommend actions without current ThingPurposeConnection (e.g., "install this")
- Multiple Agents can make conflicting Recommendations
- Actions can implement, reject, or ignore Recommendations

---

### Event Type: Contingency

Represents alternatives with logical constraints on selection.

**Specific fields:**
- `logic_type`: Constraint on alternatives (agent-defined)

**Common logic_type values:**
- `"exactly_one"`: Mutually exclusive alternatives, must choose one
- `"at_least_one"`: Can choose multiple, must choose at least one
- `"at_most_one"`: Optional choice, can choose zero or one
- `"sequential_elimination"`: Try in order until one succeeds
- Custom: Agents can define domain-specific logic

**Usage:**
- See ContingencyAlternative table for listing alternatives
- See ContingencyResolution table for recording resolution

**Use cases:**
- Diagnostic uncertainty (one of three fault modes)
- Resource constraints (limited staff/budget)
- Decision trees (conditional paths)
- Risk mitigation strategies

---

### Event Type: ResultSet

Groups output Things produced by Algorithm execution.

**Specific fields:**
- `result_set_algorithm`: Algorithm that produced outputs
- `result_set_action`: Action that executed the algorithm

**Common parameter patterns:**
```json
{
  "base:execution_duration_seconds": 145.3,
  "base:output_things": ["thing_uuid1", "thing_uuid2"],
  "compute:cpu_time_seconds": 120.5,
  "compute:memory_peak_mb": 2048
}
```

**Notes:**
- Links execution context (Action, Algorithm) to outputs
- Enables tracing: which data went in, which code ran, which results came out
- Multiple ResultSets can exist for same Algorithm (different executions)

---

## Connections

Connections are event-like entities (temporal, agent-asserted) maintained in separate tables for query efficiency. While philosophically they are Events, they are not stored in the Event table.

### Connection Base Pattern

All connection types share this structure:

```
Connection (abstract pattern, not a table):
  uuid: UUID (primary key)
  agent: UUID (foreign key -> Agent)
  start_time: timestamp
  start_time_uncertainty: jsonb (nullable)
  stop_time: timestamp (nullable, original assertion)
  stop_time_uncertainty: jsonb (nullable)
  effective_stop_time: timestamp (nullable, computed from ObservationEvents)
  recorded_time: timestamp
  parameters: jsonb
```

**About effective_stop_time:**
- Cached value computed from ObservationEvents asserting end time
- Improves query performance (avoid complex observation traversal)
- ObservationEvents remain source of truth for audit trail
- Can differ from stop_time (planned vs actual)

---

### ThingPurposeConnection

Links Things to the Purposes they fulfill.

```
ThingPurposeConnection:
  uuid: UUID (primary key)
  agent: UUID (foreign key -> Agent)
  thing: UUID (foreign key -> Thing)
  purpose: UUID (foreign key -> Purpose)
  start_time: timestamp
  start_time_uncertainty: jsonb (nullable)
  stop_time: timestamp (nullable)
  stop_time_uncertainty: jsonb (nullable)
  effective_stop_time: timestamp (nullable)
  recorded_time: timestamp
  parameters: jsonb
```

**Lifecycle pattern:**
```
1. Create with stop_time = null (ongoing)
2. When replaced: ObservationEvent asserts effective_stop_time
3. Application updates effective_stop_time field (cached)
4. Create new ThingPurposeConnection for replacement
5. Old connection remains in history (write-only)
```

**Notes:**
- Multiple Things can fulfill same Purpose (redundancy, alternatives)
- Single Thing can fulfill multiple Purposes (multi-function components)
- Temporal overlaps are valid (transition periods)

---

### PurposePurposeConnection

Relationships between Purposes.

```
PurposePurposeConnection:
  uuid: UUID (primary key)
  agent: UUID (foreign key -> Agent)
  source_purpose: UUID (foreign key -> Purpose)
  target_purpose: UUID (foreign key -> Purpose)
  connection_type: enum ["decomposition", "derivation", "succession", 
                         "equivalence", "other"]
  start_time: timestamp
  start_time_uncertainty: jsonb (nullable)
  stop_time: timestamp (nullable)
  stop_time_uncertainty: jsonb (nullable)
  effective_stop_time: timestamp (nullable)
  recorded_time: timestamp
  parameters: jsonb
```

**Connection Types:**

- **decomposition**: Source Purpose breaks into Target sub-purpose
  - Example: "Navigate" decomposes into "Determine Position"
  
- **derivation**: Target derived from Source template
  - Example: Operator's "Coolant System" derived from Manufacturer's template
  
- **succession**: Target replaces Source
  - Example: "New Backup Strategy" succeeds "Old Backup Strategy"
  
- **equivalence**: Source and Target serve same function
  - Example: "Manual Process" equivalent to "Automated Process"
  
- **other**: Agent-defined relationship in parameters
  - Example: `"agent_uuid:custom:relationship_type": "temporal_overlap"`

**Notes:**
- Build hierarchies via decomposition chains
- Track provenance via derivation chains
- Handle evolution via succession chains
- Same Purpose can have multiple connection types to different Purposes

---

### EventEventConnection

Relationships between Events.

```
EventEventConnection:
  uuid: UUID (primary key)
  agent: UUID (foreign key -> Agent)
  source_event: UUID (foreign key -> Event)
  target_event: UUID (foreign key -> Event)
  connection_type: enum ["causal", "enables", "contradicts", 
                         "supersedes", "correlation", "evidence_for", "other"]
  start_time: timestamp
  start_time_uncertainty: jsonb (nullable)
  stop_time: timestamp (nullable)
  stop_time_uncertainty: jsonb (nullable)
  effective_stop_time: timestamp (nullable)
  recorded_time: timestamp
  parameters: jsonb
```

**Connection Types:**

- **causal**: Source Event caused Target Event
  - Example: "Maintenance Action" caused "System Downtime"
  
- **enables**: Source Event made Target Event possible
  - Example: "Parts Arrived" enabled "Repair Action"
  
- **contradicts**: Source and Target Events are mutually exclusive
  - Example: Conflicting observations from different sensors
  
- **supersedes**: Target Event replaces/corrects Source Event
  - Example: Updated observation replaces erroneous reading
  
- **correlation**: Source and Target Events co-occurred
  - Example: "Temperature Spike" correlated with "Pressure Drop"
  
- **evidence_for**: Source Event supports Target Event claim
  - Example: Sensor readings support Health Assessment
  - Note: Can also use simple evidence array in Event.parameters
  
- **other**: Agent-defined relationship in parameters

**Notes:**
- Evidence can use simple array in parameters OR this connection type
- Use EventEventConnection when relationship semantics matter
- Enables chain-of-causality analysis
- Multiple agents can assert different relationships for same event pair

---

## Algorithm Support Structures

### PortSet

Collections of Ports forming input or output signatures for Algorithms.

```
PortSet:
  uuid: UUID (primary key)
  algorithm: UUID (foreign key -> Algorithm)
  direction: enum ["input", "output"]
  created_at: timestamp
  created_by_agent: UUID (foreign key -> Agent)
```

**Notes:**
- Each Algorithm can have multiple input PortSets (overloading)
- Each Algorithm should have single output PortSet per signature
- Empty PortSets are valid (no-input or no-output algorithms)

---

### PortSetMembership

Defines which Ports belong to which PortSets.

```
PortSetMembership:
  uuid: UUID (primary key)
  port_set: UUID (foreign key -> PortSet)
  port: UUID (foreign key -> Port)
  ordinal: integer (nullable, for ordered parameters)
  required: boolean (default true)
  created_at: timestamp
```

**Notes:**
- `ordinal` defines parameter order when relevant (e.g., positional args)
- `required = false` indicates optional parameters
- Same Port can appear in multiple input PortSets (reusable interfaces)
- Ports in output PortSets should be unique to one Algorithm (ownership)

**Example - Function Signature:**
```
Algorithm: calculate_bearing_health
  Input PortSet 1:
    - Port: temperature (ordinal: 1, required: true)
    - Port: vibration (ordinal: 2, required: true)
    - Port: speed (ordinal: 3, required: false)
  Output PortSet:
    - Port: health_score
    - Port: confidence
```

---

## Contingency Support Structures

### ContingencyAlternative

Lists alternative Events within a Contingency.

```
ContingencyAlternative:
  uuid: UUID (primary key)
  contingency: UUID (foreign key -> Event where event_type = "contingency")
  alternative_event: UUID (foreign key -> Event)
  ordinal: integer (nullable, for preserving order)
  created_at: timestamp
```

**Notes:**
- `ordinal` matters for logic_type = "sequential_elimination"
- Alternative Events are typically Recommendations or HealthAssessments
- Same Event can be alternative in multiple Contingencies

**Example:**
```
Contingency: diagnostic_uncertainty
  logic_type: "exactly_one"
  Alternatives:
    - HealthAssessment: bearing_failure (ordinal: 1)
    - HealthAssessment: misalignment (ordinal: 2)
    - HealthAssessment: sensor_error (ordinal: 3)
```

---

### ContingencyResolution

Records how a Contingency was resolved.

```
ContingencyResolution:
  uuid: UUID (primary key)
  contingency: UUID (foreign key -> Event where event_type = "contingency")
  resolving_action: UUID (foreign key -> Event where event_type = "action")
  selected_alternative: UUID (foreign key -> Event, must be in ContingencyAlternative)
  resolution_time: timestamp
```

**Notes:**
- Resolution is optional (Contingencies can remain unresolved)
- `selected_alternative` must exist in ContingencyAlternative for this Contingency
- `resolving_action` is the Action that made the selection
- For logic_type = "at_least_one", create multiple resolutions

**Example:**
```
Action: performed_vibration_analysis
  implements_recommendation: rec_run_diagnostics

ContingencyResolution:
  contingency: diagnostic_uncertainty
  resolving_action: performed_vibration_analysis
  selected_alternative: bearing_failure
  resolution_time: 2024-03-15T14:30:00Z
```

---

## Engineering Units

Standardized representation of measurements with automatic conversion capability.

```
EngineeringUnit:
  uuid: UUID (primary key)
  name: string
  base_unit: UUID (nullable, foreign key -> EngineeringUnit)
  multiplication_factor: float (default 1.0)
  offset: float (default 0.0)
  created_at: timestamp
  created_by_agent: UUID (foreign key -> Agent)
  namespace: string (agent_uuid:namespace pattern)
  parameters: jsonb (for additional unit metadata)
```

**Conversion formula:**
```
target_value = (source_value * multiplication_factor) + offset
```

**Notes:**
- `base_unit = null` for SI base units or agent-defined base units
- Chain conversions by traversing base_unit references
- Multiple unit systems can coexist via namespaces

**Examples:**

**SI Base Unit:**
```
EngineeringUnit:
  name: "meter"
  base_unit: null
  multiplication_factor: 1.0
  offset: 0.0
  namespace: "base:si"
```

**Derived Unit:**
```
EngineeringUnit:
  name: "kilometer"
  base_unit: <meter_uuid>
  multiplication_factor: 1000.0
  offset: 0.0
  namespace: "base:si"
```

**Temperature with offset:**
```
EngineeringUnit:
  name: "fahrenheit"
  base_unit: <celsius_uuid>
  multiplication_factor: 1.8
  offset: 32.0
  namespace: "base:imperial"
```

**Compound units:**
- Store as composite in parameters:
```json
{
  "base:numerator_units": ["kilogram", "meter"],
  "base:denominator_units": ["second", "second"],
  "base:compound_name": "newton"
}
```

---

## Namespace Conventions

### Base Namespace

Reserved namespace for core ontology parameters: `base:`

**Common base parameters:**
- `base:evidence` - Array of Event UUIDs supporting a claim
- `base:confidence` - Numeric confidence level (typically 0.0-1.0)
- `base:effective_stop_time` - Asserted end time for Connections
- `base:reason` - Explanation for an assertion
- `base:unit` - Reference to EngineeringUnit
- `base:value` - Measured or computed value
- `base:superseded_by` - Reference to replacing Event
- `base:implements_recommendation` - Reference to Recommendation being implemented
- `base:rejects_recommendation` - Reference to Recommendation being rejected

### Agent Namespaces

Pattern: `agent_uuid:domain:parameter`

**Examples:**
- `uuid_123:iso14224:equipment_class` - ISO 14224 standard
- `uuid_456:predictive:remaining_useful_life_hours` - Predictive analytics
- `uuid_789:maintenance:downtime_hours` - Maintenance tracking
- `uuid_abc:opc_ua:node_id` - OPC UA mapping

**Guidelines:**
- Use lowercase with underscores for consistency
- Choose domain names that indicate standard/system (iso14224, opc_ua, custom_app)
- Parameters should be self-documenting
- Document namespace conventions in agent-specific schemas

---

## Common Query Patterns

### Find Active Thing-Purpose Connections

```
SELECT * FROM ThingPurposeConnection
WHERE start_time <= NOW()
  AND (effective_stop_time IS NULL OR effective_stop_time > NOW())
```

### Trace Evidence Chain

```
-- Find all events supporting a HealthAssessment
WITH RECURSIVE evidence_chain AS (
  SELECT uuid, parameters->'base:evidence' as evidence
  FROM Event
  WHERE uuid = :health_assessment_uuid
  
  UNION ALL
  
  SELECT e.uuid, e.parameters->'base:evidence'
  FROM Event e
  JOIN evidence_chain ec ON e.uuid = ANY(ec.evidence::uuid[])
)
SELECT * FROM evidence_chain;
```

### Find Purpose Hierarchy

```
-- Get all sub-purposes of a parent purpose
WITH RECURSIVE purpose_tree AS (
  SELECT target_purpose as uuid, 0 as depth
  FROM PurposePurposeConnection
  WHERE source_purpose = :parent_purpose_uuid
    AND connection_type = 'decomposition'
  
  UNION ALL
  
  SELECT ppc.target_purpose, pt.depth + 1
  FROM PurposePurposeConnection ppc
  JOIN purpose_tree pt ON ppc.source_purpose = pt.uuid
  WHERE ppc.connection_type = 'decomposition'
)
SELECT * FROM purpose_tree;
```

### Find Conflicting Observations

```
-- Find observations about same Thing with different values
SELECT 
  thing_observed,
  agent,
  parameters->'base:property_name' as property,
  parameters->'base:value' as value,
  recorded_time
FROM Event
WHERE event_type = 'observation'
  AND thing_observed = :thing_uuid
  AND parameters->'base:property_name' = :property_name
ORDER BY recorded_time DESC;
```

---

## Implementation Notes

### Write-Only Enforcement

**Application layer responsibilities:**
- Prevent UPDATE and DELETE operations on all tables
- Only allow INSERT operations
- Corrections via new ObservationEvents with confidence = 0.0
- Supersession via new Events referencing old ones

### Effective Stop Time Computation

**When ObservationEvent asserts effective_stop_time:**
```
1. Find ObservationEvents where:
   - thing_observed = <connection_uuid>
   - parameters contains 'base:effective_stop_time'
2. Select most recent/most trusted assertion
3. Update Connection.effective_stop_time (cached value)
```

**Trust/conflict resolution is application-specific:**
- Most recent observation
- Highest confidence score
- Most trusted agent
- Domain-specific rules

### Indexing Recommendations

**Critical indexes:**
- Event.agent, Event.event_type, Event.recorded_time
- Event.start_time, Event.stop_time
- ThingPurposeConnection.effective_stop_time
- All foreign key columns
- GIN/JSONB indexes on parameters for frequent query patterns

### Performance Considerations

**Materialized views for common queries:**
- "Current state" of Thing-Purpose connections
- Active Purposes by hierarchy level
- Recent observations by Thing
- Unresolved Contingencies

**Partition strategies:**
- Events by recorded_time (time-series)
- Connections by start_time
- Archive old data while maintaining immutability

---

## Validation Rules

### Entity Constraints

1. **Temporal consistency:**
   - `start_time <= stop_time` (when stop_time is not null)
   - `recorded_time` can be before, during, or after event window

2. **Agent attribution:**
   - All Events, Purposes, and Connections must have valid agent reference

3. **Event type polymorphism:**
   - Subtype-specific fields must be populated for corresponding event_type
   - Example: event_type = "observation" requires thing_observed

### Connection Constraints

1. **ThingPurposeConnection:**
   - thing must reference valid Thing
   - purpose must reference valid Purpose

2. **PurposePurposeConnection:**
   - source_purpose and target_purpose must be different
   - Avoid cycles (application-level check for decomposition chains)

3. **EventEventConnection:**
   - source_event and target_event must be valid Events
   - Can be same Event (self-referential observation)

### Algorithm Constraints

1. **PortSet:**
   - Algorithm must have purpose_type = "algorithm"
   - Each Algorithm should have at least one PortSet

2. **PortSetMembership:**
   - Port must have purpose_type = "port"
   - Same Port should not appear twice in same PortSet

### Contingency Constraints

1. **ContingencyAlternative:**
   - contingency must have event_type = "contingency"
   - alternative_event must be valid Event

2. **ContingencyResolution:**
   - selected_alternative must exist in ContingencyAlternative for that Contingency
   - resolving_action must have event_type = "action"

---

## Extension Points

### Custom Event Types

While the base ontology defines core event_type values, implementations can extend via:

**Option 1: Use parameters for subtyping**
```json
Event {
  event_type: "observation",
  parameters: {
    "agent_uuid:custom:observation_subtype": "thermal_imaging",
    "agent_uuid:custom:camera_id": "flir_23"
  }
}
```

**Option 2: Add to enum (requires schema migration)**
```
event_type: enum [..., "custom_diagnostic"]
```

### Custom Connection Types

When base connection_type values insufficient:

```
PurposePurposeConnection {
  connection_type: "other",
  parameters: {
    "agent_uuid:domain:connection_type": "temporal_overlap",
    "agent_uuid:domain:overlap_percentage": 0.65
  }
}
```

### Custom Uncertainty Representations

Agents define their own uncertainty formats:

```json
{
  "agent_uuid:simple:uncertainty": "±5min",
  "agent_uuid:distribution:type": "normal",
  "agent_uuid:distribution:std_dev": 300,
  "agent_uuid:bayesian:prior": "...",
  "agent_uuid:fuzzy:membership_function": "..."
}
```

---

## Migration and Versioning

### Schema Evolution

When base ontology evolves:

1. **Additive changes** (new fields, new enum values):
   - Add to schema with nullable/default values
   - Update documentation
   - Old data remains valid

2. **Breaking changes** (removing fields, changing semantics):
   - Create new schema version
   - Provide migration tools
   - Consider maintaining multiple versions

### Data Migration

For moving to TELOS from other systems:

1. **Preserve original timestamps:**
   - Set `recorded_time` to migration time
   - Store original timestamps in parameters
   - Add provenance: `"base:migrated_from": "legacy_system"`

2. **Maintain traceability:**
   - Create Agent for migration process
   - Link migrated entities to source system identifiers
   - Document transformation logic in parameters

---

## Appendix: Complete Example

**Scenario:** Temperature sensor reading leads to health assessment and replacement recommendation.

```yaml
# 1. Sensor observation
Event:
  uuid: obs_001
  event_type: observation
  agent: sensor_system_uuid
  thing_observed: temp_sensor_23_uuid
  start_time: 2024-03-15T10:30:00Z
  stop_time: 2024-03-15T10:30:01Z
  recorded_time: 2024-03-15T10:30:02Z
  parameters:
    base:property_name: temperature
    base:value: 95.3
    base:unit: celsius_uuid
    sensor:location: bearing_housing
    sensor:accuracy: ±0.5

# 2. Health assessment based on observation
Event:
  uuid: health_001
  event_type: health_assessment
  agent: predictive_system_uuid
  assessment_thing: bearing_assembly_uuid
  assessment_purpose: high_speed_rotation_uuid
  start_time: 2024-03-15T10:31:00Z
  recorded_time: 2024-03-15T10:31:05Z
  parameters:
    base:suitability_score: 0.45
    base:evidence: [obs_001]
    predictive:remaining_useful_life_hours: 240
    predictive:failure_probability_30day: 0.35

# 3. Recommendation based on assessment
Event:
  uuid: rec_001
  event_type: recommendation
  agent: maintenance_planner_uuid
  recommendation_thing: bearing_assembly_uuid
  recommendation_purpose: high_speed_rotation_uuid
  start_time: 2024-03-15T10:35:00Z
  recorded_time: 2024-03-15T10:35:00Z
  parameters:
    base:action: replace
    base:priority: high
    base:target_date: 2024-03-20
    base:evidence: [health_001]
    maintenance:estimated_downtime_hours: 4

# 4. Action implements recommendation
Event:
  uuid: action_001
  event_type: action
  agent: technician_uuid
  start_time: 2024-03-18T08:00:00Z
  stop_time: 2024-03-18T11:30:00Z
  recorded_time: 2024-03-18T11:45:00Z
  parameters:
    base:implements_recommendation: rec_001
    maintenance:action_type: replace_bearing
    maintenance:parts_used: [new_bearing_xyz]

# 5. Old connection gets effective end time
ObservationEvent:
  uuid: obs_002
  event_type: observation
  agent: technician_uuid
  thing_observed: connection_001_uuid
  recorded_time: 2024-03-18T11:45:00Z
  parameters:
    base:effective_stop_time: 2024-03-18T09:00:00Z
    base:reason: component_replacement

# Updated connection (cached):
ThingPurposeConnection:
  uuid: connection_001
  thing: old_bearing_uuid
  purpose: high_speed_rotation_uuid
  start_time: 2023-01-15T00:00:00Z
  stop_time: null
  effective_stop_time: 2024-03-18T09:00:00Z  # Cached from obs_002

# 6. New connection created
ThingPurposeConnection:
  uuid: connection_002
  agent: technician_uuid
  thing: new_bearing_xyz
  purpose: high_speed_rotation_uuid
  start_time: 2024-03-18T09:30:00Z
  stop_time: null
  effective_stop_time: null
  recorded_time: 2024-03-18T11:45:00Z

# 7. Verification observation
Event:
  uuid: obs_003
  event_type: observation
  agent: sensor_system_uuid
  thing_observed: temp_sensor_23_uuid
  start_time: 2024-03-18T14:00:00Z
  recorded_time: 2024-03-18T14:00:01Z
  parameters:
    base:property_name: temperature
    base:value: 72.1
    base:unit: celsius_uuid
```

---

**End of Abstract Schema Specification**