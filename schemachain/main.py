import sys
import re
import os
import subprocess
import time
import contextlib
import migra
import sqlbag
import git
import click
from typing import cast
from pglast.parser import fingerprint  # pylint: disable=no-name-in-module


@click.group()
def cli():
    pass


@cli.command()
@click.argument("schema_filename")
@click.argument("migration_dir")
def generate_migration(schema_filename, migration_dir):
    cmd_generate_migration(schema_filename, migration_dir)


@cli.command()
@click.argument("schema_filename")
def history(schema_filename):
    cmd_history(schema_filename)


MIGRATION_FILENAME_PATTERN = "^([0-9]+)_([a-z0-9]+)-([a-z0-9]+)\\.sql$"
PG_TMP_EXEC = os.path.dirname(os.path.abspath(__file__)) + "/pg_tmp"


def cmd_generate_migration(schema_filename, migration_dir):
    with open(schema_filename) as schema_file:
        current_schema_content = schema_file.read()
    current_schema_fingerprint = fingerprint(current_schema_content)
    last_migration_filename = get_last_migration_file(migration_dir)
    last_migration_fingerprint = (
        None
        if last_migration_filename is None
        else get_migration_target_fingerprint(last_migration_filename)
    )

    print(f"Schema file name: {schema_filename}")
    print(f"Migration directory: {migration_dir}")
    print(f"Current schema fingerprint: {current_schema_fingerprint}")
    print(f"Last migrated schema fingerprint: {last_migration_fingerprint or 'none'}")

    if current_schema_fingerprint == last_migration_fingerprint:
        print("Schema and last migration match, nothing to do.")
    else:
        if last_migration_filename is None:
            next_migration_filename = (
                f"{migration_dir}/000_none-{current_schema_fingerprint}.sql"
            )
            previous_schema_content = None
        else:
            next_migration_index = get_next_migration_index(migration_dir)
            next_migration_filename = f"{migration_dir}/{next_migration_index:03}_{last_migration_fingerprint}-{current_schema_fingerprint}.sql"  # pylint: disable=line-too-long
            previous_schema_content = get_schema_content_at_fingerprint(
                schema_filename, last_migration_fingerprint
            )

        next_migration_content = diff_schemas(
            previous_schema_content, current_schema_content
        )
        assert next_migration_content != None
        with open(next_migration_filename, "w") as next_migration_file:
            next_migration_file.write(next_migration_content)
        print(f"Generated migration {next_migration_filename}")


def get_migration_target_fingerprint(migration_file_name):
    result = re.match(MIGRATION_FILENAME_PATTERN, migration_file_name)
    if result:
        return result.group(3)
    else:
        raise Exception("Malformed migration file name")


def get_last_migration_file(migration_dir):
    migration_file_names = os.listdir(migration_dir)
    if len(migration_file_names) == 0:
        return None
    else:
        migration_file_names.sort()
        return migration_file_names[-1]


def get_next_migration_index(migration_dir):
    return 1 + max(
        [
            int(name.split("_")[0])
            for name in os.listdir(migration_dir)
            if re.match(MIGRATION_FILENAME_PATTERN, name)
        ]
    )


def get_schema_content_at_fingerprint(schema_filename, target_fingerprint):
    repo = git.Repo()
    commits_involving_schema = [
        line.split(" ")[1]
        for line in repo.git.log(schema_filename).split("\n")
        if re.match("^commit", line)
    ]
    for commit in commits_involving_schema:
        schema_content_at_commit = cast(
            str, repo.git.show(f"{commit}:{schema_filename}")
        )
        if fingerprint(schema_content_at_commit) == target_fingerprint:
            return schema_content_at_commit
    return None


def launch_pg_tmp():
    uri = subprocess.run(
        [PG_TMP_EXEC, "-w", "10"], stdout=subprocess.PIPE, check=True
    ).stdout.decode("utf-8")
    time.sleep(0.1)
    return uri


def diff_schemas(previous_schema_content, current_schema_content):
    with pg_tmp() as db_previous, pg_tmp() as db_current:
        if previous_schema_content is not None:
            db_previous.execute(previous_schema_content)
        db_current.execute(current_schema_content)
        schema_migration = migra.Migration(db_previous, db_current)
        schema_migration.set_safety(False)
        schema_migration.add_all_changes(privileges=True)
        if schema_migration.statements:
            sql = schema_migration.sql
            if not type(sql) is str:
                raise Exception(f"Type error: sql not a str")
            return cast(str, sql)
        return None


def cmd_history(schema_filename):
    pass


def get_schema_history(schema_filename):
    repo = git.Repo()
    return [
        {
            "commit": commit.hexsha,
            "fingerprint": fingerprint(repo.git.show(f"{commit}:{schema_filename}")),
            "message": commit.message,
        }
        for commit in repo.iter_commits("--all", paths=schema_filename)
    ]


@contextlib.contextmanager
def pg_tmp():
    pg_uri = launch_pg_tmp()
    with sqlbag.S(pg_uri) as pg_conn:
        yield pg_conn
