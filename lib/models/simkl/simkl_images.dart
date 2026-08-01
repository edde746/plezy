String? simklPosterUrl(String? hash) {
  if (hash == null || hash.isEmpty) return null;
  return 'https://simkl.in/posters/${hash}_m.webp';
}

Map<int, String>? simklPosterVariants(String? hash) {
  if (hash == null || hash.isEmpty) return null;
  final base = 'https://simkl.in/posters/$hash';
  return {
    40: '${base}_s.webp',
    84: '${base}_cm.webp',
    170: '${base}_c.webp',
    190: '${base}_ca.webp',
    340: '${base}_m.webp',
  };
}

String? simklFanartUrl(String? hash) {
  if (hash == null || hash.isEmpty) return null;
  return 'https://simkl.in/fanart/${hash}_medium.webp';
}

Map<int, String>? simklFanartVariants(String? hash) {
  if (hash == null || hash.isEmpty) return null;
  final base = 'https://simkl.in/fanart/$hash';
  return {48: '${base}_s48.webp', 600: '${base}_w.webp', 960: '${base}_mobile.webp', 1920: '${base}_medium.webp'};
}
