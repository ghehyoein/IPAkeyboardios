# 标准表来源

International Phonetic Association, *The International Phonetic Alphabet*, © 2026 IPA. 页底注明 “IPA Chart revised to 2015/2005”。

- 总表页面：https://www.internationalphoneticassociation.org/content/ipa-chart
- 原 PDF：https://www.internationalphoneticassociation.org/IPAcharts/common_files/pdfs/pdfs_IPA_charts_E/IPA_Kiel.pdf
- 获取日期：2026-11-09 UTC。
- 仓库仅保留来源说明，PDF 可通过上述官方链接下载。表中标注 Creative Commons Attribution-ShareAlike，具体授权参见官网说明：https://creativecommons.org/licenses/by-sa/4.0/

符号库是按官方表视觉核对的 Unicode 输入清单；字母键的滑动和长按分组是本项目的输入法设计，不是协会提供或认可的映射。未复制官方图表到 App 界面；参考 PDF 不打包进入应用。

## 扩充资料

- [Unicode 18.0.0 UnicodeData](https://www.unicode.org/Public/18.0.0/ucd/UnicodeData.txt)：项目中的 `Unicode/phonetic-records.json` 提取语音相关码位，保留官方字符名、类别及分解。许可原文见 `Unicode/LICENSE.txt`。
- [Unicode 18 第 7 章](https://www.unicode.org/versions/Unicode18.0.0/core-spec/chapter-7/)及 [汉学上标字符提案 L2/24-147](https://www.unicode.org/L2/L2024/24147-sinological-ext-ipa.pdf)：核对汉语音标及其上标形式，是否已编码以 Unicode 18 正式数据为准。
- [教育部《中国通用音标符号集》](https://www.moe.gov.cn/jyb_sjzl/ziliao/A19/200602/t20060201_186105.html)：规范来源。已编码清单结合下列汉学音标资料与 Unicode 数据核对，未声称对规范中的所有未编码印刷字形做过逐页审校。
- [Sinological phonetic notation](https://en.wikipedia.org/wiki/Sinological_phonetic_notation)：汉学音标、中国通用音标集已编码项目和声调形式的交叉核对。
- [Obsolete and nonstandard IPA symbols](https://en.wikipedia.org/wiki/Obsolete_and_nonstandard_IPA_symbols)：历史/非标准字母及标记清单；保留文字中实际编码字符，跳过字形图片、未编码项目与明显打字机替代项。再按 Unicode 数据补全历史腭钩/卷舌钩字母。
- [国际语音协会历史图表](https://www.internationalphoneticassociation.org/IPAcharts/IPA_charts_H/IPA_charts_H.html)：历史版本来源入口。
- ICPLA，Martin J. Ball / Kirk Miller，*ExtIPA Symbols for Disordered Speech*，2025。[发布机构资源页](https://www.icpla.org.uk/resources)，[2025 原表镜像与出处](https://commons.wikimedia.org/wiki/File:ExtIPA_chart_(2025).pdf)。按原表核对字母、组合标记与组合示例；该表标注 CC BY-SA 4.0。旧版鼻气流记号另保留以便历史文献输入。

`extended-inventory.json` 是对上述音标资料的字符清单整理；`Shared/ipa-catalog.json` 增加了本项目的中文标签、分类、Unicode 码位和键位归属。引用/改编的音标资料与这两个数据文件按 [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) 提供；Unicode 官方字段另遵循 Unicode 许可。没有整篇复制百科或论文正文。

浮动候选条采用项目定义的相对顺序（现版 IPA、中国通用、旧版、extIPA），不是 Unicode 官方排序。Unicode 语音补充属于单独的兜底集合，不能误称为 extIPA 或现版 IPA。
