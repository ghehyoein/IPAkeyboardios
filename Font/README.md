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

## Project-made contributions to the 51 supplementary glyphs

The supplement includes work carried out for this project, rather than simply copying a ready-made set of superscript and subscript glyphs. OFL-licensed Charis/Gentium components were adapted with changes to scale, superscript or subscript placement, optical proportions, and spacing.

The provenance records describe 43 glyphs made primarily by transforming licensed base outlines and eight with additional outline work:

- **U+1DFCD:** a newly drawn rounded return hook added to a licensed turned-r base.
- **U+1DFCE and U+1DFCF:** openings cut into licensed o/u outlines.
- **U+1DFD7, U+1DFD8, and U+1DFDB:** horizontal bars added at selected heights on licensed bases.
- **U+1DFE0 and U+1DFE4:** licensed consonant outlines joined while preserving their distinguishing curls.

These are project-made adaptations and constructions, not a claim that all 51 glyphs were drawn from scratch or that upstream copyrights have transferred to the project. The original notices remain applicable and the resulting font is distributed under OFL 1.1. Whether any added elements qualify for separate copyright depends on applicable law and the specific creative contribution.

See the [per-glyph provenance records](supplement-provenance.json) for component sources and transformations.

## Maintaining this directory

This directory provides a standalone distribution copy. The app continues to bundle the identical font from `Shared/Fonts/ipa-plus.ttf`. When regenerating the font, update this copy, the notices, and the coverage/provenance records together. The source documentation is maintained in `FONT_SOURCES_AND_LICENSE.md`; keep this directory's copy in sync, adjusting relative links.

See the [build instructions](../tools/fonts/README.txt) for the build inputs and validation commands.
