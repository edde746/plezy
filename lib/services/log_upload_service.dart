import 'dart:convert';

import '../utils/media_server_http_client.dart';

/// Relay endpoint that returns a short, quotable Log ID.
const String logUploadEndpoint = 'https://ice.plezy.app/logs';

/// Relay `/logs` accepts 1 MiB. The in-memory buffer intentionally remains
/// larger for local viewing and copying; uploads retain the device header and
/// newest log lines within this transport contract.
const int maxLogUploadBytes = 1 * 1024 * 1024;

/// Trims [logs] from the front so `header + logs` fits [maxBytes], keeping the
/// header intact and never splitting a UTF-8 sequence or a log line.
String constrainLogUploadPayload({required String header, required String logs, int maxBytes = maxLogUploadBytes}) {
  if (maxBytes <= 0) return '';

  final headerBytes = utf8.encode(header);
  if (headerBytes.length >= maxBytes) {
    var end = maxBytes;
    while (end > 0 && end < headerBytes.length && (headerBytes[end] & 0xC0) == 0x80) {
      end--;
    }
    return utf8.decode(headerBytes.sublist(0, end));
  }

  final logBytes = utf8.encode(logs);
  final availableLogBytes = maxBytes - headerBytes.length;
  if (logBytes.length <= availableLogBytes) return '$header$logs';

  var start = logBytes.length - availableLogBytes;
  while (start < logBytes.length && (logBytes[start] & 0xC0) == 0x80) {
    start++;
  }
  final nextLine = logBytes.indexOf(0x0A, start);
  if (nextLine >= 0 && nextLine + 1 < logBytes.length) {
    start = nextLine + 1;
  }
  return header + utf8.decode(logBytes.sublist(start));
}

/// Posts [payload] to the log relay and returns the short Log ID.
///
/// Shared by Settings › Logs and by the startup failure screen, which cannot
/// reach Settings because the gate it needs has not completed (#1732).
///
/// [payload] must already be redacted and allowlisted by the caller; this
/// function performs no sanitisation of its own.
Future<String> uploadDiagnosticText(String payload, {MediaServerHttpClient? client}) async {
  final response = await (client ?? httpClient).post(
    logUploadEndpoint,
    body: payload,
    headers: {'Content-Type': 'text/plain'},
  );
  final data = response.data is String ? jsonDecode(response.data as String) : response.data;
  return (data as Map<String, dynamic>)['id'] as String;
}
