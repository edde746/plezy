import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/hotkey_model.dart';
import '../../widgets/hotkey_recorder.dart';
import '../../i18n/strings.g.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_wrapper.dart';
import '../../widgets/dialog_action_button.dart';

class HotKeyRecorderWidget extends StatefulWidget {
  final String actionName;
  final HotKey? currentHotKey;
  final Function(HotKey) onHotKeyRecorded;
  final VoidCallback onCancel;

  const HotKeyRecorderWidget({
    super.key,
    required this.actionName,
    this.currentHotKey,
    required this.onHotKeyRecorded,
    required this.onCancel,
  });

  @override
  State<HotKeyRecorderWidget> createState() => _HotKeyRecorderWidgetState();
}

class _HotKeyRecorderWidgetState extends State<HotKeyRecorderWidget> {
  HotKey? _recordedHotKey;
  bool _isCapturing = false;
  final _recorderFocusNode = FocusNode(debugLabel: 'HotKeyRecorder.record');
  final _clearFocusNode = FocusNode(debugLabel: 'HotKeyRecorder.clear');
  final _cancelFocusNode = FocusNode(debugLabel: 'HotKeyRecorder.cancel');
  final _saveFocusNode = FocusNode(debugLabel: 'HotKeyRecorder.save');

  @override
  void initState() {
    super.initState();
    _recordedHotKey = widget.currentHotKey;
  }

  @override
  void dispose() {
    _recorderFocusNode.dispose();
    _clearFocusNode.dispose();
    _cancelFocusNode.dispose();
    _saveFocusNode.dispose();
    super.dispose();
  }

  void _startCapturing() {
    setState(() => _isCapturing = true);
    _recorderFocusNode.requestFocus();
  }

  void _handleHotKeyRecorded(HotKey hotKey) {
    setState(() {
      _recordedHotKey = hotKey;
      _isCapturing = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _saveFocusNode.requestFocus();
    });
  }

  void _clearShortcut() {
    setState(() {
      _recordedHotKey = null;
      _isCapturing = false;
    });
    _recorderFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasShortcut = _recordedHotKey != null;
    final recordLabel = _isCapturing ? t.hotkeys.recordingShortcut : t.hotkeys.pressToRecord;

    return AlertDialog(
      title: Text(t.hotkeys.setShortcutFor(actionName: widget.actionName)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Text(
                t.hotkeys.currentShortcut,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: .bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: FocusableWrapper(
                      focusNode: _recorderFocusNode,
                      autofocus: true,
                      onSelect: _startCapturing,
                      onBack: widget.onCancel,
                      onNavigateRight: hasShortcut ? _clearFocusNode.requestFocus : null,
                      onNavigateDown: (hasShortcut ? _saveFocusNode : _cancelFocusNode).requestFocus,
                      semanticLabel: recordLabel,
                      descendantsAreFocusable: false,
                      useBackgroundFocus: true,
                      child: GestureDetector(
                        onTap: _startCapturing,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(BorderSide(color: Theme.of(context).dividerColor)),
                            borderRadius: const BorderRadius.all(Radius.circular(6)),
                          ),
                          child: HotKeyRecorder(
                            initalHotKey: _recordedHotKey,
                            enabled: _isCapturing,
                            placeholder: Text(recordLabel),
                            onHotKeyRecorded: _handleHotKeyRecorded,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasShortcut) ...[
                    const SizedBox(width: 8),
                    FocusableButton(
                      focusNode: _clearFocusNode,
                      onPressed: _clearShortcut,
                      onBack: widget.onCancel,
                      onNavigateLeft: _recorderFocusNode.requestFocus,
                      onNavigateDown: _saveFocusNode.requestFocus,
                      autoScroll: false,
                      child: IconButton(
                        icon: const AppIcon(Symbols.backspace_rounded, fill: 1, size: 18),
                        onPressed: _clearShortcut,
                        padding: .zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: t.hotkeys.clearShortcut,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recordLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        DialogActionButton(
          focusNode: _cancelFocusNode,
          onPressed: widget.onCancel,
          onBack: widget.onCancel,
          onNavigateUp: _recorderFocusNode.requestFocus,
          onNavigateRight: _saveFocusNode.requestFocus,
          label: t.common.cancel,
        ),
        DialogActionButton(
          focusNode: _saveFocusNode,
          onPressed: hasShortcut ? () => widget.onHotKeyRecorded(_recordedHotKey!) : null,
          onBack: widget.onCancel,
          onNavigateUp: _recorderFocusNode.requestFocus,
          onNavigateLeft: _cancelFocusNode.requestFocus,
          label: t.common.save,
          isPrimary: true,
        ),
      ],
    );
  }
}
