# Plezy GKUI 1.0.2 Plex certificate-chain fix

Build date: 2026-09-29.

## Physical evidence

Version 1.0.1 reached native HTTPS but failed before receiving media with:

`SSLHandshakeException -> CertificateException -> CertPathValidatorException`

The date on the head unit was correct. Resolution changes cannot fix this error;
certificate-path validation happens before video data or codec negotiation.

## Root-cause match

This is a high-confidence match for a Plex Media Server certificate incident
reported after renewals beginning around 2026-09-20. Affected `plex.direct`
servers sent the leaf and Let's Encrypt YR2 intermediate but omitted the
cross-signed Root YR link. Strict clients therefore could not build a path to
the established ISRG Root X1 trust anchor. The prior Plezy bundle contained X1
but not the new Generation-Y link. The exact issuer on this user's server was
not captured, so physical validation is still required.

References:

- Plex report with the same incomplete YR2 chain and remediation:
  https://forums.plex.tv/t/https-certs-are-missing-trust-roots/943238
- Let's Encrypt's authoritative Generation-Y chain definitions and certificates:
  https://letsencrypt.org/certificates/

## Change

The strict native trust bundle now includes the official Let’s Encrypt
cross-signed Generation-Y certificates:

- Root YR signed by ISRG Root X1 (RSA)
- Root YE signed by ISRG Root X2 (ECDSA)

Certificate-chain validation and hostname verification remain enabled. There is
no trust-all manager, hostname bypass, plaintext fallback, or user certificate
import. TLS remains limited to TLS 1.2/1.3.

## Verification

- The bundle parses as five X.509 certificates, all currently valid.
- A native unit test verifies the Root YR signature using the bundled ISRG Root
  X1 public key and checks both Generation-Y subjects and issuers.
- Four native unit tests pass in total.
- Ten Flutter tests pass; static analysis reports no issues.
- Android release lint passes.
- The signed APK was inspected and contains Root YR, Root YE, and ISRG Root X1.
- APK identity: `com.jialim.plezygkui`, version 1.0.2 (4), min SDK 19,
  ARMv7 only, v1/v2 signed with the same update-compatible signer.
- SHA-256:
  `0b6043f4ed239f78d3c40527e31420c2091599d1060cedc728c55d5a07d0c00c`

## Deliverable and remaining limit

`build/gkui/Plezy-GKUI-1.0.2-api19-armeabi-v7a.apk`

Install over version 1.0.1. This desktop verification proves the intended
missing trust link is present and valid, but does not prove which certificate
chain the user's Plex server presents or certify playback on the XE1115H. One
physical playback attempt is still required.
