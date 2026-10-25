# Security remediation — 25 October 2026

Scope: the six source findings reproduced in PlezyNG and upstream Plezy. The upstream comparison is against `edde746/plezy@d1c957ba4aa0addb2ca5474cc7043b50d72d2482`. The fork remediation started at `8c1334bd4dbd7752e864912491e49c3b9a6e61b5` and incorporates the intervening main changes through `3d17bc4289619b6b18e9394e00a5b18a79b67156`.

| Finding | Resolution | Upstream relevance |
| --- | --- | --- |
| Public account/server identifiers could authenticate companion remote control | Protocol 2 requires a random 128-bit host pairing capability; authenticated peers remember it in the credential vault. Resetting the host code disconnects and revokes existing pairings. Legacy authentication is rejected. | Present in `remote_auth_service.dart` and the peer handshake. Submit upstream. |
| libmpv could send authenticated playback requests without verifying HTTPS certificates | Enable certificate and hostname verification on every native video/audio core and before Dart can load media. Supply CA roots where the bundled TLS backend needs them. | Present in shared C++/Apple and Android startup options. Submit upstream. |
| HTTP endpoints could win discovery or become fallback paths for HTTPS credentials | Prefer successful HTTPS probes, remove HTTP fallbacks from HTTPS connections, and require explicit consent before new HTTP password/token/Quick Connect flows. | Present in Jellyfin/Emby discovery and onboarding. Submit that portion upstream; Direct Plex changes belong only to the fork. |
| Vault encryption key lived beside encrypted data; tracker tokens and Seerr cookies were persisted in plaintext | Store AES keys in OS credential storage; versioned ciphertext records its immutable key ID. Verify legacy key migration before removing the plaintext key. Encrypt complete tracker/Seerr sessions and pairing capabilities. | Present in the vault and both session stores. Submit upstream with platform adapters and migration tests. |
| Fragmented unauthenticated WebSocket messages bypassed the delivered-message size limit | Enforce a transport byte budget before WebSocket reassembly, including control/continuation frames, while retaining peer-count and authentication time limits. | Present in the companion peer listener. Submit upstream. |
| Short support-log identifiers were guessable bearer capabilities | New identifiers use 130 random bits. Old identifiers remain readable only for their existing three-day lifetime. | Present in `server/main.go`. Submit upstream; deployment of the relay is separately required. |

CI also identified [GO-2026-6809](https://pkg.go.dev/vuln/GO-2026-6809) in the pinned Go 1.27.2 standard library. Both relay patches move to Go 1.27.3 and its verified multi-architecture container digest. This additional upstream dependency fix is relevant.

## Compatibility and migration

- Companion remote devices must update together and pair once using the host's displayed code. Keeping the old identifier-only protocol would preserve the vulnerability. Pairing codes are secrets; share them only with intended controllers.
- Existing explicitly configured HTTP servers remain usable. New HTTP sign-in/Quick Connect/token transmission requires consent. An HTTPS connection no longer silently falls back to HTTP; an administrator must explicitly configure an intended HTTP connection.
- Trusted HTTPS playback remains supported. Linux uses system roots; Android exports its installed system/user authorities; Apple and Windows use the shipped Mozilla CA bundle. Private authorities on Apple/Windows require an explicit `tls-ca-file` in the existing mpv configuration. Untrusted/self-signed certificates are deliberately rejected. Keep the bundled CA roots updated.
- Credential migration is lazy and preserves existing credentials. OS-store write/read failures propagate without deleting the legacy key or converting a temporarily unavailable token into an empty token. Missing device-bound keys after a device restore require signing in again. Downgrading to an old app after migration cannot read v2 credentials.
- Linux requires an available unlocked Secret Service/keyring or supported libsecret portal backend. There is no plaintext fallback. Snap declares `password-manager-service`; installations without automatic connection need `sudo snap connect plezyng:password-manager-service`. Android backup rules exclude device-bound credential-key files.
- The vendored Linux storage implementation isolates vault keys into distinct Secret Service entries and fixes a schema-name lifetime bug. Windows uses Credential Manager directly to avoid a plugin wrapping-key creation race. tvOS has a small native Keychain adapter.

## Fork release trust and remaining administrator work

The inherited Sparkle/WinSparkle public key has been removed. Release builds enable native updating only when `SPARKLE_PUBLIC_KEY` is configured. If a private signing seed is supplied, the build verifies it matches the public key; the inherited upstream key and malformed/mismatched keys fail the build. Without fork-owned key configuration, GitHub release checks/manual downloads remain available and native updating stays disabled. The existing appcast generator already omitted unsigned enclosures; this audit does **not** claim it published unsigned updates.

Repository administration is outside the connected GitHub application's permission set. The inspected main branch had no protection/rulesets. An administrator still needs to:

1. Protect `main`: require pull requests and the relevant CI checks, block deletion/force pushes, and restrict bypasses and release environments to trusted maintainers.
2. Generate a fork-owned Ed25519 updater key using the updater's supported tooling. Configure the public key as repository variable `SPARKLE_PUBLIC_KEY` and the matching private seed as secret `SPARKLE_PRIVATE_KEY`. Never commit the private material. The public-key transition requires a trusted installer/manual update for existing installations.
3. Deploy the updated support relay to retire issuance of short log identifiers; committing app code does not deploy that service.

## Upstream submission decision

Recommend upstream fixes for all six confirmed core findings, preferably as focused changes for pairing, transport/TLS, credential storage, WebSocket limits, and relay identifiers. The prepared upstream branch is based directly on the upstream revision above and omits fork-only branding, updater ownership, Direct Plex functionality, and unrelated fork test repairs. Coordinate the authentication/credential disclosure with upstream maintainers before opening public vulnerability discussions. No upstream PR or disclosure message has been sent as part of this work.

## Validation

Validation results are recorded with the remediation PR. The upstream-specific patch passed 255 targeted tests and static analysis. Regression coverage includes rejected legacy/wrong-code remote authentication, fragmented-frame byte limits, credential migration and OS-store failure recovery, full-session encryption, HTTP consent guards, and playback TLS initialization ordering. A loopback libmpv test uses only generated certificates and dummy credentials to check untrusted certificates, explicitly trusted certificates, and hostname mismatch. Release-key configuration is checked with public test vectors.

Unit tests and source checks cannot prove absence of bugs. Native CI compilation/tests and subsequent device smoke testing remain necessary, especially locked keychains, first-launch migration, Snap/Flatpak portal behavior, and private-CA playback on each supported platform.
