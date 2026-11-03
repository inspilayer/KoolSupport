#!/usr/bin/env python3
"""Fail closed if CurseForge's native packager would leak optional or development files.

Use without arguments to statically validate .pkgmeta. With --built-zip the
Packager dry-run output must be checked against actual addon source paths.
"""
from pathlib import Path
import argparse
import sys
import zipfile

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = ROOT / ".pkgmeta"

def fields(text):
    current = None
    result = {}
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line.startswith((" ", "\t")):
            current = None
            key, sep, value = line.partition(":")
            assert sep, f"Malformed top-level YAML: {line}"
            key, value = key.strip(), value.strip()
            result[key] = value if value else []
            if not value: current = key
        else:
            assert current, f"Unexpected indentation: {line}"
            raw = line.strip()
            if raw.startswith("- "):
                result[current].append(raw[2:].strip())
            else:
                key, sep, value = raw.partition(":")
                assert sep, f"Malformed mapping entry: {line}"
                result[current].append((key.strip(),value.strip()))
    return result

def validate_meta():
    meta = fields(PACKAGE.read_text(encoding="utf-8"))
    assert meta["package-as"] == "KoolSupport"
    assert meta["enable-nolib-creation"] == "no"
    assert meta["license-output"] == "LICENSE"
    assert dict(meta["move-folders"]) == {
        "KoolSupport/addons/KSMacros": "KSMacros",
        "KoolSupport/addons/KoolSupport": "KoolSupport",
    }, "Unexpected move-folders may break WoW installation"
    ignored = set(meta["ignore"])
    required = {
        "addons/KSSupportSessions", "addons/KSStealth", "addons/KSAfflictions",
        "docs", "tests", "scripts", "preview", "legacy", ".github", "README.md",
    }
    assert required.issubset(ignored), "Unsafe CurseForge package ignore rules"
    assert (ROOT / "LICENSE").is_file(), "No MIT license"
    print("PASS CurseForge .pkgmeta: only Base + Macros intended, no plugins or dev content")

def validate_zip(path):
    with zipfile.ZipFile(path) as package:
        assert package.testzip() is None, "Corrupt CurseForge ZIP"
        names = {n for n in package.namelist() if not n.endswith("/")}
    expected = {
        f"{name}/{p.relative_to(ROOT / 'addons' / name).as_posix()}"
        for name in ("KoolSupport", "KSMacros")
        for p in (ROOT / "addons" / name).rglob("*")
        if p.is_file()
    }
    assert expected.issubset(names), f"Missing addon source files: {sorted(expected - names)}"
    extra = names - expected
    assert extra.issubset({"KoolSupport/LICENSE", "KSMacros/LICENSE"}), (
        f"Unexpected packager files; could install junk: {sorted(extra)}"
    )
    assert not any("/addons/" in n or n.startswith(("addons/", "docs/", "tests/")) for n in names)
    print(f"PASS CurseForge packager dry run: {len(names)} files in 2 sibling addon directories")
    print(path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--built-zip",help="Path to actual packager-produced ZIP")
    args = parser.parse_args()
    validate_meta()
    if args.built_zip: validate_zip(Path(args.built_zip))
