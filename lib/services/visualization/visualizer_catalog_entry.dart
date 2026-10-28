import 'dart:convert';

/// An immutable pack authorized by an app pin or a verified signed catalog.
class VisualizerPackCatalogEntry {
  const VisualizerPackCatalogEntry({
    required this.id,
    required this.name,
    required this.version,
    required this.license,
    required this.description,
    required this.contentNotice,
    required this.archiveUrl,
    required this.sha256,
    required this.archiveBytes,
    required this.expandedBytes,
    required this.presetCount,
    required this.sourceUrl,
    this.searchText = '',
    this.bundledAsset,
  });

  final String id;
  final String name;
  final String version;
  final String license;
  final String description;
  final String contentNotice;
  final String archiveUrl;
  final String sha256;
  final int archiveBytes;
  final int expandedBytes;
  final int presetCount;
  final String sourceUrl;
  final String searchText;
  final String? bundledAsset;

  String get fileName => '$id-$version.rmpack';

  String get identity => '$id@$version';

  Map<String, Object> toJson() => {
    'id': id, 'name': name, 'version': version, 'license': license,
    'description': description, 'contentNotice': contentNotice,
    'archiveUrl': archiveUrl, 'sha256': sha256, 'archiveBytes': archiveBytes,
    'expandedBytes': expandedBytes, 'presetCount': presetCount,
    'sourceUrl': sourceUrl, 'searchText': searchText,
    'distributionStatus': 'redistributable',
  };

  bool sameArtifact(VisualizerPackCatalogEntry other) =>
      bundledAsset == other.bundledAsset && jsonEncode(toJson()) == jsonEncode(other.toJson());

  static const redistributableLicenses = <String>{
    '0BSD', 'Apache-2.0', 'BSD-2-Clause', 'BSD-3-Clause', 'CC-BY-3.0',
    'CC-BY-4.0', 'CC-BY-SA-3.0', 'CC-BY-SA-4.0', 'CC0-1.0',
    'GPL-2.0-only', 'GPL-2.0-or-later', 'GPL-3.0-only', 'GPL-3.0-or-later',
    'ISC', 'LGPL-2.1-only', 'LGPL-2.1-or-later', 'LGPL-3.0-only',
    'LGPL-3.0-or-later', 'MIT', 'Unlicense', 'Zlib',
  };

  factory VisualizerPackCatalogEntry.fromJson(Map<String, dynamic> value) {
    String field(String key, int limit) {
      final text = value[key];
      if (text is! String || text.trim().isEmpty || text.length > limit || text.contains('\u0000')) {
        throw FormatException('Invalid catalog field: $key');
      }
      return text;
    }
    int count(String key, int limit) {
      final number = value[key];
      if (number is! int || number <= 0 || number > limit) throw FormatException('Invalid catalog size: $key');
      return number;
    }
    final id = field('id', 80), version = field('version', 80);
    final component = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$');
    for (final part in [id, version]) {
      if (!component.hasMatch(part) || part.endsWith('.') || part.endsWith('.previous') || part.endsWith('.partial') ||
          RegExp(r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])($|\.)', caseSensitive: false).hasMatch(part)) {
        throw const FormatException('Invalid catalog identity');
      }
    }
    if (value['distributionStatus'] != 'redistributable' ||
        !redistributableLicenses.contains(value['license'])) {
      throw const FormatException('Catalog pack has no approved redistribution declaration');
    }
    final archive = field('archiveUrl', 1024);
    if (!RegExp(r'^https://raw\.githubusercontent\.com/snapetech-org/MilkRust/[a-f0-9]{40}/content/downloads/[A-Za-z0-9._-]+\.rmpack$').hasMatch(archive)) {
      throw const FormatException('Pack archives must use an immutable MilkRust content revision');
    }
    final digest = field('sha256', 64);
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) throw const FormatException('Invalid archive SHA-256');
    final source = field('sourceUrl', 2048), uri = Uri.tryParse(source);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const FormatException('Invalid pack source URL');
    }
    final search = value['searchText'] ?? '';
    if (search is! String || search.length > 4096) throw const FormatException('Invalid pack search metadata');
    return VisualizerPackCatalogEntry(
      id: id, name: field('name', 200), version: version, license: field('license', 100),
      description: field('description', 4096), contentNotice: field('contentNotice', 8192),
      archiveUrl: archive, sha256: digest, archiveBytes: count('archiveBytes', 32 * 1024 * 1024),
      expandedBytes: count('expandedBytes', 64 * 1024 * 1024), presetCount: count('presetCount', 2500),
      sourceUrl: source, searchText: search,
    );
  }

  static const available = <VisualizerPackCatalogEntry>[
    VisualizerPackCatalogEntry(
      id: 'milkrust-sample-pack',
      name: 'MilkRust Sample Pack',
      version: '0.1.0',
      license: 'CC0-1.0',
      description: 'Two MilkRust-authored sample presets. No third-party assets.',
      contentNotice: 'MilkRust-authored sample content dedicated under CC0-1.0. No third-party presets or textures are included.',
      archiveUrl:
          'https://raw.githubusercontent.com/snapetech-org/MilkRust/de41e50c9d04c0b7c2de03f472c71720e1e9fda0/content/downloads/milkrust-sample-pack-0.1.0.rmpack',
      sha256: '175a042deb4edb224055a6334f67a1c492f32e447dc3c90a54f22849c43a27df',
      archiveBytes: 2927,
      expandedBytes: 5467,
      presetCount: 2,
      sourceUrl:
          'https://github.com/snapetech-org/MilkRust/tree/de41e50c9d04c0b7c2de03f472c71720e1e9fda0/examples/sample-pack',
      searchText: 'Warm Scope Blue Shape scope geometry shape fixture',
      bundledAsset: 'assets/visualizer/milkrust-sample-pack-0.1.0.rmpack',
    ),
  ];
}
