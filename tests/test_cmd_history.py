import re
from pg_dev.main import cmd_history, get_schema_history


def test_cmd_history(repo_with_schema_commits, capsys):
    cmd_history("schema.sql")
    out, _ = capsys.readouterr()

    assert re.findall(r"376ef48bf0288477\s+add vehicles\s+[a-f0-9]{40}", out)
    assert re.findall(r"1cdda8b9f32e428b\s+add widgets\s+[a-f0-9]{40}", out)
    assert re.findall(r"628c46f278dd3da2\s+initial import\s+[a-f0-9]{40}", out)


def test_get_schema_history(repo_with_schema_commits):
    assert get_schema_history(repo_with_schema_commits, "schema.sql") == [
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
