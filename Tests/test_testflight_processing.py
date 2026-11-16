import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from verify_testflight import validate

class ProcessingTests(unittest.TestCase):
    @patch.dict(os.environ, IPA_MARKETING_VERSION='0.8.2')
    def test_requires_valid_store_eligible_matching_build(self):
        build = {'attributes': dict(processingState='VALID', expired=False, buildAudienceType='APP_STORE_ELIGIBLE')}
        self.assertTrue(validate(build, '0.8.2'))
        with self.assertRaises(ValueError): validate(build, '0.8.1')
        build['attributes']['buildAudienceType'] = 'INTERNAL_ONLY'
        with self.assertRaises(ValueError): validate(build, '0.8.2')

    def test_waits_for_processing_but_rejects_failure(self):
        self.assertFalse(validate({'attributes': dict(processingState='PROCESSING')}, None))
        for state in ['FAILED', 'INVALID']:
            with self.assertRaises(ValueError): validate({'attributes': dict(processingState=state)}, None)
