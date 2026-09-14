import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from check_container_image_pins import (
    ImageReference,
    SUPPORTED_PLATFORMS,
    check_paths,
    iter_compose_references,
    iter_dockerfile_references,
    main,
    validate_image,
)

DIGEST = "0123456789abcdef" * 4
PLATFORMS = frozenset({"linux/amd64", "linux/arm64"})


class ContainerImagePinsTest(unittest.TestCase):
    def test_accepts_readable_digest_pins_for_supported_platforms(self) -> None:
        references = [
            f"golang:1.22.12-alpine3.21@sha256:{DIGEST}",
            f"ghcr.io/owner/image:sha-0123456@sha256:{DIGEST}",
        ]
        for reference in references:
            with self.subTest(reference=reference):
                image = ImageReference(Path("fixture"), 1, reference, PLATFORMS)
                self.assertEqual(validate_image(image), [])

    def test_rejects_mutable_or_malformed_external_images(self) -> None:
        references = [
            "golang:1.22-alpine",
            "golang:latest",
            "golang@sha256:" + DIGEST,
            "${BUILDER_IMAGE}",
            f"golang:1.22@sha256:{DIGEST.upper()}",
            "golang:1.22@sha256:0123456",
        ]
        for reference in references:
            with self.subTest(reference=reference):
                image = ImageReference(Path("fixture"), 1, reference, PLATFORMS)
                self.assertTrue(validate_image(image))

        latest = ImageReference(
            Path("fixture"),
            1,
            f"ghcr.io/owner/image:latest@sha256:{DIGEST}",
            PLATFORMS,
        )
        self.assertIn("must not be latest", " ".join(validate_image(latest)))

    def test_requires_exact_supported_platform_declaration(self) -> None:
        reference = f"registry.example/image:v1@sha256:{DIGEST}"
        cases = [
            (None, "declaration is required"),
            (frozenset({"linux/amd64"}), "linux/arm64"),
            (
                frozenset({"linux/amd64", "linux/arm64", "linux/s390x"}),
                "linux/s390x",
            ),
        ]
        for platforms, expected in cases:
            with self.subTest(platforms=platforms):
                image = ImageReference(Path("fixture"), 1, reference, platforms)
                self.assertIn(expected, " ".join(validate_image(image)))

    def test_parses_production_sources_and_ignores_scratch_and_comments(self) -> None:
        dockerfile = f'''\
# FROM alpine:latest
# Review update details.
# Platforms: linux/amd64, linux/arm64
FROM --platform=$BUILDPLATFORM golang:1.22.12-alpine3.21@sha256:{DIGEST} AS build
FROM scratch
'''
        compose = f'''\
services:
  service:
    # image: alpine:latest
    # Review update details.
    # Platforms: linux/amd64, linux/arm64
    image: "ghcr.io/owner/service:sha-0123456@sha256:{DIGEST}"
'''
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docker_path = root / "Dockerfile"
            compose_path = root / "docker-compose.yml"
            docker_path.write_text(dockerfile, encoding="utf-8")
            compose_path.write_text(compose, encoding="utf-8")
            docker_images = list(iter_dockerfile_references(docker_path))
            compose_images = list(iter_compose_references(compose_path))

        self.assertEqual(len(docker_images), 1)
        self.assertEqual(len(compose_images), 1)
        self.assertEqual(docker_images[0].platforms, SUPPORTED_PLATFORMS)
        self.assertEqual(compose_images[0].platforms, SUPPORTED_PLATFORMS)
        self.assertEqual(validate_image(docker_images[0]), [])
        self.assertEqual(validate_image(compose_images[0]), [])

    def test_checker_reports_each_source_location(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docker_path = root / "Dockerfile"
            compose_path = root / "docker-compose.yml"
            docker_path.write_text("FROM golang:1.22-alpine AS build\n", encoding="utf-8")
            compose_path.write_text(
                "services:\n  bugs:\n    image: ghcr.io/owner/bugs:latest\n",
                encoding="utf-8",
            )
            violations = check_paths([docker_path], [compose_path])
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                status = main([str(docker_path), str(compose_path)])

        self.assertEqual(status, 1)
        self.assertGreaterEqual(len(violations), 4)
        output = stderr.getvalue()
        self.assertIn("Dockerfile:1", output)
        self.assertIn("docker-compose.yml:3", output)
        self.assertIn("golang:1.22-alpine", output)
        self.assertIn("ghcr.io/owner/bugs:latest", output)

    def test_repository_production_references_pass(self) -> None:
        self.assertEqual(main([]), 0)


if __name__ == "__main__":
    unittest.main()
