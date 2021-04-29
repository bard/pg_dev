# -*- mode: sh -*-

setup() {
  WORKDIR=$(mktemp -d -t schemachain-test_XXXXXXXXXX)
  cd $WORKDIR
  mkdir migrations
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd)"
  echo $PROJECT_ROOT
  source $PROJECT_ROOT/src/get_next_migration_index.incl.bash
}

teardown() {
  rm -rf $WORKDIR
}

@test 'can get next index when migration files start from one' {
  touch migrations/001_none-abc123.sql
  touch migrations/002_abc123-def456.sql
  touch migrations/003_def456-ghi789.sql
  test "$(get_next_migration_index migrations)" = 4
}

@test 'can get next index when migration files start from index greater than one' {
  touch migrations/004_none-abc123.sql
  touch migrations/005_abc123-def456.sql
  touch migrations/006_def456-ghi789.sql
  test "$(get_next_migration_index migrations)" = 7
}
