#!/usr/bin/env python3

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SIGN_RPM = ROOT / "linux/packaging/sign-rpm.sh"
REAL_SIGNING_TOOLS = ("fpm", "gpg", "rpm", "rpmsign")

def generate_private_key_export(
    primary_keys: int,
    capabilities: str = "sign",
    add_signing_subkey: bool = False,
) -> str:
    with tempfile.TemporaryDirectory(prefix="plezy-test-gnupg-", dir="/tmp") as directory:
        home = Path(directory)
        home.chmod(0o700)
        env = os.environ.copy()
        env["GNUPGHOME"] = str(home)
        for index in range(primary_keys):
            subprocess.run(
                [
                    "gpg",
                    "--batch",
                    "--pinentry-mode",
                    "loopback",
                    "--passphrase",
                    "",
                    "--quick-gen-key",
                    f"Plezy RPM Test {index} <rpm-test-{index}@plezy.invalid>",
                    "rsa2048",
                    capabilities,
                    "1d",
                ],
                env=env,
                check=True,
                capture_output=True,
                text=True,
            )
            if add_signing_subkey:
                listing = subprocess.run(
                    ["gpg", "--batch", "--with-colons", "--list-secret-keys", "--fingerprint"],
                    env=env,
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout
                fingerprint = next(
                    line.split(":")[9]
                    for line in listing.splitlines()
                    if line.startswith("fpr:")
                )
                subprocess.run(
                    [
                        "gpg",
                        "--batch",
                        "--pinentry-mode",
                        "loopback",
                        "--passphrase",
                        "",
                        "--quick-add-key",
                        fingerprint,
                        "rsa2048",
                        "sign",
                        "1d",
                    ],
                    env=env,
                    check=True,
                    capture_output=True,
                    text=True,
                )
        return subprocess.run(
            ["gpg", "--batch", "--armor", "--export-secret-keys"],
            env=env,
            check=True,
            capture_output=True,
            text=True,
        ).stdout

def run_signer(private_key: str | None) -> tuple[subprocess.CompletedProcess[str], bytes, list[Path]]:
    with tempfile.TemporaryDirectory(prefix="plezy-sign-rpm-test-", dir="/tmp") as directory:
        temp_dir = Path(directory)
        rpm_path = temp_dir / "plezy.rpm"
        rpm_path.write_bytes(b"unsigned rpm fixture")
        env = os.environ.copy()
        env["RUNNER_TEMP"] = str(temp_dir)
        if private_key is None:
            env.pop("RPM_SIGNING_PRIVATE_KEY", None)
        else:
            env["RPM_SIGNING_PRIVATE_KEY"] = private_key
        result = subprocess.run(
            ["bash", str(SIGN_RPM), str(rpm_path)],
            cwd=ROOT,
            env=env,
            check=False,
            capture_output=True,
            text=True,
        )
        return result, rpm_path.read_bytes(), list(temp_dir.glob("plezy-rpm-signing.*"))

class SignRpmTest(unittest.TestCase):
    def test_missing_or_invalid_key_fails_before_modifying_the_rpm(self) -> None:
        invalid_keys = (
            None,
            "not an OpenPGP private key",
            generate_private_key_export(2),
            generate_private_key_export(1, capabilities="encr"),
        )

        for private_key in invalid_keys:
            with self.subTest(key_supplied=private_key is not None):
                result, package, temporary_paths = run_signer(private_key)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(package, b"unsigned rpm fixture")
                self.assertEqual(temporary_paths, [])
                if private_key:
                    self.assertNotIn(private_key, result.stdout + result.stderr)

    @unittest.skipIf(
        any(shutil.which(tool) is None for tool in REAL_SIGNING_TOOLS),
        "complete RPM signing toolchain is unavailable",
    )
    def test_real_rpm_is_signed_and_verified_with_a_signing_subkey(self) -> None:
        private_key = generate_private_key_export(
            1,
            capabilities="cert",
            add_signing_subkey=True,
        )
        with tempfile.TemporaryDirectory(prefix="plezy-real-signing-test-", dir="/tmp") as directory:
            temp_dir = Path(directory)
            payload = temp_dir / "payload"
            payload.mkdir()
            (payload / "plezy").write_text("package fixture\n", encoding="utf-8")
            rpm_path = temp_dir / "plezy.rpm"
            subprocess.run(
                [
                    "fpm",
                    "-s",
                    "dir",
                    "-t",
                    "rpm",
                    "-n",
                    "plezy",
                    "-v",
                    "1.2.3",
                    "--iteration",
                    "1",
                    "--package",
                    str(rpm_path),
                    f"{payload}/=/opt/plezy/",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            env = os.environ.copy()
            env["RPM_SIGNING_PRIVATE_KEY"] = private_key
            env["RUNNER_TEMP"] = str(temp_dir)
            signing = subprocess.run(
                ["bash", str(SIGN_RPM), str(rpm_path)],
                cwd=ROOT,
                env=env,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(signing.returncode, 0, signing.stderr)
            self.assertNotIn(private_key, signing.stdout + signing.stderr)
            self.assertEqual(list(temp_dir.glob("plezy-rpm-signing.*")), [])

            verification_home = temp_dir / "verification-gnupg"
            verification_home.mkdir(mode=0o700)
            verification_env = os.environ.copy()
            verification_env["GNUPGHOME"] = str(verification_home)
            subprocess.run(
                ["gpg", "--batch", "--import"],
                input=private_key,
                env=verification_env,
                check=True,
                capture_output=True,
                text=True,
            )
            public_key = temp_dir / "public-key.asc"
            public_key.write_text(
                subprocess.run(
                    ["gpg", "--batch", "--armor", "--export"],
                    env=verification_env,
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout,
                encoding="utf-8",
            )
            rpm_database = temp_dir / "verification-rpmdb"
            subprocess.run(
                ["rpm", "--dbpath", str(rpm_database), "--initdb"],
                check=True,
                capture_output=True,
            )
            subprocess.run(
                ["rpm", "--dbpath", str(rpm_database), "--import", str(public_key)],
                check=True,
                capture_output=True,
            )
            verification = subprocess.run(
                ["rpm", "--dbpath", str(rpm_database), "--checksig", str(rpm_path)],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(verification.returncode, 0, verification.stdout + verification.stderr)
            self.assertNotIn("NOKEY", verification.stdout)
            self.assertNotIn("NOT OK", verification.stdout)

if __name__ == "__main__":
    unittest.main()
