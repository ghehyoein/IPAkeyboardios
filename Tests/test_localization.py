import json,re,unittest,plistlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class LocalizationTests(unittest.TestCase):
 def test_interface_and_annotations_have_translations(self):
  data=json.loads((ROOT/'Shared/localization.json').read_text())
  for path in list((ROOT/'App').glob('*.swift'))+list((ROOT/'Shared').glob('*.swift')):
   if path.name=='Localization.swift':continue
   for key in re.findall(r'"([^"\\\n]*)"\.localized',path.read_text()):
    if re.search('[\u4e00-\u9fff]',key):
     self.assertIn(key,data['ui'],(path,key))
  catalog=json.loads((ROOT/'Shared/ipa-catalog.json').read_text())
  for symbol in catalog['symbols']:
   if re.search('[\u4e00-\u9fff]',symbol['name']):self.assertIn(symbol['name'],data['names'])
  for group in data.values():
   for key,value in group.items():
    for language in (['zh-Hans','ja'] if group is data['words'] else ['en','ja']):self.assertTrue(value.get(language),key)
 def test_localization_resources_and_version_are_packaged(self):
  for target in ['App','KeyboardExtension']:
   info=plistlib.loads((ROOT/target/'Info.plist').read_bytes())
   self.assertEqual(info['CFBundleShortVersionString'],(ROOT/'VERSION').read_text().strip())
   self.assertEqual(set(info['CFBundleLocalizations']),{'zh-Hans','zh-Hant','en','ja'})
  project=(ROOT/'IPAKeyboard.xcodeproj/project.pbxproj').read_text()
  self.assertIn('Shared/Localization.swift',project);self.assertIn('Shared/localization.json',project)
