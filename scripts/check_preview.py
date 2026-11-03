#!/usr/bin/env python3
"""Check the committed offline browser simulator without installing dependencies."""
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
preview = ROOT / "preview" / "KS_Afflictions_Browser_Preview.html"
html = preview.read_text(encoding="utf8")
assert html.startswith("<!DOCTYPE html>") and "</html>" in html
for marker in (
    'id="styleSelect"', 'id="lethalSelect"', 'id="colorSelect"',
    'Modern KS', 'Classic WoW', 'Minimal',
    'function lethalWord(', 'function previewHud(', 'function renderWorld(',
    "style:'modern'", "lethalMode:'dies'", "dotColor:'purple'",
    'OFFLINE TESTBED',
):
    assert marker in html, f"Missing browser UI/simulation contract: {marker}"

parts = html.split("<script>")
assert len(parts) == 2, "Expected one inline JavaScript block"
script = parts[1].split("</script>", 1)[0]
node = shutil.which("node")
if node:
    with tempfile.TemporaryDirectory() as tmp:
        check = Path(tmp) / "koolsupport-preview-check.js"
        check.write_text(script, encoding="utf8")
        subprocess.run([node, "--check", str(check)], check=True)
    print("PASS browser preview HTML contract and JavaScript syntax")
else:
    print("WARNING Node.js not installed; HTML contract passed, JS syntax not checked")
