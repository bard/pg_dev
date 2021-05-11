
function dispatch_command() {
  if [ "$#" -eq 0 ]; then
    cmd_help
    exit 1
  fi
  
  COMMAND=$1
  case $COMMAND in
    "" | "-h" | "--help")
      cmd_help
      ;;
    check)
      shift
      cmd_check "$@"
      ;;
    generate-migration-old)
      shift
      cmd_generate_migration_old "$@"
      ;;
    generate-migration)
      shift
      cmd_generate_migration "$@"
      ;;
    status)
      shift
      cmd_status "$@"
      ;;
    *)
      echo "Error: command '$COMMAND' not recognized." >&2
      echo "Run '$(basename $0) --help' for a list of commands." >&2
      exit 1
      ;;
  esac
}

