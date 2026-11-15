"""Select an installed iOS runtime and compatible device using project requirements."""
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def version(value):
    parts = tuple(int(p) for p in value.split('.'))
    return (parts + (0, 0, 0))[:3]


def select(runtimes, minimum, requested=None, runtime_prefix=None, family="iPhone"):
    compatible = sorted(
        (r for r in runtimes if r.get('isAvailable') and r['name'].startswith('iOS ')
         and version(r['version']) >= version(minimum)
         and (not runtime_prefix or r['version'].split('.')[0] == runtime_prefix)),
        key=lambda r: version(r['version']), reverse=True)
    for runtime in compatible:
        devices = sorted((d for d in runtime.get('supportedDeviceTypes', [])
                          if d['name'].startswith(family)
                          and (not requested or d['identifier'] == requested or d['identifier'].startswith(requested + '-'))),
                         key=lambda d: d['identifier'])
        if devices:
            return runtime, devices[0]
    raise ValueError(f'No compatible {family} for runtime {runtime_prefix or minimum}: {requested}. '
                     f'Available: {[(r["version"], [d["identifier"] for d in r.get("supportedDeviceTypes", []) if d["name"].startswith(family)]) for r in compatible]}')


def create():
    project = (ROOT / 'IPAKeyboard.xcodeproj/project.pbxproj').read_text()
    targets = re.findall(r'"?IPHONEOS_DEPLOYMENT_TARGET"?\s*=\s*"?([0-9.]+)', project)
    if not targets:
        raise ValueError('Project has no iOS deployment target.')
    minimum = max(targets, key=version)
    runtimes = json.loads(subprocess.check_output(
        ['xcrun', 'simctl', 'list', 'runtimes', '--json']))['runtimes']
    # Older simulator metadata omits supportedDeviceTypes. simctl validates the
    # explicitly requested device when creating it on those runtimes.
    device_types = json.loads(subprocess.check_output(
        ['xcrun', 'simctl', 'list', 'devicetypes', '--json']))['devicetypes']
    for item in runtimes:
        if not item.get('supportedDeviceTypes'):
            item['supportedDeviceTypes'] = device_types
    runtime, device_type = select(runtimes, minimum, os.environ.get('IPA_SIMULATOR_DEVICE_TYPE'),
                                  os.environ.get('IPA_SIMULATOR_RUNTIME'),
                                  os.environ.get('IPA_SIMULATOR_FAMILY', 'iPhone'))
    device = subprocess.check_output(
        ['xcrun', 'simctl', 'create', 'IPA Keyboard Tests', device_type['identifier'], runtime['identifier']],
        text=True).strip()
    print('Simulator:', device_type['name'], runtime['name'], device)
    return device, runtime['version']


if __name__ == '__main__':
    device, runtime_version = create()
    if os.environ.get('GITHUB_ENV'):
        with open(os.environ['GITHUB_ENV'], 'a') as f:
            f.write(f'SIMULATOR_ID={device}\nTEST_IOS_VERSION={runtime_version}\n')
