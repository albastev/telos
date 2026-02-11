# Contingency Support Structures

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
