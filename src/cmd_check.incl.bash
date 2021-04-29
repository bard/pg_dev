
function cmd_check() {
  local CURRENT_SCHEMA_FILE
  local CURRENT_SCHEMA_FINGERPRINT
  local LAST_MIGRATION_FILE
  
  CURRENT_SCHEMA_FILE=$1
  CURRENT_SCHEMA_FINGERPRINT=$(fingerprint_schema <$CURRENT_SCHEMA_FILE)
  LAST_MIGRATION_FILE=get_last_migration_file

  if echo $LAST_MIGRATION_FILE | grep "-${CURRENT_SCHEMA_FINGERPRINT}.sql$" >/dev/null; then
    echo "Last migration points to current schema, all good."
  else
    echo "Error: Last migration does not match current schema fingerprint."
    echo "  - last migration file: ${LAST_MIGRATION_FILE}"
    echo "  - current schema fingerprint: ${CURRENT_SCHEMA_FINGERPRINT}"
    echo
    return 1
  fi
}
