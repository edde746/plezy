class DeletionProgress {
  final String globalKey;
  final String itemTitle;
  final int currentItem;
  final int totalItems;
  final String? currentOperation;

  const DeletionProgress({
    required this.globalKey,
    required this.itemTitle,
    required this.currentItem,
    required this.totalItems,
    this.currentOperation,
  });

  double get progressPercent =>
      totalItems > 0 ? (currentItem / totalItems) : 0.0;

  int get progressPercentInt => (progressPercent * 100).round();

  bool get isComplete => currentItem >= totalItems;

  DeletionProgress copyWith({
    String? globalKey,
    String? itemTitle,
    int? currentItem,
    int? totalItems,
    String? currentOperation,
  }) {
    return DeletionProgress(
      globalKey: globalKey ?? this.globalKey,
      itemTitle: itemTitle ?? this.itemTitle,
      currentItem: currentItem ?? this.currentItem,
      totalItems: totalItems ?? this.totalItems,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }

  @override
  String toString() {
    return 'DeletionProgress(globalKey: $globalKey, itemTitle: $itemTitle, '
        'currentItem: $currentItem, totalItems: $totalItems, '
        'progressPercent: $progressPercentInt%)';
  }
}
