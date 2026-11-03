#!/usr/bin/env python3
"""Validate and package modular KoolSupport addons without shipping dev files."""
from pathlib import Path
import re
import shutil
import subprocess
import sys
import zipfile

ROOT=Path(__file__).resolve().parent.parent
ADDONS=ROOT/'addons'
VERSION='0.10.1-rc.1'
MANIFESTS={
 'KoolSupport': [],
 'KSMacros': ['KoolSupport'],
 'KSSupportSessions': ['KoolSupport','KSMacros'],
 'KSStealth': ['KoolSupport'],
 'KSAfflictions': ['KoolSupport'],
}

def verify():
    for name, deps in MANIFESTS.items():
        toc=ADDONS/name/(name+'.toc')
        assert toc.is_file(),f'Missing manifest: {toc}'
        text=toc.read_text(encoding='utf8')
        assert '## Interface: 16001' in text,f'Unexpected interface in {toc}'
        assert '## Version: '+VERSION in text,f'Unexpected version in {toc}'
        if deps:
            actual=re.search(r'^## Dependencies: (.*)$',text,re.M)
            assert actual and [x.strip() for x in actual.group(1).split(',')]==deps,(name,'dependencies')
        for row in text.splitlines():
            if row.endswith('.lua') and not row.startswith('#'):
                assert (toc.parent/row.strip()).is_file(),(toc,row)
    assert 'KS.VERSION = "'+VERSION+'"' in (ADDONS/'KoolSupport/Core.lua').read_text(encoding='utf8')
    for file in ADDONS.rglob('*.lua'):
        assert '\x00' not in file.read_text(encoding='utf8'),f'NUL in {file}'
    assert (ADDONS/'KSAfflictions/Vendor/LICENSE').is_file(), 'Missing upstream license'
    tracker=(ADDONS/'KSAfflictions/Vendor/Tracker.lua').read_text(encoding='utf8')
    assert 'KSAfflictionsTrackerDB' in tracker and 'SLASH_DOESITDIE1' not in tracker
    lua=shutil.which('lua5.4') or shutil.which('lua') or shutil.which('texlua')
    if lua:
        syntax=(ROOT/'scripts/lua_syntax.lua')
        subprocess.run([lua,str(syntax),*[str(p) for p in sorted(ADDONS.rglob('*.lua'))]],cwd=ROOT,check=True)
        for test in sorted((ROOT/'tests').glob('test_*.lua')):
            subprocess.run([lua,str(test)],cwd=ROOT,check=True)
        print('PASS Lua syntax and offline runtime tests')
    else:
        print('WARNING: Lua unavailable; syntax and runtime tests skipped')

def zip_addons(name,folders):
    dest=ROOT/'dist'/f'{name}_{VERSION}.zip'
    dest.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as z:
        for folder in folders:
            for f in sorted((ADDONS/folder).rglob('*')):
                if f.is_file():z.write(f,f.relative_to(ADDONS).as_posix())
    print('Created',dest)
    return dest

def verify_unified_package(path):
    """One CurseForge listing: all declared AddOns at the archive root."""
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, "Corrupt standard package"
        entries={n for n in archive.namelist() if not n.endswith('/')}
    roots={n.split('/',1)[0] for n in entries}
    assert roots==set(MANIFESTS), f'Unexpected roots in standard ZIP: {roots}'
    for name in MANIFESTS:
        assert f'{name}/{name}.toc' in entries, f'Missing {name} .toc'
    assert 'KSAfflictions/Vendor/LICENSE' in entries, 'DoT engine license not bundled'
    assert 'KSAfflictions/Vendor/NOTICE.md' in entries, 'DoT modification notice not bundled'
    print('PASS unified standard ZIP: five sibling addons and vendor notices')

def package():
    zip_addons('KoolSupport_Base_Macros',['KoolSupport','KSMacros'])
    standard=zip_addons('KoolSupport_CurseForge_Standard',list(MANIFESTS))
    verify_unified_package(standard)
    zip_addons('KSSupportSessions_Plugin',['KSSupportSessions'])
    zip_addons('KSStealth_Plugin',['KSStealth'])
    zip_addons('KSAfflictions_Plugin',['KSAfflictions'])
    zip_addons('KoolSupport_All_Modules_Development',['KoolSupport','KSMacros','KSSupportSessions','KSStealth','KSAfflictions'])

if __name__=='__main__':
    verify()
    if '--package' in sys.argv:package()
