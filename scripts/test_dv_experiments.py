#!/usr/bin/env python3
"""Make experimental routing/companion tests part of ordinary CI guards."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/dv-engine"))

if __name__ == "__main__":
    suite = unittest.defaultTestLoader.discover(str(ROOT / "tools/dv-engine"), pattern="test_*.py")
    raise SystemExit(not unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful())
