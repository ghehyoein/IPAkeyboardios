"""Download exact reviewed font inputs. Reject upstream changes instead of drifting."""
import argparse,hashlib,io,json,urllib.request,zipfile
from pathlib import Path

def fetch(destination):
 for entry in json.loads(Path(__file__).with_name('sources.json').read_text()):
  path=destination/entry['path']
  if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']:continue
  payload=urllib.request.urlopen(entry['url'],timeout=120).read()
  if entry['archive_member']:payload=zipfile.ZipFile(io.BytesIO(payload)).read(entry['archive_member'])
  if hashlib.sha256(payload).hexdigest()!=entry['sha256']:raise ValueError('Source changed; review its license and coverage before updating: '+entry['path'])
  path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(payload)
  print('Verified',entry['path'])
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('destination',type=Path);fetch(parser.parse_args().destination)
