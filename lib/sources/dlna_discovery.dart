import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'source_transport.dart';

class DlnaDiscoveredDevice {
  const DlnaDiscoveredDevice({required this.name, required this.location});

  final String name;
  final Uri location;
}

/// Best-effort SSDP discovery. Device-description URLs are checked against
/// the responder address and only returned when they expose ContentDirectory.
class DlnaDiscovery {
  static const _group = '239.255.255.250';
  static const _port = 1900;
  static const _targets = [
    'urn:schemas-upnp-org:device:MediaServer:1',
    'urn:schemas-upnp-org:service:ContentDirectory:1',
  ];

  Future<List<DlnaDiscoveredDevice>> discover({Duration timeout = const Duration(seconds: 4)}) async {
    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? subscription;
    final locations = <String, ({Uri location, String responder})>{};
    try {
      final datagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket = datagramSocket;
      subscription = datagramSocket.listen((event) {
        if (event != RawSocketEvent.read) return;
        Datagram? datagram;
        while ((datagram = datagramSocket.receive()) != null) {
          final packet = utf8.decode(datagram!.data, allowMalformed: true);
          for (final line in const LineSplitter().convert(packet).skip(1)) {
            final colon = line.indexOf(':');
            if (colon <= 0 || line.substring(0, colon).trim().toLowerCase() != 'location') continue;
            final location = Uri.tryParse(line.substring(colon + 1).trim());
            if (location == null ||
                !const {'http', 'https'}.contains(location.scheme) ||
                location.host.isEmpty ||
                location.userInfo.isNotEmpty ||
                location.hasQuery ||
                location.hasFragment) {
              continue;
            }
            locations[location.toString()] = (location: location, responder: datagram.address.address);
          }
        }
      }, onError: (_) {});
      for (final target in _targets) {
        final request = [
          'M-SEARCH * HTTP/1.1',
          'HOST: $_group:$_port',
          'MAN: "ssdp:discover"',
          'MX: 2',
          'ST: $target',
          '',
          '',
        ].join('\r\n');
        datagramSocket.send(utf8.encode(request), InternetAddress(_group), _port);
      }
      await Future<void>.delayed(timeout);
    } on Object {
      return const [];
    } finally {
      await subscription?.cancel();
      socket?.close();
    }

    final transport = SourceTransport(allowHttp: true);
    try {
      final found = await Future.wait(
        locations.values.take(24).map((candidate) => _describe(candidate.location, candidate.responder, transport)),
      );
      final devices = found.whereType<DlnaDiscoveredDevice>().toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return devices;
    } finally {
      transport.close();
    }
  }

  Future<DlnaDiscoveredDevice?> _describe(Uri location, String responder, SourceTransport transport) async {
    try {
      final addresses = await InternetAddress.lookup(location.host).timeout(const Duration(seconds: 2));
      if (!addresses.any((address) => address.address == responder)) return null;
      final xml = await transport.text('GET', location, limit: 2 * 1024 * 1024).timeout(const Duration(seconds: 4));
      final document = XmlDocument.parse(xml);
      final elements = _descendants(document).toList();
      final supportsDirectory = elements.any(
        (element) =>
            element.name.local == 'service' &&
            _childText(element, 'serviceType')?.contains(':ContentDirectory:') == true,
      );
      if (!supportsDirectory) return null;
      final name = elements
          .where((element) => element.name.local == 'friendlyName')
          .map((element) => element.innerText.trim())
          .firstWhere((value) => value.isNotEmpty, orElse: () => location.host);
      return DlnaDiscoveredDevice(name: name, location: location);
    } on Object {
      return null;
    }
  }

  static Iterable<XmlElement> _descendants(XmlNode node) sync* {
    for (final child in node.children) {
      if (child is XmlElement) {
        yield child;
        yield* _descendants(child);
      }
    }
  }

  static String? _childText(XmlElement parent, String localName) {
    for (final child in parent.children.whereType<XmlElement>()) {
      if (child.name.local == localName) return child.innerText.trim();
    }
    return null;
  }
}
