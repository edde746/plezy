import 'package:flutter/material.dart';

/// Base class for video control bottom sheets providing common UI structure
class BaseVideoControlSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  const BaseVideoControlSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  /// Get consistent bottom sheet constraints across all video control sheets
  static BoxConstraints getBottomSheetConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return BoxConstraints(
      maxWidth: isDesktop ? 700 : double.infinity,
      maxHeight: isDesktop ? 400 : size.height * 0.75,
      minHeight: isDesktop ? 300 : size.height * 0.5,
    );
  }

  /// Helper method to show a modal bottom sheet with consistent styling
  static Future<T?> showSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: getBottomSheetConstraints(context),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(color: Colors.white24, height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.white),
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
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
