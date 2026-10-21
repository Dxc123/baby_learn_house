"""Deterministic offline number course. No audio generation."""
from copy import deepcopy

def build_number_catalog(data: dict) -> dict:
    result=deepcopy(data)
    for category in result['categories']:
        identifier=category['id']
        if identifier=='drawing':
            category.update(activityKind='drawing',available=True,description='自由绘画、保存草稿与导出 PNG')
        tables={'hundred':('hundred','1～100 十列排列，0 单独认识'),'plus':('additionTable','两个加数各 1～9，观察加法规律'),'minus':('subtractionTable','被减数 1～9，结果不小于零'),'times':('multiplicationTable','1～9 的组数与每组数量'),'divide':('divisionTable','行是分组数，列是每组数量，格中是总数')}
        if identifier in tables:
            activity,description=tables[identifier]
            category.update(activityKind=activity,available=True,description=description)
        if identifier=='numbers':
            category.update(kind='number',available=True,description='认识 0～10，数字与数量对应')
        elif identifier in {'count','plus-block','minus-block'}:
            category.update(activityKind={'count':'count','plus-block':'addition','minus-block':'subtraction'}[identifier],available=True)
            if identifier=='count':
                category['description']='点一点，数清每一个物体'
    result['items']=[i for i in result['items'] if i['categoryId']!='numbers']
    for number,(text,pinyin) in enumerate(zip('零一二三四五六七八九十','líng yī èr sān sì wǔ liù qī bā jiǔ shí'.split())):
        result['items'].append(dict(id=f'number-{number}',categoryId='numbers',text=text,pinyin=[pinyin],
            numberValue=number,symbol=str(number),sortKey=f'{number:02}',audio=None,audioQuality='unavailable',
            note='数字与数量 · 自编课程',example='一个也没有，就是零。' if number==0 else f'数一数，这里有 {number} 个。'))
    return result
