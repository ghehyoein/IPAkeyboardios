# ipa+ 字体：来源与授权许可

本文说明本仓库随 ipa+ keyboard 分发的 **ipa+** 字体的来源、修改方式及许可证。这里的授权依据是上游公开许可证，不是另行签发的商业授权证书或版权登记证书。

## 字体文件

- 字体家族名称：**ipa+**；PostScript 名称：`IPAPlus-Regular`。
- 仓库文件：[ipa-plus.ttf](Shared/Fonts/ipa-plus.ttf)。
- 下载：[字体文件](https://github.com/ghehyoein/IPAkeyboardios/releases/latest/download/ipa-plus.ttf) · [包含许可证和覆盖报告的字体包](https://github.com/ghehyoein/IPAkeyboardios/releases/latest/download/ipa-plus-font.zip)。
- 本文对应的字体文件覆盖 1,308 个 Unicode 码位，含 1,469 个字形（包括复合字形和排版所需的依赖），大小为 248,288 字节。这是当前键盘输入集合的覆盖范围，不代表全部 Unicode。
- SHA-256：`77b0ce4f0ba81c4f350b146afff641ff948442a7b74e5feab7b8470b7a3697ce`。

## 上游来源

| 来源 | 版本及官方来源 | 在 ipa+ 中的用途 | 采用的许可 |
| --- | --- | --- | --- |
| Charis | [7.000，SIL 官方发布](https://github.com/silnrsi/font-charis/releases/tag/v7.000) | 主体字形，直接提供 985 个码位；另外参与 51 字符补充字体中的 50 个字符构造 | SIL OFL 1.1 |
| Gentium | [7.000，SIL 官方发布](https://github.com/silnrsi/font-gentium/releases/tag/v7.000) | 通过补充字体提供 U+1DFF3 的基础 ψ 字形 | SIL OFL 1.1 |
| BabelStone Roman | [16.000，官方字体页面](https://www.babelstone.co.uk/Fonts/Roman.html) | 补充 113 个码位 | SIL OFL 1.1 |
| GNU Unifont | [18.0.01，官方发布目录](https://unifoundry.com/pub/unifont/unifont-18.0.01/font-builds/)；[项目说明](https://unifoundry.com/unifont/) | 普通文件补充 61 个码位，upper 文件补充 98 个码位 | 采用这些编译字体提供的 SIL OFL 1.1 授权选项 |
| IPA Plus Supplement | [仓库中的补充字体](Reference/Fonts/IPAPlusSupplement-Regular.ttf)及[逐字符来源](Reference/Fonts/supplement-provenance.json) | 51 个补充字符，由已获 OFL 授权的 Charis/Gentium 部件及自行构造的轮廓形成 | [SIL OFL 1.1](Reference/Fonts/Supplement-OFL.txt) |

补充字体已包含在最终的单一 TTF 内，不需要另行安装。上表中的 Gentium 贡献包含在补充字体的 51 个字符内，不重复计数。

上游字体的版权与保留名称声明见文末原文。修改后的字体使用新名称 **ipa+**，不使用上游的保留字体名称 Charis、Gentium、SIL、BabelStone 作为字体名称，也不表示上游作者为此衍生字体背书。

## 合并与修改

构建按 Charis、补充字体、BabelStone、Unifont、Unifont Upper 的顺序选取所需码位，合并到单一字体文件，并裁剪未使用的映射；复合轮廓和排版功能需要的字形依赖会保留。

补充字符经过缩放、位置和比例调整，部分还包含自行构造的钩、横线或开口。构建保留所需的 OpenType 排版功能，并补充跨来源组合附加符号的定位锚点。部分罕见 Unifont 来源字形仍保留点阵式轮廓。

本字体没有嵌入从 Unicode 码表提取的参考字体或示例图片轮廓。字符名称、码位和组合类别等数据用于字符识别及定位；Unicode 数据的许可证另见 [Unicode LICENSE](Reference/Unicode/LICENSE.txt)。字体轮廓的授权依据是上游 OFL 许可，而不是与参考图形“略有不同”。

## 使用与再分发条件

**ipa+ 字体整体按 SIL Open Font License 1.1 分发。** 该字体许可独立于 App 源码的许可。

- 可在遵守 OFL 条件时使用、嵌入、修改和再分发，包括随商业 App 分发。
- 字体及其单独组件不可单独出售；可以随软件捆绑销售。
- 再分发时必须保留适用的版权声明和完整许可证；修改版字体仍须按 OFL 分发，并遵守保留字体名称限制。
- 不得未经许可使用上游作者或权利人名称为修改版宣传背书；说明来源和贡献除外。
- 使用字体制作的文档或图片不因此必须采用 OFL。

以上是便于阅读的摘要，完整条款以文末英文原文为准。许可证按原样提供字体，不提供包括不侵权在内的担保；本文记录来源和许可，不构成独立的权利认证。

完整声明也随 [Font-Licenses.txt](Shared/Fonts/Font-Licenses.txt) 分发，并嵌入 TTF 的 name 表：name ID 0 保存版权及来源声明，name ID 13 保存 OFL 正文，name ID 14 指向官方许可页面。

## 可核查的来源记录

- [下载地址与文件 SHA-256](tools/fonts/sources.json)：构建输入采用固定哈希校验，防止上游文件更新后被静默替换。
- [最终字体覆盖与逐码位来源](Reference/Fonts/unified-coverage.json)。
- [51 个补充字符的基础字形、变换和来源哈希](Reference/Fonts/supplement-provenance.json)。
- [构建说明](tools/fonts/README.txt)及[合并脚本](tools/fonts/build.py)。

以下是本次合并输入文件的 SHA-256（压缩包中的字体使用解压后文件的哈希）：

| 文件 | SHA-256 |
| --- | --- |
| `Charis-Regular.ttf` | `c03738834bd3a43c3e4a59b11878bd6ede3ee505998242ae649ed1f9cd2edcf6` |
| `IPAPlusSupplement-Regular.ttf` | `cf7afc9bef927e3d6360005aa648c425420f4bbda24c40766bfc499859d11ad3` |
| `BabelStoneRoman.ttf` | `ffa5663ef462ac7510587cb1bd93ca1d2173567006c0a19a654c48c28cce8a6a` |
| `unifont-18.0.01.otf` | `88d0a14d4aa9a96419720b39ba5da921a59560d76d4ec7d523acc06ed85cd3c2` |
| `unifont_upper-18.0.01.otf` | `472201e45a050bff4c7658208b8c73e34ebce3764b287a5a46c7774038ef9391` |
| `Gentium-Regular.ttf`（补充字形来源） | `158d89548ef28f62abfc2921878fa253b833111e8d3932da7f501daef6d0eccf` |

## 随字体分发的版权声明及完整许可证

以下原文与仓库中的 `Font-Licenses.txt` 一致。

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
