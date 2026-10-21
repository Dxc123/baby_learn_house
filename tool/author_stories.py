"""Developer-only authoring helper. Requires existing pypinyin; never used by App."""
import json
from pathlib import Path
from pypinyin import lazy_pinyin,Style

ROOT=Path(__file__).resolve().parents[1]
PUNCT='，。！？；：、（）《》“”‘’—…·'
def annotation(text):
    result=[p if ch not in PUNCT else '' for ch,p in zip(text,lazy_pinyin(text,style=Style.TONE,neutral_tone_with_five=False))]
    for phrase,corrected in {'长时间':['cháng','shí','jiān'],'东西':['dōng','xi'],'地方':['dì','fang']}.items():
        start=0
        while (at:=text.find(phrase,start))>=0:
            result[at:at+len(phrase)]=corrected;start=at+len(phrase)
    return result

BOOKS=[
 ('book-share-toys','一起玩小火车','share','两位朋友商量怎样一起玩，也尊重正在使用玩具的人。',[
  ('小米看见小乐在搭轨道，也想一起玩小火车。','小米站在旁边，看小乐把两段轨道接起来。'),
  ('小乐正在搭一座小桥，还想把这一段搭好。','小乐举起一段桥形轨道，小米在旁边等候。'),
  ('小米轻轻问，我可以和你一起搭轨道吗？','小米张开手掌提出请求，小乐转头倾听。'),
  ('小乐说，等我搭好小桥，我们再轮流开车。','小乐指向还没接好的小桥，两人商量顺序。'),
  ('小米帮忙接上轨道，两个人轮流开小火车。','轨道连成环，小米和小乐各坐一边轮流推车。'),
  ('玩好以后，他们一起把小火车放回盒子里。','两位朋友把小火车和轨道放进收纳盒。'),
 ],'如果朋友还想玩一会儿，你可以怎样商量？'),
 ('book-tidy-up','玩具回家啦','tidy','整理可以分成小步骤，也可以邀请别人一起帮忙。',[
  ('游戏结束了，小米看见地上还有积木和小球。','小米看着散落在地面的三块积木和两个球。'),
  ('走路的地方有些挤，我们先腾出一条小路。','小米把散落的玩具移到一边，留出通道。'),
  ('小米把积木放进方盒，小球放进圆圆的篮子。','积木放入方盒，小球放入带提手的篮子。'),
  ('还有一个大盒子，小米请小乐一起帮忙搬。','小米指向大盒子，小乐走过来准备帮忙。'),
  ('他们一人扶住一边，慢慢把盒子放回架子。','两位朋友托住盒子两侧，放在低矮架子上。'),
  ('地上又有了空地方，明天还能继续快乐地玩。','玩具回到低架和篮子，地面留出空地方。'),
 ],'如果东西太多，你想先整理哪一小部分？'),
 ('book-feelings','我有一点生气','feelings','感受可以被看见，也可以用安全的方法表达需要。',[
  ('小米搭的小塔倒下了，心里忽然有一点生气。','小米坐在倒下的小积木塔旁，眉毛皱起来。'),
  ('小米发现小手握紧了，脸上也有一点发热。','小米注意到自己握紧的手和脸上的表情。'),
  ('小米告诉小乐，我现在生气，也有一点难过。','小米指向倒下的积木，小乐坐在一旁倾听。'),
  ('他们先停下来，慢慢呼吸，再看看想做什么。','两位朋友放松双手，坐着慢慢呼吸。'),
  ('小米说，我想重新搭好，你可以帮我扶住吗？','小米拿起一块积木，向小乐提出帮扶的请求。'),
  ('小乐愿意帮忙，他们商量先从宽宽的底座搭起。','两人合作把宽底座摆好，再放上一块积木。'),
 ],'你有一点生气时，希望别人怎样陪伴你？'),
]
DIALOGS=[
 ('greeting','见面问好','小米','小乐',[
  '早上好，小乐，今天见到你真高兴。','早上好，小米，我也很高兴见到你。','你现在愿意和我聊一会儿吗？','我想先放好书包，再过来找你。','好的，我会在阅读角等你一会儿。','谢谢你等我，我们待会儿再聊。'], '别人暂时不想聊天时，你可以怎样回应？'),
 ('thanks','表达感谢','小米','小乐',[
  '谢谢你帮我捡起掉在地上的画笔。','不用客气，我看见你刚才拿着画纸。','有你的帮助，我就能拿稳这些东西。','你还需要我帮忙拿些什么吗？','我现在可以了，谢谢你先问问我。','好的，需要的时候可以再告诉我。'], '想想今天的一次帮助，你想感谢什么？'),
 ('borrowing','借用玩具','小米','小乐',[
  '小乐，我可以借用一下这辆小车吗？','我还在玩，想把这条路先开完。','好的，你大概还需要多长时间呢？','再开一圈就好，然后我来告诉你。','那我先去搭桥，等你玩好再来借。','谢谢你等我，我玩好会把车放这里。'], '如果对方今天不想借，你还可以选择什么？'),
 ('help','我需要帮助','小米','老师',[
  '老师，这个盖子很紧，我打不开。','我听见了，你愿意指给我看吗？','就是这个盒子，我试过还是打不开。','谢谢你说清楚，我们一起试试看。','我想扶住盒子，请您帮忙转盖子。','好的，我们慢慢来，遇到困难可以求助。'], '遇到困难时，你可以向哪些可信赖的大人求助？'),
 ('taking-turns','商量轮流','小米','小乐',[
  '我也想玩秋千，我们可以轮流吗？','可以，我还想再荡一小会儿。','好的，我们怎样约定换人的时候呢？','我们一起数十下，然后就换你玩。','可以，我在旁边安全的地方等你。','谢谢你，我们换人的时候再确认一下。'], '如果等得有点着急，你可以怎样表达？'),
 ('feelings','说说我的感受','小米','小乐',[
  '刚才你拿走画纸，我有一点着急。','我听见你着急了，那是你还在画的吗？','是的，我还没画完，想继续用这张纸。','对不起，我先还给你，下次会先问。','谢谢你听我说，我们可以另外找张纸。','好的，我们一起找，再慢慢画下去。'], '如果你有不同的感受，可以换成哪些自己的话？'),
]
def build():
    stories=[];scenes=[]
    for id,title,prefix,intro,pages,prompt in BOOKS:
        units=[]
        for i,(text,alt) in enumerate(pages,1):
            uid=f'{id}-page-{i:02}';scene=f'{prefix}-{i:02}'
            units.append(dict(id=uid,text=text,pinyin=annotation(text),sceneId=scene))
            scenes.append(dict(id=scene,bookId=id,pageId=uid,alt=alt,version=1,source='project-authored vector scene',quality='illustration'))
        stories.append(dict(id=id,type='pictureBook',categoryId='books',title=title,titlePinyin=annotation(title),intro=intro,pages=units,prompt=prompt,provenance=dict(source='project-authored',reviewStatus='text-reviewed')))
    for suffix,title,a,b,turns,prompt in DIALOGS:
        id='dialog-'+suffix
        stories.append(dict(id=id,type='dialogue',categoryId='dialog',title=title,titlePinyin=annotation(title),intro='和家长分角色读一读，也可以换成自己的话。',roles=[dict(id='child',name=a,avatarId='child'),dict(id='partner',name=b,avatarId='adult' if suffix=='help' else 'friend')],turns=[dict(id=f'{id}-turn-{i+1:02}',text=text,pinyin=annotation(text),roleId='child' if i%2==0 else 'partner') for i,text in enumerate(turns)],parentTips=['先倾听孩子想表达的意思，再一起试试不同说法。','可以交换角色，允许等待、拒绝和表达不同感受。'],prompt=prompt,provenance=dict(source='project-authored',reviewStatus='text-reviewed')))
    return dict(version=1,stories=stories,scenes=scenes)
if __name__=='__main__':
    (ROOT/'tool/content_sources/stories.json').write_text(json.dumps(build(),ensure_ascii=False,indent=2)+'\n')
