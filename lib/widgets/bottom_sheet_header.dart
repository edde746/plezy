import 'package:flutter/material.dart';

/// A reusable header widget for bottom sheets
/// Provides consistent styling with title, optional leading widget, optional action, and close button
class BottomSheetHeader extends StatelessWidget {
  /// The title text to display
  final String title;

  /// Optional leading widget (e.g., icon or back button)
  final Widget? leading;

  /// Optional action widget (e.g., clear button)
  final Widget? action;

  /// Optional callback when close button is pressed
  /// Defaults to Navigator.pop(context)
  final VoidCallback? onClose;

  const BottomSheetHeader({
    super.key,
    required this.title,
    this.leading,
    this.action,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (action != null) action!,
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose ?? () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
