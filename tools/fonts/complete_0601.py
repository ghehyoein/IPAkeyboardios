"""Add 13 licensed source glyphs and two smooth adaptations; no Unifont outlines."""
import argparse,copy,hashlib,json
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from refine_0601 import draw_into,ink

CHARIS=[0x01AB,0xA7F8,0xA7F9,0x0418,0x2C7C,0x2C7D,0xA7F2,0xA7F3,0xA7F4]
NOTO=list(range(0x2E59,0x2E5D))
def main():
 p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--charis',type=Path,required=True);p.add_argument('--noto',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 f=TTFont(a.input);ch=TTFont(a.charis);no=instantiateVariableFont(TTFont(a.noto),{'wght':400,'wdth':100},inplace=True);order=list(f.getGlyphOrder());added={}
 def insert(cp,pen,width,source):
  name=f'ipaAdded{cp:04X}';g=pen.glyph();g.recalcBounds(f['glyf']);f['glyf'][name]=g;f['hmtx'][name]=(round(width),g.xMin);order.append(name)
  for t in f['cmap'].tables:
   if t.isUnicode():t.cmap[cp]=name
  f['GDEF'].table.GlyphClassDef.classDefs[name]=1
  added[f'U+{cp:04X}']={'glyph':name,'source':source}
 for donor,chars,label in [(ch,CHARIS,'Charis 7.000 / SIL OFL 1.1'),(no,NOTO,'Noto Sans 2.015 / SIL OFL 1.1')]:
  for cp in chars:
   name=donor.getBestCmap()[cp];scale=f['head'].unitsPerEm/donor['head'].unitsPerEm;pen=TTGlyphPen(None)
   draw_into(donor,name,pen,(scale,0,0,scale,0,0));insert(cp,pen,donor['hmtx'][name][0]*scale,label)
 # Smooth superscript S: adapt the actual Charis S outline to the height and
 # elevation of its superscript C/F/Q peers, preserving the S's curves.
 gs=ch.getBestCmap();base=gs[0x53];x0,y0,x1,y1=ink(ch,base);ref=ink(ch,gs[0xA7F2]);scale=(ref[3]-ref[1])/(y1-y0)
 pen=TTGlyphPen(None);left=65;draw_into(ch,base,pen,(scale,0,0,scale,left-x0*scale,ref[1]-y0*scale))
 insert(0xA7F1,pen,(x1-x0)*scale+left*2,'Project adaptation of Charis S; scaled to Charis superscript metrics / OFL 1.1')
 # Variable stress is two separate, vertically aligned stress strokes, not a
 # colon or a full-height bar. Reuse licensed high/low stress outlines without
 # copying the stepped Unifont reference or tracing a Unicode chart.
 pen=TTGlyphPen(None);width=max(ch['hmtx'][gs[c]][0] for c in [0x02C8,0x02CC])
 for cp in [0x02C8,0x02CC]:
  n=gs[cp];b=ink(ch,n);draw_into(ch,n,pen,(1,0,0,1,width/2-(b[0]+b[2])/2,0))
 insert(0x208F,pen,width,'Project arrangement of Charis primary/secondary stress outlines / OFL 1.1')
 f.setGlyphOrder(order)
 # Add sensible mark-to-base anchors for newly imported letters. Keep existing
 # lookup class assignments, using the established stem/ascender reference.
 newnames={v['glyph'] for v in added.values()};refname=f.getBestCmap()[ord('I')];refbox=ink(f,refname)
 for lookup in f['GPOS'].table.LookupList.Lookup:
  for st in lookup.SubTable:
   typ=lookup.LookupType
   if typ==9:typ,st=st.ExtensionLookupType,st.ExtSubTable
   if typ!=4 or refname not in st.BaseCoverage.glyphs:continue
   record=st.BaseArray.BaseRecord[st.BaseCoverage.glyphs.index(refname)]
   existing=dict(zip(st.BaseCoverage.glyphs,st.BaseArray.BaseRecord))
   for n in newnames:
    bb=ink(f,n);r=copy.deepcopy(record)
    for anchor in r.BaseAnchor:
     if anchor:
      anchor.XCoordinate+=round((bb[0]+bb[2]-refbox[0]-refbox[2])/2)
      anchor.YCoordinate+=bb[3]-refbox[3] if anchor.YCoordinate>0 else bb[1]-refbox[1]
    existing[n]=r
   names=sorted(existing,key=f.getGlyphID);st.BaseCoverage.glyphs=names;st.BaseArray.BaseRecord=[existing[n] for n in names];st.BaseArray.BaseCount=len(names)
 for record in list(f['name'].names):
  if record.nameID==5:f['name'].setName('Version 0.601; phonetic coverage and enclosure fixes',5,record.platformID,record.platEncID,record.langID)
 f['head'].fontRevision=0.601
 # Add source credit to the actual binary, not only external documentation.
 for record in list(f['name'].names):
  if record.nameID==0:
   s=record.toUnicode()+'; Includes Noto Sans and Noto Sans Symbols, Copyright The Noto Project Authors, SIL OFL 1.1. Two additional Charis-based adaptations by ghehyoein.'
   f['name'].setName(s,0,record.platformID,record.platEncID,record.langID)
 f.recalcTimestamp=False;f.save(a.output)
 report={'version':'0.601','added':added,'sources':{str(p.name):hashlib.sha256(p.read_bytes()).hexdigest() for p in [a.input,a.charis,a.noto]},'font_sha256':hashlib.sha256(a.output.read_bytes()).hexdigest(),'mapped_codepoints':len(f.getBestCmap()),'unifont_outlines_used':False}
 a.output.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
