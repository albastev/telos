# Query Patterns and Validation

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
