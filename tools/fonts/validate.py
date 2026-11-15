"""Static + HarfBuzz checks; iOS CoreText coverage is verified by Swift tests."""
import hashlib,json,sys
from pathlib import Path
from fontTools.ttLib import TTFont
import uharfbuzz as hb
from inventory import ROOT,codepoints,strings

def main():
 path=ROOT/'Shared/Fonts/ipa-plus.ttf';font=TTFont(path);required=codepoints();cm=font.getBestCmap()
 assert set(cm)==required,('missing',required-set(cm),'extra',set(cm)-required)
 assert font['name'].getDebugName(6)=='IPAPlus-Regular'
 assert font['name'].getDebugName(1)=='ipa+'
 assert 'PERMISSION & CONDITIONS' in font['name'].getDebugName(13)
 assert 'TERMINATION' in font['name'].getDebugName(13)
 for owner in ['SIL Global', 'SIL International', 'Andrew West', 'Roman Czyborra', 'Paul Hardy']:
  assert owner in font['name'].getDebugName(0),owner
 assert font['OS/2'].fsType==0
 assert all(font.getGlyphID(cm[cp])>0 for cp in required)
 assert not any(tag in font for tag in ['fpgm','prep','cvt ','DSIG','Silt','meta'])
 shaped=hb.Font(hb.Face(path.read_bytes()))
 def shape(s):
  b=hb.Buffer();b.add_str(s);b.guess_segment_properties();hb.shape(shaped,b)
  assert not any(g.codepoint==0 for g in b.glyph_infos),repr(s)
  return sum(p.x_advance for p in b.glyph_positions)
 for value in strings():shape(value)
 width=shape('a')
 for value in ['a\u1acf','a\u1acf\u0301','a\u0301\u1acf','a\u0325\u1add','a\u20dd']:assert shape(value)==width,value
 # A second subset pass cannot find any unreachable layout/outline dependencies.
 from build import subset
 before=set(font.getGlyphOrder());subset(font,required);assert set(font.getGlyphOrder())==before
 report=json.loads((ROOT/'Reference/Fonts/unified-coverage.json').read_text())
 assert report['sha256']==hashlib.sha256(path.read_bytes()).hexdigest()
 assert report['codepoints']==len(required)
 print(f'{len(required)} exact codepoints, {len(strings())} input/display strings, no missing glyphs; mark advance and dependency closure passed.')
if __name__=='__main__':main()
