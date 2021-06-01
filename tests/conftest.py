import os
import git
import pytest


@pytest.fixture(name="repo")
def fixture_repo(tmp_path):
    os.chdir(tmp_path)
    os.mkdir("migrations")
    return git.Repo.init(tmp_path)
