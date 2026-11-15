"""Package reviewed keyboard scenes; keep unsigned settings diagnostics out of marketing."""
import json
from pathlib import Path
import sys
from zipfile import ZIP_DEFLATED, ZipFile

source, destination = map(Path, sys.argv[1:3])
manifest = json.loads((source / 'manifest.json').read_text())
selected = [entry for entry in manifest if entry['scene'] != '04-settings']
expected = {(device, language, scene)
            for device in ('iphone-medium', 'iphone-large', 'ipad')
            for language in ('zh-Hans', 'zh-Hant', 'en', 'ja')
            for scene in ('01-keyboard', '02-variants', '03-symbols')}
actual = {(Path(entry['path']).parts[0], entry['language'], entry['scene']) for entry in selected}
if actual != expected or len(selected) != 36:
    raise SystemExit('Incomplete localized keyboard screenshot set')
destination.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(destination, 'w', ZIP_DEFLATED) as archive:
    for entry in selected:
        archive.write(source / entry['path'], 'AppStore-Screenshots/' + entry['path'])
    archive.writestr('AppStore-Screenshots/manifest.json', json.dumps(selected, ensure_ascii=False, indent=2) + '\n')
print(f'Packaged {len(selected)} native JPEG screenshots: {destination}')
