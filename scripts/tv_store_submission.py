#!/usr/bin/env python3
"""Create deterministic manual handoff bundles for Samsung and LG TV stores."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import sys
import zipfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PROFILES: dict[str, dict[str, Any]] = {
    "samsung": {
        "store": "Samsung TV Seller Office",
        "portal": "https://seller.samsungapps.com/tv/",
        "package_suffix": ".tpk",
        "architecture": "ARM Tizen TV",
        "application_id": "org.snapetech.plezyng",
        "platform": "Samsung Smart TV / Tizen",
        "regional_note": (
            "A Public Seller is limited to the United States. Partner Seller "
            "approval is required for distribution outside the United States."
        ),
        "signing_note": (
            "Confirm that the named security profile is authorized for Seller "
            "Office distribution. The bundle builder cannot inspect that account approval."
        ),
    },
    "lg": {
        "store": "LG Seller Lounge / LG Content Store",
        "portal": "https://seller.lgappstv.com/",
        "package_suffix": ".ipk",
        "architecture": "ARMv7 webOS TV",
        "application_id": "org.snapetech.plezyng",
        "platform": "LG webOS TV",
        "regional_note": (
            "Confirm the approved seller account and supported countries in Seller Lounge."
        ),
        "signing_note": (
            "Confirm the IPK and runtime libraries meet the Seller Lounge requirements "
            "and the repository's LG redistribution gate."
        ),
    },
}


def valid_version(value: str) -> bool:
    parts = value.split(".")
    return len(parts) == 3 and all(
        part.isdigit() and (part == "0" or not part.startswith("0")) for part in parts
    )


def valid_commit(value: str) -> bool:
    return 7 <= len(value) <= 40 and all(char.lower() in "0123456789abcdef" for char in value)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_regular_file(path: Path) -> bytes:
    if path.is_symlink():
        raise ValueError(f"refusing symlink input: {path}")
    resolved = path.resolve(strict=True)
    if not resolved.is_file():
        raise ValueError(f"input is not a regular file: {path}")
    return resolved.read_bytes()


def archive_file(entries: dict[str, bytes], archive_path: str, source: Path) -> None:
    name = source.name
    if not name or name in {".", ".."}:
        raise ValueError(f"invalid input filename: {source}")
    archive_path = f"{archive_path.rstrip('/')}/{name}"
    if archive_path in entries:
        raise ValueError(f"duplicate archive path: {archive_path}")
    entries[archive_path] = read_regular_file(source)


def make_readme(profile: dict[str, Any], args: argparse.Namespace, package_hash: str) -> str:
    lines = [
        f"# PlezyNG manual submission handoff: {profile['store']}",
        "",
        f"- App: PlezyNG ({profile['application_id']})",
        f"- Version: {args.version}",
        f"- Package: package/{args.package.name}",
        f"- Package SHA-256: {package_hash}",
        f"- Source commit: {args.source_commit}",
        f"- Store portal: {profile['portal']}",
        "- Submission method: sign in to the seller portal and upload the package manually.",
        "",
        "## Before submission",
        "",
        "- Confirm seller-account approval, app identity, availability by country, and current store requirements.",
        f"- {profile['regional_note']}",
        f"- {profile['signing_note']}",
        "- Capture genuine screenshots from the supported TV app. This bundle contains no fabricated or placeholder screenshots.",
        "- Complete the seller portal's listing, age/content rating, privacy, test-account, and review fields as applicable.",
        "- Check the included store listing copy and privacy policy against the final app build.",
        "- Review the evidence files in evidence/; they are build records, not a substitute for store certification.",
        "",
        "## Scope and handling",
        "",
        "This ZIP prepares files for manual review. It does not sign, upload, submit, or publish the app to either vendor store.",
        "It does not independently verify the package signature or establish device compatibility; use the attached build evidence and target-device qualification records.",
        "No store credentials, private keys, TV addresses, or device identifiers are included.",
        "PlezyNG is a public repository. Treat its GitHub Actions artifacts as accessible to repository readers.",
        "",
    ]
    if args.release_gates_passed:
        lines.extend([
            "The release workflow's exact-candidate eligibility gate passed before this LG bundle was created. This is not LG Seller Lounge approval.",
            "",
        ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--store", choices=sorted(PROFILES), required=True)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--evidence", type=Path, action="append", default=[])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--release-gates-passed",
        action="store_true",
        help="Record that the LG exact-candidate release gate passed before bundling.",
    )
    args = parser.parse_args()

    try:
        profile = PROFILES[args.store]
        if not valid_version(args.version):
            raise ValueError("version must be a semantic version such as 2.24.1")
        if not valid_commit(args.source_commit):
            raise ValueError("source commit must be a hexadecimal Git commit SHA")
        if args.package.suffix.lower() != profile["package_suffix"]:
            raise ValueError(f"{args.store} packages must end in {profile['package_suffix']}")
        if args.store == "lg" and not args.release_gates_passed:
            raise ValueError("LG handoff bundles may only be created after the exact-candidate release gate passes")
        if not args.evidence:
            raise ValueError("at least one package inspection or provenance file must be included")
        if args.release_gates_passed and args.store != "lg":
            raise ValueError("--release-gates-passed is only valid for an LG bundle")

        package_bytes = read_regular_file(args.package)
        if not package_bytes:
            raise ValueError("package file is empty")

        entries: dict[str, bytes] = {}
        archive_file(entries, "package", args.package)
        seen_evidence: set[str] = set()
        for evidence in args.evidence:
            if evidence.name in seen_evidence or evidence.name == args.package.name:
                raise ValueError(f"duplicate evidence filename: {evidence.name}")
            seen_evidence.add(evidence.name)
            archive_file(entries, "evidence", evidence)

        entries["listing/store-listing-copy.md"] = read_regular_file(
            ROOT / "docs/maintainers/store-listing-copy.md"
        )
        entries["legal/PRIVACY.md"] = read_regular_file(ROOT / "PRIVACY.md")
        entries["legal/LICENSE"] = read_regular_file(ROOT / "LICENSE")

        included_files = [
            {"path": name, "sha256": sha256(data), "size": len(data)}
            for name, data in sorted(entries.items())
        ]
        manifest = {
            "schema": "org.snapetech.plezyng.tv-store-handoff.v1",
            "store": profile["store"],
            "platform": profile["platform"],
            "application_id": profile["application_id"],
            "application_name": "PlezyNG",
            "version": args.version,
            "architecture": profile["architecture"],
            "package": {
                "path": f"package/{args.package.name}",
                "sha256": sha256(package_bytes),
                "size": len(package_bytes),
            },
            "source_commit": args.source_commit.lower(),
            "release_eligibility_gate": (
                "passed for this exact LG candidate" if args.release_gates_passed
                else "not asserted by the bundle builder"
            ),
            "submission": {
                "method": "manual seller-portal upload",
                "automated_upload_supported": False,
                "seller_account_approval": "not recorded by this bundle",
                "tv_screenshots_included": False,
                "private_credentials_included": False,
            },
            "included_files": included_files,
        }
        entries["submission.json"] = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
        entries["SUBMISSION.md"] = make_readme(profile, args, sha256(package_bytes)).encode()

        output = args.output
        if output.exists() and output.is_symlink():
            raise ValueError(f"refusing symlink output: {output}")
        output.parent.mkdir(parents=True, exist_ok=True)
        temporary = output.with_name(output.name + ".tmp")
        if temporary.exists() and temporary.is_symlink():
            raise ValueError(f"refusing symlink temporary output: {temporary}")
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name, data in sorted(entries.items()):
                info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                info.create_system = 3
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (stat.S_IFREG | 0o644) << 16
                archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        os.replace(temporary, output)
        print(json.dumps({
            "store": profile["store"],
            "package_sha256": sha256(package_bytes),
            "bundle": str(output),
            "bundle_sha256": sha256(output.read_bytes()),
            "source_commit": args.source_commit.lower(),
            "submission_method": "manual seller-portal upload",
        }, sort_keys=True))
        return 0
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"TV store handoff preparation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
