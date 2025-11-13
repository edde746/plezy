import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/strings.g.dart';

/// Dialog for entering a PIN to access a protected profile
class PinEntryDialog extends StatefulWidget {
  final String userName;
  final String? errorMessage;

  const PinEntryDialog({super.key, required this.userName, this.errorMessage});

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscureText = true;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create a shake effect that oscillates
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    // Auto-focus the PIN field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();

      // If there's an error message, trigger shake and clear field
      if (widget.errorMessage != null) {
        _pinController.clear();
        _shakeController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.userName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pinController,
              focusNode: _focusNode,
              obscureText: _obscureText,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                hintText: t.pinEntry.enterPin,
                border: const OutlineInputBorder(),
                errorText: widget.errorMessage,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  tooltip: _obscureText
                      ? t.pinEntry.showPin
                      : t.pinEntry.hidePin,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(t.common.cancel),
          ),
          FilledButton(onPressed: _submit, child: Text(t.common.submit)),
        ],
      ),
    );
  }
}

/// Shows the PIN entry dialog and returns the entered PIN, or null if cancelled
Future<String?> showPinEntryDialog(
  BuildContext context,
  String userName, {
  String? errorMessage,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        PinEntryDialog(userName: userName, errorMessage: errorMessage),
  );
}
