import copy
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from number_catalog import build_number_catalog

class NumbersTest(unittest.TestCase):
    def test_invalid_activity_and_numbers_rejected(self):
        from expand_phase2_content import build_catalog, validate_catalog
        root=Path(__file__).resolve().parents[2]
        for change in ['activity','ambiguous','bool','range','duplicate','item-in-tool','empty-pinyin','blank-pinyin']:
            with self.subTest(change=change):
                data=build_catalog(root)
                c=next(c for c in data['categories'] if c['id']=='count')
                n=next(i for i in data['items'] if i['id']=='number-1')
                if change=='activity': c['activityKind']='other'
                elif change=='ambiguous': c['kind']='number'
                elif change=='bool': n['numberValue']=True
                elif change=='range': n['numberValue']=11
                elif change=='duplicate': n['numberValue']=0
                elif change=='empty-pinyin': n['pinyin']=[]
                elif change=='blank-pinyin': n['pinyin']=[' ']
                else: n['categoryId']='count'
                with self.assertRaises(ValueError): validate_catalog(data)
    def test_deterministic_no_input_mutation(self):
        source={'categories':[{'id':x} for x in ['numbers','count','plus-block','minus-block']], 'items':[]}
        before=copy.deepcopy(source)
        result=build_number_catalog(source)
        self.assertEqual(source,before)
        self.assertEqual(result,build_number_catalog(source))
        self.assertEqual([x['numberValue'] for x in result['items']],list(range(11)))
        self.assertTrue(all(x['audio'] is None and x['audioQuality']=='unavailable' for x in result['items']))
