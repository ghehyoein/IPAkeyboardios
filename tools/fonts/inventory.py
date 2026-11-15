"""The shipped font covers catalog entries AND numeric/punctuation long presses."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def strings():
 c=json.loads((ROOT/'Shared/ipa-catalog.json').read_text())
 result={s[k] for s in c['symbols'] for k in ('text','display')}
 for key,value in c['keys'].items():result.update([key,*value['variants'],*value['swipes'].values()])
 layout=(ROOT/'Shared/KeyboardLayout.swift').read_text().split('/// Accumulates')[0]
 result.update(json.loads(s) for s in re.findall(r'"(?:\\.|[^"\\])*"',layout))
 result.update(chr(cp) for cp in range(32,127))
 result.update(['◌','◌̃','′','″'])
 return sorted(result)
def codepoints():return {ord(c) for s in strings() for c in s if ord(c)>=32}
