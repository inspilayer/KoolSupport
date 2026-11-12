#!/usr/bin/env python3
"""Validate the single-project CurseForge ZIP: all seven sibling WoW addon folders.

Run without arguments for static .pkgmeta validation. Pass --built-zip to
inspect the real packager output (CI uses BigWigsMods/packager@v2 -d).
"""
from pathlib import Path
import argparse
import zipfile

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = ROOT / ".pkgmeta"
ADDONS = ("KoolSupport", "KSMacros", "KSSupportSessions", "KSStealth", "KSAfflictions", "KSCampfireChat", "KSThreat")

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
            if not value:
                current = key
        else:
            assert current, f"Unexpected indentation: {line}"
            raw = line.strip()
            if raw.startswith("- "):
                result[current].append(raw[2:].strip())
            else:
                key, sep, value = raw.partition(":")
                assert sep, f"Malformed mapping entry: {line}"
                result[current].append((key.strip(), value.strip()))
    return result

def validate_meta():
    meta = fields(PACKAGE.read_text(encoding="utf-8"))
    assert meta["package-as"] == "KoolSupport"
    assert meta["enable-nolib-creation"] == "no"
    assert meta["license-output"] == "LICENSE"
    expected = {f"KoolSupport/addons/{name}": name for name in ADDONS}
    assert dict(meta["move-folders"]) == expected, (
        "All seven modules must be placed at sibling Interface/AddOns paths"
    )
    ignored = set(meta["ignore"])
    required = {"docs", "tests", "scripts", "preview", "legacy", ".github", "README.md"}
    assert required.issubset(ignored), "Development files could enter game package"
    assert not any(f"addons/{name}" in ignored for name in ADDONS), (
        "A bundled module must not be ignored"
    )
    assert (ROOT / "LICENSE").is_file(), "Missing project MIT license"
    vendor = ROOT / "addons" / "KSAfflictions" / "Vendor"
    assert (vendor / "LICENSE").is_file(), "Missing DoesItDie MIT license"
    assert (vendor / "NOTICE.md").is_file(), "Missing DoesItDie modification notice"
    print("PASS CurseForge .pkgmeta: single project, all 7 sibling modules, dev files excluded")

def validate_zip(path):
    with zipfile.ZipFile(path) as package:
        assert package.testzip() is None, "Corrupt CurseForge ZIP"
        names = {n for n in package.namelist() if not n.endswith("/")}
    expected = {
        f"{name}/{p.relative_to(ROOT / 'addons' / name).as_posix()}"
        for name in ADDONS
        for p in (ROOT / "addons" / name).rglob("*")
        if p.is_file()
    }
    assert expected.issubset(names), f"Missing addon source files: {sorted(expected - names)}"
    extras = names - expected
    permitted_extras = {f"{name}/LICENSE" for name in ADDONS}
    permitted_extras.add("KoolSupport/CHANGELOG.md")
    assert extras.issubset(permitted_extras), (
        f"Unexpected packager files or nested junk: {sorted(extras)}"
    )
    roots = {name.split("/", 1)[0] for name in names}
    assert roots == set(ADDONS), f"Incorrect AddOns roots: {sorted(roots)}"
    for name in ADDONS:
        assert f"{name}/{name}.toc" in names, f"Missing loadable addon manifest for {name}"
    assert "KSAfflictions/Vendor/LICENSE" in names
    assert "KSAfflictions/Vendor/NOTICE.md" in names
    assert not any("/addons/" in n or n.startswith(("addons/", "docs/", "tests/")) for n in names)
    print(f"PASS CurseForge packager dry run: {len(names)} files in 7 sibling addon directories")
    print(path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--built-zip", help="Path to actual CurseForge packager ZIP")
    args = parser.parse_args()
    validate_meta()
    if args.built_zip:
        validate_zip(Path(args.built_zip))
