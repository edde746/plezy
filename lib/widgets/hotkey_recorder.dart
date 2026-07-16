import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/dpad_navigator.dart';
import '../models/hotkey_model.dart';

/// Captures a key combination from the user and calls [onHotKeyRecorded].
class HotKeyRecorder extends StatefulWidget {
  const HotKeyRecorder({
    super.key,
    this.initalHotKey,
    required this.onHotKeyRecorded,
    this.enabled = true,
    this.placeholder,
  });

  final HotKey? initalHotKey;
  final ValueChanged<HotKey> onHotKeyRecorded;
  final bool enabled;
  final Widget? placeholder;

  @override
  State<HotKeyRecorder> createState() => _HotKeyRecorderState();
}

class _HotKeyRecorderState extends State<HotKeyRecorder> {
  HotKey? _hotKey;

  @override
  void initState() {
    super.initState();
    _hotKey = widget.initalHotKey;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void didUpdateWidget(HotKeyRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initalHotKey != oldWidget.initalHotKey) {
      _hotKey = widget.initalHotKey;
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent keyEvent) {
    if (!widget.enabled) return false;
    if (keyEvent is KeyUpEvent) return false;

    final physicalKeysPressed = HardwareKeyboard.instance.physicalKeysPressed;
    final PhysicalKeyboardKey key = keyEvent.physicalKey;

    // Detect which modifiers are currently held down, excluding the primary key
    final List<HotKeyModifier> modifiers = HotKeyModifier.values
        .where((m) => m.physicalKeys.any(physicalKeysPressed.contains))
        .where((m) => !m.physicalKeys.contains(key))
        .toList();

    final hotKey = HotKey(key: key, modifiers: modifiers.isNotEmpty ? modifiers : null);
    setState(() => _hotKey = hotKey);

    final isModifierOnly = HotKeyModifier.values.any((modifier) => modifier.physicalKeys.contains(key));
    if (isModifierOnly) return true;

    if (keyEvent.logicalKey.isSelectKey) {
      SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    }
    widget.onHotKeyRecorded(hotKey);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_hotKey == null) return widget.placeholder ?? const SizedBox.shrink();
    return HotKeyVirtualView(hotKey: _hotKey!);
  }
}

/// Renders a [HotKey] as a row of styled key label chips.
class HotKeyVirtualView extends StatelessWidget {
  const HotKeyVirtualView({super.key, required this.hotKey});

  final HotKey hotKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final modifier in hotKey.modifiers ?? [])
          _VirtualKeyView(keyLabel: physicalKeyLabel(modifier.physicalKeys.first)),
        _VirtualKeyView(keyLabel: physicalKeyLabel(hotKey.key)),
      ],
    );
  }
}

class _VirtualKeyView extends StatelessWidget {
  const _VirtualKeyView({required this.keyLabel});

  final String keyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border.fromBorderSide(BorderSide(color: Theme.of(context).dividerColor)),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0.0, 1.0))],
      ),
      child: Text(keyLabel, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
    );
  }
}
