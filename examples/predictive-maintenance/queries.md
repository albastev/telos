# Predictive Maintenance Scenario Queries

This file provides practical query patterns for the scenario in `data.json`.

## 1) What is the current active component for `high_speed_rotation`?

**Intent:** derive current state from append-only connection history.

Pseudo-SQL:

```sql
SELECT tpc.uuid, tpc.thing, tpc.purpose, tpc.start_time, tpc.effective_stop_time
FROM thing_purpose_connection tpc
WHERE tpc.purpose = 'purpose:high_speed_rotation'
  AND tpc.start_time <= NOW()
  AND (tpc.effective_stop_time IS NULL OR tpc.effective_stop_time > NOW())
ORDER BY tpc.start_time DESC;
```

Expected result in this scenario:
- `tpc:new_bearing_fulfills_rotation` is active
- `tpc:old_bearing_fulfills_rotation` is historical (ended via `base:effective_stop_time`)

## 2) Show full evidence chain from final health outcome back to raw observation

**Intent:** audit why `event:health_002_restored` was asserted.

Pseudo traversal:

1. Start at `event:health_002_restored`
2. Follow `base:evidence` list and/or `event_event_connection` with `connection_type = evidence_for`
3. Continue until reaching raw observations/actions

Expected chain highlights:
- `event:health_002_restored`
  - evidence: `event:obs_004_post_replacement_temp`
  - evidence: `event:action_001_replace_bearing`
  - supporting connection: `eec:post_replacement_supports_restored_health`

## 3) Which recommendations disagreed, and who issued each one?

**Intent:** preserve multi-agent conflict without forced consensus.

Pseudo-SQL:

```sql
SELECT
  c.uuid AS connection_uuid,
  c.from_event,
  e1.agent AS from_agent,
  c.to_event,
  e2.agent AS to_agent,
  c.parameters
FROM event_event_connection c
JOIN event e1 ON e1.uuid = c.from_event
JOIN event e2 ON e2.uuid = c.to_event
WHERE c.connection_type = 'contradicts';
```

Expected result:
- `event:rec_001_replace_now` (maintenance planner) contradicts
- `event:rec_002_monitor_first` (operations supervisor)

## 4) What action was ultimately executed, and what recommendation did it implement?

**Intent:** link planning to execution.

Pseudo-SQL:

```sql
SELECT
  a.uuid AS action_uuid,
  a.agent,
  a.start_time,
  a.stop_time,
  a.parameters->>'base:implements_recommendation' AS implemented_recommendation
FROM event a
WHERE a.event_type = 'action';
```

Expected result:
- `event:action_001_replace_bearing` implements `event:rec_001_replace_now`

## 5) List all events for the bearing purpose in time order

**Intent:** produce a complete timeline for audit/replay.

Pseudo-SQL:

```sql
SELECT uuid, event_type, agent, start_time, recorded_time
FROM event
WHERE
  assessment_purpose = 'purpose:high_speed_rotation'
  OR recommendation_purpose = 'purpose:high_speed_rotation'
  OR uuid IN (
    'event:action_001_replace_bearing',
    'event:obs_003_connection_effective_stop',
    'event:obs_004_post_replacement_temp'
  )
ORDER BY COALESCE(start_time, recorded_time), recorded_time;
```

Expected result sequence:
1. `event:health_001_unsuitable`
2. `event:rec_001_replace_now`
3. `event:rec_002_monitor_first`
4. `event:action_001_replace_bearing`
5. `event:obs_003_connection_effective_stop`
6. `event:obs_004_post_replacement_temp`
7. `event:health_002_restored`

## 6) Show all namespaced parameters used (flexibility audit)

**Intent:** show structured core + extensible domains.

Examples present in this scenario:
- `base:*` → common ontology keys
- `sensor:*` → sensor metadata
- `predictive:*` → model output semantics
- `maintenance:*` → work execution semantics
- `ops:*` → operational tradeoff rationale
