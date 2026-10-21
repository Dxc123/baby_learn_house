import copy
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('catalog', ROOT / 'tool/expand_phase2_content.py')
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)

class CatalogTest(unittest.TestCase):
    def test_invalid_hanzi_source_schema(self):
        for field,value in [('pinyin',[]),('groupId','nonexistent'),('strokes',0)]:
            with self.subTest(field=field),tempfile.TemporaryDirectory() as temp:
                root=Path(temp)
                source=root/'tool/content_sources'
                source.mkdir(parents=True)
                for name in ['base_catalog.json','hanzi.json']:
                    (source/name).write_bytes((ROOT/'tool/content_sources'/name).read_bytes())
                data=json.loads((source/'hanzi.json').read_text())
                data['items'][0][field]=value
                (source/'hanzi.json').write_text(json.dumps(data))
                with self.assertRaises((AssertionError,ValueError)):
                    catalog.build_catalog(root)
    def test_repeatable_and_old_ids(self):
        first = catalog.build_catalog(ROOT)
        self.assertEqual(first, catalog.build_catalog(ROOT))
        previous = json.loads((ROOT / 'test/fixtures/phase1_content.json').read_text())
        self.assertTrue({i['id'] for i in previous['items']} <= {i['id'] for i in first['items']})
        self.assertEqual(len(first['items']), 261)

    def test_invalid_source_fails_before_output(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'tool/content_sources'
            source.mkdir(parents=True)
            for name in ['base_catalog.json','hanzi.json']:
                (source/name).write_bytes((ROOT/'tool/content_sources'/name).read_bytes())
            data = json.loads((source/'hanzi.json').read_text())
            data['items'][0]['words'][0]['pinyin'] = []
            (source/'hanzi.json').write_text(json.dumps(data))
            output = root / 'assets/data/content.json'
            output.parent.mkdir(parents=True)
            output.write_text('keep')
            with self.assertRaises(AssertionError):
                catalog.build_catalog(root)
            self.assertEqual(output.read_text(), 'keep')
