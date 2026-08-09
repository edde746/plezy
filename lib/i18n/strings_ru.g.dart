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
class TranslationsRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ru app = _Translations$app$ru._(_root);
	@override late final _Translations$auth$ru auth = _Translations$auth$ru._(_root);
	@override late final _Translations$common$ru common = _Translations$common$ru._(_root);
	@override late final _Translations$screens$ru screens = _Translations$screens$ru._(_root);
	@override late final _Translations$update$ru update = _Translations$update$ru._(_root);
	@override late final _Translations$settings$ru settings = _Translations$settings$ru._(_root);
	@override late final _Translations$search$ru search = _Translations$search$ru._(_root);
	@override late final _Translations$hotkeys$ru hotkeys = _Translations$hotkeys$ru._(_root);
	@override late final _Translations$fileInfo$ru fileInfo = _Translations$fileInfo$ru._(_root);
	@override late final _Translations$mediaMenu$ru mediaMenu = _Translations$mediaMenu$ru._(_root);
	@override late final _Translations$rateSheet$ru rateSheet = _Translations$rateSheet$ru._(_root);
	@override late final _Translations$accessibility$ru accessibility = _Translations$accessibility$ru._(_root);
	@override late final _Translations$tooltips$ru tooltips = _Translations$tooltips$ru._(_root);
	@override late final _Translations$audioTracks$ru audioTracks = _Translations$audioTracks$ru._(_root);
	@override late final _Translations$videoControls$ru videoControls = _Translations$videoControls$ru._(_root);
	@override late final _Translations$messages$ru messages = _Translations$messages$ru._(_root);
	@override late final _Translations$subtitlingStyling$ru subtitlingStyling = _Translations$subtitlingStyling$ru._(_root);
	@override late final _Translations$mpvConfig$ru mpvConfig = _Translations$mpvConfig$ru._(_root);
	@override late final _Translations$dialog$ru dialog = _Translations$dialog$ru._(_root);
	@override late final _Translations$profiles$ru profiles = _Translations$profiles$ru._(_root);
	@override late final _Translations$connections$ru connections = _Translations$connections$ru._(_root);
	@override late final _Translations$discover$ru discover = _Translations$discover$ru._(_root);
	@override late final _Translations$errors$ru errors = _Translations$errors$ru._(_root);
	@override late final _Translations$libraries$ru libraries = _Translations$libraries$ru._(_root);
	@override late final _Translations$about$ru about = _Translations$about$ru._(_root);
	@override late final _Translations$serverSelection$ru serverSelection = _Translations$serverSelection$ru._(_root);
	@override late final _Translations$hubDetail$ru hubDetail = _Translations$hubDetail$ru._(_root);
	@override late final _Translations$logs$ru logs = _Translations$logs$ru._(_root);
	@override late final _Translations$startup$ru startup = _Translations$startup$ru._(_root);
	@override late final _Translations$licenses$ru licenses = _Translations$licenses$ru._(_root);
	@override late final _Translations$navigation$ru navigation = _Translations$navigation$ru._(_root);
	@override late final _Translations$explore$ru explore = _Translations$explore$ru._(_root);
	@override late final _Translations$liveTv$ru liveTv = _Translations$liveTv$ru._(_root);
	@override late final _Translations$collections$ru collections = _Translations$collections$ru._(_root);
	@override late final _Translations$playlists$ru playlists = _Translations$playlists$ru._(_root);
	@override late final _Translations$music$ru music = _Translations$music$ru._(_root);
	@override late final _Translations$watchTogether$ru watchTogether = _Translations$watchTogether$ru._(_root);
	@override late final _Translations$downloads$ru downloads = _Translations$downloads$ru._(_root);
	@override late final _Translations$shaders$ru shaders = _Translations$shaders$ru._(_root);
	@override late final _Translations$companionRemote$ru companionRemote = _Translations$companionRemote$ru._(_root);
	@override late final _Translations$videoSettings$ru videoSettings = _Translations$videoSettings$ru._(_root);
	@override late final _Translations$performanceOverlay$ru performanceOverlay = _Translations$performanceOverlay$ru._(_root);
	@override late final _Translations$externalPlayer$ru externalPlayer = _Translations$externalPlayer$ru._(_root);
	@override late final _Translations$metadataEdit$ru metadataEdit = _Translations$metadataEdit$ru._(_root);
	@override late final _Translations$matchScreen$ru matchScreen = _Translations$matchScreen$ru._(_root);
	@override late final _Translations$serverTasks$ru serverTasks = _Translations$serverTasks$ru._(_root);
	@override late final _Translations$trakt$ru trakt = _Translations$trakt$ru._(_root);
	@override late final _Translations$seerr$ru seerr = _Translations$seerr$ru._(_root);
	@override late final _Translations$services$ru services = _Translations$services$ru._(_root);
	@override late final _Translations$addServer$ru addServer = _Translations$addServer$ru._(_root);
}

// Path: app
class _Translations$app$ru extends Translations$app$en {
	_Translations$app$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$ru extends Translations$auth$en {
	_Translations$auth$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Войти через Plex';
	@override String get showQRCode => 'Показать QR-код';
	@override String get authenticate => 'Войти';
	@override String get authenticationTimeout => 'Время аутентификации истекло. Попробуйте снова.';
	@override String get scanQRToSignIn => 'Отсканируйте QR-код для входа';
	@override String get waitingForAuth => 'Ожидание аутентификации...\nВыполните вход в браузере.';
	@override String get useBrowser => 'Использовать браузер';
	@override String get or => 'или';
	@override String connectToMediaBrowser({required Object product}) => 'Подключиться к ${product}';
	@override String get useQuickConnect => 'Использовать Quick Connect';
	@override String get quickConnectInstructions => 'Откройте Quick Connect в Jellyfin и введите этот код.';
	@override String get quickConnectWaiting => 'Ожидание подтверждения…';
	@override String get quickConnectCancel => 'Отмена';
	@override String get quickConnectExpired => 'Срок действия Quick Connect истёк. Попробуйте снова.';
	@override String get localDataRecoveryRequired => 'Plezy не удалось безопасно восстановить данные локального входа и несинхронизированные данные о воспроизведении. Войдите снова.';
}

// Path: common
class _Translations$common$ru extends Translations$common$en {
	_Translations$common$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
	@override String get edit => 'Редактировать';
	@override String get shuffle => 'Перемешать';
	@override String get addTo => 'Добавить в...';
	@override String get createNew => 'Создать новый';
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
	@override String get off => 'Выкл.';
	@override String seasonNumber({required Object number}) => 'Сезон ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Эпизод ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Глава ${number}';
	@override String get reconnect => 'Переподключить';
	@override String get viewAll => 'Показать все';
	@override String get checkingNetwork => 'Проверка сети...';
	@override String get loadingServers => 'Загрузка серверов...';
	@override String get connectingToServers => 'Подключение к серверам...';
	@override String get startingOfflineMode => 'Запуск автономного режима...';
	@override String get loading => 'Загрузка...';
	@override String get fullscreen => 'Полноэкранный режим';
	@override String get exitFullscreen => 'Выйти из полноэкранного режима';
	@override String get pressBackAgainToExit => 'Нажмите ещё раз для выхода';
	@override late final _Translations$common$ratingSource$ru ratingSource = _Translations$common$ratingSource$ru._(_root);
}

// Path: screens
class _Translations$screens$ru extends Translations$screens$en {
	_Translations$screens$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Лицензии';
	@override String get switchProfile => 'Сменить профиль';
	@override String get subtitleStyling => 'Стиль субтитров';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Логи';
}

// Path: update
class _Translations$update$ru extends Translations$update$en {
	_Translations$update$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
class _Translations$settings$ru extends Translations$settings$en {
	_Translations$settings$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Настройки';
	@override String get supportDeveloper => 'Поддержать Plezy';
	@override String get supportDeveloperDescription => 'Пожертвуйте через Liberapay на развитие';
	@override String get language => 'Язык';
	@override String get theme => 'Тема';
	@override String get appearance => 'Внешний вид';
	@override String get videoPlayback => 'Воспроизведение видео';
	@override String get videoPlaybackDescription => 'Настройка поведения воспроизведения';
	@override String get advanced => 'Дополнительно';
	@override String get episodePosterMode => 'Стиль постера эпизода';
	@override String get seriesPoster => 'Постер сериала';
	@override String get seasonPoster => 'Постер сезона';
	@override String get episodeThumbnail => 'Миниатюра';
	@override String get showHeroSectionDescription => 'Показывать карусель избранного контента на главном экране';
	@override String get secondsLabel => 'Секунды';
	@override String get minutesLabel => 'Минуты';
	@override String get secondsShort => 'с';
	@override String get minutesShort => 'м';
	@override String durationHint({required Object min, required Object max}) => 'Введите длительность (${min}-${max})';
	@override String get systemTheme => 'Системная';
	@override String get lightTheme => 'Светлая';
	@override String get darkTheme => 'Тёмная';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Плотность библиотеки';
	@override String get displayScale => 'Масштаб отображения';
	@override String get compact => 'Компактный';
	@override String get comfortable => 'Комфортный';
	@override String get tvCornerSpotlightBackdrop => 'Фоновое изображение в углу';
	@override String get tvCornerSpotlightBackdropDescription => 'Показывать изображение избранного материала в правом верхнем углу, а не на весь экран';
	@override String get viewMode => 'Режим просмотра';
	@override String get gridView => 'Сетка';
	@override String get listView => 'Список';
	@override String get showHeroSection => 'Показать раздел избранного';
	@override String get continueWatchingAction => 'Действие для «Продолжить просмотр»';
	@override String get continueWatchingPlay => 'Воспроизвести';
	@override String get continueWatchingDetails => 'Открыть сведения';
	@override String get episodeAction => 'Действие для эпизодов';
	@override String get episodePlay => 'Воспроизвести';
	@override String get episodeDetails => 'Открыть сведения';
	@override String get useGlobalHubs => 'Использовать макет главной';
	@override String get useGlobalHubsDescription => 'Показывать единые разделы главной. Иначе использовать рекомендации библиотек.';
	@override String get showServerNameOnHubs => 'Показывать имя сервера в хабах';
	@override String get showServerNameOnHubsDescription => 'Всегда показывать имена серверов в заголовках разделов.';
	@override String get groupLibrariesByServer => 'Группировать библиотеки по серверам';
	@override String get groupLibrariesByServerDescription => 'Группировать библиотеки боковой панели по медиасерверам.';
	@override String get alwaysKeepSidebarOpen => 'Всегда держать боковую панель открытой';
	@override String get alwaysKeepSidebarOpenDescription => 'Боковая панель остаётся развёрнутой, область контента подстраивается';
	@override String get showUnwatchedCount => 'Показывать количество непросмотренных';
	@override String get showUnwatchedCountDescription => 'Отображать количество непросмотренных эпизодов для сериалов и сезонов';
	@override String get showEpisodeNumberOnCards => 'Показывать номер эпизода на карточках';
	@override String get showEpisodeNumberOnCardsDescription => 'Показывать номер сезона и серии на карточках серий';
	@override String get showSeasonPostersOnTabs => 'Показывать постеры сезонов на вкладках';
	@override String get showSeasonPostersOnTabsDescription => 'Показывать постер каждого сезона над его вкладкой';
	@override String get tvFullCardLayout => 'Полноформатные ТВ-карточки';
	@override String get tvFullCardLayoutDescription => 'Использовать ТВ-карточки только с изображением и наложенными именами актёров';
	@override String get focusGlow => 'Свечение при фокусе';
	@override String get focusGlowDescription => 'Показывать мягкое свечение вокруг карточки в фокусе';
	@override String get visualEffects => 'Визуальные эффекты';
	@override String get visualEffectsAuto => 'Автоматически';
	@override String get visualEffectsAutoDescription => 'Автоматически уменьшать эффекты на маломощных устройствах';
	@override String get visualEffectsFull => 'Полные';
	@override String get visualEffectsReduced => 'Уменьшенные';
	@override String get visualEffectsReducedDescription => 'Меньше анимаций и графика с более низким разрешением';
	@override String get hideSpoilers => 'Скрыть спойлеры непросмотренных эпизодов';
	@override String get hideSpoilersDescription => 'Размывать миниатюры и описания непросмотренных серий';
	@override String get playerBackend => 'Бэкенд плеера';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Аппаратное декодирование';
	@override String get hardwareDecodingDescription => 'Использовать аппаратное ускорение, когда доступно';
	@override String get bufferSize => 'Размер буфера';
	@override String bufferSizeMB({required Object size}) => '${size}МБ';
	@override String get bufferSizeAuto => 'Авто (Рекомендуется)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Доступно памяти: ${heap} МБ. Буфер размером ${size} МБ может повлиять на воспроизведение.';
	@override String get playbackBuffer => 'Буфер воспроизведения';
	@override String get playbackBufferAuto => 'Авто (рекомендуется)';
	@override String get playbackBufferLarge => 'Большой';
	@override String get playbackBufferExtraLarge => 'Очень большой';
	@override String get playbackBufferDescription => 'Буферизирует больше при нестабильном соединении. Также ограничено размером буфера.';
	@override String get defaultQualityTitle => 'Качество по умолчанию';
	@override String get musicQualityTitle => 'Качество музыки';
	@override String get subtitleStyling => 'Стиль субтитров';
	@override String get subtitleStylingDescription => 'Настроить внешний вид субтитров';
	@override String get smallSkipDuration => 'Малая перемотка';
	@override String get largeSkipDuration => 'Большая перемотка';
	@override String get rewindOnResume => 'Перемотка при возобновлении';
	@override String secondsUnit({required Object seconds}) => '${seconds} с';
	@override String get defaultSleepTimer => 'Таймер сна по умолчанию';
	@override String minutesUnit({required Object minutes}) => '${minutes} мин';
	@override String get rememberTrackSelections => 'Запоминать выбор дорожек для каждого сериала/фильма';
	@override String get rememberTrackSelectionsDescription => 'Запоминать выбор аудиодорожки и субтитров для каждого материала';
	@override String get followServerTrackSelections => 'Использовать выбор дорожек сервера для каждой серии';
	@override String get followServerTrackSelectionsDescription => 'При смене серии применять аудио и субтитры, выбранные на сервере, вместо переноса текущего выбора';
	@override String get showChapterMarkersOnTimeline => 'Показывать маркеры глав на шкале перемотки';
	@override String get showChapterMarkersOnTimelineDescription => 'Разделять шкалу перемотки по границам глав';
	@override String get clickVideoTogglesPlayback => 'Нажатие на видео запускает или приостанавливает воспроизведение';
	@override String get clickVideoTogglesPlaybackDescription => 'Нажатие на видео запускает или приостанавливает воспроизведение вместо показа элементов управления.';
	@override String get videoPlayerControls => 'Элементы управления плеером';
	@override String get keyboardShortcuts => 'Горячие клавиши';
	@override String get keyboardShortcutsDescription => 'Настроить горячие клавиши';
	@override String get videoPlayerNavigation => 'Навигация видеоплеера';
	@override String get videoPlayerNavigationDescription => 'Использовать клавиши стрелок для навигации по элементам управления плеером';
	@override String get watchTogetherRelay => 'Сервер ретрансляции для совместного просмотра';
	@override String get watchTogetherRelayDescription => 'Задайте свой сервер ретрансляции. Все участники должны использовать один сервер.';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Введите допустимый базовый HTTP- или HTTPS-адрес сервера ретрансляции.';
	@override String get crashReporting => 'Отчёты об ошибках';
	@override String get crashReportingDescription => 'Отправлять отчёты об ошибках для улучшения приложения';
	@override String get debugLogging => 'Журнал отладки';
	@override String get debugLoggingDescription => 'Включить подробное журналирование для устранения неполадок';
	@override String get viewLogs => 'Просмотр логов';
	@override String get viewLogsDescription => 'Просмотр логов приложения';
	@override String get clearImageCache => 'Очистить кэш изображений';
	@override String get clearImageCacheDescription => 'Очистить кэшированные обложки и миниатюры. Изображения могут загружаться медленнее, пока не будут загружены снова.';
	@override String get clearImageCacheSuccess => 'Кэш изображений успешно очищен';
	@override String get resetSettings => 'Сбросить настройки';
	@override String get resetSettingsDescription => 'Восстановить настройки по умолчанию. Это нельзя отменить.';
	@override String get resetSettingsSuccess => 'Настройки успешно сброшены';
	@override String get backup => 'Резервная копия';
	@override String get exportSettings => 'Экспорт настроек';
	@override String get exportSettingsDescription => 'Сохранить настройки в файл';
	@override String get exportSettingsSuccess => 'Настройки экспортированы';
	@override String get importSettings => 'Импорт настроек';
	@override String get importSettingsDescription => 'Восстановить настройки из файла';
	@override String get importSettingsConfirm => 'Это заменит ваши текущие настройки. Продолжить?';
	@override String get importSettingsSuccess => 'Настройки импортированы';
	@override String get importSettingsInvalidFile => 'Этот файл не является действительным экспортом настроек Plezy';
	@override String get importSettingsNoUser => 'Войдите в систему перед импортом настроек';
	@override String get shortcutsReset => 'Горячие клавиши сброшены по умолчанию';
	@override String get about => 'О приложении';
	@override String get aboutDescription => 'Информация о приложении и лицензии';
	@override String get updates => 'Обновления';
	@override String get updateAvailable => 'Доступно обновление';
	@override String get checkForUpdates => 'Проверить обновления';
	@override String get autoCheckUpdatesOnStartup => 'Автоматически проверять обновления при запуске';
	@override String get autoCheckUpdatesOnStartupDescription => 'Уведомлять о доступном обновлении при запуске';
	@override String get validationErrorEnterNumber => 'Введите корректное число';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Длительность должна быть от ${min} до ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Сочетание клавиш уже назначено действию «${action}»';
	@override String shortcutUpdated({required Object action}) => 'Сочетание клавиш для действия «${action}» обновлено';
	@override String get saveFailed => 'Не удалось сохранить изменения. Попробуйте снова.';
	@override String get autoSkip => 'Автопропуск';
	@override String get autoSkipIntro => 'Автопропуск вступления';
	@override String get autoSkipIntroDescription => 'Автоматически пропускать маркеры вступления через несколько секунд';
	@override String get autoSkipCredits => 'Автопропуск титров';
	@override String get autoSkipCreditsDescription => 'Автоматически пропускать титры и воспроизводить следующий эпизод';
	@override String get forceSkipMarkerFallback => 'Всегда использовать резервные маркеры';
	@override String get forceSkipMarkerFallbackDescription => 'Использовать шаблоны названий глав, даже если в Plex есть собственные маркеры';
	@override String get autoSkipDelay => 'Задержка автопропуска';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Подождать ${seconds} секунд перед автопропуском';
	@override String get introPattern => 'Шаблон маркера вступления';
	@override String get introPatternDescription => 'Регулярное выражение для распознавания маркеров вступления в заголовках глав';
	@override String get creditsPattern => 'Шаблон маркера титров';
	@override String get creditsPatternDescription => 'Регулярное выражение для распознавания маркеров титров в заголовках глав';
	@override String get invalidRegex => 'Недопустимое регулярное выражение';
	@override String get regex => 'Регулярное выражение';
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
	@override String get downloadLocationPickerUnavailable => 'Выбор папки недоступен на этом устройстве';
	@override String get downloadOnWifiOnly => 'Загружать только по Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Запретить загрузку по мобильным данным';
	@override String get autoRemoveWatchedDownloads => 'Автоудаление просмотренных загрузок';
	@override String get autoRemoveWatchedDownloadsDescription => 'Автоматически удалять просмотренные загрузки';
	@override String get cellularDownloadBlocked => 'Загрузки через мобильную сеть заблокированы. Используйте Wi-Fi или измените настройку.';
	@override String get maxVolume => 'Максимальная громкость';
	@override String get maxVolumeDescription => 'Разрешить усиление громкости выше 100% для тихих медиа';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Показывать, что вы смотрите, в Discord';
	@override String get services => 'Сервисы';
	@override String get servicesDescription => 'Подключите Trakt, MyAnimeList, Seerr и другие';
	@override String get manageLibrariesDescription => 'Изменять порядок и скрывать библиотеки';
	@override String get companionRemoteServer => 'Сервер удалённого управления';
	@override String get companionRemoteServerDescription => 'Разрешить мобильным устройствам в сети управлять этим приложением';
	@override String get autoPip => 'Автоматический режим «картинка в картинке»';
	@override String get autoPipDescription => 'Автоматически включать режим «картинка в картинке» при выходе из приложения во время воспроизведения';
	@override String get matchContentFrameRate => 'Соответствие частоты кадров контента';
	@override String get matchContentFrameRateDescription => 'Подстраивать частоту обновления экрана под видео';
	@override String get matchRefreshRate => 'Соответствие частоты обновления';
	@override String get matchRefreshRateDescription => 'Подстраивать частоту обновления в полноэкранном режиме';
	@override String get matchDynamicRange => 'Соответствие динамического диапазона';
	@override String get matchDynamicRangeDescription => 'Включать HDR для HDR-контента, затем возвращаться к SDR';
	@override String get displaySwitchDelay => 'Задержка переключения дисплея';
	@override String get tunneledPlayback => 'Туннельное воспроизведение';
	@override String get tunneledPlaybackDescription => 'Использовать видеотуннелирование. Отключите, если при воспроизведении HDR отображается чёрный экран.';
	@override String get audioPassthrough => 'Сквозной вывод аудио';
	@override String get audioPassthroughDescription => 'Передавать звук Dolby/DTS на ресивер или телевизор без перекодирования, сохраняя объёмный звук. Отключите, если нет звука.';
	@override String get audioPassthroughDescriptionAppleTv => 'Использовать встроенный декодер Dolby от Apple для Dolby Digital Plus, включая Atmos. DTS и TrueHD по-прежнему воспроизводятся как многоканальный PCM. Отключите, если звук отсутствует.';
	@override String get audioDownmix => 'Микширование в стерео';
	@override String get audioDownmixDescription => 'Микширует объёмный звук в два канала для стереодинамиков или наушников';
	@override String get downmixCenterBoost => 'Усиление центрального канала';
	@override String downmixCenterBoostValue({required Object db}) => '${db} дБ';
	@override String get downmixCenterBoostLabel => 'Усиление (дБ)';
	@override String get downmixCenterBoostShort => 'дБ';
	@override String get audioDownmixNormalize => 'Нормализация громкости при микшировании';
	@override String get audioDownmixNormalizeDescription => 'Снижает уровень микса во избежание клиппинга. Отключите, чтобы сохранить исходную громкость (возможны искажения в громких сценах).';
	@override String get dvConversionMode => 'Преобразование Dolby Vision';
	@override String get dvConversionModeDescription => 'Выберите, как ExoPlayer обрабатывает файлы Dolby Vision Profile 7.';
	@override String get dvConversionAuto => 'Авто';
	@override String get dvConversionNative => 'Нативно / отключено';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Использовать определение возможностей устройства и обычное резервное поведение';
	@override String get dvConversionNativeDescription => 'Принудительно использовать нативный DV7 и не повторять DV-конвертацию';
	@override String get dvConversionDv81Description => 'Принудительно выполнять inline-конвертацию RPU в Dolby Vision профиль 8.1';
	@override String get dvConversionHevcStripDescription => 'Удалять слои Dolby Vision RPU/EL и передавать обычный HEVC';
	@override String get requireProfileSelectionOnOpen => 'Запрашивать профиль при запуске';
	@override String get requireProfileSelectionOnOpenDescription => 'Показывать выбор профиля при каждом открытии приложения';
	@override String get forceTvMode => 'Принудительный режим ТВ';
	@override String get forceTvModeDescription => 'Принудительно включить ТВ-интерфейс. Для устройств без автоопределения. Требуется перезапуск.';
	@override String get startInFullscreen => 'Запускать в полноэкранном режиме';
	@override String get startInFullscreenDescription => 'Открывать Plezy в полноэкранном режиме при запуске';
	@override String get exitFullscreenOnPlayerClose => 'Выходить из полноэкранного режима при закрытии плеера';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Автоматически выходить из полноэкранного режима при закрытии видеоплеера';
	@override String get autoHidePerformanceOverlay => 'Автоскрытие оверлея производительности';
	@override String get autoHidePerformanceOverlayDescription => 'Скрывать оверлей производительности вместе с элементами управления воспроизведением';
	@override String get showNavBarLabels => 'Показывать подписи панели навигации';
	@override String get showNavBarLabelsDescription => 'Отображать текстовые подписи под иконками панели навигации';
	@override String get startupSection => 'Начальный раздел';
	@override String get liveTvDefaultFavorites => 'Избранные каналы по умолчанию';
	@override String get liveTvDefaultFavoritesDescription => 'Показывать только избранные каналы при открытии ТВ';
	@override String get display => 'Экран';
	@override String get homeScreen => 'Главный экран';
	@override String get navigation => 'Навигация';
	@override String get window => 'Окно';
	@override String get content => 'Контент';
	@override String get player => 'Плеер';
	@override String get subtitlesAndConfig => 'Субтитры и конфигурация';
	@override String get seekAndTiming => 'Перемотка и время';
	@override String get behavior => 'Поведение';
}

// Path: search
class _Translations$search$ru extends Translations$search$en {
	_Translations$search$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Поиск фильмов, сериалов, музыки...';
	@override String get tryDifferentTerm => 'Попробуйте другой запрос';
	@override String get searchYourMedia => 'Поиск в вашей медиатеке';
	@override String get enterTitleActorOrKeyword => 'Введите название, актёра или ключевое слово';
}

// Path: hotkeys
class _Translations$hotkeys$ru extends Translations$hotkeys$en {
	_Translations$hotkeys$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Назначить клавишу для ${actionName}';
	@override String get clearShortcut => 'Очистить клавишу';
	@override String get noShortcutSet => 'Сочетание не задано';
	@override String get currentShortcut => 'Текущее сочетание:';
	@override String get pressToRecord => 'Выберите, чтобы записать сочетание клавиш';
	@override String get recordingShortcut => 'Нажмите сочетание клавиш сейчас';
	@override late final _Translations$hotkeys$actions$ru actions = _Translations$hotkeys$actions$ru._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$ru extends Translations$fileInfo$en {
	_Translations$fileInfo$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Информация о файле';
	@override String get overview => 'Обзор';
	@override String get video => 'Видео';
	@override String get audio => 'Аудио';
	@override String get subtitles => 'Субтитры';
	@override String get images => 'Встроенные изображения';
	@override String get dataStreams => 'Потоки данных';
	@override String get lyrics => 'Текст песни';
	@override String get file => 'Файл';
	@override String get attachments => 'Вложения';
	@override String get delivery => 'Доставка';
	@override String versionCounter({required Object index, required Object count}) => 'Версия ${index} из ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Файл ${index} из ${count}';
	@override String get noStreams => 'Сервер не сообщил о потоках для этого файла.';
	@override String get copyPath => 'Копировать путь';
	@override String get pathCopied => 'Путь к файлу скопирован';
	@override String get codec => 'Кодек';
	@override String get codecTag => 'Тег кодека';
	@override String get resolution => 'Разрешение';
	@override String get codedResolution => 'Кодированное разрешение';
	@override String get bitrate => 'Битрейт';
	@override String get frameRate => 'Частота кадров';
	@override String get rotation => 'Поворот';
	@override String get comment => 'Комментарий';
	@override String get audioDescription => 'Аудиоописание';
	@override String get headerCompression => 'Сжатие заголовков';
	@override String get sidecarFile => 'Файл-спутник';
	@override String get transportTimestamp => 'Метка времени транспорта';
	@override String get displayOffset => 'Смещение отображения';
	@override String get previewFailureCode => 'Код ошибки превью';
	@override String get previewRetries => 'Повторные попытки превью';
	@override String get aspectRatio => 'Соотношение сторон';
	@override String get pixelAspectRatio => 'Попиксельное соотношение сторон';
	@override String get profile => 'Профиль';
	@override String get level => 'Уровень';
	@override String get bitDepth => 'Глубина цвета';
	@override String get pixelFormat => 'Формат пикселей';
	@override String get colorSpace => 'Цветовое пространство';
	@override String get colorRange => 'Цветовой диапазон';
	@override String get colorPrimaries => 'Основные цвета';
	@override String get colorTransfer => 'Передача цвета';
	@override String get chromaSubsampling => 'Субдискретизация цветности';
	@override String get chromaLocation => 'Расположение цветности';
	@override String get scanType => 'Тип развёртки';
	@override String get interlaced => 'Чересстрочный';
	@override String get anamorphic => 'Анаморфный';
	@override String get referenceFrames => 'Опорные кадры';
	@override String get dynamicRange => 'Динамический диапазон';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Уровень Dolby Vision';
	@override String get dolbyVisionVersion => 'Версия Dolby Vision';
	@override String get dolbyVisionLayers => 'Слои Dolby Vision';
	@override String get baseLayerCompatibility => 'Совместимость базового слоя';
	@override String get avcBitstream => 'Битовый поток AVC';
	@override String get nalLengthSize => 'Размер длины NAL';
	@override String get scalingMatrix => 'Пользовательская матрица масштабирования';
	@override String get streamIdentifier => 'Идентификатор потока';
	@override String get streamIndex => 'Индекс потока';
	@override String get streamId => 'ID потока';
	@override String get language => 'Язык';
	@override String get languageCode => 'Код языка';
	@override String get streamTitle => 'Название дорожки';
	@override String get channels => 'Каналы';
	@override String get sampleRate => 'Частота дискретизации';
	@override String get spatialAudio => 'Пространственное аудио';
	@override String get textBased => 'Текстовый';
	@override String get subtitleFormat => 'Формат файла-спутника';
	@override String get provider => 'Провайдер';
	@override String get matchScore => 'Оценка совпадения';
	@override String get externalDelivery => 'Может передаваться отдельно';
	@override String get sidecarPath => 'Путь к файлу-спутнику';
	@override String get sourceStream => 'Скопировано из';
	@override String get temporary => 'Временный';
	@override String get timeBase => 'Временная база';
	@override String get overallBitrate => 'Общий битрейт';
	@override String get path => 'Путь';
	@override String get fileName => 'Имя файла';
	@override String get size => 'Размер';
	@override String get totalSize => 'Общий размер';
	@override String get container => 'Контейнер';
	@override String get duration => 'Длительность';
	@override String get previewThumbnails => 'Миниатюры превью';
	@override String get previewIndex => 'Индекс превью';
	@override String get packetLength => 'Длина пакета';
	@override String get filePresent => 'Файл присутствует';
	@override String get fileReadable => 'Доступен для чтения сервером';
	@override String get streamPath => 'Путь потока';
	@override String get optimizedForStreaming => 'Оптимизировано для потоковой передачи';
	@override String get has64bitOffsets => '64-битные смещения';
	@override String get protocol => 'Протокол';
	@override String get mediaType => 'Тип медиа';
	@override String get sourceKind => 'Тип источника';
	@override String get optimizedVersion => 'Оптимизированная версия';
	@override String get optimizationTarget => 'Цель оптимизации';
	@override String get deletedAt => 'Удалено';
	@override String get remoteSource => 'Удалённый источник';
	@override String get infiniteStream => 'Бесконечный поток';
	@override String get directPlay => 'Прямое воспроизведение';
	@override String get directStream => 'Прямой поток';
	@override String get transcoding => 'Транскодирование';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID версии';
	@override String get fileId => 'ID файла';
	@override String get defaultAudioTrack => 'Аудиодорожка по умолчанию';
	@override String get defaultSubtitleTrack => 'Дорожка субтитров по умолчанию';
	@override String get subtitlesOff => 'Выкл.';
	@override String get flagDefault => 'По умолчанию';
	@override String get flagForced => 'Принудительная';
	@override String get flagSelected => 'Выбрана';
	@override String get flagExternal => 'Внешняя';
	@override String get flagHearingImpaired => 'Для слабослышащих';
	@override String get flagDub => 'Дубляж';
	@override String get flagOriginal => 'Оригинал';
}

// Path: mediaMenu
class _Translations$mediaMenu$ru extends Translations$mediaMenu$en {
	_Translations$mediaMenu$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Отметить как просмотренное';
	@override String get markAsUnwatched => 'Отметить как непросмотренное';
	@override String get removeFromContinueWatching => 'Удалить из «Продолжить просмотр»';
	@override String get viewDetails => 'Показать сведения';
	@override String get goToSeries => 'Перейти к сериалу';
	@override String get shufflePlay => 'Случайное воспроизведение';
	@override String get shuffleNotAvailableOffline => 'Перемешивание недоступно офлайн';
	@override String get fileInfo => 'Информация о файле';
	@override String get deleteEpisodeFromServer => 'Удалить эпизод с сервера';
	@override String get deleteSeasonFromServer => 'Удалить сезон с сервера';
	@override String get deleteShowFromServer => 'Удалить сериал с сервера';
	@override String get deleteMovieFromServer => 'Удалить фильм с сервера';
	@override String get deleteEpisodeTitle => 'Удалить этот эпизод?';
	@override String get deleteSeasonTitle => 'Удалить этот сезон?';
	@override String get deleteShowTitle => 'Удалить этот сериал?';
	@override String get deleteMovieTitle => 'Удалить этот фильм?';
	@override String get deleteEpisodeConfirm => 'Удалить эпизод';
	@override String get deleteSeasonConfirm => 'Удалить сезон';
	@override String get deleteShowConfirm => 'Удалить сериал';
	@override String get deleteMovieConfirm => 'Удалить фильм';
	@override String get deleteAnyway => 'Всё равно удалить';
	@override String confirmDeleteTarget({required Object title}) => 'Навсегда удалить ${title} с вашего сервера?';
	@override String get deleteMultipleWarning => 'Это включает все эпизоды и их файлы.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: 'Это удалит содержащийся в нём ${n} эпизод и его файл.',
		few: 'Это удалит содержащиеся в нём ${n} эпизода и их файлы.',
		many: 'Это удалит содержащиеся в нём ${n} эпизодов и их файлы.',
		other: 'Это удалит содержащиеся в нём ${n} эпизодов и их файлы.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: 'Этот элемент хранится как ${n} файл, который будет удалён.',
		few: 'Этот элемент хранится в ${n} файлах, и все они будут удалены.',
		many: 'Этот элемент хранится в ${n} файлах, и все они будут удалены.',
		other: 'Этот элемент хранится в ${n} файлах, и все они будут удалены.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: 'В этом же файле хранится ещё ${n} эпизод, и он тоже будет удалён:',
		few: 'В этом же файле хранятся ещё ${n} эпизода, и они тоже будут удалены:',
		many: 'В этом же файле хранятся ещё ${n} эпизодов, и они тоже будут удалены:',
		other: 'В этом же файле хранятся ещё ${n} эпизодов, и они тоже будут удалены:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy не смог проверить, какие файлы будут удалены, поэтому может быть удалено больше, чем указанный выше элемент. Отмените и попробуйте снова либо удалите в любом случае.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Ваш сервер не предоставил сведения о файлах для этого элемента, поэтому Plezy не может проверить, какие файлы будут удалены. Может быть удалено больше, чем указанный выше элемент.';
	@override String get mediaDeletedSuccessfully => 'Медиаэлемент успешно удалён';
	@override String get mediaFailedToDelete => 'Не удалось удалить медиаэлемент';
	@override String get rate => 'Оценить';
	@override String get playFromBeginning => 'Воспроизвести сначала';
	@override String get playVersion => 'Воспроизвести версию...';
}

// Path: rateSheet
class _Translations$rateSheet$ru extends Translations$rateSheet$en {
	_Translations$rateSheet$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Оценить';
	@override String get server => 'Сервер';
	@override String get favorite => 'Добавить в избранное';
	@override String get favorited => 'Добавлено в избранное';
	@override String get saved => 'Сохранено';
	@override String get notAvailable => 'Совпадений не найдено';
	@override String get noConnectedServices => 'Подключите сервис в настройках, чтобы выставлять оценки в нём.';
}

// Path: accessibility
class _Translations$accessibility$ru extends Translations$accessibility$en {
	_Translations$accessibility$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
	@override String get decrease => 'Уменьшить';
	@override String get increase => 'Увеличить';
	@override String decreaseValue({required Object label}) => 'Уменьшить ${label}';
	@override String increaseValue({required Object label}) => 'Увеличить ${label}';
	@override String get hue => 'Цветовой тон';
	@override String get saturation => 'Насыщенность';
	@override String get brightness => 'Яркость';
	@override String get hexColor => 'Шестнадцатеричный цвет';
	@override String get expandText => 'Развернуть текст';
	@override String get collapseText => 'Свернуть текст';
	@override String get alphabetNavigation => 'Навигация по алфавиту';
	@override String get alphabetScrollHint => 'Проведите вверх или вниз для перехода по буквам';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Строка ${row} из ${rowCount}, столбец ${column} из ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Строка ${row} из ${rowCount}';
}

// Path: tooltips
class _Translations$tooltips$ru extends Translations$tooltips$en {
	_Translations$tooltips$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Случайное воспроизведение';
	@override String get playTrailer => 'Воспроизвести трейлер';
	@override String get markAsWatched => 'Отметить как просмотренное';
	@override String get markAsUnwatched => 'Отметить как непросмотренное';
}

// Path: audioTracks
class _Translations$audioTracks$ru extends Translations$audioTracks$en {
	_Translations$audioTracks$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Аудиодорожка ${n}';
}

// Path: videoControls
class _Translations$videoControls$ru extends Translations$videoControls$en {
	_Translations$videoControls$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
	@override String get letterbox => 'Вписать в экран';
	@override String get fillScreen => 'Заполнить экран';
	@override String get stretch => 'Растянуть';
	@override String get lockRotation => 'Заблокировать поворот';
	@override String get unlockRotation => 'Разблокировать поворот';
	@override String get timerActive => 'Таймер активен';
	@override String playbackWillPauseIn({required Object duration}) => 'Воспроизведение будет приостановлено через ${duration}';
	@override String get sleepTimerEndOfVideo => 'Конец текущего видео';
	@override String get sleepTimerStopAtHeader => 'Остановить на';
	@override String get sleepTimerDurationHeader => 'Таймер';
	@override String get playbackWillPauseAtEnd => 'Воспроизведение будет приостановлено в конце этого видео';
	@override String get stillWatching => 'Всё ещё смотрите?';
	@override String pausingIn({required Object seconds}) => 'Пауза через ${seconds}с';
	@override String get continueWatching => 'Продолжить';
	@override String get autoPlayNext => 'Автовоспроизведение следующего';
	@override String get playNext => 'Следующее';
	@override String get playButton => 'Воспроизвести';
	@override String get pauseButton => 'Пауза';
	@override String get playbackPaused => 'На паузе';
	@override String get playbackResumed => 'Воспроизведение';
	@override String get loadingVideo => 'Загрузка видео';
	@override String get showPlaybackControls => 'Показать элементы управления воспроизведением';
	@override String get hidePlaybackControls => 'Скрыть элементы управления воспроизведением';
	@override String seekBackwardButton({required Object seconds}) => 'Перемотать назад на ${seconds} с';
	@override String seekForwardButton({required Object seconds}) => 'Перемотать вперёд на ${seconds} с';
	@override String get previousButton => 'Предыдущий эпизод';
	@override String get nextButton => 'Следующий эпизод';
	@override String get previousChapterButton => 'Предыдущая глава';
	@override String get nextChapterButton => 'Следующая глава';
	@override String get muteButton => 'Без звука';
	@override String get unmuteButton => 'Включить звук';
	@override String get settingsButton => 'Настройки воспроизведения';
	@override String get tracksButton => 'Аудио и субтитры';
	@override String get chaptersButton => 'Главы';
	@override String get versionQualityButton => 'Версия и качество';
	@override String get versionColumnHeader => 'Версия';
	@override String get qualityColumnHeader => 'Качество';
	@override String get qualityOriginal => 'Оригинал';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Мбит/с';
	@override String get transcodeUnavailableFallback => 'Транскодирование недоступно — воспроизведение в оригинальном качестве';
	@override String get subtitleUnavailableFallback => 'Не удалось загрузить выбранные субтитры — воспроизведение продолжится без субтитров';
	@override String get pipButton => 'Режим «картинка в картинке»';
	@override String get aspectRatioButton => 'Соотношение сторон';
	@override String get ambientLighting => 'Фоновая подсветка';
	@override String get fullscreenButton => 'Полноэкранный режим';
	@override String get exitFullscreenButton => 'Выйти из полноэкранного режима';
	@override String get alwaysOnTopButton => 'Всегда поверх';
	@override String get rotationLockButton => 'Блокировка поворота';
	@override String get lockScreen => 'Заблокировать экран';
	@override String get screenLockButton => 'Блокировка экрана';
	@override String get longPressToUnlock => 'Удерживайте для разблокировки';
	@override String get timelineSlider => 'Временная шкала';
	@override String get volumeSlider => 'Уровень громкости';
	@override String endsAt({required Object time}) => 'Закончится в ${time}';
	@override String get pipActive => 'Воспроизводится в режиме «картинка в картинке»';
	@override String get pipFailed => 'Не удалось запустить режим «картинка в картинке»';
	@override String get screenshotSaved => 'Снимок экрана сохранён';
	@override String zoomPercent({required Object percent}) => 'Масштаб ${percent}%';
	@override late final _Translations$videoControls$pipErrors$ru pipErrors = _Translations$videoControls$pipErrors$ru._(_root);
	@override String get chapters => 'Главы';
	@override String get noChaptersAvailable => 'Главы недоступны';
	@override String get queue => 'Очередь';
	@override String get noQueueItems => 'В очереди нет элементов';
	@override String get noAudioDevicesAvailable => 'Нет доступных аудиоустройств';
	@override String get searchSubtitles => 'Поиск субтитров';
	@override String get language => 'Язык';
	@override String get noSubtitlesFound => 'Субтитры не найдены';
	@override String get subtitleDownloaded => 'Субтитры загружены';
	@override String get subtitleDownloadedNotApplied => 'Субтитры загружены, но их не удалось выбрать';
	@override String get subtitleDownloadFailed => 'Не удалось загрузить субтитры';
	@override String get searchLanguages => 'Поиск языков...';
}

// Path: messages
class _Translations$messages$ru extends Translations$messages$en {
	_Translations$messages$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Отмечено как просмотренное';
	@override String get markedAsUnwatched => 'Отмечено как непросмотренное';
	@override String get markedAsWatchedOffline => 'Отмечено как просмотренное (синхронизируется при подключении)';
	@override String get markedAsUnwatchedOffline => 'Отмечено как непросмотренное (синхронизируется при подключении)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Автоудалено: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: 'Автоматически удалена ${n} просмотренная загрузка',
		few: 'Автоматически удалены ${n} просмотренные загрузки',
		many: 'Автоматически удалено ${n} просмотренных загрузок',
		other: 'Автоматически удалено ${n} просмотренной загрузки',
	);
	@override String get removedFromContinueWatching => 'Удалено из «Продолжить просмотр»';
	@override String errorLoading({required Object error}) => 'Ошибка: ${error}';
	@override String get searchPartialResults => 'Поиск по некоторым медиасерверам не удался. Показываем доступные результаты.';
	@override String get streamInterrupted => 'Поток прервался. Нажмите «Воспроизвести» или перемотайте, чтобы повторить попытку.';
	@override String get liveStreamInterrupted => 'Прямая трансляция прервалась. Нажмите «Воспроизвести», чтобы повторить попытку.';
	@override String get fileInfoNotAvailable => 'Информация о файле недоступна';
	@override String get playbackAuthenticationRequired => 'Чтобы воспроизвести этот материал, снова войдите на медиасервер.';
	@override String get playbackServerUnavailable => 'Медиасервер недоступен. Попробуйте позже.';
	@override String get playbackDataInvalid => 'Сервер вернул некорректные сведения для воспроизведения.';
	@override String get playbackCancelled => 'Воспроизведение отменено.';
	@override String get playbackFailed => 'Не удалось начать воспроизведение.';
	@override String errorLoadingFileInfo({required Object error}) => 'Ошибка загрузки информации о файле: ${error}';
	@override String get errorLoadingSeries => 'Ошибка загрузки сериала';
	@override String get musicNotSupported => 'Воспроизведение музыки пока не поддерживается';
	@override String get noDescriptionAvailable => 'Описание недоступно';
	@override String get noProfilesAvailable => 'Профили недоступны';
	@override String get contactAdminForProfiles => 'Обратитесь к администратору сервера для добавления профилей';
	@override String get unableToDetermineLibrarySection => 'Не удаётся определить раздел библиотеки для этого элемента';
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
	@override String get seasonsLoadFailed => 'Не удалось загрузить сезоны';
	@override String get noEpisodesFound => 'Эпизоды в первом сезоне не найдены';
	@override String get noEpisodesFoundGeneral => 'Эпизоды не найдены';
	@override String get episodesLoadFailed => 'Не удалось загрузить эпизоды';
	@override String get noResultsFound => 'Результаты не найдены';
	@override String sleepTimerSet({required Object label}) => 'Таймер сна установлен на ${label}';
	@override String get noItemsAvailable => 'Нет доступных элементов';
	@override String get failedToCreatePlayQueueNoItems => 'Не удалось создать очередь воспроизведения — нет элементов';
	@override String failedPlayback({required Object action, required Object error}) => 'Не удалось ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Переключение на совместимый плеер...';
	@override String get serverLimitTitle => 'Ошибка воспроизведения';
	@override String get serverLimitBody => 'Ошибка сервера (HTTP 500). Лимит пропускной способности/транскодирования, вероятно, отклонил сессию. Попросите владельца изменить настройки.';
	@override String get mediaUnreadableTitle => 'Файл недоступен';
	@override String get mediaUnreadableBody => 'Сервер нашёл этот элемент, но не смог прочитать его файл (HTTP 404). Вероятно, файл был перемещён, удалён или его хранилище недоступно. Попросите владельца сервера проверить файл и пересканировать библиотеку.';
	@override String get logsUploaded => 'Логи загружены';
	@override String get logsUploadFailed => 'Не удалось загрузить логи';
	@override String get logId => 'ID лога';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$ru extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get text => 'Текст';
	@override String get border => 'Обводка';
	@override String get background => 'Фон';
	@override String get fontSize => 'Размер шрифта';
	@override String get textColor => 'Цвет текста';
	@override String get borderSize => 'Размер обводки';
	@override String get borderColor => 'Цвет обводки';
	@override String get backgroundOpacity => 'Прозрачность фона';
	@override String get backgroundColor => 'Цвет фона';
	@override String get position => 'Позиция';
	@override String get assOverride => 'Переопределение ASS';
	@override String get overrideScale => 'Масштаб';
	@override String get overrideForce => 'Принудительно';
	@override String get overrideStrip => 'Удалить стили';
	@override String get positionTop => 'Сверху';
	@override String get positionBottom => 'Снизу';
	@override String get bold => 'Жирный';
	@override String get italic => 'Курсив';
	@override String get renderResolution => 'Разрешение отрисовки';
	@override String get renderResolutionScreen => 'Разрешение экрана';
	@override String get renderResolutionVideo => 'Разрешение видео';
}

// Path: mpvConfig
class _Translations$mpvConfig$ru extends Translations$mpvConfig$en {
	_Translations$mpvConfig$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
class _Translations$dialog$ru extends Translations$dialog$en {
	_Translations$dialog$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Подтвердить действие';
}

// Path: profiles
class _Translations$profiles$ru extends Translations$profiles$en {
	_Translations$profiles$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Добавить профиль Plezy';
	@override String get switchingProfile => 'Переключение профиля…';
	@override String get deleteThisProfileTitle => 'Удалить этот профиль?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Удалить ${displayName}. Подключения не изменятся.';
	@override String get active => 'Активный';
	@override String get manage => 'Управление';
	@override String get delete => 'Удалить';
	@override String get signOut => 'Выйти';
	@override String get signOutPlexTitle => 'Выйти из Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Удалить ${displayName} и всех пользователей Plex Home? Вы сможете войти снова в любое время.';
	@override String get signedOutPlex => 'Вы вышли из Plex.';
	@override String get signOutFailed => 'Не удалось выйти.';
	@override String get sectionTitle => 'Профили';
	@override String get summarySingle => 'Добавляйте профили, чтобы сочетать управляемых пользователей и локальные профили';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} профилей · активный: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} профилей';
	@override String get removeConnectionTitle => 'Удалить соединение?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Удалить доступ ${displayName} к ${connectionLabel}. У других профилей он останется.';
	@override String get deleteProfileTitle => 'Удалить профиль?';
	@override String deleteProfileMessage({required Object displayName}) => 'Удалить ${displayName} и его подключения. Серверы останутся доступны.';
	@override String get profileNameLabel => 'Имя профиля';
	@override String get pinProtectionLabel => 'Защита PIN-кодом';
	@override String get pinManagedByPlex => 'PIN управляется Plex. Редактируйте на plex.tv.';
	@override String get noPinSetEditOnPlex => 'PIN не установлен. Чтобы требовать его, отредактируйте пользователя Home на plex.tv.';
	@override String get setPin => 'Установить PIN';
	@override String get setPinTitle => 'Установить PIN';
	@override String get confirmPinTitle => 'Подтвердить PIN';
	@override String get pinSet => 'PIN установлен';
	@override String get changePin => 'Изменить';
	@override String get removePin => 'Удалить';
	@override String get connectionsLabel => 'Соединения';
	@override String get add => 'Добавить';
	@override String get deleteProfileButton => 'Удалить профиль';
	@override String get noConnectionsHint => 'Нет соединений — добавьте одно, чтобы использовать этот профиль.';
	@override String get noConnections => 'Нет соединений';
	@override String get plexHomeAccount => 'Аккаунт Plex Home';
	@override String plexAccountChip({required Object account}) => 'Аккаунт Plex: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} через ${account}';
	@override String get connectionDefault => 'По умолчанию';
	@override String connectionAs({required Object displayName}) => 'как ${displayName}';
	@override String get makeDefault => 'Сделать по умолчанию';
	@override String get removeConnection => 'Удалить';
	@override String get profileRenamed => 'Профиль переименован.';
	@override String borrowAddTo({required Object displayName}) => 'Добавить в ${displayName}';
	@override String get borrowExplain => 'Используйте подключение другого профиля. Для защищённых профилей потребуется PIN.';
	@override String get borrowEmpty => 'Пока нет доступных подключений.';
	@override String get borrowEmptySubtitle => 'Сначала подключите Plex или Jellyfin к другому профилю.';
	@override String get borrowLoadFailed => 'Не удалось загрузить доступные подключения. Попробуйте снова.';
	@override String borrowFromProfile({required Object displayName}) => 'От ${displayName}';
	@override String get borrowConnectionBorrowed => 'Подключение добавлено.';
	@override String get borrowFailed => 'Не удалось добавить подключение.';
	@override String get incorrectPin => 'Неверный PIN.';
	@override String get incorrectPinTryAgain => 'Неверный PIN. Попробуйте ещё раз.';
	@override String get sourceProfileMissingParentAccount => 'У исходного профиля отсутствует родительская учётная запись.';
	@override String get failedToLoadHomeUsers => 'Не удалось загрузить пользователей Plex Home. Проверьте подключение и попробуйте ещё раз.';
	@override String get failedToVerifyPin => 'Не удалось проверить PIN.';
	@override String get newProfile => 'Новый профиль';
	@override String get profileNameHint => 'например, Гости, Дети, Семейная комната';
	@override String get pinProtectionOptional => 'Защита PIN-кодом (необязательно)';
	@override String get pinExplain => 'Для переключения профилей нужен 4-значный PIN.';
	@override String get continueButton => 'Продолжить';
	@override String get pinsDontMatch => 'PIN-коды не совпадают';
}

// Path: connections
class _Translations$connections$ru extends Translations$connections$en {
	_Translations$connections$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Подключения';
	@override String get addConnection => 'Добавить подключение';
	@override String get addConnectionSubtitleNoProfile => 'Войдите через Plex или подключите сервер Jellyfin';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Добавить к ${displayName}: Plex, Jellyfin или подключение другого профиля';
	@override String sessionExpiredOne({required Object name}) => 'Сессия истекла для ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Сессия истекла для ${count} серверов';
	@override String get signInAgain => 'Войти снова';
	@override String editMediaBrowserTitle({required Object product}) => 'Изменить подключение ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Добавьте или удалите URL-адреса для ${serverName}. Plezy будет использовать доступный URL с наименьшей задержкой.';
}

// Path: discover
class _Translations$discover$ru extends Translations$discover$en {
	_Translations$discover$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Обзор';
	@override String get noContentAvailable => 'Контент недоступен';
	@override String get addMediaToLibraries => 'Добавьте медиафайлы в ваши библиотеки';
	@override String get continueWatching => 'Продолжить просмотр';
	@override String continueWatchingIn({required Object library}) => 'Продолжить просмотр в ${library}';
	@override String get nextUp => 'Далее';
	@override String nextUpIn({required Object library}) => 'Далее в ${library}';
	@override String get recentlyAdded => 'Недавно добавленное';
	@override String recentlyAddedIn({required Object library}) => 'Недавно добавленное в ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Последние альбомы в ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Недавно прослушанное в ${library}';
	@override String mostPlayedIn({required Object library}) => 'Часто прослушиваемое в ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Обзор';
	@override String get cast => 'В ролях';
	@override String get extras => 'Трейлеры и доп. материалы';
	@override String get studio => 'Студия';
	@override String get rating => 'Рейтинг';
	@override String get director => 'Режиссёр';
	@override String get directors => 'Режиссёры';
	@override String get movie => 'Фильм';
	@override String get tvShow => 'Сериал';
	@override String minutesLeft({required Object minutes}) => 'Осталось ${minutes} мин';
	@override String get moreLikeThis => 'Похожее';
}

// Path: errors
class _Translations$errors$ru extends Translations$errors$en {
	_Translations$errors$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Ошибка поиска: ${error}';
	@override String get searchUnavailable => 'Поиску не удалось связаться ни с одним медиасервером.';
	@override String connectionTimeout({required Object context}) => 'Таймаут подключения при загрузке ${context}';
	@override String get connectionFailed => 'Не удалось подключиться к медиасерверу';
	@override String unableToLoad({required Object context}) => 'Не удалось загрузить ${context}. Повторите попытку.';
	@override String get noClientAvailable => 'Клиент недоступен';
	@override String get pleaseEnterToken => 'Введите токен';
	@override String get invalidToken => 'Недействительный токен';
	@override String failedToVerifyToken({required Object error}) => 'Не удалось проверить токен: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Не удалось переключиться на ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Не удалось удалить ${displayName}';
	@override String get failedToRate => 'Не удалось обновить оценку';
}

// Path: libraries
class _Translations$libraries$ru extends Translations$libraries$en {
	_Translations$libraries$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Библиотеки';
	@override String get fallbackTitle => 'Библиотека';
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
	@override String get allLibrariesHidden => 'Все библиотеки скрыты';
	@override String hiddenLibrariesCount({required Object count}) => 'Скрытые библиотеки (${count})';
	@override String get thisLibraryIsEmpty => 'Эта библиотека пуста';
	@override String get noItemsMatchFilters => 'Нет элементов, соответствующих активным фильтрам';
	@override String get resetFilters => 'Сбросить фильтры';
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
	@override late final _Translations$libraries$tabs$ru tabs = _Translations$libraries$tabs$ru._(_root);
	@override late final _Translations$libraries$groupings$ru groupings = _Translations$libraries$groupings$ru._(_root);
	@override late final _Translations$libraries$filterCategories$ru filterCategories = _Translations$libraries$filterCategories$ru._(_root);
	@override late final _Translations$libraries$sortLabels$ru sortLabels = _Translations$libraries$sortLabels$ru._(_root);
}

// Path: about
class _Translations$about$ru extends Translations$about$en {
	_Translations$about$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'О приложении';
	@override String get openSourceLicenses => 'Лицензии открытого ПО';
	@override String versionLabel({required Object version}) => 'Версия ${version}';
	@override String get appDescription => 'Красивый клиент Plex и Jellyfin на Flutter';
	@override String get viewLicensesDescription => 'Просмотр лицензий сторонних библиотек';
}

// Path: serverSelection
class _Translations$serverSelection$ru extends Translations$serverSelection$en {
	_Translations$serverSelection$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Серверы не найдены для ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Не удалось загрузить серверы: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$ru extends Translations$hubDetail$en {
	_Translations$hubDetail$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Название';
	@override String get releaseYear => 'Год выпуска';
	@override String get dateAdded => 'Дата добавления';
	@override String get rating => 'Рейтинг';
	@override String get noItemsFound => 'Элементы не найдены';
}

// Path: logs
class _Translations$logs$ru extends Translations$logs$en {
	_Translations$logs$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Очистить логи';
	@override String get copyLogs => 'Скопировать логи';
	@override String get uploadLogs => 'Загрузить логи';
}

// Path: startup
class _Translations$startup$ru extends Translations$startup$en {
	_Translations$startup$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy не удалось запустить';
	@override String get failedBody => 'Во время запуска что-то пошло не так. Сведения ниже показывают, что именно не удалось.';
	@override String get failedBodyRepairable => 'Сохранённый файл настроек Plezy повреждён, и его необходимо пересоздать, прежде чем Plezy сможет запуститься. Повторные попытки не помогут — выберите «Восстановить хранилище».';
	@override String get phaseLabel => 'Шаг';
	@override String get showDetails => 'Показать сведения';
	@override String get hideDetails => 'Скрыть сведения';
	@override String get copyDetails => 'Копировать сведения';
	@override String get detailsCopied => 'Сведения скопированы в буфер обмена';
	@override String get uploadDetails => 'Отправить сведения';
	@override String get repairStorage => 'Восстановить хранилище';
	@override String get repairTitle => 'Восстановить сохранённые данные?';
	@override String get repairBodyCommon => 'Файл настроек Plezy повреждён и не может быть прочитан. Восстановление сбросит все настройки к значениям по умолчанию.';
	@override String get repairBodyOneCredential => 'Одна сохранённая учётная запись повреждена и не может быть прочитана. Восстановление удалит только её; остальные настройки не будут затронуты.';
	@override String get repairBodySignInsKept => 'Вход в ваши серверы и профили будет сохранён.';
	@override String get repairBodySignInsLost => 'Ключ, защищающий сохранённые входы, невозможно восстановить из этого файла, поэтому вам придётся снова войти на каждый сервер и в каждый профиль. На вашем медиасервере ничего не изменится.';
	@override String get repairBodySessionsUncertain => 'Трекеры (MAL, AniList, Simkl, Trakt) и Seerr хранятся отдельно и могут сохраниться или нет. Plezy точно сообщит, что удалось сохранить.';
	@override String get repairConfirm => 'Восстановить';
	@override String get repairSucceeded => 'Хранилище восстановлено';
	@override String get repairNeedsRestart => 'Хранилище восстановлено — требуется перезапуск';
	@override String get restartRequiredBody => 'Ваши данные были восстановлены, но Plezy должен запуститься заново, чтобы использовать их. Закройте Plezy и откройте его снова.';
	@override String get quitPlezy => 'Выйти из Plezy';
	@override String get repairFailed => 'Не удалось восстановить';
	@override String get repairKeptSignIns => 'Ваши серверы и профили по-прежнему в системе.';
	@override String get repairLostSignIns => 'Ключ, защищающий сохранённые входы, не удалось восстановить. Вам придётся снова войти на каждый сервер и в каждый профиль.';
	@override String get repairLostSessions => 'Потеряно как минимум одно подключение трекера или Seerr — его нужно восстановить.';
	@override String get backupTitle => 'Сохранена копия повреждённого файла';
	@override String get backupWarning => 'Она содержит ваши учётные данные для входа. Не загружайте и не передавайте её.';
	@override String get deleteBackup => 'Удалить копию';
	@override String get backupDeleted => 'Копия удалена.';
	@override String get previousFailureTitle => 'В прошлый раз Plezy не удалось запустить';
}

// Path: licenses
class _Translations$licenses$ru extends Translations$licenses$en {
	_Translations$licenses$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Связанные пакеты';
	@override String get license => 'Лицензия';
	@override String licenseNumber({required Object number}) => 'Лицензия ${number}';
	@override String licensesCount({required Object count}) => '${count} лицензий';
}

// Path: navigation
class _Translations$navigation$ru extends Translations$navigation$en {
	_Translations$navigation$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Библиотеки';
	@override String get downloads => 'Загрузки';
	@override String get liveTv => 'Прямой эфир';
	@override String get explore => 'Обзор';
}

// Path: explore
class _Translations$explore$ru extends Translations$explore$en {
	_Translations$explore$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Обзор';
	@override String get selectSource => 'Выбрать источник';
	@override late final _Translations$explore$rows$ru rows = _Translations$explore$rows$ru._(_root);
	@override late final _Translations$explore$status$ru status = _Translations$explore$status$ru._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: '${n} эпизод',
		few: '${n} эпизода',
		many: '${n} эпизодов',
		other: '${n} эпизода',
	);
	@override String get cast => 'В ролях';
	@override String get characters => 'Персонажи';
	@override String get addToWatchlist => 'Добавить в список для просмотра';
	@override String get removeFromWatchlist => 'Удалить из списка для просмотра';
	@override String get watchlistUpdateFailed => 'Не удалось обновить список для просмотра';
	@override String get notInLibrary => 'Нет в вашей библиотеке';
	@override String get inTheseLibraries => 'В этих библиотеках';
	@override String get checkingLibrary => 'Проверка вашей библиотеки...';
	@override String get emptyTitle => 'Здесь пока ничего нет';
	@override String emptyMessage({required Object source}) => 'Разделы из ${source} появятся здесь, когда в них появится контент.';
	@override String searchHint({required Object source}) => 'Поиск в ${source}';
	@override String searchEmpty({required Object query}) => 'Нет результатов по запросу "${query}"';
	@override String searchPrompt({required Object source}) => 'Ищите фильмы и сериалы в ${source}.';
	@override String get searchFailed => 'Ошибка поиска. Проверьте подключение и повторите попытку.';
	@override late final _Translations$explore$badge$ru badge = _Translations$explore$badge$ru._(_root);
	@override late final _Translations$explore$stats$ru stats = _Translations$explore$stats$ru._(_root);
	@override late final _Translations$explore$season$ru season = _Translations$explore$season$ru._(_root);
	@override late final _Translations$explore$format$ru format = _Translations$explore$format$ru._(_root);
	@override late final _Translations$explore$sourceMaterial$ru sourceMaterial = _Translations$explore$sourceMaterial$ru._(_root);
	@override late final _Translations$explore$creditRole$ru creditRole = _Translations$explore$creditRole$ru._(_root);
	@override late final _Translations$explore$relation$ru relation = _Translations$explore$relation$ru._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Выходит ${day} в ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Выходит ${day} в ${time} ${timezone}';
	@override late final _Translations$explore$detail$ru detail = _Translations$explore$detail$ru._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: '${n} результат',
		few: '${n} результата',
		many: '${n} результатов',
		other: '${n} результатов',
	);
}

// Path: liveTv
class _Translations$liveTv$ru extends Translations$liveTv$en {
	_Translations$liveTv$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'ТВ в прямом эфире';
	@override String get guide => 'Программа';
	@override String get noChannels => 'Нет доступных каналов';
	@override String get noDvr => 'DVR не настроен ни на одном сервере';
	@override String get serverUnavailable => 'Сервер прямого эфира недоступен.';
	@override String get serverNotConnected => 'Сервер прямого эфира не подключён.';
	@override String get noPrograms => 'Нет данных о программах';
	@override String get liveStreamFailed => 'Не удалось запустить прямой эфир';
	@override String get unknownProgram => 'Неизвестная программа';
	@override String get unknownHub => 'Неизвестно';
	@override String get unknownError => 'Неизвестная ошибка';
	@override String channelNumber({required Object number}) => 'Канал ${number}';
	@override String get unknownChannel => 'Неизвестный канал';
	@override String get live => 'ЭФИР';
	@override String get reloadGuide => 'Перезагрузить программу';
	@override String get now => 'Сейчас';
	@override String get today => 'Сегодня';
	@override String get tomorrow => 'Завтра';
	@override String get midnight => 'Полночь';
	@override String get overnight => 'Ночь';
	@override String get morning => 'Утро';
	@override String get daytime => 'День';
	@override String get evening => 'Вечер';
	@override String get lateNight => 'Поздний вечер';
	@override String get whatsOn => 'Что идёт';
	@override String get watchChannel => 'Смотреть канал';
	@override String get favorites => 'Избранное';
	@override String get reorderFavorites => 'Изменить порядок избранного';
	@override String get favoritesLoadFailed => 'Не удалось загрузить избранное. Проверьте подключение и повторите попытку.';
	@override String get favoritesUpdateFailed => 'Не удалось обновить избранное. Проверьте подключение и повторите попытку.';
	@override String get joinSession => 'Присоединиться к текущему сеансу';
	@override String watchFromStart({required Object minutes}) => 'Смотреть сначала (${minutes} мин. назад)';
	@override String get watchLive => 'Смотреть в прямом эфире';
	@override String get goToLive => 'К прямому эфиру';
	@override String get record => 'Запись';
	@override String get recordEpisode => 'Записать эпизод';
	@override String get recordSeries => 'Записать сериал';
	@override String get recordOptions => 'Параметры записи';
	@override String get saveTo => 'Сохранить в';
	@override String get recordings => 'Записи';
	@override String get scheduledRecordings => 'Запланировано';
	@override String get recordingRules => 'Правила записи';
	@override String get noScheduledRecordings => 'Нет запланированных записей';
	@override String get manageRecording => 'Управление записью';
	@override String get cancelRecording => 'Отменить запись';
	@override String get cancelRecordingTitle => 'Отменить эту запись?';
	@override String cancelRecordingMessage({required Object title}) => '${title} больше не будет записываться.';
	@override String get deleteRule => 'Удалить правило';
	@override String get deleteRuleTitle => 'Удалить правило записи?';
	@override String deleteRuleMessage({required Object title}) => 'Будущие эпизоды ${title} не будут записаны.';
	@override String get recordingScheduled => 'Запись запланирована';
	@override String get alreadyScheduled => 'Эта передача уже запланирована';
	@override String get dvrAdminRequired => 'Настройки DVR требуют учётной записи администратора';
	@override String get recordingFailed => 'Не удалось запланировать запись';
	@override String get recordingTargetMissing => 'Не удалось определить библиотеку записи';
	@override String get recordNotAvailable => 'Запись недоступна для этой передачи';
	@override String get recordingCancelled => 'Запись отменена';
	@override String get recordingRuleDeleted => 'Правило записи удалено';
	@override String get processRecordingRules => 'Пересчитать правила';
	@override String get recordingInProgress => 'Идёт запись';
	@override String recordingsCount({required Object count}) => 'Запланировано: ${count}';
	@override String get editRule => 'Изменить правило';
	@override String get editRuleAction => 'Изменить';
	@override String get recordingRuleUpdated => 'Правило записи обновлено';
	@override String get guideReloadRequested => 'Запрошено обновление гайда';
	@override String get rulesProcessRequested => 'Запрошен пересчёт правил';
	@override String get recordShow => 'Записать передачу';
}

// Path: collections
class _Translations$collections$ru extends Translations$collections$en {
	_Translations$collections$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Коллекции';
	@override String get collection => 'Коллекция';
	@override String get empty => 'Коллекция пуста';
	@override String get deleteCollection => 'Удалить коллекцию';
	@override String deleteConfirm({required Object title}) => 'Удалить "${title}"? Это нельзя отменить.';
	@override String get deleted => 'Коллекция удалена';
	@override String get deleteFailed => 'Не удалось удалить коллекцию';
	@override String deleteFailedWithError({required Object error}) => 'Не удалось удалить коллекцию: ${error}';
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
	@override String get searchCollections => 'Поиск коллекций...';
}

// Path: playlists
class _Translations$playlists$ru extends Translations$playlists$en {
	_Translations$playlists$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
	@override String get searchPlaylists => 'Поиск плейлистов...';
	@override String get errorCreating => 'Не удалось создать плейлист';
	@override String get errorDeleting => 'Не удалось удалить плейлист';
	@override String get errorLoading => 'Не удалось загрузить плейлисты';
	@override String get errorAdding => 'Не удалось добавить в плейлист';
	@override String get errorReordering => 'Не удалось переупорядочить элемент плейлиста';
	@override String get errorRemoving => 'Не удалось удалить из плейлиста';
}

// Path: music
class _Translations$music$ru extends Translations$music$en {
	_Translations$music$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Перейти к альбому';
	@override String get goToArtist => 'Перейти к исполнителю';
	@override String get instantMix => 'Быстрый микс';
	@override String get playNext => 'Воспроизвести следующим';
	@override String get addToQueue => 'Добавить в очередь';
	@override String discNumber({required Object n}) => 'Диск ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: '${n} трек',
		few: '${n} трека',
		many: '${n} треков',
		other: '${n} трека',
	);
	@override String get nowPlaying => 'Сейчас играет';
	@override String playingFrom({required Object title}) => 'Воспроизведение из ${title}';
	@override String get queue => 'Очередь';
	@override String get clearQueue => 'Очистить очередь';
	@override String get lyrics => 'Текст песни';
	@override String get noLyrics => 'Текст песни недоступен';
	@override String get sleepTimer => 'Таймер сна';
	@override String get sleepTimerEndOfTrack => 'Конец трека';
	@override String sleepTimerMinutes({required Object n}) => '${n} минут';
	@override String get stopPlayback => 'Остановить воспроизведение';
	@override String get previousTrack => 'Предыдущий трек';
	@override String get nextTrack => 'Следующий трек';
	@override String get repeat => 'Повтор';
	@override String get repeatAll => 'Повторять все';
	@override String get repeatOne => 'Повторять один';
}

// Path: watchTogether
class _Translations$watchTogether$ru extends Translations$watchTogether$en {
	_Translations$watchTogether$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
	@override String get hostOnly => 'Только организатор';
	@override String get anyone => 'Все';
	@override String get hostingSession => 'Вы организатор';
	@override String get inSession => 'В сессии';
	@override String get sessionCode => 'Код сессии';
	@override String get openSessionControls => 'Открыть управление сессией «Смотреть вместе»';
	@override String get copySessionCode => 'Скопировать код сессии';
	@override String get hostControlsPlayback => 'Организатор управляет воспроизведением';
	@override String get anyoneCanControl => 'Любой может управлять воспроизведением';
	@override String get hostControls => 'Управляет организатор';
	@override String get anyoneControls => 'Управляют все';
	@override String get participants => 'Участники';
	@override String get host => 'Организатор';
	@override String get hostBadge => 'ОРГАНИЗАТОР';
	@override String get youAreHost => 'Вы — организатор';
	@override String get watchingWithOthers => 'Совместный просмотр';
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
	@override String get enterCodeHint => 'Введите 5-символьный код';
	@override String get pasteFromClipboard => 'Вставить из буфера обмена';
	@override String get pleaseEnterCode => 'Введите код сессии';
	@override String get codeMustBe5Chars => 'Код сессии должен содержать 5 символов';
	@override String get joinInstructions => 'Введите код сессии организатора, чтобы присоединиться.';
	@override String get failedToCreate => 'Не удалось создать сессию';
	@override String get failedToJoin => 'Не удалось присоединиться к сессии';
	@override String get sessionCodeCopied => 'Код сессии скопирован в буфер обмена';
	@override String get relayUnreachable => 'Сервер ретрансляции недоступен. Блокировка интернет-провайдером может помешать совместному просмотру.';
	@override String get reconnectingToHost => 'Повторное подключение к организатору...';
	@override String get currentPlayback => 'Текущее воспроизведение';
	@override String get joinCurrentPlayback => 'Присоединиться к текущему воспроизведению';
	@override String get joinCurrentPlaybackDescription => 'Вернуться к материалу, который сейчас смотрит организатор';
	@override String get failedToOpenCurrentPlayback => 'Не удалось открыть текущее воспроизведение';
	@override String participantJoined({required Object name}) => '${name} присоединился';
	@override String participantLeft({required Object name}) => '${name} вышел';
	@override String participantPaused({required Object name}) => '${name} поставил на паузу';
	@override String participantResumed({required Object name}) => '${name} возобновил';
	@override String participantSeeked({required Object name}) => '${name} перемотал';
	@override String participantBuffering({required Object name}) => 'У ${name} идёт буферизация';
	@override String participantNeedsUpdate({required Object name}) => '${name} использует старую версию приложения — синхронизация недоступна';
	@override String resumingWithout({required Object name}) => 'Возобновление без ${name}';
	@override String get waitingForParticipants => 'Ожидание загрузки у других...';
	@override String waitingForName({required Object name}) => 'Ожидание ${name}...';
	@override String get recentRooms => 'Недавние комнаты';
	@override String get renameRoom => 'Переименовать комнату';
	@override String get removeRoom => 'Удалить';
	@override String get guestSwitchUnavailable => 'Не удалось переключиться — сервер недоступен для синхронизации';
	@override String get guestSwitchFailed => 'Не удалось переключиться — содержимое не найдено на этом сервере';
}

// Path: downloads
class _Translations$downloads$ru extends Translations$downloads$en {
	_Translations$downloads$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Загрузки';
	@override String get manage => 'Управление';
	@override String get tvShows => 'Сериалы';
	@override String get movies => 'Фильмы';
	@override String get music => 'Музыка';
	@override String tracksQueued({required Object count}) => '${count} треков в очереди на загрузку';
	@override String get noDownloads => 'Загрузок пока нет';
	@override String get noDownloadsDescription => 'Загруженный контент появится здесь для просмотра офлайн';
	@override String get downloadNow => 'Загрузить';
	@override String get deleteDownload => 'Удалить загрузку';
	@override String get retryDownload => 'Повторить загрузку';
	@override String get downloadQueued => 'Загрузка поставлена в очередь';
	@override String get downloadResumed => 'Загрузка возобновлена';
	@override String get serverErrorBitrate => 'Ошибка сервера: файл может превышать установленное на сервере ограничение битрейта';
	@override String get storageFull => 'Загрузки остановлены, так как хранилище устройства заполнено. Освободите место и повторите попытку.';
	@override String episodesQueued({required Object count}) => '${count} эпизодов поставлено в очередь загрузки';
	@override String get downloadDeleted => 'Загрузка удалена';
	@override String deleteConfirm({required Object title}) => 'Удалить "${title}" с этого устройства?';
	@override String get cancelledDownloadTitle => 'Загрузка отменена';
	@override String get cancelledDownloadMessage => 'Эта загрузка была отменена. Что вы хотите сделать?';
	@override String get allEpisodesAlreadyDownloaded => 'Все эпизоды уже загружены';
	@override String get resumeDownload => 'Возобновить загрузку';
	@override String get cancelledDownload => 'Загрузка отменена';
	@override String syncingFile({required Object file, required Object status}) => '${file} (синхронизация ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} загружен — нажмите, чтобы завершить';
	@override String get partialDownloadClickToComplete => 'Частично загружено — нажмите, чтобы завершить';
	@override String get deleting => 'Удаление...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Удаление ${title}... (${current} из ${total})';
	@override String get queuedTooltip => 'В очереди';
	@override String queuedFilesTooltip({required Object files}) => 'В очереди: ${files}';
	@override String get downloadingTooltip => 'Загрузка...';
	@override String downloadingFilesTooltip({required Object files}) => 'Загрузка ${files}';
	@override String get noDownloadsTree => 'Нет загрузок';
	@override String get pauseAll => 'Приостановить все';
	@override String get resumeAll => 'Возобновить все';
	@override String get deleteAll => 'Удалить все';
	@override String get selectVersion => 'Выбрать версию';
	@override String get allEpisodes => 'Все эпизоды';
	@override String get unwatchedOnly => 'Только непросмотренные';
	@override String nextNUnwatched({required Object count}) => 'Следующие ${count} непросмотренных';
	@override String get customAmount => 'Указать количество...';
	@override String get includeSpecials => 'Включить спецвыпуски';
	@override String get howManyEpisodes => 'Сколько эпизодов?';
	@override String get invalidEpisodeCount => 'Введите допустимое количество эпизодов.';
	@override String get keepSynced => 'Синхронизировать';
	@override String get downloadOnce => 'Скачать один раз';
	@override String keepNUnwatched({required Object count}) => 'Хранить ${count} непросмотренных';
	@override String get editSyncRule => 'Редактировать правило синхронизации';
	@override String get removeSyncRule => 'Удалить правило синхронизации';
	@override String removeSyncRuleConfirm({required Object title}) => 'Прекратить синхронизацию «${title}»? Скачанные эпизоды будут сохранены.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Прекратить синхронизацию "${title}"?';
	@override String get deleteSyncRuleDownloads => 'Также удалить связанные загрузки';
	@override String get deleteSyncRuleDownloadsDescription => 'Загрузки, используемые другим правилом синхронизации или профилем, будут сохранены.';
	@override String syncRuleCreated({required Object count}) => 'Правило синхронизации создано — хранится ${count} непросмотренных эпизодов';
	@override String get syncRuleUpdated => 'Правило синхронизации обновлено';
	@override String get syncRuleRemoved => 'Правило синхронизации удалено';
	@override String get syncRuleAndDownloadsRemoved => 'Правило синхронизации и связанные загрузки удалены';
	@override String get syncRuleCleanupBusy => 'Правила синхронизации сейчас обновляются. Попробуйте снова чуть позже.';
	@override String get syncRuleCleanupUnavailable => 'Не удалось надёжно определить связанные загрузки. Переподключите сервер и повторите попытку либо удалите правило без удаления загрузок.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Синхронизировано ${count} новых эпизодов для ${title}';
	@override String get activeSyncRules => 'Правила синхронизации';
	@override String get noSyncRules => 'Нет правил синхронизации';
	@override String get manageSyncRule => 'Управление синхронизацией';
	@override String get editEpisodeCount => 'Количество эпизодов';
	@override String get editSyncFilter => 'Фильтр синхронизации';
	@override String get syncAllItems => 'Синхронизация всех элементов';
	@override String get syncUnwatchedItems => 'Синхронизация непросмотренных элементов';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Сервер: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Доступен';
	@override String get syncRuleOffline => 'Офлайн';
	@override String get syncRuleSignInRequired => 'Требуется вход';
	@override String get syncRuleNotAvailableForProfile => 'Недоступно для текущего профиля';
	@override String get syncRuleUnknownServer => 'Неизвестный сервер';
	@override String get syncRuleListCreated => 'Правило синхронизации создано';
	@override late final _Translations$downloads$backgroundWarning$ru backgroundWarning = _Translations$downloads$backgroundWarning$ru._(_root);
}

// Path: shaders
class _Translations$shaders$ru extends Translations$shaders$en {
	_Translations$shaders$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Шейдеры';
	@override String get noShaderDescription => 'Без улучшения видео';
	@override String get nvscalerDescription => 'Масштабирование NVIDIA для более чёткого видео';
	@override String get artcnnVariantNeutral => 'Нейтральный';
	@override String get artcnnVariantDenoise => 'Шумоподавление';
	@override String get artcnnVariantDenoiseSharpen => 'Шумоподавление + резкость';
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
class _Translations$companionRemote$ru extends Translations$companionRemote$en {
	_Translations$companionRemote$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Пульт управления';
	@override String connectedTo({required Object name}) => 'Подключено к ${name}';
	@override String get unknownDevice => 'Неизвестное устройство';
	@override late final _Translations$companionRemote$session$ru session = _Translations$companionRemote$session$ru._(_root);
	@override late final _Translations$companionRemote$pairing$ru pairing = _Translations$companionRemote$pairing$ru._(_root);
	@override late final _Translations$companionRemote$remote$ru remote = _Translations$companionRemote$remote$ru._(_root);
	@override late final _Translations$companionRemote$errors$ru errors = _Translations$companionRemote$errors$ru._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$ru extends Translations$videoSettings$en {
	_Translations$videoSettings$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Скорость воспроизведения';
	@override String get normalSpeed => 'Обычная';
	@override String sleepTimerActive({required Object duration}) => 'Активен (${duration})';
	@override String get zoom => 'Масштаб';
	@override String get sleepTimer => 'Таймер сна';
	@override String get audioSync => 'Синхронизация аудио';
	@override String get subtitleSync => 'Синхронизация субтитров';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Аудиовыход';
	@override String get performanceOverlay => 'Оверлей производительности';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Объёмный звук';
	@override String get audioOutputSpatial => 'Пространственное аудио';
	@override String get audioOutputStereo => 'Стерео';
	@override String get audioNormalization => 'Нормализация громкости';
	@override String get audioDownmix => 'Микширование в стерео';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$ru extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get color => 'Цвет';
	@override String get performance => 'Производительность';
	@override String get buffer => 'Буфер';
	@override String get app => 'Приложение';
	@override String get decoder => 'Декодер';
	@override String get rawDecoder => 'Raw-декодер';
	@override String get tunneling => 'Туннелирование';
	@override String get aspect => 'Соотношение';
	@override String get rotation => 'Поворот';
	@override String get dvSource => 'Источник DV';
	@override String get dvPath => 'Путь DV';
	@override String get p7Conversion => 'Конв. P7';
	@override String get sampleRate => 'Частота дискр.';
	@override String get pixelFormat => 'Формат пикселей';
	@override String get hwFormat => 'Формат HW';
	@override String get matrix => 'Матрица';
	@override String get primaries => 'Основные цвета';
	@override String get transfer => 'Передача';
	@override String get renderFps => 'FPS рендера';
	@override String get displayFps => 'FPS дисплея';
	@override String get avSync => 'A/V синхр.';
	@override String get dropped => 'Пропущено';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'Сред. DV RPU';
	@override String get dvSampleAverage => 'Сред. сэмпл DV';
	@override String get maxLuma => 'Макс. яркость';
	@override String get minLuma => 'Мин. яркость';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Кэш использован';
	@override String get cacheLimit => 'Лимит кэша';
	@override String get speed => 'Скорость';
	@override String get player => 'Плеер';
	@override String get memory => 'Память';
	@override String get uiFps => 'UI FPS';
}

// Path: externalPlayer
class _Translations$externalPlayer$ru extends Translations$externalPlayer$en {
	_Translations$externalPlayer$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Внешний плеер';
	@override String get useExternalPlayer => 'Использовать внешний плеер';
	@override String get useExternalPlayerDescription => 'Открывать видео в другом приложении';
	@override String get selectPlayer => 'Выбрать плеер';
	@override String get customPlayers => 'Свои плееры';
	@override String get systemDefault => 'Системный по умолчанию';
	@override String get addCustomPlayer => 'Добавить свой плеер';
	@override String get playerName => 'Название плеера';
	@override String get playerNameHint => 'Мой плеер';
	@override String get playerCommand => 'Команда';
	@override String get playerPackage => 'Имя пакета';
	@override String get playerUrlScheme => 'URL-схема';
	@override String get off => 'Выкл.';
	@override String get launchFailed => 'Не удалось открыть внешний плеер';
	@override String appNotInstalled({required Object name}) => '${name} не установлен';
	@override String get playInExternalPlayer => 'Воспроизвести во внешнем плеере';
}

// Path: metadataEdit
class _Translations$metadataEdit$ru extends Translations$metadataEdit$en {
	_Translations$metadataEdit$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
	@override String get logo => 'Логотип';
	@override String get squareArt => 'Квадратное изображение';
	@override String get selectPoster => 'Выбрать постер';
	@override String get selectBackground => 'Выбрать фон';
	@override String get selectLogo => 'Выбрать логотип';
	@override String get selectSquareArt => 'Выбрать квадратное изображение';
	@override String get fromUrl => 'По URL';
	@override String get uploadFile => 'Загрузить файл';
	@override String get enterImageUrl => 'Введите URL изображения';
	@override String get imageUrl => 'URL изображения';
	@override String get metadataUpdated => 'Метаданные обновлены';
	@override String get metadataUpdateFailed => 'Не удалось обновить метаданные';
	@override String get artworkUpdated => 'Обложка обновлена';
	@override String get artworkUpdateFailed => 'Не удалось обновить обложку';
	@override String get noArtworkAvailable => 'Обложки недоступны';
	@override String artworkOption({required Object index}) => 'Вариант обложки ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Вариант обложки ${index}, выбран';
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
	@override String get tmdbAiring => 'The Movie Database (по дате выхода)';
	@override String get tvdbAiring => 'TheTVDB (по дате выхода)';
	@override String get tvdbAbsolute => 'TheTVDB (абсолютный порядок)';
	@override String get metadataLanguage => 'Язык метаданных';
	@override String get useOriginalTitle => 'Использовать оригинальное название';
	@override String get preferredAudioLanguage => 'Предпочитаемый язык аудио';
	@override String get preferredSubtitleLanguage => 'Предпочитаемый язык субтитров';
	@override String get subtitleMode => 'Автовыбор субтитров';
	@override String get manuallySelected => 'Выбор вручную';
	@override String get shownWithForeignAudio => 'Показывать при иноязычном аудио';
	@override String get alwaysEnabled => 'Всегда включены';
	@override String get tags => 'Теги';
	@override String get addTag => 'Добавить тег';
	@override String get genre => 'Жанр';
	@override String get director => 'Режиссёр';
	@override String get writer => 'Сценарист';
	@override String get producer => 'Продюсер';
	@override String get country => 'Страна';
	@override String get collection => 'Коллекция';
	@override String get label => 'Метка';
	@override String get style => 'Стиль';
	@override String get mood => 'Настроение';
}

// Path: matchScreen
class _Translations$matchScreen$ru extends Translations$matchScreen$en {
	_Translations$matchScreen$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get match => 'Сопоставить...';
	@override String get fixMatch => 'Исправить сопоставление...';
	@override String get unmatch => 'Сбросить сопоставление';
	@override String get unmatchConfirm => 'Очистить это совпадение? Plex будет считать его несопоставленным до повторного сопоставления.';
	@override String get unmatchSuccess => 'Сопоставление сброшено';
	@override String get unmatchFailed => 'Не удалось сбросить сопоставление';
	@override String get matchApplied => 'Сопоставление применено';
	@override String get matchFailed => 'Не удалось применить сопоставление';
	@override String get titleHint => 'Название';
	@override String get yearHint => 'Год';
	@override String get search => 'Поиск';
	@override String get noMatchesFound => 'Совпадений не найдено';
}

// Path: serverTasks
class _Translations$serverTasks$ru extends Translations$serverTasks$en {
	_Translations$serverTasks$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Задачи сервера';
	@override String get failedToLoad => 'Не удалось загрузить задачи';
	@override String get noTasks => 'Нет выполняемых задач';
}

// Path: trakt
class _Translations$trakt$ru extends Translations$trakt$en {
	_Translations$trakt$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Подключено';
	@override String connectedAs({required Object username}) => 'Подключено как @${username}';
	@override String get disconnectConfirm => 'Отключить аккаунт Trakt?';
	@override String get disconnectConfirmBody => 'Plezy перестанет отправлять события в Trakt. Можно подключить снова в любое время.';
	@override String get scrobble => 'Скробблинг в реальном времени';
	@override String get scrobbleDescription => 'Отправлять события воспроизведения, паузы и остановки в Trakt во время просмотра.';
	@override String get watchedSync => 'Синхронизация статуса просмотра';
	@override String get watchedSyncDescription => 'Когда вы отмечаете элементы как просмотренные в Plezy, они отмечаются и в Trakt.';
}

// Path: seerr
class _Translations$seerr$ru extends Translations$seerr$en {
	_Translations$seerr$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Подключить Seerr';
	@override String get serverUrl => 'URL сервера';
	@override String get serverUrlHelper => 'Адрес вашего экземпляра Seerr';
	@override String get checkServer => 'Продолжить';
	@override String get signInWithJellyfin => 'Войти через Jellyfin';
	@override String get signInWithEmby => 'Войти через Emby';
	@override String get signInWithLocal => 'Использовать локальную учётную запись';
	@override String get email => 'Эл. почта';
	@override String get noSignInMethods => 'Этот экземпляр Seerr не предлагает способа входа, поддерживаемого Plezy.';
	@override String get instance => 'Экземпляр';
	@override String get disconnectConfirm => 'Отключить Seerr?';
	@override String get disconnectConfirmBody => 'Plezy забудет этот экземпляр Seerr. Подключитесь снова в любое время.';
	@override String get request => 'Запросить';
	@override String get request4k => 'Запросить в 4K';
	@override String get seasons => 'Сезоны';
	@override String get allSeasons => 'Все сезоны';
	@override String get advancedOptions => 'Дополнительно';
	@override String get destinationServer => 'Целевой сервер';
	@override String get qualityProfile => 'Профиль качества';
	@override String get rootFolder => 'Корневая папка';
	@override String get languageProfile => 'Языковой профиль';
	@override String get requestSubmitted => 'Запрос отправлен';
	@override String requestFailed({required Object error}) => 'Ошибка запроса: ${error}';
	@override String get requestsLoadFailed => 'Не удалось загрузить параметры запроса';
	@override String get nothingToRequest => 'Всё уже доступно или запрошено.';
	@override String get statusAvailable => 'Доступно';
	@override String get statusPartiallyAvailable => 'Частично доступно';
	@override String get statusRequested => 'Запрошено';
	@override String get statusProcessing => 'Обработка';
}

// Path: services
class _Translations$services$ru extends Translations$services$en {
	_Translations$services$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сервисы';
	@override String get hubSubtitle => 'Синхронизируйте прогресс просмотра и запрашивайте новые фильмы и сериалы.';
	@override String get notConnected => 'Не подключено';
	@override String connectedAs({required Object username}) => 'Подключено как @${username}';
	@override String get scrobble => 'Автоматически отслеживать прогресс';
	@override String get scrobbleDescription => 'Обновляет список, когда вы заканчиваете эпизод или фильм.';
	@override String disconnectConfirm({required Object service}) => 'Отключить ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy перестанет обновлять ${service}. Подключите снова в любое время.';
	@override String connectFailed({required Object service}) => 'Не удалось подключиться к ${service}. Попробуйте ещё раз.';
	@override late final _Translations$services$names$ru names = _Translations$services$names$ru._(_root);
	@override late final _Translations$services$deviceCode$ru deviceCode = _Translations$services$deviceCode$ru._(_root);
	@override late final _Translations$services$oauthProxy$ru oauthProxy = _Translations$services$oauthProxy$ru._(_root);
	@override late final _Translations$services$pendingAuth$ru pendingAuth = _Translations$services$pendingAuth$ru._(_root);
	@override late final _Translations$services$libraryFilter$ru libraryFilter = _Translations$services$libraryFilter$ru._(_root);
}

// Path: addServer
class _Translations$addServer$ru extends Translations$addServer$en {
	_Translations$addServer$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Добавить сервер ${product}';
	@override String get serverUrls => 'URL-адреса сервера';
	@override String get serverUrlsHelper => 'Можно указать несколько URL через запятую.';
	@override String get findServer => 'Найти сервер';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Поиск локальных серверов ${product}...';
	@override String localMediaBrowserServers({required Object product}) => 'Локальные серверы ${product}';
	@override String get username => 'Имя пользователя';
	@override String get password => 'Пароль';
	@override String get signIn => 'Войти';
	@override String get change => 'Изменить';
	@override String get required => 'Обязательно';
	@override String couldNotReachServer({required Object error}) => 'Не удалось связаться с сервером: ${error}';
	@override String signInFailed({required Object error}) => 'Не удалось войти: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect не удался: ${error}';
	@override String get addPlexTitle => 'Войти через Plex';
	@override String get pinExpired => 'Срок действия PIN истёк до входа. Попробуйте снова.';
	@override String failedToRegisterAccount({required Object error}) => 'Не удалось зарегистрировать учётную запись: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Введите URL вашего сервера ${product}';
	@override String get addConnectionTitle => 'Добавить подключение';
	@override String addConnectionTitleScoped({required Object name}) => 'Добавить в ${name}';
	@override String get signInWithPlexCard => 'Войти через Plex';
	@override String get signInWithPlexCardSubtitle => 'Авторизуйте это устройство. Общие серверы будут добавлены.';
	@override String get signInWithPlexCardSubtitleScoped => 'Авторизуйте аккаунт Plex. Пользователи Home станут профилями.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Подключиться к ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Введите URL сервера, имя пользователя и пароль.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Войдите на свой сервер ${product}. Будет привязано к ${name}.';
	@override String get borrowFromAnotherProfile => 'Использовать подключение другого профиля';
	@override String get borrowFromAnotherProfileSubtitle => 'Повторно используйте подключение другого профиля. Для защищённых профилей потребуется PIN.';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$ru extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Критики';
	@override String get audience => 'Зрители';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Критики Rotten Tomatoes';
	@override String get rottenTomatoesAudience => 'Зрители Rotten Tomatoes';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$ru extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$ru._(TranslationsRu root) : this._root = root, super.internal(root);

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
	@override String get episodeNext => 'Следующая серия';
	@override String get episodePrevious => 'Предыдущая серия';
	@override String get speedIncrease => 'Увеличить скорость';
	@override String get speedDecrease => 'Уменьшить скорость';
	@override String get speedReset => 'Сбросить скорость';
	@override String get zoomIn => 'Увеличить масштаб';
	@override String get zoomOut => 'Уменьшить масштаб';
	@override String get zoomReset => 'Сбросить масштаб';
	@override String get subSeekNext => 'К следующему субтитру';
	@override String get subSeekPrev => 'К предыдущему субтитру';
	@override String get shaderToggle => 'Вкл./выкл. шейдеры';
	@override String get skipMarker => 'Пропустить вступление/титры';
	@override String get screenshot => 'Сделать снимок экрана';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$ru extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Требуется Android 8.0 или новее';
	@override String get iosVersion => 'Требуется iOS 15.0 или новее';
	@override String get permissionDisabled => 'Режим «картинка в картинке» отключён. Включите его в системных настройках.';
	@override String get notSupported => 'Устройство не поддерживает режим «картинка в картинке»';
	@override String get voSwitchFailed => 'Не удалось переключить видеовыход для «картинки в картинке»';
	@override String get failed => 'Не удалось запустить режим «картинка в картинке»';
	@override String unknown({required Object error}) => 'Произошла ошибка: ${error}';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$ru extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Рекомендуемые';
	@override String get browse => 'Обзор';
	@override String get collections => 'Коллекции';
	@override String get playlists => 'Плейлисты';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$ru extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Группировка';
	@override String get all => 'Все';
	@override String get movies => 'Фильмы';
	@override String get shows => 'Сериалы';
	@override String get seasons => 'Сезоны';
	@override String get episodes => 'Эпизоды';
	@override String get artists => 'Исполнители';
	@override String get albums => 'Альбомы';
	@override String get tracks => 'Треки';
	@override String get folders => 'Папки';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$ru extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Жанр';
	@override String get year => 'Год';
	@override String get contentRating => 'Возрастной рейтинг';
	@override String get tag => 'Тег';
	@override String get unwatched => 'Непросмотренные';
	@override String get unplayed => 'Не прослушано';
	@override String get favorites => 'Избранное';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$ru extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Название';
	@override String get dateAdded => 'Дата добавления';
	@override String get releaseDate => 'Дата выхода';
	@override String get rating => 'Рейтинг';
	@override String get communityRating => 'Оценка сообщества';
	@override String get criticRating => 'Оценка критиков';
	@override String get userRating => 'Пользовательская оценка';
	@override String get datePlayed => 'Дата просмотра';
	@override String get playCount => 'Количество просмотров';
	@override String get productionYear => 'Год производства';
	@override String get runtime => 'Длительность';
	@override String get officialRating => 'Официальный рейтинг';
	@override String get premiereDate => 'Дата премьеры';
	@override String get startDate => 'Дата начала';
	@override String get airTime => 'Время эфира';
	@override String get studio => 'Студия';
	@override String get random => 'Случайно';
	@override String get dateShared => 'Дата открытия доступа';
	@override String get latestEpisodeAirDate => 'Дата выхода последнего эпизода';
	@override String get lastEpisodeDateAdded => 'Дата добавления последнего эпизода';
}

// Path: explore.rows
class _Translations$explore$rows$ru extends Translations$explore$rows$en {
	_Translations$explore$rows$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Список для просмотра';
	@override String get recommendedMovies => 'Рекомендуемые фильмы';
	@override String get recommendedShows => 'Рекомендуемые сериалы';
	@override String get trendingMovies => 'Фильмы в тренде';
	@override String get trendingShows => 'Сериалы в тренде';
	@override String get popularMovies => 'Популярные фильмы';
	@override String get popularShows => 'Популярные сериалы';
	@override String get trendingAnime => 'Аниме в тренде';
	@override String get suggestedAnime => 'Рекомендуемые аниме';
	@override String get airingAnime => 'Топ выходящих аниме';
	@override String get popularAnime => 'Самые популярные аниме';
	@override String get trending => 'В тренде';
	@override String get upcomingMovies => 'Ожидаемые фильмы';
	@override String get upcomingShows => 'Ожидаемые сериалы';
}

// Path: explore.status
class _Translations$explore$status$ru extends Translations$explore$status$en {
	_Translations$explore$status$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Выходит';
	@override String get ended => 'Завершён';
	@override String get canceled => 'Отменён';
	@override String get upcoming => 'Скоро';
}

// Path: explore.badge
class _Translations$explore$badge$ru extends Translations$explore$badge$en {
	_Translations$explore$badge$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} по популярности';
	@override String rankAiring({required Object n}) => '#${n} в эфире';
	@override String rankRated({required Object n}) => '#${n} по оценкам';
	@override String rankFavorited({required Object n}) => '#${n} по избранному';
	@override String rankTrending({required Object n}) => '#${n} в тренде';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} в сезоне ${season}';
	@override String watchingNow({required Object n}) => '${n} смотрят';
	@override String get available => 'Доступно';
	@override String get partiallyAvailable => 'Доступно частично';
	@override String get availableIn4k => 'Доступно в 4K';
	@override String get requested => 'Запрошено';
	@override String get pendingApproval => 'Ожидает одобрения';
	@override String get processing => 'В обработке';
	@override String get declined => 'Отклонено';
	@override String get requestFailed => 'Запрос не удался';
	@override String get requested4k => 'Запрошено в 4K';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} сезонов';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Серия ${episode} через ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Далее через ${duration}';
	@override String episodesShort({required Object n}) => '${n} эп.';
	@override String minutesPerEpisode({required Object n}) => '${n} мин/эп.';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$ru extends Translations$explore$stats$en {
	_Translations$explore$stats$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} в списках';
	@override String viewersDay({required Object n}) => '${n} посмотрели сегодня';
	@override String viewersWeek({required Object n}) => '${n} посмотрели на этой неделе';
	@override String viewersMonth({required Object n}) => '${n} посмотрели в этом месяце';
	@override String viewersYear({required Object n}) => '${n} посмотрели в этом году';
	@override String viewersAllTime({required Object n}) => '${n} зрителей';
	@override String planning({required Object n}) => '${n} планируют посмотреть';
	@override String favorited({required Object n}) => '${n} в избранном';
	@override String dropRate({required Object percent}) => '${percent} бросили';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: '${n} комментарий',
		few: '${n} комментария',
		many: '${n} комментариев',
		other: '${n} комментариев',
	);
	@override String votes({required Object n}) => '${n} голосов';
	@override String watching({required Object n}) => '${n} смотрят';
	@override String completed({required Object n}) => '${n} завершили';
	@override String onHold({required Object n}) => '${n} отложили';
	@override String dropped({required Object n}) => '${n} бросили';
}

// Path: explore.season
class _Translations$explore$season$ru extends Translations$explore$season$en {
	_Translations$explore$season$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Зима';
	@override String get spring => 'Весна';
	@override String get summer => 'Лето';
	@override String get fall => 'Осень';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$ru extends Translations$explore$format$en {
	_Translations$explore$format$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get tv => 'ТВ';
	@override String get tvShort => 'Короткометражное ТВ';
	@override String get movie => 'Фильм';
	@override String get special => 'Спецвыпуск';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Музыка';
	@override String get other => 'Другое';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$ru extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get original => 'Оригинал';
	@override String get manga => 'Манга';
	@override String get lightNovel => 'Ранобэ';
	@override String get novel => 'Новелла';
	@override String get visualNovel => 'Визуальная новелла';
	@override String get game => 'Игра';
	@override String get webComic => 'Веб-комикс';
	@override String get musicRelease => 'Музыка';
	@override String get otherMedia => 'Другое';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$ru extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get director => 'Режиссёр';
	@override String get writer => 'Сценарист';
	@override String get producer => 'Продюсер';
	@override String get creator => 'Создатель';
	@override String get composer => 'Композитор';
}

// Path: explore.relation
class _Translations$explore$relation$ru extends Translations$explore$relation$en {
	_Translations$explore$relation$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Приквел';
	@override String get sequel => 'Сиквел';
	@override String get sideStory => 'Побочная история';
	@override String get spinOff => 'Спин-офф';
	@override String get alternativeVersion => 'Альтернативная версия';
	@override String get summary => 'Краткое изложение';
	@override String get parentStory => 'Основная история';
	@override String get adaptation => 'Адаптация';
	@override String get other => 'Связано';
}

// Path: explore.detail
class _Translations$explore$detail$ru extends Translations$explore$detail$en {
	_Translations$explore$detail$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Оригинальное название';
	@override String get alsoKnownAs => 'Также известен как';
	@override String get studios => 'Студии';
	@override String get country => 'Страна';
	@override String get language => 'Язык';
	@override String get released => 'Выпущено';
	@override String get physicalRelease => 'На диске';
	@override String get ended => 'Завершено';
	@override String addedOn({required Object date}) => 'Добавлено ${date}';
	@override String get yourRating => 'Ваша оценка';
	@override String get budget => 'Бюджет';
	@override String get revenue => 'Сборы';
	@override String get contentAdvisory => 'Возрастные ограничения';
	@override String get tags => 'Теги';
	@override String get revealSpoilerTags => 'Показать теги со спойлерами';
	@override String get links => 'Ссылки';
	@override String get watchOn => 'Смотреть на';
	@override String get watchTrailer => 'Смотреть трейлер';
	@override String openOn({required Object site}) => 'Открыть на ${site}';
	@override String get crew => 'Съёмочная группа';
	@override String get ratings => 'Рейтинги';
	@override String get schedule => 'Расписание';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: 'Рекомендуют ${n} пользователь',
		few: 'Рекомендуют ${n} пользователя',
		many: 'Рекомендуют ${n} пользователей',
		other: 'Рекомендуют ${n} пользователей',
	);
	@override String recommendedBy({required Object who}) => 'Рекомендовано: ${who}';
	@override String favoritedBy({required Object who}) => 'В избранном у ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} ещё не вышли';
	@override String recommendedByPercent({required Object percent}) => 'Рекомендуют ${percent} зрителей';
	@override String get relatedTitles => 'Связанные названия';
	@override String get background => 'Фон';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$ru extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Загрузки остановятся, когда вы выйдете из приложения';
	@override String get bannerDegraded => 'Фоновые загрузки могут быть ограничены';
	@override String get bannerAction => 'Подробнее';
	@override String get sheetTitle => 'Фоновые загрузки заблокированы';
	@override String get sheetTitleDegraded => 'Фоновые загрузки могут быть ограничены';
	@override String get sheetIntro => 'Android не позволяет Plezy стабильно выполнять загрузки в фоновом режиме.';
	@override String get sheetIntroDegraded => 'Ваше устройство ограничивает время, когда Plezy может выполнять загрузки в фоновом режиме.';
	@override String get reasonBackgroundRestricted => 'Фоновая работа Plezy ограничена. В настройках расхода заряда батареи или фоновой работы выберите «Без ограничений».';
	@override String get reasonStandbyRestricted => 'Android перевёл Plezy в режим ожидания с ограничениями. Для расхода заряда батареи выберите «Без ограничений».';
	@override String get reasonDownloadChannelBlocked => 'Уведомления о загрузках отключены, поэтому ход загрузок и элементы управления могут быть недоступны.';
	@override String get reasonNotificationsDisabled => 'Уведомления отключены. В Android 13 и более новых версиях они необходимы для длительных фоновых загрузок.';
	@override String get reasonDataSaver => 'Экономия трафика включена, поэтому фоновые загрузки через мобильную сеть заблокированы. Загрузки по Wi-Fi должны работать.';
	@override String get reasonOemUnknown => 'Загрузки неоднократно останавливались, пока Plezy работал в фоне. Проверьте настройки расхода заряда батареи или фоновой работы для Plezy.';
	@override String get openSettings => 'Открыть настройки';
	@override String get stillNotWorking => 'Помощь для вашего устройства';
	@override String get stillNotWorkingDescription => 'Посмотрите инструкции для своего устройства. Если проблема не исчезнет, отправьте лог через Настройки › Просмотр логов.';
	@override String get dialogTitle => 'Загрузки могут не завершиться';
	@override String get dialogDownloadAnyway => 'Всё равно скачать';
	@override String get dialogFixFirst => 'Сначала исправить';
	@override String get statusTile => 'Фоновые загрузки';
	@override String get statusOk => 'Работа в фоне разрешена';
	@override String get statusBlocked => 'Заблокировано настройками системы';
	@override String get statusDegraded => 'Ограничено настройками системы';
	@override String get statusUnknown => 'Ещё не проверено';
	@override String get settingsUnavailable => 'Не удалось открыть системные настройки на этом устройстве';
	@override String get linkUnavailable => 'Не удалось открыть dontkillmyapp.com на этом устройстве';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$ru extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Запуск удалённого сервера...';
	@override String get hostAddress => 'Адрес хоста';
	@override String get connected => 'Подключено';
	@override String get serverRunning => 'Удалённый сервер активен';
	@override String get serverStopped => 'Удалённый сервер остановлен';
	@override String get serverRunningDescription => 'Мобильные устройства в вашей сети могут подключаться к этому приложению';
	@override String get serverStoppedDescription => 'Запустите сервер, чтобы разрешить подключение мобильных устройств';
	@override String get usePhoneToControl => 'Используйте мобильное устройство для управления этим приложением';
	@override String get startServer => 'Запустить сервер';
	@override String get stopServer => 'Остановить сервер';
	@override String get minimize => 'Свернуть';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$ru extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Устройства Plezy с тем же аккаунтом Plex появятся здесь';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Подключение...';
	@override String get searchingForDevices => 'Поиск устройств...';
	@override String get noDevicesFound => 'Устройства в вашей сети не найдены';
	@override String get noDevicesHint => 'Откройте Plezy на компьютере и подключите оба устройства к одной сети Wi-Fi';
	@override String get availableDevices => 'Доступные устройства';
	@override String get manualConnection => 'Ручное подключение';
	@override String get cryptoInitFailed => 'Не удалось установить защищённое соединение. Сначала войдите в Plex.';
	@override String get validationHostRequired => 'Введите адрес хоста';
	@override String get validationHostFormat => 'Формат должен быть IP:порт (например, 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Время подключения истекло. Используйте одну сеть на обоих устройствах.';
	@override String get sessionNotFound => 'Устройство не найдено. Убедитесь, что Plezy запущен на хосте.';
	@override String get authFailed => 'Аутентификация не удалась. На обоих устройствах нужен один аккаунт Plex.';
	@override String failedToConnect({required Object error}) => 'Не удалось подключиться: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$ru extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Отключиться от удалённой сессии?';
	@override String get reconnecting => 'Переподключение...';
	@override String attemptOf({required Object current}) => 'Попытка ${current} из 5';
	@override String get retryNow => 'Повторить сейчас';
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

// Path: companionRemote.errors
class _Translations$companionRemote$errors$ru extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Сетевой интерфейс не найден';
	@override String get authenticationFailed => 'Ошибка аутентификации';
	@override String serverStartFailed({required Object error}) => 'Не удалось запустить удалённый сервер: ${error}';
	@override String commandFailed({required Object error}) => 'Не удалось отправить удалённую команду: ${error}';
	@override String get joinTimedOut => 'Время подключения к сеансу истекло';
	@override String get failedToConnectAnyAddress => 'Не удалось подключиться ни к одному адресу';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Соединение потеряно после ${attempts} попыток';
	@override String get connectionLost => 'Соединение потеряно';
}

// Path: services.names
class _Translations$services$names$ru extends Translations$services$names$en {
	_Translations$services$names$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$ru extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Активируйте Plezy в ${service}';
	@override String openToActivate({required Object service}) => 'Открыть ${service} для активации';
	@override String get copyCode => 'Скопировать код активации';
	@override String get waitingForAuthorization => 'Ожидание авторизации…';
	@override String get codeCopied => 'Код скопирован';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$ru extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Войти в ${service}';
	@override String get body => 'Отсканируйте этот QR-код или откройте URL на любом устройстве.';
	@override String openToSignIn({required Object service}) => 'Открыть ${service} для входа';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$ru extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Скопировать URL для входа';
	@override String get urlCopied => 'URL скопирован';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$ru extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Фильтр библиотек';
	@override String get subtitleAllSyncing => 'Синхронизация всех библиотек';
	@override String get subtitleNoneSyncing => 'Ничего не синхронизируется';
	@override String subtitleBlocked({required Object count}) => '${count} заблокировано';
	@override String subtitleAllowed({required Object count}) => '${count} разрешено';
	@override String get mode => 'Режим фильтра';
	@override String get modeBlacklist => 'Чёрный список';
	@override String get modeWhitelist => 'Белый список';
	@override String get modeHintBlacklist => 'Синхронизировать все библиотеки, кроме отмеченных ниже.';
	@override String get modeHintWhitelist => 'Синхронизировать только библиотеки, отмеченные ниже.';
	@override String get libraries => 'Библиотеки';
	@override String get noLibraries => 'Библиотеки недоступны';
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
			'auth.authenticate' => 'Войти',
			'auth.authenticationTimeout' => 'Время аутентификации истекло. Попробуйте снова.',
			'auth.scanQRToSignIn' => 'Отсканируйте QR-код для входа',
			'auth.waitingForAuth' => 'Ожидание аутентификации...\nВыполните вход в браузере.',
			'auth.useBrowser' => 'Использовать браузер',
			'auth.or' => 'или',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Подключиться к ${product}',
			'auth.useQuickConnect' => 'Использовать Quick Connect',
			'auth.quickConnectInstructions' => 'Откройте Quick Connect в Jellyfin и введите этот код.',
			'auth.quickConnectWaiting' => 'Ожидание подтверждения…',
			'auth.quickConnectCancel' => 'Отмена',
			'auth.quickConnectExpired' => 'Срок действия Quick Connect истёк. Попробуйте снова.',
			'auth.localDataRecoveryRequired' => 'Plezy не удалось безопасно восстановить данные локального входа и несинхронизированные данные о воспроизведении. Войдите снова.',
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
			'common.edit' => 'Редактировать',
			'common.shuffle' => 'Перемешать',
			'common.addTo' => 'Добавить в...',
			'common.createNew' => 'Создать новый',
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
			'common.off' => 'Выкл.',
			'common.seasonNumber' => ({required Object number}) => 'Сезон ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Эпизод ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Глава ${number}',
			'common.reconnect' => 'Переподключить',
			'common.viewAll' => 'Показать все',
			'common.checkingNetwork' => 'Проверка сети...',
			'common.loadingServers' => 'Загрузка серверов...',
			'common.connectingToServers' => 'Подключение к серверам...',
			'common.startingOfflineMode' => 'Запуск автономного режима...',
			'common.loading' => 'Загрузка...',
			'common.fullscreen' => 'Полноэкранный режим',
			'common.exitFullscreen' => 'Выйти из полноэкранного режима',
			'common.pressBackAgainToExit' => 'Нажмите ещё раз для выхода',
			'common.ratingSource.critic' => 'Критики',
			'common.ratingSource.audience' => 'Зрители',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Критики Rotten Tomatoes',
			'common.ratingSource.rottenTomatoesAudience' => 'Зрители Rotten Tomatoes',
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
			'settings.supportDeveloper' => 'Поддержать Plezy',
			'settings.supportDeveloperDescription' => 'Пожертвуйте через Liberapay на развитие',
			'settings.language' => 'Язык',
			'settings.theme' => 'Тема',
			'settings.appearance' => 'Внешний вид',
			'settings.videoPlayback' => 'Воспроизведение видео',
			'settings.videoPlaybackDescription' => 'Настройка поведения воспроизведения',
			'settings.advanced' => 'Дополнительно',
			'settings.episodePosterMode' => 'Стиль постера эпизода',
			'settings.seriesPoster' => 'Постер сериала',
			'settings.seasonPoster' => 'Постер сезона',
			'settings.episodeThumbnail' => 'Миниатюра',
			'settings.showHeroSectionDescription' => 'Показывать карусель избранного контента на главном экране',
			'settings.secondsLabel' => 'Секунды',
			'settings.minutesLabel' => 'Минуты',
			'settings.secondsShort' => 'с',
			'settings.minutesShort' => 'м',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Введите длительность (${min}-${max})',
			'settings.systemTheme' => 'Системная',
			'settings.lightTheme' => 'Светлая',
			'settings.darkTheme' => 'Тёмная',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Плотность библиотеки',
			'settings.displayScale' => 'Масштаб отображения',
			'settings.compact' => 'Компактный',
			'settings.comfortable' => 'Комфортный',
			'settings.tvCornerSpotlightBackdrop' => 'Фоновое изображение в углу',
			'settings.tvCornerSpotlightBackdropDescription' => 'Показывать изображение избранного материала в правом верхнем углу, а не на весь экран',
			'settings.viewMode' => 'Режим просмотра',
			'settings.gridView' => 'Сетка',
			'settings.listView' => 'Список',
			'settings.showHeroSection' => 'Показать раздел избранного',
			'settings.continueWatchingAction' => 'Действие для «Продолжить просмотр»',
			'settings.continueWatchingPlay' => 'Воспроизвести',
			'settings.continueWatchingDetails' => 'Открыть сведения',
			'settings.episodeAction' => 'Действие для эпизодов',
			'settings.episodePlay' => 'Воспроизвести',
			'settings.episodeDetails' => 'Открыть сведения',
			'settings.useGlobalHubs' => 'Использовать макет главной',
			'settings.useGlobalHubsDescription' => 'Показывать единые разделы главной. Иначе использовать рекомендации библиотек.',
			'settings.showServerNameOnHubs' => 'Показывать имя сервера в хабах',
			'settings.showServerNameOnHubsDescription' => 'Всегда показывать имена серверов в заголовках разделов.',
			'settings.groupLibrariesByServer' => 'Группировать библиотеки по серверам',
			'settings.groupLibrariesByServerDescription' => 'Группировать библиотеки боковой панели по медиасерверам.',
			'settings.alwaysKeepSidebarOpen' => 'Всегда держать боковую панель открытой',
			'settings.alwaysKeepSidebarOpenDescription' => 'Боковая панель остаётся развёрнутой, область контента подстраивается',
			'settings.showUnwatchedCount' => 'Показывать количество непросмотренных',
			'settings.showUnwatchedCountDescription' => 'Отображать количество непросмотренных эпизодов для сериалов и сезонов',
			'settings.showEpisodeNumberOnCards' => 'Показывать номер эпизода на карточках',
			'settings.showEpisodeNumberOnCardsDescription' => 'Показывать номер сезона и серии на карточках серий',
			'settings.showSeasonPostersOnTabs' => 'Показывать постеры сезонов на вкладках',
			'settings.showSeasonPostersOnTabsDescription' => 'Показывать постер каждого сезона над его вкладкой',
			'settings.tvFullCardLayout' => 'Полноформатные ТВ-карточки',
			'settings.tvFullCardLayoutDescription' => 'Использовать ТВ-карточки только с изображением и наложенными именами актёров',
			'settings.focusGlow' => 'Свечение при фокусе',
			'settings.focusGlowDescription' => 'Показывать мягкое свечение вокруг карточки в фокусе',
			'settings.visualEffects' => 'Визуальные эффекты',
			'settings.visualEffectsAuto' => 'Автоматически',
			'settings.visualEffectsAutoDescription' => 'Автоматически уменьшать эффекты на маломощных устройствах',
			'settings.visualEffectsFull' => 'Полные',
			'settings.visualEffectsReduced' => 'Уменьшенные',
			'settings.visualEffectsReducedDescription' => 'Меньше анимаций и графика с более низким разрешением',
			'settings.hideSpoilers' => 'Скрыть спойлеры непросмотренных эпизодов',
			'settings.hideSpoilersDescription' => 'Размывать миниатюры и описания непросмотренных серий',
			'settings.playerBackend' => 'Бэкенд плеера',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Аппаратное декодирование',
			'settings.hardwareDecodingDescription' => 'Использовать аппаратное ускорение, когда доступно',
			'settings.bufferSize' => 'Размер буфера',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}МБ',
			'settings.bufferSizeAuto' => 'Авто (Рекомендуется)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Доступно памяти: ${heap} МБ. Буфер размером ${size} МБ может повлиять на воспроизведение.',
			'settings.playbackBuffer' => 'Буфер воспроизведения',
			'settings.playbackBufferAuto' => 'Авто (рекомендуется)',
			'settings.playbackBufferLarge' => 'Большой',
			'settings.playbackBufferExtraLarge' => 'Очень большой',
			'settings.playbackBufferDescription' => 'Буферизирует больше при нестабильном соединении. Также ограничено размером буфера.',
			'settings.defaultQualityTitle' => 'Качество по умолчанию',
			'settings.musicQualityTitle' => 'Качество музыки',
			'settings.subtitleStyling' => 'Стиль субтитров',
			'settings.subtitleStylingDescription' => 'Настроить внешний вид субтитров',
			'settings.smallSkipDuration' => 'Малая перемотка',
			'settings.largeSkipDuration' => 'Большая перемотка',
			'settings.rewindOnResume' => 'Перемотка при возобновлении',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} с',
			'settings.defaultSleepTimer' => 'Таймер сна по умолчанию',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} мин',
			'settings.rememberTrackSelections' => 'Запоминать выбор дорожек для каждого сериала/фильма',
			'settings.rememberTrackSelectionsDescription' => 'Запоминать выбор аудиодорожки и субтитров для каждого материала',
			'settings.followServerTrackSelections' => 'Использовать выбор дорожек сервера для каждой серии',
			'settings.followServerTrackSelectionsDescription' => 'При смене серии применять аудио и субтитры, выбранные на сервере, вместо переноса текущего выбора',
			'settings.showChapterMarkersOnTimeline' => 'Показывать маркеры глав на шкале перемотки',
			'settings.showChapterMarkersOnTimelineDescription' => 'Разделять шкалу перемотки по границам глав',
			'settings.clickVideoTogglesPlayback' => 'Нажатие на видео запускает или приостанавливает воспроизведение',
			'settings.clickVideoTogglesPlaybackDescription' => 'Нажатие на видео запускает или приостанавливает воспроизведение вместо показа элементов управления.',
			'settings.videoPlayerControls' => 'Элементы управления плеером',
			'settings.keyboardShortcuts' => 'Горячие клавиши',
			'settings.keyboardShortcutsDescription' => 'Настроить горячие клавиши',
			'settings.videoPlayerNavigation' => 'Навигация видеоплеера',
			'settings.videoPlayerNavigationDescription' => 'Использовать клавиши стрелок для навигации по элементам управления плеером',
			'settings.watchTogetherRelay' => 'Сервер ретрансляции для совместного просмотра',
			'settings.watchTogetherRelayDescription' => 'Задайте свой сервер ретрансляции. Все участники должны использовать один сервер.',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Введите допустимый базовый HTTP- или HTTPS-адрес сервера ретрансляции.',
			'settings.crashReporting' => 'Отчёты об ошибках',
			'settings.crashReportingDescription' => 'Отправлять отчёты об ошибках для улучшения приложения',
			'settings.debugLogging' => 'Журнал отладки',
			'settings.debugLoggingDescription' => 'Включить подробное журналирование для устранения неполадок',
			'settings.viewLogs' => 'Просмотр логов',
			'settings.viewLogsDescription' => 'Просмотр логов приложения',
			'settings.clearImageCache' => 'Очистить кэш изображений',
			'settings.clearImageCacheDescription' => 'Очистить кэшированные обложки и миниатюры. Изображения могут загружаться медленнее, пока не будут загружены снова.',
			'settings.clearImageCacheSuccess' => 'Кэш изображений успешно очищен',
			'settings.resetSettings' => 'Сбросить настройки',
			'settings.resetSettingsDescription' => 'Восстановить настройки по умолчанию. Это нельзя отменить.',
			'settings.resetSettingsSuccess' => 'Настройки успешно сброшены',
			'settings.backup' => 'Резервная копия',
			'settings.exportSettings' => 'Экспорт настроек',
			'settings.exportSettingsDescription' => 'Сохранить настройки в файл',
			'settings.exportSettingsSuccess' => 'Настройки экспортированы',
			'settings.importSettings' => 'Импорт настроек',
			'settings.importSettingsDescription' => 'Восстановить настройки из файла',
			'settings.importSettingsConfirm' => 'Это заменит ваши текущие настройки. Продолжить?',
			'settings.importSettingsSuccess' => 'Настройки импортированы',
			'settings.importSettingsInvalidFile' => 'Этот файл не является действительным экспортом настроек Plezy',
			'settings.importSettingsNoUser' => 'Войдите в систему перед импортом настроек',
			'settings.shortcutsReset' => 'Горячие клавиши сброшены по умолчанию',
			'settings.about' => 'О приложении',
			'settings.aboutDescription' => 'Информация о приложении и лицензии',
			'settings.updates' => 'Обновления',
			'settings.updateAvailable' => 'Доступно обновление',
			'settings.checkForUpdates' => 'Проверить обновления',
			'settings.autoCheckUpdatesOnStartup' => 'Автоматически проверять обновления при запуске',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Уведомлять о доступном обновлении при запуске',
			'settings.validationErrorEnterNumber' => 'Введите корректное число',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Длительность должна быть от ${min} до ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Сочетание клавиш уже назначено действию «${action}»',
			'settings.shortcutUpdated' => ({required Object action}) => 'Сочетание клавиш для действия «${action}» обновлено',
			'settings.saveFailed' => 'Не удалось сохранить изменения. Попробуйте снова.',
			'settings.autoSkip' => 'Автопропуск',
			'settings.autoSkipIntro' => 'Автопропуск вступления',
			'settings.autoSkipIntroDescription' => 'Автоматически пропускать маркеры вступления через несколько секунд',
			'settings.autoSkipCredits' => 'Автопропуск титров',
			'settings.autoSkipCreditsDescription' => 'Автоматически пропускать титры и воспроизводить следующий эпизод',
			'settings.forceSkipMarkerFallback' => 'Всегда использовать резервные маркеры',
			'settings.forceSkipMarkerFallbackDescription' => 'Использовать шаблоны названий глав, даже если в Plex есть собственные маркеры',
			'settings.autoSkipDelay' => 'Задержка автопропуска',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Подождать ${seconds} секунд перед автопропуском',
			'settings.introPattern' => 'Шаблон маркера вступления',
			'settings.introPatternDescription' => 'Регулярное выражение для распознавания маркеров вступления в заголовках глав',
			'settings.creditsPattern' => 'Шаблон маркера титров',
			'settings.creditsPatternDescription' => 'Регулярное выражение для распознавания маркеров титров в заголовках глав',
			'settings.invalidRegex' => 'Недопустимое регулярное выражение',
			'settings.regex' => 'Регулярное выражение',
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
			'settings.downloadLocationPickerUnavailable' => 'Выбор папки недоступен на этом устройстве',
			'settings.downloadOnWifiOnly' => 'Загружать только по Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Запретить загрузку по мобильным данным',
			'settings.autoRemoveWatchedDownloads' => 'Автоудаление просмотренных загрузок',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Автоматически удалять просмотренные загрузки',
			'settings.cellularDownloadBlocked' => 'Загрузки через мобильную сеть заблокированы. Используйте Wi-Fi или измените настройку.',
			'settings.maxVolume' => 'Максимальная громкость',
			'settings.maxVolumeDescription' => 'Разрешить усиление громкости выше 100% для тихих медиа',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Показывать, что вы смотрите, в Discord',
			'settings.services' => 'Сервисы',
			'settings.servicesDescription' => 'Подключите Trakt, MyAnimeList, Seerr и другие',
			'settings.manageLibrariesDescription' => 'Изменять порядок и скрывать библиотеки',
			'settings.companionRemoteServer' => 'Сервер удалённого управления',
			'settings.companionRemoteServerDescription' => 'Разрешить мобильным устройствам в сети управлять этим приложением',
			'settings.autoPip' => 'Автоматический режим «картинка в картинке»',
			'settings.autoPipDescription' => 'Автоматически включать режим «картинка в картинке» при выходе из приложения во время воспроизведения',
			'settings.matchContentFrameRate' => 'Соответствие частоты кадров контента',
			'settings.matchContentFrameRateDescription' => 'Подстраивать частоту обновления экрана под видео',
			'settings.matchRefreshRate' => 'Соответствие частоты обновления',
			'settings.matchRefreshRateDescription' => 'Подстраивать частоту обновления в полноэкранном режиме',
			'settings.matchDynamicRange' => 'Соответствие динамического диапазона',
			'settings.matchDynamicRangeDescription' => 'Включать HDR для HDR-контента, затем возвращаться к SDR',
			'settings.displaySwitchDelay' => 'Задержка переключения дисплея',
			'settings.tunneledPlayback' => 'Туннельное воспроизведение',
			'settings.tunneledPlaybackDescription' => 'Использовать видеотуннелирование. Отключите, если при воспроизведении HDR отображается чёрный экран.',
			'settings.audioPassthrough' => 'Сквозной вывод аудио',
			'settings.audioPassthroughDescription' => 'Передавать звук Dolby/DTS на ресивер или телевизор без перекодирования, сохраняя объёмный звук. Отключите, если нет звука.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Использовать встроенный декодер Dolby от Apple для Dolby Digital Plus, включая Atmos. DTS и TrueHD по-прежнему воспроизводятся как многоканальный PCM. Отключите, если звук отсутствует.',
			'settings.audioDownmix' => 'Микширование в стерео',
			'settings.audioDownmixDescription' => 'Микширует объёмный звук в два канала для стереодинамиков или наушников',
			'settings.downmixCenterBoost' => 'Усиление центрального канала',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} дБ',
			'settings.downmixCenterBoostLabel' => 'Усиление (дБ)',
			'settings.downmixCenterBoostShort' => 'дБ',
			'settings.audioDownmixNormalize' => 'Нормализация громкости при микшировании',
			'settings.audioDownmixNormalizeDescription' => 'Снижает уровень микса во избежание клиппинга. Отключите, чтобы сохранить исходную громкость (возможны искажения в громких сценах).',
			'settings.dvConversionMode' => 'Преобразование Dolby Vision',
			'settings.dvConversionModeDescription' => 'Выберите, как ExoPlayer обрабатывает файлы Dolby Vision Profile 7.',
			'settings.dvConversionAuto' => 'Авто',
			'settings.dvConversionNative' => 'Нативно / отключено',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Использовать определение возможностей устройства и обычное резервное поведение',
			'settings.dvConversionNativeDescription' => 'Принудительно использовать нативный DV7 и не повторять DV-конвертацию',
			'settings.dvConversionDv81Description' => 'Принудительно выполнять inline-конвертацию RPU в Dolby Vision профиль 8.1',
			'settings.dvConversionHevcStripDescription' => 'Удалять слои Dolby Vision RPU/EL и передавать обычный HEVC',
			'settings.requireProfileSelectionOnOpen' => 'Запрашивать профиль при запуске',
			'settings.requireProfileSelectionOnOpenDescription' => 'Показывать выбор профиля при каждом открытии приложения',
			'settings.forceTvMode' => 'Принудительный режим ТВ',
			'settings.forceTvModeDescription' => 'Принудительно включить ТВ-интерфейс. Для устройств без автоопределения. Требуется перезапуск.',
			'settings.startInFullscreen' => 'Запускать в полноэкранном режиме',
			'settings.startInFullscreenDescription' => 'Открывать Plezy в полноэкранном режиме при запуске',
			'settings.exitFullscreenOnPlayerClose' => 'Выходить из полноэкранного режима при закрытии плеера',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Автоматически выходить из полноэкранного режима при закрытии видеоплеера',
			'settings.autoHidePerformanceOverlay' => 'Автоскрытие оверлея производительности',
			'settings.autoHidePerformanceOverlayDescription' => 'Скрывать оверлей производительности вместе с элементами управления воспроизведением',
			'settings.showNavBarLabels' => 'Показывать подписи панели навигации',
			'settings.showNavBarLabelsDescription' => 'Отображать текстовые подписи под иконками панели навигации',
			'settings.startupSection' => 'Начальный раздел',
			'settings.liveTvDefaultFavorites' => 'Избранные каналы по умолчанию',
			'settings.liveTvDefaultFavoritesDescription' => 'Показывать только избранные каналы при открытии ТВ',
			'settings.display' => 'Экран',
			'settings.homeScreen' => 'Главный экран',
			'settings.navigation' => 'Навигация',
			'settings.window' => 'Окно',
			'settings.content' => 'Контент',
			'settings.player' => 'Плеер',
			'settings.subtitlesAndConfig' => 'Субтитры и конфигурация',
			'settings.seekAndTiming' => 'Перемотка и время',
			'settings.behavior' => 'Поведение',
			'search.hint' => 'Поиск фильмов, сериалов, музыки...',
			'search.tryDifferentTerm' => 'Попробуйте другой запрос',
			'search.searchYourMedia' => 'Поиск в вашей медиатеке',
			'search.enterTitleActorOrKeyword' => 'Введите название, актёра или ключевое слово',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Назначить клавишу для ${actionName}',
			'hotkeys.clearShortcut' => 'Очистить клавишу',
			'hotkeys.noShortcutSet' => 'Сочетание не задано',
			'hotkeys.currentShortcut' => 'Текущее сочетание:',
			'hotkeys.pressToRecord' => 'Выберите, чтобы записать сочетание клавиш',
			'hotkeys.recordingShortcut' => 'Нажмите сочетание клавиш сейчас',
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
			'hotkeys.actions.episodeNext' => 'Следующая серия',
			'hotkeys.actions.episodePrevious' => 'Предыдущая серия',
			'hotkeys.actions.speedIncrease' => 'Увеличить скорость',
			'hotkeys.actions.speedDecrease' => 'Уменьшить скорость',
			'hotkeys.actions.speedReset' => 'Сбросить скорость',
			'hotkeys.actions.zoomIn' => 'Увеличить масштаб',
			'hotkeys.actions.zoomOut' => 'Уменьшить масштаб',
			'hotkeys.actions.zoomReset' => 'Сбросить масштаб',
			'hotkeys.actions.subSeekNext' => 'К следующему субтитру',
			'hotkeys.actions.subSeekPrev' => 'К предыдущему субтитру',
			'hotkeys.actions.shaderToggle' => 'Вкл./выкл. шейдеры',
			'hotkeys.actions.skipMarker' => 'Пропустить вступление/титры',
			'hotkeys.actions.screenshot' => 'Сделать снимок экрана',
			'fileInfo.title' => 'Информация о файле',
			'fileInfo.overview' => 'Обзор',
			'fileInfo.video' => 'Видео',
			'fileInfo.audio' => 'Аудио',
			'fileInfo.subtitles' => 'Субтитры',
			'fileInfo.images' => 'Встроенные изображения',
			'fileInfo.dataStreams' => 'Потоки данных',
			'fileInfo.lyrics' => 'Текст песни',
			'fileInfo.file' => 'Файл',
			'fileInfo.attachments' => 'Вложения',
			'fileInfo.delivery' => 'Доставка',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Версия ${index} из ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Файл ${index} из ${count}',
			'fileInfo.noStreams' => 'Сервер не сообщил о потоках для этого файла.',
			'fileInfo.copyPath' => 'Копировать путь',
			'fileInfo.pathCopied' => 'Путь к файлу скопирован',
			'fileInfo.codec' => 'Кодек',
			'fileInfo.codecTag' => 'Тег кодека',
			'fileInfo.resolution' => 'Разрешение',
			'fileInfo.codedResolution' => 'Кодированное разрешение',
			'fileInfo.bitrate' => 'Битрейт',
			'fileInfo.frameRate' => 'Частота кадров',
			'fileInfo.rotation' => 'Поворот',
			'fileInfo.comment' => 'Комментарий',
			'fileInfo.audioDescription' => 'Аудиоописание',
			'fileInfo.headerCompression' => 'Сжатие заголовков',
			'fileInfo.sidecarFile' => 'Файл-спутник',
			'fileInfo.transportTimestamp' => 'Метка времени транспорта',
			'fileInfo.displayOffset' => 'Смещение отображения',
			'fileInfo.previewFailureCode' => 'Код ошибки превью',
			'fileInfo.previewRetries' => 'Повторные попытки превью',
			'fileInfo.aspectRatio' => 'Соотношение сторон',
			'fileInfo.pixelAspectRatio' => 'Попиксельное соотношение сторон',
			'fileInfo.profile' => 'Профиль',
			'fileInfo.level' => 'Уровень',
			'fileInfo.bitDepth' => 'Глубина цвета',
			'fileInfo.pixelFormat' => 'Формат пикселей',
			'fileInfo.colorSpace' => 'Цветовое пространство',
			'fileInfo.colorRange' => 'Цветовой диапазон',
			'fileInfo.colorPrimaries' => 'Основные цвета',
			'fileInfo.colorTransfer' => 'Передача цвета',
			'fileInfo.chromaSubsampling' => 'Субдискретизация цветности',
			'fileInfo.chromaLocation' => 'Расположение цветности',
			'fileInfo.scanType' => 'Тип развёртки',
			'fileInfo.interlaced' => 'Чересстрочный',
			'fileInfo.anamorphic' => 'Анаморфный',
			'fileInfo.referenceFrames' => 'Опорные кадры',
			'fileInfo.dynamicRange' => 'Динамический диапазон',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Уровень Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Версия Dolby Vision',
			'fileInfo.dolbyVisionLayers' => 'Слои Dolby Vision',
			'fileInfo.baseLayerCompatibility' => 'Совместимость базового слоя',
			'fileInfo.avcBitstream' => 'Битовый поток AVC',
			'fileInfo.nalLengthSize' => 'Размер длины NAL',
			'fileInfo.scalingMatrix' => 'Пользовательская матрица масштабирования',
			'fileInfo.streamIdentifier' => 'Идентификатор потока',
			'fileInfo.streamIndex' => 'Индекс потока',
			'fileInfo.streamId' => 'ID потока',
			'fileInfo.language' => 'Язык',
			'fileInfo.languageCode' => 'Код языка',
			'fileInfo.streamTitle' => 'Название дорожки',
			'fileInfo.channels' => 'Каналы',
			'fileInfo.sampleRate' => 'Частота дискретизации',
			'fileInfo.spatialAudio' => 'Пространственное аудио',
			'fileInfo.textBased' => 'Текстовый',
			'fileInfo.subtitleFormat' => 'Формат файла-спутника',
			'fileInfo.provider' => 'Провайдер',
			'fileInfo.matchScore' => 'Оценка совпадения',
			'fileInfo.externalDelivery' => 'Может передаваться отдельно',
			'fileInfo.sidecarPath' => 'Путь к файлу-спутнику',
			'fileInfo.sourceStream' => 'Скопировано из',
			'fileInfo.temporary' => 'Временный',
			'fileInfo.timeBase' => 'Временная база',
			'fileInfo.overallBitrate' => 'Общий битрейт',
			'fileInfo.path' => 'Путь',
			'fileInfo.fileName' => 'Имя файла',
			'fileInfo.size' => 'Размер',
			'fileInfo.totalSize' => 'Общий размер',
			'fileInfo.container' => 'Контейнер',
			'fileInfo.duration' => 'Длительность',
			'fileInfo.previewThumbnails' => 'Миниатюры превью',
			'fileInfo.previewIndex' => 'Индекс превью',
			'fileInfo.packetLength' => 'Длина пакета',
			'fileInfo.filePresent' => 'Файл присутствует',
			'fileInfo.fileReadable' => 'Доступен для чтения сервером',
			'fileInfo.streamPath' => 'Путь потока',
			'fileInfo.optimizedForStreaming' => 'Оптимизировано для потоковой передачи',
			'fileInfo.has64bitOffsets' => '64-битные смещения',
			'fileInfo.protocol' => 'Протокол',
			'fileInfo.mediaType' => 'Тип медиа',
			'fileInfo.sourceKind' => 'Тип источника',
			'fileInfo.optimizedVersion' => 'Оптимизированная версия',
			'fileInfo.optimizationTarget' => 'Цель оптимизации',
			'fileInfo.deletedAt' => 'Удалено',
			'fileInfo.remoteSource' => 'Удалённый источник',
			'fileInfo.infiniteStream' => 'Бесконечный поток',
			'fileInfo.directPlay' => 'Прямое воспроизведение',
			'fileInfo.directStream' => 'Прямой поток',
			'fileInfo.transcoding' => 'Транскодирование',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID версии',
			'fileInfo.fileId' => 'ID файла',
			'fileInfo.defaultAudioTrack' => 'Аудиодорожка по умолчанию',
			'fileInfo.defaultSubtitleTrack' => 'Дорожка субтитров по умолчанию',
			'fileInfo.subtitlesOff' => 'Выкл.',
			'fileInfo.flagDefault' => 'По умолчанию',
			'fileInfo.flagForced' => 'Принудительная',
			'fileInfo.flagSelected' => 'Выбрана',
			'fileInfo.flagExternal' => 'Внешняя',
			'fileInfo.flagHearingImpaired' => 'Для слабослышащих',
			'fileInfo.flagDub' => 'Дубляж',
			'fileInfo.flagOriginal' => 'Оригинал',
			'mediaMenu.markAsWatched' => 'Отметить как просмотренное',
			'mediaMenu.markAsUnwatched' => 'Отметить как непросмотренное',
			'mediaMenu.removeFromContinueWatching' => 'Удалить из «Продолжить просмотр»',
			'mediaMenu.viewDetails' => 'Показать сведения',
			'mediaMenu.goToSeries' => 'Перейти к сериалу',
			'mediaMenu.shufflePlay' => 'Случайное воспроизведение',
			'mediaMenu.shuffleNotAvailableOffline' => 'Перемешивание недоступно офлайн',
			'mediaMenu.fileInfo' => 'Информация о файле',
			'mediaMenu.deleteEpisodeFromServer' => 'Удалить эпизод с сервера',
			'mediaMenu.deleteSeasonFromServer' => 'Удалить сезон с сервера',
			'mediaMenu.deleteShowFromServer' => 'Удалить сериал с сервера',
			'mediaMenu.deleteMovieFromServer' => 'Удалить фильм с сервера',
			'mediaMenu.deleteEpisodeTitle' => 'Удалить этот эпизод?',
			'mediaMenu.deleteSeasonTitle' => 'Удалить этот сезон?',
			'mediaMenu.deleteShowTitle' => 'Удалить этот сериал?',
			'mediaMenu.deleteMovieTitle' => 'Удалить этот фильм?',
			'mediaMenu.deleteEpisodeConfirm' => 'Удалить эпизод',
			'mediaMenu.deleteSeasonConfirm' => 'Удалить сезон',
			'mediaMenu.deleteShowConfirm' => 'Удалить сериал',
			'mediaMenu.deleteMovieConfirm' => 'Удалить фильм',
			'mediaMenu.deleteAnyway' => 'Всё равно удалить',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Навсегда удалить ${title} с вашего сервера?',
			'mediaMenu.deleteMultipleWarning' => 'Это включает все эпизоды и их файлы.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: 'Это удалит содержащийся в нём ${n} эпизод и его файл.', few: 'Это удалит содержащиеся в нём ${n} эпизода и их файлы.', many: 'Это удалит содержащиеся в нём ${n} эпизодов и их файлы.', other: 'Это удалит содержащиеся в нём ${n} эпизодов и их файлы.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: 'Этот элемент хранится как ${n} файл, который будет удалён.', few: 'Этот элемент хранится в ${n} файлах, и все они будут удалены.', many: 'Этот элемент хранится в ${n} файлах, и все они будут удалены.', other: 'Этот элемент хранится в ${n} файлах, и все они будут удалены.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: 'В этом же файле хранится ещё ${n} эпизод, и он тоже будет удалён:', few: 'В этом же файле хранятся ещё ${n} эпизода, и они тоже будут удалены:', many: 'В этом же файле хранятся ещё ${n} эпизодов, и они тоже будут удалены:', other: 'В этом же файле хранятся ещё ${n} эпизодов, и они тоже будут удалены:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy не смог проверить, какие файлы будут удалены, поэтому может быть удалено больше, чем указанный выше элемент. Отмените и попробуйте снова либо удалите в любом случае.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Ваш сервер не предоставил сведения о файлах для этого элемента, поэтому Plezy не может проверить, какие файлы будут удалены. Может быть удалено больше, чем указанный выше элемент.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Медиаэлемент успешно удалён',
			'mediaMenu.mediaFailedToDelete' => 'Не удалось удалить медиаэлемент',
			'mediaMenu.rate' => 'Оценить',
			'mediaMenu.playFromBeginning' => 'Воспроизвести сначала',
			'mediaMenu.playVersion' => 'Воспроизвести версию...',
			'rateSheet.title' => 'Оценить',
			'rateSheet.server' => 'Сервер',
			'rateSheet.favorite' => 'Добавить в избранное',
			'rateSheet.favorited' => 'Добавлено в избранное',
			'rateSheet.saved' => 'Сохранено',
			'rateSheet.notAvailable' => 'Совпадений не найдено',
			'rateSheet.noConnectedServices' => 'Подключите сервис в настройках, чтобы выставлять оценки в нём.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, фильм',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, сериал',
			_ => null,
		} ?? switch (path) {
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'просмотрено',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => 'просмотрено ${percent} процентов',
			'accessibility.mediaCardUnwatched' => 'не просмотрено',
			'accessibility.tapToPlay' => 'Нажмите для воспроизведения',
			'accessibility.decrease' => 'Уменьшить',
			'accessibility.increase' => 'Увеличить',
			'accessibility.decreaseValue' => ({required Object label}) => 'Уменьшить ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Увеличить ${label}',
			'accessibility.hue' => 'Цветовой тон',
			'accessibility.saturation' => 'Насыщенность',
			'accessibility.brightness' => 'Яркость',
			'accessibility.hexColor' => 'Шестнадцатеричный цвет',
			'accessibility.expandText' => 'Развернуть текст',
			'accessibility.collapseText' => 'Свернуть текст',
			'accessibility.alphabetNavigation' => 'Навигация по алфавиту',
			'accessibility.alphabetScrollHint' => 'Проведите вверх или вниз для перехода по буквам',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Строка ${row} из ${rowCount}, столбец ${column} из ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Строка ${row} из ${rowCount}',
			'tooltips.shufflePlay' => 'Случайное воспроизведение',
			'tooltips.playTrailer' => 'Воспроизвести трейлер',
			'tooltips.markAsWatched' => 'Отметить как просмотренное',
			'tooltips.markAsUnwatched' => 'Отметить как непросмотренное',
			'audioTracks.track' => ({required Object n}) => 'Аудиодорожка ${n}',
			'videoControls.audioLabel' => 'Аудио',
			'videoControls.subtitlesLabel' => 'Субтитры',
			'videoControls.resetToZero' => 'Сбросить до 0мс',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} воспроизводится позже',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} воспроизводится раньше',
			'videoControls.noOffset' => 'Без смещения',
			'videoControls.letterbox' => 'Вписать в экран',
			'videoControls.fillScreen' => 'Заполнить экран',
			'videoControls.stretch' => 'Растянуть',
			'videoControls.lockRotation' => 'Заблокировать поворот',
			'videoControls.unlockRotation' => 'Разблокировать поворот',
			'videoControls.timerActive' => 'Таймер активен',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Воспроизведение будет приостановлено через ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Конец текущего видео',
			'videoControls.sleepTimerStopAtHeader' => 'Остановить на',
			'videoControls.sleepTimerDurationHeader' => 'Таймер',
			'videoControls.playbackWillPauseAtEnd' => 'Воспроизведение будет приостановлено в конце этого видео',
			'videoControls.stillWatching' => 'Всё ещё смотрите?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Пауза через ${seconds}с',
			'videoControls.continueWatching' => 'Продолжить',
			'videoControls.autoPlayNext' => 'Автовоспроизведение следующего',
			'videoControls.playNext' => 'Следующее',
			'videoControls.playButton' => 'Воспроизвести',
			'videoControls.pauseButton' => 'Пауза',
			'videoControls.playbackPaused' => 'На паузе',
			'videoControls.playbackResumed' => 'Воспроизведение',
			'videoControls.loadingVideo' => 'Загрузка видео',
			'videoControls.showPlaybackControls' => 'Показать элементы управления воспроизведением',
			'videoControls.hidePlaybackControls' => 'Скрыть элементы управления воспроизведением',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Перемотать назад на ${seconds} с',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Перемотать вперёд на ${seconds} с',
			'videoControls.previousButton' => 'Предыдущий эпизод',
			'videoControls.nextButton' => 'Следующий эпизод',
			'videoControls.previousChapterButton' => 'Предыдущая глава',
			'videoControls.nextChapterButton' => 'Следующая глава',
			'videoControls.muteButton' => 'Без звука',
			'videoControls.unmuteButton' => 'Включить звук',
			'videoControls.settingsButton' => 'Настройки воспроизведения',
			'videoControls.tracksButton' => 'Аудио и субтитры',
			'videoControls.chaptersButton' => 'Главы',
			'videoControls.versionQualityButton' => 'Версия и качество',
			'videoControls.versionColumnHeader' => 'Версия',
			'videoControls.qualityColumnHeader' => 'Качество',
			'videoControls.qualityOriginal' => 'Оригинал',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Мбит/с',
			'videoControls.transcodeUnavailableFallback' => 'Транскодирование недоступно — воспроизведение в оригинальном качестве',
			'videoControls.subtitleUnavailableFallback' => 'Не удалось загрузить выбранные субтитры — воспроизведение продолжится без субтитров',
			'videoControls.pipButton' => 'Режим «картинка в картинке»',
			'videoControls.aspectRatioButton' => 'Соотношение сторон',
			'videoControls.ambientLighting' => 'Фоновая подсветка',
			'videoControls.fullscreenButton' => 'Полноэкранный режим',
			'videoControls.exitFullscreenButton' => 'Выйти из полноэкранного режима',
			'videoControls.alwaysOnTopButton' => 'Всегда поверх',
			'videoControls.rotationLockButton' => 'Блокировка поворота',
			'videoControls.lockScreen' => 'Заблокировать экран',
			'videoControls.screenLockButton' => 'Блокировка экрана',
			'videoControls.longPressToUnlock' => 'Удерживайте для разблокировки',
			'videoControls.timelineSlider' => 'Временная шкала',
			'videoControls.volumeSlider' => 'Уровень громкости',
			'videoControls.endsAt' => ({required Object time}) => 'Закончится в ${time}',
			'videoControls.pipActive' => 'Воспроизводится в режиме «картинка в картинке»',
			'videoControls.pipFailed' => 'Не удалось запустить режим «картинка в картинке»',
			'videoControls.screenshotSaved' => 'Снимок экрана сохранён',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Масштаб ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Требуется Android 8.0 или новее',
			'videoControls.pipErrors.iosVersion' => 'Требуется iOS 15.0 или новее',
			'videoControls.pipErrors.permissionDisabled' => 'Режим «картинка в картинке» отключён. Включите его в системных настройках.',
			'videoControls.pipErrors.notSupported' => 'Устройство не поддерживает режим «картинка в картинке»',
			'videoControls.pipErrors.voSwitchFailed' => 'Не удалось переключить видеовыход для «картинки в картинке»',
			'videoControls.pipErrors.failed' => 'Не удалось запустить режим «картинка в картинке»',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Произошла ошибка: ${error}',
			'videoControls.chapters' => 'Главы',
			'videoControls.noChaptersAvailable' => 'Главы недоступны',
			'videoControls.queue' => 'Очередь',
			'videoControls.noQueueItems' => 'В очереди нет элементов',
			'videoControls.noAudioDevicesAvailable' => 'Нет доступных аудиоустройств',
			'videoControls.searchSubtitles' => 'Поиск субтитров',
			'videoControls.language' => 'Язык',
			'videoControls.noSubtitlesFound' => 'Субтитры не найдены',
			'videoControls.subtitleDownloaded' => 'Субтитры загружены',
			'videoControls.subtitleDownloadedNotApplied' => 'Субтитры загружены, но их не удалось выбрать',
			'videoControls.subtitleDownloadFailed' => 'Не удалось загрузить субтитры',
			'videoControls.searchLanguages' => 'Поиск языков...',
			'messages.markedAsWatched' => 'Отмечено как просмотренное',
			'messages.markedAsUnwatched' => 'Отмечено как непросмотренное',
			'messages.markedAsWatchedOffline' => 'Отмечено как просмотренное (синхронизируется при подключении)',
			'messages.markedAsUnwatchedOffline' => 'Отмечено как непросмотренное (синхронизируется при подключении)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Автоудалено: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: 'Автоматически удалена ${n} просмотренная загрузка', few: 'Автоматически удалены ${n} просмотренные загрузки', many: 'Автоматически удалено ${n} просмотренных загрузок', other: 'Автоматически удалено ${n} просмотренной загрузки', ), 
			'messages.removedFromContinueWatching' => 'Удалено из «Продолжить просмотр»',
			'messages.errorLoading' => ({required Object error}) => 'Ошибка: ${error}',
			'messages.searchPartialResults' => 'Поиск по некоторым медиасерверам не удался. Показываем доступные результаты.',
			'messages.streamInterrupted' => 'Поток прервался. Нажмите «Воспроизвести» или перемотайте, чтобы повторить попытку.',
			'messages.liveStreamInterrupted' => 'Прямая трансляция прервалась. Нажмите «Воспроизвести», чтобы повторить попытку.',
			'messages.fileInfoNotAvailable' => 'Информация о файле недоступна',
			'messages.playbackAuthenticationRequired' => 'Чтобы воспроизвести этот материал, снова войдите на медиасервер.',
			'messages.playbackServerUnavailable' => 'Медиасервер недоступен. Попробуйте позже.',
			'messages.playbackDataInvalid' => 'Сервер вернул некорректные сведения для воспроизведения.',
			'messages.playbackCancelled' => 'Воспроизведение отменено.',
			'messages.playbackFailed' => 'Не удалось начать воспроизведение.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Ошибка загрузки информации о файле: ${error}',
			'messages.errorLoadingSeries' => 'Ошибка загрузки сериала',
			'messages.musicNotSupported' => 'Воспроизведение музыки пока не поддерживается',
			'messages.noDescriptionAvailable' => 'Описание недоступно',
			'messages.noProfilesAvailable' => 'Профили недоступны',
			'messages.contactAdminForProfiles' => 'Обратитесь к администратору сервера для добавления профилей',
			'messages.unableToDetermineLibrarySection' => 'Не удаётся определить раздел библиотеки для этого элемента',
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
			'messages.seasonsLoadFailed' => 'Не удалось загрузить сезоны',
			'messages.noEpisodesFound' => 'Эпизоды в первом сезоне не найдены',
			'messages.noEpisodesFoundGeneral' => 'Эпизоды не найдены',
			'messages.episodesLoadFailed' => 'Не удалось загрузить эпизоды',
			'messages.noResultsFound' => 'Результаты не найдены',
			'messages.sleepTimerSet' => ({required Object label}) => 'Таймер сна установлен на ${label}',
			'messages.noItemsAvailable' => 'Нет доступных элементов',
			'messages.failedToCreatePlayQueueNoItems' => 'Не удалось создать очередь воспроизведения — нет элементов',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Не удалось ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Переключение на совместимый плеер...',
			'messages.serverLimitTitle' => 'Ошибка воспроизведения',
			'messages.serverLimitBody' => 'Ошибка сервера (HTTP 500). Лимит пропускной способности/транскодирования, вероятно, отклонил сессию. Попросите владельца изменить настройки.',
			'messages.mediaUnreadableTitle' => 'Файл недоступен',
			'messages.mediaUnreadableBody' => 'Сервер нашёл этот элемент, но не смог прочитать его файл (HTTP 404). Вероятно, файл был перемещён, удалён или его хранилище недоступно. Попросите владельца сервера проверить файл и пересканировать библиотеку.',
			'messages.logsUploaded' => 'Логи загружены',
			'messages.logsUploadFailed' => 'Не удалось загрузить логи',
			'messages.logId' => 'ID лога',
			'subtitlingStyling.text' => 'Текст',
			'subtitlingStyling.border' => 'Обводка',
			'subtitlingStyling.background' => 'Фон',
			'subtitlingStyling.fontSize' => 'Размер шрифта',
			'subtitlingStyling.textColor' => 'Цвет текста',
			'subtitlingStyling.borderSize' => 'Размер обводки',
			'subtitlingStyling.borderColor' => 'Цвет обводки',
			'subtitlingStyling.backgroundOpacity' => 'Прозрачность фона',
			'subtitlingStyling.backgroundColor' => 'Цвет фона',
			'subtitlingStyling.position' => 'Позиция',
			'subtitlingStyling.assOverride' => 'Переопределение ASS',
			'subtitlingStyling.overrideScale' => 'Масштаб',
			'subtitlingStyling.overrideForce' => 'Принудительно',
			'subtitlingStyling.overrideStrip' => 'Удалить стили',
			'subtitlingStyling.positionTop' => 'Сверху',
			'subtitlingStyling.positionBottom' => 'Снизу',
			'subtitlingStyling.bold' => 'Жирный',
			'subtitlingStyling.italic' => 'Курсив',
			'subtitlingStyling.renderResolution' => 'Разрешение отрисовки',
			'subtitlingStyling.renderResolutionScreen' => 'Разрешение экрана',
			'subtitlingStyling.renderResolutionVideo' => 'Разрешение видео',
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
			'profiles.addPlezyProfile' => 'Добавить профиль Plezy',
			'profiles.switchingProfile' => 'Переключение профиля…',
			'profiles.deleteThisProfileTitle' => 'Удалить этот профиль?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Удалить ${displayName}. Подключения не изменятся.',
			'profiles.active' => 'Активный',
			'profiles.manage' => 'Управление',
			'profiles.delete' => 'Удалить',
			'profiles.signOut' => 'Выйти',
			'profiles.signOutPlexTitle' => 'Выйти из Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Удалить ${displayName} и всех пользователей Plex Home? Вы сможете войти снова в любое время.',
			'profiles.signedOutPlex' => 'Вы вышли из Plex.',
			'profiles.signOutFailed' => 'Не удалось выйти.',
			'profiles.sectionTitle' => 'Профили',
			'profiles.summarySingle' => 'Добавляйте профили, чтобы сочетать управляемых пользователей и локальные профили',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} профилей · активный: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} профилей',
			'profiles.removeConnectionTitle' => 'Удалить соединение?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Удалить доступ ${displayName} к ${connectionLabel}. У других профилей он останется.',
			'profiles.deleteProfileTitle' => 'Удалить профиль?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Удалить ${displayName} и его подключения. Серверы останутся доступны.',
			'profiles.profileNameLabel' => 'Имя профиля',
			'profiles.pinProtectionLabel' => 'Защита PIN-кодом',
			'profiles.pinManagedByPlex' => 'PIN управляется Plex. Редактируйте на plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'PIN не установлен. Чтобы требовать его, отредактируйте пользователя Home на plex.tv.',
			'profiles.setPin' => 'Установить PIN',
			'profiles.setPinTitle' => 'Установить PIN',
			'profiles.confirmPinTitle' => 'Подтвердить PIN',
			'profiles.pinSet' => 'PIN установлен',
			'profiles.changePin' => 'Изменить',
			'profiles.removePin' => 'Удалить',
			'profiles.connectionsLabel' => 'Соединения',
			'profiles.add' => 'Добавить',
			'profiles.deleteProfileButton' => 'Удалить профиль',
			'profiles.noConnectionsHint' => 'Нет соединений — добавьте одно, чтобы использовать этот профиль.',
			'profiles.noConnections' => 'Нет соединений',
			'profiles.plexHomeAccount' => 'Аккаунт Plex Home',
			'profiles.plexAccountChip' => ({required Object account}) => 'Аккаунт Plex: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} через ${account}',
			'profiles.connectionDefault' => 'По умолчанию',
			'profiles.connectionAs' => ({required Object displayName}) => 'как ${displayName}',
			'profiles.makeDefault' => 'Сделать по умолчанию',
			'profiles.removeConnection' => 'Удалить',
			'profiles.profileRenamed' => 'Профиль переименован.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Добавить в ${displayName}',
			'profiles.borrowExplain' => 'Используйте подключение другого профиля. Для защищённых профилей потребуется PIN.',
			'profiles.borrowEmpty' => 'Пока нет доступных подключений.',
			'profiles.borrowEmptySubtitle' => 'Сначала подключите Plex или Jellyfin к другому профилю.',
			'profiles.borrowLoadFailed' => 'Не удалось загрузить доступные подключения. Попробуйте снова.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'От ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Подключение добавлено.',
			'profiles.borrowFailed' => 'Не удалось добавить подключение.',
			'profiles.incorrectPin' => 'Неверный PIN.',
			'profiles.incorrectPinTryAgain' => 'Неверный PIN. Попробуйте ещё раз.',
			'profiles.sourceProfileMissingParentAccount' => 'У исходного профиля отсутствует родительская учётная запись.',
			'profiles.failedToLoadHomeUsers' => 'Не удалось загрузить пользователей Plex Home. Проверьте подключение и попробуйте ещё раз.',
			'profiles.failedToVerifyPin' => 'Не удалось проверить PIN.',
			'profiles.newProfile' => 'Новый профиль',
			'profiles.profileNameHint' => 'например, Гости, Дети, Семейная комната',
			'profiles.pinProtectionOptional' => 'Защита PIN-кодом (необязательно)',
			'profiles.pinExplain' => 'Для переключения профилей нужен 4-значный PIN.',
			'profiles.continueButton' => 'Продолжить',
			'profiles.pinsDontMatch' => 'PIN-коды не совпадают',
			'connections.sectionTitle' => 'Подключения',
			'connections.addConnection' => 'Добавить подключение',
			'connections.addConnectionSubtitleNoProfile' => 'Войдите через Plex или подключите сервер Jellyfin',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Добавить к ${displayName}: Plex, Jellyfin или подключение другого профиля',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Сессия истекла для ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Сессия истекла для ${count} серверов',
			'connections.signInAgain' => 'Войти снова',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Изменить подключение ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Добавьте или удалите URL-адреса для ${serverName}. Plezy будет использовать доступный URL с наименьшей задержкой.',
			'discover.title' => 'Обзор',
			'discover.noContentAvailable' => 'Контент недоступен',
			'discover.addMediaToLibraries' => 'Добавьте медиафайлы в ваши библиотеки',
			'discover.continueWatching' => 'Продолжить просмотр',
			'discover.continueWatchingIn' => ({required Object library}) => 'Продолжить просмотр в ${library}',
			'discover.nextUp' => 'Далее',
			'discover.nextUpIn' => ({required Object library}) => 'Далее в ${library}',
			'discover.recentlyAdded' => 'Недавно добавленное',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Недавно добавленное в ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Последние альбомы в ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Недавно прослушанное в ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Часто прослушиваемое в ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Обзор',
			'discover.cast' => 'В ролях',
			'discover.extras' => 'Трейлеры и доп. материалы',
			'discover.studio' => 'Студия',
			'discover.rating' => 'Рейтинг',
			'discover.director' => 'Режиссёр',
			'discover.directors' => 'Режиссёры',
			'discover.movie' => 'Фильм',
			'discover.tvShow' => 'Сериал',
			'discover.minutesLeft' => ({required Object minutes}) => 'Осталось ${minutes} мин',
			'discover.moreLikeThis' => 'Похожее',
			'errors.searchFailed' => ({required Object error}) => 'Ошибка поиска: ${error}',
			'errors.searchUnavailable' => 'Поиску не удалось связаться ни с одним медиасервером.',
			'errors.connectionTimeout' => ({required Object context}) => 'Таймаут подключения при загрузке ${context}',
			'errors.connectionFailed' => 'Не удалось подключиться к медиасерверу',
			'errors.unableToLoad' => ({required Object context}) => 'Не удалось загрузить ${context}. Повторите попытку.',
			'errors.noClientAvailable' => 'Клиент недоступен',
			'errors.pleaseEnterToken' => 'Введите токен',
			'errors.invalidToken' => 'Недействительный токен',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Не удалось проверить токен: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Не удалось переключиться на ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Не удалось удалить ${displayName}',
			'errors.failedToRate' => 'Не удалось обновить оценку',
			'libraries.title' => 'Библиотеки',
			'libraries.fallbackTitle' => 'Библиотека',
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
			'libraries.allLibrariesHidden' => 'Все библиотеки скрыты',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Скрытые библиотеки (${count})',
			'libraries.thisLibraryIsEmpty' => 'Эта библиотека пуста',
			'libraries.noItemsMatchFilters' => 'Нет элементов, соответствующих активным фильтрам',
			'libraries.resetFilters' => 'Сбросить фильтры',
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
			'libraries.groupings.title' => 'Группировка',
			'libraries.groupings.all' => 'Все',
			'libraries.groupings.movies' => 'Фильмы',
			'libraries.groupings.shows' => 'Сериалы',
			'libraries.groupings.seasons' => 'Сезоны',
			'libraries.groupings.episodes' => 'Эпизоды',
			'libraries.groupings.artists' => 'Исполнители',
			'libraries.groupings.albums' => 'Альбомы',
			'libraries.groupings.tracks' => 'Треки',
			'libraries.groupings.folders' => 'Папки',
			'libraries.filterCategories.genre' => 'Жанр',
			'libraries.filterCategories.year' => 'Год',
			'libraries.filterCategories.contentRating' => 'Возрастной рейтинг',
			'libraries.filterCategories.tag' => 'Тег',
			'libraries.filterCategories.unwatched' => 'Непросмотренные',
			'libraries.filterCategories.unplayed' => 'Не прослушано',
			'libraries.filterCategories.favorites' => 'Избранное',
			'libraries.sortLabels.title' => 'Название',
			'libraries.sortLabels.dateAdded' => 'Дата добавления',
			'libraries.sortLabels.releaseDate' => 'Дата выхода',
			'libraries.sortLabels.rating' => 'Рейтинг',
			'libraries.sortLabels.communityRating' => 'Оценка сообщества',
			'libraries.sortLabels.criticRating' => 'Оценка критиков',
			'libraries.sortLabels.userRating' => 'Пользовательская оценка',
			'libraries.sortLabels.datePlayed' => 'Дата просмотра',
			'libraries.sortLabels.playCount' => 'Количество просмотров',
			'libraries.sortLabels.productionYear' => 'Год производства',
			'libraries.sortLabels.runtime' => 'Длительность',
			'libraries.sortLabels.officialRating' => 'Официальный рейтинг',
			'libraries.sortLabels.premiereDate' => 'Дата премьеры',
			'libraries.sortLabels.startDate' => 'Дата начала',
			'libraries.sortLabels.airTime' => 'Время эфира',
			'libraries.sortLabels.studio' => 'Студия',
			'libraries.sortLabels.random' => 'Случайно',
			'libraries.sortLabels.dateShared' => 'Дата открытия доступа',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Дата выхода последнего эпизода',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Дата добавления последнего эпизода',
			'about.title' => 'О приложении',
			'about.openSourceLicenses' => 'Лицензии открытого ПО',
			'about.versionLabel' => ({required Object version}) => 'Версия ${version}',
			'about.appDescription' => 'Красивый клиент Plex и Jellyfin на Flutter',
			'about.viewLicensesDescription' => 'Просмотр лицензий сторонних библиотек',
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
			'startup.failedTitle' => 'Plezy не удалось запустить',
			'startup.failedBody' => 'Во время запуска что-то пошло не так. Сведения ниже показывают, что именно не удалось.',
			'startup.failedBodyRepairable' => 'Сохранённый файл настроек Plezy повреждён, и его необходимо пересоздать, прежде чем Plezy сможет запуститься. Повторные попытки не помогут — выберите «Восстановить хранилище».',
			'startup.phaseLabel' => 'Шаг',
			'startup.showDetails' => 'Показать сведения',
			'startup.hideDetails' => 'Скрыть сведения',
			'startup.copyDetails' => 'Копировать сведения',
			'startup.detailsCopied' => 'Сведения скопированы в буфер обмена',
			'startup.uploadDetails' => 'Отправить сведения',
			'startup.repairStorage' => 'Восстановить хранилище',
			'startup.repairTitle' => 'Восстановить сохранённые данные?',
			'startup.repairBodyCommon' => 'Файл настроек Plezy повреждён и не может быть прочитан. Восстановление сбросит все настройки к значениям по умолчанию.',
			'startup.repairBodyOneCredential' => 'Одна сохранённая учётная запись повреждена и не может быть прочитана. Восстановление удалит только её; остальные настройки не будут затронуты.',
			'startup.repairBodySignInsKept' => 'Вход в ваши серверы и профили будет сохранён.',
			'startup.repairBodySignInsLost' => 'Ключ, защищающий сохранённые входы, невозможно восстановить из этого файла, поэтому вам придётся снова войти на каждый сервер и в каждый профиль. На вашем медиасервере ничего не изменится.',
			'startup.repairBodySessionsUncertain' => 'Трекеры (MAL, AniList, Simkl, Trakt) и Seerr хранятся отдельно и могут сохраниться или нет. Plezy точно сообщит, что удалось сохранить.',
			'startup.repairConfirm' => 'Восстановить',
			'startup.repairSucceeded' => 'Хранилище восстановлено',
			'startup.repairNeedsRestart' => 'Хранилище восстановлено — требуется перезапуск',
			'startup.restartRequiredBody' => 'Ваши данные были восстановлены, но Plezy должен запуститься заново, чтобы использовать их. Закройте Plezy и откройте его снова.',
			'startup.quitPlezy' => 'Выйти из Plezy',
			'startup.repairFailed' => 'Не удалось восстановить',
			'startup.repairKeptSignIns' => 'Ваши серверы и профили по-прежнему в системе.',
			'startup.repairLostSignIns' => 'Ключ, защищающий сохранённые входы, не удалось восстановить. Вам придётся снова войти на каждый сервер и в каждый профиль.',
			'startup.repairLostSessions' => 'Потеряно как минимум одно подключение трекера или Seerr — его нужно восстановить.',
			'startup.backupTitle' => 'Сохранена копия повреждённого файла',
			'startup.backupWarning' => 'Она содержит ваши учётные данные для входа. Не загружайте и не передавайте её.',
			'startup.deleteBackup' => 'Удалить копию',
			'startup.backupDeleted' => 'Копия удалена.',
			'startup.previousFailureTitle' => 'В прошлый раз Plezy не удалось запустить',
			'licenses.relatedPackages' => 'Связанные пакеты',
			'licenses.license' => 'Лицензия',
			'licenses.licenseNumber' => ({required Object number}) => 'Лицензия ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} лицензий',
			'navigation.libraries' => 'Библиотеки',
			'navigation.downloads' => 'Загрузки',
			'navigation.liveTv' => 'Прямой эфир',
			'navigation.explore' => 'Обзор',
			'explore.title' => 'Обзор',
			'explore.selectSource' => 'Выбрать источник',
			'explore.rows.watchlist' => 'Список для просмотра',
			'explore.rows.recommendedMovies' => 'Рекомендуемые фильмы',
			'explore.rows.recommendedShows' => 'Рекомендуемые сериалы',
			'explore.rows.trendingMovies' => 'Фильмы в тренде',
			'explore.rows.trendingShows' => 'Сериалы в тренде',
			'explore.rows.popularMovies' => 'Популярные фильмы',
			'explore.rows.popularShows' => 'Популярные сериалы',
			'explore.rows.trendingAnime' => 'Аниме в тренде',
			'explore.rows.suggestedAnime' => 'Рекомендуемые аниме',
			'explore.rows.airingAnime' => 'Топ выходящих аниме',
			'explore.rows.popularAnime' => 'Самые популярные аниме',
			'explore.rows.trending' => 'В тренде',
			'explore.rows.upcomingMovies' => 'Ожидаемые фильмы',
			'explore.rows.upcomingShows' => 'Ожидаемые сериалы',
			'explore.status.airing' => 'Выходит',
			'explore.status.ended' => 'Завершён',
			'explore.status.canceled' => 'Отменён',
			'explore.status.upcoming' => 'Скоро',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: '${n} эпизод', few: '${n} эпизода', many: '${n} эпизодов', other: '${n} эпизода', ), 
			'explore.cast' => 'В ролях',
			'explore.characters' => 'Персонажи',
			'explore.addToWatchlist' => 'Добавить в список для просмотра',
			'explore.removeFromWatchlist' => 'Удалить из списка для просмотра',
			'explore.watchlistUpdateFailed' => 'Не удалось обновить список для просмотра',
			'explore.notInLibrary' => 'Нет в вашей библиотеке',
			'explore.inTheseLibraries' => 'В этих библиотеках',
			'explore.checkingLibrary' => 'Проверка вашей библиотеки...',
			'explore.emptyTitle' => 'Здесь пока ничего нет',
			'explore.emptyMessage' => ({required Object source}) => 'Разделы из ${source} появятся здесь, когда в них появится контент.',
			'explore.searchHint' => ({required Object source}) => 'Поиск в ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Нет результатов по запросу "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Ищите фильмы и сериалы в ${source}.',
			'explore.searchFailed' => 'Ошибка поиска. Проверьте подключение и повторите попытку.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} по популярности',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} в эфире',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} по оценкам',
			'explore.badge.rankFavorited' => ({required Object n}) => '#${n} по избранному',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} в тренде',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} в сезоне ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} смотрят',
			'explore.badge.available' => 'Доступно',
			'explore.badge.partiallyAvailable' => 'Доступно частично',
			'explore.badge.availableIn4k' => 'Доступно в 4K',
			'explore.badge.requested' => 'Запрошено',
			'explore.badge.pendingApproval' => 'Ожидает одобрения',
			'explore.badge.processing' => 'В обработке',
			'explore.badge.declined' => 'Отклонено',
			'explore.badge.requestFailed' => 'Запрос не удался',
			'explore.badge.requested4k' => 'Запрошено в 4K',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} сезонов',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Серия ${episode} через ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Далее через ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} эп.',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} мин/эп.',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} в списках',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} посмотрели сегодня',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} посмотрели на этой неделе',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} посмотрели в этом месяце',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} посмотрели в этом году',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} зрителей',
			'explore.stats.planning' => ({required Object n}) => '${n} планируют посмотреть',
			'explore.stats.favorited' => ({required Object n}) => '${n} в избранном',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} бросили',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: '${n} комментарий', few: '${n} комментария', many: '${n} комментариев', other: '${n} комментариев', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} голосов',
			'explore.stats.watching' => ({required Object n}) => '${n} смотрят',
			'explore.stats.completed' => ({required Object n}) => '${n} завершили',
			'explore.stats.onHold' => ({required Object n}) => '${n} отложили',
			'explore.stats.dropped' => ({required Object n}) => '${n} бросили',
			_ => null,
		} ?? switch (path) {
			'explore.season.winter' => 'Зима',
			'explore.season.spring' => 'Весна',
			'explore.season.summer' => 'Лето',
			'explore.season.fall' => 'Осень',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'ТВ',
			'explore.format.tvShort' => 'Короткометражное ТВ',
			'explore.format.movie' => 'Фильм',
			'explore.format.special' => 'Спецвыпуск',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Музыка',
			'explore.format.other' => 'Другое',
			'explore.sourceMaterial.original' => 'Оригинал',
			'explore.sourceMaterial.manga' => 'Манга',
			'explore.sourceMaterial.lightNovel' => 'Ранобэ',
			'explore.sourceMaterial.novel' => 'Новелла',
			'explore.sourceMaterial.visualNovel' => 'Визуальная новелла',
			'explore.sourceMaterial.game' => 'Игра',
			'explore.sourceMaterial.webComic' => 'Веб-комикс',
			'explore.sourceMaterial.musicRelease' => 'Музыка',
			'explore.sourceMaterial.otherMedia' => 'Другое',
			'explore.creditRole.director' => 'Режиссёр',
			'explore.creditRole.writer' => 'Сценарист',
			'explore.creditRole.producer' => 'Продюсер',
			'explore.creditRole.creator' => 'Создатель',
			'explore.creditRole.composer' => 'Композитор',
			'explore.relation.prequel' => 'Приквел',
			'explore.relation.sequel' => 'Сиквел',
			'explore.relation.sideStory' => 'Побочная история',
			'explore.relation.spinOff' => 'Спин-офф',
			'explore.relation.alternativeVersion' => 'Альтернативная версия',
			'explore.relation.summary' => 'Краткое изложение',
			'explore.relation.parentStory' => 'Основная история',
			'explore.relation.adaptation' => 'Адаптация',
			'explore.relation.other' => 'Связано',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Выходит ${day} в ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Выходит ${day} в ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Оригинальное название',
			'explore.detail.alsoKnownAs' => 'Также известен как',
			'explore.detail.studios' => 'Студии',
			'explore.detail.country' => 'Страна',
			'explore.detail.language' => 'Язык',
			'explore.detail.released' => 'Выпущено',
			'explore.detail.physicalRelease' => 'На диске',
			'explore.detail.ended' => 'Завершено',
			'explore.detail.addedOn' => ({required Object date}) => 'Добавлено ${date}',
			'explore.detail.yourRating' => 'Ваша оценка',
			'explore.detail.budget' => 'Бюджет',
			'explore.detail.revenue' => 'Сборы',
			'explore.detail.contentAdvisory' => 'Возрастные ограничения',
			'explore.detail.tags' => 'Теги',
			'explore.detail.revealSpoilerTags' => 'Показать теги со спойлерами',
			'explore.detail.links' => 'Ссылки',
			'explore.detail.watchOn' => 'Смотреть на',
			'explore.detail.watchTrailer' => 'Смотреть трейлер',
			'explore.detail.openOn' => ({required Object site}) => 'Открыть на ${site}',
			'explore.detail.crew' => 'Съёмочная группа',
			'explore.detail.ratings' => 'Рейтинги',
			'explore.detail.schedule' => 'Расписание',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: 'Рекомендуют ${n} пользователь', few: 'Рекомендуют ${n} пользователя', many: 'Рекомендуют ${n} пользователей', other: 'Рекомендуют ${n} пользователей', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Рекомендовано: ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'В избранном у ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} ещё не вышли',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Рекомендуют ${percent} зрителей',
			'explore.detail.relatedTitles' => 'Связанные названия',
			'explore.detail.background' => 'Фон',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: '${n} результат', few: '${n} результата', many: '${n} результатов', other: '${n} результатов', ), 
			'liveTv.title' => 'ТВ в прямом эфире',
			'liveTv.guide' => 'Программа',
			'liveTv.noChannels' => 'Нет доступных каналов',
			'liveTv.noDvr' => 'DVR не настроен ни на одном сервере',
			'liveTv.serverUnavailable' => 'Сервер прямого эфира недоступен.',
			'liveTv.serverNotConnected' => 'Сервер прямого эфира не подключён.',
			'liveTv.noPrograms' => 'Нет данных о программах',
			'liveTv.liveStreamFailed' => 'Не удалось запустить прямой эфир',
			'liveTv.unknownProgram' => 'Неизвестная программа',
			'liveTv.unknownHub' => 'Неизвестно',
			'liveTv.unknownError' => 'Неизвестная ошибка',
			'liveTv.channelNumber' => ({required Object number}) => 'Канал ${number}',
			'liveTv.unknownChannel' => 'Неизвестный канал',
			'liveTv.live' => 'ЭФИР',
			'liveTv.reloadGuide' => 'Перезагрузить программу',
			'liveTv.now' => 'Сейчас',
			'liveTv.today' => 'Сегодня',
			'liveTv.tomorrow' => 'Завтра',
			'liveTv.midnight' => 'Полночь',
			'liveTv.overnight' => 'Ночь',
			'liveTv.morning' => 'Утро',
			'liveTv.daytime' => 'День',
			'liveTv.evening' => 'Вечер',
			'liveTv.lateNight' => 'Поздний вечер',
			'liveTv.whatsOn' => 'Что идёт',
			'liveTv.watchChannel' => 'Смотреть канал',
			'liveTv.favorites' => 'Избранное',
			'liveTv.reorderFavorites' => 'Изменить порядок избранного',
			'liveTv.favoritesLoadFailed' => 'Не удалось загрузить избранное. Проверьте подключение и повторите попытку.',
			'liveTv.favoritesUpdateFailed' => 'Не удалось обновить избранное. Проверьте подключение и повторите попытку.',
			'liveTv.joinSession' => 'Присоединиться к текущему сеансу',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Смотреть сначала (${minutes} мин. назад)',
			'liveTv.watchLive' => 'Смотреть в прямом эфире',
			'liveTv.goToLive' => 'К прямому эфиру',
			'liveTv.record' => 'Запись',
			'liveTv.recordEpisode' => 'Записать эпизод',
			'liveTv.recordSeries' => 'Записать сериал',
			'liveTv.recordOptions' => 'Параметры записи',
			'liveTv.saveTo' => 'Сохранить в',
			'liveTv.recordings' => 'Записи',
			'liveTv.scheduledRecordings' => 'Запланировано',
			'liveTv.recordingRules' => 'Правила записи',
			'liveTv.noScheduledRecordings' => 'Нет запланированных записей',
			'liveTv.manageRecording' => 'Управление записью',
			'liveTv.cancelRecording' => 'Отменить запись',
			'liveTv.cancelRecordingTitle' => 'Отменить эту запись?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} больше не будет записываться.',
			'liveTv.deleteRule' => 'Удалить правило',
			'liveTv.deleteRuleTitle' => 'Удалить правило записи?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Будущие эпизоды ${title} не будут записаны.',
			'liveTv.recordingScheduled' => 'Запись запланирована',
			'liveTv.alreadyScheduled' => 'Эта передача уже запланирована',
			'liveTv.dvrAdminRequired' => 'Настройки DVR требуют учётной записи администратора',
			'liveTv.recordingFailed' => 'Не удалось запланировать запись',
			'liveTv.recordingTargetMissing' => 'Не удалось определить библиотеку записи',
			'liveTv.recordNotAvailable' => 'Запись недоступна для этой передачи',
			'liveTv.recordingCancelled' => 'Запись отменена',
			'liveTv.recordingRuleDeleted' => 'Правило записи удалено',
			'liveTv.processRecordingRules' => 'Пересчитать правила',
			'liveTv.recordingInProgress' => 'Идёт запись',
			'liveTv.recordingsCount' => ({required Object count}) => 'Запланировано: ${count}',
			'liveTv.editRule' => 'Изменить правило',
			'liveTv.editRuleAction' => 'Изменить',
			'liveTv.recordingRuleUpdated' => 'Правило записи обновлено',
			'liveTv.guideReloadRequested' => 'Запрошено обновление гайда',
			'liveTv.rulesProcessRequested' => 'Запрошен пересчёт правил',
			'liveTv.recordShow' => 'Записать передачу',
			'collections.title' => 'Коллекции',
			'collections.collection' => 'Коллекция',
			'collections.empty' => 'Коллекция пуста',
			'collections.deleteCollection' => 'Удалить коллекцию',
			'collections.deleteConfirm' => ({required Object title}) => 'Удалить "${title}"? Это нельзя отменить.',
			'collections.deleted' => 'Коллекция удалена',
			'collections.deleteFailed' => 'Не удалось удалить коллекцию',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Не удалось удалить коллекцию: ${error}',
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
			'collections.searchCollections' => 'Поиск коллекций...',
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
			'playlists.searchPlaylists' => 'Поиск плейлистов...',
			'playlists.errorCreating' => 'Не удалось создать плейлист',
			'playlists.errorDeleting' => 'Не удалось удалить плейлист',
			'playlists.errorLoading' => 'Не удалось загрузить плейлисты',
			'playlists.errorAdding' => 'Не удалось добавить в плейлист',
			'playlists.errorReordering' => 'Не удалось переупорядочить элемент плейлиста',
			'playlists.errorRemoving' => 'Не удалось удалить из плейлиста',
			'music.goToAlbum' => 'Перейти к альбому',
			'music.goToArtist' => 'Перейти к исполнителю',
			'music.instantMix' => 'Быстрый микс',
			'music.playNext' => 'Воспроизвести следующим',
			'music.addToQueue' => 'Добавить в очередь',
			'music.discNumber' => ({required Object n}) => 'Диск ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, one: '${n} трек', few: '${n} трека', many: '${n} треков', other: '${n} трека', ), 
			'music.nowPlaying' => 'Сейчас играет',
			'music.playingFrom' => ({required Object title}) => 'Воспроизведение из ${title}',
			'music.queue' => 'Очередь',
			'music.clearQueue' => 'Очистить очередь',
			'music.lyrics' => 'Текст песни',
			'music.noLyrics' => 'Текст песни недоступен',
			'music.sleepTimer' => 'Таймер сна',
			'music.sleepTimerEndOfTrack' => 'Конец трека',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} минут',
			'music.stopPlayback' => 'Остановить воспроизведение',
			'music.previousTrack' => 'Предыдущий трек',
			'music.nextTrack' => 'Следующий трек',
			'music.repeat' => 'Повтор',
			'music.repeatAll' => 'Повторять все',
			'music.repeatOne' => 'Повторять один',
			'watchTogether.title' => 'Смотреть вместе',
			'watchTogether.description' => 'Смотрите контент синхронно с друзьями и семьёй',
			'watchTogether.createSession' => 'Создать сессию',
			'watchTogether.creating' => 'Создание...',
			'watchTogether.joinSession' => 'Присоединиться к сессии',
			'watchTogether.joining' => 'Подключение...',
			'watchTogether.controlMode' => 'Режим управления',
			'watchTogether.controlModeQuestion' => 'Кто может управлять воспроизведением?',
			'watchTogether.hostOnly' => 'Только организатор',
			'watchTogether.anyone' => 'Все',
			'watchTogether.hostingSession' => 'Вы организатор',
			'watchTogether.inSession' => 'В сессии',
			'watchTogether.sessionCode' => 'Код сессии',
			'watchTogether.openSessionControls' => 'Открыть управление сессией «Смотреть вместе»',
			'watchTogether.copySessionCode' => 'Скопировать код сессии',
			'watchTogether.hostControlsPlayback' => 'Организатор управляет воспроизведением',
			'watchTogether.anyoneCanControl' => 'Любой может управлять воспроизведением',
			'watchTogether.hostControls' => 'Управляет организатор',
			'watchTogether.anyoneControls' => 'Управляют все',
			'watchTogether.participants' => 'Участники',
			'watchTogether.host' => 'Организатор',
			'watchTogether.hostBadge' => 'ОРГАНИЗАТОР',
			'watchTogether.youAreHost' => 'Вы — организатор',
			'watchTogether.watchingWithOthers' => 'Совместный просмотр',
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
			'watchTogether.enterCodeHint' => 'Введите 5-символьный код',
			'watchTogether.pasteFromClipboard' => 'Вставить из буфера обмена',
			'watchTogether.pleaseEnterCode' => 'Введите код сессии',
			'watchTogether.codeMustBe5Chars' => 'Код сессии должен содержать 5 символов',
			'watchTogether.joinInstructions' => 'Введите код сессии организатора, чтобы присоединиться.',
			'watchTogether.failedToCreate' => 'Не удалось создать сессию',
			'watchTogether.failedToJoin' => 'Не удалось присоединиться к сессии',
			'watchTogether.sessionCodeCopied' => 'Код сессии скопирован в буфер обмена',
			'watchTogether.relayUnreachable' => 'Сервер ретрансляции недоступен. Блокировка интернет-провайдером может помешать совместному просмотру.',
			'watchTogether.reconnectingToHost' => 'Повторное подключение к организатору...',
			'watchTogether.currentPlayback' => 'Текущее воспроизведение',
			'watchTogether.joinCurrentPlayback' => 'Присоединиться к текущему воспроизведению',
			'watchTogether.joinCurrentPlaybackDescription' => 'Вернуться к материалу, который сейчас смотрит организатор',
			'watchTogether.failedToOpenCurrentPlayback' => 'Не удалось открыть текущее воспроизведение',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} присоединился',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} вышел',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} поставил на паузу',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} возобновил',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} перемотал',
			'watchTogether.participantBuffering' => ({required Object name}) => 'У ${name} идёт буферизация',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} использует старую версию приложения — синхронизация недоступна',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Возобновление без ${name}',
			'watchTogether.waitingForParticipants' => 'Ожидание загрузки у других...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Ожидание ${name}...',
			'watchTogether.recentRooms' => 'Недавние комнаты',
			'watchTogether.renameRoom' => 'Переименовать комнату',
			'watchTogether.removeRoom' => 'Удалить',
			'watchTogether.guestSwitchUnavailable' => 'Не удалось переключиться — сервер недоступен для синхронизации',
			'watchTogether.guestSwitchFailed' => 'Не удалось переключиться — содержимое не найдено на этом сервере',
			'downloads.title' => 'Загрузки',
			'downloads.manage' => 'Управление',
			'downloads.tvShows' => 'Сериалы',
			'downloads.movies' => 'Фильмы',
			'downloads.music' => 'Музыка',
			'downloads.tracksQueued' => ({required Object count}) => '${count} треков в очереди на загрузку',
			'downloads.noDownloads' => 'Загрузок пока нет',
			'downloads.noDownloadsDescription' => 'Загруженный контент появится здесь для просмотра офлайн',
			'downloads.downloadNow' => 'Загрузить',
			'downloads.deleteDownload' => 'Удалить загрузку',
			'downloads.retryDownload' => 'Повторить загрузку',
			'downloads.downloadQueued' => 'Загрузка поставлена в очередь',
			'downloads.downloadResumed' => 'Загрузка возобновлена',
			'downloads.serverErrorBitrate' => 'Ошибка сервера: файл может превышать установленное на сервере ограничение битрейта',
			'downloads.storageFull' => 'Загрузки остановлены, так как хранилище устройства заполнено. Освободите место и повторите попытку.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} эпизодов поставлено в очередь загрузки',
			'downloads.downloadDeleted' => 'Загрузка удалена',
			'downloads.deleteConfirm' => ({required Object title}) => 'Удалить "${title}" с этого устройства?',
			'downloads.cancelledDownloadTitle' => 'Загрузка отменена',
			'downloads.cancelledDownloadMessage' => 'Эта загрузка была отменена. Что вы хотите сделать?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Все эпизоды уже загружены',
			'downloads.resumeDownload' => 'Возобновить загрузку',
			'downloads.cancelledDownload' => 'Загрузка отменена',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (синхронизация ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} загружен — нажмите, чтобы завершить',
			'downloads.partialDownloadClickToComplete' => 'Частично загружено — нажмите, чтобы завершить',
			'downloads.deleting' => 'Удаление...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Удаление ${title}... (${current} из ${total})',
			'downloads.queuedTooltip' => 'В очереди',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'В очереди: ${files}',
			'downloads.downloadingTooltip' => 'Загрузка...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Загрузка ${files}',
			'downloads.noDownloadsTree' => 'Нет загрузок',
			'downloads.pauseAll' => 'Приостановить все',
			'downloads.resumeAll' => 'Возобновить все',
			'downloads.deleteAll' => 'Удалить все',
			'downloads.selectVersion' => 'Выбрать версию',
			'downloads.allEpisodes' => 'Все эпизоды',
			'downloads.unwatchedOnly' => 'Только непросмотренные',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Следующие ${count} непросмотренных',
			'downloads.customAmount' => 'Указать количество...',
			'downloads.includeSpecials' => 'Включить спецвыпуски',
			'downloads.howManyEpisodes' => 'Сколько эпизодов?',
			'downloads.invalidEpisodeCount' => 'Введите допустимое количество эпизодов.',
			'downloads.keepSynced' => 'Синхронизировать',
			'downloads.downloadOnce' => 'Скачать один раз',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Хранить ${count} непросмотренных',
			'downloads.editSyncRule' => 'Редактировать правило синхронизации',
			'downloads.removeSyncRule' => 'Удалить правило синхронизации',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Прекратить синхронизацию «${title}»? Скачанные эпизоды будут сохранены.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Прекратить синхронизацию "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'Также удалить связанные загрузки',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Загрузки, используемые другим правилом синхронизации или профилем, будут сохранены.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Правило синхронизации создано — хранится ${count} непросмотренных эпизодов',
			'downloads.syncRuleUpdated' => 'Правило синхронизации обновлено',
			'downloads.syncRuleRemoved' => 'Правило синхронизации удалено',
			'downloads.syncRuleAndDownloadsRemoved' => 'Правило синхронизации и связанные загрузки удалены',
			'downloads.syncRuleCleanupBusy' => 'Правила синхронизации сейчас обновляются. Попробуйте снова чуть позже.',
			'downloads.syncRuleCleanupUnavailable' => 'Не удалось надёжно определить связанные загрузки. Переподключите сервер и повторите попытку либо удалите правило без удаления загрузок.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Синхронизировано ${count} новых эпизодов для ${title}',
			'downloads.activeSyncRules' => 'Правила синхронизации',
			'downloads.noSyncRules' => 'Нет правил синхронизации',
			'downloads.manageSyncRule' => 'Управление синхронизацией',
			'downloads.editEpisodeCount' => 'Количество эпизодов',
			'downloads.editSyncFilter' => 'Фильтр синхронизации',
			'downloads.syncAllItems' => 'Синхронизация всех элементов',
			'downloads.syncUnwatchedItems' => 'Синхронизация непросмотренных элементов',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Сервер: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Доступен',
			'downloads.syncRuleOffline' => 'Офлайн',
			'downloads.syncRuleSignInRequired' => 'Требуется вход',
			'downloads.syncRuleNotAvailableForProfile' => 'Недоступно для текущего профиля',
			'downloads.syncRuleUnknownServer' => 'Неизвестный сервер',
			'downloads.syncRuleListCreated' => 'Правило синхронизации создано',
			'downloads.backgroundWarning.bannerBlocked' => 'Загрузки остановятся, когда вы выйдете из приложения',
			'downloads.backgroundWarning.bannerDegraded' => 'Фоновые загрузки могут быть ограничены',
			'downloads.backgroundWarning.bannerAction' => 'Подробнее',
			'downloads.backgroundWarning.sheetTitle' => 'Фоновые загрузки заблокированы',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Фоновые загрузки могут быть ограничены',
			'downloads.backgroundWarning.sheetIntro' => 'Android не позволяет Plezy стабильно выполнять загрузки в фоновом режиме.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Ваше устройство ограничивает время, когда Plezy может выполнять загрузки в фоновом режиме.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Фоновая работа Plezy ограничена. В настройках расхода заряда батареи или фоновой работы выберите «Без ограничений».',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android перевёл Plezy в режим ожидания с ограничениями. Для расхода заряда батареи выберите «Без ограничений».',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Уведомления о загрузках отключены, поэтому ход загрузок и элементы управления могут быть недоступны.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Уведомления отключены. В Android 13 и более новых версиях они необходимы для длительных фоновых загрузок.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Экономия трафика включена, поэтому фоновые загрузки через мобильную сеть заблокированы. Загрузки по Wi-Fi должны работать.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Загрузки неоднократно останавливались, пока Plezy работал в фоне. Проверьте настройки расхода заряда батареи или фоновой работы для Plezy.',
			'downloads.backgroundWarning.openSettings' => 'Открыть настройки',
			'downloads.backgroundWarning.stillNotWorking' => 'Помощь для вашего устройства',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Посмотрите инструкции для своего устройства. Если проблема не исчезнет, отправьте лог через Настройки › Просмотр логов.',
			'downloads.backgroundWarning.dialogTitle' => 'Загрузки могут не завершиться',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Всё равно скачать',
			'downloads.backgroundWarning.dialogFixFirst' => 'Сначала исправить',
			'downloads.backgroundWarning.statusTile' => 'Фоновые загрузки',
			'downloads.backgroundWarning.statusOk' => 'Работа в фоне разрешена',
			'downloads.backgroundWarning.statusBlocked' => 'Заблокировано настройками системы',
			'downloads.backgroundWarning.statusDegraded' => 'Ограничено настройками системы',
			'downloads.backgroundWarning.statusUnknown' => 'Ещё не проверено',
			'downloads.backgroundWarning.settingsUnavailable' => 'Не удалось открыть системные настройки на этом устройстве',
			'downloads.backgroundWarning.linkUnavailable' => 'Не удалось открыть dontkillmyapp.com на этом устройстве',
			'shaders.title' => 'Шейдеры',
			'shaders.noShaderDescription' => 'Без улучшения видео',
			'shaders.nvscalerDescription' => 'Масштабирование NVIDIA для более чёткого видео',
			'shaders.artcnnVariantNeutral' => 'Нейтральный',
			'shaders.artcnnVariantDenoise' => 'Шумоподавление',
			'shaders.artcnnVariantDenoiseSharpen' => 'Шумоподавление + резкость',
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
			'companionRemote.connectedTo' => ({required Object name}) => 'Подключено к ${name}',
			'companionRemote.unknownDevice' => 'Неизвестное устройство',
			'companionRemote.session.startingServer' => 'Запуск удалённого сервера...',
			'companionRemote.session.hostAddress' => 'Адрес хоста',
			'companionRemote.session.connected' => 'Подключено',
			'companionRemote.session.serverRunning' => 'Удалённый сервер активен',
			'companionRemote.session.serverStopped' => 'Удалённый сервер остановлен',
			'companionRemote.session.serverRunningDescription' => 'Мобильные устройства в вашей сети могут подключаться к этому приложению',
			'companionRemote.session.serverStoppedDescription' => 'Запустите сервер, чтобы разрешить подключение мобильных устройств',
			'companionRemote.session.usePhoneToControl' => 'Используйте мобильное устройство для управления этим приложением',
			'companionRemote.session.startServer' => 'Запустить сервер',
			'companionRemote.session.stopServer' => 'Остановить сервер',
			'companionRemote.session.minimize' => 'Свернуть',
			'companionRemote.pairing.discoveryDescription' => 'Устройства Plezy с тем же аккаунтом Plex появятся здесь',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Подключение...',
			'companionRemote.pairing.searchingForDevices' => 'Поиск устройств...',
			'companionRemote.pairing.noDevicesFound' => 'Устройства в вашей сети не найдены',
			'companionRemote.pairing.noDevicesHint' => 'Откройте Plezy на компьютере и подключите оба устройства к одной сети Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Доступные устройства',
			'companionRemote.pairing.manualConnection' => 'Ручное подключение',
			'companionRemote.pairing.cryptoInitFailed' => 'Не удалось установить защищённое соединение. Сначала войдите в Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Введите адрес хоста',
			'companionRemote.pairing.validationHostFormat' => 'Формат должен быть IP:порт (например, 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Время подключения истекло. Используйте одну сеть на обоих устройствах.',
			'companionRemote.pairing.sessionNotFound' => 'Устройство не найдено. Убедитесь, что Plezy запущен на хосте.',
			'companionRemote.pairing.authFailed' => 'Аутентификация не удалась. На обоих устройствах нужен один аккаунт Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Не удалось подключиться: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Отключиться от удалённой сессии?',
			'companionRemote.remote.reconnecting' => 'Переподключение...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Попытка ${current} из 5',
			'companionRemote.remote.retryNow' => 'Повторить сейчас',
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
			'companionRemote.errors.noNetworkInterface' => 'Сетевой интерфейс не найден',
			'companionRemote.errors.authenticationFailed' => 'Ошибка аутентификации',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Не удалось запустить удалённый сервер: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Не удалось отправить удалённую команду: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Время подключения к сеансу истекло',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Не удалось подключиться ни к одному адресу',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Соединение потеряно после ${attempts} попыток',
			'companionRemote.errors.connectionLost' => 'Соединение потеряно',
			'videoSettings.playbackSpeed' => 'Скорость воспроизведения',
			'videoSettings.normalSpeed' => 'Обычная',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Активен (${duration})',
			'videoSettings.zoom' => 'Масштаб',
			'videoSettings.sleepTimer' => 'Таймер сна',
			'videoSettings.audioSync' => 'Синхронизация аудио',
			'videoSettings.subtitleSync' => 'Синхронизация субтитров',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Аудиовыход',
			'videoSettings.performanceOverlay' => 'Оверлей производительности',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Объёмный звук',
			'videoSettings.audioOutputSpatial' => 'Пространственное аудио',
			'videoSettings.audioOutputStereo' => 'Стерео',
			'videoSettings.audioNormalization' => 'Нормализация громкости',
			'videoSettings.audioDownmix' => 'Микширование в стерео',
			'performanceOverlay.color' => 'Цвет',
			'performanceOverlay.performance' => 'Производительность',
			'performanceOverlay.buffer' => 'Буфер',
			'performanceOverlay.app' => 'Приложение',
			'performanceOverlay.decoder' => 'Декодер',
			'performanceOverlay.rawDecoder' => 'Raw-декодер',
			'performanceOverlay.tunneling' => 'Туннелирование',
			'performanceOverlay.aspect' => 'Соотношение',
			'performanceOverlay.rotation' => 'Поворот',
			'performanceOverlay.dvSource' => 'Источник DV',
			'performanceOverlay.dvPath' => 'Путь DV',
			'performanceOverlay.p7Conversion' => 'Конв. P7',
			'performanceOverlay.sampleRate' => 'Частота дискр.',
			'performanceOverlay.pixelFormat' => 'Формат пикселей',
			'performanceOverlay.hwFormat' => 'Формат HW',
			'performanceOverlay.matrix' => 'Матрица',
			'performanceOverlay.primaries' => 'Основные цвета',
			'performanceOverlay.transfer' => 'Передача',
			'performanceOverlay.renderFps' => 'FPS рендера',
			'performanceOverlay.displayFps' => 'FPS дисплея',
			'performanceOverlay.avSync' => 'A/V синхр.',
			'performanceOverlay.dropped' => 'Пропущено',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'Сред. DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Сред. сэмпл DV',
			'performanceOverlay.maxLuma' => 'Макс. яркость',
			'performanceOverlay.minLuma' => 'Мин. яркость',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Кэш использован',
			'performanceOverlay.cacheLimit' => 'Лимит кэша',
			'performanceOverlay.speed' => 'Скорость',
			'performanceOverlay.player' => 'Плеер',
			'performanceOverlay.memory' => 'Память',
			'performanceOverlay.uiFps' => 'UI FPS',
			'externalPlayer.title' => 'Внешний плеер',
			'externalPlayer.useExternalPlayer' => 'Использовать внешний плеер',
			'externalPlayer.useExternalPlayerDescription' => 'Открывать видео в другом приложении',
			'externalPlayer.selectPlayer' => 'Выбрать плеер',
			'externalPlayer.customPlayers' => 'Свои плееры',
			'externalPlayer.systemDefault' => 'Системный по умолчанию',
			'externalPlayer.addCustomPlayer' => 'Добавить свой плеер',
			'externalPlayer.playerName' => 'Название плеера',
			'externalPlayer.playerNameHint' => 'Мой плеер',
			'externalPlayer.playerCommand' => 'Команда',
			'externalPlayer.playerPackage' => 'Имя пакета',
			'externalPlayer.playerUrlScheme' => 'URL-схема',
			'externalPlayer.off' => 'Выкл.',
			_ => null,
		} ?? switch (path) {
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
			'metadataEdit.logo' => 'Логотип',
			'metadataEdit.squareArt' => 'Квадратное изображение',
			'metadataEdit.selectPoster' => 'Выбрать постер',
			'metadataEdit.selectBackground' => 'Выбрать фон',
			'metadataEdit.selectLogo' => 'Выбрать логотип',
			'metadataEdit.selectSquareArt' => 'Выбрать квадратное изображение',
			'metadataEdit.fromUrl' => 'По URL',
			'metadataEdit.uploadFile' => 'Загрузить файл',
			'metadataEdit.enterImageUrl' => 'Введите URL изображения',
			'metadataEdit.imageUrl' => 'URL изображения',
			'metadataEdit.metadataUpdated' => 'Метаданные обновлены',
			'metadataEdit.metadataUpdateFailed' => 'Не удалось обновить метаданные',
			'metadataEdit.artworkUpdated' => 'Обложка обновлена',
			'metadataEdit.artworkUpdateFailed' => 'Не удалось обновить обложку',
			'metadataEdit.noArtworkAvailable' => 'Обложки недоступны',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Вариант обложки ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Вариант обложки ${index}, выбран',
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
			'metadataEdit.tmdbAiring' => 'The Movie Database (по дате выхода)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (по дате выхода)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (абсолютный порядок)',
			'metadataEdit.metadataLanguage' => 'Язык метаданных',
			'metadataEdit.useOriginalTitle' => 'Использовать оригинальное название',
			'metadataEdit.preferredAudioLanguage' => 'Предпочитаемый язык аудио',
			'metadataEdit.preferredSubtitleLanguage' => 'Предпочитаемый язык субтитров',
			'metadataEdit.subtitleMode' => 'Автовыбор субтитров',
			'metadataEdit.manuallySelected' => 'Выбор вручную',
			'metadataEdit.shownWithForeignAudio' => 'Показывать при иноязычном аудио',
			'metadataEdit.alwaysEnabled' => 'Всегда включены',
			'metadataEdit.tags' => 'Теги',
			'metadataEdit.addTag' => 'Добавить тег',
			'metadataEdit.genre' => 'Жанр',
			'metadataEdit.director' => 'Режиссёр',
			'metadataEdit.writer' => 'Сценарист',
			'metadataEdit.producer' => 'Продюсер',
			'metadataEdit.country' => 'Страна',
			'metadataEdit.collection' => 'Коллекция',
			'metadataEdit.label' => 'Метка',
			'metadataEdit.style' => 'Стиль',
			'metadataEdit.mood' => 'Настроение',
			'matchScreen.match' => 'Сопоставить...',
			'matchScreen.fixMatch' => 'Исправить сопоставление...',
			'matchScreen.unmatch' => 'Сбросить сопоставление',
			'matchScreen.unmatchConfirm' => 'Очистить это совпадение? Plex будет считать его несопоставленным до повторного сопоставления.',
			'matchScreen.unmatchSuccess' => 'Сопоставление сброшено',
			'matchScreen.unmatchFailed' => 'Не удалось сбросить сопоставление',
			'matchScreen.matchApplied' => 'Сопоставление применено',
			'matchScreen.matchFailed' => 'Не удалось применить сопоставление',
			'matchScreen.titleHint' => 'Название',
			'matchScreen.yearHint' => 'Год',
			'matchScreen.search' => 'Поиск',
			'matchScreen.noMatchesFound' => 'Совпадений не найдено',
			'serverTasks.title' => 'Задачи сервера',
			'serverTasks.failedToLoad' => 'Не удалось загрузить задачи',
			'serverTasks.noTasks' => 'Нет выполняемых задач',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Подключено',
			'trakt.connectedAs' => ({required Object username}) => 'Подключено как @${username}',
			'trakt.disconnectConfirm' => 'Отключить аккаунт Trakt?',
			'trakt.disconnectConfirmBody' => 'Plezy перестанет отправлять события в Trakt. Можно подключить снова в любое время.',
			'trakt.scrobble' => 'Скробблинг в реальном времени',
			'trakt.scrobbleDescription' => 'Отправлять события воспроизведения, паузы и остановки в Trakt во время просмотра.',
			'trakt.watchedSync' => 'Синхронизация статуса просмотра',
			'trakt.watchedSyncDescription' => 'Когда вы отмечаете элементы как просмотренные в Plezy, они отмечаются и в Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Подключить Seerr',
			'seerr.serverUrl' => 'URL сервера',
			'seerr.serverUrlHelper' => 'Адрес вашего экземпляра Seerr',
			'seerr.checkServer' => 'Продолжить',
			'seerr.signInWithJellyfin' => 'Войти через Jellyfin',
			'seerr.signInWithEmby' => 'Войти через Emby',
			'seerr.signInWithLocal' => 'Использовать локальную учётную запись',
			'seerr.email' => 'Эл. почта',
			'seerr.noSignInMethods' => 'Этот экземпляр Seerr не предлагает способа входа, поддерживаемого Plezy.',
			'seerr.instance' => 'Экземпляр',
			'seerr.disconnectConfirm' => 'Отключить Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy забудет этот экземпляр Seerr. Подключитесь снова в любое время.',
			'seerr.request' => 'Запросить',
			'seerr.request4k' => 'Запросить в 4K',
			'seerr.seasons' => 'Сезоны',
			'seerr.allSeasons' => 'Все сезоны',
			'seerr.advancedOptions' => 'Дополнительно',
			'seerr.destinationServer' => 'Целевой сервер',
			'seerr.qualityProfile' => 'Профиль качества',
			'seerr.rootFolder' => 'Корневая папка',
			'seerr.languageProfile' => 'Языковой профиль',
			'seerr.requestSubmitted' => 'Запрос отправлен',
			'seerr.requestFailed' => ({required Object error}) => 'Ошибка запроса: ${error}',
			'seerr.requestsLoadFailed' => 'Не удалось загрузить параметры запроса',
			'seerr.nothingToRequest' => 'Всё уже доступно или запрошено.',
			'seerr.statusAvailable' => 'Доступно',
			'seerr.statusPartiallyAvailable' => 'Частично доступно',
			'seerr.statusRequested' => 'Запрошено',
			'seerr.statusProcessing' => 'Обработка',
			'services.title' => 'Сервисы',
			'services.hubSubtitle' => 'Синхронизируйте прогресс просмотра и запрашивайте новые фильмы и сериалы.',
			'services.notConnected' => 'Не подключено',
			'services.connectedAs' => ({required Object username}) => 'Подключено как @${username}',
			'services.scrobble' => 'Автоматически отслеживать прогресс',
			'services.scrobbleDescription' => 'Обновляет список, когда вы заканчиваете эпизод или фильм.',
			'services.disconnectConfirm' => ({required Object service}) => 'Отключить ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy перестанет обновлять ${service}. Подключите снова в любое время.',
			'services.connectFailed' => ({required Object service}) => 'Не удалось подключиться к ${service}. Попробуйте ещё раз.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => 'Активируйте Plezy в ${service}',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Открыть ${service} для активации',
			'services.deviceCode.copyCode' => 'Скопировать код активации',
			'services.deviceCode.waitingForAuthorization' => 'Ожидание авторизации…',
			'services.deviceCode.codeCopied' => 'Код скопирован',
			'services.oauthProxy.title' => ({required Object service}) => 'Войти в ${service}',
			'services.oauthProxy.body' => 'Отсканируйте этот QR-код или откройте URL на любом устройстве.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Открыть ${service} для входа',
			'services.pendingAuth.copyUrl' => 'Скопировать URL для входа',
			'services.pendingAuth.urlCopied' => 'URL скопирован',
			'services.libraryFilter.title' => 'Фильтр библиотек',
			'services.libraryFilter.subtitleAllSyncing' => 'Синхронизация всех библиотек',
			'services.libraryFilter.subtitleNoneSyncing' => 'Ничего не синхронизируется',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} заблокировано',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} разрешено',
			'services.libraryFilter.mode' => 'Режим фильтра',
			'services.libraryFilter.modeBlacklist' => 'Чёрный список',
			'services.libraryFilter.modeWhitelist' => 'Белый список',
			'services.libraryFilter.modeHintBlacklist' => 'Синхронизировать все библиотеки, кроме отмеченных ниже.',
			'services.libraryFilter.modeHintWhitelist' => 'Синхронизировать только библиотеки, отмеченные ниже.',
			'services.libraryFilter.libraries' => 'Библиотеки',
			'services.libraryFilter.noLibraries' => 'Библиотеки недоступны',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Добавить сервер ${product}',
			'addServer.serverUrls' => 'URL-адреса сервера',
			'addServer.serverUrlsHelper' => 'Можно указать несколько URL через запятую.',
			'addServer.findServer' => 'Найти сервер',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Поиск локальных серверов ${product}...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Локальные серверы ${product}',
			'addServer.username' => 'Имя пользователя',
			'addServer.password' => 'Пароль',
			'addServer.signIn' => 'Войти',
			'addServer.change' => 'Изменить',
			'addServer.required' => 'Обязательно',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Не удалось связаться с сервером: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Не удалось войти: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect не удался: ${error}',
			'addServer.addPlexTitle' => 'Войти через Plex',
			'addServer.pinExpired' => 'Срок действия PIN истёк до входа. Попробуйте снова.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Не удалось зарегистрировать учётную запись: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Введите URL вашего сервера ${product}',
			'addServer.addConnectionTitle' => 'Добавить подключение',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Добавить в ${name}',
			'addServer.signInWithPlexCard' => 'Войти через Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Авторизуйте это устройство. Общие серверы будут добавлены.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Авторизуйте аккаунт Plex. Пользователи Home станут профилями.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Подключиться к ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Введите URL сервера, имя пользователя и пароль.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Войдите на свой сервер ${product}. Будет привязано к ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Использовать подключение другого профиля',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Повторно используйте подключение другого профиля. Для защищённых профилей потребуется PIN.',
			_ => null,
		};
	}
}
