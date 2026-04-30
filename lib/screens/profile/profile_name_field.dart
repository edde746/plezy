import 'package:flutter/material.dart';

/// Bordered "Profile name" text field used by both the new-profile flow and
/// the profile-detail rename row. Optional [trailing] slot for an inline Save
/// button — pass `null` when the screen saves elsewhere (e.g. on Continue).
class ProfileNameField extends StatelessWidget {
  const ProfileNameField({super.key, required this.controller, this.hintText, this.trailing, this.onChanged});

  final TextEditingController controller;
  final String? hintText;
  final Widget? trailing;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(hintText: hintText, border: const OutlineInputBorder()),
      onChanged: (_) => onChanged?.call(),
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
