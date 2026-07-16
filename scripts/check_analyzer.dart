import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _analysisTimeout = Duration(minutes: 3);

final _allowedDiagnostics = <AnalyzerDiagnostic>{
  const AnalyzerDiagnostic(
    severity: 'INFO',
    type: 'LINT',
    code: 'UNAWAITED_FUTURES',
    path: 'test/navigation/profile_navigation_scope_test.dart',
    line: 21,
    column: 28,
    length: 4,
    message: "Missing an 'await' for the 'Future' computed by this expression.",
  ),
  const AnalyzerDiagnostic(
    severity: 'INFO',
    type: 'HINT',
    code: 'UNNECESSARY_IMPORT',
    path: 'test/widgets/video_controls_two_finger_double_tap_tracker_test.dart',
    line: 1,
    column: 8,
    length: 31,
    message:
        "The import of 'package:flutter/material.dart' is unnecessary because "
        'all of the used elements are also provided by the import of '
        "'package:flutter_test/flutter_test.dart'.",
  ),
};

Future<void> main() async {
  final scriptDirectory = File.fromUri(Platform.script).parent;
  final root = scriptDirectory.parent.path;
  late final Process process;

  try {
    process = await Process.start(
      Platform.resolvedExecutable,
      const ['analyze', '--format', 'machine', '--fatal-infos'],
      workingDirectory: root,
      runInShell: false,
    );
  } on ProcessException catch (error) {
    stderr.writeln('Failed to start the analyzer: $error');
    exitCode = 1;
    return;
  }

  final analyzerStdoutFuture = process.stdout.transform(utf8.decoder).join();
  final analyzerStderrFuture = process.stderr.transform(utf8.decoder).join();

  int analyzerExitCode;
  try {
    analyzerExitCode = await process.exitCode.timeout(_analysisTimeout);
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await Future.wait([analyzerStdoutFuture, analyzerStderrFuture]);
    stderr.writeln('Analyzer timed out after ${_analysisTimeout.inMinutes} minutes.');
    exitCode = 1;
    return;
  }

  final analyzerStdout = await analyzerStdoutFuture;
  final analyzerStderr = await analyzerStderrFuture;
  stdout.write(analyzerStdout);
  stderr.write(analyzerStderr);

  final failure = validateAnalyzerResult(
    analyzerExitCode: analyzerExitCode,
    analyzerStdout: analyzerStdout,
    analyzerStderr: analyzerStderr,
    rootPath: root,
  );
  if (failure != null) {
    stderr.writeln('Analyzer check failed: $failure');
    exitCode = 1;
    return;
  }

  final diagnosticCount = analyzerStdout.trim().isEmpty ? 0 : const LineSplitter().convert(analyzerStdout).length;
  stdout.writeln(
    'Analyzer passed with $diagnosticCount explicitly allowed info '
    'diagnostic(s).',
  );
}

String? validateAnalyzerResult({
  required int analyzerExitCode,
  required String analyzerStdout,
  required String analyzerStderr,
  required String rootPath,
}) {
  if (analyzerStderr.trim().isNotEmpty) {
    return 'unexpected stderr output (exit $analyzerExitCode)';
  }

  final lines = const LineSplitter().convert(analyzerStdout);
  final diagnostics = <AnalyzerDiagnostic>[];
  for (final line in lines) {
    if (line.isEmpty) {
      return 'unexpected blank line in machine output';
    }
    final diagnostic = AnalyzerDiagnostic.tryParse(line, rootPath: rootPath);
    if (diagnostic == null) {
      return 'malformed machine output: $line';
    }
    diagnostics.add(diagnostic);
  }

  final seen = <AnalyzerDiagnostic>{};
  for (final diagnostic in diagnostics) {
    if (diagnostic.severity != 'INFO') {
      return 'unexpected ${diagnostic.severity} diagnostic: ${diagnostic.code}';
    }
    if (!_allowedDiagnostics.contains(diagnostic)) {
      return 'info diagnostic is not explicitly allowed: '
          '${diagnostic.code} at ${diagnostic.path}:${diagnostic.line}';
    }
    if (!seen.add(diagnostic)) {
      return 'duplicate diagnostic: '
          '${diagnostic.code} at ${diagnostic.path}:${diagnostic.line}';
    }
  }

  if (analyzerExitCode == 0) {
    return diagnostics.isEmpty ? null : 'analyzer returned success despite --fatal-infos diagnostics';
  }
  if (analyzerExitCode == 1 && diagnostics.isNotEmpty) {
    return null;
  }
  return 'analyzer exited $analyzerExitCode without only allowed info diagnostics';
}

class AnalyzerDiagnostic {
  const AnalyzerDiagnostic({
    required this.severity,
    required this.type,
    required this.code,
    required this.path,
    required this.line,
    required this.column,
    required this.length,
    required this.message,
  });

  factory AnalyzerDiagnostic._fromParts(List<String> parts, String rootPath) {
    return AnalyzerDiagnostic(
      severity: parts[0],
      type: parts[1],
      code: parts[2],
      path: _relativePath(parts[3], rootPath),
      line: int.parse(parts[4]),
      column: int.parse(parts[5]),
      length: int.parse(parts[6]),
      message: parts.sublist(7).join('|'),
    );
  }

  static AnalyzerDiagnostic? tryParse(String line, {required String rootPath}) {
    final parts = line.split('|');
    if (parts.length < 8 || parts.take(8).any((part) => part.isEmpty)) {
      return null;
    }
    if (int.tryParse(parts[4]) == null || int.tryParse(parts[5]) == null || int.tryParse(parts[6]) == null) {
      return null;
    }
    return AnalyzerDiagnostic._fromParts(parts, rootPath);
  }

  static String _relativePath(String path, String rootPath) {
    final normalizedPath = _normalizePath(path);
    final normalizedRoot = _normalizePath(rootPath);
    final rootPrefix = '$normalizedRoot/';
    if (normalizedPath.toLowerCase().startsWith(rootPrefix.toLowerCase())) {
      return normalizedPath.substring(rootPrefix.length);
    }
    return normalizedPath;
  }

  static String _normalizePath(String path) => path.replaceAll(r'\\', '/').replaceAll(r'\', '/');

  final String severity;
  final String type;
  final String code;
  final String path;
  final int line;
  final int column;
  final int length;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is AnalyzerDiagnostic &&
      severity == other.severity &&
      type == other.type &&
      code == other.code &&
      path == other.path &&
      line == other.line &&
      column == other.column &&
      length == other.length &&
      message == other.message;

  @override
  int get hashCode => Object.hash(severity, type, code, path, line, column, length, message);
}
