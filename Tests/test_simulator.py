import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('create_simulator', Path(__file__).resolve().parents[1]/'tools/create_simulator.py')
simulator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(simulator)

class SimulatorSelection(unittest.TestCase):
    def runtime(self, version, devices, available=True):
        return dict(name='iOS '+version, version=version, identifier='runtime-'+version,
                    isAvailable=available, supportedDeviceTypes=[dict(name=name, identifier=identifier) for name, identifier in devices])

    def test_supported_runtime_and_phone_selection(self):
        records = [self.runtime('25.0', [('iPhone A','a')]),
                   self.runtime('26.9', [('iPhone A','a')]),
                   self.runtime('26.10', [('iPad A','tablet'), ('iPhone B','b')]),
                   self.runtime('27.0', [('iPhone C','c')], available=False)]
        runtime, device = simulator.select(records, '26.0')
        self.assertEqual(runtime['version'], '26.10')
        self.assertEqual(device['identifier'], 'b')
        self.assertEqual(simulator.select(records, '26.0', 'a')[1]['identifier'], 'a')
        for minimum, requested in [('28.0', None), ('26.0', 'missing')]:
            with self.assertRaises(ValueError): simulator.select(records, minimum, requested)
