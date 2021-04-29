function does_file_exist_in_history() {
  local FILE=$1
  git ls-files --error-unmatch $FILE >/dev/null 2>&1
}
