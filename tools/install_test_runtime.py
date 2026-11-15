"""Initialize CoreSimulator before asking Xcode to install a compatibility runtime."""
import json
import subprocess
import sys

requested = sys.argv[1]
for attempt in range(2):
    runtimes = json.loads(subprocess.check_output(
        ['xcrun', 'simctl', 'list', 'runtimes', '--json'], timeout=240))['runtimes']
    if any(r.get('isAvailable') and r['version'].startswith(requested) for r in runtimes):
        break
    result = subprocess.run(['xcodebuild', '-downloadPlatform', 'iOS', '-buildVersion', requested], timeout=1200)
    if result.returncode == 0:
        break
    if attempt:
        result.check_returncode()
