import 'package:flutter/material.dart';
import 'package:plezy/widgets/bottom_sheet_header.dart';

/// Shared header widget for video control sheets
///
/// This is now a thin wrapper around [BottomSheetHeader] for backward compatibility.
/// Consider using [BottomSheetHeader] directly for new implementations.
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
    return BottomSheetHeader(
      title: title,
      icon: icon,
      iconColor: iconColor ?? Colors.white,
      onBack: onBack,
      onClose: onClose,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      showBorder: false,
    );
  }
}
