import os
from pg_dev.main import (
    cmd_generate_migration,
)


def test_display_status_information(repo, capsys):
    with open("schema.sql", "w") as file:
        file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")

    cmd_generate_migration("schema.sql", "migrations")

    out, _ = capsys.readouterr()
    assert "Schema file name: schema.sql" in out
    assert "Migration directory: migrations" in out
    assert "Current schema fingerprint: 628c46f278dd3da2" in out
    assert "Last migrated schema fingerprint: none" in out


def test_generate_first_migration_when_none_present(repo, capsys):
    with open("schema.sql", "w") as file:
        file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")

    cmd_generate_migration("schema.sql", "migrations")

    out, _ = capsys.readouterr()
    assert "Current schema fingerprint: 628c46f278dd3da2" in out
    assert "Last migrated schema fingerprint: none" in out
    assert os.path.exists("migrations/000_none-628c46f278dd3da2.sql")
    with open("migrations/000_none-628c46f278dd3da2.sql") as migration_file:
        migration_content = migration_file.read()
        assert 'create table "public"."users"' in migration_content


def test_do_nothing_when_current_schema_already_matches_last_migration(repo, capsys):
    with open("schema.sql", "w") as file:
        file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
    open("migrations/000_none-628c46f278dd3da2.sql", "w").close()

    cmd_generate_migration("schema.sql", "migrations")

    out, _ = capsys.readouterr()
    assert "Schema and last migration match, nothing to do." in out


def test_produce_migration_from_last_migrated_schema_to_current_schema(repo, capsys):
    with open("schema.sql", "w") as file:
        file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    cmd_generate_migration("schema.sql", "migrations")
    assert os.path.exists("migrations/000_none-628c46f278dd3da2.sql")

    with open("schema.sql", "a") as file:
        file.write("CREATE TABLE widgets (id INTEGER, name TEXT);\n")
    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    with open("schema.sql", "a") as file:
        file.write(
            "CREATE TABLE vehicles (id INTEGER, name TEXT);\n"
        )  # pylint: disable=duplicate-code

    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    cmd_generate_migration("schema.sql", "migrations")
    assert os.path.exists("migrations/001_628c46f278dd3da2-376ef48bf0288477.sql")


def test_generate_destructive_migrations(repo, capsys):
    with open("schema.sql", "w") as file:
        file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    cmd_generate_migration("schema.sql", "migrations")
    assert os.path.exists("migrations/000_none-628c46f278dd3da2.sql")

    with open("schema.sql", "w") as file:
        file.write("CREATE TABLE users (id INTEGER);\n")
    repo.index.add(["schema.sql"])
    repo.index.commit(".")

    cmd_generate_migration("schema.sql", "migrations")

    out, _ = capsys.readouterr()

    assert "Schema file name: schema.sql" in out
    assert os.path.exists("migrations/001_628c46f278dd3da2-c0659d1fe44cd0ef.sql")
    with open("migrations/001_628c46f278dd3da2-c0659d1fe44cd0ef.sql") as file:
        assert 'alter table "public"."users" drop column "name";' in file.read()
