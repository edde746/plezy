#!/usr/bin/env python3
"""Guard the Linux package dependency lists against what the runner links.

linux/packaging/bundle-libs.sh deliberately refuses to bundle the display- and
driver-coupled libraries (libEGL, libwayland-*, libGL, libdrm ...): they must
come from the host or the app will not talk to the compositor it is running
under. That makes them the package manager's problem, and the depends lists in
linux/packaging/build-packages.py are maintained by hand.

Nothing connected the two. Adding a pkg-config link to the runner produced a
binary with an undeclared shared-library dependency, and the failure surfaces
only on a user's machine at exec time - a class of bug no compile or unit test
can reach. This walks the runner's own link line instead:

  target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::WAYLAND_EGL)
    -> pkg_check_modules(WAYLAND_EGL REQUIRED IMPORTED_TARGET wayland-egl)
    -> RUNTIME_PACKAGES["wayland-egl"] -> libwayland-egl1 / libwayland-egl / wayland

and requires every distro to declare it. A new pkg-config module fails here
until its runtime package names are named for all three.

What it walks is exactly CMAKE_FILES, the three CMakeLists.txt this checkout
owns - and nothing else. The Flutter plugins link into the same binary from
linux/flutter/generated_plugins.cmake, whose add_subdirectory() targets live
under flutter/ephemeral/.plugin_symlinks/, a directory that only exists after
`flutter pub get`. A plugin's own pkg_check_modules is therefore unreadable at
pull-request time, and a plugin that starts linking a new host library passes
here. linux/packaging/check-bundle-host-deps.py is what covers that: it runs
ldd over the built bundle, where every link edge is finally real.
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
# pkg_check_modules for targets the runner links may live in any of these.
CMAKE_FILES = (RUNNER_CMAKE, LINUX / "CMakeLists.txt", LINUX / "flutter/CMakeLists.txt")

# pkg-config modules whose library ships *inside* the package instead of being
# depended on. libmpv is pinned and Wayland-enabled because the video plane needs
# it to be; a distro libmpv silently drops hwdec to vaapi-copy. Bundling it means
# there is deliberately no runtime dependency to find, so the walk must not
# demand one - but the libraries it links that bundle-libs.sh excludes still have
# to be declared, which the packaging job re-derives from the built bundle.
BUNDLED_MODULES = {"mpv"}

# pkg-config module -> the package that ships its runtime library, per distro.
# Only modules the runner actually links are consulted, so an unused entry here
# is harmless; a missing one is an error.
RUNTIME_PACKAGES = {
    "gtk+-3.0": {"deb": "libgtk-3-0", "rpm": "gtk3", "pacman": "gtk3"},
    "epoxy": {"deb": "libepoxy0", "rpm": "libepoxy", "pacman": "libepoxy"},
    # Reached through the `flutter` INTERFACE target rather than named by the
    # runner, which is why the graph has to cross file boundaries to see them.
    "glib-2.0": {"deb": "libglib2.0-0", "rpm": "glib2", "pacman": "glib2"},
    "gio-2.0": {"deb": "libglib2.0-0", "rpm": "glib2", "pacman": "glib2"},
    "wayland-client": {
        "deb": "libwayland-client0",
        "rpm": "libwayland-client",
        # Arch ships every libwayland-* in the one `wayland` package.
        "pacman": "wayland",
    },
    "wayland-egl": {
        "deb": "libwayland-egl1",
        "rpm": "libwayland-egl",
        "pacman": "wayland",
    },
    # libglvnd is the vendor-neutral dispatch that provides libEGL.so.1.
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


# Keywords that carry no target name.
LINK_KEYWORDS = {"PRIVATE", "PUBLIC", "INTERFACE", "optimized", "debug", "general"}
# Options CMake accepts between IMPORTED_TARGET and the module names, in any order.
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
            # The options may precede the module names, so skip any run of them
            # rather than taking the first token and reporting `REQUIRED` as a
            # package nobody ships. The tail is then every remaining token up to
            # the closing paren.
            r"pkg_check_modules\(\s*(\w+)\b[^)]*?IMPORTED_TARGET\s+((?:(?:" + options + r")\s+)*[^)]*)\)",
            strip_comments(read(path)),
        ):
            # A moduleSpec is `<name>` or `<name><op><version>`, so the version
            # constraint has to come off before the name is looked up - otherwise
            # a perfectly legal `mpv>=0.40` is reported as a package nobody
            # ships, and the message sends whoever hits it off to invent a
            # RUNTIME_PACKAGES entry for it. Pinning that minimum is a plausible
            # next edit here: target-colorspace-hint=auto needs mpv 0.40.
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


# Every file, not just the runner's: `flutter` is defined in flutter/CMakeLists.txt
# and propagates GTK, GLIB and GIO to whatever links it, so a graph built from one
# file treats it as a leaf and never sees them. A member that moved or was renamed
# is fatal rather than a smaller walk: its modules drop out of the graph, a
# declaration deleted alongside it goes unreported, and every check below then
# passes over a tree nobody actually looked at.
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

# The exclusion list is what makes declaring these mandatory rather than
# optional. If bundling ever starts covering them, this guard is the wrong shape.
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
            # Shipped inside the package, so there is no dependency to find. Still
            # counted, so the summary keeps naming everything the walk reached and
            # a module going missing is a drop rather than a silent skip.
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
