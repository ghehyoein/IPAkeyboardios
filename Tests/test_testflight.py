import importlib.util, os, plistlib, subprocess, tempfile, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('testflight_config', ROOT/'tools/testflight_config.py')
config = importlib.util.module_from_spec(spec); spec.loader.exec_module(config)

class TestFlightConfiguration(unittest.TestCase):
 def test_identifiers_and_versions_reject_invalid_values(self):
  self.assertEqual(config.settings({'APPLE_TEAM_ID':'AB12345678'})[1], 'com.ghehyoein.IPAKeyboard')
  for key,value in [('APPLE_TEAM_ID',''),('IPA_BUNDLE_IDENTIFIER','invalid'),('IPA_APP_GROUP_IDENTIFIER','bad'),('IPA_MARKETING_VERSION','0.5;echo'),('IPA_BUILD_NUMBER','invalid')]:
   with self.subTest(key=key), self.assertRaises(ValueError): config.settings(dict(APPLE_TEAM_ID='AB12345678',**{key:value}) if key!='APPLE_TEAM_ID' else {key:value})
 def test_distribution_generation_in_isolated_copy(self):
  import shutil
  with tempfile.TemporaryDirectory() as folder:
   target=Path(folder)/'repo'; shutil.copytree(ROOT,target,ignore=shutil.ignore_patterns('build','.git','Design','UnicodeData.txt'))
   env=dict(os.environ,IPA_BUNDLE_IDENTIFIER='com.example.phonetics',IPA_APP_GROUP_IDENTIFIER='group.com.example.phonetics',IPA_MARKETING_VERSION='0.5.0',IPA_BUILD_NUMBER='12.2')
   subprocess.run(['python3',str(target/'tools/generate_project.py')],env=env,check=True,stdout=subprocess.DEVNULL)
   for path in ['App/Info.plist','KeyboardExtension/Info.plist']:
    info=plistlib.loads((target/path).read_bytes()); self.assertEqual(info['CFBundleVersion'],'12.2'); self.assertEqual(info['CFBundleShortVersionString'],'0.5.0')
   project=(target/'IPAKeyboard.xcodeproj/project.pbxproj').read_text()
   self.assertIn('com.example.phonetics.Keyboard',project); self.assertIn('group.com.example.phonetics',project)
   self.assertEqual(project.count('"fileRef" = "'+__import__('hashlib').sha1(b'file:Shared/PrivacyInfo.xcprivacy').hexdigest()[:24].upper()+'"'),2)
 def test_secret_files_are_restricted(self):
  with tempfile.TemporaryDirectory() as folder:
   env=dict(os.environ,APPLE_TEAM_ID='AB12345678',RUNNER_TEMP=folder,ASC_KEY_ID='AB12345678',ASC_ISSUER_ID='00000000-0000-0000-0000-000000000000',ASC_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\nTEST ONLY\n-----END PRIVATE KEY-----')
   env.update(APP_PROFILE_UUID='test-app',EXT_PROFILE_UUID='test-extension')
   subprocess.run(['python3',str(ROOT/'tools/testflight_config.py')],env=env,check=True,stdout=subprocess.DEVNULL)
   key=Path(folder)/'ipa-testflight/AuthKey.p8'; self.assertEqual(key.stat().st_mode & 0o777,0o600)
   options=plistlib.loads((key.parent/'ExportOptions.plist').read_bytes()); self.assertEqual(options['method'],'app-store-connect'); self.assertEqual(options['signingStyle'],'manual')
   self.assertEqual(options['provisioningProfiles'],{'com.ghehyoein.IPAKeyboard':'test-app','com.ghehyoein.IPAKeyboard.Keyboard':'test-extension'})
   self.assertassertFalse(...)
