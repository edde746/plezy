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
class TranslationsId extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsId({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.id,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <id>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsId _root = this; // ignore: unused_field

	@override 
	TranslationsId $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsId(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$id app = _Translations$app$id._(_root);
	@override late final _Translations$cast$id cast = _Translations$cast$id._(_root);
	@override late final _Translations$automation$id automation = _Translations$automation$id._(_root);
	@override late final _Translations$notifications$id notifications = _Translations$notifications$id._(_root);
	@override late final _Translations$appIcon$id appIcon = _Translations$appIcon$id._(_root);
	@override late final _Translations$auth$id auth = _Translations$auth$id._(_root);
	@override late final _Translations$common$id common = _Translations$common$id._(_root);
	@override late final _Translations$screens$id screens = _Translations$screens$id._(_root);
	@override late final _Translations$update$id update = _Translations$update$id._(_root);
	@override late final _Translations$appAccess$id appAccess = _Translations$appAccess$id._(_root);
	@override late final _Translations$settings$id settings = _Translations$settings$id._(_root);
	@override late final _Translations$themeEditor$id themeEditor = _Translations$themeEditor$id._(_root);
	@override late final _Translations$search$id search = _Translations$search$id._(_root);
	@override late final _Translations$hotkeys$id hotkeys = _Translations$hotkeys$id._(_root);
	@override late final _Translations$fileInfo$id fileInfo = _Translations$fileInfo$id._(_root);
	@override late final _Translations$mediaMenu$id mediaMenu = _Translations$mediaMenu$id._(_root);
	@override late final _Translations$rateSheet$id rateSheet = _Translations$rateSheet$id._(_root);
	@override late final _Translations$accessibility$id accessibility = _Translations$accessibility$id._(_root);
	@override late final _Translations$tooltips$id tooltips = _Translations$tooltips$id._(_root);
	@override late final _Translations$audioTracks$id audioTracks = _Translations$audioTracks$id._(_root);
	@override late final _Translations$videoControls$id videoControls = _Translations$videoControls$id._(_root);
	@override late final _Translations$messages$id messages = _Translations$messages$id._(_root);
	@override late final _Translations$subtitlingStyling$id subtitlingStyling = _Translations$subtitlingStyling$id._(_root);
	@override late final _Translations$mpvConfig$id mpvConfig = _Translations$mpvConfig$id._(_root);
	@override late final _Translations$dialog$id dialog = _Translations$dialog$id._(_root);
	@override late final _Translations$profiles$id profiles = _Translations$profiles$id._(_root);
	@override late final _Translations$connections$id connections = _Translations$connections$id._(_root);
	@override late final _Translations$accountPreferences$id accountPreferences = _Translations$accountPreferences$id._(_root);
	@override late final _Translations$discover$id discover = _Translations$discover$id._(_root);
	@override late final _Translations$errors$id errors = _Translations$errors$id._(_root);
	@override late final _Translations$libraries$id libraries = _Translations$libraries$id._(_root);
	@override late final _Translations$about$id about = _Translations$about$id._(_root);
	@override late final _Translations$serverSelection$id serverSelection = _Translations$serverSelection$id._(_root);
	@override late final _Translations$hubDetail$id hubDetail = _Translations$hubDetail$id._(_root);
	@override late final _Translations$logs$id logs = _Translations$logs$id._(_root);
	@override late final _Translations$detail$id detail = _Translations$detail$id._(_root);
	@override late final _Translations$startup$id startup = _Translations$startup$id._(_root);
	@override late final _Translations$licenses$id licenses = _Translations$licenses$id._(_root);
	@override late final _Translations$navigation$id navigation = _Translations$navigation$id._(_root);
	@override late final _Translations$explore$id explore = _Translations$explore$id._(_root);
	@override late final _Translations$liveTv$id liveTv = _Translations$liveTv$id._(_root);
	@override late final _Translations$collections$id collections = _Translations$collections$id._(_root);
	@override late final _Translations$playlists$id playlists = _Translations$playlists$id._(_root);
	@override late final _Translations$music$id music = _Translations$music$id._(_root);
	@override late final _Translations$watchTogether$id watchTogether = _Translations$watchTogether$id._(_root);
	@override late final _Translations$downloads$id downloads = _Translations$downloads$id._(_root);
	@override late final _Translations$shaders$id shaders = _Translations$shaders$id._(_root);
	@override late final _Translations$companionRemote$id companionRemote = _Translations$companionRemote$id._(_root);
	@override late final _Translations$videoSettings$id videoSettings = _Translations$videoSettings$id._(_root);
	@override late final _Translations$performanceOverlay$id performanceOverlay = _Translations$performanceOverlay$id._(_root);
	@override late final _Translations$externalPlayer$id externalPlayer = _Translations$externalPlayer$id._(_root);
	@override late final _Translations$metadataEdit$id metadataEdit = _Translations$metadataEdit$id._(_root);
	@override late final _Translations$matchScreen$id matchScreen = _Translations$matchScreen$id._(_root);
	@override late final _Translations$serverTasks$id serverTasks = _Translations$serverTasks$id._(_root);
	@override late final _Translations$trakt$id trakt = _Translations$trakt$id._(_root);
	@override late final _Translations$seerr$id seerr = _Translations$seerr$id._(_root);
	@override late final _Translations$services$id services = _Translations$services$id._(_root);
	@override late final _Translations$addServer$id addServer = _Translations$addServer$id._(_root);
	@override late final _Translations$watchLink$id watchLink = _Translations$watchLink$id._(_root);
	@override late final _Translations$homeLayout$id homeLayout = _Translations$homeLayout$id._(_root);
	@override late final _Translations$platform$id platform = _Translations$platform$id._(_root);
	@override late final _Translations$universalMedia$id universalMedia = _Translations$universalMedia$id._(_root);
	@override late final _Translations$fileSources$id fileSources = _Translations$fileSources$id._(_root);
	@override late final _Translations$lending$id lending = _Translations$lending$id._(_root);
	@override late final _Translations$audiobook$id audiobook = _Translations$audiobook$id._(_root);
	@override late final _Translations$sourceSetup$id sourceSetup = _Translations$sourceSetup$id._(_root);
	@override late final _Translations$comics$id comics = _Translations$comics$id._(_root);
	@override late final _Translations$games$id games = _Translations$games$id._(_root);
}

// Path: app
class _Translations$app$id extends Translations$app$en {
	_Translations$app$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$id extends Translations$cast$en {
	_Translations$cast$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Transmisikan ke perangkat';
	@override String get searching => 'Mencari alat-alat yang terbuat dari ...';
	@override String connectedTo({required Object device}) => 'Menghubungkan ke ${device}';
	@override String get device => 'Perangkat transmisi';
	@override String get readyToCast => 'Siap mentransmisikan';
	@override String get subtitle => 'Subtitel';
	@override String get serverNotAvailable => 'Media server tidak tersedia.';
	@override String get stopCasting => 'Hentikan transmisi';
	@override String get castToDevice => 'Transmisikan ke perangkat';
	@override String get noEpisodeAvailable => 'Tidak ada episode yang tersedia untuk ditayangkan.';
	@override String get startFailed => 'Tidak bisa memulai casting. periksa server dan coba lagi.';
}

// Path: automation
class _Translations$automation$id extends Translations$automation$en {
	_Translations$automation$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Tidak ada sesi video aktif untuk dikendalikan.';
	@override String get profileNotFound => 'Yang Plezy profil tidak dapat ditemukan.';
}

// Path: notifications
class _Translations$notifications$id extends Translations$notifications$en {
	_Translations$notifications$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'episode baru';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$id extends Translations$appIcon$en {
	_Translations$appIcon$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Aplikasi Ikon';
	@override String get defaultIcon => 'Bawaan';
	@override String get current => 'Ikon saat ini';
	@override String get locked => 'Akses seumur hidup yang diperlukan';
	@override String get lockedHint => 'Mulai percobaan 7 hari Anda atau membuka kunci PlezyNG selama hidup Anda untuk menggunakan ikon alternatif.';
	@override String get changeFailed => 'Tidak bisa mengubah ikon aplikasi';
	@override String get launcherHint => 'Ikon baru muncul di layar rumah Anda setelah Anda meninggalkan PlezyNG.';
	@override String get tvLauncherHint => 'Banner baru muncul setelah Anda meninggalkan PlezyNG. Android TV dapat terus menampilkan yang lama sampai TV kembali.';
	@override late final _Translations$appIcon$names$id names = _Translations$appIcon$names$id._(_root);
	@override String get description => 'Pilih ikon yang ditunjukkan oleh peluncuran perangkat Anda. previews menunjukkan bagaimana setiap opsi terlihat.';
}

// Path: auth
class _Translations$auth$id extends Translations$auth$en {
	_Translations$auth$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Mendaftar dengan Plex';
	@override String get showQRCode => 'Menampilkan QR Code';
	@override String get authenticate => 'autentik';
	@override String get authenticationTimeout => 'Pengesahan sudah selesai, silakan coba lagi.';
	@override String get scanQRToSignIn => 'Scan kode QR ini untuk mendaftar';
	@override String get waitingForAuth => 'Menunggu untuk autentikasi ... Mendaftar dari browser Anda.';
	@override String get useBrowser => 'Menggunakan browser';
	@override String get or => 'atau';
	@override String connectToMediaBrowser({required Object product}) => 'Menghubungkan ke ${product}';
	@override String get quickConnect => 'Koneksi Cepat';
	@override String get useQuickConnect => 'Gunakan Koneksi Cepat';
	@override String get quickConnectInstructions => 'Buka Quick Connect di Jellyfin dan masukkan kode ini.';
	@override String get quickConnectWaiting => 'Menunggu kelulusan...';
	@override String get quickConnectCancel => 'Batal';
	@override String get quickConnectExpired => 'Koneksi Cepat kedaluwarsa. Coba lagi.';
	@override String get localDataRecoveryRequired => 'PlezyNG tidak dapat memulihkan data masuk lokal dan data pemutaran yang tertunda dengan aman. Silakan masuk lagi.';
	@override String get pinCheckRejected => 'Pengesahan PIN Plex ditolak';
	@override String get connectToDirectPlex => 'Menghubungkan ke server lokal Plex';
}

// Path: common
class _Translations$common$id extends Translations$common$en {
	_Translations$common$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Batal';
	@override String get save => 'Simpan';
	@override String get close => 'Tutup';
	@override String get closeMiniPlayer => 'Berdekatan dengan Mini Player';
	@override String get closeWorkspaceWindow => 'Jendela yang dekat';
	@override String get returnToFullView => 'Kembali ke Full View';
	@override String get manageMediaSessions => 'Mengelola sesi media';
	@override String get hideMediaSessions => 'Menyembunyikan sesi media';
	@override String get mediaSessions => 'Sesi Media';
	@override String get mediaSessionsHint => 'Pilih untuk membawa sesi ke depan.Park menyembunyikan jendela tetapi tetap terbuka.Kembali membuka dalam pandangan penuh; dekat menutupnya.';
	@override String get sessionInWorkspace => 'Dalam ruang kerja';
	@override String get sessionParked => 'parkir';
	@override String get sessionFullscreen => 'layar penuh';
	@override String get switchToNextWindow => 'Swap dengan jendela berikutnya';
	@override String get moveWindow => 'Menggerakkan jendela';
	@override String get finishMovingWindow => 'Menutup jendela bergerak';
	@override String get moveWindowHint => 'Tekan panjang dan tarik jendela untuk memindahkannya. kontrol ini juga memungkinkan pergerakan kunci arrow.';
	@override String get movingWindowHelp => 'Menarik untuk bergerak · Menarik kunci disesuaikan · Enter saves · Escape cancles';
	@override String get resizeWindow => 'Menarik jendela';
	@override String get resizeWindowHint => 'Tarik handuk ini atau gunakan kunci anak panah untuk memutar ulang jendela.';
	@override String get workspaceWindowHint => 'Gunakan kontrol pergerakan atau tekanan panjang dan tarik untuk bergerak. gunakan handuk resize untuk resize.';
	@override String get workspacePaneHint => 'Pilih panel ini untuk fokus. gunakan kontrol layar penuh untuk memperluasnya.';
	@override String workspaceWindowLabel({required Object title}) => 'Jendela sesi: ${title}';
	@override String get workspaceTitleHint => 'Pilih untuk fokus. tarik bar judul untuk bergerak; gunakan tombol layar penuh untuk memperluas.';
	@override String get moveToSessionTray => 'Bergerak ke sesi tray';
	@override String get moveToSessionTrayHint => 'Kees sesi ini tersedia tanpa menampilkan jendela.';
	@override String get closeSessionHint => 'Menutup jendela ini dan mengakhiri sesi.';
	@override String get sideBySideLayout => 'Beralih ke sisi-by-side layout';
	@override String get floatingWindows => 'Switch untuk mengalir jendela';
	@override String get clear => 'jelas';
	@override String get reset => 'Atur Ulang';
	@override String get later => 'Kemudian';
	@override String get submit => 'Kirim';
	@override String get confirm => 'mengkonfirmasi';
	@override String get retry => 'Coba Lagi';
	@override String get logout => 'Log keluar';
	@override String get unknown => 'Tidak Dikenal';
	@override String get refresh => 'Segarkan';
	@override String get yes => 'Ya';
	@override String get no => 'Tidak';
	@override String get delete => 'Hapus';
	@override String get edit => 'Sunting';
	@override String get shuffle => 'Acak';
	@override String get addTo => 'Tambah ke...';
	@override String get createNew => 'Membuat yang baru';
	@override String get connect => 'Sambung';
	@override String get disconnect => 'Memutuskan';
	@override String get play => 'Putar';
	@override String get pause => 'Jeda';
	@override String get resume => 'Lanjutkan';
	@override String get error => 'Kesalahan';
	@override String get search => 'Cari';
	@override String get home => 'rumah';
	@override String get back => 'Kembali';
	@override String get settings => 'Pengaturan';
	@override String get mute => 'Bisukan';
	@override String get ok => 'OK';
	@override String get off => 'Nonaktif';
	@override String get options => 'Pilihan';
	@override String seasonNumber({required Object number}) => 'Musim ini ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episode ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Bab ${number}';
	@override String get reconnect => 'Menghubungkan kembali';
	@override String get viewAll => 'Lihat semua';
	@override String get checkingNetwork => 'Jaringan pemeriksaan...';
	@override String get loadingServers => 'Layanan Layanan Layanan...';
	@override String get connectingToServers => 'Menghubungkan ke server';
	@override String get startingOfflineMode => 'Mulai dari mode offline.';
	@override String get loading => 'Mengisi...';
	@override String get fullscreen => 'Layar penuh';
	@override String get exitFullscreen => 'Penampilan Full Screen';
	@override String get pressBackAgainToExit => 'Tekan kembali untuk keluar';
	@override late final _Translations$common$ratingSource$id ratingSource = _Translations$common$ratingSource$id._(_root);
	@override String get notAvailable => 'N / A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$id mediaKind = _Translations$common$mediaKind$id._(_root);
}

// Path: screens
class _Translations$screens$id extends Translations$screens$en {
	_Translations$screens$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lisensi';
	@override String get switchProfile => 'Profil Switch';
	@override String get subtitleStyling => 'Subtitle gaya';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Log';
}

// Path: update
class _Translations$update$id extends Translations$update$en {
	_Translations$update$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update yang tersedia';
	@override String versionAvailable({required Object version}) => 'Versi ${version} tersedia';
	@override String currentVersion({required Object version}) => 'Saat ini: ${version}';
	@override String get skipVersion => 'Hapus versi ini';
	@override String get viewRelease => 'Lihat Release';
	@override String get latestVersion => 'Anda berada di versi terbaru';
	@override String get checkFailed => 'gagal memeriksa update';
}

// Path: appAccess
class _Translations$appAccess$id extends Translations$appAccess$en {
	_Translations$appAccess$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cobalah setiap fitur gratis selama 7 hari';
	@override String get description => 'Memulai percobaan tujuh hari dengan akses penuh ke setiap fitur PlezyNG. tidak ada biaya selama percobaan dan tidak ada langganan. setelah percobaan, satu pembelian seumur hidup pada harga toko Anda membuka PlezyNG seumur hidup.';
	@override String get trialEndedDescription => 'Unlock setiap fitur di PlezyNG untuk hidup dengan satu pembelian pada harga toko Anda.';
	@override String get startTrial => 'Mulai ujian gratis 7 hari saya';
	@override String get trialActive => '7 hari ujian full-feature Anda aktif.';
	@override String get trialEnded => 'Pengadilan 7 hari telah berakhir';
	@override String get trialStartFailed => 'Saya tidak bisa menyimpan percobaan pada perangkat ini. silakan coba lagi.';
	@override String get lifetimeTitle => 'PlezyNG dibebaskan untuk hidup';
	@override String get lifetimeBody => 'Terima kasih! Anda memiliki akses seumur hidup ke setiap fitur PlezyNG.';
	@override String get manageTitle => 'PlezyNG akses seumur hidup';
	@override String get manageDescription => 'Cobalah setiap fitur gratis selama 7 hari, kemudian membuka semua untuk hidup dengan satu pembayaran pada harga toko Anda.';
	@override String buy({required Object price}) => 'Menghapus setiap fitur untuk ${price}';
	@override String get loadingPrice => 'Harga toko yang terjangkau...';
	@override String get retryPrice => 'Harga Retry Lookup';
	@override String get restore => 'Restorasi pembelian seumur hidup';
	@override String get pending => 'Pembelian Anda sedang menunggu pembayaran atau kelulusan. akses seumur hidup dibuka sebaik saja toko menyelesaikannya.';
	@override String get storeUnavailable => 'Pastikan bahwa Anda terdaftar di toko dan pembelian diizinkan pada perangkat ini.';
	@override String get productNotFound => 'Pembukaan PlezyNG seumur hidup belum tersedia di toko ini.';
	@override String get productQueryFailed => 'Tidak bisa menagih harga toko. periksa koneksi Anda dan coba lagi.';
	@override String get purchaseFailed => 'Pembelian tidak berjalan. coba lagi.';
	@override String get restoreFailed => 'Tidak bisa sampai ke toko untuk memulihkan pembelian Anda. coba lagi.';
	@override String get nothingToRestore => 'Nombor PlezyNG pembelian seumur hidup ditemukan untuk akun toko ini.';
}

// Path: settings
class _Translations$settings$id extends Translations$settings$en {
	_Translations$settings$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pengaturan';
	@override String get supportDeveloper => 'Dukungan PlezyNG';
	@override String get supportDeveloperDescription => 'Memberi dukungan untuk pengembangan';
	@override String get lifetimeAccess => 'PlezyNG akses seumur hidup';
	@override String get language => 'Bahasa';
	@override String get theme => 'Tema';
	@override String get appearance => 'penampilan';
	@override String get detailPage => 'Detail halaman';
	@override String get themeSongsEnabled => 'Mainkan lagu tema';
	@override String get themeSongsEnabledDescription => 'Mainkan lagu tema yang tersedia sambil melihat detail media.';
	@override String get themeSongVolume => 'Tema Lagu Volume';
	@override String get videoPlayback => 'Video dari Playback';
	@override String get videoPlaybackDescription => 'Mengatur perilaku playback';
	@override String get advanced => 'Canggih';
	@override String get episodePosterMode => 'Gaya Poster';
	@override String get seriesPoster => 'Poster seri';
	@override String get seasonPoster => 'Poster Musim';
	@override String get episodeThumbnail => 'Gambar mini';
	@override String get showHeroSectionDescription => 'Tampilkan konten carousel pada layar rumah';
	@override String get secondsLabel => 'sekunder';
	@override String get minutesLabel => 'Minit';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'M';
	@override String durationHint({required Object min, required Object max}) => 'Masukkan nilai (${min}-${max})';
	@override String get systemTheme => 'Sistem';
	@override String get lightTheme => 'Cahaya';
	@override String get darkTheme => 'gelap';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Manusia';
	@override String get glacierTheme => 'Gletser';
	@override String get forestTheme => 'Hutan';
	@override String get plumTheme => 'Ungu prem';
	@override String get paperTheme => 'Kertas';
	@override String get libraryDensity => 'Ketebalan perpustakaan';
	@override String get displayScale => 'Skala Display';
	@override String get compact => 'Kompak';
	@override String get comfortable => 'nyaman';
	@override String get gridSpacing => 'Jaringan Spacing';
	@override String get gridSpacingTight => 'Rapat';
	@override String get gridSpacingNormal => 'Biasa';
	@override String get gridSpacingSpacious => 'ruang';
	@override String get tvCornerSpotlightBackdrop => 'Spesifikasi Spotlight Backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'Tunjukkan karya seni di sudut kanan atas bukannya mengisi layar';
	@override String get viewMode => 'Lihat mode';
	@override String get gridView => 'Jaringan';
	@override String get listView => 'Listing';
	@override String get showHeroSection => 'Menampilkan Hero Section';
	@override String get showHomeBackdrop => 'Menampilkan rumah backdrop artwork';
	@override String get showHomeBackdropDescription => 'Tunjukkan karya seni besar di balik rantai rumah yang ditampilkan';
	@override String get contentScreensaverEnabled => 'Menggunakan Screensaver';
	@override String get contentScreensaverEnabledDescription => 'Tunjukkan karya seni layar penuh setelah aplikasi menjadi idle';
	@override String get contentScreensaverDelay => 'Memulai screensaver setelah';
	@override String get contentScreensaverLibraries => 'Perpustakaan Screensaver';
	@override String get contentScreensaverLibrariesDescription => 'Pilih perpustakaan mana yang menyediakan karya seni screensaver.Jika tidak ada yang dipilih, karya seni dari semua perpustakaan digunakan.';
	@override String get contentScreensaverAllLibraries => 'Semua pustaka';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} perpustakaan terpilih';
	@override String get contentScreensaverNoLibraries => 'Tidak ada perpustakaan media yang terhubung.';
	@override String get contentScreensaverDismissHint => 'Tekan tombol atau ketik untuk membatalkan';
	@override String get newEpisodeNotifications => 'Pemberitahuan episode baru';
	@override String get newEpisodeNotificationsDescription => 'Peringatan ketika episode baru ditambahkan ke sebuah acara Anda terperangkap di. periksa saat Plezy terbuka.';
	@override String get continueWatchingRowSize => 'Lanjutkan perhatikan ukuran baris';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} kartu';
	@override String get rowSizeCompact => 'Kompak';
	@override String get rowSizeStandard => 'Standar';
	@override String get rowSizeLarge => 'Besar';
	@override String get continueWatchingAction => 'Lanjutkan pengawasan aksi';
	@override String get continueWatchingPlay => 'Putar';
	@override String get continueWatchingDetails => 'Detail Terbuka';
	@override String get episodeAction => 'Episode Aksi';
	@override String get episodePlay => 'Putar';
	@override String get episodeDetails => 'Detail Terbuka';
	@override String get useGlobalHubs => 'Menggunakan Home Layout';
	@override String get useGlobalHubsDescription => 'Tampilkan hub rumah bersatu. jika tidak, gunakan rekomendasi perpustakaan.';
	@override String get showServerNameOnHubs => 'Menampilkan nama server di Hubs';
	@override String get showServerNameOnHubsDescription => 'Selalu menunjukkan nama server dalam judul hub.';
	@override String get groupLibrariesByServer => 'Perpustakaan Perpustakaan Server';
	@override String get groupLibrariesByServerDescription => 'Perpustakaan sidebar kelompok di bawah setiap server media.';
	@override String get alwaysKeepSidebarOpen => 'Selalu Tetap Sidebar Terbuka';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidebar tetap diperluas dan area konten disesuaikan untuk memenuhi';
	@override String get showUnwatchedCount => 'Menampilkan Unwatched Count';
	@override String get showUnwatchedCountDescription => 'Menampilkan episode yang tidak ditonton di acara dan musim';
	@override String get showWatchedIndicators => 'Menampilkan indikator yang diperhatikan';
	@override String get showWatchedIndicatorsDescription => 'Menampilkan tanda kontrol pada film, acara, dan episode yang ditonton';
	@override String get showEpisodeNumberOnCards => 'Tunjukkan Episode Number pada Kartu';
	@override String get showEpisodeNumberOnCardsDescription => 'Tunjukkan musim dan nomor episode pada kartu episode';
	@override String get showSeasonPostersOnTabs => 'Menampilkan Poster Musim di Tabs';
	@override String get showSeasonPostersOnTabsDescription => 'Tunjukkan poster setiap musim di atas tabnya';
	@override String get tvFullCardLayout => 'Kartu televisi penuh';
	@override String get tvFullCardLayoutDescription => 'Gunakan kartu TV hanya dengan nama-nama aktris yang ditinggalkan';
	@override String get focusGlow => 'Fokus pada Glow';
	@override String get focusGlowDescription => 'Menggerakkan cahaya lembut di sekitar kartu fokus';
	@override String get visualEffects => 'Efek visual';
	@override String get visualEffectsAuto => 'mobil';
	@override String get visualEffectsAutoDescription => 'Mengurangi efek secara otomatis pada perangkat rendah daya';
	@override String get visualEffectsFull => 'penuh';
	@override String get visualEffectsReduced => 'dikurangi';
	@override String get visualEffectsReducedDescription => 'Kurang animasi dan karya seni resolusi rendah';
	@override String get hideSpoilers => 'Temukan Spoilers untuk Unwatched Episodes';
	@override String get hideSpoilersDescription => 'Blur miniatur dan deskripsi untuk episode yang tidak ditonton';
	@override String get playerBackend => 'Pembuat Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hardware Dekodasi';
	@override String get hardwareDecodingDescription => 'Menggunakan akselerasi perangkat keras saat tersedia';
	@override String get playbackBuffer => 'Pemain Buffer';
	@override String get playbackBufferAuto => 'Mobil yang disarankan (Rekomendasi)';
	@override String get playbackBufferLarge => 'Besar';
	@override String get playbackBufferExtraLarge => 'Ekstra besar';
	@override String get playbackBufferDescription => 'Buffer lebih banyak terhadap koneksi yang tidak stabil. juga terbatas oleh Buffer Size.';
	@override String get streamBufferSize => 'Ukuran Buffer';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Berapa banyak video yang harus dimuat ke depan saat bermain langsung. transcodes berhenti di buffer transcode server sendiri. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Menggantikan Playback Buffer saat ditempatkan, ditangkap di setengah batas memori aplikasi';
	@override String get streamBufferMegabytes => 'Megabita';
	@override String get defaultQualityTitle => 'kualitas default';
	@override String get cellularQualityTitle => 'Kualitas pada selular';
	@override String get remoteQualityTitle => 'Kualitas Streaming Jarak Jauh';
	@override String get remoteQualitySameAsDefault => 'Sama dengan kualitas default';
	@override String get cellularQualitySameAsDefault => 'Sama dengan kualitas default';
	@override String get directPlayCoveredQuality => 'Mainkan Video Kecil dengan Kualitas Asli';
	@override String get directPlayCoveredQualityDescription => 'Mainkan video secara langsung di bawah batas kualitas, bukannya menyulitkan mereka';
	@override String get videoCodecs => 'Video kode';
	@override String get videoCodecsDescription => 'Kodek yang tidak disemak disekodkan oleh server';
	@override String get videoCodecsAlwaysAccepted => 'Selalu diterima';
	@override String get musicQualityTitle => 'Kualitas Musik';
	@override String get subtitleStyling => 'Subtitle gaya';
	@override String get subtitleStylingDescription => 'Menampilkan Subtitle';
	@override String get smallSkipDuration => 'Kecil Skik Durasi';
	@override String get largeSkipDuration => 'Jangka Panjang Skip';
	@override String get rewindOnResume => 'Kembali ke Resume';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} detik',
	);
	@override String get defaultSleepTimer => 'Tidur Tidur Default';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} menit',
	);
	@override String get rememberTrackSelections => 'Ingat seleksi track per show/movie';
	@override String get chooseTracksBeforePlayback => 'Pilih audio dan subtitle sebelum playback';
	@override String get chooseTracksBeforePlaybackDescription => 'Pilih sumber audio dan subtitle track sebelum setiap video dimulai.';
	@override String get alwaysShowSubtitlesOnDevice => 'Selalu tunjukkan subtitle pada perangkat ini';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Jika server tidak memiliki subtitle yang dipilih, pilih track secara lokal. ini tidak pernah mengubah preferensi server.';
	@override String get autoDownloadPreferredSubtitle => 'FATCH Lost Favorit-bahasa subtitle';
	@override String get autoDownloadPreferredSubtitleDescription => 'Pilih subtitle yang tersedia dalam bahasa favorit Anda secara lokal.Jika tidak ada, minta server untuk menangkap satu ketika didukung.';
	@override String get rememberTrackSelectionsDescription => 'Simpan audio dan pilihan subtitle dengan show atau film pada perangkat ini';
	@override String get rememberTrackSelectionsBackendRule => 'Bekerja secara lokal dengan Plex, Jellyfin, dan Emby; Plex dan Jellyfin juga dapat menyimpan seleksi pada server';
	@override String get followServerTrackSelections => 'Gunakan seleksi trek per episode server';
	@override String get followServerTrackSelectionsDescription => 'Pada perubahan episode, gunakan audio dan subtitle yang dipilih pada server bukannya membawa di atas pilihan saat ini.';
	@override String get resumeMusicOnLaunch => 'Ingat sesi musik';
	@override String get resumeMusicOnLaunchDescription => 'Buka kembali lagu terakhir berhenti di mana ia meninggalkan ketika aplikasi dimulai';
	@override String get showChapterMarkersOnTimeline => 'Tampilkan catatan bab pada mencari bar';
	@override String get showChapterMarkersOnTimelineDescription => 'Segmen yang mencari bar di bab batas';
	@override String get specialsOrdering => 'Spesialisasi dalam episode order';
	@override String get specialsOrderingDescription => 'Di mana spesial bermain dalam urutan jam acara';
	@override String get specialsOrderingServer => 'Perintah server';
	@override String get specialsOrderingAirDate => 'Interleave dengan tanggal udara';
	@override String get specialsOrderingLast => 'Setelah musim biasa';
	@override String get clickVideoTogglesPlayback => 'Klik pada video untuk bermain / istirahat';
	@override String get clickVideoTogglesPlaybackDescription => 'Klik video untuk memainkan/berhenti daripada menampilkan kontrol.';
	@override String get videoPlayerControls => 'Video Player Pengendalian';
	@override String get keyboardShortcuts => 'Keyboard pendek';
	@override String get keyboardShortcutsDescription => 'Cara menyesuaikan keyboard shortcuts';
	@override String get videoPlayerNavigation => 'Navigasi Video Player';
	@override String get videoPlayerNavigationDescription => 'Gunakan kunci pistol untuk menavigasi kontrol pemutar video';
	@override String get watchTogetherRelay => 'Lihat bersama Reli';
	@override String get watchTogetherRelayDescription => 'Public Open Watch Party meluncurkan kecuali Anda menetapkan sendiri';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Masukkan URL dasar relai HTTP atau HTTPS yang valid.';
	@override String get crashReporting => 'Laporan kecelakaan';
	@override String get crashReportingDescription => 'Mengirim laporan kecelakaan untuk membantu memperbaiki aplikasi';
	@override String get debugLogging => 'Pencatatan debug';
	@override String get debugLoggingDescription => 'Memungkinkan loging terperinci untuk penyelesaian masalah';
	@override String get viewLogs => 'Lihat log';
	@override String get viewLogsDescription => 'Lihat Aplikasi Logs';
	@override String get clearImageCache => 'Cache gambar yang jelas';
	@override String get clearImageCacheDescription => 'Gambar dapat dimuat lebih lambat sampai dimuat kembali.';
	@override String get clearImageCacheSuccess => 'Image cache diselesaikan dengan sukses';
	@override String get resetSettings => 'Restorasi Settings';
	@override String get resetSettingsDescription => 'Mengembalikan pengaturan default. ini tidak dapat dibatasi.';
	@override String get resetSettingsSuccess => 'Setting Reset dengan sukses';
	@override String get backup => 'Cadangan';
	@override String get exportSettings => 'Pengaturan Eksport';
	@override String get exportSettingsDescription => 'Simpan preferensi Anda ke file';
	@override String get exportSettingsSuccess => 'Pengaturan Ekspor';
	@override String get importSettings => 'Pengaturan Import';
	@override String get importSettingsDescription => 'Memulihkan preferensi dari file';
	@override String get importSettingsConfirm => 'Ini akan menggantikan pengaturan Anda saat ini. lanjutkan?';
	@override String get importSettingsSuccess => 'Pengaturan yang diimpor';
	@override String get importSettingsInvalidFile => 'Fail ini tidak valid PlezyNG pengeksportan pengaturan';
	@override String get importSettingsNoUser => 'Mendaftar sebelum mengimport pengaturan';
	@override String get cloudBackup => 'Cloud Backup untuk';
	@override String get cloudBackupDescription => 'Cadangkan pengaturan yang dapat dipindahkan ke alamat WebDAV melalui HTTPS. Koneksi server dan informasi masuk tetap disimpan di perangkat ini.';
	@override String get cloudBackupUrl => 'URL berkas JSON WebDAV';
	@override String get cloudBackupUsername => 'Nama Pengguna';
	@override String get cloudBackupPassword => 'Kata sandi';
	@override String get cloudBackupSaved => 'Cloud Backup Destinasi disimpan';
	@override String get cloudBackupNow => 'Kembali ke sekarang';
	@override String get cloudBackupComplete => 'Settings backup upload';
	@override String get cloudBackupRestore => 'Restorasi Backup';
	@override String get cloudBackupRestoreConfirm => 'Ini akan menggantikan pengaturan portabel yang sepadan pada perangkat ini.';
	@override String get cloudBackupRestored => 'Pengaturan yang dikembalikan dari cloud backup';
	@override String get shortcutsReset => 'Kembali ke default';
	@override String get resetShortcutsConfirm => 'Ini akan menggantikan singkatan yang disesuaikan dengan default.';
	@override String get about => 'Tentang';
	@override String get aboutDescription => 'Informasi Aplikasi dan Lisensi';
	@override String get updates => 'Update yang';
	@override String get updateAvailable => 'Update yang tersedia';
	@override String get checkForUpdates => 'Periksa Update';
	@override String get autoCheckUpdatesOnStartup => 'Periksa secara otomatis untuk update pada startup';
	@override String get autoCheckUpdatesOnStartupDescription => 'Pemberitahuan saat update tersedia pada peluncuran';
	@override String get validationErrorEnterNumber => 'Silakan masukkan nomor yang valid';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'harus antara ${min} dan ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Kursi yang sudah ditugaskan ke ${action}';
	@override String shortcutUpdated({required Object action}) => 'Keterlambatan dikemas kini untuk ${action}';
	@override String get saveFailed => 'Anda tidak bisa menyimpan perubahan. coba lagi.';
	@override String get autoPlayAndSkip => 'Perbedaan Auto-Play & Skip';
	@override String get autoPlayNextEpisode => 'Auto-Play Episode selanjutnya';
	@override String get autoPlayNextEpisodeDescription => 'Memulai episode berikutnya secara otomatis ketika satu berakhir';
	@override String get shuffleStartsFromBeginning => 'Shuffle dimulai dari awal';
	@override String get shuffleStartsFromBeginningDescription => 'Memulai setiap episode pada awal ketika mengetuk bukannya mengulang';
	@override String get plexCinemaPreRoll => 'Menggunakan server cinema intros';
	@override String get plexCinemaPreRollDescription => 'Mainkan pre-roll Plex atau Jellyfin dan Emby intros yang dikonfigurasi sebelum film dimulai.';
	@override String get playNextCountdown => 'Mainkan Next Countdown';
	@override String get playNextCountdownImmediate => 'Bermain dengan segera';
	@override String get skipIntroMode => 'Pergi ke Into';
	@override String get skipIntroModeOffDescription => 'Mainkan intros secara normal tanpa tombol skip';
	@override String get skipIntroModeButtonDescription => 'Tunjukkan tombol skip ketika intro dimulai';
	@override String get skipIntroModeAutoDescription => 'Meluncur masuk secara otomatis setelah keterlambatan di bawah';
	@override String get skipCreditsMode => 'Skripsi Kredit';
	@override String get skipCreditsModeOffDescription => 'Bermain kredit secara normal tanpa tombol skip';
	@override String get skipCreditsModeButtonDescription => 'Tunjukkan tombol skip saat kredit dimulai';
	@override String get skipCreditsModeAutoDescription => 'Luncurkan kredit secara otomatis dan memainkan episode berikutnya';
	@override String get skipAdsMode => 'Pemberitahuan Skip';
	@override String get skipAdsModeOffDescription => 'Mainkan iklan yang terdeteksi secara normal tanpa tombol skip';
	@override String get skipAdsModeButtonDescription => 'Menampilkan tombol skip ketika Plex mengidentifikasi iklan';
	@override String get skipAdsModeAutoDescription => 'Mengalihkan iklan yang ditemukan secara otomatis setelah keterlambatan di bawah';
	@override String get musicPlayback => 'Musik Playback';
	@override String get musicSweetFades => 'Susu yang manis';
	@override String get musicSweetFadesDescription => 'Fade musik pada ujung track ketika Plex memiliki data suara. album playback tetap tidak berubah.';
	@override String get skipMarkerModeOff => 'Nonaktif';
	@override String get skipMarkerModeButton => 'Tampilkan tombol';
	@override String get skipMarkerModeAuto => 'otomatis';
	@override String get forceSkipMarkerFallback => 'Kekuatan Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'Gunakan pola judul bab bahkan ketika Plex memiliki markers';
	@override String get theIntroDbFallback => 'Menggunakan TheIntroDB sebagai intro fallback';
	@override String get theIntroDbFallbackDescription => 'Gunakan waktu komunitas hanya ketika server tidak memiliki intro markers. pertandingan dapat bervariasi dengan release.';
	@override String get autoSkipDelay => 'Tanggapan mobil';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Tunggu ${seconds} detik sebelum melompat sendiri';
	@override String get introPattern => 'Intro Marker Potensi';
	@override String get introPatternDescription => 'Regex pattern untuk memenuhi intro markers dalam judul bab';
	@override String get creditsPattern => 'Potensi Kredit Marker';
	@override String get creditsPatternDescription => 'Regex pattern untuk memenuhi kredit markers dalam judul bab';
	@override String get prerolls => 'Preliminasi';
	@override String get playPrerollsBeforeMovies => 'Bermain Prerolls Sebelum Film';
	@override String get playPrerollsBeforeMoviesDescription => 'Mainkan klip rawak dari seleksi Anda di bawah sebelum setiap film. tekan kembali untuk melompat.';
	@override String get prerollLibrary => 'Perpustakaan Preroll';
	@override String get prerollLibraryNotSet => 'Tidak menetapkan';
	@override String get prerollLibraryNoneFound => 'Tidak ada perpustakaan yang ditemukan di server Anda.';
	@override String get prerollSelection => 'Pemilu Preliminasi';
	@override String get prerollSelectionPickLibraryFirst => 'Pilih perpustakaan terlebih dahulu';
	@override String get prerollSelectionNoneSelected => 'Tidak ada preroll yang dipilih';
	@override String prerollSelectionCount({required Object count}) => '${count} dipilih';
	@override String get prerollItemPicker => 'Pilih Preliminasi';
	@override String get prerollItemPickerLoadFailed => 'Saya tidak bisa mengisi barang-barang dari perpustakaan ini.';
	@override String get invalidRegex => 'Ketidakmampuan ekspresi biasa';
	@override String get regex => 'Ekspresi yang teratur';
	@override String get downloads => 'Unduhan';
	@override String get downloadLocationDescription => 'Pilih tempat untuk menyimpan konten yang dimuat turun';
	@override String get downloadLocationDefault => 'Aplikasi Penyimpanan (App Storage)';
	@override String get downloadLocationCustom => 'Lokasi Custom';
	@override String get selectFolder => 'Pilih Folder';
	@override String get resetToDefault => 'Kembali ke default';
	@override String currentPath({required Object path}) => 'Saat ini: ${path}';
	@override String get downloadLocationChanged => 'Download Lokasi yang diubah';
	@override String get downloadLocationReset => 'Download lokasi reset ke default';
	@override String get downloadLocationInvalid => 'folder yang dipilih tidak dapat ditulis';
	@override String get downloadLocationPickerUnavailable => 'Seleksi folder tidak tersedia pada perangkat ini';
	@override String get downloadOnWifiOnly => 'Download di Wi-Fi hanya';
	@override String get downloadOnWifiOnlyDescription => 'Menghindari download ketika pada data seluler';
	@override String get autoRemoveWatchedDownloads => 'Auto-remove download yang ditonton';
	@override String get autoRemoveWatchedDownloadsDescription => 'Menghapus download secara otomatis';
	@override String get autoDownloadContinueWatching => 'Auto-Download Teruskan Menonton';
	@override String get autoDownloadContinueWatchingDescription => 'Simpan item di rak Anda terus menonton yang dimuat turun, dan menghapusnya setelah mereka meninggalkan rak';
	@override String get downloadQuality => 'Download kualitas';
	@override String get downloadQualityDescription => 'Plex mempersiapkan salinan terkonversi dalam kue muat turunnya. Jellyfin dan Emby transcode saat file muat turun; transfer terputus mungkin perlu dimulai kembali.';
	@override String get askDownloadQualityEachTime => 'Pilih kualitas untuk setiap download';
	@override String get askDownloadQualityEachTimeDescription => 'Tunjukkan kualitas picker sebelum menguji setiap video download';
	@override String get cellularDownloadBlocked => 'Download diblokir pada seluler. gunakan Wi-Fi atau ubah pengaturan.';
	@override String get maxVolume => 'Volume maksimum';
	@override String get maxVolumeDescription => 'Izinkan peningkatan volume di atas 100% untuk media bersuara pelan';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Kekurangan Kekayaan';
	@override String get discordRichPresenceDescription => 'Tunjukkan apa yang Anda lihat di Discord';
	@override String get services => 'Layanan';
	@override String get servicesDescription => 'Hubungi Trakt, MyAnimeList, Seerr, dan banyak lagi';
	@override String get manageLibrariesDescription => 'Membuka dan menyembunyikan perpustakaan';
	@override String get companionRemoteServer => 'Layanan Remote Server';
	@override String get companionRemoteServerDescription => 'Memungkinkan perangkat mobile di jaringan Anda untuk mengontrol aplikasi ini';
	@override String get companionRemoteServerStartFailed => 'Tidak bisa memulai server';
	@override String get companionRemoteServerStopFailed => 'Tidak bisa menghentikan server';
	@override String get autoPip => 'Foto-foto dalam gambar';
	@override String get autoPipDescription => 'Secara otomatis masuk gambar-in-gambar ketika Anda meninggalkan aplikasi selama pemutaran';
	@override String get matchContentFrameRate => 'Perbandingan Content Frame Rate';
	@override String get matchContentFrameRateDescription => 'Pertandingan paparan tingkat pembaharuan untuk konten video';
	@override String get matchContentResolution => 'Resolusi Konten Pertandingan';
	@override String get matchContentResolutionDescription => 'Tukar paparan ke resolusi asli video sehingga TV Anda menangani upscaling. menu dan subtitle juga upscaled selama playback';
	@override String get matchRefreshRate => 'Pertandingan Meningkatkan Rata';
	@override String get matchRefreshRateDescription => 'Match Display Rata Pembaharuan di Full Screen';
	@override String get matchDynamicRange => 'Rangkaian Dinamik';
	@override String get matchDynamicRangeDescription => 'Tukar HDR untuk konten HDR, kemudian kembali ke SDR';
	@override String get displaySwitchDelay => 'Penundaan switch';
	@override String get tunneledPlayback => 'Pelatihan Playback';
	@override String get tunneledPlaybackDescription => 'Gunakan tunel video. mematikan jika HDR playback menampilkan video hitam atau stutters gerakan.';
	@override String get audioPassthrough => 'Audio yang berkelanjutan';
	@override String get audioPassthroughDescription => 'Kirim audio Dolby/DTS ke penerima atau TV Anda tanpa kode ulang, menyimpan suara sekitar.';
	@override String get audioPassthroughDescriptionApple => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. DTS dan TrueHD masih memainkan sebagai PCM multi-saluran.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. Pada iOS, iPadOS dan tvOS 26 atau lebih, TrueHD Atmos dan DTS:X memainkan sebagai audio ruang.';
	@override String get audioPassthroughOverriddenByNormalization => 'Sementara suara normalisasi sedang';
	@override String get audioChannelLimit => 'Saluran audio';
	@override String get audioChannelLimitDescription => 'Campurkan audio yang dikodkan untuk speaker, headphone, atau setup HDMI yang tidak dapat memainkan setiap saluran';
	@override String get audioChannelLimitOriginal => 'asli';
	@override String get audioChannelLimitOriginalDescription => 'Mainkan setiap saluran di jalur';
	@override String get audioChannelLimitSurround51 => 'hingga 5.1';
	@override String get audioChannelLimitSurround51Description => 'Campurkan 7.1 ke bawah 5.1 untuk TV dan penerima yang hanya mengambil 5.1 PCM.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Campurkan ke dua saluran untuk speaker stereo atau headset.';
	@override String get downmixCenterBoost => 'Bintang Channel Boost';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Peningkatan (db)';
	@override String get downmixCenterBoostShort => 'db';
	@override String get audioDownmixNormalize => 'Meningkatkan volume pada Downmix';
	@override String get audioDownmixNormalizeDescription => 'Mengurangi campuran untuk menghindari penipuan. tutup untuk menjaga volume asli (mungkin mengganggu adegan yang keras).';
	@override String get dvConversionMode => 'Dolby Vision Konversi';
	@override String get dvConversionModeDescription => 'Pilih bagaimana Dolby Vision Profil 7 file diproses.';
	@override String get dvConversionAuto => 'mobil';
	@override String get dvConversionNative => 'Penduduk / Penyandang Disabilitas';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Menggunakan kemampuan deteksi perangkat dan perilaku fallback normal';
	@override String get dvConversionNativeDescription => 'Kuasa asli DV7 dan penindasan DV konversi retry';
	@override String get dvConversionDv81Description => 'Konversi RPU Inline Kekuatan ke Dolby Vision Profil 8.1';
	@override String get dvConversionHevcStripDescription => 'Strip Dolby Vision lapisan RPU/EL dan rata saat ini HEVC';
	@override String get experimentalDolbyVision => 'Dolby Vision eksperimental';
	@override String get experimentalDolbyVisionDescription => 'Gunakan perender FEL eksperimental pada pemutaran berikutnya. Memerlukan build mesin terpisah.';
	@override String get dvExperimentUnavailableDescription => 'Eksperimen ini saat ini hanya tersedia di Linux.';
	@override String get dvCompatibilityFallback => 'Cadangan kompatibilitas';
	@override String get dvCompatibilityFallbackDescription => 'Gunakan perender standar jika eksperimen tidak dapat dimulai. Data FEL mungkin hilang.';
	@override String get dvExperimentDiagnostics => 'Pencatatan eksperimen video';
	@override String get dvExperimentDiagnosticsDescription => 'Aktifkan log pemutar terperinci pada pemutaran berikutnya.';
	@override String get disableDolbyVision => 'Tidak dapat dibatasi Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Bermain file HDR10 atau lapisan HLG bukannya Dolby Vision, ketika itu memiliki satu';
	@override String get hdrSdrConversion => 'Konversi HDR ke SDR';
	@override String get hdrSdrConversionDescription => 'Pilih apa yang mengubah video HDR ketika layar tidak dapat menampilkan HDR.';
	@override String get hdrSdrConversionAuto => 'mobil';
	@override String get hdrSdrConversionAutoDescription => 'Perangkat pada Android 9 dan lebih baru, pemain pada versi yang lebih tua';
	@override String get hdrSdrConversionDevice => 'Perangkat';
	@override String get hdrSdrConversionDeviceDescription => 'Hardware video perangkat Anda mengubahnya. paling cepat, tetapi warna tergantung pada perangkat';
	@override String get hdrSdrConversionPlayer => 'Pemutar';
	@override String get hdrSdrConversionPlayerDescription => 'Warna konsisten, tetapi 4K dapat menandai kotak TV low-end';
	@override String get deinterlace => 'Interlokasi';
	@override String get deinterlaceDescription => 'Menghapus artefak berkombinasi dari video yang terhubung (mpv pemain saja)';
	@override String get deinterlaceOff => 'Nonaktif';
	@override String get deinterlaceOffDescription => 'Menampilkan video terhubung saat dikodkan';
	@override String get deinterlaceVideo => 'Video yang';
	@override String get deinterlaceVideoDescription => 'Tukar setiap medan ke dalam bingkai penuh. untuk video tangkapan untuk TV, seperti olahraga, berita, dan konser';
	@override String get deinterlaceFilm => 'Film yang';
	@override String get deinterlaceFilmDescription => 'Restorasi bingkai asli film dan animasi telecined ke 29.97 fps, umum pada DVD NTSC. Video shot untuk TV stutters. Live TV menggunakan Video';
	@override String get requireProfileSelectionOnOpen => 'Meminta profil di aplikasi terbuka';
	@override String get requireProfileSelectionOnOpenDescription => 'Menampilkan seleksi profil setiap kali aplikasi dibuka';
	@override String get forceTvMode => 'Mode TV Kekuatan';
	@override String get forceTvModeDescription => 'Untuk perangkat yang tidak mendeteksi secara otomatis. memerlukan restart.';
	@override String get startInFullscreen => 'Mulai dengan layar penuh';
	@override String get startInFullscreenDescription => 'Buka PlezyNG dalam mode layar penuh saat diluncurkan';
	@override String get exitFullscreenOnPlayerClose => 'Penuh layar keluar pada player close';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Secara otomatis keluar layar penuh saat menutup pemutar video';
	@override String get autoHidePerformanceOverlay => 'Auto-Hide Performa Overlay';
	@override String get autoHidePerformanceOverlayDescription => 'Fade performance overlay dengan playback controls';
	@override String get showNavBarLabels => 'Tampilkan Navigasi Bar Label';
	@override String get showNavBarLabelsDescription => 'Menampilkan label teks di bawah ikon bar navigasi';
	@override String get startupSection => 'Bagian Startup';
	@override String get preferredServer => 'Server yang disukai';
	@override String get preferredServerDescription => 'Prioritaskan hasil server ini sambil menjaga setiap server terhubung tersedia.';
	@override String get preferredServerAutomatic => 'otomatis';
	@override String get showExploreTab => 'Menampilkan Tab';
	@override String get showExploreTabDescription => 'Tampilkan tab Explore dengan konten dari Plex Discover dan tracker terhubung';
	@override String get hideEmptyLibraries => 'Menutup perpustakaan kosong';
	@override String get hideEmptyLibrariesDescription => 'Menghapus perpustakaan dengan jumlah item yang dilaporkan oleh server dari nol dari navigasi.';
	@override String get liveTvDefaultFavorites => 'Menerima saluran favorit';
	@override String get liveTvDefaultFavoritesDescription => 'Menampilkan hanya saluran favorit saat membuka Live TV';
	@override String get general => 'Umum';
	@override String get generalDescription => 'Bahasa, startup, dan tingkap perilaku';
	@override String get languageAndRegion => 'Bahasa & Wilayah';
	@override String get startup => 'Saat mulai';
	@override String get display => 'Tampilan';
	@override String get libraryAndCards => 'Perpustakaan & Kartu';
	@override String get homeScreen => 'Home layar';
	@override String get navigation => 'Navigasi';
	@override String get window => 'jendela';
	@override String get liveTv => 'TV Langsung';
	@override String get player => 'Pemutar';
	@override String get videoAndDisplay => 'Video dan Display';
	@override String get audio => 'Audio yang';
	@override String get quality => 'Kualitas';
	@override String get subtitles => 'Subtitel';
	@override String get seekAndTiming => 'Pencarian & Timing';
	@override String get behavior => 'perilaku';
	@override String get gestures => 'Gejala';
	@override String get gestureBrightnessSwipe => 'Cahaya bersinar';
	@override String get gestureBrightnessSwipeDescription => 'Putar ke atas atau ke bawah di tepi kiri untuk menyesuaikan kecerahan';
	@override String get gestureVolumeSwipe => 'Jumlah Swipe';
	@override String get gestureVolumeSwipeDescription => 'Beralih ke atas atau ke bawah di tepi kanan untuk menyesuaikan volume';
	@override String get gesturePinchToZoom => 'Pinch untuk Zoom';
	@override String get gesturePinchToZoomDescription => 'Klik pada video untuk zoom ke dalam atau keluar';
	@override String get gestureSeekSwipe => 'Mencari Swipe';
	@override String get gestureSeekSwipeDescription => 'Beralih ke kiri atau kanan di mana saja di video untuk mencari; melepaskan untuk melompat';
	@override String get rememberBrightnessLevel => 'Mengingat tingkat kecerahan';
	@override String get rememberBrightnessLevelDescription => 'Mulai playback pada kecerahan yang ditetapkan oleh swipe terakhir';
	@override String get controls => 'Kontrol';
	@override String get rememberPlayerChanges => 'Ingat perubahan pemain';
	@override String get rememberPlayerChangesDescription => 'Di mana perubahan yang dibuat selama playback disimpan dan diterapkan kembali dari';
	@override String get scopePlaybackSpeed => 'Kecepatan Pemutaran';
	@override String get scopeShaderPreset => 'Shader Preset yang';
	@override String get scopeAspectRatio => 'Rasio perbandingan';
	@override String get scopeSyncOffsets => 'Audio dan Subtitle Sync';
	@override String get playerScopeOff => 'Jangan Menyelamatkan';
	@override String get playerScopeGlobal => 'di mana-mana';
	@override String get playerScopeLibrary => 'Per Perpustakaan';
	@override String get playerScopeTitle => 'Untuk acara atau film';
	@override String get exportDialogTitle => 'Eksport PlezyNG pengaturan';
	@override String get followSystem => 'Ikuti sistem';
	@override String get followAppLanguage => 'Samakan dengan bahasa antarmuka';
	@override String get regionFormat => 'Format regional';
	@override String get regionFormatDescription => 'Pilih cara menampilkan tanggal, angka, dan satuan ukuran.';
	@override String get metadataLanguage => 'Bahasa metadata';
	@override String get metadataLanguageDescription => 'Bahasa judul dan deskripsi yang diutamakan jika didukung server. Preferensi audio dan subtitel diatur secara terpisah.';
	@override String get enterFullscreenOnPlaybackStart => 'Masuk layar penuh saat playback dimulai';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Buka desktop video pada layar penuh ketika playback dimulai';
	@override String get extendVideoIntoDisplayCutout => 'Mengembangkan video ke display cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Biarkan video layar penuh menggunakan kamera cutout pada ponsel Android';
	@override String get languageDescription => 'Pilih bahasa yang digunakan untuk kontrol dan pesan PlezyNG. sistem mengikuti bahasa perangkat Anda.';
	@override String get themeDescription => 'Pilih warna dan kontras yang digunakan di seluruh aplikasi.';
	@override String get libraryDensityDescription => 'Mengubah berapa banyak kartu perpustakaan yang cocok dalam setiap baris.';
	@override String get displayScaleDescription => 'Memperbaiki antarmuka pada layar mobil ini tanpa mengubah ukuran teks seluruh perangkat Anda.';
	@override String get themeSongVolumeDescription => 'Tetapkan volume lagu tema yang relatif dengan audio lainnya.';
	@override String get viewModeDescription => 'Pilih apakah item perpustakaan muncul sebagai poster di jaringan atau sebagai daftar kompak.';
	@override String get gridViewDescription => 'Mengatur item perpustakaan dalam baris dan kolom poster.';
	@override String get listViewDescription => 'Tunjukkan item perpustakaan dalam daftar vertikal dengan lebih banyak teks per item.';
	@override String get gridSpacingDescription => 'Tetapkan jurang antara poster di jaringan perpustakaan.';
	@override String get gridSpacingTightDescription => 'Tetapkan lebih banyak poster di seluruh layar dengan jurang yang lebih kecil.';
	@override String get gridSpacingNormalDescription => 'Gunakan jurang standar antara poster.';
	@override String get gridSpacingSpaciousDescription => 'Tambahkan jurang yang lebih besar antara poster untuk pemisahan lebih banyak.';
	@override String get episodePosterModeDescription => 'Pilih karya seni yang muncul pada kartu episode.';
	@override String get seriesPosterDescription => 'Gunakan poster serial untuk setiap episode.';
	@override String get seasonPosterDescription => 'Gunakan poster musim untuk setiap episode ketika tersedia.';
	@override String get episodeThumbnailDescription => 'Gunakan bingkai dari episode ketika tersedia.';
	@override String get continueWatchingActionDescription => 'Pilih apa yang terjadi saat Anda mengaktifkan kartu terus-menerus.';
	@override String get continueWatchingPlayDescription => 'Mulai film atau episode dengan segera.';
	@override String get continueWatchingDetailsDescription => 'Buka halaman judul terlebih dahulu sehingga Anda dapat meninjau rincian dan memilih tindakan.';
	@override String get episodeActionDescription => 'Pilih apa yang terjadi saat Anda mengaktifkan kartu episode.';
	@override String get episodePlayDescription => 'Mulailah episode ini dengan segera.';
	@override String get episodeDetailsDescription => 'Buka halaman episode sebelum playback.';
	@override String get contentScreensaverDelayDescription => 'Pilih berapa lama PlezyNG menunggu tanpa input sebelum menunjukkan karya seni.';
	@override String get continueWatchingRowSizeDescription => 'Pilih seberapa besar kartu yang ada di baris terus-menerus.';
	@override String get rowSizeCompactDescription => 'Tunjukkan kartu yang lebih kecil sehingga lebih banyak item cocok di sepanjang baris.';
	@override String get rowSizeStandardDescription => 'Gunakan ukuran kartu standar.';
	@override String get rowSizeLargeDescription => 'Tunjukkan kartu yang lebih besar dengan detail karya seni yang lebih banyak.';
	@override String get visualEffectsDescription => 'Pilih anggaran animasi dan efek karya seni untuk perangkat ini.';
	@override String get visualEffectsFullDescription => 'Gunakan efek animasi dan karya seni penuh pada setiap perangkat.';
	@override String get startupSectionDescription => 'Pilih bagian mana yang dibuka saat PlezyNG dimulai.';
	@override late final _Translations$settings$startupSectionOptions$id startupSectionOptions = _Translations$settings$startupSectionOptions$id._(_root);
	@override String get smallSkipDurationDescription => 'Tetapkan jarak yang dipindahkan oleh belakang pendek dan ke depan mencari kontrol.';
	@override String get largeSkipDurationDescription => 'Tetapkan jarak yang dipindahkan oleh belakang panjang dan ke depan mencari kontrol.';
	@override String get rewindOnResumeDescription => 'Move playback kembali dengan jumlah ini ketika mengembalikan video.';
	@override String get defaultSleepTimerDescription => 'Tetapkan durasi awal yang digunakan saat Anda memulai timer tidur.';
	@override String get playNextCountdownDescription => 'Tunggu ini lama sebelum memulai episode berikutnya. set ke 0 untuk memulai dengan segera.';
	@override String get autoSkipDelaySettingDescription => 'Ini berlaku ketika intro, kredit, atau iklan ditetapkan untuk meluncur secara otomatis.';
	@override String get downmixCenterBoostDescription => 'Meningkatkan dialog di saluran pusat ketika audio sekitar dicampur ke bawah ke stereo.';
	@override String get displaySwitchDelayDescription => 'Tunggu sebelum mengubah mode paparan sehingga TV atau penerima dapat menyelesaikan switch sebelumnya.';
	@override String get playerBackendDescription => 'Pilih mesin playback mana yang mendekorasi dan menghasilkan video pada perangkat ini.';
	@override String get exoPlayerDescription => 'Gunakan pemutar asli Android yang berbasis Media3 dan jalur perangkat keras yang didukung.';
	@override String get mpvDescription => 'Gunakan mpv, yang mendedahkan pemutaran tambahan, subtitle, dan kontrol pemrosesan video.';
	@override String get scopeOffDescription => 'Hanya menyimpan perubahan untuk sesi playback saat ini.';
	@override String get scopeGlobalDescription => 'Gunakan kembali nilai yang sama untuk setiap perpustakaan dan judul.';
	@override String get scopeLibraryDescription => 'Ingatlah nilai yang berbeda untuk setiap perpustakaan.';
	@override String get scopeTitleDescription => 'Ingat nilai terpisah untuk setiap acara atau film.';
	@override String get specialsOrderingServerDescription => 'Tinggalkan pesanan episode yang disediakan oleh server media.';
	@override String get specialsOrderingAirDateDescription => 'Menempatkan spesial di antara episode biasa pada tanggal udara mereka.';
	@override String get specialsOrderingLastDescription => 'Tempatkan masing-masing spesial setelah musim biasa.';
	@override String get skipIntroModeDescription => 'Pilih apakah intro markers bermain normal, menunjukkan tombol skip, atau skip secara otomatis.';
	@override String get skipCreditsModeDescription => 'Pilih apakah kredit bermain normal, menunjukkan tombol skip, atau skip secara otomatis.';
	@override String get skipAdsModeDescription => 'Pilih apakah iklan yang dideteksi memainkan secara normal, menampilkan tombol skip, atau skip secara otomatis.';
	@override String get playbackBufferAutoDescription => 'Biarkan pemain aktif memilih ukuran buffer normalnya.';
	@override String get playbackBufferLargeDescription => 'Tetap lebih banyak media siap sebelum playback; ini menggunakan lebih banyak memori.';
	@override String get playbackBufferExtraLargeDescription => 'Simpan buffer bacaan terbesar; ini menggunakan memori yang paling banyak.';
	@override String get defaultQualityDescription => 'Tetapkan resolusi video default dan bitrate atap untuk aliran yang transcod server.';
	@override String get cellularQualityDescription => 'Override Default Quality ketika perangkat menggunakan koneksi seluler saja.';
	@override String get remoteQualityDescription => 'Override Default Quality ketika terhubung ke server melalui koneksi remote.';
	@override String get qualityPresetOriginalDescription => 'Mainkan sumber pada kualitas yang tersedia tanpa meminta server untuk transcode.';
	@override String get qualityPresetTranscodeOptionDescription => 'Tanya server untuk aliran terkonversi menggunakan resolusi dan bitrate yang ditunjukkan di atas.';
	@override String get qualityPresetSameAsDefaultDescription => 'Gunakan kualitas yang dipilih dalam Default Quality.';
	@override String get musicQualityDescription => 'Tetapkan bitrate audio maksimum yang diminta dari server; Original mempertahankan aliran sumber.';
	@override String get musicQualityOriginalDescription => 'Mainkan audio sumber tanpa transcode bitrate.';
	@override String get musicQualityTranscodeOptionDescription => 'Meminta transcode server yang dicap dekat bitrate yang ditunjukkan di atas; output sebenarnya dapat bervariasi.';
	@override String get maxVolumeInputLabel => 'Jumlah maksimum (%)';
	@override String get checkForUpdatesDescription => 'Periksa sekarang apakah versi PlezyNG yang lebih baru tersedia.';
	@override String get appearanceDescription => 'Pilih tema aplikasi dan menyesuaikan kartu perpustakaan, baris rumah, dan navigasi.';
	@override String get prerollLibraryDescription => 'Pilih perpustakaan yang berisi klip yang tersedia sebagai pre-roll film.';
	@override String get prerollSelectionDescription => 'Pilih klip dari perpustakaan yang dipilih dapat dimainkan sebelum film.';
	@override String get contentScreensaverDelayOptionDescription => 'Tunggu ini beberapa menit tanpa input sebelum menunjukkan karya seni screensaver.';
	@override String get videoCodecOptionDescription => 'Memungkinkan playback langsung untuk codec ini ketika didukung. codec yang tidak disemak dikodifikasi oleh server media.';
}

// Path: themeEditor
class _Translations$themeEditor$id extends Translations$themeEditor$en {
	_Translations$themeEditor$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'dibangun';
	@override String get presets => 'Preset';
	@override String get custom => 'Kustom';
	@override String get customEmpty => 'belum diciptakan';
	@override String get editCustom => 'Edit Tema Khas';
	@override String get editCustomDescription => 'Pilih setiap warna sendiri';
	@override String get locked => 'Akses seumur hidup yang diperlukan';
	@override String get savedLocked => 'Disimpan - tersedia dengan akses seumur hidup';
	@override String get title => 'Tema yang disesuaikan';
	@override String get startFrom => 'Mulai dari';
	@override String get startFromDescription => 'Menyalin semua warna dari tema lain';
	@override String get colors => 'warna';
	@override String get preview => 'Pratinjau';
	@override late final _Translations$themeEditor$slots$id slots = _Translations$themeEditor$slots$id._(_root);
	@override String get opacity => 'Opacitas';
	@override String get hexHint => '#RRGGBB atau #AARRGGBB';
	@override String get fromOtherThemes => 'Dari tema lain';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$id contrast = _Translations$themeEditor$contrast$id._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, di bawah yang disarankan ${minimum}:1';
	@override String get discardTitle => 'Mengabaikan perubahan?';
	@override String get discardMessage => 'Perubahan warna yang tidak disimpan akan hilang.';
	@override String get discard => 'Diskarat';
	@override String previewCardTitle({required Object number}) => 'Keterangan ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} min dibatasi';
	@override String get previewSwitch => 'Putar otomatis';
	@override String get previewMutedText => 'Artikel ini dibaca seperti ini';
	@override String get themeSystemDescription => 'Ikuti penampilan perangkat Anda dan beralih antara cahaya dan kegelapan secara otomatis.';
	@override String get themeLightDescription => 'Gunakan latar belakang yang terang dengan teks gelap.';
	@override String get themeDarkDescription => 'Gunakan latar belakang gelap dengan teks terang.';
	@override String get themeOledDescription => 'Gunakan permukaan berdekatan hitam yang mengurangi cahaya pada layar OLED.';
	@override String get themeEmberDescription => 'Gunakan warna merah hangat dan aksen amber.';
	@override String get themeGlacierDescription => 'Gunakan warna aksen biru yang sejuk.';
	@override String get themeForestDescription => 'Gunakan warna hijau dan aksen alami.';
	@override String get themePlumDescription => 'Gunakan warna aksen violet dan plum.';
	@override String get themePaperDescription => 'Gunakan permukaan yang hangat seperti kertas dan warna terinspirasi tinta.';
	@override String get themeCustomDescription => 'Gunakan palet warna yang Anda ciptakan dalam editor tema tersuai.';
	@override String get editorDescription => 'Pilih warna palet, menyesuaikan kulitnya, kenyang, kecerahan, atau ketidakselesaan, dan lihat update preview sebelum menghemat.';
}

// Path: search
class _Translations$search$id extends Translations$search$en {
	_Translations$search$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Mencari film, acara, musik...';
	@override String get tryDifferentTerm => 'Cobalah istilah pencarian yang berbeda';
	@override String get searchYourMedia => 'Temukan Media Anda';
	@override String get enterTitleActorOrKeyword => 'Masukkan judul, aktor, atau kata kunci';
	@override String get people => 'Orang-orang';
}

// Path: hotkeys
class _Translations$hotkeys$id extends Translations$hotkeys$en {
	_Translations$hotkeys$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Set Shortcut untuk ${actionName}';
	@override String get clearShortcut => 'Singkatnya';
	@override String get noShortcutSet => 'Tidak ada shortcut set';
	@override String get currentShortcut => 'Current singkatan :';
	@override String get pressToRecord => 'Pilih untuk mencatat singkatan';
	@override String get recordingShortcut => 'Tekan Shortcut sekarang';
	@override late final _Translations$hotkeys$actions$id actions = _Translations$hotkeys$actions$id._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$id extends Translations$fileInfo$en {
	_Translations$fileInfo$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informasi File';
	@override String get overview => 'Tinjauan';
	@override String get video => 'Video yang';
	@override String get audio => 'Audio yang';
	@override String get subtitles => 'Subtitel';
	@override String get images => 'Gambar yang terintegrasi';
	@override String get dataStreams => 'Data Stream';
	@override String get lyrics => 'Lirik';
	@override String get file => 'File yang';
	@override String get attachments => 'Aksesori';
	@override String get delivery => 'Pengiriman';
	@override String versionCounter({required Object index, required Object count}) => 'Versi ${index} dari ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'File ${index} dari ${count}';
	@override String get noStreams => 'Server tidak melaporkan streaming untuk file ini.';
	@override String get copyPath => 'Kopi Jalan';
	@override String get pathCopied => 'File Path yang disalin';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Tag Kodek';
	@override String get resolution => 'Resolusi';
	@override String get codedResolution => 'Resolusi Kod';
	@override String get bitrate => 'Bitrate yang';
	@override String get frameRate => 'Rata-rata Frame';
	@override String get rotation => 'Rotasi';
	@override String get comment => 'Bagaimana';
	@override String get audioDescription => 'Audio deskripsi';
	@override String get headerCompression => 'Kepala Kompresi';
	@override String get sidecarFile => 'Sidecar file';
	@override String get transportTimestamp => 'Pengangkutan Timestamp';
	@override String get displayOffset => 'Menampilkan Offset';
	@override String get previewFailureCode => 'Preview Kode Kegagalan';
	@override String get previewRetries => 'Preview Kembali';
	@override String get aspectRatio => 'Rasio perbandingan';
	@override String get pixelAspectRatio => 'Piksel Aspek Ratio';
	@override String get profile => 'Profil';
	@override String get level => 'Tingkat';
	@override String get bitDepth => 'Kedalaman Bit';
	@override String get pixelFormat => 'Format Piksel';
	@override String get colorSpace => 'Ruang warna';
	@override String get colorRange => 'Rangkaian warna';
	@override String get colorPrimaries => 'Warna primer';
	@override String get colorTransfer => 'Transfer warna';
	@override String get chromaSubsampling => 'Kromium Subsampling';
	@override String get chromaLocation => 'Lokasi Chromium';
	@override String get scanType => 'Scan jenis';
	@override String get interlaced => 'Terjalin';
	@override String get anamorphic => 'Anamorfik';
	@override String get referenceFrames => 'Referensi Framework';
	@override String get dynamicRange => 'Rangkaian Dinamik';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision Tingkat';
	@override String get dolbyVisionVersion => 'Dolby Vision versi';
	@override String get dolbyVisionLayers => 'Dolby Vision Layer';
	@override String get baseLayerCompatibility => 'Kompatibilitas Layer Basis';
	@override String get avcBitstream => 'Perbedaan AVC Bitstream';
	@override String get nalLengthSize => 'Ukuran panjang';
	@override String get scalingMatrix => 'Matriks Scaling yang tersuai';
	@override String get streamIdentifier => 'Identifikasi Stream';
	@override String get streamIndex => 'Indeks Stream';
	@override String get streamId => 'ID aliran';
	@override String get language => 'Bahasa';
	@override String get languageCode => 'kode bahasa';
	@override String get streamTitle => 'Judul Track';
	@override String get channels => 'Saluran';
	@override String get sampleRate => 'Nilai Sampel';
	@override String get spatialAudio => 'Ruang Audio';
	@override String get textBased => 'Teks Berdasarkan';
	@override String get subtitleFormat => 'Formasi Sidecar';
	@override String get provider => 'Penyedia';
	@override String get matchScore => 'Pertandingan skor';
	@override String get externalDelivery => 'dapat disajikan secara terpisah';
	@override String get sidecarPath => 'Jalan Sidekar';
	@override String get sourceStream => 'Diterjemahkan dari';
	@override String get temporary => 'sementara';
	@override String get timeBase => 'basis waktu';
	@override String get overallBitrate => 'Jumlah Bitrate';
	@override String get path => 'Lokasi';
	@override String get fileName => 'Nama file';
	@override String get size => 'Ukuran';
	@override String get totalSize => 'Total ukuran';
	@override String get container => 'Penyimpan';
	@override String get duration => 'Durasi';
	@override String get previewThumbnails => 'Praktek Tumbnails';
	@override String get previewIndex => 'Indeks Preview';
	@override String get packetLength => 'Panjang paket';
	@override String get filePresent => 'File yang hadir';
	@override String get fileReadable => 'dapat dibaca oleh server';
	@override String get streamPath => 'Jalur aliran';
	@override String get optimizedForStreaming => 'Optimisasi untuk Streaming';
	@override String get has64bitOffsets => '64 bit offset';
	@override String get protocol => 'Protokol';
	@override String get mediaType => 'Jenis Media';
	@override String get sourceKind => 'Sumber yang baik';
	@override String get optimizedVersion => 'Versi yang Optimis';
	@override String get optimizationTarget => 'Optimisasi Target';
	@override String get deletedAt => 'dihapus';
	@override String get remoteSource => 'Sumber Jarak Jauh';
	@override String get infiniteStream => 'Infinite aliran';
	@override String get directPlay => 'Bermain langsung';
	@override String get directStream => 'Stream langsung';
	@override String get transcoding => 'Transkode';
	@override String get etag => 'ETag';
	@override String get versionId => 'Versi ID';
	@override String get fileId => 'ID berkas';
	@override String get defaultAudioTrack => 'Perangkat Audio Track';
	@override String get defaultSubtitleTrack => 'Subtitle Track yang';
	@override String get subtitlesOff => 'Nonaktif';
	@override String get flagDefault => 'Bawaan';
	@override String get flagForced => 'Dipaksa';
	@override String get flagSelected => 'Seleksi';
	@override String get flagExternal => 'Eksternal';
	@override String get flagHearingImpaired => 'Mendengarkan terganggu';
	@override String get flagDub => 'Dub yang';
	@override String get flagOriginal => 'asli';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$id extends Translations$mediaMenu$en {
	_Translations$mediaMenu$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Mark yang dilihat';
	@override String get markAsUnwatched => 'Mark sebagai Unwatched';
	@override String get removeFromContinueWatching => 'Menghapus dari terus menonton';
	@override String get viewDetails => 'Lihat detail';
	@override String get goToSeries => 'Pergi ke seri';
	@override String get shufflePlay => 'Bermain Shuffle';
	@override String get shuffleNotAvailableOffline => 'Shuffle tidak tersedia offline';
	@override String get fileInfo => 'Informasi File';
	@override String get deleteEpisodeFromServer => 'Menghapus episode dari server';
	@override String get deleteSeasonFromServer => 'Menghapus Musim dari Server';
	@override String get deleteShowFromServer => 'Menghapus tampilan dari server';
	@override String get deleteMovieFromServer => 'Menghapus film dari server';
	@override String get deleteEpisodeTitle => 'Apakah Anda menghapus episode ini?';
	@override String get deleteSeasonTitle => 'Apakah Anda menghapus musim ini?';
	@override String get deleteShowTitle => 'Apakah Anda menghapus acara ini?';
	@override String get deleteMovieTitle => 'Menghapus film ini?';
	@override String get deleteEpisodeConfirm => 'Hapus Episode';
	@override String get deleteSeasonConfirm => 'Musim yang dihapus';
	@override String get deleteShowConfirm => 'Menghapus Show';
	@override String get deleteMovieConfirm => 'Menghapus Film';
	@override String get deleteAnyway => 'Menghapus bagaimanapun';
	@override String confirmDeleteTarget({required Object title}) => 'Permanen menghapus ${title} dari server Anda?';
	@override String get deleteMultipleWarning => 'Ini termasuk semua episode dan file mereka.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: 'Ini menghapus semua ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode di dalamnya, dan file mereka.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: 'Item ini disimpan di seluruh file ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}, dan semua dari mereka akan dihapus.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode lain disimpan dalam file yang sama dan juga akan dihapus:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG tidak dapat memeriksa berkas mana yang akan dihapus, sehingga mungkin menghapus lebih dari item yang disebutkan di atas. Batalkan dan coba lagi, atau tetap hapus.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Server tidak memberikan rincian berkas untuk item ini, sehingga PlezyNG tidak dapat memeriksa berkas mana yang akan dihapus. Penghapusan mungkin mencakup lebih dari item yang disebutkan di atas.';
	@override String get mediaDeletedSuccessfully => 'Media item dihapus dengan sukses';
	@override String get mediaFailedToDelete => 'gagal menghapus media item';
	@override String get rate => 'Rating';
	@override String get playFromBeginning => 'Mainkan dari awal';
	@override String get playVersion => 'Bermain versi...';
}

// Path: rateSheet
class _Translations$rateSheet$id extends Translations$rateSheet$en {
	_Translations$rateSheet$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rating';
	@override String get server => 'Server yang';
	@override String get favorite => 'Favorit';
	@override String get favorited => 'Favorit';
	@override String get saved => 'diselamatkan';
	@override String get notAvailable => 'Tidak ditemukan pertandingan';
	@override String get noConnectedServices => 'Sambungkan layanan di Settings untuk menilai di sana.';
}

// Path: accessibility
class _Translations$accessibility$id extends Translations$accessibility$en {
	_Translations$accessibility$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, acara televisi';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'Ditonton';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} persen dilihat';
	@override String get mediaCardUnwatched => 'belum ditonton';
	@override String get tapToPlay => 'Ketuk untuk memutar';
	@override String get decrease => 'Penurunan';
	@override String get increase => 'Meningkat';
	@override String decreaseValue({required Object label}) => 'Penurunan ${label}';
	@override String increaseValue({required Object label}) => 'Peningkatan ${label}';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturasi';
	@override String get brightness => 'kecerahan';
	@override String get hexColor => 'Hex warna';
	@override String get expandText => 'Perkembangan teks';
	@override String get collapseText => 'Teks yang runtuh';
	@override String get alphabetNavigation => 'Navigasi Alphabet';
	@override String get alphabetScrollHint => 'Geser ke atas atau ke bawah untuk berpindah menurut huruf';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Jalur ${row} dari ${rowCount}, kolom ${column} dari ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Ruang ${row} dari ${rowCount}';
	@override String get autoScrollPlay => 'Bermain dengan Auto-Scroll';
	@override String get autoScrollPause => 'Perhentian Auto-Scroll';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Merah';
	@override String get green => 'Hijau';
	@override String get blue => 'Biru';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Aksesibilitas';
	@override String get summary => 'Teks, kontras, gerakan dan kontrol';
	@override String get systemHint => 'Sesuai dengan pengaturan aksesibilitas perangkat Anda, Anda akan selalu menggunakan pengaturan ini. pilihan ini menambah penyesuaian sepanjang PlezyNG.';
	@override String get readability => 'Membaca dan melihat';
	@override String get textSize => 'Ukuran teks tambahan';
	@override String get preview => 'Baca, dengar dan lihat pada kecepatan Anda sendiri.';
	@override String get boldText => 'Interface yang baik';
	@override String get highContrast => 'kontras yang tinggi';
	@override String get highContrastHint => 'Teks yang lebih kuat, outlines dan fokus indikator pada permukaan terang atau gelap.';
	@override String get interaction => 'Pergerakan dan Interaksi';
	@override String get reduceMotion => 'Mengurangi gerakan';
	@override String get reduceMotionHint => 'Hentikan animasi indikator fokus, transisi halaman, dan efek dekoratif.';
	@override String get largeTargets => 'Target Touch yang lebih besar';
	@override String get largeTargetsHint => 'Memberi kontrol yang dikongsi lebih banyak ruang untuk sentuhan dan navigasi asisten.';
	@override String get navigationHint => 'Gunakan Tab dan Shift+Tab untuk berpindah antar kontrol, Enter atau Space untuk mengaktifkan, dan Escape atau tombol Kembali untuk menutup. Zoom dan preferensi membaca tersedia saat buku terbuka.';
	@override String get textSizeDescription => 'Skala antara muka teks dalam PlezyNG ditambah dengan pengaturan ukuran teks sistem perangkat Anda.';
	@override String get boldTextHint => 'Gunakan berat yang lebih berat untuk label dan pesan antarmuka untuk membuat mereka lebih mudah dibedakan.';
}

// Path: tooltips
class _Translations$tooltips$id extends Translations$tooltips$en {
	_Translations$tooltips$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Permainan Shuffle';
	@override String get playTrailer => 'Bermain Trailer';
	@override String get markAsWatched => 'Mark yang ditonton';
	@override String get markAsUnwatched => 'Mark yang tidak diperhatikan';
}

// Path: audioTracks
class _Translations$audioTracks$id extends Translations$audioTracks$en {
	_Translations$audioTracks$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Trek audio ${n}';
}

// Path: videoControls
class _Translations$videoControls$id extends Translations$videoControls$en {
	_Translations$videoControls$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengaturan',
	);
	@override String get audioLabel => 'Audio yang';
	@override String get subtitlesLabel => 'Subtitel';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Surat Kotak';
	@override String get fillScreen => 'Mengisi layar';
	@override String get stretch => 'Mengisi';
	@override String get lockRotation => 'Lock rotasi';
	@override String get unlockRotation => 'Unlock rotasi';
	@override String get timerActive => 'Timer aktif';
	@override String playbackWillPauseIn({required Object duration}) => 'Playback akan berhenti di ${duration}';
	@override String get sleepTimerEndOfVideo => 'Akhir dari video saat ini';
	@override String get sleepTimerStopAtHeader => 'Berhenti di';
	@override String get sleepTimerDurationHeader => 'Waktu';
	@override String get playbackWillPauseAtEnd => 'Playback Akan Berhenti di Akhir Video Ini';
	@override String get stillWatching => 'Masih menonton?';
	@override String pausingIn({required Object seconds}) => 'Berhenti di ${seconds}s';
	@override String get continueWatching => 'Selanjutnya';
	@override String get autoPlayNext => 'Auto-Play selanjutnya';
	@override String get playNext => 'Mainkan selanjutnya';
	@override String get playButton => 'Putar';
	@override String get pauseButton => 'Jeda';
	@override String get playbackPaused => 'beristirahat';
	@override String get playbackResumed => 'Bermain';
	@override String get loadingVideo => 'Download video';
	@override String get showPlaybackControls => 'Menampilkan Playback Control';
	@override String get hidePlaybackControls => 'Menggunakan Playback Control';
	@override String seekBackwardButton({required Object seconds}) => 'Mencari ke belakang ${seconds} detik';
	@override String seekForwardButton({required Object seconds}) => 'Mencari ke depan ${seconds} detik';
	@override String get previousButton => 'episode sebelumnya';
	@override String get nextButton => 'Episode Selanjutnya';
	@override String get previousChapterButton => 'Bab sebelumnya';
	@override String get nextChapterButton => 'Bab selanjutnya';
	@override String get muteButton => 'Bisukan';
	@override String get unmuteButton => 'Membunyikan';
	@override String get settingsButton => 'Pengaturan Playback';
	@override String get tracksButton => 'Audio dan Subtitle';
	@override String get trackSelectionTitle => 'Pilih jalur sebelum playback';
	@override String get trackSelectionAuto => 'Seleksi otomatis';
	@override String get chaptersButton => 'bab yang';
	@override String get versionQualityButton => 'Versi & Kualitas';
	@override String get versionColumnHeader => 'Versi';
	@override String get qualityColumnHeader => 'Kualitas';
	@override String get qualityOriginal => 'asli';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcoding tidak tersedia – bermain kualitas asli';
	@override String get subtitleUnavailableFallback => 'Subtitle yang dipilih tidak dapat dimuat — terus tanpa subtitle';
	@override String get pipButton => 'Gambar dalam mode';
	@override String get openMiniPlayer => 'Pemain mini terbuka';
	@override String get returnToFullPlayer => 'Kembali ke Full Player';
	@override String get aspectRatioButton => 'Rasio perbandingan';
	@override String get ambientLighting => 'Lampu Lingkungan';
	@override String get fullscreenButton => 'Masuk ke layar penuh';
	@override String get exitFullscreenButton => 'Penampilan Full Screen';
	@override String get alwaysOnTopButton => 'Selalu di atas';
	@override String get rotationLockButton => 'Lock rotasi';
	@override String get lockScreen => 'Lock layar';
	@override String get screenLockButton => 'layar lock';
	@override String get longPressToUnlock => 'Tekan panjang untuk membuka kunci';
	@override String get timelineSlider => 'Video Timeline';
	@override String get volumeSlider => 'Tingkat Volume';
	@override String endsAt({required Object time}) => 'Berakhir di ${time}';
	@override String get pipActive => 'Bermain dalam Picture-in-Picture';
	@override String get pipFailed => 'Gambar-gambar yang gagal dimulai';
	@override String get screenshotSaved => 'Screenshot disimpan';
	@override String get screenshotFailed => 'Tidak bisa mengambil screenshot';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override String volumePercent({required Object percent}) => 'Volume ${percent}%';
	@override late final _Translations$videoControls$pipErrors$id pipErrors = _Translations$videoControls$pipErrors$id._(_root);
	@override String get chapters => 'bab yang';
	@override String get noChaptersAvailable => 'Tidak ada bab yang tersedia';
	@override String get queue => 'Keuangan';
	@override String get noQueueItems => 'Tidak ada item dalam kue';
	@override String get noAudioDevicesAvailable => 'Tidak ada audio yang tersedia';
	@override String get searchSubtitles => 'Temuan Subtitle';
	@override String get loadSubtitleFile => 'Download file subtitle.';
	@override String get subtitleLoadFailed => 'gagal mengisi file subtitle';
	@override String get language => 'Bahasa';
	@override String get noSubtitlesFound => 'Tidak ditemukan subtitle';
	@override String get subtitleDownloaded => 'Subtitle diunduh';
	@override String get subtitleDownloadedNotApplied => 'Subtitle diunduh, tapi tidak bisa dipilih';
	@override String get subtitleDownloadFailed => 'Tidak bisa download subtitle';
	@override String get searchLanguages => 'Bahasa pencarian...';
	@override String get skipIntro => 'Pergi ke Into';
	@override String get skipCredits => 'Skripsi Kredit';
	@override String get skipAds => 'Pemberitahuan Skip';
	@override String get nextEpisode => 'Episode Selanjutnya';
	@override String subtitleTrack({required Object n}) => 'Jalan Raya ${n}';
	@override String subtitleFile({required Object name}) => 'Subtitel ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Penggunaan)';
	@override String get osdSubtitlesOff => 'Judul : Off';
	@override String osdSubtitles({required Object track}) => 'Nama Panggilan : ${track}';
	@override String osdAudio({required Object track}) => 'Audio : ${track}';
}

// Path: messages
class _Translations$messages$id extends Translations$messages$en {
	_Translations$messages$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Ditandai seperti yang dilihat';
	@override String get markedAsUnwatched => 'Ditandai sebagai tidak diperhatikan';
	@override String get markedAsWatchedOffline => 'Ditandai seperti yang dilihat (sinkronisasi saat online)';
	@override String get markedAsUnwatchedOffline => 'Ditandai sebagai tidak dipantau (sinkronisasi saat online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Penghapusan otomatis: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menonton download',
	);
	@override String get removedFromContinueWatching => 'Menghapus dari terus menonton';
	@override String errorLoading({required Object error}) => 'Kesalahan : ${error}';
	@override String get searchPartialResults => 'Beberapa server media tidak dapat dicari. menunjukkan hasil yang tersedia.';
	@override String get streamInterrupted => 'Stream dihentikan. bermain atau mencoba untuk berundur.';
	@override String get liveStreamInterrupted => 'Stream langsung dihentikan. pers bermain untuk retry.';
	@override String get fileInfoNotAvailable => 'Informasi file tidak tersedia';
	@override String get playbackAuthenticationRequired => 'Mendaftar kembali ke server media untuk memainkan item ini.';
	@override String get playbackServerUnavailable => 'Server media tidak tersedia. coba lagi nanti.';
	@override String get playbackDataInvalid => 'Server mengembalikan informasi playback yang tidak sah.';
	@override String get playbackCancelled => 'Playback sudah dibatalkan.';
	@override String get playbackFailed => 'Playback tidak bisa dimulai.';
	@override String playbackFailedDetail({required Object error}) => 'Playback tidak bisa dimulai: ${error}';
	@override String get audioOutputFailed => 'Periksa koneksi audio TV atau penerima; jika aplikasi lain tidak memiliki suara juga, memulai ulang perangkat.';
	@override String get mediaUnavailable => 'Konten ini tidak lagi tersedia.';
	@override String errorLoadingFileInfo({required Object error}) => 'Info file kesalahan: ${error}';
	@override String get errorLoadingSeries => 'Serangkaian Error Loading';
	@override String get musicNotSupported => 'Playback musik belum disokong';
	@override String get noDescriptionAvailable => 'Tidak ada deskripsi yang tersedia';
	@override String get noProfilesAvailable => 'Tidak ada profil tersedia';
	@override String get contactAdminForProfiles => 'Hubungi administrator server Anda untuk menambahkan profil';
	@override String get unableToDetermineLibrarySection => 'Tidak dapat menentukan bagian perpustakaan untuk item ini';
	@override String get logsCleared => 'Log yang dibersihkan';
	@override String get logsCopied => 'Daftar yang disalin ke clipboard';
	@override String get noLogsAvailable => 'Tidak ada log yang tersedia';
	@override String libraryScanning({required Object title}) => 'Mengimbas “${title}”';
	@override String libraryScanStarted({required Object title}) => 'Scan perpustakaan dimulai untuk "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Tidak berhasil memindai perpustakaan: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadata yang diperbaharui untuk "${title}..."';
	@override String metadataRefreshStarted({required Object title}) => 'Metadata pembaharuan dimulai untuk "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Tidak dapat memperbarui metadata: ${error}';
	@override String get logoutConfirm => 'Apakah Anda yakin Anda ingin keluar?';
	@override String get noSeasonsFound => 'Tidak ada musim ditemukan';
	@override String get seasonsLoadFailed => 'Tidak bisa mengisi musim';
	@override String get noEpisodesFound => 'Tidak ada episode yang ditemukan di musim pertama';
	@override String get noEpisodesFoundGeneral => 'Tidak ditemukan episode';
	@override String get episodesLoadFailed => 'Tidak bisa memuat episode';
	@override String get noResultsFound => 'Tidak ada hasil.';
	@override String sleepTimerSet({required Object label}) => 'Waktu tidur untuk ${label}';
	@override String get noItemsAvailable => 'Tidak ada item yang tersedia';
	@override String get failedToCreatePlayQueueNoItems => 'Tidak berhasil membuat kue permainan - tidak ada item';
	@override String failedPlayback({required Object action, required Object error}) => 'Kegagalan ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Beralih ke pemain yang kompatibel.';
	@override String get serverLimitTitle => 'Playback gagal';
	@override String get serverLimitBody => 'Kesalahan server (HTTP 500). batas bandwidth/transcoding mungkin menolak sesi ini.';
	@override String get mediaUnreadableTitle => 'File yang tidak tersedia';
	@override String get mediaUnreadableBody => 'Server menemukan item ini tetapi tidak dapat membaca file (HTTP 404). file ini mungkin telah dipindahkan, dihapus, atau penyimpanannya offline.';
	@override String get serverBusyTitle => 'Stream tidak tersedia';
	@override String get serverBusyBody => 'Server tetap menolak untuk streaming file ini (HTTP 503). itu mungkin restarting, sibuk, atau penyimpanan file mungkin offline. cuba lagi dalam beberapa saat — jika itu terus terjadi, minta pemilik server untuk memeriksa server dan penyimpanan file.';
	@override String get playbackNotAllowedTitle => 'Playback tidak diizinkan';
	@override String get playbackNotAllowedBody => 'Server menolak untuk streaming item ini (HTTP 403). akun Anda mungkin tidak memiliki izin untuk memainkannya, atau server mungkin hanya memungkinkan pemutaran di jaringan lokalnya.';
	@override String get logsUploaded => 'Log yang diunggah';
	@override String get logsUploadFailed => 'gagal mengunggah log';
	@override String get logId => 'ID log';
	@override String get burnedSubtitlesUseMenu => 'Subtitle dibakar ke dalam aliran ini. mengubahnya dari menu subtitle.';
	@override String get noVideoUrl => 'Tidak ada URL video';
	@override String get playbackNoMediaSources => 'Server tidak mengembalikan sumber media yang dapat dimainkan';
	@override String get playbackDataNotPrepared => 'Playback dimulai sebelum data siap.';
	@override String get streamSelectionUnavailable => 'Stream seleksi tidak tersedia untuk sumber ini';
	@override String get streamSelectionFailed => 'Tidak dapat menggunakan aliran yang dipilih';
	@override String get trackSelectionNotRemembered => 'Pilihan track ini hanya berlaku untuk playback saat ini.';
	@override String get serverUnavailableForProfile => 'Tidak ada server yang tersedia untuk profil aktif';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$id extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Kucing coklat cepat melompat ke atas anjing lazy';
	@override String get text => 'Teks';
	@override String get border => 'Perbatasan';
	@override String get background => 'latar belakang';
	@override String get fontSize => 'Ukuran Font';
	@override String get textColor => 'Warna teks';
	@override String get borderSize => 'Ukuran Perbatasan';
	@override String get borderColor => 'Perbatasan warna';
	@override String get backgroundOpacity => 'Latar Belakang Opacity';
	@override String get backgroundColor => 'warna latar belakang';
	@override String get position => 'Posisi';
	@override String get assOverride => 'ASS Perbedaan';
	@override String get overrideScale => 'Skala';
	@override String get overrideForce => 'Kekuatan';
	@override String get overrideStrip => 'Menghapus styling';
	@override String get positionTop => 'Top';
	@override String get positionBottom => 'Bawah';
	@override String get useMargins => 'Menggunakan margin';
	@override String get useMarginsDescription => 'Biarkan subtitle teks di ruang di luar video. subtitle bergaya dapat menjaga penempatan asli mereka.';
	@override String get anchorToScreen => 'Anchor untuk layar';
	@override String get anchorToScreenDescription => 'Tunjukkan subtitle teks di bar hitam di bawah video layar lebar';
	@override String get bold => 'Tebal';
	@override String get italic => 'Italia';
	@override String get renderResolution => 'Resolusi Render';
	@override String get renderResolutionScreen => 'Resolusi Layar';
	@override String get renderResolutionVideo => 'Resolusi Video';
	@override String get fontSizeDescription => 'Tetapkan ukuran subtitle teks pada perangkat ini.';
	@override String get textColorDescription => 'Pilih warna yang digunakan untuk subtitle teks.';
	@override String get borderSizeDescription => 'Tetapkan ketebalan outline di sekitar subtitle teks.';
	@override String get borderColorDescription => 'Pilih warna yang digunakan untuk subtitle outline.';
	@override String get backgroundColorDescription => 'Pilih warna di belakang subtitle.';
	@override String get backgroundOpacityDescription => 'Tetapkan betapa transparan latar belakang subtitle: 0% jelas dan 100% solid.';
	@override String get positionDescription => 'Pergerakan subtitle secara vertikal. 0% adalah bagian atas video dan 100% adalah bagian bawah.';
	@override String get assOverrideDescription => 'Pilih apakah pemain mengikuti, menyesuaikan, mengganti, atau menghapus gaya yang tertanam dalam subtitle ASS.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$id assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$id._(_root);
	@override String get renderResolutionDescription => 'Pilih resolusi yang digunakan untuk rasterize gambar dan subtitle ASS. Skala Android yang lebih rendah dapat mengurangi kerja rendering tetapi terlihat lebih lembut.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$id renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$id._(_root);
	@override String get boldDescription => 'Cetak subtitle teks dalam berat yang lebih berat.';
	@override String get italicDescription => 'Menarik subtitle teks dalam bahasa Italia.';
}

// Path: mpvConfig
class _Translations$mpvConfig$id extends Translations$mpvConfig$en {
	_Translations$mpvConfig$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Pengaturan pemutar video lanjutan';
	@override String get presets => 'Preset';
	@override String get noPresets => 'Tidak ada preset yang terselamat';
	@override String get saveAsPreset => 'Menyelamatkan sebagai preset.';
	@override String get presetName => 'Nama Praset';
	@override String get presetNameHint => 'Masukkan nama untuk preset ini';
	@override String get loadPreset => 'beban';
	@override String get deletePreset => 'Hapus';
	@override String get presetSaved => 'Preset diselamatkan';
	@override String get presetLoaded => 'Preset yang diisi';
	@override String get presetDeleted => 'Preset dihapus';
	@override String get confirmDeletePreset => 'Apakah Anda yakin Anda ingin menghapus preset ini?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # komentar';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Tambahkan garis';
	@override String get removeLine => 'Menghapus garis';
	@override String get embeddedVoHint => 'vo, gpu-kontekst dan gpu-api diabaikan pada Linux: video tertanam selalu mengalir melalui vo=libmpv pada pesawat video, dan gpu-next (yang komputasi bayangan seperti ArtCNN perlu) tidak dapat berjalan tertanam.';
}

// Path: dialog
class _Translations$dialog$id extends Translations$dialog$en {
	_Translations$dialog$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Mengkonfirmasi Tindakan';
}

// Path: profiles
class _Translations$profiles$id extends Translations$profiles$en {
	_Translations$profiles$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Tambahkan profil PlezyNG';
	@override String get switchingProfile => 'Mengganti profil...';
	@override String get deleteThisProfileTitle => 'Menghapus profil ini?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Menghapus ${displayName}. sambungan tidak terganggu.';
	@override String get active => 'aktif';
	@override String get manage => 'Manajemen';
	@override String get delete => 'Hapus';
	@override String get signOut => 'Sign out';
	@override String get signOutPlexTitle => 'Mendaftar keluar dari Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Menghapus ${displayName} dan semua Plex Pengguna Rumah?';
	@override String get signOutPlexDeleteDownloads => 'Juga menghapus download';
	@override String get signOutPlexDeleteDownloadsDescription => 'Jika tidak, unduhan tetap disimpan di perangkat ini dan tersedia lagi saat Anda masuk kembali ke akun ini.';
	@override String get signedOutPlex => 'Ditandatangani dari Plex.';
	@override String get signOutFailed => 'Menandatangani gagal';
	@override String get sectionTitle => 'Profil';
	@override String get summarySingle => 'Menambahkan profil untuk mencampur pengguna yang dikelola dan identitas lokal';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profil · aktif: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} Profil';
	@override String get removeConnectionTitle => 'Menghapus koneksi?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Menghapus akses ${displayName} ke ${connectionLabel}. profil lainnya menyimpannya.';
	@override String get deleteProfileTitle => 'Menghapus profil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Menghapus ${displayName} dan koneksi. server tetap tersedia.';
	@override String get profileNameLabel => 'Nama Profil';
	@override String get pinProtectionLabel => 'Perlindungan PIN';
	@override String get copyAutomationLink => 'Kopi Android link otomatisasi';
	@override String get copyAutomationLinkDescription => 'Pilih profil ini dari tujuan atau otomatisasi Android. verifikasi PIN profil masih berlaku.';
	@override String get automationLinkCopied => 'Profil otomatis link disalin.';
	@override String get pinManagedByPlex => 'PIN yang dikelola oleh Plex. Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'Tidak ada set PIN. Untuk meminta satu, mengedit pengguna rumah di plex.tv.';
	@override String get setPin => 'Mengatur PIN';
	@override String get setPinTitle => 'Mengatur PIN';
	@override String get confirmPinTitle => 'Mengkonfirmasi PIN';
	@override String get pinSet => 'PIN Set';
	@override String get changePin => 'Perubahan';
	@override String get removePin => 'Hapus';
	@override String get connectionsLabel => 'Hubungan';
	@override String get add => 'Tambah';
	@override String get deleteProfileButton => 'Menghapus profil';
	@override String get noConnectionsHint => 'Tidak ada koneksi — tambahkan satu untuk menggunakan profil ini.';
	@override String get noConnections => 'Tidak ada koneksi';
	@override String get plexHomeAccount => 'Plex Akun Rumah';
	@override String plexAccountChip({required Object account}) => 'Plex Akun: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} melalui ${account}';
	@override String get connectionDefault => 'Bawaan';
	@override String connectionAs({required Object displayName}) => 'Jumlah : ${displayName}';
	@override String get makeDefault => 'Membuat default';
	@override String get removeConnection => 'Hapus';
	@override String get profileRenamed => 'Profil yang disebutkan kembali.';
	@override String borrowAddTo({required Object displayName}) => 'Tambahkan ke ${displayName}';
	@override String get borrowExplain => 'Pinjam koneksi profil lain. profil yang dilindungi PIN membutuhkan PIN.';
	@override String get borrowEmpty => 'Belum ada yang bisa dipinjam.';
	@override String get borrowEmptySubtitle => 'Sambungkan Plex, Jellyfin, atau Emby ke profil lain terlebih dahulu.';
	@override String get borrowLoadFailed => 'Koneksi yang tersedia tidak dapat dimuat. coba lagi.';
	@override String borrowFromProfile({required Object displayName}) => 'dari ${displayName}';
	@override String get borrowConnectionBorrowed => 'Hubungan yang dipinjam.';
	@override String get borrowFailed => 'Tidak berhasil meminjam link.';
	@override String get incorrectPin => 'PIN yang tidak benar.';
	@override String get incorrectPinTryAgain => 'PIN yang salah, silakan coba lagi.';
	@override String get sourceProfileMissingParentAccount => 'Profil sumber hilang akun ibu.';
	@override String get failedToLoadHomeUsers => 'Tidak bisa memuat pengguna rumah Plex Anda. periksa koneksi Anda dan coba lagi.';
	@override String get failedToVerifyPin => 'Tidak dapat mengkonfirmasi PIN.';
	@override String get newProfile => 'Profil baru';
	@override String get profileNameHint => 'Misalnya, tamu, anak-anak, kamar keluarga';
	@override String get pinProtectionOptional => 'Perlindungan PIN (Optional)';
	@override String get pinExplain => 'PIN 4 digit diperlukan untuk menukar profil.';
	@override String get continueButton => 'Selanjutnya';
	@override String get pinsDontMatch => 'PIN tidak cocok';
	@override String get tokenIdentityMismatch => 'Token profil Plex diselesaikan ke server yang tidak dijangka';
	@override String get settingsLocked => 'Seting disekat untuk profil ini.';
	@override String get unlockSettings => 'Unlock pengaturan';
	@override String get showExploreForProfile => 'Tunjukkan eksplorasi untuk profil ini';
	@override String get showExploreForProfileDescription => 'Berhenti untuk menghapus Explore dari navigasi profil ini.';
}

// Path: connections
class _Translations$connections$id extends Translations$connections$en {
	_Translations$connections$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Hubungan';
	@override String get addConnection => 'Tambahkan koneksi';
	@override String get addConnectionSubtitleNoProfile => 'Mendaftar dengan Plex atau menghubungkan server Jellyfin atau Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Tambahkan ke ${displayName}: Plex, Jellyfin, Emby, atau koneksi profil lainnya';
	@override String sessionExpiredOne({required Object name}) => 'Sesi berakhir untuk ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sesi berakhir untuk server ${count}';
	@override String accessDeniedOne({required Object name}) => '${name} menolak akses ke akun ini';
	@override String accessDeniedMany({required Object count}) => '${count} server menolak akses untuk akun ini';
	@override String get signInAgain => 'Menandatangani lagi';
	@override String editMediaBrowserTitle({required Object product}) => 'Mengedit ${product} koneksi';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Menambahkan atau menghapus URL untuk ${serverName}. PlezyNG akan menggunakan URL yang dapat diakses dengan latensi terendah.';
}

// Path: accountPreferences
class _Translations$accountPreferences$id extends Translations$accountPreferences$en {
	_Translations$accountPreferences$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Keutamaan Akun';
	@override String hubSubtitleSingle({required Object account}) => 'Audio, subtitle, dan pilihan perpustakaan disimpan pada ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Audio, subtitle, dan pilihan perpustakaan disimpan pada ${count} akun';
	@override String get pickAccount => 'Setiap akun menyimpan preferensi tersendiri. pilih satu untuk mengedit.';
	@override String get storedOnAccount => 'Opsi ini disimpan di akun itu sendiri, sehingga setiap aplikasi yang terdaftar di dalamnya menggunakannya — termasuk PlezyNG pada perangkat lain Anda.';
	@override String get noAccounts => 'Tidak ada akun yang dapat dikonfigurasi';
	@override String get noAccountsHint => 'Mendaftar di Plex, atau terhubung ke server Jellyfin atau Emby, dan preferensi yang disimpan di akun tersebut ditampilkan di sini.';
	@override String get unavailable => 'Tidak dapat mengakses akun ini';
	@override String get loadFailed => 'Tidak bisa mengisi preferensi ini';
	@override String get noPreference => 'Tidak ada preferensi';
	@override String get notSet => 'Tidak menetapkan';
	@override late final _Translations$accountPreferences$groups$id groups = _Translations$accountPreferences$groups$id._(_root);
	@override String get preferredAudioLanguage => 'Bahasa audio yang disukai';
	@override String get autoSelectAudio => 'Memilih Audio dengan Bahasa';
	@override String get autoSelectAudioDescription => 'Menghapus apa pun audio track file mark sebagai default.';
	@override String get preferredSubtitleLanguage => 'Bahasa teks yang diinginkan';
	@override String get subtitleMode => 'Mengalihkan subtitle ke';
	@override late final _Translations$accountPreferences$subtitleModes$id subtitleModes = _Translations$accountPreferences$subtitleModes$id._(_root);
	@override String get subtitleAccessibility => 'SDH subtitle';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$id subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$id._(_root);
	@override String get forcedSubtitles => 'Subtitle yang dipaksa';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$id forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$id._(_root);
	@override String get displayMissingEpisodes => 'Menampilkan episode yang hilang';
	@override String get displayMissingEpisodesDescription => 'Daftar episode yang server tahu tentang tetapi tidak memiliki file untuk.';
	@override String get hidePlayedInLatest => 'Temukan item yang ditonton di terbaru';
	@override String get hidePlayedInLatestDescription => 'Tinggalkan item yang sudah Anda lihat dari baris terbaru server.';
	@override String get displayCollectionsView => 'Tampilkan Koleksi View';
	@override String get displayCollectionsViewDescription => 'Tawarkan tampilan Koleksi server di samping perpustakaan Anda.';
	@override String get rewatchingInNextUp => 'Tinggalkan persembahan di Next Up';
	@override String get rewatchingInNextUpDescription => 'Setelah Anda menyelesaikan sebuah acara, mulai lagi dan Next Up mengikuti rewatch bukannya menurunkan acara.';
	@override String get watchedIndicator => 'Indikator yang diperhatikan';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$id watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$id._(_root);
	@override String get mediaReviewsVisibility => 'Rating & Ulasan';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$id mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$id._(_root);
	@override String get preferredAudioLanguageDescription => 'Anda lebih suka track audio dalam bahasa ini ketika server atau pemain secara otomatis memilih track.';
	@override String get preferredSubtitleLanguageDescription => 'Lebih baik mengikuti subtitle dalam bahasa ini ketika subtitle dipilih secara otomatis.';
	@override String get subtitleAccessibilityDescription => 'Pilih apakah capsi SDH disukai atau diperlukan selama pemilihan subtitle otomatis.';
	@override String get forcedSubtitleDescription => 'Pilih apakah jalur subtitle paksa disukai atau diperlukan selama pemilihan otomatis.';
	@override String get watchedIndicatorDescription => 'Pilih jenis media yang menerima tanda kontrol yang ditonton di antara muka server.';
	@override String get mediaReviewsVisibilityDescription => 'Pilih penonton dan kritikan mana yang ditampilkan oleh server di halaman media.';
	@override String get subtitleModeDescription => 'Pilih kapan subtitle secara otomatis dimulai untuk akun server ini.';
	@override String get hubDescription => 'Keutamaan ini disimpan di akun media-server Anda dan mungkin berlaku untuk klien lain juga.';
}

// Path: discover
class _Translations$discover$id extends Translations$discover$en {
	_Translations$discover$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Temukan';
	@override String get noContentAvailable => 'Tidak ada konten yang tersedia';
	@override String get addMediaToLibraries => 'Tambahkan beberapa media ke perpustakaan Anda';
	@override String get continueWatching => 'Lanjutkan menonton';
	@override String continueWatchingIn({required Object library}) => 'Lihat lagi reviu untuk ${library}';
	@override String get nextUp => 'Selanjutnya';
	@override String nextUpIn({required Object library}) => 'Berikutnya di ${library}';
	@override String get recentlyAdded => 'Terbaru';
	@override String recentlyAddedIn({required Object library}) => 'Baru-baru ini ditambahkan di ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Album terbaru di ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Dimainkan di ${library}';
	@override String mostPlayedIn({required Object library}) => 'Paling banyak dimainkan di ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Tinjauan';
	@override String get cast => 'Tembak';
	@override late final _Translations$discover$findNext$id findNext = _Translations$discover$findNext$id._(_root);
	@override String get extras => 'Trailer dan Ekstras';
	@override String get studio => 'Studio yang';
	@override String get rating => 'Peringkat';
	@override String get director => 'Direktur';
	@override String get directors => 'Direktur';
	@override String get movie => 'Film';
	@override String get tvShow => 'televisi show';
	@override String minutesLeft({required Object minutes}) => '${minutes} min dibatasi';
	@override String get moreLikeThis => 'Lainnya Seperti Ini';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} judul',
	);
	@override late final _Translations$discover$person$id person = _Translations$discover$person$id._(_root);
}

// Path: errors
class _Translations$errors$id extends Translations$errors$en {
	_Translations$errors$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Pencarian gagal: ${error}';
	@override String get searchUnavailable => 'Pencarian tidak dapat mencapai server media apapun.';
	@override String connectionTimeout({required Object context}) => 'Menghubungkan timeout saat muat ${context}';
	@override String get connectionFailed => 'Tidak dapat terhubung ke server media';
	@override String unableToLoad({required Object context}) => 'Tidak dapat mengisi ${context}. silakan coba lagi.';
	@override String get noClientAvailable => 'Tidak ada klien yang tersedia';
	@override String get pleaseEnterToken => 'Silakan masukkan token';
	@override String get invalidToken => 'Token tidak valid';
	@override String failedToVerifyToken({required Object error}) => 'Tidak dapat mengkonfirmasi token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Tidak dapat beralih ke ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Tidak dapat dihapus ${displayName}';
	@override String get failedToRate => 'Tidak bisa update rating';
	@override String get reasonTimedOut => 'Koneksi yang ditempuh';
	@override String get reasonUnreachable => 'Server tidak dapat diakses';
	@override String get reasonRefused => 'Server menolak permintaan';
	@override String get reasonNotFound => 'Item ini tidak lagi di server';
	@override String get reasonServerError => 'Server melaporkan kesalahan';
	@override String get reasonCancelled => 'Permintaan ini dibatalkan';
	@override String get reasonUnexpected => 'Salah yang tak terduga terjadi';
}

// Path: libraries
class _Translations$libraries$id extends Translations$libraries$en {
	_Translations$libraries$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Mainkan film yang rahasia';
	@override String get randomPickFailed => 'Tidak bisa memilih film rawak dari perpustakaan ini.';
	@override String get title => 'Pustaka';
	@override String get fallbackTitle => 'Pustaka';
	@override String get scanLibraryFiles => 'Perpustakaan file scan';
	@override String get scanLibrary => 'Pindai pustaka';
	@override String get analyze => 'Analisis';
	@override String get analyzeLibrary => 'Analisis Perpustakaan';
	@override String get refreshMetadata => 'Segarkan metadata';
	@override String get emptyTrash => 'Tembusan kosong';
	@override String emptyingTrash({required Object title}) => 'Menghilangkan sampah untuk "${title}..."';
	@override String trashEmptied({required Object title}) => 'Langkah-langkah untuk "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Kegagalan untuk membuang sampah kosong: ${error}';
	@override String analyzing({required Object title}) => 'Berdasarkan analisis “${title}”';
	@override String analysisStarted({required Object title}) => 'Analisis dimulai untuk "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Tidak berhasil menganalisis perpustakaan: ${error}';
	@override String get noLibrariesFound => 'Tidak ditemukan perpustakaan';
	@override String get allLibrariesHidden => 'Semua perpustakaan tersembunyi';
	@override String hiddenLibrariesCount({required Object count}) => 'Perpustakaan Tersembunyi (${count})';
	@override String get thisLibraryIsEmpty => 'Perpustakaan ini kosong';
	@override String get noItemsMatchFilters => 'Tidak ada item yang sesuai dengan filter aktif';
	@override String get resetFilters => 'Reset filter';
	@override String get all => 'Semua';
	@override String get clearAll => 'jelas semua';
	@override String scanLibraryConfirm({required Object title}) => 'Apakah Anda yakin Anda ingin memindai "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Apakah Anda yakin Anda ingin menganalisis "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Apakah Anda yakin ingin memperbarui metadata untuk "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Apakah Anda yakin Anda ingin mengosongkan sampah untuk "${title}"?';
	@override String get manageLibraries => 'Manajemen Perpustakaan';
	@override String get sort => 'Menyortir';
	@override String get sortBy => 'Sortir dengan';
	@override String get filters => 'Filter';
	@override String get confirmActionMessage => 'Apakah Anda yakin Anda ingin melakukan tindakan ini?';
	@override String get showLibrary => 'Tampilkan perpustakaan';
	@override String get hideLibrary => 'Perpustakaan tersembunyi';
	@override String get libraryOptions => 'Pilihan perpustakaan';
	@override String get content => 'Perpustakaan konten';
	@override String get selectLibrary => 'Pilih perpustakaan';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Tidak ada rekomendasi tersedia';
	@override String get noCollections => 'Tidak ada koleksi di perpustakaan ini';
	@override String get noFoldersFound => 'Tidak ditemukan folder';
	@override String get folders => 'Folder';
	@override late final _Translations$libraries$tabs$id tabs = _Translations$libraries$tabs$id._(_root);
	@override late final _Translations$libraries$groupings$id groupings = _Translations$libraries$groupings$id._(_root);
	@override late final _Translations$libraries$filterCategories$id filterCategories = _Translations$libraries$filterCategories$id._(_root);
	@override late final _Translations$libraries$sortLabels$id sortLabels = _Translations$libraries$sortLabels$id._(_root);
	@override late final _Translations$libraries$advancedFilters$id advancedFilters = _Translations$libraries$advancedFilters$id._(_root);
	@override late final _Translations$libraries$selection$id selection = _Translations$libraries$selection$id._(_root);
}

// Path: about
class _Translations$about$id extends Translations$about$en {
	_Translations$about$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tentang';
	@override String get openSourceLicenses => 'Lisensi sumber terbuka';
	@override String versionLabel({required Object version}) => 'Versi ${version}';
	@override String get appDescription => 'Pelanggan yang indah Plex, Jellyfin, dan Emby untuk Flutter';
	@override String get viewLicensesDescription => 'Lihat lisensi perpustakaan pihak ketiga';
	@override String get privacyPolicy => 'Kebijakan Privasi';
}

// Path: serverSelection
class _Translations$serverSelection$id extends Translations$serverSelection$en {
	_Translations$serverSelection$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Tidak ada server yang ditemukan untuk ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Server yang gagal dimuat: ${error}';
	@override String get noValidServers => 'Tidak ada server yang dapat digunakan di akun ini';
}

// Path: hubDetail
class _Translations$hubDetail$id extends Translations$hubDetail$en {
	_Translations$hubDetail$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Judul';
	@override String get releaseYear => 'Tahun Pembebasan';
	@override String get dateAdded => 'Tanggal ditambahkan';
	@override String get rating => 'Peringkat';
	@override String get noItemsFound => 'Tidak ada item ditemukan';
}

// Path: logs
class _Translations$logs$id extends Translations$logs$en {
	_Translations$logs$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Log yang jelas';
	@override String get copyLogs => 'Kopi Log';
	@override String get uploadLogs => 'Mengunggah Logs';
	@override String get saveLogs => 'Simpan log ke file';
	@override String logsSaved({required Object path}) => 'Daftar yang disimpan di ${path}';
	@override String get saveLogsFailed => 'Tidak bisa menyimpan file log.';
}

// Path: detail
class _Translations$detail$id extends Translations$detail$en {
	_Translations$detail$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Berakhir di ${time}';
}

// Path: startup
class _Translations$startup$id extends Translations$startup$en {
	_Translations$startup$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG tidak bisa memulai';
	@override String get failedBody => 'Ada sesuatu yang salah selama startup. detail di bawah ini mengidentifikasi apa yang gagal.';
	@override String get failedBodyRepairable => 'Berkas pengaturan PlezyNG yang tersimpan rusak dan harus dibuat ulang sebelum aplikasi dapat dimulai. Mencoba lagi tidak akan membantu — pilih Perbaiki penyimpanan.';
	@override String get phaseLabel => 'Langkah';
	@override String get showDetails => 'Tunjukkan detail';
	@override String get hideDetails => 'Temukan detail';
	@override String get copyDetails => 'Copy detail';
	@override String get detailsCopied => 'Detail yang disalin ke clipboard';
	@override String get uploadDetails => 'Upload Detail';
	@override String get repairStorage => 'Perbaikan Penyimpanan';
	@override String get repairTitle => 'Membaiki data yang disimpan?';
	@override String get repairBodyCommon => 'file pengaturan PlezyNG rusak dan tidak dapat dibaca. perbaikan mengatur kembali setiap pengaturan ke defaultnya.';
	@override String get repairBodyOneCredential => 'Satu login yang disimpan rosak dan tidak dapat dibaca. pembaikan menghapus hanya satu; seting lain Anda ditinggalkan sendirian.';
	@override String get repairBodySignInsKept => 'Sesi masuk ke server dan profil Anda seharusnya tetap aktif.';
	@override String get repairBodySignInsLost => 'Kunci yang melindungi data masuk tersimpan tidak dapat dipulihkan dari berkas ini. Anda harus masuk lagi ke setiap server dan profil. Tidak ada yang berubah di server media Anda.';
	@override String get repairBodySessionsUncertain => 'Data pelacak (MAL, AniList, Simkl, Trakt) dan Seerr disimpan terpisah dan mungkin tetap tersimpan atau hilang. PlezyNG akan memberi tahu dengan tepat data yang dipertahankan.';
	@override String get repairConfirm => 'Perbaikan';
	@override String get repairSucceeded => 'Penyimpanan diperbaiki';
	@override String get repairNeedsRestart => 'Penyimpanan diperbaiki - perlu memulai kembali';
	@override String get restartRequiredBody => 'Data Anda telah diperbaiki, tetapi PlezyNG harus dimulai ulang sebelum dapat menggunakannya. Tutup PlezyNG lalu buka kembali.';
	@override String get quitPlezy => 'Berdasarkan PlezyNG';
	@override String get repairFailed => 'Perbaikan gagal';
	@override String get repairKeptSignIns => 'Sesi masuk ke server dan profil Anda masih aktif.';
	@override String get repairLostSignIns => 'Kunci melindungi sign-ins yang disimpan Anda tidak dapat dipulihkan. Anda akan perlu mendaftar masuk ke setiap server dan profil lagi.';
	@override String get repairLostSessions => 'Sekurang-kurangnya satu tracker atau koneksi Seerr telah hilang dan harus dihubungkan kembali.';
	@override String get backupTitle => 'Satu salinan file yang rusak disimpan';
	@override String get backupWarning => 'Salinan ini berisi informasi masuk Anda. Jangan unggah atau bagikan.';
	@override String get deleteBackup => 'Menghapus Kopi';
	@override String get backupDeleted => 'Kopi yang dihapus.';
	@override String get previousFailureTitle => 'PlezyNG gagal memulai kali terakhir';
}

// Path: licenses
class _Translations$licenses$id extends Translations$licenses$en {
	_Translations$licenses$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Paket terkait';
	@override String get license => 'Lisensi';
	@override String licenseNumber({required Object number}) => 'Lisensi ${number}';
	@override String licensesCount({required Object count}) => '${count} Lisensi';
}

// Path: navigation
class _Translations$navigation$id extends Translations$navigation$en {
	_Translations$navigation$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Pustaka';
	@override String get downloads => 'Unduhan';
	@override String get liveTv => 'TV Langsung';
	@override String get explore => 'eksplorasi';
}

// Path: explore
class _Translations$explore$id extends Translations$explore$en {
	_Translations$explore$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$id mdblistShelves = _Translations$explore$mdblistShelves$id._(_root);
	@override String get title => 'eksplorasi';
	@override String get selectSource => 'Pilih sumber';
	@override late final _Translations$explore$rows$id rows = _Translations$explore$rows$id._(_root);
	@override late final _Translations$explore$status$id status = _Translations$explore$status$id._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode',
	);
	@override String get cast => 'Tembak';
	@override String get characters => 'Karakter yang';
	@override String get addToWatchlist => 'Tambahkan ke Watchlist';
	@override String get removeFromWatchlist => 'Menghapus dari Watchlist';
	@override String get addedToWatchlist => 'Ditambahkan ke watchlist';
	@override String get removedFromWatchlist => 'Menghapus dari watchlist';
	@override String get watchlistUpdateFailed => 'Tidak bisa update watchlist';
	@override String get watchlistNoMatch => 'Tidak bisa menyesuaikan item ini dengan daftar pengawas';
	@override String get notInLibrary => 'Tidak di perpustakaan Anda';
	@override String get inTheseLibraries => 'Di perpustakaan ini';
	@override String get checkingLibrary => 'Memeriksa perpustakaan Anda.';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: 'Tidak dapat memeriksa server ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
	);
	@override String get emptyTitle => 'Belum ada yang di sini';
	@override String emptyMessage({required Object source}) => 'Roda dari ${source} akan muncul di sini setelah mereka memiliki konten.';
	@override String searchHint({required Object source}) => 'Pencarian ${source}';
	@override String searchEmpty({required Object query}) => 'Tidak ada hasil untuk "${query}"';
	@override String searchPrompt({required Object source}) => 'Cari film dan acara di ${source}.';
	@override String get searchFailed => 'Pencarian gagal. periksa koneksi Anda dan coba lagi.';
	@override late final _Translations$explore$badge$id badge = _Translations$explore$badge$id._(_root);
	@override late final _Translations$explore$stats$id stats = _Translations$explore$stats$id._(_root);
	@override late final _Translations$explore$season$id season = _Translations$explore$season$id._(_root);
	@override late final _Translations$explore$format$id format = _Translations$explore$format$id._(_root);
	@override late final _Translations$explore$sourceMaterial$id sourceMaterial = _Translations$explore$sourceMaterial$id._(_root);
	@override late final _Translations$explore$creditRole$id creditRole = _Translations$explore$creditRole$id._(_root);
	@override late final _Translations$explore$relation$id relation = _Translations$explore$relation$id._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} di ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} di ${time} ${timezone}';
	@override late final _Translations$explore$detail$id detail = _Translations$explore$detail$id._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hasilnya',
	);
}

// Path: liveTv
class _Translations$liveTv$id extends Translations$liveTv$en {
	_Translations$liveTv$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV Langsung';
	@override String get guide => 'Panduan';
	@override String get noChannels => 'Tidak ada saluran yang tersedia';
	@override String get noDvr => 'Tidak ada DVR yang terkonfigurasi pada server';
	@override String get serverUnavailable => 'Live TV server tidak tersedia.';
	@override String get serverNotConnected => 'Live TV server tidak terhubung.';
	@override String get noPrograms => 'Tidak ada data program yang tersedia';
	@override String get liveStreamFailed => 'Live Stream gagal';
	@override String get unknownProgram => 'Program yang tidak diketahui';
	@override String get timelineLiveProgram => 'Live program (playback mungkin berada di luar program ini)';
	@override String get timelineBuffer => 'Timer Buffer';
	@override String get timelineUnavailable => 'Timeline tidak tersedia';
	@override String get timelineEstimated => 'Berharga tentang playback';
	@override String get timelinePending => 'Menunggu mencari';
	@override String get timelineStale => 'Jadual dapat tertunda';
	@override String get unknownHub => 'Tidak Dikenal';
	@override String get unknownError => 'Kesalahan yang tidak diketahui';
	@override String channelNumber({required Object number}) => 'Saluran ${number}';
	@override String get unknownChannel => 'saluran yang tidak diketahui';
	@override String get live => 'Langsung';
	@override String get premiereBadge => 'Baru';
	@override String get reloadGuide => 'Reload Panduan';
	@override String get searchGuide => 'Panduan Pencarian';
	@override String get searchHint => 'Mencari saluran dan program';
	@override String searchNoResults({required Object query}) => 'Tidak ada pertandingan untuk "${query}"';
	@override String get channelsSection => 'Saluran';
	@override String get programsSection => 'Program';
	@override String get now => 'Sekarang';
	@override String get today => 'Hari ini';
	@override String get tomorrow => 'besok';
	@override String get midnight => 'tengah malam';
	@override String get overnight => 'Malam hari';
	@override String get morning => 'pagi hari';
	@override String get daytime => 'Waktu hari';
	@override String get evening => 'Malam hari';
	@override String get lateNight => 'Malam yang lambat';
	@override String get whatsOn => 'Apa yang ada di';
	@override String get watchChannel => 'Menonton Channel';
	@override String get favorites => 'Favorit';
	@override String get reorderFavorites => 'Kegemaran Reorder';
	@override String get noFavoriteChannels => 'Tidak ada saluran favorit';
	@override String get noFavoriteChannelsHint => 'Tunjukkan semua saluran, kemudian tekan panjang saluran untuk menambahkan ke favorit Anda.';
	@override String get showAllChannels => 'Menampilkan semua saluran';
	@override String get favoritesLoadFailed => 'Anda tidak bisa mengisi favorit. periksa koneksi Anda dan coba lagi.';
	@override String get favoritesUpdateFailed => 'Anda tidak bisa memperbarui favorit Anda. periksa koneksi Anda dan coba lagi.';
	@override String get joinSession => 'Berpartisipasi dalam Sesi';
	@override String watchFromStart({required Object minutes}) => 'Menonton dari awal (${minutes} menit yang lalu)';
	@override String get watchLive => 'Lihat Live';
	@override String get goToLive => 'Pergi untuk Hidup';
	@override String get record => 'Merekam';
	@override String get recordEpisode => 'Rekor episode';
	@override String get recordSeries => 'Seri rekaman';
	@override String get recordOptions => 'Rekor Opsi';
	@override String get saveTo => 'Selamatkan untuk';
	@override String get recordings => 'Rekaman';
	@override String get scheduledRecordings => 'jadwal';
	@override String get recordingRules => 'Peraturan Rekaman';
	@override String get noScheduledRecordings => 'Tidak ada yang direncanakan untuk merekam';
	@override String get manageRecording => 'Atur Rekaman';
	@override String get cancelRecording => 'Batalkan perekaman';
	@override String get cancelRecordingTitle => 'Membatalkan rekaman ini?';
	@override String cancelRecordingMessage({required Object title}) => '${title} tidak akan lagi tercatat.';
	@override String get deleteRule => 'Menghapus aturan';
	@override String get deleteRuleTitle => 'Menghapus aturan rekaman?';
	@override String deleteRuleMessage({required Object title}) => 'Episode mendatang dari ${title} tidak akan direkam.';
	@override String get recordingScheduled => 'Perekaman dijadwalkan.';
	@override String get alreadyScheduled => 'Program ini sudah direncanakan';
	@override String get dvrAdminRequired => 'Pengaturan DVR membutuhkan akun admin';
	@override String get recordingFailed => 'Tidak bisa merancang rekaman';
	@override String get recordingTargetMissing => 'Tidak bisa menentukan rekaman perpustakaan';
	@override String get recordNotAvailable => 'Tidak tersedia untuk program ini';
	@override String get recordingCancelled => 'Rekaman dibatalkan';
	@override String get recordingRuleDeleted => 'Peraturan rekaman dihapus';
	@override String get processRecordingRules => 'Menilai kembali aturan';
	@override String get recordingInProgress => 'Rekaman sekarang';
	@override String recordingsCount({required Object count}) => '${count} diatur';
	@override String get editRule => 'Edit Peraturan';
	@override String get editRuleAction => 'Sunting';
	@override String get recordingRuleUpdated => 'Peraturan rekaman diperbarui';
	@override String get guideReloadRequested => 'Panduan pembaharuan diminta';
	@override String get guideReloadFailed => 'Tidak bisa memperbaharui panduan';
	@override String get rulesProcessRequested => 'Peraturan penilaian ulang yang diminta';
	@override String get rulesProcessFailed => 'Tidak bisa menilai kembali aturan rekaman';
	@override String get recordShow => 'Rekor Show';
	@override late final _Translations$liveTv$recordSettings$id recordSettings = _Translations$liveTv$recordSettings$id._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Mulai dalam ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} pada ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} mengembalikan data live TV playback yang tidak sah';
	@override String get failedToStartChannel => 'Tidak bisa memulai live channel.';
	@override String get failedToBuildStreamUrl => 'Tidak bisa membuat URL streaming';
	@override String playbackStartFailed({required Object reason}) => 'Tidak bisa memulai saluran: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Tidak bisa menukar saluran: ${reason}';
}

// Path: collections
class _Translations$collections$id extends Translations$collections$en {
	_Translations$collections$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Koleksi';
	@override String get collection => 'Koleksi';
	@override String get empty => 'Koleksi itu kosong';
	@override String get deleteCollection => 'Menghapus Koleksi';
	@override String deleteConfirm({required Object title}) => 'Hapus "${title}"? Tindakan ini tidak dapat dibatalkan.';
	@override String get deleted => 'Koleksi dihapus';
	@override String get deleteFailed => 'gagal menghapus koleksi';
	@override String deleteFailedWithError({required Object error}) => 'Tidak berhasil menghapus koleksi: ${error}';
	@override String get selectCollection => 'Seleksi Seleksi';
	@override String get collectionName => 'Nama Koleksi';
	@override String get enterCollectionName => 'Masukkan nama koleksi';
	@override String get addedToCollection => 'Ditambahkan ke Koleksi';
	@override String get errorAddingToCollection => 'gagal menambahkan ke koleksi';
	@override String get created => 'Koleksi yang diciptakan';
	@override String get removeFromCollection => 'Hapus dari koleksi';
	@override String removeFromCollectionConfirm({required Object title}) => 'Hapus “${title}” dari koleksi ini?';
	@override String get removedFromCollection => 'Menghapus dari Koleksi';
	@override String get removeFromCollectionFailed => 'Tidak berhasil keluar dari koleksi';
	@override String removeFromCollectionError({required Object error}) => 'Kesalahan penghapusan dari koleksi: ${error}';
	@override String get searchCollections => 'Koleksi pencarian...';
}

// Path: playlists
class _Translations$playlists$id extends Translations$playlists$en {
	_Translations$playlists$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Daftar putar';
	@override String get playlist => 'Daftar Putar';
	@override String get noPlaylists => 'Tidak ditemukan playlist';
	@override String get create => 'Membuat Playlist';
	@override String get playlistName => 'Nama Playlist';
	@override String get enterPlaylistName => 'Masukkan nama playlist';
	@override String get delete => 'Menghapus Playlist';
	@override String get removeItem => 'Hapus dari daftar putar';
	@override String get smartPlaylist => 'Daftar Pemain Pintar';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item',
	);
	@override String get emptyPlaylist => 'Playlist ini kosong';
	@override String get deleteConfirm => 'Menghapus Playlist?';
	@override String deleteMessage({required Object name}) => 'Apakah Anda yakin Anda ingin menghapus "${name}"?';
	@override String get created => 'Playlist yang diciptakan';
	@override String get deleted => 'Playlist dihapus';
	@override String get itemAdded => 'Ditambahkan ke playlist';
	@override String get itemRemoved => 'Menghapus dari playlist';
	@override String get selectPlaylist => 'Pilih Playlist';
	@override String get searchPlaylists => 'Mencari playlist...';
	@override String get errorCreating => 'gagal membuat playlist';
	@override String get errorDeleting => 'Tidak berhasil menghapus playlist';
	@override String get errorLoading => 'gagal mengisi playlists';
	@override String get errorAdding => 'gagal menambahkan ke playlist';
	@override String get errorReordering => 'gagal mengatur ulang item playlist';
	@override String get errorRemoving => 'Tidak berhasil keluar dari playlist';
}

// Path: music
class _Translations$music$id extends Translations$music$en {
	_Translations$music$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Pergi ke album';
	@override String get goToArtist => 'Pergi ke artis';
	@override String get instantMix => 'Mix Instan';
	@override String get playNext => 'Mainkan selanjutnya';
	@override String get addToQueue => 'Tambahkan ke kue';
	@override String discNumber({required Object n}) => 'Disk ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} jalur',
	);
	@override String get nowPlaying => 'Sekarang Bermain';
	@override String playingFrom({required Object title}) => 'Bermain dari ${title}';
	@override String get queue => 'Keuangan';
	@override String get clearQueue => 'Hapus antrian';
	@override String get lyrics => 'Lirik';
	@override String get visualizer => 'Visualisasi';
	@override String get visualizerProfileLoading => 'Membaca Track Analysis';
	@override String get visualizerAmbientMotion => 'Pergerakan Lingkungan';
	@override String get visualizerPlexLoudness => 'Plex suara';
	@override String get visualizerPreviousPreset => 'Gaya visual sebelumnya';
	@override String get visualizerNextPreset => 'Seterusnya Visual Style';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Bloom yang';
	@override String get visualizerPresetOrbitals => 'Orbitasi';
	@override String get visualizerPresetPrism => 'Prisme';
	@override String get visualizerPresetTunnel => 'terowongan';
	@override String get visualizerPresetTrackMap => 'Peta Track';
	@override String get noLyrics => 'Tidak ada lyrics tersedia';
	@override String get sleepTimer => 'Waktu Tidur';
	@override String get sleepTimerEndOfTrack => 'Akhir dari trek';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menit',
	);
	@override String get stopPlayback => 'Hentikan pemutaran';
	@override String get previousTrack => 'Lagu sebelumnya';
	@override String get nextTrack => 'Lagu berikutnya';
	@override String get repeat => 'Ulangi';
	@override String get repeatAll => 'Ulang semua';
	@override String get repeatOne => 'Ulangi Sekali';
	@override String get instantMixNoServer => 'Tidak ada server yang tersedia untuk campuran instan';
	@override String get instantMixFailed => 'Tidak berhasil mengisi mix instant';
	@override String get instantMixEmpty => 'Tombol ini kembali tanpa jejak.';
	@override String noAudioUrl({required Object track}) => 'Tidak ada URL audio yang tersedia untuk ${track}';
	@override late final _Translations$music$discography$id discography = _Translations$music$discography$id._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$id extends Translations$watchTogether$en {
	_Translations$watchTogether$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tonton Bersama';
	@override String get description => 'Menonton konten dalam sinergitas dengan teman dan keluarga';
	@override String get createRoom => 'Membuat ruangan';
	@override String get creatingRoom => 'Membangun ruangan...';
	@override String get joinRoom => 'Bergabunglah dengan ruangan';
	@override String get joiningRoom => 'Untuk menyertai ruangan...';
	@override String get connecting => 'Menghubungkan...';
	@override String get relayPublic => 'Ruang-ruang yang digunakan oleh publik Open Watch Party.';
	@override String relayCustom({required Object url}) => 'Kamar menggunakan relay Anda di ${url}.';
	@override String get recentRooms => 'Ruang Baru';
	@override String get roomActions => 'Ruang Aksi';
	@override String get renameRoom => 'Ruang Rename';
	@override String get removeRoom => 'Hapus';
	@override String get enterRoomCode => 'Masukkan kode 6 karakter dari host.';
	@override String get roomCode => 'Kode kamar';
	@override String get paste => 'Tempel';
	@override String get noCodeInClipboard => 'Clipboard tidak mengandung kode kamar';
	@override String get copyCode => 'Kopi kode';
	@override String get codeCopied => 'Kode kamar disalin';
	@override String get shareInvite => 'Membagi Jemputan';
	@override String get inviteCopied => 'Tuliskan pesan, masukkan ke dalam pesan.';
	@override String inviteMessage({required Object code}) => 'Bergabunglah dengan Watch bersama saya di PlezyNG: buka Watch bersama, pilih Join Room dan masukkan ${code}.';
	@override String get openSessionControls => 'Open Watch Bersama-sama kontrol sesi';
	@override String get reconnecting => 'Menghubungkan kembali...';
	@override String get reconnectingDescription => 'Koneksi terputus.Anda masuk ke ruangan secara otomatis.';
	@override String get connected => 'terhubung';
	@override String get disconnected => 'terhubung';
	@override String get youAreHost => 'Anda adalah tuan rumah';
	@override String hostedBy({required Object name}) => 'Diposting oleh ${name}';
	@override String get hostControlsPlayback => 'Pengelolaan Playback';
	@override String get anyoneCanControl => 'Siapa pun bisa mengontrol playback.';
	@override String get roomLocked => 'Kamar Tertutup';
	@override String get nowPlaying => 'Sekarang Bermain';
	@override String get nothingPlaying => 'Tidak ada bermain';
	@override String get nothingPlayingHost => 'Mainkan sesuatu dari perpustakaan apa pun untuk membagikannya dengan ruangan.';
	@override String get nothingPlayingGuest => 'Ketika tuan rumah memainkan sesuatu, itu dibuka di sini.';
	@override String get notShareable => 'Video ini tidak memiliki catatan, sehingga hanya orang dengan akses ke server yang sama dapat memainkannya.';
	@override String get searching => 'Mencari video ini di perpustakaan Anda...';
	@override String get yourCopy => 'Kopi Anda';
	@override String get sharingYourCopy => 'Anda berbagi salinan Anda';
	@override String playingOtherLength({required Object difference}) => 'Bermain salinan Anda, ${difference}';
	@override String get mismatchTitle => 'Kopi Anda adalah panjang yang berbeda';
	@override String mismatchDescription({required Object difference}) => 'Kopi terdekat Anda adalah ${difference} dari video ruangan. itu bisa menjadi potongan atau versi lain.';
	@override String get playAnyway => 'bermain apa pun';
	@override String get chooseAnotherCopy => 'Pilih salinan lain';
	@override String get dontPlay => 'Jangan Bermain';
	@override String get unavailableTitle => 'Anda tidak memiliki video ini';
	@override String get unavailableDescription => 'PlezyNG tidak dapat menemukannya di perpustakaan Anda. pilih salinan sendiri atau cari lagi.';
	@override String get chooseCopy => 'Pilih salinan';
	@override String get searchAgain => 'Cari lagi';
	@override String get noCandidates => 'Tidak ada salinan yang ditemukan di perpustakaan Anda.';
	@override String get choiceFailed => 'Saya tidak bisa memainkan salinan ini untuk ruangan';
	@override String lengthLonger({required Object duration}) => '${duration} lebih lama';
	@override String lengthShorter({required Object duration}) => '${duration} lebih pendek';
	@override String get lengthSame => 'panjang yang sama';
	@override String get lengthUnknown => 'panjang yang tidak diketahui';
	@override String get joinCurrentPlayback => 'Bergabunglah dengan Playback';
	@override String get joinCurrentPlaybackDescription => 'Kembali ke apa yang sedang ditonton oleh tuan rumah';
	@override String get stopMedia => 'Stop Video untuk Semua Orang';
	@override String get syncOffset => 'Sinkronisasi Offset';
	@override String get syncOffsetDescription => 'Pindah video Anda jika ia berjalan di depan atau di belakang ruangan.';
	@override String offsetHint({required Object difference}) => 'Kopi Anda adalah ${difference} dari video kamar.';
	@override String applyDifference({required Object offset}) => 'Menggunakan ${offset}';
	@override String get offsetMinusSecond => '1 s';
	@override String get offsetMinusTenth => '- 100 ms';
	@override String get offsetPlusTenth => '+ 100 ms';
	@override String get offsetPlusSecond => '+ 1 s';
	@override String get participants => 'peserta';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} peserta',
	);
	@override String get hostBadge => 'tamu';
	@override String nameYou({required Object name}) => '${name} (Anda)';
	@override String get playerIdle => 'Diam';
	@override String get playerLoading => 'Pengisian';
	@override String get playerReady => 'Bersedia';
	@override String get playerBuffering => 'Buffer';
	@override String get matchSearching => 'pencarian';
	@override String get matchMatched => 'memiliki video';
	@override String get matchMismatched => 'panjang yang berbeda';
	@override String get matchUnavailable => 'Tidak ada video';
	@override String participantOffset({required Object offset}) => 'Pengaturan ${offset}';
	@override String get makeHost => 'Membuat host';
	@override String get makeHostQuestion => 'Pengiriman ke host?';
	@override String makeHostConfirm({required Object name}) => '${name} akan mengendalikan playback dan menjalankan sesi untuk semua orang.';
	@override String get transfer => 'Pindahkan';
	@override String get removeParticipant => 'Keluar dari ruangan';
	@override String removeParticipantQuestion({required Object name}) => 'Menghapus ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} meninggalkan ruangan. mereka dapat bergabung lagi dengan kode kecuali Anda menutup ruangan.';
	@override String get remove => 'Hapus';
	@override String get roomSettings => 'Settings ruangan';
	@override String get letEveryoneControl => 'Semua orang bisa bermain playback';
	@override String get lockRoom => 'ruang tertutup';
	@override String get lockRoomDescription => 'Tidak ada yang baru yang bisa bergabung';
	@override String get leaveRoom => 'Tinggalkan Kamar';
	@override String get leaveRoomQuestion => 'Tinggalkan kamar?';
	@override String get leaveRoomConfirm => 'Anda dapat bergabung lagi dengan kode kamar.';
	@override String get leave => 'Tinggal';
	@override String get endRoom => 'Bilik Akhir';
	@override String get endRoomQuestion => 'Bilik akhir ?';
	@override String get endRoomConfirm => 'Ini mengakhiri ruang untuk semua orang.';
	@override String get end => 'Akhirnya';
	@override String get playBlockedTitle => 'Playback tidak dimulai';
	@override String get playBlockedDescription => 'Mainkan permainan untuk mulai menonton dengan ruangan.';
	@override late final _Translations$watchTogether$notices$id notices = _Translations$watchTogether$notices$id._(_root);
	@override late final _Translations$watchTogether$ended$id ended = _Translations$watchTogether$ended$id._(_root);
	@override late final _Translations$watchTogether$errors$id errors = _Translations$watchTogether$errors$id._(_root);
	@override String untitledEpisode({required Object number}) => 'Keterangan ${number}';
}

// Path: downloads
class _Translations$downloads$id extends Translations$downloads$en {
	_Translations$downloads$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Unduhan';
	@override String get manage => 'Manajemen';
	@override String get tvShows => 'Acara TV';
	@override String get movies => 'Film';
	@override String get music => 'Musik';
	@override String tracksQueued({required Object count}) => '${count} track yang diunduh untuk download';
	@override String get noDownloads => 'Belum ada download';
	@override String get noDownloadsDescription => 'Konten yang dimuat turun akan muncul di sini untuk menonton offline';
	@override String get downloadNow => 'Unduh';
	@override String get deleteDownload => 'Menghapus download';
	@override String get retryDownload => 'Kembali ke download';
	@override String get downloadQueued => 'Download Dijadwalkan.';
	@override String get downloadResumed => 'Download kembali';
	@override String get serverErrorBitrate => 'Kesalahan server: file mungkin melebihi batas bitrate remote';
	@override String get storageFull => 'Download berhenti untuk melindungi penyimpanan yang tersedia.Bebaskan beberapa ruang atau pilih lokasi download lain, kemudian retry.';
	@override String get storageUnavailable => 'Download berhenti karena penyimpanan yang tersedia tidak dapat diperiksa. periksa lokasi download, kemudian retry.';
	@override String episodesQueued({required Object count}) => '${count} episode yang dikeluarkan untuk download';
	@override String get downloadDeleted => 'Download dihapus';
	@override String deleteConfirm({required Object title}) => 'Menghapus "${title}" dari perangkat ini?';
	@override String get deleteCollectionDownloads => 'Menghapus Downloads';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Hapus semua unduhan dalam “${title}” dari perangkat ini?';
	@override String get collectionDownloadsDeleted => 'Download yang dihapus';
	@override String get cancelledDownloadTitle => 'Pembatalan Download';
	@override String get cancelledDownloadMessage => 'Download ini dibatalkan. apa yang ingin Anda lakukan?';
	@override String get allEpisodesAlreadyDownloaded => 'Semua episode sudah dimuat turun';
	@override String get resumeDownload => 'Lanjutkan unduhan';
	@override String get cancelledDownload => 'Pembatalan download';
	@override String syncingFile({required Object file, required Object status}) => '${file} (sinkronisasi ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'Dimuat turun ${file} - Klik untuk menyelesaikan';
	@override String get partialDownloadClickToComplete => 'Dilancarkan secara parsial - Klik untuk menyelesaikan';
	@override String get deleting => 'Menghapus...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Menghapus ${title}... (${current} dari ${total})';
	@override String get queuedTooltip => 'Keuangan';
	@override String queuedFilesTooltip({required Object files}) => 'Kemenangan ${files}';
	@override String get downloadingTooltip => 'Mengunduh...';
	@override String downloadingFilesTooltip({required Object files}) => 'Mengunduh ${files}';
	@override String get noDownloadsTree => 'Tidak ada download';
	@override String get pauseAll => 'Beristirahat Semua';
	@override String get resumeAll => 'Resume Semua';
	@override String get retryAll => 'Kembalikan Semua';
	@override String get retryFailed => 'Retry gagal download';
	@override String get deleteAll => 'Hapus Semua';
	@override String get selectVersion => 'Pilih versi';
	@override String get allEpisodes => 'Semua episode';
	@override String get unwatchedOnly => 'Hanya tidak diperhatikan';
	@override String nextNUnwatched({required Object count}) => '${count} tidak diperhatikan';
	@override String get customAmount => 'Jumlah Custom...';
	@override String get customAmountAny => 'Jumlah yang disesuaikan (setiap kali)';
	@override String get randomEpisodes => 'episode rahasia';
	@override String get includeSpecials => 'Termasuk spesial';
	@override String get howManyEpisodes => 'Berapa banyak episode?';
	@override String get invalidEpisodeCount => 'Masukkan jumlah episode yang valid.';
	@override String get keepSynced => 'Tetap Sinkronisasi';
	@override String get downloadOnce => 'Download 1 kali';
	@override String keepNUnwatched({required Object count}) => 'Tinggalkan ${count} tidak dipantau';
	@override String get editSyncRule => 'Mengedit Sink';
	@override String get removeSyncRule => 'Menghapus aturan sinergi';
	@override String removeSyncRuleConfirm({required Object title}) => 'Hentikan sinkronisasi "${title}"? Episode yang telah diunduh akan tetap disimpan.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Berhenti menyinkronkan "${title}"';
	@override String get deleteSyncRuleDownloads => 'Juga menghapus download yang terkait';
	@override String get deleteSyncRuleDownloadsDescription => 'Download yang digunakan oleh aturan sink atau profil lain akan disimpan.';
	@override String syncRuleCreated({required Object count}) => 'Sinkronisasi yang dibuat — menyimpan ${count} episode yang tidak dipantau';
	@override String get syncRuleUpdated => 'Peraturan Sync diperbarui';
	@override String get syncRuleRemoved => 'Peraturan Sync dihapus';
	@override String get syncRuleAndDownloadsRemoved => 'Peraturan Sync dan download terkait dihapus';
	@override String get syncRuleCleanupBusy => 'Peraturan Sync saat ini sedang diperbarui. coba lagi dalam beberapa saat.';
	@override String get syncRuleCleanupUnavailable => 'Menghubungkan kembali server dan mencoba lagi, atau menghapus aturan tanpa menghapus download.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Synced ${count} episode baru untuk ${title}';
	@override String get syncNow => 'Sync sekarang';
	@override String get downloadsUpToDate => 'Downloads sampai saat ini';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync lengkap · ${queued} queued, ${removed} dihapus';
	@override String get activeSyncRules => 'Peraturan Sync';
	@override String get reviewOrphanFiles => 'Download dari Orphaned';
	@override String get orphanReviewTitle => 'Download dari Orphaned';
	@override String get orphanReviewDescription => 'File yang ditandai ini berada dalam folder download yang dikendalikan oleh aplikasi default PlezyNG dan tidak memiliki rekaman download atau tugas aktif yang sepadan.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} file · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Menghapus file ${count}';
	@override String get orphanCleanupNone => 'Tidak ada file download yang ditemukan';
	@override String get orphanCleanupFailed => 'PlezyNG tidak dapat dengan aman memindai folder download yang dikelola.';
	@override String get orphanCleanupChanged => 'Daftar muat turun berubah selama review. ulangi file lagi sebelum membersihkan.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Menghapus ${count} file orphaned · ${size} dikeluarkan';
	@override String get noSyncRules => 'Tidak ada aturan sync';
	@override String get manageSyncRule => 'Manajemen Sync';
	@override String get editEpisodeCount => 'Episode Menghitung';
	@override String get editSyncFilter => 'Filter Sinkronisasi';
	@override String get syncAllItems => 'Sinkronisasi semua item';
	@override String get syncUnwatchedItems => 'Sinkronisasi item yang tidak diperhatikan';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Tersedia';
	@override String get syncRuleOffline => 'Luring';
	@override String get syncRuleSignInRequired => 'Menandatangani yang diperlukan';
	@override String get syncRuleAccessDenied => 'Akses yang ditolak';
	@override String get syncRuleNotAvailableForProfile => 'Tidak tersedia untuk profil saat ini';
	@override String get syncRuleUnknownServer => 'Server yang tidak diketahui';
	@override String get syncRuleListCreated => 'Sinkronisasi yang dibuat';
	@override late final _Translations$downloads$backgroundWarning$id backgroundWarning = _Translations$downloads$backgroundWarning$id._(_root);
	@override String get options => 'Pilihan download';
	@override late final _Translations$downloads$groupings$id groupings = _Translations$downloads$groupings$id._(_root);
	@override String get unknownLibrary => 'Perpustakaan yang tidak diketahui';
	@override String get unknownShow => 'Pameran yang tidak diketahui';
	@override String get unknownSeason => 'Musim yang tidak diketahui';
	@override String get unknownAlbum => 'Album yang tidak diketahui';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} selesai';
	@override String storageUsed({required Object size}) => 'Penyimpanan yang digunakan: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengunduran',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menunjukkan',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
	);
	@override String get errorFileNotFound => 'File yang tidak ditemukan (404)';
	@override String get errorDownloadNotAllowed => 'Download tidak diizinkan oleh server (403)';
	@override String get errorDownloadFailed => 'Download gagal';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Download gagal: ${reason}';
	@override String get convertingOnServer => 'Konversi ke server';
	@override String convertingOnServerPercent({required Object percent}) => 'Konversi pada server · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Download gagal (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Setelah pemrosesan gagal: ${reason}';
	@override String get reasonFileNotSaved => 'File tidak dapat disimpan pada perangkat ini.';
	@override String get reasonCannotResume => 'Download parsial tidak dapat diulang';
	@override String get reasonDeviceStorageFull => 'Perangkat ini tidak disimpan';
	@override String get notificationDownloading => 'Mengunduh...';
	@override String get notificationComplete => 'Download lengkap';
	@override String get notificationPaused => 'Download yang beristirahat';
}

// Path: shaders
class _Translations$shaders$id extends Translations$shaders$en {
	_Translations$shaders$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Tidak ada peningkatan video';
	@override String get nvscalerDescription => 'Skala gambar NVIDIA untuk video yang lebih tajam';
	@override String get artcnnVariantNeutral => 'Neutral';
	@override String get artcnnVariantDenoise => 'Denosiasi';
	@override String get artcnnVariantDenoiseSharpen => 'Kekuatan + Sharpen';
	@override String get qualityFast => 'Cepat';
	@override String get qualityHQ => 'kualitas tinggi';
	@override String get mode => 'Mode';
	@override String get importShader => 'Pengiriman Shader';
	@override String get customShaderDescription => 'Ciri-ciri GSL Shader';
	@override String get shaderImported => 'Shader yang diimpor';
	@override String get shaderImportFailed => 'gagal mengimpor shader';
	@override String get deleteShader => 'Menghapus Shader';
	@override String deleteShaderConfirm({required Object name}) => 'Menghapus “${name}”';
}

// Path: companionRemote
class _Translations$companionRemote$id extends Translations$companionRemote$en {
	_Translations$companionRemote$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Remote Pendamping';
	@override String connectedTo({required Object name}) => 'Menghubungkan ke ${name}';
	@override String get unknownDevice => 'perangkat yang tidak diketahui';
	@override late final _Translations$companionRemote$session$id session = _Translations$companionRemote$session$id._(_root);
	@override late final _Translations$companionRemote$pairing$id pairing = _Translations$companionRemote$pairing$id._(_root);
	@override late final _Translations$companionRemote$remote$id remote = _Translations$companionRemote$remote$id._(_root);
	@override late final _Translations$companionRemote$errors$id errors = _Translations$companionRemote$errors$id._(_root);
	@override String get closedBeforeAuth => 'Koneksi ditutup sebelum autentikasi';
}

// Path: videoSettings
class _Translations$videoSettings$id extends Translations$videoSettings$en {
	_Translations$videoSettings$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Kecepatan Pemutaran';
	@override String get normalSpeed => 'Biasa';
	@override String sleepTimerActive({required Object duration}) => 'Aktif (${duration})';
	@override String get zoom => 'Penutup';
	@override String get sleepTimer => 'Tidur Tidur';
	@override String get audioSync => 'Audio Sinkron';
	@override String get subtitleSync => 'Subtitle Sinkronisasi';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR tidak tersedia di sini - komposer desktop atau output video ini tidak dapat membawanya.';
	@override String get hdrToneMapping => 'HDR Tone Peta';
	@override String get hdrToneMappingCompositor => 'Komposisi';
	@override String get hdrToneMappingCompositorDescription => 'Melalui metadata HDR sumber dan biarkan peta komposer desktop itu.';
	@override String get hdrToneMappingPlayer => 'Pemutar';
	@override String get hdrToneMappingPlayerDescription => 'Peta ke puncak kecerahan layar di pemain, kemudian memberitahu komposer hasilnya.';
	@override String get hdrToneMappingFailed => 'Tidak bisa mengubah pemetaan nada HDR - mode sebelumnya masih aktif.';
	@override String get audioOutput => 'Audio output';
	@override String get performanceOverlay => 'Perkembangan Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'sekitarnya';
	@override String get audioOutputSpatial => 'Ruang Audio';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Ekualiser audio';
	@override String get audioEqualizerDescription => 'Tersedia pada mpv; EQ aktif mendekodkan audio dan menghentikan matchhrough.';
	@override String get audioEqualizerFlat => 'Lantai';
	@override String get audioEqualizerActive => 'Kustom';
	@override String get audioEqualizerSaveFailed => 'Tidak bisa menyimpan seting audio equalizer.';
	@override String get backgroundVideoAudio => 'Video audio latar belakang';
	@override String get backgroundVideoAudioDescription => 'Tetap bermain audio video ketika Anda meninggalkan pemain; gambar itu tersembunyi sampai Anda kembali. Android menggunakan pemberitahuan pemutaran media.';
	@override String get audioNormalization => 'Normalisasi bunyi';
	@override String get audioNormalizationDisablesPassthrough => 'Decode audio ke PCM; passthrough dihapus saat ini';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$id extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get color => 'warna';
	@override String get performance => 'Performa';
	@override String get buffer => 'Buffer';
	@override String get app => 'Aplikasi';
	@override String get decoder => 'Dekoder';
	@override String get rawDecoder => 'Kekuatan Decoder';
	@override String get tunneling => 'tunel';
	@override String get passthrough => 'Pasangan';
	@override String get aspect => 'Aspek';
	@override String get rotation => 'Rotasi';
	@override String get dvSource => 'D. Sumber';
	@override String get dvPath => 'Jalan Dwi';
	@override String get dvRouteDecoder => 'Dolby Vision penghapusan';
	@override String get dvRouteDecoderP81 => 'Dolby Vision decoder (P7 → 8.1)';
	@override String get dvRouteBaseLayer => 'Lantai dasar';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 lapisan dasar';
	@override String get dvRouteBaseLayerHlg => 'Lantai dasar HLG';
	@override String get dvRouteBaseLayerSdr => 'Lantai dasar SDR';
	@override String get dvRouteReshaped => 'RPU yang dihapus kembali (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Grafik Eksperimen P7 FEL (tidak berkelayakan)';
	@override String get p7Conversion => 'P7 dan Conv';
	@override String get sampleRate => 'Nilai Sampel';
	@override String get pixelFormat => 'Pengaturan Pixel Fmt';
	@override String get hwFormat => 'Format perangkat keras';
	@override String get matrix => 'Matriks';
	@override String get primaries => 'Primarisasi';
	@override String get transfer => 'Pindahkan';
	@override String get renderFps => 'Keterangan FPS';
	@override String get displayFps => 'Tampilan FPS';
	@override String get avSync => 'A / V Sync';
	@override String get dropped => 'pecah';
	@override String get dvRpus => 'RPU yang';
	@override String get dvRpuAverage => 'RPU AVG';
	@override String get dvSampleAverage => 'Sebutkan Sample Avg';
	@override String get maxLuma => 'Luma maks.';
	@override String get minLuma => 'Luma min.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache yang digunakan';
	@override String get cacheLimit => 'Cache batas';
	@override String get speed => 'kecepatan';
	@override String get player => 'Pemutar';
	@override String get playMethod => 'Metode putar';
	@override String get memory => 'memori';
	@override String get uiFps => 'FPS yang';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'Nvidia HW';
	@override String get decoderQualcommHw => 'Keterangan Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Keberadaan HW';
	@override String get decoderSoftware => 'Software yang';
	@override String get decoderHardware => 'Perangkat keras';
	@override String get tunnelingActive => 'aktif';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} gagal)';
}

// Path: externalPlayer
class _Translations$externalPlayer$id extends Translations$externalPlayer$en {
	_Translations$externalPlayer$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pemain eksternal';
	@override String get useExternalPlayer => 'Gunakan pemain eksternal';
	@override String get useExternalPlayerDescription => 'Membuka video di aplikasi lain';
	@override String get selectPlayer => 'Pilih Pemain';
	@override String get customPlayers => 'Pemain Custom';
	@override String get systemDefault => 'Sistem default';
	@override String get addCustomPlayer => 'Menambahkan Custom Player';
	@override String get playerName => 'Nama Pemain';
	@override String get playerNameHint => 'Pemain saya';
	@override String get playerCommand => 'Komando';
	@override String get playerPackage => 'Nama Pakej';
	@override String get playerUrlScheme => 'Sistem URL';
	@override String get off => 'Nonaktif';
	@override String get launchFailed => 'gagal membuka pemain eksternal';
	@override String appNotInstalled({required Object name}) => '${name} tidak diinstal';
	@override String get playInExternalPlayer => 'Bermain dengan pemain luar';
	@override String get description => 'Pilih aplikasi lain untuk membuka video di. pemain yang tersedia tergantung pada perangkat Anda dan aplikasi yang terinstal.';
	@override String get systemDefaultDescription => 'Biarkan sistem operasi membuka video dengan aplikasi defaultnya.';
	@override String playerOptionDescription({required Object player}) => 'Buka video dengan ${player}.';
	@override String get playerNameDescription => 'Label yang ditunjukkan dalam daftar pemain.';
	@override String get playerPackageDescription => 'Masukkan nama paket Android dari aplikasi pemain, seperti com.example.player.';
	@override String get playerCommandDescription => 'Masukkan perintah pemain yang terinstal atau jalur eksekusi untuk perangkat ini.';
	@override String get playerUrlSchemeDescription => 'Masukkan skema URL dan template URL pilihan yang digunakan untuk meluncurkan pemain.';
}

// Path: metadataEdit
class _Translations$metadataEdit$id extends Translations$metadataEdit$en {
	_Translations$metadataEdit$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Sunting';
	@override String get screenTitle => 'Sunting metadata';
	@override String get basicInfo => 'Informasi dasar';
	@override String get artwork => 'seni';
	@override String get advancedSettings => 'Pengaturan Lanjutan';
	@override String get title => 'Judul';
	@override String get sortTitle => 'Urutkan judul';
	@override String get originalTitle => 'Judul asli';
	@override String get releaseDate => 'Tanggal rilis';
	@override String get contentRating => 'Penilaian konten';
	@override String get studio => 'Studio yang';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Kesimpulan';
	@override String get poster => 'Gambar';
	@override String get background => 'latar belakang';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Lapangan Seni';
	@override String get selectPoster => 'Pilih Poster';
	@override String get selectBackground => 'Pilih latar belakang';
	@override String get selectLogo => 'Pilih Logo';
	@override String get selectSquareArt => 'Seleksi Square Art';
	@override String get fromUrl => 'dari URL';
	@override String get uploadFile => 'Upload file';
	@override String get enterImageUrl => 'Masukkan URL gambar';
	@override String get imageUrl => 'Gambar URL';
	@override String get metadataUpdated => 'Metadata yang diperbarui';
	@override String get metadataUpdateFailed => 'Tidak dapat mengemas kini metadata';
	@override String get artworkUpdated => 'Artwork dikemas kini';
	@override String get artworkUpdateFailed => 'gagal memperbarui karya seni';
	@override String get noArtworkAvailable => 'Tidak ada seni yang tersedia';
	@override String artworkOption({required Object index}) => 'Opsi seni ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opsi seni ${index}, dipilih';
	@override String get notSet => 'Tidak menetapkan';
	@override String get libraryDefault => 'Perpustakaan default';
	@override String get accountDefault => 'Akun default';
	@override String get seriesDefault => 'Serangkaian default';
	@override String get episodeSorting => 'Episode yang disusun';
	@override String get oldestFirst => 'Yang Tertua Pertama';
	@override String get newestFirst => 'yang baru pertama';
	@override String get keep => 'Tetap';
	@override String get allEpisodes => 'Semua episode';
	@override String latestEpisodes({required Object count}) => '${count} episode terbaru';
	@override String get latestEpisode => 'episode terakhir';
	@override String episodesAddedPastDays({required Object count}) => 'Episod ditambahkan dalam ${count} hari terakhir';
	@override String get deleteAfterPlaying => 'Menghapus episode setelah bermain';
	@override String get never => 'Tidak Pernah';
	@override String get afterADay => 'Setelah satu hari';
	@override String get afterAWeek => 'Setelah seminggu';
	@override String get afterAMonth => 'Setelah sebulan';
	@override String get onNextRefresh => 'Pada hari berikutnya pembersihan';
	@override String get seasons => 'Musim';
	@override String get show => 'Pameran';
	@override String get hide => 'Sembunyikan';
	@override String get episodeOrdering => 'episode perintah';
	@override String get tmdbAiring => 'Database Film (Baca Juga)';
	@override String get tvdbAiring => 'Kegiatan yang dilakukan oleh TheTVDB (Aired)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolute) adalah';
	@override String get metadataLanguage => 'Metadata Bahasa';
	@override String get useOriginalTitle => 'Gunakan judul asli';
	@override String get preferredAudioLanguage => 'Bahasa audio yang disukai';
	@override String get preferredSubtitleLanguage => 'Bahasa teks yang diinginkan';
	@override String get subtitleMode => 'Seleksi Subtitle Mode';
	@override String get manuallySelected => 'Seleksi secara manual';
	@override String get shownWithForeignAudio => 'Menampilkan Audio Asing';
	@override String get alwaysEnabled => 'Selalu diizinkan';
	@override String get tags => 'Label';
	@override String get addTag => 'Tambahkan tag';
	@override String get genre => 'Aliran';
	@override String get director => 'Direktur';
	@override String get writer => 'Penulis';
	@override String get producer => 'Produsen';
	@override String get country => 'Negara';
	@override String get collection => 'Koleksi';
	@override String get label => 'Label';
	@override String get quickTag => 'Tag yang cepat...';
}

// Path: matchScreen
class _Translations$matchScreen$id extends Translations$matchScreen$en {
	_Translations$matchScreen$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get match => 'Pertandingan...';
	@override String get fixMatch => 'Perlawanan tetap...';
	@override String get unmatch => 'Batalkan pencocokan';
	@override String get unmatchConfirm => 'Plex memperlakukan pertandingan ini sebagai tidak bertanding sampai selesai.';
	@override String get unmatchSuccess => 'item yang tidak sesuai';
	@override String get unmatchFailed => 'Kegagalan untuk Unmatch item';
	@override String get matchApplied => 'Pertandingan yang diterapkan';
	@override String get matchFailed => 'gagal mengajukan pertandingan';
	@override String get titleHint => 'Judul';
	@override String get yearHint => 'Tahun';
	@override String get search => 'Cari';
	@override String get noMatchesFound => 'Tidak ditemukan pertandingan';
}

// Path: serverTasks
class _Translations$serverTasks$id extends Translations$serverTasks$en {
	_Translations$serverTasks$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tugas Server';
	@override String get failedToLoad => 'gagal mengisi tugas';
	@override String get noTasks => 'Tidak ada tugas yang berjalan';
}

// Path: trakt
class _Translations$trakt$id extends Translations$trakt$en {
	_Translations$trakt$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'terhubung';
	@override String connectedAs({required Object username}) => 'Terhubung dengan @${username}';
	@override String get disconnectConfirm => 'Menghapus akun Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG akan berhenti mengirimkan acara ke Trakt. Anda dapat menghubungkan kembali kapan saja.';
	@override String get scrobble => 'waktu nyata scrobbling';
	@override String get scrobbleDescription => 'Hantar permainan, istirahat, dan menghentikan acara ke Trakt selama pemutaran.';
	@override String get watchedSync => 'Sinkronisasi status';
	@override String get watchedSyncDescription => 'Ketika Anda menandakan item seperti yang dilihat di PlezyNG, mereka juga ditandakan seperti yang dilihat di Trakt.';
}

// Path: seerr
class _Translations$seerr$id extends Translations$seerr$en {
	_Translations$seerr$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Menghubungkan Seerr';
	@override String get serverUrl => 'URL server';
	@override String get serverUrlHelper => 'Alamat dari instansi Seerr';
	@override String get checkServer => 'Selanjutnya';
	@override String get signInWithJellyfin => 'Mendaftar dengan Jellyfin';
	@override String get signInWithEmby => 'Mendaftar dengan Emby';
	@override String get signInWithLocal => 'Gunakan akun lokal';
	@override String get email => 'Email';
	@override String get noSignInMethods => 'Contoh Seerr ini tidak menawarkan dukungan log masuk metode PlezyNG.';
	@override String get instance => 'instansi';
	@override String get disconnectConfirm => 'Menghubungkan Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG akan melupakan contoh Seerr ini. sambungkan kembali kapan saja.';
	@override String get request => 'Permintaan';
	@override String get request4k => 'Permintaan dalam 4K';
	@override String get seasons => 'Musim';
	@override String get allSeasons => 'Semua Musim';
	@override String get advancedOptions => 'Canggih';
	@override String get destinationServer => 'Destinasi server';
	@override String get qualityProfile => 'Profil Kualitas';
	@override String get rootFolder => 'Fasilitas root';
	@override String get languageProfile => 'Profil Bahasa';
	@override String get tags => 'Label';
	@override String get noTags => 'Tidak ada tag';
	@override String defaultOption({required Object name}) => '${name} (dengan default)';
	@override String get animeNote => 'Seri ini adalah anime.';
	@override String get requestSubmitted => 'Permintaan yang disampaikan';
	@override String requestFailed({required Object error}) => 'Permintaan gagal: ${error}';
	@override String get requestsLoadFailed => 'Tidak bisa memuat pilihan permintaan';
	@override String get nothingToRequest => 'Semua sudah tersedia atau diminta.';
	@override String get statusAvailable => 'Tersedia';
	@override String get statusPartiallyAvailable => 'Parsial tersedia';
	@override String get statusRequested => 'yang diminta';
	@override String get statusProcessing => 'Pemrosesan';
	@override String get statusBlocklisted => 'Blokasi';
	@override String couldNotReach({required Object url, required Object error}) => 'Tidak bisa mencapai ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'No Seerr kasus di ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Sebuah proxy terbalik yang mengesahkan (SSO atau HTTP auth) dijawab sebagai gantinya Seerr. PlezyNG tidak dapat mendaftar melalui itu: biarkan /api/v1 laluan Seerr melewati proxy untuk aplikasi ini, atau gunakan alamat yang mencapai Seerr secara langsung.';
	@override String get invalidUrl => 'Masukkan alamat server seperti https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Contoh Seerr ini tidak mendukung Quick Connect.Ia membutuhkan Seerr 3.4 atau lebih baru.';
	@override String get notInitialized => 'Instansi Seerr ini belum menyelesaikan setup pertama yang dijalankan';
	@override String get noPlexTokenForReauth => 'No. Plex token tersedia untuk mendaftar kembali';
	@override String get noStoredCredentials => 'Tidak ada pengesahan yang disimpan tersedia untuk mendaftar kembali';
	@override String get signInRejected => 'Tanda-tanda ini ditolak';
	@override String get noSessionCookie => 'Seerr tidak mengeluarkan cookie sesi';
	@override String get freshCookieRejected => 'Seerr menolak cookie sesi baru';
	@override String get noUserInformation => 'Seerr tidak mengembalikan informasi pengguna';
	@override String get sessionRejectedAfterReauth => 'Perjanjian itu ditolak setelah ditandatangani lagi.';
	@override String get permissionDenied => 'Seerr menolak tindakan ini: akun Anda tidak lagi memiliki izin yang diperlukan';
	@override String get permissionRevoked => 'Anda tidak lagi memiliki izin untuk meminta ini';
}

// Path: services
class _Translations$services$id extends Translations$services$en {
	_Translations$services$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Layanan';
	@override String get hubSubtitle => 'Sync menonton kemajuan dan meminta judul baru.';
	@override String get integrations => 'Integrasi';
	@override String get notConnected => 'Tidak terhubung';
	@override String connectedAs({required Object username}) => 'Terhubung dengan @${username}';
	@override String get scrobble => 'Menjejaki kemajuan secara otomatis';
	@override String get scrobbleDescription => 'Update daftar Anda saat Anda menyelesaikan episode atau film.';
	@override String disconnectConfirm({required Object service}) => 'Menghubungkan ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG akan berhenti mengemas kini ${service}. sambungkan kembali kapan saja.';
	@override String connectFailed({required Object service}) => 'Saya tidak bisa menghubungkan ke ${service}. coba lagi.';
	@override late final _Translations$services$names$id names = _Translations$services$names$id._(_root);
	@override late final _Translations$services$simklReconnect$id simklReconnect = _Translations$services$simklReconnect$id._(_root);
	@override late final _Translations$services$deviceCode$id deviceCode = _Translations$services$deviceCode$id._(_root);
	@override late final _Translations$services$oauthProxy$id oauthProxy = _Translations$services$oauthProxy$id._(_root);
	@override late final _Translations$services$pendingAuth$id pendingAuth = _Translations$services$pendingAuth$id._(_root);
	@override late final _Translations$services$libraryFilter$id libraryFilter = _Translations$services$libraryFilter$id._(_root);
	@override String get seerrDescription => 'Hubungi Seerr atau Overseerr untuk mencari judul dan mengajukan permintaan media.';
	@override late final _Translations$services$trackerDescriptions$id trackerDescriptions = _Translations$services$trackerDescriptions$id._(_root);
}

// Path: addServer
class _Translations$addServer$id extends Translations$addServer$en {
	_Translations$addServer$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Tambahkan server ${product}';
	@override String get serverUrls => 'URL server yang';
	@override String get serverUrlsHelper => 'Banyak URL yang diizinkan, dipisahkan oleh commas.';
	@override String get findServer => 'Temukan server';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Mencari server lokal ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'Lokasi ${product} server';
	@override String get username => 'Nama Pengguna';
	@override String get password => 'Kata sandi';
	@override String get signIn => 'Masuk';
	@override String get change => 'Perubahan';
	@override String get required => 'Diperlukan';
	@override String couldNotReachServer({required Object error}) => 'Tidak dapat mencapai server: ${error}';
	@override String signInFailed({required Object error}) => 'Daftar yang gagal: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect gagal: ${error}';
	@override String get addPlexTitle => 'Mendaftar dengan Plex';
	@override String get pinExpired => 'PIN sudah habis sebelum masuk.Sila coba lagi.';
	@override String failedToRegisterAccount({required Object error}) => 'Kegagalan mendaftarkan akun: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Masukkan URL server ${product} Anda';
	@override String get addConnectionTitle => 'Tambahkan koneksi';
	@override String addConnectionTitleScoped({required Object name}) => 'Tambahkan ke ${name}';
	@override String get signInWithPlexCard => 'Mendaftar dengan Plex';
	@override String get signInWithPlexCardSubtitle => 'Mengaktifkan perangkat ini. server yang dibagikan ditambahkan.';
	@override String get signInWithPlexCardSubtitleScoped => 'Mengaktifkan akun Plex . pengguna rumah menjadi profil.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Menghubungkan ke ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Masukkan URL, nama pengguna, dan kata sandi server Anda.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Mendaftar ke server ${product} Anda. menghubungkan ke ${name}.';
	@override String get borrowFromAnotherProfile => 'Pinjaman dari profil lain';
	@override String get borrowFromAnotherProfileSubtitle => 'Menggunakan koneksi profil lain. profil yang dilindungi PIN membutuhkan PIN.';
	@override String get invalidCredentials => 'Nama pengguna atau kata sandi yang tidak sah';
	@override String get authResponseNotJson => 'Jawaban pengesahan tidak sah JSON';
	@override String get authResponseIncomplete => 'Respon sign-in dari server tidak lengkap';
	@override String get quickConnectRejected => 'Quick Connect ditolak oleh server';
	@override String get quickConnectNotJson => 'Jawaban Quick Connect tidak sah JSON';
	@override String get quickConnectMissingFields => 'Jawaban Quick Connect tidak memiliki kode atau rahasia';
	@override String get quickConnectPollRejected => 'Quick Connect pertanyaan ditolak oleh server';
	@override String get serverTimedOut => 'Server tidak bertindak balas tepat waktu.';
	@override String get responseNotJson => 'Jawaban server tidak valid JSON';
	@override String responseMissingIdentity({required Object product}) => 'Jawabannya hilang ID atau nama server — apakah ini server ${product}?';
	@override String probeFailed({required Object error}) => 'Tidak dapat mencapai server: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Masukkan sekurang-kurangnya satu URL server ${product}';
	@override String noReachableServer({required Object product}) => 'Tidak ditemukan server yang dapat diakses ${product}';
	@override String urlsPointToDifferentServers({required Object product}) => 'URL ini menunjuk ke server yang berbeda ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'URL ini tidak sesuai dengan server ${product}';
	@override String get redirectUnsupported => 'Server yang dialihkan ke URL yang tidak didukung';
	@override String redirectDifferentHost({required Object product}) => 'Server dialihkan ke host yang berbeda.Masukkan URL akhir ${product} langsung.';
	@override String get redirectInsecure => 'Server yang dialihkan dari HTTPS ke URL yang tidak aman';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Server dialihkan ke URL yang tidak didukung. masukkan URL terakhir ${product} langsung.';
	@override String get directPlexServerUrl => 'Plex URL server';
	@override String get directPlexServerUrlHelper => 'Masukkan IP dan port lokal dari server media Plex Anda.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (pilihan)';
	@override String get plexTokenHelper => 'Tinggalkan kosong jika akses tanpa auth diizinkan di server ini.';
	@override String get plexTokenRequired => 'Silahkan masukkan token Plex Anda (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Server media Plex (langsung / lokal)';
	@override String get connectDirectPlexCardSubtitle => 'Hubungi secara langsung menggunakan IP atau URL lokal tanpa akun plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Hubungi secara langsung menggunakan IP lokal atau URL. Hubungi ${name}.';
	@override String get insecureTitle => 'Koneksi yang tidak terenkripsi';
	@override String insecureDescription({required Object url}) => '${url} menggunakan HTTP. Orang lain di jaringan dapat membaca atau mengubah kata sandi, token, dan media Anda. Gunakan HTTPS jika tersedia. Lanjutkan hanya jika Anda memercayai jaringan ini dan menerima risikonya.';
	@override String get allowHttp => 'Izinkan HTTP';
	@override String get httpsRequired => 'Menggunakan HTTPS atau secara eksplisit memungkinkan koneksi yang tidak terenkripsi.';
}

// Path: watchLink
class _Translations$watchLink$id extends Translations$watchLink$en {
	_Translations$watchLink$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Saya tidak bisa mengakses server Plex untuk link ini.';
	@override String get notFound => 'Saya tidak dapat menemukan acara atau film ini di server Plex Anda.';
	@override String get ambiguous => 'Link ini cocok dengan item di lebih dari satu server.Tambahkan server ke link.';
	@override String get plexOnly => 'Link menonton saat ini hanya mendukung server Plex.';
	@override String get unsupportedItem => 'Link menonton hanya dapat membuka acara atau film.';
	@override String get menuItem => 'Lihat link';
	@override String get dialogTitle => 'Lihat link';
	@override String get dialogShowHint => 'Membuka link ini memainkan episode berikutnya.Tambahkan &mode=shuffle ke akhir untuk memainkan acara di shuffle.';
	@override String get dialogMovieHint => 'Membuka link ini memainkan film ini.';
	@override String get copy => 'Salin';
	@override String get copied => 'Link yang disalin';
}

// Path: homeLayout
class _Translations$homeLayout$id extends Translations$homeLayout$en {
	_Translations$homeLayout$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rumah Layout';
	@override String get resetToast => 'Home Reset ke layout hero asli Plezy';
	@override String get resetHeroTitle => 'Mengembalikan layout pahlawan ke stok Plezy?';
	@override String get resetHeroBody => 'Mengalih keluar setiap baris pengaturan pahlawan dan membawa kembali satu banner berputar di bagian atas rumah, seperti sebelum baris pahlawan ada.';
	@override String get removeRowTitle => 'Menghapus rumah tangga?';
	@override String removeRowBody({required Object title}) => '${title} akan dihapus. ini tidak dapat dibatalkan.';
	@override String get sync => 'Sinkron';
	@override String get syncAccountTitle => 'Sinkronisasi layout dengan akun Plex Anda';
	@override String get syncAccountOn => 'Pada: perangkat ini berbagi urutan, urutan, Hero dan Auto-slide dengan perangkat lain Anda.';
	@override String get syncAccountOff => 'Off: perangkat ini mempertahankan layoutnya sendiri.';
	@override String get syncNow => 'Sync sekarang';
	@override String get plexHomeManager => 'Plex Pengurus Rumah';
	@override String get managePlexRows => 'Mengelola Plex baris di Plezy';
	@override String get managePlexRowsDescription => 'Terbuka untuk mengatur rangkaian yang dipilih di rumah';
	@override String get organizeHomeRows => 'Mengatur rangkaian rumah';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} baris: bergerak, Hero, Auto-slide, menghapus';
	@override String organizeLibraryRows({required Object library}) => 'Mengatur ${library} baris';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Selanjutnya Menonton + ${n} baris: bergerak, Perpustakaan, Rumah, Hero, Auto-slide';
	@override String get renderAsHero => 'Render sebagai kartu pahlawan';
	@override String get heroOnlySingleCollection => 'Hanya tersedia ketika baris ini diselesaikan untuk judul nyata dari satu koleksi';
	@override String get hero => 'pahlawan';
	@override String get autoSlide => 'Seluruh Slide';
	@override String get autoSlideDescription => 'Arrows (PC) dan d-pad (TV) selalu bekerja dan memulai kembali timer.';
	@override String get autoSlideEditDescription => 'Selain itu, ia juga meluncur sendiri setiap beberapa detik. Off: hanya bergerak ketika Anda mengklik pistol (PC) atau tekan kiri/kanan pada remote (TV). Arrow dan d-pad selalu bekerja sama.';
	@override String get enableHeroFirst => 'Memungkinkan Hero Pertama';
	@override String get showOnHome => 'Tampilkan pada Home Screen';
	@override String get home => 'rumah';
	@override String get removeFromHome => 'Menghilangkan dari rumah';
	@override String get selectRowsFirst => 'Pilih rumah baris di bawah pertama.';
	@override String plexManagedRows({required Object n}) => '${n} Plex baris yang dikendalikan';
	@override String get continueWatching => 'Lanjutkan menonton';
	@override String get continueWatchingLibraryDescription => 'Perpustakaan ini sendiri resume-progress baris';
	@override String get continueWatchingHomeDescription => 'Rangkaian kemajuan yang ditunjukkan di rumah';
	@override String get nextUpHomeDescription => 'Next Unwatched episode series yang ditampilkan secara terpisah di Home';
	@override String get library => 'Pustaka';
	@override String get showInRecommended => 'Perpustakaan yang disarankan';
	@override String get customPlexRow => 'Keterampilan Plex baris';
	@override String get heroNeedsLibrary => 'Periksa perpustakaan pertama — Hero perlu di suatu tempat untuk menunjukkan';
	@override String get heroNeedsSurface => 'Periksa Perpustakaan atau Rumah terlebih dahulu — Hero perlu di suatu tempat untuk menunjukkan';
	@override String get removeHub => 'Menghapus Hub';
	@override String get noPlexRows => 'No. Plex baris yang dikelola kembali untuk perpustakaan ini.';
	@override String get openDetails => 'Detail Terbuka';
	@override String get heroCards => 'Kartu Hero';
	@override String get tapHeroCard => 'Menangkap Kartu Pahlawan';
	@override String get tvPlayFocus => 'TV Remote: Meningkatkan tombol Play';
	@override String get tvPlayFocusDescription => 'D-pad ke bawah berhenti pada tombol Play sebelum bergerak ke baris berikutnya.';
	@override String get tvWrap => 'TV Remote: Kartu Pahlawan Loop';
	@override String get tvWrapDescription => 'Tepat pada kartu terakhir kembali ke kartu pertama. berhenti pada kartu terakhir. kiri pada kartu pertama selalu pergi ke bar samping.';
	@override String get castOnHero => 'Bermain dengan Hero Banner';
	@override String get castOnHeroDescription => 'Menunjukkan cast di bagian bawah banner pahlawan. di luar hanya menyimpan judul dan ringkasan.';
	@override String get customRows => 'Rangkaian Custom';
	@override String get loading => 'Layout Rumah Layout...';
	@override String get noCustomRows => 'Belum ada rangkaian';
	@override String get addRowHint => 'Gunakan Add Home row untuk membuat satu.';
	@override String get addHomeRow => 'Menambahkan Home Rue';
	@override String get addHomeRowDescription => 'Pilih kategori; baris baru ditambahkan ke Organisator secara otomatis';
	@override String get removeRow => 'Menghilangkan Ronde';
	@override String get recentlyAdded => 'Terbaru';
	@override String get recentlyReleased => 'Baru-baru ini dilepaskan';
	@override String get movieCollections => 'Koleksi Film';
	@override String get showCollections => 'Tunjukkan Koleksi';
	@override String get rowTitle => 'Judul Row';
	@override String get content => 'Sukses';
	@override String get showThisRowIn => 'Tunjukkan baris ini di:';
	@override String get libraryRecommended => 'Perpustakaan yang disarankan';
	@override String get heroCard => 'Kartu Hero';
	@override String get heroCardDescription => 'Menunjukkan sebagai satu kartu putar lebar penuh bukannya poster shelf.';
	@override String get heroUnavailableDescription => 'Hanya tersedia ketika baris ini diselesaikan untuk judul nyata dari satu koleksi - dengan lebih dari satu koleksi terpilih tidak ada satu judul untuk berputar melalui.';
	@override String get librariesSelection => 'Perpustakaan (meninggalkan semua tidak disemak untuk mencakup setiap perpustakaan)';
	@override String get librariesMergedDescription => 'Setiap perpustakaan yang diperiksa di sini digabungkan ke dalam satu baris ini.';
	@override String get movieCollectionsSelection => 'Koleksi film (meninggalkan semua tidak disemak untuk setiap perpustakaan yang dipilih)';
	@override String get showCollectionsSelection => 'Menampilkan koleksi (meninggalkan semua yang tidak disemak untuk setiap perpustakaan yang dipilih)';
	@override String get collectionRowsDescription => 'Jika satu koleksi bertanding, judulnya ditampilkan secara langsung dalam urutan.Jika lebih dari satu koleksi bertanding, setiap koleksi ditampilkan sebagai satu poster — ketiknya untuk membuka koleksi itu.';
	@override String get allCollections => 'Semua Koleksi';
	@override String get noRowsHere => 'Belum ada baris di sini.';
	@override String get hideWatchedRows => 'Menutup barang-barang yang dilihat dalam baris';
	@override String get hideWatchedRowsDescription => 'Judul yang dipantau sepenuhnya meninggalkan Rumah dan perpustakaan Rangkaian yang disarankan.';
	@override String get untitledCollection => 'Koleksi Untitled';
	@override String get moveRowHint => 'Up/Down: bergerak baris · Pilih: turun di sini · Kembali: membatalkan';
	@override String get organizeRowsHint => 'Pilih pada urutan (atau tahan Pilih): pindah · Kiri/Kiri: pilihan urutan · Kembali: selesai';
	@override String get layoutNavDescription => 'Pilih baris, perpustakaan, dan kategori koleksi';
	@override String get editHomeRow => 'Edit rumah tangga';
	@override String get resetHeroButton => 'Reset Hero layout ke stok Plezy';
	@override String get reorderingUnlocked => 'Kembali ke Unlocked';
	@override String get reorderingLocked => 'Kembali tertutup';
	@override String get rowsCanBeDragged => 'Roda dapat ditarik — tekan kunci untuk mencegah';
	@override String get tapLockToDrag => 'Tekan kunci untuk menarik baris';
	@override String customRowLabel({required Object title}) => 'Jumlah : ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Sembunyikan';
	@override String get remove => 'Hapus';
	@override String get libraryResumeRow => 'Perpustakaan ini kembali';
	@override String get pressAgainToDelete => 'Tekan lagi untuk menghapus';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'pada';
	@override String get resetHeroButtonDescription => 'Mengalih keluar setiap baris pengaturan pahlawan dan membawa kembali satu banner berputar di atas, seperti sebelum baris pahlawan ada.';
	@override String get tapHeroCardDescription => 'Pilih apakah menekan atau memilih kartu Hero memulai playback atau membuka detailnya.';
	@override String get heroTapPlayDescription => 'Mulai item yang dipilih segera.';
	@override String get heroTapDetailsDescription => 'Buka detail item yang dipilih sebelum memilih tindakan.';
}

// Path: platform
class _Translations$platform$id extends Translations$platform$en {
	_Translations$platform$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG terhubung ke server media dan perangkat playback Anda di jaringan lokal Anda.';
	@override String get locationPermission => 'PlezyNG menggunakan akses lokasi ketika iOS membutuhkan untuk mengidentifikasi jaringan lokal Anda dan menghubungkannya ke server media Anda.';
	@override String get photoLibraryPermission => 'Pilih gambar dari perpustakaan foto Anda untuk digunakan sebagai karya seni media.';
	@override String get cameraPermission => 'Mengimbas kode QR untuk berpasangan dengan Companion Remote.';
}

// Path: universalMedia
class _Translations$universalMedia$id extends Translations$universalMedia$en {
	_Translations$universalMedia$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Media Terbuka';
	@override String get shortcutHelp => 'Mainkan link, playlist, atau file untuk sesi ini.';
	@override String get intro => 'Buka link, playlist, atau file. Playback menggunakan pemutar standar PlezyNG dan tidak menambahkan sejarah ke perpustakaan Anda.';
	@override String get openWhat => 'Apa yang ingin Anda buka?';
	@override String get stream => 'Alamat Stream';
	@override String get playlist => 'Daftar Playlist';
	@override String get files => 'perangkat file';
	@override String get favorites => 'Penyimpanan Stream Favorit';
	@override String get address => 'Alamat Media';
	@override String get addressHelp => 'URL dengan parameter pengesahan atau tandatangan yang diakui hanya digunakan untuk sesi ini dan tidak dapat disimpan sebagai favorit.';
	@override String get displayName => 'Nama Pameran (Optional)';
	@override String get displayNameHelp => 'Pilih nama singkat untuk pemain dan kontrol media sistem.';
	@override String get allowHttp => 'Memungkinkan koneksi HTTP yang tidak terenkripsi';
	@override String get allowHttpHelp => 'HTTP tidak menyulitkan koneksi. hanya membiarkannya di jaringan yang dipercaya. gunakan HTTPS kapan saja mungkin.';
	@override String get advancedProtocols => 'Hanya MPV: masukkan alamat RTSP, RTMP/RTMPS, UDP, atau RTP. Alamat ini tidak dapat disimpan sebagai favorit.';
	@override String get liveStream => 'Perlakukan sebagai hidup';
	@override String get liveStreamHelp => 'Gunakan ini untuk live video atau radio. aplikasi menyembunyikan bar waktu, skip tombol, dan go-to-time opsi.';
	@override String get privateSession => 'Hanya playback ini menggunakan alamat.Save a eligible stream favorite to keep it in this profile.';
	@override String get saveFavorite => 'Selamatkan Favorit';
	@override String get playNow => 'Bermain sekarang';
	@override String get favoriteSaved => 'Stream favorit disimpan ke profil ini';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${count} masuk daftar main yang tidak didukung atau tidak aman.',
	);
	@override String get playlistAddress => 'Alamat Playlist';
	@override String get playlistAddressHelp => 'Buka daftar main M3U, M3u8, atau PLS dari alamat web. link streaming langsung tidak menyimpan daftar main.';
	@override String get choosePlaylist => 'Pilih file playlist';
	@override String get openPlaylist => 'Pembukaan playlist';
	@override String get playlistFormatsHelp => 'Daftar main dapat berisi lebih dari 1.000 item dan 2 MB. HLS terbuka sebagai arus sehingga pemain dapat memilih kualitas.';
	@override String get noFavorites => 'Belum disimpan streaming favorit sampai sekarang. favorit tetap di profil ini.';
	@override String get removeFavorite => 'Menghapus Stream Favorit';
	@override String get filesHelp => 'Pilih file audio, video, atau ISO untuk catatan sementara.File dan URL tidak ditambahkan ke sejarah perpustakaan.';
	@override String get chooseFiles => 'Pilih file';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${count} file terpilih',
	);
	@override String get wifiTransfer => 'Mengirim file melalui Wi-Fi';
	@override String get wifiTransferHelp => 'Memindahkan file yang didukung dari browser pada jaringan yang sama.';
	@override String get wifiTransferIntro => 'Buka alamat ini dalam browser pada perangkat lain. pilih file untuk menambahkan mereka ke perpustakaan File dan buku perangkat ini.';
	@override String get wifiTransferPrivacy => 'Setiap orang yang tahu alamat ini dapat mengirim file sampai Anda menghentikan transfer atau alamat berakhir setelah 15 menit. maksimum: 100 file, 4 GiB per file, 10 GiB total.';
	@override String get wifiTransferStarting => 'Menyiapkan transfer pribadi dan terbatas waktu.';
	@override String get wifiTransferUnavailable => 'Tidak bisa memulai transfer. periksa akses jaringan lokal dan coba lagi.';
	@override String get openThisAddress => 'Buka salah satu alamat ini pada perangkat pengiriman';
	@override String get copyAddress => 'Kopi alamat transfer';
	@override String get addressCopied => 'Alamat transfer yang disalin';
	@override String transferExpires({required Object time}) => 'Alamat ini berakhir di ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${count} file yang diterima',
	);
	@override String uploadedData({required Object size}) => 'Diterima oleh ${size}';
	@override String get stopTransfer => 'Hentikan transfer dan membatalkan alamat';
	@override String get startTransfer => 'Mulai transfer';
	@override String get wifiImportedFiles => 'Pengiriman Wi-Fi';
	@override String get wifiBrowserTitle => 'Mengirim file ke PlezyNG';
	@override String get wifiBrowserIntro => 'Pilih file audio, video, ebook, atau komik untuk dikirimkan. file disimpan di perpustakaan File dan buku perangkat ini. maksimum: 100 file, 4 GiB per file, 10 GiB total.';
	@override String get uploadFilesLabel => 'File untuk dikirimkan';
	@override String get uploadSelected => 'Mengunggah file terpilih';
	@override String get uploadSelectFirst => 'Pilih satu atau lebih file terlebih dahulu.';
	@override String get uploading => 'mengirimkan';
	@override String get uploadComplete => 'File yang ditambahkan ke PlezyNG.';
	@override String get uploadFailed => 'File tidak dapat ditambahkan.Jadilah halaman ini terbuka dan coba lagi.';
	@override String get liveCue => 'hidup';
	@override String get liveSession => 'Live Stream';
	@override String get liveCueHelp => 'Untuk video atau radio langsung, aplikasi menyembunyikan bar waktu dan melompat tombol. tidak menyimpan alamat atau menonton sejarah.';
	@override String get sessionOnly => 'Playback ini hanya sesi saja.';
	@override String get sessionOnlyHelp => 'Playback tidak pernah menyimpan kemajuan atau sejarah.Save the stream as a favorite to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'Gambar penyesuaian';
	@override String get pictureHelp => 'Perubahan gambar ini hanya mempengaruhi playback ini. mereka menetapkan kembali ketika playback berakhir.';
	@override String get resetPicture => 'Reset gambar';
	@override String get brightness => 'Cahaya';
	@override String get contrast => 'kontras';
	@override String get gamma => 'Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturasi';
	@override String get view360 => 'Pemandangan rata untuk video 360 derajat';
	@override String get view360Help => 'Gunakan ini untuk video 360° equirectangular. MPV membutuhkan filter v360 FFmpeg untuk pandangan ini.';
	@override String get view360Unavailable => 'Pembuatan MPV ini tidak dapat menerapkan filter 360 derajat.';
	@override String get view360Yaw => 'pandangan horizontal';
	@override String get view360Pitch => 'Pandangan Vertikal';
	@override String get view360FieldOfView => 'Bidang Penglihatan';
	@override String get recordStream => 'Rekor Live Stream';
	@override String get stopRecording => 'Hentikan dan Simpan Rekaman';
	@override String get recordingStarted => 'Rekaman aktif. meninggalkan playback berhenti dan menyimpan rekaman.';
	@override String get recordingSaved => 'Rekaman selesai dan diselamatkan.';
	@override String get recordingActive => 'Mengingat perangkat ini. meninggalkan playback berhenti dan menyimpannya.';
	@override String get recordingFormatHelp => 'Untuk video, pilih MKV atau MPEG-TS. untuk audio, pilih MKA atau MKV.';
	@override String get replaceRecordingTitle => 'Mengganti rekaman ini?';
	@override String get replaceRecordingHelp => 'PlezyNG mengembalikan file yang ada saat merekam.Jika tidak dapat menyimpan rekaman baru, plezyNG memulihkan sandaran.';
	@override String get replaceRecording => 'Mengganti file';
	@override String get discHelp => 'Buka cakera di drive optik komputer ini.Anda juga dapat membuka gambar ISO dari file perangkat.';
	@override String get discs => 'Disk optik';
	@override String get dvd => 'DVD';
	@override String get bluray => 'dan Blu-ray';
	@override String get audioCd => 'Audio CD';
	@override String get discAvailability => 'Disk playback membutuhkan konfigurasi MPV yang kompatibel, drive yang didukung, dan izin sistem operasi.';
	@override String get converterTitle => 'Konversi file media lokal';
	@override String get converterHelp => 'Gunakan FFmpeg untuk membuat MP4, M4A, atau MP3 salinan.';
	@override String get converterIntro => 'Konversi file audio atau video lokal ke format yang bekerja pada lebih banyak perangkat.';
	@override String get converterPrivacy => 'FFmpeg harus dipasang pada komputer ini.Conversion hanya membaca file lokal.Ia tidak mengunduh aliran atau menghapus DRM.';
	@override String get converterChooseInput => 'Pilih file media lokal';
	@override String get converterFormat => 'Format output';
	@override String get converterMp4 => 'MP4 H.264 dan AAC';
	@override String get converterM4a => 'M4A · AAC audio';
	@override String get converterMp3 => 'MP3 dan Audio';
	@override String get converterSaveAs => 'Menyimpan media yang terkonversi sebagai';
	@override String get converterExtensionMismatch => 'Pilih nama file dengan ekstensi output yang dipilih.';
	@override String get converterUnsupportedInput => 'Pilih file audio atau video.';
	@override String get converterLocalOnly => 'File yang dipilih tidak tersedia sebagai jalur perangkat lokal.';
	@override String get converterReplaceTitle => 'Mengganti file ini?';
	@override String get converterReplaceHelp => 'PlezyNG mengembalikan file yang ada sampai salinan terkonversi disimpan.';
	@override String get converterStarting => 'Mulai dari FFmpeg...';
	@override String get converterProgress => 'Beralih ke komputer ini...';
	@override String get converterComplete => 'Konversi selesai. file baru sudah siap.';
	@override String get converterFfmpegMissing => 'Instal FFmpeg dengan dukungan H.264, AAC, dan MP3, kemudian coba lagi.';
	@override String get converterFailed => 'Periksa bahwa file sumber dapat dibaca dan tujuan memiliki cukup ruang gratis.';
	@override String get converterCancelled => 'Konversi dibatalkan. hasil yang tidak lengkap dihapus.';
	@override String get converterDesktopOnly => 'Konversi lokal tersedia pada komputer desktop dengan FFmpeg terinstal.';
	@override String get converterStart => 'Konversi file';
}


// Path: fileSources
class _Translations$fileSources$id extends Translations$fileSources$en {
	_Translations$fileSources$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'File dan buku';
	@override String get subtitle => 'Baca, dengar, dan menonton dari file Anda sendiri.';
	@override String get add => 'Tambahkan sumber';
	@override String get importFiles => 'Import file';
	@override String get localFiles => 'Pada perangkat ini';
	@override String get source => 'Sumber';
	@override String get name => 'Nama';
	@override String get endpoint => 'URL server';
	@override String get smbEndpointHint => 'Contoh: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Masukkan server SMB dan satu folder bersama.';
	@override String get root => 'Folder atau prefiks';
	@override String get smbFolderHelp => 'Biarkan kosong untuk menggunakan seluruh folder bersama, atau masukkan folder di dalamnya.';
	@override String get username => 'Nama Pengguna';
	@override String get smbDomain => 'Domain (opsional)';
	@override String get password => 'Kata sandi';
	@override String get token => 'API Token';
	@override String get accessKey => 'Akses ke kunci ID';
	@override String get secretKey => 'Key akses rahasia';
	@override String get sessionToken => 'Sesi token ( opsi)';
	@override String get region => 'Daerah';
	@override String get clientId => 'ID pelanggan OAuth';
	@override String get clientSecret => 'OAuth Client Secret (hanya desktop Google)';
	@override String get allowHttp => 'Izinkan HTTP tanpa enkripsi di jaringan tepercaya';
	@override String get smbEncryption => 'Enkripsi koneksi SMB3';
	@override String get smbEncryptionHint => 'Gunakan enkripsi SMB3 jika NAS mendukungnya.';
	@override String get connect => 'Sambung';
	@override String get cancel => 'Batal';
	@override String get save => 'Simpan';
	@override String get close => 'Tutup';
	@override String get removeSource => 'Sumber yang terhubung';
	@override String get disconnectMessage => 'Putuskan sambungan sumber ini? Berkas yang diunduh serta riwayat membaca dan mendengarkan Anda akan tetap tersimpan di perangkat ini.';
	@override String get localFolder => 'Pilih folder';
	@override String get empty => 'Belum ada yang di sini';
	@override String get emptyHint => 'Tambah sumber atau impor buku, audiobook, musik, atau video.';
	@override String get search => 'Cari folder ini';
	@override String get searchCached => 'Mencari perpustakaan yang diselamatkan';
	@override String get refresh => 'Segarkan';
	@override String get loadMore => 'Layar Lebih';
	@override String get offline => 'Tersedia offline';
	@override String get download => 'Tetap offline';
	@override String get removeDownload => 'Menghapus offline copy';
	@override String get continueReading => 'Lanjutkan Membaca';
	@override String get continueListening => 'Lanjut Mendengarkan';
	@override String get continueWatching => 'Lanjutkan menonton';
	@override String get read => 'Bacaan';
	@override String get listen => 'Dengarkan';
	@override String get play => 'Putar';
	@override String get pause => 'Jeda';
	@override String get stop => 'Berhenti';
	@override String get startOver => 'Mulai dari';
	@override String get finished => 'selesai';
	@override String get markFinished => 'Mark sudah selesai';
	@override String get markUnfinished => 'Mark yang tak terbatas';
	@override String get editions => 'Edisi dan file';
	@override String get chapters => 'bab yang';
	@override String get bookmarks => 'Buku dan Notis';
	@override String get bookmark => 'Tambahkan Bookmark';
	@override String get highlight => 'Peningkatan';
	@override String get note => 'Catatan';
	@override String get delete => 'Hapus';
	@override String get export => 'Notis Ekspor';
	@override String get exported => 'Notis yang diekspor';
	@override String get sync => 'Sinkronisasi Kemajuan';
	@override String get synced => 'Kemajuan Sinkronisasi';
	@override String get conflict => 'Perangkat lain memiliki posisi yang berbeda. pilih di mana untuk melanjutkan.';
	@override String get useLocal => 'Gunakan perangkat ini';
	@override String get useRemote => 'Gunakan perangkat lain';
	@override String get history => 'Posisi Sejarah';
	@override String get groupAudio => 'Mendengarkan sebagai satu buku audio';
	@override String get groupHint => 'Menghubungkan file audio yang saat ini dimuat dalam folder ini. muat semua halaman terlebih dahulu.';
	@override String get order => 'File perintah';
	@override String get moveUp => 'bergerak ke atas';
	@override String get moveDown => 'Memuat turun';
	@override String get speed => 'Kecepatan Pemutaran';
	@override String get sleep => 'Waktu Tidur';
	@override String get sleepOff => 'Nonaktif';
	@override String get endChapter => 'Akhir dari bab';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} menit',
	);
	@override String get skipBack => 'Kembali ke Sk';
	@override String get skipForward => 'melangkah maju';
	@override String get smartRewind => 'Kembali ke Smart After a Pause';
	@override String get playbackOptions => 'Pilihan Mendengarkan';
	@override String remaining({required Object time}) => '${time} yang tersisa';
	@override String get contents => 'Konten';
	@override String get readerSettings => 'Membaca Settings';
	@override String get fontSize => 'Ukuran teks';
	@override String get lineHeight => 'Line ruang';
	@override String get margin => 'Margin';
	@override String get font => 'Tipe Wajah';
	@override String get serif => 'Serif';
	@override String get sans => 'Tanpa serif';
	@override String get mono => 'Monospace';
	@override String get columns => 'Kolom';
	@override String get scroll => 'Scroll secara vertikal';
	@override String get justify => 'Ratakan teks kiri-kanan';
	@override String get readerTheme => 'Penampilan halaman';
	@override String get appTheme => 'Mengikuti tema app';
	@override String get paper => 'Kertas';
	@override String get sepia => 'Sepia';
	@override String get night => 'Malam yang';
	@override String get readAloud => 'Bacakan halaman ini';
	@override String get readAlong => 'Baca sambil mendengarkan';
	@override String get stopReading => 'Hentikan narasi';
	@override String get searchBook => 'Pencarian dalam buku';
	@override String get noMatches => 'Tidak ada pertandingan';
	@override String get previousPage => 'Halaman sebelumnya';
	@override String get nextPage => 'Halaman selanjutnya';
	@override String page({required Object number}) => 'Halaman ${number}';
	@override String get externalBlocked => 'Link buku eksternal diblokir di pembaca.';
	@override String get loading => 'Pembukaan...';
	@override String get narrator => 'narator';
	@override String get audio => 'Audio yang';
	@override String get video => 'Video yang';
	@override String get ebooks => 'ebook';
	@override String get all => 'Semua';
	@override String get downloads => 'File Offline';
	@override String get confirmDelete => 'Hapus salinan luring yang dipilih? Posisi membaca atau mendengarkan dan catatan Anda akan tetap tersimpan.';
	@override String get errorAuthentication => 'Masuk lagi untuk menyambungkan kembali sumber ini.';
	@override String get errorPermission => 'Sumber ini tidak memberikan akses ke file yang diminta.';
	@override String get errorUnavailable => 'Sumber tidak tersedia. Coba lagi, atau buka salinan luring.';
	@override String get errorUnsupported => 'Format atau koneksi ini tidak didukung pada perangkat ini. periksa panduan pengaturan sumber.';
	@override String get errorInvalidData => 'File atau respons server ini tidak dapat dibaca dengan aman.';
	@override String get errorCancelled => 'Operasi ini dibatalkan.';
	@override String get errorConflict => 'Posisi berubah dalam sesi lain. buka kembali item untuk memilih posisi.';
	@override String get signIn => 'Masuk';
	@override String get reconnect => 'Menghubungkan kembali';
	@override String get folderHelp => 'Tinggalkan kosong untuk memulai pada akar sumber. URL S3 termasuk bucket.';
	@override String get preferences => 'preferensi';
	@override String get timePosition => 'Posisi';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Subtitle Track';
	@override String get none => 'Tidak Ada';
	@override String get fullscreen => 'Layar penuh';
	@override String get syncLocation => 'Fold Sinkronisasi Progress (optional)';
	@override String get syncLocationHint => 'Sebuah folder khusus WebDAV untuk PlezyNG status. menggunakan tulisan bersyarat; media tetap tidak berubah.';
	@override String get audiobooks => 'Buku Audio';
	@override String get comics => 'Komik';
	@override String get scan => 'Scan untuk buku dan media';
	@override String get browserReader => 'Pembaca Terbuka';
	@override String get browserReaderHelp => 'Membaca dibuka di browser Anda.Jadilah PlezyNG terbuka untuk menyimpan lokasi dan catatan Anda.';
	@override String get on => 'pada';
	@override String get advancedSetup => 'Aplikasi pendaftaran';
	@override String get microsoftSignIn => 'Mendaftar dengan Microsoft';
	@override String get zoomIn => 'Zoom dalam';
	@override String get zoomOut => 'Zoom keluar';
	@override String get fitPage => 'Halaman yang sesuai';
	@override String get fitWidth => 'Berkelanjutan';
	@override String get actualSize => 'Ukuran saat ini';
	@override String get goToPage => 'Pergi ke halaman';
	@override String get goToSection => 'Pergi ke bab';
	@override String pageRange({required Object count}) => 'Masukkan nomor dari 1 ke ${count}';
	@override String get pageLayout => 'Layout halaman';
	@override String get automatic => 'otomatis';
	@override String get singlePage => 'Satu halaman';
	@override String get twoPages => '2 Halaman';
	@override String get readingDirection => 'Membaca arah';
	@override String get leftToRight => 'ke kiri ke kanan';
	@override String get rightToLeft => 'Kanan ke kiri';
	@override String get letterSpacing => 'Surat yang Spasial';
	@override String get wordSpacing => 'Kata ruang';
	@override String get readerControlsHelp => 'Rentangkan dua jari atau gunakan kontrol zoom untuk memperbesar halaman. Seret untuk menggeser halaman. Ctrl/⌘ dengan + atau − mengubah zoom; Ctrl/⌘ dengan 0 meresetnya. Page Up dan Page Down membalik halaman.';
	@override String get imagePage => 'Komik halaman';
	@override String get resetReader => 'Reset preferensi bacaan';
	@override String get zoom => 'Penutup';
	@override String get useFiles => 'Menggunakan file dan buku';
	@override String get cancelScan => 'Batalkan scan';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Batas unduhan offline';
	@override String get offlineQuotaHelp => 'Tetapkan ruang maksimum yang digunakan oleh salinan offline, file terimpor, dan muat turun. Mengurangi batas tidak menghapus salinan sedia ada.';
	@override String get offlineStorageUsage => 'Penyimpanan Offline';
	@override String get reservedStorage => 'disimpan';
	@override String get downloadQueue => 'Mengunduh Queue';
	@override String get downloadRunning => 'Download';
	@override String get downloadQueued => 'Menunggu';
	@override String get downloadPaused => 'beristirahat';
	@override String get downloadFailed => 'Keperluan Retri';
	@override String get importing => 'Imporsi';
	@override String get importInterrupted => 'Import terputus · menghapus untuk jelas';
	@override String get errorQuotaExceeded => 'Meningkatkan batas atau menghapus salinan yang dimuat turun.';
	@override String get errorStorageLow => 'Tidak ada penyimpanan perangkat gratis yang cukup untuk mempertahankan reserve yang dilindungi.';
	@override String get errorStorageUnavailable => 'PlezyNG tidak dapat memeriksa penyimpanan perangkat gratis, jadi penulisan dihentikan.';
	@override String get removeDownloadJob => 'Menghapus download';
	@override String get downloadAlreadyComplete => 'Download ini selesai sebelum dapat dihapus. item sekarang tersedia offline.';
	@override String get confirmRemoveDownloadJob => 'Menghapus download ini dan menyingkirkan data yang diunduh secara parsial? posisi dan catatan Anda akan tetap.';
}

// Path: lending
class _Translations$lending$id extends Translations$lending$en {
	_Translations$lending$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Perpustakaan Publik';
	@override String get add => 'Tambahkan perpustakaan';
	@override String get other => 'Perpustakaan lain';
	@override String get libraryName => 'Nama perpustakaan';
	@override String get libraryUrl => 'Situs Perpustakaan';
	@override String get libraryUrlHint => 'Gunakan katalog perpustakaan atau halaman masuknya.';
	@override String get intro => 'Pinjam dari perpustakaan Anda.Tahan buku Anda dekat.';
	@override String get handoff => 'Masuk, pinjam, dan baca dengan aman melalui layanan perpustakaan Anda sendiri.';
	@override String get openService => 'Perpustakaan Terbuka';
	@override String get findLibrary => 'Temukan perpustakaan';
	@override String get search => 'Mencari buku dan penulis';
	@override String get catalogue => 'Katalog';
	@override String get loans => 'Pinjaman';
	@override String get holds => 'Reservasi';
	@override String get signIn => 'Mendaftar dengan perpustakaan Anda';
	@override String get waiting => 'Selesaikan pendaftaran di browser Anda, kemudian kembali ke sini.';
	@override String get cancel => 'Batal';
	@override String get disconnect => 'Menghapus perpustakaan';
	@override String get disconnectMessage => 'Hapus perpustakaan ini dari profil ini? Pinjaman dan reservasi Anda tetap tersimpan di perpustakaan.';
	@override String get getBook => 'Dapatkan Buku';
	@override String get checkAvailability => 'Periksa ketersediaan';
	@override String get available => 'tersedia untuk pinjaman';
	@override String get unavailable => 'Saat ini tidak tersedia';
	@override String get borrow => 'Pinjam';
	@override String get placeHold => 'Buat reservasi';
	@override String get returnBook => 'Kembali Cepat';
	@override String get cancelHold => 'Batalkan reservasi';
	@override String get confirmBorrow => 'Apakah Anda meminjam judul ini dari perpustakaan Anda?';
	@override String get confirmReturn => 'Kembalikan judul ini sekarang? Anda mungkin perlu meminjamnya lagi untuk melanjutkan.';
	@override String get confirmCancelHold => 'Batalkan reservasi Anda untuk judul ini?';
	@override String get email => 'Pastikan pemberitahuan email';
	@override String due({required Object date}) => 'Batas pengembalian: ${date}';
	@override String queue({required Object position}) => 'Posisi ${position} dalam baris';
	@override String get empty => 'Belum ada judul di sini.';
	@override String get openLibraryNote => 'Temukan katalog Open Library. opsi bacaan dan pinjaman ditampilkan di halaman setiap judul.';
	@override String get more => 'Layar Lebih';
	@override String get gateway => 'Perpustakaan Servis';
	@override String get gatewayHint => 'Disediakan oleh perpustakaan Anda atau administrator PlezyNG.';
	@override String get advanced => 'Integrasi perpustakaan';
	@override String get loadLibraries => 'Pilih perpustakaan Anda';
	@override String get expired => 'Pinjaman ini sudah habis.';
	@override String get updated => 'Perpustakaan yang diperbarui';
	@override String get continueService => 'Terus di Layanan';
	@override String get comingSoon => 'In-app pinjaman · Datang segera';
	@override String get comingSoonDescription => 'Anda dapat menggunakan perpustakaan Anda di Libby saat kami selesai menghubungkannya.';
	@override String get suspendHold => 'Tangguhkan reservasi';
	@override String get resumeHold => 'Lanjutkan reservasi';
	@override String get suspendMessage => 'Pertahankan posisi Anda dalam antrean dan biarkan pembaca berikutnya meminjam salinan ini? Anda dapat melanjutkan reservasi nanti.';
	@override String get resumeMessage => 'Lanjutkan reservasi ini agar perpustakaan dapat menawarkan salinan berikutnya yang tersedia?';
	@override String get editEmail => 'Perubahan email pemberitahuan';
}

// Path: audiobook
class _Translations$audiobook$id extends Translations$audiobook$en {
	_Translations$audiobook$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Membaca & Mendengarkan Sync';
	@override String get syncHelp => 'Tetap membaca posisi, mendengarkan posisi, status penyelesaian, buku catatan dan catatan di seluruh perangkat Anda. Pilih akun penyimpanan yang disertakan dan gunakan kode sinkron yang sama pada setiap perangkat. Membaca dan mendengarkan tetap terpisah.';
	@override String get addSyncSource => 'Tambah Google Drive, OneDrive, Dropbox, WebDAV atau S3 ke File & Buku terlebih dahulu.';
	@override String get syncDestination => 'Sinkronisasi akun penyimpanan';
	@override String get syncFolder => 'Sinkron folder atau prefix';
	@override String get syncFolderHelp => 'Gunakan folder terpisah yang ada di dalam sumber WebDAV Anda, atau prefix S3 khusus. file buku tidak pernah diubah.';
	@override String get syncCode => 'Kode Sinkronisasi';
	@override String get syncCodeHelp => 'Buat kode pada perangkat pertama Anda, kemudian masukkan kode itu pada perangkat lain Anda. simpan salinan pribadi: itu adalah kunci untuk status enkripsi Anda. Gunakan kode yang berbeda untuk setiap orang.';
	@override String get showCode => 'Menampilkan atau menyembunyikan kode sink';
	@override String get newSyncCode => 'Mencipta kode sink baru';
	@override String get saveSync => 'Simpan dan Sync';
	@override String get disableSync => 'Hentikan Sync pada perangkat ini';
	@override String get syncSourceDisconnect => 'Menghapus sumber ini akan mematikan membaca dan mendengarkan sync di sini. file sync tersulit akan tetap di penyedia.';
	@override String get syncReconnect => 'Menghubungkan kembali akun penyimpanan';
	@override String lastSynced({required Object time}) => 'Terakhir disinkronkan di ${time}';
	@override String get syncPrivacy => 'Hanya kemajuan dan catatan yang disulitkan disimpan. file audio dan ebook, token akun dan kata sandi tidak dimuat naik. Google Drive dan OneDrive menggunakan penyimpanan aplikasi; Dropbox menggunakan PlezyNG Sync. Membolehkan penyegerakan dapat meminta akses penulisan tambahan. Sementara diaktifkan, tujuan ini memiliki penyegerakan kemajuan; kemajuan server tetap terpisah. Mengalihkan penyegerakan mengekalkan sejarah lokal dan keadaan remote.';
	@override String get syncConflicts => 'Pilih tempat untuk kembali';
	@override String get conflictHelp => 'Perubahan-perubahan ini dilakukan secara independen. pilih posisi atau bookmark versi untuk tetap. timestamp kemudian atau peratusan yang lebih tinggi tidak secara otomatis menang.';
	@override String syncDevice({required Object device}) => 'Perangkat ${device}';
	@override String get syncUnknownDevice => 'peralatan yang tidak diketahui';
	@override String get deletedBookmark => 'Bookmark yang dihapus';
	@override String get finished => 'selesai';
	@override String readingPosition({required Object percent}) => 'Membaca · ${percent}%';
	@override String get chapterTimeline => 'Bab Kemajuan';
	@override String get bookTimeline => 'Buku Lengkap Kemajuan';
	@override String bookRemaining({required Object time}) => 'Waktu yang tersisa dalam buku ini: ${time}';
	@override String chapterRemaining({required Object time}) => 'Waktu yang tersisa dalam bab ini: ${time}';
	@override String get unknownRemaining => 'Total waktu tersedia sebagai bagian yang dimainkan';
	@override String get undoSeek => 'yang terakhir dicari';
	@override String get customSpeed => 'Kecepatan playback yang disesuaikan';
	@override String get speedHelp => 'Pilih kecepatan dari 0.25× hingga 4×.';
	@override String get apply => 'Mengaplikasikan';
	@override String get customSleep => 'Waktu Tidur Custom';
	@override String get sleepMinutes => '1 menit (1 – 1440)';
	@override String sleepChapters({required Object count}) => 'Berhenti setelah ${count} bab';
	@override String get extendSleep => 'Tambahkan 5 menit';
	@override String sleepRemaining({required Object time}) => 'Waktu Tidur: ${time}';
	@override String get useDefaults => 'Gunakan kontrol pendengaran ini untuk buku baru';
	@override String get librarySort => 'Berbagai Buku';
	@override String get sortTitle => 'Judul';
	@override String get sortAuthor => 'Penulis';
	@override String get sortNarrator => 'narator';
	@override String get sortSeries => 'Serangkaian perintah';
	@override String get sortRecent => 'Baru-baru ini dibuka';
	@override String get statusFilter => 'Status bacaan';
	@override String get statusAll => 'Semua buku';
	@override String get statusNew => 'Tidak dimulai';
	@override String get statusProgress => 'dalam kemajuan';
	@override String get statusFinished => 'selesai';
	@override String get goToTime => 'Pergi ke Waktu';
	@override String get timeHelp => 'Waktu: menit: detik, atau menit: detik';
	@override String get recoveryHelp => 'Ekspor salinan yang disulitkan baru-baru ini sebelum memindahkan atau memperbaiki data sink. Import bergabung dengan keadaan saat ini; mereka tidak pernah mengganti sejarah sink lokal.';
	@override String get recoveryExport => 'Mengekspor file pemulihan yang disulitkan';
	@override String get recoveryImport => 'Mengimport file pemulihan yang disulitkan';
	@override String get recoveryImportConfirm => 'Menggabungkan file pemulihan yang disulitkan ini dengan posisi bacaan dan catatan saat ini? sejarah yang ada akan disimpan. perpustakaan berbagi dan ID item tidak termasuk; menetapkan ID yang sepadan pada setiap perangkat sebelum mengimpor.';
	@override String get recoveryExported => 'File pemulihan yang disulitkan disimpan.';
	@override String get recoveryImported => 'Data pemulihan digabungkan.';
}

// Path: sourceSetup
class _Translations$sourceSetup$id extends Translations$sourceSetup$en {
	_Translations$sourceSetup$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Sertifikat server tersimpan';
	@override String get nfsEndpointInvalid => 'Masukkan URL NFS, misalnya nfs://nas:2049/export.';
	@override String get dlnaNone => 'Tidak ada server DLNA yang ditemukan. Masukkan URL deskripsi perangkat secara manual.';
	@override String get dlnaServers => 'Server media DLNA';
	@override String get dlnaUnavailable => 'Penemuan DLNA tidak tersedia di jaringan ini. Masukkan URL deskripsi perangkat secara manual.';
	@override String get dlnaSearching => 'Mencari server DLNA di jaringan lokal';
	@override String get networkSearching => 'Mencari di jaringan lokal…';
	@override String get dlnaDiscover => 'Temukan server DLNA';
	@override String get dlnaHelp => 'Penemuan bergantung pada multicast jaringan lokal. Jika tidak ada server yang muncul, masukkan URL deskripsi perangkatnya di atas.';
	@override String get dlnaRoot => 'ID objek DLNA; kosongkan untuk menggunakan akar perangkat.';
	@override String get passwordOrKey => 'Masukkan kata sandi atau tambahkan kunci privat di bawah.';
	@override String get sshFingerprint => 'Sidik jari SHA256 kunci host SSH';
	@override String get sshFingerprintHelp => 'Verifikasi dengan administrator server. Di server, jalankan ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub dan gunakan nilai SHA256-nya.';
	@override String get sshFingerprintKeep => 'Kosongkan untuk mempertahankan sidik jari yang disematkan saat ini, atau masukkan sidik jari server yang baru.';
	@override String get sshAuthentication => 'Autentikasi SSH dengan kunci publik';
	@override String get sshAuthenticationHelp => 'Opsional; autentikasi kata sandi juga didukung.';
	@override String get privateKey => 'Kunci privat (format PEM atau OpenSSH)';
	@override String get privateKeyPassphrase => 'Frasa sandi kunci privat';
	@override String get nfsMountPort => 'Port TCP layanan mount NFS';
	@override String get nfsMountPortHelp => 'Bawaan: 20048';
	@override String get nfsUserId => 'ID pengguna NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Bawaan: 1000. Gunakan ID yang diizinkan oleh ekspor NFS di NAS.';
	@override String get nfsGroupId => 'ID grup NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Bawaan: 1000. Gunakan ID grup yang diizinkan oleh ekspor NFS di NAS.';
	@override String get nfsEncryption => 'Wajibkan NFS terenkripsi (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Wajibkan TLS 1.3 untuk NFS dan layanan mount. Jika NAS tidak mendukungnya, koneksi ditolak.';
	@override String get nfsTrustCertificate => 'CA NFS khusus atau sertifikat server (PEM, opsional)';
	@override String get nfsTrustHelp => 'Kosongkan untuk sertifikat yang dipercaya perangkat ini. Jika perlu, tambahkan sertifikat CA privat atau sertifikat server yang ditandatangani sendiri; namanya harus cocok dengan host pada URL NFS.';
	@override String get nfsTrustInvalid => 'Gunakan sertifikat CA atau server dalam format PEM. Jangan sertakan kunci privat.';
	@override String get addTrustCertificate => 'Tambahkan sertifikat kepercayaan khusus';
	@override String get replaceTrustCertificate => 'Ganti sertifikat khusus yang tersimpan';
	@override String get nfsTlsHelp => 'RPC-with-TLS menggunakan port NFS dan layanan mount biasa serta memerlukan dukungan RFC 9289 pada NAS. TLS 1.3 wajib digunakan. Nama host atau IP harus cocok dengan sertifikat. AUTH_SYS UID/GID tetap berlaku di dalam saluran terenkripsi.';
	@override String get clientCertificate => 'Sertifikat klien (opsional)';
	@override String get clientCertificateHelp => 'Memungkinkan NAS mengautentikasi klien ini; ID AUTH_SYS tetap bergantung pada kebijakan ekspor NFS di NAS.';
	@override String get savedIdentity => 'Identitas klien yang tersimpan akan digunakan.';
	@override String get replaceIdentity => 'Ganti identitas klien yang tersimpan';
	@override String get chooseIdentity => 'Pilih identitas klien PKCS#12';
	@override String get identityPassphrase => 'Frasa sandi identitas klien';
	@override String get identityPassphraseHelp => 'Kosongkan jika file tidak memiliki frasa sandi.';
	@override String get removeIdentity => 'Hapus identitas klien yang tersimpan';
	@override String get identityStorageHelp => 'Identitas klien disimpan di penyimpanan kredensial sumber yang terenkripsi. Jangan ubah bagian ini untuk mempertahankan identitas yang tersimpan.';
	@override String get nfsLimitations => 'NFSv3 hanya-baca melalui TCP. Tanpa RPC-with-TLS, lalu lintas NFS tidak terenkripsi. NAS harus mengizinkan ID AUTH_SYS yang dipilih dan port klien tanpa hak istimewa (sering disebut opsi ekspor “insecure”). NFSv4 dan UDP tidak didukung.';
	@override String get nfsSetupHelp => 'Bantuan pengaturan NFS';
	@override String get nfsSetupHint => 'Periksa pengaturan ini jika koneksi tidak dapat dibuka.';
	@override String get nfsSetupDetails => 'Gunakan ekspor NFSv3 melalui TCP. Jika enkripsi diwajibkan, layanan NFS dan mount harus sama-sama mendukung RPC-with-TLS. Kosongkan sertifikat khusus untuk sertifikat server yang dipercaya perangkat ini, atau tambahkan sertifikat CA NAS atau sertifikat yang ditandatangani sendiri. Nama pada sertifikat harus cocok dengan host titik akhir. Jika NAS meminta autentikasi TLS dua arah, tambahkan identitas klien PKCS#12-nya. Terakhir, pastikan ekspor mengizinkan AUTH_SYS UID/GID yang dikonfigurasi dan kebijakan port klien.';
	@override String get ftpHelp => 'FTP menggunakan mode pasif. Gunakan ftp:// untuk FTP tanpa enkripsi, ftpes:// untuk TLS eksplisit, atau ftps:// untuk TLS (implisit pada port 990; eksplisit pada port lainnya).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Pencarian subtitel opsional untuk video mandiri.';
	@override String get apiKey => 'Kunci API';
	@override String get optionalUsername => 'Nama pengguna akun (opsional)';
	@override String get optionalPassword => 'Kata sandi akun (opsional)';
	@override String get subtitlePrivacy => 'Dapatkan kunci API dari opensubtitles.com. Pencarian mengirim judul video dan ID IMDb/TMDB yang tersedia, tidak pernah mengirim file video. Kunci dan kredensial akun opsional dienkripsi bersama sumber ini.';
	@override String get automaticMetadata => 'Metadata video daring otomatis';
	@override String get metadataPrivacy => 'Hanya mengirim judul/tahun dari nama file dan nomor episode atau ID NFO, tidak pernah mengirim media atau kredensial. Kolom NFO tetap menjadi acuan utama.';
	@override String get nfsEncryptionFailure => 'Untuk NFS terenkripsi, periksa dukungan RFC 9289 dan TLS 1.3 pada kedua layanan NAS, nama sertifikat, serta UID/GID ekspor. PlezyNG tidak akan mencoba ulang koneksi ini tanpa enkripsi.';
	@override String get sourceConnecting => 'Menghubungkan ke sumber';
	@override String get metadataSearchPrivacy => 'Pencarian judul ini dikirim ke Trakt. Yang dikirim adalah judul yang Anda masukkan, bukan video atau kredensial sumber.';
	@override String get chooseMatch => 'Pilih kecocokan';
	@override String get metadataMatchHelp => 'Periksa judul dan tahun sebelum memilih. Trakt menerima judul pencarian; video tetap berada di sumbernya.';
	@override String get metadataNoMatches => 'Tidak ditemukan judul yang cocok secara daring. Coba judul lain.';
	@override String get metadataSearch => 'Cari metadata daring';
	@override String get metadataLoading => 'Mencari detail film dan acara TV secara daring…';
	@override String get metadataFromTrakt => 'Metadata daring dari Trakt';
	@override String get metadataNoAutomaticMatch => 'Tidak ditemukan kecocokan judul otomatis. Cari judulnya untuk memilih kecocokan.';
	@override String get metadataFailed => 'Metadata daring tidak dapat dimuat. Pemutaran dan detail lokal tetap tersedia.';
	@override String get videoDetailsLoading => 'Memuat detail video';
	@override String get subtitleKeyRequired => 'Kunci API OpenSubtitles diperlukan';
	@override String get subtitleKeyHelp => 'Edit sumber file ini dan tambahkan kunci API OpenSubtitles di pengaturan subtitel opsionalnya.';
	@override String get subtitleSearchFailed => 'Pencarian subtitel gagal. Periksa kunci API, koneksi, dan akses layanan.';
	@override String get subtitleApplyFailed => 'Subtitel ini tidak dapat diunduh atau diterapkan. Periksa koneksi dan coba hasil lain.';
	@override String get subtitleSearch => 'Cari di OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'Pencarian menggunakan judul dan ID IMDb/TMDB yang tersedia. File video tetap berada di sumbernya. Periksa bahasa, penanda subtitel paksa atau untuk penyandang gangguan pendengaran, dan nilai sebelum memilih.';
	@override String get movieOrShow => 'Film atau acara TV';
	@override String get subtitleTitleHint => 'Masukkan judul untuk mempersempit hasil';
	@override String get subtitleLanguage => 'Bahasa subtitel';
	@override String get subtitleSearching => 'Mencari di OpenSubtitles';
	@override String get subtitleNoMatches => 'Tidak ditemukan subtitel yang cocok. Coba judul atau bahasa lain.';
	@override String get downloadSubtitle => 'Unduh subtitel';
	@override String get subtitle => 'Subtitel';
	@override String get nfsTlsRequired => 'RPC-with-TLS diperlukan';
	@override String get nfsUnencrypted => 'NFS tanpa enkripsi';
	@override String get tlsEncrypted => 'Terenkripsi dengan TLS';
	@override String get ftpPlain => 'FTP tanpa enkripsi';
	@override String get sshPinned => 'SSH terenkripsi · kunci host disematkan';
	@override String get smbEncrypted => 'Enkripsi SMB3 aktif';
	@override String get smbUnencrypted => 'Enkripsi SMB3 nonaktif';
	@override String get httpUnencrypted => 'HTTP tanpa enkripsi transport';
	@override String get checkEndpointSecurity => 'Periksa keamanan titik akhir';
	@override String fieldRequired({required Object label}) => '${label} wajib diisi.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Masukkan ${label} dari ${min} hingga ${max}.';
	@override String replaceFile({required Object name}) => 'Ganti ${name}';
	@override String selectedIdentity({required Object name}) => 'Identitas klien terpilih: ${name}';
	@override String subtitleRating({required Object rating}) => 'Nilai ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Mengunduh subtitel: ${title}';
	@override String get sharedEntryPair => 'Berpasangan item ini';
	@override String get sharedEntryPairHelp => 'Masukkan ID yang sama untuk item ini pada setiap perangkat. Gunakan pengidentifikasi perkongsian stabil atau buat satu dan salin ke item yang sesuai. Kemajuan hanya berpasangan ketika jenis file edisi, ukuran, dan pesanan sepadan. Blank menghapus peta ini.';
	@override String get sharedEntryId => 'Identifikasi item';
	@override String get generateSharedEntryId => 'Identifikasi item yang dibagikan';
	@override String get sharedLibraryId => 'ID Perpustakaan Berkongsi (optional)';
	@override String get sharedLibraryHelp => 'Gunakan ID yang sama pada perangkat yang membuka perpustakaan yang sama.ID publik ini membantu membawa kemajuan membaca dan catatan melalui koneksi sumber yang berbeda; itu bukan kata sandi.';
	@override String get sharedLibraryInvalid => 'Gunakan 8-100 huruf, angka, titik, subscores atau hyphens.';
	@override String get generateSharedLibraryId => 'Menghasilkan ID perpustakaan yang dikongsi';
	@override String get nfsReadAhead => 'NFS Read-ahead Permintaan';
	@override String get nfsReadAheadHelp => 'Lebih banyak pembaca paralel dapat meningkatkan lalu lintas pada NAS atau jaringan yang cepat. gunakan 1 jika server membatasi permintaan serentak.';
	@override String get nfsReadTest => 'Mengukur prestasi baca NFS';
	@override String get nfsReadTestHelp => 'Membaca hingga 64 MiB dari file terbesar untuk mengukur koneksi NAS ini.';
	@override String get nfsQualificationResult => 'NFS membaca pengukuran';
	@override String get nfsReadBytes => 'Data yang dibaca';
	@override String get nfsReadSpeed => 'Kecepatan yang diukur';
	@override String get nfsReadRequests => 'Baca Permintaan';
	@override String get sharedEntryConflict => 'ID item yang dikongsi ini sudah dibagi dengan item lain di perpustakaan ini. pilih ID berbeda.';
}

// Path: comics
class _Translations$comics$id extends Translations$comics$en {
	_Translations$comics$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Sesuaikan tinggi';
	@override String get readingMode => 'Mode baca';
	@override String get paged => 'Halaman';
	@override String get webtoon => 'Gulir berkelanjutan';
	@override String get coverAlone => 'Tampilkan sampul sendiri';
	@override String get splitWide => 'Bagi halaman lebar';
	@override String get splitWideHelp => 'Tampilkan setiap bagian secara terpisah sesuai urutan baca. Tampilan dua halaman berdampingan dijeda saat opsi ini aktif.';
	@override String get thumbnails => 'Thumbnail halaman';
	@override String get controlsHelp => 'Geser untuk membalik halaman. Ketuk dua kali untuk mengubah penyesuaian. Dalam gulir berkelanjutan, geser vertikal atau gunakan Page Up dan Page Down.';
	@override String get savedForComic => 'Pengaturan tampilan diingat untuk komik ini dalam profil ini.';
	@override String get readLists => 'Daftar bacaan';
	@override String get collections => 'Koleksi';
}

// Path: games
class _Translations$games$id extends Translations$games$en {
	_Translations$games$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Games';
	@override String get enable => 'Show Games for this profile';
	@override String get enableDescription => 'Discover your gaming computers and play with an embedded streaming engine.';
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
	@override String get recent => 'Recently opened';
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
	@override String get steamBetaTitle => 'Steam beta · Pyrowave';
	@override String get steamBetaDescription => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.';
	@override String get steamLibrary => 'Steam library';
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamAppId => 'Steam App ID';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
	@override String get steamLibraryHint => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.';
}

// Path: appIcon.names
class _Translations$appIcon$names$id extends Translations$appIcon$names$en {
	_Translations$appIcon$names$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'tengah malam';
	@override String get ember => 'Manusia';
	@override String get paper => 'Kertas';
	@override String get oled => 'OLED';
	@override String get line => 'garis';
	@override String get ocean => 'Lautan';
	@override String get ultraviolet => 'Ultraviolet';
	@override String get matcha => 'Pertandingan';
	@override String get sunset => 'matahari terbenam';
	@override String get gold => 'emas';
	@override String get titanium => 'Titanium';
	@override String get glass => 'kaca';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Piksel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Sticker';
	@override String get ticket => 'tiket';
	@override String get pop => 'Pop';
	@override String get strata => 'jalan';
	@override String get facet => 'Wajah';
	@override String get tilde => 'Tilda';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$id extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

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
class _Translations$common$mediaKind$id extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Pameran';
	@override String get season => 'Musim';
	@override String get episode => 'Episod';
	@override String get artist => 'Artis';
	@override String get album => 'Album';
	@override String get track => 'Trek';
	@override String get collection => 'Koleksi';
	@override String get playlist => 'Daftar Putar';
	@override String get clip => 'Fitur';
	@override String get photo => 'Foto';
	@override String get folder => 'Map';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$id extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Membuka rekomendasi dan item dari sumber penemuan yang terhubung.';
	@override String get libraries => 'Buka perpustakaan media yang terhubung.';
	@override String get liveTv => 'Buka Live TV ketika server menyediakan; jika tidak, startup jatuh kembali ke Home.';
	@override String get search => 'pencarian media terbuka.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$id extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get bg => 'latar belakang';
	@override String get surface => 'permukaan';
	@override String get outline => 'outline';
	@override String get text => 'Teks';
	@override String get textMuted => 'Teks Sekunder';
	@override String get accent => 'aksen';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$id extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Teks di latar belakang';
	@override String get textOnSurface => 'Teks di permukaan';
	@override String get textMutedOnBg => 'Teks sekunder di latar belakang';
	@override String get textMutedOnSurface => 'Teks sekunder di permukaan';
	@override String get accentOnBg => 'Fokus pada latar belakang';
	@override String get accentOnSurface => 'Fokus pada permukaan';
	@override String get labelOnAccent => 'Label tombol pada aksen';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$id extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Bermain dan beristirahat';
	@override String get volumeUp => 'Jumlah Up';
	@override String get volumeDown => 'Volume turun';
	@override String seekForward({required Object seconds}) => 'Mencari ke depan (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Mencari ke belakang (${seconds}s)';
	@override String get fullscreenToggle => 'Bersama Fullscreen';
	@override String get muteToggle => 'Bersama Mutu';
	@override String get subtitleToggle => 'Menggabungkan Subtitle';
	@override String get audioTrackNext => 'Berikut ini Audio Track';
	@override String get subtitleTrackNext => 'Subtitle selanjutnya Track';
	@override String get chapterNext => 'Bab selanjutnya';
	@override String get chapterPrevious => 'Bab sebelumnya';
	@override String get episodeNext => 'Episode Selanjutnya';
	@override String get episodePrevious => 'episode sebelumnya';
	@override String get speedIncrease => 'Meningkatkan kecepatan';
	@override String get speedDecrease => 'Menurunkan kecepatan';
	@override String get speedReset => 'Reset kecepatan';
	@override String get zoomIn => 'Zoom dalam';
	@override String get zoomOut => 'Zoom keluar';
	@override String get zoomReset => 'Atur ulang zoom';
	@override String get subSeekNext => 'Temukan Subtitle berikutnya';
	@override String get subSeekPrev => 'Temukan Subtitle sebelumnya';
	@override String get subtitleDelayIncrease => 'Penundaan Subtitle';
	@override String get subtitleDelayDecrease => 'Subtitle yang maju';
	@override String get shaderToggle => 'Bersama Shaders';
	@override String get skipMarker => 'Langkah-langkah untuk masuk / kredit';
	@override String get screenshot => 'Mengambil screenshot';
	@override String get framePrevious => 'Frame sebelumnya';
	@override String get frameNext => 'Frame selanjutnya';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$id extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Memerlukan Android 8.0 atau lebih baru';
	@override String get iosVersion => 'Memerlukan iOS 15.0 atau lebih baru';
	@override String get permissionDisabled => 'Image-in-image disabled. memungkinkan dalam pengaturan sistem.';
	@override String get notSupported => 'Perangkat tidak mendukung mode gambar-in-gambar';
	@override String get voSwitchFailed => 'gagal menukar output video untuk gambar-dalam-gambar';
	@override String get failed => 'Gambar-gambar yang gagal dimulai';
	@override String get prepareFailed => 'Gambar-gambar dalam-gambar tidak dapat disiapkan';
	@override String unknown({required Object error}) => 'Kesalahan yang terjadi: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$id extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get no => 'Simpan huruf, warna, ukuran, dan penempatan yang ditulis dalam subtitle file.';
	@override String get yes => 'Memungkinkan pengaturan gaya subtitle pemain untuk menyesuaikan subtitle ASS.';
	@override String get scale => 'Mengaplikasikan gaya pemain dan skala ukuran tertanam untuk memenuhi dimensi video.';
	@override String get force => 'Mengganti gaya ASS yang tertanam dengan gaya subtitle pemain.';
	@override String get strip => 'Menghapus format ASS tertanam dan membuat subtitle teks dengan jelas.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$id extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render pada resolusi permukaan layar penuh untuk hasil yang paling tajam.';
	@override String get video => 'Render menggunakan resolusi video sebagai referensi, yang dapat mengurangi pekerjaan pada paparan resolusi tinggi.';
	@override String get threeQuarter => 'Rendah pada 75% resolusi permukaan paparan untuk penjimatan kinerja yang sederhana.';
	@override String get half => 'Render pada 50% resolusi permukaan paparan untuk mengurangi kerja, dengan tepi yang lebih lembut.';
	@override String get third => 'Render pada satu pertiga resolusi permukaan paparan untuk mengurangi pekerjaan, dengan tepi yang lebih lembut.';
	@override String get quarter => 'Render pada satu perempat dari resolusi permukaan paparan untuk mengurangi kerja, dengan hasil yang paling lembut.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$id extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio dan Subtitle';
	@override String get libraryDisplay => 'Pustaka';
	@override String get personalMedia => 'Media pribadi';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$id extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get none => 'Seleksi secara manual';
	@override String get noneDescription => 'Jangan pernah memutar subtitle sendiri.';
	@override String get defaultMode => 'Ikuti bendera track';
	@override String get defaultModeDescription => 'Gunakan bendera default dan paksa yang disimpan di setiap jalur subtitle.';
	@override String get always => 'Selalu diizinkan';
	@override String get alwaysDescription => 'Beralih pada jalur subtitle dalam bahasa yang disukai setiap kali ada.';
	@override String get onlyForced => 'Hanya subtitle yang dipaksakan';
	@override String get onlyForcedDescription => 'Hanya mengisi jalur yang ditandai sebagai paksa.';
	@override String get smart => 'Menampilkan Audio Asing';
	@override String get smartDescription => 'Tukar subtitle hanya ketika audio berada dalam bahasa lain.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$id extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Lebih Baik Subtitle Non-SDH';
	@override String get preferSdh => 'Lebih suka subtitle SDH';
	@override String get onlySdh => 'Hanya subtitle SDH';
	@override String get onlyNonSdh => 'Hanya subtitle non-SDH';
	@override String get preferNonSdhDescription => 'Anda lebih suka subtitle standar ketika kedua versi standar dan SDH tersedia.';
	@override String get preferSdhDescription => 'Saya lebih suka subtitle SDH saat tersedia, tetapi memungkinkan subtitle standar sebagai downback.';
	@override String get onlySdhDescription => 'Gunakan subtitle SDH saja; jangan jatuh kembali ke subtitle standar.';
	@override String get onlyNonSdhDescription => 'Gunakan subtitle standar saja; mengecualikan subtitle SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$id extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Lebih suka subtitle yang tidak terikat';
	@override String get preferForced => 'Lebih suka subtitle';
	@override String get onlyForced => 'Hanya subtitle yang dipaksakan';
	@override String get onlyNonForced => 'Hanya subtitle yang tidak dipaksakan';
	@override String get preferNonForcedDescription => 'Lebih suka subtitles biasa, tetapi memungkinkan trek paksa sebagai penurunan.';
	@override String get preferForcedDescription => 'Mereka lebih suka trek paksa ketika tersedia, tetapi memungkinkan subtitle biasa sebagai downback.';
	@override String get onlyForcedDescription => 'Gunakan hanya jalur yang ditandai sebagai paksa.';
	@override String get onlyNonForcedDescription => 'Mengecualikan jalur yang ditandai sebagai paksa.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$id extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get none => 'Tidak Pernah';
	@override String get moviesAndShows => 'Film dan acara televisi';
	@override String get movies => 'Hanya film';
	@override String get shows => 'TV hanya menampilkan';
	@override String get noneDescription => 'Jangan menampilkan tanda-tanda yang dipantau.';
	@override String get moviesAndShowsDescription => 'Menampilkan tanda-tanda yang ditonton untuk film dan acara TV.';
	@override String get moviesDescription => 'Tampilkan tanda-tanda yang ditonton untuk film saja.';
	@override String get showsDescription => 'Menampilkan tanda-tanda yang ditonton untuk acara TV saja.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$id extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Pengguna dan kritikus';
	@override String get usersOnly => 'Pengguna hanya';
	@override String get criticsOnly => 'Hanya kritikan';
	@override String get nobody => 'tersembunyi';
	@override String get usersAndCriticsDescription => 'Tampilkan kedua penarafan pengguna dan penilaian kritis.';
	@override String get usersOnlyDescription => 'Tunjukkan penilaian dan ulasan yang disampaikan oleh pengguna.';
	@override String get criticsOnlyDescription => 'Tunjukkan penilaian kritis dan ulasan.';
	@override String get nobodyDescription => 'Temukan rating dan ulasan.';
}

// Path: discover.findNext
class _Translations$discover$findNext$id extends Translations$discover$findNext$en {
	_Translations$discover$findNext$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Temukan pilihan berikutnya';
	@override String get open => 'Temukan pilihan berikutnya';
	@override String get anyTime => 'Tanpa batas waktu';
	@override String get timeAvailable => 'Berapa banyak waktu yang Anda punya?';
	@override String get filters => 'Pilih yang sesuai saat ini';
	@override String get watch => 'Tonton';
	@override String get listen => 'Dengarkan';
	@override String get read => 'Baca';
	@override String finishable({required Object duration}) => 'Bisa selesai dalam ${duration}';
	@override String aboutDuration({required Object duration}) => 'Sekitar ${duration}';
	@override String nextUnit({required Object duration}) => 'Bab berikutnya · ${duration}';
	@override String totalDuration({required Object duration}) => 'Total ${duration}';
	@override String get timingVaries => 'Durasi bervariasi';
	@override String get notNow => 'Tidak sekarang';
	@override String get swipeHint => 'Geser sampul ke arah panah atau gunakan tombol di bawah.';
	@override String get saved => 'Pilihan tersimpan';
	@override String savedCount({required Object count}) => 'Pilihan tersimpan · ${count}';
	@override String get undo => 'Urungkan';
	@override String get details => 'Detail';
	@override String get noPicks => 'Belum ada pilihan';
	@override String get noPicksHint => 'Hubungkan perpustakaan atau tambahkan sumber media untuk memulai.';
	@override String get noMatches => 'Belum ada yang cocok saat ini';
	@override String get noMatchesHint => 'Coba jenis media lain atau luangkan lebih banyak waktu.';
	@override String get allDone => 'Semua pilihan sudah Anda lihat';
	@override String get allDoneHint => 'Mulai kumpulan baru untuk melihat pilihan ini lagi.';
	@override String get refresh => 'Cari kumpulan pilihan lain';
	@override String sourceReason({required Object source}) => 'Dari ${source}';
	@override String libraryReason({required Object library}) => 'Dari ${library}';
	@override String get ownedReason => 'Dari perpustakaan Anda';
	@override String get liveNow => 'Sedang tayang';
	@override String get watchLive => 'Tonton siaran langsung';
	@override String get filterAnything => 'Apa saja';
	@override String get filterWatch => 'Tonton';
	@override String get filterListen => 'Dengarkan';
	@override String get filterRead => 'Baca';
	@override String get twentyMinutes => '20 menit';
	@override String get fortyFiveMinutes => '45 menit';
	@override String get ninetyMinutes => '90 menit';
	@override String get apply => 'Terapkan';
	@override String get openFailed => 'Pilihan ini sudah tidak tersedia. Segarkan untuk memeriksa lagi.';
	@override String get changeFailed => 'Perubahan tidak dapat disimpan. Coba lagi.';
	@override String get savedLimit => 'Daftar pilihan tersimpan sudah penuh. Hapus satu pilihan untuk menyimpan yang lain.';
	@override String get chooseHint => 'Buka judul, simpan untuk nanti, atau lewati.';
	@override String get howItWorks => 'Cara menggunakan';
	@override String get notNowHelp => 'Lewati judul ini untuk saat ini. Judul tetap ada di pustaka Anda.';
	@override String get saveHelp => 'Simpan ke pilihan tersimpan profil ini di perangkat ini. Menyimpan tidak mengunduh judul.';
	@override String get openHelp => 'Pilih sampul untuk melihat detail. Gunakan tindakan utama untuk memutar, membaca, atau membuka judul.';
	@override String get controlsHelp => 'Keyboard atau remote: fokuskan tombol, lalu tekan Enter atau Pilih. Urungkan mengembalikan pilihan terakhir Anda.';
	@override String get artworkLoading => 'Memuat gambar…';
	@override String get artworkUnavailable => 'Gambar tidak tersedia';
	@override String get savedFeedback => 'Ditambahkan ke pilihan tersimpan';
	@override String get skippedFeedback => 'Dilewati untuk saat ini';
	@override String get releaseToConfirm => 'Lepaskan untuk mengonfirmasi';
	@override String get remoteHint => 'Saat sampul terfokus: ← / → memilih · Pilih: detail · ↑ / ↓ pindah fokus';
}

// Path: discover.person
class _Translations$discover$person$id extends Translations$discover$person$en {
	_Translations$discover$person$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get born => 'lahir';
	@override String get died => 'meninggal';
	@override String get birthplace => 'Tempat lahir';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (usia ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (usia ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$id extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Disarankan';
	@override String get browse => 'Jelajah';
	@override String get collections => 'Koleksi';
	@override String get playlists => 'Daftar putar';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$id extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'kelompok';
	@override String get all => 'Semua';
	@override String get movies => 'Film';
	@override String get shows => 'Acara TV';
	@override String get seasons => 'Musim';
	@override String get episodes => 'Semua episode';
	@override String get artists => 'Artis';
	@override String get albums => 'Album';
	@override String get tracks => 'Trek';
	@override String get folders => 'Folder';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$id extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Aliran';
	@override String get year => 'Tahun';
	@override String get contentRating => 'Penilaian konten';
	@override String get tag => 'Tag';
	@override String get unwatched => 'tidak diperhatikan';
	@override String get unplayed => 'Belum dimainkan';
	@override String get favorites => 'Favorit';
	@override String get filePath => 'Jalur berkas';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$id extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Judul';
	@override String get dateAdded => 'Tanggal ditambahkan';
	@override String get releaseDate => 'Tanggal rilis';
	@override String get rating => 'Peringkat';
	@override String get communityRating => 'Peringkat komunitas';
	@override String get criticRating => 'Kritis Rating';
	@override String get userRating => 'Rating Pengguna';
	@override String get datePlayed => 'Tanggal dimainkan';
	@override String get playCount => 'Hitung Putaran';
	@override String get productionYear => 'Tahun Produksi';
	@override String get runtime => 'Durasi';
	@override String get officialRating => 'Rating resmi';
	@override String get premiereDate => 'Tanggal Tayang Perdana';
	@override String get startDate => 'Tanggal dimulai';
	@override String get airTime => 'Jam tayang';
	@override String get studio => 'Studio yang';
	@override String get random => 'Acak';
	@override String get dateShared => 'Tanggal yang dibagi';
	@override String get latestEpisodeAirDate => 'Episode Terakhir Air Date';
	@override String get lastEpisodeDateAdded => 'Episode Terakhir Ditambahkan';
	@override String get dateDownloaded => 'Tanggal yang diunduh';
	@override String get size => 'Ukuran';
	@override String get library => 'Pustaka';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$id extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get include => 'Termasuk';
	@override String get exclude => 'Pengecualian';
	@override String get any => 'Apa saja';
	@override String get yes => 'Ya';
	@override String get no => 'Tidak';
	@override String not({required Object value}) => 'Tidak ada ${value}';
	@override String valueCount({required Object count}) => '${count} dipilih';
	@override String valueCountExcluded({required Object count}) => '${count} dikecualikan';
	@override String get searchValues => 'nilai pencarian';
	@override String get noValues => 'Tidak ada nilai';
	@override String get matchContains => 'Konteks';
	@override String get matchNotContains => 'Tidak mengandung';
	@override String get matchIs => 'adalah';
	@override String get matchIsNot => 'Tidak ada';
	@override String get matchBeginsWith => 'Mulai dengan';
	@override String get matchEndsWith => 'Berakhir dengan';
	@override String get textHint => 'Jenis untuk Match';
	@override String get from => 'dari';
	@override String get to => 'Untuk';
	@override String range({required Object from, required Object to}) => '${from} sampai ${to}';
	@override String atLeast({required Object value}) => '${value} dan di atas';
	@override String atMost({required Object value}) => 'Jumlah : ${value}';
	@override String dateLastDays({required Object count}) => '${count} hari yang lalu';
	@override String get dateLastYear => 'Tahun lalu';
	@override String dateOlderThanDays({required Object count}) => 'Lebih dari ${count} hari';
	@override String get dateOlderThanYear => 'Lebih dari 1 tahun';
}

// Path: libraries.selection
class _Translations$libraries$selection$id extends Translations$libraries$selection$en {
	_Translations$libraries$selection$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Pilih item';
	@override String selectedCount({required Object count}) => '${count} dipilih';
	@override String get actions => 'Tindakan Seleksi';
	@override String get confirmDescendants => 'Ini mengubah semua episode dalam acara dan musim yang dipilih.';
	@override String get confirmUnwatched => 'Ini juga membersihkan kemajuan playback untuk item yang dipilih.';
	@override String confirmCount({required Object count}) => 'Jumlah item yang dipilih: ${count}.';
	@override String completed({required Object count}) => 'Item yang diperbarui: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Dikemas kini ${succeeded}; gagal ${failed}. item gagal tetap terpilih.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$id extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Mengelola eksplorasi shelves';
	@override String get manageDescription => 'Pilih dan jadikan daftar dari akun MDBList Anda';
	@override String get description => 'Pilih daftar film dan TV publik dari akun MDBList Anda. membuat atau menyalin daftar di MDBList, kemudian memperbarui.';
	@override String get selected => 'Seleksi Seleksi';
	@override String get available => 'Daftar akun yang tersedia';
	@override String get noLists => 'Tidak ada film atau daftar televisi publik yang dikembalikan. membuat atau menyalin daftar di MDBList, kemudian memperbarui.';
	@override String get displayName => 'Nama Shelf Display';
	@override String get nameHint => 'Tinggalkan kosong untuk menggunakan nama daftar sumber.';
	@override String get add => 'Tambahkan shelf';
	@override String get save => 'Menyelamatkan shelter';
	@override String moveUp({required Object title}) => 'Move ${title} ke atas';
	@override String moveDown({required Object title}) => 'Move ${title} ke bawah';
	@override String get unavailable => 'Daftar ini tidak tersedia.Tarik balik atau menghapus shell dalam pengaturan.';
	@override String get rateLimited => 'MDBList batas permintaan telah dicapai. silakan mundur kemudian.';
	@override String get loadFailed => 'Tidak bisa mengisi rak. periksa koneksi dan retry Anda.';
	@override String get saveFailed => 'Saya tidak bisa menyimpan shelves. silakan retry.';
	@override String get accountChanged => 'Akun atau profil berubah. buka seting ini lagi.';
	@override String get settingsUnreadable => 'Tab yang disimpan tidak dapat dibaca. pilih daftar Anda lagi untuk menggantikan pengaturan ini.';
}

// Path: explore.rows
class _Translations$explore$rows$id extends Translations$explore$rows$en {
	_Translations$explore$rows$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Pengawasan';
	@override String get recommendedMovies => 'Film yang disarankan';
	@override String get recommendedShows => 'Persembahan yang disarankan';
	@override String get trendingMovies => 'Film yang Trend';
	@override String get trendingShows => 'Tendangan menunjukkan';
	@override String get popularMovies => 'Film populer';
	@override String get popularShows => 'Pameran populer';
	@override String get trendingAnime => 'Tindakan Anime';
	@override String get suggestedAnime => 'Anime yang disarankan';
	@override String get airingAnime => 'Anime teratas yang sedang tayang';
	@override String get popularAnime => 'Anime yang paling populer';
	@override String get trending => 'Trend yang';
	@override String get upcomingMovies => 'Film yang akan datang';
	@override String get upcomingShows => 'Pertunjukan yang akan datang';
}

// Path: explore.status
class _Translations$explore$status$id extends Translations$explore$status$en {
	_Translations$explore$status$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get airing => 'udara';
	@override String get ended => 'Berakhir';
	@override String get canceled => 'dibatalkan';
	@override String get upcoming => 'Akan datang';
}

// Path: explore.badge
class _Translations$explore$badge$id extends Translations$explore$badge$en {
	_Translations$explore$badge$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} populer';
	@override String rankAiring({required Object n}) => '#${n} airing';
	@override String rankRated({required Object n}) => '#${n} dicatat';
	@override String rankTrending({required Object n}) => '#${n} trending';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} di ${season}';
	@override String watchingNow({required Object n}) => '${n} menonton';
	@override String get available => 'Tersedia';
	@override String get partiallyAvailable => 'Sebagian tersedia';
	@override String get availableIn4k => '4K tersedia';
	@override String get requested => 'yang diminta';
	@override String get pendingApproval => 'Menunggu kelulusan';
	@override String get processing => 'Pemrosesan';
	@override String get declined => 'dikecualikan';
	@override String get requestFailed => 'Permintaan gagal';
	@override String get requested4k => '4K yang diminta';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} musim';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} dalam ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Selanjutnya di ${duration}';
	@override String episodesShort({required Object n}) => '${n} ep.';
	@override String minutesPerEpisode({required Object n}) => '${n} mnt/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$id extends Translations$explore$stats$en {
	_Translations$explore$stats$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} disenaraikan';
	@override String viewersDay({required Object n}) => '${n} menonton hari ini';
	@override String viewersWeek({required Object n}) => '${n} menonton minggu ini';
	@override String viewersMonth({required Object n}) => '${n} dilihat bulan ini';
	@override String viewersYear({required Object n}) => '${n} dilihat tahun ini';
	@override String viewersAllTime({required Object n}) => '${n} penonton';
	@override String planning({required Object n}) => '${n} perencanaan untuk menonton';
	@override String favorited({required Object n}) => '${n} favorit';
	@override String dropRate({required Object percent}) => '${percent} mengunduhnya';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentar',
	);
	@override String votes({required Object n}) => '${n} mengundi';
	@override String watching({required Object n}) => '${n} menonton';
	@override String completed({required Object n}) => '${n} selesai';
	@override String onHold({required Object n}) => '${n} pada hold';
	@override String dropped({required Object n}) => '${n} ditinggalkan';
}

// Path: explore.season
class _Translations$explore$season$id extends Translations$explore$season$en {
	_Translations$explore$season$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Musim dingin';
	@override String get spring => 'Musim semi';
	@override String get summer => 'musim panas';
	@override String get fall => 'jatuh';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$id extends Translations$explore$format$en {
	_Translations$explore$format$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get tv => 'televisi';
	@override String get tvShort => 'TV pendek';
	@override String get movie => 'Film';
	@override String get special => 'Khususnya';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Musik';
	@override String get other => 'Lainnya';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$id extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get original => 'asli';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'novel cahaya';
	@override String get novel => 'Novel';
	@override String get visualNovel => 'novel visual';
	@override String get game => 'Permainan';
	@override String get webComic => 'Web Komik';
	@override String get musicRelease => 'Musik';
	@override String get otherMedia => 'Lainnya';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$id extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Aktor';
	@override String get director => 'Direktur';
	@override String get writer => 'Penulis';
	@override String get producer => 'Produsen';
	@override String get creator => 'pencipta';
	@override String get composer => 'Komposer';
}

// Path: explore.relation
class _Translations$explore$relation$id extends Translations$explore$relation$en {
	_Translations$explore$relation$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Praktek';
	@override String get sequel => 'Selanjutnya';
	@override String get sideStory => 'Halaman cerita';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Versi Alternatif';
	@override String get summary => 'Kesimpulan';
	@override String get parentStory => 'Kisah Orangtua';
	@override String get adaptation => 'Adaptasi';
	@override String get other => 'terkait';
}

// Path: explore.detail
class _Translations$explore$detail$id extends Translations$explore$detail$en {
	_Translations$explore$detail$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Judul asli';
	@override String get alsoKnownAs => 'Juga dikenal sebagai';
	@override String get studios => 'Studio';
	@override String get country => 'Negara';
	@override String get language => 'Bahasa';
	@override String get released => 'dibebaskan';
	@override String get physicalRelease => 'pada disk';
	@override String get ended => 'Berakhir';
	@override String addedOn({required Object date}) => 'Ditambahkan ${date}';
	@override String get yourRating => 'rating Anda';
	@override String get budget => 'anggaran';
	@override String get revenue => 'Kantor Kotak';
	@override String get contentAdvisory => 'Usia panduan';
	@override String get tags => 'Label';
	@override String get revealSpoilerTags => 'Menampilkan spoiler tag';
	@override String get links => 'Kiri';
	@override String get watchOn => 'Lihatlah';
	@override String get watchTrailer => 'Lihat Trailer';
	@override String openOn({required Object site}) => 'Terbuka pada ${site}';
	@override String get crew => 'Kapal';
	@override String get ratings => 'Peringkat';
	@override String get schedule => 'Jadwal';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: 'Direkomendasikan oleh ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengguna',
	);
	@override String recommendedBy({required Object who}) => 'Diterima oleh ${who}';
	@override String favoritedBy({required Object who}) => 'disukai oleh ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} belum diunggah';
	@override String recommendedByPercent({required Object percent}) => 'Dipertimbangkan oleh ${percent} penonton';
	@override String get relatedTitles => 'Judul terkait';
	@override String get background => 'latar belakang';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$id extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Mulai lebih awal (second)';
	@override String get endLate => 'Berakhir terlambat (second)';
	@override String get newOnly => 'Hanya episode baru';
	@override String get anyChannel => 'Rekaman di setiap saluran';
	@override String get anyTime => 'Rekor pada setiap waktu';
	@override String get skipInLibrary => 'Luncurkan episode sudah di perpustakaan';
	@override String get keepUpTo => 'Episod yang harus dipantau';
	@override String get keepUpToHint => '0 memegang setiap episode';
}

// Path: music.discography
class _Translations$music$discography$id extends Translations$music$discography$en {
	_Translations$music$discography$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles dan EPs';
	@override String get live => 'Langsung';
	@override String get compilations => 'Kompilasi';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$id extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} permainan yang ditekan';
	@override String get playbackStarted => 'Playback dimulai';
	@override String paused({required Object name}) => '${name} ditangguhkan';
	@override String get playbackPaused => 'Playback beristirahat';
	@override String jumpedTo({required Object name, required Object position}) => '${name} melompat ke ${position}';
	@override String roomJumpedTo({required Object position}) => 'Diperoleh pada ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} menetapkan kecepatan ke ${speed}';
	@override String speedChanged({required Object speed}) => 'Kecepatan yang ditetapkan pada ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} dimulai ${title}';
	@override String mediaStarted({required Object title}) => 'Sekarang bermain ${title}';
	@override String stoppedMedia({required Object name}) => '${name} berhenti video';
	@override String get mediaStopped => 'Video itu berhenti';
	@override String waitingFor({required Object name}) => 'Menunggu untuk ${name} ...';
	@override String get waitingForSomeone => 'Menunggu seseorang untuk menangkap ...';
	@override String get finished => 'selesai';
	@override String hostChangedTo({required Object name}) => '${name} sekarang menjadi tuan rumah';
	@override String get youAreNowHost => 'Sekarang kau adalah tuan rumah';
	@override String joined({required Object name}) => '${name} menyertai';
	@override String left({required Object name}) => '${name} keluar';
	@override String get controlRefused => 'Hanya tuan rumah yang dapat mengontrol playback.';
	@override String get searchFailed => 'Beberapa server tidak dapat dicari untuk video ruangan';
	@override String get playBlocked => 'Bermain Press untuk Mulai';
	@override String get shareFailed => 'Saya tidak bisa berbagi video ini dengan ruangan';
	@override String get downloadNotShared => 'Download tidak dibagi dengan ruangan saat server mereka offline';
	@override String get openFailed => 'Tidak bisa membuka video kamar';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$id extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Pengantin mengakhiri kamar';
	@override String get kicked => 'Anda diusir dari ruangan';
	@override String get expired => 'Ruang itu habis';
	@override String get replaced => 'Anda bergabung dengan ruangan ini pada perangkat lain';
	@override String get lost => 'Kehilangan koneksi ke ruangan';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$id extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Kod memiliki 6 huruf dan angka, tanpa 0, 1, I, L atau O.';
	@override String get roomNotFound => 'Tidak ada ruang yang memiliki kode itu. mungkin telah berakhir.';
	@override String get roomFull => 'Ruang itu penuh.';
	@override String get roomLocked => 'Pemilik rumah itu menutup kamar itu.';
	@override String get relayFull => 'Lihat Bersama sibuk sekarang. coba lagi nanti.';
	@override String get unreachable => 'Tidak bisa mencapai jam bersama relay. periksa koneksi Anda.';
	@override String get rateLimited => 'Terlalu banyak usaha. tunggu sebentar dan coba lagi.';
	@override String get clientBlocked => 'Versi PlezyNG ini tidak dapat menggunakan relay. update aplikasi.';
	@override String get forbidden => 'Hanya tuan rumah yang bisa melakukannya.';
	@override String get notInRoom => 'Anda tidak berada di ruangan.';
	@override String get alreadyInRoom => 'Anda sudah berada di kamar.';
	@override String get resumeFailed => 'Aku tidak bisa masuk ke kamar.';
	@override String get unsupported => 'Relay tidak mendukung hal ini.';
	@override String get generic => 'Ada yang salah, coba lagi.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$id extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Download akan berhenti saat Anda meninggalkan aplikasi';
	@override String get bannerDegraded => 'Download latar belakang dapat terbatas';
	@override String get bannerAction => 'Detail';
	@override String get sheetTitle => 'Download latar belakang diblokir';
	@override String get sheetTitleDegraded => 'Download latar belakang dapat terbatas';
	@override String get sheetIntro => 'Android mencegah PlezyNG dari mengunduh dengan aman di latar belakang.';
	@override String get sheetIntroDegraded => 'Perangkat Anda membatasi kapan PlezyNG dapat dimuat turun di latar belakang.';
	@override String get reasonBackgroundRestricted => 'Penggunaan latar belakang PlezyNG terbatas. menetapkan penggunaan bateri atau latar belakangnya pada "Tidak terbatas".';
	@override String get reasonStandbyRestricted => 'Android telah menempatkan PlezyNG dalam keadaan standby terbatas.';
	@override String get reasonDownloadChannelBlocked => 'Pemberitahuan muat turun terputus, sehingga kemajuan dan kontrol mungkin tidak tersedia.';
	@override String get reasonNotificationsDisabled => 'Notifikasi dihapus. pada Android 13 atau lebih baru, mereka diperlukan untuk download latar belakang yang panjang.';
	@override String get reasonDataSaver => 'Data Saver ada, yang memblokir download latar belakang pada data mobile. download harus tetap berjalan di Wi-Fi.';
	@override String get reasonOemUnknown => 'Muat turun berulang kali berhenti sementara PlezyNG berada di latar belakang. periksa pengaturan penggunaan baterai atau latar belakang PlezyNG.';
	@override String get openSettings => 'Tetapan Terbuka';
	@override String get stillNotWorking => 'Bantuan khusus perangkat';
	@override String get stillNotWorkingDescription => 'Lihat langkah-langkah untuk perangkat Anda, atau kirim log dari Settings › Lihat log jika masalah berlanjut.';
	@override String get dialogTitle => 'Download mungkin tidak selesai';
	@override String get dialogDownloadAnyway => 'Download dengan cara apapun';
	@override String get dialogFixFirst => 'Tetaplah ini dulu';
	@override String get statusTile => 'Latar Belakang Downloads';
	@override String get statusOk => 'Dirancang untuk berjalan di latar belakang';
	@override String get statusBlocked => 'Diblokir oleh sistem pengaturan';
	@override String get statusDegraded => 'Terbatas oleh sistem pengaturan';
	@override String get statusUnknown => 'Belum diperiksa';
	@override String get settingsUnavailable => 'Tidak bisa membuka pengaturan sistem pada perangkat ini';
	@override String get linkUnavailable => 'Tidak bisa membuka dontkillmyapp.com pada perangkat ini';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$id extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get library => 'Pustaka';
	@override String get collections => 'Koleksi';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$id extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Mulai dari remote server.';
	@override String get hostAddress => 'Alamat tamu';
	@override String get connected => 'terhubung';
	@override String get serverRunning => 'Remote server aktif';
	@override String get serverStopped => 'Remote server terhenti';
	@override String get serverRunningDescription => 'perangkat mobile di jaringan Anda dapat terhubung ke aplikasi ini';
	@override String get serverStoppedDescription => 'Memulai server untuk memungkinkan perangkat mobile untuk terhubung';
	@override String get usePhoneToControl => 'Gunakan perangkat seluler Anda untuk mengontrol aplikasi ini';
	@override String get startServer => 'Memulai Server';
	@override String get stopServer => 'Hentikan Server';
	@override String get minimize => 'Minimalisasikan';
	@override String get manualAddressHint => 'Alamat koneksi manual :';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$id extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'PlezyNG perangkat dengan akun yang sama Plex muncul di sini';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Menghubungkan...';
	@override String get searchingForDevices => 'Mencari perangkat...';
	@override String get noDevicesFound => 'Tidak ada perangkat yang ditemukan di jaringan Anda';
	@override String get noDevicesHint => 'Buka PlezyNG di desktop dan gunakan Wi-Fi yang sama';
	@override String get availableDevices => 'Perangkat yang tersedia';
	@override String get manualConnection => 'Manual koneksi';
	@override String get cryptoInitFailed => 'Tidak bisa memulai koneksi yang aman. mendaftar di Plex pertama.';
	@override String get validationHostRequired => 'Silakan masukkan alamat host';
	@override String get validationHostFormat => 'Format harus IP:port (misalnya 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Menggunakan jaringan yang sama pada kedua perangkat.';
	@override String get sessionNotFound => 'Perangkat tidak ditemukan. pastikan PlezyNG berjalan pada host.';
	@override String get authFailed => 'Kedua perangkat membutuhkan akun yang sama Plex.';
	@override String failedToConnect({required Object error}) => 'Tidak dapat dihubungkan: ${error}';
	@override String get codeTitle => 'Kode Pasangan';
	@override String get codeDescription => 'Masukkan kode yang ditunjukkan di Companion Remote pada perangkat host. Kedua perangkat harus menggunakan versi yang mendukung pasangan yang aman.';
	@override String get codeInvalid => 'Masukkan semua 32 huruf dan angka dari kode tuan rumah.';
	@override String get updateRequired => 'Update kedua perangkat ke versi yang mendukung pasangan yang aman.';
	@override String get hostDescription => 'Masukkan kode ini sekali pada setiap remote. tetaplah privasi: ini memberikan kontrol profil ini.';
	@override String get resetCode => 'Mengatur kode paring';
	@override String get resetDescription => 'Menghilangkan semua remote dan membuat kode baru. setiap remote akan perlu untuk berpasangan lagi.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$id extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Apakah Anda ingin menyingkirkan dari sesi remote?';
	@override String get reconnecting => 'Menghubungkan kembali...';
	@override String attemptOf({required Object current}) => 'Mencoba ${current} dari 5';
	@override String get retryNow => 'Kembali sekarang';
	@override String get tabRemote => 'jarak jauh';
	@override String get tabPlay => 'Putar';
	@override String get tabMore => 'Lebih banyak';
	@override String get menu => 'Menu yang';
	@override String get tabNavigation => 'Tab Navigasi';
	@override String get tabDiscover => 'Temukan';
	@override String get tabLibraries => 'Pustaka';
	@override String get tabSearch => 'Cari';
	@override String get tabDownloads => 'Unduhan';
	@override String get tabSettings => 'Pengaturan';
	@override String get previous => 'Sebelumnya';
	@override String get playPause => 'Bermain dan beristirahat';
	@override String get next => 'Berikutnya';
	@override String get seekBack => 'Mencari kembali';
	@override String get stop => 'Berhenti';
	@override String get seekForward => 'Mencari FWD';
	@override String get volume => 'Jumlah';
	@override String get volumeDown => 'Turun';
	@override String get volumeUp => 'Ke atas';
	@override String get fullscreen => 'Layar penuh';
	@override String get subtitles => 'Subtitel';
	@override String get audio => 'Audio yang';
	@override String get searchHint => 'Mencari di Desktop';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$id extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Tidak ditemukan interaksi jaringan';
	@override String get authenticationFailed => 'Authenticasi gagal';
	@override String serverStartFailed({required Object error}) => 'Tidak berhasil memulai server remote: ${error}';
	@override String commandFailed({required Object error}) => 'Tidak dapat mengirimkan perintah jarak jauh: ${error}';
	@override String get joinTimedOut => 'Waktu untuk bergabung dengan sesi';
	@override String get failedToConnectAnyAddress => 'Tidak dapat terhubung ke alamat apa pun';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Hubungan hilang setelah ${attempts} percobaan';
	@override String get connectionLost => 'Hubungan yang hilang';
}

// Path: services.names
class _Translations$services$names$id extends Translations$services$names$en {
	_Translations$services$names$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$id extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Menghubungkan Simkl';
	@override String get subtitle => 'Simkl adalah penarikan metode login yang menggunakan koneksi ini. re-connecting membuka simkl.com untuk meluluskan PlezyNG — PlezyNG tidak pernah melihat kata sandi Anda. sejarah jam Anda tetap pada Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$id extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Mengaktifkan PlezyNG pada ${service}';
	@override String get instructions => 'Periksa kode QR, atau kunjungi alamat di bawah dan masukkan kode ini:';
	@override String openToActivate({required Object service}) => 'Buka ${service} untuk mengaktifkan';
	@override String get copyCode => 'Mengaktifkan kode';
	@override String get waitingForAuthorization => 'Menunggu izin...';
	@override String get codeCopied => 'Kode yang disalin';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$id extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Mendaftar di ${service}';
	@override String get body => 'Memindai kode QR ini atau buka URL pada perangkat apa pun.';
	@override String openToSignIn({required Object service}) => 'Buka ${service} untuk mendaftar';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$id extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Mendaftar di URL';
	@override String get urlCopied => 'URL yang disalin';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$id extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get title => 'Perpustakaan filter';
	@override String get subtitleAllSyncing => 'Sinkronisasi Semua Perpustakaan';
	@override String get subtitleNoneSyncing => 'Tidak ada sinergi';
	@override String subtitleBlocked({required Object count}) => '${count} dikunci';
	@override String subtitleAllowed({required Object count}) => '${count} diizinkan';
	@override String get mode => 'Mode filter';
	@override String get modeBlacklist => 'Daftar hitam';
	@override String get modeWhitelist => 'Daftar putih';
	@override String get modeHintBlacklist => 'Sinkronkan setiap perpustakaan kecuali yang diperiksa di bawah.';
	@override String get modeHintWhitelist => 'Simak hanya perpustakaan yang diperiksa di bawah ini.';
	@override String get libraries => 'Pustaka';
	@override String get noLibraries => 'Tidak ada perpustakaan yang tersedia';
	@override String get modeDescription => 'Pilih apakah perpustakaan yang disemak diblokir dari sinergi atau adalah satu-satunya perpustakan yang bersinkron.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$id extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$id._(TranslationsId root) : this._root = root, super.internal(root);

	final TranslationsId _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Sinkronkan episode dan film yang ditonton dengan akun Trakt Anda.';
	@override String get mal => 'Sinkronkan daftar anime dan perhatikan kemajuan dengan MyAnimeList.';
	@override String get anilist => 'Sync anime daftar dan menonton kemajuan dengan AniList.';
	@override String get simkl => 'Sync menonton film, acara TV, dan anime dengan Simkl.';
	@override String get mdblist => 'Tunjukkan rating dan daftar MDBList dalam rekomendasi dan Temukan.';
}

/// The flat map containing all translations for locale <id>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsId {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'Transmisikan ke perangkat',
			'cast.searching' => 'Mencari alat-alat yang terbuat dari ...',
			'cast.connectedTo' => ({required Object device}) => 'Menghubungkan ke ${device}',
			'cast.device' => 'Perangkat transmisi',
			'cast.readyToCast' => 'Siap mentransmisikan',
			'cast.subtitle' => 'Subtitel',
			'cast.serverNotAvailable' => 'Media server tidak tersedia.',
			'cast.stopCasting' => 'Hentikan transmisi',
			'cast.castToDevice' => 'Transmisikan ke perangkat',
			'cast.noEpisodeAvailable' => 'Tidak ada episode yang tersedia untuk ditayangkan.',
			'cast.startFailed' => 'Tidak bisa memulai casting. periksa server dan coba lagi.',
			'automation.noActivePlayback' => 'Tidak ada sesi video aktif untuk dikendalikan.',
			'automation.profileNotFound' => 'Yang Plezy profil tidak dapat ditemukan.',
			'notifications.newEpisodeTitle' => 'episode baru',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'Aplikasi Ikon',
			'appIcon.defaultIcon' => 'Bawaan',
			'appIcon.current' => 'Ikon saat ini',
			'appIcon.locked' => 'Akses seumur hidup yang diperlukan',
			'appIcon.lockedHint' => 'Mulai percobaan 7 hari Anda atau membuka kunci PlezyNG selama hidup Anda untuk menggunakan ikon alternatif.',
			'appIcon.changeFailed' => 'Tidak bisa mengubah ikon aplikasi',
			'appIcon.launcherHint' => 'Ikon baru muncul di layar rumah Anda setelah Anda meninggalkan PlezyNG.',
			'appIcon.tvLauncherHint' => 'Banner baru muncul setelah Anda meninggalkan PlezyNG. Android TV dapat terus menampilkan yang lama sampai TV kembali.',
			'appIcon.names.midnight' => 'tengah malam',
			'appIcon.names.ember' => 'Manusia',
			'appIcon.names.paper' => 'Kertas',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'garis',
			'appIcon.names.ocean' => 'Lautan',
			'appIcon.names.ultraviolet' => 'Ultraviolet',
			'appIcon.names.matcha' => 'Pertandingan',
			'appIcon.names.sunset' => 'matahari terbenam',
			'appIcon.names.gold' => 'emas',
			'appIcon.names.titanium' => 'Titanium',
			'appIcon.names.glass' => 'kaca',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Piksel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Sticker',
			'appIcon.names.ticket' => 'tiket',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'jalan',
			'appIcon.names.facet' => 'Wajah',
			'appIcon.names.tilde' => 'Tilda',
			'appIcon.description' => 'Pilih ikon yang ditunjukkan oleh peluncuran perangkat Anda. previews menunjukkan bagaimana setiap opsi terlihat.',
			'auth.signInWithPlex' => 'Mendaftar dengan Plex',
			'auth.showQRCode' => 'Menampilkan QR Code',
			'auth.authenticate' => 'autentik',
			'auth.authenticationTimeout' => 'Pengesahan sudah selesai, silakan coba lagi.',
			'auth.scanQRToSignIn' => 'Scan kode QR ini untuk mendaftar',
			'auth.waitingForAuth' => 'Menunggu untuk autentikasi ... Mendaftar dari browser Anda.',
			'auth.useBrowser' => 'Menggunakan browser',
			'auth.or' => 'atau',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Menghubungkan ke ${product}',
			'auth.quickConnect' => 'Koneksi Cepat',
			'auth.useQuickConnect' => 'Gunakan Koneksi Cepat',
			'auth.quickConnectInstructions' => 'Buka Quick Connect di Jellyfin dan masukkan kode ini.',
			'auth.quickConnectWaiting' => 'Menunggu kelulusan...',
			'auth.quickConnectCancel' => 'Batal',
			'auth.quickConnectExpired' => 'Koneksi Cepat kedaluwarsa. Coba lagi.',
			'auth.localDataRecoveryRequired' => 'PlezyNG tidak dapat memulihkan data masuk lokal dan data pemutaran yang tertunda dengan aman. Silakan masuk lagi.',
			'auth.pinCheckRejected' => 'Pengesahan PIN Plex ditolak',
			'auth.connectToDirectPlex' => 'Menghubungkan ke server lokal Plex',
			'common.cancel' => 'Batal',
			'common.save' => 'Simpan',
			'common.close' => 'Tutup',
			'common.closeMiniPlayer' => 'Berdekatan dengan Mini Player',
			'common.closeWorkspaceWindow' => 'Jendela yang dekat',
			'common.returnToFullView' => 'Kembali ke Full View',
			'common.manageMediaSessions' => 'Mengelola sesi media',
			'common.hideMediaSessions' => 'Menyembunyikan sesi media',
			'common.mediaSessions' => 'Sesi Media',
			'common.mediaSessionsHint' => 'Pilih untuk membawa sesi ke depan.Park menyembunyikan jendela tetapi tetap terbuka.Kembali membuka dalam pandangan penuh; dekat menutupnya.',
			'common.sessionInWorkspace' => 'Dalam ruang kerja',
			'common.sessionParked' => 'parkir',
			'common.sessionFullscreen' => 'layar penuh',
			'common.switchToNextWindow' => 'Swap dengan jendela berikutnya',
			'common.moveWindow' => 'Menggerakkan jendela',
			'common.finishMovingWindow' => 'Menutup jendela bergerak',
			'common.moveWindowHint' => 'Tekan panjang dan tarik jendela untuk memindahkannya. kontrol ini juga memungkinkan pergerakan kunci arrow.',
			'common.movingWindowHelp' => 'Menarik untuk bergerak · Menarik kunci disesuaikan · Enter saves · Escape cancles',
			'common.resizeWindow' => 'Menarik jendela',
			'common.resizeWindowHint' => 'Tarik handuk ini atau gunakan kunci anak panah untuk memutar ulang jendela.',
			'common.workspaceWindowHint' => 'Gunakan kontrol pergerakan atau tekanan panjang dan tarik untuk bergerak. gunakan handuk resize untuk resize.',
			'common.workspacePaneHint' => 'Pilih panel ini untuk fokus. gunakan kontrol layar penuh untuk memperluasnya.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Jendela sesi: ${title}',
			'common.workspaceTitleHint' => 'Pilih untuk fokus. tarik bar judul untuk bergerak; gunakan tombol layar penuh untuk memperluas.',
			'common.moveToSessionTray' => 'Bergerak ke sesi tray',
			'common.moveToSessionTrayHint' => 'Kees sesi ini tersedia tanpa menampilkan jendela.',
			'common.closeSessionHint' => 'Menutup jendela ini dan mengakhiri sesi.',
			'common.sideBySideLayout' => 'Beralih ke sisi-by-side layout',
			'common.floatingWindows' => 'Switch untuk mengalir jendela',
			'common.clear' => 'jelas',
			'common.reset' => 'Atur Ulang',
			'common.later' => 'Kemudian',
			'common.submit' => 'Kirim',
			'common.confirm' => 'mengkonfirmasi',
			'common.retry' => 'Coba Lagi',
			'common.logout' => 'Log keluar',
			'common.unknown' => 'Tidak Dikenal',
			'common.refresh' => 'Segarkan',
			'common.yes' => 'Ya',
			'common.no' => 'Tidak',
			'common.delete' => 'Hapus',
			'common.edit' => 'Sunting',
			'common.shuffle' => 'Acak',
			'common.addTo' => 'Tambah ke...',
			'common.createNew' => 'Membuat yang baru',
			'common.connect' => 'Sambung',
			'common.disconnect' => 'Memutuskan',
			'common.play' => 'Putar',
			'common.pause' => 'Jeda',
			'common.resume' => 'Lanjutkan',
			'common.error' => 'Kesalahan',
			'common.search' => 'Cari',
			'common.home' => 'rumah',
			'common.back' => 'Kembali',
			'common.settings' => 'Pengaturan',
			'common.mute' => 'Bisukan',
			'common.ok' => 'OK',
			'common.off' => 'Nonaktif',
			'common.options' => 'Pilihan',
			'common.seasonNumber' => ({required Object number}) => 'Musim ini ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episode ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Bab ${number}',
			'common.reconnect' => 'Menghubungkan kembali',
			'common.viewAll' => 'Lihat semua',
			'common.checkingNetwork' => 'Jaringan pemeriksaan...',
			'common.loadingServers' => 'Layanan Layanan Layanan...',
			'common.connectingToServers' => 'Menghubungkan ke server',
			'common.startingOfflineMode' => 'Mulai dari mode offline.',
			'common.loading' => 'Mengisi...',
			'common.fullscreen' => 'Layar penuh',
			'common.exitFullscreen' => 'Penampilan Full Screen',
			'common.pressBackAgainToExit' => 'Tekan kembali untuk keluar',
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
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'Pameran',
			'common.mediaKind.season' => 'Musim',
			'common.mediaKind.episode' => 'Episod',
			'common.mediaKind.artist' => 'Artis',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Trek',
			'common.mediaKind.collection' => 'Koleksi',
			'common.mediaKind.playlist' => 'Daftar Putar',
			'common.mediaKind.clip' => 'Fitur',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Map',
			'screens.licenses' => 'Lisensi',
			'screens.switchProfile' => 'Profil Switch',
			'screens.subtitleStyling' => 'Subtitle gaya',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Log',
			'update.available' => 'Update yang tersedia',
			'update.versionAvailable' => ({required Object version}) => 'Versi ${version} tersedia',
			'update.currentVersion' => ({required Object version}) => 'Saat ini: ${version}',
			'update.skipVersion' => 'Hapus versi ini',
			'update.viewRelease' => 'Lihat Release',
			'update.latestVersion' => 'Anda berada di versi terbaru',
			'update.checkFailed' => 'gagal memeriksa update',
			'appAccess.title' => 'Cobalah setiap fitur gratis selama 7 hari',
			'appAccess.description' => 'Memulai percobaan tujuh hari dengan akses penuh ke setiap fitur PlezyNG. tidak ada biaya selama percobaan dan tidak ada langganan. setelah percobaan, satu pembelian seumur hidup pada harga toko Anda membuka PlezyNG seumur hidup.',
			'appAccess.trialEndedDescription' => 'Unlock setiap fitur di PlezyNG untuk hidup dengan satu pembelian pada harga toko Anda.',
			'appAccess.startTrial' => 'Mulai ujian gratis 7 hari saya',
			'appAccess.trialActive' => '7 hari ujian full-feature Anda aktif.',
			'appAccess.trialEnded' => 'Pengadilan 7 hari telah berakhir',
			'appAccess.trialStartFailed' => 'Saya tidak bisa menyimpan percobaan pada perangkat ini. silakan coba lagi.',
			'appAccess.lifetimeTitle' => 'PlezyNG dibebaskan untuk hidup',
			'appAccess.lifetimeBody' => 'Terima kasih! Anda memiliki akses seumur hidup ke setiap fitur PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG akses seumur hidup',
			'appAccess.manageDescription' => 'Cobalah setiap fitur gratis selama 7 hari, kemudian membuka semua untuk hidup dengan satu pembayaran pada harga toko Anda.',
			'appAccess.buy' => ({required Object price}) => 'Menghapus setiap fitur untuk ${price}',
			'appAccess.loadingPrice' => 'Harga toko yang terjangkau...',
			'appAccess.retryPrice' => 'Harga Retry Lookup',
			'appAccess.restore' => 'Restorasi pembelian seumur hidup',
			'appAccess.pending' => 'Pembelian Anda sedang menunggu pembayaran atau kelulusan. akses seumur hidup dibuka sebaik saja toko menyelesaikannya.',
			'appAccess.storeUnavailable' => 'Pastikan bahwa Anda terdaftar di toko dan pembelian diizinkan pada perangkat ini.',
			'appAccess.productNotFound' => 'Pembukaan PlezyNG seumur hidup belum tersedia di toko ini.',
			'appAccess.productQueryFailed' => 'Tidak bisa menagih harga toko. periksa koneksi Anda dan coba lagi.',
			'appAccess.purchaseFailed' => 'Pembelian tidak berjalan. coba lagi.',
			'appAccess.restoreFailed' => 'Tidak bisa sampai ke toko untuk memulihkan pembelian Anda. coba lagi.',
			'appAccess.nothingToRestore' => 'Nombor PlezyNG pembelian seumur hidup ditemukan untuk akun toko ini.',
			'settings.title' => 'Pengaturan',
			'settings.supportDeveloper' => 'Dukungan PlezyNG',
			'settings.supportDeveloperDescription' => 'Memberi dukungan untuk pengembangan',
			'settings.lifetimeAccess' => 'PlezyNG akses seumur hidup',
			'settings.language' => 'Bahasa',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'penampilan',
			'settings.detailPage' => 'Detail halaman',
			'settings.themeSongsEnabled' => 'Mainkan lagu tema',
			'settings.themeSongsEnabledDescription' => 'Mainkan lagu tema yang tersedia sambil melihat detail media.',
			'settings.themeSongVolume' => 'Tema Lagu Volume',
			'settings.videoPlayback' => 'Video dari Playback',
			'settings.videoPlaybackDescription' => 'Mengatur perilaku playback',
			'settings.advanced' => 'Canggih',
			'settings.episodePosterMode' => 'Gaya Poster',
			'settings.seriesPoster' => 'Poster seri',
			'settings.seasonPoster' => 'Poster Musim',
			'settings.episodeThumbnail' => 'Gambar mini',
			'settings.showHeroSectionDescription' => 'Tampilkan konten carousel pada layar rumah',
			'settings.secondsLabel' => 'sekunder',
			'settings.minutesLabel' => 'Minit',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'M',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Masukkan nilai (${min}-${max})',
			'settings.systemTheme' => 'Sistem',
			'settings.lightTheme' => 'Cahaya',
			'settings.darkTheme' => 'gelap',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Manusia',
			'settings.glacierTheme' => 'Gletser',
			'settings.forestTheme' => 'Hutan',
			'settings.plumTheme' => 'Ungu prem',
			'settings.paperTheme' => 'Kertas',
			'settings.libraryDensity' => 'Ketebalan perpustakaan',
			'settings.displayScale' => 'Skala Display',
			'settings.compact' => 'Kompak',
			'settings.comfortable' => 'nyaman',
			'settings.gridSpacing' => 'Jaringan Spacing',
			'settings.gridSpacingTight' => 'Rapat',
			'settings.gridSpacingNormal' => 'Biasa',
			'settings.gridSpacingSpacious' => 'ruang',
			'settings.tvCornerSpotlightBackdrop' => 'Spesifikasi Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'Tunjukkan karya seni di sudut kanan atas bukannya mengisi layar',
			'settings.viewMode' => 'Lihat mode',
			'settings.gridView' => 'Jaringan',
			'settings.listView' => 'Listing',
			'settings.showHeroSection' => 'Menampilkan Hero Section',
			'settings.showHomeBackdrop' => 'Menampilkan rumah backdrop artwork',
			'settings.showHomeBackdropDescription' => 'Tunjukkan karya seni besar di balik rantai rumah yang ditampilkan',
			'settings.contentScreensaverEnabled' => 'Menggunakan Screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Tunjukkan karya seni layar penuh setelah aplikasi menjadi idle',
			'settings.contentScreensaverDelay' => 'Memulai screensaver setelah',
			'settings.contentScreensaverLibraries' => 'Perpustakaan Screensaver',
			'settings.contentScreensaverLibrariesDescription' => 'Pilih perpustakaan mana yang menyediakan karya seni screensaver.Jika tidak ada yang dipilih, karya seni dari semua perpustakaan digunakan.',
			'settings.contentScreensaverAllLibraries' => 'Semua pustaka',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} perpustakaan terpilih',
			'settings.contentScreensaverNoLibraries' => 'Tidak ada perpustakaan media yang terhubung.',
			'settings.contentScreensaverDismissHint' => 'Tekan tombol atau ketik untuk membatalkan',
			'settings.newEpisodeNotifications' => 'Pemberitahuan episode baru',
			'settings.newEpisodeNotificationsDescription' => 'Peringatan ketika episode baru ditambahkan ke sebuah acara Anda terperangkap di. periksa saat Plezy terbuka.',
			'settings.continueWatchingRowSize' => 'Lanjutkan perhatikan ukuran baris',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} kartu',
			'settings.rowSizeCompact' => 'Kompak',
			'settings.rowSizeStandard' => 'Standar',
			'settings.rowSizeLarge' => 'Besar',
			'settings.continueWatchingAction' => 'Lanjutkan pengawasan aksi',
			'settings.continueWatchingPlay' => 'Putar',
			'settings.continueWatchingDetails' => 'Detail Terbuka',
			'settings.episodeAction' => 'Episode Aksi',
			'settings.episodePlay' => 'Putar',
			'settings.episodeDetails' => 'Detail Terbuka',
			'settings.useGlobalHubs' => 'Menggunakan Home Layout',
			'settings.useGlobalHubsDescription' => 'Tampilkan hub rumah bersatu. jika tidak, gunakan rekomendasi perpustakaan.',
			'settings.showServerNameOnHubs' => 'Menampilkan nama server di Hubs',
			'settings.showServerNameOnHubsDescription' => 'Selalu menunjukkan nama server dalam judul hub.',
			'settings.groupLibrariesByServer' => 'Perpustakaan Perpustakaan Server',
			'settings.groupLibrariesByServerDescription' => 'Perpustakaan sidebar kelompok di bawah setiap server media.',
			'settings.alwaysKeepSidebarOpen' => 'Selalu Tetap Sidebar Terbuka',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidebar tetap diperluas dan area konten disesuaikan untuk memenuhi',
			'settings.showUnwatchedCount' => 'Menampilkan Unwatched Count',
			'settings.showUnwatchedCountDescription' => 'Menampilkan episode yang tidak ditonton di acara dan musim',
			'settings.showWatchedIndicators' => 'Menampilkan indikator yang diperhatikan',
			'settings.showWatchedIndicatorsDescription' => 'Menampilkan tanda kontrol pada film, acara, dan episode yang ditonton',
			'settings.showEpisodeNumberOnCards' => 'Tunjukkan Episode Number pada Kartu',
			'settings.showEpisodeNumberOnCardsDescription' => 'Tunjukkan musim dan nomor episode pada kartu episode',
			'settings.showSeasonPostersOnTabs' => 'Menampilkan Poster Musim di Tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'Tunjukkan poster setiap musim di atas tabnya',
			'settings.tvFullCardLayout' => 'Kartu televisi penuh',
			'settings.tvFullCardLayoutDescription' => 'Gunakan kartu TV hanya dengan nama-nama aktris yang ditinggalkan',
			'settings.focusGlow' => 'Fokus pada Glow',
			'settings.focusGlowDescription' => 'Menggerakkan cahaya lembut di sekitar kartu fokus',
			'settings.visualEffects' => 'Efek visual',
			'settings.visualEffectsAuto' => 'mobil',
			'settings.visualEffectsAutoDescription' => 'Mengurangi efek secara otomatis pada perangkat rendah daya',
			'settings.visualEffectsFull' => 'penuh',
			'settings.visualEffectsReduced' => 'dikurangi',
			'settings.visualEffectsReducedDescription' => 'Kurang animasi dan karya seni resolusi rendah',
			'settings.hideSpoilers' => 'Temukan Spoilers untuk Unwatched Episodes',
			'settings.hideSpoilersDescription' => 'Blur miniatur dan deskripsi untuk episode yang tidak ditonton',
			'settings.playerBackend' => 'Pembuat Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardware Dekodasi',
			'settings.hardwareDecodingDescription' => 'Menggunakan akselerasi perangkat keras saat tersedia',
			'settings.playbackBuffer' => 'Pemain Buffer',
			'settings.playbackBufferAuto' => 'Mobil yang disarankan (Rekomendasi)',
			'settings.playbackBufferLarge' => 'Besar',
			'settings.playbackBufferExtraLarge' => 'Ekstra besar',
			'settings.playbackBufferDescription' => 'Buffer lebih banyak terhadap koneksi yang tidak stabil. juga terbatas oleh Buffer Size.',
			'settings.streamBufferSize' => 'Ukuran Buffer',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Berapa banyak video yang harus dimuat ke depan saat bermain langsung. transcodes berhenti di buffer transcode server sendiri. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Menggantikan Playback Buffer saat ditempatkan, ditangkap di setengah batas memori aplikasi',
			'settings.streamBufferMegabytes' => 'Megabita',
			'settings.defaultQualityTitle' => 'kualitas default',
			'settings.cellularQualityTitle' => 'Kualitas pada selular',
			'settings.remoteQualityTitle' => 'Kualitas Streaming Jarak Jauh',
			'settings.remoteQualitySameAsDefault' => 'Sama dengan kualitas default',
			'settings.cellularQualitySameAsDefault' => 'Sama dengan kualitas default',
			'settings.directPlayCoveredQuality' => 'Mainkan Video Kecil dengan Kualitas Asli',
			'settings.directPlayCoveredQualityDescription' => 'Mainkan video secara langsung di bawah batas kualitas, bukannya menyulitkan mereka',
			'settings.videoCodecs' => 'Video kode',
			'settings.videoCodecsDescription' => 'Kodek yang tidak disemak disekodkan oleh server',
			'settings.videoCodecsAlwaysAccepted' => 'Selalu diterima',
			'settings.musicQualityTitle' => 'Kualitas Musik',
			'settings.subtitleStyling' => 'Subtitle gaya',
			'settings.subtitleStylingDescription' => 'Menampilkan Subtitle',
			'settings.smallSkipDuration' => 'Kecil Skik Durasi',
			'settings.largeSkipDuration' => 'Jangka Panjang Skip',
			'settings.rewindOnResume' => 'Kembali ke Resume',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} detik', ), 
			'settings.defaultSleepTimer' => 'Tidur Tidur Default',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} menit', ), 
			'settings.rememberTrackSelections' => 'Ingat seleksi track per show/movie',
			'settings.chooseTracksBeforePlayback' => 'Pilih audio dan subtitle sebelum playback',
			'settings.chooseTracksBeforePlaybackDescription' => 'Pilih sumber audio dan subtitle track sebelum setiap video dimulai.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Selalu tunjukkan subtitle pada perangkat ini',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Jika server tidak memiliki subtitle yang dipilih, pilih track secara lokal. ini tidak pernah mengubah preferensi server.',
			'settings.autoDownloadPreferredSubtitle' => 'FATCH Lost Favorit-bahasa subtitle',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Pilih subtitle yang tersedia dalam bahasa favorit Anda secara lokal.Jika tidak ada, minta server untuk menangkap satu ketika didukung.',
			'settings.rememberTrackSelectionsDescription' => 'Simpan audio dan pilihan subtitle dengan show atau film pada perangkat ini',
			'settings.rememberTrackSelectionsBackendRule' => 'Bekerja secara lokal dengan Plex, Jellyfin, dan Emby; Plex dan Jellyfin juga dapat menyimpan seleksi pada server',
			'settings.followServerTrackSelections' => 'Gunakan seleksi trek per episode server',
			'settings.followServerTrackSelectionsDescription' => 'Pada perubahan episode, gunakan audio dan subtitle yang dipilih pada server bukannya membawa di atas pilihan saat ini.',
			'settings.resumeMusicOnLaunch' => 'Ingat sesi musik',
			'settings.resumeMusicOnLaunchDescription' => 'Buka kembali lagu terakhir berhenti di mana ia meninggalkan ketika aplikasi dimulai',
			'settings.showChapterMarkersOnTimeline' => 'Tampilkan catatan bab pada mencari bar',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segmen yang mencari bar di bab batas',
			'settings.specialsOrdering' => 'Spesialisasi dalam episode order',
			'settings.specialsOrderingDescription' => 'Di mana spesial bermain dalam urutan jam acara',
			'settings.specialsOrderingServer' => 'Perintah server',
			'settings.specialsOrderingAirDate' => 'Interleave dengan tanggal udara',
			'settings.specialsOrderingLast' => 'Setelah musim biasa',
			'settings.clickVideoTogglesPlayback' => 'Klik pada video untuk bermain / istirahat',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klik video untuk memainkan/berhenti daripada menampilkan kontrol.',
			'settings.videoPlayerControls' => 'Video Player Pengendalian',
			'settings.keyboardShortcuts' => 'Keyboard pendek',
			'settings.keyboardShortcutsDescription' => 'Cara menyesuaikan keyboard shortcuts',
			'settings.videoPlayerNavigation' => 'Navigasi Video Player',
			'settings.videoPlayerNavigationDescription' => 'Gunakan kunci pistol untuk menavigasi kontrol pemutar video',
			'settings.watchTogetherRelay' => 'Lihat bersama Reli',
			'settings.watchTogetherRelayDescription' => 'Public Open Watch Party meluncurkan kecuali Anda menetapkan sendiri',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Masukkan URL dasar relai HTTP atau HTTPS yang valid.',
			'settings.crashReporting' => 'Laporan kecelakaan',
			'settings.crashReportingDescription' => 'Mengirim laporan kecelakaan untuk membantu memperbaiki aplikasi',
			'settings.debugLogging' => 'Pencatatan debug',
			'settings.debugLoggingDescription' => 'Memungkinkan loging terperinci untuk penyelesaian masalah',
			'settings.viewLogs' => 'Lihat log',
			'settings.viewLogsDescription' => 'Lihat Aplikasi Logs',
			'settings.clearImageCache' => 'Cache gambar yang jelas',
			'settings.clearImageCacheDescription' => 'Gambar dapat dimuat lebih lambat sampai dimuat kembali.',
			'settings.clearImageCacheSuccess' => 'Image cache diselesaikan dengan sukses',
			'settings.resetSettings' => 'Restorasi Settings',
			'settings.resetSettingsDescription' => 'Mengembalikan pengaturan default. ini tidak dapat dibatasi.',
			'settings.resetSettingsSuccess' => 'Setting Reset dengan sukses',
			'settings.backup' => 'Cadangan',
			'settings.exportSettings' => 'Pengaturan Eksport',
			'settings.exportSettingsDescription' => 'Simpan preferensi Anda ke file',
			'settings.exportSettingsSuccess' => 'Pengaturan Ekspor',
			'settings.importSettings' => 'Pengaturan Import',
			'settings.importSettingsDescription' => 'Memulihkan preferensi dari file',
			'settings.importSettingsConfirm' => 'Ini akan menggantikan pengaturan Anda saat ini. lanjutkan?',
			'settings.importSettingsSuccess' => 'Pengaturan yang diimpor',
			'settings.importSettingsInvalidFile' => 'Fail ini tidak valid PlezyNG pengeksportan pengaturan',
			'settings.importSettingsNoUser' => 'Mendaftar sebelum mengimport pengaturan',
			'settings.cloudBackup' => 'Cloud Backup untuk',
			'settings.cloudBackupDescription' => 'Cadangkan pengaturan yang dapat dipindahkan ke alamat WebDAV melalui HTTPS. Koneksi server dan informasi masuk tetap disimpan di perangkat ini.',
			'settings.cloudBackupUrl' => 'URL berkas JSON WebDAV',
			'settings.cloudBackupUsername' => 'Nama Pengguna',
			'settings.cloudBackupPassword' => 'Kata sandi',
			'settings.cloudBackupSaved' => 'Cloud Backup Destinasi disimpan',
			'settings.cloudBackupNow' => 'Kembali ke sekarang',
			'settings.cloudBackupComplete' => 'Settings backup upload',
			'settings.cloudBackupRestore' => 'Restorasi Backup',
			'settings.cloudBackupRestoreConfirm' => 'Ini akan menggantikan pengaturan portabel yang sepadan pada perangkat ini.',
			'settings.cloudBackupRestored' => 'Pengaturan yang dikembalikan dari cloud backup',
			'settings.shortcutsReset' => 'Kembali ke default',
			'settings.resetShortcutsConfirm' => 'Ini akan menggantikan singkatan yang disesuaikan dengan default.',
			'settings.about' => 'Tentang',
			'settings.aboutDescription' => 'Informasi Aplikasi dan Lisensi',
			'settings.updates' => 'Update yang',
			'settings.updateAvailable' => 'Update yang tersedia',
			'settings.checkForUpdates' => 'Periksa Update',
			'settings.autoCheckUpdatesOnStartup' => 'Periksa secara otomatis untuk update pada startup',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Pemberitahuan saat update tersedia pada peluncuran',
			'settings.validationErrorEnterNumber' => 'Silakan masukkan nomor yang valid',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'harus antara ${min} dan ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Kursi yang sudah ditugaskan ke ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Keterlambatan dikemas kini untuk ${action}',
			'settings.saveFailed' => 'Anda tidak bisa menyimpan perubahan. coba lagi.',
			'settings.autoPlayAndSkip' => 'Perbedaan Auto-Play & Skip',
			'settings.autoPlayNextEpisode' => 'Auto-Play Episode selanjutnya',
			'settings.autoPlayNextEpisodeDescription' => 'Memulai episode berikutnya secara otomatis ketika satu berakhir',
			'settings.shuffleStartsFromBeginning' => 'Shuffle dimulai dari awal',
			'settings.shuffleStartsFromBeginningDescription' => 'Memulai setiap episode pada awal ketika mengetuk bukannya mengulang',
			'settings.plexCinemaPreRoll' => 'Menggunakan server cinema intros',
			'settings.plexCinemaPreRollDescription' => 'Mainkan pre-roll Plex atau Jellyfin dan Emby intros yang dikonfigurasi sebelum film dimulai.',
			'settings.playNextCountdown' => 'Mainkan Next Countdown',
			'settings.playNextCountdownImmediate' => 'Bermain dengan segera',
			'settings.skipIntroMode' => 'Pergi ke Into',
			'settings.skipIntroModeOffDescription' => 'Mainkan intros secara normal tanpa tombol skip',
			'settings.skipIntroModeButtonDescription' => 'Tunjukkan tombol skip ketika intro dimulai',
			'settings.skipIntroModeAutoDescription' => 'Meluncur masuk secara otomatis setelah keterlambatan di bawah',
			'settings.skipCreditsMode' => 'Skripsi Kredit',
			'settings.skipCreditsModeOffDescription' => 'Bermain kredit secara normal tanpa tombol skip',
			'settings.skipCreditsModeButtonDescription' => 'Tunjukkan tombol skip saat kredit dimulai',
			'settings.skipCreditsModeAutoDescription' => 'Luncurkan kredit secara otomatis dan memainkan episode berikutnya',
			'settings.skipAdsMode' => 'Pemberitahuan Skip',
			'settings.skipAdsModeOffDescription' => 'Mainkan iklan yang terdeteksi secara normal tanpa tombol skip',
			'settings.skipAdsModeButtonDescription' => 'Menampilkan tombol skip ketika Plex mengidentifikasi iklan',
			'settings.skipAdsModeAutoDescription' => 'Mengalihkan iklan yang ditemukan secara otomatis setelah keterlambatan di bawah',
			'settings.musicPlayback' => 'Musik Playback',
			'settings.musicSweetFades' => 'Susu yang manis',
			'settings.musicSweetFadesDescription' => 'Fade musik pada ujung track ketika Plex memiliki data suara. album playback tetap tidak berubah.',
			'settings.skipMarkerModeOff' => 'Nonaktif',
			'settings.skipMarkerModeButton' => 'Tampilkan tombol',
			'settings.skipMarkerModeAuto' => 'otomatis',
			'settings.forceSkipMarkerFallback' => 'Kekuatan Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'Gunakan pola judul bab bahkan ketika Plex memiliki markers',
			'settings.theIntroDbFallback' => 'Menggunakan TheIntroDB sebagai intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Gunakan waktu komunitas hanya ketika server tidak memiliki intro markers. pertandingan dapat bervariasi dengan release.',
			'settings.autoSkipDelay' => 'Tanggapan mobil',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Tunggu ${seconds} detik sebelum melompat sendiri',
			'settings.introPattern' => 'Intro Marker Potensi',
			'settings.introPatternDescription' => 'Regex pattern untuk memenuhi intro markers dalam judul bab',
			'settings.creditsPattern' => 'Potensi Kredit Marker',
			'settings.creditsPatternDescription' => 'Regex pattern untuk memenuhi kredit markers dalam judul bab',
			'settings.prerolls' => 'Preliminasi',
			'settings.playPrerollsBeforeMovies' => 'Bermain Prerolls Sebelum Film',
			'settings.playPrerollsBeforeMoviesDescription' => 'Mainkan klip rawak dari seleksi Anda di bawah sebelum setiap film. tekan kembali untuk melompat.',
			'settings.prerollLibrary' => 'Perpustakaan Preroll',
			'settings.prerollLibraryNotSet' => 'Tidak menetapkan',
			'settings.prerollLibraryNoneFound' => 'Tidak ada perpustakaan yang ditemukan di server Anda.',
			'settings.prerollSelection' => 'Pemilu Preliminasi',
			'settings.prerollSelectionPickLibraryFirst' => 'Pilih perpustakaan terlebih dahulu',
			'settings.prerollSelectionNoneSelected' => 'Tidak ada preroll yang dipilih',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} dipilih',
			'settings.prerollItemPicker' => 'Pilih Preliminasi',
			'settings.prerollItemPickerLoadFailed' => 'Saya tidak bisa mengisi barang-barang dari perpustakaan ini.',
			'settings.invalidRegex' => 'Ketidakmampuan ekspresi biasa',
			'settings.regex' => 'Ekspresi yang teratur',
			'settings.downloads' => 'Unduhan',
			'settings.downloadLocationDescription' => 'Pilih tempat untuk menyimpan konten yang dimuat turun',
			'settings.downloadLocationDefault' => 'Aplikasi Penyimpanan (App Storage)',
			'settings.downloadLocationCustom' => 'Lokasi Custom',
			'settings.selectFolder' => 'Pilih Folder',
			'settings.resetToDefault' => 'Kembali ke default',
			'settings.currentPath' => ({required Object path}) => 'Saat ini: ${path}',
			'settings.downloadLocationChanged' => 'Download Lokasi yang diubah',
			'settings.downloadLocationReset' => 'Download lokasi reset ke default',
			'settings.downloadLocationInvalid' => 'folder yang dipilih tidak dapat ditulis',
			'settings.downloadLocationPickerUnavailable' => 'Seleksi folder tidak tersedia pada perangkat ini',
			'settings.downloadOnWifiOnly' => 'Download di Wi-Fi hanya',
			'settings.downloadOnWifiOnlyDescription' => 'Menghindari download ketika pada data seluler',
			'settings.autoRemoveWatchedDownloads' => 'Auto-remove download yang ditonton',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Menghapus download secara otomatis',
			'settings.autoDownloadContinueWatching' => 'Auto-Download Teruskan Menonton',
			'settings.autoDownloadContinueWatchingDescription' => 'Simpan item di rak Anda terus menonton yang dimuat turun, dan menghapusnya setelah mereka meninggalkan rak',
			'settings.downloadQuality' => 'Download kualitas',
			'settings.downloadQualityDescription' => 'Plex mempersiapkan salinan terkonversi dalam kue muat turunnya. Jellyfin dan Emby transcode saat file muat turun; transfer terputus mungkin perlu dimulai kembali.',
			'settings.askDownloadQualityEachTime' => 'Pilih kualitas untuk setiap download',
			'settings.askDownloadQualityEachTimeDescription' => 'Tunjukkan kualitas picker sebelum menguji setiap video download',
			'settings.cellularDownloadBlocked' => 'Download diblokir pada seluler. gunakan Wi-Fi atau ubah pengaturan.',
			'settings.maxVolume' => 'Volume maksimum',
			'settings.maxVolumeDescription' => 'Izinkan peningkatan volume di atas 100% untuk media bersuara pelan',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Kekurangan Kekayaan',
			'settings.discordRichPresenceDescription' => 'Tunjukkan apa yang Anda lihat di Discord',
			'settings.services' => 'Layanan',
			'settings.servicesDescription' => 'Hubungi Trakt, MyAnimeList, Seerr, dan banyak lagi',
			'settings.manageLibrariesDescription' => 'Membuka dan menyembunyikan perpustakaan',
			'settings.companionRemoteServer' => 'Layanan Remote Server',
			'settings.companionRemoteServerDescription' => 'Memungkinkan perangkat mobile di jaringan Anda untuk mengontrol aplikasi ini',
			'settings.companionRemoteServerStartFailed' => 'Tidak bisa memulai server',
			'settings.companionRemoteServerStopFailed' => 'Tidak bisa menghentikan server',
			'settings.autoPip' => 'Foto-foto dalam gambar',
			'settings.autoPipDescription' => 'Secara otomatis masuk gambar-in-gambar ketika Anda meninggalkan aplikasi selama pemutaran',
			'settings.matchContentFrameRate' => 'Perbandingan Content Frame Rate',
			'settings.matchContentFrameRateDescription' => 'Pertandingan paparan tingkat pembaharuan untuk konten video',
			'settings.matchContentResolution' => 'Resolusi Konten Pertandingan',
			'settings.matchContentResolutionDescription' => 'Tukar paparan ke resolusi asli video sehingga TV Anda menangani upscaling. menu dan subtitle juga upscaled selama playback',
			'settings.matchRefreshRate' => 'Pertandingan Meningkatkan Rata',
			'settings.matchRefreshRateDescription' => 'Match Display Rata Pembaharuan di Full Screen',
			'settings.matchDynamicRange' => 'Rangkaian Dinamik',
			'settings.matchDynamicRangeDescription' => 'Tukar HDR untuk konten HDR, kemudian kembali ke SDR',
			'settings.displaySwitchDelay' => 'Penundaan switch',
			'settings.tunneledPlayback' => 'Pelatihan Playback',
			'settings.tunneledPlaybackDescription' => 'Gunakan tunel video. mematikan jika HDR playback menampilkan video hitam atau stutters gerakan.',
			'settings.audioPassthrough' => 'Audio yang berkelanjutan',
			'settings.audioPassthroughDescription' => 'Kirim audio Dolby/DTS ke penerima atau TV Anda tanpa kode ulang, menyimpan suara sekitar.',
			'settings.audioPassthroughDescriptionApple' => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. DTS dan TrueHD masih memainkan sebagai PCM multi-saluran.',
			_ => null,
		} ?? switch (path) {
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Gunakan decoder Dolby asli Apple untuk Dolby Digital Plus, termasuk Atmos. Pada iOS, iPadOS dan tvOS 26 atau lebih, TrueHD Atmos dan DTS:X memainkan sebagai audio ruang.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Sementara suara normalisasi sedang',
			'settings.audioChannelLimit' => 'Saluran audio',
			'settings.audioChannelLimitDescription' => 'Campurkan audio yang dikodkan untuk speaker, headphone, atau setup HDMI yang tidak dapat memainkan setiap saluran',
			'settings.audioChannelLimitOriginal' => 'asli',
			'settings.audioChannelLimitOriginalDescription' => 'Mainkan setiap saluran di jalur',
			'settings.audioChannelLimitSurround51' => 'hingga 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Campurkan 7.1 ke bawah 5.1 untuk TV dan penerima yang hanya mengambil 5.1 PCM.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Campurkan ke dua saluran untuk speaker stereo atau headset.',
			'settings.downmixCenterBoost' => 'Bintang Channel Boost',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Peningkatan (db)',
			'settings.downmixCenterBoostShort' => 'db',
			'settings.audioDownmixNormalize' => 'Meningkatkan volume pada Downmix',
			'settings.audioDownmixNormalizeDescription' => 'Mengurangi campuran untuk menghindari penipuan. tutup untuk menjaga volume asli (mungkin mengganggu adegan yang keras).',
			'settings.dvConversionMode' => 'Dolby Vision Konversi',
			'settings.dvConversionModeDescription' => 'Pilih bagaimana Dolby Vision Profil 7 file diproses.',
			'settings.dvConversionAuto' => 'mobil',
			'settings.dvConversionNative' => 'Penduduk / Penyandang Disabilitas',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Menggunakan kemampuan deteksi perangkat dan perilaku fallback normal',
			'settings.dvConversionNativeDescription' => 'Kuasa asli DV7 dan penindasan DV konversi retry',
			'settings.dvConversionDv81Description' => 'Konversi RPU Inline Kekuatan ke Dolby Vision Profil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Strip Dolby Vision lapisan RPU/EL dan rata saat ini HEVC',
			'settings.experimentalDolbyVision' => 'Dolby Vision eksperimental',
			'settings.experimentalDolbyVisionDescription' => 'Gunakan perender FEL eksperimental pada pemutaran berikutnya. Memerlukan build mesin terpisah.',
			'settings.dvExperimentUnavailableDescription' => 'Eksperimen ini saat ini hanya tersedia di Linux.',
			'settings.dvCompatibilityFallback' => 'Cadangan kompatibilitas',
			'settings.dvCompatibilityFallbackDescription' => 'Gunakan perender standar jika eksperimen tidak dapat dimulai. Data FEL mungkin hilang.',
			'settings.dvExperimentDiagnostics' => 'Pencatatan eksperimen video',
			'settings.dvExperimentDiagnosticsDescription' => 'Aktifkan log pemutar terperinci pada pemutaran berikutnya.',
			'settings.disableDolbyVision' => 'Tidak dapat dibatasi Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Bermain file HDR10 atau lapisan HLG bukannya Dolby Vision, ketika itu memiliki satu',
			'settings.hdrSdrConversion' => 'Konversi HDR ke SDR',
			'settings.hdrSdrConversionDescription' => 'Pilih apa yang mengubah video HDR ketika layar tidak dapat menampilkan HDR.',
			'settings.hdrSdrConversionAuto' => 'mobil',
			'settings.hdrSdrConversionAutoDescription' => 'Perangkat pada Android 9 dan lebih baru, pemain pada versi yang lebih tua',
			'settings.hdrSdrConversionDevice' => 'Perangkat',
			'settings.hdrSdrConversionDeviceDescription' => 'Hardware video perangkat Anda mengubahnya. paling cepat, tetapi warna tergantung pada perangkat',
			'settings.hdrSdrConversionPlayer' => 'Pemutar',
			'settings.hdrSdrConversionPlayerDescription' => 'Warna konsisten, tetapi 4K dapat menandai kotak TV low-end',
			'settings.deinterlace' => 'Interlokasi',
			'settings.deinterlaceDescription' => 'Menghapus artefak berkombinasi dari video yang terhubung (mpv pemain saja)',
			'settings.deinterlaceOff' => 'Nonaktif',
			'settings.deinterlaceOffDescription' => 'Menampilkan video terhubung saat dikodkan',
			'settings.deinterlaceVideo' => 'Video yang',
			'settings.deinterlaceVideoDescription' => 'Tukar setiap medan ke dalam bingkai penuh. untuk video tangkapan untuk TV, seperti olahraga, berita, dan konser',
			'settings.deinterlaceFilm' => 'Film yang',
			'settings.deinterlaceFilmDescription' => 'Restorasi bingkai asli film dan animasi telecined ke 29.97 fps, umum pada DVD NTSC. Video shot untuk TV stutters. Live TV menggunakan Video',
			'settings.requireProfileSelectionOnOpen' => 'Meminta profil di aplikasi terbuka',
			'settings.requireProfileSelectionOnOpenDescription' => 'Menampilkan seleksi profil setiap kali aplikasi dibuka',
			'settings.forceTvMode' => 'Mode TV Kekuatan',
			'settings.forceTvModeDescription' => 'Untuk perangkat yang tidak mendeteksi secara otomatis. memerlukan restart.',
			'settings.startInFullscreen' => 'Mulai dengan layar penuh',
			'settings.startInFullscreenDescription' => 'Buka PlezyNG dalam mode layar penuh saat diluncurkan',
			'settings.exitFullscreenOnPlayerClose' => 'Penuh layar keluar pada player close',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Secara otomatis keluar layar penuh saat menutup pemutar video',
			'settings.autoHidePerformanceOverlay' => 'Auto-Hide Performa Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'Fade performance overlay dengan playback controls',
			'settings.showNavBarLabels' => 'Tampilkan Navigasi Bar Label',
			'settings.showNavBarLabelsDescription' => 'Menampilkan label teks di bawah ikon bar navigasi',
			'settings.startupSection' => 'Bagian Startup',
			'settings.preferredServer' => 'Server yang disukai',
			'settings.preferredServerDescription' => 'Prioritaskan hasil server ini sambil menjaga setiap server terhubung tersedia.',
			'settings.preferredServerAutomatic' => 'otomatis',
			'settings.showExploreTab' => 'Menampilkan Tab',
			'settings.showExploreTabDescription' => 'Tampilkan tab Explore dengan konten dari Plex Discover dan tracker terhubung',
			'settings.hideEmptyLibraries' => 'Menutup perpustakaan kosong',
			'settings.hideEmptyLibrariesDescription' => 'Menghapus perpustakaan dengan jumlah item yang dilaporkan oleh server dari nol dari navigasi.',
			'settings.liveTvDefaultFavorites' => 'Menerima saluran favorit',
			'settings.liveTvDefaultFavoritesDescription' => 'Menampilkan hanya saluran favorit saat membuka Live TV',
			'settings.general' => 'Umum',
			'settings.generalDescription' => 'Bahasa, startup, dan tingkap perilaku',
			'settings.languageAndRegion' => 'Bahasa & Wilayah',
			'settings.startup' => 'Saat mulai',
			'settings.display' => 'Tampilan',
			'settings.libraryAndCards' => 'Perpustakaan & Kartu',
			'settings.homeScreen' => 'Home layar',
			'settings.navigation' => 'Navigasi',
			'settings.window' => 'jendela',
			'settings.liveTv' => 'TV Langsung',
			'settings.player' => 'Pemutar',
			'settings.videoAndDisplay' => 'Video dan Display',
			'settings.audio' => 'Audio yang',
			'settings.quality' => 'Kualitas',
			'settings.subtitles' => 'Subtitel',
			'settings.seekAndTiming' => 'Pencarian & Timing',
			'settings.behavior' => 'perilaku',
			'settings.gestures' => 'Gejala',
			'settings.gestureBrightnessSwipe' => 'Cahaya bersinar',
			'settings.gestureBrightnessSwipeDescription' => 'Putar ke atas atau ke bawah di tepi kiri untuk menyesuaikan kecerahan',
			'settings.gestureVolumeSwipe' => 'Jumlah Swipe',
			'settings.gestureVolumeSwipeDescription' => 'Beralih ke atas atau ke bawah di tepi kanan untuk menyesuaikan volume',
			'settings.gesturePinchToZoom' => 'Pinch untuk Zoom',
			'settings.gesturePinchToZoomDescription' => 'Klik pada video untuk zoom ke dalam atau keluar',
			'settings.gestureSeekSwipe' => 'Mencari Swipe',
			'settings.gestureSeekSwipeDescription' => 'Beralih ke kiri atau kanan di mana saja di video untuk mencari; melepaskan untuk melompat',
			'settings.rememberBrightnessLevel' => 'Mengingat tingkat kecerahan',
			'settings.rememberBrightnessLevelDescription' => 'Mulai playback pada kecerahan yang ditetapkan oleh swipe terakhir',
			'settings.controls' => 'Kontrol',
			'settings.rememberPlayerChanges' => 'Ingat perubahan pemain',
			'settings.rememberPlayerChangesDescription' => 'Di mana perubahan yang dibuat selama playback disimpan dan diterapkan kembali dari',
			'settings.scopePlaybackSpeed' => 'Kecepatan Pemutaran',
			'settings.scopeShaderPreset' => 'Shader Preset yang',
			'settings.scopeAspectRatio' => 'Rasio perbandingan',
			'settings.scopeSyncOffsets' => 'Audio dan Subtitle Sync',
			'settings.playerScopeOff' => 'Jangan Menyelamatkan',
			'settings.playerScopeGlobal' => 'di mana-mana',
			'settings.playerScopeLibrary' => 'Per Perpustakaan',
			'settings.playerScopeTitle' => 'Untuk acara atau film',
			'settings.exportDialogTitle' => 'Eksport PlezyNG pengaturan',
			'settings.followSystem' => 'Ikuti sistem',
			'settings.followAppLanguage' => 'Samakan dengan bahasa antarmuka',
			'settings.regionFormat' => 'Format regional',
			'settings.regionFormatDescription' => 'Pilih cara menampilkan tanggal, angka, dan satuan ukuran.',
			'settings.metadataLanguage' => 'Bahasa metadata',
			'settings.metadataLanguageDescription' => 'Bahasa judul dan deskripsi yang diutamakan jika didukung server. Preferensi audio dan subtitel diatur secara terpisah.',
			'settings.enterFullscreenOnPlaybackStart' => 'Masuk layar penuh saat playback dimulai',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Buka desktop video pada layar penuh ketika playback dimulai',
			'settings.extendVideoIntoDisplayCutout' => 'Mengembangkan video ke display cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Biarkan video layar penuh menggunakan kamera cutout pada ponsel Android',
			'settings.languageDescription' => 'Pilih bahasa yang digunakan untuk kontrol dan pesan PlezyNG. sistem mengikuti bahasa perangkat Anda.',
			'settings.themeDescription' => 'Pilih warna dan kontras yang digunakan di seluruh aplikasi.',
			'settings.libraryDensityDescription' => 'Mengubah berapa banyak kartu perpustakaan yang cocok dalam setiap baris.',
			'settings.displayScaleDescription' => 'Memperbaiki antarmuka pada layar mobil ini tanpa mengubah ukuran teks seluruh perangkat Anda.',
			'settings.themeSongVolumeDescription' => 'Tetapkan volume lagu tema yang relatif dengan audio lainnya.',
			'settings.viewModeDescription' => 'Pilih apakah item perpustakaan muncul sebagai poster di jaringan atau sebagai daftar kompak.',
			'settings.gridViewDescription' => 'Mengatur item perpustakaan dalam baris dan kolom poster.',
			'settings.listViewDescription' => 'Tunjukkan item perpustakaan dalam daftar vertikal dengan lebih banyak teks per item.',
			'settings.gridSpacingDescription' => 'Tetapkan jurang antara poster di jaringan perpustakaan.',
			'settings.gridSpacingTightDescription' => 'Tetapkan lebih banyak poster di seluruh layar dengan jurang yang lebih kecil.',
			'settings.gridSpacingNormalDescription' => 'Gunakan jurang standar antara poster.',
			'settings.gridSpacingSpaciousDescription' => 'Tambahkan jurang yang lebih besar antara poster untuk pemisahan lebih banyak.',
			'settings.episodePosterModeDescription' => 'Pilih karya seni yang muncul pada kartu episode.',
			'settings.seriesPosterDescription' => 'Gunakan poster serial untuk setiap episode.',
			'settings.seasonPosterDescription' => 'Gunakan poster musim untuk setiap episode ketika tersedia.',
			'settings.episodeThumbnailDescription' => 'Gunakan bingkai dari episode ketika tersedia.',
			'settings.continueWatchingActionDescription' => 'Pilih apa yang terjadi saat Anda mengaktifkan kartu terus-menerus.',
			'settings.continueWatchingPlayDescription' => 'Mulai film atau episode dengan segera.',
			'settings.continueWatchingDetailsDescription' => 'Buka halaman judul terlebih dahulu sehingga Anda dapat meninjau rincian dan memilih tindakan.',
			'settings.episodeActionDescription' => 'Pilih apa yang terjadi saat Anda mengaktifkan kartu episode.',
			'settings.episodePlayDescription' => 'Mulailah episode ini dengan segera.',
			'settings.episodeDetailsDescription' => 'Buka halaman episode sebelum playback.',
			'settings.contentScreensaverDelayDescription' => 'Pilih berapa lama PlezyNG menunggu tanpa input sebelum menunjukkan karya seni.',
			'settings.continueWatchingRowSizeDescription' => 'Pilih seberapa besar kartu yang ada di baris terus-menerus.',
			'settings.rowSizeCompactDescription' => 'Tunjukkan kartu yang lebih kecil sehingga lebih banyak item cocok di sepanjang baris.',
			'settings.rowSizeStandardDescription' => 'Gunakan ukuran kartu standar.',
			'settings.rowSizeLargeDescription' => 'Tunjukkan kartu yang lebih besar dengan detail karya seni yang lebih banyak.',
			'settings.visualEffectsDescription' => 'Pilih anggaran animasi dan efek karya seni untuk perangkat ini.',
			'settings.visualEffectsFullDescription' => 'Gunakan efek animasi dan karya seni penuh pada setiap perangkat.',
			'settings.startupSectionDescription' => 'Pilih bagian mana yang dibuka saat PlezyNG dimulai.',
			'settings.startupSectionOptions.discover' => 'Membuka rekomendasi dan item dari sumber penemuan yang terhubung.',
			'settings.startupSectionOptions.libraries' => 'Buka perpustakaan media yang terhubung.',
			'settings.startupSectionOptions.liveTv' => 'Buka Live TV ketika server menyediakan; jika tidak, startup jatuh kembali ke Home.',
			'settings.startupSectionOptions.search' => 'pencarian media terbuka.',
			'settings.smallSkipDurationDescription' => 'Tetapkan jarak yang dipindahkan oleh belakang pendek dan ke depan mencari kontrol.',
			'settings.largeSkipDurationDescription' => 'Tetapkan jarak yang dipindahkan oleh belakang panjang dan ke depan mencari kontrol.',
			'settings.rewindOnResumeDescription' => 'Move playback kembali dengan jumlah ini ketika mengembalikan video.',
			'settings.defaultSleepTimerDescription' => 'Tetapkan durasi awal yang digunakan saat Anda memulai timer tidur.',
			'settings.playNextCountdownDescription' => 'Tunggu ini lama sebelum memulai episode berikutnya. set ke 0 untuk memulai dengan segera.',
			'settings.autoSkipDelaySettingDescription' => 'Ini berlaku ketika intro, kredit, atau iklan ditetapkan untuk meluncur secara otomatis.',
			'settings.downmixCenterBoostDescription' => 'Meningkatkan dialog di saluran pusat ketika audio sekitar dicampur ke bawah ke stereo.',
			'settings.displaySwitchDelayDescription' => 'Tunggu sebelum mengubah mode paparan sehingga TV atau penerima dapat menyelesaikan switch sebelumnya.',
			'settings.playerBackendDescription' => 'Pilih mesin playback mana yang mendekorasi dan menghasilkan video pada perangkat ini.',
			'settings.exoPlayerDescription' => 'Gunakan pemutar asli Android yang berbasis Media3 dan jalur perangkat keras yang didukung.',
			'settings.mpvDescription' => 'Gunakan mpv, yang mendedahkan pemutaran tambahan, subtitle, dan kontrol pemrosesan video.',
			'settings.scopeOffDescription' => 'Hanya menyimpan perubahan untuk sesi playback saat ini.',
			'settings.scopeGlobalDescription' => 'Gunakan kembali nilai yang sama untuk setiap perpustakaan dan judul.',
			'settings.scopeLibraryDescription' => 'Ingatlah nilai yang berbeda untuk setiap perpustakaan.',
			'settings.scopeTitleDescription' => 'Ingat nilai terpisah untuk setiap acara atau film.',
			'settings.specialsOrderingServerDescription' => 'Tinggalkan pesanan episode yang disediakan oleh server media.',
			'settings.specialsOrderingAirDateDescription' => 'Menempatkan spesial di antara episode biasa pada tanggal udara mereka.',
			'settings.specialsOrderingLastDescription' => 'Tempatkan masing-masing spesial setelah musim biasa.',
			'settings.skipIntroModeDescription' => 'Pilih apakah intro markers bermain normal, menunjukkan tombol skip, atau skip secara otomatis.',
			'settings.skipCreditsModeDescription' => 'Pilih apakah kredit bermain normal, menunjukkan tombol skip, atau skip secara otomatis.',
			'settings.skipAdsModeDescription' => 'Pilih apakah iklan yang dideteksi memainkan secara normal, menampilkan tombol skip, atau skip secara otomatis.',
			'settings.playbackBufferAutoDescription' => 'Biarkan pemain aktif memilih ukuran buffer normalnya.',
			'settings.playbackBufferLargeDescription' => 'Tetap lebih banyak media siap sebelum playback; ini menggunakan lebih banyak memori.',
			'settings.playbackBufferExtraLargeDescription' => 'Simpan buffer bacaan terbesar; ini menggunakan memori yang paling banyak.',
			'settings.defaultQualityDescription' => 'Tetapkan resolusi video default dan bitrate atap untuk aliran yang transcod server.',
			'settings.cellularQualityDescription' => 'Override Default Quality ketika perangkat menggunakan koneksi seluler saja.',
			'settings.remoteQualityDescription' => 'Override Default Quality ketika terhubung ke server melalui koneksi remote.',
			'settings.qualityPresetOriginalDescription' => 'Mainkan sumber pada kualitas yang tersedia tanpa meminta server untuk transcode.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Tanya server untuk aliran terkonversi menggunakan resolusi dan bitrate yang ditunjukkan di atas.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Gunakan kualitas yang dipilih dalam Default Quality.',
			'settings.musicQualityDescription' => 'Tetapkan bitrate audio maksimum yang diminta dari server; Original mempertahankan aliran sumber.',
			'settings.musicQualityOriginalDescription' => 'Mainkan audio sumber tanpa transcode bitrate.',
			'settings.musicQualityTranscodeOptionDescription' => 'Meminta transcode server yang dicap dekat bitrate yang ditunjukkan di atas; output sebenarnya dapat bervariasi.',
			'settings.maxVolumeInputLabel' => 'Jumlah maksimum (%)',
			'settings.checkForUpdatesDescription' => 'Periksa sekarang apakah versi PlezyNG yang lebih baru tersedia.',
			'settings.appearanceDescription' => 'Pilih tema aplikasi dan menyesuaikan kartu perpustakaan, baris rumah, dan navigasi.',
			'settings.prerollLibraryDescription' => 'Pilih perpustakaan yang berisi klip yang tersedia sebagai pre-roll film.',
			'settings.prerollSelectionDescription' => 'Pilih klip dari perpustakaan yang dipilih dapat dimainkan sebelum film.',
			'settings.contentScreensaverDelayOptionDescription' => 'Tunggu ini beberapa menit tanpa input sebelum menunjukkan karya seni screensaver.',
			'settings.videoCodecOptionDescription' => 'Memungkinkan playback langsung untuk codec ini ketika didukung. codec yang tidak disemak dikodifikasi oleh server media.',
			'themeEditor.builtIn' => 'dibangun',
			'themeEditor.presets' => 'Preset',
			'themeEditor.custom' => 'Kustom',
			'themeEditor.customEmpty' => 'belum diciptakan',
			'themeEditor.editCustom' => 'Edit Tema Khas',
			'themeEditor.editCustomDescription' => 'Pilih setiap warna sendiri',
			'themeEditor.locked' => 'Akses seumur hidup yang diperlukan',
			'themeEditor.savedLocked' => 'Disimpan - tersedia dengan akses seumur hidup',
			'themeEditor.title' => 'Tema yang disesuaikan',
			'themeEditor.startFrom' => 'Mulai dari',
			'themeEditor.startFromDescription' => 'Menyalin semua warna dari tema lain',
			'themeEditor.colors' => 'warna',
			'themeEditor.preview' => 'Pratinjau',
			'themeEditor.slots.bg' => 'latar belakang',
			'themeEditor.slots.surface' => 'permukaan',
			'themeEditor.slots.outline' => 'outline',
			'themeEditor.slots.text' => 'Teks',
			'themeEditor.slots.textMuted' => 'Teks Sekunder',
			'themeEditor.slots.accent' => 'aksen',
			'themeEditor.opacity' => 'Opacitas',
			'themeEditor.hexHint' => '#RRGGBB atau #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Dari tema lain',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'Teks di latar belakang',
			'themeEditor.contrast.textOnSurface' => 'Teks di permukaan',
			'themeEditor.contrast.textMutedOnBg' => 'Teks sekunder di latar belakang',
			'themeEditor.contrast.textMutedOnSurface' => 'Teks sekunder di permukaan',
			'themeEditor.contrast.accentOnBg' => 'Fokus pada latar belakang',
			'themeEditor.contrast.accentOnSurface' => 'Fokus pada permukaan',
			'themeEditor.contrast.labelOnAccent' => 'Label tombol pada aksen',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, di bawah yang disarankan ${minimum}:1',
			'themeEditor.discardTitle' => 'Mengabaikan perubahan?',
			'themeEditor.discardMessage' => 'Perubahan warna yang tidak disimpan akan hilang.',
			'themeEditor.discard' => 'Diskarat',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Keterangan ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} min dibatasi',
			'themeEditor.previewSwitch' => 'Putar otomatis',
			'themeEditor.previewMutedText' => 'Artikel ini dibaca seperti ini',
			'themeEditor.themeSystemDescription' => 'Ikuti penampilan perangkat Anda dan beralih antara cahaya dan kegelapan secara otomatis.',
			'themeEditor.themeLightDescription' => 'Gunakan latar belakang yang terang dengan teks gelap.',
			'themeEditor.themeDarkDescription' => 'Gunakan latar belakang gelap dengan teks terang.',
			'themeEditor.themeOledDescription' => 'Gunakan permukaan berdekatan hitam yang mengurangi cahaya pada layar OLED.',
			'themeEditor.themeEmberDescription' => 'Gunakan warna merah hangat dan aksen amber.',
			'themeEditor.themeGlacierDescription' => 'Gunakan warna aksen biru yang sejuk.',
			'themeEditor.themeForestDescription' => 'Gunakan warna hijau dan aksen alami.',
			'themeEditor.themePlumDescription' => 'Gunakan warna aksen violet dan plum.',
			'themeEditor.themePaperDescription' => 'Gunakan permukaan yang hangat seperti kertas dan warna terinspirasi tinta.',
			'themeEditor.themeCustomDescription' => 'Gunakan palet warna yang Anda ciptakan dalam editor tema tersuai.',
			'themeEditor.editorDescription' => 'Pilih warna palet, menyesuaikan kulitnya, kenyang, kecerahan, atau ketidakselesaan, dan lihat update preview sebelum menghemat.',
			'search.hint' => 'Mencari film, acara, musik...',
			'search.tryDifferentTerm' => 'Cobalah istilah pencarian yang berbeda',
			'search.searchYourMedia' => 'Temukan Media Anda',
			'search.enterTitleActorOrKeyword' => 'Masukkan judul, aktor, atau kata kunci',
			'search.people' => 'Orang-orang',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Set Shortcut untuk ${actionName}',
			'hotkeys.clearShortcut' => 'Singkatnya',
			'hotkeys.noShortcutSet' => 'Tidak ada shortcut set',
			'hotkeys.currentShortcut' => 'Current singkatan :',
			'hotkeys.pressToRecord' => 'Pilih untuk mencatat singkatan',
			'hotkeys.recordingShortcut' => 'Tekan Shortcut sekarang',
			'hotkeys.actions.playPause' => 'Bermain dan beristirahat',
			'hotkeys.actions.volumeUp' => 'Jumlah Up',
			'hotkeys.actions.volumeDown' => 'Volume turun',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Mencari ke depan (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Mencari ke belakang (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Bersama Fullscreen',
			'hotkeys.actions.muteToggle' => 'Bersama Mutu',
			'hotkeys.actions.subtitleToggle' => 'Menggabungkan Subtitle',
			'hotkeys.actions.audioTrackNext' => 'Berikut ini Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'Subtitle selanjutnya Track',
			'hotkeys.actions.chapterNext' => 'Bab selanjutnya',
			'hotkeys.actions.chapterPrevious' => 'Bab sebelumnya',
			'hotkeys.actions.episodeNext' => 'Episode Selanjutnya',
			'hotkeys.actions.episodePrevious' => 'episode sebelumnya',
			'hotkeys.actions.speedIncrease' => 'Meningkatkan kecepatan',
			'hotkeys.actions.speedDecrease' => 'Menurunkan kecepatan',
			'hotkeys.actions.speedReset' => 'Reset kecepatan',
			'hotkeys.actions.zoomIn' => 'Zoom dalam',
			'hotkeys.actions.zoomOut' => 'Zoom keluar',
			'hotkeys.actions.zoomReset' => 'Atur ulang zoom',
			'hotkeys.actions.subSeekNext' => 'Temukan Subtitle berikutnya',
			'hotkeys.actions.subSeekPrev' => 'Temukan Subtitle sebelumnya',
			'hotkeys.actions.subtitleDelayIncrease' => 'Penundaan Subtitle',
			'hotkeys.actions.subtitleDelayDecrease' => 'Subtitle yang maju',
			'hotkeys.actions.shaderToggle' => 'Bersama Shaders',
			'hotkeys.actions.skipMarker' => 'Langkah-langkah untuk masuk / kredit',
			'hotkeys.actions.screenshot' => 'Mengambil screenshot',
			'hotkeys.actions.framePrevious' => 'Frame sebelumnya',
			'hotkeys.actions.frameNext' => 'Frame selanjutnya',
			'fileInfo.title' => 'Informasi File',
			'fileInfo.overview' => 'Tinjauan',
			'fileInfo.video' => 'Video yang',
			'fileInfo.audio' => 'Audio yang',
			'fileInfo.subtitles' => 'Subtitel',
			'fileInfo.images' => 'Gambar yang terintegrasi',
			'fileInfo.dataStreams' => 'Data Stream',
			'fileInfo.lyrics' => 'Lirik',
			'fileInfo.file' => 'File yang',
			'fileInfo.attachments' => 'Aksesori',
			'fileInfo.delivery' => 'Pengiriman',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versi ${index} dari ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'File ${index} dari ${count}',
			'fileInfo.noStreams' => 'Server tidak melaporkan streaming untuk file ini.',
			'fileInfo.copyPath' => 'Kopi Jalan',
			'fileInfo.pathCopied' => 'File Path yang disalin',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Tag Kodek',
			'fileInfo.resolution' => 'Resolusi',
			'fileInfo.codedResolution' => 'Resolusi Kod',
			'fileInfo.bitrate' => 'Bitrate yang',
			'fileInfo.frameRate' => 'Rata-rata Frame',
			'fileInfo.rotation' => 'Rotasi',
			'fileInfo.comment' => 'Bagaimana',
			'fileInfo.audioDescription' => 'Audio deskripsi',
			'fileInfo.headerCompression' => 'Kepala Kompresi',
			'fileInfo.sidecarFile' => 'Sidecar file',
			'fileInfo.transportTimestamp' => 'Pengangkutan Timestamp',
			'fileInfo.displayOffset' => 'Menampilkan Offset',
			'fileInfo.previewFailureCode' => 'Preview Kode Kegagalan',
			'fileInfo.previewRetries' => 'Preview Kembali',
			'fileInfo.aspectRatio' => 'Rasio perbandingan',
			'fileInfo.pixelAspectRatio' => 'Piksel Aspek Ratio',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Tingkat',
			'fileInfo.bitDepth' => 'Kedalaman Bit',
			'fileInfo.pixelFormat' => 'Format Piksel',
			'fileInfo.colorSpace' => 'Ruang warna',
			'fileInfo.colorRange' => 'Rangkaian warna',
			'fileInfo.colorPrimaries' => 'Warna primer',
			'fileInfo.colorTransfer' => 'Transfer warna',
			'fileInfo.chromaSubsampling' => 'Kromium Subsampling',
			'fileInfo.chromaLocation' => 'Lokasi Chromium',
			'fileInfo.scanType' => 'Scan jenis',
			'fileInfo.interlaced' => 'Terjalin',
			'fileInfo.anamorphic' => 'Anamorfik',
			'fileInfo.referenceFrames' => 'Referensi Framework',
			'fileInfo.dynamicRange' => 'Rangkaian Dinamik',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision Tingkat',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision versi',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision Layer',
			'fileInfo.baseLayerCompatibility' => 'Kompatibilitas Layer Basis',
			'fileInfo.avcBitstream' => 'Perbedaan AVC Bitstream',
			'fileInfo.nalLengthSize' => 'Ukuran panjang',
			'fileInfo.scalingMatrix' => 'Matriks Scaling yang tersuai',
			'fileInfo.streamIdentifier' => 'Identifikasi Stream',
			'fileInfo.streamIndex' => 'Indeks Stream',
			'fileInfo.streamId' => 'ID aliran',
			'fileInfo.language' => 'Bahasa',
			'fileInfo.languageCode' => 'kode bahasa',
			'fileInfo.streamTitle' => 'Judul Track',
			'fileInfo.channels' => 'Saluran',
			'fileInfo.sampleRate' => 'Nilai Sampel',
			'fileInfo.spatialAudio' => 'Ruang Audio',
			'fileInfo.textBased' => 'Teks Berdasarkan',
			'fileInfo.subtitleFormat' => 'Formasi Sidecar',
			'fileInfo.provider' => 'Penyedia',
			'fileInfo.matchScore' => 'Pertandingan skor',
			'fileInfo.externalDelivery' => 'dapat disajikan secara terpisah',
			'fileInfo.sidecarPath' => 'Jalan Sidekar',
			'fileInfo.sourceStream' => 'Diterjemahkan dari',
			'fileInfo.temporary' => 'sementara',
			'fileInfo.timeBase' => 'basis waktu',
			'fileInfo.overallBitrate' => 'Jumlah Bitrate',
			'fileInfo.path' => 'Lokasi',
			'fileInfo.fileName' => 'Nama file',
			'fileInfo.size' => 'Ukuran',
			'fileInfo.totalSize' => 'Total ukuran',
			'fileInfo.container' => 'Penyimpan',
			'fileInfo.duration' => 'Durasi',
			'fileInfo.previewThumbnails' => 'Praktek Tumbnails',
			'fileInfo.previewIndex' => 'Indeks Preview',
			'fileInfo.packetLength' => 'Panjang paket',
			'fileInfo.filePresent' => 'File yang hadir',
			'fileInfo.fileReadable' => 'dapat dibaca oleh server',
			'fileInfo.streamPath' => 'Jalur aliran',
			'fileInfo.optimizedForStreaming' => 'Optimisasi untuk Streaming',
			'fileInfo.has64bitOffsets' => '64 bit offset',
			'fileInfo.protocol' => 'Protokol',
			'fileInfo.mediaType' => 'Jenis Media',
			'fileInfo.sourceKind' => 'Sumber yang baik',
			'fileInfo.optimizedVersion' => 'Versi yang Optimis',
			'fileInfo.optimizationTarget' => 'Optimisasi Target',
			'fileInfo.deletedAt' => 'dihapus',
			'fileInfo.remoteSource' => 'Sumber Jarak Jauh',
			'fileInfo.infiniteStream' => 'Infinite aliran',
			'fileInfo.directPlay' => 'Bermain langsung',
			'fileInfo.directStream' => 'Stream langsung',
			'fileInfo.transcoding' => 'Transkode',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Versi ID',
			'fileInfo.fileId' => 'ID berkas',
			'fileInfo.defaultAudioTrack' => 'Perangkat Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'Subtitle Track yang',
			'fileInfo.subtitlesOff' => 'Nonaktif',
			'fileInfo.flagDefault' => 'Bawaan',
			'fileInfo.flagForced' => 'Dipaksa',
			'fileInfo.flagSelected' => 'Seleksi',
			'fileInfo.flagExternal' => 'Eksternal',
			'fileInfo.flagHearingImpaired' => 'Mendengarkan terganggu',
			'fileInfo.flagDub' => 'Dub yang',
			'fileInfo.flagOriginal' => 'asli',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Mark yang dilihat',
			'mediaMenu.markAsUnwatched' => 'Mark sebagai Unwatched',
			'mediaMenu.removeFromContinueWatching' => 'Menghapus dari terus menonton',
			'mediaMenu.viewDetails' => 'Lihat detail',
			'mediaMenu.goToSeries' => 'Pergi ke seri',
			'mediaMenu.shufflePlay' => 'Bermain Shuffle',
			'mediaMenu.shuffleNotAvailableOffline' => 'Shuffle tidak tersedia offline',
			'mediaMenu.fileInfo' => 'Informasi File',
			'mediaMenu.deleteEpisodeFromServer' => 'Menghapus episode dari server',
			'mediaMenu.deleteSeasonFromServer' => 'Menghapus Musim dari Server',
			'mediaMenu.deleteShowFromServer' => 'Menghapus tampilan dari server',
			'mediaMenu.deleteMovieFromServer' => 'Menghapus film dari server',
			'mediaMenu.deleteEpisodeTitle' => 'Apakah Anda menghapus episode ini?',
			'mediaMenu.deleteSeasonTitle' => 'Apakah Anda menghapus musim ini?',
			'mediaMenu.deleteShowTitle' => 'Apakah Anda menghapus acara ini?',
			'mediaMenu.deleteMovieTitle' => 'Menghapus film ini?',
			'mediaMenu.deleteEpisodeConfirm' => 'Hapus Episode',
			'mediaMenu.deleteSeasonConfirm' => 'Musim yang dihapus',
			'mediaMenu.deleteShowConfirm' => 'Menghapus Show',
			'mediaMenu.deleteMovieConfirm' => 'Menghapus Film',
			'mediaMenu.deleteAnyway' => 'Menghapus bagaimanapun',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Permanen menghapus ${title} dari server Anda?',
			'mediaMenu.deleteMultipleWarning' => 'Ini termasuk semua episode dan file mereka.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: 'Ini menghapus semua ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode di dalamnya, dan file mereka.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: 'Item ini disimpan di seluruh file ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}, dan semua dari mereka akan dihapus.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode lain disimpan dalam file yang sama dan juga akan dihapus:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG tidak dapat memeriksa berkas mana yang akan dihapus, sehingga mungkin menghapus lebih dari item yang disebutkan di atas. Batalkan dan coba lagi, atau tetap hapus.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Server tidak memberikan rincian berkas untuk item ini, sehingga PlezyNG tidak dapat memeriksa berkas mana yang akan dihapus. Penghapusan mungkin mencakup lebih dari item yang disebutkan di atas.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media item dihapus dengan sukses',
			'mediaMenu.mediaFailedToDelete' => 'gagal menghapus media item',
			'mediaMenu.rate' => 'Rating',
			'mediaMenu.playFromBeginning' => 'Mainkan dari awal',
			'mediaMenu.playVersion' => 'Bermain versi...',
			'rateSheet.title' => 'Rating',
			'rateSheet.server' => 'Server yang',
			'rateSheet.favorite' => 'Favorit',
			'rateSheet.favorited' => 'Favorit',
			'rateSheet.saved' => 'diselamatkan',
			'rateSheet.notAvailable' => 'Tidak ditemukan pertandingan',
			'rateSheet.noConnectedServices' => 'Sambungkan layanan di Settings untuk menilai di sana.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, acara televisi',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'Ditonton',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} persen dilihat',
			'accessibility.mediaCardUnwatched' => 'belum ditonton',
			'accessibility.tapToPlay' => 'Ketuk untuk memutar',
			'accessibility.decrease' => 'Penurunan',
			'accessibility.increase' => 'Meningkat',
			'accessibility.decreaseValue' => ({required Object label}) => 'Penurunan ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Peningkatan ${label}',
			'accessibility.hue' => 'Hue',
			'accessibility.saturation' => 'Saturasi',
			'accessibility.brightness' => 'kecerahan',
			'accessibility.hexColor' => 'Hex warna',
			'accessibility.expandText' => 'Perkembangan teks',
			'accessibility.collapseText' => 'Teks yang runtuh',
			'accessibility.alphabetNavigation' => 'Navigasi Alphabet',
			'accessibility.alphabetScrollHint' => 'Geser ke atas atau ke bawah untuk berpindah menurut huruf',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Jalur ${row} dari ${rowCount}, kolom ${column} dari ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Ruang ${row} dari ${rowCount}',
			'accessibility.autoScrollPlay' => 'Bermain dengan Auto-Scroll',
			'accessibility.autoScrollPause' => 'Perhentian Auto-Scroll',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Merah',
			'accessibility.green' => 'Hijau',
			'accessibility.blue' => 'Biru',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Aksesibilitas',
			'accessibility.summary' => 'Teks, kontras, gerakan dan kontrol',
			'accessibility.systemHint' => 'Sesuai dengan pengaturan aksesibilitas perangkat Anda, Anda akan selalu menggunakan pengaturan ini. pilihan ini menambah penyesuaian sepanjang PlezyNG.',
			'accessibility.readability' => 'Membaca dan melihat',
			'accessibility.textSize' => 'Ukuran teks tambahan',
			'accessibility.preview' => 'Baca, dengar dan lihat pada kecepatan Anda sendiri.',
			'accessibility.boldText' => 'Interface yang baik',
			'accessibility.highContrast' => 'kontras yang tinggi',
			'accessibility.highContrastHint' => 'Teks yang lebih kuat, outlines dan fokus indikator pada permukaan terang atau gelap.',
			'accessibility.interaction' => 'Pergerakan dan Interaksi',
			'accessibility.reduceMotion' => 'Mengurangi gerakan',
			'accessibility.reduceMotionHint' => 'Hentikan animasi indikator fokus, transisi halaman, dan efek dekoratif.',
			'accessibility.largeTargets' => 'Target Touch yang lebih besar',
			'accessibility.largeTargetsHint' => 'Memberi kontrol yang dikongsi lebih banyak ruang untuk sentuhan dan navigasi asisten.',
			'accessibility.navigationHint' => 'Gunakan Tab dan Shift+Tab untuk berpindah antar kontrol, Enter atau Space untuk mengaktifkan, dan Escape atau tombol Kembali untuk menutup. Zoom dan preferensi membaca tersedia saat buku terbuka.',
			'accessibility.textSizeDescription' => 'Skala antara muka teks dalam PlezyNG ditambah dengan pengaturan ukuran teks sistem perangkat Anda.',
			'accessibility.boldTextHint' => 'Gunakan berat yang lebih berat untuk label dan pesan antarmuka untuk membuat mereka lebih mudah dibedakan.',
			'tooltips.shufflePlay' => 'Permainan Shuffle',
			'tooltips.playTrailer' => 'Bermain Trailer',
			'tooltips.markAsWatched' => 'Mark yang ditonton',
			'tooltips.markAsUnwatched' => 'Mark yang tidak diperhatikan',
			'audioTracks.track' => ({required Object n}) => 'Trek audio ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengaturan', ), 
			'videoControls.audioLabel' => 'Audio yang',
			'videoControls.subtitlesLabel' => 'Subtitel',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Surat Kotak',
			'videoControls.fillScreen' => 'Mengisi layar',
			'videoControls.stretch' => 'Mengisi',
			'videoControls.lockRotation' => 'Lock rotasi',
			'videoControls.unlockRotation' => 'Unlock rotasi',
			'videoControls.timerActive' => 'Timer aktif',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Playback akan berhenti di ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Akhir dari video saat ini',
			'videoControls.sleepTimerStopAtHeader' => 'Berhenti di',
			'videoControls.sleepTimerDurationHeader' => 'Waktu',
			_ => null,
		} ?? switch (path) {
			'videoControls.playbackWillPauseAtEnd' => 'Playback Akan Berhenti di Akhir Video Ini',
			'videoControls.stillWatching' => 'Masih menonton?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Berhenti di ${seconds}s',
			'videoControls.continueWatching' => 'Selanjutnya',
			'videoControls.autoPlayNext' => 'Auto-Play selanjutnya',
			'videoControls.playNext' => 'Mainkan selanjutnya',
			'videoControls.playButton' => 'Putar',
			'videoControls.pauseButton' => 'Jeda',
			'videoControls.playbackPaused' => 'beristirahat',
			'videoControls.playbackResumed' => 'Bermain',
			'videoControls.loadingVideo' => 'Download video',
			'videoControls.showPlaybackControls' => 'Menampilkan Playback Control',
			'videoControls.hidePlaybackControls' => 'Menggunakan Playback Control',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Mencari ke belakang ${seconds} detik',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Mencari ke depan ${seconds} detik',
			'videoControls.previousButton' => 'episode sebelumnya',
			'videoControls.nextButton' => 'Episode Selanjutnya',
			'videoControls.previousChapterButton' => 'Bab sebelumnya',
			'videoControls.nextChapterButton' => 'Bab selanjutnya',
			'videoControls.muteButton' => 'Bisukan',
			'videoControls.unmuteButton' => 'Membunyikan',
			'videoControls.settingsButton' => 'Pengaturan Playback',
			'videoControls.tracksButton' => 'Audio dan Subtitle',
			'videoControls.trackSelectionTitle' => 'Pilih jalur sebelum playback',
			'videoControls.trackSelectionAuto' => 'Seleksi otomatis',
			'videoControls.chaptersButton' => 'bab yang',
			'videoControls.versionQualityButton' => 'Versi & Kualitas',
			'videoControls.versionColumnHeader' => 'Versi',
			'videoControls.qualityColumnHeader' => 'Kualitas',
			'videoControls.qualityOriginal' => 'asli',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcoding tidak tersedia – bermain kualitas asli',
			'videoControls.subtitleUnavailableFallback' => 'Subtitle yang dipilih tidak dapat dimuat — terus tanpa subtitle',
			'videoControls.pipButton' => 'Gambar dalam mode',
			'videoControls.openMiniPlayer' => 'Pemain mini terbuka',
			'videoControls.returnToFullPlayer' => 'Kembali ke Full Player',
			'videoControls.aspectRatioButton' => 'Rasio perbandingan',
			'videoControls.ambientLighting' => 'Lampu Lingkungan',
			'videoControls.fullscreenButton' => 'Masuk ke layar penuh',
			'videoControls.exitFullscreenButton' => 'Penampilan Full Screen',
			'videoControls.alwaysOnTopButton' => 'Selalu di atas',
			'videoControls.rotationLockButton' => 'Lock rotasi',
			'videoControls.lockScreen' => 'Lock layar',
			'videoControls.screenLockButton' => 'layar lock',
			'videoControls.longPressToUnlock' => 'Tekan panjang untuk membuka kunci',
			'videoControls.timelineSlider' => 'Video Timeline',
			'videoControls.volumeSlider' => 'Tingkat Volume',
			'videoControls.endsAt' => ({required Object time}) => 'Berakhir di ${time}',
			'videoControls.pipActive' => 'Bermain dalam Picture-in-Picture',
			'videoControls.pipFailed' => 'Gambar-gambar yang gagal dimulai',
			'videoControls.screenshotSaved' => 'Screenshot disimpan',
			'videoControls.screenshotFailed' => 'Tidak bisa mengambil screenshot',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volume ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Memerlukan Android 8.0 atau lebih baru',
			'videoControls.pipErrors.iosVersion' => 'Memerlukan iOS 15.0 atau lebih baru',
			'videoControls.pipErrors.permissionDisabled' => 'Image-in-image disabled. memungkinkan dalam pengaturan sistem.',
			'videoControls.pipErrors.notSupported' => 'Perangkat tidak mendukung mode gambar-in-gambar',
			'videoControls.pipErrors.voSwitchFailed' => 'gagal menukar output video untuk gambar-dalam-gambar',
			'videoControls.pipErrors.failed' => 'Gambar-gambar yang gagal dimulai',
			'videoControls.pipErrors.prepareFailed' => 'Gambar-gambar dalam-gambar tidak dapat disiapkan',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Kesalahan yang terjadi: ${error}',
			'videoControls.chapters' => 'bab yang',
			'videoControls.noChaptersAvailable' => 'Tidak ada bab yang tersedia',
			'videoControls.queue' => 'Keuangan',
			'videoControls.noQueueItems' => 'Tidak ada item dalam kue',
			'videoControls.noAudioDevicesAvailable' => 'Tidak ada audio yang tersedia',
			'videoControls.searchSubtitles' => 'Temuan Subtitle',
			'videoControls.loadSubtitleFile' => 'Download file subtitle.',
			'videoControls.subtitleLoadFailed' => 'gagal mengisi file subtitle',
			'videoControls.language' => 'Bahasa',
			'videoControls.noSubtitlesFound' => 'Tidak ditemukan subtitle',
			'videoControls.subtitleDownloaded' => 'Subtitle diunduh',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle diunduh, tapi tidak bisa dipilih',
			'videoControls.subtitleDownloadFailed' => 'Tidak bisa download subtitle',
			'videoControls.searchLanguages' => 'Bahasa pencarian...',
			'videoControls.skipIntro' => 'Pergi ke Into',
			'videoControls.skipCredits' => 'Skripsi Kredit',
			'videoControls.skipAds' => 'Pemberitahuan Skip',
			'videoControls.nextEpisode' => 'Episode Selanjutnya',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Jalan Raya ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Subtitel ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Penggunaan)',
			'videoControls.osdSubtitlesOff' => 'Judul : Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Nama Panggilan : ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio : ${track}',
			'messages.markedAsWatched' => 'Ditandai seperti yang dilihat',
			'messages.markedAsUnwatched' => 'Ditandai sebagai tidak diperhatikan',
			'messages.markedAsWatchedOffline' => 'Ditandai seperti yang dilihat (sinkronisasi saat online)',
			'messages.markedAsUnwatchedOffline' => 'Ditandai sebagai tidak dipantau (sinkronisasi saat online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Penghapusan otomatis: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menonton download', ), 
			'messages.removedFromContinueWatching' => 'Menghapus dari terus menonton',
			'messages.errorLoading' => ({required Object error}) => 'Kesalahan : ${error}',
			'messages.searchPartialResults' => 'Beberapa server media tidak dapat dicari. menunjukkan hasil yang tersedia.',
			'messages.streamInterrupted' => 'Stream dihentikan. bermain atau mencoba untuk berundur.',
			'messages.liveStreamInterrupted' => 'Stream langsung dihentikan. pers bermain untuk retry.',
			'messages.fileInfoNotAvailable' => 'Informasi file tidak tersedia',
			'messages.playbackAuthenticationRequired' => 'Mendaftar kembali ke server media untuk memainkan item ini.',
			'messages.playbackServerUnavailable' => 'Server media tidak tersedia. coba lagi nanti.',
			'messages.playbackDataInvalid' => 'Server mengembalikan informasi playback yang tidak sah.',
			'messages.playbackCancelled' => 'Playback sudah dibatalkan.',
			'messages.playbackFailed' => 'Playback tidak bisa dimulai.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback tidak bisa dimulai: ${error}',
			'messages.audioOutputFailed' => 'Periksa koneksi audio TV atau penerima; jika aplikasi lain tidak memiliki suara juga, memulai ulang perangkat.',
			'messages.mediaUnavailable' => 'Konten ini tidak lagi tersedia.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Info file kesalahan: ${error}',
			'messages.errorLoadingSeries' => 'Serangkaian Error Loading',
			'messages.musicNotSupported' => 'Playback musik belum disokong',
			'messages.noDescriptionAvailable' => 'Tidak ada deskripsi yang tersedia',
			'messages.noProfilesAvailable' => 'Tidak ada profil tersedia',
			'messages.contactAdminForProfiles' => 'Hubungi administrator server Anda untuk menambahkan profil',
			'messages.unableToDetermineLibrarySection' => 'Tidak dapat menentukan bagian perpustakaan untuk item ini',
			'messages.logsCleared' => 'Log yang dibersihkan',
			'messages.logsCopied' => 'Daftar yang disalin ke clipboard',
			'messages.noLogsAvailable' => 'Tidak ada log yang tersedia',
			'messages.libraryScanning' => ({required Object title}) => 'Mengimbas “${title}”',
			'messages.libraryScanStarted' => ({required Object title}) => 'Scan perpustakaan dimulai untuk "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Tidak berhasil memindai perpustakaan: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Metadata yang diperbaharui untuk "${title}..."',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadata pembaharuan dimulai untuk "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Tidak dapat memperbarui metadata: ${error}',
			'messages.logoutConfirm' => 'Apakah Anda yakin Anda ingin keluar?',
			'messages.noSeasonsFound' => 'Tidak ada musim ditemukan',
			'messages.seasonsLoadFailed' => 'Tidak bisa mengisi musim',
			'messages.noEpisodesFound' => 'Tidak ada episode yang ditemukan di musim pertama',
			'messages.noEpisodesFoundGeneral' => 'Tidak ditemukan episode',
			'messages.episodesLoadFailed' => 'Tidak bisa memuat episode',
			'messages.noResultsFound' => 'Tidak ada hasil.',
			'messages.sleepTimerSet' => ({required Object label}) => 'Waktu tidur untuk ${label}',
			'messages.noItemsAvailable' => 'Tidak ada item yang tersedia',
			'messages.failedToCreatePlayQueueNoItems' => 'Tidak berhasil membuat kue permainan - tidak ada item',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kegagalan ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Beralih ke pemain yang kompatibel.',
			'messages.serverLimitTitle' => 'Playback gagal',
			'messages.serverLimitBody' => 'Kesalahan server (HTTP 500). batas bandwidth/transcoding mungkin menolak sesi ini.',
			'messages.mediaUnreadableTitle' => 'File yang tidak tersedia',
			'messages.mediaUnreadableBody' => 'Server menemukan item ini tetapi tidak dapat membaca file (HTTP 404). file ini mungkin telah dipindahkan, dihapus, atau penyimpanannya offline.',
			'messages.serverBusyTitle' => 'Stream tidak tersedia',
			'messages.serverBusyBody' => 'Server tetap menolak untuk streaming file ini (HTTP 503). itu mungkin restarting, sibuk, atau penyimpanan file mungkin offline. cuba lagi dalam beberapa saat — jika itu terus terjadi, minta pemilik server untuk memeriksa server dan penyimpanan file.',
			'messages.playbackNotAllowedTitle' => 'Playback tidak diizinkan',
			'messages.playbackNotAllowedBody' => 'Server menolak untuk streaming item ini (HTTP 403). akun Anda mungkin tidak memiliki izin untuk memainkannya, atau server mungkin hanya memungkinkan pemutaran di jaringan lokalnya.',
			'messages.logsUploaded' => 'Log yang diunggah',
			'messages.logsUploadFailed' => 'gagal mengunggah log',
			'messages.logId' => 'ID log',
			'messages.burnedSubtitlesUseMenu' => 'Subtitle dibakar ke dalam aliran ini. mengubahnya dari menu subtitle.',
			'messages.noVideoUrl' => 'Tidak ada URL video',
			'messages.playbackNoMediaSources' => 'Server tidak mengembalikan sumber media yang dapat dimainkan',
			'messages.playbackDataNotPrepared' => 'Playback dimulai sebelum data siap.',
			'messages.streamSelectionUnavailable' => 'Stream seleksi tidak tersedia untuk sumber ini',
			'messages.streamSelectionFailed' => 'Tidak dapat menggunakan aliran yang dipilih',
			'messages.trackSelectionNotRemembered' => 'Pilihan track ini hanya berlaku untuk playback saat ini.',
			'messages.serverUnavailableForProfile' => 'Tidak ada server yang tersedia untuk profil aktif',
			'subtitlingStyling.previewSample' => 'Kucing coklat cepat melompat ke atas anjing lazy',
			'subtitlingStyling.text' => 'Teks',
			'subtitlingStyling.border' => 'Perbatasan',
			'subtitlingStyling.background' => 'latar belakang',
			'subtitlingStyling.fontSize' => 'Ukuran Font',
			'subtitlingStyling.textColor' => 'Warna teks',
			'subtitlingStyling.borderSize' => 'Ukuran Perbatasan',
			'subtitlingStyling.borderColor' => 'Perbatasan warna',
			'subtitlingStyling.backgroundOpacity' => 'Latar Belakang Opacity',
			'subtitlingStyling.backgroundColor' => 'warna latar belakang',
			'subtitlingStyling.position' => 'Posisi',
			'subtitlingStyling.assOverride' => 'ASS Perbedaan',
			'subtitlingStyling.overrideScale' => 'Skala',
			'subtitlingStyling.overrideForce' => 'Kekuatan',
			'subtitlingStyling.overrideStrip' => 'Menghapus styling',
			'subtitlingStyling.positionTop' => 'Top',
			'subtitlingStyling.positionBottom' => 'Bawah',
			'subtitlingStyling.useMargins' => 'Menggunakan margin',
			'subtitlingStyling.useMarginsDescription' => 'Biarkan subtitle teks di ruang di luar video. subtitle bergaya dapat menjaga penempatan asli mereka.',
			'subtitlingStyling.anchorToScreen' => 'Anchor untuk layar',
			'subtitlingStyling.anchorToScreenDescription' => 'Tunjukkan subtitle teks di bar hitam di bawah video layar lebar',
			'subtitlingStyling.bold' => 'Tebal',
			'subtitlingStyling.italic' => 'Italia',
			'subtitlingStyling.renderResolution' => 'Resolusi Render',
			'subtitlingStyling.renderResolutionScreen' => 'Resolusi Layar',
			'subtitlingStyling.renderResolutionVideo' => 'Resolusi Video',
			'subtitlingStyling.fontSizeDescription' => 'Tetapkan ukuran subtitle teks pada perangkat ini.',
			'subtitlingStyling.textColorDescription' => 'Pilih warna yang digunakan untuk subtitle teks.',
			'subtitlingStyling.borderSizeDescription' => 'Tetapkan ketebalan outline di sekitar subtitle teks.',
			'subtitlingStyling.borderColorDescription' => 'Pilih warna yang digunakan untuk subtitle outline.',
			'subtitlingStyling.backgroundColorDescription' => 'Pilih warna di belakang subtitle.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Tetapkan betapa transparan latar belakang subtitle: 0% jelas dan 100% solid.',
			'subtitlingStyling.positionDescription' => 'Pergerakan subtitle secara vertikal. 0% adalah bagian atas video dan 100% adalah bagian bawah.',
			'subtitlingStyling.assOverrideDescription' => 'Pilih apakah pemain mengikuti, menyesuaikan, mengganti, atau menghapus gaya yang tertanam dalam subtitle ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Simpan huruf, warna, ukuran, dan penempatan yang ditulis dalam subtitle file.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Memungkinkan pengaturan gaya subtitle pemain untuk menyesuaikan subtitle ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Mengaplikasikan gaya pemain dan skala ukuran tertanam untuk memenuhi dimensi video.',
			'subtitlingStyling.assOverrideOptions.force' => 'Mengganti gaya ASS yang tertanam dengan gaya subtitle pemain.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Menghapus format ASS tertanam dan membuat subtitle teks dengan jelas.',
			'subtitlingStyling.renderResolutionDescription' => 'Pilih resolusi yang digunakan untuk rasterize gambar dan subtitle ASS. Skala Android yang lebih rendah dapat mengurangi kerja rendering tetapi terlihat lebih lembut.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render pada resolusi permukaan layar penuh untuk hasil yang paling tajam.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render menggunakan resolusi video sebagai referensi, yang dapat mengurangi pekerjaan pada paparan resolusi tinggi.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Rendah pada 75% resolusi permukaan paparan untuk penjimatan kinerja yang sederhana.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render pada 50% resolusi permukaan paparan untuk mengurangi kerja, dengan tepi yang lebih lembut.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render pada satu pertiga resolusi permukaan paparan untuk mengurangi pekerjaan, dengan tepi yang lebih lembut.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render pada satu perempat dari resolusi permukaan paparan untuk mengurangi kerja, dengan hasil yang paling lembut.',
			'subtitlingStyling.boldDescription' => 'Cetak subtitle teks dalam berat yang lebih berat.',
			'subtitlingStyling.italicDescription' => 'Menarik subtitle teks dalam bahasa Italia.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Pengaturan pemutar video lanjutan',
			'mpvConfig.presets' => 'Preset',
			'mpvConfig.noPresets' => 'Tidak ada preset yang terselamat',
			'mpvConfig.saveAsPreset' => 'Menyelamatkan sebagai preset.',
			'mpvConfig.presetName' => 'Nama Praset',
			'mpvConfig.presetNameHint' => 'Masukkan nama untuk preset ini',
			'mpvConfig.loadPreset' => 'beban',
			'mpvConfig.deletePreset' => 'Hapus',
			'mpvConfig.presetSaved' => 'Preset diselamatkan',
			'mpvConfig.presetLoaded' => 'Preset yang diisi',
			'mpvConfig.presetDeleted' => 'Preset dihapus',
			'mpvConfig.confirmDeletePreset' => 'Apakah Anda yakin Anda ingin menghapus preset ini?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # komentar',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Tambahkan garis',
			'mpvConfig.removeLine' => 'Menghapus garis',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-kontekst dan gpu-api diabaikan pada Linux: video tertanam selalu mengalir melalui vo=libmpv pada pesawat video, dan gpu-next (yang komputasi bayangan seperti ArtCNN perlu) tidak dapat berjalan tertanam.',
			'dialog.confirmAction' => 'Mengkonfirmasi Tindakan',
			'profiles.addPlezyProfile' => 'Tambahkan profil PlezyNG',
			'profiles.switchingProfile' => 'Mengganti profil...',
			'profiles.deleteThisProfileTitle' => 'Menghapus profil ini?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Menghapus ${displayName}. sambungan tidak terganggu.',
			'profiles.active' => 'aktif',
			'profiles.manage' => 'Manajemen',
			'profiles.delete' => 'Hapus',
			'profiles.signOut' => 'Sign out',
			'profiles.signOutPlexTitle' => 'Mendaftar keluar dari Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Menghapus ${displayName} dan semua Plex Pengguna Rumah?',
			'profiles.signOutPlexDeleteDownloads' => 'Juga menghapus download',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Jika tidak, unduhan tetap disimpan di perangkat ini dan tersedia lagi saat Anda masuk kembali ke akun ini.',
			'profiles.signedOutPlex' => 'Ditandatangani dari Plex.',
			'profiles.signOutFailed' => 'Menandatangani gagal',
			'profiles.sectionTitle' => 'Profil',
			'profiles.summarySingle' => 'Menambahkan profil untuk mencampur pengguna yang dikelola dan identitas lokal',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profil · aktif: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} Profil',
			'profiles.removeConnectionTitle' => 'Menghapus koneksi?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Menghapus akses ${displayName} ke ${connectionLabel}. profil lainnya menyimpannya.',
			'profiles.deleteProfileTitle' => 'Menghapus profil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Menghapus ${displayName} dan koneksi. server tetap tersedia.',
			'profiles.profileNameLabel' => 'Nama Profil',
			'profiles.pinProtectionLabel' => 'Perlindungan PIN',
			'profiles.copyAutomationLink' => 'Kopi Android link otomatisasi',
			'profiles.copyAutomationLinkDescription' => 'Pilih profil ini dari tujuan atau otomatisasi Android. verifikasi PIN profil masih berlaku.',
			'profiles.automationLinkCopied' => 'Profil otomatis link disalin.',
			'profiles.pinManagedByPlex' => 'PIN yang dikelola oleh Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Tidak ada set PIN. Untuk meminta satu, mengedit pengguna rumah di plex.tv.',
			'profiles.setPin' => 'Mengatur PIN',
			'profiles.setPinTitle' => 'Mengatur PIN',
			'profiles.confirmPinTitle' => 'Mengkonfirmasi PIN',
			'profiles.pinSet' => 'PIN Set',
			'profiles.changePin' => 'Perubahan',
			'profiles.removePin' => 'Hapus',
			'profiles.connectionsLabel' => 'Hubungan',
			'profiles.add' => 'Tambah',
			'profiles.deleteProfileButton' => 'Menghapus profil',
			'profiles.noConnectionsHint' => 'Tidak ada koneksi — tambahkan satu untuk menggunakan profil ini.',
			'profiles.noConnections' => 'Tidak ada koneksi',
			'profiles.plexHomeAccount' => 'Plex Akun Rumah',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex Akun: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} melalui ${account}',
			'profiles.connectionDefault' => 'Bawaan',
			'profiles.connectionAs' => ({required Object displayName}) => 'Jumlah : ${displayName}',
			'profiles.makeDefault' => 'Membuat default',
			'profiles.removeConnection' => 'Hapus',
			'profiles.profileRenamed' => 'Profil yang disebutkan kembali.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Tambahkan ke ${displayName}',
			'profiles.borrowExplain' => 'Pinjam koneksi profil lain. profil yang dilindungi PIN membutuhkan PIN.',
			'profiles.borrowEmpty' => 'Belum ada yang bisa dipinjam.',
			'profiles.borrowEmptySubtitle' => 'Sambungkan Plex, Jellyfin, atau Emby ke profil lain terlebih dahulu.',
			'profiles.borrowLoadFailed' => 'Koneksi yang tersedia tidak dapat dimuat. coba lagi.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'dari ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Hubungan yang dipinjam.',
			'profiles.borrowFailed' => 'Tidak berhasil meminjam link.',
			'profiles.incorrectPin' => 'PIN yang tidak benar.',
			'profiles.incorrectPinTryAgain' => 'PIN yang salah, silakan coba lagi.',
			'profiles.sourceProfileMissingParentAccount' => 'Profil sumber hilang akun ibu.',
			'profiles.failedToLoadHomeUsers' => 'Tidak bisa memuat pengguna rumah Plex Anda. periksa koneksi Anda dan coba lagi.',
			'profiles.failedToVerifyPin' => 'Tidak dapat mengkonfirmasi PIN.',
			'profiles.newProfile' => 'Profil baru',
			'profiles.profileNameHint' => 'Misalnya, tamu, anak-anak, kamar keluarga',
			'profiles.pinProtectionOptional' => 'Perlindungan PIN (Optional)',
			'profiles.pinExplain' => 'PIN 4 digit diperlukan untuk menukar profil.',
			'profiles.continueButton' => 'Selanjutnya',
			'profiles.pinsDontMatch' => 'PIN tidak cocok',
			'profiles.tokenIdentityMismatch' => 'Token profil Plex diselesaikan ke server yang tidak dijangka',
			'profiles.settingsLocked' => 'Seting disekat untuk profil ini.',
			'profiles.unlockSettings' => 'Unlock pengaturan',
			'profiles.showExploreForProfile' => 'Tunjukkan eksplorasi untuk profil ini',
			'profiles.showExploreForProfileDescription' => 'Berhenti untuk menghapus Explore dari navigasi profil ini.',
			'connections.sectionTitle' => 'Hubungan',
			'connections.addConnection' => 'Tambahkan koneksi',
			'connections.addConnectionSubtitleNoProfile' => 'Mendaftar dengan Plex atau menghubungkan server Jellyfin atau Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Tambahkan ke ${displayName}: Plex, Jellyfin, Emby, atau koneksi profil lainnya',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sesi berakhir untuk ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sesi berakhir untuk server ${count}',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} menolak akses ke akun ini',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} server menolak akses untuk akun ini',
			'connections.signInAgain' => 'Menandatangani lagi',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Mengedit ${product} koneksi',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Menambahkan atau menghapus URL untuk ${serverName}. PlezyNG akan menggunakan URL yang dapat diakses dengan latensi terendah.',
			'accountPreferences.sectionTitle' => 'Keutamaan Akun',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Audio, subtitle, dan pilihan perpustakaan disimpan pada ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Audio, subtitle, dan pilihan perpustakaan disimpan pada ${count} akun',
			'accountPreferences.pickAccount' => 'Setiap akun menyimpan preferensi tersendiri. pilih satu untuk mengedit.',
			'accountPreferences.storedOnAccount' => 'Opsi ini disimpan di akun itu sendiri, sehingga setiap aplikasi yang terdaftar di dalamnya menggunakannya — termasuk PlezyNG pada perangkat lain Anda.',
			'accountPreferences.noAccounts' => 'Tidak ada akun yang dapat dikonfigurasi',
			'accountPreferences.noAccountsHint' => 'Mendaftar di Plex, atau terhubung ke server Jellyfin atau Emby, dan preferensi yang disimpan di akun tersebut ditampilkan di sini.',
			'accountPreferences.unavailable' => 'Tidak dapat mengakses akun ini',
			'accountPreferences.loadFailed' => 'Tidak bisa mengisi preferensi ini',
			'accountPreferences.noPreference' => 'Tidak ada preferensi',
			'accountPreferences.notSet' => 'Tidak menetapkan',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio dan Subtitle',
			'accountPreferences.groups.libraryDisplay' => 'Pustaka',
			'accountPreferences.groups.personalMedia' => 'Media pribadi',
			'accountPreferences.preferredAudioLanguage' => 'Bahasa audio yang disukai',
			'accountPreferences.autoSelectAudio' => 'Memilih Audio dengan Bahasa',
			'accountPreferences.autoSelectAudioDescription' => 'Menghapus apa pun audio track file mark sebagai default.',
			'accountPreferences.preferredSubtitleLanguage' => 'Bahasa teks yang diinginkan',
			'accountPreferences.subtitleMode' => 'Mengalihkan subtitle ke',
			'accountPreferences.subtitleModes.none' => 'Seleksi secara manual',
			'accountPreferences.subtitleModes.noneDescription' => 'Jangan pernah memutar subtitle sendiri.',
			'accountPreferences.subtitleModes.defaultMode' => 'Ikuti bendera track',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Gunakan bendera default dan paksa yang disimpan di setiap jalur subtitle.',
			'accountPreferences.subtitleModes.always' => 'Selalu diizinkan',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Beralih pada jalur subtitle dalam bahasa yang disukai setiap kali ada.',
			'accountPreferences.subtitleModes.onlyForced' => 'Hanya subtitle yang dipaksakan',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Hanya mengisi jalur yang ditandai sebagai paksa.',
			'accountPreferences.subtitleModes.smart' => 'Menampilkan Audio Asing',
			'accountPreferences.subtitleModes.smartDescription' => 'Tukar subtitle hanya ketika audio berada dalam bahasa lain.',
			'accountPreferences.subtitleAccessibility' => 'SDH subtitle',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Lebih Baik Subtitle Non-SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Lebih suka subtitle SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Hanya subtitle SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Hanya subtitle non-SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Anda lebih suka subtitle standar ketika kedua versi standar dan SDH tersedia.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Saya lebih suka subtitle SDH saat tersedia, tetapi memungkinkan subtitle standar sebagai downback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Gunakan subtitle SDH saja; jangan jatuh kembali ke subtitle standar.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Gunakan subtitle standar saja; mengecualikan subtitle SDH.',
			'accountPreferences.forcedSubtitles' => 'Subtitle yang dipaksa',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Lebih suka subtitle yang tidak terikat',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Lebih suka subtitle',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Hanya subtitle yang dipaksakan',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Hanya subtitle yang tidak dipaksakan',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Lebih suka subtitles biasa, tetapi memungkinkan trek paksa sebagai penurunan.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Mereka lebih suka trek paksa ketika tersedia, tetapi memungkinkan subtitle biasa sebagai downback.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Gunakan hanya jalur yang ditandai sebagai paksa.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Mengecualikan jalur yang ditandai sebagai paksa.',
			'accountPreferences.displayMissingEpisodes' => 'Menampilkan episode yang hilang',
			'accountPreferences.displayMissingEpisodesDescription' => 'Daftar episode yang server tahu tentang tetapi tidak memiliki file untuk.',
			'accountPreferences.hidePlayedInLatest' => 'Temukan item yang ditonton di terbaru',
			'accountPreferences.hidePlayedInLatestDescription' => 'Tinggalkan item yang sudah Anda lihat dari baris terbaru server.',
			'accountPreferences.displayCollectionsView' => 'Tampilkan Koleksi View',
			'accountPreferences.displayCollectionsViewDescription' => 'Tawarkan tampilan Koleksi server di samping perpustakaan Anda.',
			'accountPreferences.rewatchingInNextUp' => 'Tinggalkan persembahan di Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'Setelah Anda menyelesaikan sebuah acara, mulai lagi dan Next Up mengikuti rewatch bukannya menurunkan acara.',
			'accountPreferences.watchedIndicator' => 'Indikator yang diperhatikan',
			'accountPreferences.watchedIndicatorOptions.none' => 'Tidak Pernah',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Film dan acara televisi',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Hanya film',
			'accountPreferences.watchedIndicatorOptions.shows' => 'TV hanya menampilkan',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Jangan menampilkan tanda-tanda yang dipantau.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Menampilkan tanda-tanda yang ditonton untuk film dan acara TV.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Tampilkan tanda-tanda yang ditonton untuk film saja.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Menampilkan tanda-tanda yang ditonton untuk acara TV saja.',
			'accountPreferences.mediaReviewsVisibility' => 'Rating & Ulasan',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Pengguna dan kritikus',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Pengguna hanya',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Hanya kritikan',
			'accountPreferences.mediaReviewsOptions.nobody' => 'tersembunyi',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Tampilkan kedua penarafan pengguna dan penilaian kritis.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Tunjukkan penilaian dan ulasan yang disampaikan oleh pengguna.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Tunjukkan penilaian kritis dan ulasan.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Temukan rating dan ulasan.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Anda lebih suka track audio dalam bahasa ini ketika server atau pemain secara otomatis memilih track.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Lebih baik mengikuti subtitle dalam bahasa ini ketika subtitle dipilih secara otomatis.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Pilih apakah capsi SDH disukai atau diperlukan selama pemilihan subtitle otomatis.',
			'accountPreferences.forcedSubtitleDescription' => 'Pilih apakah jalur subtitle paksa disukai atau diperlukan selama pemilihan otomatis.',
			'accountPreferences.watchedIndicatorDescription' => 'Pilih jenis media yang menerima tanda kontrol yang ditonton di antara muka server.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Pilih penonton dan kritikan mana yang ditampilkan oleh server di halaman media.',
			'accountPreferences.subtitleModeDescription' => 'Pilih kapan subtitle secara otomatis dimulai untuk akun server ini.',
			'accountPreferences.hubDescription' => 'Keutamaan ini disimpan di akun media-server Anda dan mungkin berlaku untuk klien lain juga.',
			'discover.title' => 'Temukan',
			'discover.noContentAvailable' => 'Tidak ada konten yang tersedia',
			'discover.addMediaToLibraries' => 'Tambahkan beberapa media ke perpustakaan Anda',
			'discover.continueWatching' => 'Lanjutkan menonton',
			'discover.continueWatchingIn' => ({required Object library}) => 'Lihat lagi reviu untuk ${library}',
			'discover.nextUp' => 'Selanjutnya',
			'discover.nextUpIn' => ({required Object library}) => 'Berikutnya di ${library}',
			'discover.recentlyAdded' => 'Terbaru',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Baru-baru ini ditambahkan di ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Album terbaru di ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Dimainkan di ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Paling banyak dimainkan di ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Tinjauan',
			'discover.cast' => 'Tembak',
			'discover.findNext.title' => 'Temukan pilihan berikutnya',
			'discover.findNext.open' => 'Temukan pilihan berikutnya',
			'discover.findNext.anyTime' => 'Tanpa batas waktu',
			'discover.findNext.timeAvailable' => 'Berapa banyak waktu yang Anda punya?',
			'discover.findNext.filters' => 'Pilih yang sesuai saat ini',
			'discover.findNext.watch' => 'Tonton',
			'discover.findNext.listen' => 'Dengarkan',
			'discover.findNext.read' => 'Baca',
			'discover.findNext.finishable' => ({required Object duration}) => 'Bisa selesai dalam ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Sekitar ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Bab berikutnya · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Total ${duration}',
			'discover.findNext.timingVaries' => 'Durasi bervariasi',
			'discover.findNext.notNow' => 'Tidak sekarang',
			'discover.findNext.swipeHint' => 'Geser sampul ke arah panah atau gunakan tombol di bawah.',
			'discover.findNext.saved' => 'Pilihan tersimpan',
			'discover.findNext.savedCount' => ({required Object count}) => 'Pilihan tersimpan · ${count}',
			'discover.findNext.undo' => 'Urungkan',
			'discover.findNext.details' => 'Detail',
			'discover.findNext.noPicks' => 'Belum ada pilihan',
			'discover.findNext.noPicksHint' => 'Hubungkan perpustakaan atau tambahkan sumber media untuk memulai.',
			'discover.findNext.noMatches' => 'Belum ada yang cocok saat ini',
			'discover.findNext.noMatchesHint' => 'Coba jenis media lain atau luangkan lebih banyak waktu.',
			'discover.findNext.allDone' => 'Semua pilihan sudah Anda lihat',
			'discover.findNext.allDoneHint' => 'Mulai kumpulan baru untuk melihat pilihan ini lagi.',
			'discover.findNext.refresh' => 'Cari kumpulan pilihan lain',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Dari ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Dari ${library}',
			'discover.findNext.ownedReason' => 'Dari perpustakaan Anda',
			'discover.findNext.liveNow' => 'Sedang tayang',
			'discover.findNext.watchLive' => 'Tonton siaran langsung',
			'discover.findNext.filterAnything' => 'Apa saja',
			'discover.findNext.filterWatch' => 'Tonton',
			'discover.findNext.filterListen' => 'Dengarkan',
			'discover.findNext.filterRead' => 'Baca',
			'discover.findNext.twentyMinutes' => '20 menit',
			'discover.findNext.fortyFiveMinutes' => '45 menit',
			'discover.findNext.ninetyMinutes' => '90 menit',
			'discover.findNext.apply' => 'Terapkan',
			'discover.findNext.openFailed' => 'Pilihan ini sudah tidak tersedia. Segarkan untuk memeriksa lagi.',
			'discover.findNext.changeFailed' => 'Perubahan tidak dapat disimpan. Coba lagi.',
			'discover.findNext.savedLimit' => 'Daftar pilihan tersimpan sudah penuh. Hapus satu pilihan untuk menyimpan yang lain.',
			'discover.findNext.chooseHint' => 'Buka judul, simpan untuk nanti, atau lewati.',
			'discover.findNext.howItWorks' => 'Cara menggunakan',
			'discover.findNext.notNowHelp' => 'Lewati judul ini untuk saat ini. Judul tetap ada di pustaka Anda.',
			'discover.findNext.saveHelp' => 'Simpan ke pilihan tersimpan profil ini di perangkat ini. Menyimpan tidak mengunduh judul.',
			'discover.findNext.openHelp' => 'Pilih sampul untuk melihat detail. Gunakan tindakan utama untuk memutar, membaca, atau membuka judul.',
			'discover.findNext.controlsHelp' => 'Keyboard atau remote: fokuskan tombol, lalu tekan Enter atau Pilih. Urungkan mengembalikan pilihan terakhir Anda.',
			'discover.findNext.artworkLoading' => 'Memuat gambar…',
			'discover.findNext.artworkUnavailable' => 'Gambar tidak tersedia',
			'discover.findNext.savedFeedback' => 'Ditambahkan ke pilihan tersimpan',
			'discover.findNext.skippedFeedback' => 'Dilewati untuk saat ini',
			'discover.findNext.releaseToConfirm' => 'Lepaskan untuk mengonfirmasi',
			'discover.findNext.remoteHint' => 'Saat sampul terfokus: ← / → memilih · Pilih: detail · ↑ / ↓ pindah fokus',
			'discover.extras' => 'Trailer dan Ekstras',
			'discover.studio' => 'Studio yang',
			'discover.rating' => 'Peringkat',
			'discover.director' => 'Direktur',
			'discover.directors' => 'Direktur',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'televisi show',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min dibatasi',
			'discover.moreLikeThis' => 'Lainnya Seperti Ini',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} judul', ), 
			'discover.person.born' => 'lahir',
			'discover.person.died' => 'meninggal',
			'discover.person.birthplace' => 'Tempat lahir',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (usia ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (usia ${age})',
			'errors.searchFailed' => ({required Object error}) => 'Pencarian gagal: ${error}',
			'errors.searchUnavailable' => 'Pencarian tidak dapat mencapai server media apapun.',
			'errors.connectionTimeout' => ({required Object context}) => 'Menghubungkan timeout saat muat ${context}',
			'errors.connectionFailed' => 'Tidak dapat terhubung ke server media',
			'errors.unableToLoad' => ({required Object context}) => 'Tidak dapat mengisi ${context}. silakan coba lagi.',
			'errors.noClientAvailable' => 'Tidak ada klien yang tersedia',
			'errors.pleaseEnterToken' => 'Silakan masukkan token',
			'errors.invalidToken' => 'Token tidak valid',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Tidak dapat mengkonfirmasi token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Tidak dapat beralih ke ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Tidak dapat dihapus ${displayName}',
			'errors.failedToRate' => 'Tidak bisa update rating',
			'errors.reasonTimedOut' => 'Koneksi yang ditempuh',
			'errors.reasonUnreachable' => 'Server tidak dapat diakses',
			'errors.reasonRefused' => 'Server menolak permintaan',
			'errors.reasonNotFound' => 'Item ini tidak lagi di server',
			'errors.reasonServerError' => 'Server melaporkan kesalahan',
			'errors.reasonCancelled' => 'Permintaan ini dibatalkan',
			'errors.reasonUnexpected' => 'Salah yang tak terduga terjadi',
			'libraries.playRandomMovie' => 'Mainkan film yang rahasia',
			'libraries.randomPickFailed' => 'Tidak bisa memilih film rawak dari perpustakaan ini.',
			'libraries.title' => 'Pustaka',
			'libraries.fallbackTitle' => 'Pustaka',
			'libraries.scanLibraryFiles' => 'Perpustakaan file scan',
			'libraries.scanLibrary' => 'Pindai pustaka',
			'libraries.analyze' => 'Analisis',
			'libraries.analyzeLibrary' => 'Analisis Perpustakaan',
			'libraries.refreshMetadata' => 'Segarkan metadata',
			'libraries.emptyTrash' => 'Tembusan kosong',
			'libraries.emptyingTrash' => ({required Object title}) => 'Menghilangkan sampah untuk "${title}..."',
			'libraries.trashEmptied' => ({required Object title}) => 'Langkah-langkah untuk "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Kegagalan untuk membuang sampah kosong: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Berdasarkan analisis “${title}”',
			'libraries.analysisStarted' => ({required Object title}) => 'Analisis dimulai untuk "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Tidak berhasil menganalisis perpustakaan: ${error}',
			'libraries.noLibrariesFound' => 'Tidak ditemukan perpustakaan',
			'libraries.allLibrariesHidden' => 'Semua perpustakaan tersembunyi',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Perpustakaan Tersembunyi (${count})',
			'libraries.thisLibraryIsEmpty' => 'Perpustakaan ini kosong',
			'libraries.noItemsMatchFilters' => 'Tidak ada item yang sesuai dengan filter aktif',
			'libraries.resetFilters' => 'Reset filter',
			'libraries.all' => 'Semua',
			'libraries.clearAll' => 'jelas semua',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Apakah Anda yakin Anda ingin memindai "${title}"?',
			_ => null,
		} ?? switch (path) {
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Apakah Anda yakin Anda ingin menganalisis "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Apakah Anda yakin ingin memperbarui metadata untuk "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Apakah Anda yakin Anda ingin mengosongkan sampah untuk "${title}"?',
			'libraries.manageLibraries' => 'Manajemen Perpustakaan',
			'libraries.sort' => 'Menyortir',
			'libraries.sortBy' => 'Sortir dengan',
			'libraries.filters' => 'Filter',
			'libraries.confirmActionMessage' => 'Apakah Anda yakin Anda ingin melakukan tindakan ini?',
			'libraries.showLibrary' => 'Tampilkan perpustakaan',
			'libraries.hideLibrary' => 'Perpustakaan tersembunyi',
			'libraries.libraryOptions' => 'Pilihan perpustakaan',
			'libraries.content' => 'Perpustakaan konten',
			'libraries.selectLibrary' => 'Pilih perpustakaan',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filter (${count})',
			'libraries.noRecommendations' => 'Tidak ada rekomendasi tersedia',
			'libraries.noCollections' => 'Tidak ada koleksi di perpustakaan ini',
			'libraries.noFoldersFound' => 'Tidak ditemukan folder',
			'libraries.folders' => 'Folder',
			'libraries.tabs.recommended' => 'Disarankan',
			'libraries.tabs.browse' => 'Jelajah',
			'libraries.tabs.collections' => 'Koleksi',
			'libraries.tabs.playlists' => 'Daftar putar',
			'libraries.groupings.title' => 'kelompok',
			'libraries.groupings.all' => 'Semua',
			'libraries.groupings.movies' => 'Film',
			'libraries.groupings.shows' => 'Acara TV',
			'libraries.groupings.seasons' => 'Musim',
			'libraries.groupings.episodes' => 'Semua episode',
			'libraries.groupings.artists' => 'Artis',
			'libraries.groupings.albums' => 'Album',
			'libraries.groupings.tracks' => 'Trek',
			'libraries.groupings.folders' => 'Folder',
			'libraries.filterCategories.genre' => 'Aliran',
			'libraries.filterCategories.year' => 'Tahun',
			'libraries.filterCategories.contentRating' => 'Penilaian konten',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'tidak diperhatikan',
			'libraries.filterCategories.unplayed' => 'Belum dimainkan',
			'libraries.filterCategories.favorites' => 'Favorit',
			'libraries.filterCategories.filePath' => 'Jalur berkas',
			'libraries.sortLabels.title' => 'Judul',
			'libraries.sortLabels.dateAdded' => 'Tanggal ditambahkan',
			'libraries.sortLabels.releaseDate' => 'Tanggal rilis',
			'libraries.sortLabels.rating' => 'Peringkat',
			'libraries.sortLabels.communityRating' => 'Peringkat komunitas',
			'libraries.sortLabels.criticRating' => 'Kritis Rating',
			'libraries.sortLabels.userRating' => 'Rating Pengguna',
			'libraries.sortLabels.datePlayed' => 'Tanggal dimainkan',
			'libraries.sortLabels.playCount' => 'Hitung Putaran',
			'libraries.sortLabels.productionYear' => 'Tahun Produksi',
			'libraries.sortLabels.runtime' => 'Durasi',
			'libraries.sortLabels.officialRating' => 'Rating resmi',
			'libraries.sortLabels.premiereDate' => 'Tanggal Tayang Perdana',
			'libraries.sortLabels.startDate' => 'Tanggal dimulai',
			'libraries.sortLabels.airTime' => 'Jam tayang',
			'libraries.sortLabels.studio' => 'Studio yang',
			'libraries.sortLabels.random' => 'Acak',
			'libraries.sortLabels.dateShared' => 'Tanggal yang dibagi',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Episode Terakhir Air Date',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Episode Terakhir Ditambahkan',
			'libraries.sortLabels.dateDownloaded' => 'Tanggal yang diunduh',
			'libraries.sortLabels.size' => 'Ukuran',
			'libraries.sortLabels.library' => 'Pustaka',
			'libraries.advancedFilters.include' => 'Termasuk',
			'libraries.advancedFilters.exclude' => 'Pengecualian',
			'libraries.advancedFilters.any' => 'Apa saja',
			'libraries.advancedFilters.yes' => 'Ya',
			'libraries.advancedFilters.no' => 'Tidak',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Tidak ada ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} dipilih',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} dikecualikan',
			'libraries.advancedFilters.searchValues' => 'nilai pencarian',
			'libraries.advancedFilters.noValues' => 'Tidak ada nilai',
			'libraries.advancedFilters.matchContains' => 'Konteks',
			'libraries.advancedFilters.matchNotContains' => 'Tidak mengandung',
			'libraries.advancedFilters.matchIs' => 'adalah',
			'libraries.advancedFilters.matchIsNot' => 'Tidak ada',
			'libraries.advancedFilters.matchBeginsWith' => 'Mulai dengan',
			'libraries.advancedFilters.matchEndsWith' => 'Berakhir dengan',
			'libraries.advancedFilters.textHint' => 'Jenis untuk Match',
			'libraries.advancedFilters.from' => 'dari',
			'libraries.advancedFilters.to' => 'Untuk',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} sampai ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} dan di atas',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Jumlah : ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} hari yang lalu',
			'libraries.advancedFilters.dateLastYear' => 'Tahun lalu',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Lebih dari ${count} hari',
			'libraries.advancedFilters.dateOlderThanYear' => 'Lebih dari 1 tahun',
			'libraries.selection.selectItems' => 'Pilih item',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} dipilih',
			'libraries.selection.actions' => 'Tindakan Seleksi',
			'libraries.selection.confirmDescendants' => 'Ini mengubah semua episode dalam acara dan musim yang dipilih.',
			'libraries.selection.confirmUnwatched' => 'Ini juga membersihkan kemajuan playback untuk item yang dipilih.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Jumlah item yang dipilih: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Item yang diperbarui: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Dikemas kini ${succeeded}; gagal ${failed}. item gagal tetap terpilih.',
			'about.title' => 'Tentang',
			'about.openSourceLicenses' => 'Lisensi sumber terbuka',
			'about.versionLabel' => ({required Object version}) => 'Versi ${version}',
			'about.appDescription' => 'Pelanggan yang indah Plex, Jellyfin, dan Emby untuk Flutter',
			'about.viewLicensesDescription' => 'Lihat lisensi perpustakaan pihak ketiga',
			'about.privacyPolicy' => 'Kebijakan Privasi',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Tidak ada server yang ditemukan untuk ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Server yang gagal dimuat: ${error}',
			'serverSelection.noValidServers' => 'Tidak ada server yang dapat digunakan di akun ini',
			'hubDetail.title' => 'Judul',
			'hubDetail.releaseYear' => 'Tahun Pembebasan',
			'hubDetail.dateAdded' => 'Tanggal ditambahkan',
			'hubDetail.rating' => 'Peringkat',
			'hubDetail.noItemsFound' => 'Tidak ada item ditemukan',
			'logs.clearLogs' => 'Log yang jelas',
			'logs.copyLogs' => 'Kopi Log',
			'logs.uploadLogs' => 'Mengunggah Logs',
			'logs.saveLogs' => 'Simpan log ke file',
			'logs.logsSaved' => ({required Object path}) => 'Daftar yang disimpan di ${path}',
			'logs.saveLogsFailed' => 'Tidak bisa menyimpan file log.',
			'detail.endsAt' => ({required Object time}) => 'Berakhir di ${time}',
			'startup.failedTitle' => 'PlezyNG tidak bisa memulai',
			'startup.failedBody' => 'Ada sesuatu yang salah selama startup. detail di bawah ini mengidentifikasi apa yang gagal.',
			'startup.failedBodyRepairable' => 'Berkas pengaturan PlezyNG yang tersimpan rusak dan harus dibuat ulang sebelum aplikasi dapat dimulai. Mencoba lagi tidak akan membantu — pilih Perbaiki penyimpanan.',
			'startup.phaseLabel' => 'Langkah',
			'startup.showDetails' => 'Tunjukkan detail',
			'startup.hideDetails' => 'Temukan detail',
			'startup.copyDetails' => 'Copy detail',
			'startup.detailsCopied' => 'Detail yang disalin ke clipboard',
			'startup.uploadDetails' => 'Upload Detail',
			'startup.repairStorage' => 'Perbaikan Penyimpanan',
			'startup.repairTitle' => 'Membaiki data yang disimpan?',
			'startup.repairBodyCommon' => 'file pengaturan PlezyNG rusak dan tidak dapat dibaca. perbaikan mengatur kembali setiap pengaturan ke defaultnya.',
			'startup.repairBodyOneCredential' => 'Satu login yang disimpan rosak dan tidak dapat dibaca. pembaikan menghapus hanya satu; seting lain Anda ditinggalkan sendirian.',
			'startup.repairBodySignInsKept' => 'Sesi masuk ke server dan profil Anda seharusnya tetap aktif.',
			'startup.repairBodySignInsLost' => 'Kunci yang melindungi data masuk tersimpan tidak dapat dipulihkan dari berkas ini. Anda harus masuk lagi ke setiap server dan profil. Tidak ada yang berubah di server media Anda.',
			'startup.repairBodySessionsUncertain' => 'Data pelacak (MAL, AniList, Simkl, Trakt) dan Seerr disimpan terpisah dan mungkin tetap tersimpan atau hilang. PlezyNG akan memberi tahu dengan tepat data yang dipertahankan.',
			'startup.repairConfirm' => 'Perbaikan',
			'startup.repairSucceeded' => 'Penyimpanan diperbaiki',
			'startup.repairNeedsRestart' => 'Penyimpanan diperbaiki - perlu memulai kembali',
			'startup.restartRequiredBody' => 'Data Anda telah diperbaiki, tetapi PlezyNG harus dimulai ulang sebelum dapat menggunakannya. Tutup PlezyNG lalu buka kembali.',
			'startup.quitPlezy' => 'Berdasarkan PlezyNG',
			'startup.repairFailed' => 'Perbaikan gagal',
			'startup.repairKeptSignIns' => 'Sesi masuk ke server dan profil Anda masih aktif.',
			'startup.repairLostSignIns' => 'Kunci melindungi sign-ins yang disimpan Anda tidak dapat dipulihkan. Anda akan perlu mendaftar masuk ke setiap server dan profil lagi.',
			'startup.repairLostSessions' => 'Sekurang-kurangnya satu tracker atau koneksi Seerr telah hilang dan harus dihubungkan kembali.',
			'startup.backupTitle' => 'Satu salinan file yang rusak disimpan',
			'startup.backupWarning' => 'Salinan ini berisi informasi masuk Anda. Jangan unggah atau bagikan.',
			'startup.deleteBackup' => 'Menghapus Kopi',
			'startup.backupDeleted' => 'Kopi yang dihapus.',
			'startup.previousFailureTitle' => 'PlezyNG gagal memulai kali terakhir',
			'licenses.relatedPackages' => 'Paket terkait',
			'licenses.license' => 'Lisensi',
			'licenses.licenseNumber' => ({required Object number}) => 'Lisensi ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} Lisensi',
			'navigation.libraries' => 'Pustaka',
			'navigation.downloads' => 'Unduhan',
			'navigation.liveTv' => 'TV Langsung',
			'navigation.explore' => 'eksplorasi',
			'explore.mdblistShelves.manage' => 'Mengelola eksplorasi shelves',
			'explore.mdblistShelves.manageDescription' => 'Pilih dan jadikan daftar dari akun MDBList Anda',
			'explore.mdblistShelves.description' => 'Pilih daftar film dan TV publik dari akun MDBList Anda. membuat atau menyalin daftar di MDBList, kemudian memperbarui.',
			'explore.mdblistShelves.selected' => 'Seleksi Seleksi',
			'explore.mdblistShelves.available' => 'Daftar akun yang tersedia',
			'explore.mdblistShelves.noLists' => 'Tidak ada film atau daftar televisi publik yang dikembalikan. membuat atau menyalin daftar di MDBList, kemudian memperbarui.',
			'explore.mdblistShelves.displayName' => 'Nama Shelf Display',
			'explore.mdblistShelves.nameHint' => 'Tinggalkan kosong untuk menggunakan nama daftar sumber.',
			'explore.mdblistShelves.add' => 'Tambahkan shelf',
			'explore.mdblistShelves.save' => 'Menyelamatkan shelter',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Move ${title} ke atas',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Move ${title} ke bawah',
			'explore.mdblistShelves.unavailable' => 'Daftar ini tidak tersedia.Tarik balik atau menghapus shell dalam pengaturan.',
			'explore.mdblistShelves.rateLimited' => 'MDBList batas permintaan telah dicapai. silakan mundur kemudian.',
			'explore.mdblistShelves.loadFailed' => 'Tidak bisa mengisi rak. periksa koneksi dan retry Anda.',
			'explore.mdblistShelves.saveFailed' => 'Saya tidak bisa menyimpan shelves. silakan retry.',
			'explore.mdblistShelves.accountChanged' => 'Akun atau profil berubah. buka seting ini lagi.',
			'explore.mdblistShelves.settingsUnreadable' => 'Tab yang disimpan tidak dapat dibaca. pilih daftar Anda lagi untuk menggantikan pengaturan ini.',
			'explore.title' => 'eksplorasi',
			'explore.selectSource' => 'Pilih sumber',
			'explore.rows.watchlist' => 'Pengawasan',
			'explore.rows.recommendedMovies' => 'Film yang disarankan',
			'explore.rows.recommendedShows' => 'Persembahan yang disarankan',
			'explore.rows.trendingMovies' => 'Film yang Trend',
			'explore.rows.trendingShows' => 'Tendangan menunjukkan',
			'explore.rows.popularMovies' => 'Film populer',
			'explore.rows.popularShows' => 'Pameran populer',
			'explore.rows.trendingAnime' => 'Tindakan Anime',
			'explore.rows.suggestedAnime' => 'Anime yang disarankan',
			'explore.rows.airingAnime' => 'Anime teratas yang sedang tayang',
			'explore.rows.popularAnime' => 'Anime yang paling populer',
			'explore.rows.trending' => 'Trend yang',
			'explore.rows.upcomingMovies' => 'Film yang akan datang',
			'explore.rows.upcomingShows' => 'Pertunjukan yang akan datang',
			'explore.status.airing' => 'udara',
			'explore.status.ended' => 'Berakhir',
			'explore.status.canceled' => 'dibatalkan',
			'explore.status.upcoming' => 'Akan datang',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episode', ), 
			'explore.cast' => 'Tembak',
			'explore.characters' => 'Karakter yang',
			'explore.addToWatchlist' => 'Tambahkan ke Watchlist',
			'explore.removeFromWatchlist' => 'Menghapus dari Watchlist',
			'explore.addedToWatchlist' => 'Ditambahkan ke watchlist',
			'explore.removedFromWatchlist' => 'Menghapus dari watchlist',
			'explore.watchlistUpdateFailed' => 'Tidak bisa update watchlist',
			'explore.watchlistNoMatch' => 'Tidak bisa menyesuaikan item ini dengan daftar pengawas',
			'explore.notInLibrary' => 'Tidak di perpustakaan Anda',
			'explore.inTheseLibraries' => 'Di perpustakaan ini',
			'explore.checkingLibrary' => 'Memeriksa perpustakaan Anda.',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: 'Tidak dapat memeriksa server ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', ), 
			'explore.emptyTitle' => 'Belum ada yang di sini',
			'explore.emptyMessage' => ({required Object source}) => 'Roda dari ${source} akan muncul di sini setelah mereka memiliki konten.',
			'explore.searchHint' => ({required Object source}) => 'Pencarian ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Tidak ada hasil untuk "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Cari film dan acara di ${source}.',
			'explore.searchFailed' => 'Pencarian gagal. periksa koneksi Anda dan coba lagi.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} populer',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} airing',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} dicatat',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} trending',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} di ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} menonton',
			'explore.badge.available' => 'Tersedia',
			'explore.badge.partiallyAvailable' => 'Sebagian tersedia',
			'explore.badge.availableIn4k' => '4K tersedia',
			'explore.badge.requested' => 'yang diminta',
			'explore.badge.pendingApproval' => 'Menunggu kelulusan',
			'explore.badge.processing' => 'Pemrosesan',
			'explore.badge.declined' => 'dikecualikan',
			'explore.badge.requestFailed' => 'Permintaan gagal',
			'explore.badge.requested4k' => '4K yang diminta',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} musim',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} dalam ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Selanjutnya di ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ep.',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} mnt/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} disenaraikan',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} menonton hari ini',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} menonton minggu ini',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} dilihat bulan ini',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} dilihat tahun ini',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} penonton',
			'explore.stats.planning' => ({required Object n}) => '${n} perencanaan untuk menonton',
			'explore.stats.favorited' => ({required Object n}) => '${n} favorit',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} mengunduhnya',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentar', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} mengundi',
			'explore.stats.watching' => ({required Object n}) => '${n} menonton',
			'explore.stats.completed' => ({required Object n}) => '${n} selesai',
			'explore.stats.onHold' => ({required Object n}) => '${n} pada hold',
			'explore.stats.dropped' => ({required Object n}) => '${n} ditinggalkan',
			'explore.season.winter' => 'Musim dingin',
			'explore.season.spring' => 'Musim semi',
			'explore.season.summer' => 'musim panas',
			'explore.season.fall' => 'jatuh',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'televisi',
			'explore.format.tvShort' => 'TV pendek',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Khususnya',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Musik',
			'explore.format.other' => 'Lainnya',
			'explore.sourceMaterial.original' => 'asli',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'novel cahaya',
			'explore.sourceMaterial.novel' => 'Novel',
			'explore.sourceMaterial.visualNovel' => 'novel visual',
			'explore.sourceMaterial.game' => 'Permainan',
			'explore.sourceMaterial.webComic' => 'Web Komik',
			'explore.sourceMaterial.musicRelease' => 'Musik',
			'explore.sourceMaterial.otherMedia' => 'Lainnya',
			'explore.creditRole.actor' => 'Aktor',
			'explore.creditRole.director' => 'Direktur',
			'explore.creditRole.writer' => 'Penulis',
			'explore.creditRole.producer' => 'Produsen',
			'explore.creditRole.creator' => 'pencipta',
			'explore.creditRole.composer' => 'Komposer',
			'explore.relation.prequel' => 'Praktek',
			'explore.relation.sequel' => 'Selanjutnya',
			'explore.relation.sideStory' => 'Halaman cerita',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Versi Alternatif',
			'explore.relation.summary' => 'Kesimpulan',
			'explore.relation.parentStory' => 'Kisah Orangtua',
			'explore.relation.adaptation' => 'Adaptasi',
			'explore.relation.other' => 'terkait',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} di ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} di ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Judul asli',
			'explore.detail.alsoKnownAs' => 'Juga dikenal sebagai',
			'explore.detail.studios' => 'Studio',
			'explore.detail.country' => 'Negara',
			'explore.detail.language' => 'Bahasa',
			'explore.detail.released' => 'dibebaskan',
			'explore.detail.physicalRelease' => 'pada disk',
			'explore.detail.ended' => 'Berakhir',
			'explore.detail.addedOn' => ({required Object date}) => 'Ditambahkan ${date}',
			'explore.detail.yourRating' => 'rating Anda',
			'explore.detail.budget' => 'anggaran',
			'explore.detail.revenue' => 'Kantor Kotak',
			'explore.detail.contentAdvisory' => 'Usia panduan',
			'explore.detail.tags' => 'Label',
			'explore.detail.revealSpoilerTags' => 'Menampilkan spoiler tag',
			'explore.detail.links' => 'Kiri',
			'explore.detail.watchOn' => 'Lihatlah',
			'explore.detail.watchTrailer' => 'Lihat Trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Terbuka pada ${site}',
			'explore.detail.crew' => 'Kapal',
			'explore.detail.ratings' => 'Peringkat',
			'explore.detail.schedule' => 'Jadwal',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: 'Direkomendasikan oleh ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengguna', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Diterima oleh ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'disukai oleh ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} belum diunggah',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Dipertimbangkan oleh ${percent} penonton',
			'explore.detail.relatedTitles' => 'Judul terkait',
			'explore.detail.background' => 'latar belakang',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hasilnya', ), 
			'liveTv.title' => 'TV Langsung',
			'liveTv.guide' => 'Panduan',
			'liveTv.noChannels' => 'Tidak ada saluran yang tersedia',
			'liveTv.noDvr' => 'Tidak ada DVR yang terkonfigurasi pada server',
			'liveTv.serverUnavailable' => 'Live TV server tidak tersedia.',
			'liveTv.serverNotConnected' => 'Live TV server tidak terhubung.',
			'liveTv.noPrograms' => 'Tidak ada data program yang tersedia',
			'liveTv.liveStreamFailed' => 'Live Stream gagal',
			'liveTv.unknownProgram' => 'Program yang tidak diketahui',
			'liveTv.timelineLiveProgram' => 'Live program (playback mungkin berada di luar program ini)',
			'liveTv.timelineBuffer' => 'Timer Buffer',
			'liveTv.timelineUnavailable' => 'Timeline tidak tersedia',
			'liveTv.timelineEstimated' => 'Berharga tentang playback',
			'liveTv.timelinePending' => 'Menunggu mencari',
			'liveTv.timelineStale' => 'Jadual dapat tertunda',
			'liveTv.unknownHub' => 'Tidak Dikenal',
			'liveTv.unknownError' => 'Kesalahan yang tidak diketahui',
			'liveTv.channelNumber' => ({required Object number}) => 'Saluran ${number}',
			'liveTv.unknownChannel' => 'saluran yang tidak diketahui',
			'liveTv.live' => 'Langsung',
			'liveTv.premiereBadge' => 'Baru',
			'liveTv.reloadGuide' => 'Reload Panduan',
			'liveTv.searchGuide' => 'Panduan Pencarian',
			'liveTv.searchHint' => 'Mencari saluran dan program',
			'liveTv.searchNoResults' => ({required Object query}) => 'Tidak ada pertandingan untuk "${query}"',
			'liveTv.channelsSection' => 'Saluran',
			'liveTv.programsSection' => 'Program',
			'liveTv.now' => 'Sekarang',
			'liveTv.today' => 'Hari ini',
			'liveTv.tomorrow' => 'besok',
			'liveTv.midnight' => 'tengah malam',
			'liveTv.overnight' => 'Malam hari',
			'liveTv.morning' => 'pagi hari',
			'liveTv.daytime' => 'Waktu hari',
			'liveTv.evening' => 'Malam hari',
			'liveTv.lateNight' => 'Malam yang lambat',
			'liveTv.whatsOn' => 'Apa yang ada di',
			'liveTv.watchChannel' => 'Menonton Channel',
			'liveTv.favorites' => 'Favorit',
			'liveTv.reorderFavorites' => 'Kegemaran Reorder',
			'liveTv.noFavoriteChannels' => 'Tidak ada saluran favorit',
			'liveTv.noFavoriteChannelsHint' => 'Tunjukkan semua saluran, kemudian tekan panjang saluran untuk menambahkan ke favorit Anda.',
			'liveTv.showAllChannels' => 'Menampilkan semua saluran',
			'liveTv.favoritesLoadFailed' => 'Anda tidak bisa mengisi favorit. periksa koneksi Anda dan coba lagi.',
			'liveTv.favoritesUpdateFailed' => 'Anda tidak bisa memperbarui favorit Anda. periksa koneksi Anda dan coba lagi.',
			'liveTv.joinSession' => 'Berpartisipasi dalam Sesi',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Menonton dari awal (${minutes} menit yang lalu)',
			'liveTv.watchLive' => 'Lihat Live',
			'liveTv.goToLive' => 'Pergi untuk Hidup',
			'liveTv.record' => 'Merekam',
			'liveTv.recordEpisode' => 'Rekor episode',
			'liveTv.recordSeries' => 'Seri rekaman',
			'liveTv.recordOptions' => 'Rekor Opsi',
			'liveTv.saveTo' => 'Selamatkan untuk',
			'liveTv.recordings' => 'Rekaman',
			'liveTv.scheduledRecordings' => 'jadwal',
			'liveTv.recordingRules' => 'Peraturan Rekaman',
			'liveTv.noScheduledRecordings' => 'Tidak ada yang direncanakan untuk merekam',
			'liveTv.manageRecording' => 'Atur Rekaman',
			'liveTv.cancelRecording' => 'Batalkan perekaman',
			'liveTv.cancelRecordingTitle' => 'Membatalkan rekaman ini?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} tidak akan lagi tercatat.',
			'liveTv.deleteRule' => 'Menghapus aturan',
			'liveTv.deleteRuleTitle' => 'Menghapus aturan rekaman?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Episode mendatang dari ${title} tidak akan direkam.',
			'liveTv.recordingScheduled' => 'Perekaman dijadwalkan.',
			'liveTv.alreadyScheduled' => 'Program ini sudah direncanakan',
			'liveTv.dvrAdminRequired' => 'Pengaturan DVR membutuhkan akun admin',
			'liveTv.recordingFailed' => 'Tidak bisa merancang rekaman',
			'liveTv.recordingTargetMissing' => 'Tidak bisa menentukan rekaman perpustakaan',
			'liveTv.recordNotAvailable' => 'Tidak tersedia untuk program ini',
			'liveTv.recordingCancelled' => 'Rekaman dibatalkan',
			'liveTv.recordingRuleDeleted' => 'Peraturan rekaman dihapus',
			'liveTv.processRecordingRules' => 'Menilai kembali aturan',
			'liveTv.recordingInProgress' => 'Rekaman sekarang',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} diatur',
			'liveTv.editRule' => 'Edit Peraturan',
			'liveTv.editRuleAction' => 'Sunting',
			'liveTv.recordingRuleUpdated' => 'Peraturan rekaman diperbarui',
			'liveTv.guideReloadRequested' => 'Panduan pembaharuan diminta',
			'liveTv.guideReloadFailed' => 'Tidak bisa memperbaharui panduan',
			'liveTv.rulesProcessRequested' => 'Peraturan penilaian ulang yang diminta',
			'liveTv.rulesProcessFailed' => 'Tidak bisa menilai kembali aturan rekaman',
			'liveTv.recordShow' => 'Rekor Show',
			'liveTv.recordSettings.startEarly' => 'Mulai lebih awal (second)',
			'liveTv.recordSettings.endLate' => 'Berakhir terlambat (second)',
			'liveTv.recordSettings.newOnly' => 'Hanya episode baru',
			'liveTv.recordSettings.anyChannel' => 'Rekaman di setiap saluran',
			'liveTv.recordSettings.anyTime' => 'Rekor pada setiap waktu',
			'liveTv.recordSettings.skipInLibrary' => 'Luncurkan episode sudah di perpustakaan',
			'liveTv.recordSettings.keepUpTo' => 'Episod yang harus dipantau',
			'liveTv.recordSettings.keepUpToHint' => '0 memegang setiap episode',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Mulai dalam ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} pada ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} mengembalikan data live TV playback yang tidak sah',
			'liveTv.failedToStartChannel' => 'Tidak bisa memulai live channel.',
			'liveTv.failedToBuildStreamUrl' => 'Tidak bisa membuat URL streaming',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Tidak bisa memulai saluran: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Tidak bisa menukar saluran: ${reason}',
			'collections.title' => 'Koleksi',
			'collections.collection' => 'Koleksi',
			'collections.empty' => 'Koleksi itu kosong',
			'collections.deleteCollection' => 'Menghapus Koleksi',
			'collections.deleteConfirm' => ({required Object title}) => 'Hapus "${title}"? Tindakan ini tidak dapat dibatalkan.',
			'collections.deleted' => 'Koleksi dihapus',
			'collections.deleteFailed' => 'gagal menghapus koleksi',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Tidak berhasil menghapus koleksi: ${error}',
			'collections.selectCollection' => 'Seleksi Seleksi',
			'collections.collectionName' => 'Nama Koleksi',
			'collections.enterCollectionName' => 'Masukkan nama koleksi',
			'collections.addedToCollection' => 'Ditambahkan ke Koleksi',
			'collections.errorAddingToCollection' => 'gagal menambahkan ke koleksi',
			'collections.created' => 'Koleksi yang diciptakan',
			'collections.removeFromCollection' => 'Hapus dari koleksi',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Hapus “${title}” dari koleksi ini?',
			'collections.removedFromCollection' => 'Menghapus dari Koleksi',
			'collections.removeFromCollectionFailed' => 'Tidak berhasil keluar dari koleksi',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Kesalahan penghapusan dari koleksi: ${error}',
			'collections.searchCollections' => 'Koleksi pencarian...',
			'playlists.title' => 'Daftar putar',
			'playlists.playlist' => 'Daftar Putar',
			'playlists.noPlaylists' => 'Tidak ditemukan playlist',
			'playlists.create' => 'Membuat Playlist',
			'playlists.playlistName' => 'Nama Playlist',
			'playlists.enterPlaylistName' => 'Masukkan nama playlist',
			'playlists.delete' => 'Menghapus Playlist',
			'playlists.removeItem' => 'Hapus dari daftar putar',
			'playlists.smartPlaylist' => 'Daftar Pemain Pintar',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item', ), 
			'playlists.emptyPlaylist' => 'Playlist ini kosong',
			'playlists.deleteConfirm' => 'Menghapus Playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Apakah Anda yakin Anda ingin menghapus "${name}"?',
			'playlists.created' => 'Playlist yang diciptakan',
			'playlists.deleted' => 'Playlist dihapus',
			'playlists.itemAdded' => 'Ditambahkan ke playlist',
			'playlists.itemRemoved' => 'Menghapus dari playlist',
			'playlists.selectPlaylist' => 'Pilih Playlist',
			'playlists.searchPlaylists' => 'Mencari playlist...',
			'playlists.errorCreating' => 'gagal membuat playlist',
			'playlists.errorDeleting' => 'Tidak berhasil menghapus playlist',
			'playlists.errorLoading' => 'gagal mengisi playlists',
			'playlists.errorAdding' => 'gagal menambahkan ke playlist',
			'playlists.errorReordering' => 'gagal mengatur ulang item playlist',
			'playlists.errorRemoving' => 'Tidak berhasil keluar dari playlist',
			'music.goToAlbum' => 'Pergi ke album',
			'music.goToArtist' => 'Pergi ke artis',
			'music.instantMix' => 'Mix Instan',
			'music.playNext' => 'Mainkan selanjutnya',
			'music.addToQueue' => 'Tambahkan ke kue',
			'music.discNumber' => ({required Object n}) => 'Disk ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} jalur', ), 
			'music.nowPlaying' => 'Sekarang Bermain',
			'music.playingFrom' => ({required Object title}) => 'Bermain dari ${title}',
			'music.queue' => 'Keuangan',
			'music.clearQueue' => 'Hapus antrian',
			'music.lyrics' => 'Lirik',
			'music.visualizer' => 'Visualisasi',
			'music.visualizerProfileLoading' => 'Membaca Track Analysis',
			'music.visualizerAmbientMotion' => 'Pergerakan Lingkungan',
			'music.visualizerPlexLoudness' => 'Plex suara',
			'music.visualizerPreviousPreset' => 'Gaya visual sebelumnya',
			'music.visualizerNextPreset' => 'Seterusnya Visual Style',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Bloom yang',
			'music.visualizerPresetOrbitals' => 'Orbitasi',
			'music.visualizerPresetPrism' => 'Prisme',
			'music.visualizerPresetTunnel' => 'terowongan',
			'music.visualizerPresetTrackMap' => 'Peta Track',
			'music.noLyrics' => 'Tidak ada lyrics tersedia',
			'music.sleepTimer' => 'Waktu Tidur',
			'music.sleepTimerEndOfTrack' => 'Akhir dari trek',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menit', ), 
			'music.stopPlayback' => 'Hentikan pemutaran',
			'music.previousTrack' => 'Lagu sebelumnya',
			'music.nextTrack' => 'Lagu berikutnya',
			'music.repeat' => 'Ulangi',
			'music.repeatAll' => 'Ulang semua',
			'music.repeatOne' => 'Ulangi Sekali',
			'music.instantMixNoServer' => 'Tidak ada server yang tersedia untuk campuran instan',
			'music.instantMixFailed' => 'Tidak berhasil mengisi mix instant',
			'music.instantMixEmpty' => 'Tombol ini kembali tanpa jejak.',
			'music.noAudioUrl' => ({required Object track}) => 'Tidak ada URL audio yang tersedia untuk ${track}',
			'music.discography.singlesAndEps' => 'Singles dan EPs',
			'music.discography.live' => 'Langsung',
			'music.discography.compilations' => 'Kompilasi',
			'watchTogether.title' => 'Tonton Bersama',
			'watchTogether.description' => 'Menonton konten dalam sinergitas dengan teman dan keluarga',
			'watchTogether.createRoom' => 'Membuat ruangan',
			'watchTogether.creatingRoom' => 'Membangun ruangan...',
			'watchTogether.joinRoom' => 'Bergabunglah dengan ruangan',
			'watchTogether.joiningRoom' => 'Untuk menyertai ruangan...',
			'watchTogether.connecting' => 'Menghubungkan...',
			'watchTogether.relayPublic' => 'Ruang-ruang yang digunakan oleh publik Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Kamar menggunakan relay Anda di ${url}.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.recentRooms' => 'Ruang Baru',
			'watchTogether.roomActions' => 'Ruang Aksi',
			'watchTogether.renameRoom' => 'Ruang Rename',
			'watchTogether.removeRoom' => 'Hapus',
			'watchTogether.enterRoomCode' => 'Masukkan kode 6 karakter dari host.',
			'watchTogether.roomCode' => 'Kode kamar',
			'watchTogether.paste' => 'Tempel',
			'watchTogether.noCodeInClipboard' => 'Clipboard tidak mengandung kode kamar',
			'watchTogether.copyCode' => 'Kopi kode',
			'watchTogether.codeCopied' => 'Kode kamar disalin',
			'watchTogether.shareInvite' => 'Membagi Jemputan',
			'watchTogether.inviteCopied' => 'Tuliskan pesan, masukkan ke dalam pesan.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Bergabunglah dengan Watch bersama saya di PlezyNG: buka Watch bersama, pilih Join Room dan masukkan ${code}.',
			'watchTogether.openSessionControls' => 'Open Watch Bersama-sama kontrol sesi',
			'watchTogether.reconnecting' => 'Menghubungkan kembali...',
			'watchTogether.reconnectingDescription' => 'Koneksi terputus.Anda masuk ke ruangan secara otomatis.',
			'watchTogether.connected' => 'terhubung',
			'watchTogether.disconnected' => 'terhubung',
			'watchTogether.youAreHost' => 'Anda adalah tuan rumah',
			'watchTogether.hostedBy' => ({required Object name}) => 'Diposting oleh ${name}',
			'watchTogether.hostControlsPlayback' => 'Pengelolaan Playback',
			'watchTogether.anyoneCanControl' => 'Siapa pun bisa mengontrol playback.',
			'watchTogether.roomLocked' => 'Kamar Tertutup',
			'watchTogether.nowPlaying' => 'Sekarang Bermain',
			'watchTogether.nothingPlaying' => 'Tidak ada bermain',
			'watchTogether.nothingPlayingHost' => 'Mainkan sesuatu dari perpustakaan apa pun untuk membagikannya dengan ruangan.',
			'watchTogether.nothingPlayingGuest' => 'Ketika tuan rumah memainkan sesuatu, itu dibuka di sini.',
			'watchTogether.notShareable' => 'Video ini tidak memiliki catatan, sehingga hanya orang dengan akses ke server yang sama dapat memainkannya.',
			'watchTogether.searching' => 'Mencari video ini di perpustakaan Anda...',
			'watchTogether.yourCopy' => 'Kopi Anda',
			'watchTogether.sharingYourCopy' => 'Anda berbagi salinan Anda',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Bermain salinan Anda, ${difference}',
			'watchTogether.mismatchTitle' => 'Kopi Anda adalah panjang yang berbeda',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Kopi terdekat Anda adalah ${difference} dari video ruangan. itu bisa menjadi potongan atau versi lain.',
			'watchTogether.playAnyway' => 'bermain apa pun',
			'watchTogether.chooseAnotherCopy' => 'Pilih salinan lain',
			'watchTogether.dontPlay' => 'Jangan Bermain',
			'watchTogether.unavailableTitle' => 'Anda tidak memiliki video ini',
			'watchTogether.unavailableDescription' => 'PlezyNG tidak dapat menemukannya di perpustakaan Anda. pilih salinan sendiri atau cari lagi.',
			'watchTogether.chooseCopy' => 'Pilih salinan',
			'watchTogether.searchAgain' => 'Cari lagi',
			'watchTogether.noCandidates' => 'Tidak ada salinan yang ditemukan di perpustakaan Anda.',
			'watchTogether.choiceFailed' => 'Saya tidak bisa memainkan salinan ini untuk ruangan',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} lebih lama',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} lebih pendek',
			'watchTogether.lengthSame' => 'panjang yang sama',
			'watchTogether.lengthUnknown' => 'panjang yang tidak diketahui',
			'watchTogether.joinCurrentPlayback' => 'Bergabunglah dengan Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'Kembali ke apa yang sedang ditonton oleh tuan rumah',
			'watchTogether.stopMedia' => 'Stop Video untuk Semua Orang',
			'watchTogether.syncOffset' => 'Sinkronisasi Offset',
			'watchTogether.syncOffsetDescription' => 'Pindah video Anda jika ia berjalan di depan atau di belakang ruangan.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Kopi Anda adalah ${difference} dari video kamar.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Menggunakan ${offset}',
			'watchTogether.offsetMinusSecond' => '1 s',
			'watchTogether.offsetMinusTenth' => '- 100 ms',
			'watchTogether.offsetPlusTenth' => '+ 100 ms',
			'watchTogether.offsetPlusSecond' => '+ 1 s',
			'watchTogether.participants' => 'peserta',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} peserta', ), 
			'watchTogether.hostBadge' => 'tamu',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (Anda)',
			'watchTogether.playerIdle' => 'Diam',
			'watchTogether.playerLoading' => 'Pengisian',
			'watchTogether.playerReady' => 'Bersedia',
			'watchTogether.playerBuffering' => 'Buffer',
			'watchTogether.matchSearching' => 'pencarian',
			'watchTogether.matchMatched' => 'memiliki video',
			'watchTogether.matchMismatched' => 'panjang yang berbeda',
			'watchTogether.matchUnavailable' => 'Tidak ada video',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Pengaturan ${offset}',
			'watchTogether.makeHost' => 'Membuat host',
			'watchTogether.makeHostQuestion' => 'Pengiriman ke host?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} akan mengendalikan playback dan menjalankan sesi untuk semua orang.',
			'watchTogether.transfer' => 'Pindahkan',
			'watchTogether.removeParticipant' => 'Keluar dari ruangan',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Menghapus ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} meninggalkan ruangan. mereka dapat bergabung lagi dengan kode kecuali Anda menutup ruangan.',
			'watchTogether.remove' => 'Hapus',
			'watchTogether.roomSettings' => 'Settings ruangan',
			'watchTogether.letEveryoneControl' => 'Semua orang bisa bermain playback',
			'watchTogether.lockRoom' => 'ruang tertutup',
			'watchTogether.lockRoomDescription' => 'Tidak ada yang baru yang bisa bergabung',
			'watchTogether.leaveRoom' => 'Tinggalkan Kamar',
			'watchTogether.leaveRoomQuestion' => 'Tinggalkan kamar?',
			'watchTogether.leaveRoomConfirm' => 'Anda dapat bergabung lagi dengan kode kamar.',
			'watchTogether.leave' => 'Tinggal',
			'watchTogether.endRoom' => 'Bilik Akhir',
			'watchTogether.endRoomQuestion' => 'Bilik akhir ?',
			'watchTogether.endRoomConfirm' => 'Ini mengakhiri ruang untuk semua orang.',
			'watchTogether.end' => 'Akhirnya',
			'watchTogether.playBlockedTitle' => 'Playback tidak dimulai',
			'watchTogether.playBlockedDescription' => 'Mainkan permainan untuk mulai menonton dengan ruangan.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} permainan yang ditekan',
			'watchTogether.notices.playbackStarted' => 'Playback dimulai',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} ditangguhkan',
			'watchTogether.notices.playbackPaused' => 'Playback beristirahat',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} melompat ke ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Diperoleh pada ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} menetapkan kecepatan ke ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Kecepatan yang ditetapkan pada ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} dimulai ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Sekarang bermain ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} berhenti video',
			'watchTogether.notices.mediaStopped' => 'Video itu berhenti',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Menunggu untuk ${name} ...',
			'watchTogether.notices.waitingForSomeone' => 'Menunggu seseorang untuk menangkap ...',
			'watchTogether.notices.finished' => 'selesai',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} sekarang menjadi tuan rumah',
			'watchTogether.notices.youAreNowHost' => 'Sekarang kau adalah tuan rumah',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} menyertai',
			'watchTogether.notices.left' => ({required Object name}) => '${name} keluar',
			'watchTogether.notices.controlRefused' => 'Hanya tuan rumah yang dapat mengontrol playback.',
			'watchTogether.notices.searchFailed' => 'Beberapa server tidak dapat dicari untuk video ruangan',
			'watchTogether.notices.playBlocked' => 'Bermain Press untuk Mulai',
			'watchTogether.notices.shareFailed' => 'Saya tidak bisa berbagi video ini dengan ruangan',
			'watchTogether.notices.downloadNotShared' => 'Download tidak dibagi dengan ruangan saat server mereka offline',
			'watchTogether.notices.openFailed' => 'Tidak bisa membuka video kamar',
			'watchTogether.ended.ended' => 'Pengantin mengakhiri kamar',
			'watchTogether.ended.kicked' => 'Anda diusir dari ruangan',
			'watchTogether.ended.expired' => 'Ruang itu habis',
			'watchTogether.ended.replaced' => 'Anda bergabung dengan ruangan ini pada perangkat lain',
			'watchTogether.ended.lost' => 'Kehilangan koneksi ke ruangan',
			'watchTogether.errors.invalidCode' => 'Kod memiliki 6 huruf dan angka, tanpa 0, 1, I, L atau O.',
			'watchTogether.errors.roomNotFound' => 'Tidak ada ruang yang memiliki kode itu. mungkin telah berakhir.',
			'watchTogether.errors.roomFull' => 'Ruang itu penuh.',
			'watchTogether.errors.roomLocked' => 'Pemilik rumah itu menutup kamar itu.',
			'watchTogether.errors.relayFull' => 'Lihat Bersama sibuk sekarang. coba lagi nanti.',
			'watchTogether.errors.unreachable' => 'Tidak bisa mencapai jam bersama relay. periksa koneksi Anda.',
			'watchTogether.errors.rateLimited' => 'Terlalu banyak usaha. tunggu sebentar dan coba lagi.',
			'watchTogether.errors.clientBlocked' => 'Versi PlezyNG ini tidak dapat menggunakan relay. update aplikasi.',
			'watchTogether.errors.forbidden' => 'Hanya tuan rumah yang bisa melakukannya.',
			'watchTogether.errors.notInRoom' => 'Anda tidak berada di ruangan.',
			'watchTogether.errors.alreadyInRoom' => 'Anda sudah berada di kamar.',
			'watchTogether.errors.resumeFailed' => 'Aku tidak bisa masuk ke kamar.',
			'watchTogether.errors.unsupported' => 'Relay tidak mendukung hal ini.',
			'watchTogether.errors.generic' => 'Ada yang salah, coba lagi.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Keterangan ${number}',
			'downloads.title' => 'Unduhan',
			'downloads.manage' => 'Manajemen',
			'downloads.tvShows' => 'Acara TV',
			'downloads.movies' => 'Film',
			'downloads.music' => 'Musik',
			'downloads.tracksQueued' => ({required Object count}) => '${count} track yang diunduh untuk download',
			'downloads.noDownloads' => 'Belum ada download',
			'downloads.noDownloadsDescription' => 'Konten yang dimuat turun akan muncul di sini untuk menonton offline',
			'downloads.downloadNow' => 'Unduh',
			'downloads.deleteDownload' => 'Menghapus download',
			'downloads.retryDownload' => 'Kembali ke download',
			'downloads.downloadQueued' => 'Download Dijadwalkan.',
			'downloads.downloadResumed' => 'Download kembali',
			'downloads.serverErrorBitrate' => 'Kesalahan server: file mungkin melebihi batas bitrate remote',
			'downloads.storageFull' => 'Download berhenti untuk melindungi penyimpanan yang tersedia.Bebaskan beberapa ruang atau pilih lokasi download lain, kemudian retry.',
			'downloads.storageUnavailable' => 'Download berhenti karena penyimpanan yang tersedia tidak dapat diperiksa. periksa lokasi download, kemudian retry.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episode yang dikeluarkan untuk download',
			'downloads.downloadDeleted' => 'Download dihapus',
			'downloads.deleteConfirm' => ({required Object title}) => 'Menghapus "${title}" dari perangkat ini?',
			'downloads.deleteCollectionDownloads' => 'Menghapus Downloads',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Hapus semua unduhan dalam “${title}” dari perangkat ini?',
			'downloads.collectionDownloadsDeleted' => 'Download yang dihapus',
			'downloads.cancelledDownloadTitle' => 'Pembatalan Download',
			'downloads.cancelledDownloadMessage' => 'Download ini dibatalkan. apa yang ingin Anda lakukan?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Semua episode sudah dimuat turun',
			'downloads.resumeDownload' => 'Lanjutkan unduhan',
			'downloads.cancelledDownload' => 'Pembatalan download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (sinkronisasi ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Dimuat turun ${file} - Klik untuk menyelesaikan',
			'downloads.partialDownloadClickToComplete' => 'Dilancarkan secara parsial - Klik untuk menyelesaikan',
			'downloads.deleting' => 'Menghapus...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Menghapus ${title}... (${current} dari ${total})',
			'downloads.queuedTooltip' => 'Keuangan',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Kemenangan ${files}',
			'downloads.downloadingTooltip' => 'Mengunduh...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Mengunduh ${files}',
			'downloads.noDownloadsTree' => 'Tidak ada download',
			'downloads.pauseAll' => 'Beristirahat Semua',
			'downloads.resumeAll' => 'Resume Semua',
			'downloads.retryAll' => 'Kembalikan Semua',
			'downloads.retryFailed' => 'Retry gagal download',
			'downloads.deleteAll' => 'Hapus Semua',
			'downloads.selectVersion' => 'Pilih versi',
			'downloads.allEpisodes' => 'Semua episode',
			'downloads.unwatchedOnly' => 'Hanya tidak diperhatikan',
			'downloads.nextNUnwatched' => ({required Object count}) => '${count} tidak diperhatikan',
			'downloads.customAmount' => 'Jumlah Custom...',
			'downloads.customAmountAny' => 'Jumlah yang disesuaikan (setiap kali)',
			'downloads.randomEpisodes' => 'episode rahasia',
			'downloads.includeSpecials' => 'Termasuk spesial',
			'downloads.howManyEpisodes' => 'Berapa banyak episode?',
			'downloads.invalidEpisodeCount' => 'Masukkan jumlah episode yang valid.',
			'downloads.keepSynced' => 'Tetap Sinkronisasi',
			'downloads.downloadOnce' => 'Download 1 kali',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Tinggalkan ${count} tidak dipantau',
			'downloads.editSyncRule' => 'Mengedit Sink',
			'downloads.removeSyncRule' => 'Menghapus aturan sinergi',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Hentikan sinkronisasi "${title}"? Episode yang telah diunduh akan tetap disimpan.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Berhenti menyinkronkan "${title}"',
			'downloads.deleteSyncRuleDownloads' => 'Juga menghapus download yang terkait',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Download yang digunakan oleh aturan sink atau profil lain akan disimpan.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Sinkronisasi yang dibuat — menyimpan ${count} episode yang tidak dipantau',
			'downloads.syncRuleUpdated' => 'Peraturan Sync diperbarui',
			'downloads.syncRuleRemoved' => 'Peraturan Sync dihapus',
			'downloads.syncRuleAndDownloadsRemoved' => 'Peraturan Sync dan download terkait dihapus',
			'downloads.syncRuleCleanupBusy' => 'Peraturan Sync saat ini sedang diperbarui. coba lagi dalam beberapa saat.',
			'downloads.syncRuleCleanupUnavailable' => 'Menghubungkan kembali server dan mencoba lagi, atau menghapus aturan tanpa menghapus download.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Synced ${count} episode baru untuk ${title}',
			'downloads.syncNow' => 'Sync sekarang',
			'downloads.downloadsUpToDate' => 'Downloads sampai saat ini',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync lengkap · ${queued} queued, ${removed} dihapus',
			'downloads.activeSyncRules' => 'Peraturan Sync',
			'downloads.reviewOrphanFiles' => 'Download dari Orphaned',
			'downloads.orphanReviewTitle' => 'Download dari Orphaned',
			'downloads.orphanReviewDescription' => 'File yang ditandai ini berada dalam folder download yang dikendalikan oleh aplikasi default PlezyNG dan tidak memiliki rekaman download atau tugas aktif yang sepadan.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} file · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Menghapus file ${count}',
			'downloads.orphanCleanupNone' => 'Tidak ada file download yang ditemukan',
			'downloads.orphanCleanupFailed' => 'PlezyNG tidak dapat dengan aman memindai folder download yang dikelola.',
			'downloads.orphanCleanupChanged' => 'Daftar muat turun berubah selama review. ulangi file lagi sebelum membersihkan.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Menghapus ${count} file orphaned · ${size} dikeluarkan',
			'downloads.noSyncRules' => 'Tidak ada aturan sync',
			'downloads.manageSyncRule' => 'Manajemen Sync',
			'downloads.editEpisodeCount' => 'Episode Menghitung',
			'downloads.editSyncFilter' => 'Filter Sinkronisasi',
			'downloads.syncAllItems' => 'Sinkronisasi semua item',
			'downloads.syncUnwatchedItems' => 'Sinkronisasi item yang tidak diperhatikan',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Tersedia',
			'downloads.syncRuleOffline' => 'Luring',
			'downloads.syncRuleSignInRequired' => 'Menandatangani yang diperlukan',
			'downloads.syncRuleAccessDenied' => 'Akses yang ditolak',
			'downloads.syncRuleNotAvailableForProfile' => 'Tidak tersedia untuk profil saat ini',
			'downloads.syncRuleUnknownServer' => 'Server yang tidak diketahui',
			'downloads.syncRuleListCreated' => 'Sinkronisasi yang dibuat',
			'downloads.backgroundWarning.bannerBlocked' => 'Download akan berhenti saat Anda meninggalkan aplikasi',
			'downloads.backgroundWarning.bannerDegraded' => 'Download latar belakang dapat terbatas',
			'downloads.backgroundWarning.bannerAction' => 'Detail',
			'downloads.backgroundWarning.sheetTitle' => 'Download latar belakang diblokir',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Download latar belakang dapat terbatas',
			'downloads.backgroundWarning.sheetIntro' => 'Android mencegah PlezyNG dari mengunduh dengan aman di latar belakang.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Perangkat Anda membatasi kapan PlezyNG dapat dimuat turun di latar belakang.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Penggunaan latar belakang PlezyNG terbatas. menetapkan penggunaan bateri atau latar belakangnya pada "Tidak terbatas".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android telah menempatkan PlezyNG dalam keadaan standby terbatas.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Pemberitahuan muat turun terputus, sehingga kemajuan dan kontrol mungkin tidak tersedia.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Notifikasi dihapus. pada Android 13 atau lebih baru, mereka diperlukan untuk download latar belakang yang panjang.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver ada, yang memblokir download latar belakang pada data mobile. download harus tetap berjalan di Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Muat turun berulang kali berhenti sementara PlezyNG berada di latar belakang. periksa pengaturan penggunaan baterai atau latar belakang PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Tetapan Terbuka',
			'downloads.backgroundWarning.stillNotWorking' => 'Bantuan khusus perangkat',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Lihat langkah-langkah untuk perangkat Anda, atau kirim log dari Settings › Lihat log jika masalah berlanjut.',
			'downloads.backgroundWarning.dialogTitle' => 'Download mungkin tidak selesai',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Download dengan cara apapun',
			'downloads.backgroundWarning.dialogFixFirst' => 'Tetaplah ini dulu',
			'downloads.backgroundWarning.statusTile' => 'Latar Belakang Downloads',
			'downloads.backgroundWarning.statusOk' => 'Dirancang untuk berjalan di latar belakang',
			'downloads.backgroundWarning.statusBlocked' => 'Diblokir oleh sistem pengaturan',
			'downloads.backgroundWarning.statusDegraded' => 'Terbatas oleh sistem pengaturan',
			'downloads.backgroundWarning.statusUnknown' => 'Belum diperiksa',
			'downloads.backgroundWarning.settingsUnavailable' => 'Tidak bisa membuka pengaturan sistem pada perangkat ini',
			'downloads.backgroundWarning.linkUnavailable' => 'Tidak bisa membuka dontkillmyapp.com pada perangkat ini',
			'downloads.options' => 'Pilihan download',
			'downloads.groupings.library' => 'Pustaka',
			'downloads.groupings.collections' => 'Koleksi',
			'downloads.unknownLibrary' => 'Perpustakaan yang tidak diketahui',
			'downloads.unknownShow' => 'Pameran yang tidak diketahui',
			'downloads.unknownSeason' => 'Musim yang tidak diketahui',
			'downloads.unknownAlbum' => 'Album yang tidak diketahui',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} selesai',
			'downloads.storageUsed' => ({required Object size}) => 'Penyimpanan yang digunakan: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pengunduran', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} menunjukkan', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', ), 
			'downloads.errorFileNotFound' => 'File yang tidak ditemukan (404)',
			'downloads.errorDownloadNotAllowed' => 'Download tidak diizinkan oleh server (403)',
			'downloads.errorDownloadFailed' => 'Download gagal',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Download gagal: ${reason}',
			'downloads.convertingOnServer' => 'Konversi ke server',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Konversi pada server · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Download gagal (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Setelah pemrosesan gagal: ${reason}',
			'downloads.reasonFileNotSaved' => 'File tidak dapat disimpan pada perangkat ini.',
			'downloads.reasonCannotResume' => 'Download parsial tidak dapat diulang',
			'downloads.reasonDeviceStorageFull' => 'Perangkat ini tidak disimpan',
			'downloads.notificationDownloading' => 'Mengunduh...',
			'downloads.notificationComplete' => 'Download lengkap',
			'downloads.notificationPaused' => 'Download yang beristirahat',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Tidak ada peningkatan video',
			'shaders.nvscalerDescription' => 'Skala gambar NVIDIA untuk video yang lebih tajam',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Denosiasi',
			'shaders.artcnnVariantDenoiseSharpen' => 'Kekuatan + Sharpen',
			'shaders.qualityFast' => 'Cepat',
			'shaders.qualityHQ' => 'kualitas tinggi',
			'shaders.mode' => 'Mode',
			'shaders.importShader' => 'Pengiriman Shader',
			'shaders.customShaderDescription' => 'Ciri-ciri GSL Shader',
			'shaders.shaderImported' => 'Shader yang diimpor',
			'shaders.shaderImportFailed' => 'gagal mengimpor shader',
			'shaders.deleteShader' => 'Menghapus Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Menghapus “${name}”',
			'companionRemote.title' => 'Remote Pendamping',
			'companionRemote.connectedTo' => ({required Object name}) => 'Menghubungkan ke ${name}',
			'companionRemote.unknownDevice' => 'perangkat yang tidak diketahui',
			'companionRemote.session.startingServer' => 'Mulai dari remote server.',
			'companionRemote.session.hostAddress' => 'Alamat tamu',
			'companionRemote.session.connected' => 'terhubung',
			'companionRemote.session.serverRunning' => 'Remote server aktif',
			'companionRemote.session.serverStopped' => 'Remote server terhenti',
			'companionRemote.session.serverRunningDescription' => 'perangkat mobile di jaringan Anda dapat terhubung ke aplikasi ini',
			'companionRemote.session.serverStoppedDescription' => 'Memulai server untuk memungkinkan perangkat mobile untuk terhubung',
			'companionRemote.session.usePhoneToControl' => 'Gunakan perangkat seluler Anda untuk mengontrol aplikasi ini',
			'companionRemote.session.startServer' => 'Memulai Server',
			'companionRemote.session.stopServer' => 'Hentikan Server',
			'companionRemote.session.minimize' => 'Minimalisasikan',
			'companionRemote.session.manualAddressHint' => 'Alamat koneksi manual :',
			'companionRemote.pairing.discoveryDescription' => 'PlezyNG perangkat dengan akun yang sama Plex muncul di sini',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Menghubungkan...',
			'companionRemote.pairing.searchingForDevices' => 'Mencari perangkat...',
			'companionRemote.pairing.noDevicesFound' => 'Tidak ada perangkat yang ditemukan di jaringan Anda',
			'companionRemote.pairing.noDevicesHint' => 'Buka PlezyNG di desktop dan gunakan Wi-Fi yang sama',
			'companionRemote.pairing.availableDevices' => 'Perangkat yang tersedia',
			'companionRemote.pairing.manualConnection' => 'Manual koneksi',
			'companionRemote.pairing.cryptoInitFailed' => 'Tidak bisa memulai koneksi yang aman. mendaftar di Plex pertama.',
			'companionRemote.pairing.validationHostRequired' => 'Silakan masukkan alamat host',
			'companionRemote.pairing.validationHostFormat' => 'Format harus IP:port (misalnya 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Menggunakan jaringan yang sama pada kedua perangkat.',
			'companionRemote.pairing.sessionNotFound' => 'Perangkat tidak ditemukan. pastikan PlezyNG berjalan pada host.',
			'companionRemote.pairing.authFailed' => 'Kedua perangkat membutuhkan akun yang sama Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Tidak dapat dihubungkan: ${error}',
			'companionRemote.pairing.codeTitle' => 'Kode Pasangan',
			'companionRemote.pairing.codeDescription' => 'Masukkan kode yang ditunjukkan di Companion Remote pada perangkat host. Kedua perangkat harus menggunakan versi yang mendukung pasangan yang aman.',
			'companionRemote.pairing.codeInvalid' => 'Masukkan semua 32 huruf dan angka dari kode tuan rumah.',
			'companionRemote.pairing.updateRequired' => 'Update kedua perangkat ke versi yang mendukung pasangan yang aman.',
			'companionRemote.pairing.hostDescription' => 'Masukkan kode ini sekali pada setiap remote. tetaplah privasi: ini memberikan kontrol profil ini.',
			'companionRemote.pairing.resetCode' => 'Mengatur kode paring',
			'companionRemote.pairing.resetDescription' => 'Menghilangkan semua remote dan membuat kode baru. setiap remote akan perlu untuk berpasangan lagi.',
			'companionRemote.remote.disconnectConfirm' => 'Apakah Anda ingin menyingkirkan dari sesi remote?',
			'companionRemote.remote.reconnecting' => 'Menghubungkan kembali...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Mencoba ${current} dari 5',
			'companionRemote.remote.retryNow' => 'Kembali sekarang',
			'companionRemote.remote.tabRemote' => 'jarak jauh',
			'companionRemote.remote.tabPlay' => 'Putar',
			'companionRemote.remote.tabMore' => 'Lebih banyak',
			'companionRemote.remote.menu' => 'Menu yang',
			'companionRemote.remote.tabNavigation' => 'Tab Navigasi',
			'companionRemote.remote.tabDiscover' => 'Temukan',
			'companionRemote.remote.tabLibraries' => 'Pustaka',
			'companionRemote.remote.tabSearch' => 'Cari',
			'companionRemote.remote.tabDownloads' => 'Unduhan',
			'companionRemote.remote.tabSettings' => 'Pengaturan',
			'companionRemote.remote.previous' => 'Sebelumnya',
			'companionRemote.remote.playPause' => 'Bermain dan beristirahat',
			'companionRemote.remote.next' => 'Berikutnya',
			'companionRemote.remote.seekBack' => 'Mencari kembali',
			'companionRemote.remote.stop' => 'Berhenti',
			'companionRemote.remote.seekForward' => 'Mencari FWD',
			'companionRemote.remote.volume' => 'Jumlah',
			'companionRemote.remote.volumeDown' => 'Turun',
			'companionRemote.remote.volumeUp' => 'Ke atas',
			'companionRemote.remote.fullscreen' => 'Layar penuh',
			'companionRemote.remote.subtitles' => 'Subtitel',
			'companionRemote.remote.audio' => 'Audio yang',
			'companionRemote.remote.searchHint' => 'Mencari di Desktop',
			'companionRemote.errors.noNetworkInterface' => 'Tidak ditemukan interaksi jaringan',
			'companionRemote.errors.authenticationFailed' => 'Authenticasi gagal',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Tidak berhasil memulai server remote: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Tidak dapat mengirimkan perintah jarak jauh: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Waktu untuk bergabung dengan sesi',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Tidak dapat terhubung ke alamat apa pun',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Hubungan hilang setelah ${attempts} percobaan',
			'companionRemote.errors.connectionLost' => 'Hubungan yang hilang',
			'companionRemote.closedBeforeAuth' => 'Koneksi ditutup sebelum autentikasi',
			'videoSettings.playbackSpeed' => 'Kecepatan Pemutaran',
			'videoSettings.normalSpeed' => 'Biasa',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktif (${duration})',
			'videoSettings.zoom' => 'Penutup',
			'videoSettings.sleepTimer' => 'Tidur Tidur',
			'videoSettings.audioSync' => 'Audio Sinkron',
			'videoSettings.subtitleSync' => 'Subtitle Sinkronisasi',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR tidak tersedia di sini - komposer desktop atau output video ini tidak dapat membawanya.',
			'videoSettings.hdrToneMapping' => 'HDR Tone Peta',
			'videoSettings.hdrToneMappingCompositor' => 'Komposisi',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Melalui metadata HDR sumber dan biarkan peta komposer desktop itu.',
			'videoSettings.hdrToneMappingPlayer' => 'Pemutar',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Peta ke puncak kecerahan layar di pemain, kemudian memberitahu komposer hasilnya.',
			'videoSettings.hdrToneMappingFailed' => 'Tidak bisa mengubah pemetaan nada HDR - mode sebelumnya masih aktif.',
			'videoSettings.audioOutput' => 'Audio output',
			'videoSettings.performanceOverlay' => 'Perkembangan Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'sekitarnya',
			'videoSettings.audioOutputSpatial' => 'Ruang Audio',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Ekualiser audio',
			'videoSettings.audioEqualizerDescription' => 'Tersedia pada mpv; EQ aktif mendekodkan audio dan menghentikan matchhrough.',
			'videoSettings.audioEqualizerFlat' => 'Lantai',
			'videoSettings.audioEqualizerActive' => 'Kustom',
			'videoSettings.audioEqualizerSaveFailed' => 'Tidak bisa menyimpan seting audio equalizer.',
			'videoSettings.backgroundVideoAudio' => 'Video audio latar belakang',
			'videoSettings.backgroundVideoAudioDescription' => 'Tetap bermain audio video ketika Anda meninggalkan pemain; gambar itu tersembunyi sampai Anda kembali. Android menggunakan pemberitahuan pemutaran media.',
			'videoSettings.audioNormalization' => 'Normalisasi bunyi',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Decode audio ke PCM; passthrough dihapus saat ini',
			'performanceOverlay.color' => 'warna',
			'performanceOverlay.performance' => 'Performa',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'Aplikasi',
			'performanceOverlay.decoder' => 'Dekoder',
			'performanceOverlay.rawDecoder' => 'Kekuatan Decoder',
			'performanceOverlay.tunneling' => 'tunel',
			'performanceOverlay.passthrough' => 'Pasangan',
			'performanceOverlay.aspect' => 'Aspek',
			'performanceOverlay.rotation' => 'Rotasi',
			'performanceOverlay.dvSource' => 'D. Sumber',
			'performanceOverlay.dvPath' => 'Jalan Dwi',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision penghapusan',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision decoder (P7 → 8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Lantai dasar',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 lapisan dasar',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Lantai dasar HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Lantai dasar SDR',
			'performanceOverlay.dvRouteReshaped' => 'RPU yang dihapus kembali (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Grafik Eksperimen P7 FEL (tidak berkelayakan)',
			'performanceOverlay.p7Conversion' => 'P7 dan Conv',
			'performanceOverlay.sampleRate' => 'Nilai Sampel',
			'performanceOverlay.pixelFormat' => 'Pengaturan Pixel Fmt',
			'performanceOverlay.hwFormat' => 'Format perangkat keras',
			'performanceOverlay.matrix' => 'Matriks',
			'performanceOverlay.primaries' => 'Primarisasi',
			'performanceOverlay.transfer' => 'Pindahkan',
			'performanceOverlay.renderFps' => 'Keterangan FPS',
			'performanceOverlay.displayFps' => 'Tampilan FPS',
			'performanceOverlay.avSync' => 'A / V Sync',
			'performanceOverlay.dropped' => 'pecah',
			'performanceOverlay.dvRpus' => 'RPU yang',
			'performanceOverlay.dvRpuAverage' => 'RPU AVG',
			'performanceOverlay.dvSampleAverage' => 'Sebutkan Sample Avg',
			'performanceOverlay.maxLuma' => 'Luma maks.',
			'performanceOverlay.minLuma' => 'Luma min.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache yang digunakan',
			'performanceOverlay.cacheLimit' => 'Cache batas',
			'performanceOverlay.speed' => 'kecepatan',
			'performanceOverlay.player' => 'Pemutar',
			'performanceOverlay.playMethod' => 'Metode putar',
			'performanceOverlay.memory' => 'memori',
			'performanceOverlay.uiFps' => 'FPS yang',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'Nvidia HW',
			'performanceOverlay.decoderQualcommHw' => 'Keterangan Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Keberadaan HW',
			'performanceOverlay.decoderSoftware' => 'Software yang',
			'performanceOverlay.decoderHardware' => 'Perangkat keras',
			'performanceOverlay.tunnelingActive' => 'aktif',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} gagal)',
			'externalPlayer.title' => 'Pemain eksternal',
			'externalPlayer.useExternalPlayer' => 'Gunakan pemain eksternal',
			'externalPlayer.useExternalPlayerDescription' => 'Membuka video di aplikasi lain',
			'externalPlayer.selectPlayer' => 'Pilih Pemain',
			'externalPlayer.customPlayers' => 'Pemain Custom',
			'externalPlayer.systemDefault' => 'Sistem default',
			'externalPlayer.addCustomPlayer' => 'Menambahkan Custom Player',
			'externalPlayer.playerName' => 'Nama Pemain',
			'externalPlayer.playerNameHint' => 'Pemain saya',
			'externalPlayer.playerCommand' => 'Komando',
			'externalPlayer.playerPackage' => 'Nama Pakej',
			'externalPlayer.playerUrlScheme' => 'Sistem URL',
			'externalPlayer.off' => 'Nonaktif',
			'externalPlayer.launchFailed' => 'gagal membuka pemain eksternal',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} tidak diinstal',
			'externalPlayer.playInExternalPlayer' => 'Bermain dengan pemain luar',
			'externalPlayer.description' => 'Pilih aplikasi lain untuk membuka video di. pemain yang tersedia tergantung pada perangkat Anda dan aplikasi yang terinstal.',
			'externalPlayer.systemDefaultDescription' => 'Biarkan sistem operasi membuka video dengan aplikasi defaultnya.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Buka video dengan ${player}.',
			'externalPlayer.playerNameDescription' => 'Label yang ditunjukkan dalam daftar pemain.',
			'externalPlayer.playerPackageDescription' => 'Masukkan nama paket Android dari aplikasi pemain, seperti com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Masukkan perintah pemain yang terinstal atau jalur eksekusi untuk perangkat ini.',
			'externalPlayer.playerUrlSchemeDescription' => 'Masukkan skema URL dan template URL pilihan yang digunakan untuk meluncurkan pemain.',
			'metadataEdit.editMetadata' => 'Sunting',
			'metadataEdit.screenTitle' => 'Sunting metadata',
			'metadataEdit.basicInfo' => 'Informasi dasar',
			'metadataEdit.artwork' => 'seni',
			'metadataEdit.advancedSettings' => 'Pengaturan Lanjutan',
			'metadataEdit.title' => 'Judul',
			'metadataEdit.sortTitle' => 'Urutkan judul',
			'metadataEdit.originalTitle' => 'Judul asli',
			'metadataEdit.releaseDate' => 'Tanggal rilis',
			'metadataEdit.contentRating' => 'Penilaian konten',
			'metadataEdit.studio' => 'Studio yang',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Kesimpulan',
			'metadataEdit.poster' => 'Gambar',
			'metadataEdit.background' => 'latar belakang',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Lapangan Seni',
			'metadataEdit.selectPoster' => 'Pilih Poster',
			'metadataEdit.selectBackground' => 'Pilih latar belakang',
			'metadataEdit.selectLogo' => 'Pilih Logo',
			'metadataEdit.selectSquareArt' => 'Seleksi Square Art',
			'metadataEdit.fromUrl' => 'dari URL',
			'metadataEdit.uploadFile' => 'Upload file',
			'metadataEdit.enterImageUrl' => 'Masukkan URL gambar',
			'metadataEdit.imageUrl' => 'Gambar URL',
			'metadataEdit.metadataUpdated' => 'Metadata yang diperbarui',
			'metadataEdit.metadataUpdateFailed' => 'Tidak dapat mengemas kini metadata',
			'metadataEdit.artworkUpdated' => 'Artwork dikemas kini',
			'metadataEdit.artworkUpdateFailed' => 'gagal memperbarui karya seni',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.noArtworkAvailable' => 'Tidak ada seni yang tersedia',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opsi seni ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opsi seni ${index}, dipilih',
			'metadataEdit.notSet' => 'Tidak menetapkan',
			'metadataEdit.libraryDefault' => 'Perpustakaan default',
			'metadataEdit.accountDefault' => 'Akun default',
			'metadataEdit.seriesDefault' => 'Serangkaian default',
			'metadataEdit.episodeSorting' => 'Episode yang disusun',
			'metadataEdit.oldestFirst' => 'Yang Tertua Pertama',
			'metadataEdit.newestFirst' => 'yang baru pertama',
			'metadataEdit.keep' => 'Tetap',
			'metadataEdit.allEpisodes' => 'Semua episode',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episode terbaru',
			'metadataEdit.latestEpisode' => 'episode terakhir',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episod ditambahkan dalam ${count} hari terakhir',
			'metadataEdit.deleteAfterPlaying' => 'Menghapus episode setelah bermain',
			'metadataEdit.never' => 'Tidak Pernah',
			'metadataEdit.afterADay' => 'Setelah satu hari',
			'metadataEdit.afterAWeek' => 'Setelah seminggu',
			'metadataEdit.afterAMonth' => 'Setelah sebulan',
			'metadataEdit.onNextRefresh' => 'Pada hari berikutnya pembersihan',
			'metadataEdit.seasons' => 'Musim',
			'metadataEdit.show' => 'Pameran',
			'metadataEdit.hide' => 'Sembunyikan',
			'metadataEdit.episodeOrdering' => 'episode perintah',
			'metadataEdit.tmdbAiring' => 'Database Film (Baca Juga)',
			'metadataEdit.tvdbAiring' => 'Kegiatan yang dilakukan oleh TheTVDB (Aired)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolute) adalah',
			'metadataEdit.metadataLanguage' => 'Metadata Bahasa',
			'metadataEdit.useOriginalTitle' => 'Gunakan judul asli',
			'metadataEdit.preferredAudioLanguage' => 'Bahasa audio yang disukai',
			'metadataEdit.preferredSubtitleLanguage' => 'Bahasa teks yang diinginkan',
			'metadataEdit.subtitleMode' => 'Seleksi Subtitle Mode',
			'metadataEdit.manuallySelected' => 'Seleksi secara manual',
			'metadataEdit.shownWithForeignAudio' => 'Menampilkan Audio Asing',
			'metadataEdit.alwaysEnabled' => 'Selalu diizinkan',
			'metadataEdit.tags' => 'Label',
			'metadataEdit.addTag' => 'Tambahkan tag',
			'metadataEdit.genre' => 'Aliran',
			'metadataEdit.director' => 'Direktur',
			'metadataEdit.writer' => 'Penulis',
			'metadataEdit.producer' => 'Produsen',
			'metadataEdit.country' => 'Negara',
			'metadataEdit.collection' => 'Koleksi',
			'metadataEdit.label' => 'Label',
			'metadataEdit.quickTag' => 'Tag yang cepat...',
			'matchScreen.match' => 'Pertandingan...',
			'matchScreen.fixMatch' => 'Perlawanan tetap...',
			'matchScreen.unmatch' => 'Batalkan pencocokan',
			'matchScreen.unmatchConfirm' => 'Plex memperlakukan pertandingan ini sebagai tidak bertanding sampai selesai.',
			'matchScreen.unmatchSuccess' => 'item yang tidak sesuai',
			'matchScreen.unmatchFailed' => 'Kegagalan untuk Unmatch item',
			'matchScreen.matchApplied' => 'Pertandingan yang diterapkan',
			'matchScreen.matchFailed' => 'gagal mengajukan pertandingan',
			'matchScreen.titleHint' => 'Judul',
			'matchScreen.yearHint' => 'Tahun',
			'matchScreen.search' => 'Cari',
			'matchScreen.noMatchesFound' => 'Tidak ditemukan pertandingan',
			'serverTasks.title' => 'Tugas Server',
			'serverTasks.failedToLoad' => 'gagal mengisi tugas',
			'serverTasks.noTasks' => 'Tidak ada tugas yang berjalan',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'terhubung',
			'trakt.connectedAs' => ({required Object username}) => 'Terhubung dengan @${username}',
			'trakt.disconnectConfirm' => 'Menghapus akun Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG akan berhenti mengirimkan acara ke Trakt. Anda dapat menghubungkan kembali kapan saja.',
			'trakt.scrobble' => 'waktu nyata scrobbling',
			'trakt.scrobbleDescription' => 'Hantar permainan, istirahat, dan menghentikan acara ke Trakt selama pemutaran.',
			'trakt.watchedSync' => 'Sinkronisasi status',
			'trakt.watchedSyncDescription' => 'Ketika Anda menandakan item seperti yang dilihat di PlezyNG, mereka juga ditandakan seperti yang dilihat di Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Menghubungkan Seerr',
			'seerr.serverUrl' => 'URL server',
			'seerr.serverUrlHelper' => 'Alamat dari instansi Seerr',
			'seerr.checkServer' => 'Selanjutnya',
			'seerr.signInWithJellyfin' => 'Mendaftar dengan Jellyfin',
			'seerr.signInWithEmby' => 'Mendaftar dengan Emby',
			'seerr.signInWithLocal' => 'Gunakan akun lokal',
			'seerr.email' => 'Email',
			'seerr.noSignInMethods' => 'Contoh Seerr ini tidak menawarkan dukungan log masuk metode PlezyNG.',
			'seerr.instance' => 'instansi',
			'seerr.disconnectConfirm' => 'Menghubungkan Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG akan melupakan contoh Seerr ini. sambungkan kembali kapan saja.',
			'seerr.request' => 'Permintaan',
			'seerr.request4k' => 'Permintaan dalam 4K',
			'seerr.seasons' => 'Musim',
			'seerr.allSeasons' => 'Semua Musim',
			'seerr.advancedOptions' => 'Canggih',
			'seerr.destinationServer' => 'Destinasi server',
			'seerr.qualityProfile' => 'Profil Kualitas',
			'seerr.rootFolder' => 'Fasilitas root',
			'seerr.languageProfile' => 'Profil Bahasa',
			'seerr.tags' => 'Label',
			'seerr.noTags' => 'Tidak ada tag',
			'seerr.defaultOption' => ({required Object name}) => '${name} (dengan default)',
			'seerr.animeNote' => 'Seri ini adalah anime.',
			'seerr.requestSubmitted' => 'Permintaan yang disampaikan',
			'seerr.requestFailed' => ({required Object error}) => 'Permintaan gagal: ${error}',
			'seerr.requestsLoadFailed' => 'Tidak bisa memuat pilihan permintaan',
			'seerr.nothingToRequest' => 'Semua sudah tersedia atau diminta.',
			'seerr.statusAvailable' => 'Tersedia',
			'seerr.statusPartiallyAvailable' => 'Parsial tersedia',
			'seerr.statusRequested' => 'yang diminta',
			'seerr.statusProcessing' => 'Pemrosesan',
			'seerr.statusBlocklisted' => 'Blokasi',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Tidak bisa mencapai ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'No Seerr kasus di ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Sebuah proxy terbalik yang mengesahkan (SSO atau HTTP auth) dijawab sebagai gantinya Seerr. PlezyNG tidak dapat mendaftar melalui itu: biarkan /api/v1 laluan Seerr melewati proxy untuk aplikasi ini, atau gunakan alamat yang mencapai Seerr secara langsung.',
			'seerr.invalidUrl' => 'Masukkan alamat server seperti https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Contoh Seerr ini tidak mendukung Quick Connect.Ia membutuhkan Seerr 3.4 atau lebih baru.',
			'seerr.notInitialized' => 'Instansi Seerr ini belum menyelesaikan setup pertama yang dijalankan',
			'seerr.noPlexTokenForReauth' => 'No. Plex token tersedia untuk mendaftar kembali',
			'seerr.noStoredCredentials' => 'Tidak ada pengesahan yang disimpan tersedia untuk mendaftar kembali',
			'seerr.signInRejected' => 'Tanda-tanda ini ditolak',
			'seerr.noSessionCookie' => 'Seerr tidak mengeluarkan cookie sesi',
			'seerr.freshCookieRejected' => 'Seerr menolak cookie sesi baru',
			'seerr.noUserInformation' => 'Seerr tidak mengembalikan informasi pengguna',
			'seerr.sessionRejectedAfterReauth' => 'Perjanjian itu ditolak setelah ditandatangani lagi.',
			'seerr.permissionDenied' => 'Seerr menolak tindakan ini: akun Anda tidak lagi memiliki izin yang diperlukan',
			'seerr.permissionRevoked' => 'Anda tidak lagi memiliki izin untuk meminta ini',
			'services.title' => 'Layanan',
			'services.hubSubtitle' => 'Sync menonton kemajuan dan meminta judul baru.',
			'services.integrations' => 'Integrasi',
			'services.notConnected' => 'Tidak terhubung',
			'services.connectedAs' => ({required Object username}) => 'Terhubung dengan @${username}',
			'services.scrobble' => 'Menjejaki kemajuan secara otomatis',
			'services.scrobbleDescription' => 'Update daftar Anda saat Anda menyelesaikan episode atau film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Menghubungkan ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG akan berhenti mengemas kini ${service}. sambungkan kembali kapan saja.',
			'services.connectFailed' => ({required Object service}) => 'Saya tidak bisa menghubungkan ke ${service}. coba lagi.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Menghubungkan Simkl',
			'services.simklReconnect.subtitle' => 'Simkl adalah penarikan metode login yang menggunakan koneksi ini. re-connecting membuka simkl.com untuk meluluskan PlezyNG — PlezyNG tidak pernah melihat kata sandi Anda. sejarah jam Anda tetap pada Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Mengaktifkan PlezyNG pada ${service}',
			'services.deviceCode.instructions' => 'Periksa kode QR, atau kunjungi alamat di bawah dan masukkan kode ini:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Buka ${service} untuk mengaktifkan',
			'services.deviceCode.copyCode' => 'Mengaktifkan kode',
			'services.deviceCode.waitingForAuthorization' => 'Menunggu izin...',
			'services.deviceCode.codeCopied' => 'Kode yang disalin',
			'services.oauthProxy.title' => ({required Object service}) => 'Mendaftar di ${service}',
			'services.oauthProxy.body' => 'Memindai kode QR ini atau buka URL pada perangkat apa pun.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Buka ${service} untuk mendaftar',
			'services.pendingAuth.copyUrl' => 'Mendaftar di URL',
			'services.pendingAuth.urlCopied' => 'URL yang disalin',
			'services.libraryFilter.title' => 'Perpustakaan filter',
			'services.libraryFilter.subtitleAllSyncing' => 'Sinkronisasi Semua Perpustakaan',
			'services.libraryFilter.subtitleNoneSyncing' => 'Tidak ada sinergi',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} dikunci',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} diizinkan',
			'services.libraryFilter.mode' => 'Mode filter',
			'services.libraryFilter.modeBlacklist' => 'Daftar hitam',
			'services.libraryFilter.modeWhitelist' => 'Daftar putih',
			'services.libraryFilter.modeHintBlacklist' => 'Sinkronkan setiap perpustakaan kecuali yang diperiksa di bawah.',
			'services.libraryFilter.modeHintWhitelist' => 'Simak hanya perpustakaan yang diperiksa di bawah ini.',
			'services.libraryFilter.libraries' => 'Pustaka',
			'services.libraryFilter.noLibraries' => 'Tidak ada perpustakaan yang tersedia',
			'services.libraryFilter.modeDescription' => 'Pilih apakah perpustakaan yang disemak diblokir dari sinergi atau adalah satu-satunya perpustakan yang bersinkron.',
			'services.seerrDescription' => 'Hubungi Seerr atau Overseerr untuk mencari judul dan mengajukan permintaan media.',
			'services.trackerDescriptions.trakt' => 'Sinkronkan episode dan film yang ditonton dengan akun Trakt Anda.',
			'services.trackerDescriptions.mal' => 'Sinkronkan daftar anime dan perhatikan kemajuan dengan MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Sync anime daftar dan menonton kemajuan dengan AniList.',
			'services.trackerDescriptions.simkl' => 'Sync menonton film, acara TV, dan anime dengan Simkl.',
			'services.trackerDescriptions.mdblist' => 'Tunjukkan rating dan daftar MDBList dalam rekomendasi dan Temukan.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Tambahkan server ${product}',
			'addServer.serverUrls' => 'URL server yang',
			'addServer.serverUrlsHelper' => 'Banyak URL yang diizinkan, dipisahkan oleh commas.',
			'addServer.findServer' => 'Temukan server',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Mencari server lokal ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Lokasi ${product} server',
			'addServer.username' => 'Nama Pengguna',
			'addServer.password' => 'Kata sandi',
			'addServer.signIn' => 'Masuk',
			'addServer.change' => 'Perubahan',
			'addServer.required' => 'Diperlukan',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Tidak dapat mencapai server: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Daftar yang gagal: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect gagal: ${error}',
			'addServer.addPlexTitle' => 'Mendaftar dengan Plex',
			'addServer.pinExpired' => 'PIN sudah habis sebelum masuk.Sila coba lagi.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Kegagalan mendaftarkan akun: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Masukkan URL server ${product} Anda',
			'addServer.addConnectionTitle' => 'Tambahkan koneksi',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Tambahkan ke ${name}',
			'addServer.signInWithPlexCard' => 'Mendaftar dengan Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Mengaktifkan perangkat ini. server yang dibagikan ditambahkan.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Mengaktifkan akun Plex . pengguna rumah menjadi profil.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Menghubungkan ke ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Masukkan URL, nama pengguna, dan kata sandi server Anda.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Mendaftar ke server ${product} Anda. menghubungkan ke ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Pinjaman dari profil lain',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Menggunakan koneksi profil lain. profil yang dilindungi PIN membutuhkan PIN.',
			'addServer.invalidCredentials' => 'Nama pengguna atau kata sandi yang tidak sah',
			'addServer.authResponseNotJson' => 'Jawaban pengesahan tidak sah JSON',
			'addServer.authResponseIncomplete' => 'Respon sign-in dari server tidak lengkap',
			'addServer.quickConnectRejected' => 'Quick Connect ditolak oleh server',
			'addServer.quickConnectNotJson' => 'Jawaban Quick Connect tidak sah JSON',
			'addServer.quickConnectMissingFields' => 'Jawaban Quick Connect tidak memiliki kode atau rahasia',
			'addServer.quickConnectPollRejected' => 'Quick Connect pertanyaan ditolak oleh server',
			'addServer.serverTimedOut' => 'Server tidak bertindak balas tepat waktu.',
			'addServer.responseNotJson' => 'Jawaban server tidak valid JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Jawabannya hilang ID atau nama server — apakah ini server ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Tidak dapat mencapai server: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Masukkan sekurang-kurangnya satu URL server ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Tidak ditemukan server yang dapat diakses ${product}',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'URL ini menunjuk ke server yang berbeda ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'URL ini tidak sesuai dengan server ${product}',
			'addServer.redirectUnsupported' => 'Server yang dialihkan ke URL yang tidak didukung',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Server dialihkan ke host yang berbeda.Masukkan URL akhir ${product} langsung.',
			'addServer.redirectInsecure' => 'Server yang dialihkan dari HTTPS ke URL yang tidak aman',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Server dialihkan ke URL yang tidak didukung. masukkan URL terakhir ${product} langsung.',
			'addServer.directPlexServerUrl' => 'Plex URL server',
			'addServer.directPlexServerUrlHelper' => 'Masukkan IP dan port lokal dari server media Plex Anda.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (pilihan)',
			'addServer.plexTokenHelper' => 'Tinggalkan kosong jika akses tanpa auth diizinkan di server ini.',
			'addServer.plexTokenRequired' => 'Silahkan masukkan token Plex Anda (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Server media Plex (langsung / lokal)',
			'addServer.connectDirectPlexCardSubtitle' => 'Hubungi secara langsung menggunakan IP atau URL lokal tanpa akun plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Hubungi secara langsung menggunakan IP lokal atau URL. Hubungi ${name}.',
			'addServer.insecureTitle' => 'Koneksi yang tidak terenkripsi',
			'addServer.insecureDescription' => ({required Object url}) => '${url} menggunakan HTTP. Orang lain di jaringan dapat membaca atau mengubah kata sandi, token, dan media Anda. Gunakan HTTPS jika tersedia. Lanjutkan hanya jika Anda memercayai jaringan ini dan menerima risikonya.',
			'addServer.allowHttp' => 'Izinkan HTTP',
			'addServer.httpsRequired' => 'Menggunakan HTTPS atau secara eksplisit memungkinkan koneksi yang tidak terenkripsi.',
			'watchLink.serverUnavailable' => 'Saya tidak bisa mengakses server Plex untuk link ini.',
			'watchLink.notFound' => 'Saya tidak dapat menemukan acara atau film ini di server Plex Anda.',
			'watchLink.ambiguous' => 'Link ini cocok dengan item di lebih dari satu server.Tambahkan server ke link.',
			'watchLink.plexOnly' => 'Link menonton saat ini hanya mendukung server Plex.',
			'watchLink.unsupportedItem' => 'Link menonton hanya dapat membuka acara atau film.',
			'watchLink.menuItem' => 'Lihat link',
			'watchLink.dialogTitle' => 'Lihat link',
			'watchLink.dialogShowHint' => 'Membuka link ini memainkan episode berikutnya.Tambahkan &mode=shuffle ke akhir untuk memainkan acara di shuffle.',
			'watchLink.dialogMovieHint' => 'Membuka link ini memainkan film ini.',
			'watchLink.copy' => 'Salin',
			'watchLink.copied' => 'Link yang disalin',
			'homeLayout.title' => 'Rumah Layout',
			'homeLayout.resetToast' => 'Home Reset ke layout hero asli Plezy',
			'homeLayout.resetHeroTitle' => 'Mengembalikan layout pahlawan ke stok Plezy?',
			'homeLayout.resetHeroBody' => 'Mengalih keluar setiap baris pengaturan pahlawan dan membawa kembali satu banner berputar di bagian atas rumah, seperti sebelum baris pahlawan ada.',
			'homeLayout.removeRowTitle' => 'Menghapus rumah tangga?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} akan dihapus. ini tidak dapat dibatalkan.',
			'homeLayout.sync' => 'Sinkron',
			'homeLayout.syncAccountTitle' => 'Sinkronisasi layout dengan akun Plex Anda',
			'homeLayout.syncAccountOn' => 'Pada: perangkat ini berbagi urutan, urutan, Hero dan Auto-slide dengan perangkat lain Anda.',
			'homeLayout.syncAccountOff' => 'Off: perangkat ini mempertahankan layoutnya sendiri.',
			'homeLayout.syncNow' => 'Sync sekarang',
			'homeLayout.plexHomeManager' => 'Plex Pengurus Rumah',
			'homeLayout.managePlexRows' => 'Mengelola Plex baris di Plezy',
			'homeLayout.managePlexRowsDescription' => 'Terbuka untuk mengatur rangkaian yang dipilih di rumah',
			'homeLayout.organizeHomeRows' => 'Mengatur rangkaian rumah',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} baris: bergerak, Hero, Auto-slide, menghapus',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Mengatur ${library} baris',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Selanjutnya Menonton + ${n} baris: bergerak, Perpustakaan, Rumah, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Render sebagai kartu pahlawan',
			'homeLayout.heroOnlySingleCollection' => 'Hanya tersedia ketika baris ini diselesaikan untuk judul nyata dari satu koleksi',
			'homeLayout.hero' => 'pahlawan',
			'homeLayout.autoSlide' => 'Seluruh Slide',
			'homeLayout.autoSlideDescription' => 'Arrows (PC) dan d-pad (TV) selalu bekerja dan memulai kembali timer.',
			'homeLayout.autoSlideEditDescription' => 'Selain itu, ia juga meluncur sendiri setiap beberapa detik. Off: hanya bergerak ketika Anda mengklik pistol (PC) atau tekan kiri/kanan pada remote (TV). Arrow dan d-pad selalu bekerja sama.',
			'homeLayout.enableHeroFirst' => 'Memungkinkan Hero Pertama',
			'homeLayout.showOnHome' => 'Tampilkan pada Home Screen',
			'homeLayout.home' => 'rumah',
			'homeLayout.removeFromHome' => 'Menghilangkan dari rumah',
			'homeLayout.selectRowsFirst' => 'Pilih rumah baris di bawah pertama.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex baris yang dikendalikan',
			'homeLayout.continueWatching' => 'Lanjutkan menonton',
			'homeLayout.continueWatchingLibraryDescription' => 'Perpustakaan ini sendiri resume-progress baris',
			'homeLayout.continueWatchingHomeDescription' => 'Rangkaian kemajuan yang ditunjukkan di rumah',
			'homeLayout.nextUpHomeDescription' => 'Next Unwatched episode series yang ditampilkan secara terpisah di Home',
			'homeLayout.library' => 'Pustaka',
			'homeLayout.showInRecommended' => 'Perpustakaan yang disarankan',
			'homeLayout.customPlexRow' => 'Keterampilan Plex baris',
			'homeLayout.heroNeedsLibrary' => 'Periksa perpustakaan pertama — Hero perlu di suatu tempat untuk menunjukkan',
			'homeLayout.heroNeedsSurface' => 'Periksa Perpustakaan atau Rumah terlebih dahulu — Hero perlu di suatu tempat untuk menunjukkan',
			'homeLayout.removeHub' => 'Menghapus Hub',
			'homeLayout.noPlexRows' => 'No. Plex baris yang dikelola kembali untuk perpustakaan ini.',
			'homeLayout.openDetails' => 'Detail Terbuka',
			'homeLayout.heroCards' => 'Kartu Hero',
			'homeLayout.tapHeroCard' => 'Menangkap Kartu Pahlawan',
			'homeLayout.tvPlayFocus' => 'TV Remote: Meningkatkan tombol Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad ke bawah berhenti pada tombol Play sebelum bergerak ke baris berikutnya.',
			'homeLayout.tvWrap' => 'TV Remote: Kartu Pahlawan Loop',
			'homeLayout.tvWrapDescription' => 'Tepat pada kartu terakhir kembali ke kartu pertama. berhenti pada kartu terakhir. kiri pada kartu pertama selalu pergi ke bar samping.',
			'homeLayout.castOnHero' => 'Bermain dengan Hero Banner',
			'homeLayout.castOnHeroDescription' => 'Menunjukkan cast di bagian bawah banner pahlawan. di luar hanya menyimpan judul dan ringkasan.',
			'homeLayout.customRows' => 'Rangkaian Custom',
			'homeLayout.loading' => 'Layout Rumah Layout...',
			'homeLayout.noCustomRows' => 'Belum ada rangkaian',
			'homeLayout.addRowHint' => 'Gunakan Add Home row untuk membuat satu.',
			'homeLayout.addHomeRow' => 'Menambahkan Home Rue',
			'homeLayout.addHomeRowDescription' => 'Pilih kategori; baris baru ditambahkan ke Organisator secara otomatis',
			'homeLayout.removeRow' => 'Menghilangkan Ronde',
			'homeLayout.recentlyAdded' => 'Terbaru',
			'homeLayout.recentlyReleased' => 'Baru-baru ini dilepaskan',
			'homeLayout.movieCollections' => 'Koleksi Film',
			'homeLayout.showCollections' => 'Tunjukkan Koleksi',
			'homeLayout.rowTitle' => 'Judul Row',
			'homeLayout.content' => 'Sukses',
			'homeLayout.showThisRowIn' => 'Tunjukkan baris ini di:',
			'homeLayout.libraryRecommended' => 'Perpustakaan yang disarankan',
			'homeLayout.heroCard' => 'Kartu Hero',
			'homeLayout.heroCardDescription' => 'Menunjukkan sebagai satu kartu putar lebar penuh bukannya poster shelf.',
			'homeLayout.heroUnavailableDescription' => 'Hanya tersedia ketika baris ini diselesaikan untuk judul nyata dari satu koleksi - dengan lebih dari satu koleksi terpilih tidak ada satu judul untuk berputar melalui.',
			'homeLayout.librariesSelection' => 'Perpustakaan (meninggalkan semua tidak disemak untuk mencakup setiap perpustakaan)',
			'homeLayout.librariesMergedDescription' => 'Setiap perpustakaan yang diperiksa di sini digabungkan ke dalam satu baris ini.',
			'homeLayout.movieCollectionsSelection' => 'Koleksi film (meninggalkan semua tidak disemak untuk setiap perpustakaan yang dipilih)',
			'homeLayout.showCollectionsSelection' => 'Menampilkan koleksi (meninggalkan semua yang tidak disemak untuk setiap perpustakaan yang dipilih)',
			'homeLayout.collectionRowsDescription' => 'Jika satu koleksi bertanding, judulnya ditampilkan secara langsung dalam urutan.Jika lebih dari satu koleksi bertanding, setiap koleksi ditampilkan sebagai satu poster — ketiknya untuk membuka koleksi itu.',
			'homeLayout.allCollections' => 'Semua Koleksi',
			'homeLayout.noRowsHere' => 'Belum ada baris di sini.',
			'homeLayout.hideWatchedRows' => 'Menutup barang-barang yang dilihat dalam baris',
			'homeLayout.hideWatchedRowsDescription' => 'Judul yang dipantau sepenuhnya meninggalkan Rumah dan perpustakaan Rangkaian yang disarankan.',
			'homeLayout.untitledCollection' => 'Koleksi Untitled',
			'homeLayout.moveRowHint' => 'Up/Down: bergerak baris · Pilih: turun di sini · Kembali: membatalkan',
			'homeLayout.organizeRowsHint' => 'Pilih pada urutan (atau tahan Pilih): pindah · Kiri/Kiri: pilihan urutan · Kembali: selesai',
			'homeLayout.layoutNavDescription' => 'Pilih baris, perpustakaan, dan kategori koleksi',
			'homeLayout.editHomeRow' => 'Edit rumah tangga',
			'homeLayout.resetHeroButton' => 'Reset Hero layout ke stok Plezy',
			'homeLayout.reorderingUnlocked' => 'Kembali ke Unlocked',
			'homeLayout.reorderingLocked' => 'Kembali tertutup',
			'homeLayout.rowsCanBeDragged' => 'Roda dapat ditarik — tekan kunci untuk mencegah',
			'homeLayout.tapLockToDrag' => 'Tekan kunci untuk menarik baris',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Jumlah : ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Sembunyikan',
			'homeLayout.remove' => 'Hapus',
			'homeLayout.libraryResumeRow' => 'Perpustakaan ini kembali',
			'homeLayout.pressAgainToDelete' => 'Tekan lagi untuk menghapus',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'pada',
			'homeLayout.resetHeroButtonDescription' => 'Mengalih keluar setiap baris pengaturan pahlawan dan membawa kembali satu banner berputar di atas, seperti sebelum baris pahlawan ada.',
			'homeLayout.tapHeroCardDescription' => 'Pilih apakah menekan atau memilih kartu Hero memulai playback atau membuka detailnya.',
			'homeLayout.heroTapPlayDescription' => 'Mulai item yang dipilih segera.',
			'homeLayout.heroTapDetailsDescription' => 'Buka detail item yang dipilih sebelum memilih tindakan.',
			'platform.localNetworkPermission' => 'PlezyNG terhubung ke server media dan perangkat playback Anda di jaringan lokal Anda.',
			'platform.locationPermission' => 'PlezyNG menggunakan akses lokasi ketika iOS membutuhkan untuk mengidentifikasi jaringan lokal Anda dan menghubungkannya ke server media Anda.',
			'platform.photoLibraryPermission' => 'Pilih gambar dari perpustakaan foto Anda untuk digunakan sebagai karya seni media.',
			'platform.cameraPermission' => 'Mengimbas kode QR untuk berpasangan dengan Companion Remote.',
			'universalMedia.title' => 'Media Terbuka',
			'universalMedia.shortcutHelp' => 'Mainkan link, playlist, atau file untuk sesi ini.',
			'universalMedia.intro' => 'Buka link, playlist, atau file. Playback menggunakan pemutar standar PlezyNG dan tidak menambahkan sejarah ke perpustakaan Anda.',
			'universalMedia.openWhat' => 'Apa yang ingin Anda buka?',
			'universalMedia.stream' => 'Alamat Stream',
			'universalMedia.playlist' => 'Daftar Playlist',
			'universalMedia.files' => 'perangkat file',
			'universalMedia.favorites' => 'Penyimpanan Stream Favorit',
			'universalMedia.address' => 'Alamat Media',
			'universalMedia.addressHelp' => 'URL dengan parameter pengesahan atau tandatangan yang diakui hanya digunakan untuk sesi ini dan tidak dapat disimpan sebagai favorit.',
			'universalMedia.displayName' => 'Nama Pameran (Optional)',
			'universalMedia.displayNameHelp' => 'Pilih nama singkat untuk pemain dan kontrol media sistem.',
			'universalMedia.allowHttp' => 'Memungkinkan koneksi HTTP yang tidak terenkripsi',
			'universalMedia.allowHttpHelp' => 'HTTP tidak menyulitkan koneksi. hanya membiarkannya di jaringan yang dipercaya. gunakan HTTPS kapan saja mungkin.',
			'universalMedia.advancedProtocols' => 'Hanya MPV: masukkan alamat RTSP, RTMP/RTMPS, UDP, atau RTP. Alamat ini tidak dapat disimpan sebagai favorit.',
			'universalMedia.liveStream' => 'Perlakukan sebagai hidup',
			'universalMedia.liveStreamHelp' => 'Gunakan ini untuk live video atau radio. aplikasi menyembunyikan bar waktu, skip tombol, dan go-to-time opsi.',
			'universalMedia.privateSession' => 'Hanya playback ini menggunakan alamat.Save a eligible stream favorite to keep it in this profile.',
			'universalMedia.saveFavorite' => 'Selamatkan Favorit',
			'universalMedia.playNow' => 'Bermain sekarang',
			'universalMedia.favoriteSaved' => 'Stream favorit disimpan ke profil ini',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${count} masuk daftar main yang tidak didukung atau tidak aman.', ),
			'universalMedia.playlistAddress' => 'Alamat Playlist',
			'universalMedia.playlistAddressHelp' => 'Buka daftar main M3U, M3u8, atau PLS dari alamat web. link streaming langsung tidak menyimpan daftar main.',
			'universalMedia.choosePlaylist' => 'Pilih file playlist',
			'universalMedia.openPlaylist' => 'Pembukaan playlist',
			'universalMedia.playlistFormatsHelp' => 'Daftar main dapat berisi lebih dari 1.000 item dan 2 MB. HLS terbuka sebagai arus sehingga pemain dapat memilih kualitas.',
			'universalMedia.noFavorites' => 'Belum disimpan streaming favorit sampai sekarang. favorit tetap di profil ini.',
			'universalMedia.removeFavorite' => 'Menghapus Stream Favorit',
			'universalMedia.filesHelp' => 'Pilih file audio, video, atau ISO untuk catatan sementara.File dan URL tidak ditambahkan ke sejarah perpustakaan.',
			'universalMedia.chooseFiles' => 'Pilih file',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${count} file terpilih', ),
			'universalMedia.wifiTransfer' => 'Mengirim file melalui Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Memindahkan file yang didukung dari browser pada jaringan yang sama.',
			'universalMedia.wifiTransferIntro' => 'Buka alamat ini dalam browser pada perangkat lain. pilih file untuk menambahkan mereka ke perpustakaan File dan buku perangkat ini.',
			'universalMedia.wifiTransferPrivacy' => 'Setiap orang yang tahu alamat ini dapat mengirim file sampai Anda menghentikan transfer atau alamat berakhir setelah 15 menit. maksimum: 100 file, 4 GiB per file, 10 GiB total.',
			'universalMedia.wifiTransferStarting' => 'Menyiapkan transfer pribadi dan terbatas waktu.',
			'universalMedia.wifiTransferUnavailable' => 'Tidak bisa memulai transfer. periksa akses jaringan lokal dan coba lagi.',
			'universalMedia.openThisAddress' => 'Buka salah satu alamat ini pada perangkat pengiriman',
			'universalMedia.copyAddress' => 'Kopi alamat transfer',
			'universalMedia.addressCopied' => 'Alamat transfer yang disalin',
			'universalMedia.transferExpires' => ({required Object time}) => 'Alamat ini berakhir di ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${count} file yang diterima', ),
			'universalMedia.uploadedData' => ({required Object size}) => 'Diterima oleh ${size}',
			'universalMedia.stopTransfer' => 'Hentikan transfer dan membatalkan alamat',
			'universalMedia.startTransfer' => 'Mulai transfer',
			'universalMedia.wifiImportedFiles' => 'Pengiriman Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Mengirim file ke PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Pilih file audio, video, ebook, atau komik untuk dikirimkan. file disimpan di perpustakaan File dan buku perangkat ini. maksimum: 100 file, 4 GiB per file, 10 GiB total.',
			'universalMedia.uploadFilesLabel' => 'File untuk dikirimkan',
			'universalMedia.uploadSelected' => 'Mengunggah file terpilih',
			'universalMedia.uploadSelectFirst' => 'Pilih satu atau lebih file terlebih dahulu.',
			'universalMedia.uploading' => 'mengirimkan',
			'universalMedia.uploadComplete' => 'File yang ditambahkan ke PlezyNG.',
			'universalMedia.uploadFailed' => 'File tidak dapat ditambahkan.Jadilah halaman ini terbuka dan coba lagi.',
			'universalMedia.liveCue' => 'hidup',
			'universalMedia.liveSession' => 'Live Stream',
			'universalMedia.liveCueHelp' => 'Untuk video atau radio langsung, aplikasi menyembunyikan bar waktu dan melompat tombol. tidak menyimpan alamat atau menonton sejarah.',
			'universalMedia.sessionOnly' => 'Playback ini hanya sesi saja.',
			'universalMedia.sessionOnlyHelp' => 'Playback tidak pernah menyimpan kemajuan atau sejarah.Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'Gambar penyesuaian',
			'universalMedia.pictureHelp' => 'Perubahan gambar ini hanya mempengaruhi playback ini. mereka menetapkan kembali ketika playback berakhir.',
			'universalMedia.resetPicture' => 'Reset gambar',
			'universalMedia.brightness' => 'Cahaya',
			'universalMedia.contrast' => 'kontras',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturasi',
			'universalMedia.view360' => 'Pemandangan rata untuk video 360 derajat',
			'universalMedia.view360Help' => 'Gunakan ini untuk video 360° equirectangular. MPV membutuhkan filter v360 FFmpeg untuk pandangan ini.',
			'universalMedia.view360Unavailable' => 'Pembuatan MPV ini tidak dapat menerapkan filter 360 derajat.',
			'universalMedia.view360Yaw' => 'pandangan horizontal',
			'universalMedia.view360Pitch' => 'Pandangan Vertikal',
			'universalMedia.view360FieldOfView' => 'Bidang Penglihatan',
			'universalMedia.recordStream' => 'Rekor Live Stream',
			'universalMedia.stopRecording' => 'Hentikan dan Simpan Rekaman',
			'universalMedia.recordingStarted' => 'Rekaman aktif. meninggalkan playback berhenti dan menyimpan rekaman.',
			'universalMedia.recordingSaved' => 'Rekaman selesai dan diselamatkan.',
			'universalMedia.recordingActive' => 'Mengingat perangkat ini. meninggalkan playback berhenti dan menyimpannya.',
			'universalMedia.recordingFormatHelp' => 'Untuk video, pilih MKV atau MPEG-TS. untuk audio, pilih MKA atau MKV.',
			'universalMedia.replaceRecordingTitle' => 'Mengganti rekaman ini?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG mengembalikan file yang ada saat merekam.Jika tidak dapat menyimpan rekaman baru, plezyNG memulihkan sandaran.',
			'universalMedia.replaceRecording' => 'Mengganti file',
			'universalMedia.discHelp' => 'Buka cakera di drive optik komputer ini.Anda juga dapat membuka gambar ISO dari file perangkat.',
			'universalMedia.discs' => 'Disk optik',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'dan Blu-ray',
			'universalMedia.audioCd' => 'Audio CD',
			'universalMedia.discAvailability' => 'Disk playback membutuhkan konfigurasi MPV yang kompatibel, drive yang didukung, dan izin sistem operasi.',
			'universalMedia.converterTitle' => 'Konversi file media lokal',
			'universalMedia.converterHelp' => 'Gunakan FFmpeg untuk membuat MP4, M4A, atau MP3 salinan.',
			'universalMedia.converterIntro' => 'Konversi file audio atau video lokal ke format yang bekerja pada lebih banyak perangkat.',
			'universalMedia.converterPrivacy' => 'FFmpeg harus dipasang pada komputer ini.Conversion hanya membaca file lokal.Ia tidak mengunduh aliran atau menghapus DRM.',
			'universalMedia.converterChooseInput' => 'Pilih file media lokal',
			'universalMedia.converterFormat' => 'Format output',
			'universalMedia.converterMp4' => 'MP4 H.264 dan AAC',
			'universalMedia.converterM4a' => 'M4A · AAC audio',
			'universalMedia.converterMp3' => 'MP3 dan Audio',
			'universalMedia.converterSaveAs' => 'Menyimpan media yang terkonversi sebagai',
			'universalMedia.converterExtensionMismatch' => 'Pilih nama file dengan ekstensi output yang dipilih.',
			'universalMedia.converterUnsupportedInput' => 'Pilih file audio atau video.',
			'universalMedia.converterLocalOnly' => 'File yang dipilih tidak tersedia sebagai jalur perangkat lokal.',
			'universalMedia.converterReplaceTitle' => 'Mengganti file ini?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG mengembalikan file yang ada sampai salinan terkonversi disimpan.',
			'universalMedia.converterStarting' => 'Mulai dari FFmpeg...',
			'universalMedia.converterProgress' => 'Beralih ke komputer ini...',
			'universalMedia.converterComplete' => 'Konversi selesai. file baru sudah siap.',
			'universalMedia.converterFfmpegMissing' => 'Instal FFmpeg dengan dukungan H.264, AAC, dan MP3, kemudian coba lagi.',
			'universalMedia.converterFailed' => 'Periksa bahwa file sumber dapat dibaca dan tujuan memiliki cukup ruang gratis.',
			'universalMedia.converterCancelled' => 'Konversi dibatalkan. hasil yang tidak lengkap dihapus.',
			'universalMedia.converterDesktopOnly' => 'Konversi lokal tersedia pada komputer desktop dengan FFmpeg terinstal.',
			'universalMedia.converterStart' => 'Konversi file',
			'fileSources.title' => 'File dan buku',
			'fileSources.subtitle' => 'Baca, dengar, dan menonton dari file Anda sendiri.',
			'fileSources.add' => 'Tambahkan sumber',
			'fileSources.importFiles' => 'Import file',
			'fileSources.localFiles' => 'Pada perangkat ini',
			'fileSources.source' => 'Sumber',
			'fileSources.name' => 'Nama',
			'fileSources.endpoint' => 'URL server',
			'fileSources.smbEndpointHint' => 'Contoh: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Masukkan server SMB dan satu folder bersama.',
			'fileSources.root' => 'Folder atau prefiks',
			'fileSources.smbFolderHelp' => 'Biarkan kosong untuk menggunakan seluruh folder bersama, atau masukkan folder di dalamnya.',
			'fileSources.username' => 'Nama Pengguna',
			'fileSources.smbDomain' => 'Domain (opsional)',
			'fileSources.password' => 'Kata sandi',
			'fileSources.token' => 'API Token',
			'fileSources.accessKey' => 'Akses ke kunci ID',
			'fileSources.secretKey' => 'Key akses rahasia',
			'fileSources.sessionToken' => 'Sesi token ( opsi)',
			'fileSources.region' => 'Daerah',
			'fileSources.clientId' => 'ID pelanggan OAuth',
			'fileSources.clientSecret' => 'OAuth Client Secret (hanya desktop Google)',
			'fileSources.allowHttp' => 'Izinkan HTTP tanpa enkripsi di jaringan tepercaya',
			'fileSources.smbEncryption' => 'Enkripsi koneksi SMB3',
			'fileSources.smbEncryptionHint' => 'Gunakan enkripsi SMB3 jika NAS mendukungnya.',
			'fileSources.connect' => 'Sambung',
			'fileSources.cancel' => 'Batal',
			'fileSources.save' => 'Simpan',
			'fileSources.close' => 'Tutup',
			'fileSources.removeSource' => 'Sumber yang terhubung',
			'fileSources.disconnectMessage' => 'Putuskan sambungan sumber ini? Berkas yang diunduh serta riwayat membaca dan mendengarkan Anda akan tetap tersimpan di perangkat ini.',
			'fileSources.localFolder' => 'Pilih folder',
			'fileSources.empty' => 'Belum ada yang di sini',
			'fileSources.emptyHint' => 'Tambah sumber atau impor buku, audiobook, musik, atau video.',
			'fileSources.search' => 'Cari folder ini',
			'fileSources.searchCached' => 'Mencari perpustakaan yang diselamatkan',
			'fileSources.refresh' => 'Segarkan',
			'fileSources.loadMore' => 'Layar Lebih',
			'fileSources.offline' => 'Tersedia offline',
			'fileSources.download' => 'Tetap offline',
			'fileSources.removeDownload' => 'Menghapus offline copy',
			'fileSources.continueReading' => 'Lanjutkan Membaca',
			'fileSources.continueListening' => 'Lanjut Mendengarkan',
			'fileSources.continueWatching' => 'Lanjutkan menonton',
			'fileSources.read' => 'Bacaan',
			'fileSources.listen' => 'Dengarkan',
			'fileSources.play' => 'Putar',
			'fileSources.pause' => 'Jeda',
			'fileSources.stop' => 'Berhenti',
			'fileSources.startOver' => 'Mulai dari',
			'fileSources.finished' => 'selesai',
			'fileSources.markFinished' => 'Mark sudah selesai',
			'fileSources.markUnfinished' => 'Mark yang tak terbatas',
			'fileSources.editions' => 'Edisi dan file',
			'fileSources.chapters' => 'bab yang',
			'fileSources.bookmarks' => 'Buku dan Notis',
			'fileSources.bookmark' => 'Tambahkan Bookmark',
			'fileSources.highlight' => 'Peningkatan',
			'fileSources.note' => 'Catatan',
			'fileSources.delete' => 'Hapus',
			'fileSources.export' => 'Notis Ekspor',
			'fileSources.exported' => 'Notis yang diekspor',
			'fileSources.sync' => 'Sinkronisasi Kemajuan',
			'fileSources.synced' => 'Kemajuan Sinkronisasi',
			'fileSources.conflict' => 'Perangkat lain memiliki posisi yang berbeda. pilih di mana untuk melanjutkan.',
			'fileSources.useLocal' => 'Gunakan perangkat ini',
			'fileSources.useRemote' => 'Gunakan perangkat lain',
			'fileSources.history' => 'Posisi Sejarah',
			'fileSources.groupAudio' => 'Mendengarkan sebagai satu buku audio',
			'fileSources.groupHint' => 'Menghubungkan file audio yang saat ini dimuat dalam folder ini. muat semua halaman terlebih dahulu.',
			'fileSources.order' => 'File perintah',
			'fileSources.moveUp' => 'bergerak ke atas',
			'fileSources.moveDown' => 'Memuat turun',
			'fileSources.speed' => 'Kecepatan Pemutaran',
			'fileSources.sleep' => 'Waktu Tidur',
			'fileSources.sleepOff' => 'Nonaktif',
			'fileSources.endChapter' => 'Akhir dari bab',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} menit', ), 
			'fileSources.skipBack' => 'Kembali ke Sk',
			'fileSources.skipForward' => 'melangkah maju',
			'fileSources.smartRewind' => 'Kembali ke Smart After a Pause',
			'fileSources.playbackOptions' => 'Pilihan Mendengarkan',
			'fileSources.remaining' => ({required Object time}) => '${time} yang tersisa',
			'fileSources.contents' => 'Konten',
			'fileSources.readerSettings' => 'Membaca Settings',
			'fileSources.fontSize' => 'Ukuran teks',
			'fileSources.lineHeight' => 'Line ruang',
			'fileSources.margin' => 'Margin',
			'fileSources.font' => 'Tipe Wajah',
			'fileSources.serif' => 'Serif',
			'fileSources.sans' => 'Tanpa serif',
			'fileSources.mono' => 'Monospace',
			'fileSources.columns' => 'Kolom',
			'fileSources.scroll' => 'Scroll secara vertikal',
			'fileSources.justify' => 'Ratakan teks kiri-kanan',
			'fileSources.readerTheme' => 'Penampilan halaman',
			'fileSources.appTheme' => 'Mengikuti tema app',
			'fileSources.paper' => 'Kertas',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Malam yang',
			'fileSources.readAloud' => 'Bacakan halaman ini',
			'fileSources.readAlong' => 'Baca sambil mendengarkan',
			'fileSources.stopReading' => 'Hentikan narasi',
			'fileSources.searchBook' => 'Pencarian dalam buku',
			'fileSources.noMatches' => 'Tidak ada pertandingan',
			'fileSources.previousPage' => 'Halaman sebelumnya',
			'fileSources.nextPage' => 'Halaman selanjutnya',
			'fileSources.page' => ({required Object number}) => 'Halaman ${number}',
			'fileSources.externalBlocked' => 'Link buku eksternal diblokir di pembaca.',
			'fileSources.loading' => 'Pembukaan...',
			'fileSources.narrator' => 'narator',
			'fileSources.audio' => 'Audio yang',
			'fileSources.video' => 'Video yang',
			'fileSources.ebooks' => 'ebook',
			'fileSources.all' => 'Semua',
			'fileSources.downloads' => 'File Offline',
			'fileSources.confirmDelete' => 'Hapus salinan luring yang dipilih? Posisi membaca atau mendengarkan dan catatan Anda akan tetap tersimpan.',
			'fileSources.errorAuthentication' => 'Masuk lagi untuk menyambungkan kembali sumber ini.',
			'fileSources.errorPermission' => 'Sumber ini tidak memberikan akses ke file yang diminta.',
			'fileSources.errorUnavailable' => 'Sumber tidak tersedia. Coba lagi, atau buka salinan luring.',
			'fileSources.errorUnsupported' => 'Format atau koneksi ini tidak didukung pada perangkat ini. periksa panduan pengaturan sumber.',
			'fileSources.errorInvalidData' => 'File atau respons server ini tidak dapat dibaca dengan aman.',
			'fileSources.errorCancelled' => 'Operasi ini dibatalkan.',
			'fileSources.errorConflict' => 'Posisi berubah dalam sesi lain. buka kembali item untuk memilih posisi.',
			'fileSources.signIn' => 'Masuk',
			'fileSources.reconnect' => 'Menghubungkan kembali',
			'fileSources.folderHelp' => 'Tinggalkan kosong untuk memulai pada akar sumber. URL S3 termasuk bucket.',
			'fileSources.preferences' => 'preferensi',
			'fileSources.timePosition' => 'Posisi',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Subtitle Track',
			'fileSources.none' => 'Tidak Ada',
			'fileSources.fullscreen' => 'Layar penuh',
			'fileSources.syncLocation' => 'Fold Sinkronisasi Progress (optional)',
			'fileSources.syncLocationHint' => 'Sebuah folder khusus WebDAV untuk PlezyNG status. menggunakan tulisan bersyarat; media tetap tidak berubah.',
			'fileSources.audiobooks' => 'Buku Audio',
			'fileSources.comics' => 'Komik',
			'fileSources.scan' => 'Scan untuk buku dan media',
			'fileSources.browserReader' => 'Pembaca Terbuka',
			'fileSources.browserReaderHelp' => 'Membaca dibuka di browser Anda.Jadilah PlezyNG terbuka untuk menyimpan lokasi dan catatan Anda.',
			'fileSources.on' => 'pada',
			'fileSources.advancedSetup' => 'Aplikasi pendaftaran',
			'fileSources.microsoftSignIn' => 'Mendaftar dengan Microsoft',
			'fileSources.zoomIn' => 'Zoom dalam',
			'fileSources.zoomOut' => 'Zoom keluar',
			'fileSources.fitPage' => 'Halaman yang sesuai',
			'fileSources.fitWidth' => 'Berkelanjutan',
			'fileSources.actualSize' => 'Ukuran saat ini',
			'fileSources.goToPage' => 'Pergi ke halaman',
			'fileSources.goToSection' => 'Pergi ke bab',
			'fileSources.pageRange' => ({required Object count}) => 'Masukkan nomor dari 1 ke ${count}',
			'fileSources.pageLayout' => 'Layout halaman',
			'fileSources.automatic' => 'otomatis',
			'fileSources.singlePage' => 'Satu halaman',
			'fileSources.twoPages' => '2 Halaman',
			'fileSources.readingDirection' => 'Membaca arah',
			'fileSources.leftToRight' => 'ke kiri ke kanan',
			'fileSources.rightToLeft' => 'Kanan ke kiri',
			'fileSources.letterSpacing' => 'Surat yang Spasial',
			'fileSources.wordSpacing' => 'Kata ruang',
			'fileSources.readerControlsHelp' => 'Rentangkan dua jari atau gunakan kontrol zoom untuk memperbesar halaman. Seret untuk menggeser halaman. Ctrl/⌘ dengan + atau − mengubah zoom; Ctrl/⌘ dengan 0 meresetnya. Page Up dan Page Down membalik halaman.',
			'fileSources.imagePage' => 'Komik halaman',
			'fileSources.resetReader' => 'Reset preferensi bacaan',
			'fileSources.zoom' => 'Penutup',
			'fileSources.useFiles' => 'Menggunakan file dan buku',
			'fileSources.cancelScan' => 'Batalkan scan',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Batas unduhan offline',
			'fileSources.offlineQuotaHelp' => 'Tetapkan ruang maksimum yang digunakan oleh salinan offline, file terimpor, dan muat turun. Mengurangi batas tidak menghapus salinan sedia ada.',
			'fileSources.offlineStorageUsage' => 'Penyimpanan Offline',
			'fileSources.reservedStorage' => 'disimpan',
			_ => null,
		} ?? switch (path) {
			'fileSources.downloadQueue' => 'Mengunduh Queue',
			'fileSources.downloadRunning' => 'Download',
			'fileSources.downloadQueued' => 'Menunggu',
			'fileSources.downloadPaused' => 'beristirahat',
			'fileSources.downloadFailed' => 'Keperluan Retri',
			'fileSources.importing' => 'Imporsi',
			'fileSources.importInterrupted' => 'Import terputus · menghapus untuk jelas',
			'fileSources.errorQuotaExceeded' => 'Meningkatkan batas atau menghapus salinan yang dimuat turun.',
			'fileSources.errorStorageLow' => 'Tidak ada penyimpanan perangkat gratis yang cukup untuk mempertahankan reserve yang dilindungi.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG tidak dapat memeriksa penyimpanan perangkat gratis, jadi penulisan dihentikan.',
			'fileSources.removeDownloadJob' => 'Menghapus download',
			'fileSources.downloadAlreadyComplete' => 'Download ini selesai sebelum dapat dihapus. item sekarang tersedia offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Menghapus download ini dan menyingkirkan data yang diunduh secara parsial? posisi dan catatan Anda akan tetap.',
			'lending.title' => 'Perpustakaan Publik',
			'lending.add' => 'Tambahkan perpustakaan',
			'lending.other' => 'Perpustakaan lain',
			'lending.libraryName' => 'Nama perpustakaan',
			'lending.libraryUrl' => 'Situs Perpustakaan',
			'lending.libraryUrlHint' => 'Gunakan katalog perpustakaan atau halaman masuknya.',
			'lending.intro' => 'Pinjam dari perpustakaan Anda.Tahan buku Anda dekat.',
			'lending.handoff' => 'Masuk, pinjam, dan baca dengan aman melalui layanan perpustakaan Anda sendiri.',
			'lending.openService' => 'Perpustakaan Terbuka',
			'lending.findLibrary' => 'Temukan perpustakaan',
			'lending.search' => 'Mencari buku dan penulis',
			'lending.catalogue' => 'Katalog',
			'lending.loans' => 'Pinjaman',
			'lending.holds' => 'Reservasi',
			'lending.signIn' => 'Mendaftar dengan perpustakaan Anda',
			'lending.waiting' => 'Selesaikan pendaftaran di browser Anda, kemudian kembali ke sini.',
			'lending.cancel' => 'Batal',
			'lending.disconnect' => 'Menghapus perpustakaan',
			'lending.disconnectMessage' => 'Hapus perpustakaan ini dari profil ini? Pinjaman dan reservasi Anda tetap tersimpan di perpustakaan.',
			'lending.getBook' => 'Dapatkan Buku',
			'lending.checkAvailability' => 'Periksa ketersediaan',
			'lending.available' => 'tersedia untuk pinjaman',
			'lending.unavailable' => 'Saat ini tidak tersedia',
			'lending.borrow' => 'Pinjam',
			'lending.placeHold' => 'Buat reservasi',
			'lending.returnBook' => 'Kembali Cepat',
			'lending.cancelHold' => 'Batalkan reservasi',
			'lending.confirmBorrow' => 'Apakah Anda meminjam judul ini dari perpustakaan Anda?',
			'lending.confirmReturn' => 'Kembalikan judul ini sekarang? Anda mungkin perlu meminjamnya lagi untuk melanjutkan.',
			'lending.confirmCancelHold' => 'Batalkan reservasi Anda untuk judul ini?',
			'lending.email' => 'Pastikan pemberitahuan email',
			'lending.due' => ({required Object date}) => 'Batas pengembalian: ${date}',
			'lending.queue' => ({required Object position}) => 'Posisi ${position} dalam baris',
			'lending.empty' => 'Belum ada judul di sini.',
			'lending.openLibraryNote' => 'Temukan katalog Open Library. opsi bacaan dan pinjaman ditampilkan di halaman setiap judul.',
			'lending.more' => 'Layar Lebih',
			'lending.gateway' => 'Perpustakaan Servis',
			'lending.gatewayHint' => 'Disediakan oleh perpustakaan Anda atau administrator PlezyNG.',
			'lending.advanced' => 'Integrasi perpustakaan',
			'lending.loadLibraries' => 'Pilih perpustakaan Anda',
			'lending.expired' => 'Pinjaman ini sudah habis.',
			'lending.updated' => 'Perpustakaan yang diperbarui',
			'lending.continueService' => 'Terus di Layanan',
			'lending.comingSoon' => 'In-app pinjaman · Datang segera',
			'lending.comingSoonDescription' => 'Anda dapat menggunakan perpustakaan Anda di Libby saat kami selesai menghubungkannya.',
			'lending.suspendHold' => 'Tangguhkan reservasi',
			'lending.resumeHold' => 'Lanjutkan reservasi',
			'lending.suspendMessage' => 'Pertahankan posisi Anda dalam antrean dan biarkan pembaca berikutnya meminjam salinan ini? Anda dapat melanjutkan reservasi nanti.',
			'lending.resumeMessage' => 'Lanjutkan reservasi ini agar perpustakaan dapat menawarkan salinan berikutnya yang tersedia?',
			'lending.editEmail' => 'Perubahan email pemberitahuan',
			'audiobook.syncTitle' => 'Membaca & Mendengarkan Sync',
			'audiobook.syncHelp' => 'Tetap membaca posisi, mendengarkan posisi, status penyelesaian, buku catatan dan catatan di seluruh perangkat Anda. Pilih akun penyimpanan yang disertakan dan gunakan kode sinkron yang sama pada setiap perangkat. Membaca dan mendengarkan tetap terpisah.',
			'audiobook.addSyncSource' => 'Tambah Google Drive, OneDrive, Dropbox, WebDAV atau S3 ke File & Buku terlebih dahulu.',
			'audiobook.syncDestination' => 'Sinkronisasi akun penyimpanan',
			'audiobook.syncFolder' => 'Sinkron folder atau prefix',
			'audiobook.syncFolderHelp' => 'Gunakan folder terpisah yang ada di dalam sumber WebDAV Anda, atau prefix S3 khusus. file buku tidak pernah diubah.',
			'audiobook.syncCode' => 'Kode Sinkronisasi',
			'audiobook.syncCodeHelp' => 'Buat kode pada perangkat pertama Anda, kemudian masukkan kode itu pada perangkat lain Anda. simpan salinan pribadi: itu adalah kunci untuk status enkripsi Anda. Gunakan kode yang berbeda untuk setiap orang.',
			'audiobook.showCode' => 'Menampilkan atau menyembunyikan kode sink',
			'audiobook.newSyncCode' => 'Mencipta kode sink baru',
			'audiobook.saveSync' => 'Simpan dan Sync',
			'audiobook.disableSync' => 'Hentikan Sync pada perangkat ini',
			'audiobook.syncSourceDisconnect' => 'Menghapus sumber ini akan mematikan membaca dan mendengarkan sync di sini. file sync tersulit akan tetap di penyedia.',
			'audiobook.syncReconnect' => 'Menghubungkan kembali akun penyimpanan',
			'audiobook.lastSynced' => ({required Object time}) => 'Terakhir disinkronkan di ${time}',
			'audiobook.syncPrivacy' => 'Hanya kemajuan dan catatan yang disulitkan disimpan. file audio dan ebook, token akun dan kata sandi tidak dimuat naik. Google Drive dan OneDrive menggunakan penyimpanan aplikasi; Dropbox menggunakan PlezyNG Sync. Membolehkan penyegerakan dapat meminta akses penulisan tambahan. Sementara diaktifkan, tujuan ini memiliki penyegerakan kemajuan; kemajuan server tetap terpisah. Mengalihkan penyegerakan mengekalkan sejarah lokal dan keadaan remote.',
			'audiobook.syncConflicts' => 'Pilih tempat untuk kembali',
			'audiobook.conflictHelp' => 'Perubahan-perubahan ini dilakukan secara independen. pilih posisi atau bookmark versi untuk tetap. timestamp kemudian atau peratusan yang lebih tinggi tidak secara otomatis menang.',
			'audiobook.syncDevice' => ({required Object device}) => 'Perangkat ${device}',
			'audiobook.syncUnknownDevice' => 'peralatan yang tidak diketahui',
			'audiobook.deletedBookmark' => 'Bookmark yang dihapus',
			'audiobook.finished' => 'selesai',
			'audiobook.readingPosition' => ({required Object percent}) => 'Membaca · ${percent}%',
			'audiobook.chapterTimeline' => 'Bab Kemajuan',
			'audiobook.bookTimeline' => 'Buku Lengkap Kemajuan',
			'audiobook.bookRemaining' => ({required Object time}) => 'Waktu yang tersisa dalam buku ini: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Waktu yang tersisa dalam bab ini: ${time}',
			'audiobook.unknownRemaining' => 'Total waktu tersedia sebagai bagian yang dimainkan',
			'audiobook.undoSeek' => 'yang terakhir dicari',
			'audiobook.customSpeed' => 'Kecepatan playback yang disesuaikan',
			'audiobook.speedHelp' => 'Pilih kecepatan dari 0.25× hingga 4×.',
			'audiobook.apply' => 'Mengaplikasikan',
			'audiobook.customSleep' => 'Waktu Tidur Custom',
			'audiobook.sleepMinutes' => '1 menit (1 – 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Berhenti setelah ${count} bab',
			'audiobook.extendSleep' => 'Tambahkan 5 menit',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Waktu Tidur: ${time}',
			'audiobook.useDefaults' => 'Gunakan kontrol pendengaran ini untuk buku baru',
			'audiobook.librarySort' => 'Berbagai Buku',
			'audiobook.sortTitle' => 'Judul',
			'audiobook.sortAuthor' => 'Penulis',
			'audiobook.sortNarrator' => 'narator',
			'audiobook.sortSeries' => 'Serangkaian perintah',
			'audiobook.sortRecent' => 'Baru-baru ini dibuka',
			'audiobook.statusFilter' => 'Status bacaan',
			'audiobook.statusAll' => 'Semua buku',
			'audiobook.statusNew' => 'Tidak dimulai',
			'audiobook.statusProgress' => 'dalam kemajuan',
			'audiobook.statusFinished' => 'selesai',
			'audiobook.goToTime' => 'Pergi ke Waktu',
			'audiobook.timeHelp' => 'Waktu: menit: detik, atau menit: detik',
			'audiobook.recoveryHelp' => 'Ekspor salinan yang disulitkan baru-baru ini sebelum memindahkan atau memperbaiki data sink. Import bergabung dengan keadaan saat ini; mereka tidak pernah mengganti sejarah sink lokal.',
			'audiobook.recoveryExport' => 'Mengekspor file pemulihan yang disulitkan',
			'audiobook.recoveryImport' => 'Mengimport file pemulihan yang disulitkan',
			'audiobook.recoveryImportConfirm' => 'Menggabungkan file pemulihan yang disulitkan ini dengan posisi bacaan dan catatan saat ini? sejarah yang ada akan disimpan. perpustakaan berbagi dan ID item tidak termasuk; menetapkan ID yang sepadan pada setiap perangkat sebelum mengimpor.',
			'audiobook.recoveryExported' => 'File pemulihan yang disulitkan disimpan.',
			'audiobook.recoveryImported' => 'Data pemulihan digabungkan.',
			'sourceSetup.savedCertificate' => 'Sertifikat server tersimpan',
			'sourceSetup.nfsEndpointInvalid' => 'Masukkan URL NFS, misalnya nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Tidak ada server DLNA yang ditemukan. Masukkan URL deskripsi perangkat secara manual.',
			'sourceSetup.dlnaServers' => 'Server media DLNA',
			'sourceSetup.dlnaUnavailable' => 'Penemuan DLNA tidak tersedia di jaringan ini. Masukkan URL deskripsi perangkat secara manual.',
			'sourceSetup.dlnaSearching' => 'Mencari server DLNA di jaringan lokal',
			'sourceSetup.networkSearching' => 'Mencari di jaringan lokal…',
			'sourceSetup.dlnaDiscover' => 'Temukan server DLNA',
			'sourceSetup.dlnaHelp' => 'Penemuan bergantung pada multicast jaringan lokal. Jika tidak ada server yang muncul, masukkan URL deskripsi perangkatnya di atas.',
			'sourceSetup.dlnaRoot' => 'ID objek DLNA; kosongkan untuk menggunakan akar perangkat.',
			'sourceSetup.passwordOrKey' => 'Masukkan kata sandi atau tambahkan kunci privat di bawah.',
			'sourceSetup.sshFingerprint' => 'Sidik jari SHA256 kunci host SSH',
			'sourceSetup.sshFingerprintHelp' => 'Verifikasi dengan administrator server. Di server, jalankan ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub dan gunakan nilai SHA256-nya.',
			'sourceSetup.sshFingerprintKeep' => 'Kosongkan untuk mempertahankan sidik jari yang disematkan saat ini, atau masukkan sidik jari server yang baru.',
			'sourceSetup.sshAuthentication' => 'Autentikasi SSH dengan kunci publik',
			'sourceSetup.sshAuthenticationHelp' => 'Opsional; autentikasi kata sandi juga didukung.',
			'sourceSetup.privateKey' => 'Kunci privat (format PEM atau OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Frasa sandi kunci privat',
			'sourceSetup.nfsMountPort' => 'Port TCP layanan mount NFS',
			'sourceSetup.nfsMountPortHelp' => 'Bawaan: 20048',
			'sourceSetup.nfsUserId' => 'ID pengguna NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Bawaan: 1000. Gunakan ID yang diizinkan oleh ekspor NFS di NAS.',
			'sourceSetup.nfsGroupId' => 'ID grup NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Bawaan: 1000. Gunakan ID grup yang diizinkan oleh ekspor NFS di NAS.',
			'sourceSetup.nfsEncryption' => 'Wajibkan NFS terenkripsi (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Wajibkan TLS 1.3 untuk NFS dan layanan mount. Jika NAS tidak mendukungnya, koneksi ditolak.',
			'sourceSetup.nfsTrustCertificate' => 'CA NFS khusus atau sertifikat server (PEM, opsional)',
			'sourceSetup.nfsTrustHelp' => 'Kosongkan untuk sertifikat yang dipercaya perangkat ini. Jika perlu, tambahkan sertifikat CA privat atau sertifikat server yang ditandatangani sendiri; namanya harus cocok dengan host pada URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Gunakan sertifikat CA atau server dalam format PEM. Jangan sertakan kunci privat.',
			'sourceSetup.addTrustCertificate' => 'Tambahkan sertifikat kepercayaan khusus',
			'sourceSetup.replaceTrustCertificate' => 'Ganti sertifikat khusus yang tersimpan',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS menggunakan port NFS dan layanan mount biasa serta memerlukan dukungan RFC 9289 pada NAS. TLS 1.3 wajib digunakan. Nama host atau IP harus cocok dengan sertifikat. AUTH_SYS UID/GID tetap berlaku di dalam saluran terenkripsi.',
			'sourceSetup.clientCertificate' => 'Sertifikat klien (opsional)',
			'sourceSetup.clientCertificateHelp' => 'Memungkinkan NAS mengautentikasi klien ini; ID AUTH_SYS tetap bergantung pada kebijakan ekspor NFS di NAS.',
			'sourceSetup.savedIdentity' => 'Identitas klien yang tersimpan akan digunakan.',
			'sourceSetup.replaceIdentity' => 'Ganti identitas klien yang tersimpan',
			'sourceSetup.chooseIdentity' => 'Pilih identitas klien PKCS#12',
			'sourceSetup.identityPassphrase' => 'Frasa sandi identitas klien',
			'sourceSetup.identityPassphraseHelp' => 'Kosongkan jika file tidak memiliki frasa sandi.',
			'sourceSetup.removeIdentity' => 'Hapus identitas klien yang tersimpan',
			'sourceSetup.identityStorageHelp' => 'Identitas klien disimpan di penyimpanan kredensial sumber yang terenkripsi. Jangan ubah bagian ini untuk mempertahankan identitas yang tersimpan.',
			'sourceSetup.nfsLimitations' => 'NFSv3 hanya-baca melalui TCP. Tanpa RPC-with-TLS, lalu lintas NFS tidak terenkripsi. NAS harus mengizinkan ID AUTH_SYS yang dipilih dan port klien tanpa hak istimewa (sering disebut opsi ekspor “insecure”). NFSv4 dan UDP tidak didukung.',
			'sourceSetup.nfsSetupHelp' => 'Bantuan pengaturan NFS',
			'sourceSetup.nfsSetupHint' => 'Periksa pengaturan ini jika koneksi tidak dapat dibuka.',
			'sourceSetup.nfsSetupDetails' => 'Gunakan ekspor NFSv3 melalui TCP. Jika enkripsi diwajibkan, layanan NFS dan mount harus sama-sama mendukung RPC-with-TLS. Kosongkan sertifikat khusus untuk sertifikat server yang dipercaya perangkat ini, atau tambahkan sertifikat CA NAS atau sertifikat yang ditandatangani sendiri. Nama pada sertifikat harus cocok dengan host titik akhir. Jika NAS meminta autentikasi TLS dua arah, tambahkan identitas klien PKCS#12-nya. Terakhir, pastikan ekspor mengizinkan AUTH_SYS UID/GID yang dikonfigurasi dan kebijakan port klien.',
			'sourceSetup.ftpHelp' => 'FTP menggunakan mode pasif. Gunakan ftp:// untuk FTP tanpa enkripsi, ftpes:// untuk TLS eksplisit, atau ftps:// untuk TLS (implisit pada port 990; eksplisit pada port lainnya).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Pencarian subtitel opsional untuk video mandiri.',
			'sourceSetup.apiKey' => 'Kunci API',
			'sourceSetup.optionalUsername' => 'Nama pengguna akun (opsional)',
			'sourceSetup.optionalPassword' => 'Kata sandi akun (opsional)',
			'sourceSetup.subtitlePrivacy' => 'Dapatkan kunci API dari opensubtitles.com. Pencarian mengirim judul video dan ID IMDb/TMDB yang tersedia, tidak pernah mengirim file video. Kunci dan kredensial akun opsional dienkripsi bersama sumber ini.',
			'sourceSetup.automaticMetadata' => 'Metadata video daring otomatis',
			'sourceSetup.metadataPrivacy' => 'Hanya mengirim judul/tahun dari nama file dan nomor episode atau ID NFO, tidak pernah mengirim media atau kredensial. Kolom NFO tetap menjadi acuan utama.',
			'sourceSetup.nfsEncryptionFailure' => 'Untuk NFS terenkripsi, periksa dukungan RFC 9289 dan TLS 1.3 pada kedua layanan NAS, nama sertifikat, serta UID/GID ekspor. PlezyNG tidak akan mencoba ulang koneksi ini tanpa enkripsi.',
			'sourceSetup.sourceConnecting' => 'Menghubungkan ke sumber',
			'sourceSetup.metadataSearchPrivacy' => 'Pencarian judul ini dikirim ke Trakt. Yang dikirim adalah judul yang Anda masukkan, bukan video atau kredensial sumber.',
			'sourceSetup.chooseMatch' => 'Pilih kecocokan',
			'sourceSetup.metadataMatchHelp' => 'Periksa judul dan tahun sebelum memilih. Trakt menerima judul pencarian; video tetap berada di sumbernya.',
			'sourceSetup.metadataNoMatches' => 'Tidak ditemukan judul yang cocok secara daring. Coba judul lain.',
			'sourceSetup.metadataSearch' => 'Cari metadata daring',
			'sourceSetup.metadataLoading' => 'Mencari detail film dan acara TV secara daring…',
			'sourceSetup.metadataFromTrakt' => 'Metadata daring dari Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Tidak ditemukan kecocokan judul otomatis. Cari judulnya untuk memilih kecocokan.',
			'sourceSetup.metadataFailed' => 'Metadata daring tidak dapat dimuat. Pemutaran dan detail lokal tetap tersedia.',
			'sourceSetup.videoDetailsLoading' => 'Memuat detail video',
			'sourceSetup.subtitleKeyRequired' => 'Kunci API OpenSubtitles diperlukan',
			'sourceSetup.subtitleKeyHelp' => 'Edit sumber file ini dan tambahkan kunci API OpenSubtitles di pengaturan subtitel opsionalnya.',
			'sourceSetup.subtitleSearchFailed' => 'Pencarian subtitel gagal. Periksa kunci API, koneksi, dan akses layanan.',
			'sourceSetup.subtitleApplyFailed' => 'Subtitel ini tidak dapat diunduh atau diterapkan. Periksa koneksi dan coba hasil lain.',
			'sourceSetup.subtitleSearch' => 'Cari di OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'Pencarian menggunakan judul dan ID IMDb/TMDB yang tersedia. File video tetap berada di sumbernya. Periksa bahasa, penanda subtitel paksa atau untuk penyandang gangguan pendengaran, dan nilai sebelum memilih.',
			'sourceSetup.movieOrShow' => 'Film atau acara TV',
			'sourceSetup.subtitleTitleHint' => 'Masukkan judul untuk mempersempit hasil',
			'sourceSetup.subtitleLanguage' => 'Bahasa subtitel',
			'sourceSetup.subtitleSearching' => 'Mencari di OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Tidak ditemukan subtitel yang cocok. Coba judul atau bahasa lain.',
			'sourceSetup.downloadSubtitle' => 'Unduh subtitel',
			'sourceSetup.subtitle' => 'Subtitel',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS diperlukan',
			'sourceSetup.nfsUnencrypted' => 'NFS tanpa enkripsi',
			'sourceSetup.tlsEncrypted' => 'Terenkripsi dengan TLS',
			'sourceSetup.ftpPlain' => 'FTP tanpa enkripsi',
			'sourceSetup.sshPinned' => 'SSH terenkripsi · kunci host disematkan',
			'sourceSetup.smbEncrypted' => 'Enkripsi SMB3 aktif',
			'sourceSetup.smbUnencrypted' => 'Enkripsi SMB3 nonaktif',
			'sourceSetup.httpUnencrypted' => 'HTTP tanpa enkripsi transport',
			'sourceSetup.checkEndpointSecurity' => 'Periksa keamanan titik akhir',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} wajib diisi.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Masukkan ${label} dari ${min} hingga ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Ganti ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Identitas klien terpilih: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Nilai ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Mengunduh subtitel: ${title}',
			'sourceSetup.sharedEntryPair' => 'Berpasangan item ini',
			'sourceSetup.sharedEntryPairHelp' => 'Masukkan ID yang sama untuk item ini pada setiap perangkat. Gunakan pengidentifikasi perkongsian stabil atau buat satu dan salin ke item yang sesuai. Kemajuan hanya berpasangan ketika jenis file edisi, ukuran, dan pesanan sepadan. Blank menghapus peta ini.',
			'sourceSetup.sharedEntryId' => 'Identifikasi item',
			'sourceSetup.generateSharedEntryId' => 'Identifikasi item yang dibagikan',
			'sourceSetup.sharedLibraryId' => 'ID Perpustakaan Berkongsi (optional)',
			'sourceSetup.sharedLibraryHelp' => 'Gunakan ID yang sama pada perangkat yang membuka perpustakaan yang sama.ID publik ini membantu membawa kemajuan membaca dan catatan melalui koneksi sumber yang berbeda; itu bukan kata sandi.',
			'sourceSetup.sharedLibraryInvalid' => 'Gunakan 8-100 huruf, angka, titik, subscores atau hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Menghasilkan ID perpustakaan yang dikongsi',
			'sourceSetup.nfsReadAhead' => 'NFS Read-ahead Permintaan',
			'sourceSetup.nfsReadAheadHelp' => 'Lebih banyak pembaca paralel dapat meningkatkan lalu lintas pada NAS atau jaringan yang cepat. gunakan 1 jika server membatasi permintaan serentak.',
			'sourceSetup.nfsReadTest' => 'Mengukur prestasi baca NFS',
			'sourceSetup.nfsReadTestHelp' => 'Membaca hingga 64 MiB dari file terbesar untuk mengukur koneksi NAS ini.',
			'sourceSetup.nfsQualificationResult' => 'NFS membaca pengukuran',
			'sourceSetup.nfsReadBytes' => 'Data yang dibaca',
			'sourceSetup.nfsReadSpeed' => 'Kecepatan yang diukur',
			'sourceSetup.nfsReadRequests' => 'Baca Permintaan',
			'sourceSetup.sharedEntryConflict' => 'ID item yang dikongsi ini sudah dibagi dengan item lain di perpustakaan ini. pilih ID berbeda.',
			'comics.fitHeight' => 'Sesuaikan tinggi',
			'comics.readingMode' => 'Mode baca',
			'comics.paged' => 'Halaman',
			'comics.webtoon' => 'Gulir berkelanjutan',
			'comics.coverAlone' => 'Tampilkan sampul sendiri',
			'comics.splitWide' => 'Bagi halaman lebar',
			'comics.splitWideHelp' => 'Tampilkan setiap bagian secara terpisah sesuai urutan baca. Tampilan dua halaman berdampingan dijeda saat opsi ini aktif.',
			'comics.thumbnails' => 'Thumbnail halaman',
			'comics.controlsHelp' => 'Geser untuk membalik halaman. Ketuk dua kali untuk mengubah penyesuaian. Dalam gulir berkelanjutan, geser vertikal atau gunakan Page Up dan Page Down.',
			'comics.savedForComic' => 'Pengaturan tampilan diingat untuk komik ini dalam profil ini.',
			'comics.readLists' => 'Daftar bacaan',
			'comics.collections' => 'Koleksi',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
			'games.enableDescription' => 'Discover your gaming computers and play with an embedded streaming engine.',
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
			'games.recent' => 'Recently opened',
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
			'games.steamBetaTitle' => 'Steam beta · Pyrowave',
			'games.steamBetaDescription' => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.',
			'games.steamLibrary' => 'Steam library',
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamAppId' => 'Steam App ID',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.steamLibraryHint' => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.',
			_ => null,
		};
	}
}
