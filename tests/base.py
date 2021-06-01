import io
import git
import os
import shutil
import sys
import tempfile
import unittest
import git


class BaseTestCase(unittest.TestCase):
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
