# ipa+ font: sources and licensing

This document describes the standalone **ipa+ 0.600** font in [Font/](README.md). It records technical provenance and licensing; it is not a copyright registration or an independent legal-clearance certificate.

## Distributed file

- File: [ipa-plus.ttf](ipa-plus.ttf).
- Family: **ipa+**; PostScript name: `IPAPlus-Regular`.
- Coverage: **1,308 code points**, **1,469 glyphs** including shaping/composite dependencies, **265,064 bytes**.
- SHA-256: `ac8e01c6c4ede57d08bcfed80777ae1403320143ec0ecc0181f9da996bf323b8`.
- Complete license and notices: [Font-Licenses.txt](Font-Licenses.txt), also embedded in the font's name table.

This publication is separate from the older App resource at `Shared/Fonts/ipa-plus.ttf`. The App's existing release downloads and baseline build records should not be treated as records for this file.

## Upstream sources

| Source | Version / official source | Contribution | License |
| --- | --- | --- | --- |
| Charis | [7.000](https://github.com/silnrsi/font-charis/releases/tag/v7.000) | 985 retained direct mappings, components for 87 reconstructed mappings, and components in the supplement | SIL OFL 1.1 |
| Gentium | [7.000](https://github.com/silnrsi/font-gentium/releases/tag/v7.000) | 11 reconstructed mappings and the supplement's psi component | SIL OFL 1.1 |
| BabelStone Roman | [16.000](https://www.babelstone.co.uk/Fonts/Roman.html) | 113 retained direct mappings | SIL OFL 1.1 |
| Noto Sans Math | [3.000](https://github.com/notofonts/math) | 12 exact-code-point vector outlines, including mathematical brackets and arrows | SIL OFL 1.1 |
| Noto Sans Georgian | [2.005](https://github.com/notofonts/georgian) | U+10DD | SIL OFL 1.1 |
| IPA Plus Supplement | [Provenance records](supplement-provenance.json) | 51 adapted supplementary characters | SIL OFL 1.1 |
| GNU Unifont / Unifont Upper | [18.0.01](https://unifoundry.com/pub/unifont/unifont-18.0.01/font-builds/) | Historical merged baseline; its 159 mapped assignments are replaced in this edition | Compiled fonts' SIL OFL 1.1 option; original notices retained |

The remaining 48 replacement mappings are project vector constructions, including the twelve new drawings. Source counts refer to final mapped assignments; components and inherited notices are documented separately. Input versions, hashes, and final assignments are in [unified-coverage.json](unified-coverage.json).

## The 51-character supplement

The unchanged supplement uses licensed Charis components for 50 characters and a Gentium psi component for one. Its records describe 43 glyphs made primarily through scale, placement, and proportion changes, and eight with additional outline construction: a return hook, two cut openings, three added crossbars, and two joined consonant constructions.

These are project-made adaptations, not a claim that all 51 glyphs were drawn from scratch. Original upstream rights and notices remain applicable. [Per-character supplement records](supplement-provenance.json) identify the components and transformations.

## The 159 replacement glyphs and twelve new drawings

The original merged baseline assigned 159 code points to Unifont/Unifont Upper. This edition replaces those mapped outlines with 87 Charis-based constructions, 11 Gentium-based constructions, 12 exact-code-point Noto Sans Math outlines, one Noto Sans Georgian outline, 36 project vector constructions, and twelve newly drawn project outlines. These categories total 159 and do not count the 51-character supplement again.

The twelve drawings replace earlier constructions for U+1DF60, U+1DF6B, U+1DF6C, U+1DF74–U+1DF79, U+1DF7C, U+1DF7D, and U+1DF81. Their filled Bezier contours were written anew; the old target contours and Unicode chart outlines were not used as outline input. Capital/lowercase pairs share new construction logic with optical proportion adjustments; lowercase u has separate entry and exit details. This describes programmatic construction, not human hand-drawing or exclusive ownership of the entire font.

The replacement work also corrects character components, connected strokes, and combining-mark attachment. [Glyph provenance](glyph-provenance.json) records the final construction for each affected code point. Historical Unifont copyright notices remain preserved from the merged baseline; the current per-code-point assignments identify the replacement sources.

## License and permitted use

The complete font is distributed under **SIL Open Font License 1.1**, independently of the application's PolyForm Noncommercial source-code license.

- Use, modification, embedding, and redistribution are permitted under OFL, including bundling with commercial software.
- The font or its individual components may not be sold by themselves.
- Redistributed copies must retain applicable copyright notices and the complete license; modified font versions remain under OFL.
- The derivative family name **ipa+** does not use the donors' Reserved Font Names. Upstream attribution does not imply endorsement.
- A document or image does not become subject to OFL merely because it was typeset with the font.

The complete [license text](Font-Licenses.txt) governs. It includes the OFL warranty disclaimer. Any copyright arising in eligible project contributions is separate from upstream rights and depends on authorship and applicable law; neither technical provenance nor AI-assisted construction establishes exclusive ownership of upstream material.

Unicode character definitions and reference shapes inform identification and structure. No extracted Unicode-chart font outlines or reference images are embedded in the TTF. The permission to adapt and merge source fonts comes from their licenses, not from making the result look different. Unicode data has its [separate license](../Reference/Unicode/LICENSE.txt).

## Verification and maintenance

[validation.json](validation.json) identifies the published file and records coverage, expected contour/counter checks, 456 direct mark-attachment checks, and 36 stacked-mark checks. Twenty-four additional cases undergo canonical decomposition and are recorded separately from direct attachment checks. These checks do not substitute for iOS CoreText or device testing.

The older baseline pipeline under `tools/fonts` does not recreate this standalone edition without the subsequent reconstruction and redraw work. Keep the distributed binary, current provenance, coverage report, validation records, and notices together when maintaining this folder.
