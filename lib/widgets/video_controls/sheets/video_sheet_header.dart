import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Shared header widget for video control sheets
///
/// Provides a consistent header with an icon/back button, title, and close button
class VideoSheetHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  const VideoSheetHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.onBack,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button or icon
          if (onBack != null)
            IconButton(
              icon: const AppIcon(
                Symbols.arrow_back_rounded,
                fill: 1,
                color: Colors.white,
              ),
              onPressed: onBack,
            )
          else if (icon != null)
            AppIcon(icon, fill: 1, color: iconColor ?? Colors.white),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const AppIcon(
              Symbols.close_rounded,
              fill: 1,
              color: Colors.white,
            ),
            onPressed: onClose ?? () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
