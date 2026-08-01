import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

const _canonicalAppIconPath = 'lib/widgets/app_icon.dart';
const _generatedSuffixes = ['.g.dart', '.freezed.dart', '.gen.dart'];
final _generatedHeader = RegExp(
  r'^\s*///?\s*(?:auto-)?generated\b.*\bdo not (?:edit|modify)\b',
  caseSensitive: false,
  multiLine: true,
);

void main(List<String> arguments) {
  final scriptDirectory = File.fromUri(Platform.script).absolute.parent;
  late final Directory root;
  if (arguments.isEmpty) {
    root = scriptDirectory.parent;
  } else if (arguments.length == 2 && arguments.first == '--root') {
    root = Directory(arguments.last).absolute;
  } else {
    stderr.writeln('Usage: dart run scripts/check_icon_consistency.dart [--root <path>]');
    exitCode = 64;
    return;
  }
  final libDirectory = Directory('${root.path}${Platform.pathSeparator}lib');
  if (!libDirectory.existsSync()) {
    stderr.writeln('lib:1:1: lib directory not found');
    exitCode = 1;
    return;
  }

  final files =
      libDirectory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final failures = <_Failure>[];
  var scannedFileCount = 0;
  for (final file in files) {
    final relativePath = _relativePath(file.path, root.path);
    final source = file.readAsStringSync();
    if (_isGenerated(relativePath, source)) continue;

    scannedFileCount++;
    final parseResult = parseString(content: source, path: file.path, throwIfDiagnostics: false);
    final unit = parseResult.unit;
    unit.accept(
      _IconConsistencyVisitor(
        path: relativePath,
        lineInfo: parseResult.lineInfo,
        allowFlutterIcon: relativePath == _canonicalAppIconPath,
        flutterIconPrefixes: _importPrefixes(unit, const {
          'package:flutter/cupertino.dart',
          'package:flutter/material.dart',
          'package:flutter/widgets.dart',
        }),
        materialPrefixes: _importPrefixes(unit, const {'package:flutter/material.dart'}),
        symbolsPrefixes: _importPrefixes(unit, const {
          'package:material_symbols_icons/material_symbols_icons.dart',
          'package:material_symbols_icons/symbols.dart',
        }),
        failures: failures,
      ),
    );
  }

  failures.sort((a, b) {
    final pathComparison = a.path.compareTo(b.path);
    if (pathComparison != 0) return pathComparison;
    final lineComparison = a.line.compareTo(b.line);
    if (lineComparison != 0) return lineComparison;
    final columnComparison = a.column.compareTo(b.column);
    if (columnComparison != 0) return columnComparison;
    return a.message.compareTo(b.message);
  });

  if (failures.isNotEmpty) {
    for (final failure in failures) {
      stderr.writeln(failure);
    }
    stderr.writeln('Icon consistency check failed with ${failures.length} violation(s).');
    exitCode = 1;
    return;
  }

  stdout.writeln('Icon consistency check passed ($scannedFileCount non-generated files scanned).');
}

bool _isGenerated(String relativePath, String source) {
  final fileName = relativePath.split('/').last;
  if (_generatedSuffixes.any(fileName.endsWith)) return true;
  if (relativePath.contains('/generated/')) return true;

  final headerLength = source.length < 1024 ? source.length : 1024;
  return _generatedHeader.hasMatch(source.substring(0, headerLength));
}

String _relativePath(String path, String rootPath) {
  final normalizedPath = path.replaceAll(r'\', '/');
  final normalizedRoot = rootPath.replaceAll(r'\', '/');
  return normalizedPath.substring(normalizedRoot.length + 1);
}

Set<String> _importPrefixes(CompilationUnit unit, Set<String> uris) {
  final prefixes = <String>{};
  for (final directive in unit.directives.whereType<ImportDirective>()) {
    final prefix = directive.prefix;
    if (prefix != null && uris.contains(directive.uri.stringValue)) {
      prefixes.add(prefix.name);
    }
  }
  return prefixes;
}

class _IconConsistencyVisitor extends RecursiveAstVisitor<void> {
  _IconConsistencyVisitor({
    required this.path,
    required this.lineInfo,
    required this.allowFlutterIcon,
    required this.flutterIconPrefixes,
    required this.materialPrefixes,
    required this.symbolsPrefixes,
    required this.failures,
  });

  final String path;
  final LineInfo lineInfo;
  final bool allowFlutterIcon;
  final Set<String> flutterIconPrefixes;
  final Set<String> materialPrefixes;
  final Set<String> symbolsPrefixes;
  final List<_Failure> failures;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!allowFlutterIcon && node.constructorName.type.name.lexeme == 'Icon') {
      _report(node.constructorName.type, 'Flutter Icon construction is forbidden; use AppIcon instead');
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    if (!allowFlutterIcon && node.constructorName.type.name.lexeme == 'Icon') {
      _report(node.constructorName.type, 'Flutter Icon constructor tear-offs are forbidden; use AppIcon instead');
    }
    super.visitConstructorReference(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefix = node.prefix.name;
    final member = node.identifier.name;
    if (prefix == 'Icons') {
      _report(node, 'Icons.$member is forbidden; use a rounded Symbols member');
    } else if (prefix == 'Symbols' && !member.endsWith('_rounded')) {
      _report(node, 'Symbols.$member must use its _rounded counterpart');
    } else if (!allowFlutterIcon && prefix == 'Icon' && member == 'new') {
      _report(node, 'Flutter Icon constructor tear-offs are forbidden; use AppIcon instead');
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is PrefixedIdentifier) {
      final importPrefix = target.prefix.name;
      final typeName = target.identifier.name;
      final member = node.propertyName.name;
      if (typeName == 'Icons' && materialPrefixes.contains(importPrefix)) {
        _report(node, '$importPrefix.Icons.$member is forbidden; use a rounded Symbols member');
      } else if (typeName == 'Symbols' && symbolsPrefixes.contains(importPrefix) && !member.endsWith('_rounded')) {
        _report(node, '$importPrefix.Symbols.$member must use its _rounded counterpart');
      } else if (!allowFlutterIcon &&
          typeName == 'Icon' &&
          member == 'new' &&
          flutterIconPrefixes.contains(importPrefix)) {
        _report(node, 'Flutter Icon constructor tear-offs are forbidden; use AppIcon instead');
      }
    }
    super.visitPropertyAccess(node);
  }

  void _report(AstNode node, String message) {
    final location = lineInfo.getLocation(node.offset);
    failures.add(_Failure(path: path, line: location.lineNumber, column: location.columnNumber, message: message));
  }
}

class _Failure {
  const _Failure({required this.path, required this.line, required this.column, required this.message});

  final String path;
  final int line;
  final int column;
  final String message;

  @override
  String toString() => '$path:$line:$column: $message';
}
