# ipa+ font

A phonetic font distributed under the **SIL Open Font License 1.1**, independently of the keyboard application's source-code license. The font may be embedded in commercial software under the OFL conditions.

## Files

| File | Purpose |
| --- | --- |
| [ipa-plus.ttf](ipa-plus.ttf) | Ready-to-install font; family name **ipa+**, PostScript name `IPAPlus-Regular` |
| [Font-Licenses.txt](Font-Licenses.txt) | Required upstream copyright notices and complete OFL 1.1 license |
| [SOURCES_AND_LICENSE.md](SOURCES_AND_LICENSE.md) | Sources, modifications, licensing conditions, and rights information for the 51 supplementary glyphs |
| [unified-coverage.json](unified-coverage.json) | Coverage, per-code-point sources, and file hashes |
| [supplement-provenance.json](supplement-provenance.json) | Component sources and transformations for the 51 supplementary glyphs |

[Download the TTF](https://github.com/ghehyoein/IPAkeyboardios/raw/refs/heads/main/Font/ipa-plus.ttf) · [Release package](https://github.com/ghehyoein/IPAkeyboardios/releases/latest/download/ipa-plus-font.zip)

The current font covers 1,308 Unicode code points in the keyboard's input inventory. It does not cover all of Unicode. Some rare glyphs retain pixel-shaped outlines. Installing the font on iOS does not replace system fonts; other apps must support selecting it.

Keep the copyright notices and full license when redistributing the font. The font may not be sold by itself. See the complete license for all conditions.

## Maintaining this directory

This directory provides a standalone distribution copy. The app continues to bundle the identical font from `Shared/Fonts/ipa-plus.ttf`. When regenerating the font, update this copy, the notices, and the coverage/provenance records together. The source documentation is maintained in `FONT_SOURCES_AND_LICENSE.md`; keep this directory's copy in sync, adjusting relative links.

See the [build instructions](../tools/fonts/README.txt) for the build inputs and validation commands.
