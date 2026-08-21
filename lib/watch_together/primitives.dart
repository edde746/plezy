int watchTogetherSystemNowMs() => DateTime.now().millisecondsSinceEpoch;

bool orderedStringListsEqual(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var i = 0; i < first.length; i++) {
    if (first[i] != second[i]) return false;
  }
  return true;
}
