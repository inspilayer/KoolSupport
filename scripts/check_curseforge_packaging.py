#!/usr/bin/env python3
"""Verify the real CurseForge packager produces ONE KoolSupport addon directory."""
from pathlib import Path
import argparse
import zipfile

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = ROOT / '.pkgmeta'
MODULES = ('KSMacros', 'KSSupportSessions', 'KSStealth',
           'KSAfflictions', 'KSCampfireChat', 'KSThreat')

def fields(text):
    current = None
    result = {}
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if not line.startswith((' ', '\t')):
            current = None
            key, sep, value = line.partition(':')
            assert sep, f'Malformed top-level YAML: {line}'
            key, value = key.strip(), value.strip()
            result[key] = value if value else []
            if not value:
                current = key
        else:
            assert current, f'Unexpected indentation: {line}'
            raw = line.strip()
            if raw.startswith('- '):
                result[current].append(raw[2:].strip())
            else:
                key, sep, value = raw.partition(':')
                assert sep, f'Malformed mapping entry: {line}'
                result[current].append((key.strip(), value.strip()))
    return result

def mapping():
    expected = {
        f'KoolSupport/{p.relative_to(ROOT / "addons" / "KoolSupport").as_posix()}'
        for p in (ROOT / 'addons' / 'KoolSupport').rglob('*') if p.is_file()
    }
    for module in MODULES:
        expected.update(
            f'KoolSupport/Modules/{module}/{p.relative_to(ROOT / "addons" / module).as_posix()}'
            for p in (ROOT / 'addons' / module).rglob('*')
            if p.is_file() and p.name != module + '.toc'
        )
    return expected

def validate_meta():
    meta = fields(PACKAGE.read_text(encoding='utf-8'))
    assert meta['package-as'] == 'KoolSupport'
    assert meta['enable-nolib-creation'] == 'no'
    assert meta['license-output'] == 'LICENSE'
    expected_moves = {'KoolSupport/addons/KoolSupport': 'KoolSupport'}
    expected_moves.update({
        f'KoolSupport/addons/{name}': f'KoolSupport/Modules/{name}'
        for name in MODULES
    })
    assert dict(meta['move-folders']) == expected_moves, (
        'Each optional module must be nested under ONE KoolSupport root'
    )
    ignored = set(meta['ignore'])
    assert {'docs', 'tests', 'scripts', 'preview', 'legacy', '.github', 'README.md'}.issubset(ignored)
    for module in MODULES:
        assert f'addons/{module}/{module}.toc' in ignored, 'Do not ship nested independent addon manifests'
        assert f'addons/{module}' not in ignored, 'Do not omit a bundled module'
    assert (ROOT / 'LICENSE').is_file()
    assert (ROOT / 'addons' / 'KSAfflictions' / 'Vendor' / 'LICENSE').is_file()
    assert (ROOT / 'addons' / 'KSAfflictions' / 'Vendor' / 'NOTICE.md').is_file()
    print('PASS CurseForge .pkgmeta: one KoolSupport root with six nested modules')

def validate_zip(path):
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, 'Corrupt package'
        names = {name for name in archive.namelist() if not name.endswith('/')}
    expected = mapping()
    extras = names - expected
    allowed_extras = {'KoolSupport/LICENSE', 'KoolSupport/CHANGELOG.md'}
    assert expected.issubset(names), f'Missing packaged files: {sorted(expected - names)}'
    assert extras.issubset(allowed_extras), f'Unexpected packager extras: {sorted(extras)}'
    assert {n.split('/', 1)[0] for n in names} == {'KoolSupport'}, 'Only one AddOns root is permitted'
    assert 'KoolSupport/KoolSupport.toc' in names
    for module in MODULES:
        assert any(n.startswith(f'KoolSupport/Modules/{module}/') for n in names)
        assert f'KoolSupport/Modules/{module}/{module}.toc' not in names
    assert 'KoolSupport/Modules/KSAfflictions/Vendor/LICENSE' in names
    assert 'KoolSupport/Modules/KSAfflictions/Vendor/NOTICE.md' in names
    assert not any('/addons/' in n or n.startswith(('addons/', 'docs/', 'tests/')) for n in names)
    print(f'PASS CurseForge dry run: {len(names)} files under one installable KoolSupport folder')
    print(path)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--built-zip', help='Real packager output ZIP')
    args = parser.parse_args()
    validate_meta()
    if args.built_zip:
        validate_zip(Path(args.built_zip))
