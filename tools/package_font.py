"""Package the reviewed font and required notices beside a release IPA."""
import hashlib
import json
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def package(destination):
    destination.mkdir(parents=True, exist_ok=True)
    font = ROOT / 'Shared/Fonts/ipa-plus.ttf'
    report = ROOT / 'Reference/Fonts/unified-coverage.json'
    assert hashlib.sha256(font.read_bytes()).hexdigest() == json.loads(report.read_text())['sha256']
    files = [font, ROOT / 'Shared/Fonts/Font-Licenses.txt', ROOT / 'Shared/Fonts/README.md', report]
    for source in files[:2]:
        shutil.copyfile(source, destination / source.name)
    bundle = destination / 'ipa-plus-font.zip'
    with zipfile.ZipFile(bundle, 'w', zipfile.ZIP_DEFLATED) as archive:
        for source in files:
            info = zipfile.ZipInfo(source.name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, source.read_bytes())
    assets = [destination / 'ipa-plus.ttf', destination / 'Font-Licenses.txt', bundle]
    checksums = destination / 'SHA256SUMS.txt'
    names = {p.name for p in assets}
    previous = checksums.read_text().splitlines() if checksums.exists() else []
    lines = [line for line in previous if line.split()[-1].lstrip('*') not in names]
    lines += [hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name for p in assets]
    checksums.write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    package(Path(sys.argv[1]))
