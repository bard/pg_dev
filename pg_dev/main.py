import re
import os
import subprocess
import time
import contextlib
import tempfile
import shutil
from typing import cast
from tabulate import tabulate
import shortuuid
import migra
import psycopg2
import sqlbag
import git
import click
from pglast.parser import fingerprint  # pylint: disable=no-name-in-module


@click.group()
def cli():
    pass


@cli.command()
@click.argument("schema_filename")
@click.argument("migration_dir")
@click.option("--launcher", default="pg_tmp", help="Launcher (pg_tmp, docker).")
@click.option(
    "--docker-image", default="postgres:13", help="Image for docker launcher."
)
def generate_migration(schema_filename, migration_dir, **kwargs):
    cmd_generate_migration(schema_filename, migration_dir, **kwargs)


@cli.command()
@click.argument("schema_filename")
def history(schema_filename):
    cmd_history(schema_filename)


MIGRATION_FILENAME_PATTERN = "^([0-9]+)_([a-z0-9]+)-([a-z0-9]+)\\.sql$"
PG_TMP_EXEC = os.path.dirname(os.path.abspath(__file__)) + "/pg_tmp"


def cmd_generate_migration(schema_filename, migration_dir, **kwargs):
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
            previous_schema = get_schema_content_at_fingerprint(
                schema_filename, last_migration_fingerprint
            )
            if previous_schema is not None:
                previous_schema_content, commit = previous_schema
                print(f"Last migrated schema commit: {commit}")
            else:
                raise Exception(
                    f"Could not find a commit for schema with fingerprint {last_migration_fingerprint}"
                )

        next_migration_content = diff_schemas(
            previous_schema_content, current_schema_content, **kwargs
        )
        assert next_migration_content is not None
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
    repo = git.Repo(os.path.dirname(schema_filename), search_parent_directories=True)
    schema_repo_filename = os.path.relpath(schema_filename, repo.working_dir)
    commits_involving_schema = [
        line.split(" ")[1]
        for line in repo.git.log(schema_repo_filename).split("\n")
        if re.match("^commit", line)
    ]
    for commit in commits_involving_schema:
        schema_content_at_commit = cast(
            str, repo.git.show(f"{commit}:{schema_repo_filename}")
        )
        try:
            if fingerprint(schema_content_at_commit) == target_fingerprint:
                return schema_content_at_commit, commit
        except:
            pass
    return None


def diff_schemas(previous_schema_content, current_schema_content, **kwargs):
    with ephemeral_postgres(**kwargs) as db_previous, ephemeral_postgres(
        **kwargs
    ) as db_current:
        if previous_schema_content is not None:
            db_previous.execute(previous_schema_content)
        db_current.execute(current_schema_content)
        schema_migration = migra.Migration(db_previous, db_current)
        schema_migration.set_safety(False)
        schema_migration.add_all_changes(privileges=True)
        if schema_migration.statements:
            sql = schema_migration.sql
            if not isinstance(sql, str):
                raise Exception("Type error: sql not a str")
            return cast(str, sql)
        return None


def cmd_history(schema_filename):
    repo = git.Repo(os.path.dirname(schema_filename), search_parent_directories=True)
    data = [
        [entry["fingerprint"], entry["message"], entry["commit"]]
        for entry in get_schema_history(repo, schema_filename)
    ]
    print(tabulate(data, headers=["fingerprint", "commit message", "commit hash"]))


def get_schema_history(repo, schema_filename):
    return [
        {
            "commit": commit.hexsha,
            "fingerprint": fingerprint(repo.git.show(f"{commit}:{schema_filename}")),
            "message": commit.message,
        }
        for commit in repo.iter_commits("--all", paths=schema_filename)
    ]


@contextlib.contextmanager
def ephemeral_postgres(launcher="pg_tmp", docker_image="postgres:13"):
    if launcher == "pg_tmp":
        pg_uri = subprocess.run(
            [PG_TMP_EXEC, "-w", "10"], stdout=subprocess.PIPE, check=True
        ).stdout.decode("utf-8")
        with sqlbag.S(pg_uri) as pg_conn:
            yield pg_conn
            # https://dba.stackexchange.com/questions/221063/how-to-shutdown-postgres-through-psql
            pg_conn.execute(
                "COPY (SELECT 1) TO PROGRAM 'pg_ctl stop -m smart --no-wait';"
            )

    elif launcher == "docker":
        tmp_dir = os.path.join(tempfile.gettempdir(), "pg_dev-tmp")
        os.makedirs(tmp_dir, exist_ok=True)
        pg_dir = tempfile.mkdtemp(dir=tmp_dir)
        container_name = "postgres-pgdev-" + shortuuid.uuid()
        try:
            subprocess.run(
                [
                    "docker",
                    "run",
                    "--rm",
                    "--name",
                    container_name,
                    "--detach",
                    "-e",
                    "POSTGRES_USER=pgdev",
                    "-e",
                    "POSTGRES_PASSWORD=pgdev",
                    "--tmpfs",
                    "/var/lib/postgresql/data",
                    "-v",
                    f"{pg_dir}:/var/run/postgresql",
                    docker_image,
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            pg_uri = "postgresql://pgdev@/pgdev?host=" + pg_dir
            wait_for_postgres(pg_uri)
            with sqlbag.S(pg_uri) as pg_conn:
                yield pg_conn
        finally:
            subprocess.run(
                ["docker", "stop", container_name], stdout=subprocess.DEVNULL
            )


def wait_for_postgres(pg_uri):
    start_time = time.time()
    check_timeout = 30
    check_interval = 1
    while time.time() - start_time < check_timeout:
        try:
            conn = psycopg2.connect(pg_uri)
            conn.close()
            return True
        except psycopg2.OperationalError:
            time.sleep(check_interval)

    raise Exception("Postgres did not appear")
