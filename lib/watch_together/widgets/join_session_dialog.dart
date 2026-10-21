import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';
import '../providers/watch_together_provider.dart';
import '../services/watch_party_relays.dart';
import 'watch_labels.dart';

/// Asks for a room code and joins that room. True once joined.
Future<bool> showJoinRoomDialog(BuildContext context) async =>
    await showScopedDialog<bool>(context: context, builder: (_) => const JoinRoomDialog()) ?? false;

/// The code entry of [showJoinRoomDialog]: typed or pasted, shown as
/// `K7M-Q2X`, with the join's error under the field.
class JoinRoomDialog extends StatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final _controller = TextEditingController();
  final _fieldFocusNode = FocusNode(debugLabel: 'JoinRoomCode');
  final _pasteFocusNode = FocusNode(debugLabel: 'JoinRoomPaste');
  final _cancelFocusNode = FocusNode(debugLabel: 'JoinRoomCancel');
  final _joinFocusNode = FocusNode(debugLabel: 'JoinRoomJoin');
  String? _error;
  bool _joining = false;

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocusNode.dispose();
    _pasteFocusNode.dispose();
    _cancelFocusNode.dispose();
    _joinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final code = roomCodeIn(data?.text ?? '');
    if (code == null) {
      setState(() => _error = t.watchTogether.noCodeInClipboard);
      return;
    }
    final text = owp.formatCode(code);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _error = null);
    _joinFocusNode.requestFocus();
  }

  Future<void> _join() async {
    if (_joining) return;
    final code = normalizeRoomCode(_controller.text);
    if (code == null) {
      setState(() => _error = watchErrorText(owp.ErrorCode.invalidCode));
      return;
    }
    final provider = context.read<WatchTogetherProvider>();
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await provider.joinRoom(code);
      if (mounted) Navigator.of(context).pop(true);
    } on owp.PartyException catch (error) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        if (error.code != owp.ErrorCode.cancelled) _error = watchErrorText(error.code);
      });
    }
  }

  void _cancel() => Navigator.of(context).pop(false);

  /// Leaving the dialog any way but a finished join (Cancel, Back, Escape,
  /// gamepad B, a tap outside) also stops a join that is under way, so the
  /// user isn't put into the room they backed out of.
  void _onPopped(bool didPop, bool? joined) {
    if (didPop && _joining && joined != true) context.read<WatchTogetherProvider>().leave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<bool>(
      onPopInvokedWithResult: _onPopped,
      child: AlertDialog(
        title: Text(t.watchTogether.joinRoom),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.watchTogether.enterRoomCode,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FocusableTextField(
                controller: _controller,
                focusNode: _fieldFocusNode,
                autofocus: true,
                enabled: !_joining,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.go,
                inputFormatters: const [RoomCodeInputFormatter()],
                style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'monospace', letterSpacing: 2),
                decoration: InputDecoration(
                  labelText: t.watchTogether.roomCode,
                  hintText: 'K7M-Q2X',
                  errorText: _error,
                  errorMaxLines: 3,
                  prefixIcon: const AppIcon(Symbols.tag_rounded),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _join(),
                onNavigateDown: _joinFocusNode.requestFocus,
              ),
            ],
          ),
        ),
        actions: [
          DialogActionButton(
            focusNode: _pasteFocusNode,
            onPressed: _joining ? null : _paste,
            label: t.watchTogether.paste,
            icon: const AppIcon(Symbols.content_paste_rounded),
            onNavigateUp: _fieldFocusNode.requestFocus,
            onNavigateRight: _cancelFocusNode.requestFocus,
          ),
          DialogActionButton(
            focusNode: _cancelFocusNode,
            onPressed: _cancel,
            label: t.common.cancel,
            onNavigateUp: _fieldFocusNode.requestFocus,
            onNavigateLeft: _pasteFocusNode.requestFocus,
            onNavigateRight: _joinFocusNode.requestFocus,
          ),
          DialogActionButton(
            focusNode: _joinFocusNode,
            onPressed: _joining ? null : _join,
            label: _joining ? t.watchTogether.joiningRoom : t.watchTogether.joinRoom,
            isPrimary: true,
            onNavigateUp: _fieldFocusNode.requestFocus,
            onNavigateLeft: _cancelFocusNode.requestFocus,
          ),
        ],
      ),
    );
  }
}

/// Room code entry: letters and digits only, upper case, at most 6 symbols,
/// grouped as `K7M-Q2X`. Whatever separators the user types or pastes drop
/// out; symbols outside the code alphabet stay, so the join can say the code
/// is wrong instead of silently eating them.
class RoomCodeInputFormatter extends TextInputFormatter {
  const RoomCodeInputFormatter();

  static final _notSymbol = RegExp('[^A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final symbols = newValue.text.toUpperCase().replaceAll(_notSymbol, '');
    final kept = symbols.length > 6 ? symbols.substring(0, 6) : symbols;
    final text = kept.length > 3 ? '${kept.substring(0, 3)}-${kept.substring(3)}' : kept;
    // Keep the caret after the same number of symbols.
    final caret = newValue.selection.isValid ? newValue.selection.extentOffset : newValue.text.length;
    final before = newValue.text
        .substring(0, caret.clamp(0, newValue.text.length))
        .toUpperCase()
        .replaceAll(_notSymbol, '')
        .length
        .clamp(0, kept.length);
    final offset = before > 3 ? before + 1 : before;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// The room code in [text]: the whole text as a code, else the first word in
/// it written like one (an invite message): `K7M-Q2X` first, then a word with
/// a digit. A plain word such as "snacks" never counts. Null without one.
String? roomCodeIn(String text) {
  final whole = normalizeRoomCode(text);
  if (whole != null) return whole;
  String? withDigit;
  for (final match in _codeWord.allMatches(text)) {
    final word = match[0]!;
    final code = normalizeRoomCode(word);
    if (code == null) continue;
    if (word.contains('-')) return code;
    if (word.contains(_digit)) withDigit ??= code;
  }
  return withDigit;
}

final _digit = RegExp('[0-9]');

final _codeWord = RegExp(r'(?<![A-Za-z0-9])[A-Za-z0-9]{3}-?[A-Za-z0-9]{3}(?![A-Za-z0-9])');
