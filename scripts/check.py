#!/usr/bin/env python3
"""Package modular dev addon and check manifests and Lua syntax where Lua exists."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'addons'
MANIFESTS = [BASE/'KoolSupport'/'KoolSupport.toc', BASE/'KSMacros'/'KSMacros.toc']

def verify():
    for toc in MANIFESTS:
        assert toc.is_file(), f'Missing manifest: {toc}'
        text = toc.read_text(encoding='utf-8')
        assert '## Interface: 16001' in text
        assert '## Version: 0.7.0-dev' in text
        if toc.parent.name == 'KSMacros':
            assert '## Dependencies: KoolSupport' in text
        for line in text.splitlines():
            line = line.strip()
            if line.endswith('.lua') and not line.startswith('#'):
                assert (toc.parent / line).is_file(), f'Missing source file: {line}'
    for source in BASE.rglob('*.lua'):
        data = source.read_text(encoding='utf-8')
        assert '\x00' not in data
    lua = shutil.which('lua') or shutil.which('lua5.4')
    if lua:
        for path in sorted(BASE.rglob('*.lua')):
            cmd = [lua, '-e', 'assert(loadfile(arg[1]))', str(path)]
            subprocess.run(cmd, cwd=ROOT, check=True)
        for path in sorted((ROOT / 'tests').glob('test_*.lua')):
            subprocess.run([lua, str(path.relative_to(ROOT))], cwd=ROOT, check=True)
        print('PASS Lua syntax and runtime tests')
    else:
        print('WARNING: Lua interpreter unavailable; manifest/source checks only')

def package():
    dest = ROOT / 'dist' / 'KoolSupport_Modular_Base_0.7.0-dev.zip'
    dest.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(BASE.rglob('*')):
            if path.is_file():
                z.write(path, path.relative_to(BASE).as_posix())
    print(f'Created {dest}')

if __name__ == '__main__':
    verify()
    if '--package' in sys.argv: package()
