# Predictive Maintenance Scenario: Bearing Overheat Decision Chain

## Goal

Show an end-to-end TELOS scenario that demonstrates the Core Philosophy:

- **Write-only by design** (new assertions, no edits/deletes)
- **Agent-centric** (multiple agents, including disagreement)
- **Purpose-driven** (asset suitability is judged against a declared purpose)
- **Flexible but structured** (base keys + namespaced extensions)

## Context

A pump train has a bearing assembly fulfilling the purpose `high_speed_rotation`. A sensor detects high temperature. A predictive system assesses health, planners provide recommendations (including disagreement), a technician acts, and follow-up observations confirm recovery.

## Main Entities

- **Thing**: `bearing_assembly_a`, `temp_sensor_23`, `bearing_component_new`
- **Purpose**: `high_speed_rotation`
- **Agents**:
  - `agent:sensor_system`
  - `agent:predictive_service`
  - `agent:maintenance_planner`
  - `agent:operations_supervisor`
  - `agent:technician`

## Timeline (Append-Only)

1. Baseline observation: normal temperature
2. Over-temperature observation
3. Health assessment references both observations as evidence
4. Planner recommendation: replace bearing quickly
5. Operations recommendation: monitor first (disagrees with #4)
6. Technician action implements replacement recommendation
7. Observation records `effective_stop_time` for old ThingPurposeConnection
8. New ThingPurposeConnection starts for replacement component
9. Post-replacement observation: temperature normalized
10. Follow-up health assessment: suitability restored

## Core Philosophy Coverage Notes

### 1) Write-only by design

- No prior event is updated.
- New events and connections are added to represent changed understanding/state.
- Relationship semantics (evidence, contradiction) are explicit in connection records.

### 2) Agent-centric

- Distinct agents produce observations, assessments, recommendations, and actions.
- Recommendations can conflict and both remain valid historical facts.

### 3) Purpose-driven

- The bearing is evaluated relative to `high_speed_rotation`, not in isolation.
- Health and recommendation objects are tied to the Thing+Purpose pair.

### 4) Flexible but structured

- Shared semantics use `base:*` keys.
- Domain details use namespaced keys (e.g., `predictive:*`, `maintenance:*`, `ops:*`, `sensor:*`).

## Files in This Scenario

- `data.json`: concrete entities, events, and connections in one append-only timeline
- `queries.md`: example query patterns for current-state, evidence tracing, disagreement, and replacement history
