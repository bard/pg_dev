# An experimental git-centric workflow for better DX in Postgres schema development and migration management

## What is it

Migration-based schema evolution has some intrinsic issues (you're hand-rolling a version control system on top of another; you can't look at the latest schema without running a database) plus some that are a consequence of specific practices (if you use a tool to generate migrations by diff'ing the dev and prod databases, you have a source of truth that is outside of your repository).

While we're unlikely to ever be able to evolve databases like we evolve code — there's only so much we can do to change buildings (schemas) while people (data) are living in it — the experiment presented here aims at making schema evolution smoother and more reliable through a workflow that is:

- **transparent**: the latest schema is always available in the repository in plain SQL
- **schema-driven**: the developer modifies the schema and, when happy, a migration is generating automatically by diff'ing against the previous schema
- **git-centric** and **uni-directional**: repo is the source of truth, changes flow only from development to production, no runtime system needs to be queried to diff against previous schemas

## How it works

## Typical workflow

1. make changes to `schema_file.sql`
2. once you're happy, and before committing, run:

```sh
$ schemachain generate db/schema_file.sql db/migrations_dir
```

3. a `migrations_dir/nnn_sourcehash-desthash.sql` get screated; stage it and `schema_file.sql` and then commit

However, schemachain is only distributed as docker container, so that becomes:

```sh
$ docker run \
  --user "$(id -u):$(id -g)" -v /etc/passwd:/etc/passwd:ro -v $(pwd):/repo schemachain:latest \
  schemachain generate-migration db/schema_file.sql db/migrations_dir
```

As that's lengthy, you might want to place it in a `Makefile` target, `package.json` script, or equivalent, and invoke it with `make migrate`, `npx migrate`, etc.

Notes:

- `--user $(id -u):$(id -g)` and `-v /etc/passwd:/etc/passwd:ro` cause migrations to be created on the host permissions; you can omit them, but migrations will be created with root as owner; see also [Arbiratry --user Notes](https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes) for why mounting `/etc/passwd` is needed.
- `-v $(pwd)/repo` causes the current dir be mounted into the container, at the location where schemachain expects it.

## Adopting in an existing project

1. Dump the existing database schema:

```sh
pg_dump -U postgres -s --schema=public >schema.sql
```

2. Clean this file up. You might want to e.g. move constrain creation to `CREATE TABLE` statements. This will be the go-to place for all schema-related work.

3. Create a no-op migration that will only act as a checkpoint for the transition. For example, if migrations are stored in the `migrations` directory and the last migration is indexed at `13`:

```sh
$ docker run --rm schemachain generate-migration schema.sql migrations 14
```

This will generate `migrations/014_none-6dd578ee10c5d5e5.sql` file, meaning "migrating from no schema to schema 6dd578ee10c5d5e5".

5. Delete all content from `migrations/none_abcd1234-defg5678.sql`.

6. Commit the schema and the dummy migration.

## Troubleshooting
