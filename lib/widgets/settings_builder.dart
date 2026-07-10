import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../services/settings_service.dart';

/// Non-reactive one-shot read of [pref] from the singleton [SettingsService].
/// Use for callbacks and event handlers that need the current value but don't
/// need to rebuild on change. For reactive reads in build methods, prefer
/// [SettingValueBuilder] / [SettingsBuilder] so only the dependent subtree rebuilds.
extension SettingsContextRead on BuildContext {
  T settingsRead<T>(Pref<T> pref) => SettingsService.instance.read(pref);
  Future<void> settingsWrite<T>(Pref<T> pref, T value) => SettingsService.instance.write(pref, value);
}

/// Rebuild [builder] when any of [prefs] changes. Use when a widget's output
/// depends on multiple settings (conditional visibility, derived values).
/// Inside [builder], read with [SettingsService.read] directly — the rebuild
/// is already wired through.
///
/// Stateful so the merged listenable is created once, not per build: cards
/// rebuild this widget constantly and re-merging would unsubscribe/resubscribe
/// every pref listener each time.
class SettingsBuilder extends StatefulWidget {
  final List<Pref<Object?>> prefs;
  final WidgetBuilder builder;

  const SettingsBuilder({super.key, required this.prefs, required this.builder});

  @override
  State<SettingsBuilder> createState() => _SettingsBuilderState();
}

class _SettingsBuilderState extends State<SettingsBuilder> {
  late Listenable _merged = _merge();

  Listenable _merge() {
    final svc = SettingsService.instance;
    return Listenable.merge(widget.prefs.map(svc.listenableOf).toList(growable: false));
  }

  @override
  void didUpdateWidget(covariant SettingsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.prefs, oldWidget.prefs)) _merged = _merge();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _merged, builder: (context, _) => widget.builder(context));
  }
}

/// Single-pref wrapper around [ValueListenableBuilder] keyed by a [Pref].
/// Equivalent to `ValueListenableBuilder(valueListenable: svc.listenable(pref))`
/// but reads cleaner at call sites that don't already hold the service.
class SettingValueBuilder<T> extends StatelessWidget {
  final Pref<T> pref;
  final Widget Function(BuildContext, T value, Widget? child) builder;
  final Widget? child;

  const SettingValueBuilder({super.key, required this.pref, required this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: builder,
      child: child,
    );
  }
}
