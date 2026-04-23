import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_button.dart';
import '../focus/focusable_text_field.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../models/plex_match_result.dart';
import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_icon.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/pill_input_decoration.dart';
import '../widgets/plex_optimized_image.dart';

/// Fix / apply a metadata match on a movie or show.
///
/// On success, pops `true` so the caller can refresh its view.
class MatchScreen extends StatefulWidget {
  final PlexMetadata metadata;

  const MatchScreen({super.key, required this.metadata});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final PlexClient _client;
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  final _nameFocus = FocusNode();
  final _yearFocus = FocusNode();
  final _searchFocus = FocusNode();

  List<PlexMatchResult>? _results;
  bool _isSearching = false;
  String? _applyingGuid;

  bool get _isApplying => _applyingGuid != null;

  @override
  void initState() {
    super.initState();
    _client = context.getClientWithFallback(widget.metadata.serverId);
    _nameController = TextEditingController(text: widget.metadata.title);
    _yearController = TextEditingController(text: widget.metadata.year?.toString() ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (InputModeTracker.isKeyboardMode(context)) {
        _nameFocus.requestFocus();
      }
      _search();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _nameFocus.dispose();
    _yearFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_isSearching) return;
    setState(() => _isSearching = true);
    final results = await _client.findMatches(
      widget.metadata.ratingKey,
      title: _nameController.text.trim(),
      year: _yearController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  Future<void> _applyMatch(PlexMatchResult result) async {
    if (_isApplying) return;
    setState(() => _applyingGuid = result.guid);
    final success = await _client.applyMatch(
      widget.metadata.ratingKey,
      guid: result.guid,
      name: result.name,
      year: result.year?.toString(),
    );
    if (!mounted) return;
    setState(() => _applyingGuid = null);
    if (success) {
      showSuccessSnackBar(context, t.matchScreen.matchApplied);
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, t.matchScreen.matchFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(widget.metadata.isUnmatched ? t.matchScreen.match : t.matchScreen.fixMatch),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: _buildSearchForm(context)),
        ),
        if (_isSearching || _results == null)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
        else if (_results!.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                t.matchScreen.noMatchesFound,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            sliver: SliverList.builder(
              itemCount: _results!.length,
              itemBuilder: (context, index) => _buildResultTile(_results![index]),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FocusableTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: pillInputDecoration(
                  context,
                  hintText: t.matchScreen.titleHint,
                  prefixIcon: const AppIcon(Symbols.search_rounded),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _yearFocus.requestFocus(),
                onNavigateRight: _yearFocus.requestFocus,
                onNavigateDown: _searchFocus.requestFocus,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: FocusableTextField(
                controller: _yearController,
                focusNode: _yearFocus,
                decoration: pillInputDecoration(context, hintText: t.matchScreen.yearHint),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                onNavigateLeft: _nameFocus.requestFocus,
                onNavigateDown: _searchFocus.requestFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FocusableButton(
          focusNode: _searchFocus,
          useBackgroundFocus: true,
          onPressed: _isSearching ? null : _search,
          child: FilledButton.icon(
            onPressed: _isSearching ? null : _search,
            icon: const AppIcon(Symbols.search_rounded),
            label: Text(t.matchScreen.search),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultTile(PlexMatchResult result) {
    final isApplyingThis = _isApplying && _applyingGuid == result.guid;
    final yearLabel = result.year?.toString() ?? '';
    final titleText = yearLabel.isEmpty ? result.name : '${result.name} (${result.year})';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: FocusableListTile(
        enabled: !_isApplying,
        onTap: () => _applyMatch(result),
        leading: SizedBox(
          width: 48,
          height: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: PlexOptimizedImage(
              client: _client,
              imagePath: result.thumb,
              fit: BoxFit.cover,
              fallbackIcon: Symbols.movie_rounded,
            ),
          ),
        ),
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: result.summary != null && result.summary!.isNotEmpty
            ? Text(result.summary!, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: isApplyingThis
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : result.score != null
            ? _ScoreChip(score: result.score!)
            : null,
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int score;
  const _ScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(100)),
      child: Text(
        '$score',
        style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600),
      ),
    );
  }
}
