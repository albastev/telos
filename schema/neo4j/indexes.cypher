// TELOS Neo4j Indexes
// Version: 1.0.0

// -----------------------------------------------------------------------------
// Temporal Indexes
// -----------------------------------------------------------------------------

CREATE INDEX event_start_time_idx IF NOT EXISTS
FOR (n:Event)
ON (n.start_time);

CREATE INDEX event_stop_time_idx IF NOT EXISTS
FOR (n:Event)
ON (n.stop_time);

CREATE INDEX event_recorded_time_idx IF NOT EXISTS
FOR (n:Event)
ON (n.recorded_time);

CREATE INDEX connection_start_time_idx IF NOT EXISTS
FOR (n:Connection)
ON (n.start_time);

CREATE INDEX connection_stop_time_idx IF NOT EXISTS
FOR (n:Connection)
ON (n.stop_time);

CREATE INDEX connection_effective_stop_time_idx IF NOT EXISTS
FOR (n:Connection)
ON (n.effective_stop_time);

CREATE INDEX connection_recorded_time_idx IF NOT EXISTS
FOR (n:Connection)
ON (n.recorded_time);

// -----------------------------------------------------------------------------
// Frequent Filter / Join Indexes
// -----------------------------------------------------------------------------

CREATE INDEX event_type_idx IF NOT EXISTS
FOR (n:Event)
ON (n.event_type);

CREATE INDEX purpose_type_idx IF NOT EXISTS
FOR (n:Purpose)
ON (n.purpose_type);

CREATE INDEX purpose_purpose_connection_type_idx IF NOT EXISTS
FOR (n:PurposePurposeConnection)
ON (n.connection_type);

CREATE INDEX event_event_connection_type_idx IF NOT EXISTS
FOR (n:EventEventConnection)
ON (n.connection_type);

CREATE INDEX port_set_direction_idx IF NOT EXISTS
FOR (n:PortSet)
ON (n.direction);

CREATE INDEX engineering_unit_namespace_idx IF NOT EXISTS
FOR (n:EngineeringUnit)
ON (n.namespace);

CREATE INDEX contingency_resolution_time_idx IF NOT EXISTS
FOR (n:ContingencyResolution)
ON (n.resolution_time);
