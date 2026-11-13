#!/usr/bin/env python3
"""Validate unified KoolSupport source and build a SINGLE installable WoW addon."""
from pathlib import Path
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parent.parent
ADDONS = ROOT / 'addons'
VERSION = '0.10.10-rc.1'
# Source is separated for maintainability; distribution has one KoolSupport.toc.
MODULES = {
    'KSMacros': ['KoolSupport'],
    'KSSupportSessions': ['KoolSupport', 'KSMacros'],
    'KSStealth': ['KoolSupport'],
    'KSAfflictions': ['KoolSupport'],
    'KSCampfireChat': ['KoolSupport'],
    'KSThreat': ['KoolSupport'],
}

def entries(toc):
    """Read ordered Lua files from TOC. Comments/metadata are not file paths."""
    return [line.strip().replace('\\', '/')
            for line in toc.read_text(encoding='utf8').splitlines()
            if line.strip().lower().endswith('.lua') and
            not line.lstrip().startswith('#')]

def package_entries():
    """Source file -> final ZIP entry path, no nested loadable addon TOCs."""
    output = {}
    for file in sorted((ADDONS / 'KoolSupport').rglob('*')):
        if file.is_file():
            output[file] = 'KoolSupport/' + file.relative_to(ADDONS / 'KoolSupport').as_posix()
    for module in MODULES:
        for file in sorted((ADDONS / module).rglob('*')):
            if file.is_file() and file.name != module + '.toc':
                output[file] = 'KoolSupport/Modules/' + module + '/' + file.relative_to(ADDONS / module).as_posix()
    return output

def verify():
    base = ADDONS / 'KoolSupport' / 'KoolSupport.toc'
    body = base.read_text(encoding='utf8')
    assert '## Interface: 16001' in body
    assert '## Version: ' + VERSION in body
    assert '## SavedVariablesPerCharacter: KoolSupportDB' in body, 'Preserve existing character preferences'
    assert '## SavedVariables: KSAfflictionsTrackerDB' in body, 'Register the tracker in the new host addon'
    original_base = ['Core.lua', 'BarTheme.lua', 'Diagnostics.lua', 'UI.lua']
    expected = list(original_base)
    for module, deps in MODULES.items():
        toc = ADDONS / module / (module + '.toc')
        assert toc.is_file(), 'Missing source module manifest: ' + str(toc)
        txt = toc.read_text(encoding='utf8')
        assert '## Interface: 16001' in txt
        assert '## Version: ' + VERSION in txt
        expected_deps = re.search(r'^## Dependencies: (.*)$', txt, re.M)
        assert expected_deps and [x.strip() for x in expected_deps.group(1).split(',')] == deps
        src_entries = entries(toc)
        assert src_entries, 'Missing module scripts: ' + module
        expected += ['Modules/' + module + '/' + file for file in src_entries]
        for file in src_entries:
            assert (toc.parent / file).is_file(), 'Missing source script: ' + module + '/' + file
    actual = entries(base)
    assert actual == expected, 'Unified manifest is out of order or missing scripts'
    mapping = package_entries()
    packaged = set(mapping.values())
    assert len(mapping) == len(packaged), 'Duplicate package entries'
    for file in actual:
        assert 'KoolSupport/' + file in packaged, 'Manifest references absent package script: ' + file
    assert all(not name.endswith('/' + module + '.toc') for module in MODULES for name in packaged), 'Nested addons should not load'
    assert 'KS.VERSION = "' + VERSION + '"' in (ADDONS / 'KoolSupport' / 'Core.lua').read_text(encoding='utf8')
    for file in ADDONS.rglob('*.lua'):
        assert '\x00' not in file.read_text(encoding='utf8'), 'NUL in ' + str(file)
    assert 'KoolSupport/Modules/KSAfflictions/Vendor/LICENSE' in packaged
    assert 'KoolSupport/Modules/KSAfflictions/Vendor/NOTICE.md' in packaged
    tracker = (ADDONS / 'KSAfflictions' / 'Vendor' / 'Tracker.lua').read_text(encoding='utf8')
    assert 'KSAfflictionsTrackerDB' in tracker and 'SLASH_DOESITDIE1' not in tracker

    lua = shutil.which('lua5.4') or shutil.which('lua') or shutil.which('texlua')
    if lua:
        subprocess.run([lua, str(ROOT / 'scripts' / 'lua_syntax.lua'),
                        *[str(p) for p in sorted(ADDONS.rglob('*.lua'))]], cwd=ROOT, check=True)
        for test in sorted((ROOT / 'tests').glob('test_*.lua')):
            subprocess.run([lua, str(test)], cwd=ROOT, check=True)
        print('PASS Lua syntax and offline runtime tests')
    else:
        print('WARNING: Lua unavailable; syntax and runtime tests skipped')

def zip_unified(name):
    dest = ROOT / 'dist' / (name + '_' + VERSION + '.zip')
    dest.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as archive:
        for src, entry in package_entries().items():
            archive.write(src, entry)
    verify_unified_package(dest)
    print('Created', dest)
    return dest

def verify_unified_package(path):
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, 'Corrupt ZIP'
        names = {name for name in archive.namelist() if not name.endswith('/')}
    assert names == set(package_entries().values()), 'Missing or unexpected package entries'
    assert {name.split('/')[0] for name in names} == {'KoolSupport'}, 'Must install ONE root addon folder'
    assert 'KoolSupport/KoolSupport.toc' in names
    assert 'KoolSupport/Modules/KSAfflictions/Vendor/LICENSE' in names
    assert 'KoolSupport/Modules/KSAfflictions/Vendor/NOTICE.md' in names
    print('PASS one KoolSupport root, six source modules nested, MIT notice retained')

def package():
    zip_unified('KoolSupport_CurseForge_Standard')
    zip_unified('KoolSupport_All_Modules_Development')

if __name__ == '__main__':
    verify()
    if '--package' in sys.argv:
        package()
