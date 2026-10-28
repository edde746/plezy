///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:plezy/i18n/locale_preferences.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsMs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsMs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ms,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ms>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsMs _root = this; // ignore: unused_field

	@override 
	TranslationsMs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsMs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ms app = _Translations$app$ms._(_root);
	@override late final _Translations$appIcon$ms appIcon = _Translations$appIcon$ms._(_root);
	@override late final _Translations$auth$ms auth = _Translations$auth$ms._(_root);
	@override late final _Translations$common$ms common = _Translations$common$ms._(_root);
	@override late final _Translations$screens$ms screens = _Translations$screens$ms._(_root);
	@override late final _Translations$update$ms update = _Translations$update$ms._(_root);
	@override late final _Translations$settings$ms settings = _Translations$settings$ms._(_root);
	@override late final _Translations$themeEditor$ms themeEditor = _Translations$themeEditor$ms._(_root);
	@override late final _Translations$search$ms search = _Translations$search$ms._(_root);
	@override late final _Translations$hotkeys$ms hotkeys = _Translations$hotkeys$ms._(_root);
	@override late final _Translations$fileInfo$ms fileInfo = _Translations$fileInfo$ms._(_root);
	@override late final _Translations$mediaMenu$ms mediaMenu = _Translations$mediaMenu$ms._(_root);
	@override late final _Translations$rateSheet$ms rateSheet = _Translations$rateSheet$ms._(_root);
	@override late final _Translations$accessibility$ms accessibility = _Translations$accessibility$ms._(_root);
	@override late final _Translations$tooltips$ms tooltips = _Translations$tooltips$ms._(_root);
	@override late final _Translations$audioTracks$ms audioTracks = _Translations$audioTracks$ms._(_root);
	@override late final _Translations$videoControls$ms videoControls = _Translations$videoControls$ms._(_root);
	@override late final _Translations$messages$ms messages = _Translations$messages$ms._(_root);
	@override late final _Translations$subtitlingStyling$ms subtitlingStyling = _Translations$subtitlingStyling$ms._(_root);
	@override late final _Translations$mpvConfig$ms mpvConfig = _Translations$mpvConfig$ms._(_root);
	@override late final _Translations$dialog$ms dialog = _Translations$dialog$ms._(_root);
	@override late final _Translations$profiles$ms profiles = _Translations$profiles$ms._(_root);
	@override late final _Translations$connections$ms connections = _Translations$connections$ms._(_root);
	@override late final _Translations$accountPreferences$ms accountPreferences = _Translations$accountPreferences$ms._(_root);
	@override late final _Translations$discover$ms discover = _Translations$discover$ms._(_root);
	@override late final _Translations$errors$ms errors = _Translations$errors$ms._(_root);
	@override late final _Translations$libraries$ms libraries = _Translations$libraries$ms._(_root);
	@override late final _Translations$about$ms about = _Translations$about$ms._(_root);
	@override late final _Translations$serverSelection$ms serverSelection = _Translations$serverSelection$ms._(_root);
	@override late final _Translations$hubDetail$ms hubDetail = _Translations$hubDetail$ms._(_root);
	@override late final _Translations$logs$ms logs = _Translations$logs$ms._(_root);
	@override late final _Translations$startup$ms startup = _Translations$startup$ms._(_root);
	@override late final _Translations$licenses$ms licenses = _Translations$licenses$ms._(_root);
	@override late final _Translations$navigation$ms navigation = _Translations$navigation$ms._(_root);
	@override late final _Translations$explore$ms explore = _Translations$explore$ms._(_root);
	@override late final _Translations$liveTv$ms liveTv = _Translations$liveTv$ms._(_root);
	@override late final _Translations$collections$ms collections = _Translations$collections$ms._(_root);
	@override late final _Translations$playlists$ms playlists = _Translations$playlists$ms._(_root);
	@override late final _Translations$music$ms music = _Translations$music$ms._(_root);
	@override late final _Translations$watchTogether$ms watchTogether = _Translations$watchTogether$ms._(_root);
	@override late final _Translations$downloads$ms downloads = _Translations$downloads$ms._(_root);
	@override late final _Translations$shaders$ms shaders = _Translations$shaders$ms._(_root);
	@override late final _Translations$companionRemote$ms companionRemote = _Translations$companionRemote$ms._(_root);
	@override late final _Translations$videoSettings$ms videoSettings = _Translations$videoSettings$ms._(_root);
	@override late final _Translations$performanceOverlay$ms performanceOverlay = _Translations$performanceOverlay$ms._(_root);
	@override late final _Translations$externalPlayer$ms externalPlayer = _Translations$externalPlayer$ms._(_root);
	@override late final _Translations$metadataEdit$ms metadataEdit = _Translations$metadataEdit$ms._(_root);
	@override late final _Translations$matchScreen$ms matchScreen = _Translations$matchScreen$ms._(_root);
	@override late final _Translations$serverTasks$ms serverTasks = _Translations$serverTasks$ms._(_root);
	@override late final _Translations$trakt$ms trakt = _Translations$trakt$ms._(_root);
	@override late final _Translations$seerr$ms seerr = _Translations$seerr$ms._(_root);
	@override late final _Translations$services$ms services = _Translations$services$ms._(_root);
	@override late final _Translations$addServer$ms addServer = _Translations$addServer$ms._(_root);
	@override late final _Translations$cast$ms cast = _Translations$cast$ms._(_root);
	@override late final _Translations$automation$ms automation = _Translations$automation$ms._(_root);
	@override late final _Translations$notifications$ms notifications = _Translations$notifications$ms._(_root);
	@override late final _Translations$appAccess$ms appAccess = _Translations$appAccess$ms._(_root);
	@override late final _Translations$detail$ms detail = _Translations$detail$ms._(_root);
	@override late final _Translations$watchLink$ms watchLink = _Translations$watchLink$ms._(_root);
	@override late final _Translations$homeLayout$ms homeLayout = _Translations$homeLayout$ms._(_root);
	@override late final _Translations$platform$ms platform = _Translations$platform$ms._(_root);
	@override late final _Translations$universalMedia$ms universalMedia = _Translations$universalMedia$ms._(_root);
	@override late final _Translations$fileSources$ms fileSources = _Translations$fileSources$ms._(_root);
	@override late final _Translations$lending$ms lending = _Translations$lending$ms._(_root);
	@override late final _Translations$audiobook$ms audiobook = _Translations$audiobook$ms._(_root);
	@override late final _Translations$sourceSetup$ms sourceSetup = _Translations$sourceSetup$ms._(_root);
	@override late final _Translations$comics$ms comics = _Translations$comics$ms._(_root);
	@override late final _Translations$games$ms games = _Translations$games$ms._(_root);
	@override late final _Translations$deepLinks$ms deepLinks = _Translations$deepLinks$ms._(_root);
	@override late final _Translations$householdSetup$ms householdSetup = _Translations$householdSetup$ms._(_root);
	@override late final _Translations$issueReport$ms issueReport = _Translations$issueReport$ms._(_root);
}

// Path: app
class _Translations$app$ms extends Translations$app$en {
	_Translations$app$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$ms extends Translations$appIcon$en {
	_Translations$appIcon$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icon Permohonan';
	@override String get defaultIcon => 'Perkataan default';
	@override String get current => 'Ikon semasa';
	@override String get locked => 'Akses seumur hidup diperlukan';
	@override String get lockedHint => 'Mulakan percubaan 7 hari anda atau membuka kunci PlezyNG sepanjang hayat anda untuk menggunakan ikon alternatif.';
	@override String get changeFailed => 'Tidak boleh mengubah ikon app';
	@override String get launcherHint => 'Ikon baru muncul pada skrin rumah anda apabila anda meninggalkan PlezyNG.';
	@override String get tvLauncherHint => 'Banner baru muncul apabila anda meninggalkan PlezyNG. Android TV boleh terus menunjukkan yang lama sehingga TV bermula semula.';
	@override late final _Translations$appIcon$names$ms names = _Translations$appIcon$names$ms._(_root);
	@override String get description => 'Pilih ikon yang ditunjukkan oleh pelancaran peranti anda. previews menunjukkan bagaimana setiap opsyen kelihatan.';
}

// Path: auth
class _Translations$auth$ms extends Translations$auth$en {
	_Translations$auth$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Mendaftar dengan Plex';
	@override String get showQRCode => 'Menunjukkan kod QR';
	@override String get authenticate => 'Autentik';
	@override String get authenticationTimeout => 'Pengesahan telah tiba.Sila cuba lagi.';
	@override String get scanQRToSignIn => 'Mengimbas kod QR ini untuk mendaftar';
	@override String get waitingForAuth => 'Menunggu untuk pengesahan ... Mendaftar masuk daripada pelayar anda.';
	@override String get useBrowser => 'Penggunaan Browser';
	@override String get or => 'atau';
	@override String connectToMediaBrowser({required Object product}) => 'Hubungi ${product}';
	@override String get quickConnect => 'Sambung Pantas';
	@override String get useQuickConnect => 'Gunakan Sambungan Pantas';
	@override String get quickConnectInstructions => 'Buka Quick Connect dalam Jellyfin dan masukkan kod ini.';
	@override String get quickConnectWaiting => 'Menunggu kelulusan...';
	@override String get quickConnectCancel => 'Batalkan';
	@override String get quickConnectExpired => 'Sambungan Pantas telah tamat tempoh. Cuba lagi.';
	@override String get localDataRecoveryRequired => 'PlezyNG tidak dapat memulihkan maklumat log masuk tempatan dan data main balik yang belum diproses dengan selamat. Sila log masuk semula.';
	@override String get pinCheckRejected => 'Pendaftaran PIN Plex ditolak';
	@override String get connectToDirectPlex => 'Menyambung ke pelayan tempatan Plex';
}

// Path: common
class _Translations$common$ms extends Translations$common$en {
	_Translations$common$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Batalkan';
	@override String get save => 'menyelamatkan';
	@override String get close => 'Tutup';
	@override String get closeMiniPlayer => 'Berhampiran Mini Pemain';
	@override String get closeWorkspaceWindow => 'tetingkap terdekat';
	@override String get returnToFullView => 'Kembali ke pandangan penuh';
	@override String get manageMediaSessions => 'Menguruskan sesi media';
	@override String get hideMediaSessions => 'Menyembunyikan sesi media';
	@override String get mediaSessions => 'Mesyuarat Media';
	@override String get mediaSessionsHint => 'Pilih untuk membawa sesi ke hadapan.Park menyembunyikan tetingkap tetapi mengekalkannya terbuka.Kembali membuka ia dalam pandangan penuh; berhampiran menamatkannya.';
	@override String get sessionInWorkspace => 'dalam ruang kerja';
	@override String get sessionParked => 'tempat letak kereta';
	@override String get sessionFullscreen => 'skrin penuh';
	@override String get switchToNextWindow => 'Tukar dengan tetingkap seterusnya';
	@override String get moveWindow => 'Pergerakan tingkap';
	@override String get finishMovingWindow => 'Menamatkan tetingkap bergerak';
	@override String get moveWindowHint => 'Tekan panjang dan tarik tetingkap untuk memindahkannya. kawalan ini juga membolehkan pergerakan kunci tiang.';
	@override String get movingWindowHelp => 'Tarik ke bergerak · Tarik kunci disesuaikan · Enter saves · Melarikan diri membatalkan';
	@override String get resizeWindow => 'Menyelesaikan tetingkap';
	@override String get resizeWindowHint => 'Tarik tangan ini atau gunakan kunci anak panah untuk memutar semula tetingkap.';
	@override String get workspaceWindowHint => 'Gunakan kawalan pergerakan atau tekanan panjang dan tarik untuk bergerak.';
	@override String get workspacePaneHint => 'Pilih panel ini untuk memberi tumpuan kepada ia. gunakan kawalan skrin penuh untuk mengembangkan.';
	@override String workspaceWindowLabel({required Object title}) => 'Jendela sesi: ${title}';
	@override String get workspaceTitleHint => 'Tarik bar tajuk untuk bergerak; gunakan butang skrin penuh untuk mengembangkan.';
	@override String get moveToSessionTray => 'Bergerak ke sesi tray';
	@override String get moveToSessionTrayHint => 'Keep sesi ini boleh didapati tanpa menunjukkan tetingkapnya.';
	@override String get closeSessionHint => 'Menutup tetingkap ini dan menamatkan sesi.';
	@override String get sideBySideLayout => 'Tukar kepada layout side-by-side';
	@override String get floatingWindows => 'Switch untuk mengalir tetingkap';
	@override String get clear => 'jelas';
	@override String get reset => 'Kembali ke';
	@override String get later => 'Kemudian';
	@override String get submit => 'Hantar';
	@override String get confirm => 'mengesahkan';
	@override String get retry => 'Kembali';
	@override String get logout => 'Log keluar';
	@override String get unknown => 'yang tidak diketahui';
	@override String get refresh => 'Menyejukkan';
	@override String get yes => 'Ya';
	@override String get no => 'Tidak';
	@override String get delete => 'Padam';
	@override String get edit => 'Sunting';
	@override String get shuffle => 'Rawak';
	@override String get addTo => 'Tambah kepada...';
	@override String get createNew => 'Mencipta yang baru';
	@override String get connect => 'Sambung';
	@override String get disconnect => 'Putuskan sambungan';
	@override String get play => 'Mainkan';
	@override String get pause => 'Henti Sejenak';
	@override String get resume => 'Sambung semula';
	@override String get error => 'Ralat';
	@override String get search => 'Pencarian';
	@override String get home => 'rumah';
	@override String get back => 'Kembali';
	@override String get settings => 'Tetapan';
	@override String get mute => 'Mutu';
	@override String get ok => 'Ok';
	@override String get off => 'Dimatikan';
	@override String get options => 'Pilihan';
	@override String seasonNumber({required Object number}) => 'Tarikh : ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Bahagian ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Perbincangan ${number}';
	@override String get reconnect => 'Sambungan semula';
	@override String get viewAll => 'Lihat semua';
	@override String get checkingNetwork => 'Rangkaian pemeriksaan ...';
	@override String get loadingServers => 'Pelayan Pengecasan ...';
	@override String get connectingToServers => 'Menyambung ke pelayan ...';
	@override String get startingOfflineMode => 'Bermula dengan mod offline.';
	@override String get loading => 'Pengangkutan...';
	@override String get fullscreen => 'Paparan skrin penuh';
	@override String get exitFullscreen => 'Keluarkan skrin penuh';
	@override String get pressBackAgainToExit => 'Tekan balik lagi untuk keluar';
	@override late final _Translations$common$ratingSource$ms ratingSource = _Translations$common$ratingSource$ms._(_root);
	@override String get notAvailable => 'N / A';
	@override String get url => 'URL';
	@override String get letterKeys => 'Tag : ABC';
	@override late final _Translations$common$mediaKind$ms mediaKind = _Translations$common$mediaKind$ms._(_root);
}

// Path: screens
class _Translations$screens$ms extends Translations$screens$en {
	_Translations$screens$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Permohonan';
	@override String get switchProfile => 'Profil Switch';
	@override String get subtitleStyling => 'Subtitle Pengurusan';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs yang';
}

// Path: update
class _Translations$update$ms extends Translations$update$en {
	_Translations$update$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update yang tersedia';
	@override String versionAvailable({required Object version}) => 'Versi ${version} boleh didapati';
	@override String currentVersion({required Object version}) => 'Jumlah : ${version}';
	@override String get skipVersion => 'Hentikan versi ini';
	@override String get viewRelease => 'Lihat pelancaran';
	@override String get latestVersion => 'Anda berada dalam versi terkini';
	@override String get checkFailed => 'Tidak boleh memeriksa untuk update';
}

// Path: settings
class _Translations$settings$ms extends Translations$settings$en {
	_Translations$settings$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tetapan';
	@override String get supportDeveloper => 'Perkhidmatan PlezyNG';
	@override String get supportDeveloperDescription => 'Memberi sumbangan untuk menyokong pembangunan';
	@override String get lifetimeAccess => 'PlezyNG akses seumur hidup';
	@override String get language => 'Bahasa Melayu';
	@override String get theme => 'Subjek';
	@override String get appearance => 'Penampilan';
	@override String get detailPage => 'Halaman terperinci';
	@override String get themeSongsEnabled => 'Main lagu tema';
	@override String get themeSongsEnabledDescription => 'Mainkan lagu tema yang tersedia sambil melihat butiran media.';
	@override String get themeSongVolume => 'Kumpulan Lagu Volume';
	@override String get videoPlayback => 'Video untuk Playback';
	@override String get videoPlaybackDescription => 'Mengesetkan tingkah laku playback';
	@override String get advanced => 'Kemajuan';
	@override String get episodePosterMode => 'Gambar Poster Gaya';
	@override String get seriesPoster => 'Poster siri';
	@override String get seasonPoster => 'Poster Musim';
	@override String get episodeThumbnail => 'Tumbnail';
	@override String get showHeroSectionDescription => 'Menampilkan kandungan karousel pada skrin rumah';
	@override String get secondsLabel => 'Sekejap';
	@override String get minutesLabel => 'Minit';
	@override String get secondsShort => 's s';
	@override String get minutesShort => 'M ialah';
	@override String durationHint({required Object min, required Object max}) => 'Masukkan nilai (${min}-${max})';
	@override String get systemTheme => 'Sistem';
	@override String get lightTheme => 'cahaya';
	@override String get darkTheme => 'kegelapan';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'orang';
	@override String get glacierTheme => 'Gletser';
	@override String get forestTheme => 'hutan';
	@override String get plumTheme => 'Ungu plum';
	@override String get paperTheme => 'kertas';
	@override String get libraryDensity => 'Ketebalan perpustakaan';
	@override String get displayScale => 'Skala Pameran';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'selesa';
	@override String get gridSpacing => 'Rangkaian Spacing';
	@override String get gridSpacingTight => 'Tight untuk';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'ruang';
	@override String get tvCornerSpotlightBackdrop => 'Tag: latar belakang spotlight backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'Tunjukkan spotlight artwork di sudut kanan atas bukannya mengisi skrin';
	@override String get viewMode => 'Lihat Mode';
	@override String get gridView => 'Rangkaian';
	@override String get listView => 'Senarai';
	@override String get showHeroSection => 'Menampilkan Hero Seksyen';
	@override String get showHomeBackdrop => 'Menunjukkan rumah backdrop artwork';
	@override String get showHomeBackdropDescription => 'Tunjukkan karya seni besar di belakang rangkaian rumah yang ditampilkan';
	@override String get contentScreensaverEnabled => 'Perkhidmatan Screensaver';
	@override String get contentScreensaverEnabledDescription => 'Tunjukkan karya seni skrin penuh selepas aplikasi telah menjadi idle';
	@override String get contentScreensaverDelay => 'Memulakan screensaver selepas';
	@override String get contentScreensaverLibraries => 'Perpustakaan Screensaver';
	@override String get contentScreensaverLibrariesDescription => 'Pilih perpustakaan mana yang menyediakan karya seni pemantauan skrin.Jika tiada yang dipilih, karya seni dari semua perpustakaan digunakan.';
	@override String get contentScreensaverAllLibraries => 'Semua pustaka';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} perpustakaan terpilih';
	@override String get contentScreensaverNoLibraries => 'Tiada perpustakaan media yang disambungkan tersedia.';
	@override String get contentScreensaverDismissHint => 'Tekan butang atau ketik untuk membatalkan';
	@override String get newEpisodeNotifications => 'Pemberitahuan episod baru';
	@override String get newEpisodeNotificationsDescription => 'Peringatan apabila episod baru ditambah kepada persembahan yang anda terperangkap. semak sementara Plezy dibuka.';
	@override String get continueWatchingRowSize => 'Lihat lagi reviu untuk Range Size';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} kad';
	@override String get rowSizeCompact => 'Kompakt';
	@override String get rowSizeStandard => 'standard';
	@override String get rowSizeLarge => 'besar';
	@override String get continueWatchingAction => 'Lanjutkan pengawasan tindakan';
	@override String get continueWatchingPlay => 'Bermain';
	@override String get continueWatchingDetails => 'Maklumat Terbuka';
	@override String get episodeAction => 'Tindakan episod';
	@override String get episodePlay => 'Bermain';
	@override String get episodeDetails => 'Maklumat Terbuka';
	@override String get useGlobalHubs => 'Menggunakan Home Layout';
	@override String get useGlobalHubsDescription => 'Tunjukkan hub rumah bersatu. jika tidak, gunakan cadangan perpustakaan.';
	@override String get showServerNameOnHubs => 'Tunjukkan nama pelayan pada Hubs';
	@override String get showServerNameOnHubsDescription => 'Selalu tunjukkan nama pelayan dalam tajuk hub.';
	@override String get groupLibrariesByServer => 'Perpustakaan Perpustakaan oleh Server';
	@override String get groupLibrariesByServerDescription => 'Kumpulan halaman perpustakaan di bawah setiap pelayan media.';
	@override String get alwaysKeepSidebarOpen => 'Sentiasa buka sidebar';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidebar kekal diperluaskan dan kawasan kandungan disesuaikan untuk menyesuaikan';
	@override String get showUnwatchedCount => 'Tunjukkan Unwatched Count';
	@override String get showUnwatchedCountDescription => 'Menampilkan episod yang tidak dilihat mengira pada persembahan dan musim';
	@override String get showWatchedIndicators => 'Menunjukkan indikator yang dilihat';
	@override String get showWatchedIndicatorsDescription => 'Tunjukkan tanda semak pada filem, persembahan, dan episod yang dilihat';
	@override String get showEpisodeNumberOnCards => 'Tunjukkan nombor episod pada kad';
	@override String get showEpisodeNumberOnCardsDescription => 'Tunjukkan musim dan nombor episod pada kad episod';
	@override String get showSeasonPostersOnTabs => 'Tunjukkan Poster Musim di Tabs';
	@override String get showSeasonPostersOnTabsDescription => 'Tunjukkan poster setiap musim di atas tabnya';
	@override String get tvFullCardLayout => 'Kertas TV penuh';
	@override String get tvFullCardLayoutDescription => 'Gunakan kad TV imej sahaja dengan nama pelakon yang terlepas';
	@override String get focusGlow => 'Perbincangan Glow';
	@override String get focusGlowDescription => 'Tekan cahaya lembut di sekeliling kad fokus';
	@override String get visualEffects => 'Kesan visual';
	@override String get visualEffectsAuto => 'Kereta';
	@override String get visualEffectsAutoDescription => 'Mengurangkan kesan secara automatik pada peranti kuasa rendah';
	@override String get visualEffectsFull => 'penuh';
	@override String get visualEffectsReduced => 'dikurangkan';
	@override String get visualEffectsReducedDescription => 'Kurang animasi dan karya seni resolusi rendah';
	@override String get hideSpoilers => 'Menyembunyikan spoilers untuk episod yang tidak dipantau';
	@override String get hideSpoilersDescription => 'Blur miniatur dan deskripsi untuk episod yang tidak dilihat';
	@override String get playerBackend => 'Penyertaan Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Perkakasan decoding';
	@override String get hardwareDecodingDescription => 'Menggunakan kelajuan perkakasan apabila tersedia';
	@override String get playbackBuffer => 'Perbincangan:Playback Buffer';
	@override String get playbackBufferAuto => 'Kereta yang disyorkan (';
	@override String get playbackBufferLarge => 'besar';
	@override String get playbackBufferExtraLarge => 'Terlalu besar';
	@override String get playbackBufferDescription => 'Buffer lebih daripada sambungan yang tidak stabil. juga terhad oleh Buffer Size.';
	@override String get streamBufferSize => 'Saiz Buffer';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Berapa banyak video yang perlu dimuat naik ke hadapan apabila memainkan secara langsung. transcodes berhenti di buffer transcode sendiri pelayan. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Menggantikan Playback Buffer apabila ditetapkan, capped pada separuh had memori aplikasi';
	@override String get streamBufferMegabytes => 'Megabytes';
	@override String get defaultQualityTitle => 'Kualiti lalai';
	@override String get cellularQualityTitle => 'Kualiti yang rendah pada sel';
	@override String get remoteQualityTitle => 'Kualiti Streaming Jarak Jauh';
	@override String get remoteQualitySameAsDefault => 'Sama seperti kualiti default';
	@override String get cellularQualitySameAsDefault => 'Sama seperti kualiti lalai';
	@override String get directPlayCoveredQuality => 'Mainkan Video Kecil Dengan Kualiti Asli';
	@override String get directPlayCoveredQualityDescription => 'Mainkan video secara langsung dalam had kualiti daripada menyulitkan mereka';
	@override String get videoCodecs => 'Video Kodek';
	@override String get videoCodecsDescription => 'Kodek yang tidak disemak disulitkan oleh pelayan';
	@override String get videoCodecsAlwaysAccepted => 'Selalu diterima';
	@override String get musicQualityTitle => 'Kualiti muzik';
	@override String get subtitleStyling => 'Subtitle Pengurusan';
	@override String get subtitleStylingDescription => 'Menerapkan penampilan subtitle';
	@override String get smallSkipDuration => 'Tempoh Skik Kecil';
	@override String get largeSkipDuration => 'Jangka Panjang Skik';
	@override String get rewindOnResume => 'Kembali ke Resume';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} saat',
	);
	@override String get defaultSleepTimer => 'Tempoh Tidur Default';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minit',
	);
	@override String get rememberTrackSelections => 'Ingat pilihan trek per persembahan/filem';
	@override String get chooseTracksBeforePlayback => 'Pilih audio dan subtitle sebelum playback';
	@override String get chooseTracksBeforePlaybackDescription => 'Pilih sumber audio dan subtitle trek sebelum setiap video bermula.';
	@override String get alwaysShowSubtitlesOnDevice => 'Selalu tunjukkan subtitle pada peranti ini';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Apabila pelayan tidak mempunyai subtitle yang dipilih, pilih trek secara tempatan. ini tidak pernah mengubah keutamaan pelayan.';
	@override String get autoDownloadPreferredSubtitle => 'FETCH kekurangan subtitle bahasa kegemaran';
	@override String get autoDownloadPreferredSubtitleDescription => 'Pilih subtitle yang tersedia dalam bahasa kegemaran anda secara tempatan.Jika tiada, minta pelayan untuk menangkap satu apabila disokong.Pilihan kekal pada peranti ini.';
	@override String get rememberTrackSelectionsDescription => 'Menyimpan pilihan audio dan subtitle mengikut persembahan atau filem pada peranti ini';
	@override String get rememberTrackSelectionsBackendRule => 'Bekerja secara tempatan dengan Plex, Jellyfin, dan Emby; Plex dan Jellyfin juga boleh menyimpan pemilihan pada pelayan';
	@override String get followServerTrackSelections => 'Menggunakan pilihan trek per episod pelayan';
	@override String get followServerTrackSelectionsDescription => 'Pada perubahan episod, gunakan audio dan subtitle yang dipilih pada pelayan bukannya membawa di atas pilihan semasa.';
	@override String get resumeMusicOnLaunch => 'Ingat sesi muzik';
	@override String get resumeMusicOnLaunchDescription => 'Buka semula lagu terakhir berhenti di mana ia meninggalkan apabila aplikasi bermula';
	@override String get showChapterMarkersOnTimeline => 'Tunjukkan penanda bab pada mencari bar';
	@override String get showChapterMarkersOnTimelineDescription => 'Segmen bar pencarian di sempadan bab';
	@override String get specialsOrdering => 'Khas dalam perintah episod';
	@override String get specialsOrderingDescription => 'Di mana istimewa bermain dalam perintah jam persembahan';
	@override String get specialsOrderingServer => 'Mengikut Perintah Server';
	@override String get specialsOrderingAirDate => 'Tarikh penerbangan mengikut tarikh';
	@override String get specialsOrderingLast => 'Selepas musim biasa';
	@override String get clickVideoTogglesPlayback => 'Klik pada video untuk toggle play/pause';
	@override String get clickVideoTogglesPlaybackDescription => 'Klik video untuk memainkan/berhenti daripada menunjukkan kawalan.';
	@override String get videoPlayerControls => 'Pengawal Video Player';
	@override String get keyboardShortcuts => 'Tag: kekunci pendek';
	@override String get keyboardShortcutsDescription => 'Menyesuaikan kekunci kekunci';
	@override String get videoPlayerNavigation => 'Pelakon navigasi video';
	@override String get videoPlayerNavigationDescription => 'Gunakan kunci pistol untuk menavigasi kawalan pemutar video';
	@override String get watchTogetherRelay => 'Lihat bersama-sama relay';
	@override String get watchTogetherRelayDescription => 'Public Open Watch Party melayari kecuali anda menetapkan anda sendiri';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Masukkan URL asas geganti HTTP atau HTTPS yang sah.';
	@override String get crashReporting => 'Laporan kemalangan';
	@override String get crashReportingDescription => 'Hantar laporan kemalangan untuk membantu memperbaiki aplikasi';
	@override String get debugLogging => 'Pengenalan Debug';
	@override String get debugLoggingDescription => 'Membolehkan log terperinci untuk penyelesaian masalah';
	@override String get viewLogs => 'Lihat log';
	@override String get viewLogsDescription => 'Lihat log aplikasi';
	@override String get clearImageCache => 'Gambaran keseluruhan Cache';
	@override String get clearImageCacheDescription => 'Gambar boleh dimuat turun lebih perlahan sehingga dimuat turun lagi.';
	@override String get clearImageCacheSuccess => 'Cache imej diselesaikan dengan berjaya';
	@override String get resetSettings => 'Pengaturan semula';
	@override String get resetSettingsDescription => 'Mengembalikan tetapan lalai. ini tidak boleh dikecualikan.';
	@override String get resetSettingsSuccess => 'Seting Setuju berjaya';
	@override String get backup => 'Penyimpanan';
	@override String get exportSettings => 'Pengaturan Eksport';
	@override String get exportSettingsDescription => 'Simpan keutamaan anda untuk fail';
	@override String get exportSettingsSuccess => 'Seting yang dieksport';
	@override String get importSettings => 'Pengenalan Import';
	@override String get importSettingsDescription => 'Memulihkan keutamaan daripada fail';
	@override String get importSettingsConfirm => 'Ini akan menggantikan tetapan semasa anda.Lanjutkan?';
	@override String get importSettingsSuccess => 'Seting yang diimport';
	@override String get importSettingsInvalidFile => 'Fail ini bukan pengeksportan tetapan PlezyNG yang sah';
	@override String get importSettingsNoUser => 'Menandatangani sebelum mengimport tetapan';
	@override String get cloudBackup => 'Penyelesaian Cloud Backup';
	@override String get cloudBackupDescription => 'Sandarkan tetapan yang boleh dipindahkan ke alamat WebDAV melalui HTTPS. Sambungan pelayan dan maklumat log masuk kekal pada peranti ini.';
	@override String get cloudBackupUrl => 'WebDAV URL fail JSON';
	@override String get cloudBackupUsername => 'Nama Pengguna';
	@override String get cloudBackupPassword => 'kata laluan';
	@override String get cloudBackupSaved => 'Cloud backup destinasi disimpan';
	@override String get cloudBackupNow => 'Kembali ke sekarang';
	@override String get cloudBackupComplete => 'Setup backup diunggah';
	@override String get cloudBackupRestore => 'Memulihkan Backup';
	@override String get cloudBackupRestoreConfirm => 'Ini akan menggantikan tetapan mudah alih yang sepadan pada peranti ini.';
	@override String get cloudBackupRestored => 'Seting yang dipulihkan daripada Cloud Backup';
	@override String get shortcutsReset => 'Pengurangan semula kepada default';
	@override String get resetShortcutsConfirm => 'Ini akan menggantikan kekurangan yang disesuaikan anda dengan kekurangan.';
	@override String get about => 'Mengenai';
	@override String get aboutDescription => 'Maklumat App dan Lesen';
	@override String get updates => 'Kemas kini';
	@override String get updateAvailable => 'Update yang tersedia';
	@override String get checkForUpdates => 'Semak untuk kemas kini';
	@override String get autoCheckUpdatesOnStartup => 'Semak secara automatik untuk kemas kini pada startup';
	@override String get autoCheckUpdatesOnStartupDescription => 'Pemberitahuan apabila kemas kini tersedia pada pelancaran';
	@override String get validationErrorEnterNumber => 'Sila masukkan nombor yang sah';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Ia mesti antara ${min} dan ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Shortcut yang telah ditugaskan kepada ${action}';
	@override String shortcutUpdated({required Object action}) => 'Shortcut dikemaskini untuk ${action}';
	@override String get saveFailed => 'Tidak boleh simpan perubahan. cuba lagi.';
	@override String get autoPlayAndSkip => 'Permainan dalam talian & Skip';
	@override String get autoPlayNextEpisode => 'Auto-Play Episode seterusnya';
	@override String get autoPlayNextEpisodeDescription => 'Memulakan episod seterusnya secara automatik apabila satu berakhir';
	@override String get shuffleStartsFromBeginning => 'Shuffle bermula pada permulaan';
	@override String get shuffleStartsFromBeginningDescription => 'Memulakan setiap episod pada permulaan apabila menghisap bukannya mengulangi';
	@override String get plexCinemaPreRoll => 'Penggunaan pelayan filem intros';
	@override String get plexCinemaPreRollDescription => 'Mainkan Plex pre-rolls atau Jellyfin dan Emby intros yang dikonfigurasi sebelum filem bermula.';
	@override String get playNextCountdown => 'Permainan dalam talian Next Countdown';
	@override String get playNextCountdownImmediate => 'Bermain dengan segera';
	@override String get skipIntroMode => 'Lapangan Terbang Intro';
	@override String get skipIntroModeOffDescription => 'Bermain intros secara normal tanpa butang skip';
	@override String get skipIntroModeButtonDescription => 'Tunjukkan butang skip apabila intro bermula';
	@override String get skipIntroModeAutoDescription => 'Melompat masuk secara automatik selepas keterlambatan di bawah';
	@override String get skipCreditsMode => 'Melompat kredit';
	@override String get skipCreditsModeOffDescription => 'Bermain kredit secara normal tanpa butang skip';
	@override String get skipCreditsModeButtonDescription => 'Tunjukkan butang skip apabila kredit bermula';
	@override String get skipCreditsModeAutoDescription => 'Melompat kredit secara automatik dan memainkan episod berikutnya';
	@override String get skipAdsMode => 'Laporan Ads';
	@override String get skipAdsModeOffDescription => 'Mainkan iklan yang dikesan secara normal tanpa butang skip';
	@override String get skipAdsModeButtonDescription => 'Tunjukkan butang skip apabila Plex mendeteksi iklan';
	@override String get skipAdsModeAutoDescription => 'Hentikan iklan yang dikesan secara automatik selepas penundaan di bawah';
	@override String get musicPlayback => 'Kumpulan Lagu Playback';
	@override String get musicSweetFades => 'buah manis';
	@override String get musicSweetFadesDescription => 'Fade muzik pada tepi trek apabila Plex mempunyai data bunyi.';
	@override String get skipMarkerModeOff => 'keluar';
	@override String get skipMarkerModeButton => 'Tunjukkan butang';
	@override String get skipMarkerModeAuto => 'automatik';
	@override String get forceSkipMarkerFallback => 'Pengenalan kepada Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'Gunakan corak tajuk bab walaupun Plex mempunyai penanda';
	@override String get theIntroDbFallback => 'Menggunakan TheIntroDB sebagai intro fallback';
	@override String get theIntroDbFallbackDescription => 'Gunakan jadual komuniti hanya apabila pelayan tidak mempunyai penanda intro. perlawanan boleh berbeza-beza mengikut pelepasan.';
	@override String get autoSkipDelay => 'Kereta Api Tangguh';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Menunggu ${seconds} saat sebelum melompat';
	@override String get introPattern => 'Pengenalan kepada pattern';
	@override String get introPatternDescription => 'Pattern Regex untuk menyesuaikan intro markers dalam tajuk bab';
	@override String get creditsPattern => 'Perbezaan kredit markers';
	@override String get creditsPatternDescription => 'Model Regex untuk memenuhi penanda kredit dalam tajuk bab';
	@override String get prerolls => 'Preliminasi';
	@override String get playPrerollsBeforeMovies => 'Bermain Prerolls Sebelum Filem';
	@override String get playPrerollsBeforeMoviesDescription => 'Mainkan klip rawak daripada pilihan anda di bawah sebelum setiap filem. tekan kembali untuk melompat.';
	@override String get prerollLibrary => 'Perpustakaan Preroll';
	@override String get prerollLibraryNotSet => 'Tidak menetapkan';
	@override String get prerollLibraryNoneFound => 'Tiada perpustakaan yang ditemui di pelayan anda.';
	@override String get prerollSelection => 'Pemilihan prerolls';
	@override String get prerollSelectionPickLibraryFirst => 'Pilih perpustakaan terlebih dahulu';
	@override String get prerollSelectionNoneSelected => 'Tiada jurulatih yang dipilih';
	@override String prerollSelectionCount({required Object count}) => '${count} telah dipilih';
	@override String get prerollItemPicker => 'Pilih Preliminasi';
	@override String get prerollItemPickerLoadFailed => 'Saya tidak boleh memuatkan item daripada perpustakaan ini.';
	@override String get invalidRegex => 'Ketidakupayaan ekspresi biasa';
	@override String get regex => 'Ekspresi yang kerap';
	@override String get downloads => 'Muat turun';
	@override String get downloadLocationDescription => 'Pilih di mana untuk menyimpan kandungan yang dimuat turun';
	@override String get downloadLocationDefault => 'Penyimpanan Aplikasi (App Storage)';
	@override String get downloadLocationCustom => 'Lokasi Custom';
	@override String get selectFolder => 'Pilih Folder';
	@override String get resetToDefault => 'Kembali ke lalai';
	@override String currentPath({required Object path}) => 'Jumlah : ${path}';
	@override String get downloadLocationChanged => 'Lokasi muat turun berubah';
	@override String get downloadLocationReset => 'Download lokasi reset kepada default';
	@override String get downloadLocationInvalid => 'folder yang dipilih tidak boleh ditulis';
	@override String get downloadLocationPickerUnavailable => 'Pemilihan folder tidak tersedia pada peranti ini';
	@override String get downloadOnWifiOnly => 'Muat turun pada Wi-Fi sahaja';
	@override String get downloadOnWifiOnlyDescription => 'Mencegah muat turun apabila pada data selular';
	@override String get autoRemoveWatchedDownloads => 'Auto-remove download yang dilihat';
	@override String get autoRemoveWatchedDownloadsDescription => 'Menghapuskan muat turun secara automatik';
	@override String get autoDownloadContinueWatching => 'Auto-Download teruskan penglihatan';
	@override String get autoDownloadContinueWatchingDescription => 'Simpan item pada rak terus anda dimuat turun, dan menghapuskan mereka sebaik sahaja mereka meninggalkan rak';
	@override String get downloadQuality => 'Download Kualiti';
	@override String get downloadQualityDescription => 'Plex menyediakan salinan yang ditukar dalam kue muat turunnya. Jellyfin dan Emby transcode semasa fail muat turun; pemindahan terputus mungkin perlu dimulakan semula.';
	@override String get askDownloadQualityEachTime => 'Pilih kualiti untuk setiap download';
	@override String get askDownloadQualityEachTimeDescription => 'Tunjukkan picker kualiti sebelum mengecualikan setiap video muat turun';
	@override String get cellularDownloadBlocked => 'Muat turun disekat pada selular. gunakan Wi-Fi atau ubah tetapan.';
	@override String get maxVolume => 'Kelantangan maksimum';
	@override String get maxVolumeDescription => 'Benarkan peningkatan kelantangan melebihi 100% untuk media yang bunyinya perlahan';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Tunjukkan apa yang anda lihat di Discord';
	@override String get services => 'Perkhidmatan';
	@override String get servicesDescription => 'Hubungi Trakt, MyAnimeList, Seerr, dan banyak lagi';
	@override String get manageLibrariesDescription => 'Menyelamatkan dan menyembunyikan perpustakaan';
	@override String get companionRemoteServer => 'Pengenalan kepada Remote Server';
	@override String get companionRemoteServerDescription => 'Membolehkan peranti mudah alih di rangkaian anda untuk mengawal aplikasi ini';
	@override String get companionRemoteServerStartFailed => 'Tidak boleh memulakan pelayan rakan';
	@override String get companionRemoteServerStopFailed => 'Tidak boleh menghentikan pelayan rakan';
	@override String get autoPip => 'Pengenalan kepada Auto Picture-in-Picture';
	@override String get autoPipDescription => 'Secara automatik, masukkan imej dalam imej apabila anda meninggalkan aplikasi semasa pemutaran';
	@override String get matchContentFrameRate => 'Rata-rata Perlawanan Content Frame Rate';
	@override String get matchContentFrameRateDescription => 'Match menunjukkan kadar pembaharuan kepada kandungan video';
	@override String get matchContentResolution => 'Perlawanan Content Resolution';
	@override String get matchContentResolutionDescription => 'Tukar paparan kepada resolusi asli video supaya TV anda berfungsi upscaling. menu dan subtitle juga upscaled semasa playback';
	@override String get matchRefreshRate => 'Perlawanan Rata-rata Pembersihan';
	@override String get matchRefreshRateDescription => 'Matches paparan kadar pembaharuan dalam skrin penuh';
	@override String get matchDynamicRange => 'Perlawanan Dynamic Range';
	@override String get matchDynamicRangeDescription => 'Tukar HDR untuk kandungan HDR, kemudian kembali kepada SDR';
	@override String get displaySwitchDelay => 'Kelewatan Pertukaran Paparan';
	@override String get tunneledPlayback => 'Perbincangan:Tunnel Playback';
	@override String get tunneledPlaybackDescription => 'Gunakan video tunel.Tonaktifkan jika HDR playback menunjukkan video hitam atau stutters pergerakan.';
	@override String get audioPassthrough => 'Perbincangan:Audio Passthrough';
	@override String get audioPassthroughDescription => 'Hantar audio Dolby/DTS ke penerima atau TV anda tanpa mengekod semula, mengekalkan bunyi sekitar.';
	@override String get audioPassthroughDescriptionApple => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. DTS dan TrueHD masih memainkan PCM pelbagai saluran.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. Pada iOS, iPadOS dan tvOS 26 atau lebih lama, TrueHD Atmos dan DTS:X memainkan sebagai audio ruang.';
	@override String get audioPassthroughOverriddenByNormalization => 'Hentikan semasa normalisasi bunyi';
	@override String get audioChannelLimit => 'saluran audio';
	@override String get audioChannelLimitDescription => 'Campurkan audio yang dikodkan ke bawah untuk speaker, headphone, atau setup HDMI yang tidak boleh memainkan setiap saluran';
	@override String get audioChannelLimitOriginal => 'asal';
	@override String get audioChannelLimitOriginalDescription => 'Mainkan setiap saluran dalam trek';
	@override String get audioChannelLimitSurround51 => 'sehingga 5.1';
	@override String get audioChannelLimitSurround51Description => 'Campurkan 7.1 ke bawah kepada 5.1 untuk TV dan penerima yang hanya mengambil 5.1 PCM.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Campurkan ke dua saluran untuk speaker stereo atau headphone.';
	@override String get downmixCenterBoost => 'Perbincangan Channel Boost';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Pengukuran (db)';
	@override String get downmixCenterBoostShort => 'DB';
	@override String get audioDownmixNormalize => 'Meningkatkan jumlah pada Downmix';
	@override String get audioDownmixNormalizeDescription => 'Mengurangkan campuran untuk mengelakkan penipisan. beralih untuk mengekalkan volum asal (mungkin mengganggu adegan yang keras).';
	@override String get dvConversionMode => 'Dolby Vision Pengubahsuaian';
	@override String get dvConversionModeDescription => 'Pilih bagaimana fail Dolby Vision Profil 7 diuruskan.';
	@override String get dvConversionAuto => 'Kereta';
	@override String get dvConversionNative => 'Keluarga / Disabiliti';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Menggunakan pengesanan keupayaan peranti dan tingkah laku fallback normal';
	@override String get dvConversionNativeDescription => 'Kuasa asli DV7 dan penindasan DV penukaran retry';
	@override String get dvConversionDv81Description => 'Kuasa dalam rangkaian RPU penukaran kepada Dolby Vision profil 8.1';
	@override String get dvConversionHevcStripDescription => 'Strip Dolby Vision lapisan RPU/EL dan rata semasa HEVC';
	@override String get experimentalDolbyVision => 'Dolby Vision eksperimen';
	@override String get experimentalDolbyVisionDescription => 'Gunakan pemapar FEL eksperimen pada main balik seterusnya. Memerlukan binaan enjin yang berasingan.';
	@override String get dvExperimentUnavailableDescription => 'Eksperimen ini kini hanya tersedia pada Linux.';
	@override String get dvCompatibilityFallback => 'Pilihan sandaran keserasian';
	@override String get dvCompatibilityFallbackDescription => 'Gunakan pemapar standard jika eksperimen tidak dapat dimulakan. Data FEL mungkin hilang.';
	@override String get dvExperimentDiagnostics => 'Pengelogan eksperimen video';
	@override String get dvExperimentDiagnosticsDescription => 'Dayakan log pemain terperinci pada main balik seterusnya.';
	@override String get disableDolbyVision => 'Penyelesaian Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Mainkan lapisan fail HDR10 atau HLG daripada Dolby Vision, apabila ia mempunyai lapisan';
	@override String get hdrSdrConversion => 'HDR kepada SDR Konversi';
	@override String get hdrSdrConversionDescription => 'Pilih apa yang menukar video HDR apabila paparan tidak boleh menunjukkan HDR.';
	@override String get hdrSdrConversionAuto => 'Kereta';
	@override String get hdrSdrConversionAutoDescription => 'Peranti pada Android 9 dan seterusnya, pemain pada versi yang lebih tua';
	@override String get hdrSdrConversionDevice => 'peranti';
	@override String get hdrSdrConversionDeviceDescription => 'Perkakasan video peranti anda menukarnya. paling cepat, tetapi warna bergantung kepada peranti';
	@override String get hdrSdrConversionPlayer => 'Pemain';
	@override String get hdrSdrConversionPlayerDescription => 'Warna yang konsisten, tetapi 4K boleh menjejaskan kotak TV rendah';
	@override String get deinterlace => 'Perbincangan';
	@override String get deinterlaceDescription => 'Menghilangkan objek bercampur daripada video yang terhubung (mpv pemain sahaja)';
	@override String get deinterlaceOff => 'keluar';
	@override String get deinterlaceOffDescription => 'Tunjukkan video terhubung seperti ia dikodkan';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Tukar setiap medan ke dalam bingkai penuh. untuk video tangkapan untuk TV, seperti sukan, berita, dan konsert';
	@override String get deinterlaceFilm => 'Filem';
	@override String get deinterlaceFilmDescription => 'Memulihkan bingkai asal filem dan animasi telecined kepada 29.97 fps, biasa pada DVD NTSC. Video shot untuk TV stutters.';
	@override String get requireProfileSelectionOnOpen => 'Mencari profil dalam app open';
	@override String get requireProfileSelectionOnOpenDescription => 'Tunjukkan pemilihan profil setiap kali aplikasi dibuka';
	@override String get forceTvMode => 'Kekuatan TV Mode';
	@override String get forceTvModeDescription => 'Layout TV Force. untuk peranti yang tidak mendeteksi secara automatik. memerlukan pemulihan semula.';
	@override String get startInFullscreen => 'Mulakan pada skrin penuh';
	@override String get startInFullscreenDescription => 'Buka PlezyNG dalam mod skrin penuh pada pelancaran';
	@override String get exitFullscreenOnPlayerClose => 'Ekran penuh keluar pada pemain tertutup';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Secara automatik keluar skrin penuh apabila menutup pemutar video';
	@override String get autoHidePerformanceOverlay => 'Auto-Hide Perkhidmatan Overlay';
	@override String get autoHidePerformanceOverlayDescription => 'Mengurangkan prestasi dengan kawalan playback';
	@override String get showNavBarLabels => 'Tunjukkan Navigasi Bar Label';
	@override String get showNavBarLabelsDescription => 'Menampilkan label teks di bawah ikon bar navigasi';
	@override String get startupSection => 'Bahagian Startup';
	@override String get preferredServer => 'Pelayan yang disukai';
	@override String get preferredServerDescription => 'Prioriti hasil pelayan ini sambil mengekalkan setiap pelayan yang disambungkan.';
	@override String get preferredServerAutomatic => 'automatik';
	@override String get showExploreTab => 'Lihat Tab';
	@override String get showExploreTabDescription => 'Tunjukkan tab Cari dengan kandungan daripada Plex Cari dan pengesan yang disambungkan';
	@override String get hideEmptyLibraries => 'Menyembunyikan perpustakaan kosong';
	@override String get hideEmptyLibrariesDescription => 'Menghilangkan perpustakaan dengan bilangan item yang dilaporkan oleh pelayan daripada sifar daripada navigasi.';
	@override String get liveTvDefaultFavorites => 'Menerima saluran kegemaran';
	@override String get liveTvDefaultFavoritesDescription => 'Menampilkan saluran kegemaran sahaja apabila membuka TV langsung';
	@override String get general => 'Umum';
	@override String get generalDescription => 'Bahasa, permulaan, dan tingkap tingkah laku';
	@override String get languageAndRegion => 'Bahasa & Wilayah';
	@override String get startup => 'Permulaan';
	@override String get display => 'Papar';
	@override String get libraryAndCards => 'Perpustakaan & Kartu';
	@override String get homeScreen => 'Home » skrin';
	@override String get navigation => 'Navigasi';
	@override String get window => 'Jendela';
	@override String get liveTv => 'TV Langsung';
	@override String get player => 'Pemain';
	@override String get videoAndDisplay => 'Video & Pameran';
	@override String get audio => 'Audio yang';
	@override String get quality => 'Kualiti';
	@override String get subtitles => 'Sari kata';
	@override String get seekAndTiming => 'Pencarian & Tempoh';
	@override String get behavior => 'tingkah laku';
	@override String get gestures => 'Gejala';
	@override String get gestureBrightnessSwipe => 'Cahaya bersinar';
	@override String get gestureBrightnessSwipeDescription => 'Tukar ke atas atau ke bawah pada tepi kiri untuk menyesuaikan kecerahan';
	@override String get gestureVolumeSwipe => 'Jumlah Swipe';
	@override String get gestureVolumeSwipeDescription => 'Tukar ke atas atau ke bawah pada tepi kanan untuk menyesuaikan volum';
	@override String get gesturePinchToZoom => 'Pinch untuk Zoom';
	@override String get gesturePinchToZoomDescription => 'Pin pada video untuk zoom dalam atau keluar';
	@override String get gestureSeekSwipe => 'Mencari Swipe';
	@override String get gestureSeekSwipeDescription => 'Beralih ke kiri atau kanan di mana-mana video untuk mencari; melepaskan untuk melompat';
	@override String get rememberBrightnessLevel => 'Ingat tahap kecerahan';
	@override String get rememberBrightnessLevelDescription => 'Mulakan playback pada kecerahan yang ditetapkan oleh swipe terakhir';
	@override String get controls => 'kawalan';
	@override String get rememberPlayerChanges => 'Ingat perubahan pemain';
	@override String get rememberPlayerChangesDescription => 'Di mana perubahan yang dibuat semasa playback disimpan dan digunakan semula daripada';
	@override String get scopePlaybackSpeed => 'Kelajuan Playback';
	@override String get scopeShaderPreset => 'Perbincangan Shader Preset';
	@override String get scopeAspectRatio => 'Nisbah aspek';
	@override String get scopeSyncOffsets => 'Audio dan Subtitle Sync';
	@override String get playerScopeOff => 'Jangan menyelamatkan';
	@override String get playerScopeGlobal => 'Di mana-mana sahaja';
	@override String get playerScopeLibrary => 'Per Perpustakaan';
	@override String get playerScopeTitle => 'untuk persembahan atau filem';
	@override String get exportDialogTitle => 'Eksport PlezyNG tetapan';
	@override String get followSystem => 'Ikut sistem';
	@override String get followAppLanguage => 'Ikut bahasa antara muka';
	@override String get regionFormat => 'Format serantau';
	@override String get regionFormatDescription => 'Pilih cara tarikh, nombor dan unit ukuran dipaparkan.';
	@override String get metadataLanguage => 'Bahasa metadata';
	@override String get metadataLanguageDescription => 'Bahasa tajuk dan huraian pilihan jika disokong oleh pelayan. Pilihan audio dan sari kata ditetapkan secara berasingan.';
	@override String get enterFullscreenOnPlaybackStart => 'Masukkan skrin penuh apabila playback bermula';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Membuka video desktop dalam skrin penuh apabila playback bermula';
	@override String get extendVideoIntoDisplayCutout => 'Memperluaskan video ke dalam display cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Biarkan video skrin penuh menggunakan kamera cutout pada telefon Android';
	@override String get languageDescription => 'Pilih bahasa yang digunakan untuk kawalan dan mesej PlezyNG. sistem mengikuti bahasa peranti anda.';
	@override String get themeDescription => 'Pilih warna dan kontras yang digunakan sepanjang aplikasi.';
	@override String get libraryDensityDescription => 'Mengubah bilangan kad perpustakaan yang sesuai dalam setiap baris.';
	@override String get displayScaleDescription => 'Mengembalikan antara muka pada paparan kereta ini tanpa mengubah saiz teks keseluruhan peranti anda.';
	@override String get themeSongVolumeDescription => 'Tetapkan jumlah lagu tema berbanding dengan audio lain.';
	@override String get viewModeDescription => 'Pilih sama ada item perpustakaan muncul sebagai poster dalam rangkaian atau sebagai senarai kompak.';
	@override String get gridViewDescription => 'Menyusun item perpustakaan dalam baris dan lajur poster.';
	@override String get listViewDescription => 'Tunjukkan item perpustakaan dalam senarai vertikal dengan lebih banyak teks per item.';
	@override String get gridSpacingDescription => 'Menetapkan jurang antara poster dalam rangkaian perpustakaan.';
	@override String get gridSpacingTightDescription => 'Menyesuaikan lebih banyak poster di seluruh skrin dengan jurang yang lebih kecil.';
	@override String get gridSpacingNormalDescription => 'Gunakan jurang standard antara poster.';
	@override String get gridSpacingSpaciousDescription => 'Tambah jurang yang lebih besar antara poster untuk lebih banyak pemisahan.';
	@override String get episodePosterModeDescription => 'Pilih karya seni yang muncul pada kad episod.';
	@override String get seriesPosterDescription => 'Gunakan poster siri untuk setiap episod.';
	@override String get seasonPosterDescription => 'Gunakan poster musim untuk setiap episod apabila tersedia.';
	@override String get episodeThumbnailDescription => 'Gunakan bingkai daripada episod apabila tersedia.';
	@override String get continueWatchingActionDescription => 'Pilih apa yang berlaku apabila anda mengaktifkan Kad Pengawasan Berterusan.';
	@override String get continueWatchingPlayDescription => 'Mulakan filem atau episod dengan segera.';
	@override String get continueWatchingDetailsDescription => 'Buka halaman tajuk terlebih dahulu supaya anda boleh meninjau butiran dan pilih tindakan.';
	@override String get episodeActionDescription => 'Pilih apa yang berlaku apabila anda mengaktifkan kad episod.';
	@override String get episodePlayDescription => 'Mulakan episod ini dengan segera.';
	@override String get episodeDetailsDescription => 'Buka halaman episod sebelum playback.';
	@override String get contentScreensaverDelayDescription => 'Pilih berapa lama PlezyNG menunggu tanpa input sebelum menunjukkan karya seni.';
	@override String get continueWatchingRowSizeDescription => 'Pilih seberapa besar kad yang terdapat dalam baris terus-menerus.';
	@override String get rowSizeCompactDescription => 'Tunjukkan kad yang lebih kecil supaya lebih banyak item sesuai di sepanjang baris.';
	@override String get rowSizeStandardDescription => 'Gunakan saiz kad standard.';
	@override String get rowSizeLargeDescription => 'Tunjukkan kad yang lebih besar dengan lebih banyak butiran karya seni.';
	@override String get visualEffectsDescription => 'Pilih anggaran animasi dan kesan seni untuk peranti ini.';
	@override String get visualEffectsFullDescription => 'Gunakan kesan animasi dan seni penuh pada setiap peranti.';
	@override String get startupSectionDescription => 'Pilih bahagian mana yang dibuka apabila PlezyNG bermula.';
	@override late final _Translations$settings$startupSectionOptions$ms startupSectionOptions = _Translations$settings$startupSectionOptions$ms._(_root);
	@override String get smallSkipDurationDescription => 'Tetapkan jarak yang dipindahkan oleh belakang pendek dan ke hadapan mencari kawalan.';
	@override String get largeSkipDurationDescription => 'Tetapkan jarak yang dipindahkan oleh latar belakang panjang dan ke hadapan mencari kawalan.';
	@override String get rewindOnResumeDescription => 'Move playback kembali dengan jumlah ini apabila mengembalikan video.';
	@override String get defaultSleepTimerDescription => 'Tetapkan tempoh permulaan yang digunakan apabila anda memulakan jam tidur.';
	@override String get playNextCountdownDescription => 'Tunggu ini lama sebelum memulakan episod set set kepada 0 untuk bermula dengan segera.';
	@override String get autoSkipDelaySettingDescription => 'Ia terpakai apabila entri, kredit, atau iklan ditetapkan untuk melarikan diri secara automatik.';
	@override String get downmixCenterBoostDescription => 'Meningkatkan dialog di saluran pusat apabila audio persekitaran dicampur ke bawah ke stereo.';
	@override String get displaySwitchDelayDescription => 'Tunggu sebelum mengubah mod paparan supaya TV atau penerima boleh menyelesaikan peralihan terdahulu.';
	@override String get playerBackendDescription => 'Pilih mana enjin playback yang memecahkan dan mengembalikan video pada peranti ini.';
	@override String get exoPlayerDescription => 'Gunakan pemutar berasaskan Media3 asli Android dan laluan perkakasan yang disokong.';
	@override String get mpvDescription => 'Gunakan mpv, yang mendedahkan pemutaran tambahan, subtitle, dan kawalan pemprosesan video.';
	@override String get scopeOffDescription => 'Mengekalkan perubahan untuk sesi playback semasa sahaja.';
	@override String get scopeGlobalDescription => 'Gunakan semula nilai yang sama untuk setiap perpustakaan dan tajuk.';
	@override String get scopeLibraryDescription => 'Ingat nilai yang berasingan untuk setiap perpustakaan.';
	@override String get scopeTitleDescription => 'Ingat nilai berasingan untuk setiap persembahan atau filem.';
	@override String get specialsOrderingServerDescription => 'Simpan pesanan episod yang disediakan oleh pelayan media.';
	@override String get specialsOrderingAirDateDescription => 'Letakkan istimewa di antara episod biasa mengikut tarikh udara mereka.';
	@override String get specialsOrderingLastDescription => 'Letakkan setiap istimewa selepas musim biasa.';
	@override String get skipIntroModeDescription => 'Pilih sama ada penanda intro memainkan secara normal, menunjukkan butang skip, atau skip secara automatik.';
	@override String get skipCreditsModeDescription => 'Pilih sama ada kredit memainkan secara normal, menunjukkan butang skip, atau skip secara automatik.';
	@override String get skipAdsModeDescription => 'Pilih sama ada iklan yang dikesan memainkan secara normal, menunjukkan butang skip, atau skip secara automatik.';
	@override String get playbackBufferAutoDescription => 'Biarkan pemain aktif memilih saiz buffer biasa.';
	@override String get playbackBufferLargeDescription => 'Tetap lebih banyak media bersedia sebelum playback; ini menggunakan lebih banyak memori.';
	@override String get playbackBufferExtraLargeDescription => 'Mengekalkan buffer bacaan terbesar; ini menggunakan memori yang paling banyak.';
	@override String get defaultQualityDescription => 'Setkan resolusi video lalai dan bitrate bumbung untuk aliran yang pelayan transcod.';
	@override String get cellularQualityDescription => 'Override Kualiti lalai apabila peranti menggunakan sambungan selular sahaja.';
	@override String get remoteQualityDescription => 'Override Kualiti lalai apabila menyambung ke pelayan melalui sambungan jauh.';
	@override String get qualityPresetOriginalDescription => 'Mainkan sumber dalam kualiti yang tersedia tanpa meminta pelayan untuk menyalakan kodnya.';
	@override String get qualityPresetTranscodeOptionDescription => 'Tanya pelayan untuk aliran yang ditukar menggunakan resolusi dan bitrate yang dipaparkan di atas.';
	@override String get qualityPresetSameAsDefaultDescription => 'Gunakan kualiti yang dipilih dalam Kualiti lalai.';
	@override String get musicQualityDescription => 'Tetapkan kadar bit audio maksimum yang diminta daripada pelayan; Original mengekalkan aliran sumber.';
	@override String get musicQualityOriginalDescription => 'Mainkan audio sumber tanpa transcode bitrate-capped.';
	@override String get musicQualityTranscodeOptionDescription => 'Meminta transcode pelayan yang dilapisi berhampiran kadar bit yang ditunjukkan di atas; output sebenar boleh berbeza-beza.';
	@override String get maxVolumeInputLabel => 'Jumlah maksimum (%)';
	@override String get checkForUpdatesDescription => 'Sekarang semak sama ada versi PlezyNG yang lebih baru boleh didapati.';
	@override String get appearanceDescription => 'Pilih tema aplikasi dan menyesuaikan kad perpustakaan, baris rumah, dan navigasi.';
	@override String get prerollLibraryDescription => 'Pilih perpustakaan yang mengandungi klip yang tersedia sebagai pre-rolls filem.';
	@override String get prerollSelectionDescription => 'Pilih klip mana daripada perpustakaan yang dipilih boleh dimainkan sebelum filem.';
	@override String get contentScreensaverDelayOptionDescription => 'Tunggu ini banyak minit tanpa input sebelum menunjukkan screensaver artwork.';
	@override String get videoCodecOptionDescription => 'Membolehkan pemutaran langsung untuk kodek ini apabila disokong. kodek yang tidak disemak disulitkan oleh pelayan media.';
}

// Path: themeEditor
class _Translations$themeEditor$ms extends Translations$themeEditor$en {
	_Translations$themeEditor$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'dibina dalam';
	@override String get presets => 'Persembahan';
	@override String get custom => 'Khas';
	@override String get customEmpty => 'belum dicipta';
	@override String get editCustom => 'Edit tema khas';
	@override String get editCustomDescription => 'Pilih setiap warna anda sendiri';
	@override String get locked => 'Akses seumur hidup diperlukan';
	@override String get savedLocked => 'Disimpan - boleh didapati dengan akses seumur hidup';
	@override String get title => 'Subjek Custom';
	@override String get startFrom => 'Bermula daripada';
	@override String get startFromDescription => 'Menyalin semua warna daripada tema lain';
	@override String get colors => 'warna';
	@override String get preview => 'Persiapan';
	@override late final _Translations$themeEditor$slots$ms slots = _Translations$themeEditor$slots$ms._(_root);
	@override String get opacity => 'Ketidakpastian';
	@override String get hexHint => '#RRGGBB atau #AARRGGBB';
	@override String get fromOtherThemes => 'daripada topik lain';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$ms contrast = _Translations$themeEditor$contrast$ms._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, di bawah yang disyorkan ${minimum}:1';
	@override String get discardTitle => 'Mengabaikan perubahan ?';
	@override String get discardMessage => 'Perubahan warna yang tidak disimpan akan hilang.';
	@override String get discard => 'Diskaun';
	@override String previewCardTitle({required Object number}) => 'Perbincangan ${number}';
	@override String previewCardSubtitle({required Object minutes}) => 'Baki ${minutes} min';
	@override String get previewSwitch => 'Main automatik';
	@override String get previewMutedText => 'Artikel sekunder baca seperti ini';
	@override String get themeSystemDescription => 'Ikuti penampilan peranti anda dan beralih antara cahaya dan kegelapan secara automatik.';
	@override String get themeLightDescription => 'Gunakan latar belakang yang cerah dengan teks gelap.';
	@override String get themeDarkDescription => 'Gunakan latar belakang gelap dengan teks yang cerah.';
	@override String get themeOledDescription => 'Gunakan permukaan berwarna hitam yang mengurangkan cahaya pada skrin OLED.';
	@override String get themeEmberDescription => 'Gunakan warna merah hangat dan aksen amber.';
	@override String get themeGlacierDescription => 'Gunakan warna aksen biru sejuk.';
	@override String get themeForestDescription => 'Gunakan warna hijau dan aksen semulajadi.';
	@override String get themePlumDescription => 'Gunakan warna aksen violet dan plum.';
	@override String get themePaperDescription => 'Gunakan permukaan seperti kertas yang hangat dan warna yang diilhamkan tinta.';
	@override String get themeCustomDescription => 'Gunakan palet warna yang anda cipta dalam editor tema tersuai.';
	@override String get editorDescription => 'Pilih warna palet, menyesuaikan hue, kenyang, kecerahan, atau ketidakselesaan, dan lihat kemas kini pra-penglihatan sebelum simpan.';
}

// Path: search
class _Translations$search$ms extends Translations$search$en {
	_Translations$search$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Mencari filem, persembahan, muzik ...';
	@override String get tryDifferentTerm => 'Cuba istilah carian yang berbeza';
	@override String get searchYourMedia => 'Cari media anda';
	@override String get enterTitleActorOrKeyword => 'Masukkan tajuk, pelakon, atau kata kunci';
	@override String get people => 'Orang Melayu';
}

// Path: hotkeys
class _Translations$hotkeys$ms extends Translations$hotkeys$en {
	_Translations$hotkeys$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Set Shortcut untuk ${actionName}';
	@override String get clearShortcut => 'Pendekatan yang jelas';
	@override String get noShortcutSet => 'Tiada set pendek';
	@override String get currentShortcut => 'Pendekatan semasa :';
	@override String get pressToRecord => 'Pilih untuk mencatat singkatan';
	@override String get recordingShortcut => 'Tekan singkatan sekarang';
	@override late final _Translations$hotkeys$actions$ms actions = _Translations$hotkeys$actions$ms._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$ms extends Translations$fileInfo$en {
	_Translations$fileInfo$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Maklumat fail';
	@override String get overview => 'Gambaran keseluruhan';
	@override String get video => 'Video';
	@override String get audio => 'Audio yang';
	@override String get subtitles => 'Sari kata';
	@override String get images => 'imej tertanam';
	@override String get dataStreams => 'Aliran Data';
	@override String get lyrics => 'Lirik';
	@override String get file => 'Fail';
	@override String get attachments => 'Penyertaan';
	@override String get delivery => 'Penghantaran';
	@override String versionCounter({required Object index, required Object count}) => 'Versi ${index} daripada ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Fail ${index} daripada ${count}';
	@override String get noStreams => 'Pelayan tidak melaporkan sebarang aliran untuk fail ini.';
	@override String get copyPath => 'Kopi laluan';
	@override String get pathCopied => 'Fail laluan disalin';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Tag Kodek';
	@override String get resolution => 'Resolusi';
	@override String get codedResolution => 'Resolusi Kod';
	@override String get bitrate => 'Perbezaan Bitrate';
	@override String get frameRate => 'Rata-rata kerangka';
	@override String get rotation => 'Rotasi';
	@override String get comment => 'Bagaimana';
	@override String get audioDescription => 'Audio Penerangan';
	@override String get headerCompression => 'Pengertian Kompresi';
	@override String get sidecarFile => 'Laporan Sidecar';
	@override String get transportTimestamp => 'Pengangkutan Timestamp';
	@override String get displayOffset => 'Perbincangan Offset';
	@override String get previewFailureCode => 'Kod Kegagalan Preview';
	@override String get previewRetries => 'Perbincangan Retries';
	@override String get aspectRatio => 'Nisbah aspek';
	@override String get pixelAspectRatio => 'Perbandingan Aspect Pixel';
	@override String get profile => 'Profil';
	@override String get level => 'Tahap';
	@override String get bitDepth => 'Kecil Kedalaman';
	@override String get pixelFormat => 'Pengenalan Pixel';
	@override String get colorSpace => 'Ruang warna';
	@override String get colorRange => 'Rangkaian warna';
	@override String get colorPrimaries => 'Warna primer';
	@override String get colorTransfer => 'Pemindahan warna';
	@override String get chromaSubsampling => 'Pengambilan Chroma';
	@override String get chromaLocation => 'Lokasi Chromium';
	@override String get scanType => 'Jenis pemindaian';
	@override String get interlaced => 'Terhubung';
	@override String get anamorphic => 'Anamorfisme';
	@override String get referenceFrames => 'Rangka rujukan';
	@override String get dynamicRange => 'Rangkaian Dinamik';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision Peringkat';
	@override String get dolbyVisionVersion => 'Dolby Vision Perbincangan';
	@override String get dolbyVisionLayers => 'Dolby Vision Lapisan';
	@override String get baseLayerCompatibility => 'Penyesuaian lapisan asas';
	@override String get avcBitstream => 'Perkhidmatan AVC Bitstream';
	@override String get nalLengthSize => 'NAL panjang saiz';
	@override String get scalingMatrix => 'Matriks Pengukuran Custom';
	@override String get streamIdentifier => 'Pengenalpastian Stream';
	@override String get streamIndex => 'Indeks aliran';
	@override String get streamId => 'Pengenalan ID';
	@override String get language => 'Bahasa Melayu';
	@override String get languageCode => 'Kod Bahasa';
	@override String get streamTitle => 'Tajuk Track';
	@override String get channels => 'Saluran';
	@override String get sampleRate => 'Kadar sampel';
	@override String get spatialAudio => 'Audio ruang';
	@override String get textBased => 'Perkataan berdasarkan';
	@override String get subtitleFormat => 'Pengenalan Format';
	@override String get provider => 'Pembekal';
	@override String get matchScore => 'Perlawanan skor';
	@override String get externalDelivery => 'Boleh disajikan secara berasingan';
	@override String get sidecarPath => 'Laluan Sidecar';
	@override String get sourceStream => 'Diterjemahkan daripada';
	@override String get temporary => 'sementara';
	@override String get timeBase => 'pangkalan masa';
	@override String get overallBitrate => 'Keseluruhan Bitrate';
	@override String get path => 'Jalan';
	@override String get fileName => 'Nama fail';
	@override String get size => 'Ukuran';
	@override String get totalSize => 'Jumlah keseluruhan';
	@override String get container => 'Kontainer';
	@override String get duration => 'tempoh';
	@override String get previewThumbnails => 'Gambaran keseluruhan Thumbnails';
	@override String get previewIndex => 'Indeks Pencapaian';
	@override String get packetLength => 'Panjang pakej';
	@override String get filePresent => 'fail yang hadir';
	@override String get fileReadable => 'boleh dibaca oleh server';
	@override String get streamPath => 'Laluan aliran';
	@override String get optimizedForStreaming => 'Optimisasi untuk Streaming';
	@override String get has64bitOffsets => 'Perbezaan 64-bit';
	@override String get protocol => 'Protokol';
	@override String get mediaType => 'Jenis Media';
	@override String get sourceKind => 'Sumber yang baik';
	@override String get optimizedVersion => 'Versi optimum';
	@override String get optimizationTarget => 'Matlamat Optimisasi';
	@override String get deletedAt => 'dihapuskan';
	@override String get remoteSource => 'Sumber Jarak Jauh';
	@override String get infiniteStream => 'Penghantaran Infinite Stream';
	@override String get directPlay => 'Permainan langsung';
	@override String get directStream => 'aliran langsung';
	@override String get transcoding => 'Transkod';
	@override String get etag => 'ETag';
	@override String get versionId => 'Pengenalan ID';
	@override String get fileId => 'Pengenalan ID';
	@override String get defaultAudioTrack => 'Pengenalan Audio Track';
	@override String get defaultSubtitleTrack => 'Perbezaan Subtitle Track';
	@override String get subtitlesOff => 'keluar';
	@override String get flagDefault => 'Perkataan default';
	@override String get flagForced => 'Paksa';
	@override String get flagSelected => 'dipilih';
	@override String get flagExternal => 'luar';
	@override String get flagHearingImpaired => 'pendengaran yang rosak';
	@override String get flagDub => 'Duba';
	@override String get flagOriginal => 'asal';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Perbincangan:Profil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$ms extends Translations$mediaMenu$en {
	_Translations$mediaMenu$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Tag: seperti yang dilihat';
	@override String get markAsUnwatched => 'Tag: yang tidak dipantau';
	@override String get removeFromContinueWatching => 'Menghapus daripada terus menonton';
	@override String get viewDetails => 'Lihat butiran';
	@override String get goToSeries => 'Pergi ke siri';
	@override String get shufflePlay => 'Permainan Shuffle';
	@override String get shuffleNotAvailableOffline => 'Shuffle tidak boleh didapati offline';
	@override String get fileInfo => 'Maklumat fail';
	@override String get deleteEpisodeFromServer => 'Menghapuskan episod daripada server';
	@override String get deleteSeasonFromServer => 'Menghapuskan musim daripada server';
	@override String get deleteShowFromServer => 'Menghapuskan paparan daripada server';
	@override String get deleteMovieFromServer => 'Menghapuskan filem daripada pelayan';
	@override String get deleteEpisodeTitle => 'Adakah anda menghapuskan episod ini?';
	@override String get deleteSeasonTitle => 'Hentikan musim ini?';
	@override String get deleteShowTitle => 'Hentikan persembahan ini?';
	@override String get deleteMovieTitle => 'Adakah anda memadamkan filem ini?';
	@override String get deleteEpisodeConfirm => 'menghapuskan episod';
	@override String get deleteSeasonConfirm => 'Hilang Musim';
	@override String get deleteShowConfirm => 'Menghapuskan persembahan';
	@override String get deleteMovieConfirm => 'Menghapus filem';
	@override String get deleteAnyway => 'Menghapuskan bagaimanapun';
	@override String confirmDeleteTarget({required Object title}) => 'Permanen menghapuskan ${title} daripada pelayan anda?';
	@override String get deleteMultipleWarning => 'Ini termasuk semua episod dan fail mereka.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: 'Ini memadamkan semua ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episod di dalamnya, dan fail mereka.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: 'Item ini disimpan melalui fail ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dan semua akan dipadamkan.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episod lain disimpan dalam fail yang sama dan juga akan dipadamkan:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG tidak dapat memeriksa fail yang akan dipadamkan, jadi lebih daripada item yang dinyatakan di atas mungkin dipadamkan. Batalkan dan cuba lagi, atau padamkan juga.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Pelayan anda tidak memberikan butiran fail untuk item ini, jadi PlezyNG tidak dapat memeriksa fail yang akan dipadamkan. Lebih daripada item yang dinyatakan di atas mungkin dipadamkan.';
	@override String get mediaDeletedSuccessfully => 'Media item dihapuskan dengan berjaya';
	@override String get mediaFailedToDelete => 'gagal menghapuskan item media';
	@override String get rate => 'Kadar';
	@override String get playFromBeginning => 'Bermain dari awal';
	@override String get playVersion => 'Bermain versi ...';
}

// Path: rateSheet
class _Translations$rateSheet$ms extends Translations$rateSheet$en {
	_Translations$rateSheet$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kadar';
	@override String get server => 'Pelayan';
	@override String get favorite => 'Kegemaran';
	@override String get favorited => 'kegemaran';
	@override String get saved => 'diselamatkan';
	@override String get notAvailable => 'Tiada perlawanan ditemui';
	@override String get noConnectedServices => 'Sambungkan perkhidmatan dalam Settings untuk menilai di sana.';
}

// Path: accessibility
class _Translations$accessibility$ms extends Translations$accessibility$en {
	_Translations$accessibility$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, filem';
	@override String mediaCardShow({required Object title}) => '${title}, rancangan televisyen';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'Pengawasan';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} peratus dilihat';
	@override String get mediaCardUnwatched => 'belum ditonton';
	@override String get tapToPlay => 'Tap untuk bermain';
	@override String get decrease => 'Penurunan';
	@override String get increase => 'Meningkat';
	@override String decreaseValue({required Object label}) => 'Pengurangan ${label}';
	@override String increaseValue({required Object label}) => 'Peningkatan ${label}';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturasi';
	@override String get brightness => 'cahaya terang';
	@override String get hexColor => 'Warna Hex';
	@override String get expandText => 'Meningkatkan teks';
	@override String get collapseText => 'Teks yang runtuh';
	@override String get alphabetNavigation => 'Alphabet navigasi';
	@override String get alphabetScrollHint => 'Leret ke atas atau ke bawah untuk bergerak mengikut huruf';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Laluan ${row} daripada ${rowCount}, lajur ${column} daripada ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Laluan ${row} daripada ${rowCount}';
	@override String get autoScrollPlay => 'Permainan dalam Auto-Scroll';
	@override String get autoScrollPause => 'Perbezaan Auto-Scroll';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S S';
	@override String get valueShort => 'V dalam';
	@override String get red => 'Merah';
	@override String get green => 'hijau';
	@override String get blue => 'Biru';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Aksesibiliti';
	@override String get summary => 'teks, kontras, pergerakan dan kawalan';
	@override String get systemHint => 'Seting aksesibiliti peranti anda sentiasa terpakai. pilihan ini menambah penyesuaian sepanjang PlezyNG.';
	@override String get readability => 'Pembacaan dan penglihatan';
	@override String get textSize => 'Saiz teks tambahan';
	@override String get preview => 'Baca, dengar dan lihat pada kelajuan anda sendiri.';
	@override String get boldText => 'Perbezaan antara muka teks';
	@override String get highContrast => 'kontras yang tinggi';
	@override String get highContrastHint => 'Teks yang lebih kuat, outlines dan fokus indikator pada permukaan cahaya atau gelap.';
	@override String get interaction => 'Pergerakan dan interaksi';
	@override String get reduceMotion => 'Mengurangkan gerakan';
	@override String get reduceMotionHint => 'Hentikan animasi penunjuk fokus, peralihan halaman dan kesan hiasan.';
	@override String get largeTargets => 'Target sentuhan yang lebih besar';
	@override String get largeTargetsHint => 'Memberi kawalan berkongsi lebih banyak ruang untuk sentuhan dan navigasi bantuan.';
	@override String get navigationHint => 'Gunakan Tab dan Shift+Tab untuk bergerak antara kawalan, Enter atau Space untuk mengaktifkan, dan Escape atau butang Kembali untuk menutup. Zum dan keutamaan bacaan tersedia semasa buku dibuka.';
	@override String get textSizeDescription => 'Skala antara muka teks dalam PlezyNG di samping tetapan saiz teks sistem peranti anda.';
	@override String get boldTextHint => 'Gunakan berat yang lebih berat untuk label antara muka dan mesej untuk memudahkan mereka untuk membezakan.';
}

// Path: tooltips
class _Translations$tooltips$ms extends Translations$tooltips$en {
	_Translations$tooltips$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Permainan Shuffle';
	@override String get playTrailer => 'Bermain Trailer';
	@override String get markAsWatched => 'Mark yang dilihat';
	@override String get markAsUnwatched => 'Tag: tidak dipantau';
}

// Path: audioTracks
class _Translations$audioTracks$ms extends Translations$audioTracks$en {
	_Translations$audioTracks$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Perbincangan:Audio Track ${n}';
}

// Path: videoControls
class _Translations$videoControls$ms extends Translations$videoControls$en {
	_Translations$videoControls$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio yang';
	@override String get subtitlesLabel => 'Sari kata';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Kotak Surat';
	@override String get fillScreen => 'Mengisi skrin';
	@override String get stretch => 'Regang';
	@override String get lockRotation => 'Lock rotasi';
	@override String get unlockRotation => 'Menghapuskan rotasi';
	@override String get timerActive => 'Aktiviti Aktiviti';
	@override String playbackWillPauseIn({required Object duration}) => 'Playback akan berhenti pada ${duration}';
	@override String get sleepTimerEndOfVideo => 'Akhir daripada video semasa';
	@override String get sleepTimerStopAtHeader => 'Berhenti untuk';
	@override String get sleepTimerDurationHeader => 'Masa yang';
	@override String get playbackWillPauseAtEnd => 'Playback Akan Berhenti Pada Akhir Video Ini';
	@override String get stillWatching => 'Masih boleh tengok?';
	@override String pausingIn({required Object seconds}) => 'Berhenti dalam ${seconds}s';
	@override String get continueWatching => 'teruskan';
	@override String get autoPlayNext => 'Auto-Play yang seterusnya';
	@override String get playNext => 'Bermain seterusnya';
	@override String get playButton => 'Bermain';
	@override String get pauseButton => 'Henti Sejenak';
	@override String get playbackPaused => 'beristirahat';
	@override String get playbackResumed => 'Bermain';
	@override String get loadingVideo => 'Penghantaran Video';
	@override String get showPlaybackControls => 'Menunjukkan kawalan playback';
	@override String get hidePlaybackControls => 'Menggunakan Playback Control';
	@override String seekBackwardButton({required Object seconds}) => 'Mencari ke belakang ${seconds} saat';
	@override String seekForwardButton({required Object seconds}) => 'Mencari ke hadapan ${seconds} saat';
	@override String get previousButton => 'episod terdahulu';
	@override String get nextButton => 'Episod seterusnya';
	@override String get previousChapterButton => 'Bab sebelumnya';
	@override String get nextChapterButton => 'Bab seterusnya';
	@override String get muteButton => 'Mutu';
	@override String get unmuteButton => 'Tidak banyak';
	@override String get settingsButton => 'Pengaturan Playback';
	@override String get tracksButton => 'Audio dan Subtitle';
	@override String get chaptersButton => 'Bab yang';
	@override String get segmentLoopHelp => 'Setkan A, kemudian setkan B kemudian dalam garis masa.';
	@override String get setLoopStart => 'Set loop permulaan (A)';
	@override String get setLoopEnd => 'Set loop akhir (B)';
	@override String get clearSegmentLoop => 'Segmen yang jelas';
	@override String get setLoopStartFirst => 'Set loop permulaan (A) sebelum akhir (B).';
	@override String get loopEndAfterStart => 'Tarikh akhir mesti lebih lambat daripada permulaan.';
	@override String get segmentLoopUnavailable => 'Segment looping tidak tersedia untuk playback ini.';
	@override String get loopPointNotSet => 'Tidak menetapkan';
	@override String get bookmarksHelp => 'Tanda-tanda buku disimpan pada peranti ini. pilih satu untuk pergi ke masa itu.';
	@override String get bookmarksButton => 'Buku-buku yang';
	@override String get chaptersAndBookmarks => 'Bab dan Bookmark';
	@override String get segmentLoop => 'Perbezaan segmen';
	@override String get addBookmark => 'Menambah Bookmark';
	@override String get bookmarkName => 'Nama Bookmark';
	@override String get bookmarkNameHint => 'Sebagai contoh, adegan pembukaan';
	@override String bookmarkDefaultName({required Object n}) => 'Perpustakaan ${n}';
	@override String get bookmarkNameRequired => 'Masukkan nama untuk buku ini.';
	@override String get deleteBookmark => 'Menghapuskan Bookmark';
	@override String get bookmarkLimitReached => 'Artikel ini sudah mempunyai 100 buku.';
	@override String get bookmarkUnavailable => 'Saya tidak boleh menyimpan atau menghapuskan buku ini.';
	@override String get bookmarkSaved => 'Bookmark diselamatkan';
	@override String get bookmarkDeleted => 'Bookmark telah dihapuskan.';
	@override String loopPointSet({required Object point, required Object time}) => 'Tarikan titik ${point} Set untuk ${time}.';
	@override String get noChaptersOrBookmarks => 'Tiada bab atau buku-buku yang tersedia.';
	@override String get versionQualityButton => 'Versi & Kualiti';
	@override String get versionColumnHeader => 'Versi';
	@override String get qualityColumnHeader => 'Kualiti';
	@override String get qualityOriginal => 'asal';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcoding tidak tersedia - bermain kualiti asal';
	@override String get subtitleUnavailableFallback => 'Subtitle yang dipilih tidak boleh dimuat naik - berterusan tanpa subtitle';
	@override String get pipButton => 'Gambar dalam mode';
	@override String get aspectRatioButton => 'Nisbah aspek';
	@override String get ambientLighting => 'Lampu persekitaran';
	@override String get fullscreenButton => 'Masuk skrin penuh';
	@override String get exitFullscreenButton => 'Keluarkan skrin penuh';
	@override String get alwaysOnTopButton => 'Selalu di atas';
	@override String get rotationLockButton => 'Lencana Rotasi';
	@override String get lockScreen => 'Menutup skrin';
	@override String get screenLockButton => 'Penutup skrin';
	@override String get timelineSlider => 'Tarikh video';
	@override String get volumeSlider => 'Tahap Volume';
	@override String endsAt({required Object time}) => 'Berakhir pada ${time}';
	@override String get pipActive => 'Bermain dalam Picture-in-Picture';
	@override String get pipFailed => 'Gambar-gambar dalam gagal bermula';
	@override String get screenshotSaved => 'Screenshot disimpan';
	@override String get screenshotFailed => 'Tidak boleh mengambil screenshot';
	@override String zoomPercent({required Object percent}) => 'Zum ${percent}%';
	@override String volumePercent({required Object percent}) => 'Kelantangan ${percent}%';
	@override late final _Translations$videoControls$pipErrors$ms pipErrors = _Translations$videoControls$pipErrors$ms._(_root);
	@override String get chapters => 'Bab yang';
	@override String get noChaptersAvailable => 'Tiada bab yang tersedia';
	@override String get queue => 'Perbincangan';
	@override String get noQueueItems => 'Tiada item dalam Queue';
	@override String get noAudioDevicesAvailable => 'Tiada peranti audio yang tersedia';
	@override String get searchSubtitles => 'Pencarian Subtitle';
	@override String get language => 'Bahasa Melayu';
	@override String get noSubtitlesFound => 'Tiada subtitle yang ditemui';
	@override String get subtitleDownloaded => 'Subtitle dikurangkan';
	@override String get subtitleDownloadedNotApplied => 'Subtitle telah dimuat turun, tetapi tidak boleh dipilih';
	@override String get subtitleDownloadFailed => 'Tidak boleh download subtitle';
	@override String get searchLanguages => 'Pencarian Bahasa...';
	@override String get skipIntro => 'Lapangan Terbang Intro';
	@override String get skipCredits => 'Melompat kredit';
	@override String get nextEpisode => 'Episod berikutnya';
	@override String subtitleTrack({required Object n}) => 'Lapangan Terbang ${n}';
	@override String subtitleFile({required Object name}) => 'Tajuk : ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Perkh<unk> yang diperlukan)';
	@override String get osdSubtitlesOff => 'Tajuk : Off';
	@override String osdSubtitles({required Object track}) => 'Tajuk : ${track}';
	@override String osdAudio({required Object track}) => 'Perbincangan : ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} penghalang',
	);
	@override String get trackSelectionTitle => 'Pilih trek sebelum playback';
	@override String get trackSelectionAuto => 'Pemilihan automatik';
	@override String get openMiniPlayer => 'Permainan Mini Terbuka';
	@override String get returnToFullPlayer => 'Kembali kepada pemain penuh';
	@override String get loadSubtitleFile => 'Mengisi subtitle fail ...';
	@override String get subtitleLoadFailed => 'gagal untuk memuat turun subtitle fail';
	@override String get skipAds => 'Laporan Ads';
	@override String get tapToUnlock => 'Ketik untuk membuka kunci';
	@override String get tapAgainToUnlock => 'Ketik sekali lagi untuk membuka kunci';
}

// Path: messages
class _Translations$messages$ms extends Translations$messages$en {
	_Translations$messages$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Ditandakan seperti yang dilihat';
	@override String get markedAsUnwatched => 'Ditandakan sebagai tidak diperhatikan';
	@override String get markedAsWatchedOffline => 'Menandakan seperti yang dilihat (sinkronkan apabila dalam talian)';
	@override String get markedAsUnwatchedOffline => 'Ditandakan sebagai tidak dipantau (sinkronkan apabila dalam talian)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Pengeluaran : ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dilihat muat turun',
	);
	@override String get removedFromContinueWatching => 'Menghapus daripada terus menonton';
	@override String errorLoading({required Object error}) => 'Kesilapan : ${error}';
	@override String get searchPartialResults => 'Sesetengah pelayan media tidak boleh dicari. menunjukkan hasil yang tersedia.';
	@override String get streamInterrupted => 'Aliran telah dihentikan. bermain percetakan atau cuba untuk berundur.';
	@override String get liveStreamInterrupted => 'siaran langsung telah dihentikan. siaran akhbar untuk retry.';
	@override String get fileInfoNotAvailable => 'Maklumat fail tidak tersedia';
	@override String get playbackAuthenticationRequired => 'Mendaftar masuk ke pelayan media sekali lagi untuk memainkan item ini.';
	@override String get playbackServerUnavailable => 'Server media tidak tersedia. cuba lagi kemudian.';
	@override String get playbackDataInvalid => 'Pelayan mengembalikan maklumat playback yang tidak sah.';
	@override String get playbackCancelled => 'Playback telah dibatalkan.';
	@override String get playbackFailed => 'Playback tidak boleh dimulakan.';
	@override String playbackFailedDetail({required Object error}) => 'Playback tidak boleh dimulakan: ${error}';
	@override String get audioOutputFailed => 'Periksa sambungan audio TV atau penerima; jika aplikasi lain tidak mempunyai bunyi sama sekali, mulakan semula peranti.';
	@override String get mediaUnavailable => 'Kandungan ini tidak lagi tersedia.';
	@override String errorLoadingFileInfo({required Object error}) => 'Fail pengecasan kesilapan info: ${error}';
	@override String get errorLoadingSeries => 'Kesilapan siri pengisian';
	@override String get musicNotSupported => 'Playback muzik belum disokong';
	@override String get noDescriptionAvailable => 'Tiada penerangan yang tersedia';
	@override String get noProfilesAvailable => 'Tiada profil yang tersedia';
	@override String get contactAdminForProfiles => 'Hubungi pentadbir pelayan anda untuk menambah profil';
	@override String get unableToDetermineLibrarySection => 'Tidak dapat menentukan bahagian perpustakaan untuk item ini';
	@override String get logsCleared => 'Log yang dibersihkan';
	@override String get logsCopied => 'Logs disalin ke clipboard';
	@override String get noLogsAvailable => 'Tiada log yang tersedia';
	@override String libraryScanning({required Object title}) => 'Mengimbas “${title}”';
	@override String libraryScanStarted({required Object title}) => 'Perpustakaan pemindaian bermula untuk "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Kegagalan untuk memindai perpustakaan: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Mengemaskini metadata untuk "${title}" ...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadata pembaharuan bermula untuk "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Tidak dapat memperbaharui metadata: ${error}';
	@override String get logoutConfirm => 'Adakah anda pasti anda mahu log keluar?';
	@override String get noSeasonsFound => 'Tiada musim yang ditemui';
	@override String get seasonsLoadFailed => 'Tidak boleh mengisi musim';
	@override String get noEpisodesFound => 'Tiada episod yang ditemui pada musim pertama';
	@override String get noEpisodesFoundGeneral => 'Tiada episod yang ditemui';
	@override String get episodesLoadFailed => 'Tidak boleh memuatkan episod';
	@override String get noResultsFound => 'Tiada hasil yang ditemui';
	@override String sleepTimerSet({required Object label}) => 'Jam tidur set untuk ${label}';
	@override String get noItemsAvailable => 'Tiada item yang tersedia';
	@override String get failedToCreatePlayQueueNoItems => 'gagal untuk mencipta permainan kue - tiada item';
	@override String failedPlayback({required Object action, required Object error}) => 'Kegagalan ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Menukar kepada pemain yang kompatibel ...';
	@override String get serverLimitTitle => 'Playback gagal';
	@override String get serverLimitBody => 'Kesilapan pelayan (HTTP 500). had lebar jalur/transcoding mungkin menolak sesi ini.';
	@override String get mediaUnreadableTitle => 'fail yang tidak tersedia';
	@override String get mediaUnreadableBody => 'Pelayan mendapati item ini tetapi tidak dapat membaca failnya (HTTP 404). fail itu mungkin telah dipindahkan, dipadamkan, atau penyimpanan adalah offline.';
	@override String get serverBusyTitle => 'aliran tidak tersedia';
	@override String get serverBusyBody => 'Pelayan tetap enggan untuk menyiarkan fail ini (HTTP 503). ia boleh memulakan semula, sibuk, atau penyimpanan fail mungkin offline. cuba lagi dalam sekejap - jika ia terus berlaku, minta pemilik pelayan untuk memeriksa pelayan dan penyimpanan fail.';
	@override String get playbackNotAllowedTitle => 'Playback tidak dibenarkan';
	@override String get playbackNotAllowedBody => 'Pelayan menolak untuk menyiarkan item ini (HTTP 403). akaun anda mungkin tidak dibenarkan untuk memainkannya, atau pelayan hanya boleh membenarkan pemutaran pada rangkaian tempatan.';
	@override String get logsUploaded => 'Log yang diunggah';
	@override String get logsUploadFailed => 'Kegagalan untuk memuat naik log';
	@override String get logId => 'Pengenalan ID';
	@override String get burnedSubtitlesUseMenu => 'Subtitle dibakar ke dalam aliran ini. tukar mereka daripada menu subtitle.';
	@override String get noVideoUrl => 'Tiada URL video yang tersedia';
	@override String get playbackNoMediaSources => 'Server tidak mengembalikan sumber media yang boleh dimainkan';
	@override String get playbackDataNotPrepared => 'Playback bermula sebelum data telah siap.';
	@override String get streamSelectionUnavailable => 'Stream Selection tidak tersedia untuk sumber ini';
	@override String get streamSelectionFailed => 'Tidak boleh menggunakan aliran yang dipilih';
	@override String get trackSelectionNotRemembered => 'Pilihan trek ini hanya terpakai kepada playback semasa.';
	@override String get serverUnavailableForProfile => 'Tiada pelayan boleh didapati untuk profil aktif';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$ms extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Tag: anjing coklat cepat melompat ke atas anjing lazy';
	@override String get text => 'teks';
	@override String get border => 'Perbatasan';
	@override String get background => 'latar belakang';
	@override String get fontSize => 'Tag: saiz font';
	@override String get textColor => 'Warna teks';
	@override String get borderSize => 'Perbatasan saiz';
	@override String get borderColor => 'Warna Perbatasan';
	@override String get backgroundOpacity => 'Latar Belakang Opacity';
	@override String get backgroundColor => 'warna latar belakang';
	@override String get position => 'Kedudukan';
	@override String get assOverride => 'ASS Perbezaan';
	@override String get overrideScale => 'skala';
	@override String get overrideForce => 'Kekuatan';
	@override String get overrideStrip => 'Menghapuskan styling';
	@override String get positionTop => 'Top';
	@override String get positionBottom => 'Bawah';
	@override String get useMargins => 'Menggunakan margin';
	@override String get useMarginsDescription => 'Biarkan subtitle teks di dalam ruang di luar video. subtitle bergaya boleh mengekalkan penempatan asal mereka.';
	@override String get anchorToScreen => 'Anchor untuk skrin';
	@override String get anchorToScreenDescription => 'Tunjukkan subtitle teks dalam bar hitam di bawah video skrin lebar';
	@override String get bold => 'berani';
	@override String get italic => 'Bahasa Itali';
	@override String get renderResolution => 'Resolusi Render';
	@override String get renderResolutionScreen => 'resolusi skrin';
	@override String get renderResolutionVideo => 'Video resolusi';
	@override String get fontSizeDescription => 'Setkan saiz teks subtitle pada peranti ini.';
	@override String get textColorDescription => 'Pilih warna yang digunakan untuk teks subtitle.';
	@override String get borderSizeDescription => 'Tetapkan ketebalan outline di sekeliling teks subtitle.';
	@override String get borderColorDescription => 'Pilih warna yang digunakan untuk subtitle outline.';
	@override String get backgroundColorDescription => 'Pilih warna di sebalik subtitle teks.';
	@override String get backgroundOpacityDescription => 'Tetapkan betapa telus latar belakang subtitle ialah: 0% jelas dan 100% kukuh.';
	@override String get positionDescription => 'Pergerakan subtitle secara vertikal. 0% adalah bahagian atas video dan 100% adalah bahagian bawah.';
	@override String get assOverrideDescription => 'Pilih sama ada pemain mengikuti, menyesuaikan, menggantikan atau menghapuskan gaya yang dimasukkan ke dalam subtitle ASS.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$ms assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$ms._(_root);
	@override String get renderResolutionDescription => 'Pilih resolusi yang digunakan untuk rasterize imej dan subtitle ASS. Skala Android yang lebih rendah boleh mengurangkan kerja rendering tetapi kelihatan lebih lembut.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$ms renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$ms._(_root);
	@override String get boldDescription => 'Menarik teks subtitle dalam berat yang lebih berat.';
	@override String get italicDescription => 'Menarik subtitle teks dalam bahasa Itali.';
}

// Path: mpvConfig
class _Translations$mpvConfig$ms extends Translations$mpvConfig$en {
	_Translations$mpvConfig$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Pengaturan pemutar video lanjutan';
	@override String get presets => 'Persembahan';
	@override String get noPresets => 'Tiada preset yang diselamatkan';
	@override String get saveAsPreset => 'Menyelamatkan sebagai preset';
	@override String get presetName => 'Nama Praset';
	@override String get presetNameHint => 'Masukkan nama untuk preset ini';
	@override String get loadPreset => 'Pengangkutan';
	@override String get deletePreset => 'Padam';
	@override String get presetSaved => 'Preset selamatkan';
	@override String get presetLoaded => 'Preset dikendalikan';
	@override String get presetDeleted => 'Preset telah dihapuskan';
	@override String get confirmDeletePreset => 'Adakah anda pasti anda mahu memadamkan preset ini?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # komen';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Tambah garis';
	@override String get removeLine => 'Menghilangkan garis';
	@override String get embeddedVoHint => 'vo, konteks gpu dan gpu-api diabaikan pada Linux: video tertanam sentiasa mengalir melalui vo=libmpv pada pesawat video, dan gpu-next (yang bayangan komputer seperti ArtCNN perlu) tidak boleh berjalan tertanam.';
}

// Path: dialog
class _Translations$dialog$ms extends Translations$dialog$en {
	_Translations$dialog$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Mengesahkan tindakan';
}

// Path: profiles
class _Translations$profiles$ms extends Translations$profiles$en {
	_Translations$profiles$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Menambah PlezyNG profil';
	@override String get switchingProfile => 'Menukar profil ...';
	@override String get deleteThisProfileTitle => 'Menghapuskan profil ini?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Menghapus ${displayName}. sambungan tidak terjejas.';
	@override String get active => 'Aktiviti';
	@override String get manage => 'Pengurusan';
	@override String get delete => 'Padam';
	@override String get signOut => 'Sign out';
	@override String get signOutPlexTitle => 'Mendaftar keluar daripada Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Menghapuskan ${displayName} dan semua Plex Pengguna Rumah?';
	@override String get signOutPlexDeleteDownloads => 'Juga menghapuskan download';
	@override String get signOutPlexDeleteDownloadsDescription => 'Jika tidak, mereka akan kekal pada peranti ini dan kembali apabila anda mendaftar kembali ke akaun ini.';
	@override String get signedOutPlex => 'Ditandatangani daripada Plex.';
	@override String get signOutFailed => 'Menandatangani gagal';
	@override String get sectionTitle => 'Profil';
	@override String get summarySingle => 'Menambah profil untuk mencampur pengguna yang dikendalikan dan identiti tempatan';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profil · aktif: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} Profil';
	@override String get removeConnectionTitle => 'Menghapuskan sambungan?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Menghapuskan akses ${displayName} ke ${connectionLabel}. profil lain menyimpannya.';
	@override String get deleteProfileTitle => 'Menghapuskan profil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Menghapuskan ${displayName} dan sambungan. pelayan kekal tersedia.';
	@override String get profileNameLabel => 'Nama Profil';
	@override String get pinProtectionLabel => 'Perlindungan PIN';
	@override String get copyAutomationLink => 'Salinan Android pautan automatik';
	@override String get copyAutomationLinkDescription => 'Pilih profil ini daripada niat atau automatik Android. pemeriksaan PIN profil masih terpakai.';
	@override String get automationLinkCopied => 'Profil automatik pautan disalin.';
	@override String get pinManagedByPlex => 'PIN dikendalikan oleh Plex. Edit di plex.tv.';
	@override String get noPinSetEditOnPlex => 'Tidak ada set PIN. Untuk memerlukan satu, mengedit pengguna rumah di plex.tv.';
	@override String get setPin => 'Menyediakan PIN';
	@override String get setPinTitle => 'Menyediakan PIN';
	@override String get confirmPinTitle => 'Mengesahkan PIN';
	@override String get pinSet => 'Pin set';
	@override String get changePin => 'Perubahan';
	@override String get removePin => 'Keluarkan';
	@override String get connectionsLabel => 'sambungan';
	@override String get add => 'Tambah';
	@override String get deleteProfileButton => 'Menghapuskan profil';
	@override String get noConnectionsHint => 'Tiada sambungan - tambahkan satu untuk menggunakan profil ini.';
	@override String get noConnections => 'Tiada sambungan';
	@override String get plexHomeAccount => 'Plex Akaun rumah';
	@override String plexAccountChip({required Object account}) => 'Plex akaun: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} melalui ${account}';
	@override String get connectionDefault => 'Perkataan default';
	@override String connectionAs({required Object displayName}) => 'daripada ${displayName}';
	@override String get makeDefault => 'Menjadikan default';
	@override String get removeConnection => 'Keluarkan';
	@override String get profileRenamed => 'Profil yang dinamakan semula.';
	@override String borrowAddTo({required Object displayName}) => 'Menambah kepada ${displayName}';
	@override String get borrowExplain => 'Pinjaman sambungan profil lain. profil yang dilindungi PIN memerlukan PIN.';
	@override String get borrowEmpty => 'Tiada apa-apa lagi yang boleh dipinjam.';
	@override String get borrowEmptySubtitle => 'Sambungkan Plex, Jellyfin, atau Emby kepada profil lain terlebih dahulu.';
	@override String get borrowLoadFailed => 'sambungan yang tersedia tidak boleh dimuat naik. cuba lagi.';
	@override String borrowFromProfile({required Object displayName}) => 'daripada ${displayName}';
	@override String get borrowConnectionBorrowed => 'sambungan yang dipinjam.';
	@override String get borrowFailed => 'Tidak berjaya meminjamkan sambungan.';
	@override String get incorrectPin => 'Pin yang tidak betul';
	@override String get incorrectPinTryAgain => 'Pin yang salah, sila cuba lagi.';
	@override String get sourceProfileMissingParentAccount => 'Profil sumber kekurangan akaun ibu.';
	@override String get failedToLoadHomeUsers => 'Tidak boleh memuatkan pengguna rumah anda Plex . semak sambungan anda dan cuba lagi.';
	@override String get failedToVerifyPin => 'Tidak boleh mengesahkan PIN.';
	@override String get newProfile => 'Profil baru';
	@override String get profileNameHint => 'contohnya tetamu, kanak-kanak, bilik keluarga';
	@override String get pinProtectionOptional => 'Perlindungan PIN (pilihan)';
	@override String get pinExplain => 'PIN 4 digit diperlukan untuk menukar profil.';
	@override String get continueButton => 'teruskan';
	@override String get pinsDontMatch => 'Pin tidak sesuai';
	@override String get tokenIdentityMismatch => 'Token profil Plex diselesaikan ke pelayan yang tidak dijangka';
	@override String get settingsLocked => 'Seting disekat untuk profil ini.';
	@override String get unlockSettings => 'Menghapus tetapan';
	@override String get showExploreForProfile => 'Tunjukkan Penjelajahan untuk Profil ini';
	@override String get showExploreForProfileDescription => 'Matikan untuk menghapuskan Explore daripada navigasi profil ini.';
}

// Path: connections
class _Translations$connections$ms extends Translations$connections$en {
	_Translations$connections$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'sambungan';
	@override String get addConnection => 'Menambah sambungan';
	@override String get addConnectionSubtitleNoProfile => 'Mendaftar dengan Plex atau sambungkan Jellyfin atau Emby server';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Tambah ke ${displayName}: Plex, Jellyfin, Emby, atau sambungan profil lain';
	@override String sessionExpiredOne({required Object name}) => 'Sesi berakhir untuk ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sesi berakhir untuk ${count} pelayan';
	@override String accessDeniedOne({required Object name}) => '${name} menolak akses kepada akaun ini';
	@override String accessDeniedMany({required Object count}) => '${count} pelayan menolak akses kepada akaun ini';
	@override String get signInAgain => 'Menandatangani lagi';
	@override String editMediaBrowserTitle({required Object product}) => 'Edit ${product} sambungan';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Menambah atau menghapuskan URL untuk ${serverName}. PlezyNG akan menggunakan URL yang boleh dicapai dengan latensi terendah.';
}

// Path: accountPreferences
class _Translations$accountPreferences$ms extends Translations$accountPreferences$en {
	_Translations$accountPreferences$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Keutamaan akaun';
	@override String hubSubtitleSingle({required Object account}) => 'Audio, subtitle dan pilihan perpustakaan disimpan pada ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Audio, subtitle dan pilihan perpustakaan disimpan pada ${count} akaun';
	@override String get pickAccount => 'Setiap akaun menyimpan keutamaan mereka sendiri. pilih yang untuk mengedit.';
	@override String get storedOnAccount => 'Pilihan-pilihan ini disimpan pada akaun itu sendiri, jadi setiap aplikasi yang mendaftar masuk ke dalamnya menggunakan mereka - termasuk PlezyNG pada peranti lain anda.';
	@override String get noAccounts => 'Tiada akaun yang boleh dikonfigurasi';
	@override String get noAccountsHint => 'Mendaftar masuk ke Plex, atau sambungkan pelayan Jellyfin atau Emby, dan keutamaan yang disimpan pada akaun itu dipaparkan di sini.';
	@override String get unavailable => 'Tidak boleh mencapai akaun ini';
	@override String get loadFailed => 'Tidak boleh memuatkan keutamaan ini';
	@override String get noPreference => 'Tiada keutamaan';
	@override String get notSet => 'Tidak menetapkan';
	@override late final _Translations$accountPreferences$groups$ms groups = _Translations$accountPreferences$groups$ms._(_root);
	@override String get preferredAudioLanguage => 'Bahasa audio yang disukai';
	@override String get autoSelectAudio => 'Pilih audio mengikut bahasa';
	@override String get autoSelectAudioDescription => 'Menghapus mengekalkan apa-apa audio yang menjejak fail sebagai lalai.';
	@override String get preferredSubtitleLanguage => 'Bahasa Subtitle yang disukai';
	@override String get subtitleMode => 'Tukar subtitle pada';
	@override late final _Translations$accountPreferences$subtitleModes$ms subtitleModes = _Translations$accountPreferences$subtitleModes$ms._(_root);
	@override String get subtitleAccessibility => 'Tajuk SDH';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$ms subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$ms._(_root);
	@override String get forcedSubtitles => 'Subtitle yang terpaksa';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$ms forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$ms._(_root);
	@override String get displayMissingEpisodes => 'Menunjukkan episod yang hilang';
	@override String get displayMissingEpisodesDescription => 'Senarai episod yang pelayan tahu tentang tetapi tidak mempunyai fail untuk.';
	@override String get hidePlayedInLatest => 'Menyembunyikan item yang dilihat dalam terkini';
	@override String get hidePlayedInLatestDescription => 'Tinggalkan item yang telah anda lihat daripada baris terakhir pelayan.';
	@override String get displayCollectionsView => 'Tunjukkan pandangan koleksi';
	@override String get displayCollectionsViewDescription => 'Tawarkan pandangan Koleksi pelayan di sebelah perpustakaan anda.';
	@override String get rewatchingInNextUp => 'Tinggalkan persembahan yang disemak semula di Next Up';
	@override String get rewatchingInNextUpDescription => 'Sebaik sahaja anda selesai persembahan, mulakan semula dan Next Up mengikuti rewatch daripada menurunkan persembahan.';
	@override String get watchedIndicator => 'Indikator yang dilihat';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$ms watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$ms._(_root);
	@override String get mediaReviewsVisibility => 'Penilaian & Ulasan';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$ms mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$ms._(_root);
	@override String get preferredAudioLanguageDescription => 'Lebih suka trek audio dalam bahasa ini apabila pelayan atau pemain memilih trek secara automatik.';
	@override String get preferredSubtitleLanguageDescription => 'Lebih suka mengikuti subtitle dalam bahasa ini apabila subtitle dipilih secara automatik.';
	@override String get subtitleAccessibilityDescription => 'Pilih sama ada capsi SDH disukai atau diperlukan semasa pemilihan subtitle automatik.';
	@override String get forcedSubtitleDescription => 'Pilih sama ada trek subtitle paksa disukai atau diperlukan semasa pemilihan automatik.';
	@override String get watchedIndicatorDescription => 'Pilih jenis media yang menerima tanda semak yang dilihat dalam antara muka pelayan.';
	@override String get mediaReviewsVisibilityDescription => 'Pilih penonton dan penilaian kritikal yang dipaparkan oleh pelayan pada halaman media.';
	@override String get subtitleModeDescription => 'Pilih apabila subtitle akan diaktifkan secara automatik untuk akaun pelayan ini.';
	@override String get hubDescription => 'Keutamaan ini disimpan pada akaun media-server anda dan boleh digunakan untuk pelanggan lain juga.';
}

// Path: discover
class _Translations$discover$ms extends Translations$discover$en {
	_Translations$discover$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Menjelajahi';
	@override String get noContentAvailable => 'Tiada kandungan yang tersedia';
	@override String get addMediaToLibraries => 'Tambah beberapa media ke perpustakaan anda';
	@override String get continueWatching => 'Menyambung tontonan';
	@override String continueWatchingIn({required Object library}) => 'Lihat lagi reviu untuk ${library}';
	@override String get nextUp => 'Seterusnya Up';
	@override String nextUpIn({required Object library}) => 'Seterusnya Up dalam ${library}';
	@override String get recentlyAdded => 'baru-baru ini ditambah';
	@override String recentlyAddedIn({required Object library}) => 'Baru-baru ini ditambah dalam ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Album terkini dalam ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Dimainkan baru-baru ini dalam ${library}';
	@override String mostPlayedIn({required Object library}) => 'Paling banyak dimainkan dalam ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'M${season}E${episode}';
	@override String get overview => 'Gambaran keseluruhan';
	@override String get cast => 'Tembakan';
	@override late final _Translations$discover$findNext$ms findNext = _Translations$discover$findNext$ms._(_root);
	@override String get extras => 'Pelancaran & Extra';
	@override String get studio => 'Pengajian';
	@override String get rating => 'Penilaian';
	@override String get director => 'Pengarah';
	@override String get directors => 'Pengarah';
	@override String get movie => 'filem';
	@override String get tvShow => 'Persembahan TV';
	@override String minutesLeft({required Object minutes}) => 'Baki ${minutes} min';
	@override String get moreLikeThis => 'lebih seperti ini';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tajuk',
	);
	@override late final _Translations$discover$person$ms person = _Translations$discover$person$ms._(_root);
}

// Path: errors
class _Translations$errors$ms extends Translations$errors$en {
	_Translations$errors$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Pencarian yang gagal: ${error}';
	@override String get searchUnavailable => 'Pencarian tidak boleh mencapai mana-mana pelayan media.';
	@override String connectionTimeout({required Object context}) => 'Sambungan timeout semasa muat ${context}';
	@override String get connectionFailed => 'Tidak dapat menyambung ke server media';
	@override String unableToLoad({required Object context}) => 'Tidak boleh memuatkan ${context}. sila cuba lagi.';
	@override String get noClientAvailable => 'Tiada pelanggan yang tersedia';
	@override String get pleaseEnterToken => 'Sila masukkan token';
	@override String get invalidToken => 'Token yang tidak sah';
	@override String failedToVerifyToken({required Object error}) => 'Token yang gagal disahkan: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kegagalan untuk menukar kepada ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Tidak boleh dipadamkan ${displayName}';
	@override String get failedToRate => 'Tidak boleh update rating';
	@override String get reasonTimedOut => 'sambungan yang ditangguhkan';
	@override String get reasonUnreachable => 'Pelayan tidak boleh diakses';
	@override String get reasonRefused => 'Pelayan menolak permintaan';
	@override String get reasonNotFound => 'item tidak lagi di server';
	@override String get reasonServerError => 'Pelayan melaporkan kesilapan';
	@override String get reasonCancelled => 'Permohonan telah dibatalkan';
	@override String get reasonUnexpected => 'Kesilapan yang tidak dijangka berlaku';
}

// Path: libraries
class _Translations$libraries$ms extends Translations$libraries$en {
	_Translations$libraries$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Mainkan sebuah filem rawak';
	@override String get randomPickFailed => 'Tidak boleh memilih filem rawak daripada perpustakaan ini.';
	@override String get title => 'Pustaka';
	@override String get fallbackTitle => 'Pustaka';
	@override String get scanLibraryFiles => 'Perpustakaan fail';
	@override String get scanLibrary => 'Perpustakaan Scan';
	@override String get analyze => 'Analisis';
	@override String get analyzeLibrary => 'Analisis Perpustakaan';
	@override String get refreshMetadata => 'Meningkatkan Metadata';
	@override String get emptyTrash => 'Kerosakan kosong';
	@override String emptyingTrash({required Object title}) => 'Pembersihan sampah untuk "${title}"';
	@override String trashEmptied({required Object title}) => 'Perbincangan:Penggambaran untuk "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Kegagalan untuk membuang sampah kosong: ${error}';
	@override String analyzing({required Object title}) => 'Perbincangan : ${title}';
	@override String analysisStarted({required Object title}) => 'Analisis bermula untuk "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Kegagalan untuk menganalisis perpustakaan: ${error}';
	@override String get noLibrariesFound => 'Tiada perpustakaan yang ditemui';
	@override String get allLibrariesHidden => 'Semua perpustakaan tersembunyi';
	@override String hiddenLibrariesCount({required Object count}) => 'Perpustakaan yang tersembunyi (${count})';
	@override String get thisLibraryIsEmpty => 'Perpustakaan ini kosong';
	@override String get noItemsMatchFilters => 'Tiada item yang sepadan dengan penapis aktif';
	@override String get resetFilters => 'Filter semula';
	@override String get all => 'Semua';
	@override String get clearAll => 'Semua jelas';
	@override String scanLibraryConfirm({required Object title}) => 'Adakah anda pasti anda mahu memindai "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Adakah anda pasti anda mahu menganalisis "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Adakah anda pasti anda mahu memperbaharui metadata untuk "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Adakah anda pasti anda mahu mengosongkan sampah untuk "${title}"?';
	@override String get manageLibraries => 'Pengurusan Perpustakaan';
	@override String get sort => 'Berwarna';
	@override String get sortBy => 'Berbahagialah dengan';
	@override String get filters => 'Penapis';
	@override String get confirmActionMessage => 'Adakah anda pasti anda mahu melaksanakan tindakan ini?';
	@override String get showLibrary => 'Tunjukkan Perpustakaan';
	@override String get hideLibrary => 'Perpustakaan tersembunyi';
	@override String get libraryOptions => 'Pilihan Perpustakaan';
	@override String get content => 'Perpustakaan kandungan';
	@override String get selectLibrary => 'Pilih Perpustakaan';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Tiada cadangan yang tersedia';
	@override String get noCollections => 'Tiada koleksi dalam perpustakaan ini';
	@override String get noFoldersFound => 'Tiada folder yang ditemui';
	@override String get folders => 'Folder-folder';
	@override late final _Translations$libraries$tabs$ms tabs = _Translations$libraries$tabs$ms._(_root);
	@override late final _Translations$libraries$groupings$ms groupings = _Translations$libraries$groupings$ms._(_root);
	@override late final _Translations$libraries$filterCategories$ms filterCategories = _Translations$libraries$filterCategories$ms._(_root);
	@override late final _Translations$libraries$sortLabels$ms sortLabels = _Translations$libraries$sortLabels$ms._(_root);
	@override late final _Translations$libraries$advancedFilters$ms advancedFilters = _Translations$libraries$advancedFilters$ms._(_root);
	@override late final _Translations$libraries$selection$ms selection = _Translations$libraries$selection$ms._(_root);
}

// Path: about
class _Translations$about$ms extends Translations$about$en {
	_Translations$about$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mengenai';
	@override String get openSourceLicenses => 'Lesen sumber terbuka';
	@override String versionLabel({required Object version}) => 'Perbincangan:Bahasa Inggeris ${version}';
	@override String get appDescription => 'Pelanggan yang indah Plex, Jellyfin, dan Emby untuk Flutter';
	@override String get viewLicensesDescription => 'Lihat lesen perpustakaan pihak ketiga';
	@override String get privacyPolicy => 'Kebijakan Privasi';
}

// Path: serverSelection
class _Translations$serverSelection$ms extends Translations$serverSelection$en {
	_Translations$serverSelection$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Tiada pelayan yang ditemui untuk ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Pelayan yang gagal memuat naik: ${error}';
	@override String get noValidServers => 'Tiada pelayan yang boleh digunakan ditemui dalam akaun ini';
}

// Path: hubDetail
class _Translations$hubDetail$ms extends Translations$hubDetail$en {
	_Translations$hubDetail$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tajuk';
	@override String get releaseYear => 'Tahun pelepasan';
	@override String get dateAdded => 'Tarikh ditambah';
	@override String get rating => 'Penilaian';
	@override String get noItemsFound => 'Tiada item yang ditemui';
}

// Path: logs
class _Translations$logs$ms extends Translations$logs$en {
	_Translations$logs$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Log yang jelas';
	@override String get copyLogs => 'Menyalin log';
	@override String get uploadLogs => 'Meningkatkan log';
	@override String get saveLogs => 'Simpan log ke fail';
	@override String logsSaved({required Object path}) => 'Rekod disimpan pada ${path}';
	@override String get saveLogsFailed => 'Saya tidak boleh menyimpan fail log.';
}

// Path: startup
class _Translations$startup$ms extends Translations$startup$en {
	_Translations$startup$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG tidak boleh bermula';
	@override String get failedBody => 'Sesuatu yang salah semasa permulaan. butiran di bawah mengenal pasti apa yang gagal.';
	@override String get failedBodyRepairable => 'Fail tetapan PlezyNG yang disimpan rosak dan perlu dibina semula sebelum aplikasi boleh bermula. Mencuba lagi tidak akan membantu — pilih Baiki storan.';
	@override String get phaseLabel => 'Langkah';
	@override String get showDetails => 'Tunjukkan butiran';
	@override String get hideDetails => 'menyembunyikan butiran';
	@override String get copyDetails => 'Menyalin butiran';
	@override String get detailsCopied => 'Maklumat disalin ke clipboard';
	@override String get uploadDetails => 'Tambah butiran';
	@override String get repairStorage => 'Perbaikan penyimpanan';
	@override String get repairTitle => 'Perbaikan data yang disimpan?';
	@override String get repairBodyCommon => 'Fail tetapan PlezyNG rosak dan tidak boleh dibaca. pembaikan memulihkan setiap tetapan kepada lalai.';
	@override String get repairBodyOneCredential => 'Satu log masuk yang disimpan rosak dan tidak boleh dibaca. pembaikan menghapuskan hanya satu; tetapan lain anda ditinggalkan sendirian.';
	@override String get repairBodySignInsKept => 'Sesi log masuk pelayan dan profil anda sepatutnya kekal aktif.';
	@override String get repairBodySignInsLost => 'Kunci yang melindungi maklumat log masuk tersimpan tidak dapat dipulihkan daripada fail ini. Anda perlu log masuk semula ke setiap pelayan dan profil. Tiada apa-apa pada pelayan media anda terjejas.';
	@override String get repairBodySessionsUncertain => 'Data penjejak (MAL, AniList, Simkl, Trakt) dan Seerr disimpan secara berasingan dan mungkin kekal atau hilang. PlezyNG akan memberitahu anda dengan tepat data yang dikekalkan.';
	@override String get repairConfirm => 'Perbaikan';
	@override String get repairSucceeded => 'Penyimpanan diperbaiki';
	@override String get repairNeedsRestart => 'Penyimpanan diperbaiki - perlu memulakan semula';
	@override String get restartRequiredBody => 'Data anda telah dibaiki, tetapi PlezyNG perlu dimulakan semula sebelum dapat menggunakannya. Tutup PlezyNG dan buka semula.';
	@override String get quitPlezy => 'Perbincangan:Penghantaran PlezyNG';
	@override String get repairFailed => 'Perbaikan gagal';
	@override String get repairKeptSignIns => 'Sesi log masuk pelayan dan profil anda masih aktif.';
	@override String get repairLostSignIns => 'Kunci yang melindungi maklumat log masuk tersimpan tidak dapat dipulihkan. Anda perlu log masuk semula ke setiap pelayan dan profil.';
	@override String get repairLostSessions => 'Sekurang-kurangnya satu pengesan atau sambungan Seerr telah hilang dan perlu disambungkan semula.';
	@override String get backupTitle => 'Satu salinan fail yang rosak disimpan';
	@override String get backupWarning => 'Ia mengandungi pengesahan log masuk anda.Jangan muat naik atau berkongsi.';
	@override String get deleteBackup => 'Menghapuskan copy';
	@override String get backupDeleted => 'salinan telah dipadamkan.';
	@override String get previousFailureTitle => 'PlezyNG gagal memulakan kali terakhir';
}

// Path: licenses
class _Translations$licenses$ms extends Translations$licenses$en {
	_Translations$licenses$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pakej yang berkaitan';
	@override String get license => 'Lisensi';
	@override String licenseNumber({required Object number}) => 'Permohonan Permohonan ${number}';
	@override String licensesCount({required Object count}) => '${count} pengesahan';
}

// Path: navigation
class _Translations$navigation$ms extends Translations$navigation$en {
	_Translations$navigation$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Pustaka';
	@override String get downloads => 'Muat turun';
	@override String get liveTv => 'TV Langsung';
	@override String get explore => 'Menjelajah';
}

// Path: explore
class _Translations$explore$ms extends Translations$explore$en {
	_Translations$explore$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$ms mdblistShelves = _Translations$explore$mdblistShelves$ms._(_root);
	@override String get title => 'Menjelajah';
	@override String get selectSource => 'Pilih sumber';
	@override late final _Translations$explore$rows$ms rows = _Translations$explore$rows$ms._(_root);
	@override late final _Translations$explore$status$ms status = _Translations$explore$status$ms._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episod',
	);
	@override String get cast => 'Tembakan';
	@override String get characters => 'watak';
	@override String get addToWatchlist => 'Tambah ke Watchlist';
	@override String get removeFromWatchlist => 'Mengalih keluar daripada Watchlist';
	@override String get addedToWatchlist => 'Ditambah kepada watchlist';
	@override String get removedFromWatchlist => 'Menghapus daripada watchlist';
	@override String get watchlistUpdateFailed => 'Tidak boleh update watchlist';
	@override String get watchlistNoMatch => 'Tidak boleh menyesuaikan item ini dengan senarai pengawasan';
	@override String get notInLibrary => 'Bukan di perpustakaan anda';
	@override String get inTheseLibraries => 'Di dalam perpustakaan ini';
	@override String get checkingLibrary => 'Periksa perpustakaan anda.';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: 'Tidak boleh memeriksa ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pelayan',
	);
	@override String get emptyTitle => 'Tiada apa-apa di sini';
	@override String emptyMessage({required Object source}) => 'Roda daripada ${source} akan muncul di sini sebaik sahaja mereka mempunyai kandungan.';
	@override String searchHint({required Object source}) => 'Pencarian untuk ${source}';
	@override String searchEmpty({required Object query}) => 'Tiada hasil untuk "${query}"';
	@override String searchPrompt({required Object source}) => 'Cari filem dan persembahan di ${source}.';
	@override String get searchFailed => 'Pencarian gagal. semak sambungan anda dan cuba lagi.';
	@override late final _Translations$explore$badge$ms badge = _Translations$explore$badge$ms._(_root);
	@override late final _Translations$explore$stats$ms stats = _Translations$explore$stats$ms._(_root);
	@override late final _Translations$explore$season$ms season = _Translations$explore$season$ms._(_root);
	@override late final _Translations$explore$format$ms format = _Translations$explore$format$ms._(_root);
	@override late final _Translations$explore$sourceMaterial$ms sourceMaterial = _Translations$explore$sourceMaterial$ms._(_root);
	@override late final _Translations$explore$creditRole$ms creditRole = _Translations$explore$creditRole$ms._(_root);
	@override late final _Translations$explore$relation$ms relation = _Translations$explore$relation$ms._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} di ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} di ${time} ${timezone}';
	@override late final _Translations$explore$detail$ms detail = _Translations$explore$detail$ms._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hasil',
	);
}

// Path: liveTv
class _Translations$liveTv$ms extends Translations$liveTv$en {
	_Translations$liveTv$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV Langsung';
	@override String get guide => 'Panduan';
	@override String get noChannels => 'Tiada saluran yang tersedia';
	@override String get noDvr => 'Tiada DVR yang dikonfigurasi pada mana-mana pelayan';
	@override String get serverUnavailable => 'Pelayan TV langsung tidak tersedia.';
	@override String get serverNotConnected => 'Pelayan TV Live tidak disambungkan.';
	@override String get noPrograms => 'Tiada data program yang tersedia';
	@override String get liveStreamFailed => 'Live Stream gagal';
	@override String get unknownProgram => 'Program yang tidak diketahui';
	@override String get timelineLiveProgram => 'Program Live (playback boleh berada di luar program ini)';
	@override String get timelineBuffer => 'Tarikh Buffer';
	@override String get timelineUnavailable => 'Jadual yang tidak tersedia';
	@override String get timelineEstimated => 'Penghargaan Playback';
	@override String get timelinePending => 'Menjelang mencari';
	@override String get timelineStale => 'Jadual boleh ditangguhkan';
	@override String get unknownHub => 'yang tidak diketahui';
	@override String get unknownError => 'Kesilapan yang tidak diketahui';
	@override String channelNumber({required Object number}) => 'Rangkaian : ${number}';
	@override String get unknownChannel => 'saluran yang tidak diketahui';
	@override String get live => 'hidup';
	@override String get premiereBadge => 'baru';
	@override String get reloadGuide => 'Reload panduan';
	@override String get searchGuide => 'Panduan Pencarian';
	@override String get searchHint => 'Mencari saluran dan program';
	@override String searchNoResults({required Object query}) => 'Tiada perlawanan untuk "${query}"';
	@override String get channelsSection => 'Saluran';
	@override String get programsSection => 'Program yang';
	@override String get now => 'Sekarang';
	@override String get today => 'Hari ini';
	@override String get tomorrow => 'esok hari';
	@override String get midnight => 'tengah malam';
	@override String get overnight => 'Pagi hari';
	@override String get morning => 'Pagi';
	@override String get daytime => 'harian';
	@override String get evening => 'Malam hari';
	@override String get lateNight => 'Malam yang terlambat';
	@override String get whatsOn => 'Apa yang ada di';
	@override String get watchChannel => 'Lihat saluran';
	@override String get favorites => 'Kegemaran';
	@override String get reorderFavorites => 'Penghormatan Favorit';
	@override String get noFavoriteChannels => 'Tiada saluran kegemaran';
	@override String get noFavoriteChannelsHint => 'Tunjukkan semua saluran, kemudian tekan panjang saluran untuk menambahnya kepada kegemaran anda.';
	@override String get showAllChannels => 'Tunjukkan semua saluran';
	@override String get favoritesLoadFailed => 'Tidak boleh memuatkan kegemaran. semak sambungan anda dan cuba lagi.';
	@override String get favoritesUpdateFailed => 'Tidak boleh mengemas kini kegemaran. semak sambungan anda dan cuba lagi.';
	@override String get joinSession => 'Sesi dalam kemajuan';
	@override String watchFromStart({required Object minutes}) => 'Lihat dari awal (${minutes} min yang lalu)';
	@override String get watchLive => 'Lihat Live';
	@override String get goToLive => 'Pergi untuk hidup';
	@override String get record => 'Rekod';
	@override String get recordEpisode => 'rekod episod';
	@override String get recordSeries => 'Rekod siri';
	@override String get recordOptions => 'Rekod Pilihan';
	@override String get saveTo => 'menyelamatkan kepada';
	@override String get recordings => 'rekod';
	@override String get scheduledRecordings => 'Jadual';
	@override String get recordingRules => 'Peraturan rekod';
	@override String get noScheduledRecordings => 'Tiada apa-apa yang dijadualkan untuk rekod';
	@override String get manageRecording => 'Menguruskan rekod';
	@override String get cancelRecording => 'Batalkan rakaman';
	@override String get cancelRecordingTitle => 'Adakah anda membatalkan rekod ini?';
	@override String cancelRecordingMessage({required Object title}) => '${title} tidak lagi akan didaftarkan.';
	@override String get deleteRule => 'Menghapuskan peraturan';
	@override String get deleteRuleTitle => 'Menghapuskan peraturan rekod?';
	@override String deleteRuleMessage({required Object title}) => 'Episod-episod masa depan daripada ${title} tidak akan direkodkan.';
	@override String get recordingScheduled => 'Rekod yang dijadualkan';
	@override String get alreadyScheduled => 'Program ini telah dirancang';
	@override String get dvrAdminRequired => 'Seting DVR memerlukan akaun admin';
	@override String get recordingFailed => 'Tidak boleh merancang rekod';
	@override String get recordingTargetMissing => 'Tidak boleh menentukan rekod perpustakaan';
	@override String get recordNotAvailable => 'Rekod tidak tersedia untuk program ini';
	@override String get recordingCancelled => 'Rekod dibatalkan';
	@override String get recordingRuleDeleted => 'Peraturan rekod dipadamkan';
	@override String get processRecordingRules => 'Menilai semula peraturan';
	@override String get recordingInProgress => 'Rekod sekarang';
	@override String recordingsCount({required Object count}) => '${count} telah ditetapkan';
	@override String get editRule => 'Peraturan Edit';
	@override String get editRuleAction => 'Sunting';
	@override String get recordingRuleUpdated => 'Peraturan rekod dikemaskini';
	@override String get guideReloadRequested => 'Panduan pembaharuan diminta';
	@override String get guideReloadFailed => 'Tidak boleh memperbaharui panduan';
	@override String get rulesProcessRequested => 'Peraturan penilaian semula diminta';
	@override String get rulesProcessFailed => 'Tidak boleh menilai semula peraturan rekod';
	@override String get recordShow => 'Rekod Pameran';
	@override late final _Translations$liveTv$recordSettings$ms recordSettings = _Translations$liveTv$recordSettings$ms._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Bermula dalam ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} di ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} mengembalikan data pemutaran TV langsung yang tidak sah';
	@override String get failedToStartChannel => 'Tidak boleh memulakan saluran langsung';
	@override String get failedToBuildStreamUrl => 'Tidak boleh membina URL aliran';
	@override String playbackStartFailed({required Object reason}) => 'Tidak boleh memulakan saluran: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Tidak boleh menukar saluran: ${reason}';
}

// Path: collections
class _Translations$collections$ms extends Translations$collections$en {
	_Translations$collections$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Koleksi';
	@override String get collection => 'Koleksi';
	@override String get empty => 'Koleksi yang kosong';
	@override String get deleteCollection => 'Penghapusan Koleksi';
	@override String deleteConfirm({required Object title}) => 'Padam "${title}"? Tindakan ini tidak boleh dibuat asal.';
	@override String get deleted => 'Koleksi dihapuskan';
	@override String get deleteFailed => 'gagal menghapuskan koleksi';
	@override String deleteFailedWithError({required Object error}) => 'Kegagalan untuk memadamkan koleksi: ${error}';
	@override String get selectCollection => 'Pilih Koleksi';
	@override String get collectionName => 'Nama Koleksi';
	@override String get enterCollectionName => 'Masukkan nama koleksi';
	@override String get addedToCollection => 'Ditambah kepada koleksi';
	@override String get errorAddingToCollection => 'gagal untuk menambah kepada koleksi';
	@override String get created => 'Koleksi yang dibuat';
	@override String get removeFromCollection => 'Keluar daripada koleksi';
	@override String removeFromCollectionConfirm({required Object title}) => 'Alih keluar “${title}” daripada koleksi ini?';
	@override String get removedFromCollection => 'Dipecat daripada koleksi';
	@override String get removeFromCollectionFailed => 'gagal keluar daripada koleksi';
	@override String removeFromCollectionError({required Object error}) => 'Kesilapan penghapusan daripada koleksi: ${error}';
	@override String get searchCollections => 'Mencari koleksi...';
}

// Path: playlists
class _Translations$playlists$ms extends Translations$playlists$en {
	_Translations$playlists$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Senarai ulangmain';
	@override String get playlist => 'Senarai Main';
	@override String get noPlaylists => 'Tiada senarai permainan yang ditemui';
	@override String get create => 'Mencipta Playlist';
	@override String get playlistName => 'Nama Playlist';
	@override String get enterPlaylistName => 'Masukkan nama playlist';
	@override String get delete => 'Menghapuskan Playlist';
	@override String get removeItem => 'Menghapus daripada Playlist';
	@override String get smartPlaylist => 'Senarai Pemain Pintar';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item',
	);
	@override String get emptyPlaylist => 'Senarai permainan ini kosong';
	@override String get deleteConfirm => 'Menghapuskan Playlist?';
	@override String deleteMessage({required Object name}) => 'Adakah anda pasti anda mahu memadamkan "${name}"?';
	@override String get created => 'Playlist yang dibuat';
	@override String get deleted => 'Playlist telah dihapuskan';
	@override String get itemAdded => 'Ditambah ke playlist';
	@override String get itemRemoved => 'Menghapus daripada playlist';
	@override String get selectPlaylist => 'Pilih Playlist';
	@override String get searchPlaylists => 'Mencari senarai permainan...';
	@override String get errorCreating => 'gagal mencipta playlist';
	@override String get errorDeleting => 'Tidak boleh memadamkan playlist';
	@override String get errorLoading => 'Kegagalan untuk memuatkan playlist';
	@override String get errorAdding => 'Tidak boleh ditambah ke playlist';
	@override String get errorReordering => 'Kegagalan untuk mengatur semula item playlist';
	@override String get errorRemoving => 'gagal keluar daripada playlist';
}

// Path: music
class _Translations$music$ms extends Translations$music$en {
	_Translations$music$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Pergi ke album';
	@override String get goToArtist => 'Pergi ke artis';
	@override String get instantMix => 'Tag: campuran instan';
	@override String get playNext => 'Bermain selanjutnya';
	@override String get addToQueue => 'Tambah kepada Queue';
	@override String discNumber({required Object n}) => 'Perbincangan:Disk ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} laluan',
	);
	@override String get nowPlaying => 'Bermain sekarang';
	@override String playingFrom({required Object title}) => 'Bermain daripada ${title}';
	@override String get queue => 'Perbincangan';
	@override String get clearQueue => 'Kosongkan barisan';
	@override String get lyrics => 'Lirik';
	@override String get visualizer => 'Visualisasi';
	@override String get visualizerProfileLoading => 'Membaca Analisis Track ...';
	@override String get visualizerAmbientMotion => 'Pergerakan Lingkungan';
	@override String get visualizerPlexLoudness => 'Plex bunyi';
	@override String get visualizerLiveAudio => 'Analisis audio langsung';
	@override String get visualizerPreviousPreset => 'Gaya visual yang terdahulu';
	@override String get visualizerNextPreset => 'Seterusnya Visual Style';
	@override String get visualizerPresetAurora => 'Aurora yang';
	@override String get visualizerPresetBloom => 'Bloom daripada';
	@override String get visualizerPresetOrbitals => 'Orbit yang';
	@override String get visualizerPresetPrism => 'Penghargaan';
	@override String get visualizerPresetTunnel => 'Terowong';
	@override String get visualizerPresetTrackMap => 'Tarikan peta';
	@override String get noLyrics => 'Tiada lyrics boleh didapati';
	@override String get sleepTimer => 'Waktu Tidur';
	@override String get sleepTimerEndOfTrack => 'Akhir daripada trek';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minit',
	);
	@override String get stopPlayback => 'Berhenti bermain';
	@override String get previousTrack => 'Trek sebelumnya';
	@override String get nextTrack => 'Trek seterusnya';
	@override String get repeat => 'Kembali';
	@override String get repeatAll => 'Ulangi semua';
	@override String get repeatOne => 'Ulangi satu';
	@override String get instantMixNoServer => 'Tiada pelayan boleh didapati untuk campuran instan';
	@override String get instantMixFailed => 'Tidak boleh mengisi campuran instan';
	@override String get instantMixEmpty => 'SeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnya';
	@override String noAudioUrl({required Object track}) => 'Tiada URL audio boleh didapati untuk ${track}';
	@override late final _Translations$music$discography$ms discography = _Translations$music$discography$ms._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$ms extends Translations$watchTogether$en {
	_Translations$watchTogether$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tonton Bersama';
	@override String get description => 'Menonton kandungan dalam sinkron dengan rakan-rakan dan keluarga';
	@override String get createRoom => 'Mencipta bilik';
	@override String get creatingRoom => 'Mencipta bilik ...';
	@override String get joinRoom => 'menyertai bilik';
	@override String get joiningRoom => 'Perhimpunan bilik...';
	@override String get connecting => 'Menghubungkan ...';
	@override String get relayPublic => 'Bilik-bilik menggunakan rangkaian Open Watch Party awam.';
	@override String relayCustom({required Object url}) => 'Bilik-bilik menggunakan relay anda di ${url}.';
	@override String get recentRooms => 'Bilik baru';
	@override String get roomActions => 'Aktiviti bilik';
	@override String get renameRoom => 'Reka bentuk bilik';
	@override String get removeRoom => 'Keluarkan';
	@override String get enterRoomCode => 'Masukkan kod 6 aksara daripada tuan rumah.';
	@override String get roomCode => 'Kod bilik';
	@override String get paste => 'Paste yang';
	@override String get noCodeInClipboard => 'Klipboard tidak mengandungi kod bilik';
	@override String get copyCode => 'Kode salinan';
	@override String get codeCopied => 'Kod bilik disalin';
	@override String get shareInvite => 'Memberi jemputan';
	@override String get inviteCopied => 'Sila rujuk. masukkan ke dalam mesej.';
	@override String inviteMessage({required Object code}) => 'Bergabunglah dengan Bilik Bersama saya di PlezyNG: buka Bilik Bersama, pilih Bilik Bersama dan masukkan ${code}.';
	@override String get openSessionControls => 'Open Watch Bersama-sama kawalan sesi';
	@override String get reconnecting => 'Menghubungkan semula...';
	@override String get reconnectingDescription => 'sambungan hilang. anda menyertai bilik secara automatik.';
	@override String get connected => 'Terhubung';
	@override String get disconnected => 'Disambungkan';
	@override String get youAreHost => 'Awak lah tuan rumah';
	@override String hostedBy({required Object name}) => 'Diterima oleh ${name}';
	@override String get hostControlsPlayback => 'Pengawal Pengawal Playback';
	@override String get anyoneCanControl => 'Siapa sahaja boleh mengawal playback';
	@override String get roomLocked => 'Bilik tertutup';
	@override String get nowPlaying => 'Bermain sekarang';
	@override String get nothingPlaying => 'Tiada bermain';
	@override String get nothingPlayingHost => 'Main sesuatu daripada mana-mana perpustakaan untuk berkongsi dengan bilik.';
	@override String get nothingPlayingGuest => 'Apabila tuan rumah memainkan sesuatu, ia dibuka di sini.';
	@override String get notShareable => 'Video ini tidak mempunyai perlawanan katalog, jadi hanya orang yang mempunyai akses ke pelayan yang sama boleh memainkannya.';
	@override String get searching => 'Mencari video ini di perpustakaan anda ...';
	@override String get yourCopy => 'Kopi anda';
	@override String get sharingYourCopy => 'Anda berkongsi salinan anda';
	@override String playingOtherLength({required Object difference}) => 'Bermain salinan anda, ${difference}';
	@override String get mismatchTitle => 'Kopi anda berbeza panjang';
	@override String mismatchDescription({required Object difference}) => 'Salinan terdekat anda ialah ${difference} daripada video bilik.';
	@override String get playAnyway => 'Bermain bagaimanapun';
	@override String get chooseAnotherCopy => 'Pilih salinan lain';
	@override String get dontPlay => 'Jangan Bermain';
	@override String get unavailableTitle => 'Anda tidak mempunyai video ini';
	@override String get unavailableDescription => 'PlezyNG tidak dapat menemukannya dalam perpustakaan anda. pilih salinan sendiri atau cari lagi.';
	@override String get chooseCopy => 'Pilih salinan';
	@override String get searchAgain => 'Cari lagi';
	@override String get noCandidates => 'Tiada salinan yang boleh didapati di perpustakaan anda.';
	@override String get choiceFailed => 'Saya tidak boleh memainkan salinan ini untuk bilik';
	@override String lengthLonger({required Object duration}) => '${duration} lebih lama';
	@override String lengthShorter({required Object duration}) => '${duration} lebih pendek';
	@override String get lengthSame => 'panjang yang sama';
	@override String get lengthUnknown => 'Panjang yang tidak diketahui';
	@override String get joinCurrentPlayback => 'Menyertai Playback';
	@override String get joinCurrentPlaybackDescription => 'Kembali ke apa yang tuan rumah sedang menonton';
	@override String get stopMedia => 'Hentikan video untuk semua orang';
	@override String get syncOffset => 'Penyelesaian Offset';
	@override String get syncOffsetDescription => 'Pindah video anda jika ia berjalan di hadapan atau di belakang bilik.';
	@override String offsetHint({required Object difference}) => 'Salinan anda ialah ${difference} daripada video bilik.';
	@override String applyDifference({required Object offset}) => 'Penggunaan ${offset}';
	@override String get offsetMinusSecond => '1 s';
	@override String get offsetMinusTenth => '- 100 ms';
	@override String get offsetPlusTenth => '+ 100 ms';
	@override String get offsetPlusSecond => '+ 1 s';
	@override String get participants => 'peserta';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} peserta',
	);
	@override String get hostBadge => 'tetamu';
	@override String nameYou({required Object name}) => '${name} (Anda)';
	@override String get playerIdle => 'Idol';
	@override String get playerLoading => 'Pengecasan';
	@override String get playerReady => 'Bersedia';
	@override String get playerBuffering => 'Perbezaan';
	@override String get matchSearching => 'Pencarian';
	@override String get matchMatched => 'Mempunyai video';
	@override String get matchMismatched => 'panjang yang berbeza';
	@override String get matchUnavailable => 'Tidak ada video';
	@override String participantOffset({required Object offset}) => 'Perbezaan ${offset}';
	@override String get makeHost => 'buat tuan rumah';
	@override String get makeHostQuestion => 'Penghantaran kepada tuan rumah?';
	@override String makeHostConfirm({required Object name}) => '${name} akan mengawal playback dan memandu sesi untuk semua orang.';
	@override String get transfer => 'Penghantaran';
	@override String get removeParticipant => 'Keluar Dari Bilik';
	@override String removeParticipantQuestion({required Object name}) => 'Menghapuskan ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} meninggalkan bilik. mereka boleh menyertai kod lagi melainkan anda menutup bilik.';
	@override String get remove => 'Keluarkan';
	@override String get roomSettings => 'tetapan bilik';
	@override String get letEveryoneControl => 'Semua orang boleh mengawal playback';
	@override String get lockRoom => 'Bilik Lock';
	@override String get lockRoomDescription => 'Tiada yang baru boleh menyertai';
	@override String get leaveRoom => 'Tinggalkan Bilik';
	@override String get leaveRoomQuestion => 'Tinggalkan bilik?';
	@override String get leaveRoomConfirm => 'Anda boleh menyertai lagi dengan kod bilik.';
	@override String get leave => 'Tinggalkan';
	@override String get endRoom => 'Bilik Akhir';
	@override String get endRoomQuestion => 'Bilik Akhir ?';
	@override String get endRoomConfirm => 'Ini berakhir bilik bagi semua orang.';
	@override String get end => 'Akhirnya';
	@override String get playBlockedTitle => 'Playback Tidak Bermula';
	@override String get playBlockedDescription => 'Bermain untuk mula menonton dengan bilik.';
	@override late final _Translations$watchTogether$notices$ms notices = _Translations$watchTogether$notices$ms._(_root);
	@override late final _Translations$watchTogether$ended$ms ended = _Translations$watchTogether$ended$ms._(_root);
	@override late final _Translations$watchTogether$errors$ms errors = _Translations$watchTogether$errors$ms._(_root);
	@override String untitledEpisode({required Object number}) => 'Perbincangan ${number}';
}

// Path: downloads
class _Translations$downloads$ms extends Translations$downloads$en {
	_Translations$downloads$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Muat turun';
	@override String get manage => 'Pengurusan';
	@override String get tvShows => 'Rancangan TV';
	@override String get movies => 'Filem-filem';
	@override String get music => 'Muzik';
	@override String tracksQueued({required Object count}) => '${count} trek yang dikeluarkan untuk muat turun';
	@override String get noDownloads => 'Tiada muat turun';
	@override String get noDownloadsDescription => 'Kandungan yang dimuat turun akan muncul di sini untuk pandangan offline';
	@override String get downloadNow => 'Muat turun';
	@override String get deleteDownload => 'Menghapus download';
	@override String get retryDownload => 'Kembali ke download';
	@override String get downloadQueued => 'Download yang dikemukakan';
	@override String get downloadResumed => 'muat turun semula';
	@override String get serverErrorBitrate => 'Kesilapan pelayan: fail boleh melebihi had bitrate jauh';
	@override String get storageFull => 'Muat turun berhenti untuk melindungi penyimpanan yang tersedia.Bebaskan beberapa ruang atau pilih lokasi muat turun lain, kemudian keluar.';
	@override String get storageUnavailable => 'Muat turun berhenti kerana penyimpanan yang tersedia tidak boleh disemak. semak lokasi muat turun, kemudian keluar.';
	@override String episodesQueued({required Object count}) => '${count} episod yang dikeluarkan untuk muat turun';
	@override String get downloadDeleted => 'Download dihapuskan';
	@override String deleteConfirm({required Object title}) => 'Menghapus "${title}" daripada peranti ini?';
	@override String get deleteCollectionDownloads => 'Menghapuskan Downloads';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Padam semua muat turun dalam “${title}” daripada peranti ini?';
	@override String get collectionDownloadsDeleted => 'Downloads dihapuskan';
	@override String get cancelledDownloadTitle => 'Pembatalan Download';
	@override String get cancelledDownloadMessage => 'Download ini telah dibatalkan. apa yang anda mahu lakukan?';
	@override String get allEpisodesAlreadyDownloaded => 'Semua episod telah dimuat turun';
	@override String get resumeDownload => 'Rujukan Download';
	@override String get cancelledDownload => 'Pembatalan download';
	@override String syncingFile({required Object file, required Object status}) => '${file} (sinkronkan ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'Dimuat turun ${file} - Klik untuk menyelesaikan';
	@override String get partialDownloadClickToComplete => 'Bahagian muat turun - klik untuk menyelesaikan';
	@override String get deleting => 'Menghapuskan ...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Menghapuskan ${title}... (${current} daripada ${total})';
	@override String get queuedTooltip => 'Peringatan';
	@override String queuedFilesTooltip({required Object files}) => 'Perbincangan : ${files}';
	@override String get downloadingTooltip => 'Dilancarkan...';
	@override String downloadingFilesTooltip({required Object files}) => 'Perbincangan ${files}';
	@override String get noDownloadsTree => 'Tiada download';
	@override String get pauseAll => 'Beristirahat semua';
	@override String get resumeAll => 'Menggambar semua';
	@override String get retryAll => 'Kembalikan semua';
	@override String get retryFailed => 'Retry kegagalan download';
	@override String get deleteAll => 'Padam semua';
	@override String get selectVersion => 'Pilih versi';
	@override String get allEpisodes => 'Semua episod';
	@override String get unwatchedOnly => 'Hanya tidak diperhatikan';
	@override String nextNUnwatched({required Object count}) => 'Seterusnya ${count} tidak dilihat';
	@override String get customAmount => 'Jumlah yang disesuaikan...';
	@override String get customAmountAny => 'Jumlah yang disesuaikan (setiap tahun)';
	@override String get randomEpisodes => 'Kejadian rawak';
	@override String get includeSpecials => 'Termasuk spesial';
	@override String get howManyEpisodes => 'Berapakah jumlah episod?';
	@override String get invalidEpisodeCount => 'Masukkan nombor episod yang sah.';
	@override String get keepSynced => 'Tetap bersinkron';
	@override String get downloadOnce => 'Download sekali';
	@override String keepNUnwatched({required Object count}) => '${count} tidak disemak';
	@override String get editSyncRule => 'Edit Peraturan Sinkron';
	@override String get removeSyncRule => 'Menghapuskan Peraturan Sync';
	@override String removeSyncRuleConfirm({required Object title}) => 'Hentikan penyegerakan "${title}"? episod yang dimuat turun akan disimpan.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Hentikan penyegerakan "${title}"';
	@override String get deleteSyncRuleDownloads => 'Juga menghapuskan download yang berkaitan';
	@override String get deleteSyncRuleDownloadsDescription => 'Muat turun yang digunakan oleh peraturan sink atau profil lain akan disimpan.';
	@override String syncRuleCreated({required Object count}) => 'Peraturan sinkron yang dicipta — mengekalkan ${count} episod yang tidak dilihat';
	@override String get syncRuleUpdated => 'Peraturan Sync dikemaskini';
	@override String get syncRuleRemoved => 'Peraturan Sync dihapuskan';
	@override String get syncRuleAndDownloadsRemoved => 'Peraturan Sinkron dan muat turun yang berkaitan dihapuskan';
	@override String get syncRuleCleanupBusy => 'Peraturan Sync kini dikemas kini. cuba lagi dalam sekejap.';
	@override String get syncRuleCleanupUnavailable => 'Penyambung semula pelayan dan cuba lagi, atau menghapuskan peraturan tanpa memadamkan muat turun.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Sinkronkan ${count} episod baru untuk ${title}';
	@override String get syncNow => 'Sinkronkan sekarang';
	@override String get downloadsUpToDate => 'Downloads sehingga kini';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync lengkap · ${queued} queued, ${removed} dihapuskan';
	@override String get activeSyncRules => 'Peraturan Sync';
	@override String get reviewOrphanFiles => 'Lihat lagi reviu untuk Orphaned downloads';
	@override String get orphanReviewTitle => 'Lihat lagi reviu untuk Orphaned downloads';
	@override String get orphanReviewDescription => 'Fail-fail yang ditandakan ini terdapat dalam folder muat turun yang dikendalikan oleh aplikasi lalai PlezyNG dan tidak mempunyai rekod muat turun atau tugas aktif yang sepadan.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} fail · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Memadamkan fail ${count}';
	@override String get orphanCleanupNone => 'Tiada fail muat turun yang ditemui';
	@override String get orphanCleanupFailed => 'PlezyNG tidak boleh selamat memindai folder muat turun yang dikendalikan. tiada fail yang dipadamkan.';
	@override String get orphanCleanupChanged => 'Senarai muat turun berubah semasa ulasan. ulasan semula fail sebelum pembersihan.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Memadamkan ${count} fail yatim piatu · ${size} dibebaskan';
	@override String get noSyncRules => 'Tiada Peraturan Sinkron';
	@override String get manageSyncRule => 'Pengurusan Sync';
	@override String get editEpisodeCount => 'Perhitungan Episod';
	@override String get editSyncFilter => 'Filter Sinkron';
	@override String get syncAllItems => 'Menggabungkan semua item';
	@override String get syncUnwatchedItems => 'Menggabungkan item yang tidak dipantau';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Pelayan : ${server} • ${status}';
	@override String get syncRuleAvailable => 'Tersedia';
	@override String get syncRuleOffline => 'Perbincangan Offline';
	@override String get syncRuleSignInRequired => 'Menandatangani yang diperlukan';
	@override String get syncRuleAccessDenied => 'Akses yang ditolak';
	@override String get syncRuleNotAvailableForProfile => 'Tidak tersedia untuk profil semasa';
	@override String get syncRuleUnknownServer => 'Pelayan yang tidak diketahui';
	@override String get syncRuleListCreated => 'Peraturan Sync yang diwujudkan';
	@override late final _Translations$downloads$backgroundWarning$ms backgroundWarning = _Translations$downloads$backgroundWarning$ms._(_root);
	@override String get options => 'Pilihan muat turun';
	@override late final _Translations$downloads$groupings$ms groupings = _Translations$downloads$groupings$ms._(_root);
	@override String get unknownLibrary => 'Perpustakaan yang tidak diketahui';
	@override String get unknownShow => 'persembahan yang tidak diketahui';
	@override String get unknownSeason => 'Musim yang tidak diketahui';
	@override String get unknownAlbum => 'Album yang tidak diketahui';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} selesai';
	@override String storageUsed({required Object size}) => 'Penyimpanan yang digunakan: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} muat turun',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menunjukkan',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filem-filem',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} buah buku',
	);
	@override String get errorFileNotFound => 'Fail yang tidak ditemui (404)';
	@override String get errorDownloadNotAllowed => 'Muat turun tidak dibenarkan oleh pelayan (403)';
	@override String get errorDownloadFailed => 'Download gagal';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Pendaftaran yang gagal: ${reason}';
	@override String get convertingOnServer => 'Menukar kepada server ...';
	@override String convertingOnServerPercent({required Object percent}) => 'Penukaran pada pelayan · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'muat turun gagal (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Selepas pemprosesan gagal: ${reason}';
	@override String get reasonFileNotSaved => 'fail tidak boleh disimpan pada peranti ini';
	@override String get reasonCannotResume => 'Bahagian download tidak boleh dikembalikan';
	@override String get reasonDeviceStorageFull => 'Peranti ini tidak disimpan';
	@override String get notificationDownloading => 'Dilancarkan...';
	@override String get notificationComplete => 'muat turun lengkap';
	@override String get notificationPaused => 'Download beristirahat';
}

// Path: shaders
class _Translations$shaders$ms extends Translations$shaders$en {
	_Translations$shaders$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tembakan';
	@override String get noShaderDescription => 'Tiada peningkatan video';
	@override String get nvscalerDescription => 'Skala imej NVIDIA untuk video yang lebih tajam';
	@override String get artcnnVariantNeutral => 'Neutral';
	@override String get artcnnVariantDenoise => 'Dini';
	@override String get artcnnVariantDenoiseSharpen => 'Perbincangan:Denoise + Sharpen';
	@override String get qualityFast => 'Cepat';
	@override String get qualityHQ => 'Kualiti Tinggi';
	@override String get mode => 'Mod yang';
	@override String get importShader => 'Pengangkutan Shader';
	@override String get customShaderDescription => 'Penyesuaian GLSL Shader';
	@override String get shaderImported => 'Shader yang diimport';
	@override String get shaderImportFailed => 'Kegagalan untuk mengimport shader';
	@override String get deleteShader => 'Menghapus Shader';
	@override String deleteShaderConfirm({required Object name}) => 'Menghapuskan "${name}"';
}

// Path: companionRemote
class _Translations$companionRemote$ms extends Translations$companionRemote$en {
	_Translations$companionRemote$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Alat Kawalan Pendamping';
	@override String connectedTo({required Object name}) => 'Menghubungkan ke ${name}';
	@override String get unknownDevice => 'Peranti yang tidak diketahui';
	@override late final _Translations$companionRemote$session$ms session = _Translations$companionRemote$session$ms._(_root);
	@override late final _Translations$companionRemote$pairing$ms pairing = _Translations$companionRemote$pairing$ms._(_root);
	@override late final _Translations$companionRemote$remote$ms remote = _Translations$companionRemote$remote$ms._(_root);
	@override late final _Translations$companionRemote$errors$ms errors = _Translations$companionRemote$errors$ms._(_root);
	@override String get closedBeforeAuth => 'Perhubungan ditutup sebelum pengesahan';
}

// Path: videoSettings
class _Translations$videoSettings$ms extends Translations$videoSettings$en {
	_Translations$videoSettings$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Kelajuan Playback';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Aktif (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Tidur Tidur';
	@override String get audioSync => 'Perbincangan Audio Sync';
	@override String get subtitleSync => 'Subtitle Sinkronisasi';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR tidak tersedia di sini - komposer desktop atau output video ini tidak boleh membawanya.';
	@override String get hdrToneMapping => 'HDR Tone Peta';
	@override String get hdrToneMappingCompositor => 'Komposisi';
	@override String get hdrToneMappingCompositorDescription => 'Melalui metadata HDR sumber dan biarkan peta komposer desktop melakukannya.';
	@override String get hdrToneMappingPlayer => 'Pemain';
	@override String get hdrToneMappingPlayerDescription => 'Peta ke puncak kecerahan paparan dalam pemain, kemudian memberitahu komposer hasilnya.';
	@override String get hdrToneMappingFailed => 'Tidak boleh mengubah pemetaan nada HDR - mod terdahulu masih aktif.';
	@override String get audioOutput => 'Pengeluaran Audio';
	@override String get videoTrack => 'Trek video';
	@override String get videoTrackDescription => 'Pilih strim video yang hendak dipaparkan. Tersedia dalam main balik MPV apabila fail mengandungi trek video alternatif.';
	@override String get videoTrackDefault => 'Lalai';
	@override String get videoTrackUnavailable => 'Tiada trek video alternatif yang tersedia.';
	@override String get videoTrackFailed => 'Trek video tidak dapat ditukar.';
	@override String videoTrackNumber({required Object id}) => 'Trek ${id}';
	@override String get performanceOverlay => 'Persembahan Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'di sekitar';
	@override String get audioOutputSpatial => 'Audio ruang';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Audio Penyelesaian';
	@override String get audioEqualizerDescription => '10 band equalizer untuk MPVFilter audio menggunakan audio yang dikodkan dan mematikan passthrough.';
	@override String get audioEqualizerFlat => 'Permukaan';
	@override String get audioEqualizerActive => 'Khas';
	@override String get audioEqualizerSaveFailed => 'Tidak boleh menyimpan seting audio equalizer.';
	@override String get audioEffectsDescription => 'Efek menggunakan audio yang dikodkan, jadi passthrough berbalik. persekitaran bilik dan pembesaran stereo bergantung kepada MPV membina dan mengesan.';
	@override String get audioStereoWidth => 'Pengembangan Stereo';
	@override String get audioSpatializer => 'Persekitaran bilik';
	@override String get audioSpatializerDescription => 'Menambah refleksi bilik yang tenang.';
	@override String get audioPitch => 'Perubahan Pitch';
	@override String get audioPitchDescription => 'Menukar pitch tanpa mengubah kelajuan. MPV Pembinaan hendaklah termasuk Rubber Band.';
	@override String get audioEffectUnavailable => 'Kesan ini tidak tersedia untuk trek ini atau MPV membina .';
	@override String get backgroundVideoAudio => 'Video audio latar belakang';
	@override String get backgroundVideoAudioDescription => 'Pastikan video audio dimainkan apabila anda meninggalkan pemain; imej itu tersembunyi sehingga anda kembali. Android menggunakan pemberitahuan pemutaran media.';
	@override String get audioNormalization => 'Mengatur bunyi bising';
	@override String get audioNormalizationDisablesPassthrough => 'Memecahkan audio ke PCM; passthrough keluar sementara ini';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$ms extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get color => 'warna';
	@override String get performance => 'prestasi';
	@override String get buffer => 'Buffer';
	@override String get app => 'Apl';
	@override String get decoder => 'Pengecut';
	@override String get rawDecoder => 'Rujukan Decoder';
	@override String get tunneling => 'tunel';
	@override String get passthrough => 'Pasukan';
	@override String get aspect => 'Aspek';
	@override String get rotation => 'Rotasi';
	@override String get dvSource => 'D. Sumber';
	@override String get dvPath => 'Laluan DV';
	@override String get dvRouteDecoder => 'Dolby Vision pengecut';
	@override String get dvRouteDecoderP81 => 'Dolby Vision decoder (P7→8.1) untuk';
	@override String get dvRouteBaseLayer => 'Lapisan asas';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 lapisan asas';
	@override String get dvRouteBaseLayerHlg => 'Lapisan asas HLG';
	@override String get dvRouteBaseLayerSdr => 'Lapisan asas SDR';
	@override String get dvRouteReshaped => 'RPU diselesaikan semula (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Grafik Eksperimen P7 FEL (tidak berkelayakan)';
	@override String get p7Conversion => 'P7 Perbezaan';
	@override String get sampleRate => 'Kadar sampel';
	@override String get pixelFormat => 'Pengenalan kepada Pixel Fmt';
	@override String get hwFormat => 'Format perkakasan';
	@override String get matrix => 'Matriks';
	@override String get primaries => 'Permulaan';
	@override String get transfer => 'Penghantaran';
	@override String get renderFps => 'Penghantaran FPS';
	@override String get displayFps => 'Pemandangan FPS';
	@override String get avSync => 'A / V Sinkron';
	@override String get dropped => 'pecah';
	@override String get dvRpus => 'RPU yang';
	@override String get dvRpuAverage => 'Perbezaan RPU AVG';
	@override String get dvSampleAverage => 'Perbezaan sampel AVG';
	@override String get maxLuma => 'Tag: Max Luma';
	@override String get minLuma => 'Luma min.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache digunakan';
	@override String get cacheLimit => 'Perbezaan Cache';
	@override String get speed => 'kelajuan';
	@override String get player => 'Pemain';
	@override String get playMethod => 'Permainan kaedah';
	@override String get memory => 'Memori yang';
	@override String get uiFps => 'Perbezaan FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'Perkhidmatan NVIDIA HW';
	@override String get decoderQualcommHw => 'Perkhidmatan Qualcomm HW';
	@override String get decoderMediatekHw => 'Perbincangan HW';
	@override String get decoderExynosHw => 'Perbezaan HW';
	@override String get decoderSoftware => 'Perisian';
	@override String get decoderHardware => 'Perkakasan';
	@override String get tunnelingActive => 'Aktiviti';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} gagal)';
}

// Path: externalPlayer
class _Translations$externalPlayer$ms extends Translations$externalPlayer$en {
	_Translations$externalPlayer$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pemain luar';
	@override String get useExternalPlayer => 'Penggunaan Pemain Luar';
	@override String get useExternalPlayerDescription => 'Membuka video dalam aplikasi lain';
	@override String get selectPlayer => 'Pilih Pemain';
	@override String get customPlayers => 'Pemain Custom';
	@override String get systemDefault => 'Sistem yang lalai';
	@override String get addCustomPlayer => 'Menambah Custom Player';
	@override String get playerName => 'Nama Pemain';
	@override String get playerNameHint => 'Pemain saya';
	@override String get playerCommand => 'Perintah';
	@override String get playerPackage => 'Nama Pakej';
	@override String get playerUrlScheme => 'Rancangan URL';
	@override String get off => 'keluar';
	@override String get launchFailed => 'gagal membuka pemain luar';
	@override String appNotInstalled({required Object name}) => '${name} tidak dipasang';
	@override String get playInExternalPlayer => 'Bermain dalam pemain luaran';
	@override String get description => 'Pilih aplikasi lain untuk membuka video dalam. pemain yang tersedia bergantung kepada peranti anda dan aplikasi yang dipasang.';
	@override String get systemDefaultDescription => 'Biarkan sistem operasi membuka video dengan aplikasi lalai.';
	@override String playerOptionDescription({required Object player}) => 'Buka video dengan ${player}.';
	@override String get playerNameDescription => 'Label yang ditunjukkan dalam senarai pemain.';
	@override String get playerPackageDescription => 'Masukkan nama pakej Android aplikasi pemain, seperti com.example.player.';
	@override String get playerCommandDescription => 'Masukkan perintah pemain yang dipasang atau laluan yang boleh dijalankan untuk peranti ini.';
	@override String get playerUrlSchemeDescription => 'Masukkan skema URL dan templat URL pilihan yang digunakan untuk melancarkan pemain.';
}

// Path: metadataEdit
class _Translations$metadataEdit$ms extends Translations$metadataEdit$en {
	_Translations$metadataEdit$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Sunting';
	@override String get screenTitle => 'Sunting metadata';
	@override String get basicInfo => 'Maklumat asas';
	@override String get artwork => 'seni';
	@override String get advancedSettings => 'Pengaturan Lanjutan';
	@override String get title => 'Tajuk';
	@override String get sortTitle => 'Tajuk Berwarna';
	@override String get originalTitle => 'Tajuk asli';
	@override String get releaseDate => 'Tarikh pelepasan';
	@override String get contentRating => 'Penilaian Kandungan';
	@override String get studio => 'Pengajian';
	@override String get tagline => 'Slogan';
	@override String get summary => 'ringkasan';
	@override String get poster => 'Poster';
	@override String get background => 'latar belakang';
	@override String get logo => 'Logo yang';
	@override String get squareArt => 'Lapangan seni';
	@override String get selectPoster => 'Pilih Poster';
	@override String get selectBackground => 'Pilih latar belakang';
	@override String get selectLogo => 'Pilih logo';
	@override String get selectSquareArt => 'Pilih Square Art';
	@override String get fromUrl => 'Daripada URL';
	@override String get uploadFile => 'Muat naik fail';
	@override String get enterImageUrl => 'Masukkan URL imej';
	@override String get imageUrl => 'imej URL';
	@override String get metadataUpdated => 'Metadata dikemaskini';
	@override String get metadataUpdateFailed => 'Kegagalan Mengemas kini Metadata';
	@override String get artworkUpdated => 'Seni yang dikemaskini';
	@override String get artworkUpdateFailed => 'Kegagalan untuk mengemas kini karya seni';
	@override String get noArtworkAvailable => 'Tiada karya seni yang tersedia';
	@override String artworkOption({required Object index}) => 'Pilihan seni ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Pilihan seni ${index}, dipilih';
	@override String get notSet => 'Tidak menetapkan';
	@override String get libraryDefault => 'Perpustakaan kekurangan';
	@override String get accountDefault => 'Akaun yang tidak sah';
	@override String get seriesDefault => 'Serangkaian default';
	@override String get episodeSorting => 'Perbezaan Episod';
	@override String get oldestFirst => 'Yang Tertua Pertama';
	@override String get newestFirst => 'Yang baru pertama';
	@override String get keep => 'teruskan';
	@override String get allEpisodes => 'Semua episod';
	@override String latestEpisodes({required Object count}) => '${count} episod terkini';
	@override String get latestEpisode => 'Episod Terkini';
	@override String episodesAddedPastDays({required Object count}) => 'Episod ditambah dalam ${count} hari yang lalu';
	@override String get deleteAfterPlaying => 'Menghapuskan episod selepas bermain';
	@override String get never => 'Tidak pernah';
	@override String get afterADay => 'Selepas satu hari';
	@override String get afterAWeek => 'Selepas seminggu';
	@override String get afterAMonth => 'Selepas sebulan';
	@override String get onNextRefresh => 'Selepas pembersihan';
	@override String get seasons => 'Musim';
	@override String get show => 'Pameran';
	@override String get hide => 'menyembunyikan';
	@override String get episodeOrdering => 'Episod Perintah';
	@override String get tmdbAiring => 'Database Filem (Bahasa Inggeris)';
	@override String get tvdbAiring => 'Perbincangan :Bahasa Inggeris (Bahasa Melayu)';
	@override String get tvdbAbsolute => 'Perbincangan :DDB ( Absolute )';
	@override String get metadataLanguage => 'Bahasa Metadata';
	@override String get useOriginalTitle => 'Menggunakan tajuk asal';
	@override String get preferredAudioLanguage => 'Bahasa audio yang disukai';
	@override String get preferredSubtitleLanguage => 'Subtitle Bahasa yang disukai';
	@override String get subtitleMode => 'Pilihan Subtitle Mode';
	@override String get manuallySelected => 'dipilih secara manual';
	@override String get shownWithForeignAudio => 'Diterbitkan dengan audio asing';
	@override String get alwaysEnabled => 'Selalu dibenarkan';
	@override String get tags => 'Tag :';
	@override String get addTag => 'Tambah tag';
	@override String get genre => 'Jenis';
	@override String get director => 'Pengarah';
	@override String get writer => 'Penulis';
	@override String get producer => 'Penerbit';
	@override String get country => 'negara';
	@override String get collection => 'Koleksi';
	@override String get label => 'Label';
	@override String get quickTag => 'Tag yang cepat...';
}

// Path: matchScreen
class _Translations$matchScreen$ms extends Translations$matchScreen$en {
	_Translations$matchScreen$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get match => 'Perlawanan ...';
	@override String get fixMatch => 'Menyelesaikan perlawanan...';
	@override String get unmatch => 'Perlawanan';
	@override String get unmatchConfirm => 'Plex memperlakukan perlawanan ini sebagai tidak bertanding sehingga selesai.';
	@override String get unmatchSuccess => 'item yang tidak sesuai';
	@override String get unmatchFailed => 'Kegagalan untuk Unmatch item';
	@override String get matchApplied => 'Perlawanan yang digunakan';
	@override String get matchFailed => 'gagal melaksanakan perlawanan';
	@override String get titleHint => 'Tajuk';
	@override String get yearHint => 'Tahun yang';
	@override String get search => 'Pencarian';
	@override String get noMatchesFound => 'Tiada perlawanan yang ditemui';
}

// Path: serverTasks
class _Translations$serverTasks$ms extends Translations$serverTasks$en {
	_Translations$serverTasks$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tugas Pelayan';
	@override String get failedToLoad => 'Kegagalan mengisi tugas';
	@override String get noTasks => 'Tiada tugas yang berjalan';
}

// Path: trakt
class _Translations$trakt$ms extends Translations$trakt$en {
	_Translations$trakt$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Terhubung';
	@override String connectedAs({required Object username}) => 'Terhubung dengan @${username}';
	@override String get disconnectConfirm => 'Mengalih keluar akaun Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG akan berhenti menghantar acara ke Trakt. anda boleh menyambung semula pada bila-bila masa.';
	@override String get scrobble => 'Pengeluaran masa nyata scrobbling';
	@override String get scrobbleDescription => 'Hantar permainan, istirahat, dan menghentikan peristiwa kepada Trakt semasa pemutaran.';
	@override String get watchedSync => 'Sinkronkan status yang dilihat';
	@override String get watchedSyncDescription => 'Apabila anda menandakan item seperti yang dilihat di PlezyNG, mereka juga ditandakan seperti yang dilihat di Trakt.';
}

// Path: seerr
class _Translations$seerr$ms extends Translations$seerr$en {
	_Translations$seerr$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Menghubungkan Seerr';
	@override String get serverUrl => 'Pelayan URL';
	@override String get serverUrlHelper => 'alamat instans anda';
	@override String get checkServer => 'teruskan';
	@override String get signInWithJellyfin => 'Mendaftar dengan Jellyfin';
	@override String get signInWithEmby => 'Mendaftar dengan Emby';
	@override String get signInWithLocal => 'Menggunakan akaun tempatan';
	@override String get email => 'Email yang';
	@override String get noSignInMethods => 'Contoh Seerr ini tidak menawarkan sokongan kaedah log masuk PlezyNG.';
	@override String get instance => 'instans';
	@override String get disconnectConfirm => 'Menghubungkan Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG akan melupakan instans Seerr ini. sambungkan semula pada bila-bila masa.';
	@override String get request => 'Permintaan';
	@override String get request4k => 'Permintaan dalam 4K';
	@override String get seasons => 'Musim';
	@override String get allSeasons => 'Semua musim';
	@override String get advancedOptions => 'Kemajuan';
	@override String get destinationServer => 'Pelayan Destinasi';
	@override String get qualityProfile => 'Profil Kualiti';
	@override String get rootFolder => 'Rujukan folder';
	@override String get languageProfile => 'Profil Bahasa Melayu';
	@override String get tags => 'Tag :';
	@override String get noTags => 'Tiada tags';
	@override String defaultOption({required Object name}) => '${name} (Defektif)';
	@override String get animeNote => 'Seri ini merupakan anime.';
	@override String get requestSubmitted => 'Permohonan yang dikemukakan';
	@override String requestFailed({required Object error}) => 'Permohonan gagal: ${error}';
	@override String get requestsLoadFailed => 'Tidak boleh memuatkan opsyen permintaan';
	@override String get nothingToRequest => 'Semua sudah tersedia atau diminta.';
	@override String get statusAvailable => 'Tersedia';
	@override String get statusPartiallyAvailable => 'Bahagian tersedia';
	@override String get statusRequested => 'Permohonan';
	@override String get statusProcessing => 'Pemprosesan';
	@override String get statusBlocklisted => 'Terjejas';
	@override String couldNotReach({required Object url, required Object error}) => 'Tidak boleh mencapai ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Tiada permohonan Seerr di ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Sebuah proxy terbalik yang mengesahkan (SSO atau HTTP auth) dijawab daripada Seerr. PlezyNG tidak boleh mendaftar melalui: biarkan laluan /api/v1 Seerr melepasi proxy untuk aplikasi ini, atau gunakan alamat yang mencapai Seerr secara langsung.';
	@override String get invalidUrl => 'Masukkan alamat pelayan seperti https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Contoh Seerr ini tidak menyokong Quick Connect.Ia memerlukan Seerr 3.4 atau lebih baru.';
	@override String get notInitialized => 'instans Seerr ini tidak menyelesaikan setup pertama berjalan';
	@override String get noPlexTokenForReauth => 'No. Plex token boleh didaftarkan semula';
	@override String get noStoredCredentials => 'Tiada maklumat log masuk tersimpan untuk log masuk semula';
	@override String get signInRejected => 'Sign-in telah ditolak';
	@override String get noSessionCookie => 'Seerr tidak mengeluarkan kuki sesi';
	@override String get freshCookieRejected => 'Seerr menolak kuki sesi baru';
	@override String get noUserInformation => 'Seerr tidak mengembalikan maklumat pengguna';
	@override String get sessionRejectedAfterReauth => 'Mesyuarat itu ditolak selepas penandatanganan semula.';
	@override String get permissionDenied => 'Seerr menafikan tindakan ini: akaun anda tidak lagi mempunyai kebenaran yang diperlukan';
	@override String get permissionRevoked => 'Anda tidak lagi mempunyai keizinan untuk meminta ini';
}

// Path: services
class _Translations$services$ms extends Translations$services$en {
	_Translations$services$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Perkhidmatan';
	@override String get hubSubtitle => 'Sync menonton kemajuan dan meminta tajuk baru.';
	@override String get integrations => 'Integrasi';
	@override String get notConnected => 'Tidak terhubung';
	@override String connectedAs({required Object username}) => 'Terhubung dengan @${username}';
	@override String get scrobble => 'Menjejaki kemajuan secara automatik';
	@override String get scrobbleDescription => 'Memperbaharui senarai anda apabila anda menyelesaikan episod atau filem.';
	@override String disconnectConfirm({required Object service}) => 'Menghilangkan sambungan ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG akan berhenti mengemas kini ${service}. sambungkan semula pada bila-bila masa.';
	@override String connectFailed({required Object service}) => 'Saya tidak boleh menyambung ke ${service}. cuba lagi.';
	@override late final _Translations$services$names$ms names = _Translations$services$names$ms._(_root);
	@override late final _Translations$services$simklReconnect$ms simklReconnect = _Translations$services$simklReconnect$ms._(_root);
	@override late final _Translations$services$deviceCode$ms deviceCode = _Translations$services$deviceCode$ms._(_root);
	@override late final _Translations$services$oauthProxy$ms oauthProxy = _Translations$services$oauthProxy$ms._(_root);
	@override late final _Translations$services$pendingAuth$ms pendingAuth = _Translations$services$pendingAuth$ms._(_root);
	@override late final _Translations$services$libraryFilter$ms libraryFilter = _Translations$services$libraryFilter$ms._(_root);
	@override String get seerrDescription => 'Hubungi Seerr atau Overseerr untuk mencari tajuk dan mengemukakan permintaan media.';
	@override late final _Translations$services$trackerDescriptions$ms trackerDescriptions = _Translations$services$trackerDescriptions$ms._(_root);
}

// Path: addServer
class _Translations$addServer$ms extends Translations$addServer$en {
	_Translations$addServer$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Menambah ${product} pelayan';
	@override String get serverUrls => 'Penyimpanan URL';
	@override String get serverUrlsHelper => 'Multiple URL dibenarkan, dipisahkan oleh commas.';
	@override String get findServer => 'Cari pelayan';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Mencari pelayan tempatan ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'Pelayan tempatan ${product}';
	@override String get username => 'Nama Pengguna';
	@override String get password => 'kata laluan';
	@override String get signIn => 'Log masuk';
	@override String get change => 'Perubahan';
	@override String get required => 'diperlukan';
	@override String couldNotReachServer({required Object error}) => 'Tidak boleh mencapai pelayan: ${error}';
	@override String signInFailed({required Object error}) => 'Pendaftaran yang gagal: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect kegagalan: ${error}';
	@override String get addPlexTitle => 'Mendaftar dengan Plex';
	@override String get pinExpired => 'PIN telah tamat sebelum log masuk.Sila cuba lagi.';
	@override String failedToRegisterAccount({required Object error}) => 'Akaun yang gagal didaftarkan: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Masukkan URL pelayan ${product} anda';
	@override String get addConnectionTitle => 'Menambah sambungan';
	@override String addConnectionTitleScoped({required Object name}) => 'Menambah kepada ${name}';
	@override String get signInWithPlexCard => 'Mendaftar dengan Plex';
	@override String get signInWithPlexCardSubtitle => 'Mengesahkan peranti ini. pelayan yang dikongsi ditambah.';
	@override String get signInWithPlexCardSubtitleScoped => 'Mengaktifkan akaun Plex. pengguna rumah menjadi profil.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Hubungi ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Masukkan URL, nama pengguna dan kata laluan pelayan anda.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Mendaftar masuk ke pelayan ${product} anda. menghubungkan ke ${name}.';
	@override String get borrowFromAnotherProfile => 'Pinjaman daripada profil lain';
	@override String get borrowFromAnotherProfileSubtitle => 'Menggunakan semula sambungan profil lain. profil yang dilindungi PIN memerlukan PIN.';
	@override String get invalidCredentials => 'Nama pengguna atau kata laluan yang tidak sah';
	@override String get authResponseNotJson => 'Jawapan pengesahan tidak sah JSON';
	@override String get authResponseIncomplete => 'Jawapan pendaftaran daripada pelayan tidak lengkap';
	@override String get quickConnectRejected => 'Quick Connect telah ditolak oleh pelayan';
	@override String get quickConnectNotJson => 'Jawapan Quick Connect tidak sah JSON';
	@override String get quickConnectMissingFields => 'Jawapan Quick Connect kekurangan kod atau rahsia';
	@override String get quickConnectPollRejected => 'Quick Connect pertanyaan telah ditolak oleh pelayan';
	@override String get serverTimedOut => 'Pelayan tidak bertindak balas dalam masa';
	@override String get responseNotJson => 'Jawapan pelayan tidak sah JSON';
	@override String responseMissingIdentity({required Object product}) => 'Jawapan itu kekurangan ID atau nama pelayan - adakah ini pelayan ${product}?';
	@override String probeFailed({required Object error}) => 'Tidak boleh mencapai pelayan: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Masukkan sekurang-kurangnya satu URL pelayan ${product}';
	@override String noReachableServer({required Object product}) => 'Tiada pelayan yang boleh diakses ${product} ditemui';
	@override String urlsPointToDifferentServers({required Object product}) => 'URL ini menunjuk kepada pelayan yang berbeza ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'URL ini tidak sepadan dengan pelayan ${product}';
	@override String get redirectUnsupported => 'Pelayan yang dialihkan ke URL yang tidak disokong';
	@override String redirectDifferentHost({required Object product}) => 'Server yang diarahkan ke host yang berbeza.Masukkan URL akhir ${product} secara langsung.';
	@override String get redirectInsecure => 'Pelayan yang diarahkan semula daripada HTTPS ke URL yang tidak selamat';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Pelayan yang diarahkan semula ke URL yang tidak disokong.Masukkan URL akhir ${product} secara langsung.';
	@override String get directPlexServerUrl => 'Plex URL pelayan';
	@override String get directPlexServerUrlHelper => 'Masukkan IP dan port tempatan pelayan media Plex anda.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (pilihan)';
	@override String get plexTokenHelper => 'Tinggalkan kosong jika akses tanpa auth dibenarkan pada pelayan ini.';
	@override String get plexTokenRequired => 'Sila masukkan token Plex anda (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Media Server (Lokal / Langsung)';
	@override String get connectDirectPlexCardSubtitle => 'Sambungkan secara langsung menggunakan IP atau URL tempatan tanpa akaun plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Hubungi secara langsung menggunakan IP atau URL tempatan. Hubungi ${name}.';
	@override String get insecureTitle => 'sambungan yang tidak disulitkan';
	@override String insecureDescription({required Object url}) => '${url} menggunakan HTTP. Orang lain dalam rangkaian boleh membaca atau mengubah kata laluan, token dan media anda. Gunakan HTTPS jika tersedia. Teruskan hanya jika anda mempercayai rangkaian ini dan menerima risikonya.';
	@override String get allowHttp => 'Benarkan HTTP';
	@override String get httpsRequired => 'Menggunakan HTTPS atau secara eksplisit membenarkan sambungan yang tidak disulitkan.';
}

// Path: cast
class _Translations$cast$ms extends Translations$cast$en {
	_Translations$cast$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Hantar ke peranti';
	@override String get searching => 'Mencari peranti yang dikeluarkan...';
	@override String connectedTo({required Object device}) => 'Menghubungkan ke ${device}';
	@override String get device => 'Peranti penghantaran';
	@override String get readyToCast => 'Sedia untuk dihantar';
	@override String get subtitle => 'Sari kata';
	@override String get serverNotAvailable => 'Media server tidak tersedia.';
	@override String get stopCasting => 'Hentikan penghantaran';
	@override String get castToDevice => 'Hantar ke peranti';
	@override String get noEpisodeAvailable => 'Tiada episod yang boleh ditayangkan.';
	@override String get startFailed => 'Tidak boleh memulakan casting. semak pelayan dan cuba lagi.';
}

// Path: automation
class _Translations$automation$ms extends Translations$automation$en {
	_Translations$automation$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Tiada sesi video aktif untuk dikendalikan.';
}

// Path: notifications
class _Translations$notifications$ms extends Translations$notifications$en {
	_Translations$notifications$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Episod baru';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$ms extends Translations$appAccess$en {
	_Translations$appAccess$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cuba setiap ciri percuma selama 7 hari';
	@override String get description => 'Memulakan percubaan tujuh hari dengan akses penuh kepada setiap ciri PlezyNG. tiada bayaran semasa percubaan dan tiada langganan.Selepas percubaan, satu pembelian seumur hidup pada harga kedai anda membuka PlezyNG seumur hidup.';
	@override String get trialEndedDescription => 'Membuka kunci setiap ciri dalam PlezyNG untuk hidup dengan satu pembelian pada harga kedai anda.';
	@override String get startTrial => 'Mulakan percubaan percuma 7 hari';
	@override String get trialActive => 'Ujian penuh 7 hari anda aktif.';
	@override String get trialEnded => 'Perbicaraan 7 hari telah berakhir';
	@override String get trialStartFailed => 'Saya tidak boleh menyimpan percubaan pada peranti ini. sila cuba lagi.';
	@override String get lifetimeTitle => 'PlezyNG dikunci untuk seumur hidup';
	@override String get lifetimeBody => 'Terima kasih! anda mempunyai akses seumur hidup kepada setiap fungsi PlezyNG.';
	@override String get manageTitle => 'PlezyNG akses seumur hidup';
	@override String get manageDescription => 'Cuba setiap ciri percuma selama 7 hari, kemudian membuka semua untuk seumur hidup dengan satu pembayaran pada harga kedai anda.';
	@override String buy({required Object price}) => 'Membuka semua ciri untuk ${price}';
	@override String get loadingPrice => 'Harga kedai yang dibayar...';
	@override String get retryPrice => 'Kembali ke harga lookup';
	@override String get restore => 'Restorasi pembelian seumur hidup';
	@override String get pending => 'Pembelian anda sedang menunggu pembayaran atau kelulusan. akses seumur hidup dibuka sebaik sahaja kedai melengkapkannya.';
	@override String get storeUnavailable => 'Pastikan anda mendaftar di kedai dan pembelian dibenarkan pada peranti ini.';
	@override String get productNotFound => 'PlezyNG seumur hidup tidak tersedia di kedai ini sehingga kini.';
	@override String get productQueryFailed => 'Tidak boleh memuatkan harga kedai. semak sambungan anda dan cuba lagi.';
	@override String get purchaseFailed => 'Pembelian tidak berjalan. cuba lagi.';
	@override String get restoreFailed => 'Tidak boleh sampai ke kedai untuk memulihkan pembelian anda. cuba lagi.';
	@override String get nothingToRestore => 'Nombor PlezyNG pembelian seumur hidup telah ditemui untuk akaun kedai ini.';
}

// Path: detail
class _Translations$detail$ms extends Translations$detail$en {
	_Translations$detail$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Berakhir pada ${time}';
}

// Path: watchLink
class _Translations$watchLink$ms extends Translations$watchLink$en {
	_Translations$watchLink$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Saya tidak boleh mencapai server Plex untuk pautan ini.';
	@override String get notFound => 'Saya tidak boleh menemui persembahan atau filem ini pada pelayan anda Plex.';
	@override String get ambiguous => 'Link ini sepadan dengan item pada lebih daripada satu pelayan.Tambah pelayan ke pautan.';
	@override String get plexOnly => 'Lihat pautan pada masa ini hanya menyokong Plex pelayan.';
	@override String get unsupportedItem => 'Lihat pautan hanya boleh membuka persembahan atau filem.';
	@override String get menuItem => 'Lihat link';
	@override String get dialogTitle => 'Lihat link';
	@override String get dialogShowHint => 'Membuka pautan ini memainkan episod seterusnya.Tambah &mode=shuffle ke hujung untuk memainkan persembahan di shuffle.';
	@override String get dialogMovieHint => 'Membuka pautan ini memainkan filem ini.';
	@override String get copy => 'Salin';
	@override String get copied => 'Link yang disalin';
}

// Path: homeLayout
class _Translations$homeLayout$ms extends Translations$homeLayout$en {
	_Translations$homeLayout$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Susun atur laman utama';
	@override String get resetToast => 'Home Reset ke layout asli Plezy hero';
	@override String get resetHeroTitle => 'Mengembalikan tataletak pahlawan kepada stok Plezy?';
	@override String get resetHeroBody => 'Mengalih keluar seting wira setiap baris dan membawa kembali satu banner berputar di bahagian atas rumah, seperti sebelum baris wira wujud.';
	@override String get removeRowTitle => 'Menghilangkan Home Range?';
	@override String removeRowBody({required Object title}) => '${title} akan dipadamkan. ini tidak boleh dikecualikan.';
	@override String get sync => 'Sinkron';
	@override String get syncAccountTitle => 'Sinkronkan tataletak dengan akaun Plex anda';
	@override String get syncAccountOn => 'Pada: peranti ini berkongsi urutan, baris, Hero dan Auto-slide dengan peranti lain anda.';
	@override String get syncAccountOff => 'Off: Peranti ini mengekalkan tataletak sendiri.';
	@override String get syncNow => 'Sinkronkan sekarang';
	@override String get plexHomeManager => 'Plex Pengurus Rumah';
	@override String get managePlexRows => 'Menguruskan Plex baris dalam Plezy';
	@override String get managePlexRowsDescription => 'Terbuka untuk menganjurkan baris-baris yang dipilih di rumah';
	@override String get organizeHomeRows => 'Mengatur rangkaian rumah';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} baris: bergerak, Hero, Auto-slide, menghapuskan';
	@override String organizeLibraryRows({required Object library}) => 'Mengatur ${library} baris';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Teruskan Menonton + ${n} baris: bergerak, Perpustakaan, Rumah, Hero, Auto-slide';
	@override String get renderAsHero => 'Render sebagai kad pahlawan';
	@override String get heroOnlySingleCollection => 'Hanya boleh didapati apabila baris ini diselesaikan kepada tajuk sebenar satu koleksi';
	@override String get hero => 'Sepanduk utama';
	@override String get autoSlide => 'Slaid automatik';
	@override String get autoSlideDescription => 'Arrows (PC) dan d-pad (TV) sentiasa berfungsi dan memulakan semula timer.';
	@override String get autoSlideEditDescription => 'Ia juga bergerak sendiri setiap beberapa saat. keluar: hanya bergerak apabila anda mengklik anak panah (PC) atau tekan kiri/kanan pada remote (TV).';
	@override String get enableHeroFirst => 'Membolehkan Hero Pertama';
	@override String get showOnHome => 'Menampilkan pada skrin rumah';
	@override String get home => 'rumah';
	@override String get removeFromHome => 'Keluar dari rumah';
	@override String get selectRowsFirst => 'Pilih baris rumah di bawah terlebih dahulu.';
	@override String plexManagedRows({required Object n}) => '${n} Plex baris yang dikendalikan';
	@override String get continueWatching => 'Menyambung tontonan';
	@override String get continueWatchingLibraryDescription => 'Perpustakaan ini mempunyai rangkaian kemajuan semula';
	@override String get continueWatchingHomeDescription => 'Rangkaian kemajuan semula yang ditunjukkan di Home';
	@override String get nextUpHomeDescription => 'Next Unwatched episode rangkaian dipaparkan secara berasingan di Home';
	@override String get library => 'Pustaka';
	@override String get showInRecommended => 'Pameran dalam Perpustakaan yang disyorkan';
	@override String get customPlexRow => 'Perbezaan Plex baris';
	@override String get heroNeedsLibrary => 'Periksa Perpustakaan Pertama — Hero Perlu Di Mana-mana Untuk Tunjukkan';
	@override String get heroNeedsSurface => 'Periksa Perpustakaan atau Rumah terlebih dahulu — Hero perlu di mana-mana untuk menunjukkan';
	@override String get removeHub => 'Menghilangkan Hub';
	@override String get noPlexRows => 'Nombor Plex baris yang dikendalikan dikembalikan untuk perpustakaan ini.';
	@override String get openDetails => 'Maklumat Terbuka';
	@override String get heroCards => 'Pemenang Kartu';
	@override String get tapHeroCard => 'Menangkap Kad Pahlawan';
	@override String get tvPlayFocus => 'Remote TV: menonjolkan butang Play';
	@override String get tvPlayFocusDescription => 'D-pad ke bawah berhenti pada butang Main sebelum bergerak ke baris seterusnya.';
	@override String get tvWrap => 'Remote TV: Kartu Pahlawan Loop';
	@override String get tvWrapDescription => 'Pada kad terakhir akan kembali ke kad pertama. berhenti pada kad terakhir. kiri pada kad pertama akan sentiasa pergi ke bar samping.';
	@override String get castOnHero => 'Bermain dengan banner pahlawan';
	@override String get castOnHeroDescription => 'Tunjukkan cast di bahagian bawah banner pahlawan. di luar hanya tajuk dan ringkasan.';
	@override String get customRows => 'Rangkaian Custom';
	@override String get loading => 'Home » Layout ...';
	@override String get noCustomRows => 'Tiada rangkaian biasa lagi';
	@override String get addRowHint => 'Gunakan Add Home row untuk membuat satu.';
	@override String get addHomeRow => 'Menambah Home Ronde';
	@override String get addHomeRowDescription => 'Pilih kategori; baris baru ditambah kepada Penganjur secara automatik';
	@override String get removeRow => 'Menghapuskan baris';
	@override String get recentlyAdded => 'baru-baru ini ditambah';
	@override String get recentlyReleased => 'baru-baru ini dikeluarkan';
	@override String get movieCollections => 'Koleksi filem';
	@override String get showCollections => 'Tunjukkan koleksi';
	@override String get rowTitle => 'Tajuk Row';
	@override String get content => 'Kesan';
	@override String get showThisRowIn => 'Tunjukkan baris ini dalam:';
	@override String get libraryRecommended => 'Perpustakaan yang disyorkan';
	@override String get heroCard => 'Pemenang Kartu';
	@override String get heroCardDescription => 'Menunjukkan sebagai satu kad berputar lebar penuh bukannya poster shelf.';
	@override String get heroUnavailableDescription => 'Hanya boleh didapati apabila baris ini diselesaikan kepada tajuk sebenar satu koleksi - dengan lebih daripada satu koleksi dipilih tidak ada satu tajuk untuk berputar melalui.';
	@override String get librariesSelection => 'Perpustakaan (meninggalkan semua tidak disemak untuk termasuk setiap perpustakaan)';
	@override String get librariesMergedDescription => 'Setiap perpustakaan yang disemak di sini digabungkan ke dalam satu baris ini.';
	@override String get movieCollectionsSelection => 'Koleksi filem (meninggalkan semua tidak disemak untuk setiap perpustakaan yang dipilih)';
	@override String get showCollectionsSelection => 'Tunjukkan koleksi (meninggalkan semua tidak disemak untuk setiap perpustakaan yang dipilih)';
	@override String get collectionRowsDescription => 'Jika satu koleksi bertanding, tajuk-tajuknya dipaparkan secara langsung dalam baris.Jika lebih daripada satu bertanding, setiap koleksi dipaparkan sebagai satu poster — ketiknya untuk membuka koleksi itu.';
	@override String get allCollections => 'Semua Koleksi';
	@override String get noRowsHere => 'Tiada baris di sini lagi.';
	@override String get hideWatchedRows => 'Menutup item yang dilihat dalam baris';
	@override String get hideWatchedRowsDescription => 'Judul yang dipantau sepenuhnya meninggalkan Rumah dan perpustakaan baris yang disyorkan.';
	@override String get untitledCollection => 'Koleksi yang tidak bertajuk';
	@override String get moveRowHint => 'Up/Down: bergerak baris · Pilih: turun di sini · Kembali: dibatalkan';
	@override String get organizeRowsHint => 'Pilih pada baris (atau tahan Pilih): pindah · Kiri/Kiri: pilihan baris · Kembali: selesai';
	@override String get layoutNavDescription => 'Pilih baris, perpustakaan, dan kategori koleksi';
	@override String get editHomeRow => 'Edit rumah rangkaian';
	@override String get resetHeroButton => 'Mengembalikan tataletak pahlawan kepada stok Plezy';
	@override String get reorderingUnlocked => 'Penyelesaian semula diselesaikan';
	@override String get reorderingLocked => 'Penyelesaian Locked';
	@override String get rowsCanBeDragged => 'Roda boleh ditarik — tekan kunci untuk mengelakkan';
	@override String get tapLockToDrag => 'Tekan kunci untuk menarik baris';
	@override String customRowLabel({required Object title}) => 'Jumlah : ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'menyembunyikan';
	@override String get remove => 'Keluarkan';
	@override String get libraryResumeRow => 'Rujukan semula perpustakaan ini';
	@override String get pressAgainToDelete => 'Tekan lagi untuk memadamkan';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'Pada';
	@override String get resetHeroButtonDescription => 'Mengalih keluar seting wira setiap baris dan membawa kembali satu banner berputar di atas, seperti sebelum baris wira wujud.';
	@override String get tapHeroCardDescription => 'Pilih sama ada menandakan atau memilih kad Hero memulakan playback atau membuka butiran.';
	@override String get heroTapPlayDescription => 'Mulakan item yang dipilih dengan segera.';
	@override String get heroTapDetailsDescription => 'Buka butiran item yang dipilih sebelum memilih tindakan.';
}

// Path: platform
class _Translations$platform$ms extends Translations$platform$en {
	_Translations$platform$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG menyambung ke pelayan media dan peranti playback anda di rangkaian tempatan anda.';
	@override String get locationPermission => 'PlezyNG menggunakan akses lokasi apabila iOS memerlukan untuk mengesan rangkaian tempatan anda dan menyambung ke pelayan media anda.';
	@override String get photoLibraryPermission => 'Pilih imej daripada perpustakaan foto anda untuk digunakan sebagai karya seni media.';
	@override String get cameraPermission => 'Mengimbas kod QR untuk menggabungkan Companion Remote.';
}

// Path: universalMedia
class _Translations$universalMedia$ms extends Translations$universalMedia$en {
	_Translations$universalMedia$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Media Terbuka';
	@override String get shortcutHelp => 'Mainkan pautan, senarai main atau fail untuk sesi ini.';
	@override String get intro => 'Buka pautan, senarai main, atau fail. Playback menggunakan pemain standard PlezyNG dan tidak menambah sejarah kepada perpustakaan anda.';
	@override String get openWhat => 'Apa yang anda mahu buka?';
	@override String get stream => 'Alamat aliran';
	@override String get playlist => 'Senarai Playlist';
	@override String get files => 'Peranti fail';
	@override String get favorites => 'Penyimpanan Stream Favorit';
	@override String get address => 'Alamat Media';
	@override String get addressHelp => 'URL dengan parameter pengesahan atau tandatangan yang diiktiraf hanya digunakan untuk sesi ini dan tidak boleh disimpan sebagai kegemaran.';
	@override String get displayName => 'Nama Pameran ( opsional )';
	@override String get displayNameHelp => 'Pilih nama pendek untuk pemutar dan kawalan media sistem.';
	@override String get allowHttp => 'Membolehkan sambungan HTTP yang tidak disulitkan';
	@override String get allowHttpHelp => 'HTTP tidak menyulitkan sambungan. membenarkan ia hanya pada rangkaian yang dipercayai. gunakan HTTPS apabila mungkin.';
	@override String get advancedProtocols => 'MPV sahaja: masukkan alamat RTSP, RTMP/RTMPS, UDP, atau RTP. Alamat ini tidak boleh disimpan sebagai kegemaran.';
	@override String get liveStream => 'Perlakukan sebagai hidup';
	@override String get liveStreamHelp => 'Gunakan ini untuk video atau radio secara langsung. aplikasi menyembunyikan bar masa, melompat butang, dan pergi ke masa opsyen.';
	@override String get privateSession => 'Hanya playback ini menggunakan alamat.Save a eligible stream favorite to keep it in this profile.';
	@override String get saveFavorite => 'Selamatkan kegemaran';
	@override String get playNow => 'Bermain sekarang';
	@override String get favoriteSaved => 'Stream favorit disimpan ke profil ini';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${count} masuk senarai main yang tidak disokong atau tidak selamat.',
	);
	@override String get playlistAddress => 'Alamat Playlist';
	@override String get playlistAddressHelp => 'Buka senarai m3U, M3U8, atau PLS daripada alamat web. pautan siaran langsung tidak menyimpan senarai main.';
	@override String get choosePlaylist => 'Pilih fail playlist';
	@override String get openPlaylist => 'Senarai Permainan Terbuka';
	@override String get playlistFormatsHelp => 'Senarai main boleh mengandungi sehingga 1,000 item dan 2 MB. HLS terbuka sebagai aliran supaya pemain boleh memilih kualiti.';
	@override String get saveQueuePlaylist => 'Simpan baris gilir sebagai senarai main';
	@override String get queuePlaylistSaved => 'Senarai main disimpan di sebelah fail media.';
	@override String get queuePlaylistUnavailable => 'Baris gilir ini tidak dapat disimpan sebagai senarai main setempat yang boleh digunakan semula.';
	@override String get queuePlaylistFolderRequired => 'Pilih lokasi simpanan dalam folder yang sama dengan fail dalam baris gilir.';
	@override String get noFavorites => 'Tiada rangkaian kegemaran disimpan sehingga kini. kekal dalam profil ini.';
	@override String get removeFavorite => 'Menghapuskan stream kegemaran';
	@override String get filesHelp => 'Pilih fail audio, video, atau ISO untuk tempoh sementara. fail dan URL tidak ditambah kepada sejarah perpustakaan.';
	@override String get chooseFiles => 'Pilih fail';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${count} fail yang dipilih',
	);
	@override String get wifiTransfer => 'Hantar fail melalui Wi-Fi';
	@override String get wifiTransferHelp => 'Memindahkan fail yang disokong daripada pelayar pada rangkaian yang sama dipercayai.';
	@override String get wifiTransferIntro => 'Buka alamat ini dalam pelayar pada peranti lain. pilih fail untuk menambahnya ke perpustakaan Fail dan buku peranti ini.';
	@override String get wifiTransferPrivacy => 'Peranti ini menerima fail melalui rangkaian tempatan anda. sesiapa sahaja yang tahu alamat ini boleh menghantar fail sehingga anda berhenti pemindahan atau alamat tamat tempoh selepas 15 minit. maksimum: 100 fail, 4 GiB per fail, 10 GiB total.';
	@override String get wifiTransferStarting => 'Menyediakan pemindahan peribadi dan terhad ...';
	@override String get wifiTransferUnavailable => 'Tidak boleh memulakan pemindahan. semak akses rangkaian tempatan dan cuba lagi.';
	@override String get openThisAddress => 'Buka salah satu daripada alamat ini pada peranti penghantaran';
	@override String get copyAddress => 'Menyalin alamat pemindahan';
	@override String get addressCopied => 'Alamat pemindahan disalin';
	@override String transferExpires({required Object time}) => 'Alamat ini tamat tempoh dalam ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${count} fail yang diterima',
	);
	@override String uploadedData({required Object size}) => 'Pengenalan kepada ${size}';
	@override String get stopTransfer => 'Hentikan pemindahan dan membatalkan alamat';
	@override String get startTransfer => 'Mulakan pemindahan';
	@override String get wifiImportedFiles => 'Penghantaran Wi-Fi';
	@override String get wifiBrowserTitle => 'Hantar fail kepada PlezyNG';
	@override String get wifiBrowserIntro => 'Pilih audio, video, ebook, atau komik fail untuk dihantar. fail disimpan dalam perpustakaan fail dan buku peranti ini. maksimum: 100 fail, 4 GiB setiap fail, 10 GiB total.';
	@override String get uploadFilesLabel => 'fail untuk menghantar';
	@override String get uploadSelected => 'Muat naik fail yang dipilih';
	@override String get uploadSelectFirst => 'Pilih satu atau lebih fail terlebih dahulu.';
	@override String get uploading => 'Penghantaran';
	@override String get uploadComplete => 'Fail ditambah kepada PlezyNG.';
	@override String get uploadFailed => 'Fail tidak boleh ditambah.Tahan halaman ini terbuka dan cuba lagi.';
	@override String get liveCue => 'hidup';
	@override String get liveSession => 'Penghantaran Live Stream';
	@override String get liveCueHelp => 'Untuk video atau radio secara langsung, aplikasi menyembunyikan bar masa dan melompat butang. ia tidak menyimpan alamat atau menonton sejarah.';
	@override String get sessionOnly => 'Playback ini merupakan sesi sahaja.';
	@override String get sessionOnlyHelp => 'Playback tidak pernah menyimpan kemajuan atau sejarah.Save the stream as a favorite to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'Gambar penyesuaian';
	@override String get pictureHelp => 'Perubahan imej ini hanya menjejaskan playback ini. mereka menetapkan semula apabila playback berakhir.';
	@override String get resetPicture => 'Reset imej';
	@override String get brightness => 'Cahaya';
	@override String get contrast => 'kontras';
	@override String get gamma => 'Perbezaan Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'Penghormatan';
	@override String get view360 => 'Pemandangan rata untuk video 360 darjah';
	@override String get view360Help => 'MPV memerlukan penapis v360 FFmpeg untuk pandangan ini.';
	@override String get view360Unavailable => 'Pembinaan MPV ini tidak boleh menggunakan penapis 360 darjah.';
	@override String get view360Yaw => 'pandangan horizontal';
	@override String get view360Pitch => 'Pandangan Vertikal';
	@override String get view360FieldOfView => 'Bidang pandangan';
	@override String get recordStream => 'Rekod Live Stream';
	@override String get stopRecording => 'Hentikan dan simpan rekod';
	@override String get recordingStarted => 'Rekod aktif. meninggalkan playback berhenti dan menyimpan rakaman.';
	@override String get recordingSaved => 'Rekod selesai dan diselamatkan.';
	@override String get recordingActive => 'Mengikut peranti ini. meninggalkan playback berhenti dan menyimpannya.';
	@override String get recordingFormatHelp => 'Untuk video, pilih MKV atau MPEG-TS. untuk audio, pilih MKA atau MKV.';
	@override String get replaceRecordingTitle => 'Menggantikan rekod ini?';
	@override String get replaceRecordingHelp => 'PlezyNG mengembalikan fail yang sedia ada semasa rakaman.Jika ia tidak dapat menyimpan rakaman baru, Plezyng memulihkan sandaran.';
	@override String get replaceRecording => 'Menggantikan fail';
	@override String get discHelp => 'Buka cakera dalam cakera optik komputer ini.Anda juga boleh membuka imej ISO daripada fail Peranti.';
	@override String get discs => 'cakera optik';
	@override String get editionOrTitle => 'Edisi atau tajuk cakera';
	@override String get dvd => 'Perkhidmatan DVD';
	@override String get bluray => 'Perbezaan Blu-ray';
	@override String get audioCd => 'CD audio';
	@override String get discAvailability => 'Disk playback memerlukan pembinaan MPV yang kompatibel, cakera disokong, dan kebenaran sistem operasi. ia tidak boleh melebihi perlindungan cakera komersial.';
	@override String get converterTitle => 'Menukar fail media tempatan';
	@override String get converterHelp => 'Menukar fail tempatan atau mengubahnya dengan FFmpeg.';
	@override String get converterIntro => 'Menukar fail audio atau video tempatan kepada format yang berfungsi pada lebih banyak peranti.';
	@override String get converterPrivacy => 'FFmpeg mesti dipasang pada komputer ini.Conversion hanya membaca fail tempatan.Ia tidak memuat turun aliran atau menghapuskan DRM.';
	@override String get converterChooseInput => 'Pilih fail media tempatan';
	@override String get converterFormat => 'Format output';
	@override String get converterMp4 => 'MP4 · H.264 dan AAC';
	@override String get converterM4a => 'M4A · AAC audio';
	@override String get converterMp3 => 'MP3 dan audio';
	@override String get allowFtp => 'membenarkan FTP';
	@override String get allowFtpHelp => 'FTP menghantar media tanpa penyulitan. gunakan hanya pada rangkaian yang dipercayai.';
	@override String get converterSaveAs => 'Menyelamatkan media yang ditukar sebagai';
	@override String get converterExtensionMismatch => 'Pilih nama fail dengan ekstensi output yang dipilih.';
	@override String get converterUnsupportedInput => 'Pilih fail audio atau video.';
	@override String get converterLocalOnly => 'Fail yang dipilih tidak tersedia sebagai laluan peranti tempatan.';
	@override String get converterReplaceTitle => 'Menggantikan fail ini?';
	@override String get converterReplaceHelp => 'PlezyNG mengembalikan fail yang sedia ada sehingga salinan yang ditukar disimpan.';
	@override String get converterStarting => 'Bermula daripada FFmpeg...';
	@override String get converterProgress => 'Menukar kepada komputer ini ...';
	@override String get converterComplete => 'Konversi selesai. fail baru telah siap.';
	@override String get converterFfmpegMissing => 'FFmpeg kekurangan atau tidak menyokong format ini.';
	@override String get converterFailed => 'Periksa bahawa fail sumber boleh dibaca dan destinasi mempunyai ruang percuma yang mencukupi.';
	@override String get converterCancelled => 'Konversi dibatalkan. hasil yang tidak lengkap telah dihapuskan.';
	@override String get converterDesktopOnly => 'Konversi tempatan boleh didapati pada komputer desktop dengan FFmpeg dipasang.';
	@override String get converterStart => 'Menukar fail';
	@override String get mediaToolsTitle => 'Alat Media';
	@override String get mediaToolsShortcut => 'Menangkap atau berkongsi media, menambah ekstensi carian, atau gunakan baris perintah.';
	@override String get mediaToolsIntro => 'Pilih alat berfokus. capture dan stream-out menggunakan FFmpeg yang dipasang pada desktop ini. ekstensi dan perintah CLI menggunakan permintaan HTTPS yang terhad dan aliran Open media yang sedia ada.';
	@override String get mediaToolsAccessibility => 'Pilihan alat dan kawalan berfungsi dengan sentuhan, penunjuk, papan kekunci, dan fokus D-pad. Rekod, perkongsian, dan perubahan status carian diumumkan.';
	@override String get mediaTool => 'Alat Media';
	@override String get captureIntro => 'Mencatat skrin atau kamera anda ke fail MP4 pada komputer ini. FFmpeg perlu dipasang dan termasuk kod H.264.';
	@override String get captureNoDevices => 'Tiada skrin atau kamera ditemui. semak sokongan penangkapan FFmpeg dan keizinan privasi sistem operasi.';
	@override String get captureSource => 'skrin atau kamera';
	@override String get captureScreen => 'skrin';
	@override String get captureAudioSource => 'Pengenalan audio ( opsional )';
	@override String get captureAudioHelp => 'Tambah audio daripada mikrofon atau input yang tersedia. pilihan peranti bergantung kepada FFmpeg dan keizinan sistem.';
	@override String get captureAudioNone => 'Tiada audio';
	@override String get captureDefaultAudio => 'Pengenalan audio lalai';
	@override String get captureWaylandHelp => 'Wayland membatasi penangkapan XWayland ini kepada X display. Windows di luar XWayland mungkin tidak muncul.';
	@override String get captureFrameRate => 'Kadar rakaman';
	@override String get capturePrivacy => 'Rekod disimpan hanya untuk fail yang anda pilih. penangkapan mikrofon adalah opsional. PlezyNG tidak memuat naik rekod.';
	@override String get captureSaveAs => 'Menyimpan rekod skrin sebagai';
	@override String get captureExtensionMismatch => 'Pilih nama fail yang berakhir dalam .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg atau kod video H.264 tidak boleh didapati.Memasang pembinaan FFmpeg yang disokong, kemudian cuba lagi.';
	@override String get captureFailed => 'Pendaftaran tidak boleh disimpan. semak kebenaran peranti, penyimpanan yang tersedia, dan sokongan FFmpeg.';
	@override String get captureSaved => 'Rekod skrin disimpan.';
	@override String get captureElapsedLabel => 'Masa rekod';
	@override String get captureStart => 'Mulakan rekod';
	@override String get capturePreview => 'Pratonton dalam pemain';
	@override String get capturePreviewHelp => 'Pratonton sumber yang dipilih dalam pemain standard. Pratonton hanya untuk sesi ini dan tidak menyimpan rakaman. Sokongan peranti dan keizinan bergantung pada MPV dan sistem pengendalian. Pratonton menggunakan video sahaja; audio pilihan boleh disertakan dalam rakaman yang disimpan.';
	@override String get capturePreviewActive => 'Pratonton langsung · tidak merakam';
	@override String get captureStop => 'berhenti dan menyelamatkan';
	@override String get captureMode => 'Penangkapan';
	@override String get shareMode => 'berkongsi';
	@override String get shareIntro => 'Hantar fail media tempatan ke peranti lain di rangkaian peribadi anda. PlezyNG mewujudkan aliran sementara HLS.';
	@override String get sharePrivacy => 'Sesiapa sahaja di rangkaian tempatan anda yang menerima pautan peribadi boleh menonton sementara ia aktif. pautan tamat tempoh selepas 60 minit. berhenti berkongsi untuk menutup pelayan dan membatalkan pautan.';
	@override String get shareChooseFile => 'Pilih fail media';
	@override String get shareChooseHelp => 'Pilih fail audio atau video tempatan. fail itu kekal pada komputer ini.';
	@override String get shareFfmpegMissing => 'FFmpeg atau kod H.264/AAC tidak tersedia.Memasang FFmpeg dengan sokongan kod H.264 dan AAC.';
	@override String get shareFailed => 'Aliran tidak boleh bermula atau berhenti secara tidak dijangka. semak FFmpeg dan akses rangkaian.';
	@override String get shareActive => 'Stream bersedia di rangkaian peribadi anda.';
	@override String get shareEnded => 'Media telah mencapai akhir dan tidak lagi dibahagikan.';
	@override String get shareStopped => 'Perkongsian berhenti. pautan sementara tidak lagi sah.';
	@override String get shareUrlCopied => 'alamat yang disalin.';
	@override String get shareOpenUrl => 'Buka alamat ini dalam satu pemain pada peranti lain';
	@override String get shareQrLabel => 'Kod QR untuk alamat aliran sementara';
	@override String get shareQrHelp => 'Scan dengan pemain yang kompatibel yang disambungkan ke rangkaian peribadi yang sama.';
	@override String get shareHttpHint => 'Stream ini menggunakan HTTP yang tidak disulitkan. dalam PlezyNG, biarkan HTTP sebelum membuka.';
	@override String get shareCopyUrl => 'Menyalin alamat Stream';
	@override String get shareExpiresLabel => 'Link akan tamat pada';
	@override String get shareStarting => 'Menyediakan aliran ...';
	@override String get shareStart => 'Mulakan perkongsian';
	@override String get shareStop => 'Berhenti berkongsi';
	@override String get extensionsMode => 'Perpanjangan dan CLI';
	@override String get extensionsIntro => 'Tambah data-hanya ekstensi carian untuk mencari media. Pilih hasil untuk memuat naik ke borang yang biasa Open media.';
	@override String get extensionsPrivacy => 'Manifesto boleh menentukan satu titik akhir carian HTTPS dan medan tindak balas peta. ia tidak boleh menjalankan kod, menambah tajuk permintaan, membaca fail, atau melancarkan perintah shell.';
	@override String get extensionImport => 'Menambah Perpanjangan manifest';
	@override String get extensionEmpty => 'Tiada perkhidmatan carian lagi. pilih fail manifest JSON yang boleh dipercayai untuk menambah satu.';
	@override String get extensionChoose => 'Perkhidmatan Pencarian';
	@override String get extensionSearchConsent => 'Setiap carian menghantar kata-kata anda kepada perkhidmatan HTTPS ini. hasil dibuka hanya selepas anda memilih satu.';
	@override String get extensionSearchLabel => 'Pencarian Media';
	@override String get extensionSearch => 'Pencarian';
	@override String get extensionSearching => 'Mencari ...';
	@override String get extensionNoResults => 'Tiada hasil media yang selamat dikembalikan. cuba carian lain.';
	@override String get extensionInstallTitle => 'Menambah perkhidmatan carian ini?';
	@override String get extensionReplaceTitle => 'Memperbaharui perkhidmatan carian ini?';
	@override String get extensionService => 'Perkhidmatan';
	@override String get extensionEndpoint => 'HTTPS titik akhir';
	@override String get extensionConsent => 'Teks carian anda dihantar ke perkhidmatan ini. manifesto tidak mengandungi kod yang boleh dijalankan. teruskan hanya jika anda mempercayai titik akhir ini.';
	@override String get extensionInstall => 'menambah perkhidmatan';
	@override String get extensionReplace => 'Perkhidmatan Update';
	@override String get extensionRemoveTitle => 'Menghapuskan perkhidmatan carian ini?';
	@override String get extensionRemoveHelp => 'Ini menghapuskan perkhidmatan daripada profil ini.PlezyNG tidak menghubungi titik akhir.';
	@override String get extensionRemove => 'Hentikan Perkhidmatan';
	@override String get extensionInvalidManifest => 'Fail ini bukan manifest lanjutan yang disokong. lihat panduan Open media untuk format.';
	@override String get extensionSaveFailed => 'Perpanjangan tidak boleh disimpan ke profil aktif.';
	@override String get extensionSearchFailed => 'Perkhidmatan carian tidak mengembalikan jawapan yang sah. semak titik akhir dan cuba lagi.';
	@override String get cliTitle => 'Garis Perintah';
	@override String get cliHelp => 'Gunakan panduan plezyctl untuk mengesahkan manifesto atau mencari ekstensi yang sama. Ulasan perkhidmatan HTTPS sebelum setiap carian. Hasil dibuka dalam borang media yang sedia ada; pilih butang playback untuk memulakan.';
	@override String get cliCopyExample => 'Contoh perintah salinan';
	@override String get cliCopied => 'contoh yang disalin.';
}

// Path: fileSources
class _Translations$fileSources$ms extends Translations$fileSources$en {
	_Translations$fileSources$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'fail dan buku';
	@override String get subtitle => 'Membaca, mendengarkan, dan menonton daripada fail anda sendiri.';
	@override String get add => 'Menambah sumber';
	@override String get importFiles => 'Pengimportan fail';
	@override String get localFiles => 'Pada peranti ini';
	@override String get source => 'Sumber';
	@override String get name => 'Nama';
	@override String get endpoint => 'Pelayan URL';
	@override String get smbEndpointHint => 'Contoh: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Masukkan pelayan SMB dan satu folder kongsi.';
	@override String get root => 'Folder atau awalan';
	@override String get smbFolderHelp => 'Biarkan kosong untuk menggunakan seluruh folder kongsi, atau masukkan folder di dalamnya.';
	@override String get username => 'Nama Pengguna';
	@override String get smbDomain => 'Domain (pilihan)';
	@override String get password => 'kata laluan';
	@override String get token => 'API token';
	@override String get accessKey => 'Akses ke kunci ID';
	@override String get secretKey => 'Kunci akses rahsia';
	@override String get sessionToken => 'Token sesi ( opsional )';
	@override String get region => 'Daerah';
	@override String get clientId => 'Pengenalan kepada OAuth Client ID';
	@override String get clientSecret => 'OAuth Client Secret (hanya desktop Google)';
	@override String get allowHttp => 'Benarkan HTTP tanpa penyulitan pada rangkaian yang dipercayai';
	@override String get smbEncryption => 'Sulitkan sambungan SMB3';
	@override String get smbEncryptionHint => 'Gunakan penyulitan SMB3 apabila NAS menyokongnya.';
	@override String get connect => 'Sambung';
	@override String get cancel => 'Batalkan';
	@override String get save => 'menyelamatkan';
	@override String get close => 'Tutup';
	@override String get removeSource => 'Penyambung sumber';
	@override String get disconnectMessage => 'Putuskan sambungan sumber ini? Fail yang dimuat turun serta sejarah bacaan dan pendengaran anda akan kekal pada peranti ini.';
	@override String get localFolder => 'Pilih folder';
	@override String get empty => 'Tiada apa-apa di sini';
	@override String get emptyHint => 'Tambah sumber atau import buku, buku audio, muzik, atau video.';
	@override String get search => 'Cari folder ini';
	@override String get searchCached => 'Pencarian untuk perpustakaan diselamatkan';
	@override String get refresh => 'Menyejukkan';
	@override String get loadMore => 'muat lebih banyak';
	@override String get offline => 'Terdapat offline';
	@override String get download => 'Tetap offline';
	@override String get removeDownload => 'Menghapuskan offline copy';
	@override String get continueReading => 'Teruskan bacaan';
	@override String get continueListening => 'Teruskan Dengarkan';
	@override String get continueWatching => 'Menyambung tontonan';
	@override String get read => 'Bacaan';
	@override String get listen => 'Dengarkan';
	@override String get play => 'Bermain';
	@override String get pause => 'Henti Sejenak';
	@override String get stop => 'Berhenti';
	@override String get startOver => 'Bermula di atas';
	@override String get finished => 'selesai';
	@override String get markFinished => 'Mark telah selesai';
	@override String get markUnfinished => 'Mark yang tidak selesai';
	@override String get editions => 'Edisi dan fail';
	@override String get chapters => 'Bab';
	@override String get bookmarks => 'Buku dan nota';
	@override String get bookmark => 'Menambah Bookmark';
	@override String get highlight => 'Peningkatan';
	@override String get note => 'Nota';
	@override String get delete => 'Padam';
	@override String get export => 'Notis eksport';
	@override String get exported => 'Notis yang dieksport';
	@override String get sync => 'Sinkronkan kemajuan';
	@override String get synced => 'Kemajuan bersin';
	@override String get conflict => 'Peranti lain mempunyai kedudukan yang berbeza. pilih di mana untuk meneruskan.';
	@override String get useLocal => 'Gunakan peranti ini';
	@override String get useRemote => 'Menggunakan peranti lain';
	@override String get history => 'Sejarah Posisi';
	@override String get groupAudio => 'Mendengar sebagai satu buku audio';
	@override String get groupHint => 'Menggabungkan fail audio yang kini dimuat naik dalam folder ini. muat semua halaman terlebih dahulu.';
	@override String get order => 'Perintah fail';
	@override String get moveUp => 'bergerak ke atas';
	@override String get moveDown => 'bergerak ke bawah';
	@override String get speed => 'Kelajuan Playback';
	@override String get sleep => 'Waktu Tidur';
	@override String get sleepOff => 'keluar';
	@override String get endChapter => 'Akhir daripada bab';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minit',
	);
	@override String get skipBack => 'Kembali ke Sk';
	@override String get skipForward => 'melompat ke hadapan';
	@override String get smartRewind => 'Kembali ke Smart selepas istirahat';
	@override String get playbackOptions => 'Pilihan pendengaran';
	@override String remaining({required Object time}) => '${time} yang tersisa';
	@override String get contents => 'Kandungan';
	@override String get readerSettings => 'Membaca seting';
	@override String get fontSize => 'Saiz teks';
	@override String get lineHeight => 'Garis ruang';
	@override String get margin => 'Margin';
	@override String get font => 'Jenis muka';
	@override String get serif => 'Serif';
	@override String get sans => 'Tanpa serif';
	@override String get mono => 'Monospace';
	@override String get columns => 'Kolom';
	@override String get scroll => 'Bergerak secara vertikal';
	@override String get justify => 'Jajarkan teks pada kedua-dua sisi';
	@override String get readerTheme => 'Penampilan halaman';
	@override String get appTheme => 'Mengikuti tema app';
	@override String get paper => 'kertas';
	@override String get sepia => 'Sepia';
	@override String get night => 'Malam yang';
	@override String get readAloud => 'Bacakan halaman ini dengan kuat';
	@override String get readAlong => 'Baca sambil mendengar';
	@override String get stopReading => 'Hentikan Narrasi';
	@override String get searchBook => 'Pencarian dalam buku';
	@override String get noMatches => 'Tiada perlawanan';
	@override String get previousPage => 'Halaman Sebelumnya';
	@override String get nextPage => 'Halaman seterusnya';
	@override String page({required Object number}) => 'Halaman ${number}';
	@override String get externalBlocked => 'Rujukan buku luaran disekat dalam pembaca.';
	@override String get loading => 'Pembukaan...';
	@override String get narrator => 'Penyanyi';
	@override String get audio => 'Audio yang';
	@override String get video => 'Video';
	@override String get ebooks => 'Ebook';
	@override String get all => 'Semua';
	@override String get downloads => 'fail offline';
	@override String get confirmDelete => 'Alih keluar salinan luar talian yang dipilih? Kedudukan bacaan atau pendengaran dan nota anda akan disimpan.';
	@override String get errorAuthentication => 'Log masuk semula untuk menyambungkan semula sumber ini.';
	@override String get errorPermission => 'Sumber ini tidak memberikan akses kepada fail yang diminta.';
	@override String get errorUnavailable => 'Sumber tidak tersedia. cuba lagi, atau buka salinan offline.';
	@override String get errorUnsupported => 'Format atau sambungan ini tidak disokong pada peranti ini.Sila semak panduan tetapan sumber.';
	@override String get errorInvalidData => 'Fail atau jawapan pelayan ini tidak boleh dibaca dengan selamat.';
	@override String get errorCancelled => 'Operasi telah dibatalkan.';
	@override String get errorConflict => 'Kedudukan berubah dalam sesi lain. buka semula item untuk memilih kedudukan.';
	@override String get signIn => 'Log masuk';
	@override String get reconnect => 'Sambungan semula';
	@override String get folderHelp => 'Biarkan kosong untuk bermula pada akar sumber. URL S3 termasuk bucket.';
	@override String get preferences => 'Persyaratan';
	@override String get timePosition => 'Kedudukan';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Subtitle trek';
	@override String get none => 'Tiada';
	@override String get fullscreen => 'skrin penuh';
	@override String get syncLocation => 'folder Sink progress (pilihan)';
	@override String get syncLocationHint => 'folder WebDAV yang didedikasikan untuk PlezyNG status. menggunakan penulisan bersyarat; media kekal tidak berubah.';
	@override String get audiobooks => 'Buku audio';
	@override String get comics => 'Komik';
	@override String get scan => 'Scan untuk buku dan media';
	@override String get browserReader => 'Pembaca Terbuka';
	@override String get browserReaderHelp => 'Membaca dibuka dalam pelayar anda.Jadilah PlezyNG terbuka untuk menyimpan lokasi dan nota anda.';
	@override String get on => 'Pada';
	@override String get advancedSetup => 'Pendaftaran App';
	@override String get microsoftSignIn => 'Mendaftar dengan Microsoft';
	@override String get zoomIn => 'Zoom dalam';
	@override String get zoomOut => 'Zoom keluar';
	@override String get fitPage => 'Halaman yang sesuai';
	@override String get fitWidth => 'Sesuai lebar';
	@override String get actualSize => 'Saiz semasa';
	@override String get goToPage => 'Pergi ke halaman';
	@override String get goToSection => 'Pergi ke bab';
	@override String pageRange({required Object count}) => 'Masukkan nombor dari 1 hingga ${count}';
	@override String get pageLayout => 'Laman Layout';
	@override String get automatic => 'automatik';
	@override String get singlePage => 'Halaman tunggal';
	@override String get twoPages => '2 Halaman';
	@override String get readingDirection => 'Membaca arah';
	@override String get leftToRight => 'kiri ke kanan';
	@override String get rightToLeft => 'Kanan ke kiri';
	@override String get letterSpacing => 'Surat yang meliputi';
	@override String get wordSpacing => 'Perkataan ruang';
	@override String get readerControlsHelp => 'Jarakkan dua jari atau gunakan kawalan zum untuk membesarkan halaman. Seret untuk mengalihkan halaman. Ctrl/⌘ dengan + atau − melaraskan zum; Ctrl/⌘ dengan 0 menetapkannya semula. Page Up dan Page Down menyelak halaman.';
	@override String get imagePage => 'Halaman Komik';
	@override String get resetReader => 'Menetapkan semula keutamaan bacaan';
	@override String get zoom => 'Zoom';
	@override String get useFiles => 'Menggunakan fail dan buku';
	@override String get cancelScan => 'Batalkan pemindaian';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Terdapat Limit Download Offline';
	@override String get offlineQuotaHelp => 'Tetapkan ruang maksimum yang digunakan oleh salinan offline, fail yang diimport, dan muat turun. Mengurangkan had tidak menghapuskan salinan sedia ada.';
	@override String get offlineStorageUsage => 'Penyimpanan Offline';
	@override String get reservedStorage => 'Penyimpanan';
	@override String get downloadQueue => 'Mengunduh Queue';
	@override String get downloadRunning => 'Dimuat turun';
	@override String get downloadQueued => 'Menunggu';
	@override String get downloadPaused => 'beristirahat';
	@override String get downloadFailed => 'keperluan penarikan diri';
	@override String get importing => 'Pengimportan';
	@override String get importInterrupted => 'Import dihentikan · menghapuskan untuk membersihkan';
	@override String get errorQuotaExceeded => 'Batas penyimpanan offline telah dicapai. menaikkan had atau menghapuskan salinan yang dimuat turun.';
	@override String get errorStorageLow => 'Tiada penyimpanan peranti percuma yang mencukupi untuk mengekalkan simpanan yang dilindungi.';
	@override String get errorStorageUnavailable => 'PlezyNG tidak boleh memeriksa penyimpanan peranti percuma, jadi penulisan dihentikan.';
	@override String get removeDownloadJob => 'Menghapus download';
	@override String get downloadAlreadyComplete => 'Download ini selesai sebelum ia boleh dihapuskan. item kini tersedia offline.';
	@override String get confirmRemoveDownloadJob => 'Menghapuskan muat turun ini dan menyingkirkan sebarang data yang dimuat turun sebahagiannya? kedudukan dan nota anda akan kekal.';
}

// Path: lending
class _Translations$lending$ms extends Translations$lending$en {
	_Translations$lending$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Perpustakaan Awam';
	@override String get add => 'Menambah perpustakaan';
	@override String get other => 'Perpustakaan lain';
	@override String get libraryName => 'Nama Perpustakaan';
	@override String get libraryUrl => 'Laman web perpustakaan';
	@override String get libraryUrlHint => 'Gunakan katalog perpustakaan anda atau halaman log masuknya.';
	@override String get intro => 'Pinjaman daripada perpustakaan anda.Tahan buku anda dekat.';
	@override String get handoff => 'Log masuk, pinjam dan baca dengan selamat melalui perkhidmatan perpustakaan anda sendiri.';
	@override String get openService => 'Perpustakaan Terbuka';
	@override String get findLibrary => 'Cari perpustakaan';
	@override String get search => 'Mencari buku dan penulis';
	@override String get catalogue => 'Katalog';
	@override String get loans => 'Pinjaman';
	@override String get holds => 'Tempahan';
	@override String get signIn => 'Mendaftar dengan perpustakaan anda';
	@override String get waiting => 'Hentikan pendaftaran dalam pelayar anda, kemudian kembali ke sini.';
	@override String get cancel => 'Batalkan';
	@override String get disconnect => 'Menghapuskan perpustakaan';
	@override String get disconnectMessage => 'Alih keluar perpustakaan ini daripada profil ini? Pinjaman dan tempahan anda kekal dengan perpustakaan.';
	@override String get getBook => 'Dapatkan buku';
	@override String get checkAvailability => 'Periksa ketersediaan';
	@override String get available => 'tersedia untuk pinjaman';
	@override String get unavailable => 'Tidak tersedia pada masa ini';
	@override String get borrow => 'Pinjam';
	@override String get placeHold => 'Buat tempahan';
	@override String get returnBook => 'Kembali awal';
	@override String get cancelHold => 'Batalkan tempahan';
	@override String get confirmBorrow => 'Adakah anda meminjam tajuk ini daripada perpustakaan anda?';
	@override String get confirmReturn => 'Pulangkan judul ini sekarang? Anda mungkin perlu meminjamnya semula untuk meneruskan.';
	@override String get confirmCancelHold => 'Batalkan tempahan anda untuk judul ini?';
	@override String get email => 'Pastikan pemberitahuan email';
	@override String due({required Object date}) => 'Tarikh pemulangan: ${date}';
	@override String queue({required Object position}) => 'Posisi ${position} dalam baris';
	@override String get empty => 'Tiada tajuk di sini.';
	@override String get openLibraryNote => 'Terokai katalog Open Library. Pilihan membaca dan meminjam dipaparkan pada halaman setiap judul.';
	@override String get more => 'muat lebih banyak';
	@override String get gateway => 'Perpustakaan Perkhidmatan Sign-in';
	@override String get gatewayHint => 'disediakan oleh perpustakaan anda atau pentadbir PlezyNG.';
	@override String get advanced => 'Integrasi Perpustakaan';
	@override String get loadLibraries => 'Pilih perpustakaan anda';
	@override String get expired => 'Pinjaman ini telah tamat tempoh.';
	@override String get updated => 'Perpustakaan dikemaskini';
	@override String get continueService => 'Teruskan dalam perkhidmatan';
	@override String get comingSoon => 'Pinjaman dalam aplikasi · Datang segera';
	@override String get comingSoonDescription => 'Anda boleh menggunakan perpustakaan anda di Libby semasa kami selesai menghubungkannya.';
	@override String get suspendHold => 'Tangguhkan tempahan';
	@override String get resumeHold => 'Sambung semula tempahan';
	@override String get suspendMessage => 'Kekalkan tempat anda dalam barisan dan benarkan pembaca seterusnya meminjam salinan ini? Anda boleh menyambung semula tempahan kemudian.';
	@override String get resumeMessage => 'Sambung semula tempahan ini supaya perpustakaan boleh menawarkan salinan seterusnya yang tersedia?';
	@override String get editEmail => 'Perubahan pemberitahuan e-mel';
}

// Path: audiobook
class _Translations$audiobook$ms extends Translations$audiobook$en {
	_Translations$audiobook$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Membaca & Mendengarkan Sync';
	@override String get syncHelp => 'Tetapkan kedudukan bacaan, kedudukan pendengaran, status penyelesaian, penanda buku dan nota di seluruh peranti anda. Pilih akaun penyimpanan yang disertakan dan gunakan kod sinkron yang sama pada setiap peranti. Membaca dan mendengar kekal berasingan.';
	@override String get addSyncSource => 'Tambah Google Drive, OneDrive, Dropbox, WebDAV atau S3 dalam Fail & Buku terlebih dahulu.';
	@override String get syncDestination => 'Akaun Penyimpanan Sync';
	@override String get syncFolder => 'Sinkron folder atau prefix';
	@override String get syncCode => 'Kod Sinkron Peribadi';
	@override String get syncCodeHelp => 'Mencipta kod pada peranti pertama anda, kemudian masukkan kod itu pada peranti lain anda. simpan salinan peribadi: ia adalah kunci kepada keadaan yang disulitkan anda. gunakan kod yang berbeza untuk setiap orang.';
	@override String get showCode => 'Menunjukkan atau menyembunyikan kod sink';
	@override String get newSyncCode => 'Mencipta kod sink baru';
	@override String get saveSync => 'Penyimpanan dan Sync';
	@override String get disableSync => 'Hentikan penyegerakan pada peranti ini';
	@override String get syncSourceDisconnect => 'Menghapuskan sumber ini akan mematikan bacaan dan mendengar sink di sini. fail sink yang disulitkan akan kekal dalam pembekal.';
	@override String get syncReconnect => 'Menghubungkan semula akaun penyimpanan';
	@override String lastSynced({required Object time}) => 'Terakhir disegerakkan di ${time}';
	@override String get syncConflicts => 'Pilih di mana untuk mengembalikan';
	@override String get conflictHelp => 'Perubahan-perubahan ini dibuat secara bebas. pilih kedudukan atau versi bookmark untuk disimpan. jam yang lebih lambat atau peratusan yang lebih tinggi tidak secara automatik menang.';
	@override String syncDevice({required Object device}) => 'Peranti ${device}';
	@override String get syncUnknownDevice => 'Peranti yang tidak diketahui';
	@override String get deletedBookmark => 'Tanda buku yang dihapuskan';
	@override String get finished => 'selesai';
	@override String readingPosition({required Object percent}) => 'Pembacaan · ${percent}%';
	@override String get chapterTimeline => 'Bab Kemajuan';
	@override String get bookTimeline => 'Buku Keseluruhan Kemajuan';
	@override String bookRemaining({required Object time}) => 'Waktu yang tersisa dalam buku ini: ${time}';
	@override String chapterRemaining({required Object time}) => 'Waktu yang tersisa dalam bab ini: ${time}';
	@override String get unknownRemaining => 'Jumlah masa yang tersedia apabila bahagian-bahagian dimainkan';
	@override String get undoSeek => 'Permintaan Terakhir';
	@override String get customSpeed => 'Kelajuan Playback yang disesuaikan';
	@override String get speedHelp => 'Pilih kelajuan daripada 0.25× kepada 4×.';
	@override String get apply => 'Permohonan';
	@override String get customSleep => 'Tarikh Tidur Khas';
	@override String get sleepMinutes => 'Jadual : 1 - 1440';
	@override String sleepChapters({required Object count}) => 'Berhenti selepas ${count} bab';
	@override String get extendSleep => 'Tambah 5 minit';
	@override String sleepRemaining({required Object time}) => 'Jadual tidur : ${time}';
	@override String get useDefaults => 'Gunakan kawalan pendengaran ini untuk buku baru';
	@override String get librarySort => 'Perbezaan buku';
	@override String get sortTitle => 'Tajuk';
	@override String get sortAuthor => 'Penulis';
	@override String get sortNarrator => 'Penceramah';
	@override String get sortSeries => 'Perintah siri';
	@override String get sortRecent => 'baru-baru ini dibuka';
	@override String get statusFilter => 'Status bacaan';
	@override String get statusAll => 'Semua buku';
	@override String get statusNew => 'Tidak bermula';
	@override String get statusProgress => 'dalam kemajuan';
	@override String get statusFinished => 'selesai';
	@override String get goToTime => 'Pergi ke masa';
	@override String get timeHelp => 'Jam : minit : detik atau minit : detik';
	@override String get recoveryHelp => 'Eksport salinan yang disulitkan baru-baru ini sebelum memindahkan atau memperbaiki data sink. Import bergabung dengan keadaan semasa; mereka tidak pernah menggantikan sejarah sink tempatan. Simpan kod sink secara berasingan.';
	@override String get recoveryExport => 'Mengeksport fail pemulihan yang disulitkan';
	@override String get recoveryImport => 'Import fail pemulihan yang disulitkan';
	@override String get recoveryImportConfirm => 'Menggabungkan fail pemulihan yang disulitkan ini dengan kedudukan bacaan semasa dan nota? sejarah yang sedia ada akan dikekalkan. perpustakaan berkongsi dan ID item tidak termasuk; tetapkan ID yang sepadan pada setiap peranti sebelum mengimport.';
	@override String get recoveryExported => 'Fail pemulihan yang disulitkan disimpan.';
	@override String get recoveryImported => 'Data pemulihan telah digabungkan.';
}

// Path: sourceSetup
class _Translations$sourceSetup$ms extends Translations$sourceSetup$en {
	_Translations$sourceSetup$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Sijil pelayan yang disimpan';
	@override String get nfsEndpointInvalid => 'Masukkan URL NFS, contohnya nfs://nas:2049/export.';
	@override String get dlnaNone => 'Tiada pelayan DLNA ditemukan. Masukkan URL perihalan peranti secara manual.';
	@override String get dlnaServers => 'Pelayan media DLNA';
	@override String get dlnaUnavailable => 'Penemuan DLNA tidak tersedia pada rangkaian ini. Masukkan URL perihalan peranti secara manual.';
	@override String get dlnaSearching => 'Mencari pelayan DLNA pada rangkaian setempat';
	@override String get networkSearching => 'Mencari pada rangkaian setempat…';
	@override String get dlnaDiscover => 'Temukan pelayan DLNA';
	@override String get dlnaHelp => 'Penemuan bergantung pada multisiar rangkaian setempat. Jika tiada pelayan muncul, masukkan URL perihalan perantinya di atas.';
	@override String get dlnaRoot => 'ID objek DLNA; biarkan kosong untuk menggunakan akar peranti.';
	@override String get passwordOrKey => 'Masukkan kata laluan atau tambah kunci peribadi di bawah.';
	@override String get sshFingerprint => 'Cap jari SHA256 kunci hos SSH';
	@override String get sshFingerprintHelp => 'Sahkan dengan pentadbir pelayan. Pada pelayan, jalankan ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub dan gunakan nilai SHA256-nya.';
	@override String get sshFingerprintKeep => 'Biarkan kosong untuk mengekalkan cap jari yang ditetapkan sekarang, atau masukkan cap jari pelayan yang baharu.';
	@override String get sshAuthentication => 'Pengesahan SSH dengan kunci awam';
	@override String get sshAuthenticationHelp => 'Pilihan; pengesahan dengan kata laluan juga disokong.';
	@override String get privateKey => 'Kunci peribadi (format PEM atau OpenSSH)';
	@override String get privateKeyPassphrase => 'Frasa laluan kunci peribadi';
	@override String get nfsMountPort => 'Port TCP perkhidmatan lekap NFS';
	@override String get nfsMountPortHelp => 'Lalai: 20048';
	@override String get nfsUserId => 'ID pengguna NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Lalai: 1000. Gunakan ID yang dibenarkan oleh perkongsian NFS pada NAS.';
	@override String get nfsGroupId => 'ID kumpulan NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Lalai: 1000. Gunakan ID kumpulan yang dibenarkan oleh perkongsian NFS pada NAS.';
	@override String get nfsEncryption => 'Wajibkan NFS disulitkan (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Wajibkan TLS 1.3 untuk NFS dan perkhidmatan lekap. Jika NAS tidak menyokongnya, sambungan ditolak.';
	@override String get nfsTrustCertificate => 'CA NFS tersuai atau sijil pelayan (PEM, pilihan)';
	@override String get nfsTrustHelp => 'Biarkan kosong untuk sijil yang dipercayai oleh peranti ini. Jika perlu, tambah sijil CA persendirian atau sijil pelayan yang ditandatangani sendiri; namanya mesti sepadan dengan hos dalam URL NFS.';
	@override String get nfsTrustInvalid => 'Gunakan sijil CA atau pelayan dalam format PEM. Jangan sertakan kunci peribadi.';
	@override String get addTrustCertificate => 'Tambah sijil kepercayaan tersuai';
	@override String get replaceTrustCertificate => 'Gantikan sijil tersuai yang disimpan';
	@override String get nfsTlsHelp => 'RPC-with-TLS menggunakan port NFS dan perkhidmatan lekap yang biasa serta memerlukan sokongan RFC 9289 pada NAS. TLS 1.3 diwajibkan. Nama hos atau IP mesti sepadan dengan sijil. AUTH_SYS UID/GID masih terpakai dalam saluran yang disulitkan.';
	@override String get clientCertificate => 'Sijil klien (pilihan)';
	@override String get clientCertificateHelp => 'Membolehkan NAS mengesahkan klien ini; ID AUTH_SYS masih bergantung pada dasar perkongsian NFS pada NAS.';
	@override String get savedIdentity => 'Identiti klien yang disimpan akan digunakan.';
	@override String get replaceIdentity => 'Gantikan identiti klien yang disimpan';
	@override String get chooseIdentity => 'Pilih identiti klien PKCS#12';
	@override String get identityPassphrase => 'Frasa laluan identiti klien';
	@override String get identityPassphraseHelp => 'Biarkan kosong jika fail tiada frasa laluan.';
	@override String get removeIdentity => 'Alih keluar sebarang identiti klien yang disimpan';
	@override String get identityStorageHelp => 'Identiti klien disimpan dalam stor bukti kelayakan sumber yang disulitkan. Biarkan bahagian ini tidak berubah untuk mengekalkan identiti yang disimpan.';
	@override String get nfsLimitations => 'NFSv3 baca sahaja melalui TCP. Tanpa RPC-with-TLS, trafik NFS tidak disulitkan. NAS mesti membenarkan ID AUTH_SYS yang dipilih dan port klien tanpa keistimewaan (sering dipanggil pilihan eksport “insecure”). NFSv4 dan UDP tidak disokong.';
	@override String get nfsSetupHelp => 'Bantuan persediaan NFS';
	@override String get nfsSetupHint => 'Semak tetapan ini jika sambungan tidak dapat dibuka.';
	@override String get nfsSetupDetails => 'Gunakan perkongsian NFSv3 melalui TCP. Jika penyulitan diwajibkan, perkhidmatan NFS dan lekap mesti kedua-duanya menyokong RPC-with-TLS. Biarkan sijil tersuai kosong untuk sijil pelayan yang dipercayai oleh peranti ini, atau tambah sijil CA NAS atau sijil yang ditandatangani sendiri. Nama dalam sijil mesti sepadan dengan hos titik akhir. Jika NAS memerlukan pengesahan TLS dua hala, tambah identiti klien PKCS#12-nya. Akhir sekali, pastikan perkongsian membenarkan AUTH_SYS UID/GID yang dikonfigurasi serta dasar port klien.';
	@override String get ftpHelp => 'FTP menggunakan mod pasif. Gunakan ftp:// untuk FTP tanpa penyulitan, ftpes:// untuk TLS eksplisit, atau ftps:// untuk TLS (implisit pada port 990; eksplisit pada port lain).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Carian sari kata pilihan untuk video kendiri.';
	@override String get apiKey => 'Kunci API';
	@override String get optionalUsername => 'Nama pengguna akaun (pilihan)';
	@override String get optionalPassword => 'Kata laluan akaun (pilihan)';
	@override String get subtitlePrivacy => 'Dapatkan kunci API daripada opensubtitles.com. Carian menghantar tajuk video dan ID IMDb/TMDB yang tersedia, bukan fail video sama sekali. Kunci dan bukti kelayakan akaun pilihan disulitkan bersama sumber ini.';
	@override String get automaticMetadata => 'Metadata video dalam talian automatik';
	@override String get metadataPrivacy => 'Hanya menghantar tajuk/tahun daripada nama fail dan nombor episod atau ID NFO; tidak sekali-kali menghantar media atau bukti kelayakan. Medan NFO kekal sebagai rujukan utama.';
	@override String get nfsEncryptionFailure => 'Untuk NFS disulitkan, semak sokongan RFC 9289 dan TLS 1.3 pada kedua-dua perkhidmatan NAS, nama sijil dan UID/GID perkongsian. PlezyNG tidak akan mencuba semula sambungan ini tanpa penyulitan.';
	@override String get sourceConnecting => 'Menyambung ke sumber';
	@override String get metadataSearchPrivacy => 'Carian tajuk ini dihantar ke Trakt. Carian menghantar tajuk yang anda masukkan, bukan video atau bukti kelayakan sumber.';
	@override String get chooseMatch => 'Pilih padanan';
	@override String get metadataMatchHelp => 'Semak tajuk dan tahun sebelum memilih. Trakt menerima tajuk carian; video kekal pada sumbernya.';
	@override String get metadataNoMatches => 'Tiada padanan tajuk dalam talian ditemukan. Cuba tajuk lain.';
	@override String get metadataSearch => 'Cari metadata dalam talian';
	@override String get metadataLoading => 'Mencari butiran filem dan rancangan TV dalam talian…';
	@override String get metadataFromTrakt => 'Metadata dalam talian daripada Trakt';
	@override String get metadataNoAutomaticMatch => 'Tiada padanan tajuk automatik ditemukan. Cari tajuk untuk memilih padanan.';
	@override String get metadataFailed => 'Metadata dalam talian tidak dapat dimuatkan. Main balik dan butiran setempat masih tersedia.';
	@override String get videoDetailsLoading => 'Memuatkan butiran video';
	@override String get subtitleKeyRequired => 'Kunci API OpenSubtitles diperlukan';
	@override String get subtitleKeyHelp => 'Edit sumber fail ini dan tambah kunci API OpenSubtitles dalam tetapan sari kata pilihannya.';
	@override String get subtitleSearchFailed => 'Carian sari kata gagal. Semak kunci API, sambungan dan akses kepada perkhidmatan.';
	@override String get subtitleApplyFailed => 'Sari kata ini tidak dapat dimuat turun atau digunakan. Semak sambungan dan cuba hasil lain.';
	@override String get subtitleSearch => 'Cari di OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'Carian menggunakan tajuk dan ID IMDb/TMDB yang tersedia. Fail video kekal pada sumbernya. Semak bahasa, penanda sari kata paksa atau untuk orang kurang upaya pendengaran, serta penilaian sebelum memilih.';
	@override String get movieOrShow => 'Filem atau rancangan TV';
	@override String get subtitleTitleHint => 'Masukkan tajuk untuk memperincikan hasil';
	@override String get subtitleLanguage => 'Bahasa sari kata';
	@override String get subtitleSearching => 'Mencari di OpenSubtitles';
	@override String get subtitleNoMatches => 'Tiada sari kata sepadan ditemukan. Cuba tajuk atau bahasa lain.';
	@override String get downloadSubtitle => 'Muat turun sari kata';
	@override String get subtitle => 'Sari kata';
	@override String get nfsTlsRequired => 'RPC-with-TLS diperlukan';
	@override String get nfsUnencrypted => 'NFS tidak disulitkan';
	@override String get tlsEncrypted => 'Disulitkan dengan TLS';
	@override String get ftpPlain => 'FTP tanpa penyulitan';
	@override String get sshPinned => 'SSH disulitkan · kunci hos ditetapkan';
	@override String get smbEncrypted => 'Penyulitan SMB3 dihidupkan';
	@override String get smbUnencrypted => 'Penyulitan SMB3 dimatikan';
	@override String get httpUnencrypted => 'HTTP tanpa penyulitan pengangkutan';
	@override String get checkEndpointSecurity => 'Semak keselamatan titik akhir';
	@override String fieldRequired({required Object label}) => '${label} diperlukan.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Masukkan ${label} antara ${min} dengan ${max}.';
	@override String replaceFile({required Object name}) => 'Gantikan ${name}';
	@override String selectedIdentity({required Object name}) => 'Identiti klien yang dipilih: ${name}';
	@override String subtitleRating({required Object rating}) => 'Penilaian ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Memuat turun sari kata: ${title}';
	@override String get sharedEntryPair => 'Berpasangan item ini';
	@override String get sharedEntryPairHelp => 'Masukkan ID yang sama untuk item ini pada setiap peranti. Gunakan pengenalpastian kongsi yang stabil atau buat satu dan salin ke item yang sepadan. Kemajuan hanya berpasangan apabila jenis fail edisi, saiz, dan pesanan sesuai. Blank menghapuskan peta ini.';
	@override String get sharedEntryId => 'Pengenalan item ID';
	@override String get generateSharedEntryId => 'Mencipta item yang dikongsi ID';
	@override String get sharedLibraryId => 'ID perpustakaan berkongsi (pilihan)';
	@override String get sharedLibraryHelp => 'Gunakan ID yang sama pada peranti yang membuka perpustakaan yang sama. ID awam ini membantu membawa kemajuan bacaan dan nota melalui sambungan sumber yang berbeza; ia bukan kata laluan. Apabila pembekal menggunakan ID item yang berlainan, pasangan item tersebut daripada skrin terperinci mereka.';
	@override String get sharedLibraryInvalid => 'Gunakan 8-100 huruf, nombor, titik, subscores atau hyphens.';
	@override String get generateSharedLibraryId => 'Mencipta ID perpustakaan yang dikongsi';
	@override String get nfsReadAhead => 'Permintaan bacaan NFS';
	@override String get nfsReadAheadHelp => 'Lebih banyak bacaan serentak boleh meningkatkan pencapaian pada NAS atau rangkaian yang cepat. gunakan 1 jika pelayan mengehadkan permintaan yang sama.';
	@override String get nfsReadTest => 'Mengukur prestasi bacaan NFS';
	@override String get nfsReadTestHelp => 'Membaca sehingga 64 MiB daripada fail terbesar untuk mengukur sambungan NAS ini.';
	@override String get nfsQualificationResult => 'NFS baca pengukuran';
	@override String get nfsReadBytes => 'Data bacaan';
	@override String get nfsReadSpeed => 'Kelajuan yang diukur';
	@override String get nfsReadRequests => 'Membaca Permintaan';
	@override String get sharedEntryConflict => 'ID item yang dikongsi ini telah digabungkan dengan item lain dalam perpustakaan ini. pilih ID yang berbeza.';
}

// Path: comics
class _Translations$comics$ms extends Translations$comics$en {
	_Translations$comics$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Muatkan mengikut tinggi';
	@override String get readingMode => 'Mod bacaan';
	@override String get paged => 'Halaman';
	@override String get webtoon => 'Tatal berterusan';
	@override String get coverAlone => 'Paparkan kulit buku secara berasingan';
	@override String get splitWide => 'Bahagikan halaman lebar';
	@override String get splitWideHelp => 'Paparkan setiap separuh secara berasingan mengikut urutan bacaan. Paparan dua halaman bersebelahan dijeda semasa pilihan ini aktif.';
	@override String get thumbnails => 'Lakaran kecil halaman';
	@override String get controlsHelp => 'Leret untuk menyelak halaman. Ketik dua kali untuk menukar padanan. Dalam tatal berterusan, leret menegak atau gunakan Page Up dan Page Down.';
	@override String get savedForComic => 'Tetapan paparan diingati untuk komik ini dalam profil ini.';
	@override String get readLists => 'Senarai bacaan';
	@override String get collections => 'Koleksi';
}

// Path: games
class _Translations$games$ms extends Translations$games$en {
	_Translations$games$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Games';
	@override String get enable => 'Show Games for this profile';
	@override String get subtitle => 'Your games, from your computers.';
	@override String get computers => 'Your computers';
	@override String get nearby => 'Nearby computers';
	@override String get findComputers => 'Find computers';
	@override String get addComputer => 'Add computer';
	@override String get scanHint => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.';
	@override String get empty => 'Add your gaming computer to get started.';
	@override String get noNearby => 'No computers found on this network. You can enter an address manually.';
	@override String get name => 'Computer name';
	@override String get address => 'IP address or hostname';
	@override String get port => 'Service port';
	@override String get protocol => 'Streaming service';
	@override String get moonlight => 'Sunshine / Moonlight';
	@override String get steam => 'Steam Remote Play';
	@override String get save => 'Save computer';
	@override String get invalidAddress => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.';
	@override String get pair => 'Connect computer';
	@override String get pairTitle => 'Approve this device';
	@override String get pairInstructions => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.';
	@override String get pairHelp => 'Connect this computer again to approve or renew pairing.';
	@override String get openPairingPage => 'Open Sunshine PIN page';
	@override String get qrHelp => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.';
	@override String get refreshGames => 'Refresh games';
	@override String get play => 'Play';
	@override String get favorites => 'Favorites';
	@override String get allGames => 'All games';
	@override String get search => 'Find a game';
	@override String get noMatches => 'No games match this search.';
	@override String get favorite => 'Save favorite';
	@override String get unfavorite => 'Remove favorite';
	@override String get forget => 'Forget computer';
	@override String get forgetDescription => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.';
	@override String get unavailable => 'The connection could not complete. Check that the computer is awake and paired, then try again.';
	@override String get timeout => 'Connection timed out. Check the computer, pairing code and network before trying again.';
	@override String get libraryHint => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.';
	@override String get touchControls => 'On-screen controller';
	@override String get touchDescription => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.';
	@override String get touchSetup => 'On-screen controls';
	@override String get touchSetupHint => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.';
	@override String get addGame => 'Add game shortcut';
	@override String get gameName => 'Game name';
	@override String get gameId => 'Host application ID';
	@override String get invalidGame => 'Enter a game name and a positive numeric host application ID.';
	@override String get wake => 'Wake computer';
	@override String get wakeSent => 'Wake request sent. The computer must support Wake-on-LAN on this network.';
	@override String get mac => 'MAC address (optional)';
	@override String get help => 'Games help';
	@override String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.';
	@override String get steamLibrary => 'Steam library';
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
}

// Path: deepLinks
class _Translations$deepLinks$ms extends Translations$deepLinks$en {
	_Translations$deepLinks$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Link Plezy ini tidak sah.';
	@override String profileNotFound({required Object profile}) => 'Tiada profil yang sepadan dengan "${profile}".';
	@override String get serverUnavailable => 'Saya tidak boleh mencapai pelayan untuk pautan ini.';
	@override String get notFound => 'Saya tidak boleh menemui tajuk ini di perpustakaan anda.';
	@override String get unsupportedItem => 'Link ini tidak boleh dimainkan.';
	@override String get noLiveTv => 'Tiada pelayan TV langsung boleh didapati untuk pautan ini.';
	@override String channelNotFound({required Object channel}) => 'Saya tidak boleh menemui saluran "${channel}".';
	@override String get showLink => 'Tunjukkan link';
	@override String get showProfileLink => 'Tunjukkan profil link';
	@override String get dialogTitle => 'Link yang';
	@override String get showHint => 'Membuka pautan ini memainkan episod seterusnya.Tambah &mode=shuffle untuk bermain persembahan pada shuffle.';
	@override String get movieHint => 'Membuka pautan ini memainkan filem.';
	@override String get episodeHint => 'Membuka pautan ini memainkan episod ini.';
	@override String get profileHint => 'Membuka pautan ini beralih kepada profil ini.';
	@override String openAsProfile({required Object name}) => 'Buka sebagai ${name}';
	@override String get copy => 'Salinan';
	@override String get copied => 'Link yang disalin';
}

// Path: householdSetup
class _Translations$householdSetup$ms extends Translations$householdSetup$en {
	_Translations$householdSetup$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Persediaan rumah tangga';
}

// Path: issueReport
class _Translations$issueReport$ms extends Translations$issueReport$en {
	_Translations$issueReport$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Laporkan masalah';
	@override String get instructions => 'Imbas kod QR untuk membuka draf GitHub yang telah diisi. Semak dan hantar apabila anda bersedia.';
	@override String get privacy => 'Draf mengandungi versi aplikasi, platform dan bilangan sambungan. Alamat pelayan, nama akaun dan profil, tajuk media serta laluan fail tidak disertakan.';
	@override String get logPrivacy => 'Log adalah pilihan. Semak sebelum memuat naik. ID log ditambahkan pada draf yang mungkin terbuka kepada umum.';
	@override String get openDraft => 'Buka draf GitHub';
}

// Path: appIcon.names
class _Translations$appIcon$names$ms extends Translations$appIcon$names$en {
	_Translations$appIcon$names$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'tengah malam';
	@override String get ember => 'orang';
	@override String get paper => 'kertas';
	@override String get oled => 'OLED';
	@override String get line => 'garis';
	@override String get ocean => 'Lautan';
	@override String get ultraviolet => 'Ultrasifikasi';
	@override String get matcha => 'Perlawanan';
	@override String get sunset => 'Matahari terbenam';
	@override String get gold => 'emas';
	@override String get titanium => 'Tag: titanium';
	@override String get glass => 'kaca';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Perbezaan';
	@override String get pixel => 'Piksel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Sticker yang';
	@override String get ticket => 'tiket';
	@override String get pop => 'Pop yang';
	@override String get strata => 'Jalan';
	@override String get facet => 'Wajah';
	@override String get tilde => 'Tag : Tilde';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$ms extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Critics';
	@override String get audience => 'Audience';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes critics';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes audience';
	@override String get metacritic => 'Metacritic';
	@override String get letterboxd => 'Letterboxd';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$ms extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get movie => 'filem';
	@override String get show => 'Pameran';
	@override String get season => 'Musim';
	@override String get episode => 'Episod';
	@override String get artist => 'Artis';
	@override String get album => 'Album';
	@override String get track => 'Laluan';
	@override String get collection => 'Koleksi';
	@override String get playlist => 'Senarai Main';
	@override String get clip => 'Klip';
	@override String get photo => 'Gambar';
	@override String get folder => 'Folder dalam';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$ms extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Membuka cadangan dan item daripada sumber penemuan yang berkaitan.';
	@override String get libraries => 'Buka perpustakaan media yang disambungkan.';
	@override String get liveTv => 'Buka TV secara langsung apabila pelayan menyediakan ia; jika tidak, permulaan jatuh kembali ke Home.';
	@override String get search => 'Pencarian media terbuka.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$ms extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get bg => 'latar belakang';
	@override String get surface => 'permukaan';
	@override String get outline => 'outline dalam';
	@override String get text => 'teks';
	@override String get textMuted => 'teks sekunder';
	@override String get accent => 'Tumpuan';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$ms extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Teks dalam latar belakang';
	@override String get textOnSurface => 'Teks di permukaan';
	@override String get textMutedOnBg => 'Teks sekunder pada latar belakang';
	@override String get textMutedOnSurface => 'Perkataan sekunder di permukaan';
	@override String get accentOnBg => 'Fokus pada latar belakang';
	@override String get accentOnSurface => 'Fokus pada permukaan';
	@override String get labelOnAccent => 'Button label pada aksen';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$ms extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Bermain / beristirahat';
	@override String get volumeUp => 'Volume ke atas';
	@override String get volumeDown => 'Volume turun';
	@override String seekForward({required Object seconds}) => 'Mencari ke hadapan (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Mencari Kembali (${seconds}s)';
	@override String get fullscreenToggle => 'Menyertai Fullscreen';
	@override String get muteToggle => 'Bersama Muta';
	@override String get subtitleToggle => 'Menggabungkan Subtitle';
	@override String get audioTrackNext => 'Seterusnya Audio Track';
	@override String get subtitleTrackNext => 'Seterusnya Subtitle Track';
	@override String get chapterNext => 'Bab seterusnya';
	@override String get chapterPrevious => 'Bab sebelumnya';
	@override String get episodeNext => 'Episod berikutnya';
	@override String get episodePrevious => 'Episod Sebelumnya';
	@override String get speedIncrease => 'Meningkatkan kelajuan';
	@override String get speedDecrease => 'Mengurangkan kelajuan';
	@override String get speedReset => 'Kembali ke kelajuan';
	@override String get zoomIn => 'Zoom dalam';
	@override String get zoomOut => 'Zoom keluar';
	@override String get zoomReset => 'Mengubah Zoom';
	@override String get subSeekNext => 'Cari untuk Subtitle berikutnya';
	@override String get subSeekPrev => 'Mencari Subtitle Sebelumnya';
	@override String get subtitleDelayIncrease => 'Penangguhan Subtitle';
	@override String get subtitleDelayDecrease => 'Subtitle yang maju';
	@override String get shaderToggle => 'Bersama Shaders';
	@override String get skipMarker => 'Pinjaman / Pinjaman';
	@override String get screenshot => 'Mengambil screenshot';
	@override String get framePrevious => 'Frame yang lepas';
	@override String get frameNext => 'Frame yang seterusnya';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$ms extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Memerlukan Android 8.0 atau lebih baru';
	@override String get iosVersion => 'Memerlukan iOS 15.0 atau lebih baru';
	@override String get permissionDisabled => 'Gambar-gambar dalam disekat. ia boleh didayakan dalam tetapan sistem.';
	@override String get notSupported => 'Peranti tidak menyokong mod imej dalam imej';
	@override String get voSwitchFailed => 'gagal untuk menukar output video untuk imej-dalam-gambar';
	@override String get failed => 'Gambar-gambar dalam gagal bermula';
	@override String get prepareFailed => 'Gambar-gambar dalam tidak boleh disediakan';
	@override String unknown({required Object error}) => 'Kesilapan yang berlaku: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$ms extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get no => 'Simpan huruf, warna, saiz, dan kedudukan yang ditulis dalam fail subtitle.';
	@override String get yes => 'Membolehkan tetapan gaya subtitle pemain untuk menyesuaikan subtitle ASS.';
	@override String get scale => 'Gunakan gaya pemain dan skala saiz tertanam untuk memenuhi dimensi video.';
	@override String get force => 'Menggantikan gaya ASS yang tertanam dengan gaya subtitle pemain.';
	@override String get strip => 'Menghilangkan format ASS terbina dalam dan membuat subtitle teks dengan jelas.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$ms extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render pada resolusi permukaan paparan penuh untuk hasil yang paling tajam.';
	@override String get video => 'Render menggunakan resolusi video sebagai rujukan, yang boleh mengurangkan kerja pada paparan resolusi tinggi.';
	@override String get threeQuarter => 'Rendah pada 75% daripada resolusi permukaan paparan untuk penjimatan prestasi yang sederhana.';
	@override String get half => 'Rendah pada 50% daripada resolusi permukaan paparan untuk mengurangkan kerja, dengan tepi yang lebih lembut.';
	@override String get third => 'Render pada satu pertiga daripada resolusi permukaan paparan untuk mengurangkan kerja, dengan tepi yang lebih lembut.';
	@override String get quarter => 'Render pada satu perempat daripada resolusi permukaan paparan untuk mengurangkan kerja, dengan hasil yang paling lembut.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$ms extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio dan Subtitle';
	@override String get libraryDisplay => 'Pustaka';
	@override String get personalMedia => 'Media Peribadi';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$ms extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get none => 'dipilih secara manual';
	@override String get noneDescription => 'Jangan sesekali menukar subtitle kepada diri sendiri.';
	@override String get defaultMode => 'Ikuti bendera trek';
	@override String get defaultModeDescription => 'Gunakan bendera lalai dan paksa yang disimpan pada setiap trek subtitle.';
	@override String get always => 'Selalu dibenarkan';
	@override String get alwaysDescription => 'Tukar pada trek subtitle dalam bahasa kegemaran bila-bila masa yang ada.';
	@override String get onlyForced => 'Hanya subtitle paksa sahaja';
	@override String get onlyForcedDescription => 'Mengisi hanya trek yang ditandakan sebagai paksa.';
	@override String get smart => 'Diterbitkan dengan audio asing';
	@override String get smartDescription => 'Tukar subtitle hanya apabila audio dalam bahasa lain.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$ms extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Sebaik-baik subtitle bukan SDH';
	@override String get preferSdh => 'Lebih suka subtitle SDH';
	@override String get onlySdh => 'Hanya subtitle SDH sahaja';
	@override String get onlyNonSdh => 'Hanya subtitle bukan SDH';
	@override String get preferNonSdhDescription => 'Lebih suka subtitle standard apabila kedua-dua versi standard dan SDH tersedia.';
	@override String get preferSdhDescription => 'Saya lebih suka subtitle SDH apabila tersedia, tetapi membenarkan subtitle standard sebagai fallback.';
	@override String get onlySdhDescription => 'Gunakan subtitle SDH sahaja; jangan jatuh kembali kepada subtitle standard.';
	@override String get onlyNonSdhDescription => 'Gunakan subtitle standard sahaja; mengecualikan subtitle SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$ms extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Lebih suka subtitle yang tidak dikenakan';
	@override String get preferForced => 'Lebih suka subtitle';
	@override String get onlyForced => 'Hanya subtitle paksa sahaja';
	@override String get onlyNonForced => 'Hanya subtitle yang tidak dipaksakan';
	@override String get preferNonForcedDescription => 'Lebih suka subtitle biasa, tetapi membenarkan trek paksa sebagai jatuh.';
	@override String get preferForcedDescription => 'Lebih suka trek paksa apabila tersedia, tetapi membenarkan subtitle biasa sebagai jatuh balik.';
	@override String get onlyForcedDescription => 'Gunakan hanya trek yang ditandai sebagai paksa.';
	@override String get onlyNonForcedDescription => 'Mengecualikan laluan yang ditandakan sebagai paksa.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$ms extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get none => 'Tidak pernah';
	@override String get moviesAndShows => 'Filem dan rancangan televisyen';
	@override String get movies => 'Filem sahaja';
	@override String get shows => 'TV hanya menunjukkan';
	@override String get noneDescription => 'Jangan tunjukkan tanda-tanda yang dipantau.';
	@override String get moviesAndShowsDescription => 'Tunjukkan tanda-tanda yang dilihat untuk filem dan rancangan televisyen.';
	@override String get moviesDescription => 'Tunjukkan tanda-tanda yang dilihat untuk filem sahaja.';
	@override String get showsDescription => 'Tunjukkan tanda-tanda yang dilihat untuk persembahan TV sahaja.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$ms extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Pengguna dan kritikus';
	@override String get usersOnly => 'Pengguna sahaja';
	@override String get criticsOnly => 'Hanya kritikan sahaja';
	@override String get nobody => 'tersembunyi';
	@override String get usersAndCriticsDescription => 'Tunjukkan kedua-dua penilaian pengguna dan penarafan kritikal.';
	@override String get usersOnlyDescription => 'Tunjukkan penilaian dan ulasan yang dikemukakan oleh pengguna.';
	@override String get criticsOnlyDescription => 'Tunjukkan penilaian kritikal dan ulasan.';
	@override String get nobodyDescription => 'menyembunyikan penilaian dan ulasan.';
}

// Path: discover.findNext
class _Translations$discover$findNext$ms extends Translations$discover$findNext$en {
	_Translations$discover$findNext$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Temui pilihan anda yang seterusnya';
	@override String get open => 'Temui pilihan anda yang seterusnya';
	@override String get anyTime => 'Tanpa had masa';
	@override String get timeAvailable => 'Berapa banyak masa yang anda ada?';
	@override String get filters => 'Pilih yang sesuai untuk saat ini';
	@override String get watch => 'Tonton';
	@override String get listen => 'Dengar';
	@override String get read => 'Baca';
	@override String finishable({required Object duration}) => 'Boleh selesai dalam ${duration}';
	@override String aboutDuration({required Object duration}) => 'Kira-kira ${duration}';
	@override String nextUnit({required Object duration}) => 'Bab seterusnya · ${duration}';
	@override String totalDuration({required Object duration}) => 'Jumlah masa: ${duration}';
	@override String get timingVaries => 'Tempoh mungkin berbeza';
	@override String get notNow => 'Bukan sekarang';
	@override String get swipeHint => 'Leret imej muka depan ke arah anak panah atau gunakan butang di bawah.';
	@override String get saved => 'Cadangan yang disimpan';
	@override String savedCount({required Object count}) => 'Cadangan yang disimpan · ${count}';
	@override String get undo => 'Buat asal';
	@override String get details => 'Butiran';
	@override String get noPicks => 'Belum ada pilihan';
	@override String get noPicksHint => 'Sambungkan pustaka atau tambah sumber media untuk bermula.';
	@override String get noMatches => 'Tiada yang sesuai untuk saat ini';
	@override String get noMatchesHint => 'Cuba jenis media lain atau luangkan lebih banyak masa.';
	@override String get allDone => 'Anda telah melihat semua cadangan';
	@override String get allDoneHint => 'Mulakan himpunan baharu untuk melihat pilihan ini semula.';
	@override String get refresh => 'Cari himpunan lain';
	@override String sourceReason({required Object source}) => 'Daripada ${source}';
	@override String libraryReason({required Object library}) => 'Daripada ${library}';
	@override String get ownedReason => 'Daripada pustaka anda';
	@override String get liveNow => 'Sedang disiarkan';
	@override String get watchLive => 'Tonton siaran langsung';
	@override String get filterAnything => 'Apa-apa sahaja';
	@override String get filterWatch => 'Tonton';
	@override String get filterListen => 'Dengar';
	@override String get filterRead => 'Baca';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Gunakan';
	@override String get openFailed => 'Pilihan ini tidak lagi tersedia. Muat semula untuk menyemak lagi.';
	@override String get changeFailed => 'Perubahan ini tidak dapat disimpan. Cuba lagi.';
	@override String get savedLimit => 'Senarai cadangan yang disimpan sudah penuh. Alih keluar satu cadangan untuk menyimpan yang lain.';
	@override String get chooseHint => 'Buka tajuk, simpan untuk kemudian atau langkau.';
	@override String get howItWorks => 'Cara penggunaan';
	@override String get notNowHelp => 'Langkau tajuk ini buat masa ini. Ia kekal dalam pustaka anda.';
	@override String get saveHelp => 'Simpan dalam pilihan tersimpan profil ini pada peranti ini. Menyimpan tidak memuat turun tajuk.';
	@override String get openHelp => 'Pilih kulit untuk melihat butiran. Gunakan tindakan utama untuk memainkan, membaca atau membuka tajuk.';
	@override String get controlsHelp => 'Papan kekunci atau alat kawalan jauh: fokus pada butang, kemudian tekan Enter atau Pilih. Buat asal memulihkan pilihan terakhir anda.';
	@override String get artworkLoading => 'Memuatkan imej…';
	@override String get artworkUnavailable => 'Imej tidak tersedia';
	@override String get savedFeedback => 'Ditambah ke pilihan tersimpan';
	@override String get skippedFeedback => 'Dilangkau buat masa ini';
	@override String get releaseToConfirm => 'Lepaskan untuk mengesahkan';
	@override String get remoteHint => 'Kulit dalam fokus: ← / → pilih · Pilih: butiran · ↑ / ↓ alih fokus';
}

// Path: discover.person
class _Translations$discover$person$ms extends Translations$discover$person$en {
	_Translations$discover$person$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get born => 'dilahirkan';
	@override String get died => 'Kematian';
	@override String get birthplace => 'tempat kelahiran';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (umur ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (usia ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$ms extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Rekomendasi';
	@override String get browse => 'Semak imbas';
	@override String get collections => 'Koleksi';
	@override String get playlists => 'Senarai ulangmain';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$ms extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kumpulan';
	@override String get all => 'Semua';
	@override String get movies => 'Filem-filem';
	@override String get shows => 'Rancangan TV';
	@override String get seasons => 'Musim';
	@override String get episodes => 'Peristiwa';
	@override String get artists => 'Artis';
	@override String get albums => 'Album';
	@override String get tracks => 'Laluan';
	@override String get folders => 'Folder-folder';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$ms extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Jenis';
	@override String get year => 'Tahun yang';
	@override String get contentRating => 'Penilaian Kandungan';
	@override String get tag => 'Tag';
	@override String get unwatched => 'tidak diperhatikan';
	@override String get unplayed => 'Tidak Bermain';
	@override String get favorites => 'Kegemaran';
	@override String get filePath => 'Fail laluan';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$ms extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tajuk';
	@override String get dateAdded => 'Tarikh ditambah';
	@override String get releaseDate => 'Tarikh pelepasan';
	@override String get rating => 'Penilaian';
	@override String get communityRating => 'Penilaian komuniti';
	@override String get criticRating => 'Penilaian kritikal';
	@override String get userRating => 'Penilaian pengguna';
	@override String get datePlayed => 'Tarikh dimainkan';
	@override String get playCount => 'Bermain dengan Count';
	@override String get productionYear => 'Tahun Pengeluaran';
	@override String get runtime => 'Perbincangan Runtime';
	@override String get officialRating => 'Penilaian rasmi';
	@override String get premiereDate => 'Tarikh Perdana';
	@override String get startDate => 'Tarikh bermula';
	@override String get airTime => 'Waktu udara';
	@override String get studio => 'Pengajian';
	@override String get random => 'Peristiwa';
	@override String get dateShared => 'Tarikh berkongsi';
	@override String get latestEpisodeAirDate => 'Perbincangan:Episod Terkini Air Date';
	@override String get lastEpisodeDateAdded => 'Tarikh akhir episode ditambah';
	@override String get dateDownloaded => 'Tarikh Dimuat turun';
	@override String get size => 'Ukuran';
	@override String get library => 'Pustaka';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$ms extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get include => 'termasuk';
	@override String get exclude => 'Pengecualian';
	@override String get any => 'mana-mana';
	@override String get yes => 'Ya Ya';
	@override String get no => 'Tidak';
	@override String not({required Object value}) => 'Tidak boleh ${value}';
	@override String valueCount({required Object count}) => '${count} telah dipilih';
	@override String valueCountExcluded({required Object count}) => '${count} dikecualikan';
	@override String get searchValues => 'nilai pencarian';
	@override String get noValues => 'Tiada nilai';
	@override String get matchContains => 'mengandungi';
	@override String get matchNotContains => 'Tidak mengandungi';
	@override String get matchIs => 'Adalah';
	@override String get matchIsNot => 'Tidak boleh';
	@override String get matchBeginsWith => 'Bermula dengan';
	@override String get matchEndsWith => 'Berakhir dengan';
	@override String get textHint => 'jenis untuk match';
	@override String get from => 'Daripada';
	@override String get to => 'kepada';
	@override String range({required Object from, required Object to}) => '${from} kepada ${to}';
	@override String atLeast({required Object value}) => '${value} dan ke atas';
	@override String atMost({required Object value}) => 'sehingga ${value}';
	@override String dateLastDays({required Object count}) => '${count} hari yang lalu';
	@override String get dateLastYear => 'Tahun lepas';
	@override String dateOlderThanDays({required Object count}) => 'Lebih daripada ${count} hari';
	@override String get dateOlderThanYear => 'lebih tua daripada 1 tahun';
}

// Path: libraries.selection
class _Translations$libraries$selection$ms extends Translations$libraries$selection$en {
	_Translations$libraries$selection$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Pilih item';
	@override String selectedCount({required Object count}) => '${count} telah dipilih';
	@override String get actions => 'Tindakan Seleksi';
	@override String get confirmDescendants => 'Ini mengubah semua episod dalam persembahan dan musim yang dipilih.';
	@override String get confirmUnwatched => 'Ini juga membersihkan kemajuan playback untuk item yang dipilih.';
	@override String confirmCount({required Object count}) => 'Jumlah item yang dipilih : ${count}.';
	@override String completed({required Object count}) => 'Item yang dikemaskini: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Diperbaharui ${succeeded}; gagal ${failed}. item yang gagal kekal dipilih.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$ms extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Pengurusan Pelancongan Pelancongan';
	@override String get manageDescription => 'Pilih dan mengatur senarai daripada akaun anda MDBList';
	@override String get description => 'Pilih senarai filem dan televisyen awam daripada akaun MDBList. mencipta atau menyalin senarai di MDBList, kemudian memperbaharui.';
	@override String get selected => 'Pelabuhan yang dipilih';
	@override String get available => 'Senarai akaun yang tersedia';
	@override String get noLists => 'Tiada senarai filem atau televisyen awam dikembalikan. mencipta atau menyalin senarai di MDBList, kemudian memperbaharui.';
	@override String get displayName => 'Nama Pameran Shelf';
	@override String get nameHint => 'Tinggalkan kosong untuk menggunakan nama senarai sumber.';
	@override String get add => 'Tambah shelf';
	@override String get save => 'Menyelamatkan kerusi';
	@override String moveUp({required Object title}) => 'Pergerakan ${title} ke atas';
	@override String moveDown({required Object title}) => 'Pergerakan ${title} ke bawah';
	@override String get unavailable => 'Senarai ini tidak boleh didapati.Tarik balik atau keluarkan shell dalam tetapan.';
	@override String get rateLimited => 'MDBList permintaan had telah dicapai. sila berundur kemudian.';
	@override String get loadFailed => 'Tidak boleh mengisi rak. semak sambungan anda dan retry.';
	@override String get saveFailed => 'Saya tak boleh simpan.Sila rujuk.';
	@override String get accountChanged => 'Akaun atau profil telah berubah.Buka semula tetapan ini.';
	@override String get settingsUnreadable => 'Tab yang disimpan tidak boleh dibaca. pilih semula senarai anda untuk menggantikan tetapan ini.';
}

// Path: explore.rows
class _Translations$explore$rows$ms extends Translations$explore$rows$en {
	_Translations$explore$rows$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Pengawasan';
	@override String get recommendedMovies => 'Filem yang disyorkan';
	@override String get recommendedShows => 'Persembahan yang disyorkan';
	@override String get trendingMovies => 'filem trending';
	@override String get trendingShows => 'Rujukan Trend';
	@override String get popularMovies => 'Filem popular';
	@override String get popularShows => 'Persembahan popular';
	@override String get trendingAnime => 'Perbincangan Anime';
	@override String get suggestedAnime => 'Anime yang disyorkan';
	@override String get airingAnime => 'Anime teratas yang sedang ditayangkan';
	@override String get popularAnime => 'Anime yang paling popular';
	@override String get trending => 'Trend yang';
	@override String get upcomingMovies => 'Filem yang akan datang';
	@override String get upcomingShows => 'Persembahan yang akan datang';
}

// Path: explore.status
class _Translations$explore$status$ms extends Translations$explore$status$en {
	_Translations$explore$status$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get airing => 'udara';
	@override String get ended => 'Tamat';
	@override String get canceled => 'Pembatalan';
	@override String get upcoming => 'yang akan datang';
}

// Path: explore.badge
class _Translations$explore$badge$ms extends Translations$explore$badge$en {
	_Translations$explore$badge$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} popular';
	@override String rankAiring({required Object n}) => '#${n} pengangkutan udara';
	@override String rankRated({required Object n}) => '#${n} disenaraikan';
	@override String rankTrending({required Object n}) => 'Sohor kini #${n}';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} dalam ${season}';
	@override String watchingNow({required Object n}) => '${n} dilihat';
	@override String get available => 'Tersedia';
	@override String get partiallyAvailable => 'Sebahagian tersedia';
	@override String get availableIn4k => '4K boleh didapati';
	@override String get requested => 'Permohonan';
	@override String get pendingApproval => 'Menunggu kelulusan';
	@override String get processing => 'Pemprosesan';
	@override String get declined => 'dikecualikan';
	@override String get requestFailed => 'Permohonan gagal';
	@override String get requested4k => '4K dikehendaki';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} musim';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} dalam ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Seterusnya dalam ${duration}';
	@override String episodesShort({required Object n}) => '${n} EPS';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$ms extends Translations$explore$stats$en {
	_Translations$explore$stats$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} disenaraikan';
	@override String viewersDay({required Object n}) => '${n} dilihat hari ini';
	@override String viewersWeek({required Object n}) => '${n} menonton minggu ini';
	@override String viewersMonth({required Object n}) => '${n} menonton bulan ini';
	@override String viewersYear({required Object n}) => '${n} menonton tahun ini';
	@override String viewersAllTime({required Object n}) => '${n} penonton';
	@override String planning({required Object n}) => '${n} rancangan untuk menonton';
	@override String favorited({required Object n}) => '${n} kegemaran';
	@override String dropRate({required Object percent}) => '${percent} telah meletakkannya';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komen',
	);
	@override String votes({required Object n}) => '${n} undian';
	@override String watching({required Object n}) => '${n} menonton';
	@override String completed({required Object n}) => '${n} telah selesai';
	@override String onHold({required Object n}) => '${n} dalam pemegang';
	@override String dropped({required Object n}) => '${n} dikurangkan';
}

// Path: explore.season
class _Translations$explore$season$ms extends Translations$explore$season$en {
	_Translations$explore$season$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Musim Sejuk';
	@override String get spring => 'Musim semi';
	@override String get summer => 'Musim panas';
	@override String get fall => 'jatuh';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$ms extends Translations$explore$format$en {
	_Translations$explore$format$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get tv => 'televisyen';
	@override String get tvShort => 'Televisyen pendek';
	@override String get movie => 'filem';
	@override String get special => 'Khusus';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Muzik';
	@override String get other => 'yang lain';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$ms extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get original => 'asal';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'novel cahaya';
	@override String get novel => 'Novel';
	@override String get visualNovel => 'Kisah Visual';
	@override String get game => 'Permainan';
	@override String get webComic => 'Laman web komik';
	@override String get musicRelease => 'Muzik';
	@override String get otherMedia => 'yang lain';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$ms extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Pelakon';
	@override String get director => 'Pengarah';
	@override String get writer => 'Penulis';
	@override String get producer => 'Penerbit';
	@override String get creator => 'Pencipta';
	@override String get composer => 'Komposer';
}

// Path: explore.relation
class _Translations$explore$relation$ms extends Translations$explore$relation$en {
	_Translations$explore$relation$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Peringatan';
	@override String get sequel => 'Seterusnya';
	@override String get sideStory => 'Kisah sampingan';
	@override String get spinOff => 'Perbincangan Spin-off';
	@override String get alternativeVersion => 'Versi alternatif';
	@override String get summary => 'ringkasan';
	@override String get parentStory => 'Kisah Keluarga';
	@override String get adaptation => 'Penyesuaian';
	@override String get other => 'berkaitan';
}

// Path: explore.detail
class _Translations$explore$detail$ms extends Translations$explore$detail$en {
	_Translations$explore$detail$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Tajuk asal';
	@override String get alsoKnownAs => 'Juga dikenali sebagai';
	@override String get studios => 'Pengajian';
	@override String get country => 'negara';
	@override String get language => 'Bahasa Melayu';
	@override String get released => 'dibebaskan';
	@override String get physicalRelease => 'Pada cakera';
	@override String get ended => 'Tamat';
	@override String addedOn({required Object date}) => 'Ditambah ${date}';
	@override String get yourRating => 'Penilaian anda';
	@override String get budget => 'Bajet';
	@override String get revenue => 'Pejabat Box';
	@override String get contentAdvisory => 'Panduan Umur';
	@override String get tags => 'Tag :';
	@override String get revealSpoilerTags => 'Menunjukkan spoiler tag';
	@override String get links => 'Kiri';
	@override String get watchOn => 'Lihatlah';
	@override String get watchTrailer => 'Lihat trailer';
	@override String openOn({required Object site}) => 'Terbuka pada ${site}';
	@override String get crew => 'Pasukan';
	@override String get ratings => 'Penilaian';
	@override String get schedule => 'Jadual';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n,
		other: 'Disyorkan oleh ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengguna',
	);
	@override String recommendedBy({required Object who}) => 'disyorkan oleh ${who}';
	@override String favoritedBy({required Object who}) => 'disukai oleh ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} belum diakses';
	@override String recommendedByPercent({required Object percent}) => 'disyorkan oleh ${percent} penonton';
	@override String get relatedTitles => 'Tajuk yang berkaitan';
	@override String get background => 'latar belakang';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$ms extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Bermula awal (second)';
	@override String get endLate => 'Akhir yang terlambat (second)';
	@override String get newOnly => 'Hanya episod baru';
	@override String get anyChannel => 'Rekod di mana-mana saluran';
	@override String get anyTime => 'Rekod pada bila-bila masa';
	@override String get skipInLibrary => 'Melemparkan episod-episod yang sudah di perpustakaan';
	@override String get keepUpTo => 'Episod yang perlu dikekalkan';
	@override String get keepUpToHint => '0 mengekalkan setiap episod';
}

// Path: music.discography
class _Translations$music$discography$ms extends Translations$music$discography$en {
	_Translations$music$discography$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Kumpulan & EPs';
	@override String get live => 'hidup';
	@override String get compilations => 'Kompilasi';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$ms extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} permainan percetakan';
	@override String get playbackStarted => 'Playback telah bermula';
	@override String paused({required Object name}) => '${name} beristirahat';
	@override String get playbackPaused => 'Playback bercuti';
	@override String jumpedTo({required Object name, required Object position}) => '${name} melompat ke ${position}';
	@override String roomJumpedTo({required Object position}) => 'Perbincangan:Penghormatan kepada ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} menetapkan kelajuan kepada ${speed}';
	@override String speedChanged({required Object speed}) => 'Kelajuan yang ditetapkan kepada ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} bermula ${title}';
	@override String mediaStarted({required Object title}) => 'Bermain sekarang ${title}';
	@override String stoppedMedia({required Object name}) => '${name} berhenti video';
	@override String get mediaStopped => 'Video telah berhenti';
	@override String waitingFor({required Object name}) => 'Menunggu untuk ${name} ...';
	@override String get waitingForSomeone => 'Menunggu orang lain untuk menangkap ...';
	@override String get finished => 'selesai';
	@override String hostChangedTo({required Object name}) => '${name} kini menjadi tuan rumah';
	@override String get youAreNowHost => 'Sekarang awak tuan rumah';
	@override String joined({required Object name}) => '${name} menyertai';
	@override String left({required Object name}) => '${name} keluar';
	@override String get controlRefused => 'Hanya tuan rumah yang boleh mengawal playback';
	@override String get searchFailed => 'Sesetengah pelayan tidak boleh dicari untuk video bilik';
	@override String get playBlocked => 'Permainan akhbar untuk bermula';
	@override String get shareFailed => 'Saya tidak boleh berkongsi video ini dengan bilik';
	@override String get downloadNotShared => 'Muat turun tidak dikongsi dengan bilik sementara pelayan mereka offline';
	@override String get openFailed => 'Tidak boleh membuka video bilik';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$ms extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Penghuni telah mengakhiri bilik';
	@override String get kicked => 'Anda telah diusir dari bilik';
	@override String get expired => 'Bilik telah tamat';
	@override String get replaced => 'Anda telah menyertai bilik ini pada peranti lain';
	@override String get lost => 'Kehilangan sambungan ke bilik';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$ms extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Kod mempunyai 6 huruf dan angka, tanpa 0, 1, I, L atau O.';
	@override String get roomNotFound => 'Tiada bilik yang mempunyai kod itu. ia mungkin telah berakhir.';
	@override String get roomFull => 'Bilik itu penuh.';
	@override String get roomLocked => 'Pihak pengurus telah menutup bilik itu.';
	@override String get relayFull => 'Lihat Bersama sibuk sekarang. cuba lagi nanti.';
	@override String get unreachable => 'Tidak boleh mencapai jam bersama relay. semak sambungan anda.';
	@override String get rateLimited => 'Terlalu banyak percubaan. tunggu sebentar dan cuba lagi.';
	@override String get clientBlocked => 'Versi PlezyNG ini tidak boleh menggunakan relay.';
	@override String get forbidden => 'Hanya tuan rumah sahaja yang boleh melakukannya.';
	@override String get notInRoom => 'Awak tak ada di dalam bilik.';
	@override String get alreadyInRoom => 'Awak dah ada di dalam bilik.';
	@override String get resumeFailed => 'Saya tak boleh masuk ke dalam bilik.';
	@override String get unsupported => 'Radio tidak menyokong perkara ini.';
	@override String get generic => 'Ada yang salah, cuba lagi.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$ms extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Muat turun akan berhenti apabila anda meninggalkan app';
	@override String get bannerDegraded => 'Download latar belakang boleh terhad';
	@override String get bannerAction => 'Maklumat';
	@override String get sheetTitle => 'Download latar belakang disekat';
	@override String get sheetTitleDegraded => 'Download latar belakang boleh terhad';
	@override String get sheetIntro => 'Android mencegah PlezyNG daripada memuat turun dengan boleh dipercayai dalam latar belakang.';
	@override String get sheetIntroDegraded => 'Peranti anda membatasi apabila PlezyNG boleh dimuat turun dalam latar belakang.';
	@override String get reasonBackgroundRestricted => 'Penggunaan latar belakang PlezyNG terhad. tetapkan penggunaan bateri atau latar belakang kepada "Tidak terhad".';
	@override String get reasonStandbyRestricted => 'Android telah meletakkan PlezyNG dalam keadaan berdiri terhad. menetapkan penggunaan bateri kepada "Tidak terhad".';
	@override String get reasonDownloadChannelBlocked => 'Pemberitahuan muat turun dimatikan, jadi kemajuan dan kawalan mungkin tidak tersedia.';
	@override String get reasonNotificationsDisabled => 'Pada Android 13 atau lebih baru, mereka diperlukan untuk muat turun latar belakang yang panjang.';
	@override String get reasonDataSaver => 'Data Saver ialah pada, yang memblokir muat turun latar belakang pada data mudah alih. muat turun masih perlu berjalan pada Wi-Fi.';
	@override String get reasonOemUnknown => 'Muat turun berulang kali berhenti semasa PlezyNG berada di latar belakang. semak tetapan penggunaan bateri atau latar belakang PlezyNG.';
	@override String get openSettings => 'Seting Terbuka';
	@override String get stillNotWorking => 'Bantuan khusus peranti';
	@override String get stillNotWorkingDescription => 'Lihat langkah-langkah untuk peranti anda, atau hantar log daripada Settings › Lihat log jika masalah berterusan.';
	@override String get dialogTitle => 'Download tidak boleh selesai';
	@override String get dialogDownloadAnyway => 'Download apa pun';
	@override String get dialogFixFirst => 'Tetapkan ini terlebih dahulu';
	@override String get statusTile => 'Latar Belakang Download';
	@override String get statusOk => 'dibenarkan untuk berlari di latar belakang';
	@override String get statusBlocked => 'disekat oleh sistem pengaturan';
	@override String get statusDegraded => 'Terhad oleh tetapan sistem';
	@override String get statusUnknown => 'belum disemak';
	@override String get settingsUnavailable => 'Tidak boleh membuka tetapan sistem pada peranti ini';
	@override String get linkUnavailable => 'Tidak boleh membuka dontkillmyapp.com pada peranti ini';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$ms extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get library => 'Pustaka';
	@override String get collections => 'Koleksi';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$ms extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Memulakan pelayan jarak jauh';
	@override String get hostAddress => 'alamat tuan rumah';
	@override String get connected => 'Terhubung';
	@override String get serverRunning => 'Remote server aktif';
	@override String get serverStopped => 'Remote server telah berhenti';
	@override String get serverRunningDescription => 'Peranti mudah alih di rangkaian anda boleh menyambung ke aplikasi ini';
	@override String get serverStoppedDescription => 'Mulakan pelayan untuk membolehkan peranti mudah alih untuk menyambung';
	@override String get usePhoneToControl => 'Gunakan peranti mudah alih anda untuk mengawal aplikasi ini';
	@override String get startServer => 'Mulakan pelayan';
	@override String get stopServer => 'Hentikan pelayan';
	@override String get minimize => 'Minimum';
	@override String get manualAddressHint => 'Alamat sambungan manual :';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$ms extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'PlezyNG peranti dengan akaun yang sama Plex muncul di sini';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Menghubungkan ...';
	@override String get searchingForDevices => 'Mencari peranti ...';
	@override String get noDevicesFound => 'Tiada peranti yang ditemui di rangkaian anda';
	@override String get noDevicesHint => 'Buka PlezyNG pada desktop dan gunakan yang sama Wi-Fi';
	@override String get availableDevices => 'Peranti yang tersedia';
	@override String get manualConnection => 'Penghubung manual';
	@override String get cryptoInitFailed => 'Tidak boleh memulakan sambungan yang selamat. mendaftar di Plex terlebih dahulu.';
	@override String get validationHostRequired => 'Sila masukkan alamat tuan rumah';
	@override String get validationHostFormat => 'Format hendaklah IP:port (contohnya, 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Menggunakan rangkaian yang sama pada kedua-dua peranti.';
	@override String get sessionNotFound => 'Peranti tidak ditemui. pastikan PlezyNG berjalan pada host.';
	@override String get authFailed => 'Pengesahan gagal. kedua-dua peranti memerlukan akaun yang sama Plex.';
	@override String failedToConnect({required Object error}) => 'Kegagalan untuk menghubungkan: ${error}';
	@override String get codeTitle => 'Pasangan Kod';
	@override String get codeDescription => 'Masukkan kod yang ditunjukkan dalam Companion Remote pada peranti tuan rumah. kedua-dua peranti mesti menggunakan versi yang menyokong perpaduan yang selamat.';
	@override String get codeInvalid => 'Masukkan semua 32 huruf dan nombor daripada kod tuan rumah.';
	@override String get updateRequired => 'Kemas kini kedua-dua peranti kepada versi yang menyokong perpaduan yang selamat.';
	@override String get hostDescription => 'Masukkan kod ini sekali pada setiap remote. simpan peribadi: ia memberikan kawalan profil ini.';
	@override String get resetCode => 'Menerapkan kod pasangan';
	@override String get resetDescription => 'Mengalih keluar semua remote dan mencipta kod baru. setiap remote akan perlu berpasangan lagi.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$ms extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Adakah anda mahu menyambung keluar daripada sesi jauh?';
	@override String get reconnecting => 'Menghubungkan semula...';
	@override String attemptOf({required Object current}) => 'Mencuba ${current} daripada 5';
	@override String get retryNow => 'Kembali sekarang';
	@override String get tabRemote => 'jarak jauh';
	@override String get tabPlay => 'Bermain';
	@override String get tabMore => 'Lagi';
	@override String get menu => 'Menu yang';
	@override String get tabNavigation => 'Tab navigasi';
	@override String get tabDiscover => 'Menjelajahi';
	@override String get tabLibraries => 'Pustaka';
	@override String get tabSearch => 'Pencarian';
	@override String get tabDownloads => 'Muat turun';
	@override String get tabSettings => 'Tetapan';
	@override String get previous => 'Sebelumnya';
	@override String get playPause => 'Bermain / beristirahat';
	@override String get next => 'Seterusnya';
	@override String get seekBack => 'Mencari Kembali';
	@override String get stop => 'Berhenti';
	@override String get seekForward => 'Mencari FWD';
	@override String get volume => 'Jumlah';
	@override String get volumeDown => 'Bawah';
	@override String get volumeUp => 'Tambah';
	@override String get fullscreen => 'Paparan skrin penuh';
	@override String get subtitles => 'Sari kata';
	@override String get audio => 'Audio yang';
	@override String get searchHint => 'Mencari di Desktop';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$ms extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Tiada antara muka rangkaian yang ditemui';
	@override String get authenticationFailed => 'Kegagalan pengesahan';
	@override String serverStartFailed({required Object error}) => 'Tidak memulakan pelayan jauh: ${error}';
	@override String commandFailed({required Object error}) => 'Tidak dapat menghantar perintah jauh: ${error}';
	@override String get joinTimedOut => 'Tarikh keluar untuk menyertai sesi';
	@override String get failedToConnectAnyAddress => 'Tidak dapat menghubungkan ke mana-mana alamat';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Hubungan hilang selepas ${attempts} percubaan';
	@override String get connectionLost => 'Hubungan yang hilang';
}

// Path: services.names
class _Translations$services$names$ms extends Translations$services$names$en {
	_Translations$services$names$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$ms extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Perbincangan Simkl';
	@override String get subtitle => 'Simkl adalah penarikan kaedah log masuk yang menggunakan sambungan ini. penyambungan semula membuka simkl.com untuk meluluskan PlezyNG — PlezyNG tidak pernah melihat kata laluan anda. sejarah jam anda kekal pada Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$ms extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Mengaktifkan PlezyNG pada ${service}';
	@override String get instructions => 'Mengimbas kod QR, atau lawati alamat di bawah dan masukkan kod ini:';
	@override String openToActivate({required Object service}) => 'Buka ${service} untuk mengaktifkan';
	@override String get copyCode => 'Menyalin kod pengaktifan';
	@override String get waitingForAuthorization => 'Menunggu kelulusan...';
	@override String get codeCopied => 'Kod yang disalin';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$ms extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Mendaftar di ${service}';
	@override String get body => 'Memindai kod QR ini atau buka URL pada mana-mana peranti.';
	@override String openToSignIn({required Object service}) => 'Buka ${service} untuk mendaftar';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$ms extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Mendaftar dalam URL';
	@override String get urlCopied => 'URL yang disalin';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$ms extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filter Perpustakaan';
	@override String get subtitleAllSyncing => 'Menyusun semua perpustakaan';
	@override String get subtitleNoneSyncing => 'Tiada apa-apa yang disinkronkan';
	@override String subtitleBlocked({required Object count}) => '${count} disekat';
	@override String subtitleAllowed({required Object count}) => '${count} dibenarkan';
	@override String get mode => 'Filter Mode';
	@override String get modeBlacklist => 'Senarai hitam';
	@override String get modeWhitelist => 'Putih';
	@override String get modeHintBlacklist => 'Sinkronkan setiap perpustakaan kecuali yang disemak di bawah.';
	@override String get modeHintWhitelist => 'Simak hanya perpustakaan yang disemak di bawah.';
	@override String get libraries => 'Pustaka';
	@override String get noLibraries => 'Tiada perpustakaan yang tersedia';
	@override String get modeDescription => 'Pilih sama ada perpustakaan yang disemak terhalang daripada menyegerakkan atau merupakan satu-satunya perpustaka yang menyegerakan.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$ms extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$ms._(TranslationsMs root) : this._root = root, super.internal(root);

	final TranslationsMs _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Sinkronkan episod dan filem yang dilihat dengan akaun Trakt anda.';
	@override String get mal => 'Menyegerakkan senarai anime dan menonton kemajuan dengan MyAnimeList.';
	@override String get anilist => 'Menyegerakkan senarai anime dan menonton kemajuan dengan AniList.';
	@override String get simkl => 'Sync menonton filem, rancangan televisyen, dan anime dengan Simkl.';
	@override String get mdblist => 'Tunjukkan penarafan MDBList dan senarai dalam cadangan dan Cari.';
}

/// The flat map containing all translations for locale <ms>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsMs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Icon Permohonan',
			'appIcon.defaultIcon' => 'Perkataan default',
			'appIcon.current' => 'Ikon semasa',
			'appIcon.locked' => 'Akses seumur hidup diperlukan',
			'appIcon.lockedHint' => 'Mulakan percubaan 7 hari anda atau membuka kunci PlezyNG sepanjang hayat anda untuk menggunakan ikon alternatif.',
			'appIcon.changeFailed' => 'Tidak boleh mengubah ikon app',
			'appIcon.launcherHint' => 'Ikon baru muncul pada skrin rumah anda apabila anda meninggalkan PlezyNG.',
			'appIcon.tvLauncherHint' => 'Banner baru muncul apabila anda meninggalkan PlezyNG. Android TV boleh terus menunjukkan yang lama sehingga TV bermula semula.',
			'appIcon.names.midnight' => 'tengah malam',
			'appIcon.names.ember' => 'orang',
			'appIcon.names.paper' => 'kertas',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'garis',
			'appIcon.names.ocean' => 'Lautan',
			'appIcon.names.ultraviolet' => 'Ultrasifikasi',
			'appIcon.names.matcha' => 'Perlawanan',
			'appIcon.names.sunset' => 'Matahari terbenam',
			'appIcon.names.gold' => 'emas',
			'appIcon.names.titanium' => 'Tag: titanium',
			'appIcon.names.glass' => 'kaca',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Perbezaan',
			'appIcon.names.pixel' => 'Piksel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Sticker yang',
			'appIcon.names.ticket' => 'tiket',
			'appIcon.names.pop' => 'Pop yang',
			'appIcon.names.strata' => 'Jalan',
			'appIcon.names.facet' => 'Wajah',
			'appIcon.names.tilde' => 'Tag : Tilde',
			'appIcon.description' => 'Pilih ikon yang ditunjukkan oleh pelancaran peranti anda. previews menunjukkan bagaimana setiap opsyen kelihatan.',
			'auth.signInWithPlex' => 'Mendaftar dengan Plex',
			'auth.showQRCode' => 'Menunjukkan kod QR',
			'auth.authenticate' => 'Autentik',
			'auth.authenticationTimeout' => 'Pengesahan telah tiba.Sila cuba lagi.',
			'auth.scanQRToSignIn' => 'Mengimbas kod QR ini untuk mendaftar',
			'auth.waitingForAuth' => 'Menunggu untuk pengesahan ... Mendaftar masuk daripada pelayar anda.',
			'auth.useBrowser' => 'Penggunaan Browser',
			'auth.or' => 'atau',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Hubungi ${product}',
			'auth.quickConnect' => 'Sambung Pantas',
			'auth.useQuickConnect' => 'Gunakan Sambungan Pantas',
			'auth.quickConnectInstructions' => 'Buka Quick Connect dalam Jellyfin dan masukkan kod ini.',
			'auth.quickConnectWaiting' => 'Menunggu kelulusan...',
			'auth.quickConnectCancel' => 'Batalkan',
			'auth.quickConnectExpired' => 'Sambungan Pantas telah tamat tempoh. Cuba lagi.',
			'auth.localDataRecoveryRequired' => 'PlezyNG tidak dapat memulihkan maklumat log masuk tempatan dan data main balik yang belum diproses dengan selamat. Sila log masuk semula.',
			'auth.pinCheckRejected' => 'Pendaftaran PIN Plex ditolak',
			'auth.connectToDirectPlex' => 'Menyambung ke pelayan tempatan Plex',
			'common.cancel' => 'Batalkan',
			'common.save' => 'menyelamatkan',
			'common.close' => 'Tutup',
			'common.closeMiniPlayer' => 'Berhampiran Mini Pemain',
			'common.closeWorkspaceWindow' => 'tetingkap terdekat',
			'common.returnToFullView' => 'Kembali ke pandangan penuh',
			'common.manageMediaSessions' => 'Menguruskan sesi media',
			'common.hideMediaSessions' => 'Menyembunyikan sesi media',
			'common.mediaSessions' => 'Mesyuarat Media',
			'common.mediaSessionsHint' => 'Pilih untuk membawa sesi ke hadapan.Park menyembunyikan tetingkap tetapi mengekalkannya terbuka.Kembali membuka ia dalam pandangan penuh; berhampiran menamatkannya.',
			'common.sessionInWorkspace' => 'dalam ruang kerja',
			'common.sessionParked' => 'tempat letak kereta',
			'common.sessionFullscreen' => 'skrin penuh',
			'common.switchToNextWindow' => 'Tukar dengan tetingkap seterusnya',
			'common.moveWindow' => 'Pergerakan tingkap',
			'common.finishMovingWindow' => 'Menamatkan tetingkap bergerak',
			'common.moveWindowHint' => 'Tekan panjang dan tarik tetingkap untuk memindahkannya. kawalan ini juga membolehkan pergerakan kunci tiang.',
			'common.movingWindowHelp' => 'Tarik ke bergerak · Tarik kunci disesuaikan · Enter saves · Melarikan diri membatalkan',
			'common.resizeWindow' => 'Menyelesaikan tetingkap',
			'common.resizeWindowHint' => 'Tarik tangan ini atau gunakan kunci anak panah untuk memutar semula tetingkap.',
			'common.workspaceWindowHint' => 'Gunakan kawalan pergerakan atau tekanan panjang dan tarik untuk bergerak.',
			'common.workspacePaneHint' => 'Pilih panel ini untuk memberi tumpuan kepada ia. gunakan kawalan skrin penuh untuk mengembangkan.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Jendela sesi: ${title}',
			'common.workspaceTitleHint' => 'Tarik bar tajuk untuk bergerak; gunakan butang skrin penuh untuk mengembangkan.',
			'common.moveToSessionTray' => 'Bergerak ke sesi tray',
			'common.moveToSessionTrayHint' => 'Keep sesi ini boleh didapati tanpa menunjukkan tetingkapnya.',
			'common.closeSessionHint' => 'Menutup tetingkap ini dan menamatkan sesi.',
			'common.sideBySideLayout' => 'Tukar kepada layout side-by-side',
			'common.floatingWindows' => 'Switch untuk mengalir tetingkap',
			'common.clear' => 'jelas',
			'common.reset' => 'Kembali ke',
			'common.later' => 'Kemudian',
			'common.submit' => 'Hantar',
			'common.confirm' => 'mengesahkan',
			'common.retry' => 'Kembali',
			'common.logout' => 'Log keluar',
			'common.unknown' => 'yang tidak diketahui',
			'common.refresh' => 'Menyejukkan',
			'common.yes' => 'Ya',
			'common.no' => 'Tidak',
			'common.delete' => 'Padam',
			'common.edit' => 'Sunting',
			'common.shuffle' => 'Rawak',
			'common.addTo' => 'Tambah kepada...',
			'common.createNew' => 'Mencipta yang baru',
			'common.connect' => 'Sambung',
			'common.disconnect' => 'Putuskan sambungan',
			'common.play' => 'Mainkan',
			'common.pause' => 'Henti Sejenak',
			'common.resume' => 'Sambung semula',
			'common.error' => 'Ralat',
			'common.search' => 'Pencarian',
			'common.home' => 'rumah',
			'common.back' => 'Kembali',
			'common.settings' => 'Tetapan',
			'common.mute' => 'Mutu',
			'common.ok' => 'Ok',
			'common.off' => 'Dimatikan',
			'common.options' => 'Pilihan',
			'common.seasonNumber' => ({required Object number}) => 'Tarikh : ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Bahagian ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Perbincangan ${number}',
			'common.reconnect' => 'Sambungan semula',
			'common.viewAll' => 'Lihat semua',
			'common.checkingNetwork' => 'Rangkaian pemeriksaan ...',
			'common.loadingServers' => 'Pelayan Pengecasan ...',
			'common.connectingToServers' => 'Menyambung ke pelayan ...',
			'common.startingOfflineMode' => 'Bermula dengan mod offline.',
			'common.loading' => 'Pengangkutan...',
			'common.fullscreen' => 'Paparan skrin penuh',
			'common.exitFullscreen' => 'Keluarkan skrin penuh',
			'common.pressBackAgainToExit' => 'Tekan balik lagi untuk keluar',
			'common.ratingSource.critic' => 'Critics',
			'common.ratingSource.audience' => 'Audience',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes critics',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes audience',
			'common.ratingSource.metacritic' => 'Metacritic',
			'common.ratingSource.letterboxd' => 'Letterboxd',
			'common.notAvailable' => 'N / A',
			'common.url' => 'URL',
			'common.letterKeys' => 'Tag : ABC',
			'common.mediaKind.movie' => 'filem',
			'common.mediaKind.show' => 'Pameran',
			'common.mediaKind.season' => 'Musim',
			'common.mediaKind.episode' => 'Episod',
			'common.mediaKind.artist' => 'Artis',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Laluan',
			'common.mediaKind.collection' => 'Koleksi',
			'common.mediaKind.playlist' => 'Senarai Main',
			'common.mediaKind.clip' => 'Klip',
			'common.mediaKind.photo' => 'Gambar',
			'common.mediaKind.folder' => 'Folder dalam',
			'screens.licenses' => 'Permohonan',
			'screens.switchProfile' => 'Profil Switch',
			'screens.subtitleStyling' => 'Subtitle Pengurusan',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logs yang',
			'update.available' => 'Update yang tersedia',
			'update.versionAvailable' => ({required Object version}) => 'Versi ${version} boleh didapati',
			'update.currentVersion' => ({required Object version}) => 'Jumlah : ${version}',
			'update.skipVersion' => 'Hentikan versi ini',
			'update.viewRelease' => 'Lihat pelancaran',
			'update.latestVersion' => 'Anda berada dalam versi terkini',
			'update.checkFailed' => 'Tidak boleh memeriksa untuk update',
			'settings.title' => 'Tetapan',
			'settings.supportDeveloper' => 'Perkhidmatan PlezyNG',
			'settings.supportDeveloperDescription' => 'Memberi sumbangan untuk menyokong pembangunan',
			'settings.lifetimeAccess' => 'PlezyNG akses seumur hidup',
			'settings.language' => 'Bahasa Melayu',
			'settings.theme' => 'Subjek',
			'settings.appearance' => 'Penampilan',
			'settings.detailPage' => 'Halaman terperinci',
			'settings.themeSongsEnabled' => 'Main lagu tema',
			'settings.themeSongsEnabledDescription' => 'Mainkan lagu tema yang tersedia sambil melihat butiran media.',
			'settings.themeSongVolume' => 'Kumpulan Lagu Volume',
			'settings.videoPlayback' => 'Video untuk Playback',
			'settings.videoPlaybackDescription' => 'Mengesetkan tingkah laku playback',
			'settings.advanced' => 'Kemajuan',
			'settings.episodePosterMode' => 'Gambar Poster Gaya',
			'settings.seriesPoster' => 'Poster siri',
			'settings.seasonPoster' => 'Poster Musim',
			'settings.episodeThumbnail' => 'Tumbnail',
			'settings.showHeroSectionDescription' => 'Menampilkan kandungan karousel pada skrin rumah',
			'settings.secondsLabel' => 'Sekejap',
			'settings.minutesLabel' => 'Minit',
			'settings.secondsShort' => 's s',
			'settings.minutesShort' => 'M ialah',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Masukkan nilai (${min}-${max})',
			'settings.systemTheme' => 'Sistem',
			'settings.lightTheme' => 'cahaya',
			'settings.darkTheme' => 'kegelapan',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'orang',
			'settings.glacierTheme' => 'Gletser',
			'settings.forestTheme' => 'hutan',
			'settings.plumTheme' => 'Ungu plum',
			'settings.paperTheme' => 'kertas',
			'settings.libraryDensity' => 'Ketebalan perpustakaan',
			'settings.displayScale' => 'Skala Pameran',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'selesa',
			'settings.gridSpacing' => 'Rangkaian Spacing',
			'settings.gridSpacingTight' => 'Tight untuk',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'ruang',
			'settings.tvCornerSpotlightBackdrop' => 'Tag: latar belakang spotlight backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'Tunjukkan spotlight artwork di sudut kanan atas bukannya mengisi skrin',
			'settings.viewMode' => 'Lihat Mode',
			'settings.gridView' => 'Rangkaian',
			'settings.listView' => 'Senarai',
			'settings.showHeroSection' => 'Menampilkan Hero Seksyen',
			'settings.showHomeBackdrop' => 'Menunjukkan rumah backdrop artwork',
			'settings.showHomeBackdropDescription' => 'Tunjukkan karya seni besar di belakang rangkaian rumah yang ditampilkan',
			'settings.contentScreensaverEnabled' => 'Perkhidmatan Screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Tunjukkan karya seni skrin penuh selepas aplikasi telah menjadi idle',
			'settings.contentScreensaverDelay' => 'Memulakan screensaver selepas',
			'settings.contentScreensaverLibraries' => 'Perpustakaan Screensaver',
			'settings.contentScreensaverLibrariesDescription' => 'Pilih perpustakaan mana yang menyediakan karya seni pemantauan skrin.Jika tiada yang dipilih, karya seni dari semua perpustakaan digunakan.',
			'settings.contentScreensaverAllLibraries' => 'Semua pustaka',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} perpustakaan terpilih',
			'settings.contentScreensaverNoLibraries' => 'Tiada perpustakaan media yang disambungkan tersedia.',
			'settings.contentScreensaverDismissHint' => 'Tekan butang atau ketik untuk membatalkan',
			'settings.newEpisodeNotifications' => 'Pemberitahuan episod baru',
			'settings.newEpisodeNotificationsDescription' => 'Peringatan apabila episod baru ditambah kepada persembahan yang anda terperangkap. semak sementara Plezy dibuka.',
			'settings.continueWatchingRowSize' => 'Lihat lagi reviu untuk Range Size',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} kad',
			'settings.rowSizeCompact' => 'Kompakt',
			'settings.rowSizeStandard' => 'standard',
			'settings.rowSizeLarge' => 'besar',
			'settings.continueWatchingAction' => 'Lanjutkan pengawasan tindakan',
			'settings.continueWatchingPlay' => 'Bermain',
			'settings.continueWatchingDetails' => 'Maklumat Terbuka',
			'settings.episodeAction' => 'Tindakan episod',
			'settings.episodePlay' => 'Bermain',
			'settings.episodeDetails' => 'Maklumat Terbuka',
			'settings.useGlobalHubs' => 'Menggunakan Home Layout',
			'settings.useGlobalHubsDescription' => 'Tunjukkan hub rumah bersatu. jika tidak, gunakan cadangan perpustakaan.',
			'settings.showServerNameOnHubs' => 'Tunjukkan nama pelayan pada Hubs',
			'settings.showServerNameOnHubsDescription' => 'Selalu tunjukkan nama pelayan dalam tajuk hub.',
			'settings.groupLibrariesByServer' => 'Perpustakaan Perpustakaan oleh Server',
			'settings.groupLibrariesByServerDescription' => 'Kumpulan halaman perpustakaan di bawah setiap pelayan media.',
			'settings.alwaysKeepSidebarOpen' => 'Sentiasa buka sidebar',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidebar kekal diperluaskan dan kawasan kandungan disesuaikan untuk menyesuaikan',
			'settings.showUnwatchedCount' => 'Tunjukkan Unwatched Count',
			'settings.showUnwatchedCountDescription' => 'Menampilkan episod yang tidak dilihat mengira pada persembahan dan musim',
			'settings.showWatchedIndicators' => 'Menunjukkan indikator yang dilihat',
			'settings.showWatchedIndicatorsDescription' => 'Tunjukkan tanda semak pada filem, persembahan, dan episod yang dilihat',
			'settings.showEpisodeNumberOnCards' => 'Tunjukkan nombor episod pada kad',
			'settings.showEpisodeNumberOnCardsDescription' => 'Tunjukkan musim dan nombor episod pada kad episod',
			'settings.showSeasonPostersOnTabs' => 'Tunjukkan Poster Musim di Tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'Tunjukkan poster setiap musim di atas tabnya',
			'settings.tvFullCardLayout' => 'Kertas TV penuh',
			'settings.tvFullCardLayoutDescription' => 'Gunakan kad TV imej sahaja dengan nama pelakon yang terlepas',
			'settings.focusGlow' => 'Perbincangan Glow',
			'settings.focusGlowDescription' => 'Tekan cahaya lembut di sekeliling kad fokus',
			'settings.visualEffects' => 'Kesan visual',
			'settings.visualEffectsAuto' => 'Kereta',
			'settings.visualEffectsAutoDescription' => 'Mengurangkan kesan secara automatik pada peranti kuasa rendah',
			'settings.visualEffectsFull' => 'penuh',
			'settings.visualEffectsReduced' => 'dikurangkan',
			'settings.visualEffectsReducedDescription' => 'Kurang animasi dan karya seni resolusi rendah',
			'settings.hideSpoilers' => 'Menyembunyikan spoilers untuk episod yang tidak dipantau',
			'settings.hideSpoilersDescription' => 'Blur miniatur dan deskripsi untuk episod yang tidak dilihat',
			'settings.playerBackend' => 'Penyertaan Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Perkakasan decoding',
			'settings.hardwareDecodingDescription' => 'Menggunakan kelajuan perkakasan apabila tersedia',
			'settings.playbackBuffer' => 'Perbincangan:Playback Buffer',
			'settings.playbackBufferAuto' => 'Kereta yang disyorkan (',
			'settings.playbackBufferLarge' => 'besar',
			'settings.playbackBufferExtraLarge' => 'Terlalu besar',
			'settings.playbackBufferDescription' => 'Buffer lebih daripada sambungan yang tidak stabil. juga terhad oleh Buffer Size.',
			'settings.streamBufferSize' => 'Saiz Buffer',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Berapa banyak video yang perlu dimuat naik ke hadapan apabila memainkan secara langsung. transcodes berhenti di buffer transcode sendiri pelayan. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Menggantikan Playback Buffer apabila ditetapkan, capped pada separuh had memori aplikasi',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Kualiti lalai',
			'settings.cellularQualityTitle' => 'Kualiti yang rendah pada sel',
			'settings.remoteQualityTitle' => 'Kualiti Streaming Jarak Jauh',
			'settings.remoteQualitySameAsDefault' => 'Sama seperti kualiti default',
			'settings.cellularQualitySameAsDefault' => 'Sama seperti kualiti lalai',
			'settings.directPlayCoveredQuality' => 'Mainkan Video Kecil Dengan Kualiti Asli',
			'settings.directPlayCoveredQualityDescription' => 'Mainkan video secara langsung dalam had kualiti daripada menyulitkan mereka',
			'settings.videoCodecs' => 'Video Kodek',
			'settings.videoCodecsDescription' => 'Kodek yang tidak disemak disulitkan oleh pelayan',
			'settings.videoCodecsAlwaysAccepted' => 'Selalu diterima',
			'settings.musicQualityTitle' => 'Kualiti muzik',
			'settings.subtitleStyling' => 'Subtitle Pengurusan',
			'settings.subtitleStylingDescription' => 'Menerapkan penampilan subtitle',
			'settings.smallSkipDuration' => 'Tempoh Skik Kecil',
			'settings.largeSkipDuration' => 'Jangka Panjang Skik',
			'settings.rewindOnResume' => 'Kembali ke Resume',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} saat', ), 
			'settings.defaultSleepTimer' => 'Tempoh Tidur Default',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minit', ), 
			'settings.rememberTrackSelections' => 'Ingat pilihan trek per persembahan/filem',
			'settings.chooseTracksBeforePlayback' => 'Pilih audio dan subtitle sebelum playback',
			'settings.chooseTracksBeforePlaybackDescription' => 'Pilih sumber audio dan subtitle trek sebelum setiap video bermula.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Selalu tunjukkan subtitle pada peranti ini',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Apabila pelayan tidak mempunyai subtitle yang dipilih, pilih trek secara tempatan. ini tidak pernah mengubah keutamaan pelayan.',
			'settings.autoDownloadPreferredSubtitle' => 'FETCH kekurangan subtitle bahasa kegemaran',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Pilih subtitle yang tersedia dalam bahasa kegemaran anda secara tempatan.Jika tiada, minta pelayan untuk menangkap satu apabila disokong.Pilihan kekal pada peranti ini.',
			'settings.rememberTrackSelectionsDescription' => 'Menyimpan pilihan audio dan subtitle mengikut persembahan atau filem pada peranti ini',
			'settings.rememberTrackSelectionsBackendRule' => 'Bekerja secara tempatan dengan Plex, Jellyfin, dan Emby; Plex dan Jellyfin juga boleh menyimpan pemilihan pada pelayan',
			'settings.followServerTrackSelections' => 'Menggunakan pilihan trek per episod pelayan',
			'settings.followServerTrackSelectionsDescription' => 'Pada perubahan episod, gunakan audio dan subtitle yang dipilih pada pelayan bukannya membawa di atas pilihan semasa.',
			'settings.resumeMusicOnLaunch' => 'Ingat sesi muzik',
			'settings.resumeMusicOnLaunchDescription' => 'Buka semula lagu terakhir berhenti di mana ia meninggalkan apabila aplikasi bermula',
			'settings.showChapterMarkersOnTimeline' => 'Tunjukkan penanda bab pada mencari bar',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segmen bar pencarian di sempadan bab',
			'settings.specialsOrdering' => 'Khas dalam perintah episod',
			'settings.specialsOrderingDescription' => 'Di mana istimewa bermain dalam perintah jam persembahan',
			'settings.specialsOrderingServer' => 'Mengikut Perintah Server',
			'settings.specialsOrderingAirDate' => 'Tarikh penerbangan mengikut tarikh',
			'settings.specialsOrderingLast' => 'Selepas musim biasa',
			'settings.clickVideoTogglesPlayback' => 'Klik pada video untuk toggle play/pause',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klik video untuk memainkan/berhenti daripada menunjukkan kawalan.',
			'settings.videoPlayerControls' => 'Pengawal Video Player',
			'settings.keyboardShortcuts' => 'Tag: kekunci pendek',
			'settings.keyboardShortcutsDescription' => 'Menyesuaikan kekunci kekunci',
			'settings.videoPlayerNavigation' => 'Pelakon navigasi video',
			'settings.videoPlayerNavigationDescription' => 'Gunakan kunci pistol untuk menavigasi kawalan pemutar video',
			'settings.watchTogetherRelay' => 'Lihat bersama-sama relay',
			'settings.watchTogetherRelayDescription' => 'Public Open Watch Party melayari kecuali anda menetapkan anda sendiri',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Masukkan URL asas geganti HTTP atau HTTPS yang sah.',
			'settings.crashReporting' => 'Laporan kemalangan',
			'settings.crashReportingDescription' => 'Hantar laporan kemalangan untuk membantu memperbaiki aplikasi',
			'settings.debugLogging' => 'Pengenalan Debug',
			'settings.debugLoggingDescription' => 'Membolehkan log terperinci untuk penyelesaian masalah',
			'settings.viewLogs' => 'Lihat log',
			'settings.viewLogsDescription' => 'Lihat log aplikasi',
			'settings.clearImageCache' => 'Gambaran keseluruhan Cache',
			'settings.clearImageCacheDescription' => 'Gambar boleh dimuat turun lebih perlahan sehingga dimuat turun lagi.',
			'settings.clearImageCacheSuccess' => 'Cache imej diselesaikan dengan berjaya',
			'settings.resetSettings' => 'Pengaturan semula',
			'settings.resetSettingsDescription' => 'Mengembalikan tetapan lalai. ini tidak boleh dikecualikan.',
			'settings.resetSettingsSuccess' => 'Seting Setuju berjaya',
			'settings.backup' => 'Penyimpanan',
			'settings.exportSettings' => 'Pengaturan Eksport',
			'settings.exportSettingsDescription' => 'Simpan keutamaan anda untuk fail',
			'settings.exportSettingsSuccess' => 'Seting yang dieksport',
			'settings.importSettings' => 'Pengenalan Import',
			'settings.importSettingsDescription' => 'Memulihkan keutamaan daripada fail',
			'settings.importSettingsConfirm' => 'Ini akan menggantikan tetapan semasa anda.Lanjutkan?',
			'settings.importSettingsSuccess' => 'Seting yang diimport',
			'settings.importSettingsInvalidFile' => 'Fail ini bukan pengeksportan tetapan PlezyNG yang sah',
			'settings.importSettingsNoUser' => 'Menandatangani sebelum mengimport tetapan',
			'settings.cloudBackup' => 'Penyelesaian Cloud Backup',
			'settings.cloudBackupDescription' => 'Sandarkan tetapan yang boleh dipindahkan ke alamat WebDAV melalui HTTPS. Sambungan pelayan dan maklumat log masuk kekal pada peranti ini.',
			'settings.cloudBackupUrl' => 'WebDAV URL fail JSON',
			'settings.cloudBackupUsername' => 'Nama Pengguna',
			'settings.cloudBackupPassword' => 'kata laluan',
			'settings.cloudBackupSaved' => 'Cloud backup destinasi disimpan',
			'settings.cloudBackupNow' => 'Kembali ke sekarang',
			'settings.cloudBackupComplete' => 'Setup backup diunggah',
			'settings.cloudBackupRestore' => 'Memulihkan Backup',
			'settings.cloudBackupRestoreConfirm' => 'Ini akan menggantikan tetapan mudah alih yang sepadan pada peranti ini.',
			'settings.cloudBackupRestored' => 'Seting yang dipulihkan daripada Cloud Backup',
			'settings.shortcutsReset' => 'Pengurangan semula kepada default',
			'settings.resetShortcutsConfirm' => 'Ini akan menggantikan kekurangan yang disesuaikan anda dengan kekurangan.',
			'settings.about' => 'Mengenai',
			'settings.aboutDescription' => 'Maklumat App dan Lesen',
			'settings.updates' => 'Kemas kini',
			'settings.updateAvailable' => 'Update yang tersedia',
			'settings.checkForUpdates' => 'Semak untuk kemas kini',
			'settings.autoCheckUpdatesOnStartup' => 'Semak secara automatik untuk kemas kini pada startup',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Pemberitahuan apabila kemas kini tersedia pada pelancaran',
			'settings.validationErrorEnterNumber' => 'Sila masukkan nombor yang sah',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Ia mesti antara ${min} dan ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Shortcut yang telah ditugaskan kepada ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Shortcut dikemaskini untuk ${action}',
			'settings.saveFailed' => 'Tidak boleh simpan perubahan. cuba lagi.',
			'settings.autoPlayAndSkip' => 'Permainan dalam talian & Skip',
			'settings.autoPlayNextEpisode' => 'Auto-Play Episode seterusnya',
			'settings.autoPlayNextEpisodeDescription' => 'Memulakan episod seterusnya secara automatik apabila satu berakhir',
			'settings.shuffleStartsFromBeginning' => 'Shuffle bermula pada permulaan',
			'settings.shuffleStartsFromBeginningDescription' => 'Memulakan setiap episod pada permulaan apabila menghisap bukannya mengulangi',
			'settings.plexCinemaPreRoll' => 'Penggunaan pelayan filem intros',
			'settings.plexCinemaPreRollDescription' => 'Mainkan Plex pre-rolls atau Jellyfin dan Emby intros yang dikonfigurasi sebelum filem bermula.',
			'settings.playNextCountdown' => 'Permainan dalam talian Next Countdown',
			'settings.playNextCountdownImmediate' => 'Bermain dengan segera',
			'settings.skipIntroMode' => 'Lapangan Terbang Intro',
			'settings.skipIntroModeOffDescription' => 'Bermain intros secara normal tanpa butang skip',
			'settings.skipIntroModeButtonDescription' => 'Tunjukkan butang skip apabila intro bermula',
			'settings.skipIntroModeAutoDescription' => 'Melompat masuk secara automatik selepas keterlambatan di bawah',
			'settings.skipCreditsMode' => 'Melompat kredit',
			'settings.skipCreditsModeOffDescription' => 'Bermain kredit secara normal tanpa butang skip',
			'settings.skipCreditsModeButtonDescription' => 'Tunjukkan butang skip apabila kredit bermula',
			'settings.skipCreditsModeAutoDescription' => 'Melompat kredit secara automatik dan memainkan episod berikutnya',
			'settings.skipAdsMode' => 'Laporan Ads',
			'settings.skipAdsModeOffDescription' => 'Mainkan iklan yang dikesan secara normal tanpa butang skip',
			'settings.skipAdsModeButtonDescription' => 'Tunjukkan butang skip apabila Plex mendeteksi iklan',
			'settings.skipAdsModeAutoDescription' => 'Hentikan iklan yang dikesan secara automatik selepas penundaan di bawah',
			'settings.musicPlayback' => 'Kumpulan Lagu Playback',
			'settings.musicSweetFades' => 'buah manis',
			'settings.musicSweetFadesDescription' => 'Fade muzik pada tepi trek apabila Plex mempunyai data bunyi.',
			'settings.skipMarkerModeOff' => 'keluar',
			'settings.skipMarkerModeButton' => 'Tunjukkan butang',
			'settings.skipMarkerModeAuto' => 'automatik',
			'settings.forceSkipMarkerFallback' => 'Pengenalan kepada Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'Gunakan corak tajuk bab walaupun Plex mempunyai penanda',
			'settings.theIntroDbFallback' => 'Menggunakan TheIntroDB sebagai intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Gunakan jadual komuniti hanya apabila pelayan tidak mempunyai penanda intro. perlawanan boleh berbeza-beza mengikut pelepasan.',
			'settings.autoSkipDelay' => 'Kereta Api Tangguh',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Menunggu ${seconds} saat sebelum melompat',
			'settings.introPattern' => 'Pengenalan kepada pattern',
			'settings.introPatternDescription' => 'Pattern Regex untuk menyesuaikan intro markers dalam tajuk bab',
			'settings.creditsPattern' => 'Perbezaan kredit markers',
			'settings.creditsPatternDescription' => 'Model Regex untuk memenuhi penanda kredit dalam tajuk bab',
			'settings.prerolls' => 'Preliminasi',
			'settings.playPrerollsBeforeMovies' => 'Bermain Prerolls Sebelum Filem',
			'settings.playPrerollsBeforeMoviesDescription' => 'Mainkan klip rawak daripada pilihan anda di bawah sebelum setiap filem. tekan kembali untuk melompat.',
			'settings.prerollLibrary' => 'Perpustakaan Preroll',
			'settings.prerollLibraryNotSet' => 'Tidak menetapkan',
			'settings.prerollLibraryNoneFound' => 'Tiada perpustakaan yang ditemui di pelayan anda.',
			'settings.prerollSelection' => 'Pemilihan prerolls',
			'settings.prerollSelectionPickLibraryFirst' => 'Pilih perpustakaan terlebih dahulu',
			'settings.prerollSelectionNoneSelected' => 'Tiada jurulatih yang dipilih',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} telah dipilih',
			'settings.prerollItemPicker' => 'Pilih Preliminasi',
			'settings.prerollItemPickerLoadFailed' => 'Saya tidak boleh memuatkan item daripada perpustakaan ini.',
			'settings.invalidRegex' => 'Ketidakupayaan ekspresi biasa',
			'settings.regex' => 'Ekspresi yang kerap',
			'settings.downloads' => 'Muat turun',
			'settings.downloadLocationDescription' => 'Pilih di mana untuk menyimpan kandungan yang dimuat turun',
			'settings.downloadLocationDefault' => 'Penyimpanan Aplikasi (App Storage)',
			'settings.downloadLocationCustom' => 'Lokasi Custom',
			'settings.selectFolder' => 'Pilih Folder',
			'settings.resetToDefault' => 'Kembali ke lalai',
			'settings.currentPath' => ({required Object path}) => 'Jumlah : ${path}',
			'settings.downloadLocationChanged' => 'Lokasi muat turun berubah',
			'settings.downloadLocationReset' => 'Download lokasi reset kepada default',
			'settings.downloadLocationInvalid' => 'folder yang dipilih tidak boleh ditulis',
			'settings.downloadLocationPickerUnavailable' => 'Pemilihan folder tidak tersedia pada peranti ini',
			'settings.downloadOnWifiOnly' => 'Muat turun pada Wi-Fi sahaja',
			'settings.downloadOnWifiOnlyDescription' => 'Mencegah muat turun apabila pada data selular',
			'settings.autoRemoveWatchedDownloads' => 'Auto-remove download yang dilihat',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Menghapuskan muat turun secara automatik',
			'settings.autoDownloadContinueWatching' => 'Auto-Download teruskan penglihatan',
			'settings.autoDownloadContinueWatchingDescription' => 'Simpan item pada rak terus anda dimuat turun, dan menghapuskan mereka sebaik sahaja mereka meninggalkan rak',
			'settings.downloadQuality' => 'Download Kualiti',
			'settings.downloadQualityDescription' => 'Plex menyediakan salinan yang ditukar dalam kue muat turunnya. Jellyfin dan Emby transcode semasa fail muat turun; pemindahan terputus mungkin perlu dimulakan semula.',
			'settings.askDownloadQualityEachTime' => 'Pilih kualiti untuk setiap download',
			'settings.askDownloadQualityEachTimeDescription' => 'Tunjukkan picker kualiti sebelum mengecualikan setiap video muat turun',
			'settings.cellularDownloadBlocked' => 'Muat turun disekat pada selular. gunakan Wi-Fi atau ubah tetapan.',
			'settings.maxVolume' => 'Kelantangan maksimum',
			'settings.maxVolumeDescription' => 'Benarkan peningkatan kelantangan melebihi 100% untuk media yang bunyinya perlahan',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Tunjukkan apa yang anda lihat di Discord',
			'settings.services' => 'Perkhidmatan',
			'settings.servicesDescription' => 'Hubungi Trakt, MyAnimeList, Seerr, dan banyak lagi',
			'settings.manageLibrariesDescription' => 'Menyelamatkan dan menyembunyikan perpustakaan',
			'settings.companionRemoteServer' => 'Pengenalan kepada Remote Server',
			'settings.companionRemoteServerDescription' => 'Membolehkan peranti mudah alih di rangkaian anda untuk mengawal aplikasi ini',
			'settings.companionRemoteServerStartFailed' => 'Tidak boleh memulakan pelayan rakan',
			'settings.companionRemoteServerStopFailed' => 'Tidak boleh menghentikan pelayan rakan',
			'settings.autoPip' => 'Pengenalan kepada Auto Picture-in-Picture',
			'settings.autoPipDescription' => 'Secara automatik, masukkan imej dalam imej apabila anda meninggalkan aplikasi semasa pemutaran',
			'settings.matchContentFrameRate' => 'Rata-rata Perlawanan Content Frame Rate',
			'settings.matchContentFrameRateDescription' => 'Match menunjukkan kadar pembaharuan kepada kandungan video',
			'settings.matchContentResolution' => 'Perlawanan Content Resolution',
			'settings.matchContentResolutionDescription' => 'Tukar paparan kepada resolusi asli video supaya TV anda berfungsi upscaling. menu dan subtitle juga upscaled semasa playback',
			'settings.matchRefreshRate' => 'Perlawanan Rata-rata Pembersihan',
			'settings.matchRefreshRateDescription' => 'Matches paparan kadar pembaharuan dalam skrin penuh',
			'settings.matchDynamicRange' => 'Perlawanan Dynamic Range',
			'settings.matchDynamicRangeDescription' => 'Tukar HDR untuk kandungan HDR, kemudian kembali kepada SDR',
			'settings.displaySwitchDelay' => 'Kelewatan Pertukaran Paparan',
			'settings.tunneledPlayback' => 'Perbincangan:Tunnel Playback',
			'settings.tunneledPlaybackDescription' => 'Gunakan video tunel.Tonaktifkan jika HDR playback menunjukkan video hitam atau stutters pergerakan.',
			'settings.audioPassthrough' => 'Perbincangan:Audio Passthrough',
			'settings.audioPassthroughDescription' => 'Hantar audio Dolby/DTS ke penerima atau TV anda tanpa mengekod semula, mengekalkan bunyi sekitar.',
			'settings.audioPassthroughDescriptionApple' => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. DTS dan TrueHD masih memainkan PCM pelbagai saluran.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. Pada iOS, iPadOS dan tvOS 26 atau lebih lama, TrueHD Atmos dan DTS:X memainkan sebagai audio ruang.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Hentikan semasa normalisasi bunyi',
			'settings.audioChannelLimit' => 'saluran audio',
			'settings.audioChannelLimitDescription' => 'Campurkan audio yang dikodkan ke bawah untuk speaker, headphone, atau setup HDMI yang tidak boleh memainkan setiap saluran',
			'settings.audioChannelLimitOriginal' => 'asal',
			'settings.audioChannelLimitOriginalDescription' => 'Mainkan setiap saluran dalam trek',
			'settings.audioChannelLimitSurround51' => 'sehingga 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Campurkan 7.1 ke bawah kepada 5.1 untuk TV dan penerima yang hanya mengambil 5.1 PCM.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Campurkan ke dua saluran untuk speaker stereo atau headphone.',
			'settings.downmixCenterBoost' => 'Perbincangan Channel Boost',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Pengukuran (db)',
			'settings.downmixCenterBoostShort' => 'DB',
			'settings.audioDownmixNormalize' => 'Meningkatkan jumlah pada Downmix',
			'settings.audioDownmixNormalizeDescription' => 'Mengurangkan campuran untuk mengelakkan penipisan. beralih untuk mengekalkan volum asal (mungkin mengganggu adegan yang keras).',
			'settings.dvConversionMode' => 'Dolby Vision Pengubahsuaian',
			'settings.dvConversionModeDescription' => 'Pilih bagaimana fail Dolby Vision Profil 7 diuruskan.',
			'settings.dvConversionAuto' => 'Kereta',
			'settings.dvConversionNative' => 'Keluarga / Disabiliti',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Menggunakan pengesanan keupayaan peranti dan tingkah laku fallback normal',
			'settings.dvConversionNativeDescription' => 'Kuasa asli DV7 dan penindasan DV penukaran retry',
			'settings.dvConversionDv81Description' => 'Kuasa dalam rangkaian RPU penukaran kepada Dolby Vision profil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Strip Dolby Vision lapisan RPU/EL dan rata semasa HEVC',
			'settings.experimentalDolbyVision' => 'Dolby Vision eksperimen',
			'settings.experimentalDolbyVisionDescription' => 'Gunakan pemapar FEL eksperimen pada main balik seterusnya. Memerlukan binaan enjin yang berasingan.',
			'settings.dvExperimentUnavailableDescription' => 'Eksperimen ini kini hanya tersedia pada Linux.',
			'settings.dvCompatibilityFallback' => 'Pilihan sandaran keserasian',
			'settings.dvCompatibilityFallbackDescription' => 'Gunakan pemapar standard jika eksperimen tidak dapat dimulakan. Data FEL mungkin hilang.',
			'settings.dvExperimentDiagnostics' => 'Pengelogan eksperimen video',
			'settings.dvExperimentDiagnosticsDescription' => 'Dayakan log pemain terperinci pada main balik seterusnya.',
			'settings.disableDolbyVision' => 'Penyelesaian Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Mainkan lapisan fail HDR10 atau HLG daripada Dolby Vision, apabila ia mempunyai lapisan',
			'settings.hdrSdrConversion' => 'HDR kepada SDR Konversi',
			'settings.hdrSdrConversionDescription' => 'Pilih apa yang menukar video HDR apabila paparan tidak boleh menunjukkan HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Kereta',
			'settings.hdrSdrConversionAutoDescription' => 'Peranti pada Android 9 dan seterusnya, pemain pada versi yang lebih tua',
			'settings.hdrSdrConversionDevice' => 'peranti',
			'settings.hdrSdrConversionDeviceDescription' => 'Perkakasan video peranti anda menukarnya. paling cepat, tetapi warna bergantung kepada peranti',
			'settings.hdrSdrConversionPlayer' => 'Pemain',
			'settings.hdrSdrConversionPlayerDescription' => 'Warna yang konsisten, tetapi 4K boleh menjejaskan kotak TV rendah',
			'settings.deinterlace' => 'Perbincangan',
			'settings.deinterlaceDescription' => 'Menghilangkan objek bercampur daripada video yang terhubung (mpv pemain sahaja)',
			'settings.deinterlaceOff' => 'keluar',
			'settings.deinterlaceOffDescription' => 'Tunjukkan video terhubung seperti ia dikodkan',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Tukar setiap medan ke dalam bingkai penuh. untuk video tangkapan untuk TV, seperti sukan, berita, dan konsert',
			'settings.deinterlaceFilm' => 'Filem',
			'settings.deinterlaceFilmDescription' => 'Memulihkan bingkai asal filem dan animasi telecined kepada 29.97 fps, biasa pada DVD NTSC. Video shot untuk TV stutters.',
			'settings.requireProfileSelectionOnOpen' => 'Mencari profil dalam app open',
			'settings.requireProfileSelectionOnOpenDescription' => 'Tunjukkan pemilihan profil setiap kali aplikasi dibuka',
			'settings.forceTvMode' => 'Kekuatan TV Mode',
			'settings.forceTvModeDescription' => 'Layout TV Force. untuk peranti yang tidak mendeteksi secara automatik. memerlukan pemulihan semula.',
			'settings.startInFullscreen' => 'Mulakan pada skrin penuh',
			'settings.startInFullscreenDescription' => 'Buka PlezyNG dalam mod skrin penuh pada pelancaran',
			'settings.exitFullscreenOnPlayerClose' => 'Ekran penuh keluar pada pemain tertutup',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Secara automatik keluar skrin penuh apabila menutup pemutar video',
			'settings.autoHidePerformanceOverlay' => 'Auto-Hide Perkhidmatan Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'Mengurangkan prestasi dengan kawalan playback',
			'settings.showNavBarLabels' => 'Tunjukkan Navigasi Bar Label',
			'settings.showNavBarLabelsDescription' => 'Menampilkan label teks di bawah ikon bar navigasi',
			'settings.startupSection' => 'Bahagian Startup',
			'settings.preferredServer' => 'Pelayan yang disukai',
			'settings.preferredServerDescription' => 'Prioriti hasil pelayan ini sambil mengekalkan setiap pelayan yang disambungkan.',
			'settings.preferredServerAutomatic' => 'automatik',
			'settings.showExploreTab' => 'Lihat Tab',
			'settings.showExploreTabDescription' => 'Tunjukkan tab Cari dengan kandungan daripada Plex Cari dan pengesan yang disambungkan',
			'settings.hideEmptyLibraries' => 'Menyembunyikan perpustakaan kosong',
			'settings.hideEmptyLibrariesDescription' => 'Menghilangkan perpustakaan dengan bilangan item yang dilaporkan oleh pelayan daripada sifar daripada navigasi.',
			'settings.liveTvDefaultFavorites' => 'Menerima saluran kegemaran',
			'settings.liveTvDefaultFavoritesDescription' => 'Menampilkan saluran kegemaran sahaja apabila membuka TV langsung',
			'settings.general' => 'Umum',
			'settings.generalDescription' => 'Bahasa, permulaan, dan tingkap tingkah laku',
			'settings.languageAndRegion' => 'Bahasa & Wilayah',
			'settings.startup' => 'Permulaan',
			'settings.display' => 'Papar',
			'settings.libraryAndCards' => 'Perpustakaan & Kartu',
			'settings.homeScreen' => 'Home » skrin',
			'settings.navigation' => 'Navigasi',
			'settings.window' => 'Jendela',
			'settings.liveTv' => 'TV Langsung',
			'settings.player' => 'Pemain',
			'settings.videoAndDisplay' => 'Video & Pameran',
			'settings.audio' => 'Audio yang',
			'settings.quality' => 'Kualiti',
			'settings.subtitles' => 'Sari kata',
			'settings.seekAndTiming' => 'Pencarian & Tempoh',
			'settings.behavior' => 'tingkah laku',
			'settings.gestures' => 'Gejala',
			'settings.gestureBrightnessSwipe' => 'Cahaya bersinar',
			'settings.gestureBrightnessSwipeDescription' => 'Tukar ke atas atau ke bawah pada tepi kiri untuk menyesuaikan kecerahan',
			'settings.gestureVolumeSwipe' => 'Jumlah Swipe',
			'settings.gestureVolumeSwipeDescription' => 'Tukar ke atas atau ke bawah pada tepi kanan untuk menyesuaikan volum',
			'settings.gesturePinchToZoom' => 'Pinch untuk Zoom',
			'settings.gesturePinchToZoomDescription' => 'Pin pada video untuk zoom dalam atau keluar',
			'settings.gestureSeekSwipe' => 'Mencari Swipe',
			'settings.gestureSeekSwipeDescription' => 'Beralih ke kiri atau kanan di mana-mana video untuk mencari; melepaskan untuk melompat',
			'settings.rememberBrightnessLevel' => 'Ingat tahap kecerahan',
			'settings.rememberBrightnessLevelDescription' => 'Mulakan playback pada kecerahan yang ditetapkan oleh swipe terakhir',
			'settings.controls' => 'kawalan',
			'settings.rememberPlayerChanges' => 'Ingat perubahan pemain',
			'settings.rememberPlayerChangesDescription' => 'Di mana perubahan yang dibuat semasa playback disimpan dan digunakan semula daripada',
			'settings.scopePlaybackSpeed' => 'Kelajuan Playback',
			'settings.scopeShaderPreset' => 'Perbincangan Shader Preset',
			'settings.scopeAspectRatio' => 'Nisbah aspek',
			'settings.scopeSyncOffsets' => 'Audio dan Subtitle Sync',
			'settings.playerScopeOff' => 'Jangan menyelamatkan',
			'settings.playerScopeGlobal' => 'Di mana-mana sahaja',
			'settings.playerScopeLibrary' => 'Per Perpustakaan',
			'settings.playerScopeTitle' => 'untuk persembahan atau filem',
			'settings.exportDialogTitle' => 'Eksport PlezyNG tetapan',
			'settings.followSystem' => 'Ikut sistem',
			'settings.followAppLanguage' => 'Ikut bahasa antara muka',
			'settings.regionFormat' => 'Format serantau',
			'settings.regionFormatDescription' => 'Pilih cara tarikh, nombor dan unit ukuran dipaparkan.',
			'settings.metadataLanguage' => 'Bahasa metadata',
			'settings.metadataLanguageDescription' => 'Bahasa tajuk dan huraian pilihan jika disokong oleh pelayan. Pilihan audio dan sari kata ditetapkan secara berasingan.',
			'settings.enterFullscreenOnPlaybackStart' => 'Masukkan skrin penuh apabila playback bermula',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Membuka video desktop dalam skrin penuh apabila playback bermula',
			'settings.extendVideoIntoDisplayCutout' => 'Memperluaskan video ke dalam display cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Biarkan video skrin penuh menggunakan kamera cutout pada telefon Android',
			'settings.languageDescription' => 'Pilih bahasa yang digunakan untuk kawalan dan mesej PlezyNG. sistem mengikuti bahasa peranti anda.',
			'settings.themeDescription' => 'Pilih warna dan kontras yang digunakan sepanjang aplikasi.',
			'settings.libraryDensityDescription' => 'Mengubah bilangan kad perpustakaan yang sesuai dalam setiap baris.',
			'settings.displayScaleDescription' => 'Mengembalikan antara muka pada paparan kereta ini tanpa mengubah saiz teks keseluruhan peranti anda.',
			'settings.themeSongVolumeDescription' => 'Tetapkan jumlah lagu tema berbanding dengan audio lain.',
			'settings.viewModeDescription' => 'Pilih sama ada item perpustakaan muncul sebagai poster dalam rangkaian atau sebagai senarai kompak.',
			'settings.gridViewDescription' => 'Menyusun item perpustakaan dalam baris dan lajur poster.',
			'settings.listViewDescription' => 'Tunjukkan item perpustakaan dalam senarai vertikal dengan lebih banyak teks per item.',
			'settings.gridSpacingDescription' => 'Menetapkan jurang antara poster dalam rangkaian perpustakaan.',
			'settings.gridSpacingTightDescription' => 'Menyesuaikan lebih banyak poster di seluruh skrin dengan jurang yang lebih kecil.',
			'settings.gridSpacingNormalDescription' => 'Gunakan jurang standard antara poster.',
			'settings.gridSpacingSpaciousDescription' => 'Tambah jurang yang lebih besar antara poster untuk lebih banyak pemisahan.',
			'settings.episodePosterModeDescription' => 'Pilih karya seni yang muncul pada kad episod.',
			'settings.seriesPosterDescription' => 'Gunakan poster siri untuk setiap episod.',
			'settings.seasonPosterDescription' => 'Gunakan poster musim untuk setiap episod apabila tersedia.',
			'settings.episodeThumbnailDescription' => 'Gunakan bingkai daripada episod apabila tersedia.',
			'settings.continueWatchingActionDescription' => 'Pilih apa yang berlaku apabila anda mengaktifkan Kad Pengawasan Berterusan.',
			'settings.continueWatchingPlayDescription' => 'Mulakan filem atau episod dengan segera.',
			'settings.continueWatchingDetailsDescription' => 'Buka halaman tajuk terlebih dahulu supaya anda boleh meninjau butiran dan pilih tindakan.',
			'settings.episodeActionDescription' => 'Pilih apa yang berlaku apabila anda mengaktifkan kad episod.',
			'settings.episodePlayDescription' => 'Mulakan episod ini dengan segera.',
			'settings.episodeDetailsDescription' => 'Buka halaman episod sebelum playback.',
			'settings.contentScreensaverDelayDescription' => 'Pilih berapa lama PlezyNG menunggu tanpa input sebelum menunjukkan karya seni.',
			'settings.continueWatchingRowSizeDescription' => 'Pilih seberapa besar kad yang terdapat dalam baris terus-menerus.',
			'settings.rowSizeCompactDescription' => 'Tunjukkan kad yang lebih kecil supaya lebih banyak item sesuai di sepanjang baris.',
			'settings.rowSizeStandardDescription' => 'Gunakan saiz kad standard.',
			'settings.rowSizeLargeDescription' => 'Tunjukkan kad yang lebih besar dengan lebih banyak butiran karya seni.',
			'settings.visualEffectsDescription' => 'Pilih anggaran animasi dan kesan seni untuk peranti ini.',
			'settings.visualEffectsFullDescription' => 'Gunakan kesan animasi dan seni penuh pada setiap peranti.',
			'settings.startupSectionDescription' => 'Pilih bahagian mana yang dibuka apabila PlezyNG bermula.',
			'settings.startupSectionOptions.discover' => 'Membuka cadangan dan item daripada sumber penemuan yang berkaitan.',
			'settings.startupSectionOptions.libraries' => 'Buka perpustakaan media yang disambungkan.',
			'settings.startupSectionOptions.liveTv' => 'Buka TV secara langsung apabila pelayan menyediakan ia; jika tidak, permulaan jatuh kembali ke Home.',
			'settings.startupSectionOptions.search' => 'Pencarian media terbuka.',
			'settings.smallSkipDurationDescription' => 'Tetapkan jarak yang dipindahkan oleh belakang pendek dan ke hadapan mencari kawalan.',
			'settings.largeSkipDurationDescription' => 'Tetapkan jarak yang dipindahkan oleh latar belakang panjang dan ke hadapan mencari kawalan.',
			'settings.rewindOnResumeDescription' => 'Move playback kembali dengan jumlah ini apabila mengembalikan video.',
			'settings.defaultSleepTimerDescription' => 'Tetapkan tempoh permulaan yang digunakan apabila anda memulakan jam tidur.',
			'settings.playNextCountdownDescription' => 'Tunggu ini lama sebelum memulakan episod set set kepada 0 untuk bermula dengan segera.',
			'settings.autoSkipDelaySettingDescription' => 'Ia terpakai apabila entri, kredit, atau iklan ditetapkan untuk melarikan diri secara automatik.',
			'settings.downmixCenterBoostDescription' => 'Meningkatkan dialog di saluran pusat apabila audio persekitaran dicampur ke bawah ke stereo.',
			'settings.displaySwitchDelayDescription' => 'Tunggu sebelum mengubah mod paparan supaya TV atau penerima boleh menyelesaikan peralihan terdahulu.',
			'settings.playerBackendDescription' => 'Pilih mana enjin playback yang memecahkan dan mengembalikan video pada peranti ini.',
			'settings.exoPlayerDescription' => 'Gunakan pemutar berasaskan Media3 asli Android dan laluan perkakasan yang disokong.',
			'settings.mpvDescription' => 'Gunakan mpv, yang mendedahkan pemutaran tambahan, subtitle, dan kawalan pemprosesan video.',
			'settings.scopeOffDescription' => 'Mengekalkan perubahan untuk sesi playback semasa sahaja.',
			'settings.scopeGlobalDescription' => 'Gunakan semula nilai yang sama untuk setiap perpustakaan dan tajuk.',
			'settings.scopeLibraryDescription' => 'Ingat nilai yang berasingan untuk setiap perpustakaan.',
			'settings.scopeTitleDescription' => 'Ingat nilai berasingan untuk setiap persembahan atau filem.',
			'settings.specialsOrderingServerDescription' => 'Simpan pesanan episod yang disediakan oleh pelayan media.',
			'settings.specialsOrderingAirDateDescription' => 'Letakkan istimewa di antara episod biasa mengikut tarikh udara mereka.',
			'settings.specialsOrderingLastDescription' => 'Letakkan setiap istimewa selepas musim biasa.',
			'settings.skipIntroModeDescription' => 'Pilih sama ada penanda intro memainkan secara normal, menunjukkan butang skip, atau skip secara automatik.',
			'settings.skipCreditsModeDescription' => 'Pilih sama ada kredit memainkan secara normal, menunjukkan butang skip, atau skip secara automatik.',
			'settings.skipAdsModeDescription' => 'Pilih sama ada iklan yang dikesan memainkan secara normal, menunjukkan butang skip, atau skip secara automatik.',
			'settings.playbackBufferAutoDescription' => 'Biarkan pemain aktif memilih saiz buffer biasa.',
			'settings.playbackBufferLargeDescription' => 'Tetap lebih banyak media bersedia sebelum playback; ini menggunakan lebih banyak memori.',
			'settings.playbackBufferExtraLargeDescription' => 'Mengekalkan buffer bacaan terbesar; ini menggunakan memori yang paling banyak.',
			'settings.defaultQualityDescription' => 'Setkan resolusi video lalai dan bitrate bumbung untuk aliran yang pelayan transcod.',
			'settings.cellularQualityDescription' => 'Override Kualiti lalai apabila peranti menggunakan sambungan selular sahaja.',
			'settings.remoteQualityDescription' => 'Override Kualiti lalai apabila menyambung ke pelayan melalui sambungan jauh.',
			'settings.qualityPresetOriginalDescription' => 'Mainkan sumber dalam kualiti yang tersedia tanpa meminta pelayan untuk menyalakan kodnya.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Tanya pelayan untuk aliran yang ditukar menggunakan resolusi dan bitrate yang dipaparkan di atas.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Gunakan kualiti yang dipilih dalam Kualiti lalai.',
			'settings.musicQualityDescription' => 'Tetapkan kadar bit audio maksimum yang diminta daripada pelayan; Original mengekalkan aliran sumber.',
			'settings.musicQualityOriginalDescription' => 'Mainkan audio sumber tanpa transcode bitrate-capped.',
			'settings.musicQualityTranscodeOptionDescription' => 'Meminta transcode pelayan yang dilapisi berhampiran kadar bit yang ditunjukkan di atas; output sebenar boleh berbeza-beza.',
			'settings.maxVolumeInputLabel' => 'Jumlah maksimum (%)',
			'settings.checkForUpdatesDescription' => 'Sekarang semak sama ada versi PlezyNG yang lebih baru boleh didapati.',
			'settings.appearanceDescription' => 'Pilih tema aplikasi dan menyesuaikan kad perpustakaan, baris rumah, dan navigasi.',
			'settings.prerollLibraryDescription' => 'Pilih perpustakaan yang mengandungi klip yang tersedia sebagai pre-rolls filem.',
			'settings.prerollSelectionDescription' => 'Pilih klip mana daripada perpustakaan yang dipilih boleh dimainkan sebelum filem.',
			'settings.contentScreensaverDelayOptionDescription' => 'Tunggu ini banyak minit tanpa input sebelum menunjukkan screensaver artwork.',
			'settings.videoCodecOptionDescription' => 'Membolehkan pemutaran langsung untuk kodek ini apabila disokong. kodek yang tidak disemak disulitkan oleh pelayan media.',
			'themeEditor.builtIn' => 'dibina dalam',
			'themeEditor.presets' => 'Persembahan',
			'themeEditor.custom' => 'Khas',
			'themeEditor.customEmpty' => 'belum dicipta',
			'themeEditor.editCustom' => 'Edit tema khas',
			'themeEditor.editCustomDescription' => 'Pilih setiap warna anda sendiri',
			'themeEditor.locked' => 'Akses seumur hidup diperlukan',
			'themeEditor.savedLocked' => 'Disimpan - boleh didapati dengan akses seumur hidup',
			'themeEditor.title' => 'Subjek Custom',
			'themeEditor.startFrom' => 'Bermula daripada',
			'themeEditor.startFromDescription' => 'Menyalin semua warna daripada tema lain',
			'themeEditor.colors' => 'warna',
			'themeEditor.preview' => 'Persiapan',
			'themeEditor.slots.bg' => 'latar belakang',
			'themeEditor.slots.surface' => 'permukaan',
			'themeEditor.slots.outline' => 'outline dalam',
			'themeEditor.slots.text' => 'teks',
			'themeEditor.slots.textMuted' => 'teks sekunder',
			'themeEditor.slots.accent' => 'Tumpuan',
			'themeEditor.opacity' => 'Ketidakpastian',
			'themeEditor.hexHint' => '#RRGGBB atau #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'daripada topik lain',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'Teks dalam latar belakang',
			'themeEditor.contrast.textOnSurface' => 'Teks di permukaan',
			'themeEditor.contrast.textMutedOnBg' => 'Teks sekunder pada latar belakang',
			'themeEditor.contrast.textMutedOnSurface' => 'Perkataan sekunder di permukaan',
			'themeEditor.contrast.accentOnBg' => 'Fokus pada latar belakang',
			'themeEditor.contrast.accentOnSurface' => 'Fokus pada permukaan',
			'themeEditor.contrast.labelOnAccent' => 'Button label pada aksen',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, di bawah yang disyorkan ${minimum}:1',
			'themeEditor.discardTitle' => 'Mengabaikan perubahan ?',
			'themeEditor.discardMessage' => 'Perubahan warna yang tidak disimpan akan hilang.',
			'themeEditor.discard' => 'Diskaun',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Perbincangan ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => 'Baki ${minutes} min',
			'themeEditor.previewSwitch' => 'Main automatik',
			'themeEditor.previewMutedText' => 'Artikel sekunder baca seperti ini',
			'themeEditor.themeSystemDescription' => 'Ikuti penampilan peranti anda dan beralih antara cahaya dan kegelapan secara automatik.',
			'themeEditor.themeLightDescription' => 'Gunakan latar belakang yang cerah dengan teks gelap.',
			'themeEditor.themeDarkDescription' => 'Gunakan latar belakang gelap dengan teks yang cerah.',
			'themeEditor.themeOledDescription' => 'Gunakan permukaan berwarna hitam yang mengurangkan cahaya pada skrin OLED.',
			'themeEditor.themeEmberDescription' => 'Gunakan warna merah hangat dan aksen amber.',
			'themeEditor.themeGlacierDescription' => 'Gunakan warna aksen biru sejuk.',
			'themeEditor.themeForestDescription' => 'Gunakan warna hijau dan aksen semulajadi.',
			'themeEditor.themePlumDescription' => 'Gunakan warna aksen violet dan plum.',
			'themeEditor.themePaperDescription' => 'Gunakan permukaan seperti kertas yang hangat dan warna yang diilhamkan tinta.',
			'themeEditor.themeCustomDescription' => 'Gunakan palet warna yang anda cipta dalam editor tema tersuai.',
			'themeEditor.editorDescription' => 'Pilih warna palet, menyesuaikan hue, kenyang, kecerahan, atau ketidakselesaan, dan lihat kemas kini pra-penglihatan sebelum simpan.',
			'search.hint' => 'Mencari filem, persembahan, muzik ...',
			'search.tryDifferentTerm' => 'Cuba istilah carian yang berbeza',
			'search.searchYourMedia' => 'Cari media anda',
			'search.enterTitleActorOrKeyword' => 'Masukkan tajuk, pelakon, atau kata kunci',
			'search.people' => 'Orang Melayu',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Set Shortcut untuk ${actionName}',
			'hotkeys.clearShortcut' => 'Pendekatan yang jelas',
			'hotkeys.noShortcutSet' => 'Tiada set pendek',
			'hotkeys.currentShortcut' => 'Pendekatan semasa :',
			'hotkeys.pressToRecord' => 'Pilih untuk mencatat singkatan',
			'hotkeys.recordingShortcut' => 'Tekan singkatan sekarang',
			'hotkeys.actions.playPause' => 'Bermain / beristirahat',
			'hotkeys.actions.volumeUp' => 'Volume ke atas',
			'hotkeys.actions.volumeDown' => 'Volume turun',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Mencari ke hadapan (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Mencari Kembali (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Menyertai Fullscreen',
			'hotkeys.actions.muteToggle' => 'Bersama Muta',
			'hotkeys.actions.subtitleToggle' => 'Menggabungkan Subtitle',
			'hotkeys.actions.audioTrackNext' => 'Seterusnya Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'Seterusnya Subtitle Track',
			'hotkeys.actions.chapterNext' => 'Bab seterusnya',
			'hotkeys.actions.chapterPrevious' => 'Bab sebelumnya',
			'hotkeys.actions.episodeNext' => 'Episod berikutnya',
			'hotkeys.actions.episodePrevious' => 'Episod Sebelumnya',
			'hotkeys.actions.speedIncrease' => 'Meningkatkan kelajuan',
			'hotkeys.actions.speedDecrease' => 'Mengurangkan kelajuan',
			'hotkeys.actions.speedReset' => 'Kembali ke kelajuan',
			'hotkeys.actions.zoomIn' => 'Zoom dalam',
			'hotkeys.actions.zoomOut' => 'Zoom keluar',
			'hotkeys.actions.zoomReset' => 'Mengubah Zoom',
			'hotkeys.actions.subSeekNext' => 'Cari untuk Subtitle berikutnya',
			'hotkeys.actions.subSeekPrev' => 'Mencari Subtitle Sebelumnya',
			'hotkeys.actions.subtitleDelayIncrease' => 'Penangguhan Subtitle',
			'hotkeys.actions.subtitleDelayDecrease' => 'Subtitle yang maju',
			'hotkeys.actions.shaderToggle' => 'Bersama Shaders',
			'hotkeys.actions.skipMarker' => 'Pinjaman / Pinjaman',
			'hotkeys.actions.screenshot' => 'Mengambil screenshot',
			'hotkeys.actions.framePrevious' => 'Frame yang lepas',
			'hotkeys.actions.frameNext' => 'Frame yang seterusnya',
			'fileInfo.title' => 'Maklumat fail',
			'fileInfo.overview' => 'Gambaran keseluruhan',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio yang',
			'fileInfo.subtitles' => 'Sari kata',
			'fileInfo.images' => 'imej tertanam',
			'fileInfo.dataStreams' => 'Aliran Data',
			'fileInfo.lyrics' => 'Lirik',
			'fileInfo.file' => 'Fail',
			'fileInfo.attachments' => 'Penyertaan',
			'fileInfo.delivery' => 'Penghantaran',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versi ${index} daripada ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Fail ${index} daripada ${count}',
			'fileInfo.noStreams' => 'Pelayan tidak melaporkan sebarang aliran untuk fail ini.',
			'fileInfo.copyPath' => 'Kopi laluan',
			'fileInfo.pathCopied' => 'Fail laluan disalin',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Tag Kodek',
			'fileInfo.resolution' => 'Resolusi',
			'fileInfo.codedResolution' => 'Resolusi Kod',
			'fileInfo.bitrate' => 'Perbezaan Bitrate',
			'fileInfo.frameRate' => 'Rata-rata kerangka',
			'fileInfo.rotation' => 'Rotasi',
			'fileInfo.comment' => 'Bagaimana',
			'fileInfo.audioDescription' => 'Audio Penerangan',
			'fileInfo.headerCompression' => 'Pengertian Kompresi',
			'fileInfo.sidecarFile' => 'Laporan Sidecar',
			'fileInfo.transportTimestamp' => 'Pengangkutan Timestamp',
			'fileInfo.displayOffset' => 'Perbincangan Offset',
			'fileInfo.previewFailureCode' => 'Kod Kegagalan Preview',
			'fileInfo.previewRetries' => 'Perbincangan Retries',
			'fileInfo.aspectRatio' => 'Nisbah aspek',
			'fileInfo.pixelAspectRatio' => 'Perbandingan Aspect Pixel',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Tahap',
			'fileInfo.bitDepth' => 'Kecil Kedalaman',
			'fileInfo.pixelFormat' => 'Pengenalan Pixel',
			'fileInfo.colorSpace' => 'Ruang warna',
			'fileInfo.colorRange' => 'Rangkaian warna',
			'fileInfo.colorPrimaries' => 'Warna primer',
			'fileInfo.colorTransfer' => 'Pemindahan warna',
			'fileInfo.chromaSubsampling' => 'Pengambilan Chroma',
			'fileInfo.chromaLocation' => 'Lokasi Chromium',
			'fileInfo.scanType' => 'Jenis pemindaian',
			'fileInfo.interlaced' => 'Terhubung',
			'fileInfo.anamorphic' => 'Anamorfisme',
			'fileInfo.referenceFrames' => 'Rangka rujukan',
			'fileInfo.dynamicRange' => 'Rangkaian Dinamik',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision Peringkat',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision Perbincangan',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision Lapisan',
			'fileInfo.baseLayerCompatibility' => 'Penyesuaian lapisan asas',
			'fileInfo.avcBitstream' => 'Perkhidmatan AVC Bitstream',
			'fileInfo.nalLengthSize' => 'NAL panjang saiz',
			'fileInfo.scalingMatrix' => 'Matriks Pengukuran Custom',
			'fileInfo.streamIdentifier' => 'Pengenalpastian Stream',
			'fileInfo.streamIndex' => 'Indeks aliran',
			'fileInfo.streamId' => 'Pengenalan ID',
			'fileInfo.language' => 'Bahasa Melayu',
			'fileInfo.languageCode' => 'Kod Bahasa',
			'fileInfo.streamTitle' => 'Tajuk Track',
			'fileInfo.channels' => 'Saluran',
			'fileInfo.sampleRate' => 'Kadar sampel',
			'fileInfo.spatialAudio' => 'Audio ruang',
			'fileInfo.textBased' => 'Perkataan berdasarkan',
			'fileInfo.subtitleFormat' => 'Pengenalan Format',
			'fileInfo.provider' => 'Pembekal',
			'fileInfo.matchScore' => 'Perlawanan skor',
			'fileInfo.externalDelivery' => 'Boleh disajikan secara berasingan',
			'fileInfo.sidecarPath' => 'Laluan Sidecar',
			'fileInfo.sourceStream' => 'Diterjemahkan daripada',
			'fileInfo.temporary' => 'sementara',
			'fileInfo.timeBase' => 'pangkalan masa',
			'fileInfo.overallBitrate' => 'Keseluruhan Bitrate',
			'fileInfo.path' => 'Jalan',
			'fileInfo.fileName' => 'Nama fail',
			'fileInfo.size' => 'Ukuran',
			'fileInfo.totalSize' => 'Jumlah keseluruhan',
			'fileInfo.container' => 'Kontainer',
			'fileInfo.duration' => 'tempoh',
			'fileInfo.previewThumbnails' => 'Gambaran keseluruhan Thumbnails',
			'fileInfo.previewIndex' => 'Indeks Pencapaian',
			'fileInfo.packetLength' => 'Panjang pakej',
			'fileInfo.filePresent' => 'fail yang hadir',
			'fileInfo.fileReadable' => 'boleh dibaca oleh server',
			'fileInfo.streamPath' => 'Laluan aliran',
			'fileInfo.optimizedForStreaming' => 'Optimisasi untuk Streaming',
			'fileInfo.has64bitOffsets' => 'Perbezaan 64-bit',
			'fileInfo.protocol' => 'Protokol',
			'fileInfo.mediaType' => 'Jenis Media',
			'fileInfo.sourceKind' => 'Sumber yang baik',
			'fileInfo.optimizedVersion' => 'Versi optimum',
			'fileInfo.optimizationTarget' => 'Matlamat Optimisasi',
			'fileInfo.deletedAt' => 'dihapuskan',
			'fileInfo.remoteSource' => 'Sumber Jarak Jauh',
			'fileInfo.infiniteStream' => 'Penghantaran Infinite Stream',
			'fileInfo.directPlay' => 'Permainan langsung',
			'fileInfo.directStream' => 'aliran langsung',
			'fileInfo.transcoding' => 'Transkod',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Pengenalan ID',
			'fileInfo.fileId' => 'Pengenalan ID',
			'fileInfo.defaultAudioTrack' => 'Pengenalan Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'Perbezaan Subtitle Track',
			'fileInfo.subtitlesOff' => 'keluar',
			'fileInfo.flagDefault' => 'Perkataan default',
			'fileInfo.flagForced' => 'Paksa',
			'fileInfo.flagSelected' => 'dipilih',
			'fileInfo.flagExternal' => 'luar',
			'fileInfo.flagHearingImpaired' => 'pendengaran yang rosak',
			'fileInfo.flagDub' => 'Duba',
			'fileInfo.flagOriginal' => 'asal',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Perbincangan:Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Tag: seperti yang dilihat',
			'mediaMenu.markAsUnwatched' => 'Tag: yang tidak dipantau',
			'mediaMenu.removeFromContinueWatching' => 'Menghapus daripada terus menonton',
			'mediaMenu.viewDetails' => 'Lihat butiran',
			'mediaMenu.goToSeries' => 'Pergi ke siri',
			'mediaMenu.shufflePlay' => 'Permainan Shuffle',
			'mediaMenu.shuffleNotAvailableOffline' => 'Shuffle tidak boleh didapati offline',
			'mediaMenu.fileInfo' => 'Maklumat fail',
			'mediaMenu.deleteEpisodeFromServer' => 'Menghapuskan episod daripada server',
			'mediaMenu.deleteSeasonFromServer' => 'Menghapuskan musim daripada server',
			'mediaMenu.deleteShowFromServer' => 'Menghapuskan paparan daripada server',
			'mediaMenu.deleteMovieFromServer' => 'Menghapuskan filem daripada pelayan',
			'mediaMenu.deleteEpisodeTitle' => 'Adakah anda menghapuskan episod ini?',
			'mediaMenu.deleteSeasonTitle' => 'Hentikan musim ini?',
			'mediaMenu.deleteShowTitle' => 'Hentikan persembahan ini?',
			'mediaMenu.deleteMovieTitle' => 'Adakah anda memadamkan filem ini?',
			'mediaMenu.deleteEpisodeConfirm' => 'menghapuskan episod',
			'mediaMenu.deleteSeasonConfirm' => 'Hilang Musim',
			'mediaMenu.deleteShowConfirm' => 'Menghapuskan persembahan',
			'mediaMenu.deleteMovieConfirm' => 'Menghapus filem',
			'mediaMenu.deleteAnyway' => 'Menghapuskan bagaimanapun',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Permanen menghapuskan ${title} daripada pelayan anda?',
			'mediaMenu.deleteMultipleWarning' => 'Ini termasuk semua episod dan fail mereka.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: 'Ini memadamkan semua ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episod di dalamnya, dan fail mereka.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: 'Item ini disimpan melalui fail ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dan semua akan dipadamkan.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episod lain disimpan dalam fail yang sama dan juga akan dipadamkan:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG tidak dapat memeriksa fail yang akan dipadamkan, jadi lebih daripada item yang dinyatakan di atas mungkin dipadamkan. Batalkan dan cuba lagi, atau padamkan juga.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Pelayan anda tidak memberikan butiran fail untuk item ini, jadi PlezyNG tidak dapat memeriksa fail yang akan dipadamkan. Lebih daripada item yang dinyatakan di atas mungkin dipadamkan.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media item dihapuskan dengan berjaya',
			'mediaMenu.mediaFailedToDelete' => 'gagal menghapuskan item media',
			'mediaMenu.rate' => 'Kadar',
			'mediaMenu.playFromBeginning' => 'Bermain dari awal',
			'mediaMenu.playVersion' => 'Bermain versi ...',
			'rateSheet.title' => 'Kadar',
			'rateSheet.server' => 'Pelayan',
			'rateSheet.favorite' => 'Kegemaran',
			'rateSheet.favorited' => 'kegemaran',
			'rateSheet.saved' => 'diselamatkan',
			'rateSheet.notAvailable' => 'Tiada perlawanan ditemui',
			'rateSheet.noConnectedServices' => 'Sambungkan perkhidmatan dalam Settings untuk menilai di sana.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, filem',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, rancangan televisyen',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'Pengawasan',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} peratus dilihat',
			'accessibility.mediaCardUnwatched' => 'belum ditonton',
			'accessibility.tapToPlay' => 'Tap untuk bermain',
			'accessibility.decrease' => 'Penurunan',
			'accessibility.increase' => 'Meningkat',
			'accessibility.decreaseValue' => ({required Object label}) => 'Pengurangan ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Peningkatan ${label}',
			'accessibility.hue' => 'Hue',
			'accessibility.saturation' => 'Saturasi',
			'accessibility.brightness' => 'cahaya terang',
			'accessibility.hexColor' => 'Warna Hex',
			'accessibility.expandText' => 'Meningkatkan teks',
			'accessibility.collapseText' => 'Teks yang runtuh',
			'accessibility.alphabetNavigation' => 'Alphabet navigasi',
			'accessibility.alphabetScrollHint' => 'Leret ke atas atau ke bawah untuk bergerak mengikut huruf',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Laluan ${row} daripada ${rowCount}, lajur ${column} daripada ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Laluan ${row} daripada ${rowCount}',
			'accessibility.autoScrollPlay' => 'Permainan dalam Auto-Scroll',
			'accessibility.autoScrollPause' => 'Perbezaan Auto-Scroll',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S S',
			'accessibility.valueShort' => 'V dalam',
			'accessibility.red' => 'Merah',
			'accessibility.green' => 'hijau',
			'accessibility.blue' => 'Biru',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Aksesibiliti',
			'accessibility.summary' => 'teks, kontras, pergerakan dan kawalan',
			'accessibility.systemHint' => 'Seting aksesibiliti peranti anda sentiasa terpakai. pilihan ini menambah penyesuaian sepanjang PlezyNG.',
			'accessibility.readability' => 'Pembacaan dan penglihatan',
			'accessibility.textSize' => 'Saiz teks tambahan',
			'accessibility.preview' => 'Baca, dengar dan lihat pada kelajuan anda sendiri.',
			'accessibility.boldText' => 'Perbezaan antara muka teks',
			'accessibility.highContrast' => 'kontras yang tinggi',
			'accessibility.highContrastHint' => 'Teks yang lebih kuat, outlines dan fokus indikator pada permukaan cahaya atau gelap.',
			'accessibility.interaction' => 'Pergerakan dan interaksi',
			'accessibility.reduceMotion' => 'Mengurangkan gerakan',
			'accessibility.reduceMotionHint' => 'Hentikan animasi penunjuk fokus, peralihan halaman dan kesan hiasan.',
			'accessibility.largeTargets' => 'Target sentuhan yang lebih besar',
			'accessibility.largeTargetsHint' => 'Memberi kawalan berkongsi lebih banyak ruang untuk sentuhan dan navigasi bantuan.',
			'accessibility.navigationHint' => 'Gunakan Tab dan Shift+Tab untuk bergerak antara kawalan, Enter atau Space untuk mengaktifkan, dan Escape atau butang Kembali untuk menutup. Zum dan keutamaan bacaan tersedia semasa buku dibuka.',
			'accessibility.textSizeDescription' => 'Skala antara muka teks dalam PlezyNG di samping tetapan saiz teks sistem peranti anda.',
			'accessibility.boldTextHint' => 'Gunakan berat yang lebih berat untuk label antara muka dan mesej untuk memudahkan mereka untuk membezakan.',
			'tooltips.shufflePlay' => 'Permainan Shuffle',
			'tooltips.playTrailer' => 'Bermain Trailer',
			'tooltips.markAsWatched' => 'Mark yang dilihat',
			'tooltips.markAsUnwatched' => 'Tag: tidak dipantau',
			'audioTracks.track' => ({required Object n}) => 'Perbincangan:Audio Track ${n}',
			'videoControls.audioLabel' => 'Audio yang',
			'videoControls.subtitlesLabel' => 'Sari kata',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Kotak Surat',
			'videoControls.fillScreen' => 'Mengisi skrin',
			'videoControls.stretch' => 'Regang',
			'videoControls.lockRotation' => 'Lock rotasi',
			'videoControls.unlockRotation' => 'Menghapuskan rotasi',
			'videoControls.timerActive' => 'Aktiviti Aktiviti',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Playback akan berhenti pada ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Akhir daripada video semasa',
			'videoControls.sleepTimerStopAtHeader' => 'Berhenti untuk',
			'videoControls.sleepTimerDurationHeader' => 'Masa yang',
			'videoControls.playbackWillPauseAtEnd' => 'Playback Akan Berhenti Pada Akhir Video Ini',
			'videoControls.stillWatching' => 'Masih boleh tengok?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Berhenti dalam ${seconds}s',
			'videoControls.continueWatching' => 'teruskan',
			'videoControls.autoPlayNext' => 'Auto-Play yang seterusnya',
			'videoControls.playNext' => 'Bermain seterusnya',
			'videoControls.playButton' => 'Bermain',
			'videoControls.pauseButton' => 'Henti Sejenak',
			'videoControls.playbackPaused' => 'beristirahat',
			'videoControls.playbackResumed' => 'Bermain',
			'videoControls.loadingVideo' => 'Penghantaran Video',
			'videoControls.showPlaybackControls' => 'Menunjukkan kawalan playback',
			'videoControls.hidePlaybackControls' => 'Menggunakan Playback Control',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Mencari ke belakang ${seconds} saat',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Mencari ke hadapan ${seconds} saat',
			'videoControls.previousButton' => 'episod terdahulu',
			'videoControls.nextButton' => 'Episod seterusnya',
			'videoControls.previousChapterButton' => 'Bab sebelumnya',
			'videoControls.nextChapterButton' => 'Bab seterusnya',
			'videoControls.muteButton' => 'Mutu',
			'videoControls.unmuteButton' => 'Tidak banyak',
			'videoControls.settingsButton' => 'Pengaturan Playback',
			'videoControls.tracksButton' => 'Audio dan Subtitle',
			'videoControls.chaptersButton' => 'Bab yang',
			'videoControls.segmentLoopHelp' => 'Setkan A, kemudian setkan B kemudian dalam garis masa.',
			'videoControls.setLoopStart' => 'Set loop permulaan (A)',
			'videoControls.setLoopEnd' => 'Set loop akhir (B)',
			'videoControls.clearSegmentLoop' => 'Segmen yang jelas',
			'videoControls.setLoopStartFirst' => 'Set loop permulaan (A) sebelum akhir (B).',
			'videoControls.loopEndAfterStart' => 'Tarikh akhir mesti lebih lambat daripada permulaan.',
			'videoControls.segmentLoopUnavailable' => 'Segment looping tidak tersedia untuk playback ini.',
			'videoControls.loopPointNotSet' => 'Tidak menetapkan',
			'videoControls.bookmarksHelp' => 'Tanda-tanda buku disimpan pada peranti ini. pilih satu untuk pergi ke masa itu.',
			'videoControls.bookmarksButton' => 'Buku-buku yang',
			'videoControls.chaptersAndBookmarks' => 'Bab dan Bookmark',
			'videoControls.segmentLoop' => 'Perbezaan segmen',
			'videoControls.addBookmark' => 'Menambah Bookmark',
			'videoControls.bookmarkName' => 'Nama Bookmark',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'Sebagai contoh, adegan pembukaan',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Perpustakaan ${n}',
			'videoControls.bookmarkNameRequired' => 'Masukkan nama untuk buku ini.',
			'videoControls.deleteBookmark' => 'Menghapuskan Bookmark',
			'videoControls.bookmarkLimitReached' => 'Artikel ini sudah mempunyai 100 buku.',
			'videoControls.bookmarkUnavailable' => 'Saya tidak boleh menyimpan atau menghapuskan buku ini.',
			'videoControls.bookmarkSaved' => 'Bookmark diselamatkan',
			'videoControls.bookmarkDeleted' => 'Bookmark telah dihapuskan.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Tarikan titik ${point} Set untuk ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'Tiada bab atau buku-buku yang tersedia.',
			'videoControls.versionQualityButton' => 'Versi & Kualiti',
			'videoControls.versionColumnHeader' => 'Versi',
			'videoControls.qualityColumnHeader' => 'Kualiti',
			'videoControls.qualityOriginal' => 'asal',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcoding tidak tersedia - bermain kualiti asal',
			'videoControls.subtitleUnavailableFallback' => 'Subtitle yang dipilih tidak boleh dimuat naik - berterusan tanpa subtitle',
			'videoControls.pipButton' => 'Gambar dalam mode',
			'videoControls.aspectRatioButton' => 'Nisbah aspek',
			'videoControls.ambientLighting' => 'Lampu persekitaran',
			'videoControls.fullscreenButton' => 'Masuk skrin penuh',
			'videoControls.exitFullscreenButton' => 'Keluarkan skrin penuh',
			'videoControls.alwaysOnTopButton' => 'Selalu di atas',
			'videoControls.rotationLockButton' => 'Lencana Rotasi',
			'videoControls.lockScreen' => 'Menutup skrin',
			'videoControls.screenLockButton' => 'Penutup skrin',
			'videoControls.timelineSlider' => 'Tarikh video',
			'videoControls.volumeSlider' => 'Tahap Volume',
			'videoControls.endsAt' => ({required Object time}) => 'Berakhir pada ${time}',
			'videoControls.pipActive' => 'Bermain dalam Picture-in-Picture',
			'videoControls.pipFailed' => 'Gambar-gambar dalam gagal bermula',
			'videoControls.screenshotSaved' => 'Screenshot disimpan',
			'videoControls.screenshotFailed' => 'Tidak boleh mengambil screenshot',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zum ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Kelantangan ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Memerlukan Android 8.0 atau lebih baru',
			'videoControls.pipErrors.iosVersion' => 'Memerlukan iOS 15.0 atau lebih baru',
			'videoControls.pipErrors.permissionDisabled' => 'Gambar-gambar dalam disekat. ia boleh didayakan dalam tetapan sistem.',
			'videoControls.pipErrors.notSupported' => 'Peranti tidak menyokong mod imej dalam imej',
			'videoControls.pipErrors.voSwitchFailed' => 'gagal untuk menukar output video untuk imej-dalam-gambar',
			'videoControls.pipErrors.failed' => 'Gambar-gambar dalam gagal bermula',
			'videoControls.pipErrors.prepareFailed' => 'Gambar-gambar dalam tidak boleh disediakan',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Kesilapan yang berlaku: ${error}',
			'videoControls.chapters' => 'Bab yang',
			'videoControls.noChaptersAvailable' => 'Tiada bab yang tersedia',
			'videoControls.queue' => 'Perbincangan',
			'videoControls.noQueueItems' => 'Tiada item dalam Queue',
			'videoControls.noAudioDevicesAvailable' => 'Tiada peranti audio yang tersedia',
			'videoControls.searchSubtitles' => 'Pencarian Subtitle',
			'videoControls.language' => 'Bahasa Melayu',
			'videoControls.noSubtitlesFound' => 'Tiada subtitle yang ditemui',
			'videoControls.subtitleDownloaded' => 'Subtitle dikurangkan',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle telah dimuat turun, tetapi tidak boleh dipilih',
			'videoControls.subtitleDownloadFailed' => 'Tidak boleh download subtitle',
			'videoControls.searchLanguages' => 'Pencarian Bahasa...',
			'videoControls.skipIntro' => 'Lapangan Terbang Intro',
			'videoControls.skipCredits' => 'Melompat kredit',
			'videoControls.nextEpisode' => 'Episod berikutnya',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Lapangan Terbang ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Tajuk : ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Perkh<unk> yang diperlukan)',
			'videoControls.osdSubtitlesOff' => 'Tajuk : Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Tajuk : ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Perbincangan : ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} penghalang', ), 
			'videoControls.trackSelectionTitle' => 'Pilih trek sebelum playback',
			'videoControls.trackSelectionAuto' => 'Pemilihan automatik',
			'videoControls.openMiniPlayer' => 'Permainan Mini Terbuka',
			'videoControls.returnToFullPlayer' => 'Kembali kepada pemain penuh',
			'videoControls.loadSubtitleFile' => 'Mengisi subtitle fail ...',
			'videoControls.subtitleLoadFailed' => 'gagal untuk memuat turun subtitle fail',
			'videoControls.skipAds' => 'Laporan Ads',
			'videoControls.tapToUnlock' => 'Ketik untuk membuka kunci',
			'videoControls.tapAgainToUnlock' => 'Ketik sekali lagi untuk membuka kunci',
			'messages.markedAsWatched' => 'Ditandakan seperti yang dilihat',
			'messages.markedAsUnwatched' => 'Ditandakan sebagai tidak diperhatikan',
			'messages.markedAsWatchedOffline' => 'Menandakan seperti yang dilihat (sinkronkan apabila dalam talian)',
			'messages.markedAsUnwatchedOffline' => 'Ditandakan sebagai tidak dipantau (sinkronkan apabila dalam talian)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Pengeluaran : ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dilihat muat turun', ), 
			'messages.removedFromContinueWatching' => 'Menghapus daripada terus menonton',
			'messages.errorLoading' => ({required Object error}) => 'Kesilapan : ${error}',
			'messages.searchPartialResults' => 'Sesetengah pelayan media tidak boleh dicari. menunjukkan hasil yang tersedia.',
			'messages.streamInterrupted' => 'Aliran telah dihentikan. bermain percetakan atau cuba untuk berundur.',
			'messages.liveStreamInterrupted' => 'siaran langsung telah dihentikan. siaran akhbar untuk retry.',
			'messages.fileInfoNotAvailable' => 'Maklumat fail tidak tersedia',
			'messages.playbackAuthenticationRequired' => 'Mendaftar masuk ke pelayan media sekali lagi untuk memainkan item ini.',
			'messages.playbackServerUnavailable' => 'Server media tidak tersedia. cuba lagi kemudian.',
			'messages.playbackDataInvalid' => 'Pelayan mengembalikan maklumat playback yang tidak sah.',
			'messages.playbackCancelled' => 'Playback telah dibatalkan.',
			'messages.playbackFailed' => 'Playback tidak boleh dimulakan.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback tidak boleh dimulakan: ${error}',
			'messages.audioOutputFailed' => 'Periksa sambungan audio TV atau penerima; jika aplikasi lain tidak mempunyai bunyi sama sekali, mulakan semula peranti.',
			'messages.mediaUnavailable' => 'Kandungan ini tidak lagi tersedia.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fail pengecasan kesilapan info: ${error}',
			'messages.errorLoadingSeries' => 'Kesilapan siri pengisian',
			'messages.musicNotSupported' => 'Playback muzik belum disokong',
			'messages.noDescriptionAvailable' => 'Tiada penerangan yang tersedia',
			'messages.noProfilesAvailable' => 'Tiada profil yang tersedia',
			'messages.contactAdminForProfiles' => 'Hubungi pentadbir pelayan anda untuk menambah profil',
			'messages.unableToDetermineLibrarySection' => 'Tidak dapat menentukan bahagian perpustakaan untuk item ini',
			'messages.logsCleared' => 'Log yang dibersihkan',
			'messages.logsCopied' => 'Logs disalin ke clipboard',
			'messages.noLogsAvailable' => 'Tiada log yang tersedia',
			'messages.libraryScanning' => ({required Object title}) => 'Mengimbas “${title}”',
			'messages.libraryScanStarted' => ({required Object title}) => 'Perpustakaan pemindaian bermula untuk "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Kegagalan untuk memindai perpustakaan: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Mengemaskini metadata untuk "${title}" ...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadata pembaharuan bermula untuk "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Tidak dapat memperbaharui metadata: ${error}',
			'messages.logoutConfirm' => 'Adakah anda pasti anda mahu log keluar?',
			'messages.noSeasonsFound' => 'Tiada musim yang ditemui',
			'messages.seasonsLoadFailed' => 'Tidak boleh mengisi musim',
			'messages.noEpisodesFound' => 'Tiada episod yang ditemui pada musim pertama',
			'messages.noEpisodesFoundGeneral' => 'Tiada episod yang ditemui',
			'messages.episodesLoadFailed' => 'Tidak boleh memuatkan episod',
			'messages.noResultsFound' => 'Tiada hasil yang ditemui',
			'messages.sleepTimerSet' => ({required Object label}) => 'Jam tidur set untuk ${label}',
			'messages.noItemsAvailable' => 'Tiada item yang tersedia',
			'messages.failedToCreatePlayQueueNoItems' => 'gagal untuk mencipta permainan kue - tiada item',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kegagalan ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Menukar kepada pemain yang kompatibel ...',
			'messages.serverLimitTitle' => 'Playback gagal',
			'messages.serverLimitBody' => 'Kesilapan pelayan (HTTP 500). had lebar jalur/transcoding mungkin menolak sesi ini.',
			'messages.mediaUnreadableTitle' => 'fail yang tidak tersedia',
			'messages.mediaUnreadableBody' => 'Pelayan mendapati item ini tetapi tidak dapat membaca failnya (HTTP 404). fail itu mungkin telah dipindahkan, dipadamkan, atau penyimpanan adalah offline.',
			'messages.serverBusyTitle' => 'aliran tidak tersedia',
			'messages.serverBusyBody' => 'Pelayan tetap enggan untuk menyiarkan fail ini (HTTP 503). ia boleh memulakan semula, sibuk, atau penyimpanan fail mungkin offline. cuba lagi dalam sekejap - jika ia terus berlaku, minta pemilik pelayan untuk memeriksa pelayan dan penyimpanan fail.',
			'messages.playbackNotAllowedTitle' => 'Playback tidak dibenarkan',
			'messages.playbackNotAllowedBody' => 'Pelayan menolak untuk menyiarkan item ini (HTTP 403). akaun anda mungkin tidak dibenarkan untuk memainkannya, atau pelayan hanya boleh membenarkan pemutaran pada rangkaian tempatan.',
			'messages.logsUploaded' => 'Log yang diunggah',
			'messages.logsUploadFailed' => 'Kegagalan untuk memuat naik log',
			'messages.logId' => 'Pengenalan ID',
			'messages.burnedSubtitlesUseMenu' => 'Subtitle dibakar ke dalam aliran ini. tukar mereka daripada menu subtitle.',
			'messages.noVideoUrl' => 'Tiada URL video yang tersedia',
			'messages.playbackNoMediaSources' => 'Server tidak mengembalikan sumber media yang boleh dimainkan',
			'messages.playbackDataNotPrepared' => 'Playback bermula sebelum data telah siap.',
			'messages.streamSelectionUnavailable' => 'Stream Selection tidak tersedia untuk sumber ini',
			'messages.streamSelectionFailed' => 'Tidak boleh menggunakan aliran yang dipilih',
			'messages.trackSelectionNotRemembered' => 'Pilihan trek ini hanya terpakai kepada playback semasa.',
			'messages.serverUnavailableForProfile' => 'Tiada pelayan boleh didapati untuk profil aktif',
			'subtitlingStyling.previewSample' => 'Tag: anjing coklat cepat melompat ke atas anjing lazy',
			'subtitlingStyling.text' => 'teks',
			'subtitlingStyling.border' => 'Perbatasan',
			'subtitlingStyling.background' => 'latar belakang',
			'subtitlingStyling.fontSize' => 'Tag: saiz font',
			'subtitlingStyling.textColor' => 'Warna teks',
			'subtitlingStyling.borderSize' => 'Perbatasan saiz',
			'subtitlingStyling.borderColor' => 'Warna Perbatasan',
			'subtitlingStyling.backgroundOpacity' => 'Latar Belakang Opacity',
			'subtitlingStyling.backgroundColor' => 'warna latar belakang',
			'subtitlingStyling.position' => 'Kedudukan',
			'subtitlingStyling.assOverride' => 'ASS Perbezaan',
			'subtitlingStyling.overrideScale' => 'skala',
			'subtitlingStyling.overrideForce' => 'Kekuatan',
			'subtitlingStyling.overrideStrip' => 'Menghapuskan styling',
			'subtitlingStyling.positionTop' => 'Top',
			'subtitlingStyling.positionBottom' => 'Bawah',
			'subtitlingStyling.useMargins' => 'Menggunakan margin',
			'subtitlingStyling.useMarginsDescription' => 'Biarkan subtitle teks di dalam ruang di luar video. subtitle bergaya boleh mengekalkan penempatan asal mereka.',
			'subtitlingStyling.anchorToScreen' => 'Anchor untuk skrin',
			'subtitlingStyling.anchorToScreenDescription' => 'Tunjukkan subtitle teks dalam bar hitam di bawah video skrin lebar',
			'subtitlingStyling.bold' => 'berani',
			'subtitlingStyling.italic' => 'Bahasa Itali',
			'subtitlingStyling.renderResolution' => 'Resolusi Render',
			'subtitlingStyling.renderResolutionScreen' => 'resolusi skrin',
			'subtitlingStyling.renderResolutionVideo' => 'Video resolusi',
			'subtitlingStyling.fontSizeDescription' => 'Setkan saiz teks subtitle pada peranti ini.',
			'subtitlingStyling.textColorDescription' => 'Pilih warna yang digunakan untuk teks subtitle.',
			'subtitlingStyling.borderSizeDescription' => 'Tetapkan ketebalan outline di sekeliling teks subtitle.',
			'subtitlingStyling.borderColorDescription' => 'Pilih warna yang digunakan untuk subtitle outline.',
			'subtitlingStyling.backgroundColorDescription' => 'Pilih warna di sebalik subtitle teks.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Tetapkan betapa telus latar belakang subtitle ialah: 0% jelas dan 100% kukuh.',
			'subtitlingStyling.positionDescription' => 'Pergerakan subtitle secara vertikal. 0% adalah bahagian atas video dan 100% adalah bahagian bawah.',
			'subtitlingStyling.assOverrideDescription' => 'Pilih sama ada pemain mengikuti, menyesuaikan, menggantikan atau menghapuskan gaya yang dimasukkan ke dalam subtitle ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Simpan huruf, warna, saiz, dan kedudukan yang ditulis dalam fail subtitle.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Membolehkan tetapan gaya subtitle pemain untuk menyesuaikan subtitle ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Gunakan gaya pemain dan skala saiz tertanam untuk memenuhi dimensi video.',
			'subtitlingStyling.assOverrideOptions.force' => 'Menggantikan gaya ASS yang tertanam dengan gaya subtitle pemain.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Menghilangkan format ASS terbina dalam dan membuat subtitle teks dengan jelas.',
			'subtitlingStyling.renderResolutionDescription' => 'Pilih resolusi yang digunakan untuk rasterize imej dan subtitle ASS. Skala Android yang lebih rendah boleh mengurangkan kerja rendering tetapi kelihatan lebih lembut.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render pada resolusi permukaan paparan penuh untuk hasil yang paling tajam.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render menggunakan resolusi video sebagai rujukan, yang boleh mengurangkan kerja pada paparan resolusi tinggi.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Rendah pada 75% daripada resolusi permukaan paparan untuk penjimatan prestasi yang sederhana.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Rendah pada 50% daripada resolusi permukaan paparan untuk mengurangkan kerja, dengan tepi yang lebih lembut.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render pada satu pertiga daripada resolusi permukaan paparan untuk mengurangkan kerja, dengan tepi yang lebih lembut.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render pada satu perempat daripada resolusi permukaan paparan untuk mengurangkan kerja, dengan hasil yang paling lembut.',
			'subtitlingStyling.boldDescription' => 'Menarik teks subtitle dalam berat yang lebih berat.',
			'subtitlingStyling.italicDescription' => 'Menarik subtitle teks dalam bahasa Itali.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Pengaturan pemutar video lanjutan',
			'mpvConfig.presets' => 'Persembahan',
			'mpvConfig.noPresets' => 'Tiada preset yang diselamatkan',
			'mpvConfig.saveAsPreset' => 'Menyelamatkan sebagai preset',
			'mpvConfig.presetName' => 'Nama Praset',
			'mpvConfig.presetNameHint' => 'Masukkan nama untuk preset ini',
			'mpvConfig.loadPreset' => 'Pengangkutan',
			'mpvConfig.deletePreset' => 'Padam',
			'mpvConfig.presetSaved' => 'Preset selamatkan',
			'mpvConfig.presetLoaded' => 'Preset dikendalikan',
			'mpvConfig.presetDeleted' => 'Preset telah dihapuskan',
			'mpvConfig.confirmDeletePreset' => 'Adakah anda pasti anda mahu memadamkan preset ini?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # komen',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Tambah garis',
			'mpvConfig.removeLine' => 'Menghilangkan garis',
			'mpvConfig.embeddedVoHint' => 'vo, konteks gpu dan gpu-api diabaikan pada Linux: video tertanam sentiasa mengalir melalui vo=libmpv pada pesawat video, dan gpu-next (yang bayangan komputer seperti ArtCNN perlu) tidak boleh berjalan tertanam.',
			'dialog.confirmAction' => 'Mengesahkan tindakan',
			'profiles.addPlezyProfile' => 'Menambah PlezyNG profil',
			'profiles.switchingProfile' => 'Menukar profil ...',
			'profiles.deleteThisProfileTitle' => 'Menghapuskan profil ini?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Menghapus ${displayName}. sambungan tidak terjejas.',
			'profiles.active' => 'Aktiviti',
			'profiles.manage' => 'Pengurusan',
			'profiles.delete' => 'Padam',
			'profiles.signOut' => 'Sign out',
			'profiles.signOutPlexTitle' => 'Mendaftar keluar daripada Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Menghapuskan ${displayName} dan semua Plex Pengguna Rumah?',
			'profiles.signOutPlexDeleteDownloads' => 'Juga menghapuskan download',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Jika tidak, mereka akan kekal pada peranti ini dan kembali apabila anda mendaftar kembali ke akaun ini.',
			'profiles.signedOutPlex' => 'Ditandatangani daripada Plex.',
			'profiles.signOutFailed' => 'Menandatangani gagal',
			'profiles.sectionTitle' => 'Profil',
			'profiles.summarySingle' => 'Menambah profil untuk mencampur pengguna yang dikendalikan dan identiti tempatan',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profil · aktif: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} Profil',
			'profiles.removeConnectionTitle' => 'Menghapuskan sambungan?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Menghapuskan akses ${displayName} ke ${connectionLabel}. profil lain menyimpannya.',
			'profiles.deleteProfileTitle' => 'Menghapuskan profil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Menghapuskan ${displayName} dan sambungan. pelayan kekal tersedia.',
			'profiles.profileNameLabel' => 'Nama Profil',
			'profiles.pinProtectionLabel' => 'Perlindungan PIN',
			'profiles.copyAutomationLink' => 'Salinan Android pautan automatik',
			'profiles.copyAutomationLinkDescription' => 'Pilih profil ini daripada niat atau automatik Android. pemeriksaan PIN profil masih terpakai.',
			'profiles.automationLinkCopied' => 'Profil automatik pautan disalin.',
			'profiles.pinManagedByPlex' => 'PIN dikendalikan oleh Plex. Edit di plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Tidak ada set PIN. Untuk memerlukan satu, mengedit pengguna rumah di plex.tv.',
			'profiles.setPin' => 'Menyediakan PIN',
			'profiles.setPinTitle' => 'Menyediakan PIN',
			'profiles.confirmPinTitle' => 'Mengesahkan PIN',
			'profiles.pinSet' => 'Pin set',
			'profiles.changePin' => 'Perubahan',
			'profiles.removePin' => 'Keluarkan',
			'profiles.connectionsLabel' => 'sambungan',
			'profiles.add' => 'Tambah',
			'profiles.deleteProfileButton' => 'Menghapuskan profil',
			'profiles.noConnectionsHint' => 'Tiada sambungan - tambahkan satu untuk menggunakan profil ini.',
			'profiles.noConnections' => 'Tiada sambungan',
			'profiles.plexHomeAccount' => 'Plex Akaun rumah',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex akaun: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} melalui ${account}',
			'profiles.connectionDefault' => 'Perkataan default',
			'profiles.connectionAs' => ({required Object displayName}) => 'daripada ${displayName}',
			'profiles.makeDefault' => 'Menjadikan default',
			'profiles.removeConnection' => 'Keluarkan',
			'profiles.profileRenamed' => 'Profil yang dinamakan semula.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Menambah kepada ${displayName}',
			'profiles.borrowExplain' => 'Pinjaman sambungan profil lain. profil yang dilindungi PIN memerlukan PIN.',
			'profiles.borrowEmpty' => 'Tiada apa-apa lagi yang boleh dipinjam.',
			'profiles.borrowEmptySubtitle' => 'Sambungkan Plex, Jellyfin, atau Emby kepada profil lain terlebih dahulu.',
			'profiles.borrowLoadFailed' => 'sambungan yang tersedia tidak boleh dimuat naik. cuba lagi.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'daripada ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'sambungan yang dipinjam.',
			'profiles.borrowFailed' => 'Tidak berjaya meminjamkan sambungan.',
			'profiles.incorrectPin' => 'Pin yang tidak betul',
			'profiles.incorrectPinTryAgain' => 'Pin yang salah, sila cuba lagi.',
			'profiles.sourceProfileMissingParentAccount' => 'Profil sumber kekurangan akaun ibu.',
			'profiles.failedToLoadHomeUsers' => 'Tidak boleh memuatkan pengguna rumah anda Plex . semak sambungan anda dan cuba lagi.',
			'profiles.failedToVerifyPin' => 'Tidak boleh mengesahkan PIN.',
			'profiles.newProfile' => 'Profil baru',
			'profiles.profileNameHint' => 'contohnya tetamu, kanak-kanak, bilik keluarga',
			'profiles.pinProtectionOptional' => 'Perlindungan PIN (pilihan)',
			'profiles.pinExplain' => 'PIN 4 digit diperlukan untuk menukar profil.',
			'profiles.continueButton' => 'teruskan',
			'profiles.pinsDontMatch' => 'Pin tidak sesuai',
			'profiles.tokenIdentityMismatch' => 'Token profil Plex diselesaikan ke pelayan yang tidak dijangka',
			'profiles.settingsLocked' => 'Seting disekat untuk profil ini.',
			'profiles.unlockSettings' => 'Menghapus tetapan',
			'profiles.showExploreForProfile' => 'Tunjukkan Penjelajahan untuk Profil ini',
			'profiles.showExploreForProfileDescription' => 'Matikan untuk menghapuskan Explore daripada navigasi profil ini.',
			'connections.sectionTitle' => 'sambungan',
			'connections.addConnection' => 'Menambah sambungan',
			'connections.addConnectionSubtitleNoProfile' => 'Mendaftar dengan Plex atau sambungkan Jellyfin atau Emby server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Tambah ke ${displayName}: Plex, Jellyfin, Emby, atau sambungan profil lain',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sesi berakhir untuk ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sesi berakhir untuk ${count} pelayan',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} menolak akses kepada akaun ini',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} pelayan menolak akses kepada akaun ini',
			'connections.signInAgain' => 'Menandatangani lagi',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edit ${product} sambungan',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Menambah atau menghapuskan URL untuk ${serverName}. PlezyNG akan menggunakan URL yang boleh dicapai dengan latensi terendah.',
			'accountPreferences.sectionTitle' => 'Keutamaan akaun',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Audio, subtitle dan pilihan perpustakaan disimpan pada ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Audio, subtitle dan pilihan perpustakaan disimpan pada ${count} akaun',
			'accountPreferences.pickAccount' => 'Setiap akaun menyimpan keutamaan mereka sendiri. pilih yang untuk mengedit.',
			'accountPreferences.storedOnAccount' => 'Pilihan-pilihan ini disimpan pada akaun itu sendiri, jadi setiap aplikasi yang mendaftar masuk ke dalamnya menggunakan mereka - termasuk PlezyNG pada peranti lain anda.',
			'accountPreferences.noAccounts' => 'Tiada akaun yang boleh dikonfigurasi',
			'accountPreferences.noAccountsHint' => 'Mendaftar masuk ke Plex, atau sambungkan pelayan Jellyfin atau Emby, dan keutamaan yang disimpan pada akaun itu dipaparkan di sini.',
			'accountPreferences.unavailable' => 'Tidak boleh mencapai akaun ini',
			'accountPreferences.loadFailed' => 'Tidak boleh memuatkan keutamaan ini',
			'accountPreferences.noPreference' => 'Tiada keutamaan',
			'accountPreferences.notSet' => 'Tidak menetapkan',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio dan Subtitle',
			'accountPreferences.groups.libraryDisplay' => 'Pustaka',
			'accountPreferences.groups.personalMedia' => 'Media Peribadi',
			'accountPreferences.preferredAudioLanguage' => 'Bahasa audio yang disukai',
			'accountPreferences.autoSelectAudio' => 'Pilih audio mengikut bahasa',
			'accountPreferences.autoSelectAudioDescription' => 'Menghapus mengekalkan apa-apa audio yang menjejak fail sebagai lalai.',
			'accountPreferences.preferredSubtitleLanguage' => 'Bahasa Subtitle yang disukai',
			'accountPreferences.subtitleMode' => 'Tukar subtitle pada',
			'accountPreferences.subtitleModes.none' => 'dipilih secara manual',
			'accountPreferences.subtitleModes.noneDescription' => 'Jangan sesekali menukar subtitle kepada diri sendiri.',
			'accountPreferences.subtitleModes.defaultMode' => 'Ikuti bendera trek',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Gunakan bendera lalai dan paksa yang disimpan pada setiap trek subtitle.',
			'accountPreferences.subtitleModes.always' => 'Selalu dibenarkan',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Tukar pada trek subtitle dalam bahasa kegemaran bila-bila masa yang ada.',
			'accountPreferences.subtitleModes.onlyForced' => 'Hanya subtitle paksa sahaja',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Mengisi hanya trek yang ditandakan sebagai paksa.',
			'accountPreferences.subtitleModes.smart' => 'Diterbitkan dengan audio asing',
			'accountPreferences.subtitleModes.smartDescription' => 'Tukar subtitle hanya apabila audio dalam bahasa lain.',
			'accountPreferences.subtitleAccessibility' => 'Tajuk SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Sebaik-baik subtitle bukan SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Lebih suka subtitle SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Hanya subtitle SDH sahaja',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Hanya subtitle bukan SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Lebih suka subtitle standard apabila kedua-dua versi standard dan SDH tersedia.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Saya lebih suka subtitle SDH apabila tersedia, tetapi membenarkan subtitle standard sebagai fallback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Gunakan subtitle SDH sahaja; jangan jatuh kembali kepada subtitle standard.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Gunakan subtitle standard sahaja; mengecualikan subtitle SDH.',
			'accountPreferences.forcedSubtitles' => 'Subtitle yang terpaksa',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Lebih suka subtitle yang tidak dikenakan',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Lebih suka subtitle',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Hanya subtitle paksa sahaja',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Hanya subtitle yang tidak dipaksakan',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Lebih suka subtitle biasa, tetapi membenarkan trek paksa sebagai jatuh.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Lebih suka trek paksa apabila tersedia, tetapi membenarkan subtitle biasa sebagai jatuh balik.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Gunakan hanya trek yang ditandai sebagai paksa.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Mengecualikan laluan yang ditandakan sebagai paksa.',
			'accountPreferences.displayMissingEpisodes' => 'Menunjukkan episod yang hilang',
			'accountPreferences.displayMissingEpisodesDescription' => 'Senarai episod yang pelayan tahu tentang tetapi tidak mempunyai fail untuk.',
			'accountPreferences.hidePlayedInLatest' => 'Menyembunyikan item yang dilihat dalam terkini',
			'accountPreferences.hidePlayedInLatestDescription' => 'Tinggalkan item yang telah anda lihat daripada baris terakhir pelayan.',
			'accountPreferences.displayCollectionsView' => 'Tunjukkan pandangan koleksi',
			'accountPreferences.displayCollectionsViewDescription' => 'Tawarkan pandangan Koleksi pelayan di sebelah perpustakaan anda.',
			'accountPreferences.rewatchingInNextUp' => 'Tinggalkan persembahan yang disemak semula di Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'Sebaik sahaja anda selesai persembahan, mulakan semula dan Next Up mengikuti rewatch daripada menurunkan persembahan.',
			'accountPreferences.watchedIndicator' => 'Indikator yang dilihat',
			'accountPreferences.watchedIndicatorOptions.none' => 'Tidak pernah',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filem dan rancangan televisyen',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Filem sahaja',
			'accountPreferences.watchedIndicatorOptions.shows' => 'TV hanya menunjukkan',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Jangan tunjukkan tanda-tanda yang dipantau.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Tunjukkan tanda-tanda yang dilihat untuk filem dan rancangan televisyen.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Tunjukkan tanda-tanda yang dilihat untuk filem sahaja.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Tunjukkan tanda-tanda yang dilihat untuk persembahan TV sahaja.',
			'accountPreferences.mediaReviewsVisibility' => 'Penilaian & Ulasan',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Pengguna dan kritikus',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Pengguna sahaja',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Hanya kritikan sahaja',
			'accountPreferences.mediaReviewsOptions.nobody' => 'tersembunyi',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Tunjukkan kedua-dua penilaian pengguna dan penarafan kritikal.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Tunjukkan penilaian dan ulasan yang dikemukakan oleh pengguna.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Tunjukkan penilaian kritikal dan ulasan.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'menyembunyikan penilaian dan ulasan.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Lebih suka trek audio dalam bahasa ini apabila pelayan atau pemain memilih trek secara automatik.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Lebih suka mengikuti subtitle dalam bahasa ini apabila subtitle dipilih secara automatik.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Pilih sama ada capsi SDH disukai atau diperlukan semasa pemilihan subtitle automatik.',
			'accountPreferences.forcedSubtitleDescription' => 'Pilih sama ada trek subtitle paksa disukai atau diperlukan semasa pemilihan automatik.',
			'accountPreferences.watchedIndicatorDescription' => 'Pilih jenis media yang menerima tanda semak yang dilihat dalam antara muka pelayan.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Pilih penonton dan penilaian kritikal yang dipaparkan oleh pelayan pada halaman media.',
			'accountPreferences.subtitleModeDescription' => 'Pilih apabila subtitle akan diaktifkan secara automatik untuk akaun pelayan ini.',
			'accountPreferences.hubDescription' => 'Keutamaan ini disimpan pada akaun media-server anda dan boleh digunakan untuk pelanggan lain juga.',
			'discover.title' => 'Menjelajahi',
			'discover.noContentAvailable' => 'Tiada kandungan yang tersedia',
			'discover.addMediaToLibraries' => 'Tambah beberapa media ke perpustakaan anda',
			'discover.continueWatching' => 'Menyambung tontonan',
			'discover.continueWatchingIn' => ({required Object library}) => 'Lihat lagi reviu untuk ${library}',
			'discover.nextUp' => 'Seterusnya Up',
			'discover.nextUpIn' => ({required Object library}) => 'Seterusnya Up dalam ${library}',
			'discover.recentlyAdded' => 'baru-baru ini ditambah',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Baru-baru ini ditambah dalam ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Album terkini dalam ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Dimainkan baru-baru ini dalam ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Paling banyak dimainkan dalam ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'M${season}E${episode}',
			'discover.overview' => 'Gambaran keseluruhan',
			'discover.cast' => 'Tembakan',
			'discover.findNext.title' => 'Temui pilihan anda yang seterusnya',
			'discover.findNext.open' => 'Temui pilihan anda yang seterusnya',
			'discover.findNext.anyTime' => 'Tanpa had masa',
			'discover.findNext.timeAvailable' => 'Berapa banyak masa yang anda ada?',
			'discover.findNext.filters' => 'Pilih yang sesuai untuk saat ini',
			'discover.findNext.watch' => 'Tonton',
			'discover.findNext.listen' => 'Dengar',
			'discover.findNext.read' => 'Baca',
			'discover.findNext.finishable' => ({required Object duration}) => 'Boleh selesai dalam ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Kira-kira ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Bab seterusnya · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Jumlah masa: ${duration}',
			'discover.findNext.timingVaries' => 'Tempoh mungkin berbeza',
			'discover.findNext.notNow' => 'Bukan sekarang',
			'discover.findNext.swipeHint' => 'Leret imej muka depan ke arah anak panah atau gunakan butang di bawah.',
			'discover.findNext.saved' => 'Cadangan yang disimpan',
			'discover.findNext.savedCount' => ({required Object count}) => 'Cadangan yang disimpan · ${count}',
			'discover.findNext.undo' => 'Buat asal',
			'discover.findNext.details' => 'Butiran',
			'discover.findNext.noPicks' => 'Belum ada pilihan',
			'discover.findNext.noPicksHint' => 'Sambungkan pustaka atau tambah sumber media untuk bermula.',
			'discover.findNext.noMatches' => 'Tiada yang sesuai untuk saat ini',
			'discover.findNext.noMatchesHint' => 'Cuba jenis media lain atau luangkan lebih banyak masa.',
			'discover.findNext.allDone' => 'Anda telah melihat semua cadangan',
			'discover.findNext.allDoneHint' => 'Mulakan himpunan baharu untuk melihat pilihan ini semula.',
			'discover.findNext.refresh' => 'Cari himpunan lain',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Daripada ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Daripada ${library}',
			'discover.findNext.ownedReason' => 'Daripada pustaka anda',
			'discover.findNext.liveNow' => 'Sedang disiarkan',
			'discover.findNext.watchLive' => 'Tonton siaran langsung',
			'discover.findNext.filterAnything' => 'Apa-apa sahaja',
			'discover.findNext.filterWatch' => 'Tonton',
			'discover.findNext.filterListen' => 'Dengar',
			'discover.findNext.filterRead' => 'Baca',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Gunakan',
			'discover.findNext.openFailed' => 'Pilihan ini tidak lagi tersedia. Muat semula untuk menyemak lagi.',
			'discover.findNext.changeFailed' => 'Perubahan ini tidak dapat disimpan. Cuba lagi.',
			'discover.findNext.savedLimit' => 'Senarai cadangan yang disimpan sudah penuh. Alih keluar satu cadangan untuk menyimpan yang lain.',
			'discover.findNext.chooseHint' => 'Buka tajuk, simpan untuk kemudian atau langkau.',
			'discover.findNext.howItWorks' => 'Cara penggunaan',
			'discover.findNext.notNowHelp' => 'Langkau tajuk ini buat masa ini. Ia kekal dalam pustaka anda.',
			'discover.findNext.saveHelp' => 'Simpan dalam pilihan tersimpan profil ini pada peranti ini. Menyimpan tidak memuat turun tajuk.',
			'discover.findNext.openHelp' => 'Pilih kulit untuk melihat butiran. Gunakan tindakan utama untuk memainkan, membaca atau membuka tajuk.',
			'discover.findNext.controlsHelp' => 'Papan kekunci atau alat kawalan jauh: fokus pada butang, kemudian tekan Enter atau Pilih. Buat asal memulihkan pilihan terakhir anda.',
			'discover.findNext.artworkLoading' => 'Memuatkan imej…',
			'discover.findNext.artworkUnavailable' => 'Imej tidak tersedia',
			'discover.findNext.savedFeedback' => 'Ditambah ke pilihan tersimpan',
			'discover.findNext.skippedFeedback' => 'Dilangkau buat masa ini',
			'discover.findNext.releaseToConfirm' => 'Lepaskan untuk mengesahkan',
			'discover.findNext.remoteHint' => 'Kulit dalam fokus: ← / → pilih · Pilih: butiran · ↑ / ↓ alih fokus',
			'discover.extras' => 'Pelancaran & Extra',
			'discover.studio' => 'Pengajian',
			'discover.rating' => 'Penilaian',
			'discover.director' => 'Pengarah',
			'discover.directors' => 'Pengarah',
			'discover.movie' => 'filem',
			'discover.tvShow' => 'Persembahan TV',
			'discover.minutesLeft' => ({required Object minutes}) => 'Baki ${minutes} min',
			'discover.moreLikeThis' => 'lebih seperti ini',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tajuk', ), 
			'discover.person.born' => 'dilahirkan',
			'discover.person.died' => 'Kematian',
			'discover.person.birthplace' => 'tempat kelahiran',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (umur ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (usia ${age})',
			'errors.searchFailed' => ({required Object error}) => 'Pencarian yang gagal: ${error}',
			'errors.searchUnavailable' => 'Pencarian tidak boleh mencapai mana-mana pelayan media.',
			'errors.connectionTimeout' => ({required Object context}) => 'Sambungan timeout semasa muat ${context}',
			'errors.connectionFailed' => 'Tidak dapat menyambung ke server media',
			'errors.unableToLoad' => ({required Object context}) => 'Tidak boleh memuatkan ${context}. sila cuba lagi.',
			'errors.noClientAvailable' => 'Tiada pelanggan yang tersedia',
			'errors.pleaseEnterToken' => 'Sila masukkan token',
			'errors.invalidToken' => 'Token yang tidak sah',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Token yang gagal disahkan: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Kegagalan untuk menukar kepada ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Tidak boleh dipadamkan ${displayName}',
			'errors.failedToRate' => 'Tidak boleh update rating',
			'errors.reasonTimedOut' => 'sambungan yang ditangguhkan',
			'errors.reasonUnreachable' => 'Pelayan tidak boleh diakses',
			'errors.reasonRefused' => 'Pelayan menolak permintaan',
			'errors.reasonNotFound' => 'item tidak lagi di server',
			'errors.reasonServerError' => 'Pelayan melaporkan kesilapan',
			'errors.reasonCancelled' => 'Permohonan telah dibatalkan',
			'errors.reasonUnexpected' => 'Kesilapan yang tidak dijangka berlaku',
			'libraries.playRandomMovie' => 'Mainkan sebuah filem rawak',
			'libraries.randomPickFailed' => 'Tidak boleh memilih filem rawak daripada perpustakaan ini.',
			'libraries.title' => 'Pustaka',
			'libraries.fallbackTitle' => 'Pustaka',
			'libraries.scanLibraryFiles' => 'Perpustakaan fail',
			'libraries.scanLibrary' => 'Perpustakaan Scan',
			'libraries.analyze' => 'Analisis',
			'libraries.analyzeLibrary' => 'Analisis Perpustakaan',
			'libraries.refreshMetadata' => 'Meningkatkan Metadata',
			'libraries.emptyTrash' => 'Kerosakan kosong',
			'libraries.emptyingTrash' => ({required Object title}) => 'Pembersihan sampah untuk "${title}"',
			'libraries.trashEmptied' => ({required Object title}) => 'Perbincangan:Penggambaran untuk "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Kegagalan untuk membuang sampah kosong: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Perbincangan : ${title}',
			'libraries.analysisStarted' => ({required Object title}) => 'Analisis bermula untuk "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Kegagalan untuk menganalisis perpustakaan: ${error}',
			'libraries.noLibrariesFound' => 'Tiada perpustakaan yang ditemui',
			'libraries.allLibrariesHidden' => 'Semua perpustakaan tersembunyi',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Perpustakaan yang tersembunyi (${count})',
			'libraries.thisLibraryIsEmpty' => 'Perpustakaan ini kosong',
			'libraries.noItemsMatchFilters' => 'Tiada item yang sepadan dengan penapis aktif',
			'libraries.resetFilters' => 'Filter semula',
			'libraries.all' => 'Semua',
			'libraries.clearAll' => 'Semua jelas',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Adakah anda pasti anda mahu memindai "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Adakah anda pasti anda mahu menganalisis "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Adakah anda pasti anda mahu memperbaharui metadata untuk "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Adakah anda pasti anda mahu mengosongkan sampah untuk "${title}"?',
			'libraries.manageLibraries' => 'Pengurusan Perpustakaan',
			'libraries.sort' => 'Berwarna',
			'libraries.sortBy' => 'Berbahagialah dengan',
			'libraries.filters' => 'Penapis',
			'libraries.confirmActionMessage' => 'Adakah anda pasti anda mahu melaksanakan tindakan ini?',
			'libraries.showLibrary' => 'Tunjukkan Perpustakaan',
			'libraries.hideLibrary' => 'Perpustakaan tersembunyi',
			'libraries.libraryOptions' => 'Pilihan Perpustakaan',
			'libraries.content' => 'Perpustakaan kandungan',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'Pilih Perpustakaan',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filter (${count})',
			'libraries.noRecommendations' => 'Tiada cadangan yang tersedia',
			'libraries.noCollections' => 'Tiada koleksi dalam perpustakaan ini',
			'libraries.noFoldersFound' => 'Tiada folder yang ditemui',
			'libraries.folders' => 'Folder-folder',
			'libraries.tabs.recommended' => 'Rekomendasi',
			'libraries.tabs.browse' => 'Semak imbas',
			'libraries.tabs.collections' => 'Koleksi',
			'libraries.tabs.playlists' => 'Senarai ulangmain',
			'libraries.groupings.title' => 'Kumpulan',
			'libraries.groupings.all' => 'Semua',
			'libraries.groupings.movies' => 'Filem-filem',
			'libraries.groupings.shows' => 'Rancangan TV',
			'libraries.groupings.seasons' => 'Musim',
			'libraries.groupings.episodes' => 'Peristiwa',
			'libraries.groupings.artists' => 'Artis',
			'libraries.groupings.albums' => 'Album',
			'libraries.groupings.tracks' => 'Laluan',
			'libraries.groupings.folders' => 'Folder-folder',
			'libraries.filterCategories.genre' => 'Jenis',
			'libraries.filterCategories.year' => 'Tahun yang',
			'libraries.filterCategories.contentRating' => 'Penilaian Kandungan',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'tidak diperhatikan',
			'libraries.filterCategories.unplayed' => 'Tidak Bermain',
			'libraries.filterCategories.favorites' => 'Kegemaran',
			'libraries.filterCategories.filePath' => 'Fail laluan',
			'libraries.sortLabels.title' => 'Tajuk',
			'libraries.sortLabels.dateAdded' => 'Tarikh ditambah',
			'libraries.sortLabels.releaseDate' => 'Tarikh pelepasan',
			'libraries.sortLabels.rating' => 'Penilaian',
			'libraries.sortLabels.communityRating' => 'Penilaian komuniti',
			'libraries.sortLabels.criticRating' => 'Penilaian kritikal',
			'libraries.sortLabels.userRating' => 'Penilaian pengguna',
			'libraries.sortLabels.datePlayed' => 'Tarikh dimainkan',
			'libraries.sortLabels.playCount' => 'Bermain dengan Count',
			'libraries.sortLabels.productionYear' => 'Tahun Pengeluaran',
			'libraries.sortLabels.runtime' => 'Perbincangan Runtime',
			'libraries.sortLabels.officialRating' => 'Penilaian rasmi',
			'libraries.sortLabels.premiereDate' => 'Tarikh Perdana',
			'libraries.sortLabels.startDate' => 'Tarikh bermula',
			'libraries.sortLabels.airTime' => 'Waktu udara',
			'libraries.sortLabels.studio' => 'Pengajian',
			'libraries.sortLabels.random' => 'Peristiwa',
			'libraries.sortLabels.dateShared' => 'Tarikh berkongsi',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Perbincangan:Episod Terkini Air Date',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Tarikh akhir episode ditambah',
			'libraries.sortLabels.dateDownloaded' => 'Tarikh Dimuat turun',
			'libraries.sortLabels.size' => 'Ukuran',
			'libraries.sortLabels.library' => 'Pustaka',
			'libraries.advancedFilters.include' => 'termasuk',
			'libraries.advancedFilters.exclude' => 'Pengecualian',
			'libraries.advancedFilters.any' => 'mana-mana',
			'libraries.advancedFilters.yes' => 'Ya Ya',
			'libraries.advancedFilters.no' => 'Tidak',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Tidak boleh ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} telah dipilih',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} dikecualikan',
			'libraries.advancedFilters.searchValues' => 'nilai pencarian',
			'libraries.advancedFilters.noValues' => 'Tiada nilai',
			'libraries.advancedFilters.matchContains' => 'mengandungi',
			'libraries.advancedFilters.matchNotContains' => 'Tidak mengandungi',
			'libraries.advancedFilters.matchIs' => 'Adalah',
			'libraries.advancedFilters.matchIsNot' => 'Tidak boleh',
			'libraries.advancedFilters.matchBeginsWith' => 'Bermula dengan',
			'libraries.advancedFilters.matchEndsWith' => 'Berakhir dengan',
			'libraries.advancedFilters.textHint' => 'jenis untuk match',
			'libraries.advancedFilters.from' => 'Daripada',
			'libraries.advancedFilters.to' => 'kepada',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} kepada ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} dan ke atas',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'sehingga ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} hari yang lalu',
			'libraries.advancedFilters.dateLastYear' => 'Tahun lepas',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Lebih daripada ${count} hari',
			'libraries.advancedFilters.dateOlderThanYear' => 'lebih tua daripada 1 tahun',
			'libraries.selection.selectItems' => 'Pilih item',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} telah dipilih',
			'libraries.selection.actions' => 'Tindakan Seleksi',
			'libraries.selection.confirmDescendants' => 'Ini mengubah semua episod dalam persembahan dan musim yang dipilih.',
			'libraries.selection.confirmUnwatched' => 'Ini juga membersihkan kemajuan playback untuk item yang dipilih.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Jumlah item yang dipilih : ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Item yang dikemaskini: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Diperbaharui ${succeeded}; gagal ${failed}. item yang gagal kekal dipilih.',
			'about.title' => 'Mengenai',
			'about.openSourceLicenses' => 'Lesen sumber terbuka',
			'about.versionLabel' => ({required Object version}) => 'Perbincangan:Bahasa Inggeris ${version}',
			'about.appDescription' => 'Pelanggan yang indah Plex, Jellyfin, dan Emby untuk Flutter',
			'about.viewLicensesDescription' => 'Lihat lesen perpustakaan pihak ketiga',
			'about.privacyPolicy' => 'Kebijakan Privasi',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Tiada pelayan yang ditemui untuk ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Pelayan yang gagal memuat naik: ${error}',
			'serverSelection.noValidServers' => 'Tiada pelayan yang boleh digunakan ditemui dalam akaun ini',
			'hubDetail.title' => 'Tajuk',
			'hubDetail.releaseYear' => 'Tahun pelepasan',
			'hubDetail.dateAdded' => 'Tarikh ditambah',
			'hubDetail.rating' => 'Penilaian',
			'hubDetail.noItemsFound' => 'Tiada item yang ditemui',
			'logs.clearLogs' => 'Log yang jelas',
			'logs.copyLogs' => 'Menyalin log',
			'logs.uploadLogs' => 'Meningkatkan log',
			'logs.saveLogs' => 'Simpan log ke fail',
			'logs.logsSaved' => ({required Object path}) => 'Rekod disimpan pada ${path}',
			'logs.saveLogsFailed' => 'Saya tidak boleh menyimpan fail log.',
			'startup.failedTitle' => 'PlezyNG tidak boleh bermula',
			'startup.failedBody' => 'Sesuatu yang salah semasa permulaan. butiran di bawah mengenal pasti apa yang gagal.',
			'startup.failedBodyRepairable' => 'Fail tetapan PlezyNG yang disimpan rosak dan perlu dibina semula sebelum aplikasi boleh bermula. Mencuba lagi tidak akan membantu — pilih Baiki storan.',
			'startup.phaseLabel' => 'Langkah',
			'startup.showDetails' => 'Tunjukkan butiran',
			'startup.hideDetails' => 'menyembunyikan butiran',
			'startup.copyDetails' => 'Menyalin butiran',
			'startup.detailsCopied' => 'Maklumat disalin ke clipboard',
			'startup.uploadDetails' => 'Tambah butiran',
			'startup.repairStorage' => 'Perbaikan penyimpanan',
			'startup.repairTitle' => 'Perbaikan data yang disimpan?',
			'startup.repairBodyCommon' => 'Fail tetapan PlezyNG rosak dan tidak boleh dibaca. pembaikan memulihkan setiap tetapan kepada lalai.',
			'startup.repairBodyOneCredential' => 'Satu log masuk yang disimpan rosak dan tidak boleh dibaca. pembaikan menghapuskan hanya satu; tetapan lain anda ditinggalkan sendirian.',
			'startup.repairBodySignInsKept' => 'Sesi log masuk pelayan dan profil anda sepatutnya kekal aktif.',
			'startup.repairBodySignInsLost' => 'Kunci yang melindungi maklumat log masuk tersimpan tidak dapat dipulihkan daripada fail ini. Anda perlu log masuk semula ke setiap pelayan dan profil. Tiada apa-apa pada pelayan media anda terjejas.',
			'startup.repairBodySessionsUncertain' => 'Data penjejak (MAL, AniList, Simkl, Trakt) dan Seerr disimpan secara berasingan dan mungkin kekal atau hilang. PlezyNG akan memberitahu anda dengan tepat data yang dikekalkan.',
			'startup.repairConfirm' => 'Perbaikan',
			'startup.repairSucceeded' => 'Penyimpanan diperbaiki',
			'startup.repairNeedsRestart' => 'Penyimpanan diperbaiki - perlu memulakan semula',
			'startup.restartRequiredBody' => 'Data anda telah dibaiki, tetapi PlezyNG perlu dimulakan semula sebelum dapat menggunakannya. Tutup PlezyNG dan buka semula.',
			'startup.quitPlezy' => 'Perbincangan:Penghantaran PlezyNG',
			'startup.repairFailed' => 'Perbaikan gagal',
			'startup.repairKeptSignIns' => 'Sesi log masuk pelayan dan profil anda masih aktif.',
			'startup.repairLostSignIns' => 'Kunci yang melindungi maklumat log masuk tersimpan tidak dapat dipulihkan. Anda perlu log masuk semula ke setiap pelayan dan profil.',
			'startup.repairLostSessions' => 'Sekurang-kurangnya satu pengesan atau sambungan Seerr telah hilang dan perlu disambungkan semula.',
			'startup.backupTitle' => 'Satu salinan fail yang rosak disimpan',
			'startup.backupWarning' => 'Ia mengandungi pengesahan log masuk anda.Jangan muat naik atau berkongsi.',
			'startup.deleteBackup' => 'Menghapuskan copy',
			'startup.backupDeleted' => 'salinan telah dipadamkan.',
			'startup.previousFailureTitle' => 'PlezyNG gagal memulakan kali terakhir',
			'licenses.relatedPackages' => 'Pakej yang berkaitan',
			'licenses.license' => 'Lisensi',
			'licenses.licenseNumber' => ({required Object number}) => 'Permohonan Permohonan ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} pengesahan',
			'navigation.libraries' => 'Pustaka',
			'navigation.downloads' => 'Muat turun',
			'navigation.liveTv' => 'TV Langsung',
			'navigation.explore' => 'Menjelajah',
			'explore.mdblistShelves.manage' => 'Pengurusan Pelancongan Pelancongan',
			'explore.mdblistShelves.manageDescription' => 'Pilih dan mengatur senarai daripada akaun anda MDBList',
			'explore.mdblistShelves.description' => 'Pilih senarai filem dan televisyen awam daripada akaun MDBList. mencipta atau menyalin senarai di MDBList, kemudian memperbaharui.',
			'explore.mdblistShelves.selected' => 'Pelabuhan yang dipilih',
			'explore.mdblistShelves.available' => 'Senarai akaun yang tersedia',
			'explore.mdblistShelves.noLists' => 'Tiada senarai filem atau televisyen awam dikembalikan. mencipta atau menyalin senarai di MDBList, kemudian memperbaharui.',
			'explore.mdblistShelves.displayName' => 'Nama Pameran Shelf',
			'explore.mdblistShelves.nameHint' => 'Tinggalkan kosong untuk menggunakan nama senarai sumber.',
			'explore.mdblistShelves.add' => 'Tambah shelf',
			'explore.mdblistShelves.save' => 'Menyelamatkan kerusi',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Pergerakan ${title} ke atas',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Pergerakan ${title} ke bawah',
			'explore.mdblistShelves.unavailable' => 'Senarai ini tidak boleh didapati.Tarik balik atau keluarkan shell dalam tetapan.',
			'explore.mdblistShelves.rateLimited' => 'MDBList permintaan had telah dicapai. sila berundur kemudian.',
			'explore.mdblistShelves.loadFailed' => 'Tidak boleh mengisi rak. semak sambungan anda dan retry.',
			'explore.mdblistShelves.saveFailed' => 'Saya tak boleh simpan.Sila rujuk.',
			'explore.mdblistShelves.accountChanged' => 'Akaun atau profil telah berubah.Buka semula tetapan ini.',
			'explore.mdblistShelves.settingsUnreadable' => 'Tab yang disimpan tidak boleh dibaca. pilih semula senarai anda untuk menggantikan tetapan ini.',
			'explore.title' => 'Menjelajah',
			'explore.selectSource' => 'Pilih sumber',
			'explore.rows.watchlist' => 'Pengawasan',
			'explore.rows.recommendedMovies' => 'Filem yang disyorkan',
			'explore.rows.recommendedShows' => 'Persembahan yang disyorkan',
			'explore.rows.trendingMovies' => 'filem trending',
			'explore.rows.trendingShows' => 'Rujukan Trend',
			'explore.rows.popularMovies' => 'Filem popular',
			'explore.rows.popularShows' => 'Persembahan popular',
			'explore.rows.trendingAnime' => 'Perbincangan Anime',
			'explore.rows.suggestedAnime' => 'Anime yang disyorkan',
			'explore.rows.airingAnime' => 'Anime teratas yang sedang ditayangkan',
			'explore.rows.popularAnime' => 'Anime yang paling popular',
			'explore.rows.trending' => 'Trend yang',
			'explore.rows.upcomingMovies' => 'Filem yang akan datang',
			'explore.rows.upcomingShows' => 'Persembahan yang akan datang',
			'explore.status.airing' => 'udara',
			'explore.status.ended' => 'Tamat',
			'explore.status.canceled' => 'Pembatalan',
			'explore.status.upcoming' => 'yang akan datang',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episod', ), 
			'explore.cast' => 'Tembakan',
			'explore.characters' => 'watak',
			'explore.addToWatchlist' => 'Tambah ke Watchlist',
			'explore.removeFromWatchlist' => 'Mengalih keluar daripada Watchlist',
			'explore.addedToWatchlist' => 'Ditambah kepada watchlist',
			'explore.removedFromWatchlist' => 'Menghapus daripada watchlist',
			'explore.watchlistUpdateFailed' => 'Tidak boleh update watchlist',
			'explore.watchlistNoMatch' => 'Tidak boleh menyesuaikan item ini dengan senarai pengawasan',
			'explore.notInLibrary' => 'Bukan di perpustakaan anda',
			'explore.inTheseLibraries' => 'Di dalam perpustakaan ini',
			'explore.checkingLibrary' => 'Periksa perpustakaan anda.',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: 'Tidak boleh memeriksa ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pelayan', ), 
			'explore.emptyTitle' => 'Tiada apa-apa di sini',
			'explore.emptyMessage' => ({required Object source}) => 'Roda daripada ${source} akan muncul di sini sebaik sahaja mereka mempunyai kandungan.',
			'explore.searchHint' => ({required Object source}) => 'Pencarian untuk ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Tiada hasil untuk "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Cari filem dan persembahan di ${source}.',
			'explore.searchFailed' => 'Pencarian gagal. semak sambungan anda dan cuba lagi.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} popular',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} pengangkutan udara',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} disenaraikan',
			'explore.badge.rankTrending' => ({required Object n}) => 'Sohor kini #${n}',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} dalam ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} dilihat',
			'explore.badge.available' => 'Tersedia',
			'explore.badge.partiallyAvailable' => 'Sebahagian tersedia',
			'explore.badge.availableIn4k' => '4K boleh didapati',
			'explore.badge.requested' => 'Permohonan',
			'explore.badge.pendingApproval' => 'Menunggu kelulusan',
			'explore.badge.processing' => 'Pemprosesan',
			'explore.badge.declined' => 'dikecualikan',
			'explore.badge.requestFailed' => 'Permohonan gagal',
			'explore.badge.requested4k' => '4K dikehendaki',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} musim',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} dalam ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Seterusnya dalam ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} EPS',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} disenaraikan',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} dilihat hari ini',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} menonton minggu ini',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} menonton bulan ini',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} menonton tahun ini',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} penonton',
			'explore.stats.planning' => ({required Object n}) => '${n} rancangan untuk menonton',
			'explore.stats.favorited' => ({required Object n}) => '${n} kegemaran',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} telah meletakkannya',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komen', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} undian',
			'explore.stats.watching' => ({required Object n}) => '${n} menonton',
			'explore.stats.completed' => ({required Object n}) => '${n} telah selesai',
			'explore.stats.onHold' => ({required Object n}) => '${n} dalam pemegang',
			'explore.stats.dropped' => ({required Object n}) => '${n} dikurangkan',
			'explore.season.winter' => 'Musim Sejuk',
			'explore.season.spring' => 'Musim semi',
			'explore.season.summer' => 'Musim panas',
			'explore.season.fall' => 'jatuh',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'televisyen',
			'explore.format.tvShort' => 'Televisyen pendek',
			'explore.format.movie' => 'filem',
			'explore.format.special' => 'Khusus',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Muzik',
			'explore.format.other' => 'yang lain',
			'explore.sourceMaterial.original' => 'asal',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'novel cahaya',
			'explore.sourceMaterial.novel' => 'Novel',
			'explore.sourceMaterial.visualNovel' => 'Kisah Visual',
			'explore.sourceMaterial.game' => 'Permainan',
			'explore.sourceMaterial.webComic' => 'Laman web komik',
			'explore.sourceMaterial.musicRelease' => 'Muzik',
			'explore.sourceMaterial.otherMedia' => 'yang lain',
			'explore.creditRole.actor' => 'Pelakon',
			'explore.creditRole.director' => 'Pengarah',
			'explore.creditRole.writer' => 'Penulis',
			'explore.creditRole.producer' => 'Penerbit',
			'explore.creditRole.creator' => 'Pencipta',
			'explore.creditRole.composer' => 'Komposer',
			'explore.relation.prequel' => 'Peringatan',
			'explore.relation.sequel' => 'Seterusnya',
			'explore.relation.sideStory' => 'Kisah sampingan',
			'explore.relation.spinOff' => 'Perbincangan Spin-off',
			'explore.relation.alternativeVersion' => 'Versi alternatif',
			'explore.relation.summary' => 'ringkasan',
			'explore.relation.parentStory' => 'Kisah Keluarga',
			'explore.relation.adaptation' => 'Penyesuaian',
			'explore.relation.other' => 'berkaitan',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} di ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} di ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Tajuk asal',
			'explore.detail.alsoKnownAs' => 'Juga dikenali sebagai',
			'explore.detail.studios' => 'Pengajian',
			'explore.detail.country' => 'negara',
			'explore.detail.language' => 'Bahasa Melayu',
			'explore.detail.released' => 'dibebaskan',
			'explore.detail.physicalRelease' => 'Pada cakera',
			'explore.detail.ended' => 'Tamat',
			'explore.detail.addedOn' => ({required Object date}) => 'Ditambah ${date}',
			'explore.detail.yourRating' => 'Penilaian anda',
			'explore.detail.budget' => 'Bajet',
			'explore.detail.revenue' => 'Pejabat Box',
			'explore.detail.contentAdvisory' => 'Panduan Umur',
			'explore.detail.tags' => 'Tag :',
			'explore.detail.revealSpoilerTags' => 'Menunjukkan spoiler tag',
			'explore.detail.links' => 'Kiri',
			'explore.detail.watchOn' => 'Lihatlah',
			'explore.detail.watchTrailer' => 'Lihat trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Terbuka pada ${site}',
			'explore.detail.crew' => 'Pasukan',
			'explore.detail.ratings' => 'Penilaian',
			'explore.detail.schedule' => 'Jadual',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: 'Disyorkan oleh ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengguna', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'disyorkan oleh ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'disukai oleh ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} belum diakses',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'disyorkan oleh ${percent} penonton',
			'explore.detail.relatedTitles' => 'Tajuk yang berkaitan',
			'explore.detail.background' => 'latar belakang',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hasil', ), 
			'liveTv.title' => 'TV Langsung',
			'liveTv.guide' => 'Panduan',
			'liveTv.noChannels' => 'Tiada saluran yang tersedia',
			'liveTv.noDvr' => 'Tiada DVR yang dikonfigurasi pada mana-mana pelayan',
			'liveTv.serverUnavailable' => 'Pelayan TV langsung tidak tersedia.',
			'liveTv.serverNotConnected' => 'Pelayan TV Live tidak disambungkan.',
			'liveTv.noPrograms' => 'Tiada data program yang tersedia',
			'liveTv.liveStreamFailed' => 'Live Stream gagal',
			'liveTv.unknownProgram' => 'Program yang tidak diketahui',
			'liveTv.timelineLiveProgram' => 'Program Live (playback boleh berada di luar program ini)',
			'liveTv.timelineBuffer' => 'Tarikh Buffer',
			'liveTv.timelineUnavailable' => 'Jadual yang tidak tersedia',
			'liveTv.timelineEstimated' => 'Penghargaan Playback',
			'liveTv.timelinePending' => 'Menjelang mencari',
			'liveTv.timelineStale' => 'Jadual boleh ditangguhkan',
			'liveTv.unknownHub' => 'yang tidak diketahui',
			'liveTv.unknownError' => 'Kesilapan yang tidak diketahui',
			'liveTv.channelNumber' => ({required Object number}) => 'Rangkaian : ${number}',
			'liveTv.unknownChannel' => 'saluran yang tidak diketahui',
			'liveTv.live' => 'hidup',
			'liveTv.premiereBadge' => 'baru',
			'liveTv.reloadGuide' => 'Reload panduan',
			'liveTv.searchGuide' => 'Panduan Pencarian',
			'liveTv.searchHint' => 'Mencari saluran dan program',
			'liveTv.searchNoResults' => ({required Object query}) => 'Tiada perlawanan untuk "${query}"',
			'liveTv.channelsSection' => 'Saluran',
			'liveTv.programsSection' => 'Program yang',
			'liveTv.now' => 'Sekarang',
			'liveTv.today' => 'Hari ini',
			'liveTv.tomorrow' => 'esok hari',
			'liveTv.midnight' => 'tengah malam',
			'liveTv.overnight' => 'Pagi hari',
			'liveTv.morning' => 'Pagi',
			'liveTv.daytime' => 'harian',
			'liveTv.evening' => 'Malam hari',
			'liveTv.lateNight' => 'Malam yang terlambat',
			'liveTv.whatsOn' => 'Apa yang ada di',
			'liveTv.watchChannel' => 'Lihat saluran',
			'liveTv.favorites' => 'Kegemaran',
			'liveTv.reorderFavorites' => 'Penghormatan Favorit',
			'liveTv.noFavoriteChannels' => 'Tiada saluran kegemaran',
			'liveTv.noFavoriteChannelsHint' => 'Tunjukkan semua saluran, kemudian tekan panjang saluran untuk menambahnya kepada kegemaran anda.',
			'liveTv.showAllChannels' => 'Tunjukkan semua saluran',
			'liveTv.favoritesLoadFailed' => 'Tidak boleh memuatkan kegemaran. semak sambungan anda dan cuba lagi.',
			'liveTv.favoritesUpdateFailed' => 'Tidak boleh mengemas kini kegemaran. semak sambungan anda dan cuba lagi.',
			'liveTv.joinSession' => 'Sesi dalam kemajuan',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Lihat dari awal (${minutes} min yang lalu)',
			'liveTv.watchLive' => 'Lihat Live',
			'liveTv.goToLive' => 'Pergi untuk hidup',
			'liveTv.record' => 'Rekod',
			'liveTv.recordEpisode' => 'rekod episod',
			'liveTv.recordSeries' => 'Rekod siri',
			'liveTv.recordOptions' => 'Rekod Pilihan',
			'liveTv.saveTo' => 'menyelamatkan kepada',
			'liveTv.recordings' => 'rekod',
			'liveTv.scheduledRecordings' => 'Jadual',
			'liveTv.recordingRules' => 'Peraturan rekod',
			'liveTv.noScheduledRecordings' => 'Tiada apa-apa yang dijadualkan untuk rekod',
			'liveTv.manageRecording' => 'Menguruskan rekod',
			'liveTv.cancelRecording' => 'Batalkan rakaman',
			'liveTv.cancelRecordingTitle' => 'Adakah anda membatalkan rekod ini?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} tidak lagi akan didaftarkan.',
			'liveTv.deleteRule' => 'Menghapuskan peraturan',
			'liveTv.deleteRuleTitle' => 'Menghapuskan peraturan rekod?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Episod-episod masa depan daripada ${title} tidak akan direkodkan.',
			'liveTv.recordingScheduled' => 'Rekod yang dijadualkan',
			'liveTv.alreadyScheduled' => 'Program ini telah dirancang',
			'liveTv.dvrAdminRequired' => 'Seting DVR memerlukan akaun admin',
			'liveTv.recordingFailed' => 'Tidak boleh merancang rekod',
			'liveTv.recordingTargetMissing' => 'Tidak boleh menentukan rekod perpustakaan',
			'liveTv.recordNotAvailable' => 'Rekod tidak tersedia untuk program ini',
			'liveTv.recordingCancelled' => 'Rekod dibatalkan',
			'liveTv.recordingRuleDeleted' => 'Peraturan rekod dipadamkan',
			'liveTv.processRecordingRules' => 'Menilai semula peraturan',
			'liveTv.recordingInProgress' => 'Rekod sekarang',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} telah ditetapkan',
			'liveTv.editRule' => 'Peraturan Edit',
			'liveTv.editRuleAction' => 'Sunting',
			'liveTv.recordingRuleUpdated' => 'Peraturan rekod dikemaskini',
			'liveTv.guideReloadRequested' => 'Panduan pembaharuan diminta',
			'liveTv.guideReloadFailed' => 'Tidak boleh memperbaharui panduan',
			'liveTv.rulesProcessRequested' => 'Peraturan penilaian semula diminta',
			'liveTv.rulesProcessFailed' => 'Tidak boleh menilai semula peraturan rekod',
			'liveTv.recordShow' => 'Rekod Pameran',
			'liveTv.recordSettings.startEarly' => 'Bermula awal (second)',
			'liveTv.recordSettings.endLate' => 'Akhir yang terlambat (second)',
			'liveTv.recordSettings.newOnly' => 'Hanya episod baru',
			'liveTv.recordSettings.anyChannel' => 'Rekod di mana-mana saluran',
			'liveTv.recordSettings.anyTime' => 'Rekod pada bila-bila masa',
			'liveTv.recordSettings.skipInLibrary' => 'Melemparkan episod-episod yang sudah di perpustakaan',
			'liveTv.recordSettings.keepUpTo' => 'Episod yang perlu dikekalkan',
			'liveTv.recordSettings.keepUpToHint' => '0 mengekalkan setiap episod',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Bermula dalam ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} di ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} mengembalikan data pemutaran TV langsung yang tidak sah',
			'liveTv.failedToStartChannel' => 'Tidak boleh memulakan saluran langsung',
			'liveTv.failedToBuildStreamUrl' => 'Tidak boleh membina URL aliran',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Tidak boleh memulakan saluran: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Tidak boleh menukar saluran: ${reason}',
			'collections.title' => 'Koleksi',
			'collections.collection' => 'Koleksi',
			'collections.empty' => 'Koleksi yang kosong',
			'collections.deleteCollection' => 'Penghapusan Koleksi',
			'collections.deleteConfirm' => ({required Object title}) => 'Padam "${title}"? Tindakan ini tidak boleh dibuat asal.',
			'collections.deleted' => 'Koleksi dihapuskan',
			'collections.deleteFailed' => 'gagal menghapuskan koleksi',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Kegagalan untuk memadamkan koleksi: ${error}',
			'collections.selectCollection' => 'Pilih Koleksi',
			'collections.collectionName' => 'Nama Koleksi',
			'collections.enterCollectionName' => 'Masukkan nama koleksi',
			'collections.addedToCollection' => 'Ditambah kepada koleksi',
			'collections.errorAddingToCollection' => 'gagal untuk menambah kepada koleksi',
			'collections.created' => 'Koleksi yang dibuat',
			'collections.removeFromCollection' => 'Keluar daripada koleksi',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Alih keluar “${title}” daripada koleksi ini?',
			'collections.removedFromCollection' => 'Dipecat daripada koleksi',
			'collections.removeFromCollectionFailed' => 'gagal keluar daripada koleksi',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Kesilapan penghapusan daripada koleksi: ${error}',
			'collections.searchCollections' => 'Mencari koleksi...',
			'playlists.title' => 'Senarai ulangmain',
			'playlists.playlist' => 'Senarai Main',
			'playlists.noPlaylists' => 'Tiada senarai permainan yang ditemui',
			'playlists.create' => 'Mencipta Playlist',
			'playlists.playlistName' => 'Nama Playlist',
			'playlists.enterPlaylistName' => 'Masukkan nama playlist',
			'playlists.delete' => 'Menghapuskan Playlist',
			'playlists.removeItem' => 'Menghapus daripada Playlist',
			'playlists.smartPlaylist' => 'Senarai Pemain Pintar',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item', ), 
			'playlists.emptyPlaylist' => 'Senarai permainan ini kosong',
			'playlists.deleteConfirm' => 'Menghapuskan Playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Adakah anda pasti anda mahu memadamkan "${name}"?',
			'playlists.created' => 'Playlist yang dibuat',
			'playlists.deleted' => 'Playlist telah dihapuskan',
			'playlists.itemAdded' => 'Ditambah ke playlist',
			'playlists.itemRemoved' => 'Menghapus daripada playlist',
			'playlists.selectPlaylist' => 'Pilih Playlist',
			'playlists.searchPlaylists' => 'Mencari senarai permainan...',
			'playlists.errorCreating' => 'gagal mencipta playlist',
			'playlists.errorDeleting' => 'Tidak boleh memadamkan playlist',
			'playlists.errorLoading' => 'Kegagalan untuk memuatkan playlist',
			'playlists.errorAdding' => 'Tidak boleh ditambah ke playlist',
			'playlists.errorReordering' => 'Kegagalan untuk mengatur semula item playlist',
			'playlists.errorRemoving' => 'gagal keluar daripada playlist',
			'music.goToAlbum' => 'Pergi ke album',
			'music.goToArtist' => 'Pergi ke artis',
			'music.instantMix' => 'Tag: campuran instan',
			'music.playNext' => 'Bermain selanjutnya',
			'music.addToQueue' => 'Tambah kepada Queue',
			'music.discNumber' => ({required Object n}) => 'Perbincangan:Disk ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} laluan', ), 
			'music.nowPlaying' => 'Bermain sekarang',
			'music.playingFrom' => ({required Object title}) => 'Bermain daripada ${title}',
			'music.queue' => 'Perbincangan',
			'music.clearQueue' => 'Kosongkan barisan',
			'music.lyrics' => 'Lirik',
			'music.visualizer' => 'Visualisasi',
			'music.visualizerProfileLoading' => 'Membaca Analisis Track ...',
			'music.visualizerAmbientMotion' => 'Pergerakan Lingkungan',
			'music.visualizerPlexLoudness' => 'Plex bunyi',
			'music.visualizerLiveAudio' => 'Analisis audio langsung',
			'music.visualizerPreviousPreset' => 'Gaya visual yang terdahulu',
			'music.visualizerNextPreset' => 'Seterusnya Visual Style',
			'music.visualizerPresetAurora' => 'Aurora yang',
			'music.visualizerPresetBloom' => 'Bloom daripada',
			'music.visualizerPresetOrbitals' => 'Orbit yang',
			'music.visualizerPresetPrism' => 'Penghargaan',
			'music.visualizerPresetTunnel' => 'Terowong',
			'music.visualizerPresetTrackMap' => 'Tarikan peta',
			'music.noLyrics' => 'Tiada lyrics boleh didapati',
			'music.sleepTimer' => 'Waktu Tidur',
			'music.sleepTimerEndOfTrack' => 'Akhir daripada trek',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minit', ), 
			'music.stopPlayback' => 'Berhenti bermain',
			'music.previousTrack' => 'Trek sebelumnya',
			'music.nextTrack' => 'Trek seterusnya',
			'music.repeat' => 'Kembali',
			'music.repeatAll' => 'Ulangi semua',
			'music.repeatOne' => 'Ulangi satu',
			'music.instantMixNoServer' => 'Tiada pelayan boleh didapati untuk campuran instan',
			'music.instantMixFailed' => 'Tidak boleh mengisi campuran instan',
			'music.instantMixEmpty' => 'SeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnyaSeterusnya',
			'music.noAudioUrl' => ({required Object track}) => 'Tiada URL audio boleh didapati untuk ${track}',
			'music.discography.singlesAndEps' => 'Kumpulan & EPs',
			'music.discography.live' => 'hidup',
			'music.discography.compilations' => 'Kompilasi',
			'watchTogether.title' => 'Tonton Bersama',
			'watchTogether.description' => 'Menonton kandungan dalam sinkron dengan rakan-rakan dan keluarga',
			'watchTogether.createRoom' => 'Mencipta bilik',
			'watchTogether.creatingRoom' => 'Mencipta bilik ...',
			'watchTogether.joinRoom' => 'menyertai bilik',
			'watchTogether.joiningRoom' => 'Perhimpunan bilik...',
			'watchTogether.connecting' => 'Menghubungkan ...',
			'watchTogether.relayPublic' => 'Bilik-bilik menggunakan rangkaian Open Watch Party awam.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Bilik-bilik menggunakan relay anda di ${url}.',
			'watchTogether.recentRooms' => 'Bilik baru',
			'watchTogether.roomActions' => 'Aktiviti bilik',
			'watchTogether.renameRoom' => 'Reka bentuk bilik',
			'watchTogether.removeRoom' => 'Keluarkan',
			'watchTogether.enterRoomCode' => 'Masukkan kod 6 aksara daripada tuan rumah.',
			'watchTogether.roomCode' => 'Kod bilik',
			'watchTogether.paste' => 'Paste yang',
			'watchTogether.noCodeInClipboard' => 'Klipboard tidak mengandungi kod bilik',
			'watchTogether.copyCode' => 'Kode salinan',
			'watchTogether.codeCopied' => 'Kod bilik disalin',
			'watchTogether.shareInvite' => 'Memberi jemputan',
			'watchTogether.inviteCopied' => 'Sila rujuk. masukkan ke dalam mesej.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.inviteMessage' => ({required Object code}) => 'Bergabunglah dengan Bilik Bersama saya di PlezyNG: buka Bilik Bersama, pilih Bilik Bersama dan masukkan ${code}.',
			'watchTogether.openSessionControls' => 'Open Watch Bersama-sama kawalan sesi',
			'watchTogether.reconnecting' => 'Menghubungkan semula...',
			'watchTogether.reconnectingDescription' => 'sambungan hilang. anda menyertai bilik secara automatik.',
			'watchTogether.connected' => 'Terhubung',
			'watchTogether.disconnected' => 'Disambungkan',
			'watchTogether.youAreHost' => 'Awak lah tuan rumah',
			'watchTogether.hostedBy' => ({required Object name}) => 'Diterima oleh ${name}',
			'watchTogether.hostControlsPlayback' => 'Pengawal Pengawal Playback',
			'watchTogether.anyoneCanControl' => 'Siapa sahaja boleh mengawal playback',
			'watchTogether.roomLocked' => 'Bilik tertutup',
			'watchTogether.nowPlaying' => 'Bermain sekarang',
			'watchTogether.nothingPlaying' => 'Tiada bermain',
			'watchTogether.nothingPlayingHost' => 'Main sesuatu daripada mana-mana perpustakaan untuk berkongsi dengan bilik.',
			'watchTogether.nothingPlayingGuest' => 'Apabila tuan rumah memainkan sesuatu, ia dibuka di sini.',
			'watchTogether.notShareable' => 'Video ini tidak mempunyai perlawanan katalog, jadi hanya orang yang mempunyai akses ke pelayan yang sama boleh memainkannya.',
			'watchTogether.searching' => 'Mencari video ini di perpustakaan anda ...',
			'watchTogether.yourCopy' => 'Kopi anda',
			'watchTogether.sharingYourCopy' => 'Anda berkongsi salinan anda',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Bermain salinan anda, ${difference}',
			'watchTogether.mismatchTitle' => 'Kopi anda berbeza panjang',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Salinan terdekat anda ialah ${difference} daripada video bilik.',
			'watchTogether.playAnyway' => 'Bermain bagaimanapun',
			'watchTogether.chooseAnotherCopy' => 'Pilih salinan lain',
			'watchTogether.dontPlay' => 'Jangan Bermain',
			'watchTogether.unavailableTitle' => 'Anda tidak mempunyai video ini',
			'watchTogether.unavailableDescription' => 'PlezyNG tidak dapat menemukannya dalam perpustakaan anda. pilih salinan sendiri atau cari lagi.',
			'watchTogether.chooseCopy' => 'Pilih salinan',
			'watchTogether.searchAgain' => 'Cari lagi',
			'watchTogether.noCandidates' => 'Tiada salinan yang boleh didapati di perpustakaan anda.',
			'watchTogether.choiceFailed' => 'Saya tidak boleh memainkan salinan ini untuk bilik',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} lebih lama',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} lebih pendek',
			'watchTogether.lengthSame' => 'panjang yang sama',
			'watchTogether.lengthUnknown' => 'Panjang yang tidak diketahui',
			'watchTogether.joinCurrentPlayback' => 'Menyertai Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'Kembali ke apa yang tuan rumah sedang menonton',
			'watchTogether.stopMedia' => 'Hentikan video untuk semua orang',
			'watchTogether.syncOffset' => 'Penyelesaian Offset',
			'watchTogether.syncOffsetDescription' => 'Pindah video anda jika ia berjalan di hadapan atau di belakang bilik.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Salinan anda ialah ${difference} daripada video bilik.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Penggunaan ${offset}',
			'watchTogether.offsetMinusSecond' => '1 s',
			'watchTogether.offsetMinusTenth' => '- 100 ms',
			'watchTogether.offsetPlusTenth' => '+ 100 ms',
			'watchTogether.offsetPlusSecond' => '+ 1 s',
			'watchTogether.participants' => 'peserta',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} peserta', ), 
			'watchTogether.hostBadge' => 'tetamu',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (Anda)',
			'watchTogether.playerIdle' => 'Idol',
			'watchTogether.playerLoading' => 'Pengecasan',
			'watchTogether.playerReady' => 'Bersedia',
			'watchTogether.playerBuffering' => 'Perbezaan',
			'watchTogether.matchSearching' => 'Pencarian',
			'watchTogether.matchMatched' => 'Mempunyai video',
			'watchTogether.matchMismatched' => 'panjang yang berbeza',
			'watchTogether.matchUnavailable' => 'Tidak ada video',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Perbezaan ${offset}',
			'watchTogether.makeHost' => 'buat tuan rumah',
			'watchTogether.makeHostQuestion' => 'Penghantaran kepada tuan rumah?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} akan mengawal playback dan memandu sesi untuk semua orang.',
			'watchTogether.transfer' => 'Penghantaran',
			'watchTogether.removeParticipant' => 'Keluar Dari Bilik',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Menghapuskan ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} meninggalkan bilik. mereka boleh menyertai kod lagi melainkan anda menutup bilik.',
			'watchTogether.remove' => 'Keluarkan',
			'watchTogether.roomSettings' => 'tetapan bilik',
			'watchTogether.letEveryoneControl' => 'Semua orang boleh mengawal playback',
			'watchTogether.lockRoom' => 'Bilik Lock',
			'watchTogether.lockRoomDescription' => 'Tiada yang baru boleh menyertai',
			'watchTogether.leaveRoom' => 'Tinggalkan Bilik',
			'watchTogether.leaveRoomQuestion' => 'Tinggalkan bilik?',
			'watchTogether.leaveRoomConfirm' => 'Anda boleh menyertai lagi dengan kod bilik.',
			'watchTogether.leave' => 'Tinggalkan',
			'watchTogether.endRoom' => 'Bilik Akhir',
			'watchTogether.endRoomQuestion' => 'Bilik Akhir ?',
			'watchTogether.endRoomConfirm' => 'Ini berakhir bilik bagi semua orang.',
			'watchTogether.end' => 'Akhirnya',
			'watchTogether.playBlockedTitle' => 'Playback Tidak Bermula',
			'watchTogether.playBlockedDescription' => 'Bermain untuk mula menonton dengan bilik.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} permainan percetakan',
			'watchTogether.notices.playbackStarted' => 'Playback telah bermula',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} beristirahat',
			'watchTogether.notices.playbackPaused' => 'Playback bercuti',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} melompat ke ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Perbincangan:Penghormatan kepada ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} menetapkan kelajuan kepada ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Kelajuan yang ditetapkan kepada ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} bermula ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Bermain sekarang ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} berhenti video',
			'watchTogether.notices.mediaStopped' => 'Video telah berhenti',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Menunggu untuk ${name} ...',
			'watchTogether.notices.waitingForSomeone' => 'Menunggu orang lain untuk menangkap ...',
			'watchTogether.notices.finished' => 'selesai',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} kini menjadi tuan rumah',
			'watchTogether.notices.youAreNowHost' => 'Sekarang awak tuan rumah',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} menyertai',
			'watchTogether.notices.left' => ({required Object name}) => '${name} keluar',
			'watchTogether.notices.controlRefused' => 'Hanya tuan rumah yang boleh mengawal playback',
			'watchTogether.notices.searchFailed' => 'Sesetengah pelayan tidak boleh dicari untuk video bilik',
			'watchTogether.notices.playBlocked' => 'Permainan akhbar untuk bermula',
			'watchTogether.notices.shareFailed' => 'Saya tidak boleh berkongsi video ini dengan bilik',
			'watchTogether.notices.downloadNotShared' => 'Muat turun tidak dikongsi dengan bilik sementara pelayan mereka offline',
			'watchTogether.notices.openFailed' => 'Tidak boleh membuka video bilik',
			'watchTogether.ended.ended' => 'Penghuni telah mengakhiri bilik',
			'watchTogether.ended.kicked' => 'Anda telah diusir dari bilik',
			'watchTogether.ended.expired' => 'Bilik telah tamat',
			'watchTogether.ended.replaced' => 'Anda telah menyertai bilik ini pada peranti lain',
			'watchTogether.ended.lost' => 'Kehilangan sambungan ke bilik',
			'watchTogether.errors.invalidCode' => 'Kod mempunyai 6 huruf dan angka, tanpa 0, 1, I, L atau O.',
			'watchTogether.errors.roomNotFound' => 'Tiada bilik yang mempunyai kod itu. ia mungkin telah berakhir.',
			'watchTogether.errors.roomFull' => 'Bilik itu penuh.',
			'watchTogether.errors.roomLocked' => 'Pihak pengurus telah menutup bilik itu.',
			'watchTogether.errors.relayFull' => 'Lihat Bersama sibuk sekarang. cuba lagi nanti.',
			'watchTogether.errors.unreachable' => 'Tidak boleh mencapai jam bersama relay. semak sambungan anda.',
			'watchTogether.errors.rateLimited' => 'Terlalu banyak percubaan. tunggu sebentar dan cuba lagi.',
			'watchTogether.errors.clientBlocked' => 'Versi PlezyNG ini tidak boleh menggunakan relay.',
			'watchTogether.errors.forbidden' => 'Hanya tuan rumah sahaja yang boleh melakukannya.',
			'watchTogether.errors.notInRoom' => 'Awak tak ada di dalam bilik.',
			'watchTogether.errors.alreadyInRoom' => 'Awak dah ada di dalam bilik.',
			'watchTogether.errors.resumeFailed' => 'Saya tak boleh masuk ke dalam bilik.',
			'watchTogether.errors.unsupported' => 'Radio tidak menyokong perkara ini.',
			'watchTogether.errors.generic' => 'Ada yang salah, cuba lagi.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Perbincangan ${number}',
			'downloads.title' => 'Muat turun',
			'downloads.manage' => 'Pengurusan',
			'downloads.tvShows' => 'Rancangan TV',
			'downloads.movies' => 'Filem-filem',
			'downloads.music' => 'Muzik',
			'downloads.tracksQueued' => ({required Object count}) => '${count} trek yang dikeluarkan untuk muat turun',
			'downloads.noDownloads' => 'Tiada muat turun',
			'downloads.noDownloadsDescription' => 'Kandungan yang dimuat turun akan muncul di sini untuk pandangan offline',
			'downloads.downloadNow' => 'Muat turun',
			'downloads.deleteDownload' => 'Menghapus download',
			'downloads.retryDownload' => 'Kembali ke download',
			'downloads.downloadQueued' => 'Download yang dikemukakan',
			'downloads.downloadResumed' => 'muat turun semula',
			'downloads.serverErrorBitrate' => 'Kesilapan pelayan: fail boleh melebihi had bitrate jauh',
			'downloads.storageFull' => 'Muat turun berhenti untuk melindungi penyimpanan yang tersedia.Bebaskan beberapa ruang atau pilih lokasi muat turun lain, kemudian keluar.',
			'downloads.storageUnavailable' => 'Muat turun berhenti kerana penyimpanan yang tersedia tidak boleh disemak. semak lokasi muat turun, kemudian keluar.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episod yang dikeluarkan untuk muat turun',
			'downloads.downloadDeleted' => 'Download dihapuskan',
			'downloads.deleteConfirm' => ({required Object title}) => 'Menghapus "${title}" daripada peranti ini?',
			'downloads.deleteCollectionDownloads' => 'Menghapuskan Downloads',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Padam semua muat turun dalam “${title}” daripada peranti ini?',
			'downloads.collectionDownloadsDeleted' => 'Downloads dihapuskan',
			'downloads.cancelledDownloadTitle' => 'Pembatalan Download',
			'downloads.cancelledDownloadMessage' => 'Download ini telah dibatalkan. apa yang anda mahu lakukan?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Semua episod telah dimuat turun',
			'downloads.resumeDownload' => 'Rujukan Download',
			'downloads.cancelledDownload' => 'Pembatalan download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (sinkronkan ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Dimuat turun ${file} - Klik untuk menyelesaikan',
			'downloads.partialDownloadClickToComplete' => 'Bahagian muat turun - klik untuk menyelesaikan',
			'downloads.deleting' => 'Menghapuskan ...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Menghapuskan ${title}... (${current} daripada ${total})',
			'downloads.queuedTooltip' => 'Peringatan',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Perbincangan : ${files}',
			'downloads.downloadingTooltip' => 'Dilancarkan...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Perbincangan ${files}',
			'downloads.noDownloadsTree' => 'Tiada download',
			'downloads.pauseAll' => 'Beristirahat semua',
			'downloads.resumeAll' => 'Menggambar semua',
			'downloads.retryAll' => 'Kembalikan semua',
			'downloads.retryFailed' => 'Retry kegagalan download',
			'downloads.deleteAll' => 'Padam semua',
			'downloads.selectVersion' => 'Pilih versi',
			'downloads.allEpisodes' => 'Semua episod',
			'downloads.unwatchedOnly' => 'Hanya tidak diperhatikan',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Seterusnya ${count} tidak dilihat',
			'downloads.customAmount' => 'Jumlah yang disesuaikan...',
			'downloads.customAmountAny' => 'Jumlah yang disesuaikan (setiap tahun)',
			'downloads.randomEpisodes' => 'Kejadian rawak',
			'downloads.includeSpecials' => 'Termasuk spesial',
			'downloads.howManyEpisodes' => 'Berapakah jumlah episod?',
			'downloads.invalidEpisodeCount' => 'Masukkan nombor episod yang sah.',
			'downloads.keepSynced' => 'Tetap bersinkron',
			'downloads.downloadOnce' => 'Download sekali',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} tidak disemak',
			'downloads.editSyncRule' => 'Edit Peraturan Sinkron',
			'downloads.removeSyncRule' => 'Menghapuskan Peraturan Sync',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Hentikan penyegerakan "${title}"? episod yang dimuat turun akan disimpan.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Hentikan penyegerakan "${title}"',
			'downloads.deleteSyncRuleDownloads' => 'Juga menghapuskan download yang berkaitan',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Muat turun yang digunakan oleh peraturan sink atau profil lain akan disimpan.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Peraturan sinkron yang dicipta — mengekalkan ${count} episod yang tidak dilihat',
			'downloads.syncRuleUpdated' => 'Peraturan Sync dikemaskini',
			'downloads.syncRuleRemoved' => 'Peraturan Sync dihapuskan',
			'downloads.syncRuleAndDownloadsRemoved' => 'Peraturan Sinkron dan muat turun yang berkaitan dihapuskan',
			'downloads.syncRuleCleanupBusy' => 'Peraturan Sync kini dikemas kini. cuba lagi dalam sekejap.',
			'downloads.syncRuleCleanupUnavailable' => 'Penyambung semula pelayan dan cuba lagi, atau menghapuskan peraturan tanpa memadamkan muat turun.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Sinkronkan ${count} episod baru untuk ${title}',
			'downloads.syncNow' => 'Sinkronkan sekarang',
			'downloads.downloadsUpToDate' => 'Downloads sehingga kini',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync lengkap · ${queued} queued, ${removed} dihapuskan',
			'downloads.activeSyncRules' => 'Peraturan Sync',
			'downloads.reviewOrphanFiles' => 'Lihat lagi reviu untuk Orphaned downloads',
			'downloads.orphanReviewTitle' => 'Lihat lagi reviu untuk Orphaned downloads',
			'downloads.orphanReviewDescription' => 'Fail-fail yang ditandakan ini terdapat dalam folder muat turun yang dikendalikan oleh aplikasi lalai PlezyNG dan tidak mempunyai rekod muat turun atau tugas aktif yang sepadan.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} fail · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Memadamkan fail ${count}',
			'downloads.orphanCleanupNone' => 'Tiada fail muat turun yang ditemui',
			'downloads.orphanCleanupFailed' => 'PlezyNG tidak boleh selamat memindai folder muat turun yang dikendalikan. tiada fail yang dipadamkan.',
			'downloads.orphanCleanupChanged' => 'Senarai muat turun berubah semasa ulasan. ulasan semula fail sebelum pembersihan.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Memadamkan ${count} fail yatim piatu · ${size} dibebaskan',
			'downloads.noSyncRules' => 'Tiada Peraturan Sinkron',
			'downloads.manageSyncRule' => 'Pengurusan Sync',
			'downloads.editEpisodeCount' => 'Perhitungan Episod',
			'downloads.editSyncFilter' => 'Filter Sinkron',
			'downloads.syncAllItems' => 'Menggabungkan semua item',
			'downloads.syncUnwatchedItems' => 'Menggabungkan item yang tidak dipantau',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Pelayan : ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Tersedia',
			'downloads.syncRuleOffline' => 'Perbincangan Offline',
			'downloads.syncRuleSignInRequired' => 'Menandatangani yang diperlukan',
			'downloads.syncRuleAccessDenied' => 'Akses yang ditolak',
			'downloads.syncRuleNotAvailableForProfile' => 'Tidak tersedia untuk profil semasa',
			'downloads.syncRuleUnknownServer' => 'Pelayan yang tidak diketahui',
			'downloads.syncRuleListCreated' => 'Peraturan Sync yang diwujudkan',
			'downloads.backgroundWarning.bannerBlocked' => 'Muat turun akan berhenti apabila anda meninggalkan app',
			'downloads.backgroundWarning.bannerDegraded' => 'Download latar belakang boleh terhad',
			'downloads.backgroundWarning.bannerAction' => 'Maklumat',
			'downloads.backgroundWarning.sheetTitle' => 'Download latar belakang disekat',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Download latar belakang boleh terhad',
			'downloads.backgroundWarning.sheetIntro' => 'Android mencegah PlezyNG daripada memuat turun dengan boleh dipercayai dalam latar belakang.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Peranti anda membatasi apabila PlezyNG boleh dimuat turun dalam latar belakang.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Penggunaan latar belakang PlezyNG terhad. tetapkan penggunaan bateri atau latar belakang kepada "Tidak terhad".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android telah meletakkan PlezyNG dalam keadaan berdiri terhad. menetapkan penggunaan bateri kepada "Tidak terhad".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Pemberitahuan muat turun dimatikan, jadi kemajuan dan kawalan mungkin tidak tersedia.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Pada Android 13 atau lebih baru, mereka diperlukan untuk muat turun latar belakang yang panjang.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver ialah pada, yang memblokir muat turun latar belakang pada data mudah alih. muat turun masih perlu berjalan pada Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Muat turun berulang kali berhenti semasa PlezyNG berada di latar belakang. semak tetapan penggunaan bateri atau latar belakang PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Seting Terbuka',
			'downloads.backgroundWarning.stillNotWorking' => 'Bantuan khusus peranti',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Lihat langkah-langkah untuk peranti anda, atau hantar log daripada Settings › Lihat log jika masalah berterusan.',
			'downloads.backgroundWarning.dialogTitle' => 'Download tidak boleh selesai',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Download apa pun',
			'downloads.backgroundWarning.dialogFixFirst' => 'Tetapkan ini terlebih dahulu',
			'downloads.backgroundWarning.statusTile' => 'Latar Belakang Download',
			'downloads.backgroundWarning.statusOk' => 'dibenarkan untuk berlari di latar belakang',
			'downloads.backgroundWarning.statusBlocked' => 'disekat oleh sistem pengaturan',
			'downloads.backgroundWarning.statusDegraded' => 'Terhad oleh tetapan sistem',
			'downloads.backgroundWarning.statusUnknown' => 'belum disemak',
			'downloads.backgroundWarning.settingsUnavailable' => 'Tidak boleh membuka tetapan sistem pada peranti ini',
			'downloads.backgroundWarning.linkUnavailable' => 'Tidak boleh membuka dontkillmyapp.com pada peranti ini',
			'downloads.options' => 'Pilihan muat turun',
			'downloads.groupings.library' => 'Pustaka',
			'downloads.groupings.collections' => 'Koleksi',
			'downloads.unknownLibrary' => 'Perpustakaan yang tidak diketahui',
			'downloads.unknownShow' => 'persembahan yang tidak diketahui',
			'downloads.unknownSeason' => 'Musim yang tidak diketahui',
			'downloads.unknownAlbum' => 'Album yang tidak diketahui',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} selesai',
			'downloads.storageUsed' => ({required Object size}) => 'Penyimpanan yang digunakan: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} muat turun', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menunjukkan', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filem-filem', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} buah buku', ), 
			'downloads.errorFileNotFound' => 'Fail yang tidak ditemui (404)',
			'downloads.errorDownloadNotAllowed' => 'Muat turun tidak dibenarkan oleh pelayan (403)',
			'downloads.errorDownloadFailed' => 'Download gagal',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Pendaftaran yang gagal: ${reason}',
			'downloads.convertingOnServer' => 'Menukar kepada server ...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Penukaran pada pelayan · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'muat turun gagal (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Selepas pemprosesan gagal: ${reason}',
			'downloads.reasonFileNotSaved' => 'fail tidak boleh disimpan pada peranti ini',
			'downloads.reasonCannotResume' => 'Bahagian download tidak boleh dikembalikan',
			'downloads.reasonDeviceStorageFull' => 'Peranti ini tidak disimpan',
			'downloads.notificationDownloading' => 'Dilancarkan...',
			'downloads.notificationComplete' => 'muat turun lengkap',
			'downloads.notificationPaused' => 'Download beristirahat',
			'shaders.title' => 'Tembakan',
			'shaders.noShaderDescription' => 'Tiada peningkatan video',
			'shaders.nvscalerDescription' => 'Skala imej NVIDIA untuk video yang lebih tajam',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Dini',
			'shaders.artcnnVariantDenoiseSharpen' => 'Perbincangan:Denoise + Sharpen',
			'shaders.qualityFast' => 'Cepat',
			'shaders.qualityHQ' => 'Kualiti Tinggi',
			'shaders.mode' => 'Mod yang',
			'shaders.importShader' => 'Pengangkutan Shader',
			'shaders.customShaderDescription' => 'Penyesuaian GLSL Shader',
			'shaders.shaderImported' => 'Shader yang diimport',
			'shaders.shaderImportFailed' => 'Kegagalan untuk mengimport shader',
			'shaders.deleteShader' => 'Menghapus Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Menghapuskan "${name}"',
			'companionRemote.title' => 'Alat Kawalan Pendamping',
			'companionRemote.connectedTo' => ({required Object name}) => 'Menghubungkan ke ${name}',
			'companionRemote.unknownDevice' => 'Peranti yang tidak diketahui',
			'companionRemote.session.startingServer' => 'Memulakan pelayan jarak jauh',
			'companionRemote.session.hostAddress' => 'alamat tuan rumah',
			'companionRemote.session.connected' => 'Terhubung',
			'companionRemote.session.serverRunning' => 'Remote server aktif',
			'companionRemote.session.serverStopped' => 'Remote server telah berhenti',
			'companionRemote.session.serverRunningDescription' => 'Peranti mudah alih di rangkaian anda boleh menyambung ke aplikasi ini',
			'companionRemote.session.serverStoppedDescription' => 'Mulakan pelayan untuk membolehkan peranti mudah alih untuk menyambung',
			'companionRemote.session.usePhoneToControl' => 'Gunakan peranti mudah alih anda untuk mengawal aplikasi ini',
			'companionRemote.session.startServer' => 'Mulakan pelayan',
			'companionRemote.session.stopServer' => 'Hentikan pelayan',
			'companionRemote.session.minimize' => 'Minimum',
			'companionRemote.session.manualAddressHint' => 'Alamat sambungan manual :',
			'companionRemote.pairing.discoveryDescription' => 'PlezyNG peranti dengan akaun yang sama Plex muncul di sini',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Menghubungkan ...',
			'companionRemote.pairing.searchingForDevices' => 'Mencari peranti ...',
			'companionRemote.pairing.noDevicesFound' => 'Tiada peranti yang ditemui di rangkaian anda',
			'companionRemote.pairing.noDevicesHint' => 'Buka PlezyNG pada desktop dan gunakan yang sama Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Peranti yang tersedia',
			'companionRemote.pairing.manualConnection' => 'Penghubung manual',
			'companionRemote.pairing.cryptoInitFailed' => 'Tidak boleh memulakan sambungan yang selamat. mendaftar di Plex terlebih dahulu.',
			'companionRemote.pairing.validationHostRequired' => 'Sila masukkan alamat tuan rumah',
			'companionRemote.pairing.validationHostFormat' => 'Format hendaklah IP:port (contohnya, 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Menggunakan rangkaian yang sama pada kedua-dua peranti.',
			'companionRemote.pairing.sessionNotFound' => 'Peranti tidak ditemui. pastikan PlezyNG berjalan pada host.',
			'companionRemote.pairing.authFailed' => 'Pengesahan gagal. kedua-dua peranti memerlukan akaun yang sama Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kegagalan untuk menghubungkan: ${error}',
			'companionRemote.pairing.codeTitle' => 'Pasangan Kod',
			'companionRemote.pairing.codeDescription' => 'Masukkan kod yang ditunjukkan dalam Companion Remote pada peranti tuan rumah. kedua-dua peranti mesti menggunakan versi yang menyokong perpaduan yang selamat.',
			'companionRemote.pairing.codeInvalid' => 'Masukkan semua 32 huruf dan nombor daripada kod tuan rumah.',
			'companionRemote.pairing.updateRequired' => 'Kemas kini kedua-dua peranti kepada versi yang menyokong perpaduan yang selamat.',
			'companionRemote.pairing.hostDescription' => 'Masukkan kod ini sekali pada setiap remote. simpan peribadi: ia memberikan kawalan profil ini.',
			'companionRemote.pairing.resetCode' => 'Menerapkan kod pasangan',
			'companionRemote.pairing.resetDescription' => 'Mengalih keluar semua remote dan mencipta kod baru. setiap remote akan perlu berpasangan lagi.',
			'companionRemote.remote.disconnectConfirm' => 'Adakah anda mahu menyambung keluar daripada sesi jauh?',
			'companionRemote.remote.reconnecting' => 'Menghubungkan semula...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Mencuba ${current} daripada 5',
			'companionRemote.remote.retryNow' => 'Kembali sekarang',
			'companionRemote.remote.tabRemote' => 'jarak jauh',
			'companionRemote.remote.tabPlay' => 'Bermain',
			'companionRemote.remote.tabMore' => 'Lagi',
			'companionRemote.remote.menu' => 'Menu yang',
			'companionRemote.remote.tabNavigation' => 'Tab navigasi',
			'companionRemote.remote.tabDiscover' => 'Menjelajahi',
			'companionRemote.remote.tabLibraries' => 'Pustaka',
			'companionRemote.remote.tabSearch' => 'Pencarian',
			'companionRemote.remote.tabDownloads' => 'Muat turun',
			'companionRemote.remote.tabSettings' => 'Tetapan',
			'companionRemote.remote.previous' => 'Sebelumnya',
			'companionRemote.remote.playPause' => 'Bermain / beristirahat',
			'companionRemote.remote.next' => 'Seterusnya',
			'companionRemote.remote.seekBack' => 'Mencari Kembali',
			'companionRemote.remote.stop' => 'Berhenti',
			'companionRemote.remote.seekForward' => 'Mencari FWD',
			'companionRemote.remote.volume' => 'Jumlah',
			'companionRemote.remote.volumeDown' => 'Bawah',
			'companionRemote.remote.volumeUp' => 'Tambah',
			'companionRemote.remote.fullscreen' => 'Paparan skrin penuh',
			'companionRemote.remote.subtitles' => 'Sari kata',
			'companionRemote.remote.audio' => 'Audio yang',
			'companionRemote.remote.searchHint' => 'Mencari di Desktop',
			'companionRemote.errors.noNetworkInterface' => 'Tiada antara muka rangkaian yang ditemui',
			'companionRemote.errors.authenticationFailed' => 'Kegagalan pengesahan',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Tidak memulakan pelayan jauh: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Tidak dapat menghantar perintah jauh: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Tarikh keluar untuk menyertai sesi',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Tidak dapat menghubungkan ke mana-mana alamat',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Hubungan hilang selepas ${attempts} percubaan',
			'companionRemote.errors.connectionLost' => 'Hubungan yang hilang',
			'companionRemote.closedBeforeAuth' => 'Perhubungan ditutup sebelum pengesahan',
			'videoSettings.playbackSpeed' => 'Kelajuan Playback',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktif (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Tidur Tidur',
			'videoSettings.audioSync' => 'Perbincangan Audio Sync',
			'videoSettings.subtitleSync' => 'Subtitle Sinkronisasi',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR tidak tersedia di sini - komposer desktop atau output video ini tidak boleh membawanya.',
			'videoSettings.hdrToneMapping' => 'HDR Tone Peta',
			'videoSettings.hdrToneMappingCompositor' => 'Komposisi',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Melalui metadata HDR sumber dan biarkan peta komposer desktop melakukannya.',
			'videoSettings.hdrToneMappingPlayer' => 'Pemain',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Peta ke puncak kecerahan paparan dalam pemain, kemudian memberitahu komposer hasilnya.',
			'videoSettings.hdrToneMappingFailed' => 'Tidak boleh mengubah pemetaan nada HDR - mod terdahulu masih aktif.',
			'videoSettings.audioOutput' => 'Pengeluaran Audio',
			'videoSettings.videoTrack' => 'Trek video',
			'videoSettings.videoTrackDescription' => 'Pilih strim video yang hendak dipaparkan. Tersedia dalam main balik MPV apabila fail mengandungi trek video alternatif.',
			'videoSettings.videoTrackDefault' => 'Lalai',
			'videoSettings.videoTrackUnavailable' => 'Tiada trek video alternatif yang tersedia.',
			'videoSettings.videoTrackFailed' => 'Trek video tidak dapat ditukar.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'Trek ${id}',
			'videoSettings.performanceOverlay' => 'Persembahan Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'di sekitar',
			'videoSettings.audioOutputSpatial' => 'Audio ruang',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio Penyelesaian',
			'videoSettings.audioEqualizerDescription' => '10 band equalizer untuk MPVFilter audio menggunakan audio yang dikodkan dan mematikan passthrough.',
			'videoSettings.audioEqualizerFlat' => 'Permukaan',
			'videoSettings.audioEqualizerActive' => 'Khas',
			'videoSettings.audioEqualizerSaveFailed' => 'Tidak boleh menyimpan seting audio equalizer.',
			'videoSettings.audioEffectsDescription' => 'Efek menggunakan audio yang dikodkan, jadi passthrough berbalik. persekitaran bilik dan pembesaran stereo bergantung kepada MPV membina dan mengesan.',
			'videoSettings.audioStereoWidth' => 'Pengembangan Stereo',
			'videoSettings.audioSpatializer' => 'Persekitaran bilik',
			'videoSettings.audioSpatializerDescription' => 'Menambah refleksi bilik yang tenang.',
			'videoSettings.audioPitch' => 'Perubahan Pitch',
			'videoSettings.audioPitchDescription' => 'Menukar pitch tanpa mengubah kelajuan. MPV Pembinaan hendaklah termasuk Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'Kesan ini tidak tersedia untuk trek ini atau MPV membina .',
			'videoSettings.backgroundVideoAudio' => 'Video audio latar belakang',
			'videoSettings.backgroundVideoAudioDescription' => 'Pastikan video audio dimainkan apabila anda meninggalkan pemain; imej itu tersembunyi sehingga anda kembali. Android menggunakan pemberitahuan pemutaran media.',
			'videoSettings.audioNormalization' => 'Mengatur bunyi bising',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Memecahkan audio ke PCM; passthrough keluar sementara ini',
			'performanceOverlay.color' => 'warna',
			'performanceOverlay.performance' => 'prestasi',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'Apl',
			'performanceOverlay.decoder' => 'Pengecut',
			'performanceOverlay.rawDecoder' => 'Rujukan Decoder',
			'performanceOverlay.tunneling' => 'tunel',
			'performanceOverlay.passthrough' => 'Pasukan',
			'performanceOverlay.aspect' => 'Aspek',
			'performanceOverlay.rotation' => 'Rotasi',
			'performanceOverlay.dvSource' => 'D. Sumber',
			'performanceOverlay.dvPath' => 'Laluan DV',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision pengecut',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision decoder (P7→8.1) untuk',
			'performanceOverlay.dvRouteBaseLayer' => 'Lapisan asas',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 lapisan asas',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Lapisan asas HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Lapisan asas SDR',
			'performanceOverlay.dvRouteReshaped' => 'RPU diselesaikan semula (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Grafik Eksperimen P7 FEL (tidak berkelayakan)',
			'performanceOverlay.p7Conversion' => 'P7 Perbezaan',
			'performanceOverlay.sampleRate' => 'Kadar sampel',
			'performanceOverlay.pixelFormat' => 'Pengenalan kepada Pixel Fmt',
			'performanceOverlay.hwFormat' => 'Format perkakasan',
			'performanceOverlay.matrix' => 'Matriks',
			'performanceOverlay.primaries' => 'Permulaan',
			'performanceOverlay.transfer' => 'Penghantaran',
			'performanceOverlay.renderFps' => 'Penghantaran FPS',
			'performanceOverlay.displayFps' => 'Pemandangan FPS',
			'performanceOverlay.avSync' => 'A / V Sinkron',
			'performanceOverlay.dropped' => 'pecah',
			'performanceOverlay.dvRpus' => 'RPU yang',
			'performanceOverlay.dvRpuAverage' => 'Perbezaan RPU AVG',
			'performanceOverlay.dvSampleAverage' => 'Perbezaan sampel AVG',
			'performanceOverlay.maxLuma' => 'Tag: Max Luma',
			'performanceOverlay.minLuma' => 'Luma min.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache digunakan',
			'performanceOverlay.cacheLimit' => 'Perbezaan Cache',
			'performanceOverlay.speed' => 'kelajuan',
			'performanceOverlay.player' => 'Pemain',
			'performanceOverlay.playMethod' => 'Permainan kaedah',
			'performanceOverlay.memory' => 'Memori yang',
			'performanceOverlay.uiFps' => 'Perbezaan FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'Perkhidmatan NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Perkhidmatan Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'Perbincangan HW',
			'performanceOverlay.decoderExynosHw' => 'Perbezaan HW',
			'performanceOverlay.decoderSoftware' => 'Perisian',
			'performanceOverlay.decoderHardware' => 'Perkakasan',
			'performanceOverlay.tunnelingActive' => 'Aktiviti',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} gagal)',
			'externalPlayer.title' => 'Pemain luar',
			'externalPlayer.useExternalPlayer' => 'Penggunaan Pemain Luar',
			'externalPlayer.useExternalPlayerDescription' => 'Membuka video dalam aplikasi lain',
			'externalPlayer.selectPlayer' => 'Pilih Pemain',
			'externalPlayer.customPlayers' => 'Pemain Custom',
			'externalPlayer.systemDefault' => 'Sistem yang lalai',
			'externalPlayer.addCustomPlayer' => 'Menambah Custom Player',
			'externalPlayer.playerName' => 'Nama Pemain',
			'externalPlayer.playerNameHint' => 'Pemain saya',
			'externalPlayer.playerCommand' => 'Perintah',
			'externalPlayer.playerPackage' => 'Nama Pakej',
			'externalPlayer.playerUrlScheme' => 'Rancangan URL',
			'externalPlayer.off' => 'keluar',
			'externalPlayer.launchFailed' => 'gagal membuka pemain luar',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} tidak dipasang',
			'externalPlayer.playInExternalPlayer' => 'Bermain dalam pemain luaran',
			'externalPlayer.description' => 'Pilih aplikasi lain untuk membuka video dalam. pemain yang tersedia bergantung kepada peranti anda dan aplikasi yang dipasang.',
			'externalPlayer.systemDefaultDescription' => 'Biarkan sistem operasi membuka video dengan aplikasi lalai.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Buka video dengan ${player}.',
			'externalPlayer.playerNameDescription' => 'Label yang ditunjukkan dalam senarai pemain.',
			'externalPlayer.playerPackageDescription' => 'Masukkan nama pakej Android aplikasi pemain, seperti com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Masukkan perintah pemain yang dipasang atau laluan yang boleh dijalankan untuk peranti ini.',
			'externalPlayer.playerUrlSchemeDescription' => 'Masukkan skema URL dan templat URL pilihan yang digunakan untuk melancarkan pemain.',
			'metadataEdit.editMetadata' => 'Sunting',
			'metadataEdit.screenTitle' => 'Sunting metadata',
			'metadataEdit.basicInfo' => 'Maklumat asas',
			'metadataEdit.artwork' => 'seni',
			'metadataEdit.advancedSettings' => 'Pengaturan Lanjutan',
			'metadataEdit.title' => 'Tajuk',
			'metadataEdit.sortTitle' => 'Tajuk Berwarna',
			'metadataEdit.originalTitle' => 'Tajuk asli',
			'metadataEdit.releaseDate' => 'Tarikh pelepasan',
			'metadataEdit.contentRating' => 'Penilaian Kandungan',
			'metadataEdit.studio' => 'Pengajian',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'ringkasan',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'latar belakang',
			'metadataEdit.logo' => 'Logo yang',
			'metadataEdit.squareArt' => 'Lapangan seni',
			'metadataEdit.selectPoster' => 'Pilih Poster',
			'metadataEdit.selectBackground' => 'Pilih latar belakang',
			'metadataEdit.selectLogo' => 'Pilih logo',
			'metadataEdit.selectSquareArt' => 'Pilih Square Art',
			'metadataEdit.fromUrl' => 'Daripada URL',
			'metadataEdit.uploadFile' => 'Muat naik fail',
			'metadataEdit.enterImageUrl' => 'Masukkan URL imej',
			'metadataEdit.imageUrl' => 'imej URL',
			'metadataEdit.metadataUpdated' => 'Metadata dikemaskini',
			'metadataEdit.metadataUpdateFailed' => 'Kegagalan Mengemas kini Metadata',
			'metadataEdit.artworkUpdated' => 'Seni yang dikemaskini',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.artworkUpdateFailed' => 'Kegagalan untuk mengemas kini karya seni',
			'metadataEdit.noArtworkAvailable' => 'Tiada karya seni yang tersedia',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Pilihan seni ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Pilihan seni ${index}, dipilih',
			'metadataEdit.notSet' => 'Tidak menetapkan',
			'metadataEdit.libraryDefault' => 'Perpustakaan kekurangan',
			'metadataEdit.accountDefault' => 'Akaun yang tidak sah',
			'metadataEdit.seriesDefault' => 'Serangkaian default',
			'metadataEdit.episodeSorting' => 'Perbezaan Episod',
			'metadataEdit.oldestFirst' => 'Yang Tertua Pertama',
			'metadataEdit.newestFirst' => 'Yang baru pertama',
			'metadataEdit.keep' => 'teruskan',
			'metadataEdit.allEpisodes' => 'Semua episod',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episod terkini',
			'metadataEdit.latestEpisode' => 'Episod Terkini',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episod ditambah dalam ${count} hari yang lalu',
			'metadataEdit.deleteAfterPlaying' => 'Menghapuskan episod selepas bermain',
			'metadataEdit.never' => 'Tidak pernah',
			'metadataEdit.afterADay' => 'Selepas satu hari',
			'metadataEdit.afterAWeek' => 'Selepas seminggu',
			'metadataEdit.afterAMonth' => 'Selepas sebulan',
			'metadataEdit.onNextRefresh' => 'Selepas pembersihan',
			'metadataEdit.seasons' => 'Musim',
			'metadataEdit.show' => 'Pameran',
			'metadataEdit.hide' => 'menyembunyikan',
			'metadataEdit.episodeOrdering' => 'Episod Perintah',
			'metadataEdit.tmdbAiring' => 'Database Filem (Bahasa Inggeris)',
			'metadataEdit.tvdbAiring' => 'Perbincangan :Bahasa Inggeris (Bahasa Melayu)',
			'metadataEdit.tvdbAbsolute' => 'Perbincangan :DDB ( Absolute )',
			'metadataEdit.metadataLanguage' => 'Bahasa Metadata',
			'metadataEdit.useOriginalTitle' => 'Menggunakan tajuk asal',
			'metadataEdit.preferredAudioLanguage' => 'Bahasa audio yang disukai',
			'metadataEdit.preferredSubtitleLanguage' => 'Subtitle Bahasa yang disukai',
			'metadataEdit.subtitleMode' => 'Pilihan Subtitle Mode',
			'metadataEdit.manuallySelected' => 'dipilih secara manual',
			'metadataEdit.shownWithForeignAudio' => 'Diterbitkan dengan audio asing',
			'metadataEdit.alwaysEnabled' => 'Selalu dibenarkan',
			'metadataEdit.tags' => 'Tag :',
			'metadataEdit.addTag' => 'Tambah tag',
			'metadataEdit.genre' => 'Jenis',
			'metadataEdit.director' => 'Pengarah',
			'metadataEdit.writer' => 'Penulis',
			'metadataEdit.producer' => 'Penerbit',
			'metadataEdit.country' => 'negara',
			'metadataEdit.collection' => 'Koleksi',
			'metadataEdit.label' => 'Label',
			'metadataEdit.quickTag' => 'Tag yang cepat...',
			'matchScreen.match' => 'Perlawanan ...',
			'matchScreen.fixMatch' => 'Menyelesaikan perlawanan...',
			'matchScreen.unmatch' => 'Perlawanan',
			'matchScreen.unmatchConfirm' => 'Plex memperlakukan perlawanan ini sebagai tidak bertanding sehingga selesai.',
			'matchScreen.unmatchSuccess' => 'item yang tidak sesuai',
			'matchScreen.unmatchFailed' => 'Kegagalan untuk Unmatch item',
			'matchScreen.matchApplied' => 'Perlawanan yang digunakan',
			'matchScreen.matchFailed' => 'gagal melaksanakan perlawanan',
			'matchScreen.titleHint' => 'Tajuk',
			'matchScreen.yearHint' => 'Tahun yang',
			'matchScreen.search' => 'Pencarian',
			'matchScreen.noMatchesFound' => 'Tiada perlawanan yang ditemui',
			'serverTasks.title' => 'Tugas Pelayan',
			'serverTasks.failedToLoad' => 'Kegagalan mengisi tugas',
			'serverTasks.noTasks' => 'Tiada tugas yang berjalan',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Terhubung',
			'trakt.connectedAs' => ({required Object username}) => 'Terhubung dengan @${username}',
			'trakt.disconnectConfirm' => 'Mengalih keluar akaun Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG akan berhenti menghantar acara ke Trakt. anda boleh menyambung semula pada bila-bila masa.',
			'trakt.scrobble' => 'Pengeluaran masa nyata scrobbling',
			'trakt.scrobbleDescription' => 'Hantar permainan, istirahat, dan menghentikan peristiwa kepada Trakt semasa pemutaran.',
			'trakt.watchedSync' => 'Sinkronkan status yang dilihat',
			'trakt.watchedSyncDescription' => 'Apabila anda menandakan item seperti yang dilihat di PlezyNG, mereka juga ditandakan seperti yang dilihat di Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Menghubungkan Seerr',
			'seerr.serverUrl' => 'Pelayan URL',
			'seerr.serverUrlHelper' => 'alamat instans anda',
			'seerr.checkServer' => 'teruskan',
			'seerr.signInWithJellyfin' => 'Mendaftar dengan Jellyfin',
			'seerr.signInWithEmby' => 'Mendaftar dengan Emby',
			'seerr.signInWithLocal' => 'Menggunakan akaun tempatan',
			'seerr.email' => 'Email yang',
			'seerr.noSignInMethods' => 'Contoh Seerr ini tidak menawarkan sokongan kaedah log masuk PlezyNG.',
			'seerr.instance' => 'instans',
			'seerr.disconnectConfirm' => 'Menghubungkan Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG akan melupakan instans Seerr ini. sambungkan semula pada bila-bila masa.',
			'seerr.request' => 'Permintaan',
			'seerr.request4k' => 'Permintaan dalam 4K',
			'seerr.seasons' => 'Musim',
			'seerr.allSeasons' => 'Semua musim',
			'seerr.advancedOptions' => 'Kemajuan',
			'seerr.destinationServer' => 'Pelayan Destinasi',
			'seerr.qualityProfile' => 'Profil Kualiti',
			'seerr.rootFolder' => 'Rujukan folder',
			'seerr.languageProfile' => 'Profil Bahasa Melayu',
			'seerr.tags' => 'Tag :',
			'seerr.noTags' => 'Tiada tags',
			'seerr.defaultOption' => ({required Object name}) => '${name} (Defektif)',
			'seerr.animeNote' => 'Seri ini merupakan anime.',
			'seerr.requestSubmitted' => 'Permohonan yang dikemukakan',
			'seerr.requestFailed' => ({required Object error}) => 'Permohonan gagal: ${error}',
			'seerr.requestsLoadFailed' => 'Tidak boleh memuatkan opsyen permintaan',
			'seerr.nothingToRequest' => 'Semua sudah tersedia atau diminta.',
			'seerr.statusAvailable' => 'Tersedia',
			'seerr.statusPartiallyAvailable' => 'Bahagian tersedia',
			'seerr.statusRequested' => 'Permohonan',
			'seerr.statusProcessing' => 'Pemprosesan',
			'seerr.statusBlocklisted' => 'Terjejas',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Tidak boleh mencapai ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Tiada permohonan Seerr di ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Sebuah proxy terbalik yang mengesahkan (SSO atau HTTP auth) dijawab daripada Seerr. PlezyNG tidak boleh mendaftar melalui: biarkan laluan /api/v1 Seerr melepasi proxy untuk aplikasi ini, atau gunakan alamat yang mencapai Seerr secara langsung.',
			'seerr.invalidUrl' => 'Masukkan alamat pelayan seperti https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Contoh Seerr ini tidak menyokong Quick Connect.Ia memerlukan Seerr 3.4 atau lebih baru.',
			'seerr.notInitialized' => 'instans Seerr ini tidak menyelesaikan setup pertama berjalan',
			'seerr.noPlexTokenForReauth' => 'No. Plex token boleh didaftarkan semula',
			'seerr.noStoredCredentials' => 'Tiada maklumat log masuk tersimpan untuk log masuk semula',
			'seerr.signInRejected' => 'Sign-in telah ditolak',
			'seerr.noSessionCookie' => 'Seerr tidak mengeluarkan kuki sesi',
			'seerr.freshCookieRejected' => 'Seerr menolak kuki sesi baru',
			'seerr.noUserInformation' => 'Seerr tidak mengembalikan maklumat pengguna',
			'seerr.sessionRejectedAfterReauth' => 'Mesyuarat itu ditolak selepas penandatanganan semula.',
			'seerr.permissionDenied' => 'Seerr menafikan tindakan ini: akaun anda tidak lagi mempunyai kebenaran yang diperlukan',
			'seerr.permissionRevoked' => 'Anda tidak lagi mempunyai keizinan untuk meminta ini',
			'services.title' => 'Perkhidmatan',
			'services.hubSubtitle' => 'Sync menonton kemajuan dan meminta tajuk baru.',
			'services.integrations' => 'Integrasi',
			'services.notConnected' => 'Tidak terhubung',
			'services.connectedAs' => ({required Object username}) => 'Terhubung dengan @${username}',
			'services.scrobble' => 'Menjejaki kemajuan secara automatik',
			'services.scrobbleDescription' => 'Memperbaharui senarai anda apabila anda menyelesaikan episod atau filem.',
			'services.disconnectConfirm' => ({required Object service}) => 'Menghilangkan sambungan ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG akan berhenti mengemas kini ${service}. sambungkan semula pada bila-bila masa.',
			'services.connectFailed' => ({required Object service}) => 'Saya tidak boleh menyambung ke ${service}. cuba lagi.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Perbincangan Simkl',
			'services.simklReconnect.subtitle' => 'Simkl adalah penarikan kaedah log masuk yang menggunakan sambungan ini. penyambungan semula membuka simkl.com untuk meluluskan PlezyNG — PlezyNG tidak pernah melihat kata laluan anda. sejarah jam anda kekal pada Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Mengaktifkan PlezyNG pada ${service}',
			'services.deviceCode.instructions' => 'Mengimbas kod QR, atau lawati alamat di bawah dan masukkan kod ini:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Buka ${service} untuk mengaktifkan',
			'services.deviceCode.copyCode' => 'Menyalin kod pengaktifan',
			'services.deviceCode.waitingForAuthorization' => 'Menunggu kelulusan...',
			'services.deviceCode.codeCopied' => 'Kod yang disalin',
			'services.oauthProxy.title' => ({required Object service}) => 'Mendaftar di ${service}',
			'services.oauthProxy.body' => 'Memindai kod QR ini atau buka URL pada mana-mana peranti.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Buka ${service} untuk mendaftar',
			'services.pendingAuth.copyUrl' => 'Mendaftar dalam URL',
			'services.pendingAuth.urlCopied' => 'URL yang disalin',
			'services.libraryFilter.title' => 'Filter Perpustakaan',
			'services.libraryFilter.subtitleAllSyncing' => 'Menyusun semua perpustakaan',
			'services.libraryFilter.subtitleNoneSyncing' => 'Tiada apa-apa yang disinkronkan',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} disekat',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} dibenarkan',
			'services.libraryFilter.mode' => 'Filter Mode',
			'services.libraryFilter.modeBlacklist' => 'Senarai hitam',
			'services.libraryFilter.modeWhitelist' => 'Putih',
			'services.libraryFilter.modeHintBlacklist' => 'Sinkronkan setiap perpustakaan kecuali yang disemak di bawah.',
			'services.libraryFilter.modeHintWhitelist' => 'Simak hanya perpustakaan yang disemak di bawah.',
			'services.libraryFilter.libraries' => 'Pustaka',
			'services.libraryFilter.noLibraries' => 'Tiada perpustakaan yang tersedia',
			'services.libraryFilter.modeDescription' => 'Pilih sama ada perpustakaan yang disemak terhalang daripada menyegerakkan atau merupakan satu-satunya perpustaka yang menyegerakan.',
			'services.seerrDescription' => 'Hubungi Seerr atau Overseerr untuk mencari tajuk dan mengemukakan permintaan media.',
			'services.trackerDescriptions.trakt' => 'Sinkronkan episod dan filem yang dilihat dengan akaun Trakt anda.',
			'services.trackerDescriptions.mal' => 'Menyegerakkan senarai anime dan menonton kemajuan dengan MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Menyegerakkan senarai anime dan menonton kemajuan dengan AniList.',
			'services.trackerDescriptions.simkl' => 'Sync menonton filem, rancangan televisyen, dan anime dengan Simkl.',
			'services.trackerDescriptions.mdblist' => 'Tunjukkan penarafan MDBList dan senarai dalam cadangan dan Cari.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Menambah ${product} pelayan',
			'addServer.serverUrls' => 'Penyimpanan URL',
			'addServer.serverUrlsHelper' => 'Multiple URL dibenarkan, dipisahkan oleh commas.',
			'addServer.findServer' => 'Cari pelayan',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Mencari pelayan tempatan ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Pelayan tempatan ${product}',
			'addServer.username' => 'Nama Pengguna',
			'addServer.password' => 'kata laluan',
			'addServer.signIn' => 'Log masuk',
			'addServer.change' => 'Perubahan',
			'addServer.required' => 'diperlukan',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Tidak boleh mencapai pelayan: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Pendaftaran yang gagal: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect kegagalan: ${error}',
			'addServer.addPlexTitle' => 'Mendaftar dengan Plex',
			'addServer.pinExpired' => 'PIN telah tamat sebelum log masuk.Sila cuba lagi.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Akaun yang gagal didaftarkan: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Masukkan URL pelayan ${product} anda',
			'addServer.addConnectionTitle' => 'Menambah sambungan',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Menambah kepada ${name}',
			'addServer.signInWithPlexCard' => 'Mendaftar dengan Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Mengesahkan peranti ini. pelayan yang dikongsi ditambah.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Mengaktifkan akaun Plex. pengguna rumah menjadi profil.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Hubungi ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Masukkan URL, nama pengguna dan kata laluan pelayan anda.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Mendaftar masuk ke pelayan ${product} anda. menghubungkan ke ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Pinjaman daripada profil lain',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Menggunakan semula sambungan profil lain. profil yang dilindungi PIN memerlukan PIN.',
			'addServer.invalidCredentials' => 'Nama pengguna atau kata laluan yang tidak sah',
			'addServer.authResponseNotJson' => 'Jawapan pengesahan tidak sah JSON',
			'addServer.authResponseIncomplete' => 'Jawapan pendaftaran daripada pelayan tidak lengkap',
			'addServer.quickConnectRejected' => 'Quick Connect telah ditolak oleh pelayan',
			'addServer.quickConnectNotJson' => 'Jawapan Quick Connect tidak sah JSON',
			'addServer.quickConnectMissingFields' => 'Jawapan Quick Connect kekurangan kod atau rahsia',
			'addServer.quickConnectPollRejected' => 'Quick Connect pertanyaan telah ditolak oleh pelayan',
			'addServer.serverTimedOut' => 'Pelayan tidak bertindak balas dalam masa',
			'addServer.responseNotJson' => 'Jawapan pelayan tidak sah JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Jawapan itu kekurangan ID atau nama pelayan - adakah ini pelayan ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Tidak boleh mencapai pelayan: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Masukkan sekurang-kurangnya satu URL pelayan ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Tiada pelayan yang boleh diakses ${product} ditemui',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'URL ini menunjuk kepada pelayan yang berbeza ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'URL ini tidak sepadan dengan pelayan ${product}',
			'addServer.redirectUnsupported' => 'Pelayan yang dialihkan ke URL yang tidak disokong',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Server yang diarahkan ke host yang berbeza.Masukkan URL akhir ${product} secara langsung.',
			'addServer.redirectInsecure' => 'Pelayan yang diarahkan semula daripada HTTPS ke URL yang tidak selamat',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Pelayan yang diarahkan semula ke URL yang tidak disokong.Masukkan URL akhir ${product} secara langsung.',
			'addServer.directPlexServerUrl' => 'Plex URL pelayan',
			'addServer.directPlexServerUrlHelper' => 'Masukkan IP dan port tempatan pelayan media Plex anda.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (pilihan)',
			'addServer.plexTokenHelper' => 'Tinggalkan kosong jika akses tanpa auth dibenarkan pada pelayan ini.',
			'addServer.plexTokenRequired' => 'Sila masukkan token Plex anda (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (Lokal / Langsung)',
			'addServer.connectDirectPlexCardSubtitle' => 'Sambungkan secara langsung menggunakan IP atau URL tempatan tanpa akaun plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Hubungi secara langsung menggunakan IP atau URL tempatan. Hubungi ${name}.',
			'addServer.insecureTitle' => 'sambungan yang tidak disulitkan',
			'addServer.insecureDescription' => ({required Object url}) => '${url} menggunakan HTTP. Orang lain dalam rangkaian boleh membaca atau mengubah kata laluan, token dan media anda. Gunakan HTTPS jika tersedia. Teruskan hanya jika anda mempercayai rangkaian ini dan menerima risikonya.',
			'addServer.allowHttp' => 'Benarkan HTTP',
			'addServer.httpsRequired' => 'Menggunakan HTTPS atau secara eksplisit membenarkan sambungan yang tidak disulitkan.',
			'cast.chooseDevice' => 'Hantar ke peranti',
			'cast.searching' => 'Mencari peranti yang dikeluarkan...',
			'cast.connectedTo' => ({required Object device}) => 'Menghubungkan ke ${device}',
			'cast.device' => 'Peranti penghantaran',
			'cast.readyToCast' => 'Sedia untuk dihantar',
			'cast.subtitle' => 'Sari kata',
			'cast.serverNotAvailable' => 'Media server tidak tersedia.',
			'cast.stopCasting' => 'Hentikan penghantaran',
			'cast.castToDevice' => 'Hantar ke peranti',
			'cast.noEpisodeAvailable' => 'Tiada episod yang boleh ditayangkan.',
			'cast.startFailed' => 'Tidak boleh memulakan casting. semak pelayan dan cuba lagi.',
			'automation.noActivePlayback' => 'Tiada sesi video aktif untuk dikendalikan.',
			'notifications.newEpisodeTitle' => 'Episod baru',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Cuba setiap ciri percuma selama 7 hari',
			'appAccess.description' => 'Memulakan percubaan tujuh hari dengan akses penuh kepada setiap ciri PlezyNG. tiada bayaran semasa percubaan dan tiada langganan.Selepas percubaan, satu pembelian seumur hidup pada harga kedai anda membuka PlezyNG seumur hidup.',
			'appAccess.trialEndedDescription' => 'Membuka kunci setiap ciri dalam PlezyNG untuk hidup dengan satu pembelian pada harga kedai anda.',
			'appAccess.startTrial' => 'Mulakan percubaan percuma 7 hari',
			'appAccess.trialActive' => 'Ujian penuh 7 hari anda aktif.',
			'appAccess.trialEnded' => 'Perbicaraan 7 hari telah berakhir',
			'appAccess.trialStartFailed' => 'Saya tidak boleh menyimpan percubaan pada peranti ini. sila cuba lagi.',
			'appAccess.lifetimeTitle' => 'PlezyNG dikunci untuk seumur hidup',
			'appAccess.lifetimeBody' => 'Terima kasih! anda mempunyai akses seumur hidup kepada setiap fungsi PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG akses seumur hidup',
			'appAccess.manageDescription' => 'Cuba setiap ciri percuma selama 7 hari, kemudian membuka semua untuk seumur hidup dengan satu pembayaran pada harga kedai anda.',
			'appAccess.buy' => ({required Object price}) => 'Membuka semua ciri untuk ${price}',
			'appAccess.loadingPrice' => 'Harga kedai yang dibayar...',
			'appAccess.retryPrice' => 'Kembali ke harga lookup',
			'appAccess.restore' => 'Restorasi pembelian seumur hidup',
			'appAccess.pending' => 'Pembelian anda sedang menunggu pembayaran atau kelulusan. akses seumur hidup dibuka sebaik sahaja kedai melengkapkannya.',
			'appAccess.storeUnavailable' => 'Pastikan anda mendaftar di kedai dan pembelian dibenarkan pada peranti ini.',
			'appAccess.productNotFound' => 'PlezyNG seumur hidup tidak tersedia di kedai ini sehingga kini.',
			'appAccess.productQueryFailed' => 'Tidak boleh memuatkan harga kedai. semak sambungan anda dan cuba lagi.',
			'appAccess.purchaseFailed' => 'Pembelian tidak berjalan. cuba lagi.',
			'appAccess.restoreFailed' => 'Tidak boleh sampai ke kedai untuk memulihkan pembelian anda. cuba lagi.',
			'appAccess.nothingToRestore' => 'Nombor PlezyNG pembelian seumur hidup telah ditemui untuk akaun kedai ini.',
			'detail.endsAt' => ({required Object time}) => 'Berakhir pada ${time}',
			'watchLink.serverUnavailable' => 'Saya tidak boleh mencapai server Plex untuk pautan ini.',
			'watchLink.notFound' => 'Saya tidak boleh menemui persembahan atau filem ini pada pelayan anda Plex.',
			'watchLink.ambiguous' => 'Link ini sepadan dengan item pada lebih daripada satu pelayan.Tambah pelayan ke pautan.',
			'watchLink.plexOnly' => 'Lihat pautan pada masa ini hanya menyokong Plex pelayan.',
			'watchLink.unsupportedItem' => 'Lihat pautan hanya boleh membuka persembahan atau filem.',
			'watchLink.menuItem' => 'Lihat link',
			'watchLink.dialogTitle' => 'Lihat link',
			'watchLink.dialogShowHint' => 'Membuka pautan ini memainkan episod seterusnya.Tambah &mode=shuffle ke hujung untuk memainkan persembahan di shuffle.',
			'watchLink.dialogMovieHint' => 'Membuka pautan ini memainkan filem ini.',
			'watchLink.copy' => 'Salin',
			'watchLink.copied' => 'Link yang disalin',
			'homeLayout.title' => 'Susun atur laman utama',
			'homeLayout.resetToast' => 'Home Reset ke layout asli Plezy hero',
			'homeLayout.resetHeroTitle' => 'Mengembalikan tataletak pahlawan kepada stok Plezy?',
			'homeLayout.resetHeroBody' => 'Mengalih keluar seting wira setiap baris dan membawa kembali satu banner berputar di bahagian atas rumah, seperti sebelum baris wira wujud.',
			'homeLayout.removeRowTitle' => 'Menghilangkan Home Range?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} akan dipadamkan. ini tidak boleh dikecualikan.',
			'homeLayout.sync' => 'Sinkron',
			'homeLayout.syncAccountTitle' => 'Sinkronkan tataletak dengan akaun Plex anda',
			'homeLayout.syncAccountOn' => 'Pada: peranti ini berkongsi urutan, baris, Hero dan Auto-slide dengan peranti lain anda.',
			'homeLayout.syncAccountOff' => 'Off: Peranti ini mengekalkan tataletak sendiri.',
			'homeLayout.syncNow' => 'Sinkronkan sekarang',
			'homeLayout.plexHomeManager' => 'Plex Pengurus Rumah',
			'homeLayout.managePlexRows' => 'Menguruskan Plex baris dalam Plezy',
			'homeLayout.managePlexRowsDescription' => 'Terbuka untuk menganjurkan baris-baris yang dipilih di rumah',
			'homeLayout.organizeHomeRows' => 'Mengatur rangkaian rumah',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} baris: bergerak, Hero, Auto-slide, menghapuskan',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Mengatur ${library} baris',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Teruskan Menonton + ${n} baris: bergerak, Perpustakaan, Rumah, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Render sebagai kad pahlawan',
			'homeLayout.heroOnlySingleCollection' => 'Hanya boleh didapati apabila baris ini diselesaikan kepada tajuk sebenar satu koleksi',
			'homeLayout.hero' => 'Sepanduk utama',
			'homeLayout.autoSlide' => 'Slaid automatik',
			'homeLayout.autoSlideDescription' => 'Arrows (PC) dan d-pad (TV) sentiasa berfungsi dan memulakan semula timer.',
			'homeLayout.autoSlideEditDescription' => 'Ia juga bergerak sendiri setiap beberapa saat. keluar: hanya bergerak apabila anda mengklik anak panah (PC) atau tekan kiri/kanan pada remote (TV).',
			'homeLayout.enableHeroFirst' => 'Membolehkan Hero Pertama',
			'homeLayout.showOnHome' => 'Menampilkan pada skrin rumah',
			'homeLayout.home' => 'rumah',
			'homeLayout.removeFromHome' => 'Keluar dari rumah',
			'homeLayout.selectRowsFirst' => 'Pilih baris rumah di bawah terlebih dahulu.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex baris yang dikendalikan',
			'homeLayout.continueWatching' => 'Menyambung tontonan',
			'homeLayout.continueWatchingLibraryDescription' => 'Perpustakaan ini mempunyai rangkaian kemajuan semula',
			'homeLayout.continueWatchingHomeDescription' => 'Rangkaian kemajuan semula yang ditunjukkan di Home',
			'homeLayout.nextUpHomeDescription' => 'Next Unwatched episode rangkaian dipaparkan secara berasingan di Home',
			'homeLayout.library' => 'Pustaka',
			'homeLayout.showInRecommended' => 'Pameran dalam Perpustakaan yang disyorkan',
			'homeLayout.customPlexRow' => 'Perbezaan Plex baris',
			'homeLayout.heroNeedsLibrary' => 'Periksa Perpustakaan Pertama — Hero Perlu Di Mana-mana Untuk Tunjukkan',
			'homeLayout.heroNeedsSurface' => 'Periksa Perpustakaan atau Rumah terlebih dahulu — Hero perlu di mana-mana untuk menunjukkan',
			'homeLayout.removeHub' => 'Menghilangkan Hub',
			'homeLayout.noPlexRows' => 'Nombor Plex baris yang dikendalikan dikembalikan untuk perpustakaan ini.',
			'homeLayout.openDetails' => 'Maklumat Terbuka',
			'homeLayout.heroCards' => 'Pemenang Kartu',
			'homeLayout.tapHeroCard' => 'Menangkap Kad Pahlawan',
			'homeLayout.tvPlayFocus' => 'Remote TV: menonjolkan butang Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad ke bawah berhenti pada butang Main sebelum bergerak ke baris seterusnya.',
			'homeLayout.tvWrap' => 'Remote TV: Kartu Pahlawan Loop',
			'homeLayout.tvWrapDescription' => 'Pada kad terakhir akan kembali ke kad pertama. berhenti pada kad terakhir. kiri pada kad pertama akan sentiasa pergi ke bar samping.',
			'homeLayout.castOnHero' => 'Bermain dengan banner pahlawan',
			'homeLayout.castOnHeroDescription' => 'Tunjukkan cast di bahagian bawah banner pahlawan. di luar hanya tajuk dan ringkasan.',
			'homeLayout.customRows' => 'Rangkaian Custom',
			'homeLayout.loading' => 'Home » Layout ...',
			'homeLayout.noCustomRows' => 'Tiada rangkaian biasa lagi',
			'homeLayout.addRowHint' => 'Gunakan Add Home row untuk membuat satu.',
			'homeLayout.addHomeRow' => 'Menambah Home Ronde',
			'homeLayout.addHomeRowDescription' => 'Pilih kategori; baris baru ditambah kepada Penganjur secara automatik',
			'homeLayout.removeRow' => 'Menghapuskan baris',
			'homeLayout.recentlyAdded' => 'baru-baru ini ditambah',
			'homeLayout.recentlyReleased' => 'baru-baru ini dikeluarkan',
			'homeLayout.movieCollections' => 'Koleksi filem',
			'homeLayout.showCollections' => 'Tunjukkan koleksi',
			'homeLayout.rowTitle' => 'Tajuk Row',
			'homeLayout.content' => 'Kesan',
			'homeLayout.showThisRowIn' => 'Tunjukkan baris ini dalam:',
			'homeLayout.libraryRecommended' => 'Perpustakaan yang disyorkan',
			'homeLayout.heroCard' => 'Pemenang Kartu',
			'homeLayout.heroCardDescription' => 'Menunjukkan sebagai satu kad berputar lebar penuh bukannya poster shelf.',
			'homeLayout.heroUnavailableDescription' => 'Hanya boleh didapati apabila baris ini diselesaikan kepada tajuk sebenar satu koleksi - dengan lebih daripada satu koleksi dipilih tidak ada satu tajuk untuk berputar melalui.',
			'homeLayout.librariesSelection' => 'Perpustakaan (meninggalkan semua tidak disemak untuk termasuk setiap perpustakaan)',
			'homeLayout.librariesMergedDescription' => 'Setiap perpustakaan yang disemak di sini digabungkan ke dalam satu baris ini.',
			'homeLayout.movieCollectionsSelection' => 'Koleksi filem (meninggalkan semua tidak disemak untuk setiap perpustakaan yang dipilih)',
			'homeLayout.showCollectionsSelection' => 'Tunjukkan koleksi (meninggalkan semua tidak disemak untuk setiap perpustakaan yang dipilih)',
			'homeLayout.collectionRowsDescription' => 'Jika satu koleksi bertanding, tajuk-tajuknya dipaparkan secara langsung dalam baris.Jika lebih daripada satu bertanding, setiap koleksi dipaparkan sebagai satu poster — ketiknya untuk membuka koleksi itu.',
			'homeLayout.allCollections' => 'Semua Koleksi',
			'homeLayout.noRowsHere' => 'Tiada baris di sini lagi.',
			'homeLayout.hideWatchedRows' => 'Menutup item yang dilihat dalam baris',
			'homeLayout.hideWatchedRowsDescription' => 'Judul yang dipantau sepenuhnya meninggalkan Rumah dan perpustakaan baris yang disyorkan.',
			'homeLayout.untitledCollection' => 'Koleksi yang tidak bertajuk',
			'homeLayout.moveRowHint' => 'Up/Down: bergerak baris · Pilih: turun di sini · Kembali: dibatalkan',
			'homeLayout.organizeRowsHint' => 'Pilih pada baris (atau tahan Pilih): pindah · Kiri/Kiri: pilihan baris · Kembali: selesai',
			'homeLayout.layoutNavDescription' => 'Pilih baris, perpustakaan, dan kategori koleksi',
			'homeLayout.editHomeRow' => 'Edit rumah rangkaian',
			'homeLayout.resetHeroButton' => 'Mengembalikan tataletak pahlawan kepada stok Plezy',
			'homeLayout.reorderingUnlocked' => 'Penyelesaian semula diselesaikan',
			'homeLayout.reorderingLocked' => 'Penyelesaian Locked',
			'homeLayout.rowsCanBeDragged' => 'Roda boleh ditarik — tekan kunci untuk mengelakkan',
			'homeLayout.tapLockToDrag' => 'Tekan kunci untuk menarik baris',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Jumlah : ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'menyembunyikan',
			'homeLayout.remove' => 'Keluarkan',
			'homeLayout.libraryResumeRow' => 'Rujukan semula perpustakaan ini',
			'homeLayout.pressAgainToDelete' => 'Tekan lagi untuk memadamkan',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'Pada',
			'homeLayout.resetHeroButtonDescription' => 'Mengalih keluar seting wira setiap baris dan membawa kembali satu banner berputar di atas, seperti sebelum baris wira wujud.',
			'homeLayout.tapHeroCardDescription' => 'Pilih sama ada menandakan atau memilih kad Hero memulakan playback atau membuka butiran.',
			'homeLayout.heroTapPlayDescription' => 'Mulakan item yang dipilih dengan segera.',
			'homeLayout.heroTapDetailsDescription' => 'Buka butiran item yang dipilih sebelum memilih tindakan.',
			'platform.localNetworkPermission' => 'PlezyNG menyambung ke pelayan media dan peranti playback anda di rangkaian tempatan anda.',
			'platform.locationPermission' => 'PlezyNG menggunakan akses lokasi apabila iOS memerlukan untuk mengesan rangkaian tempatan anda dan menyambung ke pelayan media anda.',
			'platform.photoLibraryPermission' => 'Pilih imej daripada perpustakaan foto anda untuk digunakan sebagai karya seni media.',
			'platform.cameraPermission' => 'Mengimbas kod QR untuk menggabungkan Companion Remote.',
			'universalMedia.title' => 'Media Terbuka',
			'universalMedia.shortcutHelp' => 'Mainkan pautan, senarai main atau fail untuk sesi ini.',
			'universalMedia.intro' => 'Buka pautan, senarai main, atau fail. Playback menggunakan pemain standard PlezyNG dan tidak menambah sejarah kepada perpustakaan anda.',
			'universalMedia.openWhat' => 'Apa yang anda mahu buka?',
			'universalMedia.stream' => 'Alamat aliran',
			'universalMedia.playlist' => 'Senarai Playlist',
			'universalMedia.files' => 'Peranti fail',
			'universalMedia.favorites' => 'Penyimpanan Stream Favorit',
			'universalMedia.address' => 'Alamat Media',
			'universalMedia.addressHelp' => 'URL dengan parameter pengesahan atau tandatangan yang diiktiraf hanya digunakan untuk sesi ini dan tidak boleh disimpan sebagai kegemaran.',
			'universalMedia.displayName' => 'Nama Pameran ( opsional )',
			'universalMedia.displayNameHelp' => 'Pilih nama pendek untuk pemutar dan kawalan media sistem.',
			'universalMedia.allowHttp' => 'Membolehkan sambungan HTTP yang tidak disulitkan',
			'universalMedia.allowHttpHelp' => 'HTTP tidak menyulitkan sambungan. membenarkan ia hanya pada rangkaian yang dipercayai. gunakan HTTPS apabila mungkin.',
			'universalMedia.advancedProtocols' => 'MPV sahaja: masukkan alamat RTSP, RTMP/RTMPS, UDP, atau RTP. Alamat ini tidak boleh disimpan sebagai kegemaran.',
			'universalMedia.liveStream' => 'Perlakukan sebagai hidup',
			'universalMedia.liveStreamHelp' => 'Gunakan ini untuk video atau radio secara langsung. aplikasi menyembunyikan bar masa, melompat butang, dan pergi ke masa opsyen.',
			'universalMedia.privateSession' => 'Hanya playback ini menggunakan alamat.Save a eligible stream favorite to keep it in this profile.',
			'universalMedia.saveFavorite' => 'Selamatkan kegemaran',
			'universalMedia.playNow' => 'Bermain sekarang',
			'universalMedia.favoriteSaved' => 'Stream favorit disimpan ke profil ini',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${count} masuk senarai main yang tidak disokong atau tidak selamat.', ), 
			'universalMedia.playlistAddress' => 'Alamat Playlist',
			'universalMedia.playlistAddressHelp' => 'Buka senarai m3U, M3U8, atau PLS daripada alamat web. pautan siaran langsung tidak menyimpan senarai main.',
			'universalMedia.choosePlaylist' => 'Pilih fail playlist',
			'universalMedia.openPlaylist' => 'Senarai Permainan Terbuka',
			'universalMedia.playlistFormatsHelp' => 'Senarai main boleh mengandungi sehingga 1,000 item dan 2 MB. HLS terbuka sebagai aliran supaya pemain boleh memilih kualiti.',
			'universalMedia.saveQueuePlaylist' => 'Simpan baris gilir sebagai senarai main',
			'universalMedia.queuePlaylistSaved' => 'Senarai main disimpan di sebelah fail media.',
			'universalMedia.queuePlaylistUnavailable' => 'Baris gilir ini tidak dapat disimpan sebagai senarai main setempat yang boleh digunakan semula.',
			'universalMedia.queuePlaylistFolderRequired' => 'Pilih lokasi simpanan dalam folder yang sama dengan fail dalam baris gilir.',
			'universalMedia.noFavorites' => 'Tiada rangkaian kegemaran disimpan sehingga kini. kekal dalam profil ini.',
			'universalMedia.removeFavorite' => 'Menghapuskan stream kegemaran',
			'universalMedia.filesHelp' => 'Pilih fail audio, video, atau ISO untuk tempoh sementara. fail dan URL tidak ditambah kepada sejarah perpustakaan.',
			'universalMedia.chooseFiles' => 'Pilih fail',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${count} fail yang dipilih', ), 
			'universalMedia.wifiTransfer' => 'Hantar fail melalui Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Memindahkan fail yang disokong daripada pelayar pada rangkaian yang sama dipercayai.',
			'universalMedia.wifiTransferIntro' => 'Buka alamat ini dalam pelayar pada peranti lain. pilih fail untuk menambahnya ke perpustakaan Fail dan buku peranti ini.',
			'universalMedia.wifiTransferPrivacy' => 'Peranti ini menerima fail melalui rangkaian tempatan anda. sesiapa sahaja yang tahu alamat ini boleh menghantar fail sehingga anda berhenti pemindahan atau alamat tamat tempoh selepas 15 minit. maksimum: 100 fail, 4 GiB per fail, 10 GiB total.',
			'universalMedia.wifiTransferStarting' => 'Menyediakan pemindahan peribadi dan terhad ...',
			'universalMedia.wifiTransferUnavailable' => 'Tidak boleh memulakan pemindahan. semak akses rangkaian tempatan dan cuba lagi.',
			'universalMedia.openThisAddress' => 'Buka salah satu daripada alamat ini pada peranti penghantaran',
			'universalMedia.copyAddress' => 'Menyalin alamat pemindahan',
			'universalMedia.addressCopied' => 'Alamat pemindahan disalin',
			'universalMedia.transferExpires' => ({required Object time}) => 'Alamat ini tamat tempoh dalam ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(n, other: '${count} fail yang diterima', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Pengenalan kepada ${size}',
			'universalMedia.stopTransfer' => 'Hentikan pemindahan dan membatalkan alamat',
			'universalMedia.startTransfer' => 'Mulakan pemindahan',
			'universalMedia.wifiImportedFiles' => 'Penghantaran Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Hantar fail kepada PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Pilih audio, video, ebook, atau komik fail untuk dihantar. fail disimpan dalam perpustakaan fail dan buku peranti ini. maksimum: 100 fail, 4 GiB setiap fail, 10 GiB total.',
			'universalMedia.uploadFilesLabel' => 'fail untuk menghantar',
			'universalMedia.uploadSelected' => 'Muat naik fail yang dipilih',
			'universalMedia.uploadSelectFirst' => 'Pilih satu atau lebih fail terlebih dahulu.',
			'universalMedia.uploading' => 'Penghantaran',
			'universalMedia.uploadComplete' => 'Fail ditambah kepada PlezyNG.',
			'universalMedia.uploadFailed' => 'Fail tidak boleh ditambah.Tahan halaman ini terbuka dan cuba lagi.',
			'universalMedia.liveCue' => 'hidup',
			'universalMedia.liveSession' => 'Penghantaran Live Stream',
			'universalMedia.liveCueHelp' => 'Untuk video atau radio secara langsung, aplikasi menyembunyikan bar masa dan melompat butang. ia tidak menyimpan alamat atau menonton sejarah.',
			'universalMedia.sessionOnly' => 'Playback ini merupakan sesi sahaja.',
			'universalMedia.sessionOnlyHelp' => 'Playback tidak pernah menyimpan kemajuan atau sejarah.Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'Gambar penyesuaian',
			'universalMedia.pictureHelp' => 'Perubahan imej ini hanya menjejaskan playback ini. mereka menetapkan semula apabila playback berakhir.',
			'universalMedia.resetPicture' => 'Reset imej',
			'universalMedia.brightness' => 'Cahaya',
			'universalMedia.contrast' => 'kontras',
			'universalMedia.gamma' => 'Perbezaan Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Penghormatan',
			'universalMedia.view360' => 'Pemandangan rata untuk video 360 darjah',
			'universalMedia.view360Help' => 'MPV memerlukan penapis v360 FFmpeg untuk pandangan ini.',
			'universalMedia.view360Unavailable' => 'Pembinaan MPV ini tidak boleh menggunakan penapis 360 darjah.',
			'universalMedia.view360Yaw' => 'pandangan horizontal',
			'universalMedia.view360Pitch' => 'Pandangan Vertikal',
			'universalMedia.view360FieldOfView' => 'Bidang pandangan',
			'universalMedia.recordStream' => 'Rekod Live Stream',
			'universalMedia.stopRecording' => 'Hentikan dan simpan rekod',
			'universalMedia.recordingStarted' => 'Rekod aktif. meninggalkan playback berhenti dan menyimpan rakaman.',
			'universalMedia.recordingSaved' => 'Rekod selesai dan diselamatkan.',
			'universalMedia.recordingActive' => 'Mengikut peranti ini. meninggalkan playback berhenti dan menyimpannya.',
			'universalMedia.recordingFormatHelp' => 'Untuk video, pilih MKV atau MPEG-TS. untuk audio, pilih MKA atau MKV.',
			'universalMedia.replaceRecordingTitle' => 'Menggantikan rekod ini?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG mengembalikan fail yang sedia ada semasa rakaman.Jika ia tidak dapat menyimpan rakaman baru, Plezyng memulihkan sandaran.',
			'universalMedia.replaceRecording' => 'Menggantikan fail',
			'universalMedia.discHelp' => 'Buka cakera dalam cakera optik komputer ini.Anda juga boleh membuka imej ISO daripada fail Peranti.',
			'universalMedia.discs' => 'cakera optik',
			'universalMedia.editionOrTitle' => 'Edisi atau tajuk cakera',
			'universalMedia.dvd' => 'Perkhidmatan DVD',
			'universalMedia.bluray' => 'Perbezaan Blu-ray',
			'universalMedia.audioCd' => 'CD audio',
			'universalMedia.discAvailability' => 'Disk playback memerlukan pembinaan MPV yang kompatibel, cakera disokong, dan kebenaran sistem operasi. ia tidak boleh melebihi perlindungan cakera komersial.',
			'universalMedia.converterTitle' => 'Menukar fail media tempatan',
			'universalMedia.converterHelp' => 'Menukar fail tempatan atau mengubahnya dengan FFmpeg.',
			'universalMedia.converterIntro' => 'Menukar fail audio atau video tempatan kepada format yang berfungsi pada lebih banyak peranti.',
			'universalMedia.converterPrivacy' => 'FFmpeg mesti dipasang pada komputer ini.Conversion hanya membaca fail tempatan.Ia tidak memuat turun aliran atau menghapuskan DRM.',
			'universalMedia.converterChooseInput' => 'Pilih fail media tempatan',
			'universalMedia.converterFormat' => 'Format output',
			'universalMedia.converterMp4' => 'MP4 · H.264 dan AAC',
			'universalMedia.converterM4a' => 'M4A · AAC audio',
			'universalMedia.converterMp3' => 'MP3 dan audio',
			'universalMedia.allowFtp' => 'membenarkan FTP',
			'universalMedia.allowFtpHelp' => 'FTP menghantar media tanpa penyulitan. gunakan hanya pada rangkaian yang dipercayai.',
			'universalMedia.converterSaveAs' => 'Menyelamatkan media yang ditukar sebagai',
			'universalMedia.converterExtensionMismatch' => 'Pilih nama fail dengan ekstensi output yang dipilih.',
			'universalMedia.converterUnsupportedInput' => 'Pilih fail audio atau video.',
			'universalMedia.converterLocalOnly' => 'Fail yang dipilih tidak tersedia sebagai laluan peranti tempatan.',
			'universalMedia.converterReplaceTitle' => 'Menggantikan fail ini?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG mengembalikan fail yang sedia ada sehingga salinan yang ditukar disimpan.',
			'universalMedia.converterStarting' => 'Bermula daripada FFmpeg...',
			'universalMedia.converterProgress' => 'Menukar kepada komputer ini ...',
			'universalMedia.converterComplete' => 'Konversi selesai. fail baru telah siap.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg kekurangan atau tidak menyokong format ini.',
			'universalMedia.converterFailed' => 'Periksa bahawa fail sumber boleh dibaca dan destinasi mempunyai ruang percuma yang mencukupi.',
			'universalMedia.converterCancelled' => 'Konversi dibatalkan. hasil yang tidak lengkap telah dihapuskan.',
			'universalMedia.converterDesktopOnly' => 'Konversi tempatan boleh didapati pada komputer desktop dengan FFmpeg dipasang.',
			'universalMedia.converterStart' => 'Menukar fail',
			'universalMedia.mediaToolsTitle' => 'Alat Media',
			'universalMedia.mediaToolsShortcut' => 'Menangkap atau berkongsi media, menambah ekstensi carian, atau gunakan baris perintah.',
			'universalMedia.mediaToolsIntro' => 'Pilih alat berfokus. capture dan stream-out menggunakan FFmpeg yang dipasang pada desktop ini. ekstensi dan perintah CLI menggunakan permintaan HTTPS yang terhad dan aliran Open media yang sedia ada.',
			'universalMedia.mediaToolsAccessibility' => 'Pilihan alat dan kawalan berfungsi dengan sentuhan, penunjuk, papan kekunci, dan fokus D-pad. Rekod, perkongsian, dan perubahan status carian diumumkan.',
			'universalMedia.mediaTool' => 'Alat Media',
			'universalMedia.captureIntro' => 'Mencatat skrin atau kamera anda ke fail MP4 pada komputer ini. FFmpeg perlu dipasang dan termasuk kod H.264.',
			'universalMedia.captureNoDevices' => 'Tiada skrin atau kamera ditemui. semak sokongan penangkapan FFmpeg dan keizinan privasi sistem operasi.',
			'universalMedia.captureSource' => 'skrin atau kamera',
			'universalMedia.captureScreen' => 'skrin',
			'universalMedia.captureAudioSource' => 'Pengenalan audio ( opsional )',
			'universalMedia.captureAudioHelp' => 'Tambah audio daripada mikrofon atau input yang tersedia. pilihan peranti bergantung kepada FFmpeg dan keizinan sistem.',
			'universalMedia.captureAudioNone' => 'Tiada audio',
			'universalMedia.captureDefaultAudio' => 'Pengenalan audio lalai',
			'universalMedia.captureWaylandHelp' => 'Wayland membatasi penangkapan XWayland ini kepada X display. Windows di luar XWayland mungkin tidak muncul.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.captureFrameRate' => 'Kadar rakaman',
			'universalMedia.capturePrivacy' => 'Rekod disimpan hanya untuk fail yang anda pilih. penangkapan mikrofon adalah opsional. PlezyNG tidak memuat naik rekod.',
			'universalMedia.captureSaveAs' => 'Menyimpan rekod skrin sebagai',
			'universalMedia.captureExtensionMismatch' => 'Pilih nama fail yang berakhir dalam .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg atau kod video H.264 tidak boleh didapati.Memasang pembinaan FFmpeg yang disokong, kemudian cuba lagi.',
			'universalMedia.captureFailed' => 'Pendaftaran tidak boleh disimpan. semak kebenaran peranti, penyimpanan yang tersedia, dan sokongan FFmpeg.',
			'universalMedia.captureSaved' => 'Rekod skrin disimpan.',
			'universalMedia.captureElapsedLabel' => 'Masa rekod',
			'universalMedia.captureStart' => 'Mulakan rekod',
			'universalMedia.capturePreview' => 'Pratonton dalam pemain',
			'universalMedia.capturePreviewHelp' => 'Pratonton sumber yang dipilih dalam pemain standard. Pratonton hanya untuk sesi ini dan tidak menyimpan rakaman. Sokongan peranti dan keizinan bergantung pada MPV dan sistem pengendalian. Pratonton menggunakan video sahaja; audio pilihan boleh disertakan dalam rakaman yang disimpan.',
			'universalMedia.capturePreviewActive' => 'Pratonton langsung · tidak merakam',
			'universalMedia.captureStop' => 'berhenti dan menyelamatkan',
			'universalMedia.captureMode' => 'Penangkapan',
			'universalMedia.shareMode' => 'berkongsi',
			'universalMedia.shareIntro' => 'Hantar fail media tempatan ke peranti lain di rangkaian peribadi anda. PlezyNG mewujudkan aliran sementara HLS.',
			'universalMedia.sharePrivacy' => 'Sesiapa sahaja di rangkaian tempatan anda yang menerima pautan peribadi boleh menonton sementara ia aktif. pautan tamat tempoh selepas 60 minit. berhenti berkongsi untuk menutup pelayan dan membatalkan pautan.',
			'universalMedia.shareChooseFile' => 'Pilih fail media',
			'universalMedia.shareChooseHelp' => 'Pilih fail audio atau video tempatan. fail itu kekal pada komputer ini.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg atau kod H.264/AAC tidak tersedia.Memasang FFmpeg dengan sokongan kod H.264 dan AAC.',
			'universalMedia.shareFailed' => 'Aliran tidak boleh bermula atau berhenti secara tidak dijangka. semak FFmpeg dan akses rangkaian.',
			'universalMedia.shareActive' => 'Stream bersedia di rangkaian peribadi anda.',
			'universalMedia.shareEnded' => 'Media telah mencapai akhir dan tidak lagi dibahagikan.',
			'universalMedia.shareStopped' => 'Perkongsian berhenti. pautan sementara tidak lagi sah.',
			'universalMedia.shareUrlCopied' => 'alamat yang disalin.',
			'universalMedia.shareOpenUrl' => 'Buka alamat ini dalam satu pemain pada peranti lain',
			'universalMedia.shareQrLabel' => 'Kod QR untuk alamat aliran sementara',
			'universalMedia.shareQrHelp' => 'Scan dengan pemain yang kompatibel yang disambungkan ke rangkaian peribadi yang sama.',
			'universalMedia.shareHttpHint' => 'Stream ini menggunakan HTTP yang tidak disulitkan. dalam PlezyNG, biarkan HTTP sebelum membuka.',
			'universalMedia.shareCopyUrl' => 'Menyalin alamat Stream',
			'universalMedia.shareExpiresLabel' => 'Link akan tamat pada',
			'universalMedia.shareStarting' => 'Menyediakan aliran ...',
			'universalMedia.shareStart' => 'Mulakan perkongsian',
			'universalMedia.shareStop' => 'Berhenti berkongsi',
			'universalMedia.extensionsMode' => 'Perpanjangan dan CLI',
			'universalMedia.extensionsIntro' => 'Tambah data-hanya ekstensi carian untuk mencari media. Pilih hasil untuk memuat naik ke borang yang biasa Open media.',
			'universalMedia.extensionsPrivacy' => 'Manifesto boleh menentukan satu titik akhir carian HTTPS dan medan tindak balas peta. ia tidak boleh menjalankan kod, menambah tajuk permintaan, membaca fail, atau melancarkan perintah shell.',
			'universalMedia.extensionImport' => 'Menambah Perpanjangan manifest',
			'universalMedia.extensionEmpty' => 'Tiada perkhidmatan carian lagi. pilih fail manifest JSON yang boleh dipercayai untuk menambah satu.',
			'universalMedia.extensionChoose' => 'Perkhidmatan Pencarian',
			'universalMedia.extensionSearchConsent' => 'Setiap carian menghantar kata-kata anda kepada perkhidmatan HTTPS ini. hasil dibuka hanya selepas anda memilih satu.',
			'universalMedia.extensionSearchLabel' => 'Pencarian Media',
			'universalMedia.extensionSearch' => 'Pencarian',
			'universalMedia.extensionSearching' => 'Mencari ...',
			'universalMedia.extensionNoResults' => 'Tiada hasil media yang selamat dikembalikan. cuba carian lain.',
			'universalMedia.extensionInstallTitle' => 'Menambah perkhidmatan carian ini?',
			'universalMedia.extensionReplaceTitle' => 'Memperbaharui perkhidmatan carian ini?',
			'universalMedia.extensionService' => 'Perkhidmatan',
			'universalMedia.extensionEndpoint' => 'HTTPS titik akhir',
			'universalMedia.extensionConsent' => 'Teks carian anda dihantar ke perkhidmatan ini. manifesto tidak mengandungi kod yang boleh dijalankan. teruskan hanya jika anda mempercayai titik akhir ini.',
			'universalMedia.extensionInstall' => 'menambah perkhidmatan',
			'universalMedia.extensionReplace' => 'Perkhidmatan Update',
			'universalMedia.extensionRemoveTitle' => 'Menghapuskan perkhidmatan carian ini?',
			'universalMedia.extensionRemoveHelp' => 'Ini menghapuskan perkhidmatan daripada profil ini.PlezyNG tidak menghubungi titik akhir.',
			'universalMedia.extensionRemove' => 'Hentikan Perkhidmatan',
			'universalMedia.extensionInvalidManifest' => 'Fail ini bukan manifest lanjutan yang disokong. lihat panduan Open media untuk format.',
			'universalMedia.extensionSaveFailed' => 'Perpanjangan tidak boleh disimpan ke profil aktif.',
			'universalMedia.extensionSearchFailed' => 'Perkhidmatan carian tidak mengembalikan jawapan yang sah. semak titik akhir dan cuba lagi.',
			'universalMedia.cliTitle' => 'Garis Perintah',
			'universalMedia.cliHelp' => 'Gunakan panduan plezyctl untuk mengesahkan manifesto atau mencari ekstensi yang sama. Ulasan perkhidmatan HTTPS sebelum setiap carian. Hasil dibuka dalam borang media yang sedia ada; pilih butang playback untuk memulakan.',
			'universalMedia.cliCopyExample' => 'Contoh perintah salinan',
			'universalMedia.cliCopied' => 'contoh yang disalin.',
			'fileSources.title' => 'fail dan buku',
			'fileSources.subtitle' => 'Membaca, mendengarkan, dan menonton daripada fail anda sendiri.',
			'fileSources.add' => 'Menambah sumber',
			'fileSources.importFiles' => 'Pengimportan fail',
			'fileSources.localFiles' => 'Pada peranti ini',
			'fileSources.source' => 'Sumber',
			'fileSources.name' => 'Nama',
			'fileSources.endpoint' => 'Pelayan URL',
			'fileSources.smbEndpointHint' => 'Contoh: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Masukkan pelayan SMB dan satu folder kongsi.',
			'fileSources.root' => 'Folder atau awalan',
			'fileSources.smbFolderHelp' => 'Biarkan kosong untuk menggunakan seluruh folder kongsi, atau masukkan folder di dalamnya.',
			'fileSources.username' => 'Nama Pengguna',
			'fileSources.smbDomain' => 'Domain (pilihan)',
			'fileSources.password' => 'kata laluan',
			'fileSources.token' => 'API token',
			'fileSources.accessKey' => 'Akses ke kunci ID',
			'fileSources.secretKey' => 'Kunci akses rahsia',
			'fileSources.sessionToken' => 'Token sesi ( opsional )',
			'fileSources.region' => 'Daerah',
			'fileSources.clientId' => 'Pengenalan kepada OAuth Client ID',
			'fileSources.clientSecret' => 'OAuth Client Secret (hanya desktop Google)',
			'fileSources.allowHttp' => 'Benarkan HTTP tanpa penyulitan pada rangkaian yang dipercayai',
			'fileSources.smbEncryption' => 'Sulitkan sambungan SMB3',
			'fileSources.smbEncryptionHint' => 'Gunakan penyulitan SMB3 apabila NAS menyokongnya.',
			'fileSources.connect' => 'Sambung',
			'fileSources.cancel' => 'Batalkan',
			'fileSources.save' => 'menyelamatkan',
			'fileSources.close' => 'Tutup',
			'fileSources.removeSource' => 'Penyambung sumber',
			'fileSources.disconnectMessage' => 'Putuskan sambungan sumber ini? Fail yang dimuat turun serta sejarah bacaan dan pendengaran anda akan kekal pada peranti ini.',
			'fileSources.localFolder' => 'Pilih folder',
			'fileSources.empty' => 'Tiada apa-apa di sini',
			'fileSources.emptyHint' => 'Tambah sumber atau import buku, buku audio, muzik, atau video.',
			'fileSources.search' => 'Cari folder ini',
			'fileSources.searchCached' => 'Pencarian untuk perpustakaan diselamatkan',
			'fileSources.refresh' => 'Menyejukkan',
			'fileSources.loadMore' => 'muat lebih banyak',
			'fileSources.offline' => 'Terdapat offline',
			'fileSources.download' => 'Tetap offline',
			'fileSources.removeDownload' => 'Menghapuskan offline copy',
			'fileSources.continueReading' => 'Teruskan bacaan',
			'fileSources.continueListening' => 'Teruskan Dengarkan',
			'fileSources.continueWatching' => 'Menyambung tontonan',
			'fileSources.read' => 'Bacaan',
			'fileSources.listen' => 'Dengarkan',
			'fileSources.play' => 'Bermain',
			'fileSources.pause' => 'Henti Sejenak',
			'fileSources.stop' => 'Berhenti',
			'fileSources.startOver' => 'Bermula di atas',
			'fileSources.finished' => 'selesai',
			'fileSources.markFinished' => 'Mark telah selesai',
			'fileSources.markUnfinished' => 'Mark yang tidak selesai',
			'fileSources.editions' => 'Edisi dan fail',
			'fileSources.chapters' => 'Bab',
			'fileSources.bookmarks' => 'Buku dan nota',
			'fileSources.bookmark' => 'Menambah Bookmark',
			'fileSources.highlight' => 'Peningkatan',
			'fileSources.note' => 'Nota',
			'fileSources.delete' => 'Padam',
			'fileSources.export' => 'Notis eksport',
			'fileSources.exported' => 'Notis yang dieksport',
			'fileSources.sync' => 'Sinkronkan kemajuan',
			'fileSources.synced' => 'Kemajuan bersin',
			'fileSources.conflict' => 'Peranti lain mempunyai kedudukan yang berbeza. pilih di mana untuk meneruskan.',
			'fileSources.useLocal' => 'Gunakan peranti ini',
			'fileSources.useRemote' => 'Menggunakan peranti lain',
			'fileSources.history' => 'Sejarah Posisi',
			'fileSources.groupAudio' => 'Mendengar sebagai satu buku audio',
			'fileSources.groupHint' => 'Menggabungkan fail audio yang kini dimuat naik dalam folder ini. muat semua halaman terlebih dahulu.',
			'fileSources.order' => 'Perintah fail',
			'fileSources.moveUp' => 'bergerak ke atas',
			'fileSources.moveDown' => 'bergerak ke bawah',
			'fileSources.speed' => 'Kelajuan Playback',
			'fileSources.sleep' => 'Waktu Tidur',
			'fileSources.sleepOff' => 'keluar',
			'fileSources.endChapter' => 'Akhir daripada bab',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ms'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minit', ), 
			'fileSources.skipBack' => 'Kembali ke Sk',
			'fileSources.skipForward' => 'melompat ke hadapan',
			'fileSources.smartRewind' => 'Kembali ke Smart selepas istirahat',
			'fileSources.playbackOptions' => 'Pilihan pendengaran',
			'fileSources.remaining' => ({required Object time}) => '${time} yang tersisa',
			'fileSources.contents' => 'Kandungan',
			'fileSources.readerSettings' => 'Membaca seting',
			'fileSources.fontSize' => 'Saiz teks',
			'fileSources.lineHeight' => 'Garis ruang',
			'fileSources.margin' => 'Margin',
			'fileSources.font' => 'Jenis muka',
			'fileSources.serif' => 'Serif',
			'fileSources.sans' => 'Tanpa serif',
			'fileSources.mono' => 'Monospace',
			'fileSources.columns' => 'Kolom',
			'fileSources.scroll' => 'Bergerak secara vertikal',
			'fileSources.justify' => 'Jajarkan teks pada kedua-dua sisi',
			'fileSources.readerTheme' => 'Penampilan halaman',
			'fileSources.appTheme' => 'Mengikuti tema app',
			'fileSources.paper' => 'kertas',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Malam yang',
			'fileSources.readAloud' => 'Bacakan halaman ini dengan kuat',
			'fileSources.readAlong' => 'Baca sambil mendengar',
			'fileSources.stopReading' => 'Hentikan Narrasi',
			'fileSources.searchBook' => 'Pencarian dalam buku',
			'fileSources.noMatches' => 'Tiada perlawanan',
			'fileSources.previousPage' => 'Halaman Sebelumnya',
			'fileSources.nextPage' => 'Halaman seterusnya',
			'fileSources.page' => ({required Object number}) => 'Halaman ${number}',
			'fileSources.externalBlocked' => 'Rujukan buku luaran disekat dalam pembaca.',
			'fileSources.loading' => 'Pembukaan...',
			'fileSources.narrator' => 'Penyanyi',
			'fileSources.audio' => 'Audio yang',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'Ebook',
			'fileSources.all' => 'Semua',
			'fileSources.downloads' => 'fail offline',
			'fileSources.confirmDelete' => 'Alih keluar salinan luar talian yang dipilih? Kedudukan bacaan atau pendengaran dan nota anda akan disimpan.',
			'fileSources.errorAuthentication' => 'Log masuk semula untuk menyambungkan semula sumber ini.',
			'fileSources.errorPermission' => 'Sumber ini tidak memberikan akses kepada fail yang diminta.',
			'fileSources.errorUnavailable' => 'Sumber tidak tersedia. cuba lagi, atau buka salinan offline.',
			'fileSources.errorUnsupported' => 'Format atau sambungan ini tidak disokong pada peranti ini.Sila semak panduan tetapan sumber.',
			'fileSources.errorInvalidData' => 'Fail atau jawapan pelayan ini tidak boleh dibaca dengan selamat.',
			'fileSources.errorCancelled' => 'Operasi telah dibatalkan.',
			'fileSources.errorConflict' => 'Kedudukan berubah dalam sesi lain. buka semula item untuk memilih kedudukan.',
			'fileSources.signIn' => 'Log masuk',
			'fileSources.reconnect' => 'Sambungan semula',
			'fileSources.folderHelp' => 'Biarkan kosong untuk bermula pada akar sumber. URL S3 termasuk bucket.',
			'fileSources.preferences' => 'Persyaratan',
			'fileSources.timePosition' => 'Kedudukan',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Subtitle trek',
			'fileSources.none' => 'Tiada',
			'fileSources.fullscreen' => 'skrin penuh',
			'fileSources.syncLocation' => 'folder Sink progress (pilihan)',
			'fileSources.syncLocationHint' => 'folder WebDAV yang didedikasikan untuk PlezyNG status. menggunakan penulisan bersyarat; media kekal tidak berubah.',
			'fileSources.audiobooks' => 'Buku audio',
			'fileSources.comics' => 'Komik',
			'fileSources.scan' => 'Scan untuk buku dan media',
			'fileSources.browserReader' => 'Pembaca Terbuka',
			'fileSources.browserReaderHelp' => 'Membaca dibuka dalam pelayar anda.Jadilah PlezyNG terbuka untuk menyimpan lokasi dan nota anda.',
			'fileSources.on' => 'Pada',
			'fileSources.advancedSetup' => 'Pendaftaran App',
			'fileSources.microsoftSignIn' => 'Mendaftar dengan Microsoft',
			'fileSources.zoomIn' => 'Zoom dalam',
			'fileSources.zoomOut' => 'Zoom keluar',
			'fileSources.fitPage' => 'Halaman yang sesuai',
			'fileSources.fitWidth' => 'Sesuai lebar',
			'fileSources.actualSize' => 'Saiz semasa',
			'fileSources.goToPage' => 'Pergi ke halaman',
			'fileSources.goToSection' => 'Pergi ke bab',
			'fileSources.pageRange' => ({required Object count}) => 'Masukkan nombor dari 1 hingga ${count}',
			'fileSources.pageLayout' => 'Laman Layout',
			'fileSources.automatic' => 'automatik',
			'fileSources.singlePage' => 'Halaman tunggal',
			'fileSources.twoPages' => '2 Halaman',
			'fileSources.readingDirection' => 'Membaca arah',
			'fileSources.leftToRight' => 'kiri ke kanan',
			'fileSources.rightToLeft' => 'Kanan ke kiri',
			'fileSources.letterSpacing' => 'Surat yang meliputi',
			'fileSources.wordSpacing' => 'Perkataan ruang',
			'fileSources.readerControlsHelp' => 'Jarakkan dua jari atau gunakan kawalan zum untuk membesarkan halaman. Seret untuk mengalihkan halaman. Ctrl/⌘ dengan + atau − melaraskan zum; Ctrl/⌘ dengan 0 menetapkannya semula. Page Up dan Page Down menyelak halaman.',
			'fileSources.imagePage' => 'Halaman Komik',
			'fileSources.resetReader' => 'Menetapkan semula keutamaan bacaan',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Menggunakan fail dan buku',
			'fileSources.cancelScan' => 'Batalkan pemindaian',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Terdapat Limit Download Offline',
			'fileSources.offlineQuotaHelp' => 'Tetapkan ruang maksimum yang digunakan oleh salinan offline, fail yang diimport, dan muat turun. Mengurangkan had tidak menghapuskan salinan sedia ada.',
			'fileSources.offlineStorageUsage' => 'Penyimpanan Offline',
			'fileSources.reservedStorage' => 'Penyimpanan',
			'fileSources.downloadQueue' => 'Mengunduh Queue',
			'fileSources.downloadRunning' => 'Dimuat turun',
			'fileSources.downloadQueued' => 'Menunggu',
			'fileSources.downloadPaused' => 'beristirahat',
			'fileSources.downloadFailed' => 'keperluan penarikan diri',
			'fileSources.importing' => 'Pengimportan',
			'fileSources.importInterrupted' => 'Import dihentikan · menghapuskan untuk membersihkan',
			'fileSources.errorQuotaExceeded' => 'Batas penyimpanan offline telah dicapai. menaikkan had atau menghapuskan salinan yang dimuat turun.',
			'fileSources.errorStorageLow' => 'Tiada penyimpanan peranti percuma yang mencukupi untuk mengekalkan simpanan yang dilindungi.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG tidak boleh memeriksa penyimpanan peranti percuma, jadi penulisan dihentikan.',
			'fileSources.removeDownloadJob' => 'Menghapus download',
			'fileSources.downloadAlreadyComplete' => 'Download ini selesai sebelum ia boleh dihapuskan. item kini tersedia offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Menghapuskan muat turun ini dan menyingkirkan sebarang data yang dimuat turun sebahagiannya? kedudukan dan nota anda akan kekal.',
			'lending.title' => 'Perpustakaan Awam',
			'lending.add' => 'Menambah perpustakaan',
			'lending.other' => 'Perpustakaan lain',
			'lending.libraryName' => 'Nama Perpustakaan',
			'lending.libraryUrl' => 'Laman web perpustakaan',
			'lending.libraryUrlHint' => 'Gunakan katalog perpustakaan anda atau halaman log masuknya.',
			'lending.intro' => 'Pinjaman daripada perpustakaan anda.Tahan buku anda dekat.',
			'lending.handoff' => 'Log masuk, pinjam dan baca dengan selamat melalui perkhidmatan perpustakaan anda sendiri.',
			'lending.openService' => 'Perpustakaan Terbuka',
			'lending.findLibrary' => 'Cari perpustakaan',
			'lending.search' => 'Mencari buku dan penulis',
			'lending.catalogue' => 'Katalog',
			'lending.loans' => 'Pinjaman',
			'lending.holds' => 'Tempahan',
			'lending.signIn' => 'Mendaftar dengan perpustakaan anda',
			'lending.waiting' => 'Hentikan pendaftaran dalam pelayar anda, kemudian kembali ke sini.',
			'lending.cancel' => 'Batalkan',
			'lending.disconnect' => 'Menghapuskan perpustakaan',
			'lending.disconnectMessage' => 'Alih keluar perpustakaan ini daripada profil ini? Pinjaman dan tempahan anda kekal dengan perpustakaan.',
			'lending.getBook' => 'Dapatkan buku',
			'lending.checkAvailability' => 'Periksa ketersediaan',
			'lending.available' => 'tersedia untuk pinjaman',
			'lending.unavailable' => 'Tidak tersedia pada masa ini',
			'lending.borrow' => 'Pinjam',
			'lending.placeHold' => 'Buat tempahan',
			'lending.returnBook' => 'Kembali awal',
			'lending.cancelHold' => 'Batalkan tempahan',
			'lending.confirmBorrow' => 'Adakah anda meminjam tajuk ini daripada perpustakaan anda?',
			'lending.confirmReturn' => 'Pulangkan judul ini sekarang? Anda mungkin perlu meminjamnya semula untuk meneruskan.',
			'lending.confirmCancelHold' => 'Batalkan tempahan anda untuk judul ini?',
			'lending.email' => 'Pastikan pemberitahuan email',
			'lending.due' => ({required Object date}) => 'Tarikh pemulangan: ${date}',
			'lending.queue' => ({required Object position}) => 'Posisi ${position} dalam baris',
			'lending.empty' => 'Tiada tajuk di sini.',
			'lending.openLibraryNote' => 'Terokai katalog Open Library. Pilihan membaca dan meminjam dipaparkan pada halaman setiap judul.',
			'lending.more' => 'muat lebih banyak',
			'lending.gateway' => 'Perpustakaan Perkhidmatan Sign-in',
			'lending.gatewayHint' => 'disediakan oleh perpustakaan anda atau pentadbir PlezyNG.',
			'lending.advanced' => 'Integrasi Perpustakaan',
			'lending.loadLibraries' => 'Pilih perpustakaan anda',
			'lending.expired' => 'Pinjaman ini telah tamat tempoh.',
			'lending.updated' => 'Perpustakaan dikemaskini',
			'lending.continueService' => 'Teruskan dalam perkhidmatan',
			'lending.comingSoon' => 'Pinjaman dalam aplikasi · Datang segera',
			'lending.comingSoonDescription' => 'Anda boleh menggunakan perpustakaan anda di Libby semasa kami selesai menghubungkannya.',
			'lending.suspendHold' => 'Tangguhkan tempahan',
			'lending.resumeHold' => 'Sambung semula tempahan',
			'lending.suspendMessage' => 'Kekalkan tempat anda dalam barisan dan benarkan pembaca seterusnya meminjam salinan ini? Anda boleh menyambung semula tempahan kemudian.',
			'lending.resumeMessage' => 'Sambung semula tempahan ini supaya perpustakaan boleh menawarkan salinan seterusnya yang tersedia?',
			'lending.editEmail' => 'Perubahan pemberitahuan e-mel',
			'audiobook.syncTitle' => 'Membaca & Mendengarkan Sync',
			'audiobook.syncHelp' => 'Tetapkan kedudukan bacaan, kedudukan pendengaran, status penyelesaian, penanda buku dan nota di seluruh peranti anda. Pilih akaun penyimpanan yang disertakan dan gunakan kod sinkron yang sama pada setiap peranti. Membaca dan mendengar kekal berasingan.',
			'audiobook.addSyncSource' => 'Tambah Google Drive, OneDrive, Dropbox, WebDAV atau S3 dalam Fail & Buku terlebih dahulu.',
			'audiobook.syncDestination' => 'Akaun Penyimpanan Sync',
			'audiobook.syncFolder' => 'Sinkron folder atau prefix',
			'audiobook.syncCode' => 'Kod Sinkron Peribadi',
			'audiobook.syncCodeHelp' => 'Mencipta kod pada peranti pertama anda, kemudian masukkan kod itu pada peranti lain anda. simpan salinan peribadi: ia adalah kunci kepada keadaan yang disulitkan anda. gunakan kod yang berbeza untuk setiap orang.',
			'audiobook.showCode' => 'Menunjukkan atau menyembunyikan kod sink',
			'audiobook.newSyncCode' => 'Mencipta kod sink baru',
			'audiobook.saveSync' => 'Penyimpanan dan Sync',
			'audiobook.disableSync' => 'Hentikan penyegerakan pada peranti ini',
			'audiobook.syncSourceDisconnect' => 'Menghapuskan sumber ini akan mematikan bacaan dan mendengar sink di sini. fail sink yang disulitkan akan kekal dalam pembekal.',
			'audiobook.syncReconnect' => 'Menghubungkan semula akaun penyimpanan',
			'audiobook.lastSynced' => ({required Object time}) => 'Terakhir disegerakkan di ${time}',
			'audiobook.syncConflicts' => 'Pilih di mana untuk mengembalikan',
			'audiobook.conflictHelp' => 'Perubahan-perubahan ini dibuat secara bebas. pilih kedudukan atau versi bookmark untuk disimpan. jam yang lebih lambat atau peratusan yang lebih tinggi tidak secara automatik menang.',
			'audiobook.syncDevice' => ({required Object device}) => 'Peranti ${device}',
			'audiobook.syncUnknownDevice' => 'Peranti yang tidak diketahui',
			'audiobook.deletedBookmark' => 'Tanda buku yang dihapuskan',
			'audiobook.finished' => 'selesai',
			'audiobook.readingPosition' => ({required Object percent}) => 'Pembacaan · ${percent}%',
			'audiobook.chapterTimeline' => 'Bab Kemajuan',
			'audiobook.bookTimeline' => 'Buku Keseluruhan Kemajuan',
			'audiobook.bookRemaining' => ({required Object time}) => 'Waktu yang tersisa dalam buku ini: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Waktu yang tersisa dalam bab ini: ${time}',
			'audiobook.unknownRemaining' => 'Jumlah masa yang tersedia apabila bahagian-bahagian dimainkan',
			'audiobook.undoSeek' => 'Permintaan Terakhir',
			'audiobook.customSpeed' => 'Kelajuan Playback yang disesuaikan',
			'audiobook.speedHelp' => 'Pilih kelajuan daripada 0.25× kepada 4×.',
			'audiobook.apply' => 'Permohonan',
			'audiobook.customSleep' => 'Tarikh Tidur Khas',
			'audiobook.sleepMinutes' => 'Jadual : 1 - 1440',
			'audiobook.sleepChapters' => ({required Object count}) => 'Berhenti selepas ${count} bab',
			'audiobook.extendSleep' => 'Tambah 5 minit',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Jadual tidur : ${time}',
			'audiobook.useDefaults' => 'Gunakan kawalan pendengaran ini untuk buku baru',
			'audiobook.librarySort' => 'Perbezaan buku',
			'audiobook.sortTitle' => 'Tajuk',
			'audiobook.sortAuthor' => 'Penulis',
			'audiobook.sortNarrator' => 'Penceramah',
			'audiobook.sortSeries' => 'Perintah siri',
			'audiobook.sortRecent' => 'baru-baru ini dibuka',
			'audiobook.statusFilter' => 'Status bacaan',
			'audiobook.statusAll' => 'Semua buku',
			'audiobook.statusNew' => 'Tidak bermula',
			'audiobook.statusProgress' => 'dalam kemajuan',
			'audiobook.statusFinished' => 'selesai',
			'audiobook.goToTime' => 'Pergi ke masa',
			'audiobook.timeHelp' => 'Jam : minit : detik atau minit : detik',
			'audiobook.recoveryHelp' => 'Eksport salinan yang disulitkan baru-baru ini sebelum memindahkan atau memperbaiki data sink. Import bergabung dengan keadaan semasa; mereka tidak pernah menggantikan sejarah sink tempatan. Simpan kod sink secara berasingan.',
			'audiobook.recoveryExport' => 'Mengeksport fail pemulihan yang disulitkan',
			'audiobook.recoveryImport' => 'Import fail pemulihan yang disulitkan',
			'audiobook.recoveryImportConfirm' => 'Menggabungkan fail pemulihan yang disulitkan ini dengan kedudukan bacaan semasa dan nota? sejarah yang sedia ada akan dikekalkan. perpustakaan berkongsi dan ID item tidak termasuk; tetapkan ID yang sepadan pada setiap peranti sebelum mengimport.',
			'audiobook.recoveryExported' => 'Fail pemulihan yang disulitkan disimpan.',
			'audiobook.recoveryImported' => 'Data pemulihan telah digabungkan.',
			'sourceSetup.savedCertificate' => 'Sijil pelayan yang disimpan',
			'sourceSetup.nfsEndpointInvalid' => 'Masukkan URL NFS, contohnya nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Tiada pelayan DLNA ditemukan. Masukkan URL perihalan peranti secara manual.',
			'sourceSetup.dlnaServers' => 'Pelayan media DLNA',
			'sourceSetup.dlnaUnavailable' => 'Penemuan DLNA tidak tersedia pada rangkaian ini. Masukkan URL perihalan peranti secara manual.',
			'sourceSetup.dlnaSearching' => 'Mencari pelayan DLNA pada rangkaian setempat',
			'sourceSetup.networkSearching' => 'Mencari pada rangkaian setempat…',
			'sourceSetup.dlnaDiscover' => 'Temukan pelayan DLNA',
			'sourceSetup.dlnaHelp' => 'Penemuan bergantung pada multisiar rangkaian setempat. Jika tiada pelayan muncul, masukkan URL perihalan perantinya di atas.',
			'sourceSetup.dlnaRoot' => 'ID objek DLNA; biarkan kosong untuk menggunakan akar peranti.',
			'sourceSetup.passwordOrKey' => 'Masukkan kata laluan atau tambah kunci peribadi di bawah.',
			'sourceSetup.sshFingerprint' => 'Cap jari SHA256 kunci hos SSH',
			'sourceSetup.sshFingerprintHelp' => 'Sahkan dengan pentadbir pelayan. Pada pelayan, jalankan ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub dan gunakan nilai SHA256-nya.',
			'sourceSetup.sshFingerprintKeep' => 'Biarkan kosong untuk mengekalkan cap jari yang ditetapkan sekarang, atau masukkan cap jari pelayan yang baharu.',
			'sourceSetup.sshAuthentication' => 'Pengesahan SSH dengan kunci awam',
			'sourceSetup.sshAuthenticationHelp' => 'Pilihan; pengesahan dengan kata laluan juga disokong.',
			'sourceSetup.privateKey' => 'Kunci peribadi (format PEM atau OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Frasa laluan kunci peribadi',
			'sourceSetup.nfsMountPort' => 'Port TCP perkhidmatan lekap NFS',
			'sourceSetup.nfsMountPortHelp' => 'Lalai: 20048',
			'sourceSetup.nfsUserId' => 'ID pengguna NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Lalai: 1000. Gunakan ID yang dibenarkan oleh perkongsian NFS pada NAS.',
			'sourceSetup.nfsGroupId' => 'ID kumpulan NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Lalai: 1000. Gunakan ID kumpulan yang dibenarkan oleh perkongsian NFS pada NAS.',
			'sourceSetup.nfsEncryption' => 'Wajibkan NFS disulitkan (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Wajibkan TLS 1.3 untuk NFS dan perkhidmatan lekap. Jika NAS tidak menyokongnya, sambungan ditolak.',
			'sourceSetup.nfsTrustCertificate' => 'CA NFS tersuai atau sijil pelayan (PEM, pilihan)',
			'sourceSetup.nfsTrustHelp' => 'Biarkan kosong untuk sijil yang dipercayai oleh peranti ini. Jika perlu, tambah sijil CA persendirian atau sijil pelayan yang ditandatangani sendiri; namanya mesti sepadan dengan hos dalam URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Gunakan sijil CA atau pelayan dalam format PEM. Jangan sertakan kunci peribadi.',
			'sourceSetup.addTrustCertificate' => 'Tambah sijil kepercayaan tersuai',
			'sourceSetup.replaceTrustCertificate' => 'Gantikan sijil tersuai yang disimpan',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS menggunakan port NFS dan perkhidmatan lekap yang biasa serta memerlukan sokongan RFC 9289 pada NAS. TLS 1.3 diwajibkan. Nama hos atau IP mesti sepadan dengan sijil. AUTH_SYS UID/GID masih terpakai dalam saluran yang disulitkan.',
			'sourceSetup.clientCertificate' => 'Sijil klien (pilihan)',
			'sourceSetup.clientCertificateHelp' => 'Membolehkan NAS mengesahkan klien ini; ID AUTH_SYS masih bergantung pada dasar perkongsian NFS pada NAS.',
			'sourceSetup.savedIdentity' => 'Identiti klien yang disimpan akan digunakan.',
			'sourceSetup.replaceIdentity' => 'Gantikan identiti klien yang disimpan',
			'sourceSetup.chooseIdentity' => 'Pilih identiti klien PKCS#12',
			'sourceSetup.identityPassphrase' => 'Frasa laluan identiti klien',
			'sourceSetup.identityPassphraseHelp' => 'Biarkan kosong jika fail tiada frasa laluan.',
			'sourceSetup.removeIdentity' => 'Alih keluar sebarang identiti klien yang disimpan',
			'sourceSetup.identityStorageHelp' => 'Identiti klien disimpan dalam stor bukti kelayakan sumber yang disulitkan. Biarkan bahagian ini tidak berubah untuk mengekalkan identiti yang disimpan.',
			'sourceSetup.nfsLimitations' => 'NFSv3 baca sahaja melalui TCP. Tanpa RPC-with-TLS, trafik NFS tidak disulitkan. NAS mesti membenarkan ID AUTH_SYS yang dipilih dan port klien tanpa keistimewaan (sering dipanggil pilihan eksport “insecure”). NFSv4 dan UDP tidak disokong.',
			'sourceSetup.nfsSetupHelp' => 'Bantuan persediaan NFS',
			'sourceSetup.nfsSetupHint' => 'Semak tetapan ini jika sambungan tidak dapat dibuka.',
			'sourceSetup.nfsSetupDetails' => 'Gunakan perkongsian NFSv3 melalui TCP. Jika penyulitan diwajibkan, perkhidmatan NFS dan lekap mesti kedua-duanya menyokong RPC-with-TLS. Biarkan sijil tersuai kosong untuk sijil pelayan yang dipercayai oleh peranti ini, atau tambah sijil CA NAS atau sijil yang ditandatangani sendiri. Nama dalam sijil mesti sepadan dengan hos titik akhir. Jika NAS memerlukan pengesahan TLS dua hala, tambah identiti klien PKCS#12-nya. Akhir sekali, pastikan perkongsian membenarkan AUTH_SYS UID/GID yang dikonfigurasi serta dasar port klien.',
			'sourceSetup.ftpHelp' => 'FTP menggunakan mod pasif. Gunakan ftp:// untuk FTP tanpa penyulitan, ftpes:// untuk TLS eksplisit, atau ftps:// untuk TLS (implisit pada port 990; eksplisit pada port lain).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Carian sari kata pilihan untuk video kendiri.',
			'sourceSetup.apiKey' => 'Kunci API',
			'sourceSetup.optionalUsername' => 'Nama pengguna akaun (pilihan)',
			'sourceSetup.optionalPassword' => 'Kata laluan akaun (pilihan)',
			'sourceSetup.subtitlePrivacy' => 'Dapatkan kunci API daripada opensubtitles.com. Carian menghantar tajuk video dan ID IMDb/TMDB yang tersedia, bukan fail video sama sekali. Kunci dan bukti kelayakan akaun pilihan disulitkan bersama sumber ini.',
			'sourceSetup.automaticMetadata' => 'Metadata video dalam talian automatik',
			'sourceSetup.metadataPrivacy' => 'Hanya menghantar tajuk/tahun daripada nama fail dan nombor episod atau ID NFO; tidak sekali-kali menghantar media atau bukti kelayakan. Medan NFO kekal sebagai rujukan utama.',
			'sourceSetup.nfsEncryptionFailure' => 'Untuk NFS disulitkan, semak sokongan RFC 9289 dan TLS 1.3 pada kedua-dua perkhidmatan NAS, nama sijil dan UID/GID perkongsian. PlezyNG tidak akan mencuba semula sambungan ini tanpa penyulitan.',
			'sourceSetup.sourceConnecting' => 'Menyambung ke sumber',
			'sourceSetup.metadataSearchPrivacy' => 'Carian tajuk ini dihantar ke Trakt. Carian menghantar tajuk yang anda masukkan, bukan video atau bukti kelayakan sumber.',
			'sourceSetup.chooseMatch' => 'Pilih padanan',
			'sourceSetup.metadataMatchHelp' => 'Semak tajuk dan tahun sebelum memilih. Trakt menerima tajuk carian; video kekal pada sumbernya.',
			'sourceSetup.metadataNoMatches' => 'Tiada padanan tajuk dalam talian ditemukan. Cuba tajuk lain.',
			'sourceSetup.metadataSearch' => 'Cari metadata dalam talian',
			'sourceSetup.metadataLoading' => 'Mencari butiran filem dan rancangan TV dalam talian…',
			'sourceSetup.metadataFromTrakt' => 'Metadata dalam talian daripada Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Tiada padanan tajuk automatik ditemukan. Cari tajuk untuk memilih padanan.',
			'sourceSetup.metadataFailed' => 'Metadata dalam talian tidak dapat dimuatkan. Main balik dan butiran setempat masih tersedia.',
			'sourceSetup.videoDetailsLoading' => 'Memuatkan butiran video',
			'sourceSetup.subtitleKeyRequired' => 'Kunci API OpenSubtitles diperlukan',
			'sourceSetup.subtitleKeyHelp' => 'Edit sumber fail ini dan tambah kunci API OpenSubtitles dalam tetapan sari kata pilihannya.',
			'sourceSetup.subtitleSearchFailed' => 'Carian sari kata gagal. Semak kunci API, sambungan dan akses kepada perkhidmatan.',
			'sourceSetup.subtitleApplyFailed' => 'Sari kata ini tidak dapat dimuat turun atau digunakan. Semak sambungan dan cuba hasil lain.',
			'sourceSetup.subtitleSearch' => 'Cari di OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'Carian menggunakan tajuk dan ID IMDb/TMDB yang tersedia. Fail video kekal pada sumbernya. Semak bahasa, penanda sari kata paksa atau untuk orang kurang upaya pendengaran, serta penilaian sebelum memilih.',
			'sourceSetup.movieOrShow' => 'Filem atau rancangan TV',
			'sourceSetup.subtitleTitleHint' => 'Masukkan tajuk untuk memperincikan hasil',
			'sourceSetup.subtitleLanguage' => 'Bahasa sari kata',
			'sourceSetup.subtitleSearching' => 'Mencari di OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Tiada sari kata sepadan ditemukan. Cuba tajuk atau bahasa lain.',
			'sourceSetup.downloadSubtitle' => 'Muat turun sari kata',
			'sourceSetup.subtitle' => 'Sari kata',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS diperlukan',
			'sourceSetup.nfsUnencrypted' => 'NFS tidak disulitkan',
			'sourceSetup.tlsEncrypted' => 'Disulitkan dengan TLS',
			'sourceSetup.ftpPlain' => 'FTP tanpa penyulitan',
			'sourceSetup.sshPinned' => 'SSH disulitkan · kunci hos ditetapkan',
			'sourceSetup.smbEncrypted' => 'Penyulitan SMB3 dihidupkan',
			'sourceSetup.smbUnencrypted' => 'Penyulitan SMB3 dimatikan',
			'sourceSetup.httpUnencrypted' => 'HTTP tanpa penyulitan pengangkutan',
			'sourceSetup.checkEndpointSecurity' => 'Semak keselamatan titik akhir',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} diperlukan.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Masukkan ${label} antara ${min} dengan ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Gantikan ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Identiti klien yang dipilih: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Penilaian ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Memuat turun sari kata: ${title}',
			'sourceSetup.sharedEntryPair' => 'Berpasangan item ini',
			'sourceSetup.sharedEntryPairHelp' => 'Masukkan ID yang sama untuk item ini pada setiap peranti. Gunakan pengenalpastian kongsi yang stabil atau buat satu dan salin ke item yang sepadan. Kemajuan hanya berpasangan apabila jenis fail edisi, saiz, dan pesanan sesuai. Blank menghapuskan peta ini.',
			'sourceSetup.sharedEntryId' => 'Pengenalan item ID',
			'sourceSetup.generateSharedEntryId' => 'Mencipta item yang dikongsi ID',
			'sourceSetup.sharedLibraryId' => 'ID perpustakaan berkongsi (pilihan)',
			'sourceSetup.sharedLibraryHelp' => 'Gunakan ID yang sama pada peranti yang membuka perpustakaan yang sama. ID awam ini membantu membawa kemajuan bacaan dan nota melalui sambungan sumber yang berbeza; ia bukan kata laluan. Apabila pembekal menggunakan ID item yang berlainan, pasangan item tersebut daripada skrin terperinci mereka.',
			'sourceSetup.sharedLibraryInvalid' => 'Gunakan 8-100 huruf, nombor, titik, subscores atau hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Mencipta ID perpustakaan yang dikongsi',
			'sourceSetup.nfsReadAhead' => 'Permintaan bacaan NFS',
			'sourceSetup.nfsReadAheadHelp' => 'Lebih banyak bacaan serentak boleh meningkatkan pencapaian pada NAS atau rangkaian yang cepat. gunakan 1 jika pelayan mengehadkan permintaan yang sama.',
			'sourceSetup.nfsReadTest' => 'Mengukur prestasi bacaan NFS',
			'sourceSetup.nfsReadTestHelp' => 'Membaca sehingga 64 MiB daripada fail terbesar untuk mengukur sambungan NAS ini.',
			'sourceSetup.nfsQualificationResult' => 'NFS baca pengukuran',
			'sourceSetup.nfsReadBytes' => 'Data bacaan',
			'sourceSetup.nfsReadSpeed' => 'Kelajuan yang diukur',
			'sourceSetup.nfsReadRequests' => 'Membaca Permintaan',
			'sourceSetup.sharedEntryConflict' => 'ID item yang dikongsi ini telah digabungkan dengan item lain dalam perpustakaan ini. pilih ID yang berbeza.',
			'comics.fitHeight' => 'Muatkan mengikut tinggi',
			'comics.readingMode' => 'Mod bacaan',
			'comics.paged' => 'Halaman',
			'comics.webtoon' => 'Tatal berterusan',
			'comics.coverAlone' => 'Paparkan kulit buku secara berasingan',
			'comics.splitWide' => 'Bahagikan halaman lebar',
			'comics.splitWideHelp' => 'Paparkan setiap separuh secara berasingan mengikut urutan bacaan. Paparan dua halaman bersebelahan dijeda semasa pilihan ini aktif.',
			'comics.thumbnails' => 'Lakaran kecil halaman',
			'comics.controlsHelp' => 'Leret untuk menyelak halaman. Ketik dua kali untuk menukar padanan. Dalam tatal berterusan, leret menegak atau gunakan Page Up dan Page Down.',
			'comics.savedForComic' => 'Tetapan paparan diingati untuk komik ini dalam profil ini.',
			'comics.readLists' => 'Senarai bacaan',
			'comics.collections' => 'Koleksi',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
			'games.subtitle' => 'Your games, from your computers.',
			'games.computers' => 'Your computers',
			'games.nearby' => 'Nearby computers',
			'games.findComputers' => 'Find computers',
			'games.addComputer' => 'Add computer',
			'games.scanHint' => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.',
			'games.empty' => 'Add your gaming computer to get started.',
			'games.noNearby' => 'No computers found on this network. You can enter an address manually.',
			'games.name' => 'Computer name',
			'games.address' => 'IP address or hostname',
			'games.port' => 'Service port',
			'games.protocol' => 'Streaming service',
			'games.moonlight' => 'Sunshine / Moonlight',
			'games.steam' => 'Steam Remote Play',
			'games.save' => 'Save computer',
			'games.invalidAddress' => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.',
			'games.pair' => 'Connect computer',
			'games.pairTitle' => 'Approve this device',
			'games.pairInstructions' => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.',
			'games.pairHelp' => 'Connect this computer again to approve or renew pairing.',
			'games.openPairingPage' => 'Open Sunshine PIN page',
			'games.qrHelp' => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.',
			'games.refreshGames' => 'Refresh games',
			'games.play' => 'Play',
			'games.favorites' => 'Favorites',
			'games.allGames' => 'All games',
			'games.search' => 'Find a game',
			'games.noMatches' => 'No games match this search.',
			'games.favorite' => 'Save favorite',
			'games.unfavorite' => 'Remove favorite',
			'games.forget' => 'Forget computer',
			'games.forgetDescription' => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.',
			'games.unavailable' => 'The connection could not complete. Check that the computer is awake and paired, then try again.',
			'games.timeout' => 'Connection timed out. Check the computer, pairing code and network before trying again.',
			'games.libraryHint' => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.',
			'games.touchControls' => 'On-screen controller',
			_ => null,
		} ?? switch (path) {
			'games.touchDescription' => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.',
			'games.touchSetup' => 'On-screen controls',
			'games.touchSetupHint' => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.',
			'games.addGame' => 'Add game shortcut',
			'games.gameName' => 'Game name',
			'games.gameId' => 'Host application ID',
			'games.invalidGame' => 'Enter a game name and a positive numeric host application ID.',
			'games.wake' => 'Wake computer',
			'games.wakeSent' => 'Wake request sent. The computer must support Wake-on-LAN on this network.',
			'games.mac' => 'MAC address (optional)',
			'games.help' => 'Games help',
			'games.helpBody' => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.',
			'games.cancel' => 'Cancel',
			'games.scanning' => 'Looking for computers…',
			'games.saveShortcut' => 'Save shortcut',
			'games.manualHint' => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.',
			'games.engineUnavailable' => 'In-app streaming is not available here yet',
			'games.nativeEnginePending' => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.',
			'games.steamEnginePending' => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.',
			'games.steamLibrary' => 'Steam library',
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'deepLinks.invalid' => 'Link Plezy ini tidak sah.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Tiada profil yang sepadan dengan "${profile}".',
			'deepLinks.serverUnavailable' => 'Saya tidak boleh mencapai pelayan untuk pautan ini.',
			'deepLinks.notFound' => 'Saya tidak boleh menemui tajuk ini di perpustakaan anda.',
			'deepLinks.unsupportedItem' => 'Link ini tidak boleh dimainkan.',
			'deepLinks.noLiveTv' => 'Tiada pelayan TV langsung boleh didapati untuk pautan ini.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Saya tidak boleh menemui saluran "${channel}".',
			'deepLinks.showLink' => 'Tunjukkan link',
			'deepLinks.showProfileLink' => 'Tunjukkan profil link',
			'deepLinks.dialogTitle' => 'Link yang',
			'deepLinks.showHint' => 'Membuka pautan ini memainkan episod seterusnya.Tambah &mode=shuffle untuk bermain persembahan pada shuffle.',
			'deepLinks.movieHint' => 'Membuka pautan ini memainkan filem.',
			'deepLinks.episodeHint' => 'Membuka pautan ini memainkan episod ini.',
			'deepLinks.profileHint' => 'Membuka pautan ini beralih kepada profil ini.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Buka sebagai ${name}',
			'deepLinks.copy' => 'Salinan',
			'deepLinks.copied' => 'Link yang disalin',
			'householdSetup.title' => 'Persediaan rumah tangga',
			'issueReport.title' => 'Laporkan masalah',
			'issueReport.instructions' => 'Imbas kod QR untuk membuka draf GitHub yang telah diisi. Semak dan hantar apabila anda bersedia.',
			'issueReport.privacy' => 'Draf mengandungi versi aplikasi, platform dan bilangan sambungan. Alamat pelayan, nama akaun dan profil, tajuk media serta laluan fail tidak disertakan.',
			'issueReport.logPrivacy' => 'Log adalah pilihan. Semak sebelum memuat naik. ID log ditambahkan pada draf yang mungkin terbuka kepada umum.',
			'issueReport.openDraft' => 'Buka draf GitHub',
			_ => null,
		};
	}
}
