# Security remediation — 26 October 2026

Addresses the three findings reproduced against `main` at
`a4c98530ca0eb50e14748d067907826aefec286d`.

## S1: credential-bearing redirects

`SafeRedirectClient` disables transport-managed redirects on every hop. It
preserves authentication only for the same scheme, host and effective port,
rejects HTTPS downgrades and URL userinfo, and uses an explicit nonsecret header
allowlist for supported cross-origin GET/HEAD downloads. Credentials removed on
a CDN hop are never restored by a redirect back to the original origin.

The wrapper also protects direct streaming users of
`MediaServerHttpClient.inner`. Same-origin redirects, ranges, final-URI metadata,
POST-to-GET on 303, cancellation, graceful close and existing phase timeouts are
preserved. Unsafe redirects are policy failures, not transient failures that
should trigger endpoint failover. Redirect bodies are cancelled rather than
drained without a size bound.

## S2: cloud settings restore downgrade

Cloud restore uses the same redirect implementation with cross-origin redirects
disabled. Only same-origin HTTPS hops can reach the importer. Existing response
size and active-profile ownership checks remain in effect. Tests verify failed
redirects leave preferences unchanged. The initial audit did not establish a
Basic-password leak; standard Authorization was already stripped by Dart.

## S3: destructive webOS secure-storage failure handling

Reads never initialize, prune or rewrite the saved row. Unavailable key-service
operations, malformed ciphertext and SQLite read errors propagate as errors,
distinct from a missing entry. Every operation reloads persisted state.

Writes stage independent random key names and encrypted envelopes for both the
changed value and the index. Native SQLite compare-and-store commits the entire
row in one transaction, rejecting stale writers, including simultaneous first
use. Previously referenced keys are retired only after a confirmed commit. A
lost commit acknowledgement leaves staging keys intact because the row may
already reference them. Cleanup failure may leave unused OS keys, but cannot
invalidate an active credential. Operations in one isolate share a lock;
cross-isolate conflicts reload and retry within a bounded attempt count.

Existing unversioned rows and entries remain readable. Writes introduce `v2:`
envelopes without changing SQLite columns; untouched legacy entries remain
readable after an index upgrade. Older plugin versions do not understand the
new envelopes, so downgrading the plugin after a write requires restoring a
compatible app version or signing in again. Keep the Dart and native plugin
changes together in the same build.

## Validation

Completed on Linux with Flutter 3.47.1 / Dart 3.13.1: **572 tests passed across
23 affected suites**, including 43 new security regressions. Static analysis of
the changed Dart code/tests passed. The native SQLite harness passed and the
method-channel C++ adapter passed its syntax check. The suites cover existing
Plex/Jellyfin/Emby request behavior, artwork, failover, download cancellation,
timeouts, credential migration, settings export, remote pairing, sources and
the webOS media proxy in addition to the fixes below.

The new suites exercise real loopback TLS/HTTP redirects, same-origin
authentication, CDN and range behavior, body disposal, cancellation, import
ownership/size limits, legacy storage, failure injection, restart recovery,
competing writers and uncertain commit outcomes:

```sh
flutter test --no-pub \
  test/utils/media_server_http_client_redirects_test.dart \
  test/services/cloud_settings_backup_service_test.dart \
  test/services/webos_secure_storage_recovery_test.dart
```

The existing Jellyfin URL suite now blocks unmocked HTTP and explicitly mocks
its independent failover probe. Shared backend fixtures also default public
probes to an isolated mock instead of real external HTTP. All credentials in
these tests are fixtures.
The localhost certificate is the existing public test fixture; TLS verification
remains enabled.

Native SQLite regression checks use the real storage implementation and SQLite
library, with only LG logging replaced in the host harness. On a Linux host
with a C++17 compiler and SQLite development headers:

```sh
c++ -std=c++17 -Wall -Wextra -Werror -pthread \
  -Ipackages/webos_plugins/flutter_secure_storage_webos/webos \
  test/native/webos_secure_storage_test.cc \
  packages/webos_plugins/flutter_secure_storage_webos/webos/secure_storage.cc \
  $(pkg-config --cflags --libs sqlite3) -o /tmp/plezy-webos-storage-test
/tmp/plezy-webos-storage-test
```

This verifies concurrent first insertion/overwrite, stale-writer rejection,
transaction rollback, read-error propagation and retry after an open failure.
The method-channel C++ adapter is also syntax-checked against Flutter headers.
LG hardware behavior still needs device validation; these tests establish the
Dart adapter and native SQLite behavior, not the failure frequency of LG's key
service. Windows WinHTTP execution is likewise outside the Linux test run.
