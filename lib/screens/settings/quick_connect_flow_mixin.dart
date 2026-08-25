import 'package:flutter/widgets.dart';

import 'async_form_state_mixin.dart';

/// Attempt bookkeeping for a Quick Connect code flow, shared by the screens
/// that host `QuickConnectCodePanel`: the MediaBrowser add-server form and the
/// Seerr connect form.
///
/// The poll behind the panel runs for minutes. Nothing may cancel it directly,
/// so cancellation is expressed as an attempt id: [beginQuickConnectAttempt]
/// mints one, [quickConnectAborted] is handed to the service as its
/// `shouldCancel`, and [isCurrentQuickConnectAttempt] guards every state write
/// after an await — including `runAsync`'s `shouldApplyState`, so a dismissed
/// attempt can neither clear busy nor show an error belonging to the attempt
/// that replaced it.
mixin QuickConnectFlowMixin<T extends StatefulWidget> on AsyncFormStateMixin<T> {
  String? _code;
  bool _cancelled = false;
  int _attemptId = 0;

  /// Code currently on screen, or null when the panel is not showing.
  String? get quickConnectCode => _code;

  /// Whether the visible attempt was dismissed by the user. Distinguishes a
  /// silent cancel from an expiry worth an error message.
  bool get quickConnectCancelled => _cancelled;

  /// Starts an attempt, invalidating any earlier one. Returns its id.
  int beginQuickConnectAttempt() {
    _cancelled = false;
    return ++_attemptId;
  }

  /// Whether [attemptId] is still the live attempt on a mounted screen.
  bool isCurrentQuickConnectAttempt(int attemptId) => mounted && attemptId == _attemptId;

  /// `shouldCancel` for the polling service call: true once the attempt was
  /// dismissed or superseded.
  bool quickConnectAborted(int attemptId) => _cancelled || attemptId != _attemptId;

  void showQuickConnectCode(String code) {
    if (mounted) setState(() => _code = code);
  }

  void hideQuickConnectCode() {
    if (mounted) setState(() => _code = null);
  }

  /// User dismissed the panel: the in-flight poll unwinds silently and the
  /// form comes back without an error.
  void cancelQuickConnect() {
    _attemptId++;
    setState(() {
      _cancelled = true;
      _code = null;
    });
    setBusy(false);
  }

  /// Call from `dispose`: short-circuits the in-flight poll so it cannot try to
  /// setState after the screen is gone.
  void endQuickConnectFlow() {
    _cancelled = true;
    _attemptId++;
  }
}
