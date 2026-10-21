"""Generate development demos in staging; preserve old artifacts on any failure."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import wave
from reading_catalog import validate_source

ROOT=Path(__file__).resolve().parents[1]
def text_hash(line):
    return hashlib.sha256(json.dumps({'text':line['text'],'speechText':line['speechText'],'pinyin':line['pinyin']},ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def generate_line(line,target):
    with tempfile.TemporaryDirectory() as temp:
        aiff=Path(temp)/'voice.aiff';wav=Path(temp)/'voice.wav'
        subprocess.run(['say','-v','Tingting','-r','130','-o',str(aiff),line['speechText']],check=True)
        subprocess.run(['afconvert','-f','WAVE','-d','LEI16@22050',str(aiff),str(wav)],check=True)
        with wave.open(str(wav)) as audio:
            frames=audio.readframes(audio.getnframes())
            if audio.getnframes()<1000 or not any(frames):raise RuntimeError('Silent generated audio')
        target.write_bytes(wav.read_bytes())

def main():
    source=ROOT/'tool/content_sources/readings.json'
    data=json.loads(source.read_text());entries=[]
    validate_source(data)
    manifest_file=ROOT/'assets/audio/reading/manifest.json'
    old=json.loads(manifest_file.read_text()) if manifest_file.exists() else []
    old_by={e['lineId']:e for e in old}
    with tempfile.TemporaryDirectory() as temp:
        staged=[]
        for p in data['passages']:
            if not p['provenance'].get('audioEligible'):continue
            for line in p['lines']:
                asset=f"audio/reading/{line['id']}.wav";target=ROOT/'assets'/asset
                stamp=text_hash(line);entry=old_by.get(line['id'])
                if entry and entry['textSha256']==stamp and target.exists() and hashlib.sha256(target.read_bytes()).hexdigest()==entry['audioSha256']:
                    entries.append(entry)
                else:
                    stage=Path(temp)/(line['id']+'.wav');generate_line(line,stage);staged.append((stage,target))
                    entries.append(dict(lineId=line['id'],asset=asset,source='macOS system speech; development demo',voice='Tingting',speechText=line['speechText'],textSha256=stamp,audioSha256=hashlib.sha256(stage.read_bytes()).hexdigest(),quality='demo',reviewedBy=None))
                line.update(audio=asset,audioQuality='demo')
        replacements=[(target,stage.read_bytes()) for stage,target in staged]
        replacements.extend([(manifest_file,(json.dumps(entries,ensure_ascii=False,indent=2)+'\n').encode()),(source,(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode())])
        previous={path:path.read_bytes() if path.exists() else None for path,_ in replacements}
        try:
            for path,content in replacements:
                path.parent.mkdir(parents=True,exist_ok=True)
                temporary=path.with_suffix(path.suffix+'.tmp');temporary.write_bytes(content);os.replace(temporary,path)
        except BaseException:
            for path,content in previous.items():
                if content is None:path.unlink(missing_ok=True)
                else:path.write_bytes(content)
            raise
        finally:
            for path,_ in replacements:path.with_suffix(path.suffix+'.tmp').unlink(missing_ok=True)
    print('Reading demo clips:',len(entries),'; professional teaching review pending')

if __name__=='__main__':main()
