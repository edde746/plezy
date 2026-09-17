import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_logger.dart';

/// Which certificate authorities a dart:io TLS handshake may trust, per host.
///
/// dart:io does its own TLS in BoringSSL. On Android that means the system
/// store on disk and nothing else: `network_security_config.xml` is read by
/// the platform stack alone (`background_downloader`, ExoPlayer's Cronet data
/// source), so its `<certificates src="user" />` anchor stopped reaching the
/// app's own requests when Cronet was dropped (#2140). A self-hosted server
/// behind a private CA the device owner installed then failed every probe —
/// #1564 came back as #2339.
///
/// [loadUserAuthorities] pulls that user store over a platform channel and
/// [contextFor] hands it out for exactly the hosts the security config gives
/// it to: everything except the fixed first-party endpoints, which carry
/// account tokens and OAuth codes and by construction never sit behind a
/// private CA. Those keep [SecurityContext.defaultContext] and its system
/// anchors, mirroring the `<domain-config>` block. Every other platform
/// already consults the owner-managed store (keychain, `/etc/ssl/certs`,
/// Schannel) and is left alone.
abstract final class CertificateTrust {
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('com.plezy/user_certificates');

  /// Parent domains of every hard-coded HTTPS endpoint, matched together with
  /// their subdomains. Kept equal to the `<domain-config>` in
  /// `android/app/src/main/res/xml/network_security_config.xml`;
  /// `test/android/network_security_config_test.dart` pins both to the sources.
  static const Set<String> fixedEndpointDomains = {
    'plex.tv',
    'plezy.app',
    'trakt.tv',
    'myanimelist.net',
    'anilist.co',
    'simkl.com',
    'simkl.in',
    'jsdelivr.net',
    'api.github.com',
    'image.tmdb.org',
  };

  static SecurityContext? _userAuthorities;

  /// Whether [host] is one of [fixedEndpointDomains] or a subdomain of one.
  static bool isFixedEndpoint(String host) {
    final candidate = host.toLowerCase();
    for (final domain in fixedEndpointDomains) {
      if (candidate == domain) return true;
      final parentStart = candidate.length - domain.length;
      if (parentStart > 0 && candidate.endsWith(domain) && candidate.codeUnitAt(parentStart - 1) == 0x2e /* . */ ) {
        return true;
      }
    }
    return false;
  }

  /// The context a direct TLS connection to [host] should verify against, or
  /// null to keep the SDK default (system anchors only).
  static SecurityContext? contextFor(String host) {
    final authorities = _userAuthorities;
    if (authorities == null || isFixedEndpoint(host)) return null;
    return authorities;
  }

  /// Reads the owner-installed authorities from the platform and makes them
  /// available through [contextFor]. Android only; callers gate on platform.
  ///
  /// Never throws. An unreadable store, a missing channel or an unparsable
  /// bundle is logged and leaves system-only trust in place, so it is safe to
  /// start early and await later. Certificates installed while the app is
  /// running are picked up on the next launch, like every other Android app.
  static Future<void> loadUserAuthorities() async {
    try {
      final pem = await channel.invokeMethod<String>('getUserAuthoritiesPem');
      if (pem == null || pem.isEmpty) return;
      final context = SecurityContext(withTrustedRoots: true)..setTrustedCertificatesBytes(utf8.encode(pem));
      _userAuthorities = context;
      final count = '-----BEGIN CERTIFICATE-----'.allMatches(pem).length;
      appLogger.i('Trusting $count user-installed certificate authorities for user-entered hosts');
    } catch (e, st) {
      appLogger.w(
        'User-installed certificate authorities unavailable; keeping system anchors',
        error: e,
        stackTrace: st,
      );
    }
  }

  @visibleForTesting
  static void debugReset() => _userAuthorities = null;
}
