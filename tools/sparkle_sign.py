#!/usr/bin/env python3
"""Print the Sparkle / WinSparkle EdDSA signature of a file, as the appcast's sparkle:edSignature carries it.

The signature is Ed25519 (RFC 8032) over the file's bytes, base64-encoded: what Sparkle's sign_update prints and what
the macOS app (Sparkle) and the Windows app check against their public key before installing an update. The private
key comes from the environment variable SPARKLE_PRIVATE_KEY, base64 of one of:
  - the 32-byte seed (Sparkle's `generate_keys -x` export);
  - 64 bytes, the seed followed by its public key;
  - 96 bytes, Sparkle's older export: the 64-byte expanded private key followed by the public key.
A key whose stored public key isn't the one its private part derives is refused.

  tools/sparkle_sign.py <file>         prints the signature
  tools/sparkle_sign.py --public-key   prints the key's public key (base64), as the apps embed it

Plain Python, no packages: it runs on every release runner as is. Ed25519 is deterministic, so a key and a file always
give the same signature, which sign_update's matches byte for byte.
"""

from __future__ import annotations

import base64
import binascii
import hashlib
import os
import sys
from pathlib import Path

# Curve25519 in twisted Edwards form (RFC 8032, section 5.1), points in extended coordinates (X, Y, Z, T).
P = 2**255 - 19
L = 2**252 + 27742317777372353535851937790883648493
D = -121665 * pow(121666, P - 2, P) % P
SQRT_M1 = pow(2, (P - 1) // 4, P)
CHUNK = 1 << 20


def _add(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    e1 = (a[1] - a[0]) * (b[1] - b[0]) % P
    e2 = (a[1] + a[0]) * (b[1] + b[0]) % P
    c = 2 * a[3] * b[3] * D % P
    d = 2 * a[2] * b[2] % P
    e, f, g, h = e2 - e1, d - c, d + c, e2 + e1
    return e * f % P, g * h % P, f * g % P, e * h % P


def _mul(s: int, point: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    result = (0, 1, 1, 0)
    while s:
        if s & 1:
            result = _add(result, point)
        point = _add(point, point)
        s >>= 1
    return result


def _encode(point: tuple[int, int, int, int]) -> bytes:
    z_inv = pow(point[2], P - 2, P)
    x, y = point[0] * z_inv % P, point[1] * z_inv % P
    return (y | (x & 1) << 255).to_bytes(32, "little")


def _decode(data: bytes) -> tuple[int, int, int, int] | None:
    y = int.from_bytes(data, "little")
    sign, y = y >> 255, y & ((1 << 255) - 1)
    if y >= P:
        return None
    x2 = (y * y - 1) * pow(D * y * y + 1, P - 2, P) % P
    x = pow(x2, (P + 3) // 8, P)
    if (x * x - x2) % P:
        x = x * SQRT_M1 % P
    if (x * x - x2) % P or (x == 0 and sign):
        return None
    if x & 1 != sign:
        x = P - x
    return x, y, 1, x * y % P


_GY = 4 * pow(5, P - 2, P) % P
BASE = _decode(_GY.to_bytes(32, "little"))


def _sha512(*parts: bytes | Path) -> int:
    """SHA-512 of the parts, a Path read in chunks, as a little-endian integer."""
    digest = hashlib.sha512()
    for part in parts:
        if isinstance(part, Path):
            with part.open("rb") as stream:
                while chunk := stream.read(CHUNK):
                    digest.update(chunk)
        else:
            digest.update(part)
    return int.from_bytes(digest.digest(), "little")


class SigningKey:
    """An Ed25519 private key as its scalar and nonce prefix (RFC 8032's expanded secret key)."""

    def __init__(self, scalar: int, prefix: bytes) -> None:
        self.scalar = scalar
        self.prefix = prefix
        self.public_key = _encode(_mul(scalar, BASE))

    @classmethod
    def from_seed(cls, seed: bytes) -> SigningKey:
        if len(seed) != 32:
            raise ValueError(f"an Ed25519 seed is 32 bytes, not {len(seed)}")
        return cls._from_expanded(hashlib.sha512(seed).digest())

    @classmethod
    def _from_expanded(cls, expanded: bytes) -> SigningKey:
        scalar = int.from_bytes(expanded[:32], "little")
        scalar &= (1 << 254) - 8
        scalar |= 1 << 254
        return cls(scalar, expanded[32:])

    @classmethod
    def from_secret(cls, secret: str) -> SigningKey:
        """Reads SPARKLE_PRIVATE_KEY's value (see the module's documentation for the three forms)."""
        try:
            raw = base64.b64decode("".join(secret.split()), validate=True)
        except binascii.Error as error:
            raise ValueError(f"the private key is not base64: {error}") from None
        if len(raw) == 32:
            return cls.from_seed(raw)
        if len(raw) == 64:
            key, stored = cls.from_seed(raw[:32]), raw[32:]
        elif len(raw) == 96:
            key, stored = cls._from_expanded(raw[:64]), raw[64:]
        else:
            raise ValueError(f"the private key decodes to {len(raw)} bytes, not 32, 64 or 96")
        if key.public_key != stored:
            raise ValueError("the private key's public half is not the one its private half derives")
        return key

    def sign(self, message: bytes | Path) -> bytes:
        """The 64-byte signature of the message, or of a file's contents (read twice, in chunks)."""
        r = _sha512(self.prefix, message) % L
        encoded_r = _encode(_mul(r, BASE))
        k = _sha512(encoded_r, self.public_key, message) % L
        s = (r + k * self.scalar) % L
        return encoded_r + s.to_bytes(32, "little")


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print("usage: sparkle_sign.py <file> | --public-key   (key in SPARKLE_PRIVATE_KEY)", file=sys.stderr)
        return 2
    secret = os.environ.get("SPARKLE_PRIVATE_KEY", "")
    if not secret.strip():
        print("sparkle_sign.py: SPARKLE_PRIVATE_KEY is not set", file=sys.stderr)
        return 1
    try:
        key = SigningKey.from_secret(secret)
    except ValueError as error:
        print(f"sparkle_sign.py: {error}", file=sys.stderr)
        return 1
    if argv[0] == "--public-key":
        print(base64.b64encode(key.public_key).decode("ascii"))
        return 0
    path = Path(argv[0])
    if not path.is_file():
        print(f"sparkle_sign.py: {path} is not a file", file=sys.stderr)
        return 1
    print(base64.b64encode(key.sign(path)).decode("ascii"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
