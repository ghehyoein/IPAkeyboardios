"""Wait for Apple's processing and require a build eligible for App Store submission.

Uses the runner's temporary API key; never writes or prints an authentication token.
"""
import base64
import json
import os
from pathlib import Path
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request


def b64(data):
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def jwt():
    now = int(time.time())
    header = b64(json.dumps(dict(alg='ES256', kid=os.environ['ASC_KEY_ID'], typ='JWT')).encode())
    claims = b64(json.dumps(dict(iss=os.environ['ASC_ISSUER_ID'], iat=now-10,
                                exp=now+600, aud='appstoreconnect-v1')).encode())
    message = (header+'.'+claims).encode()
    key = Path(os.environ['RUNNER_TEMP'])/'ipa-testflight/AuthKey.p8'
    signature = subprocess.check_output(['openssl','dgst','-sha256','-sign',str(key)],input=message)
    # P-256 ECDSA DER sequence -> JWT fixed-width r || s. Both integers fit a
    # one-byte DER length (at most 33 bytes with the sign-padding byte).
    if signature[0] != 0x30 or signature[1] != len(signature)-2:
        raise ValueError('Unexpected ECDSA signature encoding')
    pos = 2
    parts = []
    for _ in range(2):
        if signature[pos] != 2:
            raise ValueError('Expected ECDSA integer')
        length = signature[pos+1]
        parts.append(int.from_bytes(signature[pos+2:pos+2+length], 'big').to_bytes(32,'big'))
        pos += 2+length
    if pos != len(signature):
        raise ValueError('Trailing ECDSA data')
    return message.decode()+'.'+b64(b''.join(parts))


def api(path, params=None):
    query = '?'+urllib.parse.urlencode(params) if params else ''
    request = urllib.request.Request('https://api.appstoreconnect.apple.com/v1/'+path+query,
                                    headers={'Authorization':'Bearer '+jwt()})
    with urllib.request.urlopen(request,timeout=45) as response:
        return json.load(response)


def validate(build, version):
    attrs = build['attributes']
    if attrs['processingState'] in ('FAILED','INVALID'):
        raise ValueError('Apple processing failed: '+attrs['processingState'])
    if attrs['processingState'] != 'VALID':
        return False
    if attrs.get('expired'):
        raise ValueError('The uploaded build has expired')
    if attrs.get('buildAudienceType') != 'APP_STORE_ELIGIBLE':
        raise ValueError('Build is not marked APP_STORE_ELIGIBLE by Apple')
    if version != os.environ['IPA_MARKETING_VERSION']:
        raise ValueError('Unexpected marketing version: '+version)
    return True


def main():
    bundle = os.environ.get('IPA_BUNDLE_IDENTIFIER') or 'com.ghehyoein.IPAKeyboard'
    apps = api('apps', {'filter[bundleId]':bundle})['data']
    if len(apps) != 1:
        raise SystemExit('Expected one App Store Connect app for the configured bundle ID')
    app = apps[0]['id']
    build_number = os.environ['IPA_BUILD_NUMBER']
    for attempt in range(61):
        try:
            result = api('builds', {'filter[app]':app, 'filter[version]':build_number,
                                   'include':'preReleaseVersion', 'limit':10})
            versions = {item['id']:item['attributes']['version'] for item in result.get('included',[])
                        if item['type']=='preReleaseVersions'}
            for build in result['data']:
                relation = build['relationships']['preReleaseVersion']['data']['id']
                version = versions.get(relation)
                if validate(build, version):
                    message = f"TestFlight {version} ({build_number}): VALID; APP_STORE_ELIGIBLE."
                    print(message)
                    with open(os.environ['GITHUB_STEP_SUMMARY'],'a') as f:
                        f.write('\n'+message+'\n')
                        f.write(f'App Store Connect: https://appstoreconnect.apple.com/apps/{app}/testflight/ios\n')
                    return
            print(f'Waiting for Apple processing: build {build_number}, attempt {attempt+1}/61')
        except urllib.error.HTTPError as error:
            if error.code != 429 and error.code < 500:
                raise SystemExit(f'App Store Connect verification failed: HTTP {error.code}')
            print(f'Apple API temporarily unavailable: HTTP {error.code}')
        if attempt < 60:
            time.sleep(30)
    raise SystemExit('Upload was accepted, but processing was not confirmed within 30 minutes. Do not upload a duplicate; inspect this build in App Store Connect.')


if __name__ == '__main__':
    main()
