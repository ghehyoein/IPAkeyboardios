"""Refine the approved 0.600 font without rebuilding or tracing its outlines.

Adds 26 OFL Noto Sans Symbols glyphs and contextual parenthesis variants for
ring/caron marks. Existing character outlines and general stacking stay intact.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables as ot
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.feaLib.builder import addOpenTypeFeaturesFromString
from fontTools.otlLib import builder as b

BASE_SHA = 'ac8e01c6c4ede57d08bcfed80777ae1403320143ec0ecc0181f9da996bf323b8'
SYMBOLS_SHA = 'f7e7e04b4a24b6c78893d50cbfd2b2f6cae49617ab047bfef668d252adb128f7'


def draw_into(source, name, pen, transform):
    recording = DecomposingRecordingPen(source.getGlyphSet())
    source.getGlyphSet()[name].draw(recording)
    recording.replay(TransformPen(pen, transform))


def ink(font, name):
    g = font['glyf'][name]
    g.recalcBounds(font['glyf'])
    return g.xMin, g.yMin, g.xMax, g.yMax


def append_lookup(font, lookup, feature):
    table = font['GPOS'].table
    index = len(table.LookupList.Lookup)
    table.LookupList.Lookup.append(lookup)
    table.LookupList.LookupCount = len(table.LookupList.Lookup)
    for record in table.FeatureList.FeatureRecord:
        if record.FeatureTag == feature:
            record.Feature.LookupListIndex.append(index)
            record.Feature.LookupCount = len(record.Feature.LookupListIndex)


def effective_base_offsets(font, mark):
    result = {}
    for lookup in font['GPOS'].table.LookupList.Lookup:
        for sub in lookup.SubTable:
            kind = lookup.LookupType
            if kind == 9:
                kind, sub = sub.ExtensionLookupType, sub.ExtSubTable
            if kind != 4 or mark not in sub.MarkCoverage.glyphs:
                continue
            rec = sub.MarkArray.MarkRecord[sub.MarkCoverage.glyphs.index(mark)]
            for name, base in zip(sub.BaseCoverage.glyphs, sub.BaseArray.BaseRecord):
                anchor = base.BaseAnchor[rec.Class]
                if anchor:
                    result[name] = b.buildAnchor(anchor.XCoordinate-rec.MarkAnchor.XCoordinate,
                                                 anchor.YCoordinate-rec.MarkAnchor.YCoordinate)
    return result


def append_context_substitutions(font, feature_text):
    temporary = TTFont()
    temporary.setGlyphOrder(font.getGlyphOrder())
    addOpenTypeFeaturesFromString(temporary, feature_text)
    existing, added = font['GSUB'].table, temporary['GSUB'].table
    offset = len(existing.LookupList.Lookup)
    def remap(value):
        if isinstance(value, ot.SubstLookupRecord):
            value.LookupListIndex += offset
        elif isinstance(value, list):
            for child in value: remap(child)
        elif hasattr(value, '__dict__'):
            for child in vars(value).values(): remap(child)
    lookups = copy.deepcopy(added.LookupList.Lookup)
    for lookup in lookups: remap(lookup)
    existing.LookupList.Lookup.extend(lookups)
    existing.LookupList.LookupCount = len(existing.LookupList.Lookup)
    indices = next(r.Feature.LookupListIndex for r in added.FeatureList.FeatureRecord if r.FeatureTag == 'ccmp')
    for record in existing.FeatureList.FeatureRecord:
        if record.FeatureTag == 'ccmp':
            record.Feature.LookupListIndex.extend(index+offset for index in indices)
            record.Feature.LookupCount = len(record.Feature.LookupListIndex)


def build(baseline, symbols, output):
    assert hashlib.sha256(baseline.read_bytes()).hexdigest() == BASE_SHA
    assert hashlib.sha256(symbols.read_bytes()).hexdigest() == SYMBOLS_SHA
    font = TTFont(baseline)
    donor = instantiateVariableFont(TTFont(symbols), {'wght': 400}, inplace=True)
    cmap = font.getBestCmap()
    order = list(font.getGlyphOrder())
    for cp in range(0x24B6, 0x24D0):
        name = f'notoSymbols{cp:04X}'
        scale = font['head'].unitsPerEm / donor['head'].unitsPerEm
        old = donor.getBestCmap()[cp]
        pen = TTGlyphPen(None)
        draw_into(donor, old, pen, (scale, 0, 0, scale, 0, 0))
        glyph = pen.glyph(); glyph.recalcBounds(font['glyf'])
        font['glyf'][name] = glyph
        font['hmtx'][name] = (round(donor['hmtx'][old][0]*scale), glyph.xMin)
        order.append(name)
        for table in font['cmap'].tables:
            if table.isUnicode(): table.cmap[cp] = name
    font.setGlyphOrder(order)
    order = list(font.getGlyphOrder())
    mark_groups = [(0x030A, 'above', [0x1ABB,0x1ABC,0x1AC1,0x1AC2]),
                   (0x030C, 'above', [0x1ABB,0x1ABC,0x1AC1,0x1AC2]),
                   (0x0325, 'below', [0x1ABD,0x1AC3,0x1AC4]),
                   (0x032C, 'below', [0x1ABD,0x1AC3,0x1AC4])]
    variants = {}
    features = ['feature ccmp {']
    # HarfBuzz/CoreText can normalize a decomposed base + mark before GSUB.
    # Expand supported precomposed forms only next to enclosing parentheses;
    # ordinary accented text retains its original glyph and positioning.
    import unicodedata
    paren_names = [cmap[c] for c in [0x1ABB,0x1ABC,0x1ABD,0x1AC1,0x1AC2,0x1AC3,0x1AC4]]
    paren_class = '['+' '.join(paren_names)+']'
    for cp, glyph_name in cmap.items():
        nfd = unicodedata.normalize('NFD',chr(cp))
        if len(nfd)==2 and ord(nfd[1]) in [0x030A,0x030C,0x0325,0x032C] and all(ord(c) in cmap for c in nfd):
            expansion = ' '.join(cmap[ord(c)] for c in nfd)
            features.append(f"sub {glyph_name}' {paren_class} by {expansion};")
            features.append(f"sub {paren_class} {glyph_name}' by {expansion};")
    mark_records, base_records = {}, {}
    for cls, (mark_cp, side, parens) in enumerate(mark_groups):
        mark = cmap[mark_cp]
        x0,y0,x1,y1 = ink(font, mark)
        cx,cy = (x0+x1)/2,(y0+y1)/2
        height = y1-y0+160
        gap = x1-x0+110
        left_cp, right_cp = (0x1AC1,0x1AC2) if side == 'above' else (0x1AC3,0x1AC4)
        offsets = effective_base_offsets(font, mark)
        for name, anchor in offsets.items(): base_records.setdefault(name,{})[cls] = anchor
        for paren_cp in parens:
            name = f'ipaParen{paren_cp:04X}For{mark_cp:04X}'
            pen = TTGlyphPen(None)
            is_left = paren_cp in (left_cp,0x1ABB,0x1ABC,0x1ABD)
            is_right = paren_cp in (right_cp,0x1ABB,0x1ABC,0x1ABD)
            for cp, enabled, sign in [(left_cp,is_left,-1),(right_cp,is_right,1)]:
                if not enabled: continue
                source = cmap[cp]
                a,z,c,d = ink(font,source)
                scale = height/(d-z)
                half_width = (c-a)*scale
                repeats = 2 if paren_cp == 0x1ABC else 1
                for repeat in range(repeats):
                    target_x = cx-gap/2-half_width if sign < 0 else cx+gap/2
                    target_x += sign*repeat*(half_width+35)
                    draw_into(font,source,pen,(scale,0,0,scale,target_x-a*scale,cy-height/2-z*scale))
            glyph = pen.glyph(); glyph.recalcBounds(font['glyf'])
            font['glyf'][name] = glyph
            font['hmtx'][name] = (0,glyph.xMin)
            order.append(name)
            variants[name] = {'parenthesis':paren_cp,'mark':mark_cp,'side':side,'center':(round(cx),round(cy))}
            mark_records[name] = (cls,b.buildAnchor(0,0))
            font['GDEF'].table.GlyphClassDef.classDefs[name] = 3
            original = cmap[paren_cp]
            features += [f'sub {mark} {original}\' by {name};', f'sub {original}\' {mark} by {name};']
    # Allow both single-sided parentheses around the same diacritic in either
    # order, including a previously substituted contextual parenthesis.
    for name, data in variants.items():
        mark, original = cmap[data['mark']], cmap[data['parenthesis']]
        neighbors = [cmap[cp] for cp in ([0x1ABB,0x1ABC,0x1AC1,0x1AC2] if data['side']=='above' else [0x1ABD,0x1AC3,0x1AC4])]
        neighbors += [n for n,v in variants.items() if v['side']==data['side']]
        group = '['+' '.join(neighbors)+']'
        features += [f'sub {mark} {group} {original}\' by {name};',
                     f'sub {original}\' {group} {mark} by {name};']
    features.append('} ccmp;')
    font.setGlyphOrder(order)
    append_context_substitutions(font,'\n'.join(features))
    sub = b.buildMarkBasePosSubtable(mark_records,base_records,font.getReverseGlyphMap())
    append_lookup(font,b.buildLookup([sub]),'mark')
    for side in ['above','below']:
        selected = {n:v for n,v in variants.items() if v['side']==side}
        ordinary = {cmap[cp]: ink(font,cmap[cp]) for cp,s,_ in mark_groups if s==side}
        centers = {n:(round((a+c)/2),round((z+d)/2)) for n,(a,z,c,d) in ordinary.items()}
        centers.update({n:v['center'] for n,v in selected.items()})
        for incoming, targets in [(selected,centers),(ordinary,{n:v['center'] for n,v in selected.items()})]:
            builder = b.MarkMarkPosBuilder(font,None)
            builder.marks = {n:(side,b.buildAnchor(*centers[n])) for n in incoming}
            builder.baseMarks = {n:{side:b.buildAnchor(*center)} for n,center in targets.items()}
            append_lookup(font,builder.build(),'mkmk')
    font['name'].setName('ipa+-0.601',3,3,1,0x409)
    font['name'].setName('Version 0.601; enclosed diacritic positioning and circled capitals',5,3,1,0x409)
    font['OS/2'].usMaxContext = max(font['OS/2'].usMaxContext,3)
    font.recalcTimestamp = False
    font.save(output)
    return {'baseline_sha256':BASE_SHA,'source_sha256':SYMBOLS_SHA,'added_characters':[f'U+{cp:04X}' for cp in range(0x24B6,0x24D0)],
            'contextual_parentheses':variants,'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline',type=Path,required=True)
    parser.add_argument('--symbols-source',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    report = build(args.baseline,args.symbols_source,args.output)
    args.output.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n')
    print(args.output,report['sha256'])
