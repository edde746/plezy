import 'package:flutter/material.dart';

import '../../focus/focusable_text_field.dart';

/// "Profile name" text field used by both the new-profile flow and the
/// profile-detail rename row; inherits the app-wide filled input style.
/// Optional [trailing] slot for an inline Save button — pass `null` when the
/// screen saves elsewhere (e.g. on Continue).
class ProfileNameField extends StatelessWidget {
  const ProfileNameField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.trailing,
    this.onChanged,
    this.autofocus = false,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onNavigateLeft,
    this.onNavigateRight,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final Widget? trailing;
  final VoidCallback? onChanged;
  final bool autofocus;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;

  @override
  Widget build(BuildContext context) {
    final field = FocusableTextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(hintText: hintText),
      onChanged: (_) => onChanged?.call(),
      onNavigateUp: onNavigateUp ?? () => FocusScope.of(context).previousFocus(),
      onNavigateDown: onNavigateDown ?? () => FocusScope.of(context).nextFocus(),
      onNavigateLeft: onNavigateLeft,
      onNavigateRight: onNavigateRight,
    );
    if (trailing == null) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: 12),
        trailing!,
      ],
    );
  }
}
