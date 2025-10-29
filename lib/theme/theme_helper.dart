import 'package:flutter/material.dart';
import 'mono_tokens.dart';

/// Helper function to access MonoTokens from context
MonoTokens tokens(BuildContext context) =>
    Theme.of(context).extension<MonoTokens>()!;
