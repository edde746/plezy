import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../utils/formatters.dart';
import '../../lending/lending_service.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/provider_mark.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../libraries/state_messages.dart';
import '../sources/source_widgets.dart';

class PublicLibrariesScreen extends StatefulWidget {
  const PublicLibrariesScreen({super.key});
  @override
  State<PublicLibrariesScreen> createState() => _PublicLibrariesScreenState();
}

class _PublicLibrariesScreenState extends State<PublicLibrariesScreen> {
  LendingService? _service;
  List<LendingLibrary> _libraries = [];
  Object? _error;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sources = context.read<SourceController>();
      await sources.ready;
      if (!mounted) return;
      sources.requireSession();
      final epoch = sources.generation;
      _service ??= LendingService(
        sources.repository,
        sources.profileId!,
        valid: () => mounted && sources.current(epoch) && !sources.blocked,
      );
      final libraries = await _service!.libraries();
      if (mounted) {
        setState(() {
          _libraries = libraries;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add([LendingProvider? provider]) async {
    if (_service == null || _loading) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddLibraryScreen(service: _service!, provider: provider),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _open(LendingLibrary library) async {
    final service = _service;
    if (service == null) return;
    if (library.native && LendingService.overdriveEnabled) {
      if (!await service.connected(library)) {
        if (mounted) await _signIn(context, service, library);
        if (!await service.connected(library)) return;
      }
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LibraryCatalogueScreen(service: service, library: library),
          ),
        );
      }
    } else {
      await service.openPage(lendingHttps(library.home));
    }
  }

  @override
  void dispose() {
    _service?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.lending.title),
    focusableAppBarActions: true,
    actions: [
      IconButton(
        tooltip: t.lending.add,
        onPressed: _service == null || _loading ? null : () => _add(),
        icon: const AppIcon(Symbols.add_rounded),
      ),
    ],
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.lending.intro, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(t.common.loading, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    )
                  else if (_error != null)
                    SizedBox(
                      height: 240,
                      child: ErrorStateWidget(
                        message: sourceFailureText(_error!),
                        icon: Symbols.error_outline_rounded,
                        onRetry: () => unawaited(_load()),
                        actionUseBackgroundFocus: true,
                      ),
                    ),
                  SourceTile(
                    title: 'Open Library',
                    subtitle: t.lending.openLibraryNote,
                    icon: Symbols.menu_book_rounded,
                    onTap: _service == null || _loading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LibraryCatalogueScreen(service: _service!)),
                          ),
                  ),
                  if (_libraries.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    for (var i = 0; i < _libraries.length; i++)
                      SourceTile(
                        title: _libraries[i].name,
                        subtitle:
                            _libraries[i].provider == LendingProvider.overdrive && !LendingService.overdriveEnabled
                            ? t.lending.comingSoon
                            : _libraries[i].provider.label,
                        icon: Symbols.local_library_rounded,
                        leading: _libraries[i].provider == LendingProvider.overdrive
                            ? const ProviderMark('libby.png', label: 'Libby, by OverDrive')
                            : null,
                        index: i,
                        count: _libraries.length,
                        onTap: () => sourceAction(context, () => _open(_libraries[i])),
                        trailing: AppMenuButton<String>(
                          icon: const AppIcon(Symbols.more_vert_rounded),
                          tooltip: t.fileSources.preferences,
                          adaptiveSheet: true,
                          entriesBuilder: (_) => [
                            if (_libraries[i].native && LendingService.overdriveEnabled)
                              AppMenuItem(value: 'signIn', label: t.lending.signIn, icon: Symbols.login_rounded),
                            AppMenuItem(value: 'remove', label: t.lending.disconnect, icon: Symbols.link_off_rounded),
                          ],
                          onSelected: (action) => sourceAction(context, () async {
                            final library = _libraries[i];
                            if (action == 'signIn') {
                              await _signIn(context, _service!, library);
                              return;
                            }
                            if (await showConfirmDialog(
                              context,
                              title: t.lending.disconnect,
                              message: t.lending.disconnectMessage,
                              confirmText: t.lending.disconnect,
                            )) {
                              await _service!.remove(library);
                              if (mounted) await _load();
                            }
                          }),
                        ),
                      ),
                  ],
                  const SizedBox(height: 32),
                  Text(t.lending.findLibrary, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final provider in LendingProvider.values.where(
                        (p) => p != LendingProvider.openLibrary && p != LendingProvider.other,
                      ))
                        ActionChip(
                          avatar: provider == LendingProvider.overdrive
                              ? const ProviderMark('libby.png', size: 24)
                              : null,
                          label: Text(provider.label),
                          onPressed: _service == null || _loading ? null : () => _add(provider),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> _signIn(BuildContext context, LendingService service, LendingLibrary library) async {
  Object? failure;
  final finished = Completer<void>();
  unawaited(
    service
        .authorize(library)
        .catchError((Object error) {
          failure = error;
        })
        .whenComplete(() => finished.complete()),
  );
  await showScopedDialog<void>(
    context: context,
    builder: (dialogContext) => _SignInDialog(service: service, finished: finished.future),
  );
  service.cancelAuthorization();
  if (failure != null && context.mounted) showErrorSnackBar(context, sourceFailureText(failure!));
}

class _SignInDialog extends StatefulWidget {
  const _SignInDialog({required this.service, required this.finished});
  final LendingService service;
  final Future<void> finished;
  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.finished.then((_) {
        if (mounted) Navigator.pop(context);
      }),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.lending.signIn),
    content: Text(t.lending.waiting),
    actions: [
      DialogActionButton(
        autofocus: true,
        onPressed: () {
          widget.service.cancelAuthorization();
          Navigator.pop(context);
        },
        label: t.lending.cancel,
      ),
    ],
  );
}

class _AddLibraryScreen extends StatefulWidget {
  const _AddLibraryScreen({required this.service, this.provider});
  final LendingService service;
  final LendingProvider? provider;
  @override
  State<_AddLibraryScreen> createState() => _AddLibraryScreenState();
}

class _AddLibraryScreenState extends State<_AddLibraryScreen> {
  late LendingProvider _provider = widget.provider ?? LendingProvider.overdrive;
  final _name = TextEditingController(), _url = TextEditingController();
  final _gateway = TextEditingController(text: const String.fromEnvironment('LENDING_GATEWAY_URL'));
  List<Map<String, dynamic>> _available = [];
  Map<String, dynamic>? _selected;
  bool _busy = false;
  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _gateway.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final native = _selected;
      final library = LendingLibrary(
        id: const Uuid().v4(),
        provider: _provider,
        name: _name.text.trim().isNotEmpty ? _name.text.trim() : native?['name'] as String? ?? _provider.label,
        home: _url.text.trim().isNotEmpty ? _url.text.trim() : native?['home'] as String? ?? _provider.home,
        gateway: native == null ? '' : _gateway.text.trim(),
        remoteId: native?['id']?.toString() ?? '',
        integration: native?['integration'] == true,
        circulation: native?['circulation'] == true,
      );
      if (library.name.isEmpty) throw const SourceException(SourceFailure.invalidData);
      await widget.service.save(library);
      if (!mounted) return;
      if (library.native) await _signIn(context, widget.service, library);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.lending.add),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<LendingProvider>(
                    isExpanded: true,
                    icon: const AppIcon(Symbols.expand_more_rounded),
                    initialValue: _provider,
                    items: [
                      for (final p in LendingProvider.values.where((p) => p != LendingProvider.openLibrary))
                        DropdownMenuItem(value: p, child: Text(p == LendingProvider.other ? t.lending.other : p.label)),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _provider = value!;
                            _selected = null;
                          }),
                  ),
                  const SizedBox(height: 24),
                  if (_provider == LendingProvider.overdrive) ...[
                    const Center(child: ProviderMark('libby.png', size: 72, label: 'Libby, by OverDrive')),
                    if (Theme.of(context).brightness == Brightness.dark)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/provider_marks/overdrive_white.svg',
                            width: 108,
                            semanticsLabel: 'OverDrive',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  Text(t.lending.handoff),
                  const SizedBox(height: 24),
                  FocusableTextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: t.lending.libraryName),
                  ),
                  const SizedBox(height: 16),
                  FocusableTextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: t.lending.libraryUrl,
                      hintText: _provider.home,
                      helperText: t.lending.libraryUrlHint,
                    ),
                  ),
                  if (_provider == LendingProvider.overdrive && !LendingService.overdriveEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.lending.comingSoon, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Text(t.lending.comingSoonDescription),
                        ],
                      ),
                    ),
                  if (_provider == LendingProvider.overdrive && LendingService.overdriveEnabled)
                    ExpansionTile(
                      title: Text(t.lending.advanced),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        FocusableTextField(
                          controller: _gateway,
                          autocorrect: false,
                          decoration: InputDecoration(labelText: t.lending.gateway, helperText: t.lending.gatewayHint),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => sourceAction(context, () async {
                                  setState(() => _busy = true);
                                  try {
                                    final choices = await widget.service.gatewayLibraries(_gateway.text.trim());
                                    if (mounted) setState(() => _available = choices);
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                }),
                          child: Text(t.lending.loadLibraries),
                        ),
                        if (_available.isNotEmpty)
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            icon: const AppIcon(Symbols.expand_more_rounded),
                            items: [
                              for (final l in _available)
                                DropdownMenuItem(value: '${l['id']}', child: Text('${l['name']}')),
                            ],
                            onChanged: (id) =>
                                setState(() => _selected = _available.firstWhere((l) => '${l['id']}' == id)),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : () => sourceAction(context, _save),
                    child: Text(_selected == null ? t.lending.add : t.lending.signIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class LibraryCatalogueScreen extends StatefulWidget {
  const LibraryCatalogueScreen({super.key, required this.service, this.library});
  final LendingService service;
  final LendingLibrary? library;
  @override
  State<LibraryCatalogueScreen> createState() => _LibraryCatalogueScreenState();
}

class _LibraryCatalogueScreenState extends State<LibraryCatalogueScreen> {
  final _search = TextEditingController();
  List<LendingBook> _books = [];
  String _shelf = 'catalogue';
  int _page = 1, _request = 0;
  bool _busy = false, _more = false;
  Object? _error;
  Future<void> _load({bool more = false}) async {
    if (_shelf == 'catalogue' && _search.text.trim().isEmpty) return;
    final request = ++_request;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = more ? _page + 1 : 1, service = widget.service, library = widget.library;
      final result = library == null
          ? await service.openLibrarySearch(_search.text.trim(), page: page)
          : _shelf == 'catalogue'
          ? await service.search(library, _search.text.trim(), page: page)
          : await service.shelf(library, holds: _shelf == 'holds');
      if (mounted && request == _request) {
        setState(() {
          _books = more ? [..._books, ...result.books] : result.books;
          _page = page;
          _more = result.more;
        });
      }
    } catch (error) {
      if (mounted && request == _request) setState(() => _error = error);
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(LendingBook book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LendingDetailScreen(service: widget.service, library: widget.library, book: book),
      ),
    );
    if (mounted && _shelf != 'catalogue') await _load();
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(widget.library?.name ?? 'Open Library'),
    focusableAppBarActions: true,
    actions: [
      if (widget.library != null)
        IconButton(
          tooltip: t.lending.openService,
          onPressed: () => sourceAction(context, () => widget.service.openPage(lendingHttps(widget.library!.home))),
          icon: const AppIcon(Symbols.open_in_new_rounded),
        ),
    ],
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.library != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in {
                        'catalogue': t.lending.catalogue,
                        'loans': t.lending.loans,
                        'holds': t.lending.holds,
                      }.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _shelf == entry.key,
                          onSelected: _busy
                              ? null
                              : (_) {
                                  setState(() {
                                    _shelf = entry.key;
                                    _books = [];
                                    _more = false;
                                  });
                                  unawaited(_load());
                                },
                        ),
                    ],
                  ),
                ),
              if (_shelf == 'catalogue')
                FocusableTextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: t.lending.search,
                    prefixIcon: const AppIcon(Symbols.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: _busy ? null : () => _load(),
                      icon: AppIcon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Symbols.arrow_back_rounded
                            : Symbols.arrow_forward_rounded,
                      ),
                    ),
                  ),
                ),
              if (_busy) const Padding(padding: EdgeInsets.only(top: 20), child: LinearProgressIndicator()),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 20), child: Text(sourceFailureText(_error!))),
              if (!_busy && _books.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(widget.library == null ? t.lending.openLibraryNote : t.lending.empty),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 210,
            mainAxisSpacing: 28,
            crossAxisSpacing: 20,
            childAspectRatio: .54,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final book = _books[index];
            return FocusableWrapper(
              onSelect: () => _open(book),
              borderRadius: tokens(context).radiusMd,
              child: InkWell(
                onTap: () => _open(book),
                canRequestFocus: false,
                borderRadius: BorderRadius.circular(tokens(context).radiusMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: LendingCover(book: book)),
                    const SizedBox(height: 10),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                    ),
                    if (book.due != null)
                      Text(
                        t.lending.due(date: formatAbbreviatedDate(book.due!.toLocal().toIso8601String())),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (book.queuePosition != null)
                      Text(
                        t.lending.queue(position: formatCount(book.queuePosition!)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            );
          }, childCount: _books.length),
        ),
      ),
      if (_more)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TextButton(onPressed: _busy ? null : () => _load(more: true), child: Text(t.lending.more)),
          ),
        ),
    ],
  );
}

class LendingCover extends StatelessWidget {
  const LendingCover({super.key, required this.book});
  final LendingBook book;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: tokens(context).surface,
      child: Center(child: AppIcon(Symbols.menu_book_rounded, size: 52, color: tokens(context).textMuted)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      child: SizedBox.expand(
        child: book.cover == null
            ? fallback
            : Image.network(
                book.cover.toString(),
                fit: BoxFit.cover,
                cacheWidth: 420,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _LendingDetailScreen extends StatefulWidget {
  const _LendingDetailScreen({required this.service, required this.library, required this.book});
  final LendingService service;
  final LendingLibrary? library;
  final LendingBook book;
  @override
  State<_LendingDetailScreen> createState() => _LendingDetailScreenState();
}

class _LendingDetailScreenState extends State<_LendingDetailScreen> {
  Map<String, dynamic>? _availability;
  bool _busy = false, _changed = false;
  Future<void> _act(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
      if (mounted) setState(() => _changed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _borrow({bool hold = false}) async {
    String? email;
    if (hold) {
      final controller = TextEditingController();
      email = await showScopedDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.lending.placeHold),
          content: FocusableTextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: t.lending.email),
          ),
          actions: [
            DialogActionButton(onPressed: () => Navigator.pop(ctx), label: t.lending.cancel),
            DialogActionButton(
              onPressed: () {
                if (controller.text.contains('@')) Navigator.pop(ctx, controller.text.trim());
              },
              label: t.lending.placeHold,
              isPrimary: true,
            ),
          ],
        ),
      );
      // Dialog route may still be animating when its result completes.
      unawaited(Future<void>.delayed(const Duration(seconds: 1), controller.dispose));
      if (email == null) return;
    } else if (!await showConfirmDialog(
      context,
      title: t.lending.borrow,
      message: t.lending.confirmBorrow,
      confirmText: t.lending.borrow,
    )) {
      return;
    }
    if (!mounted) return;
    await _act(() => widget.service.borrow(widget.library!, widget.book, holdEmail: email));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book, library = widget.library;
    final expired = book.due?.isBefore(DateTime.now()) ?? false;
    final available = _availability?['available'] == true;
    return FocusedScrollScaffold(
      title: Text(library?.name ?? 'Open Library'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 220, height: 330, child: LendingCover(book: book)),
                    const SizedBox(height: 28),
                    Text(book.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      book.author,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tokens(context).textMuted),
                    ),
                    const SizedBox(height: 24),
                    if (book.due != null)
                      Text(
                        expired
                            ? t.lending.expired
                            : t.lending.due(date: formatFullDate(book.due!.toLocal().toIso8601String())),
                      ),
                    if (book.queuePosition != null) Text(t.lending.queue(position: formatCount(book.queuePosition!))),
                    if (_changed) Text(t.lending.updated),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (book.loan && !expired && !_changed)
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => sourceAction(context, () => widget.service.fulfill(library!, book)),
                            icon: const AppIcon(Symbols.menu_book_rounded),
                            label: Text(t.lending.getBook),
                          ),
                        if (book.hold && book.action('checkout') != null && library?.circulation == true && !_changed)
                          FilledButton(
                            onPressed: _busy ? null : () => sourceAction(context, () => _borrow()),
                            child: Text(t.lending.borrow),
                          ),
                        if (book.hold && library?.circulation == true && !_changed) ...[
                          if (book.action('addSuspension') != null || book.action('releaseSuspension') != null)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => sourceAction(context, () async {
                                      final resume = book.action('releaseSuspension') != null;
                                      if (await showConfirmDialog(
                                        context,
                                        title: resume ? t.lending.resumeHold : t.lending.suspendHold,
                                        message: resume ? t.lending.resumeMessage : t.lending.suspendMessage,
                                        confirmText: resume ? t.lending.resumeHold : t.lending.suspendHold,
                                      )) {
                                        await _act(() => widget.service.suspendHold(library!, book, resume: resume));
                                      }
                                    }),
                              child: Text(
                                book.action('releaseSuspension') != null ? t.lending.resumeHold : t.lending.suspendHold,
                              ),
                            ),
                          if (book.action('editHold') != null)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => sourceAction(context, () async {
                                      final input = TextEditingController(
                                        text: book.data['emailAddress'] as String? ?? '',
                                      );
                                      final email = await showScopedDialog<String>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(t.lending.editEmail),
                                          content: FocusableTextField(
                                            controller: input,
                                            autofocus: true,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: InputDecoration(labelText: t.lending.email),
                                          ),
                                          actions: [
                                            DialogActionButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              label: t.lending.cancel,
                                            ),
                                            DialogActionButton(
                                              onPressed: () {
                                                if (input.text.contains('@')) Navigator.pop(ctx, input.text.trim());
                                              },
                                              label: t.fileSources.save,
                                              isPrimary: true,
                                            ),
                                          ],
                                        ),
                                      );
                                      unawaited(Future<void>.delayed(const Duration(seconds: 1), input.dispose));
                                      if (email != null && mounted) {
                                        await _act(() => widget.service.editHoldEmail(library!, book, email));
                                      }
                                    }),
                              child: Text(t.lending.editEmail),
                            ),
                        ],
                        if (book.page != null)
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => sourceAction(context, () => widget.service.openPage(book.page!)),
                            icon: const AppIcon(Symbols.open_in_new_rounded),
                            label: Text(t.lending.continueService),
                          ),
                        if (library != null && !book.loan && !book.hold && !_changed) ...[
                          if (_availability == null)
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => sourceAction(context, () async {
                                      setState(() => _busy = true);
                                      try {
                                        final value = await widget.service.availability(library, book);
                                        if (mounted) setState(() => _availability = value);
                                      } finally {
                                        if (mounted) setState(() => _busy = false);
                                      }
                                    }),
                              child: Text(t.lending.checkAvailability),
                            )
                          else if (library.circulation)
                            FilledButton(
                              onPressed: _busy ? null : () => sourceAction(context, () => _borrow(hold: !available)),
                              child: Text(available ? t.lending.borrow : t.lending.placeHold),
                            ),
                        ],
                        if (library?.circulation == true &&
                            !_changed &&
                            (book.action('earlyReturn') != null || book.action('removeHold') != null))
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => sourceAction(context, () async {
                                    if (await showConfirmDialog(
                                      context,
                                      title: book.hold ? t.lending.cancelHold : t.lending.returnBook,
                                      message: book.hold ? t.lending.confirmCancelHold : t.lending.confirmReturn,
                                      confirmText: book.hold ? t.lending.cancelHold : t.lending.returnBook,
                                    )) {
                                      await _act(() => widget.service.returnOrCancel(library!, book));
                                    }
                                  }),
                            child: Text(book.hold ? t.lending.cancelHold : t.lending.returnBook),
                          ),
                      ],
                    ),
                    if (_availability != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(available ? t.lending.available : t.lending.unavailable),
                      ),
                    if (_busy) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                    const SizedBox(height: 24),
                    Text(library == null ? t.lending.openLibraryNote : t.lending.handoff, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
