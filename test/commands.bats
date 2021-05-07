# -*- mode: sh -*-

source ./test/common.bash

@test 'can report status' {
  mkdir migrations
  git init
  echo 'CREATE TABLE users (id INTEGER, name TEXT);' >schema.sql

  run cmd_status schema.sql migrations
  echo $output grep --fixed-strings 'Schema file schema.sql present in work tree but absent from git'
  test $status -eq 1

  touch migrations/001_none-628c46f278dd3da2.sql
  git add schema.sql migrations/001_none-628c46f278dd3da2.sql
  git commit -m.
  
  run cmd_status schema.sql migrations
  echo $output | grep --fixed-strings 'Schema working copy and last committed schema match.'
  test $status -eq 0

  echo 'CREATE TABLE users (id INTEGER, name TEXT, phone TEXT);' >schema.sql
  run cmd_status schema.sql migrations
  echo $output | grep --fixed-strings 'Schema working copy differs from last committed schema'
  echo $output | grep --fixed-strings 'Last migration does not cover latest changes. Remember to'
  test $status -eq 1
}

