"""Render every project-contributed glyph from the released ipa+ font.

Requires Pillow (with FreeType/RAQM) and fontTools. No fallback fonts are used
for the specimens. The two provenance inventories define the complete scope.
"""
from pathlib import Path
import json
import math
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / 'Font/ipa-plus.ttf'
OUTPUT = ROOT / 'Font/previews/ipa-plus-original-glyphs.png'


def main():
    provenance = json.loads((ROOT / 'Font/glyph-provenance.json').read_text())['glyphs']
    supplement = json.loads((ROOT / 'Font/supplement-provenance.json').read_text())
    groups = [
        ('01  Newly drawn', '48 original vector glyphs', [g for g in provenance if g['category'] in ('ProjectOutlines', 'ProjectVectors')]),
        ('02  Adapted from licensed fonts', '100 Charis / Gentium-based adaptations', [g for g in provenance if g['category'] in ('CharisDerived', 'GentiumDerived')]),
        ('03  Supplement', '51 glyphs adapted from licensed Charis / Gentium components', supplement),
    ]
    assert [len(g[2]) for g in groups] == [48, 100, 51]
    entries = [g for _, _, group in groups for g in group]
    assert len({g['codepoint'] for g in entries}) == 199
    cmap = TTFont(FONT).getBestCmap()
    assert 0x25CC in cmap
    assert all(int(g['codepoint'][2:], 16) in cmap for g in entries)
    margin, columns, cell_width, cell_height = 70, 10, 186, 205
    width = margin * 2 + columns * cell_width
    total_rows = sum(math.ceil(len(g[2]) / columns) for g in groups)
    height = 280 + len(groups) * 110 + total_rows * cell_height + 110 + 64
    image = Image.new('RGB', (width, height), '#faf9f6')
    draw = ImageDraw.Draw(image)
    ink, muted, line = '#20201e', '#62625e', '#deded7'
    font = ImageFont.truetype(str(FONT), 124)
    brand = ImageFont.truetype(str(FONT), 85)
    ui = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    label = ImageFont.truetype(ui, 19)
    body = ImageFont.truetype(ui, 24)
    heading = ImageFont.truetype(ui, 30)
    draw.text((margin, 35), 'ipa+', font=brand, fill=ink)
    draw.text((margin, 150), 'All 199 project-contributed glyphs by ghehyoein', font=heading, fill=ink)
    draw.text((margin, 199), '48 newly drawn + 151 adapted from licensed fonts', font=body, fill=muted)
    draw.text((width-margin, 85), 'FONT 0.601', font=body, fill=muted, anchor='ra')
    y = 280
    rendered = []
    for group_index, (title, subtitle, group) in enumerate(groups):
        if group_index:
            y += 32
        draw.text((margin, y), title, font=heading, fill=ink)
        draw.text((margin, y+45), subtitle, font=body, fill=muted)
        y += 110
        for index, entry in enumerate(sorted(group, key=lambda g: int(g['codepoint'][2:], 16))):
            row, col = divmod(index, columns)
            x, cell_y = margin + col * cell_width, y + row * cell_height
            cp = int(entry['codepoint'][2:], 16)
            name = entry.get('unicode_name', entry.get('name', ''))
            # Dotted circle is a positioning aid for combining marks only.
            text = ('\u25cc' if name.startswith('COMBINING ') else '') + chr(cp)
            draw.text((x+12, cell_y+12), entry['codepoint'], font=label, fill=muted)
            specimen = font
            left, top, right, bottom = draw.textbbox((0, 0), text, font=specimen)
            scale = min(1, (cell_width-28)/max(right-left, 1), (cell_height-58)/max(bottom-top, 1))
            if scale < 1:
                specimen = ImageFont.truetype(str(FONT), int(124*scale))
                left, top, right, bottom = draw.textbbox((0, 0), text, font=specimen)
            draw.text((x+(cell_width-(right-left))/2-left, cell_y+48+(cell_height-58-(bottom-top))/2-top), text, font=specimen, fill=ink)
            if col:
                draw.line((x, cell_y+10, x, cell_y+cell_height-10), fill=line)
            if col == 0:
                draw.line((margin, cell_y, width-margin, cell_y), fill=line)
            rendered.append(cp)
        y += math.ceil(len(group)/columns)*cell_height
        draw.line((margin, y, width-margin, y), fill=line)
    assert len(rendered) == len(set(rendered)) == 199
    draw.text((margin, y+32), 'Actual font rendering. Dotted circles show combining-mark placement.', font=label, fill=muted)
    draw.text((margin, y+65), 'Upstream attribution is retained for adapted glyphs. SIL Open Font License 1.1.', font=label, fill=muted)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, optimize=True)
    print(f'{OUTPUT}: {width} x {height}, {len(rendered)} distinct project glyphs')


if __name__ == '__main__':
    main()
