"""Author canonical reading content; pypinyin is a development-only draft helper.

Poetry readings are explicit. Story drafts use phrase-aware readings with overrides;
the canonical JSON is checked in and can be corrected without running this helper.
"""
import json
from pathlib import Path
from pypinyin import lazy_pinyin,Style,load_phrases_dict

ROOT=Path(__file__).resolve().parents[1]
POEMS=[
('yong-e','咏鹅','yǒng é','骆宾王','詠鵝',[
('鹅，鹅，鹅，','é é é','诗人呼唤着白鹅。'),('曲项向天歌。','qū xiàng xiàng tiān gē','白鹅弯着脖子，朝天空鸣叫。'),('白毛浮绿水，','bái máo fú lǜ shuǐ','白色羽毛浮在绿水上。'),('红掌拨清波。','hóng zhǎng bō qīng bō','红色脚掌拨动清清的水波。')]),
('jingyesi','静夜思','jìng yè sī','李白','靜夜思',[
('床前明月光，','chuáng qián míng yuè guāng','床前洒着明亮的月光。'),('疑是地上霜。','yí shì dì shàng shuāng','诗人一时以为地上落了霜。'),('举头望明月，','jǔ tóu wàng míng yuè','抬起头望着天上的月亮。'),('低头思故乡。','dī tóu sī gù xiāng','低下头想念远方的故乡。')]),
('chunxiao','春晓','chūn xiǎo','孟浩然','春曉_(孟浩然)',[
('春眠不觉晓，','chūn mián bù jué xiǎo','春天睡得香，不知天已亮。'),('处处闻啼鸟。','chù chù wén tí niǎo','到处都能听见鸟叫。'),('夜来风雨声，','yè lái fēng yǔ shēng','想起夜里的风雨声音。'),('花落知多少。','huā luò zhī duō shǎo','不知道有多少花被风雨吹落。')]),
('minnong-2','悯农（其二）','mǐn nóng qí èr','李绅','憫農_(李紳)',[
('锄禾日当午，','chú hé rì dāng wǔ','正午时，农人在田间锄草。'),('汗滴禾下土。','hàn dī hé xià tǔ','汗水滴在禾苗下面的土里。'),('谁知盘中餐，','shuí zhī pán zhōng cān','谁能想到碗里的饭菜，'),('粒粒皆辛苦。','lì lì jiē xīn kǔ','每一粒粮食都来自辛勤劳动。')]),
('dengguanquelou','登鹳雀楼','dēng guàn què lóu','王之涣','登鸛雀樓_(王之渙)',[
('白日依山尽，','bái rì yī shān jìn','太阳靠着远山慢慢落下。'),('黄河入海流。','huáng hé rù hǎi liú','黄河奔流，流向大海。'),('欲穷千里目，','yù qióng qiān lǐ mù','如果想把更远的景色看清，'),('更上一层楼。','gèng shàng yì céng lóu','就再登上一层楼。')]),
('xunyinzhebuyu','寻隐者不遇','xún yǐn zhě bù yù','贾岛','尋隱者不遇',[
('松下问童子，','sōng xià wèn tóng zǐ','在松树下向小孩子问路。'),('言师采药去。','yán shī cǎi yào qù','孩子说老师采药去了。'),('只在此山中，','zhǐ zài cǐ shān zhōng','就在这座山里面，'),('云深不知处。','yún shēn bù zhī chù','云雾很浓，不知他具体在哪里。')]),
('jiangxue','江雪','jiāng xuě','柳宗元','江雪',[
('千山鸟飞绝，','qiān shān niǎo fēi jué','许多山间都看不到飞鸟。'),('万径人踪灭。','wàn jìng rén zōng miè','许多小路上都没有人的足迹。'),('孤舟蓑笠翁，','gū zhōu suō lì wēng','孤单的小船上，老人穿蓑衣戴斗笠。'),('独钓寒江雪。','dú diào hán jiāng xuě','他独自在下雪的寒江上钓鱼。')]),
('gulangyuexing-excerpt','古朗月行（节选）','gǔ lǎng yuè xíng jié xuǎn','李白','古朗月行',[
('小时不识月，','xiǎo shí bù shí yuè','小时候还不认识月亮，'),('呼作白玉盘。','hū zuò bái yù pán','把它叫作白色的玉盘。'),('又疑瑶台镜，','yòu yí yáo tái jìng','又觉得它像瑶台上的镜子，'),('飞在青云端。','fēi zài qīng yún duān','飞在高高的青云上面。')]),
('xiaochi','小池','xiǎo chí','杨万里','小池',[
('泉眼无声惜细流，','quán yǎn wú shēng xī xì liú','小泉眼静静地流着细水。'),('树阴照水爱晴柔。','shù yīn zhào shuǐ ài qíng róu','树影映在水中，晴天温柔美好。'),('小荷才露尖尖角，','xiǎo hé cái lù jiān jiān jiǎo','小荷叶刚露出尖尖的角，'),('早有蜻蜓立上头。','zǎo yǒu qīng tíng lì shàng tóu','已经有蜻蜓站在上面了。')]),
('shanxing','山行','shān xíng','杜牧','山行_(杜牧)',[
('远上寒山石径斜，','yuǎn shàng hán shān shí jìng xié','顺着弯曲的石头小路走上秋山。'),('白云生处有人家。','bái yún shēng chù yǒu rén jiā','白云升起的地方，有几户人家。'),('停车坐爱枫林晚，','tíng chē zuò ài fēng lín wǎn','停下车，是因为喜爱傍晚的枫林。'),('霜叶红于二月花。','shuāng yè hóng yú èr yuè huā','经霜的红叶，比二月的春花还红。')]),
]
STORIES=[
('shouzhudaitu','守株待兔','韩非子·五蠹','韓非子/五蠹','不能把偶然的好运当作每天都会发生的事情。',[
'一个农夫在田里干活，看见兔子撞上树桩。','农夫捡到了兔子，心里觉得非常高兴。','从此他不再种田，天天坐在树桩旁等待。','后来兔子没有再来，田里的庄稼却荒废了。']),
('wangyangbulao','亡羊补牢','战国策·楚策四','戰國策_(士禮居叢書本)/楚/四','发现问题后及时改进，仍然可以减少损失。',[
'一个人养了几只羊，羊圈破了一个大洞。','夜里狼从洞里钻进去，叼走了一只小羊。','邻居劝他修好羊圈，他这才认真补上洞。','羊圈修好了，剩下的羊也得到了保护。']),
('huashetianzu','画蛇添足','战国策·齐策二','戰國策_(士禮居叢書本)/齊/二','做事要想清需要什么，并非添加得越多越好。',[
'几个人商量比赛画蛇，先画完的人得到酒。','一个人很快画好了，见别人还在慢慢画。','他得意地给蛇添上脚，想显示自己画得快。','别人说蛇本来没有脚，他反而失去了酒。']),
('yanerdaoling','掩耳盗铃','吕氏春秋·自知','呂氏春秋/卷二十四#自知','不去听问题，并不表示问题就不存在。',[
'一个人想偷偷拿走铃铛，却怕铃声被听见。','他用双手捂住耳朵，以为别人也听不到。','等他伸手去碰铃铛，清脆的铃声马上响起。','别人听到声音走过来，他的想法并不管用。']),
('jingdizhiwa','井底之蛙','庄子·秋水','莊子/秋水','多听不同的见闻，可以帮助我们开阔眼界。',[
'一只青蛙住在井底，觉得自己的天地很大。','一天海龟来到井边，说起辽阔的大海。','青蛙听了很吃惊，原来井外还有那么多景色。','它开始明白，自己看到的只是世界的一小部分。']),
('kezhouqiujian','刻舟求剑','吕氏春秋·察今','呂氏春秋/卷十五#察今','情况改变后，解决问题的方法也需要调整。',[
'一个人乘船过河，不小心把剑掉进了水里。','他急忙在船边刻记号，记住剑掉下的位置。','船继续向前走，他却等船停下才准备找剑。','船的位置已经改变，照着记号找不到原来的剑。']),
('bamiaozhuzhang','拔苗助长','孟子·公孙丑上','孟子/公孫丑上','成长需要时间，合适的帮助要尊重生长规律。',[
'一个人每天看禾苗，总觉得禾苗长得太慢。','他想帮助禾苗长高，就把每棵苗往上拔。','忙了一整天以后，他高兴地回家告诉家人。','家人去田里查看，发现禾苗已经开始枯萎。']),
('hujiahuawei','狐假虎威','战国策·楚策一','戰國策_(士禮居叢書本)/楚/一','判断事情时，要分清看到的现象和真正的原因。',[
'老虎抓住一只狐狸，狐狸想了一个脱身办法。','狐狸说大家都怕自己，请老虎跟着走一走。','森林里的动物看见老虎，纷纷跑开躲起来。','老虎以为动物怕狐狸，其实大家怕的是老虎。']),
('zixiangmaodun','自相矛盾','韩非子·难一','韓非子/難一','说话要前后一致，夸大事实容易出现矛盾。',[
'一个人卖矛又卖盾，先夸自己的盾特别坚固。','接着他又夸自己的矛，说什么盾都能刺穿。','有人问用这根矛刺这面盾，会发生什么事情。','他发现两种说法互相冲突，一时回答不出来。']),
('yugongyishan','愚公移山','列子·汤问','列子/湯問篇','故事赞扬坚持和合作，实际做事也要考虑可行办法。',[
'愚公家门前有两座大山，每次出门都要绕路。','他和家人商量以后，决定一起设法搬走大山。','有人笑他做不到，他仍然带着大家坚持劳动。','故事中的神被诚意感动，帮助他们搬走了山。']),
]
CLASSICS=[('人之初','rén zhī chū','传统文本开始谈论人的成长。'),('性本善','xìng běn shàn','这是古人的一种看法，可以从善意地理解别人开始。'),('性相近','xìng xiāng jìn','古人认为，人最初有不少相近之处。'),('习相远','xí xiāng yuǎn','不同的经历和习惯，会带来不同的变化。'),('苟不教','gǒu bù jiào','如果缺少合适的教导和帮助，'),('性乃迁','xìng nǎi qiān','人的习惯和行为可能发生变化。'),('教之道','jiào zhī dào','说到教导和学习的方法，'),('贵以专','guì yǐ zhuān','古人重视专心，学习也需要休息和耐心。'),('昔孟母','xī mèng mǔ','从前，孟子的母亲，'),('择邻处','zé lín chǔ','选择适合孩子成长的环境居住。'),('子不学','zǐ bù xué','故事讲到孩子一时不愿学习，'),('断机杼','duàn jī zhù','母亲用中断织布作比喻，劝他坚持学习。')]

PUNCT='，。！？；：、（）《》“”‘’—…·'
STORY_NOTES=[
 ['树桩是树被砍后留下的部分。','捡到兔子是一次偶然的事情。','等待取代了本来应该做的劳动。','田地没有照料，庄稼就长不好。'],
 ['羊圈是围起来养羊的地方。','破洞让羊失去了保护。','邻居的提醒帮助他发现问题。','修补虽然晚了一点，仍然有作用。'],
 ['先说好比赛的规则。','他已经完成了原本的任务。','添脚是多做了不需要做的事情。','不符合规则的添加，反而破坏了结果。'],
 ['这个故事把原典的大钟改写为铃铛。','捂住自己的耳朵，不能捂住别人的耳朵。','铃铛被碰到，仍然会发出声音。','想象中的办法，没有改变真实情况。'],
 ['井底能看到的范围很有限。','海龟带来了青蛙没听过的见闻。','新的见闻让青蛙感到惊讶。','承认自己不知道，也是一种学习。'],
 ['剑落在河水中的某个地方。','记号只能记住船上的位置。','船在移动，剑没有跟着船走。','寻找的方法要考虑位置的变化。'],
 ['禾苗有自己的生长速度。','拔高禾苗会伤害它的根。','他以为自己的办法有效。','没有照顾生长规律，帮助变成了伤害。'],
 ['狐狸想借老虎的威势脱身。','跟在狐狸身后的老虎才是关键。','动物们真正看到的是凶猛的老虎。','老虎把动物逃跑的原因弄错了。'],
 ['矛用于刺击，盾用于防护。','两个夸张的说法不能同时成立。','这个问题把两种说法放在一起比较。','发现说法冲突，就要重新想一想。'],
 ['大山让出行变得不方便。','愚公与家人商量，大家一起合作。','故事强调坚持，但做事也需要方法。','这是带有神话色彩的故事结尾。'],
]
load_phrases_dict({'长高':[['zhǎng'],['gāo']],'长得':[['zhǎng'],['de']],'看见':[['kàn'],['jiàn']],'觉得':[['jué'],['de']],'羊圈':[['yáng'],['juàn']],'一只':[['yì'],['zhī']],'一个':[['yí'],['gè']],'开始':[['kāi'],['shǐ']],'得到':[['dé'],['dào']],'处处':[['chù'],['chù']]})
load_phrases_dict({'庄稼':[['zhuāng'],['jia']],'商量':[['shāng'],['liang']],'得意地':[['dé'],['yì'],['de']],'画得快':[['huà'],['de'],['kuài']],'铃铛':[['líng'],['dang']],'耳朵':[['ěr'],['duo']],'位置':[['wèi'],['zhi']],'狐狸':[['hú'],['li']],'高兴地':[['gāo'],['xìng'],['de']],'一天':[['yì'],['tiān']],'一整天':[['yì'],['zhěng'],['tiān']],'一小':[['yì'],['xiǎo']],'一时':[['yì'],['shí']],'走一走':[['zǒu'],['yi'],['zǒu']]})
def annotation(text,explicit=None):
    units=iter(explicit.split()) if explicit else None
    return ['' if c in PUNCT else next(units) if units else lazy_pinyin(c,style=Style.TONE)[0] for c in text] if explicit else [p if c not in PUNCT else '' for c,p in zip(text,lazy_pinyin(text,style=Style.TONE,neutral_tone_with_five=False))]

def main():
    passages=[]
    def add(identifier,category,title,author,page,rows,intro,title_py=None,edition='古籍正文，简体转写；标点为本项目整理'):
        lines=[]
        for i,(text,py,explanation) in enumerate(rows):
            line=dict(id=f'{identifier}-line-{i+1:02}',text=text,pinyin=annotation(text,py),explanation=explanation,audio=None,audioQuality='unavailable',speechText=text)
            if category=='classics':line['learningItemId']=f'classic-opening-{i+1:02}'
            lines.append(line)
        passages.append(dict(id=identifier,categoryId=category,title=title,titlePinyin=annotation(title,title_py),author=author,sourceLabel='根据传统故事改写' if category=='idioms' else '传统蒙学文本' if category=='classics' else '古诗 · 自编解释',intro=intro,lines=lines,provenance=dict(url='https://zh.wikisource.org/wiki/'+page,edition=edition,reviewStatus='structure-and-reading-draft-checked; professional teaching review pending',audioEligible=True)))
    for slug,title,py,author,page,rows in POEMS:
        add('poetry-'+slug,'poetry',title,author,page,rows,'读一读诗句，想一想诗人看到的景象。',py,edition='唐诗三百首所收通行版本' if slug=='jingyesi' else '前四个五言句节选' if slug=='gulangyuexing-excerpt' else '其二；项目采用通行用字餐（cān），所链接古籍页面作飧；非逐字影印' if slug=='minnong-2' else '简体通行本；山行采用白云生处、斜读xié，小池采用树阴')
    for story_index,(slug,title,source,page,intro,lines) in enumerate(STORIES):
        assert 4<=len(lines)<=6
        assert all(12<=sum(c not in PUNCT for c in line)<=28 for line in lines),(title,lines)
        add('idiom-'+slug,'idioms',title,source,page,[(line,None,STORY_NOTES[story_index][i]) for i,line in enumerate(lines)],intro,edition='仅核对传统典故来源；正文与启发为本项目自编，盗铃故事由原典盗钟改写')
    add('classics-opening','classics','三字经（开篇）','传统蒙学读物，作者归属有不同说法','三字經易解',CLASSICS,'用今天的眼光阅读传统蒙学文本。每个孩子都有自己的成长节奏，不用这些话给孩子贴标签。','sān zì jīng kāi piān',edition='只采用三字经古典正文前36字，不采用该站现代易解；解释为项目自编')
    (ROOT/'tool/content_sources/readings.json').write_text(json.dumps(dict(version=1,passages=passages),ensure_ascii=False,indent=2)+'\n')
    print('Authored',len(passages),'passages;',sum(len(p['lines']) for p in passages),'lines')

if __name__=='__main__':main()
