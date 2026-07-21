String? simklPosterUrl(String? hash) {
  if (hash == null || hash.isEmpty) return null;
  return 'https://simkl.in/posters/${hash}_m.webp';
}

String? simklFanartUrl(String? hash) {
  if (hash == null || hash.isEmpty) return null;
  return 'https://simkl.in/fanart/${hash}_medium.webp';
}
