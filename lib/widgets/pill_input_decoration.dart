import 'package:flutter/material.dart';

const pillInputRadius = BorderRadius.all(Radius.circular(100));

InputDecoration pillInputDecoration(BuildContext context, {String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
  final fillColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
  const border = OutlineInputBorder(borderRadius: pillInputRadius, borderSide: BorderSide.none);
  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: fillColor,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
