#!/usr/bin/env python3
"""Return a small source-generation patch in CI logs; never writes to GitHub."""
import base64
import subprocess
import zlib

patch = subprocess.run(["git", "diff", "--binary", "--", "lib", "test"], check=True, capture_output=True).stdout
if len(patch) > 4 * 1024 * 1024:
    raise SystemExit("generation diff too large; inspect the runner instead")
print("PLEZYNG_DV_PATCH_BEGIN")
print(base64.b64encode(zlib.compress(patch)).decode("ascii"))
print("PLEZYNG_DV_PATCH_END")
