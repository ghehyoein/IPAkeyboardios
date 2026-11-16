# ipa+ Font: Sources and Licensing

This document records the sources, modifications, and licensing of the **ipa+** font distributed with ipa+ keyboard. Authorization comes from the upstream licenses; this document is not a separately issued commercial license certificate or copyright registration.

## Font file

- Family name: **ipa+**. PostScript name: `IPAPlus-Regular`.
- Repository file: [ipa-plus.ttf](Shared/Fonts/ipa-plus.ttf).
- Downloads: [TTF](https://github.com/ghehyoein/IPAkeyboardios/releases/latest/download/ipa-plus.ttf) · [Font package with licenses and coverage report](https://github.com/ghehyoein/IPAkeyboardios/releases/latest/download/ipa-plus-font.zip).
- The documented file covers 1,308 Unicode code points and contains 1,469 glyphs, including composite and shaping dependencies. Its size is 248,288 bytes. Coverage targets the keyboard's current input inventory, not all of Unicode.
- SHA-256: `77b0ce4f0ba81c4f350b146afff641ff948442a7b74e5feab7b8470b7a3697ce`.

## Upstream sources

| Source | Version and official source | Contribution to ipa+ | License used |
| --- | --- | --- | --- |
| Charis | [7.000, official SIL release](https://github.com/silnrsi/font-charis/releases/tag/v7.000) | Primary source: 985 directly selected code points; also supplies components for 50 of the 51 supplementary characters | SIL OFL 1.1 |
| Gentium | [7.000, official SIL release](https://github.com/silnrsi/font-gentium/releases/tag/v7.000) | Supplies the base ψ outline for U+1DFF3 through the supplement | SIL OFL 1.1 |
| BabelStone Roman | [16.000, official font page](https://www.babelstone.co.uk/Fonts/Roman.html) | Supplies 113 additional code points | SIL OFL 1.1 |
| GNU Unifont | [18.0.01, official release directory](https://unifoundry.com/pub/unifont/unifont-18.0.01/font-builds/) · [Project information](https://unifoundry.com/unifont/) | The ordinary file supplies 61 code points; the upper file supplies 98 | The SIL OFL 1.1 licensing option offered for these compiled fonts |
| IPA Plus Supplement | [Supplement font](Reference/Fonts/IPAPlusSupplement-Regular.ttf) · [Per-character provenance](Reference/Fonts/supplement-provenance.json) | 51 supplementary characters derived from OFL-licensed Charis/Gentium components and additional outline constructions | [SIL OFL 1.1](Reference/Fonts/Supplement-OFL.txt) |

The supplement is merged into the final TTF and does not require separate installation. Gentium's contribution is included in the supplement's 51 characters, not counted again.

The original copyright and Reserved Font Name notices are reproduced below. The derivative uses the new name **ipa+**, rather than the upstream Reserved Font Names Charis, Gentium, SIL, or BabelStone. Attribution does not imply endorsement by upstream authors.

## Merging and modifications

The build selects required code points in this order: Charis, the supplement, BabelStone, Unifont, and Unifont Upper. It merges them into one font and removes unused mappings while retaining glyph dependencies needed for composite outlines and shaping.

Supplementary characters have adjusted scale, placement, and proportions; some also include newly constructed hooks, bars, or openings. The build retains required OpenType shaping features and adds anchors for combining marks across source fonts. Some rare Unifont-derived glyphs retain pixel-shaped outlines.

No fonts or example-image outlines extracted from Unicode reference charts are embedded. Unicode character names, code points, and combining properties are used for identification and positioning; the data license is recorded separately in [Unicode LICENSE](Reference/Unicode/LICENSE.txt). Permission to use the font outlines comes from the upstream OFL licenses, not from making them look slightly different from reference images.

## Rights in the 51 supplementary glyphs

These 51 glyphs are derivative constructions, not 51 wholly independent drawings. The provenance records identify Charis components for 50 and a Gentium component for one. Of these, 43 are recorded as transformations of licensed base outlines, and eight include additional outline construction while still using Charis components.

Upstream rights in those components remain with their respective rightsholders. Any copyright that arises in eligible original contributions is distinct from those upstream rights. Its existence and ownership depend on authorship, applicable law, and relevant agreements; scaling, moving, or mechanically modifying an outline does not automatically create a new exclusive copyright. AI-assisted or AI-generated contributions also require an assessment of protectable human authorship under applicable law.

The provenance records document technical sources and changes; they do not establish exclusive ownership of all 51 glyphs by the project owner. Any protectable additions remain subject to the OFL distribution requirements when distributed as part of this derivative font. OFL licensing does not itself transfer copyright ownership to the public.

## Use and redistribution

**The complete ipa+ font is distributed under the SIL Open Font License 1.1.** Its license is separate from the application source-code license.

- Use, embedding, modification, and redistribution are permitted under the OFL conditions, including bundling with commercial apps.
- The font or its individual components may not be sold by themselves; bundling and sale with software are permitted.
- Redistribution must retain the applicable copyright notices and complete license. Modified font versions must remain under the OFL and comply with Reserved Font Name restrictions.
- Upstream authors' or rightsholders' names may not be used to promote or endorse a modified font without permission, except to acknowledge their contributions.
- Documents and images created using the font do not have to adopt the OFL merely because they use the font.

This is a reading aid; the complete English license below governs. The license provides the font as is, without warranties, including a warranty of noninfringement. This document records provenance and licensing rather than independently certifying rights.

The complete notices are also distributed in [Font-Licenses.txt](Shared/Fonts/Font-Licenses.txt) and embedded in the TTF name table: name ID 0 contains the copyright and source notices, name ID 13 contains the OFL text, and name ID 14 links to the official license page.

## Verifiable source records

- [Download URLs and SHA-256 hashes](tools/fonts/sources.json): pinned hashes prevent silently accepting changed upstream files.
- [Final coverage and per-code-point source assignments](Reference/Fonts/unified-coverage.json).
- [Base outlines, transformations, and source hashes for the 51 supplementary characters](Reference/Fonts/supplement-provenance.json).
- [Build instructions](tools/fonts/README.txt) and [merge script](tools/fonts/build.py).

SHA-256 hashes of the font inputs used in this build follow. For archived fonts, hashes refer to the extracted font files, not the archives.

| File | SHA-256 |
| --- | --- |
| `Charis-Regular.ttf` | `c03738834bd3a43c3e4a59b11878bd6ede3ee505998242ae649ed1f9cd2edcf6` |
| `IPAPlusSupplement-Regular.ttf` | `cf7afc9bef927e3d6360005aa648c425420f4bbda24c40766bfc499859d11ad3` |
| `BabelStoneRoman.ttf` | `ffa5663ef462ac7510587cb1bd93ca1d2173567006c0a19a654c48c28cce8a6a` |
| `unifont-18.0.01.otf` | `88d0a14d4aa9a96419720b39ba5da921a59560d76d4ec7d523acc06ed85cd3c2` |
| `unifont_upper-18.0.01.otf` | `472201e45a050bff4c7658208b8c73e34ebce3764b287a5a46c7774038ef9391` |
| `Gentium-Regular.ttf` (supplement source) | `158d89548ef28f62abfc2921878fa253b833111e8d3932da7f501daef6d0eccf` |

## Distributed copyright notices and complete license

The following text matches `Font-Licenses.txt` in this repository.

```text
ipa+ — SIL Open Font License 1.1

Modified and merged font. The original notices below remain applicable.

Charis
Copyright (c) 1997-2025 SIL Global (https://www.sil.org/) with Reserved Font Names "Charis" and "SIL".

Gentium
Copyright (c) 2003-2025 SIL Global (https://www.sil.org/) with Reserved Font Names "Gentium" and "SIL".

BabelStone Roman
Copyright (c) SIL International, 1994-2014; Andrew West, 2014-2024.
Copyright (c) 2015-2024, Andrew West with Reserved Font Names "BabelStone".

Unifont
Copyright © 1998-2026 Roman Czyborra, Paul Hardy, Qianqian Fang, Andrew Miller, Johnnie Weaver, David Corbett, Ælla Chiana Moskopp, Rebecca Bettencourt, Ho-Seok Ee, et al.
The compiled Unifont fonts are used under their SIL OFL 1.1 option.

SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font creation
efforts of academic and linguistic communities, and to provide a free and
open framework in which fonts may be shared and improved in partnership
with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply
to any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software components as
distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software to a
new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed, modify,
redistribute, and sell modified and unmodified copies of the Font
Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components,
in Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the corresponding
Copyright Holder. This restriction only applies to the primary font name as
presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created
using the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
```
