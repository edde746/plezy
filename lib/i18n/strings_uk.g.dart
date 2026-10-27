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
class TranslationsUk extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsUk({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.uk,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <uk>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsUk _root = this; // ignore: unused_field

	@override 
	TranslationsUk $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsUk(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$uk app = _Translations$app$uk._(_root);
	@override late final _Translations$cast$uk cast = _Translations$cast$uk._(_root);
	@override late final _Translations$automation$uk automation = _Translations$automation$uk._(_root);
	@override late final _Translations$notifications$uk notifications = _Translations$notifications$uk._(_root);
	@override late final _Translations$appIcon$uk appIcon = _Translations$appIcon$uk._(_root);
	@override late final _Translations$auth$uk auth = _Translations$auth$uk._(_root);
	@override late final _Translations$common$uk common = _Translations$common$uk._(_root);
	@override late final _Translations$screens$uk screens = _Translations$screens$uk._(_root);
	@override late final _Translations$update$uk update = _Translations$update$uk._(_root);
	@override late final _Translations$appAccess$uk appAccess = _Translations$appAccess$uk._(_root);
	@override late final _Translations$settings$uk settings = _Translations$settings$uk._(_root);
	@override late final _Translations$themeEditor$uk themeEditor = _Translations$themeEditor$uk._(_root);
	@override late final _Translations$search$uk search = _Translations$search$uk._(_root);
	@override late final _Translations$hotkeys$uk hotkeys = _Translations$hotkeys$uk._(_root);
	@override late final _Translations$fileInfo$uk fileInfo = _Translations$fileInfo$uk._(_root);
	@override late final _Translations$mediaMenu$uk mediaMenu = _Translations$mediaMenu$uk._(_root);
	@override late final _Translations$rateSheet$uk rateSheet = _Translations$rateSheet$uk._(_root);
	@override late final _Translations$accessibility$uk accessibility = _Translations$accessibility$uk._(_root);
	@override late final _Translations$tooltips$uk tooltips = _Translations$tooltips$uk._(_root);
	@override late final _Translations$audioTracks$uk audioTracks = _Translations$audioTracks$uk._(_root);
	@override late final _Translations$videoControls$uk videoControls = _Translations$videoControls$uk._(_root);
	@override late final _Translations$messages$uk messages = _Translations$messages$uk._(_root);
	@override late final _Translations$subtitlingStyling$uk subtitlingStyling = _Translations$subtitlingStyling$uk._(_root);
	@override late final _Translations$mpvConfig$uk mpvConfig = _Translations$mpvConfig$uk._(_root);
	@override late final _Translations$dialog$uk dialog = _Translations$dialog$uk._(_root);
	@override late final _Translations$profiles$uk profiles = _Translations$profiles$uk._(_root);
	@override late final _Translations$connections$uk connections = _Translations$connections$uk._(_root);
	@override late final _Translations$accountPreferences$uk accountPreferences = _Translations$accountPreferences$uk._(_root);
	@override late final _Translations$discover$uk discover = _Translations$discover$uk._(_root);
	@override late final _Translations$errors$uk errors = _Translations$errors$uk._(_root);
	@override late final _Translations$libraries$uk libraries = _Translations$libraries$uk._(_root);
	@override late final _Translations$about$uk about = _Translations$about$uk._(_root);
	@override late final _Translations$serverSelection$uk serverSelection = _Translations$serverSelection$uk._(_root);
	@override late final _Translations$hubDetail$uk hubDetail = _Translations$hubDetail$uk._(_root);
	@override late final _Translations$logs$uk logs = _Translations$logs$uk._(_root);
	@override late final _Translations$detail$uk detail = _Translations$detail$uk._(_root);
	@override late final _Translations$startup$uk startup = _Translations$startup$uk._(_root);
	@override late final _Translations$licenses$uk licenses = _Translations$licenses$uk._(_root);
	@override late final _Translations$navigation$uk navigation = _Translations$navigation$uk._(_root);
	@override late final _Translations$explore$uk explore = _Translations$explore$uk._(_root);
	@override late final _Translations$liveTv$uk liveTv = _Translations$liveTv$uk._(_root);
	@override late final _Translations$collections$uk collections = _Translations$collections$uk._(_root);
	@override late final _Translations$playlists$uk playlists = _Translations$playlists$uk._(_root);
	@override late final _Translations$music$uk music = _Translations$music$uk._(_root);
	@override late final _Translations$watchTogether$uk watchTogether = _Translations$watchTogether$uk._(_root);
	@override late final _Translations$downloads$uk downloads = _Translations$downloads$uk._(_root);
	@override late final _Translations$shaders$uk shaders = _Translations$shaders$uk._(_root);
	@override late final _Translations$companionRemote$uk companionRemote = _Translations$companionRemote$uk._(_root);
	@override late final _Translations$videoSettings$uk videoSettings = _Translations$videoSettings$uk._(_root);
	@override late final _Translations$performanceOverlay$uk performanceOverlay = _Translations$performanceOverlay$uk._(_root);
	@override late final _Translations$externalPlayer$uk externalPlayer = _Translations$externalPlayer$uk._(_root);
	@override late final _Translations$metadataEdit$uk metadataEdit = _Translations$metadataEdit$uk._(_root);
	@override late final _Translations$matchScreen$uk matchScreen = _Translations$matchScreen$uk._(_root);
	@override late final _Translations$serverTasks$uk serverTasks = _Translations$serverTasks$uk._(_root);
	@override late final _Translations$trakt$uk trakt = _Translations$trakt$uk._(_root);
	@override late final _Translations$seerr$uk seerr = _Translations$seerr$uk._(_root);
	@override late final _Translations$services$uk services = _Translations$services$uk._(_root);
	@override late final _Translations$addServer$uk addServer = _Translations$addServer$uk._(_root);
	@override late final _Translations$watchLink$uk watchLink = _Translations$watchLink$uk._(_root);
	@override late final _Translations$homeLayout$uk homeLayout = _Translations$homeLayout$uk._(_root);
	@override late final _Translations$platform$uk platform = _Translations$platform$uk._(_root);
	@override late final _Translations$fileSources$uk fileSources = _Translations$fileSources$uk._(_root);
	@override late final _Translations$lending$uk lending = _Translations$lending$uk._(_root);
	@override late final _Translations$audiobook$uk audiobook = _Translations$audiobook$uk._(_root);
	@override late final _Translations$sourceSetup$uk sourceSetup = _Translations$sourceSetup$uk._(_root);
	@override late final _Translations$comics$uk comics = _Translations$comics$uk._(_root);
	@override late final _Translations$games$uk games = _Translations$games$uk._(_root);
}

// Path: app
class _Translations$app$uk extends Translations$app$en {
	_Translations$app$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$uk extends Translations$cast$en {
	_Translations$cast$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Транслювати на пристрій';
	@override String get searching => 'Пошук пристроїв для вишивки...';
	@override String connectedTo({required Object device}) => 'Підключений до ${device}';
	@override String get device => 'Пристрій для трансляції';
	@override String get readyToCast => 'Готово до трансляції';
	@override String get subtitle => 'Субтитри';
	@override String get serverNotAvailable => 'Медіа-сервер не доступний.';
	@override String get stopCasting => 'Зупинити трансляцію';
	@override String get castToDevice => 'Транслювати на пристрій';
	@override String get noEpisodeAvailable => 'Епізоду не можна випустити.';
	@override String get startFailed => 'Не можна почати кастинг. перевірте сервер і спробуйте знову.';
}

// Path: automation
class _Translations$automation$uk extends Translations$automation$en {
	_Translations$automation$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Не існує активної відеосесії для контролю.';
	@override String get profileNotFound => 'Профіль Plezy не знайдено.';
}

// Path: notifications
class _Translations$notifications$uk extends Translations$notifications$en {
	_Translations$notifications$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Новий епізод';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$uk extends Translations$appIcon$en {
	_Translations$appIcon$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ікони App';
	@override String get defaultIcon => 'За замовчуванням';
	@override String get current => 'Теперішня ікона';
	@override String get locked => 'Доступ до життєдіяльності необхідний';
	@override String get lockedHint => 'Запустіть 7-денний тест або розблокуйте PlezyNG протягом усього життя, щоб використовувати альтернативні ікони.';
	@override String get changeFailed => 'Я не зміню ікону додатку';
	@override String get launcherHint => 'Нова ікона з\'являється на домашньому екрані після того, як ви залишите PlezyNG.';
	@override String get tvLauncherHint => 'Новий банер з\'являється, як тільки ви залишите PlezyNG. Android TV може продовжувати показувати старий до відновлення телевізора.';
	@override late final _Translations$appIcon$names$uk names = _Translations$appIcon$names$uk._(_root);
}

// Path: auth
class _Translations$auth$uk extends Translations$auth$en {
	_Translations$auth$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Зареєструйтесь за адресою Plex';
	@override String get showQRCode => 'Показати QR код';
	@override String get authenticate => 'автентичні';
	@override String get authenticationTimeout => 'Офіційна аутентифікація закінчилася, будь ласка, спробуйте знову.';
	@override String get scanQRToSignIn => 'Сканувати цей QR-код для підписання';
	@override String get waitingForAuth => 'Чекаючи на аутентифікацію... Зареєструйтесь з браузера.';
	@override String get useBrowser => 'Використання браузера';
	@override String get or => 'або';
	@override String connectToMediaBrowser({required Object product}) => 'Підключення до ${product}';
	@override String get quickConnect => 'Швидке підключення';
	@override String get useQuickConnect => 'Використати Quick Connect';
	@override String get quickConnectInstructions => 'Відкрийте Quick Connect в Jellyfin і введіть цей код.';
	@override String get quickConnectWaiting => 'Чекаємо на затвердження...';
	@override String get quickConnectCancel => 'Скасувати';
	@override String get quickConnectExpired => 'Термін дії швидкого підключення минув. Спробуйте ще раз.';
	@override String get localDataRecoveryRequired => 'PlezyNG не вдалося безпечно відновити локальні дані входу та дані відтворення, що очікують обробки. Увійдіть знову.';
	@override String get pinCheckRejected => 'Кінцевий код PIN Plex відхилено';
	@override String get connectToDirectPlex => 'Підключення до локального сервера Plex';
}

// Path: common
class _Translations$common$uk extends Translations$common$en {
	_Translations$common$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Скасувати';
	@override String get save => 'Зберегти';
	@override String get close => 'Закрити';
	@override String get clear => 'чітко';
	@override String get reset => 'Скинути';
	@override String get later => 'Пізніше';
	@override String get submit => 'Підтвердити';
	@override String get confirm => 'підтверджує';
	@override String get retry => 'Повторити';
	@override String get logout => 'Зареєструйтеся';
	@override String get unknown => 'Невідоме';
	@override String get refresh => 'Оновити';
	@override String get yes => 'Так';
	@override String get no => 'Ні';
	@override String get delete => 'Видалити';
	@override String get edit => 'Редагувати';
	@override String get shuffle => 'Перемішати';
	@override String get addTo => 'Додайте до...';
	@override String get createNew => 'Створення Новий';
	@override String get connect => 'Підключитись';
	@override String get disconnect => 'Від’єднатися';
	@override String get play => 'Грати';
	@override String get pause => 'Пауза';
	@override String get resume => 'Продовжити';
	@override String get error => 'Помилка';
	@override String get search => 'Пошук';
	@override String get home => 'Головна';
	@override String get back => 'Назад';
	@override String get settings => 'Налаштування';
	@override String get mute => 'Заглушити';
	@override String get ok => 'ОК';
	@override String get off => 'Вимкнути';
	@override String get options => 'варіанти';
	@override String seasonNumber({required Object number}) => 'Сезон ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Епізод ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Розділ ${number}';
	@override String get reconnect => 'Відновлення';
	@override String get viewAll => 'Переглянути всі';
	@override String get checkingNetwork => 'Перевірка мережі...';
	@override String get loadingServers => 'Завантаження серверів...';
	@override String get connectingToServers => 'Підключення до серверів...';
	@override String get startingOfflineMode => 'Починаючи з офлайн-моду';
	@override String get loading => 'Завантажити...';
	@override String get fullscreen => 'Повноекранний режим';
	@override String get exitFullscreen => 'Повний екран виходу';
	@override String get pressBackAgainToExit => 'Натисніть знову на вихід';
	@override late final _Translations$common$ratingSource$uk ratingSource = _Translations$common$ratingSource$uk._(_root);
	@override String get notAvailable => 'Н / А';
	@override String get url => 'URL';
	@override String get letterKeys => 'АБС';
	@override late final _Translations$common$mediaKind$uk mediaKind = _Translations$common$mediaKind$uk._(_root);
}

// Path: screens
class _Translations$screens$uk extends Translations$screens$en {
	_Translations$screens$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'ліцензії';
	@override String get switchProfile => 'Профіль перемикача';
	@override String get subtitleStyling => 'Стилізація субтитрів';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Журнали';
}

// Path: update
class _Translations$update$uk extends Translations$update$en {
	_Translations$update$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get available => 'Оновлення доступне';
	@override String versionAvailable({required Object version}) => 'Версія ${version} доступна';
	@override String currentVersion({required Object version}) => 'Теперішній номер: ${version}';
	@override String get skipVersion => 'Скачати цю версію';
	@override String get viewRelease => 'Переглянути випуск';
	@override String get latestVersion => 'Ви знаходитесь в останній версії';
	@override String get checkFailed => 'Не вдалося перевірити оновлення';
}

// Path: appAccess
class _Translations$appAccess$uk extends Translations$appAccess$en {
	_Translations$appAccess$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Спробуйте будь-яку функцію безкоштовно протягом 7 днів';
	@override String get description => 'Почніть семиденний випробування з повним доступом до кожної функції PlezyNG. під час випробування немає оплати і без підписки. Після випробування один життєвий купівля за ціною вашого магазину відкриває PlezyNG на життя.';
	@override String get trialEndedDescription => 'Відключити кожну функцію в PlezyNG на життя з одним покупкою за ціною вашого магазину.';
	@override String get startTrial => 'Початок мого 7-денного безкоштовного випробування';
	@override String get trialActive => 'Ваш 7-денний повний тест функції активний.';
	@override String get trialEnded => 'Сім днів судового розгляду закінчилися';
	@override String get trialStartFailed => 'Я не можу врятувати випробування на цьому пристрої. будь ласка, спробуйте знову.';
	@override String get lifetimeTitle => 'PlezyNG відключено на життя';
	@override String get lifetimeBody => 'Ви маєте доступу до кожної функції PlezyNG.';
	@override String get manageTitle => 'PlezyNG Доступ до життя';
	@override String get manageDescription => 'Спробуйте кожну функцію безкоштовно протягом 7 днів, а потім розблокуйте все на життя з однією оплатою за ціною вашого магазину.';
	@override String buy({required Object price}) => 'Відключити кожну функцію для ${price}';
	@override String get loadingPrice => 'Вартість магазину ...';
	@override String get retryPrice => 'Повернення ціни Lookup';
	@override String get restore => 'Відновлення життєвого купівлі';
	@override String get pending => 'Ваш покупка чекає на оплату або затвердження. Доступ до життєвого часу відкривається, як тільки магазин завершить його.';
	@override String get storeUnavailable => 'Переконайтеся, що ви підписуєтеся в магазин, а покупки дозволені на цьому пристрої.';
	@override String get productNotFound => 'PlezyNG життєвий відключення ще не доступно в цьому магазині.';
	@override String get productQueryFailed => 'Ціна магазину не може бути завантажена. перевірте зв\'язок і спробуйте знову.';
	@override String get purchaseFailed => 'Купівля не пройшла. спробуйте знову.';
	@override String get restoreFailed => 'Я не міг би дістатися до магазину, щоб відновити вашу покупку. спробуйте знову.';
	@override String get nothingToRestore => 'Номер PlezyNG життєвий купівля був знайдений для цього облікового запису магазину.';
}

// Path: settings
class _Translations$settings$uk extends Translations$settings$en {
	_Translations$settings$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Налаштування';
	@override String get supportDeveloper => 'Підтримка PlezyNG';
	@override String get supportDeveloperDescription => 'Донорство на підтримку розвитку';
	@override String get lifetimeAccess => 'PlezyNG Доступ до життя';
	@override String get language => 'Мова';
	@override String get theme => 'Тема';
	@override String get appearance => 'Поява';
	@override String get detailPage => 'Детальна сторінка';
	@override String get themeSongsEnabled => 'Грати в тематичні пісні';
	@override String get themeSongsEnabledDescription => 'Грати на доступні тематичні пісні під час перегляду медіа-деталі.';
	@override String get themeSongVolume => 'ТОВАРИСТВО З ОБМЕЖЕНОЮ ВІДПОВІДАЛЬНІСТЮ';
	@override String get videoPlayback => 'Відео Playback';
	@override String get videoPlaybackDescription => 'Налаштування поведінки Playback';
	@override String get advanced => 'Розширені';
	@override String get episodePosterMode => 'Стиль епізоду';
	@override String get seriesPoster => 'Серія Постер';
	@override String get seasonPoster => 'Сезонний плакат';
	@override String get episodeThumbnail => 'Тюмен';
	@override String get showHeroSectionDescription => 'Дисплей з контентом карусель на домашньому екрані';
	@override String get secondsLabel => 'секунди';
	@override String get minutesLabel => 'хвилин';
	@override String get secondsShort => 'С';
	@override String get minutesShort => 'М';
	@override String durationHint({required Object min, required Object max}) => 'Введіть значення (${min}-${max})';
	@override String get systemTheme => 'Система';
	@override String get lightTheme => 'світло';
	@override String get darkTheme => 'Темний';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Чоловік';
	@override String get glacierTheme => 'Льодовик';
	@override String get forestTheme => 'ліс';
	@override String get plumTheme => 'Плюм';
	@override String get paperTheme => 'папір';
	@override String get libraryDensity => 'Бібліотечна щільність';
	@override String get displayScale => 'Дисплей масштаби';
	@override String get compact => 'компактний';
	@override String get comfortable => 'зручність';
	@override String get gridSpacing => 'Стіл-простір';
	@override String get gridSpacingTight => 'Тетяни';
	@override String get gridSpacingNormal => 'Звичайний';
	@override String get gridSpacingSpacious => 'Простір';
	@override String get tvCornerSpotlightBackdrop => 'Створення Spotlight Backdrop';
	@override String get tvCornerSpotlightBackdropDescription => 'Показати художню твір в правому верхньому куті замість заповнення екрану';
	@override String get viewMode => 'Погляд на моду';
	@override String get gridView => 'мережа';
	@override String get listView => 'Список';
	@override String get showHeroSection => 'Показати розділ Героя';
	@override String get showHomeBackdrop => 'Показати будинок Backdrop Artwork';
	@override String get showHomeBackdropDescription => 'Показати великі твори мистецтва за прикладом Домашніх рядків';
	@override String get contentScreensaverEnabled => 'Скриншоти контенту';
	@override String get contentScreensaverEnabledDescription => 'Показати повний екран художньої роботи після того, як додаток був ідл';
	@override String get contentScreensaverDelay => 'Завантажити екран після';
	@override String get contentScreensaverLibraries => 'Бібліотека Screensaver';
	@override String get contentScreensaverLibrariesDescription => 'Виберіть, які бібліотеки надають екран-захист художньої роботи. якщо жодного не вибрано, художній твір з усіх бібліотек використовується.';
	@override String get contentScreensaverAllLibraries => 'Всі медіатеки';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} вибраних бібліотек';
	@override String get contentScreensaverNoLibraries => 'Бібліотеки з підключеними медіа не доступні.';
	@override String get contentScreensaverDismissHint => 'Натисніть будь-який кнопка або натисніть, щоб відмовитися';
	@override String get newEpisodeNotifications => 'Новий епізод повідомлень';
	@override String get newEpisodeNotificationsDescription => 'Попередження, коли до шоу додається новий епізод, ви застрягли. перевіряти, поки відкритий Plezy.';
	@override String get continueWatchingRowSize => 'Продовжуйте спостерігати за розміром ряду';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} картки';
	@override String get rowSizeCompact => 'компактний';
	@override String get rowSizeStandard => 'Стандартний';
	@override String get rowSizeLarge => 'Більший';
	@override String get continueWatchingAction => 'Продовжуйте спостерігати за діяльністю';
	@override String get continueWatchingPlay => 'Грати';
	@override String get continueWatchingDetails => 'Відкриті деталі';
	@override String get episodeAction => 'Епізод дії';
	@override String get episodePlay => 'Грати';
	@override String get episodeDetails => 'Відкриті деталі';
	@override String get useGlobalHubs => 'Використовуйте Home Layout';
	@override String get useGlobalHubsDescription => 'Показати об\'єднані будинкові центри. в іншому випадку використовуйте рекомендації бібліотеки.';
	@override String get showServerNameOnHubs => 'Показати назву сервера на Hubs';
	@override String get showServerNameOnHubsDescription => 'Завжди показуйте імена серверів в заголовках hub.';
	@override String get groupLibrariesByServer => 'Групові бібліотеки за сервером';
	@override String get groupLibrariesByServerDescription => 'Бібліотеки групової сторінки під кожним медіа-сервером.';
	@override String get alwaysKeepSidebarOpen => 'Завжди тримайте стіни відкритими';
	@override String get alwaysKeepSidebarOpenDescription => 'Базовий бар залишається розширеним, а вміст-об\'єкт адаптується до';
	@override String get showUnwatchedCount => 'Показати невідомий номер';
	@override String get showUnwatchedCountDescription => 'Дивитись непереглянутий епізод рахувати на шоу і сезони';
	@override String get showWatchedIndicators => 'Показати переглянуті показники';
	@override String get showWatchedIndicatorsDescription => 'Показати перевірку на переглянутих фільмах, шоу і епізодах';
	@override String get showEpisodeNumberOnCards => 'Показати номер епізоду на картах';
	@override String get showEpisodeNumberOnCardsDescription => 'Показати сезон і номер епізоду на епізодних картах';
	@override String get showSeasonPostersOnTabs => 'Показати сезонні плакати на таблицях';
	@override String get showSeasonPostersOnTabsDescription => 'Показати плакат кожного сезону над його клавішкою';
	@override String get tvFullCardLayout => 'Повний телеканал';
	@override String get tvFullCardLayoutDescription => 'Використовуйте тільки телевізійні картки з іменами акторів';
	@override String get focusGlow => 'Фокус Глоу';
	@override String get focusGlowDescription => 'Натисніть м\'який світло навколо зосередженої картки';
	@override String get visualEffects => 'Візуальні ефекти';
	@override String get visualEffectsAuto => 'Авто';
	@override String get visualEffectsAutoDescription => 'Автоматично зменшується вплив на пристрої з низькою потужністю';
	@override String get visualEffectsFull => 'Повний';
	@override String get visualEffectsReduced => 'Зниження';
	@override String get visualEffectsReducedDescription => 'Менше анімацій і низькорозв\'язаних творів мистецтва';
	@override String get hideSpoilers => 'Сховання споюлерів для невідомих епізодів';
	@override String get hideSpoilersDescription => 'Блур тюменні і описи для несподіваних епізодів';
	@override String get playerBackend => 'Гравець Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Декодування харчового обладнання';
	@override String get hardwareDecodingDescription => 'Використовуйте прискорення харчових пристроїв, коли вони доступні';
	@override String get playbackBuffer => 'Завантажити Playback Buffer';
	@override String get playbackBufferAuto => 'Автомобіль (загальна кількість автомобілів)';
	@override String get playbackBufferLarge => 'Більший';
	@override String get playbackBufferExtraLarge => 'Дуже великий';
	@override String get playbackBufferDescription => 'Баффер більше проти нестабільних зв\'язків. також обмежений розміром Баффер.';
	@override String get streamBufferSize => 'Буффер розмір';
	@override String streamBufferSizeValue({required Object size}) => '${size} Мб';
	@override String get streamBufferSizeDescription => 'Скільки відео потрібно завантажувати, коли грати безпосередньо. транскоди зупиняються на власному транскоді сервера. 0 = Авто';
	@override String get streamBufferSizeExoNote => 'Замінює Playback Buffer при налаштуванні, закріплений на половині межі пам\'яті програми';
	@override String get streamBufferMegabytes => 'Мегабайт';
	@override String get defaultQualityTitle => 'дефектна якість';
	@override String get cellularQualityTitle => 'Дефіцитна якість на клітині';
	@override String get remoteQualityTitle => 'Кваліфікація віддаленого потоку';
	@override String get remoteQualitySameAsDefault => 'Як і стандартна якість';
	@override String get cellularQualitySameAsDefault => 'Як і стандартна якість';
	@override String get directPlayCoveredQuality => 'Переглянути відео в оригінальній якості';
	@override String get directPlayCoveredQualityDescription => 'Пряма відтворення відео вже в межах межі якості замість перекодування';
	@override String get videoCodecs => 'Кодекс відео';
	@override String get videoCodecsDescription => 'Неперевірені кодек перешифруються сервером';
	@override String get videoCodecsAlwaysAccepted => 'Завжди прийнято';
	@override String get musicQualityTitle => 'Якість музики';
	@override String get subtitleStyling => 'Стилізація субтитрів';
	@override String get subtitleStylingDescription => 'Підвищення субтитра вигляду';
	@override String get smallSkipDuration => 'Маленький Скіп Тривалість';
	@override String get largeSkipDuration => 'Довжина великого стрибка';
	@override String get rewindOnResume => 'Повернення на резюме';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунда',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунди',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунд',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунди',
	);
	@override String get defaultSleepTimer => 'Заборонений час сну';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилина',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилини',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилин',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилини',
	);
	@override String get rememberTrackSelections => 'Зауважимо, що вибір трак за шоу/фільм';
	@override String get chooseTracksBeforePlayback => 'Виберіть аудіо та субтитри перед відтворенням';
	@override String get chooseTracksBeforePlaybackDescription => 'Виберіть джерело аудіо і субтитри, перш ніж починається кожен відео.';
	@override String get alwaysShowSubtitlesOnDevice => 'Завжди показуйте субтитри на цьому пристрої';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Коли сервер не має підзаголовок, виберіть траку локально.Це ніколи не змінює переваги сервера.';
	@override String get autoDownloadPreferredSubtitle => 'Фетч відсутній улюблений субтитри мови';
	@override String get autoDownloadPreferredSubtitleDescription => 'Виберіть доступний субтитр у вашому улюбленому мові локально. якщо жодного немає, попросіть сервера завантажити один, коли підтримується.';
	@override String get rememberTrackSelectionsDescription => 'Зберігати аудіо і субтитри виборів шоу або фільму на цьому пристрої';
	@override String get rememberTrackSelectionsBackendRule => 'Працює локально з Plex, Jellyfin, і Emby; Plex і Jellyfin також може зберегти вибір на сервері';
	@override String get followServerTrackSelections => 'Використовуйте серверні відгуки за епізодом';
	@override String get followServerTrackSelectionsDescription => 'При зміні епізоду застосовуйте аудіо та підзаголовки, вибрані на сервері, а не переносять поточний вибір.';
	@override String get resumeMusicOnLaunch => 'Згадаймо музичну сесію';
	@override String get resumeMusicOnLaunchDescription => 'Відкрити останню пісню зупинився, де вона залишилася, коли програма стартує';
	@override String get showChapterMarkersOnTimeline => 'Показати розділ знаків на пошуковій смузі';
	@override String get showChapterMarkersOnTimelineDescription => 'Секмент пошукової смуги на межі розділу';
	@override String get specialsOrdering => 'Особливості в порядку епізоду';
	@override String get specialsOrderingDescription => 'Де спеціальні грають в порядку годинника шоу';
	@override String get specialsOrderingServer => 'Слідкуйте за замовленням сервера';
	@override String get specialsOrderingAirDate => 'Повітряна дата перевезення';
	@override String get specialsOrderingLast => 'Після регулярних сезонів';
	@override String get clickVideoTogglesPlayback => 'Натисніть на відео, щоб зіграти / перервати';
	@override String get clickVideoTogglesPlaybackDescription => 'Натисніть на відео, щоб грати / перервати замість того, щоб показати контроль.';
	@override String get videoPlayerControls => 'Контроль відеоплеєра';
	@override String get keyboardShortcuts => 'Ключові короткострокові';
	@override String get keyboardShortcutsDescription => 'Налаштування клавіатурних скорочень';
	@override String get videoPlayerNavigation => 'Відеопередач навігація';
	@override String get videoPlayerNavigationDescription => 'Використовуйте ключі стрілки для навігації контролів відеоплеєра';
	@override String get watchTogetherRelay => 'Дивіться реліз';
	@override String get watchTogetherRelayDescription => 'Відкрита партія розповсюджується, якщо ви не встановили власний';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Введіть дійсну базову URL-адресу ретранслятора з HTTP або HTTPS.';
	@override String get crashReporting => 'Звіт про катастрофу';
	@override String get crashReportingDescription => 'Надіслати повідомлення про аварії, щоб допомогти поліпшити додаток';
	@override String get debugLogging => 'Дебютний логінг';
	@override String get debugLoggingDescription => 'Дозволяється детальний логінг для вирішення проблем';
	@override String get viewLogs => 'Переглянути логіки';
	@override String get viewLogsDescription => 'Переглянути логотипи';
	@override String get clearImageCache => 'Чистий зображення Cache';
	@override String get clearImageCacheDescription => 'Зображення можуть завантажуватися повільніше, поки не завантажуються знову.';
	@override String get clearImageCacheSuccess => 'Зображення каше успішно очищено';
	@override String get resetSettings => 'Реабілітація налаштувань';
	@override String get resetSettingsDescription => 'Відновлення стандартних налаштувань.Це не може бути недійсним.';
	@override String get resetSettingsSuccess => 'Перезавантаження успішно';
	@override String get backup => 'Резервна копія';
	@override String get exportSettings => 'Експортні налаштування';
	@override String get exportSettingsDescription => 'Зберегти свої переваги до файлу';
	@override String get exportSettingsSuccess => 'Налаштування експортуються';
	@override String get importSettings => 'Ввезення налаштувань';
	@override String get importSettingsDescription => 'Відновлення переваг з файлу';
	@override String get importSettingsConfirm => 'Це замінить ваші поточні налаштування.';
	@override String get importSettingsSuccess => 'Ввезені налаштування';
	@override String get importSettingsInvalidFile => 'Цей файл не є дійсним експортом PlezyNG налаштувань';
	@override String get importSettingsNoUser => 'Зареєструйтесь перед імпортуванням';
	@override String get cloudBackup => 'Створення Cloud Backup';
	@override String get cloudBackupDescription => 'Збережіть резервну копію переносних налаштувань за адресою WebDAV через HTTPS. Підключення до серверів і дані входу залишаться на цьому пристрої.';
	@override String get cloudBackupUrl => 'WebDAV URL файлу JSON';
	@override String get cloudBackupUsername => 'Ім’я користувача';
	@override String get cloudBackupPassword => 'Пароль';
	@override String get cloudBackupSaved => 'Облачна резервна резервна дестинація збережена';
	@override String get cloudBackupNow => 'Повернутись зараз';
	@override String get cloudBackupComplete => 'Завантажити Backup';
	@override String get cloudBackupRestore => 'Відновлення резервного коду';
	@override String get cloudBackupRestoreConfirm => 'Це замінить відповідні портативні налаштування на цьому пристрої.';
	@override String get cloudBackupRestored => 'Налаштування відновлено з облачної резервної копії';
	@override String get shortcutsReset => 'Швидкість відновлення до дефолтів';
	@override String get resetShortcutsConfirm => 'Це замінить ваші пристосовані скорочення дефолтами.';
	@override String get about => 'Про';
	@override String get aboutDescription => 'Інформація та ліцензії';
	@override String get updates => 'Оновлення';
	@override String get updateAvailable => 'Оновлення доступне';
	@override String get checkForUpdates => 'Перевірте оновлення';
	@override String get autoCheckUpdatesOnStartup => 'Автоматично перевіряти оновлення на стартапі';
	@override String get autoCheckUpdatesOnStartupDescription => 'Повідомлення про те, коли оновлення буде доступно на запуску';
	@override String get validationErrorEnterNumber => 'Будь ласка, введіть діюче число';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Вона повинна бути між ${min} і ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Швидкість, яка вже присвоєна ${action}';
	@override String shortcutUpdated({required Object action}) => 'Про це повідомляється в повідомленні ${action}';
	@override String get saveFailed => 'Зміни не можна врятувати, спробуйте знову.';
	@override String get autoPlayAndSkip => 'Автомобільні і скачальні';
	@override String get autoPlayNextEpisode => 'Автомобільні перегляди наступного епізоду';
	@override String get autoPlayNextEpisodeDescription => 'Почнемо наступний епізод автоматично, коли закінчується';
	@override String get shuffleStartsFromBeginning => 'Шуффлі починається з самого початку';
	@override String get shuffleStartsFromBeginningDescription => 'Почніть кожен епізод з самого початку, коли занурюється, а не повторюється';
	@override String get plexCinemaPreRoll => 'Використання серверного кіноінтросу';
	@override String get plexCinemaPreRollDescription => 'Грати в конфігуровані Plex попередні ролі або Jellyfin і Emby входи перед початком фільму.';
	@override String get playNextCountdown => 'Завантажити Next Countdown';
	@override String get playNextCountdownImmediate => 'Грати негайно';
	@override String get skipIntroMode => 'Скіп Інтро';
	@override String get skipIntroModeOffDescription => 'Грати в інтроси нормально без кнопки скачування';
	@override String get skipIntroModeButtonDescription => 'Показати кнопку скип, коли стартує вхід';
	@override String get skipIntroModeAutoDescription => 'Автоматично відправляйте вхід після затримки нижче';
	@override String get skipCreditsMode => 'Кредити Скіп';
	@override String get skipCreditsModeOffDescription => 'Грати кредити зазвичай без кнопки скип';
	@override String get skipCreditsModeButtonDescription => 'Показати кнопку скип, коли починаються кредити';
	@override String get skipCreditsModeAutoDescription => 'Скачати кредити автоматично і грати в наступний епізод';
	@override String get skipAdsMode => 'Скачати рекламу';
	@override String get skipAdsModeOffDescription => 'Відкриті оголошення зазвичай відтворюються без кнопки сканування';
	@override String get skipAdsModeButtonDescription => 'Показати кнопку скачати, коли Plex виявляє рекламу';
	@override String get skipAdsModeAutoDescription => 'Автоматично скачати знайдені оголошення після затримки нижче';
	@override String get musicPlayback => 'Музика Playback';
	@override String get musicSweetFades => 'Солодкі ФАДЕ';
	@override String get musicSweetFadesDescription => 'Фейд-музика на краях сліду, коли Plex має дані про голос.';
	@override String get skipMarkerModeOff => 'Вимкнути';
	@override String get skipMarkerModeButton => 'Показати кнопку';
	@override String get skipMarkerModeAuto => 'Автоматичний';
	@override String get forceSkipMarkerFallback => 'Форс Фаллбак Маркерс';
	@override String get forceSkipMarkerFallbackDescription => 'Використовуйте шаблони заголовку розділу, навіть якщо Plex має маркери';
	@override String get theIntroDbFallback => 'Використовуйте TheIntroDB як інтро-пальбак';
	@override String get theIntroDbFallbackDescription => 'Використовуйте час спільноти тільки тоді, коли сервер не має вхідного знака.';
	@override String get autoSkipDelay => 'Автомобіль відкладає';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Залишилося ${seconds} секунди, перш ніж автоматично скачати';
	@override String get introPattern => 'Вхідний маркер';
	@override String get introPatternDescription => 'Регекс-патрий, щоб відповідати інтро-маркерам в заголовках розділів';
	@override String get creditsPattern => 'Кредитний маркер';
	@override String get creditsPatternDescription => 'Регекс-патрий, щоб порівняти кредитні маркери в заголовках';
	@override String get prerolls => 'Проролів';
	@override String get playPrerollsBeforeMovies => 'Грати в преролі перед фільмами';
	@override String get playPrerollsBeforeMoviesDescription => 'Грати випадковий кліп з вашого вибору нижче перед кожним фільмом. натисніть назад, щоб перервати.';
	@override String get prerollLibrary => 'Бібліотека Прероль';
	@override String get prerollLibraryNotSet => 'Не встановлюйте';
	@override String get prerollLibraryNoneFound => 'Бібліотеки на серверах не знайдено.';
	@override String get prerollSelection => 'Вибрані преролі';
	@override String get prerollSelectionPickLibraryFirst => 'Перш за все, вибирайте бібліотеку';
	@override String get prerollSelectionNoneSelected => 'Не вибрані преролії';
	@override String prerollSelectionCount({required Object count}) => '${count} вибрано';
	@override String get prerollItemPicker => 'Вибір преролів';
	@override String get prerollItemPickerLoadFailed => 'Не можна було завантажувати матеріали з цієї бібліотеки.';
	@override String get invalidRegex => 'Недостатній регулярний вираження';
	@override String get regex => 'Регулярне вираження';
	@override String get downloads => 'Завантаження';
	@override String get downloadLocationDescription => 'Виберіть, де зберігати завантажений контент';
	@override String get downloadLocationDefault => 'За замовчуванням (App Storage)';
	@override String get downloadLocationCustom => 'Кваліфіковані місця';
	@override String get selectFolder => 'Вибір папки';
	@override String get resetToDefault => 'Повернення до дефолту';
	@override String currentPath({required Object path}) => 'Теперішній номер: ${path}';
	@override String get downloadLocationChanged => 'Змінено місце розташування';
	@override String get downloadLocationReset => 'Завантажити місце розташування Reset to default';
	@override String get downloadLocationInvalid => 'Вибраний папку не можна писати';
	@override String get downloadLocationPickerUnavailable => 'Вибір папки не доступний на цьому пристрої';
	@override String get downloadOnWifiOnly => 'Завантажити на Wi-Fi тільки';
	@override String get downloadOnWifiOnlyDescription => 'Забороняється завантажувати, коли на клітинних даних';
	@override String get autoRemoveWatchedDownloads => 'Авто-усунути переглянуті завантаження';
	@override String get autoRemoveWatchedDownloadsDescription => 'Автоматично видаляти переглянуті завантаження';
	@override String get autoDownloadContinueWatching => 'Автомобільні завантаження Продовжувати дивитися';
	@override String get autoDownloadContinueWatchingDescription => 'Зберігайте елементи на вашій скриньці Продовження перегляду завантажені, і видаляйте їх, як тільки вони покинуть скриньку';
	@override String get downloadQuality => 'Завантажити якість';
	@override String get downloadQualityDescription => 'Plex підготує конвертовану копію в її копії завантаження. Jellyfin і Emby транскод під час завантаження файлу; перервані передачі можуть знадобитися для перезавантаження.';
	@override String get askDownloadQualityEachTime => 'Вибір якості для кожного завантаження';
	@override String get askDownloadQualityEachTimeDescription => 'Показати якісний пікер перед тим, як переглянути кожен відеозавантаження';
	@override String get cellularDownloadBlocked => 'Завантаження блокуються на мобільному телефоні. використовуйте Wi-Fi або змініть налаштування.';
	@override String get maxVolume => 'Максимальна гучність';
	@override String get maxVolumeDescription => 'Дозволити підсилення гучності понад 100% для медіа з тихим звуком';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Річ у багатій присутності';
	@override String get discordRichPresenceDescription => 'Покажіть, що ви дивитеся на Discord';
	@override String get services => 'Сервіси';
	@override String get servicesDescription => 'Зв\'яжіться Trakt, MyAnimeList, Seerr, і багато іншого';
	@override String get manageLibrariesDescription => 'Завантажити та приховати бібліотеки';
	@override String get companionRemoteServer => 'Віддалені сервери';
	@override String get companionRemoteServerDescription => 'Дозвольте мобільним пристроям у вашій мережі контролювати цю програму';
	@override String get companionRemoteServerStartFailed => 'Не можна було запустити сервер товаришів';
	@override String get companionRemoteServerStopFailed => 'Не можна було зупинити сервер товаришів';
	@override String get autoPip => 'Створення Auto Picture-in-Picture';
	@override String get autoPipDescription => 'Автоматично введіть зображення в зображення, коли ви покидаєте додаток під час відтворення';
	@override String get matchContentFrameRate => 'Матч Content Frame Rate';
	@override String get matchContentFrameRateDescription => 'Матч показує відновлювальний показ до відеоконтенту';
	@override String get matchContentResolution => 'Матч контент резолюція';
	@override String get matchContentResolutionDescription => 'Перемістіть дисплей на різноманітність відео так, щоб ваш телевізор працював упсскальними.';
	@override String get matchRefreshRate => 'Матч відновлює темпи';
	@override String get matchRefreshRateDescription => 'Матч показує швидкість оновлення на повній екрані';
	@override String get matchDynamicRange => 'Динамічний діапазон';
	@override String get matchDynamicRangeDescription => 'Перемістіть HDR для HDR-контенту, а потім поверніться до SDR';
	@override String get displaySwitchDelay => 'Затримка дисплею Switch';
	@override String get tunneledPlayback => 'Тунель Playback';
	@override String get tunneledPlaybackDescription => 'Використовуйте відео-туннелінг. Вимкніть, якщо HDR відтворює чорне відео або рух-стутери.';
	@override String get audioPassthrough => 'Анонс аудіо';
	@override String get audioPassthroughDescription => 'Надіслати звук Dolby/DTS на ваш приймач або телевізор без перекодування, зберігаючи звук навколо.';
	@override String get audioPassthroughDescriptionApple => 'Використовуйте корінний декодер Dolby Apple для Dolby Digital Plus, в тому числі Atmos. DTS і TrueHD все ще грають як багатоканальний PCM.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Використовувати власний декодер Dolby від Apple для Dolby Digital Plus, зокрема Atmos. На iOS, iPadOS і tvOS 26 або новіших TrueHD Atmos та DTS:X відтворюються як просторове аудіо. Інші доріжки DTS і TrueHD відтворюються як багатоканальний PCM. Вимкніть, якщо немає звуку.';
	@override String get audioPassthroughOverriddenByNormalization => 'Вимкніть, поки звукова нормалізація на';
	@override String get audioChannelLimit => 'Аудіоканали';
	@override String get audioChannelLimitDescription => 'Змішайте розшифрований аудіо для голосових пристроїв, наушників або налаштувань HDMI, які не можуть грати в будь-який канал';
	@override String get audioChannelLimitOriginal => 'Оригінальна';
	@override String get audioChannelLimitOriginalDescription => 'Грати в кожен канал на трасі';
	@override String get audioChannelLimitSurround51 => 'До 5.1';
	@override String get audioChannelLimitSurround51Description => 'Змішайте 7.1 до 5.1 для телевізорів і приймачів, які приймають тільки 5.1 ПКМ.';
	@override String get audioChannelLimitStereo => 'Стерео';
	@override String get audioChannelLimitStereoDescription => 'Змішайте до двох каналів для стерео-голосних пристроїв або наушників.';
	@override String get downmixCenterBoost => 'Створення Channel Boost';
	@override String downmixCenterBoostValue({required Object db}) => '${db} дБ';
	@override String get downmixCenterBoostLabel => 'Завантажити (dB)';
	@override String get downmixCenterBoostShort => 'ДБ';
	@override String get audioDownmixNormalize => 'Використання об\'єктів Downmix';
	@override String get audioDownmixNormalizeDescription => 'Знизити суміш, щоб уникнути схилу. вимкніть, щоб зберегти оригінальний обсяг (може порушити голосні сцени).';
	@override String get dvConversionMode => 'Dolby Vision Перетворення';
	@override String get dvConversionModeDescription => 'Виберіть, як обробляються файли Dolby Vision Профіль 7 .';
	@override String get dvConversionAuto => 'Авто';
	@override String get dvConversionNative => 'Інвалідність / Disabled';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Використання пристрою здатності виявлення і нормального поведінки падіння';
	@override String get dvConversionNativeDescription => 'ДВ7 і ДВ-конверсійний ретрит';
	@override String get dvConversionDv81Description => 'Конвертація силового RPU на Dolby Vision профіль 8.1';
	@override String get dvConversionHevcStripDescription => 'Стрип Dolby Vision РПУ/ЕЛ шари і нинішня плоска HEVC';
	@override String get disableDolbyVision => 'Завантажити Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Грати в файл HDR10 або HLG-слой замість Dolby Vision, коли у нього є один';
	@override String get hdrSdrConversion => 'Конвертація HDR до SDR';
	@override String get hdrSdrConversionDescription => 'Виберіть, що конвертує HDR відео, коли дисплей не може показати HDR.';
	@override String get hdrSdrConversionAuto => 'Авто';
	@override String get hdrSdrConversionAutoDescription => 'Пристрій на Android 9 і пізніше, гравець на попередніх версіях';
	@override String get hdrSdrConversionDevice => 'Пристрій';
	@override String get hdrSdrConversionDeviceDescription => 'Найшвидше, але кольори залежить від пристрою';
	@override String get hdrSdrConversionPlayer => 'Програвач';
	@override String get hdrSdrConversionPlayerDescription => 'Консистентні кольори, але 4K може зіткнутися з низькоповерховими телевізійними ящиками';
	@override String get deinterlace => 'Відключення';
	@override String get deinterlaceDescription => 'Видалення об\'єктивних артефактів з переміщеного відео (mpv гравців тільки)';
	@override String get deinterlaceOff => 'Вимкнути';
	@override String get deinterlaceOffDescription => 'Показати відео, як він декодирований';
	@override String get deinterlaceVideo => 'Відео';
	@override String get deinterlaceVideoDescription => 'Для відеозапису для телевізора, таких як спорт, новини та концерти';
	@override String get deinterlaceFilm => 'Фільми';
	@override String get deinterlaceFilmDescription => 'Відновлюйте оригінальні рамки фільму та анімації, телецентовані до 29,97 фп/с, поширені на DVD-дисках NTSC. Відеозапис для телевізійних стутерів.';
	@override String get requireProfileSelectionOnOpen => 'Запросити профіль на відкритому пристрої';
	@override String get requireProfileSelectionOnOpenDescription => 'Показати вибір профілю кожен раз, коли відкривається додаток';
	@override String get forceTvMode => 'Мода телевізора';
	@override String get forceTvModeDescription => 'Для пристроїв, які не автоматично виявляються, необхідно перезавантажувати.';
	@override String get startInFullscreen => 'Почнемо з повного екрану';
	@override String get startInFullscreenDescription => 'Відкрийте PlezyNG в режимі повного екрану на запуску';
	@override String get exitFullscreenOnPlayerClose => 'Повний екран виходу на гравця закритий';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Автоматично виходить повний екран при закритті відеоплеєра';
	@override String get autoHidePerformanceOverlay => 'Автоматичний прикритий показник';
	@override String get autoHidePerformanceOverlayDescription => 'Завантажити перелік продуктивності за допомогою контролів відтворення';
	@override String get showNavBarLabels => 'Показати Navigation Bar Labels';
	@override String get showNavBarLabelsDescription => 'Показати текстові етикетки під іконами смуги навігації';
	@override String get startupSection => 'Розділ Startup';
	@override String get preferredServer => 'Улюблений сервер';
	@override String get preferredServerDescription => 'Приоритетним є результати цього сервера, зберігаючи доступ до кожного підключеного сервера.';
	@override String get preferredServerAutomatic => 'Автоматичний';
	@override String get showExploreTab => 'Показати таб';
	@override String get showExploreTabDescription => 'Показати кнопку Explore з контентом з Plex Discover та підключених відстежувачів';
	@override String get hideEmptyLibraries => 'Закрийте порожні бібліотеки';
	@override String get hideEmptyLibrariesDescription => 'Усунути бібліотеки з сервером-репортажним числом елементів нуля з навігації.';
	@override String get liveTvDefaultFavorites => 'Завантажити улюблені канали';
	@override String get liveTvDefaultFavoritesDescription => 'Показати тільки улюблені канали при відкритті Live TV';
	@override String get general => 'Загальні';
	@override String get generalDescription => 'Мова, стартап і поведінка вікна';
	@override String get languageAndRegion => 'Мова і регіон';
	@override String get startup => 'Стартує';
	@override String get display => 'Подання';
	@override String get libraryAndCards => 'Бібліотека & Карти';
	@override String get homeScreen => 'Домашній екран';
	@override String get navigation => 'Навігація';
	@override String get window => 'вікно';
	@override String get liveTv => 'Прямий ефір';
	@override String get player => 'Програвач';
	@override String get videoAndDisplay => 'Відео та дисплей';
	@override String get audio => 'Аудіо';
	@override String get quality => 'Якість';
	@override String get subtitles => 'Субтитри';
	@override String get seekAndTiming => 'Пошук і час';
	@override String get behavior => 'поведінка';
	@override String get gestures => 'Гестюр';
	@override String get gestureBrightnessSwipe => 'Світло Свіп';
	@override String get gestureBrightnessSwipeDescription => 'Перемішайте вгору або вниз на лівому краю, щоб налаштувати яскравість';
	@override String get gestureVolumeSwipe => 'Обсяг Swipe';
	@override String get gestureVolumeSwipeDescription => 'Перемішайте вгору або вниз на правому краю, щоб встановити обсяг';
	@override String get gesturePinchToZoom => 'Пінч до зоуму';
	@override String get gesturePinchToZoomDescription => 'Натисніть на відео, щоб зумувати в або вийти';
	@override String get gestureSeekSwipe => 'Пошук Swipe';
	@override String get gestureSeekSwipeDescription => 'Перемішайте ліворуч або праворуч в будь-якій точці відео, щоб шукати; випустіть, щоб стрибнути';
	@override String get rememberBrightnessLevel => 'Згадайте рівень яскравості';
	@override String get rememberBrightnessLevelDescription => 'Почніть відтворювати на яскравості, встановленому останньою перемикачею';
	@override String get controls => 'Елементи керування';
	@override String get rememberPlayerChanges => 'Зміни гравців';
	@override String get rememberPlayerChangesDescription => 'де зміна, зроблена під час відтворення, зберігається і повторюється з';
	@override String get scopePlaybackSpeed => 'Швидкість відтворення';
	@override String get scopeShaderPreset => 'Шейдер Пресет';
	@override String get scopeAspectRatio => 'Співвідношення сторін';
	@override String get scopeSyncOffsets => 'Audio & Subtitle Співвідношення';
	@override String get playerScopeOff => 'Не врятуйте';
	@override String get playerScopeGlobal => 'всюди';
	@override String get playerScopeLibrary => 'за бібліотекою';
	@override String get playerScopeTitle => 'Про шоу або фільм';
	@override String get exportDialogTitle => 'Експорт PlezyNG установки';
	@override String get followSystem => 'Мова системи';
	@override String get followAppLanguage => 'Як у мові інтерфейсу';
	@override String get regionFormat => 'Регіональні формати';
	@override String get regionFormatDescription => 'Виберіть формат відображення дат, чисел і одиниць вимірювання.';
	@override String get metadataLanguage => 'Мова метаданих';
	@override String get metadataLanguageDescription => 'Бажана мова назв та описів, якщо сервер її підтримує. Налаштування звуку й субтитрів залишаються окремими.';
	@override String get experimentalDolbyVision => 'Експериментальний Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'Під час наступного відтворення використовувати експериментальний рендерер FEL. Потрібна окрема збірка рушія.';
	@override String get dvExperimentUnavailableDescription => 'Цей експеримент наразі доступний лише в Linux.';
	@override String get dvCompatibilityFallback => 'Резервний режим сумісності';
	@override String get dvCompatibilityFallbackDescription => 'Використовувати стандартний рендерер, якщо експеримент не запускається. Дані FEL можуть бути втрачені.';
	@override String get dvExperimentDiagnostics => 'Журнал відеоексперименту';
	@override String get dvExperimentDiagnosticsDescription => 'Увімкнути докладні журнали програвача під час наступного відтворення.';
}

// Path: themeEditor
class _Translations$themeEditor$uk extends Translations$themeEditor$en {
	_Translations$themeEditor$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Будівництво';
	@override String get presets => 'Президи';
	@override String get custom => 'Користувацький';
	@override String get customEmpty => 'Наразі не створено';
	@override String get editCustom => 'Редагувати тематику';
	@override String get editCustomDescription => 'Виберіть колір самостійно';
	@override String get locked => 'Доступ до життєдіяльності необхідний';
	@override String get savedLocked => 'Збережений — доступний з доступом до життя';
	@override String get title => 'Кваліфіковані теми';
	@override String get startFrom => 'Почнемо з';
	@override String get startFromDescription => 'Копіюйте всі кольори з іншої теми';
	@override String get colors => 'Кольори';
	@override String get preview => 'Попередній перегляд';
	@override late final _Translations$themeEditor$slots$uk slots = _Translations$themeEditor$slots$uk._(_root);
	@override String get opacity => 'Опаситність';
	@override String get hexHint => '#RRGGBB або #AARRGGBB';
	@override String get fromOtherThemes => 'з інших тем';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$uk contrast = _Translations$themeEditor$contrast$uk._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, нижче рекомендованої ${minimum}:1';
	@override String get discardTitle => 'Не вистачає змін?';
	@override String get discardMessage => 'Незбережені зміни кольорів буде втрачено.';
	@override String get discard => 'Дискард';
	@override String previewCardTitle({required Object number}) => 'Епізод ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} хвилини';
	@override String get previewSwitch => 'Автомобільний';
	@override String get previewMutedText => 'Другий текст читається таким чином.';
}

// Path: search
class _Translations$search$uk extends Translations$search$en {
	_Translations$search$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Пошук фільмів, шоу, музики...';
	@override String get tryDifferentTerm => 'Спробуйте інший термін пошуку';
	@override String get searchYourMedia => 'Знайдіть свої медіа';
	@override String get enterTitleActorOrKeyword => 'Введіть заголовок, актор або ключове слово';
	@override String get people => 'Люди';
}

// Path: hotkeys
class _Translations$hotkeys$uk extends Translations$hotkeys$en {
	_Translations$hotkeys$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Розташований короткометражний набір для ${actionName}';
	@override String get clearShortcut => 'Чистий короткий';
	@override String get noShortcutSet => 'Без короткострокових';
	@override String get currentShortcut => 'Теперішній короткостроковий:';
	@override String get pressToRecord => 'Виберіть для запису короткострокового';
	@override String get recordingShortcut => 'Натисніть скорочення зараз';
	@override late final _Translations$hotkeys$actions$uk actions = _Translations$hotkeys$actions$uk._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$uk extends Translations$fileInfo$en {
	_Translations$fileInfo$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Файли Info';
	@override String get overview => 'Опис';
	@override String get video => 'Відео';
	@override String get audio => 'Аудіо';
	@override String get subtitles => 'Субтитри';
	@override String get images => 'Вбудовані зображення';
	@override String get dataStreams => 'Дані потоків';
	@override String get lyrics => 'Текст пісні';
	@override String get file => 'Файл';
	@override String get attachments => 'Активісти';
	@override String get delivery => 'Доставка';
	@override String versionCounter({required Object index, required Object count}) => 'Версія ${index} з ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Файл ${index} з ${count}';
	@override String get noStreams => 'Сервер не повідомив про потоки для цього файлу.';
	@override String get copyPath => 'Копіювати шлях';
	@override String get pathCopied => 'Копіювати шлях файлу';
	@override String get codec => 'Кодек';
	@override String get codecTag => 'Тег кодека';
	@override String get resolution => 'Роздільна здатність';
	@override String get codedResolution => 'Кодирована резолюція';
	@override String get bitrate => 'Бітрейт';
	@override String get frameRate => 'Рамкова швидкість';
	@override String get rotation => 'Обертання';
	@override String get comment => 'Як';
	@override String get audioDescription => 'Опис аудіо';
	@override String get headerCompression => 'Головний компрес';
	@override String get sidecarFile => 'Файли Sidecar';
	@override String get transportTimestamp => 'Транспортний час';
	@override String get displayOffset => 'Завантажити Offset';
	@override String get previewFailureCode => 'Кодекс провалу';
	@override String get previewRetries => 'Предыдущая запись: Retries';
	@override String get aspectRatio => 'Співвідношення сторін';
	@override String get pixelAspectRatio => 'Розмір Pixel Aspect';
	@override String get profile => 'Профіль';
	@override String get level => 'Рівень';
	@override String get bitDepth => 'Розрядність';
	@override String get pixelFormat => 'Піксельний формат';
	@override String get colorSpace => 'Кольоровий простір';
	@override String get colorRange => 'Колірний діапазон';
	@override String get colorPrimaries => 'Основні кольори';
	@override String get colorTransfer => 'Передача кольору';
	@override String get chromaSubsampling => 'Хрома Субсамплінг';
	@override String get chromaLocation => 'Хрома розташування';
	@override String get scanType => 'Скенерний тип';
	@override String get interlaced => 'Переплетений';
	@override String get anamorphic => 'Анаморфний';
	@override String get referenceFrames => 'Референтні рамки';
	@override String get dynamicRange => 'Динамічний діапазон';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision Рівень';
	@override String get dolbyVisionVersion => 'Dolby Vision Видання';
	@override String get dolbyVisionLayers => 'Dolby Vision Склади';
	@override String get baseLayerCompatibility => 'Сумісність базового шару';
	@override String get avcBitstream => 'АВК Bitstream';
	@override String get nalLengthSize => 'Розмір довжини';
	@override String get scalingMatrix => 'Матриці для скалювання';
	@override String get streamIdentifier => 'Потік ідентифікатора';
	@override String get streamIndex => 'Індекс потоку';
	@override String get streamId => 'Потік ID';
	@override String get language => 'Мова';
	@override String get languageCode => 'Кодекс мови';
	@override String get streamTitle => 'Назва трак';
	@override String get channels => 'Канали';
	@override String get sampleRate => 'Частота дискретизації';
	@override String get spatialAudio => 'Космічний аудіо';
	@override String get textBased => 'Текст заснований';
	@override String get subtitleFormat => 'Формат сидіння';
	@override String get provider => 'Провайдер';
	@override String get matchScore => 'Матч Результати';
	@override String get externalDelivery => 'Їх можна подавати окремо';
	@override String get sidecarPath => 'Сидекарський шлях';
	@override String get sourceStream => 'Копіюється з';
	@override String get temporary => 'Тимчасовий';
	@override String get timeBase => 'База часу';
	@override String get overallBitrate => 'Всього Bitrate';
	@override String get path => 'Шлях';
	@override String get fileName => 'Назва файлу';
	@override String get size => 'Розмір';
	@override String get totalSize => 'загальний розмір';
	@override String get container => 'Контейнер';
	@override String get duration => 'Тривалість';
	@override String get previewThumbnails => 'Предыдущая статьяТумфаль';
	@override String get previewIndex => 'Індекс попереднього';
	@override String get packetLength => 'Довжина пакету';
	@override String get filePresent => 'Файл присутній';
	@override String get fileReadable => 'Читання сервера';
	@override String get streamPath => 'Потік шляху';
	@override String get optimizedForStreaming => 'Оптимізація для потоку';
	@override String get has64bitOffsets => '64-бітний Offsets';
	@override String get protocol => 'Протокол';
	@override String get mediaType => 'Тип медіа';
	@override String get sourceKind => 'Джерело: Kind';
	@override String get optimizedVersion => 'Оптимізована версія';
	@override String get optimizationTarget => 'Мета оптимізації';
	@override String get deletedAt => 'Знято';
	@override String get remoteSource => 'Віддалені джерела';
	@override String get infiniteStream => 'Нескінченний потік';
	@override String get directPlay => 'Пряма гра';
	@override String get directStream => 'Прямий потік';
	@override String get transcoding => 'Перекодування';
	@override String get etag => 'ETag';
	@override String get versionId => 'Версія ID';
	@override String get fileId => 'Файл ID';
	@override String get defaultAudioTrack => 'Завантажити Audio Track';
	@override String get defaultSubtitleTrack => 'Завантажити Subtitle Track';
	@override String get subtitlesOff => 'Вимкнути';
	@override String get flagDefault => 'За замовчуванням';
	@override String get flagForced => 'Примусово';
	@override String get flagSelected => 'Вибрані';
	@override String get flagExternal => 'Зовнішній';
	@override String get flagHearingImpaired => 'Погіршення слуху';
	@override String get flagDub => 'Дуб';
	@override String get flagOriginal => 'Оригінальна';
	@override String get channelsMono => 'Моно';
	@override String dolbyVisionProfile({required Object profile}) => 'Профіль ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$uk extends Translations$mediaMenu$en {
	_Translations$mediaMenu$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Марк як спостерігається';
	@override String get markAsUnwatched => 'Марк як невідомий';
	@override String get removeFromContinueWatching => 'Видалення від продовження спостереження';
	@override String get viewDetails => 'Переглянути деталі';
	@override String get goToSeries => 'Перейти до серіалу';
	@override String get shufflePlay => 'Шуффлей Play';
	@override String get shuffleNotAvailableOffline => 'Шанхай не доступний офлайн';
	@override String get fileInfo => 'Файли Info';
	@override String get deleteEpisodeFromServer => 'Видалення епізоду з сервера';
	@override String get deleteSeasonFromServer => 'Видалення сезону з сервера';
	@override String get deleteShowFromServer => 'Видалення з сервера';
	@override String get deleteMovieFromServer => 'Видалення фільму з сервера';
	@override String get deleteEpisodeTitle => 'Чи можна видалити цей епізод?';
	@override String get deleteSeasonTitle => 'Чи вийде цей сезон?';
	@override String get deleteShowTitle => 'Чи відмовилися ви від цього шоу?';
	@override String get deleteMovieTitle => 'Чи можна видалити цей фільм?';
	@override String get deleteEpisodeConfirm => 'Видалити епізод';
	@override String get deleteSeasonConfirm => 'Зняти сезон';
	@override String get deleteShowConfirm => 'Зняти шоу';
	@override String get deleteMovieConfirm => 'Знімайте фільм';
	@override String get deleteAnyway => 'Зніміть в будь-якому випадку';
	@override String confirmDeleteTarget({required Object title}) => 'Постійно видаляти ${title} з сервера?';
	@override String get deleteMultipleWarning => 'Це включає в себе всі епізоди і їх файли.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: 'Це видалить ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізод у ньому та його файл.',
		few: 'Це видалить усі ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізоди в ньому та їхні файли.',
		many: 'Це видалить усі ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізодів у ньому та їхні файли.',
		other: 'Буде видалено всі епізоди в цьому елементі (кількість: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) та їхні файли.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: 'Цей елемент зберігається в ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} файлі, який буде видалено.',
		few: 'Цей елемент зберігається в ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} файлах, і всі вони будуть видалені.',
		many: 'Цей елемент зберігається в ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} файлах, і всі вони будуть видалені.',
		other: 'Цей елемент зберігається у файлах (кількість: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}); усі ці файли буде видалено.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: 'У тому самому файлі зберігається ще ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізод, який також буде видалено:',
		few: 'У тому самому файлі зберігаються ще ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізоди, які також буде видалено:',
		many: 'У тому самому файлі зберігається ще ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізодів, які також буде видалено:',
		other: 'Інші епізоди в тому самому файлі (кількість: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) також буде видалено:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG не вдалося перевірити, які файли буде видалено, тому може бути видалено більше, ніж зазначений вище елемент. Скасуйте дію та спробуйте знову або видаліть попри це.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Сервер не надав відомостей про файли цього елемента, тому PlezyNG не може перевірити, які файли буде видалено. Може бути видалено більше, ніж зазначений вище елемент.';
	@override String get mediaDeletedSuccessfully => 'Медіа-елементи успішно видалені';
	@override String get mediaFailedToDelete => 'Не вдалося видалити медіа';
	@override String get rate => 'Оцінити';
	@override String get playFromBeginning => 'Грати з початку';
	@override String get playVersion => 'Грати в версію...';
}

// Path: rateSheet
class _Translations$rateSheet$uk extends Translations$rateSheet$en {
	_Translations$rateSheet$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Оцінити';
	@override String get server => 'Сервер';
	@override String get favorite => 'Обране';
	@override String get favorited => 'улюблений';
	@override String get saved => 'Збережений';
	@override String get notAvailable => 'Матч не знайдено';
	@override String get noConnectedServices => 'Підключіть сервіс в налаштуваннях, щоб оцінити там.';
}

// Path: accessibility
class _Translations$accessibility$uk extends Translations$accessibility$en {
	_Translations$accessibility$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, фільм';
	@override String mediaCardShow({required Object title}) => '${title}, телевізійне шоу';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'Переглянуто';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} відсотків переглянуто';
	@override String get mediaCardUnwatched => 'не переглянуто';
	@override String get tapToPlay => 'Натисніть, щоб грати';
	@override String get decrease => 'Зниження';
	@override String get increase => 'Збільшення';
	@override String decreaseValue({required Object label}) => 'Зниження ${label}';
	@override String increaseValue({required Object label}) => 'Збільшення ${label}';
	@override String get hue => 'ХІХ';
	@override String get saturation => 'Сатурн';
	@override String get brightness => 'Яскравість';
	@override String get hexColor => 'Hex колір';
	@override String get expandText => 'Розширення тексту';
	@override String get collapseText => 'Порушення тексту';
	@override String get alphabetNavigation => 'Алфавитна навігація';
	@override String get alphabetScrollHint => 'Проведіть угору або вниз, щоб переходити за літерами';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Рядок ${row} із ${rowCount}, стовпець ${column} із ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Роль ${row} з ${rowCount}';
	@override String get autoScrollPlay => 'Грати в Auto-Scroll';
	@override String get autoScrollPause => 'Відпочинок Auto-Scroll';
	@override String get hueShort => 'Х';
	@override String get saturationShort => 'С';
	@override String get valueShort => 'В';
	@override String get red => 'Червоний';
	@override String get green => 'Зелений';
	@override String get blue => 'Синій';
	@override String get redShort => 'Р';
	@override String get greenShort => 'G';
	@override String get blueShort => 'Б';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'РГБ';
	@override String get title => 'Доступність';
	@override String get summary => 'Текст, контраст, рух і контроль';
	@override String get systemHint => 'Налаштування доступності вашого пристрою завжди застосовуються. ці варіанти додають налаштування протягом PlezyNG.';
	@override String get readability => 'Читання та видимість';
	@override String get textSize => 'Додатковий текст розмір';
	@override String get preview => 'Читайте, слухайте і дивіться у своєму власному темпі.';
	@override String get boldText => 'Сміливий інтерфейс тексту';
	@override String get highContrast => 'Високий контраст';
	@override String get highContrastHint => 'Сильніший текст, виклади та індикатори фокусу на світлих або темних поверхнях.';
	@override String get interaction => 'Мотивація і взаємодія';
	@override String get reduceMotion => 'Зменшення руху';
	@override String get reduceMotionHint => 'Зупиняє анімацію індикатора фокусу, переходи сторінок і декоративні ефекти.';
	@override String get largeTargets => 'Більшість цілей';
	@override String get largeTargetsHint => 'Дайте спільним контролям більше місця для дотику і асистентської навігації.';
	@override String get navigationHint => 'Використовуйте Tab і Shift+Tab для переходу між елементами керування, Enter або пробіл для активації, а Escape або кнопку «Назад» для закриття. Коли книгу відкрито, доступні масштабування й налаштування читання.';
}

// Path: tooltips
class _Translations$tooltips$uk extends Translations$tooltips$en {
	_Translations$tooltips$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Шуффлей грає';
	@override String get playTrailer => 'Грати в трейлер';
	@override String get markAsWatched => 'Марк як спостерігається';
	@override String get markAsUnwatched => 'Марк як невідомий';
}

// Path: audioTracks
class _Translations$audioTracks$uk extends Translations$audioTracks$en {
	_Translations$audioTracks$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Анонс звуку ${n}';
}

// Path: videoControls
class _Translations$videoControls$uk extends Translations$videoControls$en {
	_Translations$videoControls$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадр',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадри',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадрів',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадри',
	);
	@override String get audioLabel => 'Аудіо';
	@override String get subtitlesLabel => 'Субтитри';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Літературний ящик';
	@override String get fillScreen => 'Завантажити екран';
	@override String get stretch => 'Розтягнути';
	@override String get lockRotation => 'Ротація замку';
	@override String get unlockRotation => 'Відключення ротації';
	@override String get timerActive => 'Активний час';
	@override String playbackWillPauseIn({required Object duration}) => 'Завантажити Playback в ${duration}';
	@override String get sleepTimerEndOfVideo => 'Кінець поточного відео';
	@override String get sleepTimerStopAtHeader => 'зупиніться на';
	@override String get sleepTimerDurationHeader => 'Час';
	@override String get playbackWillPauseAtEnd => 'Playback буде перерватися в кінці цього відео';
	@override String get stillWatching => 'Чи все ще дивитися?';
	@override String pausingIn({required Object seconds}) => 'Позиція в ${seconds}s';
	@override String get continueWatching => 'Продовжуйте';
	@override String get autoPlayNext => 'Автомобільні наступні';
	@override String get playNext => 'Наступне';
	@override String get playButton => 'Грати';
	@override String get pauseButton => 'Пауза';
	@override String get playbackPaused => 'Відпочинок';
	@override String get playbackResumed => 'Грати';
	@override String get loadingVideo => 'Завантажити відео';
	@override String get showPlaybackControls => 'Переглянути Playback Control';
	@override String get hidePlaybackControls => 'Завантажити Playback Control';
	@override String seekBackwardButton({required Object seconds}) => 'Пошук назад ${seconds} секунд';
	@override String seekForwardButton({required Object seconds}) => 'Пошук вперед ${seconds} секунд';
	@override String get previousButton => 'Попередній епізод';
	@override String get nextButton => 'Наступний епізод';
	@override String get previousChapterButton => 'Попередня сцена';
	@override String get nextChapterButton => 'Наступна сцена';
	@override String get muteButton => 'Заглушити';
	@override String get unmuteButton => 'Увімкнути звук';
	@override String get settingsButton => 'Створення Playback Settings';
	@override String get tracksButton => 'Аудіо та субтитри';
	@override String get trackSelectionTitle => 'Вибирайте сходинки перед відтворенням';
	@override String get trackSelectionAuto => 'Автоматичний вибір';
	@override String get chaptersButton => 'Розділи';
	@override String get versionQualityButton => 'Версія і якість';
	@override String get versionColumnHeader => 'Версія';
	@override String get qualityColumnHeader => 'Якість';
	@override String get qualityOriginal => 'Оригінальна';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Мб/с';
	@override String get transcodeUnavailableFallback => 'Перешифрування недоступне — грати в оригінальну якість';
	@override String get subtitleUnavailableFallback => 'Вибрані субтитри не можуть бути завантажені — продовжувати без субтитри';
	@override String get pipButton => 'Модуль зображення в режимі';
	@override String get aspectRatioButton => 'Співвідношення сторін';
	@override String get ambientLighting => 'Екологічне освітлення';
	@override String get fullscreenButton => 'Введіть повний екран';
	@override String get exitFullscreenButton => 'Повний екран виходу';
	@override String get alwaysOnTopButton => 'Завжди на вершині';
	@override String get rotationLockButton => 'Ротаційний замок';
	@override String get lockScreen => 'Закритий екран';
	@override String get screenLockButton => 'Закриття екрану';
	@override String get longPressToUnlock => 'Довгий тиск для розблокування';
	@override String get timelineSlider => 'Відео Timeline';
	@override String get volumeSlider => 'Розмір обсягу';
	@override String endsAt({required Object time}) => 'Завершився на ${time}';
	@override String get pipActive => 'Створення Picture-in-Picture';
	@override String get pipFailed => 'Фото-ін-фото не вдалося почати';
	@override String get screenshotSaved => 'Створення Screenshot Save';
	@override String get screenshotFailed => 'Я не міг зробити екран';
	@override String zoomPercent({required Object percent}) => 'Масштаб ${percent}%';
	@override String volumePercent({required Object percent}) => 'Гучність ${percent}%';
	@override late final _Translations$videoControls$pipErrors$uk pipErrors = _Translations$videoControls$pipErrors$uk._(_root);
	@override String get chapters => 'Розділи';
	@override String get noChaptersAvailable => 'Розділів немає';
	@override String get queue => 'Квітень';
	@override String get noQueueItems => 'Немає предметів в ковбасі';
	@override String get noAudioDevicesAvailable => 'Немає доступних аудіопристроїв';
	@override String get searchSubtitles => 'Пошук субтитри';
	@override String get loadSubtitleFile => 'Завантажити файл підзаголовок...';
	@override String get subtitleLoadFailed => 'Не вдалося завантажити файл субтитри';
	@override String get language => 'Мова';
	@override String get noSubtitlesFound => 'Немає знайдених субтитри';
	@override String get subtitleDownloaded => 'Підзаголовок завантажено';
	@override String get subtitleDownloadedNotApplied => 'Підзаголовок завантажено, але його не можна було вибрати';
	@override String get subtitleDownloadFailed => 'Не вдалося завантажити субтитри';
	@override String get searchLanguages => 'Язики пошуку...';
	@override String get skipIntro => 'Скіп Інтро';
	@override String get skipCredits => 'Кредити Скіп';
	@override String get skipAds => 'Скачати рекламу';
	@override String get nextEpisode => 'Наступний епізод';
	@override String subtitleTrack({required Object n}) => 'Стрічка ${n}';
	@override String subtitleFile({required Object name}) => 'Підголовок ${name}';
	@override String forcedTrack({required Object label}) => '${label} (примусовий)';
	@override String get osdSubtitlesOff => 'Підзаголовок: Off';
	@override String osdSubtitles({required Object track}) => 'Підзаголовок: ${track}';
	@override String osdAudio({required Object track}) => 'Звук: ${track}';
}

// Path: messages
class _Translations$messages$uk extends Translations$messages$en {
	_Translations$messages$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Ознаковано як спостерігається';
	@override String get markedAsUnwatched => 'Ознаковано як невидиме';
	@override String get markedAsWatchedOffline => 'Марковано як спостерігалося (синхровується, коли онлайн)';
	@override String get markedAsUnwatchedOffline => 'Ознаковано як невизначено (синхровується, коли онлайн)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Автомобільний відключений: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: 'Авто-усунути ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} переглянуто завантажити',
		other: 'Авто-усунути ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} переглянуто завантаження',
	);
	@override String get removedFromContinueWatching => 'Звільнення від продовження спостереження';
	@override String errorLoading({required Object error}) => 'Помилка: ${error}';
	@override String get searchPartialResults => 'Деякі медіа-сервери не можуть бути пошуковані. показуючи доступні результати.';
	@override String get streamInterrupted => 'Потік був перерваний. друку грати або шукати відступ.';
	@override String get liveStreamInterrupted => 'Протягом потоку було припинено. преса грати до відходу.';
	@override String get fileInfoNotAvailable => 'Файл інформації не доступний';
	@override String get playbackAuthenticationRequired => 'Зареєструйтесь на сервері ЗМІ знову, щоб грати в цей елемент.';
	@override String get playbackServerUnavailable => 'Медіа-сервер не доступний. спробуйте знову пізніше.';
	@override String get playbackDataInvalid => 'Сервер повернув недійсну інформацію про відтворення.';
	@override String get playbackCancelled => 'Playback було скасовано.';
	@override String get playbackFailed => 'Playback не можна було почати.';
	@override String playbackFailedDetail({required Object error}) => 'Завантажити не можна: ${error}';
	@override String get audioOutputFailed => 'Перевірте аудіозв\'язок телевізора або приймача; якщо інші додатки також не мають звуку, перезапустіть пристрій.';
	@override String get mediaUnavailable => 'Цей контент більше не доступний.';
	@override String errorLoadingFileInfo({required Object error}) => 'Помилка завантаження файлу інформація: ${error}';
	@override String get errorLoadingSeries => 'Серія помилок завантаження';
	@override String get musicNotSupported => 'Музичне відтворення ще не підтримується';
	@override String get noDescriptionAvailable => 'Опис не доступний';
	@override String get noProfilesAvailable => 'Доступні профілі немає';
	@override String get contactAdminForProfiles => 'Зв\'яжіться з адміністратором сервера, щоб додати профілі';
	@override String get unableToDetermineLibrarySection => 'Неможливо визначити розділ бібліотеки для цього пункту';
	@override String get logsCleared => 'Логіки очищені';
	@override String get logsCopied => 'Копіюється в clipboard';
	@override String get noLogsAvailable => 'Доступні записи немає';
	@override String libraryScanning({required Object title}) => 'Сканування «${title}»';
	@override String libraryScanStarted({required Object title}) => 'Сканування бібліотеки розпочато для «${title}»';
	@override String libraryScanFailed({required Object error}) => 'Не вдалося сканувати бібліотеку: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Повторні метадані для «${title}»';
	@override String metadataRefreshStarted({required Object title}) => 'Початок оновлення метаданів для «${title}»';
	@override String metadataRefreshFailed({required Object error}) => 'Не вдалося оновити метаданни: ${error}';
	@override String get logoutConfirm => 'Ви впевнені, що хочете вийти?';
	@override String get noSeasonsFound => 'Сезон не знайдено';
	@override String get seasonsLoadFailed => 'Не можна завантажувати сезони';
	@override String get noEpisodesFound => 'У першому сезоні не знайдено жодних епізодів';
	@override String get noEpisodesFoundGeneral => 'Епізодів не знайдено';
	@override String get episodesLoadFailed => 'Не можна завантажувати епізоди';
	@override String get noResultsFound => 'Нічого не знайдено.';
	@override String sleepTimerSet({required Object label}) => 'Співальний час встановлений для ${label}';
	@override String get noItemsAvailable => 'Немає предметів доступних';
	@override String get failedToCreatePlayQueueNoItems => 'Не вдалося створити гравцю — немає предметів';
	@override String failedPlayback({required Object action, required Object error}) => 'Не вдалося ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Перехід до комбінованого гравця.';
	@override String get serverLimitTitle => 'Playback провалився';
	@override String get serverLimitBody => 'Серверна помилка (HTTP 500). обмеження ширини смуги/перешифрування, ймовірно, відкинули цю сесію.';
	@override String get mediaUnreadableTitle => 'Файли недоступні';
	@override String get mediaUnreadableBody => 'Сервер знайшов цей елемент, але не міг прочитати його файл (HTTP 404). файл, ймовірно, був переміщений, видалений, або його зберігання офлайн.';
	@override String get serverBusyTitle => 'Потік недоступний';
	@override String get serverBusyBody => 'Сервер продовжував відмовлятися від потоку цього файлу (HTTP 503). це може бути відновлення, зайнятий, або зберігання файлу може бути офлайн. спробуйте знову в один момент — якщо це продовжується, попросіть власника сервера перевірити сервер і зберігання файлу.';
	@override String get playbackNotAllowedTitle => 'Playback не дозволяється';
	@override String get playbackNotAllowedBody => 'Сервер відмовився передавати цей елемент (HTTP 403). Ваш обліковий запис може не мати дозволу на його відтворення, або сервер може дозволяти відтворення тільки на його місцевій мережі.';
	@override String get logsUploaded => 'Завантажити Logs';
	@override String get logsUploadFailed => 'Не вдалося завантажити логіки';
	@override String get logId => 'Ідентифікатор';
	@override String get burnedSubtitlesUseMenu => 'Підголоси спалюються в цей потік. змінюйте їх з меню підголосів.';
	@override String get noVideoUrl => 'Відео URL не доступно';
	@override String get playbackNoMediaSources => 'Сервер не повернув жодних джерел гральних засобів масової інформації';
	@override String get playbackDataNotPrepared => 'Playback почався до того, як його дані були готові.';
	@override String get streamSelectionUnavailable => 'Вибір потоку не доступний для цього джерела';
	@override String get streamSelectionFailed => 'Не можна застосовувати вибрані потоки';
	@override String get trackSelectionNotRemembered => 'Цей варіант трас застосовується тільки до поточного відтворення.';
	@override String get serverUnavailableForProfile => 'Сервер не доступний для активного профілю';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$uk extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Швидкий коричневий фокс стрибає над лазовим собакою';
	@override String get text => 'Текст';
	@override String get border => 'кордони';
	@override String get background => 'фонтани';
	@override String get fontSize => 'Розмір шрифту';
	@override String get textColor => 'Колір тексту';
	@override String get borderSize => 'Гранична величина';
	@override String get borderColor => 'Колір кордону';
	@override String get backgroundOpacity => 'Позашляховик Opacity';
	@override String get backgroundColor => 'Колір фону';
	@override String get position => 'Позиція';
	@override String get assOverride => 'ASS Перевищення';
	@override String get overrideScale => 'Скелі';
	@override String get overrideForce => 'Сила';
	@override String get overrideStrip => 'Зняти стилізм';
	@override String get positionTop => 'ТОП';
	@override String get positionBottom => 'Підземний';
	@override String get useMargins => 'Використання маргінів';
	@override String get useMarginsDescription => 'Дозвольте текстовим субтитрам у просторі поза відео. Стильовані субтитри можуть зберігати своє оригінальне розташування.';
	@override String get anchorToScreen => 'Анкор на екрани';
	@override String get anchorToScreenDescription => 'Показати підзаголовки тексту в чорних смугах нижче відео широкого екрану';
	@override String get bold => 'Жирний';
	@override String get italic => 'Італійська';
	@override String get renderResolution => 'Резолюція Рендер';
	@override String get renderResolutionScreen => 'Роздільна здатність екрану';
	@override String get renderResolutionVideo => 'Роздільна здатність відео';
}

// Path: mpvConfig
class _Translations$mpvConfig$uk extends Translations$mpvConfig$en {
	_Translations$mpvConfig$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Налаштування передових відеоплеєрів';
	@override String get presets => 'Президи';
	@override String get noPresets => 'Не збереглися прецеденти';
	@override String get saveAsPreset => 'Зберегти як прецедент';
	@override String get presetName => 'Назва Пресет';
	@override String get presetNameHint => 'Введіть ім\'я для цього пресету';
	@override String get loadPreset => 'Завантажити';
	@override String get deletePreset => 'Видалити';
	@override String get presetSaved => 'Прес-центр врятований';
	@override String get presetLoaded => 'Прес-завантаження завантажено';
	@override String get presetDeleted => 'Прес-реліз видалений';
	@override String get confirmDeletePreset => 'Ви впевнені, що ви хочете видалити цей пресет?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # коментар';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Додати лінію';
	@override String get removeLine => 'Зняти лінію';
	@override String get embeddedVoHint => 'vo, gpu-контекст і gpu-api ігноруються на Linux: вбудований відео завжди передається через vo=libmpv на відеоповерхні, і gpu-next (який комп\'ютерні відтінки, такі як ArtCNN потрібні) не може працювати вбудований.';
}

// Path: dialog
class _Translations$dialog$uk extends Translations$dialog$en {
	_Translations$dialog$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Підтвердити дії';
}

// Path: profiles
class _Translations$profiles$uk extends Translations$profiles$en {
	_Translations$profiles$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Додати профіль PlezyNG';
	@override String get switchingProfile => 'Профільний перехід...';
	@override String get deleteThisProfileTitle => 'Чи можна видалити цей профіль?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Видалити ${displayName}. Підключення залишаться без змін.';
	@override String get active => 'Активний';
	@override String get manage => 'Управління';
	@override String get delete => 'Видалити';
	@override String get signOut => 'Вийти';
	@override String get signOutPlexTitle => 'Зареєструйтеся на Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Видалити ${displayName} і всі Plex Домашні користувачі?';
	@override String get signOutPlexDeleteDownloads => 'Також видаляти завантаження';
	@override String get signOutPlexDeleteDownloadsDescription => 'Інакше завантаження залишаться на цьому пристрої й знову з’являться, коли ви ввійдете в цей обліковий запис.';
	@override String get signedOutPlex => 'Підписано з Plex.';
	@override String get signOutFailed => 'Підписання провалилася.';
	@override String get sectionTitle => 'Профіль';
	@override String get summarySingle => 'Додайте профілі, щоб змішувати управляних користувачів і місцевих ідентифікацій';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} профілі · активний: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} Профіль';
	@override String get removeConnectionTitle => 'Відключити зв’язок?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Усунути доступ ${displayName} до ${connectionLabel}. інші профілі зберігають його.';
	@override String get deleteProfileTitle => 'Профіль вимкнений?';
	@override String deleteProfileMessage({required Object displayName}) => 'Усунути ${displayName} та його підключення. сервери залишаються доступними.';
	@override String get profileNameLabel => 'Профільне ім\'я';
	@override String get pinProtectionLabel => 'PIN захист';
	@override String get copyAutomationLink => 'Копіювати Android автоматизаційний посилання';
	@override String get copyAutomationLinkDescription => 'Виберіть цей профіль з Android наміру або автоматизації.';
	@override String get automationLinkCopied => 'Профіль автоматизації посилання копіюється.';
	@override String get pinManagedByPlex => 'PIN керується Plex.Редагувати на plex.tv.';
	@override String get noPinSetEditOnPlex => 'Для того, щоб вимагати одного, редагуйте домашнього користувача на plex.tv.';
	@override String get setPin => 'Налаштування PIN';
	@override String get setPinTitle => 'Налаштування PIN';
	@override String get confirmPinTitle => 'Підтвердити PIN';
	@override String get pinSet => 'Пін Сет';
	@override String get changePin => 'Зміни';
	@override String get removePin => 'Видалити';
	@override String get connectionsLabel => 'Зв\'язки';
	@override String get add => 'Додати';
	@override String get deleteProfileButton => 'Профіль видалення';
	@override String get noConnectionsHint => 'Немає підключень — додайте один для використання цього профілю.';
	@override String get noConnections => 'Немає зв\'язків';
	@override String get plexHomeAccount => 'Plex Домашній рахунок';
	@override String plexAccountChip({required Object account}) => 'Plex обліковий запис: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} через ${account}';
	@override String get connectionDefault => 'За замовчуванням';
	@override String connectionAs({required Object displayName}) => 'Створення ${displayName}';
	@override String get makeDefault => 'Зробіть дефолт';
	@override String get removeConnection => 'Видалити';
	@override String get profileRenamed => 'Профіль перейменований';
	@override String borrowAddTo({required Object displayName}) => 'Додати до ${displayName}';
	@override String get borrowExplain => 'Заощаджуйте зв\'язок іншого профілю. PIN-захищені профілі потребують PIN.';
	@override String get borrowEmpty => 'На даний момент немає нічого, що можна позичити.';
	@override String get borrowEmptySubtitle => 'Перш за все, підключіть Plex, Jellyfin, або Emby до іншого профілю.';
	@override String get borrowLoadFailed => 'Доступні зв\'язки не можуть бути завантажені. спробуйте знову.';
	@override String borrowFromProfile({required Object displayName}) => 'від ${displayName}';
	@override String get borrowConnectionBorrowed => 'Заощаджені зв\'язки';
	@override String get borrowFailed => 'У зв\'язку з тим, що не вдалося взяти кредит.';
	@override String get incorrectPin => 'Неправильний PIN';
	@override String get incorrectPinTryAgain => 'Помилковий PIN, будь ласка, спробуйте ще раз.';
	@override String get sourceProfileMissingParentAccount => 'Профіль джерела не вистачає свого батьківського рахунку.';
	@override String get failedToLoadHomeUsers => 'Не можна завантажувати ваші користувачі Plex. перевірте зв\'язок і спробуйте знову.';
	@override String get failedToVerifyPin => 'Не вдалося перевірити PIN.';
	@override String get newProfile => 'Новий профіль';
	@override String get profileNameHint => 'Наприклад, гості, діти, сімейний номер';
	@override String get pinProtectionOptional => 'Захист PIN (за винятком)';
	@override String get pinExplain => '4-цифровий PIN необхідний для перетворення профілів.';
	@override String get continueButton => 'Продовжуйте';
	@override String get pinsDontMatch => 'PIN не відповідає';
	@override String get tokenIdentityMismatch => 'Профільний токен Plex розв\'язаний на несподіваний сервер';
	@override String get settingsLocked => 'Налаштування заблоковані для цього профілю.';
	@override String get unlockSettings => 'Відключення налаштувань';
	@override String get showExploreForProfile => 'Показати Пошук для цього профілю';
	@override String get showExploreForProfileDescription => 'Вимкніть, щоб видалити Explore з навігації цього профілю.';
}

// Path: connections
class _Translations$connections$uk extends Translations$connections$en {
	_Translations$connections$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Зв\'язки';
	@override String get addConnection => 'Додати зв\'язок';
	@override String get addConnectionSubtitleNoProfile => 'Зареєструйтесь за допомогою Plex або підключіться до сервера Jellyfin або Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Додати до ${displayName}: Plex, Jellyfin, Emby, або іншого профільного зв\'язку';
	@override String sessionExpiredOne({required Object name}) => 'Завершилася сесія за ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Завершилася сесія для серверів ${count}';
	@override String accessDeniedOne({required Object name}) => '${name} відмовляється отримати доступ до цього облікового запису';
	@override String accessDeniedMany({required Object count}) => '${count} сервери відмовилися від доступу до цього облікового запису';
	@override String get signInAgain => 'Підписуйтесь знову';
	@override String editMediaBrowserTitle({required Object product}) => 'Реєстрація ${product} зв\'язок';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Додати або видалити URL-адреси для ${serverName}. PlezyNG буде використовувати доступний URL з найнижчою затримкою.';
}

// Path: accountPreferences
class _Translations$accountPreferences$uk extends Translations$accountPreferences$en {
	_Translations$accountPreferences$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Переваги облікового запису';
	@override String hubSubtitleSingle({required Object account}) => 'Аудіо, субтитри та варіанти бібліотеки збереглися на ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Аудіо, субтитри та варіанти бібліотеки збережені на акаунтах ${count}';
	@override String get pickAccount => 'Кожен обліковий запис зберігає свої власні переваги. виберіть один для редагування.';
	@override String get storedOnAccount => 'Ці варіанти зберігаються на самому обліковому записі, тому кожна програма, що підписується на нього, використовує їх — в тому числі PlezyNG на ваших інших пристроях.';
	@override String get noAccounts => 'Конфігурувати не можна';
	@override String get noAccountsHint => 'Зареєструйтесь на Plex, або підключіться до сервера Jellyfin або Emby, і переваги, що зберігаються на цьому рахунку, відображаються тут.';
	@override String get unavailable => 'Не можна отримати доступ до цього рахунку';
	@override String get loadFailed => 'Я не можу завантажити ці переваги';
	@override String get noPreference => 'Немає переваг';
	@override String get notSet => 'Не встановлюйте';
	@override late final _Translations$accountPreferences$groups$uk groups = _Translations$accountPreferences$groups$uk._(_root);
	@override String get preferredAudioLanguage => 'Бажана мова аудіо';
	@override String get autoSelectAudio => 'Вибір звуку за мовою';
	@override String get autoSelectAudioDescription => 'Відключено зберігає будь-який аудіо відстеження файлу знаків за замовчуванням.';
	@override String get preferredSubtitleLanguage => 'Бажана мова субтитрів';
	@override String get subtitleMode => 'Завантажити субтитри';
	@override late final _Translations$accountPreferences$subtitleModes$uk subtitleModes = _Translations$accountPreferences$subtitleModes$uk._(_root);
	@override String get subtitleAccessibility => 'СДГ підзаголовок';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$uk subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$uk._(_root);
	@override String get forcedSubtitles => 'Примусові субтитри';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$uk forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$uk._(_root);
	@override String get displayMissingEpisodes => 'Показати відсутні епізоди';
	@override String get displayMissingEpisodesDescription => 'Список епізодів, про які сервер знає, але у нього немає файлів.';
	@override String get hidePlayedInLatest => 'Сховати переглянуті речі в останній';
	@override String get hidePlayedInLatestDescription => 'Залишити елементи, які ви вже переглянули з останніх рядків сервера.';
	@override String get displayCollectionsView => 'Показати зображення колекцій';
	@override String get displayCollectionsViewDescription => 'Подайте перегляд колекцій на сервері разом з бібліотеками.';
	@override String get rewatchingInNextUp => 'Продовжуйте переглянути шоу в Next Up';
	@override String get rewatchingInNextUpDescription => 'Після того, як ви закінчите шоу, почніть знову, а Next Up слідує за переглядом, а не відкидає шоу.';
	@override String get watchedIndicator => 'Переглянуті показники';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$uk watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$uk._(_root);
	@override String get mediaReviewsVisibility => 'Рейтинг & рецензії';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$uk mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$uk._(_root);
}

// Path: discover
class _Translations$discover$uk extends Translations$discover$en {
	_Translations$discover$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Відкриття';
	@override String get noContentAvailable => 'Немає контенту доступного';
	@override String get addMediaToLibraries => 'Додайте деякі медіа до своїх бібліотек';
	@override String get continueWatching => 'Продовжити перегляд';
	@override String continueWatchingIn({required Object library}) => 'Продовжувати дивитися в ${library}';
	@override String get nextUp => 'Далі';
	@override String nextUpIn({required Object library}) => 'Наступна статтяУкрзалізниця ${library}';
	@override String get recentlyAdded => 'Нещодавно додані';
	@override String recentlyAddedIn({required Object library}) => 'Нещодавно додано в ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Найсвіжіші альбоми в ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Нещодавно зіграно в ${library}';
	@override String mostPlayedIn({required Object library}) => 'Найбільше переглянуто в ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'С${season}Е${episode}';
	@override String get overview => 'Опис';
	@override String get cast => 'Каст';
	@override late final _Translations$discover$findNext$uk findNext = _Translations$discover$findNext$uk._(_root);
	@override String get extras => 'Трейлери та екстраси';
	@override String get studio => 'Студія';
	@override String get rating => 'Рейтинг';
	@override String get director => 'Режисер';
	@override String get directors => 'Режисери';
	@override String get movie => 'Фільми';
	@override String get tvShow => 'Телевізійне шоу';
	@override String minutesLeft({required Object minutes}) => '${minutes} хвилини';
	@override String get moreLikeThis => 'Подібні до цього';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назва',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назви',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назв',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назви',
	);
	@override late final _Translations$discover$person$uk person = _Translations$discover$person$uk._(_root);
}

// Path: errors
class _Translations$errors$uk extends Translations$errors$en {
	_Translations$errors$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Пошук провалився: ${error}';
	@override String get searchUnavailable => 'Пошук не міг досягти жодного медіа-сервера.';
	@override String connectionTimeout({required Object context}) => 'Час очікування з’єднання вичерпано під час завантаження ${context}';
	@override String get connectionFailed => 'Неможливість підключення до медіа-сервера';
	@override String unableToLoad({required Object context}) => 'Не можна завантажувати ${context}. будь ласка, спробуйте знову.';
	@override String get noClientAvailable => 'Клієнт не доступний';
	@override String get pleaseEnterToken => 'Будь ласка, введіть токен';
	@override String get invalidToken => 'Недійсний токен';
	@override String failedToVerifyToken({required Object error}) => 'Невідомий токен: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Не вдалося перейти до ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Не вдалося видалити ${displayName}';
	@override String get failedToRate => 'Не можна оновити рейтинг';
	@override String get reasonTimedOut => 'Зв\'язок тимчасовий';
	@override String get reasonUnreachable => 'Сервер не може бути доступний';
	@override String get reasonRefused => 'Сервер відмовився від запиту';
	@override String get reasonNotFound => 'Продукт більше не знаходиться на сервері.';
	@override String get reasonServerError => 'Сервер повідомив про помилку';
	@override String get reasonCancelled => 'Заява була скасована';
	@override String get reasonUnexpected => 'Несподівана помилка сталася';
}

// Path: libraries
class _Translations$libraries$uk extends Translations$libraries$en {
	_Translations$libraries$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Грати в випадковий фільм';
	@override String get randomPickFailed => 'Я не можу вибрати фільм з цієї бібліотеки.';
	@override String get title => 'Медіатеки';
	@override String get fallbackTitle => 'Медіатека';
	@override String get scanLibraryFiles => 'Сканування бібліотечних файлів';
	@override String get scanLibrary => 'Сканувати медіатеку';
	@override String get analyze => 'Аналіз';
	@override String get analyzeLibrary => 'Аналіз бібліотеки';
	@override String get refreshMetadata => 'Оновити метадані';
	@override String get emptyTrash => 'Порожній траш';
	@override String emptyingTrash({required Object title}) => 'Попередня статтяКто чего не ест – ${title}...';
	@override String trashEmptied({required Object title}) => 'Попередня статтяКто чего не ест – ${title}';
	@override String failedToEmptyTrash({required Object error}) => 'Не вдалося встановити порожній сміттєзвалище: ${error}';
	@override String analyzing({required Object title}) => 'Аналіз «${title}»';
	@override String analysisStarted({required Object title}) => 'Аналіз розпочався для «${title}»';
	@override String failedToAnalyze({required Object error}) => 'Не вдалося проаналізувати бібліотеку: ${error}';
	@override String get noLibrariesFound => 'Бібліотеки не знайдено';
	@override String get allLibrariesHidden => 'Всі бібліотеки приховані';
	@override String hiddenLibrariesCount({required Object count}) => 'Схована бібліотека (${count})';
	@override String get thisLibraryIsEmpty => 'Ця бібліотека порожня';
	@override String get noItemsMatchFilters => 'Ніякі елементи не відповідають активним фільтрам';
	@override String get resetFilters => 'Скинути фільтри';
	@override String get all => 'Всі';
	@override String get clearAll => 'Все чітко';
	@override String scanLibraryConfirm({required Object title}) => 'Ви впевнені, що ви хочете сканувати "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Ви впевнені, що ви хочете проаналізувати "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Ви впевнені, що ви хочете оновити метаданни для "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Ви впевнені, що ви хочете порожній сміттєзвалище для "${title}"?';
	@override String get manageLibraries => 'Управління бібліотеками';
	@override String get sort => 'Сортувати';
	@override String get sortBy => 'Сортувати за';
	@override String get filters => 'Фільтри';
	@override String get confirmActionMessage => 'Ви впевнені, що хочете здійснити цю діяльність?';
	@override String get showLibrary => 'Показати бібліотеку';
	@override String get hideLibrary => 'Сховати бібліотеку';
	@override String get libraryOptions => 'Бібліотечні варіанти';
	@override String get content => 'Бібліотека контент';
	@override String get selectLibrary => 'Вибір бібліотеки';
	@override String filtersWithCount({required Object count}) => 'Фільтри (${count})';
	@override String get noRecommendations => 'Немає доступних рекомендацій';
	@override String get noCollections => 'Ніяких колекцій в цій бібліотеці';
	@override String get noFoldersFound => 'Не знайдено жодних паперів';
	@override String get folders => 'Теки';
	@override late final _Translations$libraries$tabs$uk tabs = _Translations$libraries$tabs$uk._(_root);
	@override late final _Translations$libraries$groupings$uk groupings = _Translations$libraries$groupings$uk._(_root);
	@override late final _Translations$libraries$filterCategories$uk filterCategories = _Translations$libraries$filterCategories$uk._(_root);
	@override late final _Translations$libraries$sortLabels$uk sortLabels = _Translations$libraries$sortLabels$uk._(_root);
	@override late final _Translations$libraries$advancedFilters$uk advancedFilters = _Translations$libraries$advancedFilters$uk._(_root);
	@override late final _Translations$libraries$selection$uk selection = _Translations$libraries$selection$uk._(_root);
}

// Path: about
class _Translations$about$uk extends Translations$about$en {
	_Translations$about$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Про';
	@override String get openSourceLicenses => 'Відкритий код ліцензій';
	@override String versionLabel({required Object version}) => 'Версія ${version}';
	@override String get appDescription => 'Красивий клієнт Plex, Jellyfin і Emby для Flutter';
	@override String get viewLicensesDescription => 'Переглянути ліцензії на бібліотеки третьої сторони';
	@override String get privacyPolicy => 'Політика конфіденційності';
}

// Path: serverSelection
class _Translations$serverSelection$uk extends Translations$serverSelection$en {
	_Translations$serverSelection$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Немає серверів для ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Завантаження серверів: ${error}';
	@override String get noValidServers => 'На цьому обліковому записі не знайдено жодного сервера.';
}

// Path: hubDetail
class _Translations$hubDetail$uk extends Translations$hubDetail$en {
	_Translations$hubDetail$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Назва';
	@override String get releaseYear => 'Рік випуску';
	@override String get dateAdded => 'Дата додавання';
	@override String get rating => 'Рейтинг';
	@override String get noItemsFound => 'Не знайдено предметів';
}

// Path: logs
class _Translations$logs$uk extends Translations$logs$en {
	_Translations$logs$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Чистий лог';
	@override String get copyLogs => 'Копіювати логіки';
	@override String get uploadLogs => 'Завантажити Logs';
	@override String get saveLogs => 'Зберегти логі до файлів';
	@override String logsSaved({required Object path}) => 'Зареєстровано до ${path}';
	@override String get saveLogsFailed => 'Я не можу зберегти файл.';
}

// Path: detail
class _Translations$detail$uk extends Translations$detail$en {
	_Translations$detail$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Завершився на ${time}';
}

// Path: startup
class _Translations$startup$uk extends Translations$startup$en {
	_Translations$startup$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG не може почати';
	@override String get failedBody => 'Щось пройшло неправильно під час стартапу. деталі нижче визначають, що не вдалося.';
	@override String get failedBodyRepairable => 'Збережений файл налаштувань PlezyNG пошкоджено. Перед запуском програми його потрібно відновити. Повторна спроба не допоможе — виберіть відновлення сховища.';
	@override String get phaseLabel => 'Крок';
	@override String get showDetails => 'Покажіть деталі';
	@override String get hideDetails => 'Сховати деталі';
	@override String get copyDetails => 'Копіювати деталі';
	@override String get detailsCopied => 'Детальніше Копіювати на Clipboard';
	@override String get uploadDetails => 'Завантажити деталі';
	@override String get repairStorage => 'Ремонт зберігання';
	@override String get repairTitle => 'Поправка зберіганих даних?';
	@override String get repairBodyCommon => 'Файл налаштувань PlezyNG пошкоджено й неможливо прочитати. Відновлення скине всі налаштування до типових значень.';
	@override String get repairBodyOneCredential => 'Дані одного зі збережених входів пошкоджено й неможливо прочитати. Відновлення видалить лише їх; решта налаштувань залишиться без змін.';
	@override String get repairBodySignInsKept => 'Вхід на сервери та в профілі має зберегтися.';
	@override String get repairBodySignInsLost => 'Ключ, що захищає збережені дані входу, неможливо відновити з цього файлу. Тому доведеться знову ввійти на кожен сервер і в кожен профіль. Нічого на медіасервері не зміниться.';
	@override String get repairBodySessionsUncertain => 'Дані сервісів відстеження (MAL, AniList, Simkl, Trakt) і Seerr зберігаються окремо та можуть як зберегтися, так і зникнути. PlezyNG точно повідомить, які дані вдалося зберегти.';
	@override String get repairConfirm => 'Ремонт';
	@override String get repairSucceeded => 'Зберігання відремонтовано';
	@override String get repairNeedsRestart => 'Зберігання відремонтовано — необхідне відновлення';
	@override String get restartRequiredBody => 'Ваші дані відновлено, але PlezyNG потрібно перезапустити, щоб ними скористатися. Закрийте PlezyNG і відкрийте знову.';
	@override String get quitPlezy => 'Завантажити PlezyNG';
	@override String get repairFailed => 'Поправка провалилася';
	@override String get repairKeptSignIns => 'Вхід на сервери та в профілі досі активний.';
	@override String get repairLostSignIns => 'Не вдалося відновити ключ, що захищає збережені дані входу. Потрібно знову ввійти на кожен сервер і в кожен профіль.';
	@override String get repairLostSessions => 'Принаймні один тракер або Seerr зв\'язок втрачено і потрібно відновити зв\'язок.';
	@override String get backupTitle => 'Копія пошкодженого файлу зберігається';
	@override String get backupWarning => 'Вона містить ваші аутентифікації. не завантажуйте або не ділитеся.';
	@override String get deleteBackup => 'Зняти копію';
	@override String get backupDeleted => 'Копія видалена';
	@override String get previousFailureTitle => 'PlezyNG не вдалося почати останній раз';
}

// Path: licenses
class _Translations$licenses$uk extends Translations$licenses$en {
	_Translations$licenses$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Пов\'язані пакети';
	@override String get license => 'Ліцензія';
	@override String licenseNumber({required Object number}) => 'Ліцензія ${number}';
	@override String licensesCount({required Object count}) => '${count} ліцензії';
}

// Path: navigation
class _Translations$navigation$uk extends Translations$navigation$en {
	_Translations$navigation$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Медіатеки';
	@override String get downloads => 'Завантаження';
	@override String get liveTv => 'Прямий ефір';
	@override String get explore => 'Вивчення';
}

// Path: explore
class _Translations$explore$uk extends Translations$explore$en {
	_Translations$explore$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$uk mdblistShelves = _Translations$explore$mdblistShelves$uk._(_root);
	@override String get title => 'Вивчення';
	@override String get selectSource => 'Вибір джерела';
	@override late final _Translations$explore$rows$uk rows = _Translations$explore$rows$uk._(_root);
	@override late final _Translations$explore$status$uk status = _Translations$explore$status$uk._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серія',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серії',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серій',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серії',
	);
	@override String get cast => 'Каст';
	@override String get characters => 'персонажів';
	@override String get addToWatchlist => 'Додати до Watchlist';
	@override String get removeFromWatchlist => 'Видалення з Watchlist';
	@override String get addedToWatchlist => 'Додано до watchlist';
	@override String get removedFromWatchlist => 'Вилучено з обсерваторії';
	@override String get watchlistUpdateFailed => 'Не можна оновити обсерваторію';
	@override String get watchlistNoMatch => 'Цей елемент не може відповідати списку спостережень';
	@override String get notInLibrary => 'Не в бібліотеці';
	@override String get inTheseLibraries => 'У цих бібліотеках';
	@override String get checkingLibrary => 'Перевірте свою бібліотеку.';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: 'Не можна перевірити сервер ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
		other: 'Не можна перевірити сервери ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
	);
	@override String get emptyTitle => 'Тут ще нічого';
	@override String emptyMessage({required Object source}) => 'Повернення з ${source} з\'явиться тут, як тільки вони мають вміст.';
	@override String searchHint({required Object source}) => 'Пошук ${source}';
	@override String searchEmpty({required Object query}) => 'Немає результатів для «${query}»';
	@override String searchPrompt({required Object source}) => 'Пошук фільмів і шоу на ${source}.';
	@override String get searchFailed => 'Пошук провалився. перевірте зв\'язок і спробуйте знову.';
	@override late final _Translations$explore$badge$uk badge = _Translations$explore$badge$uk._(_root);
	@override late final _Translations$explore$stats$uk stats = _Translations$explore$stats$uk._(_root);
	@override late final _Translations$explore$season$uk season = _Translations$explore$season$uk._(_root);
	@override late final _Translations$explore$format$uk format = _Translations$explore$format$uk._(_root);
	@override late final _Translations$explore$sourceMaterial$uk sourceMaterial = _Translations$explore$sourceMaterial$uk._(_root);
	@override late final _Translations$explore$creditRole$uk creditRole = _Translations$explore$creditRole$uk._(_root);
	@override late final _Translations$explore$relation$uk relation = _Translations$explore$relation$uk._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Авіакомпанія Airs ${day} на ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Авіакомпанія Airs ${day} на ${time} ${timezone}';
	@override late final _Translations$explore$detail$uk detail = _Translations$explore$detail$uk._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результат',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результати',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результатів',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результати',
	);
}

// Path: liveTv
class _Translations$liveTv$uk extends Translations$liveTv$en {
	_Translations$liveTv$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Прямий ефір';
	@override String get guide => 'Телегід';
	@override String get noChannels => 'Без каналів';
	@override String get noDvr => 'Ніякого DVR не встановлюється на сервері';
	@override String get serverUnavailable => 'Телевізійний сервер не доступний.';
	@override String get serverNotConnected => 'Телевізійний сервер не підключений.';
	@override String get noPrograms => 'Програма даних не доступна';
	@override String get liveStreamFailed => 'Живий потік не вдався';
	@override String get unknownProgram => 'Невідома програма';
	@override String get timelineLiveProgram => 'Програма в прямому ефірі (перегляд може бути поза цією програмою)';
	@override String get timelineBuffer => 'Буфферний час';
	@override String get timelineUnavailable => 'Тимчасовий термін недоступний';
	@override String get timelineEstimated => 'Оцінений Playback';
	@override String get timelinePending => 'Пошук';
	@override String get timelineStale => 'Графік може бути застарілим';
	@override String get unknownHub => 'Невідоме';
	@override String get unknownError => 'Невідома помилка';
	@override String channelNumber({required Object number}) => 'Канал ${number}';
	@override String get unknownChannel => 'Невідомий канал';
	@override String get live => 'Наживо';
	@override String get premiereBadge => 'Новий';
	@override String get reloadGuide => 'Завантажити Руководство';
	@override String get searchGuide => 'Пошуковий посібник';
	@override String get searchHint => 'Програми та канали пошуку';
	@override String searchNoResults({required Object query}) => 'Немає матчів для «${query}»';
	@override String get channelsSection => 'Канали';
	@override String get programsSection => 'Програми';
	@override String get now => 'Тепер';
	@override String get today => 'Сьогодні';
	@override String get tomorrow => 'Завтра';
	@override String get midnight => 'Місяць';
	@override String get overnight => 'Увечері';
	@override String get morning => 'ранок';
	@override String get daytime => 'День часу';
	@override String get evening => 'Вечір';
	@override String get lateNight => 'Пізні ночі';
	@override String get whatsOn => 'Що є на';
	@override String get watchChannel => 'Дивитись канал';
	@override String get favorites => 'Обрані';
	@override String get reorderFavorites => 'Рейдер улюблений';
	@override String get noFavoriteChannels => 'Улюблені канали немає';
	@override String get noFavoriteChannelsHint => 'Показати всі канали, а потім довго натиснути канал, щоб додати його до ваших улюблених.';
	@override String get showAllChannels => 'Показати всі канали';
	@override String get favoritesLoadFailed => 'Не можна завантажувати улюблені. перевірте зв\'язок і спробуйте знову.';
	@override String get favoritesUpdateFailed => 'Не можна оновити улюблені. перевірте зв\'язок і спробуйте знову.';
	@override String get joinSession => 'Приєднуйтесь до сесії в прогресі';
	@override String watchFromStart({required Object minutes}) => 'Дивитись з початку (${minutes} хвилин тому)';
	@override String get watchLive => 'Дивитись Live';
	@override String get goToLive => 'Іди жити';
	@override String get record => 'Запис';
	@override String get recordEpisode => 'Рекордний епізод';
	@override String get recordSeries => 'Записати серіал';
	@override String get recordOptions => 'Рекордні варіанти';
	@override String get saveTo => 'Зберегти до';
	@override String get recordings => 'Записи';
	@override String get scheduledRecordings => 'Програма';
	@override String get recordingRules => 'Реєстраційні правила';
	@override String get noScheduledRecordings => 'Нічого не планується записувати';
	@override String get manageRecording => 'Керувати записом';
	@override String get cancelRecording => 'Скасувати запис';
	@override String get cancelRecordingTitle => 'Відмінити цей запис?';
	@override String cancelRecordingMessage({required Object title}) => '${title} більше не буде зареєстровано.';
	@override String get deleteRule => 'Зняти правила';
	@override String get deleteRuleTitle => 'Вимкніть правила запису?';
	@override String deleteRuleMessage({required Object title}) => 'Майбутні епізоди ${title} не будуть записані.';
	@override String get recordingScheduled => 'Запис заплановано.';
	@override String get alreadyScheduled => 'Ця програма вже запланована';
	@override String get dvrAdminRequired => 'Установки DVR вимагають облікового запису admin';
	@override String get recordingFailed => 'Не можна було планувати запис';
	@override String get recordingTargetMissing => 'Бібліотека не змогла записати';
	@override String get recordNotAvailable => 'Реєстрація не доступна для цієї програми';
	@override String get recordingCancelled => 'Запис скасовано';
	@override String get recordingRuleDeleted => 'Правила запису видалені';
	@override String get processRecordingRules => 'Переоцінка правил';
	@override String get recordingInProgress => 'Зареєструйте зараз';
	@override String recordingsCount({required Object count}) => '${count} Програмується';
	@override String get editRule => 'Регламент редагування';
	@override String get editRuleAction => 'Редагувати';
	@override String get recordingRuleUpdated => 'Реєстраційне правило оновлено';
	@override String get guideReloadRequested => 'Реферат на тему: Реферат запропонований';
	@override String get guideReloadFailed => 'Не можна оновити інструкцію';
	@override String get rulesProcessRequested => 'Рекомендації про переоцінку';
	@override String get rulesProcessFailed => 'Не можна переоцінювати правила запису';
	@override String get recordShow => 'Рекордний шоу';
	@override late final _Translations$liveTv$recordSettings$uk recordSettings = _Translations$liveTv$recordSettings$uk._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Початок за ${minutes} хвилин';
	@override String dayAtTime({required Object day, required Object time}) => '${day} на ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} повернуто недійсні дані відтворення Live TV';
	@override String get failedToStartChannel => 'Я не можу запустити канал';
	@override String get failedToBuildStreamUrl => 'Я не можу створити поточний URL';
	@override String playbackStartFailed({required Object reason}) => 'Не можна було запустити канал: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Канал не змінюється: ${reason}';
}

// Path: collections
class _Translations$collections$uk extends Translations$collections$en {
	_Translations$collections$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Колекції';
	@override String get collection => 'Колекція';
	@override String get empty => 'Колекція порожня';
	@override String get deleteCollection => 'Видалити Колекцію';
	@override String deleteConfirm({required Object title}) => 'Видалити «${title}»? Цю дію неможливо скасувати.';
	@override String get deleted => 'Колекція видалена';
	@override String get deleteFailed => 'Не вдалося видалити колекцію';
	@override String deleteFailedWithError({required Object error}) => 'Не вдалося видалити збірку: ${error}';
	@override String get selectCollection => 'Вибір колекції';
	@override String get collectionName => 'Колекційне ім\'я';
	@override String get enterCollectionName => 'Введіть колекційне ім\'я';
	@override String get addedToCollection => 'Додано до колекції';
	@override String get errorAddingToCollection => 'Не вдалося додати до колекції';
	@override String get created => 'Колекція створена';
	@override String get removeFromCollection => 'Вилучити з колекції';
	@override String removeFromCollectionConfirm({required Object title}) => 'Вилучити «${title}» із цієї колекції?';
	@override String get removedFromCollection => 'Вилучено з колекції';
	@override String get removeFromCollectionFailed => 'Не вдалося зняти з колекції';
	@override String removeFromCollectionError({required Object error}) => 'Помилка у видаленні з колекції: ${error}';
	@override String get searchCollections => 'Пошук колекцій...';
}

// Path: playlists
class _Translations$playlists$uk extends Translations$playlists$en {
	_Translations$playlists$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Плейлисти';
	@override String get playlist => 'Плейлист';
	@override String get noPlaylists => 'Не знайдено гравців';
	@override String get create => 'Створення Playlist';
	@override String get playlistName => 'Ім\'я Playlist';
	@override String get enterPlaylistName => 'Введіть прізвище';
	@override String get delete => 'Видалити Плейліст';
	@override String get removeItem => 'Видалити з плейлиста';
	@override String get smartPlaylist => 'Розумний Playlist';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елемент',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елементи',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елементів',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елемента',
	);
	@override String get emptyPlaylist => 'Цей перелік залишається порожнім';
	@override String get deleteConfirm => 'Використання Playlist?';
	@override String deleteMessage({required Object name}) => 'Ви впевнені, що ви хочете видалити "${name}"?';
	@override String get created => 'Створення Playlist';
	@override String get deleted => 'Завантажити Playlist';
	@override String get itemAdded => 'Додано до Playlist';
	@override String get itemRemoved => 'Вилучено з Playlist';
	@override String get selectPlaylist => 'Виберіть Playlist';
	@override String get searchPlaylists => 'Пошук гравців...';
	@override String get errorCreating => 'Не вдалося створити плей-лист';
	@override String get errorDeleting => 'Не вдалося видалити плей-лист';
	@override String get errorLoading => 'Не вдалося завантажити списки';
	@override String get errorAdding => 'Не вдалося додати до списку';
	@override String get errorReordering => 'Не вдалося перезавантажити елемент Playlist';
	@override String get errorRemoving => 'Не вдалося вилучити з списку';
}

// Path: music
class _Translations$music$uk extends Translations$music$en {
	_Translations$music$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Перейти до альбому';
	@override String get goToArtist => 'Іди до художника';
	@override String get instantMix => 'Миттєвий мікс';
	@override String get playNext => 'Наступне';
	@override String get addToQueue => 'Додати до ковбасу';
	@override String discNumber({required Object n}) => 'Диск ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композиція',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композиції',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композицій',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композиції',
	);
	@override String get nowPlaying => 'Тепер грати';
	@override String playingFrom({required Object title}) => 'Ігри з ${title}';
	@override String get queue => 'Квітень';
	@override String get clearQueue => 'Очистити чергу';
	@override String get lyrics => 'Текст пісні';
	@override String get visualizer => 'Візуалізація';
	@override String get visualizerProfileLoading => 'Читати далі про Аналіз трак...';
	@override String get visualizerAmbientMotion => 'Екологічна рух';
	@override String get visualizerPlexLoudness => 'Plex Голос';
	@override String get visualizerPreviousPreset => 'Попередній візуальний стиль';
	@override String get visualizerNextPreset => 'Наступний візуальний стиль';
	@override String get visualizerPresetAurora => 'Аврора';
	@override String get visualizerPresetBloom => 'Блюм';
	@override String get visualizerPresetOrbitals => 'орбітальні';
	@override String get visualizerPresetPrism => 'Призми';
	@override String get visualizerPresetTunnel => 'тунелі';
	@override String get visualizerPresetTrackMap => 'Карта трак';
	@override String get noLyrics => 'Немає доступних ліриків';
	@override String get sleepTimer => 'Тимчасовий сон';
	@override String get sleepTimerEndOfTrack => 'Кінцевий шлях';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилина',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилини',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилин',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилини',
	);
	@override String get stopPlayback => 'Зупинити відтворення';
	@override String get previousTrack => 'Попередня доріжка';
	@override String get nextTrack => 'Наступна доріжка';
	@override String get repeat => 'Повторювати';
	@override String get repeatAll => 'Повторюйте все';
	@override String get repeatOne => 'Повторіть одне';
	@override String get instantMixNoServer => 'Сервер не доступний для миттєвого змішування';
	@override String get instantMixFailed => 'Не вдалося завантажити миттєвий мікс';
	@override String get instantMixEmpty => 'Повернувся мікс без слідів.';
	@override String noAudioUrl({required Object track}) => 'Немає аудіо-URL для ${track}';
	@override late final _Translations$music$discography$uk discography = _Translations$music$discography$uk._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$uk extends Translations$watchTogether$en {
	_Translations$watchTogether$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Дивитися разом';
	@override String get description => 'Переглянути контент в синхроні з друзями та сім\'єю';
	@override String get createRoom => 'Створіть кімнату';
	@override String get creatingRoom => 'Створення кімнати...';
	@override String get joinRoom => 'Приєднуйтесь до кімнати';
	@override String get joiningRoom => 'Приєднуйтесь до кімнати...';
	@override String get connecting => 'Зв’язок...';
	@override String get relayPublic => 'Відкриті кімнати використовують публічні релізи партії Open Watch.';
	@override String relayCustom({required Object url}) => 'Кімнати використовують ваш релей на номер ${url}.';
	@override String get recentRooms => 'Нещодавні кімнати';
	@override String get roomActions => 'Діяльність кімнати';
	@override String get renameRoom => 'Ремонт кімнати';
	@override String get removeRoom => 'Видалити';
	@override String get enterRoomCode => 'Введіть 6-картний код з хостингу.';
	@override String get roomCode => 'Код кімнати';
	@override String get paste => 'Пастир';
	@override String get noCodeInClipboard => 'Кліпборд не містить коду кімнати';
	@override String get copyCode => 'Копіювати код';
	@override String get codeCopied => 'Код кімнати копіюється';
	@override String get shareInvite => 'Поділимо запрошення';
	@override String get inviteCopied => 'Запрошуємо копіювати. вставити її в повідомлення.';
	@override String inviteMessage({required Object code}) => 'Приєднуйтесь до моєї кімнати Watch Together в PlezyNG: відкрийте Watch Together, виберіть Приєднуйтесь до кімнати і введіть ${code}.';
	@override String get openSessionControls => 'Відкритий час спільно контрольні сесії';
	@override String get reconnecting => 'Відновлення...';
	@override String get reconnectingDescription => 'З\'єднання припинено. Ви приєднуєтеся до кімнати автоматично.';
	@override String get connected => 'Зв\'язані';
	@override String get disconnected => 'Відключені';
	@override String get youAreHost => 'Ви є гостем';
	@override String hostedBy({required Object name}) => 'Завантажити ${name}';
	@override String get hostControlsPlayback => 'Завантажити Playback';
	@override String get anyoneCanControl => 'Кожен може контролювати Playback';
	@override String get roomLocked => 'Кімната закрита';
	@override String get nowPlaying => 'Тепер грати';
	@override String get nothingPlaying => 'Нічого не грати';
	@override String get nothingPlayingHost => 'Грати в щось з будь-якої бібліотеки, щоб поділитися ним з кімнатою.';
	@override String get nothingPlayingGuest => 'Коли хостинг щось грає, він відкривається тут.';
	@override String get notShareable => 'Цей відео не має каталогу, так що тільки люди з доступом до того ж сервера можуть грати в нього.';
	@override String get searching => 'Пошук цього відео у Вашій бібліотеці...';
	@override String get yourCopy => 'Ваша копія';
	@override String get sharingYourCopy => 'Ви ділитеся копією';
	@override String playingOtherLength({required Object difference}) => 'Завантажити копію, ${difference}';
	@override String get mismatchTitle => 'Ваша копія має різну довжину';
	@override String mismatchDescription({required Object difference}) => 'Ваша найближча копія - ${difference} від відео в кімнаті. це може бути інший стрибок або версія.';
	@override String get playAnyway => 'Грати в будь-який';
	@override String get chooseAnotherCopy => 'Виберіть іншу копію';
	@override String get dontPlay => 'Не грайте';
	@override String get unavailableTitle => 'У вас немає цього відео';
	@override String get unavailableDescription => 'PlezyNG не міг знайти його у ваших бібліотеках. виберіть копію самостійно або шукати знову.';
	@override String get chooseCopy => 'Виберіть копію';
	@override String get searchAgain => 'Пошук знову';
	@override String get noCandidates => 'Копії не знайдені у ваших бібліотеках.';
	@override String get choiceFailed => 'Я не можу грати в цю копію для кімнати';
	@override String lengthLonger({required Object duration}) => '${duration} довше';
	@override String lengthShorter({required Object duration}) => '${duration} короткий';
	@override String get lengthSame => 'однакова довжина';
	@override String get lengthUnknown => 'Довжина невідома';
	@override String get joinCurrentPlayback => 'Завантажити Current Playback';
	@override String get joinCurrentPlaybackDescription => 'Зверніть увагу на те, що зараз спостерігається в хостелі.';
	@override String get stopMedia => 'Залишити відео для всіх';
	@override String get syncOffset => 'Сінтеграція Offset';
	@override String get syncOffsetDescription => 'Перемістіть відео, якщо воно проходить перед або за кімнатою.';
	@override String offsetHint({required Object difference}) => 'Ваша копія ${difference} від відео в кімнаті.';
	@override String applyDifference({required Object offset}) => 'Використання ${offset}';
	@override String get offsetMinusSecond => '1 С';
	@override String get offsetMinusTenth => '100 мс';
	@override String get offsetPlusTenth => '+ 100 мс';
	@override String get offsetPlusSecond => '1 С';
	@override String get participants => 'Учасники';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасник',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасники',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасників',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасники',
	);
	@override String get hostBadge => 'Хост';
	@override String nameYou({required Object name}) => '${name} (Ви)';
	@override String get playerIdle => 'Бездіяльність';
	@override String get playerLoading => 'Завантаження';
	@override String get playerReady => 'Готові';
	@override String get playerBuffering => 'Буффінг';
	@override String get matchSearching => 'Пошук';
	@override String get matchMatched => 'У вас є відео';
	@override String get matchMismatched => 'Різні довжини';
	@override String get matchUnavailable => 'У нас немає відео';
	@override String participantOffset({required Object offset}) => 'Офсет ${offset}';
	@override String get makeHost => 'Зробіть гостя';
	@override String get makeHostQuestion => 'Передача гостя?';
	@override String makeHostConfirm({required Object name}) => '${name} буде контролювати відтворення і керувати сесією для всіх.';
	@override String get transfer => 'Трансфер';
	@override String get removeParticipant => 'Зняти з кімнати';
	@override String removeParticipantQuestion({required Object name}) => 'Зняти ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} виходить з кімнати. вони можуть знову приєднатися до коду, якщо ви не заблокуєте кімнату.';
	@override String get remove => 'Видалити';
	@override String get roomSettings => 'Розташування кімнати';
	@override String get letEveryoneControl => 'Запрошуємо всіх взяти участь у Playback';
	@override String get lockRoom => 'Закритий номер';
	@override String get lockRoomDescription => 'Ніхто новий не може приєднатися';
	@override String get leaveRoom => 'Відпустіть кімнату';
	@override String get leaveRoomQuestion => 'Відпустіть кімнату?';
	@override String get leaveRoomConfirm => 'Ви можете знову приєднатися до коду кімнати.';
	@override String get leave => 'Відпустіть';
	@override String get endRoom => 'Кінцева кімната';
	@override String get endRoomQuestion => 'Кінцева кімната?';
	@override String get endRoomConfirm => 'Це закінчує кімнату для всіх.';
	@override String get end => 'Кінцевий';
	@override String get playBlockedTitle => 'Playback не почався';
	@override String get playBlockedDescription => 'Натисніть, щоб почати дивитися з кімнати.';
	@override late final _Translations$watchTogether$notices$uk notices = _Translations$watchTogether$notices$uk._(_root);
	@override late final _Translations$watchTogether$ended$uk ended = _Translations$watchTogether$ended$uk._(_root);
	@override late final _Translations$watchTogether$errors$uk errors = _Translations$watchTogether$errors$uk._(_root);
	@override String untitledEpisode({required Object number}) => 'Епізод ${number}';
}

// Path: downloads
class _Translations$downloads$uk extends Translations$downloads$en {
	_Translations$downloads$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Завантаження';
	@override String get manage => 'Управління';
	@override String get tvShows => 'Серіали';
	@override String get movies => 'Фільми';
	@override String get music => 'Музика';
	@override String tracksQueued({required Object count}) => '${count} сліди, що переглядаються для завантаження';
	@override String get noDownloads => 'Досі немає завантажень';
	@override String get noDownloadsDescription => 'Завантажений контент з\'явиться тут для офлайн перегляду';
	@override String get downloadNow => 'Завантажити';
	@override String get deleteDownload => 'Завантажити Download';
	@override String get retryDownload => 'Завантажити Retry';
	@override String get downloadQueued => 'Завантаження в черзі.';
	@override String get downloadResumed => 'Завантажити відновлено';
	@override String get serverErrorBitrate => 'Помилка сервера: файл може перевищувати ліміт віддаленого бітрату';
	@override String get storageFull => 'Завантаження зупинилися, щоб захистити доступне зберігання. Завантажити деякий простір або вибрати інше місце завантаження, а потім відмовитися.';
	@override String get storageUnavailable => 'Завантаження зупинилися, тому що доступне зберігання не може бути перевірено. перевірте місце завантаження, а потім відкликайте.';
	@override String episodesQueued({required Object count}) => '${count} Епізоди, що переглядаються для завантаження';
	@override String get downloadDeleted => 'Завантажити видалено';
	@override String deleteConfirm({required Object title}) => 'Видалити «${title}» з цього пристрою?';
	@override String get deleteCollectionDownloads => 'Зняти завантаження';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Видаляти кожну завантаження в розділі «${title}» з цього пристрою?';
	@override String get collectionDownloadsDeleted => 'Завантаження видалені';
	@override String get cancelledDownloadTitle => 'скасовано завантаження';
	@override String get cancelledDownloadMessage => 'Завантаження було скасовано. що ви хотіли б зробити?';
	@override String get allEpisodesAlreadyDownloaded => 'Всі епізоди вже завантажені';
	@override String get resumeDownload => 'Резюме завантаження';
	@override String get cancelledDownload => 'скасовано Download';
	@override String syncingFile({required Object file, required Object status}) => '${file} (синціонує ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'Завантажено ${file} - Клікніть, щоб завершити';
	@override String get partialDownloadClickToComplete => 'Частково завантажено - Клікніть, щоб завершити';
	@override String get deleting => 'Зняти...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Видалення ${title}... (${current} з ${total})';
	@override String get queuedTooltip => 'Квітень';
	@override String queuedFilesTooltip({required Object files}) => 'Завантажити ${files}';
	@override String get downloadingTooltip => 'Завантажити...';
	@override String downloadingFilesTooltip({required Object files}) => 'Завантажити ${files}';
	@override String get noDownloadsTree => 'Без завантаження';
	@override String get pauseAll => 'Відпочинок усі';
	@override String get resumeAll => 'Резюме Все';
	@override String get retryAll => 'Відкликати всі';
	@override String get retryFailed => 'Завантажити недійсні завантаження';
	@override String get deleteAll => 'Видалити все';
	@override String get selectVersion => 'Вибір версії';
	@override String get allEpisodes => 'Всі епізоди';
	@override String get unwatchedOnly => 'Не спостерігається тільки';
	@override String nextNUnwatched({required Object count}) => '${count} не перевірено';
	@override String get customAmount => 'Кваліфікована сума...';
	@override String get customAmountAny => 'Кількість витрат (за кожну...';
	@override String get randomEpisodes => 'Різні епізоди';
	@override String get includeSpecials => 'Включити спеціальності';
	@override String get howManyEpisodes => 'Скільки епізодів?';
	@override String get invalidEpisodeCount => 'Введіть діючу кількість епізодів.';
	@override String get keepSynced => 'Зберігайте синхронізацію';
	@override String get downloadOnce => 'Завантажити один раз';
	@override String keepNUnwatched({required Object count}) => 'Залишити ${count} не перевірено';
	@override String get editSyncRule => 'Регулювання правила синхронізації';
	@override String get removeSyncRule => 'Видалення правила синхронізації';
	@override String removeSyncRuleConfirm({required Object title}) => 'Припинити синхронізацію «${title}»? Завантажені епізоди буде збережено.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Залишити синхронізацію «${title}»?';
	@override String get deleteSyncRuleDownloads => 'Також видаляти пов\'язані завантаження';
	@override String get deleteSyncRuleDownloadsDescription => 'Завантаження, які використовуються іншим правилом синхронізації або профілем, будуть зберігатися.';
	@override String syncRuleCreated({required Object count}) => 'Правила синхронізації створена — зберігання ${count} невідомих епізодів';
	@override String get syncRuleUpdated => 'Правила синхронізації оновлено';
	@override String get syncRuleRemoved => 'Правила синхронізації видалені';
	@override String get syncRuleAndDownloadsRemoved => 'Правила синхронізації та пов\'язані з ними завантаження видалені';
	@override String get syncRuleCleanupBusy => 'Правила синхронізації в даний час оновлюються. спробуйте знову на хвилину.';
	@override String get syncRuleCleanupUnavailable => 'Повторне підключення сервера і спробуйте знову, або видалити правило без видалення завантажень.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Синхронізовано ${count} нові епізоди для ${title}';
	@override String get syncNow => 'Сінтеграція зараз';
	@override String get downloadsUpToDate => 'Завантаження на даний момент';
	@override String syncComplete({required Object queued, required Object removed}) => 'Сінк повний · ${queued} queued, ${removed} видалено';
	@override String get activeSyncRules => 'Правила синхронізації';
	@override String get reviewOrphanFiles => 'Завантажити Orphaned Downloads';
	@override String get orphanReviewTitle => 'Завантажити Orphaned Downloads';
	@override String get orphanReviewDescription => 'Ці етикетковані файли знаходяться в папках завантаження, що керуються прикладом PlezyNG і не мають відповідних записів завантаження або активних завдань.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} файли · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Видалення файлів ${count}';
	@override String get orphanCleanupNone => 'Не знайдено файлів для завантаження';
	@override String get orphanCleanupFailed => 'PlezyNG не міг безпечно сканувати папку завантажень.';
	@override String get orphanCleanupChanged => 'Список завантажень змінився під час перегляду. переглянути файли знову перед очищенням.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Вилучено ${count} сироти · ${size} звільнено';
	@override String get noSyncRules => 'Правила синхронізації';
	@override String get manageSyncRule => 'Управління синхронізацією';
	@override String get editEpisodeCount => 'Епізод рахунків';
	@override String get editSyncFilter => 'Фільтр синхронізації';
	@override String get syncAllItems => 'Сінтеграція всіх предметів';
	@override String get syncUnwatchedItems => 'Сінціонування непереглянутих предметів';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Сервер: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Доступно';
	@override String get syncRuleOffline => 'Офлайн';
	@override String get syncRuleSignInRequired => 'Підписання в необхідному';
	@override String get syncRuleAccessDenied => 'Доступ відмовляється';
	@override String get syncRuleNotAvailableForProfile => 'Не доступний для поточного профілю';
	@override String get syncRuleUnknownServer => 'Невідомий сервер';
	@override String get syncRuleListCreated => 'Створено правило синхронізації';
	@override late final _Translations$downloads$backgroundWarning$uk backgroundWarning = _Translations$downloads$backgroundWarning$uk._(_root);
	@override String get options => 'Завантажити опції';
	@override late final _Translations$downloads$groupings$uk groupings = _Translations$downloads$groupings$uk._(_root);
	@override String get unknownLibrary => 'Невідома бібліотека';
	@override String get unknownShow => 'Невідомий шоу';
	@override String get unknownSeason => 'Невідомий сезон';
	@override String get unknownAlbum => 'Невідомий альбом';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} завершено';
	@override String storageUsed({required Object size}) => 'Зберігання використовується: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантаження',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантаження',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантажень',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантаження',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіал',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіали',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіалів',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіали',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільм',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільми',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільмів',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільми',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбом',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбоми',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбомів',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбоми',
	);
	@override String get errorFileNotFound => 'Файл не знайдено (404)';
	@override String get errorDownloadNotAllowed => 'Завантаження не дозволено сервером (403)';
	@override String get errorDownloadFailed => 'Завантаження провалилося';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Завантажити не вдалося: ${reason}';
	@override String get convertingOnServer => 'Перехід на сервер.';
	@override String convertingOnServerPercent({required Object percent}) => 'Конвертація на сервер · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Завантажити не вдалося (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Пост-процесування не вдалося: ${reason}';
	@override String get reasonFileNotSaved => 'Файл не може бути збережений на цьому пристрої.';
	@override String get reasonCannotResume => 'Часткового завантаження не можна було відновити';
	@override String get reasonDeviceStorageFull => 'Цей пристрій вийшов з складу';
	@override String get notificationDownloading => 'Завантажити...';
	@override String get notificationComplete => 'Завантажити повний';
	@override String get notificationPaused => 'Завантажити Pause';
}

// Path: shaders
class _Translations$shaders$uk extends Translations$shaders$en {
	_Translations$shaders$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Шейдер';
	@override String get noShaderDescription => 'Без відеопосилення';
	@override String get nvscalerDescription => 'NVIDIA зображення скалювання для більш яскравих відео';
	@override String get artcnnVariantNeutral => 'Нейтральний';
	@override String get artcnnVariantDenoise => 'Денонс';
	@override String get artcnnVariantDenoiseSharpen => 'Створення Denoise + Sharpen';
	@override String get qualityFast => 'Швидкість';
	@override String get qualityHQ => 'Висока якість';
	@override String get mode => 'Мода';
	@override String get importShader => 'Імпорт Шейдер';
	@override String get customShaderDescription => 'Створення GLSL Shader';
	@override String get shaderImported => 'Шейдер імпортує';
	@override String get shaderImportFailed => 'Не вдалося ввезення шахтаря';
	@override String get deleteShader => 'Зніміть Shader';
	@override String deleteShaderConfirm({required Object name}) => 'Вимкніть «${name}»';
}

// Path: companionRemote
class _Translations$companionRemote$uk extends Translations$companionRemote$en {
	_Translations$companionRemote$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Додатковий пульт';
	@override String connectedTo({required Object name}) => 'Підключений до ${name}';
	@override String get unknownDevice => 'Невідомі пристрої';
	@override late final _Translations$companionRemote$session$uk session = _Translations$companionRemote$session$uk._(_root);
	@override late final _Translations$companionRemote$pairing$uk pairing = _Translations$companionRemote$pairing$uk._(_root);
	@override late final _Translations$companionRemote$remote$uk remote = _Translations$companionRemote$remote$uk._(_root);
	@override late final _Translations$companionRemote$errors$uk errors = _Translations$companionRemote$errors$uk._(_root);
	@override String get closedBeforeAuth => 'Зв\'язок закритий до аутентифікації';
}

// Path: videoSettings
class _Translations$videoSettings$uk extends Translations$videoSettings$en {
	_Translations$videoSettings$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Швидкість відтворення';
	@override String get normalSpeed => 'Звичайний';
	@override String sleepTimerActive({required Object duration}) => 'Активний (${duration})';
	@override String get zoom => 'Масштабувати';
	@override String get sleepTimer => 'Співак час';
	@override String get audioSync => 'аудіо синхронізація';
	@override String get subtitleSync => 'Підзаголовок Sync';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR не доступний тут — цей настільний композитор або відеовихід не може нести його.';
	@override String get hdrToneMapping => 'HDR Tone Картування';
	@override String get hdrToneMappingCompositor => 'Композитор';
	@override String get hdrToneMappingCompositorDescription => 'Перейти через джерело HDR метадатів і залишити на робочому столі композитор карту його.';
	@override String get hdrToneMappingPlayer => 'Програвач';
	@override String get hdrToneMappingPlayerDescription => 'Карта до вершини яскравості екрану в гравці, а потім повідомити композитору результат.';
	@override String get hdrToneMappingFailed => 'Не можна було змінити тонус HDR - попередній режим все ще активний.';
	@override String get audioOutput => 'аудіо вихід';
	@override String get performanceOverlay => 'Продукція Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'навколо';
	@override String get audioOutputSpatial => 'Космічний аудіо';
	@override String get audioOutputStereo => 'Стерео';
	@override String get audioEqualizer => 'Аудіо Еквалізований';
	@override String get audioEqualizerDescription => 'Доступно на mpv; активний EQ декодує аудіо і відключає збій.';
	@override String get audioEqualizerFlat => 'Площа';
	@override String get audioEqualizerActive => 'Користувацький';
	@override String get audioEqualizerSaveFailed => 'Не можна було встановити звуковий еквівалент.';
	@override String get backgroundVideoAudio => 'Завантажити Video Audio';
	@override String get backgroundVideoAudioDescription => 'Зберігайте відео-аудіо грати, коли ви покинете гравець; зображення приховується, поки ви не повернетеся. Android використовує повідомлення про відтворення засобів масової інформації.';
	@override String get audioNormalization => 'Нормалізація шуму';
	@override String get audioNormalizationDisablesPassthrough => 'Декодує аудіо до PCM; passthrough вимкнеться, поки це на';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$uk extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get color => 'Колір';
	@override String get performance => 'Продуктивність';
	@override String get buffer => 'Буффер';
	@override String get app => 'Додаток';
	@override String get decoder => 'Декорація';
	@override String get rawDecoder => 'РОЙ ДЕКОДЕР';
	@override String get tunneling => 'тунелі';
	@override String get passthrough => 'Пастирський';
	@override String get aspect => 'Погляд';
	@override String get rotation => 'Обертання';
	@override String get dvSource => 'ДВ джерела';
	@override String get dvPath => 'ДВ ПУТ';
	@override String get dvRouteDecoder => 'Dolby Vision Декодер';
	@override String get dvRouteDecoderP81 => 'Dolby Vision декодер (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Базовий шар';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 базовий шар';
	@override String get dvRouteBaseLayerHlg => 'HLG базовий шар';
	@override String get dvRouteBaseLayerSdr => 'СДР базовий шар';
	@override String get dvRouteReshaped => 'РПУ відновлено (gpu-next)';
	@override String get p7Conversion => 'П7 Конв';
	@override String get sampleRate => 'Частота дискретизації';
	@override String get pixelFormat => 'Піксель ФМТ';
	@override String get hwFormat => 'ФМТ';
	@override String get matrix => 'Матриця';
	@override String get primaries => 'Первинні';
	@override String get transfer => 'Трансфер';
	@override String get renderFps => 'Рендер ФПС';
	@override String get displayFps => 'Дисплей FPS';
	@override String get avSync => 'А/В синхронізація';
	@override String get dropped => 'розбито';
	@override String get dvRpus => 'ДВ РПУ';
	@override String get dvRpuAverage => 'ДВ РПУ АВГ';
	@override String get dvSampleAverage => 'ДВ Семп Avg';
	@override String get maxLuma => 'Макс Люма';
	@override String get minLuma => 'Мінус Лума';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Використовується кеш';
	@override String get cacheLimit => 'Cache обмеження';
	@override String get speed => 'Швидкість';
	@override String get player => 'Програвач';
	@override String get playMethod => 'Засіб програвання';
	@override String get memory => 'Пам\'ять';
	@override String get uiFps => 'ФПС';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android ХВ';
	@override String get decoderNvidiaHw => 'Створення NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm Світовий';
	@override String get decoderMediatekHw => 'Створення MediaTek HW';
	@override String get decoderExynosHw => 'Екзотичний HW';
	@override String get decoderSoftware => 'Програмне забезпечення';
	@override String get decoderHardware => 'Хардкор';
	@override String get tunnelingActive => 'Активний';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} не вдалося)';
}

// Path: externalPlayer
class _Translations$externalPlayer$uk extends Translations$externalPlayer$en {
	_Translations$externalPlayer$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Зовнішній гравець';
	@override String get useExternalPlayer => 'Використовуйте зовнішній гравець';
	@override String get useExternalPlayerDescription => 'Відкрийте відео в іншому додатку';
	@override String get selectPlayer => 'Вибір гравця';
	@override String get customPlayers => 'Custom гравці';
	@override String get systemDefault => 'Системний дефолт';
	@override String get addCustomPlayer => 'Додати Custom Player';
	@override String get playerName => 'Ім\'я гравця';
	@override String get playerNameHint => 'Мій гравець';
	@override String get playerCommand => 'Командування';
	@override String get playerPackage => 'Назва пакету';
	@override String get playerUrlScheme => 'УРЛ схема';
	@override String get off => 'Вимкнути';
	@override String get launchFailed => 'Не вдалося відкрити зовнішнього гравця';
	@override String appNotInstalled({required Object name}) => '${name} не встановлено';
	@override String get playInExternalPlayer => 'Грати в зовнішній гравець';
}

// Path: metadataEdit
class _Translations$metadataEdit$uk extends Translations$metadataEdit$en {
	_Translations$metadataEdit$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Редагувати';
	@override String get screenTitle => 'Редагувати метадані';
	@override String get basicInfo => 'Основна інформація';
	@override String get artwork => 'Художня робота';
	@override String get advancedSettings => 'Прогресивні налаштування';
	@override String get title => 'Назва';
	@override String get sortTitle => 'Назва сортування';
	@override String get originalTitle => 'Оригінальний заголовок';
	@override String get releaseDate => 'Дата випуску';
	@override String get contentRating => 'Рейтинг контенту';
	@override String get studio => 'Студія';
	@override String get tagline => 'Слоган';
	@override String get summary => 'резюме';
	@override String get poster => 'Постер';
	@override String get background => 'фонтани';
	@override String get logo => 'Логотип';
	@override String get squareArt => 'Площа мистецтва';
	@override String get selectPoster => 'Виберіть постер';
	@override String get selectBackground => 'Виберіть фон';
	@override String get selectLogo => 'Вибір логотипу';
	@override String get selectSquareArt => 'Вибір площі мистецтва';
	@override String get fromUrl => 'Від URL';
	@override String get uploadFile => 'Завантажити файл';
	@override String get enterImageUrl => 'Введіть URL';
	@override String get imageUrl => 'Зображення URL';
	@override String get metadataUpdated => 'Актуальні метастази';
	@override String get metadataUpdateFailed => 'Не вдалося оновити метаданни';
	@override String get artworkUpdated => 'Актуальна художня робота';
	@override String get artworkUpdateFailed => 'Не вдалося оновити художню роботу';
	@override String get noArtworkAvailable => 'Немає художніх творів';
	@override String artworkOption({required Object index}) => 'Вибір художньої роботи ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Вибір художнього твору ${index}, вибраний';
	@override String get notSet => 'Не встановлюйте';
	@override String get libraryDefault => 'Бібліотека дефолт';
	@override String get accountDefault => 'Дефіцит рахунку';
	@override String get seriesDefault => 'Серія дефолт';
	@override String get episodeSorting => 'Епізод Сортінг';
	@override String get oldestFirst => 'Найстаріший перший';
	@override String get newestFirst => 'Найновіші перші';
	@override String get keep => 'Дотримуйтесь';
	@override String get allEpisodes => 'Всі епізоди';
	@override String latestEpisodes({required Object count}) => '${count} останні епізоди';
	@override String get latestEpisode => 'Останній епізод';
	@override String episodesAddedPastDays({required Object count}) => 'Епізоди додано за останні ${count} днів';
	@override String get deleteAfterPlaying => 'Зняти епізоди після гри';
	@override String get never => 'Ніколи';
	@override String get afterADay => 'Після одного дня';
	@override String get afterAWeek => 'Після тижня';
	@override String get afterAMonth => 'Після місяця';
	@override String get onNextRefresh => 'На наступному відновлюванні';
	@override String get seasons => 'Сезони';
	@override String get show => 'показ';
	@override String get hide => 'Приховати';
	@override String get episodeOrdering => 'Епізод замовлення';
	@override String get tmdbAiring => 'База даних фільмів (Aired)';
	@override String get tvdbAiring => 'TheTVDB (Відкритий)';
	@override String get tvdbAbsolute => 'TheTVDB (Абсолютний)';
	@override String get metadataLanguage => 'Мета-язики';
	@override String get useOriginalTitle => 'Використовуйте оригінальний заголовок';
	@override String get preferredAudioLanguage => 'Бажана мова аудіо';
	@override String get preferredSubtitleLanguage => 'Бажана мова субтитрів';
	@override String get subtitleMode => 'Автомобільний підзаголовок';
	@override String get manuallySelected => 'Ручно вибрані';
	@override String get shownWithForeignAudio => 'Завантажити аудіо з іноземним';
	@override String get alwaysEnabled => 'Завжди дозволяється';
	@override String get tags => 'Мітки';
	@override String get addTag => 'Додати тег';
	@override String get genre => 'Жанр';
	@override String get director => 'Режисер';
	@override String get writer => 'Сценарист';
	@override String get producer => 'Продюсер';
	@override String get country => 'країна';
	@override String get collection => 'Колекція';
	@override String get label => 'Етикетка';
	@override String get quickTag => 'Швидкий Tag...';
}

// Path: matchScreen
class _Translations$matchScreen$uk extends Translations$matchScreen$en {
	_Translations$matchScreen$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get match => 'Матч...';
	@override String get fixMatch => 'Змагання пройшли...';
	@override String get unmatch => 'Без матчу';
	@override String get unmatchConfirm => 'Plex розглядає його як несумісний до завершеного.';
	@override String get unmatchSuccess => 'Несумісні елементи';
	@override String get unmatchFailed => 'Невдача в безперервному об\'єкті';
	@override String get matchApplied => 'Матч застосовується';
	@override String get matchFailed => 'Не вдалося встановити матч';
	@override String get titleHint => 'Назва';
	@override String get yearHint => 'Рік';
	@override String get search => 'Пошук';
	@override String get noMatchesFound => 'Не знайдено матчів';
}

// Path: serverTasks
class _Translations$serverTasks$uk extends Translations$serverTasks$en {
	_Translations$serverTasks$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сервіс завдань';
	@override String get failedToLoad => 'Не вдалося завантажити завдання';
	@override String get noTasks => 'Не виконувати завдання';
}

// Path: trakt
class _Translations$trakt$uk extends Translations$trakt$en {
	_Translations$trakt$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Зв\'язані';
	@override String connectedAs({required Object username}) => 'Зв\'язаний як @${username}';
	@override String get disconnectConfirm => 'Вимкніть обліковий запис Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG перестане відправляти події на Trakt. Ви можете знову підключитися в будь-який час.';
	@override String get scrobble => 'Реальний час Скрипаль';
	@override String get scrobbleDescription => 'Надіслати відгуки, перерви та зупинки подій на номер Trakt під час перегляду.';
	@override String get watchedSync => 'Синхен спостерігається статус';
	@override String get watchedSyncDescription => 'Коли ви відзначаєте елементи, як спостерігалося в PlezyNG, вони також відзначаються як спостерігалося в Trakt.';
}

// Path: seerr
class _Translations$seerr$uk extends Translations$seerr$en {
	_Translations$seerr$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Зв\'яжіть Seerr';
	@override String get serverUrl => 'Сервер URL';
	@override String get serverUrlHelper => 'Адреса Вашої інстанції';
	@override String get checkServer => 'Продовжуйте';
	@override String get signInWithJellyfin => 'Зареєструйтесь за адресою Jellyfin';
	@override String get signInWithEmby => 'Зареєструйтесь за адресою Emby';
	@override String get signInWithLocal => 'Використовуйте місцевий рахунок';
	@override String get email => 'Електронна';
	@override String get noSignInMethods => 'Цей приклад Seerr не пропонує підписки методу PlezyNG підтримки.';
	@override String get instance => 'Інстанція';
	@override String get disconnectConfirm => 'Відключення від Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG забуде цей приклад Seerr. Зв\'яжіться в будь-який час.';
	@override String get request => 'Запрошення';
	@override String get request4k => 'Заявка в 4K';
	@override String get seasons => 'Сезони';
	@override String get allSeasons => 'Всі сезони';
	@override String get advancedOptions => 'Розширені';
	@override String get destinationServer => 'Сервіс призначення';
	@override String get qualityProfile => 'Профіль якості';
	@override String get rootFolder => 'Короткий папір';
	@override String get languageProfile => 'Профіль мови';
	@override String get tags => 'Мітки';
	@override String get noTags => 'Ніяких тегів';
	@override String defaultOption({required Object name}) => '${name} (за замовчуванням)';
	@override String get animeNote => 'Ця серія – це аніме.';
	@override String get requestSubmitted => 'Заява подана';
	@override String requestFailed({required Object error}) => 'Заявка про недійсність: ${error}';
	@override String get requestsLoadFailed => 'Не можна завантажувати опції запиту';
	@override String get nothingToRequest => 'Все вже доступно або запропоновано.';
	@override String get statusAvailable => 'Доступно';
	@override String get statusPartiallyAvailable => 'Частково доступні';
	@override String get statusRequested => 'Запрошені';
	@override String get statusProcessing => 'обробка';
	@override String get statusBlocklisted => 'Блокування';
	@override String couldNotReach({required Object url, required Object error}) => 'Не може досягти ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'No Seerr інстанція на ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Автентифікований зворотний прокси (SSO або HTTP auth) відповів замість Seerr. PlezyNG не може зареєструватися через нього: дозвольте Seerr /api/v1 шляху перетнути прокси для цієї програми, або використовуйте адресу, яка досягає Seerr безпосередньо.';
	@override String get invalidUrl => 'Введіть адресу сервера, наприклад, https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Цей приклад Seerr не підтримує Quick Connect. він потребує Seerr 3.4 або вище.';
	@override String get notInitialized => 'Цей приклад Seerr не завершив першочергову установку';
	@override String get noPlexTokenForReauth => 'Токен No Plex доступний для реєстрації знову';
	@override String get noStoredCredentials => 'Немає збережених даних для повторного входу';
	@override String get signInRejected => 'Підписання було відхилено';
	@override String get noSessionCookie => 'Seerr не видав cookie сесії';
	@override String get freshCookieRejected => 'Seerr відмовився від нового cookie сесії';
	@override String get noUserInformation => 'Seerr не повернула інформацію користувача';
	@override String get sessionRejectedAfterReauth => 'Засідання було відхилено після повторного підписання.';
	@override String get permissionDenied => 'Seerr відмовився від цієї дії: Ваш обліковий запис більше не має необхідного дозволу';
	@override String get permissionRevoked => 'Ви більше не маєте права вимагати цього.';
}

// Path: services
class _Translations$services$uk extends Translations$services$en {
	_Translations$services$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сервіси';
	@override String get hubSubtitle => 'Sync спостерігає за прогресом і запитує нові заголовки.';
	@override String get integrations => 'Інтеграції';
	@override String get notConnected => 'Не пов\'язані';
	@override String connectedAs({required Object username}) => 'Зв\'язаний як @${username}';
	@override String get scrobble => 'Слідкуйте за прогресом автоматично';
	@override String get scrobbleDescription => 'Оновлюйте свій список, коли ви закінчите епізод або фільм.';
	@override String disconnectConfirm({required Object service}) => 'Відключення ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG буде припиняти оновлення ${service}.';
	@override String connectFailed({required Object service}) => 'Я не можу підключитися до ${service}. спробуйте знову.';
	@override late final _Translations$services$names$uk names = _Translations$services$names$uk._(_root);
	@override late final _Translations$services$simklReconnect$uk simklReconnect = _Translations$services$simklReconnect$uk._(_root);
	@override late final _Translations$services$deviceCode$uk deviceCode = _Translations$services$deviceCode$uk._(_root);
	@override late final _Translations$services$oauthProxy$uk oauthProxy = _Translations$services$oauthProxy$uk._(_root);
	@override late final _Translations$services$pendingAuth$uk pendingAuth = _Translations$services$pendingAuth$uk._(_root);
	@override late final _Translations$services$libraryFilter$uk libraryFilter = _Translations$services$libraryFilter$uk._(_root);
}

// Path: addServer
class _Translations$addServer$uk extends Translations$addServer$en {
	_Translations$addServer$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Додати сервер ${product}';
	@override String get serverUrls => 'Сервер URL';
	@override String get serverUrlsHelper => 'Дозволені кілька URL, розділені коммами.';
	@override String get findServer => 'Знайти сервер';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Пошук місцевих серверів ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'Місцеві сервери ${product}';
	@override String get username => 'Ім’я користувача';
	@override String get password => 'Пароль';
	@override String get signIn => 'Вхід';
	@override String get change => 'Зміни';
	@override String get required => 'Потрібні';
	@override String couldNotReachServer({required Object error}) => 'Не можна доступу до сервера: ${error}';
	@override String signInFailed({required Object error}) => 'Зареєструватися не вдалося: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect не вдалося: ${error}';
	@override String get addPlexTitle => 'Зареєструйтесь за адресою Plex';
	@override String get pinExpired => 'PIN закінчився перед тим, як зареєструватися, будь ласка, спробуйте знову.';
	@override String failedToRegisterAccount({required Object error}) => 'Зареєструватися не вдалося: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Введіть URL сервера ${product}';
	@override String get addConnectionTitle => 'Додати зв\'язок';
	@override String addConnectionTitleScoped({required Object name}) => 'Додати до ${name}';
	@override String get signInWithPlexCard => 'Зареєструйтесь за адресою Plex';
	@override String get signInWithPlexCardSubtitle => 'Додайте доступ до цього пристрою.Додаються спільні сервери.';
	@override String get signInWithPlexCardSubtitleScoped => 'Дозвіл на обліковий запис Plex Домашні користувачі стають профілями.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Підключення до ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Введіть URL сервера, ім\'я користувача та пароль.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Зареєструйтесь на сервер ${product}. підключіться до ${name}.';
	@override String get borrowFromAnotherProfile => 'Кредит з іншого профілю';
	@override String get borrowFromAnotherProfileSubtitle => 'Повторне використання підключення іншого профілю. PIN-захищені профілі потребують PIN.';
	@override String get invalidCredentials => 'Недійсне ім\'я користувача або пароль';
	@override String get authResponseNotJson => 'Відповідь на аутентифікацію не була дійсною JSON';
	@override String get authResponseIncomplete => 'Реакція сервера була неповною.';
	@override String get quickConnectRejected => 'Quick Connect було відхилено сервером';
	@override String get quickConnectNotJson => 'Відповідь Quick Connect не була дійсною JSON';
	@override String get quickConnectMissingFields => 'Відповідь Quick Connect відсутня код або секрет';
	@override String get quickConnectPollRejected => 'Quick Connect запит було відхилено сервером';
	@override String get serverTimedOut => 'Сервер не відповідає вчасно';
	@override String get responseNotJson => 'Серверна відповідь не була дійсною JSON';
	@override String responseMissingIdentity({required Object product}) => 'Відповідь відсутня ідентифікатор або прізвище сервера — чи є це сервером ${product}?';
	@override String probeFailed({required Object error}) => 'Не можна доступу до сервера: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Введіть щонайменше один серверний URL ${product}';
	@override String noReachableServer({required Object product}) => 'Не знайдено сервера ${product}';
	@override String urlsPointToDifferentServers({required Object product}) => 'Ці URL-адреси вказують на різні сервери ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'Цей URL не відповідає серверу ${product}';
	@override String get redirectUnsupported => 'Сервер перенаправлено на непомітний URL';
	@override String redirectDifferentHost({required Object product}) => 'Сервер перенаправлений на інший хостинг. Введіть URL ${product} прямо.';
	@override String get redirectInsecure => 'Сервер перенаправлено з HTTPS на небезпечний URL';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Сервер перенаправлено на непоміщену URL. Введіть URL ${product} прямо.';
	@override String get directPlexServerUrl => 'Plex сервер URL';
	@override String get directPlexServerUrlHelper => 'Введіть місцевий IP і порт вашого Медіа-сервера Plex.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Токен (вибірковий)';
	@override String get plexTokenHelper => 'Залишити вільний, якщо доступ без аут дозволений на цьому сервері.';
	@override String get plexTokenRequired => 'Будь ласка, введіть свій токен Plex (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Медіа-сервер (прямий / місцевий)';
	@override String get connectDirectPlexCardSubtitle => 'Зв\'яжіться безпосередньо за допомогою локального IP або URL без облікового запису plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Зв\'яжіться безпосередньо за допомогою локального IP або URL. зв\'яжіться до ${name}.';
	@override String get insecureTitle => 'Нешифрований зв\'язок';
	@override String insecureDescription({required Object url}) => '${url} використовує HTTP. Інші користувачі мережі можуть прочитати або змінити ваш пароль, токени та медіа. За можливості використовуйте HTTPS. Продовжуйте лише тоді, коли довіряєте цій мережі та приймаєте ризик.';
	@override String get allowHttp => 'Дозвіл HTTP';
	@override String get httpsRequired => 'Використовуйте HTTPS або експлицитно дозволяйте нешифрований зв\'язок.';
}

// Path: watchLink
class _Translations$watchLink$uk extends Translations$watchLink$en {
	_Translations$watchLink$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Я не міг дістатися до сервера Plex для цього посилання.';
	@override String get notFound => 'Я не можу знайти цей шоу або фільм на ваших серверах Plex.';
	@override String get ambiguous => 'Цей посилання відповідає елементам на більш ніж одному сервері. Додати сервер до посилання.';
	@override String get plexOnly => 'В даний час підтримує тільки сервери Plex.';
	@override String get unsupportedItem => 'Переглянути посилання можна тільки відкрити шоу або фільм.';
	@override String get menuItem => 'Показати посилання';
	@override String get dialogTitle => 'Переглянути link';
	@override String get dialogShowHint => 'Відкриття цього посилання грає наступний епізод. Додати &mode=shuffle до кінця, щоб грати шоу на shuffle.';
	@override String get dialogMovieHint => 'Відкриття цього посилання грає фільм.';
	@override String get copy => 'Копіювати';
	@override String get copied => 'Link копіюється';
}

// Path: homeLayout
class _Translations$homeLayout$uk extends Translations$homeLayout$en {
	_Translations$homeLayout$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Домашнє лайнування';
	@override String get resetToast => 'Повернення до оригінальної версії героя Plezy';
	@override String get resetHeroTitle => 'Перезавантажити героїчний розклад на запас Plezy?';
	@override String get resetHeroBody => 'Звертає героїчний набір кожного ряду і повертає єдиний ротаційний банер на вершині Дома, як і до героїчних рядів існували.';
	@override String get removeRowTitle => 'Зняти домашню лінію?';
	@override String removeRowBody({required Object title}) => '${title} буде видалено. це не може бути відхилено.';
	@override String get sync => 'Сінтеграція';
	@override String get syncAccountTitle => 'Спілкуйтеся з вашим обліковим записом Plex';
	@override String get syncAccountOn => 'На: Цей пристрій ділиться порядком, рядками, Героєм і Авто-Слайдом з іншими пристроями.';
	@override String get syncAccountOff => 'Вимкнено: цей пристрій зберігає свій власний розклад.';
	@override String get syncNow => 'Сінтеграція зараз';
	@override String get plexHomeManager => 'Plex Домашній менеджер';
	@override String get managePlexRows => 'Управління Plex рядки в Plezy';
	@override String get managePlexRowsDescription => 'Відкрито для організації домашньо вибраних рядків';
	@override String get organizeHomeRows => 'Організуйте домашній ряд';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} рядки: переміщення, Герої, Авто-Слайд, видалення';
	@override String organizeLibraryRows({required Object library}) => 'Організуйте ${library} рядки';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Продовжуйте дивитися + ${n} рядки: переміщення, Бібліотека, Домашній, Герої, Авто-Слайд';
	@override String get renderAsHero => 'Повернення як героїчна картка';
	@override String get heroOnlySingleCollection => 'Доступно тільки тоді, коли ця рядка вирішується на реальні заголовки однієї колекції';
	@override String get hero => 'Герой';
	@override String get autoSlide => 'Автомобільний слайд';
	@override String get autoSlideDescription => 'Пристрій (PC) і d-pad (TV) завжди працюють і відновлюють час.';
	@override String get autoSlideEditDescription => 'Вимкніть: рухається тільки тоді, коли натискаєте стрілку (ПК) або натискаєте ліво/право на віддаленому (ТВ).';
	@override String get enableHeroFirst => 'Перший герой';
	@override String get showOnHome => 'Показати на домашньому екрані';
	@override String get home => 'Головна';
	@override String get removeFromHome => 'Зняти з дому';
	@override String get selectRowsFirst => 'Виберіть домашній ряд нижче першого.';
	@override String plexManagedRows({required Object n}) => '${n} Plex управляються рядки';
	@override String get continueWatching => 'Продовжити перегляд';
	@override String get continueWatchingLibraryDescription => 'Бібліотека має власний рецидив прогресу';
	@override String get continueWatchingHomeDescription => 'Повторний прогрес, показані на Home';
	@override String get nextUpHomeDescription => 'Наступна непереглянута серія епізодів відображається окремо на Home';
	@override String get library => 'Медіатека';
	@override String get showInRecommended => 'Показати в бібліотеці Рекомендовано';
	@override String get customPlexRow => 'Кваліфікований Plex ряд';
	@override String get heroNeedsLibrary => 'Перевірте Бібліотеку спочатку — Герою потрібно десь показати';
	@override String get heroNeedsSurface => 'Перевірте Бібліотеку або Дому спочатку — Герою потрібно десь показати';
	@override String get removeHub => 'Видалення Hub';
	@override String get noPlexRows => 'No Plex-управлені рядки повернулися для цієї бібліотеки.';
	@override String get openDetails => 'Відкриті деталі';
	@override String get heroCards => 'Герої картки';
	@override String get tapHeroCard => 'Завантажити картку героя';
	@override String get tvPlayFocus => 'Телевізор віддалений: підкреслює кнопку Play';
	@override String get tvPlayFocusDescription => 'D-pad down зупиняється на кнопці Play, перш ніж перейти до наступного рядка.';
	@override String get tvWrap => 'Телевізійні дистанційні: картки героїв';
	@override String get tvWrapDescription => 'Права на останній картці йде назад до першої.Відстають зупинки на останній картці.Лево на першій картці завжди йде до бокової смуги.';
	@override String get castOnHero => 'Завантажити Hero Banner';
	@override String get castOnHeroDescription => 'Показати виставку уздовж нижньої частини героїчного банера. Офіційно зберігається тільки заголовок і резюме.';
	@override String get customRows => 'Кваліфіковані рядки';
	@override String get loading => 'Завантажити Home Layout';
	@override String get noCustomRows => 'Досі немає звичайних рядків';
	@override String get addRowHint => 'Використовуйте Додати домашній ряд, щоб створити один.';
	@override String get addHomeRow => 'Додати додому';
	@override String get addHomeRowDescription => 'Виберіть категорію; новий ряд додається до Організатора автоматично';
	@override String get removeRow => 'Зняти ряд';
	@override String get recentlyAdded => 'Нещодавно додані';
	@override String get recentlyReleased => 'Нещодавно звільнений';
	@override String get movieCollections => 'Колекції фільмів';
	@override String get showCollections => 'Покажіть колекції';
	@override String get rowTitle => 'Роу титул';
	@override String get content => 'Контент';
	@override String get showThisRowIn => 'Показати цю рядку в:';
	@override String get libraryRecommended => 'Рекомендована бібліотека';
	@override String get heroCard => 'Герой картки';
	@override String get heroCardDescription => 'Показано як одна повна широта ротаційна карта замість плакатної шафи.';
	@override String get heroUnavailableDescription => 'Доступно тільки тоді, коли ця рядка розв\'язується до реальних заголовків однієї колекції — з більш ніж однією колекцією вибраних немає жодного заголовка, який би міг би перевернути.';
	@override String get librariesSelection => 'Бібліотеки (відпустіть всі не перевірені для включення кожної бібліотеки)';
	@override String get librariesMergedDescription => 'Кожна бібліотека, що перевіряється тут, поєднується в цей один ряд.';
	@override String get movieCollectionsSelection => 'Колекції фільмів (залишити всі не перевірені для кожної вибраної бібліотеки)';
	@override String get showCollectionsSelection => 'Показати колекції (залишити всі непереглянуті для кожної вибраної бібліотеки)';
	@override String get collectionRowsDescription => 'Якщо саме одна колекція зіграє, її заголовки відображаються безпосередньо в рядку. якщо більше однієї зіграє, кожна колекція відображається як один плакат — натисніть її, щоб відкрити цю колекцію.';
	@override String get allCollections => 'Всі колекції';
	@override String get noRowsHere => 'Поки що тут немає рядів.';
	@override String get hideWatchedRows => 'Закрити спостережені предмети в рядках';
	@override String get hideWatchedRowsDescription => 'Повноцінно переглянуті заголовки залишають Домашнє та бібліотечне Рекомендовані рядки.';
	@override String get untitledCollection => 'Незаголошена колекція';
	@override String get moveRowHint => 'Завантажити / Завантажити: перемістити ряд · Виберіть: залишити тут · Звернути: скасувати';
	@override String get organizeRowsHint => 'Виберіть на рядку (або тримайте Виберіть): перемістіть · Ліворуч/Праворуч: варіанти рядку · Повернутись: зроблено';
	@override String get layoutNavDescription => 'Виберіть рядки, бібліотеки та колекційні категорії';
	@override String get editHomeRow => 'Реферат на тему: Home Row';
	@override String get resetHeroButton => 'Перезавантажити героїчний розклад на запас Plezy';
	@override String get reorderingUnlocked => 'Перезавантаження відключено';
	@override String get reorderingLocked => 'Перезавантаження заблоковано';
	@override String get rowsCanBeDragged => 'Використання зубів можна відтягнути — натисніть замок, щоб запобігти цьому';
	@override String get tapLockToDrag => 'Натисніть замок, щоб витягнути рядки';
	@override String customRowLabel({required Object title}) => 'Кваліфікація: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Приховати';
	@override String get remove => 'Видалити';
	@override String get libraryResumeRow => 'Бібліотека відновлюється';
	@override String get pressAgainToDelete => 'Натисніть знову, щоб видалити';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'На';
	@override String get resetHeroButtonDescription => 'Відкидає налаштування героя кожної серії і повертає єдиний ротаційний банер вгору, як і до того, як героїчні серії існували.';
}

// Path: platform
class _Translations$platform$uk extends Translations$platform$en {
	_Translations$platform$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG підключається до ваших медіа-серверів та пристроїв відтворення на вашій локальній мережі.';
	@override String get locationPermission => 'PlezyNG використовує доступ до геопозиції, коли iOS вимагає його для виявлення локальної мережі та підключення до ваших медіасерверів.';
	@override String get photoLibraryPermission => 'Виберіть зображення з фототеки для обкладинок медіафайлів.';
	@override String get cameraPermission => 'Сканувати QR-коди, щоб з\'єднати Companion Remote.';
}

// Path: fileSources
class _Translations$fileSources$uk extends Translations$fileSources$en {
	_Translations$fileSources$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Файли та книги';
	@override String get subtitle => 'Читати, слухати і спостерігати за своїми файлами.';
	@override String get add => 'Додати джерело';
	@override String get importFiles => 'Імпорт файлів';
	@override String get localFiles => 'На цьому пристрої';
	@override String get source => 'Джерело';
	@override String get name => 'Ім’я';
	@override String get endpoint => 'Сервер URL';
	@override String get root => 'Папка або префікс';
	@override String get username => 'Ім’я користувача';
	@override String get password => 'Пароль';
	@override String get token => 'API токен';
	@override String get accessKey => 'Доступний ключ ID';
	@override String get secretKey => 'Секретний ключ доступу';
	@override String get sessionToken => 'Сеанс токен (опціональний)';
	@override String get region => 'Регіон';
	@override String get clientId => 'Клієнт ID';
	@override String get clientSecret => 'OAuth Client Secret (один робочий стіл Google)';
	@override String get allowHttp => 'Дозволити незашифроване HTTP-з’єднання в довіреній мережі';
	@override String get connect => 'Підключитись';
	@override String get cancel => 'Скасувати';
	@override String get save => 'Зберегти';
	@override String get close => 'Закрити';
	@override String get removeSource => 'Відключення джерела';
	@override String get disconnectMessage => 'Від’єднати це джерело? Завантажені файли та історія читання й прослуховування залишаться на цьому пристрої.';
	@override String get localFolder => 'Вибір папки';
	@override String get empty => 'Тут ще нічого';
	@override String get emptyHint => 'Додайте джерело або імпортуйте книгу, аудіокнигу, музику або відео.';
	@override String get search => 'Пошук цього папки';
	@override String get searchCached => 'Пошук збережена бібліотека';
	@override String get refresh => 'Оновити';
	@override String get loadMore => 'Завантажити більше';
	@override String get offline => 'Доступно офлайн';
	@override String get download => 'Залишити офлайн';
	@override String get removeDownload => 'Видалення офлайн копії';
	@override String get continueReading => 'Читати далі';
	@override String get continueListening => 'Продовжити прослуховування';
	@override String get continueWatching => 'Продовжити перегляд';
	@override String get read => 'Читати';
	@override String get listen => 'Слухати';
	@override String get play => 'Грати';
	@override String get pause => 'Пауза';
	@override String get stop => 'Зупинити';
	@override String get startOver => 'Почнемо з';
	@override String get finished => 'Завершено';
	@override String get markFinished => 'Марк закінчився';
	@override String get markUnfinished => 'Марк нескінченний';
	@override String get editions => 'Епізоди та файли';
	@override String get chapters => 'Розділи';
	@override String get bookmarks => 'Книжкові знаки та нотації';
	@override String get bookmark => 'Додати книжковий знак';
	@override String get highlight => 'Підвищення';
	@override String get note => 'Зауважимо';
	@override String get delete => 'Видалити';
	@override String get export => 'Експортні нотації';
	@override String get exported => 'Нотації експортуються';
	@override String get sync => 'Сінтеграція прогресу';
	@override String get synced => 'Прогрес синхронізований';
	@override String get conflict => 'Інший пристрій має іншу позицію. виберіть, де продовжувати.';
	@override String get useLocal => 'Використовуйте цей пристрій';
	@override String get useRemote => 'Використовуйте інші пристрої';
	@override String get history => 'Історія позиції';
	@override String get groupAudio => 'Слухайте як аудіокнигу';
	@override String get groupHint => 'Об’єднує аудіофайли, завантажені зараз у цій папці. Спочатку завантажте всі сторінки.';
	@override String get order => 'Файловий порядок';
	@override String get moveUp => 'Змінюйся';
	@override String get moveDown => 'Перемістити вниз';
	@override String get speed => 'Швидкість відтворення';
	@override String get sleep => 'Тимчасовий сон';
	@override String get sleepOff => 'Вимкнути';
	@override String get endChapter => 'Кінець розділу';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилина',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилини',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилин',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилини',
	);
	@override String get skipBack => 'Скіп назад';
	@override String get skipForward => 'Скіп вперед';
	@override String get smartRewind => 'Смарт-реванш після перерви';
	@override String get playbackOptions => 'Вибір слухача';
	@override String remaining({required Object time}) => '${time} залишився';
	@override String get contents => 'Контент';
	@override String get readerSettings => 'Читати Постачання';
	@override String get fontSize => 'Розмір тексту';
	@override String get lineHeight => 'Лінія простір';
	@override String get margin => 'Маргіна';
	@override String get font => 'Тип';
	@override String get serif => 'Серіф';
	@override String get sans => 'Без засічок';
	@override String get mono => 'Моноширинний';
	@override String get columns => 'Колонки';
	@override String get scroll => 'Скріл вертикально';
	@override String get justify => 'Вирівняти текст за шириною';
	@override String get readerTheme => 'Поява сторінки';
	@override String get appTheme => 'Слідкуйте за темою App';
	@override String get paper => 'папір';
	@override String get sepia => 'Сепія';
	@override String get night => 'Ночі';
	@override String get readAloud => 'Читати цю сторінку голосно';
	@override String get readAlong => 'Читати далі';
	@override String get stopReading => 'Зупинити озвучення';
	@override String get searchBook => 'Пошук в книзі';
	@override String get noMatches => 'Ніяких матчів';
	@override String get previousPage => 'Попередня сторінка';
	@override String get nextPage => 'Наступна сторінка';
	@override String page({required Object number}) => 'Сторінка ${number}';
	@override String get externalBlocked => 'Зовнішні посилання в книгах вимкнено в читачі.';
	@override String get loading => 'Відкриття...';
	@override String get narrator => 'Назавжди';
	@override String get audio => 'Аудіо';
	@override String get video => 'Відео';
	@override String get ebooks => 'Ексклюзивні';
	@override String get all => 'Всі';
	@override String get downloads => 'Офлайн файли';
	@override String get confirmDelete => 'Видалити вибрану офлайн-копію? Ваше місце читання або прослуховування та нотатки збережуться.';
	@override String get errorAuthentication => 'Увійдіть знову, щоб відновити з’єднання з цим джерелом.';
	@override String get errorPermission => 'Цей джерело не надало доступу до запитуваного файлу.';
	@override String get errorUnavailable => 'Попробуйте знову або відкрийте офлайн-копію.';
	@override String get errorUnsupported => 'Цей формат або підключення не підтримується на цьому пристрої. перевірте джерело інсталяції.';
	@override String get errorInvalidData => 'Цей файл або серверний відповідь не можна було безпечно читати.';
	@override String get errorCancelled => 'Операція була скасована.';
	@override String get errorConflict => 'Позиція змінилася в іншому сесії. знову відкрити пункт, щоб вибрати позицію.';
	@override String get signIn => 'Вхід';
	@override String get reconnect => 'Відновлення';
	@override String get folderHelp => 'Залишити вільний, щоб почати з коріння джерела. URL-адреси S3 включають букет.';
	@override String get preferences => 'Переваги';
	@override String get timePosition => 'Позиція';
	@override String get audioTrack => 'Аудіо трак';
	@override String get subtitleTrack => 'Підзаголовок трак';
	@override String get none => 'Нічого';
	@override String get fullscreen => 'Повний екран';
	@override String get syncLocation => 'Прогрес синхронізування папки (опціональна)';
	@override String get syncLocationHint => 'Окрема папка WebDAV для стану PlezyNG. Використовує умовний запис; медіафайли не змінюються.';
	@override String get audiobooks => 'Аудіокниги';
	@override String get comics => 'Комікси';
	@override String get scan => 'Скенію для книг та медіа';
	@override String get browserReader => 'Відкритий читач';
	@override String get browserReaderHelp => 'Читач відкритий у вашому браузері. Зберігайте PlezyNG відкритим, щоб зберегти своє місце і записи.';
	@override String get on => 'На';
	@override String get advancedSetup => 'App реєстрація';
	@override String get microsoftSignIn => 'Підписуйтесь з Microsoft';
	@override String get zoomIn => 'Зоо в';
	@override String get zoomOut => 'Зом вийде';
	@override String get fitPage => 'Файт сторінка';
	@override String get fitWidth => 'Ширина підходить';
	@override String get actualSize => 'Теперішній розмір';
	@override String get goToPage => 'Перейти на сторінку';
	@override String get goToSection => 'Перейти до розділу';
	@override String pageRange({required Object count}) => 'Введіть номер від 1 до ${count}';
	@override String get pageLayout => 'Page Layout';
	@override String get automatic => 'Автоматичний';
	@override String get singlePage => 'Єдиний сайт';
	@override String get twoPages => '2 Сторінки';
	@override String get readingDirection => 'Читання напрямків';
	@override String get leftToRight => 'Зліва направо';
	@override String get rightToLeft => 'Справа наліво';
	@override String get letterSpacing => 'Письмо простір';
	@override String get wordSpacing => 'Слово простір';
	@override String get readerControlsHelp => 'Щоб збільшити сторінку, розведіть два пальці або скористайтеся кнопками масштабування. Перетягуйте, щоб переміщувати сторінку. Ctrl/⌘ разом із + або − змінює масштаб; Ctrl/⌘ разом із 0 скидає його. Page Up і Page Down перегортають сторінки.';
	@override String get imagePage => 'Сторінка коміксу';
	@override String get resetReader => 'Перезавантаження переваг читання';
	@override String get zoom => 'Масштабувати';
	@override String get useFiles => 'Використовуйте файли та книги';
	@override String get cancelScan => 'Сканувати сканування';
	@override String get googleDrive => 'Google Drive';
	@override String get smbEndpointHint => 'Приклад: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Введіть сервер SMB та одну спільну папку.';
	@override String get smbFolderHelp => 'Залиште поле порожнім, щоб використовувати всю спільну папку, або вкажіть папку всередині неї.';
	@override String get smbDomain => 'Домен (необов’язково)';
	@override String get smbEncryption => 'Шифрувати з’єднання SMB3';
	@override String get smbEncryptionHint => 'Використовувати шифрування SMB3, якщо NAS його підтримує.';
}

// Path: lending
class _Translations$lending$uk extends Translations$lending$en {
	_Translations$lending$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'публічні бібліотеки';
	@override String get add => 'Додати бібліотеку';
	@override String get other => 'Інша бібліотека';
	@override String get libraryName => 'Назва бібліотеки';
	@override String get libraryUrl => 'Бібліотека сайт';
	@override String get libraryUrlHint => 'Скористайтеся каталогом бібліотеки або її сторінкою входу.';
	@override String get intro => 'Позичайте книги у своїй бібліотеці й тримайте їх поруч.';
	@override String get handoff => 'Увійдіть, позичайте книги й читайте безпечно через власний сервіс бібліотеки.';
	@override String get openService => 'Відкрита бібліотека';
	@override String get findLibrary => 'Знайдіть бібліотеку';
	@override String get search => 'Пошук книг та авторів';
	@override String get catalogue => 'каталог';
	@override String get loans => 'Позичені книги';
	@override String get holds => 'Бронювання';
	@override String get signIn => 'Підписуйтесь у Вашій бібліотеці';
	@override String get waiting => 'Завершити підписання в браузері, а потім повернутися сюди.';
	@override String get cancel => 'Скасувати';
	@override String get disconnect => 'Видалення бібліотеки';
	@override String get disconnectMessage => 'Вилучити цю бібліотеку з цього профілю? Ваші позичені книги та бронювання залишаться в бібліотеці.';
	@override String get getBook => 'Отримайте книгу';
	@override String get checkAvailability => 'Перевірка наявності';
	@override String get available => 'Доступно для позики';
	@override String get unavailable => 'В даний час недоступні';
	@override String get borrow => 'Позичити';
	@override String get placeHold => 'Забронювати';
	@override String get returnBook => 'Повернення рано';
	@override String get cancelHold => 'Скасувати бронювання';
	@override String get confirmBorrow => 'Ви можете замовити цю книжку у вашій бібліотеці?';
	@override String get confirmReturn => 'Ви можете повернути цей титул зараз? Ви можете замовити його знову, щоб продовжити.';
	@override String get confirmCancelHold => 'Скасувати бронювання цього видання?';
	@override String get email => 'Зберігайте повідомлення електронною поштою';
	@override String due({required Object date}) => 'Повернути до ${date}';
	@override String queue({required Object position}) => 'Позиція ${position} в лінії';
	@override String get empty => 'Тепер тут немає титулів.';
	@override String get openLibraryNote => 'Переглядайте каталог Open Library. Варіанти читання й позичання наведено на сторінці кожного видання.';
	@override String get more => 'Завантажити більше';
	@override String get gateway => 'Бібліотека підписується';
	@override String get gatewayHint => 'Пропонується вашою бібліотекою або адміністратором PlezyNG.';
	@override String get advanced => 'Бібліотека інтеграція';
	@override String get loadLibraries => 'Виберіть свою бібліотеку';
	@override String get expired => 'Термін користування цією книгою минув.';
	@override String get updated => 'Бібліотека оновлена';
	@override String get continueService => 'Продовжуйте службу';
	@override String get comingSoon => 'Заробітна плата в Україні · Приїжджає незабаром';
	@override String get comingSoonDescription => 'Ви можете використовувати свою бібліотеку в Libby, поки ми закінчимо підключення її.';
	@override String get suspendHold => 'Призупинити бронювання';
	@override String get resumeHold => 'Відновити бронювання';
	@override String get suspendMessage => 'Зберегти своє місце в черзі й дозволити наступному читачеві позичити цей примірник? Бронювання можна відновити пізніше.';
	@override String get resumeMessage => 'Відновити бронювання, щоб бібліотека могла запропонувати вам наступний доступний примірник?';
	@override String get editEmail => 'Зміни повідомлення електронної пошти';
}

// Path: audiobook
class _Translations$audiobook$uk extends Translations$audiobook$en {
	_Translations$audiobook$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Читання та слухання Sync';
	@override String get syncHelp => 'Зберігайте позиції читання, позиції слуху, стан завершення, знаки книг і записи на ваших пристроях. Виберіть прикріплений обліковий запис зберігання і використовуйте той же код синхронізації на кожному пристрої. Читання і слухання залишаються окремими.';
	@override String get addSyncSource => 'Перш за все, додайте Google Drive, OneDrive, Dropbox, WebDAV або S3 до файлів і книг.';
	@override String get syncDestination => 'Синхронізація облікового запису';
	@override String get syncFolder => 'Завантажити папку або префікс';
	@override String get syncFolderHelp => 'Використовуйте окрему існуючу папку в межах свого джерела WebDAV, або присвячений S3 заздалегідь.';
	@override String get syncCode => 'Приватний код синхронізації';
	@override String get syncCodeHelp => 'Створіть код на першому пристрої, а потім введіть цей код на інших пристроях. Зберігайте приватну копію: це ключ до вашого зашифрованого стану.';
	@override String get showCode => 'Показати або приховати код синхронізації';
	@override String get newSyncCode => 'Створення нового синхронізаційного коду';
	@override String get saveSync => 'Зберегти і синхронізувати';
	@override String get disableSync => 'Вимкніть синхронізацію на цьому пристрої';
	@override String get syncSourceDisconnect => 'Видалення цього джерела вимкне читання і слухання синхронізації тут. шифровані синхронізовані файли залишаться в провайдері.';
	@override String get syncReconnect => 'Відновлення облікового запису';
	@override String lastSynced({required Object time}) => 'Останній синхронізований на ${time}';
	@override String get syncPrivacy => 'Тільки зашифровані прогрес і записи зберігаються. аудіо- і електронні файли, токенів облікового запису та паролі не завантажуються. Google Drive і OneDrive використовують приклад зберігання; Dropbox використовує PlezyNG Sync. дозволяючи синхронування може вимагати додаткового письмового доступу. Хоча включено, ця дестинація володіє синхроном прогресу; прогрес сервера залишається окремим.';
	@override String get syncConflicts => 'Виберіть, де відновити';
	@override String get conflictHelp => 'Ці зміни були зроблені самостійно. виберіть позицію або версію знака, щоб зберегти. Пізній час або більш високий відсоток не автоматично виграє.';
	@override String syncDevice({required Object device}) => 'Створення ${device}';
	@override String get syncUnknownDevice => 'Невідомий пристрій';
	@override String get deletedBookmark => 'Усунути книжковий знак';
	@override String get finished => 'Завершено';
	@override String readingPosition({required Object percent}) => 'Читати · ${percent}%';
	@override String get chapterTimeline => 'Розділ Прогрес';
	@override String get bookTimeline => 'Книга Прогрес';
	@override String bookRemaining({required Object time}) => 'Залишився час в цій книзі: ${time}';
	@override String chapterRemaining({required Object time}) => 'Час, що залишився в цій главі: ${time}';
	@override String get unknownRemaining => 'Повний доступний час, коли граються частини';
	@override String get undoSeek => 'Останній пошук';
	@override String get customSpeed => 'Швидкість відтворення';
	@override String get speedHelp => 'Виберіть швидкість від 0,25× до 4×.';
	@override String get apply => 'Заявка';
	@override String get customSleep => 'Кваліфікований час сну';
	@override String get sleepMinutes => '1 хвилини (1 – 1440)';
	@override String sleepChapters({required Object count}) => 'Залишився після розділів ${count}';
	@override String get extendSleep => 'Додайте 5 хвилин';
	@override String sleepRemaining({required Object time}) => 'Тимпер сну: ${time}';
	@override String get useDefaults => 'Використовуйте ці контрольні системи для нових книг';
	@override String get librarySort => 'Сорт книг';
	@override String get sortTitle => 'Заголовок';
	@override String get sortAuthor => 'Автор';
	@override String get sortNarrator => 'Назавжди';
	@override String get sortSeries => 'Серія замовлення';
	@override String get sortRecent => 'Нещодавно відкрито';
	@override String get statusFilter => 'Статус читання';
	@override String get statusAll => 'Всі книги';
	@override String get statusNew => 'Не розпочато';
	@override String get statusProgress => 'в прогресі';
	@override String get statusFinished => 'Завершено';
	@override String get goToTime => 'Ідіть до часу';
	@override String get timeHelp => 'Час: хвилини: секунди або хвилини: секунди';
}

// Path: sourceSetup
class _Translations$sourceSetup$uk extends Translations$sourceSetup$en {
	_Translations$sourceSetup$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Збережений сертифікат сервера';
	@override String get nfsEndpointInvalid => 'Введіть URL NFS, наприклад nfs://nas:2049/export.';
	@override String get dlnaNone => 'Серверів DLNA не знайдено. Введіть URL опису пристрою вручну.';
	@override String get dlnaServers => 'Медіасервери DLNA';
	@override String get dlnaUnavailable => 'Виявлення DLNA недоступне в цій мережі. Введіть URL опису пристрою вручну.';
	@override String get dlnaSearching => 'Пошук серверів DLNA в локальній мережі';
	@override String get networkSearching => 'Пошук у локальній мережі…';
	@override String get dlnaDiscover => 'Знайти сервери DLNA';
	@override String get dlnaHelp => 'Виявлення залежить від багатоадресної розсилки в локальній мережі. Якщо сервер не з’являється, введіть вище URL опису його пристрою.';
	@override String get dlnaRoot => 'ID об’єкта DLNA; залиште порожнім, щоб використати корінь пристрою.';
	@override String get passwordOrKey => 'Введіть пароль або додайте приватний ключ нижче.';
	@override String get sshFingerprint => 'Відбиток SHA256 ключа хоста SSH';
	@override String get sshFingerprintHelp => 'Звірте його з адміністратором сервера. На сервері виконайте ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub і використайте значення SHA256.';
	@override String get sshFingerprintKeep => 'Залиште порожнім, щоб зберегти закріплений відбиток, або введіть новий відбиток сервера.';
	@override String get sshAuthentication => 'Автентифікація SSH за відкритим ключем';
	@override String get sshAuthenticationHelp => 'Необов’язково; автентифікація за паролем також підтримується.';
	@override String get privateKey => 'Приватний ключ (формат PEM або OpenSSH)';
	@override String get privateKeyPassphrase => 'Парольна фраза приватного ключа';
	@override String get nfsMountPort => 'TCP-порт служби монтування NFS';
	@override String get nfsMountPortHelp => 'Типово: 20048';
	@override String get nfsUserId => 'ID користувача NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Типово: 1000. Використайте ID, дозволений експортом NFS на NAS.';
	@override String get nfsGroupId => 'ID групи NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Типово: 1000. Використайте ID групи, дозволений експортом NFS на NAS.';
	@override String get nfsEncryption => 'Вимагати шифрування NFS (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Вимагати TLS 1.3 для NFS і служби монтування. Якщо NAS цього не підтримує, з’єднання буде відхилено.';
	@override String get nfsTrustCertificate => 'Власний CA NFS або сертифікат сервера (PEM, необов’язково)';
	@override String get nfsTrustHelp => 'Залиште порожнім для сертифікатів, яким довіряє цей пристрій. За потреби додайте сертифікат приватного CA або самопідписаний сертифікат сервера; імена в ньому мають відповідати хосту в URL NFS.';
	@override String get nfsTrustInvalid => 'Використайте сертифікат CA або сервера у форматі PEM. Не додавайте приватний ключ.';
	@override String get addTrustCertificate => 'Додати власний довірений сертифікат';
	@override String get replaceTrustCertificate => 'Замінити збережений власний сертифікат';
	@override String get nfsTlsHelp => 'RPC-with-TLS використовує звичайні порти NFS і служби монтування та потребує підтримки RFC 9289 на NAS. Потрібен TLS 1.3. Ім’я хоста або IP-адреса мають відповідати сертифікату. UID/GID AUTH_SYS і далі застосовуються в зашифрованому каналі.';
	@override String get clientCertificate => 'Сертифікат клієнта (необов’язково)';
	@override String get clientCertificateHelp => 'Дає змогу NAS автентифікувати цього клієнта; ID AUTH_SYS і далі залежать від правил експорту NFS на NAS.';
	@override String get savedIdentity => 'Буде використано збережені ідентифікаційні дані клієнта.';
	@override String get replaceIdentity => 'Замінити збережені ідентифікаційні дані клієнта';
	@override String get chooseIdentity => 'Вибрати ідентифікаційні дані клієнта PKCS#12';
	@override String get identityPassphrase => 'Парольна фраза ідентифікаційних даних клієнта';
	@override String get identityPassphraseHelp => 'Залиште порожнім, якщо файл не має парольної фрази.';
	@override String get removeIdentity => 'Вилучити збережені ідентифікаційні дані клієнта';
	@override String get identityStorageHelp => 'Ідентифікаційні дані клієнта зберігаються в зашифрованому сховищі облікових даних джерела. Не змінюйте цей розділ, щоб зберегти наявні ідентифікаційні дані.';
	@override String get nfsLimitations => 'NFSv3 через TCP, лише читання. Без RPC-with-TLS трафік NFS не шифрується. NAS має дозволяти вибрані ID AUTH_SYS і непривілейовані порти клієнта (часто це параметр експорту «insecure»). NFSv4 та UDP не підтримуються.';
	@override String get nfsSetupHelp => 'Довідка з налаштування NFS';
	@override String get nfsSetupHint => 'Перевірте ці налаштування, якщо з’єднання не встановлюється.';
	@override String get nfsSetupDetails => 'Використайте експорт NFSv3 через TCP. Якщо потрібне шифрування, і служба NFS, і служба монтування мають підтримувати RPC-with-TLS. Залиште власний сертифікат порожнім для сертифіката сервера, якому довіряє цей пристрій, або додайте сертифікат CA NAS чи самопідписаний сертифікат. Ім’я в сертифікаті має відповідати хосту кінцевої точки. Якщо NAS вимагає взаємної автентифікації TLS, додайте його ідентифікаційні дані клієнта PKCS#12. Насамкінець переконайтеся, що експорт дозволяє налаштовані UID/GID AUTH_SYS і правила портів клієнта.';
	@override String get ftpHelp => 'FTP використовує пасивний режим. Використовуйте ftp:// для FTP без шифрування, ftpes:// для явного TLS або ftps:// для TLS (неявного на порту 990; явного на інших портах).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Необов’язковий пошук субтитрів для окремих відео.';
	@override String get apiKey => 'Ключ API';
	@override String get optionalUsername => 'Ім’я користувача облікового запису (необов’язково)';
	@override String get optionalPassword => 'Пароль облікового запису (необов’язково)';
	@override String get subtitlePrivacy => 'Отримайте ключ API на opensubtitles.com. Пошук надсилає назву відео й доступні ID IMDb/TMDB, але ніколи не надсилає відеофайл. Ключ і необов’язкові облікові дані шифруються разом із цим джерелом.';
	@override String get automaticMetadata => 'Автоматичні метадані відео з інтернету';
	@override String get metadataPrivacy => 'Надсилає лише назву/рік з імені файлу та номери епізодів або ID NFO, але ніколи не надсилає медіафайли чи облікові дані. Поля NFO зберігають пріоритет.';
	@override String get nfsEncryptionFailure => 'Для зашифрованого NFS перевірте підтримку RFC 9289 і TLS 1.3 обома службами NAS, ім’я в сертифікаті та UID/GID експорту. PlezyNG не повторюватиме це з’єднання без шифрування.';
	@override String get sourceConnecting => 'Підключення до джерела';
	@override String get metadataSearchPrivacy => 'Цей пошук назви надсилається до Trakt. Передається введена назва, а не відео чи облікові дані джерела.';
	@override String get chooseMatch => 'Вибрати збіг';
	@override String get metadataMatchHelp => 'Перед вибором перевірте назву й рік. Trakt отримує пошукову назву; відео залишається у своєму джерелі.';
	@override String get metadataNoMatches => 'Відповідних назв в інтернеті не знайдено. Спробуйте іншу назву.';
	@override String get metadataSearch => 'Пошук метаданих в інтернеті';
	@override String get metadataLoading => 'Пошук відомостей про фільми й серіали в інтернеті…';
	@override String get metadataFromTrakt => 'Метадані з Trakt';
	@override String get metadataNoAutomaticMatch => 'Автоматичного збігу назви не знайдено. Знайдіть назву, щоб вибрати збіг.';
	@override String get metadataFailed => 'Не вдалося завантажити метадані з інтернету. Відтворення та локальні відомості залишаються доступними.';
	@override String get videoDetailsLoading => 'Завантаження відомостей про відео';
	@override String get subtitleKeyRequired => 'Потрібен ключ API OpenSubtitles';
	@override String get subtitleKeyHelp => 'Змініть це файлове джерело й додайте ключ API OpenSubtitles у необов’язкових налаштуваннях субтитрів.';
	@override String get subtitleSearchFailed => 'Пошук субтитрів не вдався. Перевірте ключ API, з’єднання й доступ до сервісу.';
	@override String get subtitleApplyFailed => 'Не вдалося завантажити або застосувати ці субтитри. Перевірте з’єднання й спробуйте інший результат.';
	@override String get subtitleSearch => 'Пошук в OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'Пошук використовує назву й доступні ID IMDb/TMDB. Відеофайл залишається у своєму джерелі. Перед вибором перевірте мову, позначки примусових субтитрів або субтитрів для людей із порушеннями слуху та оцінку.';
	@override String get movieOrShow => 'Фільм або серіал';
	@override String get subtitleTitleHint => 'Введіть назву, щоб уточнити результати';
	@override String get subtitleLanguage => 'Мова субтитрів';
	@override String get subtitleSearching => 'Пошук в OpenSubtitles';
	@override String get subtitleNoMatches => 'Відповідних субтитрів не знайдено. Спробуйте іншу назву або мову.';
	@override String get downloadSubtitle => 'Завантажити субтитри';
	@override String get subtitle => 'Субтитри';
	@override String get nfsTlsRequired => 'Потрібен RPC-with-TLS';
	@override String get nfsUnencrypted => 'NFS без шифрування';
	@override String get tlsEncrypted => 'Шифрування TLS';
	@override String get ftpPlain => 'FTP без шифрування';
	@override String get sshPinned => 'SSH із шифруванням · ключ хоста закріплено';
	@override String get smbEncrypted => 'Шифрування SMB3 увімкнено';
	@override String get smbUnencrypted => 'Шифрування SMB3 вимкнено';
	@override String get httpUnencrypted => 'HTTP без шифрування транспорту';
	@override String get checkEndpointSecurity => 'Перевірити безпеку кінцевої точки';
	@override String fieldRequired({required Object label}) => 'Обов’язкове поле: ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Для поля «${label}» введіть значення від ${min} до ${max}.';
	@override String replaceFile({required Object name}) => 'Замінити ${name}';
	@override String selectedIdentity({required Object name}) => 'Вибрані ідентифікаційні дані клієнта: ${name}';
	@override String subtitleRating({required Object rating}) => 'Оцінка ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Завантаження субтитрів: ${title}';
}

// Path: comics
class _Translations$comics$uk extends Translations$comics$en {
	_Translations$comics$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'За висотою';
	@override String get readingMode => 'Режим читання';
	@override String get paged => 'Сторінки';
	@override String get webtoon => 'Безперервне прокручування';
	@override String get coverAlone => 'Показувати обкладинку окремо';
	@override String get splitWide => 'Розділяти широкі сторінки';
	@override String get splitWideHelp => 'Показувати кожну половину окремо в порядку читання. Поки цю опцію ввімкнено, сторінки не відображаються парами.';
	@override String get thumbnails => 'Мініатюри сторінок';
	@override String get controlsHelp => 'Проведіть, щоб перегорнути сторінку. Подвійне торкання змінює припасування розміру. При безперервному прокручуванні проводьте вертикально або використовуйте Page Up і Page Down.';
	@override String get savedForComic => 'Налаштування відображення зберігаються для цього коміксу в цьому профілі.';
	@override String get readLists => 'Списки читання';
	@override String get collections => 'Колекції';
}

// Path: games
class _Translations$games$uk extends Translations$games$en {
	_Translations$games$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

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
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
	@override String get steamLibraryHint => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.';
}

// Path: appIcon.names
class _Translations$appIcon$names$uk extends Translations$appIcon$names$en {
	_Translations$appIcon$names$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Місяць';
	@override String get ember => 'Чоловік';
	@override String get paper => 'папір';
	@override String get oled => 'OLED';
	@override String get line => 'Лінія';
	@override String get ocean => 'Океан';
	@override String get ultraviolet => 'Ультрафіолетові';
	@override String get matcha => 'Матч';
	@override String get sunset => 'Сонце';
	@override String get gold => 'Золото';
	@override String get titanium => 'Титан';
	@override String get glass => 'Склянка';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Сінтеграція';
	@override String get pixel => 'Піксель';
	@override String get neon => 'Нейон';
	@override String get sticker => 'Стикер';
	@override String get ticket => 'Квитки';
	@override String get pop => 'Поп';
	@override String get strata => 'Страта';
	@override String get facet => 'обличчя';
	@override String get tilde => 'Тіллі';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$uk extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

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
class _Translations$common$mediaKind$uk extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Фільми';
	@override String get show => 'показ';
	@override String get season => 'Сезон';
	@override String get episode => 'Епізод';
	@override String get artist => 'Виконавець';
	@override String get album => 'Альбом';
	@override String get track => 'Трек';
	@override String get collection => 'Колекція';
	@override String get playlist => 'Плейлист';
	@override String get clip => 'Кліп';
	@override String get photo => 'Фото';
	@override String get folder => 'Тека';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$uk extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get bg => 'фонтани';
	@override String get surface => 'поверхня';
	@override String get outline => 'Офіційний';
	@override String get text => 'Текст';
	@override String get textMuted => 'Вторинний текст';
	@override String get accent => 'акцент';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$uk extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Текст на фоні';
	@override String get textOnSurface => 'Текст на поверхні';
	@override String get textMutedOnBg => 'Вторинний текст на фоні';
	@override String get textMutedOnSurface => 'Вторинний текст на поверхні';
	@override String get accentOnBg => 'Акцент на фоні';
	@override String get accentOnSurface => 'акцент на поверхні';
	@override String get labelOnAccent => 'Кнопка на акценті';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$uk extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Ігри / Пауза';
	@override String get volumeUp => 'ВВП ВВП';
	@override String get volumeDown => 'Розмір Down';
	@override String seekForward({required Object seconds}) => 'Пошук вперед (${seconds})';
	@override String seekBackward({required Object seconds}) => 'Пошук назад (${seconds} с)';
	@override String get fullscreenToggle => 'Повний екран';
	@override String get muteToggle => 'Спілкуйтеся з мутом';
	@override String get subtitleToggle => 'Підвищення субтитри';
	@override String get audioTrackNext => 'Наступна стаття Audio Track';
	@override String get subtitleTrackNext => 'Наступна статтяПерші підручники';
	@override String get chapterNext => 'Наступна сцена';
	@override String get chapterPrevious => 'Попередня сцена';
	@override String get episodeNext => 'Наступний епізод';
	@override String get episodePrevious => 'Попередній епізод';
	@override String get speedIncrease => 'Збільшення швидкості';
	@override String get speedDecrease => 'Зниження швидкості';
	@override String get speedReset => 'Швидкість відновлення';
	@override String get zoomIn => 'Зом в';
	@override String get zoomOut => 'Зоум виходить';
	@override String get zoomReset => 'Реабілітація Zoom';
	@override String get subSeekNext => 'Пошук наступного субтитра';
	@override String get subSeekPrev => 'Пошук попереднього субтитра';
	@override String get subtitleDelayIncrease => 'Затримка субтитри';
	@override String get subtitleDelayDecrease => 'Наступні субтитри';
	@override String get shaderToggle => 'Співвідношення стін';
	@override String get skipMarker => 'Кредит / Кредит';
	@override String get screenshot => 'Створення Screenshot';
	@override String get framePrevious => 'Попередня рамка';
	@override String get frameNext => 'Наступна рамка';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$uk extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Потрібні Android 8.0 або новіше';
	@override String get iosVersion => 'Потрібні iOS 15.0 або новіше';
	@override String get permissionDisabled => 'Image-in-image вимкнений.Відключити його в системних налаштуваннях.';
	@override String get notSupported => 'Пристрій не підтримує режим зображення в зображенні';
	@override String get voSwitchFailed => 'Не вдалося перетворити вихід відео на зображення-в-фото';
	@override String get failed => 'Фото-ін-фото не вдалося почати';
	@override String get prepareFailed => 'Зображення в картинці не можна було підготувати';
	@override String unknown({required Object error}) => 'Повідомляється про помилку: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$uk extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Аудіо та субтитри';
	@override String get libraryDisplay => 'Медіатека';
	@override String get personalMedia => 'Персональні медіа';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$uk extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get none => 'Ручно вибрані';
	@override String get noneDescription => 'Ніколи не перетворюйте субтитри самостійно.';
	@override String get defaultMode => 'Слідкуйте за флагами';
	@override String get defaultModeDescription => 'Використовуйте стандартні та примусові прапори, що зберігаються на кожному підзаголовному трасі.';
	@override String get always => 'Завжди дозволяється';
	@override String get alwaysDescription => 'Натисніть на підзаголовок в улюбленому мові, коли він існує.';
	@override String get onlyForced => 'Тільки примусові субтитри';
	@override String get onlyForcedDescription => 'Завантажуйте тільки смуги, зазначені як примусові.';
	@override String get smart => 'Завантажити аудіо з іноземним';
	@override String get smartDescription => 'Зверніть субтитри тільки тоді, коли аудіо знаходиться на іншому мові.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$uk extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Попередня статтяКто чего не любить SDH';
	@override String get preferSdh => 'Популярні SDH субтитри';
	@override String get onlySdh => 'Тільки субтитри SDH';
	@override String get onlyNonSdh => 'Тільки не-SDH субтитри';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$uk extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Потрібні непідвищені субтитри';
	@override String get preferForced => 'Потрібні підзаголовки';
	@override String get onlyForced => 'Тільки примусові субтитри';
	@override String get onlyNonForced => 'Тільки безпідставні субтитри';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$uk extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get none => 'Ніколи';
	@override String get moviesAndShows => 'Фільми та телевізійні шоу';
	@override String get movies => 'Тільки фільми';
	@override String get shows => 'Телевізійні шоу тільки';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$uk extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Користувачі та критики';
	@override String get usersOnly => 'Користувачі тільки';
	@override String get criticsOnly => 'Тільки критики';
	@override String get nobody => 'Схована';
}

// Path: discover.findNext
class _Translations$discover$findNext$uk extends Translations$discover$findNext$en {
	_Translations$discover$findNext$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Що обрати далі?';
	@override String get open => 'Що обрати далі?';
	@override String get anyTime => 'Без обмеження часу';
	@override String get timeAvailable => 'Скільки у вас часу?';
	@override String get filters => 'Оберіть щось для цієї миті';
	@override String get watch => 'Дивитися';
	@override String get listen => 'Слухати';
	@override String get read => 'Читати';
	@override String finishable({required Object duration}) => 'Час до завершення: ${duration}';
	@override String aboutDuration({required Object duration}) => 'Орієнтовна тривалість: ${duration}';
	@override String nextUnit({required Object duration}) => 'Наступний розділ · ${duration}';
	@override String totalDuration({required Object duration}) => 'Загалом ${duration}';
	@override String get timingVaries => 'Тривалість може відрізнятися';
	@override String get notNow => 'Не зараз';
	@override String get swipeHint => 'Змахніть обкладинку в бік стрілки або скористайтеся кнопками нижче.';
	@override String get saved => 'Збережені рекомендації';
	@override String savedCount({required Object count}) => 'Збережені рекомендації · ${count}';
	@override String get undo => 'Скасувати дію';
	@override String get details => 'Докладніше';
	@override String get noPicks => 'Поки немає з чого вибирати';
	@override String get noPicksHint => 'Під’єднайте бібліотеку або додайте джерело медіа, щоб почати.';
	@override String get noMatches => 'Нічого підхожого для цієї миті';
	@override String get noMatchesHint => 'Спробуйте інший вид медіа або виділіть більше часу.';
	@override String get allDone => 'Ви переглянули всі рекомендації';
	@override String get allDoneHint => 'Створіть нову добірку, щоб знову побачити ці варіанти.';
	@override String get refresh => 'Знайти іншу добірку';
	@override String sourceReason({required Object source}) => 'Джерело: ${source}';
	@override String libraryReason({required Object library}) => 'Бібліотека: ${library}';
	@override String get ownedReason => 'З вашої бібліотеки';
	@override String get liveNow => 'Зараз в ефірі';
	@override String get watchLive => 'Дивитися наживо';
	@override String get filterAnything => 'Будь-який вид';
	@override String get filterWatch => 'Дивитися';
	@override String get filterListen => 'Слухати';
	@override String get filterRead => 'Читати';
	@override String get twentyMinutes => '20 хв';
	@override String get fortyFiveMinutes => '45 хв';
	@override String get ninetyMinutes => '90 хв';
	@override String get apply => 'Застосувати';
	@override String get openFailed => 'Цей варіант більше недоступний. Оновіть, щоб перевірити ще раз.';
	@override String get changeFailed => 'Не вдалося зберегти зміну. Спробуйте ще раз.';
	@override String get savedLimit => 'Список збережених рекомендацій заповнений. Вилучіть одну рекомендацію, щоб зберегти іншу.';
	@override String get chooseHint => 'Відкрийте твір, збережіть на потім або пропустіть.';
	@override String get howItWorks => 'Як це працює';
	@override String get notNowHelp => 'Пропустіть цей твір наразі. Він залишиться у вашій бібліотеці.';
	@override String get saveHelp => 'Додайте його до збережених добірок цього профілю на цьому пристрої. Збереження не завантажує твір.';
	@override String get openHelp => 'Виберіть обкладинку для перегляду подробиць. Основна кнопка дає змогу відтворити, читати або відкрити твір.';
	@override String get controlsHelp => 'Клавіатура або пульт: виберіть кнопку й натисніть Enter або кнопку вибору. Скасування відновлює останній вибір.';
	@override String get artworkLoading => 'Завантаження обкладинки…';
	@override String get artworkUnavailable => 'Обкладинка недоступна';
	@override String get savedFeedback => 'Додано до збережених добірок';
	@override String get skippedFeedback => 'Наразі пропущено';
	@override String get releaseToConfirm => 'Відпустіть для підтвердження';
	@override String get remoteHint => 'Фокус на обкладинці: ← / → вибір · Кнопка вибору: подробиці · ↑ / ↓ переміщення фокусу';
}

// Path: discover.person
class _Translations$discover$person$uk extends Translations$discover$person$en {
	_Translations$discover$person$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get born => 'народжується';
	@override String get died => 'Смерть';
	@override String get birthplace => 'Місце народження';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (старість ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (старість ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$uk extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Рекомендовані';
	@override String get browse => 'Огляд';
	@override String get collections => 'Колекції';
	@override String get playlists => 'Плейлисти';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$uk extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Груповання';
	@override String get all => 'Всі';
	@override String get movies => 'Фільми';
	@override String get shows => 'Серіали';
	@override String get seasons => 'Сезони';
	@override String get episodes => 'Епізоди';
	@override String get artists => 'Виконавці';
	@override String get albums => 'Альбоми';
	@override String get tracks => 'Доріжки';
	@override String get folders => 'Теки';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$uk extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Жанр';
	@override String get year => 'Рік';
	@override String get contentRating => 'Рейтинг контенту';
	@override String get tag => 'Тег';
	@override String get unwatched => 'Неоцінений';
	@override String get unplayed => 'Непрогране';
	@override String get favorites => 'Обрані';
	@override String get filePath => 'Файловий шлях';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$uk extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Назва';
	@override String get dateAdded => 'Дата додавання';
	@override String get releaseDate => 'Дата випуску';
	@override String get rating => 'Рейтинг';
	@override String get communityRating => 'Рейтинг спільноти';
	@override String get criticRating => 'Критичний рейтинг';
	@override String get userRating => 'Користувач рейтингу';
	@override String get datePlayed => 'Дата відтворення';
	@override String get playCount => 'Кількість відтворень';
	@override String get productionYear => 'Рік виробництва';
	@override String get runtime => 'Тривалість';
	@override String get officialRating => 'Офіційний рейтинг';
	@override String get premiereDate => 'Дата прем’єри';
	@override String get startDate => 'Початок дати';
	@override String get airTime => 'Час етеру';
	@override String get studio => 'Студія';
	@override String get random => 'Випадковий';
	@override String get dateShared => 'Дата поділяється';
	@override String get latestEpisodeAirDate => 'Останній епізод Air Date';
	@override String get lastEpisodeDateAdded => 'Останній епізод Дата Додано';
	@override String get dateDownloaded => 'Дата завантаження';
	@override String get size => 'Розмір';
	@override String get library => 'Медіатека';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$uk extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get include => 'Включити';
	@override String get exclude => 'Виключити';
	@override String get any => 'будь-який';
	@override String get yes => 'Так';
	@override String get no => 'Ні';
	@override String not({required Object value}) => 'не ${value}';
	@override String valueCount({required Object count}) => '${count} вибрано';
	@override String valueCountExcluded({required Object count}) => '${count} виключено';
	@override String get searchValues => 'Пошукові цінності';
	@override String get noValues => 'Немає цінностей';
	@override String get matchContains => 'контейнери';
	@override String get matchNotContains => 'Не містить';
	@override String get matchIs => 'І є';
	@override String get matchIsNot => 'Не є';
	@override String get matchBeginsWith => 'Починається з';
	@override String get matchEndsWith => 'Закінчується з';
	@override String get textHint => 'Тип до матчу';
	@override String get from => 'від';
	@override String get to => 'до';
	@override String range({required Object from, required Object to}) => '${from} до ${to}';
	@override String atLeast({required Object value}) => '${value} і вище';
	@override String atMost({required Object value}) => 'До ${value}';
	@override String dateLastDays({required Object count}) => 'Останні ${count} днів';
	@override String get dateLastYear => 'минулого року';
	@override String dateOlderThanDays({required Object count}) => 'Вік понад ${count} днів';
	@override String get dateOlderThanYear => 'старше 1 року';
}

// Path: libraries.selection
class _Translations$libraries$selection$uk extends Translations$libraries$selection$en {
	_Translations$libraries$selection$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Вибір предметів';
	@override String selectedCount({required Object count}) => '${count} вибрано';
	@override String get actions => 'Акції вибору';
	@override String get confirmDescendants => 'Це змінює всі епізоди у вибраних виставках і сезонах.';
	@override String get confirmUnwatched => 'Це також очищає прогрес відтворення для вибраних елементів.';
	@override String confirmCount({required Object count}) => 'Вибрані пункти: ${count}.';
	@override String completed({required Object count}) => 'Оновлені пункти: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Оновлено ${succeeded}; не вдалося ${failed}. Не вдалося залишити вибір.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$uk extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Управління розшуком шахів';
	@override String get manageDescription => 'Виберіть та організовуйте списки з вашого облікового запису MDBList';
	@override String get description => 'Виберіть публічні фільми та телевізійні списки з вашого облікового запису MDBList. створити або копіювати списки на MDBList, а потім оновити.';
	@override String get selected => 'Вибрані стільці';
	@override String get available => 'Список доступних рахунків';
	@override String get noLists => 'Немає публічних фільмів або телевізійних списків повернуто. Створіть або копіюйте список на MDBList, а потім оновлюйте.';
	@override String get displayName => 'Шелф показує ім\'я';
	@override String get nameHint => 'Залишити білий, щоб використовувати назву джерело списку.';
	@override String get add => 'Додайте шаф';
	@override String get save => 'Зберегти шахи';
	@override String moveUp({required Object title}) => 'Повернутись ${title}';
	@override String moveDown({required Object title}) => 'Повернутись ${title} вниз';
	@override String get unavailable => 'Цей список недоступний. Витягніть або видаліть його шаф в налаштуваннях.';
	@override String get rateLimited => 'MDBList Заявка ліміт досягнута. будь ласка, відкликайте пізніше.';
	@override String get loadFailed => 'Не можна завантажувати шари. перевірте зв\'язок і відкликайте.';
	@override String get saveFailed => 'Я не можу врятувати стільці, будь ласка, відмовляйтеся.';
	@override String get accountChanged => 'Профіль або обліковий запис змінилися. знову відкрити ці налаштування.';
	@override String get settingsUnreadable => 'Збережені шари не можуть бути прочитані. Виберіть списки знову, щоб замінити ці налаштування.';
}

// Path: explore.rows
class _Translations$explore$rows$uk extends Translations$explore$rows$en {
	_Translations$explore$rows$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Застереження';
	@override String get recommendedMovies => 'Рекомендовані фільми';
	@override String get recommendedShows => 'Рекомендовані покази';
	@override String get trendingMovies => 'Трендовий фільм';
	@override String get trendingShows => 'Трендовий показ';
	@override String get popularMovies => 'Популярні фільми';
	@override String get popularShows => 'Популярні шоу';
	@override String get trendingAnime => 'Трендовий аніме';
	@override String get suggestedAnime => 'Пропонований аніме';
	@override String get airingAnime => 'Анімаційний анімаційний';
	@override String get popularAnime => 'Найпопулярніші аніме';
	@override String get trending => 'Тенденції';
	@override String get upcomingMovies => 'Наступні фільми';
	@override String get upcomingShows => 'Наступні покази';
}

// Path: explore.status
class _Translations$explore$status$uk extends Translations$explore$status$en {
	_Translations$explore$status$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Авіація';
	@override String get ended => 'Завершено';
	@override String get canceled => 'скасовано';
	@override String get upcoming => 'Скоро';
}

// Path: explore.badge
class _Translations$explore$badge$uk extends Translations$explore$badge$en {
	_Translations$explore$badge$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} Популярні';
	@override String rankAiring({required Object n}) => 'В ефірі: №${n}';
	@override String rankRated({required Object n}) => '#${n} переглянуто';
	@override String rankTrending({required Object n}) => '#${n} Трендінг';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} в ${season}';
	@override String watchingNow({required Object n}) => '${n} переглядів';
	@override String get available => 'Доступно';
	@override String get partiallyAvailable => 'Частково доступні';
	@override String get availableIn4k => '4K доступні';
	@override String get requested => 'Запрошені';
	@override String get pendingApproval => 'Залишається затвердження';
	@override String get processing => 'обробка';
	@override String get declined => 'Декілька';
	@override String get requestFailed => 'Заява провалилася';
	@override String get requested4k => 'Запрошуємо 4K';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} сезони';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Епізод ${episode} в ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Наступна стаття ${duration}';
	@override String episodesShort({required Object n}) => '${n} Епс';
	@override String minutesPerEpisode({required Object n}) => '${n} хв/п';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$uk extends Translations$explore$stats$en {
	_Translations$explore$stats$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} перераховано';
	@override String viewersDay({required Object n}) => 'Переглянули сьогодні: ${n}';
	@override String viewersWeek({required Object n}) => 'Переглянули цього тижня: ${n}';
	@override String viewersMonth({required Object n}) => 'Переглянули цього місяця: ${n}';
	@override String viewersYear({required Object n}) => '${n} переглядів цього року';
	@override String viewersAllTime({required Object n}) => 'Глядачів: ${n}';
	@override String planning({required Object n}) => '${n} Планується переглянути';
	@override String favorited({required Object n}) => '${n} улюблених';
	@override String dropRate({required Object percent}) => '${percent} відмінили його';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментар',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментарі',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментарів',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментарі',
	);
	@override String votes({required Object n}) => '${n} голосів';
	@override String watching({required Object n}) => '${n} переглянути';
	@override String completed({required Object n}) => '${n} Завершено';
	@override String onHold({required Object n}) => '${n} на зберігання';
	@override String dropped({required Object n}) => '${n} вилучено';
}

// Path: explore.season
class _Translations$explore$season$uk extends Translations$explore$season$en {
	_Translations$explore$season$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Зимовий';
	@override String get spring => 'Весна';
	@override String get summer => 'Літо';
	@override String get fall => 'Падіння';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$uk extends Translations$explore$format$en {
	_Translations$explore$format$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get tv => 'ТБ';
	@override String get tvShort => 'Телевізор короткий';
	@override String get movie => 'Фільми';
	@override String get special => 'Особливості';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Музика';
	@override String get other => 'Інше';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$uk extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get original => 'Оригінальна';
	@override String get manga => 'Манга';
	@override String get lightNovel => 'Світло роман';
	@override String get novel => 'Роман';
	@override String get visualNovel => 'Візуальний роман';
	@override String get game => 'Ігри';
	@override String get webComic => 'WEB Комедія';
	@override String get musicRelease => 'Музика';
	@override String get otherMedia => 'Інше';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$uk extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Актор';
	@override String get director => 'Режисер';
	@override String get writer => 'Сценарист';
	@override String get producer => 'Продюсер';
	@override String get creator => 'Творець';
	@override String get composer => 'Композитор';
}

// Path: explore.relation
class _Translations$explore$relation$uk extends Translations$explore$relation$en {
	_Translations$explore$relation$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Прокляття';
	@override String get sequel => 'Секель';
	@override String get sideStory => 'Побічна історія';
	@override String get spinOff => 'Спін-офф';
	@override String get alternativeVersion => 'Альтернативна версія';
	@override String get summary => 'резюме';
	@override String get parentStory => 'Історія батьків';
	@override String get adaptation => 'адаптація';
	@override String get other => 'пов\'язані';
}

// Path: explore.detail
class _Translations$explore$detail$uk extends Translations$explore$detail$en {
	_Translations$explore$detail$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Оригінальний заголовок';
	@override String get alsoKnownAs => 'Також відомий як';
	@override String get studios => 'Студії';
	@override String get country => 'країна';
	@override String get language => 'Мова';
	@override String get released => 'звільнений';
	@override String get physicalRelease => 'На дисковому';
	@override String get ended => 'Завершено';
	@override String addedOn({required Object date}) => 'Додано ${date}';
	@override String get yourRating => 'Ваш рейтинг';
	@override String get budget => 'Бюджет';
	@override String get revenue => 'Букш офіс';
	@override String get contentAdvisory => 'Вік керівництва';
	@override String get tags => 'Мітки';
	@override String get revealSpoilerTags => 'Завантажити Spoiler Tags';
	@override String get links => 'Ліва';
	@override String get watchOn => 'Дивіться на';
	@override String get watchTrailer => 'Дивитись трейлер';
	@override String openOn({required Object site}) => 'Відкритий на ${site}';
	@override String get crew => 'Екіпаж';
	@override String get ratings => 'Рейтинг';
	@override String get schedule => 'Розклад';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n,
		one: 'Рекомендується користувачем ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
		other: 'Рекомендують користувачі: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
	);
	@override String recommendedBy({required Object who}) => 'Рекомендується ${who}';
	@override String favoritedBy({required Object who}) => 'Офіційно ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} не опубліковано';
	@override String recommendedByPercent({required Object percent}) => 'Рекомендується ${percent} відвідувачів';
	@override String get relatedTitles => 'Співвідношення титулів';
	@override String get background => 'фонтани';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$uk extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Починати рано (за секунду)';
	@override String get endLate => 'Запізнюється час (за секунду)';
	@override String get newOnly => 'Тільки нові епізоди';
	@override String get anyChannel => 'Запис на будь-якому каналі';
	@override String get anyTime => 'Рекорд у будь-який час';
	@override String get skipInLibrary => 'Скіп епізодів вже в бібліотеці';
	@override String get keepUpTo => 'Епізоди, які потрібно зберігати';
	@override String get keepUpToHint => '0 зберігає кожен епізод';
}

// Path: music.discography
class _Translations$music$discography$uk extends Translations$music$discography$en {
	_Translations$music$discography$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Епізоди та ЕП';
	@override String get live => 'Наживо';
	@override String get compilations => 'Компіляції';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$uk extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} перекладено';
	@override String get playbackStarted => 'Початок Playback';
	@override String paused({required Object name}) => '${name} перерва';
	@override String get playbackPaused => 'Плейбак зупинився';
	@override String jumpedTo({required Object name, required Object position}) => '${name} стрибнув до ${position}';
	@override String roomJumpedTo({required Object position}) => 'Завантажити ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} встановлює швидкість до ${speed}';
	@override String speedChanged({required Object speed}) => 'Швидкість встановлена до ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} почався ${title}';
	@override String mediaStarted({required Object title}) => 'Зараз грати ${title}';
	@override String stoppedMedia({required Object name}) => '${name} зупинив відео';
	@override String get mediaStopped => 'Відео зупинилося';
	@override String waitingFor({required Object name}) => 'Залишився на ${name}...';
	@override String get waitingForSomeone => 'Очікуючи, що хтось захопить...';
	@override String get finished => 'Завершено';
	@override String hostChangedTo({required Object name}) => '${name} тепер є гостем';
	@override String get youAreNowHost => 'Тепер ви – гость';
	@override String joined({required Object name}) => '${name} приєдналися';
	@override String left({required Object name}) => '${name} залишити';
	@override String get controlRefused => 'Тільки хостинг може контролювати відтворення';
	@override String get searchFailed => 'Деякі сервери не могли шукати відео в кімнаті';
	@override String get playBlocked => 'Прес-ігри для початку';
	@override String get shareFailed => 'Я не можу поділитися цим відео з кімнатою';
	@override String get downloadNotShared => 'Завантаження не поділяються з кімнатою, поки їх сервер офлайн';
	@override String get openFailed => 'Не можна було відкрити відео в кімнаті';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$uk extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Гостьовий закінчив кімнату';
	@override String get kicked => 'Ви були вилучені з кімнати.';
	@override String get expired => 'Кімната закінчилася';
	@override String get replaced => 'Ви приєдналися до цієї кімнати на іншому пристрої';
	@override String get lost => 'Втратив зв\'язок з кімнатою';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$uk extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Коди мають 6 букв і цифр, без 0, 1, I, L або O.';
	@override String get roomNotFound => 'У нього немає такого коду, він може закінчитися.';
	@override String get roomFull => 'Ця кімната повна.';
	@override String get roomLocked => 'Гость закрив цю кімнату.';
	@override String get relayFull => 'Подивитися разом зайнято зараз. спробуйте знову пізніше.';
	@override String get unreachable => 'Я не можу досягти годинника спільно передати. перевірте зв\'язок.';
	@override String get rateLimited => 'Занадто багато спроб. Чекайте хвилину і спробуйте знову.';
	@override String get clientBlocked => 'Ця версія PlezyNG не може використовувати релей.';
	@override String get forbidden => 'Це може зробити тільки гость.';
	@override String get notInRoom => 'Ви не в кімнаті.';
	@override String get alreadyInRoom => 'Ви вже в кімнаті.';
	@override String get resumeFailed => 'Я не міг прийти до кімнати.';
	@override String get unsupported => 'Релей не підтримує це.';
	@override String get generic => 'Щось не так, спробуйте ще раз.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$uk extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Завантаження зупиняться, коли ви покинете додаток';
	@override String get bannerDegraded => 'Завантаження на фоні можуть бути обмежені';
	@override String get bannerAction => 'Детальніше';
	@override String get sheetTitle => 'Завантаження фонові завантаження блокуються';
	@override String get sheetTitleDegraded => 'Завантаження на фоні можуть бути обмежені';
	@override String get sheetIntro => 'Android перешкоджає PlezyNG від завантаження надійно в фоні.';
	@override String get sheetIntroDegraded => 'Ваш пристрій обмежує, коли PlezyNG можна завантажити в фоні.';
	@override String get reasonBackgroundRestricted => 'Використання фону PlezyNG обмежено. налаштуйте його батарею або фонові використання на "Не обмежено".';
	@override String get reasonStandbyRestricted => 'Android встановив PlezyNG в обмеженому стані. встановити його використання акумулятора на "Не обмежено".';
	@override String get reasonDownloadChannelBlocked => 'Повідомлення про завантаження вимкнені, тому прогрес і контроль можуть бути недоступними.';
	@override String get reasonNotificationsDisabled => 'На Android 13 або новіше, вони потрібні для довгих завантажень фону.';
	@override String get reasonDataSaver => 'Data Saver є на, який блокує задні завантаження на мобільних даних. Завантаження повинні все ще працювати на Wi-Fi.';
	@override String get reasonOemUnknown => 'Завантаження неодноразово зупинялися, коли PlezyNG був на фоні. перевірте налаштування батареї або використання фону PlezyNG.';
	@override String get openSettings => 'Відкриті налаштування';
	@override String get stillNotWorking => 'Спеціальна допомога пристрою';
	@override String get stillNotWorkingDescription => 'Переглянути кроки для вашого пристрою, або надіслати запис з Налаштування › Переглянути записи, якщо проблема продовжується.';
	@override String get dialogTitle => 'Завантаження можуть не закінчитися';
	@override String get dialogDownloadAnyway => 'Завантажити в будь-якому';
	@override String get dialogFixFirst => 'Перш за все вирішити це';
	@override String get statusTile => 'Завантажити Background';
	@override String get statusOk => 'Дозволяється виходити на фоні';
	@override String get statusBlocked => 'Заблоковані системними установками';
	@override String get statusDegraded => 'Ограничений системою налаштування';
	@override String get statusUnknown => 'Досі не перевірено';
	@override String get settingsUnavailable => 'Не можна було відкрити системні налаштування на цьому пристрої';
	@override String get linkUnavailable => 'Не можна було відкрити dontkillmyapp.com на цьому пристрої';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$uk extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get library => 'Медіатека';
	@override String get collections => 'Колекції';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$uk extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Розпочато віддалений сервер.';
	@override String get hostAddress => 'Адреса гостя';
	@override String get connected => 'Зв\'язані';
	@override String get serverRunning => 'Віддалений сервер активний';
	@override String get serverStopped => 'Віддалений сервер зупинився';
	@override String get serverRunningDescription => 'Мобільні пристрої на вашій мережі можуть підключитися до цієї програми';
	@override String get serverStoppedDescription => 'Запустіть сервер, щоб дозволити мобільним пристроям підключитися';
	@override String get usePhoneToControl => 'Використовуйте свій мобільний пристрій для контролю за цією програмою';
	@override String get startServer => 'Початок сервера';
	@override String get stopServer => 'Залишити сервер';
	@override String get minimize => 'мінімізація';
	@override String get manualAddressHint => 'Адреса ручного зв\'язку:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$uk extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Пристрої PlezyNG з тим же аккаунтом Plex з\'являються тут';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Зв’язок...';
	@override String get searchingForDevices => 'Пошук пристроїв...';
	@override String get noDevicesFound => 'Не знайдено пристроїв у мережі';
	@override String get noDevicesHint => 'Відкрийте PlezyNG на робочому столі і використовуйте той же Wi-Fi';
	@override String get availableDevices => 'Доступні пристрої';
	@override String get manualConnection => 'Ручне підключення';
	@override String get cryptoInitFailed => 'Зареєструйтесь на номер Plex.';
	@override String get validationHostRequired => 'Будь ласка, введіть адресу гостя';
	@override String get validationHostFormat => 'Формат повинен бути IP:port (наприклад, 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Використовуйте одну і ту ж мережу на обох пристроях.';
	@override String get sessionNotFound => 'Пристрій не знайдено. переконайтеся, що PlezyNG працює на хості.';
	@override String get authFailed => 'Обидва пристрої потребують одного і того ж облікового запису Plex.';
	@override String failedToConnect({required Object error}) => 'Не вдалося підключитися: ${error}';
	@override String get codeTitle => 'Кодекс пара';
	@override String get codeDescription => 'Введіть код, що відображається в розділі Companion Remote, на пристрої-хостингу. обидва пристрої повинні використовувати версію, яка підтримує безпечне підключення.';
	@override String get codeInvalid => 'Введіть всі 32 букви та цифри з хостингового коду.';
	@override String get updateRequired => 'Оновлення обох пристроїв до версії, яка підтримує безпечне підключення.';
	@override String get hostDescription => 'Введіть цей код один раз на кожному віддаленому. Зберігайте його приватним: він надає контроль над цим профілем.';
	@override String get resetCode => 'Відновлення парового коду';
	@override String get resetDescription => 'Відключіть всі відстані і створюйте новий код. Кожен відстані потребує знову пара.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$uk extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Ви хочете відключити від дистанційної сесії?';
	@override String get reconnecting => 'Відновлення...';
	@override String attemptOf({required Object current}) => 'Пошук ${current} з 5';
	@override String get retryNow => 'Повернутись зараз';
	@override String get tabRemote => 'Віддалені';
	@override String get tabPlay => 'Грати';
	@override String get tabMore => 'Більше';
	@override String get menu => 'Меню';
	@override String get tabNavigation => 'Таб навігації';
	@override String get tabDiscover => 'Відкриття';
	@override String get tabLibraries => 'Медіатеки';
	@override String get tabSearch => 'Пошук';
	@override String get tabDownloads => 'Завантаження';
	@override String get tabSettings => 'Налаштування';
	@override String get previous => 'Назад';
	@override String get playPause => 'Ігри / Пауза';
	@override String get next => 'Вперед';
	@override String get seekBack => 'Пошук назад';
	@override String get stop => 'Зупинити';
	@override String get seekForward => 'Пошук FWD';
	@override String get volume => 'обсяг';
	@override String get volumeDown => 'Вниз';
	@override String get volumeUp => 'Вгору';
	@override String get fullscreen => 'Повноекранний режим';
	@override String get subtitles => 'Субтитри';
	@override String get audio => 'Аудіо';
	@override String get searchHint => 'Пошук на робочому місці...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$uk extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Інтерфейс мережі не знайдено';
	@override String get authenticationFailed => 'аутентифікація провалилася';
	@override String serverStartFailed({required Object error}) => 'Не вдалося запустити віддалений сервер: ${error}';
	@override String commandFailed({required Object error}) => 'Не вдалося відправити дистанційну команду: ${error}';
	@override String get joinTimedOut => 'Час приєднатися до сесії';
	@override String get failedToConnectAnyAddress => 'Не вдалося підключитися до будь-якої адреси';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Втрата зв\'язку після ${attempts} спроб';
	@override String get connectionLost => 'Загублений зв\'язок';
}

// Path: services.names
class _Translations$services$names$uk extends Translations$services$names$en {
	_Translations$services$names$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$uk extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Повторний зв\'язок Simkl';
	@override String get subtitle => 'Simkl припиняє підтримку способу входу, який використовує це підключення. Повторне підключення відкриє simkl.com для надання дозволу PlezyNG — PlezyNG ніколи не бачить ваш пароль. Історія переглядів залишиться на Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$uk extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Завантажити PlezyNG на ${service}';
	@override String get instructions => 'Скануйте QR-код або відвідайте нижче наведену адресу та введіть цей код:';
	@override String openToActivate({required Object service}) => 'Відкрийте ${service} для активування';
	@override String get copyCode => 'Копіювати код активізації';
	@override String get waitingForAuthorization => 'Чекаємо на дозвіл...';
	@override String get codeCopied => 'Код копіюється';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$uk extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Зареєструйтесь на номер ${service}';
	@override String get body => 'Скануйте цей QR-код або відкрийте URL на будь-якому пристрої.';
	@override String openToSignIn({required Object service}) => 'Відкрийте ${service} для реєстрації';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$uk extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Завантажити URL-адрес';
	@override String get urlCopied => 'URL копіюється';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$uk extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$uk._(TranslationsUk root) : this._root = root, super.internal(root);

	final TranslationsUk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Бібліотека Фільтр';
	@override String get subtitleAllSyncing => 'Сінціонувати всі бібліотеки';
	@override String get subtitleNoneSyncing => 'Нічого не синхронізує';
	@override String subtitleBlocked({required Object count}) => '${count} заблоковано';
	@override String subtitleAllowed({required Object count}) => '${count} дозволено';
	@override String get mode => 'Фільтр режиму';
	@override String get modeBlacklist => 'Чорний список';
	@override String get modeWhitelist => 'Білий список';
	@override String get modeHintBlacklist => 'Синхронізуйте кожну бібліотеку за винятком тих, які переглядаються нижче.';
	@override String get modeHintWhitelist => 'Синхронізуйте тільки бібліотеки, які перевіряються нижче.';
	@override String get libraries => 'Медіатеки';
	@override String get noLibraries => 'Бібліотеки немає';
}

/// The flat map containing all translations for locale <uk>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsUk {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'Транслювати на пристрій',
			'cast.searching' => 'Пошук пристроїв для вишивки...',
			'cast.connectedTo' => ({required Object device}) => 'Підключений до ${device}',
			'cast.device' => 'Пристрій для трансляції',
			'cast.readyToCast' => 'Готово до трансляції',
			'cast.subtitle' => 'Субтитри',
			'cast.serverNotAvailable' => 'Медіа-сервер не доступний.',
			'cast.stopCasting' => 'Зупинити трансляцію',
			'cast.castToDevice' => 'Транслювати на пристрій',
			'cast.noEpisodeAvailable' => 'Епізоду не можна випустити.',
			'cast.startFailed' => 'Не можна почати кастинг. перевірте сервер і спробуйте знову.',
			'automation.noActivePlayback' => 'Не існує активної відеосесії для контролю.',
			'automation.profileNotFound' => 'Профіль Plezy не знайдено.',
			'notifications.newEpisodeTitle' => 'Новий епізод',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'Ікони App',
			'appIcon.defaultIcon' => 'За замовчуванням',
			'appIcon.current' => 'Теперішня ікона',
			'appIcon.locked' => 'Доступ до життєдіяльності необхідний',
			'appIcon.lockedHint' => 'Запустіть 7-денний тест або розблокуйте PlezyNG протягом усього життя, щоб використовувати альтернативні ікони.',
			'appIcon.changeFailed' => 'Я не зміню ікону додатку',
			'appIcon.launcherHint' => 'Нова ікона з\'являється на домашньому екрані після того, як ви залишите PlezyNG.',
			'appIcon.tvLauncherHint' => 'Новий банер з\'являється, як тільки ви залишите PlezyNG. Android TV може продовжувати показувати старий до відновлення телевізора.',
			'appIcon.names.midnight' => 'Місяць',
			'appIcon.names.ember' => 'Чоловік',
			'appIcon.names.paper' => 'папір',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Лінія',
			'appIcon.names.ocean' => 'Океан',
			'appIcon.names.ultraviolet' => 'Ультрафіолетові',
			'appIcon.names.matcha' => 'Матч',
			'appIcon.names.sunset' => 'Сонце',
			'appIcon.names.gold' => 'Золото',
			'appIcon.names.titanium' => 'Титан',
			'appIcon.names.glass' => 'Склянка',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Сінтеграція',
			'appIcon.names.pixel' => 'Піксель',
			'appIcon.names.neon' => 'Нейон',
			'appIcon.names.sticker' => 'Стикер',
			'appIcon.names.ticket' => 'Квитки',
			'appIcon.names.pop' => 'Поп',
			'appIcon.names.strata' => 'Страта',
			'appIcon.names.facet' => 'обличчя',
			'appIcon.names.tilde' => 'Тіллі',
			'auth.signInWithPlex' => 'Зареєструйтесь за адресою Plex',
			'auth.showQRCode' => 'Показати QR код',
			'auth.authenticate' => 'автентичні',
			'auth.authenticationTimeout' => 'Офіційна аутентифікація закінчилася, будь ласка, спробуйте знову.',
			'auth.scanQRToSignIn' => 'Сканувати цей QR-код для підписання',
			'auth.waitingForAuth' => 'Чекаючи на аутентифікацію... Зареєструйтесь з браузера.',
			'auth.useBrowser' => 'Використання браузера',
			'auth.or' => 'або',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Підключення до ${product}',
			'auth.quickConnect' => 'Швидке підключення',
			'auth.useQuickConnect' => 'Використати Quick Connect',
			'auth.quickConnectInstructions' => 'Відкрийте Quick Connect в Jellyfin і введіть цей код.',
			'auth.quickConnectWaiting' => 'Чекаємо на затвердження...',
			'auth.quickConnectCancel' => 'Скасувати',
			'auth.quickConnectExpired' => 'Термін дії швидкого підключення минув. Спробуйте ще раз.',
			'auth.localDataRecoveryRequired' => 'PlezyNG не вдалося безпечно відновити локальні дані входу та дані відтворення, що очікують обробки. Увійдіть знову.',
			'auth.pinCheckRejected' => 'Кінцевий код PIN Plex відхилено',
			'auth.connectToDirectPlex' => 'Підключення до локального сервера Plex',
			'common.cancel' => 'Скасувати',
			'common.save' => 'Зберегти',
			'common.close' => 'Закрити',
			'common.clear' => 'чітко',
			'common.reset' => 'Скинути',
			'common.later' => 'Пізніше',
			'common.submit' => 'Підтвердити',
			'common.confirm' => 'підтверджує',
			'common.retry' => 'Повторити',
			'common.logout' => 'Зареєструйтеся',
			'common.unknown' => 'Невідоме',
			'common.refresh' => 'Оновити',
			'common.yes' => 'Так',
			'common.no' => 'Ні',
			'common.delete' => 'Видалити',
			'common.edit' => 'Редагувати',
			'common.shuffle' => 'Перемішати',
			'common.addTo' => 'Додайте до...',
			'common.createNew' => 'Створення Новий',
			'common.connect' => 'Підключитись',
			'common.disconnect' => 'Від’єднатися',
			'common.play' => 'Грати',
			'common.pause' => 'Пауза',
			'common.resume' => 'Продовжити',
			'common.error' => 'Помилка',
			'common.search' => 'Пошук',
			'common.home' => 'Головна',
			'common.back' => 'Назад',
			'common.settings' => 'Налаштування',
			'common.mute' => 'Заглушити',
			'common.ok' => 'ОК',
			'common.off' => 'Вимкнути',
			'common.options' => 'варіанти',
			'common.seasonNumber' => ({required Object number}) => 'Сезон ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Епізод ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Розділ ${number}',
			'common.reconnect' => 'Відновлення',
			'common.viewAll' => 'Переглянути всі',
			'common.checkingNetwork' => 'Перевірка мережі...',
			'common.loadingServers' => 'Завантаження серверів...',
			'common.connectingToServers' => 'Підключення до серверів...',
			'common.startingOfflineMode' => 'Починаючи з офлайн-моду',
			'common.loading' => 'Завантажити...',
			'common.fullscreen' => 'Повноекранний режим',
			'common.exitFullscreen' => 'Повний екран виходу',
			'common.pressBackAgainToExit' => 'Натисніть знову на вихід',
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
			'common.notAvailable' => 'Н / А',
			'common.url' => 'URL',
			'common.letterKeys' => 'АБС',
			'common.mediaKind.movie' => 'Фільми',
			'common.mediaKind.show' => 'показ',
			'common.mediaKind.season' => 'Сезон',
			'common.mediaKind.episode' => 'Епізод',
			'common.mediaKind.artist' => 'Виконавець',
			'common.mediaKind.album' => 'Альбом',
			'common.mediaKind.track' => 'Трек',
			'common.mediaKind.collection' => 'Колекція',
			'common.mediaKind.playlist' => 'Плейлист',
			'common.mediaKind.clip' => 'Кліп',
			'common.mediaKind.photo' => 'Фото',
			'common.mediaKind.folder' => 'Тека',
			'screens.licenses' => 'ліцензії',
			'screens.switchProfile' => 'Профіль перемикача',
			'screens.subtitleStyling' => 'Стилізація субтитрів',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Журнали',
			'update.available' => 'Оновлення доступне',
			'update.versionAvailable' => ({required Object version}) => 'Версія ${version} доступна',
			'update.currentVersion' => ({required Object version}) => 'Теперішній номер: ${version}',
			'update.skipVersion' => 'Скачати цю версію',
			'update.viewRelease' => 'Переглянути випуск',
			'update.latestVersion' => 'Ви знаходитесь в останній версії',
			'update.checkFailed' => 'Не вдалося перевірити оновлення',
			'appAccess.title' => 'Спробуйте будь-яку функцію безкоштовно протягом 7 днів',
			'appAccess.description' => 'Почніть семиденний випробування з повним доступом до кожної функції PlezyNG. під час випробування немає оплати і без підписки. Після випробування один життєвий купівля за ціною вашого магазину відкриває PlezyNG на життя.',
			'appAccess.trialEndedDescription' => 'Відключити кожну функцію в PlezyNG на життя з одним покупкою за ціною вашого магазину.',
			'appAccess.startTrial' => 'Початок мого 7-денного безкоштовного випробування',
			'appAccess.trialActive' => 'Ваш 7-денний повний тест функції активний.',
			'appAccess.trialEnded' => 'Сім днів судового розгляду закінчилися',
			'appAccess.trialStartFailed' => 'Я не можу врятувати випробування на цьому пристрої. будь ласка, спробуйте знову.',
			'appAccess.lifetimeTitle' => 'PlezyNG відключено на життя',
			'appAccess.lifetimeBody' => 'Ви маєте доступу до кожної функції PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG Доступ до життя',
			'appAccess.manageDescription' => 'Спробуйте кожну функцію безкоштовно протягом 7 днів, а потім розблокуйте все на життя з однією оплатою за ціною вашого магазину.',
			'appAccess.buy' => ({required Object price}) => 'Відключити кожну функцію для ${price}',
			'appAccess.loadingPrice' => 'Вартість магазину ...',
			'appAccess.retryPrice' => 'Повернення ціни Lookup',
			'appAccess.restore' => 'Відновлення життєвого купівлі',
			'appAccess.pending' => 'Ваш покупка чекає на оплату або затвердження. Доступ до життєвого часу відкривається, як тільки магазин завершить його.',
			'appAccess.storeUnavailable' => 'Переконайтеся, що ви підписуєтеся в магазин, а покупки дозволені на цьому пристрої.',
			'appAccess.productNotFound' => 'PlezyNG життєвий відключення ще не доступно в цьому магазині.',
			'appAccess.productQueryFailed' => 'Ціна магазину не може бути завантажена. перевірте зв\'язок і спробуйте знову.',
			'appAccess.purchaseFailed' => 'Купівля не пройшла. спробуйте знову.',
			'appAccess.restoreFailed' => 'Я не міг би дістатися до магазину, щоб відновити вашу покупку. спробуйте знову.',
			'appAccess.nothingToRestore' => 'Номер PlezyNG життєвий купівля був знайдений для цього облікового запису магазину.',
			'settings.title' => 'Налаштування',
			'settings.supportDeveloper' => 'Підтримка PlezyNG',
			'settings.supportDeveloperDescription' => 'Донорство на підтримку розвитку',
			'settings.lifetimeAccess' => 'PlezyNG Доступ до життя',
			'settings.language' => 'Мова',
			'settings.theme' => 'Тема',
			'settings.appearance' => 'Поява',
			'settings.detailPage' => 'Детальна сторінка',
			'settings.themeSongsEnabled' => 'Грати в тематичні пісні',
			'settings.themeSongsEnabledDescription' => 'Грати на доступні тематичні пісні під час перегляду медіа-деталі.',
			'settings.themeSongVolume' => 'ТОВАРИСТВО З ОБМЕЖЕНОЮ ВІДПОВІДАЛЬНІСТЮ',
			'settings.videoPlayback' => 'Відео Playback',
			'settings.videoPlaybackDescription' => 'Налаштування поведінки Playback',
			'settings.advanced' => 'Розширені',
			'settings.episodePosterMode' => 'Стиль епізоду',
			'settings.seriesPoster' => 'Серія Постер',
			'settings.seasonPoster' => 'Сезонний плакат',
			'settings.episodeThumbnail' => 'Тюмен',
			'settings.showHeroSectionDescription' => 'Дисплей з контентом карусель на домашньому екрані',
			'settings.secondsLabel' => 'секунди',
			'settings.minutesLabel' => 'хвилин',
			'settings.secondsShort' => 'С',
			'settings.minutesShort' => 'М',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Введіть значення (${min}-${max})',
			'settings.systemTheme' => 'Система',
			'settings.lightTheme' => 'світло',
			'settings.darkTheme' => 'Темний',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Чоловік',
			'settings.glacierTheme' => 'Льодовик',
			'settings.forestTheme' => 'ліс',
			'settings.plumTheme' => 'Плюм',
			'settings.paperTheme' => 'папір',
			'settings.libraryDensity' => 'Бібліотечна щільність',
			'settings.displayScale' => 'Дисплей масштаби',
			'settings.compact' => 'компактний',
			'settings.comfortable' => 'зручність',
			'settings.gridSpacing' => 'Стіл-простір',
			'settings.gridSpacingTight' => 'Тетяни',
			'settings.gridSpacingNormal' => 'Звичайний',
			'settings.gridSpacingSpacious' => 'Простір',
			'settings.tvCornerSpotlightBackdrop' => 'Створення Spotlight Backdrop',
			'settings.tvCornerSpotlightBackdropDescription' => 'Показати художню твір в правому верхньому куті замість заповнення екрану',
			'settings.viewMode' => 'Погляд на моду',
			'settings.gridView' => 'мережа',
			'settings.listView' => 'Список',
			'settings.showHeroSection' => 'Показати розділ Героя',
			'settings.showHomeBackdrop' => 'Показати будинок Backdrop Artwork',
			'settings.showHomeBackdropDescription' => 'Показати великі твори мистецтва за прикладом Домашніх рядків',
			'settings.contentScreensaverEnabled' => 'Скриншоти контенту',
			'settings.contentScreensaverEnabledDescription' => 'Показати повний екран художньої роботи після того, як додаток був ідл',
			'settings.contentScreensaverDelay' => 'Завантажити екран після',
			'settings.contentScreensaverLibraries' => 'Бібліотека Screensaver',
			'settings.contentScreensaverLibrariesDescription' => 'Виберіть, які бібліотеки надають екран-захист художньої роботи. якщо жодного не вибрано, художній твір з усіх бібліотек використовується.',
			'settings.contentScreensaverAllLibraries' => 'Всі медіатеки',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} вибраних бібліотек',
			'settings.contentScreensaverNoLibraries' => 'Бібліотеки з підключеними медіа не доступні.',
			'settings.contentScreensaverDismissHint' => 'Натисніть будь-який кнопка або натисніть, щоб відмовитися',
			'settings.newEpisodeNotifications' => 'Новий епізод повідомлень',
			'settings.newEpisodeNotificationsDescription' => 'Попередження, коли до шоу додається новий епізод, ви застрягли. перевіряти, поки відкритий Plezy.',
			'settings.continueWatchingRowSize' => 'Продовжуйте спостерігати за розміром ряду',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} картки',
			'settings.rowSizeCompact' => 'компактний',
			'settings.rowSizeStandard' => 'Стандартний',
			'settings.rowSizeLarge' => 'Більший',
			'settings.continueWatchingAction' => 'Продовжуйте спостерігати за діяльністю',
			'settings.continueWatchingPlay' => 'Грати',
			'settings.continueWatchingDetails' => 'Відкриті деталі',
			'settings.episodeAction' => 'Епізод дії',
			'settings.episodePlay' => 'Грати',
			'settings.episodeDetails' => 'Відкриті деталі',
			'settings.useGlobalHubs' => 'Використовуйте Home Layout',
			'settings.useGlobalHubsDescription' => 'Показати об\'єднані будинкові центри. в іншому випадку використовуйте рекомендації бібліотеки.',
			'settings.showServerNameOnHubs' => 'Показати назву сервера на Hubs',
			'settings.showServerNameOnHubsDescription' => 'Завжди показуйте імена серверів в заголовках hub.',
			'settings.groupLibrariesByServer' => 'Групові бібліотеки за сервером',
			'settings.groupLibrariesByServerDescription' => 'Бібліотеки групової сторінки під кожним медіа-сервером.',
			'settings.alwaysKeepSidebarOpen' => 'Завжди тримайте стіни відкритими',
			'settings.alwaysKeepSidebarOpenDescription' => 'Базовий бар залишається розширеним, а вміст-об\'єкт адаптується до',
			'settings.showUnwatchedCount' => 'Показати невідомий номер',
			'settings.showUnwatchedCountDescription' => 'Дивитись непереглянутий епізод рахувати на шоу і сезони',
			'settings.showWatchedIndicators' => 'Показати переглянуті показники',
			'settings.showWatchedIndicatorsDescription' => 'Показати перевірку на переглянутих фільмах, шоу і епізодах',
			'settings.showEpisodeNumberOnCards' => 'Показати номер епізоду на картах',
			'settings.showEpisodeNumberOnCardsDescription' => 'Показати сезон і номер епізоду на епізодних картах',
			'settings.showSeasonPostersOnTabs' => 'Показати сезонні плакати на таблицях',
			'settings.showSeasonPostersOnTabsDescription' => 'Показати плакат кожного сезону над його клавішкою',
			'settings.tvFullCardLayout' => 'Повний телеканал',
			'settings.tvFullCardLayoutDescription' => 'Використовуйте тільки телевізійні картки з іменами акторів',
			'settings.focusGlow' => 'Фокус Глоу',
			'settings.focusGlowDescription' => 'Натисніть м\'який світло навколо зосередженої картки',
			'settings.visualEffects' => 'Візуальні ефекти',
			'settings.visualEffectsAuto' => 'Авто',
			'settings.visualEffectsAutoDescription' => 'Автоматично зменшується вплив на пристрої з низькою потужністю',
			'settings.visualEffectsFull' => 'Повний',
			'settings.visualEffectsReduced' => 'Зниження',
			'settings.visualEffectsReducedDescription' => 'Менше анімацій і низькорозв\'язаних творів мистецтва',
			'settings.hideSpoilers' => 'Сховання споюлерів для невідомих епізодів',
			'settings.hideSpoilersDescription' => 'Блур тюменні і описи для несподіваних епізодів',
			'settings.playerBackend' => 'Гравець Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Декодування харчового обладнання',
			'settings.hardwareDecodingDescription' => 'Використовуйте прискорення харчових пристроїв, коли вони доступні',
			'settings.playbackBuffer' => 'Завантажити Playback Buffer',
			'settings.playbackBufferAuto' => 'Автомобіль (загальна кількість автомобілів)',
			'settings.playbackBufferLarge' => 'Більший',
			'settings.playbackBufferExtraLarge' => 'Дуже великий',
			'settings.playbackBufferDescription' => 'Баффер більше проти нестабільних зв\'язків. також обмежений розміром Баффер.',
			'settings.streamBufferSize' => 'Буффер розмір',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} Мб',
			'settings.streamBufferSizeDescription' => 'Скільки відео потрібно завантажувати, коли грати безпосередньо. транскоди зупиняються на власному транскоді сервера. 0 = Авто',
			'settings.streamBufferSizeExoNote' => 'Замінює Playback Buffer при налаштуванні, закріплений на половині межі пам\'яті програми',
			'settings.streamBufferMegabytes' => 'Мегабайт',
			'settings.defaultQualityTitle' => 'дефектна якість',
			'settings.cellularQualityTitle' => 'Дефіцитна якість на клітині',
			'settings.remoteQualityTitle' => 'Кваліфікація віддаленого потоку',
			'settings.remoteQualitySameAsDefault' => 'Як і стандартна якість',
			'settings.cellularQualitySameAsDefault' => 'Як і стандартна якість',
			'settings.directPlayCoveredQuality' => 'Переглянути відео в оригінальній якості',
			'settings.directPlayCoveredQualityDescription' => 'Пряма відтворення відео вже в межах межі якості замість перекодування',
			'settings.videoCodecs' => 'Кодекс відео',
			'settings.videoCodecsDescription' => 'Неперевірені кодек перешифруються сервером',
			'settings.videoCodecsAlwaysAccepted' => 'Завжди прийнято',
			'settings.musicQualityTitle' => 'Якість музики',
			'settings.subtitleStyling' => 'Стилізація субтитрів',
			'settings.subtitleStylingDescription' => 'Підвищення субтитра вигляду',
			'settings.smallSkipDuration' => 'Маленький Скіп Тривалість',
			'settings.largeSkipDuration' => 'Довжина великого стрибка',
			'settings.rewindOnResume' => 'Повернення на резюме',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунда', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунди', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунд', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} секунди', ), 
			'settings.defaultSleepTimer' => 'Заборонений час сну',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилина', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилини', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилин', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} хвилини', ), 
			'settings.rememberTrackSelections' => 'Зауважимо, що вибір трак за шоу/фільм',
			'settings.chooseTracksBeforePlayback' => 'Виберіть аудіо та субтитри перед відтворенням',
			'settings.chooseTracksBeforePlaybackDescription' => 'Виберіть джерело аудіо і субтитри, перш ніж починається кожен відео.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Завжди показуйте субтитри на цьому пристрої',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Коли сервер не має підзаголовок, виберіть траку локально.Це ніколи не змінює переваги сервера.',
			'settings.autoDownloadPreferredSubtitle' => 'Фетч відсутній улюблений субтитри мови',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Виберіть доступний субтитр у вашому улюбленому мові локально. якщо жодного немає, попросіть сервера завантажити один, коли підтримується.',
			'settings.rememberTrackSelectionsDescription' => 'Зберігати аудіо і субтитри виборів шоу або фільму на цьому пристрої',
			'settings.rememberTrackSelectionsBackendRule' => 'Працює локально з Plex, Jellyfin, і Emby; Plex і Jellyfin також може зберегти вибір на сервері',
			'settings.followServerTrackSelections' => 'Використовуйте серверні відгуки за епізодом',
			'settings.followServerTrackSelectionsDescription' => 'При зміні епізоду застосовуйте аудіо та підзаголовки, вибрані на сервері, а не переносять поточний вибір.',
			'settings.resumeMusicOnLaunch' => 'Згадаймо музичну сесію',
			'settings.resumeMusicOnLaunchDescription' => 'Відкрити останню пісню зупинився, де вона залишилася, коли програма стартує',
			'settings.showChapterMarkersOnTimeline' => 'Показати розділ знаків на пошуковій смузі',
			'settings.showChapterMarkersOnTimelineDescription' => 'Секмент пошукової смуги на межі розділу',
			'settings.specialsOrdering' => 'Особливості в порядку епізоду',
			'settings.specialsOrderingDescription' => 'Де спеціальні грають в порядку годинника шоу',
			'settings.specialsOrderingServer' => 'Слідкуйте за замовленням сервера',
			'settings.specialsOrderingAirDate' => 'Повітряна дата перевезення',
			'settings.specialsOrderingLast' => 'Після регулярних сезонів',
			'settings.clickVideoTogglesPlayback' => 'Натисніть на відео, щоб зіграти / перервати',
			'settings.clickVideoTogglesPlaybackDescription' => 'Натисніть на відео, щоб грати / перервати замість того, щоб показати контроль.',
			'settings.videoPlayerControls' => 'Контроль відеоплеєра',
			'settings.keyboardShortcuts' => 'Ключові короткострокові',
			'settings.keyboardShortcutsDescription' => 'Налаштування клавіатурних скорочень',
			'settings.videoPlayerNavigation' => 'Відеопередач навігація',
			'settings.videoPlayerNavigationDescription' => 'Використовуйте ключі стрілки для навігації контролів відеоплеєра',
			'settings.watchTogetherRelay' => 'Дивіться реліз',
			'settings.watchTogetherRelayDescription' => 'Відкрита партія розповсюджується, якщо ви не встановили власний',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Введіть дійсну базову URL-адресу ретранслятора з HTTP або HTTPS.',
			'settings.crashReporting' => 'Звіт про катастрофу',
			'settings.crashReportingDescription' => 'Надіслати повідомлення про аварії, щоб допомогти поліпшити додаток',
			'settings.debugLogging' => 'Дебютний логінг',
			'settings.debugLoggingDescription' => 'Дозволяється детальний логінг для вирішення проблем',
			'settings.viewLogs' => 'Переглянути логіки',
			'settings.viewLogsDescription' => 'Переглянути логотипи',
			'settings.clearImageCache' => 'Чистий зображення Cache',
			'settings.clearImageCacheDescription' => 'Зображення можуть завантажуватися повільніше, поки не завантажуються знову.',
			'settings.clearImageCacheSuccess' => 'Зображення каше успішно очищено',
			'settings.resetSettings' => 'Реабілітація налаштувань',
			'settings.resetSettingsDescription' => 'Відновлення стандартних налаштувань.Це не може бути недійсним.',
			'settings.resetSettingsSuccess' => 'Перезавантаження успішно',
			'settings.backup' => 'Резервна копія',
			'settings.exportSettings' => 'Експортні налаштування',
			'settings.exportSettingsDescription' => 'Зберегти свої переваги до файлу',
			'settings.exportSettingsSuccess' => 'Налаштування експортуються',
			'settings.importSettings' => 'Ввезення налаштувань',
			'settings.importSettingsDescription' => 'Відновлення переваг з файлу',
			'settings.importSettingsConfirm' => 'Це замінить ваші поточні налаштування.',
			'settings.importSettingsSuccess' => 'Ввезені налаштування',
			'settings.importSettingsInvalidFile' => 'Цей файл не є дійсним експортом PlezyNG налаштувань',
			'settings.importSettingsNoUser' => 'Зареєструйтесь перед імпортуванням',
			'settings.cloudBackup' => 'Створення Cloud Backup',
			'settings.cloudBackupDescription' => 'Збережіть резервну копію переносних налаштувань за адресою WebDAV через HTTPS. Підключення до серверів і дані входу залишаться на цьому пристрої.',
			'settings.cloudBackupUrl' => 'WebDAV URL файлу JSON',
			'settings.cloudBackupUsername' => 'Ім’я користувача',
			'settings.cloudBackupPassword' => 'Пароль',
			'settings.cloudBackupSaved' => 'Облачна резервна резервна дестинація збережена',
			'settings.cloudBackupNow' => 'Повернутись зараз',
			'settings.cloudBackupComplete' => 'Завантажити Backup',
			'settings.cloudBackupRestore' => 'Відновлення резервного коду',
			'settings.cloudBackupRestoreConfirm' => 'Це замінить відповідні портативні налаштування на цьому пристрої.',
			'settings.cloudBackupRestored' => 'Налаштування відновлено з облачної резервної копії',
			'settings.shortcutsReset' => 'Швидкість відновлення до дефолтів',
			'settings.resetShortcutsConfirm' => 'Це замінить ваші пристосовані скорочення дефолтами.',
			'settings.about' => 'Про',
			'settings.aboutDescription' => 'Інформація та ліцензії',
			'settings.updates' => 'Оновлення',
			'settings.updateAvailable' => 'Оновлення доступне',
			'settings.checkForUpdates' => 'Перевірте оновлення',
			'settings.autoCheckUpdatesOnStartup' => 'Автоматично перевіряти оновлення на стартапі',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Повідомлення про те, коли оновлення буде доступно на запуску',
			'settings.validationErrorEnterNumber' => 'Будь ласка, введіть діюче число',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Вона повинна бути між ${min} і ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Швидкість, яка вже присвоєна ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Про це повідомляється в повідомленні ${action}',
			'settings.saveFailed' => 'Зміни не можна врятувати, спробуйте знову.',
			'settings.autoPlayAndSkip' => 'Автомобільні і скачальні',
			'settings.autoPlayNextEpisode' => 'Автомобільні перегляди наступного епізоду',
			'settings.autoPlayNextEpisodeDescription' => 'Почнемо наступний епізод автоматично, коли закінчується',
			'settings.shuffleStartsFromBeginning' => 'Шуффлі починається з самого початку',
			'settings.shuffleStartsFromBeginningDescription' => 'Почніть кожен епізод з самого початку, коли занурюється, а не повторюється',
			'settings.plexCinemaPreRoll' => 'Використання серверного кіноінтросу',
			'settings.plexCinemaPreRollDescription' => 'Грати в конфігуровані Plex попередні ролі або Jellyfin і Emby входи перед початком фільму.',
			'settings.playNextCountdown' => 'Завантажити Next Countdown',
			'settings.playNextCountdownImmediate' => 'Грати негайно',
			'settings.skipIntroMode' => 'Скіп Інтро',
			'settings.skipIntroModeOffDescription' => 'Грати в інтроси нормально без кнопки скачування',
			'settings.skipIntroModeButtonDescription' => 'Показати кнопку скип, коли стартує вхід',
			'settings.skipIntroModeAutoDescription' => 'Автоматично відправляйте вхід після затримки нижче',
			'settings.skipCreditsMode' => 'Кредити Скіп',
			'settings.skipCreditsModeOffDescription' => 'Грати кредити зазвичай без кнопки скип',
			'settings.skipCreditsModeButtonDescription' => 'Показати кнопку скип, коли починаються кредити',
			'settings.skipCreditsModeAutoDescription' => 'Скачати кредити автоматично і грати в наступний епізод',
			'settings.skipAdsMode' => 'Скачати рекламу',
			'settings.skipAdsModeOffDescription' => 'Відкриті оголошення зазвичай відтворюються без кнопки сканування',
			'settings.skipAdsModeButtonDescription' => 'Показати кнопку скачати, коли Plex виявляє рекламу',
			'settings.skipAdsModeAutoDescription' => 'Автоматично скачати знайдені оголошення після затримки нижче',
			'settings.musicPlayback' => 'Музика Playback',
			'settings.musicSweetFades' => 'Солодкі ФАДЕ',
			'settings.musicSweetFadesDescription' => 'Фейд-музика на краях сліду, коли Plex має дані про голос.',
			'settings.skipMarkerModeOff' => 'Вимкнути',
			'settings.skipMarkerModeButton' => 'Показати кнопку',
			'settings.skipMarkerModeAuto' => 'Автоматичний',
			'settings.forceSkipMarkerFallback' => 'Форс Фаллбак Маркерс',
			'settings.forceSkipMarkerFallbackDescription' => 'Використовуйте шаблони заголовку розділу, навіть якщо Plex має маркери',
			'settings.theIntroDbFallback' => 'Використовуйте TheIntroDB як інтро-пальбак',
			'settings.theIntroDbFallbackDescription' => 'Використовуйте час спільноти тільки тоді, коли сервер не має вхідного знака.',
			'settings.autoSkipDelay' => 'Автомобіль відкладає',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Залишилося ${seconds} секунди, перш ніж автоматично скачати',
			'settings.introPattern' => 'Вхідний маркер',
			'settings.introPatternDescription' => 'Регекс-патрий, щоб відповідати інтро-маркерам в заголовках розділів',
			'settings.creditsPattern' => 'Кредитний маркер',
			'settings.creditsPatternDescription' => 'Регекс-патрий, щоб порівняти кредитні маркери в заголовках',
			'settings.prerolls' => 'Проролів',
			'settings.playPrerollsBeforeMovies' => 'Грати в преролі перед фільмами',
			'settings.playPrerollsBeforeMoviesDescription' => 'Грати випадковий кліп з вашого вибору нижче перед кожним фільмом. натисніть назад, щоб перервати.',
			'settings.prerollLibrary' => 'Бібліотека Прероль',
			'settings.prerollLibraryNotSet' => 'Не встановлюйте',
			'settings.prerollLibraryNoneFound' => 'Бібліотеки на серверах не знайдено.',
			'settings.prerollSelection' => 'Вибрані преролі',
			'settings.prerollSelectionPickLibraryFirst' => 'Перш за все, вибирайте бібліотеку',
			'settings.prerollSelectionNoneSelected' => 'Не вибрані преролії',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} вибрано',
			'settings.prerollItemPicker' => 'Вибір преролів',
			'settings.prerollItemPickerLoadFailed' => 'Не можна було завантажувати матеріали з цієї бібліотеки.',
			'settings.invalidRegex' => 'Недостатній регулярний вираження',
			'settings.regex' => 'Регулярне вираження',
			'settings.downloads' => 'Завантаження',
			'settings.downloadLocationDescription' => 'Виберіть, де зберігати завантажений контент',
			'settings.downloadLocationDefault' => 'За замовчуванням (App Storage)',
			'settings.downloadLocationCustom' => 'Кваліфіковані місця',
			'settings.selectFolder' => 'Вибір папки',
			'settings.resetToDefault' => 'Повернення до дефолту',
			'settings.currentPath' => ({required Object path}) => 'Теперішній номер: ${path}',
			'settings.downloadLocationChanged' => 'Змінено місце розташування',
			'settings.downloadLocationReset' => 'Завантажити місце розташування Reset to default',
			'settings.downloadLocationInvalid' => 'Вибраний папку не можна писати',
			'settings.downloadLocationPickerUnavailable' => 'Вибір папки не доступний на цьому пристрої',
			'settings.downloadOnWifiOnly' => 'Завантажити на Wi-Fi тільки',
			'settings.downloadOnWifiOnlyDescription' => 'Забороняється завантажувати, коли на клітинних даних',
			'settings.autoRemoveWatchedDownloads' => 'Авто-усунути переглянуті завантаження',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Автоматично видаляти переглянуті завантаження',
			'settings.autoDownloadContinueWatching' => 'Автомобільні завантаження Продовжувати дивитися',
			'settings.autoDownloadContinueWatchingDescription' => 'Зберігайте елементи на вашій скриньці Продовження перегляду завантажені, і видаляйте їх, як тільки вони покинуть скриньку',
			'settings.downloadQuality' => 'Завантажити якість',
			'settings.downloadQualityDescription' => 'Plex підготує конвертовану копію в її копії завантаження. Jellyfin і Emby транскод під час завантаження файлу; перервані передачі можуть знадобитися для перезавантаження.',
			'settings.askDownloadQualityEachTime' => 'Вибір якості для кожного завантаження',
			'settings.askDownloadQualityEachTimeDescription' => 'Показати якісний пікер перед тим, як переглянути кожен відеозавантаження',
			'settings.cellularDownloadBlocked' => 'Завантаження блокуються на мобільному телефоні. використовуйте Wi-Fi або змініть налаштування.',
			'settings.maxVolume' => 'Максимальна гучність',
			'settings.maxVolumeDescription' => 'Дозволити підсилення гучності понад 100% для медіа з тихим звуком',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Річ у багатій присутності',
			'settings.discordRichPresenceDescription' => 'Покажіть, що ви дивитеся на Discord',
			'settings.services' => 'Сервіси',
			'settings.servicesDescription' => 'Зв\'яжіться Trakt, MyAnimeList, Seerr, і багато іншого',
			'settings.manageLibrariesDescription' => 'Завантажити та приховати бібліотеки',
			'settings.companionRemoteServer' => 'Віддалені сервери',
			'settings.companionRemoteServerDescription' => 'Дозвольте мобільним пристроям у вашій мережі контролювати цю програму',
			'settings.companionRemoteServerStartFailed' => 'Не можна було запустити сервер товаришів',
			'settings.companionRemoteServerStopFailed' => 'Не можна було зупинити сервер товаришів',
			'settings.autoPip' => 'Створення Auto Picture-in-Picture',
			'settings.autoPipDescription' => 'Автоматично введіть зображення в зображення, коли ви покидаєте додаток під час відтворення',
			'settings.matchContentFrameRate' => 'Матч Content Frame Rate',
			'settings.matchContentFrameRateDescription' => 'Матч показує відновлювальний показ до відеоконтенту',
			'settings.matchContentResolution' => 'Матч контент резолюція',
			'settings.matchContentResolutionDescription' => 'Перемістіть дисплей на різноманітність відео так, щоб ваш телевізор працював упсскальними.',
			'settings.matchRefreshRate' => 'Матч відновлює темпи',
			'settings.matchRefreshRateDescription' => 'Матч показує швидкість оновлення на повній екрані',
			'settings.matchDynamicRange' => 'Динамічний діапазон',
			'settings.matchDynamicRangeDescription' => 'Перемістіть HDR для HDR-контенту, а потім поверніться до SDR',
			'settings.displaySwitchDelay' => 'Затримка дисплею Switch',
			'settings.tunneledPlayback' => 'Тунель Playback',
			'settings.tunneledPlaybackDescription' => 'Використовуйте відео-туннелінг. Вимкніть, якщо HDR відтворює чорне відео або рух-стутери.',
			'settings.audioPassthrough' => 'Анонс аудіо',
			'settings.audioPassthroughDescription' => 'Надіслати звук Dolby/DTS на ваш приймач або телевізор без перекодування, зберігаючи звук навколо.',
			'settings.audioPassthroughDescriptionApple' => 'Використовуйте корінний декодер Dolby Apple для Dolby Digital Plus, в тому числі Atmos. DTS і TrueHD все ще грають як багатоканальний PCM.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Використовувати власний декодер Dolby від Apple для Dolby Digital Plus, зокрема Atmos. На iOS, iPadOS і tvOS 26 або новіших TrueHD Atmos та DTS:X відтворюються як просторове аудіо. Інші доріжки DTS і TrueHD відтворюються як багатоканальний PCM. Вимкніть, якщо немає звуку.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Вимкніть, поки звукова нормалізація на',
			'settings.audioChannelLimit' => 'Аудіоканали',
			'settings.audioChannelLimitDescription' => 'Змішайте розшифрований аудіо для голосових пристроїв, наушників або налаштувань HDMI, які не можуть грати в будь-який канал',
			'settings.audioChannelLimitOriginal' => 'Оригінальна',
			'settings.audioChannelLimitOriginalDescription' => 'Грати в кожен канал на трасі',
			'settings.audioChannelLimitSurround51' => 'До 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Змішайте 7.1 до 5.1 для телевізорів і приймачів, які приймають тільки 5.1 ПКМ.',
			'settings.audioChannelLimitStereo' => 'Стерео',
			'settings.audioChannelLimitStereoDescription' => 'Змішайте до двох каналів для стерео-голосних пристроїв або наушників.',
			'settings.downmixCenterBoost' => 'Створення Channel Boost',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} дБ',
			'settings.downmixCenterBoostLabel' => 'Завантажити (dB)',
			'settings.downmixCenterBoostShort' => 'ДБ',
			'settings.audioDownmixNormalize' => 'Використання об\'єктів Downmix',
			'settings.audioDownmixNormalizeDescription' => 'Знизити суміш, щоб уникнути схилу. вимкніть, щоб зберегти оригінальний обсяг (може порушити голосні сцени).',
			'settings.dvConversionMode' => 'Dolby Vision Перетворення',
			'settings.dvConversionModeDescription' => 'Виберіть, як обробляються файли Dolby Vision Профіль 7 .',
			'settings.dvConversionAuto' => 'Авто',
			'settings.dvConversionNative' => 'Інвалідність / Disabled',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Використання пристрою здатності виявлення і нормального поведінки падіння',
			'settings.dvConversionNativeDescription' => 'ДВ7 і ДВ-конверсійний ретрит',
			'settings.dvConversionDv81Description' => 'Конвертація силового RPU на Dolby Vision профіль 8.1',
			'settings.dvConversionHevcStripDescription' => 'Стрип Dolby Vision РПУ/ЕЛ шари і нинішня плоска HEVC',
			'settings.disableDolbyVision' => 'Завантажити Dolby Vision',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'Грати в файл HDR10 або HLG-слой замість Dolby Vision, коли у нього є один',
			'settings.hdrSdrConversion' => 'Конвертація HDR до SDR',
			'settings.hdrSdrConversionDescription' => 'Виберіть, що конвертує HDR відео, коли дисплей не може показати HDR.',
			'settings.hdrSdrConversionAuto' => 'Авто',
			'settings.hdrSdrConversionAutoDescription' => 'Пристрій на Android 9 і пізніше, гравець на попередніх версіях',
			'settings.hdrSdrConversionDevice' => 'Пристрій',
			'settings.hdrSdrConversionDeviceDescription' => 'Найшвидше, але кольори залежить від пристрою',
			'settings.hdrSdrConversionPlayer' => 'Програвач',
			'settings.hdrSdrConversionPlayerDescription' => 'Консистентні кольори, але 4K може зіткнутися з низькоповерховими телевізійними ящиками',
			'settings.deinterlace' => 'Відключення',
			'settings.deinterlaceDescription' => 'Видалення об\'єктивних артефактів з переміщеного відео (mpv гравців тільки)',
			'settings.deinterlaceOff' => 'Вимкнути',
			'settings.deinterlaceOffDescription' => 'Показати відео, як він декодирований',
			'settings.deinterlaceVideo' => 'Відео',
			'settings.deinterlaceVideoDescription' => 'Для відеозапису для телевізора, таких як спорт, новини та концерти',
			'settings.deinterlaceFilm' => 'Фільми',
			'settings.deinterlaceFilmDescription' => 'Відновлюйте оригінальні рамки фільму та анімації, телецентовані до 29,97 фп/с, поширені на DVD-дисках NTSC. Відеозапис для телевізійних стутерів.',
			'settings.requireProfileSelectionOnOpen' => 'Запросити профіль на відкритому пристрої',
			'settings.requireProfileSelectionOnOpenDescription' => 'Показати вибір профілю кожен раз, коли відкривається додаток',
			'settings.forceTvMode' => 'Мода телевізора',
			'settings.forceTvModeDescription' => 'Для пристроїв, які не автоматично виявляються, необхідно перезавантажувати.',
			'settings.startInFullscreen' => 'Почнемо з повного екрану',
			'settings.startInFullscreenDescription' => 'Відкрийте PlezyNG в режимі повного екрану на запуску',
			'settings.exitFullscreenOnPlayerClose' => 'Повний екран виходу на гравця закритий',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Автоматично виходить повний екран при закритті відеоплеєра',
			'settings.autoHidePerformanceOverlay' => 'Автоматичний прикритий показник',
			'settings.autoHidePerformanceOverlayDescription' => 'Завантажити перелік продуктивності за допомогою контролів відтворення',
			'settings.showNavBarLabels' => 'Показати Navigation Bar Labels',
			'settings.showNavBarLabelsDescription' => 'Показати текстові етикетки під іконами смуги навігації',
			'settings.startupSection' => 'Розділ Startup',
			'settings.preferredServer' => 'Улюблений сервер',
			'settings.preferredServerDescription' => 'Приоритетним є результати цього сервера, зберігаючи доступ до кожного підключеного сервера.',
			'settings.preferredServerAutomatic' => 'Автоматичний',
			'settings.showExploreTab' => 'Показати таб',
			'settings.showExploreTabDescription' => 'Показати кнопку Explore з контентом з Plex Discover та підключених відстежувачів',
			'settings.hideEmptyLibraries' => 'Закрийте порожні бібліотеки',
			'settings.hideEmptyLibrariesDescription' => 'Усунути бібліотеки з сервером-репортажним числом елементів нуля з навігації.',
			'settings.liveTvDefaultFavorites' => 'Завантажити улюблені канали',
			'settings.liveTvDefaultFavoritesDescription' => 'Показати тільки улюблені канали при відкритті Live TV',
			'settings.general' => 'Загальні',
			'settings.generalDescription' => 'Мова, стартап і поведінка вікна',
			'settings.languageAndRegion' => 'Мова і регіон',
			'settings.startup' => 'Стартує',
			'settings.display' => 'Подання',
			'settings.libraryAndCards' => 'Бібліотека & Карти',
			'settings.homeScreen' => 'Домашній екран',
			'settings.navigation' => 'Навігація',
			'settings.window' => 'вікно',
			'settings.liveTv' => 'Прямий ефір',
			'settings.player' => 'Програвач',
			'settings.videoAndDisplay' => 'Відео та дисплей',
			'settings.audio' => 'Аудіо',
			'settings.quality' => 'Якість',
			'settings.subtitles' => 'Субтитри',
			'settings.seekAndTiming' => 'Пошук і час',
			'settings.behavior' => 'поведінка',
			'settings.gestures' => 'Гестюр',
			'settings.gestureBrightnessSwipe' => 'Світло Свіп',
			'settings.gestureBrightnessSwipeDescription' => 'Перемішайте вгору або вниз на лівому краю, щоб налаштувати яскравість',
			'settings.gestureVolumeSwipe' => 'Обсяг Swipe',
			'settings.gestureVolumeSwipeDescription' => 'Перемішайте вгору або вниз на правому краю, щоб встановити обсяг',
			'settings.gesturePinchToZoom' => 'Пінч до зоуму',
			'settings.gesturePinchToZoomDescription' => 'Натисніть на відео, щоб зумувати в або вийти',
			'settings.gestureSeekSwipe' => 'Пошук Swipe',
			'settings.gestureSeekSwipeDescription' => 'Перемішайте ліворуч або праворуч в будь-якій точці відео, щоб шукати; випустіть, щоб стрибнути',
			'settings.rememberBrightnessLevel' => 'Згадайте рівень яскравості',
			'settings.rememberBrightnessLevelDescription' => 'Почніть відтворювати на яскравості, встановленому останньою перемикачею',
			'settings.controls' => 'Елементи керування',
			'settings.rememberPlayerChanges' => 'Зміни гравців',
			'settings.rememberPlayerChangesDescription' => 'де зміна, зроблена під час відтворення, зберігається і повторюється з',
			'settings.scopePlaybackSpeed' => 'Швидкість відтворення',
			'settings.scopeShaderPreset' => 'Шейдер Пресет',
			'settings.scopeAspectRatio' => 'Співвідношення сторін',
			'settings.scopeSyncOffsets' => 'Audio & Subtitle Співвідношення',
			'settings.playerScopeOff' => 'Не врятуйте',
			'settings.playerScopeGlobal' => 'всюди',
			'settings.playerScopeLibrary' => 'за бібліотекою',
			'settings.playerScopeTitle' => 'Про шоу або фільм',
			'settings.exportDialogTitle' => 'Експорт PlezyNG установки',
			'settings.followSystem' => 'Мова системи',
			'settings.followAppLanguage' => 'Як у мові інтерфейсу',
			'settings.regionFormat' => 'Регіональні формати',
			'settings.regionFormatDescription' => 'Виберіть формат відображення дат, чисел і одиниць вимірювання.',
			'settings.metadataLanguage' => 'Мова метаданих',
			'settings.metadataLanguageDescription' => 'Бажана мова назв та описів, якщо сервер її підтримує. Налаштування звуку й субтитрів залишаються окремими.',
			'settings.experimentalDolbyVision' => 'Експериментальний Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'Під час наступного відтворення використовувати експериментальний рендерер FEL. Потрібна окрема збірка рушія.',
			'settings.dvExperimentUnavailableDescription' => 'Цей експеримент наразі доступний лише в Linux.',
			'settings.dvCompatibilityFallback' => 'Резервний режим сумісності',
			'settings.dvCompatibilityFallbackDescription' => 'Використовувати стандартний рендерер, якщо експеримент не запускається. Дані FEL можуть бути втрачені.',
			'settings.dvExperimentDiagnostics' => 'Журнал відеоексперименту',
			'settings.dvExperimentDiagnosticsDescription' => 'Увімкнути докладні журнали програвача під час наступного відтворення.',
			'themeEditor.builtIn' => 'Будівництво',
			'themeEditor.presets' => 'Президи',
			'themeEditor.custom' => 'Користувацький',
			'themeEditor.customEmpty' => 'Наразі не створено',
			'themeEditor.editCustom' => 'Редагувати тематику',
			'themeEditor.editCustomDescription' => 'Виберіть колір самостійно',
			'themeEditor.locked' => 'Доступ до життєдіяльності необхідний',
			'themeEditor.savedLocked' => 'Збережений — доступний з доступом до життя',
			'themeEditor.title' => 'Кваліфіковані теми',
			'themeEditor.startFrom' => 'Почнемо з',
			'themeEditor.startFromDescription' => 'Копіюйте всі кольори з іншої теми',
			'themeEditor.colors' => 'Кольори',
			'themeEditor.preview' => 'Попередній перегляд',
			'themeEditor.slots.bg' => 'фонтани',
			'themeEditor.slots.surface' => 'поверхня',
			'themeEditor.slots.outline' => 'Офіційний',
			'themeEditor.slots.text' => 'Текст',
			'themeEditor.slots.textMuted' => 'Вторинний текст',
			'themeEditor.slots.accent' => 'акцент',
			'themeEditor.opacity' => 'Опаситність',
			'themeEditor.hexHint' => '#RRGGBB або #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'з інших тем',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'Текст на фоні',
			'themeEditor.contrast.textOnSurface' => 'Текст на поверхні',
			'themeEditor.contrast.textMutedOnBg' => 'Вторинний текст на фоні',
			'themeEditor.contrast.textMutedOnSurface' => 'Вторинний текст на поверхні',
			'themeEditor.contrast.accentOnBg' => 'Акцент на фоні',
			'themeEditor.contrast.accentOnSurface' => 'акцент на поверхні',
			'themeEditor.contrast.labelOnAccent' => 'Кнопка на акценті',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, нижче рекомендованої ${minimum}:1',
			'themeEditor.discardTitle' => 'Не вистачає змін?',
			'themeEditor.discardMessage' => 'Незбережені зміни кольорів буде втрачено.',
			'themeEditor.discard' => 'Дискард',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Епізод ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} хвилини',
			'themeEditor.previewSwitch' => 'Автомобільний',
			'themeEditor.previewMutedText' => 'Другий текст читається таким чином.',
			'search.hint' => 'Пошук фільмів, шоу, музики...',
			'search.tryDifferentTerm' => 'Спробуйте інший термін пошуку',
			'search.searchYourMedia' => 'Знайдіть свої медіа',
			'search.enterTitleActorOrKeyword' => 'Введіть заголовок, актор або ключове слово',
			'search.people' => 'Люди',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Розташований короткометражний набір для ${actionName}',
			'hotkeys.clearShortcut' => 'Чистий короткий',
			'hotkeys.noShortcutSet' => 'Без короткострокових',
			'hotkeys.currentShortcut' => 'Теперішній короткостроковий:',
			'hotkeys.pressToRecord' => 'Виберіть для запису короткострокового',
			'hotkeys.recordingShortcut' => 'Натисніть скорочення зараз',
			'hotkeys.actions.playPause' => 'Ігри / Пауза',
			'hotkeys.actions.volumeUp' => 'ВВП ВВП',
			'hotkeys.actions.volumeDown' => 'Розмір Down',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Пошук вперед (${seconds})',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Пошук назад (${seconds} с)',
			'hotkeys.actions.fullscreenToggle' => 'Повний екран',
			'hotkeys.actions.muteToggle' => 'Спілкуйтеся з мутом',
			'hotkeys.actions.subtitleToggle' => 'Підвищення субтитри',
			'hotkeys.actions.audioTrackNext' => 'Наступна стаття Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'Наступна статтяПерші підручники',
			'hotkeys.actions.chapterNext' => 'Наступна сцена',
			'hotkeys.actions.chapterPrevious' => 'Попередня сцена',
			'hotkeys.actions.episodeNext' => 'Наступний епізод',
			'hotkeys.actions.episodePrevious' => 'Попередній епізод',
			'hotkeys.actions.speedIncrease' => 'Збільшення швидкості',
			'hotkeys.actions.speedDecrease' => 'Зниження швидкості',
			'hotkeys.actions.speedReset' => 'Швидкість відновлення',
			'hotkeys.actions.zoomIn' => 'Зом в',
			'hotkeys.actions.zoomOut' => 'Зоум виходить',
			'hotkeys.actions.zoomReset' => 'Реабілітація Zoom',
			'hotkeys.actions.subSeekNext' => 'Пошук наступного субтитра',
			'hotkeys.actions.subSeekPrev' => 'Пошук попереднього субтитра',
			'hotkeys.actions.subtitleDelayIncrease' => 'Затримка субтитри',
			'hotkeys.actions.subtitleDelayDecrease' => 'Наступні субтитри',
			'hotkeys.actions.shaderToggle' => 'Співвідношення стін',
			'hotkeys.actions.skipMarker' => 'Кредит / Кредит',
			'hotkeys.actions.screenshot' => 'Створення Screenshot',
			'hotkeys.actions.framePrevious' => 'Попередня рамка',
			'hotkeys.actions.frameNext' => 'Наступна рамка',
			'fileInfo.title' => 'Файли Info',
			'fileInfo.overview' => 'Опис',
			'fileInfo.video' => 'Відео',
			'fileInfo.audio' => 'Аудіо',
			'fileInfo.subtitles' => 'Субтитри',
			'fileInfo.images' => 'Вбудовані зображення',
			'fileInfo.dataStreams' => 'Дані потоків',
			'fileInfo.lyrics' => 'Текст пісні',
			'fileInfo.file' => 'Файл',
			'fileInfo.attachments' => 'Активісти',
			'fileInfo.delivery' => 'Доставка',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Версія ${index} з ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Файл ${index} з ${count}',
			'fileInfo.noStreams' => 'Сервер не повідомив про потоки для цього файлу.',
			'fileInfo.copyPath' => 'Копіювати шлях',
			'fileInfo.pathCopied' => 'Копіювати шлях файлу',
			'fileInfo.codec' => 'Кодек',
			'fileInfo.codecTag' => 'Тег кодека',
			'fileInfo.resolution' => 'Роздільна здатність',
			'fileInfo.codedResolution' => 'Кодирована резолюція',
			'fileInfo.bitrate' => 'Бітрейт',
			'fileInfo.frameRate' => 'Рамкова швидкість',
			'fileInfo.rotation' => 'Обертання',
			'fileInfo.comment' => 'Як',
			'fileInfo.audioDescription' => 'Опис аудіо',
			'fileInfo.headerCompression' => 'Головний компрес',
			'fileInfo.sidecarFile' => 'Файли Sidecar',
			'fileInfo.transportTimestamp' => 'Транспортний час',
			'fileInfo.displayOffset' => 'Завантажити Offset',
			'fileInfo.previewFailureCode' => 'Кодекс провалу',
			'fileInfo.previewRetries' => 'Предыдущая запись: Retries',
			'fileInfo.aspectRatio' => 'Співвідношення сторін',
			'fileInfo.pixelAspectRatio' => 'Розмір Pixel Aspect',
			'fileInfo.profile' => 'Профіль',
			'fileInfo.level' => 'Рівень',
			'fileInfo.bitDepth' => 'Розрядність',
			'fileInfo.pixelFormat' => 'Піксельний формат',
			'fileInfo.colorSpace' => 'Кольоровий простір',
			'fileInfo.colorRange' => 'Колірний діапазон',
			'fileInfo.colorPrimaries' => 'Основні кольори',
			'fileInfo.colorTransfer' => 'Передача кольору',
			'fileInfo.chromaSubsampling' => 'Хрома Субсамплінг',
			'fileInfo.chromaLocation' => 'Хрома розташування',
			'fileInfo.scanType' => 'Скенерний тип',
			'fileInfo.interlaced' => 'Переплетений',
			'fileInfo.anamorphic' => 'Анаморфний',
			'fileInfo.referenceFrames' => 'Референтні рамки',
			'fileInfo.dynamicRange' => 'Динамічний діапазон',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision Рівень',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision Видання',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision Склади',
			'fileInfo.baseLayerCompatibility' => 'Сумісність базового шару',
			'fileInfo.avcBitstream' => 'АВК Bitstream',
			'fileInfo.nalLengthSize' => 'Розмір довжини',
			'fileInfo.scalingMatrix' => 'Матриці для скалювання',
			'fileInfo.streamIdentifier' => 'Потік ідентифікатора',
			'fileInfo.streamIndex' => 'Індекс потоку',
			'fileInfo.streamId' => 'Потік ID',
			'fileInfo.language' => 'Мова',
			'fileInfo.languageCode' => 'Кодекс мови',
			'fileInfo.streamTitle' => 'Назва трак',
			'fileInfo.channels' => 'Канали',
			'fileInfo.sampleRate' => 'Частота дискретизації',
			'fileInfo.spatialAudio' => 'Космічний аудіо',
			'fileInfo.textBased' => 'Текст заснований',
			'fileInfo.subtitleFormat' => 'Формат сидіння',
			'fileInfo.provider' => 'Провайдер',
			'fileInfo.matchScore' => 'Матч Результати',
			'fileInfo.externalDelivery' => 'Їх можна подавати окремо',
			'fileInfo.sidecarPath' => 'Сидекарський шлях',
			'fileInfo.sourceStream' => 'Копіюється з',
			'fileInfo.temporary' => 'Тимчасовий',
			'fileInfo.timeBase' => 'База часу',
			'fileInfo.overallBitrate' => 'Всього Bitrate',
			'fileInfo.path' => 'Шлях',
			'fileInfo.fileName' => 'Назва файлу',
			'fileInfo.size' => 'Розмір',
			'fileInfo.totalSize' => 'загальний розмір',
			'fileInfo.container' => 'Контейнер',
			'fileInfo.duration' => 'Тривалість',
			'fileInfo.previewThumbnails' => 'Предыдущая статьяТумфаль',
			'fileInfo.previewIndex' => 'Індекс попереднього',
			'fileInfo.packetLength' => 'Довжина пакету',
			'fileInfo.filePresent' => 'Файл присутній',
			'fileInfo.fileReadable' => 'Читання сервера',
			'fileInfo.streamPath' => 'Потік шляху',
			'fileInfo.optimizedForStreaming' => 'Оптимізація для потоку',
			'fileInfo.has64bitOffsets' => '64-бітний Offsets',
			'fileInfo.protocol' => 'Протокол',
			'fileInfo.mediaType' => 'Тип медіа',
			'fileInfo.sourceKind' => 'Джерело: Kind',
			'fileInfo.optimizedVersion' => 'Оптимізована версія',
			'fileInfo.optimizationTarget' => 'Мета оптимізації',
			'fileInfo.deletedAt' => 'Знято',
			'fileInfo.remoteSource' => 'Віддалені джерела',
			'fileInfo.infiniteStream' => 'Нескінченний потік',
			'fileInfo.directPlay' => 'Пряма гра',
			'fileInfo.directStream' => 'Прямий потік',
			'fileInfo.transcoding' => 'Перекодування',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Версія ID',
			'fileInfo.fileId' => 'Файл ID',
			'fileInfo.defaultAudioTrack' => 'Завантажити Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'Завантажити Subtitle Track',
			'fileInfo.subtitlesOff' => 'Вимкнути',
			'fileInfo.flagDefault' => 'За замовчуванням',
			'fileInfo.flagForced' => 'Примусово',
			'fileInfo.flagSelected' => 'Вибрані',
			'fileInfo.flagExternal' => 'Зовнішній',
			'fileInfo.flagHearingImpaired' => 'Погіршення слуху',
			'fileInfo.flagDub' => 'Дуб',
			'fileInfo.flagOriginal' => 'Оригінальна',
			'fileInfo.channelsMono' => 'Моно',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Профіль ${profile}',
			'mediaMenu.markAsWatched' => 'Марк як спостерігається',
			'mediaMenu.markAsUnwatched' => 'Марк як невідомий',
			'mediaMenu.removeFromContinueWatching' => 'Видалення від продовження спостереження',
			'mediaMenu.viewDetails' => 'Переглянути деталі',
			'mediaMenu.goToSeries' => 'Перейти до серіалу',
			'mediaMenu.shufflePlay' => 'Шуффлей Play',
			'mediaMenu.shuffleNotAvailableOffline' => 'Шанхай не доступний офлайн',
			'mediaMenu.fileInfo' => 'Файли Info',
			'mediaMenu.deleteEpisodeFromServer' => 'Видалення епізоду з сервера',
			'mediaMenu.deleteSeasonFromServer' => 'Видалення сезону з сервера',
			'mediaMenu.deleteShowFromServer' => 'Видалення з сервера',
			'mediaMenu.deleteMovieFromServer' => 'Видалення фільму з сервера',
			'mediaMenu.deleteEpisodeTitle' => 'Чи можна видалити цей епізод?',
			'mediaMenu.deleteSeasonTitle' => 'Чи вийде цей сезон?',
			'mediaMenu.deleteShowTitle' => 'Чи відмовилися ви від цього шоу?',
			'mediaMenu.deleteMovieTitle' => 'Чи можна видалити цей фільм?',
			'mediaMenu.deleteEpisodeConfirm' => 'Видалити епізод',
			'mediaMenu.deleteSeasonConfirm' => 'Зняти сезон',
			'mediaMenu.deleteShowConfirm' => 'Зняти шоу',
			'mediaMenu.deleteMovieConfirm' => 'Знімайте фільм',
			'mediaMenu.deleteAnyway' => 'Зніміть в будь-якому випадку',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Постійно видаляти ${title} з сервера?',
			'mediaMenu.deleteMultipleWarning' => 'Це включає в себе всі епізоди і їх файли.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: 'Це видалить ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізод у ньому та його файл.', few: 'Це видалить усі ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізоди в ньому та їхні файли.', many: 'Це видалить усі ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізодів у ньому та їхні файли.', other: 'Буде видалено всі епізоди в цьому елементі (кількість: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) та їхні файли.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: 'Цей елемент зберігається в ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} файлі, який буде видалено.', few: 'Цей елемент зберігається в ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} файлах, і всі вони будуть видалені.', many: 'Цей елемент зберігається в ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} файлах, і всі вони будуть видалені.', other: 'Цей елемент зберігається у файлах (кількість: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}); усі ці файли буде видалено.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: 'У тому самому файлі зберігається ще ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізод, який також буде видалено:', few: 'У тому самому файлі зберігаються ще ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізоди, які також буде видалено:', many: 'У тому самому файлі зберігається ще ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} епізодів, які також буде видалено:', other: 'Інші епізоди в тому самому файлі (кількість: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) також буде видалено:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG не вдалося перевірити, які файли буде видалено, тому може бути видалено більше, ніж зазначений вище елемент. Скасуйте дію та спробуйте знову або видаліть попри це.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Сервер не надав відомостей про файли цього елемента, тому PlezyNG не може перевірити, які файли буде видалено. Може бути видалено більше, ніж зазначений вище елемент.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Медіа-елементи успішно видалені',
			'mediaMenu.mediaFailedToDelete' => 'Не вдалося видалити медіа',
			'mediaMenu.rate' => 'Оцінити',
			'mediaMenu.playFromBeginning' => 'Грати з початку',
			'mediaMenu.playVersion' => 'Грати в версію...',
			'rateSheet.title' => 'Оцінити',
			'rateSheet.server' => 'Сервер',
			'rateSheet.favorite' => 'Обране',
			'rateSheet.favorited' => 'улюблений',
			'rateSheet.saved' => 'Збережений',
			'rateSheet.notAvailable' => 'Матч не знайдено',
			'rateSheet.noConnectedServices' => 'Підключіть сервіс в налаштуваннях, щоб оцінити там.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, фільм',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, телевізійне шоу',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'Переглянуто',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} відсотків переглянуто',
			'accessibility.mediaCardUnwatched' => 'не переглянуто',
			'accessibility.tapToPlay' => 'Натисніть, щоб грати',
			'accessibility.decrease' => 'Зниження',
			'accessibility.increase' => 'Збільшення',
			'accessibility.decreaseValue' => ({required Object label}) => 'Зниження ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Збільшення ${label}',
			'accessibility.hue' => 'ХІХ',
			'accessibility.saturation' => 'Сатурн',
			'accessibility.brightness' => 'Яскравість',
			'accessibility.hexColor' => 'Hex колір',
			'accessibility.expandText' => 'Розширення тексту',
			'accessibility.collapseText' => 'Порушення тексту',
			'accessibility.alphabetNavigation' => 'Алфавитна навігація',
			'accessibility.alphabetScrollHint' => 'Проведіть угору або вниз, щоб переходити за літерами',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Рядок ${row} із ${rowCount}, стовпець ${column} із ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Роль ${row} з ${rowCount}',
			'accessibility.autoScrollPlay' => 'Грати в Auto-Scroll',
			'accessibility.autoScrollPause' => 'Відпочинок Auto-Scroll',
			'accessibility.hueShort' => 'Х',
			'accessibility.saturationShort' => 'С',
			'accessibility.valueShort' => 'В',
			'accessibility.red' => 'Червоний',
			'accessibility.green' => 'Зелений',
			'accessibility.blue' => 'Синій',
			'accessibility.redShort' => 'Р',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'Б',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'РГБ',
			'accessibility.title' => 'Доступність',
			'accessibility.summary' => 'Текст, контраст, рух і контроль',
			'accessibility.systemHint' => 'Налаштування доступності вашого пристрою завжди застосовуються. ці варіанти додають налаштування протягом PlezyNG.',
			'accessibility.readability' => 'Читання та видимість',
			'accessibility.textSize' => 'Додатковий текст розмір',
			'accessibility.preview' => 'Читайте, слухайте і дивіться у своєму власному темпі.',
			'accessibility.boldText' => 'Сміливий інтерфейс тексту',
			'accessibility.highContrast' => 'Високий контраст',
			'accessibility.highContrastHint' => 'Сильніший текст, виклади та індикатори фокусу на світлих або темних поверхнях.',
			'accessibility.interaction' => 'Мотивація і взаємодія',
			'accessibility.reduceMotion' => 'Зменшення руху',
			'accessibility.reduceMotionHint' => 'Зупиняє анімацію індикатора фокусу, переходи сторінок і декоративні ефекти.',
			'accessibility.largeTargets' => 'Більшість цілей',
			'accessibility.largeTargetsHint' => 'Дайте спільним контролям більше місця для дотику і асистентської навігації.',
			'accessibility.navigationHint' => 'Використовуйте Tab і Shift+Tab для переходу між елементами керування, Enter або пробіл для активації, а Escape або кнопку «Назад» для закриття. Коли книгу відкрито, доступні масштабування й налаштування читання.',
			'tooltips.shufflePlay' => 'Шуффлей грає',
			'tooltips.playTrailer' => 'Грати в трейлер',
			'tooltips.markAsWatched' => 'Марк як спостерігається',
			'tooltips.markAsUnwatched' => 'Марк як невідомий',
			'audioTracks.track' => ({required Object n}) => 'Анонс звуку ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадр', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадри', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадрів', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} кадри', ), 
			'videoControls.audioLabel' => 'Аудіо',
			'videoControls.subtitlesLabel' => 'Субтитри',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Літературний ящик',
			'videoControls.fillScreen' => 'Завантажити екран',
			'videoControls.stretch' => 'Розтягнути',
			'videoControls.lockRotation' => 'Ротація замку',
			'videoControls.unlockRotation' => 'Відключення ротації',
			'videoControls.timerActive' => 'Активний час',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Завантажити Playback в ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Кінець поточного відео',
			'videoControls.sleepTimerStopAtHeader' => 'зупиніться на',
			'videoControls.sleepTimerDurationHeader' => 'Час',
			'videoControls.playbackWillPauseAtEnd' => 'Playback буде перерватися в кінці цього відео',
			'videoControls.stillWatching' => 'Чи все ще дивитися?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Позиція в ${seconds}s',
			'videoControls.continueWatching' => 'Продовжуйте',
			'videoControls.autoPlayNext' => 'Автомобільні наступні',
			'videoControls.playNext' => 'Наступне',
			'videoControls.playButton' => 'Грати',
			'videoControls.pauseButton' => 'Пауза',
			'videoControls.playbackPaused' => 'Відпочинок',
			'videoControls.playbackResumed' => 'Грати',
			'videoControls.loadingVideo' => 'Завантажити відео',
			'videoControls.showPlaybackControls' => 'Переглянути Playback Control',
			'videoControls.hidePlaybackControls' => 'Завантажити Playback Control',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Пошук назад ${seconds} секунд',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Пошук вперед ${seconds} секунд',
			'videoControls.previousButton' => 'Попередній епізод',
			'videoControls.nextButton' => 'Наступний епізод',
			'videoControls.previousChapterButton' => 'Попередня сцена',
			'videoControls.nextChapterButton' => 'Наступна сцена',
			'videoControls.muteButton' => 'Заглушити',
			'videoControls.unmuteButton' => 'Увімкнути звук',
			'videoControls.settingsButton' => 'Створення Playback Settings',
			'videoControls.tracksButton' => 'Аудіо та субтитри',
			'videoControls.trackSelectionTitle' => 'Вибирайте сходинки перед відтворенням',
			'videoControls.trackSelectionAuto' => 'Автоматичний вибір',
			'videoControls.chaptersButton' => 'Розділи',
			'videoControls.versionQualityButton' => 'Версія і якість',
			'videoControls.versionColumnHeader' => 'Версія',
			'videoControls.qualityColumnHeader' => 'Якість',
			'videoControls.qualityOriginal' => 'Оригінальна',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Мб/с',
			'videoControls.transcodeUnavailableFallback' => 'Перешифрування недоступне — грати в оригінальну якість',
			'videoControls.subtitleUnavailableFallback' => 'Вибрані субтитри не можуть бути завантажені — продовжувати без субтитри',
			'videoControls.pipButton' => 'Модуль зображення в режимі',
			'videoControls.aspectRatioButton' => 'Співвідношення сторін',
			'videoControls.ambientLighting' => 'Екологічне освітлення',
			'videoControls.fullscreenButton' => 'Введіть повний екран',
			'videoControls.exitFullscreenButton' => 'Повний екран виходу',
			'videoControls.alwaysOnTopButton' => 'Завжди на вершині',
			'videoControls.rotationLockButton' => 'Ротаційний замок',
			'videoControls.lockScreen' => 'Закритий екран',
			'videoControls.screenLockButton' => 'Закриття екрану',
			'videoControls.longPressToUnlock' => 'Довгий тиск для розблокування',
			'videoControls.timelineSlider' => 'Відео Timeline',
			'videoControls.volumeSlider' => 'Розмір обсягу',
			'videoControls.endsAt' => ({required Object time}) => 'Завершився на ${time}',
			'videoControls.pipActive' => 'Створення Picture-in-Picture',
			'videoControls.pipFailed' => 'Фото-ін-фото не вдалося почати',
			'videoControls.screenshotSaved' => 'Створення Screenshot Save',
			'videoControls.screenshotFailed' => 'Я не міг зробити екран',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Масштаб ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Гучність ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Потрібні Android 8.0 або новіше',
			'videoControls.pipErrors.iosVersion' => 'Потрібні iOS 15.0 або новіше',
			'videoControls.pipErrors.permissionDisabled' => 'Image-in-image вимкнений.Відключити його в системних налаштуваннях.',
			'videoControls.pipErrors.notSupported' => 'Пристрій не підтримує режим зображення в зображенні',
			'videoControls.pipErrors.voSwitchFailed' => 'Не вдалося перетворити вихід відео на зображення-в-фото',
			'videoControls.pipErrors.failed' => 'Фото-ін-фото не вдалося почати',
			'videoControls.pipErrors.prepareFailed' => 'Зображення в картинці не можна було підготувати',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Повідомляється про помилку: ${error}',
			'videoControls.chapters' => 'Розділи',
			'videoControls.noChaptersAvailable' => 'Розділів немає',
			'videoControls.queue' => 'Квітень',
			'videoControls.noQueueItems' => 'Немає предметів в ковбасі',
			'videoControls.noAudioDevicesAvailable' => 'Немає доступних аудіопристроїв',
			'videoControls.searchSubtitles' => 'Пошук субтитри',
			'videoControls.loadSubtitleFile' => 'Завантажити файл підзаголовок...',
			'videoControls.subtitleLoadFailed' => 'Не вдалося завантажити файл субтитри',
			'videoControls.language' => 'Мова',
			'videoControls.noSubtitlesFound' => 'Немає знайдених субтитри',
			'videoControls.subtitleDownloaded' => 'Підзаголовок завантажено',
			'videoControls.subtitleDownloadedNotApplied' => 'Підзаголовок завантажено, але його не можна було вибрати',
			'videoControls.subtitleDownloadFailed' => 'Не вдалося завантажити субтитри',
			'videoControls.searchLanguages' => 'Язики пошуку...',
			'videoControls.skipIntro' => 'Скіп Інтро',
			'videoControls.skipCredits' => 'Кредити Скіп',
			'videoControls.skipAds' => 'Скачати рекламу',
			'videoControls.nextEpisode' => 'Наступний епізод',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Стрічка ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Підголовок ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (примусовий)',
			'videoControls.osdSubtitlesOff' => 'Підзаголовок: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Підзаголовок: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Звук: ${track}',
			'messages.markedAsWatched' => 'Ознаковано як спостерігається',
			'messages.markedAsUnwatched' => 'Ознаковано як невидиме',
			'messages.markedAsWatchedOffline' => 'Марковано як спостерігалося (синхровується, коли онлайн)',
			'messages.markedAsUnwatchedOffline' => 'Ознаковано як невизначено (синхровується, коли онлайн)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Автомобільний відключений: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: 'Авто-усунути ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} переглянуто завантажити', other: 'Авто-усунути ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} переглянуто завантаження', ), 
			'messages.removedFromContinueWatching' => 'Звільнення від продовження спостереження',
			'messages.errorLoading' => ({required Object error}) => 'Помилка: ${error}',
			'messages.searchPartialResults' => 'Деякі медіа-сервери не можуть бути пошуковані. показуючи доступні результати.',
			'messages.streamInterrupted' => 'Потік був перерваний. друку грати або шукати відступ.',
			'messages.liveStreamInterrupted' => 'Протягом потоку було припинено. преса грати до відходу.',
			'messages.fileInfoNotAvailable' => 'Файл інформації не доступний',
			'messages.playbackAuthenticationRequired' => 'Зареєструйтесь на сервері ЗМІ знову, щоб грати в цей елемент.',
			'messages.playbackServerUnavailable' => 'Медіа-сервер не доступний. спробуйте знову пізніше.',
			'messages.playbackDataInvalid' => 'Сервер повернув недійсну інформацію про відтворення.',
			'messages.playbackCancelled' => 'Playback було скасовано.',
			'messages.playbackFailed' => 'Playback не можна було почати.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Завантажити не можна: ${error}',
			'messages.audioOutputFailed' => 'Перевірте аудіозв\'язок телевізора або приймача; якщо інші додатки також не мають звуку, перезапустіть пристрій.',
			'messages.mediaUnavailable' => 'Цей контент більше не доступний.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Помилка завантаження файлу інформація: ${error}',
			'messages.errorLoadingSeries' => 'Серія помилок завантаження',
			'messages.musicNotSupported' => 'Музичне відтворення ще не підтримується',
			'messages.noDescriptionAvailable' => 'Опис не доступний',
			'messages.noProfilesAvailable' => 'Доступні профілі немає',
			'messages.contactAdminForProfiles' => 'Зв\'яжіться з адміністратором сервера, щоб додати профілі',
			'messages.unableToDetermineLibrarySection' => 'Неможливо визначити розділ бібліотеки для цього пункту',
			'messages.logsCleared' => 'Логіки очищені',
			'messages.logsCopied' => 'Копіюється в clipboard',
			'messages.noLogsAvailable' => 'Доступні записи немає',
			'messages.libraryScanning' => ({required Object title}) => 'Сканування «${title}»',
			'messages.libraryScanStarted' => ({required Object title}) => 'Сканування бібліотеки розпочато для «${title}»',
			'messages.libraryScanFailed' => ({required Object error}) => 'Не вдалося сканувати бібліотеку: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Повторні метадані для «${title}»',
			_ => null,
		} ?? switch (path) {
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Початок оновлення метаданів для «${title}»',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Не вдалося оновити метаданни: ${error}',
			'messages.logoutConfirm' => 'Ви впевнені, що хочете вийти?',
			'messages.noSeasonsFound' => 'Сезон не знайдено',
			'messages.seasonsLoadFailed' => 'Не можна завантажувати сезони',
			'messages.noEpisodesFound' => 'У першому сезоні не знайдено жодних епізодів',
			'messages.noEpisodesFoundGeneral' => 'Епізодів не знайдено',
			'messages.episodesLoadFailed' => 'Не можна завантажувати епізоди',
			'messages.noResultsFound' => 'Нічого не знайдено.',
			'messages.sleepTimerSet' => ({required Object label}) => 'Співальний час встановлений для ${label}',
			'messages.noItemsAvailable' => 'Немає предметів доступних',
			'messages.failedToCreatePlayQueueNoItems' => 'Не вдалося створити гравцю — немає предметів',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Не вдалося ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Перехід до комбінованого гравця.',
			'messages.serverLimitTitle' => 'Playback провалився',
			'messages.serverLimitBody' => 'Серверна помилка (HTTP 500). обмеження ширини смуги/перешифрування, ймовірно, відкинули цю сесію.',
			'messages.mediaUnreadableTitle' => 'Файли недоступні',
			'messages.mediaUnreadableBody' => 'Сервер знайшов цей елемент, але не міг прочитати його файл (HTTP 404). файл, ймовірно, був переміщений, видалений, або його зберігання офлайн.',
			'messages.serverBusyTitle' => 'Потік недоступний',
			'messages.serverBusyBody' => 'Сервер продовжував відмовлятися від потоку цього файлу (HTTP 503). це може бути відновлення, зайнятий, або зберігання файлу може бути офлайн. спробуйте знову в один момент — якщо це продовжується, попросіть власника сервера перевірити сервер і зберігання файлу.',
			'messages.playbackNotAllowedTitle' => 'Playback не дозволяється',
			'messages.playbackNotAllowedBody' => 'Сервер відмовився передавати цей елемент (HTTP 403). Ваш обліковий запис може не мати дозволу на його відтворення, або сервер може дозволяти відтворення тільки на його місцевій мережі.',
			'messages.logsUploaded' => 'Завантажити Logs',
			'messages.logsUploadFailed' => 'Не вдалося завантажити логіки',
			'messages.logId' => 'Ідентифікатор',
			'messages.burnedSubtitlesUseMenu' => 'Підголоси спалюються в цей потік. змінюйте їх з меню підголосів.',
			'messages.noVideoUrl' => 'Відео URL не доступно',
			'messages.playbackNoMediaSources' => 'Сервер не повернув жодних джерел гральних засобів масової інформації',
			'messages.playbackDataNotPrepared' => 'Playback почався до того, як його дані були готові.',
			'messages.streamSelectionUnavailable' => 'Вибір потоку не доступний для цього джерела',
			'messages.streamSelectionFailed' => 'Не можна застосовувати вибрані потоки',
			'messages.trackSelectionNotRemembered' => 'Цей варіант трас застосовується тільки до поточного відтворення.',
			'messages.serverUnavailableForProfile' => 'Сервер не доступний для активного профілю',
			'subtitlingStyling.previewSample' => 'Швидкий коричневий фокс стрибає над лазовим собакою',
			'subtitlingStyling.text' => 'Текст',
			'subtitlingStyling.border' => 'кордони',
			'subtitlingStyling.background' => 'фонтани',
			'subtitlingStyling.fontSize' => 'Розмір шрифту',
			'subtitlingStyling.textColor' => 'Колір тексту',
			'subtitlingStyling.borderSize' => 'Гранична величина',
			'subtitlingStyling.borderColor' => 'Колір кордону',
			'subtitlingStyling.backgroundOpacity' => 'Позашляховик Opacity',
			'subtitlingStyling.backgroundColor' => 'Колір фону',
			'subtitlingStyling.position' => 'Позиція',
			'subtitlingStyling.assOverride' => 'ASS Перевищення',
			'subtitlingStyling.overrideScale' => 'Скелі',
			'subtitlingStyling.overrideForce' => 'Сила',
			'subtitlingStyling.overrideStrip' => 'Зняти стилізм',
			'subtitlingStyling.positionTop' => 'ТОП',
			'subtitlingStyling.positionBottom' => 'Підземний',
			'subtitlingStyling.useMargins' => 'Використання маргінів',
			'subtitlingStyling.useMarginsDescription' => 'Дозвольте текстовим субтитрам у просторі поза відео. Стильовані субтитри можуть зберігати своє оригінальне розташування.',
			'subtitlingStyling.anchorToScreen' => 'Анкор на екрани',
			'subtitlingStyling.anchorToScreenDescription' => 'Показати підзаголовки тексту в чорних смугах нижче відео широкого екрану',
			'subtitlingStyling.bold' => 'Жирний',
			'subtitlingStyling.italic' => 'Італійська',
			'subtitlingStyling.renderResolution' => 'Резолюція Рендер',
			'subtitlingStyling.renderResolutionScreen' => 'Роздільна здатність екрану',
			'subtitlingStyling.renderResolutionVideo' => 'Роздільна здатність відео',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Налаштування передових відеоплеєрів',
			'mpvConfig.presets' => 'Президи',
			'mpvConfig.noPresets' => 'Не збереглися прецеденти',
			'mpvConfig.saveAsPreset' => 'Зберегти як прецедент',
			'mpvConfig.presetName' => 'Назва Пресет',
			'mpvConfig.presetNameHint' => 'Введіть ім\'я для цього пресету',
			'mpvConfig.loadPreset' => 'Завантажити',
			'mpvConfig.deletePreset' => 'Видалити',
			'mpvConfig.presetSaved' => 'Прес-центр врятований',
			'mpvConfig.presetLoaded' => 'Прес-завантаження завантажено',
			'mpvConfig.presetDeleted' => 'Прес-реліз видалений',
			'mpvConfig.confirmDeletePreset' => 'Ви впевнені, що ви хочете видалити цей пресет?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # коментар',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Додати лінію',
			'mpvConfig.removeLine' => 'Зняти лінію',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-контекст і gpu-api ігноруються на Linux: вбудований відео завжди передається через vo=libmpv на відеоповерхні, і gpu-next (який комп\'ютерні відтінки, такі як ArtCNN потрібні) не може працювати вбудований.',
			'dialog.confirmAction' => 'Підтвердити дії',
			'profiles.addPlezyProfile' => 'Додати профіль PlezyNG',
			'profiles.switchingProfile' => 'Профільний перехід...',
			'profiles.deleteThisProfileTitle' => 'Чи можна видалити цей профіль?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Видалити ${displayName}. Підключення залишаться без змін.',
			'profiles.active' => 'Активний',
			'profiles.manage' => 'Управління',
			'profiles.delete' => 'Видалити',
			'profiles.signOut' => 'Вийти',
			'profiles.signOutPlexTitle' => 'Зареєструйтеся на Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Видалити ${displayName} і всі Plex Домашні користувачі?',
			'profiles.signOutPlexDeleteDownloads' => 'Також видаляти завантаження',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Інакше завантаження залишаться на цьому пристрої й знову з’являться, коли ви ввійдете в цей обліковий запис.',
			'profiles.signedOutPlex' => 'Підписано з Plex.',
			'profiles.signOutFailed' => 'Підписання провалилася.',
			'profiles.sectionTitle' => 'Профіль',
			'profiles.summarySingle' => 'Додайте профілі, щоб змішувати управляних користувачів і місцевих ідентифікацій',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} профілі · активний: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} Профіль',
			'profiles.removeConnectionTitle' => 'Відключити зв’язок?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Усунути доступ ${displayName} до ${connectionLabel}. інші профілі зберігають його.',
			'profiles.deleteProfileTitle' => 'Профіль вимкнений?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Усунути ${displayName} та його підключення. сервери залишаються доступними.',
			'profiles.profileNameLabel' => 'Профільне ім\'я',
			'profiles.pinProtectionLabel' => 'PIN захист',
			'profiles.copyAutomationLink' => 'Копіювати Android автоматизаційний посилання',
			'profiles.copyAutomationLinkDescription' => 'Виберіть цей профіль з Android наміру або автоматизації.',
			'profiles.automationLinkCopied' => 'Профіль автоматизації посилання копіюється.',
			'profiles.pinManagedByPlex' => 'PIN керується Plex.Редагувати на plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Для того, щоб вимагати одного, редагуйте домашнього користувача на plex.tv.',
			'profiles.setPin' => 'Налаштування PIN',
			'profiles.setPinTitle' => 'Налаштування PIN',
			'profiles.confirmPinTitle' => 'Підтвердити PIN',
			'profiles.pinSet' => 'Пін Сет',
			'profiles.changePin' => 'Зміни',
			'profiles.removePin' => 'Видалити',
			'profiles.connectionsLabel' => 'Зв\'язки',
			'profiles.add' => 'Додати',
			'profiles.deleteProfileButton' => 'Профіль видалення',
			'profiles.noConnectionsHint' => 'Немає підключень — додайте один для використання цього профілю.',
			'profiles.noConnections' => 'Немає зв\'язків',
			'profiles.plexHomeAccount' => 'Plex Домашній рахунок',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex обліковий запис: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} через ${account}',
			'profiles.connectionDefault' => 'За замовчуванням',
			'profiles.connectionAs' => ({required Object displayName}) => 'Створення ${displayName}',
			'profiles.makeDefault' => 'Зробіть дефолт',
			'profiles.removeConnection' => 'Видалити',
			'profiles.profileRenamed' => 'Профіль перейменований',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Додати до ${displayName}',
			'profiles.borrowExplain' => 'Заощаджуйте зв\'язок іншого профілю. PIN-захищені профілі потребують PIN.',
			'profiles.borrowEmpty' => 'На даний момент немає нічого, що можна позичити.',
			'profiles.borrowEmptySubtitle' => 'Перш за все, підключіть Plex, Jellyfin, або Emby до іншого профілю.',
			'profiles.borrowLoadFailed' => 'Доступні зв\'язки не можуть бути завантажені. спробуйте знову.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'від ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Заощаджені зв\'язки',
			'profiles.borrowFailed' => 'У зв\'язку з тим, що не вдалося взяти кредит.',
			'profiles.incorrectPin' => 'Неправильний PIN',
			'profiles.incorrectPinTryAgain' => 'Помилковий PIN, будь ласка, спробуйте ще раз.',
			'profiles.sourceProfileMissingParentAccount' => 'Профіль джерела не вистачає свого батьківського рахунку.',
			'profiles.failedToLoadHomeUsers' => 'Не можна завантажувати ваші користувачі Plex. перевірте зв\'язок і спробуйте знову.',
			'profiles.failedToVerifyPin' => 'Не вдалося перевірити PIN.',
			'profiles.newProfile' => 'Новий профіль',
			'profiles.profileNameHint' => 'Наприклад, гості, діти, сімейний номер',
			'profiles.pinProtectionOptional' => 'Захист PIN (за винятком)',
			'profiles.pinExplain' => '4-цифровий PIN необхідний для перетворення профілів.',
			'profiles.continueButton' => 'Продовжуйте',
			'profiles.pinsDontMatch' => 'PIN не відповідає',
			'profiles.tokenIdentityMismatch' => 'Профільний токен Plex розв\'язаний на несподіваний сервер',
			'profiles.settingsLocked' => 'Налаштування заблоковані для цього профілю.',
			'profiles.unlockSettings' => 'Відключення налаштувань',
			'profiles.showExploreForProfile' => 'Показати Пошук для цього профілю',
			'profiles.showExploreForProfileDescription' => 'Вимкніть, щоб видалити Explore з навігації цього профілю.',
			'connections.sectionTitle' => 'Зв\'язки',
			'connections.addConnection' => 'Додати зв\'язок',
			'connections.addConnectionSubtitleNoProfile' => 'Зареєструйтесь за допомогою Plex або підключіться до сервера Jellyfin або Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Додати до ${displayName}: Plex, Jellyfin, Emby, або іншого профільного зв\'язку',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Завершилася сесія за ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Завершилася сесія для серверів ${count}',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} відмовляється отримати доступ до цього облікового запису',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} сервери відмовилися від доступу до цього облікового запису',
			'connections.signInAgain' => 'Підписуйтесь знову',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Реєстрація ${product} зв\'язок',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Додати або видалити URL-адреси для ${serverName}. PlezyNG буде використовувати доступний URL з найнижчою затримкою.',
			'accountPreferences.sectionTitle' => 'Переваги облікового запису',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Аудіо, субтитри та варіанти бібліотеки збереглися на ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Аудіо, субтитри та варіанти бібліотеки збережені на акаунтах ${count}',
			'accountPreferences.pickAccount' => 'Кожен обліковий запис зберігає свої власні переваги. виберіть один для редагування.',
			'accountPreferences.storedOnAccount' => 'Ці варіанти зберігаються на самому обліковому записі, тому кожна програма, що підписується на нього, використовує їх — в тому числі PlezyNG на ваших інших пристроях.',
			'accountPreferences.noAccounts' => 'Конфігурувати не можна',
			'accountPreferences.noAccountsHint' => 'Зареєструйтесь на Plex, або підключіться до сервера Jellyfin або Emby, і переваги, що зберігаються на цьому рахунку, відображаються тут.',
			'accountPreferences.unavailable' => 'Не можна отримати доступ до цього рахунку',
			'accountPreferences.loadFailed' => 'Я не можу завантажити ці переваги',
			'accountPreferences.noPreference' => 'Немає переваг',
			'accountPreferences.notSet' => 'Не встановлюйте',
			'accountPreferences.groups.audioAndSubtitles' => 'Аудіо та субтитри',
			'accountPreferences.groups.libraryDisplay' => 'Медіатека',
			'accountPreferences.groups.personalMedia' => 'Персональні медіа',
			'accountPreferences.preferredAudioLanguage' => 'Бажана мова аудіо',
			'accountPreferences.autoSelectAudio' => 'Вибір звуку за мовою',
			'accountPreferences.autoSelectAudioDescription' => 'Відключено зберігає будь-який аудіо відстеження файлу знаків за замовчуванням.',
			'accountPreferences.preferredSubtitleLanguage' => 'Бажана мова субтитрів',
			'accountPreferences.subtitleMode' => 'Завантажити субтитри',
			'accountPreferences.subtitleModes.none' => 'Ручно вибрані',
			'accountPreferences.subtitleModes.noneDescription' => 'Ніколи не перетворюйте субтитри самостійно.',
			'accountPreferences.subtitleModes.defaultMode' => 'Слідкуйте за флагами',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Використовуйте стандартні та примусові прапори, що зберігаються на кожному підзаголовному трасі.',
			'accountPreferences.subtitleModes.always' => 'Завжди дозволяється',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Натисніть на підзаголовок в улюбленому мові, коли він існує.',
			'accountPreferences.subtitleModes.onlyForced' => 'Тільки примусові субтитри',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Завантажуйте тільки смуги, зазначені як примусові.',
			'accountPreferences.subtitleModes.smart' => 'Завантажити аудіо з іноземним',
			'accountPreferences.subtitleModes.smartDescription' => 'Зверніть субтитри тільки тоді, коли аудіо знаходиться на іншому мові.',
			'accountPreferences.subtitleAccessibility' => 'СДГ підзаголовок',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Попередня статтяКто чего не любить SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Популярні SDH субтитри',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Тільки субтитри SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Тільки не-SDH субтитри',
			'accountPreferences.forcedSubtitles' => 'Примусові субтитри',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Потрібні непідвищені субтитри',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Потрібні підзаголовки',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Тільки примусові субтитри',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Тільки безпідставні субтитри',
			'accountPreferences.displayMissingEpisodes' => 'Показати відсутні епізоди',
			'accountPreferences.displayMissingEpisodesDescription' => 'Список епізодів, про які сервер знає, але у нього немає файлів.',
			'accountPreferences.hidePlayedInLatest' => 'Сховати переглянуті речі в останній',
			'accountPreferences.hidePlayedInLatestDescription' => 'Залишити елементи, які ви вже переглянули з останніх рядків сервера.',
			'accountPreferences.displayCollectionsView' => 'Показати зображення колекцій',
			'accountPreferences.displayCollectionsViewDescription' => 'Подайте перегляд колекцій на сервері разом з бібліотеками.',
			'accountPreferences.rewatchingInNextUp' => 'Продовжуйте переглянути шоу в Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'Після того, як ви закінчите шоу, почніть знову, а Next Up слідує за переглядом, а не відкидає шоу.',
			'accountPreferences.watchedIndicator' => 'Переглянуті показники',
			'accountPreferences.watchedIndicatorOptions.none' => 'Ніколи',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Фільми та телевізійні шоу',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Тільки фільми',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Телевізійні шоу тільки',
			'accountPreferences.mediaReviewsVisibility' => 'Рейтинг & рецензії',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Користувачі та критики',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Користувачі тільки',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Тільки критики',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Схована',
			'discover.title' => 'Відкриття',
			'discover.noContentAvailable' => 'Немає контенту доступного',
			'discover.addMediaToLibraries' => 'Додайте деякі медіа до своїх бібліотек',
			'discover.continueWatching' => 'Продовжити перегляд',
			'discover.continueWatchingIn' => ({required Object library}) => 'Продовжувати дивитися в ${library}',
			'discover.nextUp' => 'Далі',
			'discover.nextUpIn' => ({required Object library}) => 'Наступна статтяУкрзалізниця ${library}',
			'discover.recentlyAdded' => 'Нещодавно додані',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Нещодавно додано в ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Найсвіжіші альбоми в ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Нещодавно зіграно в ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Найбільше переглянуто в ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'С${season}Е${episode}',
			'discover.overview' => 'Опис',
			'discover.cast' => 'Каст',
			'discover.findNext.title' => 'Що обрати далі?',
			'discover.findNext.open' => 'Що обрати далі?',
			'discover.findNext.anyTime' => 'Без обмеження часу',
			'discover.findNext.timeAvailable' => 'Скільки у вас часу?',
			'discover.findNext.filters' => 'Оберіть щось для цієї миті',
			'discover.findNext.watch' => 'Дивитися',
			'discover.findNext.listen' => 'Слухати',
			'discover.findNext.read' => 'Читати',
			'discover.findNext.finishable' => ({required Object duration}) => 'Час до завершення: ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Орієнтовна тривалість: ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Наступний розділ · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Загалом ${duration}',
			'discover.findNext.timingVaries' => 'Тривалість може відрізнятися',
			'discover.findNext.notNow' => 'Не зараз',
			'discover.findNext.swipeHint' => 'Змахніть обкладинку в бік стрілки або скористайтеся кнопками нижче.',
			'discover.findNext.saved' => 'Збережені рекомендації',
			'discover.findNext.savedCount' => ({required Object count}) => 'Збережені рекомендації · ${count}',
			'discover.findNext.undo' => 'Скасувати дію',
			'discover.findNext.details' => 'Докладніше',
			'discover.findNext.noPicks' => 'Поки немає з чого вибирати',
			'discover.findNext.noPicksHint' => 'Під’єднайте бібліотеку або додайте джерело медіа, щоб почати.',
			'discover.findNext.noMatches' => 'Нічого підхожого для цієї миті',
			'discover.findNext.noMatchesHint' => 'Спробуйте інший вид медіа або виділіть більше часу.',
			'discover.findNext.allDone' => 'Ви переглянули всі рекомендації',
			'discover.findNext.allDoneHint' => 'Створіть нову добірку, щоб знову побачити ці варіанти.',
			'discover.findNext.refresh' => 'Знайти іншу добірку',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Джерело: ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Бібліотека: ${library}',
			'discover.findNext.ownedReason' => 'З вашої бібліотеки',
			'discover.findNext.liveNow' => 'Зараз в ефірі',
			'discover.findNext.watchLive' => 'Дивитися наживо',
			'discover.findNext.filterAnything' => 'Будь-який вид',
			'discover.findNext.filterWatch' => 'Дивитися',
			'discover.findNext.filterListen' => 'Слухати',
			'discover.findNext.filterRead' => 'Читати',
			'discover.findNext.twentyMinutes' => '20 хв',
			'discover.findNext.fortyFiveMinutes' => '45 хв',
			'discover.findNext.ninetyMinutes' => '90 хв',
			'discover.findNext.apply' => 'Застосувати',
			'discover.findNext.openFailed' => 'Цей варіант більше недоступний. Оновіть, щоб перевірити ще раз.',
			'discover.findNext.changeFailed' => 'Не вдалося зберегти зміну. Спробуйте ще раз.',
			'discover.findNext.savedLimit' => 'Список збережених рекомендацій заповнений. Вилучіть одну рекомендацію, щоб зберегти іншу.',
			'discover.findNext.chooseHint' => 'Відкрийте твір, збережіть на потім або пропустіть.',
			'discover.findNext.howItWorks' => 'Як це працює',
			'discover.findNext.notNowHelp' => 'Пропустіть цей твір наразі. Він залишиться у вашій бібліотеці.',
			'discover.findNext.saveHelp' => 'Додайте його до збережених добірок цього профілю на цьому пристрої. Збереження не завантажує твір.',
			'discover.findNext.openHelp' => 'Виберіть обкладинку для перегляду подробиць. Основна кнопка дає змогу відтворити, читати або відкрити твір.',
			'discover.findNext.controlsHelp' => 'Клавіатура або пульт: виберіть кнопку й натисніть Enter або кнопку вибору. Скасування відновлює останній вибір.',
			'discover.findNext.artworkLoading' => 'Завантаження обкладинки…',
			'discover.findNext.artworkUnavailable' => 'Обкладинка недоступна',
			'discover.findNext.savedFeedback' => 'Додано до збережених добірок',
			'discover.findNext.skippedFeedback' => 'Наразі пропущено',
			'discover.findNext.releaseToConfirm' => 'Відпустіть для підтвердження',
			'discover.findNext.remoteHint' => 'Фокус на обкладинці: ← / → вибір · Кнопка вибору: подробиці · ↑ / ↓ переміщення фокусу',
			'discover.extras' => 'Трейлери та екстраси',
			'discover.studio' => 'Студія',
			'discover.rating' => 'Рейтинг',
			'discover.director' => 'Режисер',
			'discover.directors' => 'Режисери',
			'discover.movie' => 'Фільми',
			'discover.tvShow' => 'Телевізійне шоу',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} хвилини',
			'discover.moreLikeThis' => 'Подібні до цього',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назва', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назви', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назв', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} назви', ), 
			'discover.person.born' => 'народжується',
			'discover.person.died' => 'Смерть',
			'discover.person.birthplace' => 'Місце народження',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (старість ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (старість ${age})',
			'errors.searchFailed' => ({required Object error}) => 'Пошук провалився: ${error}',
			'errors.searchUnavailable' => 'Пошук не міг досягти жодного медіа-сервера.',
			'errors.connectionTimeout' => ({required Object context}) => 'Час очікування з’єднання вичерпано під час завантаження ${context}',
			'errors.connectionFailed' => 'Неможливість підключення до медіа-сервера',
			'errors.unableToLoad' => ({required Object context}) => 'Не можна завантажувати ${context}. будь ласка, спробуйте знову.',
			'errors.noClientAvailable' => 'Клієнт не доступний',
			'errors.pleaseEnterToken' => 'Будь ласка, введіть токен',
			'errors.invalidToken' => 'Недійсний токен',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Невідомий токен: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Не вдалося перейти до ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Не вдалося видалити ${displayName}',
			'errors.failedToRate' => 'Не можна оновити рейтинг',
			'errors.reasonTimedOut' => 'Зв\'язок тимчасовий',
			'errors.reasonUnreachable' => 'Сервер не може бути доступний',
			'errors.reasonRefused' => 'Сервер відмовився від запиту',
			'errors.reasonNotFound' => 'Продукт більше не знаходиться на сервері.',
			'errors.reasonServerError' => 'Сервер повідомив про помилку',
			'errors.reasonCancelled' => 'Заява була скасована',
			'errors.reasonUnexpected' => 'Несподівана помилка сталася',
			'libraries.playRandomMovie' => 'Грати в випадковий фільм',
			'libraries.randomPickFailed' => 'Я не можу вибрати фільм з цієї бібліотеки.',
			'libraries.title' => 'Медіатеки',
			'libraries.fallbackTitle' => 'Медіатека',
			'libraries.scanLibraryFiles' => 'Сканування бібліотечних файлів',
			'libraries.scanLibrary' => 'Сканувати медіатеку',
			'libraries.analyze' => 'Аналіз',
			'libraries.analyzeLibrary' => 'Аналіз бібліотеки',
			'libraries.refreshMetadata' => 'Оновити метадані',
			'libraries.emptyTrash' => 'Порожній траш',
			'libraries.emptyingTrash' => ({required Object title}) => 'Попередня статтяКто чего не ест – ${title}...',
			'libraries.trashEmptied' => ({required Object title}) => 'Попередня статтяКто чего не ест – ${title}',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Не вдалося встановити порожній сміттєзвалище: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Аналіз «${title}»',
			'libraries.analysisStarted' => ({required Object title}) => 'Аналіз розпочався для «${title}»',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Не вдалося проаналізувати бібліотеку: ${error}',
			'libraries.noLibrariesFound' => 'Бібліотеки не знайдено',
			'libraries.allLibrariesHidden' => 'Всі бібліотеки приховані',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Схована бібліотека (${count})',
			'libraries.thisLibraryIsEmpty' => 'Ця бібліотека порожня',
			'libraries.noItemsMatchFilters' => 'Ніякі елементи не відповідають активним фільтрам',
			'libraries.resetFilters' => 'Скинути фільтри',
			'libraries.all' => 'Всі',
			'libraries.clearAll' => 'Все чітко',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Ви впевнені, що ви хочете сканувати "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Ви впевнені, що ви хочете проаналізувати "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Ви впевнені, що ви хочете оновити метаданни для "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Ви впевнені, що ви хочете порожній сміттєзвалище для "${title}"?',
			'libraries.manageLibraries' => 'Управління бібліотеками',
			'libraries.sort' => 'Сортувати',
			'libraries.sortBy' => 'Сортувати за',
			'libraries.filters' => 'Фільтри',
			'libraries.confirmActionMessage' => 'Ви впевнені, що хочете здійснити цю діяльність?',
			'libraries.showLibrary' => 'Показати бібліотеку',
			'libraries.hideLibrary' => 'Сховати бібліотеку',
			'libraries.libraryOptions' => 'Бібліотечні варіанти',
			'libraries.content' => 'Бібліотека контент',
			'libraries.selectLibrary' => 'Вибір бібліотеки',
			'libraries.filtersWithCount' => ({required Object count}) => 'Фільтри (${count})',
			'libraries.noRecommendations' => 'Немає доступних рекомендацій',
			'libraries.noCollections' => 'Ніяких колекцій в цій бібліотеці',
			'libraries.noFoldersFound' => 'Не знайдено жодних паперів',
			'libraries.folders' => 'Теки',
			'libraries.tabs.recommended' => 'Рекомендовані',
			'libraries.tabs.browse' => 'Огляд',
			'libraries.tabs.collections' => 'Колекції',
			'libraries.tabs.playlists' => 'Плейлисти',
			'libraries.groupings.title' => 'Груповання',
			'libraries.groupings.all' => 'Всі',
			'libraries.groupings.movies' => 'Фільми',
			'libraries.groupings.shows' => 'Серіали',
			'libraries.groupings.seasons' => 'Сезони',
			'libraries.groupings.episodes' => 'Епізоди',
			'libraries.groupings.artists' => 'Виконавці',
			'libraries.groupings.albums' => 'Альбоми',
			'libraries.groupings.tracks' => 'Доріжки',
			'libraries.groupings.folders' => 'Теки',
			'libraries.filterCategories.genre' => 'Жанр',
			'libraries.filterCategories.year' => 'Рік',
			'libraries.filterCategories.contentRating' => 'Рейтинг контенту',
			'libraries.filterCategories.tag' => 'Тег',
			'libraries.filterCategories.unwatched' => 'Неоцінений',
			'libraries.filterCategories.unplayed' => 'Непрогране',
			'libraries.filterCategories.favorites' => 'Обрані',
			'libraries.filterCategories.filePath' => 'Файловий шлях',
			'libraries.sortLabels.title' => 'Назва',
			'libraries.sortLabels.dateAdded' => 'Дата додавання',
			'libraries.sortLabels.releaseDate' => 'Дата випуску',
			'libraries.sortLabels.rating' => 'Рейтинг',
			'libraries.sortLabels.communityRating' => 'Рейтинг спільноти',
			'libraries.sortLabels.criticRating' => 'Критичний рейтинг',
			'libraries.sortLabels.userRating' => 'Користувач рейтингу',
			'libraries.sortLabels.datePlayed' => 'Дата відтворення',
			'libraries.sortLabels.playCount' => 'Кількість відтворень',
			'libraries.sortLabels.productionYear' => 'Рік виробництва',
			'libraries.sortLabels.runtime' => 'Тривалість',
			'libraries.sortLabels.officialRating' => 'Офіційний рейтинг',
			'libraries.sortLabels.premiereDate' => 'Дата прем’єри',
			'libraries.sortLabels.startDate' => 'Початок дати',
			'libraries.sortLabels.airTime' => 'Час етеру',
			'libraries.sortLabels.studio' => 'Студія',
			'libraries.sortLabels.random' => 'Випадковий',
			'libraries.sortLabels.dateShared' => 'Дата поділяється',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Останній епізод Air Date',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Останній епізод Дата Додано',
			'libraries.sortLabels.dateDownloaded' => 'Дата завантаження',
			'libraries.sortLabels.size' => 'Розмір',
			'libraries.sortLabels.library' => 'Медіатека',
			'libraries.advancedFilters.include' => 'Включити',
			'libraries.advancedFilters.exclude' => 'Виключити',
			'libraries.advancedFilters.any' => 'будь-який',
			'libraries.advancedFilters.yes' => 'Так',
			'libraries.advancedFilters.no' => 'Ні',
			'libraries.advancedFilters.not' => ({required Object value}) => 'не ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} вибрано',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} виключено',
			'libraries.advancedFilters.searchValues' => 'Пошукові цінності',
			'libraries.advancedFilters.noValues' => 'Немає цінностей',
			'libraries.advancedFilters.matchContains' => 'контейнери',
			'libraries.advancedFilters.matchNotContains' => 'Не містить',
			'libraries.advancedFilters.matchIs' => 'І є',
			'libraries.advancedFilters.matchIsNot' => 'Не є',
			'libraries.advancedFilters.matchBeginsWith' => 'Починається з',
			'libraries.advancedFilters.matchEndsWith' => 'Закінчується з',
			'libraries.advancedFilters.textHint' => 'Тип до матчу',
			'libraries.advancedFilters.from' => 'від',
			'libraries.advancedFilters.to' => 'до',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} до ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} і вище',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'До ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Останні ${count} днів',
			'libraries.advancedFilters.dateLastYear' => 'минулого року',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Вік понад ${count} днів',
			'libraries.advancedFilters.dateOlderThanYear' => 'старше 1 року',
			'libraries.selection.selectItems' => 'Вибір предметів',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} вибрано',
			'libraries.selection.actions' => 'Акції вибору',
			'libraries.selection.confirmDescendants' => 'Це змінює всі епізоди у вибраних виставках і сезонах.',
			'libraries.selection.confirmUnwatched' => 'Це також очищає прогрес відтворення для вибраних елементів.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Вибрані пункти: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Оновлені пункти: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Оновлено ${succeeded}; не вдалося ${failed}. Не вдалося залишити вибір.',
			'about.title' => 'Про',
			'about.openSourceLicenses' => 'Відкритий код ліцензій',
			'about.versionLabel' => ({required Object version}) => 'Версія ${version}',
			'about.appDescription' => 'Красивий клієнт Plex, Jellyfin і Emby для Flutter',
			'about.viewLicensesDescription' => 'Переглянути ліцензії на бібліотеки третьої сторони',
			'about.privacyPolicy' => 'Політика конфіденційності',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Немає серверів для ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Завантаження серверів: ${error}',
			'serverSelection.noValidServers' => 'На цьому обліковому записі не знайдено жодного сервера.',
			'hubDetail.title' => 'Назва',
			'hubDetail.releaseYear' => 'Рік випуску',
			'hubDetail.dateAdded' => 'Дата додавання',
			'hubDetail.rating' => 'Рейтинг',
			'hubDetail.noItemsFound' => 'Не знайдено предметів',
			'logs.clearLogs' => 'Чистий лог',
			'logs.copyLogs' => 'Копіювати логіки',
			'logs.uploadLogs' => 'Завантажити Logs',
			'logs.saveLogs' => 'Зберегти логі до файлів',
			'logs.logsSaved' => ({required Object path}) => 'Зареєстровано до ${path}',
			'logs.saveLogsFailed' => 'Я не можу зберегти файл.',
			'detail.endsAt' => ({required Object time}) => 'Завершився на ${time}',
			'startup.failedTitle' => 'PlezyNG не може почати',
			'startup.failedBody' => 'Щось пройшло неправильно під час стартапу. деталі нижче визначають, що не вдалося.',
			'startup.failedBodyRepairable' => 'Збережений файл налаштувань PlezyNG пошкоджено. Перед запуском програми його потрібно відновити. Повторна спроба не допоможе — виберіть відновлення сховища.',
			'startup.phaseLabel' => 'Крок',
			'startup.showDetails' => 'Покажіть деталі',
			'startup.hideDetails' => 'Сховати деталі',
			'startup.copyDetails' => 'Копіювати деталі',
			'startup.detailsCopied' => 'Детальніше Копіювати на Clipboard',
			'startup.uploadDetails' => 'Завантажити деталі',
			'startup.repairStorage' => 'Ремонт зберігання',
			'startup.repairTitle' => 'Поправка зберіганих даних?',
			'startup.repairBodyCommon' => 'Файл налаштувань PlezyNG пошкоджено й неможливо прочитати. Відновлення скине всі налаштування до типових значень.',
			'startup.repairBodyOneCredential' => 'Дані одного зі збережених входів пошкоджено й неможливо прочитати. Відновлення видалить лише їх; решта налаштувань залишиться без змін.',
			'startup.repairBodySignInsKept' => 'Вхід на сервери та в профілі має зберегтися.',
			'startup.repairBodySignInsLost' => 'Ключ, що захищає збережені дані входу, неможливо відновити з цього файлу. Тому доведеться знову ввійти на кожен сервер і в кожен профіль. Нічого на медіасервері не зміниться.',
			'startup.repairBodySessionsUncertain' => 'Дані сервісів відстеження (MAL, AniList, Simkl, Trakt) і Seerr зберігаються окремо та можуть як зберегтися, так і зникнути. PlezyNG точно повідомить, які дані вдалося зберегти.',
			'startup.repairConfirm' => 'Ремонт',
			'startup.repairSucceeded' => 'Зберігання відремонтовано',
			'startup.repairNeedsRestart' => 'Зберігання відремонтовано — необхідне відновлення',
			'startup.restartRequiredBody' => 'Ваші дані відновлено, але PlezyNG потрібно перезапустити, щоб ними скористатися. Закрийте PlezyNG і відкрийте знову.',
			'startup.quitPlezy' => 'Завантажити PlezyNG',
			'startup.repairFailed' => 'Поправка провалилася',
			'startup.repairKeptSignIns' => 'Вхід на сервери та в профілі досі активний.',
			'startup.repairLostSignIns' => 'Не вдалося відновити ключ, що захищає збережені дані входу. Потрібно знову ввійти на кожен сервер і в кожен профіль.',
			'startup.repairLostSessions' => 'Принаймні один тракер або Seerr зв\'язок втрачено і потрібно відновити зв\'язок.',
			'startup.backupTitle' => 'Копія пошкодженого файлу зберігається',
			'startup.backupWarning' => 'Вона містить ваші аутентифікації. не завантажуйте або не ділитеся.',
			'startup.deleteBackup' => 'Зняти копію',
			'startup.backupDeleted' => 'Копія видалена',
			'startup.previousFailureTitle' => 'PlezyNG не вдалося почати останній раз',
			'licenses.relatedPackages' => 'Пов\'язані пакети',
			'licenses.license' => 'Ліцензія',
			'licenses.licenseNumber' => ({required Object number}) => 'Ліцензія ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} ліцензії',
			'navigation.libraries' => 'Медіатеки',
			'navigation.downloads' => 'Завантаження',
			'navigation.liveTv' => 'Прямий ефір',
			'navigation.explore' => 'Вивчення',
			'explore.mdblistShelves.manage' => 'Управління розшуком шахів',
			'explore.mdblistShelves.manageDescription' => 'Виберіть та організовуйте списки з вашого облікового запису MDBList',
			'explore.mdblistShelves.description' => 'Виберіть публічні фільми та телевізійні списки з вашого облікового запису MDBList. створити або копіювати списки на MDBList, а потім оновити.',
			'explore.mdblistShelves.selected' => 'Вибрані стільці',
			'explore.mdblistShelves.available' => 'Список доступних рахунків',
			'explore.mdblistShelves.noLists' => 'Немає публічних фільмів або телевізійних списків повернуто. Створіть або копіюйте список на MDBList, а потім оновлюйте.',
			'explore.mdblistShelves.displayName' => 'Шелф показує ім\'я',
			'explore.mdblistShelves.nameHint' => 'Залишити білий, щоб використовувати назву джерело списку.',
			'explore.mdblistShelves.add' => 'Додайте шаф',
			'explore.mdblistShelves.save' => 'Зберегти шахи',
			_ => null,
		} ?? switch (path) {
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Повернутись ${title}',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Повернутись ${title} вниз',
			'explore.mdblistShelves.unavailable' => 'Цей список недоступний. Витягніть або видаліть його шаф в налаштуваннях.',
			'explore.mdblistShelves.rateLimited' => 'MDBList Заявка ліміт досягнута. будь ласка, відкликайте пізніше.',
			'explore.mdblistShelves.loadFailed' => 'Не можна завантажувати шари. перевірте зв\'язок і відкликайте.',
			'explore.mdblistShelves.saveFailed' => 'Я не можу врятувати стільці, будь ласка, відмовляйтеся.',
			'explore.mdblistShelves.accountChanged' => 'Профіль або обліковий запис змінилися. знову відкрити ці налаштування.',
			'explore.mdblistShelves.settingsUnreadable' => 'Збережені шари не можуть бути прочитані. Виберіть списки знову, щоб замінити ці налаштування.',
			'explore.title' => 'Вивчення',
			'explore.selectSource' => 'Вибір джерела',
			'explore.rows.watchlist' => 'Застереження',
			'explore.rows.recommendedMovies' => 'Рекомендовані фільми',
			'explore.rows.recommendedShows' => 'Рекомендовані покази',
			'explore.rows.trendingMovies' => 'Трендовий фільм',
			'explore.rows.trendingShows' => 'Трендовий показ',
			'explore.rows.popularMovies' => 'Популярні фільми',
			'explore.rows.popularShows' => 'Популярні шоу',
			'explore.rows.trendingAnime' => 'Трендовий аніме',
			'explore.rows.suggestedAnime' => 'Пропонований аніме',
			'explore.rows.airingAnime' => 'Анімаційний анімаційний',
			'explore.rows.popularAnime' => 'Найпопулярніші аніме',
			'explore.rows.trending' => 'Тенденції',
			'explore.rows.upcomingMovies' => 'Наступні фільми',
			'explore.rows.upcomingShows' => 'Наступні покази',
			'explore.status.airing' => 'Авіація',
			'explore.status.ended' => 'Завершено',
			'explore.status.canceled' => 'скасовано',
			'explore.status.upcoming' => 'Скоро',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серія', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серії', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серій', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серії', ), 
			'explore.cast' => 'Каст',
			'explore.characters' => 'персонажів',
			'explore.addToWatchlist' => 'Додати до Watchlist',
			'explore.removeFromWatchlist' => 'Видалення з Watchlist',
			'explore.addedToWatchlist' => 'Додано до watchlist',
			'explore.removedFromWatchlist' => 'Вилучено з обсерваторії',
			'explore.watchlistUpdateFailed' => 'Не можна оновити обсерваторію',
			'explore.watchlistNoMatch' => 'Цей елемент не може відповідати списку спостережень',
			'explore.notInLibrary' => 'Не в бібліотеці',
			'explore.inTheseLibraries' => 'У цих бібліотеках',
			'explore.checkingLibrary' => 'Перевірте свою бібліотеку.',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: 'Не можна перевірити сервер ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', other: 'Не можна перевірити сервери ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', ), 
			'explore.emptyTitle' => 'Тут ще нічого',
			'explore.emptyMessage' => ({required Object source}) => 'Повернення з ${source} з\'явиться тут, як тільки вони мають вміст.',
			'explore.searchHint' => ({required Object source}) => 'Пошук ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Немає результатів для «${query}»',
			'explore.searchPrompt' => ({required Object source}) => 'Пошук фільмів і шоу на ${source}.',
			'explore.searchFailed' => 'Пошук провалився. перевірте зв\'язок і спробуйте знову.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} Популярні',
			'explore.badge.rankAiring' => ({required Object n}) => 'В ефірі: №${n}',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} переглянуто',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} Трендінг',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} в ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} переглядів',
			'explore.badge.available' => 'Доступно',
			'explore.badge.partiallyAvailable' => 'Частково доступні',
			'explore.badge.availableIn4k' => '4K доступні',
			'explore.badge.requested' => 'Запрошені',
			'explore.badge.pendingApproval' => 'Залишається затвердження',
			'explore.badge.processing' => 'обробка',
			'explore.badge.declined' => 'Декілька',
			'explore.badge.requestFailed' => 'Заява провалилася',
			'explore.badge.requested4k' => 'Запрошуємо 4K',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} сезони',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Епізод ${episode} в ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Наступна стаття ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} Епс',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} хв/п',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} перераховано',
			'explore.stats.viewersDay' => ({required Object n}) => 'Переглянули сьогодні: ${n}',
			'explore.stats.viewersWeek' => ({required Object n}) => 'Переглянули цього тижня: ${n}',
			'explore.stats.viewersMonth' => ({required Object n}) => 'Переглянули цього місяця: ${n}',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} переглядів цього року',
			'explore.stats.viewersAllTime' => ({required Object n}) => 'Глядачів: ${n}',
			'explore.stats.planning' => ({required Object n}) => '${n} Планується переглянути',
			'explore.stats.favorited' => ({required Object n}) => '${n} улюблених',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} відмінили його',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментар', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментарі', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментарів', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} коментарі', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} голосів',
			'explore.stats.watching' => ({required Object n}) => '${n} переглянути',
			'explore.stats.completed' => ({required Object n}) => '${n} Завершено',
			'explore.stats.onHold' => ({required Object n}) => '${n} на зберігання',
			'explore.stats.dropped' => ({required Object n}) => '${n} вилучено',
			'explore.season.winter' => 'Зимовий',
			'explore.season.spring' => 'Весна',
			'explore.season.summer' => 'Літо',
			'explore.season.fall' => 'Падіння',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'ТБ',
			'explore.format.tvShort' => 'Телевізор короткий',
			'explore.format.movie' => 'Фільми',
			'explore.format.special' => 'Особливості',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Музика',
			'explore.format.other' => 'Інше',
			'explore.sourceMaterial.original' => 'Оригінальна',
			'explore.sourceMaterial.manga' => 'Манга',
			'explore.sourceMaterial.lightNovel' => 'Світло роман',
			'explore.sourceMaterial.novel' => 'Роман',
			'explore.sourceMaterial.visualNovel' => 'Візуальний роман',
			'explore.sourceMaterial.game' => 'Ігри',
			'explore.sourceMaterial.webComic' => 'WEB Комедія',
			'explore.sourceMaterial.musicRelease' => 'Музика',
			'explore.sourceMaterial.otherMedia' => 'Інше',
			'explore.creditRole.actor' => 'Актор',
			'explore.creditRole.director' => 'Режисер',
			'explore.creditRole.writer' => 'Сценарист',
			'explore.creditRole.producer' => 'Продюсер',
			'explore.creditRole.creator' => 'Творець',
			'explore.creditRole.composer' => 'Композитор',
			'explore.relation.prequel' => 'Прокляття',
			'explore.relation.sequel' => 'Секель',
			'explore.relation.sideStory' => 'Побічна історія',
			'explore.relation.spinOff' => 'Спін-офф',
			'explore.relation.alternativeVersion' => 'Альтернативна версія',
			'explore.relation.summary' => 'резюме',
			'explore.relation.parentStory' => 'Історія батьків',
			'explore.relation.adaptation' => 'адаптація',
			'explore.relation.other' => 'пов\'язані',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Авіакомпанія Airs ${day} на ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Авіакомпанія Airs ${day} на ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Оригінальний заголовок',
			'explore.detail.alsoKnownAs' => 'Також відомий як',
			'explore.detail.studios' => 'Студії',
			'explore.detail.country' => 'країна',
			'explore.detail.language' => 'Мова',
			'explore.detail.released' => 'звільнений',
			'explore.detail.physicalRelease' => 'На дисковому',
			'explore.detail.ended' => 'Завершено',
			'explore.detail.addedOn' => ({required Object date}) => 'Додано ${date}',
			'explore.detail.yourRating' => 'Ваш рейтинг',
			'explore.detail.budget' => 'Бюджет',
			'explore.detail.revenue' => 'Букш офіс',
			'explore.detail.contentAdvisory' => 'Вік керівництва',
			'explore.detail.tags' => 'Мітки',
			'explore.detail.revealSpoilerTags' => 'Завантажити Spoiler Tags',
			'explore.detail.links' => 'Ліва',
			'explore.detail.watchOn' => 'Дивіться на',
			'explore.detail.watchTrailer' => 'Дивитись трейлер',
			'explore.detail.openOn' => ({required Object site}) => 'Відкритий на ${site}',
			'explore.detail.crew' => 'Екіпаж',
			'explore.detail.ratings' => 'Рейтинг',
			'explore.detail.schedule' => 'Розклад',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: 'Рекомендується користувачем ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', other: 'Рекомендують користувачі: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Рекомендується ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Офіційно ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} не опубліковано',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Рекомендується ${percent} відвідувачів',
			'explore.detail.relatedTitles' => 'Співвідношення титулів',
			'explore.detail.background' => 'фонтани',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результат', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результати', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результатів', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} результати', ), 
			'liveTv.title' => 'Прямий ефір',
			'liveTv.guide' => 'Телегід',
			'liveTv.noChannels' => 'Без каналів',
			'liveTv.noDvr' => 'Ніякого DVR не встановлюється на сервері',
			'liveTv.serverUnavailable' => 'Телевізійний сервер не доступний.',
			'liveTv.serverNotConnected' => 'Телевізійний сервер не підключений.',
			'liveTv.noPrograms' => 'Програма даних не доступна',
			'liveTv.liveStreamFailed' => 'Живий потік не вдався',
			'liveTv.unknownProgram' => 'Невідома програма',
			'liveTv.timelineLiveProgram' => 'Програма в прямому ефірі (перегляд може бути поза цією програмою)',
			'liveTv.timelineBuffer' => 'Буфферний час',
			'liveTv.timelineUnavailable' => 'Тимчасовий термін недоступний',
			'liveTv.timelineEstimated' => 'Оцінений Playback',
			'liveTv.timelinePending' => 'Пошук',
			'liveTv.timelineStale' => 'Графік може бути застарілим',
			'liveTv.unknownHub' => 'Невідоме',
			'liveTv.unknownError' => 'Невідома помилка',
			'liveTv.channelNumber' => ({required Object number}) => 'Канал ${number}',
			'liveTv.unknownChannel' => 'Невідомий канал',
			'liveTv.live' => 'Наживо',
			'liveTv.premiereBadge' => 'Новий',
			'liveTv.reloadGuide' => 'Завантажити Руководство',
			'liveTv.searchGuide' => 'Пошуковий посібник',
			'liveTv.searchHint' => 'Програми та канали пошуку',
			'liveTv.searchNoResults' => ({required Object query}) => 'Немає матчів для «${query}»',
			'liveTv.channelsSection' => 'Канали',
			'liveTv.programsSection' => 'Програми',
			'liveTv.now' => 'Тепер',
			'liveTv.today' => 'Сьогодні',
			'liveTv.tomorrow' => 'Завтра',
			'liveTv.midnight' => 'Місяць',
			'liveTv.overnight' => 'Увечері',
			'liveTv.morning' => 'ранок',
			'liveTv.daytime' => 'День часу',
			'liveTv.evening' => 'Вечір',
			'liveTv.lateNight' => 'Пізні ночі',
			'liveTv.whatsOn' => 'Що є на',
			'liveTv.watchChannel' => 'Дивитись канал',
			'liveTv.favorites' => 'Обрані',
			'liveTv.reorderFavorites' => 'Рейдер улюблений',
			'liveTv.noFavoriteChannels' => 'Улюблені канали немає',
			'liveTv.noFavoriteChannelsHint' => 'Показати всі канали, а потім довго натиснути канал, щоб додати його до ваших улюблених.',
			'liveTv.showAllChannels' => 'Показати всі канали',
			'liveTv.favoritesLoadFailed' => 'Не можна завантажувати улюблені. перевірте зв\'язок і спробуйте знову.',
			'liveTv.favoritesUpdateFailed' => 'Не можна оновити улюблені. перевірте зв\'язок і спробуйте знову.',
			'liveTv.joinSession' => 'Приєднуйтесь до сесії в прогресі',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Дивитись з початку (${minutes} хвилин тому)',
			'liveTv.watchLive' => 'Дивитись Live',
			'liveTv.goToLive' => 'Іди жити',
			'liveTv.record' => 'Запис',
			'liveTv.recordEpisode' => 'Рекордний епізод',
			'liveTv.recordSeries' => 'Записати серіал',
			'liveTv.recordOptions' => 'Рекордні варіанти',
			'liveTv.saveTo' => 'Зберегти до',
			'liveTv.recordings' => 'Записи',
			'liveTv.scheduledRecordings' => 'Програма',
			'liveTv.recordingRules' => 'Реєстраційні правила',
			'liveTv.noScheduledRecordings' => 'Нічого не планується записувати',
			'liveTv.manageRecording' => 'Керувати записом',
			'liveTv.cancelRecording' => 'Скасувати запис',
			'liveTv.cancelRecordingTitle' => 'Відмінити цей запис?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} більше не буде зареєстровано.',
			'liveTv.deleteRule' => 'Зняти правила',
			'liveTv.deleteRuleTitle' => 'Вимкніть правила запису?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Майбутні епізоди ${title} не будуть записані.',
			'liveTv.recordingScheduled' => 'Запис заплановано.',
			'liveTv.alreadyScheduled' => 'Ця програма вже запланована',
			'liveTv.dvrAdminRequired' => 'Установки DVR вимагають облікового запису admin',
			'liveTv.recordingFailed' => 'Не можна було планувати запис',
			'liveTv.recordingTargetMissing' => 'Бібліотека не змогла записати',
			'liveTv.recordNotAvailable' => 'Реєстрація не доступна для цієї програми',
			'liveTv.recordingCancelled' => 'Запис скасовано',
			'liveTv.recordingRuleDeleted' => 'Правила запису видалені',
			'liveTv.processRecordingRules' => 'Переоцінка правил',
			'liveTv.recordingInProgress' => 'Зареєструйте зараз',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} Програмується',
			'liveTv.editRule' => 'Регламент редагування',
			'liveTv.editRuleAction' => 'Редагувати',
			'liveTv.recordingRuleUpdated' => 'Реєстраційне правило оновлено',
			'liveTv.guideReloadRequested' => 'Реферат на тему: Реферат запропонований',
			'liveTv.guideReloadFailed' => 'Не можна оновити інструкцію',
			'liveTv.rulesProcessRequested' => 'Рекомендації про переоцінку',
			'liveTv.rulesProcessFailed' => 'Не можна переоцінювати правила запису',
			'liveTv.recordShow' => 'Рекордний шоу',
			'liveTv.recordSettings.startEarly' => 'Починати рано (за секунду)',
			'liveTv.recordSettings.endLate' => 'Запізнюється час (за секунду)',
			'liveTv.recordSettings.newOnly' => 'Тільки нові епізоди',
			'liveTv.recordSettings.anyChannel' => 'Запис на будь-якому каналі',
			'liveTv.recordSettings.anyTime' => 'Рекорд у будь-який час',
			'liveTv.recordSettings.skipInLibrary' => 'Скіп епізодів вже в бібліотеці',
			'liveTv.recordSettings.keepUpTo' => 'Епізоди, які потрібно зберігати',
			'liveTv.recordSettings.keepUpToHint' => '0 зберігає кожен епізод',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Початок за ${minutes} хвилин',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} на ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} повернуто недійсні дані відтворення Live TV',
			'liveTv.failedToStartChannel' => 'Я не можу запустити канал',
			'liveTv.failedToBuildStreamUrl' => 'Я не можу створити поточний URL',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Не можна було запустити канал: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Канал не змінюється: ${reason}',
			'collections.title' => 'Колекції',
			'collections.collection' => 'Колекція',
			'collections.empty' => 'Колекція порожня',
			'collections.deleteCollection' => 'Видалити Колекцію',
			'collections.deleteConfirm' => ({required Object title}) => 'Видалити «${title}»? Цю дію неможливо скасувати.',
			'collections.deleted' => 'Колекція видалена',
			'collections.deleteFailed' => 'Не вдалося видалити колекцію',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Не вдалося видалити збірку: ${error}',
			'collections.selectCollection' => 'Вибір колекції',
			'collections.collectionName' => 'Колекційне ім\'я',
			'collections.enterCollectionName' => 'Введіть колекційне ім\'я',
			'collections.addedToCollection' => 'Додано до колекції',
			'collections.errorAddingToCollection' => 'Не вдалося додати до колекції',
			'collections.created' => 'Колекція створена',
			'collections.removeFromCollection' => 'Вилучити з колекції',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Вилучити «${title}» із цієї колекції?',
			'collections.removedFromCollection' => 'Вилучено з колекції',
			'collections.removeFromCollectionFailed' => 'Не вдалося зняти з колекції',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Помилка у видаленні з колекції: ${error}',
			'collections.searchCollections' => 'Пошук колекцій...',
			'playlists.title' => 'Плейлисти',
			'playlists.playlist' => 'Плейлист',
			'playlists.noPlaylists' => 'Не знайдено гравців',
			'playlists.create' => 'Створення Playlist',
			'playlists.playlistName' => 'Ім\'я Playlist',
			'playlists.enterPlaylistName' => 'Введіть прізвище',
			'playlists.delete' => 'Видалити Плейліст',
			'playlists.removeItem' => 'Видалити з плейлиста',
			'playlists.smartPlaylist' => 'Розумний Playlist',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елемент', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елементи', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елементів', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} елемента', ), 
			'playlists.emptyPlaylist' => 'Цей перелік залишається порожнім',
			'playlists.deleteConfirm' => 'Використання Playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Ви впевнені, що ви хочете видалити "${name}"?',
			'playlists.created' => 'Створення Playlist',
			'playlists.deleted' => 'Завантажити Playlist',
			'playlists.itemAdded' => 'Додано до Playlist',
			'playlists.itemRemoved' => 'Вилучено з Playlist',
			'playlists.selectPlaylist' => 'Виберіть Playlist',
			'playlists.searchPlaylists' => 'Пошук гравців...',
			'playlists.errorCreating' => 'Не вдалося створити плей-лист',
			'playlists.errorDeleting' => 'Не вдалося видалити плей-лист',
			'playlists.errorLoading' => 'Не вдалося завантажити списки',
			'playlists.errorAdding' => 'Не вдалося додати до списку',
			'playlists.errorReordering' => 'Не вдалося перезавантажити елемент Playlist',
			'playlists.errorRemoving' => 'Не вдалося вилучити з списку',
			'music.goToAlbum' => 'Перейти до альбому',
			'music.goToArtist' => 'Іди до художника',
			'music.instantMix' => 'Миттєвий мікс',
			'music.playNext' => 'Наступне',
			'music.addToQueue' => 'Додати до ковбасу',
			'music.discNumber' => ({required Object n}) => 'Диск ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композиція', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композиції', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композицій', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} композиції', ), 
			'music.nowPlaying' => 'Тепер грати',
			'music.playingFrom' => ({required Object title}) => 'Ігри з ${title}',
			'music.queue' => 'Квітень',
			'music.clearQueue' => 'Очистити чергу',
			'music.lyrics' => 'Текст пісні',
			'music.visualizer' => 'Візуалізація',
			'music.visualizerProfileLoading' => 'Читати далі про Аналіз трак...',
			'music.visualizerAmbientMotion' => 'Екологічна рух',
			'music.visualizerPlexLoudness' => 'Plex Голос',
			'music.visualizerPreviousPreset' => 'Попередній візуальний стиль',
			'music.visualizerNextPreset' => 'Наступний візуальний стиль',
			'music.visualizerPresetAurora' => 'Аврора',
			'music.visualizerPresetBloom' => 'Блюм',
			'music.visualizerPresetOrbitals' => 'орбітальні',
			'music.visualizerPresetPrism' => 'Призми',
			'music.visualizerPresetTunnel' => 'тунелі',
			'music.visualizerPresetTrackMap' => 'Карта трак',
			'music.noLyrics' => 'Немає доступних ліриків',
			'music.sleepTimer' => 'Тимчасовий сон',
			'music.sleepTimerEndOfTrack' => 'Кінцевий шлях',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилина', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилини', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилин', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} хвилини', ), 
			'music.stopPlayback' => 'Зупинити відтворення',
			'music.previousTrack' => 'Попередня доріжка',
			'music.nextTrack' => 'Наступна доріжка',
			'music.repeat' => 'Повторювати',
			'music.repeatAll' => 'Повторюйте все',
			'music.repeatOne' => 'Повторіть одне',
			'music.instantMixNoServer' => 'Сервер не доступний для миттєвого змішування',
			'music.instantMixFailed' => 'Не вдалося завантажити миттєвий мікс',
			'music.instantMixEmpty' => 'Повернувся мікс без слідів.',
			'music.noAudioUrl' => ({required Object track}) => 'Немає аудіо-URL для ${track}',
			'music.discography.singlesAndEps' => 'Епізоди та ЕП',
			'music.discography.live' => 'Наживо',
			'music.discography.compilations' => 'Компіляції',
			'watchTogether.title' => 'Дивитися разом',
			'watchTogether.description' => 'Переглянути контент в синхроні з друзями та сім\'єю',
			'watchTogether.createRoom' => 'Створіть кімнату',
			'watchTogether.creatingRoom' => 'Створення кімнати...',
			'watchTogether.joinRoom' => 'Приєднуйтесь до кімнати',
			'watchTogether.joiningRoom' => 'Приєднуйтесь до кімнати...',
			'watchTogether.connecting' => 'Зв’язок...',
			'watchTogether.relayPublic' => 'Відкриті кімнати використовують публічні релізи партії Open Watch.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Кімнати використовують ваш релей на номер ${url}.',
			'watchTogether.recentRooms' => 'Нещодавні кімнати',
			'watchTogether.roomActions' => 'Діяльність кімнати',
			'watchTogether.renameRoom' => 'Ремонт кімнати',
			'watchTogether.removeRoom' => 'Видалити',
			'watchTogether.enterRoomCode' => 'Введіть 6-картний код з хостингу.',
			'watchTogether.roomCode' => 'Код кімнати',
			'watchTogether.paste' => 'Пастир',
			'watchTogether.noCodeInClipboard' => 'Кліпборд не містить коду кімнати',
			'watchTogether.copyCode' => 'Копіювати код',
			'watchTogether.codeCopied' => 'Код кімнати копіюється',
			'watchTogether.shareInvite' => 'Поділимо запрошення',
			'watchTogether.inviteCopied' => 'Запрошуємо копіювати. вставити її в повідомлення.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Приєднуйтесь до моєї кімнати Watch Together в PlezyNG: відкрийте Watch Together, виберіть Приєднуйтесь до кімнати і введіть ${code}.',
			'watchTogether.openSessionControls' => 'Відкритий час спільно контрольні сесії',
			'watchTogether.reconnecting' => 'Відновлення...',
			'watchTogether.reconnectingDescription' => 'З\'єднання припинено. Ви приєднуєтеся до кімнати автоматично.',
			'watchTogether.connected' => 'Зв\'язані',
			'watchTogether.disconnected' => 'Відключені',
			'watchTogether.youAreHost' => 'Ви є гостем',
			'watchTogether.hostedBy' => ({required Object name}) => 'Завантажити ${name}',
			'watchTogether.hostControlsPlayback' => 'Завантажити Playback',
			'watchTogether.anyoneCanControl' => 'Кожен може контролювати Playback',
			'watchTogether.roomLocked' => 'Кімната закрита',
			'watchTogether.nowPlaying' => 'Тепер грати',
			'watchTogether.nothingPlaying' => 'Нічого не грати',
			'watchTogether.nothingPlayingHost' => 'Грати в щось з будь-якої бібліотеки, щоб поділитися ним з кімнатою.',
			'watchTogether.nothingPlayingGuest' => 'Коли хостинг щось грає, він відкривається тут.',
			'watchTogether.notShareable' => 'Цей відео не має каталогу, так що тільки люди з доступом до того ж сервера можуть грати в нього.',
			'watchTogether.searching' => 'Пошук цього відео у Вашій бібліотеці...',
			'watchTogether.yourCopy' => 'Ваша копія',
			'watchTogether.sharingYourCopy' => 'Ви ділитеся копією',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Завантажити копію, ${difference}',
			'watchTogether.mismatchTitle' => 'Ваша копія має різну довжину',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Ваша найближча копія - ${difference} від відео в кімнаті. це може бути інший стрибок або версія.',
			'watchTogether.playAnyway' => 'Грати в будь-який',
			'watchTogether.chooseAnotherCopy' => 'Виберіть іншу копію',
			'watchTogether.dontPlay' => 'Не грайте',
			'watchTogether.unavailableTitle' => 'У вас немає цього відео',
			'watchTogether.unavailableDescription' => 'PlezyNG не міг знайти його у ваших бібліотеках. виберіть копію самостійно або шукати знову.',
			'watchTogether.chooseCopy' => 'Виберіть копію',
			'watchTogether.searchAgain' => 'Пошук знову',
			'watchTogether.noCandidates' => 'Копії не знайдені у ваших бібліотеках.',
			'watchTogether.choiceFailed' => 'Я не можу грати в цю копію для кімнати',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} довше',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} короткий',
			'watchTogether.lengthSame' => 'однакова довжина',
			'watchTogether.lengthUnknown' => 'Довжина невідома',
			'watchTogether.joinCurrentPlayback' => 'Завантажити Current Playback',
			'watchTogether.joinCurrentPlaybackDescription' => 'Зверніть увагу на те, що зараз спостерігається в хостелі.',
			'watchTogether.stopMedia' => 'Залишити відео для всіх',
			'watchTogether.syncOffset' => 'Сінтеграція Offset',
			'watchTogether.syncOffsetDescription' => 'Перемістіть відео, якщо воно проходить перед або за кімнатою.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Ваша копія ${difference} від відео в кімнаті.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Використання ${offset}',
			'watchTogether.offsetMinusSecond' => '1 С',
			'watchTogether.offsetMinusTenth' => '100 мс',
			'watchTogether.offsetPlusTenth' => '+ 100 мс',
			'watchTogether.offsetPlusSecond' => '1 С',
			'watchTogether.participants' => 'Учасники',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасник', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасники', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасників', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} учасники', ), 
			'watchTogether.hostBadge' => 'Хост',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (Ви)',
			'watchTogether.playerIdle' => 'Бездіяльність',
			'watchTogether.playerLoading' => 'Завантаження',
			'watchTogether.playerReady' => 'Готові',
			'watchTogether.playerBuffering' => 'Буффінг',
			'watchTogether.matchSearching' => 'Пошук',
			'watchTogether.matchMatched' => 'У вас є відео',
			'watchTogether.matchMismatched' => 'Різні довжини',
			'watchTogether.matchUnavailable' => 'У нас немає відео',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Офсет ${offset}',
			'watchTogether.makeHost' => 'Зробіть гостя',
			'watchTogether.makeHostQuestion' => 'Передача гостя?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} буде контролювати відтворення і керувати сесією для всіх.',
			'watchTogether.transfer' => 'Трансфер',
			'watchTogether.removeParticipant' => 'Зняти з кімнати',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Зняти ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} виходить з кімнати. вони можуть знову приєднатися до коду, якщо ви не заблокуєте кімнату.',
			'watchTogether.remove' => 'Видалити',
			'watchTogether.roomSettings' => 'Розташування кімнати',
			'watchTogether.letEveryoneControl' => 'Запрошуємо всіх взяти участь у Playback',
			'watchTogether.lockRoom' => 'Закритий номер',
			'watchTogether.lockRoomDescription' => 'Ніхто новий не може приєднатися',
			'watchTogether.leaveRoom' => 'Відпустіть кімнату',
			'watchTogether.leaveRoomQuestion' => 'Відпустіть кімнату?',
			'watchTogether.leaveRoomConfirm' => 'Ви можете знову приєднатися до коду кімнати.',
			'watchTogether.leave' => 'Відпустіть',
			'watchTogether.endRoom' => 'Кінцева кімната',
			'watchTogether.endRoomQuestion' => 'Кінцева кімната?',
			'watchTogether.endRoomConfirm' => 'Це закінчує кімнату для всіх.',
			'watchTogether.end' => 'Кінцевий',
			'watchTogether.playBlockedTitle' => 'Playback не почався',
			'watchTogether.playBlockedDescription' => 'Натисніть, щоб почати дивитися з кімнати.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} перекладено',
			'watchTogether.notices.playbackStarted' => 'Початок Playback',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} перерва',
			'watchTogether.notices.playbackPaused' => 'Плейбак зупинився',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} стрибнув до ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Завантажити ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} встановлює швидкість до ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Швидкість встановлена до ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} почався ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Зараз грати ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} зупинив відео',
			'watchTogether.notices.mediaStopped' => 'Відео зупинилося',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Залишився на ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Очікуючи, що хтось захопить...',
			'watchTogether.notices.finished' => 'Завершено',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} тепер є гостем',
			'watchTogether.notices.youAreNowHost' => 'Тепер ви – гость',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} приєдналися',
			'watchTogether.notices.left' => ({required Object name}) => '${name} залишити',
			'watchTogether.notices.controlRefused' => 'Тільки хостинг може контролювати відтворення',
			'watchTogether.notices.searchFailed' => 'Деякі сервери не могли шукати відео в кімнаті',
			'watchTogether.notices.playBlocked' => 'Прес-ігри для початку',
			'watchTogether.notices.shareFailed' => 'Я не можу поділитися цим відео з кімнатою',
			'watchTogether.notices.downloadNotShared' => 'Завантаження не поділяються з кімнатою, поки їх сервер офлайн',
			'watchTogether.notices.openFailed' => 'Не можна було відкрити відео в кімнаті',
			'watchTogether.ended.ended' => 'Гостьовий закінчив кімнату',
			'watchTogether.ended.kicked' => 'Ви були вилучені з кімнати.',
			'watchTogether.ended.expired' => 'Кімната закінчилася',
			'watchTogether.ended.replaced' => 'Ви приєдналися до цієї кімнати на іншому пристрої',
			'watchTogether.ended.lost' => 'Втратив зв\'язок з кімнатою',
			'watchTogether.errors.invalidCode' => 'Коди мають 6 букв і цифр, без 0, 1, I, L або O.',
			'watchTogether.errors.roomNotFound' => 'У нього немає такого коду, він може закінчитися.',
			'watchTogether.errors.roomFull' => 'Ця кімната повна.',
			'watchTogether.errors.roomLocked' => 'Гость закрив цю кімнату.',
			'watchTogether.errors.relayFull' => 'Подивитися разом зайнято зараз. спробуйте знову пізніше.',
			'watchTogether.errors.unreachable' => 'Я не можу досягти годинника спільно передати. перевірте зв\'язок.',
			'watchTogether.errors.rateLimited' => 'Занадто багато спроб. Чекайте хвилину і спробуйте знову.',
			'watchTogether.errors.clientBlocked' => 'Ця версія PlezyNG не може використовувати релей.',
			'watchTogether.errors.forbidden' => 'Це може зробити тільки гость.',
			'watchTogether.errors.notInRoom' => 'Ви не в кімнаті.',
			'watchTogether.errors.alreadyInRoom' => 'Ви вже в кімнаті.',
			'watchTogether.errors.resumeFailed' => 'Я не міг прийти до кімнати.',
			'watchTogether.errors.unsupported' => 'Релей не підтримує це.',
			'watchTogether.errors.generic' => 'Щось не так, спробуйте ще раз.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Епізод ${number}',
			'downloads.title' => 'Завантаження',
			'downloads.manage' => 'Управління',
			'downloads.tvShows' => 'Серіали',
			'downloads.movies' => 'Фільми',
			'downloads.music' => 'Музика',
			'downloads.tracksQueued' => ({required Object count}) => '${count} сліди, що переглядаються для завантаження',
			'downloads.noDownloads' => 'Досі немає завантажень',
			'downloads.noDownloadsDescription' => 'Завантажений контент з\'явиться тут для офлайн перегляду',
			'downloads.downloadNow' => 'Завантажити',
			'downloads.deleteDownload' => 'Завантажити Download',
			'downloads.retryDownload' => 'Завантажити Retry',
			'downloads.downloadQueued' => 'Завантаження в черзі.',
			'downloads.downloadResumed' => 'Завантажити відновлено',
			'downloads.serverErrorBitrate' => 'Помилка сервера: файл може перевищувати ліміт віддаленого бітрату',
			'downloads.storageFull' => 'Завантаження зупинилися, щоб захистити доступне зберігання. Завантажити деякий простір або вибрати інше місце завантаження, а потім відмовитися.',
			'downloads.storageUnavailable' => 'Завантаження зупинилися, тому що доступне зберігання не може бути перевірено. перевірте місце завантаження, а потім відкликайте.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} Епізоди, що переглядаються для завантаження',
			'downloads.downloadDeleted' => 'Завантажити видалено',
			'downloads.deleteConfirm' => ({required Object title}) => 'Видалити «${title}» з цього пристрою?',
			'downloads.deleteCollectionDownloads' => 'Зняти завантаження',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Видаляти кожну завантаження в розділі «${title}» з цього пристрою?',
			'downloads.collectionDownloadsDeleted' => 'Завантаження видалені',
			'downloads.cancelledDownloadTitle' => 'скасовано завантаження',
			'downloads.cancelledDownloadMessage' => 'Завантаження було скасовано. що ви хотіли б зробити?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Всі епізоди вже завантажені',
			'downloads.resumeDownload' => 'Резюме завантаження',
			'downloads.cancelledDownload' => 'скасовано Download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (синціонує ${status})',
			_ => null,
		} ?? switch (path) {
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Завантажено ${file} - Клікніть, щоб завершити',
			'downloads.partialDownloadClickToComplete' => 'Частково завантажено - Клікніть, щоб завершити',
			'downloads.deleting' => 'Зняти...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Видалення ${title}... (${current} з ${total})',
			'downloads.queuedTooltip' => 'Квітень',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Завантажити ${files}',
			'downloads.downloadingTooltip' => 'Завантажити...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Завантажити ${files}',
			'downloads.noDownloadsTree' => 'Без завантаження',
			'downloads.pauseAll' => 'Відпочинок усі',
			'downloads.resumeAll' => 'Резюме Все',
			'downloads.retryAll' => 'Відкликати всі',
			'downloads.retryFailed' => 'Завантажити недійсні завантаження',
			'downloads.deleteAll' => 'Видалити все',
			'downloads.selectVersion' => 'Вибір версії',
			'downloads.allEpisodes' => 'Всі епізоди',
			'downloads.unwatchedOnly' => 'Не спостерігається тільки',
			'downloads.nextNUnwatched' => ({required Object count}) => '${count} не перевірено',
			'downloads.customAmount' => 'Кваліфікована сума...',
			'downloads.customAmountAny' => 'Кількість витрат (за кожну...',
			'downloads.randomEpisodes' => 'Різні епізоди',
			'downloads.includeSpecials' => 'Включити спеціальності',
			'downloads.howManyEpisodes' => 'Скільки епізодів?',
			'downloads.invalidEpisodeCount' => 'Введіть діючу кількість епізодів.',
			'downloads.keepSynced' => 'Зберігайте синхронізацію',
			'downloads.downloadOnce' => 'Завантажити один раз',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Залишити ${count} не перевірено',
			'downloads.editSyncRule' => 'Регулювання правила синхронізації',
			'downloads.removeSyncRule' => 'Видалення правила синхронізації',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Припинити синхронізацію «${title}»? Завантажені епізоди буде збережено.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Залишити синхронізацію «${title}»?',
			'downloads.deleteSyncRuleDownloads' => 'Також видаляти пов\'язані завантаження',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Завантаження, які використовуються іншим правилом синхронізації або профілем, будуть зберігатися.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Правила синхронізації створена — зберігання ${count} невідомих епізодів',
			'downloads.syncRuleUpdated' => 'Правила синхронізації оновлено',
			'downloads.syncRuleRemoved' => 'Правила синхронізації видалені',
			'downloads.syncRuleAndDownloadsRemoved' => 'Правила синхронізації та пов\'язані з ними завантаження видалені',
			'downloads.syncRuleCleanupBusy' => 'Правила синхронізації в даний час оновлюються. спробуйте знову на хвилину.',
			'downloads.syncRuleCleanupUnavailable' => 'Повторне підключення сервера і спробуйте знову, або видалити правило без видалення завантажень.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Синхронізовано ${count} нові епізоди для ${title}',
			'downloads.syncNow' => 'Сінтеграція зараз',
			'downloads.downloadsUpToDate' => 'Завантаження на даний момент',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Сінк повний · ${queued} queued, ${removed} видалено',
			'downloads.activeSyncRules' => 'Правила синхронізації',
			'downloads.reviewOrphanFiles' => 'Завантажити Orphaned Downloads',
			'downloads.orphanReviewTitle' => 'Завантажити Orphaned Downloads',
			'downloads.orphanReviewDescription' => 'Ці етикетковані файли знаходяться в папках завантаження, що керуються прикладом PlezyNG і не мають відповідних записів завантаження або активних завдань.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} файли · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Видалення файлів ${count}',
			'downloads.orphanCleanupNone' => 'Не знайдено файлів для завантаження',
			'downloads.orphanCleanupFailed' => 'PlezyNG не міг безпечно сканувати папку завантажень.',
			'downloads.orphanCleanupChanged' => 'Список завантажень змінився під час перегляду. переглянути файли знову перед очищенням.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Вилучено ${count} сироти · ${size} звільнено',
			'downloads.noSyncRules' => 'Правила синхронізації',
			'downloads.manageSyncRule' => 'Управління синхронізацією',
			'downloads.editEpisodeCount' => 'Епізод рахунків',
			'downloads.editSyncFilter' => 'Фільтр синхронізації',
			'downloads.syncAllItems' => 'Сінтеграція всіх предметів',
			'downloads.syncUnwatchedItems' => 'Сінціонування непереглянутих предметів',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Сервер: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Доступно',
			'downloads.syncRuleOffline' => 'Офлайн',
			'downloads.syncRuleSignInRequired' => 'Підписання в необхідному',
			'downloads.syncRuleAccessDenied' => 'Доступ відмовляється',
			'downloads.syncRuleNotAvailableForProfile' => 'Не доступний для поточного профілю',
			'downloads.syncRuleUnknownServer' => 'Невідомий сервер',
			'downloads.syncRuleListCreated' => 'Створено правило синхронізації',
			'downloads.backgroundWarning.bannerBlocked' => 'Завантаження зупиняться, коли ви покинете додаток',
			'downloads.backgroundWarning.bannerDegraded' => 'Завантаження на фоні можуть бути обмежені',
			'downloads.backgroundWarning.bannerAction' => 'Детальніше',
			'downloads.backgroundWarning.sheetTitle' => 'Завантаження фонові завантаження блокуються',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Завантаження на фоні можуть бути обмежені',
			'downloads.backgroundWarning.sheetIntro' => 'Android перешкоджає PlezyNG від завантаження надійно в фоні.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Ваш пристрій обмежує, коли PlezyNG можна завантажити в фоні.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Використання фону PlezyNG обмежено. налаштуйте його батарею або фонові використання на "Не обмежено".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android встановив PlezyNG в обмеженому стані. встановити його використання акумулятора на "Не обмежено".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Повідомлення про завантаження вимкнені, тому прогрес і контроль можуть бути недоступними.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'На Android 13 або новіше, вони потрібні для довгих завантажень фону.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver є на, який блокує задні завантаження на мобільних даних. Завантаження повинні все ще працювати на Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Завантаження неодноразово зупинялися, коли PlezyNG був на фоні. перевірте налаштування батареї або використання фону PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Відкриті налаштування',
			'downloads.backgroundWarning.stillNotWorking' => 'Спеціальна допомога пристрою',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Переглянути кроки для вашого пристрою, або надіслати запис з Налаштування › Переглянути записи, якщо проблема продовжується.',
			'downloads.backgroundWarning.dialogTitle' => 'Завантаження можуть не закінчитися',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Завантажити в будь-якому',
			'downloads.backgroundWarning.dialogFixFirst' => 'Перш за все вирішити це',
			'downloads.backgroundWarning.statusTile' => 'Завантажити Background',
			'downloads.backgroundWarning.statusOk' => 'Дозволяється виходити на фоні',
			'downloads.backgroundWarning.statusBlocked' => 'Заблоковані системними установками',
			'downloads.backgroundWarning.statusDegraded' => 'Ограничений системою налаштування',
			'downloads.backgroundWarning.statusUnknown' => 'Досі не перевірено',
			'downloads.backgroundWarning.settingsUnavailable' => 'Не можна було відкрити системні налаштування на цьому пристрої',
			'downloads.backgroundWarning.linkUnavailable' => 'Не можна було відкрити dontkillmyapp.com на цьому пристрої',
			'downloads.options' => 'Завантажити опції',
			'downloads.groupings.library' => 'Медіатека',
			'downloads.groupings.collections' => 'Колекції',
			'downloads.unknownLibrary' => 'Невідома бібліотека',
			'downloads.unknownShow' => 'Невідомий шоу',
			'downloads.unknownSeason' => 'Невідомий сезон',
			'downloads.unknownAlbum' => 'Невідомий альбом',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} завершено',
			'downloads.storageUsed' => ({required Object size}) => 'Зберігання використовується: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантаження', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантаження', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантажень', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} завантаження', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіал', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіали', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіалів', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} серіали', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільм', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільми', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільмів', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} фільми', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбом', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбоми', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбомів', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} альбоми', ), 
			'downloads.errorFileNotFound' => 'Файл не знайдено (404)',
			'downloads.errorDownloadNotAllowed' => 'Завантаження не дозволено сервером (403)',
			'downloads.errorDownloadFailed' => 'Завантаження провалилося',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Завантажити не вдалося: ${reason}',
			'downloads.convertingOnServer' => 'Перехід на сервер.',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Конвертація на сервер · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Завантажити не вдалося (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Пост-процесування не вдалося: ${reason}',
			'downloads.reasonFileNotSaved' => 'Файл не може бути збережений на цьому пристрої.',
			'downloads.reasonCannotResume' => 'Часткового завантаження не можна було відновити',
			'downloads.reasonDeviceStorageFull' => 'Цей пристрій вийшов з складу',
			'downloads.notificationDownloading' => 'Завантажити...',
			'downloads.notificationComplete' => 'Завантажити повний',
			'downloads.notificationPaused' => 'Завантажити Pause',
			'shaders.title' => 'Шейдер',
			'shaders.noShaderDescription' => 'Без відеопосилення',
			'shaders.nvscalerDescription' => 'NVIDIA зображення скалювання для більш яскравих відео',
			'shaders.artcnnVariantNeutral' => 'Нейтральний',
			'shaders.artcnnVariantDenoise' => 'Денонс',
			'shaders.artcnnVariantDenoiseSharpen' => 'Створення Denoise + Sharpen',
			'shaders.qualityFast' => 'Швидкість',
			'shaders.qualityHQ' => 'Висока якість',
			'shaders.mode' => 'Мода',
			'shaders.importShader' => 'Імпорт Шейдер',
			'shaders.customShaderDescription' => 'Створення GLSL Shader',
			'shaders.shaderImported' => 'Шейдер імпортує',
			'shaders.shaderImportFailed' => 'Не вдалося ввезення шахтаря',
			'shaders.deleteShader' => 'Зніміть Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Вимкніть «${name}»',
			'companionRemote.title' => 'Додатковий пульт',
			'companionRemote.connectedTo' => ({required Object name}) => 'Підключений до ${name}',
			'companionRemote.unknownDevice' => 'Невідомі пристрої',
			'companionRemote.session.startingServer' => 'Розпочато віддалений сервер.',
			'companionRemote.session.hostAddress' => 'Адреса гостя',
			'companionRemote.session.connected' => 'Зв\'язані',
			'companionRemote.session.serverRunning' => 'Віддалений сервер активний',
			'companionRemote.session.serverStopped' => 'Віддалений сервер зупинився',
			'companionRemote.session.serverRunningDescription' => 'Мобільні пристрої на вашій мережі можуть підключитися до цієї програми',
			'companionRemote.session.serverStoppedDescription' => 'Запустіть сервер, щоб дозволити мобільним пристроям підключитися',
			'companionRemote.session.usePhoneToControl' => 'Використовуйте свій мобільний пристрій для контролю за цією програмою',
			'companionRemote.session.startServer' => 'Початок сервера',
			'companionRemote.session.stopServer' => 'Залишити сервер',
			'companionRemote.session.minimize' => 'мінімізація',
			'companionRemote.session.manualAddressHint' => 'Адреса ручного зв\'язку:',
			'companionRemote.pairing.discoveryDescription' => 'Пристрої PlezyNG з тим же аккаунтом Plex з\'являються тут',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Зв’язок...',
			'companionRemote.pairing.searchingForDevices' => 'Пошук пристроїв...',
			'companionRemote.pairing.noDevicesFound' => 'Не знайдено пристроїв у мережі',
			'companionRemote.pairing.noDevicesHint' => 'Відкрийте PlezyNG на робочому столі і використовуйте той же Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Доступні пристрої',
			'companionRemote.pairing.manualConnection' => 'Ручне підключення',
			'companionRemote.pairing.cryptoInitFailed' => 'Зареєструйтесь на номер Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Будь ласка, введіть адресу гостя',
			'companionRemote.pairing.validationHostFormat' => 'Формат повинен бути IP:port (наприклад, 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Використовуйте одну і ту ж мережу на обох пристроях.',
			'companionRemote.pairing.sessionNotFound' => 'Пристрій не знайдено. переконайтеся, що PlezyNG працює на хості.',
			'companionRemote.pairing.authFailed' => 'Обидва пристрої потребують одного і того ж облікового запису Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Не вдалося підключитися: ${error}',
			'companionRemote.pairing.codeTitle' => 'Кодекс пара',
			'companionRemote.pairing.codeDescription' => 'Введіть код, що відображається в розділі Companion Remote, на пристрої-хостингу. обидва пристрої повинні використовувати версію, яка підтримує безпечне підключення.',
			'companionRemote.pairing.codeInvalid' => 'Введіть всі 32 букви та цифри з хостингового коду.',
			'companionRemote.pairing.updateRequired' => 'Оновлення обох пристроїв до версії, яка підтримує безпечне підключення.',
			'companionRemote.pairing.hostDescription' => 'Введіть цей код один раз на кожному віддаленому. Зберігайте його приватним: він надає контроль над цим профілем.',
			'companionRemote.pairing.resetCode' => 'Відновлення парового коду',
			'companionRemote.pairing.resetDescription' => 'Відключіть всі відстані і створюйте новий код. Кожен відстані потребує знову пара.',
			'companionRemote.remote.disconnectConfirm' => 'Ви хочете відключити від дистанційної сесії?',
			'companionRemote.remote.reconnecting' => 'Відновлення...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Пошук ${current} з 5',
			'companionRemote.remote.retryNow' => 'Повернутись зараз',
			'companionRemote.remote.tabRemote' => 'Віддалені',
			'companionRemote.remote.tabPlay' => 'Грати',
			'companionRemote.remote.tabMore' => 'Більше',
			'companionRemote.remote.menu' => 'Меню',
			'companionRemote.remote.tabNavigation' => 'Таб навігації',
			'companionRemote.remote.tabDiscover' => 'Відкриття',
			'companionRemote.remote.tabLibraries' => 'Медіатеки',
			'companionRemote.remote.tabSearch' => 'Пошук',
			'companionRemote.remote.tabDownloads' => 'Завантаження',
			'companionRemote.remote.tabSettings' => 'Налаштування',
			'companionRemote.remote.previous' => 'Назад',
			'companionRemote.remote.playPause' => 'Ігри / Пауза',
			'companionRemote.remote.next' => 'Вперед',
			'companionRemote.remote.seekBack' => 'Пошук назад',
			'companionRemote.remote.stop' => 'Зупинити',
			'companionRemote.remote.seekForward' => 'Пошук FWD',
			'companionRemote.remote.volume' => 'обсяг',
			'companionRemote.remote.volumeDown' => 'Вниз',
			'companionRemote.remote.volumeUp' => 'Вгору',
			'companionRemote.remote.fullscreen' => 'Повноекранний режим',
			'companionRemote.remote.subtitles' => 'Субтитри',
			'companionRemote.remote.audio' => 'Аудіо',
			'companionRemote.remote.searchHint' => 'Пошук на робочому місці...',
			'companionRemote.errors.noNetworkInterface' => 'Інтерфейс мережі не знайдено',
			'companionRemote.errors.authenticationFailed' => 'аутентифікація провалилася',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Не вдалося запустити віддалений сервер: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Не вдалося відправити дистанційну команду: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Час приєднатися до сесії',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Не вдалося підключитися до будь-якої адреси',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Втрата зв\'язку після ${attempts} спроб',
			'companionRemote.errors.connectionLost' => 'Загублений зв\'язок',
			'companionRemote.closedBeforeAuth' => 'Зв\'язок закритий до аутентифікації',
			'videoSettings.playbackSpeed' => 'Швидкість відтворення',
			'videoSettings.normalSpeed' => 'Звичайний',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Активний (${duration})',
			'videoSettings.zoom' => 'Масштабувати',
			'videoSettings.sleepTimer' => 'Співак час',
			'videoSettings.audioSync' => 'аудіо синхронізація',
			'videoSettings.subtitleSync' => 'Підзаголовок Sync',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR не доступний тут — цей настільний композитор або відеовихід не може нести його.',
			'videoSettings.hdrToneMapping' => 'HDR Tone Картування',
			'videoSettings.hdrToneMappingCompositor' => 'Композитор',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Перейти через джерело HDR метадатів і залишити на робочому столі композитор карту його.',
			'videoSettings.hdrToneMappingPlayer' => 'Програвач',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Карта до вершини яскравості екрану в гравці, а потім повідомити композитору результат.',
			'videoSettings.hdrToneMappingFailed' => 'Не можна було змінити тонус HDR - попередній режим все ще активний.',
			'videoSettings.audioOutput' => 'аудіо вихід',
			'videoSettings.performanceOverlay' => 'Продукція Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'навколо',
			'videoSettings.audioOutputSpatial' => 'Космічний аудіо',
			'videoSettings.audioOutputStereo' => 'Стерео',
			'videoSettings.audioEqualizer' => 'Аудіо Еквалізований',
			'videoSettings.audioEqualizerDescription' => 'Доступно на mpv; активний EQ декодує аудіо і відключає збій.',
			'videoSettings.audioEqualizerFlat' => 'Площа',
			'videoSettings.audioEqualizerActive' => 'Користувацький',
			'videoSettings.audioEqualizerSaveFailed' => 'Не можна було встановити звуковий еквівалент.',
			'videoSettings.backgroundVideoAudio' => 'Завантажити Video Audio',
			'videoSettings.backgroundVideoAudioDescription' => 'Зберігайте відео-аудіо грати, коли ви покинете гравець; зображення приховується, поки ви не повернетеся. Android використовує повідомлення про відтворення засобів масової інформації.',
			'videoSettings.audioNormalization' => 'Нормалізація шуму',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Декодує аудіо до PCM; passthrough вимкнеться, поки це на',
			'performanceOverlay.color' => 'Колір',
			'performanceOverlay.performance' => 'Продуктивність',
			'performanceOverlay.buffer' => 'Буффер',
			'performanceOverlay.app' => 'Додаток',
			'performanceOverlay.decoder' => 'Декорація',
			'performanceOverlay.rawDecoder' => 'РОЙ ДЕКОДЕР',
			'performanceOverlay.tunneling' => 'тунелі',
			'performanceOverlay.passthrough' => 'Пастирський',
			'performanceOverlay.aspect' => 'Погляд',
			'performanceOverlay.rotation' => 'Обертання',
			'performanceOverlay.dvSource' => 'ДВ джерела',
			'performanceOverlay.dvPath' => 'ДВ ПУТ',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision Декодер',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision декодер (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Базовий шар',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 базовий шар',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG базовий шар',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'СДР базовий шар',
			'performanceOverlay.dvRouteReshaped' => 'РПУ відновлено (gpu-next)',
			'performanceOverlay.p7Conversion' => 'П7 Конв',
			'performanceOverlay.sampleRate' => 'Частота дискретизації',
			'performanceOverlay.pixelFormat' => 'Піксель ФМТ',
			'performanceOverlay.hwFormat' => 'ФМТ',
			'performanceOverlay.matrix' => 'Матриця',
			'performanceOverlay.primaries' => 'Первинні',
			'performanceOverlay.transfer' => 'Трансфер',
			'performanceOverlay.renderFps' => 'Рендер ФПС',
			'performanceOverlay.displayFps' => 'Дисплей FPS',
			'performanceOverlay.avSync' => 'А/В синхронізація',
			'performanceOverlay.dropped' => 'розбито',
			'performanceOverlay.dvRpus' => 'ДВ РПУ',
			'performanceOverlay.dvRpuAverage' => 'ДВ РПУ АВГ',
			'performanceOverlay.dvSampleAverage' => 'ДВ Семп Avg',
			'performanceOverlay.maxLuma' => 'Макс Люма',
			'performanceOverlay.minLuma' => 'Мінус Лума',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Використовується кеш',
			'performanceOverlay.cacheLimit' => 'Cache обмеження',
			'performanceOverlay.speed' => 'Швидкість',
			'performanceOverlay.player' => 'Програвач',
			'performanceOverlay.playMethod' => 'Засіб програвання',
			'performanceOverlay.memory' => 'Пам\'ять',
			'performanceOverlay.uiFps' => 'ФПС',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android ХВ',
			'performanceOverlay.decoderNvidiaHw' => 'Створення NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm Світовий',
			'performanceOverlay.decoderMediatekHw' => 'Створення MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Екзотичний HW',
			'performanceOverlay.decoderSoftware' => 'Програмне забезпечення',
			'performanceOverlay.decoderHardware' => 'Хардкор',
			'performanceOverlay.tunnelingActive' => 'Активний',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} не вдалося)',
			'externalPlayer.title' => 'Зовнішній гравець',
			'externalPlayer.useExternalPlayer' => 'Використовуйте зовнішній гравець',
			'externalPlayer.useExternalPlayerDescription' => 'Відкрийте відео в іншому додатку',
			'externalPlayer.selectPlayer' => 'Вибір гравця',
			'externalPlayer.customPlayers' => 'Custom гравці',
			'externalPlayer.systemDefault' => 'Системний дефолт',
			'externalPlayer.addCustomPlayer' => 'Додати Custom Player',
			'externalPlayer.playerName' => 'Ім\'я гравця',
			'externalPlayer.playerNameHint' => 'Мій гравець',
			'externalPlayer.playerCommand' => 'Командування',
			'externalPlayer.playerPackage' => 'Назва пакету',
			'externalPlayer.playerUrlScheme' => 'УРЛ схема',
			'externalPlayer.off' => 'Вимкнути',
			'externalPlayer.launchFailed' => 'Не вдалося відкрити зовнішнього гравця',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} не встановлено',
			'externalPlayer.playInExternalPlayer' => 'Грати в зовнішній гравець',
			'metadataEdit.editMetadata' => 'Редагувати',
			'metadataEdit.screenTitle' => 'Редагувати метадані',
			'metadataEdit.basicInfo' => 'Основна інформація',
			'metadataEdit.artwork' => 'Художня робота',
			'metadataEdit.advancedSettings' => 'Прогресивні налаштування',
			'metadataEdit.title' => 'Назва',
			'metadataEdit.sortTitle' => 'Назва сортування',
			'metadataEdit.originalTitle' => 'Оригінальний заголовок',
			'metadataEdit.releaseDate' => 'Дата випуску',
			'metadataEdit.contentRating' => 'Рейтинг контенту',
			'metadataEdit.studio' => 'Студія',
			'metadataEdit.tagline' => 'Слоган',
			'metadataEdit.summary' => 'резюме',
			'metadataEdit.poster' => 'Постер',
			'metadataEdit.background' => 'фонтани',
			'metadataEdit.logo' => 'Логотип',
			'metadataEdit.squareArt' => 'Площа мистецтва',
			'metadataEdit.selectPoster' => 'Виберіть постер',
			'metadataEdit.selectBackground' => 'Виберіть фон',
			'metadataEdit.selectLogo' => 'Вибір логотипу',
			'metadataEdit.selectSquareArt' => 'Вибір площі мистецтва',
			'metadataEdit.fromUrl' => 'Від URL',
			'metadataEdit.uploadFile' => 'Завантажити файл',
			'metadataEdit.enterImageUrl' => 'Введіть URL',
			'metadataEdit.imageUrl' => 'Зображення URL',
			'metadataEdit.metadataUpdated' => 'Актуальні метастази',
			'metadataEdit.metadataUpdateFailed' => 'Не вдалося оновити метаданни',
			'metadataEdit.artworkUpdated' => 'Актуальна художня робота',
			'metadataEdit.artworkUpdateFailed' => 'Не вдалося оновити художню роботу',
			'metadataEdit.noArtworkAvailable' => 'Немає художніх творів',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Вибір художньої роботи ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Вибір художнього твору ${index}, вибраний',
			'metadataEdit.notSet' => 'Не встановлюйте',
			'metadataEdit.libraryDefault' => 'Бібліотека дефолт',
			'metadataEdit.accountDefault' => 'Дефіцит рахунку',
			'metadataEdit.seriesDefault' => 'Серія дефолт',
			'metadataEdit.episodeSorting' => 'Епізод Сортінг',
			'metadataEdit.oldestFirst' => 'Найстаріший перший',
			'metadataEdit.newestFirst' => 'Найновіші перші',
			'metadataEdit.keep' => 'Дотримуйтесь',
			'metadataEdit.allEpisodes' => 'Всі епізоди',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} останні епізоди',
			'metadataEdit.latestEpisode' => 'Останній епізод',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Епізоди додано за останні ${count} днів',
			'metadataEdit.deleteAfterPlaying' => 'Зняти епізоди після гри',
			'metadataEdit.never' => 'Ніколи',
			'metadataEdit.afterADay' => 'Після одного дня',
			'metadataEdit.afterAWeek' => 'Після тижня',
			'metadataEdit.afterAMonth' => 'Після місяця',
			'metadataEdit.onNextRefresh' => 'На наступному відновлюванні',
			'metadataEdit.seasons' => 'Сезони',
			'metadataEdit.show' => 'показ',
			'metadataEdit.hide' => 'Приховати',
			'metadataEdit.episodeOrdering' => 'Епізод замовлення',
			'metadataEdit.tmdbAiring' => 'База даних фільмів (Aired)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Відкритий)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Абсолютний)',
			'metadataEdit.metadataLanguage' => 'Мета-язики',
			'metadataEdit.useOriginalTitle' => 'Використовуйте оригінальний заголовок',
			'metadataEdit.preferredAudioLanguage' => 'Бажана мова аудіо',
			'metadataEdit.preferredSubtitleLanguage' => 'Бажана мова субтитрів',
			'metadataEdit.subtitleMode' => 'Автомобільний підзаголовок',
			'metadataEdit.manuallySelected' => 'Ручно вибрані',
			'metadataEdit.shownWithForeignAudio' => 'Завантажити аудіо з іноземним',
			'metadataEdit.alwaysEnabled' => 'Завжди дозволяється',
			'metadataEdit.tags' => 'Мітки',
			'metadataEdit.addTag' => 'Додати тег',
			'metadataEdit.genre' => 'Жанр',
			'metadataEdit.director' => 'Режисер',
			'metadataEdit.writer' => 'Сценарист',
			'metadataEdit.producer' => 'Продюсер',
			'metadataEdit.country' => 'країна',
			'metadataEdit.collection' => 'Колекція',
			'metadataEdit.label' => 'Етикетка',
			'metadataEdit.quickTag' => 'Швидкий Tag...',
			'matchScreen.match' => 'Матч...',
			'matchScreen.fixMatch' => 'Змагання пройшли...',
			'matchScreen.unmatch' => 'Без матчу',
			'matchScreen.unmatchConfirm' => 'Plex розглядає його як несумісний до завершеного.',
			'matchScreen.unmatchSuccess' => 'Несумісні елементи',
			'matchScreen.unmatchFailed' => 'Невдача в безперервному об\'єкті',
			'matchScreen.matchApplied' => 'Матч застосовується',
			'matchScreen.matchFailed' => 'Не вдалося встановити матч',
			'matchScreen.titleHint' => 'Назва',
			'matchScreen.yearHint' => 'Рік',
			'matchScreen.search' => 'Пошук',
			'matchScreen.noMatchesFound' => 'Не знайдено матчів',
			'serverTasks.title' => 'Сервіс завдань',
			'serverTasks.failedToLoad' => 'Не вдалося завантажити завдання',
			'serverTasks.noTasks' => 'Не виконувати завдання',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Зв\'язані',
			'trakt.connectedAs' => ({required Object username}) => 'Зв\'язаний як @${username}',
			'trakt.disconnectConfirm' => 'Вимкніть обліковий запис Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG перестане відправляти події на Trakt. Ви можете знову підключитися в будь-який час.',
			'trakt.scrobble' => 'Реальний час Скрипаль',
			'trakt.scrobbleDescription' => 'Надіслати відгуки, перерви та зупинки подій на номер Trakt під час перегляду.',
			'trakt.watchedSync' => 'Синхен спостерігається статус',
			'trakt.watchedSyncDescription' => 'Коли ви відзначаєте елементи, як спостерігалося в PlezyNG, вони також відзначаються як спостерігалося в Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Зв\'яжіть Seerr',
			'seerr.serverUrl' => 'Сервер URL',
			'seerr.serverUrlHelper' => 'Адреса Вашої інстанції',
			'seerr.checkServer' => 'Продовжуйте',
			'seerr.signInWithJellyfin' => 'Зареєструйтесь за адресою Jellyfin',
			'seerr.signInWithEmby' => 'Зареєструйтесь за адресою Emby',
			'seerr.signInWithLocal' => 'Використовуйте місцевий рахунок',
			'seerr.email' => 'Електронна',
			'seerr.noSignInMethods' => 'Цей приклад Seerr не пропонує підписки методу PlezyNG підтримки.',
			'seerr.instance' => 'Інстанція',
			'seerr.disconnectConfirm' => 'Відключення від Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG забуде цей приклад Seerr. Зв\'яжіться в будь-який час.',
			'seerr.request' => 'Запрошення',
			'seerr.request4k' => 'Заявка в 4K',
			'seerr.seasons' => 'Сезони',
			'seerr.allSeasons' => 'Всі сезони',
			'seerr.advancedOptions' => 'Розширені',
			'seerr.destinationServer' => 'Сервіс призначення',
			'seerr.qualityProfile' => 'Профіль якості',
			'seerr.rootFolder' => 'Короткий папір',
			'seerr.languageProfile' => 'Профіль мови',
			'seerr.tags' => 'Мітки',
			'seerr.noTags' => 'Ніяких тегів',
			'seerr.defaultOption' => ({required Object name}) => '${name} (за замовчуванням)',
			'seerr.animeNote' => 'Ця серія – це аніме.',
			'seerr.requestSubmitted' => 'Заява подана',
			'seerr.requestFailed' => ({required Object error}) => 'Заявка про недійсність: ${error}',
			'seerr.requestsLoadFailed' => 'Не можна завантажувати опції запиту',
			'seerr.nothingToRequest' => 'Все вже доступно або запропоновано.',
			'seerr.statusAvailable' => 'Доступно',
			'seerr.statusPartiallyAvailable' => 'Частково доступні',
			'seerr.statusRequested' => 'Запрошені',
			'seerr.statusProcessing' => 'обробка',
			'seerr.statusBlocklisted' => 'Блокування',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Не може досягти ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'No Seerr інстанція на ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Автентифікований зворотний прокси (SSO або HTTP auth) відповів замість Seerr. PlezyNG не може зареєструватися через нього: дозвольте Seerr /api/v1 шляху перетнути прокси для цієї програми, або використовуйте адресу, яка досягає Seerr безпосередньо.',
			'seerr.invalidUrl' => 'Введіть адресу сервера, наприклад, https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Цей приклад Seerr не підтримує Quick Connect. він потребує Seerr 3.4 або вище.',
			'seerr.notInitialized' => 'Цей приклад Seerr не завершив першочергову установку',
			'seerr.noPlexTokenForReauth' => 'Токен No Plex доступний для реєстрації знову',
			'seerr.noStoredCredentials' => 'Немає збережених даних для повторного входу',
			'seerr.signInRejected' => 'Підписання було відхилено',
			'seerr.noSessionCookie' => 'Seerr не видав cookie сесії',
			'seerr.freshCookieRejected' => 'Seerr відмовився від нового cookie сесії',
			'seerr.noUserInformation' => 'Seerr не повернула інформацію користувача',
			'seerr.sessionRejectedAfterReauth' => 'Засідання було відхилено після повторного підписання.',
			'seerr.permissionDenied' => 'Seerr відмовився від цієї дії: Ваш обліковий запис більше не має необхідного дозволу',
			'seerr.permissionRevoked' => 'Ви більше не маєте права вимагати цього.',
			'services.title' => 'Сервіси',
			'services.hubSubtitle' => 'Sync спостерігає за прогресом і запитує нові заголовки.',
			'services.integrations' => 'Інтеграції',
			'services.notConnected' => 'Не пов\'язані',
			'services.connectedAs' => ({required Object username}) => 'Зв\'язаний як @${username}',
			'services.scrobble' => 'Слідкуйте за прогресом автоматично',
			'services.scrobbleDescription' => 'Оновлюйте свій список, коли ви закінчите епізод або фільм.',
			'services.disconnectConfirm' => ({required Object service}) => 'Відключення ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG буде припиняти оновлення ${service}.',
			'services.connectFailed' => ({required Object service}) => 'Я не можу підключитися до ${service}. спробуйте знову.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Повторний зв\'язок Simkl',
			'services.simklReconnect.subtitle' => 'Simkl припиняє підтримку способу входу, який використовує це підключення. Повторне підключення відкриє simkl.com для надання дозволу PlezyNG — PlezyNG ніколи не бачить ваш пароль. Історія переглядів залишиться на Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Завантажити PlezyNG на ${service}',
			'services.deviceCode.instructions' => 'Скануйте QR-код або відвідайте нижче наведену адресу та введіть цей код:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Відкрийте ${service} для активування',
			'services.deviceCode.copyCode' => 'Копіювати код активізації',
			'services.deviceCode.waitingForAuthorization' => 'Чекаємо на дозвіл...',
			'services.deviceCode.codeCopied' => 'Код копіюється',
			'services.oauthProxy.title' => ({required Object service}) => 'Зареєструйтесь на номер ${service}',
			'services.oauthProxy.body' => 'Скануйте цей QR-код або відкрийте URL на будь-якому пристрої.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Відкрийте ${service} для реєстрації',
			'services.pendingAuth.copyUrl' => 'Завантажити URL-адрес',
			'services.pendingAuth.urlCopied' => 'URL копіюється',
			'services.libraryFilter.title' => 'Бібліотека Фільтр',
			'services.libraryFilter.subtitleAllSyncing' => 'Сінціонувати всі бібліотеки',
			'services.libraryFilter.subtitleNoneSyncing' => 'Нічого не синхронізує',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} заблоковано',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} дозволено',
			'services.libraryFilter.mode' => 'Фільтр режиму',
			'services.libraryFilter.modeBlacklist' => 'Чорний список',
			'services.libraryFilter.modeWhitelist' => 'Білий список',
			'services.libraryFilter.modeHintBlacklist' => 'Синхронізуйте кожну бібліотеку за винятком тих, які переглядаються нижче.',
			'services.libraryFilter.modeHintWhitelist' => 'Синхронізуйте тільки бібліотеки, які перевіряються нижче.',
			'services.libraryFilter.libraries' => 'Медіатеки',
			'services.libraryFilter.noLibraries' => 'Бібліотеки немає',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Додати сервер ${product}',
			'addServer.serverUrls' => 'Сервер URL',
			'addServer.serverUrlsHelper' => 'Дозволені кілька URL, розділені коммами.',
			'addServer.findServer' => 'Знайти сервер',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Пошук місцевих серверів ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Місцеві сервери ${product}',
			'addServer.username' => 'Ім’я користувача',
			'addServer.password' => 'Пароль',
			'addServer.signIn' => 'Вхід',
			'addServer.change' => 'Зміни',
			'addServer.required' => 'Потрібні',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Не можна доступу до сервера: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Зареєструватися не вдалося: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect не вдалося: ${error}',
			_ => null,
		} ?? switch (path) {
			'addServer.addPlexTitle' => 'Зареєструйтесь за адресою Plex',
			'addServer.pinExpired' => 'PIN закінчився перед тим, як зареєструватися, будь ласка, спробуйте знову.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Зареєструватися не вдалося: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Введіть URL сервера ${product}',
			'addServer.addConnectionTitle' => 'Додати зв\'язок',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Додати до ${name}',
			'addServer.signInWithPlexCard' => 'Зареєструйтесь за адресою Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Додайте доступ до цього пристрою.Додаються спільні сервери.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Дозвіл на обліковий запис Plex Домашні користувачі стають профілями.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Підключення до ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Введіть URL сервера, ім\'я користувача та пароль.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Зареєструйтесь на сервер ${product}. підключіться до ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Кредит з іншого профілю',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Повторне використання підключення іншого профілю. PIN-захищені профілі потребують PIN.',
			'addServer.invalidCredentials' => 'Недійсне ім\'я користувача або пароль',
			'addServer.authResponseNotJson' => 'Відповідь на аутентифікацію не була дійсною JSON',
			'addServer.authResponseIncomplete' => 'Реакція сервера була неповною.',
			'addServer.quickConnectRejected' => 'Quick Connect було відхилено сервером',
			'addServer.quickConnectNotJson' => 'Відповідь Quick Connect не була дійсною JSON',
			'addServer.quickConnectMissingFields' => 'Відповідь Quick Connect відсутня код або секрет',
			'addServer.quickConnectPollRejected' => 'Quick Connect запит було відхилено сервером',
			'addServer.serverTimedOut' => 'Сервер не відповідає вчасно',
			'addServer.responseNotJson' => 'Серверна відповідь не була дійсною JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Відповідь відсутня ідентифікатор або прізвище сервера — чи є це сервером ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Не можна доступу до сервера: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Введіть щонайменше один серверний URL ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Не знайдено сервера ${product}',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Ці URL-адреси вказують на різні сервери ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Цей URL не відповідає серверу ${product}',
			'addServer.redirectUnsupported' => 'Сервер перенаправлено на непомітний URL',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Сервер перенаправлений на інший хостинг. Введіть URL ${product} прямо.',
			'addServer.redirectInsecure' => 'Сервер перенаправлено з HTTPS на небезпечний URL',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Сервер перенаправлено на непоміщену URL. Введіть URL ${product} прямо.',
			'addServer.directPlexServerUrl' => 'Plex сервер URL',
			'addServer.directPlexServerUrlHelper' => 'Введіть місцевий IP і порт вашого Медіа-сервера Plex.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Токен (вибірковий)',
			'addServer.plexTokenHelper' => 'Залишити вільний, якщо доступ без аут дозволений на цьому сервері.',
			'addServer.plexTokenRequired' => 'Будь ласка, введіть свій токен Plex (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Медіа-сервер (прямий / місцевий)',
			'addServer.connectDirectPlexCardSubtitle' => 'Зв\'яжіться безпосередньо за допомогою локального IP або URL без облікового запису plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Зв\'яжіться безпосередньо за допомогою локального IP або URL. зв\'яжіться до ${name}.',
			'addServer.insecureTitle' => 'Нешифрований зв\'язок',
			'addServer.insecureDescription' => ({required Object url}) => '${url} використовує HTTP. Інші користувачі мережі можуть прочитати або змінити ваш пароль, токени та медіа. За можливості використовуйте HTTPS. Продовжуйте лише тоді, коли довіряєте цій мережі та приймаєте ризик.',
			'addServer.allowHttp' => 'Дозвіл HTTP',
			'addServer.httpsRequired' => 'Використовуйте HTTPS або експлицитно дозволяйте нешифрований зв\'язок.',
			'watchLink.serverUnavailable' => 'Я не міг дістатися до сервера Plex для цього посилання.',
			'watchLink.notFound' => 'Я не можу знайти цей шоу або фільм на ваших серверах Plex.',
			'watchLink.ambiguous' => 'Цей посилання відповідає елементам на більш ніж одному сервері. Додати сервер до посилання.',
			'watchLink.plexOnly' => 'В даний час підтримує тільки сервери Plex.',
			'watchLink.unsupportedItem' => 'Переглянути посилання можна тільки відкрити шоу або фільм.',
			'watchLink.menuItem' => 'Показати посилання',
			'watchLink.dialogTitle' => 'Переглянути link',
			'watchLink.dialogShowHint' => 'Відкриття цього посилання грає наступний епізод. Додати &mode=shuffle до кінця, щоб грати шоу на shuffle.',
			'watchLink.dialogMovieHint' => 'Відкриття цього посилання грає фільм.',
			'watchLink.copy' => 'Копіювати',
			'watchLink.copied' => 'Link копіюється',
			'homeLayout.title' => 'Домашнє лайнування',
			'homeLayout.resetToast' => 'Повернення до оригінальної версії героя Plezy',
			'homeLayout.resetHeroTitle' => 'Перезавантажити героїчний розклад на запас Plezy?',
			'homeLayout.resetHeroBody' => 'Звертає героїчний набір кожного ряду і повертає єдиний ротаційний банер на вершині Дома, як і до героїчних рядів існували.',
			'homeLayout.removeRowTitle' => 'Зняти домашню лінію?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} буде видалено. це не може бути відхилено.',
			'homeLayout.sync' => 'Сінтеграція',
			'homeLayout.syncAccountTitle' => 'Спілкуйтеся з вашим обліковим записом Plex',
			'homeLayout.syncAccountOn' => 'На: Цей пристрій ділиться порядком, рядками, Героєм і Авто-Слайдом з іншими пристроями.',
			'homeLayout.syncAccountOff' => 'Вимкнено: цей пристрій зберігає свій власний розклад.',
			'homeLayout.syncNow' => 'Сінтеграція зараз',
			'homeLayout.plexHomeManager' => 'Plex Домашній менеджер',
			'homeLayout.managePlexRows' => 'Управління Plex рядки в Plezy',
			'homeLayout.managePlexRowsDescription' => 'Відкрито для організації домашньо вибраних рядків',
			'homeLayout.organizeHomeRows' => 'Організуйте домашній ряд',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} рядки: переміщення, Герої, Авто-Слайд, видалення',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Організуйте ${library} рядки',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Продовжуйте дивитися + ${n} рядки: переміщення, Бібліотека, Домашній, Герої, Авто-Слайд',
			'homeLayout.renderAsHero' => 'Повернення як героїчна картка',
			'homeLayout.heroOnlySingleCollection' => 'Доступно тільки тоді, коли ця рядка вирішується на реальні заголовки однієї колекції',
			'homeLayout.hero' => 'Герой',
			'homeLayout.autoSlide' => 'Автомобільний слайд',
			'homeLayout.autoSlideDescription' => 'Пристрій (PC) і d-pad (TV) завжди працюють і відновлюють час.',
			'homeLayout.autoSlideEditDescription' => 'Вимкніть: рухається тільки тоді, коли натискаєте стрілку (ПК) або натискаєте ліво/право на віддаленому (ТВ).',
			'homeLayout.enableHeroFirst' => 'Перший герой',
			'homeLayout.showOnHome' => 'Показати на домашньому екрані',
			'homeLayout.home' => 'Головна',
			'homeLayout.removeFromHome' => 'Зняти з дому',
			'homeLayout.selectRowsFirst' => 'Виберіть домашній ряд нижче першого.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex управляються рядки',
			'homeLayout.continueWatching' => 'Продовжити перегляд',
			'homeLayout.continueWatchingLibraryDescription' => 'Бібліотека має власний рецидив прогресу',
			'homeLayout.continueWatchingHomeDescription' => 'Повторний прогрес, показані на Home',
			'homeLayout.nextUpHomeDescription' => 'Наступна непереглянута серія епізодів відображається окремо на Home',
			'homeLayout.library' => 'Медіатека',
			'homeLayout.showInRecommended' => 'Показати в бібліотеці Рекомендовано',
			'homeLayout.customPlexRow' => 'Кваліфікований Plex ряд',
			'homeLayout.heroNeedsLibrary' => 'Перевірте Бібліотеку спочатку — Герою потрібно десь показати',
			'homeLayout.heroNeedsSurface' => 'Перевірте Бібліотеку або Дому спочатку — Герою потрібно десь показати',
			'homeLayout.removeHub' => 'Видалення Hub',
			'homeLayout.noPlexRows' => 'No Plex-управлені рядки повернулися для цієї бібліотеки.',
			'homeLayout.openDetails' => 'Відкриті деталі',
			'homeLayout.heroCards' => 'Герої картки',
			'homeLayout.tapHeroCard' => 'Завантажити картку героя',
			'homeLayout.tvPlayFocus' => 'Телевізор віддалений: підкреслює кнопку Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad down зупиняється на кнопці Play, перш ніж перейти до наступного рядка.',
			'homeLayout.tvWrap' => 'Телевізійні дистанційні: картки героїв',
			'homeLayout.tvWrapDescription' => 'Права на останній картці йде назад до першої.Відстають зупинки на останній картці.Лево на першій картці завжди йде до бокової смуги.',
			'homeLayout.castOnHero' => 'Завантажити Hero Banner',
			'homeLayout.castOnHeroDescription' => 'Показати виставку уздовж нижньої частини героїчного банера. Офіційно зберігається тільки заголовок і резюме.',
			'homeLayout.customRows' => 'Кваліфіковані рядки',
			'homeLayout.loading' => 'Завантажити Home Layout',
			'homeLayout.noCustomRows' => 'Досі немає звичайних рядків',
			'homeLayout.addRowHint' => 'Використовуйте Додати домашній ряд, щоб створити один.',
			'homeLayout.addHomeRow' => 'Додати додому',
			'homeLayout.addHomeRowDescription' => 'Виберіть категорію; новий ряд додається до Організатора автоматично',
			'homeLayout.removeRow' => 'Зняти ряд',
			'homeLayout.recentlyAdded' => 'Нещодавно додані',
			'homeLayout.recentlyReleased' => 'Нещодавно звільнений',
			'homeLayout.movieCollections' => 'Колекції фільмів',
			'homeLayout.showCollections' => 'Покажіть колекції',
			'homeLayout.rowTitle' => 'Роу титул',
			'homeLayout.content' => 'Контент',
			'homeLayout.showThisRowIn' => 'Показати цю рядку в:',
			'homeLayout.libraryRecommended' => 'Рекомендована бібліотека',
			'homeLayout.heroCard' => 'Герой картки',
			'homeLayout.heroCardDescription' => 'Показано як одна повна широта ротаційна карта замість плакатної шафи.',
			'homeLayout.heroUnavailableDescription' => 'Доступно тільки тоді, коли ця рядка розв\'язується до реальних заголовків однієї колекції — з більш ніж однією колекцією вибраних немає жодного заголовка, який би міг би перевернути.',
			'homeLayout.librariesSelection' => 'Бібліотеки (відпустіть всі не перевірені для включення кожної бібліотеки)',
			'homeLayout.librariesMergedDescription' => 'Кожна бібліотека, що перевіряється тут, поєднується в цей один ряд.',
			'homeLayout.movieCollectionsSelection' => 'Колекції фільмів (залишити всі не перевірені для кожної вибраної бібліотеки)',
			'homeLayout.showCollectionsSelection' => 'Показати колекції (залишити всі непереглянуті для кожної вибраної бібліотеки)',
			'homeLayout.collectionRowsDescription' => 'Якщо саме одна колекція зіграє, її заголовки відображаються безпосередньо в рядку. якщо більше однієї зіграє, кожна колекція відображається як один плакат — натисніть її, щоб відкрити цю колекцію.',
			'homeLayout.allCollections' => 'Всі колекції',
			'homeLayout.noRowsHere' => 'Поки що тут немає рядів.',
			'homeLayout.hideWatchedRows' => 'Закрити спостережені предмети в рядках',
			'homeLayout.hideWatchedRowsDescription' => 'Повноцінно переглянуті заголовки залишають Домашнє та бібліотечне Рекомендовані рядки.',
			'homeLayout.untitledCollection' => 'Незаголошена колекція',
			'homeLayout.moveRowHint' => 'Завантажити / Завантажити: перемістити ряд · Виберіть: залишити тут · Звернути: скасувати',
			'homeLayout.organizeRowsHint' => 'Виберіть на рядку (або тримайте Виберіть): перемістіть · Ліворуч/Праворуч: варіанти рядку · Повернутись: зроблено',
			'homeLayout.layoutNavDescription' => 'Виберіть рядки, бібліотеки та колекційні категорії',
			'homeLayout.editHomeRow' => 'Реферат на тему: Home Row',
			'homeLayout.resetHeroButton' => 'Перезавантажити героїчний розклад на запас Plezy',
			'homeLayout.reorderingUnlocked' => 'Перезавантаження відключено',
			'homeLayout.reorderingLocked' => 'Перезавантаження заблоковано',
			'homeLayout.rowsCanBeDragged' => 'Використання зубів можна відтягнути — натисніть замок, щоб запобігти цьому',
			'homeLayout.tapLockToDrag' => 'Натисніть замок, щоб витягнути рядки',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Кваліфікація: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Приховати',
			'homeLayout.remove' => 'Видалити',
			'homeLayout.libraryResumeRow' => 'Бібліотека відновлюється',
			'homeLayout.pressAgainToDelete' => 'Натисніть знову, щоб видалити',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'На',
			'homeLayout.resetHeroButtonDescription' => 'Відкидає налаштування героя кожної серії і повертає єдиний ротаційний банер вгору, як і до того, як героїчні серії існували.',
			'platform.localNetworkPermission' => 'PlezyNG підключається до ваших медіа-серверів та пристроїв відтворення на вашій локальній мережі.',
			'platform.locationPermission' => 'PlezyNG використовує доступ до геопозиції, коли iOS вимагає його для виявлення локальної мережі та підключення до ваших медіасерверів.',
			'platform.photoLibraryPermission' => 'Виберіть зображення з фототеки для обкладинок медіафайлів.',
			'platform.cameraPermission' => 'Сканувати QR-коди, щоб з\'єднати Companion Remote.',
			'fileSources.title' => 'Файли та книги',
			'fileSources.subtitle' => 'Читати, слухати і спостерігати за своїми файлами.',
			'fileSources.add' => 'Додати джерело',
			'fileSources.importFiles' => 'Імпорт файлів',
			'fileSources.localFiles' => 'На цьому пристрої',
			'fileSources.source' => 'Джерело',
			'fileSources.name' => 'Ім’я',
			'fileSources.endpoint' => 'Сервер URL',
			'fileSources.root' => 'Папка або префікс',
			'fileSources.username' => 'Ім’я користувача',
			'fileSources.password' => 'Пароль',
			'fileSources.token' => 'API токен',
			'fileSources.accessKey' => 'Доступний ключ ID',
			'fileSources.secretKey' => 'Секретний ключ доступу',
			'fileSources.sessionToken' => 'Сеанс токен (опціональний)',
			'fileSources.region' => 'Регіон',
			'fileSources.clientId' => 'Клієнт ID',
			'fileSources.clientSecret' => 'OAuth Client Secret (один робочий стіл Google)',
			'fileSources.allowHttp' => 'Дозволити незашифроване HTTP-з’єднання в довіреній мережі',
			'fileSources.connect' => 'Підключитись',
			'fileSources.cancel' => 'Скасувати',
			'fileSources.save' => 'Зберегти',
			'fileSources.close' => 'Закрити',
			'fileSources.removeSource' => 'Відключення джерела',
			'fileSources.disconnectMessage' => 'Від’єднати це джерело? Завантажені файли та історія читання й прослуховування залишаться на цьому пристрої.',
			'fileSources.localFolder' => 'Вибір папки',
			'fileSources.empty' => 'Тут ще нічого',
			'fileSources.emptyHint' => 'Додайте джерело або імпортуйте книгу, аудіокнигу, музику або відео.',
			'fileSources.search' => 'Пошук цього папки',
			'fileSources.searchCached' => 'Пошук збережена бібліотека',
			'fileSources.refresh' => 'Оновити',
			'fileSources.loadMore' => 'Завантажити більше',
			'fileSources.offline' => 'Доступно офлайн',
			'fileSources.download' => 'Залишити офлайн',
			'fileSources.removeDownload' => 'Видалення офлайн копії',
			'fileSources.continueReading' => 'Читати далі',
			'fileSources.continueListening' => 'Продовжити прослуховування',
			'fileSources.continueWatching' => 'Продовжити перегляд',
			'fileSources.read' => 'Читати',
			'fileSources.listen' => 'Слухати',
			'fileSources.play' => 'Грати',
			'fileSources.pause' => 'Пауза',
			'fileSources.stop' => 'Зупинити',
			'fileSources.startOver' => 'Почнемо з',
			'fileSources.finished' => 'Завершено',
			'fileSources.markFinished' => 'Марк закінчився',
			'fileSources.markUnfinished' => 'Марк нескінченний',
			'fileSources.editions' => 'Епізоди та файли',
			'fileSources.chapters' => 'Розділи',
			'fileSources.bookmarks' => 'Книжкові знаки та нотації',
			'fileSources.bookmark' => 'Додати книжковий знак',
			'fileSources.highlight' => 'Підвищення',
			'fileSources.note' => 'Зауважимо',
			'fileSources.delete' => 'Видалити',
			'fileSources.export' => 'Експортні нотації',
			'fileSources.exported' => 'Нотації експортуються',
			'fileSources.sync' => 'Сінтеграція прогресу',
			'fileSources.synced' => 'Прогрес синхронізований',
			'fileSources.conflict' => 'Інший пристрій має іншу позицію. виберіть, де продовжувати.',
			'fileSources.useLocal' => 'Використовуйте цей пристрій',
			'fileSources.useRemote' => 'Використовуйте інші пристрої',
			'fileSources.history' => 'Історія позиції',
			'fileSources.groupAudio' => 'Слухайте як аудіокнигу',
			'fileSources.groupHint' => 'Об’єднує аудіофайли, завантажені зараз у цій папці. Спочатку завантажте всі сторінки.',
			'fileSources.order' => 'Файловий порядок',
			'fileSources.moveUp' => 'Змінюйся',
			'fileSources.moveDown' => 'Перемістити вниз',
			'fileSources.speed' => 'Швидкість відтворення',
			'fileSources.sleep' => 'Тимчасовий сон',
			'fileSources.sleepOff' => 'Вимкнути',
			'fileSources.endChapter' => 'Кінець розділу',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('uk'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилина', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилини', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилин', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} хвилини', ), 
			'fileSources.skipBack' => 'Скіп назад',
			'fileSources.skipForward' => 'Скіп вперед',
			'fileSources.smartRewind' => 'Смарт-реванш після перерви',
			'fileSources.playbackOptions' => 'Вибір слухача',
			'fileSources.remaining' => ({required Object time}) => '${time} залишився',
			'fileSources.contents' => 'Контент',
			'fileSources.readerSettings' => 'Читати Постачання',
			'fileSources.fontSize' => 'Розмір тексту',
			'fileSources.lineHeight' => 'Лінія простір',
			'fileSources.margin' => 'Маргіна',
			'fileSources.font' => 'Тип',
			'fileSources.serif' => 'Серіф',
			'fileSources.sans' => 'Без засічок',
			'fileSources.mono' => 'Моноширинний',
			'fileSources.columns' => 'Колонки',
			'fileSources.scroll' => 'Скріл вертикально',
			'fileSources.justify' => 'Вирівняти текст за шириною',
			'fileSources.readerTheme' => 'Поява сторінки',
			'fileSources.appTheme' => 'Слідкуйте за темою App',
			'fileSources.paper' => 'папір',
			'fileSources.sepia' => 'Сепія',
			'fileSources.night' => 'Ночі',
			'fileSources.readAloud' => 'Читати цю сторінку голосно',
			'fileSources.readAlong' => 'Читати далі',
			'fileSources.stopReading' => 'Зупинити озвучення',
			'fileSources.searchBook' => 'Пошук в книзі',
			'fileSources.noMatches' => 'Ніяких матчів',
			'fileSources.previousPage' => 'Попередня сторінка',
			'fileSources.nextPage' => 'Наступна сторінка',
			'fileSources.page' => ({required Object number}) => 'Сторінка ${number}',
			'fileSources.externalBlocked' => 'Зовнішні посилання в книгах вимкнено в читачі.',
			'fileSources.loading' => 'Відкриття...',
			'fileSources.narrator' => 'Назавжди',
			'fileSources.audio' => 'Аудіо',
			'fileSources.video' => 'Відео',
			'fileSources.ebooks' => 'Ексклюзивні',
			'fileSources.all' => 'Всі',
			'fileSources.downloads' => 'Офлайн файли',
			'fileSources.confirmDelete' => 'Видалити вибрану офлайн-копію? Ваше місце читання або прослуховування та нотатки збережуться.',
			'fileSources.errorAuthentication' => 'Увійдіть знову, щоб відновити з’єднання з цим джерелом.',
			'fileSources.errorPermission' => 'Цей джерело не надало доступу до запитуваного файлу.',
			'fileSources.errorUnavailable' => 'Попробуйте знову або відкрийте офлайн-копію.',
			'fileSources.errorUnsupported' => 'Цей формат або підключення не підтримується на цьому пристрої. перевірте джерело інсталяції.',
			'fileSources.errorInvalidData' => 'Цей файл або серверний відповідь не можна було безпечно читати.',
			'fileSources.errorCancelled' => 'Операція була скасована.',
			'fileSources.errorConflict' => 'Позиція змінилася в іншому сесії. знову відкрити пункт, щоб вибрати позицію.',
			'fileSources.signIn' => 'Вхід',
			'fileSources.reconnect' => 'Відновлення',
			'fileSources.folderHelp' => 'Залишити вільний, щоб почати з коріння джерела. URL-адреси S3 включають букет.',
			'fileSources.preferences' => 'Переваги',
			'fileSources.timePosition' => 'Позиція',
			'fileSources.audioTrack' => 'Аудіо трак',
			'fileSources.subtitleTrack' => 'Підзаголовок трак',
			'fileSources.none' => 'Нічого',
			'fileSources.fullscreen' => 'Повний екран',
			'fileSources.syncLocation' => 'Прогрес синхронізування папки (опціональна)',
			'fileSources.syncLocationHint' => 'Окрема папка WebDAV для стану PlezyNG. Використовує умовний запис; медіафайли не змінюються.',
			'fileSources.audiobooks' => 'Аудіокниги',
			'fileSources.comics' => 'Комікси',
			'fileSources.scan' => 'Скенію для книг та медіа',
			'fileSources.browserReader' => 'Відкритий читач',
			'fileSources.browserReaderHelp' => 'Читач відкритий у вашому браузері. Зберігайте PlezyNG відкритим, щоб зберегти своє місце і записи.',
			'fileSources.on' => 'На',
			'fileSources.advancedSetup' => 'App реєстрація',
			'fileSources.microsoftSignIn' => 'Підписуйтесь з Microsoft',
			'fileSources.zoomIn' => 'Зоо в',
			'fileSources.zoomOut' => 'Зом вийде',
			'fileSources.fitPage' => 'Файт сторінка',
			'fileSources.fitWidth' => 'Ширина підходить',
			'fileSources.actualSize' => 'Теперішній розмір',
			'fileSources.goToPage' => 'Перейти на сторінку',
			'fileSources.goToSection' => 'Перейти до розділу',
			'fileSources.pageRange' => ({required Object count}) => 'Введіть номер від 1 до ${count}',
			'fileSources.pageLayout' => 'Page Layout',
			'fileSources.automatic' => 'Автоматичний',
			'fileSources.singlePage' => 'Єдиний сайт',
			'fileSources.twoPages' => '2 Сторінки',
			'fileSources.readingDirection' => 'Читання напрямків',
			'fileSources.leftToRight' => 'Зліва направо',
			'fileSources.rightToLeft' => 'Справа наліво',
			'fileSources.letterSpacing' => 'Письмо простір',
			'fileSources.wordSpacing' => 'Слово простір',
			'fileSources.readerControlsHelp' => 'Щоб збільшити сторінку, розведіть два пальці або скористайтеся кнопками масштабування. Перетягуйте, щоб переміщувати сторінку. Ctrl/⌘ разом із + або − змінює масштаб; Ctrl/⌘ разом із 0 скидає його. Page Up і Page Down перегортають сторінки.',
			'fileSources.imagePage' => 'Сторінка коміксу',
			'fileSources.resetReader' => 'Перезавантаження переваг читання',
			'fileSources.zoom' => 'Масштабувати',
			'fileSources.useFiles' => 'Використовуйте файли та книги',
			'fileSources.cancelScan' => 'Сканувати сканування',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.smbEndpointHint' => 'Приклад: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Введіть сервер SMB та одну спільну папку.',
			'fileSources.smbFolderHelp' => 'Залиште поле порожнім, щоб використовувати всю спільну папку, або вкажіть папку всередині неї.',
			'fileSources.smbDomain' => 'Домен (необов’язково)',
			'fileSources.smbEncryption' => 'Шифрувати з’єднання SMB3',
			'fileSources.smbEncryptionHint' => 'Використовувати шифрування SMB3, якщо NAS його підтримує.',
			'lending.title' => 'публічні бібліотеки',
			'lending.add' => 'Додати бібліотеку',
			'lending.other' => 'Інша бібліотека',
			'lending.libraryName' => 'Назва бібліотеки',
			'lending.libraryUrl' => 'Бібліотека сайт',
			'lending.libraryUrlHint' => 'Скористайтеся каталогом бібліотеки або її сторінкою входу.',
			'lending.intro' => 'Позичайте книги у своїй бібліотеці й тримайте їх поруч.',
			'lending.handoff' => 'Увійдіть, позичайте книги й читайте безпечно через власний сервіс бібліотеки.',
			'lending.openService' => 'Відкрита бібліотека',
			'lending.findLibrary' => 'Знайдіть бібліотеку',
			'lending.search' => 'Пошук книг та авторів',
			'lending.catalogue' => 'каталог',
			'lending.loans' => 'Позичені книги',
			'lending.holds' => 'Бронювання',
			'lending.signIn' => 'Підписуйтесь у Вашій бібліотеці',
			'lending.waiting' => 'Завершити підписання в браузері, а потім повернутися сюди.',
			'lending.cancel' => 'Скасувати',
			'lending.disconnect' => 'Видалення бібліотеки',
			'lending.disconnectMessage' => 'Вилучити цю бібліотеку з цього профілю? Ваші позичені книги та бронювання залишаться в бібліотеці.',
			'lending.getBook' => 'Отримайте книгу',
			'lending.checkAvailability' => 'Перевірка наявності',
			'lending.available' => 'Доступно для позики',
			'lending.unavailable' => 'В даний час недоступні',
			'lending.borrow' => 'Позичити',
			'lending.placeHold' => 'Забронювати',
			'lending.returnBook' => 'Повернення рано',
			'lending.cancelHold' => 'Скасувати бронювання',
			'lending.confirmBorrow' => 'Ви можете замовити цю книжку у вашій бібліотеці?',
			'lending.confirmReturn' => 'Ви можете повернути цей титул зараз? Ви можете замовити його знову, щоб продовжити.',
			'lending.confirmCancelHold' => 'Скасувати бронювання цього видання?',
			'lending.email' => 'Зберігайте повідомлення електронною поштою',
			'lending.due' => ({required Object date}) => 'Повернути до ${date}',
			'lending.queue' => ({required Object position}) => 'Позиція ${position} в лінії',
			'lending.empty' => 'Тепер тут немає титулів.',
			'lending.openLibraryNote' => 'Переглядайте каталог Open Library. Варіанти читання й позичання наведено на сторінці кожного видання.',
			'lending.more' => 'Завантажити більше',
			'lending.gateway' => 'Бібліотека підписується',
			'lending.gatewayHint' => 'Пропонується вашою бібліотекою або адміністратором PlezyNG.',
			'lending.advanced' => 'Бібліотека інтеграція',
			'lending.loadLibraries' => 'Виберіть свою бібліотеку',
			'lending.expired' => 'Термін користування цією книгою минув.',
			'lending.updated' => 'Бібліотека оновлена',
			'lending.continueService' => 'Продовжуйте службу',
			'lending.comingSoon' => 'Заробітна плата в Україні · Приїжджає незабаром',
			'lending.comingSoonDescription' => 'Ви можете використовувати свою бібліотеку в Libby, поки ми закінчимо підключення її.',
			'lending.suspendHold' => 'Призупинити бронювання',
			'lending.resumeHold' => 'Відновити бронювання',
			'lending.suspendMessage' => 'Зберегти своє місце в черзі й дозволити наступному читачеві позичити цей примірник? Бронювання можна відновити пізніше.',
			'lending.resumeMessage' => 'Відновити бронювання, щоб бібліотека могла запропонувати вам наступний доступний примірник?',
			'lending.editEmail' => 'Зміни повідомлення електронної пошти',
			'audiobook.syncTitle' => 'Читання та слухання Sync',
			'audiobook.syncHelp' => 'Зберігайте позиції читання, позиції слуху, стан завершення, знаки книг і записи на ваших пристроях. Виберіть прикріплений обліковий запис зберігання і використовуйте той же код синхронізації на кожному пристрої. Читання і слухання залишаються окремими.',
			'audiobook.addSyncSource' => 'Перш за все, додайте Google Drive, OneDrive, Dropbox, WebDAV або S3 до файлів і книг.',
			'audiobook.syncDestination' => 'Синхронізація облікового запису',
			'audiobook.syncFolder' => 'Завантажити папку або префікс',
			'audiobook.syncFolderHelp' => 'Використовуйте окрему існуючу папку в межах свого джерела WebDAV, або присвячений S3 заздалегідь.',
			'audiobook.syncCode' => 'Приватний код синхронізації',
			'audiobook.syncCodeHelp' => 'Створіть код на першому пристрої, а потім введіть цей код на інших пристроях. Зберігайте приватну копію: це ключ до вашого зашифрованого стану.',
			'audiobook.showCode' => 'Показати або приховати код синхронізації',
			'audiobook.newSyncCode' => 'Створення нового синхронізаційного коду',
			'audiobook.saveSync' => 'Зберегти і синхронізувати',
			'audiobook.disableSync' => 'Вимкніть синхронізацію на цьому пристрої',
			'audiobook.syncSourceDisconnect' => 'Видалення цього джерела вимкне читання і слухання синхронізації тут. шифровані синхронізовані файли залишаться в провайдері.',
			'audiobook.syncReconnect' => 'Відновлення облікового запису',
			'audiobook.lastSynced' => ({required Object time}) => 'Останній синхронізований на ${time}',
			'audiobook.syncPrivacy' => 'Тільки зашифровані прогрес і записи зберігаються. аудіо- і електронні файли, токенів облікового запису та паролі не завантажуються. Google Drive і OneDrive використовують приклад зберігання; Dropbox використовує PlezyNG Sync. дозволяючи синхронування може вимагати додаткового письмового доступу. Хоча включено, ця дестинація володіє синхроном прогресу; прогрес сервера залишається окремим.',
			'audiobook.syncConflicts' => 'Виберіть, де відновити',
			'audiobook.conflictHelp' => 'Ці зміни були зроблені самостійно. виберіть позицію або версію знака, щоб зберегти. Пізній час або більш високий відсоток не автоматично виграє.',
			'audiobook.syncDevice' => ({required Object device}) => 'Створення ${device}',
			'audiobook.syncUnknownDevice' => 'Невідомий пристрій',
			'audiobook.deletedBookmark' => 'Усунути книжковий знак',
			'audiobook.finished' => 'Завершено',
			'audiobook.readingPosition' => ({required Object percent}) => 'Читати · ${percent}%',
			'audiobook.chapterTimeline' => 'Розділ Прогрес',
			'audiobook.bookTimeline' => 'Книга Прогрес',
			'audiobook.bookRemaining' => ({required Object time}) => 'Залишився час в цій книзі: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Час, що залишився в цій главі: ${time}',
			'audiobook.unknownRemaining' => 'Повний доступний час, коли граються частини',
			'audiobook.undoSeek' => 'Останній пошук',
			'audiobook.customSpeed' => 'Швидкість відтворення',
			'audiobook.speedHelp' => 'Виберіть швидкість від 0,25× до 4×.',
			'audiobook.apply' => 'Заявка',
			'audiobook.customSleep' => 'Кваліфікований час сну',
			'audiobook.sleepMinutes' => '1 хвилини (1 – 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Залишився після розділів ${count}',
			'audiobook.extendSleep' => 'Додайте 5 хвилин',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Тимпер сну: ${time}',
			'audiobook.useDefaults' => 'Використовуйте ці контрольні системи для нових книг',
			'audiobook.librarySort' => 'Сорт книг',
			'audiobook.sortTitle' => 'Заголовок',
			'audiobook.sortAuthor' => 'Автор',
			'audiobook.sortNarrator' => 'Назавжди',
			'audiobook.sortSeries' => 'Серія замовлення',
			'audiobook.sortRecent' => 'Нещодавно відкрито',
			'audiobook.statusFilter' => 'Статус читання',
			'audiobook.statusAll' => 'Всі книги',
			'audiobook.statusNew' => 'Не розпочато',
			'audiobook.statusProgress' => 'в прогресі',
			'audiobook.statusFinished' => 'Завершено',
			'audiobook.goToTime' => 'Ідіть до часу',
			'audiobook.timeHelp' => 'Час: хвилини: секунди або хвилини: секунди',
			'sourceSetup.savedCertificate' => 'Збережений сертифікат сервера',
			'sourceSetup.nfsEndpointInvalid' => 'Введіть URL NFS, наприклад nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Серверів DLNA не знайдено. Введіть URL опису пристрою вручну.',
			'sourceSetup.dlnaServers' => 'Медіасервери DLNA',
			'sourceSetup.dlnaUnavailable' => 'Виявлення DLNA недоступне в цій мережі. Введіть URL опису пристрою вручну.',
			'sourceSetup.dlnaSearching' => 'Пошук серверів DLNA в локальній мережі',
			'sourceSetup.networkSearching' => 'Пошук у локальній мережі…',
			'sourceSetup.dlnaDiscover' => 'Знайти сервери DLNA',
			'sourceSetup.dlnaHelp' => 'Виявлення залежить від багатоадресної розсилки в локальній мережі. Якщо сервер не з’являється, введіть вище URL опису його пристрою.',
			'sourceSetup.dlnaRoot' => 'ID об’єкта DLNA; залиште порожнім, щоб використати корінь пристрою.',
			'sourceSetup.passwordOrKey' => 'Введіть пароль або додайте приватний ключ нижче.',
			'sourceSetup.sshFingerprint' => 'Відбиток SHA256 ключа хоста SSH',
			'sourceSetup.sshFingerprintHelp' => 'Звірте його з адміністратором сервера. На сервері виконайте ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub і використайте значення SHA256.',
			'sourceSetup.sshFingerprintKeep' => 'Залиште порожнім, щоб зберегти закріплений відбиток, або введіть новий відбиток сервера.',
			'sourceSetup.sshAuthentication' => 'Автентифікація SSH за відкритим ключем',
			'sourceSetup.sshAuthenticationHelp' => 'Необов’язково; автентифікація за паролем також підтримується.',
			'sourceSetup.privateKey' => 'Приватний ключ (формат PEM або OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Парольна фраза приватного ключа',
			'sourceSetup.nfsMountPort' => 'TCP-порт служби монтування NFS',
			'sourceSetup.nfsMountPortHelp' => 'Типово: 20048',
			'sourceSetup.nfsUserId' => 'ID користувача NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Типово: 1000. Використайте ID, дозволений експортом NFS на NAS.',
			'sourceSetup.nfsGroupId' => 'ID групи NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Типово: 1000. Використайте ID групи, дозволений експортом NFS на NAS.',
			'sourceSetup.nfsEncryption' => 'Вимагати шифрування NFS (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Вимагати TLS 1.3 для NFS і служби монтування. Якщо NAS цього не підтримує, з’єднання буде відхилено.',
			'sourceSetup.nfsTrustCertificate' => 'Власний CA NFS або сертифікат сервера (PEM, необов’язково)',
			'sourceSetup.nfsTrustHelp' => 'Залиште порожнім для сертифікатів, яким довіряє цей пристрій. За потреби додайте сертифікат приватного CA або самопідписаний сертифікат сервера; імена в ньому мають відповідати хосту в URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Використайте сертифікат CA або сервера у форматі PEM. Не додавайте приватний ключ.',
			'sourceSetup.addTrustCertificate' => 'Додати власний довірений сертифікат',
			'sourceSetup.replaceTrustCertificate' => 'Замінити збережений власний сертифікат',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS використовує звичайні порти NFS і служби монтування та потребує підтримки RFC 9289 на NAS. Потрібен TLS 1.3. Ім’я хоста або IP-адреса мають відповідати сертифікату. UID/GID AUTH_SYS і далі застосовуються в зашифрованому каналі.',
			'sourceSetup.clientCertificate' => 'Сертифікат клієнта (необов’язково)',
			'sourceSetup.clientCertificateHelp' => 'Дає змогу NAS автентифікувати цього клієнта; ID AUTH_SYS і далі залежать від правил експорту NFS на NAS.',
			'sourceSetup.savedIdentity' => 'Буде використано збережені ідентифікаційні дані клієнта.',
			'sourceSetup.replaceIdentity' => 'Замінити збережені ідентифікаційні дані клієнта',
			'sourceSetup.chooseIdentity' => 'Вибрати ідентифікаційні дані клієнта PKCS#12',
			'sourceSetup.identityPassphrase' => 'Парольна фраза ідентифікаційних даних клієнта',
			'sourceSetup.identityPassphraseHelp' => 'Залиште порожнім, якщо файл не має парольної фрази.',
			'sourceSetup.removeIdentity' => 'Вилучити збережені ідентифікаційні дані клієнта',
			'sourceSetup.identityStorageHelp' => 'Ідентифікаційні дані клієнта зберігаються в зашифрованому сховищі облікових даних джерела. Не змінюйте цей розділ, щоб зберегти наявні ідентифікаційні дані.',
			'sourceSetup.nfsLimitations' => 'NFSv3 через TCP, лише читання. Без RPC-with-TLS трафік NFS не шифрується. NAS має дозволяти вибрані ID AUTH_SYS і непривілейовані порти клієнта (часто це параметр експорту «insecure»). NFSv4 та UDP не підтримуються.',
			'sourceSetup.nfsSetupHelp' => 'Довідка з налаштування NFS',
			'sourceSetup.nfsSetupHint' => 'Перевірте ці налаштування, якщо з’єднання не встановлюється.',
			'sourceSetup.nfsSetupDetails' => 'Використайте експорт NFSv3 через TCP. Якщо потрібне шифрування, і служба NFS, і служба монтування мають підтримувати RPC-with-TLS. Залиште власний сертифікат порожнім для сертифіката сервера, якому довіряє цей пристрій, або додайте сертифікат CA NAS чи самопідписаний сертифікат. Ім’я в сертифікаті має відповідати хосту кінцевої точки. Якщо NAS вимагає взаємної автентифікації TLS, додайте його ідентифікаційні дані клієнта PKCS#12. Насамкінець переконайтеся, що експорт дозволяє налаштовані UID/GID AUTH_SYS і правила портів клієнта.',
			'sourceSetup.ftpHelp' => 'FTP використовує пасивний режим. Використовуйте ftp:// для FTP без шифрування, ftpes:// для явного TLS або ftps:// для TLS (неявного на порту 990; явного на інших портах).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Необов’язковий пошук субтитрів для окремих відео.',
			'sourceSetup.apiKey' => 'Ключ API',
			'sourceSetup.optionalUsername' => 'Ім’я користувача облікового запису (необов’язково)',
			'sourceSetup.optionalPassword' => 'Пароль облікового запису (необов’язково)',
			'sourceSetup.subtitlePrivacy' => 'Отримайте ключ API на opensubtitles.com. Пошук надсилає назву відео й доступні ID IMDb/TMDB, але ніколи не надсилає відеофайл. Ключ і необов’язкові облікові дані шифруються разом із цим джерелом.',
			'sourceSetup.automaticMetadata' => 'Автоматичні метадані відео з інтернету',
			'sourceSetup.metadataPrivacy' => 'Надсилає лише назву/рік з імені файлу та номери епізодів або ID NFO, але ніколи не надсилає медіафайли чи облікові дані. Поля NFO зберігають пріоритет.',
			'sourceSetup.nfsEncryptionFailure' => 'Для зашифрованого NFS перевірте підтримку RFC 9289 і TLS 1.3 обома службами NAS, ім’я в сертифікаті та UID/GID експорту. PlezyNG не повторюватиме це з’єднання без шифрування.',
			'sourceSetup.sourceConnecting' => 'Підключення до джерела',
			'sourceSetup.metadataSearchPrivacy' => 'Цей пошук назви надсилається до Trakt. Передається введена назва, а не відео чи облікові дані джерела.',
			'sourceSetup.chooseMatch' => 'Вибрати збіг',
			'sourceSetup.metadataMatchHelp' => 'Перед вибором перевірте назву й рік. Trakt отримує пошукову назву; відео залишається у своєму джерелі.',
			'sourceSetup.metadataNoMatches' => 'Відповідних назв в інтернеті не знайдено. Спробуйте іншу назву.',
			'sourceSetup.metadataSearch' => 'Пошук метаданих в інтернеті',
			'sourceSetup.metadataLoading' => 'Пошук відомостей про фільми й серіали в інтернеті…',
			'sourceSetup.metadataFromTrakt' => 'Метадані з Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Автоматичного збігу назви не знайдено. Знайдіть назву, щоб вибрати збіг.',
			'sourceSetup.metadataFailed' => 'Не вдалося завантажити метадані з інтернету. Відтворення та локальні відомості залишаються доступними.',
			'sourceSetup.videoDetailsLoading' => 'Завантаження відомостей про відео',
			'sourceSetup.subtitleKeyRequired' => 'Потрібен ключ API OpenSubtitles',
			'sourceSetup.subtitleKeyHelp' => 'Змініть це файлове джерело й додайте ключ API OpenSubtitles у необов’язкових налаштуваннях субтитрів.',
			'sourceSetup.subtitleSearchFailed' => 'Пошук субтитрів не вдався. Перевірте ключ API, з’єднання й доступ до сервісу.',
			'sourceSetup.subtitleApplyFailed' => 'Не вдалося завантажити або застосувати ці субтитри. Перевірте з’єднання й спробуйте інший результат.',
			'sourceSetup.subtitleSearch' => 'Пошук в OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'Пошук використовує назву й доступні ID IMDb/TMDB. Відеофайл залишається у своєму джерелі. Перед вибором перевірте мову, позначки примусових субтитрів або субтитрів для людей із порушеннями слуху та оцінку.',
			'sourceSetup.movieOrShow' => 'Фільм або серіал',
			'sourceSetup.subtitleTitleHint' => 'Введіть назву, щоб уточнити результати',
			'sourceSetup.subtitleLanguage' => 'Мова субтитрів',
			'sourceSetup.subtitleSearching' => 'Пошук в OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Відповідних субтитрів не знайдено. Спробуйте іншу назву або мову.',
			'sourceSetup.downloadSubtitle' => 'Завантажити субтитри',
			'sourceSetup.subtitle' => 'Субтитри',
			'sourceSetup.nfsTlsRequired' => 'Потрібен RPC-with-TLS',
			'sourceSetup.nfsUnencrypted' => 'NFS без шифрування',
			'sourceSetup.tlsEncrypted' => 'Шифрування TLS',
			'sourceSetup.ftpPlain' => 'FTP без шифрування',
			'sourceSetup.sshPinned' => 'SSH із шифруванням · ключ хоста закріплено',
			'sourceSetup.smbEncrypted' => 'Шифрування SMB3 увімкнено',
			'sourceSetup.smbUnencrypted' => 'Шифрування SMB3 вимкнено',
			'sourceSetup.httpUnencrypted' => 'HTTP без шифрування транспорту',
			_ => null,
		} ?? switch (path) {
			'sourceSetup.checkEndpointSecurity' => 'Перевірити безпеку кінцевої точки',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'Обов’язкове поле: ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Для поля «${label}» введіть значення від ${min} до ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Замінити ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Вибрані ідентифікаційні дані клієнта: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Оцінка ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Завантаження субтитрів: ${title}',
			'comics.fitHeight' => 'За висотою',
			'comics.readingMode' => 'Режим читання',
			'comics.paged' => 'Сторінки',
			'comics.webtoon' => 'Безперервне прокручування',
			'comics.coverAlone' => 'Показувати обкладинку окремо',
			'comics.splitWide' => 'Розділяти широкі сторінки',
			'comics.splitWideHelp' => 'Показувати кожну половину окремо в порядку читання. Поки цю опцію ввімкнено, сторінки не відображаються парами.',
			'comics.thumbnails' => 'Мініатюри сторінок',
			'comics.controlsHelp' => 'Проведіть, щоб перегорнути сторінку. Подвійне торкання змінює припасування розміру. При безперервному прокручуванні проводьте вертикально або використовуйте Page Up і Page Down.',
			'comics.savedForComic' => 'Налаштування відображення зберігаються для цього коміксу в цьому профілі.',
			'comics.readLists' => 'Списки читання',
			'comics.collections' => 'Колекції',
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
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.steamLibraryHint' => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.',
			_ => null,
		};
	}
}
