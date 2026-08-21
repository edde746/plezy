import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import 'state_messages.dart';

/// Sliver wrapper around [ErrorStateWidget] for use in `CustomScrollView.slivers`.
class SliverErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final FocusNode? actionFocusNode;
  final VoidCallback? onActionNavigateUp;
  final VoidCallback? onActionNavigateLeft;
  final VoidCallback? onActionBack;
  final bool actionAutofocus;
  final bool actionUseBackgroundFocus;

  const SliverErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.actionFocusNode,
    this.onActionNavigateUp,
    this.onActionNavigateLeft,
    this.onActionBack,
    this.actionAutofocus = false,
    this.actionUseBackgroundFocus = false,
  });

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    child: ErrorStateWidget(
      message: message,
      icon: Symbols.error_outline_rounded,
      onRetry: onRetry,
      retryLabel: retryLabel,
      actionFocusNode: actionFocusNode,
      onActionNavigateUp: onActionNavigateUp,
      onActionNavigateLeft: onActionNavigateLeft,
      onActionBack: onActionBack,
      actionAutofocus: actionAutofocus,
      actionUseBackgroundFocus: actionUseBackgroundFocus,
    ),
  );
}

/// Sliver wrapper around [EmptyStateWidget] for use in `CustomScrollView.slivers`.
class SliverEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;
  final FocusNode? actionFocusNode;
  final VoidCallback? onActionNavigateUp;
  final VoidCallback? onActionNavigateLeft;
  final VoidCallback? onActionBack;

  const SliverEmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.subtitle,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
    this.actionFocusNode,
    this.onActionNavigateUp,
    this.onActionNavigateLeft,
    this.onActionBack,
  });

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    child: EmptyStateWidget(
      message: message,
      icon: icon,
      subtitle: subtitle,
      onAction: onAction,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      actionFocusNode: actionFocusNode,
      onActionNavigateUp: onActionNavigateUp,
      onActionNavigateLeft: onActionNavigateLeft,
      onActionBack: onActionBack,
    ),
  );
}

/// Footer sliver for continuation (append-to-list) pagination: a spinner while
/// the next page loads, or the error message with a focusable retry button.
class ContinuationStatusSliver extends StatelessWidget {
  /// Failure from the last page load; null while the page is still loading.
  final Object? error;
  final VoidCallback onRetry;
  final FocusNode retryFocusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const ContinuationStatusSliver({
    super.key,
    required this.error,
    required this.onRetry,
    required this.retryFocusNode,
    this.onNavigateUp,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final exception = error;
    final message = exception == null ? null : t.messages.errorLoading(error: exception.toString());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: message == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: .min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FocusableButton(
                      focusNode: retryFocusNode,
                      onPressed: onRetry,
                      onNavigateUp: onNavigateUp,
                      onBack: onBack,
                      child: TextButton(onPressed: onRetry, child: Text(t.common.retry)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

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
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && items.isEmpty) {
      return ErrorStateWidget(
        message: errorMessage!,
        icon: Symbols.error_outline_rounded,
        onRetry: onRetry,
        retryLabel: t.common.retry,
      );
    }

    if (items.isEmpty) {
      return EmptyStateWidget(message: emptyMessage, icon: emptyIcon);
    }

    return builder(items);
  }
}
