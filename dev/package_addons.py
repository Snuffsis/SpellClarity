"""Allowlist the independent addon; never ship development files or saved data."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ('Bootstrap.lua', 'Locale.lua', 'Format.lua', 'SpellData.lua',
           'SpellDetails.lua', 'NativeTooltips.lua', 'Main.lua')


def package_entries(folder=ROOT, name='SpellClarity'):
    if folder != ROOT or name != 'SpellClarity':
        raise ValueError('Only the independent SpellClarity addon may be packaged')
    names = ['SpellClarity.toc', *RUNTIME, 'README.md', 'README-sv.md',
             'UPSTREAM.md', 'spell-data-sources.json']
    if (ROOT / 'LICENSE').is_file():
        names.append('LICENSE')
    return {name: ROOT / name for name in names}


def validate_sources():
    toc = (ROOT / 'SpellClarity.toc').read_text(encoding='utf-8')
    entries = tuple(line.strip() for line in toc.splitlines()
                    if line.strip() and not line.startswith('#'))
    if entries != RUNTIME:
        raise ValueError('TOC load order differs from the reviewed runtime allowlist')
    if re.search(r'^## (?:Dependencies|RequiredDeps|OptionalDeps):', toc, re.M):
        raise ValueError('SpellClarity must remain independent')
    if re.findall(r'^## SavedVariables: (.+)$', toc, re.M) != ['SpellClarityDB']:
        raise ValueError('Preserve SpellClarityDB ownership')
    for name, path in package_entries().items():
        if not path.is_file() or path.is_symlink() or not path.resolve().is_relative_to(ROOT.resolve()):
            raise ValueError('Missing or unsafe package file: ' + name)
    provenance = json.loads((ROOT / 'spell-data-sources.json').read_text(encoding='utf-8'))
    if provenance.get('build') != '1.60.1.70338' or provenance.get('spells') != 6372:
        raise ValueError('Review data and runtime build gates together before changing support')
