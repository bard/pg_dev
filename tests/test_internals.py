from schemachain.main import (
    get_migration_target_fingerprint,
    get_last_migration_file,
    get_next_migration_index,
    get_schema_content_at_fingerprint,
)
from .base import BaseTestCase


class InternalsTestCase(BaseTestCase):
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
        assert first_schema_version != None
        self.assertIn("users", first_schema_version)
        self.assertNotIn("widgets", first_schema_version)
        self.assertNotIn("vehicles", first_schema_version)
