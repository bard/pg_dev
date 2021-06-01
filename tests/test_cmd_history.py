import re
from pg_dev.main import cmd_history, get_schema_history


def write_schema_and_commit(repo, sql, msg="[no msg]"):
    with open("schema.sql", "w") as file:
        file.write(sql)
    repo.index.add(["schema.sql"])
    repo.index.commit(msg)


def test_cmd_history(repo):
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

    cmd_history("schema.sql")


def test_get_schema_history(repo):
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

    assert get_schema_history("schema.sql") == [
        {
            "fingerprint": "376ef48bf0288477",
            "commit": PytestRegex("^[a-f0-9]{40}$"),
            "message": "add vehicles",
        },
        {
            "fingerprint": "1cdda8b9f32e428b",
            "commit": PytestRegex("^[a-f0-9]{40}$"),
            "message": "add widgets",
        },
        {
            "fingerprint": "628c46f278dd3da2",
            "commit": PytestRegex("^[a-f0-9]{40}$"),
            "message": "initial import",
        },
    ]


class PytestRegex:
    """Assert that a given string meets some expectations."""

    def __init__(self, pattern, flags=0):
        self._regex = re.compile(pattern, flags)

    def __eq__(self, actual):
        return bool(self._regex.match(actual))

    def __repr__(self):
        return self._regex.pattern
