import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tool'))

class ReadingAudioTest(unittest.TestCase):
    def test_invalid_annotations_rejected_before_any_audio_or_source_write(self):
        import json
        import generate_reading_audio as audio
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);source=root/'tool/content_sources/readings.json';source.parent.mkdir(parents=True)
            body=json.loads((ROOT/'tool/content_sources/readings.json').read_text());body['passages'][0]['lines'][0]['pinyin']=[]
            original=json.dumps(body,ensure_ascii=False);source.write_text(original)
            with patch.object(audio,'ROOT',root),patch.object(audio,'generate_line',side_effect=lambda line,target:target.write_bytes(b'fake-pcm')) as generate:
                with self.assertRaises(ValueError):audio.main()
                generate.assert_not_called()
            self.assertEqual(source.read_text(),original)
            self.assertFalse((root/'assets/audio/reading/manifest.json').exists())
    def test_generation_failure_preserves_source_and_existing_clip(self):
        from generate_reading_audio import generate_line
        with tempfile.TemporaryDirectory() as temp:
            target=Path(temp)/'test.wav';target.write_bytes(b'keep')
            line={'id':'test','text':'你好。','speechText':'你好。','audio':None,'audioQuality':'unavailable'}
            with patch('generate_reading_audio.subprocess.run',side_effect=RuntimeError('voice failed')):
                with self.assertRaises(RuntimeError):generate_line(line,target)
            self.assertEqual(target.read_bytes(),b'keep')
            self.assertIsNone(line['audio'])
