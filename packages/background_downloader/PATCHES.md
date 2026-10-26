# Vendored background downloader

This directory contains `background_downloader` 9.6.2 from
`edde746/background_downloader` commit
`7c341be73df8a6a5ddccb06124807ac250a32bc1`.

PlezyNG-specific changes:

- Register `flutter_secure_storage` in Android's headless callback engine so
  encrypted leases can resolve credentials after the app process stops.
- Retain the original encrypted task descriptor while an auth callback runs.
  Android status, progress, resume data, and system re-enqueue paths use that
  descriptor. Both mobile native status paths omit credentialed response bodies
  and headers; Android also clears its in-memory entry on final state.
- Follow at most five same-origin HTTPS GET redirects for callback-authenticated
  Android tasks; reject cross-origin, non-GET, and TLS downgrade redirects.
- Reject TLS downgrades on iOS, reject cross-origin redirects for
  callback-authenticated tasks, and strip sensitive request headers from other
  cross-origin redirects.
- Continue the optional task-start callback on both mobile platforms after an auth callback returns a request without its own Auth object.
- Include a consumer shrinker rule for the reflectively loaded vault plugin.

All other included source files match the pinned upstream commit. Provider
leases with query parameters or expiry still require provider-specific refresh;
this supports stable HTTPS header leases accepted by PlezyNG's existing validator.
