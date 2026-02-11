# Engineering Units and Namespaces

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
