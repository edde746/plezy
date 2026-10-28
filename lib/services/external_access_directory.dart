import '../media/media_kind.dart';
import '../integrations/integration_contracts.dart';
import 'book_identifiers.dart';

/// Types of title-aware provider lookups that can be handed off to an
/// official provider site. A lookup is not an availability or entitlement
/// result; the provider owns those facts.
enum ExternalAccessCategory { video, rentals, books, audiobooks, comics, music, games }

class ExternalAccessDestination {
  const ExternalAccessDestination({
    required this.id,
    required this.name,
    required this.category,
    required this.host,
    this.path = '/',
    this.queryParameter,
    this.fixedQuery = const {},
    this.accessModels = const {},
  });

  final String id;
  final String name;
  final ExternalAccessCategory category;
  final String host;
  final String path;
  final String? queryParameter;
  final Map<String, String> fixedQuery;

  /// Broad provider-level access models for directory organization only.
  /// These are not title availability, territory support, user entitlement,
  /// or a claim that PlezyNG can play the provider's content.
  final Set<ProviderAccessModel> accessModels;

  Uri searchUri(
    String title, {
    String creator = '',
    String region = 'CA',
    Map<String, String> identifiers = const {},
    Map<String, String> gamePlatformIds = const {},
  }) {
    final upperRegion = region.toUpperCase();
    final safeRegion = RegExp(r'^[A-Z]{2}$').hasMatch(upperRegion) ? upperRegion.toLowerCase() : 'ca';
    final cleanTitle = _cleanQuery(title);
    final cleanCreator = _cleanQuery(creator);
    final isbn = category == ExternalAccessCategory.books ? BookIdentifiers.preferred(identifiers) : null;
    final term = isbn ?? [cleanTitle, if (cleanCreator.isNotEmpty) cleanCreator].join(' ');
    if (id == 'steam-store') {
      final appId = gamePlatformIds['steam'];
      if (appId != null && RegExp(r'^[1-9]\d{0,9}$').hasMatch(appId)) {
        final parsed = int.tryParse(appId);
        if (parsed != null && parsed <= 0xffffffff) {
          return Uri.https(host, '/app/$parsed/');
        }
      }
    }
    return Uri.https(hostForRegion(safeRegion), pathForRegion(safeRegion), {
      ...fixedQuery,
      if (id == 'google-play-books') 'gl': safeRegion.toUpperCase(),
      if (queryParameter != null && term.isNotEmpty) queryParameter!: term,
    });
  }

  static String _cleanQuery(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ').trim();
    return cleaned.length <= 300 ? cleaned : cleaned.substring(0, 300);
  }

  String hostForRegion(String region) {
    if (id == 'amazon-books' || id == 'amazon-kindle' || id == 'comixology') {
      return switch (region) {
        'us' => 'www.amazon.com',
        'gb' => 'www.amazon.co.uk',
        'au' => 'www.amazon.com.au',
        'be' => 'www.amazon.com.be',
        'br' => 'www.amazon.com.br',
        'de' => 'www.amazon.de',
        'eg' => 'www.amazon.eg',
        'es' => 'www.amazon.es',
        'fr' => 'www.amazon.fr',
        'ie' => 'www.amazon.ie',
        'in' => 'www.amazon.in',
        'it' => 'www.amazon.it',
        'jp' => 'www.amazon.co.jp',
        'mx' => 'www.amazon.com.mx',
        'nl' => 'www.amazon.nl',
        'pl' => 'www.amazon.pl',
        'sa' => 'www.amazon.sa',
        'sg' => 'www.amazon.sg',
        'se' => 'www.amazon.se',
        'tr' => 'www.amazon.com.tr',
        'ae' => 'www.amazon.ae',
        _ => 'www.amazon.ca',
      };
    }
    if (id == 'audible') {
      return switch (region) {
        'us' => 'www.audible.com',
        'gb' => 'www.audible.co.uk',
        'au' => 'www.audible.com.au',
        'de' => 'www.audible.de',
        'fr' => 'www.audible.fr',
        'jp' => 'www.audible.co.jp',
        _ => 'www.audible.ca',
      };
    }
    if (id == 'amazon-music') {
      return switch (region) {
        'us' => 'music.amazon.com',
        'gb' => 'music.amazon.co.uk',
        'au' => 'music.amazon.com.au',
        'de' => 'music.amazon.de',
        'jp' => 'music.amazon.co.jp',
        _ => 'music.amazon.ca',
      };
    }
    return host;
  }

  String pathForRegion(String region) {
    if (id == 'apple-books' || id == 'apple-tv-plus' || id == 'apple-tv-store' || id == 'apple-music') {
      return '/$region/search';
    }
    if (id == 'xbox-store') return '/en-${region.toUpperCase()}/Search/Results';
    return path;
  }

  ProviderDefinition integrationDefinition(String region) {
    final normalizedRegion = RegExp(r'^[a-z]{2}$').hasMatch(region) ? region : 'ca';
    final entityKinds = switch (category) {
      ExternalAccessCategory.video || ExternalAccessCategory.rentals => const {
        IntegrationEntityKind.movie,
        IntegrationEntityKind.series,
        IntegrationEntityKind.season,
        IntegrationEntityKind.episode,
      },
      ExternalAccessCategory.books => const {IntegrationEntityKind.bookWork, IntegrationEntityKind.bookEdition},
      ExternalAccessCategory.audiobooks => const {
        IntegrationEntityKind.bookWork,
        IntegrationEntityKind.audiobookEdition,
      },
      ExternalAccessCategory.comics => const {
        IntegrationEntityKind.comicSeries,
        IntegrationEntityKind.comicIssue,
      },
      ExternalAccessCategory.music => const {
        IntegrationEntityKind.musicRelease,
        IntegrationEntityKind.musicRecording,
      },
      ExternalAccessCategory.games => const {IntegrationEntityKind.game, IntegrationEntityKind.gameEdition},
    };
    return ProviderDefinition(
      id: id,
      displayName: name,
      officialHosts: {host.toLowerCase(), hostForRegion(normalizedRegion).toLowerCase()},
      entityKinds: entityKinds,
      capabilities: const {ProviderCapability.officialHandoff},
      accessModels: accessModels,
    );
  }
}

/// Curated official destinations for title-level handoff. There are no
/// affiliate tags, scraped prices, credentials, or playback URLs here.
/// Partner approval and licensed catalog data are separate integration work.
abstract final class ExternalAccessDirectory {
  static const List<ExternalAccessDestination> all = [
    // Subscription and ad-supported video services outside the excluded scope.
    ExternalAccessDestination(
      id: 'crave',
      name: 'Crave',
      category: ExternalAccessCategory.video,
      host: 'www.crave.ca',
      path: '/en/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'max',
      name: 'Max',
      category: ExternalAccessCategory.video,
      host: 'www.max.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'paramount-plus',
      name: 'Paramount+',
      category: ExternalAccessCategory.video,
      host: 'www.paramountplus.com',
      path: '/search/',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'peacock',
      name: 'Peacock',
      category: ExternalAccessCategory.video,
      host: 'www.peacocktv.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'amc-plus',
      name: 'AMC+',
      category: ExternalAccessCategory.video,
      host: 'www.amcplus.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'starz',
      name: 'STARZ',
      category: ExternalAccessCategory.video,
      host: 'www.starz.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'shudder',
      name: 'Shudder',
      category: ExternalAccessCategory.video,
      host: 'www.shudder.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'discovery-plus',
      name: 'discovery+',
      category: ExternalAccessCategory.video,
      host: 'www.discoveryplus.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'hulu',
      name: 'Hulu',
      category: ExternalAccessCategory.video,
      host: 'www.hulu.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'apple-tv-plus',
      name: 'Apple TV',
      category: ExternalAccessCategory.video,
      host: 'tv.apple.com',
      path: '/search',
      queryParameter: 'term',
    ),
    ExternalAccessDestination(
      id: 'crunchyroll',
      name: 'Crunchyroll',
      category: ExternalAccessCategory.video,
      host: 'www.crunchyroll.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'hidive',
      name: 'HIDIVE',
      category: ExternalAccessCategory.video,
      host: 'www.hidive.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'mubi',
      name: 'MUBI',
      category: ExternalAccessCategory.video,
      host: 'mubi.com',
      path: '/search',
      queryParameter: 'query',
    ),
    ExternalAccessDestination(
      id: 'criterion-channel',
      name: 'The Criterion Channel',
      category: ExternalAccessCategory.video,
      host: 'www.criterionchannel.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'tubi',
      name: 'Tubi',
      category: ExternalAccessCategory.video,
      host: 'tubitv.com',
      path: '/search',
      queryParameter: 'query',
      accessModels: {ProviderAccessModel.freeAdSupported},
    ),
    ExternalAccessDestination(
      id: 'pluto-tv',
      name: 'Pluto TV',
      category: ExternalAccessCategory.video,
      host: 'pluto.tv',
      path: '/search',
      queryParameter: 'q',
      accessModels: {ProviderAccessModel.freeAdSupported},
    ),
    ExternalAccessDestination(
      id: 'cbc-gem',
      name: 'CBC Gem',
      category: ExternalAccessCategory.video,
      host: 'gem.cbc.ca',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'citytv-plus',
      name: 'Citytv+',
      category: ExternalAccessCategory.video,
      host: 'www.citytv.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'plex-streaming',
      name: 'Plex',
      category: ExternalAccessCategory.video,
      host: 'watch.plex.tv',
      path: '/search',
      queryParameter: 'q',
      accessModels: {
        ProviderAccessModel.freeAdSupported,
        ProviderAccessModel.subscription,
        ProviderAccessModel.transactional,
      },
    ),
    ExternalAccessDestination(
      id: 'youtube',
      name: 'YouTube',
      category: ExternalAccessCategory.video,
      host: 'www.youtube.com',
      path: '/results',
      queryParameter: 'search_query',
    ),
    ExternalAccessDestination(
      id: 'britbox',
      name: 'BritBox',
      category: ExternalAccessCategory.video,
      host: 'www.britbox.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'acorn-tv',
      name: 'Acorn TV',
      category: ExternalAccessCategory.video,
      host: 'acorn.tv',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'bfi-player',
      name: 'BFI Player',
      category: ExternalAccessCategory.video,
      host: 'player.bfi.org.uk',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'bbc-iplayer',
      name: 'BBC iPlayer',
      category: ExternalAccessCategory.video,
      host: 'www.bbc.co.uk',
      path: '/iplayer/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'itvx',
      name: 'ITVX',
      category: ExternalAccessCategory.video,
      host: 'www.itv.com',
      path: '/watch/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'channel-4',
      name: 'Channel 4',
      category: ExternalAccessCategory.video,
      host: 'www.channel4.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'stan',
      name: 'Stan',
      category: ExternalAccessCategory.video,
      host: 'www.stan.com.au',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'binge',
      name: 'Binge',
      category: ExternalAccessCategory.video,
      host: 'binge.com.au',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'abc-iview',
      name: 'ABC iview',
      category: ExternalAccessCategory.video,
      host: 'iview.abc.net.au',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'viki',
      name: 'Viki',
      category: ExternalAccessCategory.video,
      host: 'www.viki.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'iqiyi',
      name: 'iQIYI',
      category: ExternalAccessCategory.video,
      host: 'www.iq.com',
      path: '/search',
      queryParameter: 'query',
    ),
    ExternalAccessDestination(
      id: 'wetv',
      name: 'WeTV',
      category: ExternalAccessCategory.video,
      host: 'wetv.vip',
      path: '/search',
      queryParameter: 'keyword',
    ),
    ExternalAccessDestination(
      id: 'roku-channel',
      name: 'The Roku Channel',
      category: ExternalAccessCategory.video,
      host: 'therokuchannel.roku.com',
      path: '/search',
      queryParameter: 'query',
      accessModels: {
        ProviderAccessModel.freeAdSupported,
        ProviderAccessModel.subscription,
      },
    ),
    ExternalAccessDestination(
      id: 'samsung-tv-plus',
      name: 'Samsung TV Plus',
      category: ExternalAccessCategory.video,
      host: 'www.samsungtvplus.com',
      accessModels: {ProviderAccessModel.freeAdSupported},
    ),
    ExternalAccessDestination(
      id: 'xumo-play',
      name: 'Xumo Play',
      category: ExternalAccessCategory.video,
      host: 'play.xumo.com',
      path: '/search',
      queryParameter: 'q',
      accessModels: {ProviderAccessModel.freeAdSupported},
    ),
    ExternalAccessDestination(
      id: 'dazn',
      name: 'DAZN',
      category: ExternalAccessCategory.video,
      host: 'www.dazn.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'fubo',
      name: 'Fubo',
      category: ExternalAccessCategory.video,
      host: 'www.fubo.tv',
      path: '/welcome/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'sportsnet-plus',
      name: 'Sportsnet+',
      category: ExternalAccessCategory.video,
      host: 'www.sportsnetplus.ca',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'tsn',
      name: 'TSN',
      category: ExternalAccessCategory.video,
      host: 'www.tsn.ca',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'nfb',
      name: 'NFB / ONF',
      category: ExternalAccessCategory.video,
      host: 'www.nfb.ca',
      path: '/search',
      queryParameter: 'q',
    ),

    // Store and transactional rental destinations. A search link is not a
    // quote, an offer, or evidence that the exact edition is available.
    ExternalAccessDestination(
      id: 'apple-tv-store',
      name: 'Apple TV Store',
      category: ExternalAccessCategory.rentals,
      host: 'tv.apple.com',
      path: '/search',
      queryParameter: 'term',
    ),
    ExternalAccessDestination(
      id: 'youtube-movies',
      name: 'YouTube Movies',
      category: ExternalAccessCategory.rentals,
      host: 'www.youtube.com',
      path: '/results',
      queryParameter: 'search_query',
    ),
    ExternalAccessDestination(
      id: 'cineplex-store',
      name: 'Cineplex Store',
      category: ExternalAccessCategory.rentals,
      host: 'www.cineplex.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'fandango-at-home',
      name: 'Fandango at Home',
      category: ExternalAccessCategory.rentals,
      host: 'athome.fandango.com',
      path: '/content/browse',
      queryParameter: 'searchTerm',
    ),
    ExternalAccessDestination(
      id: 'rakuten-tv',
      name: 'Rakuten TV',
      category: ExternalAccessCategory.rentals,
      host: 'www.rakuten.tv',
      path: '/search',
      queryParameter: 'q',
    ),

    // Books and comics sold in common markets.
    ExternalAccessDestination(
      id: 'kobo',
      name: 'Kobo',
      category: ExternalAccessCategory.books,
      host: 'www.kobo.com',
      path: '/search',
      queryParameter: 'query',
    ),
    ExternalAccessDestination(
      id: 'amazon-books',
      name: 'Amazon Books',
      category: ExternalAccessCategory.books,
      host: 'www.amazon.ca',
      path: '/s',
      queryParameter: 'k',
      fixedQuery: {'i': 'stripbooks'},
    ),
    ExternalAccessDestination(
      id: 'amazon-kindle',
      name: 'Amazon Kindle Store',
      category: ExternalAccessCategory.books,
      host: 'www.amazon.ca',
      path: '/s',
      queryParameter: 'k',
      fixedQuery: {'i': 'digital-text'},
    ),
    ExternalAccessDestination(
      id: 'indigo',
      name: 'Indigo',
      category: ExternalAccessCategory.books,
      host: 'www.indigo.ca',
      path: '/en-ca/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'apple-books',
      name: 'Apple Books',
      category: ExternalAccessCategory.books,
      host: 'books.apple.com',
      path: '/ca/search',
      queryParameter: 'term',
    ),
    ExternalAccessDestination(
      id: 'google-play-books',
      name: 'Google Play Books',
      category: ExternalAccessCategory.books,
      host: 'play.google.com',
      path: '/store/search',
      queryParameter: 'q',
      fixedQuery: {'c': 'books'},
    ),
    ExternalAccessDestination(
      id: 'bookshop',
      name: 'Bookshop.org',
      category: ExternalAccessCategory.books,
      host: 'bookshop.org',
      path: '/search',
      queryParameter: 'keywords',
    ),
    ExternalAccessDestination(
      id: 'ebooks-com',
      name: 'eBooks.com',
      category: ExternalAccessCategory.books,
      host: 'www.ebooks.com',
      path: '/en-ca/searchall',
      queryParameter: 'term',
    ),
    ExternalAccessDestination(
      id: 'barnes-noble',
      name: 'Barnes & Noble',
      category: ExternalAccessCategory.books,
      host: 'www.barnesandnoble.com',
      path: '/s',
      queryParameter: 'Ntt',
    ),
    ExternalAccessDestination(
      id: 'waterstones',
      name: 'Waterstones',
      category: ExternalAccessCategory.books,
      host: 'www.waterstones.com',
      path: '/books/search/term',
      queryParameter: 'term',
    ),
    ExternalAccessDestination(
      id: 'blackwells',
      name: "Blackwell's",
      category: ExternalAccessCategory.books,
      host: 'blackwells.co.uk',
      path: '/bookshop/search',
      queryParameter: 'search',
    ),
    ExternalAccessDestination(
      id: 'abebooks',
      name: 'AbeBooks',
      category: ExternalAccessCategory.books,
      host: 'www.abebooks.com',
      path: '/servlet/SearchResults',
      queryParameter: 'kn',
    ),
    ExternalAccessDestination(
      id: 'better-world-books',
      name: 'Better World Books',
      category: ExternalAccessCategory.books,
      host: 'www.betterworldbooks.com',
      path: '/search/results',
      queryParameter: 'searchTerm',
      fixedQuery: {'searchType': 'title'},
    ),
    ExternalAccessDestination(
      id: 'thriftbooks',
      name: 'ThriftBooks',
      category: ExternalAccessCategory.books,
      host: 'www.thriftbooks.com',
      path: '/b/',
      queryParameter: 'searchterm',
    ),
    ExternalAccessDestination(
      id: 'booktopia',
      name: 'Booktopia',
      category: ExternalAccessCategory.books,
      host: 'www.booktopia.com.au',
      path: '/search.ep',
      queryParameter: 'keywords',
    ),
    ExternalAccessDestination(
      id: 'gutenberg',
      name: 'Project Gutenberg',
      category: ExternalAccessCategory.books,
      host: 'www.gutenberg.org',
      path: '/ebooks/search/',
      queryParameter: 'query',
    ),

    // Audiobook stores and subscription catalogs. Purchased files are
    // imported only from a user's official compatible download.
    ExternalAccessDestination(
      id: 'libro-fm',
      name: 'Libro.fm',
      category: ExternalAccessCategory.audiobooks,
      host: 'libro.fm',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'audible',
      name: 'Audible',
      category: ExternalAccessCategory.audiobooks,
      host: 'www.audible.ca',
      path: '/search',
      queryParameter: 'keywords',
    ),
    ExternalAccessDestination(
      id: 'audiobooks-com',
      name: 'Audiobooks.com',
      category: ExternalAccessCategory.audiobooks,
      host: 'www.audiobooks.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'chirp',
      name: 'Chirp',
      category: ExternalAccessCategory.audiobooks,
      host: 'www.chirpbooks.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'downpour',
      name: 'Downpour',
      category: ExternalAccessCategory.audiobooks,
      host: 'www.downpour.com',
      path: '/catalogsearch/result',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'kobo-audiobooks',
      name: 'Kobo Audiobooks',
      category: ExternalAccessCategory.audiobooks,
      host: 'www.kobo.com',
      path: '/search',
      queryParameter: 'query',
    ),
    ExternalAccessDestination(
      id: 'spotify-audiobooks',
      name: 'Spotify Audiobooks',
      category: ExternalAccessCategory.audiobooks,
      host: 'open.spotify.com',
      path: '/search',
      queryParameter: 'q',
    ),

    // Comic services use official catalog/reader destinations only.
    ExternalAccessDestination(
      id: 'globalcomix',
      name: 'GlobalComix',
      category: ExternalAccessCategory.comics,
      host: 'globalcomix.com',
      path: '/search',
      queryParameter: 'keyword',
    ),
    ExternalAccessDestination(
      id: 'marvel-unlimited',
      name: 'Marvel Unlimited',
      category: ExternalAccessCategory.comics,
      host: 'www.marvel.com',
      path: '/comics/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'dc-universe-infinite',
      name: 'DC Universe Infinite',
      category: ExternalAccessCategory.comics,
      host: 'www.dcuniverseinfinite.com',
      path: '/comics',
      queryParameter: 'search',
    ),
    ExternalAccessDestination(
      id: 'manga-plus',
      name: 'MANGA Plus',
      category: ExternalAccessCategory.comics,
      host: 'mangaplus.shueisha.co.jp',
      path: '/titles',
      queryParameter: 'title',
    ),
    ExternalAccessDestination(
      id: 'viz',
      name: 'VIZ',
      category: ExternalAccessCategory.comics,
      host: 'www.viz.com',
      path: '/search',
      queryParameter: 'search',
    ),
    ExternalAccessDestination(
      id: 'comixology',
      name: 'Kindle Comics',
      category: ExternalAccessCategory.comics,
      host: 'www.amazon.ca',
      path: '/s',
      queryParameter: 'k',
      fixedQuery: {'i': 'digital-text'},
    ),
    ExternalAccessDestination(
      id: 'webtoon',
      name: 'WEBTOON',
      category: ExternalAccessCategory.comics,
      host: 'www.webtoons.com',
      path: '/en/search',
      queryParameter: 'keyword',
    ),

    // Music catalogs and creator stores; playback remains owned by the
    // provider or the user's connected/self-hosted music source.
    ExternalAccessDestination(
      id: 'apple-music',
      name: 'Apple Music',
      category: ExternalAccessCategory.music,
      host: 'music.apple.com',
      path: '/ca/search',
      queryParameter: 'term',
    ),
    ExternalAccessDestination(
      id: 'spotify',
      name: 'Spotify',
      category: ExternalAccessCategory.music,
      host: 'open.spotify.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'amazon-music',
      name: 'Amazon Music',
      category: ExternalAccessCategory.music,
      host: 'music.amazon.ca',
      path: '/search',
      queryParameter: 'k',
    ),
    ExternalAccessDestination(
      id: 'tidal',
      name: 'TIDAL',
      category: ExternalAccessCategory.music,
      host: 'listen.tidal.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'qobuz',
      name: 'Qobuz',
      category: ExternalAccessCategory.music,
      host: 'www.qobuz.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'soundcloud',
      name: 'SoundCloud',
      category: ExternalAccessCategory.music,
      host: 'soundcloud.com',
      path: '/search/sounds',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'bandcamp',
      name: 'Bandcamp',
      category: ExternalAccessCategory.music,
      host: 'bandcamp.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'deezer',
      name: 'Deezer',
      category: ExternalAccessCategory.music,
      host: 'www.deezer.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'youtube-music',
      name: 'YouTube Music',
      category: ExternalAccessCategory.music,
      host: 'music.youtube.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'tunein',
      name: 'TuneIn',
      category: ExternalAccessCategory.music,
      host: 'tunein.com',
      path: '/search',
      queryParameter: 'query',
    ),
    ExternalAccessDestination(
      id: 'pandora',
      name: 'Pandora',
      category: ExternalAccessCategory.music,
      host: 'www.pandora.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'iheartradio',
      name: 'iHeartRadio',
      category: ExternalAccessCategory.music,
      host: 'www.iheart.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'siriusxm',
      name: 'SiriusXM',
      category: ExternalAccessCategory.music,
      host: 'www.siriusxm.com',
      path: '/search',
      queryParameter: 'q',
    ),

    // Game storefront lookups. A listing never grants ownership or a launch
    // route on an installed host.
    ExternalAccessDestination(
      id: 'steam-store',
      name: 'Steam Store',
      category: ExternalAccessCategory.games,
      host: 'store.steampowered.com',
      path: '/search/',
      queryParameter: 'term',
    ),
    ExternalAccessDestination(
      id: 'gog',
      name: 'GOG',
      category: ExternalAccessCategory.games,
      host: 'www.gog.com',
      path: '/en/games',
      queryParameter: 'query',
    ),
    ExternalAccessDestination(
      id: 'fanatical',
      name: 'Fanatical',
      category: ExternalAccessCategory.games,
      host: 'www.fanatical.com',
      path: '/en/search',
      queryParameter: 'search',
    ),
    ExternalAccessDestination(
      id: 'humble-store',
      name: 'Humble Store',
      category: ExternalAccessCategory.games,
      host: 'www.humblebundle.com',
      path: '/store/search',
      queryParameter: 'search',
    ),
    ExternalAccessDestination(
      id: 'epic-games',
      name: 'Epic Games Store',
      category: ExternalAccessCategory.games,
      host: 'store.epicgames.com',
      path: '/browse',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'xbox-store',
      name: 'Xbox Store',
      category: ExternalAccessCategory.games,
      host: 'www.xbox.com',
      path: '/en-CA/Search/Results',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'playstation-store',
      name: 'PlayStation Store',
      category: ExternalAccessCategory.games,
      host: 'store.playstation.com',
      path: '/en-ca/search',
      queryParameter: 'query',
    ),
    ExternalAccessDestination(
      id: 'nintendo-store',
      name: 'Nintendo eShop',
      category: ExternalAccessCategory.games,
      host: 'www.nintendo.com',
      path: '/search',
      queryParameter: 'q',
    ),
    ExternalAccessDestination(
      id: 'itch',
      name: 'itch.io',
      category: ExternalAccessCategory.games,
      host: 'itch.io',
      path: '/search',
      queryParameter: 'q',
    ),
  ];

  static List<ExternalAccessDestination> forCategory(ExternalAccessCategory category) =>
      all.where((destination) => destination.category == category).toList(growable: false);

  /// The directory entries that identify services with a general free,
  /// ad-supported offering. This is deliberately provider-level metadata; the
  /// destination must still confirm a title's availability in the selected
  /// country and whether it is free for the user.
  static List<ExternalAccessDestination> get freeAdSupportedVideo => all
      .where(
        (destination) =>
            destination.category == ExternalAccessCategory.video &&
            destination.accessModels.contains(ProviderAccessModel.freeAdSupported),
      )
      .toList(growable: false);

  /// Catalog providers may return third-party streaming links. Keep these
  /// three services outside PlezyNG's discovery and launch surface.
  static bool isExcludedStreamingLink({required String label, required String url}) {
    final normalizedLabel = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    bool isHost(String domain) => host == domain || host.endsWith('.$domain');
    return normalizedLabel == 'netflix' ||
        normalizedLabel == 'primevideo' ||
        normalizedLabel == 'amazonprimevideo' ||
        normalizedLabel == 'disneyplus' ||
        isHost('netflix.com') ||
        isHost('primevideo.com') ||
        (isHost('amazon.com') && normalizedLabel.contains('primevideo')) ||
        isHost('disneyplus.com') ||
        isHost('disneyplus.net');
  }

  static ExternalAccessCategory? forMediaKind(MediaKind kind) => switch (kind) {
    MediaKind.movie ||
    MediaKind.show ||
    MediaKind.season ||
    MediaKind.episode ||
    MediaKind.clip => ExternalAccessCategory.video,
    MediaKind.artist || MediaKind.album || MediaKind.track => ExternalAccessCategory.music,
    _ => null,
  };
}
