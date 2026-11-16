import sys
import unittest
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from testflight_simulator import validations_passed, validation_configuration


class SimulatorReuseTests(unittest.TestCase):
    def setUp(self):
        self.jobs = [dict(name=f'validate ({name}, macos-15)', conclusion='success')
                     for name in ('iOS26-iPhone', 'iOS17-iPad')]

    def test_requires_every_device_configuration(self):
        self.assertFalse(validations_passed(self.jobs[:-1]))
        self.jobs[0]['conclusion'] = 'failure'
        self.assertFalse(validations_passed(self.jobs))

    def test_independent_auxiliary_failure_does_not_invalidate_app_tests(self):
        self.assertTrue(validations_passed(self.jobs + [dict(name='auxiliary', conclusion='failure')]))


    def test_release_changes_do_not_hide_validation_changes(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'workflow.yml'
            path.write_text('jobs:\n  validate:\n    tests: all\n  release:\n    runs-on: macos-15\n')
            baseline = validation_configuration(path)
            path.write_text('jobs:\n  validate:\n    tests: all\n  release:\n    uses: isolated.yml\n')
            self.assertEqual(validation_configuration(path), baseline)
            path.write_text('jobs:\n  validate:\n    tests: all\n  release:\n    runs-on: ubuntu-latest\n')
            self.assertEqual(validation_configuration(path), baseline)
            path.write_text('jobs:\n  validate:\n    tests: subset\n  release:\n    uses: isolated.yml\n')
            self.assertNotEqual(validation_configuration(path), baseline)
