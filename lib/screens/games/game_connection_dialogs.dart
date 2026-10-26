import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../games/game_models.dart';
import '../../games/game_streaming_client.dart';
import '../../i18n/strings.g.dart';

// Leave room for AlertDialog's default outer inset and horizontal content padding.
double _gameDialogContentWidth(BuildContext context) =>
    (MediaQuery.sizeOf(context).width - 128).clamp(0.0, 420.0).toDouble();

double _gamePairingQrSize(BuildContext context) =>
    min(360.0, _gameDialogContentWidth(context)).toDouble();

class AddGameComputerDialog extends StatefulWidget {
  const AddGameComputerDialog({super.key});
  @override
  State<AddGameComputerDialog> createState() => _AddGameComputerDialogState();
}

class _AddGameComputerDialogState extends State<AddGameComputerDialog> {
  final _name = TextEditingController(),
      _address = TextEditingController(),
      _port = TextEditingController(text: '47989'),
      _mac = TextEditingController();
  GameProtocol _protocol = GameProtocol.gameStream;
  String? _error;
  @override
  void dispose() {
    for (final c in [_name, _address, _port, _mac]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    try {
      final address = _address.text.trim(), port = int.parse(_port.text);
      if (port == 65535) throw const FormatException('Invalid port');
      final host = GameHost(
        id: '$address:$port',
        name: _name.text.trim().isEmpty ? address : _name.text.trim(),
        address: address,
        port: port,
        protocol: _protocol,
        mac: _mac.text.trim().isEmpty ? null : _mac.text.trim(),
      );
      Navigator.pop(context, host);
    } catch (_) {
      setState(() => _error = t.games.invalidAddress);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.games.addComputer),
    scrollable: true,
    content: SizedBox(
      width: _gameDialogContentWidth(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.games.manualHint),
          const SizedBox(height: 16),
          DropdownButtonFormField<GameProtocol>(
            initialValue: _protocol,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.games.protocol),
            items: [
              DropdownMenuItem(value: GameProtocol.gameStream, child: Text(t.games.moonlight)),
              DropdownMenuItem(value: GameProtocol.steam, child: Text(t.games.steam)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _protocol = value;
                  _port.text = value == GameProtocol.steam ? '27036' : '47989';
                });
              }
            },
          ),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: t.games.name),
            maxLength: 256,
          ),
          TextField(
            controller: _address,
            decoration: InputDecoration(labelText: t.games.address),
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
          ),
          TextField(
            controller: _port,
            decoration: InputDecoration(labelText: t.games.port),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          TextField(
            controller: _mac,
            decoration: InputDecoration(labelText: t.games.mac),
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
          ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(t.games.cancel)),
      FilledButton(onPressed: _save, child: Text(t.games.save)),
    ],
  );
}

class PairGameComputerDialog extends StatefulWidget {
  const PairGameComputerDialog({super.key, required this.host, required this.client, required this.isCurrent});
  final GameHost host;
  final GameStreamingClient client;
  final bool Function() isCurrent;
  @override
  State<PairGameComputerDialog> createState() => _PairGameComputerDialogState();
}

class _PairGameComputerDialogState extends State<PairGameComputerDialog> {
  late final String _pin = Random.secure().nextInt(10000).toString().padLeft(4, '0');
  String? _error;
  bool _complete = false;
  bool _closingStale = false;
  @override
  void initState() {
    super.initState();
    _pair();
  }

  Future<void> _pair() async {
    try {
      if (!widget.isCurrent()) {
        _closeIfStale();
        return;
      }
      await widget.client.pair(widget.host, _pin);
      if (!mounted) return;
      if (!widget.isCurrent()) {
        _closeIfStale();
        return;
      }
      _complete = true;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      if (!widget.isCurrent()) {
        _closeIfStale();
        return;
      }
      setState(
        () => _error = error is GameClientException && error.failure == GameClientFailure.timedOut
            ? t.games.timeout
            : t.games.unavailable,
      );
    }
  }

  void _closeIfStale() {
    if (!mounted || widget.isCurrent() || _closingStale) return;
    _closingStale = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isCurrent()) {
        _closingStale = false;
        return;
      }
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.of(context).pop(false);
    });
  }

  Future<void> _openPairingPage() async {
    if (!widget.isCurrent()) {
      _closeIfStale();
      return;
    }
    try {
      final opened = await launchUrl(widget.host.sunshinePairingPage, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!widget.isCurrent()) {
        _closeIfStale();
        return;
      }
      if (!opened) setState(() => _error = t.games.unavailable);
    } catch (_) {
      if (!mounted) return;
      if (!widget.isCurrent()) {
        _closeIfStale();
        return;
      }
      setState(() => _error = t.games.unavailable);
    }
  }

  @override
  void dispose() {
    if (!_complete) widget.client.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.games.pairTitle),
    scrollable: true,
    content: SizedBox(
      width: _gameDialogContentWidth(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.host.name),
          const SizedBox(height: 12),
          Text(widget.host.protocol == GameProtocol.steam ? t.games.steamPairInstructions : t.games.pairInstructions),
          const SizedBox(height: 16),
          SelectableText(_pin, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 16),
          if (widget.host.protocol == GameProtocol.gameStream) ...[
            Semantics(
              label: t.games.qrHelp,
              image: true,
              child: SizedBox.square(
                dimension: _gamePairingQrSize(context),
                child: QrImageView(
                  data: widget.host.sunshinePairingPage.toString(),
                  size: _gamePairingQrSize(context),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Text(t.games.qrHelp),
            TextButton(
              onPressed: _openPairingPage,
              child: Text(t.games.openPairingPage),
            ),
          ],
          if (_error == null)
            const LinearProgressIndicator()
          else
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.games.cancel))],
  );
}

class AddGameShortcutDialog extends StatefulWidget {
  const AddGameShortcutDialog({super.key, required this.host});
  final GameHost host;
  @override
  State<AddGameShortcutDialog> createState() => _AddGameShortcutDialogState();
}

class _AddGameShortcutDialogState extends State<AddGameShortcutDialog> {
  final _name = TextEditingController(), _id = TextEditingController();
  bool _invalid = false;
  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.games.addGame),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          maxLength: 256,
          decoration: InputDecoration(labelText: t.games.gameName),
        ),
        TextField(
          controller: _id,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: t.games.gameId),
        ),
        if (_invalid) Text(t.games.invalidGame),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(t.games.cancel)),
      FilledButton(
        onPressed: () {
          final id = int.tryParse(_id.text);
          if (_name.text.trim().isEmpty || id == null || id < 1 || id > 0x7fffffff) {
            setState(() => _invalid = true);
            return;
          }
          Navigator.pop(context, StreamGame(hostKey: widget.host.key, id: '$id', name: _name.text.trim()));
        },
        child: Text(t.games.saveShortcut),
      ),
    ],
  );
}
