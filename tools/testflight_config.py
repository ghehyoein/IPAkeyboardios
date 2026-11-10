"""Validate non-secret distribution settings and create export options."""
import os, plistlib, re
from pathlib import Path

DEFAULT_BUNDLE = 'com.ghehyoein.IPAKeyboard'
DEFAULT_GROUP = 'group.com.ghehyoein.IPAKeyboard'

def settings(env):
    team = env.get('APPLE_TEAM_ID', '')
    bundle = env.get('IPA_BUNDLE_IDENTIFIER') or DEFAULT_BUNDLE
    group = env.get('IPA_APP_GROUP_IDENTIFIER') or DEFAULT_GROUP
    version = env.get('IPA_MARKETING_VERSION', '0.5.0')
    build = env.get('IPA_BUILD_NUMBER', '1.1')
    if not re.fullmatch(r'[A-Z0-9]{10}', team): raise ValueError('Set APPLE_TEAM_ID to your 10-character Apple Team ID.')
    if not re.fullmatch(r'[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+){2,}', bundle): raise ValueError('Invalid IPA_BUNDLE_IDENTIFIER')
    if not group.startswith('group.') or not re.fullmatch(r'[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+){2,}', group): raise ValueError('Invalid IPA_APP_GROUP_IDENTIFIER')
    if not re.fullmatch(r'\d+\.\d+\.\d+', version): raise ValueError('Version must be three numeric components, e.g. 0.5.0')
    if not re.fullmatch(r'\d+(?:\.\d+){0,2}', build): raise ValueError('Invalid build number')
    return team, bundle, group, version, build

if __name__ == '__main__':
    team, bundle, group, version, build = settings(os.environ)
    missing = [name for name in ['ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_PRIVATE_KEY'] if not os.environ.get(name)]
    if missing: raise SystemExit('Missing GitHub Actions secrets: ' + ', '.join(missing))
    if not re.fullmatch(r'[A-Z0-9]{10}', os.environ['ASC_KEY_ID']): raise SystemExit('Invalid ASC_KEY_ID format')
    if not re.fullmatch(r'[0-9a-fA-F-]{36}', os.environ['ASC_ISSUER_ID']): raise SystemExit('Invalid ASC_ISSUER_ID format')
    key = os.environ['ASC_PRIVATE_KEY'].strip()
    if not key.startswith('-----BEGIN PRIVATE KEY-----') or not key.endswith('-----END PRIVATE KEY-----'):
        raise SystemExit('ASC_PRIVATE_KEY must contain the complete .p8 file, including BEGIN/END lines.')
    folder = Path(os.environ['RUNNER_TEMP']) / 'ipa-testflight'
    folder.mkdir(mode=0o700, parents=True, exist_ok=True)
    folder.chmod(0o700)
    (folder/'AuthKey.p8').write_text(key+'\n'); (folder/'AuthKey.p8').chmod(0o600)
    options = dict(method='app-store-connect', destination='export', signingStyle='manual', teamID=team,
                   signingCertificate='Apple Distribution',testFlightInternalTestingOnly=True,
                   provisioningProfiles={bundle:os.environ['APP_PROFILE_UUID'],bundle+'.Keyboard':os.environ['EXT_PROFILE_UUID']},
                   manageAppVersionAndBuildNumber=False, uploadSymbols=True)
    (folder/'ExportOptions.plist').write_bytes(plistlib.dumps(options))
    print('Distribution settings validated; private key written only to temporary runner storage.')
