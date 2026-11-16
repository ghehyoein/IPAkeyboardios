# ipa+ font: sources and licensing

The current standalone **ipa+ font 0.600** is published in the repository's [Font folder](Font/README.md).

- [Download the TTF](https://github.com/ghehyoein/IPAkeyboardios/raw/refs/heads/main/Font/ipa-plus.ttf)
- [Complete source and licensing documentation](Font/SOURCES_AND_LICENSE.md)
- [Copyright notices and full SIL OFL 1.1 license](Font/Font-Licenses.txt)
- [Current coverage, source assignments, and hashes](Font/unified-coverage.json)
- [159-glyph construction records, including the twelve new drawings](Font/glyph-provenance.json)
- [51-character supplement provenance](Font/supplement-provenance.json)
- [Validation record](Font/validation.json) and [font changelog](Font/CHANGELOG.md)

## Current edition

The font covers **1,308 Unicode code points**. It replaces 159 formerly pixel-shaped mapped glyphs with vector constructions, including twelve newly drawn outlines, and updates combining-mark anchors. The existing 51-character Charis/Gentium-based supplement is retained.

Family name: `ipa+`. PostScript name: `IPAPlus-Regular`. Font size: **265,064 bytes**.

SHA-256: `ac8e01c6c4ede57d08bcfed80777ae1403320143ec0ecc0181f9da996bf323b8`.

## License

The complete font is distributed under **SIL Open Font License 1.1**, independently of the application's source-code license. It may be modified, embedded, and bundled with commercial software under OFL; it may not be sold by itself. Retain the original copyright notices and complete license when redistributing it.

Sources include Charis, Gentium, BabelStone Roman, Noto Sans Math, Noto Sans Georgian, and project constructions. Historical Unifont notices from the merged baseline remain preserved. The [detailed documentation](Font/SOURCES_AND_LICENSE.md) distinguishes retained source outlines, adapted components, and newly drawn contours. Project contributions do not transfer upstream copyrights or establish exclusive ownership of the complete font.

## Standalone font and App resource

This publication updates **Font/ipa-plus.ttf**. The App continues to use the separately maintained, older resource in **Shared/Fonts/ipa-plus.ttf**. The original App build/source records and older GitHub App-release font assets describe that bundled baseline, not the current standalone font.

The new standalone font has passed the checks recorded above; iOS CoreText and physical-device keyboard layout verification remain outstanding. Installing a font on iOS does not replace system fonts or force other applications to use it.
