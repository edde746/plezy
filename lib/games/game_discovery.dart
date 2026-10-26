import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:xml/xml.dart';

import 'game_models.dart';
import 'steam_discovery_codec.dart';

/// One bounded, cancellable LAN scan. Nothing is paired, persisted or launched.
class GameDiscovery {
  MDnsClient? _mdns;
  final List<RawDatagramSocket> _sockets = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  int _generation = 0;

  Future<List<GameHost>> scan({Duration duration = const Duration(seconds: 5)}) async {
    stop();
    final generation = _generation;
    final found = <String, GameHost>{};
    final queried = <String>{};
    final resolved = <String>{};
    final deadline = DateTime.now().add(duration + const Duration(seconds: 2));
    if (Platform.isAndroid) {
      try {
        await const MethodChannel('com.plezy/games').invokeMethod<void>('multicast', {'enabled': true});
      } catch (_) {}
    }
    if (generation != _generation) return [];
    void accept(GameHost host) {
      if (generation == _generation && found.length < 32) found[host.key] = host;
    }

    final mdns = MDnsClient();
    _mdns = mdns;
    var startExpired = false;
    try {
      final starting = mdns.start();
      unawaited(
        starting
            .then((_) {
              if (startExpired || generation != _generation) mdns.stop();
            })
            .catchError((Object _) {}),
      );
      await starting.timeout(const Duration(seconds: 2));
      if (generation != _generation) {
        mdns.stop();
        return [];
      }
      _subscriptions.add(
        mdns
            .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer('_nvstream._tcp.local'), timeout: duration)
            .listen((ptr) {
              if (generation != _generation || queried.length >= 32 || !queried.add(ptr.domainName)) return;
              _subscriptions.add(
                mdns.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName), timeout: duration).listen((
                  srv,
                ) {
                  if (generation != _generation ||
                      srv.port < 1 ||
                      srv.port > 65534 ||
                      resolved.length >= 32 ||
                      !resolved.add('${srv.target}:${srv.port}')) {
                    return;
                  }
                  final name = ptr.domainName.replaceFirst(RegExp(r'\._nvstream\._tcp\.local\.?$'), '');
                  _subscriptions.add(
                    mdns
                        .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target), timeout: duration)
                        .listen((ip) {
                          try {
                            accept(
                              GameHost(
                                id: '${ip.address.address}:${srv.port}',
                                name: name,
                                address: ip.address.address,
                                protocol: GameProtocol.gameStream,
                                port: srv.port,
                              ),
                            );
                          } catch (_) {
                            /* Ignore malformed beacons. */
                          }
                        }, onError: (Object _) {}),
                  );
                }, onError: (Object _) {}),
              );
            }, onError: (Object _) {}),
      );
    } catch (_) {
      startExpired = true;
      mdns.stop(); /* Manual entry and Steam discovery remain available. */
    }

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 27036, reuseAddress: true, reusePort: true);
      if (generation != _generation) {
        socket.close();
        return [];
      }
      _sockets.add(socket);
      socket.broadcastEnabled = true;
      _subscriptions.add(
        socket.listen((event) {
          if (event != RawSocketEvent.read || generation != _generation) return;
          Datagram? packet;
          var count = 0;
          while (count++ < 64 && (packet = socket.receive()) != null) {
            final status = SteamDiscoveryCodec.decode(packet!.data);
            if (status == null) continue;
            try {
              accept(
                GameHost(
                  id: status.id,
                  name: status.name,
                  address: packet.address.address,
                  protocol: GameProtocol.steam,
                  // connect_port in the advertisement belongs to the separate
                  // Steam-to-Steam TCP service. Device pairing uses UDP source.
                  port: packet.port,
                ),
              );
            } catch (_) {
              /* Untrusted LAN advertisement. */
            }
          }
        }, onError: (Object _) {}),
      );
      socket.send(
        SteamDiscoveryCodec.query(Random.secure().nextInt(0x7fffffff) + 1),
        InternetAddress('255.255.255.255'),
        27036,
      );
    } catch (_) {
      /* Steam may own the port. Manual/client discovery remains available. */
    }
    final remaining = deadline.difference(DateTime.now());
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (generation != _generation) return [];
    stop();
    return found.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void stop() {
    _generation++;
    _mdns?.stop();
    _mdns = null;
    if (Platform.isAndroid) {
      unawaited(
        const MethodChannel(
          'com.plezy/games',
        ).invokeMethod<void>('multicast', {'enabled': false}).catchError((Object _) {}),
      );
    }
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    for (final socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
  }
}

/// Resolve a manual/routed Steam host with a bounded unicast status request.
/// This identifies the peer for the PIN exchange; it does not establish trust.
Future<GameHost> identifySteamHost(GameHost candidate) async {
  final addresses = await InternetAddress.lookup(
    candidate.address,
    type: InternetAddressType.IPv4,
  ).timeout(const Duration(seconds: 3));
  if (addresses.isEmpty) throw const FormatException('Computer unavailable');
  final address = addresses.first;
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  StreamSubscription<RawSocketEvent>? subscription;
  try {
    final result = Completer<GameHost>();
    subscription = socket.listen(
      (event) {
        if (event != RawSocketEvent.read || result.isCompleted) return;
        Datagram? packet;
        var count = 0;
        while (count++ < 64 && (packet = socket.receive()) != null) {
          if (packet!.address != address || packet.port != candidate.port) continue;
          final status = SteamDiscoveryCodec.decode(packet.data);
          if (status == null) continue;
          result.complete(
            GameHost(
              id: status.id,
              name: status.name,
              address: candidate.address,
              protocol: GameProtocol.steam,
              port: packet.port,
              mac: candidate.mac,
            ),
          );
          break;
        }
      },
      onError: (Object error) {
        if (!result.isCompleted) result.completeError(error);
      },
    );
    socket.send(SteamDiscoveryCodec.query(Random.secure().nextInt(0x7fffffff) + 1), address, candidate.port);
    return await result.future.timeout(const Duration(seconds: 4));
  } finally {
    socket.close();
    await subscription?.cancel();
  }
}

/// Public serverinfo supplies the UUID used by Moonlight's official shortcut.
/// It is NOT proof of pairing or permission to control the computer.
Future<GameHost> identifyGameStreamHost(GameHost candidate) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final uri = Uri(scheme: 'http', host: candidate.address, port: candidate.port, path: '/serverinfo');
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) throw const FormatException('Computer unavailable');
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 4))) {
      bytes.addAll(chunk);
      if (bytes.length > 65536) throw const FormatException('Oversized server information');
    }
    return parseGameStreamInfo(candidate, utf8.decode(bytes));
  } finally {
    client.close(force: true);
  }
}

GameHost parseGameStreamInfo(GameHost candidate, String body) {
  if (body.length > 65536 || body.contains('<!DOCTYPE') || body.contains('<!ENTITY')) {
    throw const FormatException('Invalid server information');
  }
  final root = XmlDocument.parse(body).rootElement;
  if (root.name.local != 'root' || root.getAttribute('status_code') != '200') {
    throw const FormatException('Computer unavailable');
  }
  final id = root.getElement('uniqueid')?.innerText;
  if (id == null || !RegExp(r'^[a-fA-F0-9-]{16,64}$').hasMatch(id)) {
    throw const FormatException('Invalid computer identity');
  }
  return GameHost(
    id: id,
    name: root.getElement('hostname')?.innerText ?? candidate.name,
    address: candidate.address,
    protocol: candidate.protocol,
    port: candidate.port,
    mac: candidate.mac,
  );
}

Uint8List wakePacket(String mac) {
  if (!RegExp(r'^(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$').hasMatch(mac)) throw const FormatException('Invalid MAC');
  final address = mac.split(':').map((v) => int.parse(v, radix: 16)).toList();
  return Uint8List.fromList([for (var n = 0; n < 6; n++) 255, for (var n = 0; n < 16; n++) ...address]);
}

Future<void> wakeGameHost(GameHost host) async {
  final packet = wakePacket(host.mac!);
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  try {
    socket.broadcastEnabled = true;
    socket.send(packet, InternetAddress('255.255.255.255'), 9);
  } finally {
    socket.close();
  }
}
