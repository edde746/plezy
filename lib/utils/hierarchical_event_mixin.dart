import 'global_key_utils.dart';

/// Mixin providing hierarchical event matching methods.
///
/// Events that represent changes to media items often need to check if they
/// affect a specific item or any of its parents in the hierarchy. This mixin
/// provides common matching logic for such events.
mixin HierarchicalEventMixin {
  /// The ratingKey of the affected item.
  String get ratingKey;

  /// Composite key: serverId:ratingKey.
  String get globalKey;

  /// Server this item belongs to.
  String get serverId;

  /// Parent chain for hierarchical matching.
  /// For an episode: [seasonRatingKey, showRatingKey]
  /// For a season: [showRatingKey]
  /// For a movie: []
  List<String> get parentChain;

  /// Check if this event affects a specific item by ratingKey.
  bool affectsItem(String ratingKey) => this.ratingKey == ratingKey || parentChain.contains(ratingKey);

  /// Check if this event affects a specific globalKey.
  bool affectsGlobalKey(String globalKey) =>
      this.globalKey == globalKey || parentChain.any((pk) => buildGlobalKey(serverId, pk) == globalKey);

  /// Check if this event affects any item in a collection.
  bool affectsAnyOf(Iterable<String> ratingKeys) => ratingKeys.any(affectsItem);

  /// Check if this event affects any item in a global-key collection.
  bool affectsAnyGlobalKey(Iterable<String> globalKeys) => globalKeys.any(affectsGlobalKey);
}
