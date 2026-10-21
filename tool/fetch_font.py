"""Fetch pinned official font in resumable HTTP ranges, verify the Git blob hash."""
import concurrent.futures
import hashlib
import json
import urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
URL='https://raw.githubusercontent.com/lxgw/LxgwWenKai/v1.530/fonts/TTF/LXGWWenKai-Regular.ttf'
SIZE=25928940
GIT_BLOB='7f8f031dc5c6c5ba1913d93c36d4667c1e311cea'

def main():
    def part(index):
        start=index*1000000
        end=min(SIZE,start+1000000)-1
        request=urllib.request.Request(URL+f'?part={index}',headers={'Range':f'bytes={start}-{end}'})
        with urllib.request.urlopen(request,timeout=120) as response:
            data=response.read()
        if len(data)==SIZE:
            data=data[start:end+1]
        assert len(data)==end-start+1,(index,len(data))
        return data
    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
        data=b''.join(pool.map(part,range((SIZE+999999)//1000000)))
    assert hashlib.sha1(f'blob {len(data)}\0'.encode()+data).hexdigest()==GIT_BLOB
    target=ROOT/'assets/fonts/LXGWWenKai-Regular.ttf'
    target.write_bytes(data)
    license=ROOT/'assets/licenses/LXGW-OFL.txt'
    manifest=dict(version='v1.530',source=URL,gitBlob=GIT_BLOB,asset='assets/fonts/LXGWWenKai-Regular.ttf',assetSha256=hashlib.sha256(data).hexdigest(),license='assets/licenses/LXGW-OFL.txt',licenseSha256=hashlib.sha256(license.read_bytes()).hexdigest())
    (target.parent/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Verified official font:',len(data),'bytes')

if __name__=='__main__':
    main()
