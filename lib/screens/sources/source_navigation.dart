import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../services/remote_streams/remote_stream_models.dart';
import '../../services/remote_streams/remote_streaming_provider.dart';
import '../../sources/publication_shelf.dart';
import '../../sources/source_controller.dart';
import '../../widgets/app_menu.dart';

String shelfLabel(PublicationShelf shelf) => switch (shelf) {
  PublicationShelf.ebooks => t.fileSources.ebooks,
  PublicationShelf.audiobooks => t.fileSources.audiobooks,
  PublicationShelf.comics => t.fileSources.comics,
  PublicationShelf.videos => t.fileSources.video,
};
IconData shelfIcon(PublicationShelf shelf) => switch (shelf) {
  PublicationShelf.ebooks => Symbols.menu_book_rounded,
  PublicationShelf.audiobooks => Symbols.headphones_rounded,
  PublicationShelf.comics => Symbols.auto_stories_rounded,
  PublicationShelf.videos => Symbols.movie_rounded,
};

String remoteServiceName(RemoteStreamService service) => switch (service) {
  RemoteStreamService.realDebrid => t.streaming.realDebrid,
  RemoteStreamService.allDebrid => t.streaming.allDebrid,
  RemoteStreamService.premiumize => t.streaming.premiumize,
  RemoteStreamService.torbox => t.streaming.torbox,
};

List<AppMenuEntry<String>> sourceLibraryMenu(BuildContext context) {
  final sources = context.read<SourceController?>();
  final streaming = context.read<RemoteStreamingProvider?>();
  final accounts = streaming?.isReady == true && streaming?.profileId == sources?.profileId
      ? streaming!.accounts
      : const <RemoteStreamAccount>[];
  return [
    for (final shelf in sources?.shelves ?? <PublicationShelf>{})
      AppMenuItem(value: 'source:${shelf.name}', label: shelfLabel(shelf), icon: shelfIcon(shelf)),
    AppMenuItem(value: 'source:files', label: t.fileSources.title, icon: Symbols.folder_open_rounded),
    if (accounts.isNotEmpty) AppMenuHeader(label: t.streaming.title),
    for (final account in accounts)
      AppMenuItem(
        value: 'remote:${account.service.name}',
        label: remoteServiceName(account.service),
        subtitle: account.displayName.isEmpty
            ? null
            : t.streaming.accountConnected(username: isolateDisplayText(account.displayName)),
        icon: Symbols.cloud_rounded,
      ),
  ];
}
