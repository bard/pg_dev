function cmd_generate_migration() {
  local CURRENT_SCHEMA_FILE
  local CURRENT_SCHEMA_FINGERPRINT
  local PREVIOUS_SCHEMA_FILE
  local PREVIOUS_SCHEMA_FINGERPRINT
  local PREVIOUS_SCHEMA_COMMIT
  local POSTGRES_URI
  local POSTGRES_DATA_DIR
  local NEXT_MIGRATION_INDEX
  local LAST_MIGRATION_FILE
  local MIGRATION_FILE
  local MIGRATION_DIRECTORY

  if [ $# -lt 2 ]; then
    cmd_help
    exit 1
  fi
    
  CURRENT_SCHEMA_FILE=$1
  MIGRATION_DIRECTORY=$2

  if [ ! -e "$CURRENT_SCHEMA_FILE" ] || [ ! -d "$MIGRATION_DIRECTORY" ]; then
    cmd_help
    exit 1
  fi

  if [ $# -eq 3 ]; then
    NEXT_MIGRATION_INDEX=$(printf "%03d" $3)
  else
    NEXT_MIGRATION_INDEX=$(printf "%03d" $(get_next_migration_index "$MIGRATION_DIRECTORY"))
  fi      
  
  CURRENT_SCHEMA_FINGERPRINT=$(fingerprint_schema <$CURRENT_SCHEMA_FILE)
  
  PREVIOUS_SCHEMA_FILE=/tmp/schema_previous.sql
  if ! does_repo_have_commits || ! does_file_exist_in_history $CURRENT_SCHEMA_FILE; then
    echo "No previous revisions of the schema found in the repo history."
    echo "Will diff against an empty schema to produce the initial migration."
    echo
    
    echo "" >$PREVIOUS_SCHEMA_FILE
    PREVIOUS_SCHEMA_COMMIT=none
    PREVIOUS_SCHEMA_FINGERPRINT=none
  elif ! does_file_have_changes $CURRENT_SCHEMA_FILE; then
    echo "Error: there are no unstaged changes in $CURRENT_SCHEMA_FILE."
    echo 
    echo "Please run this tool before committing changes to the schema file,"
    echo "then commit schema changes and migration together."
    echo
    exit 1    
  else    
    PREVIOUS_SCHEMA_COMMIT=$(git rev-list -1 HEAD $CURRENT_SCHEMA_FILE)
    git show ${PREVIOUS_SCHEMA_COMMIT}:${CURRENT_SCHEMA_FILE} >${PREVIOUS_SCHEMA_FILE}
    PREVIOUS_SCHEMA_FINGERPRINT=$(fingerprint_schema <$PREVIOUS_SCHEMA_FILE)
    
    if [ "$CURRENT_SCHEMA_FINGERPRINT" = "$PREVIOUS_SCHEMA_FINGERPRINT" ]; then
      echo "Error: Current schema and last committed schema are equivalent;"
      echo "nothing to do."
      echo
      exit 1
    fi
  fi

  echo "Current schema:"
  echo "  - location: $CURRENT_SCHEMA_FILE"
  echo "  - fingerprint: $CURRENT_SCHEMA_FINGERPRINT"
  echo

  echo "Previous schema:"
  echo "  - commit: ${PREVIOUS_SCHEMA_COMMIT}"
  echo "  - fingerprint: ${PREVIOUS_SCHEMA_FINGERPRINT}"
  echo
  
  ######################################################################

  export PGPORT=15432
  echo -n "Starting postgres... "
  POSTGRES_URI=$(run_postgres_tmp)
  echo "done."
  echo ${POSTGRES_URI}

  ######################################################################

  echo -n "Creating databases and loading schemas... "
  
  psql "${POSTGRES_URI}" -c 'CREATE DATABASE db_previous;' >/dev/null 
  psql "${POSTGRES_URI}" -c 'CREATE DATABASE db_current;' >/dev/null

  DB_PREVIOUS_URI=$(echo $POSTGRES_URI | sed 's|/test|/db_previous|')
  DB_CURRENT_URI=$(echo $POSTGRES_URI | sed 's|/test|/db_current|')
  
  psql "${DB_PREVIOUS_URI}" -v 'ON_ERROR_STOP=1' -1 \
         <$PREVIOUS_SCHEMA_FILE >/dev/null
  psql "${DB_CURRENT_URI}" -v 'ON_ERROR_STOP=1' -1 \
         <$CURRENT_SCHEMA_FILE >/dev/null 
  
  echo "done."

  ######################################################################

  if get_last_migration_file "$MIGRATION_DIRECTORY" | grep -e "-${CURRENT_SCHEMA_FINGERPRINT}.sql$" >/dev/null; then
    echo "Error: current schema is already covered by last existing migration."
    echo
    exit 1
  fi
  
  MIGRATION_FILE=${MIGRATION_DIRECTORY}/${NEXT_MIGRATION_INDEX}_${PREVIOUS_SCHEMA_FINGERPRINT}-${CURRENT_SCHEMA_FINGERPRINT}.sql
  echo -n "Diff'ing previous and current schemas... "
  # XXX why does migra exit with status code 2?
  
  migra --unsafe "${DB_PREVIOUS_URI}" "${DB_CURRENT_URI}" >${MIGRATION_FILE} || true
  echo "done."
  echo

  echo "Migration saved as: ${MIGRATION_FILE}"
  echo
}
