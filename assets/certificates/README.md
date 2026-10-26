# Playback trust roots

Mozilla CA bundle from https://curl.se/ca/cacert.pem, retrieved 2026-10-25 over HTTPS and checked against https://curl.se/ca/cacert.pem.sha256.

SHA-256: `796f1389bfea13c0ed78f663b765baaff54a508e5483786bd6ece73c5e3e3cbe`

Licensing/provenance: https://curl.se/docs/caextract.html (Mozilla CA certificates, MPL 2.0). Retain the bundle header. Refresh from that source when updating playback dependencies, verify the published digest, review removed/added roots, and run the TLS regression probe. This is a bundled resource, never fetched or replaced during playback. Linux uses GnuTLS system trust; Android exports AndroidCAStore roots. Apple and Windows private CAs can be supplied with `tls-ca-file` in the existing custom mpv configuration; do not disable `tls-verify`.
