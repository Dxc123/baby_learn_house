import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('catalog',ROOT/'tool/expand_phase2_content.py')
catalog=importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)

class ReadingCatalogTest(unittest.TestCase):
    def test_fixed_corpus_cannot_be_silently_shortened(self):
        import copy
        from reading_catalog import validate_source
        source=json.loads((ROOT/'tool/content_sources/readings.json').read_text())
        short=copy.deepcopy(source);short['passages'].pop(0)
        with self.assertRaises(ValueError):validate_source(short)
        short=copy.deepcopy(source);short['passages'][-1]['lines'].pop()
        with self.assertRaises(ValueError):validate_source(short)
    def test_counts_stability_and_original_ids(self):
        data=catalog.build_catalog(ROOT)
        self.assertEqual(len(data['items']),261)
        self.assertEqual(sum(c.get('available',False) for c in data['categories']),28)
        self.assertTrue(set(json.loads((ROOT/'test/fixtures/phase2b_ids.json').read_text())) <= {i['id'] for i in data['items']})
        self.assertEqual(data,catalog.build_catalog(ROOT))
        body=json.loads((ROOT/'assets/data/readings.json').read_text())
        self.assertEqual(len(body['passages']),21)
        classics=next(p for p in body['passages'] if p['id']=='classics-opening')
        self.assertEqual(''.join(l['text'] for l in classics['lines']),'人之初性本善性相近习相远苟不教性乃迁教之道贵以专昔孟母择邻处子不学断机杼')

    def test_pair_write_rolls_back_second_replace_failure(self):
        from reading_catalog import write_catalog_pair
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);target=root/'assets/data';target.mkdir(parents=True)
            (target/'content.json').write_text('old catalog');(target/'readings.json').write_text('old body')
            import os
            replace=os.replace;calls=0
            def failing(a,b):
                nonlocal calls
                calls+=1
                if calls==2:raise OSError('second replace failed')
                return replace(a,b)
            with patch('reading_catalog.os.replace',failing):
                with self.assertRaises(OSError):write_catalog_pair(root,{'x':1},{'x':2})
            self.assertEqual((target/'content.json').read_text(),'old catalog')
            self.assertEqual((target/'readings.json').read_text(),'old body')
