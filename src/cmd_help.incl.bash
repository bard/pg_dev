function cmd_help() {
  echo "Usage: $(basename $0) <command> [options]"
  echo
  echo "Commands:"
  echo "  generate-migration SCHEMA_FILE MIGRATION_DIR - generate migration from unstaged schema"
  echo "  status SCHEMA_FILE MIGRATION_DIR             - sanity check"
  echo
}
