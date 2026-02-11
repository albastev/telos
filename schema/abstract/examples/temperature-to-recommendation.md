# Complete Example: Temperature to Recommendation

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
