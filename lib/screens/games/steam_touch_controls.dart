import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../widgets/app_icon.dart';

/// Touch assistance for player one. Platform adapters merge it independently
/// of physical controllers; removing this overlay releases assistance only.
class SteamTouchControls extends StatefulWidget {
  const SteamTouchControls({super.key, required this.onButton, required this.onStick, required this.onRelease});
  final void Function(String, bool) onButton;
  final void Function(String, Offset) onStick;
  final VoidCallback onRelease;

  @override
  State<SteamTouchControls> createState() => _SteamTouchControlsState();
}

class _SteamTouchControlsState extends State<SteamTouchControls> {
  @override
  void dispose() {
    widget.onRelease();
    super.dispose();
  }

  Widget _button(String name, String label, {IconData? icon}) => _HeldButton(
    key: ValueKey(name),
    label: label,
    onChanged: (down) => widget.onButton(name, down),
    child: icon == null ? Text(label) : AppIcon(icon),
  );

  Widget _cross({required bool directions}) => SizedBox(
    width: 144,
    height: 144,
    child: Stack(
      children: [
        Positioned(
          left: 48,
          top: 0,
          child: directions ? _button('dpadUp', '↑', icon: Symbols.arrow_upward_rounded) : _button('y', 'Y'),
        ),
        Positioned(
          left: 0,
          top: 48,
          child: directions ? _button('dpadLeft', '←', icon: Symbols.arrow_back_rounded) : _button('x', 'X'),
        ),
        Positioned(
          left: 96,
          top: 48,
          child: directions ? _button('dpadRight', '→', icon: Symbols.arrow_forward_rounded) : _button('b', 'B'),
        ),
        Positioned(
          left: 48,
          top: 96,
          child: directions ? _button('dpadDown', '↓', icon: Symbols.arrow_downward_rounded) : _button('a', 'A'),
        ),
      ],
    ),
  );

  Widget _stick(bool left) => _Stick(
    key: ValueKey(left ? 'leftStick' : 'rightStick'),
    label: left ? t.games.leftStick : t.games.rightStick,
    marker: left ? 'L' : 'R',
    onChanged: (offset) => widget.onStick(left ? 'leftStick' : 'rightStick', offset),
    onClick: (down) => widget.onButton(left ? 'leftStick' : 'rightStick', down),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 640;
      if (constraints.maxWidth < 360 || constraints.maxHeight < (wide ? 216 : 352)) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(t.games.touchResizeHint, textAlign: TextAlign.center),
              ),
            ),
          ),
        );
      }
      // Game controller geometry stays physical in RTL; menu/help flow remains
      // directional. Every discrete control has a 48-pixel touch target.
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned(
              left: 8,
              bottom: 8,
              child: wide
                  ? Row(
                      children: [
                        _cross(directions: true),
                        Column(
                          children: [
                            Row(children: [_button('leftBumper', 'LB'), _button('leftTrigger', 'LT')]),
                            _stick(true),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(children: [_button('leftBumper', 'LB'), _button('leftTrigger', 'LT')]),
                        _stick(true),
                        _cross(directions: true),
                      ],
                    ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: wide
                  ? Row(
                      children: [
                        Column(
                          children: [
                            Row(children: [_button('rightTrigger', 'RT'), _button('rightBumper', 'RB')]),
                            _stick(false),
                          ],
                        ),
                        _cross(directions: false),
                      ],
                    )
                  : Column(
                      children: [
                        Row(children: [_button('rightTrigger', 'RT'), _button('rightBumper', 'RB')]),
                        _cross(directions: false),
                        _stick(false),
                      ],
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _button('select', 'View', icon: Symbols.tab_rounded),
                  _button('start', 'Menu', icon: Symbols.menu_rounded),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _HeldButton extends StatefulWidget {
  const _HeldButton({super.key, required this.label, required this.child, required this.onChanged});
  final String label;
  final Widget child;
  final ValueChanged<bool> onChanged;
  @override
  State<_HeldButton> createState() => _HeldButtonState();
}

class _HeldButtonState extends State<_HeldButton> {
  final _pointers = <int>{};
  Timer? _pulse;
  bool _semanticPress = false, _down = false;
  void _update() {
    if (!mounted) return; // A captured pointer can finish after this overlay retires.
    final down = _pointers.isNotEmpty || _semanticPress;
    if (down == _down) return;
    setState(() => _down = down);
    widget.onChanged(down);
  }

  void _activate() {
    if (!mounted) return;
    _pulse?.cancel();
    _semanticPress = true;
    _update();
    _pulse = Timer(const Duration(milliseconds: 100), () {
      _semanticPress = false;
      _update();
    });
  }

  @override
  void dispose() {
    _pulse?.cancel();
    if (_down) widget.onChanged(false);
    _down = false;
    _pointers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.label,
      onTap: _activate,
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _pointers.add(event.pointer);
            _update();
          },
          onPointerUp: (event) {
            _pointers.remove(event.pointer);
            _update();
          },
          onPointerCancel: (event) {
            _pointers.remove(event.pointer);
            _update();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _down ? colors.primary : colors.surfaceContainerHighest,
              border: Border.all(color: _down ? colors.primary : colors.onSurfaceVariant),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: IconTheme.merge(
              data: IconThemeData(color: _down ? colors.onPrimary : colors.onSurface),
              child: DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: _down ? colors.onPrimary : colors.onSurface),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stick extends StatefulWidget {
  const _Stick({super.key, required this.label, required this.marker, required this.onChanged, required this.onClick});
  final String label, marker;
  final ValueChanged<Offset> onChanged;
  final ValueChanged<bool> onClick;
  @override
  State<_Stick> createState() => _StickState();
}

class _StickState extends State<_Stick> {
  int? _pointer;
  Offset _offset = Offset.zero;
  Timer? _clickTimer;
  void _click() {
    if (!mounted) return;
    _clickTimer?.cancel();
    widget.onClick(true);
    _clickTimer = Timer(const Duration(milliseconds: 100), () {
      _clickTimer = null;
      widget.onClick(false);
    });
  }

  void _move(Offset position) {
    var offset = (position - const Offset(44, 44)) / 32;
    if (offset.distance > 1) offset /= offset.distance;
    setState(() => _offset = offset);
    widget.onChanged(offset);
  }

  void _release() {
    _pointer = null;
    setState(() => _offset = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  void dispose() {
    if (_clickTimer != null) {
      _clickTimer!.cancel();
      widget.onClick(false);
    }
    if (_pointer != null) widget.onChanged(Offset.zero);
    _pointer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.label,
      onTap: _click,
      child: GestureDetector(
        onDoubleTap: _click,
        excludeFromSemantics: true,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (_pointer == null) {
              _pointer = event.pointer;
              _move(event.localPosition);
            }
          },
          onPointerMove: (event) {
            if (_pointer == event.pointer) _move(event.localPosition);
          },
          onPointerUp: (event) {
            if (_pointer == event.pointer) _release();
          },
          onPointerCancel: (event) {
            if (_pointer == event.pointer) _release();
          },
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceContainerHighest,
              border: Border.all(color: colors.outline),
            ),
            child: Center(
              child: Transform.translate(
                offset: _offset * 24,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary),
                  alignment: Alignment.center,
                  child: Text(widget.marker, style: TextStyle(color: colors.onPrimary)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
