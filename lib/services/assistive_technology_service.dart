import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/app_logger.dart';
import '../utils/semantics_tree_gate.dart';

/// Decides whether the semantics tree is worth compiling while Android has
/// accessibility switched on.
///
/// Android enables Flutter semantics for any bound accessibility service, and
/// on TV that is often a utility that never reads app content (the Projectivy
/// Launcher service, key remappers). The platform side reports whether an
/// enabled service can actually consume the tree; when none can, the
/// [SemanticsTreeGate] on the app binding is closed and the per-frame semantics
/// pass disappears. The gate stays open — the safe direction — until the first
/// answer arrives, whenever the enabled-service list is empty (UiAutomation,
/// which drives Maestro, is invisible in that list), and on every other
/// platform, where semantics only ever means a screen reader.
///
/// Re-evaluated when the platform toggles semantics, when Android reports a
/// change in enabled services (API 33+, pushed by the native side) and on every
/// resume, which is when a service enabled from Settings first affects the app
/// on older releases.
class AssistiveTechnologyService with WidgetsBindingObserver {
  AssistiveTechnologyService._();

  static final AssistiveTechnologyService instance = AssistiveTechnologyService._();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel('com.plezy/assistive_technology');

  bool _started = false;
  Future<void>? _inFlight;
  bool _refreshQueued = false;

  /// Begins observing. Idempotent; a no-op off Android and under a binding
  /// without the gate (tests, or a fresh binding subclass).
  void ensureStarted() {
    if (_started || defaultTargetPlatform != TargetPlatform.android) return;
    final binding = WidgetsBinding.instance;
    if (binding is! SemanticsTreeGate) return;
    final gate = binding as SemanticsTreeGate;
    _started = true;
    channel.setMethodCallHandler(_handlePlatformCall);
    gate.addPlatformSemanticsListener(_refresh);
    binding.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'onChanged') _refresh();
    return null;
  }

  /// Coalesces concurrent triggers into one query, and one follow-up when a
  /// trigger lands mid-flight so a stale answer never wins.
  void _refresh() {
    if (_inFlight != null) {
      _refreshQueued = true;
      return;
    }
    _inFlight = _evaluate().whenComplete(() {
      _inFlight = null;
      if (_refreshQueued) {
        _refreshQueued = false;
        _refresh();
      }
    });
  }

  Future<void> _evaluate() async {
    final gate = WidgetsBinding.instance as SemanticsTreeGate;
    if (!gate.platformSemanticsRequested) {
      // Nothing to gate; reset so the next request starts from the safe side.
      gate.semanticsTreeWanted = true;
      return;
    }
    bool wanted = true;
    try {
      final signals = await channel.invokeMapMethod<String, dynamic>('getSignals');
      wanted = signals?['consumesSemantics'] != false;
    } on MissingPluginException {
      // Stale native build: keep the tree.
    } on PlatformException catch (error, stackTrace) {
      appLogger.w('Assistive technology query failed, keeping semantics', error: error, stackTrace: stackTrace);
    }
    if (gate.semanticsTreeWanted != wanted) {
      appLogger.i(wanted ? 'Semantics tree enabled for an assistive technology' : 'Semantics tree gated off');
    }
    gate.semanticsTreeWanted = wanted;
  }

  @visibleForTesting
  void debugReset() {
    if (_started) {
      final binding = WidgetsBinding.instance;
      if (binding is SemanticsTreeGate) {
        final gate = binding as SemanticsTreeGate;
        gate.removePlatformSemanticsListener(_refresh);
        gate.semanticsTreeWanted = true;
      }
      binding.removeObserver(this);
      channel.setMethodCallHandler(null);
    }
    _started = false;
    _inFlight = null;
    _refreshQueued = false;
  }
}
