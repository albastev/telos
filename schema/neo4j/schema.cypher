// TELOS Neo4j Concrete Schema Mapping
// Version: 1.0.0
//
// This file documents the concrete graph model and canonical write patterns.
// Constraints/indexes are defined in constraints.cypher and indexes.cypher.

// -----------------------------------------------------------------------------
// Label Model
// -----------------------------------------------------------------------------
// Core entities:
//   (:Thing)
//   (:Agent)
//   (:Purpose)
//     - subtype labels: :Algorithm, :Port
//
// Events:
//   (:Event)
//     - subtype labels:
//       :ObservationEvent, :ActionEvent, :HealthAssessmentEvent,
//       :RecommendationEvent, :ContingencyEvent, :ResultSetEvent
//
// Connections (modeled as first-class nodes so they can be observed):
//   (:Connection)
//     - subtype labels:
//       :ThingPurposeConnection, :PurposePurposeConnection, :EventEventConnection
//
// Support structures:
//   (:PortSet)
//   (:PortSetMembership)
//   (:ContingencyAlternative)
//   (:ContingencyResolution)
//   (:EngineeringUnit)

// -----------------------------------------------------------------------------
// Relationship Model
// -----------------------------------------------------------------------------
// Common attribution:
//   (a:Agent)-[:ASSERTED]->(n)        // n in Event|Connection|Purpose|PortSet|EngineeringUnit
//
// Observation targeting (polymorphic Thing|Purpose|Event|Connection):
//   (e:ObservationEvent)-[:OBSERVES]->(target)
//
// HealthAssessment:
//   (e:HealthAssessmentEvent)-[:ASSESSMENT_OF_THING]->(t:Thing)
//   (e:HealthAssessmentEvent)-[:ASSESSMENT_OF_PURPOSE]->(p:Purpose)
//
// Recommendation:
//   (e:RecommendationEvent)-[:RECOMMENDS_FOR_THING]->(t:Thing)
//   (e:RecommendationEvent)-[:RECOMMENDS_FOR_PURPOSE]->(p:Purpose)
//
// ResultSet:
//   (e:ResultSetEvent)-[:RESULT_SET_ALGORITHM]->(alg:Algorithm)
//   (e:ResultSetEvent)-[:RESULT_SET_ACTION]->(a:ActionEvent)
//
// ThingPurposeConnection:
//   (c:ThingPurposeConnection)-[:THING]->(t:Thing)
//   (c:ThingPurposeConnection)-[:PURPOSE]->(p:Purpose)
//
// PurposePurposeConnection:
//   (c:PurposePurposeConnection)-[:SOURCE_PURPOSE]->(sp:Purpose)
//   (c:PurposePurposeConnection)-[:TARGET_PURPOSE]->(tp:Purpose)
//
// EventEventConnection:
//   (c:EventEventConnection)-[:SOURCE_EVENT]->(se:Event)
//   (c:EventEventConnection)-[:TARGET_EVENT]->(te:Event)
//
// PortSet:
//   (ps:PortSet)-[:ALGORITHM]->(alg:Algorithm)
//
// PortSetMembership:
//   (m:PortSetMembership)-[:IN_PORT_SET]->(ps:PortSet)
//   (m:PortSetMembership)-[:MEMBER_PORT]->(p:Port)
//
// ContingencyAlternative:
//   (ca:ContingencyAlternative)-[:CONTINGENCY]->(c:ContingencyEvent)
//   (ca:ContingencyAlternative)-[:ALTERNATIVE_EVENT]->(e:Event)
//
// ContingencyResolution:
//   (cr:ContingencyResolution)-[:CONTINGENCY]->(c:ContingencyEvent)
//   (cr:ContingencyResolution)-[:RESOLVING_ACTION]->(a:ActionEvent)
//   (cr:ContingencyResolution)-[:SELECTED_ALTERNATIVE]->(e:Event)
//
// EngineeringUnit hierarchy:
//   (u:EngineeringUnit)-[:BASE_UNIT]->(base:EngineeringUnit)

// -----------------------------------------------------------------------------
// Canonical Write Patterns (append-only ingestion)
// -----------------------------------------------------------------------------

// 1) Core Entity: Agent
// Params: $uuid, $created_at, $parameters
MERGE (a:Agent {uuid: $uuid})
  ON CREATE SET
    a.created_at = datetime($created_at),
    a.parameters = coalesce($parameters, {});

// 2) Core Entity: Thing
// Params: $uuid, $created_at, $parameters
MERGE (t:Thing {uuid: $uuid})
  ON CREATE SET
    t.created_at = datetime($created_at),
    t.parameters = coalesce($parameters, {});

// 3) Purpose (base/algorithm/port)
// Params: $uuid, $purpose_type, $created_at, $created_by_agent, $parameters,
//         $application_reference?, $version?, $data_type?
MATCH (a:Agent {uuid: $created_by_agent})
MERGE (p:Purpose {uuid: $uuid})
  ON CREATE SET
    p.created_at = datetime($created_at),
    p.purpose_type = $purpose_type,
    p.parameters = coalesce($parameters, {}),
    p.application_reference = $application_reference,
    p.version = $version,
    p.data_type = $data_type
MERGE (a)-[:ASSERTED]->(p)
WITH p
FOREACH (_ IN CASE WHEN $purpose_type = 'algorithm' THEN [1] ELSE [] END |
  SET p:Algorithm
)
FOREACH (_ IN CASE WHEN $purpose_type = 'port' THEN [1] ELSE [] END |
  SET p:Port
);

// 4) Event (with subtype labels)
// Params:
//   $uuid, $event_type, $agent, $start_time, $recorded_time,
//   $start_time_uncertainty?, $stop_time?, $stop_time_uncertainty?, $parameters?
// Optional refs by type:
//   observation:      $thing_observed
//   health_assessment:$assessment_thing, $assessment_purpose
//   recommendation:   $recommendation_thing, $recommendation_purpose
//   contingency:      $logic_type
//   result_set:       $result_set_algorithm, $result_set_action
MATCH (a:Agent {uuid: $agent})
MERGE (e:Event {uuid: $uuid})
  ON CREATE SET
    e.event_type = $event_type,
    e.start_time = datetime($start_time),
    e.start_time_uncertainty = $start_time_uncertainty,
    e.stop_time = CASE WHEN $stop_time IS NULL THEN NULL ELSE datetime($stop_time) END,
    e.stop_time_uncertainty = $stop_time_uncertainty,
    e.recorded_time = datetime($recorded_time),
    e.parameters = coalesce($parameters, {}),
    e.logic_type = $logic_type
MERGE (a)-[:ASSERTED]->(e)
WITH e
FOREACH (_ IN CASE WHEN $event_type = 'observation' THEN [1] ELSE [] END | SET e:ObservationEvent)
FOREACH (_ IN CASE WHEN $event_type = 'action' THEN [1] ELSE [] END | SET e:ActionEvent)
FOREACH (_ IN CASE WHEN $event_type = 'health_assessment' THEN [1] ELSE [] END | SET e:HealthAssessmentEvent)
FOREACH (_ IN CASE WHEN $event_type = 'recommendation' THEN [1] ELSE [] END | SET e:RecommendationEvent)
FOREACH (_ IN CASE WHEN $event_type = 'contingency' THEN [1] ELSE [] END | SET e:ContingencyEvent)
FOREACH (_ IN CASE WHEN $event_type = 'result_set' THEN [1] ELSE [] END | SET e:ResultSetEvent);

// 4a) Optional Event reference links (run conditionally in ingestion layer)
// Observation target (Thing|Purpose|Event|Connection)
MATCH (e:ObservationEvent {uuid: $event_uuid}), (target {uuid: $thing_observed})
WHERE target:Thing OR target:Purpose OR target:Event OR target:Connection
MERGE (e)-[:OBSERVES]->(target);

// HealthAssessment targets
MATCH (e:HealthAssessmentEvent {uuid: $event_uuid}), (t:Thing {uuid: $assessment_thing})
MERGE (e)-[:ASSESSMENT_OF_THING]->(t);
MATCH (e:HealthAssessmentEvent {uuid: $event_uuid}), (p:Purpose {uuid: $assessment_purpose})
MERGE (e)-[:ASSESSMENT_OF_PURPOSE]->(p);

// Recommendation targets
MATCH (e:RecommendationEvent {uuid: $event_uuid}), (t:Thing {uuid: $recommendation_thing})
MERGE (e)-[:RECOMMENDS_FOR_THING]->(t);
MATCH (e:RecommendationEvent {uuid: $event_uuid}), (p:Purpose {uuid: $recommendation_purpose})
MERGE (e)-[:RECOMMENDS_FOR_PURPOSE]->(p);

// ResultSet links
MATCH (e:ResultSetEvent {uuid: $event_uuid}), (alg:Algorithm {uuid: $result_set_algorithm})
MERGE (e)-[:RESULT_SET_ALGORITHM]->(alg);
MATCH (e:ResultSetEvent {uuid: $event_uuid}), (a:ActionEvent {uuid: $result_set_action})
MERGE (e)-[:RESULT_SET_ACTION]->(a);

// 5) ThingPurposeConnection
// Params: $uuid, $agent, $thing, $purpose, $start_time, $recorded_time,
//         $start_time_uncertainty?, $stop_time?, $stop_time_uncertainty?, $effective_stop_time?, $parameters?
MATCH (a:Agent {uuid: $agent}), (t:Thing {uuid: $thing}), (p:Purpose {uuid: $purpose})
MERGE (c:Connection:ThingPurposeConnection {uuid: $uuid})
  ON CREATE SET
    c.start_time = datetime($start_time),
    c.start_time_uncertainty = $start_time_uncertainty,
    c.stop_time = CASE WHEN $stop_time IS NULL THEN NULL ELSE datetime($stop_time) END,
    c.stop_time_uncertainty = $stop_time_uncertainty,
    c.effective_stop_time = CASE WHEN $effective_stop_time IS NULL THEN NULL ELSE datetime($effective_stop_time) END,
    c.recorded_time = datetime($recorded_time),
    c.parameters = coalesce($parameters, {})
MERGE (a)-[:ASSERTED]->(c)
MERGE (c)-[:THING]->(t)
MERGE (c)-[:PURPOSE]->(p);

// 6) PurposePurposeConnection
// Params include: $connection_type, $source_purpose, $target_purpose
MATCH (a:Agent {uuid: $agent}),
      (sp:Purpose {uuid: $source_purpose}),
      (tp:Purpose {uuid: $target_purpose})
MERGE (c:Connection:PurposePurposeConnection {uuid: $uuid})
  ON CREATE SET
    c.connection_type = $connection_type,
    c.start_time = datetime($start_time),
    c.start_time_uncertainty = $start_time_uncertainty,
    c.stop_time = CASE WHEN $stop_time IS NULL THEN NULL ELSE datetime($stop_time) END,
    c.stop_time_uncertainty = $stop_time_uncertainty,
    c.effective_stop_time = CASE WHEN $effective_stop_time IS NULL THEN NULL ELSE datetime($effective_stop_time) END,
    c.recorded_time = datetime($recorded_time),
    c.parameters = coalesce($parameters, {})
MERGE (a)-[:ASSERTED]->(c)
MERGE (c)-[:SOURCE_PURPOSE]->(sp)
MERGE (c)-[:TARGET_PURPOSE]->(tp);

// 7) EventEventConnection
// Params include: $connection_type, $source_event, $target_event
MATCH (a:Agent {uuid: $agent}),
      (se:Event {uuid: $source_event}),
      (te:Event {uuid: $target_event})
MERGE (c:Connection:EventEventConnection {uuid: $uuid})
  ON CREATE SET
    c.connection_type = $connection_type,
    c.start_time = datetime($start_time),
    c.start_time_uncertainty = $start_time_uncertainty,
    c.stop_time = CASE WHEN $stop_time IS NULL THEN NULL ELSE datetime($stop_time) END,
    c.stop_time_uncertainty = $stop_time_uncertainty,
    c.effective_stop_time = CASE WHEN $effective_stop_time IS NULL THEN NULL ELSE datetime($effective_stop_time) END,
    c.recorded_time = datetime($recorded_time),
    c.parameters = coalesce($parameters, {})
MERGE (a)-[:ASSERTED]->(c)
MERGE (c)-[:SOURCE_EVENT]->(se)
MERGE (c)-[:TARGET_EVENT]->(te);

// 8) PortSet
// Params: $uuid, $algorithm, $direction, $created_at, $created_by_agent, $parameters?
MATCH (alg:Algorithm {uuid: $algorithm}), (a:Agent {uuid: $created_by_agent})
MERGE (ps:PortSet {uuid: $uuid})
  ON CREATE SET
    ps.direction = $direction,
    ps.created_at = datetime($created_at),
    ps.parameters = coalesce($parameters, {})
MERGE (a)-[:ASSERTED]->(ps)
MERGE (ps)-[:ALGORITHM]->(alg);

// 9) PortSetMembership
// Params: $uuid, $port_set, $port, $created_at, $ordinal?, $required?
MATCH (ps:PortSet {uuid: $port_set}), (p:Port {uuid: $port})
MERGE (m:PortSetMembership {uuid: $uuid})
  ON CREATE SET
    m.ordinal = $ordinal,
    m.required = coalesce($required, true),
    m.created_at = datetime($created_at)
MERGE (m)-[:IN_PORT_SET]->(ps)
MERGE (m)-[:MEMBER_PORT]->(p);

// 10) ContingencyAlternative
// Params: $uuid, $contingency, $alternative_event, $created_at, $ordinal?
MATCH (c:ContingencyEvent {uuid: $contingency}), (e:Event {uuid: $alternative_event})
MERGE (ca:ContingencyAlternative {uuid: $uuid})
  ON CREATE SET
    ca.created_at = datetime($created_at),
    ca.ordinal = $ordinal
MERGE (ca)-[:CONTINGENCY]->(c)
MERGE (ca)-[:ALTERNATIVE_EVENT]->(e);

// 11) ContingencyResolution
// Params: $uuid, $contingency, $resolving_action, $selected_alternative, $resolution_time
MATCH (c:ContingencyEvent {uuid: $contingency}),
      (a:ActionEvent {uuid: $resolving_action}),
      (e:Event {uuid: $selected_alternative})
MERGE (cr:ContingencyResolution {uuid: $uuid})
  ON CREATE SET
    cr.resolution_time = datetime($resolution_time)
MERGE (cr)-[:CONTINGENCY]->(c)
MERGE (cr)-[:RESOLVING_ACTION]->(a)
MERGE (cr)-[:SELECTED_ALTERNATIVE]->(e);

// 12) EngineeringUnit
// Params: $uuid, $name, $created_at, $created_by_agent, $namespace,
//         $multiplication_factor?, $offset?, $parameters?, $base_unit?
MATCH (a:Agent {uuid: $created_by_agent})
MERGE (u:EngineeringUnit {uuid: $uuid})
  ON CREATE SET
    u.name = $name,
    u.created_at = datetime($created_at),
    u.namespace = $namespace,
    u.multiplication_factor = coalesce($multiplication_factor, 1.0),
    u.offset = coalesce($offset, 0.0),
    u.parameters = coalesce($parameters, {})
MERGE (a)-[:ASSERTED]->(u)
WITH u
OPTIONAL MATCH (base:EngineeringUnit {uuid: $base_unit})
FOREACH (_ IN CASE WHEN base IS NULL THEN [] ELSE [1] END |
  MERGE (u)-[:BASE_UNIT]->(base)
);
