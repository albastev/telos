# Algorithm Support Structures

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
