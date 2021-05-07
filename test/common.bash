
setup() {
  WORKDIR=$(mktemp -d -t schemachain-test_XXXXXXXXXX)
  cd $WORKDIR
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd)"
  echo $PROJECT_ROOT
  source $PROJECT_ROOT/src/util.incl.bash
  source $PROJECT_ROOT/src/repo.incl.bash
  source $PROJECT_ROOT/src/postgres.incl.bash
  source $PROJECT_ROOT/src/cmd_help.incl.bash
  source $PROJECT_ROOT/src/cmd_status.incl.bash
  source $PROJECT_ROOT/src/cmd_generate_migration_new.incl.bash
}

teardown() {
  rm -rf $WORKDIR
}
