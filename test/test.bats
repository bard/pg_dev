# -*- mode: sh -*-

setup() {
  WORKDIR=$(mktemp -d -t schemachain-test_XXXXXXXXXX)
  cd $WORKDIR
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd)"
  echo $PROJECT_ROOT
  source $PROJECT_ROOT/src/migration_utils.incl.bash
  source $PROJECT_ROOT/src/repo_utils.incl.bash
  source $PROJECT_ROOT/src/schema_utils.incl.bash
}

teardown() {
  rm -rf $WORKDIR
}

@test 'can get next index when migration files start from one' {
  mkdir migrations
  touch migrations/001_none-abc123.sql
  touch migrations/002_abc123-def456.sql
  touch migrations/003_def456-ghi789.sql
  test "$(get_next_migration_index migrations)" = 4
}

@test 'can get next index when migration files start from index greater than one' {
  mkdir migrations
  touch migrations/004_none-abc123.sql
  touch migrations/005_abc123-def456.sql
  touch migrations/006_def456-ghi789.sql
  test "$(get_next_migration_index migrations)" = 7
}

@test 'can check whether a file exists in git history' {
  git init
  does_file_exist_in_history foo.txt || true
  touch foo.txt
  git add foo.txt
  git commit -m.
  does_file_exist_in_history foo.txt && true
}

@test 'can fingerprint a schema' {
  SCHEMA1='CREATE TABLE users (id INTEGER, name TEXT);'
  test $(echo $SCHEMA1 | fingerprint_schema) = 628c46f278dd3da2

  SCHEMA2='create  table   users (  id INTEGER , name TEXT  );'
  test $(echo $SCHEMA1 | fingerprint_schema) = $(echo $SCHEMA2 | fingerprint_schema)
}

