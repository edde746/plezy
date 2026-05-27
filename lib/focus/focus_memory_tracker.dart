import 'package:flutter/material.dart';

/// Reusable focus memory tracker for screens with multiple focusable items.
/// Tracks which item was last focused and provides focus restoration.
class FocusMemoryTracker {
  final Map<String, FocusNode> _nodes = {};
  final Set<String> _focused = {};
  final VoidCallback? _onFocusChanged;
  final String _debugLabelPrefix;
  String? _lastFocusedKey;

  FocusMemoryTracker({VoidCallback? onFocusChanged, String debugLabelPrefix = 'focus'})
    : _onFocusChanged = onFocusChanged,
      _debugLabelPrefix = debugLabelPrefix;

  /// Get or create a focus node for the given key
  FocusNode get(String key, {String? debugLabel}) {
    return _nodes.putIfAbsent(key, () {
      final node = FocusNode(debugLabel: debugLabel ?? '${_debugLabelPrefix}_$key');
      node.addListener(() {
        final wasFocused = _focused.contains(key);
        if (node.hasFocus && !wasFocused) {
          _focused.add(key);
          _lastFocusedKey = key;
          _onFocusChanged?.call();
        } else if (!node.hasFocus && wasFocused) {
          _focused.remove(key);
          _onFocusChanged?.call();
        }
      });
      return node;
    });
  }

  /// Get the last focused key (for focus restoration)
  String? get lastFocusedKey => _lastFocusedKey;

  /// Check if a key is currently focused
  bool isFocused(String key) => _focused.contains(key);

  /// Get a node without creating it (returns null if not found)
  FocusNode? nodeFor(String key) => _nodes[key];

  /// Restore focus to the last focused item, or fallback if provided
  /// Returns true if focus was successfully restored
  bool restoreFocus({String? fallbackKey}) {
    // Try to restore last focused item
    if (_lastFocusedKey != null) {
      final node = _nodes[_lastFocusedKey];
      if (node != null) {
        node.requestFocus();
        return true;
      }
    }
    // Fallback: focus the provided key if available
    if (fallbackKey != null) {
      final node = _nodes[fallbackKey];
      if (node != null) {
        node.requestFocus();
        return true;
      }
    }
    return false;
  }

  /// Remove nodes not in the given set of valid keys (prunes stale nodes)
  void pruneExcept(Set<String> validKeys) {
    final toRemove = _nodes.keys.where((k) => !validKeys.contains(k)).toList();
    for (final key in toRemove) {
      _nodes[key]?.dispose();
      _nodes.remove(key);
      _focused.remove(key);
    }
    // Clear last focused if it was pruned
    if (_lastFocusedKey != null && !validKeys.contains(_lastFocusedKey)) {
      _lastFocusedKey = null;
    }
  }

  /// Dispose all nodes
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _nodes.clear();
    _focused.clear();
  }
}
