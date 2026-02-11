# Connections

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
