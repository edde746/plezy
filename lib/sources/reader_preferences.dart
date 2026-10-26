/// Complete, bounded preferences shared by the native and browser controls.
/// A complete snapshot also makes resetting preferences restore every option.
Map<String, dynamic> normalizeReaderPreferences(Map<String, dynamic> input) {
  String choice(String key, List<String> values) => values.contains(input[key]) ? input[key] as String : values.first;
  double number(String key, double fallback, double min, double max) {
    final value = input[key];
    return value is num && value.isFinite ? value.toDouble().clamp(min, max) : fallback;
  }

  final zoom = input['zoom'];
  return {
    'theme': choice('theme', ['app', 'paper', 'sepia', 'night']),
    'font': choice('font', ['serif', 'sans', 'mono']),
    'fontSize': number('fontSize', 20, 12, 72),
    'lineHeight': number('lineHeight', 1.6, 1, 2.5),
    'letterSpacing': number('letterSpacing', 0, 0, .3),
    'wordSpacing': number('wordSpacing', 0, 0, .5),
    'margin': number('margin', 8, 2, 20),
    'columns': number('columns', 2, 1, 2).round(),
    'scrolled': input['scrolled'] == true,
    'justify': input['justify'] == true,
    'comicMode': choice('comicMode', ['paged', 'webtoon']),
    'coverAlone': input['coverAlone'] != false,
    'splitWide': input['splitWide'] == true,
    'spread': choice('spread', ['auto', 'single', 'double']),
    'direction': choice('direction', ['auto', 'ltr', 'rtl']),
    'zoom': zoom is num && zoom.isFinite
        ? zoom.toDouble().clamp(.25, 6)
        : const ['fit-page', 'fit-width', 'fit-height'].contains(zoom)
        ? zoom
        : 'fit-page',
  };
}
