# -*- mode: sh -*-

source ./test/common.bash

@test 'status command stops when schema does not exist in work tree' {
  mkdir migrations
  git init

  run cmd_status schema.sql migrations
  echo "$output" | grep --fixed-strings 'File does not exist or cannot be read: schema.sql'
  test $status -eq 1
}

@test 'status command detects when schema is not in git' {
  mkdir migrations
  git init
  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql
  
  run cmd_status schema.sql migrations
  echo "$output" | grep --fixed-strings 'Schema file schema.sql present in work tree but absent from git'
  test $status -eq 1
}

@test 'status command detects when working copy has no corresponding migration' {
  mkdir migrations
  git init
  
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql
  touch migrations/001_none-628c46f278dd3da2.sql
  git add schema.sql migrations/001_none-628c46f278dd3da2.sql
  git commit -m.
  
  run cmd_status schema.sql migrations
  echo "$output" | grep --fixed-strings 'Schema working copy and last committed schema match.'
  test $status -eq 0
}
