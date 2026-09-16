#!/usr/bin/env python3
"""Check the installed user Flatpak against its runtime, not the build SDK.

Run after `flatpak install --user ./plezy-linux-<arch>.flatpak`.
This does not replace graphical playback verification on a Wayland desktop.
"""

import argparse
import subprocess

# The runtime includes Bash, od and ldd, but not necessarily Python/readelf.
# Enumerate inside the sandbox: the host must not resolve these dependencies.
CHECK = r'''
set -euo pipefail
export LD_LIBRARY_PATH=/app/plezy/lib
for executable in /app/bin/plezy /app/plezy/plezy /app/plezy/plezy.sh; do
    test -x "$executable" || { echo "Not executable: $executable" >&2; exit 1; }
done
if test -f /app/plezy/lib/crashpad_handler; then
    test -x /app/plezy/lib/crashpad_handler
fi
count=0
while IFS= read -r -d '' object; do
    magic=$(od -An -tx1 -N4 "$object")
    if [[ "$magic" != *"7f 45 4c 46"* ]]; then continue; fi
    dependencies=$(ldd "$object" 2>&1) || { echo "$dependencies" >&2; exit 1; }
    if [[ "$dependencies" == *"not found"* ]]; then
        printf 'Unresolved dependency in %s:\n%s\n' "$object" "$dependencies" >&2
        exit 1
    fi
    count=$((count + 1))
done < <(find /app/plezy -type f -print0)
test "$count" -gt 0
printf 'Resolved all dependencies for %s ELF objects in the installed runtime.\n' "$count"
'''

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--arch", choices=("x64", "arm64"), help="defaults to the host architecture")
args = parser.parse_args()
architecture = {"x64": "x86_64", "arm64": "aarch64"}.get(args.arch)
arch_options = [f"--arch={architecture}"] if architecture else []

subprocess.run([
    "flatpak", "run", "--user", *arch_options, "--command=bash", "com.edde746.plezy", "-c", CHECK,
], check=True)
