"""Build and verify one independent SpellClarity ZIP."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile
from package_addons import ROOT, package_entries, validate_sources

ADDONS = ('SpellClarity',)
VERSION = re.compile(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-(alpha|beta)(?:\.(0|[1-9][0-9]*))?)?')
ARTIFACTS = ROOT / 'dist/release'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def settings(publishing=False):
    config = read_json(ROOT / 'release/config.json')
    require(set(config) == {'project', 'game_versions'}, 'Configure one CurseForge project for the SpellClarity bundle')
    project = config['project']
    require(isinstance(project, dict) and set(project) == {'id', 'slug'}, 'Configure the SpellClarity project id and slug')
    identity, slug = project['id'], project['slug']
    require(identity is None or (type(identity) is int and identity > 0), 'Invalid SpellClarity project ID')
    require(slug is None or (isinstance(slug, str) and re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', slug)),
            'Invalid CurseForge slug')
    if publishing:
        require(identity is not None and slug is not None, 'Fill in CurseForge id and slug for SpellClarity')
    versions = config['game_versions']
    require(isinstance(versions, list) and versions, 'Configure supported CurseForge game versions')
    for version in versions:
        require(type(version.get('id')) is int and version['id'] > 0 and
                isinstance(version.get('name'), str) and version['name'].strip() and
                type(version.get('interface')) is int and version['interface'] > 0,
                'Invalid game version mapping')
    require(len({v['id'] for v in versions}) == len(versions), 'Duplicate game version IDs')
    return config


def release_event(env):
    require(env.get('GITHUB_EVENT_NAME') == 'release', 'Only a published GitHub Release may upload')
    event = read_json(Path(env['GITHUB_EVENT_PATH']))
    published = event.get('release', {})
    require(event.get('action') == 'published' and published.get('draft') is False, 'Release must be published')
    tag = published.get('tag_name', '')
    require(isinstance(tag, str), 'Invalid release tag')
    version = tag[1:] if tag.startswith('v') else tag
    match = VERSION.fullmatch(version)
    require(match is not None, 'Unsupported release tag version')
    require(env.get('GITHUB_REF') == 'refs/tags/' + tag, 'Release event tag differs from workflow ref')
    require(published.get('prerelease') is bool(match.group(4)),
            'Mark alpha/beta releases as pre-release; stable releases must not be')
    notes = published.get('body')
    require(isinstance(notes, str) and notes.strip(), 'Write release notes before publishing')
    return version, notes.strip() + '\n'


def source(env=None):
    env = os.environ if env is None else env
    validate_sources()
    config = settings()
    toc = (ROOT / 'SpellClarity.toc').read_text(encoding='utf-8')
    version = re.findall(r'^## Version: (\S+)$', toc, re.M)
    require(len(version) == 1 and VERSION.fullmatch(version[0]), 'Unsupported source version')
    source_version = version[0]
    version, notes = (release_event(env) if env.get('GITHUB_EVENT_NAME') == 'release'
                      else (source_version, 'Unpublished validation build.\n'))
    packages = {}
    for name in ADDONS:
        folder = ROOT
        paths = package_entries(folder, name)
        contents = {}
        for relative, path in paths.items():
            require(not path.is_symlink() and path.resolve().is_relative_to(ROOT.resolve()), f'Unsafe source file: {relative}')
            contents[relative] = path.read_bytes()
        toc_name = name + '.toc'
        toc_text = contents[toc_name].decode('utf-8')
        interfaces = re.findall(r'^## Interface: ([0-9]+)$', toc_text, re.M)
        require(len(interfaces) == 1 and all(str(v['interface']) == interfaces[0] for v in config['game_versions']),
                f'Game mapping and Interface differ: {name}')
        require(re.findall(r'^## Version: (\S+)$', toc_text, re.M) == [source_version], f'Version differs: {name}')
        project_id = config['project']['id']
        # Release versions and CurseForge IDs belong to the delivered copies.
        # The source TOC retains its development version.
        toc_text = re.sub(r'^## Version: .*$', '## Version: ' + version, toc_text, flags=re.M)
        toc_text = re.sub(r'^## X-Curse-Project-ID:.*\n?', '', toc_text, flags=re.M)
        if project_id is not None:
            toc_text = f'## X-Curse-Project-ID: {project_id}\n' + toc_text
        contents[toc_name] = toc_text.encode('utf-8')
        contents['CHANGELOG.md'] = (f'# {name} {version}\n\n' + notes).encode('utf-8')
        packages[name] = contents
    return {'version': version, 'channel': VERSION.fullmatch(version).group(4) or 'release',
            'config': config, 'notes': notes, 'packages': packages}


def bundle_files(packages):
    return {name + '/' + relative: content
            for name, files in packages.items() for relative, content in files.items()}


def package(packages):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for relative, content in sorted(bundle_files(packages).items()):
            entry = zipfile.ZipInfo(relative, date_time=(1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(entry, content)
    return buffer.getvalue()


def verify_package(data, packages):
    expected = bundle_files(packages)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        require(len(archive.infolist()) == len(expected) and set(archive.namelist()) == set(expected),
                'Missing, duplicate or unexpected bundle files')
        for entry in archive.infolist():
            require(entry.file_size == len(expected[entry.filename]) and
                    archive.read(entry) == expected[entry.filename], f'ZIP content differs: {entry.filename}')


def build(output=ARTIFACTS, env=None):
    info = source(env)
    require(set(info['packages']) == set(ADDONS), 'Bundle must contain only SpellClarity')
    output.mkdir(parents=True, exist_ok=True)
    filename = f'SpellClarity-{info["version"]}.zip'
    require(not any(p.name != filename for p in output.glob('*.zip')),
            'Stale/unexpected ZIPs; choose a clean release output directory')
    data = package(info['packages'])
    verify_package(data, info['packages'])
    report = {'commit': git('rev-parse', 'HEAD'), 'version': info['version'], 'channel': info['channel'],
              'addons': list(ADDONS), 'file': filename, 'sha256': digest(data)}
    (output / filename).write_bytes(data)
    (output / 'build.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
    (output / 'SHA256SUMS').write_text(f'{report["sha256"]}  {filename}\n', encoding='utf-8', newline='\n')
    print(f'Built and verified one SpellClarity ZIP with {len(ADDONS)} addon folders in {output}')


def verified_artifacts(output=ARTIFACTS, env=None):
    info = source(env)
    report = read_json(output / 'build.json')
    require(report.get('commit') == git('rev-parse', 'HEAD') and report.get('version') == info['version'] and
            report.get('channel') == info['channel'] and report.get('addons') == list(ADDONS),
            'Artifact report belongs to another revision/version or is incomplete')
    require(set(info['packages']) == set(ADDONS), 'Bundle must contain only SpellClarity')
    filename = f'SpellClarity-{info["version"]}.zip'
    require(report.get('file') == filename, 'Unexpected artifact filename')
    require({p.name for p in output.glob('*.zip')} == {filename}, 'Missing or unexpected artifact ZIPs')
    data = (output / filename).read_bytes()
    require(digest(data) == report.get('sha256'), 'Artifact checksum differs')
    require((output / 'SHA256SUMS').read_text(encoding='utf-8') == f'{digest(data)}  {filename}\n',
            'Artifact checksum listing differs')
    verify_package(data, info['packages'])
    return info, data


def publication_preflight(env, output=ARTIFACTS):
    require(env.get('CURSEFORGE_PUBLISH_ENABLED', '').lower() == 'true', 'Set CURSEFORGE_PUBLISH_ENABLED=true to enable publication')
    require(env.get('GITHUB_RUN_ATTEMPT') == '1', 'Re-upload blocked: inspect the previous receipt and CurseForge before recovery')
    settings(publishing=True)
    require((ROOT / 'LICENSE').is_file(), 'Owner must choose and add a distribution LICENSE before publication')
    require((ROOT / 'LICENSE').read_text(encoding='utf-8').strip(), 'Distribution LICENSE is empty')
    info, data = verified_artifacts(output, env)
    version, _ = release_event(env)
    require(version == info['version'], 'Release version differs from the verified artifacts')
    head = git('rev-parse', 'HEAD')
    ref = env['GITHUB_REF']
    require(git('rev-parse', ref + '^{commit}') == head == env.get('GITHUB_SHA'), 'Release tag must point at the tested commit')
    subprocess.run(['git', 'merge-base', '--is-ancestor', head, 'origin/master'], cwd=ROOT, check=True)
    return info, data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify', action='store_true', help='Verify previously built/downloaded artifacts')
    args = parser.parse_args()
    if args.verify:
        verified_artifacts()
        print('All artifact checksums, revision and packaged files verified.')
    else:
        build()
