"""Package an actual device archive; never fabricate an IPA from sources/simulator builds."""
import argparse
import plistlib
import subprocess
import tempfile
from pathlib import Path
from zipfile import ZipFile

parser = argparse.ArgumentParser()
parser.add_argument('archive', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
app = args.archive.resolve() / 'Products/Applications/IPAKeyboard.app'
extension = app / 'PlugIns/IPAKeyboardExtension.appex'
for bundle in [app, extension]:
    with (bundle / 'Info.plist').open('rb') as f:
        info = plistlib.load(f)
    executable = bundle / info['CFBundleExecutable']
    if not executable.is_file():
        raise SystemExit(f'Missing executable: {executable}')
    if info.get('DTPlatformName') != 'iphoneos':
        raise SystemExit(f'Expected device build, got {info.get("DTPlatformName")}: {bundle}')
    if info.get('MinimumOSVersion') != '17.0':
        raise SystemExit(f'Expected iOS 17 deployment target: {bundle}')
    if set(info.get('UIDeviceFamily', [])) != {1, 2}:
        raise SystemExit(f'Expected universal iPhone/iPad bundle: {bundle}')
    if info.get('CFBundleDisplayName') != 'ipa+ keyboard':
        raise SystemExit(f'Unexpected keyboard display name: {bundle}')
    for language in ('en', 'zh-Hans', 'zh-Hant', 'ja'):
        if not (bundle / (language + '.lproj') / 'InfoPlist.strings').is_file():
            raise SystemExit(f'Missing localized system name: {bundle} {language}')
    print(subprocess.check_output(['file', str(executable)], text=True).strip())
    if not (bundle / 'ipa-catalog.json').is_file():
        raise SystemExit(f'Missing IPA catalog: {bundle}')
app_info=plistlib.loads((app/'Info.plist').read_bytes())
if not (app/'Assets.car').is_file() or 'AppIcon' not in str(app_info.get('CFBundleIcons',{})):
    raise SystemExit('App icon missing from compiled device app')
ext_info=plistlib.loads((extension/'Info.plist').read_bytes())
if app_info.get('IPASettingsAppGroup') != ext_info.get('IPASettingsAppGroup'):
    raise SystemExit('App and keyboard App Group identifiers differ')
args.output = args.output.resolve()
args.output.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory() as temp:
    payload = Path(temp) / 'Payload'
    payload.mkdir()
    # ditto preserves executable modes and bundle metadata on macOS.
    subprocess.run(['ditto', str(app), str(payload / app.name)], check=True)
    subprocess.run(['ditto', '-c', '-k', '--keepParent', str(payload), str(args.output)], check=True)
with ZipFile(args.output) as archive:
    if archive.testzip() is not None:
        raise SystemExit('ZIP integrity check failed')
    required = ['Payload/IPAKeyboard.app/IPAKeyboard', 'Payload/IPAKeyboard.app/PlugIns/IPAKeyboardExtension.appex/IPAKeyboardExtension']
    for path in required:
        if path not in archive.namelist():
            raise SystemExit(f'Missing packaged executable: {path}')
print(f'Created unsigned device IPA: {args.output} ({args.output.stat().st_size} bytes)')
