## An experimental source-centric, TDD-friendly SQL schema development workflow for Postgres

Development usually flows from _sources_ to _live_: code, compile, test, commit, push, deploy. Source files are what you look at to know the state of development.

With SQL development, however, it's not uncommon to start with _live_ (scribbling code in a database admin interface), and end up with migration files that we may call "sources" but really are opaque _targets_.

This makes it harder to reason about code, work in tight feedback loops and controlled environments (as allowed by TDD), and guard against regressions (lacking the unit tests resulting from TDD\*\*.

**`pg_dev` facilitates a source-centric workflow for (Postgre)SQL**, where the schema's source is a first-class citizen in the repository — you can view, edit, and test it like any other source — and migrations are automatically derived from schema changes.

**This is alpha software.**

## How it works

1. You write a `schema.sql` file.

2. Optionally (but ideally), you write tests using [pg_tap](https://pgtap.org/) and a file watcher sends schema and tests to a pristine Postgres environment on every change.

3. Once happy, you run `pg_dev generate-migration`, and `pg_dev` looks through git history for the last known schema, diffs it against the current one, and saves the resulting migration.

## Installation

```sh
$ python -m pip install https://github.com/bard/pg_dev/archive/master.tar.gz
```

## Tutorial

Create a git repository:

```sh
$ mkdir example
$ cd example
$ git init
```

Create `schema.sql`:

```sql
CREATE TABLE users (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name TEXT NOT NULL
);
```

Create the migrations directory and generate the first migration:

```sh
$ mkdir migrations
$ pg_dev generate-migration schema.sql migrations
Schema file name: schema.sql
Migration directory: migrations
Current schema fingerprint: 7676866d0a1a57cb
Last migrated schema fingerprint: none
Generated migration migrations/000_none-7676866d0a1a57cb.sql
```

Add schema and migration to the repository and commit (there is no requirement to do these together, it just makes life easier for those looking at commit log later):

```sh
$ git add schema.sql migrations/000_none-7676866d0a1a57cb.sql
$ git commit -m 'add database schema'
```

Make a change to the schema:

```diff
  CREATE TABLE users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
+   address TEXT NOT NULL,
    name TEXT NOT NULL
  );
```

Generate the next migration:

```sh
$ pg_dev generate-migration schema.sql migrations
Schema file name: schema.sql
Migration directory: migrations
Current schema fingerprint: 293a4f7b996ccceb
Last migrated schema fingerprint: 7676866d0a1a57cb
Last migrated schema commit: 4b095f75a874739a4f6cfc71e92dd61ba0cf75e8
Generated migration migrations/001_7676866d0a1a57cb-293a4f7b996ccceb.sql
```

Add commit changes:

```sh
$ git add schema.sql migrations/001_7676866d0a1a57cb-293a4f7b996ccceb.sql
$ git commit -m 'add address column'
```

Inspect the schema history so far:

```sh
$ pg_dev history schema.sql
fingerprint       commit message       commit hash
----------------  -------------------  ----------------------------------------
293a4f7b996ccceb  add address column   cb3f41c51be0f5a4b72b4b70985ad438e172cb09
7676866d0a1a57cb  add database schema  4b095f75a874739a4f6cfc71e92dd61ba0cf75e8
```

## Q&A

### Does `pg_dev` generate migrations also on non-functional changes such as formatting, comments, or order of columns?

No, `pg_dev` identifies schemas by finger-printing their _normalized_ versions, so those changes won't cause a migration.

### Does `pg_dev` manage data migration?

`pg_dev` only deals with DDL, however, you can manually extend migrations to account for data if desired.

### How do I use this for TDD?

Future versions of `pg_dev` will support watching files and running tests against an internally managed [ephemeral Postgres instance](https://eradman.com/ephemeralpg/) or Postgres Docker image, or an external arbitrary Postgres instance.

For now, you'll have to provide a running Postgres instance, ensure it has access to the `pg_tap` extension (on Debian-based systems, install the `postgresql-13-pgtap` package), and run the provided [examples/run-test.sh](./examples/tdd/run-test.sh) script under a file watcher such as [watchexec](https://github.com/watchexec/watchexec).

For a complete worked example:

```sh
$ cd examples/tdd
$ docker-compose up -d # starts postgres+pgtap in container
$ watchexec -w schema.sql -w tests "./run-tests.sh tests/*"
```

Then edit `schema.sql` or files under `tests/`.

### Can I use any Postgres-supported SQL in defining a schema?

The current diff engine, [migra](https://github.com/djrobstep/migra), has good coverage of DDL constructs with a few notable [exceptions](https://databaseci.com/docs/migra). In those cases, you'll have to fall back on editing migration files after generating them.

A future version of `pg_dev` might switch to the diff engine from [pgAdmin](https://www.pgadmin.org/), Postgres's official administration tool.

### Can I split my schema into multiple files and import them with `\i`?

Only a single schema file is supported at the moment.

# Caveats

Rewriting past versions of the schema file will change their fingerprint, making it impossible for `pg_dev` to do its work.

## Development

To run tests:

```sh
$ poetry run task test
```

## Resources

- [Overcoming First Principles — A guide for accessing the features of PostgreSQL in test-driven development](https://eradman.com/talks/overcoming_first_principles/)
