"""Deterministic production catalog builder. --check never writes output."""
import argparse
import json
import os
import re
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tool'))
from reading_catalog import build_reading_catalog, write_catalog_pair, annotations
from number_catalog import build_number_catalog
from story_catalog import build_story_catalog
from catalog_transaction import write_documents

def validate_catalog(data):
    """Validate the entire generated schema before any output replacement."""
    def require(condition,message):
        if not condition:
            raise ValueError(message)
    require(data.get('version')==1,'Unsupported version')
    categories={}
    for category in data['categories']:
        require(isinstance(category.get('id'),str) and category['id'] not in categories,'Duplicate/invalid category')
        categories[category['id']]=category
        require(isinstance(category.get('tab'),int) and 0<=category['tab']<=3,'Invalid tab')
        require(isinstance(category.get('name'),str) and isinstance(category.get('pinyin'),list) and len(category['name'])==len(category['pinyin']),'Invalid category annotation')
        kind=category.get('kind')
        activity=category.get('activityKind')
        require(not (kind is not None and activity is not None),'Ambiguous capability')
        require(activity is None or {'count':'count','plus-block':'addition','minus-block':'subtraction','hundred':'hundred','plus':'additionTable','minus':'subtractionTable','times':'multiplicationTable','divide':'divisionTable','drawing':'drawing'}.get(category['id'])==activity,'Invalid activity')
        require(kind!='number' or category['id']=='numbers','Invalid number category')
        require(not category.get('available') or kind in ['pinyin','hanzi','alphabet','cognition','reading','number','pictureBook','dialogue'] or activity is not None,'Missing kind')
        groups=category.get('groups',[])
        require(len({g['id'] for g in groups})==len(groups),'Duplicate groups')
    ids=set()
    for item in data['items']:
        require(isinstance(item.get('id'),str) and item['id'] not in ids,'Duplicate/invalid item')
        ids.add(item['id'])
        require(item.get('categoryId') in categories,'Unknown category')
        category=categories[item['categoryId']]
        require(category.get('kind') is not None,'Activity cannot contain items')
        story=item.get('storyId');cover=item.get('coverSceneId');is_story=category['kind'] in ['pictureBook','dialogue']
        require((story==item['id'] and isinstance(story,str)) if is_story else story is None and cover is None,'Invalid story reference')
        require(category['kind']!='pictureBook' or (category['id']=='books' and cover in ['share-01','tidy-01','feelings-01']),'Invalid cover')
        require(category['kind']!='dialogue' or (category['id']=='dialog' and cover is None),'Invalid dialogue')
        number=item.get('numberValue')
        require((type(number) is int and 0<=number<=10 and item['id']==f'number-{number}') if category['kind']=='number' else number is None,'Invalid number')
        for key in ['text','symbol','note','example']:
            require(isinstance(item.get(key),str) and item[key].strip(),'Invalid '+key)
        if category['kind']=='reading':
            annotations(item['text'],item['pinyin'])
        else:
            require(isinstance(item.get('pinyin'),list) and all(isinstance(p,str) and p.strip() for p in item['pinyin']),'Invalid annotation type')
        if category['kind'] in ['hanzi','cognition','number','pictureBook','dialogue'] or item['pinyin']:
            require(len(item['text'])==len(item['pinyin']),'Invalid annotations')
        groups={g['id'] for g in category.get('groups',[])}
        require((not groups and item.get('groupId') is None) or item.get('groupId') in groups,'Unknown/missing group')
        for word in item.get('words',[]):
            require(isinstance(word['text'],str) and word['text'] and isinstance(word['pinyin'],list) and len(word['text'])==len(word['pinyin']) and all(isinstance(p,str) and p.strip() for p in word['pinyin']),'Invalid word')
        audio=item.get('audio')
        require(item['audioQuality'] in ['demo','verified','unavailable'] and (item['audioQuality']=='unavailable')==(audio is None),'Invalid audio quality')
        if audio:
            require(bool(re.fullmatch(r'audio/[a-zA-Z0-9_-]+\.wav',audio)),'Invalid audio path')
        if category['kind']=='hanzi':
            require(len(item['text'])==1 and type(item.get('strokes')) is int and 1<=item['strokes']<=64,'Invalid Hanzi')
            require(item.get('strokeAsset')==f"assets/strokes/{ord(item['text']):x}.json",'Invalid stroke reference')
    chinese=[i for i in data['items'] if i['categoryId']=='chinese']
    require(len(chinese)==60 and len(categories['chinese']['groups'])==10,'Invalid corpus size')
    for group in categories['chinese']['groups']:
        require(sum(i['groupId']==group['id'] for i in chinese)==6,'Invalid course size')

def build_catalog(root: Path) -> dict:
    data = json.loads((root / 'tool/content_sources/base_catalog.json').read_text())
    old = {item['id']: item for item in data['items']}
    initials = 'b p m f d t n l g k h j q x zh ch sh r z c s y w'.split()
    finals = 'a o e i u v ai ei ui ao ou iu ie ve er an en in un vn ang eng ing ong'.split()
    syllables = 'zhi chi shi ri zi ci si yi wu yu ye yue yuan yin yun ying'.split()
    items = []
    for group_id, group_name, units in [('initials','声母',initials),('finals','韵母',finals),('syllables','整体认读音节',syllables)]:
        for index, unit in enumerate(units):
            identifier = f'pinyin-{unit}'
            item = dict(old.get(identifier, {}))
            display = unit.replace('a', 'ɑ').replace('v', 'ü')
            item.update(id=identifier, categoryId='pinyin', text=display, pinyin=[], symbol=display,
                        groupId=group_id, sortKey=f'{index:02}', note=group_name)
            item.setdefault('example', f'这是{group_name} {display}。跟随老师或标准录音练习，注意它是一个完整的发音单位。')
            item.setdefault('audio', None)
            item['audioQuality'] = 'demo' if item['audio'] else 'unavailable'
            items.append(item)
    items.extend(dict(item, audioQuality='demo') for item in old.values() if item['categoryId'] == 'chinese')
    words = [
        ('Apple','苹果'),('Ball','球'),('Cat','猫'),('Dog','狗'),('Egg','鸡蛋'),('Fish','鱼'),
        ('Goat','山羊'),('Hat','帽子'),('Ice','冰'),('Juice','果汁'),('Kite','风筝'),('Lion','狮子'),
        ('Moon','月亮'),('Nest','鸟巢'),('Orange','橙子'),('Pig','猪'),('Queen','女王'),('Rabbit','兔子'),
        ('Sun','太阳'),('Tree','树'),('Umbrella','雨伞'),('Van','厢式货车'),('Water','水'),
        ('X-ray','X 光'),('Yo-yo','悠悠球'),('Zebra','斑马'),
    ]
    for index, (word, meaning) in enumerate(words):
        letter = chr(97 + index)
        items.append(dict(id=f'en-{letter}', categoryId='alphabet', text=letter.upper()+letter,
          pinyin=[], symbol=letter.upper()+letter, audio=f'audio/en-{letter}.wav', audioQuality='demo',
          note='英文字母 · 名称发音（美式合成示范）', example=f'{word} · {meaning}。当前按钮只读字母名称，不朗读例词。', sortKey=f'{index:02}'))
    
    # slug, Chinese name, hand-authored pronunciation, pictogram, concise explanation
    groups = {
     'family':[
     ('dad','爸爸','bà ba','👨','爸爸是家中的一位长辈。可以和爸爸一起读书、做游戏。'),
     ('mom','妈妈','mā ma','👩','妈妈是家中的一位长辈。可以对妈妈说说今天的发现。'),
     ('grandpa','爷爷','yé ye','👴','爸爸的爸爸，通常称作爷爷。'),
     ('grandma','奶奶','nǎi nai','👵','爸爸的妈妈，通常称作奶奶。'),
     ('brother','哥哥','gē ge','🧑','哥哥是比自己年长的男性同辈家人。'),
     ('sister','姐姐','jiě jie','👧','姐姐是比自己年长的女性同辈家人。')],
     'body':[
     ('eyes','眼睛','yǎn jing','👀','眼睛帮助我们看见颜色和形状。'),
     ('ears','耳朵','ěr duo','👂','耳朵帮助我们听到声音。'),
     ('nose','鼻子','bí zi','👃','鼻子能闻到气味，也帮助我们呼吸。'),
     ('mouth','嘴巴','zuǐ ba','👄','嘴巴可以说话，也可以吃东西。'),
     ('hand','手','shǒu','✋','手可以抓握东西，也可以帮助我们画画。'),
     ('foot','脚','jiǎo','🦶','脚帮助我们站立和行走。')],
     'sports':[
     ('run','跑步','pǎo bù','🏃','跑步时，双脚轮流向前迈。'),
     ('swim','游泳','yóu yǒng','🏊','游泳是在水中的运动，儿童要由合适的成人看护。'),
     ('rope','跳绳','tiào shéng','rope','绳子从脚下经过时，双脚轻轻跳起。'),
     ('soccer','足球','zú qiú','⚽','足球运动主要用脚控制球。'),
     ('basketball','篮球','lán qiú','🏀','篮球可以拍着走，也可以投向篮筐。'),
     ('pingpong','乒乓球','pīng pāng qiú','🏓','乒乓球使用球拍，在球台两边对打。')],
     'jobs':[
     ('doctor','医生','yī shēng','🧑‍⚕️','医生帮助人们诊断和治疗疾病。'),
     ('teacher','老师','lǎo shī','🧑‍🏫','老师帮助我们学习知识与本领。'),
     ('police','警察','jǐng chá','👮','警察维护公共秩序，帮助有需要的人。'),
     ('firefighter','消防员','xiāo fáng yuán','🧑‍🚒','消防员灭火，也参与各种救援。'),
     ('cook','厨师','chú shī','🧑‍🍳','厨师把食材做成可口的饭菜。'),
     ('farmer','农民','nóng mín','🧑‍🌾','农民种植作物或从事其他农业劳动。')],
     'colors':[(slug, name, py, slug, note) for slug, name, py, note in [
     ('red','红色','hóng sè','熟透的番茄常常是红色的。'),('yellow','黄色','huáng sè','成熟的香蕉常常是黄色的。'),
     ('blue','蓝色','lán sè','晴朗的天空常常是蓝色的。'),('green','绿色','lǜ sè','许多植物的叶子是绿色的。'),
     ('black','黑色','hēi sè','黑色是很深的颜色。'),('white','白色','bái sè','白色图块的边框帮助我们看清它的形状。')]],
     'shapes':[
     ('circle','圆形','yuán xíng','circle','圆形的边是弯曲的，没有角。'),
     ('square','正方形','zhèng fāng xíng','square','正方形有四条相等的边和四个直角。'),
     ('triangle','三角形','sān jiǎo xíng','triangle','三角形有三条边、三个角。'),
     ('rectangle','长方形','cháng fāng xíng','rectangle','长方形的对边相等，有四个直角。'),
     ('oval','椭圆形','tuǒ yuán xíng','oval','椭圆形像拉长的圆。'),
     ('star','五角星','wǔ jiǎo xīng','star','五角星有五个向外伸出的尖角。')],
     'animals':[
     ('cat','猫','māo','🐱','猫有灵敏的耳朵和长长的胡须。'),
     ('dog','狗','gǒu','🐶','狗的鼻子很灵敏，能闻到许多气味。'),
     ('rabbit','兔','tù','🐰','兔子有长长的耳朵，喜欢吃草。'),
     ('bird','鸟','niǎo','🐦','鸟的身上有羽毛，许多鸟会飞。'),
     ('fish','鱼','yú','🐟','许多鱼生活在水中，用鳃呼吸。'),
     ('cow','牛','niú','🐄','牛是常见的家畜，主要吃草等植物。')],
     'plants':[
     ('tree','树','shù','🌳','树有树干和树枝，许多树会长出茂密的叶子。'),
     ('grass','草','cǎo','grass','草通常比较矮小，叶子细长。'),
     ('lotus','荷花','hé huā','🪷','荷花生长在水中，常在夏天开放。'),
     ('sunflower','向日葵','xiàng rì kuí','🌻','向日葵有大大的花盘。'),
     ('pine','松树','sōng shù','🌲','松树的叶子常呈针形，许多种类四季常青。'),
     ('bamboo','竹子','zhú zi','bamboo','竹子的茎一节一节，叫作竹节。')],
     'foods':[
     ('apple','苹果','píng guǒ','🍎','苹果是一种常见的水果。'),
     ('banana','香蕉','xiāng jiāo','🍌','香蕉有弯弯的外形，吃之前先剥皮。'),
     ('rice','米饭','mǐ fàn','🍚','大米加水煮熟，可以做成米饭。'),
     ('bread','面包','miàn bāo','🍞','面包一般由面粉等原料烘烤而成。'),
     ('egg','鸡蛋','jī dàn','🥚','鸡蛋有蛋壳、蛋白和蛋黄。'),
     ('milk','牛奶','niú nǎi','🥛','牛奶是常见的饮品，饮用前注意保质期。')],
     'vehicles':[
     ('bike','自行车','zì xíng chē','🚲','自行车通常依靠踩踏脚踏板前进。'),
     ('car','汽车','qì chē','🚗','汽车在道路上行驶，乘坐时要系安全带。'),
     ('bus','公交车','gōng jiāo chē','🚌','公交车按照一定的路线和站点运送乘客。'),
     ('train','火车','huǒ chē','🚆','火车沿着铁轨行驶。'),
     ('ship','轮船','lún chuán','🚢','轮船在水面上航行。'),
     ('plane','飞机','fēi jī','✈️','飞机可以在空中飞行。')],
    }
    for category_id, rows in groups.items():
        for index, (slug, text, py, symbol, description) in enumerate(rows):
            identifier = f'animal-{slug}' if category_id == 'animals' else f'{category_id}-{slug}'
            item = dict(old.get(identifier, {}))
            item.update(id=identifier, categoryId=category_id, text=text, pinyin=py.split(),
                        symbol=symbol, audio=f'audio/{identifier}.wav', audioQuality='demo',
                        note='认知学习 · 图形示意', example=description, sortKey=f'{index:02}')
            items.append(item)
    for category in data['categories']:
        identifier = category['id']
        if identifier == 'pinyin':
            category.update(kind='pinyin', groups=[dict(id=k,title=t,order=i) for i,(k,t) in
              enumerate([('initials','声母'),('finals','韵母'),('syllables','整体认读音节')])])
        elif identifier == 'chinese':
            category['kind'] = 'hanzi'
        elif identifier == 'alphabet':
            category.update(kind='alphabet', available=True)
        elif identifier in groups:
            category.update(kind='cognition', available=True)
        if identifier == 'animals':
            category['description'] = '拜访六位可爱的动物朋友'
        if identifier == 'pinyin':
            category['description'] = '63 个声母、韵母与整体认读音节'
        if identifier == 'alphabet':
            category['description'] = '26 个字母，认识大小写与名称'
    data['items'] = items
    source = json.loads((root / 'tool/content_sources/hanzi.json').read_text())
    legacy = {x['text']: x for x in items if x['categoryId'] == 'chinese'}
    hanzi = []
    for index, entry in enumerate(source['items']):
        char = entry['text']
        item = dict(legacy.get(char, {}))
        item.update(entry)
        item.update(id=item.get('id', f'hanzi-u{ord(char):x}'), categoryId='chinese', symbol=char,
            note='基础汉字 · 自编课程', sortKey=f'{index:03}', strokeAsset=f'assets/strokes/{ord(char):x}.json')
        item.setdefault('audio', None)
        item['audioQuality'] = 'demo' if item['audio'] else 'unavailable'
        hanzi.append(item)
    items = [x for x in items if x['categoryId'] != 'chinese']
    items[63:63] = hanzi
    next(x for x in data['categories'] if x['id'] == 'chinese').update(groups=source['groups'], description='60 个基础汉字，认识、笔顺与描红')
    data['items'] = items
    assert len(items) == len({x['id'] for x in items}) == 209
    assert len(hanzi) == len({x['text'] for x in hanzi}) == 60
    for item in hanzi:
        assert len(item['words']) == 2
        assert all(len(w['text']) == len(w['pinyin']) for w in item['words'])
    validate_catalog(data)
    catalog,body=build_reading_catalog(root,data)
    catalog=build_number_catalog(catalog)
    catalog,stories=build_story_catalog(root,catalog)
    validate_catalog(catalog)
    return catalog

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    data = build_catalog(ROOT)
    source=json.loads((ROOT/'tool/content_sources/readings.json').read_text())
    body=dict(source,readingRevision=data['readingRevision'])
    stories=dict(json.loads((ROOT/'tool/content_sources/stories.json').read_text()),storyRevision=data['storyRevision'])
    documents={'content':data,'readings':body,'stories':stories}
    if args.check:
        for name,document in documents.items():
            if (ROOT/f'assets/data/{name}.json').read_text()!=json.dumps(document,ensure_ascii=False,indent=2)+'\n':raise SystemExit('Catalog drift: rebuild required')
    else:
        write_documents(ROOT,documents)
    print('Validated 261 items, 21 passages, 9 stories, 28 open categories.')

if __name__ == '__main__':
    main()
