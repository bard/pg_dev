import os
from schemachain.main import (
    cmd_generate_migration,
)
from .base import BaseTestCase


class CmdGenerateMigrationsTestCase(BaseTestCase):
    def test_display_status_information(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")

        cmd_generate_migration("schema.sql", "migrations")

        assert "Schema file name: schema.sql" in self.stdout.getvalue()
        assert "Migration directory: migrations" in self.stdout.getvalue()
        assert "Current schema fingerprint: 628c46f278dd3da2" in self.stdout.getvalue()
        assert "Last migrated schema fingerprint: none" in self.stdout.getvalue()

    def test_generate_first_migration_when_none_present(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")

        cmd_generate_migration("schema.sql", "migrations")

        assert "Current schema fingerprint: 628c46f278dd3da2" in self.stdout.getvalue()
        assert "Last migrated schema fingerprint: none" in self.stdout.getvalue()
        assert os.path.exists("migrations/000_none-628c46f278dd3da2.sql")
        with open("migrations/000_none-628c46f278dd3da2.sql") as migration_file:
            migration_content = migration_file.read()
            assert 'create table "public"."users"' in migration_content

    def test_do_nothing_when_current_schema_already_matches_last_migration(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
        open("migrations/000_none-628c46f278dd3da2.sql", "w").close()

        cmd_generate_migration("schema.sql", "migrations")

        assert (
            "Schema and last migration match, nothing to do." in self.stdout.getvalue()
        )

    def test_produce_migration_from_last_migrated_schema_to_current_schema(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        cmd_generate_migration("schema.sql", "migrations")
        assert os.path.exists("migrations/000_none-628c46f278dd3da2.sql")

        with open("schema.sql", "a") as file:
            file.write("CREATE TABLE widgets (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        with open("schema.sql", "a") as file:
            file.write("CREATE TABLE vehicles (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        cmd_generate_migration("schema.sql", "migrations")
        assert os.path.exists("migrations/001_628c46f278dd3da2-376ef48bf0288477.sql")

    def test_generate_destructive_migrations(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        cmd_generate_migration("schema.sql", "migrations")
        assert os.path.exists("migrations/000_none-628c46f278dd3da2.sql")

        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        cmd_generate_migration("schema.sql", "migrations")
        assert "Schema file name: schema.sql" in self.stdout.getvalue()

        assert os.path.exists("migrations/001_628c46f278dd3da2-c0659d1fe44cd0ef.sql")

        with open("migrations/001_628c46f278dd3da2-c0659d1fe44cd0ef.sql") as f:
            assert 'alter table "public"."users" drop column "name";' in f.read()
