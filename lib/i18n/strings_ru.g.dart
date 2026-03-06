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
class TranslationsRu with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppRu app = _TranslationsAppRu._(_root);
	@override late final _TranslationsAuthRu auth = _TranslationsAuthRu._(_root);
	@override late final _TranslationsCommonRu common = _TranslationsCommonRu._(_root);
	@override late final _TranslationsScreensRu screens = _TranslationsScreensRu._(_root);
	@override late final _TranslationsUpdateRu update = _TranslationsUpdateRu._(_root);
	@override late final _TranslationsSettingsRu settings = _TranslationsSettingsRu._(_root);
	@override late final _TranslationsSearchRu search = _TranslationsSearchRu._(_root);
	@override late final _TranslationsHotkeysRu hotkeys = _TranslationsHotkeysRu._(_root);
	@override late final _TranslationsPinEntryRu pinEntry = _TranslationsPinEntryRu._(_root);
	@override late final _TranslationsFileInfoRu fileInfo = _TranslationsFileInfoRu._(_root);
	@override late final _TranslationsMediaMenuRu mediaMenu = _TranslationsMediaMenuRu._(_root);
	@override late final _TranslationsAccessibilityRu accessibility = _TranslationsAccessibilityRu._(_root);
	@override late final _TranslationsTooltipsRu tooltips = _TranslationsTooltipsRu._(_root);
	@override late final _TranslationsVideoControlsRu videoControls = _TranslationsVideoControlsRu._(_root);
	@override late final _TranslationsUserStatusRu userStatus = _TranslationsUserStatusRu._(_root);
	@override late final _TranslationsMessagesRu messages = _TranslationsMessagesRu._(_root);
	@override late final _TranslationsSubtitlingStylingRu subtitlingStyling = _TranslationsSubtitlingStylingRu._(_root);
	@override late final _TranslationsMpvConfigRu mpvConfig = _TranslationsMpvConfigRu._(_root);
	@override late final _TranslationsDialogRu dialog = _TranslationsDialogRu._(_root);
	@override late final _TranslationsDiscoverRu discover = _TranslationsDiscoverRu._(_root);
	@override late final _TranslationsErrorsRu errors = _TranslationsErrorsRu._(_root);
	@override late final _TranslationsLibrariesRu libraries = _TranslationsLibrariesRu._(_root);
	@override late final _TranslationsAboutRu about = _TranslationsAboutRu._(_root);
	@override late final _TranslationsServerSelectionRu serverSelection = _TranslationsServerSelectionRu._(_root);
	@override late final _TranslationsHubDetailRu hubDetail = _TranslationsHubDetailRu._(_root);
	@override late final _TranslationsLogsRu logs = _TranslationsLogsRu._(_root);
	@override late final _TranslationsLicensesRu licenses = _TranslationsLicensesRu._(_root);
	@override late final _TranslationsNavigationRu navigation = _TranslationsNavigationRu._(_root);
	@override late final _TranslationsLiveTvRu liveTv = _TranslationsLiveTvRu._(_root);
	@override late final _TranslationsCollectionsRu collections = _TranslationsCollectionsRu._(_root);
	@override late final _TranslationsPlaylistsRu playlists = _TranslationsPlaylistsRu._(_root);
	@override late final _TranslationsWatchTogetherRu watchTogether = _TranslationsWatchTogetherRu._(_root);
	@override late final _TranslationsDownloadsRu downloads = _TranslationsDownloadsRu._(_root);
	@override late final _TranslationsShadersRu shaders = _TranslationsShadersRu._(_root);
	@override late final _TranslationsCompanionRemoteRu companionRemote = _TranslationsCompanionRemoteRu._(_root);
	@override late final _TranslationsVideoSettingsRu videoSettings = _TranslationsVideoSettingsRu._(_root);
	@override late final _TranslationsExternalPlayerRu externalPlayer = _TranslationsExternalPlayerRu._(_root);
	@override late final _TranslationsMetadataEditRu metadataEdit = _TranslationsMetadataEditRu._(_root);
}

// Path: app
class _TranslationsAppRu implements TranslationsAppEn {
	_TranslationsAppRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthRu implements TranslationsAuthEn {
	_TranslationsAuthRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Войти через Plex';
	@override String get showQRCode => 'Показать QR-код';
	@override String get authenticate => 'Аутентификация';
	@override String get debugEnterToken => 'Отладка: Ввести токен Plex';
	@override String get plexTokenLabel => 'Токен авторизации Plex';
	@override String get plexTokenHint => 'Введите ваш токен Plex.tv';
	@override String get authenticationTimeout => 'Время аутентификации истекло. Попробуйте снова.';
	@override String get scanQRToSignIn => 'Отсканируйте QR-код для входа';
	@override String get waitingForAuth => 'Ожидание аутентификации...\nЗавершите вход в браузере.';
	@override String get useBrowser => 'Использовать браузер';
}

// Path: common
class _TranslationsCommonRu implements TranslationsCommonEn {
	_TranslationsCommonRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Отмена';
	@override String get save => 'Сохранить';
	@override String get close => 'Закрыть';
	@override String get clear => 'Очистить';
	@override String get reset => 'Сбросить';
	@override String get later => 'Позже';
	@override String get submit => 'Отправить';
	@override String get confirm => 'Подтвердить';
	@override String get retry => 'Повторить';
	@override String get logout => 'Выйти';
	@override String get unknown => 'Неизвестно';
	@override String get refresh => 'Обновить';
	@override String get yes => 'Да';
	@override String get no => 'Нет';
	@override String get delete => 'Удалить';
	@override String get shuffle => 'Перемешать';
	@override String get addTo => 'Добавить в...';
	@override String get createNew => 'Создать новый';
	@override String get remove => 'Удалить';
	@override String get paste => 'Вставить';
	@override String get connect => 'Подключить';
	@override String get disconnect => 'Отключить';
	@override String get play => 'Воспроизвести';
	@override String get pause => 'Пауза';
	@override String get resume => 'Продолжить';
	@override String get error => 'Ошибка';
	@override String get search => 'Поиск';
	@override String get home => 'Главная';
	@override String get back => 'Назад';
	@override String get settings => 'Настройки';
	@override String get mute => 'Без звука';
	@override String get ok => 'OK';
	@override String get loading => 'Загрузка...';
	@override String get reconnect => 'Переподключить';
	@override String get exitConfirmTitle => 'Выйти из приложения?';
	@override String get exitConfirmMessage => 'Вы уверены, что хотите выйти?';
	@override String get dontAskAgain => 'Больше не спрашивать';
	@override String get exit => 'Выход';
	@override String get viewAll => 'Показать все';
	@override String get checkingNetwork => 'Проверка сети...';
	@override String get refreshingServers => 'Обновление серверов...';
	@override String get loadingServers => 'Загрузка серверов...';
	@override String get connectingToServers => 'Подключение к серверам...';
	@override String get startingOfflineMode => 'Запуск автономного режима...';
}

// Path: screens
class _TranslationsScreensRu implements TranslationsScreensEn {
	_TranslationsScreensRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Лицензии';
	@override String get switchProfile => 'Сменить профиль';
	@override String get subtitleStyling => 'Стиль субтитров';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Логи';
}

// Path: update
class _TranslationsUpdateRu implements TranslationsUpdateEn {
	_TranslationsUpdateRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get available => 'Доступно обновление';
	@override String versionAvailable({required Object version}) => 'Доступна версия ${version}';
	@override String currentVersion({required Object version}) => 'Текущая: ${version}';
	@override String get skipVersion => 'Пропустить эту версию';
	@override String get viewRelease => 'Посмотреть релиз';
	@override String get latestVersion => 'У вас последняя версия';
	@override String get checkFailed => 'Не удалось проверить обновления';
}

// Path: settings
class _TranslationsSettingsRu implements TranslationsSettingsEn {
	_TranslationsSettingsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Настройки';
	@override String get language => 'Язык';
	@override String get theme => 'Тема';
	@override String get appearance => 'Внешний вид';
	@override String get videoPlayback => 'Воспроизведение видео';
	@override String get advanced => 'Дополнительно';
	@override String get episodePosterMode => 'Стиль постера эпизода';
	@override String get seriesPoster => 'Постер сериала';
	@override String get seriesPosterDescription => 'Показывать постер сериала для всех эпизодов';
	@override String get seasonPoster => 'Постер сезона';
	@override String get seasonPosterDescription => 'Показывать постер конкретного сезона для эпизодов';
	@override String get episodeThumbnail => 'Миниатюра эпизода';
	@override String get episodeThumbnailDescription => 'Показывать миниатюры скриншотов эпизодов 16:9';
	@override String get showHeroSectionDescription => 'Показывать карусель избранного контента на главном экране';
	@override String get secondsLabel => 'Секунды';
	@override String get minutesLabel => 'Минуты';
	@override String get secondsShort => 'с';
	@override String get minutesShort => 'м';
	@override String durationHint({required Object min, required Object max}) => 'Введите длительность (${min}-${max})';
	@override String get systemTheme => 'Системная';
	@override String get systemThemeDescription => 'Следовать настройкам системы';
	@override String get lightTheme => 'Светлая';
	@override String get darkTheme => 'Тёмная';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Чистый чёрный для OLED-экранов';
	@override String get libraryDensity => 'Плотность библиотеки';
	@override String get compact => 'Компактный';
	@override String get compactDescription => 'Меньшие карточки, больше элементов видно';
	@override String get normal => 'Обычный';
	@override String get normalDescription => 'Размер по умолчанию';
	@override String get comfortable => 'Комфортный';
	@override String get comfortableDescription => 'Большие карточки, меньше элементов видно';
	@override String get viewMode => 'Режим просмотра';
	@override String get gridView => 'Сетка';
	@override String get gridViewDescription => 'Отображать элементы в виде сетки';
	@override String get listView => 'Список';
	@override String get listViewDescription => 'Отображать элементы в виде списка';
	@override String get showHeroSection => 'Показать раздел избранного';
	@override String get useGlobalHubs => 'Использовать макет Plex Home';
	@override String get useGlobalHubsDescription => 'Показывать хабы главной страницы как в официальном клиенте Plex. При выключении показывает рекомендации по библиотекам.';
	@override String get showServerNameOnHubs => 'Показывать имя сервера в хабах';
	@override String get showServerNameOnHubsDescription => 'Всегда показывать имя сервера в заголовках хабов. При выключении показывает только для дублирующихся имён.';
	@override String get alwaysKeepSidebarOpen => 'Всегда держать боковую панель открытой';
	@override String get alwaysKeepSidebarOpenDescription => 'Боковая панель остаётся развёрнутой, область контента подстраивается';
	@override String get showUnwatchedCount => 'Показывать количество непросмотренных';
	@override String get showUnwatchedCountDescription => 'Отображать количество непросмотренных эпизодов для сериалов и сезонов';
	@override String get hideSpoilers => 'Скрыть спойлеры непросмотренных эпизодов';
	@override String get hideSpoilersDescription => 'Размывать миниатюры и скрывать описания эпизодов, которые вы ещё не смотрели';
	@override String get playerBackend => 'Бэкенд плеера';
	@override String get exoPlayer => 'ExoPlayer (Рекомендуется)';
	@override String get exoPlayerDescription => 'Нативный Android-плеер с лучшей аппаратной поддержкой';
	@override String get mpv => 'mpv';
	@override String get mpvDescription => 'Продвинутый плеер с большим количеством функций и поддержкой субтитров ASS';
	@override String get hardwareDecoding => 'Аппаратное декодирование';
	@override String get hardwareDecodingDescription => 'Использовать аппаратное ускорение, когда доступно';
	@override String get bufferSize => 'Размер буфера';
	@override String bufferSizeMB({required Object size}) => '${size}МБ';
	@override String get bufferSizeAuto => 'Авто (Рекомендуется)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'У вашего устройства ${heap}МБ памяти. Буфер ${size}МБ может вызвать проблемы с воспроизведением.';
	@override String get subtitleStyling => 'Стиль субтитров';
	@override String get subtitleStylingDescription => 'Настроить внешний вид субтитров';
	@override String get smallSkipDuration => 'Малая перемотка';
	@override String get largeSkipDuration => 'Большая перемотка';
	@override String secondsUnit({required Object seconds}) => '${seconds} секунд';
	@override String get defaultSleepTimer => 'Таймер сна по умолчанию';
	@override String minutesUnit({required Object minutes}) => '${minutes} минут';
	@override String get rememberTrackSelections => 'Запоминать выбор дорожек для каждого сериала/фильма';
	@override String get rememberTrackSelectionsDescription => 'Автоматически сохранять предпочтения языка аудио и субтитров при переключении дорожек во время воспроизведения';
	@override String get clickVideoTogglesPlayback => 'Клик по видео для переключения воспроизведения/паузы';
	@override String get clickVideoTogglesPlaybackDescription => 'Если включено, клик по видеоплееру воспроизводит/ставит на паузу. В противном случае показывает/скрывает элементы управления.';
	@override String get videoPlayerControls => 'Элементы управления плеером';
	@override String get keyboardShortcuts => 'Горячие клавиши';
	@override String get keyboardShortcutsDescription => 'Настроить горячие клавиши';
	@override String get videoPlayerNavigation => 'Навигация видеоплеера';
	@override String get videoPlayerNavigationDescription => 'Использовать клавиши стрелок для навигации по элементам управления плеером';
	@override String get crashReporting => 'Отчёты об ошибках';
	@override String get crashReportingDescription => 'Отправлять отчёты об ошибках для улучшения приложения';
	@override String get debugLogging => 'Журнал отладки';
	@override String get debugLoggingDescription => 'Включить подробное журналирование для устранения неполадок';
	@override String get viewLogs => 'Просмотр логов';
	@override String get viewLogsDescription => 'Просмотр логов приложения';
	@override String get clearCache => 'Очистить кэш';
	@override String get clearCacheDescription => 'Это удалит все кэшированные изображения и данные. После очистки кэша приложение может загружать контент дольше.';
	@override String get clearCacheSuccess => 'Кэш успешно очищен';
	@override String get resetSettings => 'Сбросить настройки';
	@override String get resetSettingsDescription => 'Все настройки будут сброшены до значений по умолчанию. Это действие нельзя отменить.';
	@override String get resetSettingsSuccess => 'Настройки успешно сброшены';
	@override String get shortcutsReset => 'Горячие клавиши сброшены по умолчанию';
	@override String get about => 'О приложении';
	@override String get aboutDescription => 'Информация о приложении и лицензии';
	@override String get updates => 'Обновления';
	@override String get updateAvailable => 'Доступно обновление';
	@override String get checkForUpdates => 'Проверить обновления';
	@override String get validationErrorEnterNumber => 'Введите корректное число';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Длительность должна быть от ${min} до ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Клавиша уже назначена для ${action}';
	@override String shortcutUpdated({required Object action}) => 'Клавиша обновлена для ${action}';
	@override String get autoSkip => 'Автопропуск';
	@override String get autoSkipIntro => 'Автопропуск вступления';
	@override String get autoSkipIntroDescription => 'Автоматически пропускать маркеры вступления через несколько секунд';
	@override String get autoSkipCredits => 'Автопропуск титров';
	@override String get autoSkipCreditsDescription => 'Автоматически пропускать титры и воспроизводить следующий эпизод';
	@override String get autoSkipDelay => 'Задержка автопропуска';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Подождать ${seconds} секунд перед автопропуском';
	@override String get downloads => 'Загрузки';
	@override String get downloadLocationDescription => 'Выберите место для хранения загруженного контента';
	@override String get downloadLocationDefault => 'По умолчанию (Хранилище приложения)';
	@override String get downloadLocationCustom => 'Другое расположение';
	@override String get selectFolder => 'Выбрать папку';
	@override String get resetToDefault => 'Сбросить по умолчанию';
	@override String currentPath({required Object path}) => 'Текущий: ${path}';
	@override String get downloadLocationChanged => 'Место загрузки изменено';
	@override String get downloadLocationReset => 'Место загрузки сброшено по умолчанию';
	@override String get downloadLocationInvalid => 'Выбранная папка недоступна для записи';
	@override String get downloadLocationSelectError => 'Не удалось выбрать папку';
	@override String get downloadOnWifiOnly => 'Загружать только по WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Запретить загрузку по мобильным данным';
	@override String get cellularDownloadBlocked => 'Загрузка по мобильным данным отключена. Подключитесь к WiFi или измените настройку.';
	@override String get maxVolume => 'Максимальная громкость';
	@override String get maxVolumeDescription => 'Разрешить усиление громкости выше 100% для тихих медиа';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Показывать, что вы смотрите, в Discord';
	@override String get autoPip => 'Автоматический «картинка в картинке»';
	@override String get autoPipDescription => 'Автоматически переходить в режим «картинка в картинке» при выходе из приложения во время воспроизведения';
	@override String get matchContentFrameRate => 'Соответствие частоты кадров контента';
	@override String get matchContentFrameRateDescription => 'Настроить частоту обновления дисплея под видеоконтент, уменьшая дрожание и экономя батарею';
	@override String get tunneledPlayback => 'Туннельное воспроизведение';
	@override String get tunneledPlaybackDescription => 'Использовать аппаратный видеотуннелинг. Отключите, если видите чёрный экран со звуком при HDR-контенте';
	@override String get requireProfileSelectionOnOpen => 'Запрашивать профиль при запуске';
	@override String get requireProfileSelectionOnOpenDescription => 'Показывать выбор профиля при каждом открытии приложения';
	@override String get confirmExitOnBack => 'Подтверждать выход';
	@override String get confirmExitOnBackDescription => 'Показывать диалог подтверждения при нажатии «назад» для выхода из приложения';
	@override String get showNavBarLabels => 'Показывать подписи панели навигации';
	@override String get showNavBarLabelsDescription => 'Отображать текстовые подписи под иконками панели навигации';
}

// Path: search
class _TranslationsSearchRu implements TranslationsSearchEn {
	_TranslationsSearchRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Поиск фильмов, сериалов, музыки...';
	@override String get tryDifferentTerm => 'Попробуйте другой запрос';
	@override String get searchYourMedia => 'Поиск в вашей медиатеке';
	@override String get enterTitleActorOrKeyword => 'Введите название, актёра или ключевое слово';
}

// Path: hotkeys
class _TranslationsHotkeysRu implements TranslationsHotkeysEn {
	_TranslationsHotkeysRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Назначить клавишу для ${actionName}';
	@override String get clearShortcut => 'Очистить клавишу';
	@override late final _TranslationsHotkeysActionsRu actions = _TranslationsHotkeysActionsRu._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryRu implements TranslationsPinEntryEn {
	_TranslationsPinEntryRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Введите PIN';
	@override String get showPin => 'Показать PIN';
	@override String get hidePin => 'Скрыть PIN';
}

// Path: fileInfo
class _TranslationsFileInfoRu implements TranslationsFileInfoEn {
	_TranslationsFileInfoRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Информация о файле';
	@override String get video => 'Видео';
	@override String get audio => 'Аудио';
	@override String get file => 'Файл';
	@override String get advanced => 'Дополнительно';
	@override String get codec => 'Кодек';
	@override String get resolution => 'Разрешение';
	@override String get bitrate => 'Битрейт';
	@override String get frameRate => 'Частота кадров';
	@override String get aspectRatio => 'Соотношение сторон';
	@override String get profile => 'Профиль';
	@override String get bitDepth => 'Глубина цвета';
	@override String get colorSpace => 'Цветовое пространство';
	@override String get colorRange => 'Цветовой диапазон';
	@override String get colorPrimaries => 'Цветовые первичные';
	@override String get chromaSubsampling => 'Субдискретизация цветности';
	@override String get channels => 'Каналы';
	@override String get path => 'Путь';
	@override String get size => 'Размер';
	@override String get container => 'Контейнер';
	@override String get duration => 'Длительность';
	@override String get optimizedForStreaming => 'Оптимизировано для стриминга';
	@override String get has64bitOffsets => '64-битные смещения';
}

// Path: mediaMenu
class _TranslationsMediaMenuRu implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Отметить как просмотренное';
	@override String get markAsUnwatched => 'Отметить как непросмотренное';
	@override String get removeFromContinueWatching => 'Удалить из «Продолжить просмотр»';
	@override String get goToSeries => 'Перейти к сериалу';
	@override String get goToSeason => 'Перейти к сезону';
	@override String get shufflePlay => 'Случайное воспроизведение';
	@override String get fileInfo => 'Информация о файле';
	@override String get deleteFromServer => 'Удалить с сервера';
	@override String get confirmDelete => 'Это навсегда удалит этот медиафайл и его файлы с вашего сервера. Это действие нельзя отменить.';
	@override String get deleteMultipleWarning => 'Это включает все эпизоды и их файлы.';
	@override String get mediaDeletedSuccessfully => 'Медиаэлемент успешно удалён';
	@override String get mediaFailedToDelete => 'Не удалось удалить медиаэлемент';
	@override String get rate => 'Оценить';
}

// Path: accessibility
class _TranslationsAccessibilityRu implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, фильм';
	@override String mediaCardShow({required Object title}) => '${title}, сериал';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'просмотрено';
	@override String mediaCardPartiallyWatched({required Object percent}) => 'просмотрено ${percent} процентов';
	@override String get mediaCardUnwatched => 'не просмотрено';
	@override String get tapToPlay => 'Нажмите для воспроизведения';
}

// Path: tooltips
class _TranslationsTooltipsRu implements TranslationsTooltipsEn {
	_TranslationsTooltipsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Случайное воспроизведение';
	@override String get playTrailer => 'Воспроизвести трейлер';
	@override String get markAsWatched => 'Отметить как просмотренное';
	@override String get markAsUnwatched => 'Отметить как непросмотренное';
}

// Path: videoControls
class _TranslationsVideoControlsRu implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Аудио';
	@override String get subtitlesLabel => 'Субтитры';
	@override String get resetToZero => 'Сбросить до 0мс';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} воспроизводится позже';
	@override String playsEarlier({required Object label}) => '${label} воспроизводится раньше';
	@override String get noOffset => 'Без смещения';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Заполнить экран';
	@override String get stretch => 'Растянуть';
	@override String get lockRotation => 'Заблокировать поворот';
	@override String get unlockRotation => 'Разблокировать поворот';
	@override String get timerActive => 'Таймер активен';
	@override String playbackWillPauseIn({required Object duration}) => 'Воспроизведение будет приостановлено через ${duration}';
	@override String get sleepTimerCompleted => 'Таймер сна завершён — воспроизведение приостановлено';
	@override String get stillWatching => 'Всё ещё смотрите?';
	@override String pausingIn({required Object seconds}) => 'Пауза через ${seconds}с';
	@override String get continueWatching => 'Продолжить';
	@override String get autoPlayNext => 'Автовоспроизведение следующего';
	@override String get playNext => 'Следующее';
	@override String get playButton => 'Воспроизвести';
	@override String get pauseButton => 'Пауза';
	@override String seekBackwardButton({required Object seconds}) => 'Перемотка назад на ${seconds} секунд';
	@override String seekForwardButton({required Object seconds}) => 'Перемотка вперёд на ${seconds} секунд';
	@override String get previousButton => 'Предыдущий эпизод';
	@override String get nextButton => 'Следующий эпизод';
	@override String get previousChapterButton => 'Предыдущая глава';
	@override String get nextChapterButton => 'Следующая глава';
	@override String get muteButton => 'Без звука';
	@override String get unmuteButton => 'Включить звук';
	@override String get settingsButton => 'Настройки видео';
	@override String get audioTrackButton => 'Аудиодорожки';
	@override String get subtitlesButton => 'Субтитры';
	@override String get tracksButton => 'Аудио и субтитры';
	@override String get chaptersButton => 'Главы';
	@override String get versionsButton => 'Версии видео';
	@override String get pipButton => 'Режим «картинка в картинке»';
	@override String get aspectRatioButton => 'Соотношение сторон';
	@override String get ambientLighting => 'Фоновая подсветка';
	@override String get ambientLightingOn => 'Включить фоновую подсветку';
	@override String get ambientLightingOff => 'Выключить фоновую подсветку';
	@override String get fullscreenButton => 'Полноэкранный режим';
	@override String get exitFullscreenButton => 'Выйти из полноэкранного режима';
	@override String get alwaysOnTopButton => 'Всегда поверх';
	@override String get rotationLockButton => 'Блокировка поворота';
	@override String get timelineSlider => 'Временная шкала';
	@override String get volumeSlider => 'Уровень громкости';
	@override String endsAt({required Object time}) => 'Закончится в ${time}';
	@override String get pipActive => 'Воспроизводится в режиме «картинка в картинке»';
	@override String get pipFailed => 'Не удалось запустить режим «картинка в картинке»';
	@override late final _TranslationsVideoControlsPipErrorsRu pipErrors = _TranslationsVideoControlsPipErrorsRu._(_root);
	@override String get chapters => 'Главы';
	@override String get noChaptersAvailable => 'Главы недоступны';
	@override String get queue => 'Очередь';
	@override String get noQueueItems => 'В очереди нет элементов';
}

// Path: userStatus
class _TranslationsUserStatusRu implements TranslationsUserStatusEn {
	_TranslationsUserStatusRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Администратор';
	@override String get restricted => 'Ограниченный';
	@override String get protected => 'Защищённый';
	@override String get current => 'ТЕКУЩИЙ';
}

// Path: messages
class _TranslationsMessagesRu implements TranslationsMessagesEn {
	_TranslationsMessagesRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Отмечено как просмотренное';
	@override String get markedAsUnwatched => 'Отмечено как непросмотренное';
	@override String get markedAsWatchedOffline => 'Отмечено как просмотренное (синхронизируется при подключении)';
	@override String get markedAsUnwatchedOffline => 'Отмечено как непросмотренное (синхронизируется при подключении)';
	@override String get removedFromContinueWatching => 'Удалено из «Продолжить просмотр»';
	@override String errorLoading({required Object error}) => 'Ошибка: ${error}';
	@override String get fileInfoNotAvailable => 'Информация о файле недоступна';
	@override String errorLoadingFileInfo({required Object error}) => 'Ошибка загрузки информации о файле: ${error}';
	@override String get errorLoadingSeries => 'Ошибка загрузки сериала';
	@override String get errorLoadingSeason => 'Ошибка загрузки сезона';
	@override String get musicNotSupported => 'Воспроизведение музыки пока не поддерживается';
	@override String get logsCleared => 'Логи очищены';
	@override String get logsCopied => 'Логи скопированы в буфер обмена';
	@override String get noLogsAvailable => 'Логи отсутствуют';
	@override String libraryScanning({required Object title}) => 'Сканирование "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Сканирование библиотеки начато для "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Не удалось отсканировать библиотеку: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Обновление метаданных "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Обновление метаданных начато для "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Не удалось обновить метаданные: ${error}';
	@override String get logoutConfirm => 'Вы уверены, что хотите выйти?';
	@override String get noSeasonsFound => 'Сезоны не найдены';
	@override String get noEpisodesFound => 'Эпизоды в первом сезоне не найдены';
	@override String get noEpisodesFoundGeneral => 'Эпизоды не найдены';
	@override String get noResultsFound => 'Результаты не найдены';
	@override String sleepTimerSet({required Object label}) => 'Таймер сна установлен на ${label}';
	@override String get noItemsAvailable => 'Нет доступных элементов';
	@override String get failedToCreatePlayQueueNoItems => 'Не удалось создать очередь воспроизведения — нет элементов';
	@override String failedPlayback({required Object action, required Object error}) => 'Не удалось ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Переключение на совместимый плеер...';
	@override String get logsUploaded => 'Логи загружены';
	@override String get logsUploadFailed => 'Не удалось загрузить логи';
	@override String get logId => 'ID лога';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingRu implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Параметры стиля';
	@override String get fontSize => 'Размер шрифта';
	@override String get textColor => 'Цвет текста';
	@override String get borderSize => 'Размер обводки';
	@override String get borderColor => 'Цвет обводки';
	@override String get backgroundOpacity => 'Прозрачность фона';
	@override String get backgroundColor => 'Цвет фона';
	@override String get position => 'Позиция';
}

// Path: mpvConfig
class _TranslationsMpvConfigRu implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Расширенные настройки видеоплеера';
	@override String get presets => 'Пресеты';
	@override String get noPresets => 'Нет сохранённых пресетов';
	@override String get saveAsPreset => 'Сохранить как пресет...';
	@override String get presetName => 'Название пресета';
	@override String get presetNameHint => 'Введите название для пресета';
	@override String get loadPreset => 'Загрузить';
	@override String get deletePreset => 'Удалить';
	@override String get presetSaved => 'Пресет сохранён';
	@override String get presetLoaded => 'Пресет загружен';
	@override String get presetDeleted => 'Пресет удалён';
	@override String get confirmDeletePreset => 'Вы уверены, что хотите удалить этот пресет?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogRu implements TranslationsDialogEn {
	_TranslationsDialogRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Подтвердить действие';
}

// Path: discover
class _TranslationsDiscoverRu implements TranslationsDiscoverEn {
	_TranslationsDiscoverRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Обзор';
	@override String get switchProfile => 'Сменить профиль';
	@override String get noContentAvailable => 'Контент недоступен';
	@override String get addMediaToLibraries => 'Добавьте медиафайлы в ваши библиотеки';
	@override String get continueWatching => 'Продолжить просмотр';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Обзор';
	@override String get cast => 'В ролях';
	@override String get extras => 'Трейлеры и доп. материалы';
	@override String get seasons => 'Сезоны';
	@override String get studio => 'Студия';
	@override String get rating => 'Рейтинг';
	@override String episodeCount({required Object count}) => '${count} эпизодов';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} просмотрено';
	@override String get movie => 'Фильм';
	@override String get tvShow => 'Сериал';
	@override String minutesLeft({required Object minutes}) => 'Осталось ${minutes} мин';
}

// Path: errors
class _TranslationsErrorsRu implements TranslationsErrorsEn {
	_TranslationsErrorsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Ошибка поиска: ${error}';
	@override String connectionTimeout({required Object context}) => 'Таймаут подключения при загрузке ${context}';
	@override String get connectionFailed => 'Не удаётся подключиться к серверу Plex';
	@override String failedToLoad({required Object context, required Object error}) => 'Не удалось загрузить ${context}: ${error}';
	@override String get noClientAvailable => 'Клиент недоступен';
	@override String authenticationFailed({required Object error}) => 'Ошибка аутентификации: ${error}';
	@override String get couldNotLaunchUrl => 'Не удалось открыть URL аутентификации';
	@override String get pleaseEnterToken => 'Введите токен';
	@override String get invalidToken => 'Недействительный токен';
	@override String failedToVerifyToken({required Object error}) => 'Не удалось проверить токен: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Не удалось переключиться на ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesRu implements TranslationsLibrariesEn {
	_TranslationsLibrariesRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Библиотеки';
	@override String get scanLibraryFiles => 'Сканировать файлы библиотеки';
	@override String get scanLibrary => 'Сканировать библиотеку';
	@override String get analyze => 'Анализировать';
	@override String get analyzeLibrary => 'Анализировать библиотеку';
	@override String get refreshMetadata => 'Обновить метаданные';
	@override String get emptyTrash => 'Очистить корзину';
	@override String emptyingTrash({required Object title}) => 'Очистка корзины для "${title}"...';
	@override String trashEmptied({required Object title}) => 'Корзина очищена для "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Не удалось очистить корзину: ${error}';
	@override String analyzing({required Object title}) => 'Анализ "${title}"...';
	@override String analysisStarted({required Object title}) => 'Анализ начат для "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Не удалось проанализировать библиотеку: ${error}';
	@override String get noLibrariesFound => 'Библиотеки не найдены';
	@override String get thisLibraryIsEmpty => 'Эта библиотека пуста';
	@override String get all => 'Все';
	@override String get clearAll => 'Очистить все';
	@override String scanLibraryConfirm({required Object title}) => 'Вы уверены, что хотите сканировать "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Вы уверены, что хотите проанализировать "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Вы уверены, что хотите обновить метаданные для "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Вы уверены, что хотите очистить корзину для "${title}"?';
	@override String get manageLibraries => 'Управление библиотеками';
	@override String get sort => 'Сортировка';
	@override String get sortBy => 'Сортировать по';
	@override String get filters => 'Фильтры';
	@override String get confirmActionMessage => 'Вы уверены, что хотите выполнить это действие?';
	@override String get showLibrary => 'Показать библиотеку';
	@override String get hideLibrary => 'Скрыть библиотеку';
	@override String get libraryOptions => 'Параметры библиотеки';
	@override String get content => 'содержимое библиотеки';
	@override String get selectLibrary => 'Выбрать библиотеку';
	@override String filtersWithCount({required Object count}) => 'Фильтры (${count})';
	@override String get noRecommendations => 'Рекомендации недоступны';
	@override String get noCollections => 'В этой библиотеке нет коллекций';
	@override String get noFoldersFound => 'Папки не найдены';
	@override String get folders => 'папки';
	@override late final _TranslationsLibrariesTabsRu tabs = _TranslationsLibrariesTabsRu._(_root);
	@override late final _TranslationsLibrariesGroupingsRu groupings = _TranslationsLibrariesGroupingsRu._(_root);
}

// Path: about
class _TranslationsAboutRu implements TranslationsAboutEn {
	_TranslationsAboutRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'О приложении';
	@override String get openSourceLicenses => 'Лицензии открытого ПО';
	@override String versionLabel({required Object version}) => 'Версия ${version}';
	@override String get appDescription => 'Красивый клиент Plex на Flutter';
	@override String get viewLicensesDescription => 'Просмотр лицензий сторонних библиотек';
}

// Path: serverSelection
class _TranslationsServerSelectionRu implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Не удалось подключиться ни к одному серверу. Проверьте сеть и попробуйте снова.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Серверы не найдены для ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Не удалось загрузить серверы: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailRu implements TranslationsHubDetailEn {
	_TranslationsHubDetailRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Название';
	@override String get releaseYear => 'Год выпуска';
	@override String get dateAdded => 'Дата добавления';
	@override String get rating => 'Рейтинг';
	@override String get noItemsFound => 'Элементы не найдены';
}

// Path: logs
class _TranslationsLogsRu implements TranslationsLogsEn {
	_TranslationsLogsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Очистить логи';
	@override String get copyLogs => 'Скопировать логи';
	@override String get uploadLogs => 'Загрузить логи';
	@override String get error => 'Ошибка:';
	@override String get stackTrace => 'Стек вызовов:';
}

// Path: licenses
class _TranslationsLicensesRu implements TranslationsLicensesEn {
	_TranslationsLicensesRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Связанные пакеты';
	@override String get license => 'Лицензия';
	@override String licenseNumber({required Object number}) => 'Лицензия ${number}';
	@override String licensesCount({required Object count}) => '${count} лицензий';
}

// Path: navigation
class _TranslationsNavigationRu implements TranslationsNavigationEn {
	_TranslationsNavigationRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Библиотеки';
	@override String get downloads => 'Загрузки';
	@override String get liveTv => 'ТВ в прямом эфире';
}

// Path: liveTv
class _TranslationsLiveTvRu implements TranslationsLiveTvEn {
	_TranslationsLiveTvRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'ТВ в прямом эфире';
	@override String get channels => 'Каналы';
	@override String get guide => 'Программа';
	@override String get noChannels => 'Нет доступных каналов';
	@override String get noDvr => 'DVR не настроен ни на одном сервере';
	@override String get tuneFailed => 'Не удалось настроить канал';
	@override String get loading => 'Загрузка каналов...';
	@override String get nowPlaying => 'Сейчас воспроизводится';
	@override String get noPrograms => 'Нет данных о программах';
	@override String channelNumber({required Object number}) => 'Кн. ${number}';
	@override String get live => 'ЭФИР';
	@override String get hd => 'HD';
	@override String get premiere => 'НОВОЕ';
	@override String get reloadGuide => 'Перезагрузить программу';
	@override String get allChannels => 'Все каналы';
	@override String get now => 'Сейчас';
	@override String get today => 'Сегодня';
	@override String get midnight => 'Полночь';
	@override String get overnight => 'Ночь';
	@override String get morning => 'Утро';
	@override String get daytime => 'День';
	@override String get evening => 'Вечер';
	@override String get lateNight => 'Поздний вечер';
	@override String get whatsOn => 'Что идёт';
	@override String get watchChannel => 'Смотреть канал';
}

// Path: collections
class _TranslationsCollectionsRu implements TranslationsCollectionsEn {
	_TranslationsCollectionsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Коллекции';
	@override String get collection => 'Коллекция';
	@override String get empty => 'Коллекция пуста';
	@override String get unknownLibrarySection => 'Невозможно удалить: неизвестный раздел библиотеки';
	@override String get deleteCollection => 'Удалить коллекцию';
	@override String deleteConfirm({required Object title}) => 'Вы уверены, что хотите удалить "${title}"? Это действие нельзя отменить.';
	@override String get deleted => 'Коллекция удалена';
	@override String get deleteFailed => 'Не удалось удалить коллекцию';
	@override String deleteFailedWithError({required Object error}) => 'Не удалось удалить коллекцию: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Не удалось загрузить элементы коллекции: ${error}';
	@override String get selectCollection => 'Выбрать коллекцию';
	@override String get collectionName => 'Название коллекции';
	@override String get enterCollectionName => 'Введите название коллекции';
	@override String get addedToCollection => 'Добавлено в коллекцию';
	@override String get errorAddingToCollection => 'Не удалось добавить в коллекцию';
	@override String get created => 'Коллекция создана';
	@override String get removeFromCollection => 'Удалить из коллекции';
	@override String removeFromCollectionConfirm({required Object title}) => 'Удалить "${title}" из этой коллекции?';
	@override String get removedFromCollection => 'Удалено из коллекции';
	@override String get removeFromCollectionFailed => 'Не удалось удалить из коллекции';
	@override String removeFromCollectionError({required Object error}) => 'Ошибка удаления из коллекции: ${error}';
}

// Path: playlists
class _TranslationsPlaylistsRu implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Плейлисты';
	@override String get playlist => 'Плейлист';
	@override String get noPlaylists => 'Плейлисты не найдены';
	@override String get create => 'Создать плейлист';
	@override String get playlistName => 'Название плейлиста';
	@override String get enterPlaylistName => 'Введите название плейлиста';
	@override String get delete => 'Удалить плейлист';
	@override String get removeItem => 'Удалить из плейлиста';
	@override String get smartPlaylist => 'Умный плейлист';
	@override String itemCount({required Object count}) => '${count} элементов';
	@override String get oneItem => '1 элемент';
	@override String get emptyPlaylist => 'Этот плейлист пуст';
	@override String get deleteConfirm => 'Удалить плейлист?';
	@override String deleteMessage({required Object name}) => 'Вы уверены, что хотите удалить "${name}"?';
	@override String get created => 'Плейлист создан';
	@override String get deleted => 'Плейлист удалён';
	@override String get itemAdded => 'Добавлено в плейлист';
	@override String get itemRemoved => 'Удалено из плейлиста';
	@override String get selectPlaylist => 'Выбрать плейлист';
	@override String get errorCreating => 'Не удалось создать плейлист';
	@override String get errorDeleting => 'Не удалось удалить плейлист';
	@override String get errorLoading => 'Не удалось загрузить плейлисты';
	@override String get errorAdding => 'Не удалось добавить в плейлист';
	@override String get errorReordering => 'Не удалось переупорядочить элемент плейлиста';
	@override String get errorRemoving => 'Не удалось удалить из плейлиста';
}

// Path: watchTogether
class _TranslationsWatchTogetherRu implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Смотреть вместе';
	@override String get description => 'Смотрите контент синхронно с друзьями и семьёй';
	@override String get createSession => 'Создать сессию';
	@override String get creating => 'Создание...';
	@override String get joinSession => 'Присоединиться к сессии';
	@override String get joining => 'Подключение...';
	@override String get controlMode => 'Режим управления';
	@override String get controlModeQuestion => 'Кто может управлять воспроизведением?';
	@override String get hostOnly => 'Только хост';
	@override String get anyone => 'Все';
	@override String get hostingSession => 'Хостинг сессии';
	@override String get inSession => 'В сессии';
	@override String get sessionCode => 'Код сессии';
	@override String get hostControlsPlayback => 'Хост управляет воспроизведением';
	@override String get anyoneCanControl => 'Любой может управлять воспроизведением';
	@override String get hostControls => 'Управление хоста';
	@override String get anyoneControls => 'Управление для всех';
	@override String get participants => 'Участники';
	@override String get host => 'Хост';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Вы — хост';
	@override String get watchingWithOthers => 'Смотрите с другими';
	@override String get endSession => 'Завершить сессию';
	@override String get leaveSession => 'Покинуть сессию';
	@override String get endSessionQuestion => 'Завершить сессию?';
	@override String get leaveSessionQuestion => 'Покинуть сессию?';
	@override String get endSessionConfirm => 'Это завершит сессию для всех участников.';
	@override String get leaveSessionConfirm => 'Вы будете удалены из сессии.';
	@override String get endSessionConfirmOverlay => 'Это завершит сеанс просмотра для всех участников.';
	@override String get leaveSessionConfirmOverlay => 'Вы будете отключены от сеанса просмотра.';
	@override String get end => 'Завершить';
	@override String get leave => 'Покинуть';
	@override String get syncing => 'Синхронизация...';
	@override String get joinWatchSession => 'Присоединиться к просмотру';
	@override String get enterCodeHint => 'Введите 8-символьный код';
	@override String get pasteFromClipboard => 'Вставить из буфера обмена';
	@override String get pleaseEnterCode => 'Введите код сессии';
	@override String get codeMustBe8Chars => 'Код сессии должен содержать 8 символов';
	@override String get joinInstructions => 'Введите код сессии, предоставленный хостом, чтобы присоединиться к просмотру.';
	@override String get failedToCreate => 'Не удалось создать сессию';
	@override String get failedToJoin => 'Не удалось присоединиться к сессии';
	@override String get sessionCodeCopied => 'Код сессии скопирован в буфер обмена';
	@override String get relayUnreachable => 'Ретранслятор недоступен. Возможно, ваш провайдер блокирует подключение. Вы можете попробовать, но «Смотреть вместе» может не работать.';
	@override String get reconnectingToHost => 'Переподключение к хосту...';
	@override String get currentPlayback => 'Текущее воспроизведение';
	@override String get joinCurrentPlayback => 'Присоединиться к текущему воспроизведению';
	@override String get joinCurrentPlaybackDescription => 'Вернуться к тому, что сейчас смотрит хост';
	@override String get failedToOpenCurrentPlayback => 'Не удалось открыть текущее воспроизведение';
	@override String participantJoined({required Object name}) => '${name} присоединился';
	@override String participantLeft({required Object name}) => '${name} вышел';
}

// Path: downloads
class _TranslationsDownloadsRu implements TranslationsDownloadsEn {
	_TranslationsDownloadsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Загрузки';
	@override String get manage => 'Управление';
	@override String get tvShows => 'Сериалы';
	@override String get movies => 'Фильмы';
	@override String get noDownloads => 'Загрузок пока нет';
	@override String get noDownloadsDescription => 'Загруженный контент появится здесь для просмотра офлайн';
	@override String get downloadNow => 'Загрузить';
	@override String get deleteDownload => 'Удалить загрузку';
	@override String get retryDownload => 'Повторить загрузку';
	@override String get downloadQueued => 'Загрузка поставлена в очередь';
	@override String episodesQueued({required Object count}) => '${count} эпизодов поставлено в очередь загрузки';
	@override String get downloadDeleted => 'Загрузка удалена';
	@override String deleteConfirm({required Object title}) => 'Вы уверены, что хотите удалить "${title}"? Загруженный файл будет удалён с устройства.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Удаление ${title}... (${current} из ${total})';
	@override String get noDownloadsTree => 'Нет загрузок';
	@override String get pauseAll => 'Приостановить все';
	@override String get resumeAll => 'Возобновить все';
	@override String get deleteAll => 'Удалить все';
}

// Path: shaders
class _TranslationsShadersRu implements TranslationsShadersEn {
	_TranslationsShadersRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Шейдеры';
	@override String get noShaderDescription => 'Без улучшения видео';
	@override String get nvscalerDescription => 'Масштабирование NVIDIA для более чёткого видео';
	@override String get qualityFast => 'Быстрый';
	@override String get qualityHQ => 'Высокое качество';
	@override String get mode => 'Режим';
	@override String get importShader => 'Импортировать шейдер';
	@override String get customShaderDescription => 'Пользовательский GLSL шейдер';
	@override String get shaderImported => 'Шейдер импортирован';
	@override String get shaderImportFailed => 'Не удалось импортировать шейдер';
	@override String get deleteShader => 'Удалить шейдер';
	@override String deleteShaderConfirm({required Object name}) => 'Удалить "${name}"?';
}

// Path: companionRemote
class _TranslationsCompanionRemoteRu implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Пульт управления';
	@override String get connectToDevice => 'Подключиться к устройству';
	@override String get hostRemoteSession => 'Создать удалённую сессию';
	@override String get controlThisDevice => 'Управляйте этим устройством с телефона';
	@override String get remoteControl => 'Пульт управления';
	@override String get controlDesktop => 'Управлять десктопным устройством';
	@override String connectedTo({required Object name}) => 'Подключено к ${name}';
	@override late final _TranslationsCompanionRemoteSessionRu session = _TranslationsCompanionRemoteSessionRu._(_root);
	@override late final _TranslationsCompanionRemotePairingRu pairing = _TranslationsCompanionRemotePairingRu._(_root);
	@override late final _TranslationsCompanionRemoteRemoteRu remote = _TranslationsCompanionRemoteRemoteRu._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsRu implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Настройки воспроизведения';
	@override String get playbackSpeed => 'Скорость воспроизведения';
	@override String get sleepTimer => 'Таймер сна';
	@override String get audioSync => 'Синхронизация аудио';
	@override String get subtitleSync => 'Синхронизация субтитров';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Аудиовыход';
	@override String get performanceOverlay => 'Оверлей производительности';
	@override String get audioPassthrough => 'Сквозной вывод аудио';
	@override String get audioNormalization => 'Нормализация аудио';
}

// Path: externalPlayer
class _TranslationsExternalPlayerRu implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Внешний плеер';
	@override String get useExternalPlayer => 'Использовать внешний плеер';
	@override String get useExternalPlayerDescription => 'Открывать видео во внешнем приложении вместо встроенного плеера';
	@override String get selectPlayer => 'Выбрать плеер';
	@override String get systemDefault => 'Системный по умолчанию';
	@override String get addCustomPlayer => 'Добавить свой плеер';
	@override String get playerName => 'Название плеера';
	@override String get playerCommand => 'Команда';
	@override String get playerPackage => 'Имя пакета';
	@override String get playerUrlScheme => 'URL-схема';
	@override String get customPlayer => 'Свой плеер';
	@override String get off => 'Выкл.';
	@override String get launchFailed => 'Не удалось открыть внешний плеер';
	@override String appNotInstalled({required Object name}) => '${name} не установлен';
	@override String get playInExternalPlayer => 'Воспроизвести во внешнем плеере';
}

// Path: metadataEdit
class _TranslationsMetadataEditRu implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Редактировать...';
	@override String get screenTitle => 'Редактировать метаданные';
	@override String get basicInfo => 'Основная информация';
	@override String get artwork => 'Обложка';
	@override String get advancedSettings => 'Дополнительные настройки';
	@override String get title => 'Название';
	@override String get sortTitle => 'Название для сортировки';
	@override String get originalTitle => 'Оригинальное название';
	@override String get releaseDate => 'Дата выпуска';
	@override String get contentRating => 'Возрастной рейтинг';
	@override String get studio => 'Студия';
	@override String get tagline => 'Слоган';
	@override String get summary => 'Описание';
	@override String get poster => 'Постер';
	@override String get background => 'Фон';
	@override String get selectPoster => 'Выбрать постер';
	@override String get selectBackground => 'Выбрать фон';
	@override String get fromUrl => 'По URL';
	@override String get uploadFile => 'Загрузить файл';
	@override String get enterImageUrl => 'Введите URL изображения';
	@override String get imageUrl => 'URL изображения';
	@override String get metadataUpdated => 'Метаданные обновлены';
	@override String get metadataUpdateFailed => 'Не удалось обновить метаданные';
	@override String get artworkUpdated => 'Обложка обновлена';
	@override String get artworkUpdateFailed => 'Не удалось обновить обложку';
	@override String get noArtworkAvailable => 'Обложки недоступны';
	@override String get notSet => 'Не задано';
	@override String get libraryDefault => 'По умолчанию библиотеки';
	@override String get accountDefault => 'По умолчанию аккаунта';
	@override String get seriesDefault => 'По умолчанию сериала';
	@override String get episodeSorting => 'Сортировка эпизодов';
	@override String get oldestFirst => 'Сначала старые';
	@override String get newestFirst => 'Сначала новые';
	@override String get keep => 'Сохранять';
	@override String get allEpisodes => 'Все эпизоды';
	@override String latestEpisodes({required Object count}) => '${count} последних эпизодов';
	@override String get latestEpisode => 'Последний эпизод';
	@override String episodesAddedPastDays({required Object count}) => 'Эпизоды, добавленные за последние ${count} дней';
	@override String get deleteAfterPlaying => 'Удалять эпизоды после просмотра';
	@override String get never => 'Никогда';
	@override String get afterADay => 'Через день';
	@override String get afterAWeek => 'Через неделю';
	@override String get afterAMonth => 'Через месяц';
	@override String get onNextRefresh => 'При следующем обновлении';
	@override String get seasons => 'Сезоны';
	@override String get show => 'Показать';
	@override String get hide => 'Скрыть';
	@override String get episodeOrdering => 'Порядок эпизодов';
	@override String get tmdbAiring => 'The Movie Database (Эфирный)';
	@override String get tvdbAiring => 'TheTVDB (Эфирный)';
	@override String get tvdbAbsolute => 'TheTVDB (Абсолютный)';
	@override String get metadataLanguage => 'Язык метаданных';
	@override String get useOriginalTitle => 'Использовать оригинальное название';
	@override String get preferredAudioLanguage => 'Предпочитаемый язык аудио';
	@override String get preferredSubtitleLanguage => 'Предпочитаемый язык субтитров';
	@override String get subtitleMode => 'Автовыбор субтитров';
	@override String get manuallySelected => 'Выбор вручную';
	@override String get shownWithForeignAudio => 'Показывать при иноязычном аудио';
	@override String get alwaysEnabled => 'Всегда включены';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsRu implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Воспроизведение/Пауза';
	@override String get volumeUp => 'Громкость выше';
	@override String get volumeDown => 'Громкость ниже';
	@override String seekForward({required Object seconds}) => 'Перемотка вперёд (${seconds}с)';
	@override String seekBackward({required Object seconds}) => 'Перемотка назад (${seconds}с)';
	@override String get fullscreenToggle => 'Полноэкранный режим';
	@override String get muteToggle => 'Вкл./выкл. звук';
	@override String get subtitleToggle => 'Вкл./выкл. субтитры';
	@override String get audioTrackNext => 'Следующая аудиодорожка';
	@override String get subtitleTrackNext => 'Следующая дорожка субтитров';
	@override String get chapterNext => 'Следующая глава';
	@override String get chapterPrevious => 'Предыдущая глава';
	@override String get speedIncrease => 'Увеличить скорость';
	@override String get speedDecrease => 'Уменьшить скорость';
	@override String get speedReset => 'Сбросить скорость';
	@override String get subSeekNext => 'К следующему субтитру';
	@override String get subSeekPrev => 'К предыдущему субтитру';
	@override String get shaderToggle => 'Вкл./выкл. шейдеры';
	@override String get skipMarker => 'Пропустить вступление/титры';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsRu implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Требуется Android 8.0 или новее';
	@override String get iosVersion => 'Требуется iOS 15.0 или новее';
	@override String get permissionDisabled => 'Разрешение «картинка в картинке» отключено. Включите в Настройки > Приложения > Plezy > Картинка в картинке';
	@override String get notSupported => 'Устройство не поддерживает режим «картинка в картинке»';
	@override String get voSwitchFailed => 'Не удалось переключить видеовыход для «картинки в картинке»';
	@override String get failed => 'Не удалось запустить режим «картинка в картинке»';
	@override String unknown({required Object error}) => 'Произошла ошибка: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsRu implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Рекомендуемые';
	@override String get browse => 'Обзор';
	@override String get collections => 'Коллекции';
	@override String get playlists => 'Плейлисты';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsRu implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get all => 'Все';
	@override String get movies => 'Фильмы';
	@override String get shows => 'Сериалы';
	@override String get seasons => 'Сезоны';
	@override String get episodes => 'Эпизоды';
	@override String get folders => 'Папки';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionRu implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => 'Создание удалённой сессии...';
	@override String get failedToCreate => 'Не удалось создать удалённую сессию:';
	@override String get noSession => 'Нет доступных сессий';
	@override String get scanQrCode => 'Сканировать QR-код';
	@override String get orEnterManually => 'Или введите вручную';
	@override String get hostAddress => 'Адрес хоста';
	@override String get sessionId => 'ID сессии';
	@override String get pin => 'PIN';
	@override String get connected => 'Подключено';
	@override String get waitingForConnection => 'Ожидание подключения...';
	@override String get usePhoneToControl => 'Используйте мобильное устройство для управления этим приложением';
	@override String copiedToClipboard({required Object label}) => '${label} скопировано в буфер обмена';
	@override String get copyToClipboard => 'Скопировать в буфер обмена';
	@override String get newSession => 'Новая сессия';
	@override String get minimize => 'Свернуть';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingRu implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get scan => 'Сканировать';
	@override String get manual => 'Вручную';
	@override String get pairWithDesktop => 'Сопряжение с ПК';
	@override String get enterSessionDetails => 'Введите данные сессии, показанные на десктопном устройстве';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => 'Введите 8-символьный ID сессии';
	@override String get pinHint => 'Введите 6-значный PIN';
	@override String get connecting => 'Подключение...';
	@override String get tips => 'Советы';
	@override String get tipDesktop => 'Откройте Plezy на десктопе и включите пульт управления в настройках или меню';
	@override String get tipScan => 'Используйте вкладку «Сканировать» для быстрого сопряжения через QR-код на десктопе';
	@override String get tipWifi => 'Убедитесь, что оба устройства находятся в одной WiFi-сети';
	@override String get cameraPermissionRequired => 'Для сканирования QR-кодов требуется разрешение на камеру.\nПредоставьте доступ к камере в настройках устройства.';
	@override String cameraError({required Object error}) => 'Не удалось запустить камеру: ${error}';
	@override String get scanInstruction => 'Наведите камеру на QR-код, показанный на десктопе';
	@override String get invalidQrCode => 'Недопустимый формат QR-кода';
	@override String get validationHostRequired => 'Введите адрес хоста';
	@override String get validationHostFormat => 'Формат должен быть IP:порт (например, 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => 'Введите ID сессии';
	@override String get validationSessionIdLength => 'ID сессии должен содержать 8 символов';
	@override String get validationPinRequired => 'Введите PIN';
	@override String get validationPinLength => 'PIN должен содержать 6 цифр';
	@override String get connectionTimedOut => 'Время подключения истекло. Проверьте ID сессии и PIN.';
	@override String get sessionNotFound => 'Сессия не найдена. Проверьте ваши учётные данные.';
	@override String failedToConnect({required Object error}) => 'Не удалось подключиться: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteRu implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteRu._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Отключиться от удалённой сессии?';
	@override String get reconnecting => 'Переподключение...';
	@override String attemptOf({required Object current}) => 'Попытка ${current} из 5';
	@override String get retryNow => 'Повторить сейчас';
	@override String get connectionError => 'Ошибка подключения';
	@override String get notConnected => 'Не подключено';
	@override String get tabRemote => 'Пульт';
	@override String get tabPlay => 'Воспроизведение';
	@override String get tabMore => 'Ещё';
	@override String get menu => 'Меню';
	@override String get tabNavigation => 'Навигация';
	@override String get tabDiscover => 'Обзор';
	@override String get tabLibraries => 'Библиотеки';
	@override String get tabSearch => 'Поиск';
	@override String get tabDownloads => 'Загрузки';
	@override String get tabSettings => 'Настройки';
	@override String get previous => 'Предыдущий';
	@override String get playPause => 'Воспроизведение/Пауза';
	@override String get next => 'Следующий';
	@override String get seekBack => 'Назад';
	@override String get stop => 'Стоп';
	@override String get seekForward => 'Вперёд';
	@override String get volume => 'Громкость';
	@override String get volumeDown => 'Тише';
	@override String get volumeUp => 'Громче';
	@override String get fullscreen => 'Полноэкранный';
	@override String get subtitles => 'Субтитры';
	@override String get audio => 'Аудио';
	@override String get searchHint => 'Поиск на десктопе...';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Войти через Plex',
			'auth.showQRCode' => 'Показать QR-код',
			'auth.authenticate' => 'Аутентификация',
			'auth.debugEnterToken' => 'Отладка: Ввести токен Plex',
			'auth.plexTokenLabel' => 'Токен авторизации Plex',
			'auth.plexTokenHint' => 'Введите ваш токен Plex.tv',
			'auth.authenticationTimeout' => 'Время аутентификации истекло. Попробуйте снова.',
			'auth.scanQRToSignIn' => 'Отсканируйте QR-код для входа',
			'auth.waitingForAuth' => 'Ожидание аутентификации...\nЗавершите вход в браузере.',
			'auth.useBrowser' => 'Использовать браузер',
			'common.cancel' => 'Отмена',
			'common.save' => 'Сохранить',
			'common.close' => 'Закрыть',
			'common.clear' => 'Очистить',
			'common.reset' => 'Сбросить',
			'common.later' => 'Позже',
			'common.submit' => 'Отправить',
			'common.confirm' => 'Подтвердить',
			'common.retry' => 'Повторить',
			'common.logout' => 'Выйти',
			'common.unknown' => 'Неизвестно',
			'common.refresh' => 'Обновить',
			'common.yes' => 'Да',
			'common.no' => 'Нет',
			'common.delete' => 'Удалить',
			'common.shuffle' => 'Перемешать',
			'common.addTo' => 'Добавить в...',
			'common.createNew' => 'Создать новый',
			'common.remove' => 'Удалить',
			'common.paste' => 'Вставить',
			'common.connect' => 'Подключить',
			'common.disconnect' => 'Отключить',
			'common.play' => 'Воспроизвести',
			'common.pause' => 'Пауза',
			'common.resume' => 'Продолжить',
			'common.error' => 'Ошибка',
			'common.search' => 'Поиск',
			'common.home' => 'Главная',
			'common.back' => 'Назад',
			'common.settings' => 'Настройки',
			'common.mute' => 'Без звука',
			'common.ok' => 'OK',
			'common.loading' => 'Загрузка...',
			'common.reconnect' => 'Переподключить',
			'common.exitConfirmTitle' => 'Выйти из приложения?',
			'common.exitConfirmMessage' => 'Вы уверены, что хотите выйти?',
			'common.dontAskAgain' => 'Больше не спрашивать',
			'common.exit' => 'Выход',
			'common.viewAll' => 'Показать все',
			'common.checkingNetwork' => 'Проверка сети...',
			'common.refreshingServers' => 'Обновление серверов...',
			'common.loadingServers' => 'Загрузка серверов...',
			'common.connectingToServers' => 'Подключение к серверам...',
			'common.startingOfflineMode' => 'Запуск автономного режима...',
			'screens.licenses' => 'Лицензии',
			'screens.switchProfile' => 'Сменить профиль',
			'screens.subtitleStyling' => 'Стиль субтитров',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Логи',
			'update.available' => 'Доступно обновление',
			'update.versionAvailable' => ({required Object version}) => 'Доступна версия ${version}',
			'update.currentVersion' => ({required Object version}) => 'Текущая: ${version}',
			'update.skipVersion' => 'Пропустить эту версию',
			'update.viewRelease' => 'Посмотреть релиз',
			'update.latestVersion' => 'У вас последняя версия',
			'update.checkFailed' => 'Не удалось проверить обновления',
			'settings.title' => 'Настройки',
			'settings.language' => 'Язык',
			'settings.theme' => 'Тема',
			'settings.appearance' => 'Внешний вид',
			'settings.videoPlayback' => 'Воспроизведение видео',
			'settings.advanced' => 'Дополнительно',
			'settings.episodePosterMode' => 'Стиль постера эпизода',
			'settings.seriesPoster' => 'Постер сериала',
			'settings.seriesPosterDescription' => 'Показывать постер сериала для всех эпизодов',
			'settings.seasonPoster' => 'Постер сезона',
			'settings.seasonPosterDescription' => 'Показывать постер конкретного сезона для эпизодов',
			'settings.episodeThumbnail' => 'Миниатюра эпизода',
			'settings.episodeThumbnailDescription' => 'Показывать миниатюры скриншотов эпизодов 16:9',
			'settings.showHeroSectionDescription' => 'Показывать карусель избранного контента на главном экране',
			'settings.secondsLabel' => 'Секунды',
			'settings.minutesLabel' => 'Минуты',
			'settings.secondsShort' => 'с',
			'settings.minutesShort' => 'м',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Введите длительность (${min}-${max})',
			'settings.systemTheme' => 'Системная',
			'settings.systemThemeDescription' => 'Следовать настройкам системы',
			'settings.lightTheme' => 'Светлая',
			'settings.darkTheme' => 'Тёмная',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Чистый чёрный для OLED-экранов',
			'settings.libraryDensity' => 'Плотность библиотеки',
			'settings.compact' => 'Компактный',
			'settings.compactDescription' => 'Меньшие карточки, больше элементов видно',
			'settings.normal' => 'Обычный',
			'settings.normalDescription' => 'Размер по умолчанию',
			'settings.comfortable' => 'Комфортный',
			'settings.comfortableDescription' => 'Большие карточки, меньше элементов видно',
			'settings.viewMode' => 'Режим просмотра',
			'settings.gridView' => 'Сетка',
			'settings.gridViewDescription' => 'Отображать элементы в виде сетки',
			'settings.listView' => 'Список',
			'settings.listViewDescription' => 'Отображать элементы в виде списка',
			'settings.showHeroSection' => 'Показать раздел избранного',
			'settings.useGlobalHubs' => 'Использовать макет Plex Home',
			'settings.useGlobalHubsDescription' => 'Показывать хабы главной страницы как в официальном клиенте Plex. При выключении показывает рекомендации по библиотекам.',
			'settings.showServerNameOnHubs' => 'Показывать имя сервера в хабах',
			'settings.showServerNameOnHubsDescription' => 'Всегда показывать имя сервера в заголовках хабов. При выключении показывает только для дублирующихся имён.',
			'settings.alwaysKeepSidebarOpen' => 'Всегда держать боковую панель открытой',
			'settings.alwaysKeepSidebarOpenDescription' => 'Боковая панель остаётся развёрнутой, область контента подстраивается',
			'settings.showUnwatchedCount' => 'Показывать количество непросмотренных',
			'settings.showUnwatchedCountDescription' => 'Отображать количество непросмотренных эпизодов для сериалов и сезонов',
			'settings.hideSpoilers' => 'Скрыть спойлеры непросмотренных эпизодов',
			'settings.hideSpoilersDescription' => 'Размывать миниатюры и скрывать описания эпизодов, которые вы ещё не смотрели',
			'settings.playerBackend' => 'Бэкенд плеера',
			'settings.exoPlayer' => 'ExoPlayer (Рекомендуется)',
			'settings.exoPlayerDescription' => 'Нативный Android-плеер с лучшей аппаратной поддержкой',
			'settings.mpv' => 'mpv',
			'settings.mpvDescription' => 'Продвинутый плеер с большим количеством функций и поддержкой субтитров ASS',
			'settings.hardwareDecoding' => 'Аппаратное декодирование',
			'settings.hardwareDecodingDescription' => 'Использовать аппаратное ускорение, когда доступно',
			'settings.bufferSize' => 'Размер буфера',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}МБ',
			'settings.bufferSizeAuto' => 'Авто (Рекомендуется)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'У вашего устройства ${heap}МБ памяти. Буфер ${size}МБ может вызвать проблемы с воспроизведением.',
			'settings.subtitleStyling' => 'Стиль субтитров',
			'settings.subtitleStylingDescription' => 'Настроить внешний вид субтитров',
			'settings.smallSkipDuration' => 'Малая перемотка',
			'settings.largeSkipDuration' => 'Большая перемотка',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} секунд',
			'settings.defaultSleepTimer' => 'Таймер сна по умолчанию',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} минут',
			'settings.rememberTrackSelections' => 'Запоминать выбор дорожек для каждого сериала/фильма',
			'settings.rememberTrackSelectionsDescription' => 'Автоматически сохранять предпочтения языка аудио и субтитров при переключении дорожек во время воспроизведения',
			'settings.clickVideoTogglesPlayback' => 'Клик по видео для переключения воспроизведения/паузы',
			'settings.clickVideoTogglesPlaybackDescription' => 'Если включено, клик по видеоплееру воспроизводит/ставит на паузу. В противном случае показывает/скрывает элементы управления.',
			'settings.videoPlayerControls' => 'Элементы управления плеером',
			'settings.keyboardShortcuts' => 'Горячие клавиши',
			'settings.keyboardShortcutsDescription' => 'Настроить горячие клавиши',
			'settings.videoPlayerNavigation' => 'Навигация видеоплеера',
			'settings.videoPlayerNavigationDescription' => 'Использовать клавиши стрелок для навигации по элементам управления плеером',
			'settings.crashReporting' => 'Отчёты об ошибках',
			'settings.crashReportingDescription' => 'Отправлять отчёты об ошибках для улучшения приложения',
			'settings.debugLogging' => 'Журнал отладки',
			'settings.debugLoggingDescription' => 'Включить подробное журналирование для устранения неполадок',
			'settings.viewLogs' => 'Просмотр логов',
			'settings.viewLogsDescription' => 'Просмотр логов приложения',
			'settings.clearCache' => 'Очистить кэш',
			'settings.clearCacheDescription' => 'Это удалит все кэшированные изображения и данные. После очистки кэша приложение может загружать контент дольше.',
			'settings.clearCacheSuccess' => 'Кэш успешно очищен',
			'settings.resetSettings' => 'Сбросить настройки',
			'settings.resetSettingsDescription' => 'Все настройки будут сброшены до значений по умолчанию. Это действие нельзя отменить.',
			'settings.resetSettingsSuccess' => 'Настройки успешно сброшены',
			'settings.shortcutsReset' => 'Горячие клавиши сброшены по умолчанию',
			'settings.about' => 'О приложении',
			'settings.aboutDescription' => 'Информация о приложении и лицензии',
			'settings.updates' => 'Обновления',
			'settings.updateAvailable' => 'Доступно обновление',
			'settings.checkForUpdates' => 'Проверить обновления',
			'settings.validationErrorEnterNumber' => 'Введите корректное число',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Длительность должна быть от ${min} до ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Клавиша уже назначена для ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Клавиша обновлена для ${action}',
			'settings.autoSkip' => 'Автопропуск',
			'settings.autoSkipIntro' => 'Автопропуск вступления',
			'settings.autoSkipIntroDescription' => 'Автоматически пропускать маркеры вступления через несколько секунд',
			'settings.autoSkipCredits' => 'Автопропуск титров',
			'settings.autoSkipCreditsDescription' => 'Автоматически пропускать титры и воспроизводить следующий эпизод',
			'settings.autoSkipDelay' => 'Задержка автопропуска',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Подождать ${seconds} секунд перед автопропуском',
			'settings.downloads' => 'Загрузки',
			'settings.downloadLocationDescription' => 'Выберите место для хранения загруженного контента',
			'settings.downloadLocationDefault' => 'По умолчанию (Хранилище приложения)',
			'settings.downloadLocationCustom' => 'Другое расположение',
			'settings.selectFolder' => 'Выбрать папку',
			'settings.resetToDefault' => 'Сбросить по умолчанию',
			'settings.currentPath' => ({required Object path}) => 'Текущий: ${path}',
			'settings.downloadLocationChanged' => 'Место загрузки изменено',
			'settings.downloadLocationReset' => 'Место загрузки сброшено по умолчанию',
			'settings.downloadLocationInvalid' => 'Выбранная папка недоступна для записи',
			'settings.downloadLocationSelectError' => 'Не удалось выбрать папку',
			'settings.downloadOnWifiOnly' => 'Загружать только по WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Запретить загрузку по мобильным данным',
			'settings.cellularDownloadBlocked' => 'Загрузка по мобильным данным отключена. Подключитесь к WiFi или измените настройку.',
			'settings.maxVolume' => 'Максимальная громкость',
			'settings.maxVolumeDescription' => 'Разрешить усиление громкости выше 100% для тихих медиа',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Показывать, что вы смотрите, в Discord',
			'settings.autoPip' => 'Автоматический «картинка в картинке»',
			'settings.autoPipDescription' => 'Автоматически переходить в режим «картинка в картинке» при выходе из приложения во время воспроизведения',
			'settings.matchContentFrameRate' => 'Соответствие частоты кадров контента',
			'settings.matchContentFrameRateDescription' => 'Настроить частоту обновления дисплея под видеоконтент, уменьшая дрожание и экономя батарею',
			'settings.tunneledPlayback' => 'Туннельное воспроизведение',
			'settings.tunneledPlaybackDescription' => 'Использовать аппаратный видеотуннелинг. Отключите, если видите чёрный экран со звуком при HDR-контенте',
			'settings.requireProfileSelectionOnOpen' => 'Запрашивать профиль при запуске',
			'settings.requireProfileSelectionOnOpenDescription' => 'Показывать выбор профиля при каждом открытии приложения',
			'settings.confirmExitOnBack' => 'Подтверждать выход',
			'settings.confirmExitOnBackDescription' => 'Показывать диалог подтверждения при нажатии «назад» для выхода из приложения',
			'settings.showNavBarLabels' => 'Показывать подписи панели навигации',
			'settings.showNavBarLabelsDescription' => 'Отображать текстовые подписи под иконками панели навигации',
			'search.hint' => 'Поиск фильмов, сериалов, музыки...',
			'search.tryDifferentTerm' => 'Попробуйте другой запрос',
			'search.searchYourMedia' => 'Поиск в вашей медиатеке',
			'search.enterTitleActorOrKeyword' => 'Введите название, актёра или ключевое слово',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Назначить клавишу для ${actionName}',
			'hotkeys.clearShortcut' => 'Очистить клавишу',
			'hotkeys.actions.playPause' => 'Воспроизведение/Пауза',
			'hotkeys.actions.volumeUp' => 'Громкость выше',
			'hotkeys.actions.volumeDown' => 'Громкость ниже',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Перемотка вперёд (${seconds}с)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Перемотка назад (${seconds}с)',
			'hotkeys.actions.fullscreenToggle' => 'Полноэкранный режим',
			'hotkeys.actions.muteToggle' => 'Вкл./выкл. звук',
			'hotkeys.actions.subtitleToggle' => 'Вкл./выкл. субтитры',
			'hotkeys.actions.audioTrackNext' => 'Следующая аудиодорожка',
			'hotkeys.actions.subtitleTrackNext' => 'Следующая дорожка субтитров',
			'hotkeys.actions.chapterNext' => 'Следующая глава',
			'hotkeys.actions.chapterPrevious' => 'Предыдущая глава',
			'hotkeys.actions.speedIncrease' => 'Увеличить скорость',
			'hotkeys.actions.speedDecrease' => 'Уменьшить скорость',
			'hotkeys.actions.speedReset' => 'Сбросить скорость',
			'hotkeys.actions.subSeekNext' => 'К следующему субтитру',
			'hotkeys.actions.subSeekPrev' => 'К предыдущему субтитру',
			'hotkeys.actions.shaderToggle' => 'Вкл./выкл. шейдеры',
			'hotkeys.actions.skipMarker' => 'Пропустить вступление/титры',
			'pinEntry.enterPin' => 'Введите PIN',
			'pinEntry.showPin' => 'Показать PIN',
			'pinEntry.hidePin' => 'Скрыть PIN',
			'fileInfo.title' => 'Информация о файле',
			'fileInfo.video' => 'Видео',
			'fileInfo.audio' => 'Аудио',
			'fileInfo.file' => 'Файл',
			'fileInfo.advanced' => 'Дополнительно',
			'fileInfo.codec' => 'Кодек',
			'fileInfo.resolution' => 'Разрешение',
			'fileInfo.bitrate' => 'Битрейт',
			'fileInfo.frameRate' => 'Частота кадров',
			'fileInfo.aspectRatio' => 'Соотношение сторон',
			'fileInfo.profile' => 'Профиль',
			'fileInfo.bitDepth' => 'Глубина цвета',
			'fileInfo.colorSpace' => 'Цветовое пространство',
			'fileInfo.colorRange' => 'Цветовой диапазон',
			'fileInfo.colorPrimaries' => 'Цветовые первичные',
			'fileInfo.chromaSubsampling' => 'Субдискретизация цветности',
			'fileInfo.channels' => 'Каналы',
			'fileInfo.path' => 'Путь',
			'fileInfo.size' => 'Размер',
			'fileInfo.container' => 'Контейнер',
			'fileInfo.duration' => 'Длительность',
			'fileInfo.optimizedForStreaming' => 'Оптимизировано для стриминга',
			'fileInfo.has64bitOffsets' => '64-битные смещения',
			'mediaMenu.markAsWatched' => 'Отметить как просмотренное',
			'mediaMenu.markAsUnwatched' => 'Отметить как непросмотренное',
			'mediaMenu.removeFromContinueWatching' => 'Удалить из «Продолжить просмотр»',
			'mediaMenu.goToSeries' => 'Перейти к сериалу',
			'mediaMenu.goToSeason' => 'Перейти к сезону',
			'mediaMenu.shufflePlay' => 'Случайное воспроизведение',
			'mediaMenu.fileInfo' => 'Информация о файле',
			'mediaMenu.deleteFromServer' => 'Удалить с сервера',
			'mediaMenu.confirmDelete' => 'Это навсегда удалит этот медиафайл и его файлы с вашего сервера. Это действие нельзя отменить.',
			'mediaMenu.deleteMultipleWarning' => 'Это включает все эпизоды и их файлы.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Медиаэлемент успешно удалён',
			'mediaMenu.mediaFailedToDelete' => 'Не удалось удалить медиаэлемент',
			'mediaMenu.rate' => 'Оценить',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, фильм',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, сериал',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'просмотрено',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => 'просмотрено ${percent} процентов',
			'accessibility.mediaCardUnwatched' => 'не просмотрено',
			'accessibility.tapToPlay' => 'Нажмите для воспроизведения',
			'tooltips.shufflePlay' => 'Случайное воспроизведение',
			'tooltips.playTrailer' => 'Воспроизвести трейлер',
			'tooltips.markAsWatched' => 'Отметить как просмотренное',
			'tooltips.markAsUnwatched' => 'Отметить как непросмотренное',
			'videoControls.audioLabel' => 'Аудио',
			'videoControls.subtitlesLabel' => 'Субтитры',
			'videoControls.resetToZero' => 'Сбросить до 0мс',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} воспроизводится позже',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} воспроизводится раньше',
			'videoControls.noOffset' => 'Без смещения',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Заполнить экран',
			'videoControls.stretch' => 'Растянуть',
			'videoControls.lockRotation' => 'Заблокировать поворот',
			'videoControls.unlockRotation' => 'Разблокировать поворот',
			'videoControls.timerActive' => 'Таймер активен',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Воспроизведение будет приостановлено через ${duration}',
			'videoControls.sleepTimerCompleted' => 'Таймер сна завершён — воспроизведение приостановлено',
			'videoControls.stillWatching' => 'Всё ещё смотрите?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Пауза через ${seconds}с',
			'videoControls.continueWatching' => 'Продолжить',
			'videoControls.autoPlayNext' => 'Автовоспроизведение следующего',
			'videoControls.playNext' => 'Следующее',
			'videoControls.playButton' => 'Воспроизвести',
			'videoControls.pauseButton' => 'Пауза',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Перемотка назад на ${seconds} секунд',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Перемотка вперёд на ${seconds} секунд',
			'videoControls.previousButton' => 'Предыдущий эпизод',
			'videoControls.nextButton' => 'Следующий эпизод',
			'videoControls.previousChapterButton' => 'Предыдущая глава',
			'videoControls.nextChapterButton' => 'Следующая глава',
			'videoControls.muteButton' => 'Без звука',
			'videoControls.unmuteButton' => 'Включить звук',
			'videoControls.settingsButton' => 'Настройки видео',
			'videoControls.audioTrackButton' => 'Аудиодорожки',
			'videoControls.subtitlesButton' => 'Субтитры',
			'videoControls.tracksButton' => 'Аудио и субтитры',
			'videoControls.chaptersButton' => 'Главы',
			'videoControls.versionsButton' => 'Версии видео',
			'videoControls.pipButton' => 'Режим «картинка в картинке»',
			'videoControls.aspectRatioButton' => 'Соотношение сторон',
			'videoControls.ambientLighting' => 'Фоновая подсветка',
			'videoControls.ambientLightingOn' => 'Включить фоновую подсветку',
			'videoControls.ambientLightingOff' => 'Выключить фоновую подсветку',
			'videoControls.fullscreenButton' => 'Полноэкранный режим',
			'videoControls.exitFullscreenButton' => 'Выйти из полноэкранного режима',
			'videoControls.alwaysOnTopButton' => 'Всегда поверх',
			'videoControls.rotationLockButton' => 'Блокировка поворота',
			'videoControls.timelineSlider' => 'Временная шкала',
			'videoControls.volumeSlider' => 'Уровень громкости',
			'videoControls.endsAt' => ({required Object time}) => 'Закончится в ${time}',
			'videoControls.pipActive' => 'Воспроизводится в режиме «картинка в картинке»',
			'videoControls.pipFailed' => 'Не удалось запустить режим «картинка в картинке»',
			'videoControls.pipErrors.androidVersion' => 'Требуется Android 8.0 или новее',
			'videoControls.pipErrors.iosVersion' => 'Требуется iOS 15.0 или новее',
			'videoControls.pipErrors.permissionDisabled' => 'Разрешение «картинка в картинке» отключено. Включите в Настройки > Приложения > Plezy > Картинка в картинке',
			'videoControls.pipErrors.notSupported' => 'Устройство не поддерживает режим «картинка в картинке»',
			'videoControls.pipErrors.voSwitchFailed' => 'Не удалось переключить видеовыход для «картинки в картинке»',
			'videoControls.pipErrors.failed' => 'Не удалось запустить режим «картинка в картинке»',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Произошла ошибка: ${error}',
			'videoControls.chapters' => 'Главы',
			'videoControls.noChaptersAvailable' => 'Главы недоступны',
			'videoControls.queue' => 'Очередь',
			'videoControls.noQueueItems' => 'В очереди нет элементов',
			'userStatus.admin' => 'Администратор',
			'userStatus.restricted' => 'Ограниченный',
			'userStatus.protected' => 'Защищённый',
			'userStatus.current' => 'ТЕКУЩИЙ',
			'messages.markedAsWatched' => 'Отмечено как просмотренное',
			'messages.markedAsUnwatched' => 'Отмечено как непросмотренное',
			'messages.markedAsWatchedOffline' => 'Отмечено как просмотренное (синхронизируется при подключении)',
			'messages.markedAsUnwatchedOffline' => 'Отмечено как непросмотренное (синхронизируется при подключении)',
			'messages.removedFromContinueWatching' => 'Удалено из «Продолжить просмотр»',
			'messages.errorLoading' => ({required Object error}) => 'Ошибка: ${error}',
			'messages.fileInfoNotAvailable' => 'Информация о файле недоступна',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Ошибка загрузки информации о файле: ${error}',
			'messages.errorLoadingSeries' => 'Ошибка загрузки сериала',
			'messages.errorLoadingSeason' => 'Ошибка загрузки сезона',
			'messages.musicNotSupported' => 'Воспроизведение музыки пока не поддерживается',
			'messages.logsCleared' => 'Логи очищены',
			'messages.logsCopied' => 'Логи скопированы в буфер обмена',
			'messages.noLogsAvailable' => 'Логи отсутствуют',
			'messages.libraryScanning' => ({required Object title}) => 'Сканирование "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Сканирование библиотеки начато для "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Не удалось отсканировать библиотеку: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Обновление метаданных "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Обновление метаданных начато для "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Не удалось обновить метаданные: ${error}',
			'messages.logoutConfirm' => 'Вы уверены, что хотите выйти?',
			'messages.noSeasonsFound' => 'Сезоны не найдены',
			'messages.noEpisodesFound' => 'Эпизоды в первом сезоне не найдены',
			'messages.noEpisodesFoundGeneral' => 'Эпизоды не найдены',
			'messages.noResultsFound' => 'Результаты не найдены',
			'messages.sleepTimerSet' => ({required Object label}) => 'Таймер сна установлен на ${label}',
			'messages.noItemsAvailable' => 'Нет доступных элементов',
			'messages.failedToCreatePlayQueueNoItems' => 'Не удалось создать очередь воспроизведения — нет элементов',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Не удалось ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Переключение на совместимый плеер...',
			'messages.logsUploaded' => 'Логи загружены',
			'messages.logsUploadFailed' => 'Не удалось загрузить логи',
			'messages.logId' => 'ID лога',
			'subtitlingStyling.stylingOptions' => 'Параметры стиля',
			'subtitlingStyling.fontSize' => 'Размер шрифта',
			'subtitlingStyling.textColor' => 'Цвет текста',
			'subtitlingStyling.borderSize' => 'Размер обводки',
			'subtitlingStyling.borderColor' => 'Цвет обводки',
			'subtitlingStyling.backgroundOpacity' => 'Прозрачность фона',
			'subtitlingStyling.backgroundColor' => 'Цвет фона',
			'subtitlingStyling.position' => 'Позиция',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Расширенные настройки видеоплеера',
			'mpvConfig.presets' => 'Пресеты',
			'mpvConfig.noPresets' => 'Нет сохранённых пресетов',
			'mpvConfig.saveAsPreset' => 'Сохранить как пресет...',
			'mpvConfig.presetName' => 'Название пресета',
			'mpvConfig.presetNameHint' => 'Введите название для пресета',
			'mpvConfig.loadPreset' => 'Загрузить',
			'mpvConfig.deletePreset' => 'Удалить',
			'mpvConfig.presetSaved' => 'Пресет сохранён',
			'mpvConfig.presetLoaded' => 'Пресет загружен',
			'mpvConfig.presetDeleted' => 'Пресет удалён',
			'mpvConfig.confirmDeletePreset' => 'Вы уверены, что хотите удалить этот пресет?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Подтвердить действие',
			'discover.title' => 'Обзор',
			'discover.switchProfile' => 'Сменить профиль',
			'discover.noContentAvailable' => 'Контент недоступен',
			'discover.addMediaToLibraries' => 'Добавьте медиафайлы в ваши библиотеки',
			'discover.continueWatching' => 'Продолжить просмотр',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Обзор',
			'discover.cast' => 'В ролях',
			'discover.extras' => 'Трейлеры и доп. материалы',
			'discover.seasons' => 'Сезоны',
			'discover.studio' => 'Студия',
			'discover.rating' => 'Рейтинг',
			'discover.episodeCount' => ({required Object count}) => '${count} эпизодов',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} просмотрено',
			'discover.movie' => 'Фильм',
			'discover.tvShow' => 'Сериал',
			'discover.minutesLeft' => ({required Object minutes}) => 'Осталось ${minutes} мин',
			'errors.searchFailed' => ({required Object error}) => 'Ошибка поиска: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Таймаут подключения при загрузке ${context}',
			'errors.connectionFailed' => 'Не удаётся подключиться к серверу Plex',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Не удалось загрузить ${context}: ${error}',
			'errors.noClientAvailable' => 'Клиент недоступен',
			'errors.authenticationFailed' => ({required Object error}) => 'Ошибка аутентификации: ${error}',
			'errors.couldNotLaunchUrl' => 'Не удалось открыть URL аутентификации',
			'errors.pleaseEnterToken' => 'Введите токен',
			'errors.invalidToken' => 'Недействительный токен',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Не удалось проверить токен: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Не удалось переключиться на ${displayName}',
			'libraries.title' => 'Библиотеки',
			'libraries.scanLibraryFiles' => 'Сканировать файлы библиотеки',
			'libraries.scanLibrary' => 'Сканировать библиотеку',
			'libraries.analyze' => 'Анализировать',
			'libraries.analyzeLibrary' => 'Анализировать библиотеку',
			'libraries.refreshMetadata' => 'Обновить метаданные',
			'libraries.emptyTrash' => 'Очистить корзину',
			'libraries.emptyingTrash' => ({required Object title}) => 'Очистка корзины для "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Корзина очищена для "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Не удалось очистить корзину: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Анализ "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Анализ начат для "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Не удалось проанализировать библиотеку: ${error}',
			'libraries.noLibrariesFound' => 'Библиотеки не найдены',
			'libraries.thisLibraryIsEmpty' => 'Эта библиотека пуста',
			'libraries.all' => 'Все',
			'libraries.clearAll' => 'Очистить все',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Вы уверены, что хотите сканировать "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Вы уверены, что хотите проанализировать "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Вы уверены, что хотите обновить метаданные для "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Вы уверены, что хотите очистить корзину для "${title}"?',
			'libraries.manageLibraries' => 'Управление библиотеками',
			'libraries.sort' => 'Сортировка',
			'libraries.sortBy' => 'Сортировать по',
			'libraries.filters' => 'Фильтры',
			'libraries.confirmActionMessage' => 'Вы уверены, что хотите выполнить это действие?',
			'libraries.showLibrary' => 'Показать библиотеку',
			'libraries.hideLibrary' => 'Скрыть библиотеку',
			'libraries.libraryOptions' => 'Параметры библиотеки',
			'libraries.content' => 'содержимое библиотеки',
			'libraries.selectLibrary' => 'Выбрать библиотеку',
			'libraries.filtersWithCount' => ({required Object count}) => 'Фильтры (${count})',
			'libraries.noRecommendations' => 'Рекомендации недоступны',
			'libraries.noCollections' => 'В этой библиотеке нет коллекций',
			'libraries.noFoldersFound' => 'Папки не найдены',
			'libraries.folders' => 'папки',
			'libraries.tabs.recommended' => 'Рекомендуемые',
			'libraries.tabs.browse' => 'Обзор',
			'libraries.tabs.collections' => 'Коллекции',
			'libraries.tabs.playlists' => 'Плейлисты',
			'libraries.groupings.all' => 'Все',
			'libraries.groupings.movies' => 'Фильмы',
			'libraries.groupings.shows' => 'Сериалы',
			'libraries.groupings.seasons' => 'Сезоны',
			'libraries.groupings.episodes' => 'Эпизоды',
			'libraries.groupings.folders' => 'Папки',
			'about.title' => 'О приложении',
			'about.openSourceLicenses' => 'Лицензии открытого ПО',
			'about.versionLabel' => ({required Object version}) => 'Версия ${version}',
			'about.appDescription' => 'Красивый клиент Plex на Flutter',
			'about.viewLicensesDescription' => 'Просмотр лицензий сторонних библиотек',
			'serverSelection.allServerConnectionsFailed' => 'Не удалось подключиться ни к одному серверу. Проверьте сеть и попробуйте снова.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Серверы не найдены для ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Не удалось загрузить серверы: ${error}',
			'hubDetail.title' => 'Название',
			'hubDetail.releaseYear' => 'Год выпуска',
			'hubDetail.dateAdded' => 'Дата добавления',
			'hubDetail.rating' => 'Рейтинг',
			'hubDetail.noItemsFound' => 'Элементы не найдены',
			'logs.clearLogs' => 'Очистить логи',
			'logs.copyLogs' => 'Скопировать логи',
			'logs.uploadLogs' => 'Загрузить логи',
			'logs.error' => 'Ошибка:',
			'logs.stackTrace' => 'Стек вызовов:',
			'licenses.relatedPackages' => 'Связанные пакеты',
			'licenses.license' => 'Лицензия',
			'licenses.licenseNumber' => ({required Object number}) => 'Лицензия ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} лицензий',
			'navigation.libraries' => 'Библиотеки',
			'navigation.downloads' => 'Загрузки',
			'navigation.liveTv' => 'ТВ в прямом эфире',
			'liveTv.title' => 'ТВ в прямом эфире',
			'liveTv.channels' => 'Каналы',
			'liveTv.guide' => 'Программа',
			'liveTv.noChannels' => 'Нет доступных каналов',
			'liveTv.noDvr' => 'DVR не настроен ни на одном сервере',
			'liveTv.tuneFailed' => 'Не удалось настроить канал',
			'liveTv.loading' => 'Загрузка каналов...',
			'liveTv.nowPlaying' => 'Сейчас воспроизводится',
			'liveTv.noPrograms' => 'Нет данных о программах',
			'liveTv.channelNumber' => ({required Object number}) => 'Кн. ${number}',
			'liveTv.live' => 'ЭФИР',
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'НОВОЕ',
			_ => null,
		} ?? switch (path) {
			'liveTv.reloadGuide' => 'Перезагрузить программу',
			'liveTv.allChannels' => 'Все каналы',
			'liveTv.now' => 'Сейчас',
			'liveTv.today' => 'Сегодня',
			'liveTv.midnight' => 'Полночь',
			'liveTv.overnight' => 'Ночь',
			'liveTv.morning' => 'Утро',
			'liveTv.daytime' => 'День',
			'liveTv.evening' => 'Вечер',
			'liveTv.lateNight' => 'Поздний вечер',
			'liveTv.whatsOn' => 'Что идёт',
			'liveTv.watchChannel' => 'Смотреть канал',
			'collections.title' => 'Коллекции',
			'collections.collection' => 'Коллекция',
			'collections.empty' => 'Коллекция пуста',
			'collections.unknownLibrarySection' => 'Невозможно удалить: неизвестный раздел библиотеки',
			'collections.deleteCollection' => 'Удалить коллекцию',
			'collections.deleteConfirm' => ({required Object title}) => 'Вы уверены, что хотите удалить "${title}"? Это действие нельзя отменить.',
			'collections.deleted' => 'Коллекция удалена',
			'collections.deleteFailed' => 'Не удалось удалить коллекцию',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Не удалось удалить коллекцию: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Не удалось загрузить элементы коллекции: ${error}',
			'collections.selectCollection' => 'Выбрать коллекцию',
			'collections.collectionName' => 'Название коллекции',
			'collections.enterCollectionName' => 'Введите название коллекции',
			'collections.addedToCollection' => 'Добавлено в коллекцию',
			'collections.errorAddingToCollection' => 'Не удалось добавить в коллекцию',
			'collections.created' => 'Коллекция создана',
			'collections.removeFromCollection' => 'Удалить из коллекции',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Удалить "${title}" из этой коллекции?',
			'collections.removedFromCollection' => 'Удалено из коллекции',
			'collections.removeFromCollectionFailed' => 'Не удалось удалить из коллекции',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Ошибка удаления из коллекции: ${error}',
			'playlists.title' => 'Плейлисты',
			'playlists.playlist' => 'Плейлист',
			'playlists.noPlaylists' => 'Плейлисты не найдены',
			'playlists.create' => 'Создать плейлист',
			'playlists.playlistName' => 'Название плейлиста',
			'playlists.enterPlaylistName' => 'Введите название плейлиста',
			'playlists.delete' => 'Удалить плейлист',
			'playlists.removeItem' => 'Удалить из плейлиста',
			'playlists.smartPlaylist' => 'Умный плейлист',
			'playlists.itemCount' => ({required Object count}) => '${count} элементов',
			'playlists.oneItem' => '1 элемент',
			'playlists.emptyPlaylist' => 'Этот плейлист пуст',
			'playlists.deleteConfirm' => 'Удалить плейлист?',
			'playlists.deleteMessage' => ({required Object name}) => 'Вы уверены, что хотите удалить "${name}"?',
			'playlists.created' => 'Плейлист создан',
			'playlists.deleted' => 'Плейлист удалён',
			'playlists.itemAdded' => 'Добавлено в плейлист',
			'playlists.itemRemoved' => 'Удалено из плейлиста',
			'playlists.selectPlaylist' => 'Выбрать плейлист',
			'playlists.errorCreating' => 'Не удалось создать плейлист',
			'playlists.errorDeleting' => 'Не удалось удалить плейлист',
			'playlists.errorLoading' => 'Не удалось загрузить плейлисты',
			'playlists.errorAdding' => 'Не удалось добавить в плейлист',
			'playlists.errorReordering' => 'Не удалось переупорядочить элемент плейлиста',
			'playlists.errorRemoving' => 'Не удалось удалить из плейлиста',
			'watchTogether.title' => 'Смотреть вместе',
			'watchTogether.description' => 'Смотрите контент синхронно с друзьями и семьёй',
			'watchTogether.createSession' => 'Создать сессию',
			'watchTogether.creating' => 'Создание...',
			'watchTogether.joinSession' => 'Присоединиться к сессии',
			'watchTogether.joining' => 'Подключение...',
			'watchTogether.controlMode' => 'Режим управления',
			'watchTogether.controlModeQuestion' => 'Кто может управлять воспроизведением?',
			'watchTogether.hostOnly' => 'Только хост',
			'watchTogether.anyone' => 'Все',
			'watchTogether.hostingSession' => 'Хостинг сессии',
			'watchTogether.inSession' => 'В сессии',
			'watchTogether.sessionCode' => 'Код сессии',
			'watchTogether.hostControlsPlayback' => 'Хост управляет воспроизведением',
			'watchTogether.anyoneCanControl' => 'Любой может управлять воспроизведением',
			'watchTogether.hostControls' => 'Управление хоста',
			'watchTogether.anyoneControls' => 'Управление для всех',
			'watchTogether.participants' => 'Участники',
			'watchTogether.host' => 'Хост',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Вы — хост',
			'watchTogether.watchingWithOthers' => 'Смотрите с другими',
			'watchTogether.endSession' => 'Завершить сессию',
			'watchTogether.leaveSession' => 'Покинуть сессию',
			'watchTogether.endSessionQuestion' => 'Завершить сессию?',
			'watchTogether.leaveSessionQuestion' => 'Покинуть сессию?',
			'watchTogether.endSessionConfirm' => 'Это завершит сессию для всех участников.',
			'watchTogether.leaveSessionConfirm' => 'Вы будете удалены из сессии.',
			'watchTogether.endSessionConfirmOverlay' => 'Это завершит сеанс просмотра для всех участников.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Вы будете отключены от сеанса просмотра.',
			'watchTogether.end' => 'Завершить',
			'watchTogether.leave' => 'Покинуть',
			'watchTogether.syncing' => 'Синхронизация...',
			'watchTogether.joinWatchSession' => 'Присоединиться к просмотру',
			'watchTogether.enterCodeHint' => 'Введите 8-символьный код',
			'watchTogether.pasteFromClipboard' => 'Вставить из буфера обмена',
			'watchTogether.pleaseEnterCode' => 'Введите код сессии',
			'watchTogether.codeMustBe8Chars' => 'Код сессии должен содержать 8 символов',
			'watchTogether.joinInstructions' => 'Введите код сессии, предоставленный хостом, чтобы присоединиться к просмотру.',
			'watchTogether.failedToCreate' => 'Не удалось создать сессию',
			'watchTogether.failedToJoin' => 'Не удалось присоединиться к сессии',
			'watchTogether.sessionCodeCopied' => 'Код сессии скопирован в буфер обмена',
			'watchTogether.relayUnreachable' => 'Ретранслятор недоступен. Возможно, ваш провайдер блокирует подключение. Вы можете попробовать, но «Смотреть вместе» может не работать.',
			'watchTogether.reconnectingToHost' => 'Переподключение к хосту...',
			'watchTogether.currentPlayback' => 'Текущее воспроизведение',
			'watchTogether.joinCurrentPlayback' => 'Присоединиться к текущему воспроизведению',
			'watchTogether.joinCurrentPlaybackDescription' => 'Вернуться к тому, что сейчас смотрит хост',
			'watchTogether.failedToOpenCurrentPlayback' => 'Не удалось открыть текущее воспроизведение',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} присоединился',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} вышел',
			'downloads.title' => 'Загрузки',
			'downloads.manage' => 'Управление',
			'downloads.tvShows' => 'Сериалы',
			'downloads.movies' => 'Фильмы',
			'downloads.noDownloads' => 'Загрузок пока нет',
			'downloads.noDownloadsDescription' => 'Загруженный контент появится здесь для просмотра офлайн',
			'downloads.downloadNow' => 'Загрузить',
			'downloads.deleteDownload' => 'Удалить загрузку',
			'downloads.retryDownload' => 'Повторить загрузку',
			'downloads.downloadQueued' => 'Загрузка поставлена в очередь',
			'downloads.episodesQueued' => ({required Object count}) => '${count} эпизодов поставлено в очередь загрузки',
			'downloads.downloadDeleted' => 'Загрузка удалена',
			'downloads.deleteConfirm' => ({required Object title}) => 'Вы уверены, что хотите удалить "${title}"? Загруженный файл будет удалён с устройства.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Удаление ${title}... (${current} из ${total})',
			'downloads.noDownloadsTree' => 'Нет загрузок',
			'downloads.pauseAll' => 'Приостановить все',
			'downloads.resumeAll' => 'Возобновить все',
			'downloads.deleteAll' => 'Удалить все',
			'shaders.title' => 'Шейдеры',
			'shaders.noShaderDescription' => 'Без улучшения видео',
			'shaders.nvscalerDescription' => 'Масштабирование NVIDIA для более чёткого видео',
			'shaders.qualityFast' => 'Быстрый',
			'shaders.qualityHQ' => 'Высокое качество',
			'shaders.mode' => 'Режим',
			'shaders.importShader' => 'Импортировать шейдер',
			'shaders.customShaderDescription' => 'Пользовательский GLSL шейдер',
			'shaders.shaderImported' => 'Шейдер импортирован',
			'shaders.shaderImportFailed' => 'Не удалось импортировать шейдер',
			'shaders.deleteShader' => 'Удалить шейдер',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Удалить "${name}"?',
			'companionRemote.title' => 'Пульт управления',
			'companionRemote.connectToDevice' => 'Подключиться к устройству',
			'companionRemote.hostRemoteSession' => 'Создать удалённую сессию',
			'companionRemote.controlThisDevice' => 'Управляйте этим устройством с телефона',
			'companionRemote.remoteControl' => 'Пульт управления',
			'companionRemote.controlDesktop' => 'Управлять десктопным устройством',
			'companionRemote.connectedTo' => ({required Object name}) => 'Подключено к ${name}',
			'companionRemote.session.creatingSession' => 'Создание удалённой сессии...',
			'companionRemote.session.failedToCreate' => 'Не удалось создать удалённую сессию:',
			'companionRemote.session.noSession' => 'Нет доступных сессий',
			'companionRemote.session.scanQrCode' => 'Сканировать QR-код',
			'companionRemote.session.orEnterManually' => 'Или введите вручную',
			'companionRemote.session.hostAddress' => 'Адрес хоста',
			'companionRemote.session.sessionId' => 'ID сессии',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Подключено',
			'companionRemote.session.waitingForConnection' => 'Ожидание подключения...',
			'companionRemote.session.usePhoneToControl' => 'Используйте мобильное устройство для управления этим приложением',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} скопировано в буфер обмена',
			'companionRemote.session.copyToClipboard' => 'Скопировать в буфер обмена',
			'companionRemote.session.newSession' => 'Новая сессия',
			'companionRemote.session.minimize' => 'Свернуть',
			'companionRemote.pairing.scan' => 'Сканировать',
			'companionRemote.pairing.manual' => 'Вручную',
			'companionRemote.pairing.pairWithDesktop' => 'Сопряжение с ПК',
			'companionRemote.pairing.enterSessionDetails' => 'Введите данные сессии, показанные на десктопном устройстве',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Введите 8-символьный ID сессии',
			'companionRemote.pairing.pinHint' => 'Введите 6-значный PIN',
			'companionRemote.pairing.connecting' => 'Подключение...',
			'companionRemote.pairing.tips' => 'Советы',
			'companionRemote.pairing.tipDesktop' => 'Откройте Plezy на десктопе и включите пульт управления в настройках или меню',
			'companionRemote.pairing.tipScan' => 'Используйте вкладку «Сканировать» для быстрого сопряжения через QR-код на десктопе',
			'companionRemote.pairing.tipWifi' => 'Убедитесь, что оба устройства находятся в одной WiFi-сети',
			'companionRemote.pairing.cameraPermissionRequired' => 'Для сканирования QR-кодов требуется разрешение на камеру.\nПредоставьте доступ к камере в настройках устройства.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Не удалось запустить камеру: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Наведите камеру на QR-код, показанный на десктопе',
			'companionRemote.pairing.invalidQrCode' => 'Недопустимый формат QR-кода',
			'companionRemote.pairing.validationHostRequired' => 'Введите адрес хоста',
			'companionRemote.pairing.validationHostFormat' => 'Формат должен быть IP:порт (например, 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Введите ID сессии',
			'companionRemote.pairing.validationSessionIdLength' => 'ID сессии должен содержать 8 символов',
			'companionRemote.pairing.validationPinRequired' => 'Введите PIN',
			'companionRemote.pairing.validationPinLength' => 'PIN должен содержать 6 цифр',
			'companionRemote.pairing.connectionTimedOut' => 'Время подключения истекло. Проверьте ID сессии и PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Сессия не найдена. Проверьте ваши учётные данные.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Не удалось подключиться: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Отключиться от удалённой сессии?',
			'companionRemote.remote.reconnecting' => 'Переподключение...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Попытка ${current} из 5',
			'companionRemote.remote.retryNow' => 'Повторить сейчас',
			'companionRemote.remote.connectionError' => 'Ошибка подключения',
			'companionRemote.remote.notConnected' => 'Не подключено',
			'companionRemote.remote.tabRemote' => 'Пульт',
			'companionRemote.remote.tabPlay' => 'Воспроизведение',
			'companionRemote.remote.tabMore' => 'Ещё',
			'companionRemote.remote.menu' => 'Меню',
			'companionRemote.remote.tabNavigation' => 'Навигация',
			'companionRemote.remote.tabDiscover' => 'Обзор',
			'companionRemote.remote.tabLibraries' => 'Библиотеки',
			'companionRemote.remote.tabSearch' => 'Поиск',
			'companionRemote.remote.tabDownloads' => 'Загрузки',
			'companionRemote.remote.tabSettings' => 'Настройки',
			'companionRemote.remote.previous' => 'Предыдущий',
			'companionRemote.remote.playPause' => 'Воспроизведение/Пауза',
			'companionRemote.remote.next' => 'Следующий',
			'companionRemote.remote.seekBack' => 'Назад',
			'companionRemote.remote.stop' => 'Стоп',
			'companionRemote.remote.seekForward' => 'Вперёд',
			'companionRemote.remote.volume' => 'Громкость',
			'companionRemote.remote.volumeDown' => 'Тише',
			'companionRemote.remote.volumeUp' => 'Громче',
			'companionRemote.remote.fullscreen' => 'Полноэкранный',
			'companionRemote.remote.subtitles' => 'Субтитры',
			'companionRemote.remote.audio' => 'Аудио',
			'companionRemote.remote.searchHint' => 'Поиск на десктопе...',
			'videoSettings.playbackSettings' => 'Настройки воспроизведения',
			'videoSettings.playbackSpeed' => 'Скорость воспроизведения',
			'videoSettings.sleepTimer' => 'Таймер сна',
			'videoSettings.audioSync' => 'Синхронизация аудио',
			'videoSettings.subtitleSync' => 'Синхронизация субтитров',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Аудиовыход',
			'videoSettings.performanceOverlay' => 'Оверлей производительности',
			'videoSettings.audioPassthrough' => 'Сквозной вывод аудио',
			'videoSettings.audioNormalization' => 'Нормализация аудио',
			'externalPlayer.title' => 'Внешний плеер',
			'externalPlayer.useExternalPlayer' => 'Использовать внешний плеер',
			'externalPlayer.useExternalPlayerDescription' => 'Открывать видео во внешнем приложении вместо встроенного плеера',
			'externalPlayer.selectPlayer' => 'Выбрать плеер',
			'externalPlayer.systemDefault' => 'Системный по умолчанию',
			'externalPlayer.addCustomPlayer' => 'Добавить свой плеер',
			'externalPlayer.playerName' => 'Название плеера',
			'externalPlayer.playerCommand' => 'Команда',
			'externalPlayer.playerPackage' => 'Имя пакета',
			'externalPlayer.playerUrlScheme' => 'URL-схема',
			'externalPlayer.customPlayer' => 'Свой плеер',
			'externalPlayer.off' => 'Выкл.',
			'externalPlayer.launchFailed' => 'Не удалось открыть внешний плеер',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} не установлен',
			'externalPlayer.playInExternalPlayer' => 'Воспроизвести во внешнем плеере',
			'metadataEdit.editMetadata' => 'Редактировать...',
			'metadataEdit.screenTitle' => 'Редактировать метаданные',
			'metadataEdit.basicInfo' => 'Основная информация',
			'metadataEdit.artwork' => 'Обложка',
			'metadataEdit.advancedSettings' => 'Дополнительные настройки',
			'metadataEdit.title' => 'Название',
			'metadataEdit.sortTitle' => 'Название для сортировки',
			'metadataEdit.originalTitle' => 'Оригинальное название',
			'metadataEdit.releaseDate' => 'Дата выпуска',
			'metadataEdit.contentRating' => 'Возрастной рейтинг',
			'metadataEdit.studio' => 'Студия',
			'metadataEdit.tagline' => 'Слоган',
			'metadataEdit.summary' => 'Описание',
			'metadataEdit.poster' => 'Постер',
			'metadataEdit.background' => 'Фон',
			'metadataEdit.selectPoster' => 'Выбрать постер',
			'metadataEdit.selectBackground' => 'Выбрать фон',
			'metadataEdit.fromUrl' => 'По URL',
			'metadataEdit.uploadFile' => 'Загрузить файл',
			'metadataEdit.enterImageUrl' => 'Введите URL изображения',
			'metadataEdit.imageUrl' => 'URL изображения',
			'metadataEdit.metadataUpdated' => 'Метаданные обновлены',
			'metadataEdit.metadataUpdateFailed' => 'Не удалось обновить метаданные',
			'metadataEdit.artworkUpdated' => 'Обложка обновлена',
			'metadataEdit.artworkUpdateFailed' => 'Не удалось обновить обложку',
			'metadataEdit.noArtworkAvailable' => 'Обложки недоступны',
			'metadataEdit.notSet' => 'Не задано',
			'metadataEdit.libraryDefault' => 'По умолчанию библиотеки',
			'metadataEdit.accountDefault' => 'По умолчанию аккаунта',
			'metadataEdit.seriesDefault' => 'По умолчанию сериала',
			'metadataEdit.episodeSorting' => 'Сортировка эпизодов',
			'metadataEdit.oldestFirst' => 'Сначала старые',
			'metadataEdit.newestFirst' => 'Сначала новые',
			'metadataEdit.keep' => 'Сохранять',
			'metadataEdit.allEpisodes' => 'Все эпизоды',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} последних эпизодов',
			'metadataEdit.latestEpisode' => 'Последний эпизод',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Эпизоды, добавленные за последние ${count} дней',
			'metadataEdit.deleteAfterPlaying' => 'Удалять эпизоды после просмотра',
			'metadataEdit.never' => 'Никогда',
			'metadataEdit.afterADay' => 'Через день',
			'metadataEdit.afterAWeek' => 'Через неделю',
			'metadataEdit.afterAMonth' => 'Через месяц',
			'metadataEdit.onNextRefresh' => 'При следующем обновлении',
			'metadataEdit.seasons' => 'Сезоны',
			'metadataEdit.show' => 'Показать',
			'metadataEdit.hide' => 'Скрыть',
			'metadataEdit.episodeOrdering' => 'Порядок эпизодов',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Эфирный)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Эфирный)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Абсолютный)',
			'metadataEdit.metadataLanguage' => 'Язык метаданных',
			'metadataEdit.useOriginalTitle' => 'Использовать оригинальное название',
			'metadataEdit.preferredAudioLanguage' => 'Предпочитаемый язык аудио',
			'metadataEdit.preferredSubtitleLanguage' => 'Предпочитаемый язык субтитров',
			'metadataEdit.subtitleMode' => 'Автовыбор субтитров',
			'metadataEdit.manuallySelected' => 'Выбор вручную',
			'metadataEdit.shownWithForeignAudio' => 'Показывать при иноязычном аудио',
			'metadataEdit.alwaysEnabled' => 'Всегда включены',
			_ => null,
		};
	}
}
