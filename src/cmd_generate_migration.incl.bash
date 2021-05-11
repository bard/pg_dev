function validate_args() {
  if [ $# -lt 2 ]; then
    cmd_help
    return 1
  fi

  if [ ! -r "$1" ]; then
    echo "Schema $1 does not exist or is not readable"
    return 1
  fi

  if [ ! -d "$2" ] || [ ! -x "$2" ]; then
    echo "Directory $2 does not exist or is not accessible"
    return 1
  fi
}

function cmd_generate_migration() {
  local SCHEMA_FILE
  local MIGRATION_DIRECTORY
  local LAST_MIGRATION_FILE
  local LAST_MIGRATION_FINGERPRINT
  local NEXT_MIGRATION_FILE
  local NEXT_MIGRATION_INDEX
  local DB_PREVIOUS_URI
  local DB_CURRENT_URI
  local LAST_SCHEMA_FILE
  local NO_START_PG=${NO_START_PG:-0}
  
  validate_args "$1" "$2"

  SCHEMA_FILE="$1"
  MIGRATION_DIRECTORY="$2"
  CURRENT_SCHEMA_FINGERPRINT=$(fingerprint_schema <$SCHEMA_FILE)  
  LAST_MIGRATION_FILE="$(get_last_migration_file $MIGRATION_DIRECTORY)"
  LAST_MIGRATION_FINGERPRINT="$(get_migration_target_fingerprint ${LAST_MIGRATION_FILE})"

  echo "Schema file name: ${SCHEMA_FILE}"
  echo "Migration directory: ${MIGRATION_DIRECTORY}"
  echo "Current schema fingerprint: ${CURRENT_SCHEMA_FINGERPRINT}"
  echo "Last migration file: ${LAST_MIGRATION_FILE}"
  echo "Last migrated schema fingerprint: ${LAST_MIGRATION_FINGERPRINT:-none}"
  echo "Last migrated schema commit: ${PREVIOUS_SCHEMA_COMMIT:-none}"
  
  if [ -z "$LAST_MIGRATION_FILE" ]; then
    NEXT_MIGRATION_FILE="$MIGRATION_DIRECTORY/000_${PREVIOUS_SCHEMA_FINGERPRINT:-none}-${CURRENT_SCHEMA_FINGERPRINT}.sql"
    if [ "$NO_START_PG" -eq 1 ]; then
      touch $NEXT_MIGRATION_FILE
    else
      LAST_SCHEMA_FILE=/tmp/schemachain-last_schema.sql
      touch $LAST_SCHEMA_FILE
      echo -n "Starting postgres servers... "
      DB_PREVIOUS_URI=$(run_postgres_tmp)
      DB_CURRENT_URI=$(run_postgres_tmp)
      echo "done."

      echo -n "Creating databases and loading schemas... "
      psql "${DB_PREVIOUS_URI}" -v 'ON_ERROR_STOP=1' -1 <$LAST_SCHEMA_FILE >/dev/null
      psql "${DB_CURRENT_URI}" -v 'ON_ERROR_STOP=1' -1 <$SCHEMA_FILE >/dev/null
      echo "done."

      echo -n "Diff'ing previous and current schemas... "
      migra --unsafe "${DB_PREVIOUS_URI}" "${DB_CURRENT_URI}" >${NEXT_MIGRATION_FILE}
      echo "done."
    fi
  else 
    LAST_MIGRATION_FINGERPRINT="$(get_migration_target_fingerprint $LAST_MIGRATION_FILE)"

    if [ "$LAST_MIGRATION_FINGERPRINT" = "$CURRENT_SCHEMA_FINGERPRINT" ]; then
      echo "Schema and last migration match, nothing to do."
    else 
      NEXT_MIGRATION_INDEX=$(printf "%03d" $(get_next_migration_index "$MIGRATION_DIRECTORY"))
      NEXT_MIGRATION_FILE="$MIGRATION_DIRECTORY/${NEXT_MIGRATION_INDEX}_${LAST_MIGRATION_FINGERPRINT}-${CURRENT_SCHEMA_FINGERPRINT}.sql"
      if [ -n "$NO_START_PG" ]; then
        touch $NEXT_MIGRATION_FILE
      else
        LAST_SCHEMA_FILE=/tmp/schemachain-last_schema.sql
        cat_schema_version_with_fingerprint $LAST_MIGRATION_FINGERPRINT >${LAST_SCHEMA_FILE}

        echo -n "Starting postgres servers... "
        DB_PREVIOUS_URI=$(run_postgres_tmp)
        DB_CURRENT_URI=$(run_postgres_tmp)
        echo "done."

        echo -n "Creating databases and loading schemas... "
        psql "${DB_PREVIOUS_URI}" -v 'ON_ERROR_STOP=1' -1 <$LAST_SCHEMA_FILE >/dev/null
        psql "${DB_CURRENT_URI}" -v 'ON_ERROR_STOP=1' -1 <$SCHEMA_FILE >/dev/null
        echo "done."

        echo -n "Diff'ing previous and current schemas... "
        migra --unsafe "${DB_PREVIOUS_URI}" "${DB_CURRENT_URI}" >${NEXT_MIGRATION_FILE}
        echo "done."
      fi
    fi
  fi    
}
