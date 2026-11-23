#!/usr/bin/env python3
"""Read the candidate or stable version from scripts/check.py without executing it.

Used by the publish-beta workflow to prevent a formatting change such as
VERSION = '0.10.14-rc.1' from silently producing an empty release tag.
"""
import ast
from pathlib import Path
import re
import sys

CHECKER = Path(__file__).resolve().with_name("check.py")
RELEASE_CANDIDATE = re.compile(r"(?:[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+|1\.0\.0)\Z")


def extract_version(source: str) -> str:
    """Extract exactly one static VERSION assignment from a Python source file."""
    tree = ast.parse(source)
    values = []
    for stmt in tree.body:
        if isinstance(stmt, ast.Assign) and any(
            isinstance(target, ast.Name) and target.id == "VERSION"
            for target in stmt.targets
        ):
            if not isinstance(stmt.value, ast.Constant) or not isinstance(stmt.value.value, str):
                raise ValueError("VERSION must be a plain quoted string")
            values.append(stmt.value.value)
    if len(values) != 1:
        raise ValueError(f"Expected exactly one VERSION assignment, found {len(values)}")
    version = values[0]
    if not RELEASE_CANDIDATE.fullmatch(version):
        raise ValueError(f"Not an approved candidate/stable version: {version!r}")
    return version


def main() -> int:
    try:
        version = extract_version(CHECKER.read_text(encoding="utf-8"))
    except (OSError, SyntaxError, ValueError) as exc:
        print(f"Release version validation failed: {exc}", file=sys.stderr)
        return 1
    print(version)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
