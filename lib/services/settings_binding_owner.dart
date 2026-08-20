import 'package:flutter/foundation.dart';

import 'settings_service.dart';

typedef SettingsServiceAcquirer = Future<SettingsService> Function();

/// Owns a group of preference listeners backed by one [SettingsService].
class SettingsBindingOwner {
  factory SettingsBindingOwner({
    required Iterable<Pref<Object?>> prefs,
    required void Function(SettingsService service) onRefresh,
    SettingsServiceAcquirer? acquireSettings,
  }) => SettingsBindingOwner._(List.unmodifiable(prefs), onRefresh, acquireSettings);

  SettingsBindingOwner._(this._prefs, this._onRefresh, this._acquireSettings);

  final List<Pref<Object?>> _prefs;
  final void Function(SettingsService service) _onRefresh;
  final SettingsServiceAcquirer? _acquireSettings;
  final List<Listenable> _listenables = [];

  SettingsService? _settings;
  Future<void>? _bindingFuture;
  int _generation = 0;
  bool _disposed = false;

  SettingsService? get settings => _settings;
  bool get isBound => !_disposed && _settings != null;

  Future<void> bind() {
    if (_disposed) return Future.value();

    final pending = _bindingFuture;
    if (pending != null) return pending;

    final generation = ++_generation;
    late final Future<void> future;
    future = _bind(generation).whenComplete(() {
      if (identical(_bindingFuture, future)) _bindingFuture = null;
    });
    _bindingFuture = future;
    return future;
  }

  Future<void> _bind(int generation) async {
    final acquirer = _acquireSettings;
    final service = await (acquirer?.call() ?? SettingsService.getInstance());
    if (_disposed || generation != _generation) return;

    if (!identical(_settings, service)) {
      _removeListeners();
      _settings = service;
      for (final pref in _prefs) {
        final listenable = service.listenableOf(pref)..addListener(_handlePreferenceChanged);
        _listenables.add(listenable);
      }
    }

    _onRefresh(service);
  }

  void refresh() {
    final service = _settings;
    if (_disposed || service == null) return;
    _onRefresh(service);
  }

  void _handlePreferenceChanged() {
    final service = _settings;
    if (_disposed || service == null) return;
    _onRefresh(service);
  }

  void _removeListeners() {
    for (final listenable in _listenables) {
      listenable.removeListener(_handlePreferenceChanged);
    }
    _listenables.clear();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _removeListeners();
  }
}
