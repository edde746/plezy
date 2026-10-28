import '../../providers/hidden_libraries_provider.dart';
import '../../utils/global_key_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/canonical_library.dart';
import '../../media/ids.dart';
import '../../providers/multi_server_provider.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../utils/media_navigation_helper.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import 'source_detail_screen.dart';
import 'source_widgets.dart';

Future<void> openCanonicalEntry(BuildContext context, SourceEntry entry, {required String profile}) =>
    sourceAction(context, () async {
      final sources = context.read<SourceController>();
      if (sources.profileId != profile || sources.blocked) return;
      final epoch = sources.generation;
      await sources.ready;
      if (!context.mounted || !sources.current(epoch) || sources.blocked) return;
      sources.requireSession(epoch);
      final identity = CanonicalLibrary(sources.repository.database);
      await identity.recordSource(profile, entry);
      final card = await identity.cardForCopy(profile, CanonicalLibrary.entryKey(entry));
      if (!context.mounted || sources.profileId != profile || card == null) return;
      await openCanonicalCard(context, card);
    });

Future<void> openCanonicalCard(BuildContext context, CanonicalLibraryCard card) async {
  final sources = context.read<SourceController>();
  final profile = sources.profileId;
  if (profile != card.profile || sources.blocked) return;
  final servers = context.read<MultiServerProvider>();
  final hidden = context.read<HiddenLibrariesProvider?>()?.hiddenLibraryKeys ?? const <String>{};
  final copies = card.copies.where((copy) {
    final library = copy.serverItem?.libraryId;
    return library == null || !hidden.contains(buildGlobalKey(ServerId(copy.source), library));
  }).toList();
  if (copies.isEmpty) return;
  final selected = copies.length == 1
      ? copies.single
      : await showModalBottomSheet<CanonicalLibraryCopy>(
          context: context,
          isScrollControlled: true,
          builder: (sheet) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * .75),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Semantics(
                      header: true,
                      child: Text(t.streaming.availableCopies, style: Theme.of(sheet).textTheme.titleLarge),
                    ),
                  ),
                  for (final copy in copies)
                    FocusableListTile(
                      leading: AppIcon(copy.entry == null ? Symbols.dns_rounded : Symbols.cloud_rounded),
                      title: Text(
                        copy.serverItem?.serverName ??
                            sources.sources.where((s) => s.id == copy.source).firstOrNull?.name ??
                            t.streaming.cloudFiles,
                      ),
                      subtitle: Text(
                        copy.serverItem?.displayTitle ?? copy.entry!.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      enabled: copy.entry != null || servers.getClientForServer(ServerId(copy.source)) != null,
                      onTap: () => Navigator.pop(sheet, copy),
                    ),
                ],
              ),
            ),
          ),
        );
  if (selected == null || !context.mounted || sources.profileId != profile || sources.blocked) return;
  if (selected.entry case final entry?) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SourceDetailScreen(entry: entry)));
    return;
  }
  try {
    final client = servers.getClientForServer(ServerId(selected.source));
    final media = await client?.fetchItem(selected.item);
    if (!context.mounted || sources.profileId != profile || sources.blocked) return;
    if (media == null) {
      showAppSnackBar(context, t.errors.noClientAvailable);
      return;
    }
    await navigateToMediaItem(context, media);
  } on Object {
    if (context.mounted) showAppSnackBar(context, t.errors.noClientAvailable);
  }
}
