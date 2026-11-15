"""Preserve source GPOS and supply anchors only for cross-source combinations."""
from fontTools.otlLib import builder as b
from fontTools.ttLib.tables import otTables as ot
from fontTools.pens.boundsPen import BoundsPen

def add_cross_source_positioning(font,assignments,unicode_data):
 records={int(line.split(';')[0],16):line.split(';') for line in unicode_data.read_text().splitlines()}
 cm=font.getBestCmap();gs=font.getGlyphSet();bounds={}
 for name in font.getGlyphOrder():
  pen=BoundsPen(gs);gs[name].draw(pen)
  if pen.bounds:bounds[name]=pen.bounds
 classes={};origin={cm[cp]:src for cp,src in assignments.items()}
 for cp,name in cm.items():
  record=records.get(cp)
  if not record or not record[2].startswith('M') or name not in bounds:continue
  ccc=int(record[3]);label=record[1]
  group='overlay' if ccc==1 or 'OVERLAY' in label else ('below' if 'BELOW' in label or ccc in [202,218,220,222,233,240] else 'above')
  classes[name]=group
  if origin.get(name)!='Charis':font['hmtx'].metrics[name]=(0,font['hmtx'][name][1])
 gdef=font['GDEF'].table
 if gdef.GlyphClassDef is None:gdef.GlyphClassDef=ot.ClassDef();gdef.GlyphClassDef.classDefs={}
 for name in classes:gdef.GlyphClassDef.classDefs[name]=3
 base_names={n for n in bounds if n not in classes and n!='.notdef' and font['hmtx'][n][0]>0}
 donor_bases={n for n in base_names if origin.get(n,'Charis')!='Charis'}
 donor_marks={n for n in classes if origin.get(n,'Charis')!='Charis'}
 primary_marks=set(classes)-donor_marks
 groups={'above':0,'below':1,'overlay':2}
 def mark_anchor(name):
  x0,y0,x1,y1=bounds[name];group=classes[name]
  return b.buildAnchor(round((x0+x1)/2),round(y0 if group=='above' else y1 if group=='below' else (y0+y1)/2))
 def target_anchor(name,group):
  x0,y0,x1,y1=bounds[name]
  return b.buildAnchor(round((x0+x1)/2),round(y1+70 if group=='above' else y0-60 if group=='below' else (y0+y1)/2))
 def append(lookup,tag):
  gpos=font['GPOS'].table;idx=len(gpos.LookupList.Lookup);gpos.LookupList.Lookup.append(lookup);gpos.LookupList.LookupCount+=1
  # All DFLT/Latin/Greek/etc. feature alternatives receive the same fallback.
  for rec in gpos.FeatureList.FeatureRecord:
   if rec.FeatureTag==tag:rec.Feature.LookupListIndex.append(idx);rec.Feature.LookupCount+=1
 for marks,bases in [(donor_marks,base_names),(primary_marks,donor_bases)]:
  if not marks or not bases:continue
  # All three classes must be represented, even if one source lacks a group.
  used=sorted({classes[m] for m in marks});ids={g:i for i,g in enumerate(used)}
  sub=b.buildMarkBasePosSubtable({n:(ids[classes[n]],mark_anchor(n)) for n in marks},{n:{ids[g]:target_anchor(n,g) for g in used} for n in bases},font.getReverseGlyphMap())
  append(b.buildLookup([sub]),'mark')
 for group in ['above','below']:
  all_group={n for n,g in classes.items() if g==group}
  for incoming,targets in [(donor_marks&all_group,all_group),(primary_marks&all_group,donor_marks&all_group)]:
   if not incoming or not targets:continue
   mm=b.MarkMarkPosBuilder(font,None);mm.marks={n:(group,mark_anchor(n)) for n in incoming};mm.baseMarks={n:{group:target_anchor(n,group)} for n in targets}
   append(mm.build(),'mkmk')
