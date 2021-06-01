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
        assert get_last_migration_file("migrations") == "006_def456-ghi789.sql"

    def test_read_target_fingerprint_from_migration_filename(self):
        assert get_migration_target_fingerprint("006_def456-ghi789.sql") == "ghi789"

    def test_get_next_migration_index(self):
        open("migrations/004_none-abc123.sql", "w").close()
        open("migrations/005_abc123-def456.sql", "w").close()
        open("migrations/006_def456-ghi789.sql", "w").close()
        assert get_next_migration_index("migrations") == 7

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
        assert "users" in first_schema_version
        assert "widgets" not in first_schema_version
        assert "vehicles" not in first_schema_version