import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _recordedHotKey = widget.currentHotKey;
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Shortcut for ${widget.actionName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current shortcut:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: HotKeyRecorder(
                        initalHotKey: _recordedHotKey,
                        onHotKeyRecorded: (hotKey) {
                          setState(() {
                            _recordedHotKey = hotKey;
                          });
                        },
                      ),
                    ),
                    if (_recordedHotKey != null)
                      IconButton(
                        icon: const Icon(Icons.backspace, size: 18),
                        onPressed: () {
                          setState(() {
                            _recordedHotKey = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        tooltip: 'Clear shortcut',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Press any key combination to set a new shortcut',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        TextButton(
          onPressed: _recordedHotKey != null
              ? () => widget.onHotKeyRecorded(_recordedHotKey!)
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
