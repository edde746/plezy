import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/certificate_trust.dart';

/// The bundled OpenSSL players do not load platform roots automatically.
/// Linux/GnuTLS retains the system trust store, including private authorities.
/// Android uses its actual system/user store; Apple/Windows use Mozilla roots.
/// An explicit tls-ca-file in the existing mpv configuration can supply a
/// private authority on platforms that cannot export their native trust store.
abstract final class MpvCertificateTrust {
  static Future<String?>? _caFile;

  static Future<String?> caFile() {
    if (Platform.isLinux) return Future.value(null);
    return _caFile ??= _prepare().catchError((Object error, StackTrace stack) {
      _caFile = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  static Future<String> _prepare() async {
    // Never download trust material at playback time or disable verification
    // on failure. A missing/unreadable CA file must fail initialization.
    final pem = Platform.isAndroid
        ? await CertificateTrust.allAndroidAuthoritiesPem()
        : await rootBundle.loadString('assets/certificates/cacert.pem');
    if (pem == null || !pem.contains('-----BEGIN CERTIFICATE-----')) {
      throw StateError('Playback certificate authorities are unavailable');
    }
    final cache = await getTemporaryDirectory();
    // An instance-specific immutable file avoids concurrent isolates/readers
    // observing a truncated file while another player initializes.
    final directory = await cache.createTemp('plezy-mpv-ca-');
    final file = File('${directory.path}/ca.pem');
    await file.writeAsString(pem, flush: true);
    return file.path;
  }
}
