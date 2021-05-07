
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

function cat_schema_version_with_fingerprint() {
  local SCHEMA_FILE
  local TARGET_FINGERPRINT
  local FINGERPRINT_AT_COMMIT
  local TARGET_COMMIT
  SCHEMA_FILE="$1"
  TARGET_FINGERPRINT="$2"

  git log -- "$SCHEMA_FILE" | grep ^commit | cut -d' ' -f2 | while read COMMIT; do
    FINGERPRINT_AT_COMMIT=$(git show "${COMMIT}:${SCHEMA_FILE}" | fingerprint_schema)
    if [ "$FINGERPRINT_AT_COMMIT" = "$TARGET_FINGERPRINT" ]; then
      TARGET_COMMIT="$COMMIT"
      break
    fi
  done

  if [ -n "$TARGET_COMMIT" ]; then
    return 1
  else
    git show "${COMMIT}:${SCHEMA_FILE}"
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


function get_next_migration_index {
  local MIGRATION_DIRECTORY
  local LAST_INDEX
  MIGRATION_DIRECTORY="$1"
  LAST_INDEX=$(find "$MIGRATION_DIRECTORY" -maxdepth 1 -printf '%f\n'  | grep -Po '^\d+(?=_)' | get_max_number)
  echo $((10#$LAST_INDEX + 1))
}

function get_migration_target_fingerprint {
  local MIGRATION_FILENAME
  MIGRATION_FILENAME="$1"
  echo $MIGRATION_FILENAME | grep -Po '(?<=-)[0-9a-f]+(?=\.sql$)' 
}

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
