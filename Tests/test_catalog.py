"""Platform-independent checks for transcription integrity and project packaging."""
import hashlib
import json
from pathlib import Path
import plistlib
import re
import unittest
import unicodedata
import xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT/'Shared/ipa-catalog.json').read_text())
SYMBOLS = {s['text']: s for s in DATA['symbols']}
UNICODE = json.loads((ROOT/'Reference/Unicode/phonetic-records.json').read_text())['records']
INVENTORY = json.loads((ROOT/'Reference/extended-inventory.json').read_text())

class CatalogTests(unittest.TestCase):
 def test_unique_ids_and_exact_codepoints(self):
  self.assertEqual(len(SYMBOLS), len(DATA['symbols']))
  self.assertEqual(len({s['id'] for s in DATA['symbols']}), len(SYMBOLS))
  for text, s in SYMBOLS.items():
   self.assertEqual(s['id'], '-'.join(f'{ord(c):04X}' for c in text))
   self.assertNotIn('◌', text)
   self.assertFalse(any(unicodedata.category(c)=='Co' for c in text))

 def test_chart_sections(self):
  # Independently transcribed row counts from the retained official chart.
  expected={'pulmonic':59,'vowels':28,'nonpulmonic':11,'other':12,'diacritics':32,'suprasegmentals':9,'tones':24}
  self.assertEqual({g:sum(s['category']==g for s in SYMBOLS.values()) for g in expected},expected)
  # Frequently confused or omitted code points: IPA g, clicks, stress, steps, tie bars.
  for text in ['ɡ','ɟ','ʄ','ɠ','ʛ','ǀ','ǃ','ǂ','ǁ','ʘ','ⱱ','ɧ','ɺ','ɞ','ɶ','ꜜ','ꜛ','\u0361','\u035c','\u030a','\u1dc4','\u1dc5','\u1dc8']:
   self.assertTrue(SYMBOLS[text]['official'])
  self.assertNotEqual(ord('ǀ'), ord('|'))
  self.assertNotEqual(ord('ʼ'), ord("'"))
  self.assertFalse(SYMBOLS['g']['official'])

 def test_every_non_ascii_chart_letter_has_long_press(self):
  mapped={v for key in DATA['keys'].values() for v in key['variants']}
  letters={s['text'] for s in SYMBOLS.values() if s['category'] in ['pulmonic','vowels','nonpulmonic','other'] and len(s['text'])==1 and unicodedata.category(s['text']).startswith('L') and not s['text'].isascii() and s['atomic']}
  self.assertFalse(letters-mapped, letters-mapped)

 def test_all_mappings_are_reachable_valid_symbols(self):
  self.assertEqual(set(DATA['keys']),set('abcdefghijklmnopqrstuvwxyz'))
  for key in DATA['keys'].values():
   self.assertEqual(len(key['variants']),len(set(key['variants'])))
   self.assertFalse(set(key['variants'])-SYMBOLS.keys())
   self.assertFalse(set(key['swipes'])-{'up','right','down','left'})
   self.assertFalse(set(key['swipes'].values())-set(key['variants']))
   self.assertTrue(all(not v.isascii() for v in key['swipes'].values()))

 def test_combining_display_is_not_inserted_text(self):
  for s in SYMBOLS.values():
   self.assertEqual(s['combining'],all(UNICODE[c]['category'].startswith('M') for c in s['text']))
   self.assertEqual(s['display'],('◌' if s['combining'] else '')+s['text'])
  self.assertEqual([ord(c) for c in 'a'+SYMBOLS['\u0303']['text']+SYMBOLS['\u0301']['text']],[0x61,0x303,0x301])
  self.assertEqual([ord(c) for c in 't'+SYMBOLS['\u0361']['text']+'s'],[0x74,0x361,0x73])
  for text in ['ʰ','ʲ','ʷ','ˠ','ˤ','ⁿ','ˡ']:
   self.assertFalse(SYMBOLS[text]['combining'])

 def test_source_inventories_and_unicode_coverage(self):
  for family,values in INVENTORY.items():
   for text in values:
    if text=='\u034f':continue
    self.assertIn(text,SYMBOLS)
    self.assertIn(family,SYMBOLS[text]['collections'])
  for text in SYMBOLS:
   self.assertTrue(all(c in UNICODE for c in text),repr(text))
  ranges=[(0x250,0x2FF),(0x1D00,0x1DBF),(0x10780,0x107BF),(0x1DF00,0x1DF81),(0x1DFCD,0x1DFFF)]
  for c in UNICODE:
   if any(a<=ord(c)<=b for a,b in ranges):self.assertIn(c,SYMBOLS)

 def test_letter_variants_have_a_base_key(self):
  for s in SYMBOLS.values():
   if s['family'] in ['chinese','historical','extipa'] and len(s['text'])==1 and UNICODE[s['text']]['category'] in ['Ll','Lu','Lt','Lo'] and s['text']!='ꞏ':
    self.assertIsNotNone(s['baseKey'],s['text'])
    if not s['text'].isascii() and s['atomic']:self.assertIn(s['text'],DATA['keys'][s['baseKey']]['variants'])

 def test_priority_and_chinese_forms(self):
  for mapping in DATA['keys'].values():
   ranks=[SYMBOLS[c]['priority'] for c in mapping['variants']]
   self.assertEqual(ranks,sorted(ranks))
  for text in ['ɿ','ʅ','ʮ','ʯ','ᴀ','ᴇ','𝿩','𝿪','𝿫','𝿬','𝿭','𝿮']:
   self.assertEqual(SYMBOLS[text]['family'],'chinese')
   self.assertIn(text,DATA['keys'][SYMBOLS[text]['baseKey']]['variants'])
  for text in ['ʇ','ʖ','ʗ','ʞ','ɩ','ɷ','ʆ','ʓ','ƥ','ƙ']:
   self.assertIn('historical',SYMBOLS[text]['collections'])
  for text in ['ʩ','ʪ','ʫ','ʬ','ʭ','𝼀','𝼁','𝼂','𝼃','𝼄','𝼅','𝼆','𝼇','ꞎ','ꞯ','\u1ac1','\u1ac4']:
   self.assertIn('extipa',SYMBOLS[text]['collections'])

 def test_no_composites_in_shortcuts(self):
  for mapping in DATA['keys'].values():
   for text in mapping['variants']:
    self.assertTrue(SYMBOLS[text]['atomic'],text)
    self.assertEqual(len(text),1)
    if text!='ç':self.assertEqual(len(unicodedata.normalize('NFD',text)),1)
  for text in ['ã','t͡s']:
   self.assertNotIn(text,{v for k in DATA['keys'].values() for v in k['variants']})
  decomposable=[s for s in SYMBOLS.values() if s['text']!='ç' and (len(s['text'])>1 or len(unicodedata.normalize('NFD',s['text']))>1)]
  self.assertGreater(len(decomposable),20)
  self.assertTrue(all(not s['atomic'] for s in decomposable))
  for text in ['ʰ','ʲ','ʷ','ⁿ','ˡ','ᴀ','ᴇ','ɿ']:
   self.assertTrue(SYMBOLS[text]['atomic'])

 def test_privacy_and_extension_registration(self):
  info=plistlib.loads((ROOT/'KeyboardExtension/Info.plist').read_bytes())
  ext=info['NSExtension']
  self.assertEqual(ext['NSExtensionPointIdentifier'],'com.apple.keyboard-service')
  self.assertTrue(ext['NSExtensionAttributes']['RequestsOpenAccess'])
  entitlements=[plistlib.loads((ROOT/p).read_bytes()) for p in ['App/IPAKeyboard.entitlements','KeyboardExtension/IPAKeyboardExtension.entitlements']]
  self.assertEqual(entitlements[0],entitlements[1])
  self.assertEqual(entitlements[0]['com.apple.security.application-groups'],['$(IPA_APP_GROUP_IDENTIFIER)'])
  self.assertEqual(ext['NSExtensionPrincipalClass'],'$(PRODUCT_MODULE_NAME).KeyboardViewController')

 def test_app_icon_asset_is_opaque_1024_png(self):
  import struct
  folder=ROOT/'App/Assets.xcassets/AppIcon.appiconset'
  definition=json.loads((folder/'Contents.json').read_text())
  data=(folder/definition['images'][0]['filename']).read_bytes()
  self.assertEqual(data[:8],b'\x89PNG\r\n\x1a\n')
  self.assertEqual(struct.unpack('>II',data[16:24]),(1024,1024))
  self.assertEqual(data[25],2) # RGB, no alpha channel.

 def test_project_references_and_scheme(self):
  project=(ROOT/'IPAKeyboard.xcodeproj/project.pbxproj').read_text()
  # Every PBX reference resolves to an object; every project source is present.
  defined=set(re.findall(r'"([0-9A-F]{24})" = \{',project))
  referenced=set(re.findall(r'"([0-9A-F]{24})"',project))
  self.assertEqual(defined,referenced)
  for path in re.findall(r'"path" = "([^\"]+)";',project):
   if not path.endswith(('.app','.appex','.xctest')): self.assertTrue((ROOT/path).exists(),path)
  scheme=ET.parse(ROOT/'IPAKeyboard.xcodeproj/xcshareddata/xcschemes/IPAKeyboard.xcscheme')
  for node in scheme.iter('BuildableReference'): self.assertIn(node.attrib['BlueprintIdentifier'],defined)
  self.assertIn('Embed App Extensions',project)
  self.assertEqual(project.count('"isa" = "PBXNativeTarget"'),4)

if __name__=='__main__': unittest.main()
