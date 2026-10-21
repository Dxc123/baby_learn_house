"""Pure reading build, validation and rollback-safe paired output."""
import copy
import hashlib
import json
import os
import re
from pathlib import Path

PUNCT='，。！？；：、（）《》“”‘’—…·'
def validate_source(source):
    if source.get('version')!=1 or not isinstance(source.get('passages'),list):raise ValueError('Invalid reading source')
    counts={kind:sum(p.get('categoryId')==kind for p in source['passages']) for kind in ['poetry','idioms','classics']}
    if counts!={'poetry':10,'idioms':10,'classics':1}:raise ValueError('Invalid fixed reading corpus size')
    ids=set();line_ids=set()
    for p in source['passages']:
        if not isinstance(p,dict) or not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*',p.get('id','')) or p['id'] in ids or p.get('categoryId') not in ['poetry','idioms','classics']:raise ValueError('Invalid reading identity')
        ids.add(p['id']);annotations(p.get('title'),p.get('titlePinyin'))
        for key in ['author','sourceLabel','intro']:
            if not isinstance(p.get(key),str) or not p[key].strip():raise ValueError('Missing reading '+key)
        provenance=p.get('provenance',{})
        if not isinstance(provenance.get('url'),str) or not provenance['url'].startswith('https://') or not provenance.get('edition') or not provenance.get('reviewStatus'):raise ValueError('Invalid reading provenance')
        if not isinstance(p.get('lines'),list) or not p['lines']:raise ValueError('Empty reading lines')
        if p['categoryId']=='classics' and (len(p['lines'])!=12 or any(len(l.get('text',''))!=3 for l in p['lines'])):raise ValueError('Classics must contain twelve three-character lines')
        if p['categoryId']=='idioms' and (not 4<=len(p['lines'])<=6 or any(not 12<=sum(c not in PUNCT for c in l.get('text',''))<=28 for l in p['lines'])):raise ValueError('Invalid story length')
        for l in p['lines']:
            if not isinstance(l,dict) or not re.fullmatch(re.escape(p['id'])+r'-line-[0-9]{2}',l.get('id','')) or l['id'] in line_ids:raise ValueError('Invalid reading line')
            line_ids.add(l['id']);annotations(l.get('text'),l.get('pinyin'))
            if not isinstance(l.get('explanation'),str) or not l['explanation'].strip() or l.get('speechText')!=l['text']:raise ValueError('Invalid reading transcript/explanation')
            if l.get('audioQuality') not in ['demo','unavailable','verified'] or (l['audioQuality']=='unavailable')!=(l.get('audio') is None) or (l.get('audio') and l['audio']!=f"audio/reading/{l['id']}.wav"):raise ValueError('Invalid reading audio')
def annotations(text,pinyin):
    if not isinstance(text,str) or not text or not isinstance(pinyin,list) or len(text)!=len(pinyin):raise ValueError('Reading annotation length')
    for c,p in zip(text,pinyin):
        if not isinstance(p,str) or (p!='' if c in PUNCT else not ('\u3400'<=c<='\u9fff') or not p.strip()):raise ValueError('Reading annotation alignment')

def validate_body(body,catalog):
    if body['version']!=1 or body['readingRevision']!=catalog['readingRevision']:raise ValueError('Reading revision mismatch')
    passage_ids=set();line_ids=set();references=set()
    for p in body['passages']:
        if p['id'] in passage_ids:raise ValueError('Duplicate passage')
        passage_ids.add(p['id']);annotations(p['title'],p['titlePinyin'])
        if not p['lines'] or not p['intro'] or not p['author'] or not p['provenance']['url'].startswith('https://'):raise ValueError('Missing reading metadata')
        items=[i for i in catalog['items'] if i.get('readingId')==p['id']]
        if not items or any(i['categoryId']!=p['categoryId'] for i in items):raise ValueError('Invalid reading reference')
        for l in p['lines']:
            if l['id'] in line_ids or not l['id'].startswith(p['id']+'-line-'):raise ValueError('Duplicate/foreign line')
            line_ids.add(l['id']);annotations(l['text'],l['pinyin'])
            if not l['explanation'] or (l['audioQuality']=='unavailable')!=(l.get('audio') is None):raise ValueError('Invalid line metadata')
            if l.get('audio') and l['audio']!=f"audio/reading/{l['id']}.wav":raise ValueError('Invalid reading audio path')
            if l['audioQuality'] not in ['demo','unavailable','verified']:raise ValueError('Invalid audio quality')
            if p['categoryId']=='classics':
                if len(l['text'])!=3 or l.get('learningItemId') in references or not any(i['id']==l.get('learningItemId') and i.get('readingLineId')==l['id'] for i in items):raise ValueError('Invalid classic line')
                references.add(l['learningItemId'])
        if p['categoryId']=='classics' and len(items)!=len(p['lines']):raise ValueError('Classic coverage')
        if p['categoryId']!='classics' and len(items)!=1:raise ValueError('Whole passage item')
    if passage_ids!={i['readingId'] for i in catalog['items'] if i.get('readingId')}:raise ValueError('Reading coverage')

def build_reading_catalog(root:Path,base:dict):
    catalog=copy.deepcopy(base)
    source=json.loads((root/'tool/content_sources/readings.json').read_text())
    validate_source(source)
    revision=hashlib.sha256(json.dumps(source,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    body=dict(source,readingRevision=revision)
    catalog['readingRevision']=revision
    for category in catalog['categories']:
        if category['id'] in ['poetry','idioms','classics']:category.update(kind='reading',available=True,description={'poetry':'10 首古诗，逐句阅读','idioms':'10 则自编成语故事','classics':'开篇 12 句，慢慢读'}[category['id']])
    for index,p in enumerate(body['passages']):
        rows=p['lines'] if p['categoryId']=='classics' else [None]
        for n,line in enumerate(rows):
            item=dict(id=line['learningItemId'] if line else p['id'],categoryId=p['categoryId'],text=line['text'] if line else p['title'],pinyin=line['pinyin'] if line else p['titlePinyin'],symbol='读',note=p['sourceLabel'],example=p['intro'],sortKey=f'{index:02}-{n:02}',readingId=p['id'],audio=None,audioQuality='unavailable')
            if line:item['readingLineId']=line['id']
            catalog['items'].append(item)
    validate_body(body,catalog)
    return catalog,body

def write_catalog_pair(root:Path,catalog:dict,body:dict):
    from catalog_transaction import write_documents
    write_documents(root,{'content':catalog,'readings':body})
