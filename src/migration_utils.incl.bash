
function get_max_number() {
  sort --numeric-sort --reverse | head -1
}

function get_next_migration_index {
  local MIGRATION_DIRECTORY
  local LAST_INDEX
  MIGRATION_DIRECTORY="$1"
  LAST_INDEX=$(find "$MIGRATION_DIRECTORY" -maxdepth 1 -printf '%f\n'  | grep -Po '^\d+(?=_)' | get_max_number)
  echo $((LAST_INDEX + 1))
}

