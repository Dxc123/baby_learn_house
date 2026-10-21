"""Generate development-only English letter / Chinese word clips; never infer pinyin sounds."""
import json
import pathlib
import subprocess
import tempfile
import wave

ROOT = pathlib.Path(__file__).resolve().parents[1]
items = json.loads((ROOT/'assets/data/content.json').read_text())['items']
count = 0
with tempfile.TemporaryDirectory() as temporary:
    for item in items:
        if item['categoryId'] == 'pinyin' or not item.get('audio'):
            continue
        destination = ROOT/'assets'/item['audio']
        if destination.exists():
            with wave.open(str(destination)) as audio:
                if audio.getnframes() > 1000:
                    continue
        english = item['categoryId'] == 'alphabet'
        source = pathlib.Path(temporary)/'voice.aiff'
        subprocess.run(['say', '-v', 'Samantha' if english else 'Tingting', '-r', '130',
                        '-o', str(source), item['text'][0] if english else item['text']], check=True)
        subprocess.run(['afconvert', '-f','WAVE','-d','LEI16@22050', str(source), str(destination)], check=True)
        with wave.open(str(destination)) as audio:
            if audio.getnframes() < 1000:
                raise RuntimeError(f"Empty synthesized audio: {item['id']}")
        count += 1
print(f'Generated {count} additional demo clips; pinyin recordings unchanged.')
