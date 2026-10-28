import 'dart:convert';
import 'dart:io';

// Self-signed CA, valid until 2126; mirrors android/.../UserCertificateChannelTest.kt.
const _privateAuthorityPem = '''
-----BEGIN CERTIFICATE-----
MIIBpjCCAU2gAwIBAgIUE2B0ftvgw24qfGGZDgg9ahCt6W4wCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVUGxlenkgVGVzdCBQcml2YXRlIENBMCAXDTI2MDkxMzEwMDQ1
MloYDzIxMjYwODIwMTAwNDUyWjAgMR4wHAYDVQQDDBVQbGV6eSBUZXN0IFByaXZh
dGUgQ0EwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATRtBIaHTld7jouEH7XGewU
K0lQXk04cKOtASHwiJ4yeaG3IwqwUzKprnIbJ9LO8j8Yug6Z3b6UuFmmR9nCy3Z0
o2MwYTAdBgNVHQ4EFgQUMkopaSNoRnirfv98G1AIU57Bfd8wHwYDVR0jBBgwFoAU
MkopaSNoRnirfv98G1AIU57Bfd8wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8E
BAMCAQYwCgYIKoZIzj0EAwIDRwAwRAIgZ05Qu7LVaJYl3CabUJ0FvJVe6lHTsbNk
2rBsxeQin20CIHTBFcdyUpAop/I2fotqNzyyP6Awz6V5B8E6phpnwoa5
-----END CERTIFICATE-----
''';

const localTlsAuthorityPem = _privateAuthorityPem;

// Leaf for localhost / 127.0.0.1 issued by the authority above.
const _serverLeafPem = '''
-----BEGIN CERTIFICATE-----
MIIBxjCCAWugAwIBAgIUELPXCK88VPZica3MS4eHc+WP0cEwCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVUGxlenkgVGVzdCBQcml2YXRlIENBMCAXDTI2MDkxMzEwMDQ1
MloYDzIxMjYwODIwMTAwNDUyWjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwWTATBgcq
hkjOPQIBBggqhkjOPQMBBwNCAARyNHegHEHgV3jdV3igrqT2XMTZdUUGJS8seSTH
Ef5c0SbWphL3bkaJkJrmwkG2zLeztPkpcShdhF9NhmFDuFiVo4GMMIGJMBoGA1Ud
EQQTMBGCCWxvY2FsaG9zdIcEfwAAATAJBgNVHRMEAjAAMAsGA1UdDwQEAwIHgDAT
BgNVHSUEDDAKBggrBgEFBQcDATAdBgNVHQ4EFgQUza0Nj5xZ8PAzmrIZqtwLKp1E
9lAwHwYDVR0jBBgwFoAUMkopaSNoRnirfv98G1AIU57Bfd8wCgYIKoZIzj0EAwID
SQAwRgIhAK5tJYi21adtGCItM7NMz2s+feAwx0jyGICU5B1s88DCAiEArPUwqZSl
5yJJLTVYtdCVgZrAH3SJ8eau3/uKmx7uXSo=
-----END CERTIFICATE-----
''';

const _serverKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgH4LEt+A2RvrYcUy7
yysLq2toiAdeT+kXlUxy3AMeAwyhRANCAARyNHegHEHgV3jdV3igrqT2XMTZdUUG
JS8seSTHEf5c0SbWphL3bkaJkJrmwkG2zLeztPkpcShdhF9NhmFDuFiV
-----END PRIVATE KEY-----
''';

// Reuse the repository's public, test-only localhost fixture. Verification stays
// enabled; no production/private authority is trusted by this client.
class _RealHttp extends HttpOverrides {}

SecurityContext localTlsAuthorityContext() =>
    SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(utf8.encode(localTlsAuthorityPem));

HttpClient localTlsClient() => _RealHttp().createHttpClient(localTlsAuthorityContext())..findProxy = (_) => 'DIRECT';

SecurityContext localTlsServer() => SecurityContext()
  ..useCertificateChainBytes(utf8.encode('$_serverLeafPem$_privateAuthorityPem'))
  ..usePrivateKeyBytes(utf8.encode(_serverKeyPem));
