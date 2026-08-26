///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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
	@override late final _Translations$auth$az auth = _Translations$auth$az._(_root);
	@override late final _Translations$common$az common = _Translations$common$az._(_root);
	@override late final _Translations$screens$az screens = _Translations$screens$az._(_root);
	@override late final _Translations$update$az update = _Translations$update$az._(_root);
	@override late final _Translations$settings$az settings = _Translations$settings$az._(_root);
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
}

// Path: app
class _Translations$app$az extends Translations$app$en {
	_Translations$app$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
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
	@override String get useQuickConnect => 'Sürətli Qoşulmanı istifadə et';
	@override String get quickConnectInstructions => 'Jellyfin-də Sürətli Qoşulmanı açın və bu kodu daxil edin.';
	@override String get quickConnectWaiting => 'Təsdiq gözlənilir…';
	@override String get quickConnectCancel => 'Ləğv et';
	@override String get quickConnectExpired => 'Sürətli Qoşulmanın vaxtı bitdi. Təzədən cəhd edin.';
	@override String get localDataRecoveryRequired => 'Plezy yerli daxil olma və gözləyən oxutma məlumatlarını təhlükəsiz bərpa edə bilmədi. Lütfən təzədən daxil olun.';
	@override String get pinCheckRejected => 'Plex PIN yoxlaması rədd edildi';
}

// Path: common
class _Translations$common$az extends Translations$common$en {
	_Translations$common$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Ləğv et';
	@override String get save => 'Yadda saxla';
	@override String get close => 'Bağla';
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
	@override String get notAvailable => 'N/A';
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
	@override String get supportDeveloper => 'Plezy-yə dəstək ol';
	@override String get supportDeveloperDescription => 'İnkişafı maliyyələşdirmək üçün Liberapay vasitəsilə iyanə edin';
	@override String get language => 'Dil';
	@override String get theme => 'Mövzu';
	@override String get appearance => 'Görünüş';
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
	@override String get libraryDensity => 'Kitabxana sıxlığı';
	@override String get displayScale => 'Ekran miqyası';
	@override String get compact => 'Sıx';
	@override String get comfortable => 'Rəhat';
	@override String get tvCornerSpotlightBackdrop => 'Künc işıqlandırma fonu';
	@override String get tvCornerSpotlightBackdropDescription => 'Arxa fonu ekranı örtmək əvəzinə sağ üst küncdə göstər';
	@override String get viewMode => 'Baxış rejimi';
	@override String get gridView => 'Tor';
	@override String get listView => 'Siyahı';
	@override String get showHeroSection => 'Xüsusi bölməni göstər';
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
	@override String get packedStereoUi => '3D Playback UI';
	@override String get bufferSize => 'Bufer həcmi';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Avtomatik (Tövsiyə olunan)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB yaddaş əlçatandır. ${size}MB bufer oynatmaya təsir edə bilər.';
	@override String get playbackBuffer => 'Oxutma buferi';
	@override String get playbackBufferAuto => 'Avtomatik (tövsiyə olunur)';
	@override String get playbackBufferLarge => 'Böyük';
	@override String get playbackBufferExtraLarge => 'Çox böyük';
	@override String get playbackBufferDescription => 'Qeyri-sabit əlaqələrə qarşı daha çox buferləyir. Bufer ölçüsü ilə də məhdudlaşır.';
	@override String get defaultQualityTitle => 'Defolt keyfiyyət';
	@override String get musicQualityTitle => 'Musiqi keyfiyyəti';
	@override String get subtitleStyling => 'Altyazı tənzimləmələri';
	@override String get subtitleStylingDescription => 'Altyazı görünüşünü özünüləşdirin';
	@override String get smallSkipDuration => 'Kiçik ötürmə müddəti';
	@override String get largeSkipDuration => 'Böyük ötürmə müddəti';
	@override String get rewindOnResume => 'Davam edərkən geri sar';
	@override String secondsUnit({required Object seconds}) => '${seconds} saniyə';
	@override String get defaultSleepTimer => 'Defolt yuxu taymeri';
	@override String minutesUnit({required Object minutes}) => '${minutes} dəqiqə';
	@override String get rememberTrackSelections => 'Hər film/serial üçün səs/altyazı seçimlərini xatırla';
	@override String get rememberTrackSelectionsDescription => 'Hər məzmun üçün səs və altyazı seçimlərini yadda saxla';
	@override String get followServerTrackSelections => 'Hər epizod üçün serverin trek seçimlərini istifadə et';
	@override String get followServerTrackSelectionsDescription => 'Epizod dəyişəndə cari seçimi köçürmək əvəzinə serverdə seçilmiş səs və altyazını tətbiq et';
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
	@override String get watchTogetherRelayDescription => 'Xüsusi rele təyin edin. Hər kəs eyni serveri istifadə etməlidir.';
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
	@override String get importSettingsInvalidFile => 'Bu fayl düzgün Plezy tənzimləmələr faylı deyil';
	@override String get importSettingsNoUser => 'Tənzimləmələri idxal etməzdən əvvəl daxil olun';
	@override String get shortcutsReset => 'Qısayollar defolt vəziyyətə sıfırlandı';
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
	@override String get autoSkip => 'Avtomatik ötür';
	@override String get autoSkipIntro => 'Girişi avtomatik ötür';
	@override String get autoSkipIntroDescription => 'Bir neçə saniyədən sonra giriş işarələrini avtomatik ötür';
	@override String get autoSkipCredits => 'Titrləri avtomatik ötür';
	@override String get autoSkipCreditsDescription => 'Titrləri avtomatik ötür və növbəti seriyanı oynat';
	@override String get forceSkipMarkerFallback => 'Ehtiyat işarələri məcburi et';
	@override String get forceSkipMarkerFallbackDescription => 'Plex işarələri olsa belə hissə başlığı şablonlarını istifadə et';
	@override String get autoSkipDelay => 'Avtomatik ötürmə ləngiməsi';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Avtomatik ötürməzdən əvvəl ${seconds} saniyə gözlə';
	@override String get introPattern => 'Giriş işarəsi şablonu';
	@override String get introPatternDescription => 'Hissə başlıqlarında giriş işarələrini tapmaq üçün Regex şablonu';
	@override String get creditsPattern => 'Titr işarəsi şablonu';
	@override String get creditsPatternDescription => 'Hissə başlıqlarında titr işarələrini tapmaq üçün Regex şablonu';
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
	@override String get tunneledPlaybackDescription => 'Video tünelləməni istifadə et. HDR oynatdıqda qara ekran görünürsə söndürün.';
	@override String get audioPassthrough => 'Səsin birbaşa ötürülməsi (Passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS səslərini yenidən kodlamadan TV və ya resiverə göndərir. Səs gəlmirsə söndürün.';
	@override String get audioPassthroughDescriptionAppleTv => 'Atmos daxil olmaqla Dolby Digital Plus üçün Apple-ın daxili dekoderini istifadə edin. DTS və TrueHD yenə də çoxkanallı PCM kimi oynadılır. Səs gəlmirsə söndürün.';
	@override String get audioDownmix => 'Stereo-ya çevir (Downmix)';
	@override String get audioDownmixDescription => 'Çoxkanallı səsi stereo dinamiklər və ya qulaqlıqlar üçün iki kanala endirir';
	@override String get downmixCenterBoost => 'Mərkəz kanal gücləndirilməsi';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Gücləndirmə (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Çevirmədə səsi normallaşdır';
	@override String get audioDownmixNormalizeDescription => 'Səs kəsilmələrinin qarşısını almaq üçün səviyyəni endirin.';
	@override String get dvConversionMode => 'Dolby Vision çevrilməsi';
	@override String get dvConversionModeDescription => 'ExoPlayer-in Dolby Vision Profile 7 fayllarını necə emal edəcəyini seçin.';
	@override String get dvConversionAuto => 'Avtomatik';
	@override String get dvConversionNative => 'Daxili / Söndürülüb';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Cihaz imkanlarının təyini və normal davranışdan istifadə et';
	@override String get dvConversionNativeDescription => 'Daxili DV7-ni məcburi et';
	@override String get dvConversionDv81Description => 'Dolby Vision profile 8.1-ə çevrilməni məcburi et';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision təbəqələrini sil və sadə HEVC kimi təqdim et';
	@override String get demuxer => 'Konteyner demukseri';
	@override String get demuxerDescription => 'Birbaşa oxudulan faylları hansı demukserin təhlil edəcəyi. Fayl düzgün işləmirsə, media3-ə keçin.';
	@override String get demuxerFfmpeg => 'FFmpeg (Tövsiyə olunan)';
	@override String get demuxerMedia3 => 'media3';
	@override String get requireProfileSelectionOnOpen => 'Açılışda profil soruş';
	@override String get requireProfileSelectionOnOpenDescription => 'Tətbiq hər dəfə açıldıqda profil seçimini göstər';
	@override String get forceTvMode => 'TV rejimini məcburi et';
	@override String get forceTvModeDescription => 'TV interfeysini məcburi et. Avtomatik təyin etməyən cihazlar üçündür.';
	@override String get startInFullscreen => 'Tam ekranda başlat';
	@override String get startInFullscreenDescription => 'Plezy-ni açılışda tam ekran rejimində aç';
	@override String get exitFullscreenOnPlayerClose => 'Oynadıcı bağlandıqda tam ekrandan çıx';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Video oynadıcını bağlayarkən avtomatik tam ekrandan çıx';
	@override String get autoHidePerformanceOverlay => 'Məhsuldarlıq paneli avtomatik gizlənsin';
	@override String get autoHidePerformanceOverlayDescription => 'Məhsuldarlıq panelini oynatıcı idarəetmələri ilə birlikdə gizlət';
	@override String get showNavBarLabels => 'Naviqasiya paneli yazılarını göstər';
	@override String get showNavBarLabelsDescription => 'Naviqasiya paneli ikonlarının altında mətni göstər';
	@override String get startupSection => 'Başlanğıc bölməsi';
	@override String get showExploreTab => 'Kəşf et nişanını göstər';
	@override String get showExploreTabDescription => 'Plex Discover və qoşulmuş izləmə xidmətlərindəki məzmunla Kəşf et nişanını göstər';
	@override String get liveTvDefaultFavorites => 'Canlı TV-də sevimli kanalları defolt et';
	@override String get liveTvDefaultFavoritesDescription => 'Canlı TV açıldıqda yalnız sevimli kanalları göstər';
	@override String get display => 'Ekran';
	@override String get homeScreen => 'Ana ekran';
	@override String get navigation => 'Naviqasiya';
	@override String get window => 'Pəncərə';
	@override String get content => 'Məzmun';
	@override String get player => 'Oynadıcı';
	@override String get subtitlesAndConfig => 'Altyazılar və konfiqurasiya';
	@override String get seekAndTiming => 'Sarğı və vaxt tənzimləməsi';
	@override String get behavior => 'Davranış';
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
	@override String get exportDialogTitle => 'Plezy tənzimləmələrini ixrac et';
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
		one: 'Bu, içindəki ${n} seriyanı və onun faylını siləcək.',
		other: 'Bu, içindəki ${n} seriyanı və onların fayllarını siləcək.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: 'Bu element ${n} fayl kimi saxlanılır və o silinəcək.',
		other: 'Bu element ${n} faylda saxlanılır və hamısı silinəcək.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: 'Eyni faylda saxlanılan ${n} başqa seriya da silinəcək:',
		other: 'Eyni faylda saxlanılan ${n} başqa seriya da silinəcək:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy bunun hansı faylları siləcəyini yoxlaya bilmədi, ona görə də yuxarıda adı çəkilən elementdən daha çoxunu silə bilər. Ləğv edib təzədən cəhd edin və ya yenə də silin.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Serveriniz bu element üçün fayl təfərrüatlarını təqdim etmədi, ona görə Plezy bunun hansı faylları siləcəyini yoxlaya bilmir. Yuxarıda adı çəkilən elementdən daha çoxunu silə bilər.';
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
	@override String get versionQualityButton => 'Versiya və Keyfiyyət';
	@override String get versionColumnHeader => 'Versiya';
	@override String get qualityColumnHeader => 'Keyfiyyət';
	@override String get qualityOriginal => 'Orijinal';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Kod dəyişmə əlçatan deyil — orijinal keyfiyyətdə oynadılır';
	@override String get subtitleUnavailableFallback => 'Seçilmiş altyazı yüklənə bilmədi — altyazısız davam edilir';
	@override String get pipButton => 'Pəncərə daxilində pəncərə rejimi';
	@override String get aspectRatioButton => 'Tərəf nisbəti';
	@override String get packedStereoSizingLocked => 'Can not change while playing 3D source';
	@override String get ambientLighting => 'Ətraf işıqlandırması';
	@override String get fullscreenButton => 'Tam ekrana keç';
	@override String get exitFullscreenButton => 'Tam ekrandan çıx';
	@override String get alwaysOnTopButton => 'Həmişə üstə';
	@override String get rotationLockButton => 'Dönmə kilidi';
	@override String get lockScreen => 'Ekranı kilidlə';
	@override String get screenLockButton => 'Ekran kilidi';
	@override String get longPressToUnlock => 'Kilidi açmaq üçün uzun basın';
	@override String get timelineSlider => 'Video zaman çubuğu';
	@override String get volumeSlider => 'Səs səviyyəsi';
	@override String endsAt({required Object time}) => 'Bitiş vaxtı: ${time}';
	@override String get pipActive => 'Pəncərə daxilində pəncərə rejimində oynadılır';
	@override String get pipFailed => 'PiP rejimi başladılarkən xəta';
	@override String get screenshotSaved => 'Ekran şəkli yadda saxlanıldı';
	@override String zoomPercent({required Object percent}) => 'Miqyas %${percent}';
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
		one: 'Baxılmış ${n} yükləmə avtomatik silindi',
		other: 'Baxılmış ${n} yükləmə avtomatik silindi',
	);
	@override String get removedFromContinueWatching => 'İzləməyə davam et-dən silindi';
	@override String errorLoading({required Object error}) => 'Xəta: ${error}';
	@override String get searchPartialResults => 'Bəzi media serverlərində axtarış aparıla bilmədi. Mövcud nəticələr göstərilir.';
	@override String get streamInterrupted => 'Yayım kəsildi. Təzədən cəhd etmək üçün oynat düyməsinə basın.';
	@override String get liveStreamInterrupted => 'Canlı yayım kəsildi. Təzədən cəhd etmək üçün oynat düyməsinə basın.';
	@override String get fileInfoNotAvailable => 'Fayl məlumatı əlçatan deyil';
	@override String get playbackAuthenticationRequired => 'Bu elementi oynatmaq üçün media serverinə yenidən daxil olun.';
	@override String get playbackServerUnavailable => 'Media serveri əlçatan deyil. Sonra təzədən cəhd edin.';
	@override String get playbackDataInvalid => 'Server yanlış oynatma məlumatı qaytardı.';
	@override String get playbackCancelled => 'Oynatma ləğv edildi.';
	@override String get playbackFailed => 'Oynatma başladılarkən xəta.';
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
	@override String get logsUploaded => 'Jurnallar yükləndi';
	@override String get logsUploadFailed => 'Jurnallar yüklənə bilmədi';
	@override String get logId => 'Jurnal ID-si';
	@override String get burnedSubtitlesUseMenu => 'Altyazılar bu yayıma həkk edilib. Onları altyazı menyusundan dəyişin.';
	@override String get noVideoUrl => 'Video URL-i mövcud deyil';
	@override String get playbackNoMediaSources => 'Server oynadıla bilən media mənbəyi qaytarmadı';
	@override String get playbackDataNotPrepared => 'Məlumatları hazır olmadan oynatma başladıldı';
	@override String get streamSelectionUnavailable => 'Bu mənbə üçün yayım seçimi mövcud deyil';
	@override String get streamSelectionFailed => 'Seçilmiş yayımları tətbiq etmək olmadı';
	@override String get serverUnavailableForProfile => 'Aktiv profil üçün heç bir server mövcud deyil';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$az extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
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
	@override String get anchorToScreen => 'Ekrana bərkit';
	@override String get anchorToScreenDescription => 'Mətn altyazılarını geniş ekranlı videonun altındakı qara zolaqlarda göstər';
	@override String get bold => 'Qalın';
	@override String get italic => 'Kursiv';
	@override String get renderResolution => 'Emal imkanı (Resolution)';
	@override String get renderResolutionScreen => 'Ekran imkanı';
	@override String get renderResolutionVideo => 'Video imkanı';
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
	@override String get addPlezyProfile => 'Plezy profili əlavə et';
	@override String get switchingProfile => 'Profil dəyişdirilir…';
	@override String get deleteThisProfileTitle => 'Bu profil silinsin?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} silinəcək. Qoşulmalar təsirlənmir.';
	@override String get active => 'Aktiv';
	@override String get manage => 'İdarə et';
	@override String get delete => 'Sil';
	@override String get signOut => 'Çıxış et';
	@override String get signOutPlexTitle => 'Plex-dən çıxılsın?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} və bütün Plex Ev istifadəçiləri silinsin?';
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
	@override String get borrowEmptySubtitle => 'Əvvəlcə başqa bir profile Plex və ya Jellyfin qoşun.';
	@override String get borrowLoadFailed => 'Əlçatan qoşulmalar yüklənə bilmədi. Təzədən cəhd edin.';
	@override String borrowFromProfile({required Object displayName}) => '${displayName} profilindən';
	@override String get borrowConnectionBorrowed => 'Qoşulma istifadə edildi.';
	@override String get borrowFailed => 'Qoşulma istifadə edilə bilmədi.';
	@override String get incorrectPin => 'Səhv PIN.';
	@override String get incorrectPinTryAgain => 'Səhv PIN. Lütfən təzədən cəhd edin.';
	@override String get sourceProfileMissingParentAccount => 'Mənbə profilin əsas hesabı yoxdur.';
	@override String get failedToLoadHomeUsers => 'Plex Ev istifadəçiləriniz yüklənə bilmədi. Bağlantınızı yoxlayın.';
	@override String get failedToVerifyPin => 'PIN təsdiqlənə bilmədi.';
	@override String get newProfile => 'Yeni profil';
	@override String get profileNameHint => 'məs. Qonaqlar, Uşaqlar, Qonaq otağı';
	@override String get pinProtectionOptional => 'PIN mühafizəsi (istəyə bağlı)';
	@override String get pinExplain => 'Profillər arası keçid üçün 4 rəqəmli PIN tələb olunur.';
	@override String get continueButton => 'Davam et';
	@override String get pinsDontMatch => 'PIN-lər uyğun gəlmir';
	@override String get tokenIdentityMismatch => 'Plex profil tokeni gözlənilməyən serveri müəyyən etdi';
}

// Path: connections
class _Translations$connections$az extends Translations$connections$en {
	_Translations$connections$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Qoşulmalar';
	@override String get addConnection => 'Qoşulma əlavə et';
	@override String get addConnectionSubtitleNoProfile => 'Plex ilə daxil olun və ya Jellyfin serverinə qoşulun';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName} profilinə əlavə et: Plex, Jellyfin və ya başqa profil qoşulması';
	@override String sessionExpiredOne({required Object name}) => '${name} üçün seansın vaxtı bitdi';
	@override String sessionExpiredMany({required Object count}) => '${count} server üçün seansın vaxtı bitdi';
	@override String get signInAgain => 'Yenidən daxil ol';
	@override String editMediaBrowserTitle({required Object product}) => '${product} qoşulmasını düzəliş et';
	@override String editMediaBrowserIntro({required Object serverName}) => '${serverName} üçün URL-lər əlavə edin və ya silin. Plezy əlçatan olan ən aşağı gecikməli URL-i istifadə edəcək.';
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
		one: '${n} başlıq',
		other: '${n} başlıq',
	);
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
}

// Path: libraries
class _Translations$libraries$az extends Translations$libraries$en {
	_Translations$libraries$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
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
}

// Path: about
class _Translations$about$az extends Translations$about$en {
	_Translations$about$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Haqqında';
	@override String get openSourceLicenses => 'Açıq mənbə lisenziyaları';
	@override String versionLabel({required Object version}) => 'Versiya ${version}';
	@override String get appDescription => 'Flutter üçün gözəl bir Plex və Jellyfin klienti';
	@override String get viewLicensesDescription => 'Üçüncü tərəf kitabxanalarının lisenziyalarına baxın';
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
}

// Path: startup
class _Translations$startup$az extends Translations$startup$en {
	_Translations$startup$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy başlaya bilmədi';
	@override String get failedBody => 'Başlatma zamanı nəsə səhv getdi. Aşağıdakı təfərrüatlar nəyin uğursuz olduğunu göstərir.';
	@override String get failedBodyRepairable => 'Plezy-nin saxlanmış tənzimləmə faylı zədələnib və Plezy başlamazdan əvvəl yenidən qurulmalıdır. Təzədən cəhd etmək kömək etməyəcək — Yaddaşı təmir et seçin.';
	@override String get phaseLabel => 'Addım';
	@override String get showDetails => 'Təfərrüatları göstər';
	@override String get hideDetails => 'Təfərrüatları gizlət';
	@override String get copyDetails => 'Təfərrüatları kopyala';
	@override String get detailsCopied => 'Təfərrüatlar buferə kopyalandı';
	@override String get uploadDetails => 'Təfərrüatları yüklə';
	@override String get repairStorage => 'Yaddaşı təmir et';
	@override String get repairTitle => 'Saxlanmış məlumatlar təmir edilsin?';
	@override String get repairBodyCommon => 'Plezy-nin tənzimləmə faylı zədələnib və oxuna bilmir. Təmir bütün tənzimləmələri defolt vəziyyətinə sıfırlayır.';
	@override String get repairBodyOneCredential => 'Bir saxlanmış daxil olma məlumatı zədələnib və oxuna bilmir. Təmir yalnız onu silir; digər tənzimləmələrinizə toxunulmur.';
	@override String get repairBodySignInsKept => 'Serverləriniz və profilləriniz daxil olmuş vəziyyətdə qalmalıdır.';
	@override String get repairBodySignInsLost => 'Saxlanmış daxil olmalarınızı qoruyan açar bu fayldan bərpa edilə bilmir, ona görə də hər serverə və profilə yenidən daxil olmalı olacaqsınız. Media serverinizdə heç nəyə təsir olunmur.';
	@override String get repairBodySessionsUncertain => 'İzləyicilər (MAL, AniList, Simkl, Trakt) və Seerr ayrıca saxlanılır və qalıb-qalmayacaqları bəlli deyil. Plezy sizə nəyi saxladığını dəqiq bildirəcək.';
	@override String get repairConfirm => 'Təmir et';
	@override String get repairSucceeded => 'Yaddaş təmir edildi';
	@override String get repairNeedsRestart => 'Yaddaş təmir edildi — yenidən başlatma tələb olunur';
	@override String get restartRequiredBody => 'Məlumatlarınız təmir edildi, lakin Plezy ondan istifadə etmək üçün yenidən başlamalıdır. Plezy-ni bağlayın və yenidən açın.';
	@override String get quitPlezy => 'Plezy-dən çıx';
	@override String get repairFailed => 'Təmir uğursuz oldu';
	@override String get repairKeptSignIns => 'Serverləriniz və profilləriniz hələ də daxil olub.';
	@override String get repairLostSignIns => 'Saxlanmış daxil olmalarınızı qoruyan açar bərpa edilə bilmədi. Hər serverə və profilə yenidən daxil olmalı olacaqsınız.';
	@override String get repairLostSessions => 'Ən azı bir izləyici və ya Seerr əlaqəsi itirildi və yenidən qoşulmalıdır.';
	@override String get backupTitle => 'Zədələnmiş faylın nüsxəsi saxlanıldı';
	@override String get backupWarning => 'O, daxil olma məlumatlarınızı ehtiva edir. Onu yükləməyin və ya paylaşmayın.';
	@override String get deleteBackup => 'Nüsxəni sil';
	@override String get backupDeleted => 'Nüsxə silindi.';
	@override String get previousFailureTitle => 'Plezy son dəfə başlaya bilmədi';
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
	@override String get title => 'Kəşf et';
	@override String get selectSource => 'Mənbə seçin';
	@override late final _Translations$explore$rows$az rows = _Translations$explore$rows$az._(_root);
	@override late final _Translations$explore$status$az status = _Translations$explore$status$az._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n,
		one: '${n} seriya',
		other: '${n} seriya',
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
	@override String get emptyTitle => 'Hələlik burada heç nə yoxdur';
	@override String emptyMessage({required Object source}) => '${source} mənbəsindən olan sətirlər burada görünəcək.';
	@override String searchHint({required Object source}) => '${source} daxilində axtar';
	@override String searchEmpty({required Object query}) => '"${query}" üçün nəticə tapılmadı';
	@override String searchPrompt({required Object source}) => '${source} vasitəsilə kino və seriallar axtarın.';
	@override String get searchFailed => 'Axtarış uğursuz oldu. Bağlantınızı yoxlayın.';
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
		one: '${n} nəticə',
		other: '${n} nəticə',
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
	@override String get unknownHub => 'Məlum deyil';
	@override String get unknownError => 'Bilinməyən xəta';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Bilinməyən kanal';
	@override String get live => 'CANLI';
	@override String get reloadGuide => 'Bələdçini yenilə';
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
	@override String get favoritesLoadFailed => 'Sevimlilər yüklənə bilmədi.';
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
	@override String get rulesProcessRequested => 'Qaydaların yenidən qiymətləndirilməsi tələb olundu';
	@override String get recordShow => 'Şounu yaz';
	@override late final _Translations$liveTv$recordSettings$az recordSettings = _Translations$liveTv$recordSettings$az._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} dəq sonra başlayır';
	@override String dayAtTime({required Object day, required Object time}) => '${day}, saat ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} etibarsız Canlı TV oynatma məlumatı qaytardı';
	@override String get failedToStartChannel => 'Canlı kanalı başlatmaq olmadı';
	@override String get failedToBuildStreamUrl => 'Yayım URL-i yaratmaq olmadı';
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
	@override String itemCount({required Object count}) => '${count} element';
	@override String get oneItem => '1 element';
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
		one: '${n} mahnı',
		other: '${n} mahnı',
	);
	@override String get nowPlaying => 'İndi oynadılır';
	@override String playingFrom({required Object title}) => '${title} mənbəsindən oynadılır';
	@override String get queue => 'Növbə';
	@override String get clearQueue => 'Növbəni təmizlə';
	@override String get lyrics => 'Mahnı sözləri';
	@override String get noLyrics => 'Mahnı sözləri yoxdur';
	@override String get sleepTimer => 'Yuxu taymeri';
	@override String get sleepTimerEndOfTrack => 'Mahnının sonu';
	@override String sleepTimerMinutes({required Object n}) => '${n} dəqiqə';
	@override String get stopPlayback => 'Oynatmanı saxla';
	@override String get previousTrack => 'Əvvəlki mahnı';
	@override String get nextTrack => 'Növbəti mahnı';
	@override String get repeat => 'Təkrarla';
	@override String get repeatAll => 'Hamısını təkrarla';
	@override String get repeatOne => 'Birini təkrarla';
	@override String get instantMixNoServer => 'Ani miks üçün heç bir server mövcud deyil';
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
	@override String get createSession => 'Seans yarat';
	@override String get creating => 'Yaradılır...';
	@override String get joinSession => 'Seansa qoşul';
	@override String get joining => 'Qoşulunur...';
	@override String get controlMode => 'İdarəetmə rejimi';
	@override String get controlModeQuestion => 'Oynatmanı kim idarə edə bilər?';
	@override String get hostOnly => 'Yalnız təşkilatçı';
	@override String get anyone => 'Hər kəs';
	@override String get hostingSession => 'Seans təşkil olunur';
	@override String get inSession => 'Seansdadır';
	@override String get sessionCode => 'Seans kodu';
	@override String get openSessionControls => 'Birlikdə İzlə seans idarəetmələrini aç';
	@override String get copySessionCode => 'Seans kodunu kopyala';
	@override String get hostControlsPlayback => 'Oynatmanı təşkilatçı idarə edir';
	@override String get anyoneCanControl => 'Oynatmanı hər kəs idarə edə bilər';
	@override String get hostControls => 'Təşkilatçı idarə edir';
	@override String get anyoneControls => 'Hər kəs idarə edir';
	@override String get participants => 'İştirakçılar';
	@override String get host => 'Təşkilatçı';
	@override String get hostBadge => 'TƏŞKİLATÇI';
	@override String get youAreHost => 'Təşkilatçı sizsiniz';
	@override String get watchingWithOthers => 'Başqaları ilə izlənilir';
	@override String get endSession => 'Seansı bitir';
	@override String get leaveSession => 'Seansdan çıx';
	@override String get endSessionQuestion => 'Seans bitirilsin?';
	@override String get leaveSessionQuestion => 'Seansdan çıxılsın?';
	@override String get endSessionConfirm => 'Bu bütün iştirakçılar üçün seansı bitirəcək.';
	@override String get leaveSessionConfirm => 'Seansdan xaric ediləcəksiniz.';
	@override String get endSessionConfirmOverlay => 'Bu bütün iştirakçılar üçün izləmə seansını bitirəcək.';
	@override String get leaveSessionConfirmOverlay => 'İzləmə seansı ilə əlaqəniz kəsiləcək.';
	@override String get end => 'Bitir';
	@override String get leave => 'Çıx';
	@override String get syncing => 'Eyniləşdirilir...';
	@override String get joinWatchSession => 'İzləmə seansına qoşul';
	@override String get enterCodeHint => '5 rəqəmli/hərfli kodu daxil edin';
	@override String get pasteFromClipboard => 'Buferdən yapışdır';
	@override String get pleaseEnterCode => 'Lütfən seans kodunu daxil edin';
	@override String get codeMustBe5Chars => 'Seans kodu 5 simvol olmalıdır';
	@override String get joinInstructions => 'Qoşulmaq üçün təşkilatçının seans kodunu daxil edin.';
	@override String get failedToCreate => 'Seans yaradıla bilmədi';
	@override String get failedToJoin => 'Seansa qoşuluna bilmədi';
	@override String get sessionCodeCopied => 'Seans kodu buferə kopyalandı';
	@override String get relayUnreachable => 'Rele serverinə çatmaq olmur. İnternet provayderinin bloklaması Birlikdə İzləməyə mane ola bilər.';
	@override String get reconnectingToHost => 'Təşkilatçıya yenidən qoşulunur...';
	@override String get currentPlayback => 'Cari oynatma';
	@override String get joinCurrentPlayback => 'Cari oynatmaya qoşul';
	@override String get joinCurrentPlaybackDescription => 'Təşkilatçının indi baxdığı hissəyə keçin';
	@override String get failedToOpenCurrentPlayback => 'Cari oynatma açıla bilmədi';
	@override String participantJoined({required Object name}) => '${name} qoşuldu';
	@override String participantLeft({required Object name}) => '${name} ayrıldı';
	@override String participantPaused({required Object name}) => '${name} fasilə etdi';
	@override String participantResumed({required Object name}) => '${name} davam etdirdi';
	@override String participantSeeked({required Object name}) => '${name} oynatma mövqeyini dəyişdi';
	@override String participantBuffering({required Object name}) => '${name} buferləyir';
	@override String participantNeedsUpdate({required Object name}) => '${name} köhnə tətbiq versiyasındadır';
	@override String resumingWithout({required Object name}) => '${name} olmadan davam edilir';
	@override String get waitingForParticipants => 'Digərlərinin yükləməsi gözlənilir...';
	@override String waitingForName({required Object name}) => '${name} gözlənilir...';
	@override String get recentRooms => 'Son otaqlar';
	@override String get renameRoom => 'Otağın adını dəyişdir';
	@override String get removeRoom => 'Sil';
	@override String get guestSwitchUnavailable => 'Keçid etmək olmadı — eyniləşdirmə üçün server əlçatan deyil';
	@override String get guestSwitchFailed => 'Keçid etmək olmadı — məzmun tapılmadı';
	@override String get defaultDisplayName => 'İstifadəçi';
	@override late final _Translations$watchTogether$errors$az errors = _Translations$watchTogether$errors$az._(_root);
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
	@override String get storageFull => 'Cihaz yaddaşı dolu olduğu üçün yükləmə dayandırıldı.';
	@override String episodesQueued({required Object count}) => 'Yükləmə üçün ${count} seriya növbəyə alındı';
	@override String get downloadDeleted => 'Yükləmə silindi';
	@override String deleteConfirm({required Object title}) => '"${title}" bu cihazdan silinsin?';
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
	@override String get deleteAll => 'Hamısını sil';
	@override String get selectVersion => 'Versiya seç';
	@override String get allEpisodes => 'Bütün seriyalar';
	@override String get unwatchedOnly => 'Yalnız baxılmayanlar';
	@override String nextNUnwatched({required Object count}) => 'Növbəti ${count} baxılmayan';
	@override String get customAmount => 'Xüsusi miqdar...';
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
	@override String get activeSyncRules => 'Eyniləşdirmə qaydaları';
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
	@override String get syncRuleNotAvailableForProfile => 'Cari profil üçün əlçatan deyil';
	@override String get syncRuleUnknownServer => 'Bilinməyən server';
	@override String get syncRuleListCreated => 'Eyniləşdirmə qaydası yaradıldı';
	@override late final _Translations$downloads$backgroundWarning$az backgroundWarning = _Translations$downloads$backgroundWarning$az._(_root);
	@override String get unknownShow => 'Məlum olmayan serial';
	@override String get unknownSeason => 'Məlum olmayan mövsüm';
	@override String get unknownAlbum => 'Məlum olmayan albom';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} tamamlandı';
	@override String get errorFileNotFound => 'Fayl tapılmadı (404)';
	@override String get errorDownloadFailed => 'Yükləmə uğursuz oldu';
	@override String errorPostProcessing({required Object error}) => 'Sonrakı emal uğursuz oldu: ${error}';
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
	@override String get performanceOverlay => 'Məhsuldarlıq paneli';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Əhatəli səs';
	@override String get audioOutputSpatial => 'Məkan səsi';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioNormalization => 'Səsin gurluğunu normallaşdır';
	@override String get audioDownmix => 'Stereo-ya çevir';
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
}

// Path: matchScreen
class _Translations$matchScreen$az extends Translations$matchScreen$en {
	_Translations$matchScreen$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get match => 'Uyğunlaşdır...';
	@override String get fixMatch => 'Uyğunluğu düzəlt...';
	@override String get unmatch => 'Uyğunluğu ləğv et';
	@override String get unmatchConfirm => 'Bu uyğunluq təmizlənsin?';
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
	@override String get disconnectConfirmBody => 'Plezy Trakt-a məlumat göndərməyi dayandıracaq.';
	@override String get scrobble => 'Real vaxt rejimində izləmə';
	@override String get scrobbleDescription => 'Oynatma zamanı Trakt-a məlumat göndər.';
	@override String get watchedSync => 'Baxış statusunu eyniləşdir';
	@override String get watchedSyncDescription => 'Plezy-də baxıldı işarələdikdə Trakt-da da işarələnsin.';
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
	@override String get disconnectConfirmBody => 'Plezy bu Seerr ünvanını unudacaq.';
	@override String get request => 'Sorğu göndər';
	@override String get request4k => '4K sorğu göndər';
	@override String get seasons => 'Mövsümlər';
	@override String get allSeasons => 'Bütün mövsümlər';
	@override String get advancedOptions => 'Təkmilləşdirilmiş';
	@override String get destinationServer => 'Hədəf server';
	@override String get qualityProfile => 'Keyfiyyət profili';
	@override String get rootFolder => 'Kök qovluq';
	@override String get languageProfile => 'Dil profili';
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
	@override String get notInitialized => 'Bu Seerr instansiyasının ilkin quraşdırılması tamamlanmayıb';
	@override String get noPlexTokenForReauth => 'Yenidən daxil olmaq üçün Plex tokeni mövcud deyil';
	@override String get noStoredCredentials => 'Yenidən daxil olmaq üçün yadda saxlanmış giriş məlumatları mövcud deyil';
	@override String get signInRejected => 'Daxil olma rədd edildi';
	@override String get noSessionCookie => 'Seerr sessiya kukisi yaratmadı';
	@override String get freshCookieRejected => 'Seerr yeni sessiya kukisini rədd etdi';
	@override String get noUserInformation => 'Seerr istifadəçi məlumatlarını qaytarmadı';
	@override String get sessionRejectedAfterReauth => 'Yenidən daxil olduqdan sonra sessiya rədd edildi';
}

// Path: services
class _Translations$services$az extends Translations$services$en {
	_Translations$services$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get title => 'Xidmətlər';
	@override String get hubSubtitle => 'İzləmə tərəqqisini eyniləşdirin və yeni başlıqlar sorğulayın.';
	@override String get notConnected => 'Qoşulmayıb';
	@override String connectedAs({required Object username}) => '@${username} olaraq qoşuldu';
	@override String get scrobble => 'Tərəqqini avtomatik izlə';
	@override String get scrobbleDescription => 'Siyahınızı avtomatik yeniləyin.';
	@override String disconnectConfirm({required Object service}) => '${service} ayırılsın?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy ${service} yeniləməyi dayandıracaq.';
	@override String connectFailed({required Object service}) => '${service} qoşula bilmədi. Təzədən cəhd edin.';
	@override late final _Translations$services$names$az names = _Translations$services$names$az._(_root);
	@override late final _Translations$services$deviceCode$az deviceCode = _Translations$services$deviceCode$az._(_root);
	@override late final _Translations$services$oauthProxy$az oauthProxy = _Translations$services$oauthProxy$az._(_root);
	@override late final _Translations$services$pendingAuth$az pendingAuth = _Translations$services$pendingAuth$az._(_root);
	@override late final _Translations$services$libraryFilter$az libraryFilter = _Translations$services$libraryFilter$az._(_root);
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
	@override String get signInWithPlexCardSubtitle => 'Bu cihazı səlahiyyətləndirin.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex hesabını səlahiyyətləndirin.';
	@override String connectToMediaBrowserCard({required Object product}) => '${product}-a qoşul';
	@override String get connectToMediaBrowserCardSubtitle => 'Server URL-inizi, istifadəçi adınızı və şifrənizi daxil edin.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => '${product} serverinizə daxil olun. ${name} ilə əlaqələndirilir.';
	@override String get borrowFromAnotherProfile => 'Başqa profildən götür';
	@override String get borrowFromAnotherProfileSubtitle => 'Başqa profilin qoşulmasını yenidən istifadə edin.';
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
}

// Path: common.ratingSource
class _Translations$common$ratingSource$az extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Tənqidçilər';
	@override String get audience => 'Tamaşaçılar';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes tənqidçiləri';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes tamaşaçıları';
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
	@override String get shaderToggle => 'Şeyderləri aç/bağla';
	@override String get skipMarker => 'Girişi/Titrləri ötür';
	@override String get screenshot => 'Ekran şəkli çək';
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
		one: '${n} şərh',
		other: '${n} şərh',
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
		one: '${n} istifadəçi tövsiyə edir',
		other: '${n} istifadəçi tövsiyə edir',
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

// Path: watchTogether.errors
class _Translations$watchTogether$errors$az extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String get timedOut => 'Rele serveri vaxtında cavab vermədi';
	@override String get connectionLost => 'Bağlantı seans hazır olmamış kəsildi';
	@override String get invalidRelayResponse => 'Rele serveri gözlənilməz cavab göndərdi';
	@override String get sessionEnded => 'Təşkilatçı seansı bitirdi';
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
	@override String get sheetIntro => 'Android Plezy-nin arxa fonda etibarlı şəkildə yükləməsinə mane olur.';
	@override String get sheetIntroDegraded => 'Cihazınız Plezy-nin arxa fonda nə vaxt yükləyə biləcəyini məhdudlaşdırır.';
	@override String get reasonBackgroundRestricted => 'Plezy-nin arxa fon istifadəsi məhdudlaşdırılıb. Batareya və ya arxa fon istifadəsini "Məhdudiyyətsiz" edin.';
	@override String get reasonStandbyRestricted => 'Android Plezy-ni məhdud gözləmə rejiminə salıb. Batareya istifadəsini "Məhdudiyyətsiz" edin.';
	@override String get reasonDownloadChannelBlocked => 'Yükləmə bildirişləri söndürülüb, ona görə gedişat və idarəetmələr əlçatan olmaya bilər.';
	@override String get reasonNotificationsDisabled => 'Bildirişlər söndürülüb. Android 13 və daha yeni versiyalarda uzun arxa fon yükləmələri üçün onlar tələb olunur.';
	@override String get reasonDataSaver => 'Data Saver aktivdir və bu, mobil internetdə arxa fon yükləmələrini bloklayır. Wi-Fi ilə yükləmələr işləməlidir.';
	@override String get reasonOemUnknown => 'Plezy arxa fonda olarkən yükləmələr dəfələrlə dayandı. Plezy-nin batareya və ya arxa fon istifadəsi tənzimləmələrini yoxlayın.';
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
	@override String get discoveryDescription => 'Eyni Plex hesabına sahib Plezy cihazları burada görünür';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Qoşulunur...';
	@override String get searchingForDevices => 'Cihazlar axtarılır...';
	@override String get noDevicesFound => 'Şəbəkənizdə cihaz tapılmadı';
	@override String get noDevicesHint => 'Masaüstündə Plezy-ni açın və eyni Wi-Fi-dan istifadə edin';
	@override String get availableDevices => 'Əlçatan cihazlar';
	@override String get manualConnection => 'Əl ilə qoşulma';
	@override String get cryptoInitFailed => 'Təhlükəsiz qoşulma başladılarkən xəta. Əvvəlcə Plex-ə daxil olun.';
	@override String get validationHostRequired => 'Lütfən əsas cihaz ünvanını daxil edin';
	@override String get validationHostFormat => 'Format IP:port şəklində olmalıdır';
	@override String get connectionTimedOut => 'Qoşulma vaxtı bitdi.';
	@override String get sessionNotFound => 'Cihaz tapılmadı.';
	@override String get authFailed => 'Kimlik doğrulanması uğursuz oldu.';
	@override String failedToConnect({required Object error}) => 'Qoşulma uğursuz oldu: ${error}';
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

// Path: services.deviceCode
class _Translations$services$deviceCode$az extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$az._(TranslationsAz root) : this._root = root, super.internal(root);

	final TranslationsAz _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy-ni ${service} üzərində aktivləşdirin';
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
}

/// The flat map containing all translations for locale <az>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAz {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Plex ilə daxil ol',
			'auth.showQRCode' => 'QR kodu göstər',
			'auth.authenticate' => 'Təsdiqlə',
			'auth.authenticationTimeout' => 'Təsdiqləmə vaxtı bitdi. Lütfən təzədən cəhd edin.',
			'auth.scanQRToSignIn' => 'Daxil olmaq üçün bu QR kodu skan edin',
			'auth.waitingForAuth' => 'Təsdiqləmə gözlənilir...\nSəyahətçinizdən (brauzer) daxil olun.',
			'auth.useBrowser' => 'Səyahətçini istifadə et',
			'auth.or' => 'və ya',
			'auth.connectToMediaBrowser' => ({required Object product}) => '${product}-a qoşul',
			'auth.useQuickConnect' => 'Sürətli Qoşulmanı istifadə et',
			'auth.quickConnectInstructions' => 'Jellyfin-də Sürətli Qoşulmanı açın və bu kodu daxil edin.',
			'auth.quickConnectWaiting' => 'Təsdiq gözlənilir…',
			'auth.quickConnectCancel' => 'Ləğv et',
			'auth.quickConnectExpired' => 'Sürətli Qoşulmanın vaxtı bitdi. Təzədən cəhd edin.',
			'auth.localDataRecoveryRequired' => 'Plezy yerli daxil olma və gözləyən oxutma məlumatlarını təhlükəsiz bərpa edə bilmədi. Lütfən təzədən daxil olun.',
			'auth.pinCheckRejected' => 'Plex PIN yoxlaması rədd edildi',
			'common.cancel' => 'Ləğv et',
			'common.save' => 'Yadda saxla',
			'common.close' => 'Bağla',
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
			'common.ratingSource.critic' => 'Tənqidçilər',
			'common.ratingSource.audience' => 'Tamaşaçılar',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes tənqidçiləri',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes tamaşaçıları',
			'common.notAvailable' => 'N/A',
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
			'settings.supportDeveloper' => 'Plezy-yə dəstək ol',
			'settings.supportDeveloperDescription' => 'İnkişafı maliyyələşdirmək üçün Liberapay vasitəsilə iyanə edin',
			'settings.language' => 'Dil',
			'settings.theme' => 'Mövzu',
			'settings.appearance' => 'Görünüş',
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
			'settings.libraryDensity' => 'Kitabxana sıxlığı',
			'settings.displayScale' => 'Ekran miqyası',
			'settings.compact' => 'Sıx',
			'settings.comfortable' => 'Rəhat',
			'settings.tvCornerSpotlightBackdrop' => 'Künc işıqlandırma fonu',
			'settings.tvCornerSpotlightBackdropDescription' => 'Arxa fonu ekranı örtmək əvəzinə sağ üst küncdə göstər',
			'settings.viewMode' => 'Baxış rejimi',
			'settings.gridView' => 'Tor',
			'settings.listView' => 'Siyahı',
			'settings.showHeroSection' => 'Xüsusi bölməni göstər',
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
			'settings.packedStereoUi' => '3D Playback UI',
			'settings.bufferSize' => 'Bufer həcmi',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Avtomatik (Tövsiyə olunan)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB yaddaş əlçatandır. ${size}MB bufer oynatmaya təsir edə bilər.',
			'settings.playbackBuffer' => 'Oxutma buferi',
			'settings.playbackBufferAuto' => 'Avtomatik (tövsiyə olunur)',
			'settings.playbackBufferLarge' => 'Böyük',
			'settings.playbackBufferExtraLarge' => 'Çox böyük',
			'settings.playbackBufferDescription' => 'Qeyri-sabit əlaqələrə qarşı daha çox buferləyir. Bufer ölçüsü ilə də məhdudlaşır.',
			'settings.defaultQualityTitle' => 'Defolt keyfiyyət',
			'settings.musicQualityTitle' => 'Musiqi keyfiyyəti',
			'settings.subtitleStyling' => 'Altyazı tənzimləmələri',
			'settings.subtitleStylingDescription' => 'Altyazı görünüşünü özünüləşdirin',
			'settings.smallSkipDuration' => 'Kiçik ötürmə müddəti',
			'settings.largeSkipDuration' => 'Böyük ötürmə müddəti',
			'settings.rewindOnResume' => 'Davam edərkən geri sar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} saniyə',
			'settings.defaultSleepTimer' => 'Defolt yuxu taymeri',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} dəqiqə',
			'settings.rememberTrackSelections' => 'Hər film/serial üçün səs/altyazı seçimlərini xatırla',
			'settings.rememberTrackSelectionsDescription' => 'Hər məzmun üçün səs və altyazı seçimlərini yadda saxla',
			'settings.followServerTrackSelections' => 'Hər epizod üçün serverin trek seçimlərini istifadə et',
			'settings.followServerTrackSelectionsDescription' => 'Epizod dəyişəndə cari seçimi köçürmək əvəzinə serverdə seçilmiş səs və altyazını tətbiq et',
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
			'settings.watchTogetherRelayDescription' => 'Xüsusi rele təyin edin. Hər kəs eyni serveri istifadə etməlidir.',
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
			'settings.importSettingsInvalidFile' => 'Bu fayl düzgün Plezy tənzimləmələr faylı deyil',
			'settings.importSettingsNoUser' => 'Tənzimləmələri idxal etməzdən əvvəl daxil olun',
			'settings.shortcutsReset' => 'Qısayollar defolt vəziyyətə sıfırlandı',
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
			'settings.autoSkip' => 'Avtomatik ötür',
			'settings.autoSkipIntro' => 'Girişi avtomatik ötür',
			'settings.autoSkipIntroDescription' => 'Bir neçə saniyədən sonra giriş işarələrini avtomatik ötür',
			'settings.autoSkipCredits' => 'Titrləri avtomatik ötür',
			'settings.autoSkipCreditsDescription' => 'Titrləri avtomatik ötür və növbəti seriyanı oynat',
			'settings.forceSkipMarkerFallback' => 'Ehtiyat işarələri məcburi et',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex işarələri olsa belə hissə başlığı şablonlarını istifadə et',
			'settings.autoSkipDelay' => 'Avtomatik ötürmə ləngiməsi',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Avtomatik ötürməzdən əvvəl ${seconds} saniyə gözlə',
			'settings.introPattern' => 'Giriş işarəsi şablonu',
			'settings.introPatternDescription' => 'Hissə başlıqlarında giriş işarələrini tapmaq üçün Regex şablonu',
			'settings.creditsPattern' => 'Titr işarəsi şablonu',
			'settings.creditsPatternDescription' => 'Hissə başlıqlarında titr işarələrini tapmaq üçün Regex şablonu',
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
			'settings.tunneledPlaybackDescription' => 'Video tünelləməni istifadə et. HDR oynatdıqda qara ekran görünürsə söndürün.',
			'settings.audioPassthrough' => 'Səsin birbaşa ötürülməsi (Passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS səslərini yenidən kodlamadan TV və ya resiverə göndərir. Səs gəlmirsə söndürün.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Atmos daxil olmaqla Dolby Digital Plus üçün Apple-ın daxili dekoderini istifadə edin. DTS və TrueHD yenə də çoxkanallı PCM kimi oynadılır. Səs gəlmirsə söndürün.',
			'settings.audioDownmix' => 'Stereo-ya çevir (Downmix)',
			'settings.audioDownmixDescription' => 'Çoxkanallı səsi stereo dinamiklər və ya qulaqlıqlar üçün iki kanala endirir',
			'settings.downmixCenterBoost' => 'Mərkəz kanal gücləndirilməsi',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Gücləndirmə (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Çevirmədə səsi normallaşdır',
			'settings.audioDownmixNormalizeDescription' => 'Səs kəsilmələrinin qarşısını almaq üçün səviyyəni endirin.',
			'settings.dvConversionMode' => 'Dolby Vision çevrilməsi',
			'settings.dvConversionModeDescription' => 'ExoPlayer-in Dolby Vision Profile 7 fayllarını necə emal edəcəyini seçin.',
			'settings.dvConversionAuto' => 'Avtomatik',
			'settings.dvConversionNative' => 'Daxili / Söndürülüb',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Cihaz imkanlarının təyini və normal davranışdan istifadə et',
			'settings.dvConversionNativeDescription' => 'Daxili DV7-ni məcburi et',
			'settings.dvConversionDv81Description' => 'Dolby Vision profile 8.1-ə çevrilməni məcburi et',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision təbəqələrini sil və sadə HEVC kimi təqdim et',
			'settings.demuxer' => 'Konteyner demukseri',
			'settings.demuxerDescription' => 'Birbaşa oxudulan faylları hansı demukserin təhlil edəcəyi. Fayl düzgün işləmirsə, media3-ə keçin.',
			'settings.demuxerFfmpeg' => 'FFmpeg (Tövsiyə olunan)',
			'settings.demuxerMedia3' => 'media3',
			'settings.requireProfileSelectionOnOpen' => 'Açılışda profil soruş',
			'settings.requireProfileSelectionOnOpenDescription' => 'Tətbiq hər dəfə açıldıqda profil seçimini göstər',
			'settings.forceTvMode' => 'TV rejimini məcburi et',
			'settings.forceTvModeDescription' => 'TV interfeysini məcburi et. Avtomatik təyin etməyən cihazlar üçündür.',
			'settings.startInFullscreen' => 'Tam ekranda başlat',
			'settings.startInFullscreenDescription' => 'Plezy-ni açılışda tam ekran rejimində aç',
			'settings.exitFullscreenOnPlayerClose' => 'Oynadıcı bağlandıqda tam ekrandan çıx',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Video oynadıcını bağlayarkən avtomatik tam ekrandan çıx',
			'settings.autoHidePerformanceOverlay' => 'Məhsuldarlıq paneli avtomatik gizlənsin',
			'settings.autoHidePerformanceOverlayDescription' => 'Məhsuldarlıq panelini oynatıcı idarəetmələri ilə birlikdə gizlət',
			'settings.showNavBarLabels' => 'Naviqasiya paneli yazılarını göstər',
			'settings.showNavBarLabelsDescription' => 'Naviqasiya paneli ikonlarının altında mətni göstər',
			'settings.startupSection' => 'Başlanğıc bölməsi',
			'settings.showExploreTab' => 'Kəşf et nişanını göstər',
			'settings.showExploreTabDescription' => 'Plex Discover və qoşulmuş izləmə xidmətlərindəki məzmunla Kəşf et nişanını göstər',
			'settings.liveTvDefaultFavorites' => 'Canlı TV-də sevimli kanalları defolt et',
			'settings.liveTvDefaultFavoritesDescription' => 'Canlı TV açıldıqda yalnız sevimli kanalları göstər',
			'settings.display' => 'Ekran',
			'settings.homeScreen' => 'Ana ekran',
			'settings.navigation' => 'Naviqasiya',
			'settings.window' => 'Pəncərə',
			'settings.content' => 'Məzmun',
			'settings.player' => 'Oynadıcı',
			'settings.subtitlesAndConfig' => 'Altyazılar və konfiqurasiya',
			'settings.seekAndTiming' => 'Sarğı və vaxt tənzimləməsi',
			'settings.behavior' => 'Davranış',
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
			'settings.exportDialogTitle' => 'Plezy tənzimləmələrini ixrac et',
			'search.hint' => 'Kino, serial, musiqi axtar...',
			'search.tryDifferentTerm' => 'Fərqli axtarış sözü cəhd edin',
			'search.searchYourMedia' => 'Mediyanızda axtarın',
			'search.enterTitleActorOrKeyword' => 'Ad, aktyor və ya açar söz daxil edin',
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
			'hotkeys.actions.shaderToggle' => 'Şeyderləri aç/bağla',
			'hotkeys.actions.skipMarker' => 'Girişi/Titrləri ötür',
			'hotkeys.actions.screenshot' => 'Ekran şəkli çək',
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
			_ => null,
		} ?? switch (path) {
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Bu, içindəki ${n} seriyanı və onun faylını siləcək.', other: 'Bu, içindəki ${n} seriyanı və onların fayllarını siləcək.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Bu element ${n} fayl kimi saxlanılır və o silinəcək.', other: 'Bu element ${n} faylda saxlanılır və hamısı silinəcək.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Eyni faylda saxlanılan ${n} başqa seriya da silinəcək:', other: 'Eyni faylda saxlanılan ${n} başqa seriya da silinəcək:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy bunun hansı faylları siləcəyini yoxlaya bilmədi, ona görə də yuxarıda adı çəkilən elementdən daha çoxunu silə bilər. Ləğv edib təzədən cəhd edin və ya yenə də silin.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Serveriniz bu element üçün fayl təfərrüatlarını təqdim etmədi, ona görə Plezy bunun hansı faylları siləcəyini yoxlaya bilmir. Yuxarıda adı çəkilən elementdən daha çoxunu silə bilər.',
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
			'videoControls.versionQualityButton' => 'Versiya və Keyfiyyət',
			'videoControls.versionColumnHeader' => 'Versiya',
			'videoControls.qualityColumnHeader' => 'Keyfiyyət',
			'videoControls.qualityOriginal' => 'Orijinal',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Kod dəyişmə əlçatan deyil — orijinal keyfiyyətdə oynadılır',
			'videoControls.subtitleUnavailableFallback' => 'Seçilmiş altyazı yüklənə bilmədi — altyazısız davam edilir',
			'videoControls.pipButton' => 'Pəncərə daxilində pəncərə rejimi',
			'videoControls.aspectRatioButton' => 'Tərəf nisbəti',
			'videoControls.packedStereoSizingLocked' => 'Can not change while playing 3D source',
			'videoControls.ambientLighting' => 'Ətraf işıqlandırması',
			'videoControls.fullscreenButton' => 'Tam ekrana keç',
			'videoControls.exitFullscreenButton' => 'Tam ekrandan çıx',
			'videoControls.alwaysOnTopButton' => 'Həmişə üstə',
			'videoControls.rotationLockButton' => 'Dönmə kilidi',
			'videoControls.lockScreen' => 'Ekranı kilidlə',
			'videoControls.screenLockButton' => 'Ekran kilidi',
			'videoControls.longPressToUnlock' => 'Kilidi açmaq üçün uzun basın',
			'videoControls.timelineSlider' => 'Video zaman çubuğu',
			'videoControls.volumeSlider' => 'Səs səviyyəsi',
			'videoControls.endsAt' => ({required Object time}) => 'Bitiş vaxtı: ${time}',
			'videoControls.pipActive' => 'Pəncərə daxilində pəncərə rejimində oynadılır',
			'videoControls.pipFailed' => 'PiP rejimi başladılarkən xəta',
			'videoControls.screenshotSaved' => 'Ekran şəkli yadda saxlanıldı',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Miqyas %${percent}',
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
			'messages.markedAsWatched' => 'Baxıldı olaraq işarələndi',
			'messages.markedAsUnwatched' => 'Baxılmadı olaraq işarələndi',
			'messages.markedAsWatchedOffline' => 'Baxıldı olaraq işarələndi (onlayn olduqda eyniləşdiriləcək)',
			'messages.markedAsUnwatchedOffline' => 'Baxılmadı olaraq işarələndi (onlayn olduqda eyniləşdiriləcək)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Avtomatik silindi: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: 'Baxılmış ${n} yükləmə avtomatik silindi', other: 'Baxılmış ${n} yükləmə avtomatik silindi', ), 
			'messages.removedFromContinueWatching' => 'İzləməyə davam et-dən silindi',
			'messages.errorLoading' => ({required Object error}) => 'Xəta: ${error}',
			'messages.searchPartialResults' => 'Bəzi media serverlərində axtarış aparıla bilmədi. Mövcud nəticələr göstərilir.',
			'messages.streamInterrupted' => 'Yayım kəsildi. Təzədən cəhd etmək üçün oynat düyməsinə basın.',
			'messages.liveStreamInterrupted' => 'Canlı yayım kəsildi. Təzədən cəhd etmək üçün oynat düyməsinə basın.',
			'messages.fileInfoNotAvailable' => 'Fayl məlumatı əlçatan deyil',
			'messages.playbackAuthenticationRequired' => 'Bu elementi oynatmaq üçün media serverinə yenidən daxil olun.',
			'messages.playbackServerUnavailable' => 'Media serveri əlçatan deyil. Sonra təzədən cəhd edin.',
			'messages.playbackDataInvalid' => 'Server yanlış oynatma məlumatı qaytardı.',
			'messages.playbackCancelled' => 'Oynatma ləğv edildi.',
			'messages.playbackFailed' => 'Oynatma başladılarkən xəta.',
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
			'messages.logsUploaded' => 'Jurnallar yükləndi',
			'messages.logsUploadFailed' => 'Jurnallar yüklənə bilmədi',
			'messages.logId' => 'Jurnal ID-si',
			'messages.burnedSubtitlesUseMenu' => 'Altyazılar bu yayıma həkk edilib. Onları altyazı menyusundan dəyişin.',
			'messages.noVideoUrl' => 'Video URL-i mövcud deyil',
			'messages.playbackNoMediaSources' => 'Server oynadıla bilən media mənbəyi qaytarmadı',
			'messages.playbackDataNotPrepared' => 'Məlumatları hazır olmadan oynatma başladıldı',
			'messages.streamSelectionUnavailable' => 'Bu mənbə üçün yayım seçimi mövcud deyil',
			'messages.streamSelectionFailed' => 'Seçilmiş yayımları tətbiq etmək olmadı',
			'messages.serverUnavailableForProfile' => 'Aktiv profil üçün heç bir server mövcud deyil',
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
			'subtitlingStyling.anchorToScreen' => 'Ekrana bərkit',
			'subtitlingStyling.anchorToScreenDescription' => 'Mətn altyazılarını geniş ekranlı videonun altındakı qara zolaqlarda göstər',
			'subtitlingStyling.bold' => 'Qalın',
			'subtitlingStyling.italic' => 'Kursiv',
			'subtitlingStyling.renderResolution' => 'Emal imkanı (Resolution)',
			'subtitlingStyling.renderResolutionScreen' => 'Ekran imkanı',
			'subtitlingStyling.renderResolutionVideo' => 'Video imkanı',
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
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context və gpu-api Linux-da nəzərə alınmır: daxili video həmişə video müstəvisində vo=libmpv vasitəsilə göstərilir və gpu-next (ArtCNN kimi hesablama şeyderlərinə lazımdır) daxili işləyə bilməz.',
			'dialog.confirmAction' => 'Əməliyyatı təsdiqlə',
			'profiles.addPlezyProfile' => 'Plezy profili əlavə et',
			'profiles.switchingProfile' => 'Profil dəyişdirilir…',
			'profiles.deleteThisProfileTitle' => 'Bu profil silinsin?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} silinəcək. Qoşulmalar təsirlənmir.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'İdarə et',
			'profiles.delete' => 'Sil',
			'profiles.signOut' => 'Çıxış et',
			'profiles.signOutPlexTitle' => 'Plex-dən çıxılsın?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} və bütün Plex Ev istifadəçiləri silinsin?',
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
			'profiles.borrowEmptySubtitle' => 'Əvvəlcə başqa bir profile Plex və ya Jellyfin qoşun.',
			'profiles.borrowLoadFailed' => 'Əlçatan qoşulmalar yüklənə bilmədi. Təzədən cəhd edin.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName} profilindən',
			'profiles.borrowConnectionBorrowed' => 'Qoşulma istifadə edildi.',
			'profiles.borrowFailed' => 'Qoşulma istifadə edilə bilmədi.',
			'profiles.incorrectPin' => 'Səhv PIN.',
			'profiles.incorrectPinTryAgain' => 'Səhv PIN. Lütfən təzədən cəhd edin.',
			'profiles.sourceProfileMissingParentAccount' => 'Mənbə profilin əsas hesabı yoxdur.',
			'profiles.failedToLoadHomeUsers' => 'Plex Ev istifadəçiləriniz yüklənə bilmədi. Bağlantınızı yoxlayın.',
			'profiles.failedToVerifyPin' => 'PIN təsdiqlənə bilmədi.',
			'profiles.newProfile' => 'Yeni profil',
			'profiles.profileNameHint' => 'məs. Qonaqlar, Uşaqlar, Qonaq otağı',
			'profiles.pinProtectionOptional' => 'PIN mühafizəsi (istəyə bağlı)',
			'profiles.pinExplain' => 'Profillər arası keçid üçün 4 rəqəmli PIN tələb olunur.',
			'profiles.continueButton' => 'Davam et',
			'profiles.pinsDontMatch' => 'PIN-lər uyğun gəlmir',
			'profiles.tokenIdentityMismatch' => 'Plex profil tokeni gözlənilməyən serveri müəyyən etdi',
			'connections.sectionTitle' => 'Qoşulmalar',
			'connections.addConnection' => 'Qoşulma əlavə et',
			'connections.addConnectionSubtitleNoProfile' => 'Plex ilə daxil olun və ya Jellyfin serverinə qoşulun',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName} profilinə əlavə et: Plex, Jellyfin və ya başqa profil qoşulması',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} üçün seansın vaxtı bitdi',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} server üçün seansın vaxtı bitdi',
			'connections.signInAgain' => 'Yenidən daxil ol',
			'connections.editMediaBrowserTitle' => ({required Object product}) => '${product} qoşulmasını düzəliş et',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => '${serverName} üçün URL-lər əlavə edin və ya silin. Plezy əlçatan olan ən aşağı gecikməli URL-i istifadə edəcək.',
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
			'discover.extras' => 'Treylerlər və Əlavələr',
			'discover.studio' => 'Studiya',
			'discover.rating' => 'Reytinq',
			'discover.director' => 'Rejissor',
			'discover.directors' => 'Rejissorlar',
			'discover.movie' => 'Kino',
			'discover.tvShow' => 'TV Şou',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} dəq qaldı',
			'discover.moreLikeThis' => 'Buna bənzərlər',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${n} başlıq', other: '${n} başlıq', ), 
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
			'about.title' => 'Haqqında',
			'about.openSourceLicenses' => 'Açıq mənbə lisenziyaları',
			'about.versionLabel' => ({required Object version}) => 'Versiya ${version}',
			'about.appDescription' => 'Flutter üçün gözəl bir Plex və Jellyfin klienti',
			'about.viewLicensesDescription' => 'Üçüncü tərəf kitabxanalarının lisenziyalarına baxın',
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
			'startup.failedTitle' => 'Plezy başlaya bilmədi',
			'startup.failedBody' => 'Başlatma zamanı nəsə səhv getdi. Aşağıdakı təfərrüatlar nəyin uğursuz olduğunu göstərir.',
			'startup.failedBodyRepairable' => 'Plezy-nin saxlanmış tənzimləmə faylı zədələnib və Plezy başlamazdan əvvəl yenidən qurulmalıdır. Təzədən cəhd etmək kömək etməyəcək — Yaddaşı təmir et seçin.',
			'startup.phaseLabel' => 'Addım',
			'startup.showDetails' => 'Təfərrüatları göstər',
			'startup.hideDetails' => 'Təfərrüatları gizlət',
			'startup.copyDetails' => 'Təfərrüatları kopyala',
			'startup.detailsCopied' => 'Təfərrüatlar buferə kopyalandı',
			'startup.uploadDetails' => 'Təfərrüatları yüklə',
			'startup.repairStorage' => 'Yaddaşı təmir et',
			'startup.repairTitle' => 'Saxlanmış məlumatlar təmir edilsin?',
			'startup.repairBodyCommon' => 'Plezy-nin tənzimləmə faylı zədələnib və oxuna bilmir. Təmir bütün tənzimləmələri defolt vəziyyətinə sıfırlayır.',
			'startup.repairBodyOneCredential' => 'Bir saxlanmış daxil olma məlumatı zədələnib və oxuna bilmir. Təmir yalnız onu silir; digər tənzimləmələrinizə toxunulmur.',
			'startup.repairBodySignInsKept' => 'Serverləriniz və profilləriniz daxil olmuş vəziyyətdə qalmalıdır.',
			'startup.repairBodySignInsLost' => 'Saxlanmış daxil olmalarınızı qoruyan açar bu fayldan bərpa edilə bilmir, ona görə də hər serverə və profilə yenidən daxil olmalı olacaqsınız. Media serverinizdə heç nəyə təsir olunmur.',
			'startup.repairBodySessionsUncertain' => 'İzləyicilər (MAL, AniList, Simkl, Trakt) və Seerr ayrıca saxlanılır və qalıb-qalmayacaqları bəlli deyil. Plezy sizə nəyi saxladığını dəqiq bildirəcək.',
			'startup.repairConfirm' => 'Təmir et',
			'startup.repairSucceeded' => 'Yaddaş təmir edildi',
			'startup.repairNeedsRestart' => 'Yaddaş təmir edildi — yenidən başlatma tələb olunur',
			'startup.restartRequiredBody' => 'Məlumatlarınız təmir edildi, lakin Plezy ondan istifadə etmək üçün yenidən başlamalıdır. Plezy-ni bağlayın və yenidən açın.',
			'startup.quitPlezy' => 'Plezy-dən çıx',
			'startup.repairFailed' => 'Təmir uğursuz oldu',
			'startup.repairKeptSignIns' => 'Serverləriniz və profilləriniz hələ də daxil olub.',
			'startup.repairLostSignIns' => 'Saxlanmış daxil olmalarınızı qoruyan açar bərpa edilə bilmədi. Hər serverə və profilə yenidən daxil olmalı olacaqsınız.',
			'startup.repairLostSessions' => 'Ən azı bir izləyici və ya Seerr əlaqəsi itirildi və yenidən qoşulmalıdır.',
			'startup.backupTitle' => 'Zədələnmiş faylın nüsxəsi saxlanıldı',
			'startup.backupWarning' => 'O, daxil olma məlumatlarınızı ehtiva edir. Onu yükləməyin və ya paylaşmayın.',
			'startup.deleteBackup' => 'Nüsxəni sil',
			'startup.backupDeleted' => 'Nüsxə silindi.',
			'startup.previousFailureTitle' => 'Plezy son dəfə başlaya bilmədi',
			'licenses.relatedPackages' => 'Əlaqəli paketlər',
			'licenses.license' => 'Lisenziya',
			'licenses.licenseNumber' => ({required Object number}) => 'Lisenziya ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} lisenziya',
			'navigation.libraries' => 'Kitabxanalar',
			'navigation.downloads' => 'Yükləmələr',
			'navigation.liveTv' => 'Canlı TV',
			'navigation.explore' => 'Kəşf et',
			'explore.title' => 'Kəşf et',
			'explore.selectSource' => 'Mənbə seçin',
			'explore.rows.watchlist' => 'İzləmə siyahısı',
			_ => null,
		} ?? switch (path) {
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${n} seriya', other: '${n} seriya', ), 
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
			'explore.emptyTitle' => 'Hələlik burada heç nə yoxdur',
			'explore.emptyMessage' => ({required Object source}) => '${source} mənbəsindən olan sətirlər burada görünəcək.',
			'explore.searchHint' => ({required Object source}) => '${source} daxilində axtar',
			'explore.searchEmpty' => ({required Object query}) => '"${query}" üçün nəticə tapılmadı',
			'explore.searchPrompt' => ({required Object source}) => '${source} vasitəsilə kino və seriallar axtarın.',
			'explore.searchFailed' => 'Axtarış uğursuz oldu. Bağlantınızı yoxlayın.',
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${n} şərh', other: '${n} şərh', ), 
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${n} istifadəçi tövsiyə edir', other: '${n} istifadəçi tövsiyə edir', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => '${who} tövsiyə edir',
			'explore.detail.favoritedBy' => ({required Object who}) => '${who} favorit edib',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} hələ yayımlanmayıb',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'İzləyicilərin ${percent}-i tövsiyə edir',
			'explore.detail.relatedTitles' => 'Əlaqəli başlıqlar',
			'explore.detail.background' => 'Arxa fon',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${n} nəticə', other: '${n} nəticə', ), 
			'liveTv.title' => 'Canlı TV',
			'liveTv.guide' => 'Bələdçi',
			'liveTv.noChannels' => 'Əlçatan kanal yoxdur',
			'liveTv.noDvr' => 'Serverdə DVR tənzimlənməyib',
			'liveTv.serverUnavailable' => 'Canlı TV serveri əlçatan deyil.',
			'liveTv.serverNotConnected' => 'Canlı TV serverinə qoşulmayıb.',
			'liveTv.noPrograms' => 'Proqram məlumatı yoxdur',
			'liveTv.liveStreamFailed' => 'Canlı yayım uğursuz oldu',
			'liveTv.unknownProgram' => 'Bilinməyən proqram',
			'liveTv.unknownHub' => 'Məlum deyil',
			'liveTv.unknownError' => 'Bilinməyən xəta',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Bilinməyən kanal',
			'liveTv.live' => 'CANLI',
			'liveTv.reloadGuide' => 'Bələdçini yenilə',
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
			'liveTv.favoritesLoadFailed' => 'Sevimlilər yüklənə bilmədi.',
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
			'liveTv.rulesProcessRequested' => 'Qaydaların yenidən qiymətləndirilməsi tələb olundu',
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
			'playlists.itemCount' => ({required Object count}) => '${count} element',
			'playlists.oneItem' => '1 element',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('az'))(n, one: '${n} mahnı', other: '${n} mahnı', ), 
			'music.nowPlaying' => 'İndi oynadılır',
			'music.playingFrom' => ({required Object title}) => '${title} mənbəsindən oynadılır',
			'music.queue' => 'Növbə',
			'music.clearQueue' => 'Növbəni təmizlə',
			'music.lyrics' => 'Mahnı sözləri',
			'music.noLyrics' => 'Mahnı sözləri yoxdur',
			'music.sleepTimer' => 'Yuxu taymeri',
			'music.sleepTimerEndOfTrack' => 'Mahnının sonu',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} dəqiqə',
			'music.stopPlayback' => 'Oynatmanı saxla',
			'music.previousTrack' => 'Əvvəlki mahnı',
			'music.nextTrack' => 'Növbəti mahnı',
			'music.repeat' => 'Təkrarla',
			'music.repeatAll' => 'Hamısını təkrarla',
			'music.repeatOne' => 'Birini təkrarla',
			'music.instantMixNoServer' => 'Ani miks üçün heç bir server mövcud deyil',
			'music.noAudioUrl' => ({required Object track}) => '${track} üçün səs URL-i mövcud deyil',
			'music.discography.singlesAndEps' => 'Single-lar və EP-lər',
			'music.discography.live' => 'Canlı',
			'music.discography.compilations' => 'Kompilyasiyalar',
			'watchTogether.title' => 'Birlikdə İzlə',
			'watchTogether.description' => 'Dostlarınız və ailənizlə eyni vaxtda baxın',
			'watchTogether.createSession' => 'Seans yarat',
			'watchTogether.creating' => 'Yaradılır...',
			'watchTogether.joinSession' => 'Seansa qoşul',
			'watchTogether.joining' => 'Qoşulunur...',
			'watchTogether.controlMode' => 'İdarəetmə rejimi',
			'watchTogether.controlModeQuestion' => 'Oynatmanı kim idarə edə bilər?',
			'watchTogether.hostOnly' => 'Yalnız təşkilatçı',
			'watchTogether.anyone' => 'Hər kəs',
			'watchTogether.hostingSession' => 'Seans təşkil olunur',
			'watchTogether.inSession' => 'Seansdadır',
			'watchTogether.sessionCode' => 'Seans kodu',
			'watchTogether.openSessionControls' => 'Birlikdə İzlə seans idarəetmələrini aç',
			'watchTogether.copySessionCode' => 'Seans kodunu kopyala',
			'watchTogether.hostControlsPlayback' => 'Oynatmanı təşkilatçı idarə edir',
			'watchTogether.anyoneCanControl' => 'Oynatmanı hər kəs idarə edə bilər',
			'watchTogether.hostControls' => 'Təşkilatçı idarə edir',
			'watchTogether.anyoneControls' => 'Hər kəs idarə edir',
			'watchTogether.participants' => 'İştirakçılar',
			'watchTogether.host' => 'Təşkilatçı',
			'watchTogether.hostBadge' => 'TƏŞKİLATÇI',
			'watchTogether.youAreHost' => 'Təşkilatçı sizsiniz',
			'watchTogether.watchingWithOthers' => 'Başqaları ilə izlənilir',
			'watchTogether.endSession' => 'Seansı bitir',
			'watchTogether.leaveSession' => 'Seansdan çıx',
			'watchTogether.endSessionQuestion' => 'Seans bitirilsin?',
			'watchTogether.leaveSessionQuestion' => 'Seansdan çıxılsın?',
			'watchTogether.endSessionConfirm' => 'Bu bütün iştirakçılar üçün seansı bitirəcək.',
			'watchTogether.leaveSessionConfirm' => 'Seansdan xaric ediləcəksiniz.',
			'watchTogether.endSessionConfirmOverlay' => 'Bu bütün iştirakçılar üçün izləmə seansını bitirəcək.',
			'watchTogether.leaveSessionConfirmOverlay' => 'İzləmə seansı ilə əlaqəniz kəsiləcək.',
			'watchTogether.end' => 'Bitir',
			'watchTogether.leave' => 'Çıx',
			'watchTogether.syncing' => 'Eyniləşdirilir...',
			'watchTogether.joinWatchSession' => 'İzləmə seansına qoşul',
			'watchTogether.enterCodeHint' => '5 rəqəmli/hərfli kodu daxil edin',
			'watchTogether.pasteFromClipboard' => 'Buferdən yapışdır',
			'watchTogether.pleaseEnterCode' => 'Lütfən seans kodunu daxil edin',
			'watchTogether.codeMustBe5Chars' => 'Seans kodu 5 simvol olmalıdır',
			'watchTogether.joinInstructions' => 'Qoşulmaq üçün təşkilatçının seans kodunu daxil edin.',
			'watchTogether.failedToCreate' => 'Seans yaradıla bilmədi',
			'watchTogether.failedToJoin' => 'Seansa qoşuluna bilmədi',
			'watchTogether.sessionCodeCopied' => 'Seans kodu buferə kopyalandı',
			'watchTogether.relayUnreachable' => 'Rele serverinə çatmaq olmur. İnternet provayderinin bloklaması Birlikdə İzləməyə mane ola bilər.',
			'watchTogether.reconnectingToHost' => 'Təşkilatçıya yenidən qoşulunur...',
			'watchTogether.currentPlayback' => 'Cari oynatma',
			'watchTogether.joinCurrentPlayback' => 'Cari oynatmaya qoşul',
			'watchTogether.joinCurrentPlaybackDescription' => 'Təşkilatçının indi baxdığı hissəyə keçin',
			'watchTogether.failedToOpenCurrentPlayback' => 'Cari oynatma açıla bilmədi',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} qoşuldu',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} ayrıldı',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} fasilə etdi',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} davam etdirdi',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} oynatma mövqeyini dəyişdi',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} buferləyir',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} köhnə tətbiq versiyasındadır',
			'watchTogether.resumingWithout' => ({required Object name}) => '${name} olmadan davam edilir',
			'watchTogether.waitingForParticipants' => 'Digərlərinin yükləməsi gözlənilir...',
			'watchTogether.waitingForName' => ({required Object name}) => '${name} gözlənilir...',
			'watchTogether.recentRooms' => 'Son otaqlar',
			'watchTogether.renameRoom' => 'Otağın adını dəyişdir',
			'watchTogether.removeRoom' => 'Sil',
			'watchTogether.guestSwitchUnavailable' => 'Keçid etmək olmadı — eyniləşdirmə üçün server əlçatan deyil',
			'watchTogether.guestSwitchFailed' => 'Keçid etmək olmadı — məzmun tapılmadı',
			'watchTogether.defaultDisplayName' => 'İstifadəçi',
			'watchTogether.errors.timedOut' => 'Rele serveri vaxtında cavab vermədi',
			'watchTogether.errors.connectionLost' => 'Bağlantı seans hazır olmamış kəsildi',
			'watchTogether.errors.invalidRelayResponse' => 'Rele serveri gözlənilməz cavab göndərdi',
			'watchTogether.errors.sessionEnded' => 'Təşkilatçı seansı bitirdi',
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
			'downloads.storageFull' => 'Cihaz yaddaşı dolu olduğu üçün yükləmə dayandırıldı.',
			'downloads.episodesQueued' => ({required Object count}) => 'Yükləmə üçün ${count} seriya növbəyə alındı',
			'downloads.downloadDeleted' => 'Yükləmə silindi',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" bu cihazdan silinsin?',
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
			'downloads.deleteAll' => 'Hamısını sil',
			'downloads.selectVersion' => 'Versiya seç',
			'downloads.allEpisodes' => 'Bütün seriyalar',
			'downloads.unwatchedOnly' => 'Yalnız baxılmayanlar',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Növbəti ${count} baxılmayan',
			'downloads.customAmount' => 'Xüsusi miqdar...',
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
			'downloads.activeSyncRules' => 'Eyniləşdirmə qaydaları',
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
			'downloads.syncRuleNotAvailableForProfile' => 'Cari profil üçün əlçatan deyil',
			'downloads.syncRuleUnknownServer' => 'Bilinməyən server',
			'downloads.syncRuleListCreated' => 'Eyniləşdirmə qaydası yaradıldı',
			'downloads.backgroundWarning.bannerBlocked' => 'Tətbiqdən çıxdıqda yükləmələr dayanacaq',
			'downloads.backgroundWarning.bannerDegraded' => 'Arxa fonda yükləmələr məhdudlaşdırıla bilər',
			'downloads.backgroundWarning.bannerAction' => 'Ətraflı',
			'downloads.backgroundWarning.sheetTitle' => 'Arxa fonda yükləmələr bloklanıb',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Arxa fonda yükləmələr məhdudlaşdırıla bilər',
			'downloads.backgroundWarning.sheetIntro' => 'Android Plezy-nin arxa fonda etibarlı şəkildə yükləməsinə mane olur.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Cihazınız Plezy-nin arxa fonda nə vaxt yükləyə biləcəyini məhdudlaşdırır.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy-nin arxa fon istifadəsi məhdudlaşdırılıb. Batareya və ya arxa fon istifadəsini "Məhdudiyyətsiz" edin.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android Plezy-ni məhdud gözləmə rejiminə salıb. Batareya istifadəsini "Məhdudiyyətsiz" edin.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Yükləmə bildirişləri söndürülüb, ona görə gedişat və idarəetmələr əlçatan olmaya bilər.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Bildirişlər söndürülüb. Android 13 və daha yeni versiyalarda uzun arxa fon yükləmələri üçün onlar tələb olunur.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver aktivdir və bu, mobil internetdə arxa fon yükləmələrini bloklayır. Wi-Fi ilə yükləmələr işləməlidir.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezy arxa fonda olarkən yükləmələr dəfələrlə dayandı. Plezy-nin batareya və ya arxa fon istifadəsi tənzimləmələrini yoxlayın.',
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
			'downloads.unknownShow' => 'Məlum olmayan serial',
			'downloads.unknownSeason' => 'Məlum olmayan mövsüm',
			'downloads.unknownAlbum' => 'Məlum olmayan albom',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} tamamlandı',
			'downloads.errorFileNotFound' => 'Fayl tapılmadı (404)',
			'downloads.errorDownloadFailed' => 'Yükləmə uğursuz oldu',
			'downloads.errorPostProcessing' => ({required Object error}) => 'Sonrakı emal uğursuz oldu: ${error}',
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
			'companionRemote.pairing.discoveryDescription' => 'Eyni Plex hesabına sahib Plezy cihazları burada görünür',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Qoşulunur...',
			'companionRemote.pairing.searchingForDevices' => 'Cihazlar axtarılır...',
			'companionRemote.pairing.noDevicesFound' => 'Şəbəkənizdə cihaz tapılmadı',
			'companionRemote.pairing.noDevicesHint' => 'Masaüstündə Plezy-ni açın və eyni Wi-Fi-dan istifadə edin',
			'companionRemote.pairing.availableDevices' => 'Əlçatan cihazlar',
			_ => null,
		} ?? switch (path) {
			'companionRemote.pairing.manualConnection' => 'Əl ilə qoşulma',
			'companionRemote.pairing.cryptoInitFailed' => 'Təhlükəsiz qoşulma başladılarkən xəta. Əvvəlcə Plex-ə daxil olun.',
			'companionRemote.pairing.validationHostRequired' => 'Lütfən əsas cihaz ünvanını daxil edin',
			'companionRemote.pairing.validationHostFormat' => 'Format IP:port şəklində olmalıdır',
			'companionRemote.pairing.connectionTimedOut' => 'Qoşulma vaxtı bitdi.',
			'companionRemote.pairing.sessionNotFound' => 'Cihaz tapılmadı.',
			'companionRemote.pairing.authFailed' => 'Kimlik doğrulanması uğursuz oldu.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Qoşulma uğursuz oldu: ${error}',
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
			'videoSettings.performanceOverlay' => 'Məhsuldarlıq paneli',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Əhatəli səs',
			'videoSettings.audioOutputSpatial' => 'Məkan səsi',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioNormalization' => 'Səsin gurluğunu normallaşdır',
			'videoSettings.audioDownmix' => 'Stereo-ya çevir',
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
			'matchScreen.match' => 'Uyğunlaşdır...',
			'matchScreen.fixMatch' => 'Uyğunluğu düzəlt...',
			'matchScreen.unmatch' => 'Uyğunluğu ləğv et',
			'matchScreen.unmatchConfirm' => 'Bu uyğunluq təmizlənsin?',
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
			'trakt.disconnectConfirmBody' => 'Plezy Trakt-a məlumat göndərməyi dayandıracaq.',
			'trakt.scrobble' => 'Real vaxt rejimində izləmə',
			'trakt.scrobbleDescription' => 'Oynatma zamanı Trakt-a məlumat göndər.',
			'trakt.watchedSync' => 'Baxış statusunu eyniləşdir',
			'trakt.watchedSyncDescription' => 'Plezy-də baxıldı işarələdikdə Trakt-da da işarələnsin.',
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
			'seerr.disconnectConfirmBody' => 'Plezy bu Seerr ünvanını unudacaq.',
			'seerr.request' => 'Sorğu göndər',
			'seerr.request4k' => '4K sorğu göndər',
			'seerr.seasons' => 'Mövsümlər',
			'seerr.allSeasons' => 'Bütün mövsümlər',
			'seerr.advancedOptions' => 'Təkmilləşdirilmiş',
			'seerr.destinationServer' => 'Hədəf server',
			'seerr.qualityProfile' => 'Keyfiyyət profili',
			'seerr.rootFolder' => 'Kök qovluq',
			'seerr.languageProfile' => 'Dil profili',
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
			'seerr.notInitialized' => 'Bu Seerr instansiyasının ilkin quraşdırılması tamamlanmayıb',
			'seerr.noPlexTokenForReauth' => 'Yenidən daxil olmaq üçün Plex tokeni mövcud deyil',
			'seerr.noStoredCredentials' => 'Yenidən daxil olmaq üçün yadda saxlanmış giriş məlumatları mövcud deyil',
			'seerr.signInRejected' => 'Daxil olma rədd edildi',
			'seerr.noSessionCookie' => 'Seerr sessiya kukisi yaratmadı',
			'seerr.freshCookieRejected' => 'Seerr yeni sessiya kukisini rədd etdi',
			'seerr.noUserInformation' => 'Seerr istifadəçi məlumatlarını qaytarmadı',
			'seerr.sessionRejectedAfterReauth' => 'Yenidən daxil olduqdan sonra sessiya rədd edildi',
			'services.title' => 'Xidmətlər',
			'services.hubSubtitle' => 'İzləmə tərəqqisini eyniləşdirin və yeni başlıqlar sorğulayın.',
			'services.notConnected' => 'Qoşulmayıb',
			'services.connectedAs' => ({required Object username}) => '@${username} olaraq qoşuldu',
			'services.scrobble' => 'Tərəqqini avtomatik izlə',
			'services.scrobbleDescription' => 'Siyahınızı avtomatik yeniləyin.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} ayırılsın?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy ${service} yeniləməyi dayandıracaq.',
			'services.connectFailed' => ({required Object service}) => '${service} qoşula bilmədi. Təzədən cəhd edin.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => 'Plezy-ni ${service} üzərində aktivləşdirin',
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
			'addServer.signInWithPlexCardSubtitle' => 'Bu cihazı səlahiyyətləndirin.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex hesabını səlahiyyətləndirin.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => '${product}-a qoşul',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Server URL-inizi, istifadəçi adınızı və şifrənizi daxil edin.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => '${product} serverinizə daxil olun. ${name} ilə əlaqələndirilir.',
			'addServer.borrowFromAnotherProfile' => 'Başqa profildən götür',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Başqa profilin qoşulmasını yenidən istifadə edin.',
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
			_ => null,
		};
	}
}
