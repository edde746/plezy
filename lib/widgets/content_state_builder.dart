import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';

/// A widget that handles loading, error, empty, and content states
/// Provides a consistent UI pattern across the app for data-driven screens
class ContentStateBuilder<T> extends StatelessWidget {
  /// Whether data is currently loading
  final bool isLoading;

  /// Error message to display (null if no error)
  final String? errorMessage;

  /// The list of items to display
  final List<T> items;

  /// Icon to display when the list is empty
  final IconData emptyIcon;

  /// Message to display when the list is empty
  final String emptyMessage;

  /// Callback when user taps retry button
  final VoidCallback onRetry;

  /// Builder for the content when items are available
  final Widget Function(List<T> items) builder;

  const ContentStateBuilder({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state (only show loading indicator if items list is empty)
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state (only show error if items list is empty)
    if (errorMessage != null && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(t.common.retry),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // Content state - delegate to builder
    return builder(items);
  }
}
