import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_text_field.dart';
import '../i18n/strings.g.dart';
import '../services/external_access_directory.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_icon.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/settings_section.dart';

/// Title-aware official-site handoff. Provider pages make the final offer,
/// territory, account and access decision; this screen never implies that a
/// title is available or that opening a destination changed library state.
class ExternalAccessScreen extends StatefulWidget {
  const ExternalAccessScreen({
    super.key,
    required this.title,
    this.creator = '',
    required this.categories,
  });

  final String title;
  final String creator;
  final List<ExternalAccessCategory> categories;

  @override
  State<ExternalAccessScreen> createState() => _ExternalAccessScreenState();
}

class _ExternalAccessScreenState extends State<ExternalAccessScreen> {
  final TextEditingController _filter = TextEditingController();

  String _sectionLabel(ExternalAccessCategory category) => switch (category) {
    ExternalAccessCategory.video => t.explore.detail.watchOn,
    ExternalAccessCategory.rentals => t.explore.detail.links,
    ExternalAccessCategory.books => t.fileSources.read,
    ExternalAccessCategory.audiobooks => t.fileSources.listen,
    ExternalAccessCategory.comics => t.fileSources.read,
    ExternalAccessCategory.music => t.fileSources.listen,
    ExternalAccessCategory.games => t.games.title,
  };

  IconData _icon(ExternalAccessCategory category) => switch (category) {
    ExternalAccessCategory.video => Symbols.tv_rounded,
    ExternalAccessCategory.rentals => Symbols.shopping_bag_rounded,
    ExternalAccessCategory.books || ExternalAccessCategory.comics => Symbols.menu_book_rounded,
    ExternalAccessCategory.audiobooks || ExternalAccessCategory.music => Symbols.headphones_rounded,
    ExternalAccessCategory.games => Symbols.sports_esports_rounded,
  };

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, ExternalAccessDestination destination) async {
    final region = Localizations.localeOf(context).countryCode ?? 'CA';
    final uri = destination.searchUri(widget.title, creator: widget.creator, region: region);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Report the same recovery state for platform handlers and launch errors.
    }
    if (context.mounted) showErrorSnackBar(context, t.common.error);
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.text.trim().toLowerCase();
    final destinationsByCategory = {
      for (final category in widget.categories)
        category: ExternalAccessDirectory.forCategory(category)
            .where((destination) => destination.name.toLowerCase().contains(query))
            .toList(growable: false),
    };
    final hasResults = destinationsByCategory.values.any((destinations) => destinations.isNotEmpty);
    return FocusedScrollScaffold(
      title: Text(t.explore.detail.links),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title.trim().isNotEmpty)
                        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
                      if (widget.creator.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(widget.creator, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                FocusableTextField(
                  controller: _filter,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: t.lending.search,
                    prefixIcon: const AppIcon(Symbols.search_rounded),
                  ),
                ),
                for (final category in widget.categories)
                  if (destinationsByCategory[category]!.isNotEmpty)
                    SettingsGroup(
                      title: _sectionLabel(category),
                      children: [
                        for (final destination in destinationsByCategory[category]!)
                          FocusableListTile(
                            leading: AppIcon(_icon(category)),
                            title: Text(destination.name),
                            subtitle: Text(t.explore.detail.openOn(site: destination.name)),
                            trailing: const AppIcon(Symbols.open_in_new_rounded),
                            onTap: () => _open(context, destination),
                          ),
                      ],
                    ),
                if (!hasResults)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(t.messages.noResultsFound)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
