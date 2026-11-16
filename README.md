# ipa+ keyboard

An International Phonetic Alphabet (IPA) keyboard for iOS, with a keyboard extension and a companion app for symbol settings. Supports iPhone and iPad running iOS 17 or later, with interfaces in Simplified Chinese, Traditional Chinese, English, and Japanese.

## Features

- Tap to type letters, swipe in four directions for phonetic variants, or touch and hold to slide through all available candidates.
- Includes current IPA, phonetic symbols used in Chinese linguistics, historical and nonstandard IPA, extIPA, and additional Unicode phonetic characters.
- A dedicated symbol panel provides superscripts, subscripts, combining diacritics, and recently used symbols, with continuous horizontal browsing.
- Number and punctuation pages offer variants on long press. Touch and hold the space bar, then drag horizontally to move the cursor.
- Customize symbol sources, panel contents, swipe mappings for individual keys, sound, and haptic feedback.
- Browse and search a categorized symbol reference with Unicode code points and annotations.
- Supports light and dark appearances and VoiceOver.

## Privacy and compatibility

The keyboard does not access the network or collect typed text or surrounding text. Settings are shared between the app and its keyboard extension through an App Group; recently used symbols are stored locally. Basic typing and read-only settings synchronization do not require Full Access. Keyboard-extension key sounds require Full Access.

Third-party keyboards are unavailable in password fields, some other input fields, and apps that disallow keyboard extensions. Character display and combining behavior depend on the receiving app and its fonts. When the system font lacks a glyph, the candidate displays its Unicode code point; the inserted text remains the original character.

## Data sources and licensing

See [Reference/SOURCES.md](Reference/SOURCES.md) and the [Unicode license](Reference/Unicode/LICENSE.txt) for the phonetic inventory, Unicode data, and applicable licenses. Source records and Unicode snapshots support offline generation and coverage checks. Key assignments and candidate ordering are project design choices, not official mappings from standards bodies.

## Source-code license and commercial use

This project's **source code is publicly available, but no general commercial-use permission is granted**. Except for separately licensed materials, the original Swift code, keyboard implementation, build scripts, and original project assets are licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE.md). Noncommercial use, study, modification, and redistribution are permitted under its terms. **Obtain separate authorization before commercial use, commercial distribution, or incorporating the original code into a commercial product.** See [LICENSE.md](LICENSE.md) for details.

**Third-party license exceptions:** Official Unicode data remains subject to the [Unicode License](Reference/Unicode/LICENSE.txt). Portions of the [phonetic inventory and adapted data](Reference/SOURCES.md) explicitly released under CC BY-SA 4.0 may still be used under that license, including commercial use that complies with its terms. These materials are not restricted by the project's noncommercial source-code license.

## ipa+ font

The [ipa+ font](Font/README.md) integrates **Charis, Gentium, BabelStone Roman, Noto Sans Math, Noto Sans Georgian, Noto Sans, and Noto Sans Symbols** under the **SIL Open Font License 1.1**.

Contributions by **ghehyoein** cover **199 character glyphs**: **48 newly constructed vector glyphs** and **151 adaptations of licensed glyphs**. Adapted glyphs retain upstream attribution.

See [font sources and licenses](FONT_SOURCES_AND_LICENSE.md) and the [complete copyright notices and license](Font/Font-Licenses.txt).
