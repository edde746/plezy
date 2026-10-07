import '../../media/media_item.dart';
import '../../media/media_item_types.dart';

/// Explicit item selection, retained independently of paginated cache eviction.
/// Range selection includes only loaded items, never unseen results.
class LibrarySelection {
  final Map<String, MediaItem> _items = {};
  int? _anchor;

  List<MediaItem> get items => List.unmodifiable(_items.values);
  int get count => _items.length;
  bool contains(MediaItem item) => _items.containsKey(item.globalKey);

  void toggle(int index, Map<int, MediaItem> loaded, {bool range = false}) {
    final item = loaded[index];
    if (item == null || !item.isVideoContent) return;
    final anchor = _anchor;
    if (range && anchor != null) {
      final start = index < anchor ? index : anchor;
      final end = index > anchor ? index : anchor;
      for (final entry in loaded.entries) {
        if (entry.key >= start && entry.key <= end && entry.value.isVideoContent) {
          _items[entry.value.globalKey] = entry.value;
        }
      }
    } else if (_items.remove(item.globalKey) == null) {
      _items[item.globalKey] = item;
    }
    _anchor = index;
  }

  void remove(MediaItem item) => _items.remove(item.globalKey);

  void clear() {
    _items.clear();
    _anchor = null;
  }
}
