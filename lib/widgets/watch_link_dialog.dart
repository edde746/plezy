import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../providers/multi_server_provider.dart';
import '../utils/dialogs.dart';
import '../utils/external_ids.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../utils/watch_link.dart';
import 'dialog_action_button.dart';

/// Shows a portable watch link for [item], falling back to a server link when
/// the server has no catalog ids.
Future<void> showWatchLinkDialog(BuildContext context, MediaItem item) async {
  ExternalIds? externalIds;
  if (item.backend != MediaBackend.plex) {
    final serverId = serverIdOrNull(item.serverId);
    final client = serverId == null ? null : context.read<MultiServerProvider>().getClientForServer(serverId);
    if (client != null) {
      try {
        externalIds = await client.fetchExternalIds(item.id);
      } catch (_) {
        // A server-specific link remains useful when the external-id lookup
        // is unavailable.
      }
    }
  }
  if (!context.mounted) return;
  return showScopedDialog<void>(
    context: context,
    builder: (_) => WatchLinkDialog(item: item, externalIds: externalIds),
  );
}

/// The base watch link for [item] as a QR code and as text, so it can be
/// written to an NFC tag or pasted into a home automation. Copy is offered
/// wherever there is a clipboard; tvOS has none.
class WatchLinkDialog extends StatelessWidget {
  final MediaItem item;
  final ExternalIds? externalIds;

  const WatchLinkDialog({super.key, required this.item, this.externalIds});

  Future<void> _copy(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    showAppSnackBar(context, t.watchLink.copied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchLink =
        WatchLink.forItem(item, externalIds: externalIds) ??
        ServerWatchLink(ratingKey: item.id, serverId: serverIdOrNull(item.serverId));
    final link = watchLink.toLink();
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
