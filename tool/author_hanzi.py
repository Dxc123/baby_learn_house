"""Rebuild the canonical, authored 60-character source (not a textbook syllabus)."""
import json
from pathlib import Path

GROUPS = [('starter','基础起步'),('numbers','数量'),('nature','自然'),('directions','方位'),('comparisons','大小与比较'),('body','身体'),('family','家庭'),('daily','生活'),('plants','植物'),('actions','动作')]
# character | main reading | strokes | word reading | word reading | authored explanation
ROWS = '''一|yī|1|一个 yí gè|一天 yì tiān|一表示数量的起点。
二|èr|2|二月 èr yuè|十二 shí èr|二表示两个。
三|sān|3|三个 sān gè|三月 sān yuè|三比二多一。
人|rén|2|人们 rén men|大人 dà rén|人可以学习、劳动和交流。
口|kǒu|3|人口 rén kǒu|门口 mén kǒu|口可以表示嘴，也可以表示出入口。
山|shān|3|高山 gāo shān|山水 shān shuǐ|山是地面上高高隆起的部分。
四|sì|5|四个 sì gè|四季 sì jì|一年有春夏秋冬四季。
五|wǔ|4|五个 wǔ gè|五月 wǔ yuè|伸出一只手，可以数五根手指。
六|liù|4|六个 liù gè|六月 liù yuè|六比五多一。
七|qī|2|七个 qī gè|七天 qī tiān|一周有七天。
八|bā|2|八个 bā gè|八月 bā yuè|八比七多一。
九|jiǔ|2|九个 jiǔ gè|九月 jiǔ yuè|九比八多一。
日|rì|4|日子 rì zi|日出 rì chū|日可以表示太阳，也可以表示一天。
月|yuè|4|月亮 yuè liang|月光 yuè guāng|夜晚常能看到月亮。
水|shuǐ|4|水果 shuǐ guǒ|河水 hé shuǐ|生活中处处需要水。
火|huǒ|4|火车 huǒ chē|火光 huǒ guāng|火能带来热量，儿童不要玩火。
土|tǔ|3|土地 tǔ dì|泥土 ní tǔ|许多植物扎根在泥土中。
木|mù|4|木头 mù tou|树木 shù mù|木可以表示树或木材。
上|shàng|3|上面 shàng miàn|上下 shàng xià|上和下表示相对的方向。
下|xià|3|下面 xià miàn|下雨 xià yǔ|下可以表示位置较低。
左|zuǒ|5|左边 zuǒ bian|左右 zuǒ yòu|左与右是一对相对的方向。
右|yòu|5|右边 yòu bian|右手 yòu shǒu|看看自己的右手在哪里。
中|zhōng|4|中间 zhōng jiān|中心 zhōng xīn|中可以表示两边之间的位置。
大|dà|3|大小 dà xiǎo|大人 dà rén|比较物体时，可以说大或小。
小|xiǎo|3|小手 xiǎo shǒu|小鸟 xiǎo niǎo|小可以表示体积或年龄较小。
多|duō|6|多少 duō shǎo|许多 xǔ duō|比较数量时，可以说多或少。
少|shǎo|4|多少 duō shǎo|少许 shǎo xǔ|少表示数量不多。
长|cháng|4|长短 cháng duǎn|长大 zhǎng dà|长短的长读 cháng，长大的长读 zhǎng。
短|duǎn|12|长短 cháng duǎn|短小 duǎn xiǎo|短与长表示长度的比较。
高|gāo|10|高山 gāo shān|高低 gāo dī|高可以表示离地面较远。
目|mù|5|目光 mù guāng|耳目 ěr mù|目可以表示眼睛。
耳|ěr|6|耳朵 ěr duo|木耳 mù ěr|耳朵帮助我们听声音。
手|shǒu|4|双手 shuāng shǒu|手心 shǒu xīn|手可以抓握，也可以写字。
足|zú|7|手足 shǒu zú|足球 zú qiú|足可以表示脚。
心|xīn|4|开心 kāi xīn|心中 xīn zhōng|心可以表示心脏，也可以表示心情。
头|tóu|5|头发 tóu fa|木头 mù tou|头可以表示身体最上面的部分。
父|fù|4|父亲 fù qīn|父母 fù mǔ|父亲是爸爸的另一种称呼。
母|mǔ|5|母亲 mǔ qīn|母子 mǔ zǐ|母亲是妈妈的另一种称呼。
子|zǐ|3|子女 zǐ nǚ|儿子 ér zi|子在不同词中可以读不同的音。
女|nǚ|3|女孩 nǚ hái|女儿 nǚ ér|女可以表示女性。
兄|xiōng|5|兄弟 xiōng dì|兄长 xiōng zhǎng|兄是哥哥的另一种称呼。
弟|dì|7|弟弟 dì di|兄弟 xiōng dì|弟弟比自己年幼。
门|mén|3|大门 dà mén|门口 mén kǒu|门是进出房屋的通道。
车|chē|4|汽车 qì chē|火车 huǒ chē|车帮助人们运送人和物品。
马|mǎ|3|白马 bái mǎ|马车 mǎ chē|马是一种善于奔跑的动物。
牛|niú|4|水牛 shuǐ niú|牛奶 niú nǎi|牛是常见的家畜。
羊|yáng|6|山羊 shān yáng|羊毛 yáng máo|羊主要吃草等植物。
鸟|niǎo|5|小鸟 xiǎo niǎo|鸟儿 niǎo ér|鸟的身上有羽毛。
花|huā|7|花朵 huā duǒ|开花 kāi huā|许多植物会开花。
草|cǎo|9|小草 xiǎo cǎo|草地 cǎo dì|草通常比较矮小。
竹|zhú|6|竹子 zhú zi|竹林 zhú lín|竹子的茎一节一节。
禾|hé|5|禾苗 hé miáo|禾田 hé tián|禾常用来表示谷类作物。
米|mǐ|6|大米 dà mǐ|米饭 mǐ fàn|大米煮熟可以做成米饭。
果|guǒ|8|水果 shuǐ guǒ|果子 guǒ zi|许多植物会结出果实。
来|lái|7|回来 huí lái|来去 lái qù|来表示向说话人所在的方向移动。
去|qù|5|回去 huí qù|出去 chū qù|去表示离开所在的位置。
走|zǒu|7|走路 zǒu lù|行走 xíng zǒu|走路时双脚交替迈步。
出|chū|5|出去 chū qù|日出 rì chū|出表示从里面到外面。
入|rù|2|入口 rù kǒu|进入 jìn rù|入表示从外面到里面。
开|kāi|4|开心 kāi xīn|开门 kāi mén|开可以表示打开或开始。'''

def build():
    result = []
    for index, row in enumerate(ROWS.splitlines()):
        char, py, strokes, first, second, note = row.split('|')
        words = []
        for value in [first, second]:
            text, *pinyin = value.split()
            assert len(text) == len(pinyin)
            words.append(dict(text=text, pinyin=pinyin))
        result.append(dict(text=char, pinyin=[py], strokes=int(strokes), words=words,
                           example=note, groupId=GROUPS[index // 6][0]))
    assert len(result) == len({x['text'] for x in result}) == 60
    return dict(groups=[dict(id=k,title=t,order=i) for i,(k,t) in enumerate(GROUPS)], items=result)

if __name__ == '__main__':
    target = Path(__file__).parent / 'content_sources/hanzi.json'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(build(), ensure_ascii=False, indent=2)+'\n')
