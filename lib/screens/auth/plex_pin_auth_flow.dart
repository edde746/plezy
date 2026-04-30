import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../services/plex_auth_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';

/// Self-contained Plex PIN/QR auth flow.
///
/// Renders the polling UI (QR code or browser-waiting spinner) once an
/// auth attempt is started via [PlexPinAuthFlowController.startBrowser] /
/// [PlexPinAuthFlowController.startQr]. When polling resolves successfully
/// it invokes [onTokenReceived(token)]; the parent decides what to do next
/// (the legacy [AuthScreen] connects to all servers + navigates to
/// MainScreen, while [AddPlexAccountScreen] pops with success or routes
/// into the borrow flow).
///
/// Both screens previously implemented this flow inline — same `PlexAuthService`
/// orchestration, same QR widget, same browser-waiting state. Extracting
/// here removes ~300 lines of duplicate UI code and centralises the
/// poll-cancel-retry plumbing.
class PlexPinAuthFlow extends StatefulWidget {
  /// Fires when the user successfully claims the PIN. The token is the raw
  /// `X-Plex-Token` value — parent code is responsible for exchanging it
  /// for a [PlexAccountConnection] (account label + servers list).
  final Future<void> Function(String token) onTokenReceived;

  /// QR size on mobile / narrow layouts.
  final double mobileQrSize;

  /// QR size on desktop / wide layouts (where the auth screen has more
  /// horizontal room). The two-column login screen uses 300; the bottom-sheet
  /// add-account screen uses 200.
  final double desktopQrSize;

  /// When `true` and running on TV, auto-start the QR flow on first build so
  /// the user doesn't have to navigate to the QR button with the remote.
  final bool autoStartQrOnTV;

  /// Override the QR-vs-browser default before any user interaction. Useful
  /// for callers that want to force one mode (the add-account screen
  /// auto-starts QR on TV; the legacy login screen offers both).
  final bool? initialUseQr;

  /// Optional builder for the initial action buttons. The default (`null`)
  /// shows two buttons — "Sign in with Plex" (browser) and "Show QR Code".
  /// Pass a custom builder when the parent wants to integrate the buttons
  /// into a richer layout (extra Jellyfin button, debug button, branding).
  final Widget Function(BuildContext context, VoidCallback startBrowser, VoidCallback startQr, bool busy)?
  initialButtonsBuilder;

  const PlexPinAuthFlow({
    super.key,
    required this.onTokenReceived,
    this.mobileQrSize = 200,
    this.desktopQrSize = 300,
    this.autoStartQrOnTV = true,
    this.initialUseQr,
    this.initialButtonsBuilder,
  });

  @override
  State<PlexPinAuthFlow> createState() => _PlexPinAuthFlowState();
}

class _PlexPinAuthFlowState extends State<PlexPinAuthFlow> {
  PlexAuthService? _authService;
  bool _isPolling = false;
  bool _useQr = false;
  String? _qrAuthUrl;
  int _attemptId = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _useQr = widget.initialUseQr ?? PlatformDetector.isTV();
    unawaited(_initService());
  }

  Future<void> _initService() async {
    final svc = await PlexAuthService.create();
    if (!mounted) {
      svc.dispose();
      return;
    }
    setState(() {
      _authService = svc;
    });
    if (widget.autoStartQrOnTV && PlatformDetector.isTV()) {
      unawaited(_start(useQr: true));
    }
  }

  @override
  void dispose() {
    _attemptId++;
    _authService?.dispose();
    super.dispose();
  }

  Future<void> _start({required bool useQr}) async {
    final svc = _authService;
    if (svc == null) return;
    final attemptId = ++_attemptId;
    setState(() {
      _useQr = useQr;
      _isPolling = true;
      _errorMessage = null;
      _qrAuthUrl = null;
    });

    try {
      final pinData = await svc.createPin();
      if (!_isCurrentAttempt(attemptId)) return;
      final pinId = pinData['id'] as int;
      final pinCode = pinData['code'] as String;
      final url = svc.getAuthUrl(pinCode);

      if (!_isCurrentAttempt(attemptId)) return;
      if (useQr) {
        setState(() => _qrAuthUrl = url);
      } else {
        final uri = Uri.parse(url);
        try {
          final mode = PlatformDetector.isTV() ? LaunchMode.inAppWebView : LaunchMode.inAppBrowserView;
          await launchUrl(uri, mode: mode);
        } catch (_) {
          // Chrome Custom Tabs may not be available — fall back to default
          // external browser.
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      final token = await svc.pollPinUntilClaimed(pinId, shouldCancel: () => attemptId != _attemptId);
      if (!_isCurrentAttempt(attemptId)) return;

      if (token == null) {
        setState(() {
          _isPolling = false;
          _qrAuthUrl = null;
          _errorMessage = t.auth.authenticationTimeout;
        });
        return;
      }

      // Auto-close the in-app browser on mobile (no-op on desktop / when
      // already closed).
      if (!useQr) {
        try {
          await closeInAppWebView();
        } catch (_) {}
      }

      if (!_isCurrentAttempt(attemptId)) return;
      setState(() {
        _qrAuthUrl = null;
      });
      await widget.onTokenReceived(token);
      if (!_isCurrentAttempt(attemptId)) return;
      setState(() {
        _isPolling = false;
      });
    } catch (e) {
      appLogger.w('Plex PIN auth failed', error: e);
      if (!_isCurrentAttempt(attemptId)) return;
      setState(() {
        _isPolling = false;
        _qrAuthUrl = null;
        _errorMessage = e.toString();
      });
    }
  }

  bool _isCurrentAttempt(int attemptId) => mounted && attemptId == _attemptId;

  void _retry() {
    final useQr = _useQr;
    _attemptId++;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) unawaited(_start(useQr: useQr));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isPolling) {
      final isDesktop = MediaQuery.sizeOf(context).width > 700;
      if (_useQr && _qrAuthUrl != null) {
        return _buildQr(theme, isDesktop ? widget.desktopQrSize : widget.mobileQrSize);
      }
      return _buildBrowserWaiting(theme);
    }

    final builder = widget.initialButtonsBuilder ?? _defaultInitialButtons;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        builder(context, () => _start(useQr: false), () => _start(useQr: true), _authService == null),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _defaultInitialButtons(BuildContext context, VoidCallback browser, VoidCallback qr, bool busy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(onPressed: busy ? null : browser, child: Text(t.auth.signInWithPlex)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: busy ? null : qr, child: Text(t.auth.showQRCode)),
      ],
    );
  }

  Widget _buildQr(ThemeData theme, double qrSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.auth.scanQRToSignIn,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens(context).radiusMd),
            child: QrImageView(
              data: _qrAuthUrl!,
              size: qrSize,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _retry,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
          child: Text(t.common.retry),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildBrowserWaiting(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Text(
          t.auth.waitingForAuth,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _retry,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
          child: Text(t.common.retry),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
