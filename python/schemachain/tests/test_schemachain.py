import shutil
import tempfile
import io
import os
import sys
import unittest
import git
from schemachain.main import (
    cmd_generate_migration,
    get_migration_target_fingerprint,
    get_last_migration_file,
    get_next_migration_index,
    get_schema_content_at_fingerprint,
)


class CmdGenerateMigrationsTestCase(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.stdout = io.StringIO()
        sys.stdout = self.stdout
        os.chdir(self.test_dir)
        os.mkdir("migrations")
        self.repo = git.Repo.init(self.test_dir)

    def tearDown(self):
        shutil.rmtree(self.test_dir)
        sys.stdout = sys.__stdout__

    def test_display_status_information(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")

        cmd_generate_migration("schema.sql", "migrations")

        self.assertTrue("Schema file name: schema.sql" in self.stdout.getvalue())
        self.assertTrue("Migration directory: migrations" in self.stdout.getvalue())
        self.assertTrue(
            "Current schema fingerprint: 628c46f278dd3da2" in self.stdout.getvalue()
        )
        self.assertTrue(
            "Last migrated schema fingerprint: none" in self.stdout.getvalue()
        )

    def test_generate_first_migration_when_none_present(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")

        cmd_generate_migration("schema.sql", "migrations")

        self.assertTrue(
            "Current schema fingerprint: 628c46f278dd3da2" in self.stdout.getvalue()
        )
        self.assertTrue(
            "Last migrated schema fingerprint: none" in self.stdout.getvalue()
        )
        self.assertTrue(os.path.exists("migrations/000_none-628c46f278dd3da2.sql"))
        with open("migrations/000_none-628c46f278dd3da2.sql") as migration_file:
            migration_content = migration_file.read()
            self.assertTrue('create table "public"."users"' in migration_content)

    def test_do_nothing_when_current_schema_already_matches_last_migration(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
        open("migrations/000_none-628c46f278dd3da2.sql", "w").close()

        cmd_generate_migration("schema.sql", "migrations")

        self.assertTrue(
            "Schema and last migration match, nothing to do." in self.stdout.getvalue()
        )

    def test_produce_migration_from_last_migrated_schema_to_current_schema(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        cmd_generate_migration("schema.sql", "migrations")
        self.assertTrue(os.path.exists("migrations/000_none-628c46f278dd3da2.sql"))

        with open("schema.sql", "a") as file:
            file.write("CREATE TABLE widgets (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        with open("schema.sql", "a") as file:
            file.write("CREATE TABLE vehicles (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        cmd_generate_migration("schema.sql", "migrations")
        self.assertTrue(
            os.path.exists("migrations/001_628c46f278dd3da2-376ef48bf0288477.sql")
        )


class InternalsTestCase(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.stdout = io.StringIO()
        sys.stdout = self.stdout
        os.chdir(self.test_dir)
        os.mkdir("migrations")
        self.repo = git.Repo.init(self.test_dir)

    def tearDown(self):
        shutil.rmtree(self.test_dir)
        sys.stdout = sys.__stdout__

    def test_retrieve_name_of_last_migration_file(self):
        open("migrations/004_none-abc123.sql", "w").close()
        open("migrations/005_abc123-def456.sql", "w").close()
        open("migrations/006_def456-ghi789.sql", "w").close()
        self.assertEqual("006_def456-ghi789.sql", get_last_migration_file("migrations"))

    def test_read_target_fingerprint_from_migration_filename(self):
        self.assertEqual(
            "ghi789", get_migration_target_fingerprint("006_def456-ghi789.sql")
        )

    def test_get_next_migration_index(self):
        open("migrations/004_none-abc123.sql", "w").close()
        open("migrations/005_abc123-def456.sql", "w").close()
        open("migrations/006_def456-ghi789.sql", "w").close()
        self.assertEqual(7, get_next_migration_index("migrations"))

    def test_get_schema_content_at_fingerprint(self):
        with open("schema.sql", "w") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        with open("schema.sql", "a") as file:
            file.write("CREATE TABLE users (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        with open("schema.sql", "a") as file:
            file.write("CREATE TABLE vehicles (id INTEGER, name TEXT);\n")
        self.repo.index.add(["schema.sql"])
        self.repo.index.commit(".")

        first_schema_version = get_schema_content_at_fingerprint(
            "schema.sql", "628c46f278dd3da2"
        )
        self.assertTrue("users" in first_schema_version)
        self.assertFalse("widgets" in first_schema_version)
        self.assertFalse("vehicles" in first_schema_version)
