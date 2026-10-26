import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../sources/publication_shelf.dart';
import '../../sources/source_controller.dart';
import '../../widgets/app_menu.dart';

String shelfLabel(PublicationShelf shelf) => switch (shelf) {
  PublicationShelf.ebooks => t.fileSources.ebooks,
  PublicationShelf.audiobooks => t.fileSources.audiobooks,
  PublicationShelf.comics => t.fileSources.comics,
};
IconData shelfIcon(PublicationShelf shelf) => switch (shelf) {
  PublicationShelf.ebooks => Symbols.menu_book_rounded,
  PublicationShelf.audiobooks => Symbols.headphones_rounded,
  PublicationShelf.comics => Symbols.auto_stories_rounded,
};
List<AppMenuEntry<String>> sourceLibraryMenu(BuildContext context) => [
  for (final shelf in context.read<SourceController?>()?.shelves ?? <PublicationShelf>{})
    AppMenuItem(value: 'source:${shelf.name}', label: shelfLabel(shelf), icon: shelfIcon(shelf)),
  AppMenuItem(value: 'source:files', label: t.fileSources.title, icon: Symbols.folder_open_rounded),
];
