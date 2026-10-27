import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../i18n/strings.g.dart';
import '../../profiles/profile.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../external_player_service.dart';
import 'deep_link.dart';

/// Switches profiles for links. Lives at the root of the widget tree, which
/// outlives the profile session a switch replaces.
abstract interface class DeepLinkProfileHost {
  List<Profile> get profiles;

  String? get activeProfileId;

  /// Activates [profile], asking for its PIN when it is protected. Returns
  /// whether [profile] is now active; false when the viewer backed out or
  /// the switch failed (which the switch reports itself).
  Future<bool> switchTo(Profile profile);
}

/// A profile session that acts on links: the main screen of [profileId].
class DeepLinkSession {
  DeepLinkSession({required this.profileId, required this.launch});

  final String? profileId;
  final Future<void> Function(DeepLink link) launch;
}

/// Receives `plezy://` links from the platform and hands each to its owner.
///
/// The native side (Android `DeepLinkPlugin`, the shared Apple
/// `DeepLinkPlugin`) keeps a link until this service accepts it, so a link
/// that launched the app waits for [fetchInitialLink].
///
/// One link is pending at a time; a newer link replaces it. A link that
/// names a profile is applied first: at startup by SetupScreen, which
/// activates that profile instead of binding the previous one
/// ([claimStartupProfile]), and later by the [host]. Only then does the
/// attached [DeepLinkSession] of that profile get the link.
class DeepLinkService {
  DeepLinkService._(this._channel, this._platformDelivers)
    : _report = showMainSnackBar,
      _handleExternalPlayerReturn = ExternalPlayerService.handleCallbackUrl {
    if (_platformDelivers) _channel.setMethodCallHandler(_handleMethodCall);
  }

  @visibleForTesting
  DeepLinkService.forTesting(
    this._channel, {
    void Function(String message)? report,
    Future<bool> Function(Uri uri)? handleExternalPlayerReturn,
  }) : _platformDelivers = true,
       _report = report ?? ((_) {}),
       _handleExternalPlayerReturn = handleExternalPlayerReturn ?? ((_) async => false) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static final DeepLinkService instance = DeepLinkService._(
    const MethodChannel('com.plezy/deep_link'),
    // Windows and Linux register no URL scheme yet.
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS,
  );

  final MethodChannel _channel;
  final bool _platformDelivers;
  final void Function(String message) _report;
  final Future<bool> Function(Uri uri) _handleExternalPlayerReturn;

  /// Applies a link's profile once startup is over. Installed by the app root.
  DeepLinkProfileHost? host;

  _PendingLink? _pending;
  _PendingLink? _startupClaim;
  Profile? _startupProfile;
  DeepLinkSession? _session;
  bool _switching = false;
  Future<void>? _initialFetch;
  String? _lastUrl;
  final Stopwatch _sinceLastUrl = Stopwatch();

  /// Whether a link is about to choose the profile: the resume-time profile
  /// picker must not ask over it.
  bool get selectsProfile => _switching || (_pending?.awaitsProfile ?? false);

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onLink') throw MissingPluginException('${call.method} is not a deep link method');
    final args = call.arguments;
    final url = args is Map ? args['url'] : null;
    if (url is! String) return false;
    receive(url);
    return true;
  }

  /// Reads the link that launched the app, once.
  Future<void> fetchInitialLink() => _initialFetch ??= _fetchInitialLink();

  Future<void> _fetchInitialLink() async {
    if (!_platformDelivers) return;
    try {
      final url = await _channel.invokeMethod<String>('getInitialLink');
      if (url != null) receive(url);
    } on MissingPluginException {
      // Not registered on this platform build.
    } catch (e, stackTrace) {
      appLogger.w('Deep link: reading the launch link failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Accepts [url] from any source.
  void receive(String url) {
    // A link the platform sent while Dart was starting can arrive twice:
    // replayed on the channel and again as the launch link.
    if (url == _lastUrl && _sinceLastUrl.elapsed < duplicateWindow) return;
    _lastUrl = url;
    _sinceLastUrl
      ..reset()
      ..start();

    final link = DeepLink.tryParse(url);
    if (link == null) {
      appLogger.w('Deep link: not a valid Plezy link (host "${Uri.tryParse(url)?.host}")');
      _report(t.deepLinks.invalid);
      return;
    }
    appLogger.i('Deep link: ${link.runtimeType}');
    if (link is ExternalPlayerReturnLink) {
      unawaited(_returnFromExternalPlayer(link));
      return;
    }
    _pending = _PendingLink(link);
    _pump();
  }

  /// How long an identical URL counts as the same delivery.
  static const duplicateWindow = Duration(seconds: 2);

  Future<void> _returnFromExternalPlayer(ExternalPlayerReturnLink link) async {
    try {
      await _handleExternalPlayerReturn(link.uri);
    } catch (e, stackTrace) {
      appLogger.w('Deep link: external player return failed', error: e, stackTrace: stackTrace);
    }
  }

  /// For SetupScreen, before the first bind: the profile the pending link
  /// names. Startup activates it in place of the previously active profile
  /// and the profile picker, then answers with [settleStartupProfile]. Null
  /// when the link names no profile, or none that matches (reported once a
  /// session is up).
  Profile? claimStartupProfile(List<Profile> profiles) {
    final pending = _pending;
    final ref = pending?.link.profile;
    if (pending == null || ref == null || !pending.awaitsProfile) return null;
    final profile = resolveLinkProfile(profiles, ref);
    if (profile == null) return null;
    _startupClaim = pending;
    _startupProfile = profile;
    return profile;
  }

  /// The profile claimed by [claimStartupProfile] until it is settled: the
  /// first bind binds this profile only.
  String? get startupProfileId => _startupProfile?.id;

  /// Startup made the claimed profile active ([applied]), or could not
  /// (the viewer backed out of its PIN), which drops the link.
  void settleStartupProfile({required bool applied}) {
    final claim = _startupClaim;
    _startupClaim = null;
    _startupProfile = null;
    if (claim == null || !identical(_pending, claim)) return;
    if (applied) {
      claim.awaitsProfile = false;
    } else {
      _pending = null;
    }
    _pump();
  }

  /// Attaches the session that acts on links until [detach]. Delivers a
  /// pending link for its profile, and reads the launch link if startup did
  /// not (a first sign-in reaches the session without SetupScreen's bind).
  void attach(DeepLinkSession session) {
    _session = session;
    unawaited(fetchInitialLink());
    _pump();
  }

  void detach(DeepLinkSession session) {
    if (identical(_session, session)) _session = null;
  }

  void _pump() {
    final pending = _pending;
    final session = _session;
    final host = this.host;
    if (pending == null || session == null || host == null || _switching) return;

    if (pending.awaitsProfile) {
      final ref = pending.link.profile!;
      final profile = resolveLinkProfile(host.profiles, ref);
      if (profile == null) {
        _pending = null;
        _report(t.deepLinks.profileNotFound(profile: ref));
        return;
      }
      if (profile.id != host.activeProfileId) {
        unawaited(_switchFor(pending, profile, host));
        return;
      }
      pending.awaitsProfile = false;
    }

    // A session about to be replaced by a profile switch must not act.
    if (session.profileId != host.activeProfileId) return;
    _pending = null;
    unawaited(_launch(session, pending.link));
  }

  Future<void> _switchFor(_PendingLink pending, Profile profile, DeepLinkProfileHost host) async {
    _switching = true;
    var switched = false;
    try {
      switched = await host.switchTo(profile);
    } catch (e, stackTrace) {
      appLogger.w('Deep link: switching to ${profile.id} failed', error: e, stackTrace: stackTrace);
    } finally {
      _switching = false;
    }
    if (identical(_pending, pending)) {
      if (switched) {
        pending.awaitsProfile = false;
      } else {
        _pending = null;
      }
    }
    // A newer link that arrived meanwhile runs now.
    _pump();
  }

  Future<void> _launch(DeepLinkSession session, DeepLink link) async {
    try {
      await session.launch(link);
    } catch (e, stackTrace) {
      appLogger.e('Deep link: launching ${link.runtimeType} failed', error: e, stackTrace: stackTrace);
    }
  }
}

class _PendingLink {
  _PendingLink(this.link) : awaitsProfile = link.profile != null;

  final DeepLink link;

  /// The link names a profile that is not applied yet.
  bool awaitsProfile;
}
