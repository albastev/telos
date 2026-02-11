// TELOS Neo4j Constraints
// Version: 1.0.0

// -----------------------------------------------------------------------------
// UUID Uniqueness Constraints
// -----------------------------------------------------------------------------

CREATE CONSTRAINT agent_uuid_unique IF NOT EXISTS
FOR (n:Agent)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT thing_uuid_unique IF NOT EXISTS
FOR (n:Thing)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT purpose_uuid_unique IF NOT EXISTS
FOR (n:Purpose)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT event_uuid_unique IF NOT EXISTS
FOR (n:Event)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT connection_uuid_unique IF NOT EXISTS
FOR (n:Connection)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT port_set_uuid_unique IF NOT EXISTS
FOR (n:PortSet)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT port_set_membership_uuid_unique IF NOT EXISTS
FOR (n:PortSetMembership)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT contingency_alternative_uuid_unique IF NOT EXISTS
FOR (n:ContingencyAlternative)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT contingency_resolution_uuid_unique IF NOT EXISTS
FOR (n:ContingencyResolution)
REQUIRE n.uuid IS UNIQUE;

CREATE CONSTRAINT engineering_unit_uuid_unique IF NOT EXISTS
FOR (n:EngineeringUnit)
REQUIRE n.uuid IS UNIQUE;

// -----------------------------------------------------------------------------
// Required Property Constraints
// -----------------------------------------------------------------------------

CREATE CONSTRAINT agent_created_at_required IF NOT EXISTS
FOR (n:Agent)
REQUIRE n.created_at IS NOT NULL;

CREATE CONSTRAINT thing_created_at_required IF NOT EXISTS
FOR (n:Thing)
REQUIRE n.created_at IS NOT NULL;

CREATE CONSTRAINT purpose_type_required IF NOT EXISTS
FOR (n:Purpose)
REQUIRE n.purpose_type IS NOT NULL;

CREATE CONSTRAINT purpose_created_at_required IF NOT EXISTS
FOR (n:Purpose)
REQUIRE n.created_at IS NOT NULL;

CREATE CONSTRAINT event_type_required IF NOT EXISTS
FOR (n:Event)
REQUIRE n.event_type IS NOT NULL;

CREATE CONSTRAINT event_start_time_required IF NOT EXISTS
FOR (n:Event)
REQUIRE n.start_time IS NOT NULL;

CREATE CONSTRAINT event_recorded_time_required IF NOT EXISTS
FOR (n:Event)
REQUIRE n.recorded_time IS NOT NULL;

CREATE CONSTRAINT connection_start_time_required IF NOT EXISTS
FOR (n:Connection)
REQUIRE n.start_time IS NOT NULL;

CREATE CONSTRAINT connection_recorded_time_required IF NOT EXISTS
FOR (n:Connection)
REQUIRE n.recorded_time IS NOT NULL;

CREATE CONSTRAINT port_set_direction_required IF NOT EXISTS
FOR (n:PortSet)
REQUIRE n.direction IS NOT NULL;

CREATE CONSTRAINT port_set_created_at_required IF NOT EXISTS
FOR (n:PortSet)
REQUIRE n.created_at IS NOT NULL;

CREATE CONSTRAINT port_set_membership_created_at_required IF NOT EXISTS
FOR (n:PortSetMembership)
REQUIRE n.created_at IS NOT NULL;

CREATE CONSTRAINT contingency_alternative_created_at_required IF NOT EXISTS
FOR (n:ContingencyAlternative)
REQUIRE n.created_at IS NOT NULL;

CREATE CONSTRAINT contingency_resolution_time_required IF NOT EXISTS
FOR (n:ContingencyResolution)
REQUIRE n.resolution_time IS NOT NULL;

CREATE CONSTRAINT engineering_unit_name_required IF NOT EXISTS
FOR (n:EngineeringUnit)
REQUIRE n.name IS NOT NULL;

CREATE CONSTRAINT engineering_unit_namespace_required IF NOT EXISTS
FOR (n:EngineeringUnit)
REQUIRE n.namespace IS NOT NULL;

CREATE CONSTRAINT engineering_unit_created_at_required IF NOT EXISTS
FOR (n:EngineeringUnit)
REQUIRE n.created_at IS NOT NULL;
