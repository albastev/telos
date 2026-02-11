# Events

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
