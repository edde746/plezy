import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'source_widgets.dart';

Future<String?> editSourceNote(BuildContext context, {String initial = '', String? quote}) async {
  final controller = TextEditingController(text: initial);
  final value = await showScopedDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.fileSources.note),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quote?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(quote!, maxLines: 5, overflow: TextOverflow.ellipsis),
              ),
            FocusableTextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(labelText: t.fileSources.note),
            ),
          ],
        ),
      ),
      actions: [
        DialogActionButton(onPressed: () => Navigator.pop(context), label: t.fileSources.cancel),
        DialogActionButton(
          onPressed: () => Navigator.pop(context, controller.text),
          label: t.fileSources.save,
          isPrimary: true,
        ),
      ],
    ),
  );
  // Dialog exit animations may still reference the editing controller.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  return value;
}

class SourceNotesScreen extends StatefulWidget {
  const SourceNotesScreen({super.key, required this.entry, this.edition, this.mode});
  final SourceEntry entry;
  final String? edition;
  final PublicationMode? mode;
  @override
  State<SourceNotesScreen> createState() => _SourceNotesScreenState();
}

class _SourceNotesScreenState extends State<SourceNotesScreen> {
  List<BookAnnotation> _notes = [];
  String _positionLabel(BookAnnotation note) {
    final index = note.fileIndex, position = note.filePositionMs;
    if (index != null && position != null && index >= 0 && index < widget.entry.files.length) {
      return '${widget.entry.files[index].name} · ${sourceTime(position)}';
    }
    return sourceTime(note.positionMs ?? 0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) sourceAction(context, _load);
    });
  }

  Future<void> _load() async {
    final sources = context.read<SourceController>();
    sources.requireSession();
    final epoch = sources.generation;
    final notes = await sources.repository.annotations(sources.profileId!, widget.entry.key);
    if (mounted && sources.current(epoch)) {
      setState(
        () => _notes = notes
            .where(
              (a) =>
                  (widget.edition == null || a.edition == widget.edition) &&
                  (widget.mode == null || a.mode == widget.mode),
            )
            .toList(),
      );
    }
  }

  Future<void> _update(BookAnnotation note, {bool delete = false}) async {
    final sources = context.read<SourceController>(), profile = sourcesProfile(context);
    final text = delete ? note.note : await editSourceNote(context, initial: note.note, quote: note.quote);
    if (text == null || !mounted) return;
    sources.requireSession();
    if (sources.profileId != profile) return;
    await sources.repository.saveAnnotation(
      profile,
      BookAnnotation.fromJson({
        ...note.toJson(),
        'note': text,
        'deleted': delete,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    sources.scheduleSync();
    await _load();
  }

  Future<void> _export() async {
    final bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert({
          'format': 'plezyng-annotations',
          'version': 1,
          'title': widget.entry.title,
          'annotations': _notes.map((a) => a.toJson()).toList(),
        }),
      ),
    );
    final result = await FilePicker.saveFile(
      fileName: 'book-notes-${const Uuid().v4().substring(0, 8)}.json',
      bytes: bytes,
    );
    if (result != null && mounted) showSnackBar(context, t.fileSources.exported);
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.fileSources.bookmarks),
    focusableAppBarActions: true,
    actions: [
      IconButton(
        tooltip: t.fileSources.export,
        onPressed: () => sourceAction(context, _export),
        icon: const AppIcon(Symbols.ios_share_rounded),
      ),
    ],
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverList.builder(
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return SourceTile(
              title: note.note.isNotEmpty
                  ? note.note
                  : note.quote.isNotEmpty
                  ? note.quote
                  : _positionLabel(note),
              subtitle: note.mode == PublicationMode.reading ? (note.locator?.href ?? '') : _positionLabel(note),
              icon: Symbols.bookmark_rounded,
              index: index,
              count: _notes.length,
              onTap: () => Navigator.pop(context, note),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: t.fileSources.note,
                    onPressed: () => sourceAction(context, () => _update(note)),
                    icon: const AppIcon(Symbols.edit_rounded),
                  ),
                  IconButton(
                    tooltip: t.fileSources.delete,
                    onPressed: () => sourceAction(context, () => _update(note, delete: true)),
                    icon: const AppIcon(Symbols.delete_rounded),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      if (_notes.isEmpty)
        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.all(24), child: Text(t.fileSources.empty)),
        ),
    ],
  );
}

String sourcesProfile(BuildContext context) {
  final s = context.read<SourceController>();
  s.requireSession();
  return s.profileId!;
}
