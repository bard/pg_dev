#!/bin/bash
set -ue

TEST_FILES_ARGS=()
for f in "$@"
do
  TEST_FILES_ARGS+=(-f "$f")
done

export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-postgres}"
export PGHOST="${PGHOST:-127.0.0.1}"
export PGOPTIONS="${PGOPTIONS:---client-min-messages=warning}"

psql -f - \
     -f schema.sql \
     "${TEST_FILES_ARGS[@]}" \
     -c 'SELECT * FROM runtests()' <<EOF
-- Adapted from https://pgtap.org/documentation.html#pgtaptestscripts

-- Turn off echo and keep things quiet.
\unset ECHO
\set QUIET 1

-- Always begin from a blank slate, so that the outcome of every
-- test run is only dependent on test files, never on the previous
-- state of the database.
DROP DATABASE
  IF EXISTS test;

CREATE DATABASE test;

\c test

-- Load TAP
CREATE EXTENSION pgtap;

-- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager off

-- Revert all changes on failure.
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true

EOF
