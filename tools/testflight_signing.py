"""Verify distribution signatures, profiles and the shared container in an exported IPA."""
import os, plistlib, subprocess, sys, tempfile, zipfile
from pathlib import Path
from testflight_config import settings

def entitlements(bundle):
    result = subprocess.run(['codesign','-d','--entitlements',':-',str(bundle)],check=True,capture_output=True)
    return plistlib.loads(result.stdout)

def check_bundle(bundle, bundle_id, team, group, version, build):
    info = plistlib.loads((bundle/'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == bundle_id, 'Wrong bundle ID'
    assert info['CFBundleShortVersionString'] == version and info['CFBundleVersion'] == build, 'Version mismatch'
    assert info['IPASettingsAppGroup'] == group, 'Wrong settings group'
    subprocess.run(['codesign','--verify','--strict',str(bundle)],check=True)
    signed = entitlements(bundle)
    assert signed.get('com.apple.developer.team-identifier') == team, 'Wrong signing team'
    assert signed.get('application-identifier') == team+'.'+bundle_id, 'Wrong signed application ID'
    assert signed.get('com.apple.security.application-groups') == [group], 'Missing shared group in signature'
    assert not signed.get('get-task-allow', False), 'Development signature is not distributable'
    profile = subprocess.check_output(['security','cms','-D','-i',str(bundle/'embedded.mobileprovision')])
    profile = plistlib.loads(profile)
    assert team in profile['TeamIdentifier'], 'Wrong provisioning team'
    assert profile['Entitlements']['application-identifier'] == team+'.'+bundle_id, 'Wrong provisioning app ID'
    assert 'ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices'), 'Not an App Store profile'
    assert group in profile['Entitlements'].get('com.apple.security.application-groups', []), 'Group missing in profile'
    with tempfile.TemporaryDirectory() as temp:
        subprocess.run(['codesign','-d','--extract-certificates',str(bundle.resolve())],cwd=temp,check=True)
        leaf = Path(temp)/'codesign0'
        assert leaf.exists(), 'Ad-hoc signature was not replaced by a distribution signature'
        assert leaf.read_bytes() in profile['DeveloperCertificates'], 'Signature certificate does not match profile'
    assert (bundle/'PrivacyInfo.xcprivacy').exists(), 'Privacy manifest missing'

if __name__ == '__main__':
    team, identifier, group, version, build = settings(os.environ)
    mode, source = sys.argv[1:]
    if mode == 'verify':
        with tempfile.TemporaryDirectory() as temp:
            with zipfile.ZipFile(source) as archive:
                for item in archive.infolist():
                    if item.filename.startswith('/') or '..' in Path(item.filename).parts: raise ValueError('Unsafe archive path')
            subprocess.run(['ditto','-x','-k',source,temp],check=True)
            app = next((Path(temp)/'Payload').glob('*.app'))
            check_bundle(app, identifier, team, group, version, build)
            check_bundle(app/'PlugIns/IPAKeyboardExtension.appex', identifier+'.Keyboard', team, group, version, build)
        print('App and keyboard distribution signatures, versions, App Groups and profiles verified.')
    else: raise SystemExit('Expected verify')
