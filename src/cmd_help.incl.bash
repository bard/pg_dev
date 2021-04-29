function cmd_help() {
  echo "Usage: $(basename $0) <command> [options]"
  echo
  echo "Commands:"
  echo "  check schema.sql    - check that schema matches latest migration"
  echo "  generate schema.sql - generate migration from unstaged schema"
  echo
}
