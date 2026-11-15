"""Boot a simulator with one bounded retry for a stalled CoreSimulator service."""
import subprocess
import sys


def boot(device):
    for attempt in range(2):
        try:
            subprocess.run(['xcrun', 'simctl', 'boot', device], timeout=60, check=True)
            subprocess.run(['xcrun', 'simctl', 'bootstatus', device, '-b'], timeout=180, check=True)
            return
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
            if attempt:
                raise
            print('Restarting stalled simulator once.', flush=True)
            subprocess.run(['xcrun', 'simctl', 'shutdown', device], timeout=30)


if __name__ == '__main__':
    boot(sys.argv[1])
