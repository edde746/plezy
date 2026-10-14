import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../utils/dialogs.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../utils/watch_link.dart';
import 'dialog_action_button.dart';

/// Shows the watch link for [item], a Plex show or movie.
Future<void> showWatchLinkDialog(BuildContext context, MediaItem item) {
  return showScopedDialog<void>(
    context: context,
    builder: (_) => WatchLinkDialog(item: item),
  );
}

/// The base watch link for [item] as a QR code and as text, so it can be
/// written to an NFC tag or pasted into a home automation. Copy is offered
/// wherever there is a clipboard; tvOS has none.
class WatchLinkDialog extends StatelessWidget {
  final MediaItem item;

  const WatchLinkDialog({super.key, required this.item});

  Future<void> _copy(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    showAppSnackBar(context, t.watchLink.copied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = WatchLink.forItem(item)!.toLink();
    final canCopy = !PlatformDetector.isAppleTV();
    final screen = MediaQuery.sizeOf(context);
    // QR on top, link and hint under it. Wide screens (TV, desktop) get a
    // fixed width so the link fits on one line; portrait phones wrap it.
    // QR sizing matches PendingAuthDialog.
    final wide = screen.width >= 600;
    final qrSize = wide ? (screen.height * 0.45).clamp(160.0, 220.0) : (screen.width - 160).clamp(140.0, 200.0);
    final linkStyle = theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace');

    final content = Column(
      mainAxisSize: .min,
      children: [
        SizedBox.square(
          dimension: qrSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: QrImageView(data: link, size: qrSize, version: QrVersions.auto, backgroundColor: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        if (wide)
          // Scale down rather than wrap, which would strand a few characters.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(link, maxLines: 1, style: linkStyle),
          )
        else
          Text(link, style: linkStyle, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          item.kind == MediaKind.show ? t.watchLink.dialogShowHint : t.watchLink.dialogMovieHint,
          textAlign: TextAlign.center,
        ),
      ],
    );
    return AlertDialog(
      scrollable: true,
      title: Text(t.watchLink.dialogTitle),
      content: wide ? SizedBox(width: 560, child: content) : content,
      actions: [
        if (canCopy) DialogActionButton(onPressed: () => _copy(context, link), label: t.watchLink.copy),
        DialogActionButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          label: t.common.close,
          isPrimary: true,
        ),
      ],
    );
  }
}
