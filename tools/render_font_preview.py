"""Render the approved original glyphs directly from the standalone ipa+ font.

Requires Pillow (with FreeType) and fontTools. Run from any working directory.
"""
from pathlib import Path
import json

from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "Font/ipa-plus.ttf"
OUTPUT = ROOT / "Font/previews/ipa-plus-original-glyphs.png"
CODEPOINTS = [
    0x1DF60, 0x1DF6B, 0x1DF6C, 0x1DF81,
    0x1DF74, 0x1DF75, 0x1DF76, 0x1DF77,
    0x1DF78, 0x1DF79, 0x1DF7C, 0x1DF7D,
]


def main():
    font = TTFont(FONT)
    provenance = {item["codepoint"]: item for item in json.loads(
        (ROOT / "Font/glyph-provenance.json").read_text())["glyphs"]}
    for cp in CODEPOINTS:
        assert cp in font.getBestCmap(), f"Missing U+{cp:04X}"
        assert provenance[f"U+{cp:04X}"]["category"] == "ProjectOutlines"

    # No fallback fonts or redrawn approximations are used for the specimens.
    specimen = ImageFont.truetype(str(FONT), 245)
    title = ImageFont.truetype(str(FONT), 82)
    ui_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    label = ImageFont.truetype(ui_path, 21)
    subtitle = ImageFont.truetype(ui_path, 25)
    image = Image.new("RGB", (1600, 1240), "#faf9f6")
    draw = ImageDraw.Draw(image)
    ink, muted, line = "#20201e", "#62625e", "#deded7"
    draw.text((72, 42), "ipa+", font=title, fill=ink)
    draw.text((73, 146), "Twelve original glyphs by ghehyoein", font=subtitle, fill=muted)
    draw.text((1528, 85), "FONT 0.600", font=label, fill=muted, anchor="ra")

    top, width, height = 219, 364, 300
    draw.line((72, top, 1528, top), fill=line, width=2)
    for index, cp in enumerate(CODEPOINTS):
        row, col = divmod(index, 4)
        x, y = 72 + col * width, top + row * height
        draw.text((x + 24, y + 20), f"U+{cp:04X}", font=label, fill=muted)
        # Shared size and baseline retain the real upper/lowercase proportions.
        draw.text((x + width / 2, y + 251), chr(cp), font=specimen, fill=ink, anchor="ms")
        if col:
            draw.line((x, y + 18, x, y + height - 18), fill=line)
        if col == 0:
            draw.line((72, y + height, 1528, y + height), fill=line)
    draw.text((72, 1165), "Rendered directly from ipa-plus.ttf", font=label, fill=muted)
    draw.text((1528, 1165), "SIL Open Font License 1.1", font=label, fill=muted, anchor="ra")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
