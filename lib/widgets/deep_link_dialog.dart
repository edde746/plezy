import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../services/deep_links/deep_link.dart';
import '../services/deep_links/item_links.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import 'dialog_action_button.dart';
import 'focusable_list_tile.dart';

/// Shows the link that plays [item], which [canLinkItem] must accept.
Future<void> showItemLinkDialog(BuildContext context, MediaItem item) {
  final client = context.tryGetMediaClientForServer(serverIdOrNull(item.serverId));
  final profiles = Provider.of<ActiveProfileProvider?>(context, listen: false);
  final profile = profiles != null && profiles.hasMultipleProfiles ? profiles.active : null;
  return showScopedDialog<void>(
    context: context,
    builder: (_) => ItemLinkDialog(item: item, client: client, profile: profile),
  );
}

/// Shows the link that switches to [profile].
Future<void> showProfileLinkDialog(BuildContext context, Profile profile) {
  return showScopedDialog<void>(
    context: context,
    builder: (_) => ProfileLinkDialog(profile: profile),
  );
}

/// The link that plays [item]. The catalogue lookup behind [linkForItem]
/// runs while the dialog is open; when it fails the dialog shows the link to
/// the item on its server instead.
class ItemLinkDialog extends StatefulWidget {
  ItemLinkDialog({super.key, required this.item, required this.client, this.profile}) : assert(canLinkItem(item));

  final MediaItem item;

  /// The client for the item's server, or null when none is registered.
  final MediaServerClient? client;

  /// Offered as "open as" when non-null: the link then names this profile.
  final Profile? profile;

  @override
  State<ItemLinkDialog> createState() => _ItemLinkDialogState();
}

class _ItemLinkDialogState extends State<ItemLinkDialog> {
  late final PlayLink _serverLink = serverItemLink(widget.item)!;

  /// Null while resolving.
  PlayLink? _link;
  bool _asProfile = false;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    if (client == null) {
      _link = _serverLink;
    } else {
      unawaited(_resolve(client));
    }
  }

  Future<void> _resolve(MediaServerClient client) async {
    PlayLink? link;
    try {
      link = await linkForItem(client, widget.item);
    } catch (e, stackTrace) {
      appLogger.w('Item link: resolving ${widget.item.id} failed', error: e, stackTrace: stackTrace);
    }
    if (!mounted) return;
    setState(() => _link = link ?? _serverLink);
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    final profile = widget.profile;
    final shown = link != null && profile != null && _asProfile
        ? PlayLink(target: link.target, mode: link.mode, profile: linkProfileRef(profile))
        : link;
    return _LinkDialog(
      link: shown?.toUri().toString(),
      hint: switch (widget.item.kind) {
        MediaKind.show => t.deepLinks.showHint,
        MediaKind.episode => t.deepLinks.episodeHint,
        _ => t.deepLinks.movieHint,
      },
      option: profile == null
          ? null
          : FocusableSwitchListTile(
              value: _asProfile,
              onChanged: (value) => setState(() => _asProfile = value),
              title: Text(t.deepLinks.openAsProfile(name: profile.displayName)),
              contentPadding: EdgeInsets.zero,
            ),
    );
  }
}

/// The link that brings the app forward as [profile].
class ProfileLinkDialog extends StatelessWidget {
  const ProfileLinkDialog({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return _LinkDialog(
      link: OpenLink(profile: linkProfileRef(profile)).toUri().toString(),
      hint: t.deepLinks.profileHint,
    );
  }
}

/// A link as a QR code and as text, so it can be scanned, written to an NFC
/// tag or pasted into a home automation. Copy is offered wherever there is a
/// clipboard; tvOS has none.
class _LinkDialog extends StatelessWidget {
  const _LinkDialog({required this.link, required this.hint, this.option});

  /// Null while the link is resolving.
  final String? link;
  final String hint;

  /// A control under the hint that changes the link.
  final Widget? option;

  Future<void> _copy(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    showAppSnackBar(context, t.deepLinks.copied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = this.link;
    final option = this.option;
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
        // The placeholder holds the QR code's place so the dialog keeps its
        // size when the link arrives.
        SizedBox.square(
          dimension: qrSize,
          child: link == null
              ? const Center(child: CircularProgressIndicator())
              : ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: QrImageView(data: link, size: qrSize, version: QrVersions.auto, backgroundColor: Colors.white),
                ),
        ),
        const SizedBox(height: 20),
        if (wide)
          // One line whatever the link: the hidden line fixes the height and
          // the link scales down inside it rather than wrap, which would
          // strand a few characters.
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Text(' ', style: linkStyle),
                ),
                if (link != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(link, maxLines: 1, style: linkStyle),
                    ),
                  ),
              ],
            ),
          )
        else if (link != null)
          Text(link, style: linkStyle, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(hint, textAlign: TextAlign.center),
        if (option != null) ...[const SizedBox(height: 12), option],
      ],
    );
    return AlertDialog(
      scrollable: true,
      title: Text(t.deepLinks.dialogTitle),
      content: wide ? SizedBox(width: 560, child: content) : content,
      actions: [
        if (!PlatformDetector.isAppleTV())
          DialogActionButton(onPressed: link == null ? null : () => _copy(context, link), label: t.deepLinks.copy),
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
