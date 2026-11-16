# 0.601

- Added 15 missing phonetic/transcription characters and 26 circled capitals.
- Adapted two smooth Charis-based glyphs; no bitmap outline imports.
- Fixed enclosed diacritic positioning for decomposed and precomposed inputs.
- Preserved all 1,308 existing mapped outlines and metrics.

# Font changes

## 0.600 — 2026-11-16

Standalone font publication; this is a font version, not an App version.

- Replace 159 formerly pixel-shaped mapped glyphs with licensed vector components and project vector constructions.
- Correct confused letter components, stretched-letter direction, ligature connections, white curly brackets, and attached crossbars.
- Update combining-mark attachment and stacking anchors for the reconstructed outlines.
- Draw these twelve characters anew: U+1DF60, U+1DF6B, U+1DF6C, U+1DF74–U+1DF79, U+1DF7C, U+1DF7D, and U+1DF81.
- Introduce contrasting stroke weights, bracketed or angled terminals, deeper central strokes/notches, and distinct lowercase proportions.
- Preserve the existing 51 supplementary characters and the other mapped outlines outside the 159-character replacement scope.
- Retain 1,308 mapped code points and the existing family and PostScript names.

Validation uses HarfBuzz and fontTools. iOS CoreText and physical-device layout validation remain outstanding. The App-bundled font is unchanged by this standalone publication.
