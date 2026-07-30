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
class TranslationsKk extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsKk({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.kk,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <kk>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsKk _root = this; // ignore: unused_field

	@override 
	TranslationsKk $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsKk(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$kk app = _Translations$app$kk._(_root);
	@override late final _Translations$auth$kk auth = _Translations$auth$kk._(_root);
	@override late final _Translations$common$kk common = _Translations$common$kk._(_root);
	@override late final _Translations$screens$kk screens = _Translations$screens$kk._(_root);
	@override late final _Translations$update$kk update = _Translations$update$kk._(_root);
	@override late final _Translations$settings$kk settings = _Translations$settings$kk._(_root);
	@override late final _Translations$search$kk search = _Translations$search$kk._(_root);
	@override late final _Translations$hotkeys$kk hotkeys = _Translations$hotkeys$kk._(_root);
	@override late final _Translations$fileInfo$kk fileInfo = _Translations$fileInfo$kk._(_root);
	@override late final _Translations$mediaMenu$kk mediaMenu = _Translations$mediaMenu$kk._(_root);
	@override late final _Translations$rateSheet$kk rateSheet = _Translations$rateSheet$kk._(_root);
	@override late final _Translations$accessibility$kk accessibility = _Translations$accessibility$kk._(_root);
	@override late final _Translations$tooltips$kk tooltips = _Translations$tooltips$kk._(_root);
	@override late final _Translations$audioTracks$kk audioTracks = _Translations$audioTracks$kk._(_root);
	@override late final _Translations$videoControls$kk videoControls = _Translations$videoControls$kk._(_root);
	@override late final _Translations$messages$kk messages = _Translations$messages$kk._(_root);
	@override late final _Translations$subtitlingStyling$kk subtitlingStyling = _Translations$subtitlingStyling$kk._(_root);
	@override late final _Translations$mpvConfig$kk mpvConfig = _Translations$mpvConfig$kk._(_root);
	@override late final _Translations$dialog$kk dialog = _Translations$dialog$kk._(_root);
	@override late final _Translations$profiles$kk profiles = _Translations$profiles$kk._(_root);
	@override late final _Translations$connections$kk connections = _Translations$connections$kk._(_root);
	@override late final _Translations$discover$kk discover = _Translations$discover$kk._(_root);
	@override late final _Translations$errors$kk errors = _Translations$errors$kk._(_root);
	@override late final _Translations$libraries$kk libraries = _Translations$libraries$kk._(_root);
	@override late final _Translations$about$kk about = _Translations$about$kk._(_root);
	@override late final _Translations$serverSelection$kk serverSelection = _Translations$serverSelection$kk._(_root);
	@override late final _Translations$hubDetail$kk hubDetail = _Translations$hubDetail$kk._(_root);
	@override late final _Translations$logs$kk logs = _Translations$logs$kk._(_root);
	@override late final _Translations$licenses$kk licenses = _Translations$licenses$kk._(_root);
	@override late final _Translations$navigation$kk navigation = _Translations$navigation$kk._(_root);
	@override late final _Translations$explore$kk explore = _Translations$explore$kk._(_root);
	@override late final _Translations$liveTv$kk liveTv = _Translations$liveTv$kk._(_root);
	@override late final _Translations$collections$kk collections = _Translations$collections$kk._(_root);
	@override late final _Translations$playlists$kk playlists = _Translations$playlists$kk._(_root);
	@override late final _Translations$music$kk music = _Translations$music$kk._(_root);
	@override late final _Translations$watchTogether$kk watchTogether = _Translations$watchTogether$kk._(_root);
	@override late final _Translations$downloads$kk downloads = _Translations$downloads$kk._(_root);
	@override late final _Translations$shaders$kk shaders = _Translations$shaders$kk._(_root);
	@override late final _Translations$companionRemote$kk companionRemote = _Translations$companionRemote$kk._(_root);
	@override late final _Translations$videoSettings$kk videoSettings = _Translations$videoSettings$kk._(_root);
	@override late final _Translations$performanceOverlay$kk performanceOverlay = _Translations$performanceOverlay$kk._(_root);
	@override late final _Translations$externalPlayer$kk externalPlayer = _Translations$externalPlayer$kk._(_root);
	@override late final _Translations$metadataEdit$kk metadataEdit = _Translations$metadataEdit$kk._(_root);
	@override late final _Translations$matchScreen$kk matchScreen = _Translations$matchScreen$kk._(_root);
	@override late final _Translations$serverTasks$kk serverTasks = _Translations$serverTasks$kk._(_root);
	@override late final _Translations$trakt$kk trakt = _Translations$trakt$kk._(_root);
	@override late final _Translations$seerr$kk seerr = _Translations$seerr$kk._(_root);
	@override late final _Translations$services$kk services = _Translations$services$kk._(_root);
	@override late final _Translations$addServer$kk addServer = _Translations$addServer$kk._(_root);
}

// Path: app
class _Translations$app$kk extends Translations$app$en {
	_Translations$app$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$kk extends Translations$auth$en {
	_Translations$auth$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Plex арқылы кіру';
	@override String get showQRCode => 'QR кодты көрсету';
	@override String get authenticate => 'Растау';
	@override String get authenticationTimeout => 'Растау уақыты өтті. Қайтадан байқап көріңіз.';
	@override String get scanQRToSignIn => 'Кіру үшін осы QR кодты сканерлеңіз';
	@override String get waitingForAuth => 'Растау күтілуде...\nБраузеріңізден кіріңіз.';
	@override String get useBrowser => 'Браузерді пайдалану';
	@override String get or => 'немесе';
	@override String get connectToJellyfin => 'Jellyfin-ге қосылу';
	@override String get useQuickConnect => 'Жылдам қосылуды пайдалану';
	@override String get quickConnectInstructions => 'Jellyfin-де Жылдам қосылуды ашып, осы кодты енгізіңіз.';
	@override String get quickConnectWaiting => 'Растау күтілуде…';
	@override String get quickConnectCancel => 'Бас тарту';
	@override String get quickConnectExpired => 'Жылдам қосылу мерзімі өтті. Қайтадан байқап көріңіз.';
	@override String get localDataRecoveryRequired => 'Plezy жергілікті кіру мәліметтерін қалпына келтіре алмады. Қайтадан кіріңіз.';
}

// Path: common
class _Translations$common$kk extends Translations$common$en {
	_Translations$common$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Бас тарту';
	@override String get save => 'Сақтау';
	@override String get close => 'Жабу';
	@override String get clear => 'Тазалау';
	@override String get reset => 'Қалпына келтіру';
	@override String get later => 'Кейінірек';
	@override String get submit => 'Жіберу';
	@override String get confirm => 'Растау';
	@override String get retry => 'Қайталау';
	@override String get logout => 'Шығу';
	@override String get unknown => 'Белгісіз';
	@override String get refresh => 'Жаңарту';
	@override String get yes => 'Иә';
	@override String get no => 'Жоқ';
	@override String get delete => 'Өшіру';
	@override String get edit => 'Өңдеу';
	@override String get shuffle => 'Араластыру';
	@override String get addTo => 'Қосу...';
	@override String get createNew => 'Жаңасын жасау';
	@override String get connect => 'Қосылу';
	@override String get disconnect => 'Ажырату';
	@override String get play => 'Ойнату';
	@override String get pause => 'Кідірту';
	@override String get resume => 'Жалғастыру';
	@override String get error => 'Қате';
	@override String get search => 'Іздеу';
	@override String get home => 'Басты бет';
	@override String get back => 'Артқа';
	@override String get settings => 'Баптаулар';
	@override String get mute => 'Дыбысты өшіру';
	@override String get ok => 'Түсінікті';
	@override String get off => 'Өшірулі';
	@override String seasonNumber({required Object number}) => '${number}-маусым';
	@override String episodeNumberTitle({required Object number, required Object title}) => '${number}-бөлім - ${title}';
	@override String chapterNumber({required Object number}) => '${number}-бөлім';
	@override String get reconnect => 'Қайта қосылу';
	@override String get viewAll => 'Барлығын көру';
	@override String get checkingNetwork => 'Желі тексерілуде...';
	@override String get loadingServers => 'Серверлер жүктелуде...';
	@override String get connectingToServers => 'Серверлерге қосылуда...';
	@override String get startingOfflineMode => 'Офлайн режим іске қосылуда...';
	@override String get loading => 'Жүктелуде...';
	@override String get fullscreen => 'Толық экран';
	@override String get exitFullscreen => 'Толық экраннан шығу';
	@override String get pressBackAgainToExit => 'Шығу үшін артқа түймесін қайтадан басыңыз';
}

// Path: screens
class _Translations$screens$kk extends Translations$screens$en {
	_Translations$screens$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Лицензиялар';
	@override String get switchProfile => 'Профильді ауыстыру';
	@override String get subtitleStyling => 'Субтитр баптаулары';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Журналдар';
}

// Path: update
class _Translations$update$kk extends Translations$update$en {
	_Translations$update$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get available => 'Жаңарту қолжетімді';
	@override String versionAvailable({required Object version}) => '${version} нұсқасы қолжетімді';
	@override String currentVersion({required Object version}) => 'Ағымдағы: ${version}';
	@override String get skipVersion => 'Бұл нұсқаны өткізіп жіберу';
	@override String get viewRelease => 'Релизді көру';
	@override String get latestVersion => 'Сізде ең соңғы нұсқа орнатылған';
	@override String get checkFailed => 'Жаңартуларды тексеру мүмкін болмады';
}

// Path: settings
class _Translations$settings$kk extends Translations$settings$en {
	_Translations$settings$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Баптаулар';
	@override String get supportDeveloper => 'Plezy жобасын қолдау';
	@override String get supportDeveloperDescription => 'Дамытуды қаржыландыру үшін Liberapay арқылы демеушілік жасаңыз';
	@override String get language => 'Тіл';
	@override String get theme => 'Тақырып';
	@override String get appearance => 'Сыртқы келбеті';
	@override String get videoPlayback => 'Видеоны ойнату';
	@override String get videoPlaybackDescription => 'Ойнату параметрлерін реттеңіз';
	@override String get advanced => 'Кеңейтілген';
	@override String get episodePosterMode => 'Бөлім постерінің стилі';
	@override String get seriesPoster => 'Сериал постері';
	@override String get seasonPoster => 'Маусым постері';
	@override String get episodeThumbnail => 'Кадр алдын ала көрінісі';
	@override String get showHeroSectionDescription => 'Басты бетте арнайы мазмұн каруселін көрсету';
	@override String get secondsLabel => 'Секунд';
	@override String get minutesLabel => 'Минут';
	@override String get secondsShort => 'сек';
	@override String get minutesShort => 'мин';
	@override String durationHint({required Object min, required Object max}) => 'Уақытты енгізіңіз (${min}-${max})';
	@override String get systemTheme => 'Жүйелік';
	@override String get lightTheme => 'Жарық';
	@override String get darkTheme => 'Қараңғы';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Кітапхана тығыздығы';
	@override String get compact => 'Тығыз';
	@override String get comfortable => 'Ыңғайлы';
	@override String get tvCornerSpotlightBackdrop => 'Бұрыштық жарық фоны';
	@override String get tvCornerSpotlightBackdropDescription => 'Фонды толық экран орнына жоғарғы оң жақ бұрышта көрсету';
	@override String get viewMode => 'Көрініс режимі';
	@override String get gridView => 'Тор';
	@override String get listView => 'Тізім';
	@override String get showHeroSection => 'Басты бөлімді көрсету';
	@override String get continueWatchingAction => '"Көруді жалғастыру" әрекеті';
	@override String get continueWatchingPlay => 'Ойнату';
	@override String get continueWatchingDetails => 'Толығырақ ашу';
	@override String get episodeAction => 'Бөлім әрекеті';
	@override String get episodePlay => 'Ойнату';
	@override String get episodeDetails => 'Толығырақ ашу';
	@override String get useGlobalHubs => 'Басты бет құрылымын пайдалану';
	@override String get useGlobalHubsDescription => 'Біріктірілген басты бет бөлімдерін көрсету.';
	@override String get showServerNameOnHubs => 'Бөлімдерде сервер атын көрсету';
	@override String get showServerNameOnHubsDescription => 'Бөлім тақырыптарында әрдайым сервер атын көрсету.';
	@override String get groupLibrariesByServer => 'Кітапханаларды сервер бойынша топтау';
	@override String get groupLibrariesByServerDescription => 'Мүйістік мәзірдегі кітапханаларды серверлер бойынша топтау.';
	@override String get alwaysKeepSidebarOpen => 'Сүйістік мәзірді әрдайым ашық ұстау';
	@override String get alwaysKeepSidebarOpenDescription => 'Жүйелік мәзір ашық күйінде қалады';
	@override String get showUnwatchedCount => 'Көрілмегендер санын көрсету';
	@override String get showUnwatchedCountDescription => 'Сериалдар мен маусымдарда көрілмеген бөлімдер санын көрсету';
	@override String get showEpisodeNumberOnCards => 'Карточкаларда бөлім нөмірін көрсету';
	@override String get showEpisodeNumberOnCardsDescription => 'Бөлім карточкаларында маусым мен бөлім нөмірін көрсету';
	@override String get showSeasonPostersOnTabs => 'Қойындыларда маусым постерлерін көрсету';
	@override String get showSeasonPostersOnTabsDescription => 'Әр маусымның постерін өз бөлімінің үстінде көрсету';
	@override String get tvFullCardLayout => 'Толық TV карточкалары';
	@override String get tvFullCardLayoutDescription => 'Тек суреттен тұратын TV карточкаларын пайдалану';
	@override String get focusGlow => 'Фокус жарқылы';
	@override String get focusGlowDescription => 'Таңдалған карточка айналасында жұмсақ жарқыл көрсету';
	@override String get visualEffects => 'Визуалды эффектілер';
	@override String get visualEffectsAuto => 'Автоматты';
	@override String get visualEffectsAutoDescription => 'Әлсіз құрылғыларда эффектілерді автоматты түрде азайту';
	@override String get visualEffectsFull => 'Толық';
	@override String get visualEffectsReduced => 'Азайтылған';
	@override String get visualEffectsReducedDescription => 'Аз анимация және төмен сапалы суреттер';
	@override String get hideSpoilers => 'Көрілмеген бөлімдер үшін спойлерлерді жасыру';
	@override String get hideSpoilersDescription => 'Көрілмеген бөлімдердің суреттері мен сипаттамаларын бұлдырату';
	@override String get playerBackend => 'Ойнатқыш инфрақұрылымы';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Аппараттық декодтау';
	@override String get hardwareDecodingDescription => 'Мүмкіндігінше аппараттық үдетуді пайдалану';
	@override String get bufferSize => 'Буфер көлемі';
	@override String bufferSizeMB({required Object size}) => '${size} МБ';
	@override String get bufferSizeAuto => 'Автоматты (Ұсынылатын)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap} МБ ЖҰД қолжетімді. ${size} МБ буфер ойнатуға әсер етуі мүмкін.';
	@override String get defaultQualityTitle => 'Әдепкі сапа';
	@override String get musicQualityTitle => 'Музыка сапасы';
	@override String get subtitleStyling => 'Субтитр баптаулары';
	@override String get subtitleStylingDescription => 'Субтитрлердің сыртқы келбетін теңшеу';
	@override String get smallSkipDuration => 'Шағын өткізіп жіберу уақыты';
	@override String get largeSkipDuration => 'Үлкен өткізіп жіберу уақыты';
	@override String get rewindOnResume => 'Жалғастырғанда артқа айналдыру';
	@override String secondsUnit({required Object seconds}) => '${seconds} секунд';
	@override String get defaultSleepTimer => 'Әдепкі ұйқы таймері';
	@override String minutesUnit({required Object minutes}) => '${minutes} минут';
	@override String get rememberTrackSelections => 'Әр фильм/сериал үшін дыбыс/субтитр таңдауын есте сақтау';
	@override String get rememberTrackSelectionsDescription => 'Әр медиа үшін дыбыс пен субтитр таңдауын сақтау';
	@override String get followServerTrackSelections => 'Әр бөлім үшін сервердегі жолдар таңдауын қолдану';
	@override String get followServerTrackSelectionsDescription => 'Бөлім ауысқанда ағымдағы таңдауды көшірудің орнына серверде таңдалған дыбыс пен субтитрлерді қолдану';
	@override String get showChapterMarkersOnTimeline => 'Уақыт шкаласында бөлім белгілерін көрсету';
	@override String get showChapterMarkersOnTimelineDescription => 'Уақыт шкаласын бөлімдерге бөлу';
	@override String get clickVideoTogglesPlayback => 'Ойнату/кідірту үшін видеоны басу';
	@override String get clickVideoTogglesPlaybackDescription => 'Басқару элементтерін көрсету орнына ойнату немесе кідірту';
	@override String get videoPlayerControls => 'Видео ойнатқыш басқару элементтері';
	@override String get keyboardShortcuts => 'Пернетақта пернелер тіркесі';
	@override String get keyboardShortcutsDescription => 'Пернетақта пернелер тіркесін реттеу';
	@override String get videoPlayerNavigation => 'Видео ойнатқыш навигациясы';
	@override String get videoPlayerNavigationDescription => 'Ойнатқышты басқару үшін бағыттауыш пернелерді пайдалану';
	@override String get watchTogetherRelay => 'Бірге көру релесі';
	@override String get watchTogetherRelayDescription => 'Жеке реле орнату. Барлығы бір серверді пайдалануы керек.';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Дұрыс HTTP немесе HTTPS реле мекенжайын енгізіңіз.';
	@override String get crashReporting => 'Қателіктер туралы есеп';
	@override String get crashReportingDescription => 'Қолданбаны жақсартуға көмектесу үшін қателіктер есебін жіберу';
	@override String get debugLogging => 'Жөндеу журналы';
	@override String get debugLoggingDescription => 'Мәселелерді шешу үшін толық журнал жүргізуді қосу';
	@override String get viewLogs => 'Журналдарды көру';
	@override String get viewLogsDescription => 'Қолданба журналдарын көру';
	@override String get clearImageCache => 'Сурет кэшін тазалау';
	@override String get clearImageCacheDescription => 'Кэштелген суреттерді тазалайды.';
	@override String get clearImageCacheSuccess => 'Сурет кэші сәтті тазаланды';
	@override String get resetSettings => 'Баптауларды қалпына келтіру';
	@override String get resetSettingsDescription => 'Әдепкі баптауларды қайтару. Бұл әрекетті қайтару мүмкін емес.';
	@override String get resetSettingsSuccess => 'Баптаулар сәтті қалпына келтірілді';
	@override String get backup => 'Резервтік көшірме';
	@override String get exportSettings => 'Баптауларды экспорттау';
	@override String get exportSettingsDescription => 'Параметрлеріңізді файлға сақтаңыз';
	@override String get exportSettingsSuccess => 'Баптаулар экспортталды';
	@override String get importSettings => 'Баптауларды импорттау';
	@override String get importSettingsDescription => 'Параметрлерді файлдан қалпына келтіріңіз';
	@override String get importSettingsConfirm => 'Бұл ағымдағы баптауларыңыздың үстінен жазады. Жалғастырасыз ба?';
	@override String get importSettingsSuccess => 'Баптаулар импортталды';
	@override String get importSettingsInvalidFile => 'Бұл файл дұрыс Plezy баптаулар файлы емес';
	@override String get importSettingsNoUser => 'Баптауларды импорттау алдында жүйеге кіріңіз';
	@override String get shortcutsReset => 'Пернелер тіркесі әдепкі күйге қайтарылды';
	@override String get about => 'Қолданба туралы';
	@override String get aboutDescription => 'Қолданба туралы ақпарат пен лицензиялар';
	@override String get updates => 'Жаңартулар';
	@override String get updateAvailable => 'Жаңарту бар';
	@override String get checkForUpdates => 'Жаңартуларды тексеру';
	@override String get autoCheckUpdatesOnStartup => 'Іске қосылғанда жаңартуларды автоматты тексеру';
	@override String get autoCheckUpdatesOnStartupDescription => 'Іске қосылғанда жаңарту бар болса хабарлау';
	@override String get validationErrorEnterNumber => 'Дұрыс сан енгізіңіз';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Уақыт ${min} және ${max} ${unit} аралығында болуы керек';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Бұл тіркес ${action} әрекетіне тағайындалған';
	@override String shortcutUpdated({required Object action}) => '${action} үшін пернелер тіркесі жаңартылды';
	@override String get saveFailed => 'Өзгерістер сақталмады. Қайтадан байқап көріңіз.';
	@override String get autoSkip => 'Автоматты өткізу';
	@override String get autoSkipIntro => 'Киріс бөлімді (Intro) автоматты өткізу';
	@override String get autoSkipIntroDescription => 'Бірнеше секундтан кейін киріс белгілерін автоматты өткізу';
	@override String get autoSkipCredits => 'Титрлерді автоматты өткізу';
	@override String get autoSkipCreditsDescription => 'Титрлерді автоматты өткізіп, келесі бөлімді ойнату';
	@override String get forceSkipMarkerFallback => 'Қосалқы белгілерді мәжбүрлеу';
	@override String get forceSkipMarkerFallbackDescription => 'Plex белгілері болса да бөлім тақырыбы үлгілерін пайдалану';
	@override String get autoSkipDelay => 'Автоматты өткізу кідірісі';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Автоматты өткізгенге дейін ${seconds} секунд күту';
	@override String get introPattern => 'Киріс бөлім белгісінің үлгісі';
	@override String get introPatternDescription => 'Бөлім тақырыптарында интроны табуға арналған Regex үлгісі';
	@override String get creditsPattern => 'Титр белгісінің үлгісі';
	@override String get creditsPatternDescription => 'Бөлім тақырыптарында титрлерді табуға арналған Regex үлгісі';
	@override String get invalidRegex => 'Қате тұрақты өрнек (Regex)';
	@override String get regex => 'Тұрақты өрнек (Regex)';
	@override String get downloads => 'Жүктеулер';
	@override String get downloadLocationDescription => 'Жүктелген файлдар сақталатын орынды таңдаңыз';
	@override String get downloadLocationDefault => 'Әдепкі (Қолданба жады)';
	@override String get downloadLocationCustom => 'Таңдамалы орын';
	@override String get selectFolder => 'Қапшықты таңдау';
	@override String get resetToDefault => 'Әдепкі күйге қайтару';
	@override String currentPath({required Object path}) => 'Ағымдағы: ${path}';
	@override String get downloadLocationChanged => 'Жүктеу орны өзгертілді';
	@override String get downloadLocationReset => 'Жүктеу орны әдепкі күйге қайтарылды';
	@override String get downloadLocationInvalid => 'Таңдалған қапшыққа жазу мүмкін емес';
	@override String get downloadLocationPickerUnavailable => 'Бұл құрылғыда қапшықты таңдау мүмкіндігі жоқ';
	@override String get downloadOnWifiOnly => 'Тек Wi-Fi арқылы жүктеу';
	@override String get downloadOnWifiOnlyDescription => 'Мобильді деректер пайдаланылғанда жүктеулерді кідірту';
	@override String get autoRemoveWatchedDownloads => 'Көрілген жүктеулерді автоматты өшіру';
	@override String get autoRemoveWatchedDownloadsDescription => 'Көрілген жүктеулерді автоматты түрде өшіру';
	@override String get cellularDownloadBlocked => 'Мобильді желіде жүктеу бұғатталған. Wi-Fi пайдаланыңыз.';
	@override String get maxVolume => 'Максималды дыбыс';
	@override String get maxVolumeDescription => 'Ақырын видеолар үшін дыбысты 100%-дан асыруға рұқсат беру';
	@override String maxVolumePercent({required Object percent}) => '%${percent}';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Discord-та не көріп жатқаныңызды көрсету';
	@override String get services => 'Қызметтер';
	@override String get servicesDescription => 'Trakt, MyAnimeList, Seerr және т.б. қосыңыз';
	@override String get manageLibrariesDescription => 'Кітапханаларды қайта реттеу және жасыру';
	@override String get companionRemoteServer => 'Көмекші пульт сервері';
	@override String get companionRemoteServerDescription => 'Желідегі мобильді құрылғыларға осы қолданбаны басқаруға рұқсат беру';
	@override String get autoPip => 'Автоматты Суреттегі сурет (PiP)';
	@override String get autoPipDescription => 'Видео ойнап жатқанда қолданбадан шыққанда авто-PiP режиміне өту';
	@override String get matchContentFrameRate => 'Кадр жиілігін сәйкестендіру';
	@override String get matchContentFrameRateDescription => 'Экран жиілігін видео мазмұнына сәйкестендіру';
	@override String get matchRefreshRate => 'Жаңарту жиілігін сәйкестендіру';
	@override String get matchRefreshRateDescription => 'Толық экранда экран жаңарту жиілігін сәйкестендіру';
	@override String get matchDynamicRange => 'Динамикалық диапазонды сәйкестендіру';
	@override String get matchDynamicRangeDescription => 'HDR мазмұн үшін HDR қосу, кейін SDR-ға қайту';
	@override String get displaySwitchDelay => 'Экранды ауыстыру кідірісі';
	@override String get tunneledPlayback => 'Туннельді ойнату';
	@override String get tunneledPlaybackDescription => 'Видео туннельдеуді пайдалану.';
	@override String get audioPassthrough => 'Дыбысты тікелей өткізу (Passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS дыбысын қайта кодтамай ресиверге жібереді.';
	@override String get audioPassthroughDescriptionAppleTv => 'Dolby Digital Plus үшін Apple декодерін пайдалану.';
	@override String get audioDownmix => 'Стереоға түрлендіру (Downmix)';
	@override String get audioDownmixDescription => 'Көп арналы дыбысты стерео динамиктер үшін екі арнаға төмендету';
	@override String get downmixCenterBoost => 'Орталық арнаны күшейту';
	@override String downmixCenterBoostValue({required Object db}) => '${db} дБ';
	@override String get downmixCenterBoostLabel => 'Күшейту (дБ)';
	@override String get downmixCenterBoostShort => 'дБ';
	@override String get audioDownmixNormalize => 'Түрлендіруде дыбысты нормалау';
	@override String get audioDownmixNormalizeDescription => 'Дыбыс бұзылуын болдырмау үшін деңгейді төмендету.';
	@override String get atmosDiagnostics => 'Atmos шығысын тексеру';
	@override String get atmosDiagnosticsDescription => 'Dolby Atmos шығысын тексеру';
	@override String get atmosTestHlsAtmos => 'Apple Atmos ағыны';
	@override String get atmosTestHlsAtmosDescription => 'Дұрыс жұмыс істейтін Dolby Atmos ағыны.';
	@override String get atmosTestHlsControl => 'Apple көлемді дыбыс ағыны';
	@override String get atmosTestHlsControlDescription => 'Atmos емес бақылау ағыны.';
	@override String get atmosTestRawStream => 'Өңделмеген EAC3 ағыны';
	@override String get atmosTestRawStreamDescription => 'Тест файлын ішкі Atmos ретінде тарату.';
	@override String get atmosTestRawFile => 'Өңделмеген EAC3 файлы';
	@override String get atmosTestRawFileDescription => 'Тест файлын ойнату.';
	@override String get atmosTestAsbarNative => 'Сэмпл-буфер рендерері (нативті)';
	@override String get atmosTestAsbarNativeDescription => 'Файлдың өзгертілмеген сығылған дыбысын тікелей жүйелік рендерерге береді. Тест файлының URL-і қажет.';
	@override String get atmosTestAsbarGenerated => 'Сэмпл-буфер рендерері (қайта құрылған)';
	@override String get atmosTestAsbarGeneratedDescription => 'Сол сияқты, бірақ дыбыс сипаттамасы ойнату кезіндегідей қайта құрылады. Тест файлының URL-і қажет.';
	@override String get atmosTestSessionMode => 'Фильмді ойнату сеансы режимін пайдалану';
	@override String get atmosTestSessionModeDescription => 'Өшірулі — Dolby құжаттаған режим. Қосулы — бұрын пайдаланылған режим.';
	@override String get atmosTestShowRoutePicker => 'AirPlay шығысын таңдау';
	@override String get atmosTestHideRoutePicker => 'AirPlay шығысын таңдау терезесін жасыру';
	@override String get atmosTestRoutePickerDescription => 'Тестті AirPlay қабылдағышына жібереді. Анықталған дыбыс режимін тек AirPlay хабарлайды.';
	@override String get atmosTestStop => 'Тестті тоқтату';
	@override String get atmosTestUrl => 'Тест файлының URL-і';
	@override String get atmosTestUrlDescription => 'Өңделмеген .ec3 файлының HTTP URL-і';
	@override String get atmosTestUrlMissing => 'Алдымен тест файлының URL-ін орнатыңыз';
	@override String get atmosTestStatus => 'Мәртебесі';
	@override String get dvConversionMode => 'Dolby Vision түрлендіруі';
	@override String get dvConversionModeDescription => 'ExoPlayer-дің Dolby Vision Profile 7 файлдарын өңдеу әдісін таңдаңыз.';
	@override String get dvConversionAuto => 'Автоматты';
	@override String get dvConversionNative => 'Ішкі / Өшірулі';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Құрылғы мүмкіндіктерін пайдалану';
	@override String get dvConversionNativeDescription => 'Ішкі DV7 режимін мәжбүрлеу';
	@override String get dvConversionDv81Description => 'Dolby Vision profile 8.1 форматына түрлендіру';
	@override String get dvConversionHevcStripDescription => 'Dolby Vision қабаттарын алып тастап, HEVC ретінде көрсету';
	@override String get requireProfileSelectionOnOpen => 'Ашқанда профильді сұрау';
	@override String get requireProfileSelectionOnOpenDescription => 'Қолданба ашылған сайын профильді таңдауды көрсету';
	@override String get forceTvMode => 'TV режимін мәжбүрлеу';
	@override String get forceTvModeDescription => 'TV интерфейсін мәжбүрлеу.';
	@override String get startInFullscreen => 'Толық экранда бастау';
	@override String get startInFullscreenDescription => 'Plezy-ді ашқанда толық экран режимінде ашу';
	@override String get exitFullscreenOnPlayerClose => 'Ойнатқыш жабылғанда толық экраннан шығу';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Видео ойнатқышты жапқанда автоматты түрде толық экраннан шығу';
	@override String get autoHidePerformanceOverlay => 'Өнімділік панелін авто-жасыру';
	@override String get autoHidePerformanceOverlayDescription => 'Өнімділік панелін басқару элементтерімен бірге жасыру';
	@override String get showNavBarLabels => 'Навигация панелінің мәтіндерін көрсету';
	@override String get showNavBarLabelsDescription => 'Навигация белгішелерінің астында мәтінді көрсету';
	@override String get startupSection => 'Бастапқы бөлім';
	@override String get liveTvDefaultFavorites => 'Тікелей TV-де таңдаулы арналарды әдепкі ету';
	@override String get liveTvDefaultFavoritesDescription => 'Тікелей TV ашылғанда тек таңдаулы арналарды көрсету';
	@override String get display => 'Дисплей';
	@override String get homeScreen => 'Басты экран';
	@override String get navigation => 'Навигация';
	@override String get window => 'Терезе';
	@override String get content => 'Мазмұн';
	@override String get player => 'Ойнатқыш';
	@override String get subtitlesAndConfig => 'Субтитрлер мен конфигурация';
	@override String get seekAndTiming => 'Айналдыру және уақытты реттеу';
	@override String get behavior => 'Мінез-құлық';
}

// Path: search
class _Translations$search$kk extends Translations$search$en {
	_Translations$search$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Фильмдер, сериалдар, музыка іздеу...';
	@override String get tryDifferentTerm => 'Басқа іздеу сөзін байқап көріңіз';
	@override String get searchYourMedia => 'Медиафайлдардан іздеу';
	@override String get enterTitleActorOrKeyword => 'Атауын, актерді немесе кілт сөзді енгізіңіз';
}

// Path: hotkeys
class _Translations$hotkeys$kk extends Translations$hotkeys$en {
	_Translations$hotkeys$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '${actionName} үшін пернелер тіркесін орнату';
	@override String get clearShortcut => 'Тіркесті тазалау';
	@override String get noShortcutSet => 'Пернелер тіркесі орнатылмаған';
	@override String get currentShortcut => 'Ағымдағы тіркес:';
	@override String get pressToRecord => 'Тіркесті жазу үшін басыңыз';
	@override String get recordingShortcut => 'Енді пернелерді басыңыз';
	@override late final _Translations$hotkeys$actions$kk actions = _Translations$hotkeys$actions$kk._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$kk extends Translations$fileInfo$en {
	_Translations$fileInfo$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Файл туралы ақпарат';
	@override String get video => 'Видео';
	@override String get audio => 'Аудио';
	@override String get subtitles => 'Субтитрлер';
	@override String get file => 'Файл';
	@override String get codec => 'Кодек';
	@override String get resolution => 'Ажыратымдылық';
	@override String get bitrate => 'Биттік жылдамдық (Bitrate)';
	@override String get frameRate => 'Кадр жиілігі';
	@override String get aspectRatio => 'Тараптар қатынасы';
	@override String get profile => 'Профиль';
	@override String get bitDepth => 'Бит тереңдігі';
	@override String get colorSpace => 'Түс кеңістігі';
	@override String get colorRange => 'Түс диапазоны';
	@override String get colorPrimaries => 'Негізгі түстер';
	@override String get chromaSubsampling => 'Түстік субдискретизация';
	@override String get channels => 'Арналар';
	@override String get overallBitrate => 'Жалпы биттік жылдамдық';
	@override String get path => 'Жол';
	@override String get size => 'Көлемі';
	@override String get container => 'Контейнер';
	@override String get duration => 'Уақыты';
	@override String get optimizedForStreaming => 'Ағынды беру үшін оңтайландырылған';
	@override String get has64bitOffsets => '64-биттік ығысулар';
}

// Path: mediaMenu
class _Translations$mediaMenu$kk extends Translations$mediaMenu$en {
	_Translations$mediaMenu$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Көрілді деп белгілеу';
	@override String get markAsUnwatched => 'Көрілмеді деп белгілеу';
	@override String get removeFromContinueWatching => '"Көруді жалғастыру" тізімінен өшіру';
	@override String get viewDetails => 'Толығырақ көру';
	@override String get goToSeries => 'Сериалға өту';
	@override String get shufflePlay => 'Араластырып ойнату';
	@override String get shuffleNotAvailableOffline => 'Араластырып ойнату офлайн режимде қолжетімсіз';
	@override String get fileInfo => 'Файл туралы ақпарат';
	@override String get deleteFromServer => 'Серверден өшіру';
	@override String get confirmDelete => 'Осы медиа мен файлдар серверден өшірілсін бе?';
	@override String get deleteMultipleWarning => 'Бұл барлық бөлімдер мен файлдарға әсер етеді.';
	@override String get mediaDeletedSuccessfully => 'Медиа элементі сәтті өшірілді';
	@override String get mediaFailedToDelete => 'Медиа элементін өшіру мүмкін болмады';
	@override String get rate => 'Бағалау';
	@override String get playFromBeginning => 'Басынан бастап ойнату';
	@override String get playVersion => 'Нұсқаны ойнату...';
}

// Path: rateSheet
class _Translations$rateSheet$kk extends Translations$rateSheet$en {
	_Translations$rateSheet$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Бағалау';
	@override String get server => 'Сервер';
	@override String get favorite => 'Таңдаулы';
	@override String get favorited => 'Таңдаулыларға қосылды';
	@override String get saved => 'Сақталды';
	@override String get notAvailable => 'Сәйкестік табылмады';
	@override String get noConnectedServices => 'Бағалау үшін Баптаулардан қызметті қосыңыз.';
}

// Path: accessibility
class _Translations$accessibility$kk extends Translations$accessibility$en {
	_Translations$accessibility$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, фильм';
	@override String mediaCardShow({required Object title}) => '${title}, TV шоу';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'көрілген';
	@override String mediaCardPartiallyWatched({required Object percent}) => '%${percent} көрілген';
	@override String get mediaCardUnwatched => 'көрілмеген';
	@override String get tapToPlay => 'Ойнату үшін түртіңіз';
	@override String get decrease => 'Азайту';
	@override String get increase => 'Арттыру';
	@override String decreaseValue({required Object label}) => '${label} мәнін азайту';
	@override String increaseValue({required Object label}) => '${label} мәнін арттыру';
	@override String get hue => 'Түс реңкі';
	@override String get saturation => 'Қанықтылық';
	@override String get brightness => 'Жарықтық';
	@override String get hexColor => 'Hex түсі';
	@override String get expandText => 'Мәтінді жаю';
	@override String get collapseText => 'Мәтінді жинау';
	@override String get alphabetNavigation => 'Алфавиттік навигация';
	@override String get alphabetScrollHint => 'Әріптер бойынша өту үшін жоғары немесе төмен сырғытыңыз';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Жол ${row} / ${rowCount}, баған ${column} / ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Жол ${row} / ${rowCount}';
}

// Path: tooltips
class _Translations$tooltips$kk extends Translations$tooltips$en {
	_Translations$tooltips$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Араластырып ойнату';
	@override String get playTrailer => 'Трейлерді ойнату';
	@override String get markAsWatched => 'Көрілді деп белгілеу';
	@override String get markAsUnwatched => 'Көрілмеді деп белгілеу';
}

// Path: audioTracks
class _Translations$audioTracks$kk extends Translations$audioTracks$en {
	_Translations$audioTracks$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Аудиожол ${n}';
}

// Path: videoControls
class _Translations$videoControls$kk extends Translations$videoControls$en {
	_Translations$videoControls$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Дыбыс';
	@override String get subtitlesLabel => 'Субтитр';
	@override String get resetToZero => '0мс-қа қалпына келтіру';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} кейін ойнатылады';
	@override String playsEarlier({required Object label}) => '${label} бұрын ойнатылады';
	@override String get noOffset => 'Ығысусыз';
	@override String get letterbox => 'Кең экран (Letterbox)';
	@override String get fillScreen => 'Экранды толтыру';
	@override String get stretch => 'Созу';
	@override String get lockRotation => 'Бұрылысты бұғаттау';
	@override String get unlockRotation => 'Бұрылысты бұғаттаудан шығару';
	@override String get timerActive => 'Таймер белсенді';
	@override String playbackWillPauseIn({required Object duration}) => 'Ойнату ${duration} кейін кідіртіледі';
	@override String get sleepTimerEndOfVideo => 'Ағымдағы видеоның соңы';
	@override String get sleepTimerStopAtHeader => 'Тоқтату уақыты';
	@override String get sleepTimerDurationHeader => 'Таймер';
	@override String get playbackWillPauseAtEnd => 'Ойнату осы видеоның соңында кідіртіледі';
	@override String get stillWatching => 'Әлі де көріп отырсыз ба?';
	@override String pausingIn({required Object seconds}) => '${seconds}сек кейін кідіртіледі';
	@override String get continueWatching => 'Жалғастыру';
	@override String get autoPlayNext => 'Келесіні автоматты ойнату';
	@override String get playNext => 'Келесіні ойнату';
	@override String get playButton => 'Ойнату';
	@override String get pauseButton => 'Кідірту';
	@override String get showPlaybackControls => 'Басқару элементтерін көрсету';
	@override String get hidePlaybackControls => 'Басқару элементтерін жасыру';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} секунд артқа айналдыру';
	@override String seekForwardButton({required Object seconds}) => '${seconds} секунд алға айналдыру';
	@override String get previousButton => 'Алдыңғы бөлім';
	@override String get nextButton => 'Келесі бөлім';
	@override String get previousChapterButton => 'Алдыңғы бөлімше';
	@override String get nextChapterButton => 'Келесі бөлімше';
	@override String get muteButton => 'Дыбысты өшіру';
	@override String get unmuteButton => 'Дыбысты қосу';
	@override String get settingsButton => 'Ойнату баптаулары';
	@override String get tracksButton => 'Дыбыс және субтитрлер';
	@override String get chaptersButton => 'Бөлімдер';
	@override String get versionQualityButton => 'Нұсқа және сапа';
	@override String get versionColumnHeader => 'Нұсқа';
	@override String get qualityColumnHeader => 'Сапа';
	@override String get qualityOriginal => 'Түпнұсқа';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Мбит/с';
	@override String get transcodeUnavailableFallback => 'Түрлендіру қолжетімсіз — түпнұсқа сапада ойнатылады';
	@override String get subtitleUnavailableFallback => 'Таңдалған субтитр жүктелмеді';
	@override String get pipButton => 'Суреттегі сурет режимі';
	@override String get aspectRatioButton => 'Тараптар қатынасы';
	@override String get ambientLighting => 'Фондық жарықтандыру';
	@override String get fullscreenButton => 'Толық экранға өту';
	@override String get exitFullscreenButton => 'Толық экраннан шығу';
	@override String get alwaysOnTopButton => 'Әрдайым үстінде';
	@override String get rotationLockButton => 'Бұрылыс бұғаттауы';
	@override String get lockScreen => 'Экранды бұғаттау';
	@override String get screenLockButton => 'Экран бұғаттауы';
	@override String get longPressToUnlock => 'Бұғаттаудан шығару үшін ұзақ басыңыз';
	@override String get timelineSlider => 'Видео уақыт шкаласы';
	@override String get volumeSlider => 'Дыбыс деңгейі';
	@override String endsAt({required Object time}) => 'Аяқталу уақыты: ${time}';
	@override String get pipActive => 'Суреттегі сурет режимінде ойнатылуда';
	@override String get pipFailed => 'PiP режимін іске қосу қатесі';
	@override String get screenshotSaved => 'Экран суреті сақталды';
	@override String zoomPercent({required Object percent}) => 'Масштаб %${percent}';
	@override late final _Translations$videoControls$pipErrors$kk pipErrors = _Translations$videoControls$pipErrors$kk._(_root);
	@override String get chapters => 'Бөлімдер';
	@override String get noChaptersAvailable => 'Бөлімдер қолжетімсіз';
	@override String get queue => 'Кезек';
	@override String get noQueueItems => 'Кезекте элементтер жоқ';
	@override String get searchSubtitles => 'Субтитр іздеу';
	@override String get language => 'Тіл';
	@override String get noSubtitlesFound => 'Субтитр табылмады';
	@override String get subtitleDownloaded => 'Субтитр жүктелді';
	@override String get subtitleDownloadedNotApplied => 'Субтитр жүктелді, бірақ қолданылмады';
	@override String get subtitleDownloadFailed => 'Субтитрді жүктеу мүмкін болмады';
	@override String get searchLanguages => 'Тілдерден іздеу...';
}

// Path: messages
class _Translations$messages$kk extends Translations$messages$en {
	_Translations$messages$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Көрілді деп белгіленді';
	@override String get markedAsUnwatched => 'Көрілмеді деп белгіленді';
	@override String get markedAsWatchedOffline => 'Көрілді деп белгіленді (онлайн болғанда синхрондалады)';
	@override String get markedAsUnwatchedOffline => 'Көрілмеді деп белгіленді (онлайн болғанда синхрондалады)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Автоматты түрде өшірілді: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('kk'))(n,
		one: 'Көрілген ${n} жүктеу автоматты өшірілді',
		other: 'Көрілген ${n} жүктеу автоматты өшірілді',
	);
	@override String get removedFromContinueWatching => '"Көруді жалғастыру" тізімінен өшірілді';
	@override String errorLoading({required Object error}) => 'Қате: ${error}';
	@override String get searchPartialResults => 'Кейбір медиа серверлерінде іздеу орындалмады. Қолжетімді нәтижелер көрсетілуде.';
	@override String get streamInterrupted => 'Ағын үзілді. Қайталау үшін ойнату түймесін басыңыз.';
	@override String get liveStreamInterrupted => 'Тікелей ағын үзілді. Қайталау үшін ойнату түймесін басыңыз.';
	@override String get fileInfoNotAvailable => 'Файл туралы ақпарат қолжетімсіз';
	@override String get playbackAuthenticationRequired => 'Осы элементті ойнату үшін серверге қайтадан кіріңіз.';
	@override String get playbackServerUnavailable => 'Медиа сервері қолжетімсіз. Кейінірек қайталаңыз.';
	@override String get playbackDataInvalid => 'Сервер қате ойнату мәліметтерін қайтарды.';
	@override String get playbackCancelled => 'Ойнатудан бас тартылды.';
	@override String get playbackFailed => 'Ойнатуды іске қосу қатесі.';
	@override String errorLoadingFileInfo({required Object error}) => 'Файл ақпаратын жүктеу қатесі: ${error}';
	@override String get errorLoadingSeries => 'Сериалды жүктеу қатесі';
	@override String get musicNotSupported => 'Музыка ойнату әлі қолдау таппайды';
	@override String get noDescriptionAvailable => 'Сипаттамасы жоқ';
	@override String get noProfilesAvailable => 'Профильдер жоқ';
	@override String get contactAdminForProfiles => 'Профиль қосу үшін администраторға хабарласыңыз';
	@override String get unableToDetermineLibrarySection => 'Кітапхана бөлімін анықтау мүмкін болмады';
	@override String get logsCleared => 'Журналдар тазаланды';
	@override String get logsCopied => 'Журналдар көшірілді';
	@override String get noLogsAvailable => 'Журналдар жоқ';
	@override String libraryScanning({required Object title}) => '"${title}" сканерленуде...';
	@override String libraryScanStarted({required Object title}) => '"${title}" үшін сканерлеу басталды';
	@override String libraryScanFailed({required Object error}) => 'Кітапхананы сканерлеу мүмкін болмады: ${error}';
	@override String metadataRefreshing({required Object title}) => '"${title}" үшін метадеректер жаңартылуда...';
	@override String metadataRefreshStarted({required Object title}) => '"${title}" үшін метадеректерді жаңарту басталды';
	@override String metadataRefreshFailed({required Object error}) => 'Метадеректерді жаңарту мүмкін болмады: ${error}';
	@override String get logoutConfirm => 'Шынымен шыққыңыз келе ме?';
	@override String get noSeasonsFound => 'Маусымдар табылмады';
	@override String get seasonsLoadFailed => 'Маусымдарды жүктеу мүмкін болмады';
	@override String get noEpisodesFound => 'Бірінші маусымда бөлімдер табылмады';
	@override String get noEpisodesFoundGeneral => 'Бөлімдер табылмады';
	@override String get episodesLoadFailed => 'Бөлімдерді жүктеу мүмкін болмады';
	@override String get noResultsFound => 'Нәтижелер табылмады';
	@override String sleepTimerSet({required Object label}) => 'Ұйқы таймері ${label} уақытына орнатылды';
	@override String get noItemsAvailable => 'Элементтер жоқ';
	@override String get failedToCreatePlayQueueNoItems => 'Ойнату кезегін жасау мүмкін болмады — элементтер жоқ';
	@override String failedPlayback({required Object action, required Object error}) => '${action} сәтсіз аяқталды: ${error}';
	@override String get switchingToCompatiblePlayer => 'Үйлесімді ойнатқышқа ауысуда...';
	@override String get serverLimitTitle => 'Ойнату қатесі';
	@override String get serverLimitBody => 'Сервер қатесі (HTTP 500). Шектеу бұл сеансты қабылдамады.';
	@override String get logsUploaded => 'Журналдар жүктелді';
	@override String get logsUploadFailed => 'Журналдарды жүктеу мүмкін болмады';
	@override String get logId => 'Журнал ID-сі';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$kk extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get text => 'Мәтін';
	@override String get border => 'Жиек';
	@override String get background => 'Фон';
	@override String get fontSize => 'Қаріп өлшемі';
	@override String get textColor => 'Мәтін түсі';
	@override String get borderSize => 'Жиек өлшемі';
	@override String get borderColor => 'Жиек түсі';
	@override String get backgroundOpacity => 'Фон мөлдірлігі';
	@override String get backgroundColor => 'Фон түсі';
	@override String get position => 'Орналасуы';
	@override String get assOverride => 'ASS қайта анықтау';
	@override String get overrideScale => 'Масштабтау';
	@override String get overrideForce => 'Мәжбүрлеу';
	@override String get overrideStrip => 'Форматтауды жою';
	@override String get positionTop => 'Жоғары';
	@override String get positionBottom => 'Төмен';
	@override String get bold => 'Қалың';
	@override String get italic => 'Көлбеу';
	@override String get renderResolution => 'Рендеринг ажыратымдылығы';
	@override String get renderResolutionScreen => 'Экран ажыратымдылығы';
	@override String get renderResolutionVideo => 'Видео ажыратымдылығы';
}

// Path: mpvConfig
class _Translations$mpvConfig$kk extends Translations$mpvConfig$en {
	_Translations$mpvConfig$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Кеңейтілген видео ойнатқыш баптаулары';
	@override String get presets => 'Дайын баптаулар';
	@override String get noPresets => 'Сақталған баптаулар жоқ';
	@override String get saveAsPreset => 'Баптау ретінде сақтау...';
	@override String get presetName => 'Баптау атауы';
	@override String get presetNameHint => 'Осы баптау үшін атау енгізіңіз';
	@override String get loadPreset => 'Жүктеу';
	@override String get deletePreset => 'Өшіру';
	@override String get presetSaved => 'Баптау сақталды';
	@override String get presetLoaded => 'Баптау жүктелді';
	@override String get presetDeleted => 'Баптау өшірілді';
	@override String get confirmDeletePreset => 'Осы баптауды өшіргіңіз келетініне сенімдісіз бе?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# түсініктеме';
}

// Path: dialog
class _Translations$dialog$kk extends Translations$dialog$en {
	_Translations$dialog$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Әрекетті растау';
}

// Path: profiles
class _Translations$profiles$kk extends Translations$profiles$en {
	_Translations$profiles$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Plezy профилін қосу';
	@override String get switchingProfile => 'Профильді ауыстыру…';
	@override String get deleteThisProfileTitle => 'Осы профиль өшірілсін бе?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} өшіріледі. Қосылымдарға әсер етпейді.';
	@override String get active => 'Белсенді';
	@override String get manage => 'Басқару';
	@override String get delete => 'Өшіру';
	@override String get signOut => 'Шығу';
	@override String get signOutPlexTitle => 'Plex-тен шығу?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} мен барлық Plex Home пайдаланушылары өшіріледі.';
	@override String get signedOutPlex => 'Plex-тен шықтыңыз.';
	@override String get signOutFailed => 'Шығу мүмкін болмады.';
	@override String get sectionTitle => 'Профильдер';
	@override String get summarySingle => 'Басқарылатын пайдаланушыларды біріктіру үшін профильдер қосыңыз';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} профиль · белсенді: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} профиль';
	@override String get removeConnectionTitle => 'Қосылым өшірілсін бе?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName} пайдаланушысының ${connectionLabel} қолжетімділігі өшіріледі.';
	@override String get deleteProfileTitle => 'Профиль өшірілсін бе?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} мен оның қосылымдары өшіріледі.';
	@override String get profileNameLabel => 'Профиль атауы';
	@override String get pinProtectionLabel => 'PIN қорғанысы';
	@override String get pinManagedByPlex => 'PIN кодын Plex басқарады. plex.tv сайтында өңдеңіз.';
	@override String get noPinSetEditOnPlex => 'PIN код орнатылмаған.';
	@override String get setPin => 'PIN орнату';
	@override String get setPinTitle => 'PIN орнату';
	@override String get confirmPinTitle => 'PIN кодын растау';
	@override String get pinSet => 'PIN орнатылды';
	@override String get changePin => 'Өзгерту';
	@override String get removePin => 'Өшіру';
	@override String get connectionsLabel => 'Қосылымдар';
	@override String get add => 'Қосу';
	@override String get deleteProfileButton => 'Профильді өшіру';
	@override String get noConnectionsHint => 'Қосылымдар жоқ — бұл профильді пайдалану үшін қосылым қосыңыз.';
	@override String get noConnections => 'Қосылымдар жоқ';
	@override String get plexHomeAccount => 'Plex Home тіркелгісі';
	@override String get connectionDefault => 'Әдепкі';
	@override String connectionAs({required Object displayName}) => '${displayName} ретінде';
	@override String get makeDefault => 'Әдепкі ету';
	@override String get removeConnection => 'Өшіру';
	@override String get profileRenamed => 'Профиль атауы өзгертілді.';
	@override String borrowAddTo({required Object displayName}) => '${displayName} профиліне қосу';
	@override String get borrowExplain => 'Басқа профильдің қосылымын пайдаланыңыз.';
	@override String get borrowEmpty => 'Әлі де пайдаланатын ештеңе жоқ.';
	@override String get borrowEmptySubtitle => 'Алдымен басқа профильге Plex немесе Jellyfin қосыңыз.';
	@override String get borrowLoadFailed => 'Қолжетімді қосылымдарды жүктеу мүмкін болмады.';
	@override String borrowFromProfile({required Object displayName}) => '${displayName} профилінен';
	@override String get borrowConnectionBorrowed => 'Қосылым пайдаланылды.';
	@override String get borrowFailed => 'Қосылымды пайдалану мүмкін болмады.';
	@override String get incorrectPin => 'Қате PIN код.';
	@override String get incorrectPinTryAgain => 'Қате PIN код. Қайтадан байқап көріңіз.';
	@override String get sourceProfileMissingParentAccount => 'Бастапқы профильде негізгі тіркелгі жоқ.';
	@override String get failedToLoadHomeUsers => 'Plex Home пайдаланушыларын жүктеу мүмкін болмады.';
	@override String get failedToVerifyPin => 'PIN кодын тексеру мүмкін болмады.';
	@override String get newProfile => 'Жаңа профиль';
	@override String get profileNameHint => 'мысалы, Қонақтар, Балалар';
	@override String get pinProtectionOptional => 'PIN қорғанысы (қосымша)';
	@override String get pinExplain => 'Профильдер арасында ауысу үшін 4 таңбалы PIN код қажет.';
	@override String get continueButton => 'Жалғастыру';
	@override String get pinsDontMatch => 'PIN кодтар сәйкес келмейді';
}

// Path: connections
class _Translations$connections$kk extends Translations$connections$en {
	_Translations$connections$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Қосылымдар';
	@override String get addConnection => 'Қосылым қосу';
	@override String get addConnectionSubtitleNoProfile => 'Plex арқылы кіріңіз немесе Jellyfin серверіне қосылыңыз';
	@override String addConnectionSubtitleScoped({required Object displayName}) => '${displayName} профиліне қосу';
	@override String sessionExpiredOne({required Object name}) => '${name} үшін сеанс мерзімі өтті';
	@override String sessionExpiredMany({required Object count}) => '${count} сервер үшін сеанс мерзімі өтті';
	@override String get signInAgain => 'Қайтадан кіру';
	@override String get editJellyfinTitle => 'Jellyfin қосылымын өңдеу';
	@override String editJellyfinIntro({required Object serverName}) => '${serverName} үшін URL мекенжайын қосыңыз немесе өшіріңіз.';
}

// Path: discover
class _Translations$discover$kk extends Translations$discover$en {
	_Translations$discover$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Шолу';
	@override String get noContentAvailable => 'Мазмұн қолжетімсіз';
	@override String get addMediaToLibraries => 'Кітапханаларыңызға медиа қосыңыз';
	@override String get continueWatching => 'Көруді жалғастыру';
	@override String continueWatchingIn({required Object library}) => '${library} ішінде көруді жалғастыру';
	@override String get nextUp => 'Келесіде';
	@override String nextUpIn({required Object library}) => '${library} ішінде келесіде';
	@override String get recentlyAdded => 'Соңғы қосылғандар';
	@override String recentlyAddedIn({required Object library}) => '${library} ішінде соңғы қосылғандар';
	@override String latestAlbumsIn({required Object library}) => '${library} ішінде соңғы альбомдар';
	@override String recentlyPlayedIn({required Object library}) => '${library} ішінде соңғы ойнатылғандар';
	@override String mostPlayedIn({required Object library}) => '${library} ішінде ең көп ойнатылғандар';
	@override String playEpisode({required Object season, required Object episode}) => 'М${season}Б${episode}';
	@override String get overview => 'Сипаттамасы';
	@override String get cast => 'Актерлер';
	@override String get extras => 'Трейлерлер мен қосымшалар';
	@override String get studio => 'Студия';
	@override String get rating => 'Рейтинг';
	@override String get director => 'Режиссер';
	@override String get directors => 'Режиссерлер';
	@override String get movie => 'Фильм';
	@override String get tvShow => 'TV Шоу';
	@override String minutesLeft({required Object minutes}) => '${minutes} мин қалды';
	@override String get moreLikeThis => 'Ұқсастар';
}

// Path: errors
class _Translations$errors$kk extends Translations$errors$en {
	_Translations$errors$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Іздеу қатесі: ${error}';
	@override String get searchUnavailable => 'Іздеу ешбір медиа серверге қосыла алмады.';
	@override String connectionTimeout({required Object context}) => '${context} жүктеу уақыты өтті';
	@override String get connectionFailed => 'Медиа серверіне қосылу мүмкін емес';
	@override String unableToLoad({required Object context}) => '${context} жүктеу мүмкін болмады.';
	@override String get noClientAvailable => 'Қолжетімді клиент жоқ';
	@override String get pleaseEnterToken => 'Токенді енгізіңіз';
	@override String get invalidToken => 'Жарамсыз токен';
	@override String failedToVerifyToken({required Object error}) => 'Токенді тексеру мүмкін болмады: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '${displayName} профиліне ауысу мүмкін болмады';
	@override String failedToDeleteProfile({required Object displayName}) => '${displayName} профилін өшіру мүмкін болмады';
	@override String get failedToRate => 'Рейтингті жаңарту мүмкін болмады';
}

// Path: libraries
class _Translations$libraries$kk extends Translations$libraries$en {
	_Translations$libraries$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Кітапханалар';
	@override String get fallbackTitle => 'Кітапхана';
	@override String get scanLibraryFiles => 'Файлдарды сканерлеу';
	@override String get scanLibrary => 'Кітапхананы сканерлеу';
	@override String get analyze => 'Талдау жасау';
	@override String get analyzeLibrary => 'Кітапханаға талдау жасау';
	@override String get refreshMetadata => 'Метадеректерді жаңарту';
	@override String get emptyTrash => 'Себетті тазалау';
	@override String emptyingTrash({required Object title}) => '"${title}" себеті тазалануда...';
	@override String trashEmptied({required Object title}) => '"${title}" себеті тазаланды';
	@override String failedToEmptyTrash({required Object error}) => 'Себетті тазалау мүмкін болмады: ${error}';
	@override String analyzing({required Object title}) => '"${title}" талдануда...';
	@override String analysisStarted({required Object title}) => '"${title}" үшін талдау басталды';
	@override String failedToAnalyze({required Object error}) => 'Талдау жасау мүмкін болмады: ${error}';
	@override String get noLibrariesFound => 'Кітапханалар табылмады';
	@override String get allLibrariesHidden => 'Барлық кітапханалар жасырылған';
	@override String hiddenLibrariesCount({required Object count}) => 'Жасырын кітапханалар (${count})';
	@override String get thisLibraryIsEmpty => 'Бұл кітапхана бос';
	@override String get noItemsMatchFilters => 'Фильтрлерге сәйкес элементтер табылмады';
	@override String get resetFilters => 'Фильтрлерді қалпына келтіру';
	@override String get all => 'Барлығы';
	@override String get clearAll => 'Барлығын тазалау';
	@override String scanLibraryConfirm({required Object title}) => '"${title}" кітапханасын сканерлегіңіз келе ме?';
	@override String analyzeLibraryConfirm({required Object title}) => '"${title}" кітапханасына талдау жасағыңыз келе ме?';
	@override String refreshMetadataConfirm({required Object title}) => '"${title}" метадеректерін жаңартасыз ба?';
	@override String emptyTrashConfirm({required Object title}) => '"${title}" себетін тазалайсыз ба?';
	@override String get manageLibraries => 'Кітапханаларды басқару';
	@override String get sort => 'Сұрыптау';
	@override String get sortBy => 'Сұрыптау реті';
	@override String get filters => 'Фильтрлер';
	@override String get confirmActionMessage => 'Осы әрекетті орындағыңыз келе ме?';
	@override String get showLibrary => 'Кітапхананы көрсету';
	@override String get hideLibrary => 'Кітапхананы жасыру';
	@override String get libraryOptions => 'Кітапхана параметрлері';
	@override String get content => 'кітапхана мазмұны';
	@override String get selectLibrary => 'Кітапхананы таңдау';
	@override String filtersWithCount({required Object count}) => 'Фильтрлер (${count})';
	@override String get noRecommendations => 'Ұсыныстар жоқ';
	@override String get noCollections => 'Бұл кітапханада топтамалар жоқ';
	@override String get noFoldersFound => 'Қапшықтар табылмады';
	@override String get folders => 'қапшықтар';
	@override late final _Translations$libraries$tabs$kk tabs = _Translations$libraries$tabs$kk._(_root);
	@override late final _Translations$libraries$groupings$kk groupings = _Translations$libraries$groupings$kk._(_root);
	@override late final _Translations$libraries$filterCategories$kk filterCategories = _Translations$libraries$filterCategories$kk._(_root);
	@override late final _Translations$libraries$sortLabels$kk sortLabels = _Translations$libraries$sortLabels$kk._(_root);
}

// Path: about
class _Translations$about$kk extends Translations$about$en {
	_Translations$about$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Қолданба туралы';
	@override String get openSourceLicenses => 'Ашық бастапқы код лицензиялары';
	@override String versionLabel({required Object version}) => 'Нұсқа ${version}';
	@override String get appDescription => 'Flutter негізіндегі ыңғайлы Plex және Jellyfin клиенті';
	@override String get viewLicensesDescription => 'Үшінші тарап кітапханаларының лицензияларын көру';
}

// Path: serverSelection
class _Translations$serverSelection$kk extends Translations$serverSelection$en {
	_Translations$serverSelection$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => '${username} (${email}) үшін серверлер табылмады';
	@override String failedToLoadServers({required Object error}) => 'Серверлерді жүктеу қатесі: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$kk extends Translations$hubDetail$en {
	_Translations$hubDetail$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Атауы';
	@override String get releaseYear => 'Шыққан жылы';
	@override String get dateAdded => 'Қосылған күні';
	@override String get rating => 'Рейтинг';
	@override String get noItemsFound => 'Элементтер табылмады';
}

// Path: logs
class _Translations$logs$kk extends Translations$logs$en {
	_Translations$logs$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Журналдарды тазалау';
	@override String get copyLogs => 'Журналдарды көшіру';
	@override String get uploadLogs => 'Журналдарды жүктеу';
}

// Path: licenses
class _Translations$licenses$kk extends Translations$licenses$en {
	_Translations$licenses$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Байланысты пакеттер';
	@override String get license => 'Лицензия';
	@override String licenseNumber({required Object number}) => 'Лицензия ${number}';
	@override String licensesCount({required Object count}) => '${count} лицензия';
}

// Path: navigation
class _Translations$navigation$kk extends Translations$navigation$en {
	_Translations$navigation$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Кітапханалар';
	@override String get downloads => 'Жүктеулер';
	@override String get liveTv => 'Тікелей TV';
	@override String get explore => 'Шолу';
}

// Path: explore
class _Translations$explore$kk extends Translations$explore$en {
	_Translations$explore$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Шолу';
	@override String get selectSource => 'Дереккөзді таңдаңыз';
	@override late final _Translations$explore$rows$kk rows = _Translations$explore$rows$kk._(_root);
	@override late final _Translations$explore$status$kk status = _Translations$explore$status$kk._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('kk'))(n,
		one: '${n} бөлім',
		other: '${n} бөлім',
	);
	@override String get cast => 'Актерлер';
	@override String get characters => 'Кейіпкерлер';
	@override String get addToWatchlist => 'Көру тізіміне қосу';
	@override String get removeFromWatchlist => 'Көру тізімінен өшіру';
	@override String get watchlistUpdateFailed => 'Көру тізімін жаңарту мүмкін болмады';
	@override String get notInLibrary => 'Кітапханаңызда жоқ';
	@override String get inTheseLibraries => 'Осы кітапханаларда бар';
	@override String get checkingLibrary => 'Кітапхана тексерілуде...';
	@override String get emptyTitle => 'Әлі де мұнда ештеңе жоқ';
	@override String emptyMessage({required Object source}) => '${source} дереккөзінен алынған қатарлар мұнда көрінеді.';
	@override String searchHint({required Object source}) => '${source} ішінен іздеу';
	@override String searchEmpty({required Object query}) => '"${query}" бойынша нәтиже табылмады';
	@override String searchPrompt({required Object source}) => '${source} арқылы фильмдер мен сериалдарды іздеңіз.';
	@override String get searchFailed => 'Іздеу қатесі. Қосылымды тексеріңіз.';
}

// Path: liveTv
class _Translations$liveTv$kk extends Translations$liveTv$en {
	_Translations$liveTv$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Тікелей TV';
	@override String get guide => 'Телебағдарлама';
	@override String get noChannels => 'Қолжетімді арналар жоқ';
	@override String get noDvr => 'Серверде DVR бапталмаған';
	@override String get serverUnavailable => 'Тікелей TV сервері қолжетімсіз.';
	@override String get serverNotConnected => 'Тікелей TV серверіне қосылмаған.';
	@override String get noPrograms => 'Бағдарлама ақпараты жоқ';
	@override String get liveStreamFailed => 'Тікелей ағын қатесі';
	@override String get unknownProgram => 'Белгісіз бағдарлама';
	@override String get unknownHub => 'Белгісіз';
	@override String get unknownError => 'Белгісіз қате';
	@override String channelNumber({required Object number}) => '${number}-арна';
	@override String get unknownChannel => 'Белгісіз арна';
	@override String get live => 'ТІКЕЛЕЙ ЭФИР';
	@override String get reloadGuide => 'Бағдарламаны жаңарту';
	@override String get now => 'Қазір';
	@override String get today => 'Бүгін';
	@override String get tomorrow => 'Ертең';
	@override String get midnight => 'Түн ортасы';
	@override String get overnight => 'Түнде';
	@override String get morning => 'Таңертең';
	@override String get daytime => 'Күндіз';
	@override String get evening => 'Кешке';
	@override String get lateNight => 'Түнде';
	@override String get whatsOn => 'Қазір не болып жатыр?';
	@override String get watchChannel => 'Арнаны көру';
	@override String get favorites => 'Таңдаулылар';
	@override String get reorderFavorites => 'Таңдаулыларды қайта реттеу';
	@override String get favoritesLoadFailed => 'Таңдаулыларды жүктеу мүмкін болмады.';
	@override String get favoritesUpdateFailed => 'Таңдаулыларды жаңарту мүмкін болмады.';
	@override String get joinSession => 'Сеансқа қосылу';
	@override String watchFromStart({required Object minutes}) => 'Басынан бастап көру (${minutes} мин бұрын)';
	@override String get watchLive => 'Тікелей эфирді көру';
	@override String get goToLive => 'Тікелей эфирге өту';
	@override String get record => 'Жазу';
	@override String get recordEpisode => 'Бөлімді жазу';
	@override String get recordSeries => 'Сериалды жазу';
	@override String get recordOptions => 'Жазу параметрлері';
	@override String get saveTo => 'Мұнда сақтау';
	@override String get recordings => 'Жазылғандар';
	@override String get scheduledRecordings => 'Жоспарланғандар';
	@override String get recordingRules => 'Жазу ережелері';
	@override String get noScheduledRecordings => 'Жоспарланған жазбалар жоқ';
	@override String get manageRecording => 'Жазбаны басқару';
	@override String get cancelRecording => 'Жазудан бас тарту';
	@override String get cancelRecordingTitle => 'Жазу тоқтатылсын ба?';
	@override String cancelRecordingMessage({required Object title}) => '${title} енді жазылмайды.';
	@override String get deleteRule => 'Ережені өшіру';
	@override String get deleteRuleTitle => 'Жазу ережесі өшірілсін бе?';
	@override String deleteRuleMessage({required Object title}) => '${title} сериалының келесі бөлімдері жазылмайды.';
	@override String get recordingScheduled => 'Жазу жоспарланды';
	@override String get alreadyScheduled => 'Бұл бағдарлама бұрыннан жоспарланған';
	@override String get dvrAdminRequired => 'DVR баптаулары администратор құқығын талап етеді';
	@override String get recordingFailed => 'Жазуды жоспарлау мүмкін болмады';
	@override String get recordingTargetMissing => 'Жазатын кітапхана анықталмады';
	@override String get recordNotAvailable => 'Бұл бағдарламаны жазу мүмкін емес';
	@override String get recordingCancelled => 'Жазу тоқтатылды';
	@override String get recordingRuleDeleted => 'Жазу ережесі өшірілді';
	@override String get processRecordingRules => 'Ережелерді қайта бағалау';
	@override String get recordingInProgress => 'Қазір жазылуда';
	@override String recordingsCount({required Object count}) => '${count} жоспарланған';
	@override String get editRule => 'Ережені өңдеу';
	@override String get editRuleAction => 'Өңдеу';
	@override String get recordingRuleUpdated => 'Жазу ережесі жаңартылды';
	@override String get guideReloadRequested => 'Бағдарламаны жаңарту сұралды';
	@override String get rulesProcessRequested => 'Ережелерді қайта бағалау сұралды';
	@override String get recordShow => 'Шоуды жазу';
}

// Path: collections
class _Translations$collections$kk extends Translations$collections$en {
	_Translations$collections$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Топтамалар';
	@override String get collection => 'Топтама';
	@override String get empty => 'Топтама бос';
	@override String get deleteCollection => 'Топтаманы өшіру';
	@override String deleteConfirm({required Object title}) => '"${title}" өшірілсін бе?';
	@override String get deleted => 'Топтама өшірілді';
	@override String get deleteFailed => 'Топтаманы өшіру мүмкін болмады';
	@override String deleteFailedWithError({required Object error}) => 'Топтаманы өшіру қатесі: ${error}';
	@override String get selectCollection => 'Топтаманы таңдау';
	@override String get collectionName => 'Топтама атауы';
	@override String get enterCollectionName => 'Топтама атауын енгізіңіз';
	@override String get addedToCollection => 'Топтамаға қосылды';
	@override String get errorAddingToCollection => 'Топтамаға қосу мүмкін болмады';
	@override String get created => 'Топтама жасалды';
	@override String get removeFromCollection => 'Топтамадан өшіру';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" осы топтамадан өшірілсін бе?';
	@override String get removedFromCollection => 'Топтамадан өшірілді';
	@override String get removeFromCollectionFailed => 'Топтамадан өшіру мүмкін болмады';
	@override String removeFromCollectionError({required Object error}) => 'Өшіру қатесі: ${error}';
	@override String get searchCollections => 'Топтамалардан іздеу...';
}

// Path: playlists
class _Translations$playlists$kk extends Translations$playlists$en {
	_Translations$playlists$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ойнату тізімдері';
	@override String get playlist => 'Ойнату тізімі';
	@override String get noPlaylists => 'Ойнату тізімдері табылмады';
	@override String get create => 'Ойнату тізімін жасау';
	@override String get playlistName => 'Ойнату тізімінің атауы';
	@override String get enterPlaylistName => 'Тізім атауын енгізіңіз';
	@override String get delete => 'Ойнату тізімін өшіру';
	@override String get removeItem => 'Тізімнен өшіру';
	@override String get smartPlaylist => 'Ақылды ойнату тізімі';
	@override String itemCount({required Object count}) => '${count} элемент';
	@override String get oneItem => '1 элемент';
	@override String get emptyPlaylist => 'Бұл ойнату тізімі бос';
	@override String get deleteConfirm => 'Ойнату тізімі өшірілсін бе?';
	@override String deleteMessage({required Object name}) => '"${name}" өшірілсін бе?';
	@override String get created => 'Ойнату тізімі жасалды';
	@override String get deleted => 'Ойнату тізімі өшірілді';
	@override String get itemAdded => 'Тізімге қосылды';
	@override String get itemRemoved => 'Тізімнен өшірілді';
	@override String get selectPlaylist => 'Тізімді таңдау';
	@override String get searchPlaylists => 'Ойнату тізімдерінен іздеу...';
	@override String get errorCreating => 'Тізімді жасау мүмкін болмады';
	@override String get errorDeleting => 'Тізімді өшіру мүмкін болмады';
	@override String get errorLoading => 'Тізімдерді жүктеу мүмкін болмады';
	@override String get errorAdding => 'Тізімге қосу мүмкін болмады';
	@override String get errorReordering => 'Қайта реттеу мүмкін болмады';
	@override String get errorRemoving => 'Тізімнен өшіру мүмкін болмады';
}

// Path: music
class _Translations$music$kk extends Translations$music$en {
	_Translations$music$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Альбомға өту';
	@override String get goToArtist => 'Орындаушыға өту';
	@override String get instantMix => 'Сәттік микс';
	@override String get playNext => 'Келесіні ойнату';
	@override String get addToQueue => 'Кезекке қосу';
	@override String discNumber({required Object n}) => '${n}-диск';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('kk'))(n,
		one: '${n} ән',
		other: '${n} ән',
	);
	@override String get nowPlaying => 'Қазір ойнатылуда';
	@override String playingFrom({required Object title}) => '${title} дереккөзінен';
	@override String get queue => 'Кезек';
	@override String get clearQueue => 'Кезекті тазалау';
	@override String get lyrics => 'Ән мәтіні';
	@override String get noLyrics => 'Ән мәтіні жоқ';
	@override String get sleepTimer => 'Ұйқы таймері';
	@override String get sleepTimerEndOfTrack => 'Әннің соңы';
	@override String sleepTimerMinutes({required Object n}) => '${n} минут';
	@override String get stopPlayback => 'Ойнатуды тоқтату';
	@override String get previousTrack => 'Алдыңғы ән';
	@override String get nextTrack => 'Келесі ән';
	@override String get repeat => 'Қайталау';
	@override String get repeatAll => 'Барлығын қайталау';
	@override String get repeatOne => 'Біреуін қайталау';
}

// Path: watchTogether
class _Translations$watchTogether$kk extends Translations$watchTogether$en {
	_Translations$watchTogether$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Бірге көру';
	@override String get description => 'Достарыңызбен бірге көріңіз';
	@override String get createSession => 'Сеанс жасау';
	@override String get creating => 'Жасалуда...';
	@override String get joinSession => 'Сеансқа қосылу';
	@override String get joining => 'Қосылуда...';
	@override String get controlMode => 'Басқару режимі';
	@override String get controlModeQuestion => 'Ойнатуды кім басқара алады?';
	@override String get hostOnly => 'Тек ұйымдастырушы';
	@override String get anyone => 'Кез келген адам';
	@override String get hostingSession => 'Сеанс ұйымдастырылуда';
	@override String get inSession => 'Сеанста';
	@override String get sessionCode => 'Сеанс коды';
	@override String get openSessionControls => 'Басқару элементтерін ашу';
	@override String get copySessionCode => 'Сеанс кодын көшіру';
	@override String get hostControlsPlayback => 'Ойнатуды ұйымдастырушы басқарады';
	@override String get anyoneCanControl => 'Ойнатуды кез келген адам басқара алады';
	@override String get hostControls => 'Ұйымдастырушы басқарады';
	@override String get anyoneControls => 'Барлығы басқарады';
	@override String get participants => 'Қатысушылар';
	@override String get host => 'Ұйымдастырушы';
	@override String get hostBadge => 'ҰЙЫМДАСТЫРУШЫ';
	@override String get youAreHost => 'Сіз ұйымдастырушысыз';
	@override String get watchingWithOthers => 'Басқалармен бірге көрілуде';
	@override String get endSession => 'Сеансты аяқтау';
	@override String get leaveSession => 'Сеанстан шығу';
	@override String get endSessionQuestion => 'Сеанс аяқталсын ба?';
	@override String get leaveSessionQuestion => 'Сеанстан шығасыз ба?';
	@override String get endSessionConfirm => 'Бұл барлық қатысушылар үшін сеансты аяқтайды.';
	@override String get leaveSessionConfirm => 'Сіз сеанстан ажыратыласыз.';
	@override String get endSessionConfirmOverlay => 'Бұл барлығы үшін көру сеансын аяқтайды.';
	@override String get leaveSessionConfirmOverlay => 'Көру сеансынан ажыратыласыз.';
	@override String get end => 'Аяқтау';
	@override String get leave => 'Шығу';
	@override String get syncing => 'Синхрондалуда...';
	@override String get joinWatchSession => 'Көру сеансына қосылу';
	@override String get enterCodeHint => '5 таңбалы кодты енгізіңіз';
	@override String get pasteFromClipboard => 'Алмасу буферінен қою';
	@override String get pleaseEnterCode => 'Сеанс кодын енгізіңіз';
	@override String get codeMustBe5Chars => 'Сеанс коды 5 таңбадан тұруы керек';
	@override String get joinInstructions => 'Ұйымдастырушының сеанс кодын енгізіңіз.';
	@override String get failedToCreate => 'Сеансты жасау мүмкін болмады';
	@override String get failedToJoin => 'Сеансқа қосылу мүмкін болмады';
	@override String get sessionCodeCopied => 'Сеанс коды көшірілді';
	@override String get relayUnreachable => 'Реле сервері қолжетімсіз.';
	@override String get reconnectingToHost => 'Ұйымдастырушыға қайта қосылуда...';
	@override String get currentPlayback => 'Ағымдағы ойнату';
	@override String get joinCurrentPlayback => 'Ағымдағы ойнатуға қосылу';
	@override String get joinCurrentPlaybackDescription => 'Ұйымдастырушы көріп жатқан жерге өту';
	@override String get failedToOpenCurrentPlayback => 'Ағымдағы ойнатуды ашу мүмкін болмады';
	@override String participantJoined({required Object name}) => '${name} қосылды';
	@override String participantLeft({required Object name}) => '${name} шықты';
	@override String participantPaused({required Object name}) => '${name} кідіртті';
	@override String participantResumed({required Object name}) => '${name} жалғастырды';
	@override String participantSeeked({required Object name}) => '${name} уақытты өзгертті';
	@override String participantBuffering({required Object name}) => '${name} буферлеуде';
	@override String participantNeedsUpdate({required Object name}) => '${name} ескі нұсқада';
	@override String resumingWithout({required Object name}) => '${name} ескерусіз жалғастырылуда';
	@override String get waitingForParticipants => 'Басқалардың жүктеуін күтуде...';
	@override String waitingForName({required Object name}) => '${name} күтілуде...';
	@override String get recentRooms => 'Соңғы бөлмелер';
	@override String get renameRoom => 'Бөлме атын өзгерткіңіз келе ме?';
	@override String get removeRoom => 'Өшіру';
	@override String get guestSwitchUnavailable => 'Ауысу мүмкін болмады';
	@override String get guestSwitchFailed => 'Ауысу мүмкін болмады — мазмұн табылмады';
}

// Path: downloads
class _Translations$downloads$kk extends Translations$downloads$en {
	_Translations$downloads$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Жүктеулер';
	@override String get manage => 'Басқару';
	@override String get tvShows => 'TV Шоулар';
	@override String get movies => 'Фильмдер';
	@override String get music => 'Музыка';
	@override String tracksQueued({required Object count}) => '${count} ән жүктеу кезегіне қосылды';
	@override String get noDownloads => 'Әлі де жүктеулер жоқ';
	@override String get noDownloadsDescription => 'Жүктелген файлдар офлайн көру үшін мұнда көрінеді';
	@override String get downloadNow => 'Жүктеу';
	@override String get deleteDownload => 'Жүктеуді өшіру';
	@override String get retryDownload => 'Жүктеуді қайталау';
	@override String get downloadQueued => 'Жүктеу кезекке қойылды';
	@override String get downloadResumed => 'Жүктеу жалғастырылды';
	@override String get serverErrorBitrate => 'Сервер қатесі: файл жылдамдық шегінен асуы мүмкін';
	@override String get storageFull => 'Жады толы болғандықтан жүктеу тоқтатылды.';
	@override String episodesQueued({required Object count}) => '${count} бөлім жүктеу кезегіне қосылды';
	@override String get downloadDeleted => 'Жүктеу өшірілді';
	@override String deleteConfirm({required Object title}) => '"${title}" осы құрылғыдан өшірілсін бе?';
	@override String get cancelledDownloadTitle => 'Тоқтатылған жүктеу';
	@override String get cancelledDownloadMessage => 'Бұл жүктеу тоқтатылды.';
	@override String get allEpisodesAlreadyDownloaded => 'Барлық бөлімдер бұрыннан жүктелген';
	@override String get resumeDownload => 'Жүктеуді жалғастыру';
	@override String get cancelledDownload => 'Тоқтатылған жүктеу';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} синхрондалуда)';
	@override String downloadedFileClickToComplete({required Object file}) => 'Жүктелді ${file} - Аяқтау үшін түртіңіз';
	@override String get partialDownloadClickToComplete => 'Жартылай жүктелді - Аяқтау үшін түртіңіз';
	@override String get deleting => 'Өшірілуде...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} өшірілуде... (${current} / ${total})';
	@override String get queuedTooltip => 'Кезекте';
	@override String queuedFilesTooltip({required Object files}) => 'Кезектегі файлдар: ${files}';
	@override String get downloadingTooltip => 'Жүктелуде...';
	@override String downloadingFilesTooltip({required Object files}) => 'Жүктеліп жатқан файлдар: ${files}';
	@override String get noDownloadsTree => 'Жүктеулер жоқ';
	@override String get pauseAll => 'Барлығын кідірту';
	@override String get resumeAll => 'Барлығын жалғастыру';
	@override String get deleteAll => 'Барлығын өшіру';
	@override String get selectVersion => 'Нұсқаны таңдау';
	@override String get allEpisodes => 'Барлық бөлімдер';
	@override String get unwatchedOnly => 'Тек көрілмегендер';
	@override String nextNUnwatched({required Object count}) => 'Келесі ${count} көрілмеген';
	@override String get customAmount => 'Арнайы мөлшер...';
	@override String get includeSpecials => 'Арнайы бөлімдерді қосу';
	@override String get howManyEpisodes => 'Қанша бөлім?';
	@override String get invalidEpisodeCount => 'Дұрыс бөлім санын енгізіңіз.';
	@override String get keepSynced => 'Синхрондалған күйде ұстау';
	@override String get downloadOnce => 'Бір рет жүктеу';
	@override String keepNUnwatched({required Object count}) => '${count} көрілмеген бөлімді сақтау';
	@override String get editSyncRule => 'Синхрондау ережесін өңдеу';
	@override String get removeSyncRule => 'Синхрондау ережесін өшіру';
	@override String removeSyncRuleConfirm({required Object title}) => '"${title}" синхрондауы тоқтатылсын ба? Жүктелген бөлімдер сақталады.';
	@override String removeListSyncRuleConfirm({required Object title}) => '"${title}" синхрондауы тоқтатылсын ба?';
	@override String get deleteSyncRuleDownloads => 'Байланысты жүктеулерді де жою';
	@override String get deleteSyncRuleDownloadsDescription => 'Басқа синхрондау ережесі немесе профилі пайдаланатын жүктеулер сақталады.';
	@override String syncRuleCreated({required Object count}) => 'Синхрондау ережесі жасалды — ${count} көрілмеген бөлім сақталады';
	@override String get syncRuleUpdated => 'Синхрондау ережесі жаңартылды';
	@override String get syncRuleRemoved => 'Синхрондау ережесі өшірілді';
	@override String get syncRuleAndDownloadsRemoved => 'Синхрондау ережесі және байланысты жүктеулер өшірілді';
	@override String get syncRuleCleanupBusy => 'Синхрондау ережелері қазір жаңартылуда. Сәлден соң қайталап көріңіз.';
	@override String get syncRuleCleanupUnavailable => 'Байланысты жүктеулерді қауіпсіз анықтау мүмкін болмады. Серверге қайта қосылып көріңіз немесе ережені жүктеулерді жоймай өшіріңіз.';
	@override String syncedNewEpisodes({required Object title, required Object count}) => '${title} үшін ${count} жаңа бөлім синхрондалды';
	@override String get activeSyncRules => 'Белсенді синхрондау ережелері';
	@override String get noSyncRules => 'Синхрондау ережелері жоқ';
	@override String get manageSyncRule => 'Синхрондауды басқару';
	@override String get editEpisodeCount => 'Бөлімдер саны';
	@override String get editSyncFilter => 'Синхрондау фильтрі';
	@override String get syncAllItems => 'Барлық элементтер синхрондалады';
	@override String get syncUnwatchedItems => 'Көрілмеген элементтер синхрондалады';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Сервер: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Қолжетімді';
	@override String get syncRuleOffline => 'Офлайн';
	@override String get syncRuleSignInRequired => 'Кіру қажет';
	@override String get syncRuleNotAvailableForProfile => 'Ағымдағы профиль үшін қолжетімсіз';
	@override String get syncRuleUnknownServer => 'Белгісіз сервер';
	@override String get syncRuleListCreated => 'Синхрондау ережесі жасалды';
	@override late final _Translations$downloads$backgroundWarning$kk backgroundWarning = _Translations$downloads$backgroundWarning$kk._(_root);
}

// Path: shaders
class _Translations$shaders$kk extends Translations$shaders$en {
	_Translations$shaders$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Шейдерлер';
	@override String get noShaderDescription => 'Видеоны жақсарту өшірілген';
	@override String get nvscalerDescription => 'Анығырақ видео үшін NVIDIA масштабы';
	@override String get artcnnVariantNeutral => 'Нейтралды';
	@override String get artcnnVariantDenoise => 'Шуды азайту';
	@override String get artcnnVariantDenoiseSharpen => 'Шуды азайту + Анықтық';
	@override String get qualityFast => 'Жылдам';
	@override String get qualityHQ => 'Жоғары сапа';
	@override String get mode => 'Режим';
	@override String get importShader => 'Шейдерді импорттау';
	@override String get customShaderDescription => 'Арнайы GLSL шейдері';
	@override String get shaderImported => 'Шейдер импортталды';
	@override String get shaderImportFailed => 'Шейдерді импорттау мүмкін болмады';
	@override String get deleteShader => 'Шейдерді өшіру';
	@override String deleteShaderConfirm({required Object name}) => '"${name}" өшірілсін бе?';
}

// Path: companionRemote
class _Translations$companionRemote$kk extends Translations$companionRemote$en {
	_Translations$companionRemote$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Көмекші пульт';
	@override String connectedTo({required Object name}) => '${name} құрылғысына қосылды';
	@override String get unknownDevice => 'Белгісіз құрылғы';
	@override late final _Translations$companionRemote$session$kk session = _Translations$companionRemote$session$kk._(_root);
	@override late final _Translations$companionRemote$pairing$kk pairing = _Translations$companionRemote$pairing$kk._(_root);
	@override late final _Translations$companionRemote$remote$kk remote = _Translations$companionRemote$remote$kk._(_root);
	@override late final _Translations$companionRemote$errors$kk errors = _Translations$companionRemote$errors$kk._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$kk extends Translations$videoSettings$en {
	_Translations$videoSettings$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Ойнату жылдамдығы';
	@override String get normalSpeed => 'Қалыпты';
	@override String sleepTimerActive({required Object duration}) => 'Белсенді (${duration})';
	@override String get zoom => 'Масштаб';
	@override String get sleepTimer => 'Ұйқы таймері';
	@override String get audioSync => 'Аудио синхрондау';
	@override String get subtitleSync => 'Субтитр синхрондау';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Аудио шығысы';
	@override String get performanceOverlay => 'Өнімділік панелі';
	@override String get audioPassthrough => 'Дыбысты тікелей өткізу';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Көлемді дыбыс';
	@override String get audioOutputSpatial => 'Кеңістіктік дыбыс';
	@override String get audioOutputStereo => 'Стерео';
	@override String get audioNormalization => 'Дыбыс деңгейін нормалау';
	@override String get audioDownmix => 'Стереоға түрлендіру';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$kk extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get color => 'Түс';
	@override String get performance => 'Өнімділік';
	@override String get buffer => 'Буфер';
	@override String get app => 'Қолданба';
	@override String get decoder => 'Декодер';
	@override String get rawDecoder => 'Өңделмеген декодер';
	@override String get tunneling => 'Туннельдеу';
	@override String get aspect => 'Қатынас';
	@override String get rotation => 'Бұрылыс';
	@override String get dvSource => 'DV дереккөзі';
	@override String get dvPath => 'DV жолы';
	@override String get p7Conversion => 'P7 түрлендіруі';
	@override String get sampleRate => 'Дискретизация жиілігі';
	@override String get pixelFormat => 'Пиксель форматы';
	@override String get hwFormat => 'HW форматы';
	@override String get matrix => 'Матрица';
	@override String get primaries => 'Негізгі түстер';
	@override String get transfer => 'Беріліс';
	@override String get renderFps => 'Рендер FPS';
	@override String get displayFps => 'Дисплей FPS';
	@override String get avSync => 'A/V синхрондау';
	@override String get dropped => 'Өткізілген кадрлар';
	@override String get dvRpus => 'DV RPU-лар';
	@override String get dvRpuAverage => 'DV RPU Орт.';
	@override String get dvSampleAverage => 'DV Үлгі Орт.';
	@override String get maxLuma => 'Макс Luma';
	@override String get minLuma => 'Мин Luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Пайдаланылған кэш';
	@override String get cacheLimit => 'Кэш шегі';
	@override String get speed => 'Жылдамдық';
	@override String get player => 'Ойнатқыш';
	@override String get memory => 'Жады';
	@override String get uiFps => 'Интерфейс (UI) FPS';
}

// Path: externalPlayer
class _Translations$externalPlayer$kk extends Translations$externalPlayer$en {
	_Translations$externalPlayer$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сыртқы ойнатқыш';
	@override String get useExternalPlayer => 'Сыртқы ойнатқышты пайдалану';
	@override String get useExternalPlayerDescription => 'Видеоларды басқа қолданбада ашу';
	@override String get selectPlayer => 'Ойнатқышты таңдау';
	@override String get customPlayers => 'Арнайы ойнатқыштар';
	@override String get systemDefault => 'Жүйелік әдепкі';
	@override String get addCustomPlayer => 'Арнайы ойнатқыш қосу';
	@override String get playerName => 'Ойнатқыш атауы';
	@override String get playerNameHint => 'Менің ойнатқышым';
	@override String get playerCommand => 'Пәрмен';
	@override String get playerPackage => 'Пакет атауы';
	@override String get playerUrlScheme => 'URL схемасы';
	@override String get off => 'Өшірулі';
	@override String get launchFailed => 'Сыртқы ойнатқышты іске қосу мүмкін болмады';
	@override String appNotInstalled({required Object name}) => '${name} орнатылмаған';
	@override String get playInExternalPlayer => 'Сыртқы ойнатқышта ойнату';
}

// Path: metadataEdit
class _Translations$metadataEdit$kk extends Translations$metadataEdit$en {
	_Translations$metadataEdit$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Өңдеу...';
	@override String get screenTitle => 'Метадеректерді өңдеу';
	@override String get basicInfo => 'Негізгі ақпарат';
	@override String get artwork => 'Суреттер/Постерлер';
	@override String get advancedSettings => 'Кеңейтілген баптаулар';
	@override String get title => 'Атауы';
	@override String get sortTitle => 'Сұрыптау атауы';
	@override String get originalTitle => 'Түпнұсқа атауы';
	@override String get releaseDate => 'Шыққан күні';
	@override String get contentRating => 'Мазмұн рейтингі';
	@override String get studio => 'Студия';
	@override String get tagline => 'Ұран/Слоган';
	@override String get summary => 'Сипаттамасы/Күйі';
	@override String get poster => 'Постер';
	@override String get background => 'Фон';
	@override String get logo => 'Логотип';
	@override String get squareArt => 'Шаршы сурет';
	@override String get selectPoster => 'Постерді таңдау';
	@override String get selectBackground => 'Фонды таңдау';
	@override String get selectLogo => 'Логотипті таңдау';
	@override String get selectSquareArt => 'Шаршы суретті таңдау';
	@override String get fromUrl => 'URL арқылы';
	@override String get uploadFile => 'Файлды жүктеу';
	@override String get enterImageUrl => 'Сурет URL-ін енгізіңіз';
	@override String get imageUrl => 'Сурет URL-і';
	@override String get metadataUpdated => 'Метадеректер жаңартылды';
	@override String get metadataUpdateFailed => 'Метадеректерді жаңарту мүмкін болмады';
	@override String get artworkUpdated => 'Суреттер жаңартылды';
	@override String get artworkUpdateFailed => 'Суреттерді жаңарту мүмкін болмады';
	@override String get noArtworkAvailable => 'Сурет қолжетімсіз';
	@override String artworkOption({required Object index}) => 'Сурет опциясы ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Сурет опциясы ${index}, таңдалды';
	@override String get notSet => 'Орнатылмаған';
	@override String get libraryDefault => 'Кітапхана әдепкісі';
	@override String get accountDefault => 'Тіркелгі әдепкісі';
	@override String get seriesDefault => 'Сериал әдепкісі';
	@override String get episodeSorting => 'Бөлімдерді сұрыптау';
	@override String get oldestFirst => 'Басында ескілері';
	@override String get newestFirst => 'Басында жаңалары';
	@override String get keep => 'Сақтау';
	@override String get allEpisodes => 'Барлық бөлімдер';
	@override String latestEpisodes({required Object count}) => 'Соңғы ${count} бөлім';
	@override String get latestEpisode => 'Соңғы бөлім';
	@override String episodesAddedPastDays({required Object count}) => 'Соңғы ${count} күнде қосылған бөлімдер';
	@override String get deleteAfterPlaying => 'Ойнатқаннан кейін өшіру';
	@override String get never => 'Ешқашан';
	@override String get afterADay => 'Бір күннен кейін';
	@override String get afterAWeek => 'Бір аптадан кейін';
	@override String get afterAMonth => 'Бір айдан кейін';
	@override String get onNextRefresh => 'Келесі жаңартуда';
	@override String get seasons => 'Маусымдар';
	@override String get show => 'Көрсету';
	@override String get hide => 'Жасыру';
	@override String get episodeOrdering => 'Бөлімдер реті';
	@override String get tmdbAiring => 'The Movie Database (Эфир)';
	@override String get tvdbAiring => 'TheTVDB (Эфир)';
	@override String get tvdbAbsolute => 'TheTVDB (Абсолютті)';
	@override String get metadataLanguage => 'Метадеректер тілі';
	@override String get useOriginalTitle => 'Түпнұсқа атауын пайдалану';
	@override String get preferredAudioLanguage => 'Қалаулы аудио тілі';
	@override String get preferredSubtitleLanguage => 'Қалаулы субтитр тілі';
	@override String get subtitleMode => 'Автоматты субтитр таңдау режимі';
	@override String get manuallySelected => 'Қолмен таңдалған';
	@override String get shownWithForeignAudio => 'Шетелдік аудио кезінде көрсетіледі';
	@override String get alwaysEnabled => 'Әрдайым қосулы';
	@override String get tags => 'Тегтер';
	@override String get addTag => 'Тег қосу';
	@override String get genre => 'Жанр';
	@override String get director => 'Режиссер';
	@override String get writer => 'Сценарист';
	@override String get producer => 'Продюсер';
	@override String get country => 'Ел';
	@override String get collection => 'Топтама';
	@override String get label => 'Белгі';
	@override String get style => 'Стиль';
	@override String get mood => 'Көңіл-күй';
}

// Path: matchScreen
class _Translations$matchScreen$kk extends Translations$matchScreen$en {
	_Translations$matchScreen$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get match => 'Сәйкестендіру...';
	@override String get fixMatch => 'Сәйкестікті түзету...';
	@override String get unmatch => 'Сәйкестікті жою';
	@override String get unmatchConfirm => 'Бұл сәйкестік жойылсын ба?';
	@override String get unmatchSuccess => 'Сәйкестік жойылды';
	@override String get unmatchFailed => 'Сәйкестікті жою мүмкін болмады';
	@override String get matchApplied => 'Сәйкестік қолданылды';
	@override String get matchFailed => 'Сәйкестікті қолдану мүмкін болмады';
	@override String get titleHint => 'Атауы';
	@override String get yearHint => 'Жыл';
	@override String get search => 'Іздеу';
	@override String get noMatchesFound => 'Сәйкестіктер табылмады';
}

// Path: serverTasks
class _Translations$serverTasks$kk extends Translations$serverTasks$en {
	_Translations$serverTasks$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сервер тапсырмалары';
	@override String get failedToLoad => 'Тапсырмаларды жүктеу мүмкін болмады';
	@override String get noTasks => 'Орындалып жатқан тапсырмалар жоқ';
}

// Path: trakt
class _Translations$trakt$kk extends Translations$trakt$en {
	_Translations$trakt$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Қосылды';
	@override String connectedAs({required Object username}) => '@${username} ретінде қосылды';
	@override String get disconnectConfirm => 'Trakt ажыратылсын ба?';
	@override String get disconnectConfirmBody => 'Plezy Trakt-қа деректер жіберуді тоқтатады.';
	@override String get scrobble => 'Нақты уақытта бақылау';
	@override String get scrobbleDescription => 'Ойнату кезінде Trakt-қа деректер жіберу.';
	@override String get watchedSync => 'Көру мәртебесін синхрондау';
	@override String get watchedSyncDescription => 'Plezy-де белгіленгенде Trakt-та да белгіленеді.';
}

// Path: seerr
class _Translations$seerr$kk extends Translations$seerr$en {
	_Translations$seerr$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerr қосу';
	@override String get serverUrl => 'Сервер URL-і';
	@override String get serverUrlHelper => 'Seerr мекенжайыңыз';
	@override String get checkServer => 'Жалғастыру';
	@override String get signInWithJellyfin => 'Jellyfin арқылы кіру';
	@override String get signInWithEmby => 'Emby арқылы кіру';
	@override String get signInWithLocal => 'Жергілікті тіркелгіні пайдалану';
	@override String get email => 'Электрондық пошта';
	@override String get noSignInMethods => 'Бұл Seerr қолдау көрсетілетін кіру әдісін ұсынбайды.';
	@override String get instance => 'Инстанция';
	@override String get disconnectConfirm => 'Seerr ажыратылсын ба?';
	@override String get disconnectConfirmBody => 'Plezy бұл Seerr мекенжайын өшіреді.';
	@override String get request => 'Сұрау салу';
	@override String get request4k => '4K сұрау салу';
	@override String get seasons => 'Маусымдар';
	@override String get allSeasons => 'Барлық маусымдар';
	@override String get advancedOptions => 'Кеңейтілген';
	@override String get destinationServer => 'Нысаналы сервер';
	@override String get qualityProfile => 'Сапа профилі';
	@override String get rootFolder => 'Түпкі қапшық';
	@override String get languageProfile => 'Тіл профилі';
	@override String get requestSubmitted => 'Сұрау жіберілді';
	@override String requestFailed({required Object error}) => 'Сұрау қатесі: ${error}';
	@override String get requestsLoadFailed => 'Параметрлерді жүктеу мүмкін болмады';
	@override String get nothingToRequest => 'Барлығы бұрыннан бар немесе сұралған.';
	@override String get statusAvailable => 'Қолжетімді';
	@override String get statusPartiallyAvailable => 'Жартылай қолжетімді';
	@override String get statusRequested => 'Сұралды';
	@override String get statusProcessing => 'Өңделуде';
}

// Path: services
class _Translations$services$kk extends Translations$services$en {
	_Translations$services$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Қызметтер';
	@override String get hubSubtitle => 'Көру барысын синхрондаңыз және жаңа мазмұн сұраңыз.';
	@override String get notConnected => 'Қосылмаған';
	@override String connectedAs({required Object username}) => '@${username} ретінде қосылды';
	@override String get scrobble => 'Барысты автоматты бақылау';
	@override String get scrobbleDescription => 'Тізіміңізді автоматты түрде жаңартыңыз.';
	@override String disconnectConfirm({required Object service}) => '${service} ажыратылсын ба?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy ${service} жаңартуды тоқтатады.';
	@override String connectFailed({required Object service}) => '${service} қосылу мүмкін болмады. Қайтадан байқап көріңіз.';
	@override late final _Translations$services$names$kk names = _Translations$services$names$kk._(_root);
	@override late final _Translations$services$deviceCode$kk deviceCode = _Translations$services$deviceCode$kk._(_root);
	@override late final _Translations$services$oauthProxy$kk oauthProxy = _Translations$services$oauthProxy$kk._(_root);
	@override late final _Translations$services$libraryFilter$kk libraryFilter = _Translations$services$libraryFilter$kk._(_root);
}

// Path: addServer
class _Translations$addServer$kk extends Translations$addServer$en {
	_Translations$addServer$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Jellyfin серверін қосу';
	@override String get serverUrls => 'Сервер URL-дері';
	@override String get serverUrlsHelper => 'Үтірмен бөлінген бірнеше URL мекенжайына рұқсат етіледі.';
	@override String get findServer => 'Серверді табу';
	@override String get searchingLocalServers => 'Жергілікті Jellyfin серверлері ізделуде...';
	@override String get localServers => 'Жергілікті Jellyfin серверлері';
	@override String get username => 'Пайдаланушы аты';
	@override String get password => 'Құпия сөз';
	@override String get signIn => 'Кіру';
	@override String get change => 'Өзгерту';
	@override String get required => 'Міндетті';
	@override String couldNotReachServer({required Object error}) => 'Серверге қосылу мүмкін болмады: ${error}';
	@override String signInFailed({required Object error}) => 'Кіру қатесі: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Жылдам қосылу қатесі: ${error}';
	@override String get addPlexTitle => 'Plex арқылы кіру';
	@override String get pinExpired => 'PIN код мерзімі өтті.';
	@override String failedToRegisterAccount({required Object error}) => 'Тіркелгіні тіркеу қатесі: ${error}';
	@override String get enterJellyfinUrlError => 'Jellyfin сервер URL-ін енгізіңіз';
	@override String get addConnectionTitle => 'Қосылым қосу';
	@override String addConnectionTitleScoped({required Object name}) => '${name} профиліне қосу';
	@override String get signInWithPlexCard => 'Plex арқылы кіру';
	@override String get signInWithPlexCardSubtitle => 'Осы құрылғыны авторизациялау.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex тіркелгісін авторизациялау.';
	@override String get connectToJellyfinCard => 'Jellyfin-ге қосылу';
	@override String get connectToJellyfinCardSubtitle => 'Сервер URL-ін, пайдаланушы атын енгізіңіз.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Jellyfin серверіне кіру. ${name} профиліне жалғануда.';
	@override String get borrowFromAnotherProfile => 'Басқа профильден алу';
	@override String get borrowFromAnotherProfileSubtitle => 'Басқа профильдің қосылымын қайта пайдалану.';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$kk extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Ойнату/Кідірту';
	@override String get volumeUp => 'Дыбысты үлкейту';
	@override String get volumeDown => 'Дыбысты азайту';
	@override String seekForward({required Object seconds}) => 'Алға айналдыру (${seconds}сек)';
	@override String seekBackward({required Object seconds}) => 'Артқа айналдыру (${seconds}сек)';
	@override String get fullscreenToggle => 'Толық экранды ауыстыру';
	@override String get muteToggle => 'Дыбысты өшіру/қосу';
	@override String get subtitleToggle => 'Субтитрді қосу/өшіру';
	@override String get audioTrackNext => 'Келесі аудиожол';
	@override String get subtitleTrackNext => 'Келесі субтитр жолы';
	@override String get chapterNext => 'Келесі бөлім';
	@override String get chapterPrevious => 'Алдыңғы бөлім';
	@override String get episodeNext => 'Келесі бөлім';
	@override String get episodePrevious => 'Алдыңғы бөлім';
	@override String get speedIncrease => 'Жылдамдықты арттыру';
	@override String get speedDecrease => 'Жылдамдықты азайту';
	@override String get speedReset => 'Жылдамдықты қалпына келтіру';
	@override String get zoomIn => 'Жақындату';
	@override String get zoomOut => 'Алыстату';
	@override String get zoomReset => 'Масштабты қалпына келтіру';
	@override String get subSeekNext => 'Келесі субтитрге өту';
	@override String get subSeekPrev => 'Алдыңғы субтитрге өту';
	@override String get shaderToggle => 'Шейдерлерді қосу/өшіру';
	@override String get skipMarker => 'Интро/Титрді өткізу';
	@override String get screenshot => 'Экран суретін түсіру';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$kk extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 немесе жаңалауы қажет';
	@override String get iosVersion => 'iOS 15.0 немесе жаңалауы қажет';
	@override String get permissionDisabled => 'PiP режимі өшірілген. Жүйелік баптаулардан қосыңыз.';
	@override String get notSupported => 'Құрылғы PiP режимін қолдамайды';
	@override String get voSwitchFailed => 'PiP үшін видео шығысын ауыстыру мүмкін болмады';
	@override String get failed => 'PiP режимін іске қосу қатесі';
	@override String unknown({required Object error}) => 'Қате орын алды: ${error}';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$kk extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Ұсынылатындар';
	@override String get browse => 'Шолу';
	@override String get collections => 'Топтамалар';
	@override String get playlists => 'Ойнату тізімдері';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$kk extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Топтау';
	@override String get all => 'Барлығы';
	@override String get movies => 'Фильмдер';
	@override String get shows => 'TV Шоулар';
	@override String get seasons => 'Маусымдар';
	@override String get episodes => 'Бөлімдер';
	@override String get artists => 'Орындаушылар';
	@override String get albums => 'Альбомдар';
	@override String get tracks => 'Әндер';
	@override String get folders => 'Қапшықтар';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$kk extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Жанр';
	@override String get year => 'Жыл';
	@override String get contentRating => 'Мазмұн рейтингі';
	@override String get tag => 'Тег';
	@override String get unwatched => 'Көрілмеген';
	@override String get unplayed => 'Ойнатылмаған';
	@override String get favorites => 'Таңдаулылар';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$kk extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Атауы';
	@override String get dateAdded => 'Қосылған күні';
	@override String get releaseDate => 'Шыққан күні';
	@override String get rating => 'Рейтинг';
	@override String get communityRating => 'Қауымдастық рейтингі';
	@override String get criticRating => 'Сыншылар рейтингі';
	@override String get userRating => 'Пайдаланушы рейтингі';
	@override String get datePlayed => 'Ойнатылған күні';
	@override String get playCount => 'Ойнатылу саны';
	@override String get productionYear => 'Шығарылған жылы';
	@override String get runtime => 'Ұзақтығы';
	@override String get officialRating => 'Ресми рейтинг';
	@override String get premiereDate => 'Премьера күні';
	@override String get startDate => 'Басталған күні';
	@override String get airTime => 'Эфир уақыты';
	@override String get studio => 'Студия';
	@override String get random => 'Кездейсоқ';
	@override String get dateShared => 'Бөлісілген күні';
	@override String get latestEpisodeAirDate => 'Соңғы бөлімнің шыққан күні';
	@override String get lastEpisodeDateAdded => 'Соңғы қосылған бөлім күні';
}

// Path: explore.rows
class _Translations$explore$rows$kk extends Translations$explore$rows$en {
	_Translations$explore$rows$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Көру тізімі';
	@override String get recommendedMovies => 'Ұсынылатын фильмдер';
	@override String get recommendedShows => 'Ұсынылатын сериалдар';
	@override String get trendingMovies => 'Трендтегі фильмдер';
	@override String get trendingShows => 'Трендтегі сериалдар';
	@override String get popularMovies => 'Танымал фильмдер';
	@override String get popularShows => 'Танымал сериалдар';
	@override String get trendingAnime => 'Трендтегі аниме';
	@override String get suggestedAnime => 'Ұсынылатын аниме';
	@override String get airingAnime => 'Эфирдегі үздік аниме';
	@override String get popularAnime => 'Ең танымал аниме';
	@override String get trending => 'Трендтер';
	@override String get upcomingMovies => 'Күтілетін фильмдер';
	@override String get upcomingShows => 'Күтілетін сериалдар';
}

// Path: explore.status
class _Translations$explore$status$kk extends Translations$explore$status$en {
	_Translations$explore$status$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Эфирде';
	@override String get ended => 'Аяқталды';
	@override String get canceled => 'Тоқтатылды';
	@override String get upcoming => 'Күтілуде';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$kk extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Қолданбадан шыққанда жүктеулер тоқтайды';
	@override String get bannerDegraded => 'Фондық жүктеулер шектелуі мүмкін';
	@override String get bannerAction => 'Толығырақ';
	@override String get sheetTitle => 'Фондық жүктеулер бұғатталған';
	@override String get sheetTitleDegraded => 'Фондық жүктеулер шектелуі мүмкін';
	@override String get sheetIntro => 'Android Plezy-дің фонда сенімді жүктеуіне кедергі келтіруде.';
	@override String get sheetIntroDegraded => 'Құрылғыңыз Plezy-дің фонда қашан жүктей алатынын шектеп отыр.';
	@override String get reasonBackgroundRestricted => 'Plezy-дің фондық жұмысы шектелген. Батарея немесе фондық пайдалануды "Шектеусіз" етіп қойыңыз.';
	@override String get reasonStandbyRestricted => 'Android Plezy-ді шектеулі күту режиміне ауыстырды. Батарея пайдалануын "Шектеусіз" етіп қойыңыз.';
	@override String get reasonDownloadChannelBlocked => 'Жүктеу хабарландырулары өшірілген, сондықтан жүктеу барысы мен басқару элементтері қолжетімсіз болуы мүмкін.';
	@override String get reasonNotificationsDisabled => 'Хабарландырулар өшірілген. Android 13 және одан жаңа нұсқаларда ұзақ фондық жүктеулер үшін олар қажет.';
	@override String get reasonDataSaver => 'Трафикті үнемдеу қосулы, бұл мобильді деректер арқылы фондық жүктеулерді бұғаттайды. Wi-Fi арқылы жүктеулер жұмыс істеуі тиіс.';
	@override String get reasonOemUnknown => 'Plezy фонда тұрғанда жүктеулер бірнеше рет тоқтады. Plezy-дің батарея немесе фондық пайдалану баптауларын тексеріңіз.';
	@override String get openSettings => 'Баптауларды ашу';
	@override String get stillNotWorking => 'Құрылғыға арналған көмек';
	@override String get stillNotWorkingDescription => 'Құрылғыңызға арналған қадамдарды қараңыз немесе мәселе жалғасса Баптаулар › Журналдарды көру бөлімінен журнал жіберіңіз.';
	@override String get dialogTitle => 'Жүктеулер аяқталмауы мүмкін';
	@override String get dialogDownloadAnyway => 'Сонда да жүктеу';
	@override String get dialogFixFirst => 'Алдымен осыны түзету';
	@override String get statusTile => 'Фондық жүктеулер';
	@override String get statusOk => 'Фонда жұмыс істеуге рұқсат етілген';
	@override String get statusBlocked => 'Жүйе баптаулары бұғаттаған';
	@override String get statusDegraded => 'Жүйе баптаулары шектеген';
	@override String get statusUnknown => 'Әлі тексерілмеген';
	@override String get settingsUnavailable => 'Бұл құрылғыда жүйе баптаулары ашылмады';
	@override String get linkUnavailable => 'Бұл құрылғыда dontkillmyapp.com ашылмады';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$kk extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Пульт сервері іске қосылуда...';
	@override String get hostAddress => 'Хост мекенжайы';
	@override String get connected => 'Қосылды';
	@override String get serverRunning => 'Сервер белсенді';
	@override String get serverStopped => 'Сервер тоқтатылды';
	@override String get serverRunningDescription => 'Желідегі мобильді құрылғылар қосыла алады';
	@override String get serverStoppedDescription => 'Қосылуға рұқсат беру үшін серверді іске қосыңыз';
	@override String get usePhoneToControl => 'Осы қолданбаны басқару үшін телефоныңызды пайдаланыңыз';
	@override String get startServer => 'Серверді іске қосу';
	@override String get stopServer => 'Серверді тоқтату';
	@override String get minimize => 'Жию';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$kk extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Бірдей Plex тіркелгісіндегі Plezy құрылғылары мұнда көрінеді';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Қосылуда...';
	@override String get searchingForDevices => 'Құрылғылар ізделуде...';
	@override String get noDevicesFound => 'Желіде құрылғылар табылмады';
	@override String get noDevicesHint => 'ПК-де Plezy-ді ашып, бір Wi-Fi-ға қосылыңыз';
	@override String get availableDevices => 'Қолжетімді құрылғылар';
	@override String get manualConnection => 'Қолмен қосылу';
	@override String get cryptoInitFailed => 'Қауіпсіз қосылым қатесі. Алдымен Plex-ке кіріңіз.';
	@override String get validationHostRequired => 'Хост мекенжайын енгізіңіз';
	@override String get validationHostFormat => 'Формат IP:порт түрінде болуы керек';
	@override String get connectionTimedOut => 'Қосылу уақыты өтті.';
	@override String get sessionNotFound => 'Құрылғы табылмады.';
	@override String get authFailed => 'Аутентификация қатесі.';
	@override String failedToConnect({required Object error}) => 'Қосылу мүмкін болмады: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$kk extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Пульт сеансынан ажырайсыз ба?';
	@override String get reconnecting => 'Қайта қосылуда...';
	@override String attemptOf({required Object current}) => 'Әрекет ${current} / 5';
	@override String get retryNow => 'Қазір қайталау';
	@override String get tabRemote => 'Пульт';
	@override String get tabPlay => 'Ойнату';
	@override String get tabMore => 'Тағы';
	@override String get menu => 'Мәзір';
	@override String get tabNavigation => 'Навигация';
	@override String get tabDiscover => 'Шолу';
	@override String get tabLibraries => 'Кітапханалар';
	@override String get tabSearch => 'Іздеу';
	@override String get tabDownloads => 'Жүктеулер';
	@override String get tabSettings => 'Баптаулар';
	@override String get previous => 'Алдыңғы';
	@override String get playPause => 'Ойнату/Кідірту';
	@override String get next => 'Келесі';
	@override String get seekBack => 'Артқа айналдыру';
	@override String get stop => 'Тоқтату';
	@override String get seekForward => 'Алға айналдыру';
	@override String get volume => 'Дыбыс';
	@override String get volumeDown => 'Азайту';
	@override String get volumeUp => 'Көбейту';
	@override String get fullscreen => 'Толық экран';
	@override String get subtitles => 'Субтитрлер';
	@override String get audio => 'Дыбыс';
	@override String get searchHint => 'ПК-де іздеу...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$kk extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Желілік интерфейс табылмады';
	@override String get authenticationFailed => 'Аутентификация қатесі';
	@override String serverStartFailed({required Object error}) => 'Серверді іске қосу қатесі: ${error}';
	@override String commandFailed({required Object error}) => 'Пәрменді жіберу қатесі: ${error}';
	@override String get joinTimedOut => 'Қосылу уақыты өтті';
	@override String get failedToConnectAnyAddress => 'Ешбір мекенжайға қосылу мүмкін болмады';
	@override String connectionLostAfterAttempts({required Object attempts}) => '${attempts} әрекеттен кейін байланыс үзілді';
	@override String get connectionLost => 'Байланыс үзілді';
}

// Path: services.names
class _Translations$services$names$kk extends Translations$services$names$en {
	_Translations$services$names$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$kk extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy-ді ${service} қызметінде белсендіру';
	@override String body({required Object url}) => '${url} мекенжайына өтіп, осы кодты енгізіңіз:';
	@override String openToActivate({required Object service}) => 'Белсендіру үшін ${service} ашу';
	@override String get copyCode => 'Белсендіру кодын көшіру';
	@override String get waitingForAuthorization => 'Авторизация күтілуде…';
	@override String get codeCopied => 'Код көшірілді';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$kk extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => '${service} қызметіне кіру';
	@override String get body => 'Осы QR кодты сканерлеңіз немесе URL-ді ашыңыз.';
	@override String openToSignIn({required Object service}) => 'Кіру үшін ${service} ашу';
	@override String get copyUrl => 'Кіру URL-ін көшіру';
	@override String get urlCopied => 'URL көшірілді';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$kk extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Кітапхана фильтрі';
	@override String get subtitleAllSyncing => 'Барлық кітапханалар синхрондалуда';
	@override String get subtitleNoneSyncing => 'Ештеңе синхрондалмайды';
	@override String subtitleBlocked({required Object count}) => '${count} бұғатталды';
	@override String subtitleAllowed({required Object count}) => '${count} рұқсат етілді';
	@override String get mode => 'Фильтр режимі';
	@override String get modeBlacklist => 'Қара тізім';
	@override String get modeWhitelist => 'Ақ тізім';
	@override String get modeHintBlacklist => 'Төменде таңдалғандардан басқа барлық кітапханаларды синхрондау.';
	@override String get modeHintWhitelist => 'Тек төменде таңдалған кітапханаларды синхрондау.';
	@override String get libraries => 'Кітапханалар';
	@override String get noLibraries => 'Кітапханалар жоқ';
}

/// The flat map containing all translations for locale <kk>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsKk {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Plex арқылы кіру',
			'auth.showQRCode' => 'QR кодты көрсету',
			'auth.authenticate' => 'Растау',
			'auth.authenticationTimeout' => 'Растау уақыты өтті. Қайтадан байқап көріңіз.',
			'auth.scanQRToSignIn' => 'Кіру үшін осы QR кодты сканерлеңіз',
			'auth.waitingForAuth' => 'Растау күтілуде...\nБраузеріңізден кіріңіз.',
			'auth.useBrowser' => 'Браузерді пайдалану',
			'auth.or' => 'немесе',
			'auth.connectToJellyfin' => 'Jellyfin-ге қосылу',
			'auth.useQuickConnect' => 'Жылдам қосылуды пайдалану',
			'auth.quickConnectInstructions' => 'Jellyfin-де Жылдам қосылуды ашып, осы кодты енгізіңіз.',
			'auth.quickConnectWaiting' => 'Растау күтілуде…',
			'auth.quickConnectCancel' => 'Бас тарту',
			'auth.quickConnectExpired' => 'Жылдам қосылу мерзімі өтті. Қайтадан байқап көріңіз.',
			'auth.localDataRecoveryRequired' => 'Plezy жергілікті кіру мәліметтерін қалпына келтіре алмады. Қайтадан кіріңіз.',
			'common.cancel' => 'Бас тарту',
			'common.save' => 'Сақтау',
			'common.close' => 'Жабу',
			'common.clear' => 'Тазалау',
			'common.reset' => 'Қалпына келтіру',
			'common.later' => 'Кейінірек',
			'common.submit' => 'Жіберу',
			'common.confirm' => 'Растау',
			'common.retry' => 'Қайталау',
			'common.logout' => 'Шығу',
			'common.unknown' => 'Белгісіз',
			'common.refresh' => 'Жаңарту',
			'common.yes' => 'Иә',
			'common.no' => 'Жоқ',
			'common.delete' => 'Өшіру',
			'common.edit' => 'Өңдеу',
			'common.shuffle' => 'Араластыру',
			'common.addTo' => 'Қосу...',
			'common.createNew' => 'Жаңасын жасау',
			'common.connect' => 'Қосылу',
			'common.disconnect' => 'Ажырату',
			'common.play' => 'Ойнату',
			'common.pause' => 'Кідірту',
			'common.resume' => 'Жалғастыру',
			'common.error' => 'Қате',
			'common.search' => 'Іздеу',
			'common.home' => 'Басты бет',
			'common.back' => 'Артқа',
			'common.settings' => 'Баптаулар',
			'common.mute' => 'Дыбысты өшіру',
			'common.ok' => 'Түсінікті',
			'common.off' => 'Өшірулі',
			'common.seasonNumber' => ({required Object number}) => '${number}-маусым',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => '${number}-бөлім - ${title}',
			'common.chapterNumber' => ({required Object number}) => '${number}-бөлім',
			'common.reconnect' => 'Қайта қосылу',
			'common.viewAll' => 'Барлығын көру',
			'common.checkingNetwork' => 'Желі тексерілуде...',
			'common.loadingServers' => 'Серверлер жүктелуде...',
			'common.connectingToServers' => 'Серверлерге қосылуда...',
			'common.startingOfflineMode' => 'Офлайн режим іске қосылуда...',
			'common.loading' => 'Жүктелуде...',
			'common.fullscreen' => 'Толық экран',
			'common.exitFullscreen' => 'Толық экраннан шығу',
			'common.pressBackAgainToExit' => 'Шығу үшін артқа түймесін қайтадан басыңыз',
			'screens.licenses' => 'Лицензиялар',
			'screens.switchProfile' => 'Профильді ауыстыру',
			'screens.subtitleStyling' => 'Субтитр баптаулары',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Журналдар',
			'update.available' => 'Жаңарту қолжетімді',
			'update.versionAvailable' => ({required Object version}) => '${version} нұсқасы қолжетімді',
			'update.currentVersion' => ({required Object version}) => 'Ағымдағы: ${version}',
			'update.skipVersion' => 'Бұл нұсқаны өткізіп жіберу',
			'update.viewRelease' => 'Релизді көру',
			'update.latestVersion' => 'Сізде ең соңғы нұсқа орнатылған',
			'update.checkFailed' => 'Жаңартуларды тексеру мүмкін болмады',
			'settings.title' => 'Баптаулар',
			'settings.supportDeveloper' => 'Plezy жобасын қолдау',
			'settings.supportDeveloperDescription' => 'Дамытуды қаржыландыру үшін Liberapay арқылы демеушілік жасаңыз',
			'settings.language' => 'Тіл',
			'settings.theme' => 'Тақырып',
			'settings.appearance' => 'Сыртқы келбеті',
			'settings.videoPlayback' => 'Видеоны ойнату',
			'settings.videoPlaybackDescription' => 'Ойнату параметрлерін реттеңіз',
			'settings.advanced' => 'Кеңейтілген',
			'settings.episodePosterMode' => 'Бөлім постерінің стилі',
			'settings.seriesPoster' => 'Сериал постері',
			'settings.seasonPoster' => 'Маусым постері',
			'settings.episodeThumbnail' => 'Кадр алдын ала көрінісі',
			'settings.showHeroSectionDescription' => 'Басты бетте арнайы мазмұн каруселін көрсету',
			'settings.secondsLabel' => 'Секунд',
			'settings.minutesLabel' => 'Минут',
			'settings.secondsShort' => 'сек',
			'settings.minutesShort' => 'мин',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Уақытты енгізіңіз (${min}-${max})',
			'settings.systemTheme' => 'Жүйелік',
			'settings.lightTheme' => 'Жарық',
			'settings.darkTheme' => 'Қараңғы',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Кітапхана тығыздығы',
			'settings.compact' => 'Тығыз',
			'settings.comfortable' => 'Ыңғайлы',
			'settings.tvCornerSpotlightBackdrop' => 'Бұрыштық жарық фоны',
			'settings.tvCornerSpotlightBackdropDescription' => 'Фонды толық экран орнына жоғарғы оң жақ бұрышта көрсету',
			'settings.viewMode' => 'Көрініс режимі',
			'settings.gridView' => 'Тор',
			'settings.listView' => 'Тізім',
			'settings.showHeroSection' => 'Басты бөлімді көрсету',
			'settings.continueWatchingAction' => '"Көруді жалғастыру" әрекеті',
			'settings.continueWatchingPlay' => 'Ойнату',
			'settings.continueWatchingDetails' => 'Толығырақ ашу',
			'settings.episodeAction' => 'Бөлім әрекеті',
			'settings.episodePlay' => 'Ойнату',
			'settings.episodeDetails' => 'Толығырақ ашу',
			'settings.useGlobalHubs' => 'Басты бет құрылымын пайдалану',
			'settings.useGlobalHubsDescription' => 'Біріктірілген басты бет бөлімдерін көрсету.',
			'settings.showServerNameOnHubs' => 'Бөлімдерде сервер атын көрсету',
			'settings.showServerNameOnHubsDescription' => 'Бөлім тақырыптарында әрдайым сервер атын көрсету.',
			'settings.groupLibrariesByServer' => 'Кітапханаларды сервер бойынша топтау',
			'settings.groupLibrariesByServerDescription' => 'Мүйістік мәзірдегі кітапханаларды серверлер бойынша топтау.',
			'settings.alwaysKeepSidebarOpen' => 'Сүйістік мәзірді әрдайым ашық ұстау',
			'settings.alwaysKeepSidebarOpenDescription' => 'Жүйелік мәзір ашық күйінде қалады',
			'settings.showUnwatchedCount' => 'Көрілмегендер санын көрсету',
			'settings.showUnwatchedCountDescription' => 'Сериалдар мен маусымдарда көрілмеген бөлімдер санын көрсету',
			'settings.showEpisodeNumberOnCards' => 'Карточкаларда бөлім нөмірін көрсету',
			'settings.showEpisodeNumberOnCardsDescription' => 'Бөлім карточкаларында маусым мен бөлім нөмірін көрсету',
			'settings.showSeasonPostersOnTabs' => 'Қойындыларда маусым постерлерін көрсету',
			'settings.showSeasonPostersOnTabsDescription' => 'Әр маусымның постерін өз бөлімінің үстінде көрсету',
			'settings.tvFullCardLayout' => 'Толық TV карточкалары',
			'settings.tvFullCardLayoutDescription' => 'Тек суреттен тұратын TV карточкаларын пайдалану',
			'settings.focusGlow' => 'Фокус жарқылы',
			'settings.focusGlowDescription' => 'Таңдалған карточка айналасында жұмсақ жарқыл көрсету',
			'settings.visualEffects' => 'Визуалды эффектілер',
			'settings.visualEffectsAuto' => 'Автоматты',
			'settings.visualEffectsAutoDescription' => 'Әлсіз құрылғыларда эффектілерді автоматты түрде азайту',
			'settings.visualEffectsFull' => 'Толық',
			'settings.visualEffectsReduced' => 'Азайтылған',
			'settings.visualEffectsReducedDescription' => 'Аз анимация және төмен сапалы суреттер',
			'settings.hideSpoilers' => 'Көрілмеген бөлімдер үшін спойлерлерді жасыру',
			'settings.hideSpoilersDescription' => 'Көрілмеген бөлімдердің суреттері мен сипаттамаларын бұлдырату',
			'settings.playerBackend' => 'Ойнатқыш инфрақұрылымы',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Аппараттық декодтау',
			'settings.hardwareDecodingDescription' => 'Мүмкіндігінше аппараттық үдетуді пайдалану',
			'settings.bufferSize' => 'Буфер көлемі',
			'settings.bufferSizeMB' => ({required Object size}) => '${size} МБ',
			'settings.bufferSizeAuto' => 'Автоматты (Ұсынылатын)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap} МБ ЖҰД қолжетімді. ${size} МБ буфер ойнатуға әсер етуі мүмкін.',
			'settings.defaultQualityTitle' => 'Әдепкі сапа',
			'settings.musicQualityTitle' => 'Музыка сапасы',
			'settings.subtitleStyling' => 'Субтитр баптаулары',
			'settings.subtitleStylingDescription' => 'Субтитрлердің сыртқы келбетін теңшеу',
			'settings.smallSkipDuration' => 'Шағын өткізіп жіберу уақыты',
			'settings.largeSkipDuration' => 'Үлкен өткізіп жіберу уақыты',
			'settings.rewindOnResume' => 'Жалғастырғанда артқа айналдыру',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} секунд',
			'settings.defaultSleepTimer' => 'Әдепкі ұйқы таймері',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} минут',
			'settings.rememberTrackSelections' => 'Әр фильм/сериал үшін дыбыс/субтитр таңдауын есте сақтау',
			'settings.rememberTrackSelectionsDescription' => 'Әр медиа үшін дыбыс пен субтитр таңдауын сақтау',
			'settings.followServerTrackSelections' => 'Әр бөлім үшін сервердегі жолдар таңдауын қолдану',
			'settings.followServerTrackSelectionsDescription' => 'Бөлім ауысқанда ағымдағы таңдауды көшірудің орнына серверде таңдалған дыбыс пен субтитрлерді қолдану',
			'settings.showChapterMarkersOnTimeline' => 'Уақыт шкаласында бөлім белгілерін көрсету',
			'settings.showChapterMarkersOnTimelineDescription' => 'Уақыт шкаласын бөлімдерге бөлу',
			'settings.clickVideoTogglesPlayback' => 'Ойнату/кідірту үшін видеоны басу',
			'settings.clickVideoTogglesPlaybackDescription' => 'Басқару элементтерін көрсету орнына ойнату немесе кідірту',
			'settings.videoPlayerControls' => 'Видео ойнатқыш басқару элементтері',
			'settings.keyboardShortcuts' => 'Пернетақта пернелер тіркесі',
			'settings.keyboardShortcutsDescription' => 'Пернетақта пернелер тіркесін реттеу',
			'settings.videoPlayerNavigation' => 'Видео ойнатқыш навигациясы',
			'settings.videoPlayerNavigationDescription' => 'Ойнатқышты басқару үшін бағыттауыш пернелерді пайдалану',
			'settings.watchTogetherRelay' => 'Бірге көру релесі',
			'settings.watchTogetherRelayDescription' => 'Жеке реле орнату. Барлығы бір серверді пайдалануы керек.',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Дұрыс HTTP немесе HTTPS реле мекенжайын енгізіңіз.',
			'settings.crashReporting' => 'Қателіктер туралы есеп',
			'settings.crashReportingDescription' => 'Қолданбаны жақсартуға көмектесу үшін қателіктер есебін жіберу',
			'settings.debugLogging' => 'Жөндеу журналы',
			'settings.debugLoggingDescription' => 'Мәселелерді шешу үшін толық журнал жүргізуді қосу',
			'settings.viewLogs' => 'Журналдарды көру',
			'settings.viewLogsDescription' => 'Қолданба журналдарын көру',
			'settings.clearImageCache' => 'Сурет кэшін тазалау',
			'settings.clearImageCacheDescription' => 'Кэштелген суреттерді тазалайды.',
			'settings.clearImageCacheSuccess' => 'Сурет кэші сәтті тазаланды',
			'settings.resetSettings' => 'Баптауларды қалпына келтіру',
			'settings.resetSettingsDescription' => 'Әдепкі баптауларды қайтару. Бұл әрекетті қайтару мүмкін емес.',
			'settings.resetSettingsSuccess' => 'Баптаулар сәтті қалпына келтірілді',
			'settings.backup' => 'Резервтік көшірме',
			'settings.exportSettings' => 'Баптауларды экспорттау',
			'settings.exportSettingsDescription' => 'Параметрлеріңізді файлға сақтаңыз',
			'settings.exportSettingsSuccess' => 'Баптаулар экспортталды',
			'settings.importSettings' => 'Баптауларды импорттау',
			'settings.importSettingsDescription' => 'Параметрлерді файлдан қалпына келтіріңіз',
			'settings.importSettingsConfirm' => 'Бұл ағымдағы баптауларыңыздың үстінен жазады. Жалғастырасыз ба?',
			'settings.importSettingsSuccess' => 'Баптаулар импортталды',
			'settings.importSettingsInvalidFile' => 'Бұл файл дұрыс Plezy баптаулар файлы емес',
			'settings.importSettingsNoUser' => 'Баптауларды импорттау алдында жүйеге кіріңіз',
			'settings.shortcutsReset' => 'Пернелер тіркесі әдепкі күйге қайтарылды',
			'settings.about' => 'Қолданба туралы',
			'settings.aboutDescription' => 'Қолданба туралы ақпарат пен лицензиялар',
			'settings.updates' => 'Жаңартулар',
			'settings.updateAvailable' => 'Жаңарту бар',
			'settings.checkForUpdates' => 'Жаңартуларды тексеру',
			'settings.autoCheckUpdatesOnStartup' => 'Іске қосылғанда жаңартуларды автоматты тексеру',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Іске қосылғанда жаңарту бар болса хабарлау',
			'settings.validationErrorEnterNumber' => 'Дұрыс сан енгізіңіз',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Уақыт ${min} және ${max} ${unit} аралығында болуы керек',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Бұл тіркес ${action} әрекетіне тағайындалған',
			'settings.shortcutUpdated' => ({required Object action}) => '${action} үшін пернелер тіркесі жаңартылды',
			'settings.saveFailed' => 'Өзгерістер сақталмады. Қайтадан байқап көріңіз.',
			'settings.autoSkip' => 'Автоматты өткізу',
			'settings.autoSkipIntro' => 'Киріс бөлімді (Intro) автоматты өткізу',
			'settings.autoSkipIntroDescription' => 'Бірнеше секундтан кейін киріс белгілерін автоматты өткізу',
			'settings.autoSkipCredits' => 'Титрлерді автоматты өткізу',
			'settings.autoSkipCreditsDescription' => 'Титрлерді автоматты өткізіп, келесі бөлімді ойнату',
			'settings.forceSkipMarkerFallback' => 'Қосалқы белгілерді мәжбүрлеу',
			'settings.forceSkipMarkerFallbackDescription' => 'Plex белгілері болса да бөлім тақырыбы үлгілерін пайдалану',
			'settings.autoSkipDelay' => 'Автоматты өткізу кідірісі',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Автоматты өткізгенге дейін ${seconds} секунд күту',
			'settings.introPattern' => 'Киріс бөлім белгісінің үлгісі',
			'settings.introPatternDescription' => 'Бөлім тақырыптарында интроны табуға арналған Regex үлгісі',
			'settings.creditsPattern' => 'Титр белгісінің үлгісі',
			'settings.creditsPatternDescription' => 'Бөлім тақырыптарында титрлерді табуға арналған Regex үлгісі',
			'settings.invalidRegex' => 'Қате тұрақты өрнек (Regex)',
			'settings.regex' => 'Тұрақты өрнек (Regex)',
			'settings.downloads' => 'Жүктеулер',
			'settings.downloadLocationDescription' => 'Жүктелген файлдар сақталатын орынды таңдаңыз',
			'settings.downloadLocationDefault' => 'Әдепкі (Қолданба жады)',
			'settings.downloadLocationCustom' => 'Таңдамалы орын',
			'settings.selectFolder' => 'Қапшықты таңдау',
			'settings.resetToDefault' => 'Әдепкі күйге қайтару',
			'settings.currentPath' => ({required Object path}) => 'Ағымдағы: ${path}',
			'settings.downloadLocationChanged' => 'Жүктеу орны өзгертілді',
			'settings.downloadLocationReset' => 'Жүктеу орны әдепкі күйге қайтарылды',
			'settings.downloadLocationInvalid' => 'Таңдалған қапшыққа жазу мүмкін емес',
			'settings.downloadLocationPickerUnavailable' => 'Бұл құрылғыда қапшықты таңдау мүмкіндігі жоқ',
			'settings.downloadOnWifiOnly' => 'Тек Wi-Fi арқылы жүктеу',
			'settings.downloadOnWifiOnlyDescription' => 'Мобильді деректер пайдаланылғанда жүктеулерді кідірту',
			'settings.autoRemoveWatchedDownloads' => 'Көрілген жүктеулерді автоматты өшіру',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Көрілген жүктеулерді автоматты түрде өшіру',
			'settings.cellularDownloadBlocked' => 'Мобильді желіде жүктеу бұғатталған. Wi-Fi пайдаланыңыз.',
			'settings.maxVolume' => 'Максималды дыбыс',
			'settings.maxVolumeDescription' => 'Ақырын видеолар үшін дыбысты 100%-дан асыруға рұқсат беру',
			'settings.maxVolumePercent' => ({required Object percent}) => '%${percent}',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Discord-та не көріп жатқаныңызды көрсету',
			'settings.services' => 'Қызметтер',
			'settings.servicesDescription' => 'Trakt, MyAnimeList, Seerr және т.б. қосыңыз',
			'settings.manageLibrariesDescription' => 'Кітапханаларды қайта реттеу және жасыру',
			'settings.companionRemoteServer' => 'Көмекші пульт сервері',
			'settings.companionRemoteServerDescription' => 'Желідегі мобильді құрылғыларға осы қолданбаны басқаруға рұқсат беру',
			'settings.autoPip' => 'Автоматты Суреттегі сурет (PiP)',
			'settings.autoPipDescription' => 'Видео ойнап жатқанда қолданбадан шыққанда авто-PiP режиміне өту',
			'settings.matchContentFrameRate' => 'Кадр жиілігін сәйкестендіру',
			'settings.matchContentFrameRateDescription' => 'Экран жиілігін видео мазмұнына сәйкестендіру',
			'settings.matchRefreshRate' => 'Жаңарту жиілігін сәйкестендіру',
			'settings.matchRefreshRateDescription' => 'Толық экранда экран жаңарту жиілігін сәйкестендіру',
			'settings.matchDynamicRange' => 'Динамикалық диапазонды сәйкестендіру',
			'settings.matchDynamicRangeDescription' => 'HDR мазмұн үшін HDR қосу, кейін SDR-ға қайту',
			'settings.displaySwitchDelay' => 'Экранды ауыстыру кідірісі',
			'settings.tunneledPlayback' => 'Туннельді ойнату',
			'settings.tunneledPlaybackDescription' => 'Видео туннельдеуді пайдалану.',
			'settings.audioPassthrough' => 'Дыбысты тікелей өткізу (Passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS дыбысын қайта кодтамай ресиверге жібереді.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Dolby Digital Plus үшін Apple декодерін пайдалану.',
			'settings.audioDownmix' => 'Стереоға түрлендіру (Downmix)',
			'settings.audioDownmixDescription' => 'Көп арналы дыбысты стерео динамиктер үшін екі арнаға төмендету',
			'settings.downmixCenterBoost' => 'Орталық арнаны күшейту',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} дБ',
			'settings.downmixCenterBoostLabel' => 'Күшейту (дБ)',
			'settings.downmixCenterBoostShort' => 'дБ',
			'settings.audioDownmixNormalize' => 'Түрлендіруде дыбысты нормалау',
			'settings.audioDownmixNormalizeDescription' => 'Дыбыс бұзылуын болдырмау үшін деңгейді төмендету.',
			'settings.atmosDiagnostics' => 'Atmos шығысын тексеру',
			'settings.atmosDiagnosticsDescription' => 'Dolby Atmos шығысын тексеру',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos ағыны',
			'settings.atmosTestHlsAtmosDescription' => 'Дұрыс жұмыс істейтін Dolby Atmos ағыны.',
			'settings.atmosTestHlsControl' => 'Apple көлемді дыбыс ағыны',
			'settings.atmosTestHlsControlDescription' => 'Atmos емес бақылау ағыны.',
			'settings.atmosTestRawStream' => 'Өңделмеген EAC3 ағыны',
			'settings.atmosTestRawStreamDescription' => 'Тест файлын ішкі Atmos ретінде тарату.',
			'settings.atmosTestRawFile' => 'Өңделмеген EAC3 файлы',
			'settings.atmosTestRawFileDescription' => 'Тест файлын ойнату.',
			'settings.atmosTestAsbarNative' => 'Сэмпл-буфер рендерері (нативті)',
			'settings.atmosTestAsbarNativeDescription' => 'Файлдың өзгертілмеген сығылған дыбысын тікелей жүйелік рендерерге береді. Тест файлының URL-і қажет.',
			'settings.atmosTestAsbarGenerated' => 'Сэмпл-буфер рендерері (қайта құрылған)',
			'settings.atmosTestAsbarGeneratedDescription' => 'Сол сияқты, бірақ дыбыс сипаттамасы ойнату кезіндегідей қайта құрылады. Тест файлының URL-і қажет.',
			'settings.atmosTestSessionMode' => 'Фильмді ойнату сеансы режимін пайдалану',
			'settings.atmosTestSessionModeDescription' => 'Өшірулі — Dolby құжаттаған режим. Қосулы — бұрын пайдаланылған режим.',
			'settings.atmosTestShowRoutePicker' => 'AirPlay шығысын таңдау',
			'settings.atmosTestHideRoutePicker' => 'AirPlay шығысын таңдау терезесін жасыру',
			'settings.atmosTestRoutePickerDescription' => 'Тестті AirPlay қабылдағышына жібереді. Анықталған дыбыс режимін тек AirPlay хабарлайды.',
			'settings.atmosTestStop' => 'Тестті тоқтату',
			'settings.atmosTestUrl' => 'Тест файлының URL-і',
			'settings.atmosTestUrlDescription' => 'Өңделмеген .ec3 файлының HTTP URL-і',
			'settings.atmosTestUrlMissing' => 'Алдымен тест файлының URL-ін орнатыңыз',
			'settings.atmosTestStatus' => 'Мәртебесі',
			'settings.dvConversionMode' => 'Dolby Vision түрлендіруі',
			'settings.dvConversionModeDescription' => 'ExoPlayer-дің Dolby Vision Profile 7 файлдарын өңдеу әдісін таңдаңыз.',
			'settings.dvConversionAuto' => 'Автоматты',
			'settings.dvConversionNative' => 'Ішкі / Өшірулі',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Құрылғы мүмкіндіктерін пайдалану',
			'settings.dvConversionNativeDescription' => 'Ішкі DV7 режимін мәжбүрлеу',
			'settings.dvConversionDv81Description' => 'Dolby Vision profile 8.1 форматына түрлендіру',
			'settings.dvConversionHevcStripDescription' => 'Dolby Vision қабаттарын алып тастап, HEVC ретінде көрсету',
			'settings.requireProfileSelectionOnOpen' => 'Ашқанда профильді сұрау',
			'settings.requireProfileSelectionOnOpenDescription' => 'Қолданба ашылған сайын профильді таңдауды көрсету',
			'settings.forceTvMode' => 'TV режимін мәжбүрлеу',
			'settings.forceTvModeDescription' => 'TV интерфейсін мәжбүрлеу.',
			'settings.startInFullscreen' => 'Толық экранда бастау',
			'settings.startInFullscreenDescription' => 'Plezy-ді ашқанда толық экран режимінде ашу',
			'settings.exitFullscreenOnPlayerClose' => 'Ойнатқыш жабылғанда толық экраннан шығу',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Видео ойнатқышты жапқанда автоматты түрде толық экраннан шығу',
			'settings.autoHidePerformanceOverlay' => 'Өнімділік панелін авто-жасыру',
			'settings.autoHidePerformanceOverlayDescription' => 'Өнімділік панелін басқару элементтерімен бірге жасыру',
			'settings.showNavBarLabels' => 'Навигация панелінің мәтіндерін көрсету',
			'settings.showNavBarLabelsDescription' => 'Навигация белгішелерінің астында мәтінді көрсету',
			'settings.startupSection' => 'Бастапқы бөлім',
			'settings.liveTvDefaultFavorites' => 'Тікелей TV-де таңдаулы арналарды әдепкі ету',
			'settings.liveTvDefaultFavoritesDescription' => 'Тікелей TV ашылғанда тек таңдаулы арналарды көрсету',
			'settings.display' => 'Дисплей',
			'settings.homeScreen' => 'Басты экран',
			'settings.navigation' => 'Навигация',
			'settings.window' => 'Терезе',
			'settings.content' => 'Мазмұн',
			'settings.player' => 'Ойнатқыш',
			'settings.subtitlesAndConfig' => 'Субтитрлер мен конфигурация',
			'settings.seekAndTiming' => 'Айналдыру және уақытты реттеу',
			'settings.behavior' => 'Мінез-құлық',
			'search.hint' => 'Фильмдер, сериалдар, музыка іздеу...',
			'search.tryDifferentTerm' => 'Басқа іздеу сөзін байқап көріңіз',
			'search.searchYourMedia' => 'Медиафайлдардан іздеу',
			'search.enterTitleActorOrKeyword' => 'Атауын, актерді немесе кілт сөзді енгізіңіз',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => '${actionName} үшін пернелер тіркесін орнату',
			'hotkeys.clearShortcut' => 'Тіркесті тазалау',
			'hotkeys.noShortcutSet' => 'Пернелер тіркесі орнатылмаған',
			'hotkeys.currentShortcut' => 'Ағымдағы тіркес:',
			'hotkeys.pressToRecord' => 'Тіркесті жазу үшін басыңыз',
			'hotkeys.recordingShortcut' => 'Енді пернелерді басыңыз',
			'hotkeys.actions.playPause' => 'Ойнату/Кідірту',
			'hotkeys.actions.volumeUp' => 'Дыбысты үлкейту',
			'hotkeys.actions.volumeDown' => 'Дыбысты азайту',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Алға айналдыру (${seconds}сек)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Артқа айналдыру (${seconds}сек)',
			'hotkeys.actions.fullscreenToggle' => 'Толық экранды ауыстыру',
			'hotkeys.actions.muteToggle' => 'Дыбысты өшіру/қосу',
			'hotkeys.actions.subtitleToggle' => 'Субтитрді қосу/өшіру',
			'hotkeys.actions.audioTrackNext' => 'Келесі аудиожол',
			'hotkeys.actions.subtitleTrackNext' => 'Келесі субтитр жолы',
			'hotkeys.actions.chapterNext' => 'Келесі бөлім',
			'hotkeys.actions.chapterPrevious' => 'Алдыңғы бөлім',
			'hotkeys.actions.episodeNext' => 'Келесі бөлім',
			'hotkeys.actions.episodePrevious' => 'Алдыңғы бөлім',
			'hotkeys.actions.speedIncrease' => 'Жылдамдықты арттыру',
			'hotkeys.actions.speedDecrease' => 'Жылдамдықты азайту',
			'hotkeys.actions.speedReset' => 'Жылдамдықты қалпына келтіру',
			'hotkeys.actions.zoomIn' => 'Жақындату',
			'hotkeys.actions.zoomOut' => 'Алыстату',
			'hotkeys.actions.zoomReset' => 'Масштабты қалпына келтіру',
			'hotkeys.actions.subSeekNext' => 'Келесі субтитрге өту',
			'hotkeys.actions.subSeekPrev' => 'Алдыңғы субтитрге өту',
			'hotkeys.actions.shaderToggle' => 'Шейдерлерді қосу/өшіру',
			'hotkeys.actions.skipMarker' => 'Интро/Титрді өткізу',
			'hotkeys.actions.screenshot' => 'Экран суретін түсіру',
			'fileInfo.title' => 'Файл туралы ақпарат',
			'fileInfo.video' => 'Видео',
			'fileInfo.audio' => 'Аудио',
			'fileInfo.subtitles' => 'Субтитрлер',
			'fileInfo.file' => 'Файл',
			'fileInfo.codec' => 'Кодек',
			'fileInfo.resolution' => 'Ажыратымдылық',
			'fileInfo.bitrate' => 'Биттік жылдамдық (Bitrate)',
			'fileInfo.frameRate' => 'Кадр жиілігі',
			'fileInfo.aspectRatio' => 'Тараптар қатынасы',
			'fileInfo.profile' => 'Профиль',
			'fileInfo.bitDepth' => 'Бит тереңдігі',
			'fileInfo.colorSpace' => 'Түс кеңістігі',
			'fileInfo.colorRange' => 'Түс диапазоны',
			'fileInfo.colorPrimaries' => 'Негізгі түстер',
			'fileInfo.chromaSubsampling' => 'Түстік субдискретизация',
			'fileInfo.channels' => 'Арналар',
			'fileInfo.overallBitrate' => 'Жалпы биттік жылдамдық',
			'fileInfo.path' => 'Жол',
			'fileInfo.size' => 'Көлемі',
			'fileInfo.container' => 'Контейнер',
			'fileInfo.duration' => 'Уақыты',
			'fileInfo.optimizedForStreaming' => 'Ағынды беру үшін оңтайландырылған',
			'fileInfo.has64bitOffsets' => '64-биттік ығысулар',
			'mediaMenu.markAsWatched' => 'Көрілді деп белгілеу',
			'mediaMenu.markAsUnwatched' => 'Көрілмеді деп белгілеу',
			'mediaMenu.removeFromContinueWatching' => '"Көруді жалғастыру" тізімінен өшіру',
			'mediaMenu.viewDetails' => 'Толығырақ көру',
			'mediaMenu.goToSeries' => 'Сериалға өту',
			'mediaMenu.shufflePlay' => 'Араластырып ойнату',
			'mediaMenu.shuffleNotAvailableOffline' => 'Араластырып ойнату офлайн режимде қолжетімсіз',
			'mediaMenu.fileInfo' => 'Файл туралы ақпарат',
			'mediaMenu.deleteFromServer' => 'Серверден өшіру',
			'mediaMenu.confirmDelete' => 'Осы медиа мен файлдар серверден өшірілсін бе?',
			'mediaMenu.deleteMultipleWarning' => 'Бұл барлық бөлімдер мен файлдарға әсер етеді.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Медиа элементі сәтті өшірілді',
			'mediaMenu.mediaFailedToDelete' => 'Медиа элементін өшіру мүмкін болмады',
			'mediaMenu.rate' => 'Бағалау',
			'mediaMenu.playFromBeginning' => 'Басынан бастап ойнату',
			'mediaMenu.playVersion' => 'Нұсқаны ойнату...',
			'rateSheet.title' => 'Бағалау',
			'rateSheet.server' => 'Сервер',
			'rateSheet.favorite' => 'Таңдаулы',
			'rateSheet.favorited' => 'Таңдаулыларға қосылды',
			'rateSheet.saved' => 'Сақталды',
			'rateSheet.notAvailable' => 'Сәйкестік табылмады',
			'rateSheet.noConnectedServices' => 'Бағалау үшін Баптаулардан қызметті қосыңыз.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, фильм',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV шоу',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'көрілген',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '%${percent} көрілген',
			'accessibility.mediaCardUnwatched' => 'көрілмеген',
			'accessibility.tapToPlay' => 'Ойнату үшін түртіңіз',
			'accessibility.decrease' => 'Азайту',
			'accessibility.increase' => 'Арттыру',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} мәнін азайту',
			'accessibility.increaseValue' => ({required Object label}) => '${label} мәнін арттыру',
			'accessibility.hue' => 'Түс реңкі',
			'accessibility.saturation' => 'Қанықтылық',
			'accessibility.brightness' => 'Жарықтық',
			'accessibility.hexColor' => 'Hex түсі',
			'accessibility.expandText' => 'Мәтінді жаю',
			'accessibility.collapseText' => 'Мәтінді жинау',
			'accessibility.alphabetNavigation' => 'Алфавиттік навигация',
			'accessibility.alphabetScrollHint' => 'Әріптер бойынша өту үшін жоғары немесе төмен сырғытыңыз',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Жол ${row} / ${rowCount}, баған ${column} / ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Жол ${row} / ${rowCount}',
			'tooltips.shufflePlay' => 'Араластырып ойнату',
			'tooltips.playTrailer' => 'Трейлерді ойнату',
			'tooltips.markAsWatched' => 'Көрілді деп белгілеу',
			'tooltips.markAsUnwatched' => 'Көрілмеді деп белгілеу',
			'audioTracks.track' => ({required Object n}) => 'Аудиожол ${n}',
			'videoControls.audioLabel' => 'Дыбыс',
			'videoControls.subtitlesLabel' => 'Субтитр',
			'videoControls.resetToZero' => '0мс-қа қалпына келтіру',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} кейін ойнатылады',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} бұрын ойнатылады',
			'videoControls.noOffset' => 'Ығысусыз',
			'videoControls.letterbox' => 'Кең экран (Letterbox)',
			'videoControls.fillScreen' => 'Экранды толтыру',
			'videoControls.stretch' => 'Созу',
			'videoControls.lockRotation' => 'Бұрылысты бұғаттау',
			'videoControls.unlockRotation' => 'Бұрылысты бұғаттаудан шығару',
			'videoControls.timerActive' => 'Таймер белсенді',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Ойнату ${duration} кейін кідіртіледі',
			'videoControls.sleepTimerEndOfVideo' => 'Ағымдағы видеоның соңы',
			'videoControls.sleepTimerStopAtHeader' => 'Тоқтату уақыты',
			'videoControls.sleepTimerDurationHeader' => 'Таймер',
			'videoControls.playbackWillPauseAtEnd' => 'Ойнату осы видеоның соңында кідіртіледі',
			'videoControls.stillWatching' => 'Әлі де көріп отырсыз ба?',
			'videoControls.pausingIn' => ({required Object seconds}) => '${seconds}сек кейін кідіртіледі',
			'videoControls.continueWatching' => 'Жалғастыру',
			'videoControls.autoPlayNext' => 'Келесіні автоматты ойнату',
			'videoControls.playNext' => 'Келесіні ойнату',
			'videoControls.playButton' => 'Ойнату',
			'videoControls.pauseButton' => 'Кідірту',
			'videoControls.showPlaybackControls' => 'Басқару элементтерін көрсету',
			'videoControls.hidePlaybackControls' => 'Басқару элементтерін жасыру',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} секунд артқа айналдыру',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} секунд алға айналдыру',
			'videoControls.previousButton' => 'Алдыңғы бөлім',
			'videoControls.nextButton' => 'Келесі бөлім',
			'videoControls.previousChapterButton' => 'Алдыңғы бөлімше',
			'videoControls.nextChapterButton' => 'Келесі бөлімше',
			'videoControls.muteButton' => 'Дыбысты өшіру',
			'videoControls.unmuteButton' => 'Дыбысты қосу',
			'videoControls.settingsButton' => 'Ойнату баптаулары',
			'videoControls.tracksButton' => 'Дыбыс және субтитрлер',
			'videoControls.chaptersButton' => 'Бөлімдер',
			'videoControls.versionQualityButton' => 'Нұсқа және сапа',
			'videoControls.versionColumnHeader' => 'Нұсқа',
			'videoControls.qualityColumnHeader' => 'Сапа',
			'videoControls.qualityOriginal' => 'Түпнұсқа',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Мбит/с',
			'videoControls.transcodeUnavailableFallback' => 'Түрлендіру қолжетімсіз — түпнұсқа сапада ойнатылады',
			'videoControls.subtitleUnavailableFallback' => 'Таңдалған субтитр жүктелмеді',
			'videoControls.pipButton' => 'Суреттегі сурет режимі',
			'videoControls.aspectRatioButton' => 'Тараптар қатынасы',
			'videoControls.ambientLighting' => 'Фондық жарықтандыру',
			'videoControls.fullscreenButton' => 'Толық экранға өту',
			'videoControls.exitFullscreenButton' => 'Толық экраннан шығу',
			'videoControls.alwaysOnTopButton' => 'Әрдайым үстінде',
			'videoControls.rotationLockButton' => 'Бұрылыс бұғаттауы',
			'videoControls.lockScreen' => 'Экранды бұғаттау',
			'videoControls.screenLockButton' => 'Экран бұғаттауы',
			'videoControls.longPressToUnlock' => 'Бұғаттаудан шығару үшін ұзақ басыңыз',
			'videoControls.timelineSlider' => 'Видео уақыт шкаласы',
			'videoControls.volumeSlider' => 'Дыбыс деңгейі',
			'videoControls.endsAt' => ({required Object time}) => 'Аяқталу уақыты: ${time}',
			'videoControls.pipActive' => 'Суреттегі сурет режимінде ойнатылуда',
			'videoControls.pipFailed' => 'PiP режимін іске қосу қатесі',
			'videoControls.screenshotSaved' => 'Экран суреті сақталды',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Масштаб %${percent}',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 немесе жаңалауы қажет',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 немесе жаңалауы қажет',
			'videoControls.pipErrors.permissionDisabled' => 'PiP режимі өшірілген. Жүйелік баптаулардан қосыңыз.',
			'videoControls.pipErrors.notSupported' => 'Құрылғы PiP режимін қолдамайды',
			'videoControls.pipErrors.voSwitchFailed' => 'PiP үшін видео шығысын ауыстыру мүмкін болмады',
			'videoControls.pipErrors.failed' => 'PiP режимін іске қосу қатесі',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Қате орын алды: ${error}',
			'videoControls.chapters' => 'Бөлімдер',
			'videoControls.noChaptersAvailable' => 'Бөлімдер қолжетімсіз',
			'videoControls.queue' => 'Кезек',
			'videoControls.noQueueItems' => 'Кезекте элементтер жоқ',
			_ => null,
		} ?? switch (path) {
			'videoControls.searchSubtitles' => 'Субтитр іздеу',
			'videoControls.language' => 'Тіл',
			'videoControls.noSubtitlesFound' => 'Субтитр табылмады',
			'videoControls.subtitleDownloaded' => 'Субтитр жүктелді',
			'videoControls.subtitleDownloadedNotApplied' => 'Субтитр жүктелді, бірақ қолданылмады',
			'videoControls.subtitleDownloadFailed' => 'Субтитрді жүктеу мүмкін болмады',
			'videoControls.searchLanguages' => 'Тілдерден іздеу...',
			'messages.markedAsWatched' => 'Көрілді деп белгіленді',
			'messages.markedAsUnwatched' => 'Көрілмеді деп белгіленді',
			'messages.markedAsWatchedOffline' => 'Көрілді деп белгіленді (онлайн болғанда синхрондалады)',
			'messages.markedAsUnwatchedOffline' => 'Көрілмеді деп белгіленді (онлайн болғанда синхрондалады)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Автоматты түрде өшірілді: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('kk'))(n, one: 'Көрілген ${n} жүктеу автоматты өшірілді', other: 'Көрілген ${n} жүктеу автоматты өшірілді', ), 
			'messages.removedFromContinueWatching' => '"Көруді жалғастыру" тізімінен өшірілді',
			'messages.errorLoading' => ({required Object error}) => 'Қате: ${error}',
			'messages.searchPartialResults' => 'Кейбір медиа серверлерінде іздеу орындалмады. Қолжетімді нәтижелер көрсетілуде.',
			'messages.streamInterrupted' => 'Ағын үзілді. Қайталау үшін ойнату түймесін басыңыз.',
			'messages.liveStreamInterrupted' => 'Тікелей ағын үзілді. Қайталау үшін ойнату түймесін басыңыз.',
			'messages.fileInfoNotAvailable' => 'Файл туралы ақпарат қолжетімсіз',
			'messages.playbackAuthenticationRequired' => 'Осы элементті ойнату үшін серверге қайтадан кіріңіз.',
			'messages.playbackServerUnavailable' => 'Медиа сервері қолжетімсіз. Кейінірек қайталаңыз.',
			'messages.playbackDataInvalid' => 'Сервер қате ойнату мәліметтерін қайтарды.',
			'messages.playbackCancelled' => 'Ойнатудан бас тартылды.',
			'messages.playbackFailed' => 'Ойнатуды іске қосу қатесі.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Файл ақпаратын жүктеу қатесі: ${error}',
			'messages.errorLoadingSeries' => 'Сериалды жүктеу қатесі',
			'messages.musicNotSupported' => 'Музыка ойнату әлі қолдау таппайды',
			'messages.noDescriptionAvailable' => 'Сипаттамасы жоқ',
			'messages.noProfilesAvailable' => 'Профильдер жоқ',
			'messages.contactAdminForProfiles' => 'Профиль қосу үшін администраторға хабарласыңыз',
			'messages.unableToDetermineLibrarySection' => 'Кітапхана бөлімін анықтау мүмкін болмады',
			'messages.logsCleared' => 'Журналдар тазаланды',
			'messages.logsCopied' => 'Журналдар көшірілді',
			'messages.noLogsAvailable' => 'Журналдар жоқ',
			'messages.libraryScanning' => ({required Object title}) => '"${title}" сканерленуде...',
			'messages.libraryScanStarted' => ({required Object title}) => '"${title}" үшін сканерлеу басталды',
			'messages.libraryScanFailed' => ({required Object error}) => 'Кітапхананы сканерлеу мүмкін болмады: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => '"${title}" үшін метадеректер жаңартылуда...',
			'messages.metadataRefreshStarted' => ({required Object title}) => '"${title}" үшін метадеректерді жаңарту басталды',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Метадеректерді жаңарту мүмкін болмады: ${error}',
			'messages.logoutConfirm' => 'Шынымен шыққыңыз келе ме?',
			'messages.noSeasonsFound' => 'Маусымдар табылмады',
			'messages.seasonsLoadFailed' => 'Маусымдарды жүктеу мүмкін болмады',
			'messages.noEpisodesFound' => 'Бірінші маусымда бөлімдер табылмады',
			'messages.noEpisodesFoundGeneral' => 'Бөлімдер табылмады',
			'messages.episodesLoadFailed' => 'Бөлімдерді жүктеу мүмкін болмады',
			'messages.noResultsFound' => 'Нәтижелер табылмады',
			'messages.sleepTimerSet' => ({required Object label}) => 'Ұйқы таймері ${label} уақытына орнатылды',
			'messages.noItemsAvailable' => 'Элементтер жоқ',
			'messages.failedToCreatePlayQueueNoItems' => 'Ойнату кезегін жасау мүмкін болмады — элементтер жоқ',
			'messages.failedPlayback' => ({required Object action, required Object error}) => '${action} сәтсіз аяқталды: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Үйлесімді ойнатқышқа ауысуда...',
			'messages.serverLimitTitle' => 'Ойнату қатесі',
			'messages.serverLimitBody' => 'Сервер қатесі (HTTP 500). Шектеу бұл сеансты қабылдамады.',
			'messages.logsUploaded' => 'Журналдар жүктелді',
			'messages.logsUploadFailed' => 'Журналдарды жүктеу мүмкін болмады',
			'messages.logId' => 'Журнал ID-сі',
			'subtitlingStyling.text' => 'Мәтін',
			'subtitlingStyling.border' => 'Жиек',
			'subtitlingStyling.background' => 'Фон',
			'subtitlingStyling.fontSize' => 'Қаріп өлшемі',
			'subtitlingStyling.textColor' => 'Мәтін түсі',
			'subtitlingStyling.borderSize' => 'Жиек өлшемі',
			'subtitlingStyling.borderColor' => 'Жиек түсі',
			'subtitlingStyling.backgroundOpacity' => 'Фон мөлдірлігі',
			'subtitlingStyling.backgroundColor' => 'Фон түсі',
			'subtitlingStyling.position' => 'Орналасуы',
			'subtitlingStyling.assOverride' => 'ASS қайта анықтау',
			'subtitlingStyling.overrideScale' => 'Масштабтау',
			'subtitlingStyling.overrideForce' => 'Мәжбүрлеу',
			'subtitlingStyling.overrideStrip' => 'Форматтауды жою',
			'subtitlingStyling.positionTop' => 'Жоғары',
			'subtitlingStyling.positionBottom' => 'Төмен',
			'subtitlingStyling.bold' => 'Қалың',
			'subtitlingStyling.italic' => 'Көлбеу',
			'subtitlingStyling.renderResolution' => 'Рендеринг ажыратымдылығы',
			'subtitlingStyling.renderResolutionScreen' => 'Экран ажыратымдылығы',
			'subtitlingStyling.renderResolutionVideo' => 'Видео ажыратымдылығы',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Кеңейтілген видео ойнатқыш баптаулары',
			'mpvConfig.presets' => 'Дайын баптаулар',
			'mpvConfig.noPresets' => 'Сақталған баптаулар жоқ',
			'mpvConfig.saveAsPreset' => 'Баптау ретінде сақтау...',
			'mpvConfig.presetName' => 'Баптау атауы',
			'mpvConfig.presetNameHint' => 'Осы баптау үшін атау енгізіңіз',
			'mpvConfig.loadPreset' => 'Жүктеу',
			'mpvConfig.deletePreset' => 'Өшіру',
			'mpvConfig.presetSaved' => 'Баптау сақталды',
			'mpvConfig.presetLoaded' => 'Баптау жүктелді',
			'mpvConfig.presetDeleted' => 'Баптау өшірілді',
			'mpvConfig.confirmDeletePreset' => 'Осы баптауды өшіргіңіз келетініне сенімдісіз бе?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# түсініктеме',
			'dialog.confirmAction' => 'Әрекетті растау',
			'profiles.addPlezyProfile' => 'Plezy профилін қосу',
			'profiles.switchingProfile' => 'Профильді ауыстыру…',
			'profiles.deleteThisProfileTitle' => 'Осы профиль өшірілсін бе?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} өшіріледі. Қосылымдарға әсер етпейді.',
			'profiles.active' => 'Белсенді',
			'profiles.manage' => 'Басқару',
			'profiles.delete' => 'Өшіру',
			'profiles.signOut' => 'Шығу',
			'profiles.signOutPlexTitle' => 'Plex-тен шығу?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} мен барлық Plex Home пайдаланушылары өшіріледі.',
			'profiles.signedOutPlex' => 'Plex-тен шықтыңыз.',
			'profiles.signOutFailed' => 'Шығу мүмкін болмады.',
			'profiles.sectionTitle' => 'Профильдер',
			'profiles.summarySingle' => 'Басқарылатын пайдаланушыларды біріктіру үшін профильдер қосыңыз',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} профиль · белсенді: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} профиль',
			'profiles.removeConnectionTitle' => 'Қосылым өшірілсін бе?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName} пайдаланушысының ${connectionLabel} қолжетімділігі өшіріледі.',
			'profiles.deleteProfileTitle' => 'Профиль өшірілсін бе?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} мен оның қосылымдары өшіріледі.',
			'profiles.profileNameLabel' => 'Профиль атауы',
			'profiles.pinProtectionLabel' => 'PIN қорғанысы',
			'profiles.pinManagedByPlex' => 'PIN кодын Plex басқарады. plex.tv сайтында өңдеңіз.',
			'profiles.noPinSetEditOnPlex' => 'PIN код орнатылмаған.',
			'profiles.setPin' => 'PIN орнату',
			'profiles.setPinTitle' => 'PIN орнату',
			'profiles.confirmPinTitle' => 'PIN кодын растау',
			'profiles.pinSet' => 'PIN орнатылды',
			'profiles.changePin' => 'Өзгерту',
			'profiles.removePin' => 'Өшіру',
			'profiles.connectionsLabel' => 'Қосылымдар',
			'profiles.add' => 'Қосу',
			'profiles.deleteProfileButton' => 'Профильді өшіру',
			'profiles.noConnectionsHint' => 'Қосылымдар жоқ — бұл профильді пайдалану үшін қосылым қосыңыз.',
			'profiles.noConnections' => 'Қосылымдар жоқ',
			'profiles.plexHomeAccount' => 'Plex Home тіркелгісі',
			'profiles.connectionDefault' => 'Әдепкі',
			'profiles.connectionAs' => ({required Object displayName}) => '${displayName} ретінде',
			'profiles.makeDefault' => 'Әдепкі ету',
			'profiles.removeConnection' => 'Өшіру',
			'profiles.profileRenamed' => 'Профиль атауы өзгертілді.',
			'profiles.borrowAddTo' => ({required Object displayName}) => '${displayName} профиліне қосу',
			'profiles.borrowExplain' => 'Басқа профильдің қосылымын пайдаланыңыз.',
			'profiles.borrowEmpty' => 'Әлі де пайдаланатын ештеңе жоқ.',
			'profiles.borrowEmptySubtitle' => 'Алдымен басқа профильге Plex немесе Jellyfin қосыңыз.',
			'profiles.borrowLoadFailed' => 'Қолжетімді қосылымдарды жүктеу мүмкін болмады.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => '${displayName} профилінен',
			'profiles.borrowConnectionBorrowed' => 'Қосылым пайдаланылды.',
			'profiles.borrowFailed' => 'Қосылымды пайдалану мүмкін болмады.',
			'profiles.incorrectPin' => 'Қате PIN код.',
			'profiles.incorrectPinTryAgain' => 'Қате PIN код. Қайтадан байқап көріңіз.',
			'profiles.sourceProfileMissingParentAccount' => 'Бастапқы профильде негізгі тіркелгі жоқ.',
			'profiles.failedToLoadHomeUsers' => 'Plex Home пайдаланушыларын жүктеу мүмкін болмады.',
			'profiles.failedToVerifyPin' => 'PIN кодын тексеру мүмкін болмады.',
			'profiles.newProfile' => 'Жаңа профиль',
			'profiles.profileNameHint' => 'мысалы, Қонақтар, Балалар',
			'profiles.pinProtectionOptional' => 'PIN қорғанысы (қосымша)',
			'profiles.pinExplain' => 'Профильдер арасында ауысу үшін 4 таңбалы PIN код қажет.',
			'profiles.continueButton' => 'Жалғастыру',
			'profiles.pinsDontMatch' => 'PIN кодтар сәйкес келмейді',
			'connections.sectionTitle' => 'Қосылымдар',
			'connections.addConnection' => 'Қосылым қосу',
			'connections.addConnectionSubtitleNoProfile' => 'Plex арқылы кіріңіз немесе Jellyfin серверіне қосылыңыз',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => '${displayName} профиліне қосу',
			'connections.sessionExpiredOne' => ({required Object name}) => '${name} үшін сеанс мерзімі өтті',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} сервер үшін сеанс мерзімі өтті',
			'connections.signInAgain' => 'Қайтадан кіру',
			'connections.editJellyfinTitle' => 'Jellyfin қосылымын өңдеу',
			'connections.editJellyfinIntro' => ({required Object serverName}) => '${serverName} үшін URL мекенжайын қосыңыз немесе өшіріңіз.',
			'discover.title' => 'Шолу',
			'discover.noContentAvailable' => 'Мазмұн қолжетімсіз',
			'discover.addMediaToLibraries' => 'Кітапханаларыңызға медиа қосыңыз',
			'discover.continueWatching' => 'Көруді жалғастыру',
			'discover.continueWatchingIn' => ({required Object library}) => '${library} ішінде көруді жалғастыру',
			'discover.nextUp' => 'Келесіде',
			'discover.nextUpIn' => ({required Object library}) => '${library} ішінде келесіде',
			'discover.recentlyAdded' => 'Соңғы қосылғандар',
			'discover.recentlyAddedIn' => ({required Object library}) => '${library} ішінде соңғы қосылғандар',
			'discover.latestAlbumsIn' => ({required Object library}) => '${library} ішінде соңғы альбомдар',
			'discover.recentlyPlayedIn' => ({required Object library}) => '${library} ішінде соңғы ойнатылғандар',
			'discover.mostPlayedIn' => ({required Object library}) => '${library} ішінде ең көп ойнатылғандар',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'М${season}Б${episode}',
			'discover.overview' => 'Сипаттамасы',
			'discover.cast' => 'Актерлер',
			'discover.extras' => 'Трейлерлер мен қосымшалар',
			'discover.studio' => 'Студия',
			'discover.rating' => 'Рейтинг',
			'discover.director' => 'Режиссер',
			'discover.directors' => 'Режиссерлер',
			'discover.movie' => 'Фильм',
			'discover.tvShow' => 'TV Шоу',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} мин қалды',
			'discover.moreLikeThis' => 'Ұқсастар',
			'errors.searchFailed' => ({required Object error}) => 'Іздеу қатесі: ${error}',
			'errors.searchUnavailable' => 'Іздеу ешбір медиа серверге қосыла алмады.',
			'errors.connectionTimeout' => ({required Object context}) => '${context} жүктеу уақыты өтті',
			'errors.connectionFailed' => 'Медиа серверіне қосылу мүмкін емес',
			'errors.unableToLoad' => ({required Object context}) => '${context} жүктеу мүмкін болмады.',
			'errors.noClientAvailable' => 'Қолжетімді клиент жоқ',
			'errors.pleaseEnterToken' => 'Токенді енгізіңіз',
			'errors.invalidToken' => 'Жарамсыз токен',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Токенді тексеру мүмкін болмады: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => '${displayName} профиліне ауысу мүмкін болмады',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => '${displayName} профилін өшіру мүмкін болмады',
			'errors.failedToRate' => 'Рейтингті жаңарту мүмкін болмады',
			'libraries.title' => 'Кітапханалар',
			'libraries.fallbackTitle' => 'Кітапхана',
			'libraries.scanLibraryFiles' => 'Файлдарды сканерлеу',
			'libraries.scanLibrary' => 'Кітапхананы сканерлеу',
			'libraries.analyze' => 'Талдау жасау',
			'libraries.analyzeLibrary' => 'Кітапханаға талдау жасау',
			'libraries.refreshMetadata' => 'Метадеректерді жаңарту',
			'libraries.emptyTrash' => 'Себетті тазалау',
			'libraries.emptyingTrash' => ({required Object title}) => '"${title}" себеті тазалануда...',
			'libraries.trashEmptied' => ({required Object title}) => '"${title}" себеті тазаланды',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Себетті тазалау мүмкін болмады: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}" талдануда...',
			'libraries.analysisStarted' => ({required Object title}) => '"${title}" үшін талдау басталды',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Талдау жасау мүмкін болмады: ${error}',
			'libraries.noLibrariesFound' => 'Кітапханалар табылмады',
			'libraries.allLibrariesHidden' => 'Барлық кітапханалар жасырылған',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Жасырын кітапханалар (${count})',
			'libraries.thisLibraryIsEmpty' => 'Бұл кітапхана бос',
			'libraries.noItemsMatchFilters' => 'Фильтрлерге сәйкес элементтер табылмады',
			'libraries.resetFilters' => 'Фильтрлерді қалпына келтіру',
			'libraries.all' => 'Барлығы',
			'libraries.clearAll' => 'Барлығын тазалау',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '"${title}" кітапханасын сканерлегіңіз келе ме?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '"${title}" кітапханасына талдау жасағыңыз келе ме?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '"${title}" метадеректерін жаңартасыз ба?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '"${title}" себетін тазалайсыз ба?',
			'libraries.manageLibraries' => 'Кітапханаларды басқару',
			'libraries.sort' => 'Сұрыптау',
			'libraries.sortBy' => 'Сұрыптау реті',
			'libraries.filters' => 'Фильтрлер',
			'libraries.confirmActionMessage' => 'Осы әрекетті орындағыңыз келе ме?',
			'libraries.showLibrary' => 'Кітапхананы көрсету',
			'libraries.hideLibrary' => 'Кітапхананы жасыру',
			'libraries.libraryOptions' => 'Кітапхана параметрлері',
			'libraries.content' => 'кітапхана мазмұны',
			'libraries.selectLibrary' => 'Кітапхананы таңдау',
			'libraries.filtersWithCount' => ({required Object count}) => 'Фильтрлер (${count})',
			'libraries.noRecommendations' => 'Ұсыныстар жоқ',
			'libraries.noCollections' => 'Бұл кітапханада топтамалар жоқ',
			'libraries.noFoldersFound' => 'Қапшықтар табылмады',
			'libraries.folders' => 'қапшықтар',
			'libraries.tabs.recommended' => 'Ұсынылатындар',
			'libraries.tabs.browse' => 'Шолу',
			'libraries.tabs.collections' => 'Топтамалар',
			'libraries.tabs.playlists' => 'Ойнату тізімдері',
			'libraries.groupings.title' => 'Топтау',
			'libraries.groupings.all' => 'Барлығы',
			'libraries.groupings.movies' => 'Фильмдер',
			'libraries.groupings.shows' => 'TV Шоулар',
			'libraries.groupings.seasons' => 'Маусымдар',
			'libraries.groupings.episodes' => 'Бөлімдер',
			'libraries.groupings.artists' => 'Орындаушылар',
			'libraries.groupings.albums' => 'Альбомдар',
			'libraries.groupings.tracks' => 'Әндер',
			'libraries.groupings.folders' => 'Қапшықтар',
			'libraries.filterCategories.genre' => 'Жанр',
			'libraries.filterCategories.year' => 'Жыл',
			'libraries.filterCategories.contentRating' => 'Мазмұн рейтингі',
			'libraries.filterCategories.tag' => 'Тег',
			'libraries.filterCategories.unwatched' => 'Көрілмеген',
			'libraries.filterCategories.unplayed' => 'Ойнатылмаған',
			'libraries.filterCategories.favorites' => 'Таңдаулылар',
			'libraries.sortLabels.title' => 'Атауы',
			'libraries.sortLabels.dateAdded' => 'Қосылған күні',
			'libraries.sortLabels.releaseDate' => 'Шыққан күні',
			'libraries.sortLabels.rating' => 'Рейтинг',
			'libraries.sortLabels.communityRating' => 'Қауымдастық рейтингі',
			'libraries.sortLabels.criticRating' => 'Сыншылар рейтингі',
			'libraries.sortLabels.userRating' => 'Пайдаланушы рейтингі',
			'libraries.sortLabels.datePlayed' => 'Ойнатылған күні',
			'libraries.sortLabels.playCount' => 'Ойнатылу саны',
			'libraries.sortLabels.productionYear' => 'Шығарылған жылы',
			'libraries.sortLabels.runtime' => 'Ұзақтығы',
			'libraries.sortLabels.officialRating' => 'Ресми рейтинг',
			'libraries.sortLabels.premiereDate' => 'Премьера күні',
			'libraries.sortLabels.startDate' => 'Басталған күні',
			'libraries.sortLabels.airTime' => 'Эфир уақыты',
			'libraries.sortLabels.studio' => 'Студия',
			'libraries.sortLabels.random' => 'Кездейсоқ',
			'libraries.sortLabels.dateShared' => 'Бөлісілген күні',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Соңғы бөлімнің шыққан күні',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Соңғы қосылған бөлім күні',
			'about.title' => 'Қолданба туралы',
			'about.openSourceLicenses' => 'Ашық бастапқы код лицензиялары',
			'about.versionLabel' => ({required Object version}) => 'Нұсқа ${version}',
			'about.appDescription' => 'Flutter негізіндегі ыңғайлы Plex және Jellyfin клиенті',
			'about.viewLicensesDescription' => 'Үшінші тарап кітапханаларының лицензияларын көру',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => '${username} (${email}) үшін серверлер табылмады',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Серверлерді жүктеу қатесі: ${error}',
			'hubDetail.title' => 'Атауы',
			'hubDetail.releaseYear' => 'Шыққан жылы',
			'hubDetail.dateAdded' => 'Қосылған күні',
			'hubDetail.rating' => 'Рейтинг',
			'hubDetail.noItemsFound' => 'Элементтер табылмады',
			'logs.clearLogs' => 'Журналдарды тазалау',
			'logs.copyLogs' => 'Журналдарды көшіру',
			'logs.uploadLogs' => 'Журналдарды жүктеу',
			'licenses.relatedPackages' => 'Байланысты пакеттер',
			'licenses.license' => 'Лицензия',
			'licenses.licenseNumber' => ({required Object number}) => 'Лицензия ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} лицензия',
			'navigation.libraries' => 'Кітапханалар',
			'navigation.downloads' => 'Жүктеулер',
			'navigation.liveTv' => 'Тікелей TV',
			'navigation.explore' => 'Шолу',
			'explore.title' => 'Шолу',
			'explore.selectSource' => 'Дереккөзді таңдаңыз',
			'explore.rows.watchlist' => 'Көру тізімі',
			'explore.rows.recommendedMovies' => 'Ұсынылатын фильмдер',
			'explore.rows.recommendedShows' => 'Ұсынылатын сериалдар',
			'explore.rows.trendingMovies' => 'Трендтегі фильмдер',
			'explore.rows.trendingShows' => 'Трендтегі сериалдар',
			'explore.rows.popularMovies' => 'Танымал фильмдер',
			'explore.rows.popularShows' => 'Танымал сериалдар',
			'explore.rows.trendingAnime' => 'Трендтегі аниме',
			'explore.rows.suggestedAnime' => 'Ұсынылатын аниме',
			'explore.rows.airingAnime' => 'Эфирдегі үздік аниме',
			'explore.rows.popularAnime' => 'Ең танымал аниме',
			'explore.rows.trending' => 'Трендтер',
			'explore.rows.upcomingMovies' => 'Күтілетін фильмдер',
			'explore.rows.upcomingShows' => 'Күтілетін сериалдар',
			'explore.status.airing' => 'Эфирде',
			'explore.status.ended' => 'Аяқталды',
			'explore.status.canceled' => 'Тоқтатылды',
			'explore.status.upcoming' => 'Күтілуде',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('kk'))(n, one: '${n} бөлім', other: '${n} бөлім', ), 
			'explore.cast' => 'Актерлер',
			'explore.characters' => 'Кейіпкерлер',
			'explore.addToWatchlist' => 'Көру тізіміне қосу',
			'explore.removeFromWatchlist' => 'Көру тізімінен өшіру',
			'explore.watchlistUpdateFailed' => 'Көру тізімін жаңарту мүмкін болмады',
			'explore.notInLibrary' => 'Кітапханаңызда жоқ',
			'explore.inTheseLibraries' => 'Осы кітапханаларда бар',
			'explore.checkingLibrary' => 'Кітапхана тексерілуде...',
			'explore.emptyTitle' => 'Әлі де мұнда ештеңе жоқ',
			'explore.emptyMessage' => ({required Object source}) => '${source} дереккөзінен алынған қатарлар мұнда көрінеді.',
			'explore.searchHint' => ({required Object source}) => '${source} ішінен іздеу',
			'explore.searchEmpty' => ({required Object query}) => '"${query}" бойынша нәтиже табылмады',
			'explore.searchPrompt' => ({required Object source}) => '${source} арқылы фильмдер мен сериалдарды іздеңіз.',
			'explore.searchFailed' => 'Іздеу қатесі. Қосылымды тексеріңіз.',
			'liveTv.title' => 'Тікелей TV',
			'liveTv.guide' => 'Телебағдарлама',
			'liveTv.noChannels' => 'Қолжетімді арналар жоқ',
			'liveTv.noDvr' => 'Серверде DVR бапталмаған',
			'liveTv.serverUnavailable' => 'Тікелей TV сервері қолжетімсіз.',
			'liveTv.serverNotConnected' => 'Тікелей TV серверіне қосылмаған.',
			'liveTv.noPrograms' => 'Бағдарлама ақпараты жоқ',
			'liveTv.liveStreamFailed' => 'Тікелей ағын қатесі',
			'liveTv.unknownProgram' => 'Белгісіз бағдарлама',
			'liveTv.unknownHub' => 'Белгісіз',
			'liveTv.unknownError' => 'Белгісіз қате',
			'liveTv.channelNumber' => ({required Object number}) => '${number}-арна',
			'liveTv.unknownChannel' => 'Белгісіз арна',
			'liveTv.live' => 'ТІКЕЛЕЙ ЭФИР',
			'liveTv.reloadGuide' => 'Бағдарламаны жаңарту',
			'liveTv.now' => 'Қазір',
			'liveTv.today' => 'Бүгін',
			'liveTv.tomorrow' => 'Ертең',
			'liveTv.midnight' => 'Түн ортасы',
			'liveTv.overnight' => 'Түнде',
			'liveTv.morning' => 'Таңертең',
			'liveTv.daytime' => 'Күндіз',
			'liveTv.evening' => 'Кешке',
			'liveTv.lateNight' => 'Түнде',
			'liveTv.whatsOn' => 'Қазір не болып жатыр?',
			'liveTv.watchChannel' => 'Арнаны көру',
			'liveTv.favorites' => 'Таңдаулылар',
			'liveTv.reorderFavorites' => 'Таңдаулыларды қайта реттеу',
			'liveTv.favoritesLoadFailed' => 'Таңдаулыларды жүктеу мүмкін болмады.',
			'liveTv.favoritesUpdateFailed' => 'Таңдаулыларды жаңарту мүмкін болмады.',
			'liveTv.joinSession' => 'Сеансқа қосылу',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Басынан бастап көру (${minutes} мин бұрын)',
			'liveTv.watchLive' => 'Тікелей эфирді көру',
			'liveTv.goToLive' => 'Тікелей эфирге өту',
			'liveTv.record' => 'Жазу',
			'liveTv.recordEpisode' => 'Бөлімді жазу',
			'liveTv.recordSeries' => 'Сериалды жазу',
			'liveTv.recordOptions' => 'Жазу параметрлері',
			'liveTv.saveTo' => 'Мұнда сақтау',
			'liveTv.recordings' => 'Жазылғандар',
			'liveTv.scheduledRecordings' => 'Жоспарланғандар',
			'liveTv.recordingRules' => 'Жазу ережелері',
			'liveTv.noScheduledRecordings' => 'Жоспарланған жазбалар жоқ',
			'liveTv.manageRecording' => 'Жазбаны басқару',
			'liveTv.cancelRecording' => 'Жазудан бас тарту',
			'liveTv.cancelRecordingTitle' => 'Жазу тоқтатылсын ба?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} енді жазылмайды.',
			'liveTv.deleteRule' => 'Ережені өшіру',
			'liveTv.deleteRuleTitle' => 'Жазу ережесі өшірілсін бе?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => '${title} сериалының келесі бөлімдері жазылмайды.',
			'liveTv.recordingScheduled' => 'Жазу жоспарланды',
			'liveTv.alreadyScheduled' => 'Бұл бағдарлама бұрыннан жоспарланған',
			'liveTv.dvrAdminRequired' => 'DVR баптаулары администратор құқығын талап етеді',
			'liveTv.recordingFailed' => 'Жазуды жоспарлау мүмкін болмады',
			'liveTv.recordingTargetMissing' => 'Жазатын кітапхана анықталмады',
			'liveTv.recordNotAvailable' => 'Бұл бағдарламаны жазу мүмкін емес',
			'liveTv.recordingCancelled' => 'Жазу тоқтатылды',
			'liveTv.recordingRuleDeleted' => 'Жазу ережесі өшірілді',
			'liveTv.processRecordingRules' => 'Ережелерді қайта бағалау',
			'liveTv.recordingInProgress' => 'Қазір жазылуда',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} жоспарланған',
			'liveTv.editRule' => 'Ережені өңдеу',
			'liveTv.editRuleAction' => 'Өңдеу',
			'liveTv.recordingRuleUpdated' => 'Жазу ережесі жаңартылды',
			'liveTv.guideReloadRequested' => 'Бағдарламаны жаңарту сұралды',
			'liveTv.rulesProcessRequested' => 'Ережелерді қайта бағалау сұралды',
			'liveTv.recordShow' => 'Шоуды жазу',
			'collections.title' => 'Топтамалар',
			'collections.collection' => 'Топтама',
			'collections.empty' => 'Топтама бос',
			'collections.deleteCollection' => 'Топтаманы өшіру',
			'collections.deleteConfirm' => ({required Object title}) => '"${title}" өшірілсін бе?',
			'collections.deleted' => 'Топтама өшірілді',
			'collections.deleteFailed' => 'Топтаманы өшіру мүмкін болмады',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Топтаманы өшіру қатесі: ${error}',
			'collections.selectCollection' => 'Топтаманы таңдау',
			'collections.collectionName' => 'Топтама атауы',
			'collections.enterCollectionName' => 'Топтама атауын енгізіңіз',
			'collections.addedToCollection' => 'Топтамаға қосылды',
			'collections.errorAddingToCollection' => 'Топтамаға қосу мүмкін болмады',
			'collections.created' => 'Топтама жасалды',
			'collections.removeFromCollection' => 'Топтамадан өшіру',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" осы топтамадан өшірілсін бе?',
			'collections.removedFromCollection' => 'Топтамадан өшірілді',
			'collections.removeFromCollectionFailed' => 'Топтамадан өшіру мүмкін болмады',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Өшіру қатесі: ${error}',
			'collections.searchCollections' => 'Топтамалардан іздеу...',
			'playlists.title' => 'Ойнату тізімдері',
			'playlists.playlist' => 'Ойнату тізімі',
			'playlists.noPlaylists' => 'Ойнату тізімдері табылмады',
			'playlists.create' => 'Ойнату тізімін жасау',
			'playlists.playlistName' => 'Ойнату тізімінің атауы',
			'playlists.enterPlaylistName' => 'Тізім атауын енгізіңіз',
			'playlists.delete' => 'Ойнату тізімін өшіру',
			'playlists.removeItem' => 'Тізімнен өшіру',
			'playlists.smartPlaylist' => 'Ақылды ойнату тізімі',
			'playlists.itemCount' => ({required Object count}) => '${count} элемент',
			'playlists.oneItem' => '1 элемент',
			'playlists.emptyPlaylist' => 'Бұл ойнату тізімі бос',
			'playlists.deleteConfirm' => 'Ойнату тізімі өшірілсін бе?',
			'playlists.deleteMessage' => ({required Object name}) => '"${name}" өшірілсін бе?',
			'playlists.created' => 'Ойнату тізімі жасалды',
			'playlists.deleted' => 'Ойнату тізімі өшірілді',
			'playlists.itemAdded' => 'Тізімге қосылды',
			'playlists.itemRemoved' => 'Тізімнен өшірілді',
			'playlists.selectPlaylist' => 'Тізімді таңдау',
			'playlists.searchPlaylists' => 'Ойнату тізімдерінен іздеу...',
			'playlists.errorCreating' => 'Тізімді жасау мүмкін болмады',
			'playlists.errorDeleting' => 'Тізімді өшіру мүмкін болмады',
			'playlists.errorLoading' => 'Тізімдерді жүктеу мүмкін болмады',
			'playlists.errorAdding' => 'Тізімге қосу мүмкін болмады',
			'playlists.errorReordering' => 'Қайта реттеу мүмкін болмады',
			'playlists.errorRemoving' => 'Тізімнен өшіру мүмкін болмады',
			'music.goToAlbum' => 'Альбомға өту',
			'music.goToArtist' => 'Орындаушыға өту',
			'music.instantMix' => 'Сәттік микс',
			'music.playNext' => 'Келесіні ойнату',
			'music.addToQueue' => 'Кезекке қосу',
			'music.discNumber' => ({required Object n}) => '${n}-диск',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('kk'))(n, one: '${n} ән', other: '${n} ән', ), 
			'music.nowPlaying' => 'Қазір ойнатылуда',
			'music.playingFrom' => ({required Object title}) => '${title} дереккөзінен',
			'music.queue' => 'Кезек',
			'music.clearQueue' => 'Кезекті тазалау',
			'music.lyrics' => 'Ән мәтіні',
			'music.noLyrics' => 'Ән мәтіні жоқ',
			'music.sleepTimer' => 'Ұйқы таймері',
			'music.sleepTimerEndOfTrack' => 'Әннің соңы',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} минут',
			'music.stopPlayback' => 'Ойнатуды тоқтату',
			'music.previousTrack' => 'Алдыңғы ән',
			'music.nextTrack' => 'Келесі ән',
			'music.repeat' => 'Қайталау',
			'music.repeatAll' => 'Барлығын қайталау',
			'music.repeatOne' => 'Біреуін қайталау',
			'watchTogether.title' => 'Бірге көру',
			'watchTogether.description' => 'Достарыңызбен бірге көріңіз',
			'watchTogether.createSession' => 'Сеанс жасау',
			'watchTogether.creating' => 'Жасалуда...',
			'watchTogether.joinSession' => 'Сеансқа қосылу',
			'watchTogether.joining' => 'Қосылуда...',
			'watchTogether.controlMode' => 'Басқару режимі',
			'watchTogether.controlModeQuestion' => 'Ойнатуды кім басқара алады?',
			'watchTogether.hostOnly' => 'Тек ұйымдастырушы',
			'watchTogether.anyone' => 'Кез келген адам',
			'watchTogether.hostingSession' => 'Сеанс ұйымдастырылуда',
			'watchTogether.inSession' => 'Сеанста',
			'watchTogether.sessionCode' => 'Сеанс коды',
			'watchTogether.openSessionControls' => 'Басқару элементтерін ашу',
			'watchTogether.copySessionCode' => 'Сеанс кодын көшіру',
			'watchTogether.hostControlsPlayback' => 'Ойнатуды ұйымдастырушы басқарады',
			'watchTogether.anyoneCanControl' => 'Ойнатуды кез келген адам басқара алады',
			'watchTogether.hostControls' => 'Ұйымдастырушы басқарады',
			'watchTogether.anyoneControls' => 'Барлығы басқарады',
			'watchTogether.participants' => 'Қатысушылар',
			'watchTogether.host' => 'Ұйымдастырушы',
			'watchTogether.hostBadge' => 'ҰЙЫМДАСТЫРУШЫ',
			'watchTogether.youAreHost' => 'Сіз ұйымдастырушысыз',
			'watchTogether.watchingWithOthers' => 'Басқалармен бірге көрілуде',
			'watchTogether.endSession' => 'Сеансты аяқтау',
			'watchTogether.leaveSession' => 'Сеанстан шығу',
			'watchTogether.endSessionQuestion' => 'Сеанс аяқталсын ба?',
			'watchTogether.leaveSessionQuestion' => 'Сеанстан шығасыз ба?',
			'watchTogether.endSessionConfirm' => 'Бұл барлық қатысушылар үшін сеансты аяқтайды.',
			'watchTogether.leaveSessionConfirm' => 'Сіз сеанстан ажыратыласыз.',
			'watchTogether.endSessionConfirmOverlay' => 'Бұл барлығы үшін көру сеансын аяқтайды.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Көру сеансынан ажыратыласыз.',
			'watchTogether.end' => 'Аяқтау',
			'watchTogether.leave' => 'Шығу',
			'watchTogether.syncing' => 'Синхрондалуда...',
			'watchTogether.joinWatchSession' => 'Көру сеансына қосылу',
			'watchTogether.enterCodeHint' => '5 таңбалы кодты енгізіңіз',
			'watchTogether.pasteFromClipboard' => 'Алмасу буферінен қою',
			'watchTogether.pleaseEnterCode' => 'Сеанс кодын енгізіңіз',
			_ => null,
		} ?? switch (path) {
			'watchTogether.codeMustBe5Chars' => 'Сеанс коды 5 таңбадан тұруы керек',
			'watchTogether.joinInstructions' => 'Ұйымдастырушының сеанс кодын енгізіңіз.',
			'watchTogether.failedToCreate' => 'Сеансты жасау мүмкін болмады',
			'watchTogether.failedToJoin' => 'Сеансқа қосылу мүмкін болмады',
			'watchTogether.sessionCodeCopied' => 'Сеанс коды көшірілді',
			'watchTogether.relayUnreachable' => 'Реле сервері қолжетімсіз.',
			'watchTogether.reconnectingToHost' => 'Ұйымдастырушыға қайта қосылуда...',
			'watchTogether.currentPlayback' => 'Ағымдағы ойнату',
			'watchTogether.joinCurrentPlayback' => 'Ағымдағы ойнатуға қосылу',
			'watchTogether.joinCurrentPlaybackDescription' => 'Ұйымдастырушы көріп жатқан жерге өту',
			'watchTogether.failedToOpenCurrentPlayback' => 'Ағымдағы ойнатуды ашу мүмкін болмады',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} қосылды',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} шықты',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} кідіртті',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} жалғастырды',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} уақытты өзгертті',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} буферлеуде',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} ескі нұсқада',
			'watchTogether.resumingWithout' => ({required Object name}) => '${name} ескерусіз жалғастырылуда',
			'watchTogether.waitingForParticipants' => 'Басқалардың жүктеуін күтуде...',
			'watchTogether.waitingForName' => ({required Object name}) => '${name} күтілуде...',
			'watchTogether.recentRooms' => 'Соңғы бөлмелер',
			'watchTogether.renameRoom' => 'Бөлме атын өзгерткіңіз келе ме?',
			'watchTogether.removeRoom' => 'Өшіру',
			'watchTogether.guestSwitchUnavailable' => 'Ауысу мүмкін болмады',
			'watchTogether.guestSwitchFailed' => 'Ауысу мүмкін болмады — мазмұн табылмады',
			'downloads.title' => 'Жүктеулер',
			'downloads.manage' => 'Басқару',
			'downloads.tvShows' => 'TV Шоулар',
			'downloads.movies' => 'Фильмдер',
			'downloads.music' => 'Музыка',
			'downloads.tracksQueued' => ({required Object count}) => '${count} ән жүктеу кезегіне қосылды',
			'downloads.noDownloads' => 'Әлі де жүктеулер жоқ',
			'downloads.noDownloadsDescription' => 'Жүктелген файлдар офлайн көру үшін мұнда көрінеді',
			'downloads.downloadNow' => 'Жүктеу',
			'downloads.deleteDownload' => 'Жүктеуді өшіру',
			'downloads.retryDownload' => 'Жүктеуді қайталау',
			'downloads.downloadQueued' => 'Жүктеу кезекке қойылды',
			'downloads.downloadResumed' => 'Жүктеу жалғастырылды',
			'downloads.serverErrorBitrate' => 'Сервер қатесі: файл жылдамдық шегінен асуы мүмкін',
			'downloads.storageFull' => 'Жады толы болғандықтан жүктеу тоқтатылды.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} бөлім жүктеу кезегіне қосылды',
			'downloads.downloadDeleted' => 'Жүктеу өшірілді',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" осы құрылғыдан өшірілсін бе?',
			'downloads.cancelledDownloadTitle' => 'Тоқтатылған жүктеу',
			'downloads.cancelledDownloadMessage' => 'Бұл жүктеу тоқтатылды.',
			'downloads.allEpisodesAlreadyDownloaded' => 'Барлық бөлімдер бұрыннан жүктелген',
			'downloads.resumeDownload' => 'Жүктеуді жалғастыру',
			'downloads.cancelledDownload' => 'Тоқтатылған жүктеу',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} синхрондалуда)',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Жүктелді ${file} - Аяқтау үшін түртіңіз',
			'downloads.partialDownloadClickToComplete' => 'Жартылай жүктелді - Аяқтау үшін түртіңіз',
			'downloads.deleting' => 'Өшірілуде...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} өшірілуде... (${current} / ${total})',
			'downloads.queuedTooltip' => 'Кезекте',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Кезектегі файлдар: ${files}',
			'downloads.downloadingTooltip' => 'Жүктелуде...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Жүктеліп жатқан файлдар: ${files}',
			'downloads.noDownloadsTree' => 'Жүктеулер жоқ',
			'downloads.pauseAll' => 'Барлығын кідірту',
			'downloads.resumeAll' => 'Барлығын жалғастыру',
			'downloads.deleteAll' => 'Барлығын өшіру',
			'downloads.selectVersion' => 'Нұсқаны таңдау',
			'downloads.allEpisodes' => 'Барлық бөлімдер',
			'downloads.unwatchedOnly' => 'Тек көрілмегендер',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Келесі ${count} көрілмеген',
			'downloads.customAmount' => 'Арнайы мөлшер...',
			'downloads.includeSpecials' => 'Арнайы бөлімдерді қосу',
			'downloads.howManyEpisodes' => 'Қанша бөлім?',
			'downloads.invalidEpisodeCount' => 'Дұрыс бөлім санын енгізіңіз.',
			'downloads.keepSynced' => 'Синхрондалған күйде ұстау',
			'downloads.downloadOnce' => 'Бір рет жүктеу',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} көрілмеген бөлімді сақтау',
			'downloads.editSyncRule' => 'Синхрондау ережесін өңдеу',
			'downloads.removeSyncRule' => 'Синхрондау ережесін өшіру',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '"${title}" синхрондауы тоқтатылсын ба? Жүктелген бөлімдер сақталады.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '"${title}" синхрондауы тоқтатылсын ба?',
			'downloads.deleteSyncRuleDownloads' => 'Байланысты жүктеулерді де жою',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Басқа синхрондау ережесі немесе профилі пайдаланатын жүктеулер сақталады.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Синхрондау ережесі жасалды — ${count} көрілмеген бөлім сақталады',
			'downloads.syncRuleUpdated' => 'Синхрондау ережесі жаңартылды',
			'downloads.syncRuleRemoved' => 'Синхрондау ережесі өшірілді',
			'downloads.syncRuleAndDownloadsRemoved' => 'Синхрондау ережесі және байланысты жүктеулер өшірілді',
			'downloads.syncRuleCleanupBusy' => 'Синхрондау ережелері қазір жаңартылуда. Сәлден соң қайталап көріңіз.',
			'downloads.syncRuleCleanupUnavailable' => 'Байланысты жүктеулерді қауіпсіз анықтау мүмкін болмады. Серверге қайта қосылып көріңіз немесе ережені жүктеулерді жоймай өшіріңіз.',
			'downloads.syncedNewEpisodes' => ({required Object title, required Object count}) => '${title} үшін ${count} жаңа бөлім синхрондалды',
			'downloads.activeSyncRules' => 'Белсенді синхрондау ережелері',
			'downloads.noSyncRules' => 'Синхрондау ережелері жоқ',
			'downloads.manageSyncRule' => 'Синхрондауды басқару',
			'downloads.editEpisodeCount' => 'Бөлімдер саны',
			'downloads.editSyncFilter' => 'Синхрондау фильтрі',
			'downloads.syncAllItems' => 'Барлық элементтер синхрондалады',
			'downloads.syncUnwatchedItems' => 'Көрілмеген элементтер синхрондалады',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Сервер: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Қолжетімді',
			'downloads.syncRuleOffline' => 'Офлайн',
			'downloads.syncRuleSignInRequired' => 'Кіру қажет',
			'downloads.syncRuleNotAvailableForProfile' => 'Ағымдағы профиль үшін қолжетімсіз',
			'downloads.syncRuleUnknownServer' => 'Белгісіз сервер',
			'downloads.syncRuleListCreated' => 'Синхрондау ережесі жасалды',
			'downloads.backgroundWarning.bannerBlocked' => 'Қолданбадан шыққанда жүктеулер тоқтайды',
			'downloads.backgroundWarning.bannerDegraded' => 'Фондық жүктеулер шектелуі мүмкін',
			'downloads.backgroundWarning.bannerAction' => 'Толығырақ',
			'downloads.backgroundWarning.sheetTitle' => 'Фондық жүктеулер бұғатталған',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Фондық жүктеулер шектелуі мүмкін',
			'downloads.backgroundWarning.sheetIntro' => 'Android Plezy-дің фонда сенімді жүктеуіне кедергі келтіруде.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Құрылғыңыз Plezy-дің фонда қашан жүктей алатынын шектеп отыр.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Plezy-дің фондық жұмысы шектелген. Батарея немесе фондық пайдалануды "Шектеусіз" етіп қойыңыз.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android Plezy-ді шектеулі күту режиміне ауыстырды. Батарея пайдалануын "Шектеусіз" етіп қойыңыз.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Жүктеу хабарландырулары өшірілген, сондықтан жүктеу барысы мен басқару элементтері қолжетімсіз болуы мүмкін.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Хабарландырулар өшірілген. Android 13 және одан жаңа нұсқаларда ұзақ фондық жүктеулер үшін олар қажет.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Трафикті үнемдеу қосулы, бұл мобильді деректер арқылы фондық жүктеулерді бұғаттайды. Wi-Fi арқылы жүктеулер жұмыс істеуі тиіс.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Plezy фонда тұрғанда жүктеулер бірнеше рет тоқтады. Plezy-дің батарея немесе фондық пайдалану баптауларын тексеріңіз.',
			'downloads.backgroundWarning.openSettings' => 'Баптауларды ашу',
			'downloads.backgroundWarning.stillNotWorking' => 'Құрылғыға арналған көмек',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Құрылғыңызға арналған қадамдарды қараңыз немесе мәселе жалғасса Баптаулар › Журналдарды көру бөлімінен журнал жіберіңіз.',
			'downloads.backgroundWarning.dialogTitle' => 'Жүктеулер аяқталмауы мүмкін',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Сонда да жүктеу',
			'downloads.backgroundWarning.dialogFixFirst' => 'Алдымен осыны түзету',
			'downloads.backgroundWarning.statusTile' => 'Фондық жүктеулер',
			'downloads.backgroundWarning.statusOk' => 'Фонда жұмыс істеуге рұқсат етілген',
			'downloads.backgroundWarning.statusBlocked' => 'Жүйе баптаулары бұғаттаған',
			'downloads.backgroundWarning.statusDegraded' => 'Жүйе баптаулары шектеген',
			'downloads.backgroundWarning.statusUnknown' => 'Әлі тексерілмеген',
			'downloads.backgroundWarning.settingsUnavailable' => 'Бұл құрылғыда жүйе баптаулары ашылмады',
			'downloads.backgroundWarning.linkUnavailable' => 'Бұл құрылғыда dontkillmyapp.com ашылмады',
			'shaders.title' => 'Шейдерлер',
			'shaders.noShaderDescription' => 'Видеоны жақсарту өшірілген',
			'shaders.nvscalerDescription' => 'Анығырақ видео үшін NVIDIA масштабы',
			'shaders.artcnnVariantNeutral' => 'Нейтралды',
			'shaders.artcnnVariantDenoise' => 'Шуды азайту',
			'shaders.artcnnVariantDenoiseSharpen' => 'Шуды азайту + Анықтық',
			'shaders.qualityFast' => 'Жылдам',
			'shaders.qualityHQ' => 'Жоғары сапа',
			'shaders.mode' => 'Режим',
			'shaders.importShader' => 'Шейдерді импорттау',
			'shaders.customShaderDescription' => 'Арнайы GLSL шейдері',
			'shaders.shaderImported' => 'Шейдер импортталды',
			'shaders.shaderImportFailed' => 'Шейдерді импорттау мүмкін болмады',
			'shaders.deleteShader' => 'Шейдерді өшіру',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}" өшірілсін бе?',
			'companionRemote.title' => 'Көмекші пульт',
			'companionRemote.connectedTo' => ({required Object name}) => '${name} құрылғысына қосылды',
			'companionRemote.unknownDevice' => 'Белгісіз құрылғы',
			'companionRemote.session.startingServer' => 'Пульт сервері іске қосылуда...',
			'companionRemote.session.hostAddress' => 'Хост мекенжайы',
			'companionRemote.session.connected' => 'Қосылды',
			'companionRemote.session.serverRunning' => 'Сервер белсенді',
			'companionRemote.session.serverStopped' => 'Сервер тоқтатылды',
			'companionRemote.session.serverRunningDescription' => 'Желідегі мобильді құрылғылар қосыла алады',
			'companionRemote.session.serverStoppedDescription' => 'Қосылуға рұқсат беру үшін серверді іске қосыңыз',
			'companionRemote.session.usePhoneToControl' => 'Осы қолданбаны басқару үшін телефоныңызды пайдаланыңыз',
			'companionRemote.session.startServer' => 'Серверді іске қосу',
			'companionRemote.session.stopServer' => 'Серверді тоқтату',
			'companionRemote.session.minimize' => 'Жию',
			'companionRemote.pairing.discoveryDescription' => 'Бірдей Plex тіркелгісіндегі Plezy құрылғылары мұнда көрінеді',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Қосылуда...',
			'companionRemote.pairing.searchingForDevices' => 'Құрылғылар ізделуде...',
			'companionRemote.pairing.noDevicesFound' => 'Желіде құрылғылар табылмады',
			'companionRemote.pairing.noDevicesHint' => 'ПК-де Plezy-ді ашып, бір Wi-Fi-ға қосылыңыз',
			'companionRemote.pairing.availableDevices' => 'Қолжетімді құрылғылар',
			'companionRemote.pairing.manualConnection' => 'Қолмен қосылу',
			'companionRemote.pairing.cryptoInitFailed' => 'Қауіпсіз қосылым қатесі. Алдымен Plex-ке кіріңіз.',
			'companionRemote.pairing.validationHostRequired' => 'Хост мекенжайын енгізіңіз',
			'companionRemote.pairing.validationHostFormat' => 'Формат IP:порт түрінде болуы керек',
			'companionRemote.pairing.connectionTimedOut' => 'Қосылу уақыты өтті.',
			'companionRemote.pairing.sessionNotFound' => 'Құрылғы табылмады.',
			'companionRemote.pairing.authFailed' => 'Аутентификация қатесі.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Қосылу мүмкін болмады: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Пульт сеансынан ажырайсыз ба?',
			'companionRemote.remote.reconnecting' => 'Қайта қосылуда...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Әрекет ${current} / 5',
			'companionRemote.remote.retryNow' => 'Қазір қайталау',
			'companionRemote.remote.tabRemote' => 'Пульт',
			'companionRemote.remote.tabPlay' => 'Ойнату',
			'companionRemote.remote.tabMore' => 'Тағы',
			'companionRemote.remote.menu' => 'Мәзір',
			'companionRemote.remote.tabNavigation' => 'Навигация',
			'companionRemote.remote.tabDiscover' => 'Шолу',
			'companionRemote.remote.tabLibraries' => 'Кітапханалар',
			'companionRemote.remote.tabSearch' => 'Іздеу',
			'companionRemote.remote.tabDownloads' => 'Жүктеулер',
			'companionRemote.remote.tabSettings' => 'Баптаулар',
			'companionRemote.remote.previous' => 'Алдыңғы',
			'companionRemote.remote.playPause' => 'Ойнату/Кідірту',
			'companionRemote.remote.next' => 'Келесі',
			'companionRemote.remote.seekBack' => 'Артқа айналдыру',
			'companionRemote.remote.stop' => 'Тоқтату',
			'companionRemote.remote.seekForward' => 'Алға айналдыру',
			'companionRemote.remote.volume' => 'Дыбыс',
			'companionRemote.remote.volumeDown' => 'Азайту',
			'companionRemote.remote.volumeUp' => 'Көбейту',
			'companionRemote.remote.fullscreen' => 'Толық экран',
			'companionRemote.remote.subtitles' => 'Субтитрлер',
			'companionRemote.remote.audio' => 'Дыбыс',
			'companionRemote.remote.searchHint' => 'ПК-де іздеу...',
			'companionRemote.errors.noNetworkInterface' => 'Желілік интерфейс табылмады',
			'companionRemote.errors.authenticationFailed' => 'Аутентификация қатесі',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Серверді іске қосу қатесі: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Пәрменді жіберу қатесі: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Қосылу уақыты өтті',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Ешбір мекенжайға қосылу мүмкін болмады',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => '${attempts} әрекеттен кейін байланыс үзілді',
			'companionRemote.errors.connectionLost' => 'Байланыс үзілді',
			'videoSettings.playbackSpeed' => 'Ойнату жылдамдығы',
			'videoSettings.normalSpeed' => 'Қалыпты',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Белсенді (${duration})',
			'videoSettings.zoom' => 'Масштаб',
			'videoSettings.sleepTimer' => 'Ұйқы таймері',
			'videoSettings.audioSync' => 'Аудио синхрондау',
			'videoSettings.subtitleSync' => 'Субтитр синхрондау',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Аудио шығысы',
			'videoSettings.performanceOverlay' => 'Өнімділік панелі',
			'videoSettings.audioPassthrough' => 'Дыбысты тікелей өткізу',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Көлемді дыбыс',
			'videoSettings.audioOutputSpatial' => 'Кеңістіктік дыбыс',
			'videoSettings.audioOutputStereo' => 'Стерео',
			'videoSettings.audioNormalization' => 'Дыбыс деңгейін нормалау',
			'videoSettings.audioDownmix' => 'Стереоға түрлендіру',
			'performanceOverlay.color' => 'Түс',
			'performanceOverlay.performance' => 'Өнімділік',
			'performanceOverlay.buffer' => 'Буфер',
			'performanceOverlay.app' => 'Қолданба',
			'performanceOverlay.decoder' => 'Декодер',
			'performanceOverlay.rawDecoder' => 'Өңделмеген декодер',
			'performanceOverlay.tunneling' => 'Туннельдеу',
			'performanceOverlay.aspect' => 'Қатынас',
			'performanceOverlay.rotation' => 'Бұрылыс',
			'performanceOverlay.dvSource' => 'DV дереккөзі',
			'performanceOverlay.dvPath' => 'DV жолы',
			'performanceOverlay.p7Conversion' => 'P7 түрлендіруі',
			'performanceOverlay.sampleRate' => 'Дискретизация жиілігі',
			'performanceOverlay.pixelFormat' => 'Пиксель форматы',
			'performanceOverlay.hwFormat' => 'HW форматы',
			'performanceOverlay.matrix' => 'Матрица',
			'performanceOverlay.primaries' => 'Негізгі түстер',
			'performanceOverlay.transfer' => 'Беріліс',
			'performanceOverlay.renderFps' => 'Рендер FPS',
			'performanceOverlay.displayFps' => 'Дисплей FPS',
			'performanceOverlay.avSync' => 'A/V синхрондау',
			'performanceOverlay.dropped' => 'Өткізілген кадрлар',
			'performanceOverlay.dvRpus' => 'DV RPU-лар',
			'performanceOverlay.dvRpuAverage' => 'DV RPU Орт.',
			'performanceOverlay.dvSampleAverage' => 'DV Үлгі Орт.',
			'performanceOverlay.maxLuma' => 'Макс Luma',
			'performanceOverlay.minLuma' => 'Мин Luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Пайдаланылған кэш',
			'performanceOverlay.cacheLimit' => 'Кэш шегі',
			'performanceOverlay.speed' => 'Жылдамдық',
			'performanceOverlay.player' => 'Ойнатқыш',
			'performanceOverlay.memory' => 'Жады',
			'performanceOverlay.uiFps' => 'Интерфейс (UI) FPS',
			'externalPlayer.title' => 'Сыртқы ойнатқыш',
			'externalPlayer.useExternalPlayer' => 'Сыртқы ойнатқышты пайдалану',
			'externalPlayer.useExternalPlayerDescription' => 'Видеоларды басқа қолданбада ашу',
			'externalPlayer.selectPlayer' => 'Ойнатқышты таңдау',
			'externalPlayer.customPlayers' => 'Арнайы ойнатқыштар',
			'externalPlayer.systemDefault' => 'Жүйелік әдепкі',
			'externalPlayer.addCustomPlayer' => 'Арнайы ойнатқыш қосу',
			'externalPlayer.playerName' => 'Ойнатқыш атауы',
			'externalPlayer.playerNameHint' => 'Менің ойнатқышым',
			'externalPlayer.playerCommand' => 'Пәрмен',
			'externalPlayer.playerPackage' => 'Пакет атауы',
			'externalPlayer.playerUrlScheme' => 'URL схемасы',
			'externalPlayer.off' => 'Өшірулі',
			'externalPlayer.launchFailed' => 'Сыртқы ойнатқышты іске қосу мүмкін болмады',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} орнатылмаған',
			'externalPlayer.playInExternalPlayer' => 'Сыртқы ойнатқышта ойнату',
			'metadataEdit.editMetadata' => 'Өңдеу...',
			'metadataEdit.screenTitle' => 'Метадеректерді өңдеу',
			'metadataEdit.basicInfo' => 'Негізгі ақпарат',
			'metadataEdit.artwork' => 'Суреттер/Постерлер',
			'metadataEdit.advancedSettings' => 'Кеңейтілген баптаулар',
			'metadataEdit.title' => 'Атауы',
			'metadataEdit.sortTitle' => 'Сұрыптау атауы',
			'metadataEdit.originalTitle' => 'Түпнұсқа атауы',
			'metadataEdit.releaseDate' => 'Шыққан күні',
			'metadataEdit.contentRating' => 'Мазмұн рейтингі',
			'metadataEdit.studio' => 'Студия',
			'metadataEdit.tagline' => 'Ұран/Слоган',
			'metadataEdit.summary' => 'Сипаттамасы/Күйі',
			'metadataEdit.poster' => 'Постер',
			'metadataEdit.background' => 'Фон',
			'metadataEdit.logo' => 'Логотип',
			'metadataEdit.squareArt' => 'Шаршы сурет',
			'metadataEdit.selectPoster' => 'Постерді таңдау',
			'metadataEdit.selectBackground' => 'Фонды таңдау',
			'metadataEdit.selectLogo' => 'Логотипті таңдау',
			'metadataEdit.selectSquareArt' => 'Шаршы суретті таңдау',
			'metadataEdit.fromUrl' => 'URL арқылы',
			'metadataEdit.uploadFile' => 'Файлды жүктеу',
			'metadataEdit.enterImageUrl' => 'Сурет URL-ін енгізіңіз',
			'metadataEdit.imageUrl' => 'Сурет URL-і',
			'metadataEdit.metadataUpdated' => 'Метадеректер жаңартылды',
			'metadataEdit.metadataUpdateFailed' => 'Метадеректерді жаңарту мүмкін болмады',
			'metadataEdit.artworkUpdated' => 'Суреттер жаңартылды',
			'metadataEdit.artworkUpdateFailed' => 'Суреттерді жаңарту мүмкін болмады',
			'metadataEdit.noArtworkAvailable' => 'Сурет қолжетімсіз',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Сурет опциясы ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Сурет опциясы ${index}, таңдалды',
			'metadataEdit.notSet' => 'Орнатылмаған',
			'metadataEdit.libraryDefault' => 'Кітапхана әдепкісі',
			'metadataEdit.accountDefault' => 'Тіркелгі әдепкісі',
			'metadataEdit.seriesDefault' => 'Сериал әдепкісі',
			'metadataEdit.episodeSorting' => 'Бөлімдерді сұрыптау',
			'metadataEdit.oldestFirst' => 'Басында ескілері',
			'metadataEdit.newestFirst' => 'Басында жаңалары',
			'metadataEdit.keep' => 'Сақтау',
			'metadataEdit.allEpisodes' => 'Барлық бөлімдер',
			'metadataEdit.latestEpisodes' => ({required Object count}) => 'Соңғы ${count} бөлім',
			'metadataEdit.latestEpisode' => 'Соңғы бөлім',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Соңғы ${count} күнде қосылған бөлімдер',
			'metadataEdit.deleteAfterPlaying' => 'Ойнатқаннан кейін өшіру',
			'metadataEdit.never' => 'Ешқашан',
			'metadataEdit.afterADay' => 'Бір күннен кейін',
			'metadataEdit.afterAWeek' => 'Бір аптадан кейін',
			'metadataEdit.afterAMonth' => 'Бір айдан кейін',
			'metadataEdit.onNextRefresh' => 'Келесі жаңартуда',
			'metadataEdit.seasons' => 'Маусымдар',
			'metadataEdit.show' => 'Көрсету',
			'metadataEdit.hide' => 'Жасыру',
			'metadataEdit.episodeOrdering' => 'Бөлімдер реті',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Эфир)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Эфир)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Абсолютті)',
			'metadataEdit.metadataLanguage' => 'Метадеректер тілі',
			'metadataEdit.useOriginalTitle' => 'Түпнұсқа атауын пайдалану',
			'metadataEdit.preferredAudioLanguage' => 'Қалаулы аудио тілі',
			'metadataEdit.preferredSubtitleLanguage' => 'Қалаулы субтитр тілі',
			'metadataEdit.subtitleMode' => 'Автоматты субтитр таңдау режимі',
			'metadataEdit.manuallySelected' => 'Қолмен таңдалған',
			'metadataEdit.shownWithForeignAudio' => 'Шетелдік аудио кезінде көрсетіледі',
			'metadataEdit.alwaysEnabled' => 'Әрдайым қосулы',
			'metadataEdit.tags' => 'Тегтер',
			'metadataEdit.addTag' => 'Тег қосу',
			'metadataEdit.genre' => 'Жанр',
			'metadataEdit.director' => 'Режиссер',
			'metadataEdit.writer' => 'Сценарист',
			'metadataEdit.producer' => 'Продюсер',
			'metadataEdit.country' => 'Ел',
			'metadataEdit.collection' => 'Топтама',
			'metadataEdit.label' => 'Белгі',
			'metadataEdit.style' => 'Стиль',
			'metadataEdit.mood' => 'Көңіл-күй',
			'matchScreen.match' => 'Сәйкестендіру...',
			'matchScreen.fixMatch' => 'Сәйкестікті түзету...',
			'matchScreen.unmatch' => 'Сәйкестікті жою',
			'matchScreen.unmatchConfirm' => 'Бұл сәйкестік жойылсын ба?',
			'matchScreen.unmatchSuccess' => 'Сәйкестік жойылды',
			'matchScreen.unmatchFailed' => 'Сәйкестікті жою мүмкін болмады',
			'matchScreen.matchApplied' => 'Сәйкестік қолданылды',
			'matchScreen.matchFailed' => 'Сәйкестікті қолдану мүмкін болмады',
			'matchScreen.titleHint' => 'Атауы',
			'matchScreen.yearHint' => 'Жыл',
			'matchScreen.search' => 'Іздеу',
			'matchScreen.noMatchesFound' => 'Сәйкестіктер табылмады',
			'serverTasks.title' => 'Сервер тапсырмалары',
			'serverTasks.failedToLoad' => 'Тапсырмаларды жүктеу мүмкін болмады',
			'serverTasks.noTasks' => 'Орындалып жатқан тапсырмалар жоқ',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Қосылды',
			'trakt.connectedAs' => ({required Object username}) => '@${username} ретінде қосылды',
			'trakt.disconnectConfirm' => 'Trakt ажыратылсын ба?',
			'trakt.disconnectConfirmBody' => 'Plezy Trakt-қа деректер жіберуді тоқтатады.',
			'trakt.scrobble' => 'Нақты уақытта бақылау',
			'trakt.scrobbleDescription' => 'Ойнату кезінде Trakt-қа деректер жіберу.',
			'trakt.watchedSync' => 'Көру мәртебесін синхрондау',
			'trakt.watchedSyncDescription' => 'Plezy-де белгіленгенде Trakt-та да белгіленеді.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr қосу',
			'seerr.serverUrl' => 'Сервер URL-і',
			'seerr.serverUrlHelper' => 'Seerr мекенжайыңыз',
			'seerr.checkServer' => 'Жалғастыру',
			'seerr.signInWithJellyfin' => 'Jellyfin арқылы кіру',
			'seerr.signInWithEmby' => 'Emby арқылы кіру',
			'seerr.signInWithLocal' => 'Жергілікті тіркелгіні пайдалану',
			'seerr.email' => 'Электрондық пошта',
			'seerr.noSignInMethods' => 'Бұл Seerr қолдау көрсетілетін кіру әдісін ұсынбайды.',
			'seerr.instance' => 'Инстанция',
			'seerr.disconnectConfirm' => 'Seerr ажыратылсын ба?',
			'seerr.disconnectConfirmBody' => 'Plezy бұл Seerr мекенжайын өшіреді.',
			'seerr.request' => 'Сұрау салу',
			'seerr.request4k' => '4K сұрау салу',
			'seerr.seasons' => 'Маусымдар',
			'seerr.allSeasons' => 'Барлық маусымдар',
			'seerr.advancedOptions' => 'Кеңейтілген',
			'seerr.destinationServer' => 'Нысаналы сервер',
			'seerr.qualityProfile' => 'Сапа профилі',
			'seerr.rootFolder' => 'Түпкі қапшық',
			'seerr.languageProfile' => 'Тіл профилі',
			'seerr.requestSubmitted' => 'Сұрау жіберілді',
			'seerr.requestFailed' => ({required Object error}) => 'Сұрау қатесі: ${error}',
			'seerr.requestsLoadFailed' => 'Параметрлерді жүктеу мүмкін болмады',
			'seerr.nothingToRequest' => 'Барлығы бұрыннан бар немесе сұралған.',
			'seerr.statusAvailable' => 'Қолжетімді',
			'seerr.statusPartiallyAvailable' => 'Жартылай қолжетімді',
			'seerr.statusRequested' => 'Сұралды',
			'seerr.statusProcessing' => 'Өңделуде',
			'services.title' => 'Қызметтер',
			'services.hubSubtitle' => 'Көру барысын синхрондаңыз және жаңа мазмұн сұраңыз.',
			'services.notConnected' => 'Қосылмаған',
			'services.connectedAs' => ({required Object username}) => '@${username} ретінде қосылды',
			'services.scrobble' => 'Барысты автоматты бақылау',
			'services.scrobbleDescription' => 'Тізіміңізді автоматты түрде жаңартыңыз.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} ажыратылсын ба?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy ${service} жаңартуды тоқтатады.',
			'services.connectFailed' => ({required Object service}) => '${service} қосылу мүмкін болмады. Қайтадан байқап көріңіз.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Plezy-ді ${service} қызметінде белсендіру',
			'services.deviceCode.body' => ({required Object url}) => '${url} мекенжайына өтіп, осы кодты енгізіңіз:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Белсендіру үшін ${service} ашу',
			'services.deviceCode.copyCode' => 'Белсендіру кодын көшіру',
			'services.deviceCode.waitingForAuthorization' => 'Авторизация күтілуде…',
			'services.deviceCode.codeCopied' => 'Код көшірілді',
			'services.oauthProxy.title' => ({required Object service}) => '${service} қызметіне кіру',
			'services.oauthProxy.body' => 'Осы QR кодты сканерлеңіз немесе URL-ді ашыңыз.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Кіру үшін ${service} ашу',
			'services.oauthProxy.copyUrl' => 'Кіру URL-ін көшіру',
			'services.oauthProxy.urlCopied' => 'URL көшірілді',
			'services.libraryFilter.title' => 'Кітапхана фильтрі',
			'services.libraryFilter.subtitleAllSyncing' => 'Барлық кітапханалар синхрондалуда',
			'services.libraryFilter.subtitleNoneSyncing' => 'Ештеңе синхрондалмайды',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} бұғатталды',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} рұқсат етілді',
			'services.libraryFilter.mode' => 'Фильтр режимі',
			'services.libraryFilter.modeBlacklist' => 'Қара тізім',
			'services.libraryFilter.modeWhitelist' => 'Ақ тізім',
			'services.libraryFilter.modeHintBlacklist' => 'Төменде таңдалғандардан басқа барлық кітапханаларды синхрондау.',
			'services.libraryFilter.modeHintWhitelist' => 'Тек төменде таңдалған кітапханаларды синхрондау.',
			'services.libraryFilter.libraries' => 'Кітапханалар',
			'services.libraryFilter.noLibraries' => 'Кітапханалар жоқ',
			'addServer.addJellyfinTitle' => 'Jellyfin серверін қосу',
			'addServer.serverUrls' => 'Сервер URL-дері',
			'addServer.serverUrlsHelper' => 'Үтірмен бөлінген бірнеше URL мекенжайына рұқсат етіледі.',
			'addServer.findServer' => 'Серверді табу',
			'addServer.searchingLocalServers' => 'Жергілікті Jellyfin серверлері ізделуде...',
			'addServer.localServers' => 'Жергілікті Jellyfin серверлері',
			'addServer.username' => 'Пайдаланушы аты',
			'addServer.password' => 'Құпия сөз',
			'addServer.signIn' => 'Кіру',
			'addServer.change' => 'Өзгерту',
			'addServer.required' => 'Міндетті',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Серверге қосылу мүмкін болмады: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Кіру қатесі: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Жылдам қосылу қатесі: ${error}',
			'addServer.addPlexTitle' => 'Plex арқылы кіру',
			'addServer.pinExpired' => 'PIN код мерзімі өтті.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Тіркелгіні тіркеу қатесі: ${error}',
			'addServer.enterJellyfinUrlError' => 'Jellyfin сервер URL-ін енгізіңіз',
			'addServer.addConnectionTitle' => 'Қосылым қосу',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => '${name} профиліне қосу',
			'addServer.signInWithPlexCard' => 'Plex арқылы кіру',
			'addServer.signInWithPlexCardSubtitle' => 'Осы құрылғыны авторизациялау.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex тіркелгісін авторизациялау.',
			'addServer.connectToJellyfinCard' => 'Jellyfin-ге қосылу',
			'addServer.connectToJellyfinCardSubtitle' => 'Сервер URL-ін, пайдаланушы атын енгізіңіз.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Jellyfin серверіне кіру. ${name} профиліне жалғануда.',
			'addServer.borrowFromAnotherProfile' => 'Басқа профильден алу',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Басқа профильдің қосылымын қайта пайдалану.',
			_ => null,
		};
	}
}
