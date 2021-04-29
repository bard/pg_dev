function cmd_help() {
  echo "Usage: $(basename $0) <command> [options]"
  echo
  echo "Commands:"
  echo "  generate-migration SCHEMA_FILE MIGRATION_DIR - generate migration from unstaged schema"
  echo "  check schema.sql    - check that schema matches latest migration"
  echo
}
