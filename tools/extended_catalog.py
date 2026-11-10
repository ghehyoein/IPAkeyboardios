"""Expand the chart catalog with source inventories and Unicode 18 records.
Priority is a transcription convention, not a judgment about current IPA status.
"""
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
U=json.loads((ROOT/'Reference/Unicode/phonetic-records.json').read_text())['records']
I=json.loads((ROOT/'Reference/extended-inventory.json').read_text())
PRIORITY={'current':0,'chinese':1,'historical':2,'extipa':3,'unicode':4,'extras':5}

def expand_catalog(catalog):
    entries={s['text']:s for s in catalog['symbols']}
    for s in entries.values():
        s.update(collections=[s['category']],family='current' if s['official'] else 'extras')
        s['priority']=PRIORITY[s['family']]
    def add(text, family, collection=None, name=None):
        collection=collection or family
        if not all(c in U for c in text):
            raise ValueError('Unencoded or missing Unicode reference: '+repr(text))
        if text not in entries:
            combining=all(U[c]['category'].startswith('M') for c in text)
            entries[text]=dict(id='-'.join(f'{ord(c):04X}' for c in text),text=text,display=('◌' if combining else '')+text,
                name=name or ' / '.join(U[c]['name'] for c in text),category=collection,collections=[],combining=combining,
                official=False,family=family,priority=PRIORITY[family])
        s=entries[text]
        if PRIORITY[family]<s['priority']:
            s.update(family=family,priority=PRIORITY[family],category=collection)
        if collection not in s['collections']:s['collections'].append(collection)
        if name:s['name']=name
        return s
    for family in ['chinese','historical','extipa']:
        for text in I[family]:
            if text=='\u034f':continue # Combining Grapheme Joiner is a control, not a phonetic symbol.
            add(text,family)
    # Retired palatal/retroflex letters and historical click/affricate forms.
    for c,row in U.items():
        cp=ord(c)
        if 0x1D80<=cp<=0x1D9A or 0x1DF08<=cp<=0x1DF3D:
            add(c,'historical')
    labels={'ɿ':'舌尖前不圆唇元音','ʅ':'舌尖后不圆唇元音','ʮ':'舌尖前圆唇元音','ʯ':'舌尖后圆唇元音','ᴀ':'小型大写 A（央低元音）','ᴇ':'小型大写 E（前中元音）','ȡ':'汉语音标：浊龈腭塞音','ȶ':'汉语音标：清龈腭塞音','ȵ':'汉语音标：龈腭鼻音','ȴ':'汉语音标：龈腭边音'}
    for c,name in labels.items():entries[c]['name']=name
    # Supplementary phonetic blocks are browsable even when a character is not
    # part of one of the four source traditions. Do not call them "current IPA".
    blocks=[(0x250,0x2FF),(0x1D00,0x1DBF),(0xA700,0xA71F),(0xAB30,0xAB6B),(0x10780,0x107BF),(0x1DF00,0x1DF81),(0x1DFCD,0x1DFFF)]
    for c,row in U.items():
        cp=ord(c)
        if any(a<=cp<=b for a,b in blocks):add(c,'unicode')
        if (0x300<=cp<=0x36F or 0x1AB0<=cp<=0x1AF0 or 0x1DC0<=cp<=0x1DFF) and row['category'].startswith('M') and cp!=0x034F:
            add(c,'unicode','combining')
    # Unicode compatibility decompositions enumerate real superscript/subscript
    # characters, including the new Unicode-18 sinological modifier forms.
    for c,row in U.items():
        decomp=row['decomposition'].split()
        if not decomp or decomp[0] not in ['<super>','<sub>']:continue
        base=''.join(chr(int(x,16)) for x in decomp[1:])
        if not (base in entries or all(x.isascii() and x.isalnum() for x in base)):continue
        family=entries.get(base,{}).get('family','extipa')
        if family in ['current','extras','unicode']:family='extipa'
        add(c,family,'superscripts' if decomp[0]=='<super>' else 'subscripts')
    # Spacing historical diacritics also belong in the historical panel.
    for c in '˂˃˄˅ˊˋˌˍˎˏːˑ˒˓˔˕˖˗˘˙˚˛˜˝':add(c,'historical')
    # A shortcut inserts one atomic symbol, never a ready-made transcription.
    # Canonical decompositions also catch single-code-point forms such as ã.
    def canonical(text):
        result=''
        for c in text:
            decomposition=U.get(c,{}).get('decomposition','').split()
            if decomposition and not decomposition[0].startswith('<'):
                result+=canonical(''.join(chr(int(v,16)) for v in decomposition))
            else:result+=c
        return result
    # Every component of a reference example must remain individually reachable.
    for source in list(entries.values()):
        for c in canonical(source['text']):
            if c not in entries and not c.isascii():
                add(c,source['family'],'combining' if U[c]['category'].startswith('M') else source['family'])
    categories=[c for c in catalog['categories'] if c['id']!='extras']
    categories += [dict(id=k,title=v) for k,v in [('chinese','中国通用音标'),('historical','旧版与非标准 IPA'),('extipa','extIPA'),('superscripts','上标字符'),('subscripts','下标字符'),('combining','组合附加符号'),('unicode','Unicode 语音补充'),('extras','转写辅助')]]
    catalog['categories']=categories
    # Choose base keys by explicit convention, then by Unicode base/decomposition.
    key_for={}
    for key,mapping in catalog['keys'].items():
        for text in mapping['variants']:key_for.setdefault(text,key)
    key_for.update({'ɿ':'i','ʅ':'i','ʮ':'u','ʯ':'u','ᴀ':'a','ᴇ':'e','ᴏ':'o','ʩ':'f','ʪ':'l','ʫ':'l','ʬ':'b','ʭ':'d','¡':'c','ꞎ':'l','ꞯ':'q','𝼀':'f','𝼁':'g','𝼂':'g','𝼃':'k','𝼄':'l','𝼅':'l','𝼆':'y','𝼇':'n','ↀ':'b','π':'p','μ':'m','б':'b','Ƿ':'w','з':'z','δ':'d','ẟ':'d','ƍ':'d','σ':'s','ƻ':'z','ꜫ':'k','ꜭ':'k','т':'t','д':'d','н':'n','л':'l','р':'r','ƕ':'h','ъ':'e','ƨ':'z','ρ':'r','ᴩ':'r','ƣ':'g','ђ':'d','ᴫ':'l','ᴤ':'h','ᴥ':'q','ȣ':'u','ꜵ':'a','Ꜵ':'a','ო':'o','ꝏ':'o','ᵫ':'u','𝼢':'t','𝼣':'t','𝼠':'d','𝼡':'d','ь':'e','𝼺':'q'})
    special={'SCHWA':'e','EPSILON':'e','GAMMA':'g','BETA':'b','THETA':'t','PHI':'f','CHI':'x','PSI':'p','OMEGA':'o','ETA':'n','ENG':'n','EZH':'z','ESH':'s','LEZH':'l','HENG':'h','FENG':'f','OE':'o','AE':'a','IOTA':'i','UPSILON':'u','YOGH':'z','ETH':'d','THORN':'t','GLOTTAL STOP':'q','CLICK':'c','DEZH':'d','TESH':'t','DZ':'d','TS':'t','DB':'d','QP':'q','LS':'l','LZ':'l','TC':'t','LAMBDA':'l','ALPHA':'a','GREEK MU':'m','GREEK RHO':'r','GREEK DELTA':'d','GREEK PI':'p','GREEK SIGMA':'s'}
    def base_key(text,seen=None):
        if text in key_for:return key_for[text]
        seen=seen or set()
        if text in seen:return None
        seen.add(text)
        if len(text)>1:return base_key(text[0],seen)
        if text.isascii() and text.isalpha():return text.lower()
        row=U.get(text)
        if not row:return None
        if row['category'].startswith('M'):return None
        d=row['decomposition'].split()
        if d:
            base=''.join(chr(int(x,16)) for x in d if not x.startswith('<'))
            result=base_key(base,seen)
            if result:return result
        name=row['name']
        for fragment,key in special.items():
            if re.search(r'\b'+re.escape(fragment)+r'\b',name):return key
        parts=name.replace('-',' ').split()
        for word in parts:
            if len(word)==1 and word.isascii() and word.isalpha():return word.lower()
        return None
    for s in entries.values():
        key=base_key(s['text'])
        s['baseKey']=key
        if key and not s['text'].isascii() and s['text'] not in catalog['keys'][key]['variants']:
            catalog['keys'][key]['variants'].append(s['text'])
    for s in entries.values():
        s['atomic']=(len(canonical(s['text']))==1 or (s['official'] and len(s['text'])==1 and U[s['text']]['category'].startswith('L'))) # ç is a basic IPA letter, not a composite shortcut.
    # Keep composite records for chart/source auditing, but not as insert buttons.
    # Stable sort: preserve source order inside each family.
    for key,mapping in catalog['keys'].items():
        mapping['variants']=sorted((t for t in dict.fromkeys(mapping['variants']) if entries[t]['atomic']),key=lambda t:entries[t]['priority'])
        mapping['swipes']={d:t for d,t in mapping['swipes'].items() if entries[t]['atomic']}
    catalog['symbols']=list(entries.values())
    catalog['version']=3
    catalog['source']['unicodeVersion']='18.0.0'
    catalog['source']['scope']='Current IPA; encoded Chinese general phonetic symbols; historical/nonstandard IPA; extIPA 2025; Unicode phonetic supplement and super/subscripts.'
    catalog['source']['priority']=['current','chinese','historical','extipa','unicode','extras']
    return catalog
