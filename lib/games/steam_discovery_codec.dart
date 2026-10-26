import 'dart:convert';
import 'dart:typed_data';

/// Steam In-Home Streaming framing, shared by legacy and current LAN discovery.
/// Only status advertisements are decoded. Streaming and authentication require a separately implemented native engine.
/// References: Wireshark packet-steam-ihs-discovery.c and SteamTracking/Protobufs.
class SteamDiscoveryCodec {
  static const signature = [255, 255, 255, 255, 0x21, 0x4c, 0x5f, 0xa0];

  static Uint8List query(int clientId) {
    if (clientId <= 0) throw const FormatException('Invalid discovery identity');
    final header = [8, ..._varint(clientId), 16, 0];
    return frame(header, [8, 1]);
  }

  static Uint8List frame(List<int> header, List<int> body) {
    final bytes = Uint8List(16 + header.length + body.length);
    bytes.setAll(0, signature);
    ByteData.sublistView(bytes).setUint32(8, header.length, Endian.little);
    bytes.setAll(12, header);
    ByteData.sublistView(bytes).setUint32(12 + header.length, body.length, Endian.little);
    bytes.setAll(16 + header.length, body);
    return bytes;
  }

  static SteamAdvertisement? decode(Uint8List packet) {
    try {
      if (packet.length < 16 || packet.length > 16384) return null;
      for (var i = 0; i < 8; i++) {
        if (packet[i] != signature[i]) return null;
      }
      final view = ByteData.sublistView(packet);
      final headerLength = view.getUint32(8, Endian.little);
      if (headerLength > 2048 || 16 + headerLength > packet.length) return null;
      final bodyLength = view.getUint32(12 + headerLength, Endian.little);
      if (16 + headerLength + bodyLength != packet.length) return null;
      final header = _Proto(packet.sublist(12, 12 + headerLength)).fields();
      if (header[2] != BigInt.one || header[1] is! BigInt) return null;
      final body = _Proto(packet.sublist(16 + headerLength)).fields();
      if (body[4] is! Uint8List) return null;
      final name = utf8.decode(body[4] as Uint8List);
      final services = (body[6] as BigInt? ?? BigInt.zero).toInt();
      if (name.isEmpty || name.length > 256 || RegExp(r'[\x00-\x1f]').hasMatch(name) || services & 2 == 0) return null;
      final port = (body[3] as BigInt? ?? BigInt.from(27036)).toInt();
      if (port < 1 || port > 65535) return null;
      return SteamAdvertisement(
        id: (header[1] as BigInt).toString(),
        name: name,
        port: port,
        screenLocked: body[13] == BigInt.one,
        busy: body[14] == BigInt.one,
      );
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    } on TypeError {
      return null;
    }
  }

  static List<int> _varint(int value) {
    final out = <int>[];
    do {
      var byte = value & 127;
      value >>= 7;
      if (value != 0) byte |= 128;
      out.add(byte);
    } while (value != 0);
    return out;
  }
}

class SteamAdvertisement {
  const SteamAdvertisement({
    required this.id,
    required this.name,
    required this.port,
    required this.screenLocked,
    required this.busy,
  });
  final String id, name;
  final int port;
  final bool screenLocked, busy;
}

class _Proto {
  _Proto(this.data);
  final Uint8List data;
  int offset = 0;
  BigInt number() {
    var value = BigInt.zero;
    for (var n = 0; n < 10; n++) {
      if (offset >= data.length) throw const FormatException('Truncated protobuf');
      final byte = data[offset++];
      if (n == 9 && byte > 1) throw const FormatException('Overflow');
      value |= BigInt.from(byte & 127) << (n * 7);
      if (byte & 128 == 0) return value;
    }
    throw const FormatException('Invalid varint');
  }

  Map<int, Object> fields() {
    final result = <int, Object>{};
    var count = 0;
    while (offset < data.length) {
      if (++count > 512) throw const FormatException('Too many fields');
      final tag = number().toInt(), field = tag >> 3;
      if (field < 1) throw const FormatException('Invalid field');
      switch (tag & 7) {
        case 0:
          result[field] = number();
        case 1:
          offset += 8;
        case 2:
          final size = number();
          if (size > BigInt.from(data.length - offset)) throw const FormatException('Invalid length');
          final length = size.toInt();
          result[field] = data.sublist(offset, offset + length);
          offset += length;
        case 5:
          offset += 4;
        default:
          throw const FormatException('Unsupported wire type');
      }
      if (offset > data.length) throw const FormatException('Truncated field');
    }
    return result;
  }
}
