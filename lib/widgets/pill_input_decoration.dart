import 'package:flutter/material.dart';

const pillInputRadius = BorderRadius.all(Radius.circular(100));

/// Brighter fill on focus so input focus is visible inside TV overscan.
InputDecoration pillInputDecoration(BuildContext context, {String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final unfocusedFill = onSurface.withValues(alpha: 0.08);
  final focusedFill = onSurface.withValues(alpha: 0.18);
  const border = OutlineInputBorder(borderRadius: pillInputRadius, borderSide: BorderSide.none);
  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.focused) ? focusedFill : unfocusedFill,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
