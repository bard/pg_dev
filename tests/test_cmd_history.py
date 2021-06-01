import sys
import re
from schemachain.main import cmd_history, get_schema_history
from .base import BaseTestCase


class ViewSchemaHistoryTestCase(BaseTestCase):
    def write_schema_and_commit(self, sql, msg="[no msg]"):
        with open("schema.sql", "w") as file:
            file.write(sql)
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(msg)

    def test_cmd_history(self):
        pass

    def test_get_schema_history(self):
        self.write_schema_and_commit(
            "CREATE TABLE users (id INTEGER, name TEXT);\n", msg="initial import"
        )
        self.write_schema_and_commit(
            """
        CREATE TABLE users (id INTEGER, name TEXT);
        CREATE TABLE widgets (id INTEGER, name TEXT);
        """,
            msg="add widgets",
        )
        self.write_schema_and_commit(
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
                "commit": pytest_regex("^[a-f0-9]{40}$"),
                "message": "add vehicles",
            },
            {
                "fingerprint": "1cdda8b9f32e428b",
                "commit": pytest_regex("^[a-f0-9]{40}$"),
                "message": "add widgets",
            },
            {
                "fingerprint": "628c46f278dd3da2",
                "commit": pytest_regex("^[a-f0-9]{40}$"),
                "message": "initial import",
            },
        ]


class pytest_regex:
    """Assert that a given string meets some expectations."""

    def __init__(self, pattern, flags=0):
        self._regex = re.compile(pattern, flags)

    def __eq__(self, actual):
        return bool(self._regex.match(actual))

    def __repr__(self):
        return self._regex.pattern
