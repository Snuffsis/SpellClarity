"""Offline tests of package contents, release gates and one-attempt delivery."""
import copy
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile
import publish
import release


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.info = release.source({})

    def event(self, tag='v0.2.0-beta.1'):
        path = self.directory / 'event.json'
        event = {'action': 'published', 'release': {'draft': False,
                 'prerelease': True, 'tag_name': tag,
                 'body': 'Reviewed notes with `code` and $(literal).'}}
        path.write_text(json.dumps(event), encoding='utf-8')
        env = {'GITHUB_EVENT_NAME': 'release', 'GITHUB_EVENT_PATH': str(path),
               'GITHUB_REF': 'refs/tags/' + tag, 'GITHUB_SHA': 'abc123',
               'GITHUB_RUN_ATTEMPT': '1', 'CURSEFORGE_PUBLISH_ENABLED': 'true'}
        return env, event, path

    def test_one_independent_folder_and_no_development_files(self):
        files = release.bundle_files(self.info['packages'])
        self.assertEqual(set(self.info['packages']), {'SpellClarity'})
        self.assertIn('SpellClarity/SpellClarity.toc', files)
        self.assertFalse(any('/dev/' in n or '/.git' in n or '/SavedVariables/' in n for n in files))
        self.assertNotIn(b'Dependencies:', files['SpellClarity/SpellClarity.toc'])
        self.assertIn(b'## SavedVariables: SpellClarityDB', files['SpellClarity/SpellClarity.toc'])

    def test_packaged_runtime_loads_the_actual_toc_without_aevum(self):
        root = self.directory / 'SpellClarity'
        root.mkdir()
        for name, content in self.info['packages']['SpellClarity'].items():
            (root / name).write_bytes(content)
        (root / 'dev').mkdir()
        for name in ('test.lua', 'spellclarity_test.lua'):
            shutil.copyfile(release.ROOT / 'dev' / name, root / 'dev' / name)
        executable = shutil.which('lua5.1') or shutil.which('luajit')
        command = ([executable, 'dev/test.lua'] if executable else
                   [sys.executable, '-c', 'from lupa.lua51 import LuaRuntime; LuaRuntime().execute(\'dofile("dev/test.lua")\')'])
        subprocess.run(command, cwd=root, check=True, capture_output=True)

    def test_build_and_verify_are_deterministic(self):
        release.build(self.directory, {})
        info, data = release.verified_artifacts(self.directory, {})
        self.assertEqual(data, release.package(info['packages']))
        release.build(self.directory, {})
        self.assertEqual(data, release.verified_artifacts(self.directory, {})[1])

    def test_tampered_extra_missing_and_duplicate_zip_members_rejected(self):
        original = release.bundle_files(self.info['packages'])
        toc = 'SpellClarity/SpellClarity.toc'
        cases = [dict(original, **{toc: b'tampered'}),
                 dict(original, **{'SpellClarity/dev/secret.txt': b'extra'}),
                 {n: b for n, b in original.items() if n != toc}]
        for files in cases:
            with self.subTest(files=len(files)):
                buffer = io.BytesIO()
                with zipfile.ZipFile(buffer, 'w') as archive:
                    for name, data in files.items():
                        archive.writestr(name, data)
                with self.assertRaises(ValueError):
                    release.verify_package(buffer.getvalue(), self.info['packages'])
        buffer = io.BytesIO(release.package(self.info['packages']))
        with zipfile.ZipFile(buffer, 'a') as archive:
            import warnings
            with warnings.catch_warnings():
                warnings.simplefilter('ignore', UserWarning)
                archive.writestr(toc, original[toc])
        with self.assertRaises(ValueError):
            release.verify_package(buffer.getvalue(), self.info['packages'])

    def test_wrong_revision_and_checksum_reports_rejected(self):
        for field, value in (('commit', 'other'), ('sha256', 'wrong'), ('version', '9.9.9')):
            release.build(self.directory, {})
            path = self.directory / 'build.json'
            report = json.loads(path.read_text())
            report[field] = value
            path.write_text(json.dumps(report))
            with self.assertRaises(ValueError):
                release.verified_artifacts(self.directory, {})
        release.build(self.directory, {})
        (self.directory / 'SHA256SUMS').write_text('incorrect')
        with self.assertRaises(ValueError):
            release.verified_artifacts(self.directory, {})

    def test_stale_archives_are_rejected(self):
        (self.directory / 'Other.zip').write_bytes(b'old')
        with self.assertRaisesRegex(ValueError, 'Stale'):
            release.build(self.directory, {})

    def test_release_tag_and_notes_change_only_package(self):
        env, event, _ = self.event()
        original = (release.ROOT / 'SpellClarity.toc').read_bytes()
        info = release.source(env)
        self.assertEqual(info['version'], '0.2.0-beta.1')
        self.assertIn(b'## Version: 0.2.0-beta.1', info['packages']['SpellClarity']['SpellClarity.toc'])
        self.assertIn(event['release']['body'].encode(), info['packages']['SpellClarity']['CHANGELOG.md'])
        self.assertEqual((release.ROOT / 'SpellClarity.toc').read_bytes(), original)
        for name in ('Bootstrap.lua', 'Format.lua', 'SpellData.lua', 'SpellDetails.lua', 'Main.lua'):
            self.assertEqual(info['packages']['SpellClarity'][name], (release.ROOT / name).read_bytes())

    def test_draft_wrong_channel_empty_notes_and_non_release_rejected(self):
        for field, value in (('draft', True), ('prerelease', False), ('body', ''), ('tag_name', '../bad')):
            env, event, path = self.event()
            event['release'][field] = value
            path.write_text(json.dumps(event))
            with self.assertRaises(ValueError):
                release.release_event(env)
        env, _, _ = self.event()
        for event_name in ('push', 'pull_request', 'workflow_dispatch'):
            with self.assertRaises(ValueError):
                release.release_event(dict(env, GITHUB_EVENT_NAME=event_name))

    def test_lightweight_or_annotated_tag_names_and_stable_channel(self):
        for tag in ('0.2.0-beta.1', 'v0.2.0-beta.1'):
            env, _, _ = self.event(tag)
            self.assertEqual(release.release_event(env)[0], '0.2.0-beta.1')
        env, event, path = self.event('v0.2.0')
        event['release']['prerelease'] = False
        path.write_text(json.dumps(event))
        self.assertEqual(release.source(env)['channel'], 'release')

    def test_project_id_injected_only_in_package(self):
        config = copy.deepcopy(self.info['config'])
        config['project'] = {'id': 123, 'slug': 'spellclarity-test'}
        with patch.object(release, 'settings', return_value=config):
            info = release.source({})
        self.assertIn(b'## X-Curse-Project-ID: 123', info['packages']['SpellClarity']['SpellClarity.toc'])
        self.assertNotIn(b'X-Curse-Project-ID', (release.ROOT / 'SpellClarity.toc').read_bytes())

    def test_disabled_unconfigured_and_retry_publication_rejected(self):
        env, _, _ = self.event()
        with self.assertRaisesRegex(ValueError, 'enable publication'):
            release.publication_preflight(dict(env, CURSEFORGE_PUBLISH_ENABLED='false'))
        with self.assertRaisesRegex(ValueError, 'Re-upload blocked'):
            release.publication_preflight(dict(env, GITHUB_RUN_ATTEMPT='2'))
        config = copy.deepcopy(self.info['config'])
        config['project'] = {'id': None, 'slug': None}
        with patch.object(release, 'read_json', return_value=config):
            with self.assertRaisesRegex(ValueError, 'Fill in CurseForge'):
                release.settings(publishing=True)

    def test_missing_license_blocks_publication(self):
        env, _, _ = self.event()
        with patch.object(release, 'settings'), patch.object(release, 'ROOT', self.directory):
            with self.assertRaisesRegex(ValueError, 'LICENSE'):
                release.publication_preflight(env)

    def test_release_must_match_tested_commit_and_be_on_master(self):
        env, _, _ = self.event()
        info = dict(self.info, version='0.2.0-beta.1')
        (self.directory / 'LICENSE').write_text('Test fixture license')
        with patch.object(release, 'settings'), patch.object(release, 'ROOT', self.directory), \
             patch.object(release, 'verified_artifacts', return_value=(info, b'archive')):
            with patch.object(release, 'git', side_effect=['abc123', 'wrong']):
                with self.assertRaisesRegex(ValueError, 'tested commit'):
                    release.publication_preflight(env)
            with patch.object(release, 'git', return_value='abc123'), \
                 patch.object(release.subprocess, 'run') as run:
                self.assertEqual(release.publication_preflight(env), (info, b'archive'))
                run.assert_called_once_with(['git', 'merge-base', '--is-ancestor', 'abc123', 'origin/master'],
                                            cwd=self.directory, check=True)
                run.side_effect = subprocess.CalledProcessError(1, 'git')
                with self.assertRaises(subprocess.CalledProcessError):
                    release.publication_preflight(env)

    def upload_info(self):
        info = copy.deepcopy(self.info)
        info['config']['project'] = {'id': 123, 'slug': 'spellclarity-test'}
        return info

    def test_upload_uses_exact_archive_and_records_receipt(self):
        info, data = self.upload_info(), b'EXACT-VERIFIED-ZIP'
        receipt = self.directory / 'receipt.json'
        requests = []

        def reply(request, opener):
            requests.append(request)
            if request.get_method() == 'GET':
                return info['config']['game_versions']
            self.assertEqual(json.loads(receipt.read_text())['status'], 'unconfirmed; inspect CurseForge before retrying')
            self.assertIn(data, request.data)
            self.assertTrue(request.full_url.endswith('/projects/123/upload-file'))
            return {'id': 456}

        with patch.object(publish, 'request_json', side_effect=reply):
            publish.deliver(info, data, 'test-only', receipt)
        result = json.loads(receipt.read_text())
        self.assertEqual(result['file_id'], 456)
        self.assertEqual(result['sha256'], release.digest(data))
        self.assertEqual(len(requests), 2)

    def test_timeout_is_not_retried_and_existing_receipt_blocks_post(self):
        info, receipt = self.upload_info(), self.directory / 'receipt.json'
        with patch.object(publish, 'request_json', side_effect=[info['config']['game_versions'], ValueError('uncertain')]) as request:
            with self.assertRaisesRegex(ValueError, 'uncertain'):
                publish.deliver(info, b'zip', 'test-only', receipt)
            self.assertEqual(request.call_count, 2)
        self.assertIn('unconfirmed', json.loads(receipt.read_text())['status'])
        with patch.object(publish, 'request_json', return_value=info['config']['game_versions']) as request:
            with self.assertRaisesRegex(ValueError, 'Existing upload receipt'):
                publish.deliver(info, b'zip', 'test-only', receipt)
            self.assertEqual(request.call_count, 1)

    def test_wrong_live_game_version_prevents_post(self):
        with patch.object(publish, 'request_json', return_value=[]) as request:
            with self.assertRaisesRegex(ValueError, 'game version'):
                publish.deliver(self.upload_info(), b'zip', 'test-only', self.directory / 'receipt.json')
            self.assertEqual(request.call_count, 1)


if __name__ == '__main__':
    unittest.main()
