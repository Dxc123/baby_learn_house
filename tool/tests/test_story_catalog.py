import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from catalog_transaction import write_documents

class StoryCatalogTest(unittest.TestCase):
    def test_check_is_read_only_for_all_three_outputs(self):
        import subprocess
        import sys
        root=Path(__file__).resolve().parents[2]
        files=[root/f'assets/data/{name}.json' for name in ['content','readings','stories']]
        before=[(p.read_bytes(),p.stat().st_mtime_ns) for p in files]
        subprocess.run([sys.executable,str(root/'tool/expand_phase2_content.py'),'--check'],cwd=root,check=True,capture_output=True)
        self.assertEqual(before,[(p.read_bytes(),p.stat().st_mtime_ns) for p in files])
    def test_builder_preserves_old_item_values_and_rejects_bad_units(self):
        import copy
        from expand_phase2_content import build_catalog
        from story_catalog import build_story_catalog,validate_stories
        root=Path(__file__).resolve().parents[2]
        base=build_catalog(root);base['items']=[i for i in base['items'] if i.get('storyId') is None]
        before=copy.deepcopy(base)
        data,body=build_story_catalog(root,base)
        self.assertEqual(base,before);self.assertEqual(data['items'][:252],base['items'])
        for change in ['role','scene','pinyin','unit','tips']:
            bad=copy.deepcopy(body)
            if change=='role':bad['stories'][3]['turns'][0]['roleId']='bad'
            if change=='scene':bad['scenes'][0]['id']='bad'
            if change=='pinyin':bad['stories'][0]['pages'][0]['pinyin']=[]
            if change=='unit':bad['stories'][0]['pages'].pop()
            if change=='tips':bad['stories'][3]['parentTips']=[]
            with self.subTest(change=change),self.assertRaises(ValueError):validate_stories(bad,data)
    def test_temp_write_failure_preserves_existing_outputs(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);base=root/'assets/data';base.mkdir(parents=True)
            for name in ['content','readings','stories']:(base/f'{name}.json').write_text('old-'+name)
            with patch.object(Path,'write_text',side_effect=OSError('disk')):
                with self.assertRaises(OSError):write_documents(root,{k:{} for k in ['content','readings','stories']})
            for name in ['content','readings','stories']:self.assertEqual((base/f'{name}.json').read_text(),'old-'+name)
    def test_rollbacks_every_replace_with_missing_story(self):
        import os
        for fail_at in [1,2,3]:
            with self.subTest(fail_at=fail_at),tempfile.TemporaryDirectory() as temp:
                root=Path(temp);base=root/'assets/data';base.mkdir(parents=True)
                (base/'content.json').write_text('old-content');(base/'readings.json').write_text('old-readings')
                replace=os.replace;calls=0
                def fail(source,target):
                    nonlocal calls
                    calls+=1
                    if calls==fail_at:raise OSError('injected')
                    return replace(source,target)
                with patch('os.replace',side_effect=fail):
                    with self.assertRaises(OSError):write_documents(root,{k:{'version':1} for k in ['content','readings','stories']})
                self.assertEqual((base/'content.json').read_text(),'old-content')
                self.assertEqual((base/'readings.json').read_text(),'old-readings')
                self.assertFalse((base/'stories.json').exists())
                self.assertEqual(list(base.glob('*.tmp')),[])
