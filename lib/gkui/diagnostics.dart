import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String diagnosticsChannelName = 'com.jialim.plezygkui/diagnostics';

class DeviceDiagnostics {
  const DeviceDiagnostics(this.values);

  final Map<String, String> values;

  static const MethodChannel _channel = MethodChannel(diagnosticsChannelName);

  static Future<DeviceDiagnostics> load() async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getDiagnostics',
    );
    final values = <String, String>{};
    for (final entry in (raw ?? const <String, Object?>{}).entries) {
      values[entry.key] = entry.value?.toString() ?? 'unknown';
    }
    return DeviceDiagnostics(Map.unmodifiable(values));
  }
}

@immutable
class DiagnosticLogEntry {
  const DiagnosticLogEntry({
    required this.timestamp,
    required this.message,
  });

  final DateTime timestamp;
  final String message;

  String get line => '${timestamp.toIso8601String()}  $message';
}

class RedactingLogStore extends ChangeNotifier {
  RedactingLogStore({this.capacity = 120}) : assert(capacity > 0);

  final int capacity;
  final List<DiagnosticLogEntry> _entries = <DiagnosticLogEntry>[];

  UnmodifiableListView<DiagnosticLogEntry> get entries =>
      UnmodifiableListView<DiagnosticLogEntry>(_entries);

  void add(String message, {DateTime? at}) {
    _entries.add(
      DiagnosticLogEntry(
        timestamp: at ?? DateTime.now(),
        message: redactSecrets(message),
      ),
    );
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
    notifyListeners();
  }

  String exportText() => _entries.map((entry) => entry.line).join('\n');
}

String redactSecrets(String input) {
  var output = input;
  const keys =
      r'(?:X-Plex-Token|authToken|accessToken|Authorization|Cookie|pin)';
  output = output.replaceAllMapped(
    RegExp('([?&]$keys=)[^&\\s]+', caseSensitive: false),
    (match) => '${match.group(1)}<redacted>',
  );
  output = output.replaceAllMapped(
    RegExp('($keys\\s*[:=]\\s*)[^,;\\s]+', caseSensitive: false),
    (match) => '${match.group(1)}<redacted>',
  );
  return output;
}
