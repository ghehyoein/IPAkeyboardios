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

    def test_explicit_runtime_and_tablet_selection(self):
        records = [self.runtime('17.5', [('iPad A','tablet'), ('iPhone SE','se')]),
                   self.runtime('26.3', [('iPad B','new-tablet-8GB')])]
        runtime, device = simulator.select(records, '17.0', 'tablet', '17', 'iPad')
        self.assertEqual(runtime['version'], '17.5')
        self.assertEqual(device['identifier'], 'tablet')
        self.assertEqual(simulator.select(records, '17.0', 'new-tablet', '26', 'iPad')[1]['identifier'], 'new-tablet-8GB')
        with self.assertRaises(ValueError):
            simulator.select(records, '17.0', runtime_prefix='18')
