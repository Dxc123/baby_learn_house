"""Check all PDF labels and Hanzi/pinyin against the pinned font cmap."""
import json
from pathlib import Path
from fontTools.ttLib import TTFont

ROOT=Path(__file__).resolve().parents[1]
font=TTFont(ROOT/'assets/fonts/LXGWWenKai-Regular.ttf')
cmap=font.getBestCmap()
text='宝宝学识屋 · 汉字练习姓名：________ 日期：________画笔顺：Hanzi Writer Data / Arphic字体：LXGW WenKai / OFL0123456789'
for item in json.loads((ROOT/'assets/data/content.json').read_text())['items']:
    if item['categoryId']=='chinese':
        text+=item['text']+''.join(item['pinyin'])
        for word in item['words']:
            text+=word['text']+''.join(word['pinyin'])
missing=sorted({c for c in text if not c.isspace() and ord(c) not in cmap})
assert not missing,missing
print('PDF font coverage complete:',font['name'].getDebugName(5))
