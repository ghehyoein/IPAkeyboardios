# ipa+ 0.601 review proofs

All samples are rendered from actual fonts, with no system fallback.

- [New characters](01-added-characters.png): 15 phonetic/transcription additions and 26 circled capitals.
- [Positioning comparison](02-positioning-comparison.png): published 0.600, earlier local candidate, and corrected 0.601; same size and baseline.
- [Smooth adaptations](03-smooth-redraws.png): Unifont is shown only as a stepped-appearance reference. The new font uses licensed Charis components, with no imported or traced Unifont contours.

The two new project adaptations are U+208F and U+A7F1. Upstream Charis copyright and OFL terms are retained. The original 1,308 mapped glyph outlines and metrics remain unchanged. The other 13 additions are directly adapted from Charis (9) and Noto Sans (4); circled capitals come from Noto Sans Symbols (26).

Validation: 216 enclosure cases pass, 252 NFC/NFD equivalence cases pass, and 1,592 ordinary-mark control cases are unchanged. All 2,187 base/mark cases render without missing glyphs. These are Linux HarfBuzz/Pillow results; no physical iOS/CoreText verification or new GitHub Release is asserted by these proofs.

`ipa-plus.json` records exact source hashes and the 15 additions; `verification.json` and `shaping.json` record checks. The expanded bracket variants are unencoded contextual glyphs and do not change inserted Unicode text.
