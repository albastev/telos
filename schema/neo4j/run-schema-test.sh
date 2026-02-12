#!/bin/sh
set -eu

NEO4J_URI="${NEO4J_URI:-bolt://localhost:7687}"
NEO4J_USERNAME="${NEO4J_USERNAME:-neo4j}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-testpassword}"
NEO4J_DB="${NEO4J_DB:-neo4j}"
NEO4J_READY_TIMEOUT_SECONDS="${NEO4J_READY_TIMEOUT_SECONDS:-180}"

log() {
  printf '%s\n' "$1"
}

cypher_shell() {
  cypher-shell \
    -a "$NEO4J_URI" \
    -u "$NEO4J_USERNAME" \
    -p "$NEO4J_PASSWORD" \
    -d "$NEO4J_DB" \
    "$@"
}

cypher_shell_system() {
  cypher-shell \
    -a "$NEO4J_URI" \
    -u "$NEO4J_USERNAME" \
    -p "$NEO4J_PASSWORD" \
    -d "system" \
    "$@"
}

wait_for_system_db() {
  log "[schema-test] Waiting for Neo4j system database at $NEO4J_URI (timeout: ${NEO4J_READY_TIMEOUT_SECONDS}s)..."

  deadline=$(( $(date +%s) + NEO4J_READY_TIMEOUT_SECONDS ))
  while true; do
    if cypher_shell_system "SHOW DATABASES YIELD name RETURN count(name);" >/dev/null 2>&1; then
      log "[schema-test] Neo4j system database is ready."
      return 0
    fi

    now=$(date +%s)
    if [ "$now" -ge "$deadline" ]; then
      log "[schema-test] ERROR: Neo4j was not ready before timeout."
      return 1
    fi

    sleep 2
  done
}

ensure_target_db() {
  log "[schema-test] Ensuring target database '$NEO4J_DB' exists..."
  cypher_shell_system "CREATE DATABASE \`$NEO4J_DB\` IF NOT EXISTS;"
}

wait_for_target_db() {
  log "[schema-test] Waiting for target database '$NEO4J_DB' to become available..."

  deadline=$(( $(date +%s) + NEO4J_READY_TIMEOUT_SECONDS ))
  while true; do
    if cypher_shell "RETURN 1;" >/dev/null 2>&1; then
      log "[schema-test] Target database '$NEO4J_DB' is ready."
      return 0
    fi

    now=$(date +%s)
    if [ "$now" -ge "$deadline" ]; then
      log "[schema-test] ERROR: Target database '$NEO4J_DB' was not ready before timeout."
      return 1
    fi

    sleep 2
  done
}

apply_script() {
  script_path="$1"
  log "[schema-test] Applying $script_path"
  cypher_shell -f "$script_path"
}

main() {
  wait_for_system_db
  ensure_target_db
  wait_for_target_db

  apply_script "./constraints.cypher"
  apply_script "./indexes.cypher"

  log "[schema-test] SUCCESS: constraints and indexes applied cleanly."
}

main "$@"
