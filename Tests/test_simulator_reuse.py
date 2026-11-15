import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from testflight_simulator import validations_passed


class SimulatorReuseTests(unittest.TestCase):
    def setUp(self):
        self.jobs = [dict(name=f'validate ({name}, macos-15)', conclusion='success')
                     for name in ('iOS26-iPhone', 'iOS17-iPhone-SE', 'iOS17-iPad', 'iOS26-iPad')]

    def test_requires_every_device_configuration(self):
        self.assertFalse(validations_passed(self.jobs[:-1]))
        self.jobs[0]['conclusion'] = 'failure'
        self.assertFalse(validations_passed(self.jobs))

    def test_independent_auxiliary_failure_does_not_invalidate_app_tests(self):
        self.assertTrue(validations_passed(self.jobs + [dict(name='auxiliary', conclusion='failure')]))

