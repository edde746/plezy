/// Source-time entry for long books. Hours can exceed 24; minute/second
/// components must be in range and malformed input never becomes a zero seek.
int? parseListeningTime(String input) {
  final parts = input.trim().split(':');
  if (parts.length < 2 || parts.length > 3 || parts.any((p) => !RegExp(r'^\d{1,5}$').hasMatch(p))) return null;
  final values = parts.map(int.parse).toList();
  if (values.last >= 60 || parts.length == 3 && values[1] >= 60) return null;
  final seconds = parts.length == 3 ? values[0] * 3600 + values[1] * 60 + values[2] : values[0] * 60 + values[1];
  return seconds * 1000;
}
