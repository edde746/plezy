import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_button.dart';
import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';
import 'loading_indicator_box.dart';

/// Shell for the "waiting for out-of-band authorization" dialogs.
///
/// Every flow gets the same affordances: a QR code for [url], a readable
/// copyable URL underneath it, the service-specific [children], a button that
/// launches [url] in the browser (hidden on Apple TV, which has none), and a
/// "waiting for authorization…" spinner while the poll loop runs.
///
/// On wide viewports (TV, desktop, phone landscape) the QR pane sits beside
/// the instructions so the dialog stays short enough for TV screens — tvOS
/// renders at 540 logical pixels of height, where the stacked layout clips.
/// Dismissing calls [onCancel] so the provider can abort the poll.
class PendingAuthDialog extends StatelessWidget {
  final String title;
  final String body;

  /// Sits between the body text and the launch button, and carries its own
  /// trailing spacing.
  final List<Widget> children;

  /// Encoded in the QR code, opened by the browser button, and copied by the
  /// URL tap region.
  final String url;

  /// Short human-readable form of [url] shown under the QR code. Defaults to
  /// [url]; the scheme is stripped for display either way.
  final String? displayUrl;
  final String openLabel;
  final VoidCallback onCancel;

  const PendingAuthDialog({
    super.key,
    required this.title,
    required this.body,
    required this.children,
    required this.url,
    this.displayUrl,
    required this.openLabel,
    required this.onCancel,
  });

  Future<void> _open() async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    showAppSnackBar(context, t.services.pendingAuth.urlCopied);
  }

  String get _urlDisplayText {
    var text = displayUrl ?? url;
    text = text.replaceFirst(RegExp('^https?://'), '');
    while (text.endsWith('/')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    // Side-by-side on anything wide enough (TV, desktop, phone landscape);
    // stacked on portrait phones.
    final wide = screen.width >= 600;
    final qrSize = wide ? (screen.height * 0.45).clamp(160.0, 220.0) : (screen.width - 160).clamp(140.0, 200.0);

    final qr = SizedBox.square(
      dimension: qrSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: QrImageView(data: url, size: qrSize, version: QrVersions.auto, backgroundColor: Colors.white),
      ),
    );
    Widget urlChip({required TextAlign textAlign}) => CopyTapRegion(
      onCopy: () => _copyUrl(context),
      semanticLabel: t.services.pendingAuth.copyUrl,
      semanticValue: url,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          _urlDisplayText,
          style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace', fontWeight: .w600),
          textAlign: textAlign,
        ),
      ),
    );

    final bodyText = Text(body, style: theme.textTheme.bodyMedium);
    // tvOS has no browser, so a launch button would be a dead focus target.
    final openButton = PlatformDetector.isAppleTV()
        ? null
        : SizedBox(
            width: double.infinity,
            child: FocusableButton(
              onPressed: _open,
              useBackgroundFocus: true,
              child: FilledButton.icon(
                icon: const AppIcon(Symbols.open_in_new_rounded),
                label: Text(openLabel),
                onPressed: _open,
              ),
            ),
          );
    final waitingRow = Row(
      children: [
        const LoadingIndicatorBox(size: 16),
        const SizedBox(width: 12),
        Expanded(child: Text(t.services.deviceCode.waitingForAuthorization, style: theme.textTheme.bodySmall)),
      ],
    );

    return AlertDialog(
      scrollable: true,
      title: Text(title),
      // Wide: the QR fills the left pane and everything textual lives in the
      // right column — body at the QR's top edge, button/spinner at its bottom
      // edge, the URL above the button, and any service extras (activation
      // code) centered in the remaining space. Both flows fill their column,
      // so neither pane floats in empty space.
      content: wide
          ? IntrinsicHeight(
              child: Row(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  Column(mainAxisSize: .min, mainAxisAlignment: .center, children: [qr]),
                  const SizedBox(width: 28),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      crossAxisAlignment: .stretch,
                      children: [
                        bodyText,
                        Expanded(
                          child: children.isEmpty
                              ? const SizedBox.shrink()
                              : Column(mainAxisAlignment: .center, children: children),
                        ),
                        Align(
                          alignment: .centerLeft,
                          child: urlChip(textAlign: TextAlign.start),
                        ),
                        const SizedBox(height: 12),
                        if (openButton != null) ...[openButton, const SizedBox(height: 16)],
                        waitingRow,
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                bodyText,
                const SizedBox(height: 16),
                ...children,
                Center(
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      qr,
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: qrSize + 32),
                        child: urlChip(textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (openButton != null) ...[openButton, const SizedBox(height: 16)],
                waitingRow,
              ],
            ),
      actions: [
        DialogActionButton(
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
          label: t.common.cancel,
        ),
      ],
    );
  }
}

/// Tap/D-pad target that copies the value it displays to the clipboard.
class CopyTapRegion extends StatelessWidget {
  final VoidCallback onCopy;
  final String semanticLabel;

  /// Announced after [semanticLabel] so screen readers read out the value that
  /// will be copied instead of just the action.
  final String? semanticValue;
  final Widget child;

  const CopyTapRegion({
    super.key,
    required this.onCopy,
    required this.semanticLabel,
    this.semanticValue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      onSelect: onCopy,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      descendantsAreFocusable: false,
      useBackgroundFocus: true,
      borderRadius: 8,
      child: InkWell(canRequestFocus: false, onTap: onCopy, borderRadius: BorderRadius.circular(8), child: child),
    );
  }
}
