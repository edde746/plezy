import 'package:flutter/material.dart';

import 'focused_scroll_scaffold.dart';

/// Standard scaffold for settings pages made of ordinary list rows.
class SettingsPage extends StatelessWidget {
  final Widget title;
  final List<Widget>? children;
  final List<Widget>? slivers;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final bool pinned;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;

  const SettingsPage({
    super.key,
    required this.title,
    required List<Widget> this.children,
    this.actions,
    this.padding,
    this.pinned = true,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
  }) : slivers = null;

  const SettingsPage.slivers({
    super.key,
    required this.title,
    required List<Widget> this.slivers,
    this.actions,
    this.pinned = true,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
  }) : children = null,
       padding = null;

  @override
  Widget build(BuildContext context) {
    final pageSlivers = slivers ?? [_buildListSliver()];
    return FocusedScrollScaffold(
      title: title,
      actions: actions,
      pinned: pinned,
      automaticallyImplyLeading: automaticallyImplyLeading,
      onBackPressed: onBackPressed,
      slivers: pageSlivers,
    );
  }

  Widget _buildListSliver() {
    final list = SliverList(delegate: SliverChildListDelegate(children!));
    final pagePadding = padding;
    if (pagePadding == null) return list;
    return SliverPadding(padding: pagePadding, sliver: list);
  }
}
