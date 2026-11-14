import 'dart:async';
import 'dart:io' show InternetAddress, InternetAddressType, Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show MethodChannel, MissingPluginException;
import 'package:multicast_dns/multicast_dns.dart';

import '../utils/app_logger.dart';

/// A Music Assistant server found on the LAN.
class DiscoveredMusicAssistantServer {
  /// `http://host:port`, no trailing slash — the shape
  /// [MusicAssistantConnection.baseUrl] wants.
  final String address;

  /// The server's `server_id`. Doubles as the advertised instance name, which
  /// is what makes a discovered server matchable against a stored connection.
  final String id;

  /// Advertised `server_version`, e.g. `2.6.3`. Null when the TXT record is
  /// missing or malformed.
  final String? version;

  const DiscoveredMusicAssistantServer({required this.address, required this.id, this.version});
}

/// Browses the LAN for Music Assistant servers over mDNS.
///
/// The service type is **`_mass._tcp`**. This is the single most common thing
/// to get wrong here: `_music-assistant._tcp` looks like the obvious name, is
/// what the app this replaces browsed for, and returns nothing at all on a
/// network with a live server.
///
/// Shaped like [JellyfinLanDiscoveryService] — a bounded `discover()` returning
/// a deduplicated, stably-sorted list — but the mechanism is different: Jellyfin
/// answers a UDP broadcast, while Music Assistant only advertises over mDNS.
///
/// ### Two browsers, and why iOS gets its own
///
/// `package:multicast_dns` opens a raw UDP socket to 224.0.0.251:5353 and
/// speaks mDNS itself. That is fine on Android, on the desktops, and — the
/// trap — in the iOS **simulator**, which does not enforce the rule that
/// matters. On an iOS *device* it finds nothing at all: since iOS 14 a raw
/// multicast socket needs `com.apple.developer.networking.multicast`, an
/// entitlement Apple grants only on request, and without it the socket does
/// not error, does not close and simply never receives a datagram. There is
/// nothing to catch and nothing to log, so the failure reads as "no server on
/// this network" — which is exactly how it was reported.
///
/// So on iOS the browse goes through `NWBrowser` in
/// `BonjourDiscoveryPlugin`, which asks the `mDNSResponder` daemon that is
/// already doing this work for the whole system and needs no entitlement
/// beyond the `NSBonjourServices` declaration this app already carries. The
/// entitlement route was deliberately not taken: it means an Apple approval
/// round for permission to run a second copy of a daemon that is already
/// running.
///
/// Everywhere else keeps the Dart implementation unchanged. Both paths end at
/// [serverFromAdvert], so the rules about what an advert is allowed to claim
/// live in one place.
///
/// On iOS the type must also appear in `Info.plist` under `NSBonjourServices`,
/// or the local-network privacy rules drop the browse with no error that points
/// at the cause.
class MusicAssistantLanDiscoveryService {
  /// The DNS-SD service name, fully qualified for the local domain.
  static const String serviceType = '_mass._tcp.local';

  /// The bare DNS-SD type, which is what `NWBrowser` wants.
  static const String bonjourServiceType = '_mass._tcp';

  /// Default WebSocket/HTTP port, used when a server advertises no SRV record.
  static const int defaultPort = 8095;

  static const MethodChannel _bonjourChannel = MethodChannel('com.plezy/bonjour_discovery');

  final Future<MDnsClient> Function() _clientFactory;
  final MethodChannel _nativeChannel;

  /// Whether to browse through the platform's own Bonjour API.
  ///
  /// Defaults to iOS only. Injectable so a test can drive either path without
  /// caring which platform it happens to be running on.
  final bool useNativeBrowser;

  MusicAssistantLanDiscoveryService({
    Future<MDnsClient> Function()? clientFactory,
    MethodChannel? nativeChannel,
    bool? useNativeBrowser,
  }) : _clientFactory = clientFactory ?? _defaultClientFactory,
       _nativeChannel = nativeChannel ?? _bonjourChannel,
       useNativeBrowser = useNativeBrowser ?? _defaultUseNativeBrowser;

  static bool get _defaultUseNativeBrowser {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static Future<MDnsClient> _defaultClientFactory() async {
    final client = MDnsClient();
    await client.start();
    return client;
  }

  /// Browse for [browseTimeout], then resolve what answered.
  ///
  /// Every lookup needs its own explicit bound. `MDnsClient.lookup` issues a
  /// one-shot query whose stream then stays open indefinitely waiting for late
  /// responders, so it never completes on its own — and the two phases cannot
  /// share one deadline either, because the browse always burns its whole
  /// window and would leave the resolves nothing to spend.
  ///
  /// The browse window is the only unavoidable wait: there is no way to know
  /// how many servers are out there, so it runs to the end. Resolution is fast
  /// because each record lookup stops at its first answer and the browse has
  /// usually already primed the client's cache.
  Future<List<DiscoveredMusicAssistantServer>> discover({
    Duration browseTimeout = const Duration(milliseconds: 2500),
    Duration resolveTimeout = const Duration(milliseconds: 1500),
  }) async {
    if (useNativeBrowser) {
      return _discoverWithNativeBonjour(browseTimeout: browseTimeout, resolveTimeout: resolveTimeout);
    }
    return _discoverWithMulticastDns(browseTimeout: browseTimeout, resolveTimeout: resolveTimeout);
  }

  /// Browse through `NWBrowser`, via the platform channel.
  ///
  /// A failure here does not fall back to the Dart mDNS path. On the only
  /// platform that takes this branch that path is known to return nothing, so
  /// a "fallback" would trade a clear failure for a silent empty list — the
  /// precise behaviour this replaced.
  Future<List<DiscoveredMusicAssistantServer>> _discoverWithNativeBonjour({
    required Duration browseTimeout,
    required Duration resolveTimeout,
  }) async {
    final discovered = <String, DiscoveredMusicAssistantServer>{};
    try {
      final results = await _nativeChannel.invokeListMethod<Object?>('browse', <String, Object?>{
        'type': bonjourServiceType,
        'browseTimeoutMs': browseTimeout.inMilliseconds,
        'resolveTimeoutMs': resolveTimeout.inMilliseconds,
      });
      for (final entry in results ?? const <Object?>[]) {
        if (entry is! Map) continue;
        final txt = <String, String>{};
        final rawTxt = entry['txt'];
        if (rawTxt is Map) {
          rawTxt.forEach((key, value) {
            if (key is String && value is String) txt[key] = value;
          });
        }
        final server = serverFromAdvert(
          txt: txt,
          host: entry['host'] as String?,
          port: (entry['port'] as num?)?.toInt(),
          instanceName: entry['name'] as String?,
        );
        if (server != null) discovered.putIfAbsent(server.id, () => server);
      }
    } on MissingPluginException {
      appLogger.w('Bonjour discovery plugin is not registered on this platform');
    } catch (e, st) {
      appLogger.w('Native Bonjour discovery failed', error: e, stackTrace: st);
    }
    appLogger.i('Bonjour browse for $bonjourServiceType found ${discovered.length} server(s)');
    return sortDiscoveredServers(discovered.values);
  }

  Future<List<DiscoveredMusicAssistantServer>> _discoverWithMulticastDns({
    required Duration browseTimeout,
    required Duration resolveTimeout,
  }) async {
    MDnsClient? client;
    final discovered = <String, DiscoveredMusicAssistantServer>{};

    try {
      client = await _clientFactory();
      // Instances are collected before any is resolved: resolving inside the
      // PTR stream would interleave lookups with the browse it is still reading.
      final instances = <String>{};
      await for (final ptr in _bounded(
        client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceType)),
        browseTimeout,
      )) {
        instances.add(ptr.domainName);
      }

      for (final instance in instances) {
        final server = await _resolve(client, instance, resolveTimeout);
        if (server != null) discovered.putIfAbsent(server.id, () => server);
      }
    } catch (e, st) {
      appLogger.w('Music Assistant mDNS discovery failed', error: e, stackTrace: st);
    } finally {
      client?.stop();
    }

    return sortDiscoveredServers(discovered.values);
  }

  /// Turn one advertised instance into a reachable address.
  ///
  /// The TXT record already carries everything (`server_id`, `server_version`,
  /// `base_url`), but `base_url` is the address the *server* believes it has —
  /// on a container or a multi-homed host that is routinely not reachable from
  /// this device. So the SRV target's A record wins when it resolves, and the
  /// advertised `base_url` is only the fallback.
  ///
  /// Whichever branch wins, the result goes through [isPlausibleLanAddress]
  /// before it is offered to anyone.
  Future<DiscoveredMusicAssistantServer?> _resolve(MDnsClient client, String instance, Duration budget) async {
    if (budget <= Duration.zero) return null;
    final txt = <String, String>{};
    // One TXT record holds the whole payload; stopping at the first answer is
    // what keeps resolution from costing a full timeout per lookup.
    await for (final record in _bounded(client.lookup<TxtResourceRecord>(ResourceRecordQuery.text(instance)), budget)) {
      txt.addAll(parseTxt(record.text));
      break;
    }

    final id = txt['server_id']?.trim();
    if (id == null || id.isEmpty) return null;

    String? host;
    var port = defaultPort;
    await for (final srv in _bounded(client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(instance)), budget)) {
      port = srv.port;
      await for (final ip in _bounded(
        client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target)),
        budget,
      )) {
        host = ip.address.address;
        break;
      }
      break;
    }

    return serverFromAdvert(txt: txt, host: host, port: port);
  }

  /// Build a discovered server from one advert, whoever browsed for it.
  ///
  /// Shared by the `multicast_dns` path and the native Bonjour one on purpose.
  /// The rules applied here — which field is the id, that a resolved address
  /// beats the advertised `base_url`, and above all that the result is refused
  /// unless it is plausibly on this link — are the security-relevant part of
  /// discovery. A second browser with its own copy of them would be a second
  /// place for them to drift, and the drift would not be visible until
  /// something had already been offered to the user.
  ///
  /// [host] and [port] are what resolution produced, or null when it failed.
  @visibleForTesting
  static DiscoveredMusicAssistantServer? serverFromAdvert({
    required Map<String, String> txt,
    String? host,
    int? port,
    String? instanceName,
  }) {
    // The advertised instance name *is* the server id. Preferring TXT keeps
    // the two browsers agreeing with each other and with the greeting, and the
    // instance name covers a responder that omits the pair.
    final id = (txt['server_id']?.trim().isNotEmpty ?? false) ? txt['server_id']!.trim() : instanceName?.trim();
    if (id == null || id.isEmpty) return null;

    // Resolution can hand back the advertised *hostname* rather than an
    // address — `mass.local` instead of `10.0.2.107` — and a name costs an
    // mDNS round trip on every connection. Measured against this server that
    // is 3s versus 20ms, which is long enough that the client's socket is not
    // up when the first health check runs, and a server that was just added
    // gets dropped as offline. So a literal wins, and the name is kept only
    // when there is nothing better.
    final resolved = host != null && host.isNotEmpty ? 'http://$host:${port ?? defaultPort}' : '';
    final advertised = _trimTrailingSlashes(txt['base_url'] ?? '');
    final resolvedIsLiteral = host != null && InternetAddress.tryParse(host) != null;
    final address = switch ((resolved.isNotEmpty, advertised.isNotEmpty)) {
      (true, true) => resolvedIsLiteral ? resolved : advertised,
      (true, false) => resolved,
      (false, true) => advertised,
      (false, false) => '',
    };
    if (address.isEmpty) return null;
    // Both branches are attacker-controllable: anything on the link can answer
    // an mDNS query, and the TXT fallback in particular is a string the server
    // chose. An advertisement that names an address off the local link is
    // never legitimate — mDNS is link-scoped by definition — so it is dropped
    // rather than offered to the user as a server to add.
    if (!isPlausibleLanAddress(address)) {
      appLogger.w('Ignoring Music Assistant mDNS advert with a non-LAN address');
      return null;
    }
    return DiscoveredMusicAssistantServer(address: address, id: id, version: txt['server_version']?.trim());
  }

  /// Whether [address] is somewhere an mDNS responder could legitimately be.
  ///
  /// Accepts a private, loopback or link-local IP literal, or a name inside
  /// the mDNS domain (`*.local`), which cannot be steered by unicast DNS.
  /// Everything else — a public IP, a routable hostname — is refused: mDNS is
  /// link-scoped, so an advert pointing off-link is either broken or is trying
  /// to make this device open a socket somewhere of the advertiser's choosing.
  ///
  /// This is deliberately a membership test on the address, not a same-subnet
  /// test. The device's own interface addresses are not knowable here without
  /// an async lookup per advert, and a server one hop away on a home network
  /// with two RFC1918 ranges is a real configuration that a subnet test would
  /// wrongly reject.
  static bool isPlausibleLanAddress(String address) {
    final uri = Uri.tryParse(address);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final host = uri.host;
    if (host.isEmpty) return false;
    // Credentials in a discovered URL have no legitimate use and are a
    // phishing primitive once the address is shown to a user.
    if (uri.userInfo.isNotEmpty) return false;

    final ip = InternetAddress.tryParse(host);
    if (ip == null) {
      final name = host.toLowerCase();
      return name == 'localhost' || name.endsWith('.local');
    }
    return switch (ip.type) {
      InternetAddressType.IPv4 => _isPrivateIPv4(ip.rawAddress),
      InternetAddressType.IPv6 => _isPrivateIPv6(ip.rawAddress),
      _ => false,
    };
  }

  static bool _isPrivateIPv4(List<int> bytes) {
    if (bytes.length != 4) return false;
    final [a, b, _, _] = bytes;
    if (a == 10) return true; // 10/8
    if (a == 127) return true; // loopback
    if (a == 172 && b >= 16 && b <= 31) return true; // 172.16/12
    if (a == 192 && b == 168) return true; // 192.168/16
    if (a == 169 && b == 254) return true; // 169.254/16 link-local
    // 100.64/10 (CGNAT) is what Tailscale hands out, and a tailnet peer
    // answering mDNS over the tunnel is a real, intended setup.
    if (a == 100 && b >= 64 && b <= 127) return true;
    return false;
  }

  static bool _isPrivateIPv6(List<int> bytes) {
    if (bytes.length != 16) return false;
    // ::1
    if (bytes.take(15).every((byte) => byte == 0) && bytes.last == 1) return true;
    // fc00::/7 unique-local
    if (bytes.first & 0xFE == 0xFC) return true;
    // fe80::/10 link-local
    if (bytes.first == 0xFE && bytes[1] & 0xC0 == 0x80) return true;
    return false;
  }

  /// `key=value` lines, as `TxtResourceRecord` joins the record's strings.
  /// Values may legitimately contain `=`, so only the first one splits.
  static Map<String, String> parseTxt(String text) {
    final result = <String, String>{};
    for (final line in text.split('\n')) {
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      result[line.substring(0, separator).trim()] = line.substring(separator + 1).trim();
    }
    return result;
  }

  static List<DiscoveredMusicAssistantServer> sortDiscoveredServers(Iterable<DiscoveredMusicAssistantServer> servers) {
    final sorted = servers.toList()
      ..sort((a, b) {
        final address = a.address.compareTo(b.address);
        if (address != 0) return address;
        return a.id.compareTo(b.id);
      });
    return List.unmodifiable(sorted);
  }

  static Stream<T> _bounded<T>(Stream<T> source, Duration budget) {
    if (budget <= Duration.zero) return const Stream.empty();
    return source.timeout(budget, onTimeout: (sink) => sink.close());
  }

  static String _trimTrailingSlashes(String value) => value.trim().replaceAll(RegExp(r'/+$'), '');
}
