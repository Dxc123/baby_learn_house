"""Regenerate offline development audio on macOS (not professional recordings)."""
import pathlib
import subprocess
import tempfile
import wave

ROOT = pathlib.Path(__file__).resolve().parents[1]
SAMPLES = {
    'pinyin-a': '啊', 'pinyin-o': '喔', 'pinyin-e': '婀',
    'pinyin-i': '衣', 'pinyin-u': '乌', 'pinyin-v': '迂',
    'hanzi-yi': '一', 'hanzi-er': '二', 'hanzi-san': '三',
    'hanzi-ren': '人', 'hanzi-kou': '口', 'hanzi-shan': '山',
    'animal-cat': '猫', 'animal-dog': '狗', 'animal-rabbit': '兔',
    'animal-bird': '鸟',
}
output = ROOT / 'assets' / 'audio'
output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory() as scratch:
    for name, text in SAMPLES.items():
        source = pathlib.Path(scratch) / f'{name}.aiff'
        subprocess.run(['say', '-v', 'Tingting', '-r', '110', '-o', str(source), text], check=True)
        subprocess.run(['afconvert', '-f', 'WAVE', '-d', 'LEI16@22050', str(source), str(output / f'{name}.wav')], check=True)
        with wave.open(str(output / f'{name}.wav')) as audio:
            if audio.getnframes() < 1000:
                raise RuntimeError(f'{name}: system speech returned empty audio')
print(f'Generated {len(SAMPLES)} offline WAV samples.')
