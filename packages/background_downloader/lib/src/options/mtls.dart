import 'dart:io';

/// Holds configuration options for mutual TLS (mTLS) client authentication.
///
/// Use with [Config.mTLS] to configure client certificate authentication for
/// HTTPS connections on desktop platforms.
///
/// Provide either file paths ([certificatePath], [privateKeyPath]) or raw bytes
/// ([certificateBytes], [privateKeyBytes]) for the client certificate and private key.
/// An optional private key [password] can be supplied if required.
///
/// An optional [host] can be specified to restrict this configuration to a specific host
/// (e.g. `'api.example.com'`). If [host] is `null`, the mTLS configuration applies globally
/// (or as the default for all hosts).
///
/// To reset/clear mTLS for a host or globally, pass an [MTLSConfig] instance with no credentials
/// (or `null`/`false` in configuration).
final class MTLSConfig {
  /// Optional host (domain or IP) to which this mTLS configuration applies.
  /// If null, applies to all hosts / default.
  final String? host;

  /// Path to client certificate / chain file (PEM or DER format).
  final String? certificatePath;

  /// Bytes of client certificate / chain file (PEM or DER format).
  final List<int>? certificateBytes;

  /// Path to private key file (PEM format).
  final String? privateKeyPath;

  /// Bytes of private key file (PEM format).
  final List<int>? privateKeyBytes;

  /// Optional password for decrypting the private key or certificate.
  final String? password;

  /// Optional path to trusted server / CA certificate file.
  final String? serverCertificatePath;

  /// Optional bytes of trusted server / CA certificate file.
  final List<int>? serverCertificateBytes;

  /// Creates an [MTLSConfig] instance.
  ///
  /// Asserts that parameters are legally combined (e.g. not providing both file path
  /// and raw bytes for the same asset, and ensuring both certificate and key are provided
  /// when configuring credentials).
  const MTLSConfig({
    this.host,
    this.certificatePath,
    this.certificateBytes,
    this.privateKeyPath,
    this.privateKeyBytes,
    this.password,
    this.serverCertificatePath,
    this.serverCertificateBytes,
  }) : assert(
         !(certificatePath != null && certificateBytes != null),
         'Cannot provide both certificatePath and certificateBytes',
       ),
       assert(
         !(privateKeyPath != null && privateKeyBytes != null),
         'Cannot provide both privateKeyPath and privateKeyBytes',
       ),
       assert(
         !(serverCertificatePath != null && serverCertificateBytes != null),
         'Cannot provide both serverCertificatePath and serverCertificateBytes',
       ),
       assert(
         ((certificatePath != null || certificateBytes != null) &&
                 (privateKeyPath != null || privateKeyBytes != null)) ||
             ((certificatePath == null && certificateBytes == null) &&
                 (privateKeyPath == null && privateKeyBytes == null)),
         'Both certificate and privateKey must be provided together, or both omitted for reset',
       );

  /// Returns true if client certificate and key credentials are specified.
  bool get hasCredentials =>
      (certificatePath != null || certificateBytes != null) &&
      (privateKeyPath != null || privateKeyBytes != null);

  /// Returns true if this configuration is a reset configuration (no credentials).
  bool get isReset => !hasCredentials;

  /// Applies this mTLS configuration to the given [context].
  void applyToSecurityContext(SecurityContext context) {
    if (certificatePath != null) {
      context.useCertificateChain(certificatePath!, password: password);
    } else if (certificateBytes != null) {
      context.useCertificateChainBytes(certificateBytes!, password: password);
    }

    if (privateKeyPath != null) {
      context.usePrivateKey(privateKeyPath!, password: password);
    } else if (privateKeyBytes != null) {
      context.usePrivateKeyBytes(privateKeyBytes!, password: password);
    }

    if (serverCertificatePath != null) {
      context.setTrustedCertificates(
        serverCertificatePath!,
        password: password,
      );
    } else if (serverCertificateBytes != null) {
      context.setTrustedCertificatesBytes(
        serverCertificateBytes!,
        password: password,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MTLSConfig &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          certificatePath == other.certificatePath &&
          _listEquals(certificateBytes, other.certificateBytes) &&
          privateKeyPath == other.privateKeyPath &&
          _listEquals(privateKeyBytes, other.privateKeyBytes) &&
          password == other.password &&
          serverCertificatePath == other.serverCertificatePath &&
          _listEquals(serverCertificateBytes, other.serverCertificateBytes);

  @override
  int get hashCode =>
      host.hashCode ^
      certificatePath.hashCode ^
      Object.hashAll(certificateBytes ?? []) ^
      privateKeyPath.hashCode ^
      Object.hashAll(privateKeyBytes ?? []) ^
      password.hashCode ^
      serverCertificatePath.hashCode ^
      Object.hashAll(serverCertificateBytes ?? []);
}

bool _listEquals(List<int>? a, List<int>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
