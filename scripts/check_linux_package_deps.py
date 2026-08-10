#!/usr/bin/env python3
"""Guard distro dependencies for host libraries linked by the Linux runner.

The runner's CMake link graph maps through pkg-config modules to the hand-maintained
package lists. This catches undeclared runtime libraries before they fail on users'
machines; the built-bundle check covers plugin links unavailable before `pub get`.
"""

from pathlib import Path
import ast
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
if len(sys.argv) > 2:
    raise SystemExit(f"Usage: {Path(sys.argv[0]).name} [linux-dir]")
LINUX = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else ROOT / "linux"

RUNNER_CMAKE = LINUX / "runner/CMakeLists.txt"
PACKAGES_PY = LINUX / "packaging/build-packages.py"
BUNDLE_SH = LINUX / "packaging/bundle-libs.sh"
# Runner-linked pkg_check_modules may be declared in any of these files.
CMAKE_FILES = (RUNNER_CMAKE, LINUX / "CMakeLists.txt", LINUX / "flutter/CMakeLists.txt")

# Bundled modules have no host dependency; their excluded runtime links are
# checked separately against the built bundle.
BUNDLED_MODULES = {"mpv"}

# pkg-config module -> runtime package name for each distro.
RUNTIME_PACKAGES = {
    "gtk+-3.0": {"deb": "libgtk-3-0", "rpm": "gtk3", "pacman": "gtk3"},
    "epoxy": {"deb": "libepoxy0", "rpm": "libepoxy", "pacman": "libepoxy"},
    # Reached through the `flutter` INTERFACE target.
    "glib-2.0": {"deb": "libglib2.0-0", "rpm": "glib2", "pacman": "glib2"},
    "gio-2.0": {"deb": "libglib2.0-0", "rpm": "glib2", "pacman": "glib2"},
    "wayland-client": {
        "deb": "libwayland-client0",
        "rpm": "libwayland-client",
        # Arch ships all libwayland-* libraries in `wayland`.
        "pacman": "wayland",
    },
    "wayland-egl": {
        "deb": "libwayland-egl1",
        "rpm": "libwayland-egl",
        "pacman": "wayland",
    },
    # libglvnd provides libEGL.so.1.
    "egl": {"deb": "libegl1", "rpm": "libglvnd-egl", "pacman": "libglvnd"},
}

errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        errors.append(f"{path}: cannot read: {error}")
        return ""


LINK_KEYWORDS = {"PRIVATE", "PUBLIC", "INTERFACE", "optimized", "debug", "general"}
# Link keywords and pkg_check_modules options are not module names.
PKG_OPTIONS = ("REQUIRED", "QUIET", "GLOBAL", "NO_CMAKE_PATH", "NO_CMAKE_ENVIRONMENT_PATH")


def strip_comments(text: str) -> str:
    """A `#` comment containing `)` would otherwise truncate a call body.

    That is the fail-open direction: every target after the comment vanishes and
    the guard still exits 0, which is the whole bug class it exists to catch.
    """
    return re.sub(r"#[^\n]*", "", text)


def link_token(raw: str) -> str:
    """`$<LINK_ONLY:PkgConfig::X>` and `"PkgConfig::X"` both name PkgConfig::X."""
    return re.sub(r"^\$<[^:]*:", "", raw.strip('"')).rstrip(">")


def link_graph(text: str) -> dict[str, list[str]]:
    """target -> everything target_link_libraries() gives it, in order."""
    graph: dict[str, list[str]] = {}
    for match in re.finditer(r"target_link_libraries\(\s*([^\s)]+)\s*([^)]*)\)", strip_comments(text)):
        name = match.group(1).replace("${BINARY_NAME}", "BINARY")
        tokens = [link_token(t) for t in match.group(2).split()]
        graph.setdefault(name, []).extend(t for t in tokens if t not in LINK_KEYWORDS)
    return graph


def linked_pkgconfig_targets(text: str) -> set[str]:
    """Every PkgConfig:: target that reaches the runner's link line.

    A library hands its dependencies to whatever links it - CMake puts even
    PRIVATE ones of a static library on the consumer's link line, and an
    INTERFACE target exists only to propagate them - so an internal target has to
    be followed rather than treated as a leaf. `wayland_protocols PUBLIC
    PkgConfig::WAYLAND_CLIENT` and `flutter INTERFACE PkgConfig::GTK` are both
    invisible otherwise, the latter across a file boundary.
    """
    graph = link_graph(text)
    targets: set[str] = set()
    seen: set[str] = set()
    queue = ["BINARY"]
    while queue:
        current = queue.pop()
        if current in seen:
            continue
        seen.add(current)
        for token in graph.get(current, []):
            if token.startswith("PkgConfig::"):
                targets.add(token[len("PkgConfig::") :])
            elif token in graph:
                queue.append(token)
    return targets


def pkgconfig_modules() -> dict[str, list[str]]:
    """CMake variable prefix -> every pkg-config module the call names.

    A single call may name several - `pkg_check_modules(X REQUIRED
    IMPORTED_TARGET a b c)` makes one PkgConfig::X that links all three - and
    taking only the first is the fail-open direction: the extra libraries reach
    the binary while the guard reports a clean run. wayland-cursor and
    xkbcommon are the natural companions of a subsurface and grouping them into
    the existing call is the natural way to add them, so this is the next edit
    to this file rather than a hypothetical.
    """
    modules: dict[str, list[str]] = {}
    options = "|".join(PKG_OPTIONS)
    for path in CMAKE_FILES:
        for match in re.finditer(
            # Skip options before module names.
            r"pkg_check_modules\(\s*(\w+)\b[^)]*?IMPORTED_TARGET\s+((?:(?:" + options + r")\s+)*[^)]*)\)",
            strip_comments(read(path)),
        ):
            # Strip version constraints before package lookup.
            names = [
                re.split(r"[<>=!]", t, maxsplit=1)[0] for t in match.group(2).split() if t not in PKG_OPTIONS
            ]
            names = [n for n in names if n]
            if names:
                modules.setdefault(match.group(1), names)
    return modules


def declared_depends() -> dict[str, list[str]]:
    """distro -> depends list, read from the DISTROS literal by AST."""
    tree = ast.parse(read(PACKAGES_PY), filename=str(PACKAGES_PY))
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        if not any(isinstance(t, ast.Name) and t.id == "DISTROS" for t in node.targets):
            continue
        table = ast.literal_eval(node.value)
        return {name: list(config.get("depends", [])) for name, config in table.items()}
    errors.append(f"{PACKAGES_PY}: no DISTROS assignment to read the depends lists from")
    return {}


# Include every owned CMake input; missing files fail closed instead of shrinking
# the graph and silently passing.
absent = [path for path in CMAKE_FILES if not path.is_file()]
if absent:
    for path in absent:
        print(
            f"ERROR: {path}: expected CMake input is missing, so the dependency walk "
            "would silently cover less than it claims",
            file=sys.stderr,
        )
    sys.exit(1)

cmake_text = "\n".join(read(path) for path in CMAKE_FILES)
modules = pkgconfig_modules()
depends = declared_depends()

require(bool(depends), "no distro depends lists were found, so nothing was checked")

# These libraries must remain host-provided; bundling them would invalidate this guard.
bundle = read(BUNDLE_SH)
for pattern in (r"libEGL\.so", r"libwayland.*\.so"):
    require(
        pattern in bundle,
        f"bundle-libs.sh no longer excludes {pattern}: if those are bundled now, "
        "the depends entries this guard demands may be wrong",
    )

linked = linked_pkgconfig_targets(cmake_text)
require(
    bool(linked),
    "found no PkgConfig:: link reaching ${BINARY_NAME}; the link-line parse is broken, not the build",
)

checked_modules = 0
for target in sorted(linked):
    target_modules = modules.get(target)
    if not target_modules:
        errors.append(
            f"PkgConfig::{target} is linked into the runner but no pkg_check_modules "
            f"declares it in {', '.join(p.name for p in CMAKE_FILES)}"
        )
        continue
    for module in target_modules:
        checked_modules += 1
        if module in BUNDLED_MODULES:
            # Bundled modules have no host dependency but remain part of the summary.
            continue
        packages = RUNTIME_PACKAGES.get(module)
        if packages is None:
            errors.append(
                f"pkg-config module '{module}' (PkgConfig::{target}) is linked into the runner "
                f"but has no entry in RUNTIME_PACKAGES: name the package that ships its "
                f"runtime library on each distro, then declare it in {PACKAGES_PY.name}"
            )
            continue
        for distro, declared in sorted(depends.items()):
            package = packages.get(distro)
            if package is None:
                errors.append(
                    f"RUNTIME_PACKAGES['{module}'] has no '{distro}' package name, so the "
                    f"{distro} package cannot declare a library the runner links"
                )
                continue
            require(
                package in declared,
                f"the runner links {module} but the {distro} package does not depend on "
                f"'{package}'; bundle-libs.sh will not bundle it, so an installed package "
                f"can fail to start",
            )

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print(
    f"linux/runner CMake dependency checks passed ({len(linked)} pkg-config links, {checked_modules} modules); "
    "Flutter plugin links are out of reach here - check-bundle-host-deps.py covers those from the built bundle"
)
