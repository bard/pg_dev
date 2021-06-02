import os
import git
import pytest


@pytest.fixture(name="repo")
def fixture_repo(tmp_path):
    os.chdir(tmp_path)
    os.mkdir("migrations")
    return git.Repo.init(tmp_path)


@pytest.fixture(name="repo_with_schema_commits")
def fixture_repo_with_schema_commits(repo):
    write_schema_and_commit(
        repo, "CREATE TABLE users (id INTEGER, name TEXT);\n", msg="initial import"
    )
    write_schema_and_commit(
        repo,
        """
    CREATE TABLE users (id INTEGER, name TEXT);
    CREATE TABLE widgets (id INTEGER, name TEXT);
    """,
        msg="add widgets",
    )
    write_schema_and_commit(
        repo,
        """
    CREATE TABLE users (id INTEGER, name TEXT);
    CREATE TABLE widgets (id INTEGER, name TEXT);
    CREATE TABLE vehicles (id INTEGER, name TEXT);
    """,
        msg="add vehicles",
    )
    return repo


def write_schema_and_commit(repo, sql, msg="[no msg]"):
    with open("schema.sql", "w") as file:
        file.write(sql)
    repo.index.add(["schema.sql"])
    repo.index.commit(msg)
