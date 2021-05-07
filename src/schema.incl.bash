function fingerprint_schema() {
  python3 -c 'import sys; from pglast.parser import fingerprint; print(fingerprint(sys.stdin.read()))'
}

function check_schema_up_to_date() {
  local SCHEMA_FILE
  local MIGRATION_DIRECTORY
  local SCHEMA_FINGERPRINT
  local LAST_MIGRATION_FILE
  local LAST_MIGRATION_FINGERPRINT
  SCHEMA_FILE="$1"
  MIGRATION_DIRECTORY="$2"

  SCHEMA_FINGERPRINT=$(fingerprint_schema < "$SCHEMA_FILE")  
  LAST_MIGRATION_FILE=$(get_last_migration_file "$MIGRATION_DIRECTORY")
  LAST_MIGRATION_FINGERPRINT=$(get_migration_target_fingerprint "$LAST_MIGRATION_FILE")
  test "$SCHEMA_FINGERPRINT" = "$LAST_MIGRATION_FINGERPRINT"
}
