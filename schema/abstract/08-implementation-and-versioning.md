# Implementation, Extension, and Versioning

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
