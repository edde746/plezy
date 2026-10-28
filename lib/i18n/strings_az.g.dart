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
class TranslationsAz extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAz({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.az,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <az>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsAz _root = this; // ignore: unused_field

	@override 
	TranslationsAz $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAz(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$az app = _Translations$app$az._(_root);
	@override late final _Translations$appIcon$az appIcon = _Translations$appIcon$az._(_root);
	@override late final _Translations$auth$az auth = _Translations$auth$az._(_root);
	@override late final _Translations$common$az common = _Translations$common$az._(_root);
	@override late final _Translations$screens$az screens = _Translations$screens$az._(_root);
	@override late final _Translations$update$az update = _Translations$update$az._(_root);
	@override late final _Translations$settings$az settings = _Translations$settings$az._(_root);
	@override late final _Translations$themeEditor$az themeEditor = _Translations$themeEditor$az._(_root);
	@override late final _Translations$search$az search = _Translations$search$az._(_root);
	@override late final _Translations$hotkeys$az hotkeys = _Translations$hotkeys$az._(_root);
	@override late final _Translations$fileInfo$az fileInfo = _Translations$fileInfo$az._(_root);
	@override late final _Translations$mediaMenu$az mediaMenu = _Translations$mediaMenu$az._(_root);
	@override late final _Translations$rateSheet$az rateSheet = _Translations$rateSheet$az._(_root);
	@override late final _Translations$accessibility$az accessibility = _Translations$accessibility$az._(_root);
	@override late final _Translations$tooltips$az tooltips = _Translations$tooltips$az._(_root);
	@override late final _Translations$audioTracks$az audioTracks = _Translations$audioTracks$az._(_root);
	@override late final _Translations$videoControls$az videoControls = _Translations$videoControls$az._(_root);
	@override late final _Translations$messages$az messages = _Translations$messages$az._(_root);
	@override late final _Translations$subtitlingStyling$az subtitlingStyling = _Translations$subtitlingStyling$az._(_root);
	@override late final _Translations$mpvConfig$az mpvConfig = _Translations$mpvConfig$az._(_root);
	@override late final _Translations$dialog$az dialog = _Translations$dialog$az._(_root);
	@override late final _Translations$profiles$az profiles = _Translations$profiles$az._(_root);
	@override late final _Translations$connections$az connections = _Translations$connections$az._(_root);
	@override late final _Translations$accountPreferences$az accountPreferences = _Translations$accountPreferences$az._(_root);
	@override late final _Translations$discover$az discover = _Translations$discover$az._(_root);
	@override late final _Translations$errors$az errors = _Translations$errors$az._(_root);
	@override late final _Translations$libraries$az libraries = _Translations$libraries$az._(_root);
	@override late final _Translations$about$az about = _Translations$about$az._(_root);
	@override late final _Translations$serverSelection$az serverSelection = _Translations$serverSelection$az._(_root);
	@override late final _Translations$hubDetail$az hubDetail = _Translations$hubDetail$az._(_root);
	@override late final _Translations$logs$az logs = _Translations$logs$az._(_root);
	@override late final _Translations$startup$az startup = _Translations$startup$az._(_root);
	@override late final _Translations$licenses$az licenses = _Translations$licenses$az._(_root);
	@override late final _Translations$navigation$az navigation = _Translations$navigation$az._(_root);
	@override late final _Translations$explore$az explore = _Translations$explore$az._(_root);
	@override late final _Translations$liveTv$az liveTv = _Translations$liveTv$az._(_root);
	@override late final _Translations$collections$az collections = _Translations$collections$az._(_root);
	@override late final _Translations$playlists$az playlists = _Translations$playlists$az._(_root);
	@override late final _Translations$music$az music = _Translations$music$az._(_root);
	@override late final _Translations$watchTogether$az watchTogether = _Translations$watchTogether$az._(_root);
	@override late final _Translations$downloads$az downloads = _Translations$downloads$az._(_root);
	@override late final _Translations$shaders$az shaders = _Translations$shaders$az._(_root);
	@override late final _Translations$companionRemote$az companionRemote = _Translations$companionRemote$az._(_root);
	@override late final _Translations$videoSettings$az videoSettings = _Translations$videoSettings$az._(_root);
	@override late final _Translations$performanceOverlay$az performanceOverlay = _Translations$performanceOverlay$az._(_root);
	@override late final _Translations$externalPlayer$az externalPlayer = _Translations$externalPlayer$az._(_root);
	@override late final _Translations$metadataEdit$az metadataEdit = _Translations$metadataEdit$az._(_root);
	@override late final _Translations$matchScreen$az matchScreen = _Translations$matchScreen$az._(_root);
	@override late final _Translations$serverTasks$az serverTasks = _Translations$serverTasks$az._(_root);
	@override late final _Translations$trakt$az trakt = _Translations$trakt$az._(_root);
	@override late final _Translations$seerr$az seerr = _Translations$seerr$az._(_root);
	@override late final _Translations$services$az services = _Translations$services$az._(_root);
	@override late final _Translations$addServer$az addServer = _Translations$addServer$az._(_root);
	@override late final _Translations$cast$az cast = _Translations$cast$az._(_root);
	@override late final _Translations$automation$az automation = _Translations$automation$az._(_root);
	@override late final _Translations$notifications$az notifications = _Translations$notifications$az._(_root);
	@override late final _Translations$appAccess$az appAccess = _Translations$appAccess$az._(_root);
	@override late final _Translations$detail$az detail = _Translations$detail$az._(_root);
	@override late final _Translations$watchLink$az watchLink = _Translations$watchLink$az._(_root);
	@override late final _Translations$homeLayout$az homeLayout = _Translations$homeLayout$az._(_root);
	@override late final _Translations$platform$az platform = _Translations$platform$az._(_root);
	@override late final _Translations$universalMedia$az universalMedia = _Translations$universalMedia$az._(_root);
	@override late final _Translations$fileSources$az fileSources = _Translations$fileSources$az._(_root);
	@override late final _Translations$lending$az lending = _Translations$lending$az._(_root);
	@override late final _Translations$audiobook$az audiobook = _Translations$audiobook$az._(_root);
	@override late final _Translations$sourceSetup$az sourceSetup = _Translations$sourceSetup$az._(_root);
	@override late final _Translations$comics$az comics = _Translations$comics$az._(_root);
	@override late final _Translations$games$az games = _Translations$games$az._(_root);
	@override late final _Translations$deepLinks$az deepLinks = _Translations$deepLinks$az._(_root);
}

// Path: app
class _Translations$app$az extends Translations$app$en {
	_Translations$app$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$az extends Translations$appIcon$en {
	_Translations$appIcon$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tətbiq ikonu';
	@override String get defaultIcon => 'Defolt';
	@override String get current => 'Cari ikon';
	@override String get locked => 'Ömür boyu qalıb';
	@override String get lockedHint => '7 gün sürən testinizə başlamaq və ya alternativ ikonları kullanmaq üçün PlezyNG ömür boyu kilidini açmaq.';
	@override String get changeFailed => 'Tətbiq ikonu dəyişdirilə bilmədi';
	@override String get launcherHint => 'PlezyNG-dən çıxdıqdan sonra yeni ikon ana ekranınızda görünəcək.';
	@override String get tvLauncherHint => 'PlezyNG-dən çıxdıqdan sonra yeni banner görünəcək. Android TV televizor yenidən başladılana qədər köhnəsini göstərə bilər.';
	@override late final _Translations$appIcon$names$az names = _Translations$appIcon$names$az._(_root);
	@override String get description => '“Müsləhətçi”nin hər bir seçkinin necə göründüğünü göstər.';
}

// Path: auth
class _Translations$auth$az extends Translations$auth$en {
	_Translations$auth$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex ilə daxil ol';
	@override String get showQRCode => 'QR kodu göstər';
	@override String get authenticate => 'Təsdiqlə';
	@override String get authenticationTimeout => 'Təsdiqləmə vaxtı bitdi. Lütfən təzədən cəhd edin.';
	@override String get scanQRToSignIn => 'Daxil olmaq üçün bu QR kodu skan edin';
	@override String get waitingForAuth => 'Təsdiqləmə gözlənilir...\nSəyahətçinizdən (brauzer) daxil olun.';
	@override String get useBrowser => 'Səyahətçini istifadə et';
	@override String get or => 'və ya';
	@override String connectToMediaBrowser({required Object product}) => '${product}-a qoşul';
	@override String get quickConnect => 'Sürətli Qoşulma';
	@override String get useQuickConnect => 'Sürətli Qoşulmanı istifadə et';
	@override String get quickConnectInstructions => 'Jellyfin-də Sürətli Qoşulmanı açın və bu kodu daxil edin.';
	@override String get quickConnectWaiting => 'Təsdiq gözlənilir…';
	@override String get quickConnectCancel => 'Ləğv et';
	@override String get quickConnectExpired => 'Sürətli Qoşulmanın vaxtı bitdi. Təzədən cəhd edin.';
	@override String get localDataRecoveryRequired => 'PlezyNG yerli daxil olma və gözləyən oxutma məlumatlarını təhlükəsiz bərpa edə bilmədi. Lütfən təzədən daxil olun.';
	@override String get pinCheckRejected => 'Plex PIN yoxlaması rədd edildi';
	@override String get connectToDirectPlex => 'Yerel Plex serverinə bağlanın';
}

// Path: common
class _Translations$common$az extends Translations$common$en {
	_Translations$common$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Ləğv et';
	@override String get save => 'Yadda saxla';
	@override String get close => 'Bağla';
	@override String get closeMiniPlayer => 'Mini oyunçı';
	@override String get closeWorkspaceWindow => 'Yakın pencerə';
	@override String get returnToFullView => 'Full View-a qayıtmaq';
	@override String get manageMediaSessions => 'Medya toplantıları';
	@override String get hideMediaSessions => 'Medya toplantıları';
	@override String get mediaSessions => 'Medya toplantıları';
	@override String get mediaSessionsHint => '“Park” onun penceresini gizləyir, amma açılır.Return onu tam görünüşdə açır; yakında bitir.';
	@override String get sessionInWorkspace => 'Çalışma alanında';
	@override String get sessionParked => 'Parkı';
	@override String get sessionFullscreen => 'Full ekran';
	@override String get switchToNextWindow => 'Bir sonraki pencerə qarşılaşır';
	@override String get moveWindow => 'Xatış pencerəsi';
	@override String get finishMovingWindow => 'Moving pencerə bitir';
	@override String get moveWindowHint => 'Bu qapı, bu qapıyı düzəltmək üçün uzun sürətdir.Bu qaplı qapısı da mümkün olur.';
	@override String get movingWindowHelp => 'Movil qapı · Qapı anahtarları ayarlayın · Enter saves · Escape cancles';
	@override String get resizeWindow => 'Xatış pencerəsi';
	@override String get resizeWindowHint => 'Bu manevrı çalın və ya pencerə qayıtmaq üçün silah anahtarlarını kullanın.';
	@override String get workspaceWindowHint => 'Movay kontrolü və ya uzun basın və hareket etmək üçün sürükür.';
	@override String get workspacePaneHint => 'Bu panu seçin ki, ona odaklanmaq üçün. bütün ekran kontrolünü genişletmək üçün kullanın.';
	@override String workspaceWindowLabel({required Object title}) => 'Xəbəri: ${title}';
	@override String get workspaceTitleHint => '“Title bar”ı dəyişmək üçün sürükleyin; genişletmək üçün tam ekran düğmesini kullanın.';
	@override String get moveToSessionTray => 'Üçüncüsü Session Tray';
	@override String get moveToSessionTrayHint => 'Bu oturumu, penceresini görünməyən istifadə edir.';
	@override String get closeSessionHint => 'Bu qapıyı kapatır və oturumu bitir.';
	@override String get sideBySideLayout => '“Layout”dan “Side-by-side layout”a qayıtmaq';
	@override String get floatingWindows => 'Fırtınalı pencerə qapılmaq';
	@override String get clear => 'Təmizlə';
	@override String get reset => 'Sıfırla';
	@override String get later => 'Sonra';
	@override String get submit => 'Göndər';
	@override String get confirm => 'Təsdiqlə';
	@override String get retry => 'Təzədən cəhd et';
	@override String get logout => 'Çıxış et';
	@override String get unknown => 'Məlum deyil';
	@override String get refresh => 'Yenilə';
	@override String get yes => 'Bəli';
	@override String get no => 'Xeyr';
	@override String get delete => 'Sil';
	@override String get edit => 'Düzəliş et';
	@override String get shuffle => 'Qarışdır';
	@override String get addTo => 'Əlavə et...';
	@override String get createNew => 'Yenisini yarat';
	@override String get connect => 'Qoşul';
	@override String get disconnect => 'Əlaqəni kəs';
	@override String get play => 'Oynat';
	@override String get pause => 'Fasilə';
	@override String get resume => 'Davam et';
	@override String get error => 'Xəta';
	@override String get search => 'Axtar';
	@override String get home => 'Ana səhifə';
	@override String get back => 'Geri';
	@override String get settings => 'Tənzimləmələr';
	@override String get mute => 'Səsi söndür';
	@override String get ok => 'Oldu';
	@override String get off => 'Söndürülüb';
	@override String get options => 'Seçimlər';
	@override String seasonNumber({required Object number}) => 'Mövsüm ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Seriya ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Hissə ${number}';
	@override String get reconnect => 'Yenidən qoşul';
	@override String get viewAll => 'Hamısına bax';
	@override String get checkingNetwork => 'Şəbəkə yoxlanılır...';
	@override String get loadingServers => 'Serverlər yüklənir...';
	@override String get connectingToServers => 'Serverlərə qoşulunur...';
	@override String get startingOfflineMode => 'Oflayn rejim başladılır...';
	@override String get loading => 'Yüklənir...';
	@override String get fullscreen => 'Tam ekran';
	@override String get exitFullscreen => 'Tam ekrandan çıx';
	@override String get pressBackAgainToExit => 'Çıxmaq üçün geri düyməsinə bir daha basın';
	@override late final _Translations$common$ratingSource$az ratingSource = _Translations$common$ratingSource$az._(_root);
	@override String get notAvailable => 'Yoxdur';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$az mediaKind = _Translations$common$mediaKind$az._(_root);
}

// Path: screens
class _Translations$screens$az extends Translations$screens$en {
	_Translations$screens$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lisenziyalar';
	@override String get switchProfile => 'Profili dəyiş';
	@override String get subtitleStyling => 'Altyazı tənzimləmələri';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Jurnallar';
}

// Path: update
class _Translations$update$az extends Translations$update$en {
	_Translations$update$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get available => 'Yenilənmə var';
	@override String versionAvailable({required Object version}) => '${version} versiyası əlçatandır';
	@override String currentVersion({required Object version}) => 'Cari: ${version}';
	@override String get skipVersion => 'Bu versiyanı ötür';
	@override String get viewRelease => 'Buraxılışa bax';
	@override String get latestVersion => 'Siz ən son versiyadasınız';
	@override String get checkFailed => 'Yenilənmələr yoxlanıla bilmədi';
}

// Path: settings
class _Translations$settings$az extends Translations$settings$en {
	_Translations$settings$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tənzimləmələr';
	@override String get supportDeveloper => 'PlezyNG-yə dəstək ol';
	@override String get supportDeveloperDescription => 'İnkişafı dəstəkləmək üçün ianə edin';
	@override String get lifetimeAccess => 'PlezyNG Ömür boyu qalıb';
	@override String get language => 'Dil';
	@override String get theme => 'Mövzu';
	@override String get appearance => 'Görünüş';
	@override String get detailPage => 'Detaylı sayfa';
	@override String get themeSongsEnabled => 'Şarkı sözləri';
	@override String get themeSongsEnabledDescription => 'Tədbirlər media ilə tanışırken oyun oynayır.';
	@override String get themeSongVolume => 'Şarkı sözləri';
	@override String get videoPlayback => 'Video oynatma';
	@override String get videoPlaybackDescription => 'Oynatma davranışını tənzimləyin';
	@override String get advanced => 'Təkmilləşdirilmiş';
	@override String get episodePosterMode => 'Seriya poster stili';
	@override String get seriesPoster => 'Serial posteri';
	@override String get seasonPoster => 'Mövsüm posteri';
	@override String get episodeThumbnail => 'Kadr önizləməsi';
	@override String get showHeroSectionDescription => 'Ana səhifədə xüsusi məzmun karuselini göstər';
	@override String get secondsLabel => 'Saniyə';
	@override String get minutesLabel => 'Dəqiqə';
	@override String get secondsShort => 'san';
	@override String get minutesShort => 'dəq';
	@override String durationHint({required Object min, required Object max}) => 'Müddəti daxil edin (${min}-${max})';
	@override String get systemTheme => 'Sistem';
	@override String get lightTheme => 'Açıq';
	@override String get darkTheme => 'Tünd';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Köz';
	@override String get glacierTheme => 'Buzlaq';
	@override String get forestTheme => 'Meşə';
	@override String get plumTheme => 'Gavalı';
	@override String get paperTheme => 'Kağız';
	@override String get libraryDensity => 'Kitabxana sıxlığı';
	@override String get displayScale => 'Ekran miqyası';
	@override String get compact => 'Sıx';
	@override String get comfortable => 'Rəhat';
	@override String get gridSpacing => 'Tor aralığı';
	@override String get gridSpacingTight => 'Sıx';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Geniş';
	@override String get tvCornerSpotlightBackdrop => 'Künc işıqlandırma fonu';
	@override String get tvCornerSpotlightBackdropDescription => 'Arxa fonu ekranı örtmək əvəzinə sağ üst küncdə göstər';
	@override String get viewMode => 'Baxış rejimi';
	@override String get gridView => 'Tor';
	@override String get listView => 'Siyahı';
	@override String get showHeroSection => 'Xüsusi bölməni göstər';
	@override String get showHomeBackdrop => 'Evdə arşiv işləri görmək';
	@override String get showHomeBackdropDescription => 'Evdə böyük art işləri görmək';
	@override String get contentScreensaverEnabled => 'Ekranın içeriği';
	@override String get contentScreensaverEnabledDescription => '“Tüm ekranlı” aparın sonra “Tüm ekranlı” aparın.';
	@override String get contentScreensaverDelay => 'Ekranın başlanmasından sonra';
	@override String get contentScreensaverLibraries => 'Screensaver kütüphanləri';
	@override String get contentScreensaverLibrariesDescription => 'Ekran qoruyucusu üçün təsvirləri hansı kitabxanaların təmin edəcəyini seçin. Heç biri seçilməsə, bütün kitabxanaların təsvirləri istifadə olunur.';
	@override String get contentScreensaverAllLibraries => 'Bütün kütüphanlər';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} seçilmiş kütüphərlər';
	@override String get contentScreensaverNoLibraries => 'Bağlantılı medya kütüphaneleri yoxdur.';
	@override String get contentScreensaverDismissHint => 'Hər bir düğmə və ya xilas etmək üçün tıklayın';
	@override String get newEpisodeNotifications => 'Yeni xəbərlər';
	@override String get newEpisodeNotificationsDescription => 'Yeni bir epizod bir göstərə daxil olduğunda uyarır. Plezy açılsa da kontrol edilir.';
	@override String get continueWatchingRowSize => 'Görüntülər: Sürüntülər boyutu';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} kartları';
	@override String get rowSizeCompact => 'Sıx';
	@override String get rowSizeStandard => 'Standart';
	@override String get rowSizeLarge => 'Böyük';
	@override String get continueWatchingAction => 'İzləməyə davam et əməliyyatı';
	@override String get continueWatchingPlay => 'Oynat';
	@override String get continueWatchingDetails => 'Ətraflı aç';
	@override String get episodeAction => 'Seriya əməliyyatı';
	@override String get episodePlay => 'Oynat';
	@override String get episodeDetails => 'Ətraflı aç';
	@override String get useGlobalHubs => 'Ana səhifə quruluşunu istifadə et';
	@override String get useGlobalHubsDescription => 'Birləşdirilmiş ana səhifə bölmələrini göstər. Əks halda kitabxana tövsiyələrini istifadə edir.';
	@override String get showServerNameOnHubs => 'Bölmələrdə server adını göstər';
	@override String get showServerNameOnHubsDescription => 'Bölmə başlıqlarında həmişə server adlarını göstər.';
	@override String get groupLibrariesByServer => 'Kitabxanaları serverə görə qrupla';
	@override String get groupLibrariesByServerDescription => 'Yan menyu kitabxanalarını hər media serverinin altında qruplaşdır.';
	@override String get alwaysKeepSidebarOpen => 'Yan menyunu həmişə açıq saxla';
	@override String get alwaysKeepSidebarOpenDescription => 'Yan menyu genişlənmiş qalır və məzmun sahəsi buna uyğunlaşır';
	@override String get showUnwatchedCount => 'Baxılmamış sayını göstər';
	@override String get showUnwatchedCountDescription => 'Seriallarda və mövsümlərdə baxılmamış seriya sayını göstər';
	@override String get showWatchedIndicators => 'Baxılmış göstəriciləri göstər';
	@override String get showWatchedIndicatorsDescription => 'Baxılmış kinolarda, seriallarda və seriyalarda quşçuq göstər';
	@override String get showEpisodeNumberOnCards => 'Kartlarda seriya nömrəsini göstər';
	@override String get showEpisodeNumberOnCardsDescription => 'Seriya kartlarında mövsüm və seriya nömrəsini göstər';
	@override String get showSeasonPostersOnTabs => 'Mərhələlərdə mövsüm posterlərini göstər';
	@override String get showSeasonPostersOnTabsDescription => 'Hər mövsümün posterini öz bölməsinin üstündə göstər';
	@override String get tvFullCardLayout => 'Tam TV kartları';
	@override String get tvFullCardLayoutDescription => 'Aktyor adları üstündə olan yalnız şəkil tərkibli TV kartları istifadə et';
	@override String get focusGlow => 'Fokus parıltısı';
	@override String get focusGlowDescription => 'Fokuslanmış kartın ətrafında yumşaq parıltı çək';
	@override String get visualEffects => 'Vizual effektlər';
	@override String get visualEffectsAuto => 'Avtomatik';
	@override String get visualEffectsAutoDescription => 'Zəif cihazlarda effektləri avtomatik olaraq azalt';
	@override String get visualEffectsFull => 'Tam';
	@override String get visualEffectsReduced => 'Azaldılmış';
	@override String get visualEffectsReducedDescription => 'Daha az animasiya və daha aşağı keyfiyyətli şəkillər';
	@override String get hideSpoilers => 'Baxılmamış seriyalar üçün spoylerləri gizlə';
	@override String get hideSpoilersDescription => 'Baxılmamış seriyalar üçün miniatürləri və təsvirləri bulanıqlaşdır';
	@override String get playerBackend => 'Oynadıcı infrastrukturu';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Avadanlıq kod açılması';
	@override String get hardwareDecodingDescription => 'Mümkün olduqda avadanlıq sürətləndirməsini istifadə et';
	@override String get playbackBuffer => 'Oxutma buferi';
	@override String get playbackBufferAuto => 'Avtomatik (tövsiyə olunur)';
	@override String get playbackBufferLarge => 'Böyük';
	@override String get playbackBufferExtraLarge => 'Çox böyük';
	@override String get playbackBufferDescription => 'Qeyri-sabit əlaqələrə qarşı daha çox buferləyir. Bufer ölçüsü ilə də məhdudlaşır.';
	@override String get streamBufferSize => 'Buffer ölçüsü';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Transcodes, sunucuya öz transcode bufferdə durdurulur. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Playback Buffer-i ayarlanırsa, appın memur limitinin yarısına qapılmışdır.';
	@override String get streamBufferMegabytes => 'Megabətlər';
	@override String get defaultQualityTitle => 'Defolt keyfiyyət';
	@override String get cellularQualityTitle => 'Mobil şəbəkədə defolt keyfiyyət';
	@override String get remoteQualityTitle => 'Remote Streaming Qalığı';
	@override String get remoteQualitySameAsDefault => 'Default Qalitəsi';
	@override String get cellularQualitySameAsDefault => 'Defolt keyfiyyətlə eyni';
	@override String get directPlayCoveredQuality => 'Kiçik videoları orijinal keyfiyyətdə oynat';
	@override String get directPlayCoveredQualityDescription => 'Keyfiyyət limitinə uyğun gələn videoları yenidən kodlaşdırmaq əvəzinə birbaşa oynat';
	@override String get videoCodecs => 'Video kodekləri';
	@override String get videoCodecsDescription => 'İşarələnməmiş kodekləri server yenidən kodlaşdırır';
	@override String get videoCodecsAlwaysAccepted => 'Həmişə qəbul edilir';
	@override String get musicQualityTitle => 'Musiqi keyfiyyəti';
	@override String get subtitleStyling => 'Altyazı tənzimləmələri';
	@override String get subtitleStylingDescription => 'Altyazı görünüşünü özünüləşdirin';
	@override String get smallSkipDuration => 'Kiçik ötürmə müddəti';
	@override String get largeSkipDuration => 'Böyük ötürmə müddəti';
	@override String get rewindOnResume => 'Davam edərkən geri sar';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} saniyə',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} saniyə',
	);
	@override String get defaultSleepTimer => 'Defolt yuxu taymeri';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} dəqiqə',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} dəqiqə',
	);
	@override String get rememberTrackSelections => 'Hər film/serial üçün səs/altyazı seçimlərini xatırla';
	@override String get chooseTracksBeforePlayback => 'Video və video oyunları oynamaqdan əvvəl seçin';
	@override String get chooseTracksBeforePlaybackDescription => 'Videoya başlanmadan əvvəl kaynak audio və subtitle izləri seçin.';
	@override String get alwaysShowSubtitlesOnDevice => 'Bu cihazda hər zaman subtitrlər göstərilir.';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Serverin seçilmə qalıbı olmadığında, bir yol yerə seçin.Bu, sunucu tercihini heç vaxt dəyişməz.';
	@override String get autoDownloadPreferredSubtitle => 'FETCH-ın preferred-language subtitlesləri eksikdir';
	@override String get autoDownloadPreferredSubtitleDescription => 'İsteyiniz ki, bir yerdə bir yerdə yerdə bir subtitr seçin. bir yerdə yoksa, bir yerə destek olunca bir yerdə tutmaq istə.';
	@override String get rememberTrackSelectionsDescription => 'Hər məzmun üçün səs və altyazı seçimlərini yadda saxla';
	@override String get rememberTrackSelectionsBackendRule => 'Plex hər seçimi serverdə fayl üzrə saxlayır; Jellyfin həmçinin hesabın "Seçimləri xatırla" funksiyasını aktivləşdirir; Emby dəstəklənmir';
	@override String get followServerTrackSelections => 'Hər epizod üçün serverin trek seçimlərini istifadə et';
	@override String get followServerTrackSelectionsDescription => 'Epizod dəyişəndə cari seçimi köçürmək əvəzinə serverdə seçilmiş səs və altyazını tətbiq et';
	@override String get resumeMusicOnLaunch => 'Musiqi sessiyasını yadda saxla';
	@override String get resumeMusicOnLaunchDescription => 'Tətbiq açılanda son mahnını dayandırıldığı yerdə fasilədə aç';
	@override String get showChapterMarkersOnTimeline => 'Zaman çubuğunda hissə işarələrini göstər';
	@override String get showChapterMarkersOnTimelineDescription => 'Zaman çubuğunu hissə sərhədlərinə böl';
	@override String get specialsOrdering => 'Xüsusi bölmələr epizod sırasına görə';
	@override String get specialsOrderingDescription => 'Xüsusi bölmələrin serialın izləmə sırasındakı yeri';
	@override String get specialsOrderingServer => 'Server sırasını izlə';
	@override String get specialsOrderingAirDate => 'Yayım tarixinə görə qarışdır';
	@override String get specialsOrderingLast => 'Adi mövsümlərdən sonra';
	@override String get clickVideoTogglesPlayback => 'Oynat/fasilə üçün videoya toxun';
	@override String get clickVideoTogglesPlaybackDescription => 'İdarəetməni göstərmək əvəzinə oynatmaq/fasilə etmək üçün videoya toxun.';
	@override String get videoPlayerControls => 'Video oynadıcı idarəetmələri';
	@override String get keyboardShortcuts => 'Klaviatura qısayolları';
	@override String get keyboardShortcutsDescription => 'Klaviatura qısayollarını özünüləşdirin';
	@override String get videoPlayerNavigation => 'Video oynadıcı naviqasiyası';
	@override String get videoPlayerNavigationDescription => 'Oynadıcı idarəetmələrində hərəkət etmək üçün ox düymələrini istifadə edin';
	@override String get watchTogetherRelay => 'Birlikdə İzlə relesi';
	@override String get watchTogetherRelayDescription => 'Öz relenizi təyin etməsəniz, ictimai Open Watch Party releləri istifadə olunur';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Düzgün HTTP və ya HTTPS rele ünvanı daxil edin.';
	@override String get crashReporting => 'Xəta hesabatı';
	@override String get crashReportingDescription => 'Tətbiqi təkmilləşdirməyə kömək etmək üçün xəta hesabatları göndərin';
	@override String get debugLogging => 'Xəta saxlama jurnalı';
	@override String get debugLoggingDescription => 'Problemləri həll etmək üçün ətraflı jurnal qeydiyyatını aktivləşdirin';
	@override String get viewLogs => 'Jurnallara bax';
	@override String get viewLogsDescription => 'Tətbiq jurnallarına baxın';
	@override String get clearImageCache => 'Şəkil keşini təmizlə';
	@override String get clearImageCacheDescription => 'Keşlənmiş şəkilləri təmizləyir. Yenidən yüklənənədək şəkillər daha yavaş yüklənə bilər.';
	@override String get clearImageCacheSuccess => 'Şəkil keşi uğurla təmizləndi';
	@override String get resetSettings => 'Tənzimləmələri sıfırla';
	@override String get resetSettingsDescription => 'Defolt tənzimləmələri bərpa edin. Bu əməliyyat geri qaytarıla bilməz.';
	@override String get resetSettingsSuccess => 'Tənzimləmələr uğurla sıfırlandı';
	@override String get backup => 'Ehtiyat nüsxə';
	@override String get exportSettings => 'Tənzimləmələri ixrac et';
	@override String get exportSettingsDescription => 'Seçimlərinizi fayla yadda saxlayın';
	@override String get exportSettingsSuccess => 'Tənzimləmələr ixrac edildi';
	@override String get importSettings => 'Tənzimləmələri idxal et';
	@override String get importSettingsDescription => 'Seçimləri fayldan bərpa edin';
	@override String get importSettingsConfirm => 'Bu cari tənzimləmələrinizin üzərinə yazacaq. Davam edilsin?';
	@override String get importSettingsSuccess => 'Tənzimləmələr idxal edildi';
	@override String get importSettingsInvalidFile => 'Bu fayl düzgün PlezyNG tənzimləmələr faylı deyil';
	@override String get importSettingsNoUser => 'Tənzimləmələri idxal etməzdən əvvəl daxil olun';
	@override String get cloudBackup => 'Qıraqlı Qıraqlı';
	@override String get cloudBackupDescription => 'Xatırılan ayarları WebDAV final noktasına HTTPS üzerinden yedekə.Server bağlantıları və xəttialları bu cihazda qalır.';
	@override String get cloudBackupUrl => 'WebDAV JSON fil URL';
	@override String get cloudBackupUsername => 'İstifadəçi adı';
	@override String get cloudBackupPassword => 'Şifrə';
	@override String get cloudBackupSaved => 'Cloud backup destinasyonu qurulmuşdur';
	@override String get cloudBackupNow => 'Şimdilik geri';
	@override String get cloudBackupComplete => 'Backup yüklənlər';
	@override String get cloudBackupRestore => 'Backup qayıtmaq';
	@override String get cloudBackupRestoreConfirm => 'Bu, bu cihazda uyumlu mobil ayarların yerini alacaq.';
	@override String get cloudBackupRestored => '“Cloud Backup”dan qayıtılmış ayarlar';
	@override String get shortcutsReset => 'Qısayollar defolt vəziyyətə sıfırlandı';
	@override String get resetShortcutsConfirm => 'Bu, xüsusi qısayollarınızı defolt qısayollarla əvəz edəcək. Davam edilsin?';
	@override String get about => 'Haqqında';
	@override String get aboutDescription => 'Tətbiq məlumatı və lisenziyalar';
	@override String get updates => 'Yenilənmələr';
	@override String get updateAvailable => 'Yenilənmə var';
	@override String get checkForUpdates => 'Yenilənmələri yoxla';
	@override String get autoCheckUpdatesOnStartup => 'Açılışda yenilənmələri avtomatik yoxla';
	@override String get autoCheckUpdatesOnStartupDescription => 'Açılışda yenilənmə olduqda xəbərdar et';
	@override String get validationErrorEnterNumber => 'Lütfən düzgün rəqəm daxil edin';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Müddət ${min} və ${max} ${unit} arasında olmalıdır';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Qısayol artıq ${action} üçün təyin edilib';
	@override String shortcutUpdated({required Object action}) => '${action} üçün qısayol yeniləndi';
	@override String get saveFailed => 'Dəyişikliklər yadda saxlanıla bilmədi. Təzədən cəhd edin.';
	@override String get autoPlayAndSkip => 'Avtomatik oynat və ötür';
	@override String get autoPlayNextEpisode => 'Növbəti seriyanı avtomatik oynat';
	@override String get autoPlayNextEpisodeDescription => 'Bir seriya bitdikdə növbətisini avtomatik başlat';
	@override String get shuffleStartsFromBeginning => 'Qarışdırma əvvəldən başlayır';
	@override String get shuffleStartsFromBeginningDescription => 'Qarışdırarkən hər seriyanı davam etdirmək əvəzinə əvvəldən başlat';
	@override String get plexCinemaPreRoll => 'Cinematografya serveri';
	@override String get plexCinemaPreRollDescription => 'Filmin başlatılmasından əvvəl Plex və ya Jellyfin və Emby introsları oynayın.';
	@override String get playNextCountdown => 'Növbəti seriya geri sayımı';
	@override String get playNextCountdownImmediate => 'Dərhal oynat';
	@override String get skipIntroMode => 'Girişi ötür';
	@override String get skipIntroModeOffDescription => 'Girişləri ötürmə düyməsi olmadan normal oynat';
	@override String get skipIntroModeButtonDescription => 'Giriş başlayanda ötürmə düyməsini göstər';
	@override String get skipIntroModeAutoDescription => 'Girişləri aşağıdakı ləngimədən sonra avtomatik ötür';
	@override String get skipCreditsMode => 'Titrləri ötür';
	@override String get skipCreditsModeOffDescription => 'Titrləri ötürmə düyməsi olmadan normal oynat';
	@override String get skipCreditsModeButtonDescription => 'Titrlər başlayanda ötürmə düyməsini göstər';
	@override String get skipCreditsModeAutoDescription => 'Titrləri avtomatik ötür və növbəti seriyanı oynat';
	@override String get skipAdsMode => 'Adlar üçün';
	@override String get skipAdsModeOffDescription => 'Xatırılan reklamları normal bir skip düğmə olmadan oynayın';
	@override String get skipAdsModeButtonDescription => 'Xərimdə bir "Skype" düğmesini görünür: Plex bir reklamı tespit edər';
	@override String get skipAdsModeAutoDescription => 'Xatırılan reklamları aşağıdaki gecə sonra otomatik olarak atın';
	@override String get musicPlayback => 'Musiqi Playback';
	@override String get musicSweetFades => 'Süt fəlakları';
	@override String get musicSweetFadesDescription => 'Plex-də səs səviyyəsi məlumatları olduqda musiqi parçalarının əvvəlində və sonunda səsi tədricən dəyişin. Albomların oxudulması dəyişmir.';
	@override String get skipMarkerModeOff => 'Söndürülüb';
	@override String get skipMarkerModeButton => 'Düyməni göstər';
	@override String get skipMarkerModeAuto => 'Avtomatik';
	@override String get forceSkipMarkerFallback => 'Ehtiyat işarələri məcburi et';
	@override String get forceSkipMarkerFallbackDescription => 'Plex işarələri olsa belə hissə başlığı şablonlarını istifadə et';
	@override String get theIntroDbFallback => 'IntroDB-i intro fallback kimi istifadə edin';
	@override String get theIntroDbFallbackDescription => 'Soruşturma zamanı yalnız xilas olunsa, xilas olunsa, xilas olunsa, xilas olunsa, xilas olunsa.';
	@override String get autoSkipDelay => 'Avtomatik ötürmə ləngiməsi';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Avtomatik ötürməzdən əvvəl ${seconds} saniyə gözlə';
	@override String get introPattern => 'Giriş işarəsi şablonu';
	@override String get introPatternDescription => 'Hissə başlıqlarında giriş işarələrini tapmaq üçün Regex şablonu';
	@override String get creditsPattern => 'Titr işarəsi şablonu';
	@override String get creditsPatternDescription => 'Hissə başlıqlarında titr işarələrini tapmaq üçün Regex şablonu';
	@override String get prerolls => 'Prerolllər';
	@override String get playPrerollsBeforeMovies => 'Filmə əvvəl oynayır';
	@override String get playPrerollsBeforeMoviesDescription => 'Hər filmdən əvvəl aşağıdaki seçiminizdən bir random klip oynayın.';
	@override String get prerollLibrary => 'Preroll kütüphane';
	@override String get prerollLibraryNotSet => 'Təyin edilməyib';
	@override String get prerollLibraryNoneFound => 'Sizin serverlərinizdə heç bir kütüphane bulunmaz.';
	@override String get prerollSelection => 'Seçilmişlər';
	@override String get prerollSelectionPickLibraryFirst => 'Birincisi bir kütüphane seçin.';
	@override String get prerollSelectionNoneSelected => 'Seçilmə qalıb';
	@override String prerollSelectionCount({required Object count}) => '${count} seçilib';
	@override String get prerollItemPicker => 'Seçimlər';
	@override String get prerollItemPickerLoadFailed => 'Bu kütüphanadan bir şey yükləmə bilərəm.';
	@override String get invalidRegex => 'Səhv requlyar ifadə (Regex)';
	@override String get regex => 'Requlyar ifadə (Regex)';
	@override String get downloads => 'Yükləmələr';
	@override String get downloadLocationDescription => 'Yüklənmiş məzmunun harada saxlanacağını seçin';
	@override String get downloadLocationDefault => 'Defolt (Tətbiq yaddaşı)';
	@override String get downloadLocationCustom => 'Xüsusi məkan';
	@override String get selectFolder => 'Qovluq seç';
	@override String get resetToDefault => 'Defolt vəziyyətə sıfırla';
	@override String currentPath({required Object path}) => 'Cari: ${path}';
	@override String get downloadLocationChanged => 'Yükləmə məkanı dəyişdirildi';
	@override String get downloadLocationReset => 'Yükləmə məkanı defolt vəziyyətə sıfırlandı';
	@override String get downloadLocationInvalid => 'Seçilmiş qovluğa yazmaq olmur';
	@override String get downloadLocationPickerUnavailable => 'Qovluq seçimi bu cihazda əlçatan deyil';
	@override String get downloadOnWifiOnly => 'Yalnız Wi-Fi ilə yüklə';
	@override String get downloadOnWifiOnlyDescription => 'Mobil məlumat istifadə edildikdə yükləmələri dayandır';
	@override String get autoRemoveWatchedDownloads => 'Baxılmış yükləmələri avtomatik sil';
	@override String get autoRemoveWatchedDownloadsDescription => 'Baxılmış yükləmələri avtomatik olaraq sil';
	@override String get autoDownloadContinueWatching => 'Auto-Downloads İndi gözləyir';
	@override String get autoDownloadContinueWatchingDescription => '"Devil" filində yerləri aşağı indirilir və fildən ayrıldıqdan sonra bunları kaldırır.';
	@override String get downloadQuality => 'Qalındırma kalitəsi';
	@override String get downloadQualityDescription => 'Plex download quue-da bir dönüştürülmüş kopya hazırlar. Jellyfin və Emby transkodları, fil indirilir; durdurulmuş transferlər yeniden başlatılmalıdır.';
	@override String get askDownloadQualityEachTime => 'Hər bir download üçün seçin.';
	@override String get askDownloadQualityEachTimeDescription => 'Videoya baxmadan əvvəl cildin pikselini göstərin';
	@override String get cellularDownloadBlocked => 'Mobil şəbəkədə yükləmələr bloklanıb. Wi-Fi istifadə edin və ya tənzimləməni dəyişin.';
	@override String get maxVolume => 'Maksimal səs';
	@override String get maxVolumeDescription => 'Sakit videolar üçün səsin 100%-dən yuxarı qalxmasına icazə ver';
	@override String maxVolumePercent({required Object percent}) => '%${percent}';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord-da nəyə baxdığınızı göstərin';
	@override String get services => 'Xidmətlər';
	@override String get servicesDescription => 'Trakt, MyAnimeList, Seerr və daha çoxunu qoşun';
	@override String get manageLibrariesDescription => 'Kitabxanaları yenidən sıralayın və gizlədin';
	@override String get companionRemoteServer => 'Köməkçi pult serveri';
	@override String get companionRemoteServerDescription => 'Şəbəkənizdəki mobil cihazların bu tətbiqi idarə etməsinə icazə verin';
	@override String get companionRemoteServerStartFailed => 'Köməkçi pult serveri başladıla bilmədi';
	@override String get companionRemoteServerStopFailed => 'Köməkçi pult serveri dayandırıla bilmədi';
	@override String get autoPip => 'Avtomatik Pəncərə daxilində Pəncərə (PiP)';
	@override String get autoPipDescription => 'Oynatma zamanı tətbiqdən çıxdıqda avtomatik PiP rejiminə keç';
	@override String get matchContentFrameRate => 'Kadr tezliyini uyğunlaşdır';
	@override String get matchContentFrameRateDescription => 'Ekran yenilənmə tezliyini video məzmununa uyğunlaşdır';
	@override String get matchContentResolution => 'Məzmunun görüntü keyfiyyətinə uyğunlaş';
	@override String get matchContentResolutionDescription => 'Ekranı videonun öz görüntü keyfiyyətinə keçirir ki, miqyaslandırmanı televizorunuz etsin. Oxutma zamanı menyular və altyazılar da miqyaslandırılır';
	@override String get matchRefreshRate => 'Yenilənmə tezliyini uyğunlaşdır';
	@override String get matchRefreshRateDescription => 'Tam ekranda ekran yenilənmə tezliyini uyğunlaşdır';
	@override String get matchDynamicRange => 'Dinamik diapazonu uyğunlaşdır';
	@override String get matchDynamicRangeDescription => 'HDR məzmun üçün HDR-ı açın, sonra SDR-a qayıdın';
	@override String get displaySwitchDelay => 'Ekran dəyişmə ləngiməsi';
	@override String get tunneledPlayback => 'Tünellənmiş oynatma';
	@override String get tunneledPlaybackDescription => 'Video tünelləməni istifadə et. HDR oynatmada qara ekran görünürsə və ya hərəkət takılırsa söndürün.';
	@override String get audioPassthrough => 'Səsin birbaşa ötürülməsi (Passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS səslərini yenidən kodlamadan TV və ya resiverə göndərir. Səs gəlmirsə söndürün.';
	@override String get audioPassthroughDescriptionApple => 'Atmos daxil olmaqla Dolby Digital Plus üçün Apple-ın daxili dekoderini istifadə edin. DTS və TrueHD yenə də çoxkanallı PCM kimi oynadılır. Səs gəlmirsə söndürün.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Atmos daxil olmaqla Dolby Digital Plus üçün Apple-ın daxili Dolby dekoderini istifadə edin. iOS, iPadOS və tvOS 26 və ya daha yeni versiyalarda TrueHD Atmos və DTS:X məkan səsi kimi oynadılır. Digər DTS və TrueHD trekləri çoxkanallı PCM kimi oynadılır. Səs gəlmirsə söndürün.';
	@override String get audioPassthroughOverriddenByNormalization => 'Səsin gurluğunu normallaşdırma aktivkən söndürülüb';
	@override String get audioChannelLimit => 'Səs kanalları';
	@override String get audioChannelLimitDescription => 'Bütün kanalları oynada bilməyən dinamiklər, qulaqlıqlar və ya HDMI qurğuları üçün dekodlanmış səsi daha az kanala endir';
	@override String get audioChannelLimitOriginal => 'Orijinal';
	@override String get audioChannelLimitOriginalDescription => 'Trekdəki bütün kanalları oynat';
	@override String get audioChannelLimitSurround51 => '5.1-ə qədər';
	@override String get audioChannelLimitSurround51Description => 'Yalnız 5.1 PCM qəbul edən televizorlar və resiverlər üçün 7.1-i 5.1-ə endir. Birbaşa ötürməyə təsir etmir.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Stereo dinamiklər və ya qulaqlıqlar üçün iki kanala endir. Birbaşa ötürməni söndürür.';
	@override String get downmixCenterBoost => 'Mərkəz kanal gücləndirilməsi';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Gücləndirmə (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Çevirmədə səsi normallaşdır';
	@override String get audioDownmixNormalizeDescription => 'Səs kəsilmələrinin qarşısını almaq üçün səviyyəni endirin. Orijinal səs səviyyəsini saxlamaq üçün söndürün (yüksək səsli səhnələr təhrif oluna bilər).';
	@override String get dvConversionMode => 'Dolby Vision çevrilməsi';
	@override String get dvConversionModeDescription => 'Dolby Vision Profile 7 fayllarının necə emal ediləcəyini seçin.';
	@override String get dvConversionAuto => 'Avtomatik';
	@override String get dvConversionNative => 'Daxili / Söndürülüb';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Cihaz imkanlarının təyini və normal davranışdan istifadə et';
	@override String get dvConversionNativeDescription => 'Daxili DV7-ni məcburi et';
	@override String get dvConversionDv81Description => 'Dolby Vision profile 8.1-ə çevrilməni məcburi et';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision təbəqələrini sil və sadə HEVC kimi təqdim et';
	@override String get experimentalDolbyVision => 'Eksperimental Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'Növbəti oxutmada eksperimental FEL renderindən istifadə edin. Mühərrikin ayrıca yığılması tələb olunur.';
	@override String get dvExperimentUnavailableDescription => 'Bu sınaq hazırda yalnız Linux-da mövcuddur.';
	@override String get dvCompatibilityFallback => 'Uyğunluq üçün ehtiyat rejim';
	@override String get dvCompatibilityFallbackDescription => 'Sınaq başlaya bilməsə, standart renderdən istifadə edin. FEL məlumatları itə bilər.';
	@override String get dvExperimentDiagnostics => 'Video sınağının jurnalı';
	@override String get dvExperimentDiagnosticsDescription => 'Növbəti oxutmada ətraflı pleyer jurnallarını aktivləşdirin.';
	@override String get disableDolbyVision => 'Dolby Vision-u söndür';
	@override String get disableDolbyVisionDescription => 'Faylda varsa, Dolby Vision əvəzinə HDR10 və ya HLG təbəqəsini oynat';
	@override String get hdrSdrConversion => 'HDR-dən SDR-ə çevirmə';
	@override String get hdrSdrConversionDescription => 'Ekran HDR göstərə bilmədikdə HDR videonu nəyin çevirəcəyini seçin.';
	@override String get hdrSdrConversionAuto => 'Avtomatik';
	@override String get hdrSdrConversionAutoDescription => 'Android 9 və sonrakı versiyalarda cihaz, köhnə versiyalarda oynadıcı';
	@override String get hdrSdrConversionDevice => 'Cihaz';
	@override String get hdrSdrConversionDeviceDescription => 'Çevirməni cihazın video avadanlığı edir. Ən sürətlisi, lakin rənglər cihazdan asılıdır';
	@override String get hdrSdrConversionPlayer => 'Oynadıcı';
	@override String get hdrSdrConversionPlayerDescription => 'Çevirməni oynadıcı edir. Sabit rənglər, lakin zəif TV qutularında 4K ilişə bilər';
	@override String get deinterlace => 'Deinterleysinq';
	@override String get deinterlaceDescription => 'Sətirlərarası videodakı darama artefaktlarını aradan qaldır (yalnız mpv oynadıcısı)';
	@override String get deinterlaceOff => 'Söndürülüb';
	@override String get deinterlaceOffDescription => 'Sətirlərarası videonu dekodlandığı kimi göstər';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Hər yarımkadrı tam kadra çevir. İdman, xəbər və konsert kimi TV üçün çəkilmiş videolar üçün';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => '29.97 fps-ə telesine edilmiş film və animasiyaların orijinal kadrlarını bərpa et (NTSC DVD-lərdə geniş yayılıb). TV üçün çəkilmiş video ilişir. Canlı TV Video rejimindən istifadə edir';
	@override String get requireProfileSelectionOnOpen => 'Açılışda profil soruş';
	@override String get requireProfileSelectionOnOpenDescription => 'Tətbiq hər dəfə açıldıqda profil seçimini göstər';
	@override String get forceTvMode => 'TV rejimini məcburi et';
	@override String get forceTvModeDescription => 'TV interfeysini məcburi et. Avtomatik təyin etməyən cihazlar üçündür. Yenidən başlatma tələb olunur.';
	@override String get startInFullscreen => 'Tam ekranda başlat';
	@override String get startInFullscreenDescription => 'PlezyNG-ni açılışda tam ekran rejimində aç';
	@override String get exitFullscreenOnPlayerClose => 'Oynadıcı bağlandıqda tam ekrandan çıx';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Video oynadıcını bağlayarkən avtomatik tam ekrandan çıx';
	@override String get autoHidePerformanceOverlay => 'Məhsuldarlıq paneli avtomatik gizlənsin';
	@override String get autoHidePerformanceOverlayDescription => 'Məhsuldarlıq panelini oynatıcı idarəetmələri ilə birlikdə gizlət';
	@override String get showNavBarLabels => 'Naviqasiya paneli yazılarını göstər';
	@override String get showNavBarLabelsDescription => 'Naviqasiya paneli ikonlarının altında mətni göstər';
	@override String get startupSection => 'Başlanğıc bölməsi';
	@override String get preferredServer => 'Serverlər tercih edilir';
	@override String get preferredServerDescription => 'Bu sunucu sonucunu öncelik verin və hər bir bağlantılı sunucuya bağlanın.';
	@override String get preferredServerAutomatic => 'Avtomatik';
	@override String get showExploreTab => 'Kəşf et nişanını göstər';
	@override String get showExploreTabDescription => 'Plex Discover və qoşulmuş izləmə xidmətlərindəki məzmunla Kəşf et nişanını göstər';
	@override String get hideEmptyLibraries => 'Boş kütüphaneyi saklayın';
	@override String get hideEmptyLibrariesDescription => 'Server-da bildirilmiş element sayının sıfırı olan kütüphaneyi navigasiyadən çıkarır.';
	@override String get liveTvDefaultFavorites => 'Canlı TV-də sevimli kanalları defolt et';
	@override String get liveTvDefaultFavoritesDescription => 'Canlı TV açıldıqda yalnız sevimli kanalları göstər';
	@override String get general => 'Ümumi';
	@override String get generalDescription => 'Dil, başlanğıc və pəncərə davranışı';
	@override String get languageAndRegion => 'Dil və Region';
	@override String get startup => 'Başlanğıc';
	@override String get display => 'Ekran';
	@override String get libraryAndCards => 'Kitabxana və kartlar';
	@override String get homeScreen => 'Ana ekran';
	@override String get navigation => 'Naviqasiya';
	@override String get window => 'Pəncərə';
	@override String get liveTv => 'Canlı TV';
	@override String get player => 'Oynadıcı';
	@override String get videoAndDisplay => 'Video və Ekran';
	@override String get audio => 'Səs';
	@override String get quality => 'Keyfiyyət';
	@override String get subtitles => 'Altyazılar';
	@override String get seekAndTiming => 'Sarğı və vaxt tənzimləməsi';
	@override String get behavior => 'Davranış';
	@override String get gestures => 'Jestlər';
	@override String get gestureBrightnessSwipe => 'Parlaqlıq sürüşdürməsi';
	@override String get gestureBrightnessSwipeDescription => 'Parlaqlığı tənzimləmək üçün sol kənarda yuxarı və ya aşağı sürüşdürün';
	@override String get gestureVolumeSwipe => 'Səs sürüşdürməsi';
	@override String get gestureVolumeSwipeDescription => 'Səsi tənzimləmək üçün sağ kənarda yuxarı və ya aşağı sürüşdürün';
	@override String get gesturePinchToZoom => 'Çimdiklə yaxınlaşdır';
	@override String get gesturePinchToZoomDescription => 'Yaxınlaşdırmaq və ya uzaqlaşdırmaq üçün videoda çimdik hərəkəti edin';
	@override String get gestureSeekSwipe => 'Qəzaq Sivas';
	@override String get gestureSeekSwipeDescription => 'Videoya baxmaq üçün sol və ya düz bir yer çalın; atlayın';
	@override String get rememberBrightnessLevel => 'Parlaqlıq səviyyəsini xatırla';
	@override String get rememberBrightnessLevelDescription => 'Oxutmanı son sürüşdürmə ilə təyin edilmiş parlaqlıqda başlat';
	@override String get controls => 'İdarəetmələr';
	@override String get rememberPlayerChanges => 'Pleyer dəyişikliklərini yadda saxla';
	@override String get rememberPlayerChangesDescription => 'Oxutma zamanı edilən dəyişikliklərin harada saxlanacağı və yenidən tətbiq ediləcəyi';
	@override String get scopePlaybackSpeed => 'Oxutma sürəti';
	@override String get scopeShaderPreset => 'Şader ön ayarı';
	@override String get scopeAspectRatio => 'Tərəf nisbəti';
	@override String get scopeSyncOffsets => 'Audio və subtitr sinxronizasiyası';
	@override String get playerScopeOff => 'Saxlama';
	@override String get playerScopeGlobal => 'Hər yerdə';
	@override String get playerScopeLibrary => 'Kitabxana üzrə';
	@override String get playerScopeTitle => 'Serial və ya film üzrə';
	@override String get exportDialogTitle => 'PlezyNG tənzimləmələrini ixrac et';
	@override String get followSystem => 'Sistem dilini izləyin';
	@override String get followAppLanguage => 'İnterfeys dili ilə eyni';
	@override String get regionFormat => 'Regional formatlar';
	@override String get regionFormatDescription => 'Tarixlərin, rəqəmlərin və ölçü vahidlərinin göstərilmə qaydasını seçin.';
	@override String get metadataLanguage => 'Metaməlumat dili';
	@override String get metadataLanguageDescription => 'Server dəstəklədikdə başlıqlar və təsvirlər üçün üstün tutulan dil. Səs və altyazı seçimləri ayrıca tənzimlənir.';
	@override String get enterFullscreenOnPlaybackStart => 'Playback başladığı zaman Full Screen-a daxil olun';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Full-screen video oynamaq başladığı zaman açılır';
	@override String get extendVideoIntoDisplayCutout => 'Görüntüləri ekranın qalığına genişletir';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Full-screen videonun Android telefonlarda kamera qızı kullanmasına izin verin';
	@override String get languageDescription => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.';
	@override String get themeDescription => 'Və, bu programda istifadə edilen renk və kontrast seçin.';
	@override String get libraryDensityDescription => 'Hər bir kitabın sayını dəyişir.';
	@override String get displayScaleDescription => 'Bu arayüz ekranının interfejsini, cihazın bütünüyle texti boyutunu dəyişmədən qaytarır.';
	@override String get themeSongVolumeDescription => 'Sonraki YazıSonraki Şarkı SözleriSonrakı ŞarkılarSonraktaki Konuşma';
	@override String get viewModeDescription => 'Kitabın elementləri bir ağda plakalar kimi və ya kompakt bir list olarak görünürünü seçin.';
	@override String get gridViewDescription => 'Kütüphanə elementləri plakaların satırlarında və sütunlarında düzəltür.';
	@override String get listViewDescription => 'Kitabın elementləri daha çox texti ilə vertikal bir listə görünür.';
	@override String get gridSpacingDescription => 'Kütüphane ağlarında plakalar arasındaki boşluğu ayarlar.';
	@override String get gridSpacingTightDescription => 'Daha çox plakalar ekranın üstündə daha az boşluklarla yerləşdirilir.';
	@override String get gridSpacingNormalDescription => 'Standart plakalar arasındaki boşluğu istifadə edin.';
	@override String get gridSpacingSpaciousDescription => 'Daha çox ayrılma üçün plakalar arasında daha böyük boşluklar ekləyin.';
	@override String get episodePosterModeDescription => 'Qadınlar hangi filmdə aparılacağını seçin.';
	@override String get seriesPosterDescription => 'Şovun hər seri posterini istifadə edin.';
	@override String get seasonPosterDescription => 'Sezon posterini hər bir bölümdə istifadə edin.';
	@override String get episodeThumbnailDescription => 'Bu bölümdə hazır olduğunda bir çerçevə istifadə edin.';
	@override String get continueWatchingActionDescription => '“Gözlük” kartı aktivasiya etdiyinizdə nə olacağını seçin.';
	@override String get continueWatchingPlayDescription => 'Filmi və ya epizodunu hemen başlatır.';
	@override String get continueWatchingDetailsDescription => 'İlk dəfə başlık sayısını açın, bu yüzden ayrıntıları gözləyir və bir əməl seçirsiniz.';
	@override String get episodeActionDescription => 'Bir epizod kartı aktivasiya etdiyinizdə nə olacağını seçin.';
	@override String get episodePlayDescription => 'Bir neçə dəfə epizodı başlatır.';
	@override String get episodeDetailsDescription => '“Playback”dan əvvəl bölüm sayısını açın.';
	@override String get contentScreensaverDelayDescription => 'Artwork göstərmeden əvvəl PlezyNG nə qədər inşası olmadan gözləyir.';
	@override String get continueWatchingRowSizeDescription => 'Qadınların kartlarının nə qədər böyük olduğunu seçin.';
	@override String get rowSizeCompactDescription => 'Küçük kartları görünür ki, daha çox elementlər sıraya daxil olur.';
	@override String get rowSizeStandardDescription => 'Standart kart boyutu istifadə edin.';
	@override String get rowSizeLargeDescription => 'Daha geniş kartlar və daha çox artwork ayrıntıları ilə göstərilir.';
	@override String get visualEffectsDescription => 'Bu cihazın animasyon və sanat efektləri bütçesini seçin.';
	@override String get visualEffectsFullDescription => 'Artwork və animation efektləri hər bir cihazda istifadə edin.';
	@override String get startupSectionDescription => 'Həyatın başladığı zaman hangi bölümü seçilir.';
	@override late final _Translations$settings$startupSectionOptions$az startupSectionOptions = _Translations$settings$startupSectionOptions$az._(_root);
	@override String get smallSkipDurationDescription => 'Düşünürəm ki, bu yolda qısaltılma və geri qayıtılma yolları var.';
	@override String get largeSkipDurationDescription => 'Düşünürəm ki, bu yolda uzun sürətlər və kontrollar yerləşdirilir.';
	@override String get rewindOnResumeDescription => 'Videoya qayıtmaq üçün bu sayı ilə geri çəkilir.';
	@override String get defaultSleepTimerDescription => 'İlk vaxtı başlamaq üçün istifadə etmək lazımdır.';
	@override String get playNextCountdownDescription => 'Bir sonraki bölümə başlamadan əvvəl bu uzun müddət bekləyin.';
	@override String get autoSkipDelaySettingDescription => 'Bu, bir intro, kredit və ya reklamın otomatik olarak atılması üçün ayarlandığı zaman geçer.';
	@override String get downmixCenterBoostDescription => '“Stereo” kanalında, çevrimiçi sesin stereo-da karıştırıldığı zaman diyaloyu yüksəlir.';
	@override String get displaySwitchDelayDescription => 'Görüntülər modunu dəyişmeden əvvəl televizyonun və ya alıcının önceki anahtarını tamamlayabilmesini gözləyin.';
	@override String get playerBackendDescription => 'Bu cihazda hangi oyun motoru decod və render video seçin.';
	@override String get exoPlayerDescription => 'Android\'in yerli Media3 bazlı oynatıcıları və destekli hardware yollarını istifadə edin.';
	@override String get mpvDescription => 'MPV-i istifadə edin, bu da daha çox playback, subtitle və video işleme kontrolləri göstərir.';
	@override String get scopeOffDescription => 'Şimdiki playback-session üçün dəyişənlər yalnız saxlayın.';
	@override String get scopeGlobalDescription => 'Hər bir kütüphane və başlık için aynı değerini tekrar istifadə edin.';
	@override String get scopeLibraryDescription => 'Hər bir kütüphane üçün ayrı bir değer alın.';
	@override String get scopeTitleDescription => 'Hər bir filmdə və ya şovda ayrı bir sayı var.';
	@override String get specialsOrderingServerDescription => 'Media server tərəfindən sağlanan epizod siparişini tutun.';
	@override String get specialsOrderingAirDateDescription => '“Gözlük”da düzenli günlər arasında yerləşdirilir.';
	@override String get specialsOrderingLastDescription => 'Hər biri normal sezondan sonra yerləşdirilir.';
	@override String get skipIntroModeDescription => 'Intro markers normal oynayır, bir skip düğmesini göstərir və ya otomatik olarak skip.';
	@override String get skipCreditsModeDescription => 'Kreditlər normal oynanır, bir skip düğmesini göstərər və ya otomatik olarak skip.';
	@override String get skipAdsModeDescription => 'Görünən reklamların normal oynadığını, bir skip düğmesini göstərdiğini və ya otomatik olarak skip-i seçin.';
	@override String get playbackBufferAutoDescription => 'Aktiv oyuncu normal buffer büyüklüğünü seçsin.';
	@override String get playbackBufferLargeDescription => 'Daha çox medya hazır olun; bu, daha fazla hafızayı kullanır.';
	@override String get playbackBufferExtraLargeDescription => 'Bu, ən böyük ok-ahead bufferini saxlayır; bu, en çox hafızayı kullanır.';
	@override String get defaultQualityDescription => 'Video çözünürlüğünü ayarlayın və sunucu transcod olan akışlar için çatı bitrate.';
	@override String get cellularQualityDescription => 'Bir cihazın yalnız hücresel bağ kullanıldığı zaman standart kaliteyi aşırır.';
	@override String get remoteQualityDescription => 'Default Quality (Default Qalitəsi) ilə bir sunucuya bağlanırsa, uzaktan bağlanma yoluyla aşılır.';
	@override String get qualityPresetOriginalDescription => 'Sunucuya sızdırmaq üçün sorğu olmadan mevcut kalitede kaynağı oynayın.';
	@override String get qualityPresetTranscodeOptionDescription => 'Sunucu, yukarıda göstərilmiş çözünürlüğünü və bitrateyi kullanarak dönüştürülmüş bir akış üçün soruşun.';
	@override String get qualityPresetSameAsDefaultDescription => 'Default Quality-da seçilmiş kaliteyi istifadə edin.';
	@override String get musicQualityDescription => 'Servisdən istədiyiniz maksimum audio bitrate ayarlayın; Orijinal kaynak akışını tutar.';
	@override String get musicQualityOriginalDescription => 'Bir bitrate-capped transcode olmadan kaynak audio oynayın.';
	@override String get musicQualityTranscodeOptionDescription => 'Bir sunucu transkodu, yukarıda göstərilmiş bitrate yaxınında qapılmışdır; gerçek çıkış değişir.';
	@override String get maxVolumeInputLabel => 'Maksimum sayı (% )';
	@override String get checkForUpdatesDescription => 'İndi görmək olar ki, yeni bir versiyonu var.';
	@override String get appearanceDescription => 'App teması seçin və kütüphane kartları, Ev satırlar və navigasiya ayarlayın.';
	@override String get prerollLibraryDescription => 'Filmin hazırlığı kimi mevcut klipləri olan kütüphaneyi seçin.';
	@override String get prerollSelectionDescription => 'Seçin ki, seçilmiş kütüphanadan hangi klipləri filmlər öncə oynayabilir.';
	@override String get contentScreensaverDelayOptionDescription => 'Bu, ekranda aparılmadan əvvəl çox dakikalar bekləyin.';
	@override String get videoCodecOptionDescription => 'Bu codec üçün doğrudan oynamaq sağlanır. kontrolsüz codeclar medya sunucu tarafından transkod edilir.';
}

// Path: themeEditor
class _Translations$themeEditor$az extends Translations$themeEditor$en {
	_Translations$themeEditor$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Daxili';
	@override String get presets => 'Hazır mövzular';
	@override String get custom => 'Xüsusi';
	@override String get customEmpty => 'Hələ yaradılmayıb';
	@override String get editCustom => 'Xüsusi mövzuya düzəliş et';
	@override String get editCustomDescription => 'Bütün rəngləri özünüz seçin';
	@override String get locked => 'Ömür boyu qalıb';
	@override String get savedLocked => '“Gözəl” – ömür boyu qapı ilə';
	@override String get title => 'Xüsusi mövzu';
	@override String get startFrom => 'Başlanğıc mövzu';
	@override String get startFromDescription => 'Bütün rəngləri başqa mövzudan kopyala';
	@override String get colors => 'Rənglər';
	@override String get preview => 'Önizləmə';
	@override late final _Translations$themeEditor$slots$az slots = _Translations$themeEditor$slots$az._(_root);
	@override String get opacity => 'Şəffaflıq';
	@override String get hexHint => '#RRGGBB və ya #AARRGGBB';
	@override String get fromOtherThemes => 'Digər mövzulardan';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme}: ${color}';
	@override late final _Translations$themeEditor$contrast$az contrast = _Translations$themeEditor$contrast$az._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, tövsiyə olunan ${minimum}:1-dən aşağı';
	@override String get discardTitle => 'Dəyişikliklərdən imtina edilsin?';
	@override String get discardMessage => 'Yadda saxlanmamış rəng dəyişiklikləriniz itəcək.';
	@override String get discard => 'İmtina et';
	@override String previewCardTitle({required Object number}) => 'Seriya ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} dəq qaldı';
	@override String get previewSwitch => 'Avtomatik oynatma';
	@override String get previewMutedText => 'Köməkçi mətn belə görünür';
	@override String get themeSystemDescription => 'Görünüşünüzü izləyin və aydınlıq və karanlık arasında avtomatik olarak dəyişin.';
	@override String get themeLightDescription => 'Siyah texti ilə aydınlı bir arkağı kullanın.';
	@override String get themeDarkDescription => 'Düşünür texti ilə karanlık bir tapınak kullanır.';
	@override String get themeOledDescription => 'Qısa-siyah yüzeyləri, OLED ekranlarda ışığı azaltmaq üçün istifadə edin.';
	@override String get themeEmberDescription => 'Sıcak kırmızı və amber axent rengi kullanın.';
	@override String get themeGlacierDescription => 'Qırmızı mavi axent rengi kullanın.';
	@override String get themeForestDescription => 'Doğal və yeşil renklər kullanılır.';
	@override String get themePlumDescription => 'Viyol və plum aksent rengi kullanın.';
	@override String get themePaperDescription => 'Əslində, bu sahədə və buğdaydan ilham alınmış renklər yerləşdirilir.';
	@override String get themeCustomDescription => 'O, özü üçün hazırladığınız temalar editöründən yaratdığınız renk paleti istifadə edin.';
	@override String get editorDescription => 'Bir palet rengi seçin, onun həkimini, tohumunu, parlaklığını və ya opacityini ayarlayın və ödəniş etmədən əvvəl öncə baxış güncəlisini görün.';
}

// Path: search
class _Translations$search$az extends Translations$search$en {
	_Translations$search$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Kino, serial, musiqi axtar...';
	@override String get tryDifferentTerm => 'Fərqli axtarış sözü cəhd edin';
	@override String get searchYourMedia => 'Mediyanızda axtarın';
	@override String get enterTitleActorOrKeyword => 'Ad, aktyor və ya açar söz daxil edin';
	@override String get people => 'Şəxslər';
}

// Path: hotkeys
class _Translations$hotkeys$az extends Translations$hotkeys$en {
	_Translations$hotkeys$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName} üçün qısayol təyin et';
	@override String get clearShortcut => 'Qısayolu təmizlə';
	@override String get noShortcutSet => 'Qısayol təyin edilməyib';
	@override String get currentShortcut => 'Cari qısayol:';
	@override String get pressToRecord => 'Qısayol yazmaq üçün seçin';
	@override String get recordingShortcut => 'İndi qısayol düymələrinə basın';
	@override late final _Translations$hotkeys$actions$az actions = _Translations$hotkeys$actions$az._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$az extends Translations$fileInfo$en {
	_Translations$fileInfo$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fayl məlumatı';
	@override String get overview => 'Ümumi baxış';
	@override String get video => 'Video';
	@override String get audio => 'Səs';
	@override String get subtitles => 'Altyazılar';
	@override String get images => 'Daxili şəkillər';
	@override String get dataStreams => 'Məlumat axınları';
	@override String get lyrics => 'Mahnı sözləri';
	@override String get file => 'Fayl';
	@override String get attachments => 'Əlavələr';
	@override String get delivery => 'Çatdırılma';
	@override String versionCounter({required Object count, required Object index}) => '${count}-dən ${index} versiya';
	@override String fileCounter({required Object count, required Object index}) => '${count}-dən ${index} fayl';
	@override String get noStreams => 'Server bu fayl üçün heç bir axın bildirmədi.';
	@override String get copyPath => 'Yolu kopyala';
	@override String get pathCopied => 'Fayl yolu kopyalandı';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Kodek teqi';
	@override String get resolution => 'Ayırdetmə';
	@override String get codedResolution => 'Kodlanmış rezolyusiya';
	@override String get bitrate => 'Bit sürəti (Bitrate)';
	@override String get frameRate => 'Kadr tezliyi';
	@override String get rotation => 'Dönmə';
	@override String get comment => 'Şərh';
	@override String get audioDescription => 'Səs təsviri';
	@override String get headerCompression => 'Başlıq sıxışdırması';
	@override String get sidecarFile => 'Sidecar faylı';
	@override String get transportTimestamp => 'Transport vaxt damğası';
	@override String get displayOffset => 'Ekran ofseti';
	@override String get previewFailureCode => 'Önizləmə xəta kodu';
	@override String get previewRetries => 'Önizləmə cəhdləri';
	@override String get aspectRatio => 'Tərəf nisbəti';
	@override String get pixelAspectRatio => 'Piksel aspekt nisbəti';
	@override String get profile => 'Profil';
	@override String get level => 'Səviyyə';
	@override String get bitDepth => 'Bit dərinliyi';
	@override String get pixelFormat => 'Piksel formatı';
	@override String get colorSpace => 'Rəng sahəsi';
	@override String get colorRange => 'Rəng diapazonu';
	@override String get colorPrimaries => 'Əsas rənglər';
	@override String get colorTransfer => 'Rəng ötürməsi';
	@override String get chromaSubsampling => 'Rəng alt-diskretləşdirməsi';
	@override String get chromaLocation => 'Chroma mövqeyi';
	@override String get scanType => 'Tarama növü';
	@override String get interlaced => 'Sətirlərarası';
	@override String get anamorphic => 'Anamorfik';
	@override String get referenceFrames => 'İstinad kadrları';
	@override String get dynamicRange => 'Dinamik diapazon';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision səviyyəsi';
	@override String get dolbyVisionVersion => 'Dolby Vision versiyası';
	@override String get dolbyVisionLayers => 'Dolby Vision təbəqələri';
	@override String get baseLayerCompatibility => 'Baza təbəqə uyğunluğu';
	@override String get avcBitstream => 'AVC bit axını';
	@override String get nalLengthSize => 'NAL uzunluq ölçüsü';
	@override String get scalingMatrix => 'Xüsusi miqyaslama matrisi';
	@override String get streamIdentifier => 'Axın identifikatoru';
	@override String get streamIndex => 'Axın indeksi';
	@override String get streamId => 'Axın ID-si';
	@override String get language => 'Dil';
	@override String get languageCode => 'Dil kodu';
	@override String get streamTitle => 'Trek başlığı';
	@override String get channels => 'Kanallar';
	@override String get sampleRate => 'Diskretləşdirmə tezliyi';
	@override String get spatialAudio => 'Məkan səsi';
	@override String get textBased => 'Mətn əsaslı';
	@override String get subtitleFormat => 'Sidecar formatı';
	@override String get provider => 'Provayder';
	@override String get matchScore => 'Uyğunluq balı';
	@override String get externalDelivery => 'Ayrıca ötürülə bilər';
	@override String get sidecarPath => 'Sidecar yolu';
	@override String get sourceStream => 'Kopyalanan mənbə';
	@override String get temporary => 'Müvəqqəti';
	@override String get timeBase => 'Vaxt bazası';
	@override String get overallBitrate => 'Ümumi bit sürəti';
	@override String get path => 'Yol';
	@override String get fileName => 'Fayl adı';
	@override String get size => 'Həcm';
	@override String get totalSize => 'Ümumi ölçü';
	@override String get container => 'Konteyner';
	@override String get duration => 'Müddət';
	@override String get previewThumbnails => 'Önizləmə miniatürləri';
	@override String get previewIndex => 'Önizləmə indeksi';
	@override String get packetLength => 'Paket uzunluğu';
	@override String get filePresent => 'Fayl mövcuddur';
	@override String get fileReadable => 'Server tərəfindən oxuna bilir';
	@override String get streamPath => 'Axın yolu';
	@override String get optimizedForStreaming => 'Yayım üçün optimallaşdırılıb';
	@override String get has64bitOffsets => '64-bit ofsetlər';
	@override String get protocol => 'Protokol';
	@override String get mediaType => 'Media növü';
	@override String get sourceKind => 'Mənbə növü';
	@override String get optimizedVersion => 'Optimallaşdırılmış versiya';
	@override String get optimizationTarget => 'Optimallaşdırma hədəfi';
	@override String get deletedAt => 'Silinib';
	@override String get remoteSource => 'Uzaq mənbə';
	@override String get infiniteStream => 'Sonsuz axın';
	@override String get directPlay => 'Birbaşa oynatma';
	@override String get directStream => 'Birbaşa axın';
	@override String get transcoding => 'Yenidən kodlaşdırma';
	@override String get etag => 'ETag';
	@override String get versionId => 'Versiya ID-si';
	@override String get fileId => 'Fayl ID-si';
	@override String get defaultAudioTrack => 'Defolt səs treki';
	@override String get defaultSubtitleTrack => 'Defolt altyazı treki';
	@override String get subtitlesOff => 'Söndürülüb';
	@override String get flagDefault => 'Defolt';
	@override String get flagForced => 'Məcburi';
	@override String get flagSelected => 'Seçilib';
	@override String get flagExternal => 'Xarici';
	@override String get flagHearingImpaired => 'Eşitmə qüsurlu üçün';
	@override String get flagDub => 'Dublyaj';
	@override String get flagOriginal => 'Orijinal';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$az extends Translations$mediaMenu$en {
	_Translations$mediaMenu$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Baxıldı olaraq işarələ';
	@override String get markAsUnwatched => 'Baxılmadı olaraq işarələ';
	@override String get removeFromContinueWatching => 'İzləməyə davam et-dən sil';
	@override String get viewDetails => 'Ətraflı bax';
	@override String get goToSeries => 'Seriala keç';
	@override String get shufflePlay => 'Qarışıq oynat';
	@override String get shuffleNotAvailableOffline => 'Qarışıq oynatma oflayn rejimdə əlçatan deyil';
	@override String get fileInfo => 'Fayl məlumatı';
	@override String get deleteEpisodeFromServer => 'Seriyanı serverdən sil';
	@override String get deleteSeasonFromServer => 'Mövsümü serverdən sil';
	@override String get deleteShowFromServer => 'Serialı serverdən sil';
	@override String get deleteMovieFromServer => 'Kinonu serverdən sil';
	@override String get deleteEpisodeTitle => 'Bu seriya silinsin?';
	@override String get deleteSeasonTitle => 'Bu mövsüm silinsin?';
	@override String get deleteShowTitle => 'Bu serial silinsin?';
	@override String get deleteMovieTitle => 'Bu kino silinsin?';
	@override String get deleteEpisodeConfirm => 'Seriyanı sil';
	@override String get deleteSeasonConfirm => 'Mövsümü sil';
	@override String get deleteShowConfirm => 'Serialı sil';
	@override String get deleteMovieConfirm => 'Kinonu sil';
	@override String get deleteAnyway => 'Yenə də sil';
	@override String confirmDeleteTarget({required Object title}) => '${title} serverinizdən birdəfəlik silinsin?';
	@override String get deleteMultipleWarning => 'Bu bütün seriyaları və faylları əhatə edir.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: 'Bu, içindəki ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriyanı və onun faylını siləcək.',
		other: 'Bu, içindəki ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriyanı və onların fayllarını siləcək.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fayl kimi saxlanılır və o silinəcək.',
		other: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faylda saxlanılır və hamısı silinəcək.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: 'Eyni faylda saxlanılan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başqa seriya da silinəcək:',
		other: 'Eyni faylda saxlanılan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başqa seriya da silinəcək:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG bunun hansı faylları siləcəyini yoxlaya bilmədi, ona görə də yuxarıda adı çəkilən elementdən daha çoxunu silə bilər. Ləğv edib təzədən cəhd edin və ya yenə də silin.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Serveriniz bu element üçün fayl təfərrüatlarını təqdim etmədi, ona görə PlezyNG bunun hansı faylları siləcəyini yoxlaya bilmir. Yuxarıda adı çəkilən elementdən daha çoxunu silə bilər.';
	@override String get mediaDeletedSuccessfully => 'Media elementi uğurla silindi';
	@override String get mediaFailedToDelete => 'Media elementi silinə bilmədi';
	@override String get rate => 'Qiymətləndir';
	@override String get playFromBeginning => 'Əvvəldən oynat';
	@override String get playVersion => 'Versiyanı oynat...';
}

// Path: rateSheet
class _Translations$rateSheet$az extends Translations$rateSheet$en {
	_Translations$rateSheet$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Qiymətləndir';
	@override String get server => 'Server';
	@override String get favorite => 'Sevimli';
	@override String get favorited => 'Sevimlilərə əlavə edildi';
	@override String get saved => 'Yadda saxlanıldı';
	@override String get notAvailable => 'Uyğunluq tapılmadı';
	@override String get noConnectedServices => 'Orada qiymətləndirmək üçün Tənzimləmələrdən xidmət qoşun.';
}

// Path: accessibility
class _Translations$accessibility$az extends Translations$accessibility$en {
	_Translations$accessibility$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, kino';
	@override String mediaCardShow({required Object title}) => '${title}, TV şou';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'baxılıb';
	@override String mediaCardPartiallyWatched({required Object percent}) => '%${percent} baxılıb';
	@override String get mediaCardUnwatched => 'baxılmayıb';
	@override String get tapToPlay => 'Oynatmaq üçün toxunun';
	@override String get decrease => 'Azalt';
	@override String get increase => 'Artır';
	@override String decreaseValue({required Object label}) => '${label} dəyərini azalt';
	@override String increaseValue({required Object label}) => '${label} dəyərini artır';
	@override String get hue => 'Rəng çaları';
	@override String get saturation => 'Doyğunluq';
	@override String get brightness => 'Parlaqlıq';
	@override String get hexColor => 'Hex rəngi';
	@override String get expandText => 'Mətni genişləndir';
	@override String get collapseText => 'Mətni yığ';
	@override String get alphabetNavigation => 'Əlifba naviqasiyası';
	@override String get alphabetScrollHint => 'Hərflərə görə keçmək üçün yuxarı və ya aşağı sürüşdürün';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Sətir ${row} / ${rowCount}, sütun ${column} / ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Sətir ${row} / ${rowCount}';
	@override String get autoScrollPlay => 'Avtomatik sürüşdürməni başlat';
	@override String get autoScrollPause => 'Avtomatik sürüşdürməyə fasilə ver';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Kırmızı';
	@override String get green => 'Yeşil';
	@override String get blue => 'Mavi';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'XƏBƏL';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Aksesibillıq';
	@override String get summary => 'Text, kontrast, Movement və Control';
	@override String get systemHint => 'Bu seçeneklər PlezyNG ilə bağlı ayarları daha çox artırır.';
	@override String get readability => 'Görünürlük və baxış';
	@override String get textSize => 'Tekstil boyutu';
	@override String get preview => 'Next story Özünüzə bax, dinlə və izləyin';
	@override String get boldText => 'İyilikçi interfejs';
	@override String get highContrast => 'Kontrastın böyük';
	@override String get highContrastHint => 'Daha çox texti, tez-tez və qısıl və ya aydın yüzeylər üzerinde odak göstergeleri.';
	@override String get interaction => 'Movsiya və interaksiya';
	@override String get reduceMotion => 'Movqeyi azaltır';
	@override String get reduceMotionHint => 'Fokus göstəricisinin hərəkətini, səhifə keçidlərini və dekorativ effektləri dayandırın.';
	@override String get largeTargets => 'Təkimlər daha çox';
	@override String get largeTargetsHint => '“Müşən” komandaları daha çox touch və asistivi navigasiya üçün yer verir.';
	@override String get navigationHint => 'İdarəetmə elementləri arasında keçmək üçün Tab və Shift+Tab, aktivləşdirmək üçün Enter və ya Boşluq, bağlamaq üçün Escape və ya Geri düyməsindən istifadə edin. Kitab açıq olduqda böyütmə və oxu tənzimləmələri əlçatandır.';
	@override String get textSizeDescription => 'VVD-nin textiyi, sistemin texti-büyüklüğü ayarının yanı sıra PlezyNG-də ölçülür.';
	@override String get boldTextHint => 'İnternet etiketləri və mesajları üçün daha ağır bir ağırlık kullanın ki, onları ayırt etmək kolaydır.';
}

// Path: tooltips
class _Translations$tooltips$az extends Translations$tooltips$en {
	_Translations$tooltips$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Qarışıq oynat';
	@override String get playTrailer => 'Treyleri oynat';
	@override String get markAsWatched => 'Baxıldı olaraq işarələ';
	@override String get markAsUnwatched => 'Baxılmadı olaraq işarələ';
}

// Path: audioTracks
class _Translations$audioTracks$az extends Translations$audioTracks$en {
	_Translations$audioTracks$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Səs zolağı ${n}';
}

// Path: videoControls
class _Translations$videoControls$az extends Translations$videoControls$en {
	_Translations$videoControls$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Səs';
	@override String get subtitlesLabel => 'Altyazı';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Geniş ekran (Letterbox)';
	@override String get fillScreen => 'Ekrana doldur';
	@override String get stretch => 'Gərmək';
	@override String get lockRotation => 'Dönməni kilidlə';
	@override String get unlockRotation => 'Dönmə kilidini aç';
	@override String get timerActive => 'Taymer aktivdir';
	@override String playbackWillPauseIn({required Object duration}) => 'Oynatma ${duration} sonra fasilə olunacaq';
	@override String get sleepTimerEndOfVideo => 'Cari videonun sonu';
	@override String get sleepTimerStopAtHeader => 'Dayanma vaxtı';
	@override String get sleepTimerDurationHeader => 'Taymer';
	@override String get playbackWillPauseAtEnd => 'Oynatma bu videonun sonunda fasilə olunacaq';
	@override String get stillWatching => 'Hələ də baxırsınız?';
	@override String pausingIn({required Object seconds}) => '${seconds}san sonra fasilə edilir';
	@override String get continueWatching => 'Davam et';
	@override String get autoPlayNext => 'Növbətini avtomatik oynat';
	@override String get playNext => 'Növbətini oynat';
	@override String get playButton => 'Oynat';
	@override String get pauseButton => 'Fasilə';
	@override String get playbackPaused => 'Fasilədə';
	@override String get playbackResumed => 'Oynadılır';
	@override String get loadingVideo => 'Video yüklənir';
	@override String get showPlaybackControls => 'Oynatma idarəetmələrini göstər';
	@override String get hidePlaybackControls => 'Oynatma idarəetmələrini gizlət';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} saniyə geri sar';
	@override String seekForwardButton({required Object seconds}) => '${seconds} saniyə irəli sar';
	@override String get previousButton => 'Əvvəlki seriya';
	@override String get nextButton => 'Növbəti seriya';
	@override String get previousChapterButton => 'Əvvəlki hissə';
	@override String get nextChapterButton => 'Növbəti hissə';
	@override String get muteButton => 'Səsi söndür';
	@override String get unmuteButton => 'Səsi aç';
	@override String get settingsButton => 'Oynatma tənzimləmələri';
	@override String get tracksButton => 'Səs və Altyazılar';
	@override String get chaptersButton => 'Hissələr';
	@override String get segmentLoopHelp => 'Bu oxutma zamanı bir bölməni təkrarlayın. Əvvəl A-nı, sonra zaman xəttində daha sonrakı nöqtədə B-ni təyin edin.';
	@override String get setLoopStart => 'Təkrarın başlanğıcını təyin et (A)';
	@override String get setLoopEnd => 'Təkrarın sonunu təyin et (B)';
	@override String get clearSegmentLoop => 'Bölmə təkrarını sil';
	@override String get setLoopStartFirst => 'Əvvəl təkrarın başlanğıcını (A), sonra sonunu (B) təyin edin.';
	@override String get loopEndAfterStart => 'Təkrarın sonu başlanğıcdan sonra olmalıdır.';
	@override String get segmentLoopUnavailable => 'Bu oxutma üçün bölmə təkrarı mövcud deyil.';
	@override String get loopPointNotSet => 'Təyin edilməyib';
	@override String get bookmarksHelp => 'Əlfəcinlər bu cihazda saxlanılır. Həmin vaxta keçmək üçün birini seçin.';
	@override String get bookmarksButton => 'Əlfəcinlər';
	@override String get chaptersAndBookmarks => 'Fəsillər və əlfəcinlər';
	@override String get segmentLoop => 'Bölmə təkrarı';
	@override String get addBookmark => 'Əlfəcin əlavə et';
	@override String get bookmarkName => 'Əlfəcin adı';
	@override String get bookmarkNameHint => 'Məsələn, açılış səhnəsi';
	@override String bookmarkDefaultName({required Object n}) => 'Əlfəcin ${n}';
	@override String get bookmarkNameRequired => 'Bu əlfəcin üçün ad daxil edin.';
	@override String get deleteBookmark => 'Əlfəcini sil';
	@override String get bookmarkLimitReached => 'Bu elementdə artıq 100 əlfəcin var.';
	@override String get bookmarkUnavailable => 'Bu əlfəcini saxlamaq və ya silmək mümkün olmadı.';
	@override String get bookmarkSaved => 'Əlfəcin saxlanıldı.';
	@override String get bookmarkDeleted => 'Əlfəcin silindi.';
	@override String loopPointSet({required Object point, required Object time}) => '${point} təkrar nöqtəsi ${time} vaxtında təyin edildi.';
	@override String get noChaptersOrBookmarks => 'Fəsil və ya əlfəcin yoxdur.';
	@override String get versionQualityButton => 'Versiya və Keyfiyyət';
	@override String get versionColumnHeader => 'Versiya';
	@override String get qualityColumnHeader => 'Keyfiyyət';
	@override String get qualityOriginal => 'Orijinal';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Kod dəyişmə əlçatan deyil — orijinal keyfiyyətdə oynadılır';
	@override String get subtitleUnavailableFallback => 'Seçilmiş altyazı yüklənə bilmədi — altyazısız davam edilir';
	@override String get pipButton => 'Pəncərə daxilində pəncərə rejimi';
	@override String get aspectRatioButton => 'Tərəf nisbəti';
	@override String get ambientLighting => 'Ətraf işıqlandırması';
	@override String get fullscreenButton => 'Tam ekrana keç';
	@override String get exitFullscreenButton => 'Tam ekrandan çıx';
	@override String get alwaysOnTopButton => 'Həmişə üstə';
	@override String get rotationLockButton => 'Dönmə kilidi';
	@override String get lockScreen => 'Ekranı kilidlə';
	@override String get screenLockButton => 'Ekran kilidi';
	@override String get timelineSlider => 'Video zaman çubuğu';
	@override String get volumeSlider => 'Səs səviyyəsi';
	@override String endsAt({required Object time}) => 'Bitiş vaxtı: ${time}';
	@override String get pipActive => 'Pəncərə daxilində pəncərə rejimində oynadılır';
	@override String get pipFailed => 'PiP rejimi başladılarkən xəta';
	@override String get screenshotSaved => 'Ekran şəkli yadda saxlanıldı';
	@override String get screenshotFailed => 'Ekran şəkli çəkilə bilmədi';
	@override String zoomPercent({required Object percent}) => 'Miqyas %${percent}';
	@override String volumePercent({required Object percent}) => 'Səs ${percent}%';
	@override late final _Translations$videoControls$pipErrors$az pipErrors = _Translations$videoControls$pipErrors$az._(_root);
	@override String get chapters => 'Hissələr';
	@override String get noChaptersAvailable => 'Hissələr əlçatan deyil';
	@override String get queue => 'Növbə';
	@override String get noQueueItems => 'Növbədə element yoxdur';
	@override String get noAudioDevicesAvailable => 'Səs cihazları əlçatan deyil';
	@override String get searchSubtitles => 'Altyazı axtar';
	@override String get language => 'Dil';
	@override String get noSubtitlesFound => 'Altyazı tapılmadı';
	@override String get subtitleDownloaded => 'Altyazı yükləndi';
	@override String get subtitleDownloadedNotApplied => 'Altyazı yükləndi, lakin seçilə bilmədi';
	@override String get subtitleDownloadFailed => 'Altyazı yüklənə bilmədi';
	@override String get searchLanguages => 'Dillərdə axtar...';
	@override String get skipIntro => 'Girişi keç';
	@override String get skipCredits => 'Titrləri keç';
	@override String get nextEpisode => 'Növbəti seriya';
	@override String subtitleTrack({required Object n}) => 'Zolaq ${n}';
	@override String subtitleFile({required Object name}) => 'Altyazı ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Məcburi)';
	@override String get osdSubtitlesOff => 'Altyazı: Söndürülüb';
	@override String osdSubtitles({required Object track}) => 'Altyazı: ${track}';
	@override String osdAudio({required Object track}) => 'Səs: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qalıb',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qəlblər',
	);
	@override String get trackSelectionTitle => 'Playback öncə oyun seçin';
	@override String get trackSelectionAuto => 'Automatik seçim';
	@override String get openMiniPlayer => 'Mini oyunçı';
	@override String get returnToFullPlayer => 'Full oyuncuya qayıtmaq';
	@override String get loadSubtitleFile => 'Subtitle filə yükləmək.';
	@override String get subtitleLoadFailed => 'Subtitle filini yüklə bilmədim';
	@override String get skipAds => 'Adlar üçün';
	@override String get tapToUnlock => 'Kilidi açmaq üçün toxunun';
	@override String get tapAgainToUnlock => 'Kilidi açmaq üçün yenidən toxunun';
}

// Path: messages
class _Translations$messages$az extends Translations$messages$en {
	_Translations$messages$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Baxıldı olaraq işarələndi';
	@override String get markedAsUnwatched => 'Baxılmadı olaraq işarələndi';
	@override String get markedAsWatchedOffline => 'Baxıldı olaraq işarələndi (onlayn olduqda eyniləşdiriləcək)';
	@override String get markedAsUnwatchedOffline => 'Baxılmadı olaraq işarələndi (onlayn olduqda eyniləşdiriləcək)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Avtomatik silindi: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: 'Baxılmış ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yükləmə avtomatik silindi',
		other: 'Baxılmış ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yükləmə avtomatik silindi',
	);
	@override String get removedFromContinueWatching => 'İzləməyə davam et-dən silindi';
	@override String errorLoading({required Object error}) => 'Xəta: ${error}';
	@override String get searchPartialResults => 'Bəzi media serverlərində axtarış aparıla bilmədi. Mövcud nəticələr göstərilir.';
	@override String get streamInterrupted => 'Yayım kəsildi. Yenidən cəhd etmək üçün oynat düyməsinə basın və ya irəli-geri çəkin.';
	@override String get liveStreamInterrupted => 'Canlı yayım kəsildi. Təzədən cəhd etmək üçün oynat düyməsinə basın.';
	@override String get fileInfoNotAvailable => 'Fayl məlumatı əlçatan deyil';
	@override String get playbackAuthenticationRequired => 'Bu elementi oynatmaq üçün media serverinə yenidən daxil olun.';
	@override String get playbackServerUnavailable => 'Media serveri əlçatan deyil. Sonra təzədən cəhd edin.';
	@override String get playbackDataInvalid => 'Server yanlış oynatma məlumatı qaytardı.';
	@override String get playbackCancelled => 'Oynatma ləğv edildi.';
	@override String get playbackFailed => 'Oynatma başladılarkən xəta.';
	@override String playbackFailedDetail({required Object error}) => 'Oynatma başladıla bilmədi: ${error}';
	@override String get audioOutputFailed => 'Səs çıxışı cavab verməyi dayandırdı. TV və ya resiverin səs bağlantısını yoxlayın; başqa tətbiqlərdə də səs yoxdursa, cihazı yenidən başladın.';
	@override String get mediaUnavailable => 'Bu məzmun artıq əlçatan deyil.';
	@override String errorLoadingFileInfo({required Object error}) => 'Fayl məlumatı yüklənərkən xəta: ${error}';
	@override String get errorLoadingSeries => 'Serial yüklənərkən xəta';
	@override String get musicNotSupported => 'Musiqi oynatması hələ dəstəklənmir';
	@override String get noDescriptionAvailable => 'Təsvir əlçatan deyil';
	@override String get noProfilesAvailable => 'Profil yoxdur';
	@override String get contactAdminForProfiles => 'Profil əlavə etmək üçün server inzibatçınızla əlaqə saxlayın';
	@override String get unableToDetermineLibrarySection => 'Bu element üçün kitabxana bölməsi müəyyən edilə bilmədi';
	@override String get logsCleared => 'Jurnallar təmizləndi';
	@override String get logsCopied => 'Jurnallar buferə kopyalandı';
	@override String get noLogsAvailable => 'Jurnal yoxdur';
	@override String libraryScanning({required Object title}) => '"${title}" skan edilir...';
	@override String libraryScanStarted({required Object title}) => '"${title}" üçün skan başladı';
	@override String libraryScanFailed({required Object error}) => 'Kitabxana skan edilə bilmədi: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" üçün meta-məlumatlar yenilənir...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" üçün meta-məlumat yenilənməsi başladı';
	@override String metadataRefreshFailed({required Object error}) => 'Meta-məlumatlar yenilənə bilmədi: ${error}';
	@override String get logoutConfirm => 'Çıxış etmək istədiyinizdən əminsiniz?';
	@override String get noSeasonsFound => 'Mövsüm tapılmadı';
	@override String get seasonsLoadFailed => 'Mövsümlər yüklənə bilmədi';
	@override String get noEpisodesFound => 'Birinci mövsümdə seriya tapılmadı';
	@override String get noEpisodesFoundGeneral => 'Seriya tapılmadı';
	@override String get episodesLoadFailed => 'Seriyalar yüklənə bilmədi';
	@override String get noResultsFound => 'Nəticə tapılmadı';
	@override String sleepTimerSet({required Object label}) => 'Yuxu taymeri ${label} üçün təyin edildi';
	@override String get noItemsAvailable => 'Element yoxdur';
	@override String get failedToCreatePlayQueueNoItems => 'Oynatma növbəsi yaradıla bilmədi — element yoxdur';
	@override String failedPlayback({required Object action, required Object error}) => '${action} uğursuz oldu: ${error}';
	@override String get switchingToCompatiblePlayer => 'Uyğun oynadıcıya keçilir...';
	@override String get serverLimitTitle => 'Oynatma uğursuz oldu';
	@override String get serverLimitBody => 'Server xətası (HTTP 500). Məhdudiyyət bu seansı rədd etdi.';
	@override String get mediaUnreadableTitle => 'Fayl əlçatan deyil';
	@override String get mediaUnreadableBody => 'Server bu elementi tapdı, lakin onun faylını oxuya bilmədi (HTTP 404). Fayl yəqin ki, köçürülüb, silinib və ya onun saxlanma yeri oflayndır. Server sahibindən faylı yoxlamasını və kitabxananı yenidən skan etməsini xahiş edin.';
	@override String get serverBusyTitle => 'Yayım əlçatan deyil';
	@override String get serverBusyBody => 'Server bu faylı yayımlamaqdan dəfələrlə imtina etdi (HTTP 503). Server yenidən başladılır və ya məşğul ola bilər, yaxud faylın yerləşdiyi yaddaş oflayn ola bilər. Bir az sonra təzədən cəhd edin — problem davam edərsə, server sahibindən serveri və faylın yerləşdiyi yaddaşı yoxlamasını istəyin.';
	@override String get playbackNotAllowedTitle => 'Oynatmaya icazə verilmir';
	@override String get playbackNotAllowedBody => 'Server bu elementi yayımlamaqdan imtina etdi (HTTP 403). Hesabınızın onu oynatmaq icazəsi olmaya bilər, yaxud server oynatmaya yalnız öz yerli şəbəkəsində icazə verə bilər.';
	@override String get logsUploaded => 'Jurnallar yükləndi';
	@override String get logsUploadFailed => 'Jurnallar yüklənə bilmədi';
	@override String get logId => 'Jurnal ID-si';
	@override String get burnedSubtitlesUseMenu => 'Altyazılar bu yayıma həkk edilib. Onları altyazı menyusundan dəyişin.';
	@override String get noVideoUrl => 'Video URL-i mövcud deyil';
	@override String get playbackNoMediaSources => 'Server oynadıla bilən media mənbəyi qaytarmadı';
	@override String get playbackDataNotPrepared => 'Məlumatları hazır olmadan oynatma başladıldı';
	@override String get streamSelectionUnavailable => 'Bu mənbə üçün yayım seçimi mövcud deyil';
	@override String get streamSelectionFailed => 'Seçilmiş yayımları tətbiq etmək olmadı';
	@override String get trackSelectionNotRemembered => 'Bu trek seçimi yalnız cari oynatmaya tətbiq olunur.';
	@override String get serverUnavailableForProfile => 'Aktiv profil üçün heç bir server mövcud deyil';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$az extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Cəld qəhvəyi tülkü tənbəl itin üstündən tullanır.';
	@override String get text => 'Mətn';
	@override String get border => 'Haşiyə';
	@override String get background => 'Arxa fon';
	@override String get fontSize => 'Şrift ölçüsü';
	@override String get textColor => 'Mətn rəngi';
	@override String get borderSize => 'Haşiyə ölçüsü';
	@override String get borderColor => 'Haşiyə rəngi';
	@override String get backgroundOpacity => 'Arxa fon şəffaflığı';
	@override String get backgroundColor => 'Arxa fon rəngi';
	@override String get position => 'Mövqe';
	@override String get assOverride => 'ASS ləğvi';
	@override String get overrideScale => 'Miqyasla';
	@override String get overrideForce => 'Məcburi et';
	@override String get overrideStrip => 'Formatlaşdırmanı sil';
	@override String get positionTop => 'Yuxarı';
	@override String get positionBottom => 'Aşağı';
	@override String get useMargins => 'Kənar boşluqlardan istifadə et';
	@override String get useMarginsDescription => 'Mətn altyazılarına videodan kənar sahədə icazə ver. Üslublu altyazılar öz orijinal yerləşməsini saxlaya bilər.';
	@override String get anchorToScreen => 'Ekrana bərkit';
	@override String get anchorToScreenDescription => 'Mətn altyazılarını geniş ekranlı videonun altındakı qara zolaqlarda göstər';
	@override String get bold => 'Qalın';
	@override String get italic => 'Kursiv';
	@override String get renderResolution => 'Emal imkanı (Resolution)';
	@override String get renderResolutionScreen => 'Ekran imkanı';
	@override String get renderResolutionVideo => 'Video imkanı';
	@override String get fontSizeDescription => 'Subtitle texti boyutu bu cihazda ayarlayın.';
	@override String get textColorDescription => 'Subtitle texti üçün kullanılan renk seçin.';
	@override String get borderSizeDescription => 'Subtitle texti ilə çevrilər.';
	@override String get borderColorDescription => 'Subtitle üçün kullanılan renk seçin.';
	@override String get backgroundColorDescription => 'Subtitle texti arkasındaki rengi seçin.';
	@override String get backgroundOpacityDescription => 'Subtitle aralığının nə qədər şifrəsi olduğunu ayarlayın: 0% açıq və 100% sabitdir.';
	@override String get positionDescription => 'Yüzde 0 - videonun üstində və % 100 - altındadır.';
	@override String get assOverrideDescription => 'Oynayan oyuncu, düzeltmək, değiştirmək və ya ASS subtitlularına yerleştirilmiş stilini kaldırmaq üçün seçin.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$az assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$az._(_root);
	@override String get renderResolutionDescription => 'Görüntüyü və ASS subtitlesini rasterize etmək üçün kullanılan çözünürlüğünü seçin. Düşük Android ölçeği rendering çalışmasını azalta bilər, amma daha yumuşak görünür.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$az renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$az._(_root);
	@override String get boldDescription => 'Subtitle texti daha ağır bir ağırlıqda çəkilir.';
	@override String get italicDescription => 'İtaliqdə yazılan subtitr texti.';
}

// Path: mpvConfig
class _Translations$mpvConfig$az extends Translations$mpvConfig$en {
	_Translations$mpvConfig$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Təkmilləşdirilmiş video oynatıcı tənzimləmələri';
	@override String get presets => 'Ön ayarlar';
	@override String get noPresets => 'Yadda saxlanılmış ön ayar yoxdur';
	@override String get saveAsPreset => 'Ön ayar kimi yadda saxla...';
	@override String get presetName => 'Ön ayar adı';
	@override String get presetNameHint => 'Bu ön ayar üçün ad daxil edin';
	@override String get loadPreset => 'Yüklə';
	@override String get deletePreset => 'Sil';
	@override String get presetSaved => 'Ön ayar yadda saxlanıldı';
	@override String get presetLoaded => 'Ön ayar yükləndi';
	@override String get presetDeleted => 'Ön ayar silindi';
	@override String get confirmDeletePreset => 'Bu ön ayarı silmək istədiyinizə əminsiniz?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# şərh';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Sətir əlavə et';
	@override String get removeLine => 'Sətiri sil';
	@override String get embeddedVoHint => 'vo, gpu-context və gpu-api Linux-da nəzərə alınmır: daxili video həmişə video müstəvisində vo=libmpv vasitəsilə göstərilir və gpu-next (ArtCNN kimi hesablama şeyderlərinə lazımdır) daxili işləyə bilməz.';
}

// Path: dialog
class _Translations$dialog$az extends Translations$dialog$en {
	_Translations$dialog$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Əməliyyatı təsdiqlə';
}

// Path: profiles
class _Translations$profiles$az extends Translations$profiles$en {
	_Translations$profiles$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'PlezyNG profili əlavə et';
	@override String get switchingProfile => 'Profil dəyişdirilir…';
	@override String get deleteThisProfileTitle => 'Bu profil silinsin?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} silinəcək. Qoşulmalar təsirlənmir.';
	@override String get active => 'Aktiv';
	@override String get manage => 'İdarə et';
	@override String get delete => 'Sil';
	@override String get signOut => 'Çıxış et';
	@override String get signOutPlexTitle => 'Plex-dən çıxılsın?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} və bütün Plex Home istifadəçiləri silinsin? İstənilən vaxt yenidən daxil ola bilərsiniz.';
	@override String get signOutPlexDeleteDownloads => 'Yükləmələri də sil';
	@override String get signOutPlexDeleteDownloadsDescription => 'Əks halda onlar bu cihazda qalır və bu hesaba yenidən daxil olduqda geri qayıdır.';
	@override String get signedOutPlex => 'Plex-dən çıxıldı.';
	@override String get signOutFailed => 'Çıxış uğursuz oldu.';
	@override String get sectionTitle => 'Profillər';
	@override String get summarySingle => 'İdarə olunan istifadəçiləri və yerli kimlikləri qarışdırmaq üçün profillər əlavə edin';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profil · aktiv: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profil';
	@override String get removeConnectionTitle => 'Qoşulma silinsin?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName} istifadəçisinin ${connectionLabel} giriş hüququ silinəcək. Digər profillərdə qalacaq.';
	@override String get deleteProfileTitle => 'Profil silinsin?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} və onun qoşulmaları silinəcək. Serverlər əlçatan qalır.';
	@override String get profileNameLabel => 'Profil adı';
	@override String get pinProtectionLabel => 'PIN mühafizəsi';
	@override String get copyAutomationLink => 'Android avtomatizasiya bağlantısı';
	@override String get copyAutomationLinkDescription => 'Bu profili Android və ya avtomatizasiyadan seçin.Profil PIN kontrolları hala geçerlidir.';
	@override String get automationLinkCopied => 'Profile avtomatizasiyası kopyalanır.';
	@override String get pinManagedByPlex => 'PIN Plex tərəfindən idarə olunur. plex.tv-də düzəliş edin.';
	@override String get noPinSetEditOnPlex => 'PIN təyin edilməyib. Tələb etmək üçün plex.tv-də düzəliş edin.';
	@override String get setPin => 'PIN təyin et';
	@override String get setPinTitle => 'PIN təyin et';
	@override String get confirmPinTitle => 'PIN-i təsdiqlə';
	@override String get pinSet => 'PIN təyin edildi';
	@override String get changePin => 'Dəyişdir';
	@override String get removePin => 'Sil';
	@override String get connectionsLabel => 'Qoşulmalar';
	@override String get add => 'Əlavə et';
	@override String get deleteProfileButton => 'Profili sil';
	@override String get noConnectionsHint => 'Qoşulma yoxdur — bu profili istifadə etmək üçün birini əlavə edin.';
	@override String get noConnections => 'Qoşulma yoxdur';
	@override String get plexHomeAccount => 'Plex Ev hesabı';
	@override String plexAccountChip({required Object account}) => 'Plex hesabı: ${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account} hesabı vasitəsilə ${user}';
	@override String get connectionDefault => 'Defolt';
	@override String connectionAs({required Object displayName}) => '${displayName} olaraq';
	@override String get makeDefault => 'Defolt et';
	@override String get removeConnection => 'Sil';
	@override String get profileRenamed => 'Profil adı dəyişdirildi.';
	@override String borrowAddTo({required Object displayName}) => '${displayName} profilinə əlavə et';
	@override String get borrowExplain => 'Başqa profilin qoşulmasını istifadə edin. PIN ilə qorunan profillər PIN tələb edir.';
	@override String get borrowEmpty => 'Hələ istifadə ediləcək bir şey yoxdur.';
	@override String get borrowEmptySubtitle => 'Əvvəlcə başqa bir profile Plex, Jellyfin və ya Emby qoşun.';
	@override String get borrowLoadFailed => 'Əlçatan qoşulmalar yüklənə bilmədi. Təzədən cəhd edin.';
	@override String borrowFromProfile({required Object displayName}) => '${displayName} profilindən';
	@override String get borrowConnectionBorrowed => 'Qoşulma istifadə edildi.';
	@override String get borrowFailed => 'Qoşulma istifadə edilə bilmədi.';
	@override String get incorrectPin => 'Səhv PIN.';
	@override String get incorrectPinTryAgain => 'Səhv PIN. Lütfən təzədən cəhd edin.';
	@override String get sourceProfileMissingParentAccount => 'Mənbə profilin əsas hesabı yoxdur.';
	@override String get failedToLoadHomeUsers => 'Plex Home istifadəçiləriniz yüklənə bilmədi. Bağlantınızı yoxlayın və yenidən cəhd edin.';
	@override String get failedToVerifyPin => 'PIN təsdiqlənə bilmədi.';
	@override String get newProfile => 'Yeni profil';
	@override String get profileNameHint => 'məs. Qonaqlar, Uşaqlar, Qonaq otağı';
	@override String get pinProtectionOptional => 'PIN mühafizəsi (istəyə bağlı)';
	@override String get pinExplain => 'Profillər arası keçid üçün 4 rəqəmli PIN tələb olunur.';
	@override String get continueButton => 'Davam et';
	@override String get pinsDontMatch => 'PIN-lər uyğun gəlmir';
	@override String get tokenIdentityMismatch => 'Plex profil tokeni gözlənilməyən serveri müəyyən etdi';
	@override String get settingsLocked => 'Bu profillərin qalıb olması üçün bu profillərin qalıb olmasıdır.';
	@override String get unlockSettings => 'Qatırılma';
	@override String get showExploreForProfile => 'Bu profillə baxın';
	@override String get showExploreForProfileDescription => 'Bu profillərin navigasiyasından Explore-i kaldırmaq üçün açılın.';
}

// Path: connections
class _Translations$connections$az extends Translations$connections$en {
	_Translations$connections$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Qoşulmalar';
	@override String get addConnection => 'Qoşulma əlavə et';
	@override String get addConnectionSubtitleNoProfile => 'Plex ilə daxil olun və ya Jellyfin yaxud Emby serverinə qoşulun';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName} profilinə əlavə et: Plex, Jellyfin, Emby və ya başqa profil qoşulması';
	@override String sessionExpiredOne({required Object name}) => '${name} üçün seansın vaxtı bitdi';
	@override String sessionExpiredMany({required Object count}) => '${count} server üçün seansın vaxtı bitdi';
	@override String accessDeniedOne({required Object name}) => '${name} bu hesaba girişi rədd etdi';
	@override String accessDeniedMany({required Object count}) => '${count} server bu hesaba girişi rədd etdi';
	@override String get signInAgain => 'Yenidən daxil ol';
	@override String editMediaBrowserTitle({required Object product}) => '${product} qoşulmasını düzəliş et';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName} üçün URL-lər əlavə edin və ya silin. PlezyNG əlçatan olan ən aşağı gecikməli URL-i istifadə edəcək.';
}

// Path: accountPreferences
class _Translations$accountPreferences$az extends Translations$accountPreferences$en {
	_Translations$accountPreferences$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Hesab tərcihləri';
	@override String hubSubtitleSingle({required Object account}) => '${account} hesabında saxlanılan səs, altyazı və kitabxana seçimləri';
	@override String hubSubtitleMultiple({required Object count}) => '${count} hesabda saxlanılan səs, altyazı və kitabxana seçimləri';
	@override String get pickAccount => 'Hər hesab öz tərcihlərini saxlayır. Düzəliş etmək üçün birini seçin.';
	@override String get storedOnAccount => 'Bu seçimlər hesabın özündə saxlanılır, ona görə də ona daxil olan hər tətbiq onlardan istifadə edir — digər cihazlarınızdakı PlezyNG də daxil olmaqla.';
	@override String get noAccounts => 'Konfiqurasiya ediləcək hesab yoxdur';
	@override String get noAccountsHint => 'Plex-ə daxil olun və ya Jellyfin və ya Emby serverinə qoşulun; o hesabda saxlanılan tərcihlər burada görünəcək.';
	@override String get unavailable => 'Bu hesaba çatmaq olmur';
	@override String get loadFailed => 'Bu tərcihlər yüklənə bilmədi';
	@override String get noPreference => 'Tərcih yoxdur';
	@override String get notSet => 'Təyin edilməyib';
	@override late final _Translations$accountPreferences$groups$az groups = _Translations$accountPreferences$groups$az._(_root);
	@override String get preferredAudioLanguage => 'Üstünlük verilən səs dili';
	@override String get autoSelectAudio => 'Səsi dilə görə seç';
	@override String get autoSelectAudioDescription => 'Söndürüldükdə faylın defolt olaraq işarələdiyi səs treki istifadə olunur.';
	@override String get preferredSubtitleLanguage => 'Üstünlük verilən altyazı dili';
	@override String get subtitleMode => 'Altyazıları aç';
	@override late final _Translations$accountPreferences$subtitleModes$az subtitleModes = _Translations$accountPreferences$subtitleModes$az._(_root);
	@override String get subtitleAccessibility => 'SDH altyazıları';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$az subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$az._(_root);
	@override String get forcedSubtitles => 'Məcburi altyazılar';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$az forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$az._(_root);
	@override String get displayMissingEpisodes => 'Çatışmayan seriyaları göstər';
	@override String get displayMissingEpisodesDescription => 'Serverin bildiyi, lakin faylı olmayan seriyaları siyahıya al.';
	@override String get hidePlayedInLatest => 'Baxılmış elementləri Son əlavə olunanlarda gizlət';
	@override String get hidePlayedInLatestDescription => 'Artıq baxdığınız elementləri serverin Son əlavə olunanlar sətirlərində göstərmə.';
	@override String get displayCollectionsView => 'Kolleksiyalar görünüşünü göstər';
	@override String get displayCollectionsViewDescription => 'Kitabxanalarınızla yanaşı serverin Kolleksiyalar görünüşünü də təklif et.';
	@override String get rewatchingInNextUp => 'Təkrar baxılan serialları Sırada saxla';
	@override String get rewatchingInNextUpDescription => 'Bir serialı bitirdikdən sonra yenidən başlasanız, Sırada serialı atmaq əvəzinə təkrar baxışı izləyir.';
	@override String get watchedIndicator => 'Baxıldı göstəriciləri';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$az watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$az._(_root);
	@override String get mediaReviewsVisibility => 'Reytinq və rəylər';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$az mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$az._(_root);
	@override String get preferredAudioLanguageDescription => 'Bu dildə audio izləri tercih edər ki, sunucu və ya oynatıcı otomatik olarak bir izi seçer.';
	@override String get preferredSubtitleLanguageDescription => 'Subtitles automatik olaraq seçildiğinde bu dildə subtitles izləri tercih edilir.';
	@override String get subtitleAccessibilityDescription => 'SDH qapsiyaları automatik subtitle seçimi sırasında tercih edilir və ya gerektirir.';
	@override String get forcedSubtitleDescription => 'Seçin ki, automatik seçimdə zorunlu alt başlık izləri tercih edilir və ya gerektirir.';
	@override String get watchedIndicatorDescription => 'Həkimlər, server interfejsində gözləmiş bir kontrol işareti aldığını seçin.';
	@override String get mediaReviewsVisibilityDescription => 'Həyatçıların və müştərinin hədisində nə olduğunu seçin.';
	@override String get subtitleModeDescription => 'Subtitles bu server hesabı üçün automatik olarak açılırsa seçin.';
	@override String get hubDescription => 'Bu seçeneklər Media-server hesabınızda saxlanır və diğer müştərilər üçün də geçerlidir.';
}

// Path: discover
class _Translations$discover$az extends Translations$discover$en {
	_Translations$discover$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kəşf et';
	@override String get noContentAvailable => 'Məzmun əlçatan deyil';
	@override String get addMediaToLibraries => 'Kitabxanalarınıza bir az media əlavə edin';
	@override String get continueWatching => 'İzləməyə davam et';
	@override String continueWatchingIn({required Object library}) => '${library} daxilində İzləməyə davam et';
	@override String get nextUp => 'Sırada';
	@override String nextUpIn({required Object library}) => '${library} daxilində Sırada';
	@override String get recentlyAdded => 'Son əlavə olunanlar';
	@override String recentlyAddedIn({required Object library}) => '${library} daxilində Son əlavə olunanlar';
	@override String latestAlbumsIn({required Object library}) => '${library} daxilində Son albomlar';
	@override String recentlyPlayedIn({required Object library}) => '${library} daxilində Son oynadılanlar';
	@override String mostPlayedIn({required Object library}) => '${library} daxilində Ən çox oynadılanlar';
	@override String playEpisode({required Object season, required Object episode}) => 'M${season}S${episode}';
	@override String get overview => 'İcmal';
	@override String get cast => 'Aktyorlar';
	@override late final _Translations$discover$findNext$az findNext = _Translations$discover$findNext$az._(_root);
	@override String get extras => 'Treylerlər və Əlavələr';
	@override String get studio => 'Studiya';
	@override String get rating => 'Reytinq';
	@override String get director => 'Rejissor';
	@override String get directors => 'Rejissorlar';
	@override String get movie => 'Kino';
	@override String get tvShow => 'TV Şou';
	@override String minutesLeft({required Object minutes}) => '${minutes} dəq qaldı';
	@override String get moreLikeThis => 'Buna bənzərlər';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başlıq',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başlıq',
	);
	@override late final _Translations$discover$person$az person = _Translations$discover$person$az._(_root);
}

// Path: errors
class _Translations$errors$az extends Translations$errors$en {
	_Translations$errors$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Axtarış uğursuz oldu: ${error}';
	@override String get searchUnavailable => 'Axtarış heç bir media serverinə çata bilmədi.';
	@override String connectionTimeout({required Object context}) => '${context} yüklənərkən vaxt bitdi';
	@override String get connectionFailed => 'Media serverinə qoşulmaq olmur';
	@override String unableToLoad({required Object context}) => '${context} yüklənə bilmədi. Lütfən təzədən cəhd edin.';
	@override String get noClientAvailable => 'Əlçatan klient yoxdur';
	@override String get pleaseEnterToken => 'Lütfən token daxil edin';
	@override String get invalidToken => 'Yanlış token';
	@override String failedToVerifyToken({required Object error}) => 'Token təsdiqlənə bilmədi: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName} profilinə keçilə bilmədi';
	@override String failedToDeleteProfile({required Object displayName}) => '${displayName} profili silinə bilmədi';
	@override String get failedToRate => 'Reytinq yenilənə bilmədi';
	@override String get reasonTimedOut => 'bağlantının vaxtı bitdi';
	@override String get reasonUnreachable => 'serverə çatmaq mümkün olmadı';
	@override String get reasonRefused => 'server sorğunu rədd etdi';
	@override String get reasonNotFound => 'element artıq serverdə yoxdur';
	@override String get reasonServerError => 'server xəta bildirdi';
	@override String get reasonCancelled => 'sorğu ləğv edildi';
	@override String get reasonUnexpected => 'gözlənilməz xəta baş verdi';
}

// Path: libraries
class _Translations$libraries$az extends Translations$libraries$en {
	_Translations$libraries$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Xatırıq filmini oynayır';
	@override String get randomPickFailed => 'Bu kütüphanadan bir film seçmək mümkün deyil.';
	@override String get title => 'Kitabxanalar';
	@override String get fallbackTitle => 'Kitabxana';
	@override String get scanLibraryFiles => 'Kitabxana fayllarını skan et';
	@override String get scanLibrary => 'Kitabxananı skan et';
	@override String get analyze => 'Analiz et';
	@override String get analyzeLibrary => 'Kitabxananı analiz et';
	@override String get refreshMetadata => 'Meta-məlumatları yenilə';
	@override String get emptyTrash => 'Zibil qutusunu təmizlə';
	@override String emptyingTrash({required Object title}) => '"${title}" üçün zibil qutusu təmizlənir...';
	@override String trashEmptied({required Object title}) => '"${title}" üçün zibil qutusu təmizləndi';
	@override String failedToEmptyTrash({required Object error}) => 'Zibil qutusu təmizlənə bilmədi: ${error}';
	@override String analyzing({required Object title}) => '"${title}" analiz edilir...';
	@override String analysisStarted({required Object title}) => '"${title}" üçün analiz başladı';
	@override String failedToAnalyze({required Object error}) => 'Kitabxana analiz edilə bilmədi: ${error}';
	@override String get noLibrariesFound => 'Kitabxana tapılmadı';
	@override String get allLibrariesHidden => 'Bütün kitabxanalar gizlədilib';
	@override String hiddenLibrariesCount({required Object count}) => 'Gizli kitabxanalar (${count})';
	@override String get thisLibraryIsEmpty => 'Bu kitabxana boşdur';
	@override String get noItemsMatchFilters => 'Filtrlərə uyğun element tapılmadı';
	@override String get resetFilters => 'Filtrləri sıfırla';
	@override String get all => 'Hamısı';
	@override String get clearAll => 'Hamısını təmizlə';
	@override String scanLibraryConfirm({required Object title}) => '"${title}" kitabxanasını skan etmək istədiyinizdən əminsiniz?';
	@override String analyzeLibraryConfirm({required Object title}) => '"${title}" kitabxanasını analiz etmək istədiyinizdən əminsiniz?';
	@override String refreshMetadataConfirm({required Object title}) => '"${title}" üçün meta-məlumatları yeniləmək istədiyinizdən əminsiniz?';
	@override String emptyTrashConfirm({required Object title}) => '"${title}" üçün zibil qutusunu təmizləmək istədiyinizdən əminsiniz?';
	@override String get manageLibraries => 'Kitabxanaları idarə et';
	@override String get sort => 'Sırala';
	@override String get sortBy => 'Sıralama meyarı';
	@override String get filters => 'Filtrlər';
	@override String get confirmActionMessage => 'Bu əməliyyatı yerinə yetirmək istədiyinizdən əminsiniz?';
	@override String get showLibrary => 'Kitabxananı göstər';
	@override String get hideLibrary => 'Kitabxananı gizlət';
	@override String get libraryOptions => 'Kitabxana seçimləri';
	@override String get content => 'kitabxana məzmunu';
	@override String get selectLibrary => 'Kitabxana seç';
	@override String filtersWithCount({required Object count}) => 'Filtrlər (${count})';
	@override String get noRecommendations => 'Tövsiyə yoxdur';
	@override String get noCollections => 'Bu kitabxanada kolleksiya yoxdur';
	@override String get noFoldersFound => 'Qovluq tapılmadı';
	@override String get folders => 'qovluqlar';
	@override late final _Translations$libraries$tabs$az tabs = _Translations$libraries$tabs$az._(_root);
	@override late final _Translations$libraries$groupings$az groupings = _Translations$libraries$groupings$az._(_root);
	@override late final _Translations$libraries$filterCategories$az filterCategories = _Translations$libraries$filterCategories$az._(_root);
	@override late final _Translations$libraries$sortLabels$az sortLabels = _Translations$libraries$sortLabels$az._(_root);
	@override late final _Translations$libraries$advancedFilters$az advancedFilters = _Translations$libraries$advancedFilters$az._(_root);
	@override late final _Translations$libraries$selection$az selection = _Translations$libraries$selection$az._(_root);
}

// Path: about
class _Translations$about$az extends Translations$about$en {
	_Translations$about$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Haqqında';
	@override String get openSourceLicenses => 'Açıq mənbə lisenziyaları';
	@override String versionLabel({required Object version}) => 'Versiya ${version}';
	@override String get appDescription => 'Flutter üçün gözəl bir Plex, Jellyfin və Emby klienti';
	@override String get viewLicensesDescription => 'Üçüncü tərəf kitabxanalarının lisenziyalarına baxın';
	@override String get privacyPolicy => 'Məxfilik Siyasəti';
}

// Path: serverSelection
class _Translations$serverSelection$az extends Translations$serverSelection$en {
	_Translations$serverSelection$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email}) üçün server tapılmadı';
	@override String failedToLoadServers({required Object error}) => 'Serverlər yüklənə bilmədi: ${error}';
	@override String get noValidServers => 'Bu hesabda istifadəyə yararlı server tapılmadı';
}

// Path: hubDetail
class _Translations$hubDetail$az extends Translations$hubDetail$en {
	_Translations$hubDetail$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Başlıq';
	@override String get releaseYear => 'Buraxılış ili';
	@override String get dateAdded => 'Əlavə olunma tarixi';
	@override String get rating => 'Reytinq';
	@override String get noItemsFound => 'Element tapılmadı';
}

// Path: logs
class _Translations$logs$az extends Translations$logs$en {
	_Translations$logs$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Jurnalları təmizlə';
	@override String get copyLogs => 'Jurnalları kopyala';
	@override String get uploadLogs => 'Jurnalları yüklə';
	@override String get saveLogs => 'Filə yazmaq';
	@override String logsSaved({required Object path}) => 'Xatırılan sayı: ${path}';
	@override String get saveLogsFailed => 'Bu log dosyasını saxlamamışdır.';
}

// Path: startup
class _Translations$startup$az extends Translations$startup$en {
	_Translations$startup$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG başlaya bilmədi';
	@override String get failedBody => 'Başlatma zamanı nəsə səhv getdi. Aşağıdakı təfərrüatlar nəyin uğursuz olduğunu göstərir.';
	@override String get failedBodyRepairable => 'PlezyNG-nin saxlanmış tənzimləmə faylı zədələnib və PlezyNG başlamazdan əvvəl yenidən qurulmalıdır. Təzədən cəhd etmək kömək etməyəcək — Yaddaşı təmir et seçin.';
	@override String get phaseLabel => 'Addım';
	@override String get showDetails => 'Təfərrüatları göstər';
	@override String get hideDetails => 'Təfərrüatları gizlət';
	@override String get copyDetails => 'Təfərrüatları kopyala';
	@override String get detailsCopied => 'Təfərrüatlar buferə kopyalandı';
	@override String get uploadDetails => 'Təfərrüatları yüklə';
	@override String get repairStorage => 'Yaddaşı təmir et';
	@override String get repairTitle => 'Saxlanmış məlumatlar təmir edilsin?';
	@override String get repairBodyCommon => 'PlezyNG-nin tənzimləmə faylı zədələnib və oxuna bilmir. Təmir bütün tənzimləmələri defolt vəziyyətinə sıfırlayır.';
	@override String get repairBodyOneCredential => 'Bir saxlanmış daxil olma məlumatı zədələnib və oxuna bilmir. Təmir yalnız onu silir; digər tənzimləmələrinizə toxunulmur.';
	@override String get repairBodySignInsKept => 'Serverləriniz və profilləriniz daxil olmuş vəziyyətdə qalmalıdır.';
	@override String get repairBodySignInsLost => 'Saxlanmış daxil olmalarınızı qoruyan açar bu fayldan bərpa edilə bilmir, ona görə də hər serverə və profilə yenidən daxil olmalı olacaqsınız. Media serverinizdə heç nəyə təsir olunmur.';
	@override String get repairBodySessionsUncertain => 'İzləyicilər (MAL, AniList, Simkl, Trakt) və Seerr ayrıca saxlanılır və qalıb-qalmayacaqları bəlli deyil. PlezyNG sizə nəyi saxladığını dəqiq bildirəcək.';
	@override String get repairConfirm => 'Təmir et';
	@override String get repairSucceeded => 'Yaddaş təmir edildi';
	@override String get repairNeedsRestart => 'Yaddaş təmir edildi — yenidən başlatma tələb olunur';
	@override String get restartRequiredBody => 'Məlumatlarınız təmir edildi, lakin PlezyNG ondan istifadə etmək üçün yenidən başlamalıdır. PlezyNG-ni bağlayın və yenidən açın.';
	@override String get quitPlezy => 'PlezyNG-dən çıx';
	@override String get repairFailed => 'Təmir uğursuz oldu';
	@override String get repairKeptSignIns => 'Serverləriniz və profilləriniz hələ də daxil olub.';
	@override String get repairLostSignIns => 'Saxlanmış daxil olmalarınızı qoruyan açar bərpa edilə bilmədi. Hər serverə və profilə yenidən daxil olmalı olacaqsınız.';
	@override String get repairLostSessions => 'Ən azı bir izləyici və ya Seerr əlaqəsi itirildi və yenidən qoşulmalıdır.';
	@override String get backupTitle => 'Zədələnmiş faylın nüsxəsi saxlanıldı';
	@override String get backupWarning => 'O, daxil olma məlumatlarınızı ehtiva edir. Onu yükləməyin və ya paylaşmayın.';
	@override String get deleteBackup => 'Nüsxəni sil';
	@override String get backupDeleted => 'Nüsxə silindi.';
	@override String get previousFailureTitle => 'PlezyNG son dəfə başlaya bilmədi';
}

// Path: licenses
class _Translations$licenses$az extends Translations$licenses$en {
	_Translations$licenses$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Əlaqəli paketlər';
	@override String get license => 'Lisenziya';
	@override String licenseNumber({required Object number}) => 'Lisenziya ${number}';
	@override String licensesCount({required Object count}) => '${count} lisenziya';
}

// Path: navigation
class _Translations$navigation$az extends Translations$navigation$en {
	_Translations$navigation$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Kitabxanalar';
	@override String get downloads => 'Yükləmələr';
	@override String get liveTv => 'Canlı TV';
	@override String get explore => 'Kəşf et';
}

// Path: explore
class _Translations$explore$az extends Translations$explore$en {
	_Translations$explore$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$az mdblistShelves = _Translations$explore$mdblistShelves$az._(_root);
	@override String get title => 'Kəşf et';
	@override String get selectSource => 'Mənbə seçin';
	@override late final _Translations$explore$rows$az rows = _Translations$explore$rows$az._(_root);
	@override late final _Translations$explore$status$az status = _Translations$explore$status$az._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriya',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriya',
	);
	@override String get cast => 'Aktyorlar';
	@override String get characters => 'Personajlar';
	@override String get addToWatchlist => 'İzləmə siyahısına əlavə et';
	@override String get removeFromWatchlist => 'İzləmə siyahısından sil';
	@override String get addedToWatchlist => 'Baxış siyahısına əlavə edildi';
	@override String get removedFromWatchlist => 'Baxış siyahısından silindi';
	@override String get watchlistUpdateFailed => 'İzləmə siyahısı yenilənə bilmədi';
	@override String get watchlistNoMatch => 'Bu elementi heç bir baxış siyahısı ilə uyğunlaşdırmaq olmadı';
	@override String get notInLibrary => 'Kitabxananızda yoxdur';
	@override String get inTheseLibraries => 'Bu kitabxanalarda var';
	@override String get checkingLibrary => 'Kitabxananız yoxlanılır...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveri yoxlamaq olmadı',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveri yoxlamaq olmadı',
	);
	@override String get emptyTitle => 'Hələlik burada heç nə yoxdur';
	@override String emptyMessage({required Object source}) => '${source} mənbəsindən olan sətirlər burada görünəcək.';
	@override String searchHint({required Object source}) => '${source} daxilində axtar';
	@override String searchEmpty({required Object query}) => '"${query}" üçün nəticə tapılmadı';
	@override String searchPrompt({required Object source}) => '${source} vasitəsilə kino və seriallar axtarın.';
	@override String get searchFailed => 'Axtarış uğursuz oldu. Bağlantınızı yoxlayın və yenidən cəhd edin.';
	@override late final _Translations$explore$badge$az badge = _Translations$explore$badge$az._(_root);
	@override late final _Translations$explore$stats$az stats = _Translations$explore$stats$az._(_root);
	@override late final _Translations$explore$season$az season = _Translations$explore$season$az._(_root);
	@override late final _Translations$explore$format$az format = _Translations$explore$format$az._(_root);
	@override late final _Translations$explore$sourceMaterial$az sourceMaterial = _Translations$explore$sourceMaterial$az._(_root);
	@override late final _Translations$explore$creditRole$az creditRole = _Translations$explore$creditRole$az._(_root);
	@override late final _Translations$explore$relation$az relation = _Translations$explore$relation$az._(_root);
	@override String broadcast({required Object day, required Object time}) => '${day} saat ${time}-da yayımlanır';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => '${day} saat ${time} (${timezone}) yayımlanır';
	@override late final _Translations$explore$detail$az detail = _Translations$explore$detail$az._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nəticə',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nəticə',
	);
}

// Path: liveTv
class _Translations$liveTv$az extends Translations$liveTv$en {
	_Translations$liveTv$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Canlı TV';
	@override String get guide => 'Bələdçi';
	@override String get noChannels => 'Əlçatan kanal yoxdur';
	@override String get noDvr => 'Serverdə DVR tənzimlənməyib';
	@override String get serverUnavailable => 'Canlı TV serveri əlçatan deyil.';
	@override String get serverNotConnected => 'Canlı TV serverinə qoşulmayıb.';
	@override String get noPrograms => 'Proqram məlumatı yoxdur';
	@override String get liveStreamFailed => 'Canlı yayım uğursuz oldu';
	@override String get unknownProgram => 'Bilinməyən proqram';
	@override String get timelineLiveProgram => 'Live program (playback bu programın dışında olacaq)';
	@override String get timelineBuffer => 'Buffer zamanlama';
	@override String get timelineUnavailable => 'Saatlər mevcut deyil';
	@override String get timelineEstimated => 'Playback-in çox sayısı';
	@override String get timelinePending => 'Qadınlar arama';
	@override String get timelineStale => 'Tarihdə yaşlanmaq mümkündür.';
	@override String get unknownHub => 'Məlum deyil';
	@override String get unknownError => 'Bilinməyən xəta';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Bilinməyən kanal';
	@override String get live => 'CANLI';
	@override String get premiereBadge => 'Yeni';
	@override String get reloadGuide => 'Bələdçini yenilə';
	@override String get searchGuide => 'Bələdçidə axtar';
	@override String get searchHint => 'Kanal və proqram axtar';
	@override String searchNoResults({required Object query}) => '"${query}" üçün uyğunluq tapılmadı';
	@override String get channelsSection => 'Kanallar';
	@override String get programsSection => 'Proqramlar';
	@override String get now => 'İndi';
	@override String get today => 'Bu gün';
	@override String get tomorrow => 'Sabah';
	@override String get midnight => 'Gecə yarısı';
	@override String get overnight => 'Gecə boyu';
	@override String get morning => 'Səhər';
	@override String get daytime => 'Gündüz';
	@override String get evening => 'Axşam';
	@override String get lateNight => 'Gecə vaxtı';
	@override String get whatsOn => 'İndi nə var?';
	@override String get watchChannel => 'Kanala bax';
	@override String get favorites => 'Sevimlilər';
	@override String get reorderFavorites => 'Sevimliləri yenidən sırala';
	@override String get noFavoriteChannels => 'Sevimli kanal yoxdur';
	@override String get noFavoriteChannelsHint => 'Bütün kanalları göstərin, sonra kanalı sevimlilərə əlavə etmək üçün üzərinə uzun basın.';
	@override String get showAllChannels => 'Bütün kanalları göstər';
	@override String get favoritesLoadFailed => 'Sevimlilər yüklənə bilmədi. Bağlantınızı yoxlayın və yenidən cəhd edin.';
	@override String get favoritesUpdateFailed => 'Sevimlilər yenilənə bilmədi.';
	@override String get joinSession => 'Davam edən seansa qoşul';
	@override String watchFromStart({required Object minutes}) => 'Əvvəldən bax (${minutes} dəq əvvəl)';
	@override String get watchLive => 'Canlı bax';
	@override String get goToLive => 'Canlı yayıma keç';
	@override String get record => 'Yaz';
	@override String get recordEpisode => 'Seriyanı yaz';
	@override String get recordSeries => 'Serialı yaz';
	@override String get recordOptions => 'Yazma seçimləri';
	@override String get saveTo => 'Buraya saxla';
	@override String get recordings => 'Yazılmışlar';
	@override String get scheduledRecordings => 'Planlaşdırılmışlar';
	@override String get recordingRules => 'Yazma qaydaları';
	@override String get noScheduledRecordings => 'Yazılacaq heç nə planlaşdırılmayıb';
	@override String get manageRecording => 'Yazmanı idarə et';
	@override String get cancelRecording => 'Yazmanı ləğv et';
	@override String get cancelRecordingTitle => 'Bu yazma ləğv edilsin?';
	@override String cancelRecordingMessage({required Object title}) => '${title} artıq yazılmayacaq.';
	@override String get deleteRule => 'Qaydanı sil';
	@override String get deleteRuleTitle => 'Yazma qaydası silinsin?';
	@override String deleteRuleMessage({required Object title}) => '${title} serialının gələcək seriyaları yazılmayacaq.';
	@override String get recordingScheduled => 'Yazma planlaşdırıldı';
	@override String get alreadyScheduled => 'Bu proqram artıq planlaşdırılıb';
	@override String get dvrAdminRequired => 'DVR tənzimləmələri inzibatçı hesabı tələb edir';
	@override String get recordingFailed => 'Yazma planlaşdırıla bilmədi';
	@override String get recordingTargetMissing => 'Yazma kitabxanası müəyyən edilə bilmədi';
	@override String get recordNotAvailable => 'Bu proqram üçün yazma əlçatan deyil';
	@override String get recordingCancelled => 'Yazma ləğv edildi';
	@override String get recordingRuleDeleted => 'Yazma qaydası silindi';
	@override String get processRecordingRules => 'Qaydaları yenidən qiymətləndir';
	@override String get recordingInProgress => 'İndi yazılır';
	@override String recordingsCount({required Object count}) => '${count} planlaşdırılıb';
	@override String get editRule => 'Qaydanı dəyişdir';
	@override String get editRuleAction => 'Düzəliş et';
	@override String get recordingRuleUpdated => 'Yazma qaydası yeniləndi';
	@override String get guideReloadRequested => 'Bələdçi yenilənməsi tələb olundu';
	@override String get guideReloadFailed => 'Bələdçi yenilənmədi';
	@override String get rulesProcessRequested => 'Qaydaların yenidən qiymətləndirilməsi tələb olundu';
	@override String get rulesProcessFailed => 'Yazı qaydaları yenidən qiymətləndirilmədi';
	@override String get recordShow => 'Şounu yaz';
	@override late final _Translations$liveTv$recordSettings$az recordSettings = _Translations$liveTv$recordSettings$az._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} dəq sonra başlayır';
	@override String dayAtTime({required Object day, required Object time}) => '${day}, saat ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} etibarsız Canlı TV oynatma məlumatı qaytardı';
	@override String get failedToStartChannel => 'Canlı kanalı başlatmaq olmadı';
	@override String get failedToBuildStreamUrl => 'Yayım URL-i yaratmaq olmadı';
	@override String playbackStartFailed({required Object reason}) => 'Kanal başladıla bilmədi: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Kanal dəyişdirilə bilmədi: ${reason}';
}

// Path: collections
class _Translations$collections$az extends Translations$collections$en {
	_Translations$collections$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kolleksiyalar';
	@override String get collection => 'Kolleksiya';
	@override String get empty => 'Kolleksiya boşdur';
	@override String get deleteCollection => 'Kolleksiyanı sil';
	@override String deleteConfirm({required Object title}) => '"${title}" silinsin? Bu əməliyyat geri qaytarıla bilməz.';
	@override String get deleted => 'Kolleksiya silindi';
	@override String get deleteFailed => 'Kolleksiya silinə bilmədi';
	@override String deleteFailedWithError({required Object error}) => 'Kolleksiya silinə bilmədi: ${error}';
	@override String get selectCollection => 'Kolleksiya seç';
	@override String get collectionName => 'Kolleksiya adı';
	@override String get enterCollectionName => 'Kolleksiya adını daxil edin';
	@override String get addedToCollection => 'Kolleksiyaya əlavə edildi';
	@override String get errorAddingToCollection => 'Kolleksiyaya əlavə edilə bilmədi';
	@override String get created => 'Kolleksiya yaradıldı';
	@override String get removeFromCollection => 'Kolleksiyadan sil';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" bu kolleksiyadan silinsin?';
	@override String get removedFromCollection => 'Kolleksiyadan silindi';
	@override String get removeFromCollectionFailed => 'Kolleksiyadan silinə bilmədi';
	@override String removeFromCollectionError({required Object error}) => 'Kolleksiyadan silinərkən xəta: ${error}';
	@override String get searchCollections => 'Kolleksiyalarda axtar...';
}

// Path: playlists
class _Translations$playlists$az extends Translations$playlists$en {
	_Translations$playlists$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oynatma siyahıları';
	@override String get playlist => 'Oynatma siyahısı';
	@override String get noPlaylists => 'Oynatma siyahısı tapılmadı';
	@override String get create => 'Oynatma siyahısı yarat';
	@override String get playlistName => 'Oynatma siyahısı adı';
	@override String get enterPlaylistName => 'Oynatma siyahısı adını daxil edin';
	@override String get delete => 'Oynatma siyahısını sil';
	@override String get removeItem => 'Oynatma siyahısından sil';
	@override String get smartPlaylist => 'Ağıllı oynatma siyahısı';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element',
	);
	@override String get emptyPlaylist => 'Bu oynatma siyahısı boşdur';
	@override String get deleteConfirm => 'Oynatma siyahısı silinsin?';
	@override String deleteMessage({required Object name}) => '"${name}" siyahısını silmək istədiyinizdən əminsiniz?';
	@override String get created => 'Oynatma siyahısı yaradıldı';
	@override String get deleted => 'Oynatma siyahısı silindi';
	@override String get itemAdded => 'Oynatma siyahısına əlavə edildi';
	@override String get itemRemoved => 'Oynatma siyahısından silindi';
	@override String get selectPlaylist => 'Oynatma siyahısı seç';
	@override String get searchPlaylists => 'Oynatma siyahılarında axtar...';
	@override String get errorCreating => 'Oynatma siyahısı yaradıla bilmədi';
	@override String get errorDeleting => 'Oynatma siyahısı silinə bilmədi';
	@override String get errorLoading => 'Oynatma siyahıları yüklənə bilmədi';
	@override String get errorAdding => 'Oynatma siyahısına əlavə edilə bilmədi';
	@override String get errorReordering => 'Element yenidən sıralana bilmədi';
	@override String get errorRemoving => 'Oynatma siyahısından silinə bilmədi';
}

// Path: music
class _Translations$music$az extends Translations$music$en {
	_Translations$music$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Alboma keç';
	@override String get goToArtist => 'İfaçıya keç';
	@override String get instantMix => 'Anında qarışıq';
	@override String get playNext => 'Növbətini oynat';
	@override String get addToQueue => 'Növbəyə əlavə et';
	@override String discNumber({required Object n}) => 'Disk ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mahnı',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mahnı',
	);
	@override String get nowPlaying => 'İndi oynadılır';
	@override String playingFrom({required Object title}) => '${title} mənbəsindən oynadılır';
	@override String get queue => 'Növbə';
	@override String get clearQueue => 'Növbəni təmizlə';
	@override String get lyrics => 'Mahnı sözləri';
	@override String get visualizer => 'Görüntülər';
	@override String get visualizerProfileLoading => 'İndi analizə baxmaq...';
	@override String get visualizerAmbientMotion => 'Atmosferin aktivitesi';
	@override String get visualizerPlexLoudness => 'Plex Sürücüsüz';
	@override String get visualizerPreviousPreset => 'Öncəki Görünürlük';
	@override String get visualizerNextPreset => 'Sonraki Görünüş Stili';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Blum';
	@override String get visualizerPresetOrbitals => 'Orbitlər';
	@override String get visualizerPresetPrism => 'Prismə';
	@override String get visualizerPresetTunnel => 'Tünel';
	@override String get visualizerPresetTrackMap => 'Harita yolları';
	@override String get noLyrics => 'Mahnı sözləri yoxdur';
	@override String get sleepTimer => 'Yuxu taymeri';
	@override String get sleepTimerEndOfTrack => 'Mahnının sonu';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dəqiqə',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dəqiqə',
	);
	@override String get stopPlayback => 'Oynatmanı saxla';
	@override String get previousTrack => 'Əvvəlki mahnı';
	@override String get nextTrack => 'Növbəti mahnı';
	@override String get repeat => 'Təkrarla';
	@override String get repeatAll => 'Hamısını təkrarla';
	@override String get repeatOne => 'Birini təkrarla';
	@override String get instantMixNoServer => 'Ani miks üçün heç bir server mövcud deyil';
	@override String get instantMixFailed => 'Anında qarışıq yüklənə bilmədi';
	@override String get instantMixEmpty => 'Anında qarışıq heç bir mahnı qaytarmadı';
	@override String noAudioUrl({required Object track}) => '${track} üçün səs URL-i mövcud deyil';
	@override late final _Translations$music$discography$az discography = _Translations$music$discography$az._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$az extends Translations$watchTogether$en {
	_Translations$watchTogether$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Birlikdə İzlə';
	@override String get description => 'Dostlarınız və ailənizlə eyni vaxtda baxın';
	@override String get createRoom => 'Otaq yarat';
	@override String get creatingRoom => 'Otaq yaradılır...';
	@override String get joinRoom => 'Otağa qoşul';
	@override String get joiningRoom => 'Otağa qoşulunur...';
	@override String get connecting => 'Qoşulunur...';
	@override String get relayPublic => 'Otaqlar ictimai Open Watch Party relelərindən istifadə edir.';
	@override String relayCustom({required Object url}) => 'Otaqlar ${url} ünvanındakı relenizdən istifadə edir.';
	@override String get recentRooms => 'Son otaqlar';
	@override String get roomActions => 'Otaq əməliyyatları';
	@override String get renameRoom => 'Otağın adını dəyişdir';
	@override String get removeRoom => 'Sil';
	@override String get enterRoomCode => 'Təşkilatçının verdiyi 6 simvollu kodu daxil edin.';
	@override String get roomCode => 'Otaq kodu';
	@override String get paste => 'Yapışdır';
	@override String get noCodeInClipboard => 'Buferdə otaq kodu yoxdur';
	@override String get copyCode => 'Kodu kopyala';
	@override String get codeCopied => 'Otaq kodu kopyalandı';
	@override String get shareInvite => 'Dəvəti paylaş';
	@override String get inviteCopied => 'Dəvət kopyalandı. Onu mesaja yapışdırın.';
	@override String inviteMessage({required Object code}) => 'PlezyNG-də Birlikdə İzlə otağıma qoşul: Birlikdə İzlə bölməsini aç, "Otağa qoşul" düyməsinə bas və ${code} kodunu daxil et.';
	@override String get openSessionControls => 'Birlikdə İzlə seans idarəetmələrini aç';
	@override String get reconnecting => 'Yenidən qoşulunur...';
	@override String get reconnectingDescription => 'Əlaqə kəsildi. Otağa avtomatik olaraq yenidən qoşulacaqsınız.';
	@override String get connected => 'Qoşulub';
	@override String get disconnected => 'Əlaqə kəsilib';
	@override String get youAreHost => 'Təşkilatçı sizsiniz';
	@override String hostedBy({required Object name}) => 'Təşkilatçı: ${name}';
	@override String get hostControlsPlayback => 'Oynatmanı təşkilatçı idarə edir';
	@override String get anyoneCanControl => 'Oynatmanı hər kəs idarə edə bilər';
	@override String get roomLocked => 'Otaq kilidlənib';
	@override String get nowPlaying => 'İndi oynadılır';
	@override String get nothingPlaying => 'Heç nə oynadılmır';
	@override String get nothingPlayingHost => 'Otaqla paylaşmaq üçün istənilən kitabxanadan nəsə oynadın.';
	@override String get nothingPlayingGuest => 'Təşkilatçı nəsə oynatdıqda, burada açılacaq.';
	@override String get notShareable => 'Bu videonun kataloqda uyğunluğu yoxdur, ona görə də onu yalnız eyni serverə çıxışı olanlar oynada bilər.';
	@override String get searching => 'Bu video kitabxanalarınızda axtarılır...';
	@override String get yourCopy => 'Sizin nüsxəniz';
	@override String get sharingYourCopy => 'Nüsxənizi paylaşırsınız';
	@override String playingOtherLength({required Object difference}) => 'Nüsxəniz oynadılır (${difference})';
	@override String get mismatchTitle => 'Nüsxənizin uzunluğu fərqlidir';
	@override String mismatchDescription({required Object difference}) => 'Ən yaxın nüsxəniz otaqdakı videodan ${difference}. Bu, başqa montaj və ya versiya ola bilər.';
	@override String get playAnyway => 'Yenə də oynat';
	@override String get chooseAnotherCopy => 'Başqa nüsxə seç';
	@override String get dontPlay => 'Oynatma';
	@override String get unavailableTitle => 'Bu video sizdə yoxdur';
	@override String get unavailableDescription => 'PlezyNG onu kitabxanalarınızda tapa bilmədi. Nüsxəni özünüz seçin və ya yenidən axtarın.';
	@override String get chooseCopy => 'Nüsxə seç';
	@override String get searchAgain => 'Yenidən axtar';
	@override String get noCandidates => 'Kitabxanalarınızda nüsxə tapılmadı.';
	@override String get choiceFailed => 'Bu nüsxəni otaq üçün oynatmaq mümkün olmadı';
	@override String lengthLonger({required Object duration}) => '${duration} daha uzun';
	@override String lengthShorter({required Object duration}) => '${duration} daha qısa';
	@override String get lengthSame => 'Eyni uzunluq';
	@override String get lengthUnknown => 'Uzunluq məlum deyil';
	@override String get joinCurrentPlayback => 'Cari oynatmaya qoşul';
	@override String get joinCurrentPlaybackDescription => 'Təşkilatçının indi baxdığı hissəyə keçin';
	@override String get stopMedia => 'Videonu hamı üçün dayandır';
	@override String get syncOffset => 'Sinxronizasiya ofseti';
	@override String get syncOffsetDescription => 'Videonuz otaqdan qabaqda və ya geridə qalırsa, onu sürüşdürün.';
	@override String offsetHint({required Object difference}) => 'Nüsxəniz otaqdakı videodan ${difference}.';
	@override String applyDifference({required Object offset}) => '${offset} tətbiq et';
	@override String get offsetMinusSecond => '-1 san';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 san';
	@override String get participants => 'İştirakçılar';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} iştirakçı',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} iştirakçı',
	);
	@override String get hostBadge => 'TƏŞKİLATÇI';
	@override String nameYou({required Object name}) => '${name} (Siz)';
	@override String get playerIdle => 'Gözləmədə';
	@override String get playerLoading => 'Yüklənir';
	@override String get playerReady => 'Hazırdır';
	@override String get playerBuffering => 'Buferlənir';
	@override String get matchSearching => 'Axtarır';
	@override String get matchMatched => 'Video var';
	@override String get matchMismatched => 'Fərqli uzunluq';
	@override String get matchUnavailable => 'Video yoxdur';
	@override String participantOffset({required Object offset}) => 'Ofset ${offset}';
	@override String get makeHost => 'Təşkilatçı təyin et';
	@override String get makeHostQuestion => 'Təşkilatçı köçürülsün?';
	@override String makeHostConfirm({required Object name}) => '${name} oynatmanı idarə edəcək və seansı hər kəs üçün aparacaq.';
	@override String get transfer => 'Köçür';
	@override String get removeParticipant => 'Otaqdan çıxar';
	@override String removeParticipantQuestion({required Object name}) => '${name} çıxarılsın?';
	@override String removeParticipantConfirm({required Object name}) => '${name} otağı tərk edəcək. Otağı kilidləməsəniz, kodla yenidən qoşula bilər.';
	@override String get remove => 'Çıxar';
	@override String get roomSettings => 'Otaq tənzimləmələri';
	@override String get letEveryoneControl => 'Hamıya oynatmanı idarə etməyə icazə ver';
	@override String get lockRoom => 'Otağı kilidlə';
	@override String get lockRoomDescription => 'Heç kim yeni qoşula bilməz';
	@override String get leaveRoom => 'Otağı tərk et';
	@override String get leaveRoomQuestion => 'Otaq tərk edilsin?';
	@override String get leaveRoomConfirm => 'Otaq kodu ilə yenidən qoşula bilərsiniz.';
	@override String get leave => 'Çıx';
	@override String get endRoom => 'Otağı bağla';
	@override String get endRoomQuestion => 'Otaq bağlansın?';
	@override String get endRoomConfirm => 'Bu, otağı hamı üçün bağlayır.';
	@override String get end => 'Bitir';
	@override String get playBlockedTitle => 'Oynatma başlamadı';
	@override String get playBlockedDescription => 'Otaqla birlikdə baxmağa başlamaq üçün oynat düyməsinə basın.';
	@override late final _Translations$watchTogether$notices$az notices = _Translations$watchTogether$notices$az._(_root);
	@override late final _Translations$watchTogether$ended$az ended = _Translations$watchTogether$ended$az._(_root);
	@override late final _Translations$watchTogether$errors$az errors = _Translations$watchTogether$errors$az._(_root);
	@override String untitledEpisode({required Object number}) => 'Seriya ${number}';
}

// Path: downloads
class _Translations$downloads$az extends Translations$downloads$en {
	_Translations$downloads$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Yükləmələr';
	@override String get manage => 'İdarə et';
	@override String get tvShows => 'TV Şoular';
	@override String get movies => 'Kinolar';
	@override String get music => 'Musiqi';
	@override String tracksQueued({required Object count}) => 'Yükləmə üçün ${count} mahnı növbəyə alındı';
	@override String get noDownloads => 'Hələlik yükləmə yoxdur';
	@override String get noDownloadsDescription => 'Yüklənmiş məzmun oflayn baxış üçün burada görünəcək';
	@override String get downloadNow => 'Yüklə';
	@override String get deleteDownload => 'Yükləməni sil';
	@override String get retryDownload => 'Yükləməni təzədən cəhd et';
	@override String get downloadQueued => 'Yükləmə növbəyə alındı';
	@override String get downloadResumed => 'Yükləmə davam etdirildi';
	@override String get serverErrorBitrate => 'Server xətası: fayl sürət limitini aşa bilər';
	@override String get storageFull => 'Boş yaddaşı qorumaq üçün yükləmələr dayandırıldı. Yer boşaldın və ya başqa yükləmə yeri seçin, sonra yenidən cəhd edin.';
	@override String get storageUnavailable => 'Boş yaddaşı yoxlamaq mümkün olmadığı üçün yükləmələr dayandırıldı. Yükləmə yerini yoxlayın, sonra təzədən cəhd edin.';
	@override String episodesQueued({required Object count}) => 'Yükləmə üçün ${count} seriya növbəyə alındı';
	@override String get downloadDeleted => 'Yükləmə silindi';
	@override String deleteConfirm({required Object title}) => '"${title}" bu cihazdan silinsin?';
	@override String get deleteCollectionDownloads => 'Yükləmələri sil';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => '"${title}" daxilindəki bütün yükləmələr bu cihazdan silinsin?';
	@override String get collectionDownloadsDeleted => 'Yükləmələr silindi';
	@override String get cancelledDownloadTitle => 'Ləğv edilmiş yükləmə';
	@override String get cancelledDownloadMessage => 'Bu yükləmə ləğv edildi. Nə etmək istərdiniz?';
	@override String get allEpisodesAlreadyDownloaded => 'Bütün seriyalar artıq yüklənib';
	@override String get resumeDownload => 'Yükləməni davam etdir';
	@override String get cancelledDownload => 'Ləğv edilmiş yükləmə';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} eyniləşdirilir)';
	@override String downloadedFileClickToComplete({required Object file}) => 'Yükləndi ${file} - Tamamlamaq üçün toxunun';
	@override String get partialDownloadClickToComplete => 'Hissəvi yükləndi - Tamamlamaq üçün toxunun';
	@override String get deleting => 'Silinir...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} silinir... (${current} / ${total})';
	@override String get queuedTooltip => 'Növbədədir';
	@override String queuedFilesTooltip({required Object files}) => 'Növbəyə alınan fayllar: ${files}';
	@override String get downloadingTooltip => 'Yüklənir...';
	@override String downloadingFilesTooltip({required Object files}) => 'Yüklənən fayllar: ${files}';
	@override String get noDownloadsTree => 'Yükləmə yoxdur';
	@override String get pauseAll => 'Hamısını fasilə et';
	@override String get resumeAll => 'Hamısını davam etdir';
	@override String get retryAll => 'Hamısını təzədən cəhd et';
	@override String get retryFailed => 'Uğursuz yükləmələri təzədən cəhd et';
	@override String get deleteAll => 'Hamısını sil';
	@override String get selectVersion => 'Versiya seç';
	@override String get allEpisodes => 'Bütün seriyalar';
	@override String get unwatchedOnly => 'Yalnız baxılmayanlar';
	@override String nextNUnwatched({required Object count}) => 'Növbəti ${count} baxılmayan';
	@override String get customAmount => 'Xüsusi miqdar...';
	@override String get customAmountAny => 'Hər bir dəfə (yəni)';
	@override String get randomEpisodes => 'Random epizodları';
	@override String get includeSpecials => 'Xüsusi seriyaları daxil et';
	@override String get howManyEpisodes => 'Neçə seriya?';
	@override String get invalidEpisodeCount => 'Düzgün seriya sayı daxil edin.';
	@override String get keepSynced => 'Eyniləşdirilmiş saxla';
	@override String get downloadOnce => 'Bir dəfə yüklə';
	@override String keepNUnwatched({required Object count}) => '${count} baxılmayan seriyanı saxla';
	@override String get editSyncRule => 'Eyniləşdirmə qaydasını dəyişdir';
	@override String get removeSyncRule => 'Eyniləşdirmə qaydasını sil';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" eyniləşdirməsi dayandırılsın? Yüklənmiş seriyalar saxlanılacaq.';
	@override String removeListSyncRuleConfirm({required Object title}) => '"${title}" eyniləşdirməsi dayandırılsın?';
	@override String get deleteSyncRuleDownloads => 'Əlaqəli yükləmələri də sil';
	@override String get deleteSyncRuleDownloadsDescription => 'Başqa eyniləşdirmə qaydası və ya profil tərəfindən istifadə olunan yükləmələr saxlanılacaq.';
	@override String syncRuleCreated({required Object count}) => 'Eyniləşdirmə qaydası yaradıldı — ${count} baxılmayan seriya saxlanılır';
	@override String get syncRuleUpdated => 'Eyniləşdirmə qaydası yeniləndi';
	@override String get syncRuleRemoved => 'Eyniləşdirmə qaydası silindi';
	@override String get syncRuleAndDownloadsRemoved => 'Eyniləşdirmə qaydası və əlaqəli yükləmələr silindi';
	@override String get syncRuleCleanupBusy => 'Eyniləşdirmə qaydaları hazırda yenilənir. Bir azdan təzədən cəhd edin.';
	@override String get syncRuleCleanupUnavailable => 'Əlaqəli yükləmələr təhlükəsiz şəkildə müəyyən edilə bilmədi. Serverə yenidən qoşulub cəhd edin və ya qaydanı yükləmələri silmədən silin.';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '${title} üçün ${count} yeni seriya eyniləşdirildi';
	@override String get syncNow => 'Sünnə';
	@override String get downloadsUpToDate => 'İndirlər günümüzdən';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sinxronlaşdırma tamamlandı · ${queued} növbəyə əlavə edildi, ${removed} silindi';
	@override String get activeSyncRules => 'Eyniləşdirmə qaydaları';
	@override String get reviewOrphanFiles => 'Yetim qalmış endirmələri nəzərdən keçir';
	@override String get orphanReviewTitle => 'Yetim qalmış endirmələri nəzərdən keçir';
	@override String get orphanReviewDescription => 'Bu teqlənmiş fayllar PlezyNG-nin tətbiq tərəfindən idarə olunan standart endirmə qovluqlarındadır və onlara uyğun endirmə qeydi və ya aktiv tapşırıq yoxdur. Silməzdən əvvəl siyahını yoxlayın.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} fayl · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '${count} faylı sil';
	@override String get orphanCleanupNone => 'Yetim qalmış endirmə faylı tapılmadı';
	@override String get orphanCleanupFailed => 'PlezyNG idarə olunan endirmələr qovluğunu təhlükəsiz şəkildə skan edə bilmədi. Heç bir fayl silinmədi.';
	@override String get orphanCleanupChanged => 'Nəzərdən keçirmə zamanı endirmə siyahısı dəyişdi. Təmizləməzdən əvvəl faylları yenidən nəzərdən keçirin.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '${count} yetim endirmə faylı silindi · ${size} yer boşaldıldı';
	@override String get noSyncRules => 'Eyniləşdirmə qaydası yoxdur';
	@override String get manageSyncRule => 'Eyniləşdirməni idarə et';
	@override String get editEpisodeCount => 'Seriya sayı';
	@override String get editSyncFilter => 'Eyniləşdirmə filtri';
	@override String get syncAllItems => 'Bütün elementlər eyniləşdirilir';
	@override String get syncUnwatchedItems => 'Baxılmayan elementlər eyniləşdirilir';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Əlçatandır';
	@override String get syncRuleOffline => 'Oflayn';
	@override String get syncRuleSignInRequired => 'Daxil olmaq tələb olunur';
	@override String get syncRuleAccessDenied => 'Giriş rədd edildi';
	@override String get syncRuleNotAvailableForProfile => 'Cari profil üçün əlçatan deyil';
	@override String get syncRuleUnknownServer => 'Bilinməyən server';
	@override String get syncRuleListCreated => 'Eyniləşdirmə qaydası yaradıldı';
	@override late final _Translations$downloads$backgroundWarning$az backgroundWarning = _Translations$downloads$backgroundWarning$az._(_root);
	@override String get options => 'Yükləmə seçimləri';
	@override late final _Translations$downloads$groupings$az groupings = _Translations$downloads$groupings$az._(_root);
	@override String get unknownLibrary => 'Məlum olmayan kitabxana';
	@override String get unknownShow => 'Məlum olmayan serial';
	@override String get unknownSeason => 'Məlum olmayan mövsüm';
	@override String get unknownAlbum => 'Məlum olmayan albom';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} tamamlandı';
	@override String storageUsed({required Object size}) => 'Kullanılan qapı: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} endirmə',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} endirmə',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} xəbərlər',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} izləyir',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmləri',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmlər',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom',
	);
	@override String get errorFileNotFound => 'Fayl tapılmadı (404)';
	@override String get errorDownloadNotAllowed => 'Server yükləməyə icazə vermir (403)';
	@override String get errorDownloadFailed => 'Yükləmə uğursuz oldu';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Yükləmə uğursuz oldu: ${reason}';
	@override String get convertingOnServer => 'Servisə dönüştürülüb.';
	@override String convertingOnServerPercent({required Object percent}) => 'Sunucuya dönüşüm · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Yükləmə uğursuz oldu (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Sonrakı emal uğursuz oldu: ${reason}';
	@override String get reasonFileNotSaved => 'fayl bu cihazda saxlanıla bilmədi';
	@override String get reasonCannotResume => 'yarımçıq yükləməni davam etdirmək mümkün olmadı';
	@override String get reasonDeviceStorageFull => 'bu cihazda yer qalmayıb';
	@override String get notificationDownloading => 'Yüklənir...';
	@override String get notificationComplete => 'Yükləmə tamamlandı';
	@override String get notificationPaused => 'Yükləmə dayandırıldı';
}

// Path: shaders
class _Translations$shaders$az extends Translations$shaders$en {
	_Translations$shaders$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Şeyderlər';
	@override String get noShaderDescription => 'Video təkmilləşdirməsi yoxdur';
	@override String get nvscalerDescription => 'Daha kəskin video üçün NVIDIA miqyaslaması';
	@override String get artcnnVariantNeutral => 'Neytral';
	@override String get artcnnVariantDenoise => 'Küyün aradan qaldırılması';
	@override String get artcnnVariantDenoiseSharpen => 'Küyün aradan qaldırılması + Kəskinləşdirmə';
	@override String get qualityFast => 'Sürətli';
	@override String get qualityHQ => 'Yüksək keyfiyyət';
	@override String get mode => 'Rejim';
	@override String get importShader => 'Şeyder idxal et';
	@override String get customShaderDescription => 'Xüsusi GLSL şeyderi';
	@override String get shaderImported => 'Şeyder idxal edildi';
	@override String get shaderImportFailed => 'Şeyder idxal edilə bilmədi';
	@override String get deleteShader => 'Şeyderi sil';
	@override String deleteShaderConfirm({required Object name}) => '"${name}" silinsin?';
}

// Path: companionRemote
class _Translations$companionRemote$az extends Translations$companionRemote$en {
	_Translations$companionRemote$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Köməkçi pult';
	@override String connectedTo({required Object name}) => '${name} cihazına qoşuldu';
	@override String get unknownDevice => 'Bilinməyən cihaz';
	@override late final _Translations$companionRemote$session$az session = _Translations$companionRemote$session$az._(_root);
	@override late final _Translations$companionRemote$pairing$az pairing = _Translations$companionRemote$pairing$az._(_root);
	@override late final _Translations$companionRemote$remote$az remote = _Translations$companionRemote$remote$az._(_root);
	@override late final _Translations$companionRemote$errors$az errors = _Translations$companionRemote$errors$az._(_root);
	@override String get closedBeforeAuth => 'Bağlantı autentifikasiyadan əvvəl bağlandı';
}

// Path: videoSettings
class _Translations$videoSettings$az extends Translations$videoSettings$en {
	_Translations$videoSettings$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Oynatma sürəti';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Aktivdir (${duration})';
	@override String get zoom => 'Miqyas';
	@override String get sleepTimer => 'Yuxu taymeri';
	@override String get audioSync => 'Səs sinxronizasiyası';
	@override String get subtitleSync => 'Altyazı sinxronizasiyası';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR burada əlçatan deyil — bu masaüstü kompozitoru və ya video çıxışı onu ötürə bilmir.';
	@override String get hdrToneMapping => 'HDR ton uyğunlaşdırması';
	@override String get hdrToneMappingCompositor => 'Kompozitor';
	@override String get hdrToneMappingCompositorDescription => 'Mənbənin HDR metaməlumatlarını dəyişmədən ötür və ton uyğunlaşdırmasını masaüstü kompozitoruna həvalə et.';
	@override String get hdrToneMappingPlayer => 'Oynadıcı';
	@override String get hdrToneMappingPlayerDescription => 'Oynadıcıda tonları ekranın pik parlaqlığına uyğunlaşdır, sonra nəticəni kompozitora bildir.';
	@override String get hdrToneMappingFailed => 'HDR ton uyğunlaşdırmasını dəyişmək olmadı — əvvəlki rejim hələ də aktivdir.';
	@override String get audioOutput => 'Səs çıxışı';
	@override String get videoTrack => 'Video treki';
	@override String get videoTrackDescription => 'Göstəriləcək video axınını seçin. Faylda alternativ video trekləri olduqda MPV oynadılmasında mövcuddur.';
	@override String get videoTrackDefault => 'Standart';
	@override String get videoTrackUnavailable => 'Alternativ video treki yoxdur.';
	@override String get videoTrackFailed => 'Video trekini dəyişmək mümkün olmadı.';
	@override String videoTrackNumber({required Object id}) => 'Trek ${id}';
	@override String get performanceOverlay => 'Məhsuldarlıq paneli';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Əhatəli səs';
	@override String get audioOutputSpatial => 'Məkan səsi';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Audio düzəltmə';
	@override String get audioEqualizerDescription => 'MPV üçün 10 zolaqlı ekvalayzer. Audio filtrləri dekodlaşdırılmış səsdən istifadə edir və ötürməni söndürür.';
	@override String get audioEqualizerFlat => 'Düz';
	@override String get audioEqualizerActive => 'Xüsusi';
	@override String get audioEqualizerSaveFailed => 'Audio equalizer ayarları saxlayamazdı.';
	@override String get audioEffectsDescription => 'Effektlər dekodlaşdırılmış səsdən istifadə edir, buna görə birbaşa ötürmə söndürülür. Otaq əks-sədası və stereo genişləndirməsi MPV quruluşundan və trekdən asılıdır.';
	@override String get audioStereoWidth => 'Stereo genişləndirmə';
	@override String get audioSpatializer => 'Otaq mühiti';
	@override String get audioSpatializerDescription => 'Yüngül otaq əks-sədası əlavə et.';
	@override String get audioPitch => 'Tonun dəyişdirilməsi';
	@override String get audioPitchDescription => 'Sürəti dəyişmədən tonu dəyişin. MPV quruluşunda Rubber Band olmalıdır.';
	@override String get audioEffectUnavailable => 'Bu effekt bu trek və ya MPV quruluşu üçün əlçatan deyil.';
	@override String get backgroundVideoAudio => 'Video və Audio';
	@override String get backgroundVideoAudioDescription => 'Videoya oyunun oynamaq üçün oynamaq üçün videoya oyunun oyuncusu çıxırsanız qalandır. xilasın geri qayıtılana qədər gizlidir. Android bir medya oynamaq bildirimi kullanır.';
	@override String get audioNormalization => 'Səsin gurluğunu normallaşdır';
	@override String get audioNormalizationDisablesPassthrough => 'Səsi PCM-ə dekodlayır; bu aktivkən birbaşa ötürmə söndürülür';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$az extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get color => 'Rəng';
	@override String get performance => 'Məhsuldarlıq';
	@override String get buffer => 'Bufer';
	@override String get app => 'Tətbiq';
	@override String get decoder => 'Çözücü';
	@override String get rawDecoder => 'Xam çözücü';
	@override String get tunneling => 'Tünelləmə';
	@override String get passthrough => 'Birbaşa ötürmə';
	@override String get aspect => 'Nisbət';
	@override String get rotation => 'Dönmə';
	@override String get dvSource => 'DV mənbəyi';
	@override String get dvPath => 'DV yolu';
	@override String get dvRouteDecoder => 'Dolby Vision çözücüsü';
	@override String get dvRouteDecoderP81 => 'Dolby Vision çözücüsü (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Baza təbəqə';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 baza təbəqə';
	@override String get dvRouteBaseLayerHlg => 'HLG baza təbəqə';
	@override String get dvRouteBaseLayerSdr => 'SDR baza təbəqə';
	@override String get dvRouteReshaped => 'RPU ilə yenidən formalaşdırılıb (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Eksperimental P7 FEL grafik (kalifikatə olmayan)';
	@override String get p7Conversion => 'P7 çevrilməsi';
	@override String get sampleRate => 'Diskretləşdirmə tezliyi';
	@override String get pixelFormat => 'Piksel formatı';
	@override String get hwFormat => 'HW formatı';
	@override String get matrix => 'Matrisa';
	@override String get primaries => 'Əsas rənglər';
	@override String get transfer => 'Ötürmə';
	@override String get renderFps => 'Emal FPS-i';
	@override String get displayFps => 'Ekran FPS-i';
	@override String get avSync => 'A/V Eyniləşdirilməsi';
	@override String get dropped => 'İtirilmiş kadrlar';
	@override String get dvRpus => 'DV RPU-ları';
	@override String get dvRpuAverage => 'DV RPU Ort.';
	@override String get dvSampleAverage => 'DV Nümunə Ort.';
	@override String get maxLuma => 'Maks Luma';
	@override String get minLuma => 'Min Luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'İstifadə olunan keş';
	@override String get cacheLimit => 'Keş limiti';
	@override String get speed => 'Sürət';
	@override String get player => 'Oynadıcı';
	@override String get playMethod => 'Oyun metodları';
	@override String get memory => 'Yaddaş';
	@override String get uiFps => 'Arayüz (UI) FPS-i';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Proqram təminatı';
	@override String get decoderHardware => 'Aparat təminatı';
	@override String get tunnelingActive => 'Aktiv';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} uğursuz)';
}

// Path: externalPlayer
class _Translations$externalPlayer$az extends Translations$externalPlayer$en {
	_Translations$externalPlayer$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Xarici oynadıcı';
	@override String get useExternalPlayer => 'Xarici oynadıcı istifadə et';
	@override String get useExternalPlayerDescription => 'Videoları başqa tətbiqdə açın';
	@override String get selectPlayer => 'Oynadıcı seç';
	@override String get customPlayers => 'Xüsusi oynadıcılar';
	@override String get systemDefault => 'Sistem defoltu';
	@override String get addCustomPlayer => 'Xüsusi oynadıcı əlavə et';
	@override String get playerName => 'Oynadıcı adı';
	@override String get playerNameHint => 'Mənim oynadıcım';
	@override String get playerCommand => 'Əmr';
	@override String get playerPackage => 'Paket adı';
	@override String get playerUrlScheme => 'URL sxemi';
	@override String get off => 'Söndürülüb';
	@override String get launchFailed => 'Xarici oynadıcı açıla bilmədi';
	@override String appNotInstalled({required Object name}) => '${name} quraşdırılmayıb';
	@override String get playInExternalPlayer => 'Xarici oynadıcıda oynat';
	@override String get description => 'Video açmaq üçün başka bir proqram seçin. mevcut oyuncular cihazınıza və yüklü uygulamalarına bağlıdır.';
	@override String get systemDefaultDescription => 'Operasiya sisteminin default app ilə video açmasına izin verin.';
	@override String playerOptionDescription({required Object player}) => '${player} ilə video açın.';
	@override String get playerNameDescription => 'Oyunçı listəsində göstərən etiket.';
	@override String get playerPackageDescription => '“Android” paketinin adı, oyuncu proqramının adı, örneğin com.example.player kimi girin.';
	@override String get playerCommandDescription => 'Bu cihazın yüklü oyuncu komandası və ya yürütülebilir yolunu girin.';
	@override String get playerUrlSchemeDescription => 'URL şeması və oyuncu başlatmaq üçün kullanılan seçici URL şablonu girin.';
}

// Path: metadataEdit
class _Translations$metadataEdit$az extends Translations$metadataEdit$en {
	_Translations$metadataEdit$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Düzəliş et...';
	@override String get screenTitle => 'Meta-məlumatlara düzəliş et';
	@override String get basicInfo => 'Əsas məlumatlar';
	@override String get artwork => 'Şəkillər/Posterlər';
	@override String get advancedSettings => 'Təkmilləşdirilmiş tənzimləmələr';
	@override String get title => 'Başlıq';
	@override String get sortTitle => 'Sıralama başlığı';
	@override String get originalTitle => 'Orijinal başlıq';
	@override String get releaseDate => 'Buraxılış tarixi';
	@override String get contentRating => 'Məzmun reytinqi';
	@override String get studio => 'Studiya';
	@override String get tagline => 'Deviz/Slogan';
	@override String get summary => 'Məzmun/Xülasə';
	@override String get poster => 'Poster';
	@override String get background => 'Arxa fon';
	@override String get logo => 'Loqo';
	@override String get squareArt => 'Kvadrat şəkil';
	@override String get selectPoster => 'Poster seç';
	@override String get selectBackground => 'Arxa fon seç';
	@override String get selectLogo => 'Loqo seç';
	@override String get selectSquareArt => 'Kvadrat şəkil seç';
	@override String get fromUrl => 'URL-dən';
	@override String get uploadFile => 'Fayl yüklə';
	@override String get enterImageUrl => 'Şəkil URL-i daxil edin';
	@override String get imageUrl => 'Şəkil URL-i';
	@override String get metadataUpdated => 'Meta-məlumatlar yeniləndi';
	@override String get metadataUpdateFailed => 'Meta-məlumatlar yenilənə bilmədi';
	@override String get artworkUpdated => 'Şəkillər yeniləndi';
	@override String get artworkUpdateFailed => 'Şəkillər yenilənə bilmədi';
	@override String get noArtworkAvailable => 'Şəkil əlçatan deyil';
	@override String artworkOption({required Object index}) => 'Şəkil seçimi ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Şəkil seçimi ${index}, seçildi';
	@override String get notSet => 'Təyin edilməyib';
	@override String get libraryDefault => 'Kitabxana defoltu';
	@override String get accountDefault => 'Hesab defoltu';
	@override String get seriesDefault => 'Serial defoltu';
	@override String get episodeSorting => 'Seriya sıralaması';
	@override String get oldestFirst => 'Əvvəlcə ən köhnə';
	@override String get newestFirst => 'Əvvəlcə ən yeni';
	@override String get keep => 'Saxla';
	@override String get allEpisodes => 'Bütün seriyalar';
	@override String latestEpisodes({required Object count}) => 'Ən son ${count} seriya';
	@override String get latestEpisode => 'Ən son seriya';
	@override String episodesAddedPastDays({required Object count}) => 'Son ${count} gündə əlavə olunan seriyalar';
	@override String get deleteAfterPlaying => 'Oynatdıqdan sonra seriyaları sil';
	@override String get never => 'Heç vaxt';
	@override String get afterADay => 'Bir gün sonra';
	@override String get afterAWeek => 'Bir həftə sonra';
	@override String get afterAMonth => 'Bir ay sonra';
	@override String get onNextRefresh => 'Növbəti yenilənmədə';
	@override String get seasons => 'Mövsümlər';
	@override String get show => 'Göstər';
	@override String get hide => 'Gizlət';
	@override String get episodeOrdering => 'Seriya ardıcıllığı';
	@override String get tmdbAiring => 'The Movie Database (Yayımlanma)';
	@override String get tvdbAiring => 'TheTVDB (Yayımlanma)';
	@override String get tvdbAbsolute => 'TheTVDB (Mütləq)';
	@override String get metadataLanguage => 'Meta-məlumat dili';
	@override String get useOriginalTitle => 'Orijinal başlığı istifadə et';
	@override String get preferredAudioLanguage => 'Üstünlük verilən səs dili';
	@override String get preferredSubtitleLanguage => 'Üstünlük verilən altyazı dili';
	@override String get subtitleMode => 'Avtomatik altyazı seçim rejimi';
	@override String get manuallySelected => 'Əl ilə seçilmiş';
	@override String get shownWithForeignAudio => 'Xarici səs olduqda göstərilən';
	@override String get alwaysEnabled => 'Həmişə aktivdir';
	@override String get tags => 'Teqlər';
	@override String get addTag => 'Teq əlavə et';
	@override String get genre => 'Janr';
	@override String get director => 'Rejissor';
	@override String get writer => 'Ssenarist';
	@override String get producer => 'Prodüser';
	@override String get country => 'Ölkə';
	@override String get collection => 'Kolleksiya';
	@override String get label => 'Etiket';
	@override String get quickTag => 'Sürətli etiket...';
}

// Path: matchScreen
class _Translations$matchScreen$az extends Translations$matchScreen$en {
	_Translations$matchScreen$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get match => 'Uyğunlaşdır...';
	@override String get fixMatch => 'Uyğunluğu düzəlt...';
	@override String get unmatch => 'Uyğunluğu ləğv et';
	@override String get unmatchConfirm => 'Bu uyğunluq təmizlənsin? Yenidən uyğunlaşdırılana qədər Plex onu uyğunlaşdırılmamış sayacaq.';
	@override String get unmatchSuccess => 'Element uyğunluğu ləğv edildi';
	@override String get unmatchFailed => 'Uyğunluq ləğv edilə bilmədi';
	@override String get matchApplied => 'Uyğunluq tətbiq edildi';
	@override String get matchFailed => 'Uyğunluq tətbiq edilə bilmədi';
	@override String get titleHint => 'Ad';
	@override String get yearHint => 'İl';
	@override String get search => 'Axtar';
	@override String get noMatchesFound => 'Uyğunluq tapılmadı';
}

// Path: serverTasks
class _Translations$serverTasks$az extends Translations$serverTasks$en {
	_Translations$serverTasks$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Server tapşırıqları';
	@override String get failedToLoad => 'Tapşırıqlar yüklənə bilmədi';
	@override String get noTasks => 'İcra olunan tapşırıq yoxdur';
}

// Path: trakt
class _Translations$trakt$az extends Translations$trakt$en {
	_Translations$trakt$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Qoşuldu';
	@override String connectedAs({required Object username}) => '@${username} olaraq qoşuldu';
	@override String get disconnectConfirm => 'Trakt hesabı ayırılsın?';
	@override String get disconnectConfirmBody => 'PlezyNG Trakt-a məlumat göndərməyi dayandıracaq.';
	@override String get scrobble => 'Real vaxt rejimində izləmə';
	@override String get scrobbleDescription => 'Oynatma zamanı Trakt-a məlumat göndər.';
	@override String get watchedSync => 'Baxış statusunu eyniləşdir';
	@override String get watchedSyncDescription => 'PlezyNG-də baxıldı işarələdikdə Trakt-da da işarələnsin.';
}

// Path: seerr
class _Translations$seerr$az extends Translations$seerr$en {
	_Translations$seerr$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerr qoş';
	@override String get serverUrl => 'Server URL-i';
	@override String get serverUrlHelper => 'Seerr ünvanınız';
	@override String get checkServer => 'Davam et';
	@override String get signInWithJellyfin => 'Jellyfin ilə daxil ol';
	@override String get signInWithEmby => 'Emby ilə daxil ol';
	@override String get signInWithLocal => 'Yerli hesab istifadə et';
	@override String get email => 'E-poçt';
	@override String get noSignInMethods => 'Bu Seerr dəstəklənən daxil olma üsulu təklif etmir.';
	@override String get instance => 'Nüsxə';
	@override String get disconnectConfirm => 'Seerr ayırılsın?';
	@override String get disconnectConfirmBody => 'PlezyNG bu Seerr serverini unudacaq. İstənilən vaxt yenidən qoşula bilərsiniz.';
	@override String get request => 'Sorğu göndər';
	@override String get request4k => '4K sorğu göndər';
	@override String get seasons => 'Mövsümlər';
	@override String get allSeasons => 'Bütün mövsümlər';
	@override String get advancedOptions => 'Təkmilləşdirilmiş';
	@override String get destinationServer => 'Hədəf server';
	@override String get qualityProfile => 'Keyfiyyət profili';
	@override String get rootFolder => 'Kök qovluq';
	@override String get languageProfile => 'Dil profili';
	@override String get tags => 'Teqlər';
	@override String get noTags => 'Teq yoxdur';
	@override String defaultOption({required Object name}) => '${name} (Defolt)';
	@override String get animeNote => 'Bu serial animedir.';
	@override String get requestSubmitted => 'Sorğu göndərildi';
	@override String requestFailed({required Object error}) => 'Sorğu uğursuz oldu: ${error}';
	@override String get requestsLoadFailed => 'Seçimlər yüklənə bilmədi';
	@override String get nothingToRequest => 'Hər şey artıq var və ya sorğu göndərilib.';
	@override String get statusAvailable => 'Əlçatandır';
	@override String get statusPartiallyAvailable => 'Hissəvi əlçatandır';
	@override String get statusRequested => 'Sorğu göndərildi';
	@override String get statusProcessing => 'Emal edilir';
	@override String get statusBlocklisted => 'Bloklanmış';
	@override String couldNotReach({required Object url, required Object error}) => '${url} ünvanına çatmaq olmadı: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => '${url} ünvanında Seerr instansiyası yoxdur (HTTP ${status})';
	@override String get behindAuthProxy => 'Seerr əvəzinə autentifikasiya edən tərs proksi (SSO və ya HTTP auth) cavab verdi. PlezyNG onun vasitəsilə daxil ola bilmir: bu tətbiq üçün Seerr-in /api/v1 yolunun proksini yan keçməsinə icazə verin və ya Seerr-ə birbaşa çatan ünvan istifadə edin.';
	@override String get invalidUrl => 'https://seerr.example.com kimi server ünvanı daxil edin';
	@override String get quickConnectUnsupported => 'Bu Seerr nüsxəsi Sürətli Qoşulmanı dəstəkləmir. Seerr 3.4 və ya daha yeni versiya tələb olunur.';
	@override String get notInitialized => 'Bu Seerr instansiyasının ilkin quraşdırılması tamamlanmayıb';
	@override String get noPlexTokenForReauth => 'Yenidən daxil olmaq üçün Plex tokeni mövcud deyil';
	@override String get noStoredCredentials => 'Yenidən daxil olmaq üçün yadda saxlanmış giriş məlumatları mövcud deyil';
	@override String get signInRejected => 'Daxil olma rədd edildi';
	@override String get noSessionCookie => 'Seerr sessiya kukisi yaratmadı';
	@override String get freshCookieRejected => 'Seerr yeni sessiya kukisini rədd etdi';
	@override String get noUserInformation => 'Seerr istifadəçi məlumatlarını qaytarmadı';
	@override String get sessionRejectedAfterReauth => 'Yenidən daxil olduqdan sonra sessiya rədd edildi';
	@override String get permissionDenied => 'Seerr bu əməliyyatı rədd etdi: hesabınızda artıq tələb olunan icazə yoxdur';
	@override String get permissionRevoked => 'Bunu sorğulamaq üçün artıq icazəniz yoxdur';
}

// Path: services
class _Translations$services$az extends Translations$services$en {
	_Translations$services$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Xidmətlər';
	@override String get hubSubtitle => 'İzləmə tərəqqisini eyniləşdirin və yeni başlıqlar sorğulayın.';
	@override String get integrations => 'İnteqrasiyalar';
	@override String get notConnected => 'Qoşulmayıb';
	@override String connectedAs({required Object username}) => '@${username} olaraq qoşuldu';
	@override String get scrobble => 'Tərəqqini avtomatik izlə';
	@override String get scrobbleDescription => 'Bir epizodu və ya filmi bitirdikdə siyahınızı yeniləyin.';
	@override String disconnectConfirm({required Object service}) => '${service} ayırılsın?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG ${service} yeniləməyi dayandıracaq. İstənilən vaxt yenidən qoşula bilərsiniz.';
	@override String connectFailed({required Object service}) => '${service} qoşula bilmədi. Təzədən cəhd edin.';
	@override late final _Translations$services$names$az names = _Translations$services$names$az._(_root);
	@override late final _Translations$services$simklReconnect$az simklReconnect = _Translations$services$simklReconnect$az._(_root);
	@override late final _Translations$services$deviceCode$az deviceCode = _Translations$services$deviceCode$az._(_root);
	@override late final _Translations$services$oauthProxy$az oauthProxy = _Translations$services$oauthProxy$az._(_root);
	@override late final _Translations$services$pendingAuth$az pendingAuth = _Translations$services$pendingAuth$az._(_root);
	@override late final _Translations$services$libraryFilter$az libraryFilter = _Translations$services$libraryFilter$az._(_root);
	@override String get seerrDescription => '“Seerr” və ya “Overseerr” ilə bağlanın, başlıklar aradan və medya talepləri gönderin.';
	@override late final _Translations$services$trackerDescriptions$az trackerDescriptions = _Translations$services$trackerDescriptions$az._(_root);
}

// Path: addServer
class _Translations$addServer$az extends Translations$addServer$en {
	_Translations$addServer$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '${product} serveri əlavə et';
	@override String get serverUrls => 'Server URL-ləri';
	@override String get serverUrlsHelper => 'Vergüllə ayrılmış bir neçə URL-ə icazə verilir.';
	@override String get findServer => 'Server tap';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Yerli ${product} serverləri axtarılır...';
	@override String localMediaBrowserServers({required Object product}) => 'Yerli ${product} serverləri';
	@override String get username => 'İstifadəçi adı';
	@override String get password => 'Şifrə';
	@override String get signIn => 'Daxil ol';
	@override String get change => 'Dəyişdir';
	@override String get required => 'Tələb olunur';
	@override String couldNotReachServer({required Object error}) => 'Serverə çatmaq olmadı: ${error}';
	@override String signInFailed({required Object error}) => 'Daxil olma uğursuz oldu: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Sürətli Qoşulma uğursuz oldu: ${error}';
	@override String get addPlexTitle => 'Plex ilə daxil ol';
	@override String get pinExpired => 'PIN-in vaxtı bitdi. Lütfən təzədən cəhd edin.';
	@override String failedToRegisterAccount({required Object error}) => 'Hesab qeydiyyatı uğursuz oldu: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => '${product} server URL-inizi daxil edin';
	@override String get addConnectionTitle => 'Qoşulma əlavə et';
	@override String addConnectionTitleScoped({required Object name}) => '${name} profilinə əlavə et';
	@override String get signInWithPlexCard => 'Plex ilə daxil ol';
	@override String get signInWithPlexCardSubtitle => 'Bu cihazı səlahiyyətləndirin. Paylaşılan serverlər əlavə olunur.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex hesabını səlahiyyətləndirin. Home istifadəçiləri profillərə çevrilir.';
	@override String connectToMediaBrowserCard({required Object product}) => '${product}-a qoşul';
	@override String get connectToMediaBrowserCardSubtitle => 'Server URL-inizi, istifadəçi adınızı və şifrənizi daxil edin.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => '${product} serverinizə daxil olun. ${name} ilə əlaqələndirilir.';
	@override String get borrowFromAnotherProfile => 'Başqa profildən götür';
	@override String get borrowFromAnotherProfileSubtitle => 'Başqa profilin qoşulmasını yenidən istifadə edin. PIN ilə qorunan profillər PIN tələb edir.';
	@override String get invalidCredentials => 'İstifadəçi adı və ya şifrə yanlışdır';
	@override String get authResponseNotJson => 'Autentifikasiya cavabı etibarlı JSON deyildi';
	@override String get authResponseIncomplete => 'Serverin giriş cavabı natamam idi';
	@override String get quickConnectRejected => 'Quick Connect server tərəfindən rədd edildi';
	@override String get quickConnectNotJson => 'Quick Connect cavabı etibarlı JSON deyildi';
	@override String get quickConnectMissingFields => 'Quick Connect cavabında kod və ya məxfi açar yoxdur';
	@override String get quickConnectPollRejected => 'Quick Connect sorğulaması server tərəfindən rədd edildi';
	@override String get serverTimedOut => 'Server vaxtında cavab vermədi';
	@override String get responseNotJson => 'Server cavabı etibarlı JSON deyildi';
	@override String responseMissingIdentity({required Object product}) => 'Cavabda ID və ya server adı yoxdur — bu, ${product} serveridir?';
	@override String probeFailed({required Object error}) => 'Serverə çatmaq olmadı: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Ən azı bir ${product} server URL-i daxil edin';
	@override String noReachableServer({required Object product}) => 'Əlçatan ${product} serveri tapılmadı';
	@override String urlsPointToDifferentServers({required Object product}) => 'Bu URL-lər fərqli ${product} serverlərinə aiddir';
	@override String urlDoesNotMatchServer({required Object product}) => 'Bu URL ${product} serverinə uyğun gəlmir';
	@override String get redirectUnsupported => 'Server dəstəklənməyən URL-ə yönləndirdi';
	@override String redirectDifferentHost({required Object product}) => 'Server başqa hosta yönləndirdi. Son ${product} URL-ni birbaşa daxil edin.';
	@override String get redirectInsecure => 'Server HTTPS-dən təhlükəsiz olmayan URL-ə yönləndirdi';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Server dəstəklənməyən URL-ə yönləndirdi. Son ${product} URL-ni birbaşa daxil edin.';
	@override String get directPlexServerUrl => 'Plex serverinin URL-si';
	@override String get directPlexServerUrlHelper => 'Yerel IP və portunu Plex Media Serverinizə daxil edin.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (özümlü)';
	@override String get plexTokenHelper => 'Bu serverdə auth olmadan qalıbsa boş bırakın.';
	@override String get plexTokenRequired => 'Kimliyin təsdiqlənməsi tələb olunur. Plex tokeninizi (X-Plex-Token) daxil edin.';
	@override String get connectDirectPlexCard => 'Plex Media Server (Doğrudan / Yerel)';
	@override String get connectDirectPlexCardSubtitle => 'Yerel IP və ya URL hesabı olmadan doğrudan bağlanın.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Yerel IP və ya URL ilə doğrudan bağlayın. ${name} ilə bağlanır.';
	@override String get insecureTitle => 'Şifrelə olmayan bağlantı';
	@override String insecureDescription({required Object url}) => '${url} HTTP istifadə edir. Şəbəkədəki şəxslər parolunuzu, tokenlərinizi və medianızı oxuya və ya dəyişə bilər. Mümkün olduqda HTTPS istifadə edin. Yalnız bu şəbəkəyə etibar edirsinizsə və riski qəbul edirsinizsə davam edin.';
	@override String get allowHttp => 'HTTP-yə icazə ver';
	@override String get httpsRequired => 'HTTPS və ya şifrə olmayan bir bağlantı üçün açıq-aydın izin verir.';
}

// Path: cast
class _Translations$cast$az extends Translations$cast$en {
	_Translations$cast$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Bir cihazın qapısı';
	@override String get searching => 'Xatırma aparaturları aradan...';
	@override String connectedTo({required Object device}) => 'Qəzaqə ${device}';
	@override String get device => 'Xatırma aparatı';
	@override String get readyToCast => 'Hazır atmaq';
	@override String get subtitle => 'Altyazılar';
	@override String get serverNotAvailable => 'Medya serveri yoxdur.';
	@override String get stopCasting => 'Qısağı durdurma';
	@override String get castToDevice => 'Təlimə qalıb';
	@override String get noEpisodeAvailable => 'Bu bölümdə oynamaq mümkün deyil.';
	@override String get startFailed => 'Yayımı başlatmaq mümkün olmadı. Serveri yoxlayın və yenidən cəhd edin.';
}

// Path: automation
class _Translations$automation$az extends Translations$automation$en {
	_Translations$automation$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Video-kontroleyi kontrol etmək mümkün deyil.';
}

// Path: notifications
class _Translations$notifications$az extends Translations$notifications$en {
	_Translations$notifications$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Yeni epizod';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$az extends Translations$appAccess$en {
	_Translations$appAccess$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => '7 gün ərzində hər bir funksiyaya özgürlük göstərin.';
	@override String get description => '7 gün sürən bir testə başlamaq, hər bir PlezyNG funksiyasına tam qapı ilə. testdə heç bir ücret və abonə yoxdur. testdən sonra, mağazanın fiyatında bir ömürlük satın alın, ömürlük PlezyNG kilitlənir.';
	@override String get trialEndedDescription => 'Mağazanızın qiymətinə bir dəfə alış edərək PlezyNG-nin bütün funksiyalarını həmişəlik açın. Abunəlik yoxdur.';
	@override String get startTrial => '7 gün özgür sınavı başlatır';
	@override String get trialActive => '7 gün sürən bütün testiniz aktivdir.';
	@override String get trialEnded => '7 gündən sonra proses bitirir.';
	@override String get trialStartFailed => 'Bu cihazın testini salmaq mümkün deyil. lütfen bir daha çalışın.';
	@override String get lifetimeTitle => 'PlezyNG ömür boyu boşaltılmışdır';
	@override String get lifetimeBody => 'Şükürlər! hər bir PlezyNG funksiyasına lifetime qapı var.';
	@override String get manageTitle => 'PlezyNG Ömür boyu qalıb';
	@override String get manageDescription => 'Hər bir funksiyayı 7 gün üçün özgürlə deneyin, sonra mağazanın fiyatına bir payla hər şeyin ömür boyu kilidini açın.';
	@override String buy({required Object price}) => 'Hər bir funksiya ${price} üçün çalın';
	@override String get loadingPrice => 'Buğdayın fiyatı...';
	@override String get retryPrice => 'Qatırılma fiyatı';
	@override String get restore => 'Ömür boyu satın alın';
	@override String get pending => 'Müəllifinizin ömür boyu qapı və ya qapı ilə bağlı və ya qalanlıqla bağlı və ya hökm və ya qalıqla bağlı və və ya qalınlıqla bağlı bir qapıdır.';
	@override String get storeUnavailable => 'Bu sistemdə satın alınmaq üçün izin verilmə bilər.Bu sistemdə satın alma üçün izin verilməyə bilər.';
	@override String get productNotFound => 'PlezyNG lifetime unlock bu mağazada yet mevcut deyil.';
	@override String get productQueryFailed => 'Bu barədə xəbər verir ki, bu barədə “Global News Network” və “Global News Network” xəbər verir.';
	@override String get purchaseFailed => 'İnşallah bu işə qayıtmayıb.Bir daha baxın.';
	@override String get restoreFailed => 'Mən bu işdən qayıtmaq üçün mağazaya gəlməyirəm.';
	@override String get nothingToRestore => 'Bu mağazanın hesabı üçün PlezyNG ömür boyu satın alınmışdır.';
}

// Path: detail
class _Translations$detail$az extends Translations$detail$en {
	_Translations$detail$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Bitiş vaxtı: ${time}';
}

// Path: watchLink
class _Translations$watchLink$az extends Translations$watchLink$en {
	_Translations$watchLink$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Bu linki üçün Plex serverə ulaşamazdım.';
	@override String get notFound => 'Bu göstərici və filmi Plex serverinizdə bulamazdım.';
	@override String get ambiguous => 'Bu bağ birdən çox serverdə elementlər ilə eşlik edir.';
	@override String get plexOnly => 'Görüntülər linki şu anda yalnız Plex serverləri destek edir.';
	@override String get unsupportedItem => 'Görüntülənlər yalnız bir film və ya bir göstəri açılabilir.';
	@override String get menuItem => 'Görüntülər Link';
	@override String get dialogTitle => 'Linkə baxın';
	@override String get dialogShowHint => 'Bu linki açmaq bir sonraki epizod oynayır. shuffle-da şov oynamak üçün sonuna &mode=shuffle-i ekdir.';
	@override String get dialogMovieHint => 'Bu linki açmaq filmin oyununu oynayır.';
	@override String get copy => 'Kopya';
	@override String get copied => 'Link kopyalar';
}

// Path: homeLayout
class _Translations$homeLayout$az extends Translations$homeLayout$en {
	_Translations$homeLayout$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Evdə Layout';
	@override String get resetToast => 'Evə qayıdın, orijinal Plezy kahramanı düzəlmə';
	@override String get resetHeroTitle => 'Plezy-nin standart əsas banner düzənini bərpa etmək istəyirsiniz?';
	@override String get resetHeroBody => 'Hər bir sıraın kahramanı ayarını devreyar və evin üstündeki tek bir dönən bannerı, daha əvvəl kahramanın sıraları olduğu kimi geri getirir.';
	@override String get removeRowTitle => 'Evdə qalıb?';
	@override String removeRowBody({required Object title}) => '${title} xilas ediləcək.Bu xilas edilemez.';
	@override String get sync => 'Sünni';
	@override String get syncAccountTitle => 'Sizin hesabınızla Plex-i işləmək';
	@override String get syncAccountOn => 'Bu cihaz, sıra sırasını, sıraları, Hero və Auto-slide üçün diğer cihazlarınızla paylaşır.';
	@override String get syncAccountOff => 'Bu cihazın öz layoutunu saxlayır.';
	@override String get syncNow => 'Sünnə';
	@override String get plexHomeManager => 'Plex Ev yöneticisi';
	@override String get managePlexRows => 'Plezy-də Plex satırları yönetir';
	@override String get managePlexRowsDescription => 'Evdə seçilmiş yolların organizasiyası üçün açılır';
	@override String get organizeHomeRows => 'Evdə qalıb';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} sıra: Moving, Hero, Auto-slide, kaldırma';
	@override String organizeLibraryRows({required Object library}) => '${library} yolları organizə edin';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Qiyamış + ${n} sıra: Moving, Library, Home, Hero, Auto-slide';
	@override String get renderAsHero => 'Bir kahramanın kartı kimi';
	@override String get heroOnlySingleCollection => 'Bu sayı yalnız bir koleksiyonun gerçek başlıklarına çözüldüğünde mevcutdır.';
	@override String get hero => 'Heroya';
	@override String get autoSlide => 'Auto-Slayt';
	@override String get autoSlideDescription => 'Qadınlar (PC) və d-pad (TV) hər zaman çalışır və zamanlayıcının yeniden başlatılmasıdır.';
	@override String get autoSlideEditDescription => 'Bu, hər bir saniye özünə çıxır. Off: yalnız bir pul (PC) tıklayınca və ya televizyonda sol/sağ basınca hareket edir.';
	@override String get enableHeroFirst => 'Birincisi Hero.';
	@override String get showOnHome => 'Ev ekranında görünür';
	@override String get home => 'Ana səhifə';
	@override String get removeFromHome => 'Evdən çıxmaq';
	@override String get selectRowsFirst => 'İlk dəfə aşağıda yerləşdirilmiş yerlər seçilir.';
	@override String plexManagedRows({required Object n}) => '${n} Plex-manual edilmiş sıra';
	@override String get continueWatching => 'İzləməyə davam et';
	@override String get continueWatchingLibraryDescription => 'Bu kütüphaneye öz-düzgün-gelişmiş yol';
	@override String get continueWatchingHomeDescription => 'Evdə göstərilmiş olan “Gözlük”';
	@override String get nextUpHomeDescription => 'Sonraki İçerikDünyanın ən azı yerləri evdə';
	@override String get library => 'Kitabxana';
	@override String get showInRecommended => 'İnternet-kitabətdə danışılanlar';
	@override String get customPlexRow => 'Xərimlər Plex';
	@override String get heroNeedsLibrary => 'Birincisi, “Bibliothèque” – “Hero”ın bir yerə baxması lazımdır.';
	@override String get heroNeedsSurface => 'Birincisi kütüphanə və ya evə baxın — Hero bir yerə göstərmək lazımdır';
	@override String get removeHub => 'Həkimə qalıb';
	@override String get noPlexRows => 'Bu kütüphane üçün Plex-managed sıra qayıtılıb.';
	@override String get openDetails => 'Açıklama Detayları';
	@override String get heroCards => 'Hero kartları';
	@override String get tapHeroCard => 'Bir kahramanın kartı';
	@override String get tvPlayFocus => 'Televiziyası: Play düğmesi';
	@override String get tvPlayFocusDescription => 'D-Pad aşağı durur, bir sonraki sıraya çıxmadan önce Play düğmesine.';
	@override String get tvWrap => 'Televiziyası: Gəlim kartları';
	@override String get tvWrapDescription => 'Son kartın üstündə ilk kartın üstünde durdurulur, son kartın üstündən sol kart da ilk kartın yan barına qaytarır.';
	@override String get castOnHero => 'Hero Banner-da qalıb';
	@override String get castOnHeroDescription => '“Müslər” adlı filmdə “Müslər” və “Müslər” adlı filmdə “Müslər” və “Müslər” adlı filmdə bir neçə dəfə baxılıb.';
	@override String get customRows => 'Özəllər';
	@override String get loading => 'Evdə yerleşim yeri...';
	@override String get noCustomRows => 'Artıq heç bir qalıq yok';
	@override String get addRowHint => 'Birini yaratmaq üçün Home Add rw istifadə edin.';
	@override String get addHomeRow => 'Home Rəviş';
	@override String get addHomeRowDescription => 'Bir kategoriyi seçin; yeni sıra automatik olarak Organizer-a daxil edilir';
	@override String get removeRow => 'Rövidini kaldırır';
	@override String get recentlyAdded => 'Son əlavə olunanlar';
	@override String get recentlyReleased => 'Son zamanlarda yayımlanan';
	@override String get movieCollections => 'Film Koleksiya';
	@override String get showCollections => 'Koleksiya göstərişi';
	@override String get rowTitle => 'Rövb Adı';
	@override String get content => 'Qadınlar';
	@override String get showThisRowIn => 'Bu yolda belə bir şey göstərilir:';
	@override String get libraryRecommended => 'Kütüphanə danışmaq';
	@override String get heroCard => 'Hero kartı';
	@override String get heroCardDescription => 'Bir kartın yerində bir kartın yerində bir kartın yerində bir kartın yerində görünür.';
	@override String get heroUnavailableDescription => 'Bu sıra yalnız bir koleksiyonun gerçek başlığına çözüldüğünde mevcutdur - birdən çox koleksiyon seçildiğinde, bir başlığı dönmək mümkün deyil.';
	@override String get librariesSelection => 'Kütüphanələr (her kütüphanə daxil olmaq üçün bütün kontrolsüzləri bırakın)';
	@override String get librariesMergedDescription => 'Burada hər bir kütüphane bu bir sıraya birleşir.';
	@override String get movieCollectionsSelection => 'Film koleksiyonları (tüm seçilmiş kütüphane üçün kontrol edilməyənləri bırakın)';
	@override String get showCollectionsSelection => 'Koleksiyaları görünür (tüm seçilmiş kütüphane üçün kontrolsüz olanları bırakın)';
	@override String get collectionRowsDescription => 'Bir koleksiyonun tam bir dəfə birləşirse, onun başlığı doğrudan bir sıraya çıxır.Birdən çox bir dəfə birləşdirsə, hər koleksiyon bir poster olarak görünür - o koleksiyonu açmak üçün onu tövbə edin.';
	@override String get allCollections => 'Bütün Koleksiya';
	@override String get noRowsHere => 'Burada bir sıra yoxdur.';
	@override String get hideWatchedRows => 'Görüntülənlər bir sıraya düşüb';
	@override String get hideWatchedRowsDescription => 'Ev və kütüphane üçün bütün izləmiş başlıklar ev və kütüphane ilə ayrılır.';
	@override String get untitledCollection => 'Untitled Koleksiya';
	@override String get moveRowHint => 'Yüksə/Down: Moving sequence · Select: drop it here · Back: Cancel';
	@override String get organizeRowsHint => 'Bir sıra seçin (ya da tutun): seçin · Sağ/Sağ: sıra seçin · Geri: tamamlandı';
	@override String get layoutNavDescription => 'Bu kategorilər, kütüphərlər və koleksiyon kategorileri seçilir.';
	@override String get editHomeRow => 'Evdə qalıb';
	@override String get resetHeroButton => 'Xatırım oyunları Plezy';
	@override String get reorderingUnlocked => 'Yenə açılma';
	@override String get reorderingLocked => 'Yenə qalıb';
	@override String get rowsCanBeDragged => 'Sətirlərin yerini sürükləyərək dəyişə bilərsiniz. Bunun qarşısını almaq üçün kilidə toxunun.';
	@override String get tapLockToDrag => 'Sürücüsüz qapı çalın';
	@override String customRowLabel({required Object title}) => 'Qadın sayı: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Gizlət';
	@override String get remove => 'Sil';
	@override String get libraryResumeRow => 'Bu kütüphaneyi yenə';
	@override String get pressAgainToDelete => 'Yenə xilas etmək üçün basın';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'Onda';
	@override String get resetHeroButtonDescription => 'Hər bir sıraın kahramanı ayarını devreyar və kahramanın sıraya gəlmədən əvvəl olduğu kimi, üstündə bir dönən bannerı geri getirir.';
	@override String get tapHeroCardDescription => 'Bir Hero kartı seçmək və ya oynamaq başlar və ya onun ayrıntılarını açır.';
	@override String get heroTapPlayDescription => 'Seçilmiş elementdən hemen başlayın.';
	@override String get heroTapDetailsDescription => 'Seçilmiş elementin ayrıntılarını seçməkdən əvvəl açın.';
}

// Path: platform
class _Translations$platform$az extends Translations$platform$en {
	_Translations$platform$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG yerel ağınızda medya və playback cihazlarına bağlanır.';
	@override String get locationPermission => 'Yerli şəbəkəni aşkar etmək və media serverlərinə qoşulmaq üçün iOS tələb etdikdə PlezyNG məkan məlumatlarına girişdən istifadə edir.';
	@override String get photoLibraryPermission => 'Media üçün təsvir kimi istifadə etmək məqsədilə foto kitabxananızdan şəkillər seçin.';
	@override String get cameraPermission => 'Companion Remote pultunu qoşmaq üçün QR kodlarını skan edin.';
}

// Path: universalMedia
class _Translations$universalMedia$az extends Translations$universalMedia$en {
	_Translations$universalMedia$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Açık medya';
	@override String get shortcutHelp => 'Bu oturum üçün bir bağlantı, playlist və ya dosyayı oynayın.';
	@override String get intro => 'Playback PlezyNG standart oynatıcı ilə istifadə edir və kütüphaneye tarih ekləmir.';
	@override String get openWhat => '- Neyi açmaq istəyirsiniz?';
	@override String get stream => 'Trafik adresi';
	@override String get playlist => 'Oyunçı';
	@override String get files => 'Fillər';
	@override String get favorites => 'Sürücüsüz favoritlər';
	@override String get address => 'Medyanın adresi';
	@override String get addressHelp => 'HTTPS-i tercih edilir. tanınmış kimlik və ya imza parametrləri olan URL-lər yalnız bu oturum üçün istifadə edilir və favori olarak saklanamaz.';
	@override String get displayName => 'Görüntülər adı (optional)';
	@override String get displayNameHelp => 'Bir oyuncu və sistem medya kontrolləri üçün kısa adı seçin.';
	@override String get allowHttp => 'HTTP bağlantısı qapılmamışdır';
	@override String get allowHttpHelp => 'HTTP bağlantıyı şifrə etmir. yalnız güvenilir bir ağda izin verin. mümkün olduğunca HTTPS-i istifadə edin.';
	@override String get advancedProtocols => 'MPV yalnız: RTSP, RTMP/RTMPS, UDP və ya RTP adresi daxil edin.';
	@override String get liveStream => 'Yaşayan kimi davranın';
	@override String get liveStreamHelp => 'Video və ya radyo üçün bunu istifadə edin. App zaman barını, skip düğmelerini və go-to-time seçeneğini gizir.';
	@override String get privateSession => 'Və bu video-da yalnız bu adresi istifadə edir.Bu profildə tutmaq üçün bir seçkin akış favorisini saklayın.';
	@override String get saveFavorite => 'Favoritları salmaq';
	@override String get playNow => 'Şimdilik oynayın';
	@override String get favoriteSaved => 'Bu profillə saldığın sevgilisi';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${count}-in düzgün və ya güvenli olmayan oynay listə girişini atıb.',
		other: '${count}-in kömək etmədik və ya güvenli olmayan oynatma listəsi girişləri atıldı.',
	);
	@override String get playlistAddress => 'Playlist adresləri';
	@override String get playlistAddressHelp => 'M3U, M3u8 və ya PLS oynatma listasını bir web adresindən açın.';
	@override String get choosePlaylist => 'Playlist filləri seçin';
	@override String get openPlaylist => 'Açıklandı Playlist';
	@override String get playlistFormatsHelp => 'Bir oyun listəsi 1000-dən çox element və 2 MB içerir. HLS akışlar kimi açılır, bu yüzden oyuncu bir kalitə seçebilir.';
	@override String get saveQueuePlaylist => 'Növbəni pleylist kimi saxla';
	@override String get queuePlaylistSaved => 'Pleylist media fayllarının yanında saxlanıldı.';
	@override String get queuePlaylistUnavailable => 'Bu növbəni təkrar istifadə edilə bilən yerli pleylist kimi saxlamaq mümkün deyil.';
	@override String get queuePlaylistFolderRequired => 'Yadda saxlama yeri növbədəki fayllarla eyni qovluqda olmalıdır.';
	@override String get noFavorites => 'Movqe.Az xəbər verir ki, Hollandiyada futbolçular bu profildə qalır.';
	@override String get removeFavorite => 'Movqe favoritləri';
	@override String get filesHelp => 'Video, audio və ISO filləri seçin. Fillər və URL-lər kütüphane tarihinə daxil olmaz.';
	@override String get chooseFiles => 'Fillər seçin';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '1 seçilmiş fil',
		other: '${count} seçilmiş dosyalar',
	);
	@override String get wifiTransfer => 'Fillər Wi-Fi yoluyla göndərilir';
	@override String get wifiTransferHelp => 'Desteklə olan dosyaları bir browserdan aynı güvenilir ağda göndərir.';
	@override String get wifiTransferIntro => 'Bu adresi başqa cihazda bir browserda açın.Bu cihazın Fillər və kitab kütüphanasına ekləmək üçün dosyaları seçin.';
	@override String get wifiTransferPrivacy => 'Bu cihaz yerel ağınızdan dosyaları alınır.Bu adresi bilən kimsə, transferin durdurulana qədər və ya adres 15 min sonra sona erdirilmə qədər dosyalarını göndərir. Maksimum: 100 dosya, 4 GiB fil başına, 10 GiB toplam.';
	@override String get wifiTransferStarting => 'Özel, zamanla sınırlı bir transfer hazırlanır.';
	@override String get wifiTransferUnavailable => 'İnternetdən istifadə etmək mümkün olmayıb.İnternetin qapısını kontrol edin və bir daha çalışın.';
	@override String get openThisAddress => 'Bu adresdən birini gönderdən aparaturda açın';
	@override String get copyAddress => 'Transfer adresini kopyalar';
	@override String get addressCopied => 'Transfer adresi kopyalanır';
	@override String transferExpires({required Object time}) => 'Bu adres ${time}-də sona erdirir.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${count} faili alınır',
		other: '${count} filləri alınmışdır',
	);
	@override String uploadedData({required Object size}) => '${size} ilə bağlı';
	@override String get stopTransfer => 'Transfert və adresin iptal edilməsi';
	@override String get startTransfer => 'Transfer başlatır';
	@override String get wifiImportedFiles => 'Wi-Fi təyyarə';
	@override String get wifiBrowserTitle => 'Fəlilə Göndənlər';
	@override String get wifiBrowserIntro => 'Fillər bu cihazın Dosya və kitab kütüphanəsində salınır. Maksimum: 100 dosya, 4 GiB filə, 10 GiB toplamda.';
	@override String get uploadFilesLabel => 'Göndən Fillər';
	@override String get uploadSelected => 'Seçilmiş dosyaları yüklə';
	@override String get uploadSelectFirst => 'Əvvəlcə bir və ya daha çox fil seçin.';
	@override String get uploading => 'Göndən';
	@override String get uploadComplete => 'Fəlilə PlezyNG-a daxil olmuşdur.';
	@override String get uploadFailed => 'Bu sayıyı açın və tekrar çalışın.';
	@override String get liveCue => 'Yaşama';
	@override String get liveSession => 'Live akış';
	@override String get liveCueHelp => 'Live video və radyo üçün, app zaman barını giz edir və skip düğümləri. adresi və ya tarihini gözləyir.';
	@override String get sessionOnly => 'Bu oyun yalnız oturumdan';
	@override String get sessionOnlyHelp => 'Playback heç vaxt ilerməyi və ya tarihini saklamaz. bu profildə tutmaq üçün bir favorit olarak akışını saklayın, eğer uygun olursa.';
	@override String get pictureAdjustments => 'Görüntülər ayarları';
	@override String get pictureHelp => 'Görüntüləri dəyişdirənlər yalnız bu playback-i etkilə bilər.';
	@override String get resetPicture => 'Görüntülər';
	@override String get brightness => 'Aydınlıq';
	@override String get contrast => 'Kontrast';
	@override String get gamma => 'Gamma';
	@override String get hue => 'Həyat';
	@override String get saturation => 'Saturasiya';
	@override String get view360 => 'Görüntülər 360° video üçün';
	@override String get view360Help => 'Bu görüntü üçün MPV-in FFmpeg v360 filtresine ihtiyacı var.';
	@override String get view360Unavailable => 'Bu mpv yapı 360° filtresini istifadə edemezdi.';
	@override String get view360Yaw => 'Horizontal görüş';
	@override String get view360Pitch => 'Vertikal görüş';
	@override String get view360FieldOfView => 'Görüş alanı';
	@override String get recordStream => 'İndi Live Stream';
	@override String get stopRecording => 'İndirmə və kaydırma';
	@override String get recordingStarted => 'Xatırmaq aktivdir. playback durdurur və kayıtları saldıra bilər.';
	@override String get recordingSaved => 'Rekordlar tamamlandı və saldıq.';
	@override String get recordingActive => 'Bu cihazın qalındığı üçün, playback durdurur və saldıra bilər.';
	@override String get recordingFormatHelp => 'Video üçün, MKV və ya MPEG-TS seçin.';
	@override String get replaceRecordingTitle => 'Bu filmləri dəyişib?';
	@override String get replaceRecordingHelp => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.';
	@override String get replaceRecording => 'Filə dəyişdirmək';
	@override String get discHelp => 'Bu bilgisayarın optik sürücüsündən bir disk açılır.Ayrıca cihaz dosyalarından ISO görüntü açabilirsiniz.';
	@override String get discs => 'Optik disk';
	@override String get editionOrTitle => 'Buraxılış və ya disk başlığı';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Blu-ray';
	@override String get audioCd => 'Audio CD';
	@override String get discAvailability => 'Disk playback-ın uyumlu MPV yapılandırması, supported drive və operating-system izinə ehtiyacıdır.';
	@override String get converterTitle => 'Yerel medya dosyasını dönüştürmək';
	@override String get converterHelp => 'Yerli faylı FFmpeg ilə çevirin və ya konteynerini yenidən qurun.';
	@override String get converterIntro => 'Yerel bir audio və video dosyasını daha çox cihazlarda çalışan formata dönüştürür.';
	@override String get converterPrivacy => 'Bu bilgisayarda FFmpeg yüklü olmalıdır. Conversion yalnız yerel dosyaları oxur. Streamları indirmir və DRM-i kaldırmaz.';
	@override String get converterChooseInput => 'Yerel medya dosyasını seçin';
	@override String get converterFormat => 'Çıkan formatı';
	@override String get converterMp4 => 'MP4 · H.264 və AAC';
	@override String get converterM4a => 'M4A və AAC audio';
	@override String get converterMp3 => 'MP3 və audio';
	@override String get allowFtp => 'FTP-yə icazə ver';
	@override String get allowFtpHelp => 'FTP medianı şifrələmədən göndərir. Yalnız etibarlı şəbəkələrdə istifadə edin.';
	@override String get converterSaveAs => 'Konvertiyasiya medya';
	@override String get converterExtensionMismatch => 'Bir filnamə seçin, seçilmiş çıkış genişliği ilə.';
	@override String get converterUnsupportedInput => 'Video və ya audio fil seçin.';
	@override String get converterLocalOnly => 'Seçilmiş dosya yerel bir cihaz yolu olarak mevcut deyil.';
	@override String get converterReplaceTitle => 'Bu dosyayı dəyişir?';
	@override String get converterReplaceHelp => 'VVD-nin idarə etdiyi superkarlar – bu, artıq çox mərkəzdədir.';
	@override String get converterStarting => 'Başlamaq üçün FFmpeg...';
	@override String get converterProgress => 'Bu bilgisayara dönüştürmək üçün...';
	@override String get converterComplete => 'Yeni fil hazırdır.';
	@override String get converterFfmpegMissing => 'FFmpeg yoxdur və ya bu formatı dəstəkləmir.';
	@override String get converterFailed => 'Konversiya başarısız oldu. kaynak dosyasının oxuyub və destinasyonun yeterli boş alanı var olduğunu kontrol edin.';
	@override String get converterCancelled => 'Konversiya iptal edilmişdir. eksakt çıkış kaldırılmışdır.';
	@override String get converterDesktopOnly => 'Yerel dönüşüm, FFmpeg yüklü olan masaüstü bilgisayarlarda mevcutdur.';
	@override String get converterStart => 'Filə dönüştürülür';
	@override String get mediaToolsTitle => 'Medya təyyarəsi';
	@override String get mediaToolsShortcut => 'Media və ya qapı və ya komandası ilə istifadə edin.';
	@override String get mediaToolsIntro => 'Choose a focused tool. Capture and stream-out use FFmpeg installed on this desktop. Extensions and CLI commands use bounded HTTPS requests and the existing Open media flow.';
	@override String get mediaToolsAccessibility => 'Təlim seçimler və kontrollar touch, point, keyboard və D-pad fokus ilə çalışır. Rekord, paylaşım və arama statusu dəyişdirilməsi bildirilir.';
	@override String get mediaTool => 'Medya təyyarəsi';
	@override String get captureIntro => 'Record your screen or a camera to an MP4 file on this computer. FFmpeg must be installed and include the H.264 encoder.';
	@override String get captureNoDevices => 'No screen or camera was found. Check FFmpeg capture support and operating-system privacy permissions.';
	@override String get captureSource => 'Kamera və ekran';
	@override String get captureScreen => 'Ekran';
	@override String get captureAudioSource => 'Audio giriş (optional)';
	@override String get captureAudioHelp => 'Bir mikrofondan və ya var olan girişdən audio eklə. cihaz seçenekleri FFmpeg və sistem izni ilə bağlıdır.';
	@override String get captureAudioNone => 'Audio yoxdur';
	@override String get captureDefaultAudio => 'İndirimli audio';
	@override String get captureWaylandHelp => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.';
	@override String get captureFrameRate => 'Xatırım çerçevəsi';
	@override String get capturePrivacy => '“Mikrofon” filinin seçilməsinə yalnız kaydırılır.Mikrofon çekimi seçicidir.PlezyNG, kaydı yükləmir.';
	@override String get captureSaveAs => 'Ekranın qalıbı kimi';
	@override String get captureExtensionMismatch => '.mp4-də son olan bir filnamə seçin.';
	@override String get captureFfmpegMissing => 'FFmpeg və ya H.264 video kodlayıcısı mevcut deyil. destekli FFmpeg yapıları yüklə, sonra tekrar çalışın.';
	@override String get captureFailed => 'Xatırmaq mümkün olmayıb. cihazın izinini, mevcut depolama və FFmpeg supportunu kontrol edin.';
	@override String get captureSaved => 'Ekranın qalıb olması.';
	@override String get captureElapsedLabel => 'Rekord zamanı';
	@override String get captureStart => 'Rekord başlatmaq';
	@override String get capturePreview => 'Pleyerdə önizləmə';
	@override String get capturePreviewHelp => 'Seçilmiş mənbəyə standart pleyerdə baxın. Bu, yalnız cari sessiya üçündür və yazı yaratmır. Cihaz dəstəyi və icazələr MPV-dən və əməliyyat sistemindən asılıdır. Önizləmə yalnız videonu göstərir; yadda saxlanan yazılara əlavə audio daxil edilə bilər.';
	@override String get capturePreviewActive => 'Canlı önizləmə · yazılmır';
	@override String get captureStop => 'Qısa və qısa';
	@override String get captureMode => 'Tövbə';
	@override String get shareMode => 'Paylaşım';
	@override String get shareIntro => 'PlezyNG, HLS-in bir zamanlı akışını yaratır.';
	@override String get sharePrivacy => 'Qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar,';
	@override String get shareChooseFile => 'Medya filləri seçin';
	@override String get shareChooseHelp => 'Yerel bir audio və video dosyası seçin. dosyası bu bilgisayarda kalır.';
	@override String get shareFfmpegMissing => 'FFmpeg və ya H.264/AAC kodlayıcıları mevcut deyil. H.264 və AAC kodlayıcı köməkiyle FFmpeg yükləyin.';
	@override String get shareFailed => 'The stream could not start or stopped unexpectedly. Check FFmpeg and network access.';
	@override String get shareActive => 'İnternetinizə hazırdır.';
	@override String get shareEnded => 'Media sonuna gəldi və artık paylaşılmıyor.';
	@override String get shareStopped => 'Şirkətdə də bu günlər var.Şirkətdə də bu günlər var.';
	@override String get shareUrlCopied => 'İnternet adresi kopyalanır.';
	@override String get shareOpenUrl => 'Bu adresi bir oyuncuda başqa cihazda açın';
	@override String get shareQrLabel => 'QR-codu geçici akış adresi üçün';
	@override String get shareQrHelp => 'Bu sistemdə, aynı özel ağla bağlanan uyumlu bir oyuncu ilə skanlaşdırılır.';
	@override String get shareHttpHint => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.';
	@override String get shareCopyUrl => 'Qızıl adresini kopyalama';
	@override String get shareExpiresLabel => 'Linklər bitirir';
	@override String get shareStarting => 'Trafik hazırlanması üçün...';
	@override String get shareStart => 'Paylaşım başlatır';
	@override String get shareStop => 'Paylaşımın durması';
	@override String get extensionsMode => 'Xərimlər və CLI';
	@override String get extensionsIntro => 'Add a data-only search extension to find media. Choose a result to load it into the familiar Open media form.';
	@override String get extensionsPrivacy => 'Bir manifesto bir HTTPS arama son noktası və map yanıt alanları tanımlayabilir. kodu çalıştıramaz, istey başlıkları, filları oxuma, və ya başlat shell komandaları.';
	@override String get extensionImport => 'Açıklama: Manifest';
	@override String get extensionEmpty => 'Birini ekləmək üçün bizə güvenilir bir manifesto JSON faili seçin.';
	@override String get extensionChoose => 'İtfaiya xidmətləri';
	@override String get extensionSearchConsent => 'Hər arzu bu HTTPS servisine sözünüzü göndərir.';
	@override String get extensionSearchLabel => 'İndi Media';
	@override String get extensionSearch => 'İtfaiya';
	@override String get extensionSearching => 'Arşivlər...';
	@override String get extensionNoResults => 'Safir medyanın nəticələri qayıtılmamışdır.Bir daha arama çalışın.';
	@override String get extensionInstallTitle => 'Bu arşivdən istifadə etmək olarmı?';
	@override String get extensionReplaceTitle => 'Bu arşivdə güncələ edilir?';
	@override String get extensionService => 'Servisi';
	@override String get extensionEndpoint => 'HTTPS endpoint';
	@override String get extensionConsent => '“Manifest” bu xidmətə göndərilir.Manifest, işləmə qalıq kodunu içermez.Sadəcə, bu son noktaya inanırsanız devam edin.';
	@override String get extensionInstall => 'Servisi artırmaq';
	@override String get extensionReplace => 'Güncellemələr';
	@override String get extensionRemoveTitle => 'Bu arşivdən çıxır?';
	@override String get extensionRemoveHelp => 'Bu, bu profillardan hizmetin silinir.PlezyNG onun son noktası ilə iletişime geçmez.';
	@override String get extensionRemove => 'Servisi kaldırır';
	@override String get extensionInvalidManifest => 'Bu fail supported extension manifest deyil. formatı üçün Open media qapı görünür.';
	@override String get extensionSaveFailed => 'Bu aktiv profillərin aktiv olması mümkün deyil.';
	@override String get extensionSearchFailed => 'İtfaiyətdən istifadə edilmə bilər.Gözlükdən istifadə etmək üçün bir dəfə baxın və tekrar baxın.';
	@override String get cliTitle => 'Komanda linki';
	@override String get cliHelp => 'plezyctl yolunu bir manifesti validasiya etmək və ya aynı genişlik arama etmək üçün kullanın. HTTPS servisini hər arama əvvəl gözləmək. Sonuçlar mevcut medya formunda açılır; başlatmaq üçün oynatma düğmesini seçin.';
	@override String get cliCopyExample => 'Komanda örnekləri';
	@override String get cliCopied => 'Komanda örnek kopyalanır.';
}

// Path: fileSources
class _Translations$fileSources$az extends Translations$fileSources$en {
	_Translations$fileSources$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fillər və kitablar';
	@override String get subtitle => '- Özünüzdən, özünüzdən, Özünüzdən və özünüzdən baxın.';
	@override String get add => 'Kaynakları artır';
	@override String get importFiles => 'İthalat Fillər';
	@override String get localFiles => 'Bu cihazda';
	@override String get source => 'Kaynak';
	@override String get name => 'İsim';
	@override String get endpoint => 'Server URL-i';
	@override String get smbEndpointHint => 'Nümunə: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'SMB serverini və bir paylaşılan qovluğu daxil edin.';
	@override String get root => 'Fərzər və Prefix';
	@override String get smbFolderHelp => 'Bütün paylaşılan qovluqdan istifadə etmək üçün boş saxlayın və ya onun daxilindəki qovluğu daxil edin.';
	@override String get username => 'İstifadəçi adı';
	@override String get smbDomain => 'Domen (istəyə bağlı)';
	@override String get password => 'Şifrə';
	@override String get token => 'API xətnamə';
	@override String get accessKey => 'Key ID qalıq';
	@override String get secretKey => 'Gizli qapı';
	@override String get sessionToken => 'Session token (İncelətif)';
	@override String get region => 'Region';
	@override String get clientId => 'OAuth müştəri ID';
	@override String get clientSecret => 'OAuth müştəri gizli (yalnız Google namizədləri)';
	@override String get allowHttp => 'Etibarlı şəbəkədə şifrələnməmiş HTTP bağlantısına icazə ver';
	@override String get smbEncryption => 'SMB3 bağlantısını şifrələ';
	@override String get smbEncryptionHint => 'NAS dəstəkləyirsə, SMB3 şifrələməsindən istifadə edin.';
	@override String get connect => 'Qoşul';
	@override String get cancel => 'Ləğv et';
	@override String get save => 'Yadda saxla';
	@override String get close => 'Bağla';
	@override String get removeSource => 'Kaynaklar qalıb';
	@override String get disconnectMessage => 'Bu mənbə ilə əlaqə kəsilsin? Endirilmiş fayllar, oxu və dinləmə tarixçəniz bu cihazda qalacaq.';
	@override String get localFolder => 'Fildi seçin';
	@override String get empty => 'Hələlik burada heç nə yoxdur';
	@override String get emptyHint => 'Bir kitab, bir audiobüslər, bir musiqi və ya bir video bağlayın.';
	@override String get search => 'Bu folderı arama';
	@override String get searchCached => 'İnşaat kütüphanəsi';
	@override String get refresh => 'Yenilə';
	@override String get loadMore => 'Daha çox yüklə';
	@override String get offline => 'Offline ilə bağlı';
	@override String get download => 'Offline qalıb';
	@override String get removeDownload => 'Offline kopya';
	@override String get continueReading => 'Okuma devamı';
	@override String get continueListening => 'Qısaq dinlə';
	@override String get continueWatching => 'Görüşə devam edin';
	@override String get read => 'Qısaq';
	@override String get listen => 'Qısaq';
	@override String get play => 'Oynat';
	@override String get pause => 'Fasilə';
	@override String get stop => 'Saxla';
	@override String get startOver => 'Başlıq';
	@override String get finished => 'Bitdi';
	@override String get markFinished => 'Mark bitir';
	@override String get markUnfinished => 'Markın sonunu';
	@override String get editions => 'Yayınlar və dosyalar';
	@override String get chapters => 'Hissələr';
	@override String get bookmarks => 'Bookmark və notlar';
	@override String get bookmark => 'Bookmark və';
	@override String get highlight => 'Yüksək';
	@override String get note => 'Notlər';
	@override String get delete => 'Sil';
	@override String get export => 'Eksport notları';
	@override String get exported => 'Eksportə alınan';
	@override String get sync => 'Sink progresları';
	@override String get synced => 'Sünnetlər';
	@override String get conflict => 'Bir çox yerdə bir yer var, bir yerdə bir seçin.';
	@override String get useLocal => 'Bu cihazı kullanın';
	@override String get useRemote => 'Diğer cihazları kullanın';
	@override String get history => 'Position Tarihi';
	@override String get groupAudio => 'Bir audiobüsləri kimi dinləyin';
	@override String get groupHint => 'Bu ildə yüklən audio dosyaları birləşir.İlkə bütün sayfa yüklə.';
	@override String get order => 'File ordusu';
	@override String get moveUp => 'Yüksək';
	@override String get moveDown => 'aşağı doğru hareket';
	@override String get speed => 'Playback hızı';
	@override String get sleep => 'Yuxu taymeri';
	@override String get sleepOff => 'Söndürülüb';
	@override String get endChapter => 'Başqapının sonuna';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} dəqiqə',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} dəqiqə',
	);
	@override String get skipBack => 'Geri qayıdın';
	@override String get skipForward => 'İstiqlaşma';
	@override String get smartRewind => '“Smart”dan sonra bir neçə dəfə';
	@override String get playbackOptions => 'Qısa seçenekleri';
	@override String remaining({required Object time}) => '${time} İndər';
	@override String get contents => 'İçərlər';
	@override String get readerSettings => 'Qısaq ayarları';
	@override String get fontSize => 'Text ölçüsü';
	@override String get lineHeight => 'Line-düzər';
	@override String get margin => 'Marqət';
	@override String get font => 'Tiplər';
	@override String get serif => 'Serifik';
	@override String get sans => 'Xərxət olmadan';
	@override String get mono => 'Monopoli';
	@override String get columns => 'Kolonlar';
	@override String get scroll => 'Vertikal olaraq';
	@override String get justify => 'Texti Xalət';
	@override String get readerTheme => 'Sayfa görünüşü';
	@override String get appTheme => 'App Təmə';
	@override String get paper => 'Kağız';
	@override String get sepia => 'Səbri';
	@override String get night => 'Gecə';
	@override String get readAloud => 'Bu səhifəni səsləndir';
	@override String get readAlong => 'Okumaya devam edin';
	@override String get stopReading => 'Səsləndirməni dayandır';
	@override String get searchBook => 'Kitabın arşusu';
	@override String get noMatches => 'Oyunlar yoxdur';
	@override String get previousPage => 'Əvvəlki səhifə';
	@override String get nextPage => 'Növbəti səhifə';
	@override String page({required Object number}) => 'Sayfa ${number}';
	@override String get externalBlocked => 'Oxu proqramında kitabların xarici keçidləri deaktiv edilib.';
	@override String get loading => 'Açılımı...';
	@override String get narrator => 'Tədbir';
	@override String get audio => 'Səs';
	@override String get video => 'Video';
	@override String get ebooks => 'Ebook';
	@override String get all => 'Hamısı';
	@override String get downloads => 'Offline fillər';
	@override String get confirmDelete => 'Seçilmiş oflayn nüsxə silinsin? Oxu və ya dinləmə mövqeyiniz və qeydləriniz saxlanacaq.';
	@override String get errorAuthentication => 'Bu il daha sonra bu il yeniden bağlanmaq üçün.';
	@override String get errorPermission => 'Bu mənbə tələb olunan fayla giriş icazəsi vermədi.';
	@override String get errorUnavailable => 'Bu barədə bir dəfə daha baxmayaraq, bir dəfə daha yazıb, bir dəfə də yazıb.';
	@override String get errorUnsupported => 'Bu formatı və/y bağlantı bu cihazda desteklə etmir. kaynak ayarları kılavuzunu gözləyin.';
	@override String get errorInvalidData => 'Bu faylı və ya serverin cavabını təhlükəsiz şəkildə oxumaq mümkün olmadı.';
	@override String get errorCancelled => 'Operasiya iptal edildi.';
	@override String get errorConflict => 'Bir neçə dəfə bir neçə dəfə bir dəfə bir dəfə seçilir.';
	@override String get signIn => 'Daxil ol';
	@override String get reconnect => 'Yenidən qoşul';
	@override String get folderHelp => 'Bu, S3 URL-ləri buqeti içerir.';
	@override String get preferences => 'İsteqlər';
	@override String get timePosition => 'Mövqe';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Subtitle Təbri';
	@override String get none => 'Bir';
	@override String get fullscreen => 'Full ekran';
	@override String get syncLocation => 'Movqeynlik filosu (optional)';
	@override String get syncLocationHint => 'PlezyNG statusu üçün dedikodul bir WebDAV klasör. şartlı yazılar istifadə edir; medya dəyişməzdir.';
	@override String get audiobooks => 'Avidiyalı';
	@override String get comics => 'Komikslər';
	@override String get scan => 'Kitaplar və medyanın skanları';
	@override String get browserReader => 'Open Əsət';
	@override String get browserReaderHelp => 'Oxuyucu brauzerinizdə açıqdır. Oxuduğunuz yeri və qeydlərinizi saxlamaq üçün PlezyNG tətbiqini açıq saxlayın.';
	@override String get on => 'Onda';
	@override String get advancedSetup => 'App-in təhrif';
	@override String get microsoftSignIn => 'Microsoft ilə giriş yapın';
	@override String get zoomIn => 'ZOOM İÇİN';
	@override String get zoomOut => 'ZOOM İÇİN';
	@override String get fitPage => 'Əsas sayfa';
	@override String get fitWidth => 'Xərimət';
	@override String get actualSize => 'Günlük ölçü';
	@override String get goToPage => 'Sayfaya gəlin';
	@override String get goToSection => 'Qəzaq başlığı';
	@override String pageRange({required Object count}) => '1dən ${count} qədər bir sayı girin';
	@override String get pageLayout => 'Sayfa Layout';
	@override String get automatic => 'Avtomatik';
	@override String get singlePage => 'Bir sayfa';
	@override String get twoPages => '2 sayfa';
	@override String get readingDirection => 'Qısaq yönü';
	@override String get leftToRight => 'Soldan sağa';
	@override String get rightToLeft => 'Sağdan sola';
	@override String get letterSpacing => 'İtraflar';
	@override String get wordSpacing => 'Sözlər';
	@override String get readerControlsHelp => 'Səhifəni böyütmək üçün iki barmağınızı aralayın və ya böyütmə düymələrindən istifadə edin. Səhifəni hərəkət etdirmək üçün sürükləyin. Ctrl/⌘ ilə + və ya − miqyası dəyişir; Ctrl/⌘ ilə 0 onu sıfırlayır. Page Up və Page Down səhifələri dəyişir.';
	@override String get imagePage => 'Komiks səhifəsi';
	@override String get resetReader => 'Read Preferences - Qəzaqlama';
	@override String get zoom => 'Miqyas';
	@override String get useFiles => 'Fillər və kitablar';
	@override String get cancelScan => 'Scanı iptal et';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Offline download limitləri';
	@override String get offlineQuotaHelp => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.';
	@override String get offlineStorageUsage => 'Offline təyyarə';
	@override String get reservedStorage => 'Rezervasiya';
	@override String get downloadQueue => 'İndir kiçik';
	@override String get downloadRunning => 'İndirmə';
	@override String get downloadQueued => 'Bekənlər';
	@override String get downloadPaused => 'İstihbarat';
	@override String get downloadFailed => 'RETRİ İhtiyaç';
	@override String get importing => 'İthalat';
	@override String get importInterrupted => 'İhracat durduruldu; xilas edilmə';
	@override String get errorQuotaExceeded => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın ulduzduğunu göstərir.';
	@override String get errorStorageLow => 'Bu sistemin korunması üçün bağımsız bir aparatur depoları yoxdur.';
	@override String get errorStorageUnavailable => '"PlezyNG" özgür cihazın depolarını kontrol edemezdi, bu yüzden yazmaq durduruldu.';
	@override String get removeDownloadJob => 'Download İndir';
	@override String get downloadAlreadyComplete => 'Bu download bitirilmə əvvəl, kaldırılabilir. element şimdi çevrimdışı mevcutdur.';
	@override String get confirmRemoveDownloadJob => 'Bu indirmeyi kaldırın və kısmi indirilmiş məlumatları silinir? pozisyonunuz və notlarınız kalır.';
}

// Path: lending
class _Translations$lending$az extends Translations$lending$en {
	_Translations$lending$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Public kütüphane';
	@override String get add => 'Bir kütüphane də eklə';
	@override String get other => 'Bir çox kütüphane';
	@override String get libraryName => 'Kütüphanın adı';
	@override String get libraryUrl => 'İnternet kütüphanəsi';
	@override String get libraryUrlHint => 'Kitabın katalogunu və ya sayfanı istifadə edin.';
	@override String get intro => 'Kitabınızdan borç alın, kitabınızı qapı tutun.';
	@override String get handoff => 'İndi, yazın, yazın və öz kütüphaneyi öz servisinizlə güvenli bir şekilde yazın.';
	@override String get openService => 'Open Kütüphanə';
	@override String get findLibrary => 'Bir kütüphaneyi bulma';
	@override String get search => 'Kitablar və yazarlar arama';
	@override String get catalogue => 'Katalog';
	@override String get loans => 'Kredisi';
	@override String get holds => 'Rezervasiyalar';
	@override String get signIn => 'Kitabınızla giriş olun';
	@override String get waiting => 'Bu gün, bu gün, bu browserda girişini bitir, sonra buraya qayıdın.';
	@override String get cancel => 'Ləğv et';
	@override String get disconnect => 'Kütüphanə çıxmaq';
	@override String get disconnectMessage => 'Bu kitabxana bu profildən silinsin? Götürdüyünüz kitablar və rezervasiyalarınız kitabxana hesabınızda qalacaq.';
	@override String get getBook => 'Kitabı alın';
	@override String get checkAvailability => 'Hazırlıq kontrolü';
	@override String get available => 'Kredisi üçün istifadə ediləcək';
	@override String get unavailable => 'Şu an mevcut olmayan';
	@override String get borrow => 'Müvəqqəti götür';
	@override String get placeHold => 'Rezervasiya et';
	@override String get returnBook => 'Gecə qayıtmaq';
	@override String get cancelHold => 'Rezervasiyanı ləğv et';
	@override String get confirmBorrow => 'Bu kitabı kütüphanınızdan borçluya bilərsiniz?';
	@override String get confirmReturn => 'Bu kitab indi qaytarılsın? Davam etmək üçün onu yenidən götürməli ola bilərsiniz.';
	@override String get confirmCancelHold => 'Bu kitab üçün rezervasiyanız ləğv edilsin?';
	@override String get email => 'İzinli bildirim e-mail';
	@override String due({required Object date}) => 'Əsasə ${date}';
	@override String queue({required Object position}) => 'Qadınlar ${position}';
	@override String get empty => 'Burada heç bir titulu yoxdur.';
	@override String get openLibraryNote => 'Bu yazının yazılı kitabı, yazılı kitabın yazılı kitabını, yazılı yazılı kitabının yazılı yazısını, yazılı yazı yazılı kitabına, yazılı Yazılı kitabın kitabını, Yazılı kitabının kitabını, yazı yazılı yazısı, yazılı kitap yazılı kitabından, yazılı Kitabın kitabını yazılıdır.';
	@override String get more => 'Daha çox yüklə';
	@override String get gateway => 'Bibliotekarın işləvi';
	@override String get gatewayHint => 'Bu barədə “Bütçəniz” və ya “PlezyNG administrator” tərəfindən bildirilir.';
	@override String get advanced => 'Kütüphanə integrasiya';
	@override String get loadLibraries => 'Kütüphanınızı seçin';
	@override String get expired => 'Bu kreditlər sonuna qədər sona gəldi.';
	@override String get updated => 'Kütüphanə güncəl';
	@override String get continueService => 'Servisi ilə devam edin';
	@override String get comingSoon => '“Gözəl” və “Gözəllər”';
	@override String get comingSoonDescription => 'Libby-nin bütünleşməsi yolunda olub. Libby-də kütüphaneyi istifadə edirsiniz, biz onu bağlayırıq.';
	@override String get suspendHold => 'Qısaq tutma';
	@override String get resumeHold => 'Qəzaq tut';
	@override String get suspendMessage => 'Növbədəki yerinizi saxlayıb növbəti oxucunun bu nüsxəni götürməsinə icazə verilsin? Rezervasiyanı sonra bərpa edə bilərsiniz.';
	@override String get resumeMessage => 'Kitabxananın növbəti əlçatan nüsxəni sizə təklif etməsi üçün bu rezervasiya bərpa edilsin?';
	@override String get editEmail => 'İzin dəyişmək';
}

// Path: audiobook
class _Translations$audiobook$az extends Translations$audiobook$en {
	_Translations$audiobook$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Okunmaq və dinləmək';
	@override String get syncHelp => 'Sizin cihazlarınızda okuma pozisyonları, dinleme pozisyonları, tamamlama statusu, notları və notları tutun. bağlı bir depolama hesabı seçin və hər cihazda aynı sinq kodunu kullanın. Okuma və dinleme ayrı kalır.';
	@override String get addSyncSource => 'Google Drive, OneDrive, Dropbox, WebDAV və ya S3 filləri və kitabları ilk dəfə ekləyin.';
	@override String get syncDestination => 'Sync hesabı';
	@override String get syncFolder => 'Xatırmaq və / və ya prefix';
	@override String get syncFolderHelp => 'WebDAV kaynağınızın içində ayrı bir var olan klassiyayı və ya özgün bir S3 prefiksini istifadə edin.';
	@override String get syncCode => 'Private Sink kodları';
	@override String get syncCodeHelp => 'İlk cihazınızda bir kod oluşturun, sonra o kodu diğer cihazlarınızda yazın. özel bir kopya tutun: bu şifrə edilmiş durumunuzun anahtarıdır. hər kişi için farklı bir kod kullanın.';
	@override String get showCode => 'Sink kodu göstərmək və ya gizləmək';
	@override String get newSyncCode => 'Yeni bir sink kodu yaratır';
	@override String get saveSync => 'Sink və Sink';
	@override String get disableSync => 'Bu cihazda sinqrini devreyin';
	@override String get syncSourceDisconnect => 'Bu kayanın kaldırılması burada oxuma və dinləmə sinqə açılır. şifrə edilmiş sinq filları sağlayıcının içində kalır.';
	@override String get syncReconnect => 'Depozito hesabını yeniden bağlayın';
	@override String lastSynced({required Object time}) => 'Son zamanlarda ${time}';
	@override String get syncPrivacy => 'Sadəcə şifrə edilmiş progres və notlar kaydedilir. Audio və ebook filləri, hesab tokenləri və şifrələr yüklə edilmir. Google Drive və OneDrive istifadə app depolama; Dropbox kullanır PlezyNG Sync. Enable sync ekstra yazma qapı isteyebilir. Enable, bu destinasyon progres sync sahibidir; server progres ayrı kalır. Turn sync off yerel tarih və uzaq durum tutar.';
	@override String get syncConflicts => 'Yenə qayıtma yeri seçin';
	@override String get conflictHelp => 'Bu değişikliklər bağımsızdır. tutmaq üçün pozisyonu və ya kart versiyonu seçin. Daha sonra bir zaman çizgisi və ya daha yüksek bir faiz oranı otomatik olarak kazanmaz.';
	@override String syncDevice({required Object device}) => '${device} və QXZQ';
	@override String get syncUnknownDevice => 'Bilinmeyen cihazlar';
	@override String get deletedBookmark => 'Çözülmüş kitabı';
	@override String get finished => 'Hazırda';
	@override String readingPosition({required Object percent}) => '${percent} %';
	@override String get chapterTimeline => 'Bölüm progresları';
	@override String get bookTimeline => 'Bütün kitablar';
	@override String bookRemaining({required Object time}) => 'Bu kitabda kalan zaman: ${time}';
	@override String chapterRemaining({required Object time}) => 'Bu bölümdə kalan zaman: ${time}';
	@override String get unknownRemaining => 'Bütün oyunlar oynanır ki, bütün oyunlar oynanır';
	@override String get undoSeek => 'Son arama';
	@override String get customSpeed => 'Playback hızı';
	@override String get speedHelp => 'İndərlik: 0.25 x 4 x arasında seçilir.';
	@override String get apply => 'İhtiyaç';
	@override String get customSleep => 'Qadın uyku saatləri';
	@override String get sleepMinutes => '1 min və 1440 min arası';
	@override String sleepChapters({required Object count}) => '${count} qapıdan sonra durun';
	@override String get extendSleep => '5 dəqiqə';
	@override String sleepRemaining({required Object time}) => 'Uyku vaxtı: ${time}';
	@override String get useDefaults => 'Yeni kitablar üçün bu oxuma kontrollarını kullanın';
	@override String get librarySort => 'Kitaplar';
	@override String get sortTitle => 'Başlık';
	@override String get sortAuthor => 'Yazarın';
	@override String get sortNarrator => 'Öykənlər';
	@override String get sortSeries => 'Seriyalı komandalar';
	@override String get sortRecent => 'Son zamanlarda açıldı';
	@override String get statusFilter => 'Okuma statusu';
	@override String get statusAll => 'Bütün kitablar';
	@override String get statusNew => 'Başlamadı';
	@override String get statusProgress => 'Gəlimdə';
	@override String get statusFinished => 'Hazırda';
	@override String get goToTime => 'Zamanla gəlin';
	@override String get timeHelp => 'Saatlar:minutlar:saniyələr və ya minutlar:saniyələr';
	@override String get recoveryHelp => 'Son zamanlarda şifrə edilmiş bir kopyayı ithal etmədən əvvəl və ya sinqlər verilerini düzeltmək. İthalatlar mevcut durumla birleşir; yerel sinq tarihini asılmazlar. Sinq kodunu ayrı tutun.';
	@override String get recoveryExport => 'Şifrelə qayıtma dosyası';
	@override String get recoveryImport => 'Şifrelə qayıtma dosyası';
	@override String get recoveryImportConfirm => 'Bu şifrə edilmiş qaytarma dosyasını günümüzdeki okuma pozisyonları və notlarla birleştirir? mevcut geçmişi tutulur. Paylaşılmış kütüphane və element kimlikləri içermez; ithal etmeden əvvəl hər cihazda eşitsiz kimliklər ayarlayın.';
	@override String get recoveryExported => 'Şifrelə qayıtma dosyası qurulmuşdur.';
	@override String get recoveryImported => 'İtraf verileri birləşmişdir.';
}

// Path: sourceSetup
class _Translations$sourceSetup$az extends Translations$sourceSetup$en {
	_Translations$sourceSetup$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Yadda saxlanmış server sertifikatı';
	@override String get nfsEndpointInvalid => 'nfs://nas:2049/export kimi NFS URL-i daxil edin.';
	@override String get dlnaNone => 'DLNA serveri tapılmadı. Cihazın təsvir URL-ini əl ilə daxil edin.';
	@override String get dlnaServers => 'DLNA media serverləri';
	@override String get dlnaUnavailable => 'Bu şəbəkədə DLNA axtarışı mümkün deyil. Cihazın təsvir URL-ini əl ilə daxil edin.';
	@override String get dlnaSearching => 'Yerli şəbəkədə DLNA serverləri axtarılır';
	@override String get networkSearching => 'Yerli şəbəkədə axtarılır…';
	@override String get dlnaDiscover => 'DLNA serverlərini tap';
	@override String get dlnaHelp => 'Axtarış yerli şəbəkədə multicast yayımından asılıdır. Server görünmürsə, yuxarıda onun cihaz təsviri URL-ini daxil edin.';
	@override String get dlnaRoot => 'DLNA obyekt ID-si; cihazın kökünü istifadə etmək üçün boş saxlayın.';
	@override String get passwordOrKey => 'Şifrə daxil edin və ya aşağıda özəl açar əlavə edin.';
	@override String get sshFingerprint => 'SSH host açarının SHA256 izi';
	@override String get sshFingerprintHelp => 'Server administratoru ilə yoxlayın. Serverdə ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub əmrini işlədin və SHA256 dəyərini istifadə edin.';
	@override String get sshFingerprintKeep => 'Hazırda sabitlənmiş izi saxlamaq üçün boş saxlayın və ya serverin yeni izini daxil edin.';
	@override String get sshAuthentication => 'Açıq açarla SSH kimlik təsdiqi';
	@override String get sshAuthenticationHelp => 'İstəyə bağlıdır; şifrə ilə kimlik təsdiqi də dəstəklənir.';
	@override String get privateKey => 'Özəl açar (PEM və ya OpenSSH formatı)';
	@override String get privateKeyPassphrase => 'Özəl açarın parol ifadəsi';
	@override String get nfsMountPort => 'NFS mount xidmətinin TCP portu';
	@override String get nfsMountPortHelp => 'Standart: 20048';
	@override String get nfsUserId => 'NFS istifadəçi ID-si (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Standart: 1000. NAS-ın NFS paylaşımında icazə verilən ID-ni istifadə edin.';
	@override String get nfsGroupId => 'NFS qrup ID-si (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Standart: 1000. NAS-ın NFS paylaşımında icazə verilən qrup ID-sini istifadə edin.';
	@override String get nfsEncryption => 'Şifrələnmiş NFS tələb et (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'NFS və mount xidməti üçün TLS 1.3 tələb edin. NAS bunu dəstəkləmirsə, bağlantı rədd edilir.';
	@override String get nfsTrustCertificate => 'Xüsusi NFS CA və ya server sertifikatı (PEM, istəyə bağlı)';
	@override String get nfsTrustHelp => 'Bu cihazın etibar etdiyi sertifikatlar üçün boş saxlayın. Lazım olduqda özəl CA sertifikatı və ya öz-özünə imzalanmış server sertifikatı əlavə edin; sertifikatdakı adlar NFS URL-indəki hosta uyğun gəlməlidir.';
	@override String get nfsTrustInvalid => 'PEM formatında CA və ya server sertifikatı istifadə edin. Özəl açar daxil etməyin.';
	@override String get addTrustCertificate => 'Xüsusi etibar sertifikatı əlavə et';
	@override String get replaceTrustCertificate => 'Yadda saxlanmış xüsusi sertifikatı əvəz et';
	@override String get nfsTlsHelp => 'RPC-with-TLS adi NFS və mount xidməti portlarını istifadə edir və NAS-da RFC 9289 dəstəyi tələb edir. TLS 1.3 tələb olunur. Host adı və ya IP ünvanı sertifikata uyğun gəlməlidir. Şifrələnmiş kanalda da AUTH_SYS UID/GID qüvvədə qalır.';
	@override String get clientCertificate => 'Klient sertifikatı (istəyə bağlı)';
	@override String get clientCertificateHelp => 'NAS-a bu klientin kimliyini təsdiqləməyə imkan verir; AUTH_SYS ID-ləri yenə NAS-ın NFS paylaşım qaydalarından asılıdır.';
	@override String get savedIdentity => 'Yadda saxlanmış klient kimlik məlumatları istifadə olunacaq.';
	@override String get replaceIdentity => 'Yadda saxlanmış klient kimlik məlumatlarını əvəz et';
	@override String get chooseIdentity => 'PKCS#12 klient kimlik məlumatlarını seç';
	@override String get identityPassphrase => 'Klient kimlik məlumatlarının parol ifadəsi';
	@override String get identityPassphraseHelp => 'Faylın parol ifadəsi yoxdursa, boş saxlayın.';
	@override String get removeIdentity => 'Yadda saxlanmış klient kimlik məlumatlarını sil';
	@override String get identityStorageHelp => 'Klient kimlik məlumatları mənbənin şifrələnmiş giriş məlumatları yaddaşında saxlanılır. Yadda saxlanmış kimlik məlumatlarını qorumaq üçün bu bölməni dəyişməyin.';
	@override String get nfsLimitations => 'TCP üzərindən yalnız oxuma üçün NFSv3. RPC-with-TLS olmadan NFS trafiki şifrələnmir. NAS seçilmiş AUTH_SYS ID-lərinə və imtiyaz tələb etməyən klient portlarına icazə verməlidir (çox vaxt “insecure” export seçimi adlanır). NFSv4 və UDP dəstəklənmir.';
	@override String get nfsSetupHelp => 'NFS quraşdırma köməyi';
	@override String get nfsSetupHint => 'Bağlantı açılmırsa, bu ayarları yoxlayın.';
	@override String get nfsSetupDetails => 'TCP üzərindən NFSv3 paylaşımı istifadə edin. Şifrələmə tələb olunursa, həm NFS, həm də mount xidməti RPC-with-TLS dəstəkləməlidir. Cihazın etibar etdiyi server sertifikatı üçün xüsusi sertifikat sahəsini boş saxlayın və ya NAS-ın CA sertifikatını yaxud öz-özünə imzalanmış sertifikatını əlavə edin. Sertifikatdakı ad bağlantı ünvanındakı hosta uyğun olmalıdır. NAS qarşılıqlı TLS tələb edirsə, onun PKCS#12 klient kimlik məlumatlarını əlavə edin. Sonda paylaşımın təyin edilmiş AUTH_SYS UID/GID və klient portu qaydalarına icazə verdiyini yoxlayın.';
	@override String get ftpHelp => 'FTP passiv rejimdən istifadə edir. Şifrələnməmiş FTP üçün ftp://, ayrıca əmrlə TLS-ə keçid üçün ftpes://, TLS üçün isə ftps:// istifadə edin (990 portunda TLS dərhal başlayır, digər portlarda ayrıca əmrlə başladılır).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Ayrıca videolar üçün istəyə bağlı altyazı axtarışı.';
	@override String get apiKey => 'API açarı';
	@override String get optionalUsername => 'Hesabın istifadəçi adı (istəyə bağlı)';
	@override String get optionalPassword => 'Hesabın şifrəsi (istəyə bağlı)';
	@override String get subtitlePrivacy => 'opensubtitles.com saytından API açarı alın. Axtarış videonun adını və mövcud IMDb/TMDB ID-lərini göndərir, video faylını isə heç vaxt göndərmir. Açar və istəyə bağlı hesab giriş məlumatları bu mənbə ilə birlikdə şifrələnir.';
	@override String get automaticMetadata => 'Avtomatik onlayn video metadatası';
	@override String get metadataPrivacy => 'Yalnız fayl adındakı adı/ili və epizod nömrələrini və ya NFO ID-sini göndərir; media və giriş məlumatlarını heç vaxt göndərmir. NFO sahələri üstünlüyünü saxlayır.';
	@override String get nfsEncryptionFailure => 'Şifrələnmiş NFS üçün hər iki NAS xidmətində RFC 9289 və TLS 1.3 dəstəyini, sertifikat adını və paylaşımın UID/GID dəyərlərini yoxlayın. PlezyNG bu bağlantını şifrələmə olmadan yenidən sınamayacaq.';
	@override String get sourceConnecting => 'Mənbəyə qoşulur';
	@override String get metadataSearchPrivacy => 'Bu ad axtarışı Trakt-a göndərilir. Daxil etdiyiniz ad göndərilir, video və ya mənbənin giriş məlumatları deyil.';
	@override String get chooseMatch => 'Uyğun nəticəni seç';
	@override String get metadataMatchHelp => 'Seçməzdən əvvəl adı və ili yoxlayın. Trakt axtarılan adı alır; video öz mənbəyində qalır.';
	@override String get metadataNoMatches => 'Onlayn uyğun ad tapılmadı. Başqa ad sınayın.';
	@override String get metadataSearch => 'Onlayn metadata axtar';
	@override String get metadataLoading => 'Onlayn film və serial məlumatları axtarılır…';
	@override String get metadataFromTrakt => 'Trakt-dan onlayn metadata';
	@override String get metadataNoAutomaticMatch => 'Avtomatik ad uyğunluğu tapılmadı. Uyğun nəticəni seçmək üçün adı axtarın.';
	@override String get metadataFailed => 'Onlayn metadata yüklənmədi. Oynatma və yerli məlumatlar hələ də əlçatandır.';
	@override String get videoDetailsLoading => 'Video məlumatları yüklənir';
	@override String get subtitleKeyRequired => 'OpenSubtitles API açarı tələb olunur';
	@override String get subtitleKeyHelp => 'Bu fayl mənbəyini redaktə edin və istəyə bağlı altyazı ayarlarına OpenSubtitles API açarı əlavə edin.';
	@override String get subtitleSearchFailed => 'Altyazı axtarışı uğursuz oldu. API açarını, bağlantını və xidmətə girişi yoxlayın.';
	@override String get subtitleApplyFailed => 'Bu altyazı endirilə və ya tətbiq edilə bilmədi. Bağlantınızı yoxlayın və başqa nəticə sınayın.';
	@override String get subtitleSearch => 'OpenSubtitles-də axtar';
	@override String get subtitleSearchPrivacy => 'Axtarış adı və mövcud IMDb/TMDB ID-lərini istifadə edir. Video faylı öz mənbəyində qalır. Seçməzdən əvvəl dili, məcburi altyazı və ya eşitmə məhdudiyyətli şəxslər üçün altyazı işarələrini və reytinqi yoxlayın.';
	@override String get movieOrShow => 'Film və ya serial';
	@override String get subtitleTitleHint => 'Nəticələri dəqiqləşdirmək üçün ad daxil edin';
	@override String get subtitleLanguage => 'Altyazı dili';
	@override String get subtitleSearching => 'OpenSubtitles-də axtarılır';
	@override String get subtitleNoMatches => 'Uyğun altyazı tapılmadı. Başqa ad və ya dil sınayın.';
	@override String get downloadSubtitle => 'Altyazını endir';
	@override String get subtitle => 'Altyazı';
	@override String get nfsTlsRequired => 'RPC-with-TLS tələb olunur';
	@override String get nfsUnencrypted => 'Şifrələnməmiş NFS';
	@override String get tlsEncrypted => 'TLS ilə şifrələnib';
	@override String get ftpPlain => 'Şifrələnməmiş FTP';
	@override String get sshPinned => 'SSH şifrələnib · host açarı sabitlənib';
	@override String get smbEncrypted => 'SMB3 şifrələməsi aktivdir';
	@override String get smbUnencrypted => 'SMB3 şifrələməsi deaktivdir';
	@override String get httpUnencrypted => 'Nəqliyyat şifrələməsi olmayan HTTP';
	@override String get checkEndpointSecurity => 'Bağlantı ünvanının təhlükəsizliyini yoxla';
	@override String fieldRequired({required Object label}) => 'Tələb olunan sahə: ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => '${label} üçün ${min} ilə ${max} arasında dəyər daxil edin.';
	@override String replaceFile({required Object name}) => '${name} əvəz et';
	@override String selectedIdentity({required Object name}) => 'Seçilmiş klient kimlik məlumatları: ${name}';
	@override String subtitleRating({required Object rating}) => 'Reytinq ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Altyazı endirilir: ${title}';
	@override String get sharedEntryPair => 'Bu elementin parası';
	@override String get sharedEntryPairHelp => 'Hər bir cihazda bu öğə üçün aynı ID-i girin. sabit paylaşılan tanımlayıcı kullanın və birini oluşturun və eşleşən öğeye kopyalanın. Progress pars yalnız versiyonu dosya türləri, büyüklükleri və sipariş eşleşir. Blank bu mapping kaldırır.';
	@override String get sharedEntryId => 'Xatırılmış element ID';
	@override String get generateSharedEntryId => 'Paylaşılmış element ID';
	@override String get sharedLibraryId => 'Kütüphanə ID-i paylaşılmışdır (optional)';
	@override String get sharedLibraryHelp => 'Bu public ID-i aynı kütüphaneyi açan cihazlarda da aynı ID-ə istifadə edin.Bu yayın ID-si, farklı kaynak bağlantıları üzerinden okuma progresunu və notlarını götürmək üçün kömək edir; bu bir şifard deyil.';
	@override String get sharedLibraryInvalid => '8–100 yazı, sayı, nokta, subscores və hyphens istifadə edin.';
	@override String get generateSharedLibraryId => 'Bir kütüphane ID-i oluşturmaq';
	@override String get nfsReadAhead => 'NFS-nin Qəzaq İzinləri';
	@override String get nfsReadAheadHelp => 'Daha çox paralel okurlar, bir NAS və ya ağda geçiş gücünü artırır. sunucu sözleşmelerini sınırlandırdığında 1 istifadə edin.';
	@override String get nfsReadTest => 'NFS-in performansını ölçmək';
	@override String get nfsReadTestHelp => 'Bu NAS bağlantısını ölçmək üçün ən böyük faildən 64 MiB-a qədər okunur.Bu ağ bandwidthını kullanır.';
	@override String get nfsQualificationResult => 'NFS-in ölçüləri';
	@override String get nfsReadBytes => 'Tarihlər Read';
	@override String get nfsReadSpeed => 'Hızın ölçülməsi';
	@override String get nfsReadRequests => 'İhtiyaçları okuyun';
	@override String get sharedEntryConflict => 'Bu paylaşılan element kimliği bu kütüphanada başqa bir elementlə də parədir. farklı bir ID seçin.';
}

// Path: comics
class _Translations$comics$az extends Translations$comics$en {
	_Translations$comics$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Hündürlüyə uyğunlaşdır';
	@override String get readingMode => 'Oxu rejimi';
	@override String get paged => 'Səhifələr';
	@override String get webtoon => 'Davamlı sürüşdürmə';
	@override String get coverAlone => 'Üz qabığını ayrıca göstər';
	@override String get splitWide => 'Geniş səhifələri böl';
	@override String get splitWideHelp => 'Hər yarını oxu ardıcıllığı ilə ayrıca göstər. Bu seçim aktiv olduqda iki səhifənin birlikdə göstərilməsi dayandırılır.';
	@override String get thumbnails => 'Səhifə miniatürləri';
	@override String get controlsHelp => 'Səhifələri çevirmək üçün sürüşdürün. Uyğunlaşdırmanı dəyişmək üçün iki dəfə toxunun. Davamlı sürüşdürmədə şaquli sürüşdürün və ya Page Up və Page Down istifadə edin.';
	@override String get savedForComic => 'Görüntü ayarları bu profildə bu komiks üçün yadda saxlanılır.';
	@override String get readLists => 'Oxu siyahıları';
	@override String get collections => 'Kolleksiyalar';
}

// Path: games
class _Translations$games$az extends Translations$games$en {
	_Translations$games$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

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

// Path: deepLinks
class _Translations$deepLinks$az extends Translations$deepLinks$en {
	_Translations$deepLinks$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Bu Plezy bağlantısı geçerli deyil.';
	@override String profileNotFound({required Object profile}) => '“${profile}” və “ZxqPROFile0” arasında heç bir profil yoxdur.';
	@override String get serverUnavailable => 'Bu linki üçün serverə ulaşamazdım.';
	@override String get notFound => 'Bu kitabın kitabında bir başlık bulamazdım.';
	@override String get unsupportedItem => 'Bu linki oynamaq mümkün deyil.';
	@override String get noLiveTv => 'Bu linki üçün Live TV server yoxdur.';
	@override String channelNotFound({required Object channel}) => '“${channel}” kanalını bulamazdım.';
	@override String get showLink => 'İndir Link';
	@override String get showProfileLink => 'Profil link göstərmək';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'Bu linki açın, bir sonraki epizod oynanır. shuffle-da şov oynamak için &mode=shuffle ekləyin.';
	@override String get movieHint => 'Bu linki açmaq filmi oynayır.';
	@override String get episodeHint => 'Bu linki açmaq bu epizodu oynayır.';
	@override String get profileHint => 'Bu profillə bu link-i açılır.';
	@override String openAsProfile({required Object name}) => '${name} kimi açılır';
	@override String get copy => 'Kopya';
	@override String get copied => 'Link kopyalar';
}

// Path: appIcon.names
class _Translations$appIcon$names$az extends Translations$appIcon$names$en {
	_Translations$appIcon$names$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Gecəyarısı';
	@override String get ember => 'Köz';
	@override String get paper => 'Kağız';
	@override String get oled => 'OLED';
	@override String get line => 'Xətt';
	@override String get ocean => 'Okean';
	@override String get ultraviolet => 'Ultrabənövşəyi';
	@override String get matcha => 'Matça';
	@override String get sunset => 'Gün batımı';
	@override String get gold => 'Qızıl';
	@override String get titanium => 'Titan';
	@override String get glass => 'Şüşə';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Piksel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Stiker';
	@override String get ticket => 'Bilet';
	@override String get pop => 'Pop';
	@override String get strata => 'Laylar';
	@override String get facet => 'Faset';
	@override String get tilde => 'Tilda';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$az extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

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
class _Translations$common$mediaKind$az extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Serial';
	@override String get season => 'Sezon';
	@override String get episode => 'Epizod';
	@override String get artist => 'İfaçı';
	@override String get album => 'Albom';
	@override String get track => 'Mahnı';
	@override String get collection => 'Kolleksiya';
	@override String get playlist => 'Pleylist';
	@override String get clip => 'Klip';
	@override String get photo => 'Şəkil';
	@override String get folder => 'Qovluq';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$az extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Əvvəlki xəbərlər və məlumatlar bağlanmış qalıqlardan alınır.';
	@override String get libraries => 'Bağlantılı medya kütüphanalarını açın.';
	@override String get liveTv => 'Live TV-i bir serverin sağladığı zaman açılır; aksi takdirde start-up evə qayıtır.';
	@override String get search => 'Açıklama medya aralığı.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$az extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Arxa fon';
	@override String get surface => 'Səth';
	@override String get outline => 'Kontur';
	@override String get text => 'Mətn';
	@override String get textMuted => 'Köməkçi mətn';
	@override String get accent => 'Vurğu';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$az extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Arxa fonda mətn';
	@override String get textOnSurface => 'Səthdə mətn';
	@override String get textMutedOnBg => 'Arxa fonda köməkçi mətn';
	@override String get textMutedOnSurface => 'Səthdə köməkçi mətn';
	@override String get accentOnBg => 'Arxa fonda vurğu';
	@override String get accentOnSurface => 'Səthdə vurğu';
	@override String get labelOnAccent => 'Vurğu üzərində düymə mətni';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$az extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Oynat/Fasilə';
	@override String get volumeUp => 'Səsi artır';
	@override String get volumeDown => 'Səsi azalt';
	@override String seekForward({required Object seconds}) => 'İrəli sar (${seconds}san)';
	@override String seekBackward({required Object seconds}) => 'Geri sar (${seconds}san)';
	@override String get fullscreenToggle => 'Tam ekranı dəyişdir';
	@override String get muteToggle => 'Səsi aç/bağla';
	@override String get subtitleToggle => 'Altyazını aç/bağla';
	@override String get audioTrackNext => 'Növbəti səs zolağı';
	@override String get subtitleTrackNext => 'Növbəti altyazı zolağı';
	@override String get chapterNext => 'Növbəti hissə';
	@override String get chapterPrevious => 'Əvvəlki hissə';
	@override String get episodeNext => 'Növbəti seriya';
	@override String get episodePrevious => 'Əvvəlki seriya';
	@override String get speedIncrease => 'Sürəti artır';
	@override String get speedDecrease => 'Sürəti azalt';
	@override String get speedReset => 'Sürəti sıfırla';
	@override String get zoomIn => 'Yaxınlaşdır';
	@override String get zoomOut => 'Uzaqlaşdır';
	@override String get zoomReset => 'Miqyası sıfırla';
	@override String get subSeekNext => 'Növbəti altyazıya sar';
	@override String get subSeekPrev => 'Əvvəlki altyazıya sar';
	@override String get subtitleDelayIncrease => 'Altyazını gecikdir';
	@override String get subtitleDelayDecrease => 'Altyazını irəli çək';
	@override String get shaderToggle => 'Şeyderləri aç/bağla';
	@override String get skipMarker => 'Girişi/Titrləri ötür';
	@override String get screenshot => 'Ekran şəkli çək';
	@override String get framePrevious => 'Öncəki Frame';
	@override String get frameNext => 'Sonraki Frame';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$az extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 və ya daha yenisini tələb edir';
	@override String get iosVersion => 'iOS 15.0 və ya daha yenisini tələb edir';
	@override String get permissionDisabled => 'PiP rejimi söndürülüb. Sistem tənzimləmələrindən aktivləşdirin.';
	@override String get notSupported => 'Cihaz PiP rejimini dəstəkləmir';
	@override String get voSwitchFailed => 'PiP üçün video çıxışı dəyişdirilə bilmədi';
	@override String get failed => 'PiP rejimi başladılarkən xəta';
	@override String get prepareFailed => 'PiP rejimi hazırlana bilmədi';
	@override String unknown({required Object error}) => 'Xəta baş verdi: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$az extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get no => 'Fırtınalar, renkler, boyutlar və yerleşim dosyada yazılmış tutun.';
	@override String get yes => 'Subtitle stil ayarlarını ASS subtitlləri düzeltmək üçün izin verin.';
	@override String get scale => 'Oyuncu stilini və video boyutlarını ayarlaymaq üçün yerleşik ölçümləri ölçün.';
	@override String get force => 'Xatırılan ASS stillarını oyuncu subtitrinin stili ilə dəyişir.';
	@override String get strip => 'Düşünürəm ki, bu formatı düzgün bir biçimdir.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$az extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Əslində, ən yaxşı nəticə üçün tam ekran yüzey çözünürlüğüne qaytarılır.';
	@override String get video => 'Video çözünürlüğünü referans olarak kullanır, bu da yüksek çözünənlik ekranlarında çalışmayı azaltır.';
	@override String get threeQuarter => 'Yüzünün 75-dəki ekranın yüzey çözünürlüğüne düşüş, müsahib performans tasarrufu üçün.';
	@override String get half => '50 % ekranın yüzey çözünürlüğünü, işini azaltmaq üçün, yumuşak kenarlarla bağlayır.';
	@override String get third => 'Üçte biri ekranın yüzey çözünürlüğünün üçte birində çalışmayı azaltmaq üçün, yumuşak kenarlarla.';
	@override String get quarter => 'Üçüncü çeyrek ekran yüzey çözünürlüğünün üçün, işini azaltmaq üçün, ən yumuşak sonuca var.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$az extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Səs və altyazılar';
	@override String get libraryDisplay => 'Kitabxana';
	@override String get personalMedia => 'Şəxsi media';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$az extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get none => 'Əl ilə seçilmiş';
	@override String get noneDescription => 'Altyazıları heç vaxt özbaşına açma.';
	@override String get defaultMode => 'Trek bayraqlarına əməl et';
	@override String get defaultModeDescription => 'Hər altyazı trekində saxlanılan defolt və məcburi bayraqları istifadə et.';
	@override String get always => 'Həmişə aktivdir';
	@override String get alwaysDescription => 'Üstünlük verilən dildə altyazı treki mövcuddursa, onu aç.';
	@override String get onlyForced => 'Yalnız məcburi altyazılar';
	@override String get onlyForcedDescription => 'Yalnız məcburi işarələnmiş trekləri yüklə.';
	@override String get smart => 'Xarici səs olduqda göstərilən';
	@override String get smartDescription => 'Altyazıları yalnız səs başqa dildə olduqda aç.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$az extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'SDH olmayan altyazılara üstünlük ver';
	@override String get preferSdh => 'SDH altyazılarına üstünlük ver';
	@override String get onlySdh => 'Yalnız SDH altyazıları';
	@override String get onlyNonSdh => 'Yalnız SDH olmayan altyazılar';
	@override String get preferNonSdhDescription => 'Standart və SDH versiyonları var olduğunda standart alt başlıklar tercih edilir.';
	@override String get preferSdhDescription => 'SDH subtitlləri mevcut olduğunda tercih edər, ancak standart subtitrlər düşüş kimi izin verir.';
	@override String get onlySdhDescription => 'SDH subtitlləri yalnız istifadə edin; standart subtitrələrə qayıtmayın.';
	@override String get onlyNonSdhDescription => 'Standart subtitlləri yalnız istifadə edin; SDH subtitraları dışlayın.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$az extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Məcburi olmayan altyazılara üstünlük ver';
	@override String get preferForced => 'Məcburi altyazılara üstünlük ver';
	@override String get onlyForced => 'Yalnız məcburi altyazılar';
	@override String get onlyNonForced => 'Yalnız məcburi olmayan altyazılar';
	@override String get preferNonForcedDescription => 'VVD-nin idarə etdiyi superkarlar – bu, artıq çox az fərqlənib.';
	@override String get preferForcedDescription => 'Hazır olduğunda zorlu yolları tercih edər, ancak düşüş kimi düzgün alt başlıklara izin verir.';
	@override String get onlyForcedDescription => 'Yalnızca zorunlu olarak işaretlenmiş yolları kullanın.';
	@override String get onlyNonForcedDescription => 'Xatırılan yollar işaretlenir.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$az extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get none => 'Heç vaxt';
	@override String get moviesAndShows => 'Kinolar və TV şoular';
	@override String get movies => 'Yalnız kinolar';
	@override String get shows => 'Yalnız TV şoular';
	@override String get noneDescription => 'Görüntülən kontrol markaları göstərməyin.';
	@override String get moviesAndShowsDescription => 'Televiziyası və filmlər üçün gözləyir.';
	@override String get moviesDescription => 'Görüntülər yalnız filmlər üçün gözləyir.';
	@override String get showsDescription => 'Televiziyalar üçün yalnız gözləyirlər göstərilir.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$az extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'İstifadəçilər və tənqidçilər';
	@override String get usersOnly => 'Yalnız istifadəçilər';
	@override String get criticsOnly => 'Yalnız tənqidçilər';
	@override String get nobody => 'Gizlədilib';
	@override String get usersAndCriticsDescription => 'Kullanıcıların və kritik puanları da göstərilir.';
	@override String get usersOnlyDescription => 'Görünür ki, kullanıcılar tərəfindən göndərilmiş değerlendirmələr və görüşlər.';
	@override String get criticsOnlyDescription => 'Critical ratings və reviewlər göstərilir.';
	@override String get nobodyDescription => 'Qalıqlar və değerlendirmələr.';
}

// Path: discover.findNext
class _Translations$discover$findNext$az extends Translations$discover$findNext$en {
	_Translations$discover$findNext$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Növbəti seçiminizi tapın';
	@override String get open => 'Növbəti seçiminizi tapın';
	@override String get anyTime => 'İstənilən müddət';
	@override String get timeAvailable => 'Nə qədər vaxtınız var?';
	@override String get filters => 'Vaxtınıza uyğun seçim edin';
	@override String get watch => 'İzləyin';
	@override String get listen => 'Dinləyin';
	@override String get read => 'Oxuyun';
	@override String finishable({required Object duration}) => '${duration} ərzində bitirə bilərsiniz';
	@override String aboutDuration({required Object duration}) => 'Təxminən ${duration}';
	@override String nextUnit({required Object duration}) => 'Növbəti fəsil · ${duration}';
	@override String totalDuration({required Object duration}) => 'Ümumi müddət: ${duration}';
	@override String get timingVaries => 'Müddət dəyişə bilər';
	@override String get notNow => 'İndi yox';
	@override String get swipeHint => 'Üz qabığını ox istiqamətində sürüşdürün və ya aşağıdakı düymələrdən istifadə edin.';
	@override String get saved => 'Yadda saxlanmış seçimlər';
	@override String savedCount({required Object count}) => 'Yadda saxlanmış seçimlər · ${count}';
	@override String get undo => 'Geri al';
	@override String get details => 'Təfərrüatlar';
	@override String get noPicks => 'Hələ seçim yoxdur';
	@override String get noPicksHint => 'Başlamaq üçün kitabxana qoşun və ya media mənbəyi əlavə edin.';
	@override String get noMatches => 'Hazırkı vaxtınıza uyğun seçim yoxdur';
	@override String get noMatchesHint => 'Başqa media növünü sınayın və ya daha çox vaxt ayırın.';
	@override String get allDone => 'Bütün seçimlərə baxdınız';
	@override String get allDoneHint => 'Bu seçimləri yenidən görmək üçün yeni bir seçim dəsti yaradın.';
	@override String get refresh => 'Başqa seçimlər tapın';
	@override String sourceReason({required Object source}) => 'Mənbə: ${source}';
	@override String libraryReason({required Object library}) => 'Kitabxana: ${library}';
	@override String get ownedReason => 'Kitabxananızdan';
	@override String get liveNow => 'Hazırda yayımlanır';
	@override String get watchLive => 'Canlı izləyin';
	@override String get filterAnything => 'İstənilən növ';
	@override String get filterWatch => 'İzləyin';
	@override String get filterListen => 'Dinləyin';
	@override String get filterRead => 'Oxuyun';
	@override String get twentyMinutes => '20 dəq';
	@override String get fortyFiveMinutes => '45 dəq';
	@override String get ninetyMinutes => '90 dəq';
	@override String get apply => 'Tətbiq et';
	@override String get openFailed => 'Bu seçim artıq mövcud deyil. Yenidən yoxlamaq üçün yeniləyin.';
	@override String get changeFailed => 'Bu dəyişikliyi yadda saxlamaq mümkün olmadı. Yenidən cəhd edin.';
	@override String get savedLimit => 'Yadda saxlanmış seçimlər siyahısı doludur. Başqa seçim saxlamaq üçün birini silin.';
	@override String get chooseHint => 'Bir başlığı açın, sonraya saxlayın və ya keçin.';
	@override String get howItWorks => 'İstifadə qaydası';
	@override String get notNowHelp => 'Bu başlığı hələlik keçin. O, kitabxananızda qalacaq.';
	@override String get saveHelp => 'Bu cihazda bu profilin saxlanmış seçimlərinə əlavə edin. Saxlamaq məzmunu endirmir.';
	@override String get openHelp => 'Təfərrüatlar üçün üz qabığını seçin. Başlığı oynatmaq, oxumaq və ya açmaq üçün əsas düymədən istifadə edin.';
	@override String get controlsHelp => 'Klaviatura və ya pult: düyməni seçin, sonra Enter və ya seçim düyməsini basın. Geri al son seçiminizi bərpa edir.';
	@override String get artworkLoading => 'Şəkil yüklənir…';
	@override String get artworkUnavailable => 'Şəkil mövcud deyil';
	@override String get savedFeedback => 'Saxlanmış seçimlərə əlavə edildi';
	@override String get skippedFeedback => 'Hələlik keçildi';
	@override String get releaseToConfirm => 'Təsdiqləmək üçün buraxın';
	@override String get remoteHint => 'Üz qabığı fokusda: ← / → seçin · Seçim düyməsi: təfərrüatlar · ↑ / ↓ fokusu dəyişin';
}

// Path: discover.person
class _Translations$discover$person$az extends Translations$discover$person$en {
	_Translations$discover$person$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get born => 'Doğum tarixi';
	@override String get died => 'Vəfat tarixi';
	@override String get birthplace => 'Doğum yeri';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} yaş)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (${age} yaşında)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$az extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Tövsiyə olunanlar';
	@override String get browse => 'Baxış';
	@override String get collections => 'Kolleksiyalar';
	@override String get playlists => 'Oynatma siyahıları';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$az extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Qruplaşdırma';
	@override String get all => 'Hamısı';
	@override String get movies => 'Kinolar';
	@override String get shows => 'TV Şoular';
	@override String get seasons => 'Mövsümlər';
	@override String get episodes => 'Seriyalar';
	@override String get artists => 'Müğənnilər/Müəlliflər';
	@override String get albums => 'Albomlar';
	@override String get tracks => 'Mahnılar';
	@override String get folders => 'Qovluqlar';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$az extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Janr';
	@override String get year => 'İl';
	@override String get contentRating => 'Məzmun reytinqi';
	@override String get tag => 'Teq';
	@override String get unwatched => 'Baxılmayıb';
	@override String get unplayed => 'Oynadılmayıb';
	@override String get favorites => 'Sevimlilər';
	@override String get filePath => 'Fayl yolu';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$az extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ad';
	@override String get dateAdded => 'Əlavə olunma tarixi';
	@override String get releaseDate => 'Buraxılış tarixi';
	@override String get rating => 'Reytinq';
	@override String get communityRating => 'İcma reytinqi';
	@override String get criticRating => 'Tənqidçi reytinqi';
	@override String get userRating => 'İstifadəçi reytinqi';
	@override String get datePlayed => 'Oynadılma tarixi';
	@override String get playCount => 'Oynadılma sayı';
	@override String get productionYear => 'İstehsal ili';
	@override String get runtime => 'Müddət';
	@override String get officialRating => 'Rəsmi reytinq';
	@override String get premiereDate => 'Premyera tarixi';
	@override String get startDate => 'Başlanğıc tarixi';
	@override String get airTime => 'Yayımlanma vaxtı';
	@override String get studio => 'Studiya';
	@override String get random => 'Təsadüfi';
	@override String get dateShared => 'Paylaşılma tarixi';
	@override String get latestEpisodeAirDate => 'Son seriya yayın tarixi';
	@override String get lastEpisodeDateAdded => 'Əlavə olunan son seriya tarixi';
	@override String get dateDownloaded => 'Yüklənmə tarixi';
	@override String get size => 'Həcm';
	@override String get library => 'Kitabxana';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$az extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get include => 'Daxil et';
	@override String get exclude => 'Xaric et';
	@override String get any => 'İstənilən';
	@override String get yes => 'Bəli';
	@override String get no => 'Xeyr';
	@override String not({required Object value}) => '${value} deyil';
	@override String valueCount({required Object count}) => '${count} seçilib';
	@override String valueCountExcluded({required Object count}) => '${count} xaric edilib';
	@override String get searchValues => 'Dəyərlərdə axtar';
	@override String get noValues => 'Dəyər yoxdur';
	@override String get matchContains => 'Ehtiva edir';
	@override String get matchNotContains => 'Ehtiva etmir';
	@override String get matchIs => 'Bərabərdir';
	@override String get matchIsNot => 'Bərabər deyil';
	@override String get matchBeginsWith => 'İlə başlayır';
	@override String get matchEndsWith => 'İlə bitir';
	@override String get textHint => 'Uyğunluq üçün yazın';
	@override String get from => 'Başlanğıc';
	@override String get to => 'Son';
	@override String range({required Object from, required Object to}) => '${from} – ${to}';
	@override String atLeast({required Object value}) => '${value} və yuxarı';
	@override String atMost({required Object value}) => '${value} və aşağı';
	@override String dateLastDays({required Object count}) => 'Son ${count} gün';
	@override String get dateLastYear => 'Son bir il';
	@override String dateOlderThanDays({required Object count}) => '${count} gündən köhnə';
	@override String get dateOlderThanYear => 'Bir ildən köhnə';
}

// Path: libraries.selection
class _Translations$libraries$selection$az extends Translations$libraries$selection$en {
	_Translations$libraries$selection$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Seçimlər';
	@override String selectedCount({required Object count}) => '${count} seçilib';
	@override String get actions => 'Seçimlər';
	@override String get confirmDescendants => 'Bu, seçilmiş şovlarda və sezonlarda bütün epizodları dəyişir.';
	@override String get confirmUnwatched => 'Bu, seçilmiş elementlərin oxutma gedişatını da sıfırlayır.';
	@override String confirmCount({required Object count}) => 'Seçilmiş elementlər: ${count}.';
	@override String completed({required Object count}) => 'Güncellenmiş elementlər: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Xatırılmış ${succeeded}; başarısız ${failed}. başarısız elementlər seçilmişdir.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$az extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Gəlimlər: Təbrişlər';
	@override String get manageDescription => 'Hesabınızdan MDBList listləri seçin və düzeltin';
	@override String get description => 'Xəbəri və TV listləri hesabınızdan seçin MDBList-dən. listaları MDBList-dən yaratın və ya kopyalayın.';
	@override String get selected => 'Seçilmiş çadırlar';
	@override String get available => 'Hesab listaları';
	@override String get noLists => 'İctimai film və ya TV siyahısı tapılmadı. MDBList-də siyahı yaradın və ya köçürün, sonra yeniləyin.';
	@override String get displayName => 'Xatırın adı';
	@override String get nameHint => 'Bu barədə “Müslər” adlı kitabın adı yazılır.';
	@override String get add => 'Şelətlər';
	@override String get save => 'Şahətlər';
	@override String moveUp({required Object title}) => 'Qəzaqə ${title}';
	@override String moveDown({required Object title}) => 'Qəzaqə ${title}';
	@override String get unavailable => 'Bu listə baxılmır. ayarlarda şelalini geri qaytarır və ya kaldırır.';
	@override String get rateLimited => 'MDBList sorğu limitinə çatıldı. Daha sonra yenidən cəhd edin.';
	@override String get loadFailed => 'Rəfləri yükləmək mümkün olmadı. Bağlantınızı yoxlayın və yenidən cəhd edin.';
	@override String get saveFailed => 'Rəfləri yadda saxlamaq mümkün olmadı. Yenidən cəhd edin.';
	@override String get accountChanged => 'Hesab və profil dəyişib.Bu ayarları yeniden açın.';
	@override String get settingsUnreadable => 'Bu ayarları dəyişdirmək üçün listlərinizə qayıdan seçin.';
}

// Path: explore.rows
class _Translations$explore$rows$az extends Translations$explore$rows$en {
	_Translations$explore$rows$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'İzləmə siyahısı';
	@override String get recommendedMovies => 'Tövsiyə olunan kinolar';
	@override String get recommendedShows => 'Tövsiyə olunan seriallar';
	@override String get trendingMovies => 'Trend kinolar';
	@override String get trendingShows => 'Trend seriallar';
	@override String get popularMovies => 'Məşhur kinolar';
	@override String get popularShows => 'Məşhur seriallar';
	@override String get trendingAnime => 'Trend animelər';
	@override String get suggestedAnime => 'Tövsiyə olunan animelər';
	@override String get airingAnime => 'Ən yaxşı yayımlanan animelər';
	@override String get popularAnime => 'Ən məşhur animelər';
	@override String get trending => 'Trendlər';
	@override String get upcomingMovies => 'Gələcək kinolar';
	@override String get upcomingShows => 'Gələcək seriallar';
}

// Path: explore.status
class _Translations$explore$status$az extends Translations$explore$status$en {
	_Translations$explore$status$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Yayımlanır';
	@override String get ended => 'Bitdi';
	@override String get canceled => 'Ləğv edildi';
	@override String get upcoming => 'Gələcək';
}

// Path: explore.badge
class _Translations$explore$badge$az extends Translations$explore$badge$en {
	_Translations$explore$badge$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} populyar';
	@override String rankAiring({required Object n}) => '#${n} yayımlanır';
	@override String rankRated({required Object n}) => '#${n} qiymətləndirilib';
	@override String rankTrending({required Object n}) => '#${n} trenddə';
	@override String rankSeasonal({required Object season, required Object n}) => '${season} üçün #${n}';
	@override String watchingNow({required Object n}) => '${n} izləyir';
	@override String get available => 'Əlçatandır';
	@override String get partiallyAvailable => 'Hissəvi əlçatandır';
	@override String get availableIn4k => '4K əlçatandır';
	@override String get requested => 'Sorğu göndərildi';
	@override String get pendingApproval => 'Təsdiq gözlənilir';
	@override String get processing => 'Emal edilir';
	@override String get declined => 'Rədd edildi';
	@override String get requestFailed => 'Sorğu uğursuz oldu';
	@override String get requested4k => '4K sorğu göndərildi';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} mövsüm';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} ${duration} sonra';
	@override String nextAiringIn({required Object duration}) => 'Növbəti ${duration} sonra';
	@override String episodesShort({required Object n}) => '${n} ep';
	@override String minutesPerEpisode({required Object n}) => '${n} dəq/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$az extends Translations$explore$stats$en {
	_Translations$explore$stats$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} siyahıya alınıb';
	@override String viewersDay({required Object n}) => 'Bu gün ${n} izlədi';
	@override String viewersWeek({required Object n}) => 'Bu həftə ${n} izlədi';
	@override String viewersMonth({required Object n}) => 'Bu ay ${n} izlədi';
	@override String viewersYear({required Object n}) => 'Bu il ${n} izlədi';
	@override String viewersAllTime({required Object n}) => '${n} izləyici';
	@override String planning({required Object n}) => '${n} izləməyi planlaşdırır';
	@override String favorited({required Object n}) => '${n} favorit';
	@override String dropRate({required Object percent}) => '${percent} izləməyi dayandırdı';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} şərh',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} şərh',
	);
	@override String votes({required Object n}) => '${n} səs';
	@override String watching({required Object n}) => '${n} izləyir';
	@override String completed({required Object n}) => '${n} tamamladı';
	@override String onHold({required Object n}) => '${n} fasilədə';
	@override String dropped({required Object n}) => '${n} izləməyi dayandırdı';
}

// Path: explore.season
class _Translations$explore$season$az extends Translations$explore$season$en {
	_Translations$explore$season$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Qış';
	@override String get spring => 'Yaz';
	@override String get summer => 'Yay';
	@override String get fall => 'Payız';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$az extends Translations$explore$format$en {
	_Translations$explore$format$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'Qısa TV';
	@override String get movie => 'Kino';
	@override String get special => 'Xüsusi buraxılış';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Musiqi';
	@override String get other => 'Digər';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$az extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get original => 'Orijinal';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Roman';
	@override String get visualNovel => 'Vizual roman';
	@override String get game => 'Oyun';
	@override String get webComic => 'Veb komiks';
	@override String get musicRelease => 'Musiqi';
	@override String get otherMedia => 'Digər';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$az extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Aktyor';
	@override String get director => 'Rejissor';
	@override String get writer => 'Ssenarist';
	@override String get producer => 'Prodüser';
	@override String get creator => 'Yaradıcı';
	@override String get composer => 'Bəstəkar';
}

// Path: explore.relation
class _Translations$explore$relation$az extends Translations$explore$relation$en {
	_Translations$explore$relation$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prikvel';
	@override String get sequel => 'Sikvel';
	@override String get sideStory => 'Yan hekayə';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Alternativ versiya';
	@override String get summary => 'Xülasə';
	@override String get parentStory => 'Əsas hekayə';
	@override String get adaptation => 'Adaptasiya';
	@override String get other => 'Əlaqəli';
}

// Path: explore.detail
class _Translations$explore$detail$az extends Translations$explore$detail$en {
	_Translations$explore$detail$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Orijinal başlıq';
	@override String get alsoKnownAs => 'Digər adları';
	@override String get studios => 'Studiyalar';
	@override String get country => 'Ölkə';
	@override String get language => 'Dil';
	@override String get released => 'Buraxılıb';
	@override String get physicalRelease => 'Diskdə';
	@override String get ended => 'Bitib';
	@override String addedOn({required Object date}) => '${date} əlavə edildi';
	@override String get yourRating => 'Sizin qiymətləndirməniz';
	@override String get budget => 'Büdcə';
	@override String get revenue => 'Kassa gəliri';
	@override String get contentAdvisory => 'Yaş tövsiyəsi';
	@override String get tags => 'Teqlər';
	@override String get revealSpoilerTags => 'Spoyler teqlərini göstər';
	@override String get links => 'Keçidlər';
	@override String get watchOn => 'İzlə';
	@override String get watchTrailer => 'Treyleri izlə';
	@override String openOn({required Object site}) => '${site} saytında aç';
	@override String get crew => 'Heyət';
	@override String get ratings => 'Reytinq';
	@override String get schedule => 'Cədvəl';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} istifadəçi tövsiyə edir',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} istifadəçi tövsiyə edir',
	);
	@override String recommendedBy({required Object who}) => '${who} tövsiyə edir';
	@override String favoritedBy({required Object who}) => '${who} favorit edib';
	@override String unairedEpisodes({required Object n}) => '${n} hələ yayımlanmayıb';
	@override String recommendedByPercent({required Object percent}) => 'İzləyicilərin ${percent}-i tövsiyə edir';
	@override String get relatedTitles => 'Əlaqəli başlıqlar';
	@override String get background => 'Arxa fon';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$az extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Erkən başla (saniyə)';
	@override String get endLate => 'Gec bitir (saniyə)';
	@override String get newOnly => 'Yalnız yeni epizodlar';
	@override String get anyChannel => 'İstənilən kanalda yaz';
	@override String get anyTime => 'İstənilən vaxt yaz';
	@override String get skipInLibrary => 'Kitabxanada artıq olan epizodları ötür';
	@override String get keepUpTo => 'Saxlanılacaq epizodlar';
	@override String get keepUpToHint => '0 bütün epizodları saxlayır';
}

// Path: music.discography
class _Translations$music$discography$az extends Translations$music$discography$en {
	_Translations$music$discography$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Single-lar və EP-lər';
	@override String get live => 'Canlı';
	@override String get compilations => 'Kompilyasiyalar';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$az extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} oynat düyməsinə basdı';
	@override String get playbackStarted => 'Oynatma başladı';
	@override String paused({required Object name}) => '${name} fasilə etdi';
	@override String get playbackPaused => 'Oynatma fasilə edildi';
	@override String jumpedTo({required Object name, required Object position}) => '${name} ${position} anına keçdi';
	@override String roomJumpedTo({required Object position}) => '${position} anına keçildi';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} sürəti ${speed} olaraq təyin etdi';
	@override String speedChanged({required Object speed}) => 'Sürət ${speed} olaraq təyin edildi';
	@override String startedMedia({required Object name, required Object title}) => '${name} oynatmağa başladı: ${title}';
	@override String mediaStarted({required Object title}) => 'İndi oynadılır: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} videonu dayandırdı';
	@override String get mediaStopped => 'Video dayandı';
	@override String waitingFor({required Object name}) => '${name} gözlənilir...';
	@override String get waitingForSomeone => 'Kiminsə yetişməsi gözlənilir...';
	@override String get finished => 'Bitdi';
	@override String hostChangedTo({required Object name}) => '${name} indi təşkilatçıdır';
	@override String get youAreNowHost => 'İndi təşkilatçı sizsiniz';
	@override String joined({required Object name}) => '${name} qoşuldu';
	@override String left({required Object name}) => '${name} ayrıldı';
	@override String get controlRefused => 'Oynatmanı yalnız təşkilatçı idarə edə bilər';
	@override String get searchFailed => 'Bəzi serverlərdə otağın videosunu axtarmaq mümkün olmadı';
	@override String get playBlocked => 'Başlamaq üçün oynat düyməsinə basın';
	@override String get shareFailed => 'Bu videonu otaqla paylaşmaq mümkün olmadı';
	@override String get downloadNotShared => 'Serverləri oflayn olduğu müddətdə yükləmələr otaqla paylaşılmır';
	@override String get openFailed => 'Otağın videosunu açmaq mümkün olmadı';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$az extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Təşkilatçı otağı bağladı';
	@override String get kicked => 'Siz otaqdan çıxarıldınız';
	@override String get expired => 'Otağın vaxtı bitdi';
	@override String get replaced => 'Bu otağa başqa cihazda qoşuldunuz';
	@override String get lost => 'Otaqla əlaqə kəsildi';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$az extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Bu, otaq kodu deyil. Kodlar 0, 1, I, L və ya O olmadan 6 hərf və rəqəmdən ibarətdir.';
	@override String get roomNotFound => 'Bu kodla otaq yoxdur. O, bağlanmış ola bilər.';
	@override String get roomFull => 'Bu otaq doludur.';
	@override String get roomLocked => 'Təşkilatçı bu otağı kilidləyib.';
	@override String get relayFull => 'Birlikdə İzlə hazırda məşğuldur. Sonra yenidən cəhd edin.';
	@override String get unreachable => 'Birlikdə İzlə relesinə qoşulmaq mümkün olmadı. Bağlantınızı yoxlayın.';
	@override String get rateLimited => 'Həddindən çox cəhd. Bir az gözləyib yenidən cəhd edin.';
	@override String get clientBlocked => 'PlezyNG-nin bu versiyası releni istifadə edə bilmir. Tətbiqi yeniləyin.';
	@override String get forbidden => 'Bunu yalnız təşkilatçı edə bilər.';
	@override String get notInRoom => 'Siz otaqda deyilsiniz.';
	@override String get alreadyInRoom => 'Siz artıq otaqdasınız.';
	@override String get resumeFailed => 'Otağa yenidən qoşulmaq mümkün olmadı.';
	@override String get unsupported => 'Rele bunu dəstəkləmir.';
	@override String get generic => 'Nəsə səhv getdi. Yenidən cəhd edin.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$az extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Tətbiqdən çıxdıqda yükləmələr dayanacaq';
	@override String get bannerDegraded => 'Arxa fonda yükləmələr məhdudlaşdırıla bilər';
	@override String get bannerAction => 'Ətraflı';
	@override String get sheetTitle => 'Arxa fonda yükləmələr bloklanıb';
	@override String get sheetTitleDegraded => 'Arxa fonda yükləmələr məhdudlaşdırıla bilər';
	@override String get sheetIntro => 'Android PlezyNG-nin arxa fonda etibarlı şəkildə yükləməsinə mane olur.';
	@override String get sheetIntroDegraded => 'Cihazınız PlezyNG-nin arxa fonda nə vaxt yükləyə biləcəyini məhdudlaşdırır.';
	@override String get reasonBackgroundRestricted => 'PlezyNG-nin arxa fon istifadəsi məhdudlaşdırılıb. Batareya və ya arxa fon istifadəsini "Məhdudiyyətsiz" edin.';
	@override String get reasonStandbyRestricted => 'Android PlezyNG-ni məhdud gözləmə rejiminə salıb. Batareya istifadəsini "Məhdudiyyətsiz" edin.';
	@override String get reasonDownloadChannelBlocked => 'Yükləmə bildirişləri söndürülüb, ona görə gedişat və idarəetmələr əlçatan olmaya bilər.';
	@override String get reasonNotificationsDisabled => 'Bildirişlər söndürülüb. Android 13 və daha yeni versiyalarda uzun arxa fon yükləmələri üçün onlar tələb olunur.';
	@override String get reasonDataSaver => 'Data Saver aktivdir və bu, mobil internetdə arxa fon yükləmələrini bloklayır. Wi-Fi ilə yükləmələr işləməlidir.';
	@override String get reasonOemUnknown => 'PlezyNG arxa fonda olarkən yükləmələr dəfələrlə dayandı. PlezyNG-nin batareya və ya arxa fon istifadəsi tənzimləmələrini yoxlayın.';
	@override String get openSettings => 'Tənzimləmələri aç';
	@override String get stillNotWorking => 'Cihaza özəl kömək';
	@override String get stillNotWorkingDescription => 'Cihazınız üçün addımlara baxın və ya problem davam edərsə Tənzimləmələr › Jurnallara bax bölməsindən jurnal göndərin.';
	@override String get dialogTitle => 'Yükləmələr tamamlanmaya bilər';
	@override String get dialogDownloadAnyway => 'Yenə də yüklə';
	@override String get dialogFixFirst => 'Əvvəlcə bunu düzəlt';
	@override String get statusTile => 'Arxa fonda yükləmələr';
	@override String get statusOk => 'Arxa fonda işləməyə icazə verilir';
	@override String get statusBlocked => 'Sistem tənzimləmələri ilə bloklanıb';
	@override String get statusDegraded => 'Sistem tənzimləmələri ilə məhdudlaşdırılıb';
	@override String get statusUnknown => 'Hələ yoxlanılmayıb';
	@override String get settingsUnavailable => 'Bu cihazda sistem tənzimləmələri açıla bilmədi';
	@override String get linkUnavailable => 'Bu cihazda dontkillmyapp.com açıla bilmədi';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$az extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get library => 'Kitabxana';
	@override String get collections => 'Kolleksiyalar';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$az extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Pult serveri başladılır...';
	@override String get hostAddress => 'Əsas cihaz ünvanı';
	@override String get connected => 'Qoşuldu';
	@override String get serverRunning => 'Pult serveri aktivdir';
	@override String get serverStopped => 'Pult serveri dayandırıldı';
	@override String get serverRunningDescription => 'Şəbəkənizdəki mobil cihazlar qoşula bilər';
	@override String get serverStoppedDescription => 'Mobil cihazların qoşulmasına icazə vermək üçün serveri başladın';
	@override String get usePhoneToControl => 'Bu tətbiqi idarə etmək üçün mobil cihazınızı istifadə edin';
	@override String get startServer => 'Serveri başlat';
	@override String get stopServer => 'Serveri dayandır';
	@override String get minimize => 'Yığ';
	@override String get manualAddressHint => 'Əl ilə bağlantı ünvanı:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$az extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Eyni Plex hesabına sahib PlezyNG cihazları burada görünür';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Qoşulunur...';
	@override String get searchingForDevices => 'Cihazlar axtarılır...';
	@override String get noDevicesFound => 'Şəbəkənizdə cihaz tapılmadı';
	@override String get noDevicesHint => 'Masaüstündə PlezyNG-ni açın və eyni Wi-Fi-dan istifadə edin';
	@override String get availableDevices => 'Əlçatan cihazlar';
	@override String get manualConnection => 'Əl ilə qoşulma';
	@override String get cryptoInitFailed => 'Təhlükəsiz qoşulma başladılarkən xəta. Əvvəlcə Plex-ə daxil olun.';
	@override String get validationHostRequired => 'Lütfən əsas cihaz ünvanını daxil edin';
	@override String get validationHostFormat => 'Format IP:port şəklində olmalıdır';
	@override String get connectionTimedOut => 'Qoşulma vaxtı bitdi. Hər iki cihazda eyni şəbəkədən istifadə edin.';
	@override String get sessionNotFound => 'Cihaz tapılmadı.';
	@override String get authFailed => 'Kimlik doğrulanması uğursuz oldu.';
	@override String failedToConnect({required Object error}) => 'Qoşulma uğursuz oldu: ${error}';
	@override String get codeTitle => 'Çiftlik kodları';
	@override String get codeDescription => 'Bu barədə “Müslər” və “Müllər” adlı kitabın yazdığı “Müssər” adlı versiyonu yazıb.';
	@override String get codeInvalid => 'Bütün 32 sayı və sayıları ev kodundan girin.';
	@override String get updateRequired => 'İki cihazı da güvenli çifti destekleyen versiyona güncələ bilər.';
	@override String get hostDescription => 'Bu kodu bir dəfə hər bir yoldan daxil edin. gizli tutun: bu profilin kontrolünü sağlar.';
	@override String get resetCode => 'Xatırılan kodlar';
	@override String get resetDescription => 'Hər bir qalıqın yeni bir kod yaratır və hər bir qalıqın yeni bir kod yaratır.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$az extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Pult seansından ayrılmaq istəyirsiniz?';
	@override String get reconnecting => 'Yenidən qoşulunur...';
	@override String attemptOf({required Object current}) => 'Cəhd ${current} / 5';
	@override String get retryNow => 'İndi təzədən cəhd et';
	@override String get tabRemote => 'Pult';
	@override String get tabPlay => 'Oynat';
	@override String get tabMore => 'Daha çox';
	@override String get menu => 'Menyu';
	@override String get tabNavigation => 'Naviqasiya';
	@override String get tabDiscover => 'Kəşf et';
	@override String get tabLibraries => 'Kitabxanalar';
	@override String get tabSearch => 'Axtar';
	@override String get tabDownloads => 'Yükləmələr';
	@override String get tabSettings => 'Tənzimləmələr';
	@override String get previous => 'Əvvəlki';
	@override String get playPause => 'Oynat/Fasilə';
	@override String get next => 'Növbəti';
	@override String get seekBack => 'Geri sar';
	@override String get stop => 'Saxla';
	@override String get seekForward => 'İrəli sar';
	@override String get volume => 'Səs';
	@override String get volumeDown => 'Azalt';
	@override String get volumeUp => 'Artır';
	@override String get fullscreen => 'Tam ekran';
	@override String get subtitles => 'Altyazılar';
	@override String get audio => 'Səs';
	@override String get searchHint => 'Masaüstündə axtar...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$az extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Şəbəkə interfeysi tapılmadı';
	@override String get authenticationFailed => 'Kimlik doğrulanması uğursuz oldu';
	@override String serverStartFailed({required Object error}) => 'Pult serveri başladıla bilmədi: ${error}';
	@override String commandFailed({required Object error}) => 'Pult əmri göndərilə bilmədi: ${error}';
	@override String get joinTimedOut => 'Seansa qoşulma vaxtı bitdi';
	@override String get failedToConnectAnyAddress => 'Heç bir ünvana qoşuluna bilmədi';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts} cəhddən sonra əlaqə kəsildi';
	@override String get connectionLost => 'Əlaqə kəsildi';
}

// Path: services.names
class _Translations$services$names$az extends Translations$services$names$en {
	_Translations$services$names$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$az extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Simkl-ə yenidən qoşul';
	@override String get subtitle => 'Simkl bu bağlantının istifadə etdiyi daxil olma üsulunu ləğv edir. Yenidən qoşulduqda PlezyNG-ni təsdiqləmək üçün simkl.com açılır — PlezyNG parolunuzu heç vaxt görmür. Baxış tarixçəniz Simkl-də qalır.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$az extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'PlezyNG-ni ${service} üzərində aktivləşdirin';
	@override String get instructions => 'QR kodunu skan edin və ya aşağıdakı ünvana keçib bu kodu daxil edin:';
	@override String openToActivate({required Object service}) => 'Aktivləşdirmək üçün ${service} açın';
	@override String get copyCode => 'Aktivləşdirmə kodunu kopyala';
	@override String get waitingForAuthorization => 'Səlahiyyət gözlənilir…';
	@override String get codeCopied => 'Kod kopyalandı';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$az extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} xidmətinə daxil olun';
	@override String get body => 'Bu QR kodu skan edin və ya URL-i açın.';
	@override String openToSignIn({required Object service}) => 'Daxil olmaq üçün ${service} açın';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$az extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Daxil olma URL-ini kopyala';
	@override String get urlCopied => 'URL kopyalandı';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$az extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kitabxana filtri';
	@override String get subtitleAllSyncing => 'Bütün kitabxanalar eyniləşdirilir';
	@override String get subtitleNoneSyncing => 'Heç nə eyniləşdirilmir';
	@override String subtitleBlocked({required Object count}) => '${count} bloklandı';
	@override String subtitleAllowed({required Object count}) => '${count} icazə verildi';
	@override String get mode => 'Filtr rejimi';
	@override String get modeBlacklist => 'Qara siyahı';
	@override String get modeWhitelist => 'Ağ siyahı';
	@override String get modeHintBlacklist => 'Aşağıda seçilənlərdən başqa bütün kitabxanaları eyniləşdir.';
	@override String get modeHintWhitelist => 'Yalnız aşağıda seçilən kitabxanaları eyniləşdir.';
	@override String get libraries => 'Kitabxanalar';
	@override String get noLibraries => 'Kitabxana yoxdur';
	@override String get modeDescription => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$az extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Filmlər və filmləri hesabınızla eşlik edin.';
	@override String get mal => 'Anime listləri və MyAnimeList ilə progresə baxın.';
	@override String get anilist => 'Anime listləri və AniList ilə ilerlemeyi izləyin.';
	@override String get simkl => 'Simkl ilə filmlər, televiziyalar və anime izledi.';
	@override String get mdblist => 'MDBList ratings və listləri rekomandasyonlarda və Explore-da görünür.';
}

/// The flat map containing all translations for locale <az>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAz {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Tətbiq ikonu',
			'appIcon.defaultIcon' => 'Defolt',
			'appIcon.current' => 'Cari ikon',
			'appIcon.locked' => 'Ömür boyu qalıb',
			'appIcon.lockedHint' => '7 gün sürən testinizə başlamaq və ya alternativ ikonları kullanmaq üçün PlezyNG ömür boyu kilidini açmaq.',
			'appIcon.changeFailed' => 'Tətbiq ikonu dəyişdirilə bilmədi',
			'appIcon.launcherHint' => 'PlezyNG-dən çıxdıqdan sonra yeni ikon ana ekranınızda görünəcək.',
			'appIcon.tvLauncherHint' => 'PlezyNG-dən çıxdıqdan sonra yeni banner görünəcək. Android TV televizor yenidən başladılana qədər köhnəsini göstərə bilər.',
			'appIcon.names.midnight' => 'Gecəyarısı',
			'appIcon.names.ember' => 'Köz',
			'appIcon.names.paper' => 'Kağız',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Xətt',
			'appIcon.names.ocean' => 'Okean',
			'appIcon.names.ultraviolet' => 'Ultrabənövşəyi',
			'appIcon.names.matcha' => 'Matça',
			'appIcon.names.sunset' => 'Gün batımı',
			'appIcon.names.gold' => 'Qızıl',
			'appIcon.names.titanium' => 'Titan',
			'appIcon.names.glass' => 'Şüşə',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Piksel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Stiker',
			'appIcon.names.ticket' => 'Bilet',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Laylar',
			'appIcon.names.facet' => 'Faset',
			'appIcon.names.tilde' => 'Tilda',
			'appIcon.description' => '“Müsləhətçi”nin hər bir seçkinin necə göründüğünü göstər.',
			'auth.signInWithPlex' => 'Plex ilə daxil ol',
			'auth.showQRCode' => 'QR kodu göstər',
			'auth.authenticate' => 'Təsdiqlə',
			'auth.authenticationTimeout' => 'Təsdiqləmə vaxtı bitdi. Lütfən təzədən cəhd edin.',
			'auth.scanQRToSignIn' => 'Daxil olmaq üçün bu QR kodu skan edin',
			'auth.waitingForAuth' => 'Təsdiqləmə gözlənilir...\nSəyahətçinizdən (brauzer) daxil olun.',
			'auth.useBrowser' => 'Səyahətçini istifadə et',
			'auth.or' => 'və ya',
			'auth.connectToMediaBrowser' => ({required Object product}) => '${product}-a qoşul',
			'auth.quickConnect' => 'Sürətli Qoşulma',
			'auth.useQuickConnect' => 'Sürətli Qoşulmanı istifadə et',
			'auth.quickConnectInstructions' => 'Jellyfin-də Sürətli Qoşulmanı açın və bu kodu daxil edin.',
			'auth.quickConnectWaiting' => 'Təsdiq gözlənilir…',
			'auth.quickConnectCancel' => 'Ləğv et',
			'auth.quickConnectExpired' => 'Sürətli Qoşulmanın vaxtı bitdi. Təzədən cəhd edin.',
			'auth.localDataRecoveryRequired' => 'PlezyNG yerli daxil olma və gözləyən oxutma məlumatlarını təhlükəsiz bərpa edə bilmədi. Lütfən təzədən daxil olun.',
			'auth.pinCheckRejected' => 'Plex PIN yoxlaması rədd edildi',
			'auth.connectToDirectPlex' => 'Yerel Plex serverinə bağlanın',
			'common.cancel' => 'Ləğv et',
			'common.save' => 'Yadda saxla',
			'common.close' => 'Bağla',
			'common.closeMiniPlayer' => 'Mini oyunçı',
			'common.closeWorkspaceWindow' => 'Yakın pencerə',
			'common.returnToFullView' => 'Full View-a qayıtmaq',
			'common.manageMediaSessions' => 'Medya toplantıları',
			'common.hideMediaSessions' => 'Medya toplantıları',
			'common.mediaSessions' => 'Medya toplantıları',
			'common.mediaSessionsHint' => '“Park” onun penceresini gizləyir, amma açılır.Return onu tam görünüşdə açır; yakında bitir.',
			'common.sessionInWorkspace' => 'Çalışma alanında',
			'common.sessionParked' => 'Parkı',
			'common.sessionFullscreen' => 'Full ekran',
			'common.switchToNextWindow' => 'Bir sonraki pencerə qarşılaşır',
			'common.moveWindow' => 'Xatış pencerəsi',
			'common.finishMovingWindow' => 'Moving pencerə bitir',
			'common.moveWindowHint' => 'Bu qapı, bu qapıyı düzəltmək üçün uzun sürətdir.Bu qaplı qapısı da mümkün olur.',
			'common.movingWindowHelp' => 'Movil qapı · Qapı anahtarları ayarlayın · Enter saves · Escape cancles',
			'common.resizeWindow' => 'Xatış pencerəsi',
			'common.resizeWindowHint' => 'Bu manevrı çalın və ya pencerə qayıtmaq üçün silah anahtarlarını kullanın.',
			'common.workspaceWindowHint' => 'Movay kontrolü və ya uzun basın və hareket etmək üçün sürükür.',
			'common.workspacePaneHint' => 'Bu panu seçin ki, ona odaklanmaq üçün. bütün ekran kontrolünü genişletmək üçün kullanın.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Xəbəri: ${title}',
			'common.workspaceTitleHint' => '“Title bar”ı dəyişmək üçün sürükleyin; genişletmək üçün tam ekran düğmesini kullanın.',
			'common.moveToSessionTray' => 'Üçüncüsü Session Tray',
			'common.moveToSessionTrayHint' => 'Bu oturumu, penceresini görünməyən istifadə edir.',
			'common.closeSessionHint' => 'Bu qapıyı kapatır və oturumu bitir.',
			'common.sideBySideLayout' => '“Layout”dan “Side-by-side layout”a qayıtmaq',
			'common.floatingWindows' => 'Fırtınalı pencerə qapılmaq',
			'common.clear' => 'Təmizlə',
			'common.reset' => 'Sıfırla',
			'common.later' => 'Sonra',
			'common.submit' => 'Göndər',
			'common.confirm' => 'Təsdiqlə',
			'common.retry' => 'Təzədən cəhd et',
			'common.logout' => 'Çıxış et',
			'common.unknown' => 'Məlum deyil',
			'common.refresh' => 'Yenilə',
			'common.yes' => 'Bəli',
			'common.no' => 'Xeyr',
			'common.delete' => 'Sil',
			'common.edit' => 'Düzəliş et',
			'common.shuffle' => 'Qarışdır',
			'common.addTo' => 'Əlavə et...',
			'common.createNew' => 'Yenisini yarat',
			'common.connect' => 'Qoşul',
			'common.disconnect' => 'Əlaqəni kəs',
			'common.play' => 'Oynat',
			'common.pause' => 'Fasilə',
			'common.resume' => 'Davam et',
			'common.error' => 'Xəta',
			'common.search' => 'Axtar',
			'common.home' => 'Ana səhifə',
			'common.back' => 'Geri',
			'common.settings' => 'Tənzimləmələr',
			'common.mute' => 'Səsi söndür',
			'common.ok' => 'Oldu',
			'common.off' => 'Söndürülüb',
			'common.options' => 'Seçimlər',
			'common.seasonNumber' => ({required Object number}) => 'Mövsüm ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Seriya ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Hissə ${number}',
			'common.reconnect' => 'Yenidən qoşul',
			'common.viewAll' => 'Hamısına bax',
			'common.checkingNetwork' => 'Şəbəkə yoxlanılır...',
			'common.loadingServers' => 'Serverlər yüklənir...',
			'common.connectingToServers' => 'Serverlərə qoşulunur...',
			'common.startingOfflineMode' => 'Oflayn rejim başladılır...',
			'common.loading' => 'Yüklənir...',
			'common.fullscreen' => 'Tam ekran',
			'common.exitFullscreen' => 'Tam ekrandan çıx',
			'common.pressBackAgainToExit' => 'Çıxmaq üçün geri düyməsinə bir daha basın',
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
			'common.notAvailable' => 'Yoxdur',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'Serial',
			'common.mediaKind.season' => 'Sezon',
			'common.mediaKind.episode' => 'Epizod',
			'common.mediaKind.artist' => 'İfaçı',
			'common.mediaKind.album' => 'Albom',
			'common.mediaKind.track' => 'Mahnı',
			'common.mediaKind.collection' => 'Kolleksiya',
			'common.mediaKind.playlist' => 'Pleylist',
			'common.mediaKind.clip' => 'Klip',
			'common.mediaKind.photo' => 'Şəkil',
			'common.mediaKind.folder' => 'Qovluq',
			'screens.licenses' => 'Lisenziyalar',
			'screens.switchProfile' => 'Profili dəyiş',
			'screens.subtitleStyling' => 'Altyazı tənzimləmələri',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Jurnallar',
			'update.available' => 'Yenilənmə var',
			'update.versionAvailable' => ({required Object version}) => '${version} versiyası əlçatandır',
			'update.currentVersion' => ({required Object version}) => 'Cari: ${version}',
			'update.skipVersion' => 'Bu versiyanı ötür',
			'update.viewRelease' => 'Buraxılışa bax',
			'update.latestVersion' => 'Siz ən son versiyadasınız',
			'update.checkFailed' => 'Yenilənmələr yoxlanıla bilmədi',
			'settings.title' => 'Tənzimləmələr',
			'settings.supportDeveloper' => 'PlezyNG-yə dəstək ol',
			'settings.supportDeveloperDescription' => 'İnkişafı dəstəkləmək üçün ianə edin',
			'settings.lifetimeAccess' => 'PlezyNG Ömür boyu qalıb',
			'settings.language' => 'Dil',
			'settings.theme' => 'Mövzu',
			'settings.appearance' => 'Görünüş',
			'settings.detailPage' => 'Detaylı sayfa',
			'settings.themeSongsEnabled' => 'Şarkı sözləri',
			'settings.themeSongsEnabledDescription' => 'Tədbirlər media ilə tanışırken oyun oynayır.',
			'settings.themeSongVolume' => 'Şarkı sözləri',
			'settings.videoPlayback' => 'Video oynatma',
			'settings.videoPlaybackDescription' => 'Oynatma davranışını tənzimləyin',
			'settings.advanced' => 'Təkmilləşdirilmiş',
			'settings.episodePosterMode' => 'Seriya poster stili',
			'settings.seriesPoster' => 'Serial posteri',
			'settings.seasonPoster' => 'Mövsüm posteri',
			'settings.episodeThumbnail' => 'Kadr önizləməsi',
			'settings.showHeroSectionDescription' => 'Ana səhifədə xüsusi məzmun karuselini göstər',
			'settings.secondsLabel' => 'Saniyə',
			'settings.minutesLabel' => 'Dəqiqə',
			'settings.secondsShort' => 'san',
			'settings.minutesShort' => 'dəq',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Müddəti daxil edin (${min}-${max})',
			'settings.systemTheme' => 'Sistem',
			'settings.lightTheme' => 'Açıq',
			'settings.darkTheme' => 'Tünd',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Köz',
			'settings.glacierTheme' => 'Buzlaq',
			'settings.forestTheme' => 'Meşə',
			'settings.plumTheme' => 'Gavalı',
			'settings.paperTheme' => 'Kağız',
			'settings.libraryDensity' => 'Kitabxana sıxlığı',
			'settings.displayScale' => 'Ekran miqyası',
			'settings.compact' => 'Sıx',
			'settings.comfortable' => 'Rəhat',
			'settings.gridSpacing' => 'Tor aralığı',
			'settings.gridSpacingTight' => 'Sıx',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Geniş',
			'settings.tvCornerSpotlightBackdrop' => 'Künc işıqlandırma fonu',
			'settings.tvCornerSpotlightBackdropDescription' => 'Arxa fonu ekranı örtmək əvəzinə sağ üst küncdə göstər',
			'settings.viewMode' => 'Baxış rejimi',
			'settings.gridView' => 'Tor',
			'settings.listView' => 'Siyahı',
			'settings.showHeroSection' => 'Xüsusi bölməni göstər',
			'settings.showHomeBackdrop' => 'Evdə arşiv işləri görmək',
			'settings.showHomeBackdropDescription' => 'Evdə böyük art işləri görmək',
			'settings.contentScreensaverEnabled' => 'Ekranın içeriği',
			'settings.contentScreensaverEnabledDescription' => '“Tüm ekranlı” aparın sonra “Tüm ekranlı” aparın.',
			'settings.contentScreensaverDelay' => 'Ekranın başlanmasından sonra',
			'settings.contentScreensaverLibraries' => 'Screensaver kütüphanləri',
			'settings.contentScreensaverLibrariesDescription' => 'Ekran qoruyucusu üçün təsvirləri hansı kitabxanaların təmin edəcəyini seçin. Heç biri seçilməsə, bütün kitabxanaların təsvirləri istifadə olunur.',
			'settings.contentScreensaverAllLibraries' => 'Bütün kütüphanlər',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} seçilmiş kütüphərlər',
			'settings.contentScreensaverNoLibraries' => 'Bağlantılı medya kütüphaneleri yoxdur.',
			'settings.contentScreensaverDismissHint' => 'Hər bir düğmə və ya xilas etmək üçün tıklayın',
			'settings.newEpisodeNotifications' => 'Yeni xəbərlər',
			'settings.newEpisodeNotificationsDescription' => 'Yeni bir epizod bir göstərə daxil olduğunda uyarır. Plezy açılsa da kontrol edilir.',
			'settings.continueWatchingRowSize' => 'Görüntülər: Sürüntülər boyutu',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} kartları',
			'settings.rowSizeCompact' => 'Sıx',
			'settings.rowSizeStandard' => 'Standart',
			'settings.rowSizeLarge' => 'Böyük',
			'settings.continueWatchingAction' => 'İzləməyə davam et əməliyyatı',
			'settings.continueWatchingPlay' => 'Oynat',
			'settings.continueWatchingDetails' => 'Ətraflı aç',
			'settings.episodeAction' => 'Seriya əməliyyatı',
			'settings.episodePlay' => 'Oynat',
			'settings.episodeDetails' => 'Ətraflı aç',
			'settings.useGlobalHubs' => 'Ana səhifə quruluşunu istifadə et',
			'settings.useGlobalHubsDescription' => 'Birləşdirilmiş ana səhifə bölmələrini göstər. Əks halda kitabxana tövsiyələrini istifadə edir.',
			'settings.showServerNameOnHubs' => 'Bölmələrdə server adını göstər',
			'settings.showServerNameOnHubsDescription' => 'Bölmə başlıqlarında həmişə server adlarını göstər.',
			'settings.groupLibrariesByServer' => 'Kitabxanaları serverə görə qrupla',
			'settings.groupLibrariesByServerDescription' => 'Yan menyu kitabxanalarını hər media serverinin altında qruplaşdır.',
			'settings.alwaysKeepSidebarOpen' => 'Yan menyunu həmişə açıq saxla',
			'settings.alwaysKeepSidebarOpenDescription' => 'Yan menyu genişlənmiş qalır və məzmun sahəsi buna uyğunlaşır',
			'settings.showUnwatchedCount' => 'Baxılmamış sayını göstər',
			'settings.showUnwatchedCountDescription' => 'Seriallarda və mövsümlərdə baxılmamış seriya sayını göstər',
			'settings.showWatchedIndicators' => 'Baxılmış göstəriciləri göstər',
			'settings.showWatchedIndicatorsDescription' => 'Baxılmış kinolarda, seriallarda və seriyalarda quşçuq göstər',
			'settings.showEpisodeNumberOnCards' => 'Kartlarda seriya nömrəsini göstər',
			'settings.showEpisodeNumberOnCardsDescription' => 'Seriya kartlarında mövsüm və seriya nömrəsini göstər',
			'settings.showSeasonPostersOnTabs' => 'Mərhələlərdə mövsüm posterlərini göstər',
			'settings.showSeasonPostersOnTabsDescription' => 'Hər mövsümün posterini öz bölməsinin üstündə göstər',
			'settings.tvFullCardLayout' => 'Tam TV kartları',
			'settings.tvFullCardLayoutDescription' => 'Aktyor adları üstündə olan yalnız şəkil tərkibli TV kartları istifadə et',
			'settings.focusGlow' => 'Fokus parıltısı',
			'settings.focusGlowDescription' => 'Fokuslanmış kartın ətrafında yumşaq parıltı çək',
			'settings.visualEffects' => 'Vizual effektlər',
			'settings.visualEffectsAuto' => 'Avtomatik',
			'settings.visualEffectsAutoDescription' => 'Zəif cihazlarda effektləri avtomatik olaraq azalt',
			'settings.visualEffectsFull' => 'Tam',
			'settings.visualEffectsReduced' => 'Azaldılmış',
			'settings.visualEffectsReducedDescription' => 'Daha az animasiya və daha aşağı keyfiyyətli şəkillər',
			'settings.hideSpoilers' => 'Baxılmamış seriyalar üçün spoylerləri gizlə',
			'settings.hideSpoilersDescription' => 'Baxılmamış seriyalar üçün miniatürləri və təsvirləri bulanıqlaşdır',
			'settings.playerBackend' => 'Oynadıcı infrastrukturu',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Avadanlıq kod açılması',
			'settings.hardwareDecodingDescription' => 'Mümkün olduqda avadanlıq sürətləndirməsini istifadə et',
			'settings.playbackBuffer' => 'Oxutma buferi',
			'settings.playbackBufferAuto' => 'Avtomatik (tövsiyə olunur)',
			'settings.playbackBufferLarge' => 'Böyük',
			'settings.playbackBufferExtraLarge' => 'Çox böyük',
			'settings.playbackBufferDescription' => 'Qeyri-sabit əlaqələrə qarşı daha çox buferləyir. Bufer ölçüsü ilə də məhdudlaşır.',
			'settings.streamBufferSize' => 'Buffer ölçüsü',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Transcodes, sunucuya öz transcode bufferdə durdurulur. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Playback Buffer-i ayarlanırsa, appın memur limitinin yarısına qapılmışdır.',
			'settings.streamBufferMegabytes' => 'Megabətlər',
			'settings.defaultQualityTitle' => 'Defolt keyfiyyət',
			'settings.cellularQualityTitle' => 'Mobil şəbəkədə defolt keyfiyyət',
			'settings.remoteQualityTitle' => 'Remote Streaming Qalığı',
			'settings.remoteQualitySameAsDefault' => 'Default Qalitəsi',
			'settings.cellularQualitySameAsDefault' => 'Defolt keyfiyyətlə eyni',
			'settings.directPlayCoveredQuality' => 'Kiçik videoları orijinal keyfiyyətdə oynat',
			'settings.directPlayCoveredQualityDescription' => 'Keyfiyyət limitinə uyğun gələn videoları yenidən kodlaşdırmaq əvəzinə birbaşa oynat',
			'settings.videoCodecs' => 'Video kodekləri',
			'settings.videoCodecsDescription' => 'İşarələnməmiş kodekləri server yenidən kodlaşdırır',
			'settings.videoCodecsAlwaysAccepted' => 'Həmişə qəbul edilir',
			'settings.musicQualityTitle' => 'Musiqi keyfiyyəti',
			'settings.subtitleStyling' => 'Altyazı tənzimləmələri',
			'settings.subtitleStylingDescription' => 'Altyazı görünüşünü özünüləşdirin',
			'settings.smallSkipDuration' => 'Kiçik ötürmə müddəti',
			'settings.largeSkipDuration' => 'Böyük ötürmə müddəti',
			'settings.rewindOnResume' => 'Davam edərkən geri sar',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} saniyə', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} saniyə', ), 
			'settings.defaultSleepTimer' => 'Defolt yuxu taymeri',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} dəqiqə', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} dəqiqə', ), 
			'settings.rememberTrackSelections' => 'Hər film/serial üçün səs/altyazı seçimlərini xatırla',
			'settings.chooseTracksBeforePlayback' => 'Video və video oyunları oynamaqdan əvvəl seçin',
			'settings.chooseTracksBeforePlaybackDescription' => 'Videoya başlanmadan əvvəl kaynak audio və subtitle izləri seçin.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Bu cihazda hər zaman subtitrlər göstərilir.',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Serverin seçilmə qalıbı olmadığında, bir yol yerə seçin.Bu, sunucu tercihini heç vaxt dəyişməz.',
			'settings.autoDownloadPreferredSubtitle' => 'FETCH-ın preferred-language subtitlesləri eksikdir',
			'settings.autoDownloadPreferredSubtitleDescription' => 'İsteyiniz ki, bir yerdə bir yerdə yerdə bir subtitr seçin. bir yerdə yoksa, bir yerə destek olunca bir yerdə tutmaq istə.',
			'settings.rememberTrackSelectionsDescription' => 'Hər məzmun üçün səs və altyazı seçimlərini yadda saxla',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex hər seçimi serverdə fayl üzrə saxlayır; Jellyfin həmçinin hesabın "Seçimləri xatırla" funksiyasını aktivləşdirir; Emby dəstəklənmir',
			'settings.followServerTrackSelections' => 'Hər epizod üçün serverin trek seçimlərini istifadə et',
			'settings.followServerTrackSelectionsDescription' => 'Epizod dəyişəndə cari seçimi köçürmək əvəzinə serverdə seçilmiş səs və altyazını tətbiq et',
			'settings.resumeMusicOnLaunch' => 'Musiqi sessiyasını yadda saxla',
			'settings.resumeMusicOnLaunchDescription' => 'Tətbiq açılanda son mahnını dayandırıldığı yerdə fasilədə aç',
			'settings.showChapterMarkersOnTimeline' => 'Zaman çubuğunda hissə işarələrini göstər',
			'settings.showChapterMarkersOnTimelineDescription' => 'Zaman çubuğunu hissə sərhədlərinə böl',
			'settings.specialsOrdering' => 'Xüsusi bölmələr epizod sırasına görə',
			'settings.specialsOrderingDescription' => 'Xüsusi bölmələrin serialın izləmə sırasındakı yeri',
			'settings.specialsOrderingServer' => 'Server sırasını izlə',
			'settings.specialsOrderingAirDate' => 'Yayım tarixinə görə qarışdır',
			'settings.specialsOrderingLast' => 'Adi mövsümlərdən sonra',
			'settings.clickVideoTogglesPlayback' => 'Oynat/fasilə üçün videoya toxun',
			'settings.clickVideoTogglesPlaybackDescription' => 'İdarəetməni göstərmək əvəzinə oynatmaq/fasilə etmək üçün videoya toxun.',
			'settings.videoPlayerControls' => 'Video oynadıcı idarəetmələri',
			'settings.keyboardShortcuts' => 'Klaviatura qısayolları',
			'settings.keyboardShortcutsDescription' => 'Klaviatura qısayollarını özünüləşdirin',
			'settings.videoPlayerNavigation' => 'Video oynadıcı naviqasiyası',
			'settings.videoPlayerNavigationDescription' => 'Oynadıcı idarəetmələrində hərəkət etmək üçün ox düymələrini istifadə edin',
			'settings.watchTogetherRelay' => 'Birlikdə İzlə relesi',
			'settings.watchTogetherRelayDescription' => 'Öz relenizi təyin etməsəniz, ictimai Open Watch Party releləri istifadə olunur',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Düzgün HTTP və ya HTTPS rele ünvanı daxil edin.',
			'settings.crashReporting' => 'Xəta hesabatı',
			'settings.crashReportingDescription' => 'Tətbiqi təkmilləşdirməyə kömək etmək üçün xəta hesabatları göndərin',
			'settings.debugLogging' => 'Xəta saxlama jurnalı',
			'settings.debugLoggingDescription' => 'Problemləri həll etmək üçün ətraflı jurnal qeydiyyatını aktivləşdirin',
			'settings.viewLogs' => 'Jurnallara bax',
			'settings.viewLogsDescription' => 'Tətbiq jurnallarına baxın',
			'settings.clearImageCache' => 'Şəkil keşini təmizlə',
			'settings.clearImageCacheDescription' => 'Keşlənmiş şəkilləri təmizləyir. Yenidən yüklənənədək şəkillər daha yavaş yüklənə bilər.',
			'settings.clearImageCacheSuccess' => 'Şəkil keşi uğurla təmizləndi',
			'settings.resetSettings' => 'Tənzimləmələri sıfırla',
			'settings.resetSettingsDescription' => 'Defolt tənzimləmələri bərpa edin. Bu əməliyyat geri qaytarıla bilməz.',
			'settings.resetSettingsSuccess' => 'Tənzimləmələr uğurla sıfırlandı',
			'settings.backup' => 'Ehtiyat nüsxə',
			'settings.exportSettings' => 'Tənzimləmələri ixrac et',
			'settings.exportSettingsDescription' => 'Seçimlərinizi fayla yadda saxlayın',
			'settings.exportSettingsSuccess' => 'Tənzimləmələr ixrac edildi',
			'settings.importSettings' => 'Tənzimləmələri idxal et',
			'settings.importSettingsDescription' => 'Seçimləri fayldan bərpa edin',
			'settings.importSettingsConfirm' => 'Bu cari tənzimləmələrinizin üzərinə yazacaq. Davam edilsin?',
			'settings.importSettingsSuccess' => 'Tənzimləmələr idxal edildi',
			'settings.importSettingsInvalidFile' => 'Bu fayl düzgün PlezyNG tənzimləmələr faylı deyil',
			'settings.importSettingsNoUser' => 'Tənzimləmələri idxal etməzdən əvvəl daxil olun',
			'settings.cloudBackup' => 'Qıraqlı Qıraqlı',
			'settings.cloudBackupDescription' => 'Xatırılan ayarları WebDAV final noktasına HTTPS üzerinden yedekə.Server bağlantıları və xəttialları bu cihazda qalır.',
			'settings.cloudBackupUrl' => 'WebDAV JSON fil URL',
			'settings.cloudBackupUsername' => 'İstifadəçi adı',
			'settings.cloudBackupPassword' => 'Şifrə',
			'settings.cloudBackupSaved' => 'Cloud backup destinasyonu qurulmuşdur',
			'settings.cloudBackupNow' => 'Şimdilik geri',
			'settings.cloudBackupComplete' => 'Backup yüklənlər',
			'settings.cloudBackupRestore' => 'Backup qayıtmaq',
			'settings.cloudBackupRestoreConfirm' => 'Bu, bu cihazda uyumlu mobil ayarların yerini alacaq.',
			'settings.cloudBackupRestored' => '“Cloud Backup”dan qayıtılmış ayarlar',
			'settings.shortcutsReset' => 'Qısayollar defolt vəziyyətə sıfırlandı',
			'settings.resetShortcutsConfirm' => 'Bu, xüsusi qısayollarınızı defolt qısayollarla əvəz edəcək. Davam edilsin?',
			'settings.about' => 'Haqqında',
			'settings.aboutDescription' => 'Tətbiq məlumatı və lisenziyalar',
			'settings.updates' => 'Yenilənmələr',
			'settings.updateAvailable' => 'Yenilənmə var',
			'settings.checkForUpdates' => 'Yenilənmələri yoxla',
			'settings.autoCheckUpdatesOnStartup' => 'Açılışda yenilənmələri avtomatik yoxla',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Açılışda yenilənmə olduqda xəbərdar et',
			'settings.validationErrorEnterNumber' => 'Lütfən düzgün rəqəm daxil edin',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Müddət ${min} və ${max} ${unit} arasında olmalıdır',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Qısayol artıq ${action} üçün təyin edilib',
			'settings.shortcutUpdated' => ({required Object action}) => '${action} üçün qısayol yeniləndi',
			'settings.saveFailed' => 'Dəyişikliklər yadda saxlanıla bilmədi. Təzədən cəhd edin.',
			'settings.autoPlayAndSkip' => 'Avtomatik oynat və ötür',
			'settings.autoPlayNextEpisode' => 'Növbəti seriyanı avtomatik oynat',
			'settings.autoPlayNextEpisodeDescription' => 'Bir seriya bitdikdə növbətisini avtomatik başlat',
			'settings.shuffleStartsFromBeginning' => 'Qarışdırma əvvəldən başlayır',
			'settings.shuffleStartsFromBeginningDescription' => 'Qarışdırarkən hər seriyanı davam etdirmək əvəzinə əvvəldən başlat',
			'settings.plexCinemaPreRoll' => 'Cinematografya serveri',
			'settings.plexCinemaPreRollDescription' => 'Filmin başlatılmasından əvvəl Plex və ya Jellyfin və Emby introsları oynayın.',
			'settings.playNextCountdown' => 'Növbəti seriya geri sayımı',
			'settings.playNextCountdownImmediate' => 'Dərhal oynat',
			'settings.skipIntroMode' => 'Girişi ötür',
			'settings.skipIntroModeOffDescription' => 'Girişləri ötürmə düyməsi olmadan normal oynat',
			'settings.skipIntroModeButtonDescription' => 'Giriş başlayanda ötürmə düyməsini göstər',
			'settings.skipIntroModeAutoDescription' => 'Girişləri aşağıdakı ləngimədən sonra avtomatik ötür',
			'settings.skipCreditsMode' => 'Titrləri ötür',
			'settings.skipCreditsModeOffDescription' => 'Titrləri ötürmə düyməsi olmadan normal oynat',
			'settings.skipCreditsModeButtonDescription' => 'Titrlər başlayanda ötürmə düyməsini göstər',
			'settings.skipCreditsModeAutoDescription' => 'Titrləri avtomatik ötür və növbəti seriyanı oynat',
			'settings.skipAdsMode' => 'Adlar üçün',
			'settings.skipAdsModeOffDescription' => 'Xatırılan reklamları normal bir skip düğmə olmadan oynayın',
			'settings.skipAdsModeButtonDescription' => 'Xərimdə bir "Skype" düğmesini görünür: Plex bir reklamı tespit edər',
			'settings.skipAdsModeAutoDescription' => 'Xatırılan reklamları aşağıdaki gecə sonra otomatik olarak atın',
			'settings.musicPlayback' => 'Musiqi Playback',
			'settings.musicSweetFades' => 'Süt fəlakları',
			'settings.musicSweetFadesDescription' => 'Plex-də səs səviyyəsi məlumatları olduqda musiqi parçalarının əvvəlində və sonunda səsi tədricən dəyişin. Albomların oxudulması dəyişmir.',
			'settings.skipMarkerModeOff' => 'Söndürülüb',
			'settings.skipMarkerModeButton' => 'Düyməni göstər',
			'settings.skipMarkerModeAuto' => 'Avtomatik',
			'settings.forceSkipMarkerFallback' => 'Ehtiyat işarələri məcburi et',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex işarələri olsa belə hissə başlığı şablonlarını istifadə et',
			'settings.theIntroDbFallback' => 'IntroDB-i intro fallback kimi istifadə edin',
			'settings.theIntroDbFallbackDescription' => 'Soruşturma zamanı yalnız xilas olunsa, xilas olunsa, xilas olunsa, xilas olunsa, xilas olunsa.',
			'settings.autoSkipDelay' => 'Avtomatik ötürmə ləngiməsi',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Avtomatik ötürməzdən əvvəl ${seconds} saniyə gözlə',
			'settings.introPattern' => 'Giriş işarəsi şablonu',
			'settings.introPatternDescription' => 'Hissə başlıqlarında giriş işarələrini tapmaq üçün Regex şablonu',
			'settings.creditsPattern' => 'Titr işarəsi şablonu',
			'settings.creditsPatternDescription' => 'Hissə başlıqlarında titr işarələrini tapmaq üçün Regex şablonu',
			'settings.prerolls' => 'Prerolllər',
			'settings.playPrerollsBeforeMovies' => 'Filmə əvvəl oynayır',
			'settings.playPrerollsBeforeMoviesDescription' => 'Hər filmdən əvvəl aşağıdaki seçiminizdən bir random klip oynayın.',
			'settings.prerollLibrary' => 'Preroll kütüphane',
			'settings.prerollLibraryNotSet' => 'Təyin edilməyib',
			'settings.prerollLibraryNoneFound' => 'Sizin serverlərinizdə heç bir kütüphane bulunmaz.',
			'settings.prerollSelection' => 'Seçilmişlər',
			'settings.prerollSelectionPickLibraryFirst' => 'Birincisi bir kütüphane seçin.',
			'settings.prerollSelectionNoneSelected' => 'Seçilmə qalıb',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} seçilib',
			'settings.prerollItemPicker' => 'Seçimlər',
			'settings.prerollItemPickerLoadFailed' => 'Bu kütüphanadan bir şey yükləmə bilərəm.',
			'settings.invalidRegex' => 'Səhv requlyar ifadə (Regex)',
			'settings.regex' => 'Requlyar ifadə (Regex)',
			'settings.downloads' => 'Yükləmələr',
			'settings.downloadLocationDescription' => 'Yüklənmiş məzmunun harada saxlanacağını seçin',
			'settings.downloadLocationDefault' => 'Defolt (Tətbiq yaddaşı)',
			'settings.downloadLocationCustom' => 'Xüsusi məkan',
			'settings.selectFolder' => 'Qovluq seç',
			'settings.resetToDefault' => 'Defolt vəziyyətə sıfırla',
			'settings.currentPath' => ({required Object path}) => 'Cari: ${path}',
			'settings.downloadLocationChanged' => 'Yükləmə məkanı dəyişdirildi',
			'settings.downloadLocationReset' => 'Yükləmə məkanı defolt vəziyyətə sıfırlandı',
			'settings.downloadLocationInvalid' => 'Seçilmiş qovluğa yazmaq olmur',
			'settings.downloadLocationPickerUnavailable' => 'Qovluq seçimi bu cihazda əlçatan deyil',
			'settings.downloadOnWifiOnly' => 'Yalnız Wi-Fi ilə yüklə',
			'settings.downloadOnWifiOnlyDescription' => 'Mobil məlumat istifadə edildikdə yükləmələri dayandır',
			'settings.autoRemoveWatchedDownloads' => 'Baxılmış yükləmələri avtomatik sil',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Baxılmış yükləmələri avtomatik olaraq sil',
			'settings.autoDownloadContinueWatching' => 'Auto-Downloads İndi gözləyir',
			'settings.autoDownloadContinueWatchingDescription' => '"Devil" filində yerləri aşağı indirilir və fildən ayrıldıqdan sonra bunları kaldırır.',
			'settings.downloadQuality' => 'Qalındırma kalitəsi',
			'settings.downloadQualityDescription' => 'Plex download quue-da bir dönüştürülmüş kopya hazırlar. Jellyfin və Emby transkodları, fil indirilir; durdurulmuş transferlər yeniden başlatılmalıdır.',
			'settings.askDownloadQualityEachTime' => 'Hər bir download üçün seçin.',
			'settings.askDownloadQualityEachTimeDescription' => 'Videoya baxmadan əvvəl cildin pikselini göstərin',
			'settings.cellularDownloadBlocked' => 'Mobil şəbəkədə yükləmələr bloklanıb. Wi-Fi istifadə edin və ya tənzimləməni dəyişin.',
			'settings.maxVolume' => 'Maksimal səs',
			'settings.maxVolumeDescription' => 'Sakit videolar üçün səsin 100%-dən yuxarı qalxmasına icazə ver',
			'settings.maxVolumePercent' => ({required Object percent}) => '%${percent}',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discord-da nəyə baxdığınızı göstərin',
			'settings.services' => 'Xidmətlər',
			'settings.servicesDescription' => 'Trakt, MyAnimeList, Seerr və daha çoxunu qoşun',
			'settings.manageLibrariesDescription' => 'Kitabxanaları yenidən sıralayın və gizlədin',
			'settings.companionRemoteServer' => 'Köməkçi pult serveri',
			'settings.companionRemoteServerDescription' => 'Şəbəkənizdəki mobil cihazların bu tətbiqi idarə etməsinə icazə verin',
			'settings.companionRemoteServerStartFailed' => 'Köməkçi pult serveri başladıla bilmədi',
			'settings.companionRemoteServerStopFailed' => 'Köməkçi pult serveri dayandırıla bilmədi',
			'settings.autoPip' => 'Avtomatik Pəncərə daxilində Pəncərə (PiP)',
			'settings.autoPipDescription' => 'Oynatma zamanı tətbiqdən çıxdıqda avtomatik PiP rejiminə keç',
			'settings.matchContentFrameRate' => 'Kadr tezliyini uyğunlaşdır',
			'settings.matchContentFrameRateDescription' => 'Ekran yenilənmə tezliyini video məzmununa uyğunlaşdır',
			'settings.matchContentResolution' => 'Məzmunun görüntü keyfiyyətinə uyğunlaş',
			'settings.matchContentResolutionDescription' => 'Ekranı videonun öz görüntü keyfiyyətinə keçirir ki, miqyaslandırmanı televizorunuz etsin. Oxutma zamanı menyular və altyazılar da miqyaslandırılır',
			'settings.matchRefreshRate' => 'Yenilənmə tezliyini uyğunlaşdır',
			'settings.matchRefreshRateDescription' => 'Tam ekranda ekran yenilənmə tezliyini uyğunlaşdır',
			'settings.matchDynamicRange' => 'Dinamik diapazonu uyğunlaşdır',
			'settings.matchDynamicRangeDescription' => 'HDR məzmun üçün HDR-ı açın, sonra SDR-a qayıdın',
			'settings.displaySwitchDelay' => 'Ekran dəyişmə ləngiməsi',
			'settings.tunneledPlayback' => 'Tünellənmiş oynatma',
			'settings.tunneledPlaybackDescription' => 'Video tünelləməni istifadə et. HDR oynatmada qara ekran görünürsə və ya hərəkət takılırsa söndürün.',
			'settings.audioPassthrough' => 'Səsin birbaşa ötürülməsi (Passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS səslərini yenidən kodlamadan TV və ya resiverə göndərir. Səs gəlmirsə söndürün.',
			'settings.audioPassthroughDescriptionApple' => 'Atmos daxil olmaqla Dolby Digital Plus üçün Apple-ın daxili dekoderini istifadə edin. DTS və TrueHD yenə də çoxkanallı PCM kimi oynadılır. Səs gəlmirsə söndürün.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Atmos daxil olmaqla Dolby Digital Plus üçün Apple-ın daxili Dolby dekoderini istifadə edin. iOS, iPadOS və tvOS 26 və ya daha yeni versiyalarda TrueHD Atmos və DTS:X məkan səsi kimi oynadılır. Digər DTS və TrueHD trekləri çoxkanallı PCM kimi oynadılır. Səs gəlmirsə söndürün.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Səsin gurluğunu normallaşdırma aktivkən söndürülüb',
			'settings.audioChannelLimit' => 'Səs kanalları',
			'settings.audioChannelLimitDescription' => 'Bütün kanalları oynada bilməyən dinamiklər, qulaqlıqlar və ya HDMI qurğuları üçün dekodlanmış səsi daha az kanala endir',
			'settings.audioChannelLimitOriginal' => 'Orijinal',
			'settings.audioChannelLimitOriginalDescription' => 'Trekdəki bütün kanalları oynat',
			'settings.audioChannelLimitSurround51' => '5.1-ə qədər',
			'settings.audioChannelLimitSurround51Description' => 'Yalnız 5.1 PCM qəbul edən televizorlar və resiverlər üçün 7.1-i 5.1-ə endir. Birbaşa ötürməyə təsir etmir.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Stereo dinamiklər və ya qulaqlıqlar üçün iki kanala endir. Birbaşa ötürməni söndürür.',
			'settings.downmixCenterBoost' => 'Mərkəz kanal gücləndirilməsi',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Gücləndirmə (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Çevirmədə səsi normallaşdır',
			'settings.audioDownmixNormalizeDescription' => 'Səs kəsilmələrinin qarşısını almaq üçün səviyyəni endirin. Orijinal səs səviyyəsini saxlamaq üçün söndürün (yüksək səsli səhnələr təhrif oluna bilər).',
			'settings.dvConversionMode' => 'Dolby Vision çevrilməsi',
			'settings.dvConversionModeDescription' => 'Dolby Vision Profile 7 fayllarının necə emal ediləcəyini seçin.',
			'settings.dvConversionAuto' => 'Avtomatik',
			'settings.dvConversionNative' => 'Daxili / Söndürülüb',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Cihaz imkanlarının təyini və normal davranışdan istifadə et',
			'settings.dvConversionNativeDescription' => 'Daxili DV7-ni məcburi et',
			'settings.dvConversionDv81Description' => 'Dolby Vision profile 8.1-ə çevrilməni məcburi et',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision təbəqələrini sil və sadə HEVC kimi təqdim et',
			'settings.experimentalDolbyVision' => 'Eksperimental Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'Növbəti oxutmada eksperimental FEL renderindən istifadə edin. Mühərrikin ayrıca yığılması tələb olunur.',
			'settings.dvExperimentUnavailableDescription' => 'Bu sınaq hazırda yalnız Linux-da mövcuddur.',
			'settings.dvCompatibilityFallback' => 'Uyğunluq üçün ehtiyat rejim',
			'settings.dvCompatibilityFallbackDescription' => 'Sınaq başlaya bilməsə, standart renderdən istifadə edin. FEL məlumatları itə bilər.',
			'settings.dvExperimentDiagnostics' => 'Video sınağının jurnalı',
			'settings.dvExperimentDiagnosticsDescription' => 'Növbəti oxutmada ətraflı pleyer jurnallarını aktivləşdirin.',
			'settings.disableDolbyVision' => 'Dolby Vision-u söndür',
			'settings.disableDolbyVisionDescription' => 'Faylda varsa, Dolby Vision əvəzinə HDR10 və ya HLG təbəqəsini oynat',
			'settings.hdrSdrConversion' => 'HDR-dən SDR-ə çevirmə',
			'settings.hdrSdrConversionDescription' => 'Ekran HDR göstərə bilmədikdə HDR videonu nəyin çevirəcəyini seçin.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Avtomatik',
			'settings.hdrSdrConversionAutoDescription' => 'Android 9 və sonrakı versiyalarda cihaz, köhnə versiyalarda oynadıcı',
			'settings.hdrSdrConversionDevice' => 'Cihaz',
			'settings.hdrSdrConversionDeviceDescription' => 'Çevirməni cihazın video avadanlığı edir. Ən sürətlisi, lakin rənglər cihazdan asılıdır',
			'settings.hdrSdrConversionPlayer' => 'Oynadıcı',
			'settings.hdrSdrConversionPlayerDescription' => 'Çevirməni oynadıcı edir. Sabit rənglər, lakin zəif TV qutularında 4K ilişə bilər',
			'settings.deinterlace' => 'Deinterleysinq',
			'settings.deinterlaceDescription' => 'Sətirlərarası videodakı darama artefaktlarını aradan qaldır (yalnız mpv oynadıcısı)',
			'settings.deinterlaceOff' => 'Söndürülüb',
			'settings.deinterlaceOffDescription' => 'Sətirlərarası videonu dekodlandığı kimi göstər',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Hər yarımkadrı tam kadra çevir. İdman, xəbər və konsert kimi TV üçün çəkilmiş videolar üçün',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => '29.97 fps-ə telesine edilmiş film və animasiyaların orijinal kadrlarını bərpa et (NTSC DVD-lərdə geniş yayılıb). TV üçün çəkilmiş video ilişir. Canlı TV Video rejimindən istifadə edir',
			'settings.requireProfileSelectionOnOpen' => 'Açılışda profil soruş',
			'settings.requireProfileSelectionOnOpenDescription' => 'Tətbiq hər dəfə açıldıqda profil seçimini göstər',
			'settings.forceTvMode' => 'TV rejimini məcburi et',
			'settings.forceTvModeDescription' => 'TV interfeysini məcburi et. Avtomatik təyin etməyən cihazlar üçündür. Yenidən başlatma tələb olunur.',
			'settings.startInFullscreen' => 'Tam ekranda başlat',
			'settings.startInFullscreenDescription' => 'PlezyNG-ni açılışda tam ekran rejimində aç',
			'settings.exitFullscreenOnPlayerClose' => 'Oynadıcı bağlandıqda tam ekrandan çıx',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Video oynadıcını bağlayarkən avtomatik tam ekrandan çıx',
			'settings.autoHidePerformanceOverlay' => 'Məhsuldarlıq paneli avtomatik gizlənsin',
			'settings.autoHidePerformanceOverlayDescription' => 'Məhsuldarlıq panelini oynatıcı idarəetmələri ilə birlikdə gizlət',
			'settings.showNavBarLabels' => 'Naviqasiya paneli yazılarını göstər',
			'settings.showNavBarLabelsDescription' => 'Naviqasiya paneli ikonlarının altında mətni göstər',
			'settings.startupSection' => 'Başlanğıc bölməsi',
			'settings.preferredServer' => 'Serverlər tercih edilir',
			'settings.preferredServerDescription' => 'Bu sunucu sonucunu öncelik verin və hər bir bağlantılı sunucuya bağlanın.',
			'settings.preferredServerAutomatic' => 'Avtomatik',
			'settings.showExploreTab' => 'Kəşf et nişanını göstər',
			'settings.showExploreTabDescription' => 'Plex Discover və qoşulmuş izləmə xidmətlərindəki məzmunla Kəşf et nişanını göstər',
			'settings.hideEmptyLibraries' => 'Boş kütüphaneyi saklayın',
			'settings.hideEmptyLibrariesDescription' => 'Server-da bildirilmiş element sayının sıfırı olan kütüphaneyi navigasiyadən çıkarır.',
			'settings.liveTvDefaultFavorites' => 'Canlı TV-də sevimli kanalları defolt et',
			'settings.liveTvDefaultFavoritesDescription' => 'Canlı TV açıldıqda yalnız sevimli kanalları göstər',
			'settings.general' => 'Ümumi',
			'settings.generalDescription' => 'Dil, başlanğıc və pəncərə davranışı',
			'settings.languageAndRegion' => 'Dil və Region',
			'settings.startup' => 'Başlanğıc',
			'settings.display' => 'Ekran',
			'settings.libraryAndCards' => 'Kitabxana və kartlar',
			'settings.homeScreen' => 'Ana ekran',
			'settings.navigation' => 'Naviqasiya',
			'settings.window' => 'Pəncərə',
			'settings.liveTv' => 'Canlı TV',
			'settings.player' => 'Oynadıcı',
			'settings.videoAndDisplay' => 'Video və Ekran',
			'settings.audio' => 'Səs',
			'settings.quality' => 'Keyfiyyət',
			'settings.subtitles' => 'Altyazılar',
			'settings.seekAndTiming' => 'Sarğı və vaxt tənzimləməsi',
			'settings.behavior' => 'Davranış',
			'settings.gestures' => 'Jestlər',
			'settings.gestureBrightnessSwipe' => 'Parlaqlıq sürüşdürməsi',
			'settings.gestureBrightnessSwipeDescription' => 'Parlaqlığı tənzimləmək üçün sol kənarda yuxarı və ya aşağı sürüşdürün',
			'settings.gestureVolumeSwipe' => 'Səs sürüşdürməsi',
			'settings.gestureVolumeSwipeDescription' => 'Səsi tənzimləmək üçün sağ kənarda yuxarı və ya aşağı sürüşdürün',
			'settings.gesturePinchToZoom' => 'Çimdiklə yaxınlaşdır',
			'settings.gesturePinchToZoomDescription' => 'Yaxınlaşdırmaq və ya uzaqlaşdırmaq üçün videoda çimdik hərəkəti edin',
			'settings.gestureSeekSwipe' => 'Qəzaq Sivas',
			'settings.gestureSeekSwipeDescription' => 'Videoya baxmaq üçün sol və ya düz bir yer çalın; atlayın',
			'settings.rememberBrightnessLevel' => 'Parlaqlıq səviyyəsini xatırla',
			'settings.rememberBrightnessLevelDescription' => 'Oxutmanı son sürüşdürmə ilə təyin edilmiş parlaqlıqda başlat',
			'settings.controls' => 'İdarəetmələr',
			'settings.rememberPlayerChanges' => 'Pleyer dəyişikliklərini yadda saxla',
			'settings.rememberPlayerChangesDescription' => 'Oxutma zamanı edilən dəyişikliklərin harada saxlanacağı və yenidən tətbiq ediləcəyi',
			'settings.scopePlaybackSpeed' => 'Oxutma sürəti',
			'settings.scopeShaderPreset' => 'Şader ön ayarı',
			'settings.scopeAspectRatio' => 'Tərəf nisbəti',
			'settings.scopeSyncOffsets' => 'Audio və subtitr sinxronizasiyası',
			'settings.playerScopeOff' => 'Saxlama',
			'settings.playerScopeGlobal' => 'Hər yerdə',
			'settings.playerScopeLibrary' => 'Kitabxana üzrə',
			'settings.playerScopeTitle' => 'Serial və ya film üzrə',
			'settings.exportDialogTitle' => 'PlezyNG tənzimləmələrini ixrac et',
			'settings.followSystem' => 'Sistem dilini izləyin',
			'settings.followAppLanguage' => 'İnterfeys dili ilə eyni',
			'settings.regionFormat' => 'Regional formatlar',
			'settings.regionFormatDescription' => 'Tarixlərin, rəqəmlərin və ölçü vahidlərinin göstərilmə qaydasını seçin.',
			'settings.metadataLanguage' => 'Metaməlumat dili',
			'settings.metadataLanguageDescription' => 'Server dəstəklədikdə başlıqlar və təsvirlər üçün üstün tutulan dil. Səs və altyazı seçimləri ayrıca tənzimlənir.',
			'settings.enterFullscreenOnPlaybackStart' => 'Playback başladığı zaman Full Screen-a daxil olun',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Full-screen video oynamaq başladığı zaman açılır',
			'settings.extendVideoIntoDisplayCutout' => 'Görüntüləri ekranın qalığına genişletir',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Full-screen videonun Android telefonlarda kamera qızı kullanmasına izin verin',
			'settings.languageDescription' => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.',
			'settings.themeDescription' => 'Və, bu programda istifadə edilen renk və kontrast seçin.',
			'settings.libraryDensityDescription' => 'Hər bir kitabın sayını dəyişir.',
			'settings.displayScaleDescription' => 'Bu arayüz ekranının interfejsini, cihazın bütünüyle texti boyutunu dəyişmədən qaytarır.',
			'settings.themeSongVolumeDescription' => 'Sonraki YazıSonraki Şarkı SözleriSonrakı ŞarkılarSonraktaki Konuşma',
			'settings.viewModeDescription' => 'Kitabın elementləri bir ağda plakalar kimi və ya kompakt bir list olarak görünürünü seçin.',
			'settings.gridViewDescription' => 'Kütüphanə elementləri plakaların satırlarında və sütunlarında düzəltür.',
			'settings.listViewDescription' => 'Kitabın elementləri daha çox texti ilə vertikal bir listə görünür.',
			'settings.gridSpacingDescription' => 'Kütüphane ağlarında plakalar arasındaki boşluğu ayarlar.',
			'settings.gridSpacingTightDescription' => 'Daha çox plakalar ekranın üstündə daha az boşluklarla yerləşdirilir.',
			'settings.gridSpacingNormalDescription' => 'Standart plakalar arasındaki boşluğu istifadə edin.',
			'settings.gridSpacingSpaciousDescription' => 'Daha çox ayrılma üçün plakalar arasında daha böyük boşluklar ekləyin.',
			'settings.episodePosterModeDescription' => 'Qadınlar hangi filmdə aparılacağını seçin.',
			'settings.seriesPosterDescription' => 'Şovun hər seri posterini istifadə edin.',
			'settings.seasonPosterDescription' => 'Sezon posterini hər bir bölümdə istifadə edin.',
			'settings.episodeThumbnailDescription' => 'Bu bölümdə hazır olduğunda bir çerçevə istifadə edin.',
			'settings.continueWatchingActionDescription' => '“Gözlük” kartı aktivasiya etdiyinizdə nə olacağını seçin.',
			'settings.continueWatchingPlayDescription' => 'Filmi və ya epizodunu hemen başlatır.',
			'settings.continueWatchingDetailsDescription' => 'İlk dəfə başlık sayısını açın, bu yüzden ayrıntıları gözləyir və bir əməl seçirsiniz.',
			'settings.episodeActionDescription' => 'Bir epizod kartı aktivasiya etdiyinizdə nə olacağını seçin.',
			'settings.episodePlayDescription' => 'Bir neçə dəfə epizodı başlatır.',
			'settings.episodeDetailsDescription' => '“Playback”dan əvvəl bölüm sayısını açın.',
			'settings.contentScreensaverDelayDescription' => 'Artwork göstərmeden əvvəl PlezyNG nə qədər inşası olmadan gözləyir.',
			'settings.continueWatchingRowSizeDescription' => 'Qadınların kartlarının nə qədər böyük olduğunu seçin.',
			'settings.rowSizeCompactDescription' => 'Küçük kartları görünür ki, daha çox elementlər sıraya daxil olur.',
			'settings.rowSizeStandardDescription' => 'Standart kart boyutu istifadə edin.',
			'settings.rowSizeLargeDescription' => 'Daha geniş kartlar və daha çox artwork ayrıntıları ilə göstərilir.',
			'settings.visualEffectsDescription' => 'Bu cihazın animasyon və sanat efektləri bütçesini seçin.',
			'settings.visualEffectsFullDescription' => 'Artwork və animation efektləri hər bir cihazda istifadə edin.',
			'settings.startupSectionDescription' => 'Həyatın başladığı zaman hangi bölümü seçilir.',
			'settings.startupSectionOptions.discover' => 'Əvvəlki xəbərlər və məlumatlar bağlanmış qalıqlardan alınır.',
			'settings.startupSectionOptions.libraries' => 'Bağlantılı medya kütüphanalarını açın.',
			'settings.startupSectionOptions.liveTv' => 'Live TV-i bir serverin sağladığı zaman açılır; aksi takdirde start-up evə qayıtır.',
			'settings.startupSectionOptions.search' => 'Açıklama medya aralığı.',
			'settings.smallSkipDurationDescription' => 'Düşünürəm ki, bu yolda qısaltılma və geri qayıtılma yolları var.',
			'settings.largeSkipDurationDescription' => 'Düşünürəm ki, bu yolda uzun sürətlər və kontrollar yerləşdirilir.',
			'settings.rewindOnResumeDescription' => 'Videoya qayıtmaq üçün bu sayı ilə geri çəkilir.',
			'settings.defaultSleepTimerDescription' => 'İlk vaxtı başlamaq üçün istifadə etmək lazımdır.',
			'settings.playNextCountdownDescription' => 'Bir sonraki bölümə başlamadan əvvəl bu uzun müddət bekləyin.',
			'settings.autoSkipDelaySettingDescription' => 'Bu, bir intro, kredit və ya reklamın otomatik olarak atılması üçün ayarlandığı zaman geçer.',
			'settings.downmixCenterBoostDescription' => '“Stereo” kanalında, çevrimiçi sesin stereo-da karıştırıldığı zaman diyaloyu yüksəlir.',
			'settings.displaySwitchDelayDescription' => 'Görüntülər modunu dəyişmeden əvvəl televizyonun və ya alıcının önceki anahtarını tamamlayabilmesini gözləyin.',
			'settings.playerBackendDescription' => 'Bu cihazda hangi oyun motoru decod və render video seçin.',
			'settings.exoPlayerDescription' => 'Android\'in yerli Media3 bazlı oynatıcıları və destekli hardware yollarını istifadə edin.',
			'settings.mpvDescription' => 'MPV-i istifadə edin, bu da daha çox playback, subtitle və video işleme kontrolləri göstərir.',
			'settings.scopeOffDescription' => 'Şimdiki playback-session üçün dəyişənlər yalnız saxlayın.',
			'settings.scopeGlobalDescription' => 'Hər bir kütüphane və başlık için aynı değerini tekrar istifadə edin.',
			'settings.scopeLibraryDescription' => 'Hər bir kütüphane üçün ayrı bir değer alın.',
			'settings.scopeTitleDescription' => 'Hər bir filmdə və ya şovda ayrı bir sayı var.',
			'settings.specialsOrderingServerDescription' => 'Media server tərəfindən sağlanan epizod siparişini tutun.',
			'settings.specialsOrderingAirDateDescription' => '“Gözlük”da düzenli günlər arasında yerləşdirilir.',
			'settings.specialsOrderingLastDescription' => 'Hər biri normal sezondan sonra yerləşdirilir.',
			'settings.skipIntroModeDescription' => 'Intro markers normal oynayır, bir skip düğmesini göstərir və ya otomatik olarak skip.',
			'settings.skipCreditsModeDescription' => 'Kreditlər normal oynanır, bir skip düğmesini göstərər və ya otomatik olarak skip.',
			'settings.skipAdsModeDescription' => 'Görünən reklamların normal oynadığını, bir skip düğmesini göstərdiğini və ya otomatik olarak skip-i seçin.',
			'settings.playbackBufferAutoDescription' => 'Aktiv oyuncu normal buffer büyüklüğünü seçsin.',
			'settings.playbackBufferLargeDescription' => 'Daha çox medya hazır olun; bu, daha fazla hafızayı kullanır.',
			'settings.playbackBufferExtraLargeDescription' => 'Bu, ən böyük ok-ahead bufferini saxlayır; bu, en çox hafızayı kullanır.',
			'settings.defaultQualityDescription' => 'Video çözünürlüğünü ayarlayın və sunucu transcod olan akışlar için çatı bitrate.',
			'settings.cellularQualityDescription' => 'Bir cihazın yalnız hücresel bağ kullanıldığı zaman standart kaliteyi aşırır.',
			'settings.remoteQualityDescription' => 'Default Quality (Default Qalitəsi) ilə bir sunucuya bağlanırsa, uzaktan bağlanma yoluyla aşılır.',
			'settings.qualityPresetOriginalDescription' => 'Sunucuya sızdırmaq üçün sorğu olmadan mevcut kalitede kaynağı oynayın.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Sunucu, yukarıda göstərilmiş çözünürlüğünü və bitrateyi kullanarak dönüştürülmüş bir akış üçün soruşun.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Default Quality-da seçilmiş kaliteyi istifadə edin.',
			'settings.musicQualityDescription' => 'Servisdən istədiyiniz maksimum audio bitrate ayarlayın; Orijinal kaynak akışını tutar.',
			'settings.musicQualityOriginalDescription' => 'Bir bitrate-capped transcode olmadan kaynak audio oynayın.',
			'settings.musicQualityTranscodeOptionDescription' => 'Bir sunucu transkodu, yukarıda göstərilmiş bitrate yaxınında qapılmışdır; gerçek çıkış değişir.',
			'settings.maxVolumeInputLabel' => 'Maksimum sayı (% )',
			'settings.checkForUpdatesDescription' => 'İndi görmək olar ki, yeni bir versiyonu var.',
			'settings.appearanceDescription' => 'App teması seçin və kütüphane kartları, Ev satırlar və navigasiya ayarlayın.',
			'settings.prerollLibraryDescription' => 'Filmin hazırlığı kimi mevcut klipləri olan kütüphaneyi seçin.',
			'settings.prerollSelectionDescription' => 'Seçin ki, seçilmiş kütüphanadan hangi klipləri filmlər öncə oynayabilir.',
			'settings.contentScreensaverDelayOptionDescription' => 'Bu, ekranda aparılmadan əvvəl çox dakikalar bekləyin.',
			'settings.videoCodecOptionDescription' => 'Bu codec üçün doğrudan oynamaq sağlanır. kontrolsüz codeclar medya sunucu tarafından transkod edilir.',
			'themeEditor.builtIn' => 'Daxili',
			'themeEditor.presets' => 'Hazır mövzular',
			'themeEditor.custom' => 'Xüsusi',
			'themeEditor.customEmpty' => 'Hələ yaradılmayıb',
			'themeEditor.editCustom' => 'Xüsusi mövzuya düzəliş et',
			'themeEditor.editCustomDescription' => 'Bütün rəngləri özünüz seçin',
			'themeEditor.locked' => 'Ömür boyu qalıb',
			'themeEditor.savedLocked' => '“Gözəl” – ömür boyu qapı ilə',
			'themeEditor.title' => 'Xüsusi mövzu',
			'themeEditor.startFrom' => 'Başlanğıc mövzu',
			'themeEditor.startFromDescription' => 'Bütün rəngləri başqa mövzudan kopyala',
			'themeEditor.colors' => 'Rənglər',
			'themeEditor.preview' => 'Önizləmə',
			'themeEditor.slots.bg' => 'Arxa fon',
			'themeEditor.slots.surface' => 'Səth',
			'themeEditor.slots.outline' => 'Kontur',
			'themeEditor.slots.text' => 'Mətn',
			'themeEditor.slots.textMuted' => 'Köməkçi mətn',
			'themeEditor.slots.accent' => 'Vurğu',
			'themeEditor.opacity' => 'Şəffaflıq',
			'themeEditor.hexHint' => '#RRGGBB və ya #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Digər mövzulardan',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme}: ${color}',
			'themeEditor.contrast.textOnBg' => 'Arxa fonda mətn',
			'themeEditor.contrast.textOnSurface' => 'Səthdə mətn',
			'themeEditor.contrast.textMutedOnBg' => 'Arxa fonda köməkçi mətn',
			'themeEditor.contrast.textMutedOnSurface' => 'Səthdə köməkçi mətn',
			'themeEditor.contrast.accentOnBg' => 'Arxa fonda vurğu',
			'themeEditor.contrast.accentOnSurface' => 'Səthdə vurğu',
			'themeEditor.contrast.labelOnAccent' => 'Vurğu üzərində düymə mətni',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, tövsiyə olunan ${minimum}:1-dən aşağı',
			'themeEditor.discardTitle' => 'Dəyişikliklərdən imtina edilsin?',
			'themeEditor.discardMessage' => 'Yadda saxlanmamış rəng dəyişiklikləriniz itəcək.',
			'themeEditor.discard' => 'İmtina et',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Seriya ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} dəq qaldı',
			'themeEditor.previewSwitch' => 'Avtomatik oynatma',
			'themeEditor.previewMutedText' => 'Köməkçi mətn belə görünür',
			'themeEditor.themeSystemDescription' => 'Görünüşünüzü izləyin və aydınlıq və karanlık arasında avtomatik olarak dəyişin.',
			'themeEditor.themeLightDescription' => 'Siyah texti ilə aydınlı bir arkağı kullanın.',
			'themeEditor.themeDarkDescription' => 'Düşünür texti ilə karanlık bir tapınak kullanır.',
			'themeEditor.themeOledDescription' => 'Qısa-siyah yüzeyləri, OLED ekranlarda ışığı azaltmaq üçün istifadə edin.',
			'themeEditor.themeEmberDescription' => 'Sıcak kırmızı və amber axent rengi kullanın.',
			'themeEditor.themeGlacierDescription' => 'Qırmızı mavi axent rengi kullanın.',
			'themeEditor.themeForestDescription' => 'Doğal və yeşil renklər kullanılır.',
			'themeEditor.themePlumDescription' => 'Viyol və plum aksent rengi kullanın.',
			'themeEditor.themePaperDescription' => 'Əslində, bu sahədə və buğdaydan ilham alınmış renklər yerləşdirilir.',
			'themeEditor.themeCustomDescription' => 'O, özü üçün hazırladığınız temalar editöründən yaratdığınız renk paleti istifadə edin.',
			'themeEditor.editorDescription' => 'Bir palet rengi seçin, onun həkimini, tohumunu, parlaklığını və ya opacityini ayarlayın və ödəniş etmədən əvvəl öncə baxış güncəlisini görün.',
			'search.hint' => 'Kino, serial, musiqi axtar...',
			'search.tryDifferentTerm' => 'Fərqli axtarış sözü cəhd edin',
			'search.searchYourMedia' => 'Mediyanızda axtarın',
			'search.enterTitleActorOrKeyword' => 'Ad, aktyor və ya açar söz daxil edin',
			'search.people' => 'Şəxslər',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName} üçün qısayol təyin et',
			'hotkeys.clearShortcut' => 'Qısayolu təmizlə',
			'hotkeys.noShortcutSet' => 'Qısayol təyin edilməyib',
			'hotkeys.currentShortcut' => 'Cari qısayol:',
			'hotkeys.pressToRecord' => 'Qısayol yazmaq üçün seçin',
			'hotkeys.recordingShortcut' => 'İndi qısayol düymələrinə basın',
			'hotkeys.actions.playPause' => 'Oynat/Fasilə',
			'hotkeys.actions.volumeUp' => 'Səsi artır',
			'hotkeys.actions.volumeDown' => 'Səsi azalt',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'İrəli sar (${seconds}san)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Geri sar (${seconds}san)',
			'hotkeys.actions.fullscreenToggle' => 'Tam ekranı dəyişdir',
			'hotkeys.actions.muteToggle' => 'Səsi aç/bağla',
			'hotkeys.actions.subtitleToggle' => 'Altyazını aç/bağla',
			'hotkeys.actions.audioTrackNext' => 'Növbəti səs zolağı',
			'hotkeys.actions.subtitleTrackNext' => 'Növbəti altyazı zolağı',
			'hotkeys.actions.chapterNext' => 'Növbəti hissə',
			'hotkeys.actions.chapterPrevious' => 'Əvvəlki hissə',
			'hotkeys.actions.episodeNext' => 'Növbəti seriya',
			'hotkeys.actions.episodePrevious' => 'Əvvəlki seriya',
			'hotkeys.actions.speedIncrease' => 'Sürəti artır',
			'hotkeys.actions.speedDecrease' => 'Sürəti azalt',
			'hotkeys.actions.speedReset' => 'Sürəti sıfırla',
			'hotkeys.actions.zoomIn' => 'Yaxınlaşdır',
			'hotkeys.actions.zoomOut' => 'Uzaqlaşdır',
			'hotkeys.actions.zoomReset' => 'Miqyası sıfırla',
			'hotkeys.actions.subSeekNext' => 'Növbəti altyazıya sar',
			'hotkeys.actions.subSeekPrev' => 'Əvvəlki altyazıya sar',
			'hotkeys.actions.subtitleDelayIncrease' => 'Altyazını gecikdir',
			'hotkeys.actions.subtitleDelayDecrease' => 'Altyazını irəli çək',
			'hotkeys.actions.shaderToggle' => 'Şeyderləri aç/bağla',
			'hotkeys.actions.skipMarker' => 'Girişi/Titrləri ötür',
			'hotkeys.actions.screenshot' => 'Ekran şəkli çək',
			'hotkeys.actions.framePrevious' => 'Öncəki Frame',
			'hotkeys.actions.frameNext' => 'Sonraki Frame',
			'fileInfo.title' => 'Fayl məlumatı',
			'fileInfo.overview' => 'Ümumi baxış',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Səs',
			'fileInfo.subtitles' => 'Altyazılar',
			'fileInfo.images' => 'Daxili şəkillər',
			'fileInfo.dataStreams' => 'Məlumat axınları',
			'fileInfo.lyrics' => 'Mahnı sözləri',
			'fileInfo.file' => 'Fayl',
			'fileInfo.attachments' => 'Əlavələr',
			'fileInfo.delivery' => 'Çatdırılma',
			'fileInfo.versionCounter' => ({required Object count, required Object index}) => '${count}-dən ${index} versiya',
			'fileInfo.fileCounter' => ({required Object count, required Object index}) => '${count}-dən ${index} fayl',
			'fileInfo.noStreams' => 'Server bu fayl üçün heç bir axın bildirmədi.',
			'fileInfo.copyPath' => 'Yolu kopyala',
			'fileInfo.pathCopied' => 'Fayl yolu kopyalandı',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Kodek teqi',
			'fileInfo.resolution' => 'Ayırdetmə',
			'fileInfo.codedResolution' => 'Kodlanmış rezolyusiya',
			'fileInfo.bitrate' => 'Bit sürəti (Bitrate)',
			'fileInfo.frameRate' => 'Kadr tezliyi',
			'fileInfo.rotation' => 'Dönmə',
			'fileInfo.comment' => 'Şərh',
			'fileInfo.audioDescription' => 'Səs təsviri',
			'fileInfo.headerCompression' => 'Başlıq sıxışdırması',
			'fileInfo.sidecarFile' => 'Sidecar faylı',
			'fileInfo.transportTimestamp' => 'Transport vaxt damğası',
			'fileInfo.displayOffset' => 'Ekran ofseti',
			'fileInfo.previewFailureCode' => 'Önizləmə xəta kodu',
			'fileInfo.previewRetries' => 'Önizləmə cəhdləri',
			'fileInfo.aspectRatio' => 'Tərəf nisbəti',
			'fileInfo.pixelAspectRatio' => 'Piksel aspekt nisbəti',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Səviyyə',
			'fileInfo.bitDepth' => 'Bit dərinliyi',
			'fileInfo.pixelFormat' => 'Piksel formatı',
			'fileInfo.colorSpace' => 'Rəng sahəsi',
			'fileInfo.colorRange' => 'Rəng diapazonu',
			'fileInfo.colorPrimaries' => 'Əsas rənglər',
			'fileInfo.colorTransfer' => 'Rəng ötürməsi',
			'fileInfo.chromaSubsampling' => 'Rəng alt-diskretləşdirməsi',
			'fileInfo.chromaLocation' => 'Chroma mövqeyi',
			'fileInfo.scanType' => 'Tarama növü',
			'fileInfo.interlaced' => 'Sətirlərarası',
			'fileInfo.anamorphic' => 'Anamorfik',
			'fileInfo.referenceFrames' => 'İstinad kadrları',
			'fileInfo.dynamicRange' => 'Dinamik diapazon',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision səviyyəsi',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision versiyası',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision təbəqələri',
			'fileInfo.baseLayerCompatibility' => 'Baza təbəqə uyğunluğu',
			'fileInfo.avcBitstream' => 'AVC bit axını',
			'fileInfo.nalLengthSize' => 'NAL uzunluq ölçüsü',
			'fileInfo.scalingMatrix' => 'Xüsusi miqyaslama matrisi',
			'fileInfo.streamIdentifier' => 'Axın identifikatoru',
			'fileInfo.streamIndex' => 'Axın indeksi',
			'fileInfo.streamId' => 'Axın ID-si',
			'fileInfo.language' => 'Dil',
			'fileInfo.languageCode' => 'Dil kodu',
			'fileInfo.streamTitle' => 'Trek başlığı',
			'fileInfo.channels' => 'Kanallar',
			'fileInfo.sampleRate' => 'Diskretləşdirmə tezliyi',
			'fileInfo.spatialAudio' => 'Məkan səsi',
			'fileInfo.textBased' => 'Mətn əsaslı',
			'fileInfo.subtitleFormat' => 'Sidecar formatı',
			'fileInfo.provider' => 'Provayder',
			'fileInfo.matchScore' => 'Uyğunluq balı',
			'fileInfo.externalDelivery' => 'Ayrıca ötürülə bilər',
			'fileInfo.sidecarPath' => 'Sidecar yolu',
			'fileInfo.sourceStream' => 'Kopyalanan mənbə',
			'fileInfo.temporary' => 'Müvəqqəti',
			'fileInfo.timeBase' => 'Vaxt bazası',
			'fileInfo.overallBitrate' => 'Ümumi bit sürəti',
			'fileInfo.path' => 'Yol',
			'fileInfo.fileName' => 'Fayl adı',
			'fileInfo.size' => 'Həcm',
			'fileInfo.totalSize' => 'Ümumi ölçü',
			'fileInfo.container' => 'Konteyner',
			'fileInfo.duration' => 'Müddət',
			'fileInfo.previewThumbnails' => 'Önizləmə miniatürləri',
			'fileInfo.previewIndex' => 'Önizləmə indeksi',
			'fileInfo.packetLength' => 'Paket uzunluğu',
			'fileInfo.filePresent' => 'Fayl mövcuddur',
			'fileInfo.fileReadable' => 'Server tərəfindən oxuna bilir',
			'fileInfo.streamPath' => 'Axın yolu',
			'fileInfo.optimizedForStreaming' => 'Yayım üçün optimallaşdırılıb',
			'fileInfo.has64bitOffsets' => '64-bit ofsetlər',
			'fileInfo.protocol' => 'Protokol',
			'fileInfo.mediaType' => 'Media növü',
			'fileInfo.sourceKind' => 'Mənbə növü',
			'fileInfo.optimizedVersion' => 'Optimallaşdırılmış versiya',
			'fileInfo.optimizationTarget' => 'Optimallaşdırma hədəfi',
			'fileInfo.deletedAt' => 'Silinib',
			'fileInfo.remoteSource' => 'Uzaq mənbə',
			'fileInfo.infiniteStream' => 'Sonsuz axın',
			'fileInfo.directPlay' => 'Birbaşa oynatma',
			'fileInfo.directStream' => 'Birbaşa axın',
			'fileInfo.transcoding' => 'Yenidən kodlaşdırma',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Versiya ID-si',
			'fileInfo.fileId' => 'Fayl ID-si',
			'fileInfo.defaultAudioTrack' => 'Defolt səs treki',
			'fileInfo.defaultSubtitleTrack' => 'Defolt altyazı treki',
			'fileInfo.subtitlesOff' => 'Söndürülüb',
			'fileInfo.flagDefault' => 'Defolt',
			'fileInfo.flagForced' => 'Məcburi',
			'fileInfo.flagSelected' => 'Seçilib',
			'fileInfo.flagExternal' => 'Xarici',
			'fileInfo.flagHearingImpaired' => 'Eşitmə qüsurlu üçün',
			'fileInfo.flagDub' => 'Dublyaj',
			'fileInfo.flagOriginal' => 'Orijinal',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Baxıldı olaraq işarələ',
			'mediaMenu.markAsUnwatched' => 'Baxılmadı olaraq işarələ',
			'mediaMenu.removeFromContinueWatching' => 'İzləməyə davam et-dən sil',
			'mediaMenu.viewDetails' => 'Ətraflı bax',
			'mediaMenu.goToSeries' => 'Seriala keç',
			'mediaMenu.shufflePlay' => 'Qarışıq oynat',
			'mediaMenu.shuffleNotAvailableOffline' => 'Qarışıq oynatma oflayn rejimdə əlçatan deyil',
			'mediaMenu.fileInfo' => 'Fayl məlumatı',
			'mediaMenu.deleteEpisodeFromServer' => 'Seriyanı serverdən sil',
			'mediaMenu.deleteSeasonFromServer' => 'Mövsümü serverdən sil',
			'mediaMenu.deleteShowFromServer' => 'Serialı serverdən sil',
			'mediaMenu.deleteMovieFromServer' => 'Kinonu serverdən sil',
			'mediaMenu.deleteEpisodeTitle' => 'Bu seriya silinsin?',
			'mediaMenu.deleteSeasonTitle' => 'Bu mövsüm silinsin?',
			'mediaMenu.deleteShowTitle' => 'Bu serial silinsin?',
			'mediaMenu.deleteMovieTitle' => 'Bu kino silinsin?',
			'mediaMenu.deleteEpisodeConfirm' => 'Seriyanı sil',
			'mediaMenu.deleteSeasonConfirm' => 'Mövsümü sil',
			'mediaMenu.deleteShowConfirm' => 'Serialı sil',
			'mediaMenu.deleteMovieConfirm' => 'Kinonu sil',
			'mediaMenu.deleteAnyway' => 'Yenə də sil',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '${title} serverinizdən birdəfəlik silinsin?',
			'mediaMenu.deleteMultipleWarning' => 'Bu bütün seriyaları və faylları əhatə edir.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Bu, içindəki ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriyanı və onun faylını siləcək.', other: 'Bu, içindəki ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriyanı və onların fayllarını siləcək.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fayl kimi saxlanılır və o silinəcək.', other: 'Bu element ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faylda saxlanılır və hamısı silinəcək.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Eyni faylda saxlanılan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başqa seriya da silinəcək:', other: 'Eyni faylda saxlanılan ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başqa seriya da silinəcək:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG bunun hansı faylları siləcəyini yoxlaya bilmədi, ona görə də yuxarıda adı çəkilən elementdən daha çoxunu silə bilər. Ləğv edib təzədən cəhd edin və ya yenə də silin.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Serveriniz bu element üçün fayl təfərrüatlarını təqdim etmədi, ona görə PlezyNG bunun hansı faylları siləcəyini yoxlaya bilmir. Yuxarıda adı çəkilən elementdən daha çoxunu silə bilər.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media elementi uğurla silindi',
			'mediaMenu.mediaFailedToDelete' => 'Media elementi silinə bilmədi',
			'mediaMenu.rate' => 'Qiymətləndir',
			'mediaMenu.playFromBeginning' => 'Əvvəldən oynat',
			'mediaMenu.playVersion' => 'Versiyanı oynat...',
			'rateSheet.title' => 'Qiymətləndir',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Sevimli',
			'rateSheet.favorited' => 'Sevimlilərə əlavə edildi',
			'rateSheet.saved' => 'Yadda saxlanıldı',
			'rateSheet.notAvailable' => 'Uyğunluq tapılmadı',
			'rateSheet.noConnectedServices' => 'Orada qiymətləndirmək üçün Tənzimləmələrdən xidmət qoşun.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, kino',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV şou',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'baxılıb',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '%${percent} baxılıb',
			'accessibility.mediaCardUnwatched' => 'baxılmayıb',
			'accessibility.tapToPlay' => 'Oynatmaq üçün toxunun',
			'accessibility.decrease' => 'Azalt',
			'accessibility.increase' => 'Artır',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} dəyərini azalt',
			'accessibility.increaseValue' => ({required Object label}) => '${label} dəyərini artır',
			'accessibility.hue' => 'Rəng çaları',
			'accessibility.saturation' => 'Doyğunluq',
			'accessibility.brightness' => 'Parlaqlıq',
			'accessibility.hexColor' => 'Hex rəngi',
			'accessibility.expandText' => 'Mətni genişləndir',
			'accessibility.collapseText' => 'Mətni yığ',
			'accessibility.alphabetNavigation' => 'Əlifba naviqasiyası',
			'accessibility.alphabetScrollHint' => 'Hərflərə görə keçmək üçün yuxarı və ya aşağı sürüşdürün',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Sətir ${row} / ${rowCount}, sütun ${column} / ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Sətir ${row} / ${rowCount}',
			'accessibility.autoScrollPlay' => 'Avtomatik sürüşdürməni başlat',
			'accessibility.autoScrollPause' => 'Avtomatik sürüşdürməyə fasilə ver',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Kırmızı',
			'accessibility.green' => 'Yeşil',
			'accessibility.blue' => 'Mavi',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'XƏBƏL',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Aksesibillıq',
			'accessibility.summary' => 'Text, kontrast, Movement və Control',
			'accessibility.systemHint' => 'Bu seçeneklər PlezyNG ilə bağlı ayarları daha çox artırır.',
			'accessibility.readability' => 'Görünürlük və baxış',
			'accessibility.textSize' => 'Tekstil boyutu',
			'accessibility.preview' => 'Next story Özünüzə bax, dinlə və izləyin',
			'accessibility.boldText' => 'İyilikçi interfejs',
			'accessibility.highContrast' => 'Kontrastın böyük',
			'accessibility.highContrastHint' => 'Daha çox texti, tez-tez və qısıl və ya aydın yüzeylər üzerinde odak göstergeleri.',
			'accessibility.interaction' => 'Movsiya və interaksiya',
			'accessibility.reduceMotion' => 'Movqeyi azaltır',
			'accessibility.reduceMotionHint' => 'Fokus göstəricisinin hərəkətini, səhifə keçidlərini və dekorativ effektləri dayandırın.',
			'accessibility.largeTargets' => 'Təkimlər daha çox',
			'accessibility.largeTargetsHint' => '“Müşən” komandaları daha çox touch və asistivi navigasiya üçün yer verir.',
			'accessibility.navigationHint' => 'İdarəetmə elementləri arasında keçmək üçün Tab və Shift+Tab, aktivləşdirmək üçün Enter və ya Boşluq, bağlamaq üçün Escape və ya Geri düyməsindən istifadə edin. Kitab açıq olduqda böyütmə və oxu tənzimləmələri əlçatandır.',
			'accessibility.textSizeDescription' => 'VVD-nin textiyi, sistemin texti-büyüklüğü ayarının yanı sıra PlezyNG-də ölçülür.',
			'accessibility.boldTextHint' => 'İnternet etiketləri və mesajları üçün daha ağır bir ağırlık kullanın ki, onları ayırt etmək kolaydır.',
			'tooltips.shufflePlay' => 'Qarışıq oynat',
			'tooltips.playTrailer' => 'Treyleri oynat',
			'tooltips.markAsWatched' => 'Baxıldı olaraq işarələ',
			'tooltips.markAsUnwatched' => 'Baxılmadı olaraq işarələ',
			'audioTracks.track' => ({required Object n}) => 'Səs zolağı ${n}',
			'videoControls.audioLabel' => 'Səs',
			'videoControls.subtitlesLabel' => 'Altyazı',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Geniş ekran (Letterbox)',
			'videoControls.fillScreen' => 'Ekrana doldur',
			'videoControls.stretch' => 'Gərmək',
			'videoControls.lockRotation' => 'Dönməni kilidlə',
			'videoControls.unlockRotation' => 'Dönmə kilidini aç',
			'videoControls.timerActive' => 'Taymer aktivdir',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Oynatma ${duration} sonra fasilə olunacaq',
			'videoControls.sleepTimerEndOfVideo' => 'Cari videonun sonu',
			'videoControls.sleepTimerStopAtHeader' => 'Dayanma vaxtı',
			'videoControls.sleepTimerDurationHeader' => 'Taymer',
			'videoControls.playbackWillPauseAtEnd' => 'Oynatma bu videonun sonunda fasilə olunacaq',
			'videoControls.stillWatching' => 'Hələ də baxırsınız?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}san sonra fasilə edilir',
			'videoControls.continueWatching' => 'Davam et',
			'videoControls.autoPlayNext' => 'Növbətini avtomatik oynat',
			'videoControls.playNext' => 'Növbətini oynat',
			'videoControls.playButton' => 'Oynat',
			'videoControls.pauseButton' => 'Fasilə',
			'videoControls.playbackPaused' => 'Fasilədə',
			'videoControls.playbackResumed' => 'Oynadılır',
			'videoControls.loadingVideo' => 'Video yüklənir',
			'videoControls.showPlaybackControls' => 'Oynatma idarəetmələrini göstər',
			'videoControls.hidePlaybackControls' => 'Oynatma idarəetmələrini gizlət',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} saniyə geri sar',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} saniyə irəli sar',
			'videoControls.previousButton' => 'Əvvəlki seriya',
			'videoControls.nextButton' => 'Növbəti seriya',
			'videoControls.previousChapterButton' => 'Əvvəlki hissə',
			'videoControls.nextChapterButton' => 'Növbəti hissə',
			'videoControls.muteButton' => 'Səsi söndür',
			'videoControls.unmuteButton' => 'Səsi aç',
			'videoControls.settingsButton' => 'Oynatma tənzimləmələri',
			'videoControls.tracksButton' => 'Səs və Altyazılar',
			'videoControls.chaptersButton' => 'Hissələr',
			'videoControls.segmentLoopHelp' => 'Bu oxutma zamanı bir bölməni təkrarlayın. Əvvəl A-nı, sonra zaman xəttində daha sonrakı nöqtədə B-ni təyin edin.',
			'videoControls.setLoopStart' => 'Təkrarın başlanğıcını təyin et (A)',
			'videoControls.setLoopEnd' => 'Təkrarın sonunu təyin et (B)',
			'videoControls.clearSegmentLoop' => 'Bölmə təkrarını sil',
			'videoControls.setLoopStartFirst' => 'Əvvəl təkrarın başlanğıcını (A), sonra sonunu (B) təyin edin.',
			'videoControls.loopEndAfterStart' => 'Təkrarın sonu başlanğıcdan sonra olmalıdır.',
			'videoControls.segmentLoopUnavailable' => 'Bu oxutma üçün bölmə təkrarı mövcud deyil.',
			'videoControls.loopPointNotSet' => 'Təyin edilməyib',
			'videoControls.bookmarksHelp' => 'Əlfəcinlər bu cihazda saxlanılır. Həmin vaxta keçmək üçün birini seçin.',
			'videoControls.bookmarksButton' => 'Əlfəcinlər',
			'videoControls.chaptersAndBookmarks' => 'Fəsillər və əlfəcinlər',
			'videoControls.segmentLoop' => 'Bölmə təkrarı',
			'videoControls.addBookmark' => 'Əlfəcin əlavə et',
			'videoControls.bookmarkName' => 'Əlfəcin adı',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'Məsələn, açılış səhnəsi',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Əlfəcin ${n}',
			'videoControls.bookmarkNameRequired' => 'Bu əlfəcin üçün ad daxil edin.',
			'videoControls.deleteBookmark' => 'Əlfəcini sil',
			'videoControls.bookmarkLimitReached' => 'Bu elementdə artıq 100 əlfəcin var.',
			'videoControls.bookmarkUnavailable' => 'Bu əlfəcini saxlamaq və ya silmək mümkün olmadı.',
			'videoControls.bookmarkSaved' => 'Əlfəcin saxlanıldı.',
			'videoControls.bookmarkDeleted' => 'Əlfəcin silindi.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => '${point} təkrar nöqtəsi ${time} vaxtında təyin edildi.',
			'videoControls.noChaptersOrBookmarks' => 'Fəsil və ya əlfəcin yoxdur.',
			'videoControls.versionQualityButton' => 'Versiya və Keyfiyyət',
			'videoControls.versionColumnHeader' => 'Versiya',
			'videoControls.qualityColumnHeader' => 'Keyfiyyət',
			'videoControls.qualityOriginal' => 'Orijinal',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Kod dəyişmə əlçatan deyil — orijinal keyfiyyətdə oynadılır',
			'videoControls.subtitleUnavailableFallback' => 'Seçilmiş altyazı yüklənə bilmədi — altyazısız davam edilir',
			'videoControls.pipButton' => 'Pəncərə daxilində pəncərə rejimi',
			'videoControls.aspectRatioButton' => 'Tərəf nisbəti',
			'videoControls.ambientLighting' => 'Ətraf işıqlandırması',
			'videoControls.fullscreenButton' => 'Tam ekrana keç',
			'videoControls.exitFullscreenButton' => 'Tam ekrandan çıx',
			'videoControls.alwaysOnTopButton' => 'Həmişə üstə',
			'videoControls.rotationLockButton' => 'Dönmə kilidi',
			'videoControls.lockScreen' => 'Ekranı kilidlə',
			'videoControls.screenLockButton' => 'Ekran kilidi',
			'videoControls.timelineSlider' => 'Video zaman çubuğu',
			'videoControls.volumeSlider' => 'Səs səviyyəsi',
			'videoControls.endsAt' => ({required Object time}) => 'Bitiş vaxtı: ${time}',
			'videoControls.pipActive' => 'Pəncərə daxilində pəncərə rejimində oynadılır',
			'videoControls.pipFailed' => 'PiP rejimi başladılarkən xəta',
			'videoControls.screenshotSaved' => 'Ekran şəkli yadda saxlanıldı',
			'videoControls.screenshotFailed' => 'Ekran şəkli çəkilə bilmədi',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Miqyas %${percent}',
			'videoControls.volumePercent' => ({required Object percent}) => 'Səs ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 və ya daha yenisini tələb edir',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 və ya daha yenisini tələb edir',
			'videoControls.pipErrors.permissionDisabled' => 'PiP rejimi söndürülüb. Sistem tənzimləmələrindən aktivləşdirin.',
			'videoControls.pipErrors.notSupported' => 'Cihaz PiP rejimini dəstəkləmir',
			'videoControls.pipErrors.voSwitchFailed' => 'PiP üçün video çıxışı dəyişdirilə bilmədi',
			'videoControls.pipErrors.failed' => 'PiP rejimi başladılarkən xəta',
			'videoControls.pipErrors.prepareFailed' => 'PiP rejimi hazırlana bilmədi',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Xəta baş verdi: ${error}',
			'videoControls.chapters' => 'Hissələr',
			'videoControls.noChaptersAvailable' => 'Hissələr əlçatan deyil',
			'videoControls.queue' => 'Növbə',
			'videoControls.noQueueItems' => 'Növbədə element yoxdur',
			'videoControls.noAudioDevicesAvailable' => 'Səs cihazları əlçatan deyil',
			'videoControls.searchSubtitles' => 'Altyazı axtar',
			'videoControls.language' => 'Dil',
			'videoControls.noSubtitlesFound' => 'Altyazı tapılmadı',
			'videoControls.subtitleDownloaded' => 'Altyazı yükləndi',
			'videoControls.subtitleDownloadedNotApplied' => 'Altyazı yükləndi, lakin seçilə bilmədi',
			'videoControls.subtitleDownloadFailed' => 'Altyazı yüklənə bilmədi',
			'videoControls.searchLanguages' => 'Dillərdə axtar...',
			'videoControls.skipIntro' => 'Girişi keç',
			'videoControls.skipCredits' => 'Titrləri keç',
			'videoControls.nextEpisode' => 'Növbəti seriya',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Zolaq ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Altyazı ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Məcburi)',
			'videoControls.osdSubtitlesOff' => 'Altyazı: Söndürülüb',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Altyazı: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Səs: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qalıb', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} qəlblər', ), 
			'videoControls.trackSelectionTitle' => 'Playback öncə oyun seçin',
			'videoControls.trackSelectionAuto' => 'Automatik seçim',
			'videoControls.openMiniPlayer' => 'Mini oyunçı',
			'videoControls.returnToFullPlayer' => 'Full oyuncuya qayıtmaq',
			'videoControls.loadSubtitleFile' => 'Subtitle filə yükləmək.',
			'videoControls.subtitleLoadFailed' => 'Subtitle filini yüklə bilmədim',
			'videoControls.skipAds' => 'Adlar üçün',
			'videoControls.tapToUnlock' => 'Kilidi açmaq üçün toxunun',
			'videoControls.tapAgainToUnlock' => 'Kilidi açmaq üçün yenidən toxunun',
			'messages.markedAsWatched' => 'Baxıldı olaraq işarələndi',
			'messages.markedAsUnwatched' => 'Baxılmadı olaraq işarələndi',
			'messages.markedAsWatchedOffline' => 'Baxıldı olaraq işarələndi (onlayn olduqda eyniləşdiriləcək)',
			'messages.markedAsUnwatchedOffline' => 'Baxılmadı olaraq işarələndi (onlayn olduqda eyniləşdiriləcək)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Avtomatik silindi: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Baxılmış ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yükləmə avtomatik silindi', other: 'Baxılmış ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} yükləmə avtomatik silindi', ), 
			'messages.removedFromContinueWatching' => 'İzləməyə davam et-dən silindi',
			'messages.errorLoading' => ({required Object error}) => 'Xəta: ${error}',
			'messages.searchPartialResults' => 'Bəzi media serverlərində axtarış aparıla bilmədi. Mövcud nəticələr göstərilir.',
			'messages.streamInterrupted' => 'Yayım kəsildi. Yenidən cəhd etmək üçün oynat düyməsinə basın və ya irəli-geri çəkin.',
			'messages.liveStreamInterrupted' => 'Canlı yayım kəsildi. Təzədən cəhd etmək üçün oynat düyməsinə basın.',
			'messages.fileInfoNotAvailable' => 'Fayl məlumatı əlçatan deyil',
			'messages.playbackAuthenticationRequired' => 'Bu elementi oynatmaq üçün media serverinə yenidən daxil olun.',
			'messages.playbackServerUnavailable' => 'Media serveri əlçatan deyil. Sonra təzədən cəhd edin.',
			'messages.playbackDataInvalid' => 'Server yanlış oynatma məlumatı qaytardı.',
			'messages.playbackCancelled' => 'Oynatma ləğv edildi.',
			'messages.playbackFailed' => 'Oynatma başladılarkən xəta.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Oynatma başladıla bilmədi: ${error}',
			'messages.audioOutputFailed' => 'Səs çıxışı cavab verməyi dayandırdı. TV və ya resiverin səs bağlantısını yoxlayın; başqa tətbiqlərdə də səs yoxdursa, cihazı yenidən başladın.',
			'messages.mediaUnavailable' => 'Bu məzmun artıq əlçatan deyil.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fayl məlumatı yüklənərkən xəta: ${error}',
			'messages.errorLoadingSeries' => 'Serial yüklənərkən xəta',
			'messages.musicNotSupported' => 'Musiqi oynatması hələ dəstəklənmir',
			'messages.noDescriptionAvailable' => 'Təsvir əlçatan deyil',
			'messages.noProfilesAvailable' => 'Profil yoxdur',
			'messages.contactAdminForProfiles' => 'Profil əlavə etmək üçün server inzibatçınızla əlaqə saxlayın',
			'messages.unableToDetermineLibrarySection' => 'Bu element üçün kitabxana bölməsi müəyyən edilə bilmədi',
			'messages.logsCleared' => 'Jurnallar təmizləndi',
			'messages.logsCopied' => 'Jurnallar buferə kopyalandı',
			'messages.noLogsAvailable' => 'Jurnal yoxdur',
			'messages.libraryScanning' => ({required Object title}) => '"${title}" skan edilir...',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}" üçün skan başladı',
			'messages.libraryScanFailed' => ({required Object error}) => 'Kitabxana skan edilə bilmədi: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}" üçün meta-məlumatlar yenilənir...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}" üçün meta-məlumat yenilənməsi başladı',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Meta-məlumatlar yenilənə bilmədi: ${error}',
			'messages.logoutConfirm' => 'Çıxış etmək istədiyinizdən əminsiniz?',
			'messages.noSeasonsFound' => 'Mövsüm tapılmadı',
			'messages.seasonsLoadFailed' => 'Mövsümlər yüklənə bilmədi',
			'messages.noEpisodesFound' => 'Birinci mövsümdə seriya tapılmadı',
			'messages.noEpisodesFoundGeneral' => 'Seriya tapılmadı',
			'messages.episodesLoadFailed' => 'Seriyalar yüklənə bilmədi',
			'messages.noResultsFound' => 'Nəticə tapılmadı',
			'messages.sleepTimerSet' => ({required Object label}) => 'Yuxu taymeri ${label} üçün təyin edildi',
			'messages.noItemsAvailable' => 'Element yoxdur',
			'messages.failedToCreatePlayQueueNoItems' => 'Oynatma növbəsi yaradıla bilmədi — element yoxdur',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action} uğursuz oldu: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Uyğun oynadıcıya keçilir...',
			'messages.serverLimitTitle' => 'Oynatma uğursuz oldu',
			'messages.serverLimitBody' => 'Server xətası (HTTP 500). Məhdudiyyət bu seansı rədd etdi.',
			'messages.mediaUnreadableTitle' => 'Fayl əlçatan deyil',
			'messages.mediaUnreadableBody' => 'Server bu elementi tapdı, lakin onun faylını oxuya bilmədi (HTTP 404). Fayl yəqin ki, köçürülüb, silinib və ya onun saxlanma yeri oflayndır. Server sahibindən faylı yoxlamasını və kitabxananı yenidən skan etməsini xahiş edin.',
			'messages.serverBusyTitle' => 'Yayım əlçatan deyil',
			'messages.serverBusyBody' => 'Server bu faylı yayımlamaqdan dəfələrlə imtina etdi (HTTP 503). Server yenidən başladılır və ya məşğul ola bilər, yaxud faylın yerləşdiyi yaddaş oflayn ola bilər. Bir az sonra təzədən cəhd edin — problem davam edərsə, server sahibindən serveri və faylın yerləşdiyi yaddaşı yoxlamasını istəyin.',
			'messages.playbackNotAllowedTitle' => 'Oynatmaya icazə verilmir',
			'messages.playbackNotAllowedBody' => 'Server bu elementi yayımlamaqdan imtina etdi (HTTP 403). Hesabınızın onu oynatmaq icazəsi olmaya bilər, yaxud server oynatmaya yalnız öz yerli şəbəkəsində icazə verə bilər.',
			'messages.logsUploaded' => 'Jurnallar yükləndi',
			'messages.logsUploadFailed' => 'Jurnallar yüklənə bilmədi',
			'messages.logId' => 'Jurnal ID-si',
			'messages.burnedSubtitlesUseMenu' => 'Altyazılar bu yayıma həkk edilib. Onları altyazı menyusundan dəyişin.',
			'messages.noVideoUrl' => 'Video URL-i mövcud deyil',
			'messages.playbackNoMediaSources' => 'Server oynadıla bilən media mənbəyi qaytarmadı',
			'messages.playbackDataNotPrepared' => 'Məlumatları hazır olmadan oynatma başladıldı',
			'messages.streamSelectionUnavailable' => 'Bu mənbə üçün yayım seçimi mövcud deyil',
			'messages.streamSelectionFailed' => 'Seçilmiş yayımları tətbiq etmək olmadı',
			'messages.trackSelectionNotRemembered' => 'Bu trek seçimi yalnız cari oynatmaya tətbiq olunur.',
			'messages.serverUnavailableForProfile' => 'Aktiv profil üçün heç bir server mövcud deyil',
			'subtitlingStyling.previewSample' => 'Cəld qəhvəyi tülkü tənbəl itin üstündən tullanır.',
			'subtitlingStyling.text' => 'Mətn',
			'subtitlingStyling.border' => 'Haşiyə',
			'subtitlingStyling.background' => 'Arxa fon',
			'subtitlingStyling.fontSize' => 'Şrift ölçüsü',
			'subtitlingStyling.textColor' => 'Mətn rəngi',
			'subtitlingStyling.borderSize' => 'Haşiyə ölçüsü',
			'subtitlingStyling.borderColor' => 'Haşiyə rəngi',
			'subtitlingStyling.backgroundOpacity' => 'Arxa fon şəffaflığı',
			'subtitlingStyling.backgroundColor' => 'Arxa fon rəngi',
			'subtitlingStyling.position' => 'Mövqe',
			'subtitlingStyling.assOverride' => 'ASS ləğvi',
			'subtitlingStyling.overrideScale' => 'Miqyasla',
			'subtitlingStyling.overrideForce' => 'Məcburi et',
			'subtitlingStyling.overrideStrip' => 'Formatlaşdırmanı sil',
			'subtitlingStyling.positionTop' => 'Yuxarı',
			'subtitlingStyling.positionBottom' => 'Aşağı',
			'subtitlingStyling.useMargins' => 'Kənar boşluqlardan istifadə et',
			'subtitlingStyling.useMarginsDescription' => 'Mətn altyazılarına videodan kənar sahədə icazə ver. Üslublu altyazılar öz orijinal yerləşməsini saxlaya bilər.',
			'subtitlingStyling.anchorToScreen' => 'Ekrana bərkit',
			'subtitlingStyling.anchorToScreenDescription' => 'Mətn altyazılarını geniş ekranlı videonun altındakı qara zolaqlarda göstər',
			'subtitlingStyling.bold' => 'Qalın',
			'subtitlingStyling.italic' => 'Kursiv',
			'subtitlingStyling.renderResolution' => 'Emal imkanı (Resolution)',
			'subtitlingStyling.renderResolutionScreen' => 'Ekran imkanı',
			'subtitlingStyling.renderResolutionVideo' => 'Video imkanı',
			'subtitlingStyling.fontSizeDescription' => 'Subtitle texti boyutu bu cihazda ayarlayın.',
			'subtitlingStyling.textColorDescription' => 'Subtitle texti üçün kullanılan renk seçin.',
			'subtitlingStyling.borderSizeDescription' => 'Subtitle texti ilə çevrilər.',
			'subtitlingStyling.borderColorDescription' => 'Subtitle üçün kullanılan renk seçin.',
			'subtitlingStyling.backgroundColorDescription' => 'Subtitle texti arkasındaki rengi seçin.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Subtitle aralığının nə qədər şifrəsi olduğunu ayarlayın: 0% açıq və 100% sabitdir.',
			'subtitlingStyling.positionDescription' => 'Yüzde 0 - videonun üstində və % 100 - altındadır.',
			'subtitlingStyling.assOverrideDescription' => 'Oynayan oyuncu, düzeltmək, değiştirmək və ya ASS subtitlularına yerleştirilmiş stilini kaldırmaq üçün seçin.',
			'subtitlingStyling.assOverrideOptions.no' => 'Fırtınalar, renkler, boyutlar və yerleşim dosyada yazılmış tutun.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Subtitle stil ayarlarını ASS subtitlləri düzeltmək üçün izin verin.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Oyuncu stilini və video boyutlarını ayarlaymaq üçün yerleşik ölçümləri ölçün.',
			'subtitlingStyling.assOverrideOptions.force' => 'Xatırılan ASS stillarını oyuncu subtitrinin stili ilə dəyişir.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Düşünürəm ki, bu formatı düzgün bir biçimdir.',
			'subtitlingStyling.renderResolutionDescription' => 'Görüntüyü və ASS subtitlesini rasterize etmək üçün kullanılan çözünürlüğünü seçin. Düşük Android ölçeği rendering çalışmasını azalta bilər, amma daha yumuşak görünür.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Əslində, ən yaxşı nəticə üçün tam ekran yüzey çözünürlüğüne qaytarılır.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Video çözünürlüğünü referans olarak kullanır, bu da yüksek çözünənlik ekranlarında çalışmayı azaltır.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Yüzünün 75-dəki ekranın yüzey çözünürlüğüne düşüş, müsahib performans tasarrufu üçün.',
			'subtitlingStyling.renderResolutionOptions.half' => '50 % ekranın yüzey çözünürlüğünü, işini azaltmaq üçün, yumuşak kenarlarla bağlayır.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Üçte biri ekranın yüzey çözünürlüğünün üçte birində çalışmayı azaltmaq üçün, yumuşak kenarlarla.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Üçüncü çeyrek ekran yüzey çözünürlüğünün üçün, işini azaltmaq üçün, ən yumuşak sonuca var.',
			'subtitlingStyling.boldDescription' => 'Subtitle texti daha ağır bir ağırlıqda çəkilir.',
			'subtitlingStyling.italicDescription' => 'İtaliqdə yazılan subtitr texti.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Təkmilləşdirilmiş video oynatıcı tənzimləmələri',
			'mpvConfig.presets' => 'Ön ayarlar',
			'mpvConfig.noPresets' => 'Yadda saxlanılmış ön ayar yoxdur',
			'mpvConfig.saveAsPreset' => 'Ön ayar kimi yadda saxla...',
			'mpvConfig.presetName' => 'Ön ayar adı',
			'mpvConfig.presetNameHint' => 'Bu ön ayar üçün ad daxil edin',
			'mpvConfig.loadPreset' => 'Yüklə',
			'mpvConfig.deletePreset' => 'Sil',
			'mpvConfig.presetSaved' => 'Ön ayar yadda saxlanıldı',
			'mpvConfig.presetLoaded' => 'Ön ayar yükləndi',
			'mpvConfig.presetDeleted' => 'Ön ayar silindi',
			'mpvConfig.confirmDeletePreset' => 'Bu ön ayarı silmək istədiyinizə əminsiniz?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# şərh',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Sətir əlavə et',
			'mpvConfig.removeLine' => 'Sətiri sil',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context və gpu-api Linux-da nəzərə alınmır: daxili video həmişə video müstəvisində vo=libmpv vasitəsilə göstərilir və gpu-next (ArtCNN kimi hesablama şeyderlərinə lazımdır) daxili işləyə bilməz.',
			'dialog.confirmAction' => 'Əməliyyatı təsdiqlə',
			'profiles.addPlezyProfile' => 'PlezyNG profili əlavə et',
			'profiles.switchingProfile' => 'Profil dəyişdirilir…',
			'profiles.deleteThisProfileTitle' => 'Bu profil silinsin?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} silinəcək. Qoşulmalar təsirlənmir.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'İdarə et',
			'profiles.delete' => 'Sil',
			'profiles.signOut' => 'Çıxış et',
			'profiles.signOutPlexTitle' => 'Plex-dən çıxılsın?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} və bütün Plex Home istifadəçiləri silinsin? İstənilən vaxt yenidən daxil ola bilərsiniz.',
			'profiles.signOutPlexDeleteDownloads' => 'Yükləmələri də sil',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Əks halda onlar bu cihazda qalır və bu hesaba yenidən daxil olduqda geri qayıdır.',
			'profiles.signedOutPlex' => 'Plex-dən çıxıldı.',
			'profiles.signOutFailed' => 'Çıxış uğursuz oldu.',
			'profiles.sectionTitle' => 'Profillər',
			'profiles.summarySingle' => 'İdarə olunan istifadəçiləri və yerli kimlikləri qarışdırmaq üçün profillər əlavə edin',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profil · aktiv: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profil',
			'profiles.removeConnectionTitle' => 'Qoşulma silinsin?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName} istifadəçisinin ${connectionLabel} giriş hüququ silinəcək. Digər profillərdə qalacaq.',
			'profiles.deleteProfileTitle' => 'Profil silinsin?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} və onun qoşulmaları silinəcək. Serverlər əlçatan qalır.',
			'profiles.profileNameLabel' => 'Profil adı',
			'profiles.pinProtectionLabel' => 'PIN mühafizəsi',
			'profiles.copyAutomationLink' => 'Android avtomatizasiya bağlantısı',
			'profiles.copyAutomationLinkDescription' => 'Bu profili Android və ya avtomatizasiyadan seçin.Profil PIN kontrolları hala geçerlidir.',
			'profiles.automationLinkCopied' => 'Profile avtomatizasiyası kopyalanır.',
			'profiles.pinManagedByPlex' => 'PIN Plex tərəfindən idarə olunur. plex.tv-də düzəliş edin.',
			'profiles.noPinSetEditOnPlex' => 'PIN təyin edilməyib. Tələb etmək üçün plex.tv-də düzəliş edin.',
			'profiles.setPin' => 'PIN təyin et',
			'profiles.setPinTitle' => 'PIN təyin et',
			'profiles.confirmPinTitle' => 'PIN-i təsdiqlə',
			'profiles.pinSet' => 'PIN təyin edildi',
			'profiles.changePin' => 'Dəyişdir',
			'profiles.removePin' => 'Sil',
			'profiles.connectionsLabel' => 'Qoşulmalar',
			'profiles.add' => 'Əlavə et',
			'profiles.deleteProfileButton' => 'Profili sil',
			'profiles.noConnectionsHint' => 'Qoşulma yoxdur — bu profili istifadə etmək üçün birini əlavə edin.',
			'profiles.noConnections' => 'Qoşulma yoxdur',
			'profiles.plexHomeAccount' => 'Plex Ev hesabı',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex hesabı: ${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account} hesabı vasitəsilə ${user}',
			'profiles.connectionDefault' => 'Defolt',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName} olaraq',
			'profiles.makeDefault' => 'Defolt et',
			'profiles.removeConnection' => 'Sil',
			'profiles.profileRenamed' => 'Profil adı dəyişdirildi.',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName} profilinə əlavə et',
			'profiles.borrowExplain' => 'Başqa profilin qoşulmasını istifadə edin. PIN ilə qorunan profillər PIN tələb edir.',
			'profiles.borrowEmpty' => 'Hələ istifadə ediləcək bir şey yoxdur.',
			'profiles.borrowEmptySubtitle' => 'Əvvəlcə başqa bir profile Plex, Jellyfin və ya Emby qoşun.',
			'profiles.borrowLoadFailed' => 'Əlçatan qoşulmalar yüklənə bilmədi. Təzədən cəhd edin.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName} profilindən',
			'profiles.borrowConnectionBorrowed' => 'Qoşulma istifadə edildi.',
			'profiles.borrowFailed' => 'Qoşulma istifadə edilə bilmədi.',
			'profiles.incorrectPin' => 'Səhv PIN.',
			'profiles.incorrectPinTryAgain' => 'Səhv PIN. Lütfən təzədən cəhd edin.',
			'profiles.sourceProfileMissingParentAccount' => 'Mənbə profilin əsas hesabı yoxdur.',
			'profiles.failedToLoadHomeUsers' => 'Plex Home istifadəçiləriniz yüklənə bilmədi. Bağlantınızı yoxlayın və yenidən cəhd edin.',
			'profiles.failedToVerifyPin' => 'PIN təsdiqlənə bilmədi.',
			'profiles.newProfile' => 'Yeni profil',
			'profiles.profileNameHint' => 'məs. Qonaqlar, Uşaqlar, Qonaq otağı',
			'profiles.pinProtectionOptional' => 'PIN mühafizəsi (istəyə bağlı)',
			'profiles.pinExplain' => 'Profillər arası keçid üçün 4 rəqəmli PIN tələb olunur.',
			'profiles.continueButton' => 'Davam et',
			'profiles.pinsDontMatch' => 'PIN-lər uyğun gəlmir',
			'profiles.tokenIdentityMismatch' => 'Plex profil tokeni gözlənilməyən serveri müəyyən etdi',
			'profiles.settingsLocked' => 'Bu profillərin qalıb olması üçün bu profillərin qalıb olmasıdır.',
			'profiles.unlockSettings' => 'Qatırılma',
			'profiles.showExploreForProfile' => 'Bu profillə baxın',
			'profiles.showExploreForProfileDescription' => 'Bu profillərin navigasiyasından Explore-i kaldırmaq üçün açılın.',
			'connections.sectionTitle' => 'Qoşulmalar',
			'connections.addConnection' => 'Qoşulma əlavə et',
			'connections.addConnectionSubtitleNoProfile' => 'Plex ilə daxil olun və ya Jellyfin yaxud Emby serverinə qoşulun',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName} profilinə əlavə et: Plex, Jellyfin, Emby və ya başqa profil qoşulması',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} üçün seansın vaxtı bitdi',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} server üçün seansın vaxtı bitdi',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} bu hesaba girişi rədd etdi',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} server bu hesaba girişi rədd etdi',
			'connections.signInAgain' => 'Yenidən daxil ol',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product} qoşulmasını düzəliş et',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName} üçün URL-lər əlavə edin və ya silin. PlezyNG əlçatan olan ən aşağı gecikməli URL-i istifadə edəcək.',
			'accountPreferences.sectionTitle' => 'Hesab tərcihləri',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => '${account} hesabında saxlanılan səs, altyazı və kitabxana seçimləri',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => '${count} hesabda saxlanılan səs, altyazı və kitabxana seçimləri',
			'accountPreferences.pickAccount' => 'Hər hesab öz tərcihlərini saxlayır. Düzəliş etmək üçün birini seçin.',
			'accountPreferences.storedOnAccount' => 'Bu seçimlər hesabın özündə saxlanılır, ona görə də ona daxil olan hər tətbiq onlardan istifadə edir — digər cihazlarınızdakı PlezyNG də daxil olmaqla.',
			'accountPreferences.noAccounts' => 'Konfiqurasiya ediləcək hesab yoxdur',
			'accountPreferences.noAccountsHint' => 'Plex-ə daxil olun və ya Jellyfin və ya Emby serverinə qoşulun; o hesabda saxlanılan tərcihlər burada görünəcək.',
			'accountPreferences.unavailable' => 'Bu hesaba çatmaq olmur',
			'accountPreferences.loadFailed' => 'Bu tərcihlər yüklənə bilmədi',
			'accountPreferences.noPreference' => 'Tərcih yoxdur',
			'accountPreferences.notSet' => 'Təyin edilməyib',
			'accountPreferences.groups.audioAndSubtitles' => 'Səs və altyazılar',
			'accountPreferences.groups.libraryDisplay' => 'Kitabxana',
			'accountPreferences.groups.personalMedia' => 'Şəxsi media',
			'accountPreferences.preferredAudioLanguage' => 'Üstünlük verilən səs dili',
			'accountPreferences.autoSelectAudio' => 'Səsi dilə görə seç',
			'accountPreferences.autoSelectAudioDescription' => 'Söndürüldükdə faylın defolt olaraq işarələdiyi səs treki istifadə olunur.',
			'accountPreferences.preferredSubtitleLanguage' => 'Üstünlük verilən altyazı dili',
			'accountPreferences.subtitleMode' => 'Altyazıları aç',
			'accountPreferences.subtitleModes.none' => 'Əl ilə seçilmiş',
			'accountPreferences.subtitleModes.noneDescription' => 'Altyazıları heç vaxt özbaşına açma.',
			'accountPreferences.subtitleModes.defaultMode' => 'Trek bayraqlarına əməl et',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Hər altyazı trekində saxlanılan defolt və məcburi bayraqları istifadə et.',
			'accountPreferences.subtitleModes.always' => 'Həmişə aktivdir',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Üstünlük verilən dildə altyazı treki mövcuddursa, onu aç.',
			'accountPreferences.subtitleModes.onlyForced' => 'Yalnız məcburi altyazılar',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Yalnız məcburi işarələnmiş trekləri yüklə.',
			'accountPreferences.subtitleModes.smart' => 'Xarici səs olduqda göstərilən',
			'accountPreferences.subtitleModes.smartDescription' => 'Altyazıları yalnız səs başqa dildə olduqda aç.',
			'accountPreferences.subtitleAccessibility' => 'SDH altyazıları',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'SDH olmayan altyazılara üstünlük ver',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH altyazılarına üstünlük ver',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Yalnız SDH altyazıları',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Yalnız SDH olmayan altyazılar',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Standart və SDH versiyonları var olduğunda standart alt başlıklar tercih edilir.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'SDH subtitlləri mevcut olduğunda tercih edər, ancak standart subtitrlər düşüş kimi izin verir.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'SDH subtitlləri yalnız istifadə edin; standart subtitrələrə qayıtmayın.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Standart subtitlləri yalnız istifadə edin; SDH subtitraları dışlayın.',
			'accountPreferences.forcedSubtitles' => 'Məcburi altyazılar',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Məcburi olmayan altyazılara üstünlük ver',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Məcburi altyazılara üstünlük ver',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Yalnız məcburi altyazılar',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Yalnız məcburi olmayan altyazılar',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'VVD-nin idarə etdiyi superkarlar – bu, artıq çox az fərqlənib.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Hazır olduğunda zorlu yolları tercih edər, ancak düşüş kimi düzgün alt başlıklara izin verir.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Yalnızca zorunlu olarak işaretlenmiş yolları kullanın.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Xatırılan yollar işaretlenir.',
			'accountPreferences.displayMissingEpisodes' => 'Çatışmayan seriyaları göstər',
			'accountPreferences.displayMissingEpisodesDescription' => 'Serverin bildiyi, lakin faylı olmayan seriyaları siyahıya al.',
			'accountPreferences.hidePlayedInLatest' => 'Baxılmış elementləri Son əlavə olunanlarda gizlət',
			'accountPreferences.hidePlayedInLatestDescription' => 'Artıq baxdığınız elementləri serverin Son əlavə olunanlar sətirlərində göstərmə.',
			'accountPreferences.displayCollectionsView' => 'Kolleksiyalar görünüşünü göstər',
			'accountPreferences.displayCollectionsViewDescription' => 'Kitabxanalarınızla yanaşı serverin Kolleksiyalar görünüşünü də təklif et.',
			'accountPreferences.rewatchingInNextUp' => 'Təkrar baxılan serialları Sırada saxla',
			'accountPreferences.rewatchingInNextUpDescription' => 'Bir serialı bitirdikdən sonra yenidən başlasanız, Sırada serialı atmaq əvəzinə təkrar baxışı izləyir.',
			'accountPreferences.watchedIndicator' => 'Baxıldı göstəriciləri',
			'accountPreferences.watchedIndicatorOptions.none' => 'Heç vaxt',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Kinolar və TV şoular',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Yalnız kinolar',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Yalnız TV şoular',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Görüntülən kontrol markaları göstərməyin.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Televiziyası və filmlər üçün gözləyir.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Görüntülər yalnız filmlər üçün gözləyir.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Televiziyalar üçün yalnız gözləyirlər göstərilir.',
			'accountPreferences.mediaReviewsVisibility' => 'Reytinq və rəylər',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'İstifadəçilər və tənqidçilər',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Yalnız istifadəçilər',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Yalnız tənqidçilər',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Gizlədilib',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Kullanıcıların və kritik puanları da göstərilir.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Görünür ki, kullanıcılar tərəfindən göndərilmiş değerlendirmələr və görüşlər.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Critical ratings və reviewlər göstərilir.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Qalıqlar və değerlendirmələr.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Bu dildə audio izləri tercih edər ki, sunucu və ya oynatıcı otomatik olarak bir izi seçer.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Subtitles automatik olaraq seçildiğinde bu dildə subtitles izləri tercih edilir.',
			'accountPreferences.subtitleAccessibilityDescription' => 'SDH qapsiyaları automatik subtitle seçimi sırasında tercih edilir və ya gerektirir.',
			'accountPreferences.forcedSubtitleDescription' => 'Seçin ki, automatik seçimdə zorunlu alt başlık izləri tercih edilir və ya gerektirir.',
			'accountPreferences.watchedIndicatorDescription' => 'Həkimlər, server interfejsində gözləmiş bir kontrol işareti aldığını seçin.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Həyatçıların və müştərinin hədisində nə olduğunu seçin.',
			'accountPreferences.subtitleModeDescription' => 'Subtitles bu server hesabı üçün automatik olarak açılırsa seçin.',
			'accountPreferences.hubDescription' => 'Bu seçeneklər Media-server hesabınızda saxlanır və diğer müştərilər üçün də geçerlidir.',
			'discover.title' => 'Kəşf et',
			'discover.noContentAvailable' => 'Məzmun əlçatan deyil',
			'discover.addMediaToLibraries' => 'Kitabxanalarınıza bir az media əlavə edin',
			'discover.continueWatching' => 'İzləməyə davam et',
			'discover.continueWatchingIn' => ({required Object library}) => '${library} daxilində İzləməyə davam et',
			'discover.nextUp' => 'Sırada',
			'discover.nextUpIn' => ({required Object library}) => '${library} daxilində Sırada',
			'discover.recentlyAdded' => 'Son əlavə olunanlar',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library} daxilində Son əlavə olunanlar',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library} daxilində Son albomlar',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library} daxilində Son oynadılanlar',
			'discover.mostPlayedIn' => ({required Object library}) => '${library} daxilində Ən çox oynadılanlar',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'M${season}S${episode}',
			'discover.overview' => 'İcmal',
			'discover.cast' => 'Aktyorlar',
			'discover.findNext.title' => 'Növbəti seçiminizi tapın',
			'discover.findNext.open' => 'Növbəti seçiminizi tapın',
			'discover.findNext.anyTime' => 'İstənilən müddət',
			'discover.findNext.timeAvailable' => 'Nə qədər vaxtınız var?',
			'discover.findNext.filters' => 'Vaxtınıza uyğun seçim edin',
			'discover.findNext.watch' => 'İzləyin',
			'discover.findNext.listen' => 'Dinləyin',
			'discover.findNext.read' => 'Oxuyun',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration} ərzində bitirə bilərsiniz',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Təxminən ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Növbəti fəsil · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Ümumi müddət: ${duration}',
			'discover.findNext.timingVaries' => 'Müddət dəyişə bilər',
			'discover.findNext.notNow' => 'İndi yox',
			'discover.findNext.swipeHint' => 'Üz qabığını ox istiqamətində sürüşdürün və ya aşağıdakı düymələrdən istifadə edin.',
			'discover.findNext.saved' => 'Yadda saxlanmış seçimlər',
			'discover.findNext.savedCount' => ({required Object count}) => 'Yadda saxlanmış seçimlər · ${count}',
			'discover.findNext.undo' => 'Geri al',
			'discover.findNext.details' => 'Təfərrüatlar',
			'discover.findNext.noPicks' => 'Hələ seçim yoxdur',
			'discover.findNext.noPicksHint' => 'Başlamaq üçün kitabxana qoşun və ya media mənbəyi əlavə edin.',
			'discover.findNext.noMatches' => 'Hazırkı vaxtınıza uyğun seçim yoxdur',
			'discover.findNext.noMatchesHint' => 'Başqa media növünü sınayın və ya daha çox vaxt ayırın.',
			'discover.findNext.allDone' => 'Bütün seçimlərə baxdınız',
			'discover.findNext.allDoneHint' => 'Bu seçimləri yenidən görmək üçün yeni bir seçim dəsti yaradın.',
			'discover.findNext.refresh' => 'Başqa seçimlər tapın',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Mənbə: ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Kitabxana: ${library}',
			'discover.findNext.ownedReason' => 'Kitabxananızdan',
			'discover.findNext.liveNow' => 'Hazırda yayımlanır',
			'discover.findNext.watchLive' => 'Canlı izləyin',
			'discover.findNext.filterAnything' => 'İstənilən növ',
			'discover.findNext.filterWatch' => 'İzləyin',
			'discover.findNext.filterListen' => 'Dinləyin',
			'discover.findNext.filterRead' => 'Oxuyun',
			'discover.findNext.twentyMinutes' => '20 dəq',
			'discover.findNext.fortyFiveMinutes' => '45 dəq',
			'discover.findNext.ninetyMinutes' => '90 dəq',
			'discover.findNext.apply' => 'Tətbiq et',
			'discover.findNext.openFailed' => 'Bu seçim artıq mövcud deyil. Yenidən yoxlamaq üçün yeniləyin.',
			'discover.findNext.changeFailed' => 'Bu dəyişikliyi yadda saxlamaq mümkün olmadı. Yenidən cəhd edin.',
			'discover.findNext.savedLimit' => 'Yadda saxlanmış seçimlər siyahısı doludur. Başqa seçim saxlamaq üçün birini silin.',
			'discover.findNext.chooseHint' => 'Bir başlığı açın, sonraya saxlayın və ya keçin.',
			'discover.findNext.howItWorks' => 'İstifadə qaydası',
			'discover.findNext.notNowHelp' => 'Bu başlığı hələlik keçin. O, kitabxananızda qalacaq.',
			'discover.findNext.saveHelp' => 'Bu cihazda bu profilin saxlanmış seçimlərinə əlavə edin. Saxlamaq məzmunu endirmir.',
			'discover.findNext.openHelp' => 'Təfərrüatlar üçün üz qabığını seçin. Başlığı oynatmaq, oxumaq və ya açmaq üçün əsas düymədən istifadə edin.',
			'discover.findNext.controlsHelp' => 'Klaviatura və ya pult: düyməni seçin, sonra Enter və ya seçim düyməsini basın. Geri al son seçiminizi bərpa edir.',
			'discover.findNext.artworkLoading' => 'Şəkil yüklənir…',
			'discover.findNext.artworkUnavailable' => 'Şəkil mövcud deyil',
			'discover.findNext.savedFeedback' => 'Saxlanmış seçimlərə əlavə edildi',
			'discover.findNext.skippedFeedback' => 'Hələlik keçildi',
			'discover.findNext.releaseToConfirm' => 'Təsdiqləmək üçün buraxın',
			'discover.findNext.remoteHint' => 'Üz qabığı fokusda: ← / → seçin · Seçim düyməsi: təfərrüatlar · ↑ / ↓ fokusu dəyişin',
			'discover.extras' => 'Treylerlər və Əlavələr',
			'discover.studio' => 'Studiya',
			'discover.rating' => 'Reytinq',
			'discover.director' => 'Rejissor',
			'discover.directors' => 'Rejissorlar',
			'discover.movie' => 'Kino',
			'discover.tvShow' => 'TV Şou',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} dəq qaldı',
			'discover.moreLikeThis' => 'Buna bənzərlər',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başlıq', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} başlıq', ), 
			'discover.person.born' => 'Doğum tarixi',
			'discover.person.died' => 'Vəfat tarixi',
			'discover.person.birthplace' => 'Doğum yeri',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} yaş)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (${age} yaşında)',
			'errors.searchFailed' => ({required Object error}) => 'Axtarış uğursuz oldu: ${error}',
			'errors.searchUnavailable' => 'Axtarış heç bir media serverinə çata bilmədi.',
			'errors.connectionTimeout' => ({required Object context}) => '${context} yüklənərkən vaxt bitdi',
			'errors.connectionFailed' => 'Media serverinə qoşulmaq olmur',
			'errors.unableToLoad' => ({required Object context}) => '${context} yüklənə bilmədi. Lütfən təzədən cəhd edin.',
			'errors.noClientAvailable' => 'Əlçatan klient yoxdur',
			'errors.pleaseEnterToken' => 'Lütfən token daxil edin',
			'errors.invalidToken' => 'Yanlış token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Token təsdiqlənə bilmədi: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName} profilinə keçilə bilmədi',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '${displayName} profili silinə bilmədi',
			'errors.failedToRate' => 'Reytinq yenilənə bilmədi',
			'errors.reasonTimedOut' => 'bağlantının vaxtı bitdi',
			'errors.reasonUnreachable' => 'serverə çatmaq mümkün olmadı',
			'errors.reasonRefused' => 'server sorğunu rədd etdi',
			'errors.reasonNotFound' => 'element artıq serverdə yoxdur',
			'errors.reasonServerError' => 'server xəta bildirdi',
			'errors.reasonCancelled' => 'sorğu ləğv edildi',
			'errors.reasonUnexpected' => 'gözlənilməz xəta baş verdi',
			'libraries.playRandomMovie' => 'Xatırıq filmini oynayır',
			'libraries.randomPickFailed' => 'Bu kütüphanadan bir film seçmək mümkün deyil.',
			'libraries.title' => 'Kitabxanalar',
			'libraries.fallbackTitle' => 'Kitabxana',
			'libraries.scanLibraryFiles' => 'Kitabxana fayllarını skan et',
			'libraries.scanLibrary' => 'Kitabxananı skan et',
			'libraries.analyze' => 'Analiz et',
			'libraries.analyzeLibrary' => 'Kitabxananı analiz et',
			'libraries.refreshMetadata' => 'Meta-məlumatları yenilə',
			'libraries.emptyTrash' => 'Zibil qutusunu təmizlə',
			'libraries.emptyingTrash' => ({required Object title}) => '"${title}" üçün zibil qutusu təmizlənir...',
			'libraries.trashEmptied' => ({required Object title}) => '"${title}" üçün zibil qutusu təmizləndi',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Zibil qutusu təmizlənə bilmədi: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}" analiz edilir...',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}" üçün analiz başladı',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Kitabxana analiz edilə bilmədi: ${error}',
			'libraries.noLibrariesFound' => 'Kitabxana tapılmadı',
			'libraries.allLibrariesHidden' => 'Bütün kitabxanalar gizlədilib',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Gizli kitabxanalar (${count})',
			'libraries.thisLibraryIsEmpty' => 'Bu kitabxana boşdur',
			'libraries.noItemsMatchFilters' => 'Filtrlərə uyğun element tapılmadı',
			'libraries.resetFilters' => 'Filtrləri sıfırla',
			'libraries.all' => 'Hamısı',
			'libraries.clearAll' => 'Hamısını təmizlə',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '"${title}" kitabxanasını skan etmək istədiyinizdən əminsiniz?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '"${title}" kitabxanasını analiz etmək istədiyinizdən əminsiniz?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '"${title}" üçün meta-məlumatları yeniləmək istədiyinizdən əminsiniz?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '"${title}" üçün zibil qutusunu təmizləmək istədiyinizdən əminsiniz?',
			'libraries.manageLibraries' => 'Kitabxanaları idarə et',
			'libraries.sort' => 'Sırala',
			'libraries.sortBy' => 'Sıralama meyarı',
			'libraries.filters' => 'Filtrlər',
			'libraries.confirmActionMessage' => 'Bu əməliyyatı yerinə yetirmək istədiyinizdən əminsiniz?',
			'libraries.showLibrary' => 'Kitabxananı göstər',
			'libraries.hideLibrary' => 'Kitabxananı gizlət',
			'libraries.libraryOptions' => 'Kitabxana seçimləri',
			'libraries.content' => 'kitabxana məzmunu',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'Kitabxana seç',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtrlər (${count})',
			'libraries.noRecommendations' => 'Tövsiyə yoxdur',
			'libraries.noCollections' => 'Bu kitabxanada kolleksiya yoxdur',
			'libraries.noFoldersFound' => 'Qovluq tapılmadı',
			'libraries.folders' => 'qovluqlar',
			'libraries.tabs.recommended' => 'Tövsiyə olunanlar',
			'libraries.tabs.browse' => 'Baxış',
			'libraries.tabs.collections' => 'Kolleksiyalar',
			'libraries.tabs.playlists' => 'Oynatma siyahıları',
			'libraries.groupings.title' => 'Qruplaşdırma',
			'libraries.groupings.all' => 'Hamısı',
			'libraries.groupings.movies' => 'Kinolar',
			'libraries.groupings.shows' => 'TV Şoular',
			'libraries.groupings.seasons' => 'Mövsümlər',
			'libraries.groupings.episodes' => 'Seriyalar',
			'libraries.groupings.artists' => 'Müğənnilər/Müəlliflər',
			'libraries.groupings.albums' => 'Albomlar',
			'libraries.groupings.tracks' => 'Mahnılar',
			'libraries.groupings.folders' => 'Qovluqlar',
			'libraries.filterCategories.genre' => 'Janr',
			'libraries.filterCategories.year' => 'İl',
			'libraries.filterCategories.contentRating' => 'Məzmun reytinqi',
			'libraries.filterCategories.tag' => 'Teq',
			'libraries.filterCategories.unwatched' => 'Baxılmayıb',
			'libraries.filterCategories.unplayed' => 'Oynadılmayıb',
			'libraries.filterCategories.favorites' => 'Sevimlilər',
			'libraries.filterCategories.filePath' => 'Fayl yolu',
			'libraries.sortLabels.title' => 'Ad',
			'libraries.sortLabels.dateAdded' => 'Əlavə olunma tarixi',
			'libraries.sortLabels.releaseDate' => 'Buraxılış tarixi',
			'libraries.sortLabels.rating' => 'Reytinq',
			'libraries.sortLabels.communityRating' => 'İcma reytinqi',
			'libraries.sortLabels.criticRating' => 'Tənqidçi reytinqi',
			'libraries.sortLabels.userRating' => 'İstifadəçi reytinqi',
			'libraries.sortLabels.datePlayed' => 'Oynadılma tarixi',
			'libraries.sortLabels.playCount' => 'Oynadılma sayı',
			'libraries.sortLabels.productionYear' => 'İstehsal ili',
			'libraries.sortLabels.runtime' => 'Müddət',
			'libraries.sortLabels.officialRating' => 'Rəsmi reytinq',
			'libraries.sortLabels.premiereDate' => 'Premyera tarixi',
			'libraries.sortLabels.startDate' => 'Başlanğıc tarixi',
			'libraries.sortLabels.airTime' => 'Yayımlanma vaxtı',
			'libraries.sortLabels.studio' => 'Studiya',
			'libraries.sortLabels.random' => 'Təsadüfi',
			'libraries.sortLabels.dateShared' => 'Paylaşılma tarixi',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Son seriya yayın tarixi',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Əlavə olunan son seriya tarixi',
			'libraries.sortLabels.dateDownloaded' => 'Yüklənmə tarixi',
			'libraries.sortLabels.size' => 'Həcm',
			'libraries.sortLabels.library' => 'Kitabxana',
			'libraries.advancedFilters.include' => 'Daxil et',
			'libraries.advancedFilters.exclude' => 'Xaric et',
			'libraries.advancedFilters.any' => 'İstənilən',
			'libraries.advancedFilters.yes' => 'Bəli',
			'libraries.advancedFilters.no' => 'Xeyr',
			'libraries.advancedFilters.not' => ({required Object value}) => '${value} deyil',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} seçilib',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} xaric edilib',
			'libraries.advancedFilters.searchValues' => 'Dəyərlərdə axtar',
			'libraries.advancedFilters.noValues' => 'Dəyər yoxdur',
			'libraries.advancedFilters.matchContains' => 'Ehtiva edir',
			'libraries.advancedFilters.matchNotContains' => 'Ehtiva etmir',
			'libraries.advancedFilters.matchIs' => 'Bərabərdir',
			'libraries.advancedFilters.matchIsNot' => 'Bərabər deyil',
			'libraries.advancedFilters.matchBeginsWith' => 'İlə başlayır',
			'libraries.advancedFilters.matchEndsWith' => 'İlə bitir',
			'libraries.advancedFilters.textHint' => 'Uyğunluq üçün yazın',
			'libraries.advancedFilters.from' => 'Başlanğıc',
			'libraries.advancedFilters.to' => 'Son',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} – ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} və yuxarı',
			'libraries.advancedFilters.atMost' => ({required Object value}) => '${value} və aşağı',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Son ${count} gün',
			'libraries.advancedFilters.dateLastYear' => 'Son bir il',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '${count} gündən köhnə',
			'libraries.advancedFilters.dateOlderThanYear' => 'Bir ildən köhnə',
			'libraries.selection.selectItems' => 'Seçimlər',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} seçilib',
			'libraries.selection.actions' => 'Seçimlər',
			'libraries.selection.confirmDescendants' => 'Bu, seçilmiş şovlarda və sezonlarda bütün epizodları dəyişir.',
			'libraries.selection.confirmUnwatched' => 'Bu, seçilmiş elementlərin oxutma gedişatını da sıfırlayır.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Seçilmiş elementlər: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Güncellenmiş elementlər: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Xatırılmış ${succeeded}; başarısız ${failed}. başarısız elementlər seçilmişdir.',
			'about.title' => 'Haqqında',
			'about.openSourceLicenses' => 'Açıq mənbə lisenziyaları',
			'about.versionLabel' => ({required Object version}) => 'Versiya ${version}',
			'about.appDescription' => 'Flutter üçün gözəl bir Plex, Jellyfin və Emby klienti',
			'about.viewLicensesDescription' => 'Üçüncü tərəf kitabxanalarının lisenziyalarına baxın',
			'about.privacyPolicy' => 'Məxfilik Siyasəti',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email}) üçün server tapılmadı',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Serverlər yüklənə bilmədi: ${error}',
			'serverSelection.noValidServers' => 'Bu hesabda istifadəyə yararlı server tapılmadı',
			'hubDetail.title' => 'Başlıq',
			'hubDetail.releaseYear' => 'Buraxılış ili',
			'hubDetail.dateAdded' => 'Əlavə olunma tarixi',
			'hubDetail.rating' => 'Reytinq',
			'hubDetail.noItemsFound' => 'Element tapılmadı',
			'logs.clearLogs' => 'Jurnalları təmizlə',
			'logs.copyLogs' => 'Jurnalları kopyala',
			'logs.uploadLogs' => 'Jurnalları yüklə',
			'logs.saveLogs' => 'Filə yazmaq',
			'logs.logsSaved' => ({required Object path}) => 'Xatırılan sayı: ${path}',
			'logs.saveLogsFailed' => 'Bu log dosyasını saxlamamışdır.',
			'startup.failedTitle' => 'PlezyNG başlaya bilmədi',
			'startup.failedBody' => 'Başlatma zamanı nəsə səhv getdi. Aşağıdakı təfərrüatlar nəyin uğursuz olduğunu göstərir.',
			'startup.failedBodyRepairable' => 'PlezyNG-nin saxlanmış tənzimləmə faylı zədələnib və PlezyNG başlamazdan əvvəl yenidən qurulmalıdır. Təzədən cəhd etmək kömək etməyəcək — Yaddaşı təmir et seçin.',
			'startup.phaseLabel' => 'Addım',
			'startup.showDetails' => 'Təfərrüatları göstər',
			'startup.hideDetails' => 'Təfərrüatları gizlət',
			'startup.copyDetails' => 'Təfərrüatları kopyala',
			'startup.detailsCopied' => 'Təfərrüatlar buferə kopyalandı',
			'startup.uploadDetails' => 'Təfərrüatları yüklə',
			'startup.repairStorage' => 'Yaddaşı təmir et',
			'startup.repairTitle' => 'Saxlanmış məlumatlar təmir edilsin?',
			'startup.repairBodyCommon' => 'PlezyNG-nin tənzimləmə faylı zədələnib və oxuna bilmir. Təmir bütün tənzimləmələri defolt vəziyyətinə sıfırlayır.',
			'startup.repairBodyOneCredential' => 'Bir saxlanmış daxil olma məlumatı zədələnib və oxuna bilmir. Təmir yalnız onu silir; digər tənzimləmələrinizə toxunulmur.',
			'startup.repairBodySignInsKept' => 'Serverləriniz və profilləriniz daxil olmuş vəziyyətdə qalmalıdır.',
			'startup.repairBodySignInsLost' => 'Saxlanmış daxil olmalarınızı qoruyan açar bu fayldan bərpa edilə bilmir, ona görə də hər serverə və profilə yenidən daxil olmalı olacaqsınız. Media serverinizdə heç nəyə təsir olunmur.',
			'startup.repairBodySessionsUncertain' => 'İzləyicilər (MAL, AniList, Simkl, Trakt) və Seerr ayrıca saxlanılır və qalıb-qalmayacaqları bəlli deyil. PlezyNG sizə nəyi saxladığını dəqiq bildirəcək.',
			'startup.repairConfirm' => 'Təmir et',
			'startup.repairSucceeded' => 'Yaddaş təmir edildi',
			'startup.repairNeedsRestart' => 'Yaddaş təmir edildi — yenidən başlatma tələb olunur',
			'startup.restartRequiredBody' => 'Məlumatlarınız təmir edildi, lakin PlezyNG ondan istifadə etmək üçün yenidən başlamalıdır. PlezyNG-ni bağlayın və yenidən açın.',
			'startup.quitPlezy' => 'PlezyNG-dən çıx',
			'startup.repairFailed' => 'Təmir uğursuz oldu',
			'startup.repairKeptSignIns' => 'Serverləriniz və profilləriniz hələ də daxil olub.',
			'startup.repairLostSignIns' => 'Saxlanmış daxil olmalarınızı qoruyan açar bərpa edilə bilmədi. Hər serverə və profilə yenidən daxil olmalı olacaqsınız.',
			'startup.repairLostSessions' => 'Ən azı bir izləyici və ya Seerr əlaqəsi itirildi və yenidən qoşulmalıdır.',
			'startup.backupTitle' => 'Zədələnmiş faylın nüsxəsi saxlanıldı',
			'startup.backupWarning' => 'O, daxil olma məlumatlarınızı ehtiva edir. Onu yükləməyin və ya paylaşmayın.',
			'startup.deleteBackup' => 'Nüsxəni sil',
			'startup.backupDeleted' => 'Nüsxə silindi.',
			'startup.previousFailureTitle' => 'PlezyNG son dəfə başlaya bilmədi',
			'licenses.relatedPackages' => 'Əlaqəli paketlər',
			'licenses.license' => 'Lisenziya',
			'licenses.licenseNumber' => ({required Object number}) => 'Lisenziya ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} lisenziya',
			'navigation.libraries' => 'Kitabxanalar',
			'navigation.downloads' => 'Yükləmələr',
			'navigation.liveTv' => 'Canlı TV',
			'navigation.explore' => 'Kəşf et',
			'explore.mdblistShelves.manage' => 'Gəlimlər: Təbrişlər',
			'explore.mdblistShelves.manageDescription' => 'Hesabınızdan MDBList listləri seçin və düzeltin',
			'explore.mdblistShelves.description' => 'Xəbəri və TV listləri hesabınızdan seçin MDBList-dən. listaları MDBList-dən yaratın və ya kopyalayın.',
			'explore.mdblistShelves.selected' => 'Seçilmiş çadırlar',
			'explore.mdblistShelves.available' => 'Hesab listaları',
			'explore.mdblistShelves.noLists' => 'İctimai film və ya TV siyahısı tapılmadı. MDBList-də siyahı yaradın və ya köçürün, sonra yeniləyin.',
			'explore.mdblistShelves.displayName' => 'Xatırın adı',
			'explore.mdblistShelves.nameHint' => 'Bu barədə “Müslər” adlı kitabın adı yazılır.',
			'explore.mdblistShelves.add' => 'Şelətlər',
			'explore.mdblistShelves.save' => 'Şahətlər',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Qəzaqə ${title}',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Qəzaqə ${title}',
			'explore.mdblistShelves.unavailable' => 'Bu listə baxılmır. ayarlarda şelalini geri qaytarır və ya kaldırır.',
			'explore.mdblistShelves.rateLimited' => 'MDBList sorğu limitinə çatıldı. Daha sonra yenidən cəhd edin.',
			'explore.mdblistShelves.loadFailed' => 'Rəfləri yükləmək mümkün olmadı. Bağlantınızı yoxlayın və yenidən cəhd edin.',
			'explore.mdblistShelves.saveFailed' => 'Rəfləri yadda saxlamaq mümkün olmadı. Yenidən cəhd edin.',
			'explore.mdblistShelves.accountChanged' => 'Hesab və profil dəyişib.Bu ayarları yeniden açın.',
			'explore.mdblistShelves.settingsUnreadable' => 'Bu ayarları dəyişdirmək üçün listlərinizə qayıdan seçin.',
			'explore.title' => 'Kəşf et',
			'explore.selectSource' => 'Mənbə seçin',
			'explore.rows.watchlist' => 'İzləmə siyahısı',
			'explore.rows.recommendedMovies' => 'Tövsiyə olunan kinolar',
			'explore.rows.recommendedShows' => 'Tövsiyə olunan seriallar',
			'explore.rows.trendingMovies' => 'Trend kinolar',
			'explore.rows.trendingShows' => 'Trend seriallar',
			'explore.rows.popularMovies' => 'Məşhur kinolar',
			'explore.rows.popularShows' => 'Məşhur seriallar',
			'explore.rows.trendingAnime' => 'Trend animelər',
			'explore.rows.suggestedAnime' => 'Tövsiyə olunan animelər',
			'explore.rows.airingAnime' => 'Ən yaxşı yayımlanan animelər',
			'explore.rows.popularAnime' => 'Ən məşhur animelər',
			'explore.rows.trending' => 'Trendlər',
			'explore.rows.upcomingMovies' => 'Gələcək kinolar',
			'explore.rows.upcomingShows' => 'Gələcək seriallar',
			'explore.status.airing' => 'Yayımlanır',
			'explore.status.ended' => 'Bitdi',
			'explore.status.canceled' => 'Ləğv edildi',
			'explore.status.upcoming' => 'Gələcək',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriya', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriya', ), 
			'explore.cast' => 'Aktyorlar',
			'explore.characters' => 'Personajlar',
			'explore.addToWatchlist' => 'İzləmə siyahısına əlavə et',
			'explore.removeFromWatchlist' => 'İzləmə siyahısından sil',
			'explore.addedToWatchlist' => 'Baxış siyahısına əlavə edildi',
			'explore.removedFromWatchlist' => 'Baxış siyahısından silindi',
			'explore.watchlistUpdateFailed' => 'İzləmə siyahısı yenilənə bilmədi',
			'explore.watchlistNoMatch' => 'Bu elementi heç bir baxış siyahısı ilə uyğunlaşdırmaq olmadı',
			'explore.notInLibrary' => 'Kitabxananızda yoxdur',
			'explore.inTheseLibraries' => 'Bu kitabxanalarda var',
			'explore.checkingLibrary' => 'Kitabxananız yoxlanılır...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveri yoxlamaq olmadı', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveri yoxlamaq olmadı', ), 
			'explore.emptyTitle' => 'Hələlik burada heç nə yoxdur',
			'explore.emptyMessage' => ({required Object source}) => '${source} mənbəsindən olan sətirlər burada görünəcək.',
			'explore.searchHint' => ({required Object source}) => '${source} daxilində axtar',
			'explore.searchEmpty' => ({required Object query}) => '"${query}" üçün nəticə tapılmadı',
			'explore.searchPrompt' => ({required Object source}) => '${source} vasitəsilə kino və seriallar axtarın.',
			'explore.searchFailed' => 'Axtarış uğursuz oldu. Bağlantınızı yoxlayın və yenidən cəhd edin.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} populyar',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} yayımlanır',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} qiymətləndirilib',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} trenddə',
			'explore.badge.rankSeasonal' => ({required Object season, required Object n}) => '${season} üçün #${n}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} izləyir',
			'explore.badge.available' => 'Əlçatandır',
			'explore.badge.partiallyAvailable' => 'Hissəvi əlçatandır',
			'explore.badge.availableIn4k' => '4K əlçatandır',
			'explore.badge.requested' => 'Sorğu göndərildi',
			'explore.badge.pendingApproval' => 'Təsdiq gözlənilir',
			'explore.badge.processing' => 'Emal edilir',
			'explore.badge.declined' => 'Rədd edildi',
			'explore.badge.requestFailed' => 'Sorğu uğursuz oldu',
			'explore.badge.requested4k' => '4K sorğu göndərildi',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} mövsüm',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} ${duration} sonra',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Növbəti ${duration} sonra',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ep',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} dəq/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} siyahıya alınıb',
			'explore.stats.viewersDay' => ({required Object n}) => 'Bu gün ${n} izlədi',
			'explore.stats.viewersWeek' => ({required Object n}) => 'Bu həftə ${n} izlədi',
			'explore.stats.viewersMonth' => ({required Object n}) => 'Bu ay ${n} izlədi',
			'explore.stats.viewersYear' => ({required Object n}) => 'Bu il ${n} izlədi',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} izləyici',
			'explore.stats.planning' => ({required Object n}) => '${n} izləməyi planlaşdırır',
			'explore.stats.favorited' => ({required Object n}) => '${n} favorit',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} izləməyi dayandırdı',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} şərh', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} şərh', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} səs',
			'explore.stats.watching' => ({required Object n}) => '${n} izləyir',
			'explore.stats.completed' => ({required Object n}) => '${n} tamamladı',
			'explore.stats.onHold' => ({required Object n}) => '${n} fasilədə',
			'explore.stats.dropped' => ({required Object n}) => '${n} izləməyi dayandırdı',
			'explore.season.winter' => 'Qış',
			'explore.season.spring' => 'Yaz',
			'explore.season.summer' => 'Yay',
			'explore.season.fall' => 'Payız',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'Qısa TV',
			'explore.format.movie' => 'Kino',
			'explore.format.special' => 'Xüsusi buraxılış',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Musiqi',
			'explore.format.other' => 'Digər',
			'explore.sourceMaterial.original' => 'Orijinal',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Roman',
			'explore.sourceMaterial.visualNovel' => 'Vizual roman',
			'explore.sourceMaterial.game' => 'Oyun',
			'explore.sourceMaterial.webComic' => 'Veb komiks',
			'explore.sourceMaterial.musicRelease' => 'Musiqi',
			'explore.sourceMaterial.otherMedia' => 'Digər',
			'explore.creditRole.actor' => 'Aktyor',
			'explore.creditRole.director' => 'Rejissor',
			'explore.creditRole.writer' => 'Ssenarist',
			'explore.creditRole.producer' => 'Prodüser',
			'explore.creditRole.creator' => 'Yaradıcı',
			'explore.creditRole.composer' => 'Bəstəkar',
			'explore.relation.prequel' => 'Prikvel',
			'explore.relation.sequel' => 'Sikvel',
			'explore.relation.sideStory' => 'Yan hekayə',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Alternativ versiya',
			'explore.relation.summary' => 'Xülasə',
			'explore.relation.parentStory' => 'Əsas hekayə',
			'explore.relation.adaptation' => 'Adaptasiya',
			'explore.relation.other' => 'Əlaqəli',
			'explore.broadcast' => ({required Object day, required Object time}) => '${day} saat ${time}-da yayımlanır',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => '${day} saat ${time} (${timezone}) yayımlanır',
			'explore.detail.originalTitle' => 'Orijinal başlıq',
			'explore.detail.alsoKnownAs' => 'Digər adları',
			'explore.detail.studios' => 'Studiyalar',
			'explore.detail.country' => 'Ölkə',
			'explore.detail.language' => 'Dil',
			'explore.detail.released' => 'Buraxılıb',
			'explore.detail.physicalRelease' => 'Diskdə',
			'explore.detail.ended' => 'Bitib',
			'explore.detail.addedOn' => ({required Object date}) => '${date} əlavə edildi',
			'explore.detail.yourRating' => 'Sizin qiymətləndirməniz',
			'explore.detail.budget' => 'Büdcə',
			'explore.detail.revenue' => 'Kassa gəliri',
			'explore.detail.contentAdvisory' => 'Yaş tövsiyəsi',
			'explore.detail.tags' => 'Teqlər',
			'explore.detail.revealSpoilerTags' => 'Spoyler teqlərini göstər',
			'explore.detail.links' => 'Keçidlər',
			'explore.detail.watchOn' => 'İzlə',
			'explore.detail.watchTrailer' => 'Treyleri izlə',
			'explore.detail.openOn' => ({required Object site}) => '${site} saytında aç',
			'explore.detail.crew' => 'Heyət',
			'explore.detail.ratings' => 'Reytinq',
			'explore.detail.schedule' => 'Cədvəl',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} istifadəçi tövsiyə edir', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} istifadəçi tövsiyə edir', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who} tövsiyə edir',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who} favorit edib',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} hələ yayımlanmayıb',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'İzləyicilərin ${percent}-i tövsiyə edir',
			'explore.detail.relatedTitles' => 'Əlaqəli başlıqlar',
			'explore.detail.background' => 'Arxa fon',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nəticə', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} nəticə', ), 
			'liveTv.title' => 'Canlı TV',
			'liveTv.guide' => 'Bələdçi',
			'liveTv.noChannels' => 'Əlçatan kanal yoxdur',
			'liveTv.noDvr' => 'Serverdə DVR tənzimlənməyib',
			'liveTv.serverUnavailable' => 'Canlı TV serveri əlçatan deyil.',
			'liveTv.serverNotConnected' => 'Canlı TV serverinə qoşulmayıb.',
			'liveTv.noPrograms' => 'Proqram məlumatı yoxdur',
			'liveTv.liveStreamFailed' => 'Canlı yayım uğursuz oldu',
			'liveTv.unknownProgram' => 'Bilinməyən proqram',
			'liveTv.timelineLiveProgram' => 'Live program (playback bu programın dışında olacaq)',
			'liveTv.timelineBuffer' => 'Buffer zamanlama',
			'liveTv.timelineUnavailable' => 'Saatlər mevcut deyil',
			'liveTv.timelineEstimated' => 'Playback-in çox sayısı',
			'liveTv.timelinePending' => 'Qadınlar arama',
			'liveTv.timelineStale' => 'Tarihdə yaşlanmaq mümkündür.',
			'liveTv.unknownHub' => 'Məlum deyil',
			'liveTv.unknownError' => 'Bilinməyən xəta',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Bilinməyən kanal',
			'liveTv.live' => 'CANLI',
			'liveTv.premiereBadge' => 'Yeni',
			'liveTv.reloadGuide' => 'Bələdçini yenilə',
			'liveTv.searchGuide' => 'Bələdçidə axtar',
			'liveTv.searchHint' => 'Kanal və proqram axtar',
			'liveTv.searchNoResults' => ({required Object query}) => '"${query}" üçün uyğunluq tapılmadı',
			'liveTv.channelsSection' => 'Kanallar',
			'liveTv.programsSection' => 'Proqramlar',
			'liveTv.now' => 'İndi',
			'liveTv.today' => 'Bu gün',
			'liveTv.tomorrow' => 'Sabah',
			'liveTv.midnight' => 'Gecə yarısı',
			'liveTv.overnight' => 'Gecə boyu',
			'liveTv.morning' => 'Səhər',
			'liveTv.daytime' => 'Gündüz',
			'liveTv.evening' => 'Axşam',
			'liveTv.lateNight' => 'Gecə vaxtı',
			'liveTv.whatsOn' => 'İndi nə var?',
			'liveTv.watchChannel' => 'Kanala bax',
			'liveTv.favorites' => 'Sevimlilər',
			'liveTv.reorderFavorites' => 'Sevimliləri yenidən sırala',
			'liveTv.noFavoriteChannels' => 'Sevimli kanal yoxdur',
			'liveTv.noFavoriteChannelsHint' => 'Bütün kanalları göstərin, sonra kanalı sevimlilərə əlavə etmək üçün üzərinə uzun basın.',
			'liveTv.showAllChannels' => 'Bütün kanalları göstər',
			'liveTv.favoritesLoadFailed' => 'Sevimlilər yüklənə bilmədi. Bağlantınızı yoxlayın və yenidən cəhd edin.',
			'liveTv.favoritesUpdateFailed' => 'Sevimlilər yenilənə bilmədi.',
			'liveTv.joinSession' => 'Davam edən seansa qoşul',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Əvvəldən bax (${minutes} dəq əvvəl)',
			'liveTv.watchLive' => 'Canlı bax',
			'liveTv.goToLive' => 'Canlı yayıma keç',
			'liveTv.record' => 'Yaz',
			'liveTv.recordEpisode' => 'Seriyanı yaz',
			'liveTv.recordSeries' => 'Serialı yaz',
			'liveTv.recordOptions' => 'Yazma seçimləri',
			'liveTv.saveTo' => 'Buraya saxla',
			'liveTv.recordings' => 'Yazılmışlar',
			'liveTv.scheduledRecordings' => 'Planlaşdırılmışlar',
			'liveTv.recordingRules' => 'Yazma qaydaları',
			'liveTv.noScheduledRecordings' => 'Yazılacaq heç nə planlaşdırılmayıb',
			'liveTv.manageRecording' => 'Yazmanı idarə et',
			'liveTv.cancelRecording' => 'Yazmanı ləğv et',
			'liveTv.cancelRecordingTitle' => 'Bu yazma ləğv edilsin?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} artıq yazılmayacaq.',
			'liveTv.deleteRule' => 'Qaydanı sil',
			'liveTv.deleteRuleTitle' => 'Yazma qaydası silinsin?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title} serialının gələcək seriyaları yazılmayacaq.',
			'liveTv.recordingScheduled' => 'Yazma planlaşdırıldı',
			'liveTv.alreadyScheduled' => 'Bu proqram artıq planlaşdırılıb',
			'liveTv.dvrAdminRequired' => 'DVR tənzimləmələri inzibatçı hesabı tələb edir',
			'liveTv.recordingFailed' => 'Yazma planlaşdırıla bilmədi',
			'liveTv.recordingTargetMissing' => 'Yazma kitabxanası müəyyən edilə bilmədi',
			'liveTv.recordNotAvailable' => 'Bu proqram üçün yazma əlçatan deyil',
			'liveTv.recordingCancelled' => 'Yazma ləğv edildi',
			'liveTv.recordingRuleDeleted' => 'Yazma qaydası silindi',
			'liveTv.processRecordingRules' => 'Qaydaları yenidən qiymətləndir',
			'liveTv.recordingInProgress' => 'İndi yazılır',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} planlaşdırılıb',
			'liveTv.editRule' => 'Qaydanı dəyişdir',
			'liveTv.editRuleAction' => 'Düzəliş et',
			'liveTv.recordingRuleUpdated' => 'Yazma qaydası yeniləndi',
			'liveTv.guideReloadRequested' => 'Bələdçi yenilənməsi tələb olundu',
			'liveTv.guideReloadFailed' => 'Bələdçi yenilənmədi',
			'liveTv.rulesProcessRequested' => 'Qaydaların yenidən qiymətləndirilməsi tələb olundu',
			'liveTv.rulesProcessFailed' => 'Yazı qaydaları yenidən qiymətləndirilmədi',
			'liveTv.recordShow' => 'Şounu yaz',
			'liveTv.recordSettings.startEarly' => 'Erkən başla (saniyə)',
			'liveTv.recordSettings.endLate' => 'Gec bitir (saniyə)',
			'liveTv.recordSettings.newOnly' => 'Yalnız yeni epizodlar',
			'liveTv.recordSettings.anyChannel' => 'İstənilən kanalda yaz',
			'liveTv.recordSettings.anyTime' => 'İstənilən vaxt yaz',
			'liveTv.recordSettings.skipInLibrary' => 'Kitabxanada artıq olan epizodları ötür',
			'liveTv.recordSettings.keepUpTo' => 'Saxlanılacaq epizodlar',
			'liveTv.recordSettings.keepUpToHint' => '0 bütün epizodları saxlayır',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes} dəq sonra başlayır',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day}, saat ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} etibarsız Canlı TV oynatma məlumatı qaytardı',
			'liveTv.failedToStartChannel' => 'Canlı kanalı başlatmaq olmadı',
			'liveTv.failedToBuildStreamUrl' => 'Yayım URL-i yaratmaq olmadı',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Kanal başladıla bilmədi: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Kanal dəyişdirilə bilmədi: ${reason}',
			'collections.title' => 'Kolleksiyalar',
			'collections.collection' => 'Kolleksiya',
			'collections.empty' => 'Kolleksiya boşdur',
			'collections.deleteCollection' => 'Kolleksiyanı sil',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" silinsin? Bu əməliyyat geri qaytarıla bilməz.',
			'collections.deleted' => 'Kolleksiya silindi',
			'collections.deleteFailed' => 'Kolleksiya silinə bilmədi',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Kolleksiya silinə bilmədi: ${error}',
			'collections.selectCollection' => 'Kolleksiya seç',
			'collections.collectionName' => 'Kolleksiya adı',
			'collections.enterCollectionName' => 'Kolleksiya adını daxil edin',
			'collections.addedToCollection' => 'Kolleksiyaya əlavə edildi',
			'collections.errorAddingToCollection' => 'Kolleksiyaya əlavə edilə bilmədi',
			'collections.created' => 'Kolleksiya yaradıldı',
			'collections.removeFromCollection' => 'Kolleksiyadan sil',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" bu kolleksiyadan silinsin?',
			'collections.removedFromCollection' => 'Kolleksiyadan silindi',
			'collections.removeFromCollectionFailed' => 'Kolleksiyadan silinə bilmədi',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Kolleksiyadan silinərkən xəta: ${error}',
			'collections.searchCollections' => 'Kolleksiyalarda axtar...',
			'playlists.title' => 'Oynatma siyahıları',
			'playlists.playlist' => 'Oynatma siyahısı',
			'playlists.noPlaylists' => 'Oynatma siyahısı tapılmadı',
			'playlists.create' => 'Oynatma siyahısı yarat',
			'playlists.playlistName' => 'Oynatma siyahısı adı',
			'playlists.enterPlaylistName' => 'Oynatma siyahısı adını daxil edin',
			'playlists.delete' => 'Oynatma siyahısını sil',
			'playlists.removeItem' => 'Oynatma siyahısından sil',
			'playlists.smartPlaylist' => 'Ağıllı oynatma siyahısı',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element', ), 
			'playlists.emptyPlaylist' => 'Bu oynatma siyahısı boşdur',
			'playlists.deleteConfirm' => 'Oynatma siyahısı silinsin?',
			'playlists.deleteMessage' => ({required Object name}) => '"${name}" siyahısını silmək istədiyinizdən əminsiniz?',
			'playlists.created' => 'Oynatma siyahısı yaradıldı',
			'playlists.deleted' => 'Oynatma siyahısı silindi',
			'playlists.itemAdded' => 'Oynatma siyahısına əlavə edildi',
			'playlists.itemRemoved' => 'Oynatma siyahısından silindi',
			'playlists.selectPlaylist' => 'Oynatma siyahısı seç',
			'playlists.searchPlaylists' => 'Oynatma siyahılarında axtar...',
			'playlists.errorCreating' => 'Oynatma siyahısı yaradıla bilmədi',
			'playlists.errorDeleting' => 'Oynatma siyahısı silinə bilmədi',
			'playlists.errorLoading' => 'Oynatma siyahıları yüklənə bilmədi',
			'playlists.errorAdding' => 'Oynatma siyahısına əlavə edilə bilmədi',
			'playlists.errorReordering' => 'Element yenidən sıralana bilmədi',
			'playlists.errorRemoving' => 'Oynatma siyahısından silinə bilmədi',
			'music.goToAlbum' => 'Alboma keç',
			'music.goToArtist' => 'İfaçıya keç',
			'music.instantMix' => 'Anında qarışıq',
			'music.playNext' => 'Növbətini oynat',
			'music.addToQueue' => 'Növbəyə əlavə et',
			'music.discNumber' => ({required Object n}) => 'Disk ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mahnı', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mahnı', ), 
			'music.nowPlaying' => 'İndi oynadılır',
			'music.playingFrom' => ({required Object title}) => '${title} mənbəsindən oynadılır',
			'music.queue' => 'Növbə',
			'music.clearQueue' => 'Növbəni təmizlə',
			'music.lyrics' => 'Mahnı sözləri',
			'music.visualizer' => 'Görüntülər',
			'music.visualizerProfileLoading' => 'İndi analizə baxmaq...',
			'music.visualizerAmbientMotion' => 'Atmosferin aktivitesi',
			'music.visualizerPlexLoudness' => 'Plex Sürücüsüz',
			'music.visualizerPreviousPreset' => 'Öncəki Görünürlük',
			'music.visualizerNextPreset' => 'Sonraki Görünüş Stili',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Blum',
			'music.visualizerPresetOrbitals' => 'Orbitlər',
			'music.visualizerPresetPrism' => 'Prismə',
			'music.visualizerPresetTunnel' => 'Tünel',
			'music.visualizerPresetTrackMap' => 'Harita yolları',
			'music.noLyrics' => 'Mahnı sözləri yoxdur',
			'music.sleepTimer' => 'Yuxu taymeri',
			'music.sleepTimerEndOfTrack' => 'Mahnının sonu',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dəqiqə', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} dəqiqə', ), 
			'music.stopPlayback' => 'Oynatmanı saxla',
			'music.previousTrack' => 'Əvvəlki mahnı',
			'music.nextTrack' => 'Növbəti mahnı',
			'music.repeat' => 'Təkrarla',
			'music.repeatAll' => 'Hamısını təkrarla',
			'music.repeatOne' => 'Birini təkrarla',
			'music.instantMixNoServer' => 'Ani miks üçün heç bir server mövcud deyil',
			'music.instantMixFailed' => 'Anında qarışıq yüklənə bilmədi',
			'music.instantMixEmpty' => 'Anında qarışıq heç bir mahnı qaytarmadı',
			'music.noAudioUrl' => ({required Object track}) => '${track} üçün səs URL-i mövcud deyil',
			'music.discography.singlesAndEps' => 'Single-lar və EP-lər',
			'music.discography.live' => 'Canlı',
			'music.discography.compilations' => 'Kompilyasiyalar',
			'watchTogether.title' => 'Birlikdə İzlə',
			'watchTogether.description' => 'Dostlarınız və ailənizlə eyni vaxtda baxın',
			'watchTogether.createRoom' => 'Otaq yarat',
			'watchTogether.creatingRoom' => 'Otaq yaradılır...',
			'watchTogether.joinRoom' => 'Otağa qoşul',
			'watchTogether.joiningRoom' => 'Otağa qoşulunur...',
			'watchTogether.connecting' => 'Qoşulunur...',
			'watchTogether.relayPublic' => 'Otaqlar ictimai Open Watch Party relelərindən istifadə edir.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Otaqlar ${url} ünvanındakı relenizdən istifadə edir.',
			'watchTogether.recentRooms' => 'Son otaqlar',
			'watchTogether.roomActions' => 'Otaq əməliyyatları',
			'watchTogether.renameRoom' => 'Otağın adını dəyişdir',
			'watchTogether.removeRoom' => 'Sil',
			'watchTogether.enterRoomCode' => 'Təşkilatçının verdiyi 6 simvollu kodu daxil edin.',
			'watchTogether.roomCode' => 'Otaq kodu',
			'watchTogether.paste' => 'Yapışdır',
			'watchTogether.noCodeInClipboard' => 'Buferdə otaq kodu yoxdur',
			'watchTogether.copyCode' => 'Kodu kopyala',
			'watchTogether.codeCopied' => 'Otaq kodu kopyalandı',
			'watchTogether.shareInvite' => 'Dəvəti paylaş',
			'watchTogether.inviteCopied' => 'Dəvət kopyalandı. Onu mesaja yapışdırın.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'PlezyNG-də Birlikdə İzlə otağıma qoşul: Birlikdə İzlə bölməsini aç, "Otağa qoşul" düyməsinə bas və ${code} kodunu daxil et.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.openSessionControls' => 'Birlikdə İzlə seans idarəetmələrini aç',
			'watchTogether.reconnecting' => 'Yenidən qoşulunur...',
			'watchTogether.reconnectingDescription' => 'Əlaqə kəsildi. Otağa avtomatik olaraq yenidən qoşulacaqsınız.',
			'watchTogether.connected' => 'Qoşulub',
			'watchTogether.disconnected' => 'Əlaqə kəsilib',
			'watchTogether.youAreHost' => 'Təşkilatçı sizsiniz',
			'watchTogether.hostedBy' => ({required Object name}) => 'Təşkilatçı: ${name}',
			'watchTogether.hostControlsPlayback' => 'Oynatmanı təşkilatçı idarə edir',
			'watchTogether.anyoneCanControl' => 'Oynatmanı hər kəs idarə edə bilər',
			'watchTogether.roomLocked' => 'Otaq kilidlənib',
			'watchTogether.nowPlaying' => 'İndi oynadılır',
			'watchTogether.nothingPlaying' => 'Heç nə oynadılmır',
			'watchTogether.nothingPlayingHost' => 'Otaqla paylaşmaq üçün istənilən kitabxanadan nəsə oynadın.',
			'watchTogether.nothingPlayingGuest' => 'Təşkilatçı nəsə oynatdıqda, burada açılacaq.',
			'watchTogether.notShareable' => 'Bu videonun kataloqda uyğunluğu yoxdur, ona görə də onu yalnız eyni serverə çıxışı olanlar oynada bilər.',
			'watchTogether.searching' => 'Bu video kitabxanalarınızda axtarılır...',
			'watchTogether.yourCopy' => 'Sizin nüsxəniz',
			'watchTogether.sharingYourCopy' => 'Nüsxənizi paylaşırsınız',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Nüsxəniz oynadılır (${difference})',
			'watchTogether.mismatchTitle' => 'Nüsxənizin uzunluğu fərqlidir',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Ən yaxın nüsxəniz otaqdakı videodan ${difference}. Bu, başqa montaj və ya versiya ola bilər.',
			'watchTogether.playAnyway' => 'Yenə də oynat',
			'watchTogether.chooseAnotherCopy' => 'Başqa nüsxə seç',
			'watchTogether.dontPlay' => 'Oynatma',
			'watchTogether.unavailableTitle' => 'Bu video sizdə yoxdur',
			'watchTogether.unavailableDescription' => 'PlezyNG onu kitabxanalarınızda tapa bilmədi. Nüsxəni özünüz seçin və ya yenidən axtarın.',
			'watchTogether.chooseCopy' => 'Nüsxə seç',
			'watchTogether.searchAgain' => 'Yenidən axtar',
			'watchTogether.noCandidates' => 'Kitabxanalarınızda nüsxə tapılmadı.',
			'watchTogether.choiceFailed' => 'Bu nüsxəni otaq üçün oynatmaq mümkün olmadı',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} daha uzun',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} daha qısa',
			'watchTogether.lengthSame' => 'Eyni uzunluq',
			'watchTogether.lengthUnknown' => 'Uzunluq məlum deyil',
			'watchTogether.joinCurrentPlayback' => 'Cari oynatmaya qoşul',
			'watchTogether.joinCurrentPlaybackDescription' => 'Təşkilatçının indi baxdığı hissəyə keçin',
			'watchTogether.stopMedia' => 'Videonu hamı üçün dayandır',
			'watchTogether.syncOffset' => 'Sinxronizasiya ofseti',
			'watchTogether.syncOffsetDescription' => 'Videonuz otaqdan qabaqda və ya geridə qalırsa, onu sürüşdürün.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Nüsxəniz otaqdakı videodan ${difference}.',
			'watchTogether.applyDifference' => ({required Object offset}) => '${offset} tətbiq et',
			'watchTogether.offsetMinusSecond' => '-1 san',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 san',
			'watchTogether.participants' => 'İştirakçılar',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} iştirakçı', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} iştirakçı', ), 
			'watchTogether.hostBadge' => 'TƏŞKİLATÇI',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (Siz)',
			'watchTogether.playerIdle' => 'Gözləmədə',
			'watchTogether.playerLoading' => 'Yüklənir',
			'watchTogether.playerReady' => 'Hazırdır',
			'watchTogether.playerBuffering' => 'Buferlənir',
			'watchTogether.matchSearching' => 'Axtarır',
			'watchTogether.matchMatched' => 'Video var',
			'watchTogether.matchMismatched' => 'Fərqli uzunluq',
			'watchTogether.matchUnavailable' => 'Video yoxdur',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Ofset ${offset}',
			'watchTogether.makeHost' => 'Təşkilatçı təyin et',
			'watchTogether.makeHostQuestion' => 'Təşkilatçı köçürülsün?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} oynatmanı idarə edəcək və seansı hər kəs üçün aparacaq.',
			'watchTogether.transfer' => 'Köçür',
			'watchTogether.removeParticipant' => 'Otaqdan çıxar',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name} çıxarılsın?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} otağı tərk edəcək. Otağı kilidləməsəniz, kodla yenidən qoşula bilər.',
			'watchTogether.remove' => 'Çıxar',
			'watchTogether.roomSettings' => 'Otaq tənzimləmələri',
			'watchTogether.letEveryoneControl' => 'Hamıya oynatmanı idarə etməyə icazə ver',
			'watchTogether.lockRoom' => 'Otağı kilidlə',
			'watchTogether.lockRoomDescription' => 'Heç kim yeni qoşula bilməz',
			'watchTogether.leaveRoom' => 'Otağı tərk et',
			'watchTogether.leaveRoomQuestion' => 'Otaq tərk edilsin?',
			'watchTogether.leaveRoomConfirm' => 'Otaq kodu ilə yenidən qoşula bilərsiniz.',
			'watchTogether.leave' => 'Çıx',
			'watchTogether.endRoom' => 'Otağı bağla',
			'watchTogether.endRoomQuestion' => 'Otaq bağlansın?',
			'watchTogether.endRoomConfirm' => 'Bu, otağı hamı üçün bağlayır.',
			'watchTogether.end' => 'Bitir',
			'watchTogether.playBlockedTitle' => 'Oynatma başlamadı',
			'watchTogether.playBlockedDescription' => 'Otaqla birlikdə baxmağa başlamaq üçün oynat düyməsinə basın.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} oynat düyməsinə basdı',
			'watchTogether.notices.playbackStarted' => 'Oynatma başladı',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} fasilə etdi',
			'watchTogether.notices.playbackPaused' => 'Oynatma fasilə edildi',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} ${position} anına keçdi',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => '${position} anına keçildi',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} sürəti ${speed} olaraq təyin etdi',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Sürət ${speed} olaraq təyin edildi',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} oynatmağa başladı: ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'İndi oynadılır: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} videonu dayandırdı',
			'watchTogether.notices.mediaStopped' => 'Video dayandı',
			'watchTogether.notices.waitingFor' => ({required Object name}) => '${name} gözlənilir...',
			'watchTogether.notices.waitingForSomeone' => 'Kiminsə yetişməsi gözlənilir...',
			'watchTogether.notices.finished' => 'Bitdi',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} indi təşkilatçıdır',
			'watchTogether.notices.youAreNowHost' => 'İndi təşkilatçı sizsiniz',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} qoşuldu',
			'watchTogether.notices.left' => ({required Object name}) => '${name} ayrıldı',
			'watchTogether.notices.controlRefused' => 'Oynatmanı yalnız təşkilatçı idarə edə bilər',
			'watchTogether.notices.searchFailed' => 'Bəzi serverlərdə otağın videosunu axtarmaq mümkün olmadı',
			'watchTogether.notices.playBlocked' => 'Başlamaq üçün oynat düyməsinə basın',
			'watchTogether.notices.shareFailed' => 'Bu videonu otaqla paylaşmaq mümkün olmadı',
			'watchTogether.notices.downloadNotShared' => 'Serverləri oflayn olduğu müddətdə yükləmələr otaqla paylaşılmır',
			'watchTogether.notices.openFailed' => 'Otağın videosunu açmaq mümkün olmadı',
			'watchTogether.ended.ended' => 'Təşkilatçı otağı bağladı',
			'watchTogether.ended.kicked' => 'Siz otaqdan çıxarıldınız',
			'watchTogether.ended.expired' => 'Otağın vaxtı bitdi',
			'watchTogether.ended.replaced' => 'Bu otağa başqa cihazda qoşuldunuz',
			'watchTogether.ended.lost' => 'Otaqla əlaqə kəsildi',
			'watchTogether.errors.invalidCode' => 'Bu, otaq kodu deyil. Kodlar 0, 1, I, L və ya O olmadan 6 hərf və rəqəmdən ibarətdir.',
			'watchTogether.errors.roomNotFound' => 'Bu kodla otaq yoxdur. O, bağlanmış ola bilər.',
			'watchTogether.errors.roomFull' => 'Bu otaq doludur.',
			'watchTogether.errors.roomLocked' => 'Təşkilatçı bu otağı kilidləyib.',
			'watchTogether.errors.relayFull' => 'Birlikdə İzlə hazırda məşğuldur. Sonra yenidən cəhd edin.',
			'watchTogether.errors.unreachable' => 'Birlikdə İzlə relesinə qoşulmaq mümkün olmadı. Bağlantınızı yoxlayın.',
			'watchTogether.errors.rateLimited' => 'Həddindən çox cəhd. Bir az gözləyib yenidən cəhd edin.',
			'watchTogether.errors.clientBlocked' => 'PlezyNG-nin bu versiyası releni istifadə edə bilmir. Tətbiqi yeniləyin.',
			'watchTogether.errors.forbidden' => 'Bunu yalnız təşkilatçı edə bilər.',
			'watchTogether.errors.notInRoom' => 'Siz otaqda deyilsiniz.',
			'watchTogether.errors.alreadyInRoom' => 'Siz artıq otaqdasınız.',
			'watchTogether.errors.resumeFailed' => 'Otağa yenidən qoşulmaq mümkün olmadı.',
			'watchTogether.errors.unsupported' => 'Rele bunu dəstəkləmir.',
			'watchTogether.errors.generic' => 'Nəsə səhv getdi. Yenidən cəhd edin.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Seriya ${number}',
			'downloads.title' => 'Yükləmələr',
			'downloads.manage' => 'İdarə et',
			'downloads.tvShows' => 'TV Şoular',
			'downloads.movies' => 'Kinolar',
			'downloads.music' => 'Musiqi',
			'downloads.tracksQueued' => ({required Object count}) => 'Yükləmə üçün ${count} mahnı növbəyə alındı',
			'downloads.noDownloads' => 'Hələlik yükləmə yoxdur',
			'downloads.noDownloadsDescription' => 'Yüklənmiş məzmun oflayn baxış üçün burada görünəcək',
			'downloads.downloadNow' => 'Yüklə',
			'downloads.deleteDownload' => 'Yükləməni sil',
			'downloads.retryDownload' => 'Yükləməni təzədən cəhd et',
			'downloads.downloadQueued' => 'Yükləmə növbəyə alındı',
			'downloads.downloadResumed' => 'Yükləmə davam etdirildi',
			'downloads.serverErrorBitrate' => 'Server xətası: fayl sürət limitini aşa bilər',
			'downloads.storageFull' => 'Boş yaddaşı qorumaq üçün yükləmələr dayandırıldı. Yer boşaldın və ya başqa yükləmə yeri seçin, sonra yenidən cəhd edin.',
			'downloads.storageUnavailable' => 'Boş yaddaşı yoxlamaq mümkün olmadığı üçün yükləmələr dayandırıldı. Yükləmə yerini yoxlayın, sonra təzədən cəhd edin.',
			'downloads.episodesQueued' => ({required Object count}) => 'Yükləmə üçün ${count} seriya növbəyə alındı',
			'downloads.downloadDeleted' => 'Yükləmə silindi',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" bu cihazdan silinsin?',
			'downloads.deleteCollectionDownloads' => 'Yükləmələri sil',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => '"${title}" daxilindəki bütün yükləmələr bu cihazdan silinsin?',
			'downloads.collectionDownloadsDeleted' => 'Yükləmələr silindi',
			'downloads.cancelledDownloadTitle' => 'Ləğv edilmiş yükləmə',
			'downloads.cancelledDownloadMessage' => 'Bu yükləmə ləğv edildi. Nə etmək istərdiniz?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Bütün seriyalar artıq yüklənib',
			'downloads.resumeDownload' => 'Yükləməni davam etdir',
			'downloads.cancelledDownload' => 'Ləğv edilmiş yükləmə',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} eyniləşdirilir)',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Yükləndi ${file} - Tamamlamaq üçün toxunun',
			'downloads.partialDownloadClickToComplete' => 'Hissəvi yükləndi - Tamamlamaq üçün toxunun',
			'downloads.deleting' => 'Silinir...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} silinir... (${current} / ${total})',
			'downloads.queuedTooltip' => 'Növbədədir',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Növbəyə alınan fayllar: ${files}',
			'downloads.downloadingTooltip' => 'Yüklənir...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Yüklənən fayllar: ${files}',
			'downloads.noDownloadsTree' => 'Yükləmə yoxdur',
			'downloads.pauseAll' => 'Hamısını fasilə et',
			'downloads.resumeAll' => 'Hamısını davam etdir',
			'downloads.retryAll' => 'Hamısını təzədən cəhd et',
			'downloads.retryFailed' => 'Uğursuz yükləmələri təzədən cəhd et',
			'downloads.deleteAll' => 'Hamısını sil',
			'downloads.selectVersion' => 'Versiya seç',
			'downloads.allEpisodes' => 'Bütün seriyalar',
			'downloads.unwatchedOnly' => 'Yalnız baxılmayanlar',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Növbəti ${count} baxılmayan',
			'downloads.customAmount' => 'Xüsusi miqdar...',
			'downloads.customAmountAny' => 'Hər bir dəfə (yəni)',
			'downloads.randomEpisodes' => 'Random epizodları',
			'downloads.includeSpecials' => 'Xüsusi seriyaları daxil et',
			'downloads.howManyEpisodes' => 'Neçə seriya?',
			'downloads.invalidEpisodeCount' => 'Düzgün seriya sayı daxil edin.',
			'downloads.keepSynced' => 'Eyniləşdirilmiş saxla',
			'downloads.downloadOnce' => 'Bir dəfə yüklə',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} baxılmayan seriyanı saxla',
			'downloads.editSyncRule' => 'Eyniləşdirmə qaydasını dəyişdir',
			'downloads.removeSyncRule' => 'Eyniləşdirmə qaydasını sil',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" eyniləşdirməsi dayandırılsın? Yüklənmiş seriyalar saxlanılacaq.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '"${title}" eyniləşdirməsi dayandırılsın?',
			'downloads.deleteSyncRuleDownloads' => 'Əlaqəli yükləmələri də sil',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Başqa eyniləşdirmə qaydası və ya profil tərəfindən istifadə olunan yükləmələr saxlanılacaq.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Eyniləşdirmə qaydası yaradıldı — ${count} baxılmayan seriya saxlanılır',
			'downloads.syncRuleUpdated' => 'Eyniləşdirmə qaydası yeniləndi',
			'downloads.syncRuleRemoved' => 'Eyniləşdirmə qaydası silindi',
			'downloads.syncRuleAndDownloadsRemoved' => 'Eyniləşdirmə qaydası və əlaqəli yükləmələr silindi',
			'downloads.syncRuleCleanupBusy' => 'Eyniləşdirmə qaydaları hazırda yenilənir. Bir azdan təzədən cəhd edin.',
			'downloads.syncRuleCleanupUnavailable' => 'Əlaqəli yükləmələr təhlükəsiz şəkildə müəyyən edilə bilmədi. Serverə yenidən qoşulub cəhd edin və ya qaydanı yükləmələri silmədən silin.',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '${title} üçün ${count} yeni seriya eyniləşdirildi',
			'downloads.syncNow' => 'Sünnə',
			'downloads.downloadsUpToDate' => 'İndirlər günümüzdən',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sinxronlaşdırma tamamlandı · ${queued} növbəyə əlavə edildi, ${removed} silindi',
			'downloads.activeSyncRules' => 'Eyniləşdirmə qaydaları',
			'downloads.reviewOrphanFiles' => 'Yetim qalmış endirmələri nəzərdən keçir',
			'downloads.orphanReviewTitle' => 'Yetim qalmış endirmələri nəzərdən keçir',
			'downloads.orphanReviewDescription' => 'Bu teqlənmiş fayllar PlezyNG-nin tətbiq tərəfindən idarə olunan standart endirmə qovluqlarındadır və onlara uyğun endirmə qeydi və ya aktiv tapşırıq yoxdur. Silməzdən əvvəl siyahını yoxlayın.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} fayl · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '${count} faylı sil',
			'downloads.orphanCleanupNone' => 'Yetim qalmış endirmə faylı tapılmadı',
			'downloads.orphanCleanupFailed' => 'PlezyNG idarə olunan endirmələr qovluğunu təhlükəsiz şəkildə skan edə bilmədi. Heç bir fayl silinmədi.',
			'downloads.orphanCleanupChanged' => 'Nəzərdən keçirmə zamanı endirmə siyahısı dəyişdi. Təmizləməzdən əvvəl faylları yenidən nəzərdən keçirin.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '${count} yetim endirmə faylı silindi · ${size} yer boşaldıldı',
			'downloads.noSyncRules' => 'Eyniləşdirmə qaydası yoxdur',
			'downloads.manageSyncRule' => 'Eyniləşdirməni idarə et',
			'downloads.editEpisodeCount' => 'Seriya sayı',
			'downloads.editSyncFilter' => 'Eyniləşdirmə filtri',
			'downloads.syncAllItems' => 'Bütün elementlər eyniləşdirilir',
			'downloads.syncUnwatchedItems' => 'Baxılmayan elementlər eyniləşdirilir',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Əlçatandır',
			'downloads.syncRuleOffline' => 'Oflayn',
			'downloads.syncRuleSignInRequired' => 'Daxil olmaq tələb olunur',
			'downloads.syncRuleAccessDenied' => 'Giriş rədd edildi',
			'downloads.syncRuleNotAvailableForProfile' => 'Cari profil üçün əlçatan deyil',
			'downloads.syncRuleUnknownServer' => 'Bilinməyən server',
			'downloads.syncRuleListCreated' => 'Eyniləşdirmə qaydası yaradıldı',
			'downloads.backgroundWarning.bannerBlocked' => 'Tətbiqdən çıxdıqda yükləmələr dayanacaq',
			'downloads.backgroundWarning.bannerDegraded' => 'Arxa fonda yükləmələr məhdudlaşdırıla bilər',
			'downloads.backgroundWarning.bannerAction' => 'Ətraflı',
			'downloads.backgroundWarning.sheetTitle' => 'Arxa fonda yükləmələr bloklanıb',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Arxa fonda yükləmələr məhdudlaşdırıla bilər',
			'downloads.backgroundWarning.sheetIntro' => 'Android PlezyNG-nin arxa fonda etibarlı şəkildə yükləməsinə mane olur.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Cihazınız PlezyNG-nin arxa fonda nə vaxt yükləyə biləcəyini məhdudlaşdırır.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'PlezyNG-nin arxa fon istifadəsi məhdudlaşdırılıb. Batareya və ya arxa fon istifadəsini "Məhdudiyyətsiz" edin.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android PlezyNG-ni məhdud gözləmə rejiminə salıb. Batareya istifadəsini "Məhdudiyyətsiz" edin.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Yükləmə bildirişləri söndürülüb, ona görə gedişat və idarəetmələr əlçatan olmaya bilər.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Bildirişlər söndürülüb. Android 13 və daha yeni versiyalarda uzun arxa fon yükləmələri üçün onlar tələb olunur.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver aktivdir və bu, mobil internetdə arxa fon yükləmələrini bloklayır. Wi-Fi ilə yükləmələr işləməlidir.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'PlezyNG arxa fonda olarkən yükləmələr dəfələrlə dayandı. PlezyNG-nin batareya və ya arxa fon istifadəsi tənzimləmələrini yoxlayın.',
			'downloads.backgroundWarning.openSettings' => 'Tənzimləmələri aç',
			'downloads.backgroundWarning.stillNotWorking' => 'Cihaza özəl kömək',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Cihazınız üçün addımlara baxın və ya problem davam edərsə Tənzimləmələr › Jurnallara bax bölməsindən jurnal göndərin.',
			'downloads.backgroundWarning.dialogTitle' => 'Yükləmələr tamamlanmaya bilər',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Yenə də yüklə',
			'downloads.backgroundWarning.dialogFixFirst' => 'Əvvəlcə bunu düzəlt',
			'downloads.backgroundWarning.statusTile' => 'Arxa fonda yükləmələr',
			'downloads.backgroundWarning.statusOk' => 'Arxa fonda işləməyə icazə verilir',
			'downloads.backgroundWarning.statusBlocked' => 'Sistem tənzimləmələri ilə bloklanıb',
			'downloads.backgroundWarning.statusDegraded' => 'Sistem tənzimləmələri ilə məhdudlaşdırılıb',
			'downloads.backgroundWarning.statusUnknown' => 'Hələ yoxlanılmayıb',
			'downloads.backgroundWarning.settingsUnavailable' => 'Bu cihazda sistem tənzimləmələri açıla bilmədi',
			'downloads.backgroundWarning.linkUnavailable' => 'Bu cihazda dontkillmyapp.com açıla bilmədi',
			'downloads.options' => 'Yükləmə seçimləri',
			'downloads.groupings.library' => 'Kitabxana',
			'downloads.groupings.collections' => 'Kolleksiyalar',
			'downloads.unknownLibrary' => 'Məlum olmayan kitabxana',
			'downloads.unknownShow' => 'Məlum olmayan serial',
			'downloads.unknownSeason' => 'Məlum olmayan mövsüm',
			'downloads.unknownAlbum' => 'Məlum olmayan albom',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} tamamlandı',
			'downloads.storageUsed' => ({required Object size}) => 'Kullanılan qapı: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} endirmə', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} endirmə', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} xəbərlər', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} izləyir', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmləri', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmlər', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albom', ), 
			'downloads.errorFileNotFound' => 'Fayl tapılmadı (404)',
			'downloads.errorDownloadNotAllowed' => 'Server yükləməyə icazə vermir (403)',
			'downloads.errorDownloadFailed' => 'Yükləmə uğursuz oldu',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Yükləmə uğursuz oldu: ${reason}',
			'downloads.convertingOnServer' => 'Servisə dönüştürülüb.',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Sunucuya dönüşüm · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Yükləmə uğursuz oldu (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Sonrakı emal uğursuz oldu: ${reason}',
			'downloads.reasonFileNotSaved' => 'fayl bu cihazda saxlanıla bilmədi',
			'downloads.reasonCannotResume' => 'yarımçıq yükləməni davam etdirmək mümkün olmadı',
			'downloads.reasonDeviceStorageFull' => 'bu cihazda yer qalmayıb',
			'downloads.notificationDownloading' => 'Yüklənir...',
			'downloads.notificationComplete' => 'Yükləmə tamamlandı',
			'downloads.notificationPaused' => 'Yükləmə dayandırıldı',
			'shaders.title' => 'Şeyderlər',
			'shaders.noShaderDescription' => 'Video təkmilləşdirməsi yoxdur',
			'shaders.nvscalerDescription' => 'Daha kəskin video üçün NVIDIA miqyaslaması',
			'shaders.artcnnVariantNeutral' => 'Neytral',
			'shaders.artcnnVariantDenoise' => 'Küyün aradan qaldırılması',
			'shaders.artcnnVariantDenoiseSharpen' => 'Küyün aradan qaldırılması + Kəskinləşdirmə',
			'shaders.qualityFast' => 'Sürətli',
			'shaders.qualityHQ' => 'Yüksək keyfiyyət',
			'shaders.mode' => 'Rejim',
			'shaders.importShader' => 'Şeyder idxal et',
			'shaders.customShaderDescription' => 'Xüsusi GLSL şeyderi',
			'shaders.shaderImported' => 'Şeyder idxal edildi',
			'shaders.shaderImportFailed' => 'Şeyder idxal edilə bilmədi',
			'shaders.deleteShader' => 'Şeyderi sil',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}" silinsin?',
			'companionRemote.title' => 'Köməkçi pult',
			'companionRemote.connectedTo' => ({required Object name}) => '${name} cihazına qoşuldu',
			'companionRemote.unknownDevice' => 'Bilinməyən cihaz',
			'companionRemote.session.startingServer' => 'Pult serveri başladılır...',
			'companionRemote.session.hostAddress' => 'Əsas cihaz ünvanı',
			'companionRemote.session.connected' => 'Qoşuldu',
			'companionRemote.session.serverRunning' => 'Pult serveri aktivdir',
			'companionRemote.session.serverStopped' => 'Pult serveri dayandırıldı',
			'companionRemote.session.serverRunningDescription' => 'Şəbəkənizdəki mobil cihazlar qoşula bilər',
			'companionRemote.session.serverStoppedDescription' => 'Mobil cihazların qoşulmasına icazə vermək üçün serveri başladın',
			'companionRemote.session.usePhoneToControl' => 'Bu tətbiqi idarə etmək üçün mobil cihazınızı istifadə edin',
			'companionRemote.session.startServer' => 'Serveri başlat',
			'companionRemote.session.stopServer' => 'Serveri dayandır',
			'companionRemote.session.minimize' => 'Yığ',
			'companionRemote.session.manualAddressHint' => 'Əl ilə bağlantı ünvanı:',
			'companionRemote.pairing.discoveryDescription' => 'Eyni Plex hesabına sahib PlezyNG cihazları burada görünür',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Qoşulunur...',
			'companionRemote.pairing.searchingForDevices' => 'Cihazlar axtarılır...',
			'companionRemote.pairing.noDevicesFound' => 'Şəbəkənizdə cihaz tapılmadı',
			'companionRemote.pairing.noDevicesHint' => 'Masaüstündə PlezyNG-ni açın və eyni Wi-Fi-dan istifadə edin',
			'companionRemote.pairing.availableDevices' => 'Əlçatan cihazlar',
			'companionRemote.pairing.manualConnection' => 'Əl ilə qoşulma',
			'companionRemote.pairing.cryptoInitFailed' => 'Təhlükəsiz qoşulma başladılarkən xəta. Əvvəlcə Plex-ə daxil olun.',
			'companionRemote.pairing.validationHostRequired' => 'Lütfən əsas cihaz ünvanını daxil edin',
			'companionRemote.pairing.validationHostFormat' => 'Format IP:port şəklində olmalıdır',
			'companionRemote.pairing.connectionTimedOut' => 'Qoşulma vaxtı bitdi. Hər iki cihazda eyni şəbəkədən istifadə edin.',
			'companionRemote.pairing.sessionNotFound' => 'Cihaz tapılmadı.',
			'companionRemote.pairing.authFailed' => 'Kimlik doğrulanması uğursuz oldu.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Qoşulma uğursuz oldu: ${error}',
			'companionRemote.pairing.codeTitle' => 'Çiftlik kodları',
			'companionRemote.pairing.codeDescription' => 'Bu barədə “Müslər” və “Müllər” adlı kitabın yazdığı “Müssər” adlı versiyonu yazıb.',
			'companionRemote.pairing.codeInvalid' => 'Bütün 32 sayı və sayıları ev kodundan girin.',
			'companionRemote.pairing.updateRequired' => 'İki cihazı da güvenli çifti destekleyen versiyona güncələ bilər.',
			'companionRemote.pairing.hostDescription' => 'Bu kodu bir dəfə hər bir yoldan daxil edin. gizli tutun: bu profilin kontrolünü sağlar.',
			'companionRemote.pairing.resetCode' => 'Xatırılan kodlar',
			'companionRemote.pairing.resetDescription' => 'Hər bir qalıqın yeni bir kod yaratır və hər bir qalıqın yeni bir kod yaratır.',
			'companionRemote.remote.disconnectConfirm' => 'Pult seansından ayrılmaq istəyirsiniz?',
			'companionRemote.remote.reconnecting' => 'Yenidən qoşulunur...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Cəhd ${current} / 5',
			'companionRemote.remote.retryNow' => 'İndi təzədən cəhd et',
			'companionRemote.remote.tabRemote' => 'Pult',
			'companionRemote.remote.tabPlay' => 'Oynat',
			'companionRemote.remote.tabMore' => 'Daha çox',
			'companionRemote.remote.menu' => 'Menyu',
			'companionRemote.remote.tabNavigation' => 'Naviqasiya',
			'companionRemote.remote.tabDiscover' => 'Kəşf et',
			'companionRemote.remote.tabLibraries' => 'Kitabxanalar',
			'companionRemote.remote.tabSearch' => 'Axtar',
			'companionRemote.remote.tabDownloads' => 'Yükləmələr',
			'companionRemote.remote.tabSettings' => 'Tənzimləmələr',
			'companionRemote.remote.previous' => 'Əvvəlki',
			'companionRemote.remote.playPause' => 'Oynat/Fasilə',
			'companionRemote.remote.next' => 'Növbəti',
			'companionRemote.remote.seekBack' => 'Geri sar',
			'companionRemote.remote.stop' => 'Saxla',
			'companionRemote.remote.seekForward' => 'İrəli sar',
			'companionRemote.remote.volume' => 'Səs',
			'companionRemote.remote.volumeDown' => 'Azalt',
			'companionRemote.remote.volumeUp' => 'Artır',
			'companionRemote.remote.fullscreen' => 'Tam ekran',
			'companionRemote.remote.subtitles' => 'Altyazılar',
			'companionRemote.remote.audio' => 'Səs',
			'companionRemote.remote.searchHint' => 'Masaüstündə axtar...',
			'companionRemote.errors.noNetworkInterface' => 'Şəbəkə interfeysi tapılmadı',
			'companionRemote.errors.authenticationFailed' => 'Kimlik doğrulanması uğursuz oldu',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Pult serveri başladıla bilmədi: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Pult əmri göndərilə bilmədi: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Seansa qoşulma vaxtı bitdi',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Heç bir ünvana qoşuluna bilmədi',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts} cəhddən sonra əlaqə kəsildi',
			'companionRemote.errors.connectionLost' => 'Əlaqə kəsildi',
			'companionRemote.closedBeforeAuth' => 'Bağlantı autentifikasiyadan əvvəl bağlandı',
			'videoSettings.playbackSpeed' => 'Oynatma sürəti',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktivdir (${duration})',
			'videoSettings.zoom' => 'Miqyas',
			'videoSettings.sleepTimer' => 'Yuxu taymeri',
			'videoSettings.audioSync' => 'Səs sinxronizasiyası',
			'videoSettings.subtitleSync' => 'Altyazı sinxronizasiyası',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR burada əlçatan deyil — bu masaüstü kompozitoru və ya video çıxışı onu ötürə bilmir.',
			'videoSettings.hdrToneMapping' => 'HDR ton uyğunlaşdırması',
			'videoSettings.hdrToneMappingCompositor' => 'Kompozitor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Mənbənin HDR metaməlumatlarını dəyişmədən ötür və ton uyğunlaşdırmasını masaüstü kompozitoruna həvalə et.',
			'videoSettings.hdrToneMappingPlayer' => 'Oynadıcı',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Oynadıcıda tonları ekranın pik parlaqlığına uyğunlaşdır, sonra nəticəni kompozitora bildir.',
			'videoSettings.hdrToneMappingFailed' => 'HDR ton uyğunlaşdırmasını dəyişmək olmadı — əvvəlki rejim hələ də aktivdir.',
			'videoSettings.audioOutput' => 'Səs çıxışı',
			'videoSettings.videoTrack' => 'Video treki',
			'videoSettings.videoTrackDescription' => 'Göstəriləcək video axınını seçin. Faylda alternativ video trekləri olduqda MPV oynadılmasında mövcuddur.',
			'videoSettings.videoTrackDefault' => 'Standart',
			'videoSettings.videoTrackUnavailable' => 'Alternativ video treki yoxdur.',
			'videoSettings.videoTrackFailed' => 'Video trekini dəyişmək mümkün olmadı.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'Trek ${id}',
			'videoSettings.performanceOverlay' => 'Məhsuldarlıq paneli',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Əhatəli səs',
			'videoSettings.audioOutputSpatial' => 'Məkan səsi',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio düzəltmə',
			'videoSettings.audioEqualizerDescription' => 'MPV üçün 10 zolaqlı ekvalayzer. Audio filtrləri dekodlaşdırılmış səsdən istifadə edir və ötürməni söndürür.',
			'videoSettings.audioEqualizerFlat' => 'Düz',
			'videoSettings.audioEqualizerActive' => 'Xüsusi',
			'videoSettings.audioEqualizerSaveFailed' => 'Audio equalizer ayarları saxlayamazdı.',
			'videoSettings.audioEffectsDescription' => 'Effektlər dekodlaşdırılmış səsdən istifadə edir, buna görə birbaşa ötürmə söndürülür. Otaq əks-sədası və stereo genişləndirməsi MPV quruluşundan və trekdən asılıdır.',
			'videoSettings.audioStereoWidth' => 'Stereo genişləndirmə',
			'videoSettings.audioSpatializer' => 'Otaq mühiti',
			'videoSettings.audioSpatializerDescription' => 'Yüngül otaq əks-sədası əlavə et.',
			'videoSettings.audioPitch' => 'Tonun dəyişdirilməsi',
			'videoSettings.audioPitchDescription' => 'Sürəti dəyişmədən tonu dəyişin. MPV quruluşunda Rubber Band olmalıdır.',
			'videoSettings.audioEffectUnavailable' => 'Bu effekt bu trek və ya MPV quruluşu üçün əlçatan deyil.',
			'videoSettings.backgroundVideoAudio' => 'Video və Audio',
			'videoSettings.backgroundVideoAudioDescription' => 'Videoya oyunun oynamaq üçün oynamaq üçün videoya oyunun oyuncusu çıxırsanız qalandır. xilasın geri qayıtılana qədər gizlidir. Android bir medya oynamaq bildirimi kullanır.',
			'videoSettings.audioNormalization' => 'Səsin gurluğunu normallaşdır',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Səsi PCM-ə dekodlayır; bu aktivkən birbaşa ötürmə söndürülür',
			'performanceOverlay.color' => 'Rəng',
			'performanceOverlay.performance' => 'Məhsuldarlıq',
			'performanceOverlay.buffer' => 'Bufer',
			'performanceOverlay.app' => 'Tətbiq',
			'performanceOverlay.decoder' => 'Çözücü',
			'performanceOverlay.rawDecoder' => 'Xam çözücü',
			'performanceOverlay.tunneling' => 'Tünelləmə',
			'performanceOverlay.passthrough' => 'Birbaşa ötürmə',
			'performanceOverlay.aspect' => 'Nisbət',
			'performanceOverlay.rotation' => 'Dönmə',
			'performanceOverlay.dvSource' => 'DV mənbəyi',
			'performanceOverlay.dvPath' => 'DV yolu',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision çözücüsü',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision çözücüsü (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Baza təbəqə',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 baza təbəqə',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG baza təbəqə',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR baza təbəqə',
			'performanceOverlay.dvRouteReshaped' => 'RPU ilə yenidən formalaşdırılıb (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Eksperimental P7 FEL grafik (kalifikatə olmayan)',
			'performanceOverlay.p7Conversion' => 'P7 çevrilməsi',
			'performanceOverlay.sampleRate' => 'Diskretləşdirmə tezliyi',
			'performanceOverlay.pixelFormat' => 'Piksel formatı',
			'performanceOverlay.hwFormat' => 'HW formatı',
			'performanceOverlay.matrix' => 'Matrisa',
			'performanceOverlay.primaries' => 'Əsas rənglər',
			'performanceOverlay.transfer' => 'Ötürmə',
			'performanceOverlay.renderFps' => 'Emal FPS-i',
			'performanceOverlay.displayFps' => 'Ekran FPS-i',
			'performanceOverlay.avSync' => 'A/V Eyniləşdirilməsi',
			'performanceOverlay.dropped' => 'İtirilmiş kadrlar',
			'performanceOverlay.dvRpus' => 'DV RPU-ları',
			'performanceOverlay.dvRpuAverage' => 'DV RPU Ort.',
			'performanceOverlay.dvSampleAverage' => 'DV Nümunə Ort.',
			'performanceOverlay.maxLuma' => 'Maks Luma',
			'performanceOverlay.minLuma' => 'Min Luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'İstifadə olunan keş',
			'performanceOverlay.cacheLimit' => 'Keş limiti',
			'performanceOverlay.speed' => 'Sürət',
			'performanceOverlay.player' => 'Oynadıcı',
			'performanceOverlay.playMethod' => 'Oyun metodları',
			'performanceOverlay.memory' => 'Yaddaş',
			'performanceOverlay.uiFps' => 'Arayüz (UI) FPS-i',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Proqram təminatı',
			'performanceOverlay.decoderHardware' => 'Aparat təminatı',
			'performanceOverlay.tunnelingActive' => 'Aktiv',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} uğursuz)',
			'externalPlayer.title' => 'Xarici oynadıcı',
			'externalPlayer.useExternalPlayer' => 'Xarici oynadıcı istifadə et',
			'externalPlayer.useExternalPlayerDescription' => 'Videoları başqa tətbiqdə açın',
			'externalPlayer.selectPlayer' => 'Oynadıcı seç',
			'externalPlayer.customPlayers' => 'Xüsusi oynadıcılar',
			'externalPlayer.systemDefault' => 'Sistem defoltu',
			'externalPlayer.addCustomPlayer' => 'Xüsusi oynadıcı əlavə et',
			'externalPlayer.playerName' => 'Oynadıcı adı',
			'externalPlayer.playerNameHint' => 'Mənim oynadıcım',
			'externalPlayer.playerCommand' => 'Əmr',
			'externalPlayer.playerPackage' => 'Paket adı',
			'externalPlayer.playerUrlScheme' => 'URL sxemi',
			'externalPlayer.off' => 'Söndürülüb',
			'externalPlayer.launchFailed' => 'Xarici oynadıcı açıla bilmədi',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} quraşdırılmayıb',
			'externalPlayer.playInExternalPlayer' => 'Xarici oynadıcıda oynat',
			'externalPlayer.description' => 'Video açmaq üçün başka bir proqram seçin. mevcut oyuncular cihazınıza və yüklü uygulamalarına bağlıdır.',
			'externalPlayer.systemDefaultDescription' => 'Operasiya sisteminin default app ilə video açmasına izin verin.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => '${player} ilə video açın.',
			'externalPlayer.playerNameDescription' => 'Oyunçı listəsində göstərən etiket.',
			'externalPlayer.playerPackageDescription' => '“Android” paketinin adı, oyuncu proqramının adı, örneğin com.example.player kimi girin.',
			'externalPlayer.playerCommandDescription' => 'Bu cihazın yüklü oyuncu komandası və ya yürütülebilir yolunu girin.',
			'externalPlayer.playerUrlSchemeDescription' => 'URL şeması və oyuncu başlatmaq üçün kullanılan seçici URL şablonu girin.',
			'metadataEdit.editMetadata' => 'Düzəliş et...',
			'metadataEdit.screenTitle' => 'Meta-məlumatlara düzəliş et',
			'metadataEdit.basicInfo' => 'Əsas məlumatlar',
			'metadataEdit.artwork' => 'Şəkillər/Posterlər',
			'metadataEdit.advancedSettings' => 'Təkmilləşdirilmiş tənzimləmələr',
			'metadataEdit.title' => 'Başlıq',
			'metadataEdit.sortTitle' => 'Sıralama başlığı',
			'metadataEdit.originalTitle' => 'Orijinal başlıq',
			'metadataEdit.releaseDate' => 'Buraxılış tarixi',
			'metadataEdit.contentRating' => 'Məzmun reytinqi',
			'metadataEdit.studio' => 'Studiya',
			'metadataEdit.tagline' => 'Deviz/Slogan',
			'metadataEdit.summary' => 'Məzmun/Xülasə',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Arxa fon',
			'metadataEdit.logo' => 'Loqo',
			'metadataEdit.squareArt' => 'Kvadrat şəkil',
			'metadataEdit.selectPoster' => 'Poster seç',
			'metadataEdit.selectBackground' => 'Arxa fon seç',
			'metadataEdit.selectLogo' => 'Loqo seç',
			'metadataEdit.selectSquareArt' => 'Kvadrat şəkil seç',
			'metadataEdit.fromUrl' => 'URL-dən',
			'metadataEdit.uploadFile' => 'Fayl yüklə',
			'metadataEdit.enterImageUrl' => 'Şəkil URL-i daxil edin',
			'metadataEdit.imageUrl' => 'Şəkil URL-i',
			'metadataEdit.metadataUpdated' => 'Meta-məlumatlar yeniləndi',
			'metadataEdit.metadataUpdateFailed' => 'Meta-məlumatlar yenilənə bilmədi',
			'metadataEdit.artworkUpdated' => 'Şəkillər yeniləndi',
			'metadataEdit.artworkUpdateFailed' => 'Şəkillər yenilənə bilmədi',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.noArtworkAvailable' => 'Şəkil əlçatan deyil',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Şəkil seçimi ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Şəkil seçimi ${index}, seçildi',
			'metadataEdit.notSet' => 'Təyin edilməyib',
			'metadataEdit.libraryDefault' => 'Kitabxana defoltu',
			'metadataEdit.accountDefault' => 'Hesab defoltu',
			'metadataEdit.seriesDefault' => 'Serial defoltu',
			'metadataEdit.episodeSorting' => 'Seriya sıralaması',
			'metadataEdit.oldestFirst' => 'Əvvəlcə ən köhnə',
			'metadataEdit.newestFirst' => 'Əvvəlcə ən yeni',
			'metadataEdit.keep' => 'Saxla',
			'metadataEdit.allEpisodes' => 'Bütün seriyalar',
			'metadataEdit.latestEpisodes' => ({required Object count}) => 'Ən son ${count} seriya',
			'metadataEdit.latestEpisode' => 'Ən son seriya',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Son ${count} gündə əlavə olunan seriyalar',
			'metadataEdit.deleteAfterPlaying' => 'Oynatdıqdan sonra seriyaları sil',
			'metadataEdit.never' => 'Heç vaxt',
			'metadataEdit.afterADay' => 'Bir gün sonra',
			'metadataEdit.afterAWeek' => 'Bir həftə sonra',
			'metadataEdit.afterAMonth' => 'Bir ay sonra',
			'metadataEdit.onNextRefresh' => 'Növbəti yenilənmədə',
			'metadataEdit.seasons' => 'Mövsümlər',
			'metadataEdit.show' => 'Göstər',
			'metadataEdit.hide' => 'Gizlət',
			'metadataEdit.episodeOrdering' => 'Seriya ardıcıllığı',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Yayımlanma)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Yayımlanma)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Mütləq)',
			'metadataEdit.metadataLanguage' => 'Meta-məlumat dili',
			'metadataEdit.useOriginalTitle' => 'Orijinal başlığı istifadə et',
			'metadataEdit.preferredAudioLanguage' => 'Üstünlük verilən səs dili',
			'metadataEdit.preferredSubtitleLanguage' => 'Üstünlük verilən altyazı dili',
			'metadataEdit.subtitleMode' => 'Avtomatik altyazı seçim rejimi',
			'metadataEdit.manuallySelected' => 'Əl ilə seçilmiş',
			'metadataEdit.shownWithForeignAudio' => 'Xarici səs olduqda göstərilən',
			'metadataEdit.alwaysEnabled' => 'Həmişə aktivdir',
			'metadataEdit.tags' => 'Teqlər',
			'metadataEdit.addTag' => 'Teq əlavə et',
			'metadataEdit.genre' => 'Janr',
			'metadataEdit.director' => 'Rejissor',
			'metadataEdit.writer' => 'Ssenarist',
			'metadataEdit.producer' => 'Prodüser',
			'metadataEdit.country' => 'Ölkə',
			'metadataEdit.collection' => 'Kolleksiya',
			'metadataEdit.label' => 'Etiket',
			'metadataEdit.quickTag' => 'Sürətli etiket...',
			'matchScreen.match' => 'Uyğunlaşdır...',
			'matchScreen.fixMatch' => 'Uyğunluğu düzəlt...',
			'matchScreen.unmatch' => 'Uyğunluğu ləğv et',
			'matchScreen.unmatchConfirm' => 'Bu uyğunluq təmizlənsin? Yenidən uyğunlaşdırılana qədər Plex onu uyğunlaşdırılmamış sayacaq.',
			'matchScreen.unmatchSuccess' => 'Element uyğunluğu ləğv edildi',
			'matchScreen.unmatchFailed' => 'Uyğunluq ləğv edilə bilmədi',
			'matchScreen.matchApplied' => 'Uyğunluq tətbiq edildi',
			'matchScreen.matchFailed' => 'Uyğunluq tətbiq edilə bilmədi',
			'matchScreen.titleHint' => 'Ad',
			'matchScreen.yearHint' => 'İl',
			'matchScreen.search' => 'Axtar',
			'matchScreen.noMatchesFound' => 'Uyğunluq tapılmadı',
			'serverTasks.title' => 'Server tapşırıqları',
			'serverTasks.failedToLoad' => 'Tapşırıqlar yüklənə bilmədi',
			'serverTasks.noTasks' => 'İcra olunan tapşırıq yoxdur',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Qoşuldu',
			'trakt.connectedAs' => ({required Object username}) => '@${username} olaraq qoşuldu',
			'trakt.disconnectConfirm' => 'Trakt hesabı ayırılsın?',
			'trakt.disconnectConfirmBody' => 'PlezyNG Trakt-a məlumat göndərməyi dayandıracaq.',
			'trakt.scrobble' => 'Real vaxt rejimində izləmə',
			'trakt.scrobbleDescription' => 'Oynatma zamanı Trakt-a məlumat göndər.',
			'trakt.watchedSync' => 'Baxış statusunu eyniləşdir',
			'trakt.watchedSyncDescription' => 'PlezyNG-də baxıldı işarələdikdə Trakt-da da işarələnsin.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr qoş',
			'seerr.serverUrl' => 'Server URL-i',
			'seerr.serverUrlHelper' => 'Seerr ünvanınız',
			'seerr.checkServer' => 'Davam et',
			'seerr.signInWithJellyfin' => 'Jellyfin ilə daxil ol',
			'seerr.signInWithEmby' => 'Emby ilə daxil ol',
			'seerr.signInWithLocal' => 'Yerli hesab istifadə et',
			'seerr.email' => 'E-poçt',
			'seerr.noSignInMethods' => 'Bu Seerr dəstəklənən daxil olma üsulu təklif etmir.',
			'seerr.instance' => 'Nüsxə',
			'seerr.disconnectConfirm' => 'Seerr ayırılsın?',
			'seerr.disconnectConfirmBody' => 'PlezyNG bu Seerr serverini unudacaq. İstənilən vaxt yenidən qoşula bilərsiniz.',
			'seerr.request' => 'Sorğu göndər',
			'seerr.request4k' => '4K sorğu göndər',
			'seerr.seasons' => 'Mövsümlər',
			'seerr.allSeasons' => 'Bütün mövsümlər',
			'seerr.advancedOptions' => 'Təkmilləşdirilmiş',
			'seerr.destinationServer' => 'Hədəf server',
			'seerr.qualityProfile' => 'Keyfiyyət profili',
			'seerr.rootFolder' => 'Kök qovluq',
			'seerr.languageProfile' => 'Dil profili',
			'seerr.tags' => 'Teqlər',
			'seerr.noTags' => 'Teq yoxdur',
			'seerr.defaultOption' => ({required Object name}) => '${name} (Defolt)',
			'seerr.animeNote' => 'Bu serial animedir.',
			'seerr.requestSubmitted' => 'Sorğu göndərildi',
			'seerr.requestFailed' => ({required Object error}) => 'Sorğu uğursuz oldu: ${error}',
			'seerr.requestsLoadFailed' => 'Seçimlər yüklənə bilmədi',
			'seerr.nothingToRequest' => 'Hər şey artıq var və ya sorğu göndərilib.',
			'seerr.statusAvailable' => 'Əlçatandır',
			'seerr.statusPartiallyAvailable' => 'Hissəvi əlçatandır',
			'seerr.statusRequested' => 'Sorğu göndərildi',
			'seerr.statusProcessing' => 'Emal edilir',
			'seerr.statusBlocklisted' => 'Bloklanmış',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url} ünvanına çatmaq olmadı: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => '${url} ünvanında Seerr instansiyası yoxdur (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Seerr əvəzinə autentifikasiya edən tərs proksi (SSO və ya HTTP auth) cavab verdi. PlezyNG onun vasitəsilə daxil ola bilmir: bu tətbiq üçün Seerr-in /api/v1 yolunun proksini yan keçməsinə icazə verin və ya Seerr-ə birbaşa çatan ünvan istifadə edin.',
			'seerr.invalidUrl' => 'https://seerr.example.com kimi server ünvanı daxil edin',
			'seerr.quickConnectUnsupported' => 'Bu Seerr nüsxəsi Sürətli Qoşulmanı dəstəkləmir. Seerr 3.4 və ya daha yeni versiya tələb olunur.',
			'seerr.notInitialized' => 'Bu Seerr instansiyasının ilkin quraşdırılması tamamlanmayıb',
			'seerr.noPlexTokenForReauth' => 'Yenidən daxil olmaq üçün Plex tokeni mövcud deyil',
			'seerr.noStoredCredentials' => 'Yenidən daxil olmaq üçün yadda saxlanmış giriş məlumatları mövcud deyil',
			'seerr.signInRejected' => 'Daxil olma rədd edildi',
			'seerr.noSessionCookie' => 'Seerr sessiya kukisi yaratmadı',
			'seerr.freshCookieRejected' => 'Seerr yeni sessiya kukisini rədd etdi',
			'seerr.noUserInformation' => 'Seerr istifadəçi məlumatlarını qaytarmadı',
			'seerr.sessionRejectedAfterReauth' => 'Yenidən daxil olduqdan sonra sessiya rədd edildi',
			'seerr.permissionDenied' => 'Seerr bu əməliyyatı rədd etdi: hesabınızda artıq tələb olunan icazə yoxdur',
			'seerr.permissionRevoked' => 'Bunu sorğulamaq üçün artıq icazəniz yoxdur',
			'services.title' => 'Xidmətlər',
			'services.hubSubtitle' => 'İzləmə tərəqqisini eyniləşdirin və yeni başlıqlar sorğulayın.',
			'services.integrations' => 'İnteqrasiyalar',
			'services.notConnected' => 'Qoşulmayıb',
			'services.connectedAs' => ({required Object username}) => '@${username} olaraq qoşuldu',
			'services.scrobble' => 'Tərəqqini avtomatik izlə',
			'services.scrobbleDescription' => 'Bir epizodu və ya filmi bitirdikdə siyahınızı yeniləyin.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} ayırılsın?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG ${service} yeniləməyi dayandıracaq. İstənilən vaxt yenidən qoşula bilərsiniz.',
			'services.connectFailed' => ({required Object service}) => '${service} qoşula bilmədi. Təzədən cəhd edin.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Simkl-ə yenidən qoşul',
			'services.simklReconnect.subtitle' => 'Simkl bu bağlantının istifadə etdiyi daxil olma üsulunu ləğv edir. Yenidən qoşulduqda PlezyNG-ni təsdiqləmək üçün simkl.com açılır — PlezyNG parolunuzu heç vaxt görmür. Baxış tarixçəniz Simkl-də qalır.',
			'services.deviceCode.title' => ({required Object service}) => 'PlezyNG-ni ${service} üzərində aktivləşdirin',
			'services.deviceCode.instructions' => 'QR kodunu skan edin və ya aşağıdakı ünvana keçib bu kodu daxil edin:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Aktivləşdirmək üçün ${service} açın',
			'services.deviceCode.copyCode' => 'Aktivləşdirmə kodunu kopyala',
			'services.deviceCode.waitingForAuthorization' => 'Səlahiyyət gözlənilir…',
			'services.deviceCode.codeCopied' => 'Kod kopyalandı',
			'services.oauthProxy.title' => ({required Object service}) => '${service} xidmətinə daxil olun',
			'services.oauthProxy.body' => 'Bu QR kodu skan edin və ya URL-i açın.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Daxil olmaq üçün ${service} açın',
			'services.pendingAuth.copyUrl' => 'Daxil olma URL-ini kopyala',
			'services.pendingAuth.urlCopied' => 'URL kopyalandı',
			'services.libraryFilter.title' => 'Kitabxana filtri',
			'services.libraryFilter.subtitleAllSyncing' => 'Bütün kitabxanalar eyniləşdirilir',
			'services.libraryFilter.subtitleNoneSyncing' => 'Heç nə eyniləşdirilmir',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloklandı',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} icazə verildi',
			'services.libraryFilter.mode' => 'Filtr rejimi',
			'services.libraryFilter.modeBlacklist' => 'Qara siyahı',
			'services.libraryFilter.modeWhitelist' => 'Ağ siyahı',
			'services.libraryFilter.modeHintBlacklist' => 'Aşağıda seçilənlərdən başqa bütün kitabxanaları eyniləşdir.',
			'services.libraryFilter.modeHintWhitelist' => 'Yalnız aşağıda seçilən kitabxanaları eyniləşdir.',
			'services.libraryFilter.libraries' => 'Kitabxanalar',
			'services.libraryFilter.noLibraries' => 'Kitabxana yoxdur',
			'services.libraryFilter.modeDescription' => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.',
			'services.seerrDescription' => '“Seerr” və ya “Overseerr” ilə bağlanın, başlıklar aradan və medya talepləri gönderin.',
			'services.trackerDescriptions.trakt' => 'Filmlər və filmləri hesabınızla eşlik edin.',
			'services.trackerDescriptions.mal' => 'Anime listləri və MyAnimeList ilə progresə baxın.',
			'services.trackerDescriptions.anilist' => 'Anime listləri və AniList ilə ilerlemeyi izləyin.',
			'services.trackerDescriptions.simkl' => 'Simkl ilə filmlər, televiziyalar və anime izledi.',
			'services.trackerDescriptions.mdblist' => 'MDBList ratings və listləri rekomandasyonlarda və Explore-da görünür.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '${product} serveri əlavə et',
			'addServer.serverUrls' => 'Server URL-ləri',
			'addServer.serverUrlsHelper' => 'Vergüllə ayrılmış bir neçə URL-ə icazə verilir.',
			'addServer.findServer' => 'Server tap',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Yerli ${product} serverləri axtarılır...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Yerli ${product} serverləri',
			'addServer.username' => 'İstifadəçi adı',
			'addServer.password' => 'Şifrə',
			'addServer.signIn' => 'Daxil ol',
			'addServer.change' => 'Dəyişdir',
			'addServer.required' => 'Tələb olunur',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Serverə çatmaq olmadı: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Daxil olma uğursuz oldu: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Sürətli Qoşulma uğursuz oldu: ${error}',
			'addServer.addPlexTitle' => 'Plex ilə daxil ol',
			'addServer.pinExpired' => 'PIN-in vaxtı bitdi. Lütfən təzədən cəhd edin.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Hesab qeydiyyatı uğursuz oldu: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => '${product} server URL-inizi daxil edin',
			'addServer.addConnectionTitle' => 'Qoşulma əlavə et',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name} profilinə əlavə et',
			'addServer.signInWithPlexCard' => 'Plex ilə daxil ol',
			'addServer.signInWithPlexCardSubtitle' => 'Bu cihazı səlahiyyətləndirin. Paylaşılan serverlər əlavə olunur.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex hesabını səlahiyyətləndirin. Home istifadəçiləri profillərə çevrilir.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => '${product}-a qoşul',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Server URL-inizi, istifadəçi adınızı və şifrənizi daxil edin.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => '${product} serverinizə daxil olun. ${name} ilə əlaqələndirilir.',
			'addServer.borrowFromAnotherProfile' => 'Başqa profildən götür',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Başqa profilin qoşulmasını yenidən istifadə edin. PIN ilə qorunan profillər PIN tələb edir.',
			'addServer.invalidCredentials' => 'İstifadəçi adı və ya şifrə yanlışdır',
			'addServer.authResponseNotJson' => 'Autentifikasiya cavabı etibarlı JSON deyildi',
			'addServer.authResponseIncomplete' => 'Serverin giriş cavabı natamam idi',
			'addServer.quickConnectRejected' => 'Quick Connect server tərəfindən rədd edildi',
			'addServer.quickConnectNotJson' => 'Quick Connect cavabı etibarlı JSON deyildi',
			'addServer.quickConnectMissingFields' => 'Quick Connect cavabında kod və ya məxfi açar yoxdur',
			'addServer.quickConnectPollRejected' => 'Quick Connect sorğulaması server tərəfindən rədd edildi',
			'addServer.serverTimedOut' => 'Server vaxtında cavab vermədi',
			'addServer.responseNotJson' => 'Server cavabı etibarlı JSON deyildi',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Cavabda ID və ya server adı yoxdur — bu, ${product} serveridir?',
			'addServer.probeFailed' => ({required Object error}) => 'Serverə çatmaq olmadı: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Ən azı bir ${product} server URL-i daxil edin',
			'addServer.noReachableServer' => ({required Object product}) => 'Əlçatan ${product} serveri tapılmadı',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Bu URL-lər fərqli ${product} serverlərinə aiddir',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Bu URL ${product} serverinə uyğun gəlmir',
			'addServer.redirectUnsupported' => 'Server dəstəklənməyən URL-ə yönləndirdi',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Server başqa hosta yönləndirdi. Son ${product} URL-ni birbaşa daxil edin.',
			'addServer.redirectInsecure' => 'Server HTTPS-dən təhlükəsiz olmayan URL-ə yönləndirdi',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Server dəstəklənməyən URL-ə yönləndirdi. Son ${product} URL-ni birbaşa daxil edin.',
			'addServer.directPlexServerUrl' => 'Plex serverinin URL-si',
			'addServer.directPlexServerUrlHelper' => 'Yerel IP və portunu Plex Media Serverinizə daxil edin.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (özümlü)',
			'addServer.plexTokenHelper' => 'Bu serverdə auth olmadan qalıbsa boş bırakın.',
			'addServer.plexTokenRequired' => 'Kimliyin təsdiqlənməsi tələb olunur. Plex tokeninizi (X-Plex-Token) daxil edin.',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (Doğrudan / Yerel)',
			'addServer.connectDirectPlexCardSubtitle' => 'Yerel IP və ya URL hesabı olmadan doğrudan bağlanın.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Yerel IP və ya URL ilə doğrudan bağlayın. ${name} ilə bağlanır.',
			'addServer.insecureTitle' => 'Şifrelə olmayan bağlantı',
			'addServer.insecureDescription' => ({required Object url}) => '${url} HTTP istifadə edir. Şəbəkədəki şəxslər parolunuzu, tokenlərinizi və medianızı oxuya və ya dəyişə bilər. Mümkün olduqda HTTPS istifadə edin. Yalnız bu şəbəkəyə etibar edirsinizsə və riski qəbul edirsinizsə davam edin.',
			'addServer.allowHttp' => 'HTTP-yə icazə ver',
			'addServer.httpsRequired' => 'HTTPS və ya şifrə olmayan bir bağlantı üçün açıq-aydın izin verir.',
			'cast.chooseDevice' => 'Bir cihazın qapısı',
			'cast.searching' => 'Xatırma aparaturları aradan...',
			'cast.connectedTo' => ({required Object device}) => 'Qəzaqə ${device}',
			'cast.device' => 'Xatırma aparatı',
			'cast.readyToCast' => 'Hazır atmaq',
			'cast.subtitle' => 'Altyazılar',
			'cast.serverNotAvailable' => 'Medya serveri yoxdur.',
			'cast.stopCasting' => 'Qısağı durdurma',
			'cast.castToDevice' => 'Təlimə qalıb',
			'cast.noEpisodeAvailable' => 'Bu bölümdə oynamaq mümkün deyil.',
			'cast.startFailed' => 'Yayımı başlatmaq mümkün olmadı. Serveri yoxlayın və yenidən cəhd edin.',
			'automation.noActivePlayback' => 'Video-kontroleyi kontrol etmək mümkün deyil.',
			'notifications.newEpisodeTitle' => 'Yeni epizod',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => '7 gün ərzində hər bir funksiyaya özgürlük göstərin.',
			'appAccess.description' => '7 gün sürən bir testə başlamaq, hər bir PlezyNG funksiyasına tam qapı ilə. testdə heç bir ücret və abonə yoxdur. testdən sonra, mağazanın fiyatında bir ömürlük satın alın, ömürlük PlezyNG kilitlənir.',
			'appAccess.trialEndedDescription' => 'Mağazanızın qiymətinə bir dəfə alış edərək PlezyNG-nin bütün funksiyalarını həmişəlik açın. Abunəlik yoxdur.',
			'appAccess.startTrial' => '7 gün özgür sınavı başlatır',
			'appAccess.trialActive' => '7 gün sürən bütün testiniz aktivdir.',
			'appAccess.trialEnded' => '7 gündən sonra proses bitirir.',
			'appAccess.trialStartFailed' => 'Bu cihazın testini salmaq mümkün deyil. lütfen bir daha çalışın.',
			'appAccess.lifetimeTitle' => 'PlezyNG ömür boyu boşaltılmışdır',
			'appAccess.lifetimeBody' => 'Şükürlər! hər bir PlezyNG funksiyasına lifetime qapı var.',
			'appAccess.manageTitle' => 'PlezyNG Ömür boyu qalıb',
			'appAccess.manageDescription' => 'Hər bir funksiyayı 7 gün üçün özgürlə deneyin, sonra mağazanın fiyatına bir payla hər şeyin ömür boyu kilidini açın.',
			'appAccess.buy' => ({required Object price}) => 'Hər bir funksiya ${price} üçün çalın',
			'appAccess.loadingPrice' => 'Buğdayın fiyatı...',
			'appAccess.retryPrice' => 'Qatırılma fiyatı',
			'appAccess.restore' => 'Ömür boyu satın alın',
			'appAccess.pending' => 'Müəllifinizin ömür boyu qapı və ya qapı ilə bağlı və ya qalanlıqla bağlı və ya hökm və ya qalıqla bağlı və və ya qalınlıqla bağlı bir qapıdır.',
			'appAccess.storeUnavailable' => 'Bu sistemdə satın alınmaq üçün izin verilmə bilər.Bu sistemdə satın alma üçün izin verilməyə bilər.',
			'appAccess.productNotFound' => 'PlezyNG lifetime unlock bu mağazada yet mevcut deyil.',
			'appAccess.productQueryFailed' => 'Bu barədə xəbər verir ki, bu barədə “Global News Network” və “Global News Network” xəbər verir.',
			'appAccess.purchaseFailed' => 'İnşallah bu işə qayıtmayıb.Bir daha baxın.',
			'appAccess.restoreFailed' => 'Mən bu işdən qayıtmaq üçün mağazaya gəlməyirəm.',
			'appAccess.nothingToRestore' => 'Bu mağazanın hesabı üçün PlezyNG ömür boyu satın alınmışdır.',
			'detail.endsAt' => ({required Object time}) => 'Bitiş vaxtı: ${time}',
			'watchLink.serverUnavailable' => 'Bu linki üçün Plex serverə ulaşamazdım.',
			'watchLink.notFound' => 'Bu göstərici və filmi Plex serverinizdə bulamazdım.',
			'watchLink.ambiguous' => 'Bu bağ birdən çox serverdə elementlər ilə eşlik edir.',
			'watchLink.plexOnly' => 'Görüntülər linki şu anda yalnız Plex serverləri destek edir.',
			'watchLink.unsupportedItem' => 'Görüntülənlər yalnız bir film və ya bir göstəri açılabilir.',
			'watchLink.menuItem' => 'Görüntülər Link',
			'watchLink.dialogTitle' => 'Linkə baxın',
			'watchLink.dialogShowHint' => 'Bu linki açmaq bir sonraki epizod oynayır. shuffle-da şov oynamak üçün sonuna &mode=shuffle-i ekdir.',
			'watchLink.dialogMovieHint' => 'Bu linki açmaq filmin oyununu oynayır.',
			'watchLink.copy' => 'Kopya',
			'watchLink.copied' => 'Link kopyalar',
			'homeLayout.title' => 'Evdə Layout',
			'homeLayout.resetToast' => 'Evə qayıdın, orijinal Plezy kahramanı düzəlmə',
			'homeLayout.resetHeroTitle' => 'Plezy-nin standart əsas banner düzənini bərpa etmək istəyirsiniz?',
			'homeLayout.resetHeroBody' => 'Hər bir sıraın kahramanı ayarını devreyar və evin üstündeki tek bir dönən bannerı, daha əvvəl kahramanın sıraları olduğu kimi geri getirir.',
			'homeLayout.removeRowTitle' => 'Evdə qalıb?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} xilas ediləcək.Bu xilas edilemez.',
			'homeLayout.sync' => 'Sünni',
			'homeLayout.syncAccountTitle' => 'Sizin hesabınızla Plex-i işləmək',
			'homeLayout.syncAccountOn' => 'Bu cihaz, sıra sırasını, sıraları, Hero və Auto-slide üçün diğer cihazlarınızla paylaşır.',
			'homeLayout.syncAccountOff' => 'Bu cihazın öz layoutunu saxlayır.',
			'homeLayout.syncNow' => 'Sünnə',
			'homeLayout.plexHomeManager' => 'Plex Ev yöneticisi',
			'homeLayout.managePlexRows' => 'Plezy-də Plex satırları yönetir',
			'homeLayout.managePlexRowsDescription' => 'Evdə seçilmiş yolların organizasiyası üçün açılır',
			'homeLayout.organizeHomeRows' => 'Evdə qalıb',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} sıra: Moving, Hero, Auto-slide, kaldırma',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '${library} yolları organizə edin',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Qiyamış + ${n} sıra: Moving, Library, Home, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Bir kahramanın kartı kimi',
			'homeLayout.heroOnlySingleCollection' => 'Bu sayı yalnız bir koleksiyonun gerçek başlıklarına çözüldüğünde mevcutdır.',
			'homeLayout.hero' => 'Heroya',
			'homeLayout.autoSlide' => 'Auto-Slayt',
			'homeLayout.autoSlideDescription' => 'Qadınlar (PC) və d-pad (TV) hər zaman çalışır və zamanlayıcının yeniden başlatılmasıdır.',
			'homeLayout.autoSlideEditDescription' => 'Bu, hər bir saniye özünə çıxır. Off: yalnız bir pul (PC) tıklayınca və ya televizyonda sol/sağ basınca hareket edir.',
			'homeLayout.enableHeroFirst' => 'Birincisi Hero.',
			'homeLayout.showOnHome' => 'Ev ekranında görünür',
			'homeLayout.home' => 'Ana səhifə',
			'homeLayout.removeFromHome' => 'Evdən çıxmaq',
			'homeLayout.selectRowsFirst' => 'İlk dəfə aşağıda yerləşdirilmiş yerlər seçilir.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex-manual edilmiş sıra',
			'homeLayout.continueWatching' => 'İzləməyə davam et',
			'homeLayout.continueWatchingLibraryDescription' => 'Bu kütüphaneye öz-düzgün-gelişmiş yol',
			'homeLayout.continueWatchingHomeDescription' => 'Evdə göstərilmiş olan “Gözlük”',
			'homeLayout.nextUpHomeDescription' => 'Sonraki İçerikDünyanın ən azı yerləri evdə',
			'homeLayout.library' => 'Kitabxana',
			'homeLayout.showInRecommended' => 'İnternet-kitabətdə danışılanlar',
			'homeLayout.customPlexRow' => 'Xərimlər Plex',
			'homeLayout.heroNeedsLibrary' => 'Birincisi, “Bibliothèque” – “Hero”ın bir yerə baxması lazımdır.',
			'homeLayout.heroNeedsSurface' => 'Birincisi kütüphanə və ya evə baxın — Hero bir yerə göstərmək lazımdır',
			'homeLayout.removeHub' => 'Həkimə qalıb',
			'homeLayout.noPlexRows' => 'Bu kütüphane üçün Plex-managed sıra qayıtılıb.',
			'homeLayout.openDetails' => 'Açıklama Detayları',
			'homeLayout.heroCards' => 'Hero kartları',
			'homeLayout.tapHeroCard' => 'Bir kahramanın kartı',
			'homeLayout.tvPlayFocus' => 'Televiziyası: Play düğmesi',
			'homeLayout.tvPlayFocusDescription' => 'D-Pad aşağı durur, bir sonraki sıraya çıxmadan önce Play düğmesine.',
			'homeLayout.tvWrap' => 'Televiziyası: Gəlim kartları',
			'homeLayout.tvWrapDescription' => 'Son kartın üstündə ilk kartın üstünde durdurulur, son kartın üstündən sol kart da ilk kartın yan barına qaytarır.',
			'homeLayout.castOnHero' => 'Hero Banner-da qalıb',
			'homeLayout.castOnHeroDescription' => '“Müslər” adlı filmdə “Müslər” və “Müslər” adlı filmdə “Müslər” və “Müslər” adlı filmdə bir neçə dəfə baxılıb.',
			'homeLayout.customRows' => 'Özəllər',
			'homeLayout.loading' => 'Evdə yerleşim yeri...',
			'homeLayout.noCustomRows' => 'Artıq heç bir qalıq yok',
			'homeLayout.addRowHint' => 'Birini yaratmaq üçün Home Add rw istifadə edin.',
			'homeLayout.addHomeRow' => 'Home Rəviş',
			'homeLayout.addHomeRowDescription' => 'Bir kategoriyi seçin; yeni sıra automatik olarak Organizer-a daxil edilir',
			'homeLayout.removeRow' => 'Rövidini kaldırır',
			'homeLayout.recentlyAdded' => 'Son əlavə olunanlar',
			'homeLayout.recentlyReleased' => 'Son zamanlarda yayımlanan',
			'homeLayout.movieCollections' => 'Film Koleksiya',
			'homeLayout.showCollections' => 'Koleksiya göstərişi',
			'homeLayout.rowTitle' => 'Rövb Adı',
			'homeLayout.content' => 'Qadınlar',
			'homeLayout.showThisRowIn' => 'Bu yolda belə bir şey göstərilir:',
			'homeLayout.libraryRecommended' => 'Kütüphanə danışmaq',
			'homeLayout.heroCard' => 'Hero kartı',
			'homeLayout.heroCardDescription' => 'Bir kartın yerində bir kartın yerində bir kartın yerində bir kartın yerində görünür.',
			'homeLayout.heroUnavailableDescription' => 'Bu sıra yalnız bir koleksiyonun gerçek başlığına çözüldüğünde mevcutdur - birdən çox koleksiyon seçildiğinde, bir başlığı dönmək mümkün deyil.',
			'homeLayout.librariesSelection' => 'Kütüphanələr (her kütüphanə daxil olmaq üçün bütün kontrolsüzləri bırakın)',
			'homeLayout.librariesMergedDescription' => 'Burada hər bir kütüphane bu bir sıraya birleşir.',
			'homeLayout.movieCollectionsSelection' => 'Film koleksiyonları (tüm seçilmiş kütüphane üçün kontrol edilməyənləri bırakın)',
			'homeLayout.showCollectionsSelection' => 'Koleksiyaları görünür (tüm seçilmiş kütüphane üçün kontrolsüz olanları bırakın)',
			'homeLayout.collectionRowsDescription' => 'Bir koleksiyonun tam bir dəfə birləşirse, onun başlığı doğrudan bir sıraya çıxır.Birdən çox bir dəfə birləşdirsə, hər koleksiyon bir poster olarak görünür - o koleksiyonu açmak üçün onu tövbə edin.',
			'homeLayout.allCollections' => 'Bütün Koleksiya',
			'homeLayout.noRowsHere' => 'Burada bir sıra yoxdur.',
			'homeLayout.hideWatchedRows' => 'Görüntülənlər bir sıraya düşüb',
			'homeLayout.hideWatchedRowsDescription' => 'Ev və kütüphane üçün bütün izləmiş başlıklar ev və kütüphane ilə ayrılır.',
			'homeLayout.untitledCollection' => 'Untitled Koleksiya',
			'homeLayout.moveRowHint' => 'Yüksə/Down: Moving sequence · Select: drop it here · Back: Cancel',
			'homeLayout.organizeRowsHint' => 'Bir sıra seçin (ya da tutun): seçin · Sağ/Sağ: sıra seçin · Geri: tamamlandı',
			'homeLayout.layoutNavDescription' => 'Bu kategorilər, kütüphərlər və koleksiyon kategorileri seçilir.',
			'homeLayout.editHomeRow' => 'Evdə qalıb',
			'homeLayout.resetHeroButton' => 'Xatırım oyunları Plezy',
			'homeLayout.reorderingUnlocked' => 'Yenə açılma',
			'homeLayout.reorderingLocked' => 'Yenə qalıb',
			'homeLayout.rowsCanBeDragged' => 'Sətirlərin yerini sürükləyərək dəyişə bilərsiniz. Bunun qarşısını almaq üçün kilidə toxunun.',
			'homeLayout.tapLockToDrag' => 'Sürücüsüz qapı çalın',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Qadın sayı: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Gizlət',
			'homeLayout.remove' => 'Sil',
			'homeLayout.libraryResumeRow' => 'Bu kütüphaneyi yenə',
			'homeLayout.pressAgainToDelete' => 'Yenə xilas etmək üçün basın',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'Onda',
			'homeLayout.resetHeroButtonDescription' => 'Hər bir sıraın kahramanı ayarını devreyar və kahramanın sıraya gəlmədən əvvəl olduğu kimi, üstündə bir dönən bannerı geri getirir.',
			'homeLayout.tapHeroCardDescription' => 'Bir Hero kartı seçmək və ya oynamaq başlar və ya onun ayrıntılarını açır.',
			'homeLayout.heroTapPlayDescription' => 'Seçilmiş elementdən hemen başlayın.',
			'homeLayout.heroTapDetailsDescription' => 'Seçilmiş elementin ayrıntılarını seçməkdən əvvəl açın.',
			'platform.localNetworkPermission' => 'PlezyNG yerel ağınızda medya və playback cihazlarına bağlanır.',
			'platform.locationPermission' => 'Yerli şəbəkəni aşkar etmək və media serverlərinə qoşulmaq üçün iOS tələb etdikdə PlezyNG məkan məlumatlarına girişdən istifadə edir.',
			'platform.photoLibraryPermission' => 'Media üçün təsvir kimi istifadə etmək məqsədilə foto kitabxananızdan şəkillər seçin.',
			'platform.cameraPermission' => 'Companion Remote pultunu qoşmaq üçün QR kodlarını skan edin.',
			'universalMedia.title' => 'Açık medya',
			'universalMedia.shortcutHelp' => 'Bu oturum üçün bir bağlantı, playlist və ya dosyayı oynayın.',
			'universalMedia.intro' => 'Playback PlezyNG standart oynatıcı ilə istifadə edir və kütüphaneye tarih ekləmir.',
			'universalMedia.openWhat' => '- Neyi açmaq istəyirsiniz?',
			'universalMedia.stream' => 'Trafik adresi',
			'universalMedia.playlist' => 'Oyunçı',
			'universalMedia.files' => 'Fillər',
			'universalMedia.favorites' => 'Sürücüsüz favoritlər',
			'universalMedia.address' => 'Medyanın adresi',
			'universalMedia.addressHelp' => 'HTTPS-i tercih edilir. tanınmış kimlik və ya imza parametrləri olan URL-lər yalnız bu oturum üçün istifadə edilir və favori olarak saklanamaz.',
			'universalMedia.displayName' => 'Görüntülər adı (optional)',
			'universalMedia.displayNameHelp' => 'Bir oyuncu və sistem medya kontrolləri üçün kısa adı seçin.',
			'universalMedia.allowHttp' => 'HTTP bağlantısı qapılmamışdır',
			'universalMedia.allowHttpHelp' => 'HTTP bağlantıyı şifrə etmir. yalnız güvenilir bir ağda izin verin. mümkün olduğunca HTTPS-i istifadə edin.',
			'universalMedia.advancedProtocols' => 'MPV yalnız: RTSP, RTMP/RTMPS, UDP və ya RTP adresi daxil edin.',
			'universalMedia.liveStream' => 'Yaşayan kimi davranın',
			'universalMedia.liveStreamHelp' => 'Video və ya radyo üçün bunu istifadə edin. App zaman barını, skip düğmelerini və go-to-time seçeneğini gizir.',
			'universalMedia.privateSession' => 'Və bu video-da yalnız bu adresi istifadə edir.Bu profildə tutmaq üçün bir seçkin akış favorisini saklayın.',
			'universalMedia.saveFavorite' => 'Favoritları salmaq',
			'universalMedia.playNow' => 'Şimdilik oynayın',
			'universalMedia.favoriteSaved' => 'Bu profillə saldığın sevgilisi',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${count}-in düzgün və ya güvenli olmayan oynay listə girişini atıb.', other: '${count}-in kömək etmədik və ya güvenli olmayan oynatma listəsi girişləri atıldı.', ), 
			'universalMedia.playlistAddress' => 'Playlist adresləri',
			'universalMedia.playlistAddressHelp' => 'M3U, M3u8 və ya PLS oynatma listasını bir web adresindən açın.',
			'universalMedia.choosePlaylist' => 'Playlist filləri seçin',
			'universalMedia.openPlaylist' => 'Açıklandı Playlist',
			'universalMedia.playlistFormatsHelp' => 'Bir oyun listəsi 1000-dən çox element və 2 MB içerir. HLS akışlar kimi açılır, bu yüzden oyuncu bir kalitə seçebilir.',
			'universalMedia.saveQueuePlaylist' => 'Növbəni pleylist kimi saxla',
			'universalMedia.queuePlaylistSaved' => 'Pleylist media fayllarının yanında saxlanıldı.',
			'universalMedia.queuePlaylistUnavailable' => 'Bu növbəni təkrar istifadə edilə bilən yerli pleylist kimi saxlamaq mümkün deyil.',
			'universalMedia.queuePlaylistFolderRequired' => 'Yadda saxlama yeri növbədəki fayllarla eyni qovluqda olmalıdır.',
			'universalMedia.noFavorites' => 'Movqe.Az xəbər verir ki, Hollandiyada futbolçular bu profildə qalır.',
			'universalMedia.removeFavorite' => 'Movqe favoritləri',
			'universalMedia.filesHelp' => 'Video, audio və ISO filləri seçin. Fillər və URL-lər kütüphane tarihinə daxil olmaz.',
			'universalMedia.chooseFiles' => 'Fillər seçin',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '1 seçilmiş fil', other: '${count} seçilmiş dosyalar', ), 
			'universalMedia.wifiTransfer' => 'Fillər Wi-Fi yoluyla göndərilir',
			'universalMedia.wifiTransferHelp' => 'Desteklə olan dosyaları bir browserdan aynı güvenilir ağda göndərir.',
			'universalMedia.wifiTransferIntro' => 'Bu adresi başqa cihazda bir browserda açın.Bu cihazın Fillər və kitab kütüphanasına ekləmək üçün dosyaları seçin.',
			'universalMedia.wifiTransferPrivacy' => 'Bu cihaz yerel ağınızdan dosyaları alınır.Bu adresi bilən kimsə, transferin durdurulana qədər və ya adres 15 min sonra sona erdirilmə qədər dosyalarını göndərir. Maksimum: 100 dosya, 4 GiB fil başına, 10 GiB toplam.',
			'universalMedia.wifiTransferStarting' => 'Özel, zamanla sınırlı bir transfer hazırlanır.',
			'universalMedia.wifiTransferUnavailable' => 'İnternetdən istifadə etmək mümkün olmayıb.İnternetin qapısını kontrol edin və bir daha çalışın.',
			'universalMedia.openThisAddress' => 'Bu adresdən birini gönderdən aparaturda açın',
			'universalMedia.copyAddress' => 'Transfer adresini kopyalar',
			'universalMedia.addressCopied' => 'Transfer adresi kopyalanır',
			'universalMedia.transferExpires' => ({required Object time}) => 'Bu adres ${time}-də sona erdirir.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${count} faili alınır', other: '${count} filləri alınmışdır', ), 
			'universalMedia.uploadedData' => ({required Object size}) => '${size} ilə bağlı',
			'universalMedia.stopTransfer' => 'Transfert və adresin iptal edilməsi',
			'universalMedia.startTransfer' => 'Transfer başlatır',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi təyyarə',
			'universalMedia.wifiBrowserTitle' => 'Fəlilə Göndənlər',
			'universalMedia.wifiBrowserIntro' => 'Fillər bu cihazın Dosya və kitab kütüphanəsində salınır. Maksimum: 100 dosya, 4 GiB filə, 10 GiB toplamda.',
			'universalMedia.uploadFilesLabel' => 'Göndən Fillər',
			'universalMedia.uploadSelected' => 'Seçilmiş dosyaları yüklə',
			'universalMedia.uploadSelectFirst' => 'Əvvəlcə bir və ya daha çox fil seçin.',
			'universalMedia.uploading' => 'Göndən',
			'universalMedia.uploadComplete' => 'Fəlilə PlezyNG-a daxil olmuşdur.',
			'universalMedia.uploadFailed' => 'Bu sayıyı açın və tekrar çalışın.',
			'universalMedia.liveCue' => 'Yaşama',
			'universalMedia.liveSession' => 'Live akış',
			'universalMedia.liveCueHelp' => 'Live video və radyo üçün, app zaman barını giz edir və skip düğümləri. adresi və ya tarihini gözləyir.',
			'universalMedia.sessionOnly' => 'Bu oyun yalnız oturumdan',
			'universalMedia.sessionOnlyHelp' => 'Playback heç vaxt ilerməyi və ya tarihini saklamaz. bu profildə tutmaq üçün bir favorit olarak akışını saklayın, eğer uygun olursa.',
			'universalMedia.pictureAdjustments' => 'Görüntülər ayarları',
			'universalMedia.pictureHelp' => 'Görüntüləri dəyişdirənlər yalnız bu playback-i etkilə bilər.',
			'universalMedia.resetPicture' => 'Görüntülər',
			'universalMedia.brightness' => 'Aydınlıq',
			'universalMedia.contrast' => 'Kontrast',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Həyat',
			'universalMedia.saturation' => 'Saturasiya',
			'universalMedia.view360' => 'Görüntülər 360° video üçün',
			'universalMedia.view360Help' => 'Bu görüntü üçün MPV-in FFmpeg v360 filtresine ihtiyacı var.',
			'universalMedia.view360Unavailable' => 'Bu mpv yapı 360° filtresini istifadə edemezdi.',
			'universalMedia.view360Yaw' => 'Horizontal görüş',
			'universalMedia.view360Pitch' => 'Vertikal görüş',
			'universalMedia.view360FieldOfView' => 'Görüş alanı',
			'universalMedia.recordStream' => 'İndi Live Stream',
			'universalMedia.stopRecording' => 'İndirmə və kaydırma',
			'universalMedia.recordingStarted' => 'Xatırmaq aktivdir. playback durdurur və kayıtları saldıra bilər.',
			'universalMedia.recordingSaved' => 'Rekordlar tamamlandı və saldıq.',
			'universalMedia.recordingActive' => 'Bu cihazın qalındığı üçün, playback durdurur və saldıra bilər.',
			'universalMedia.recordingFormatHelp' => 'Video üçün, MKV və ya MPEG-TS seçin.',
			'universalMedia.replaceRecordingTitle' => 'Bu filmləri dəyişib?',
			'universalMedia.replaceRecordingHelp' => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.',
			'universalMedia.replaceRecording' => 'Filə dəyişdirmək',
			'universalMedia.discHelp' => 'Bu bilgisayarın optik sürücüsündən bir disk açılır.Ayrıca cihaz dosyalarından ISO görüntü açabilirsiniz.',
			'universalMedia.discs' => 'Optik disk',
			'universalMedia.editionOrTitle' => 'Buraxılış və ya disk başlığı',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-ray',
			'universalMedia.audioCd' => 'Audio CD',
			'universalMedia.discAvailability' => 'Disk playback-ın uyumlu MPV yapılandırması, supported drive və operating-system izinə ehtiyacıdır.',
			'universalMedia.converterTitle' => 'Yerel medya dosyasını dönüştürmək',
			'universalMedia.converterHelp' => 'Yerli faylı FFmpeg ilə çevirin və ya konteynerini yenidən qurun.',
			'universalMedia.converterIntro' => 'Yerel bir audio və video dosyasını daha çox cihazlarda çalışan formata dönüştürür.',
			'universalMedia.converterPrivacy' => 'Bu bilgisayarda FFmpeg yüklü olmalıdır. Conversion yalnız yerel dosyaları oxur. Streamları indirmir və DRM-i kaldırmaz.',
			'universalMedia.converterChooseInput' => 'Yerel medya dosyasını seçin',
			'universalMedia.converterFormat' => 'Çıkan formatı',
			'universalMedia.converterMp4' => 'MP4 · H.264 və AAC',
			'universalMedia.converterM4a' => 'M4A və AAC audio',
			'universalMedia.converterMp3' => 'MP3 və audio',
			'universalMedia.allowFtp' => 'FTP-yə icazə ver',
			'universalMedia.allowFtpHelp' => 'FTP medianı şifrələmədən göndərir. Yalnız etibarlı şəbəkələrdə istifadə edin.',
			'universalMedia.converterSaveAs' => 'Konvertiyasiya medya',
			'universalMedia.converterExtensionMismatch' => 'Bir filnamə seçin, seçilmiş çıkış genişliği ilə.',
			'universalMedia.converterUnsupportedInput' => 'Video və ya audio fil seçin.',
			'universalMedia.converterLocalOnly' => 'Seçilmiş dosya yerel bir cihaz yolu olarak mevcut deyil.',
			'universalMedia.converterReplaceTitle' => 'Bu dosyayı dəyişir?',
			'universalMedia.converterReplaceHelp' => 'VVD-nin idarə etdiyi superkarlar – bu, artıq çox mərkəzdədir.',
			'universalMedia.converterStarting' => 'Başlamaq üçün FFmpeg...',
			'universalMedia.converterProgress' => 'Bu bilgisayara dönüştürmək üçün...',
			'universalMedia.converterComplete' => 'Yeni fil hazırdır.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg yoxdur və ya bu formatı dəstəkləmir.',
			'universalMedia.converterFailed' => 'Konversiya başarısız oldu. kaynak dosyasının oxuyub və destinasyonun yeterli boş alanı var olduğunu kontrol edin.',
			'universalMedia.converterCancelled' => 'Konversiya iptal edilmişdir. eksakt çıkış kaldırılmışdır.',
			'universalMedia.converterDesktopOnly' => 'Yerel dönüşüm, FFmpeg yüklü olan masaüstü bilgisayarlarda mevcutdur.',
			'universalMedia.converterStart' => 'Filə dönüştürülür',
			'universalMedia.mediaToolsTitle' => 'Medya təyyarəsi',
			'universalMedia.mediaToolsShortcut' => 'Media və ya qapı və ya komandası ilə istifadə edin.',
			'universalMedia.mediaToolsIntro' => 'Choose a focused tool. Capture and stream-out use FFmpeg installed on this desktop. Extensions and CLI commands use bounded HTTPS requests and the existing Open media flow.',
			'universalMedia.mediaToolsAccessibility' => 'Təlim seçimler və kontrollar touch, point, keyboard və D-pad fokus ilə çalışır. Rekord, paylaşım və arama statusu dəyişdirilməsi bildirilir.',
			'universalMedia.mediaTool' => 'Medya təyyarəsi',
			'universalMedia.captureIntro' => 'Record your screen or a camera to an MP4 file on this computer. FFmpeg must be installed and include the H.264 encoder.',
			'universalMedia.captureNoDevices' => 'No screen or camera was found. Check FFmpeg capture support and operating-system privacy permissions.',
			'universalMedia.captureSource' => 'Kamera və ekran',
			'universalMedia.captureScreen' => 'Ekran',
			'universalMedia.captureAudioSource' => 'Audio giriş (optional)',
			'universalMedia.captureAudioHelp' => 'Bir mikrofondan və ya var olan girişdən audio eklə. cihaz seçenekleri FFmpeg və sistem izni ilə bağlıdır.',
			'universalMedia.captureAudioNone' => 'Audio yoxdur',
			'universalMedia.captureDefaultAudio' => 'İndirimli audio',
			'universalMedia.captureWaylandHelp' => 'Wayland limits this XWayland capture to the X display. Windows outside XWayland may not appear.',
			'universalMedia.captureFrameRate' => 'Xatırım çerçevəsi',
			_ => null,
		} ?? switch (path) {
			'universalMedia.capturePrivacy' => '“Mikrofon” filinin seçilməsinə yalnız kaydırılır.Mikrofon çekimi seçicidir.PlezyNG, kaydı yükləmir.',
			'universalMedia.captureSaveAs' => 'Ekranın qalıbı kimi',
			'universalMedia.captureExtensionMismatch' => '.mp4-də son olan bir filnamə seçin.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg və ya H.264 video kodlayıcısı mevcut deyil. destekli FFmpeg yapıları yüklə, sonra tekrar çalışın.',
			'universalMedia.captureFailed' => 'Xatırmaq mümkün olmayıb. cihazın izinini, mevcut depolama və FFmpeg supportunu kontrol edin.',
			'universalMedia.captureSaved' => 'Ekranın qalıb olması.',
			'universalMedia.captureElapsedLabel' => 'Rekord zamanı',
			'universalMedia.captureStart' => 'Rekord başlatmaq',
			'universalMedia.capturePreview' => 'Pleyerdə önizləmə',
			'universalMedia.capturePreviewHelp' => 'Seçilmiş mənbəyə standart pleyerdə baxın. Bu, yalnız cari sessiya üçündür və yazı yaratmır. Cihaz dəstəyi və icazələr MPV-dən və əməliyyat sistemindən asılıdır. Önizləmə yalnız videonu göstərir; yadda saxlanan yazılara əlavə audio daxil edilə bilər.',
			'universalMedia.capturePreviewActive' => 'Canlı önizləmə · yazılmır',
			'universalMedia.captureStop' => 'Qısa və qısa',
			'universalMedia.captureMode' => 'Tövbə',
			'universalMedia.shareMode' => 'Paylaşım',
			'universalMedia.shareIntro' => 'PlezyNG, HLS-in bir zamanlı akışını yaratır.',
			'universalMedia.sharePrivacy' => 'Qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar, qadınlar,',
			'universalMedia.shareChooseFile' => 'Medya filləri seçin',
			'universalMedia.shareChooseHelp' => 'Yerel bir audio və video dosyası seçin. dosyası bu bilgisayarda kalır.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg və ya H.264/AAC kodlayıcıları mevcut deyil. H.264 və AAC kodlayıcı köməkiyle FFmpeg yükləyin.',
			'universalMedia.shareFailed' => 'The stream could not start or stopped unexpectedly. Check FFmpeg and network access.',
			'universalMedia.shareActive' => 'İnternetinizə hazırdır.',
			'universalMedia.shareEnded' => 'Media sonuna gəldi və artık paylaşılmıyor.',
			'universalMedia.shareStopped' => 'Şirkətdə də bu günlər var.Şirkətdə də bu günlər var.',
			'universalMedia.shareUrlCopied' => 'İnternet adresi kopyalanır.',
			'universalMedia.shareOpenUrl' => 'Bu adresi bir oyuncuda başqa cihazda açın',
			'universalMedia.shareQrLabel' => 'QR-codu geçici akış adresi üçün',
			'universalMedia.shareQrHelp' => 'Bu sistemdə, aynı özel ağla bağlanan uyumlu bir oyuncu ilə skanlaşdırılır.',
			'universalMedia.shareHttpHint' => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.',
			'universalMedia.shareCopyUrl' => 'Qızıl adresini kopyalama',
			'universalMedia.shareExpiresLabel' => 'Linklər bitirir',
			'universalMedia.shareStarting' => 'Trafik hazırlanması üçün...',
			'universalMedia.shareStart' => 'Paylaşım başlatır',
			'universalMedia.shareStop' => 'Paylaşımın durması',
			'universalMedia.extensionsMode' => 'Xərimlər və CLI',
			'universalMedia.extensionsIntro' => 'Add a data-only search extension to find media. Choose a result to load it into the familiar Open media form.',
			'universalMedia.extensionsPrivacy' => 'Bir manifesto bir HTTPS arama son noktası və map yanıt alanları tanımlayabilir. kodu çalıştıramaz, istey başlıkları, filları oxuma, və ya başlat shell komandaları.',
			'universalMedia.extensionImport' => 'Açıklama: Manifest',
			'universalMedia.extensionEmpty' => 'Birini ekləmək üçün bizə güvenilir bir manifesto JSON faili seçin.',
			'universalMedia.extensionChoose' => 'İtfaiya xidmətləri',
			'universalMedia.extensionSearchConsent' => 'Hər arzu bu HTTPS servisine sözünüzü göndərir.',
			'universalMedia.extensionSearchLabel' => 'İndi Media',
			'universalMedia.extensionSearch' => 'İtfaiya',
			'universalMedia.extensionSearching' => 'Arşivlər...',
			'universalMedia.extensionNoResults' => 'Safir medyanın nəticələri qayıtılmamışdır.Bir daha arama çalışın.',
			'universalMedia.extensionInstallTitle' => 'Bu arşivdən istifadə etmək olarmı?',
			'universalMedia.extensionReplaceTitle' => 'Bu arşivdə güncələ edilir?',
			'universalMedia.extensionService' => 'Servisi',
			'universalMedia.extensionEndpoint' => 'HTTPS endpoint',
			'universalMedia.extensionConsent' => '“Manifest” bu xidmətə göndərilir.Manifest, işləmə qalıq kodunu içermez.Sadəcə, bu son noktaya inanırsanız devam edin.',
			'universalMedia.extensionInstall' => 'Servisi artırmaq',
			'universalMedia.extensionReplace' => 'Güncellemələr',
			'universalMedia.extensionRemoveTitle' => 'Bu arşivdən çıxır?',
			'universalMedia.extensionRemoveHelp' => 'Bu, bu profillardan hizmetin silinir.PlezyNG onun son noktası ilə iletişime geçmez.',
			'universalMedia.extensionRemove' => 'Servisi kaldırır',
			'universalMedia.extensionInvalidManifest' => 'Bu fail supported extension manifest deyil. formatı üçün Open media qapı görünür.',
			'universalMedia.extensionSaveFailed' => 'Bu aktiv profillərin aktiv olması mümkün deyil.',
			'universalMedia.extensionSearchFailed' => 'İtfaiyətdən istifadə edilmə bilər.Gözlükdən istifadə etmək üçün bir dəfə baxın və tekrar baxın.',
			'universalMedia.cliTitle' => 'Komanda linki',
			'universalMedia.cliHelp' => 'plezyctl yolunu bir manifesti validasiya etmək və ya aynı genişlik arama etmək üçün kullanın. HTTPS servisini hər arama əvvəl gözləmək. Sonuçlar mevcut medya formunda açılır; başlatmaq üçün oynatma düğmesini seçin.',
			'universalMedia.cliCopyExample' => 'Komanda örnekləri',
			'universalMedia.cliCopied' => 'Komanda örnek kopyalanır.',
			'fileSources.title' => 'Fillər və kitablar',
			'fileSources.subtitle' => '- Özünüzdən, özünüzdən, Özünüzdən və özünüzdən baxın.',
			'fileSources.add' => 'Kaynakları artır',
			'fileSources.importFiles' => 'İthalat Fillər',
			'fileSources.localFiles' => 'Bu cihazda',
			'fileSources.source' => 'Kaynak',
			'fileSources.name' => 'İsim',
			'fileSources.endpoint' => 'Server URL-i',
			'fileSources.smbEndpointHint' => 'Nümunə: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'SMB serverini və bir paylaşılan qovluğu daxil edin.',
			'fileSources.root' => 'Fərzər və Prefix',
			'fileSources.smbFolderHelp' => 'Bütün paylaşılan qovluqdan istifadə etmək üçün boş saxlayın və ya onun daxilindəki qovluğu daxil edin.',
			'fileSources.username' => 'İstifadəçi adı',
			'fileSources.smbDomain' => 'Domen (istəyə bağlı)',
			'fileSources.password' => 'Şifrə',
			'fileSources.token' => 'API xətnamə',
			'fileSources.accessKey' => 'Key ID qalıq',
			'fileSources.secretKey' => 'Gizli qapı',
			'fileSources.sessionToken' => 'Session token (İncelətif)',
			'fileSources.region' => 'Region',
			'fileSources.clientId' => 'OAuth müştəri ID',
			'fileSources.clientSecret' => 'OAuth müştəri gizli (yalnız Google namizədləri)',
			'fileSources.allowHttp' => 'Etibarlı şəbəkədə şifrələnməmiş HTTP bağlantısına icazə ver',
			'fileSources.smbEncryption' => 'SMB3 bağlantısını şifrələ',
			'fileSources.smbEncryptionHint' => 'NAS dəstəkləyirsə, SMB3 şifrələməsindən istifadə edin.',
			'fileSources.connect' => 'Qoşul',
			'fileSources.cancel' => 'Ləğv et',
			'fileSources.save' => 'Yadda saxla',
			'fileSources.close' => 'Bağla',
			'fileSources.removeSource' => 'Kaynaklar qalıb',
			'fileSources.disconnectMessage' => 'Bu mənbə ilə əlaqə kəsilsin? Endirilmiş fayllar, oxu və dinləmə tarixçəniz bu cihazda qalacaq.',
			'fileSources.localFolder' => 'Fildi seçin',
			'fileSources.empty' => 'Hələlik burada heç nə yoxdur',
			'fileSources.emptyHint' => 'Bir kitab, bir audiobüslər, bir musiqi və ya bir video bağlayın.',
			'fileSources.search' => 'Bu folderı arama',
			'fileSources.searchCached' => 'İnşaat kütüphanəsi',
			'fileSources.refresh' => 'Yenilə',
			'fileSources.loadMore' => 'Daha çox yüklə',
			'fileSources.offline' => 'Offline ilə bağlı',
			'fileSources.download' => 'Offline qalıb',
			'fileSources.removeDownload' => 'Offline kopya',
			'fileSources.continueReading' => 'Okuma devamı',
			'fileSources.continueListening' => 'Qısaq dinlə',
			'fileSources.continueWatching' => 'Görüşə devam edin',
			'fileSources.read' => 'Qısaq',
			'fileSources.listen' => 'Qısaq',
			'fileSources.play' => 'Oynat',
			'fileSources.pause' => 'Fasilə',
			'fileSources.stop' => 'Saxla',
			'fileSources.startOver' => 'Başlıq',
			'fileSources.finished' => 'Bitdi',
			'fileSources.markFinished' => 'Mark bitir',
			'fileSources.markUnfinished' => 'Markın sonunu',
			'fileSources.editions' => 'Yayınlar və dosyalar',
			'fileSources.chapters' => 'Hissələr',
			'fileSources.bookmarks' => 'Bookmark və notlar',
			'fileSources.bookmark' => 'Bookmark və',
			'fileSources.highlight' => 'Yüksək',
			'fileSources.note' => 'Notlər',
			'fileSources.delete' => 'Sil',
			'fileSources.export' => 'Eksport notları',
			'fileSources.exported' => 'Eksportə alınan',
			'fileSources.sync' => 'Sink progresları',
			'fileSources.synced' => 'Sünnetlər',
			'fileSources.conflict' => 'Bir çox yerdə bir yer var, bir yerdə bir seçin.',
			'fileSources.useLocal' => 'Bu cihazı kullanın',
			'fileSources.useRemote' => 'Diğer cihazları kullanın',
			'fileSources.history' => 'Position Tarihi',
			'fileSources.groupAudio' => 'Bir audiobüsləri kimi dinləyin',
			'fileSources.groupHint' => 'Bu ildə yüklən audio dosyaları birləşir.İlkə bütün sayfa yüklə.',
			'fileSources.order' => 'File ordusu',
			'fileSources.moveUp' => 'Yüksək',
			'fileSources.moveDown' => 'aşağı doğru hareket',
			'fileSources.speed' => 'Playback hızı',
			'fileSources.sleep' => 'Yuxu taymeri',
			'fileSources.sleepOff' => 'Söndürülüb',
			'fileSources.endChapter' => 'Başqapının sonuna',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} dəqiqə', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} dəqiqə', ), 
			'fileSources.skipBack' => 'Geri qayıdın',
			'fileSources.skipForward' => 'İstiqlaşma',
			'fileSources.smartRewind' => '“Smart”dan sonra bir neçə dəfə',
			'fileSources.playbackOptions' => 'Qısa seçenekleri',
			'fileSources.remaining' => ({required Object time}) => '${time} İndər',
			'fileSources.contents' => 'İçərlər',
			'fileSources.readerSettings' => 'Qısaq ayarları',
			'fileSources.fontSize' => 'Text ölçüsü',
			'fileSources.lineHeight' => 'Line-düzər',
			'fileSources.margin' => 'Marqət',
			'fileSources.font' => 'Tiplər',
			'fileSources.serif' => 'Serifik',
			'fileSources.sans' => 'Xərxət olmadan',
			'fileSources.mono' => 'Monopoli',
			'fileSources.columns' => 'Kolonlar',
			'fileSources.scroll' => 'Vertikal olaraq',
			'fileSources.justify' => 'Texti Xalət',
			'fileSources.readerTheme' => 'Sayfa görünüşü',
			'fileSources.appTheme' => 'App Təmə',
			'fileSources.paper' => 'Kağız',
			'fileSources.sepia' => 'Səbri',
			'fileSources.night' => 'Gecə',
			'fileSources.readAloud' => 'Bu səhifəni səsləndir',
			'fileSources.readAlong' => 'Okumaya devam edin',
			'fileSources.stopReading' => 'Səsləndirməni dayandır',
			'fileSources.searchBook' => 'Kitabın arşusu',
			'fileSources.noMatches' => 'Oyunlar yoxdur',
			'fileSources.previousPage' => 'Əvvəlki səhifə',
			'fileSources.nextPage' => 'Növbəti səhifə',
			'fileSources.page' => ({required Object number}) => 'Sayfa ${number}',
			'fileSources.externalBlocked' => 'Oxu proqramında kitabların xarici keçidləri deaktiv edilib.',
			'fileSources.loading' => 'Açılımı...',
			'fileSources.narrator' => 'Tədbir',
			'fileSources.audio' => 'Səs',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'Ebook',
			'fileSources.all' => 'Hamısı',
			'fileSources.downloads' => 'Offline fillər',
			'fileSources.confirmDelete' => 'Seçilmiş oflayn nüsxə silinsin? Oxu və ya dinləmə mövqeyiniz və qeydləriniz saxlanacaq.',
			'fileSources.errorAuthentication' => 'Bu il daha sonra bu il yeniden bağlanmaq üçün.',
			'fileSources.errorPermission' => 'Bu mənbə tələb olunan fayla giriş icazəsi vermədi.',
			'fileSources.errorUnavailable' => 'Bu barədə bir dəfə daha baxmayaraq, bir dəfə daha yazıb, bir dəfə də yazıb.',
			'fileSources.errorUnsupported' => 'Bu formatı və/y bağlantı bu cihazda desteklə etmir. kaynak ayarları kılavuzunu gözləyin.',
			'fileSources.errorInvalidData' => 'Bu faylı və ya serverin cavabını təhlükəsiz şəkildə oxumaq mümkün olmadı.',
			'fileSources.errorCancelled' => 'Operasiya iptal edildi.',
			'fileSources.errorConflict' => 'Bir neçə dəfə bir neçə dəfə bir dəfə bir dəfə seçilir.',
			'fileSources.signIn' => 'Daxil ol',
			'fileSources.reconnect' => 'Yenidən qoşul',
			'fileSources.folderHelp' => 'Bu, S3 URL-ləri buqeti içerir.',
			'fileSources.preferences' => 'İsteqlər',
			'fileSources.timePosition' => 'Mövqe',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Subtitle Təbri',
			'fileSources.none' => 'Bir',
			'fileSources.fullscreen' => 'Full ekran',
			'fileSources.syncLocation' => 'Movqeynlik filosu (optional)',
			'fileSources.syncLocationHint' => 'PlezyNG statusu üçün dedikodul bir WebDAV klasör. şartlı yazılar istifadə edir; medya dəyişməzdir.',
			'fileSources.audiobooks' => 'Avidiyalı',
			'fileSources.comics' => 'Komikslər',
			'fileSources.scan' => 'Kitaplar və medyanın skanları',
			'fileSources.browserReader' => 'Open Əsət',
			'fileSources.browserReaderHelp' => 'Oxuyucu brauzerinizdə açıqdır. Oxuduğunuz yeri və qeydlərinizi saxlamaq üçün PlezyNG tətbiqini açıq saxlayın.',
			'fileSources.on' => 'Onda',
			'fileSources.advancedSetup' => 'App-in təhrif',
			'fileSources.microsoftSignIn' => 'Microsoft ilə giriş yapın',
			'fileSources.zoomIn' => 'ZOOM İÇİN',
			'fileSources.zoomOut' => 'ZOOM İÇİN',
			'fileSources.fitPage' => 'Əsas sayfa',
			'fileSources.fitWidth' => 'Xərimət',
			'fileSources.actualSize' => 'Günlük ölçü',
			'fileSources.goToPage' => 'Sayfaya gəlin',
			'fileSources.goToSection' => 'Qəzaq başlığı',
			'fileSources.pageRange' => ({required Object count}) => '1dən ${count} qədər bir sayı girin',
			'fileSources.pageLayout' => 'Sayfa Layout',
			'fileSources.automatic' => 'Avtomatik',
			'fileSources.singlePage' => 'Bir sayfa',
			'fileSources.twoPages' => '2 sayfa',
			'fileSources.readingDirection' => 'Qısaq yönü',
			'fileSources.leftToRight' => 'Soldan sağa',
			'fileSources.rightToLeft' => 'Sağdan sola',
			'fileSources.letterSpacing' => 'İtraflar',
			'fileSources.wordSpacing' => 'Sözlər',
			'fileSources.readerControlsHelp' => 'Səhifəni böyütmək üçün iki barmağınızı aralayın və ya böyütmə düymələrindən istifadə edin. Səhifəni hərəkət etdirmək üçün sürükləyin. Ctrl/⌘ ilə + və ya − miqyası dəyişir; Ctrl/⌘ ilə 0 onu sıfırlayır. Page Up və Page Down səhifələri dəyişir.',
			'fileSources.imagePage' => 'Komiks səhifəsi',
			'fileSources.resetReader' => 'Read Preferences - Qəzaqlama',
			'fileSources.zoom' => 'Miqyas',
			'fileSources.useFiles' => 'Fillər və kitablar',
			'fileSources.cancelScan' => 'Scanı iptal et',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Offline download limitləri',
			'fileSources.offlineQuotaHelp' => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın adının qısaltması kimi bilinir.',
			'fileSources.offlineStorageUsage' => 'Offline təyyarə',
			'fileSources.reservedStorage' => 'Rezervasiya',
			'fileSources.downloadQueue' => 'İndir kiçik',
			'fileSources.downloadRunning' => 'İndirmə',
			'fileSources.downloadQueued' => 'Bekənlər',
			'fileSources.downloadPaused' => 'İstihbarat',
			'fileSources.downloadFailed' => 'RETRİ İhtiyaç',
			'fileSources.importing' => 'İthalat',
			'fileSources.importInterrupted' => 'İhracat durduruldu; xilas edilmə',
			'fileSources.errorQuotaExceeded' => 'VVD - Hollandiyada futbolçu bu adla tanımır, orada VVD daha çox mərkəz-sağı təmsilən edən siyasi partiyanın ulduzduğunu göstərir.',
			'fileSources.errorStorageLow' => 'Bu sistemin korunması üçün bağımsız bir aparatur depoları yoxdur.',
			'fileSources.errorStorageUnavailable' => '"PlezyNG" özgür cihazın depolarını kontrol edemezdi, bu yüzden yazmaq durduruldu.',
			'fileSources.removeDownloadJob' => 'Download İndir',
			'fileSources.downloadAlreadyComplete' => 'Bu download bitirilmə əvvəl, kaldırılabilir. element şimdi çevrimdışı mevcutdur.',
			'fileSources.confirmRemoveDownloadJob' => 'Bu indirmeyi kaldırın və kısmi indirilmiş məlumatları silinir? pozisyonunuz və notlarınız kalır.',
			'lending.title' => 'Public kütüphane',
			'lending.add' => 'Bir kütüphane də eklə',
			'lending.other' => 'Bir çox kütüphane',
			'lending.libraryName' => 'Kütüphanın adı',
			'lending.libraryUrl' => 'İnternet kütüphanəsi',
			'lending.libraryUrlHint' => 'Kitabın katalogunu və ya sayfanı istifadə edin.',
			'lending.intro' => 'Kitabınızdan borç alın, kitabınızı qapı tutun.',
			'lending.handoff' => 'İndi, yazın, yazın və öz kütüphaneyi öz servisinizlə güvenli bir şekilde yazın.',
			'lending.openService' => 'Open Kütüphanə',
			'lending.findLibrary' => 'Bir kütüphaneyi bulma',
			'lending.search' => 'Kitablar və yazarlar arama',
			'lending.catalogue' => 'Katalog',
			'lending.loans' => 'Kredisi',
			'lending.holds' => 'Rezervasiyalar',
			'lending.signIn' => 'Kitabınızla giriş olun',
			'lending.waiting' => 'Bu gün, bu gün, bu browserda girişini bitir, sonra buraya qayıdın.',
			'lending.cancel' => 'Ləğv et',
			'lending.disconnect' => 'Kütüphanə çıxmaq',
			'lending.disconnectMessage' => 'Bu kitabxana bu profildən silinsin? Götürdüyünüz kitablar və rezervasiyalarınız kitabxana hesabınızda qalacaq.',
			'lending.getBook' => 'Kitabı alın',
			'lending.checkAvailability' => 'Hazırlıq kontrolü',
			'lending.available' => 'Kredisi üçün istifadə ediləcək',
			'lending.unavailable' => 'Şu an mevcut olmayan',
			'lending.borrow' => 'Müvəqqəti götür',
			'lending.placeHold' => 'Rezervasiya et',
			'lending.returnBook' => 'Gecə qayıtmaq',
			'lending.cancelHold' => 'Rezervasiyanı ləğv et',
			'lending.confirmBorrow' => 'Bu kitabı kütüphanınızdan borçluya bilərsiniz?',
			'lending.confirmReturn' => 'Bu kitab indi qaytarılsın? Davam etmək üçün onu yenidən götürməli ola bilərsiniz.',
			'lending.confirmCancelHold' => 'Bu kitab üçün rezervasiyanız ləğv edilsin?',
			'lending.email' => 'İzinli bildirim e-mail',
			'lending.due' => ({required Object date}) => 'Əsasə ${date}',
			'lending.queue' => ({required Object position}) => 'Qadınlar ${position}',
			'lending.empty' => 'Burada heç bir titulu yoxdur.',
			'lending.openLibraryNote' => 'Bu yazının yazılı kitabı, yazılı kitabın yazılı kitabını, yazılı yazılı kitabının yazılı yazısını, yazılı yazı yazılı kitabına, yazılı Yazılı kitabın kitabını, Yazılı kitabının kitabını, yazı yazılı yazısı, yazılı kitap yazılı kitabından, yazılı Kitabın kitabını yazılıdır.',
			'lending.more' => 'Daha çox yüklə',
			'lending.gateway' => 'Bibliotekarın işləvi',
			'lending.gatewayHint' => 'Bu barədə “Bütçəniz” və ya “PlezyNG administrator” tərəfindən bildirilir.',
			'lending.advanced' => 'Kütüphanə integrasiya',
			'lending.loadLibraries' => 'Kütüphanınızı seçin',
			'lending.expired' => 'Bu kreditlər sonuna qədər sona gəldi.',
			'lending.updated' => 'Kütüphanə güncəl',
			'lending.continueService' => 'Servisi ilə devam edin',
			'lending.comingSoon' => '“Gözəl” və “Gözəllər”',
			'lending.comingSoonDescription' => 'Libby-nin bütünleşməsi yolunda olub. Libby-də kütüphaneyi istifadə edirsiniz, biz onu bağlayırıq.',
			'lending.suspendHold' => 'Qısaq tutma',
			'lending.resumeHold' => 'Qəzaq tut',
			'lending.suspendMessage' => 'Növbədəki yerinizi saxlayıb növbəti oxucunun bu nüsxəni götürməsinə icazə verilsin? Rezervasiyanı sonra bərpa edə bilərsiniz.',
			'lending.resumeMessage' => 'Kitabxananın növbəti əlçatan nüsxəni sizə təklif etməsi üçün bu rezervasiya bərpa edilsin?',
			'lending.editEmail' => 'İzin dəyişmək',
			'audiobook.syncTitle' => 'Okunmaq və dinləmək',
			'audiobook.syncHelp' => 'Sizin cihazlarınızda okuma pozisyonları, dinleme pozisyonları, tamamlama statusu, notları və notları tutun. bağlı bir depolama hesabı seçin və hər cihazda aynı sinq kodunu kullanın. Okuma və dinleme ayrı kalır.',
			'audiobook.addSyncSource' => 'Google Drive, OneDrive, Dropbox, WebDAV və ya S3 filləri və kitabları ilk dəfə ekləyin.',
			'audiobook.syncDestination' => 'Sync hesabı',
			'audiobook.syncFolder' => 'Xatırmaq və / və ya prefix',
			'audiobook.syncFolderHelp' => 'WebDAV kaynağınızın içində ayrı bir var olan klassiyayı və ya özgün bir S3 prefiksini istifadə edin.',
			'audiobook.syncCode' => 'Private Sink kodları',
			'audiobook.syncCodeHelp' => 'İlk cihazınızda bir kod oluşturun, sonra o kodu diğer cihazlarınızda yazın. özel bir kopya tutun: bu şifrə edilmiş durumunuzun anahtarıdır. hər kişi için farklı bir kod kullanın.',
			'audiobook.showCode' => 'Sink kodu göstərmək və ya gizləmək',
			'audiobook.newSyncCode' => 'Yeni bir sink kodu yaratır',
			'audiobook.saveSync' => 'Sink və Sink',
			'audiobook.disableSync' => 'Bu cihazda sinqrini devreyin',
			'audiobook.syncSourceDisconnect' => 'Bu kayanın kaldırılması burada oxuma və dinləmə sinqə açılır. şifrə edilmiş sinq filları sağlayıcının içində kalır.',
			'audiobook.syncReconnect' => 'Depozito hesabını yeniden bağlayın',
			'audiobook.lastSynced' => ({required Object time}) => 'Son zamanlarda ${time}',
			'audiobook.syncPrivacy' => 'Sadəcə şifrə edilmiş progres və notlar kaydedilir. Audio və ebook filləri, hesab tokenləri və şifrələr yüklə edilmir. Google Drive və OneDrive istifadə app depolama; Dropbox kullanır PlezyNG Sync. Enable sync ekstra yazma qapı isteyebilir. Enable, bu destinasyon progres sync sahibidir; server progres ayrı kalır. Turn sync off yerel tarih və uzaq durum tutar.',
			'audiobook.syncConflicts' => 'Yenə qayıtma yeri seçin',
			'audiobook.conflictHelp' => 'Bu değişikliklər bağımsızdır. tutmaq üçün pozisyonu və ya kart versiyonu seçin. Daha sonra bir zaman çizgisi və ya daha yüksek bir faiz oranı otomatik olarak kazanmaz.',
			'audiobook.syncDevice' => ({required Object device}) => '${device} və QXZQ',
			'audiobook.syncUnknownDevice' => 'Bilinmeyen cihazlar',
			'audiobook.deletedBookmark' => 'Çözülmüş kitabı',
			'audiobook.finished' => 'Hazırda',
			'audiobook.readingPosition' => ({required Object percent}) => '${percent} %',
			'audiobook.chapterTimeline' => 'Bölüm progresları',
			'audiobook.bookTimeline' => 'Bütün kitablar',
			'audiobook.bookRemaining' => ({required Object time}) => 'Bu kitabda kalan zaman: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Bu bölümdə kalan zaman: ${time}',
			'audiobook.unknownRemaining' => 'Bütün oyunlar oynanır ki, bütün oyunlar oynanır',
			'audiobook.undoSeek' => 'Son arama',
			'audiobook.customSpeed' => 'Playback hızı',
			'audiobook.speedHelp' => 'İndərlik: 0.25 x 4 x arasında seçilir.',
			'audiobook.apply' => 'İhtiyaç',
			'audiobook.customSleep' => 'Qadın uyku saatləri',
			'audiobook.sleepMinutes' => '1 min və 1440 min arası',
			'audiobook.sleepChapters' => ({required Object count}) => '${count} qapıdan sonra durun',
			'audiobook.extendSleep' => '5 dəqiqə',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Uyku vaxtı: ${time}',
			'audiobook.useDefaults' => 'Yeni kitablar üçün bu oxuma kontrollarını kullanın',
			'audiobook.librarySort' => 'Kitaplar',
			'audiobook.sortTitle' => 'Başlık',
			'audiobook.sortAuthor' => 'Yazarın',
			'audiobook.sortNarrator' => 'Öykənlər',
			'audiobook.sortSeries' => 'Seriyalı komandalar',
			'audiobook.sortRecent' => 'Son zamanlarda açıldı',
			'audiobook.statusFilter' => 'Okuma statusu',
			'audiobook.statusAll' => 'Bütün kitablar',
			'audiobook.statusNew' => 'Başlamadı',
			'audiobook.statusProgress' => 'Gəlimdə',
			'audiobook.statusFinished' => 'Hazırda',
			'audiobook.goToTime' => 'Zamanla gəlin',
			'audiobook.timeHelp' => 'Saatlar:minutlar:saniyələr və ya minutlar:saniyələr',
			'audiobook.recoveryHelp' => 'Son zamanlarda şifrə edilmiş bir kopyayı ithal etmədən əvvəl və ya sinqlər verilerini düzeltmək. İthalatlar mevcut durumla birleşir; yerel sinq tarihini asılmazlar. Sinq kodunu ayrı tutun.',
			'audiobook.recoveryExport' => 'Şifrelə qayıtma dosyası',
			'audiobook.recoveryImport' => 'Şifrelə qayıtma dosyası',
			'audiobook.recoveryImportConfirm' => 'Bu şifrə edilmiş qaytarma dosyasını günümüzdeki okuma pozisyonları və notlarla birleştirir? mevcut geçmişi tutulur. Paylaşılmış kütüphane və element kimlikləri içermez; ithal etmeden əvvəl hər cihazda eşitsiz kimliklər ayarlayın.',
			'audiobook.recoveryExported' => 'Şifrelə qayıtma dosyası qurulmuşdur.',
			'audiobook.recoveryImported' => 'İtraf verileri birləşmişdir.',
			'sourceSetup.savedCertificate' => 'Yadda saxlanmış server sertifikatı',
			'sourceSetup.nfsEndpointInvalid' => 'nfs://nas:2049/export kimi NFS URL-i daxil edin.',
			'sourceSetup.dlnaNone' => 'DLNA serveri tapılmadı. Cihazın təsvir URL-ini əl ilə daxil edin.',
			'sourceSetup.dlnaServers' => 'DLNA media serverləri',
			'sourceSetup.dlnaUnavailable' => 'Bu şəbəkədə DLNA axtarışı mümkün deyil. Cihazın təsvir URL-ini əl ilə daxil edin.',
			'sourceSetup.dlnaSearching' => 'Yerli şəbəkədə DLNA serverləri axtarılır',
			'sourceSetup.networkSearching' => 'Yerli şəbəkədə axtarılır…',
			'sourceSetup.dlnaDiscover' => 'DLNA serverlərini tap',
			'sourceSetup.dlnaHelp' => 'Axtarış yerli şəbəkədə multicast yayımından asılıdır. Server görünmürsə, yuxarıda onun cihaz təsviri URL-ini daxil edin.',
			'sourceSetup.dlnaRoot' => 'DLNA obyekt ID-si; cihazın kökünü istifadə etmək üçün boş saxlayın.',
			'sourceSetup.passwordOrKey' => 'Şifrə daxil edin və ya aşağıda özəl açar əlavə edin.',
			'sourceSetup.sshFingerprint' => 'SSH host açarının SHA256 izi',
			'sourceSetup.sshFingerprintHelp' => 'Server administratoru ilə yoxlayın. Serverdə ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub əmrini işlədin və SHA256 dəyərini istifadə edin.',
			'sourceSetup.sshFingerprintKeep' => 'Hazırda sabitlənmiş izi saxlamaq üçün boş saxlayın və ya serverin yeni izini daxil edin.',
			'sourceSetup.sshAuthentication' => 'Açıq açarla SSH kimlik təsdiqi',
			'sourceSetup.sshAuthenticationHelp' => 'İstəyə bağlıdır; şifrə ilə kimlik təsdiqi də dəstəklənir.',
			'sourceSetup.privateKey' => 'Özəl açar (PEM və ya OpenSSH formatı)',
			'sourceSetup.privateKeyPassphrase' => 'Özəl açarın parol ifadəsi',
			'sourceSetup.nfsMountPort' => 'NFS mount xidmətinin TCP portu',
			'sourceSetup.nfsMountPortHelp' => 'Standart: 20048',
			'sourceSetup.nfsUserId' => 'NFS istifadəçi ID-si (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Standart: 1000. NAS-ın NFS paylaşımında icazə verilən ID-ni istifadə edin.',
			'sourceSetup.nfsGroupId' => 'NFS qrup ID-si (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Standart: 1000. NAS-ın NFS paylaşımında icazə verilən qrup ID-sini istifadə edin.',
			'sourceSetup.nfsEncryption' => 'Şifrələnmiş NFS tələb et (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'NFS və mount xidməti üçün TLS 1.3 tələb edin. NAS bunu dəstəkləmirsə, bağlantı rədd edilir.',
			'sourceSetup.nfsTrustCertificate' => 'Xüsusi NFS CA və ya server sertifikatı (PEM, istəyə bağlı)',
			'sourceSetup.nfsTrustHelp' => 'Bu cihazın etibar etdiyi sertifikatlar üçün boş saxlayın. Lazım olduqda özəl CA sertifikatı və ya öz-özünə imzalanmış server sertifikatı əlavə edin; sertifikatdakı adlar NFS URL-indəki hosta uyğun gəlməlidir.',
			'sourceSetup.nfsTrustInvalid' => 'PEM formatında CA və ya server sertifikatı istifadə edin. Özəl açar daxil etməyin.',
			'sourceSetup.addTrustCertificate' => 'Xüsusi etibar sertifikatı əlavə et',
			'sourceSetup.replaceTrustCertificate' => 'Yadda saxlanmış xüsusi sertifikatı əvəz et',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS adi NFS və mount xidməti portlarını istifadə edir və NAS-da RFC 9289 dəstəyi tələb edir. TLS 1.3 tələb olunur. Host adı və ya IP ünvanı sertifikata uyğun gəlməlidir. Şifrələnmiş kanalda da AUTH_SYS UID/GID qüvvədə qalır.',
			'sourceSetup.clientCertificate' => 'Klient sertifikatı (istəyə bağlı)',
			'sourceSetup.clientCertificateHelp' => 'NAS-a bu klientin kimliyini təsdiqləməyə imkan verir; AUTH_SYS ID-ləri yenə NAS-ın NFS paylaşım qaydalarından asılıdır.',
			'sourceSetup.savedIdentity' => 'Yadda saxlanmış klient kimlik məlumatları istifadə olunacaq.',
			'sourceSetup.replaceIdentity' => 'Yadda saxlanmış klient kimlik məlumatlarını əvəz et',
			'sourceSetup.chooseIdentity' => 'PKCS#12 klient kimlik məlumatlarını seç',
			'sourceSetup.identityPassphrase' => 'Klient kimlik məlumatlarının parol ifadəsi',
			'sourceSetup.identityPassphraseHelp' => 'Faylın parol ifadəsi yoxdursa, boş saxlayın.',
			'sourceSetup.removeIdentity' => 'Yadda saxlanmış klient kimlik məlumatlarını sil',
			'sourceSetup.identityStorageHelp' => 'Klient kimlik məlumatları mənbənin şifrələnmiş giriş məlumatları yaddaşında saxlanılır. Yadda saxlanmış kimlik məlumatlarını qorumaq üçün bu bölməni dəyişməyin.',
			'sourceSetup.nfsLimitations' => 'TCP üzərindən yalnız oxuma üçün NFSv3. RPC-with-TLS olmadan NFS trafiki şifrələnmir. NAS seçilmiş AUTH_SYS ID-lərinə və imtiyaz tələb etməyən klient portlarına icazə verməlidir (çox vaxt “insecure” export seçimi adlanır). NFSv4 və UDP dəstəklənmir.',
			'sourceSetup.nfsSetupHelp' => 'NFS quraşdırma köməyi',
			'sourceSetup.nfsSetupHint' => 'Bağlantı açılmırsa, bu ayarları yoxlayın.',
			'sourceSetup.nfsSetupDetails' => 'TCP üzərindən NFSv3 paylaşımı istifadə edin. Şifrələmə tələb olunursa, həm NFS, həm də mount xidməti RPC-with-TLS dəstəkləməlidir. Cihazın etibar etdiyi server sertifikatı üçün xüsusi sertifikat sahəsini boş saxlayın və ya NAS-ın CA sertifikatını yaxud öz-özünə imzalanmış sertifikatını əlavə edin. Sertifikatdakı ad bağlantı ünvanındakı hosta uyğun olmalıdır. NAS qarşılıqlı TLS tələb edirsə, onun PKCS#12 klient kimlik məlumatlarını əlavə edin. Sonda paylaşımın təyin edilmiş AUTH_SYS UID/GID və klient portu qaydalarına icazə verdiyini yoxlayın.',
			'sourceSetup.ftpHelp' => 'FTP passiv rejimdən istifadə edir. Şifrələnməmiş FTP üçün ftp://, ayrıca əmrlə TLS-ə keçid üçün ftpes://, TLS üçün isə ftps:// istifadə edin (990 portunda TLS dərhal başlayır, digər portlarda ayrıca əmrlə başladılır).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Ayrıca videolar üçün istəyə bağlı altyazı axtarışı.',
			'sourceSetup.apiKey' => 'API açarı',
			'sourceSetup.optionalUsername' => 'Hesabın istifadəçi adı (istəyə bağlı)',
			'sourceSetup.optionalPassword' => 'Hesabın şifrəsi (istəyə bağlı)',
			'sourceSetup.subtitlePrivacy' => 'opensubtitles.com saytından API açarı alın. Axtarış videonun adını və mövcud IMDb/TMDB ID-lərini göndərir, video faylını isə heç vaxt göndərmir. Açar və istəyə bağlı hesab giriş məlumatları bu mənbə ilə birlikdə şifrələnir.',
			'sourceSetup.automaticMetadata' => 'Avtomatik onlayn video metadatası',
			'sourceSetup.metadataPrivacy' => 'Yalnız fayl adındakı adı/ili və epizod nömrələrini və ya NFO ID-sini göndərir; media və giriş məlumatlarını heç vaxt göndərmir. NFO sahələri üstünlüyünü saxlayır.',
			'sourceSetup.nfsEncryptionFailure' => 'Şifrələnmiş NFS üçün hər iki NAS xidmətində RFC 9289 və TLS 1.3 dəstəyini, sertifikat adını və paylaşımın UID/GID dəyərlərini yoxlayın. PlezyNG bu bağlantını şifrələmə olmadan yenidən sınamayacaq.',
			'sourceSetup.sourceConnecting' => 'Mənbəyə qoşulur',
			'sourceSetup.metadataSearchPrivacy' => 'Bu ad axtarışı Trakt-a göndərilir. Daxil etdiyiniz ad göndərilir, video və ya mənbənin giriş məlumatları deyil.',
			'sourceSetup.chooseMatch' => 'Uyğun nəticəni seç',
			'sourceSetup.metadataMatchHelp' => 'Seçməzdən əvvəl adı və ili yoxlayın. Trakt axtarılan adı alır; video öz mənbəyində qalır.',
			'sourceSetup.metadataNoMatches' => 'Onlayn uyğun ad tapılmadı. Başqa ad sınayın.',
			'sourceSetup.metadataSearch' => 'Onlayn metadata axtar',
			'sourceSetup.metadataLoading' => 'Onlayn film və serial məlumatları axtarılır…',
			'sourceSetup.metadataFromTrakt' => 'Trakt-dan onlayn metadata',
			'sourceSetup.metadataNoAutomaticMatch' => 'Avtomatik ad uyğunluğu tapılmadı. Uyğun nəticəni seçmək üçün adı axtarın.',
			'sourceSetup.metadataFailed' => 'Onlayn metadata yüklənmədi. Oynatma və yerli məlumatlar hələ də əlçatandır.',
			'sourceSetup.videoDetailsLoading' => 'Video məlumatları yüklənir',
			'sourceSetup.subtitleKeyRequired' => 'OpenSubtitles API açarı tələb olunur',
			'sourceSetup.subtitleKeyHelp' => 'Bu fayl mənbəyini redaktə edin və istəyə bağlı altyazı ayarlarına OpenSubtitles API açarı əlavə edin.',
			'sourceSetup.subtitleSearchFailed' => 'Altyazı axtarışı uğursuz oldu. API açarını, bağlantını və xidmətə girişi yoxlayın.',
			'sourceSetup.subtitleApplyFailed' => 'Bu altyazı endirilə və ya tətbiq edilə bilmədi. Bağlantınızı yoxlayın və başqa nəticə sınayın.',
			'sourceSetup.subtitleSearch' => 'OpenSubtitles-də axtar',
			'sourceSetup.subtitleSearchPrivacy' => 'Axtarış adı və mövcud IMDb/TMDB ID-lərini istifadə edir. Video faylı öz mənbəyində qalır. Seçməzdən əvvəl dili, məcburi altyazı və ya eşitmə məhdudiyyətli şəxslər üçün altyazı işarələrini və reytinqi yoxlayın.',
			'sourceSetup.movieOrShow' => 'Film və ya serial',
			'sourceSetup.subtitleTitleHint' => 'Nəticələri dəqiqləşdirmək üçün ad daxil edin',
			'sourceSetup.subtitleLanguage' => 'Altyazı dili',
			'sourceSetup.subtitleSearching' => 'OpenSubtitles-də axtarılır',
			'sourceSetup.subtitleNoMatches' => 'Uyğun altyazı tapılmadı. Başqa ad və ya dil sınayın.',
			'sourceSetup.downloadSubtitle' => 'Altyazını endir',
			'sourceSetup.subtitle' => 'Altyazı',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS tələb olunur',
			'sourceSetup.nfsUnencrypted' => 'Şifrələnməmiş NFS',
			'sourceSetup.tlsEncrypted' => 'TLS ilə şifrələnib',
			'sourceSetup.ftpPlain' => 'Şifrələnməmiş FTP',
			'sourceSetup.sshPinned' => 'SSH şifrələnib · host açarı sabitlənib',
			'sourceSetup.smbEncrypted' => 'SMB3 şifrələməsi aktivdir',
			'sourceSetup.smbUnencrypted' => 'SMB3 şifrələməsi deaktivdir',
			'sourceSetup.httpUnencrypted' => 'Nəqliyyat şifrələməsi olmayan HTTP',
			'sourceSetup.checkEndpointSecurity' => 'Bağlantı ünvanının təhlükəsizliyini yoxla',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'Tələb olunan sahə: ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => '${label} üçün ${min} ilə ${max} arasında dəyər daxil edin.',
			'sourceSetup.replaceFile' => ({required Object name}) => '${name} əvəz et',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Seçilmiş klient kimlik məlumatları: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Reytinq ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Altyazı endirilir: ${title}',
			'sourceSetup.sharedEntryPair' => 'Bu elementin parası',
			'sourceSetup.sharedEntryPairHelp' => 'Hər bir cihazda bu öğə üçün aynı ID-i girin. sabit paylaşılan tanımlayıcı kullanın və birini oluşturun və eşleşən öğeye kopyalanın. Progress pars yalnız versiyonu dosya türləri, büyüklükleri və sipariş eşleşir. Blank bu mapping kaldırır.',
			'sourceSetup.sharedEntryId' => 'Xatırılmış element ID',
			'sourceSetup.generateSharedEntryId' => 'Paylaşılmış element ID',
			'sourceSetup.sharedLibraryId' => 'Kütüphanə ID-i paylaşılmışdır (optional)',
			'sourceSetup.sharedLibraryHelp' => 'Bu public ID-i aynı kütüphaneyi açan cihazlarda da aynı ID-ə istifadə edin.Bu yayın ID-si, farklı kaynak bağlantıları üzerinden okuma progresunu və notlarını götürmək üçün kömək edir; bu bir şifard deyil.',
			'sourceSetup.sharedLibraryInvalid' => '8–100 yazı, sayı, nokta, subscores və hyphens istifadə edin.',
			'sourceSetup.generateSharedLibraryId' => 'Bir kütüphane ID-i oluşturmaq',
			'sourceSetup.nfsReadAhead' => 'NFS-nin Qəzaq İzinləri',
			'sourceSetup.nfsReadAheadHelp' => 'Daha çox paralel okurlar, bir NAS və ya ağda geçiş gücünü artırır. sunucu sözleşmelerini sınırlandırdığında 1 istifadə edin.',
			'sourceSetup.nfsReadTest' => 'NFS-in performansını ölçmək',
			'sourceSetup.nfsReadTestHelp' => 'Bu NAS bağlantısını ölçmək üçün ən böyük faildən 64 MiB-a qədər okunur.Bu ağ bandwidthını kullanır.',
			'sourceSetup.nfsQualificationResult' => 'NFS-in ölçüləri',
			'sourceSetup.nfsReadBytes' => 'Tarihlər Read',
			'sourceSetup.nfsReadSpeed' => 'Hızın ölçülməsi',
			'sourceSetup.nfsReadRequests' => 'İhtiyaçları okuyun',
			'sourceSetup.sharedEntryConflict' => 'Bu paylaşılan element kimliği bu kütüphanada başqa bir elementlə də parədir. farklı bir ID seçin.',
			'comics.fitHeight' => 'Hündürlüyə uyğunlaşdır',
			'comics.readingMode' => 'Oxu rejimi',
			'comics.paged' => 'Səhifələr',
			'comics.webtoon' => 'Davamlı sürüşdürmə',
			'comics.coverAlone' => 'Üz qabığını ayrıca göstər',
			'comics.splitWide' => 'Geniş səhifələri böl',
			'comics.splitWideHelp' => 'Hər yarını oxu ardıcıllığı ilə ayrıca göstər. Bu seçim aktiv olduqda iki səhifənin birlikdə göstərilməsi dayandırılır.',
			'comics.thumbnails' => 'Səhifə miniatürləri',
			'comics.controlsHelp' => 'Səhifələri çevirmək üçün sürüşdürün. Uyğunlaşdırmanı dəyişmək üçün iki dəfə toxunun. Davamlı sürüşdürmədə şaquli sürüşdürün və ya Page Up və Page Down istifadə edin.',
			'comics.savedForComic' => 'Görüntü ayarları bu profildə bu komiks üçün yadda saxlanılır.',
			'comics.readLists' => 'Oxu siyahıları',
			'comics.collections' => 'Kolleksiyalar',
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
			_ => null,
		} ?? switch (path) {
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
			'deepLinks.invalid' => 'Bu Plezy bağlantısı geçerli deyil.',
			'deepLinks.profileNotFound' => ({required Object profile}) => '“${profile}” və “ZxqPROFile0” arasında heç bir profil yoxdur.',
			'deepLinks.serverUnavailable' => 'Bu linki üçün serverə ulaşamazdım.',
			'deepLinks.notFound' => 'Bu kitabın kitabında bir başlık bulamazdım.',
			'deepLinks.unsupportedItem' => 'Bu linki oynamaq mümkün deyil.',
			'deepLinks.noLiveTv' => 'Bu linki üçün Live TV server yoxdur.',
			'deepLinks.channelNotFound' => ({required Object channel}) => '“${channel}” kanalını bulamazdım.',
			'deepLinks.showLink' => 'İndir Link',
			'deepLinks.showProfileLink' => 'Profil link göstərmək',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Bu linki açın, bir sonraki epizod oynanır. shuffle-da şov oynamak için &mode=shuffle ekləyin.',
			'deepLinks.movieHint' => 'Bu linki açmaq filmi oynayır.',
			'deepLinks.episodeHint' => 'Bu linki açmaq bu epizodu oynayır.',
			'deepLinks.profileHint' => 'Bu profillə bu link-i açılır.',
			'deepLinks.openAsProfile' => ({required Object name}) => '${name} kimi açılır',
			'deepLinks.copy' => 'Kopya',
			'deepLinks.copied' => 'Link kopyalar',
			_ => null,
		};
	}
}
