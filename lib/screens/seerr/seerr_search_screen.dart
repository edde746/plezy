import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_search_result.dart';
import '../../providers/seerr_session_provider.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';
import 'seerr_detail_screen.dart';
import 'widgets/seerr_media_card.dart';

/// Debounced search inside the Seerr tab. Renders results as a wrapped
/// poster grid; tapping pushes [SeerrDetailScreen].
class SeerrSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SeerrSearchScreen({super.key, this.initialQuery});

  @override
  State<SeerrSearchScreen> createState() => _SeerrSearchScreenState();
}

class _SeerrSearchScreenState extends State<SeerrSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _searching = false;
  bool _hasSearched = false;
  String? _error;
  List<SeerrSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    if ((widget.initialQuery ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(widget.initialQuery!));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _hasSearched = false;
        _error = null;
      });
      return;
    }
    final client = context.read<SeerrSessionProvider>().client;
    if (client == null) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final page = await client.search(trimmed);
      if (!mounted) return;
      setState(() {
        _results = page.results.where((r) => r is! SeerrPersonResult).toList(growable: false);
        _hasSearched = true;
        _searching = false;
      });
    } catch (e, st) {
      appLogger.w('Seerr search failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  void _openDetail(SeerrSearchResult r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          final title = switch (r) {
            SeerrMovieResult(:final title) => title,
            SeerrTvResult(:final name) => name,
            SeerrPersonResult(:final name) => name,
          };
          final poster = switch (r) {
            SeerrMovieResult(:final posterPath) => posterPath,
            SeerrTvResult(:final posterPath) => posterPath,
            SeerrPersonResult(:final profilePath) => profilePath,
          };
          return SeerrDetailScreen(
            tmdbId: r.id,
            mediaType: r.mediaType,
            initialTitle: title,
            initialPosterPath: poster,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: FocusableTextField(
            controller: _controller,
            // Don't autofocus the bare-Seerr-tab open — on TV that pops the
            // virtual keyboard immediately, hiding the discover content.
            autofocus: false,
            onChanged: _onChanged,
            onSubmitted: (v) => _search(v),
            decoration: InputDecoration(
              hintText: t.seerr.search.placeholder,
              prefixIcon: const AppIcon(Symbols.search_rounded, fill: 1),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const AppIcon(Symbols.close_rounded, fill: 1),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(child: _buildBody(theme)),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_searching) return const Center(child: LoadingIndicatorBox(size: 32));
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error, textAlign: TextAlign.center),
        ),
      );
    }
    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.seerr.search.startHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(Symbols.search_off_rounded, fill: 1, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(t.seerr.search.noResults, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.52,
      ),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final r = _results[i];
        return SeerrMediaCard(result: r, onTap: () => _openDetail(r), width: 140);
      },
    );
  }
}
