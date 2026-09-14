#!/usr/bin/env python3
"""Require immutable, architecture-declared production container images."""

from __future__ import annotations

from dataclasses import dataclass
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRODUCTION_DOCKERFILES = (ROOT / "server" / "Dockerfile",)
PRODUCTION_COMPOSE_FILES = (ROOT / "server" / "docker-compose.yml",)
SUPPORTED_PLATFORMS = frozenset({"linux/amd64", "linux/arm64"})

FROM_RE = re.compile(
    r"^\s*FROM(?:\s+--platform=(?:\S+))?\s+(?P<reference>\S+)",
    re.IGNORECASE,
)
IMAGE_RE = re.compile(r"^\s*image\s*:\s*(?P<reference>[^\s#]+)\s*(?:#.*)?$")
PLATFORMS_RE = re.compile(r"^\s*#\s*Platforms\s*:\s*(?P<platforms>.+?)\s*$", re.IGNORECASE)
PINNED_REFERENCE_RE = re.compile(
    r"^(?P<name>[a-z0-9]+(?:[._-][a-z0-9]+)*(?::[0-9]+)?"
    r"(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*)"
    r":(?P<tag>[A-Za-z0-9_][A-Za-z0-9_.-]{0,127})"
    r"@sha256:(?P<digest>[0-9a-f]{64})$"
)


@dataclass(frozen=True)
class ImageReference:
    path: Path
    line_number: int
    reference: str
    platforms: frozenset[str] | None


def _adjacent_platforms(lines: list[str], reference_index: int) -> frozenset[str] | None:
    for index in range(reference_index - 1, -1, -1):
        stripped = lines[index].strip()
        if not stripped:
            break
        if not stripped.startswith("#"):
            break
        match = PLATFORMS_RE.match(lines[index])
        if match:
            values = (value.strip() for value in match.group("platforms").split(","))
            return frozenset(value for value in values if value)
    return None


def iter_dockerfile_references(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    for index, line in enumerate(lines):
        match = FROM_RE.match(line)
        if not match:
            continue
        reference = match.group("reference")
        if reference.lower() == "scratch":
            continue
        yield ImageReference(
            path=path,
            line_number=index + 1,
            reference=reference,
            platforms=_adjacent_platforms(lines, index),
        )


def iter_compose_references(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    for index, line in enumerate(lines):
        match = IMAGE_RE.match(line)
        if not match:
            continue
        yield ImageReference(
            path=path,
            line_number=index + 1,
            reference=match.group("reference").strip("'\""),
            platforms=_adjacent_platforms(lines, index),
        )


def validate_image(image: ImageReference) -> list[str]:
    violations = []
    match = PINNED_REFERENCE_RE.fullmatch(image.reference)
    if not match:
        violations.append(
            "external images must use a readable tag and full lowercase sha256 digest"
        )
    elif match.group("tag").lower() == "latest":
        violations.append("the readable image tag must not be latest")

    if image.platforms is None:
        violations.append(
            "an adjacent '# Platforms:' declaration is required for each external image"
        )
    elif image.platforms != SUPPORTED_PLATFORMS:
        expected = ", ".join(sorted(SUPPORTED_PLATFORMS))
        actual = ", ".join(sorted(image.platforms)) or "none"
        violations.append(f"platforms must be exactly {expected}; found {actual}")
    return violations


def _display_path(path: Path) -> Path:
    try:
        return path.resolve().relative_to(ROOT)
    except ValueError:
        return path


def check_paths(dockerfiles: list[Path], compose_files: list[Path]) -> list[str]:
    images = []
    for path in dockerfiles:
        images.extend(iter_dockerfile_references(path))
    for path in compose_files:
        images.extend(iter_compose_references(path))

    violations = []
    for image in images:
        for reason in validate_image(image):
            violations.append(
                f"{_display_path(image.path)}:{image.line_number}: "
                f"{image.reference!r}: {reason}"
            )
    return violations


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if args:
        dockerfiles = [Path(value) for value in args if Path(value).name == "Dockerfile"]
        compose_files = [Path(value) for value in args if Path(value).name != "Dockerfile"]
    else:
        dockerfiles = list(PRODUCTION_DOCKERFILES)
        compose_files = list(PRODUCTION_COMPOSE_FILES)

    violations = check_paths(dockerfiles, compose_files)
    if violations:
        print("Mutable or malformed production container references:", file=sys.stderr)
        for violation in violations:
            print(f"  {violation}", file=sys.stderr)
        return 1

    image_count = sum(
        1 for path in dockerfiles for _ in iter_dockerfile_references(path)
    ) + sum(1 for path in compose_files for _ in iter_compose_references(path))
    print(
        f"Production container pins verified ({image_count} external images; "
        f"platforms: {', '.join(sorted(SUPPORTED_PLATFORMS))})."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
