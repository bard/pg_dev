# -*- mode: sh -*-

source ./test/common.bash

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
  test "$(get_next_migration_index migrations)" = 5
  
  touch migrations/005_abc123-def456.sql
  touch migrations/006_def456-ghi789.sql
  test "$(get_next_migration_index migrations)" = 7
}

@test 'can get next index in a directory with bigger numbers' {
  mkdir migrations
  touch migrations/014_none-6dd578ee10c5d5e5.sql
  test "$(get_next_migration_index migrations)" = 15
}

@test 'can read target fingerprint from a migration filename' {
  test "$(get_migration_target_fingerprint 006_abc123-def456.sql)" = "def456"
}

@test 'can retrieve name of last migration file' {
  mkdir migrations
  touch migrations/004_none-abc123.sql
  touch migrations/005_abc123-def456.sql
  touch migrations/006_def456-ghi789.sql
  test "$(get_last_migration_file migrations)" = 006_def456-ghi789.sql
}

@test 'can check whether a file exists in git history' {
  git init
  does_file_exist_in_history foo.txt && false
  touch foo.txt
  git add foo.txt
  git commit -m.
  does_file_exist_in_history foo.txt && true
}

@test 'can read last committed version of a file' {
  git init
  run read_last_committed_version foo.txt
  test "$status" != 0
  
  echo hello >foo.txt
  git add foo.txt
  git commit -m.
  run read_last_committed_version foo.txt
  test "$output" = "hello"
}

@test 'can check whether a repo has any commits at all' {
  git init
  does_repo_have_commits && false
  touch foo.txt
  git add foo.txt
  git commit -m.
  does_repo_have_commits && true
}

@test 'can check whether file has uncommitted changes' {
  git init
  touch foo.txt
  git add foo.txt
  git commit -m.
  does_file_have_changes foo.txt && false
  echo bar >foo.txt
  does_file_have_changes foo.txt && true  
}

@test 'can fingerprint a schema' {
  SCHEMA1='CREATE TABLE users (id INTEGER, name TEXT);'
  test $(echo $SCHEMA1 | fingerprint_schema) = 628c46f278dd3da2

  SCHEMA2='create  table   users (  id INTEGER , name TEXT  );'
  test $(echo $SCHEMA1 | fingerprint_schema) = $(echo $SCHEMA2 | fingerprint_schema)
}

@test 'can detect whether schema is up to date' {
  mkdir migrations  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql
  
  run check_schema_up_to_date schema.sql migrations
  test $status -eq 1

  touch migrations/001_none-628c46f278dd3da2.sql
  run check_schema_up_to_date schema.sql migrations
  test $status -eq 0
}

@test 'can cat schema version from which a migration was created' {
  git init
  mkdir migrations
  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql
  touch migrations/001_none-628c46f278dd3da2.sql
  git add schema.sql migrations/*
  git commit -m.

  echo 'CREATE TABLE widgets (id INTEGER, name TEXT);' >>schema.sql
  git add schema.sql
  git commit -m.

  echo 'CREATE TABLE vehicles (id INTEGER, name TEXT);' >>schema.sql
  git add schema.sql
  git commit -m.

  run cat_schema_version_with_fingerprint schema.sql 628c46f278dd3da2
  test $status -eq 0
  echo "$output" | grep users
  if echo "$output" | grep widgets; then
    return 1
  fi
  if echo "$output" | grep vehicles; then
    return 1
  fi
}

