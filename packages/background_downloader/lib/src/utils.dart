import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'task.dart';

final _log = Logger('FileDownloader');

/// Return url String composed of the [url] and the
/// [urlQueryParameters], if given
String urlWithQueryParameters(
  String url,
  Map<String, String>? urlQueryParameters,
) {
  if (urlQueryParameters == null || urlQueryParameters.isEmpty) {
    return url;
  }
  final separator = url.contains('?') ? '&' : '?';
  return '$url$separator${urlQueryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';
}

/// Parses the range in a Range header, and returns a Pair representing
/// the range. The format needs to be "bytes=10-20"
///
/// A missing lower range is substituted with 0, and a missing upper
/// range with null.  If the string cannot be parsed, returns (0, null)
(int, int?) parseRange(String rangeStr) {
  final regex = RegExp(r'bytes=(\d*)-(\d*)');
  final match = regex.firstMatch(rangeStr);
  if (match == null) {
    return (0, null);
  }

  final start = int.tryParse(match.group(1) ?? '') ?? 0;
  final end = int.tryParse(match.group(2) ?? '');
  return (start, end);
}

/// Returns the content length extracted from the [responseHeaders], or from
/// the [task] headers
int getContentLength(Map<String, String> responseHeaders, Task task) {
  // if response provides contentLength, return it
  final contentLength = int.tryParse(
    _headerValue(responseHeaders, 'Content-Length') ?? '-1',
  );
  if (contentLength != null && contentLength != -1) {
    return contentLength;
  }
  // try extracting it from Range header
  final taskRangeHeader = _headerValue(task.headers, 'Range') ?? '';
  final taskRange = parseRange(taskRangeHeader);
  if (taskRange.$2 != null) {
    final rangeLength = taskRange.$2! - taskRange.$1 + 1;
    _log.finest(
      'TaskId ${task.taskId} contentLength set to $rangeLength based on Range header',
    );
    return rangeLength;
  }
  // try extracting it from a special "Known-Content-Length" header
  final knownLength = int.tryParse(
          _headerValue(task.headers, 'Known-Content-Length') ?? '-1') ??
      -1;
  if (knownLength != -1) {
    _log.finest(
      'TaskId ${task.taskId} contentLength set to $knownLength based on Known-Content-Length header',
    );
  } else {
    _log.finest('TaskId ${task.taskId} contentLength undetermined');
  }
  return knownLength;
}

/// Returns a copy of the [task] with the [Task.filename] property changed
/// to the filename suggested by the server, or derived from the url, or
/// unchanged.
///
/// If [unique] is true, the filename is guaranteed not to already exist. This
/// is accomplished by adding a suffix to the suggested filename with a number,
/// e.g. "data (2).txt"
///
/// The server-suggested filename is obtained from the  [responseHeaders] entry
/// "Content-Disposition" according to RFC6266, or the last path segment of the
/// URL, or leaves the filename unchanged
Future<DownloadTask> taskWithSuggestedFilename(
  DownloadTask task,
  Map<String, String> responseHeaders,
  bool unique,
) {
  /// Returns [DownloadTask] with a filename similar to the one
  /// supplied, but unused.
  ///
  /// If [unique], filename will sequence up in "filename (8).txt" format,
  /// otherwise returns the [task]
  Future<DownloadTask> uniqueFilename(DownloadTask task, bool unique) async {
    if (!unique) {
      return task;
    }
    final sequenceRegEx = RegExp(r'\((\d+)\)\.?[^.]*$');
    final extensionRegEx = RegExp(r'\.[^.]*$');
    var newTask = task;
    var filePath = await newTask.filePath();
    var exists = await File(filePath).exists();
    while (exists) {
      final extension =
          extensionRegEx.firstMatch(newTask.filename)?.group(0) ?? '';
      final match = sequenceRegEx.firstMatch(newTask.filename);
      final newSequence = int.parse(match?.group(1) ?? "0") + 1;
      final newFilename = match == null
          ? '${path.basenameWithoutExtension(newTask.filename)} ($newSequence)$extension'
          : '${newTask.filename.substring(0, match.start - 1)} ($newSequence)$extension';
      newTask = newTask.copyWith(filename: newFilename);
      filePath = await newTask.filePath();
      exists = await File(filePath).exists();
    }
    return newTask;
  }

  // start of main function
  final disposition = _headerValue(responseHeaders, 'Content-Disposition');
  final filename =
      disposition == null ? null : _filenameFromContentDisposition(disposition);
  if (filename?.isNotEmpty == true) {
    return uniqueFilename(task.copyWith(filename: filename), unique);
  }
  _log.finest('Could not determine suggested filename from server');
  // Try filename derived from last path segment of the url
  try {
    final suggestedFilename = Uri.parse(task.url).pathSegments.last;
    return uniqueFilename(task.copyWith(filename: suggestedFilename), unique);
  } catch (_) {}
  _log.finest('Could not parse URL pathSegment for suggested filename');
  // if everything fails, return the task with unchanged filename
  // except for possibly making it unique
  return uniqueFilename(task, unique);
}

String? _headerValue(Map<String, String> headers, String name) {
  final lowerName = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == lowerName && entry.value.isNotEmpty) {
      return entry.value;
    }
  }
  return null;
}

String? _filenameFromContentDisposition(String disposition) {
  final parameters = _contentDispositionParameters(disposition);
  final encodedFilename = parameters['filename*'];
  if (encodedFilename != null) {
    final decoded = _decodeExtendedFilename(encodedFilename);
    if (decoded?.isNotEmpty == true) return decoded;
  }
  return parameters['filename'];
}

String? _decodeExtendedFilename(String value) {
  final firstQuote = value.indexOf("'");
  if (firstQuote < 0) return value;
  final secondQuote = value.indexOf("'", firstQuote + 1);
  if (secondQuote < 0) return value;
  final charset = value.substring(0, firstQuote).toUpperCase();
  final encoded = value.substring(secondQuote + 1);
  if (charset != 'UTF-8') return encoded;
  try {
    return Uri.decodeComponent(encoded);
  } on ArgumentError {
    _log.finest(
      'Could not interpret suggested filename (UTF-8 url encoded) $encoded',
    );
    return null;
  }
}

Map<String, String> _contentDispositionParameters(String disposition) {
  final parameters = <String, String>{};
  for (final segment in _splitContentDisposition(disposition).skip(1)) {
    final equalsIndex = segment.indexOf('=');
    if (equalsIndex <= 0) continue;
    final key = segment.substring(0, equalsIndex).trim().toLowerCase();
    final value =
        _unquoteHeaderValue(segment.substring(equalsIndex + 1).trim());
    if (key.isNotEmpty && value.isNotEmpty) parameters[key] = value;
  }
  return parameters;
}

List<String> _splitContentDisposition(String value) {
  final segments = <String>[];
  final current = StringBuffer();
  var inQuotes = false;
  var escaped = false;
  for (final codeUnit in value.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    if (escaped) {
      current.write(char);
      escaped = false;
      continue;
    }
    if (char == '\\' && inQuotes) {
      escaped = true;
      current.write(char);
      continue;
    }
    if (char == '"') {
      inQuotes = !inQuotes;
      current.write(char);
      continue;
    }
    if (char == ';' && !inQuotes) {
      segments.add(current.toString().trim());
      current.clear();
      continue;
    }
    current.write(char);
  }
  segments.add(current.toString().trim());
  return segments;
}

String _unquoteHeaderValue(String value) {
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    final unquoted = value.substring(1, value.length - 1);
    return unquoted.replaceAll(r'\"', '"').replaceAll(r'\\', '\\');
  }
  return value;
}
