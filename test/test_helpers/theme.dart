import 'package:flutter/material.dart';
import 'package:plezy/theme/mono_tokens.dart';

/// Default [MonoTokens] for widget tests: production-shaped metrics with
/// 1ms animations, so a single `pump` settles the tree.
///
/// Use as `ThemeData(extensions: const [testMonoTokens])`.
const testMonoTokens = MonoTokens(
  radiusSm: 8,
  radiusMd: 12,
  radiusLg: 20,
  radiusXs: 5,
  groupGap: 2,
  space: 8,
  fast: Duration(milliseconds: 1),
  normal: Duration(milliseconds: 1),
  slow: Duration(milliseconds: 1),
  expressive: Duration(milliseconds: 1),
  bg: Colors.black,
  surface: Colors.black,
  outline: Colors.white24,
  text: Colors.white,
  textMuted: Colors.white70,
);

/// [testMonoTokens] with realistic animation durations, for tests that step
/// through intermediate frames instead of settling straight to the end state.
const testMonoTokensAnimated = MonoTokens(
  radiusSm: 4,
  radiusMd: 8,
  radiusLg: 20,
  radiusXs: 5,
  groupGap: 2,
  space: 8,
  fast: Duration(milliseconds: 100),
  normal: Duration(milliseconds: 200),
  slow: Duration(milliseconds: 300),
  expressive: Duration(milliseconds: 300),
  bg: Colors.black,
  surface: Color(0xFF111111),
  outline: Color(0xFF333333),
  text: Colors.white,
  textMuted: Color(0xFFAAAAAA),
);
