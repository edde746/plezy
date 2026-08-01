import '../models/catalog/catalog_item.dart';
import 'media_item.dart';

/// Recognizes [MediaItem]s synthesized from a [CatalogItem] (see
/// [CatalogItem.toMediaItem]). These are rendering-only stand-ins with no
/// server id; taps and menus must route through catalog paths instead of
/// server-backed ones.
extension CatalogMediaItemX on MediaItem {
  bool get isCatalogItem => raw?[CatalogItem.rawKey] != null;

  CatalogItem? get catalogItem {
    final data = raw?[CatalogItem.rawKey];
    if (data is! Map) return null;
    return CatalogItem.fromJson(data.cast<String, Object?>());
  }
}
