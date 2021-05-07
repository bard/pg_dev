# -*- mode: sh -*-

source ./test/common.bash

# TODO: @test 'generate-migration refuses to run outside of a git repository' 

@test '[cmd] generate-migration displays information about current/last schema and last migration' {
  git init
  mkdir migrations 
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql

  NO_START_PG=1 run cmd_generate_migration_new schema.sql migrations
  test $status -eq 0
  echo "$output" | grep --fixed-strings "Schema file name: schema.sql"
  echo "$output" | grep --fixed-strings "Migration directory: migrations"
  echo "$output" | grep --fixed-strings "Current schema fingerprint: 628c46f278dd3da2"
  echo "$output" | grep --fixed-strings "Last migrated schema fingerprint: none"
  echo "$output" | grep --fixed-strings "Last migrated schema commit: none"
}

@test '[cmd] generate-migration does nothing when current schema already matches last migration' {
  git init
  mkdir migrations

  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql
  touch migrations/000_none-628c46f278dd3da2.sql  
  NO_START_PG=1 run cmd_generate_migration_new schema.sql migrations
  test $status -eq 0
  echo "$output" | grep --fixed-strings "Schema and last migration match, nothing to do."
}

@test '[cmd] generate-migration produces first migration when none present [dry run]' {
  git init
  mkdir migrations
  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql

  NO_START_PG=1 run cmd_generate_migration_new schema.sql migrations
  test $status -eq 0
  echo "$output" | grep --fixed-strings "Last migrated schema fingerprint: none"

  test -f migrations/000_none-628c46f278dd3da2.sql
}

@test '[cmd] generate-migration produces first migration when none present' {
  git init
  mkdir migrations
  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql

  run cmd_generate_migration_new schema.sql migrations
  test $status -eq 0

  test -f migrations/000_none-628c46f278dd3da2.sql
}

@test '[cmd] generate-migration produces migration from last migrated schema to current schema [dryrun]' {
  mkdir migrations
  git init
  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql
  git add schema.sql
  git commit -m.

  NO_START_PG=1 run cmd_generate_migration_new schema.sql migrations
  test -f migrations/000_none-628c46f278dd3da2.sql

  echo 'CREATE TABLE widgets (id INTEGER, name TEXT);' >>schema.sql
  git add schema.sql
  git commit -m.

  echo 'CREATE TABLE vehicles (id INTEGER, name TEXT);' >>schema.sql
  git add schema.sql
  git commit -m.

  NO_START_PG=1 run cmd_generate_migration_new schema.sql migrations
  test $status -eq 0
  test -f migrations/001_628c46f278dd3da2-376ef48bf0288477.sql
}

@test '[cmd] generate-migration produces migration from last migrated schema to current schema' {
  mkdir migrations
  git init
  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql
  git add schema.sql
  git commit -m.

  run cmd_generate_migration_new schema.sql migrations
  test -f migrations/000_none-628c46f278dd3da2.sql

  echo 'CREATE TABLE widgets (id INTEGER, name TEXT);' >>schema.sql
  git add schema.sql
  git commit -m.

  echo 'CREATE TABLE vehicles (id INTEGER, name TEXT);' >>schema.sql
  git add schema.sql
  git commit -m.

  run cmd_generate_migration_new schema.sql migrations
  echo "$output"
  test $status -eq 0
  test -f migrations/001_628c46f278dd3da2-376ef48bf0288477.sql
}

