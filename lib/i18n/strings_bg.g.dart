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
class TranslationsBg extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsBg({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.bg,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <bg>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsBg _root = this; // ignore: unused_field

	@override 
	TranslationsBg $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsBg(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppBg app = _TranslationsAppBg._(_root);
	@override late final _TranslationsAuthBg auth = _TranslationsAuthBg._(_root);
	@override late final _TranslationsCommonBg common = _TranslationsCommonBg._(_root);
	@override late final _TranslationsScreensBg screens = _TranslationsScreensBg._(_root);
	@override late final _TranslationsUpdateBg update = _TranslationsUpdateBg._(_root);
	@override late final _TranslationsSettingsBg settings = _TranslationsSettingsBg._(_root);
	@override late final _TranslationsSearchBg search = _TranslationsSearchBg._(_root);
	@override late final _TranslationsHotkeysBg hotkeys = _TranslationsHotkeysBg._(_root);
	@override late final _TranslationsFileInfoBg fileInfo = _TranslationsFileInfoBg._(_root);
	@override late final _TranslationsMediaMenuBg mediaMenu = _TranslationsMediaMenuBg._(_root);
	@override late final _TranslationsRateSheetBg rateSheet = _TranslationsRateSheetBg._(_root);
	@override late final _TranslationsAccessibilityBg accessibility = _TranslationsAccessibilityBg._(_root);
	@override late final _TranslationsTooltipsBg tooltips = _TranslationsTooltipsBg._(_root);
	@override late final _TranslationsVideoControlsBg videoControls = _TranslationsVideoControlsBg._(_root);
	@override late final _TranslationsMessagesBg messages = _TranslationsMessagesBg._(_root);
	@override late final _TranslationsSubtitlingStylingBg subtitlingStyling = _TranslationsSubtitlingStylingBg._(_root);
	@override late final _TranslationsMpvConfigBg mpvConfig = _TranslationsMpvConfigBg._(_root);
	@override late final _TranslationsDialogBg dialog = _TranslationsDialogBg._(_root);
	@override late final _TranslationsProfilesBg profiles = _TranslationsProfilesBg._(_root);
	@override late final _TranslationsConnectionsBg connections = _TranslationsConnectionsBg._(_root);
	@override late final _TranslationsDiscoverBg discover = _TranslationsDiscoverBg._(_root);
	@override late final _TranslationsErrorsBg errors = _TranslationsErrorsBg._(_root);
	@override late final _TranslationsLibrariesBg libraries = _TranslationsLibrariesBg._(_root);
	@override late final _TranslationsAboutBg about = _TranslationsAboutBg._(_root);
	@override late final _TranslationsServerSelectionBg serverSelection = _TranslationsServerSelectionBg._(_root);
	@override late final _TranslationsHubDetailBg hubDetail = _TranslationsHubDetailBg._(_root);
	@override late final _TranslationsLogsBg logs = _TranslationsLogsBg._(_root);
	@override late final _TranslationsLicensesBg licenses = _TranslationsLicensesBg._(_root);
	@override late final _TranslationsNavigationBg navigation = _TranslationsNavigationBg._(_root);
	@override late final _TranslationsExploreBg explore = _TranslationsExploreBg._(_root);
	@override late final _TranslationsLiveTvBg liveTv = _TranslationsLiveTvBg._(_root);
	@override late final _TranslationsCollectionsBg collections = _TranslationsCollectionsBg._(_root);
	@override late final _TranslationsPlaylistsBg playlists = _TranslationsPlaylistsBg._(_root);
	@override late final _TranslationsMusicBg music = _TranslationsMusicBg._(_root);
	@override late final _TranslationsWatchTogetherBg watchTogether = _TranslationsWatchTogetherBg._(_root);
	@override late final _TranslationsDownloadsBg downloads = _TranslationsDownloadsBg._(_root);
	@override late final _TranslationsShadersBg shaders = _TranslationsShadersBg._(_root);
	@override late final _TranslationsCompanionRemoteBg companionRemote = _TranslationsCompanionRemoteBg._(_root);
	@override late final _TranslationsVideoSettingsBg videoSettings = _TranslationsVideoSettingsBg._(_root);
	@override late final _TranslationsPerformanceOverlayBg performanceOverlay = _TranslationsPerformanceOverlayBg._(_root);
	@override late final _TranslationsExternalPlayerBg externalPlayer = _TranslationsExternalPlayerBg._(_root);
	@override late final _TranslationsMetadataEditBg metadataEdit = _TranslationsMetadataEditBg._(_root);
	@override late final _TranslationsMatchScreenBg matchScreen = _TranslationsMatchScreenBg._(_root);
	@override late final _TranslationsServerTasksBg serverTasks = _TranslationsServerTasksBg._(_root);
	@override late final _TranslationsTraktBg trakt = _TranslationsTraktBg._(_root);
	@override late final _TranslationsSeerrBg seerr = _TranslationsSeerrBg._(_root);
	@override late final _TranslationsServicesBg services = _TranslationsServicesBg._(_root);
	@override late final _TranslationsAddServerBg addServer = _TranslationsAddServerBg._(_root);
}

// Path: app
class _TranslationsAppBg extends TranslationsAppEn {
	_TranslationsAppBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthBg extends TranslationsAuthEn {
	_TranslationsAuthBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Вход с Plex';
	@override String get showQRCode => 'Покажи QR код';
	@override String get authenticate => 'Удостовери';
	@override String get authenticationTimeout => 'Времето за удостоверяване изтече. Моля, опитайте отново.';
	@override String get scanQRToSignIn => 'Сканирайте този QR код, за да влезете';
	@override String get waitingForAuth => 'Изчакване на удостоверяване...\nВлезте от браузъра си.';
	@override String get useBrowser => 'Използвай браузър';
	@override String get or => 'или';
	@override String get connectToJellyfin => 'Свързване с Jellyfin';
	@override String get useQuickConnect => 'Използвай Quick Connect';
	@override String get quickConnectInstructions => 'Отворете Quick Connect в Jellyfin и въведете този код.';
	@override String get quickConnectWaiting => 'Изчакване на одобрение…';
	@override String get quickConnectCancel => 'Отказ';
	@override String get quickConnectExpired => 'Quick Connect изтече. Опитайте отново.';
}

// Path: common
class _TranslationsCommonBg extends TranslationsCommonEn {
	_TranslationsCommonBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Отказ';
	@override String get save => 'Запази';
	@override String get close => 'Затвори';
	@override String get clear => 'Изчисти';
	@override String get reset => 'Нулирай';
	@override String get later => 'По-късно';
	@override String get submit => 'Изпрати';
	@override String get confirm => 'Потвърди';
	@override String get retry => 'Опитай отново';
	@override String get logout => 'Изход';
	@override String get unknown => 'Неизвестно';
	@override String get refresh => 'Опресни';
	@override String get yes => 'Да';
	@override String get no => 'Не';
	@override String get delete => 'Изтрий';
	@override String get edit => 'Редактирай';
	@override String get shuffle => 'Разбъркай';
	@override String get addTo => 'Добави към...';
	@override String get createNew => 'Създай нов';
	@override String get connect => 'Свържи';
	@override String get disconnect => 'Прекъсни връзката';
	@override String get play => 'Пусни';
	@override String get pause => 'Пауза';
	@override String get resume => 'Продължи';
	@override String get error => 'Грешка';
	@override String get search => 'Търсене';
	@override String get home => 'Начало';
	@override String get back => 'Назад';
	@override String get settings => 'Настройки';
	@override String get mute => 'Заглуши';
	@override String get ok => 'OK';
	@override String get off => 'Изкл.';
	@override String seasonNumber({required Object number}) => 'Сезон ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Епизод ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Глава ${number}';
	@override String get reconnect => 'Свържи отново';
	@override String get viewAll => 'Виж всички';
	@override String get checkingNetwork => 'Проверка на мрежата...';
	@override String get loadingServers => 'Зареждане на сървърите...';
	@override String get connectingToServers => 'Свързване със сървърите...';
	@override String get startingOfflineMode => 'Стартиране на офлайн режим...';
	@override String get loading => 'Зареждане...';
	@override String get fullscreen => 'На цял екран';
	@override String get exitFullscreen => 'Изход от цял екран';
	@override String get pressBackAgainToExit => 'Натиснете Назад отново, за да излезете';
}

// Path: screens
class _TranslationsScreensBg extends TranslationsScreensEn {
	_TranslationsScreensBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Лицензи';
	@override String get switchProfile => 'Смяна на профил';
	@override String get subtitleStyling => 'Стил на субтитрите';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Логове';
}

// Path: update
class _TranslationsUpdateBg extends TranslationsUpdateEn {
	_TranslationsUpdateBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get available => 'Налична е актуализация';
	@override String versionAvailable({required Object version}) => 'Налична е версия ${version}';
	@override String currentVersion({required Object version}) => 'Текуща: ${version}';
	@override String get skipVersion => 'Пропусни тази версия';
	@override String get viewRelease => 'Виж версията';
	@override String get latestVersion => 'Използвате най-новата версия';
	@override String get checkFailed => 'Неуспешна проверка за актуализации';
}

// Path: settings
class _TranslationsSettingsBg extends TranslationsSettingsEn {
	_TranslationsSettingsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Настройки';
	@override String get supportDeveloper => 'Подкрепи Plezy';
	@override String get supportDeveloperDescription => 'Дарение чрез Liberapay за финансиране на разработката';
	@override String get language => 'Език';
	@override String get theme => 'Тема';
	@override String get appearance => 'Изглед';
	@override String get videoPlayback => 'Възпроизвеждане на видео';
	@override String get videoPlaybackDescription => 'Настройване на поведението при възпроизвеждане';
	@override String get advanced => 'Разширени';
	@override String get episodePosterMode => 'Стил на постера за епизод';
	@override String get seriesPoster => 'Постер на сериала';
	@override String get seasonPoster => 'Постер на сезона';
	@override String get episodeThumbnail => 'Миниатюра';
	@override String get showHeroSectionDescription => 'Показване на карусел с избрано съдържание на началния екран';
	@override String get secondsLabel => 'Секунди';
	@override String get minutesLabel => 'Минути';
	@override String get secondsShort => 'сек';
	@override String get minutesShort => 'мин';
	@override String durationHint({required Object min, required Object max}) => 'Въведете продължителност (${min}-${max})';
	@override String get systemTheme => 'Системна';
	@override String get lightTheme => 'Светла';
	@override String get darkTheme => 'Тъмна';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Плътност на библиотеката';
	@override String get compact => 'Компактна';
	@override String get comfortable => 'Удобна';
	@override String get viewMode => 'Режим на изглед';
	@override String get gridView => 'Мрежа';
	@override String get listView => 'Списък';
	@override String get showHeroSection => 'Показвай водеща секция';
	@override String get continueWatchingAction => 'Действие за продължаване на гледането';
	@override String get continueWatchingPlay => 'Пусни';
	@override String get continueWatchingDetails => 'Отвори подробности';
	@override String get episodeAction => 'Действие за епизод';
	@override String get episodePlay => 'Пусни';
	@override String get episodeDetails => 'Отвори подробности';
	@override String get useGlobalHubs => 'Използвай начално оформление';
	@override String get useGlobalHubsDescription => 'Показвай обединени начални хъбове. В противен случай използвай препоръките на библиотеката.';
	@override String get showServerNameOnHubs => 'Показвай името на сървъра в хъбовете';
	@override String get showServerNameOnHubsDescription => 'Винаги показвай имената на сървърите в заглавията на хъбовете.';
	@override String get groupLibrariesByServer => 'Групирай библиотеките по сървър';
	@override String get groupLibrariesByServerDescription => 'Групирай библиотеките в страничната лента под всеки медиен сървър.';
	@override String get alwaysKeepSidebarOpen => 'Винаги дръж страничната лента отворена';
	@override String get alwaysKeepSidebarOpenDescription => 'Страничната лента остава разгъната и зоната със съдържание се наглася да пасне';
	@override String get showUnwatchedCount => 'Показвай броя негледани';
	@override String get showUnwatchedCountDescription => 'Показвай броя негледани епизоди при сериали и сезони';
	@override String get showEpisodeNumberOnCards => 'Показвай номера на епизода върху картите';
	@override String get showEpisodeNumberOnCardsDescription => 'Показвай сезон и номер на епизод върху картите на епизодите';
	@override String get showSeasonPostersOnTabs => 'Показвай постери на сезоните в табовете';
	@override String get showSeasonPostersOnTabsDescription => 'Показвай постера на всеки сезон над неговия таб';
	@override String get tvFullCardLayout => 'Пълни TV карти';
	@override String get tvFullCardLayoutDescription => 'Използвай TV карти само с изображения, с насложени имена на актьорите';
	@override String get focusGlow => 'Сияние при фокус';
	@override String get focusGlowDescription => 'Показвай меко сияние около фокусираната карта';
	@override String get visualEffects => 'Визуални ефекти';
	@override String get visualEffectsAuto => 'Автоматично';
	@override String get visualEffectsAutoDescription => 'Автоматично намалявай ефектите на по-слаби устройства';
	@override String get visualEffectsFull => 'Пълни';
	@override String get visualEffectsReduced => 'Намалени';
	@override String get visualEffectsReducedDescription => 'По-малко анимации и изображения с по-ниска резолюция';
	@override String get hideSpoilers => 'Скривай спойлери за негледани епизоди';
	@override String get hideSpoilersDescription => 'Замазвай миниатюри и описания за негледани епизоди';
	@override String get playerBackend => 'Енджин на плеъра';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Хардуерно декодиране';
	@override String get hardwareDecodingDescription => 'Използвай хардуерно ускорение, когато е налично';
	@override String get bufferSize => 'Размер на буфера';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Автоматично (препоръчително)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Налична памет ${heap}MB. Буфер ${size}MB може да повлияе на възпроизвеждането.';
	@override String get defaultQualityTitle => 'Качество по подразбиране';
	@override String get musicQualityTitle => 'Качество на музиката';
	@override String get subtitleStyling => 'Стил на субтитрите';
	@override String get subtitleStylingDescription => 'Настройване на вида на субтитрите';
	@override String get smallSkipDuration => 'Малко прескачане';
	@override String get largeSkipDuration => 'Голямо прескачане';
	@override String get rewindOnResume => 'Връщане назад при продължаване';
	@override String secondsUnit({required Object seconds}) => '${seconds} секунди';
	@override String get defaultSleepTimer => 'Таймер за заспиване по подразбиране';
	@override String minutesUnit({required Object minutes}) => '${minutes} минути';
	@override String get rememberTrackSelections => 'Запомняй избора на аудио/субтитри за сериал/филм';
	@override String get rememberTrackSelectionsDescription => 'Запомняй избора на аудио и субтитри за всяко заглавие';
	@override String get showChapterMarkersOnTimeline => 'Показвай маркери на глави върху времевата линия';
	@override String get showChapterMarkersOnTimelineDescription => 'Разделяй времевата линия на сегменти по границите на главите';
	@override String get clickVideoTogglesPlayback => 'Клик върху видеото превключва възпроизвеждане/пауза';
	@override String get clickVideoTogglesPlaybackDescription => 'Клик върху видеото пуска/паузира вместо да показва контролите.';
	@override String get videoPlayerControls => 'Контроли на видео плейъра';
	@override String get keyboardShortcuts => 'Клавишни комбинации';
	@override String get keyboardShortcutsDescription => 'Настройване на клавишните комбинации';
	@override String get videoPlayerNavigation => 'Навигация във видео плейъра';
	@override String get videoPlayerNavigationDescription => 'Използвай стрелките за навигация в контролите на видео плейъра';
	@override String get watchTogetherRelay => 'Релей сървър за гледане заедно';
	@override String get watchTogetherRelayDescription => 'Задай собствен релей сървър. Всички трябва да използват същия сървър.';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get crashReporting => 'Докладване на сривове';
	@override String get crashReportingDescription => 'Изпращай доклади за сривове, за да помогнеш за подобряване на приложението';
	@override String get debugLogging => 'Логове за отстраняване на грешки';
	@override String get debugLoggingDescription => 'Включи подробни логове за диагностика';
	@override String get viewLogs => 'Виж логовете';
	@override String get viewLogsDescription => 'Преглед на логовете на приложението';
	@override String get clearCache => 'Изчисти кеша';
	@override String get clearCacheDescription => 'Изчисти кешираните изображения и данни. Съдържанието може да се зарежда по-бавно.';
	@override String get clearCacheSuccess => 'Кешът е изчистен успешно';
	@override String get resetSettings => 'Нулирай настройките';
	@override String get resetSettingsDescription => 'Възстанови настройките по подразбиране. Това не може да бъде отменено.';
	@override String get resetSettingsSuccess => 'Настройките са нулирани успешно';
	@override String get backup => 'Резервно копие';
	@override String get exportSettings => 'Експортирай настройките';
	@override String get exportSettingsDescription => 'Запази предпочитанията си във файл';
	@override String get exportSettingsSuccess => 'Настройките са експортирани';
	@override String get exportSettingsFailed => 'Настройките не можаха да бъдат експортирани';
	@override String get importSettings => 'Импортирай настройки';
	@override String get importSettingsDescription => 'Възстанови предпочитания от файл';
	@override String get importSettingsConfirm => 'Това ще замени текущите ви настройки. Продължавате ли?';
	@override String get importSettingsSuccess => 'Настройките са импортирани';
	@override String get importSettingsFailed => 'Настройките не можаха да бъдат импортирани';
	@override String get importSettingsInvalidFile => 'Този файл не е валиден експорт на настройки от Plezy';
	@override String get importSettingsNoUser => 'Влезте, преди да импортирате настройки';
	@override String get shortcutsReset => 'Клавишните комбинации са нулирани до подразбиране';
	@override String get about => 'Относно';
	@override String get aboutDescription => 'Информация за приложението и лицензи';
	@override String get updates => 'Актуализации';
	@override String get updateAvailable => 'Налична е актуализация';
	@override String get checkForUpdates => 'Провери за актуализации';
	@override String get autoCheckUpdatesOnStartup => 'Автоматично проверявай за актуализации при стартиране';
	@override String get autoCheckUpdatesOnStartupDescription => 'Уведомявай, когато има актуализация при стартиране';
	@override String get validationErrorEnterNumber => 'Моля, въведете валидно число';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Продължителността трябва да е между ${min} и ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Клавишната комбинация вече е назначена за ${action}';
	@override String shortcutUpdated({required Object action}) => 'Клавишната комбинация е обновена за ${action}';
	@override String get autoSkip => 'Автоматично прескачане';
	@override String get autoSkipIntro => 'Автоматично прескачане на интро';
	@override String get autoSkipIntroDescription => 'Автоматично прескачай интро маркери след няколко секунди';
	@override String get autoSkipCredits => 'Автоматично прескачане на финални надписи';
	@override String get autoSkipCreditsDescription => 'Автоматично прескачай финалните надписи и пускай следващия епизод';
	@override String get forceSkipMarkerFallback => 'Принуди резервни маркери';
	@override String get forceSkipMarkerFallbackDescription => 'Използвай шаблони в заглавията на главите дори когато Plex има маркери';
	@override String get autoSkipDelay => 'Забавяне за автоматично прескачане';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Изчакай ${seconds} секунди преди автоматично прескачане';
	@override String get introPattern => 'Шаблон за интро маркер';
	@override String get introPatternDescription => 'Шаблон с регулярен израз за намиране на интро маркери в заглавия на глави';
	@override String get creditsPattern => 'Шаблон за маркер на финални надписи';
	@override String get creditsPatternDescription => 'Шаблон с регулярен израз за намиране на маркери за финални надписи в заглавия на глави';
	@override String get invalidRegex => 'Невалиден регулярен израз';
	@override String get regex => 'Регулярен израз';
	@override String get downloads => 'Изтегляния';
	@override String get downloadLocationDescription => 'Изберете къде да се съхранява изтегленото съдържание';
	@override String get downloadLocationDefault => 'По подразбиране (хранилище на приложението)';
	@override String get downloadLocationCustom => 'Персонална локация';
	@override String get selectFolder => 'Избери папка';
	@override String get resetToDefault => 'Върни по подразбиране';
	@override String currentPath({required Object path}) => 'Текущ: ${path}';
	@override String get downloadLocationChanged => 'Местоположението за изтегляния е променено';
	@override String get downloadLocationReset => 'Местоположението за изтегляния е върнато по подразбиране';
	@override String get downloadLocationInvalid => 'Избраната папка не е записваема';
	@override String get downloadLocationSelectError => 'Неуспешен избор на папка';
	@override String get downloadOnWifiOnly => 'Изтегляне само през WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Предотвратявай изтегляния през мобилни данни';
	@override String get autoRemoveWatchedDownloads => 'Автоматично премахвай изгледаните изтегляния';
	@override String get autoRemoveWatchedDownloadsDescription => 'Изтривай изгледаните изтегляния автоматично';
	@override String get cellularDownloadBlocked => 'Изтеглянията са блокирани през мобилни данни. Използвайте WiFi или променете настройката.';
	@override String get maxVolume => 'Максимална сила на звука';
	@override String get maxVolumeDescription => 'Позволи усилване на звука над 100% за тихи медии';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Показвай какво гледате в Discord';
	@override String get services => 'Услуги';
	@override String get servicesDescription => 'Свържи Trakt, MyAnimeList, Seerr и още';
	@override String get manageLibrariesDescription => 'Пренареждай и скривай библиотеки';
	@override String get companionRemoteServer => 'Сървър за дистанционно управление';
	@override String get companionRemoteServerDescription => 'Позволи на мобилни устройства във вашата мрежа да управляват това приложение';
	@override String get autoPip => 'Автоматичен режим картина в картината';
	@override String get autoPipDescription => 'Влизай в режим картина в картината при напускане по време на възпроизвеждане';
	@override String get matchContentFrameRate => 'Напасване към кадровата честота на съдържанието';
	@override String get matchContentFrameRateDescription => 'Напасни честотата на опресняване на дисплея към видео съдържанието';
	@override String get matchRefreshRate => 'Напасване на честотата на опресняване';
	@override String get matchRefreshRateDescription => 'Напасни честотата на опресняване на дисплея при цял екран';
	@override String get matchDynamicRange => 'Напасване на динамичния диапазон';
	@override String get matchDynamicRangeDescription => 'Включи HDR за HDR съдържание, после върни към SDR';
	@override String get displaySwitchDelay => 'Забавяне при смяна на дисплея';
	@override String get tunneledPlayback => 'Тунелно възпроизвеждане';
	@override String get tunneledPlaybackDescription => 'Използвай видео тунелиране. Изключете, ако HDR възпроизвеждането показва черен екран.';
	@override String get audioPassthrough => 'Аудио passthrough';
	@override String get audioPassthroughDescription => 'Изпращай Dolby/DTS звук към ресийвъра или телевизора без прекодиране, запазвайки съраунд звука. Изключете, ако няма звук.';
	@override String get audioPassthroughDescriptionAppleTv => 'Предава Dolby Digital Plus (вкл. Atmos) на системата като битов поток. DTS и TrueHD продължават да се възпроизвеждат като многоканален PCM. При превъртане може да има кратки прекъсвания на звука.';
	@override String get audioDownmix => 'Смесване до стерео';
	@override String get audioDownmixDescription => 'Смесва съраунд звука до два канала за стерео тонколони или слушалки';
	@override String get downmixCenterBoost => 'Усилване на централния канал';
	@override String downmixCenterBoostValue({required Object db}) => '${db} дБ';
	@override String get downmixCenterBoostLabel => 'Усилване (дБ)';
	@override String get downmixCenterBoostShort => 'дБ';
	@override String get audioDownmixNormalize => 'Нормализиране на звука при смесване';
	@override String get audioDownmixNormalizeDescription => 'Понижава микса, за да се предотврати клипинг. Изключете, за да запазите оригиналната сила на звука (възможни изкривявания при силни сцени).';
	@override String get atmosDiagnostics => 'Тест на Atmos изхода';
	@override String get atmosDiagnosticsDescription => 'Диагностика на Dolby Atmos изхода чрез възпроизвеждане на тестови сигнали през системния плейър';
	@override String get atmosTestHlsAtmos => 'Apple Atmos поток';
	@override String get atmosTestHlsAtmosDescription => 'Гарантирано работещ Dolby Atmos поток. Ресийвърът трябва да покаже Dolby Atmos.';
	@override String get atmosTestHlsControl => 'Apple съраунд поток';
	@override String get atmosTestHlsControlDescription => 'Контролен поток без Atmos. Ресийвърът трябва да покаже съраунд без Atmos.';
	@override String get atmosTestRawStream => 'Суров EAC3 поток';
	@override String get atmosTestRawStreamDescription => 'Стриймва тестовия файл точно както Atmos възпроизвеждането в плейъра. Изисква URL на тестовия файл.';
	@override String get atmosTestRawFile => 'Суров EAC3 файл';
	@override String get atmosTestRawFileDescription => 'Възпроизвежда тестовия файл с известна дължина. Изисква URL на тестовия файл.';
	@override String get atmosTestStop => 'Спри теста';
	@override String get atmosTestUrl => 'URL на тестовия файл';
	@override String get atmosTestUrlDescription => 'HTTP URL на суров .ec3 Dolby Atmos файл (напр. извлечен с ffmpeg)';
	@override String get atmosTestUrlMissing => 'Първо задайте URL на тестовия файл';
	@override String get atmosTestStatus => 'Състояние';
	@override String get dvConversionMode => 'Dolby Vision конвертиране';
	@override String get dvConversionModeDescription => 'Изберете как ExoPlayer обработва Dolby Vision Profile 7 файлове.';
	@override String get dvConversionAuto => 'Автоматично';
	@override String get dvConversionNative => 'Нативно / изключено';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Използва засичане на възможностите на устройството и нормално fallback поведение';
	@override String get dvConversionNativeDescription => 'Принуждава нативен DV7 и спира повторния опит за DV конвертиране';
	@override String get dvConversionDv81Description => 'Принуждава inline RPU конвертиране към Dolby Vision профил 8.1';
	@override String get dvConversionHevcStripDescription => 'Премахва Dolby Vision RPU/EL слоевете и подава обикновен HEVC';
	@override String get requireProfileSelectionOnOpen => 'Питай за профил при отваряне на приложението';
	@override String get requireProfileSelectionOnOpenDescription => 'Показвай избор на профил всеки път при отваряне на приложението';
	@override String get forceTvMode => 'Принуди TV режим';
	@override String get forceTvModeDescription => 'Принуди ТВ оформление. За устройства, които не се разпознават автоматично. Изисква рестарт.';
	@override String get startInFullscreen => 'Стартирай на цял екран';
	@override String get startInFullscreenDescription => 'Отваряй Plezy в режим цял екран при стартиране';
	@override String get exitFullscreenOnPlayerClose => 'Изход от цял екран при затваряне на плейъра';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Автоматично излиза от режим цял екран при затваряне на видео плейъра';
	@override String get autoHidePerformanceOverlay => 'Автоматично скриване на оверлея за производителност';
	@override String get autoHidePerformanceOverlayDescription => 'Скривай постепенно оверлея за производителност заедно с контролите за възпроизвеждане';
	@override String get showNavBarLabels => 'Показвай етикети в навигационната лента';
	@override String get showNavBarLabelsDescription => 'Показвай текстови етикети под иконите в навигационната лента';
	@override String get startupSection => 'Начален раздел';
	@override String get liveTvDefaultFavorites => 'По подразбиране към любими канали';
	@override String get liveTvDefaultFavoritesDescription => 'Показвай само любими канали при отваряне на телевизия на живо';
	@override String get display => 'Дисплей';
	@override String get homeScreen => 'Начален екран';
	@override String get navigation => 'Навигация';
	@override String get window => 'Прозорец';
	@override String get content => 'Съдържание';
	@override String get player => 'Плейър';
	@override String get subtitlesAndConfig => 'Субтитри и конфигурация';
	@override String get seekAndTiming => 'Търсене и време';
	@override String get behavior => 'Поведение';
}

// Path: search
class _TranslationsSearchBg extends TranslationsSearchEn {
	_TranslationsSearchBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Търсене на филми, сериали, музика...';
	@override String get tryDifferentTerm => 'Опитайте с различна дума за търсене';
	@override String get searchYourMedia => 'Търсете във вашата медия';
	@override String get enterTitleActorOrKeyword => 'Въведете заглавие, актьор или ключова дума';
}

// Path: hotkeys
class _TranslationsHotkeysBg extends TranslationsHotkeysEn {
	_TranslationsHotkeysBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Задай клавишна комбинация за ${actionName}';
	@override String get clearShortcut => 'Изчисти клавишната комбинация';
	@override String get noShortcutSet => 'Няма зададена клавишна комбинация';
	@override String get currentShortcut => 'Текуща комбинация:';
	@override String get pressToRecord => 'Избери, за да запишеш клавишна комбинация';
	@override String get recordingShortcut => 'Натисни клавишната комбинация сега';
	@override late final _TranslationsHotkeysActionsBg actions = _TranslationsHotkeysActionsBg._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoBg extends TranslationsFileInfoEn {
	_TranslationsFileInfoBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Информация за файла';
	@override String get video => 'Видео';
	@override String get audio => 'Аудио';
	@override String get file => 'Файл';
	@override String get advanced => 'Разширени';
	@override String get codec => 'Кодек';
	@override String get resolution => 'Резолюция';
	@override String get bitrate => 'Битрейт';
	@override String get frameRate => 'Кадрова честота';
	@override String get aspectRatio => 'Съотношение на страните';
	@override String get profile => 'Профил';
	@override String get bitDepth => 'Битова дълбочина';
	@override String get colorSpace => 'Цветово пространство';
	@override String get colorRange => 'Цветови диапазон';
	@override String get colorPrimaries => 'Основни цветове';
	@override String get chromaSubsampling => 'Цветова субдискретизация';
	@override String get channels => 'Канали';
	@override String get subtitles => 'Субтитри';
	@override String get overallBitrate => 'Общ битрейт';
	@override String get path => 'Път';
	@override String get size => 'Размер';
	@override String get container => 'Контейнер';
	@override String get duration => 'Продължителност';
	@override String get optimizedForStreaming => 'Оптимизирано за стрийминг';
	@override String get has64bitOffsets => '64-битови отмествания';
}

// Path: mediaMenu
class _TranslationsMediaMenuBg extends TranslationsMediaMenuEn {
	_TranslationsMediaMenuBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Маркирай като гледано';
	@override String get markAsUnwatched => 'Маркирай като негледано';
	@override String get removeFromContinueWatching => 'Премахни от продължаване на гледането';
	@override String get viewDetails => 'Виж подробности';
	@override String get goToSeries => 'Към сериала';
	@override String get shufflePlay => 'Разбъркано възпроизвеждане';
	@override String get shuffleNotAvailableOffline => 'Разбърканото възпроизвеждане не е налично офлайн';
	@override String get fileInfo => 'Информация за файла';
	@override String get deleteFromServer => 'Изтрий от сървъра';
	@override String get confirmDelete => 'Да се изтрие ли тази медия и файловете ѝ от вашия сървър?';
	@override String get deleteMultipleWarning => 'Това включва всички епизоди и техните файлове.';
	@override String get mediaDeletedSuccessfully => 'Медията е изтрита успешно';
	@override String get mediaFailedToDelete => 'Неуспешно изтриване на медията';
	@override String get rate => 'Оцени';
	@override String get playFromBeginning => 'Пусни от началото';
	@override String get playVersion => 'Пусни версия...';
}

// Path: rateSheet
class _TranslationsRateSheetBg extends TranslationsRateSheetEn {
	_TranslationsRateSheetBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Оцени';
	@override String get server => 'Сървър';
	@override String get favorite => 'Добави в любими';
	@override String get favorited => 'Добавено в любими';
	@override String get saved => 'Запазено';
	@override String get notAvailable => 'Няма намерено съвпадение';
	@override String get noConnectedServices => 'Свържи услуга в Настройки, за да оценяваш там.';
}

// Path: accessibility
class _TranslationsAccessibilityBg extends TranslationsAccessibilityEn {
	_TranslationsAccessibilityBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, филм';
	@override String mediaCardShow({required Object title}) => '${title}, ТВ сериал';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'гледано';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} процента изгледано';
	@override String get mediaCardUnwatched => 'негледано';
	@override String get tapToPlay => 'Докоснете за възпроизвеждане';
	@override String get decrease => 'Намали';
	@override String get increase => 'Увеличи';
	@override String decreaseValue({required Object label}) => 'Намали ${label}';
	@override String increaseValue({required Object label}) => 'Увеличи ${label}';
	@override String get hue => 'Нюанс';
	@override String get saturation => 'Наситеност';
	@override String get brightness => 'Яркост';
	@override String get hexColor => 'Шестнадесетичен цвят';
	@override String get expandText => 'Разгъни текста';
	@override String get collapseText => 'Свий текста';
}

// Path: tooltips
class _TranslationsTooltipsBg extends TranslationsTooltipsEn {
	_TranslationsTooltipsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Разбъркано възпроизвеждане';
	@override String get playTrailer => 'Пусни трейлър';
	@override String get markAsWatched => 'Маркирай като гледано';
	@override String get markAsUnwatched => 'Маркирай като негледано';
}

// Path: videoControls
class _TranslationsVideoControlsBg extends TranslationsVideoControlsEn {
	_TranslationsVideoControlsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Аудио';
	@override String get subtitlesLabel => 'Субтитри';
	@override String get resetToZero => 'Нулирай до 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} се възпроизвежда по-късно';
	@override String playsEarlier({required Object label}) => '${label} се възпроизвежда по-рано';
	@override String get noOffset => 'Без отместване';
	@override String get letterbox => 'Черни ленти';
	@override String get fillScreen => 'Запълни екрана';
	@override String get stretch => 'Разтегни';
	@override String get lockRotation => 'Заключи ротацията';
	@override String get unlockRotation => 'Отключи ротацията';
	@override String get timerActive => 'Таймерът е активен';
	@override String playbackWillPauseIn({required Object duration}) => 'Възпроизвеждането ще спре след ${duration}';
	@override String get sleepTimerEndOfVideo => 'Край на текущото видео';
	@override String get sleepTimerStopAtHeader => 'Спиране при';
	@override String get sleepTimerDurationHeader => 'Таймер';
	@override String get playbackWillPauseAtEnd => 'Възпроизвеждането ще спре в края на това видео';
	@override String get stillWatching => 'Още ли гледате?';
	@override String pausingIn({required Object seconds}) => 'Пауза след ${seconds}сек';
	@override String get continueWatching => 'Продължи';
	@override String get autoPlayNext => 'Автоматично пусни следващото';
	@override String get playNext => 'Пусни следващото';
	@override String get playButton => 'Пусни';
	@override String get pauseButton => 'Пауза';
	@override String seekBackwardButton({required Object seconds}) => 'Превърти назад ${seconds} секунди';
	@override String seekForwardButton({required Object seconds}) => 'Превърти напред ${seconds} секунди';
	@override String get previousButton => 'Предишен епизод';
	@override String get nextButton => 'Следващ епизод';
	@override String get previousChapterButton => 'Предишна глава';
	@override String get nextChapterButton => 'Следваща глава';
	@override String get muteButton => 'Заглуши';
	@override String get unmuteButton => 'Включи звука';
	@override String get settingsButton => 'Настройки на възпроизвеждането';
	@override String get tracksButton => 'Аудио и субтитри';
	@override String get chaptersButton => 'Глави';
	@override String get versionQualityButton => 'Версия и качество';
	@override String get versionColumnHeader => 'Версия';
	@override String get qualityColumnHeader => 'Качество';
	@override String get qualityOriginal => 'Оригинал';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Транскодирането не е налично — пуска се оригиналното качество';
	@override String get pipButton => 'Режим картина в картината';
	@override String get aspectRatioButton => 'Съотношение на страните';
	@override String get ambientLighting => 'Амбиентно осветление';
	@override String get fullscreenButton => 'Влез на цял екран';
	@override String get exitFullscreenButton => 'Излез от цял екран';
	@override String get alwaysOnTopButton => 'Винаги отгоре';
	@override String get rotationLockButton => 'Заключване на ротацията';
	@override String get lockScreen => 'Заключи екрана';
	@override String get screenLockButton => 'Заключване на екрана';
	@override String get longPressToUnlock => 'Задръжте продължително за отключване';
	@override String get timelineSlider => 'Видео времева линия';
	@override String get volumeSlider => 'Ниво на звука';
	@override String endsAt({required Object time}) => 'Свършва в ${time}';
	@override String get pipActive => 'Възпроизвеждане в режим картина в картината';
	@override String get pipFailed => 'Режимът картина в картината не успя да стартира';
	@override String get screenshotSaved => 'Екранната снимка е запазена';
	@override String zoomPercent({required Object percent}) => 'Мащаб ${percent}%';
	@override late final _TranslationsVideoControlsPipErrorsBg pipErrors = _TranslationsVideoControlsPipErrorsBg._(_root);
	@override String get chapters => 'Глави';
	@override String get noChaptersAvailable => 'Няма налични глави';
	@override String get queue => 'Опашка';
	@override String get noQueueItems => 'Няма елементи в опашката';
	@override String get searchSubtitles => 'Търсене на субтитри';
	@override String get language => 'Език';
	@override String get noSubtitlesFound => 'Не са намерени субтитри';
	@override String get downloadedSubtitle => 'Изтеглени субтитри';
	@override String get noSubtitlesAvailable => 'Няма налични субтитри';
	@override String get noAudioTracksAvailable => 'Няма налични аудио писти';
	@override String get noTracksAvailable => 'Няма налични писти';
	@override String get subtitleDownloaded => 'Субтитърът е изтеглен';
	@override String get subtitleDownloadFailed => 'Неуспешно изтегляне на субтитър';
	@override String get searchLanguages => 'Търсене на езици...';
}

// Path: messages
class _TranslationsMessagesBg extends TranslationsMessagesEn {
	_TranslationsMessagesBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Маркирано като гледано';
	@override String get markedAsUnwatched => 'Маркирано като негледано';
	@override String get markedAsWatchedOffline => 'Маркирано като гледано (ще се синхронизира, когато сте онлайн)';
	@override String get markedAsUnwatchedOffline => 'Маркирано като негледано (ще се синхронизира, когато сте онлайн)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Автоматично премахнато: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bg'))(n,
		one: 'Автоматично премахнато ${n} гледано изтегляне',
		other: 'Автоматично премахнати ${n} гледани изтегляния',
	);
	@override String get removedFromContinueWatching => 'Премахнато от продължаване на гледането';
	@override String errorLoading({required Object error}) => 'Грешка: ${error}';
	@override String get streamInterrupted => 'Потокът прекъсна. Натиснете „Пусни“ или превъртете, за да опитате отново.';
	@override String get liveStreamInterrupted => 'Потокът на живо прекъсна. Натиснете „Пусни“, за да опитате отново.';
	@override String get fileInfoNotAvailable => 'Информацията за файла не е налична';
	@override String errorLoadingFileInfo({required Object error}) => 'Грешка при зареждане на информация за файла: ${error}';
	@override String get errorLoadingSeries => 'Грешка при зареждане на сериала';
	@override String get musicNotSupported => 'Възпроизвеждането на музика все още не се поддържа';
	@override String get noDescriptionAvailable => 'Няма налично описание';
	@override String get noProfilesAvailable => 'Няма налични профили';
	@override String get contactAdminForProfiles => 'Свържете се с администратора на сървъра, за да добави профили';
	@override String get unableToDetermineLibrarySection => 'Не може да се определи секцията на библиотеката за този елемент';
	@override String get logsCleared => 'Логовете са изчистени';
	@override String get logsCopied => 'Логовете са копирани в клипборда';
	@override String get noLogsAvailable => 'Няма налични логове';
	@override String libraryScanning({required Object title}) => 'Сканиране на "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Сканирането на библиотеката е стартирано за "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Неуспешно сканиране на библиотеката: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Опресняване на метаданни за "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Опресняването на метаданни е стартирано за "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Неуспешно опресняване на метаданни: ${error}';
	@override String get logoutConfirm => 'Сигурни ли сте, че искате да излезете?';
	@override String get noSeasonsFound => 'Не са намерени сезони';
	@override String get seasonsLoadFailed => 'Неуспешно зареждане на сезони';
	@override String get noEpisodesFound => 'Не са намерени епизоди в първия сезон';
	@override String get noEpisodesFoundGeneral => 'Не са намерени епизоди';
	@override String get episodesLoadFailed => 'Неуспешно зареждане на епизоди';
	@override String get noResultsFound => 'Няма намерени резултати';
	@override String sleepTimerSet({required Object label}) => 'Таймерът за заспиване е зададен за ${label}';
	@override String get noItemsAvailable => 'Няма налични елементи';
	@override String get failedToCreatePlayQueueNoItems => 'Неуспешно създаване на опашка за възпроизвеждане - няма елементи';
	@override String failedPlayback({required Object action, required Object error}) => 'Неуспешно ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Превключване към съвместим плейър...';
	@override String get serverLimitTitle => 'Възпроизвеждането е неуспешно';
	@override String get serverLimitBody => 'Грешка на сървъра (HTTP 500). Вероятно лимит за пропускателна способност/транскодиране е отхвърлил тази сесия. Помолете собственика да го коригира.';
	@override String get logsUploaded => 'Логовете са качени';
	@override String get logsUploadFailed => 'Неуспешно качване на логовете';
	@override String get logId => 'ID на лога';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingBg extends TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get text => 'Текст';
	@override String get border => 'Рамка';
	@override String get background => 'Фон';
	@override String get fontSize => 'Размер на шрифта';
	@override String get textColor => 'Цвят на текста';
	@override String get borderSize => 'Размер на рамката';
	@override String get borderColor => 'Цвят на рамката';
	@override String get backgroundOpacity => 'Прозрачност на фона';
	@override String get backgroundColor => 'Цвят на фона';
	@override String get position => 'Позиция';
	@override String get assOverride => 'ASS презаписване';
	@override String get overrideScale => 'Мащабиране';
	@override String get overrideForce => 'Принудително';
	@override String get overrideStrip => 'Премахване на стиловете';
	@override String get positionTop => 'Горе';
	@override String get positionBottom => 'Долу';
	@override String get bold => 'Получер';
	@override String get italic => 'Курсив';
	@override String get renderResolution => 'Резолюция на изобразяване';
	@override String get renderResolutionScreen => 'Резолюция на екрана';
	@override String get renderResolutionVideo => 'Резолюция на видеото';
}

// Path: mpvConfig
class _TranslationsMpvConfigBg extends TranslationsMpvConfigEn {
	_TranslationsMpvConfigBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Разширени настройки на видео плейъра';
	@override String get presets => 'Пресети';
	@override String get noPresets => 'Няма запазени пресети';
	@override String get saveAsPreset => 'Запази като пресет...';
	@override String get presetName => 'Име на пресет';
	@override String get presetNameHint => 'Въведете име за този пресет';
	@override String get loadPreset => 'Зареди';
	@override String get deletePreset => 'Изтрий';
	@override String get presetSaved => 'Пресетът е запазен';
	@override String get presetLoaded => 'Пресетът е зареден';
	@override String get presetDeleted => 'Пресетът е изтрит';
	@override String get confirmDeletePreset => 'Сигурни ли сте, че искате да изтриете този пресет?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogBg extends TranslationsDialogEn {
	_TranslationsDialogBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Потвърждение на действие';
}

// Path: profiles
class _TranslationsProfilesBg extends TranslationsProfilesEn {
	_TranslationsProfilesBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Добави Plezy профил';
	@override String get switchingProfile => 'Смяна на профил…';
	@override String get deleteThisProfileTitle => 'Да се изтрие ли този профил?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Премахване на ${displayName}. Връзките не се засягат.';
	@override String get active => 'Активен';
	@override String get manage => 'Управление';
	@override String get delete => 'Изтрий';
	@override String get signOut => 'Изход';
	@override String get signOutPlexTitle => 'Изход от Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Премахване на ${displayName} и всички Plex Home потребители? Можете да влезете отново по всяко време.';
	@override String get signedOutPlex => 'Излязохте от Plex.';
	@override String get signOutFailed => 'Изходът е неуспешен.';
	@override String get sectionTitle => 'Профили';
	@override String get summarySingle => 'Добавете профили, за да комбинирате управлявани потребители и локални идентичности';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} профила · активен: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} профила';
	@override String get removeConnectionTitle => 'Да се премахне ли връзката?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Премахване на достъпа на ${displayName} до ${connectionLabel}. Другите профили го запазват.';
	@override String get deleteProfileTitle => 'Да се изтрие ли профилът?';
	@override String deleteProfileMessage({required Object displayName}) => 'Премахване на ${displayName} и неговите връзки. Сървърите остават налични.';
	@override String get profileNameLabel => 'Име на профила';
	@override String get pinProtectionLabel => 'PIN защита';
	@override String get pinManagedByPlex => 'PIN-ът се управлява от Plex. Редактирайте го в plex.tv.';
	@override String get noPinSetEditOnPlex => 'Няма зададен PIN. За да изисквате PIN, редактирайте домашния потребител в plex.tv.';
	@override String get setPin => 'Задай PIN';
	@override String get setPinTitle => 'Задай PIN';
	@override String get confirmPinTitle => 'Потвърди PIN';
	@override String get pinSet => 'PIN-ът е зададен';
	@override String get changePin => 'Промени';
	@override String get removePin => 'Премахни';
	@override String get connectionsLabel => 'Връзки';
	@override String get add => 'Добави';
	@override String get deleteProfileButton => 'Изтрий профил';
	@override String get noConnectionsHint => 'Няма връзки — добавете такава, за да използвате този профил.';
	@override String get noConnections => 'Няма връзки';
	@override String get plexHomeAccount => 'Plex Home акаунт';
	@override String get connectionDefault => 'По подразбиране';
	@override String connectionAs({required Object displayName}) => 'като ${displayName}';
	@override String get makeDefault => 'Направи по подразбиране';
	@override String get removeConnection => 'Премахни';
	@override String get profileRenamed => 'Профилът е преименуван.';
	@override String borrowAddTo({required Object displayName}) => 'Добави към ${displayName}';
	@override String get borrowExplain => 'Използвай връзка от друг профил. PIN-защитените профили изискват PIN.';
	@override String get borrowEmpty => 'Все още няма какво да се използва.';
	@override String get borrowEmptySubtitle => 'Първо свържете Plex или Jellyfin към друг профил.';
	@override String borrowFromProfile({required Object displayName}) => 'От ${displayName}';
	@override String get borrowConnectionBorrowed => 'Връзката е използвана.';
	@override String get borrowFailed => 'Неуспешно използване на връзка.';
	@override String get incorrectPin => 'Неправилен PIN.';
	@override String get incorrectPinTryAgain => 'Неправилен PIN. Опитайте отново.';
	@override String get sourceProfileMissingParentAccount => 'Изходният профил няма родителски акаунт.';
	@override String get failedToLoadHomeUsers => 'Потребителите на Plex Home не можаха да бъдат заредени. Проверете връзката си и опитайте отново.';
	@override String get failedToVerifyPin => 'Неуспешна проверка на PIN.';
	@override String get newProfile => 'Нов профил';
	@override String get profileNameHint => 'напр. Гости, Деца, Семейна стая';
	@override String get pinProtectionOptional => 'PIN защита (по желание)';
	@override String get pinExplain => 'Изисква се 4-цифрен PIN за смяна на профили.';
	@override String get continueButton => 'Продължи';
	@override String get pinsDontMatch => 'PIN кодовете не съвпадат';
}

// Path: connections
class _TranslationsConnectionsBg extends TranslationsConnectionsEn {
	_TranslationsConnectionsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Връзки';
	@override String get addConnection => 'Добави връзка';
	@override String get addConnectionSubtitleNoProfile => 'Влезте с Plex или свържете Jellyfin сървър';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Добави към ${displayName}: Plex, Jellyfin или връзка от друг профил';
	@override String sessionExpiredOne({required Object name}) => 'Сесията за ${name} е изтекла';
	@override String sessionExpiredMany({required Object count}) => 'Сесиите за ${count} сървъра са изтекли';
	@override String get signInAgain => 'Влез отново';
	@override String get editJellyfinTitle => 'Редактиране на Jellyfin връзка';
	@override String editJellyfinIntro({required Object serverName}) => 'Добавете или премахнете URL адреси за ${serverName}. Plezy ще използва достъпния URL адрес с най-ниска латентност.';
}

// Path: discover
class _TranslationsDiscoverBg extends TranslationsDiscoverEn {
	_TranslationsDiscoverBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Открий';
	@override String get noContentAvailable => 'Няма налично съдържание';
	@override String get addMediaToLibraries => 'Добавете медия към библиотеките си';
	@override String get continueWatching => 'Продължи гледането';
	@override String continueWatchingIn({required Object library}) => 'Продължи гледането в ${library}';
	@override String get nextUp => 'Следва';
	@override String nextUpIn({required Object library}) => 'Следва в ${library}';
	@override String get recentlyAdded => 'Наскоро добавени';
	@override String recentlyAddedIn({required Object library}) => 'Наскоро добавени в ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Последни албуми в ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Наскоро възпроизведени в ${library}';
	@override String mostPlayedIn({required Object library}) => 'Най-възпроизвеждани в ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Обзор';
	@override String get cast => 'Актьори';
	@override String get extras => 'Трейлъри и екстри';
	@override String get studio => 'Студио';
	@override String get rating => 'Рейтинг';
	@override String get movie => 'Филм';
	@override String get tvShow => 'ТВ сериал';
	@override String minutesLeft({required Object minutes}) => 'Остават ${minutes} мин';
	@override String get moreLikeThis => 'Подобно на това';
}

// Path: errors
class _TranslationsErrorsBg extends TranslationsErrorsEn {
	_TranslationsErrorsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Търсенето е неуспешно: ${error}';
	@override String connectionTimeout({required Object context}) => 'Изтече времето за връзка при зареждане на ${context}';
	@override String get connectionFailed => 'Не може да се осъществи връзка с медиен сървър';
	@override String unableToLoad({required Object context}) => 'Не може да се зареди ${context}. Опитайте отново.';
	@override String get noClientAvailable => 'Няма наличен клиент';
	@override String get pleaseEnterToken => 'Моля, въведете токен';
	@override String get invalidToken => 'Невалиден токен';
	@override String failedToVerifyToken({required Object error}) => 'Неуспешна проверка на токена: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Неуспешна смяна към ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Неуспешно изтриване на ${displayName}';
	@override String get failedToRate => 'Оценката не можа да бъде обновена';
}

// Path: libraries
class _TranslationsLibrariesBg extends TranslationsLibrariesEn {
	_TranslationsLibrariesBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Библиотеки';
	@override String get fallbackTitle => 'Библиотека';
	@override String get scanLibraryFiles => 'Сканирай файловете на библиотеката';
	@override String get scanLibrary => 'Сканирай библиотеката';
	@override String get analyze => 'Анализирай';
	@override String get analyzeLibrary => 'Анализирай библиотеката';
	@override String get refreshMetadata => 'Опресни метаданни';
	@override String get emptyTrash => 'Изпразни кошчето';
	@override String emptyingTrash({required Object title}) => 'Изпразване на кошчето за "${title}"...';
	@override String trashEmptied({required Object title}) => 'Кошчето е изпразнено за "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Неуспешно изпразване на кошчето: ${error}';
	@override String analyzing({required Object title}) => 'Анализиране на "${title}"...';
	@override String analysisStarted({required Object title}) => 'Анализът е стартиран за "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Неуспешен анализ на библиотеката: ${error}';
	@override String get noLibrariesFound => 'Не са намерени библиотеки';
	@override String get allLibrariesHidden => 'Всички библиотеки са скрити';
	@override String hiddenLibrariesCount({required Object count}) => 'Скрити библиотеки (${count})';
	@override String get thisLibraryIsEmpty => 'Тази библиотека е празна';
	@override String get noItemsMatchFilters => 'Няма елементи, съответстващи на активните филтри';
	@override String get resetFilters => 'Нулирай филтрите';
	@override String get all => 'Всички';
	@override String get clearAll => 'Изчисти всички';
	@override String scanLibraryConfirm({required Object title}) => 'Сигурни ли сте, че искате да сканирате "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Сигурни ли сте, че искате да анализирате "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Сигурни ли сте, че искате да опресните метаданните за "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Сигурни ли сте, че искате да изпразните кошчето за "${title}"?';
	@override String get manageLibraries => 'Управление на библиотеки';
	@override String get sort => 'Сортиране';
	@override String get sortBy => 'Сортирай по';
	@override String get filters => 'Филтри';
	@override String get confirmActionMessage => 'Сигурни ли сте, че искате да извършите това действие?';
	@override String get showLibrary => 'Покажи библиотеката';
	@override String get hideLibrary => 'Скрий библиотеката';
	@override String get libraryOptions => 'Опции на библиотеката';
	@override String get content => 'съдържание на библиотеката';
	@override String get selectLibrary => 'Избери библиотека';
	@override String filtersWithCount({required Object count}) => 'Филтри (${count})';
	@override String get noRecommendations => 'Няма налични препоръки';
	@override String get noCollections => 'Няма колекции в тази библиотека';
	@override String get noFoldersFound => 'Не са намерени папки';
	@override String get folders => 'папки';
	@override late final _TranslationsLibrariesTabsBg tabs = _TranslationsLibrariesTabsBg._(_root);
	@override late final _TranslationsLibrariesGroupingsBg groupings = _TranslationsLibrariesGroupingsBg._(_root);
	@override late final _TranslationsLibrariesFilterCategoriesBg filterCategories = _TranslationsLibrariesFilterCategoriesBg._(_root);
	@override late final _TranslationsLibrariesSortLabelsBg sortLabels = _TranslationsLibrariesSortLabelsBg._(_root);
}

// Path: about
class _TranslationsAboutBg extends TranslationsAboutEn {
	_TranslationsAboutBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Относно';
	@override String get openSourceLicenses => 'Лицензи с отворен код';
	@override String versionLabel({required Object version}) => 'Версия ${version}';
	@override String get appDescription => 'Красив Plex и Jellyfin клиент за Flutter';
	@override String get viewLicensesDescription => 'Виж лицензите на библиотеки на трети страни';
}

// Path: serverSelection
class _TranslationsServerSelectionBg extends TranslationsServerSelectionEn {
	_TranslationsServerSelectionBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Не са намерени сървъри за ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Неуспешно зареждане на сървъри: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailBg extends TranslationsHubDetailEn {
	_TranslationsHubDetailBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Заглавие';
	@override String get releaseYear => 'Година на излизане';
	@override String get dateAdded => 'Дата на добавяне';
	@override String get rating => 'Рейтинг';
	@override String get noItemsFound => 'Няма намерени елементи';
}

// Path: logs
class _TranslationsLogsBg extends TranslationsLogsEn {
	_TranslationsLogsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Изчисти логовете';
	@override String get copyLogs => 'Копирай логовете';
	@override String get uploadLogs => 'Качи логовете';
}

// Path: licenses
class _TranslationsLicensesBg extends TranslationsLicensesEn {
	_TranslationsLicensesBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Свързани пакети';
	@override String get license => 'Лиценз';
	@override String licenseNumber({required Object number}) => 'Лиценз ${number}';
	@override String licensesCount({required Object count}) => '${count} лиценза';
}

// Path: navigation
class _TranslationsNavigationBg extends TranslationsNavigationEn {
	_TranslationsNavigationBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Библиотеки';
	@override String get downloads => 'Изтегляния';
	@override String get liveTv => 'Телевизия на живо';
	@override String get explore => 'Разгледай';
}

// Path: explore
class _TranslationsExploreBg extends TranslationsExploreEn {
	_TranslationsExploreBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Разгледай';
	@override String get selectSource => 'Избери източник';
	@override late final _TranslationsExploreRowsBg rows = _TranslationsExploreRowsBg._(_root);
	@override late final _TranslationsExploreStatusBg status = _TranslationsExploreStatusBg._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bg'))(n,
		one: '${n} епизод',
		other: '${n} епизода',
	);
	@override String get cast => 'Актьори';
	@override String get characters => 'Герои';
	@override String get addToWatchlist => 'Добави в списъка за гледане';
	@override String get removeFromWatchlist => 'Премахни от списъка за гледане';
	@override String get watchlistUpdateFailed => 'Неуспешно обновяване на списъка за гледане';
	@override String get notInLibrary => 'Не е в твоята библиотека';
	@override String get inTheseLibraries => 'В тези библиотеки';
	@override String get checkingLibrary => 'Проверка на твоята библиотека...';
	@override String get emptyTitle => 'Тук все още няма нищо';
	@override String emptyMessage({required Object source}) => 'Редовете от ${source} ще се появят тук, когато има съдържание.';
	@override String searchHint({required Object source}) => 'Търсене в ${source}';
	@override String searchEmpty({required Object query}) => 'Няма резултати за "${query}"';
	@override String searchPrompt({required Object source}) => 'Търси филми и сериали в ${source}.';
	@override String get searchFailed => 'Търсенето се провали. Провери връзката си и опитай отново.';
}

// Path: liveTv
class _TranslationsLiveTvBg extends TranslationsLiveTvEn {
	_TranslationsLiveTvBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Телевизия на живо';
	@override String get guide => 'ТВ програма';
	@override String get noChannels => 'Няма налични канали';
	@override String get noDvr => 'Няма конфигуриран DVR на нито един сървър';
	@override String get serverUnavailable => 'Сървърът за телевизия на живо не е наличен.';
	@override String get serverNotConnected => 'Сървърът за телевизия на живо не е свързан.';
	@override String get noPrograms => 'Няма налични програмни данни';
	@override String get liveStreamFailed => 'Потокът на живо се провали';
	@override String get unknownProgram => 'Неизвестна програма';
	@override String get unknownHub => 'Неизвестно';
	@override String get unknownError => 'Неизвестна грешка';
	@override String channelNumber({required Object number}) => 'Канал ${number}';
	@override String get unknownChannel => 'Неизвестен канал';
	@override String get live => 'НА ЖИВО';
	@override String get reloadGuide => 'Презареди ТВ програмата';
	@override String get now => 'Сега';
	@override String get today => 'Днес';
	@override String get tomorrow => 'Утре';
	@override String get midnight => 'Полунощ';
	@override String get overnight => 'През нощта';
	@override String get morning => 'Сутрин';
	@override String get daytime => 'През деня';
	@override String get evening => 'Вечер';
	@override String get lateNight => 'Късно вечер';
	@override String get whatsOn => 'Какво дават';
	@override String get watchChannel => 'Гледай канал';
	@override String get favorites => 'Любими';
	@override String get reorderFavorites => 'Пренареди любимите';
	@override String get favoritesLoadFailed => 'Любимите не можаха да се заредят. Проверете връзката си и опитайте отново.';
	@override String get joinSession => 'Присъедини се към текуща сесия';
	@override String watchFromStart({required Object minutes}) => 'Гледай от началото (преди ${minutes} мин)';
	@override String get watchLive => 'Гледай на живо';
	@override String get goToLive => 'Към живото предаване';
	@override String get record => 'Запис';
	@override String get recordEpisode => 'Запиши епизод';
	@override String get recordSeries => 'Запиши сериал';
	@override String get recordOptions => 'Опции за запис';
	@override String get saveTo => 'Запази в';
	@override String get recordings => 'Записи';
	@override String get scheduledRecordings => 'Планирани';
	@override String get recordingRules => 'Правила за запис';
	@override String get noScheduledRecordings => 'Няма планирани записи';
	@override String get manageRecording => 'Управление на запис';
	@override String get cancelRecording => 'Отмени запис';
	@override String get cancelRecordingTitle => 'Да се отмени ли този запис?';
	@override String cancelRecordingMessage({required Object title}) => '${title} вече няма да се записва.';
	@override String get deleteRule => 'Изтрий правило';
	@override String get deleteRuleTitle => 'Да се изтрие ли правилото за запис?';
	@override String deleteRuleMessage({required Object title}) => 'Бъдещи епизоди на ${title} няма да се записват.';
	@override String get recordingScheduled => 'Записът е планиран';
	@override String get alreadyScheduled => 'Тази програма вече е планирана';
	@override String get dvrAdminRequired => 'DVR настройките изискват администраторски акаунт';
	@override String get recordingFailed => 'Записът не можа да бъде планиран';
	@override String get recordingTargetMissing => 'Не може да се определи библиотеката за запис';
	@override String get recordNotAvailable => 'Записът не е наличен за тази програма';
	@override String get recordingCancelled => 'Записът е отменен';
	@override String get recordingRuleDeleted => 'Правилото за запис е изтрито';
	@override String get processRecordingRules => 'Преоцени правилата';
	@override String get recordingInProgress => 'Записва се сега';
	@override String recordingsCount({required Object count}) => '${count} планирани';
	@override String get editRule => 'Редактирай правило';
	@override String get editRuleAction => 'Редактирай';
	@override String get recordingRuleUpdated => 'Правилото за запис е обновено';
	@override String get guideReloadRequested => 'Заявено е опресняване на ТВ програмата';
	@override String get rulesProcessRequested => 'Заявена е преоценка на правилата';
	@override String get recordShow => 'Запиши предаването';
}

// Path: collections
class _TranslationsCollectionsBg extends TranslationsCollectionsEn {
	_TranslationsCollectionsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Колекции';
	@override String get collection => 'Колекция';
	@override String get empty => 'Колекцията е празна';
	@override String get deleteCollection => 'Изтрий колекция';
	@override String deleteConfirm({required Object title}) => 'Да се изтрие ли "${title}"? Това не може да бъде отменено.';
	@override String get deleted => 'Колекцията е изтрита';
	@override String get deleteFailed => 'Неуспешно изтриване на колекция';
	@override String deleteFailedWithError({required Object error}) => 'Неуспешно изтриване на колекция: ${error}';
	@override String get selectCollection => 'Избери колекция';
	@override String get collectionName => 'Име на колекция';
	@override String get enterCollectionName => 'Въведете име на колекция';
	@override String get addedToCollection => 'Добавено към колекция';
	@override String get errorAddingToCollection => 'Неуспешно добавяне към колекция';
	@override String get created => 'Колекцията е създадена';
	@override String get removeFromCollection => 'Премахни от колекция';
	@override String removeFromCollectionConfirm({required Object title}) => 'Да се премахне ли "${title}" от тази колекция?';
	@override String get removedFromCollection => 'Премахнато от колекция';
	@override String get removeFromCollectionFailed => 'Неуспешно премахване от колекция';
	@override String removeFromCollectionError({required Object error}) => 'Грешка при премахване от колекция: ${error}';
	@override String get searchCollections => 'Търсене на колекции...';
}

// Path: playlists
class _TranslationsPlaylistsBg extends TranslationsPlaylistsEn {
	_TranslationsPlaylistsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Плейлисти';
	@override String get playlist => 'Плейлист';
	@override String get noPlaylists => 'Не са намерени плейлисти';
	@override String get create => 'Създай плейлист';
	@override String get playlistName => 'Име на плейлист';
	@override String get enterPlaylistName => 'Въведете име на плейлист';
	@override String get delete => 'Изтрий плейлист';
	@override String get removeItem => 'Премахни от плейлист';
	@override String get smartPlaylist => 'Умен плейлист';
	@override String itemCount({required Object count}) => '${count} елемента';
	@override String get oneItem => '1 елемент';
	@override String get emptyPlaylist => 'Този плейлист е празен';
	@override String get deleteConfirm => 'Да се изтрие ли плейлистът?';
	@override String deleteMessage({required Object name}) => 'Сигурни ли сте, че искате да изтриете "${name}"?';
	@override String get created => 'Плейлистът е създаден';
	@override String get deleted => 'Плейлистът е изтрит';
	@override String get itemAdded => 'Добавено към плейлист';
	@override String get itemRemoved => 'Премахнато от плейлист';
	@override String get selectPlaylist => 'Избери плейлист';
	@override String get searchPlaylists => 'Търсене в плейлисти...';
	@override String get errorCreating => 'Неуспешно създаване на плейлист';
	@override String get errorDeleting => 'Неуспешно изтриване на плейлист';
	@override String get errorLoading => 'Неуспешно зареждане на плейлисти';
	@override String get errorAdding => 'Неуспешно добавяне към плейлист';
	@override String get errorReordering => 'Неуспешно пренареждане на елемент в плейлиста';
	@override String get errorRemoving => 'Неуспешно премахване от плейлист';
}

// Path: music
class _TranslationsMusicBg extends TranslationsMusicEn {
	_TranslationsMusicBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Към албума';
	@override String get goToArtist => 'Към изпълнителя';
	@override String get instantMix => 'Мигновен микс';
	@override String get playNext => 'Пусни следващото';
	@override String get addToQueue => 'Добави към опашката';
	@override String discNumber({required Object n}) => 'Диск ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bg'))(n,
		one: '${n} песен',
		other: '${n} песни',
	);
	@override String get nowPlaying => 'Сега се възпроизвежда';
	@override String playingFrom({required Object title}) => 'Възпроизвеждане от ${title}';
	@override String get queue => 'Опашка';
	@override String get clearQueue => 'Изчисти опашката';
	@override String get lyrics => 'Текст';
	@override String get noLyrics => 'Няма наличен текст';
	@override String get sleepTimer => 'Таймер за заспиване';
	@override String get sleepTimerEndOfTrack => 'Край на песента';
	@override String sleepTimerMinutes({required Object n}) => '${n} минути';
	@override String get stopPlayback => 'Спри възпроизвеждането';
	@override String get previousTrack => 'Предишна песен';
	@override String get nextTrack => 'Следваща песен';
	@override String get repeat => 'Повтори';
	@override String get repeatAll => 'Повтори всички';
	@override String get repeatOne => 'Повтори една';
}

// Path: watchTogether
class _TranslationsWatchTogetherBg extends TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Гледане заедно';
	@override String get description => 'Гледайте съдържание синхронизирано с приятели и семейство';
	@override String get createSession => 'Създай сесия';
	@override String get creating => 'Създаване...';
	@override String get joinSession => 'Присъедини се към сесия';
	@override String get joining => 'Присъединяване...';
	@override String get controlMode => 'Режим на управление';
	@override String get controlModeQuestion => 'Кой може да управлява възпроизвеждането?';
	@override String get hostOnly => 'Само домакинът';
	@override String get anyone => 'Всеки';
	@override String get hostingSession => 'Сесия с домакин';
	@override String get inSession => 'В сесия';
	@override String get sessionCode => 'Код на сесията';
	@override String get openSessionControls => 'Отвори контролите за сесията „Гледане заедно“';
	@override String get copySessionCode => 'Копирай кода на сесията';
	@override String get hostControlsPlayback => 'Домакинът управлява възпроизвеждането';
	@override String get anyoneCanControl => 'Всеки може да управлява възпроизвеждането';
	@override String get hostControls => 'Контроли на домакина';
	@override String get anyoneControls => 'Всеки управлява';
	@override String get participants => 'Участници';
	@override String get host => 'Домакин';
	@override String get hostBadge => 'ДОМАКИН';
	@override String get youAreHost => 'Вие сте домакин';
	@override String get watchingWithOthers => 'Гледате с други';
	@override String get endSession => 'Край на сесията';
	@override String get leaveSession => 'Напусни сесията';
	@override String get endSessionQuestion => 'Край на сесията?';
	@override String get leaveSessionQuestion => 'Напускане на сесията?';
	@override String get endSessionConfirm => 'Това ще прекрати сесията за всички участници.';
	@override String get leaveSessionConfirm => 'Ще бъдете премахнати от сесията.';
	@override String get endSessionConfirmOverlay => 'Това ще прекрати сесията за гледане за всички участници.';
	@override String get leaveSessionConfirmOverlay => 'Ще бъдете изключени от сесията за гледане.';
	@override String get end => 'Край';
	@override String get leave => 'Напусни';
	@override String get syncing => 'Синхронизиране...';
	@override String get joinWatchSession => 'Присъедини се към сесия за гледане';
	@override String get enterCodeHint => 'Въведете 5-символен код';
	@override String get pasteFromClipboard => 'Постави от клипборда';
	@override String get pleaseEnterCode => 'Моля, въведете код на сесия';
	@override String get codeMustBe5Chars => 'Кодът на сесията трябва да е 5 символа';
	@override String get joinInstructions => 'Въведете кода на сесията от домакина, за да се присъедините.';
	@override String get failedToCreate => 'Неуспешно създаване на сесия';
	@override String get failedToJoin => 'Неуспешно присъединяване към сесия';
	@override String get sessionCodeCopied => 'Кодът на сесията е копиран в клипборда';
	@override String get relayUnreachable => 'Релей сървърът е недостъпен. Блокиране от доставчика може да пречи на гледането заедно.';
	@override String get reconnectingToHost => 'Повторно свързване с домакина...';
	@override String get currentPlayback => 'Текущо възпроизвеждане';
	@override String get joinCurrentPlayback => 'Присъедини се към текущото възпроизвеждане';
	@override String get joinCurrentPlaybackDescription => 'Върнете се към това, което домакинът гледа в момента';
	@override String get failedToOpenCurrentPlayback => 'Неуспешно отваряне на текущото възпроизвеждане';
	@override String participantJoined({required Object name}) => '${name} се присъедини';
	@override String participantLeft({required Object name}) => '${name} напусна';
	@override String participantPaused({required Object name}) => '${name} постави на пауза';
	@override String participantResumed({required Object name}) => '${name} продължи';
	@override String participantSeeked({required Object name}) => '${name} превъртя';
	@override String participantBuffering({required Object name}) => '${name} буферира';
	@override String participantNeedsUpdate({required Object name}) => '${name} е с по-стара версия на приложението — синхронизирането не е налично';
	@override String resumingWithout({required Object name}) => 'Продължаване без ${name}';
	@override String get waitingForParticipants => 'Изчакване другите да заредят...';
	@override String waitingForName({required Object name}) => 'Изчакване на ${name}...';
	@override String get recentRooms => 'Скорошни стаи';
	@override String get renameRoom => 'Преименувай стая';
	@override String get removeRoom => 'Премахни';
	@override String get guestSwitchUnavailable => 'Превключването не е възможно — сървърът е недостъпен за синхронизация';
	@override String get guestSwitchFailed => 'Превключването не е възможно — съдържанието не е намерено на този сървър';
}

// Path: downloads
class _TranslationsDownloadsBg extends TranslationsDownloadsEn {
	_TranslationsDownloadsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Изтегляния';
	@override String get manage => 'Управление';
	@override String get tvShows => 'ТВ сериали';
	@override String get movies => 'Филми';
	@override String get music => 'Музика';
	@override String tracksQueued({required Object count}) => '${count} песни в опашката за изтегляне';
	@override String get noDownloads => 'Все още няма изтегляния';
	@override String get noDownloadsDescription => 'Изтегленото съдържание ще се показва тук за офлайн гледане';
	@override String get downloadNow => 'Изтегли';
	@override String get deleteDownload => 'Изтрий изтегляне';
	@override String get retryDownload => 'Опитай изтеглянето отново';
	@override String get downloadQueued => 'Изтеглянето е добавено в опашката';
	@override String get downloadResumed => 'Изтеглянето е възобновено';
	@override String get serverErrorBitrate => 'Грешка на сървъра: файлът може да надвишава лимита за отдалечен битрейт';
	@override String episodesQueued({required Object count}) => '${count} епизода са добавени в опашката за изтегляне';
	@override String get downloadDeleted => 'Изтеглянето е изтрито';
	@override String deleteConfirm({required Object title}) => 'Да се изтрие ли "${title}" от това устройство?';
	@override String get cancelledDownloadTitle => 'Отменено изтегляне';
	@override String get cancelledDownloadMessage => 'Това изтегляне беше отменено. Какво искате да направите?';
	@override String get allEpisodesAlreadyDownloaded => 'Всички епизоди вече са изтеглени';
	@override String get resumeDownload => 'Възобнови изтеглянето';
	@override String get cancelledDownload => 'Отменено изтегляне';
	@override String syncingFile({required Object file, required Object status}) => '${file} (синхронизира се ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'Изтеглен ${file} — щракнете за довършване';
	@override String get partialDownloadClickToComplete => 'Частично изтеглено — щракнете за довършване';
	@override String get deleting => 'Изтриване...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Изтриване на ${title}... (${current} от ${total})';
	@override String get queuedTooltip => 'В опашката';
	@override String queuedFilesTooltip({required Object files}) => 'В опашката: ${files}';
	@override String get downloadingTooltip => 'Изтегляне...';
	@override String downloadingFilesTooltip({required Object files}) => 'Изтегляне на ${files}';
	@override String get noDownloadsTree => 'Няма изтегляния';
	@override String get pauseAll => 'Пауза на всички';
	@override String get resumeAll => 'Продължи всички';
	@override String get deleteAll => 'Изтрий всички';
	@override String get selectVersion => 'Избери версия';
	@override String get allEpisodes => 'Всички епизоди';
	@override String get unwatchedOnly => 'Само негледани';
	@override String nextNUnwatched({required Object count}) => 'Следващите ${count} негледани';
	@override String get customAmount => 'Персонален брой...';
	@override String get includeSpecials => 'Включи специалните';
	@override String get howManyEpisodes => 'Колко епизода?';
	@override String get invalidEpisodeCount => 'Въведете валиден брой епизоди.';
	@override String get keepSynced => 'Поддържай синхронизирано';
	@override String get downloadOnce => 'Изтегли еднократно';
	@override String keepNUnwatched({required Object count}) => 'Пази ${count} негледани';
	@override String get editSyncRule => 'Редактирай правило за синхронизация';
	@override String get removeSyncRule => 'Премахни правило за синхронизация';
	@override String removeSyncRuleConfirm({required Object title}) => 'Да се спре ли синхронизацията за "${title}"? Изтеглените епизоди ще останат.';
	@override String syncRuleCreated({required Object count}) => 'Правилото за синхронизация е създадено — запазват се ${count} негледани епизода';
	@override String get syncRuleUpdated => 'Правилото за синхронизация е обновено';
	@override String get syncRuleRemoved => 'Правилото за синхронизация е премахнато';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Синхронизирани са ${count} нови епизода за ${title}';
	@override String get activeSyncRules => 'Правила за синхронизация';
	@override String get noSyncRules => 'Няма правила за синхронизация';
	@override String get manageSyncRule => 'Управление на синхронизацията';
	@override String get editEpisodeCount => 'Брой епизоди';
	@override String get editSyncFilter => 'Филтър за синхронизация';
	@override String get syncAllItems => 'Синхронизират се всички елементи';
	@override String get syncUnwatchedItems => 'Синхронизират се негледаните елементи';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Сървър: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Налично';
	@override String get syncRuleOffline => 'Офлайн';
	@override String get syncRuleSignInRequired => 'Изисква се вход';
	@override String get syncRuleNotAvailableForProfile => 'Не е налично за текущия профил';
	@override String get syncRuleUnknownServer => 'Неизвестен сървър';
	@override String get syncRuleListCreated => 'Правилото за синхронизация е създадено';
}

// Path: shaders
class _TranslationsShadersBg extends TranslationsShadersEn {
	_TranslationsShadersBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Шейдъри';
	@override String get noShaderDescription => 'Без видео подобрение';
	@override String get nvscalerDescription => 'Мащабиране на изображението чрез NVIDIA за по-рязко видео';
	@override String get artcnnVariantNeutral => 'Неутрален';
	@override String get artcnnVariantDenoise => 'Премахване на шум';
	@override String get artcnnVariantDenoiseSharpen => 'Премахване на шум + изостряне';
	@override String get qualityFast => 'Бързо';
	@override String get qualityHQ => 'Високо качество';
	@override String get mode => 'Режим';
	@override String get importShader => 'Импортирай шейдър';
	@override String get customShaderDescription => 'Персонален GLSL шейдър';
	@override String get shaderImported => 'Шейдърът е импортиран';
	@override String get shaderImportFailed => 'Неуспешно импортиране на шейдър';
	@override String get deleteShader => 'Изтрий шейдър';
	@override String deleteShaderConfirm({required Object name}) => 'Да се изтрие ли "${name}"?';
}

// Path: companionRemote
class _TranslationsCompanionRemoteBg extends TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Дистанционно управление';
	@override String connectedTo({required Object name}) => 'Свързан към ${name}';
	@override String get unknownDevice => 'Непознато устройство';
	@override late final _TranslationsCompanionRemoteSessionBg session = _TranslationsCompanionRemoteSessionBg._(_root);
	@override late final _TranslationsCompanionRemotePairingBg pairing = _TranslationsCompanionRemotePairingBg._(_root);
	@override late final _TranslationsCompanionRemoteRemoteBg remote = _TranslationsCompanionRemoteRemoteBg._(_root);
	@override late final _TranslationsCompanionRemoteErrorsBg errors = _TranslationsCompanionRemoteErrorsBg._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsBg extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Скорост на възпроизвеждане';
	@override String get normalSpeed => 'Нормална';
	@override String sleepTimerActive({required Object duration}) => 'Активен (${duration})';
	@override String get zoom => 'Мащаб';
	@override String get sleepTimer => 'Таймер за заспиване';
	@override String get audioSync => 'Синхронизация на аудио';
	@override String get subtitleSync => 'Синхронизация на субтитри';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Аудио изход';
	@override String get performanceOverlay => 'Оверлей за производителност';
	@override String get audioPassthrough => 'Аудио passthrough';
	@override String get audioNormalization => 'Нормализиране на силата на звука';
	@override String get audioDownmix => 'Смесване до стерео';
}

// Path: performanceOverlay
class _TranslationsPerformanceOverlayBg extends TranslationsPerformanceOverlayEn {
	_TranslationsPerformanceOverlayBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get color => 'Цвят';
	@override String get performance => 'Производителност';
	@override String get buffer => 'Буфер';
	@override String get app => 'Приложение';
	@override String get decoder => 'Декодер';
	@override String get rawDecoder => 'Суров декодер';
	@override String get tunneling => 'Тунелиране';
	@override String get aspect => 'Съотношение';
	@override String get rotation => 'Завъртане';
	@override String get dvSource => 'DV източник';
	@override String get dvPath => 'DV път';
	@override String get p7Conversion => 'P7 конв.';
	@override String get sampleRate => 'Честота';
	@override String get pixelFormat => 'Пикселен формат';
	@override String get hwFormat => 'HW формат';
	@override String get matrix => 'Матрица';
	@override String get primaries => 'Основни цветове';
	@override String get transfer => 'Трансфер';
	@override String get renderFps => 'Render FPS';
	@override String get displayFps => 'Display FPS';
	@override String get avSync => 'A/V синхр.';
	@override String get dropped => 'Изпуснати';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'Средно DV RPU';
	@override String get dvSampleAverage => 'Средно DV семпл';
	@override String get maxLuma => 'Макс. яркост';
	@override String get minLuma => 'Мин. яркост';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Използван кеш';
	@override String get cacheLimit => 'Лимит на кеша';
	@override String get speed => 'Скорост';
	@override String get player => 'Плеър';
	@override String get memory => 'Памет';
	@override String get uiFps => 'UI FPS';
}

// Path: externalPlayer
class _TranslationsExternalPlayerBg extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Външен плеър';
	@override String get useExternalPlayer => 'Използвай външен плеър';
	@override String get useExternalPlayerDescription => 'Отваряй видеата в друго приложение';
	@override String get selectPlayer => 'Избери плейър';
	@override String get customPlayers => 'Персонални плейъри';
	@override String get systemDefault => 'Системен по подразбиране';
	@override String get addCustomPlayer => 'Добави персонален плейър';
	@override String get playerName => 'Име на плейъра';
	@override String get playerNameHint => 'Моят плеър';
	@override String get playerCommand => 'Команда';
	@override String get playerPackage => 'Име на пакет';
	@override String get playerUrlScheme => 'URL схема';
	@override String get off => 'Изключено';
	@override String get launchFailed => 'Неуспешно отваряне на външен плеър';
	@override String appNotInstalled({required Object name}) => '${name} не е инсталиран';
	@override String get playInExternalPlayer => 'Пусни във външен плеър';
}

// Path: metadataEdit
class _TranslationsMetadataEditBg extends TranslationsMetadataEditEn {
	_TranslationsMetadataEditBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Редактирай...';
	@override String get screenTitle => 'Редактиране на метаданни';
	@override String get basicInfo => 'Основна информация';
	@override String get artwork => 'Обложка';
	@override String get advancedSettings => 'Разширени настройки';
	@override String get title => 'Заглавие';
	@override String get sortTitle => 'Заглавие за сортиране';
	@override String get originalTitle => 'Оригинално заглавие';
	@override String get releaseDate => 'Дата на излизане';
	@override String get contentRating => 'Възрастов рейтинг';
	@override String get studio => 'Студио';
	@override String get tagline => 'Слоган';
	@override String get summary => 'Резюме';
	@override String get poster => 'Постер';
	@override String get background => 'Фон';
	@override String get logo => 'Лого';
	@override String get squareArt => 'Квадратно изображение';
	@override String get selectPoster => 'Избери постер';
	@override String get selectBackground => 'Избери фон';
	@override String get selectLogo => 'Избери лого';
	@override String get selectSquareArt => 'Избери квадратно изображение';
	@override String get fromUrl => 'От URL';
	@override String get uploadFile => 'Качи файл';
	@override String get enterImageUrl => 'Въведете URL на изображение';
	@override String get imageUrl => 'URL на изображение';
	@override String get metadataUpdated => 'Метаданните са обновени';
	@override String get metadataUpdateFailed => 'Неуспешно обновяване на метаданни';
	@override String get artworkUpdated => 'Обложката е обновена';
	@override String get artworkUpdateFailed => 'Неуспешно обновяване на обложката';
	@override String get noArtworkAvailable => 'Няма налична обложка';
	@override String artworkOption({required Object index}) => 'Вариант за обложка ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Вариант за обложка ${index}, избран';
	@override String get notSet => 'Не е зададено';
	@override String get libraryDefault => 'По подразбиране за библиотеката';
	@override String get accountDefault => 'По подразбиране за акаунта';
	@override String get seriesDefault => 'По подразбиране за сериала';
	@override String get episodeSorting => 'Сортиране на епизоди';
	@override String get oldestFirst => 'Най-старите първо';
	@override String get newestFirst => 'Най-новите първо';
	@override String get keep => 'Пази';
	@override String get allEpisodes => 'Всички епизоди';
	@override String latestEpisodes({required Object count}) => '${count} последни епизода';
	@override String get latestEpisode => 'Последен епизод';
	@override String episodesAddedPastDays({required Object count}) => 'Епизоди, добавени през последните ${count} дни';
	@override String get deleteAfterPlaying => 'Изтрий епизодите след възпроизвеждане';
	@override String get never => 'Никога';
	@override String get afterADay => 'След един ден';
	@override String get afterAWeek => 'След една седмица';
	@override String get afterAMonth => 'След един месец';
	@override String get onNextRefresh => 'При следващо опресняване';
	@override String get seasons => 'Сезони';
	@override String get show => 'Покажи';
	@override String get hide => 'Скрий';
	@override String get episodeOrdering => 'Подредба на епизодите';
	@override String get tmdbAiring => 'The Movie Database (Aired)';
	@override String get tvdbAiring => 'TheTVDB (Aired)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolute)';
	@override String get metadataLanguage => 'Език на метаданните';
	@override String get useOriginalTitle => 'Използвай оригиналното заглавие';
	@override String get preferredAudioLanguage => 'Предпочитан аудио език';
	@override String get preferredSubtitleLanguage => 'Предпочитан език за субтитри';
	@override String get subtitleMode => 'Режим за автоматичен избор на субтитри';
	@override String get manuallySelected => 'Ръчно избрано';
	@override String get shownWithForeignAudio => 'Показва се при чуждо аудио';
	@override String get alwaysEnabled => 'Винаги включено';
	@override String get tags => 'Тагове';
	@override String get addTag => 'Добави таг';
	@override String get genre => 'Жанр';
	@override String get director => 'Режисьор';
	@override String get writer => 'Сценарист';
	@override String get producer => 'Продуцент';
	@override String get country => 'Държава';
	@override String get collection => 'Колекция';
	@override String get label => 'Етикет';
	@override String get style => 'Стил';
	@override String get mood => 'Настроение';
}

// Path: matchScreen
class _TranslationsMatchScreenBg extends TranslationsMatchScreenEn {
	_TranslationsMatchScreenBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get match => 'Съпостави...';
	@override String get fixMatch => 'Поправи съвпадение...';
	@override String get unmatch => 'Премахни съвпадение';
	@override String get unmatchConfirm => 'Да се изчисти ли това съвпадение? Plex ще го третира като несъпоставено, докато не бъде съпоставено отново.';
	@override String get unmatchSuccess => 'Съвпадението на елемента е премахнато';
	@override String get unmatchFailed => 'Неуспешно премахване на съвпадението на елемента';
	@override String get matchApplied => 'Съвпадението е приложено';
	@override String get matchFailed => 'Неуспешно прилагане на съвпадение';
	@override String get titleHint => 'Заглавие';
	@override String get yearHint => 'Година';
	@override String get search => 'Търсене';
	@override String get noMatchesFound => 'Няма намерени съвпадения';
}

// Path: serverTasks
class _TranslationsServerTasksBg extends TranslationsServerTasksEn {
	_TranslationsServerTasksBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Задачи на сървъра';
	@override String get failedToLoad => 'Неуспешно зареждане на задачи';
	@override String get noTasks => 'Няма изпълняващи се задачи';
}

// Path: trakt
class _TranslationsTraktBg extends TranslationsTraktEn {
	_TranslationsTraktBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Свързан';
	@override String connectedAs({required Object username}) => 'Свързан като @${username}';
	@override String get disconnectConfirm => 'Да се прекъсне ли Trakt акаунтът?';
	@override String get disconnectConfirmBody => 'Plezy ще спре да изпраща събития към Trakt. Можете да се свържете отново по всяко време.';
	@override String get scrobble => 'Скроблиране в реално време';
	@override String get scrobbleDescription => 'Изпращай събития за пускане, пауза и спиране към Trakt по време на възпроизвеждане.';
	@override String get watchedSync => 'Синхронизирай статус гледано';
	@override String get watchedSyncDescription => 'Когато маркирате елементи като гледани в Plezy, маркирай ги и в Trakt.';
}

// Path: seerr
class _TranslationsSeerrBg extends TranslationsSeerrEn {
	_TranslationsSeerrBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Свързване със Seerr';
	@override String get serverUrl => 'URL на сървъра';
	@override String get serverUrlHelper => 'Адресът на твоята Seerr инстанция';
	@override String get checkServer => 'Продължи';
	@override String get signInWithJellyfin => 'Вход с Jellyfin';
	@override String get signInWithEmby => 'Вход с Emby';
	@override String get signInWithLocal => 'Използвай локален акаунт';
	@override String get email => 'Имейл';
	@override String get noSignInMethods => 'Тази Seerr инстанция не предлага метод за вход, който Plezy поддържа.';
	@override String get instance => 'Инстанция';
	@override String get disconnectConfirm => 'Да се прекъсне ли Seerr?';
	@override String get disconnectConfirmBody => 'Plezy ще забрави тази Seerr инстанция. Можете да се свържете отново по всяко време.';
	@override String get request => 'Заяви';
	@override String get request4k => 'Заяви в 4K';
	@override String get seasons => 'Сезони';
	@override String get allSeasons => 'Всички сезони';
	@override String get advancedOptions => 'Разширени';
	@override String get destinationServer => 'Целеви сървър';
	@override String get qualityProfile => 'Профил за качество';
	@override String get rootFolder => 'Основна папка';
	@override String get languageProfile => 'Езиков профил';
	@override String get requestSubmitted => 'Заявката е изпратена';
	@override String requestFailed({required Object error}) => 'Заявката се провали: ${error}';
	@override String get requestsLoadFailed => 'Неуспешно зареждане на опциите за заявка';
	@override String get nothingToRequest => 'Всичко вече е налично или заявено.';
	@override String get statusAvailable => 'Налично';
	@override String get statusPartiallyAvailable => 'Частично налично';
	@override String get statusRequested => 'Заявено';
	@override String get statusProcessing => 'Обработва се';
}

// Path: services
class _TranslationsServicesBg extends TranslationsServicesEn {
	_TranslationsServicesBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Услуги';
	@override String get hubSubtitle => 'Синхронизирай прогреса на гледане и заявявай нови заглавия.';
	@override String get notConnected => 'Не е свързан';
	@override String connectedAs({required Object username}) => 'Свързан като @${username}';
	@override String get scrobble => 'Проследявай прогреса автоматично';
	@override String get scrobbleDescription => 'Обновявай списъка си, когато завършиш епизод или филм.';
	@override String disconnectConfirm({required Object service}) => 'Да се прекъсне ли ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy ще спре да обновява ${service}. Можете да се свържете отново по всяко време.';
	@override String connectFailed({required Object service}) => 'Неуспешно свързване с ${service}. Опитайте отново.';
	@override late final _TranslationsServicesNamesBg names = _TranslationsServicesNamesBg._(_root);
	@override late final _TranslationsServicesDeviceCodeBg deviceCode = _TranslationsServicesDeviceCodeBg._(_root);
	@override late final _TranslationsServicesOauthProxyBg oauthProxy = _TranslationsServicesOauthProxyBg._(_root);
	@override late final _TranslationsServicesLibraryFilterBg libraryFilter = _TranslationsServicesLibraryFilterBg._(_root);
}

// Path: addServer
class _TranslationsAddServerBg extends TranslationsAddServerEn {
	_TranslationsAddServerBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Добави Jellyfin сървър';
	@override String get serverUrls => 'URL адреси на сървъра';
	@override String get serverUrlsHelper => 'Позволени са няколко URL адреса, разделени със запетаи.';
	@override String get findServer => 'Намери сървър';
	@override String get searchingLocalServers => 'Търсене на локални Jellyfin сървъри...';
	@override String get localServers => 'Локални Jellyfin сървъри';
	@override String get username => 'Потребителско име';
	@override String get password => 'Парола';
	@override String get signIn => 'Вход';
	@override String get change => 'Промени';
	@override String get required => 'Задължително';
	@override String couldNotReachServer({required Object error}) => 'Сървърът не може да бъде достигнат: ${error}';
	@override String signInFailed({required Object error}) => 'Входът е неуспешен: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect е неуспешен: ${error}';
	@override String get addPlexTitle => 'Вход с Plex';
	@override String get pinExpired => 'PIN-ът изтече преди вход. Моля, опитайте отново.';
	@override String failedToRegisterAccount({required Object error}) => 'Неуспешна регистрация на акаунт: ${error}';
	@override String get enterJellyfinUrlError => 'Въведете URL адреса на вашия Jellyfin сървър';
	@override String get addConnectionTitle => 'Добави връзка';
	@override String addConnectionTitleScoped({required Object name}) => 'Добави към ${name}';
	@override String get signInWithPlexCard => 'Вход с Plex';
	@override String get signInWithPlexCardSubtitle => 'Удостоверете това устройство. Споделените сървъри се добавят.';
	@override String get signInWithPlexCardSubtitleScoped => 'Удостоверете Plex акаунт. Домашните потребители стават профили.';
	@override String get connectToJellyfinCard => 'Свързване с Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Въведете URL адрес на сървъра, потребителско име и парола.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Вход в Jellyfin сървър. Свързва се с ${name}.';
	@override String get borrowFromAnotherProfile => 'Използвай от друг профил';
	@override String get borrowFromAnotherProfileSubtitle => 'Използвай връзка от друг профил. PIN-защитените профили изискват PIN.';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsBg extends TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Пускане/пауза';
	@override String get volumeUp => 'Увеличи звука';
	@override String get volumeDown => 'Намали звука';
	@override String seekForward({required Object seconds}) => 'Превърти напред (${seconds}сек)';
	@override String seekBackward({required Object seconds}) => 'Превърти назад (${seconds}сек)';
	@override String get fullscreenToggle => 'Превключи цял екран';
	@override String get muteToggle => 'Превключи заглушаване';
	@override String get subtitleToggle => 'Превключи субтитри';
	@override String get audioTrackNext => 'Следващ аудио запис';
	@override String get subtitleTrackNext => 'Следващ субтитърен запис';
	@override String get chapterNext => 'Следваща глава';
	@override String get chapterPrevious => 'Предишна глава';
	@override String get episodeNext => 'Следващ епизод';
	@override String get episodePrevious => 'Предишен епизод';
	@override String get speedIncrease => 'Увеличи скоростта';
	@override String get speedDecrease => 'Намали скоростта';
	@override String get speedReset => 'Нулирай скоростта';
	@override String get zoomIn => 'Увеличи мащаба';
	@override String get zoomOut => 'Намали мащаба';
	@override String get zoomReset => 'Нулирай мащаба';
	@override String get subSeekNext => 'Отиди до следващ субтитър';
	@override String get subSeekPrev => 'Отиди до предишен субтитър';
	@override String get shaderToggle => 'Превключи шейдъри';
	@override String get skipMarker => 'Прескочи интро/финални надписи';
	@override String get screenshot => 'Направи екранна снимка';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsBg extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Изисква Android 8.0 или по-нова версия';
	@override String get iosVersion => 'Изисква iOS 15.0 или по-нова версия';
	@override String get permissionDisabled => 'Режимът картина в картината е изключен. Включете го в системните настройки.';
	@override String get notSupported => 'Устройството не поддържа режим картина в картината';
	@override String get voSwitchFailed => 'Неуспешна смяна на видео изхода за режим картина в картината';
	@override String get failed => 'Режимът картина в картината не успя да стартира';
	@override String unknown({required Object error}) => 'Възникна грешка: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsBg extends TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Препоръчани';
	@override String get browse => 'Преглед';
	@override String get collections => 'Колекции';
	@override String get playlists => 'Плейлисти';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsBg extends TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Групиране';
	@override String get all => 'Всички';
	@override String get movies => 'Филми';
	@override String get shows => 'ТВ сериали';
	@override String get seasons => 'Сезони';
	@override String get episodes => 'Епизоди';
	@override String get artists => 'Изпълнители';
	@override String get albums => 'Албуми';
	@override String get tracks => 'Песни';
	@override String get folders => 'Папки';
}

// Path: libraries.filterCategories
class _TranslationsLibrariesFilterCategoriesBg extends TranslationsLibrariesFilterCategoriesEn {
	_TranslationsLibrariesFilterCategoriesBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Жанр';
	@override String get year => 'Година';
	@override String get contentRating => 'Възрастов рейтинг';
	@override String get tag => 'Таг';
	@override String get unwatched => 'Негледани';
	@override String get unplayed => 'Непускани';
	@override String get favorites => 'Любими';
}

// Path: libraries.sortLabels
class _TranslationsLibrariesSortLabelsBg extends TranslationsLibrariesSortLabelsEn {
	_TranslationsLibrariesSortLabelsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Заглавие';
	@override String get dateAdded => 'Дата на добавяне';
	@override String get releaseDate => 'Дата на излизане';
	@override String get rating => 'Рейтинг';
	@override String get communityRating => 'Оценка от общността';
	@override String get criticRating => 'Оценка от критиците';
	@override String get userRating => 'Потребителска оценка';
	@override String get datePlayed => 'Дата на възпроизвеждане';
	@override String get playCount => 'Брой възпроизвеждания';
	@override String get productionYear => 'Година на производство';
	@override String get runtime => 'Продължителност';
	@override String get officialRating => 'Официален рейтинг';
	@override String get premiereDate => 'Дата на премиера';
	@override String get startDate => 'Начална дата';
	@override String get airTime => 'Час на излъчване';
	@override String get studio => 'Студио';
	@override String get random => 'Случайно';
	@override String get dateShared => 'Дата на споделяне';
	@override String get latestEpisodeAirDate => 'Дата на излъчване на последния епизод';
	@override String get lastEpisodeDateAdded => 'Дата на добавяне на последния епизод';
}

// Path: explore.rows
class _TranslationsExploreRowsBg extends TranslationsExploreRowsEn {
	_TranslationsExploreRowsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Списък за гледане';
	@override String get recommendedMovies => 'Препоръчани филми';
	@override String get recommendedShows => 'Препоръчани сериали';
	@override String get trendingMovies => 'Актуални филми';
	@override String get trendingShows => 'Актуални сериали';
	@override String get popularMovies => 'Популярни филми';
	@override String get popularShows => 'Популярни сериали';
	@override String get suggestedAnime => 'Препоръчани аниме';
	@override String get airingAnime => 'Топ излъчвани аниме';
	@override String get popularAnime => 'Най-популярни аниме';
	@override String get trending => 'Актуални';
	@override String get upcomingMovies => 'Предстоящи филми';
	@override String get upcomingShows => 'Предстоящи сериали';
}

// Path: explore.status
class _TranslationsExploreStatusBg extends TranslationsExploreStatusEn {
	_TranslationsExploreStatusBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Излъчва се';
	@override String get ended => 'Приключил';
	@override String get canceled => 'Отменен';
	@override String get upcoming => 'Предстоящ';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionBg extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Стартиране на сървър за дистанционно управление...';
	@override String get hostAddress => 'Адрес на хоста';
	@override String get connected => 'Свързан';
	@override String get serverRunning => 'Сървърът за дистанционно управление е активен';
	@override String get serverStopped => 'Сървърът за дистанционно управление е спрян';
	@override String get serverRunningDescription => 'Мобилни устройства във вашата мрежа могат да се свързват с това приложение';
	@override String get serverStoppedDescription => 'Стартирайте сървъра, за да позволите на мобилни устройства да се свързват';
	@override String get usePhoneToControl => 'Използвайте мобилното си устройство, за да управлявате това приложение';
	@override String get startServer => 'Стартирай сървър';
	@override String get stopServer => 'Спри сървър';
	@override String get minimize => 'Минимизирай';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingBg extends TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Plezy устройства със същия Plex акаунт се показват тук';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Свързване...';
	@override String get searchingForDevices => 'Търсене на устройства...';
	@override String get noDevicesFound => 'Не са намерени устройства във вашата мрежа';
	@override String get noDevicesHint => 'Отворете Plezy на настолен компютър и използвайте същия WiFi';
	@override String get availableDevices => 'Налични устройства';
	@override String get manualConnection => 'Ръчно свързване';
	@override String get cryptoInitFailed => 'Не може да се стартира защитена връзка. Първо влезте в Plex.';
	@override String get validationHostRequired => 'Моля, въведете адрес на хоста';
	@override String get validationHostFormat => 'Форматът трябва да е IP:port (напр. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Връзката изтече. Използвайте една и съща мрежа на двете устройства.';
	@override String get sessionNotFound => 'Устройството не е намерено. Уверете се, че Plezy работи на хоста.';
	@override String get authFailed => 'Удостоверяването е неуспешно. Двете устройства трябва да използват същия Plex акаунт.';
	@override String failedToConnect({required Object error}) => 'Неуспешно свързване: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteBg extends TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Искате ли да прекъснете връзката с дистанционната сесия?';
	@override String get reconnecting => 'Повторно свързване...';
	@override String attemptOf({required Object current}) => 'Опит ${current} от 5';
	@override String get retryNow => 'Опитай сега';
	@override String get tabRemote => 'Дистанционно';
	@override String get tabPlay => 'Пускане';
	@override String get tabMore => 'Още';
	@override String get menu => 'Меню';
	@override String get tabNavigation => 'Навигация с Tab';
	@override String get tabDiscover => 'Открий';
	@override String get tabLibraries => 'Библиотеки';
	@override String get tabSearch => 'Търсене';
	@override String get tabDownloads => 'Изтегляния';
	@override String get tabSettings => 'Настройки';
	@override String get previous => 'Предишен';
	@override String get playPause => 'Пускане/пауза';
	@override String get next => 'Следващ';
	@override String get seekBack => 'Назад';
	@override String get stop => 'Стоп';
	@override String get seekForward => 'Напред';
	@override String get volume => 'Звук';
	@override String get volumeDown => 'Надолу';
	@override String get volumeUp => 'Нагоре';
	@override String get fullscreen => 'Цял екран';
	@override String get subtitles => 'Субтитри';
	@override String get audio => 'Аудио';
	@override String get searchHint => 'Търсене на настолен компютър...';
}

// Path: companionRemote.errors
class _TranslationsCompanionRemoteErrorsBg extends TranslationsCompanionRemoteErrorsEn {
	_TranslationsCompanionRemoteErrorsBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Не е намерен мрежов интерфейс';
	@override String get authenticationFailed => 'Неуспешно удостоверяване';
	@override String serverStartFailed({required Object error}) => 'Неуспешно стартиране на отдалечения сървър: ${error}';
	@override String commandFailed({required Object error}) => 'Неуспешно изпращане на отдалечена команда: ${error}';
	@override String get joinTimedOut => 'Времето за присъединяване към сесията изтече';
	@override String get failedToConnectAnyAddress => 'Неуспешно свързване към който и да е адрес';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Връзката е загубена след ${attempts} опита';
	@override String get connectionLost => 'Връзката е загубена';
}

// Path: services.names
class _TranslationsServicesNamesBg extends TranslationsServicesNamesEn {
	_TranslationsServicesNamesBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _TranslationsServicesDeviceCodeBg extends TranslationsServicesDeviceCodeEn {
	_TranslationsServicesDeviceCodeBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Активиране на Plezy в ${service}';
	@override String body({required Object url}) => 'Посетете ${url} и въведете този код:';
	@override String openToActivate({required Object service}) => 'Отворете ${service}, за да активирате';
	@override String get copyCode => 'Копирай кода за активиране';
	@override String get waitingForAuthorization => 'Изчакване на оторизация…';
	@override String get codeCopied => 'Кодът е копиран';
}

// Path: services.oauthProxy
class _TranslationsServicesOauthProxyBg extends TranslationsServicesOauthProxyEn {
	_TranslationsServicesOauthProxyBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Вход в ${service}';
	@override String get body => 'Сканирайте този QR код или отворете URL-а на което и да е устройство.';
	@override String openToSignIn({required Object service}) => 'Отворете ${service}, за да влезете';
	@override String get copyUrl => 'Копирай URL адреса за вход';
	@override String get urlCopied => 'URL адресът е копиран';
}

// Path: services.libraryFilter
class _TranslationsServicesLibraryFilterBg extends TranslationsServicesLibraryFilterEn {
	_TranslationsServicesLibraryFilterBg._(TranslationsBg root) : this._root = root, super.internal(root);

	final TranslationsBg _root; // ignore: unused_field

	// Translations
	@override String get title => 'Филтър на библиотеките';
	@override String get subtitleAllSyncing => 'Синхронизират се всички библиотеки';
	@override String get subtitleNoneSyncing => 'Нищо не се синхронизира';
	@override String subtitleBlocked({required Object count}) => '${count} блокирани';
	@override String subtitleAllowed({required Object count}) => '${count} разрешени';
	@override String get mode => 'Режим на филтъра';
	@override String get modeBlacklist => 'Черен списък';
	@override String get modeWhitelist => 'Бял списък';
	@override String get modeHintBlacklist => 'Синхронизирай всяка библиотека, освен отметнатите по-долу.';
	@override String get modeHintWhitelist => 'Синхронизирай само отметнатите по-долу библиотеки.';
	@override String get libraries => 'Библиотеки';
	@override String get noLibraries => 'Няма налични библиотеки';
}

/// The flat map containing all translations for locale <bg>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsBg {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Вход с Plex',
			'auth.showQRCode' => 'Покажи QR код',
			'auth.authenticate' => 'Удостовери',
			'auth.authenticationTimeout' => 'Времето за удостоверяване изтече. Моля, опитайте отново.',
			'auth.scanQRToSignIn' => 'Сканирайте този QR код, за да влезете',
			'auth.waitingForAuth' => 'Изчакване на удостоверяване...\nВлезте от браузъра си.',
			'auth.useBrowser' => 'Използвай браузър',
			'auth.or' => 'или',
			'auth.connectToJellyfin' => 'Свързване с Jellyfin',
			'auth.useQuickConnect' => 'Използвай Quick Connect',
			'auth.quickConnectInstructions' => 'Отворете Quick Connect в Jellyfin и въведете този код.',
			'auth.quickConnectWaiting' => 'Изчакване на одобрение…',
			'auth.quickConnectCancel' => 'Отказ',
			'auth.quickConnectExpired' => 'Quick Connect изтече. Опитайте отново.',
			'common.cancel' => 'Отказ',
			'common.save' => 'Запази',
			'common.close' => 'Затвори',
			'common.clear' => 'Изчисти',
			'common.reset' => 'Нулирай',
			'common.later' => 'По-късно',
			'common.submit' => 'Изпрати',
			'common.confirm' => 'Потвърди',
			'common.retry' => 'Опитай отново',
			'common.logout' => 'Изход',
			'common.unknown' => 'Неизвестно',
			'common.refresh' => 'Опресни',
			'common.yes' => 'Да',
			'common.no' => 'Не',
			'common.delete' => 'Изтрий',
			'common.edit' => 'Редактирай',
			'common.shuffle' => 'Разбъркай',
			'common.addTo' => 'Добави към...',
			'common.createNew' => 'Създай нов',
			'common.connect' => 'Свържи',
			'common.disconnect' => 'Прекъсни връзката',
			'common.play' => 'Пусни',
			'common.pause' => 'Пауза',
			'common.resume' => 'Продължи',
			'common.error' => 'Грешка',
			'common.search' => 'Търсене',
			'common.home' => 'Начало',
			'common.back' => 'Назад',
			'common.settings' => 'Настройки',
			'common.mute' => 'Заглуши',
			'common.ok' => 'OK',
			'common.off' => 'Изкл.',
			'common.seasonNumber' => ({required Object number}) => 'Сезон ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Епизод ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Глава ${number}',
			'common.reconnect' => 'Свържи отново',
			'common.viewAll' => 'Виж всички',
			'common.checkingNetwork' => 'Проверка на мрежата...',
			'common.loadingServers' => 'Зареждане на сървърите...',
			'common.connectingToServers' => 'Свързване със сървърите...',
			'common.startingOfflineMode' => 'Стартиране на офлайн режим...',
			'common.loading' => 'Зареждане...',
			'common.fullscreen' => 'На цял екран',
			'common.exitFullscreen' => 'Изход от цял екран',
			'common.pressBackAgainToExit' => 'Натиснете Назад отново, за да излезете',
			'screens.licenses' => 'Лицензи',
			'screens.switchProfile' => 'Смяна на профил',
			'screens.subtitleStyling' => 'Стил на субтитрите',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Логове',
			'update.available' => 'Налична е актуализация',
			'update.versionAvailable' => ({required Object version}) => 'Налична е версия ${version}',
			'update.currentVersion' => ({required Object version}) => 'Текуща: ${version}',
			'update.skipVersion' => 'Пропусни тази версия',
			'update.viewRelease' => 'Виж версията',
			'update.latestVersion' => 'Използвате най-новата версия',
			'update.checkFailed' => 'Неуспешна проверка за актуализации',
			'settings.title' => 'Настройки',
			'settings.supportDeveloper' => 'Подкрепи Plezy',
			'settings.supportDeveloperDescription' => 'Дарение чрез Liberapay за финансиране на разработката',
			'settings.language' => 'Език',
			'settings.theme' => 'Тема',
			'settings.appearance' => 'Изглед',
			'settings.videoPlayback' => 'Възпроизвеждане на видео',
			'settings.videoPlaybackDescription' => 'Настройване на поведението при възпроизвеждане',
			'settings.advanced' => 'Разширени',
			'settings.episodePosterMode' => 'Стил на постера за епизод',
			'settings.seriesPoster' => 'Постер на сериала',
			'settings.seasonPoster' => 'Постер на сезона',
			'settings.episodeThumbnail' => 'Миниатюра',
			'settings.showHeroSectionDescription' => 'Показване на карусел с избрано съдържание на началния екран',
			'settings.secondsLabel' => 'Секунди',
			'settings.minutesLabel' => 'Минути',
			'settings.secondsShort' => 'сек',
			'settings.minutesShort' => 'мин',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Въведете продължителност (${min}-${max})',
			'settings.systemTheme' => 'Системна',
			'settings.lightTheme' => 'Светла',
			'settings.darkTheme' => 'Тъмна',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Плътност на библиотеката',
			'settings.compact' => 'Компактна',
			'settings.comfortable' => 'Удобна',
			'settings.viewMode' => 'Режим на изглед',
			'settings.gridView' => 'Мрежа',
			'settings.listView' => 'Списък',
			'settings.showHeroSection' => 'Показвай водеща секция',
			'settings.continueWatchingAction' => 'Действие за продължаване на гледането',
			'settings.continueWatchingPlay' => 'Пусни',
			'settings.continueWatchingDetails' => 'Отвори подробности',
			'settings.episodeAction' => 'Действие за епизод',
			'settings.episodePlay' => 'Пусни',
			'settings.episodeDetails' => 'Отвори подробности',
			'settings.useGlobalHubs' => 'Използвай начално оформление',
			'settings.useGlobalHubsDescription' => 'Показвай обединени начални хъбове. В противен случай използвай препоръките на библиотеката.',
			'settings.showServerNameOnHubs' => 'Показвай името на сървъра в хъбовете',
			'settings.showServerNameOnHubsDescription' => 'Винаги показвай имената на сървърите в заглавията на хъбовете.',
			'settings.groupLibrariesByServer' => 'Групирай библиотеките по сървър',
			'settings.groupLibrariesByServerDescription' => 'Групирай библиотеките в страничната лента под всеки медиен сървър.',
			'settings.alwaysKeepSidebarOpen' => 'Винаги дръж страничната лента отворена',
			'settings.alwaysKeepSidebarOpenDescription' => 'Страничната лента остава разгъната и зоната със съдържание се наглася да пасне',
			'settings.showUnwatchedCount' => 'Показвай броя негледани',
			'settings.showUnwatchedCountDescription' => 'Показвай броя негледани епизоди при сериали и сезони',
			'settings.showEpisodeNumberOnCards' => 'Показвай номера на епизода върху картите',
			'settings.showEpisodeNumberOnCardsDescription' => 'Показвай сезон и номер на епизод върху картите на епизодите',
			'settings.showSeasonPostersOnTabs' => 'Показвай постери на сезоните в табовете',
			'settings.showSeasonPostersOnTabsDescription' => 'Показвай постера на всеки сезон над неговия таб',
			'settings.tvFullCardLayout' => 'Пълни TV карти',
			'settings.tvFullCardLayoutDescription' => 'Използвай TV карти само с изображения, с насложени имена на актьорите',
			'settings.focusGlow' => 'Сияние при фокус',
			'settings.focusGlowDescription' => 'Показвай меко сияние около фокусираната карта',
			'settings.visualEffects' => 'Визуални ефекти',
			'settings.visualEffectsAuto' => 'Автоматично',
			'settings.visualEffectsAutoDescription' => 'Автоматично намалявай ефектите на по-слаби устройства',
			'settings.visualEffectsFull' => 'Пълни',
			'settings.visualEffectsReduced' => 'Намалени',
			'settings.visualEffectsReducedDescription' => 'По-малко анимации и изображения с по-ниска резолюция',
			'settings.hideSpoilers' => 'Скривай спойлери за негледани епизоди',
			'settings.hideSpoilersDescription' => 'Замазвай миниатюри и описания за негледани епизоди',
			'settings.playerBackend' => 'Енджин на плеъра',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Хардуерно декодиране',
			'settings.hardwareDecodingDescription' => 'Използвай хардуерно ускорение, когато е налично',
			'settings.bufferSize' => 'Размер на буфера',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Автоматично (препоръчително)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Налична памет ${heap}MB. Буфер ${size}MB може да повлияе на възпроизвеждането.',
			'settings.defaultQualityTitle' => 'Качество по подразбиране',
			'settings.musicQualityTitle' => 'Качество на музиката',
			'settings.subtitleStyling' => 'Стил на субтитрите',
			'settings.subtitleStylingDescription' => 'Настройване на вида на субтитрите',
			'settings.smallSkipDuration' => 'Малко прескачане',
			'settings.largeSkipDuration' => 'Голямо прескачане',
			'settings.rewindOnResume' => 'Връщане назад при продължаване',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} секунди',
			'settings.defaultSleepTimer' => 'Таймер за заспиване по подразбиране',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} минути',
			'settings.rememberTrackSelections' => 'Запомняй избора на аудио/субтитри за сериал/филм',
			'settings.rememberTrackSelectionsDescription' => 'Запомняй избора на аудио и субтитри за всяко заглавие',
			'settings.showChapterMarkersOnTimeline' => 'Показвай маркери на глави върху времевата линия',
			'settings.showChapterMarkersOnTimelineDescription' => 'Разделяй времевата линия на сегменти по границите на главите',
			'settings.clickVideoTogglesPlayback' => 'Клик върху видеото превключва възпроизвеждане/пауза',
			'settings.clickVideoTogglesPlaybackDescription' => 'Клик върху видеото пуска/паузира вместо да показва контролите.',
			'settings.videoPlayerControls' => 'Контроли на видео плейъра',
			'settings.keyboardShortcuts' => 'Клавишни комбинации',
			'settings.keyboardShortcutsDescription' => 'Настройване на клавишните комбинации',
			'settings.videoPlayerNavigation' => 'Навигация във видео плейъра',
			'settings.videoPlayerNavigationDescription' => 'Използвай стрелките за навигация в контролите на видео плейъра',
			'settings.watchTogetherRelay' => 'Релей сървър за гледане заедно',
			'settings.watchTogetherRelayDescription' => 'Задай собствен релей сървър. Всички трябва да използват същия сървър.',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.crashReporting' => 'Докладване на сривове',
			'settings.crashReportingDescription' => 'Изпращай доклади за сривове, за да помогнеш за подобряване на приложението',
			'settings.debugLogging' => 'Логове за отстраняване на грешки',
			'settings.debugLoggingDescription' => 'Включи подробни логове за диагностика',
			'settings.viewLogs' => 'Виж логовете',
			'settings.viewLogsDescription' => 'Преглед на логовете на приложението',
			'settings.clearCache' => 'Изчисти кеша',
			'settings.clearCacheDescription' => 'Изчисти кешираните изображения и данни. Съдържанието може да се зарежда по-бавно.',
			'settings.clearCacheSuccess' => 'Кешът е изчистен успешно',
			'settings.resetSettings' => 'Нулирай настройките',
			'settings.resetSettingsDescription' => 'Възстанови настройките по подразбиране. Това не може да бъде отменено.',
			'settings.resetSettingsSuccess' => 'Настройките са нулирани успешно',
			'settings.backup' => 'Резервно копие',
			'settings.exportSettings' => 'Експортирай настройките',
			'settings.exportSettingsDescription' => 'Запази предпочитанията си във файл',
			'settings.exportSettingsSuccess' => 'Настройките са експортирани',
			'settings.exportSettingsFailed' => 'Настройките не можаха да бъдат експортирани',
			'settings.importSettings' => 'Импортирай настройки',
			'settings.importSettingsDescription' => 'Възстанови предпочитания от файл',
			'settings.importSettingsConfirm' => 'Това ще замени текущите ви настройки. Продължавате ли?',
			'settings.importSettingsSuccess' => 'Настройките са импортирани',
			'settings.importSettingsFailed' => 'Настройките не можаха да бъдат импортирани',
			'settings.importSettingsInvalidFile' => 'Този файл не е валиден експорт на настройки от Plezy',
			'settings.importSettingsNoUser' => 'Влезте, преди да импортирате настройки',
			'settings.shortcutsReset' => 'Клавишните комбинации са нулирани до подразбиране',
			'settings.about' => 'Относно',
			'settings.aboutDescription' => 'Информация за приложението и лицензи',
			'settings.updates' => 'Актуализации',
			'settings.updateAvailable' => 'Налична е актуализация',
			'settings.checkForUpdates' => 'Провери за актуализации',
			'settings.autoCheckUpdatesOnStartup' => 'Автоматично проверявай за актуализации при стартиране',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Уведомявай, когато има актуализация при стартиране',
			'settings.validationErrorEnterNumber' => 'Моля, въведете валидно число',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Продължителността трябва да е между ${min} и ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Клавишната комбинация вече е назначена за ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Клавишната комбинация е обновена за ${action}',
			'settings.autoSkip' => 'Автоматично прескачане',
			'settings.autoSkipIntro' => 'Автоматично прескачане на интро',
			'settings.autoSkipIntroDescription' => 'Автоматично прескачай интро маркери след няколко секунди',
			'settings.autoSkipCredits' => 'Автоматично прескачане на финални надписи',
			'settings.autoSkipCreditsDescription' => 'Автоматично прескачай финалните надписи и пускай следващия епизод',
			'settings.forceSkipMarkerFallback' => 'Принуди резервни маркери',
			'settings.forceSkipMarkerFallbackDescription' => 'Използвай шаблони в заглавията на главите дори когато Plex има маркери',
			'settings.autoSkipDelay' => 'Забавяне за автоматично прескачане',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Изчакай ${seconds} секунди преди автоматично прескачане',
			'settings.introPattern' => 'Шаблон за интро маркер',
			'settings.introPatternDescription' => 'Шаблон с регулярен израз за намиране на интро маркери в заглавия на глави',
			'settings.creditsPattern' => 'Шаблон за маркер на финални надписи',
			'settings.creditsPatternDescription' => 'Шаблон с регулярен израз за намиране на маркери за финални надписи в заглавия на глави',
			'settings.invalidRegex' => 'Невалиден регулярен израз',
			'settings.regex' => 'Регулярен израз',
			'settings.downloads' => 'Изтегляния',
			'settings.downloadLocationDescription' => 'Изберете къде да се съхранява изтегленото съдържание',
			'settings.downloadLocationDefault' => 'По подразбиране (хранилище на приложението)',
			'settings.downloadLocationCustom' => 'Персонална локация',
			'settings.selectFolder' => 'Избери папка',
			'settings.resetToDefault' => 'Върни по подразбиране',
			'settings.currentPath' => ({required Object path}) => 'Текущ: ${path}',
			'settings.downloadLocationChanged' => 'Местоположението за изтегляния е променено',
			'settings.downloadLocationReset' => 'Местоположението за изтегляния е върнато по подразбиране',
			'settings.downloadLocationInvalid' => 'Избраната папка не е записваема',
			'settings.downloadLocationSelectError' => 'Неуспешен избор на папка',
			'settings.downloadOnWifiOnly' => 'Изтегляне само през WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Предотвратявай изтегляния през мобилни данни',
			'settings.autoRemoveWatchedDownloads' => 'Автоматично премахвай изгледаните изтегляния',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Изтривай изгледаните изтегляния автоматично',
			'settings.cellularDownloadBlocked' => 'Изтеглянията са блокирани през мобилни данни. Използвайте WiFi или променете настройката.',
			'settings.maxVolume' => 'Максимална сила на звука',
			'settings.maxVolumeDescription' => 'Позволи усилване на звука над 100% за тихи медии',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Показвай какво гледате в Discord',
			'settings.services' => 'Услуги',
			'settings.servicesDescription' => 'Свържи Trakt, MyAnimeList, Seerr и още',
			'settings.manageLibrariesDescription' => 'Пренареждай и скривай библиотеки',
			'settings.companionRemoteServer' => 'Сървър за дистанционно управление',
			'settings.companionRemoteServerDescription' => 'Позволи на мобилни устройства във вашата мрежа да управляват това приложение',
			'settings.autoPip' => 'Автоматичен режим картина в картината',
			'settings.autoPipDescription' => 'Влизай в режим картина в картината при напускане по време на възпроизвеждане',
			'settings.matchContentFrameRate' => 'Напасване към кадровата честота на съдържанието',
			'settings.matchContentFrameRateDescription' => 'Напасни честотата на опресняване на дисплея към видео съдържанието',
			'settings.matchRefreshRate' => 'Напасване на честотата на опресняване',
			'settings.matchRefreshRateDescription' => 'Напасни честотата на опресняване на дисплея при цял екран',
			'settings.matchDynamicRange' => 'Напасване на динамичния диапазон',
			'settings.matchDynamicRangeDescription' => 'Включи HDR за HDR съдържание, после върни към SDR',
			'settings.displaySwitchDelay' => 'Забавяне при смяна на дисплея',
			'settings.tunneledPlayback' => 'Тунелно възпроизвеждане',
			'settings.tunneledPlaybackDescription' => 'Използвай видео тунелиране. Изключете, ако HDR възпроизвеждането показва черен екран.',
			'settings.audioPassthrough' => 'Аудио passthrough',
			'settings.audioPassthroughDescription' => 'Изпращай Dolby/DTS звук към ресийвъра или телевизора без прекодиране, запазвайки съраунд звука. Изключете, ако няма звук.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Предава Dolby Digital Plus (вкл. Atmos) на системата като битов поток. DTS и TrueHD продължават да се възпроизвеждат като многоканален PCM. При превъртане може да има кратки прекъсвания на звука.',
			'settings.audioDownmix' => 'Смесване до стерео',
			'settings.audioDownmixDescription' => 'Смесва съраунд звука до два канала за стерео тонколони или слушалки',
			'settings.downmixCenterBoost' => 'Усилване на централния канал',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} дБ',
			'settings.downmixCenterBoostLabel' => 'Усилване (дБ)',
			'settings.downmixCenterBoostShort' => 'дБ',
			'settings.audioDownmixNormalize' => 'Нормализиране на звука при смесване',
			'settings.audioDownmixNormalizeDescription' => 'Понижава микса, за да се предотврати клипинг. Изключете, за да запазите оригиналната сила на звука (възможни изкривявания при силни сцени).',
			'settings.atmosDiagnostics' => 'Тест на Atmos изхода',
			'settings.atmosDiagnosticsDescription' => 'Диагностика на Dolby Atmos изхода чрез възпроизвеждане на тестови сигнали през системния плейър',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos поток',
			'settings.atmosTestHlsAtmosDescription' => 'Гарантирано работещ Dolby Atmos поток. Ресийвърът трябва да покаже Dolby Atmos.',
			'settings.atmosTestHlsControl' => 'Apple съраунд поток',
			'settings.atmosTestHlsControlDescription' => 'Контролен поток без Atmos. Ресийвърът трябва да покаже съраунд без Atmos.',
			'settings.atmosTestRawStream' => 'Суров EAC3 поток',
			'settings.atmosTestRawStreamDescription' => 'Стриймва тестовия файл точно както Atmos възпроизвеждането в плейъра. Изисква URL на тестовия файл.',
			'settings.atmosTestRawFile' => 'Суров EAC3 файл',
			'settings.atmosTestRawFileDescription' => 'Възпроизвежда тестовия файл с известна дължина. Изисква URL на тестовия файл.',
			'settings.atmosTestStop' => 'Спри теста',
			'settings.atmosTestUrl' => 'URL на тестовия файл',
			'settings.atmosTestUrlDescription' => 'HTTP URL на суров .ec3 Dolby Atmos файл (напр. извлечен с ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Първо задайте URL на тестовия файл',
			'settings.atmosTestStatus' => 'Състояние',
			'settings.dvConversionMode' => 'Dolby Vision конвертиране',
			'settings.dvConversionModeDescription' => 'Изберете как ExoPlayer обработва Dolby Vision Profile 7 файлове.',
			'settings.dvConversionAuto' => 'Автоматично',
			'settings.dvConversionNative' => 'Нативно / изключено',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Използва засичане на възможностите на устройството и нормално fallback поведение',
			'settings.dvConversionNativeDescription' => 'Принуждава нативен DV7 и спира повторния опит за DV конвертиране',
			'settings.dvConversionDv81Description' => 'Принуждава inline RPU конвертиране към Dolby Vision профил 8.1',
			'settings.dvConversionHevcStripDescription' => 'Премахва Dolby Vision RPU/EL слоевете и подава обикновен HEVC',
			'settings.requireProfileSelectionOnOpen' => 'Питай за профил при отваряне на приложението',
			'settings.requireProfileSelectionOnOpenDescription' => 'Показвай избор на профил всеки път при отваряне на приложението',
			'settings.forceTvMode' => 'Принуди TV режим',
			'settings.forceTvModeDescription' => 'Принуди ТВ оформление. За устройства, които не се разпознават автоматично. Изисква рестарт.',
			'settings.startInFullscreen' => 'Стартирай на цял екран',
			'settings.startInFullscreenDescription' => 'Отваряй Plezy в режим цял екран при стартиране',
			'settings.exitFullscreenOnPlayerClose' => 'Изход от цял екран при затваряне на плейъра',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Автоматично излиза от режим цял екран при затваряне на видео плейъра',
			'settings.autoHidePerformanceOverlay' => 'Автоматично скриване на оверлея за производителност',
			'settings.autoHidePerformanceOverlayDescription' => 'Скривай постепенно оверлея за производителност заедно с контролите за възпроизвеждане',
			'settings.showNavBarLabels' => 'Показвай етикети в навигационната лента',
			'settings.showNavBarLabelsDescription' => 'Показвай текстови етикети под иконите в навигационната лента',
			'settings.startupSection' => 'Начален раздел',
			'settings.liveTvDefaultFavorites' => 'По подразбиране към любими канали',
			'settings.liveTvDefaultFavoritesDescription' => 'Показвай само любими канали при отваряне на телевизия на живо',
			'settings.display' => 'Дисплей',
			'settings.homeScreen' => 'Начален екран',
			'settings.navigation' => 'Навигация',
			'settings.window' => 'Прозорец',
			'settings.content' => 'Съдържание',
			'settings.player' => 'Плейър',
			'settings.subtitlesAndConfig' => 'Субтитри и конфигурация',
			'settings.seekAndTiming' => 'Търсене и време',
			'settings.behavior' => 'Поведение',
			'search.hint' => 'Търсене на филми, сериали, музика...',
			'search.tryDifferentTerm' => 'Опитайте с различна дума за търсене',
			'search.searchYourMedia' => 'Търсете във вашата медия',
			'search.enterTitleActorOrKeyword' => 'Въведете заглавие, актьор или ключова дума',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Задай клавишна комбинация за ${actionName}',
			'hotkeys.clearShortcut' => 'Изчисти клавишната комбинация',
			'hotkeys.noShortcutSet' => 'Няма зададена клавишна комбинация',
			'hotkeys.currentShortcut' => 'Текуща комбинация:',
			'hotkeys.pressToRecord' => 'Избери, за да запишеш клавишна комбинация',
			'hotkeys.recordingShortcut' => 'Натисни клавишната комбинация сега',
			'hotkeys.actions.playPause' => 'Пускане/пауза',
			'hotkeys.actions.volumeUp' => 'Увеличи звука',
			'hotkeys.actions.volumeDown' => 'Намали звука',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Превърти напред (${seconds}сек)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Превърти назад (${seconds}сек)',
			'hotkeys.actions.fullscreenToggle' => 'Превключи цял екран',
			'hotkeys.actions.muteToggle' => 'Превключи заглушаване',
			'hotkeys.actions.subtitleToggle' => 'Превключи субтитри',
			'hotkeys.actions.audioTrackNext' => 'Следващ аудио запис',
			'hotkeys.actions.subtitleTrackNext' => 'Следващ субтитърен запис',
			'hotkeys.actions.chapterNext' => 'Следваща глава',
			'hotkeys.actions.chapterPrevious' => 'Предишна глава',
			'hotkeys.actions.episodeNext' => 'Следващ епизод',
			'hotkeys.actions.episodePrevious' => 'Предишен епизод',
			'hotkeys.actions.speedIncrease' => 'Увеличи скоростта',
			'hotkeys.actions.speedDecrease' => 'Намали скоростта',
			'hotkeys.actions.speedReset' => 'Нулирай скоростта',
			'hotkeys.actions.zoomIn' => 'Увеличи мащаба',
			'hotkeys.actions.zoomOut' => 'Намали мащаба',
			'hotkeys.actions.zoomReset' => 'Нулирай мащаба',
			'hotkeys.actions.subSeekNext' => 'Отиди до следващ субтитър',
			'hotkeys.actions.subSeekPrev' => 'Отиди до предишен субтитър',
			'hotkeys.actions.shaderToggle' => 'Превключи шейдъри',
			'hotkeys.actions.skipMarker' => 'Прескочи интро/финални надписи',
			'hotkeys.actions.screenshot' => 'Направи екранна снимка',
			'fileInfo.title' => 'Информация за файла',
			'fileInfo.video' => 'Видео',
			'fileInfo.audio' => 'Аудио',
			'fileInfo.file' => 'Файл',
			'fileInfo.advanced' => 'Разширени',
			'fileInfo.codec' => 'Кодек',
			'fileInfo.resolution' => 'Резолюция',
			'fileInfo.bitrate' => 'Битрейт',
			'fileInfo.frameRate' => 'Кадрова честота',
			'fileInfo.aspectRatio' => 'Съотношение на страните',
			'fileInfo.profile' => 'Профил',
			'fileInfo.bitDepth' => 'Битова дълбочина',
			'fileInfo.colorSpace' => 'Цветово пространство',
			'fileInfo.colorRange' => 'Цветови диапазон',
			'fileInfo.colorPrimaries' => 'Основни цветове',
			'fileInfo.chromaSubsampling' => 'Цветова субдискретизация',
			'fileInfo.channels' => 'Канали',
			'fileInfo.subtitles' => 'Субтитри',
			'fileInfo.overallBitrate' => 'Общ битрейт',
			'fileInfo.path' => 'Път',
			'fileInfo.size' => 'Размер',
			'fileInfo.container' => 'Контейнер',
			'fileInfo.duration' => 'Продължителност',
			'fileInfo.optimizedForStreaming' => 'Оптимизирано за стрийминг',
			'fileInfo.has64bitOffsets' => '64-битови отмествания',
			'mediaMenu.markAsWatched' => 'Маркирай като гледано',
			'mediaMenu.markAsUnwatched' => 'Маркирай като негледано',
			'mediaMenu.removeFromContinueWatching' => 'Премахни от продължаване на гледането',
			'mediaMenu.viewDetails' => 'Виж подробности',
			'mediaMenu.goToSeries' => 'Към сериала',
			'mediaMenu.shufflePlay' => 'Разбъркано възпроизвеждане',
			'mediaMenu.shuffleNotAvailableOffline' => 'Разбърканото възпроизвеждане не е налично офлайн',
			'mediaMenu.fileInfo' => 'Информация за файла',
			'mediaMenu.deleteFromServer' => 'Изтрий от сървъра',
			'mediaMenu.confirmDelete' => 'Да се изтрие ли тази медия и файловете ѝ от вашия сървър?',
			'mediaMenu.deleteMultipleWarning' => 'Това включва всички епизоди и техните файлове.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Медията е изтрита успешно',
			'mediaMenu.mediaFailedToDelete' => 'Неуспешно изтриване на медията',
			'mediaMenu.rate' => 'Оцени',
			'mediaMenu.playFromBeginning' => 'Пусни от началото',
			'mediaMenu.playVersion' => 'Пусни версия...',
			'rateSheet.title' => 'Оцени',
			'rateSheet.server' => 'Сървър',
			'rateSheet.favorite' => 'Добави в любими',
			'rateSheet.favorited' => 'Добавено в любими',
			'rateSheet.saved' => 'Запазено',
			'rateSheet.notAvailable' => 'Няма намерено съвпадение',
			'rateSheet.noConnectedServices' => 'Свържи услуга в Настройки, за да оценяваш там.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, филм',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, ТВ сериал',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'гледано',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} процента изгледано',
			'accessibility.mediaCardUnwatched' => 'негледано',
			'accessibility.tapToPlay' => 'Докоснете за възпроизвеждане',
			'accessibility.decrease' => 'Намали',
			'accessibility.increase' => 'Увеличи',
			'accessibility.decreaseValue' => ({required Object label}) => 'Намали ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Увеличи ${label}',
			'accessibility.hue' => 'Нюанс',
			'accessibility.saturation' => 'Наситеност',
			'accessibility.brightness' => 'Яркост',
			'accessibility.hexColor' => 'Шестнадесетичен цвят',
			'accessibility.expandText' => 'Разгъни текста',
			'accessibility.collapseText' => 'Свий текста',
			'tooltips.shufflePlay' => 'Разбъркано възпроизвеждане',
			'tooltips.playTrailer' => 'Пусни трейлър',
			'tooltips.markAsWatched' => 'Маркирай като гледано',
			'tooltips.markAsUnwatched' => 'Маркирай като негледано',
			'videoControls.audioLabel' => 'Аудио',
			'videoControls.subtitlesLabel' => 'Субтитри',
			'videoControls.resetToZero' => 'Нулирай до 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} се възпроизвежда по-късно',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} се възпроизвежда по-рано',
			'videoControls.noOffset' => 'Без отместване',
			'videoControls.letterbox' => 'Черни ленти',
			'videoControls.fillScreen' => 'Запълни екрана',
			'videoControls.stretch' => 'Разтегни',
			'videoControls.lockRotation' => 'Заключи ротацията',
			'videoControls.unlockRotation' => 'Отключи ротацията',
			'videoControls.timerActive' => 'Таймерът е активен',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Възпроизвеждането ще спре след ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Край на текущото видео',
			'videoControls.sleepTimerStopAtHeader' => 'Спиране при',
			'videoControls.sleepTimerDurationHeader' => 'Таймер',
			'videoControls.playbackWillPauseAtEnd' => 'Възпроизвеждането ще спре в края на това видео',
			'videoControls.stillWatching' => 'Още ли гледате?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Пауза след ${seconds}сек',
			'videoControls.continueWatching' => 'Продължи',
			'videoControls.autoPlayNext' => 'Автоматично пусни следващото',
			'videoControls.playNext' => 'Пусни следващото',
			'videoControls.playButton' => 'Пусни',
			'videoControls.pauseButton' => 'Пауза',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Превърти назад ${seconds} секунди',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Превърти напред ${seconds} секунди',
			'videoControls.previousButton' => 'Предишен епизод',
			'videoControls.nextButton' => 'Следващ епизод',
			'videoControls.previousChapterButton' => 'Предишна глава',
			'videoControls.nextChapterButton' => 'Следваща глава',
			'videoControls.muteButton' => 'Заглуши',
			'videoControls.unmuteButton' => 'Включи звука',
			'videoControls.settingsButton' => 'Настройки на възпроизвеждането',
			'videoControls.tracksButton' => 'Аудио и субтитри',
			'videoControls.chaptersButton' => 'Глави',
			'videoControls.versionQualityButton' => 'Версия и качество',
			'videoControls.versionColumnHeader' => 'Версия',
			'videoControls.qualityColumnHeader' => 'Качество',
			'videoControls.qualityOriginal' => 'Оригинал',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Транскодирането не е налично — пуска се оригиналното качество',
			'videoControls.pipButton' => 'Режим картина в картината',
			'videoControls.aspectRatioButton' => 'Съотношение на страните',
			'videoControls.ambientLighting' => 'Амбиентно осветление',
			'videoControls.fullscreenButton' => 'Влез на цял екран',
			'videoControls.exitFullscreenButton' => 'Излез от цял екран',
			'videoControls.alwaysOnTopButton' => 'Винаги отгоре',
			'videoControls.rotationLockButton' => 'Заключване на ротацията',
			'videoControls.lockScreen' => 'Заключи екрана',
			'videoControls.screenLockButton' => 'Заключване на екрана',
			'videoControls.longPressToUnlock' => 'Задръжте продължително за отключване',
			'videoControls.timelineSlider' => 'Видео времева линия',
			'videoControls.volumeSlider' => 'Ниво на звука',
			'videoControls.endsAt' => ({required Object time}) => 'Свършва в ${time}',
			'videoControls.pipActive' => 'Възпроизвеждане в режим картина в картината',
			'videoControls.pipFailed' => 'Режимът картина в картината не успя да стартира',
			'videoControls.screenshotSaved' => 'Екранната снимка е запазена',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Мащаб ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Изисква Android 8.0 или по-нова версия',
			'videoControls.pipErrors.iosVersion' => 'Изисква iOS 15.0 или по-нова версия',
			'videoControls.pipErrors.permissionDisabled' => 'Режимът картина в картината е изключен. Включете го в системните настройки.',
			'videoControls.pipErrors.notSupported' => 'Устройството не поддържа режим картина в картината',
			'videoControls.pipErrors.voSwitchFailed' => 'Неуспешна смяна на видео изхода за режим картина в картината',
			'videoControls.pipErrors.failed' => 'Режимът картина в картината не успя да стартира',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Възникна грешка: ${error}',
			'videoControls.chapters' => 'Глави',
			'videoControls.noChaptersAvailable' => 'Няма налични глави',
			'videoControls.queue' => 'Опашка',
			'videoControls.noQueueItems' => 'Няма елементи в опашката',
			'videoControls.searchSubtitles' => 'Търсене на субтитри',
			'videoControls.language' => 'Език',
			'videoControls.noSubtitlesFound' => 'Не са намерени субтитри',
			'videoControls.downloadedSubtitle' => 'Изтеглени субтитри',
			'videoControls.noSubtitlesAvailable' => 'Няма налични субтитри',
			'videoControls.noAudioTracksAvailable' => 'Няма налични аудио писти',
			'videoControls.noTracksAvailable' => 'Няма налични писти',
			'videoControls.subtitleDownloaded' => 'Субтитърът е изтеглен',
			'videoControls.subtitleDownloadFailed' => 'Неуспешно изтегляне на субтитър',
			'videoControls.searchLanguages' => 'Търсене на езици...',
			'messages.markedAsWatched' => 'Маркирано като гледано',
			'messages.markedAsUnwatched' => 'Маркирано като негледано',
			'messages.markedAsWatchedOffline' => 'Маркирано като гледано (ще се синхронизира, когато сте онлайн)',
			'messages.markedAsUnwatchedOffline' => 'Маркирано като негледано (ще се синхронизира, когато сте онлайн)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Автоматично премахнато: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bg'))(n, one: 'Автоматично премахнато ${n} гледано изтегляне', other: 'Автоматично премахнати ${n} гледани изтегляния', ), 
			'messages.removedFromContinueWatching' => 'Премахнато от продължаване на гледането',
			'messages.errorLoading' => ({required Object error}) => 'Грешка: ${error}',
			'messages.streamInterrupted' => 'Потокът прекъсна. Натиснете „Пусни“ или превъртете, за да опитате отново.',
			'messages.liveStreamInterrupted' => 'Потокът на живо прекъсна. Натиснете „Пусни“, за да опитате отново.',
			'messages.fileInfoNotAvailable' => 'Информацията за файла не е налична',
			_ => null,
		} ?? switch (path) {
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Грешка при зареждане на информация за файла: ${error}',
			'messages.errorLoadingSeries' => 'Грешка при зареждане на сериала',
			'messages.musicNotSupported' => 'Възпроизвеждането на музика все още не се поддържа',
			'messages.noDescriptionAvailable' => 'Няма налично описание',
			'messages.noProfilesAvailable' => 'Няма налични профили',
			'messages.contactAdminForProfiles' => 'Свържете се с администратора на сървъра, за да добави профили',
			'messages.unableToDetermineLibrarySection' => 'Не може да се определи секцията на библиотеката за този елемент',
			'messages.logsCleared' => 'Логовете са изчистени',
			'messages.logsCopied' => 'Логовете са копирани в клипборда',
			'messages.noLogsAvailable' => 'Няма налични логове',
			'messages.libraryScanning' => ({required Object title}) => 'Сканиране на "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Сканирането на библиотеката е стартирано за "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Неуспешно сканиране на библиотеката: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Опресняване на метаданни за "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Опресняването на метаданни е стартирано за "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Неуспешно опресняване на метаданни: ${error}',
			'messages.logoutConfirm' => 'Сигурни ли сте, че искате да излезете?',
			'messages.noSeasonsFound' => 'Не са намерени сезони',
			'messages.seasonsLoadFailed' => 'Неуспешно зареждане на сезони',
			'messages.noEpisodesFound' => 'Не са намерени епизоди в първия сезон',
			'messages.noEpisodesFoundGeneral' => 'Не са намерени епизоди',
			'messages.episodesLoadFailed' => 'Неуспешно зареждане на епизоди',
			'messages.noResultsFound' => 'Няма намерени резултати',
			'messages.sleepTimerSet' => ({required Object label}) => 'Таймерът за заспиване е зададен за ${label}',
			'messages.noItemsAvailable' => 'Няма налични елементи',
			'messages.failedToCreatePlayQueueNoItems' => 'Неуспешно създаване на опашка за възпроизвеждане - няма елементи',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Неуспешно ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Превключване към съвместим плейър...',
			'messages.serverLimitTitle' => 'Възпроизвеждането е неуспешно',
			'messages.serverLimitBody' => 'Грешка на сървъра (HTTP 500). Вероятно лимит за пропускателна способност/транскодиране е отхвърлил тази сесия. Помолете собственика да го коригира.',
			'messages.logsUploaded' => 'Логовете са качени',
			'messages.logsUploadFailed' => 'Неуспешно качване на логовете',
			'messages.logId' => 'ID на лога',
			'subtitlingStyling.text' => 'Текст',
			'subtitlingStyling.border' => 'Рамка',
			'subtitlingStyling.background' => 'Фон',
			'subtitlingStyling.fontSize' => 'Размер на шрифта',
			'subtitlingStyling.textColor' => 'Цвят на текста',
			'subtitlingStyling.borderSize' => 'Размер на рамката',
			'subtitlingStyling.borderColor' => 'Цвят на рамката',
			'subtitlingStyling.backgroundOpacity' => 'Прозрачност на фона',
			'subtitlingStyling.backgroundColor' => 'Цвят на фона',
			'subtitlingStyling.position' => 'Позиция',
			'subtitlingStyling.assOverride' => 'ASS презаписване',
			'subtitlingStyling.overrideScale' => 'Мащабиране',
			'subtitlingStyling.overrideForce' => 'Принудително',
			'subtitlingStyling.overrideStrip' => 'Премахване на стиловете',
			'subtitlingStyling.positionTop' => 'Горе',
			'subtitlingStyling.positionBottom' => 'Долу',
			'subtitlingStyling.bold' => 'Получер',
			'subtitlingStyling.italic' => 'Курсив',
			'subtitlingStyling.renderResolution' => 'Резолюция на изобразяване',
			'subtitlingStyling.renderResolutionScreen' => 'Резолюция на екрана',
			'subtitlingStyling.renderResolutionVideo' => 'Резолюция на видеото',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Разширени настройки на видео плейъра',
			'mpvConfig.presets' => 'Пресети',
			'mpvConfig.noPresets' => 'Няма запазени пресети',
			'mpvConfig.saveAsPreset' => 'Запази като пресет...',
			'mpvConfig.presetName' => 'Име на пресет',
			'mpvConfig.presetNameHint' => 'Въведете име за този пресет',
			'mpvConfig.loadPreset' => 'Зареди',
			'mpvConfig.deletePreset' => 'Изтрий',
			'mpvConfig.presetSaved' => 'Пресетът е запазен',
			'mpvConfig.presetLoaded' => 'Пресетът е зареден',
			'mpvConfig.presetDeleted' => 'Пресетът е изтрит',
			'mpvConfig.confirmDeletePreset' => 'Сигурни ли сте, че искате да изтриете този пресет?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Потвърждение на действие',
			'profiles.addPlezyProfile' => 'Добави Plezy профил',
			'profiles.switchingProfile' => 'Смяна на профил…',
			'profiles.deleteThisProfileTitle' => 'Да се изтрие ли този профил?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Премахване на ${displayName}. Връзките не се засягат.',
			'profiles.active' => 'Активен',
			'profiles.manage' => 'Управление',
			'profiles.delete' => 'Изтрий',
			'profiles.signOut' => 'Изход',
			'profiles.signOutPlexTitle' => 'Изход от Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Премахване на ${displayName} и всички Plex Home потребители? Можете да влезете отново по всяко време.',
			'profiles.signedOutPlex' => 'Излязохте от Plex.',
			'profiles.signOutFailed' => 'Изходът е неуспешен.',
			'profiles.sectionTitle' => 'Профили',
			'profiles.summarySingle' => 'Добавете профили, за да комбинирате управлявани потребители и локални идентичности',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} профила · активен: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} профила',
			'profiles.removeConnectionTitle' => 'Да се премахне ли връзката?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Премахване на достъпа на ${displayName} до ${connectionLabel}. Другите профили го запазват.',
			'profiles.deleteProfileTitle' => 'Да се изтрие ли профилът?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Премахване на ${displayName} и неговите връзки. Сървърите остават налични.',
			'profiles.profileNameLabel' => 'Име на профила',
			'profiles.pinProtectionLabel' => 'PIN защита',
			'profiles.pinManagedByPlex' => 'PIN-ът се управлява от Plex. Редактирайте го в plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Няма зададен PIN. За да изисквате PIN, редактирайте домашния потребител в plex.tv.',
			'profiles.setPin' => 'Задай PIN',
			'profiles.setPinTitle' => 'Задай PIN',
			'profiles.confirmPinTitle' => 'Потвърди PIN',
			'profiles.pinSet' => 'PIN-ът е зададен',
			'profiles.changePin' => 'Промени',
			'profiles.removePin' => 'Премахни',
			'profiles.connectionsLabel' => 'Връзки',
			'profiles.add' => 'Добави',
			'profiles.deleteProfileButton' => 'Изтрий профил',
			'profiles.noConnectionsHint' => 'Няма връзки — добавете такава, за да използвате този профил.',
			'profiles.noConnections' => 'Няма връзки',
			'profiles.plexHomeAccount' => 'Plex Home акаунт',
			'profiles.connectionDefault' => 'По подразбиране',
			'profiles.connectionAs' => ({required Object displayName}) => 'като ${displayName}',
			'profiles.makeDefault' => 'Направи по подразбиране',
			'profiles.removeConnection' => 'Премахни',
			'profiles.profileRenamed' => 'Профилът е преименуван.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Добави към ${displayName}',
			'profiles.borrowExplain' => 'Използвай връзка от друг профил. PIN-защитените профили изискват PIN.',
			'profiles.borrowEmpty' => 'Все още няма какво да се използва.',
			'profiles.borrowEmptySubtitle' => 'Първо свържете Plex или Jellyfin към друг профил.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'От ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Връзката е използвана.',
			'profiles.borrowFailed' => 'Неуспешно използване на връзка.',
			'profiles.incorrectPin' => 'Неправилен PIN.',
			'profiles.incorrectPinTryAgain' => 'Неправилен PIN. Опитайте отново.',
			'profiles.sourceProfileMissingParentAccount' => 'Изходният профил няма родителски акаунт.',
			'profiles.failedToLoadHomeUsers' => 'Потребителите на Plex Home не можаха да бъдат заредени. Проверете връзката си и опитайте отново.',
			'profiles.failedToVerifyPin' => 'Неуспешна проверка на PIN.',
			'profiles.newProfile' => 'Нов профил',
			'profiles.profileNameHint' => 'напр. Гости, Деца, Семейна стая',
			'profiles.pinProtectionOptional' => 'PIN защита (по желание)',
			'profiles.pinExplain' => 'Изисква се 4-цифрен PIN за смяна на профили.',
			'profiles.continueButton' => 'Продължи',
			'profiles.pinsDontMatch' => 'PIN кодовете не съвпадат',
			'connections.sectionTitle' => 'Връзки',
			'connections.addConnection' => 'Добави връзка',
			'connections.addConnectionSubtitleNoProfile' => 'Влезте с Plex или свържете Jellyfin сървър',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Добави към ${displayName}: Plex, Jellyfin или връзка от друг профил',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Сесията за ${name} е изтекла',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Сесиите за ${count} сървъра са изтекли',
			'connections.signInAgain' => 'Влез отново',
			'connections.editJellyfinTitle' => 'Редактиране на Jellyfin връзка',
			'connections.editJellyfinIntro' => ({required Object serverName}) => 'Добавете или премахнете URL адреси за ${serverName}. Plezy ще използва достъпния URL адрес с най-ниска латентност.',
			'discover.title' => 'Открий',
			'discover.noContentAvailable' => 'Няма налично съдържание',
			'discover.addMediaToLibraries' => 'Добавете медия към библиотеките си',
			'discover.continueWatching' => 'Продължи гледането',
			'discover.continueWatchingIn' => ({required Object library}) => 'Продължи гледането в ${library}',
			'discover.nextUp' => 'Следва',
			'discover.nextUpIn' => ({required Object library}) => 'Следва в ${library}',
			'discover.recentlyAdded' => 'Наскоро добавени',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Наскоро добавени в ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Последни албуми в ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Наскоро възпроизведени в ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Най-възпроизвеждани в ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Обзор',
			'discover.cast' => 'Актьори',
			'discover.extras' => 'Трейлъри и екстри',
			'discover.studio' => 'Студио',
			'discover.rating' => 'Рейтинг',
			'discover.movie' => 'Филм',
			'discover.tvShow' => 'ТВ сериал',
			'discover.minutesLeft' => ({required Object minutes}) => 'Остават ${minutes} мин',
			'discover.moreLikeThis' => 'Подобно на това',
			'errors.searchFailed' => ({required Object error}) => 'Търсенето е неуспешно: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Изтече времето за връзка при зареждане на ${context}',
			'errors.connectionFailed' => 'Не може да се осъществи връзка с медиен сървър',
			'errors.unableToLoad' => ({required Object context}) => 'Не може да се зареди ${context}. Опитайте отново.',
			'errors.noClientAvailable' => 'Няма наличен клиент',
			'errors.pleaseEnterToken' => 'Моля, въведете токен',
			'errors.invalidToken' => 'Невалиден токен',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Неуспешна проверка на токена: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Неуспешна смяна към ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Неуспешно изтриване на ${displayName}',
			'errors.failedToRate' => 'Оценката не можа да бъде обновена',
			'libraries.title' => 'Библиотеки',
			'libraries.fallbackTitle' => 'Библиотека',
			'libraries.scanLibraryFiles' => 'Сканирай файловете на библиотеката',
			'libraries.scanLibrary' => 'Сканирай библиотеката',
			'libraries.analyze' => 'Анализирай',
			'libraries.analyzeLibrary' => 'Анализирай библиотеката',
			'libraries.refreshMetadata' => 'Опресни метаданни',
			'libraries.emptyTrash' => 'Изпразни кошчето',
			'libraries.emptyingTrash' => ({required Object title}) => 'Изпразване на кошчето за "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Кошчето е изпразнено за "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Неуспешно изпразване на кошчето: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Анализиране на "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Анализът е стартиран за "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Неуспешен анализ на библиотеката: ${error}',
			'libraries.noLibrariesFound' => 'Не са намерени библиотеки',
			'libraries.allLibrariesHidden' => 'Всички библиотеки са скрити',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Скрити библиотеки (${count})',
			'libraries.thisLibraryIsEmpty' => 'Тази библиотека е празна',
			'libraries.noItemsMatchFilters' => 'Няма елементи, съответстващи на активните филтри',
			'libraries.resetFilters' => 'Нулирай филтрите',
			'libraries.all' => 'Всички',
			'libraries.clearAll' => 'Изчисти всички',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Сигурни ли сте, че искате да сканирате "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Сигурни ли сте, че искате да анализирате "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Сигурни ли сте, че искате да опресните метаданните за "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Сигурни ли сте, че искате да изпразните кошчето за "${title}"?',
			'libraries.manageLibraries' => 'Управление на библиотеки',
			'libraries.sort' => 'Сортиране',
			'libraries.sortBy' => 'Сортирай по',
			'libraries.filters' => 'Филтри',
			'libraries.confirmActionMessage' => 'Сигурни ли сте, че искате да извършите това действие?',
			'libraries.showLibrary' => 'Покажи библиотеката',
			'libraries.hideLibrary' => 'Скрий библиотеката',
			'libraries.libraryOptions' => 'Опции на библиотеката',
			'libraries.content' => 'съдържание на библиотеката',
			'libraries.selectLibrary' => 'Избери библиотека',
			'libraries.filtersWithCount' => ({required Object count}) => 'Филтри (${count})',
			'libraries.noRecommendations' => 'Няма налични препоръки',
			'libraries.noCollections' => 'Няма колекции в тази библиотека',
			'libraries.noFoldersFound' => 'Не са намерени папки',
			'libraries.folders' => 'папки',
			'libraries.tabs.recommended' => 'Препоръчани',
			'libraries.tabs.browse' => 'Преглед',
			'libraries.tabs.collections' => 'Колекции',
			'libraries.tabs.playlists' => 'Плейлисти',
			'libraries.groupings.title' => 'Групиране',
			'libraries.groupings.all' => 'Всички',
			'libraries.groupings.movies' => 'Филми',
			'libraries.groupings.shows' => 'ТВ сериали',
			'libraries.groupings.seasons' => 'Сезони',
			'libraries.groupings.episodes' => 'Епизоди',
			'libraries.groupings.artists' => 'Изпълнители',
			'libraries.groupings.albums' => 'Албуми',
			'libraries.groupings.tracks' => 'Песни',
			'libraries.groupings.folders' => 'Папки',
			'libraries.filterCategories.genre' => 'Жанр',
			'libraries.filterCategories.year' => 'Година',
			'libraries.filterCategories.contentRating' => 'Възрастов рейтинг',
			'libraries.filterCategories.tag' => 'Таг',
			'libraries.filterCategories.unwatched' => 'Негледани',
			'libraries.filterCategories.unplayed' => 'Непускани',
			'libraries.filterCategories.favorites' => 'Любими',
			'libraries.sortLabels.title' => 'Заглавие',
			'libraries.sortLabels.dateAdded' => 'Дата на добавяне',
			'libraries.sortLabels.releaseDate' => 'Дата на излизане',
			'libraries.sortLabels.rating' => 'Рейтинг',
			'libraries.sortLabels.communityRating' => 'Оценка от общността',
			'libraries.sortLabels.criticRating' => 'Оценка от критиците',
			'libraries.sortLabels.userRating' => 'Потребителска оценка',
			'libraries.sortLabels.datePlayed' => 'Дата на възпроизвеждане',
			'libraries.sortLabels.playCount' => 'Брой възпроизвеждания',
			'libraries.sortLabels.productionYear' => 'Година на производство',
			'libraries.sortLabels.runtime' => 'Продължителност',
			'libraries.sortLabels.officialRating' => 'Официален рейтинг',
			'libraries.sortLabels.premiereDate' => 'Дата на премиера',
			'libraries.sortLabels.startDate' => 'Начална дата',
			'libraries.sortLabels.airTime' => 'Час на излъчване',
			'libraries.sortLabels.studio' => 'Студио',
			'libraries.sortLabels.random' => 'Случайно',
			'libraries.sortLabels.dateShared' => 'Дата на споделяне',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Дата на излъчване на последния епизод',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Дата на добавяне на последния епизод',
			'about.title' => 'Относно',
			'about.openSourceLicenses' => 'Лицензи с отворен код',
			'about.versionLabel' => ({required Object version}) => 'Версия ${version}',
			'about.appDescription' => 'Красив Plex и Jellyfin клиент за Flutter',
			'about.viewLicensesDescription' => 'Виж лицензите на библиотеки на трети страни',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Не са намерени сървъри за ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Неуспешно зареждане на сървъри: ${error}',
			'hubDetail.title' => 'Заглавие',
			'hubDetail.releaseYear' => 'Година на излизане',
			'hubDetail.dateAdded' => 'Дата на добавяне',
			'hubDetail.rating' => 'Рейтинг',
			'hubDetail.noItemsFound' => 'Няма намерени елементи',
			'logs.clearLogs' => 'Изчисти логовете',
			'logs.copyLogs' => 'Копирай логовете',
			'logs.uploadLogs' => 'Качи логовете',
			'licenses.relatedPackages' => 'Свързани пакети',
			'licenses.license' => 'Лиценз',
			'licenses.licenseNumber' => ({required Object number}) => 'Лиценз ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} лиценза',
			'navigation.libraries' => 'Библиотеки',
			'navigation.downloads' => 'Изтегляния',
			'navigation.liveTv' => 'Телевизия на живо',
			'navigation.explore' => 'Разгледай',
			'explore.title' => 'Разгледай',
			'explore.selectSource' => 'Избери източник',
			'explore.rows.watchlist' => 'Списък за гледане',
			'explore.rows.recommendedMovies' => 'Препоръчани филми',
			'explore.rows.recommendedShows' => 'Препоръчани сериали',
			'explore.rows.trendingMovies' => 'Актуални филми',
			'explore.rows.trendingShows' => 'Актуални сериали',
			'explore.rows.popularMovies' => 'Популярни филми',
			'explore.rows.popularShows' => 'Популярни сериали',
			'explore.rows.suggestedAnime' => 'Препоръчани аниме',
			'explore.rows.airingAnime' => 'Топ излъчвани аниме',
			'explore.rows.popularAnime' => 'Най-популярни аниме',
			'explore.rows.trending' => 'Актуални',
			'explore.rows.upcomingMovies' => 'Предстоящи филми',
			'explore.rows.upcomingShows' => 'Предстоящи сериали',
			'explore.status.airing' => 'Излъчва се',
			'explore.status.ended' => 'Приключил',
			'explore.status.canceled' => 'Отменен',
			'explore.status.upcoming' => 'Предстоящ',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bg'))(n, one: '${n} епизод', other: '${n} епизода', ), 
			'explore.cast' => 'Актьори',
			'explore.characters' => 'Герои',
			'explore.addToWatchlist' => 'Добави в списъка за гледане',
			'explore.removeFromWatchlist' => 'Премахни от списъка за гледане',
			'explore.watchlistUpdateFailed' => 'Неуспешно обновяване на списъка за гледане',
			'explore.notInLibrary' => 'Не е в твоята библиотека',
			'explore.inTheseLibraries' => 'В тези библиотеки',
			'explore.checkingLibrary' => 'Проверка на твоята библиотека...',
			'explore.emptyTitle' => 'Тук все още няма нищо',
			'explore.emptyMessage' => ({required Object source}) => 'Редовете от ${source} ще се появят тук, когато има съдържание.',
			'explore.searchHint' => ({required Object source}) => 'Търсене в ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Няма резултати за "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Търси филми и сериали в ${source}.',
			'explore.searchFailed' => 'Търсенето се провали. Провери връзката си и опитай отново.',
			'liveTv.title' => 'Телевизия на живо',
			'liveTv.guide' => 'ТВ програма',
			'liveTv.noChannels' => 'Няма налични канали',
			'liveTv.noDvr' => 'Няма конфигуриран DVR на нито един сървър',
			'liveTv.serverUnavailable' => 'Сървърът за телевизия на живо не е наличен.',
			'liveTv.serverNotConnected' => 'Сървърът за телевизия на живо не е свързан.',
			'liveTv.noPrograms' => 'Няма налични програмни данни',
			'liveTv.liveStreamFailed' => 'Потокът на живо се провали',
			'liveTv.unknownProgram' => 'Неизвестна програма',
			'liveTv.unknownHub' => 'Неизвестно',
			'liveTv.unknownError' => 'Неизвестна грешка',
			'liveTv.channelNumber' => ({required Object number}) => 'Канал ${number}',
			'liveTv.unknownChannel' => 'Неизвестен канал',
			'liveTv.live' => 'НА ЖИВО',
			'liveTv.reloadGuide' => 'Презареди ТВ програмата',
			'liveTv.now' => 'Сега',
			'liveTv.today' => 'Днес',
			'liveTv.tomorrow' => 'Утре',
			'liveTv.midnight' => 'Полунощ',
			'liveTv.overnight' => 'През нощта',
			'liveTv.morning' => 'Сутрин',
			'liveTv.daytime' => 'През деня',
			'liveTv.evening' => 'Вечер',
			'liveTv.lateNight' => 'Късно вечер',
			'liveTv.whatsOn' => 'Какво дават',
			'liveTv.watchChannel' => 'Гледай канал',
			'liveTv.favorites' => 'Любими',
			'liveTv.reorderFavorites' => 'Пренареди любимите',
			'liveTv.favoritesLoadFailed' => 'Любимите не можаха да се заредят. Проверете връзката си и опитайте отново.',
			'liveTv.joinSession' => 'Присъедини се към текуща сесия',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Гледай от началото (преди ${minutes} мин)',
			'liveTv.watchLive' => 'Гледай на живо',
			'liveTv.goToLive' => 'Към живото предаване',
			'liveTv.record' => 'Запис',
			'liveTv.recordEpisode' => 'Запиши епизод',
			'liveTv.recordSeries' => 'Запиши сериал',
			'liveTv.recordOptions' => 'Опции за запис',
			'liveTv.saveTo' => 'Запази в',
			'liveTv.recordings' => 'Записи',
			'liveTv.scheduledRecordings' => 'Планирани',
			'liveTv.recordingRules' => 'Правила за запис',
			'liveTv.noScheduledRecordings' => 'Няма планирани записи',
			'liveTv.manageRecording' => 'Управление на запис',
			'liveTv.cancelRecording' => 'Отмени запис',
			'liveTv.cancelRecordingTitle' => 'Да се отмени ли този запис?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} вече няма да се записва.',
			'liveTv.deleteRule' => 'Изтрий правило',
			'liveTv.deleteRuleTitle' => 'Да се изтрие ли правилото за запис?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Бъдещи епизоди на ${title} няма да се записват.',
			'liveTv.recordingScheduled' => 'Записът е планиран',
			'liveTv.alreadyScheduled' => 'Тази програма вече е планирана',
			'liveTv.dvrAdminRequired' => 'DVR настройките изискват администраторски акаунт',
			'liveTv.recordingFailed' => 'Записът не можа да бъде планиран',
			'liveTv.recordingTargetMissing' => 'Не може да се определи библиотеката за запис',
			'liveTv.recordNotAvailable' => 'Записът не е наличен за тази програма',
			'liveTv.recordingCancelled' => 'Записът е отменен',
			'liveTv.recordingRuleDeleted' => 'Правилото за запис е изтрито',
			'liveTv.processRecordingRules' => 'Преоцени правилата',
			'liveTv.recordingInProgress' => 'Записва се сега',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} планирани',
			'liveTv.editRule' => 'Редактирай правило',
			'liveTv.editRuleAction' => 'Редактирай',
			'liveTv.recordingRuleUpdated' => 'Правилото за запис е обновено',
			'liveTv.guideReloadRequested' => 'Заявено е опресняване на ТВ програмата',
			'liveTv.rulesProcessRequested' => 'Заявена е преоценка на правилата',
			'liveTv.recordShow' => 'Запиши предаването',
			'collections.title' => 'Колекции',
			'collections.collection' => 'Колекция',
			'collections.empty' => 'Колекцията е празна',
			'collections.deleteCollection' => 'Изтрий колекция',
			'collections.deleteConfirm' => ({required Object title}) => 'Да се изтрие ли "${title}"? Това не може да бъде отменено.',
			'collections.deleted' => 'Колекцията е изтрита',
			'collections.deleteFailed' => 'Неуспешно изтриване на колекция',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Неуспешно изтриване на колекция: ${error}',
			'collections.selectCollection' => 'Избери колекция',
			'collections.collectionName' => 'Име на колекция',
			'collections.enterCollectionName' => 'Въведете име на колекция',
			'collections.addedToCollection' => 'Добавено към колекция',
			'collections.errorAddingToCollection' => 'Неуспешно добавяне към колекция',
			'collections.created' => 'Колекцията е създадена',
			'collections.removeFromCollection' => 'Премахни от колекция',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Да се премахне ли "${title}" от тази колекция?',
			'collections.removedFromCollection' => 'Премахнато от колекция',
			'collections.removeFromCollectionFailed' => 'Неуспешно премахване от колекция',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Грешка при премахване от колекция: ${error}',
			'collections.searchCollections' => 'Търсене на колекции...',
			'playlists.title' => 'Плейлисти',
			'playlists.playlist' => 'Плейлист',
			'playlists.noPlaylists' => 'Не са намерени плейлисти',
			'playlists.create' => 'Създай плейлист',
			'playlists.playlistName' => 'Име на плейлист',
			'playlists.enterPlaylistName' => 'Въведете име на плейлист',
			'playlists.delete' => 'Изтрий плейлист',
			'playlists.removeItem' => 'Премахни от плейлист',
			'playlists.smartPlaylist' => 'Умен плейлист',
			'playlists.itemCount' => ({required Object count}) => '${count} елемента',
			'playlists.oneItem' => '1 елемент',
			'playlists.emptyPlaylist' => 'Този плейлист е празен',
			'playlists.deleteConfirm' => 'Да се изтрие ли плейлистът?',
			'playlists.deleteMessage' => ({required Object name}) => 'Сигурни ли сте, че искате да изтриете "${name}"?',
			'playlists.created' => 'Плейлистът е създаден',
			'playlists.deleted' => 'Плейлистът е изтрит',
			'playlists.itemAdded' => 'Добавено към плейлист',
			'playlists.itemRemoved' => 'Премахнато от плейлист',
			'playlists.selectPlaylist' => 'Избери плейлист',
			'playlists.searchPlaylists' => 'Търсене в плейлисти...',
			'playlists.errorCreating' => 'Неуспешно създаване на плейлист',
			'playlists.errorDeleting' => 'Неуспешно изтриване на плейлист',
			'playlists.errorLoading' => 'Неуспешно зареждане на плейлисти',
			'playlists.errorAdding' => 'Неуспешно добавяне към плейлист',
			'playlists.errorReordering' => 'Неуспешно пренареждане на елемент в плейлиста',
			'playlists.errorRemoving' => 'Неуспешно премахване от плейлист',
			'music.goToAlbum' => 'Към албума',
			'music.goToArtist' => 'Към изпълнителя',
			'music.instantMix' => 'Мигновен микс',
			'music.playNext' => 'Пусни следващото',
			'music.addToQueue' => 'Добави към опашката',
			'music.discNumber' => ({required Object n}) => 'Диск ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('bg'))(n, one: '${n} песен', other: '${n} песни', ), 
			'music.nowPlaying' => 'Сега се възпроизвежда',
			'music.playingFrom' => ({required Object title}) => 'Възпроизвеждане от ${title}',
			'music.queue' => 'Опашка',
			'music.clearQueue' => 'Изчисти опашката',
			'music.lyrics' => 'Текст',
			'music.noLyrics' => 'Няма наличен текст',
			'music.sleepTimer' => 'Таймер за заспиване',
			'music.sleepTimerEndOfTrack' => 'Край на песента',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} минути',
			'music.stopPlayback' => 'Спри възпроизвеждането',
			'music.previousTrack' => 'Предишна песен',
			'music.nextTrack' => 'Следваща песен',
			'music.repeat' => 'Повтори',
			'music.repeatAll' => 'Повтори всички',
			'music.repeatOne' => 'Повтори една',
			'watchTogether.title' => 'Гледане заедно',
			'watchTogether.description' => 'Гледайте съдържание синхронизирано с приятели и семейство',
			'watchTogether.createSession' => 'Създай сесия',
			'watchTogether.creating' => 'Създаване...',
			'watchTogether.joinSession' => 'Присъедини се към сесия',
			'watchTogether.joining' => 'Присъединяване...',
			'watchTogether.controlMode' => 'Режим на управление',
			'watchTogether.controlModeQuestion' => 'Кой може да управлява възпроизвеждането?',
			'watchTogether.hostOnly' => 'Само домакинът',
			'watchTogether.anyone' => 'Всеки',
			'watchTogether.hostingSession' => 'Сесия с домакин',
			'watchTogether.inSession' => 'В сесия',
			'watchTogether.sessionCode' => 'Код на сесията',
			'watchTogether.openSessionControls' => 'Отвори контролите за сесията „Гледане заедно“',
			'watchTogether.copySessionCode' => 'Копирай кода на сесията',
			'watchTogether.hostControlsPlayback' => 'Домакинът управлява възпроизвеждането',
			'watchTogether.anyoneCanControl' => 'Всеки може да управлява възпроизвеждането',
			'watchTogether.hostControls' => 'Контроли на домакина',
			'watchTogether.anyoneControls' => 'Всеки управлява',
			'watchTogether.participants' => 'Участници',
			'watchTogether.host' => 'Домакин',
			'watchTogether.hostBadge' => 'ДОМАКИН',
			'watchTogether.youAreHost' => 'Вие сте домакин',
			'watchTogether.watchingWithOthers' => 'Гледате с други',
			'watchTogether.endSession' => 'Край на сесията',
			'watchTogether.leaveSession' => 'Напусни сесията',
			'watchTogether.endSessionQuestion' => 'Край на сесията?',
			'watchTogether.leaveSessionQuestion' => 'Напускане на сесията?',
			'watchTogether.endSessionConfirm' => 'Това ще прекрати сесията за всички участници.',
			'watchTogether.leaveSessionConfirm' => 'Ще бъдете премахнати от сесията.',
			'watchTogether.endSessionConfirmOverlay' => 'Това ще прекрати сесията за гледане за всички участници.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Ще бъдете изключени от сесията за гледане.',
			'watchTogether.end' => 'Край',
			'watchTogether.leave' => 'Напусни',
			'watchTogether.syncing' => 'Синхронизиране...',
			'watchTogether.joinWatchSession' => 'Присъедини се към сесия за гледане',
			'watchTogether.enterCodeHint' => 'Въведете 5-символен код',
			'watchTogether.pasteFromClipboard' => 'Постави от клипборда',
			'watchTogether.pleaseEnterCode' => 'Моля, въведете код на сесия',
			'watchTogether.codeMustBe5Chars' => 'Кодът на сесията трябва да е 5 символа',
			'watchTogether.joinInstructions' => 'Въведете кода на сесията от домакина, за да се присъедините.',
			'watchTogether.failedToCreate' => 'Неуспешно създаване на сесия',
			'watchTogether.failedToJoin' => 'Неуспешно присъединяване към сесия',
			'watchTogether.sessionCodeCopied' => 'Кодът на сесията е копиран в клипборда',
			'watchTogether.relayUnreachable' => 'Релей сървърът е недостъпен. Блокиране от доставчика може да пречи на гледането заедно.',
			'watchTogether.reconnectingToHost' => 'Повторно свързване с домакина...',
			'watchTogether.currentPlayback' => 'Текущо възпроизвеждане',
			'watchTogether.joinCurrentPlayback' => 'Присъедини се към текущото възпроизвеждане',
			'watchTogether.joinCurrentPlaybackDescription' => 'Върнете се към това, което домакинът гледа в момента',
			'watchTogether.failedToOpenCurrentPlayback' => 'Неуспешно отваряне на текущото възпроизвеждане',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} се присъедини',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} напусна',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} постави на пауза',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} продължи',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} превъртя',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} буферира',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} е с по-стара версия на приложението — синхронизирането не е налично',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Продължаване без ${name}',
			'watchTogether.waitingForParticipants' => 'Изчакване другите да заредят...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Изчакване на ${name}...',
			'watchTogether.recentRooms' => 'Скорошни стаи',
			'watchTogether.renameRoom' => 'Преименувай стая',
			'watchTogether.removeRoom' => 'Премахни',
			'watchTogether.guestSwitchUnavailable' => 'Превключването не е възможно — сървърът е недостъпен за синхронизация',
			'watchTogether.guestSwitchFailed' => 'Превключването не е възможно — съдържанието не е намерено на този сървър',
			'downloads.title' => 'Изтегляния',
			'downloads.manage' => 'Управление',
			'downloads.tvShows' => 'ТВ сериали',
			'downloads.movies' => 'Филми',
			_ => null,
		} ?? switch (path) {
			'downloads.music' => 'Музика',
			'downloads.tracksQueued' => ({required Object count}) => '${count} песни в опашката за изтегляне',
			'downloads.noDownloads' => 'Все още няма изтегляния',
			'downloads.noDownloadsDescription' => 'Изтегленото съдържание ще се показва тук за офлайн гледане',
			'downloads.downloadNow' => 'Изтегли',
			'downloads.deleteDownload' => 'Изтрий изтегляне',
			'downloads.retryDownload' => 'Опитай изтеглянето отново',
			'downloads.downloadQueued' => 'Изтеглянето е добавено в опашката',
			'downloads.downloadResumed' => 'Изтеглянето е възобновено',
			'downloads.serverErrorBitrate' => 'Грешка на сървъра: файлът може да надвишава лимита за отдалечен битрейт',
			'downloads.episodesQueued' => ({required Object count}) => '${count} епизода са добавени в опашката за изтегляне',
			'downloads.downloadDeleted' => 'Изтеглянето е изтрито',
			'downloads.deleteConfirm' => ({required Object title}) => 'Да се изтрие ли "${title}" от това устройство?',
			'downloads.cancelledDownloadTitle' => 'Отменено изтегляне',
			'downloads.cancelledDownloadMessage' => 'Това изтегляне беше отменено. Какво искате да направите?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Всички епизоди вече са изтеглени',
			'downloads.resumeDownload' => 'Възобнови изтеглянето',
			'downloads.cancelledDownload' => 'Отменено изтегляне',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (синхронизира се ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Изтеглен ${file} — щракнете за довършване',
			'downloads.partialDownloadClickToComplete' => 'Частично изтеглено — щракнете за довършване',
			'downloads.deleting' => 'Изтриване...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Изтриване на ${title}... (${current} от ${total})',
			'downloads.queuedTooltip' => 'В опашката',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'В опашката: ${files}',
			'downloads.downloadingTooltip' => 'Изтегляне...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Изтегляне на ${files}',
			'downloads.noDownloadsTree' => 'Няма изтегляния',
			'downloads.pauseAll' => 'Пауза на всички',
			'downloads.resumeAll' => 'Продължи всички',
			'downloads.deleteAll' => 'Изтрий всички',
			'downloads.selectVersion' => 'Избери версия',
			'downloads.allEpisodes' => 'Всички епизоди',
			'downloads.unwatchedOnly' => 'Само негледани',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Следващите ${count} негледани',
			'downloads.customAmount' => 'Персонален брой...',
			'downloads.includeSpecials' => 'Включи специалните',
			'downloads.howManyEpisodes' => 'Колко епизода?',
			'downloads.invalidEpisodeCount' => 'Въведете валиден брой епизоди.',
			'downloads.keepSynced' => 'Поддържай синхронизирано',
			'downloads.downloadOnce' => 'Изтегли еднократно',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Пази ${count} негледани',
			'downloads.editSyncRule' => 'Редактирай правило за синхронизация',
			'downloads.removeSyncRule' => 'Премахни правило за синхронизация',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Да се спре ли синхронизацията за "${title}"? Изтеглените епизоди ще останат.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Правилото за синхронизация е създадено — запазват се ${count} негледани епизода',
			'downloads.syncRuleUpdated' => 'Правилото за синхронизация е обновено',
			'downloads.syncRuleRemoved' => 'Правилото за синхронизация е премахнато',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Синхронизирани са ${count} нови епизода за ${title}',
			'downloads.activeSyncRules' => 'Правила за синхронизация',
			'downloads.noSyncRules' => 'Няма правила за синхронизация',
			'downloads.manageSyncRule' => 'Управление на синхронизацията',
			'downloads.editEpisodeCount' => 'Брой епизоди',
			'downloads.editSyncFilter' => 'Филтър за синхронизация',
			'downloads.syncAllItems' => 'Синхронизират се всички елементи',
			'downloads.syncUnwatchedItems' => 'Синхронизират се негледаните елементи',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Сървър: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Налично',
			'downloads.syncRuleOffline' => 'Офлайн',
			'downloads.syncRuleSignInRequired' => 'Изисква се вход',
			'downloads.syncRuleNotAvailableForProfile' => 'Не е налично за текущия профил',
			'downloads.syncRuleUnknownServer' => 'Неизвестен сървър',
			'downloads.syncRuleListCreated' => 'Правилото за синхронизация е създадено',
			'shaders.title' => 'Шейдъри',
			'shaders.noShaderDescription' => 'Без видео подобрение',
			'shaders.nvscalerDescription' => 'Мащабиране на изображението чрез NVIDIA за по-рязко видео',
			'shaders.artcnnVariantNeutral' => 'Неутрален',
			'shaders.artcnnVariantDenoise' => 'Премахване на шум',
			'shaders.artcnnVariantDenoiseSharpen' => 'Премахване на шум + изостряне',
			'shaders.qualityFast' => 'Бързо',
			'shaders.qualityHQ' => 'Високо качество',
			'shaders.mode' => 'Режим',
			'shaders.importShader' => 'Импортирай шейдър',
			'shaders.customShaderDescription' => 'Персонален GLSL шейдър',
			'shaders.shaderImported' => 'Шейдърът е импортиран',
			'shaders.shaderImportFailed' => 'Неуспешно импортиране на шейдър',
			'shaders.deleteShader' => 'Изтрий шейдър',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Да се изтрие ли "${name}"?',
			'companionRemote.title' => 'Дистанционно управление',
			'companionRemote.connectedTo' => ({required Object name}) => 'Свързан към ${name}',
			'companionRemote.unknownDevice' => 'Непознато устройство',
			'companionRemote.session.startingServer' => 'Стартиране на сървър за дистанционно управление...',
			'companionRemote.session.hostAddress' => 'Адрес на хоста',
			'companionRemote.session.connected' => 'Свързан',
			'companionRemote.session.serverRunning' => 'Сървърът за дистанционно управление е активен',
			'companionRemote.session.serverStopped' => 'Сървърът за дистанционно управление е спрян',
			'companionRemote.session.serverRunningDescription' => 'Мобилни устройства във вашата мрежа могат да се свързват с това приложение',
			'companionRemote.session.serverStoppedDescription' => 'Стартирайте сървъра, за да позволите на мобилни устройства да се свързват',
			'companionRemote.session.usePhoneToControl' => 'Използвайте мобилното си устройство, за да управлявате това приложение',
			'companionRemote.session.startServer' => 'Стартирай сървър',
			'companionRemote.session.stopServer' => 'Спри сървър',
			'companionRemote.session.minimize' => 'Минимизирай',
			'companionRemote.pairing.discoveryDescription' => 'Plezy устройства със същия Plex акаунт се показват тук',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Свързване...',
			'companionRemote.pairing.searchingForDevices' => 'Търсене на устройства...',
			'companionRemote.pairing.noDevicesFound' => 'Не са намерени устройства във вашата мрежа',
			'companionRemote.pairing.noDevicesHint' => 'Отворете Plezy на настолен компютър и използвайте същия WiFi',
			'companionRemote.pairing.availableDevices' => 'Налични устройства',
			'companionRemote.pairing.manualConnection' => 'Ръчно свързване',
			'companionRemote.pairing.cryptoInitFailed' => 'Не може да се стартира защитена връзка. Първо влезте в Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Моля, въведете адрес на хоста',
			'companionRemote.pairing.validationHostFormat' => 'Форматът трябва да е IP:port (напр. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Връзката изтече. Използвайте една и съща мрежа на двете устройства.',
			'companionRemote.pairing.sessionNotFound' => 'Устройството не е намерено. Уверете се, че Plezy работи на хоста.',
			'companionRemote.pairing.authFailed' => 'Удостоверяването е неуспешно. Двете устройства трябва да използват същия Plex акаунт.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Неуспешно свързване: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Искате ли да прекъснете връзката с дистанционната сесия?',
			'companionRemote.remote.reconnecting' => 'Повторно свързване...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Опит ${current} от 5',
			'companionRemote.remote.retryNow' => 'Опитай сега',
			'companionRemote.remote.tabRemote' => 'Дистанционно',
			'companionRemote.remote.tabPlay' => 'Пускане',
			'companionRemote.remote.tabMore' => 'Още',
			'companionRemote.remote.menu' => 'Меню',
			'companionRemote.remote.tabNavigation' => 'Навигация с Tab',
			'companionRemote.remote.tabDiscover' => 'Открий',
			'companionRemote.remote.tabLibraries' => 'Библиотеки',
			'companionRemote.remote.tabSearch' => 'Търсене',
			'companionRemote.remote.tabDownloads' => 'Изтегляния',
			'companionRemote.remote.tabSettings' => 'Настройки',
			'companionRemote.remote.previous' => 'Предишен',
			'companionRemote.remote.playPause' => 'Пускане/пауза',
			'companionRemote.remote.next' => 'Следващ',
			'companionRemote.remote.seekBack' => 'Назад',
			'companionRemote.remote.stop' => 'Стоп',
			'companionRemote.remote.seekForward' => 'Напред',
			'companionRemote.remote.volume' => 'Звук',
			'companionRemote.remote.volumeDown' => 'Надолу',
			'companionRemote.remote.volumeUp' => 'Нагоре',
			'companionRemote.remote.fullscreen' => 'Цял екран',
			'companionRemote.remote.subtitles' => 'Субтитри',
			'companionRemote.remote.audio' => 'Аудио',
			'companionRemote.remote.searchHint' => 'Търсене на настолен компютър...',
			'companionRemote.errors.noNetworkInterface' => 'Не е намерен мрежов интерфейс',
			'companionRemote.errors.authenticationFailed' => 'Неуспешно удостоверяване',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Неуспешно стартиране на отдалечения сървър: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Неуспешно изпращане на отдалечена команда: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Времето за присъединяване към сесията изтече',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Неуспешно свързване към който и да е адрес',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Връзката е загубена след ${attempts} опита',
			'companionRemote.errors.connectionLost' => 'Връзката е загубена',
			'videoSettings.playbackSpeed' => 'Скорост на възпроизвеждане',
			'videoSettings.normalSpeed' => 'Нормална',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Активен (${duration})',
			'videoSettings.zoom' => 'Мащаб',
			'videoSettings.sleepTimer' => 'Таймер за заспиване',
			'videoSettings.audioSync' => 'Синхронизация на аудио',
			'videoSettings.subtitleSync' => 'Синхронизация на субтитри',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Аудио изход',
			'videoSettings.performanceOverlay' => 'Оверлей за производителност',
			'videoSettings.audioPassthrough' => 'Аудио passthrough',
			'videoSettings.audioNormalization' => 'Нормализиране на силата на звука',
			'videoSettings.audioDownmix' => 'Смесване до стерео',
			'performanceOverlay.color' => 'Цвят',
			'performanceOverlay.performance' => 'Производителност',
			'performanceOverlay.buffer' => 'Буфер',
			'performanceOverlay.app' => 'Приложение',
			'performanceOverlay.decoder' => 'Декодер',
			'performanceOverlay.rawDecoder' => 'Суров декодер',
			'performanceOverlay.tunneling' => 'Тунелиране',
			'performanceOverlay.aspect' => 'Съотношение',
			'performanceOverlay.rotation' => 'Завъртане',
			'performanceOverlay.dvSource' => 'DV източник',
			'performanceOverlay.dvPath' => 'DV път',
			'performanceOverlay.p7Conversion' => 'P7 конв.',
			'performanceOverlay.sampleRate' => 'Честота',
			'performanceOverlay.pixelFormat' => 'Пикселен формат',
			'performanceOverlay.hwFormat' => 'HW формат',
			'performanceOverlay.matrix' => 'Матрица',
			'performanceOverlay.primaries' => 'Основни цветове',
			'performanceOverlay.transfer' => 'Трансфер',
			'performanceOverlay.renderFps' => 'Render FPS',
			'performanceOverlay.displayFps' => 'Display FPS',
			'performanceOverlay.avSync' => 'A/V синхр.',
			'performanceOverlay.dropped' => 'Изпуснати',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'Средно DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Средно DV семпл',
			'performanceOverlay.maxLuma' => 'Макс. яркост',
			'performanceOverlay.minLuma' => 'Мин. яркост',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Използван кеш',
			'performanceOverlay.cacheLimit' => 'Лимит на кеша',
			'performanceOverlay.speed' => 'Скорост',
			'performanceOverlay.player' => 'Плеър',
			'performanceOverlay.memory' => 'Памет',
			'performanceOverlay.uiFps' => 'UI FPS',
			'externalPlayer.title' => 'Външен плеър',
			'externalPlayer.useExternalPlayer' => 'Използвай външен плеър',
			'externalPlayer.useExternalPlayerDescription' => 'Отваряй видеата в друго приложение',
			'externalPlayer.selectPlayer' => 'Избери плейър',
			'externalPlayer.customPlayers' => 'Персонални плейъри',
			'externalPlayer.systemDefault' => 'Системен по подразбиране',
			'externalPlayer.addCustomPlayer' => 'Добави персонален плейър',
			'externalPlayer.playerName' => 'Име на плейъра',
			'externalPlayer.playerNameHint' => 'Моят плеър',
			'externalPlayer.playerCommand' => 'Команда',
			'externalPlayer.playerPackage' => 'Име на пакет',
			'externalPlayer.playerUrlScheme' => 'URL схема',
			'externalPlayer.off' => 'Изключено',
			'externalPlayer.launchFailed' => 'Неуспешно отваряне на външен плеър',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} не е инсталиран',
			'externalPlayer.playInExternalPlayer' => 'Пусни във външен плеър',
			'metadataEdit.editMetadata' => 'Редактирай...',
			'metadataEdit.screenTitle' => 'Редактиране на метаданни',
			'metadataEdit.basicInfo' => 'Основна информация',
			'metadataEdit.artwork' => 'Обложка',
			'metadataEdit.advancedSettings' => 'Разширени настройки',
			'metadataEdit.title' => 'Заглавие',
			'metadataEdit.sortTitle' => 'Заглавие за сортиране',
			'metadataEdit.originalTitle' => 'Оригинално заглавие',
			'metadataEdit.releaseDate' => 'Дата на излизане',
			'metadataEdit.contentRating' => 'Възрастов рейтинг',
			'metadataEdit.studio' => 'Студио',
			'metadataEdit.tagline' => 'Слоган',
			'metadataEdit.summary' => 'Резюме',
			'metadataEdit.poster' => 'Постер',
			'metadataEdit.background' => 'Фон',
			'metadataEdit.logo' => 'Лого',
			'metadataEdit.squareArt' => 'Квадратно изображение',
			'metadataEdit.selectPoster' => 'Избери постер',
			'metadataEdit.selectBackground' => 'Избери фон',
			'metadataEdit.selectLogo' => 'Избери лого',
			'metadataEdit.selectSquareArt' => 'Избери квадратно изображение',
			'metadataEdit.fromUrl' => 'От URL',
			'metadataEdit.uploadFile' => 'Качи файл',
			'metadataEdit.enterImageUrl' => 'Въведете URL на изображение',
			'metadataEdit.imageUrl' => 'URL на изображение',
			'metadataEdit.metadataUpdated' => 'Метаданните са обновени',
			'metadataEdit.metadataUpdateFailed' => 'Неуспешно обновяване на метаданни',
			'metadataEdit.artworkUpdated' => 'Обложката е обновена',
			'metadataEdit.artworkUpdateFailed' => 'Неуспешно обновяване на обложката',
			'metadataEdit.noArtworkAvailable' => 'Няма налична обложка',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Вариант за обложка ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Вариант за обложка ${index}, избран',
			'metadataEdit.notSet' => 'Не е зададено',
			'metadataEdit.libraryDefault' => 'По подразбиране за библиотеката',
			'metadataEdit.accountDefault' => 'По подразбиране за акаунта',
			'metadataEdit.seriesDefault' => 'По подразбиране за сериала',
			'metadataEdit.episodeSorting' => 'Сортиране на епизоди',
			'metadataEdit.oldestFirst' => 'Най-старите първо',
			'metadataEdit.newestFirst' => 'Най-новите първо',
			'metadataEdit.keep' => 'Пази',
			'metadataEdit.allEpisodes' => 'Всички епизоди',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} последни епизода',
			'metadataEdit.latestEpisode' => 'Последен епизод',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Епизоди, добавени през последните ${count} дни',
			'metadataEdit.deleteAfterPlaying' => 'Изтрий епизодите след възпроизвеждане',
			'metadataEdit.never' => 'Никога',
			'metadataEdit.afterADay' => 'След един ден',
			'metadataEdit.afterAWeek' => 'След една седмица',
			'metadataEdit.afterAMonth' => 'След един месец',
			'metadataEdit.onNextRefresh' => 'При следващо опресняване',
			'metadataEdit.seasons' => 'Сезони',
			'metadataEdit.show' => 'Покажи',
			'metadataEdit.hide' => 'Скрий',
			'metadataEdit.episodeOrdering' => 'Подредба на епизодите',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Aired)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Aired)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolute)',
			'metadataEdit.metadataLanguage' => 'Език на метаданните',
			'metadataEdit.useOriginalTitle' => 'Използвай оригиналното заглавие',
			'metadataEdit.preferredAudioLanguage' => 'Предпочитан аудио език',
			'metadataEdit.preferredSubtitleLanguage' => 'Предпочитан език за субтитри',
			'metadataEdit.subtitleMode' => 'Режим за автоматичен избор на субтитри',
			'metadataEdit.manuallySelected' => 'Ръчно избрано',
			'metadataEdit.shownWithForeignAudio' => 'Показва се при чуждо аудио',
			'metadataEdit.alwaysEnabled' => 'Винаги включено',
			'metadataEdit.tags' => 'Тагове',
			'metadataEdit.addTag' => 'Добави таг',
			'metadataEdit.genre' => 'Жанр',
			'metadataEdit.director' => 'Режисьор',
			'metadataEdit.writer' => 'Сценарист',
			'metadataEdit.producer' => 'Продуцент',
			'metadataEdit.country' => 'Държава',
			'metadataEdit.collection' => 'Колекция',
			'metadataEdit.label' => 'Етикет',
			'metadataEdit.style' => 'Стил',
			'metadataEdit.mood' => 'Настроение',
			'matchScreen.match' => 'Съпостави...',
			'matchScreen.fixMatch' => 'Поправи съвпадение...',
			'matchScreen.unmatch' => 'Премахни съвпадение',
			'matchScreen.unmatchConfirm' => 'Да се изчисти ли това съвпадение? Plex ще го третира като несъпоставено, докато не бъде съпоставено отново.',
			'matchScreen.unmatchSuccess' => 'Съвпадението на елемента е премахнато',
			'matchScreen.unmatchFailed' => 'Неуспешно премахване на съвпадението на елемента',
			'matchScreen.matchApplied' => 'Съвпадението е приложено',
			'matchScreen.matchFailed' => 'Неуспешно прилагане на съвпадение',
			'matchScreen.titleHint' => 'Заглавие',
			'matchScreen.yearHint' => 'Година',
			'matchScreen.search' => 'Търсене',
			'matchScreen.noMatchesFound' => 'Няма намерени съвпадения',
			'serverTasks.title' => 'Задачи на сървъра',
			'serverTasks.failedToLoad' => 'Неуспешно зареждане на задачи',
			'serverTasks.noTasks' => 'Няма изпълняващи се задачи',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Свързан',
			'trakt.connectedAs' => ({required Object username}) => 'Свързан като @${username}',
			'trakt.disconnectConfirm' => 'Да се прекъсне ли Trakt акаунтът?',
			'trakt.disconnectConfirmBody' => 'Plezy ще спре да изпраща събития към Trakt. Можете да се свържете отново по всяко време.',
			'trakt.scrobble' => 'Скроблиране в реално време',
			'trakt.scrobbleDescription' => 'Изпращай събития за пускане, пауза и спиране към Trakt по време на възпроизвеждане.',
			'trakt.watchedSync' => 'Синхронизирай статус гледано',
			'trakt.watchedSyncDescription' => 'Когато маркирате елементи като гледани в Plezy, маркирай ги и в Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Свързване със Seerr',
			'seerr.serverUrl' => 'URL на сървъра',
			'seerr.serverUrlHelper' => 'Адресът на твоята Seerr инстанция',
			'seerr.checkServer' => 'Продължи',
			'seerr.signInWithJellyfin' => 'Вход с Jellyfin',
			'seerr.signInWithEmby' => 'Вход с Emby',
			'seerr.signInWithLocal' => 'Използвай локален акаунт',
			'seerr.email' => 'Имейл',
			'seerr.noSignInMethods' => 'Тази Seerr инстанция не предлага метод за вход, който Plezy поддържа.',
			'seerr.instance' => 'Инстанция',
			'seerr.disconnectConfirm' => 'Да се прекъсне ли Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy ще забрави тази Seerr инстанция. Можете да се свържете отново по всяко време.',
			'seerr.request' => 'Заяви',
			'seerr.request4k' => 'Заяви в 4K',
			'seerr.seasons' => 'Сезони',
			'seerr.allSeasons' => 'Всички сезони',
			'seerr.advancedOptions' => 'Разширени',
			'seerr.destinationServer' => 'Целеви сървър',
			'seerr.qualityProfile' => 'Профил за качество',
			'seerr.rootFolder' => 'Основна папка',
			'seerr.languageProfile' => 'Езиков профил',
			'seerr.requestSubmitted' => 'Заявката е изпратена',
			'seerr.requestFailed' => ({required Object error}) => 'Заявката се провали: ${error}',
			'seerr.requestsLoadFailed' => 'Неуспешно зареждане на опциите за заявка',
			'seerr.nothingToRequest' => 'Всичко вече е налично или заявено.',
			'seerr.statusAvailable' => 'Налично',
			'seerr.statusPartiallyAvailable' => 'Частично налично',
			'seerr.statusRequested' => 'Заявено',
			'seerr.statusProcessing' => 'Обработва се',
			'services.title' => 'Услуги',
			'services.hubSubtitle' => 'Синхронизирай прогреса на гледане и заявявай нови заглавия.',
			'services.notConnected' => 'Не е свързан',
			'services.connectedAs' => ({required Object username}) => 'Свързан като @${username}',
			'services.scrobble' => 'Проследявай прогреса автоматично',
			'services.scrobbleDescription' => 'Обновявай списъка си, когато завършиш епизод или филм.',
			'services.disconnectConfirm' => ({required Object service}) => 'Да се прекъсне ли ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy ще спре да обновява ${service}. Можете да се свържете отново по всяко време.',
			'services.connectFailed' => ({required Object service}) => 'Неуспешно свързване с ${service}. Опитайте отново.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Активиране на Plezy в ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Посетете ${url} и въведете този код:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Отворете ${service}, за да активирате',
			'services.deviceCode.copyCode' => 'Копирай кода за активиране',
			'services.deviceCode.waitingForAuthorization' => 'Изчакване на оторизация…',
			'services.deviceCode.codeCopied' => 'Кодът е копиран',
			'services.oauthProxy.title' => ({required Object service}) => 'Вход в ${service}',
			'services.oauthProxy.body' => 'Сканирайте този QR код или отворете URL-а на което и да е устройство.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Отворете ${service}, за да влезете',
			'services.oauthProxy.copyUrl' => 'Копирай URL адреса за вход',
			'services.oauthProxy.urlCopied' => 'URL адресът е копиран',
			'services.libraryFilter.title' => 'Филтър на библиотеките',
			'services.libraryFilter.subtitleAllSyncing' => 'Синхронизират се всички библиотеки',
			'services.libraryFilter.subtitleNoneSyncing' => 'Нищо не се синхронизира',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} блокирани',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} разрешени',
			'services.libraryFilter.mode' => 'Режим на филтъра',
			'services.libraryFilter.modeBlacklist' => 'Черен списък',
			'services.libraryFilter.modeWhitelist' => 'Бял списък',
			'services.libraryFilter.modeHintBlacklist' => 'Синхронизирай всяка библиотека, освен отметнатите по-долу.',
			'services.libraryFilter.modeHintWhitelist' => 'Синхронизирай само отметнатите по-долу библиотеки.',
			'services.libraryFilter.libraries' => 'Библиотеки',
			'services.libraryFilter.noLibraries' => 'Няма налични библиотеки',
			'addServer.addJellyfinTitle' => 'Добави Jellyfin сървър',
			'addServer.serverUrls' => 'URL адреси на сървъра',
			'addServer.serverUrlsHelper' => 'Позволени са няколко URL адреса, разделени със запетаи.',
			'addServer.findServer' => 'Намери сървър',
			'addServer.searchingLocalServers' => 'Търсене на локални Jellyfin сървъри...',
			'addServer.localServers' => 'Локални Jellyfin сървъри',
			'addServer.username' => 'Потребителско име',
			'addServer.password' => 'Парола',
			'addServer.signIn' => 'Вход',
			'addServer.change' => 'Промени',
			'addServer.required' => 'Задължително',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Сървърът не може да бъде достигнат: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Входът е неуспешен: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect е неуспешен: ${error}',
			'addServer.addPlexTitle' => 'Вход с Plex',
			'addServer.pinExpired' => 'PIN-ът изтече преди вход. Моля, опитайте отново.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Неуспешна регистрация на акаунт: ${error}',
			'addServer.enterJellyfinUrlError' => 'Въведете URL адреса на вашия Jellyfin сървър',
			'addServer.addConnectionTitle' => 'Добави връзка',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Добави към ${name}',
			'addServer.signInWithPlexCard' => 'Вход с Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Удостоверете това устройство. Споделените сървъри се добавят.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Удостоверете Plex акаунт. Домашните потребители стават профили.',
			'addServer.connectToJellyfinCard' => 'Свързване с Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Въведете URL адрес на сървъра, потребителско име и парола.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Вход в Jellyfin сървър. Свързва се с ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Използвай от друг профил',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Използвай връзка от друг профил. PIN-защитените профили изискват PIN.',
			_ => null,
		};
	}
}
