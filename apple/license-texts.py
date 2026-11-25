#!/usr/bin/env python3
"""The licence texts an Apple app ships, which About shows: the groups of the repository's licenses/ that
licenses/apps.json gives the app (ios, macos or tvos), each folder of them in the app's resources as licenses/<folder>,
and mpv-build's, which MPVKit's resource bundle carries: MPVKit__MPVKit.bundle/licenses/<component>/ in the app's
resources (in the bundle's Contents/Resources on the Mac), one folder per component of the package, which mpv-build
collects from the sources it built.

  license-texts.py <ios|macos|tvos> <resources folder>           replaces <resources folder>/licenses with them, then checks
  license-texts.py --check <ios|macos|tvos> <resources folder>   checks a built app's

The check fails (exit 1, naming each file) unless <resources folder>/licenses holds exactly those files, byte for byte,
and MPVKit's bundle has its licenses/ with a non-empty text in each component's folder. The apps' build phase runs it
after their other phases, so a build without every text fails.
"""

import argparse
import filecmp
import json
from pathlib import Path
import shutil
import sys

LICENSES = Path(__file__).resolve().parents[1] / "licenses"


def texts(app: str) -> dict:
    """Each text's path under licenses/ → its file in the repository; exits naming a group that isn't a folder of
    licenses/ or holds no file (renamed or mistyped, its texts would otherwise be left out unnoticed)."""
    found = {}
    for group in json.loads((LICENSES / "apps.json").read_text())[app]:
        root = LICENSES / group
        if not root.is_dir():
            sys.exit(f"licenses/apps.json gives {app} licenses/{group}, which isn't a folder")
        files = sorted(path for path in root.rglob("*") if path.is_file())
        if not files:
            sys.exit(f"licenses/{group}, which licenses/apps.json gives {app}, holds no licence texts")
        for file in files:
            path = file.relative_to(root).as_posix()
            if path in found:
                sys.exit(f"licenses/{group}/{path}: also in {found[path]}")
            found[path] = file
    if not found:
        sys.exit(f"licenses/apps.json gives {app} no licence texts")
    return found


def check(expected: dict, folder: Path) -> list:
    shipped = {path.relative_to(folder).as_posix() for path in folder.rglob("*") if path.is_file()} if folder.is_dir() else set()
    problems = [f"missing: {path}" for path in sorted(expected.keys() - shipped)]
    problems += [f"not the repository's: {path}" for path in sorted(expected.keys() & shipped)
                 if not filecmp.cmp(expected[path], folder / path, shallow=False)]
    problems += [f"not in licenses/: {path}" for path in sorted(shipped - expected.keys())]
    return problems


def check_mpvkit(folder: Path) -> list:
    """The problems of MPVKit's licenses/ [folder]: absent, empty, or a component's folder without a non-empty text."""
    components = sorted(path for path in folder.iterdir() if path.is_dir()) if folder.is_dir() else []
    if not components:
        return [f"no licence texts of mpv-build's components in {folder} (MPVKit at apple/project.yml's pin)"]
    return [f"no licence text in {component}" for component in components
            if not any(path.is_file() and path.stat().st_size > 0 for path in component.rglob("*"))]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="only check a built app's texts")
    parser.add_argument("app", choices=["ios", "macos", "tvos"])
    parser.add_argument("resources", type=Path)
    args = parser.parse_args()
    expected = texts(args.app)
    folder = args.resources / "licenses"
    if not args.check:
        shutil.rmtree(folder, ignore_errors=True)
        for path, file in expected.items():
            (folder / path).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(file, folder / path)
    problems = check(expected, folder)
    if problems:
        sys.exit(f"{folder} lacks licence texts licenses/ gives {args.app}, or holds others:\n  " + "\n  ".join(problems))
    bundle = args.resources / "MPVKit__MPVKit.bundle"
    mpvkit = (bundle / "Contents" / "Resources" if args.app == "macos" else bundle) / "licenses"
    problems = check_mpvkit(mpvkit)
    if problems:
        sys.exit("\n".join(problems))
    components = sum(1 for path in mpvkit.iterdir() if path.is_dir())
    print(f"{folder}: all {len(expected)} licence texts of {args.app}; {mpvkit}: {components} components' texts")


if __name__ == "__main__":
    main()
