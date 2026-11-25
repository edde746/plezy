#!/usr/bin/env python3
"""Tests of tools/sparkle_sign.py: RFC 8032's vectors, the three key forms and the command line.

With SPARKLE_SIGN_UPDATE naming Sparkle's sign_update (Sparkle's release archive's bin/sign_update, macOS only), the
signatures are also compared with the ones it prints for the same key and file.
"""

from __future__ import annotations

import base64
import contextlib
import hashlib
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import sparkle_sign  # noqa: E402

# RFC 8032, section 7.1, TEST 1 to 3: secret key (seed), public key, message, signature.
RFC_8032_VECTORS = [
    (
        "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
        "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
        "",
        "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b",
    ),
    (
        "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
        "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
        "72",
        "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00",
    ),
    (
        "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
        "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
        "af82",
        "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a",
    ),
]


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def expanded_key(seed: bytes) -> bytes:
    """Sparkle's older 64-byte private key (orlp ed25519): SHA-512 of the seed with the scalar clamped."""
    expanded = bytearray(hashlib.sha512(seed).digest())
    expanded[0] &= 248
    expanded[31] &= 63
    expanded[31] |= 64
    return bytes(expanded)


class SparkleSignTest(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.file = Path(self.directory.name) / "plezy-macos.dmg"
        # More than one read chunk, so the streamed hashes cross a chunk boundary.
        self.file.write_bytes(os.urandom(sparkle_sign.CHUNK * 2 + 12345))

    def run_main(self, argv: list[str], secret: str | None) -> tuple[int, str, str]:
        env = {} if secret is None else {"SPARKLE_PRIVATE_KEY": secret}
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, env, clear=True), contextlib.redirect_stdout(stdout), \
                contextlib.redirect_stderr(stderr):
            status = sparkle_sign.main(argv)
        return status, stdout.getvalue(), stderr.getvalue()

    def test_rfc_8032_vectors(self) -> None:
        for seed, public, message, signature in RFC_8032_VECTORS:
            with self.subTest(public=public):
                key = sparkle_sign.SigningKey.from_seed(bytes.fromhex(seed))
                self.assertEqual(key.public_key.hex(), public)
                self.assertEqual(key.sign(bytes.fromhex(message)).hex(), signature)

    def test_prints_the_keys_signature_and_public_key(self) -> None:
        seed = os.urandom(32)
        key = sparkle_sign.SigningKey.from_seed(seed)
        status, out, err = self.run_main([str(self.file)], b64(seed))
        self.assertEqual(status, 0, err)
        self.assertEqual(out, b64(key.sign(self.file.read_bytes())) + "\n")

        status, out, err = self.run_main(["--public-key"], b64(seed))
        self.assertEqual(status, 0, err)
        self.assertEqual(out, b64(key.public_key) + "\n")

    def test_streamed_file_signature_equals_in_memory_signature(self) -> None:
        key = sparkle_sign.SigningKey.from_seed(os.urandom(32))
        self.assertEqual(key.sign(self.file), key.sign(self.file.read_bytes()))

    def test_every_key_form_signs_alike(self) -> None:
        seed = os.urandom(32)
        public_key = sparkle_sign.SigningKey.from_seed(seed).public_key
        signatures = {
            sparkle_sign.SigningKey.from_secret(secret).sign(self.file)
            for secret in (b64(seed), b64(seed + public_key), b64(expanded_key(seed) + public_key), f" {b64(seed)}\n")
        }
        self.assertEqual(len(signatures), 1)

    def test_rejects_malformed_keys(self) -> None:
        seed = os.urandom(32)
        wrong_public = sparkle_sign.SigningKey.from_seed(os.urandom(32)).public_key
        for secret, reason in (
            (b64(seed[:31]), "31 bytes"),
            (b64(seed + wrong_public), "public half"),
            (b64(expanded_key(seed) + wrong_public), "public half"),
            ("not base64!", "not base64"),
        ):
            with self.subTest(reason=reason):
                status, out, err = self.run_main([str(self.file)], secret)
                self.assertEqual(status, 1)
                self.assertEqual(out, "")
                self.assertIn(reason, err)

    def test_requires_the_key_and_a_file(self) -> None:
        status, _, err = self.run_main([str(self.file)], None)
        self.assertEqual((status, "SPARKLE_PRIVATE_KEY is not set" in err), (1, True))
        status, _, err = self.run_main([str(self.file.with_name("missing.dmg"))], b64(os.urandom(32)))
        self.assertEqual((status, "is not a file" in err), (1, True))
        status, _, _ = self.run_main([], b64(os.urandom(32)))
        self.assertEqual(status, 2)

    @unittest.skipUnless(os.environ.get("SPARKLE_SIGN_UPDATE"), "SPARKLE_SIGN_UPDATE names no sign_update")
    def test_matches_sparkle_sign_update(self) -> None:
        sign_update = os.environ["SPARKLE_SIGN_UPDATE"]
        seed = os.urandom(32)
        public_key = sparkle_sign.SigningKey.from_seed(seed).public_key
        # sign_update reads the seed or the older 96-byte form; both must give this script's signature.
        for secret in (b64(seed), b64(expanded_key(seed) + public_key)):
            with self.subTest(length=len(base64.b64decode(secret))):
                result = subprocess.run(
                    [sign_update, "--ed-key-file", "-", "-p", str(self.file)],
                    input=secret + "\n", capture_output=True, text=True, check=True,
                )
                status, out, err = self.run_main([str(self.file)], secret)
                self.assertEqual(status, 0, err)
                self.assertEqual(out.strip(), result.stdout.strip())


if __name__ == "__main__":
    unittest.main()
