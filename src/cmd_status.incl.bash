
function cmd_status() {
  local SCHEMA_FILENAME
  local MIGRATION_DIRECTORY
  local LAST_MIGRATION_FILENAME
  local COMMITTED_SCHEMA_FINGERPRINT
  
  if [ $# -lt 2 ]; then
    cmd_help
    exit 1
  fi
    
  SCHEMA_FILENAME=$1
  MIGRATION_DIRECTORY=$2

  echo
    
  if [ ! -r $SCHEMA_FILENAME ]; then
    echo " - File does not exist or cannot be read: ${SCHEMA_FILENAME}"
    return 1
  fi

  if ! does_file_exist_in_history "$SCHEMA_FILENAME"; then
    echo " - Schema file $SCHEMA_FILENAME present in work tree but absent from git"
    echo "   history."
    echo "   Run 'generate-migration' to generate the initial migration, then"
    echo "   commit both the schema and the migration file."
    return 1
  fi
  
  WORKTREE_SCHEMA_FINGERPRINT=$(fingerprint_schema <$SCHEMA_FILENAME)
  COMMITTED_SCHEMA_FINGERPRINT=$(read_last_committed_version $SCHEMA_FILENAME | fingerprint_schema)
  LAST_MIGRATION_FILE=$(get_last_migration_file $MIGRATION_DIRECTORY)
  LAST_MIGRATION_FINGERPRINT=$(get_migration_target_fingerprint $(get_last_migration_file $MIGRATION_DIRECTORY))

  if [ "$WORKTREE_SCHEMA_FINGERPRINT" = "$COMMITTED_SCHEMA_FINGERPRINT" ]; then
    echo " - Schema working copy and last committed schema match."
    echo "   Nothing to do."
  else
    echo " - Schema working copy differs from last committed schema."
    
    if [ "$LAST_MIGRATION_FINGERPRINT" != "$WORKTREE_SCHEMA_FINGERPRINT" ]; then
      echo " - Last migration does not cover latest changes. Remember to run '$(basename $0) generate-migration $SCHEMA_FILENAME $MIGRATION_DIRECTORY' before committing schema changes."
    fi
    return 1
  fi
  echo

}
