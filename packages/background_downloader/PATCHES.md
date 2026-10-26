# Vendored background downloader

This directory contains `background_downloader` 9.6.2 from
`edde746/background_downloader` commit
`7c341be73df8a6a5ddccb06124807ac250a32bc1`.

PlezyNG-specific changes:

- Register `flutter_secure_storage` in Android's headless callback engine so
  encrypted leases can resolve credentials after the app process stops.
- Retain the original encrypted task descriptor while an auth callback runs.
  Android status, progress, resume data, and system re-enqueue paths use that
  descriptor; credentialed response bodies and headers are omitted from status
  records, and the in-memory entry is cleared on final state.
- Disable automatic Android redirects for callback-authenticated tasks. Those
  redirects fail closed instead of forwarding authorization headers.
- Reject TLS downgrades on iOS, reject cross-origin redirects for
  callback-authenticated tasks, and strip sensitive request headers from other
  cross-origin redirects.
- Include a consumer shrinker rule for the reflectively loaded vault plugin.

All other included source files match the pinned upstream commit. Provider
leases with query parameters or expiry still require provider-specific refresh;
this supports stable HTTPS header leases accepted by PlezyNG's existing validator.
