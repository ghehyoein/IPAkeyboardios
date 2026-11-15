"""Boot a simulator with one bounded retry for a stalled CoreSimulator service."""
import subprocess
import sys


def boot(device):
    for attempt in range(2):
        try:
            subprocess.run(['xcrun', 'simctl', 'boot', device], timeout=90, check=False)
            subprocess.run(['xcrun', 'simctl', 'bootstatus', device, '-b'], timeout=600, check=True)
            return
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
            if attempt:
                raise
            print('Restarting stalled simulator once.', flush=True)
            try:
                subprocess.run(['xcrun', 'simctl', 'shutdown', device], timeout=90)
            except subprocess.TimeoutExpired:
                # A slow migration may still finish; bootstatus on the next
                # attempt remains the required readiness check.
                pass


if __name__ == '__main__':
    boot(sys.argv[1])
