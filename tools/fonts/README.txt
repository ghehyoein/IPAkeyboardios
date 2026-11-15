One bundled phonetic font

Build dependencies: pip install -r tools/fonts/requirements.txt
Fetch reviewed source files: python3 tools/fonts/fetch.py /tmp/ipa-font-sources
Build: python3 tools/fonts/build.py --source-dir /tmp/ipa-font-sources
Verify: python3 tools/fonts/validate.py

Only Shared/Fonts/IPAPlusUnified-Regular.ttf and Font-Licenses.txt are shipped.
Both app and keyboard extension independently bundle/register that same resource,
as each runs in its own hosting process. Original donor fonts are build inputs,
not additional runtime fonts. Reference/Fonts contains the reviewed 51-character
supplement and provenance; this folder is not copied into either app bundle.

Coverage includes catalog text/display forms, letter-key variants, ASCII uppercase,
numeric/punctuation keys and their long-press variants. Each Unicode mapping is
assigned once, in source preference order. Subsetting retains only the target
mappings and glyphs reachable through composite outlines and active shaping
features. Those dependent glyphs are not redundant characters.

Charis is primary. The 51 smooth supplementary glyphs, BabelStone Roman, and
Unifont supply the gaps. Some remaining rare Unifont-derived glyphs retain their
pixel-shaped outlines: a single font file does not imply identical source styles.

Original ccmp/locl/mark/mkmk/kern layout is retained. Cross-source anchors are
added for mixed base/mark pairs, including stacked marks and enclosing marks.
Bounding-box-based fallback anchors need visual testing for unusual sequences;
no finite test can guarantee every arbitrary sequence of typed diacritics.

All donor compiled fonts are used under SIL OFL 1.1, including Unifont's OFL
option. Original notices and font licenses are shipped verbatim. The derivative
has a new family name, IPA Plus Unified. No Unicode chart font data or reference
images are used. Font changes do not force other apps to use the font.

sources.json pins hashes and public source URLs. Builds fail on missing coverage
or changed upstream bytes. Font regeneration is separate from ordinary Xcode
builds, which use the committed reviewed TTF without needing network access.
