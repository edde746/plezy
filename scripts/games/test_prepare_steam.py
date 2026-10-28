"""Exercise real cross-process source preparation locking without network I/O."""
import multiprocessing
from pathlib import Path
import tempfile
import unittest

from prepare_steam import preparation_lock


def hold(destination, entered, release):
    with preparation_lock(Path(destination), timeout=2):
        entered.set()
        release.wait(5)


class SourceLockTest(unittest.TestCase):
    def test_competing_builder_times_out_without_mutating_sources(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / 'steam'
            # Spawn also exercises the Windows process model.
            context = multiprocessing.get_context('spawn')
            entered, release = context.Event(), context.Event()
            child = context.Process(target=hold, args=(str(destination), entered, release))
            child.start()
            try:
                self.assertTrue(entered.wait(3))
                with self.assertRaises(TimeoutError):
                    with preparation_lock(destination, timeout=0.05):
                        self.fail('A second builder entered the source transaction')
                self.assertFalse(destination.exists())
            finally:
                release.set()
                child.join(3)
                if child.is_alive():
                    child.terminate()
                    child.join()
            self.assertEqual(child.exitcode, 0)
            with preparation_lock(destination, timeout=0.1):
                destination.mkdir()
            self.assertTrue((Path(temporary) / '.steam-prepare.lock').exists())

    def test_exception_releases_lock_for_the_next_builder(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / 'steam'
            with self.assertRaises(ValueError):
                with preparation_lock(destination):
                    raise ValueError('Failed build')
            with preparation_lock(destination, timeout=0.1):
                destination.mkdir()


if __name__ == '__main__':
    unittest.main()
