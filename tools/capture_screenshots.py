"""Capture actual localized app screens on simulator; no mock interface artwork."""
import json
import os
import re
from pathlib import Path
import subprocess
import time
from create_simulator import create
from boot_simulator import boot


def run(*args, **kwargs):
    return subprocess.run(args, check=True, timeout=180, **kwargs)


def main():
    app = Path('build/Simulator/Build/Products/Debug-iphonesimulator/IPAKeyboard.app')
    output = Path('build/AppStore-Screenshots')
    devices = [('iphone-medium', 'iPhone-16-Pro', 'iPhone'),
               ('iphone-large', 'iPhone-16-Pro-Max', 'iPhone'),
               ('ipad', 'iPad-Pro-13-inch-M4', 'iPad')]
    scenes = [('01-keyboard', ['--screenshot']),
              ('02-variants', ['--screenshot', '--screenshot-popup']),
              ('03-symbols', ['--screenshot', '--screenshot-panel']),
              ('04-settings', [])]
    manifest = []
    for family, device_type, idiom in devices:
        os.environ['IPA_SIMULATOR_DEVICE_TYPE'] = 'com.apple.CoreSimulator.SimDeviceType.' + device_type
        os.environ['IPA_SIMULATOR_FAMILY'] = idiom
        device, runtime = create()
        try:
            boot(device)
            run('xcrun', 'simctl', 'status_bar', device, 'override', '--time', '9:41', '--dataNetwork', 'wifi',
                '--wifiMode', 'active', '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
            run('xcrun', 'simctl', 'ui', device, 'appearance', 'light')
            run('xcrun', 'simctl', 'install', device, str(app))
            for language in ('zh-Hans', 'zh-Hant', 'en', 'ja'):
                folder = output / family / language
                folder.mkdir(parents=True, exist_ok=True)
                for scene, flags in scenes:
                    # Let launch handle an existing process atomically. A separate
                    # terminate can stall on a freshly booted simulator with no app process.
                    run('xcrun', 'simctl', 'launch', '--terminate-running-process', device, 'org.example.IPAKeyboard',
                        '--reset-settings', '-AppleLanguages', '('+language+')', *flags)
                    time.sleep(3)
                    # Native JPEG capture avoids the alpha channel App Store Connect rejects.
                    destination = folder / (scene + '.jpg')
                    run('xcrun', 'simctl', 'io', device, 'screenshot', '--type=jpeg', str(destination))
                    metadata = subprocess.check_output(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', str(destination)], text=True)
                    size = tuple(map(int, re.findall(r'pixel(?:Width|Height): (\d+)', metadata)))
                    expected = {'iphone-medium': (1206, 2622), 'iphone-large': (1320, 2868), 'ipad': (2064, 2752)}
                    if size != expected[family]:
                        raise ValueError(f'Unexpected App Store screenshot dimensions: {family} {size}')
                    manifest.append(dict(path=str(destination.relative_to(output)), language=language,
                                         device=device_type, runtime=runtime, scene=scene, width=size[0], height=size[1]))
        finally:
            for action in ('shutdown', 'delete'):
                try:
                    subprocess.run(['xcrun', 'simctl', action, device], timeout=90)
                except subprocess.TimeoutExpired:
                    print(f'Simulator cleanup timed out: {action} {device}', flush=True)
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    assert len(manifest) == 48


if __name__ == '__main__':
    main()
