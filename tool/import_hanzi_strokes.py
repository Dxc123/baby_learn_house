"""Download only the fixed teaching corpus, preserving upstream license and hashes."""
import concurrent.futures
import hashlib
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVISION = '68d10a4b21150cae5e1ebbd223eed289cf32d90c'
BASE = f'https://raw.githubusercontent.com/chanind/hanzi-writer-data/{REVISION}'

def download(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()

def main():
    target = ROOT / 'assets/strokes'
    target.mkdir(parents=True, exist_ok=True)
    licenses = ROOT / 'assets/licenses'
    licenses.mkdir(parents=True, exist_ok=True)
    license_bytes = download(BASE + '/ARPHICPL.TXT')
    (licenses / 'ARPHICPL.TXT').write_bytes(license_bytes)
    corpus = json.loads((ROOT / 'tool/content_sources/hanzi.json').read_text())['items']
    def fetch(item):
        char = item['text']
        url = BASE + '/data/' + urllib.parse.quote(char) + '.json'
        content = download(url)
        data = json.loads(content)
        assert len(data['strokes']) == len(data['medians']) == item['strokes'], (char, len(data['strokes']), item['strokes'])
        path = f'assets/strokes/{ord(char):x}.json'
        (ROOT / path).write_bytes(content)
        return dict(character=char, asset=path, sha256=hashlib.sha256(content).hexdigest(), source=url)
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        entries = list(pool.map(fetch, corpus))
    manifest = dict(revision=REVISION, license='assets/licenses/ARPHICPL.TXT',
                    licenseSha256=hashlib.sha256(license_bytes).hexdigest(),
                    reviewStatus='automated structural validation; teaching review pending', entries=entries)
    (target / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
    print('Imported 60 stroke files from', REVISION)

if __name__ == '__main__':
    main()
