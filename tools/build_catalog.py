"""Reproducible Unicode inventory, visually checked against the IPA 2026 chart."""
import json, unicodedata as u
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
groups = [
 ('pulmonic', '肺部气流辅音', 'p b t d ʈ ɖ c ɟ k ɡ q ɢ ʔ m ɱ n ɳ ɲ ŋ ɴ ʙ r ʀ ⱱ ɾ ɽ ɸ β f v θ ð s z ʃ ʒ ʂ ʐ ç ʝ x ɣ χ ʁ ħ ʕ h ɦ ɬ ɮ ʋ ɹ ɻ j ɰ l ɭ ʎ ʟ'),
 ('vowels', '元音', 'i y ɨ ʉ ɯ u ɪ ʏ ʊ e ø ɘ ɵ ɤ o ə ɛ œ ɜ ɞ ʌ ɔ æ ɐ a ɶ ɑ ɒ'),
 ('nonpulmonic', '非肺部气流辅音', 'ʘ ǀ ǃ ǂ ǁ ɓ ɗ ʄ ɠ ʛ ʼ'),
 ('other', '其他符号与连音线', 'ʍ w ɥ ʜ ʢ ʡ ɕ ʑ ɺ ɧ \u0361 \u035c'),
 ('diacritics', '附加符号', '\u0325 \u030a \u032c ʰ \u0339 \u031c \u031f \u0320 \u0308 \u033d \u0329 \u032f ˞ \u0324 \u0330 \u033c ʷ ʲ ˠ ˤ \u0334 \u031d \u031e \u0318 \u0319 \u032a \u033a \u033b \u0303 ⁿ ˡ \u031a'),
 ('suprasegmentals', '超音段符号', 'ˈ ˌ ː ˑ \u0306 | ‖ . ‿'),
 ('tones', '声调与词重音', '\u030b \u0301 \u0304 \u0300 \u030f ˥ ˦ ˧ ˨ ˩ ꜜ ꜛ \u030c \u0302 \u1dc4 \u1dc5 \u1dc8 ˩˥ ˥˩ ˦˥ ˩˨ ˧˦˧ ↗ ↘'),
 ('extras', '转写辅助', '[ ] / ( ) - g ɚ ɝ')
]
names = {
 '\u0325':'清化（下置）', '\u030a':'清化（上置，用于有下伸部的字母）', '\u032c':'浊化', 'ʰ':'送气',
 '\u0339':'更圆唇', '\u031c':'较少圆唇', '\u031f':'前移', '\u0320':'后移', '\u0308':'央化', '\u033d':'中央化',
 '\u0329':'成音节', '\u032f':'非音节', '˞':'卷舌化', '\u0324':'气声', '\u0330':'嘎裂声', '\u033c':'舌唇音',
 'ʷ':'唇化', 'ʲ':'腭化', 'ˠ':'软腭化', 'ˤ':'咽化', '\u0334':'软腭化或咽化', '\u031d':'升高', '\u031e':'降低',
 '\u0318':'舌根前移', '\u0319':'舌根后移', '\u032a':'齿音', '\u033a':'舌尖音', '\u033b':'舌叶音', '\u0303':'鼻化',
 'ⁿ':'鼻音除阻', 'ˡ':'边音除阻', '\u031a':'无可闻除阻', '\u0361':'上连音线：在两字母之间输入', '\u035c':'下连音线：在两字母之间输入',
 'ˈ':'主重音', 'ˌ':'次重音', 'ː':'长音', 'ˑ':'半长音', '\u0306':'超短音', '|':'小韵律组边界', '‖':'大语调组边界', '.':'音节界', '‿':'连读',
 'ʼ':'挤喉音标记', 'ꜜ':'降阶', 'ꜛ':'升阶', '↗':'整体上升', '↘':'整体下降',
 '\u030b':'超高调（组合标记）', '\u0301':'高调（组合标记）', '\u0304':'中调（组合标记）', '\u0300':'低调（组合标记）', '\u030f':'超低调（组合标记）',
 '\u030c':'升调（组合标记）', '\u0302':'降调（组合标记）', '\u1dc4':'高升调（组合标记）', '\u1dc5':'低升调（组合标记）', '\u1dc8':'升降调（组合标记）',
 '˥':'超高调', '˦':'高调', '˧':'中调', '˨':'低调', '˩':'超低调', '˩˥':'升调', '˥˩':'降调', '˦˥':'高升调', '˩˨':'低升调', '˧˦˧':'升降调',
 'ɚ':'卷舌央元音（便捷预组字符）', 'ɝ':'卷舌半开央元音（便捷预组字符）'
}
symbols=[]
for group,title,chars in groups:
 for s in chars.split():
  combining=all(u.category(c).startswith('M') for c in s)
  symbols.append(dict(id='-'.join(f'{ord(c):04X}' for c in s), text=s,
   display=('◌'+s if combining else s), name=names.get(s, ' / '.join(u.name(c) for c in s)),
   category=group, combining=combining, official=group!='extras'))
# up, right, down, left; remaining symbols are available by long-press.
variants={
 'a':'ɑ æ ɐ ɒ', 'b':'ɓ β ʙ', 'c':'ç ɕ ǀ ǃ ǂ ǁ ʘ', 'd':'ð ɗ ɖ',
 'e':'ə ɛ ɜ ɘ ɞ ɚ ɝ', 'f':'ɸ', 'g':'ɡ ɣ ɠ ɢ ʛ', 'h':'ɦ ħ ʜ ɥ ʰ',
 'i':'ɪ ɨ', 'j':'ʝ ɟ ʄ ʲ', 'k':'', 'l':'ɬ ɭ ʎ ɮ ʟ ˡ',
 'm':'ɱ', 'n':'ŋ ɲ ɳ ɴ ⁿ', 'o':'ɔ ø œ ɵ ɶ ɤ', 'p':'ɸ',
 'q':'ʔ ʕ ʡ ʢ ʼ', 'r':'ɹ ɾ ɻ ʁ ʀ ɽ ɺ ˞', 's':'ʃ ʂ ɕ',
 't':'θ ʈ', 'u':'ʊ ʉ ɯ ɰ', 'v':'ʌ ʋ ⱱ', 'w':'ʍ ɰ ʷ',
 'x':'χ ɣ ɧ ˠ', 'y':'ʏ ɥ', 'z':'ʒ ʐ ʑ'
}
# k has no dedicated non-ASCII chart variant; do not invent obsolete symbols.
layouts={k:dict(variants=v.split(),swipes=dict(zip(['up','right','down','left'],v.split()[:4]))) for k,v in variants.items()}
# Make sure every non-ASCII letter on the chart is reachable via a long press.
letter_groups={'pulmonic','vowels','nonpulmonic','other'}
assigned={v for x in layouts.values() for v in x['variants']}
assert not {s['text'] for s in symbols if s['category'] in letter_groups and len(s['text'])==1 and u.category(s['text']).startswith('L') and not s['text'].isascii()}-assigned
catalog=dict(version=1, source=dict(title='IPA Chart 2026 (revised to 2015/2005)',url='https://www.internationalphoneticassociation.org/content/ipa-chart',pdf='https://www.internationalphoneticassociation.org/IPAcharts/common_files/pdfs/pdfs_IPA_charts_E/IPA_Kiel.pdf',checked='2026-11-09',scope='Standard IPA chart; extIPA and withdrawn symbols excluded.'),categories=[dict(id=g,title=t) for g,t,_ in groups],symbols=symbols,keys=layouts)
from extended_catalog import expand_catalog
catalog = expand_catalog(catalog)
(ROOT/'Shared'/'ipa-catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
print(f'{len(catalog["symbols"])} entries; {sum(s["official"] for s in symbols)} standard-chart entries (including alternate forms and tone sequences).')
