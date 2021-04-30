
function get_last_migration_file() {
  local MIGRATION_DIRECTORY
  MIGRATION_DIRECTORY="$1"
  ls -1 "$MIGRATION_DIRECTORY" | tail -1
}

function does_file_exist_in_history() {
  local FILE=$1
  git ls-files --error-unmatch $FILE >/dev/null 2>&1
}

function does_repo_have_commits() {
  test "$(git rev-parse HEAD 2>/dev/null)" != "HEAD"
}

function does_file_have_changes() {
  local FILE
  FILE=$1
  if git diff --exit-code $FILE >/dev/null; then
    return 1
  else
    return 0
  fi
}

function read_last_committed_version() {
  local FILE
  local COMMIT
  FILE=$1

  if ! does_file_exist_in_history "$FILE"; then
    return 1
  fi

  COMMIT=$(git rev-list -1 HEAD "$FILE")
  git show "${COMMIT}:${FILE}"
}
