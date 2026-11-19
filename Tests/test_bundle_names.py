"""System keyboard lists must receive the same name from either bundle/key."""
import plistlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class BundleNameTests(unittest.TestCase):
    def test_both_bundles_have_the_same_literal_fallback_names(self):
        for name in ('App', 'KeyboardExtension'):
            info = plistlib.loads((ROOT / name / 'Info.plist').read_bytes())
            self.assertEqual(info['CFBundleName'], 'ipa+ keyboard')
            self.assertEqual(info['CFBundleDisplayName'], info['CFBundleName'])
            self.assertEqual(info['CFBundleDevelopmentRegion'], 'en')
            self.assertEqual(set(info['CFBundleLocalizations']), {'en','zh-Hans','zh-Hant','ja'})

    def test_localized_name_keys_remain_identical(self):
        for language in ('en', 'zh-Hans', 'zh-Hant', 'ja'):
            name = "ipa+ keyboard"
            text = (ROOT / 'Shared' / (language + '.lproj') / 'InfoPlist.strings').read_text()
            values = dict(re.findall(r'"([^"\n]+)"\s*=\s*"([^"\n]+)";', text))
            self.assertEqual(values, {'CFBundleName': name, 'CFBundleDisplayName': name})
            self.assertEqual(name.count('ipa+'), 1)
