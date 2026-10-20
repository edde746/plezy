import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;

/// [input] as the base URL of a self-hosted Open Watch Party relay: `http` or
/// `https`, a host, an optional port and path prefix, scheme and host lower
/// case, no trailing `/`. Null when it isn't one the SDK accepts.
String? canonicalRelayBaseUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final Uri uri;
  try {
    uri = Uri.parse(trimmed);
  } on FormatException {
    return null;
  }
  final scheme = uri.scheme.toLowerCase();
  if ((scheme != 'http' && scheme != 'https') || uri.host.isEmpty) return null;
  if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
  var path = uri.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  final host = uri.host.toLowerCase();
  // An IPv6 literal keeps its brackets, or the port would read as part of it.
  final authority = host.contains(':') ? '[$host]' : host;
  final base = '$scheme://$authority${uri.hasPort ? ':${uri.port}' : ''}$path';
  try {
    owp.Relays.at(base);
  } on owp.PartyException {
    return null;
  }
  return base;
}

/// The relays rooms live on: the public Open Watch Party relays, or the
/// self-hosted one at [customBaseUrl].
owp.Relays relaysFor(String? customBaseUrl) =>
    customBaseUrl == null ? owp.Relays.public() : owp.Relays.at(customBaseUrl);

/// A stable key for the relay network a room code belongs to, so recent rooms
/// of one relay setting don't show under another.
String relayScopeOf(String? customBaseUrl) =>
    customBaseUrl == null ? 'public' : sha256.convert(utf8.encode(customBaseUrl)).toString();

/// The offset bound of SDK.md §13: 7 days either way.
const int maxRoomOffsetMs = 604800000;

/// The room rates the SDK accepts.
const double minRoomRate = 0.5;
const double maxRoomRate = 2.0;

/// [input] as a room code (separators dropped, letters upper-cased), or null
/// when it isn't 6 symbols of the code alphabet.
String? normalizeRoomCode(String input) {
  try {
    return owp.formatCode(input).replaceAll('-', '');
  } on owp.PartyException {
    return null;
  }
}
