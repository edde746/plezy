import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';

import '../../focus/back_press.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/dpad_select_long_press_controller.dart';
import '../../focus/focus_theme.dart';
import '../../theme/mono_tokens.dart';

/// One inline button on a [TvRowOrganizerScreen] row (a toggle such as Hero,
/// or a one-shot action such as Remove).
class TvOrganizerAction {
  const TvOrganizerAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.value,
    this.enabled = true,
    this.destructive = false,
    this.confirmLabel,
  });

  final String label;
  final IconData icon;

  /// On/off state for a toggle, null for a plain action.
  final bool? value;
  final bool enabled;
  final bool destructive;

  /// When set, the first press only arms the button (showing this label) and
  /// a second press runs it. Moving off the button disarms it.
  final String? confirmLabel;
  final Future<void> Function() onPressed;
}

class TvOrganizerEntry {
  const TvOrganizerEntry({
    required this.key,
    required this.title,
    this.subtitle,
    this.movable = true,
    this.actions = const [],
  });

  final String key;
  final String title;
  final String? subtitle;
  final bool movable;
  final List<TvOrganizerAction> actions;
}

/// TV-only row organizer: one screen, everything inline, driven entirely by
/// the d-pad with a virtual cursor (same model as the library management
/// dialog), so no per-row popup menus.
///
/// UP/DOWN move between rows, LEFT/RIGHT between the row and its buttons.
/// SELECT on the row (or a long SELECT anywhere, or the menu key) picks the
/// row up; UP/DOWN then move it, SELECT drops it and BACK puts it back.
/// SELECT on a button runs it. BACK leaves the screen.
class TvRowOrganizerScreen extends StatefulWidget {
  const TvRowOrganizerScreen({super.key, required this.title, required this.entries, this.onReorder});

  final String title;

  /// Rebuilt after every action, so it should read the caller's live state.
  final List<TvOrganizerEntry> Function() entries;

  /// Receives the keys of the movable entries in their new order.
  final Future<void> Function(List<String> keys)? onReorder;

  @override
  State<TvRowOrganizerScreen> createState() => _TvRowOrganizerScreenState();
}

class _TvRowOrganizerScreenState extends State<TvRowOrganizerScreen> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _backGate = BackPressGate();
  final _longPress = DpadSelectLongPressController();
  final Map<String, GlobalKey> _rowKeys = {};

  late List<TvOrganizerEntry> _entries;
  int _row = 0;
  int _column = 0;
  int? _moving;
  List<TvOrganizerEntry>? _beforeMove;
  String? _armedKey;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.entries();
  }

  @override
  void dispose() {
    _longPress.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted || _moving != null) return;
    setState(() {
      final focusedKey = _row < _entries.length ? _entries[_row].key : null;
      _entries = widget.entries();
      final kept = _entries.indexWhere((e) => e.key == focusedKey);
      _row = kept >= 0 ? kept : _row.clamp(0, _entries.isEmpty ? 0 : _entries.length - 1);
      _column = _column.clamp(0, _entries.isEmpty ? 0 : _entries[_row].actions.length);
      if (_column > 0 && !_entries[_row].actions[_column - 1].enabled) _column = 0;
    });
  }

  void _ensureVisible() {
    if (_row >= _entries.length) return;
    final context = _rowKeys[_entries[_row].key]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.35,
      duration: FocusTheme.navigationScrollDuration(this.context),
      curve: Curves.easeOut,
    );
  }

  void _setFocus(int row, int column) {
    setState(() {
      _row = row;
      _column = column;
      _armedKey = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
  }

  int? _nextEnabledColumn(int from, int step) {
    final actions = _entries[_row].actions;
    for (var c = from + step; c >= 0 && c <= actions.length; c += step) {
      if (c == 0 || actions[c - 1].enabled) return c;
    }
    return null;
  }

  void _startMove() {
    if (_entries.isEmpty || !_entries[_row].movable || widget.onReorder == null) return;
    setState(() {
      _moving = _row;
      _column = 0;
      _armedKey = null;
      _beforeMove = List.of(_entries);
    });
  }

  void _moveBy(int step) {
    final from = _moving!;
    final to = from + step;
    if (to < 0 || to >= _entries.length || !_entries[to].movable) return;
    setState(() {
      final entry = _entries.removeAt(from);
      _entries.insert(to, entry);
      _moving = to;
      _row = to;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
  }

  Future<void> _dropMove() async {
    final changed = _beforeMove != null && !_sameOrder(_beforeMove!, _entries);
    setState(() {
      _moving = null;
      _beforeMove = null;
    });
    if (changed) {
      await widget.onReorder!([
        for (final e in _entries)
          if (e.movable) e.key,
      ]);
    }
    _refresh();
  }

  void _cancelMove() {
    setState(() {
      final key = _entries[_moving!].key;
      _entries = _beforeMove ?? _entries;
      _row = _entries.indexWhere((e) => e.key == key).clamp(0, _entries.length - 1);
      _moving = null;
      _beforeMove = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
  }

  static bool _sameOrder(List<TvOrganizerEntry> a, List<TvOrganizerEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].key != b[i].key) return false;
    }
    return true;
  }

  Future<void> _activate(int row, int column) async {
    if (_busy || row >= _entries.length) return;
    if (column == 0) {
      _startMove();
      return;
    }
    final entry = _entries[row];
    final action = entry.actions[column - 1];
    if (!action.enabled) return;
    final armKey = '${entry.key}#$column';
    if (action.confirmLabel != null && _armedKey != armKey) {
      setState(() => _armedKey = armKey);
      return;
    }
    setState(() {
      _busy = true;
      _armedKey = null;
    });
    try {
      await action.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
      _refresh();
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    final back = _backGate.handle(event, () {
      if (_moving != null) {
        _cancelMove();
      } else {
        Navigator.of(context).maybePop();
      }
    });
    if (back != KeyEventResult.ignored) return back;

    if (_entries.isEmpty) return key.isDpadDirection ? KeyEventResult.handled : KeyEventResult.ignored;

    if (key.isSelectKey) {
      return _longPress.handleKeyEvent(
        event,
        isOwnerActive: () => mounted && _focusNode.hasFocus,
        onShortPress: () {
          if (_moving != null) {
            unawaited(_dropMove());
          } else {
            unawaited(_activate(_row, _column));
          }
        },
        onLongPress: () {
          if (_moving == null) _startMove();
        },
      );
    }

    if (!event.isActionable) return KeyEventResult.ignored;

    if (key.isContextMenuKey && _moving == null) {
      _startMove();
      return KeyEventResult.handled;
    }

    if (_moving != null) {
      if (key.isUpKey) _moveBy(-1);
      if (key.isDownKey) _moveBy(1);
      return key.isDpadDirection ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    if (key.isUpKey && _row > 0) {
      _setFocus(_row - 1, _clampColumn(_row - 1, _column));
    } else if (key.isDownKey && _row < _entries.length - 1) {
      _setFocus(_row + 1, _clampColumn(_row + 1, _column));
    } else if (key.isLeftKey) {
      final c = _nextEnabledColumn(_column, -1);
      if (c != null) _setFocus(_row, c);
    } else if (key.isRightKey) {
      final c = _nextEnabledColumn(_column, 1);
      if (c != null) _setFocus(_row, c);
    }
    return key.isDpadDirection ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  /// Keeps the cursor in the same button column when moving between rows
  /// that have it, so toggling Hero down a list is just DOWN, SELECT.
  int _clampColumn(int row, int column) {
    final actions = _entries[row].actions;
    if (column == 0 || column > actions.length || !actions[column - 1].enabled) return 0;
    return column;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _moving != null ? t.homeLayout.moveRowHint : t.homeLayout.organizeRowsHint;
    return PopScope(
      canPop: _moving == null,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title), automaticallyImplyLeading: false),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: _moving != null ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
              child: Text(
                hint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _moving != null ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Focus(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: _onKey,
                child: _entries.isEmpty
                    ? Center(child: Text(t.homeLayout.noRowsHere))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) => _buildRow(context, index),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = _entries[index];
    final focusedRow = index == _row;
    final moving = index == _moving;
    final rowFocused = focusedRow && _column == 0;

    final Color background;
    if (moving) {
      background = scheme.primaryContainer;
    } else if (rowFocused) {
      background = scheme.surfaceContainerHighest;
    } else {
      background = Colors.transparent;
    }

    return Padding(
      key: _rowKeys.putIfAbsent(entry.key, GlobalKey.new),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedContainer(
        duration: FocusTheme.getAnimationDuration(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rowFocused || moving ? FocusTheme.getFocusBorderColor(context) : Colors.transparent,
            width: FocusTheme.focusBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Semantics(
              button: true,
              enabled: entry.movable && widget.onReorder != null,
              label: entry.title,
              hint: t.homeLayout.organizeRowsHint,
              onTap: entry.movable && widget.onReorder != null
                  ? () {
                      _setFocus(index, 0);
                      _startMove();
                    }
                  : null,
              child: ExcludeSemantics(
                child: ExcludeFocus(
                  child: IconButton(
                    onPressed: entry.movable && widget.onReorder != null
                        ? () {
                            _setFocus(index, 0);
                            _startMove();
                          }
                        : null,
                    icon: Icon(
                      moving ? Symbols.swap_vert_rounded : Symbols.drag_indicator_rounded,
                      color: moving
                          ? scheme.primary
                          : (entry.movable ? scheme.onSurfaceVariant : scheme.outlineVariant),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (entry.subtitle != null && entry.subtitle!.isNotEmpty)
                    Text(
                      entry.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            for (final (i, action) in entry.actions.indexed) ...[
              const SizedBox(width: 8),
              _buildAction(context, entry, index, i + 1, action),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, TvOrganizerEntry entry, int row, int column, TvOrganizerAction action) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = row == _row && column == _column && _moving == null;
    final armed = _armedKey == '${entry.key}#$column';
    final on = action.value == true;

    final Color fill;
    final Color fg;
    if (!action.enabled) {
      fill = Colors.transparent;
      fg = scheme.onSurface.withValues(alpha: 0.35);
    } else if (armed) {
      fill = scheme.error;
      fg = scheme.onError;
    } else if (on) {
      fill = scheme.secondaryContainer;
      fg = scheme.onSecondaryContainer;
    } else if (focused) {
      fill = tokens(context).text.withValues(alpha: 0.12);
      fg = action.destructive ? scheme.error : scheme.primary;
    } else {
      fill = Colors.transparent;
      fg = action.destructive ? scheme.error : scheme.onSurfaceVariant;
    }

    final label = armed
        ? action.confirmLabel!
        : action.value == null
        ? action.label
        : t.homeLayout.actionState(action: action.label, state: on ? t.homeLayout.on : t.common.off);

    void activate() {
      if (!action.enabled) return;
      _setFocus(row, column);
      unawaited(_activate(row, column));
    }

    return Semantics(
      button: true,
      selected: action.value,
      enabled: action.enabled,
      focused: focused,
      label: label,
      onTap: action.enabled ? activate : null,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            duration: FocusTheme.getAnimationDuration(context),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(MonoTokens.radiusFull),
              border: focused
                  ? Border.all(color: FocusTheme.getFocusBorderColor(context), width: FocusTheme.focusBorderWidth)
                  : null,
            ),
            child: InkWell(
              onTap: action.enabled ? activate : null,
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.value == true ? Symbols.check_rounded : action.icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: focused ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
