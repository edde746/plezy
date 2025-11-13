import 'package:flutter/material.dart';
import '../utils/platform_detector.dart';
import '../i18n/strings.g.dart';

/// A menu action item for context menus
class ContextMenuItem {
  final String value;
  final IconData icon;
  final String label;
  final bool requiresConfirmation;
  final String? confirmationTitle;
  final String? confirmationMessage;
  final bool isDestructive;

  const ContextMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.requiresConfirmation = false,
    this.confirmationTitle,
    this.confirmationMessage,
    this.isDestructive = false,
  });
}

/// A wrapper widget that shows context menus differently based on platform.
/// On mobile (iOS/Android): Shows a bottom sheet on long-press
/// On desktop (Windows/macOS/Linux): Shows a popup menu on right-click or long-press
class ContextMenuWrapper extends StatefulWidget {
  final Widget child;
  final List<ContextMenuItem> menuItems;
  final Function(String)? onMenuItemSelected;
  final VoidCallback? onTap;
  final String? title;
  final bool forceBottomSheet;

  const ContextMenuWrapper({
    super.key,
    required this.child,
    required this.menuItems,
    this.onMenuItemSelected,
    this.onTap,
    this.title,
    this.forceBottomSheet = false,
  });

  @override
  State<ContextMenuWrapper> createState() => _ContextMenuWrapperState();
}

class _ContextMenuWrapperState extends State<ContextMenuWrapper> {
  Offset _tapPosition = Offset.zero;

  void _storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required bool isDestructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(t.common.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showContextMenu(BuildContext context) async {
    final useBottomSheet =
        widget.forceBottomSheet || PlatformDetector.isMobile(context);
    String? selected;

    if (useBottomSheet) {
      // Mobile: Show bottom sheet
      selected = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.title!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ...widget.menuItems.map(
                (item) => ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  onTap: () => Navigator.pop(context, item.value),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Desktop: Show popup menu
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final overlayRect = Rect.fromPoints(
        _tapPosition,
        _tapPosition.translate(1, 1),
      );

      final menuItems = widget.menuItems
          .map(
            (item) => PopupMenuItem<String>(
              value: item.value,
              child: Row(
                children: [
                  Icon(item.icon, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.label)),
                ],
              ),
            ),
          )
          .toList();

      selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          overlayRect,
          Offset.zero & overlay.size,
        ),
        items: menuItems,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        popUpAnimationStyle: AnimationStyle(
          duration: const Duration(milliseconds: 150),
          reverseDuration: const Duration(milliseconds: 100),
        ),
      );
    }

    if (selected != null && widget.onMenuItemSelected != null) {
      // Find the selected item to check if confirmation is needed
      final selectedItem = widget.menuItems.firstWhere(
        (item) => item.value == selected,
      );

      if (selectedItem.requiresConfirmation) {
        final confirmed = await _showConfirmationDialog(
          title: selectedItem.confirmationTitle ?? t.dialog.confirmAction,
          message: selectedItem.confirmationMessage ?? t.dialog.areYouSure,
          isDestructive: selectedItem.isDestructive,
        );

        if (!confirmed) return;
      }

      widget.onMenuItemSelected!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _storeTapPosition,
      onLongPress: () => _showContextMenu(context),
      onSecondaryTapDown: _storeTapPosition,
      onSecondaryTap: () => _showContextMenu(context),
      child: widget.child,
    );
  }
}
