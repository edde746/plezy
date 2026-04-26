import 'package:flutter/material.dart';

/// First grapheme of [name] uppercased, or `?` when [name] is empty.
String initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final first = trimmed.runes.first;
  return String.fromCharCode(first).toUpperCase();
}

/// Deterministic colour for [name] from a curated palette. The palette is
/// dark enough that white-on-colour text always meets contrast — callers
/// can use plain `Colors.white` for the text without per-colour checks.
Color colorForName(String name, ThemeData theme) {
  if (name.isEmpty) return theme.colorScheme.primary;
  var hash = 0;
  for (final code in name.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _palette[hash % _palette.length];
}

const _palette = <Color>[
  Color(0xFF1565C0), // blue
  Color(0xFF2E7D32), // green
  Color(0xFFAD1457), // pink
  Color(0xFF6A1B9A), // purple
  Color(0xFF00838F), // teal
  Color(0xFFE65100), // orange
  Color(0xFF4527A0), // deep purple
  Color(0xFFC62828), // red
];
