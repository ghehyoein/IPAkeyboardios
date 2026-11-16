# ipa+ font

A phonetic font for IPA, extended phonetic notation, and the input inventory of **ipa+ keyboard**. The font is distributed under the **SIL Open Font License 1.1**, separately from the application's source-code license.

**Current font version: 0.600** · **1,308 Unicode code points**

[Download ipa-plus.ttf](https://github.com/ghehyoein/IPAkeyboardios/raw/refs/heads/main/Font/ipa-plus.ttf) · [Sources and license](SOURCES_AND_LICENSE.md) · [Changes](CHANGELOG.md)

## Installation and use

- On macOS or Windows, open the TTF and use the system font installer. Select **ipa+** in an application that supports font selection.
- On iOS and iPadOS, use a font-management app or an application that imports custom fonts. Installing a font does not replace the system font or force other apps to use it.
- Developers can embed the font under the OFL conditions. Family name: `ipa+`; PostScript name: `IPAPlus-Regular`.
- Keep [Font-Licenses.txt](Font-Licenses.txt) with redistributed copies. Embedding in commercial software is permitted under OFL; selling the font by itself is not.

Coverage follows the keyboard's current input inventory, not all of Unicode. Combining-mark rendering also depends on the host application's shaping and layout engine.

## This edition

159 formerly pixel-shaped mapped glyphs have been replaced with vector constructions. Twelve of those glyphs were subsequently drawn anew with contrasting stroke weights, coordinated terminals, clearer counters, and distinct capital/lowercase proportions. Cross-source combining-mark anchors were updated to match the outlines.

The existing 51-character supplement is retained. It includes project-made adaptations of licensed Charis/Gentium components; it is not a set of 51 wholly independent drawings. See [supplement provenance](supplement-provenance.json) and the [source documentation](SOURCES_AND_LICENSE.md).

## Files

| File | Purpose |
| --- | --- |
| [ipa-plus.ttf](ipa-plus.ttf) | Complete standalone font |
| [Font-Licenses.txt](Font-Licenses.txt) | Copyright notices and complete OFL 1.1 text |
| [SOURCES_AND_LICENSE.md](SOURCES_AND_LICENSE.md) | Source inventory, construction history, and licensing |
| [unified-coverage.json](unified-coverage.json) | Current coverage, assignments, input hashes, and font checksum |
| [glyph-provenance.json](glyph-provenance.json) | Construction records for the 159 replacement glyphs, including the 12 new drawings |
| [supplement-provenance.json](supplement-provenance.json) | Component records for the unchanged 51-character supplement |
| [validation.json](validation.json) | Coverage, contour, and positioning checks for this font file |
| [licenses/](licenses/) | Original licenses for the vector sources used in the replacement work |

SHA-256 of the TTF: `ac8e01c6c4ede57d08bcfed80777ae1403320143ec0ecc0181f9da996bf323b8`.

## App integration and validation

This folder publishes the standalone font. The application resource at `Shared/Fonts/ipa-plus.ttf` is a separately maintained, older bundled version; this publication does not update the App or create an App release. Download links here point to this folder, rather than older App-release assets.

The published file passed coverage checks for 1,651 catalog strings, 456 direct combining-mark attachment checks, 36 stacked-mark checks, and expected contour/counter checks for the twelve new drawings. It has not yet been validated with iOS CoreText or physical-device keyboard layouts.

The existing `tools/fonts` build pipeline describes the older App-bundled baseline. It does not reproduce this standalone edition by itself. When updating this folder, keep the binary, checksums, provenance, notices, and validation records together.
