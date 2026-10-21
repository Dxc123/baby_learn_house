import copy
import hashlib
import json
import re
from reading_catalog import annotations

BOOKS={'book-share-toys':'share','book-tidy-up':'tidy','book-feelings':'feelings'}
DIALOGS={'dialog-'+x for x in ['greeting','thanks','borrowing','help','taking-turns','feelings']}
def validate_stories(body,catalog=None):
    def require(v,msg):
        if not v:raise ValueError(msg)
    require(body.get('version')==1,'Story version')
    stories=body['stories'];scenes=body['scenes'];by_scene={s['id']:s for s in scenes}
    require(len(stories)==9 and {s['id'] for s in stories}==set(BOOKS)|DIALOGS,'Story corpus')
    require(len(scenes)==len(by_scene)==18,'Scene corpus')
    seen=set()
    for s in stories:
        book=s['id'] in BOOKS;id=s['id']
        require(s['type']==('pictureBook' if book else 'dialogue') and s['categoryId']==('books' if book else 'dialog'),'Story kind')
        annotations(s['title'],s['titlePinyin'])
        require(s['intro'].strip() and s['prompt'].strip() and s['provenance']=={'source':'project-authored','reviewStatus':'text-reviewed'},'Story metadata')
        units=s['pages' if book else 'turns'];require(len(units)==6,'Unit count')
        if not book:
            require(len(s['roles'])==2 and len({r['id'] for r in s['roles']})==2 and all(r['name'].strip() and r['avatarId'] in ['child','friend','adult'] for r in s['roles']),'Roles')
            require(len(s['parentTips'])==2 and all(p.strip() for p in s['parentTips']),'Parent tips')
        for i,u in enumerate(units,1):
            require(u['id']==f"{id}-{'page' if book else 'turn'}-{i:02}",'Unit identity')
            annotations(u['text'],u['pinyin']);chars=len(re.findall(r'[\u3400-\u9fff]',u['text']))
            require((12<=chars<=32) if book else (8<=chars<=28),'Unit text size')
            if book:
                scene=f'{BOOKS[id]}-{i:02}';require(u.get('sceneId')==scene and 'roleId' not in u,'Page scene')
                entry=by_scene.get(scene,{});seen.add(scene)
                require(entry.get('bookId')==id and entry.get('pageId')==u['id'] and entry.get('alt','').strip() and entry.get('version')==1 and entry.get('source')=='project-authored vector scene' and entry.get('quality')=='illustration','Scene metadata')
            else:require(u.get('roleId') in {r['id'] for r in s['roles']} and 'sceneId' not in u,'Turn role')
        if catalog:
            matches=[i for i in catalog['items'] if i.get('storyId')==id]
            require(len(matches)==1 and matches[0]['id']==id and matches[0]['categoryId']==s['categoryId'],'Story reference')
            require(matches[0].get('coverSceneId')==(units[0]['sceneId'] if book else None),'Story cover')
    require(seen==set(by_scene),'Orphan scene')

def build_story_catalog(root,catalog):
    source=json.loads((root/'tool/content_sources/stories.json').read_text())
    validate_stories(source)
    revision=hashlib.sha256(json.dumps(source,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    data=copy.deepcopy(catalog)
    for c in data['categories']:
        if c['id'] in ['books','dialog']:c.update(kind='pictureBook' if c['id']=='books' else 'dialogue',available=True,description='3 本自编六页绘本' if c['id']=='books' else '6 场日常表达，分角色陪练')
    data['items']=[i for i in data['items'] if i['categoryId'] not in ['books','dialog']]
    for n,s in enumerate(source['stories']):
        item=dict(id=s['id'],storyId=s['id'],categoryId=s['categoryId'],text=s['title'],pinyin=s['titlePinyin'],symbol='绘' if s['type']=='pictureBook' else '聊',sortKey=f'{n:02}',audio=None,audioQuality='unavailable',note='自编图文 · 离线阅读',example=s['intro'])
        if s['type']=='pictureBook':item['coverSceneId']=s['pages'][0]['sceneId']
        data['items'].append(item)
    data['storyRevision']=revision
    body=dict(source,storyRevision=revision);validate_stories(body,data)
    return data,body
