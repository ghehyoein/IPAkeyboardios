"""Build one OFL font, keeping only reachable characters and shaping dependencies."""
import sys,json,hashlib,argparse,tempfile
from pathlib import Path
from fontTools.ttLib import TTFont,newTable
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.subset import Subsetter,Options
from fontTools.merge import Merger
from fontTools.ttLib.scaleUpem import scale_upem
from inventory import ROOT,codepoints
FEATURES=['ccmp','locl','liga','rlig','mark','mkmk','kern']
def subset(font,points):
 font["OS/2"].ulUnicodeRange4 &= 0x07FFFFFF
 o=Options();o.layout_features=FEATURES;o.hinting=False;o.recalc_bounds=True;o.recalc_timestamp=False;o.name_IDs=[0,1,2,3,4,5,6,13,14];o.name_legacy=True;o.name_languages=['*'];o.notdef_outline=True
 s=Subsetter(options=o);s.populate(unicodes=points);s.subset(font)
 # Never keep mappings pulled in incidentally via compatibility/substitution closure.
 for table in font['cmap'].tables:
  if table.isUnicode():table.cmap={cp:g for cp,g in table.cmap.items() if cp in points}
 return font

def to_ttf(font):
 if 'glyf' in font:return font
 order=font.getGlyphOrder();gs=font.getGlyphSet();glyphs={}
 for name in order:
  pen=TTGlyphPen(None);gs[name].draw(Cu2QuPen(pen,max_err=.05));glyphs[name]=pen.glyph()
 fb=FontBuilder(font['head'].unitsPerEm,isTTF=True);fb.setupGlyphOrder(order);fb.setupCharacterMap(font.getBestCmap());fb.setupGlyf(glyphs);fb.setupHorizontalMetrics(dict(font['hmtx'].metrics));fb.setupHorizontalHeader(ascent=font['hhea'].ascent,descent=font['hhea'].descent)
 fb.setupNameTable({'familyName':'Source intermediary','styleName':'Regular'});fb.setupOS2();fb.setupPost();fb.setupMaxp()
 out=fb.font
 for tag in ['GPOS','GSUB','GDEF','name','OS/2']: 
  if tag in font:out[tag]=font[tag]
 return out

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--source-dir',type=Path,required=True);args=ap.parse_args();cache=args.source_dir
 sources=[('Charis',cache/'Charis-7.000/Charis-Regular.ttf'),('Supplement',ROOT/'Reference/Fonts/IPAPlusSupplement-Regular.ttf'),('BabelStone',cache/'BabelStoneRoman.ttf'),('Unifont',cache/'unifont-18.0.01.otf'),('UnifontUpper',cache/'unifont_upper-18.0.01.otf')]
 required=codepoints();remaining=set(required);assignments={};proof=[]
 with tempfile.TemporaryDirectory() as folder:
  inputs=[]
  for index,(name,path) in enumerate(sources):
   f=TTFont(path);mapped={cp for cp,g in f.getBestCmap().items() if f.getGlyphID(g)};chosen=remaining&mapped;remaining-=chosen
   assignments.update({cp:name for cp in chosen});proof.append({'source':name,'file':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'selected_codepoints':len(chosen)})
   if not chosen:continue
   subset(f,chosen);f=to_ttf(f);scale_upem(f,2048)
   for tag in ['Silt','meta','gasp','fpgm','prep','cvt ','DSIG','STAT']: 
    if tag in f:del f[tag]
   f['OS/2'].version=4;f['OS/2'].sxHeight=987;f['OS/2'].sCapHeight=1400;f['OS/2'].usDefaultChar=0;f['OS/2'].usBreakChar=32;f['OS/2'].usMaxContext=8
   f['head'].created=f['head'].modified=3750000000
   dst=Path(folder)/f'{index}.ttf';f.save(dst);inputs.append(str(dst))
  if remaining:raise RuntimeError('Uncovered: '+str(sorted(remaining)))
  merged=Merger().merge(inputs)
  # FontMerger preserves source OpenType layout. Supplement cross-source anchors next.
  from positioning import add_cross_source_positioning
  add_cross_source_positioning(merged,assignments,cache/'UnicodeData.txt')
  subset(merged,required)
  from fontTools.ttLib.tables._n_a_m_e import table__n_a_m_e
  merged['name']=table__n_a_m_e('name')
  copyright='Derived from Charis and Gentium (SIL Global), BabelStone Roman (Andrew West), and Unifont (Roman Czyborra, Paul Hardy and contributors). See bundled Font-Licenses.txt for original notices.'
  for nid,value in {0:copyright,1:'IPA Plus Unified',2:'Regular',3:'IPAPlusUnified-0.1.0',4:'IPA Plus Unified Regular',5:'Version 0.100',6:'IPAPlusUnified-Regular',13:'SIL Open Font License 1.1. Derived font; original copyright and license notices are bundled in Font-Licenses.txt.',14:'https://openfontlicense.org/open-font-license-official-text/'}.items():merged['name'].setName(value,nid,3,1,0x409)
  merged['OS/2'].fsType=0
  # Stable UI metrics; overflow is allowed for uncommon multiple stacked marks.
  merged['hhea'].ascent=2300;merged['hhea'].descent=-800;merged['hhea'].lineGap=0
  os2=merged['OS/2'];os2.sTypoAscender=2300;os2.sTypoDescender=-800;os2.sTypoLineGap=0;os2.fsSelection|=128
  merged['head'].created=merged['head'].modified=3750000000;merged.recalcTimestamp=False
  dst=ROOT/'Shared/Fonts/IPAPlusUnified-Regular.ttf';merged.save(dst)
  check=TTFont(dst);assert set(check.getBestCmap())==required
  report={'codepoints':len(required),'glyphs_including_layout_dependencies':len(check.getGlyphOrder()),'bytes':dst.stat().st_size,'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'sources':proof,'assignments':{f'U+{cp:04X}':assignments[cp] for cp in sorted(assignments)}}
  (ROOT/'Reference/Fonts/unified-coverage.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
  print(json.dumps({k:v for k,v in report.items() if k!='assignments'},indent=2))
if __name__=='__main__':main()
