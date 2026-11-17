"""Regression tests for the version parser used in the Beta publishing workflow."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
PARSER = ROOT / "scripts" / "release_version.py"
SPEC = importlib.util.spec_from_file_location("release_version", PARSER)
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class ReleaseVersionTests(unittest.TestCase):
    def test_current_checkout_can_be_tagged(self):
        command = subprocess.run(
            [sys.executable, str(PARSER)], cwd=ROOT,
            check=True, capture_output=True, text=True
        )
        self.assertEqual(command.stdout.strip(), "0.10.14-rc.1")
        self.assertEqual(command.stderr, "")

    def test_spaces_and_both_quote_styles(self):
        for source in (
            "VERSION='0.10.14-rc.1'\n",
            "VERSION = '0.10.14-rc.1'\n",
            'VERSION = "0.10.14-rc.1"\n',
            "VERSION\t=\t'0.10.14-rc.1'\n",
        ):
            with self.subTest(source=source):
                self.assertEqual(module.extract_version(source), "0.10.14-rc.1")

    def test_reject_missing_duplicate_and_nonliteral_versions(self):
        for source in (
            "OTHER='0.10.14-rc.1'\n",
            "VERSION='0.10.14-rc.1'\nVERSION='0.10.14-rc.2'\n",
            "VERSION=get_version()\n",
            "VERSION='0.10.14'\n",
            "VERSION='v0.10.14-rc.1-beta'\n",
            "VERSION='0.10.14-rc.1; echo unsafe'\n",
        ):
            with self.subTest(source=source), self.assertRaises(ValueError):
                module.extract_version(source)


if __name__ == "__main__":
    unittest.main()
