import pytest
from pg_dev.main import (
    pg_tmp,
    pg_tmp_docker,
    get_migration_target_fingerprint,
    get_last_migration_file,
    get_next_migration_index,
    get_schema_content_at_fingerprint,
)


def test_pg_tmp():
    with pg_tmp() as db_conn:
        result = db_conn.execute("SELECT 1;")
        assert result.all() == [(1,)]


def test_pg_tmp_docker():
    with pg_tmp_docker() as db_conn:
        result = db_conn.execute("SELECT 1;")
        assert result.all() == [(1,)]


def test_retrieve_name_of_last_migration_file(repo):
    open("migrations/004_none-abc123.sql", "w").close()
    open("migrations/005_abc123-def456.sql", "w").close()
    open("migrations/006_def456-ghi789.sql", "w").close()
    assert get_last_migration_file("migrations") == "006_def456-ghi789.sql"


def test_read_target_fingerprint_from_migration_filename(repo):
    assert get_migration_target_fingerprint("006_def456-ghi789.sql") == "ghi789"


def test_get_next_migration_index(repo):
    open("migrations/004_none-abc123.sql", "w").close()
    open("migrations/005_abc123-def456.sql", "w").close()
    open("migrations/006_def456-ghi789.sql", "w").close()
    assert get_next_migration_index("migrations") == 7


def test_get_schema_content_at_fingerprint(repo):
    with open("schema.sql", "w") as file:
        file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    with open("schema.sql", "a") as file:
        file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    with open("schema.sql", "a") as file:
        file.write("CREATE TABLE vehicles (id INTEGER, name TEXT);\n")
    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    first_schema_version = get_schema_content_at_fingerprint(
        "schema.sql", "628c46f278dd3da2"
    )
    assert first_schema_version is not None
    assert "users" in first_schema_version
    assert "widgets" not in first_schema_version
    assert "vehicles" not in first_schema_version
