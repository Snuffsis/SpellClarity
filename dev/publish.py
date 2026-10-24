"""Publish the verified SpellClarity bundle once. No automatic upload retries."""
import argparse
import json
import os
import urllib.error
import urllib.request
import uuid
from release import ARTIFACTS, digest, publication_preflight, require

API = 'https://wow.curseforge.com/api'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request_json(request, opener):
    try:
        with opener.open(request, timeout=60) as response:
            require(200 <= response.status < 300, 'CurseForge returned a non-success status')
            return json.loads(response.read())
    except urllib.error.HTTPError as error:
        raise ValueError(f'CurseForge HTTP {error.code}; no automatic retry made') from None
    except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError):
        raise ValueError('CurseForge response unconfirmed; inspect the project before retrying') from None


def metadata(info):
    return {'displayName': f'SpellClarity {info["version"]}', 'releaseType': info['channel'],
              'changelog': info['notes'], 'changelogType': 'markdown',
              'gameVersions': [v['id'] for v in info['config']['game_versions']]}


def upload_request(info, data, headers):
    boundary = 'SpellClarity' + uuid.uuid4().hex
    filename = f'SpellClarity-{info["version"]}.zip'
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n'
            'Content-Type: application/json\r\n\r\n').encode() + json.dumps(metadata(info)).encode() + (
            f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{filename}"\r\n'
            'Content-Type: application/zip\r\n\r\n').encode() + data + f'\r\n--{boundary}--\r\n'.encode()
    project = info['config']['project']['id']
    return urllib.request.Request(f'{API}/projects/{project}/upload-file', data=body, method='POST',
                                  headers={**headers, 'Content-Type': 'multipart/form-data; boundary=' + boundary})


def deliver(info, data, token, receipt_path, opener=None):
    require(isinstance(token, str) and bool(token.strip()), 'Missing CF_API_TOKEN repository secret')
    opener = opener or urllib.request.build_opener(NoRedirect())
    headers = {'X-Api-Token': token, 'User-Agent': 'SpellClarity-Release/1'}
    versions = request_json(urllib.request.Request(API + '/game/versions', headers=headers), opener)
    require(isinstance(versions, list), 'Unexpected CurseForge version list')
    for expected in info['config']['game_versions']:
        require(any(isinstance(v, dict) and v.get('id') == expected['id'] and v.get('name') == expected['name'] for v in versions),
                'Configured game version ID/name is not available on CurseForge')
    require(not receipt_path.exists(), 'Existing upload receipt: reconcile it before recovery')
    receipt = {'version': info['version'], 'project_id': info['config']['project']['id'],
               'sha256': digest(data), 'status': 'unconfirmed; inspect CurseForge before retrying'}

    def save():
        receipt_path.write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8', newline='\n')

    save()  # An interrupted POST must not be mistaken for an upload never attempted.
    result = request_json(upload_request(info, data, headers), opener)
    require(isinstance(result, dict) and type(result.get('id')) is int and result['id'] > 0,
            'Upload response has no file ID; inspect CurseForge before retrying')
    receipt.update(file_id=result['id'], status='uploaded; moderation pending')
    save()
    print(f'SpellClarity: uploaded bundle as CurseForge file {result["id"]}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--upload', action='store_true')
    args = parser.parse_args()
    try:
        info, data = publication_preflight(os.environ)
        if args.upload:
            deliver(info, data, os.environ.get('CF_API_TOKEN'), ARTIFACTS / 'curseforge-receipt.json')
        else:
            print('Publication preflight passed. No upload or network request performed.')
    except (ValueError, KeyError, FileNotFoundError) as error:
        raise SystemExit(str(error)) from None
