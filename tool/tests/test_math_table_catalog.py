import copy
import json
import unittest
from pathlib import Path
from expand_phase2_content import build_catalog,validate_catalog
ROOT=Path(__file__).resolve().parents[2]
class TableCatalogTest(unittest.TestCase):
    def test_new_tools_preserve_items_and_body(self):
        data=build_catalog(ROOT)
        self.assertEqual(len(data['items']),261)
        self.assertEqual(sum(bool(c.get('available')) for c in data['categories']),28)
        self.assertEqual(data,build_catalog(ROOT))
        self.assertTrue(set(json.loads((ROOT/'test/fixtures/phase3a_ids.json').read_text())) <= {i['id'] for i in data['items']})
        self.assertEqual(data['readingRevision'],json.loads((ROOT/'assets/data/readings.json').read_text())['readingRevision'])
        bad=copy.deepcopy(data)
        next(c for c in bad['categories'] if c['id']=='hundred')['activityKind']='divisionTable'
        with self.assertRaises(ValueError):validate_catalog(bad)
