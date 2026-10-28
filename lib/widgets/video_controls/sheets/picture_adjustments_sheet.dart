import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_slider.dart';
import '../../../i18n/strings.g.dart';
import '../../../mpv/mpv.dart';
import '../../../widgets/app_icon.dart';

Future<void> showPictureAdjustmentsSheet(BuildContext context, Player player, {required VoidCallback onChanged}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PictureAdjustmentsSheet(player: player, onChanged: onChanged),
  );
}

class _PictureAdjustmentsSheet extends StatefulWidget {
  const _PictureAdjustmentsSheet({required this.player, required this.onChanged});
  final Player player;
  final VoidCallback onChanged;

  @override
  State<_PictureAdjustmentsSheet> createState() => _PictureAdjustmentsSheetState();
}

class _PictureAdjustmentsSheetState extends State<_PictureAdjustmentsSheet> {
  static const _properties = ['brightness', 'contrast', 'gamma', 'hue', 'saturation'];
  final Map<String, int> _values = {for (final property in _properties) property: 0};
  Timer? _debounce;
  Future<void> _writes = Future.value();
  bool _projectionEnabled = false;
  bool _projectionUnavailable = false;
  double _yaw = 0;
  double _pitch = 0;
  double _fieldOfView = 90;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentSettings());
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final values = await Future.wait(_properties.map(widget.player.getProperty));
      final filter = await widget.player.getProperty('vf') ?? '';
      if (!mounted) return;
      double filterValue(String name, double fallback) {
        final match = RegExp('(?:^|[:,])${RegExp.escape(name)}=(-?\\d+(?:\\.\\d+)?)').firstMatch(filter);
        return double.tryParse(match?.group(1) ?? '') ?? fallback;
      }

      setState(() {
        for (var index = 0; index < _properties.length; index++) {
          _values[_properties[index]] = (double.tryParse(values[index] ?? '') ?? 0).round().clamp(-100, 100);
        }
        _projectionEnabled = filter.contains('@plezy360');
        _yaw = filterValue('yaw', 0).clamp(0, 360);
        _pitch = filterValue('pitch', 0).clamp(-90, 90);
        _fieldOfView = filterValue('h_fov', 90).clamp(10, 180);
      });
    } on Object {
      // Defaults remain available if a property read is unsupported.
    }
  }

  void _setPictureValue(String property, double value) {
    widget.onChanged();
    setState(() => _values[property] = value.round().clamp(-100, 100));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), _queuePictureWrites);
  }

  void _queuePictureWrites() {
    final snapshot = Map<String, int>.of(_values);
    final next = _writes.then((_) async {
      for (final property in _properties) {
        await widget.player.setProperty(property, snapshot[property]!.toString());
      }
    });
    _writes = next.catchError((Object _) {
      if (!_disposed && mounted) setState(() {});
    });
  }

  String _projectionFilter() {
    final parameters =
        'input=equirect:output=flat:yaw=${_yaw.toStringAsFixed(1)}:pitch=${_pitch.toStringAsFixed(1)}'
        ':h_fov=${_fieldOfView.toStringAsFixed(1)}';
    return '@plezy360:lavfi=[v360=$parameters]';
  }

  Future<void> _applyProjection() async {
    try {
      if (_projectionEnabled) {
        try {
          await widget.player.command(['vf', 'del', '@plezy360']);
        } on Object {
          // Reapplying the labelled filter is still attempted below.
        }
      }
      await widget.player.command(['vf', 'add', _projectionFilter()]);
      if (mounted) {
        widget.onChanged();
        setState(() {
          _projectionEnabled = true;
          _projectionUnavailable = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _projectionEnabled = false;
          _projectionUnavailable = true;
        });
      }
    }
  }

  Future<void> _removeProjection() async {
    try {
      await widget.player.command(['vf', 'del', '@plezy360']);
    } on Object {
      // The player may already have closed its filter chain.
    }
    if (mounted) {
      widget.onChanged();
      setState(() {
        _projectionEnabled = false;
        _projectionUnavailable = false;
      });
    }
  }

  Future<void> _reset() async {
    _debounce?.cancel();
    widget.onChanged();
    setState(() {
      for (final property in _properties) {
        _values[property] = 0;
      }
      _yaw = 0;
      _pitch = 0;
      _fieldOfView = 90;
      _projectionEnabled = false;
      _projectionUnavailable = false;
    });
    final next = _writes.then((_) async {
      for (final property in _properties) {
        await widget.player.setProperty(property, '0');
      }
      await widget.player.command(['vf', 'del', '@plezy360']);
    });
    _writes = next.catchError((Object _) {});
  }

  Widget _adjustment(String property, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(_values[property]!.toString(), semanticsLabel: '$label ${_values[property]}'),
          ],
        ),
        FocusableSlider(
          value: _values[property]!.toDouble(),
          min: -100,
          max: 100,
          divisions: 200,
          semanticLabel: label,
          semanticFormatterCallback: (value) => value.round().toString(),
          onChanged: (value) => _setPictureValue(property, value),
        ),
      ],
    ),
  );

  Widget _projectionSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value.round().toString(), semanticsLabel: '$label ${value.round()}'),
          ],
        ),
        FocusableSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          semanticLabel: label,
          semanticFormatterCallback: (value) => value.round().toString(),
          onChanged: onChanged,
          onChangeEnd: (_) => unawaited(_applyProjection()),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _disposed = true;
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
      _queuePictureWrites();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.universalMedia.pictureAdjustments, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const AppIcon(Symbols.restart_alt_rounded),
                    label: Text(t.universalMedia.resetPicture),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(t.universalMedia.pictureHelp),
                  const SizedBox(height: 20),
                  _adjustment('brightness', t.universalMedia.brightness),
                  _adjustment('contrast', t.universalMedia.contrast),
                  _adjustment('gamma', t.universalMedia.gamma),
                  _adjustment('hue', t.universalMedia.hue),
                  _adjustment('saturation', t.universalMedia.saturation),
                  const Divider(height: 32),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const AppIcon(Symbols.view_in_ar_rounded),
                    title: Text(t.universalMedia.view360),
                    subtitle: Text(t.universalMedia.view360Help),
                    value: _projectionEnabled,
                    onChanged: (enabled) {
                      if (enabled) {
                        unawaited(_applyProjection());
                      } else {
                        unawaited(_removeProjection());
                      }
                    },
                  ),
                  if (_projectionUnavailable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        t.universalMedia.view360Unavailable,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  if (_projectionEnabled) ...[
                    _projectionSlider(
                      label: t.universalMedia.view360Yaw,
                      value: _yaw,
                      min: 0,
                      max: 360,
                      divisions: 360,
                      onChanged: (value) => setState(() => _yaw = value),
                    ),
                    _projectionSlider(
                      label: t.universalMedia.view360Pitch,
                      value: _pitch,
                      min: -90,
                      max: 90,
                      divisions: 180,
                      onChanged: (value) => setState(() => _pitch = value),
                    ),
                    _projectionSlider(
                      label: t.universalMedia.view360FieldOfView,
                      value: _fieldOfView,
                      min: 30,
                      max: 130,
                      divisions: 100,
                      onChanged: (value) => setState(() => _fieldOfView = value),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
