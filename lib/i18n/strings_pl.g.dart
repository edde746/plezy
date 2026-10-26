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
class TranslationsPl extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPl({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pl,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pl>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsPl _root = this; // ignore: unused_field

	@override 
	TranslationsPl $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPl(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$pl app = _Translations$app$pl._(_root);
	@override late final _Translations$cast$pl cast = _Translations$cast$pl._(_root);
	@override late final _Translations$automation$pl automation = _Translations$automation$pl._(_root);
	@override late final _Translations$notifications$pl notifications = _Translations$notifications$pl._(_root);
	@override late final _Translations$appIcon$pl appIcon = _Translations$appIcon$pl._(_root);
	@override late final _Translations$auth$pl auth = _Translations$auth$pl._(_root);
	@override late final _Translations$common$pl common = _Translations$common$pl._(_root);
	@override late final _Translations$screens$pl screens = _Translations$screens$pl._(_root);
	@override late final _Translations$update$pl update = _Translations$update$pl._(_root);
	@override late final _Translations$appAccess$pl appAccess = _Translations$appAccess$pl._(_root);
	@override late final _Translations$settings$pl settings = _Translations$settings$pl._(_root);
	@override late final _Translations$themeEditor$pl themeEditor = _Translations$themeEditor$pl._(_root);
	@override late final _Translations$search$pl search = _Translations$search$pl._(_root);
	@override late final _Translations$hotkeys$pl hotkeys = _Translations$hotkeys$pl._(_root);
	@override late final _Translations$fileInfo$pl fileInfo = _Translations$fileInfo$pl._(_root);
	@override late final _Translations$mediaMenu$pl mediaMenu = _Translations$mediaMenu$pl._(_root);
	@override late final _Translations$rateSheet$pl rateSheet = _Translations$rateSheet$pl._(_root);
	@override late final _Translations$accessibility$pl accessibility = _Translations$accessibility$pl._(_root);
	@override late final _Translations$tooltips$pl tooltips = _Translations$tooltips$pl._(_root);
	@override late final _Translations$audioTracks$pl audioTracks = _Translations$audioTracks$pl._(_root);
	@override late final _Translations$videoControls$pl videoControls = _Translations$videoControls$pl._(_root);
	@override late final _Translations$messages$pl messages = _Translations$messages$pl._(_root);
	@override late final _Translations$subtitlingStyling$pl subtitlingStyling = _Translations$subtitlingStyling$pl._(_root);
	@override late final _Translations$mpvConfig$pl mpvConfig = _Translations$mpvConfig$pl._(_root);
	@override late final _Translations$dialog$pl dialog = _Translations$dialog$pl._(_root);
	@override late final _Translations$profiles$pl profiles = _Translations$profiles$pl._(_root);
	@override late final _Translations$connections$pl connections = _Translations$connections$pl._(_root);
	@override late final _Translations$accountPreferences$pl accountPreferences = _Translations$accountPreferences$pl._(_root);
	@override late final _Translations$discover$pl discover = _Translations$discover$pl._(_root);
	@override late final _Translations$errors$pl errors = _Translations$errors$pl._(_root);
	@override late final _Translations$libraries$pl libraries = _Translations$libraries$pl._(_root);
	@override late final _Translations$about$pl about = _Translations$about$pl._(_root);
	@override late final _Translations$serverSelection$pl serverSelection = _Translations$serverSelection$pl._(_root);
	@override late final _Translations$hubDetail$pl hubDetail = _Translations$hubDetail$pl._(_root);
	@override late final _Translations$logs$pl logs = _Translations$logs$pl._(_root);
	@override late final _Translations$detail$pl detail = _Translations$detail$pl._(_root);
	@override late final _Translations$startup$pl startup = _Translations$startup$pl._(_root);
	@override late final _Translations$licenses$pl licenses = _Translations$licenses$pl._(_root);
	@override late final _Translations$navigation$pl navigation = _Translations$navigation$pl._(_root);
	@override late final _Translations$explore$pl explore = _Translations$explore$pl._(_root);
	@override late final _Translations$liveTv$pl liveTv = _Translations$liveTv$pl._(_root);
	@override late final _Translations$collections$pl collections = _Translations$collections$pl._(_root);
	@override late final _Translations$playlists$pl playlists = _Translations$playlists$pl._(_root);
	@override late final _Translations$music$pl music = _Translations$music$pl._(_root);
	@override late final _Translations$watchTogether$pl watchTogether = _Translations$watchTogether$pl._(_root);
	@override late final _Translations$downloads$pl downloads = _Translations$downloads$pl._(_root);
	@override late final _Translations$shaders$pl shaders = _Translations$shaders$pl._(_root);
	@override late final _Translations$companionRemote$pl companionRemote = _Translations$companionRemote$pl._(_root);
	@override late final _Translations$videoSettings$pl videoSettings = _Translations$videoSettings$pl._(_root);
	@override late final _Translations$performanceOverlay$pl performanceOverlay = _Translations$performanceOverlay$pl._(_root);
	@override late final _Translations$externalPlayer$pl externalPlayer = _Translations$externalPlayer$pl._(_root);
	@override late final _Translations$metadataEdit$pl metadataEdit = _Translations$metadataEdit$pl._(_root);
	@override late final _Translations$matchScreen$pl matchScreen = _Translations$matchScreen$pl._(_root);
	@override late final _Translations$serverTasks$pl serverTasks = _Translations$serverTasks$pl._(_root);
	@override late final _Translations$trakt$pl trakt = _Translations$trakt$pl._(_root);
	@override late final _Translations$seerr$pl seerr = _Translations$seerr$pl._(_root);
	@override late final _Translations$services$pl services = _Translations$services$pl._(_root);
	@override late final _Translations$addServer$pl addServer = _Translations$addServer$pl._(_root);
	@override late final _Translations$watchLink$pl watchLink = _Translations$watchLink$pl._(_root);
	@override late final _Translations$homeLayout$pl homeLayout = _Translations$homeLayout$pl._(_root);
	@override late final _Translations$platform$pl platform = _Translations$platform$pl._(_root);
	@override late final _Translations$fileSources$pl fileSources = _Translations$fileSources$pl._(_root);
	@override late final _Translations$lending$pl lending = _Translations$lending$pl._(_root);
	@override late final _Translations$audiobook$pl audiobook = _Translations$audiobook$pl._(_root);
}

// Path: app
class _Translations$app$pl extends Translations$app$en {
	_Translations$app$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: cast
class _Translations$cast$pl extends Translations$cast$en {
	_Translations$cast$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Wskaż na urządzenie';
	@override String get searching => 'W poszukiwaniu urządzeń do odbioru...';
	@override String connectedTo({required Object device}) => 'Źródło: ${device}';
	@override String get device => 'Urządzenie Cast';
	@override String get readyToCast => 'gotowy do wyrzucenia';
	@override String get subtitle => 'Napisy';
	@override String get serverNotAvailable => 'Serwer medialny nie jest dostępny.';
	@override String get stopCasting => 'Przestań casting';
	@override String get castToDevice => 'Złóż na urządzenie';
	@override String get noEpisodeAvailable => 'Nie ma żadnego odcinka do odtwarzania.';
	@override String get startFailed => 'Nie można zacząć casting. sprawdź serwer i spróbuj ponownie.';
}

// Path: automation
class _Translations$automation$pl extends Translations$automation$en {
	_Translations$automation$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Nie ma aktywnej sesji wideo do kontroli.';
	@override String get profileNotFound => 'Ten profil Plezy nie można znaleźć.';
}

// Path: notifications
class _Translations$notifications$pl extends Translations$notifications$en {
	_Translations$notifications$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Nowy epizod';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appIcon
class _Translations$appIcon$pl extends Translations$appIcon$en {
	_Translations$appIcon$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ikona aplikacji';
	@override String get defaultIcon => 'Domyślna';
	@override String get current => 'Bieżąca ikona';
	@override String get locked => 'Wymagany dostęp do życia';
	@override String get lockedHint => 'Rozpocznij 7-dniowy próbny lub odblokuj PlezyNG na całe życie, aby użyć alternatywnych ikon.';
	@override String get changeFailed => 'Nie udało się zmienić ikony aplikacji';
	@override String get launcherHint => 'Nowa ikona pojawi się na ekranie głównym po opuszczeniu PlezyNG.';
	@override String get tvLauncherHint => 'Nowy baner pojawi się po opuszczeniu PlezyNG. Android TV może wyświetlać stary baner, dopóki telewizor nie zostanie uruchomiony ponownie.';
	@override late final _Translations$appIcon$names$pl names = _Translations$appIcon$names$pl._(_root);
}

// Path: auth
class _Translations$auth$pl extends Translations$auth$en {
	_Translations$auth$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Zaloguj się przez Plex';
	@override String get showQRCode => 'Pokaż kod QR';
	@override String get authenticate => 'Uwierzytelnij';
	@override String get authenticationTimeout => 'Upłynął czas uwierzytelniania. Spróbuj ponownie.';
	@override String get scanQRToSignIn => 'Zeskanuj ten kod QR, aby się zalogować';
	@override String get waitingForAuth => 'Oczekiwanie na uwierzytelnienie...\nZaloguj się w przeglądarce.';
	@override String get useBrowser => 'Użyj przeglądarki';
	@override String get or => 'lub';
	@override String connectToMediaBrowser({required Object product}) => 'Połącz z ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Użyj Quick Connect';
	@override String get quickConnectInstructions => 'Otwórz Quick Connect w Jellyfin i wpisz ten kod.';
	@override String get quickConnectWaiting => 'Oczekiwanie na zatwierdzenie…';
	@override String get quickConnectCancel => 'Anuluj';
	@override String get quickConnectExpired => 'Quick Connect wygasł. Spróbuj ponownie.';
	@override String get localDataRecoveryRequired => 'PlezyNG nie mogło bezpiecznie odzyskać lokalnych danych logowania ani oczekujących danych odtwarzania. Zaloguj się ponownie.';
	@override String get pinCheckRejected => 'Sprawdzenie kodu PIN Plex zostało odrzucone';
	@override String get connectToDirectPlex => 'Podłącz się do lokalnego serwera Plex';
}

// Path: common
class _Translations$common$pl extends Translations$common$en {
	_Translations$common$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Anuluj';
	@override String get save => 'Zapisz';
	@override String get close => 'Zamknij';
	@override String get clear => 'Wyczyść';
	@override String get reset => 'Resetuj';
	@override String get later => 'Później';
	@override String get submit => 'Wyślij';
	@override String get confirm => 'Potwierdź';
	@override String get retry => 'Ponów';
	@override String get logout => 'Wyloguj';
	@override String get unknown => 'Nieznane';
	@override String get refresh => 'Odśwież';
	@override String get yes => 'Tak';
	@override String get no => 'Nie';
	@override String get delete => 'Usuń';
	@override String get edit => 'Edytuj';
	@override String get shuffle => 'Losowo';
	@override String get addTo => 'Dodaj do...';
	@override String get createNew => 'Utwórz';
	@override String get connect => 'Połącz';
	@override String get disconnect => 'Rozłącz';
	@override String get play => 'Odtwórz';
	@override String get pause => 'Pauza';
	@override String get resume => 'Wznów';
	@override String get error => 'Błąd';
	@override String get search => 'Szukaj';
	@override String get home => 'Start';
	@override String get back => 'Wstecz';
	@override String get settings => 'Ustawienia';
	@override String get mute => 'Wycisz';
	@override String get ok => 'OK';
	@override String get off => 'Wył.';
	@override String get options => 'Opcje';
	@override String seasonNumber({required Object number}) => 'Sezon ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Odcinek ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Rozdział ${number}';
	@override String get reconnect => 'Połącz ponownie';
	@override String get viewAll => 'Pokaż wszystko';
	@override String get checkingNetwork => 'Sprawdzanie sieci...';
	@override String get loadingServers => 'Ładowanie serwerów...';
	@override String get connectingToServers => 'Łączenie z serwerami...';
	@override String get startingOfflineMode => 'Uruchamianie trybu offline...';
	@override String get loading => 'Ładowanie...';
	@override String get fullscreen => 'Pełny ekran';
	@override String get exitFullscreen => 'Wyjdź z pełnego ekranu';
	@override String get pressBackAgainToExit => 'Naciśnij ponownie przycisk Wstecz, aby wyjść';
	@override late final _Translations$common$ratingSource$pl ratingSource = _Translations$common$ratingSource$pl._(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$pl mediaKind = _Translations$common$mediaKind$pl._(_root);
}

// Path: screens
class _Translations$screens$pl extends Translations$screens$en {
	_Translations$screens$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licencje';
	@override String get switchProfile => 'Zmień profil';
	@override String get subtitleStyling => 'Styl napisów';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logi';
}

// Path: update
class _Translations$update$pl extends Translations$update$en {
	_Translations$update$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get available => 'Dostępna aktualizacja';
	@override String versionAvailable({required Object version}) => 'Dostępna wersja ${version}';
	@override String currentVersion({required Object version}) => 'Bieżąca: ${version}';
	@override String get skipVersion => 'Pomiń tę wersję';
	@override String get viewRelease => 'Zobacz wydanie';
	@override String get latestVersion => 'Masz najnowszą wersję';
	@override String get checkFailed => 'Nie udało się sprawdzić aktualizacji';
}

// Path: appAccess
class _Translations$appAccess$pl extends Translations$appAccess$en {
	_Translations$appAccess$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Spróbuj każdej funkcji za darmo przez 7 dni';
	@override String get description => 'Rozpocznij siedemdniową próbę z pełnym dostępem do każdej funkcji PlezyNG. nie ma opłaty w trakcie prób i nie ma subskrypcji. po próbie, jeden zakup na całe życie w cenie sklepu otwiera PlezyNG na całe życia.';
	@override String get trialEndedDescription => 'Odblokuj na zawsze wszystkie funkcje PlezyNG jednorazowym zakupem w cenie podanej w sklepie. Bez subskrypcji.';
	@override String get startTrial => 'Rozpocznij moje 7 dni wolnego wyprawy';
	@override String get trialActive => 'Twoja 7-dniowa próba pełnej funkcji jest aktywna.';
	@override String get trialEnded => '7 dni sądu zakończyły się';
	@override String get trialStartFailed => 'Nie mogłem zaoszczędzić próbki na tym urządzeniu. proszę spróbować ponownie.';
	@override String get lifetimeTitle => 'PlezyNG odblokowane na całe życie';
	@override String get lifetimeBody => 'Dzięki! masz dostęp do każdej funkcji PlezyNG przez całe życie.';
	@override String get manageTitle => 'PlezyNG Dostęp do życia';
	@override String get manageDescription => 'Spróbuj każdej funkcji za darmo przez 7 dni, a następnie odblokuj wszystko na całe życie z jednym płatnością w cenie sklepu.';
	@override String buy({required Object price}) => 'Odblokuj wszystkie funkcje dla ${price}';
	@override String get loadingPrice => 'Cena sklepu ładunkowego...';
	@override String get retryPrice => 'Ceny Retry Lookup';
	@override String get restore => 'Przywrócenie zakupów na całe życie';
	@override String get pending => 'Twój zakup czeka na płatność lub zatwierdzenie. dostęp do życia otwiera się, gdy tylko sklep go ukończy.';
	@override String get storeUnavailable => 'Sprawdź, czy jesteś podpisany do sklepu, a zakupy są dozwolone na tym urządzeniu.';
	@override String get productNotFound => 'W tym sklepie nie ma jeszcze odblokowania PlezyNG na całe życie.';
	@override String get productQueryFailed => 'Nie można pobierać ceny sklepu. sprawdź połączenie i spróbuj ponownie.';
	@override String get purchaseFailed => 'Zakup nie przeszedł, spróbuj ponownie.';
	@override String get restoreFailed => 'Nie mogłem dotrzeć do sklepu, aby odzyskać zakup. spróbuj ponownie.';
	@override String get nothingToRestore => 'Nr PlezyNG zakup na całe życie znaleziono na tym koncie sklepu.';
}

// Path: settings
class _Translations$settings$pl extends Translations$settings$en {
	_Translations$settings$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ustawienia';
	@override String get supportDeveloper => 'Wesprzyj PlezyNG';
	@override String get supportDeveloperDescription => 'Wspomóż rozwój darowizną';
	@override String get lifetimeAccess => 'PlezyNG Dostęp do życia';
	@override String get language => 'Język';
	@override String get theme => 'Motyw';
	@override String get appearance => 'Wygląd';
	@override String get detailPage => 'Szczegóły strony';
	@override String get themeSongsEnabled => 'Zagraj w tematyki piosenki';
	@override String get themeSongsEnabledDescription => 'Zagraj w dostępne piosenki tematyczne podczas oglądania szczegółów mediów.';
	@override String get themeSongVolume => 'Temat piosenki Volume';
	@override String get videoPlayback => 'Odtwarzanie wideo';
	@override String get videoPlaybackDescription => 'Skonfiguruj zachowanie odtwarzania';
	@override String get advanced => 'Zaawansowane';
	@override String get episodePosterMode => 'Styl plakatu odcinka';
	@override String get seriesPoster => 'Plakat serialu';
	@override String get seasonPoster => 'Plakat sezonu';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Wyświetl karuzelę wyróżnionych treści na ekranie głównym';
	@override String get secondsLabel => 'Sekundy';
	@override String get minutesLabel => 'Minuty';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'min';
	@override String durationHint({required Object min, required Object max}) => 'Wprowadź czas (${min}-${max})';
	@override String get systemTheme => 'Systemowy';
	@override String get lightTheme => 'Jasny';
	@override String get darkTheme => 'Ciemny';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Żar';
	@override String get glacierTheme => 'Lodowiec';
	@override String get forestTheme => 'Las';
	@override String get plumTheme => 'Śliwka';
	@override String get paperTheme => 'Papier';
	@override String get libraryDensity => 'Gęstość biblioteki';
	@override String get displayScale => 'Skalowanie';
	@override String get compact => 'Kompaktowy';
	@override String get comfortable => 'Wygodny';
	@override String get gridSpacing => 'Odstępy siatki';
	@override String get gridSpacingTight => 'Ciasny';
	@override String get gridSpacingNormal => 'Normalny';
	@override String get gridSpacingSpacious => 'Przestronny';
	@override String get tvCornerSpotlightBackdrop => 'Tło wyróżnionej pozycji w rogu';
	@override String get tvCornerSpotlightBackdropDescription => 'Wyświetlaj grafikę wyróżnionej pozycji w prawym górnym rogu zamiast na całym ekranie';
	@override String get viewMode => 'Tryb widoku';
	@override String get gridView => 'Siatka';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Pokaż sekcję wyróżnioną';
	@override String get showHomeBackdrop => 'Home Artykuły Artykuł Artykuła';
	@override String get showHomeBackdropDescription => 'Wyświetl duże dzieła artystyczne za zawieszonymi rzęsami domowymi';
	@override String get contentScreensaverEnabled => 'Zawartość ekranu';
	@override String get contentScreensaverEnabledDescription => 'Wyświetl pełnoprawną sztukę po tym, jak aplikacja była idle';
	@override String get contentScreensaverDelay => 'Start ekranu po';
	@override String get contentScreensaverLibraries => 'Biblioteki Screensaver';
	@override String get contentScreensaverLibrariesDescription => 'Wybierz biblioteki, z których mają pochodzić grafiki wygaszacza ekranu. Jeśli nie wybierzesz żadnej, używane będą grafiki ze wszystkich bibliotek.';
	@override String get contentScreensaverAllLibraries => 'Wszystkie biblioteki';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} wybrane biblioteki';
	@override String get contentScreensaverNoLibraries => 'Nie ma dostępnych biblioteek medialnych.';
	@override String get contentScreensaverDismissHint => 'Naciśnij dowolny przycisk lub naciśnij, aby odwołać';
	@override String get newEpisodeNotifications => 'Nowe powiadomienia epizodowe';
	@override String get newEpisodeNotificationsDescription => 'Ostrzeżenie, gdy do pokazu jest dodany nowy odcinek, który jest uwięziony. sprawdź, kiedy jest otwarty Plezy.';
	@override String get continueWatchingRowSize => 'Spójrz dalej na rozmiar kolejki';
	@override String continueWatchingRowSizeValue({required Object label}) => 'Karty: ${label}';
	@override String get rowSizeCompact => 'Kompaktowy';
	@override String get rowSizeStandard => 'Standardowe';
	@override String get rowSizeLarge => 'Duży';
	@override String get continueWatchingAction => 'Działanie w sekcji „Kontynuuj oglądanie”';
	@override String get continueWatchingPlay => 'Odtwórz';
	@override String get continueWatchingDetails => 'Otwórz szczegóły';
	@override String get episodeAction => 'Akcja odcinka';
	@override String get episodePlay => 'Odtwórz';
	@override String get episodeDetails => 'Otwórz szczegóły';
	@override String get useGlobalHubs => 'Użyj układu strony głównej';
	@override String get useGlobalHubsDescription => 'Wyświetlaj ujednolicone sekcje ekranu głównego. W przeciwnym razie używaj rekomendacji bibliotek.';
	@override String get showServerNameOnHubs => 'Pokaż nazwę serwera w sekcjach';
	@override String get showServerNameOnHubsDescription => 'Zawsze pokazuj nazwy serwerów w tytułach sekcji.';
	@override String get groupLibrariesByServer => 'Grupuj biblioteki według serwera';
	@override String get groupLibrariesByServerDescription => 'Grupuj biblioteki paska bocznego pod każdym serwerem multimediów.';
	@override String get alwaysKeepSidebarOpen => 'Zawsze utrzymuj panel boczny otwarty';
	@override String get alwaysKeepSidebarOpenDescription => 'Panel boczny jest rozwinięty, a obszar treści dostosowuje się';
	@override String get showUnwatchedCount => 'Pokaż liczbę nieobejrzanych';
	@override String get showUnwatchedCountDescription => 'Wyświetl liczbę nieobejrzanych odcinków w serialach i sezonach';
	@override String get showWatchedIndicators => 'Pokaż wskaźniki obejrzenia';
	@override String get showWatchedIndicatorsDescription => 'Wyświetlaj znacznik na obejrzanych filmach, serialach i odcinkach';
	@override String get showEpisodeNumberOnCards => 'Pokaż numer odcinka na kartach';
	@override String get showEpisodeNumberOnCardsDescription => 'Pokazuj numer sezonu i odcinka na kartach odcinków';
	@override String get showSeasonPostersOnTabs => 'Pokaż plakaty sezonów na zakładkach';
	@override String get showSeasonPostersOnTabsDescription => 'Pokazuj plakat każdego sezonu nad jego zakładką';
	@override String get tvFullCardLayout => 'Pełne karty TV';
	@override String get tvFullCardLayoutDescription => 'Używaj kart TV tylko z obrazem i nałożonymi nazwiskami aktorów';
	@override String get focusGlow => 'Poświata zaznaczenia';
	@override String get focusGlowDescription => 'Wyświetlaj delikatną poświatę wokół zaznaczonej karty';
	@override String get visualEffects => 'Efekty wizualne';
	@override String get visualEffectsAuto => 'Automatycznie';
	@override String get visualEffectsAutoDescription => 'Automatycznie ograniczaj efekty na urządzeniach o niższej wydajności';
	@override String get visualEffectsFull => 'Pełne';
	@override String get visualEffectsReduced => 'Ograniczone';
	@override String get visualEffectsReducedDescription => 'Mniej animacji i grafiki o niższej rozdzielczości';
	@override String get hideSpoilers => 'Ukryj spoilery nieobejrzanych odcinków';
	@override String get hideSpoilersDescription => 'Rozmywaj miniatury i opisy nieobejrzanych odcinków';
	@override String get playerBackend => 'Mechanizm odtwarzania';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Dekodowanie sprzętowe';
	@override String get hardwareDecodingDescription => 'Użyj akceleracji sprzętowej, gdy dostępna';
	@override String get playbackBuffer => 'Bufor odtwarzania';
	@override String get playbackBufferAuto => 'Auto (zalecane)';
	@override String get playbackBufferLarge => 'Duży';
	@override String get playbackBufferExtraLarge => 'Bardzo duży';
	@override String get playbackBufferDescription => 'Buforuje więcej w przypadku niestabilnych połączeń. Ograniczony również przez rozmiar bufora.';
	@override String get streamBufferSize => 'rozmiar buffer';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Ile wideo należy przesyłać do przodu podczas odtwarzania bezpośredniego. transkody zatrzymują się na własnym buferze transkodu serwera. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Zastąpić Playback Buffer przy ustawieniu, przechowywany w połowie limitu pamięci aplikacji';
	@override String get streamBufferMegabytes => 'Megabytes';
	@override String get defaultQualityTitle => 'Domyślna jakość';
	@override String get cellularQualityTitle => 'Domyślna jakość w sieci komórkowej';
	@override String get remoteQualityTitle => 'Jakość transmisji zdalnej';
	@override String get remoteQualitySameAsDefault => 'Jakość standardów';
	@override String get cellularQualitySameAsDefault => 'Taka sama jak domyślna jakość';
	@override String get directPlayCoveredQuality => 'Odtwarzaj mniejsze wideo w oryginalnej jakości';
	@override String get directPlayCoveredQualityDescription => 'Odtwarzaj bezpośrednio wideo mieszczące się już w limicie jakości zamiast je transkodować';
	@override String get videoCodecs => 'Kodeki wideo';
	@override String get videoCodecsDescription => 'Niezaznaczone kodeki są transkodowane przez serwer';
	@override String get videoCodecsAlwaysAccepted => 'Zawsze akceptowany';
	@override String get musicQualityTitle => 'Jakość muzyki';
	@override String get subtitleStyling => 'Styl napisów';
	@override String get subtitleStylingDescription => 'Dostosuj wygląd napisów';
	@override String get smallSkipDuration => 'Krótki skok';
	@override String get largeSkipDuration => 'Długi skok';
	@override String get rewindOnResume => 'Przewiń przy wznowieniu';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekunda',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekund',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy',
	);
	@override String get defaultSleepTimer => 'Domyślny wyłącznik czasowy';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuta',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minut',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty',
	);
	@override String get rememberTrackSelections => 'Zapamiętuj wybór ścieżek dla każdego serialu i filmu';
	@override String get chooseTracksBeforePlayback => 'Wybierz audio i podtytuły przed odtwarzaniem';
	@override String get chooseTracksBeforePlaybackDescription => 'Wybierz źródło audio i podtytuły śladów przed każdym filmem rozpoczyna się.';
	@override String get alwaysShowSubtitlesOnDevice => 'Zawsze wyświetlać podtytuły na tym urządzeniu';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Jeśli serwer nie ma podtytułu wybranego, wybierz ścieżkę lokalnie.';
	@override String get autoDownloadPreferredSubtitle => 'FETCH brakuje preferowanych podtytułów językowych';
	@override String get autoDownloadPreferredSubtitleDescription => 'Wybierz dostępny podtytuł w preferowanym języku lokalnie.Jeśli nie istnieje, poproś serwer o to, aby go pobrał, gdy jest obsługiwany.';
	@override String get rememberTrackSelectionsDescription => 'Zapamiętuj wybór ścieżki dźwiękowej i napisów dla każdego tytułu';
	@override String get rememberTrackSelectionsBackendRule => 'Plex zapisuje każdy wybór na serwerze dla danego pliku; Jellyfin dodatkowo włącza opcję „Zapamiętaj wybory” na koncie; Emby nie jest obsługiwany';
	@override String get followServerTrackSelections => 'Używaj wyboru ścieżek z serwera dla każdego odcinka';
	@override String get followServerTrackSelectionsDescription => 'Przy zmianie odcinka stosuj ścieżkę dźwiękową i napisy wybrane na serwerze zamiast przenosić bieżący wybór';
	@override String get resumeMusicOnLaunch => 'Zapamiętaj sesję muzyczną';
	@override String get resumeMusicOnLaunchDescription => 'Przy uruchomieniu aplikacji otwieraj ostatni utwór wstrzymany w miejscu, w którym przerwano';
	@override String get showChapterMarkersOnTimeline => 'Pokaż znaczniki rozdziałów na pasku przewijania';
	@override String get showChapterMarkersOnTimelineDescription => 'Podziel pasek przewijania na granicach rozdziałów';
	@override String get specialsOrdering => 'Specjale w kolejności odcinków';
	@override String get specialsOrderingDescription => 'Miejsce odcinków specjalnych w kolejności oglądania serialu';
	@override String get specialsOrderingServer => 'Zgodnie z kolejnością serwera';
	@override String get specialsOrderingAirDate => 'Przeplataj według daty emisji';
	@override String get specialsOrderingLast => 'Po regularnych sezonach';
	@override String get clickVideoTogglesPlayback => 'Kliknięcie wideo przełącza odtwarzanie/pauzę';
	@override String get clickVideoTogglesPlaybackDescription => 'Kliknięcie wideo odtwarza/wstrzymuje zamiast pokazywać sterowanie.';
	@override String get videoPlayerControls => 'Kontrolki odtwarzacza wideo';
	@override String get keyboardShortcuts => 'Skróty klawiszowe';
	@override String get keyboardShortcutsDescription => 'Dostosuj skróty klawiszowe';
	@override String get videoPlayerNavigation => 'Nawigacja odtwarzacza wideo';
	@override String get videoPlayerNavigationDescription => 'Użyj klawiszy strzałek do nawigacji kontrolkami odtwarzacza';
	@override String get watchTogetherRelay => 'Serwer pośredniczący funkcji „Oglądaj razem”';
	@override String get watchTogetherRelayDescription => 'Publiczne serwery pośredniczące Open Watch Party, chyba że ustawisz własny';
	@override String get watchTogetherRelayHint => 'https://moj-relay.przyklad.pl';
	@override String get watchTogetherRelayInvalid => 'Wprowadź prawidłowy bazowy adres URL serwera pośredniczącego HTTP lub HTTPS.';
	@override String get crashReporting => 'Raportowanie błędów';
	@override String get crashReportingDescription => 'Wysyłaj raporty o błędach, aby pomóc ulepszyć aplikację';
	@override String get debugLogging => 'Rejestrowanie diagnostyczne';
	@override String get debugLoggingDescription => 'Włącz szczegółowe rejestrowanie, aby ułatwić rozwiązywanie problemów';
	@override String get viewLogs => 'Pokaż logi';
	@override String get viewLogsDescription => 'Pokaż logi aplikacji';
	@override String get clearImageCache => 'Wyczyść pamięć podręczną obrazów';
	@override String get clearImageCacheDescription => 'Wyczyść zapisane okładki i miniatury. Obrazy mogą ładować się wolniej, dopóki nie zostaną pobrane ponownie.';
	@override String get clearImageCacheSuccess => 'Pamięć podręczna obrazów została wyczyszczona';
	@override String get resetSettings => 'Zresetuj ustawienia';
	@override String get resetSettingsDescription => 'Przywróć ustawienia domyślne. Tego nie można cofnąć.';
	@override String get resetSettingsSuccess => 'Przywrócono ustawienia domyślne';
	@override String get backup => 'Kopia zapasowa';
	@override String get exportSettings => 'Eksportuj ustawienia';
	@override String get exportSettingsDescription => 'Zapisz swoje preferencje do pliku';
	@override String get exportSettingsSuccess => 'Ustawienia wyeksportowane';
	@override String get importSettings => 'Importuj ustawienia';
	@override String get importSettingsDescription => 'Przywróć preferencje z pliku';
	@override String get importSettingsConfirm => 'Bieżące ustawienia zostaną zastąpione. Kontynuować?';
	@override String get importSettingsSuccess => 'Ustawienia zaimportowane';
	@override String get importSettingsInvalidFile => 'Ten plik nie jest prawidłowym eksportem PlezyNG';
	@override String get importSettingsNoUser => 'Zaloguj się przed importem ustawień';
	@override String get cloudBackup => 'Kopia zapasowa w chmurze';
	@override String get cloudBackupDescription => 'Backup ustawień przenośnych do punktu końcowego WebDAV powyżej HTTPS. połączenia serwera i uwierzytelnienia pozostają na tym urządzeniu.';
	@override String get cloudBackupUrl => 'WebDAV JSON plik URL';
	@override String get cloudBackupUsername => 'Nazwa użytkownika';
	@override String get cloudBackupPassword => 'Hasło';
	@override String get cloudBackupSaved => 'Cloud Backup Destination Zbawiony';
	@override String get cloudBackupNow => 'Wróć do Now';
	@override String get cloudBackupComplete => 'Ustawienia Backup uploaded';
	@override String get cloudBackupRestore => 'Odzyskiwanie backup';
	@override String get cloudBackupRestoreConfirm => 'To zastąpi dopasowane ustawienia przenośne na tym urządzeniu.';
	@override String get cloudBackupRestored => 'Ustawienia przywróciły się z kopii zapasowej w chmurze';
	@override String get shortcutsReset => 'Skróty przywrócone do domyślnych';
	@override String get resetShortcutsConfirm => 'Twoje własne skróty zostaną zastąpione domyślnymi. Kontynuować?';
	@override String get about => 'O aplikacji';
	@override String get aboutDescription => 'Informacje o aplikacji i licencje';
	@override String get updates => 'Aktualizacje';
	@override String get updateAvailable => 'Dostępna aktualizacja';
	@override String get checkForUpdates => 'Sprawdź aktualizacje';
	@override String get autoCheckUpdatesOnStartup => 'Automatycznie sprawdzaj aktualizacje przy uruchomieniu';
	@override String get autoCheckUpdatesOnStartupDescription => 'Powiadamiaj o dostępnej aktualizacji przy uruchomieniu';
	@override String get validationErrorEnterNumber => 'Wprowadź prawidłową liczbę';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Czas musi być między ${min} a ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Skrót jest już przypisany do ${action}';
	@override String shortcutUpdated({required Object action}) => 'Skrót zaktualizowany dla ${action}';
	@override String get saveFailed => 'Nie udało się zapisać zmian. Spróbuj ponownie.';
	@override String get autoPlayAndSkip => 'Auto-odtwarzanie i pomijanie';
	@override String get autoPlayNextEpisode => 'Automatycznie odtwarzaj następny odcinek';
	@override String get autoPlayNextEpisodeDescription => 'Automatycznie uruchamiaj następny odcinek, gdy bieżący się skończy';
	@override String get shuffleStartsFromBeginning => 'Odtwarzanie losowe od początku';
	@override String get shuffleStartsFromBeginningDescription => 'Rozpoczynaj każdy odcinek od początku przy odtwarzaniu losowym zamiast wznawiać';
	@override String get plexCinemaPreRoll => 'Serwer filmowy Intros';
	@override String get plexCinemaPreRollDescription => 'Zagraj konfigurowane Plex pre-rolls lub Jellyfin i Emby intros przed rozpoczęciem filmu.';
	@override String get playNextCountdown => 'Odliczanie do następnego odcinka';
	@override String get playNextCountdownImmediate => 'Odtwarzaj natychmiast';
	@override String get skipIntroMode => 'Pomijanie czołówki';
	@override String get skipIntroModeOffDescription => 'Odtwarzaj czołówki normalnie, bez przycisku pomijania';
	@override String get skipIntroModeButtonDescription => 'Pokazuj przycisk pomijania, gdy zaczyna się czołówka';
	@override String get skipIntroModeAutoDescription => 'Pomijaj czołówki automatycznie po opóźnieniu poniżej';
	@override String get skipCreditsMode => 'Pomijanie napisów końcowych';
	@override String get skipCreditsModeOffDescription => 'Odtwarzaj napisy końcowe normalnie, bez przycisku pomijania';
	@override String get skipCreditsModeButtonDescription => 'Pokazuj przycisk pomijania, gdy zaczynają się napisy końcowe';
	@override String get skipCreditsModeAutoDescription => 'Pomijaj napisy końcowe automatycznie i odtwarzaj następny odcinek';
	@override String get skipAdsMode => 'Skok reklam';
	@override String get skipAdsModeOffDescription => 'Odtwarzanie wykrytej reklamy zwykle bez przycisku przesuwania';
	@override String get skipAdsModeButtonDescription => 'Pokaż przycisk przełączania, gdy Plex wykrywa reklamę';
	@override String get skipAdsModeAutoDescription => 'Automatycznie przesuwaj wykryte reklamy po opóźnieniu poniżej';
	@override String get musicPlayback => 'Muzyka Playback';
	@override String get musicSweetFades => 'Słodkie Fades';
	@override String get musicSweetFadesDescription => 'Muzyka w ścieżkach ścieżek, gdy Plex ma dane głośności.';
	@override String get skipMarkerModeOff => 'Wył.';
	@override String get skipMarkerModeButton => 'Pokaż przycisk';
	@override String get skipMarkerModeAuto => 'Automatycznie';
	@override String get forceSkipMarkerFallback => 'Wymuś znaczniki awaryjne';
	@override String get forceSkipMarkerFallbackDescription => 'Używaj wzorców tytułów rozdziałów, nawet gdy Plex ma znaczniki';
	@override String get theIntroDbFallback => 'Użyj TheIntroDB jako intro fallback';
	@override String get theIntroDbFallbackDescription => 'Użyj harmonogramów społeczności tylko wtedy, gdy serwer nie ma znaku wprowadzenia.';
	@override String get autoSkipDelay => 'Opóźnienie automatycznego pomijania';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Czekaj ${seconds} sekund przed automatycznym pominięciem';
	@override String get introPattern => 'Wzorzec znacznika intro';
	@override String get introPatternDescription => 'Wyrażenie regularne do rozpoznawania znaczników intro w tytułach rozdziałów';
	@override String get creditsPattern => 'Wzorzec znacznika napisów końcowych';
	@override String get creditsPatternDescription => 'Wyrażenie regularne do rozpoznawania znaczników napisów końcowych w tytułach rozdziałów';
	@override String get prerolls => 'Filmy wstępne';
	@override String get playPrerollsBeforeMovies => 'Graj w preroły przed filmami';
	@override String get playPrerollsBeforeMoviesDescription => 'Odtwarzaj przypadkowy klip z poniższego wyboru przed każdym filmem.';
	@override String get prerollLibrary => 'Biblioteka Preroll';
	@override String get prerollLibraryNotSet => 'Nie ustawiono';
	@override String get prerollLibraryNoneFound => 'Na serwerach nie znaleziono żadnych bibliotek.';
	@override String get prerollSelection => 'wybrane preroli';
	@override String get prerollSelectionPickLibraryFirst => 'Najpierw wybierz bibliotekę';
	@override String get prerollSelectionNoneSelected => 'Nie wybierane prezydencje';
	@override String prerollSelectionCount({required Object count}) => 'Wybrano: ${count}';
	@override String get prerollItemPicker => 'Wybierz preroli';
	@override String get prerollItemPickerLoadFailed => 'Nie mogłam załadować przedmiotów z tej biblioteki.';
	@override String get invalidRegex => 'Nieprawidłowe wyrażenie regularne';
	@override String get regex => 'Wyrażenie regularne';
	@override String get downloads => 'Pobrania';
	@override String get downloadLocationDescription => 'Wybierz miejsce przechowywania pobranych treści';
	@override String get downloadLocationDefault => 'Domyślne (pamięć aplikacji)';
	@override String get downloadLocationCustom => 'Niestandardowa lokalizacja';
	@override String get selectFolder => 'Wybierz folder';
	@override String get resetToDefault => 'Przywróć domyślne';
	@override String currentPath({required Object path}) => 'Bieżąca: ${path}';
	@override String get downloadLocationChanged => 'Lokalizacja pobierania zmieniona';
	@override String get downloadLocationReset => 'Lokalizacja pobierania przywrócona do domyślnej';
	@override String get downloadLocationInvalid => 'Nie można zapisywać w wybranym folderze';
	@override String get downloadLocationPickerUnavailable => 'Wybór folderu nie jest dostępny na tym urządzeniu';
	@override String get downloadOnWifiOnly => 'Pobieraj tylko przez Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Blokuj pobieranie na danych komórkowych';
	@override String get autoRemoveWatchedDownloads => 'Automatycznie usuwaj obejrzane pobrania';
	@override String get autoRemoveWatchedDownloadsDescription => 'Automatycznie usuwaj obejrzane pobrania';
	@override String get autoDownloadContinueWatching => 'Auto-Download Kontynuuj oglądanie';
	@override String get autoDownloadContinueWatchingDescription => 'Utrzymuj elementy na swojej przeglądarce i pobierz je, gdy opuszczą przeglądarkę';
	@override String get downloadQuality => 'Pobierz jakość';
	@override String get downloadQualityDescription => 'Plex przygotowuje przekształconą kopię w swojej skrzynce pobierania. Jellyfin i Emby transkody podczas pobierania pliku; przerwane przesyłki mogą być konieczne do ponownego uruchomienia.';
	@override String get askDownloadQualityEachTime => 'Wybierz jakość dla każdego pobrania';
	@override String get askDownloadQualityEachTimeDescription => 'Pokaż jakość picera przed przeglądaniem każdego pobrania wideo';
	@override String get cellularDownloadBlocked => 'Pobieranie przez sieć komórkową jest zablokowane. Użyj Wi-Fi lub zmień ustawienie.';
	@override String get maxVolume => 'Maksymalna głośność';
	@override String get maxVolumeDescription => 'Pozwól na wzmocnienie głośności powyżej 100% dla cichych multimediów';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Pokaż, co oglądasz na Discordzie';
	@override String get services => 'Usługi';
	@override String get servicesDescription => 'Połącz Trakt, MyAnimeList, Seerr i inne';
	@override String get manageLibrariesDescription => 'Zmieniaj kolejność i ukrywaj biblioteki';
	@override String get companionRemoteServer => 'Serwer zdalnego sterowania';
	@override String get companionRemoteServerDescription => 'Pozwól urządzeniom mobilnym w sieci sterować tą aplikacją';
	@override String get companionRemoteServerStartFailed => 'Nie udało się uruchomić serwera zdalnego sterowania';
	@override String get companionRemoteServerStopFailed => 'Nie udało się zatrzymać serwera zdalnego sterowania';
	@override String get autoPip => 'Automatyczny obraz w obrazie';
	@override String get autoPipDescription => 'Automatycznie włączaj tryb obrazu w obrazie po opuszczeniu aplikacji podczas odtwarzania';
	@override String get matchContentFrameRate => 'Dopasuj częstotliwość klatek do treści';
	@override String get matchContentFrameRateDescription => 'Dopasuj częstotliwość odświeżania ekranu do wideo';
	@override String get matchContentResolution => 'Dopasuj do rozdzielczości materiału';
	@override String get matchContentResolutionDescription => 'Przełącza ekran na natywną rozdzielczość wideo, aby skalowaniem zajął się telewizor. Menu i napisy są podczas odtwarzania również skalowane';
	@override String get matchRefreshRate => 'Dopasuj częstotliwość odświeżania';
	@override String get matchRefreshRateDescription => 'Dopasuj częstotliwość odświeżania w trybie pełnoekranowym';
	@override String get matchDynamicRange => 'Dopasuj zakres dynamiki';
	@override String get matchDynamicRangeDescription => 'Włącz HDR dla treści HDR, potem wróć do SDR';
	@override String get displaySwitchDelay => 'Opóźnienie przełączania ekranu';
	@override String get tunneledPlayback => 'Tunelowane odtwarzanie';
	@override String get tunneledPlaybackDescription => 'Użyj tunelowania wideo. Wyłącz, jeśli HDR pokazuje czarny obraz lub ruch się zacina.';
	@override String get audioPassthrough => 'Przekazywanie dźwięku';
	@override String get audioPassthroughDescription => 'Przesyłaj dźwięk Dolby/DTS do amplitunera lub telewizora bez ponownego kodowania, zachowując dźwięk przestrzenny. Wyłącz tę opcję, jeśli nie słychać dźwięku.';
	@override String get audioPassthroughDescriptionApple => 'Używaj natywnego dekodera Dolby firmy Apple dla Dolby Digital Plus, w tym Atmos. DTS i TrueHD nadal będą odtwarzane jako wielokanałowy dźwięk PCM. Wyłącz tę opcję, jeśli nie słychać dźwięku.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Używaj natywnego dekodera Dolby firmy Apple dla Dolby Digital Plus, w tym Atmos. W systemach iOS, iPadOS i tvOS 26 lub nowszych TrueHD Atmos i DTS:X są odtwarzane jako dźwięk przestrzenny. Pozostałe ścieżki DTS i TrueHD są odtwarzane jako wielokanałowy dźwięk PCM. Wyłącz tę opcję, jeśli nie słychać dźwięku.';
	@override String get audioPassthroughOverriddenByNormalization => 'Wyłączone, gdy włączona jest normalizacja głośności';
	@override String get audioChannelLimit => 'Kanały audio';
	@override String get audioChannelLimitDescription => 'Miksuje zdekodowany dźwięk do mniejszej liczby kanałów dla głośników, słuchawek lub zestawów HDMI, które nie obsługują wszystkich kanałów';
	@override String get audioChannelLimitOriginal => 'Oryginalne';
	@override String get audioChannelLimitOriginalDescription => 'Odtwarza wszystkie kanały ścieżki';
	@override String get audioChannelLimitSurround51 => 'Do 5.1';
	@override String get audioChannelLimitSurround51Description => 'Miksuje 7.1 do 5.1 dla telewizorów i amplitunerów, które przyjmują tylko 5.1 PCM. Nie wpływa na przekazywanie dźwięku.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Miksuje do dwóch kanałów dla głośników stereo lub słuchawek. Wyłącza przekazywanie dźwięku.';
	@override String get downmixCenterBoost => 'Wzmocnienie kanału centralnego';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Wzmocnienie (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizacja głośności przy miksowaniu';
	@override String get audioDownmixNormalizeDescription => 'Obniża miks, aby zapobiec przesterowaniu. Wyłącz, aby zachować oryginalną głośność (głośne sceny mogą być zniekształcone).';
	@override String get dvConversionMode => 'Konwersja Dolby Vision';
	@override String get dvConversionModeDescription => 'Wybierz, jak mają być obsługiwane pliki Dolby Vision Profile 7.';
	@override String get dvConversionAuto => 'Automatycznie';
	@override String get dvConversionNative => 'Natywnie / wyłączone';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Wykrywaj możliwości urządzenia i stosuj standardowy mechanizm awaryjny';
	@override String get dvConversionNativeDescription => 'Wymuś natywne DV7 i wyłącz ponowną próbę konwersji DV';
	@override String get dvConversionDv81Description => 'Wymuś wbudowaną konwersję RPU do profilu Dolby Vision 8.1';
	@override String get dvConversionHevcStripDescription => 'Usuń warstwy Dolby Vision RPU/EL i przedstaw zwykłe HEVC';
	@override String get disableDolbyVision => 'Wyłącz Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Odtwarzaj warstwę HDR10 lub HLG pliku zamiast Dolby Vision, jeśli jest dostępna';
	@override String get hdrSdrConversion => 'Konwersja HDR do SDR';
	@override String get hdrSdrConversionDescription => 'Wybierz, co konwertuje wideo HDR, gdy wyświetlacz nie obsługuje HDR.';
	@override String get hdrSdrConversionAuto => 'Automatycznie';
	@override String get hdrSdrConversionAutoDescription => 'Urządzenie na Androidzie 9 i nowszym, odtwarzacz na starszych wersjach';
	@override String get hdrSdrConversionDevice => 'Urządzenie';
	@override String get hdrSdrConversionDeviceDescription => 'Konwersję wykonuje sprzęt wideo urządzenia. Najszybciej, ale kolory zależą od urządzenia';
	@override String get hdrSdrConversionPlayer => 'Odtwarzacz';
	@override String get hdrSdrConversionPlayerDescription => 'Konwersję wykonuje odtwarzacz. Spójne kolory, ale 4K może się zacinać na słabszych przystawkach TV';
	@override String get deinterlace => 'Usuwanie przeplotu';
	@override String get deinterlaceDescription => 'Usuwa artefakty grzebienia z wideo z przeplotem (tylko odtwarzacz mpv)';
	@override String get deinterlaceOff => 'Wył.';
	@override String get deinterlaceOffDescription => 'Wyświetla wideo z przeplotem w postaci, w jakiej zostało zdekodowane';
	@override String get deinterlaceVideo => 'Wideo';
	@override String get deinterlaceVideoDescription => 'Zamienia każdy półobraz w pełną klatkę. Do materiałów nagrywanych dla telewizji, np. sportu, wiadomości i koncertów';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => 'Przywraca oryginalne klatki filmów i animacji poddanych konwersji telecine do 29,97 kl./s, częstej na płytach DVD w standardzie NTSC. Materiały nagrywane dla telewizji będą się zacinać. TV na żywo używa trybu Wideo';
	@override String get requireProfileSelectionOnOpen => 'Pytaj o profil przy otwarciu aplikacji';
	@override String get requireProfileSelectionOnOpenDescription => 'Pokaż wybór profilu za każdym razem, gdy aplikacja jest otwierana';
	@override String get forceTvMode => 'Wymuś tryb TV';
	@override String get forceTvModeDescription => 'Wymuś układ telewizyjny na urządzeniach, które nie wykrywają go automatycznie. Wymaga ponownego uruchomienia.';
	@override String get startInFullscreen => 'Uruchom na pełnym ekranie';
	@override String get startInFullscreenDescription => 'Otwiera PlezyNG w trybie pełnoekranowym przy uruchomieniu';
	@override String get exitFullscreenOnPlayerClose => 'Wyjdź z pełnego ekranu przy zamykaniu odtwarzacza';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Automatycznie wychodzi z trybu pełnoekranowego po zamknięciu odtwarzacza wideo';
	@override String get autoHidePerformanceOverlay => 'Automatycznie ukrywaj nakładkę wydajności';
	@override String get autoHidePerformanceOverlayDescription => 'Wygaszaj nakładkę wydajności wraz z kontrolkami odtwarzania';
	@override String get showNavBarLabels => 'Pokaż etykiety paska nawigacji';
	@override String get showNavBarLabelsDescription => 'Wyświetl tekstowe etykiety pod ikonami paska nawigacji';
	@override String get startupSection => 'Sekcja startowa';
	@override String get preferredServer => 'Preferowany serwer';
	@override String get preferredServerDescription => 'Priorytetuj wyniki tego serwera, jednocześnie utrzymując każdy podłączony serwer dostępny.';
	@override String get preferredServerAutomatic => 'Automatycznie';
	@override String get showExploreTab => 'Pokaż kartę Odkryj';
	@override String get showExploreTabDescription => 'Wyświetlaj kartę Odkryj z treściami z Plex Discover i połączonych serwisów śledzących';
	@override String get hideEmptyLibraries => 'Ukryj pustą bibliotekę';
	@override String get hideEmptyLibrariesDescription => 'Usuń biblioteki z liczeniem elementów zgłaszanych przez serwer z nuli z nawigacji.';
	@override String get liveTvDefaultFavorites => 'Domyślnie ulubione kanały';
	@override String get liveTvDefaultFavoritesDescription => 'Pokaż tylko ulubione kanały po otwarciu telewizji na żywo';
	@override String get general => 'Ogólne';
	@override String get generalDescription => 'Język, uruchamianie i zachowanie okna';
	@override String get languageAndRegion => 'Język i region';
	@override String get startup => 'Uruchamianie';
	@override String get display => 'Ekran';
	@override String get libraryAndCards => 'Biblioteka i karty';
	@override String get homeScreen => 'Ekran główny';
	@override String get navigation => 'Nawigacja';
	@override String get window => 'Okno';
	@override String get liveTv => 'TV na żywo';
	@override String get player => 'Odtwarzacz';
	@override String get videoAndDisplay => 'Wideo i ekran';
	@override String get audio => 'Audio';
	@override String get quality => 'Jakość';
	@override String get subtitles => 'Napisy';
	@override String get seekAndTiming => 'Przewijanie i czas';
	@override String get behavior => 'Zachowanie';
	@override String get gestures => 'Gesty';
	@override String get gestureBrightnessSwipe => 'Zmiana jasności przesunięciem';
	@override String get gestureBrightnessSwipeDescription => 'Przesuwaj palcem w górę lub w dół na lewej krawędzi, aby regulować jasność';
	@override String get gestureVolumeSwipe => 'Zmiana głośności przesunięciem';
	@override String get gestureVolumeSwipeDescription => 'Przesuwaj palcem w górę lub w dół na prawej krawędzi, aby regulować głośność';
	@override String get gesturePinchToZoom => 'Powiększanie ściskaniem';
	@override String get gesturePinchToZoomDescription => 'Ściśnij wideo palcami, aby powiększyć lub pomniejszyć';
	@override String get gestureSeekSwipe => 'Szukaj swipe';
	@override String get gestureSeekSwipeDescription => 'Przełącz lewą lub prawą stronę wideo, aby wyszukać; uwalniaj do skoku';
	@override String get rememberBrightnessLevel => 'Zapamiętaj poziom jasności';
	@override String get rememberBrightnessLevelDescription => 'Rozpoczynaj odtwarzanie z jasnością ustawioną ostatnim przesunięciem';
	@override String get controls => 'Sterowanie';
	@override String get rememberPlayerChanges => 'Zapamiętuj zmiany odtwarzacza';
	@override String get rememberPlayerChangesDescription => 'Miejsce zapisywania i ponownego stosowania zmian dokonanych podczas odtwarzania';
	@override String get scopePlaybackSpeed => 'Prędkość odtwarzania';
	@override String get scopeShaderPreset => 'Ustawienie shadera';
	@override String get scopeAspectRatio => 'Proporcje obrazu';
	@override String get scopeSyncOffsets => 'Synchronizacja dźwięku i napisów';
	@override String get playerScopeOff => 'Nie zapisuj';
	@override String get playerScopeGlobal => 'Wszędzie';
	@override String get playerScopeLibrary => 'Na bibliotekę';
	@override String get playerScopeTitle => 'Na serial lub film';
	@override String get exportDialogTitle => 'Eksport ustawień PlezyNG';
	@override String get followSystem => 'Zgodnie z systemem';
	@override String get followAppLanguage => 'Jak język interfejsu';
	@override String get regionFormat => 'Formaty regionalne';
	@override String get regionFormatDescription => 'Wybierz sposób wyświetlania dat, liczb i jednostek miary.';
	@override String get metadataLanguage => 'Język metadanych';
	@override String get metadataLanguageDescription => 'Preferowany język tytułów i opisów, jeśli serwer go obsługuje. Preferencje dźwięku i napisów ustawia się osobno.';
}

// Path: themeEditor
class _Translations$themeEditor$pl extends Translations$themeEditor$en {
	_Translations$themeEditor$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Wbudowane';
	@override String get presets => 'Gotowe motywy';
	@override String get custom => 'Własny';
	@override String get customEmpty => 'Jeszcze nie utworzono';
	@override String get editCustom => 'Edytuj własny motyw';
	@override String get editCustomDescription => 'Wybierz każdy kolor samodzielnie';
	@override String get locked => 'Wymagany dostęp do życia';
	@override String get savedLocked => 'Zbawione – dostępne z dostępem do życia';
	@override String get title => 'Własny motyw';
	@override String get startFrom => 'Zacznij od';
	@override String get startFromDescription => 'Skopiuj wszystkie kolory z innego motywu';
	@override String get colors => 'Kolory';
	@override String get preview => 'Podgląd';
	@override late final _Translations$themeEditor$slots$pl slots = _Translations$themeEditor$slots$pl._(_root);
	@override String get opacity => 'Krycie';
	@override String get hexHint => '#RRGGBB lub #AARRGGBB';
	@override String get fromOtherThemes => 'Z innych motywów';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} motywu ${theme}';
	@override late final _Translations$themeEditor$contrast$pl contrast = _Translations$themeEditor$contrast$pl._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, poniżej zalecanego ${minimum}:1';
	@override String get discardTitle => 'Odrzucić zmiany?';
	@override String get discardMessage => 'Niezapisane zmiany kolorów zostaną utracone.';
	@override String get discard => 'Odrzuć';
	@override String previewCardTitle({required Object number}) => 'Odcinek ${number}';
	@override String previewCardSubtitle({required Object minutes}) => 'Pozostało ${minutes} min';
	@override String get previewSwitch => 'Automatyczne odtwarzanie';
	@override String get previewMutedText => 'Tak wygląda tekst drugorzędny';
}

// Path: search
class _Translations$search$pl extends Translations$search$en {
	_Translations$search$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Szukaj filmów, seriali, muzyki...';
	@override String get tryDifferentTerm => 'Spróbuj innego wyszukiwania';
	@override String get searchYourMedia => 'Przeszukaj swoje media';
	@override String get enterTitleActorOrKeyword => 'Wprowadź tytuł, aktora lub słowo kluczowe';
	@override String get people => 'Osoby';
}

// Path: hotkeys
class _Translations$hotkeys$pl extends Translations$hotkeys$en {
	_Translations$hotkeys$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Ustaw skrót dla ${actionName}';
	@override String get clearShortcut => 'Wyczyść skrót';
	@override String get noShortcutSet => 'Brak ustawionego skrótu';
	@override String get currentShortcut => 'Bieżący skrót:';
	@override String get pressToRecord => 'Wybierz, aby zapisać skrót klawiszowy';
	@override String get recordingShortcut => 'Naciśnij teraz skrót klawiszowy';
	@override late final _Translations$hotkeys$actions$pl actions = _Translations$hotkeys$actions$pl._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$pl extends Translations$fileInfo$en {
	_Translations$fileInfo$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informacje o pliku';
	@override String get overview => 'Przegląd';
	@override String get video => 'Wideo';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Napisy';
	@override String get images => 'Obrazy osadzone';
	@override String get dataStreams => 'Strumienie danych';
	@override String get lyrics => 'Teksty';
	@override String get file => 'Plik';
	@override String get attachments => 'Załączniki';
	@override String get delivery => 'Dostarczanie';
	@override String versionCounter({required Object index, required Object count}) => 'Wersja ${index} z ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Plik ${index} z ${count}';
	@override String get noStreams => 'Serwer nie zgłosił żadnych strumieni dla tego pliku.';
	@override String get copyPath => 'Kopiuj ścieżkę';
	@override String get pathCopied => 'Skopiowano ścieżkę pliku';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Tag kodeka';
	@override String get resolution => 'Rozdzielczość';
	@override String get codedResolution => 'Rozdzielczość kodowania';
	@override String get bitrate => 'Przepływność';
	@override String get frameRate => 'Klatki na sekundę';
	@override String get rotation => 'Rotacja';
	@override String get comment => 'Komentarz';
	@override String get audioDescription => 'Audiodeskrypcja';
	@override String get headerCompression => 'Kompresja nagłówka';
	@override String get sidecarFile => 'Plik towarzyszący';
	@override String get transportTimestamp => 'Znacznik czasu transportu';
	@override String get displayOffset => 'Przesunięcie wyświetlania';
	@override String get previewFailureCode => 'Kod błędu podglądu';
	@override String get previewRetries => 'Ponowne próby podglądu';
	@override String get aspectRatio => 'Proporcje';
	@override String get pixelAspectRatio => 'Współczynnik proporcji pikseli';
	@override String get profile => 'Profil';
	@override String get level => 'Poziom';
	@override String get bitDepth => 'Głębia bitowa';
	@override String get pixelFormat => 'Format pikseli';
	@override String get colorSpace => 'Przestrzeń kolorów';
	@override String get colorRange => 'Zakres kolorów';
	@override String get colorPrimaries => 'Kolory podstawowe';
	@override String get colorTransfer => 'Przenoszenie kolorów';
	@override String get chromaSubsampling => 'Podpróbkowanie chrominancji';
	@override String get chromaLocation => 'Położenie chrominancji';
	@override String get scanType => 'Typ skanowania';
	@override String get interlaced => 'Z przeplotem';
	@override String get anamorphic => 'Anamorficzny';
	@override String get referenceFrames => 'Klatki referencyjne';
	@override String get dynamicRange => 'Zakres dynamiczny';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Poziom Dolby Vision';
	@override String get dolbyVisionVersion => 'Wersja Dolby Vision';
	@override String get dolbyVisionLayers => 'Warstwy Dolby Vision';
	@override String get baseLayerCompatibility => 'Zgodność warstwy bazowej';
	@override String get avcBitstream => 'Strumień bitowy AVC';
	@override String get nalLengthSize => 'Rozmiar długości NAL';
	@override String get scalingMatrix => 'Własna macierz skalowania';
	@override String get streamIdentifier => 'Identyfikator strumienia';
	@override String get streamIndex => 'Indeks strumienia';
	@override String get streamId => 'ID strumienia';
	@override String get language => 'Język';
	@override String get languageCode => 'Kod języka';
	@override String get streamTitle => 'Tytuł ścieżki';
	@override String get channels => 'Kanały';
	@override String get sampleRate => 'Częstotliwość próbkowania';
	@override String get spatialAudio => 'Dźwięk przestrzenny';
	@override String get textBased => 'Tekstowy';
	@override String get subtitleFormat => 'Format pliku towarzyszącego';
	@override String get provider => 'Dostawca';
	@override String get matchScore => 'Wynik dopasowania';
	@override String get externalDelivery => 'Może być dostarczany osobno';
	@override String get sidecarPath => 'Ścieżka pliku towarzyszącego';
	@override String get sourceStream => 'Skopiowano z';
	@override String get temporary => 'Tymczasowy';
	@override String get timeBase => 'Baza czasu';
	@override String get overallBitrate => 'Całkowita przepływność';
	@override String get path => 'Ścieżka';
	@override String get fileName => 'Nazwa pliku';
	@override String get size => 'Rozmiar';
	@override String get totalSize => 'Całkowity rozmiar';
	@override String get container => 'Kontener';
	@override String get duration => 'Czas trwania';
	@override String get previewThumbnails => 'Miniatury podglądu';
	@override String get previewIndex => 'Indeks podglądu';
	@override String get packetLength => 'Długość pakietu';
	@override String get filePresent => 'Plik obecny';
	@override String get fileReadable => 'Czytelny dla serwera';
	@override String get streamPath => 'Ścieżka strumienia';
	@override String get optimizedForStreaming => 'Zoptymalizowane do strumieniowania';
	@override String get has64bitOffsets => 'Przesunięcia 64-bitowe';
	@override String get protocol => 'Protokół';
	@override String get mediaType => 'Typ multimediów';
	@override String get sourceKind => 'Rodzaj źródła';
	@override String get optimizedVersion => 'Zoptymalizowana wersja';
	@override String get optimizationTarget => 'Cel optymalizacji';
	@override String get deletedAt => 'Usunięto';
	@override String get remoteSource => 'Źródło zdalne';
	@override String get infiniteStream => 'Nieskończony strumień';
	@override String get directPlay => 'Odtwarzanie bezpośrednie';
	@override String get directStream => 'Bezpośrednie strumieniowanie';
	@override String get transcoding => 'Transkodowanie';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID wersji';
	@override String get fileId => 'ID pliku';
	@override String get defaultAudioTrack => 'Domyślna ścieżka audio';
	@override String get defaultSubtitleTrack => 'Domyślna ścieżka napisów';
	@override String get subtitlesOff => 'Wył.';
	@override String get flagDefault => 'Domyślna';
	@override String get flagForced => 'Wymuszone';
	@override String get flagSelected => 'Wybrana';
	@override String get flagExternal => 'Zewnętrzne';
	@override String get flagHearingImpaired => 'Dla niesłyszących';
	@override String get flagDub => 'Dubbing';
	@override String get flagOriginal => 'Oryginalna';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$pl extends Translations$mediaMenu$en {
	_Translations$mediaMenu$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Oznacz jako obejrzane';
	@override String get markAsUnwatched => 'Oznacz jako nieobejrzane';
	@override String get removeFromContinueWatching => 'Usuń z kontynuowania oglądania';
	@override String get viewDetails => 'Pokaż szczegóły';
	@override String get goToSeries => 'Przejdź do serialu';
	@override String get shufflePlay => 'Odtwarzanie losowe';
	@override String get shuffleNotAvailableOffline => 'Odtwarzanie losowe nie jest dostępne offline';
	@override String get fileInfo => 'Informacje o pliku';
	@override String get deleteEpisodeFromServer => 'Usuń odcinek z serwera';
	@override String get deleteSeasonFromServer => 'Usuń sezon z serwera';
	@override String get deleteShowFromServer => 'Usuń serial z serwera';
	@override String get deleteMovieFromServer => 'Usuń film z serwera';
	@override String get deleteEpisodeTitle => 'Usunąć ten odcinek?';
	@override String get deleteSeasonTitle => 'Usunąć ten sezon?';
	@override String get deleteShowTitle => 'Usunąć ten serial?';
	@override String get deleteMovieTitle => 'Usunąć ten film?';
	@override String get deleteEpisodeConfirm => 'Usuń odcinek';
	@override String get deleteSeasonConfirm => 'Usuń sezon';
	@override String get deleteShowConfirm => 'Usuń serial';
	@override String get deleteMovieConfirm => 'Usuń film';
	@override String get deleteAnyway => 'Usuń mimo to';
	@override String confirmDeleteTarget({required Object title}) => 'Trwale usunąć ${title} z Twojego serwera?';
	@override String get deleteMultipleWarning => 'Obejmuje to wszystkie odcinki i ich pliki.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'Usunięty zostanie ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinek w nim oraz jego plik.',
		few: 'Usunięte zostaną ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinki w nim oraz ich pliki.',
		many: 'Usuniętych zostanie ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinków w nim oraz ich pliki.',
		other: 'Usuniętych zostanie ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinka w nim oraz ich pliki.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'Ten element jest przechowywany jako ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} plik, który zostanie usunięty.',
		few: 'Ten element jest przechowywany w ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} plikach, które wszystkie zostaną usunięte.',
		many: 'Ten element jest przechowywany w ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} plikach, które wszystkie zostaną usunięte.',
		other: 'Ten element jest przechowywany w ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pliku, który zostanie usunięty.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'W tym samym pliku przechowywany jest jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} inny odcinek, który również zostanie usunięty:',
		few: 'W tym samym pliku przechowywane są jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} inne odcinki, które również zostaną usunięte:',
		many: 'W tym samym pliku przechowywanych jest jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} innych odcinków, które również zostaną usunięte:',
		other: 'W tym samym pliku przechowywany jest jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} innego odcinka, który również zostanie usunięty:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG nie mogło sprawdzić, które pliki zostaną usunięte, więc może usunąć więcej niż element wymieniony powyżej. Anuluj i spróbuj ponownie albo usuń mimo to.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Twój serwer nie podał informacji o plikach tego elementu, więc PlezyNG nie może sprawdzić, które pliki zostaną usunięte. Może usunąć więcej niż element wymieniony powyżej.';
	@override String get mediaDeletedSuccessfully => 'Usunięto element multimedialny';
	@override String get mediaFailedToDelete => 'Nie udało się usunąć elementu multimedialnego';
	@override String get rate => 'Oceń';
	@override String get playFromBeginning => 'Odtwórz od początku';
	@override String get playVersion => 'Odtwórz wersję...';
}

// Path: rateSheet
class _Translations$rateSheet$pl extends Translations$rateSheet$en {
	_Translations$rateSheet$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oceń';
	@override String get server => 'Serwer';
	@override String get favorite => 'Dodaj do ulubionych';
	@override String get favorited => 'Dodano do ulubionych';
	@override String get saved => 'Zapisano';
	@override String get notAvailable => 'Nie znaleziono dopasowania';
	@override String get noConnectedServices => 'Połącz usługę w Ustawieniach, aby tam oceniać.';
}

// Path: accessibility
class _Translations$accessibility$pl extends Translations$accessibility$en {
	_Translations$accessibility$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, serial TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'obejrzane';
	@override String mediaCardPartiallyWatched({required Object percent}) => 'obejrzano w ${percent} procentach';
	@override String get mediaCardUnwatched => 'nieobejrzane';
	@override String get tapToPlay => 'Dotknij, aby odtworzyć';
	@override String get decrease => 'Zmniejsz';
	@override String get increase => 'Zwiększ';
	@override String decreaseValue({required Object label}) => 'Zmniejsz ${label}';
	@override String increaseValue({required Object label}) => 'Zwiększ ${label}';
	@override String get hue => 'Odcień';
	@override String get saturation => 'Nasycenie';
	@override String get brightness => 'Jasność';
	@override String get hexColor => 'Kolor szesnastkowy';
	@override String get expandText => 'Rozwiń tekst';
	@override String get collapseText => 'Zwiń tekst';
	@override String get alphabetNavigation => 'Nawigacja alfabetyczna';
	@override String get alphabetScrollHint => 'Przesuń w górę lub w dół, aby przejść o literę';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Wiersz ${row} z ${rowCount}, kolumna ${column} z ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Wiersz ${row} z ${rowCount}';
	@override String get autoScrollPlay => 'Uruchom automatyczne przewijanie';
	@override String get autoScrollPause => 'Wstrzymaj automatyczne przewijanie';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'w';
	@override String get red => 'Czerwony';
	@override String get green => 'Zielona';
	@override String get blue => 'niebieski';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Dostępność';
	@override String get summary => 'Tekst, kontrast, ruch i kontrolę';
	@override String get systemHint => 'Ustawienia dostępności urządzenia zawsze mają zastosowanie. te opcje dodają dostosowania w ciągu PlezyNG.';
	@override String get readability => 'Czytanie i widoczność';
	@override String get textSize => 'Dodatkowy rozmiar tekstu';
	@override String get preview => 'Przeczytaj, słuchaj i obserwuj w swoim własnym tempie.';
	@override String get boldText => 'Słynny interfejs tekst';
	@override String get highContrast => 'Wysoki kontrast';
	@override String get highContrastHint => 'Silniejsze teksty, wyświetleń i wskaźniki koncentracji na światłych lub ciemnych powierzchniach.';
	@override String get interaction => 'ruch i interakcja';
	@override String get reduceMotion => 'Zmniejszenie ruchu';
	@override String get reduceMotionHint => 'Utrzymuj koncentrację, przejścia strony i efekty dekoracyjne.';
	@override String get largeTargets => 'Większe cele dotykowe';
	@override String get largeTargetsHint => 'Daj podzielone kontrolki więcej miejsca na dotyk i pomocną nawigację.';
	@override String get navigationHint => 'Użyj karty Tab i Shift+Tab, aby przejść między kontrolami, wejść lub przestrzeń do aktywacji, a uciekać lub wrócić do zamknięcia.';
}

// Path: tooltips
class _Translations$tooltips$pl extends Translations$tooltips$en {
	_Translations$tooltips$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Odtwarzanie losowe';
	@override String get playTrailer => 'Odtwórz zwiastun';
	@override String get markAsWatched => 'Oznacz jako obejrzane';
	@override String get markAsUnwatched => 'Oznacz jako nieobejrzane';
}

// Path: audioTracks
class _Translations$audioTracks$pl extends Translations$audioTracks$en {
	_Translations$audioTracks$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Ścieżka audio ${n}';
}

// Path: videoControls
class _Translations$videoControls$pl extends Translations$videoControls$en {
	_Translations$videoControls$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} klatka',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ramy wideo',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ramy wideo',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ramy',
	);
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Napisy';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Pasy wokół obrazu';
	@override String get fillScreen => 'Wypełnij ekran';
	@override String get stretch => 'Rozciągnij';
	@override String get lockRotation => 'Zablokuj obrót';
	@override String get unlockRotation => 'Odblokuj obrót';
	@override String get timerActive => 'Wyłącznik aktywny';
	@override String playbackWillPauseIn({required Object duration}) => 'Odtwarzanie zatrzyma się za ${duration}';
	@override String get sleepTimerEndOfVideo => 'Koniec bieżącego wideo';
	@override String get sleepTimerStopAtHeader => 'Zatrzymaj o';
	@override String get sleepTimerDurationHeader => 'Minutnik';
	@override String get playbackWillPauseAtEnd => 'Odtwarzanie zatrzyma się na końcu tego wideo';
	@override String get stillWatching => 'Nadal oglądasz?';
	@override String pausingIn({required Object seconds}) => 'Pauza za ${seconds}s';
	@override String get continueWatching => 'Kontynuuj';
	@override String get autoPlayNext => 'Automatycznie odtwórz następny';
	@override String get playNext => 'Odtwórz następny';
	@override String get playButton => 'Odtwórz';
	@override String get pauseButton => 'Pauza';
	@override String get playbackPaused => 'Wstrzymano';
	@override String get playbackResumed => 'Odtwarzanie';
	@override String get loadingVideo => 'Ładowanie wideo';
	@override String get showPlaybackControls => 'Pokaż elementy sterujące odtwarzaniem';
	@override String get hidePlaybackControls => 'Ukryj elementy sterujące odtwarzaniem';
	@override String seekBackwardButton({required Object seconds}) => 'Przewiń do tyłu o ${seconds} sekund';
	@override String seekForwardButton({required Object seconds}) => 'Przewiń do przodu o ${seconds} sekund';
	@override String get previousButton => 'Poprzedni odcinek';
	@override String get nextButton => 'Następny odcinek';
	@override String get previousChapterButton => 'Poprzedni rozdział';
	@override String get nextChapterButton => 'Następny rozdział';
	@override String get muteButton => 'Wycisz';
	@override String get unmuteButton => 'Wyłącz wyciszenie';
	@override String get settingsButton => 'Ustawienia odtwarzania';
	@override String get tracksButton => 'Audio i napisy';
	@override String get trackSelectionTitle => 'Wybierz ścieżki przed playbackem';
	@override String get trackSelectionAuto => 'Automatyczne wybór';
	@override String get chaptersButton => 'Rozdziały';
	@override String get versionQualityButton => 'Wersja i jakość';
	@override String get versionColumnHeader => 'Wersja';
	@override String get qualityColumnHeader => 'Jakość';
	@override String get qualityOriginal => 'Oryginalna';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transkodowanie niedostępne — odtwarzanie w oryginalnej jakości';
	@override String get subtitleUnavailableFallback => 'Nie udało się wczytać wybranych napisów — odtwarzanie jest kontynuowane bez napisów';
	@override String get pipButton => 'Tryb obraz w obrazie';
	@override String get aspectRatioButton => 'Proporcje';
	@override String get ambientLighting => 'Oświetlenie otoczenia';
	@override String get fullscreenButton => 'Wejdź w pełny ekran';
	@override String get exitFullscreenButton => 'Wyjdź z pełnego ekranu';
	@override String get alwaysOnTopButton => 'Zawsze na wierzchu';
	@override String get rotationLockButton => 'Blokada obrotu';
	@override String get lockScreen => 'Zablokuj ekran';
	@override String get screenLockButton => 'Blokada ekranu';
	@override String get longPressToUnlock => 'Przytrzymaj, aby odblokować';
	@override String get timelineSlider => 'Oś czasu wideo';
	@override String get volumeSlider => 'Poziom głośności';
	@override String endsAt({required Object time}) => 'Kończy się o ${time}';
	@override String get pipActive => 'Odtwarzanie w trybie obraz w obrazie';
	@override String get pipFailed => 'Nie udało się uruchomić trybu obraz w obrazie';
	@override String get screenshotSaved => 'Zrzut ekranu zapisany';
	@override String get screenshotFailed => 'Nie udało się zrobić zrzutu ekranu';
	@override String zoomPercent({required Object percent}) => 'Powiększenie ${percent}%';
	@override String volumePercent({required Object percent}) => 'Głośność ${percent}%';
	@override late final _Translations$videoControls$pipErrors$pl pipErrors = _Translations$videoControls$pipErrors$pl._(_root);
	@override String get chapters => 'Rozdziały';
	@override String get noChaptersAvailable => 'Brak dostępnych rozdziałów';
	@override String get queue => 'Kolejka';
	@override String get noQueueItems => 'Brak elementów w kolejce';
	@override String get noAudioDevicesAvailable => 'Brak dostępnych urządzeń audio';
	@override String get searchSubtitles => 'Szukaj napisów';
	@override String get loadSubtitleFile => 'Pobierz subtitle plik...';
	@override String get subtitleLoadFailed => 'Nie udało się pobrać subtitle';
	@override String get language => 'Język';
	@override String get noSubtitlesFound => 'Nie znaleziono napisów';
	@override String get subtitleDownloaded => 'Napisy pobrane';
	@override String get subtitleDownloadedNotApplied => 'Napisy zostały pobrane, ale nie można ich było wybrać';
	@override String get subtitleDownloadFailed => 'Nie udało się pobrać napisów';
	@override String get searchLanguages => 'Szukaj języków...';
	@override String get skipIntro => 'Pomiń intro';
	@override String get skipCredits => 'Pomiń napisy końcowe';
	@override String get skipAds => 'Skok reklam';
	@override String get nextEpisode => 'Następny odcinek';
	@override String subtitleTrack({required Object n}) => 'Ścieżka ${n}';
	@override String subtitleFile({required Object name}) => 'Napisy ${name}';
	@override String forcedTrack({required Object label}) => '${label} (wymuszone)';
	@override String get osdSubtitlesOff => 'Napisy: wył.';
	@override String osdSubtitles({required Object track}) => 'Napisy: ${track}';
	@override String osdAudio({required Object track}) => 'Audio: ${track}';
}

// Path: messages
class _Translations$messages$pl extends Translations$messages$en {
	_Translations$messages$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Oznaczono jako obejrzane';
	@override String get markedAsUnwatched => 'Oznaczono jako nieobejrzane';
	@override String get markedAsWatchedOffline => 'Oznaczono jako obejrzane (zsynchronizuje się po połączeniu)';
	@override String get markedAsUnwatchedOffline => 'Oznaczono jako nieobejrzane (zsynchronizuje się po połączeniu)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatycznie usunięto: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzane pobranie',
		few: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzane pobrania',
		many: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzanych pobrań',
		other: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzanego pobrania',
	);
	@override String get removedFromContinueWatching => 'Usunięto z kontynuowania oglądania';
	@override String errorLoading({required Object error}) => 'Błąd: ${error}';
	@override String get searchPartialResults => 'Niektórych serwerów multimediów nie udało się przeszukać. Wyświetlane są dostępne wyniki.';
	@override String get streamInterrupted => 'Strumień został przerwany. Naciśnij odtwarzanie lub przewiń, aby spróbować ponownie.';
	@override String get liveStreamInterrupted => 'Transmisja na żywo została przerwana. Naciśnij odtwarzanie, aby spróbować ponownie.';
	@override String get fileInfoNotAvailable => 'Informacje o pliku niedostępne';
	@override String get playbackAuthenticationRequired => 'Zaloguj się ponownie na serwerze multimediów, aby odtworzyć ten element.';
	@override String get playbackServerUnavailable => 'Serwer multimediów jest niedostępny. Spróbuj ponownie później.';
	@override String get playbackDataInvalid => 'Serwer zwrócił nieprawidłowe informacje o odtwarzaniu.';
	@override String get playbackCancelled => 'Odtwarzanie zostało anulowane.';
	@override String get playbackFailed => 'Nie udało się rozpocząć odtwarzania.';
	@override String playbackFailedDetail({required Object error}) => 'Nie udało się rozpocząć odtwarzania: ${error}';
	@override String get audioOutputFailed => 'Wyjście audio przestało odpowiadać. Sprawdź połączenie audio telewizora lub amplitunera; jeśli inne aplikacje też nie mają dźwięku, uruchom urządzenie ponownie.';
	@override String get mediaUnavailable => 'Ta treść nie jest już dostępna.';
	@override String errorLoadingFileInfo({required Object error}) => 'Błąd ładowania informacji o pliku: ${error}';
	@override String get errorLoadingSeries => 'Błąd ładowania serialu';
	@override String get musicNotSupported => 'Odtwarzanie muzyki nie jest jeszcze obsługiwane';
	@override String get noDescriptionAvailable => 'Brak dostępnego opisu';
	@override String get noProfilesAvailable => 'Brak dostępnych profili';
	@override String get contactAdminForProfiles => 'Skontaktuj się z administratorem serwera, aby dodać profile';
	@override String get unableToDetermineLibrarySection => 'Nie można określić sekcji biblioteki dla tego elementu';
	@override String get logsCleared => 'Logi wyczyszczone';
	@override String get logsCopied => 'Logi skopiowane do schowka';
	@override String get noLogsAvailable => 'Brak dostępnych logów';
	@override String libraryScanning({required Object title}) => 'Skanowanie "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Rozpoczęto skanowanie biblioteki "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Nie udało się zeskanować biblioteki: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Odświeżanie metadanych "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Rozpoczęto odświeżanie metadanych "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Nie udało się odświeżyć metadanych: ${error}';
	@override String get logoutConfirm => 'Czy na pewno chcesz się wylogować?';
	@override String get noSeasonsFound => 'Nie znaleziono sezonów';
	@override String get seasonsLoadFailed => 'Nie udało się załadować sezonów';
	@override String get noEpisodesFound => 'Nie znaleziono odcinków w pierwszym sezonie';
	@override String get noEpisodesFoundGeneral => 'Nie znaleziono odcinków';
	@override String get episodesLoadFailed => 'Nie udało się załadować odcinków';
	@override String get noResultsFound => 'Nie znaleziono wyników';
	@override String sleepTimerSet({required Object label}) => 'Wyłącznik czasowy ustawiony na ${label}';
	@override String get noItemsAvailable => 'Brak dostępnych elementów';
	@override String get failedToCreatePlayQueueNoItems => 'Nie udało się utworzyć kolejki odtwarzania — brak elementów';
	@override String failedPlayback({required Object action, required Object error}) => 'Nie udało się ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Przełączanie na kompatybilny odtwarzacz...';
	@override String get serverLimitTitle => 'Odtwarzanie nie powiodło się';
	@override String get serverLimitBody => 'Błąd serwera (HTTP 500). Limit przepustowości/transkodowania prawdopodobnie odrzucił tę sesję. Poproś właściciela o zmianę.';
	@override String get mediaUnreadableTitle => 'Plik niedostępny';
	@override String get mediaUnreadableBody => 'Serwer znalazł ten element, ale nie mógł odczytać jego pliku (HTTP 404). Plik został prawdopodobnie przeniesiony, usunięty albo jego pamięć masowa jest niedostępna. Poproś właściciela serwera o sprawdzenie pliku i ponowne przeskanowanie biblioteki.';
	@override String get serverBusyTitle => 'Strumień niedostępny';
	@override String get serverBusyBody => 'Serwer wielokrotnie odmawiał strumieniowania tego pliku (HTTP 503). Być może jest ponownie uruchamiany lub zajęty albo magazyn danych zawierający plik jest offline. Spróbuj ponownie za chwilę — jeśli problem będzie się powtarzać, poproś właściciela serwera o sprawdzenie serwera i magazynu danych zawierającego plik.';
	@override String get playbackNotAllowedTitle => 'Odtwarzanie niedozwolone';
	@override String get playbackNotAllowedBody => 'Serwer odmówił strumieniowania tego elementu (HTTP 403). Twoje konto może nie mieć uprawnień do jego odtwarzania albo serwer może zezwalać na odtwarzanie tylko w swojej sieci lokalnej.';
	@override String get logsUploaded => 'Logi przesłane';
	@override String get logsUploadFailed => 'Nie udało się przesłać logów';
	@override String get logId => 'ID logu';
	@override String get burnedSubtitlesUseMenu => 'Napisy są wtopione w ten strumień. Zmień je w menu napisów.';
	@override String get noVideoUrl => 'Brak dostępnego adresu URL wideo';
	@override String get playbackNoMediaSources => 'Serwer nie zwrócił żadnych możliwych do odtworzenia źródeł multimediów';
	@override String get playbackDataNotPrepared => 'Odtwarzanie rozpoczęło się, zanim dane były gotowe';
	@override String get streamSelectionUnavailable => 'Wybór strumieni nie jest dostępny dla tego źródła';
	@override String get streamSelectionFailed => 'Nie udało się zastosować wybranych strumieni';
	@override String get trackSelectionNotRemembered => 'Ten wybór ścieżki dotyczy tylko bieżącego odtwarzania.';
	@override String get serverUnavailableForProfile => 'Brak dostępnego serwera dla aktywnego profilu';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$pl extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Szybki brązowy fox skoczy nad łagodnym psem';
	@override String get text => 'Tekst';
	@override String get border => 'Obramowanie';
	@override String get background => 'Tło';
	@override String get fontSize => 'Rozmiar czcionki';
	@override String get textColor => 'Kolor tekstu';
	@override String get borderSize => 'Rozmiar obramowania';
	@override String get borderColor => 'Kolor obramowania';
	@override String get backgroundOpacity => 'Przezroczystość tła';
	@override String get backgroundColor => 'Kolor tła';
	@override String get position => 'Pozycja';
	@override String get assOverride => 'Nadpisywanie ASS';
	@override String get overrideScale => 'Skaluj';
	@override String get overrideForce => 'Wymuś';
	@override String get overrideStrip => 'Usuń style';
	@override String get positionTop => 'Góra';
	@override String get positionBottom => 'Dół';
	@override String get useMargins => 'Użyj marginesów';
	@override String get useMarginsDescription => 'Pozwól napisom tekstowym pojawiać się w przestrzeni poza wideo. Napisy stylizowane mogą zachować pierwotne położenie.';
	@override String get anchorToScreen => 'Zakotwicz na ekranie';
	@override String get anchorToScreenDescription => 'Wyświetlaj napisy tekstowe na czarnych pasach poniżej obrazu panoramicznego';
	@override String get bold => 'Pogrubienie';
	@override String get italic => 'Kursywa';
	@override String get renderResolution => 'Rozdzielczość renderowania';
	@override String get renderResolutionScreen => 'Rozdzielczość ekranu';
	@override String get renderResolutionVideo => 'Rozdzielczość wideo';
}

// Path: mpvConfig
class _Translations$mpvConfig$pl extends Translations$mpvConfig$en {
	_Translations$mpvConfig$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Zaawansowane ustawienia odtwarzacza wideo';
	@override String get presets => 'Ustawienia wstępne';
	@override String get noPresets => 'Brak zapisanych ustawień wstępnych';
	@override String get saveAsPreset => 'Zapisz jako ustawienie wstępne...';
	@override String get presetName => 'Nazwa ustawienia wstępnego';
	@override String get presetNameHint => 'Wprowadź nazwę tego ustawienia wstępnego';
	@override String get loadPreset => 'Wczytaj';
	@override String get deletePreset => 'Usuń';
	@override String get presetSaved => 'Zapisano ustawienie wstępne';
	@override String get presetLoaded => 'Wczytano ustawienie wstępne';
	@override String get presetDeleted => 'Usunięto ustawienie wstępne';
	@override String get confirmDeletePreset => 'Czy na pewno chcesz usunąć to ustawienie wstępne?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Dodaj wiersz';
	@override String get removeLine => 'Usuń wiersz';
	@override String get embeddedVoHint => 'vo, gpu-context i gpu-api są ignorowane w systemie Linux: wbudowane wideo jest zawsze renderowane przez vo=libmpv na płaszczyźnie wideo, a gpu-next (wymagany przez shadery obliczeniowe takie jak ArtCNN) nie może działać w trybie wbudowanym.';
}

// Path: dialog
class _Translations$dialog$pl extends Translations$dialog$en {
	_Translations$dialog$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Potwierdź działanie';
}

// Path: profiles
class _Translations$profiles$pl extends Translations$profiles$en {
	_Translations$profiles$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Dodaj profil PlezyNG';
	@override String get switchingProfile => 'Przełączanie profilu…';
	@override String get deleteThisProfileTitle => 'Usunąć ten profil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Usuń ${displayName}. Połączenia nie zostaną zmienione.';
	@override String get active => 'Aktywny';
	@override String get manage => 'Zarządzaj';
	@override String get delete => 'Usuń';
	@override String get signOut => 'Wyloguj się';
	@override String get signOutPlexTitle => 'Wylogować się z Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Usunąć ${displayName} i wszystkich użytkowników Plex Home? Możesz zalogować się ponownie w każdej chwili.';
	@override String get signOutPlexDeleteDownloads => 'Usuń również pobrania';
	@override String get signOutPlexDeleteDownloadsDescription => 'W przeciwnym razie pozostaną na tym urządzeniu i wrócą po ponownym zalogowaniu się na to konto.';
	@override String get signedOutPlex => 'Wylogowano z Plex.';
	@override String get signOutFailed => 'Wylogowanie nie powiodło się.';
	@override String get sectionTitle => 'Profile';
	@override String get summarySingle => 'Dodaj profile, aby łączyć użytkowników zarządzanych z profilami lokalnymi';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => 'Liczba profili: ${count} · aktywny: ${activeName}';
	@override String summaryMultiple({required Object count}) => 'Liczba profili: ${count}';
	@override String get removeConnectionTitle => 'Usunąć połączenie?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Usuń dostęp ${displayName} do ${connectionLabel}. Inne profile go zachowają.';
	@override String get deleteProfileTitle => 'Usunąć profil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Usuń ${displayName} i jego połączenia. Serwery pozostaną dostępne.';
	@override String get profileNameLabel => 'Nazwa profilu';
	@override String get pinProtectionLabel => 'Ochrona PIN-em';
	@override String get copyAutomationLink => 'Kopiowanie Android automatyzacja link';
	@override String get copyAutomationLinkDescription => 'Wybierz ten profil z zamiaru lub automatyzacji Android.';
	@override String get automationLinkCopied => 'Profil automatyzacji link kopiował.';
	@override String get pinManagedByPlex => 'PIN zarządzany przez Plex. Edytuj na plex.tv.';
	@override String get noPinSetEditOnPlex => 'Nie ustawiono PIN-u. Aby go wymagać, edytuj użytkownika Home na plex.tv.';
	@override String get setPin => 'Ustaw PIN';
	@override String get setPinTitle => 'Ustaw PIN';
	@override String get confirmPinTitle => 'Potwierdź PIN';
	@override String get pinSet => 'PIN ustawiony';
	@override String get changePin => 'Zmień';
	@override String get removePin => 'Usuń';
	@override String get connectionsLabel => 'Połączenia';
	@override String get add => 'Dodaj';
	@override String get deleteProfileButton => 'Usuń profil';
	@override String get noConnectionsHint => 'Brak połączeń — dodaj jedno, aby używać tego profilu.';
	@override String get noConnections => 'Brak połączeń';
	@override String get plexHomeAccount => 'Konto Plex Home';
	@override String plexAccountChip({required Object account}) => 'Konto Plex: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} przez ${account}';
	@override String get connectionDefault => 'Domyślne';
	@override String connectionAs({required Object displayName}) => 'jako ${displayName}';
	@override String get makeDefault => 'Ustaw jako domyślne';
	@override String get removeConnection => 'Usuń';
	@override String get profileRenamed => 'Zmieniono nazwę profilu.';
	@override String borrowAddTo({required Object displayName}) => 'Dodaj do ${displayName}';
	@override String get borrowExplain => 'Skorzystaj z połączenia innego profilu. Profile chronione PIN-em wymagają podania PIN-u.';
	@override String get borrowEmpty => 'Nie ma jeszcze żadnych dostępnych połączeń.';
	@override String get borrowEmptySubtitle => 'Najpierw połącz Plex, Jellyfin lub Emby z innym profilem.';
	@override String get borrowLoadFailed => 'Nie udało się wczytać dostępnych połączeń. Spróbuj ponownie.';
	@override String borrowFromProfile({required Object displayName}) => 'Z profilu ${displayName}';
	@override String get borrowConnectionBorrowed => 'Dodano połączenie z innego profilu.';
	@override String get borrowFailed => 'Nie udało się dodać połączenia z innego profilu.';
	@override String get incorrectPin => 'Nieprawidłowy PIN.';
	@override String get incorrectPinTryAgain => 'Nieprawidłowy PIN. Spróbuj ponownie.';
	@override String get sourceProfileMissingParentAccount => 'Profil źródłowy nie ma konta nadrzędnego.';
	@override String get failedToLoadHomeUsers => 'Nie udało się wczytać użytkowników Plex Home. Sprawdź połączenie i spróbuj ponownie.';
	@override String get failedToVerifyPin => 'Nie udało się zweryfikować PIN-u.';
	@override String get newProfile => 'Nowy profil';
	@override String get profileNameHint => 'np. Goście, Dzieci, Salon';
	@override String get pinProtectionOptional => 'Ochrona PIN-em (opcjonalnie)';
	@override String get pinExplain => 'Do przełączania profili wymagany jest 4-cyfrowy PIN.';
	@override String get continueButton => 'Kontynuuj';
	@override String get pinsDontMatch => 'PIN-y nie pasują';
	@override String get tokenIdentityMismatch => 'Token profilu Plex został powiązany z nieoczekiwanym serwerem';
	@override String get settingsLocked => 'Ustawienia są zamknięte dla tego profilu.';
	@override String get unlockSettings => 'Odblokowanie ustawień';
	@override String get showExploreForProfile => 'Wyświetl przeglądarki dla tego profilu';
	@override String get showExploreForProfileDescription => 'Wyłącz, aby usunąć Explore z nawigacji tego profilu.';
}

// Path: connections
class _Translations$connections$pl extends Translations$connections$en {
	_Translations$connections$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Połączenia';
	@override String get addConnection => 'Dodaj połączenie';
	@override String get addConnectionSubtitleNoProfile => 'Zaloguj się przez Plex lub połącz serwer Jellyfin albo Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Dodaj do ${displayName}: Plex, Jellyfin, Emby lub połączenie innego profilu';
	@override String sessionExpiredOne({required Object name}) => 'Sesja wygasła dla ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sesja wygasła dla ${count} serwerów';
	@override String accessDeniedOne({required Object name}) => '${name} odmówił dostępu temu kontu';
	@override String accessDeniedMany({required Object count}) => 'Odmowa dostępu dla tego konta na ${count} serwerach';
	@override String get signInAgain => 'Zaloguj się ponownie';
	@override String editMediaBrowserTitle({required Object product}) => 'Edytuj połączenie z ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Dodaj lub usuń adresy URL dla ${serverName}. PlezyNG będzie używać osiągalnego adresu URL o najniższym opóźnieniu.';
}

// Path: accountPreferences
class _Translations$accountPreferences$pl extends Translations$accountPreferences$en {
	_Translations$accountPreferences$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Preferencje konta';
	@override String hubSubtitleSingle({required Object account}) => 'Opcje audio, napisów i biblioteki zapisane na koncie ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Opcje audio, napisów i biblioteki zapisane na ${count} kontach';
	@override String get pickAccount => 'Każde konto przechowuje własne preferencje. Wybierz to, które chcesz edytować.';
	@override String get storedOnAccount => 'Te opcje są zapisywane na samym koncie, więc używa ich każda aplikacja zalogowana na to konto — w tym PlezyNG na Twoich innych urządzeniach.';
	@override String get noAccounts => 'Brak kont do skonfigurowania';
	@override String get noAccountsHint => 'Zaloguj się do Plex albo połącz serwer Jellyfin lub Emby, a preferencje zapisane na tym koncie pojawią się tutaj.';
	@override String get unavailable => 'Nie można połączyć się z tym kontem';
	@override String get loadFailed => 'Nie udało się wczytać tych preferencji';
	@override String get noPreference => 'Brak preferencji';
	@override String get notSet => 'Nie ustawiono';
	@override late final _Translations$accountPreferences$groups$pl groups = _Translations$accountPreferences$groups$pl._(_root);
	@override String get preferredAudioLanguage => 'Preferowany język audio';
	@override String get autoSelectAudio => 'Wybieraj audio według języka';
	@override String get autoSelectAudioDescription => 'Ustawienie „Wył.” pozostawia ścieżkę audio, którą plik oznacza jako domyślną.';
	@override String get preferredSubtitleLanguage => 'Preferowany język napisów';
	@override String get subtitleMode => 'Włączanie napisów';
	@override late final _Translations$accountPreferences$subtitleModes$pl subtitleModes = _Translations$accountPreferences$subtitleModes$pl._(_root);
	@override String get subtitleAccessibility => 'Napisy SDH';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$pl subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$pl._(_root);
	@override String get forcedSubtitles => 'Wymuszone napisy';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$pl forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$pl._(_root);
	@override String get displayMissingEpisodes => 'Pokaż brakujące odcinki';
	@override String get displayMissingEpisodesDescription => 'Wyświetlaj odcinki, które serwer zna, ale dla których nie ma pliku.';
	@override String get hidePlayedInLatest => 'Ukrywaj obejrzane pozycje w sekcji Ostatnio dodane';
	@override String get hidePlayedInLatestDescription => 'Pomijaj pozycje, które już obejrzałeś, w wierszach „Ostatnio dodane” serwera.';
	@override String get displayCollectionsView => 'Pokaż widok „Kolekcje”';
	@override String get displayCollectionsViewDescription => 'Pokazuj widok kolekcji serwera obok Twoich bibliotek.';
	@override String get rewatchingInNextUp => 'Zachowuj ponownie oglądane seriale w sekcji „Następny odcinek”';
	@override String get rewatchingInNextUpDescription => 'Gdy skończysz serial i zaczniesz go oglądać ponownie, sekcja „Następny odcinek” podąży za ponownym oglądaniem zamiast usuwać serial.';
	@override String get watchedIndicator => 'Wskaźniki obejrzanych';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$pl watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$pl._(_root);
	@override String get mediaReviewsVisibility => 'Oceny i recenzje';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$pl mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$pl._(_root);
}

// Path: discover
class _Translations$discover$pl extends Translations$discover$en {
	_Translations$discover$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Odkryj';
	@override String get noContentAvailable => 'Brak dostępnych treści';
	@override String get addMediaToLibraries => 'Dodaj multimedia do swoich bibliotek';
	@override String get continueWatching => 'Kontynuuj oglądanie';
	@override String continueWatchingIn({required Object library}) => 'Kontynuuj oglądanie w ${library}';
	@override String get nextUp => 'Następny odcinek';
	@override String nextUpIn({required Object library}) => 'Następny odcinek w ${library}';
	@override String get recentlyAdded => 'Ostatnio dodane';
	@override String recentlyAddedIn({required Object library}) => 'Ostatnio dodane w ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Najnowsze albumy w ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Ostatnio odtwarzane w ${library}';
	@override String mostPlayedIn({required Object library}) => 'Najczęściej odtwarzane w ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Opis';
	@override String get cast => 'Obsada';
	@override late final _Translations$discover$findNext$pl findNext = _Translations$discover$findNext$pl._(_root);
	@override String get extras => 'Zwiastuny i dodatki';
	@override String get studio => 'Studio';
	@override String get rating => 'Ocena';
	@override String get director => 'Reżyser';
	@override String get directors => 'Reżyserzy';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serial TV';
	@override String minutesLeft({required Object minutes}) => 'Pozostało ${minutes} min';
	@override String get moreLikeThis => 'Więcej podobnych';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytuł',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytuły',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytułów',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytułu',
	);
	@override late final _Translations$discover$person$pl person = _Translations$discover$person$pl._(_root);
}

// Path: errors
class _Translations$errors$pl extends Translations$errors$en {
	_Translations$errors$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Wyszukiwanie nie powiodło się: ${error}';
	@override String get searchUnavailable => 'Wyszukiwanie nie mogło połączyć się z żadnym serwerem multimediów.';
	@override String connectionTimeout({required Object context}) => 'Limit czasu połączenia przy ładowaniu ${context}';
	@override String get connectionFailed => 'Nie można połączyć się z serwerem multimediów';
	@override String unableToLoad({required Object context}) => 'Nie udało się załadować ${context}. Spróbuj ponownie.';
	@override String get noClientAvailable => 'Brak dostępnego klienta';
	@override String get pleaseEnterToken => 'Wprowadź token';
	@override String get invalidToken => 'Nieprawidłowy token';
	@override String failedToVerifyToken({required Object error}) => 'Nie udało się zweryfikować tokena: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Nie udało się przełączyć na ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Nie udało się usunąć ${displayName}';
	@override String get failedToRate => 'Nie udało się zaktualizować oceny';
	@override String get reasonTimedOut => 'upłynął limit czasu połączenia';
	@override String get reasonUnreachable => 'nie można połączyć się z serwerem';
	@override String get reasonRefused => 'serwer odrzucił żądanie';
	@override String get reasonNotFound => 'elementu nie ma już na serwerze';
	@override String get reasonServerError => 'serwer zgłosił błąd';
	@override String get reasonCancelled => 'żądanie zostało anulowane';
	@override String get reasonUnexpected => 'wystąpił nieoczekiwany błąd';
}

// Path: libraries
class _Translations$libraries$pl extends Translations$libraries$en {
	_Translations$libraries$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Zagraj w filmie randomizowanym';
	@override String get randomPickFailed => 'Nie można wybrać filmów z tej biblioteki.';
	@override String get title => 'Biblioteki';
	@override String get fallbackTitle => 'Biblioteka';
	@override String get scanLibraryFiles => 'Skanuj pliki biblioteki';
	@override String get scanLibrary => 'Skanuj bibliotekę';
	@override String get analyze => 'Analizuj';
	@override String get analyzeLibrary => 'Analizuj bibliotekę';
	@override String get refreshMetadata => 'Odśwież metadane';
	@override String get emptyTrash => 'Opróżnij kosz';
	@override String emptyingTrash({required Object title}) => 'Opróżnianie kosza dla "${title}"...';
	@override String trashEmptied({required Object title}) => 'Kosz opróżniony dla "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Nie udało się opróżnić kosza: ${error}';
	@override String analyzing({required Object title}) => 'Analizowanie "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analiza rozpoczęta dla "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Nie udało się przeanalizować biblioteki: ${error}';
	@override String get noLibrariesFound => 'Nie znaleziono bibliotek';
	@override String get allLibrariesHidden => 'Wszystkie biblioteki są ukryte';
	@override String hiddenLibrariesCount({required Object count}) => 'Ukryte biblioteki (${count})';
	@override String get thisLibraryIsEmpty => 'Ta biblioteka jest pusta';
	@override String get noItemsMatchFilters => 'Żaden element nie pasuje do aktywnych filtrów';
	@override String get resetFilters => 'Resetuj filtry';
	@override String get all => 'Wszystkie';
	@override String get clearAll => 'Wyczyść wszystko';
	@override String scanLibraryConfirm({required Object title}) => 'Czy na pewno chcesz zeskanować "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Czy na pewno chcesz przeanalizować "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Czy na pewno chcesz odświeżyć metadane dla "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Czy na pewno chcesz opróżnić kosz dla "${title}"?';
	@override String get manageLibraries => 'Zarządzaj bibliotekami';
	@override String get sort => 'Sortuj';
	@override String get sortBy => 'Sortuj wg';
	@override String get filters => 'Filtry';
	@override String get confirmActionMessage => 'Czy na pewno chcesz wykonać tę operację?';
	@override String get showLibrary => 'Pokaż bibliotekę';
	@override String get hideLibrary => 'Ukryj bibliotekę';
	@override String get libraryOptions => 'Opcje biblioteki';
	@override String get content => 'zawartość biblioteki';
	@override String get selectLibrary => 'Wybierz bibliotekę';
	@override String filtersWithCount({required Object count}) => 'Filtry (${count})';
	@override String get noRecommendations => 'Brak dostępnych rekomendacji';
	@override String get noCollections => 'Brak kolekcji w tej bibliotece';
	@override String get noFoldersFound => 'Nie znaleziono folderów';
	@override String get folders => 'foldery';
	@override late final _Translations$libraries$tabs$pl tabs = _Translations$libraries$tabs$pl._(_root);
	@override late final _Translations$libraries$groupings$pl groupings = _Translations$libraries$groupings$pl._(_root);
	@override late final _Translations$libraries$filterCategories$pl filterCategories = _Translations$libraries$filterCategories$pl._(_root);
	@override late final _Translations$libraries$sortLabels$pl sortLabels = _Translations$libraries$sortLabels$pl._(_root);
	@override late final _Translations$libraries$advancedFilters$pl advancedFilters = _Translations$libraries$advancedFilters$pl._(_root);
	@override late final _Translations$libraries$selection$pl selection = _Translations$libraries$selection$pl._(_root);
}

// Path: about
class _Translations$about$pl extends Translations$about$en {
	_Translations$about$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'O aplikacji';
	@override String get openSourceLicenses => 'Licencje oprogramowania open source';
	@override String versionLabel({required Object version}) => 'Wersja ${version}';
	@override String get appDescription => 'Piękny klient Plex, Jellyfin i Emby stworzony we Flutterze';
	@override String get viewLicensesDescription => 'Wyświetl licencje bibliotek innych firm';
	@override String get privacyPolicy => 'Polityka prywatności';
}

// Path: serverSelection
class _Translations$serverSelection$pl extends Translations$serverSelection$en {
	_Translations$serverSelection$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nie znaleziono serwerów dla ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Nie udało się załadować serwerów: ${error}';
	@override String get noValidServers => 'Nie znaleziono żadnych zdatnych serwerów na tym koncie';
}

// Path: hubDetail
class _Translations$hubDetail$pl extends Translations$hubDetail$en {
	_Translations$hubDetail$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tytuł';
	@override String get releaseYear => 'Rok premiery';
	@override String get dateAdded => 'Data dodania';
	@override String get rating => 'Ocena';
	@override String get noItemsFound => 'Nie znaleziono elementów';
}

// Path: logs
class _Translations$logs$pl extends Translations$logs$en {
	_Translations$logs$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Wyczyść logi';
	@override String get copyLogs => 'Kopiuj logi';
	@override String get uploadLogs => 'Prześlij logi';
	@override String get saveLogs => 'Zapisz log do pliku';
	@override String logsSaved({required Object path}) => 'Zapisy zapisane do ${path}';
	@override String get saveLogsFailed => 'Nie mogłem zapisać pliku logowego.';
}

// Path: detail
class _Translations$detail$pl extends Translations$detail$en {
	_Translations$detail$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Kończy się o ${time}';
}

// Path: startup
class _Translations$startup$pl extends Translations$startup$en {
	_Translations$startup$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Nie udało się uruchomić PlezyNG';
	@override String get failedBody => 'Coś poszło nie tak podczas uruchamiania. Poniższe szczegóły wskazują, co zawiodło.';
	@override String get failedBodyRepairable => 'Zapisany plik ustawień PlezyNG jest uszkodzony i musi zostać odbudowany, zanim PlezyNG będzie mogło się uruchomić. Ponawianie nie pomoże — wybierz Napraw pamięć.';
	@override String get phaseLabel => 'Krok';
	@override String get showDetails => 'Pokaż szczegóły';
	@override String get hideDetails => 'Ukryj szczegóły';
	@override String get copyDetails => 'Kopiuj szczegóły';
	@override String get detailsCopied => 'Skopiowano szczegóły do schowka';
	@override String get uploadDetails => 'Prześlij szczegóły';
	@override String get repairStorage => 'Napraw pamięć';
	@override String get repairTitle => 'Naprawić zapisane dane?';
	@override String get repairBodyCommon => 'Plik ustawień PlezyNG jest uszkodzony i nie można go odczytać. Naprawa przywraca wszystkie ustawienia do wartości domyślnych.';
	@override String get repairBodyOneCredential => 'Jedno zapisane logowanie jest uszkodzone i nie można go odczytać. Naprawa usunie tylko je; pozostałe ustawienia pozostaną nietknięte.';
	@override String get repairBodySignInsKept => 'Twoje serwery i profile powinny pozostać zalogowane.';
	@override String get repairBodySignInsLost => 'Klucza chroniącego zapisane logowania nie można odzyskać z tego pliku, więc będziesz musiał zalogować się ponownie na każdym serwerze i profilu. Nic na Twoim serwerze multimediów nie zostanie zmienione.';
	@override String get repairBodySessionsUncertain => 'Usługi śledzenia (MAL, AniList, Simkl, Trakt) i Seerr są przechowywane osobno i mogą, ale nie muszą przetrwać. PlezyNG dokładnie poinformuje Cię, co zachowało.';
	@override String get repairConfirm => 'Napraw';
	@override String get repairSucceeded => 'Naprawiono pamięć';
	@override String get repairNeedsRestart => 'Naprawiono pamięć — wymagany restart';
	@override String get restartRequiredBody => 'Twoje dane zostały naprawione, ale PlezyNG musi uruchomić się od nowa, zanim będzie mogło z nich korzystać. Zamknij PlezyNG i otwórz je ponownie.';
	@override String get quitPlezy => 'Zamknij PlezyNG';
	@override String get repairFailed => 'Naprawa nie powiodła się';
	@override String get repairKeptSignIns => 'Twoje serwery i profile są nadal zalogowane.';
	@override String get repairLostSignIns => 'Nie udało się odzyskać klucza chroniącego zapisane logowania. Musisz zalogować się ponownie na każdym serwerze i profilu.';
	@override String get repairLostSessions => 'Utracono co najmniej jedno połączenie z usługą śledzenia lub Seerr i trzeba je ponownie połączyć.';
	@override String get backupTitle => 'Zachowano kopię uszkodzonego pliku';
	@override String get backupWarning => 'Zawiera Twoje dane logowania. Nie przesyłaj ani nie udostępniaj jej.';
	@override String get deleteBackup => 'Usuń kopię';
	@override String get backupDeleted => 'Usunięto kopię.';
	@override String get previousFailureTitle => 'Ostatnim razem nie udało się uruchomić PlezyNG';
}

// Path: licenses
class _Translations$licenses$pl extends Translations$licenses$en {
	_Translations$licenses$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Powiązane pakiety';
	@override String get license => 'Licencja';
	@override String licenseNumber({required Object number}) => 'Licencja ${number}';
	@override String licensesCount({required Object count}) => 'Liczba licencji: ${count}';
}

// Path: navigation
class _Translations$navigation$pl extends Translations$navigation$en {
	_Translations$navigation$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Biblioteki';
	@override String get downloads => 'Pobrania';
	@override String get liveTv => 'TV na żywo';
	@override String get explore => 'Przeglądaj';
}

// Path: explore
class _Translations$explore$pl extends Translations$explore$en {
	_Translations$explore$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$pl mdblistShelves = _Translations$explore$mdblistShelves$pl._(_root);
	@override String get title => 'Przeglądaj';
	@override String get selectSource => 'Wybierz źródło';
	@override late final _Translations$explore$rows$pl rows = _Translations$explore$rows$pl._(_root);
	@override late final _Translations$explore$status$pl status = _Translations$explore$status$pl._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinek',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinki',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinków',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinka',
	);
	@override String get cast => 'Obsada';
	@override String get characters => 'Postacie';
	@override String get addToWatchlist => 'Dodaj do listy do obejrzenia';
	@override String get removeFromWatchlist => 'Usuń z listy do obejrzenia';
	@override String get addedToWatchlist => 'Dodano do listy do obejrzenia';
	@override String get removedFromWatchlist => 'Usunięto z listy do obejrzenia';
	@override String get watchlistUpdateFailed => 'Nie udało się zaktualizować listy do obejrzenia';
	@override String get watchlistNoMatch => 'Nie udało się dopasować tej pozycji do listy do obejrzenia';
	@override String get notInLibrary => 'Nie ma tego w Twojej bibliotece';
	@override String get inTheseLibraries => 'W tych bibliotekach';
	@override String get checkingLibrary => 'Sprawdzanie Twojej biblioteki...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwera',
		few: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwerów',
		many: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwerów',
		other: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwerów',
	);
	@override String get emptyTitle => 'Jeszcze nic tu nie ma';
	@override String emptyMessage({required Object source}) => 'Wiersze z ${source} pojawią się tutaj, gdy będą zawierać treści.';
	@override String searchHint({required Object source}) => 'Szukaj w ${source}';
	@override String searchEmpty({required Object query}) => 'Brak wyników dla "${query}"';
	@override String searchPrompt({required Object source}) => 'Szukaj filmów i seriali w ${source}.';
	@override String get searchFailed => 'Wyszukiwanie nie powiodło się. Sprawdź połączenie i spróbuj ponownie.';
	@override late final _Translations$explore$badge$pl badge = _Translations$explore$badge$pl._(_root);
	@override late final _Translations$explore$stats$pl stats = _Translations$explore$stats$pl._(_root);
	@override late final _Translations$explore$season$pl season = _Translations$explore$season$pl._(_root);
	@override late final _Translations$explore$format$pl format = _Translations$explore$format$pl._(_root);
	@override late final _Translations$explore$sourceMaterial$pl sourceMaterial = _Translations$explore$sourceMaterial$pl._(_root);
	@override late final _Translations$explore$creditRole$pl creditRole = _Translations$explore$creditRole$pl._(_root);
	@override late final _Translations$explore$relation$pl relation = _Translations$explore$relation$pl._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Emisja ${day} o ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Emisja ${day} o ${time} ${timezone}';
	@override late final _Translations$explore$detail$pl detail = _Translations$explore$detail$pl._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wynik',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wyniki',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wyników',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wyniku',
	);
}

// Path: liveTv
class _Translations$liveTv$pl extends Translations$liveTv$en {
	_Translations$liveTv$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV na żywo';
	@override String get guide => 'Przewodnik';
	@override String get noChannels => 'Brak dostępnych kanałów';
	@override String get noDvr => 'Brak skonfigurowanego DVR na żadnym serwerze';
	@override String get serverUnavailable => 'Serwer telewizji na żywo jest niedostępny.';
	@override String get serverNotConnected => 'Serwer telewizji na żywo nie jest połączony.';
	@override String get noPrograms => 'Brak danych o programach';
	@override String get liveStreamFailed => 'Transmisja na żywo nie powiodła się';
	@override String get unknownProgram => 'Nieznany program';
	@override String get timelineLiveProgram => 'Program na żywo (playback może być poza tym programem)';
	@override String get timelineBuffer => 'Temat Buffer';
	@override String get timelineUnavailable => 'Czas nie dostępny';
	@override String get timelineEstimated => 'Podsumowanie Playback';
	@override String get timelinePending => 'W poszukiwaniu';
	@override String get timelineStale => 'Program może być przestarzały';
	@override String get unknownHub => 'Nieznane';
	@override String get unknownError => 'Nieznany błąd';
	@override String channelNumber({required Object number}) => 'Kanał ${number}';
	@override String get unknownChannel => 'Nieznany kanał';
	@override String get live => 'NA ŻYWO';
	@override String get premiereBadge => 'Nowy';
	@override String get reloadGuide => 'Odśwież przewodnik';
	@override String get searchGuide => 'Szukaj w przewodniku';
	@override String get searchHint => 'Szukaj kanałów i programów';
	@override String searchNoResults({required Object query}) => 'Brak dopasowań dla "${query}"';
	@override String get channelsSection => 'Kanały';
	@override String get programsSection => 'Programy';
	@override String get now => 'Teraz';
	@override String get today => 'Dzisiaj';
	@override String get tomorrow => 'Jutro';
	@override String get midnight => 'Północ';
	@override String get overnight => 'Nocą';
	@override String get morning => 'Rano';
	@override String get daytime => 'W ciągu dnia';
	@override String get evening => 'Wieczorem';
	@override String get lateNight => 'Późna noc';
	@override String get whatsOn => 'Co leci';
	@override String get watchChannel => 'Oglądaj kanał';
	@override String get favorites => 'Ulubione';
	@override String get reorderFavorites => 'Zmień kolejność ulubionych';
	@override String get noFavoriteChannels => 'Brak ulubionych kanałów';
	@override String get noFavoriteChannelsHint => 'Pokaż wszystkie kanały, a następnie naciśnij i przytrzymaj kanał, aby dodać go do ulubionych.';
	@override String get showAllChannels => 'Pokaż wszystkie kanały';
	@override String get favoritesLoadFailed => 'Nie udało się wczytać ulubionych. Sprawdź połączenie i spróbuj ponownie.';
	@override String get favoritesUpdateFailed => 'Nie udało się zaktualizować ulubionych. Sprawdź połączenie i spróbuj ponownie.';
	@override String get joinSession => 'Dołącz do trwającej sesji';
	@override String watchFromStart({required Object minutes}) => 'Oglądaj od początku (${minutes} min temu)';
	@override String get watchLive => 'Oglądaj na żywo';
	@override String get goToLive => 'Przejdź do transmisji na żywo';
	@override String get record => 'Nagraj';
	@override String get recordEpisode => 'Nagraj odcinek';
	@override String get recordSeries => 'Nagraj serial';
	@override String get recordOptions => 'Opcje nagrywania';
	@override String get saveTo => 'Zapisz w';
	@override String get recordings => 'Nagrania';
	@override String get scheduledRecordings => 'Zaplanowane';
	@override String get recordingRules => 'Reguły nagrywania';
	@override String get noScheduledRecordings => 'Brak zaplanowanych nagrań';
	@override String get manageRecording => 'Zarządzaj nagraniem';
	@override String get cancelRecording => 'Anuluj nagrywanie';
	@override String get cancelRecordingTitle => 'Anulować to nagrywanie?';
	@override String cancelRecordingMessage({required Object title}) => '${title} nie będzie już nagrywane.';
	@override String get deleteRule => 'Usuń regułę';
	@override String get deleteRuleTitle => 'Usunąć regułę nagrywania?';
	@override String deleteRuleMessage({required Object title}) => 'Przyszłe odcinki ${title} nie będą nagrywane.';
	@override String get recordingScheduled => 'Nagrywanie zaplanowane';
	@override String get alreadyScheduled => 'Ten program jest już zaplanowany';
	@override String get dvrAdminRequired => 'Ustawienia DVR wymagają konta administratora';
	@override String get recordingFailed => 'Nie można zaplanować nagrywania';
	@override String get recordingTargetMissing => 'Nie można określić biblioteki nagrań';
	@override String get recordNotAvailable => 'Nagrywanie niedostępne dla tego programu';
	@override String get recordingCancelled => 'Nagrywanie anulowane';
	@override String get recordingRuleDeleted => 'Reguła nagrywania usunięta';
	@override String get processRecordingRules => 'Ponów ocenę reguł';
	@override String get recordingInProgress => 'Trwa nagrywanie';
	@override String recordingsCount({required Object count}) => '${count} zaplanowanych';
	@override String get editRule => 'Edytuj regułę';
	@override String get editRuleAction => 'Edytuj';
	@override String get recordingRuleUpdated => 'Reguła nagrywania zaktualizowana';
	@override String get guideReloadRequested => 'Zażądano odświeżenia przewodnika';
	@override String get guideReloadFailed => 'Nie udało się odświeżyć przewodnika';
	@override String get rulesProcessRequested => 'Zażądano ponownej oceny reguł';
	@override String get rulesProcessFailed => 'Nie udało się ponownie przetworzyć reguł nagrywania';
	@override String get recordShow => 'Nagraj program';
	@override late final _Translations$liveTv$recordSettings$pl recordSettings = _Translations$liveTv$recordSettings$pl._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Rozpocznie się za ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} o ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} zwrócił nieprawidłowe dane odtwarzania TV na żywo';
	@override String get failedToStartChannel => 'Nie udało się uruchomić kanału na żywo';
	@override String get failedToBuildStreamUrl => 'Nie udało się utworzyć adresu URL strumienia';
	@override String playbackStartFailed({required Object reason}) => 'Nie udało się uruchomić kanału: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Nie udało się przełączyć kanału: ${reason}';
}

// Path: collections
class _Translations$collections$pl extends Translations$collections$en {
	_Translations$collections$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kolekcje';
	@override String get collection => 'Kolekcja';
	@override String get empty => 'Kolekcja jest pusta';
	@override String get deleteCollection => 'Usuń kolekcję';
	@override String deleteConfirm({required Object title}) => 'Usunąć "${title}"? Tego nie można cofnąć.';
	@override String get deleted => 'Kolekcja usunięta';
	@override String get deleteFailed => 'Nie udało się usunąć kolekcji';
	@override String deleteFailedWithError({required Object error}) => 'Nie udało się usunąć kolekcji: ${error}';
	@override String get selectCollection => 'Wybierz kolekcję';
	@override String get collectionName => 'Nazwa kolekcji';
	@override String get enterCollectionName => 'Wprowadź nazwę kolekcji';
	@override String get addedToCollection => 'Dodano do kolekcji';
	@override String get errorAddingToCollection => 'Nie udało się dodać do kolekcji';
	@override String get created => 'Kolekcja utworzona';
	@override String get removeFromCollection => 'Usuń z kolekcji';
	@override String removeFromCollectionConfirm({required Object title}) => 'Usunąć "${title}" z tej kolekcji?';
	@override String get removedFromCollection => 'Usunięto z kolekcji';
	@override String get removeFromCollectionFailed => 'Nie udało się usunąć z kolekcji';
	@override String removeFromCollectionError({required Object error}) => 'Błąd usuwania z kolekcji: ${error}';
	@override String get searchCollections => 'Szukaj kolekcji...';
}

// Path: playlists
class _Translations$playlists$pl extends Translations$playlists$en {
	_Translations$playlists$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlisty';
	@override String get playlist => 'Playlista';
	@override String get noPlaylists => 'Nie znaleziono playlist';
	@override String get create => 'Utwórz playlistę';
	@override String get playlistName => 'Nazwa playlisty';
	@override String get enterPlaylistName => 'Wprowadź nazwę playlisty';
	@override String get delete => 'Usuń playlistę';
	@override String get removeItem => 'Usuń z playlisty';
	@override String get smartPlaylist => 'Inteligentna playlista';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementy',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementów',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementu',
	);
	@override String get emptyPlaylist => 'Ta playlista jest pusta';
	@override String get deleteConfirm => 'Usunąć playlistę?';
	@override String deleteMessage({required Object name}) => 'Czy na pewno chcesz usunąć "${name}"?';
	@override String get created => 'Playlista utworzona';
	@override String get deleted => 'Playlista usunięta';
	@override String get itemAdded => 'Dodano do playlisty';
	@override String get itemRemoved => 'Usunięto z playlisty';
	@override String get selectPlaylist => 'Wybierz playlistę';
	@override String get searchPlaylists => 'Szukaj playlist...';
	@override String get errorCreating => 'Nie udało się utworzyć playlisty';
	@override String get errorDeleting => 'Nie udało się usunąć playlisty';
	@override String get errorLoading => 'Nie udało się załadować playlist';
	@override String get errorAdding => 'Nie udało się dodać do playlisty';
	@override String get errorReordering => 'Nie udało się zmienić kolejności elementu playlisty';
	@override String get errorRemoving => 'Nie udało się usunąć z playlisty';
}

// Path: music
class _Translations$music$pl extends Translations$music$en {
	_Translations$music$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Przejdź do albumu';
	@override String get goToArtist => 'Przejdź do wykonawcy';
	@override String get instantMix => 'Miks błyskawiczny';
	@override String get playNext => 'Odtwórz następny';
	@override String get addToQueue => 'Dodaj do kolejki';
	@override String discNumber({required Object n}) => 'Płyta ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utwór',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utwory',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utworów',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utworu',
	);
	@override String get nowPlaying => 'Teraz odtwarzane';
	@override String playingFrom({required Object title}) => 'Odtwarzanie z ${title}';
	@override String get queue => 'Kolejka';
	@override String get clearQueue => 'Wyczyść kolejkę';
	@override String get lyrics => 'Tekst utworu';
	@override String get visualizer => 'Wizualizator';
	@override String get visualizerProfileLoading => 'Czytaj dalej wpis Analiza ścieżki...';
	@override String get visualizerAmbientMotion => 'Ambientowe ruchy';
	@override String get visualizerPlexLoudness => 'Głośność Plex';
	@override String get visualizerPreviousPreset => 'Poprzedni artykułWizualny styl';
	@override String get visualizerNextPreset => 'Następny artykułWizualny styl';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Bloom';
	@override String get visualizerPresetOrbitals => 'orbity';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'tunel';
	@override String get visualizerPresetTrackMap => 'ścieżka mapy';
	@override String get noLyrics => 'Brak tekstu utworu';
	@override String get sleepTimer => 'Wyłącznik czasowy';
	@override String get sleepTimerEndOfTrack => 'Koniec utworu';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuta',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minut',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty',
	);
	@override String get stopPlayback => 'Zatrzymaj odtwarzanie';
	@override String get previousTrack => 'Poprzedni utwór';
	@override String get nextTrack => 'Następny utwór';
	@override String get repeat => 'Powtarzaj';
	@override String get repeatAll => 'Powtarzaj wszystko';
	@override String get repeatOne => 'Powtarzaj jeden';
	@override String get instantMixNoServer => 'Brak dostępnego serwera dla szybkiego miksu';
	@override String get instantMixFailed => 'Nie udało się wczytać miksu błyskawicznego';
	@override String get instantMixEmpty => 'Miks błyskawiczny nie zwrócił żadnych utworów';
	@override String noAudioUrl({required Object track}) => 'Brak dostępnego adresu URL audio dla utworu ${track}';
	@override late final _Translations$music$discography$pl discography = _Translations$music$discography$pl._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$pl extends Translations$watchTogether$en {
	_Translations$watchTogether$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oglądaj razem';
	@override String get description => 'Oglądaj treści wspólnie z rodziną i znajomymi dzięki synchronizacji odtwarzania';
	@override String get createRoom => 'Utwórz pokój';
	@override String get creatingRoom => 'Tworzenie pokoju...';
	@override String get joinRoom => 'Dołącz do pokoju';
	@override String get joiningRoom => 'Dołączanie do pokoju...';
	@override String get connecting => 'Łączenie...';
	@override String get relayPublic => 'Pokoje korzystają z publicznych serwerów pośredniczących Open Watch Party.';
	@override String relayCustom({required Object url}) => 'Pokoje korzystają z Twojego serwera pośredniczącego: ${url}.';
	@override String get recentRooms => 'Ostatnie pokoje';
	@override String get roomActions => 'Akcje pokoju';
	@override String get renameRoom => 'Zmień nazwę pokoju';
	@override String get removeRoom => 'Usuń';
	@override String get enterRoomCode => 'Wpisz 6-znakowy kod otrzymany od gospodarza.';
	@override String get roomCode => 'Kod pokoju';
	@override String get paste => 'Wklej';
	@override String get noCodeInClipboard => 'Schowek nie zawiera kodu pokoju';
	@override String get copyCode => 'Kopiuj kod';
	@override String get codeCopied => 'Skopiowano kod pokoju';
	@override String get shareInvite => 'Udostępnij zaproszenie';
	@override String get inviteCopied => 'Skopiowano zaproszenie. Wklej je do wiadomości.';
	@override String inviteMessage({required Object code}) => 'Dołącz do mojego pokoju „Oglądaj razem” w PlezyNG: otwórz „Oglądaj razem”, wybierz „Dołącz do pokoju” i wpisz kod ${code}.';
	@override String get openSessionControls => 'Otwórz sterowanie sesją „Oglądaj razem”';
	@override String get reconnecting => 'Ponowne łączenie...';
	@override String get reconnectingDescription => 'Połączenie zostało przerwane. Ponowne dołączenie do pokoju nastąpi automatycznie.';
	@override String get connected => 'Połączono';
	@override String get disconnected => 'Rozłączono';
	@override String get youAreHost => 'Jesteś gospodarzem';
	@override String hostedBy({required Object name}) => 'Gospodarz: ${name}';
	@override String get hostControlsPlayback => 'Gospodarz steruje odtwarzaniem';
	@override String get anyoneCanControl => 'Każdy może sterować odtwarzaniem';
	@override String get roomLocked => 'Pokój zablokowany';
	@override String get nowPlaying => 'Teraz odtwarzane';
	@override String get nothingPlaying => 'Nic nie jest odtwarzane';
	@override String get nothingPlayingHost => 'Odtwórz coś z dowolnej biblioteki, aby udostępnić to w pokoju.';
	@override String get nothingPlayingGuest => 'Gdy gospodarz coś włączy, pojawi się to tutaj.';
	@override String get notShareable => 'To wideo nie ma odpowiednika w katalogu, więc mogą je odtworzyć tylko osoby z dostępem do tego samego serwera.';
	@override String get searching => 'Szukanie tego wideo w Twoich bibliotekach...';
	@override String get yourCopy => 'Twoja kopia';
	@override String get sharingYourCopy => 'Udostępniasz swoją kopię';
	@override String playingOtherLength({required Object difference}) => 'Odtwarzanie Twojej kopii · ${difference}';
	@override String get mismatchTitle => 'Twoja kopia ma inną długość';
	@override String mismatchDescription({required Object difference}) => 'Twoja najbliższa kopia jest ${difference} od wideo w pokoju. Może to być inna wersja montażowa lub inne wydanie.';
	@override String get playAnyway => 'Odtwórz mimo to';
	@override String get chooseAnotherCopy => 'Wybierz inną kopię';
	@override String get dontPlay => 'Nie odtwarzaj';
	@override String get unavailableTitle => 'Nie masz tego wideo';
	@override String get unavailableDescription => 'PlezyNG nie znalazło go w Twoich bibliotekach. Wybierz kopię samodzielnie lub wyszukaj ponownie.';
	@override String get chooseCopy => 'Wybierz kopię';
	@override String get searchAgain => 'Szukaj ponownie';
	@override String get noCandidates => 'Nie znaleziono żadnych kopii w Twoich bibliotekach.';
	@override String get choiceFailed => 'Nie udało się odtworzyć tej kopii w pokoju';
	@override String lengthLonger({required Object duration}) => 'o ${duration} dłuższa';
	@override String lengthShorter({required Object duration}) => 'o ${duration} krótsza';
	@override String get lengthSame => 'Ta sama długość';
	@override String get lengthUnknown => 'Nieznana długość';
	@override String get joinCurrentPlayback => 'Dołącz do bieżącego odtwarzania';
	@override String get joinCurrentPlaybackDescription => 'Wróć do treści oglądanej obecnie przez gospodarza';
	@override String get stopMedia => 'Zatrzymaj wideo dla wszystkich';
	@override String get syncOffset => 'Przesunięcie synchronizacji';
	@override String get syncOffsetDescription => 'Przesuń swoje wideo, jeśli wyprzedza odtwarzanie w pokoju lub za nim pozostaje.';
	@override String offsetHint({required Object difference}) => 'Twoja kopia jest ${difference} od wideo w pokoju.';
	@override String applyDifference({required Object offset}) => 'Zastosuj ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Uczestnicy';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestnik',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestnicy',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestników',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestnika',
	);
	@override String get hostBadge => 'GOSPODARZ';
	@override String nameYou({required Object name}) => '${name} (Ty)';
	@override String get playerIdle => 'Bezczynny';
	@override String get playerLoading => 'Ładowanie';
	@override String get playerReady => 'Gotowy';
	@override String get playerBuffering => 'Buforowanie';
	@override String get matchSearching => 'Wyszukiwanie';
	@override String get matchMatched => 'Ma wideo';
	@override String get matchMismatched => 'Inna długość';
	@override String get matchUnavailable => 'Nie ma wideo';
	@override String participantOffset({required Object offset}) => 'Przesunięcie ${offset}';
	@override String get makeHost => 'Uczyń gospodarzem';
	@override String get makeHostQuestion => 'Przekazać rolę gospodarza?';
	@override String makeHostConfirm({required Object name}) => '${name} będzie sterować odtwarzaniem i prowadzić sesję dla wszystkich.';
	@override String get transfer => 'Przekaż';
	@override String get removeParticipant => 'Usuń z pokoju';
	@override String removeParticipantQuestion({required Object name}) => 'Usunąć ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} opuści pokój. Ta osoba może dołączyć ponownie za pomocą kodu, chyba że zablokujesz pokój.';
	@override String get remove => 'Usuń';
	@override String get roomSettings => 'Ustawienia pokoju';
	@override String get letEveryoneControl => 'Pozwól wszystkim sterować odtwarzaniem';
	@override String get lockRoom => 'Zablokuj pokój';
	@override String get lockRoomDescription => 'Nikt nowy nie może dołączyć';
	@override String get leaveRoom => 'Opuść pokój';
	@override String get leaveRoomQuestion => 'Opuścić pokój?';
	@override String get leaveRoomConfirm => 'Możesz dołączyć ponownie, używając kodu pokoju.';
	@override String get leave => 'Opuść';
	@override String get endRoom => 'Zamknij pokój';
	@override String get endRoomQuestion => 'Zamknąć pokój?';
	@override String get endRoomConfirm => 'Pokój zostanie zamknięty dla wszystkich.';
	@override String get end => 'Zakończ';
	@override String get playBlockedTitle => 'Odtwarzanie się nie rozpoczęło';
	@override String get playBlockedDescription => 'Naciśnij Odtwórz, aby oglądać razem z innymi w pokoju.';
	@override late final _Translations$watchTogether$notices$pl notices = _Translations$watchTogether$notices$pl._(_root);
	@override late final _Translations$watchTogether$ended$pl ended = _Translations$watchTogether$ended$pl._(_root);
	@override late final _Translations$watchTogether$errors$pl errors = _Translations$watchTogether$errors$pl._(_root);
	@override String untitledEpisode({required Object number}) => 'Odcinek ${number}';
}

// Path: downloads
class _Translations$downloads$pl extends Translations$downloads$en {
	_Translations$downloads$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pobrania';
	@override String get manage => 'Zarządzaj';
	@override String get tvShows => 'Seriale TV';
	@override String get movies => 'Filmy';
	@override String get music => 'Muzyka';
	@override String tracksQueued({required Object count}) => '${count} utworów w kolejce do pobrania';
	@override String get noDownloads => 'Brak pobrań';
	@override String get noDownloadsDescription => 'Pobrane treści pojawią się tutaj do oglądania offline';
	@override String get downloadNow => 'Pobierz';
	@override String get deleteDownload => 'Usuń pobranie';
	@override String get retryDownload => 'Ponów pobieranie';
	@override String get downloadQueued => 'Pobranie w kolejce';
	@override String get downloadResumed => 'Pobieranie wznowione';
	@override String get serverErrorBitrate => 'Błąd serwera: plik może przekraczać zdalny limit bitrate';
	@override String get storageFull => 'Pobieranie zostało zatrzymane, aby chronić wolne miejsce. Zwolnij miejsce lub wybierz inną lokalizację pobierania, a następnie spróbuj ponownie.';
	@override String get storageUnavailable => 'Pobieranie zostało zatrzymane, ponieważ nie można sprawdzić dostępnego miejsca. Sprawdź lokalizację pobierania i spróbuj ponownie.';
	@override String episodesQueued({required Object count}) => '${count} odcinków w kolejce pobierania';
	@override String get downloadDeleted => 'Pobranie usunięte';
	@override String deleteConfirm({required Object title}) => 'Usunąć "${title}" z tego urządzenia?';
	@override String get deleteCollectionDownloads => 'Usuń pobrania';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Usunąć z tego urządzenia wszystkie pobrania z „${title}”?';
	@override String get collectionDownloadsDeleted => 'Pobrania usunięte';
	@override String get cancelledDownloadTitle => 'Anulowane pobieranie';
	@override String get cancelledDownloadMessage => 'To pobieranie zostało anulowane. Co chcesz zrobić?';
	@override String get allEpisodesAlreadyDownloaded => 'Wszystkie odcinki są już pobrane';
	@override String get resumeDownload => 'Wznów pobieranie';
	@override String get cancelledDownload => 'Anulowane pobieranie';
	@override String syncingFile({required Object file, required Object status}) => '${file} (synchronizowanie ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'Pobrano ${file} — kliknij, aby dokończyć';
	@override String get partialDownloadClickToComplete => 'Pobrano częściowo — kliknij, aby dokończyć';
	@override String get deleting => 'Usuwanie...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Usuwanie ${title}... (${current} z ${total})';
	@override String get queuedTooltip => 'W kolejce';
	@override String queuedFilesTooltip({required Object files}) => 'W kolejce: ${files}';
	@override String get downloadingTooltip => 'Pobieranie...';
	@override String downloadingFilesTooltip({required Object files}) => 'Pobieranie ${files}';
	@override String get noDownloadsTree => 'Brak pobrań';
	@override String get pauseAll => 'Wstrzymaj wszystko';
	@override String get resumeAll => 'Wznów wszystko';
	@override String get retryAll => 'Ponów wszystkie';
	@override String get retryFailed => 'Ponów nieudane pobrania';
	@override String get deleteAll => 'Usuń wszystko';
	@override String get selectVersion => 'Wybierz wersję';
	@override String get allEpisodes => 'Wszystkie odcinki';
	@override String get unwatchedOnly => 'Tylko nieobejrzane';
	@override String nextNUnwatched({required Object count}) => 'Następne ${count} nieobejrzanych';
	@override String get customAmount => 'Własna liczba...';
	@override String get customAmountAny => 'Wskaźnik (w każdym z nich)';
	@override String get randomEpisodes => 'Randomowe epizody';
	@override String get includeSpecials => 'Uwzględnij odcinki specjalne';
	@override String get howManyEpisodes => 'Ile odcinków?';
	@override String get invalidEpisodeCount => 'Wprowadź prawidłową liczbę odcinków.';
	@override String get keepSynced => 'Synchronizuj na bieżąco';
	@override String get downloadOnce => 'Pobierz raz';
	@override String keepNUnwatched({required Object count}) => 'Zachowaj ${count} nieobejrzanych';
	@override String get editSyncRule => 'Edytuj regułę synchronizacji';
	@override String get removeSyncRule => 'Usuń regułę synchronizacji';
	@override String removeSyncRuleConfirm({required Object title}) => 'Zatrzymać synchronizację "${title}"? Pobrane odcinki zostaną zachowane.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Zatrzymać synchronizację "${title}"?';
	@override String get deleteSyncRuleDownloads => 'Usuń również powiązane pobrania';
	@override String get deleteSyncRuleDownloadsDescription => 'Pobrania używane przez inną regułę synchronizacji lub profil zostaną zachowane.';
	@override String syncRuleCreated({required Object count}) => 'Reguła synchronizacji utworzona — zachowywanie ${count} nieobejrzanych odcinków';
	@override String get syncRuleUpdated => 'Reguła synchronizacji zaktualizowana';
	@override String get syncRuleRemoved => 'Reguła synchronizacji usunięta';
	@override String get syncRuleAndDownloadsRemoved => 'Usunięto regułę synchronizacji i powiązane pobrania';
	@override String get syncRuleCleanupBusy => 'Reguły synchronizacji są aktualnie aktualizowane. Spróbuj ponownie za chwilę.';
	@override String get syncRuleCleanupUnavailable => 'Nie udało się bezpiecznie zidentyfikować powiązanych pobrań. Połącz się ponownie z serwerem i spróbuj ponownie albo usuń regułę bez usuwania pobrań.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Zsynchronizowano ${count} nowych odcinków dla ${title}';
	@override String get syncNow => 'Synchronizacja teraz';
	@override String get downloadsUpToDate => 'Pobieranie jest aktualne';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync komplet · ${queued} queued, ${removed} usunięte';
	@override String get activeSyncRules => 'Reguły synchronizacji';
	@override String get reviewOrphanFiles => 'Sprawdź pobrania bez wpisu';
	@override String get orphanReviewTitle => 'Sprawdź pobrania bez wpisu';
	@override String get orphanReviewDescription => 'Te oznaczone pliki znajdują się w domyślnych folderach pobierania zarządzanych przez aplikację PlezyNG, ale nie mają pasującego wpisu pobrania ani aktywnego zadania. Sprawdź listę przed ich usunięciem.';
	@override String orphanReviewCount({required Object count, required Object size}) => 'Liczba plików: ${count} · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Usuń pliki: ${count}';
	@override String get orphanCleanupNone => 'Nie znaleziono osieroconych plików do pobrania';
	@override String get orphanCleanupFailed => 'PlezyNG nie może bezpiecznie przeskanować zarządzanego folderu pobierania. Żadne pliki nie zostały usunięte.';
	@override String get orphanCleanupChanged => 'Lista pobrań zmieniła się podczas przeglądania. Sprawdź pliki ponownie przed czyszczeniem.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Usunięto ${count} osieroconych plików · zwolniono ${size}';
	@override String get noSyncRules => 'Brak reguł synchronizacji';
	@override String get manageSyncRule => 'Zarządzaj synchronizacją';
	@override String get editEpisodeCount => 'Liczba odcinków';
	@override String get editSyncFilter => 'Filtr synchronizacji';
	@override String get syncAllItems => 'Synchronizacja wszystkich elementów';
	@override String get syncUnwatchedItems => 'Synchronizacja nieobejrzanych elementów';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Serwer: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Dostępne';
	@override String get syncRuleOffline => 'Brak połączenia';
	@override String get syncRuleSignInRequired => 'Wymagane logowanie';
	@override String get syncRuleAccessDenied => 'Odmowa dostępu';
	@override String get syncRuleNotAvailableForProfile => 'Niedostępne dla bieżącego profilu';
	@override String get syncRuleUnknownServer => 'Nieznany serwer';
	@override String get syncRuleListCreated => 'Utworzono regułę synchronizacji';
	@override late final _Translations$downloads$backgroundWarning$pl backgroundWarning = _Translations$downloads$backgroundWarning$pl._(_root);
	@override String get options => 'Opcje pobrań';
	@override late final _Translations$downloads$groupings$pl groupings = _Translations$downloads$groupings$pl._(_root);
	@override String get unknownLibrary => 'Nieznana biblioteka';
	@override String get unknownShow => 'Nieznany serial';
	@override String get unknownSeason => 'Nieznany sezon';
	@override String get unknownAlbum => 'Nieznany album';
	@override String completedOfTotal({required Object completed, required Object total}) => 'Ukończono ${completed}/${total}';
	@override String storageUsed({required Object size}) => 'Używany magazyn: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobrany plik',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobrane pliki',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobranych plików',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobranych plików',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serial',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriale',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriali',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriali',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmy',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmów',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmów',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albumy',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albumów',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albumów',
	);
	@override String get errorFileNotFound => 'Nie znaleziono pliku (404)';
	@override String get errorDownloadNotAllowed => 'Serwer nie zezwala na pobieranie (403)';
	@override String get errorDownloadFailed => 'Pobieranie nie powiodło się';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Pobieranie nie powiodło się: ${reason}';
	@override String get convertingOnServer => 'Konwersja na serwer...';
	@override String convertingOnServerPercent({required Object percent}) => 'Konwersja na serwer · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Pobieranie nie powiodło się (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Przetwarzanie końcowe nie powiodło się: ${reason}';
	@override String get reasonFileNotSaved => 'nie udało się zapisać pliku na tym urządzeniu';
	@override String get reasonCannotResume => 'nie udało się wznowić częściowego pobierania';
	@override String get reasonDeviceStorageFull => 'na tym urządzeniu zabrakło miejsca';
	@override String get notificationDownloading => 'Pobieranie...';
	@override String get notificationComplete => 'Pobieranie zakończone';
	@override String get notificationPaused => 'Pobieranie wstrzymane';
}

// Path: shaders
class _Translations$shaders$pl extends Translations$shaders$en {
	_Translations$shaders$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shadery';
	@override String get noShaderDescription => 'Bez ulepszenia wideo';
	@override String get nvscalerDescription => 'Skalowanie obrazu NVIDIA dla ostrzejszego wideo';
	@override String get artcnnVariantNeutral => 'Neutralny';
	@override String get artcnnVariantDenoise => 'Odszumianie';
	@override String get artcnnVariantDenoiseSharpen => 'Odszumianie + wyostrzanie';
	@override String get qualityFast => 'Szybki';
	@override String get qualityHQ => 'Wysoka jakość';
	@override String get mode => 'Tryb';
	@override String get importShader => 'Importuj shader';
	@override String get customShaderDescription => 'Niestandardowy shader GLSL';
	@override String get shaderImported => 'Shader zaimportowany';
	@override String get shaderImportFailed => 'Nie udało się zaimportować shadera';
	@override String get deleteShader => 'Usuń shader';
	@override String deleteShaderConfirm({required Object name}) => 'Usunąć "${name}"?';
}

// Path: companionRemote
class _Translations$companionRemote$pl extends Translations$companionRemote$en {
	_Translations$companionRemote$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pilot';
	@override String connectedTo({required Object name}) => 'Połączono z ${name}';
	@override String get unknownDevice => 'Nieznane urządzenie';
	@override late final _Translations$companionRemote$session$pl session = _Translations$companionRemote$session$pl._(_root);
	@override late final _Translations$companionRemote$pairing$pl pairing = _Translations$companionRemote$pairing$pl._(_root);
	@override late final _Translations$companionRemote$remote$pl remote = _Translations$companionRemote$remote$pl._(_root);
	@override late final _Translations$companionRemote$errors$pl errors = _Translations$companionRemote$errors$pl._(_root);
	@override String get closedBeforeAuth => 'Połączenie zostało zamknięte przed uwierzytelnieniem';
}

// Path: videoSettings
class _Translations$videoSettings$pl extends Translations$videoSettings$en {
	_Translations$videoSettings$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Prędkość odtwarzania';
	@override String get normalSpeed => 'Normalna';
	@override String sleepTimerActive({required Object duration}) => 'Aktywny (${duration})';
	@override String get zoom => 'Powiększenie';
	@override String get sleepTimer => 'Wyłącznik czasowy';
	@override String get audioSync => 'Synchronizacja audio';
	@override String get subtitleSync => 'Synchronizacja napisów';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR nie jest tutaj dostępny — ten kompozytor pulpitu lub wyjście wideo nie może go przesyłać.';
	@override String get hdrToneMapping => 'Mapowanie tonów HDR';
	@override String get hdrToneMappingCompositor => 'Kompozytor';
	@override String get hdrToneMappingCompositorDescription => 'Przekazuj metadane HDR źródła bez zmian i pozwól kompozytorowi pulpitu je zmapować.';
	@override String get hdrToneMappingPlayer => 'Odtwarzacz';
	@override String get hdrToneMappingPlayerDescription => 'Mapuj w odtwarzaczu do szczytowej jasności wyświetlacza, a następnie przekaż kompozytorowi informację o wyniku.';
	@override String get hdrToneMappingFailed => 'Nie udało się zmienić mapowania tonów HDR — poprzedni tryb nadal jest aktywny.';
	@override String get audioOutput => 'Wyjście audio';
	@override String get performanceOverlay => 'Nakładka wydajności';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Przestrzenny';
	@override String get audioOutputSpatial => 'Dźwięk przestrzenny';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Audio równowartość';
	@override String get audioEqualizerDescription => 'Dostępne na numerze mpv; aktywny EQ decoduje dźwięk i odłączają pasterz.';
	@override String get audioEqualizerFlat => 'płaski';
	@override String get audioEqualizerActive => 'Własny';
	@override String get audioEqualizerSaveFailed => 'Nie mogła zaoszczędzić ustawień audio równanie.';
	@override String get backgroundVideoAudio => 'Audio wideo';
	@override String get backgroundVideoAudioDescription => 'Utrzymuj odtwarzanie audio wideo, gdy opuszczasz odtwarzacza; obraz jest ukryty, aż wrócisz. Android wykorzystuje powiadomienie o odtwarzaniu mediów.';
	@override String get audioNormalization => 'Normalizacja głośności';
	@override String get audioNormalizationDisablesPassthrough => 'Dekoduje dźwięk do PCM; przekazywanie jest wyłączone, gdy ta opcja jest włączona';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$pl extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get color => 'Kolor';
	@override String get performance => 'Wydajność';
	@override String get buffer => 'Bufor';
	@override String get app => 'Aplikacja';
	@override String get decoder => 'Dekoder';
	@override String get rawDecoder => 'Surowy dekoder';
	@override String get tunneling => 'Tunelowanie';
	@override String get passthrough => 'Przekazywanie';
	@override String get aspect => 'Proporcje';
	@override String get rotation => 'Obrót';
	@override String get dvSource => 'Źródło DV';
	@override String get dvPath => 'Ścieżka DV';
	@override String get dvRouteDecoder => 'Dekoder Dolby Vision';
	@override String get dvRouteDecoderP81 => 'Dekoder Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Warstwa bazowa';
	@override String get dvRouteBaseLayerHdr10 => 'Warstwa bazowa HDR10';
	@override String get dvRouteBaseLayerHlg => 'Warstwa bazowa HLG';
	@override String get dvRouteBaseLayerSdr => 'Warstwa bazowa SDR';
	@override String get dvRouteReshaped => 'Przekształcenie RPU (gpu-next)';
	@override String get p7Conversion => 'Konw. P7';
	@override String get sampleRate => 'Częstotliwość próbkowania';
	@override String get pixelFormat => 'Format pikseli';
	@override String get hwFormat => 'Format HW';
	@override String get matrix => 'Macierz';
	@override String get primaries => 'Barwy podstawowe';
	@override String get transfer => 'Charakterystyka przenoszenia';
	@override String get renderFps => 'FPS renderowania';
	@override String get displayFps => 'FPS ekranu';
	@override String get avSync => 'Synchronizacja A/V';
	@override String get dropped => 'Pominięte';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'Śr. DV RPU';
	@override String get dvSampleAverage => 'Śr. próbki DV';
	@override String get maxLuma => 'Maks. luma';
	@override String get minLuma => 'Min. luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Użyta pamięć podręczna';
	@override String get cacheLimit => 'Limit pamięci podręcznej';
	@override String get speed => 'Szybkość';
	@override String get player => 'Odtwarzacz';
	@override String get playMethod => 'Metoda gry';
	@override String get memory => 'Pamięć';
	@override String get uiFps => 'FPS interfejsu';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android (sprzętowy)';
	@override String get decoderNvidiaHw => 'NVIDIA (sprzętowy)';
	@override String get decoderQualcommHw => 'Qualcomm (sprzętowy)';
	@override String get decoderMediatekHw => 'MediaTek (sprzętowy)';
	@override String get decoderExynosHw => 'Exynos (sprzętowy)';
	@override String get decoderSoftware => 'Programowy';
	@override String get decoderHardware => 'Sprzętowy';
	@override String get tunnelingActive => 'Aktywne';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (niepowodzenia: ${failures})';
}

// Path: externalPlayer
class _Translations$externalPlayer$pl extends Translations$externalPlayer$en {
	_Translations$externalPlayer$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zewnętrzny odtwarzacz';
	@override String get useExternalPlayer => 'Użyj zewnętrznego odtwarzacza';
	@override String get useExternalPlayerDescription => 'Otwieraj wideo w innej aplikacji';
	@override String get selectPlayer => 'Wybierz odtwarzacz';
	@override String get customPlayers => 'Niestandardowe odtwarzacze';
	@override String get systemDefault => 'Domyślny systemowy';
	@override String get addCustomPlayer => 'Dodaj niestandardowy odtwarzacz';
	@override String get playerName => 'Nazwa odtwarzacza';
	@override String get playerNameHint => 'Mój odtwarzacz';
	@override String get playerCommand => 'Polecenie';
	@override String get playerPackage => 'Nazwa pakietu';
	@override String get playerUrlScheme => 'Schemat URL';
	@override String get off => 'Wyłączony';
	@override String get launchFailed => 'Nie udało się otworzyć zewnętrznego odtwarzacza';
	@override String appNotInstalled({required Object name}) => '${name} nie jest zainstalowany';
	@override String get playInExternalPlayer => 'Odtwórz w zewnętrznym odtwarzaczu';
}

// Path: metadataEdit
class _Translations$metadataEdit$pl extends Translations$metadataEdit$en {
	_Translations$metadataEdit$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Edytuj...';
	@override String get screenTitle => 'Edytuj metadane';
	@override String get basicInfo => 'Podstawowe informacje';
	@override String get artwork => 'Grafika';
	@override String get advancedSettings => 'Ustawienia zaawansowane';
	@override String get title => 'Tytuł';
	@override String get sortTitle => 'Tytuł do sortowania';
	@override String get originalTitle => 'Tytuł oryginalny';
	@override String get releaseDate => 'Data premiery';
	@override String get contentRating => 'Klasyfikacja wiekowa';
	@override String get studio => 'Studio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Opis';
	@override String get poster => 'Plakat';
	@override String get background => 'Tło';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Kwadratowy obraz';
	@override String get selectPoster => 'Wybierz plakat';
	@override String get selectBackground => 'Wybierz tło';
	@override String get selectLogo => 'Wybierz logo';
	@override String get selectSquareArt => 'Wybierz kwadratowy obraz';
	@override String get fromUrl => 'Z URL';
	@override String get uploadFile => 'Prześlij plik';
	@override String get enterImageUrl => 'Wprowadź URL obrazu';
	@override String get imageUrl => 'URL obrazu';
	@override String get metadataUpdated => 'Metadane zaktualizowane';
	@override String get metadataUpdateFailed => 'Nie udało się zaktualizować metadanych';
	@override String get artworkUpdated => 'Grafika zaktualizowana';
	@override String get artworkUpdateFailed => 'Nie udało się zaktualizować grafiki';
	@override String get noArtworkAvailable => 'Brak dostępnej grafiki';
	@override String artworkOption({required Object index}) => 'Opcja grafiki ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opcja grafiki ${index}, wybrana';
	@override String get notSet => 'Nie ustawiono';
	@override String get libraryDefault => 'Domyślne dla biblioteki';
	@override String get accountDefault => 'Domyślne dla konta';
	@override String get seriesDefault => 'Domyślne dla serialu';
	@override String get episodeSorting => 'Sortowanie odcinków';
	@override String get oldestFirst => 'Najstarsze najpierw';
	@override String get newestFirst => 'Najnowsze najpierw';
	@override String get keep => 'Zachowaj';
	@override String get allEpisodes => 'Wszystkie odcinki';
	@override String latestEpisodes({required Object count}) => '${count} najnowszych odcinków';
	@override String get latestEpisode => 'Najnowszy odcinek';
	@override String episodesAddedPastDays({required Object count}) => 'Odcinki dodane w ciągu ostatnich ${count} dni';
	@override String get deleteAfterPlaying => 'Usuń odcinki po odtworzeniu';
	@override String get never => 'Nigdy';
	@override String get afterADay => 'Po jednym dniu';
	@override String get afterAWeek => 'Po tygodniu';
	@override String get afterAMonth => 'Po miesiącu';
	@override String get onNextRefresh => 'Przy następnym odświeżeniu';
	@override String get seasons => 'Sezony';
	@override String get show => 'Pokaż';
	@override String get hide => 'Ukryj';
	@override String get episodeOrdering => 'Kolejność odcinków';
	@override String get tmdbAiring => 'The Movie Database (kolejność emisji)';
	@override String get tvdbAiring => 'TheTVDB (kolejność emisji)';
	@override String get tvdbAbsolute => 'TheTVDB (numeracja bezwzględna)';
	@override String get metadataLanguage => 'Język metadanych';
	@override String get useOriginalTitle => 'Użyj oryginalnego tytułu';
	@override String get preferredAudioLanguage => 'Preferowany język audio';
	@override String get preferredSubtitleLanguage => 'Preferowany język napisów';
	@override String get subtitleMode => 'Tryb automatycznego wyboru napisów';
	@override String get manuallySelected => 'Wybrany ręcznie';
	@override String get shownWithForeignAudio => 'Wyświetlane przy dźwięku w obcym języku';
	@override String get alwaysEnabled => 'Zawsze włączone';
	@override String get tags => 'Tagi';
	@override String get addTag => 'Dodaj tag';
	@override String get genre => 'Gatunek';
	@override String get director => 'Reżyser';
	@override String get writer => 'Scenarzysta';
	@override String get producer => 'Producent';
	@override String get country => 'Kraj';
	@override String get collection => 'Kolekcja';
	@override String get label => 'Etykieta';
	@override String get quickTag => 'Szybki tag...';
}

// Path: matchScreen
class _Translations$matchScreen$pl extends Translations$matchScreen$en {
	_Translations$matchScreen$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get match => 'Dopasuj...';
	@override String get fixMatch => 'Popraw dopasowanie...';
	@override String get unmatch => 'Usuń dopasowanie';
	@override String get unmatchConfirm => 'Usunąć to dopasowanie? Plex będzie traktować element jako niedopasowany, dopóki nie zostanie dopasowany ponownie.';
	@override String get unmatchSuccess => 'Dopasowanie usunięte';
	@override String get unmatchFailed => 'Nie udało się usunąć dopasowania';
	@override String get matchApplied => 'Dopasowanie zastosowane';
	@override String get matchFailed => 'Nie udało się zastosować dopasowania';
	@override String get titleHint => 'Tytuł';
	@override String get yearHint => 'Rok';
	@override String get search => 'Szukaj';
	@override String get noMatchesFound => 'Nie znaleziono dopasowań';
}

// Path: serverTasks
class _Translations$serverTasks$pl extends Translations$serverTasks$en {
	_Translations$serverTasks$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zadania serwera';
	@override String get failedToLoad => 'Nie udało się załadować zadań';
	@override String get noTasks => 'Brak uruchomionych zadań';
}

// Path: trakt
class _Translations$trakt$pl extends Translations$trakt$en {
	_Translations$trakt$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Połączono';
	@override String connectedAs({required Object username}) => 'Połączono jako @${username}';
	@override String get disconnectConfirm => 'Rozłączyć konto Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG przestanie wysyłać zdarzenia do serwisu Trakt. Połączenie można przywrócić w dowolnym momencie.';
	@override String get scrobble => 'Śledzenie odtwarzania w czasie rzeczywistym';
	@override String get scrobbleDescription => 'Wysyłaj do serwisu Trakt zdarzenia odtwarzania, wstrzymania i zatrzymania.';
	@override String get watchedSync => 'Synchronizuj stan obejrzenia';
	@override String get watchedSyncDescription => 'Gdy oznaczysz element jako obejrzany w PlezyNG, zostanie on również oznaczony jako obejrzany w serwisie Trakt.';
}

// Path: seerr
class _Translations$seerr$pl extends Translations$seerr$en {
	_Translations$seerr$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Połącz Seerr';
	@override String get serverUrl => 'Adres URL serwera';
	@override String get serverUrlHelper => 'Adres Twojej instancji Seerr';
	@override String get checkServer => 'Kontynuuj';
	@override String get signInWithJellyfin => 'Zaloguj się przez Jellyfin';
	@override String get signInWithEmby => 'Zaloguj się przez Emby';
	@override String get signInWithLocal => 'Użyj konta lokalnego';
	@override String get email => 'E-mail';
	@override String get noSignInMethods => 'Ta instancja Seerr nie oferuje metody logowania obsługiwanej przez PlezyNG.';
	@override String get instance => 'Instancja';
	@override String get disconnectConfirm => 'Odłączyć Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG zapomni tę instancję Seerr. Połącz ponownie w dowolnym momencie.';
	@override String get request => 'Zamów';
	@override String get request4k => 'Zamów w 4K';
	@override String get seasons => 'Sezony';
	@override String get allSeasons => 'Wszystkie sezony';
	@override String get advancedOptions => 'Zaawansowane';
	@override String get destinationServer => 'Serwer docelowy';
	@override String get qualityProfile => 'Profil jakości';
	@override String get rootFolder => 'Folder główny';
	@override String get languageProfile => 'Profil językowy';
	@override String get tags => 'Tagi';
	@override String get noTags => 'Brak tagów';
	@override String defaultOption({required Object name}) => '${name} (domyślny)';
	@override String get animeNote => 'Ten serial jest anime.';
	@override String get requestSubmitted => 'Zamówienie wysłane';
	@override String requestFailed({required Object error}) => 'Zamówienie nie powiodło się: ${error}';
	@override String get requestsLoadFailed => 'Nie udało się wczytać opcji zamówienia';
	@override String get nothingToRequest => 'Wszystko jest już dostępne lub zamówione.';
	@override String get statusAvailable => 'Dostępne';
	@override String get statusPartiallyAvailable => 'Częściowo dostępne';
	@override String get statusRequested => 'Zamówione';
	@override String get statusProcessing => 'Przetwarzanie';
	@override String get statusBlocklisted => 'Na liście blokowanych';
	@override String couldNotReach({required Object url, required Object error}) => 'Nie udało się połączyć z ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Pod adresem ${url} nie ma instancji Seerr (HTTP ${status})';
	@override String get behindAuthProxy => 'Zamiast Seerr odpowiedział uwierzytelniający reverse proxy (SSO lub uwierzytelnianie HTTP). PlezyNG nie może się przez niego zalogować: pozwól, aby ścieżka /api/v1 Seerr omijała proxy dla tej aplikacji, albo użyj adresu, który dociera do Seerr bezpośrednio.';
	@override String get invalidUrl => 'Wprowadź adres serwera, np. https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Ta instancja Seerr nie obsługuje Quick Connect. Wymagany jest Seerr 3.4 lub nowszy.';
	@override String get notInitialized => 'Ta instancja Seerr nie ukończyła konfiguracji początkowej';
	@override String get noPlexTokenForReauth => 'Brak tokenu Plex umożliwiającego ponowne zalogowanie';
	@override String get noStoredCredentials => 'Brak zapisanych danych logowania umożliwiających ponowne zalogowanie';
	@override String get signInRejected => 'Logowanie zostało odrzucone';
	@override String get noSessionCookie => 'Seerr nie utworzył pliku cookie sesji';
	@override String get freshCookieRejected => 'Seerr odrzucił nowy plik cookie sesji';
	@override String get noUserInformation => 'Seerr nie zwrócił informacji o użytkowniku';
	@override String get sessionRejectedAfterReauth => 'Sesja została odrzucona po ponownym zalogowaniu';
	@override String get permissionDenied => 'Seerr odrzucił tę akcję: Twoje konto nie ma już wymaganych uprawnień';
	@override String get permissionRevoked => 'Nie masz już uprawnień, aby to zamówić';
}

// Path: services
class _Translations$services$pl extends Translations$services$en {
	_Translations$services$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Usługi';
	@override String get hubSubtitle => 'Synchronizuj postęp oglądania i zamawiaj nowe tytuły.';
	@override String get integrations => 'Integracje';
	@override String get notConnected => 'Nie połączono';
	@override String connectedAs({required Object username}) => 'Połączono jako @${username}';
	@override String get scrobble => 'Automatycznie śledź postęp';
	@override String get scrobbleDescription => 'Aktualizuj swoją listę po ukończeniu odcinka lub filmu.';
	@override String disconnectConfirm({required Object service}) => 'Odłączyć ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG przestanie aktualizować ${service}. Połącz ponownie w dowolnym momencie.';
	@override String connectFailed({required Object service}) => 'Nie udało się połączyć z ${service}. Spróbuj ponownie.';
	@override late final _Translations$services$names$pl names = _Translations$services$names$pl._(_root);
	@override late final _Translations$services$simklReconnect$pl simklReconnect = _Translations$services$simklReconnect$pl._(_root);
	@override late final _Translations$services$deviceCode$pl deviceCode = _Translations$services$deviceCode$pl._(_root);
	@override late final _Translations$services$oauthProxy$pl oauthProxy = _Translations$services$oauthProxy$pl._(_root);
	@override late final _Translations$services$pendingAuth$pl pendingAuth = _Translations$services$pendingAuth$pl._(_root);
	@override late final _Translations$services$libraryFilter$pl libraryFilter = _Translations$services$libraryFilter$pl._(_root);
}

// Path: addServer
class _Translations$addServer$pl extends Translations$addServer$en {
	_Translations$addServer$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Dodaj serwer ${product}';
	@override String get serverUrls => 'Adresy URL serwera';
	@override String get serverUrlsHelper => 'Można podać wiele adresów URL rozdzielonych przecinkami.';
	@override String get findServer => 'Znajdź serwer';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Szukanie lokalnych serwerów ${product}...';
	@override String localMediaBrowserServers({required Object product}) => 'Lokalne serwery ${product}';
	@override String get username => 'Nazwa użytkownika';
	@override String get password => 'Hasło';
	@override String get signIn => 'Zaloguj się';
	@override String get change => 'Zmień';
	@override String get required => 'Wymagane';
	@override String couldNotReachServer({required Object error}) => 'Nie udało się połączyć z serwerem: ${error}';
	@override String signInFailed({required Object error}) => 'Logowanie nie powiodło się: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect nie powiodło się: ${error}';
	@override String get addPlexTitle => 'Zaloguj się przez Plex';
	@override String get pinExpired => 'PIN wygasł przed zalogowaniem. Spróbuj ponownie.';
	@override String failedToRegisterAccount({required Object error}) => 'Nie udało się zarejestrować konta: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Podaj adres URL serwera ${product}';
	@override String get addConnectionTitle => 'Dodaj połączenie';
	@override String addConnectionTitleScoped({required Object name}) => 'Dodaj do ${name}';
	@override String get signInWithPlexCard => 'Zaloguj się przez Plex';
	@override String get signInWithPlexCardSubtitle => 'Autoryzuj to urządzenie. Serwery udostępnione zostaną dodane.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autoryzuj konto Plex. Użytkownicy Home staną się profilami.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Połącz z ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Podaj adres URL serwera, nazwę użytkownika i hasło.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Zaloguj się do serwera ${product}. Powiązane z ${name}.';
	@override String get borrowFromAnotherProfile => 'Pożycz z innego profilu';
	@override String get borrowFromAnotherProfileSubtitle => 'Użyj połączenia innego profilu. Profile chronione PIN-em wymagają podania PIN-u.';
	@override String get invalidCredentials => 'Nieprawidłowa nazwa użytkownika lub hasło';
	@override String get authResponseNotJson => 'Odpowiedź uwierzytelniania ma nieprawidłowy format JSON';
	@override String get authResponseIncomplete => 'Odpowiedź logowania z serwera była niekompletna';
	@override String get quickConnectRejected => 'Quick Connect został odrzucony przez serwer';
	@override String get quickConnectNotJson => 'Odpowiedź Quick Connect ma nieprawidłowy format JSON';
	@override String get quickConnectMissingFields => 'W odpowiedzi Quick Connect brakuje kodu lub sekretu';
	@override String get quickConnectPollRejected => 'Odpytywanie Quick Connect zostało odrzucone przez serwer';
	@override String get serverTimedOut => 'Serwer nie odpowiedział w wymaganym czasie';
	@override String get responseNotJson => 'Odpowiedź serwera ma nieprawidłowy format JSON';
	@override String responseMissingIdentity({required Object product}) => 'W odpowiedzi brakuje identyfikatora lub nazwy serwera — czy to serwer ${product}?';
	@override String probeFailed({required Object error}) => 'Nie udało się połączyć z serwerem: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Wprowadź co najmniej jeden adres URL serwera ${product}';
	@override String noReachableServer({required Object product}) => 'Nie znaleziono żadnego osiągalnego serwera ${product}';
	@override String urlsPointToDifferentServers({required Object product}) => 'Te adresy URL wskazują różne serwery ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'Ten adres URL nie odpowiada serwerowi ${product}';
	@override String get redirectUnsupported => 'Serwer przekierował do nieobsługiwanego adresu URL';
	@override String redirectDifferentHost({required Object product}) => 'Serwer przekierował do innego hosta. Wprowadź bezpośrednio docelowy adres URL serwera ${product}.';
	@override String get redirectInsecure => 'Serwer przekierował z HTTPS do niezabezpieczonego adresu URL';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Serwer przekierował do nieobsługiwanego adresu URL. Wprowadź bezpośrednio docelowy adres URL serwera ${product}.';
	@override String get directPlexServerUrl => 'Adres URL serwera Plex';
	@override String get directPlexServerUrlHelper => 'Wprowadź lokalny adres IP i port serwera Plex Media Server.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (opcjonalny)';
	@override String get plexTokenHelper => 'Pozostaw wolny, jeśli dostęp bez auth jest dozwolony na tym serwerze.';
	@override String get plexTokenRequired => 'Wymagane jest autentyfikacja. proszę wpisać swój token Plex (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Media Server (w bezpośrednim / lokalnym)';
	@override String get connectDirectPlexCardSubtitle => 'Połączyć bezpośrednio za pomocą lokalnego adresu IP lub adresu URL bez konta plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Połączyć bezpośrednio za pomocą lokalnego adresu IP lub adresu URL. Połączyć do ${name}.';
	@override String get insecureTitle => 'Niezakrytowane połączenie';
	@override String insecureDescription({required Object url}) => '${url} używa HTTP. Inne osoby w sieci mogą odczytać lub zmienić Twoje hasło, tokeny i multimedia. Korzystaj z HTTPS, jeśli jest dostępny. Kontynuuj tylko wtedy, gdy ufasz tej sieci i akceptujesz ryzyko.';
	@override String get allowHttp => 'Pozwolenie HTTP';
	@override String get httpsRequired => 'Użyj HTTPS lub wyraźnie zezwala na nie szyfrowaną łączność.';
}

// Path: watchLink
class _Translations$watchLink$pl extends Translations$watchLink$en {
	_Translations$watchLink$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Nie mogłem dotrzeć do serwera Plex dla tego linku.';
	@override String get notFound => 'Nie mogłem znaleźć tego pokazu lub filmu na serwerach Plex.';
	@override String get ambiguous => 'Ten link odpowiada elementom na więcej niż jednym serwerze. dodać serwer do linku.';
	@override String get plexOnly => 'Linky do oglądania obecnie obsługują tylko serwery Plex.';
	@override String get unsupportedItem => 'Linky do oglądania mogą otwierać tylko pokaz lub film.';
	@override String get menuItem => 'Zobacz link';
	@override String get dialogTitle => 'Zobacz link';
	@override String get dialogShowHint => 'Otwierając ten link odtwarzasz następny odcinek. Dodaj &mode=shuffle do końca, aby odtworzyć pokaz na shuffle.';
	@override String get dialogMovieHint => 'Otwierając ten link, gra film.';
	@override String get copy => 'Kopiowanie';
	@override String get copied => 'Link kopiowany';
}

// Path: homeLayout
class _Translations$homeLayout$pl extends Translations$homeLayout$en {
	_Translations$homeLayout$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Layout';
	@override String get resetToast => 'Home Reset do oryginalnego rozmiaru bohatera Plezy';
	@override String get resetHeroTitle => 'Znowocześnij rozkład bohatera do magazynu Plezy?';
	@override String get resetHeroBody => 'Odwróci ustawienie bohatera każdej kolejki i przywraca pojedynczą banerę rotującą na szczycie Domu, tak jak przed istnieniem kolejek bohatera.';
	@override String get removeRowTitle => 'Odstąpienie domowej kolejki?';
	@override String removeRowBody({required Object title}) => '${title} zostanie usunięte. Tej operacji nie można cofnąć.';
	@override String get sync => 'Synchronizacja';
	@override String get syncAccountTitle => 'Synchronizuj rozkład z Twoim kontem Plex';
	@override String get syncAccountOn => 'Na: urządzenie to dzieli się kolejnością, kolejnością, Hero i Auto-slide z innymi urządzeniami.';
	@override String get syncAccountOff => 'Wyłącz: urządzenie to utrzymuje własny layout.';
	@override String get syncNow => 'Synchronizacja teraz';
	@override String get plexHomeManager => 'Plex Zarządca domowy';
	@override String get managePlexRows => 'Zarządzanie Plex kolejkami w Plezy';
	@override String get managePlexRowsDescription => 'Otwarte do organizowania domowo wybranych kolejek';
	@override String get organizeHomeRows => 'Organizuj domowe rzędy';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} rzędy: poruszanie się, Hero, Auto-slide, usunięcie';
	@override String organizeLibraryRows({required Object library}) => 'Zorganizuj ${library} rzędy';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Kontynuuj oglądanie + ${n} rzędy: ruch, Biblioteka, Dom, Bohater, Auto-slide';
	@override String get renderAsHero => 'Render jako karta bohatera';
	@override String get heroOnlySingleCollection => 'Dostępne tylko wtedy, gdy ta kolejka rozstrzyga się na prawdziwe tytuły jednej kolekcji';
	@override String get hero => 'bohater';
	@override String get autoSlide => 'Auto-Slide';
	@override String get autoSlideDescription => 'Wstępy (PC) i d-pad (TV) zawsze działają i ponownie uruchamiają timer.';
	@override String get autoSlideEditDescription => 'Wyłącz: porusza się tylko wtedy, gdy klikniesz strzałkę (PC) lub naciśnij lewą/prawną stronę na odległej (TV).';
	@override String get enableHeroFirst => 'Zacznij od bohatera';
	@override String get showOnHome => 'Wyświetlanie na ekranie domowym';
	@override String get home => 'Start';
	@override String get removeFromHome => 'Usuwanie z domu';
	@override String get selectRowsFirst => 'Wybierz linie domowe poniżej.';
	@override String plexManagedRows({required Object n}) => '${n} Plex rzędy zarządzane';
	@override String get continueWatching => 'Kontynuuj oglądanie';
	@override String get continueWatchingLibraryDescription => 'Biblioteka w tej kolejce własnej rewizji';
	@override String get continueWatchingHomeDescription => 'Równowaga postępu pokazana na Home';
	@override String get nextUpHomeDescription => 'Następny niewidziany odcinek kolejka pokazana oddzielnie na Home';
	@override String get library => 'Biblioteka';
	@override String get showInRecommended => 'W bibliotece zalecane';
	@override String get customPlexRow => 'Zestawienie Plex';
	@override String get heroNeedsLibrary => 'Przeczytaj bibliotekę najpierw – bohater musi gdzieś pokazać';
	@override String get heroNeedsSurface => 'Przeczytaj bibliotekę lub dom najpierw — Hero potrzebuje gdzieś, aby pokazać';
	@override String get removeHub => 'Usuń Hub';
	@override String get noPlexRows => 'Nr Plex rzędy zarządzane powróciły do tej biblioteki.';
	@override String get openDetails => 'Szczegóły otwarte';
	@override String get heroCards => 'Karta bohatera';
	@override String get tapHeroCard => 'Złapanie karty bohatera';
	@override String get tvPlayFocus => 'Telewizja zdalna: podniesienie przycisku Play';
	@override String get tvPlayFocusDescription => 'D-pad w dół zatrzymuje się na przycisku Play przed przejściem do następnego rzędu.';
	@override String get tvWrap => 'TV Remote: karty bohaterów';
	@override String get tvWrapDescription => 'Na ostatniej karcie wraca do pierwszej. wyłącz się na ostatniej karce. Lewa na pierwszej karcie zawsze wraca do bocznej paska.';
	@override String get castOnHero => 'Zwiastun bohaterów na bannery';
	@override String get castOnHeroDescription => 'Wyświetla wyciąg wzdłuż dolnej części banera bohatera. wyłączony zachowuje tylko tytuł i podsumowanie.';
	@override String get customRows => 'Custom Rows - rzędy';
	@override String get loading => 'Wstęp do lokalizacji domowej...';
	@override String get noCustomRows => 'Nie ma jeszcze kolejek';
	@override String get addRowHint => 'Użyj Dodaj kolejkę domową, aby utworzyć jedną.';
	@override String get addHomeRow => 'Dodaj domowy rzęs';
	@override String get addHomeRowDescription => 'Wybierz kategorię; nowy pasek zostanie automatycznie dodany do Organizator';
	@override String get removeRow => 'Usuń kolejkę';
	@override String get recentlyAdded => 'Ostatnio dodane';
	@override String get recentlyReleased => 'Niedawno wydane';
	@override String get movieCollections => 'Filmowe kolekcje';
	@override String get showCollections => 'Wyświetla kolekcje';
	@override String get rowTitle => 'Tytuł Row';
	@override String get content => 'Zawartość';
	@override String get showThisRowIn => 'Wyświetl tę kolejkę w:';
	@override String get libraryRecommended => 'Biblioteka zalecana';
	@override String get heroCard => 'Karta bohaterów';
	@override String get heroCardDescription => 'Wyświetla się jako jedna karta obrotowa w pełnej szerokości zamiast płyty plakatowej.';
	@override String get heroUnavailableDescription => 'Dostępne tylko wtedy, gdy ta kolejka rozstrzyga się na prawdziwe tytuły jednej kolekcji – z więcej niż jedną kolekcją wybraną nie ma żadnego tytułu do przechodzenia.';
	@override String get librariesSelection => 'Biblioteki (zostaw wszystkie nieprzeglądane do włączenia każdej biblioteki)';
	@override String get librariesMergedDescription => 'Każda biblioteka sprawdzona tutaj jest połączona w tę jedną kolejkę.';
	@override String get movieCollectionsSelection => 'Kolekcje filmów (zostaw wszystkie nieprzeglądane dla każdej wybranej biblioteki)';
	@override String get showCollectionsSelection => 'Wyświetlanie kolekcji (zostaw wszystkie nieprzeglądane dla każdej wybranej biblioteki)';
	@override String get collectionRowsDescription => 'Jeśli dokładnie jedna kolekcja sięga, jej tytuły są wyświetlane bezpośrednio w kolejce. Jeśli więcej niż jedna kolekcja ma miejsce, każda kolekcja jest wyświetlana jako jeden plakat - naciśnij go, aby otworzyć tę kolekcję.';
	@override String get allCollections => 'Wszystkie kolekcje';
	@override String get noRowsHere => 'Nie ma tu jeszcze kolejek.';
	@override String get hideWatchedRows => 'Ukryte przedmioty obserwowane w kolejkach';
	@override String get hideWatchedRowsDescription => 'Pełnie oglądane tytuły opuszczają Dom i biblioteka Zalecane linie.';
	@override String get untitledCollection => 'Kolekcja bez tytułu';
	@override String get moveRowHint => 'Up/Down: przełącz kolejność · Wybierz: oddaj się tutaj · Powrót: odwołanie';
	@override String get organizeRowsHint => 'Wybierz pozycję kolejką (lub trzymaj pozycję Wybierz pozycja): poruszaj · Lewica/Prawica: opcje kolejki · Powrót: wykonane';
	@override String get layoutNavDescription => 'Wybierz linie, biblioteki i kategorie kolekcji';
	@override String get editHomeRow => 'Edit Home Rw';
	@override String get resetHeroButton => 'Odtworzenie rozmiaru bohatera do magazynu Plezy';
	@override String get reorderingUnlocked => 'Odblokowanie odblokowane';
	@override String get reorderingLocked => 'Znowocześnie zamknięte';
	@override String get rowsCanBeDragged => 'Rury można wyciągnąć – naciśnij zamek, aby zapobiec';
	@override String get tapLockToDrag => 'Wciśnij zamek, aby wyciągnąć rzędy';
	@override String customRowLabel({required Object title}) => 'Wskaźnik: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Ukryj';
	@override String get remove => 'Usuń';
	@override String get libraryResumeRow => 'Ta biblioteka jest kolejna';
	@override String get pressAgainToDelete => 'Następny wpisNastępny Następny Nastąpi usunięcie';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'Na';
	@override String get resetHeroButtonDescription => 'Odwróci ustawienie bohatera każdej kolejki i przywraca pojedynczą banerę do góry, tak jak przed kolejkami bohaterów.';
}

// Path: platform
class _Translations$platform$pl extends Translations$platform$en {
	_Translations$platform$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG łączy się z serwerami mediów i urządzeniami odtwarzania w sieci lokalnej.';
	@override String get locationPermission => 'PlezyNG korzysta z dostępu do lokalizacji, gdy iOS wymaga od niego wykrywania sieci lokalnej i połączenia z serwerami mediów.';
	@override String get photoLibraryPermission => 'Wybierz obrazy z biblioteki zdjęć do wykorzystania jako media artwork.';
	@override String get cameraPermission => 'Skanowanie kodów QR do pary Companion Remote.';
}

// Path: fileSources
class _Translations$fileSources$pl extends Translations$fileSources$en {
	_Translations$fileSources$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Archiwum i książki';
	@override String get subtitle => 'Czytaj, słuchaj i obserwuj z własnych plików.';
	@override String get add => 'Dodaj źródło';
	@override String get importFiles => 'Importowane pliki';
	@override String get localFiles => 'Na tym urządzeniu';
	@override String get source => 'Źródło';
	@override String get name => 'Nazwa';
	@override String get endpoint => 'Adres URL serwera';
	@override String get root => 'folder lub prefix';
	@override String get username => 'Nazwa użytkownika';
	@override String get password => 'Hasło';
	@override String get token => 'API token';
	@override String get accessKey => 'Kluczowe identyfikator';
	@override String get secretKey => 'Sekretny klucz do dostępu';
	@override String get sessionToken => 'Sessions token (opcjonalny)';
	@override String get region => 'Region';
	@override String get clientId => 'OAuth ID klienta';
	@override String get clientSecret => 'OAuth klient sekret (tylko Google desktop)';
	@override String get allowHttp => 'Zezwalaj na nieszyfrowane HTTP w zaufanej sieci';
	@override String get connect => 'Połącz';
	@override String get cancel => 'Anuluj';
	@override String get save => 'Zapisz';
	@override String get close => 'Zamknij';
	@override String get removeSource => 'Źródło odłączone';
	@override String get disconnectMessage => 'Pobrane pliki i historia czytania i słuchania pozostaną na tym urządzeniu.';
	@override String get localFolder => 'Wybierz folder';
	@override String get empty => 'Jeszcze nic tu nie ma';
	@override String get emptyHint => 'Dodaj źródło lub importować książkę, audiobook, muzykę lub wideo.';
	@override String get search => 'Znajdź ten folder';
	@override String get searchCached => 'Szukaj uratowanej biblioteki';
	@override String get refresh => 'Odśwież';
	@override String get loadMore => 'Więcej ładowania';
	@override String get offline => 'Dostępne offline';
	@override String get download => 'Trzymaj się offline';
	@override String get removeDownload => 'Usuń kopii offline';
	@override String get continueReading => 'kontynuuj czytanie';
	@override String get continueListening => 'kontynuuj słuchanie';
	@override String get continueWatching => 'kontynuuj obserwację';
	@override String get read => 'Czytaj';
	@override String get listen => 'Słuchaj';
	@override String get play => 'Odtwórz';
	@override String get pause => 'Pauza';
	@override String get stop => 'Zatrzymaj';
	@override String get startOver => 'Zacznij od';
	@override String get finished => 'Zakończono';
	@override String get markFinished => 'Mark kończy się';
	@override String get markUnfinished => 'Mark niekoniec';
	@override String get editions => 'Wydawnictwa i pliki';
	@override String get chapters => 'Rozdziały';
	@override String get bookmarks => 'Bookmark i notatki';
	@override String get bookmark => 'Dodaj Bookmark';
	@override String get highlight => 'Podwyżka';
	@override String get note => 'Uwaga';
	@override String get delete => 'Usuń';
	@override String get export => 'Notatki eksportowe';
	@override String get exported => 'Notatki eksportowane';
	@override String get sync => 'Synchronizacja postępów';
	@override String get synced => 'Progres synchronizowany';
	@override String get conflict => 'Inne urządzenie ma inną pozycję. wybierz, gdzie kontynuować.';
	@override String get useLocal => 'Użyj tego urządzenia';
	@override String get useRemote => 'Użyj innego urządzenia';
	@override String get history => 'Historia pozycji';
	@override String get groupAudio => 'Słuchaj jak audiobook';
	@override String get groupHint => 'Połączyć pliki audio obecnie pobrane w tym folderze. Pobierz wszystkie strony najpierw.';
	@override String get order => 'Archiwum zamówienia';
	@override String get moveUp => 'Move Up';
	@override String get moveDown => 'Przeprowadź się w dół';
	@override String get speed => 'Prędkość Playback';
	@override String get sleep => 'Wyłącznik czasowy';
	@override String get sleepOff => 'Wył.';
	@override String get endChapter => 'Koniec rozdziału';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuta',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minut',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty',
	);
	@override String get skipBack => 'Skok powrotny';
	@override String get skipForward => 'Skok do przodu';
	@override String get smartRewind => 'Smart odwraca się po przerwie';
	@override String get playbackOptions => 'Opcje słuchania';
	@override String remaining({required Object time}) => '${time} pozostałe';
	@override String get contents => 'Zawartość';
	@override String get readerSettings => 'Czytanie ustawień';
	@override String get fontSize => 'rozmiar tekstu';
	@override String get lineHeight => 'Linia przestrzeń';
	@override String get margin => 'Marginy';
	@override String get font => 'Typowy';
	@override String get serif => 'Seryf';
	@override String get sans => 'Bez serialu';
	@override String get mono => 'Monopostowa';
	@override String get columns => 'Kolumny';
	@override String get scroll => 'Skierujmy się vertikalnie';
	@override String get justify => 'uzasadnia tekst';
	@override String get readerTheme => 'Pojawienie się strony';
	@override String get appTheme => 'Podążaj za tematem aplikacji';
	@override String get paper => 'Papier';
	@override String get sepia => 'Sepia';
	@override String get night => 'Noc';
	@override String get readAloud => 'Przeczytaj tę stronę w głośnym';
	@override String get readAlong => 'Czytaj dalej';
	@override String get stopReading => 'Zatrzymaj narrację';
	@override String get searchBook => 'Wyszukiwanie w książce';
	@override String get noMatches => 'Żadnych meczów';
	@override String get previousPage => 'Poprzedni strona';
	@override String get nextPage => 'Następna strona';
	@override String page({required Object number}) => 'Strona ${number}';
	@override String get externalBlocked => 'W czytelniku są wyłączone linki zewnętrzne do książki.';
	@override String get loading => 'Otwarcie...';
	@override String get narrator => 'narrator';
	@override String get audio => 'Audio';
	@override String get video => 'Wideo';
	@override String get ebooks => 'Ebooky';
	@override String get all => 'Wszystkie';
	@override String get downloads => 'offline pliki';
	@override String get confirmDelete => 'Usuń wybraną kopii offline? Twoja pozycja i notatki pozostaną.';
	@override String get errorAuthentication => 'Zarejestruj się ponownie, aby ponownie połączyć ten źródło.';
	@override String get errorPermission => 'Ten źródło nie zezwoliło na dostęp do żądanej pliku.';
	@override String get errorUnavailable => 'Spróbuj ponownie lub otwórz kopię offline.';
	@override String get errorUnsupported => 'Ten format lub połączenie nie jest obsługiwane na tym urządzeniu. zobacz przewodnik do ustawienia źródła.';
	@override String get errorInvalidData => 'Ten plik lub odpowiedź serwera nie może być bezpiecznie odczytany.';
	@override String get errorCancelled => 'Operacja została odwołana.';
	@override String get errorConflict => 'Pozycja zmieniła się w kolejnej sesji. ponownie otwórz element, aby wybrać pozycję.';
	@override String get signIn => 'Zaloguj się';
	@override String get reconnect => 'Połącz ponownie';
	@override String get folderHelp => 'Pozostaw biały, aby rozpocząć od korzenia źródłowego. URL S3 obejmuje bucket.';
	@override String get preferences => 'Preferencje';
	@override String get timePosition => 'Pozycja';
	@override String get audioTrack => 'Audio ścieżka';
	@override String get subtitleTrack => 'Podtytuł Track';
	@override String get none => 'Żadne';
	@override String get fullscreen => 'Pełny ekran';
	@override String get syncLocation => 'folder synchronizacyjny Progress (opcjonalny)';
	@override String get syncLocationHint => 'W skrócie WebDAV dla PlezyNG stany. używa warunkowych pisma; media pozostają niezmienione.';
	@override String get audiobooks => 'Audiobooki';
	@override String get comics => 'komiksy';
	@override String get scan => 'Skanowanie książek i mediów';
	@override String get browserReader => 'Otwarte czytelniki';
	@override String get browserReaderHelp => 'Czytelnik jest otwarty w przeglądarce. pozostaw PlezyNG otwarty, aby zaoszczędzić swoje miejsce i notatki.';
	@override String get on => 'Na';
	@override String get advancedSetup => 'aplikacja rejestracja';
	@override String get microsoftSignIn => 'Zarejestruj się z Microsoft';
	@override String get zoomIn => 'Zoom w';
	@override String get zoomOut => 'Zoom wyjść';
	@override String get fitPage => 'Fit strona';
	@override String get fitWidth => 'Wygodny widok';
	@override String get actualSize => 'Aktualny rozmiar';
	@override String get goToPage => 'Przejdź do strony';
	@override String get goToSection => 'Przejdź do rozdziału';
	@override String pageRange({required Object count}) => 'Wprowadź numer od 1 do ${count}';
	@override String get pageLayout => 'Strona layout';
	@override String get automatic => 'Automatycznie';
	@override String get singlePage => 'pojedyncza strona';
	@override String get twoPages => '2 strony';
	@override String get readingDirection => 'Czytanie kierunku';
	@override String get leftToRight => 'Lewa do prawej';
	@override String get rightToLeft => 'Prawo do opuszczenia';
	@override String get letterSpacing => 'List przestrzeń';
	@override String get wordSpacing => 'Słowo spacing';
	@override String get readerControlsHelp => 'Włącz lub użyj sterowania zoomów, aby powiększyć strony. Wejdź do panelu. Ctrl/ ⁇  + lub − dostosowuje zoom; Ctrl/ ⁇  0 go ponownie ustawia.';
	@override String get imagePage => 'Strona komiksowa';
	@override String get resetReader => 'Recykling preferencji czytania';
	@override String get zoom => 'Powiększenie';
	@override String get useFiles => 'Użyj plików i książek';
	@override String get cancelScan => 'Anuluj skanowanie';
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class _Translations$lending$pl extends Translations$lending$en {
	_Translations$lending$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteki publiczne';
	@override String get add => 'Dodaj bibliotekę';
	@override String get other => 'Inna biblioteka';
	@override String get libraryName => 'Nazwa biblioteki';
	@override String get libraryUrl => 'Biblioteka WEB';
	@override String get libraryUrlHint => 'Użyj katalogu biblioteki lub strony rejestracji.';
	@override String get intro => 'Pożycz z biblioteki, trzymaj książki w pobliżu.';
	@override String get handoff => 'Zarejestruj się, pożycz i czytaj bezpiecznie z własną usługą biblioteki.';
	@override String get openService => 'Otwarta biblioteka';
	@override String get findLibrary => 'Znajdź bibliotekę';
	@override String get search => 'Szukaj książek i autorów';
	@override String get catalogue => 'Katalog';
	@override String get loans => 'pożyczki';
	@override String get holds => 'Trzymaj';
	@override String get signIn => 'Zarejestruj się w swojej bibliotece';
	@override String get waiting => 'Zakoń rejestrację w przeglądarce, a następnie wróć tutaj.';
	@override String get cancel => 'Anuluj';
	@override String get disconnect => 'usunięcie biblioteki';
	@override String get disconnectMessage => 'Usunąć tę bibliotekę z tego profilu? Twoje pożyczki i utrzymuje pobyt z biblioteką.';
	@override String get getBook => 'Zdobądź książkę';
	@override String get checkAvailability => 'Sprawdź dostępność';
	@override String get available => 'Dostępne do pożyczki';
	@override String get unavailable => 'Obecnie niedostępne';
	@override String get borrow => 'pożyczki';
	@override String get placeHold => 'Miejsce trzymaj';
	@override String get returnBook => 'Wróć wcześnie';
	@override String get cancelHold => 'Anuluj hold';
	@override String get confirmBorrow => 'Czy pożyczasz tytuł z biblioteki?';
	@override String get confirmReturn => 'Może trzeba pożyczyć go ponownie, aby kontynuować.';
	@override String get confirmCancelHold => 'Czy można usunąć swój tytuł?';
	@override String get email => 'Utrzymuj powiadomienie e-mail';
	@override String due({required Object date}) => 'Dwa ${date}';
	@override String queue({required Object position}) => 'pozycja ${position} w linii';
	@override String get empty => 'Tutaj jeszcze nie ma tytułów.';
	@override String get openLibraryNote => 'Odkryj katalog Open Library. opcje czytania i pożyczki są wyświetlane na stronie każdego tytułu.';
	@override String get more => 'Więcej ładowania';
	@override String get gateway => 'Biblioteka w serwisie';
	@override String get gatewayHint => 'Dostarczane przez bibliotekę lub administratora PlezyNG.';
	@override String get advanced => 'Integracja biblioteki';
	@override String get loadLibraries => 'Wybierz swoją bibliotekę';
	@override String get expired => 'Pożyczka ta wygasła.';
	@override String get updated => 'Biblioteka aktualizowana';
	@override String get continueService => 'kontynuuj służbę';
	@override String get comingSoon => 'In-app pożyczki · Przyjdzie wkrótce';
	@override String get comingSoonDescription => 'Możesz użyć swojej biblioteki w Libby, podczas gdy kończymy jej połączenie.';
	@override String get suspendHold => 'zawieszenie';
	@override String get resumeHold => 'Podsumowanie trzymaj';
	@override String get suspendMessage => 'Czy Twoje miejsce jest w linii i pozwól następnemu czytelnikowi pożyczyć tę kopię?';
	@override String get resumeMessage => 'Czy powtórz tę pozycję, aby Twoja biblioteka mogła zaoferować Ci następną dostępną kopię?';
	@override String get editEmail => 'Zmiana powiadomienia e-mail';
}

// Path: audiobook
class _Translations$audiobook$pl extends Translations$audiobook$en {
	_Translations$audiobook$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Czytanie i słuchanie Sync';
	@override String get syncHelp => 'Utrzymuj pozycje czytania, pozycje słuchania, stan zakończenia, notatki i notatki na swoich urządzeniach. Wybierz załączony konto magazynowe i użyj tego samego kodu synchronizacji na każdym urządzeniu. Czytanie i słuchanie pozostają oddzielne.';
	@override String get addSyncSource => 'Dodaj Google Drive, OneDrive, Dropbox, WebDAV lub S3 do plików i książek najpierw.';
	@override String get syncDestination => 'Synchronizacja konta';
	@override String get syncFolder => 'Synchronizuj folder lub prefix';
	@override String get syncFolderHelp => 'Użyj oddzielnej istniejącej foldery w źródle WebDAV lub dedykowanej prefiksie S3.';
	@override String get syncCode => 'Kod synchronizacyjny';
	@override String get syncCodeHelp => 'Stwórz kod na pierwszym urządzeniu, a następnie wprowadź ten kod na innych urządzeniach. Zachowaj prywatną kopię: jest to klucz do twojego stanu szyfrowanego.';
	@override String get showCode => 'Pokaż lub ukryj kod synchronizacji';
	@override String get newSyncCode => 'Tworzenie nowego kodu synchronizacyjnego';
	@override String get saveSync => 'Zapisz i synchronizuj';
	@override String get disableSync => 'Wyłącz synchronizację na tym urządzeniu';
	@override String get syncSourceDisconnect => 'Usuwanie tego źródła wyłączy synchronizację czytania i słuchania tutaj. szyfrowane pliki synchronizacji pozostaną w dostawcy.';
	@override String get syncReconnect => 'Odtwarzanie konta magazynowego';
	@override String lastSynced({required Object time}) => 'Ostatnia synchronizacja w ${time}';
	@override String get syncPrivacy => 'Tylko szyfrowane postępy i notatki są przechowywane. pliki audio i ebook, tokeny konta i hasła nie są przesyłane. Google Drive i OneDrive wykorzystuje pamięć aplikacji; Dropbox wykorzystuje Sync PlezyNG. Umożliwiając sync może wymagać dodatkowego dostępu do pisania. Podczas gdy jest włączony, ten cel posiada sync postępów; postęp serwera pozostaje oddzielny. Odłączenie sync zachowuje lokalną historię i stan zdalny.';
	@override String get syncConflicts => 'Wybierz miejsce, w którym powrócić';
	@override String get conflictHelp => 'Zmiany te zostały dokonane niezależnie. wybierz pozycję lub wersję znaku, aby zachować. późniejszy czas lub wyższy odsetek nie automatycznie wygrywa.';
	@override String syncDevice({required Object device}) => 'Urządzenie ${device}';
	@override String get syncUnknownDevice => 'Nieznane urządzenie';
	@override String get deletedBookmark => 'Usunięta księgarnia';
	@override String get finished => 'zakończone';
	@override String readingPosition({required Object percent}) => 'Czytanie · ${percent}%';
	@override String get chapterTimeline => 'Rozdział postęp';
	@override String get bookTimeline => 'Cała książka Progress';
	@override String bookRemaining({required Object time}) => 'Czas pozostający w tej książce: ${time}';
	@override String chapterRemaining({required Object time}) => 'Czas pozostający w tym rozdziale: ${time}';
	@override String get unknownRemaining => 'Całkowity czas dostępny, gdy części są odtwarzane';
	@override String get undoSeek => 'Ostatnie poszukiwania';
	@override String get customSpeed => 'Szybkość odtwarzania';
	@override String get speedHelp => 'Wybierz prędkość od 0,25× do 4×.';
	@override String get apply => 'Aplikuj';
	@override String get customSleep => 'Standardowy czas snu';
	@override String get sleepMinutes => 'minuty (1 – 1440)';
	@override String sleepChapters({required Object count}) => 'Zatrzymaj się po rozdziałach ${count}';
	@override String get extendSleep => 'Dodaj 5 minut';
	@override String sleepRemaining({required Object time}) => 'Czas spania: ${time}';
	@override String get useDefaults => 'Użyj tych sterowników słuchania dla nowych książek';
	@override String get librarySort => 'Rodzaje książek';
	@override String get sortTitle => 'Tytuł';
	@override String get sortAuthor => 'Autorzy';
	@override String get sortNarrator => 'narrator';
	@override String get sortSeries => 'Seria Porządek';
	@override String get sortRecent => 'Niedawno otwarte';
	@override String get statusFilter => 'Status czytania';
	@override String get statusAll => 'Wszystkie książki';
	@override String get statusNew => 'Nie zaczął';
	@override String get statusProgress => 'w postępie';
	@override String get statusFinished => 'zakończone';
	@override String get goToTime => 'Idź do czasu';
	@override String get timeHelp => 'godziny: minuty: sekundy lub minuty: sekundy';
}

// Path: appIcon.names
class _Translations$appIcon$names$pl extends Translations$appIcon$names$en {
	_Translations$appIcon$names$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Północ';
	@override String get ember => 'Żar';
	@override String get paper => 'Papier';
	@override String get oled => 'OLED';
	@override String get line => 'Linia';
	@override String get ocean => 'Ocean';
	@override String get ultraviolet => 'Ultrafiolet';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Zachód słońca';
	@override String get gold => 'Złoto';
	@override String get titanium => 'Tytan';
	@override String get glass => 'Szkło';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Piksel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Naklejka';
	@override String get ticket => 'Bilet';
	@override String get pop => 'Pop';
	@override String get strata => 'Warstwy';
	@override String get facet => 'Szlif';
	@override String get tilde => 'Tylda';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$pl extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

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
class _Translations$common$mediaKind$pl extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Serial';
	@override String get season => 'Sezon';
	@override String get episode => 'Odcinek';
	@override String get artist => 'Wykonawca';
	@override String get album => 'Album';
	@override String get track => 'Utwór';
	@override String get collection => 'Kolekcja';
	@override String get playlist => 'Playlista';
	@override String get clip => 'Klip';
	@override String get photo => 'Zdjęcie';
	@override String get folder => 'Folder';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$pl extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Tło';
	@override String get surface => 'Powierzchnia';
	@override String get outline => 'Kontur';
	@override String get text => 'Tekst';
	@override String get textMuted => 'Tekst drugorzędny';
	@override String get accent => 'Akcent';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$pl extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Tekst na tle';
	@override String get textOnSurface => 'Tekst na powierzchni';
	@override String get textMutedOnBg => 'Tekst drugorzędny na tle';
	@override String get textMutedOnSurface => 'Tekst drugorzędny na powierzchni';
	@override String get accentOnBg => 'Akcent na tle';
	@override String get accentOnSurface => 'Akcent na powierzchni';
	@override String get labelOnAccent => 'Etykieta przycisku na akcencie';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$pl extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Odtwórz/Pauza';
	@override String get volumeUp => 'Głośniej';
	@override String get volumeDown => 'Ciszej';
	@override String seekForward({required Object seconds}) => 'Przewiń do przodu (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Przewiń do tyłu (${seconds}s)';
	@override String get fullscreenToggle => 'Pełny ekran';
	@override String get muteToggle => 'Wyciszenie';
	@override String get subtitleToggle => 'Napisy';
	@override String get audioTrackNext => 'Następna ścieżka audio';
	@override String get subtitleTrackNext => 'Następna ścieżka napisów';
	@override String get chapterNext => 'Następny rozdział';
	@override String get chapterPrevious => 'Poprzedni rozdział';
	@override String get episodeNext => 'Następny odcinek';
	@override String get episodePrevious => 'Poprzedni odcinek';
	@override String get speedIncrease => 'Zwiększ prędkość';
	@override String get speedDecrease => 'Zmniejsz prędkość';
	@override String get speedReset => 'Zresetuj prędkość';
	@override String get zoomIn => 'Powiększ';
	@override String get zoomOut => 'Pomniejsz';
	@override String get zoomReset => 'Zresetuj zoom';
	@override String get subSeekNext => 'Przewiń do następnego napisu';
	@override String get subSeekPrev => 'Przewiń do poprzedniego napisu';
	@override String get subtitleDelayIncrease => 'Opóźnij napisy';
	@override String get subtitleDelayDecrease => 'Przyspiesz napisy';
	@override String get shaderToggle => 'Przełącz shadery';
	@override String get skipMarker => 'Pomiń intro/napisy końcowe';
	@override String get screenshot => 'Zrób zrzut ekranu';
	@override String get framePrevious => 'Poprzedni Frame';
	@override String get frameNext => 'Następny Frame';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$pl extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Wymaga Androida 8.0 lub nowszego';
	@override String get iosVersion => 'Wymaga iOS 15.0 lub nowszego';
	@override String get permissionDisabled => 'Obraz w obrazie jest wyłączony. Włącz go w ustawieniach systemu.';
	@override String get notSupported => 'Urządzenie nie obsługuje trybu obraz w obrazie';
	@override String get voSwitchFailed => 'Nie udało się przełączyć wyjścia wideo dla trybu obraz w obrazie';
	@override String get failed => 'Nie udało się uruchomić trybu obraz w obrazie';
	@override String get prepareFailed => 'Nie udało się przygotować trybu obraz w obrazie';
	@override String unknown({required Object error}) => 'Wystąpił błąd: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$pl extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio i napisy';
	@override String get libraryDisplay => 'Biblioteka';
	@override String get personalMedia => 'Osobiste multimedia';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$pl extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get none => 'Wybór ręczny';
	@override String get noneDescription => 'Nigdy nie włączaj napisów automatycznie.';
	@override String get defaultMode => 'Kieruj się flagami ścieżki';
	@override String get defaultModeDescription => 'Używaj flag domyślna i wymuszona zapisanych na każdej ścieżce napisów.';
	@override String get always => 'Zawsze włączone';
	@override String get alwaysDescription => 'Włączaj ścieżkę napisów w preferowanym języku, gdy tylko istnieje.';
	@override String get onlyForced => 'Tylko wymuszone napisy';
	@override String get onlyForcedDescription => 'Wczytuj tylko ścieżki oznaczone jako wymuszone.';
	@override String get smart => 'Wyświetlane przy dźwięku w obcym języku';
	@override String get smartDescription => 'Włączaj napisy tylko wtedy, gdy dźwięk jest w innym języku.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$pl extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Preferuj napisy bez SDH';
	@override String get preferSdh => 'Preferuj napisy SDH';
	@override String get onlySdh => 'Tylko napisy SDH';
	@override String get onlyNonSdh => 'Tylko napisy bez SDH';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$pl extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Preferuj niewymuszone napisy';
	@override String get preferForced => 'Preferuj wymuszone napisy';
	@override String get onlyForced => 'Tylko wymuszone napisy';
	@override String get onlyNonForced => 'Tylko niewymuszone napisy';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$pl extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nigdy';
	@override String get moviesAndShows => 'Filmy i seriale TV';
	@override String get movies => 'Tylko filmy';
	@override String get shows => 'Tylko seriale TV';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$pl extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Użytkownicy i krytycy';
	@override String get usersOnly => 'Tylko użytkownicy';
	@override String get criticsOnly => 'Tylko krytycy';
	@override String get nobody => 'Ukryte';
}

// Path: discover.findNext
class _Translations$discover$findNext$pl extends Translations$discover$findNext$en {
	_Translations$discover$findNext$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Znajdź Twój następny';
	@override String get open => 'Znajdź Twój następny';
	@override String get anyTime => 'W każdej chwili';
	@override String get timeAvailable => 'Ile czasu masz?';
	@override String get filters => 'Wybierz moment';
	@override String get watch => 'Spójrz';
	@override String get listen => 'Słuchaj';
	@override String get read => 'Czytaj';
	@override String finishable({required Object duration}) => 'Zakończenie w ${duration}';
	@override String aboutDuration({required Object duration}) => 'O ${duration}';
	@override String nextUnit({required Object duration}) => 'Następny rozdział · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} łącznie';
	@override String get timingVaries => 'Czas różni się';
	@override String get notNow => 'Nie teraz';
	@override String get swipeHint => 'Przełącz lub użyj poniższych przycisków';
	@override String get saved => 'Oszczędne picks';
	@override String savedCount({required Object count}) => 'Zastrzeżone punkty · ${count}';
	@override String get undo => 'i w';
	@override String get details => 'Szczegóły';
	@override String get noPicks => 'Nie ma jeszcze wyboru';
	@override String get noPicksHint => 'Połączyć bibliotekę lub dodać źródło mediów, aby rozpocząć.';
	@override String get noMatches => 'Nic nie pasuje do tego momentu';
	@override String get noMatchesHint => 'Spróbuj innego formatu lub daj sobie więcej czasu.';
	@override String get allDone => 'Wszyscy jesteście złapani';
	@override String get allDoneHint => 'Rozpocznij świeżą mieszankę, aby zobaczyć te opcje ponownie.';
	@override String get refresh => 'Znajdź inną mieszankę';
	@override String sourceReason({required Object source}) => 'Od ${source}';
	@override String libraryReason({required Object library}) => 'Od ${library}';
	@override String get ownedReason => 'Z Twojej biblioteki';
	@override String get liveNow => 'Na teraz';
	@override String get watchLive => 'Spójrz na żywo';
	@override String get filterAnything => 'Wszystko';
	@override String get filterWatch => 'Spójrz';
	@override String get filterListen => 'Słuchaj';
	@override String get filterRead => 'Czytaj';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Aplikuj';
	@override String get openFailed => 'Ta opcja nie jest już dostępna. odśwież, aby sprawdzić ponownie.';
	@override String get changeFailed => 'Nie da się tego zmienić, spróbuj jeszcze raz.';
	@override String get savedLimit => 'Zbawione punkty są pełne. usunąć jeden wybór, aby zaoszczędzić drugi.';
}

// Path: discover.person
class _Translations$discover$person$pl extends Translations$discover$person$en {
	_Translations$discover$person$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get born => 'Data urodzenia';
	@override String get died => 'Data śmierci';
	@override String get birthplace => 'Miejsce urodzenia';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (wiek: ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (w wieku ${age} lat)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$pl extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Polecane';
	@override String get browse => 'Przeglądaj';
	@override String get collections => 'Kolekcje';
	@override String get playlists => 'Playlisty';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$pl extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Grupowanie';
	@override String get all => 'Wszystkie';
	@override String get movies => 'Filmy';
	@override String get shows => 'Seriale TV';
	@override String get seasons => 'Sezony';
	@override String get episodes => 'Odcinki';
	@override String get artists => 'Wykonawcy';
	@override String get albums => 'Albumy';
	@override String get tracks => 'Utwory';
	@override String get folders => 'Foldery';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$pl extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Gatunek';
	@override String get year => 'Rok';
	@override String get contentRating => 'Klasyfikacja wiekowa';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Nieobejrzane';
	@override String get unplayed => 'Nieodtworzone';
	@override String get favorites => 'Ulubione';
	@override String get filePath => 'Ścieżka pliku';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$pl extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tytuł';
	@override String get dateAdded => 'Data dodania';
	@override String get releaseDate => 'Data premiery';
	@override String get rating => 'Ocena';
	@override String get communityRating => 'Ocena społeczności';
	@override String get criticRating => 'Ocena krytyków';
	@override String get userRating => 'Ocena użytkownika';
	@override String get datePlayed => 'Data odtworzenia';
	@override String get playCount => 'Liczba odtworzeń';
	@override String get productionYear => 'Rok produkcji';
	@override String get runtime => 'Czas trwania';
	@override String get officialRating => 'Oficjalna klasyfikacja';
	@override String get premiereDate => 'Data premiery';
	@override String get startDate => 'Data rozpoczęcia';
	@override String get airTime => 'Godzina emisji';
	@override String get studio => 'Studio';
	@override String get random => 'Losowo';
	@override String get dateShared => 'Data udostępnienia';
	@override String get latestEpisodeAirDate => 'Data emisji ostatniego odcinka';
	@override String get lastEpisodeDateAdded => 'Data dodania ostatniego odcinka';
	@override String get dateDownloaded => 'Data pobrania';
	@override String get size => 'Rozmiar';
	@override String get library => 'Biblioteka';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$pl extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get include => 'Uwzględnij';
	@override String get exclude => 'Wyklucz';
	@override String get any => 'Dowolne';
	@override String get yes => 'Tak';
	@override String get no => 'Nie';
	@override String not({required Object value}) => 'Bez: ${value}';
	@override String valueCount({required Object count}) => 'Wybrano: ${count}';
	@override String valueCountExcluded({required Object count}) => 'Wykluczono: ${count}';
	@override String get searchValues => 'Szukaj wartości';
	@override String get noValues => 'Brak wartości';
	@override String get matchContains => 'Zawiera';
	@override String get matchNotContains => 'Nie zawiera';
	@override String get matchIs => 'Jest';
	@override String get matchIsNot => 'Nie jest';
	@override String get matchBeginsWith => 'Zaczyna się od';
	@override String get matchEndsWith => 'Kończy się na';
	@override String get textHint => 'Wpisz tekst do dopasowania';
	@override String get from => 'Od';
	@override String get to => 'Do';
	@override String range({required Object from, required Object to}) => '${from}–${to}';
	@override String atLeast({required Object value}) => 'Od ${value}';
	@override String atMost({required Object value}) => 'Do ${value}';
	@override String dateLastDays({required Object count}) => 'Ostatnie ${count} dni';
	@override String get dateLastYear => 'Ostatni rok';
	@override String dateOlderThanDays({required Object count}) => 'Starsze niż ${count} dni';
	@override String get dateOlderThanYear => 'Starsze niż rok';
}

// Path: libraries.selection
class _Translations$libraries$selection$pl extends Translations$libraries$selection$en {
	_Translations$libraries$selection$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Wybierz elementy';
	@override String selectedCount({required Object count}) => 'Wybrano: ${count}';
	@override String get actions => 'Akcje selekcji';
	@override String get confirmDescendants => 'To zmienia wszystkie odcinki w wybranych pokazach i sezonach.';
	@override String get confirmUnwatched => 'To również wyjaśnia postęp odtwarzania dla wybranych elementów.';
	@override String confirmCount({required Object count}) => 'Wybrane elementy: ${count}.';
	@override String completed({required Object count}) => 'Aktualizowane elementy: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Aktualizacja ${succeeded}; nieudane ${failed}. nieudane elementy pozostają wybrane.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$pl extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Zarządzanie eksploracją schodów';
	@override String get manageDescription => 'Wybierz i zorganizuj listy z konta MDBList';
	@override String get description => 'Wybierz publiczne listy filmowe i telewizyjne z konta MDBList. utworzyć lub skopiować listy na MDBList, a następnie odświeżyć.';
	@override String get selected => 'wybrane szkielety';
	@override String get available => 'Dostępne listy kont';
	@override String get noLists => 'Nie ma powrotnych list filmowych lub telewizyjnych. utworzyć lub skopiować listę na MDBList, a następnie odświeżyć.';
	@override String get displayName => 'Nazwa Shelf Display';
	@override String get nameHint => 'Pozostaw biały, aby użyć nazwy listy źródłowej.';
	@override String get add => 'Dodaj Shelf';
	@override String get save => 'Zbawienie łóżek';
	@override String moveUp({required Object title}) => 'Przeprowadź ${title} w górę';
	@override String moveDown({required Object title}) => 'Przeprowadź ${title} w dół';
	@override String get unavailable => 'Ta lista nie jest dostępna. wycofać lub usunąć jej pudełko w ustawieniach.';
	@override String get rateLimited => 'Osiągnięto limit żądań MDBList. Spróbuj ponownie później.';
	@override String get loadFailed => 'Nie można ładować płyt. sprawdź połączenie i odwracać.';
	@override String get saveFailed => 'Nie mogę się doczekać, proszę o zwrot.';
	@override String get accountChanged => 'Zmiana konta lub profilu. ponownie otworzyć te ustawienia.';
	@override String get settingsUnreadable => 'Nie można przeczytać zapisanych półek. Wybierz listy ponownie, aby zastąpić te ustawienia.';
}

// Path: explore.rows
class _Translations$explore$rows$pl extends Translations$explore$rows$en {
	_Translations$explore$rows$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Lista do obejrzenia';
	@override String get recommendedMovies => 'Rekomendowane filmy';
	@override String get recommendedShows => 'Rekomendowane seriale';
	@override String get trendingMovies => 'Filmy na czasie';
	@override String get trendingShows => 'Seriale na czasie';
	@override String get popularMovies => 'Popularne filmy';
	@override String get popularShows => 'Popularne seriale';
	@override String get trendingAnime => 'Anime na czasie';
	@override String get suggestedAnime => 'Sugerowane anime';
	@override String get airingAnime => 'Najpopularniejsze emitowane anime';
	@override String get popularAnime => 'Najpopularniejsze anime';
	@override String get trending => 'Na czasie';
	@override String get upcomingMovies => 'Nadchodzące filmy';
	@override String get upcomingShows => 'Nadchodzące seriale';
}

// Path: explore.status
class _Translations$explore$status$pl extends Translations$explore$status$en {
	_Translations$explore$status$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get airing => 'W emisji';
	@override String get ended => 'Zakończony';
	@override String get canceled => 'Anulowany';
	@override String get upcoming => 'Nadchodzący';
}

// Path: explore.badge
class _Translations$explore$badge$pl extends Translations$explore$badge$en {
	_Translations$explore$badge$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} popularne';
	@override String rankAiring({required Object n}) => '#${n} emitowane';
	@override String rankRated({required Object n}) => '#${n} najwyżej oceniane';
	@override String rankTrending({required Object n}) => '#${n} na czasie';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} w sezonie ${season}';
	@override String watchingNow({required Object n}) => '${n} ogląda teraz';
	@override String get available => 'Dostępne';
	@override String get partiallyAvailable => 'Częściowo dostępne';
	@override String get availableIn4k => 'Dostępne w 4K';
	@override String get requested => 'Zamówiono';
	@override String get pendingApproval => 'Oczekuje na zatwierdzenie';
	@override String get processing => 'Przetwarzanie';
	@override String get declined => 'Odrzucono';
	@override String get requestFailed => 'Żądanie nie powiodło się';
	@override String get requested4k => 'Zamówiono w 4K';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} sezonów';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Odc. ${episode} za ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Następny za ${duration}';
	@override String episodesShort({required Object n}) => '${n} odc.';
	@override String minutesPerEpisode({required Object n}) => '${n} min/odc.';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$pl extends Translations$explore$stats$en {
	_Translations$explore$stats$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} na listach';
	@override String viewersDay({required Object n}) => '${n} obejrzało dziś';
	@override String viewersWeek({required Object n}) => '${n} obejrzało w tym tygodniu';
	@override String viewersMonth({required Object n}) => '${n} obejrzało w tym miesiącu';
	@override String viewersYear({required Object n}) => '${n} obejrzało w tym roku';
	@override String viewersAllTime({required Object n}) => '${n} widzów';
	@override String planning({required Object n}) => '${n} planuje obejrzeć';
	@override String favorited({required Object n}) => '${n} w ulubionych';
	@override String dropRate({required Object percent}) => '${percent} porzuciło';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarz',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarze',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarzy',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarza',
	);
	@override String votes({required Object n}) => '${n} głosów';
	@override String watching({required Object n}) => '${n} ogląda';
	@override String completed({required Object n}) => '${n} ukończyło';
	@override String onHold({required Object n}) => '${n} wstrzymało';
	@override String dropped({required Object n}) => '${n} porzuciło';
}

// Path: explore.season
class _Translations$explore$season$pl extends Translations$explore$season$en {
	_Translations$explore$season$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Zima';
	@override String get spring => 'Wiosna';
	@override String get summer => 'Lato';
	@override String get fall => 'Jesień';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$pl extends Translations$explore$format$en {
	_Translations$explore$format$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'Krótka seria TV';
	@override String get movie => 'Film';
	@override String get special => 'Odcinek specjalny';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Muzyka';
	@override String get other => 'Inne';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$pl extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get original => 'Oryginał';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Powieść';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Gra';
	@override String get webComic => 'Komiks internetowy';
	@override String get musicRelease => 'Muzyka';
	@override String get otherMedia => 'Inne';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$pl extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Aktor';
	@override String get director => 'Reżyser';
	@override String get writer => 'Scenarzysta';
	@override String get producer => 'Producent';
	@override String get creator => 'Twórca';
	@override String get composer => 'Kompozytor';
}

// Path: explore.relation
class _Translations$explore$relation$pl extends Translations$explore$relation$en {
	_Translations$explore$relation$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prequel';
	@override String get sequel => 'Sequel';
	@override String get sideStory => 'Poboczna historia';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Wersja alternatywna';
	@override String get summary => 'Streszczenie';
	@override String get parentStory => 'Historia pierwotna';
	@override String get adaptation => 'Adaptacja';
	@override String get other => 'Powiązane';
}

// Path: explore.detail
class _Translations$explore$detail$pl extends Translations$explore$detail$en {
	_Translations$explore$detail$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Tytuł oryginalny';
	@override String get alsoKnownAs => 'Znany również jako';
	@override String get studios => 'Studia';
	@override String get country => 'Kraj';
	@override String get language => 'Język';
	@override String get released => 'Premiera';
	@override String get physicalRelease => 'Na nośniku';
	@override String get ended => 'Zakończony';
	@override String addedOn({required Object date}) => 'Dodano ${date}';
	@override String get yourRating => 'Twoja ocena';
	@override String get budget => 'Budżet';
	@override String get revenue => 'Box office';
	@override String get contentAdvisory => 'Klasyfikacja wiekowa';
	@override String get tags => 'Tagi';
	@override String get revealSpoilerTags => 'Pokaż tagi zawierające spoilery';
	@override String get links => 'Linki';
	@override String get watchOn => 'Oglądaj na';
	@override String get watchTrailer => 'Obejrzyj zwiastun';
	@override String openOn({required Object site}) => 'Otwórz na ${site}';
	@override String get crew => 'Obsada i ekipa';
	@override String get ratings => 'Oceny';
	@override String get schedule => 'Harmonogram';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkownika',
		few: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkowników',
		many: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkowników',
		other: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkownika',
	);
	@override String recommendedBy({required Object who}) => 'Polecany przez ${who}';
	@override String favoritedBy({required Object who}) => 'Dodany do ulubionych przez ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} jeszcze nie wyemitowano';
	@override String recommendedByPercent({required Object percent}) => 'Polecany przez ${percent} widzów';
	@override String get relatedTitles => 'Powiązane tytuły';
	@override String get background => 'Tło';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$pl extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Zacznij wcześniej (sekundy)';
	@override String get endLate => 'Zakończ później (sekundy)';
	@override String get newOnly => 'Tylko nowe odcinki';
	@override String get anyChannel => 'Nagrywaj na dowolnym kanale';
	@override String get anyTime => 'Nagrywaj o dowolnej porze';
	@override String get skipInLibrary => 'Pomijaj odcinki już obecne w bibliotece';
	@override String get keepUpTo => 'Odcinki do zachowania';
	@override String get keepUpToHint => '0 zachowuje wszystkie odcinki';
}

// Path: music.discography
class _Translations$music$discography$pl extends Translations$music$discography$en {
	_Translations$music$discography$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Single i EP';
	@override String get live => 'Na żywo';
	@override String get compilations => 'Kompilacje';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$pl extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} uruchomił odtwarzanie';
	@override String get playbackStarted => 'Odtwarzanie rozpoczęte';
	@override String paused({required Object name}) => '${name} wstrzymał';
	@override String get playbackPaused => 'Odtwarzanie wstrzymane';
	@override String jumpedTo({required Object name, required Object position}) => '${name} przeskoczył do ${position}';
	@override String roomJumpedTo({required Object position}) => 'Przeskoczono do ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} ustawił prędkość na ${speed}';
	@override String speedChanged({required Object speed}) => 'Prędkość ustawiona na ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} włączył ${title}';
	@override String mediaStarted({required Object title}) => 'Teraz odtwarzane: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} zatrzymał wideo';
	@override String get mediaStopped => 'Wideo zostało zatrzymane';
	@override String waitingFor({required Object name}) => 'Oczekiwanie na ${name}...';
	@override String get waitingForSomeone => 'Oczekiwanie, aż ktoś nadąży...';
	@override String get finished => 'Zakończono';
	@override String hostChangedTo({required Object name}) => '${name} jest teraz gospodarzem';
	@override String get youAreNowHost => 'Jesteś teraz gospodarzem';
	@override String joined({required Object name}) => '${name} dołączył';
	@override String left({required Object name}) => '${name} opuścił';
	@override String get controlRefused => 'Tylko gospodarz może sterować odtwarzaniem';
	@override String get searchFailed => 'Nie udało się przeszukać niektórych serwerów pod kątem wideo z pokoju';
	@override String get playBlocked => 'Naciśnij Odtwórz, aby rozpocząć';
	@override String get shareFailed => 'Nie udało się udostępnić tego wideo w pokoju';
	@override String get downloadNotShared => 'Pobrania nie są udostępniane w pokoju, gdy ich serwer jest offline';
	@override String get openFailed => 'Nie udało się otworzyć wideo z pokoju';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$pl extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Gospodarz zamknął pokój';
	@override String get kicked => 'Usunięto Cię z pokoju';
	@override String get expired => 'Pokój wygasł';
	@override String get replaced => 'Dołączono do tego pokoju z innego urządzenia';
	@override String get lost => 'Utracono połączenie z pokojem';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$pl extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'To nie jest kod pokoju. Kod składa się z 6 liter i cyfr, z pominięciem 0, 1, I, L i O.';
	@override String get roomNotFound => 'Nie ma pokoju o tym kodzie. Mógł już zostać zamknięty.';
	@override String get roomFull => 'Ten pokój jest pełny.';
	@override String get roomLocked => 'Gospodarz zablokował ten pokój.';
	@override String get relayFull => 'Funkcja „Oglądaj razem” jest teraz przeciążona. Spróbuj ponownie później.';
	@override String get unreachable => 'Nie udało się połączyć z serwerem pośredniczącym funkcji „Oglądaj razem”. Sprawdź połączenie.';
	@override String get rateLimited => 'Zbyt wiele prób. Poczekaj chwilę i spróbuj ponownie.';
	@override String get clientBlocked => 'Ta wersja PlezyNG nie może korzystać z serwera pośredniczącego. Zaktualizuj aplikację.';
	@override String get forbidden => 'Tylko gospodarz może to zrobić.';
	@override String get notInRoom => 'Nie jesteś w pokoju.';
	@override String get alreadyInRoom => 'Jesteś już w pokoju.';
	@override String get resumeFailed => 'Nie udało się ponownie dołączyć do pokoju.';
	@override String get unsupported => 'Serwer pośredniczący tego nie obsługuje.';
	@override String get generic => 'Coś poszło nie tak. Spróbuj ponownie.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$pl extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Po opuszczeniu aplikacji pobieranie zostanie zatrzymane';
	@override String get bannerDegraded => 'Pobieranie w tle może być ograniczone';
	@override String get bannerAction => 'Szczegóły';
	@override String get sheetTitle => 'Pobieranie w tle jest zablokowane';
	@override String get sheetTitleDegraded => 'Pobieranie w tle może być ograniczone';
	@override String get sheetIntro => 'Android uniemożliwia PlezyNG niezawodne pobieranie plików w tle.';
	@override String get sheetIntroDegraded => 'Twoje urządzenie ogranicza możliwość pobierania w tle przez PlezyNG.';
	@override String get reasonBackgroundRestricted => 'Działanie PlezyNG w tle jest ograniczone. Ustaw użycie baterii lub działanie w tle na „Bez ograniczeń”.';
	@override String get reasonStandbyRestricted => 'Android umieścił PlezyNG w ograniczonym trybie gotowości. Ustaw użycie baterii na „Bez ograniczeń”.';
	@override String get reasonDownloadChannelBlocked => 'Powiadomienia o pobieraniu są wyłączone, więc postęp i opcje sterowania mogą być niedostępne.';
	@override String get reasonNotificationsDisabled => 'Powiadomienia są wyłączone. W Android 13 lub nowszym są wymagane przy długim pobieraniu w tle.';
	@override String get reasonDataSaver => 'Oszczędzanie danych jest włączone, co blokuje pobieranie w tle przez mobilną transmisję danych. Pobieranie powinno nadal działać przez Wi-Fi.';
	@override String get reasonOemUnknown => 'Pobieranie wielokrotnie przerywało się, gdy PlezyNG działało w tle. Sprawdź ustawienia baterii lub działania w tle dla PlezyNG.';
	@override String get openSettings => 'Otwórz ustawienia';
	@override String get stillNotWorking => 'Pomoc dla Twojego urządzenia';
	@override String get stillNotWorkingDescription => 'Zobacz instrukcje dla swojego urządzenia lub, jeśli problem nadal występuje, wyślij log przez Ustawienia › Pokaż logi.';
	@override String get dialogTitle => 'Pobieranie może się nie zakończyć';
	@override String get dialogDownloadAnyway => 'Pobierz mimo to';
	@override String get dialogFixFirst => 'Najpierw rozwiąż problem';
	@override String get statusTile => 'Pobieranie w tle';
	@override String get statusOk => 'Działanie w tle jest dozwolone';
	@override String get statusBlocked => 'Zablokowane przez ustawienia systemu';
	@override String get statusDegraded => 'Ograniczone przez ustawienia systemu';
	@override String get statusUnknown => 'Jeszcze nie sprawdzono';
	@override String get settingsUnavailable => 'Nie udało się otworzyć ustawień systemowych na tym urządzeniu';
	@override String get linkUnavailable => 'Nie udało się otworzyć dontkillmyapp.com na tym urządzeniu';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$pl extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get library => 'Biblioteka';
	@override String get collections => 'Kolekcje';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$pl extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Uruchamianie serwera zdalnego...';
	@override String get hostAddress => 'Adres hosta';
	@override String get connected => 'Połączono';
	@override String get serverRunning => 'Serwer zdalny aktywny';
	@override String get serverStopped => 'Serwer zdalny zatrzymany';
	@override String get serverRunningDescription => 'Urządzenia mobilne w Twojej sieci mogą łączyć się z tą aplikacją';
	@override String get serverStoppedDescription => 'Uruchom serwer, aby umożliwić połączenie urządzeń mobilnych';
	@override String get usePhoneToControl => 'Użyj urządzenia mobilnego, aby sterować tą aplikacją';
	@override String get startServer => 'Uruchom serwer';
	@override String get stopServer => 'Zatrzymaj serwer';
	@override String get minimize => 'Minimalizuj';
	@override String get manualAddressHint => 'Ręczny adres połączenia:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$pl extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Urządzenia PlezyNG z tym samym kontem Plex pojawią się tutaj';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Łączenie...';
	@override String get searchingForDevices => 'Szukanie urządzeń...';
	@override String get noDevicesFound => 'Nie znaleziono urządzeń w sieci';
	@override String get noDevicesHint => 'Otwórz PlezyNG na komputerze i połącz oba urządzenia z tą samą siecią Wi-Fi';
	@override String get availableDevices => 'Dostępne urządzenia';
	@override String get manualConnection => 'Połączenie ręczne';
	@override String get cryptoInitFailed => 'Nie udało się uruchomić bezpiecznego połączenia. Najpierw zaloguj się do Plex.';
	@override String get validationHostRequired => 'Wprowadź adres hosta';
	@override String get validationHostFormat => 'Format musi być IP:port (np. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Limit czasu połączenia. Użyj tej samej sieci na obu urządzeniach.';
	@override String get sessionNotFound => 'Nie znaleziono urządzenia. Upewnij się, że PlezyNG działa na hoście.';
	@override String get authFailed => 'Uwierzytelnianie nie powiodło się. Oba urządzenia muszą używać tego samego konta Plex.';
	@override String failedToConnect({required Object error}) => 'Nie udało się połączyć: ${error}';
	@override String get codeTitle => 'Kod parowy';
	@override String get codeDescription => 'Wprowadź kod wyświetlany w programie Companion Remote na urządzeniu hostowym. Oba urządzenia muszą używać wersji, która wspiera bezpieczne parowanie.';
	@override String get codeInvalid => 'Wprowadź wszystkie 32 litery i liczby z kodu gospodarza.';
	@override String get updateRequired => 'Aktualizuj oba urządzenia do wersji, która obsługuje bezpieczne parowanie.';
	@override String get hostDescription => 'Wprowadź ten kod raz na każdym zdalnym. utrzymaj go prywatny: daje kontrolę nad tym profilem.';
	@override String get resetCode => 'Odtwarzanie kodu parowego';
	@override String get resetDescription => 'Wyłącz wszystkie odłączniki i utworz nowy kod. Każdy odłącznik będzie musiał ponownie parować.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$pl extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Czy chcesz się rozłączyć od sesji zdalnej?';
	@override String get reconnecting => 'Ponowne łączenie...';
	@override String attemptOf({required Object current}) => 'Próba ${current} z 5';
	@override String get retryNow => 'Ponów teraz';
	@override String get tabRemote => 'Pilot';
	@override String get tabPlay => 'Odtwórz';
	@override String get tabMore => 'Więcej';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Nawigacja';
	@override String get tabDiscover => 'Odkryj';
	@override String get tabLibraries => 'Biblioteki';
	@override String get tabSearch => 'Szukaj';
	@override String get tabDownloads => 'Pobrania';
	@override String get tabSettings => 'Ustawienia';
	@override String get previous => 'Poprzedni';
	@override String get playPause => 'Odtwórz/wstrzymaj';
	@override String get next => 'Następny';
	@override String get seekBack => 'Przewiń wstecz';
	@override String get stop => 'Zatrzymaj';
	@override String get seekForward => 'Przewiń w przód';
	@override String get volume => 'Głośność';
	@override String get volumeDown => 'Ciszej';
	@override String get volumeUp => 'Głośniej';
	@override String get fullscreen => 'Pełny ekran';
	@override String get subtitles => 'Napisy';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Szukaj na komputerze...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$pl extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Nie znaleziono interfejsu sieciowego';
	@override String get authenticationFailed => 'Uwierzytelnianie nie powiodło się';
	@override String serverStartFailed({required Object error}) => 'Nie udało się uruchomić serwera zdalnego: ${error}';
	@override String commandFailed({required Object error}) => 'Nie udało się wysłać polecenia zdalnego: ${error}';
	@override String get joinTimedOut => 'Upłynął limit czasu dołączania do sesji';
	@override String get failedToConnectAnyAddress => 'Nie udało się połączyć z żadnym adresem';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Połączenie utracone po ${attempts} próbach';
	@override String get connectionLost => 'Połączenie utracone';
}

// Path: services.names
class _Translations$services$names$pl extends Translations$services$names$en {
	_Translations$services$names$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$pl extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Połącz ponownie Simkl';
	@override String get subtitle => 'Simkl wycofuje metodę logowania, z której korzysta to połączenie. Ponowne połączenie otworzy simkl.com, aby zatwierdzić PlezyNG — PlezyNG nigdy nie widzi Twojego hasła. Historia oglądania pozostanie w Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$pl extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktywuj PlezyNG w ${service}';
	@override String get instructions => 'Zeskanuj kod QR albo przejdź pod poniższy adres i wprowadź ten kod:';
	@override String openToActivate({required Object service}) => 'Otwórz ${service}, aby aktywować';
	@override String get copyCode => 'Skopiuj kod aktywacyjny';
	@override String get waitingForAuthorization => 'Oczekiwanie na autoryzację…';
	@override String get codeCopied => 'Kod skopiowany';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$pl extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Zaloguj się do ${service}';
	@override String get body => 'Zeskanuj ten kod QR lub otwórz URL na dowolnym urządzeniu.';
	@override String openToSignIn({required Object service}) => 'Otwórz ${service}, aby się zalogować';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$pl extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Skopiuj adres URL logowania';
	@override String get urlCopied => 'URL skopiowany';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$pl extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtr bibliotek';
	@override String get subtitleAllSyncing => 'Synchronizowanie wszystkich bibliotek';
	@override String get subtitleNoneSyncing => 'Brak synchronizowanych bibliotek';
	@override String subtitleBlocked({required Object count}) => '${count} zablokowanych';
	@override String subtitleAllowed({required Object count}) => '${count} dozwolonych';
	@override String get mode => 'Tryb filtra';
	@override String get modeBlacklist => 'Czarna lista';
	@override String get modeWhitelist => 'Biała lista';
	@override String get modeHintBlacklist => 'Synchronizuj wszystkie biblioteki oprócz zaznaczonych poniżej.';
	@override String get modeHintWhitelist => 'Synchronizuj tylko biblioteki zaznaczone poniżej.';
	@override String get libraries => 'Biblioteki';
	@override String get noLibraries => 'Brak dostępnych bibliotek';
}

/// The flat map containing all translations for locale <pl>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPl {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'cast.chooseDevice' => 'Wskaż na urządzenie',
			'cast.searching' => 'W poszukiwaniu urządzeń do odbioru...',
			'cast.connectedTo' => ({required Object device}) => 'Źródło: ${device}',
			'cast.device' => 'Urządzenie Cast',
			'cast.readyToCast' => 'gotowy do wyrzucenia',
			'cast.subtitle' => 'Napisy',
			'cast.serverNotAvailable' => 'Serwer medialny nie jest dostępny.',
			'cast.stopCasting' => 'Przestań casting',
			'cast.castToDevice' => 'Złóż na urządzenie',
			'cast.noEpisodeAvailable' => 'Nie ma żadnego odcinka do odtwarzania.',
			'cast.startFailed' => 'Nie można zacząć casting. sprawdź serwer i spróbuj ponownie.',
			'automation.noActivePlayback' => 'Nie ma aktywnej sesji wideo do kontroli.',
			'automation.profileNotFound' => 'Ten profil Plezy nie można znaleźć.',
			'notifications.newEpisodeTitle' => 'Nowy epizod',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appIcon.title' => 'Ikona aplikacji',
			'appIcon.defaultIcon' => 'Domyślna',
			'appIcon.current' => 'Bieżąca ikona',
			'appIcon.locked' => 'Wymagany dostęp do życia',
			'appIcon.lockedHint' => 'Rozpocznij 7-dniowy próbny lub odblokuj PlezyNG na całe życie, aby użyć alternatywnych ikon.',
			'appIcon.changeFailed' => 'Nie udało się zmienić ikony aplikacji',
			'appIcon.launcherHint' => 'Nowa ikona pojawi się na ekranie głównym po opuszczeniu PlezyNG.',
			'appIcon.tvLauncherHint' => 'Nowy baner pojawi się po opuszczeniu PlezyNG. Android TV może wyświetlać stary baner, dopóki telewizor nie zostanie uruchomiony ponownie.',
			'appIcon.names.midnight' => 'Północ',
			'appIcon.names.ember' => 'Żar',
			'appIcon.names.paper' => 'Papier',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Linia',
			'appIcon.names.ocean' => 'Ocean',
			'appIcon.names.ultraviolet' => 'Ultrafiolet',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Zachód słońca',
			'appIcon.names.gold' => 'Złoto',
			'appIcon.names.titanium' => 'Tytan',
			'appIcon.names.glass' => 'Szkło',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Piksel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Naklejka',
			'appIcon.names.ticket' => 'Bilet',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Warstwy',
			'appIcon.names.facet' => 'Szlif',
			'appIcon.names.tilde' => 'Tylda',
			'auth.signInWithPlex' => 'Zaloguj się przez Plex',
			'auth.showQRCode' => 'Pokaż kod QR',
			'auth.authenticate' => 'Uwierzytelnij',
			'auth.authenticationTimeout' => 'Upłynął czas uwierzytelniania. Spróbuj ponownie.',
			'auth.scanQRToSignIn' => 'Zeskanuj ten kod QR, aby się zalogować',
			'auth.waitingForAuth' => 'Oczekiwanie na uwierzytelnienie...\nZaloguj się w przeglądarce.',
			'auth.useBrowser' => 'Użyj przeglądarki',
			'auth.or' => 'lub',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Połącz z ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Użyj Quick Connect',
			'auth.quickConnectInstructions' => 'Otwórz Quick Connect w Jellyfin i wpisz ten kod.',
			'auth.quickConnectWaiting' => 'Oczekiwanie na zatwierdzenie…',
			'auth.quickConnectCancel' => 'Anuluj',
			'auth.quickConnectExpired' => 'Quick Connect wygasł. Spróbuj ponownie.',
			'auth.localDataRecoveryRequired' => 'PlezyNG nie mogło bezpiecznie odzyskać lokalnych danych logowania ani oczekujących danych odtwarzania. Zaloguj się ponownie.',
			'auth.pinCheckRejected' => 'Sprawdzenie kodu PIN Plex zostało odrzucone',
			'auth.connectToDirectPlex' => 'Podłącz się do lokalnego serwera Plex',
			'common.cancel' => 'Anuluj',
			'common.save' => 'Zapisz',
			'common.close' => 'Zamknij',
			'common.clear' => 'Wyczyść',
			'common.reset' => 'Resetuj',
			'common.later' => 'Później',
			'common.submit' => 'Wyślij',
			'common.confirm' => 'Potwierdź',
			'common.retry' => 'Ponów',
			'common.logout' => 'Wyloguj',
			'common.unknown' => 'Nieznane',
			'common.refresh' => 'Odśwież',
			'common.yes' => 'Tak',
			'common.no' => 'Nie',
			'common.delete' => 'Usuń',
			'common.edit' => 'Edytuj',
			'common.shuffle' => 'Losowo',
			'common.addTo' => 'Dodaj do...',
			'common.createNew' => 'Utwórz',
			'common.connect' => 'Połącz',
			'common.disconnect' => 'Rozłącz',
			'common.play' => 'Odtwórz',
			'common.pause' => 'Pauza',
			'common.resume' => 'Wznów',
			'common.error' => 'Błąd',
			'common.search' => 'Szukaj',
			'common.home' => 'Start',
			'common.back' => 'Wstecz',
			'common.settings' => 'Ustawienia',
			'common.mute' => 'Wycisz',
			'common.ok' => 'OK',
			'common.off' => 'Wył.',
			'common.options' => 'Opcje',
			'common.seasonNumber' => ({required Object number}) => 'Sezon ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Odcinek ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Rozdział ${number}',
			'common.reconnect' => 'Połącz ponownie',
			'common.viewAll' => 'Pokaż wszystko',
			'common.checkingNetwork' => 'Sprawdzanie sieci...',
			'common.loadingServers' => 'Ładowanie serwerów...',
			'common.connectingToServers' => 'Łączenie z serwerami...',
			'common.startingOfflineMode' => 'Uruchamianie trybu offline...',
			'common.loading' => 'Ładowanie...',
			'common.fullscreen' => 'Pełny ekran',
			'common.exitFullscreen' => 'Wyjdź z pełnego ekranu',
			'common.pressBackAgainToExit' => 'Naciśnij ponownie przycisk Wstecz, aby wyjść',
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
			'common.notAvailable' => 'N/D',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'Serial',
			'common.mediaKind.season' => 'Sezon',
			'common.mediaKind.episode' => 'Odcinek',
			'common.mediaKind.artist' => 'Wykonawca',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Utwór',
			'common.mediaKind.collection' => 'Kolekcja',
			'common.mediaKind.playlist' => 'Playlista',
			'common.mediaKind.clip' => 'Klip',
			'common.mediaKind.photo' => 'Zdjęcie',
			'common.mediaKind.folder' => 'Folder',
			'screens.licenses' => 'Licencje',
			'screens.switchProfile' => 'Zmień profil',
			'screens.subtitleStyling' => 'Styl napisów',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logi',
			'update.available' => 'Dostępna aktualizacja',
			'update.versionAvailable' => ({required Object version}) => 'Dostępna wersja ${version}',
			'update.currentVersion' => ({required Object version}) => 'Bieżąca: ${version}',
			'update.skipVersion' => 'Pomiń tę wersję',
			'update.viewRelease' => 'Zobacz wydanie',
			'update.latestVersion' => 'Masz najnowszą wersję',
			'update.checkFailed' => 'Nie udało się sprawdzić aktualizacji',
			'appAccess.title' => 'Spróbuj każdej funkcji za darmo przez 7 dni',
			'appAccess.description' => 'Rozpocznij siedemdniową próbę z pełnym dostępem do każdej funkcji PlezyNG. nie ma opłaty w trakcie prób i nie ma subskrypcji. po próbie, jeden zakup na całe życie w cenie sklepu otwiera PlezyNG na całe życia.',
			'appAccess.trialEndedDescription' => 'Odblokuj na zawsze wszystkie funkcje PlezyNG jednorazowym zakupem w cenie podanej w sklepie. Bez subskrypcji.',
			'appAccess.startTrial' => 'Rozpocznij moje 7 dni wolnego wyprawy',
			'appAccess.trialActive' => 'Twoja 7-dniowa próba pełnej funkcji jest aktywna.',
			'appAccess.trialEnded' => '7 dni sądu zakończyły się',
			'appAccess.trialStartFailed' => 'Nie mogłem zaoszczędzić próbki na tym urządzeniu. proszę spróbować ponownie.',
			'appAccess.lifetimeTitle' => 'PlezyNG odblokowane na całe życie',
			'appAccess.lifetimeBody' => 'Dzięki! masz dostęp do każdej funkcji PlezyNG przez całe życie.',
			'appAccess.manageTitle' => 'PlezyNG Dostęp do życia',
			'appAccess.manageDescription' => 'Spróbuj każdej funkcji za darmo przez 7 dni, a następnie odblokuj wszystko na całe życie z jednym płatnością w cenie sklepu.',
			'appAccess.buy' => ({required Object price}) => 'Odblokuj wszystkie funkcje dla ${price}',
			'appAccess.loadingPrice' => 'Cena sklepu ładunkowego...',
			'appAccess.retryPrice' => 'Ceny Retry Lookup',
			'appAccess.restore' => 'Przywrócenie zakupów na całe życie',
			'appAccess.pending' => 'Twój zakup czeka na płatność lub zatwierdzenie. dostęp do życia otwiera się, gdy tylko sklep go ukończy.',
			'appAccess.storeUnavailable' => 'Sprawdź, czy jesteś podpisany do sklepu, a zakupy są dozwolone na tym urządzeniu.',
			'appAccess.productNotFound' => 'W tym sklepie nie ma jeszcze odblokowania PlezyNG na całe życie.',
			'appAccess.productQueryFailed' => 'Nie można pobierać ceny sklepu. sprawdź połączenie i spróbuj ponownie.',
			'appAccess.purchaseFailed' => 'Zakup nie przeszedł, spróbuj ponownie.',
			'appAccess.restoreFailed' => 'Nie mogłem dotrzeć do sklepu, aby odzyskać zakup. spróbuj ponownie.',
			'appAccess.nothingToRestore' => 'Nr PlezyNG zakup na całe życie znaleziono na tym koncie sklepu.',
			'settings.title' => 'Ustawienia',
			'settings.supportDeveloper' => 'Wesprzyj PlezyNG',
			'settings.supportDeveloperDescription' => 'Wspomóż rozwój darowizną',
			'settings.lifetimeAccess' => 'PlezyNG Dostęp do życia',
			'settings.language' => 'Język',
			'settings.theme' => 'Motyw',
			'settings.appearance' => 'Wygląd',
			'settings.detailPage' => 'Szczegóły strony',
			'settings.themeSongsEnabled' => 'Zagraj w tematyki piosenki',
			'settings.themeSongsEnabledDescription' => 'Zagraj w dostępne piosenki tematyczne podczas oglądania szczegółów mediów.',
			'settings.themeSongVolume' => 'Temat piosenki Volume',
			'settings.videoPlayback' => 'Odtwarzanie wideo',
			'settings.videoPlaybackDescription' => 'Skonfiguruj zachowanie odtwarzania',
			'settings.advanced' => 'Zaawansowane',
			'settings.episodePosterMode' => 'Styl plakatu odcinka',
			'settings.seriesPoster' => 'Plakat serialu',
			'settings.seasonPoster' => 'Plakat sezonu',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Wyświetl karuzelę wyróżnionych treści na ekranie głównym',
			'settings.secondsLabel' => 'Sekundy',
			'settings.minutesLabel' => 'Minuty',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'min',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Wprowadź czas (${min}-${max})',
			'settings.systemTheme' => 'Systemowy',
			'settings.lightTheme' => 'Jasny',
			'settings.darkTheme' => 'Ciemny',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Żar',
			'settings.glacierTheme' => 'Lodowiec',
			'settings.forestTheme' => 'Las',
			'settings.plumTheme' => 'Śliwka',
			'settings.paperTheme' => 'Papier',
			'settings.libraryDensity' => 'Gęstość biblioteki',
			'settings.displayScale' => 'Skalowanie',
			'settings.compact' => 'Kompaktowy',
			'settings.comfortable' => 'Wygodny',
			'settings.gridSpacing' => 'Odstępy siatki',
			'settings.gridSpacingTight' => 'Ciasny',
			'settings.gridSpacingNormal' => 'Normalny',
			'settings.gridSpacingSpacious' => 'Przestronny',
			'settings.tvCornerSpotlightBackdrop' => 'Tło wyróżnionej pozycji w rogu',
			'settings.tvCornerSpotlightBackdropDescription' => 'Wyświetlaj grafikę wyróżnionej pozycji w prawym górnym rogu zamiast na całym ekranie',
			'settings.viewMode' => 'Tryb widoku',
			'settings.gridView' => 'Siatka',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Pokaż sekcję wyróżnioną',
			'settings.showHomeBackdrop' => 'Home Artykuły Artykuł Artykuła',
			'settings.showHomeBackdropDescription' => 'Wyświetl duże dzieła artystyczne za zawieszonymi rzęsami domowymi',
			'settings.contentScreensaverEnabled' => 'Zawartość ekranu',
			'settings.contentScreensaverEnabledDescription' => 'Wyświetl pełnoprawną sztukę po tym, jak aplikacja była idle',
			'settings.contentScreensaverDelay' => 'Start ekranu po',
			'settings.contentScreensaverLibraries' => 'Biblioteki Screensaver',
			'settings.contentScreensaverLibrariesDescription' => 'Wybierz biblioteki, z których mają pochodzić grafiki wygaszacza ekranu. Jeśli nie wybierzesz żadnej, używane będą grafiki ze wszystkich bibliotek.',
			'settings.contentScreensaverAllLibraries' => 'Wszystkie biblioteki',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} wybrane biblioteki',
			'settings.contentScreensaverNoLibraries' => 'Nie ma dostępnych biblioteek medialnych.',
			'settings.contentScreensaverDismissHint' => 'Naciśnij dowolny przycisk lub naciśnij, aby odwołać',
			'settings.newEpisodeNotifications' => 'Nowe powiadomienia epizodowe',
			'settings.newEpisodeNotificationsDescription' => 'Ostrzeżenie, gdy do pokazu jest dodany nowy odcinek, który jest uwięziony. sprawdź, kiedy jest otwarty Plezy.',
			'settings.continueWatchingRowSize' => 'Spójrz dalej na rozmiar kolejki',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => 'Karty: ${label}',
			'settings.rowSizeCompact' => 'Kompaktowy',
			'settings.rowSizeStandard' => 'Standardowe',
			'settings.rowSizeLarge' => 'Duży',
			'settings.continueWatchingAction' => 'Działanie w sekcji „Kontynuuj oglądanie”',
			'settings.continueWatchingPlay' => 'Odtwórz',
			'settings.continueWatchingDetails' => 'Otwórz szczegóły',
			'settings.episodeAction' => 'Akcja odcinka',
			'settings.episodePlay' => 'Odtwórz',
			'settings.episodeDetails' => 'Otwórz szczegóły',
			'settings.useGlobalHubs' => 'Użyj układu strony głównej',
			'settings.useGlobalHubsDescription' => 'Wyświetlaj ujednolicone sekcje ekranu głównego. W przeciwnym razie używaj rekomendacji bibliotek.',
			'settings.showServerNameOnHubs' => 'Pokaż nazwę serwera w sekcjach',
			'settings.showServerNameOnHubsDescription' => 'Zawsze pokazuj nazwy serwerów w tytułach sekcji.',
			'settings.groupLibrariesByServer' => 'Grupuj biblioteki według serwera',
			'settings.groupLibrariesByServerDescription' => 'Grupuj biblioteki paska bocznego pod każdym serwerem multimediów.',
			'settings.alwaysKeepSidebarOpen' => 'Zawsze utrzymuj panel boczny otwarty',
			'settings.alwaysKeepSidebarOpenDescription' => 'Panel boczny jest rozwinięty, a obszar treści dostosowuje się',
			'settings.showUnwatchedCount' => 'Pokaż liczbę nieobejrzanych',
			'settings.showUnwatchedCountDescription' => 'Wyświetl liczbę nieobejrzanych odcinków w serialach i sezonach',
			'settings.showWatchedIndicators' => 'Pokaż wskaźniki obejrzenia',
			'settings.showWatchedIndicatorsDescription' => 'Wyświetlaj znacznik na obejrzanych filmach, serialach i odcinkach',
			'settings.showEpisodeNumberOnCards' => 'Pokaż numer odcinka na kartach',
			'settings.showEpisodeNumberOnCardsDescription' => 'Pokazuj numer sezonu i odcinka na kartach odcinków',
			'settings.showSeasonPostersOnTabs' => 'Pokaż plakaty sezonów na zakładkach',
			'settings.showSeasonPostersOnTabsDescription' => 'Pokazuj plakat każdego sezonu nad jego zakładką',
			'settings.tvFullCardLayout' => 'Pełne karty TV',
			'settings.tvFullCardLayoutDescription' => 'Używaj kart TV tylko z obrazem i nałożonymi nazwiskami aktorów',
			'settings.focusGlow' => 'Poświata zaznaczenia',
			'settings.focusGlowDescription' => 'Wyświetlaj delikatną poświatę wokół zaznaczonej karty',
			'settings.visualEffects' => 'Efekty wizualne',
			'settings.visualEffectsAuto' => 'Automatycznie',
			'settings.visualEffectsAutoDescription' => 'Automatycznie ograniczaj efekty na urządzeniach o niższej wydajności',
			'settings.visualEffectsFull' => 'Pełne',
			'settings.visualEffectsReduced' => 'Ograniczone',
			'settings.visualEffectsReducedDescription' => 'Mniej animacji i grafiki o niższej rozdzielczości',
			'settings.hideSpoilers' => 'Ukryj spoilery nieobejrzanych odcinków',
			'settings.hideSpoilersDescription' => 'Rozmywaj miniatury i opisy nieobejrzanych odcinków',
			'settings.playerBackend' => 'Mechanizm odtwarzania',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Dekodowanie sprzętowe',
			'settings.hardwareDecodingDescription' => 'Użyj akceleracji sprzętowej, gdy dostępna',
			'settings.playbackBuffer' => 'Bufor odtwarzania',
			'settings.playbackBufferAuto' => 'Auto (zalecane)',
			'settings.playbackBufferLarge' => 'Duży',
			'settings.playbackBufferExtraLarge' => 'Bardzo duży',
			'settings.playbackBufferDescription' => 'Buforuje więcej w przypadku niestabilnych połączeń. Ograniczony również przez rozmiar bufora.',
			'settings.streamBufferSize' => 'rozmiar buffer',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Ile wideo należy przesyłać do przodu podczas odtwarzania bezpośredniego. transkody zatrzymują się na własnym buferze transkodu serwera. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Zastąpić Playback Buffer przy ustawieniu, przechowywany w połowie limitu pamięci aplikacji',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Domyślna jakość',
			'settings.cellularQualityTitle' => 'Domyślna jakość w sieci komórkowej',
			'settings.remoteQualityTitle' => 'Jakość transmisji zdalnej',
			'settings.remoteQualitySameAsDefault' => 'Jakość standardów',
			'settings.cellularQualitySameAsDefault' => 'Taka sama jak domyślna jakość',
			'settings.directPlayCoveredQuality' => 'Odtwarzaj mniejsze wideo w oryginalnej jakości',
			'settings.directPlayCoveredQualityDescription' => 'Odtwarzaj bezpośrednio wideo mieszczące się już w limicie jakości zamiast je transkodować',
			'settings.videoCodecs' => 'Kodeki wideo',
			'settings.videoCodecsDescription' => 'Niezaznaczone kodeki są transkodowane przez serwer',
			'settings.videoCodecsAlwaysAccepted' => 'Zawsze akceptowany',
			'settings.musicQualityTitle' => 'Jakość muzyki',
			'settings.subtitleStyling' => 'Styl napisów',
			'settings.subtitleStylingDescription' => 'Dostosuj wygląd napisów',
			'settings.smallSkipDuration' => 'Krótki skok',
			'settings.largeSkipDuration' => 'Długi skok',
			'settings.rewindOnResume' => 'Przewiń przy wznowieniu',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekunda', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekund', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy', ), 
			'settings.defaultSleepTimer' => 'Domyślny wyłącznik czasowy',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuta', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minut', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty', ), 
			'settings.rememberTrackSelections' => 'Zapamiętuj wybór ścieżek dla każdego serialu i filmu',
			'settings.chooseTracksBeforePlayback' => 'Wybierz audio i podtytuły przed odtwarzaniem',
			'settings.chooseTracksBeforePlaybackDescription' => 'Wybierz źródło audio i podtytuły śladów przed każdym filmem rozpoczyna się.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Zawsze wyświetlać podtytuły na tym urządzeniu',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Jeśli serwer nie ma podtytułu wybranego, wybierz ścieżkę lokalnie.',
			'settings.autoDownloadPreferredSubtitle' => 'FETCH brakuje preferowanych podtytułów językowych',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Wybierz dostępny podtytuł w preferowanym języku lokalnie.Jeśli nie istnieje, poproś serwer o to, aby go pobrał, gdy jest obsługiwany.',
			'settings.rememberTrackSelectionsDescription' => 'Zapamiętuj wybór ścieżki dźwiękowej i napisów dla każdego tytułu',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex zapisuje każdy wybór na serwerze dla danego pliku; Jellyfin dodatkowo włącza opcję „Zapamiętaj wybory” na koncie; Emby nie jest obsługiwany',
			'settings.followServerTrackSelections' => 'Używaj wyboru ścieżek z serwera dla każdego odcinka',
			'settings.followServerTrackSelectionsDescription' => 'Przy zmianie odcinka stosuj ścieżkę dźwiękową i napisy wybrane na serwerze zamiast przenosić bieżący wybór',
			'settings.resumeMusicOnLaunch' => 'Zapamiętaj sesję muzyczną',
			'settings.resumeMusicOnLaunchDescription' => 'Przy uruchomieniu aplikacji otwieraj ostatni utwór wstrzymany w miejscu, w którym przerwano',
			'settings.showChapterMarkersOnTimeline' => 'Pokaż znaczniki rozdziałów na pasku przewijania',
			'settings.showChapterMarkersOnTimelineDescription' => 'Podziel pasek przewijania na granicach rozdziałów',
			'settings.specialsOrdering' => 'Specjale w kolejności odcinków',
			'settings.specialsOrderingDescription' => 'Miejsce odcinków specjalnych w kolejności oglądania serialu',
			'settings.specialsOrderingServer' => 'Zgodnie z kolejnością serwera',
			'settings.specialsOrderingAirDate' => 'Przeplataj według daty emisji',
			'settings.specialsOrderingLast' => 'Po regularnych sezonach',
			'settings.clickVideoTogglesPlayback' => 'Kliknięcie wideo przełącza odtwarzanie/pauzę',
			'settings.clickVideoTogglesPlaybackDescription' => 'Kliknięcie wideo odtwarza/wstrzymuje zamiast pokazywać sterowanie.',
			'settings.videoPlayerControls' => 'Kontrolki odtwarzacza wideo',
			'settings.keyboardShortcuts' => 'Skróty klawiszowe',
			'settings.keyboardShortcutsDescription' => 'Dostosuj skróty klawiszowe',
			'settings.videoPlayerNavigation' => 'Nawigacja odtwarzacza wideo',
			'settings.videoPlayerNavigationDescription' => 'Użyj klawiszy strzałek do nawigacji kontrolkami odtwarzacza',
			'settings.watchTogetherRelay' => 'Serwer pośredniczący funkcji „Oglądaj razem”',
			'settings.watchTogetherRelayDescription' => 'Publiczne serwery pośredniczące Open Watch Party, chyba że ustawisz własny',
			'settings.watchTogetherRelayHint' => 'https://moj-relay.przyklad.pl',
			'settings.watchTogetherRelayInvalid' => 'Wprowadź prawidłowy bazowy adres URL serwera pośredniczącego HTTP lub HTTPS.',
			'settings.crashReporting' => 'Raportowanie błędów',
			'settings.crashReportingDescription' => 'Wysyłaj raporty o błędach, aby pomóc ulepszyć aplikację',
			'settings.debugLogging' => 'Rejestrowanie diagnostyczne',
			'settings.debugLoggingDescription' => 'Włącz szczegółowe rejestrowanie, aby ułatwić rozwiązywanie problemów',
			'settings.viewLogs' => 'Pokaż logi',
			'settings.viewLogsDescription' => 'Pokaż logi aplikacji',
			'settings.clearImageCache' => 'Wyczyść pamięć podręczną obrazów',
			'settings.clearImageCacheDescription' => 'Wyczyść zapisane okładki i miniatury. Obrazy mogą ładować się wolniej, dopóki nie zostaną pobrane ponownie.',
			'settings.clearImageCacheSuccess' => 'Pamięć podręczna obrazów została wyczyszczona',
			'settings.resetSettings' => 'Zresetuj ustawienia',
			'settings.resetSettingsDescription' => 'Przywróć ustawienia domyślne. Tego nie można cofnąć.',
			'settings.resetSettingsSuccess' => 'Przywrócono ustawienia domyślne',
			'settings.backup' => 'Kopia zapasowa',
			'settings.exportSettings' => 'Eksportuj ustawienia',
			'settings.exportSettingsDescription' => 'Zapisz swoje preferencje do pliku',
			'settings.exportSettingsSuccess' => 'Ustawienia wyeksportowane',
			'settings.importSettings' => 'Importuj ustawienia',
			'settings.importSettingsDescription' => 'Przywróć preferencje z pliku',
			'settings.importSettingsConfirm' => 'Bieżące ustawienia zostaną zastąpione. Kontynuować?',
			'settings.importSettingsSuccess' => 'Ustawienia zaimportowane',
			'settings.importSettingsInvalidFile' => 'Ten plik nie jest prawidłowym eksportem PlezyNG',
			'settings.importSettingsNoUser' => 'Zaloguj się przed importem ustawień',
			'settings.cloudBackup' => 'Kopia zapasowa w chmurze',
			'settings.cloudBackupDescription' => 'Backup ustawień przenośnych do punktu końcowego WebDAV powyżej HTTPS. połączenia serwera i uwierzytelnienia pozostają na tym urządzeniu.',
			'settings.cloudBackupUrl' => 'WebDAV JSON plik URL',
			'settings.cloudBackupUsername' => 'Nazwa użytkownika',
			'settings.cloudBackupPassword' => 'Hasło',
			'settings.cloudBackupSaved' => 'Cloud Backup Destination Zbawiony',
			'settings.cloudBackupNow' => 'Wróć do Now',
			'settings.cloudBackupComplete' => 'Ustawienia Backup uploaded',
			'settings.cloudBackupRestore' => 'Odzyskiwanie backup',
			'settings.cloudBackupRestoreConfirm' => 'To zastąpi dopasowane ustawienia przenośne na tym urządzeniu.',
			'settings.cloudBackupRestored' => 'Ustawienia przywróciły się z kopii zapasowej w chmurze',
			'settings.shortcutsReset' => 'Skróty przywrócone do domyślnych',
			'settings.resetShortcutsConfirm' => 'Twoje własne skróty zostaną zastąpione domyślnymi. Kontynuować?',
			'settings.about' => 'O aplikacji',
			'settings.aboutDescription' => 'Informacje o aplikacji i licencje',
			'settings.updates' => 'Aktualizacje',
			'settings.updateAvailable' => 'Dostępna aktualizacja',
			'settings.checkForUpdates' => 'Sprawdź aktualizacje',
			'settings.autoCheckUpdatesOnStartup' => 'Automatycznie sprawdzaj aktualizacje przy uruchomieniu',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Powiadamiaj o dostępnej aktualizacji przy uruchomieniu',
			'settings.validationErrorEnterNumber' => 'Wprowadź prawidłową liczbę',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Czas musi być między ${min} a ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Skrót jest już przypisany do ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Skrót zaktualizowany dla ${action}',
			'settings.saveFailed' => 'Nie udało się zapisać zmian. Spróbuj ponownie.',
			'settings.autoPlayAndSkip' => 'Auto-odtwarzanie i pomijanie',
			'settings.autoPlayNextEpisode' => 'Automatycznie odtwarzaj następny odcinek',
			'settings.autoPlayNextEpisodeDescription' => 'Automatycznie uruchamiaj następny odcinek, gdy bieżący się skończy',
			'settings.shuffleStartsFromBeginning' => 'Odtwarzanie losowe od początku',
			'settings.shuffleStartsFromBeginningDescription' => 'Rozpoczynaj każdy odcinek od początku przy odtwarzaniu losowym zamiast wznawiać',
			'settings.plexCinemaPreRoll' => 'Serwer filmowy Intros',
			'settings.plexCinemaPreRollDescription' => 'Zagraj konfigurowane Plex pre-rolls lub Jellyfin i Emby intros przed rozpoczęciem filmu.',
			'settings.playNextCountdown' => 'Odliczanie do następnego odcinka',
			'settings.playNextCountdownImmediate' => 'Odtwarzaj natychmiast',
			'settings.skipIntroMode' => 'Pomijanie czołówki',
			'settings.skipIntroModeOffDescription' => 'Odtwarzaj czołówki normalnie, bez przycisku pomijania',
			'settings.skipIntroModeButtonDescription' => 'Pokazuj przycisk pomijania, gdy zaczyna się czołówka',
			'settings.skipIntroModeAutoDescription' => 'Pomijaj czołówki automatycznie po opóźnieniu poniżej',
			'settings.skipCreditsMode' => 'Pomijanie napisów końcowych',
			'settings.skipCreditsModeOffDescription' => 'Odtwarzaj napisy końcowe normalnie, bez przycisku pomijania',
			'settings.skipCreditsModeButtonDescription' => 'Pokazuj przycisk pomijania, gdy zaczynają się napisy końcowe',
			'settings.skipCreditsModeAutoDescription' => 'Pomijaj napisy końcowe automatycznie i odtwarzaj następny odcinek',
			'settings.skipAdsMode' => 'Skok reklam',
			'settings.skipAdsModeOffDescription' => 'Odtwarzanie wykrytej reklamy zwykle bez przycisku przesuwania',
			'settings.skipAdsModeButtonDescription' => 'Pokaż przycisk przełączania, gdy Plex wykrywa reklamę',
			'settings.skipAdsModeAutoDescription' => 'Automatycznie przesuwaj wykryte reklamy po opóźnieniu poniżej',
			'settings.musicPlayback' => 'Muzyka Playback',
			'settings.musicSweetFades' => 'Słodkie Fades',
			'settings.musicSweetFadesDescription' => 'Muzyka w ścieżkach ścieżek, gdy Plex ma dane głośności.',
			'settings.skipMarkerModeOff' => 'Wył.',
			'settings.skipMarkerModeButton' => 'Pokaż przycisk',
			'settings.skipMarkerModeAuto' => 'Automatycznie',
			'settings.forceSkipMarkerFallback' => 'Wymuś znaczniki awaryjne',
			'settings.forceSkipMarkerFallbackDescription' => 'Używaj wzorców tytułów rozdziałów, nawet gdy Plex ma znaczniki',
			'settings.theIntroDbFallback' => 'Użyj TheIntroDB jako intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Użyj harmonogramów społeczności tylko wtedy, gdy serwer nie ma znaku wprowadzenia.',
			'settings.autoSkipDelay' => 'Opóźnienie automatycznego pomijania',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Czekaj ${seconds} sekund przed automatycznym pominięciem',
			'settings.introPattern' => 'Wzorzec znacznika intro',
			'settings.introPatternDescription' => 'Wyrażenie regularne do rozpoznawania znaczników intro w tytułach rozdziałów',
			'settings.creditsPattern' => 'Wzorzec znacznika napisów końcowych',
			'settings.creditsPatternDescription' => 'Wyrażenie regularne do rozpoznawania znaczników napisów końcowych w tytułach rozdziałów',
			'settings.prerolls' => 'Filmy wstępne',
			'settings.playPrerollsBeforeMovies' => 'Graj w preroły przed filmami',
			'settings.playPrerollsBeforeMoviesDescription' => 'Odtwarzaj przypadkowy klip z poniższego wyboru przed każdym filmem.',
			'settings.prerollLibrary' => 'Biblioteka Preroll',
			'settings.prerollLibraryNotSet' => 'Nie ustawiono',
			'settings.prerollLibraryNoneFound' => 'Na serwerach nie znaleziono żadnych bibliotek.',
			'settings.prerollSelection' => 'wybrane preroli',
			'settings.prerollSelectionPickLibraryFirst' => 'Najpierw wybierz bibliotekę',
			'settings.prerollSelectionNoneSelected' => 'Nie wybierane prezydencje',
			'settings.prerollSelectionCount' => ({required Object count}) => 'Wybrano: ${count}',
			'settings.prerollItemPicker' => 'Wybierz preroli',
			'settings.prerollItemPickerLoadFailed' => 'Nie mogłam załadować przedmiotów z tej biblioteki.',
			'settings.invalidRegex' => 'Nieprawidłowe wyrażenie regularne',
			'settings.regex' => 'Wyrażenie regularne',
			'settings.downloads' => 'Pobrania',
			'settings.downloadLocationDescription' => 'Wybierz miejsce przechowywania pobranych treści',
			'settings.downloadLocationDefault' => 'Domyślne (pamięć aplikacji)',
			'settings.downloadLocationCustom' => 'Niestandardowa lokalizacja',
			'settings.selectFolder' => 'Wybierz folder',
			'settings.resetToDefault' => 'Przywróć domyślne',
			'settings.currentPath' => ({required Object path}) => 'Bieżąca: ${path}',
			'settings.downloadLocationChanged' => 'Lokalizacja pobierania zmieniona',
			'settings.downloadLocationReset' => 'Lokalizacja pobierania przywrócona do domyślnej',
			'settings.downloadLocationInvalid' => 'Nie można zapisywać w wybranym folderze',
			'settings.downloadLocationPickerUnavailable' => 'Wybór folderu nie jest dostępny na tym urządzeniu',
			'settings.downloadOnWifiOnly' => 'Pobieraj tylko przez Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Blokuj pobieranie na danych komórkowych',
			'settings.autoRemoveWatchedDownloads' => 'Automatycznie usuwaj obejrzane pobrania',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Automatycznie usuwaj obejrzane pobrania',
			'settings.autoDownloadContinueWatching' => 'Auto-Download Kontynuuj oglądanie',
			'settings.autoDownloadContinueWatchingDescription' => 'Utrzymuj elementy na swojej przeglądarce i pobierz je, gdy opuszczą przeglądarkę',
			'settings.downloadQuality' => 'Pobierz jakość',
			'settings.downloadQualityDescription' => 'Plex przygotowuje przekształconą kopię w swojej skrzynce pobierania. Jellyfin i Emby transkody podczas pobierania pliku; przerwane przesyłki mogą być konieczne do ponownego uruchomienia.',
			'settings.askDownloadQualityEachTime' => 'Wybierz jakość dla każdego pobrania',
			'settings.askDownloadQualityEachTimeDescription' => 'Pokaż jakość picera przed przeglądaniem każdego pobrania wideo',
			'settings.cellularDownloadBlocked' => 'Pobieranie przez sieć komórkową jest zablokowane. Użyj Wi-Fi lub zmień ustawienie.',
			'settings.maxVolume' => 'Maksymalna głośność',
			'settings.maxVolumeDescription' => 'Pozwól na wzmocnienie głośności powyżej 100% dla cichych multimediów',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Pokaż, co oglądasz na Discordzie',
			'settings.services' => 'Usługi',
			'settings.servicesDescription' => 'Połącz Trakt, MyAnimeList, Seerr i inne',
			'settings.manageLibrariesDescription' => 'Zmieniaj kolejność i ukrywaj biblioteki',
			'settings.companionRemoteServer' => 'Serwer zdalnego sterowania',
			'settings.companionRemoteServerDescription' => 'Pozwól urządzeniom mobilnym w sieci sterować tą aplikacją',
			'settings.companionRemoteServerStartFailed' => 'Nie udało się uruchomić serwera zdalnego sterowania',
			'settings.companionRemoteServerStopFailed' => 'Nie udało się zatrzymać serwera zdalnego sterowania',
			'settings.autoPip' => 'Automatyczny obraz w obrazie',
			'settings.autoPipDescription' => 'Automatycznie włączaj tryb obrazu w obrazie po opuszczeniu aplikacji podczas odtwarzania',
			'settings.matchContentFrameRate' => 'Dopasuj częstotliwość klatek do treści',
			'settings.matchContentFrameRateDescription' => 'Dopasuj częstotliwość odświeżania ekranu do wideo',
			'settings.matchContentResolution' => 'Dopasuj do rozdzielczości materiału',
			'settings.matchContentResolutionDescription' => 'Przełącza ekran na natywną rozdzielczość wideo, aby skalowaniem zajął się telewizor. Menu i napisy są podczas odtwarzania również skalowane',
			'settings.matchRefreshRate' => 'Dopasuj częstotliwość odświeżania',
			'settings.matchRefreshRateDescription' => 'Dopasuj częstotliwość odświeżania w trybie pełnoekranowym',
			'settings.matchDynamicRange' => 'Dopasuj zakres dynamiki',
			'settings.matchDynamicRangeDescription' => 'Włącz HDR dla treści HDR, potem wróć do SDR',
			'settings.displaySwitchDelay' => 'Opóźnienie przełączania ekranu',
			'settings.tunneledPlayback' => 'Tunelowane odtwarzanie',
			'settings.tunneledPlaybackDescription' => 'Użyj tunelowania wideo. Wyłącz, jeśli HDR pokazuje czarny obraz lub ruch się zacina.',
			'settings.audioPassthrough' => 'Przekazywanie dźwięku',
			'settings.audioPassthroughDescription' => 'Przesyłaj dźwięk Dolby/DTS do amplitunera lub telewizora bez ponownego kodowania, zachowując dźwięk przestrzenny. Wyłącz tę opcję, jeśli nie słychać dźwięku.',
			'settings.audioPassthroughDescriptionApple' => 'Używaj natywnego dekodera Dolby firmy Apple dla Dolby Digital Plus, w tym Atmos. DTS i TrueHD nadal będą odtwarzane jako wielokanałowy dźwięk PCM. Wyłącz tę opcję, jeśli nie słychać dźwięku.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Używaj natywnego dekodera Dolby firmy Apple dla Dolby Digital Plus, w tym Atmos. W systemach iOS, iPadOS i tvOS 26 lub nowszych TrueHD Atmos i DTS:X są odtwarzane jako dźwięk przestrzenny. Pozostałe ścieżki DTS i TrueHD są odtwarzane jako wielokanałowy dźwięk PCM. Wyłącz tę opcję, jeśli nie słychać dźwięku.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Wyłączone, gdy włączona jest normalizacja głośności',
			'settings.audioChannelLimit' => 'Kanały audio',
			'settings.audioChannelLimitDescription' => 'Miksuje zdekodowany dźwięk do mniejszej liczby kanałów dla głośników, słuchawek lub zestawów HDMI, które nie obsługują wszystkich kanałów',
			'settings.audioChannelLimitOriginal' => 'Oryginalne',
			'settings.audioChannelLimitOriginalDescription' => 'Odtwarza wszystkie kanały ścieżki',
			'settings.audioChannelLimitSurround51' => 'Do 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Miksuje 7.1 do 5.1 dla telewizorów i amplitunerów, które przyjmują tylko 5.1 PCM. Nie wpływa na przekazywanie dźwięku.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Miksuje do dwóch kanałów dla głośników stereo lub słuchawek. Wyłącza przekazywanie dźwięku.',
			'settings.downmixCenterBoost' => 'Wzmocnienie kanału centralnego',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Wzmocnienie (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizacja głośności przy miksowaniu',
			'settings.audioDownmixNormalizeDescription' => 'Obniża miks, aby zapobiec przesterowaniu. Wyłącz, aby zachować oryginalną głośność (głośne sceny mogą być zniekształcone).',
			'settings.dvConversionMode' => 'Konwersja Dolby Vision',
			'settings.dvConversionModeDescription' => 'Wybierz, jak mają być obsługiwane pliki Dolby Vision Profile 7.',
			'settings.dvConversionAuto' => 'Automatycznie',
			'settings.dvConversionNative' => 'Natywnie / wyłączone',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Wykrywaj możliwości urządzenia i stosuj standardowy mechanizm awaryjny',
			'settings.dvConversionNativeDescription' => 'Wymuś natywne DV7 i wyłącz ponowną próbę konwersji DV',
			'settings.dvConversionDv81Description' => 'Wymuś wbudowaną konwersję RPU do profilu Dolby Vision 8.1',
			'settings.dvConversionHevcStripDescription' => 'Usuń warstwy Dolby Vision RPU/EL i przedstaw zwykłe HEVC',
			'settings.disableDolbyVision' => 'Wyłącz Dolby Vision',
			_ => null,
		} ?? switch (path) {
			'settings.disableDolbyVisionDescription' => 'Odtwarzaj warstwę HDR10 lub HLG pliku zamiast Dolby Vision, jeśli jest dostępna',
			'settings.hdrSdrConversion' => 'Konwersja HDR do SDR',
			'settings.hdrSdrConversionDescription' => 'Wybierz, co konwertuje wideo HDR, gdy wyświetlacz nie obsługuje HDR.',
			'settings.hdrSdrConversionAuto' => 'Automatycznie',
			'settings.hdrSdrConversionAutoDescription' => 'Urządzenie na Androidzie 9 i nowszym, odtwarzacz na starszych wersjach',
			'settings.hdrSdrConversionDevice' => 'Urządzenie',
			'settings.hdrSdrConversionDeviceDescription' => 'Konwersję wykonuje sprzęt wideo urządzenia. Najszybciej, ale kolory zależą od urządzenia',
			'settings.hdrSdrConversionPlayer' => 'Odtwarzacz',
			'settings.hdrSdrConversionPlayerDescription' => 'Konwersję wykonuje odtwarzacz. Spójne kolory, ale 4K może się zacinać na słabszych przystawkach TV',
			'settings.deinterlace' => 'Usuwanie przeplotu',
			'settings.deinterlaceDescription' => 'Usuwa artefakty grzebienia z wideo z przeplotem (tylko odtwarzacz mpv)',
			'settings.deinterlaceOff' => 'Wył.',
			'settings.deinterlaceOffDescription' => 'Wyświetla wideo z przeplotem w postaci, w jakiej zostało zdekodowane',
			'settings.deinterlaceVideo' => 'Wideo',
			'settings.deinterlaceVideoDescription' => 'Zamienia każdy półobraz w pełną klatkę. Do materiałów nagrywanych dla telewizji, np. sportu, wiadomości i koncertów',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'Przywraca oryginalne klatki filmów i animacji poddanych konwersji telecine do 29,97 kl./s, częstej na płytach DVD w standardzie NTSC. Materiały nagrywane dla telewizji będą się zacinać. TV na żywo używa trybu Wideo',
			'settings.requireProfileSelectionOnOpen' => 'Pytaj o profil przy otwarciu aplikacji',
			'settings.requireProfileSelectionOnOpenDescription' => 'Pokaż wybór profilu za każdym razem, gdy aplikacja jest otwierana',
			'settings.forceTvMode' => 'Wymuś tryb TV',
			'settings.forceTvModeDescription' => 'Wymuś układ telewizyjny na urządzeniach, które nie wykrywają go automatycznie. Wymaga ponownego uruchomienia.',
			'settings.startInFullscreen' => 'Uruchom na pełnym ekranie',
			'settings.startInFullscreenDescription' => 'Otwiera PlezyNG w trybie pełnoekranowym przy uruchomieniu',
			'settings.exitFullscreenOnPlayerClose' => 'Wyjdź z pełnego ekranu przy zamykaniu odtwarzacza',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Automatycznie wychodzi z trybu pełnoekranowego po zamknięciu odtwarzacza wideo',
			'settings.autoHidePerformanceOverlay' => 'Automatycznie ukrywaj nakładkę wydajności',
			'settings.autoHidePerformanceOverlayDescription' => 'Wygaszaj nakładkę wydajności wraz z kontrolkami odtwarzania',
			'settings.showNavBarLabels' => 'Pokaż etykiety paska nawigacji',
			'settings.showNavBarLabelsDescription' => 'Wyświetl tekstowe etykiety pod ikonami paska nawigacji',
			'settings.startupSection' => 'Sekcja startowa',
			'settings.preferredServer' => 'Preferowany serwer',
			'settings.preferredServerDescription' => 'Priorytetuj wyniki tego serwera, jednocześnie utrzymując każdy podłączony serwer dostępny.',
			'settings.preferredServerAutomatic' => 'Automatycznie',
			'settings.showExploreTab' => 'Pokaż kartę Odkryj',
			'settings.showExploreTabDescription' => 'Wyświetlaj kartę Odkryj z treściami z Plex Discover i połączonych serwisów śledzących',
			'settings.hideEmptyLibraries' => 'Ukryj pustą bibliotekę',
			'settings.hideEmptyLibrariesDescription' => 'Usuń biblioteki z liczeniem elementów zgłaszanych przez serwer z nuli z nawigacji.',
			'settings.liveTvDefaultFavorites' => 'Domyślnie ulubione kanały',
			'settings.liveTvDefaultFavoritesDescription' => 'Pokaż tylko ulubione kanały po otwarciu telewizji na żywo',
			'settings.general' => 'Ogólne',
			'settings.generalDescription' => 'Język, uruchamianie i zachowanie okna',
			'settings.languageAndRegion' => 'Język i region',
			'settings.startup' => 'Uruchamianie',
			'settings.display' => 'Ekran',
			'settings.libraryAndCards' => 'Biblioteka i karty',
			'settings.homeScreen' => 'Ekran główny',
			'settings.navigation' => 'Nawigacja',
			'settings.window' => 'Okno',
			'settings.liveTv' => 'TV na żywo',
			'settings.player' => 'Odtwarzacz',
			'settings.videoAndDisplay' => 'Wideo i ekran',
			'settings.audio' => 'Audio',
			'settings.quality' => 'Jakość',
			'settings.subtitles' => 'Napisy',
			'settings.seekAndTiming' => 'Przewijanie i czas',
			'settings.behavior' => 'Zachowanie',
			'settings.gestures' => 'Gesty',
			'settings.gestureBrightnessSwipe' => 'Zmiana jasności przesunięciem',
			'settings.gestureBrightnessSwipeDescription' => 'Przesuwaj palcem w górę lub w dół na lewej krawędzi, aby regulować jasność',
			'settings.gestureVolumeSwipe' => 'Zmiana głośności przesunięciem',
			'settings.gestureVolumeSwipeDescription' => 'Przesuwaj palcem w górę lub w dół na prawej krawędzi, aby regulować głośność',
			'settings.gesturePinchToZoom' => 'Powiększanie ściskaniem',
			'settings.gesturePinchToZoomDescription' => 'Ściśnij wideo palcami, aby powiększyć lub pomniejszyć',
			'settings.gestureSeekSwipe' => 'Szukaj swipe',
			'settings.gestureSeekSwipeDescription' => 'Przełącz lewą lub prawą stronę wideo, aby wyszukać; uwalniaj do skoku',
			'settings.rememberBrightnessLevel' => 'Zapamiętaj poziom jasności',
			'settings.rememberBrightnessLevelDescription' => 'Rozpoczynaj odtwarzanie z jasnością ustawioną ostatnim przesunięciem',
			'settings.controls' => 'Sterowanie',
			'settings.rememberPlayerChanges' => 'Zapamiętuj zmiany odtwarzacza',
			'settings.rememberPlayerChangesDescription' => 'Miejsce zapisywania i ponownego stosowania zmian dokonanych podczas odtwarzania',
			'settings.scopePlaybackSpeed' => 'Prędkość odtwarzania',
			'settings.scopeShaderPreset' => 'Ustawienie shadera',
			'settings.scopeAspectRatio' => 'Proporcje obrazu',
			'settings.scopeSyncOffsets' => 'Synchronizacja dźwięku i napisów',
			'settings.playerScopeOff' => 'Nie zapisuj',
			'settings.playerScopeGlobal' => 'Wszędzie',
			'settings.playerScopeLibrary' => 'Na bibliotekę',
			'settings.playerScopeTitle' => 'Na serial lub film',
			'settings.exportDialogTitle' => 'Eksport ustawień PlezyNG',
			'settings.followSystem' => 'Zgodnie z systemem',
			'settings.followAppLanguage' => 'Jak język interfejsu',
			'settings.regionFormat' => 'Formaty regionalne',
			'settings.regionFormatDescription' => 'Wybierz sposób wyświetlania dat, liczb i jednostek miary.',
			'settings.metadataLanguage' => 'Język metadanych',
			'settings.metadataLanguageDescription' => 'Preferowany język tytułów i opisów, jeśli serwer go obsługuje. Preferencje dźwięku i napisów ustawia się osobno.',
			'themeEditor.builtIn' => 'Wbudowane',
			'themeEditor.presets' => 'Gotowe motywy',
			'themeEditor.custom' => 'Własny',
			'themeEditor.customEmpty' => 'Jeszcze nie utworzono',
			'themeEditor.editCustom' => 'Edytuj własny motyw',
			'themeEditor.editCustomDescription' => 'Wybierz każdy kolor samodzielnie',
			'themeEditor.locked' => 'Wymagany dostęp do życia',
			'themeEditor.savedLocked' => 'Zbawione – dostępne z dostępem do życia',
			'themeEditor.title' => 'Własny motyw',
			'themeEditor.startFrom' => 'Zacznij od',
			'themeEditor.startFromDescription' => 'Skopiuj wszystkie kolory z innego motywu',
			'themeEditor.colors' => 'Kolory',
			'themeEditor.preview' => 'Podgląd',
			'themeEditor.slots.bg' => 'Tło',
			'themeEditor.slots.surface' => 'Powierzchnia',
			'themeEditor.slots.outline' => 'Kontur',
			'themeEditor.slots.text' => 'Tekst',
			'themeEditor.slots.textMuted' => 'Tekst drugorzędny',
			'themeEditor.slots.accent' => 'Akcent',
			'themeEditor.opacity' => 'Krycie',
			'themeEditor.hexHint' => '#RRGGBB lub #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Z innych motywów',
			'themeEditor.swatchLabel' => ({required Object color, required Object theme}) => '${color} motywu ${theme}',
			'themeEditor.contrast.textOnBg' => 'Tekst na tle',
			'themeEditor.contrast.textOnSurface' => 'Tekst na powierzchni',
			'themeEditor.contrast.textMutedOnBg' => 'Tekst drugorzędny na tle',
			'themeEditor.contrast.textMutedOnSurface' => 'Tekst drugorzędny na powierzchni',
			'themeEditor.contrast.accentOnBg' => 'Akcent na tle',
			'themeEditor.contrast.accentOnSurface' => 'Akcent na powierzchni',
			'themeEditor.contrast.labelOnAccent' => 'Etykieta przycisku na akcencie',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, poniżej zalecanego ${minimum}:1',
			'themeEditor.discardTitle' => 'Odrzucić zmiany?',
			'themeEditor.discardMessage' => 'Niezapisane zmiany kolorów zostaną utracone.',
			'themeEditor.discard' => 'Odrzuć',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Odcinek ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => 'Pozostało ${minutes} min',
			'themeEditor.previewSwitch' => 'Automatyczne odtwarzanie',
			'themeEditor.previewMutedText' => 'Tak wygląda tekst drugorzędny',
			'search.hint' => 'Szukaj filmów, seriali, muzyki...',
			'search.tryDifferentTerm' => 'Spróbuj innego wyszukiwania',
			'search.searchYourMedia' => 'Przeszukaj swoje media',
			'search.enterTitleActorOrKeyword' => 'Wprowadź tytuł, aktora lub słowo kluczowe',
			'search.people' => 'Osoby',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Ustaw skrót dla ${actionName}',
			'hotkeys.clearShortcut' => 'Wyczyść skrót',
			'hotkeys.noShortcutSet' => 'Brak ustawionego skrótu',
			'hotkeys.currentShortcut' => 'Bieżący skrót:',
			'hotkeys.pressToRecord' => 'Wybierz, aby zapisać skrót klawiszowy',
			'hotkeys.recordingShortcut' => 'Naciśnij teraz skrót klawiszowy',
			'hotkeys.actions.playPause' => 'Odtwórz/Pauza',
			'hotkeys.actions.volumeUp' => 'Głośniej',
			'hotkeys.actions.volumeDown' => 'Ciszej',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Przewiń do przodu (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Przewiń do tyłu (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Pełny ekran',
			'hotkeys.actions.muteToggle' => 'Wyciszenie',
			'hotkeys.actions.subtitleToggle' => 'Napisy',
			'hotkeys.actions.audioTrackNext' => 'Następna ścieżka audio',
			'hotkeys.actions.subtitleTrackNext' => 'Następna ścieżka napisów',
			'hotkeys.actions.chapterNext' => 'Następny rozdział',
			'hotkeys.actions.chapterPrevious' => 'Poprzedni rozdział',
			'hotkeys.actions.episodeNext' => 'Następny odcinek',
			'hotkeys.actions.episodePrevious' => 'Poprzedni odcinek',
			'hotkeys.actions.speedIncrease' => 'Zwiększ prędkość',
			'hotkeys.actions.speedDecrease' => 'Zmniejsz prędkość',
			'hotkeys.actions.speedReset' => 'Zresetuj prędkość',
			'hotkeys.actions.zoomIn' => 'Powiększ',
			'hotkeys.actions.zoomOut' => 'Pomniejsz',
			'hotkeys.actions.zoomReset' => 'Zresetuj zoom',
			'hotkeys.actions.subSeekNext' => 'Przewiń do następnego napisu',
			'hotkeys.actions.subSeekPrev' => 'Przewiń do poprzedniego napisu',
			'hotkeys.actions.subtitleDelayIncrease' => 'Opóźnij napisy',
			'hotkeys.actions.subtitleDelayDecrease' => 'Przyspiesz napisy',
			'hotkeys.actions.shaderToggle' => 'Przełącz shadery',
			'hotkeys.actions.skipMarker' => 'Pomiń intro/napisy końcowe',
			'hotkeys.actions.screenshot' => 'Zrób zrzut ekranu',
			'hotkeys.actions.framePrevious' => 'Poprzedni Frame',
			'hotkeys.actions.frameNext' => 'Następny Frame',
			'fileInfo.title' => 'Informacje o pliku',
			'fileInfo.overview' => 'Przegląd',
			'fileInfo.video' => 'Wideo',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Napisy',
			'fileInfo.images' => 'Obrazy osadzone',
			'fileInfo.dataStreams' => 'Strumienie danych',
			'fileInfo.lyrics' => 'Teksty',
			'fileInfo.file' => 'Plik',
			'fileInfo.attachments' => 'Załączniki',
			'fileInfo.delivery' => 'Dostarczanie',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Wersja ${index} z ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Plik ${index} z ${count}',
			'fileInfo.noStreams' => 'Serwer nie zgłosił żadnych strumieni dla tego pliku.',
			'fileInfo.copyPath' => 'Kopiuj ścieżkę',
			'fileInfo.pathCopied' => 'Skopiowano ścieżkę pliku',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Tag kodeka',
			'fileInfo.resolution' => 'Rozdzielczość',
			'fileInfo.codedResolution' => 'Rozdzielczość kodowania',
			'fileInfo.bitrate' => 'Przepływność',
			'fileInfo.frameRate' => 'Klatki na sekundę',
			'fileInfo.rotation' => 'Rotacja',
			'fileInfo.comment' => 'Komentarz',
			'fileInfo.audioDescription' => 'Audiodeskrypcja',
			'fileInfo.headerCompression' => 'Kompresja nagłówka',
			'fileInfo.sidecarFile' => 'Plik towarzyszący',
			'fileInfo.transportTimestamp' => 'Znacznik czasu transportu',
			'fileInfo.displayOffset' => 'Przesunięcie wyświetlania',
			'fileInfo.previewFailureCode' => 'Kod błędu podglądu',
			'fileInfo.previewRetries' => 'Ponowne próby podglądu',
			'fileInfo.aspectRatio' => 'Proporcje',
			'fileInfo.pixelAspectRatio' => 'Współczynnik proporcji pikseli',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Poziom',
			'fileInfo.bitDepth' => 'Głębia bitowa',
			'fileInfo.pixelFormat' => 'Format pikseli',
			'fileInfo.colorSpace' => 'Przestrzeń kolorów',
			'fileInfo.colorRange' => 'Zakres kolorów',
			'fileInfo.colorPrimaries' => 'Kolory podstawowe',
			'fileInfo.colorTransfer' => 'Przenoszenie kolorów',
			'fileInfo.chromaSubsampling' => 'Podpróbkowanie chrominancji',
			'fileInfo.chromaLocation' => 'Położenie chrominancji',
			'fileInfo.scanType' => 'Typ skanowania',
			'fileInfo.interlaced' => 'Z przeplotem',
			'fileInfo.anamorphic' => 'Anamorficzny',
			'fileInfo.referenceFrames' => 'Klatki referencyjne',
			'fileInfo.dynamicRange' => 'Zakres dynamiczny',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Poziom Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Wersja Dolby Vision',
			'fileInfo.dolbyVisionLayers' => 'Warstwy Dolby Vision',
			'fileInfo.baseLayerCompatibility' => 'Zgodność warstwy bazowej',
			'fileInfo.avcBitstream' => 'Strumień bitowy AVC',
			'fileInfo.nalLengthSize' => 'Rozmiar długości NAL',
			'fileInfo.scalingMatrix' => 'Własna macierz skalowania',
			'fileInfo.streamIdentifier' => 'Identyfikator strumienia',
			'fileInfo.streamIndex' => 'Indeks strumienia',
			'fileInfo.streamId' => 'ID strumienia',
			'fileInfo.language' => 'Język',
			'fileInfo.languageCode' => 'Kod języka',
			'fileInfo.streamTitle' => 'Tytuł ścieżki',
			'fileInfo.channels' => 'Kanały',
			'fileInfo.sampleRate' => 'Częstotliwość próbkowania',
			'fileInfo.spatialAudio' => 'Dźwięk przestrzenny',
			'fileInfo.textBased' => 'Tekstowy',
			'fileInfo.subtitleFormat' => 'Format pliku towarzyszącego',
			'fileInfo.provider' => 'Dostawca',
			'fileInfo.matchScore' => 'Wynik dopasowania',
			'fileInfo.externalDelivery' => 'Może być dostarczany osobno',
			'fileInfo.sidecarPath' => 'Ścieżka pliku towarzyszącego',
			'fileInfo.sourceStream' => 'Skopiowano z',
			'fileInfo.temporary' => 'Tymczasowy',
			'fileInfo.timeBase' => 'Baza czasu',
			'fileInfo.overallBitrate' => 'Całkowita przepływność',
			'fileInfo.path' => 'Ścieżka',
			'fileInfo.fileName' => 'Nazwa pliku',
			'fileInfo.size' => 'Rozmiar',
			'fileInfo.totalSize' => 'Całkowity rozmiar',
			'fileInfo.container' => 'Kontener',
			'fileInfo.duration' => 'Czas trwania',
			'fileInfo.previewThumbnails' => 'Miniatury podglądu',
			'fileInfo.previewIndex' => 'Indeks podglądu',
			'fileInfo.packetLength' => 'Długość pakietu',
			'fileInfo.filePresent' => 'Plik obecny',
			'fileInfo.fileReadable' => 'Czytelny dla serwera',
			'fileInfo.streamPath' => 'Ścieżka strumienia',
			'fileInfo.optimizedForStreaming' => 'Zoptymalizowane do strumieniowania',
			'fileInfo.has64bitOffsets' => 'Przesunięcia 64-bitowe',
			'fileInfo.protocol' => 'Protokół',
			'fileInfo.mediaType' => 'Typ multimediów',
			'fileInfo.sourceKind' => 'Rodzaj źródła',
			'fileInfo.optimizedVersion' => 'Zoptymalizowana wersja',
			'fileInfo.optimizationTarget' => 'Cel optymalizacji',
			'fileInfo.deletedAt' => 'Usunięto',
			'fileInfo.remoteSource' => 'Źródło zdalne',
			'fileInfo.infiniteStream' => 'Nieskończony strumień',
			'fileInfo.directPlay' => 'Odtwarzanie bezpośrednie',
			'fileInfo.directStream' => 'Bezpośrednie strumieniowanie',
			'fileInfo.transcoding' => 'Transkodowanie',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID wersji',
			'fileInfo.fileId' => 'ID pliku',
			'fileInfo.defaultAudioTrack' => 'Domyślna ścieżka audio',
			'fileInfo.defaultSubtitleTrack' => 'Domyślna ścieżka napisów',
			'fileInfo.subtitlesOff' => 'Wył.',
			'fileInfo.flagDefault' => 'Domyślna',
			'fileInfo.flagForced' => 'Wymuszone',
			'fileInfo.flagSelected' => 'Wybrana',
			'fileInfo.flagExternal' => 'Zewnętrzne',
			'fileInfo.flagHearingImpaired' => 'Dla niesłyszących',
			'fileInfo.flagDub' => 'Dubbing',
			'fileInfo.flagOriginal' => 'Oryginalna',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Oznacz jako obejrzane',
			'mediaMenu.markAsUnwatched' => 'Oznacz jako nieobejrzane',
			'mediaMenu.removeFromContinueWatching' => 'Usuń z kontynuowania oglądania',
			'mediaMenu.viewDetails' => 'Pokaż szczegóły',
			'mediaMenu.goToSeries' => 'Przejdź do serialu',
			'mediaMenu.shufflePlay' => 'Odtwarzanie losowe',
			'mediaMenu.shuffleNotAvailableOffline' => 'Odtwarzanie losowe nie jest dostępne offline',
			'mediaMenu.fileInfo' => 'Informacje o pliku',
			'mediaMenu.deleteEpisodeFromServer' => 'Usuń odcinek z serwera',
			'mediaMenu.deleteSeasonFromServer' => 'Usuń sezon z serwera',
			'mediaMenu.deleteShowFromServer' => 'Usuń serial z serwera',
			'mediaMenu.deleteMovieFromServer' => 'Usuń film z serwera',
			'mediaMenu.deleteEpisodeTitle' => 'Usunąć ten odcinek?',
			'mediaMenu.deleteSeasonTitle' => 'Usunąć ten sezon?',
			'mediaMenu.deleteShowTitle' => 'Usunąć ten serial?',
			'mediaMenu.deleteMovieTitle' => 'Usunąć ten film?',
			'mediaMenu.deleteEpisodeConfirm' => 'Usuń odcinek',
			'mediaMenu.deleteSeasonConfirm' => 'Usuń sezon',
			'mediaMenu.deleteShowConfirm' => 'Usuń serial',
			'mediaMenu.deleteMovieConfirm' => 'Usuń film',
			'mediaMenu.deleteAnyway' => 'Usuń mimo to',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Trwale usunąć ${title} z Twojego serwera?',
			'mediaMenu.deleteMultipleWarning' => 'Obejmuje to wszystkie odcinki i ich pliki.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Usunięty zostanie ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinek w nim oraz jego plik.', few: 'Usunięte zostaną ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinki w nim oraz ich pliki.', many: 'Usuniętych zostanie ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinków w nim oraz ich pliki.', other: 'Usuniętych zostanie ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinka w nim oraz ich pliki.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Ten element jest przechowywany jako ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} plik, który zostanie usunięty.', few: 'Ten element jest przechowywany w ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} plikach, które wszystkie zostaną usunięte.', many: 'Ten element jest przechowywany w ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} plikach, które wszystkie zostaną usunięte.', other: 'Ten element jest przechowywany w ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pliku, który zostanie usunięty.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'W tym samym pliku przechowywany jest jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} inny odcinek, który również zostanie usunięty:', few: 'W tym samym pliku przechowywane są jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} inne odcinki, które również zostaną usunięte:', many: 'W tym samym pliku przechowywanych jest jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} innych odcinków, które również zostaną usunięte:', other: 'W tym samym pliku przechowywany jest jeszcze ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} innego odcinka, który również zostanie usunięty:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG nie mogło sprawdzić, które pliki zostaną usunięte, więc może usunąć więcej niż element wymieniony powyżej. Anuluj i spróbuj ponownie albo usuń mimo to.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Twój serwer nie podał informacji o plikach tego elementu, więc PlezyNG nie może sprawdzić, które pliki zostaną usunięte. Może usunąć więcej niż element wymieniony powyżej.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Usunięto element multimedialny',
			'mediaMenu.mediaFailedToDelete' => 'Nie udało się usunąć elementu multimedialnego',
			'mediaMenu.rate' => 'Oceń',
			'mediaMenu.playFromBeginning' => 'Odtwórz od początku',
			'mediaMenu.playVersion' => 'Odtwórz wersję...',
			'rateSheet.title' => 'Oceń',
			'rateSheet.server' => 'Serwer',
			'rateSheet.favorite' => 'Dodaj do ulubionych',
			'rateSheet.favorited' => 'Dodano do ulubionych',
			'rateSheet.saved' => 'Zapisano',
			'rateSheet.notAvailable' => 'Nie znaleziono dopasowania',
			'rateSheet.noConnectedServices' => 'Połącz usługę w Ustawieniach, aby tam oceniać.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serial TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'obejrzane',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => 'obejrzano w ${percent} procentach',
			'accessibility.mediaCardUnwatched' => 'nieobejrzane',
			'accessibility.tapToPlay' => 'Dotknij, aby odtworzyć',
			'accessibility.decrease' => 'Zmniejsz',
			'accessibility.increase' => 'Zwiększ',
			'accessibility.decreaseValue' => ({required Object label}) => 'Zmniejsz ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Zwiększ ${label}',
			'accessibility.hue' => 'Odcień',
			'accessibility.saturation' => 'Nasycenie',
			'accessibility.brightness' => 'Jasność',
			'accessibility.hexColor' => 'Kolor szesnastkowy',
			'accessibility.expandText' => 'Rozwiń tekst',
			'accessibility.collapseText' => 'Zwiń tekst',
			'accessibility.alphabetNavigation' => 'Nawigacja alfabetyczna',
			'accessibility.alphabetScrollHint' => 'Przesuń w górę lub w dół, aby przejść o literę',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Wiersz ${row} z ${rowCount}, kolumna ${column} z ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Wiersz ${row} z ${rowCount}',
			'accessibility.autoScrollPlay' => 'Uruchom automatyczne przewijanie',
			'accessibility.autoScrollPause' => 'Wstrzymaj automatyczne przewijanie',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'w',
			'accessibility.red' => 'Czerwony',
			'accessibility.green' => 'Zielona',
			'accessibility.blue' => 'niebieski',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Dostępność',
			'accessibility.summary' => 'Tekst, kontrast, ruch i kontrolę',
			'accessibility.systemHint' => 'Ustawienia dostępności urządzenia zawsze mają zastosowanie. te opcje dodają dostosowania w ciągu PlezyNG.',
			'accessibility.readability' => 'Czytanie i widoczność',
			'accessibility.textSize' => 'Dodatkowy rozmiar tekstu',
			'accessibility.preview' => 'Przeczytaj, słuchaj i obserwuj w swoim własnym tempie.',
			'accessibility.boldText' => 'Słynny interfejs tekst',
			'accessibility.highContrast' => 'Wysoki kontrast',
			'accessibility.highContrastHint' => 'Silniejsze teksty, wyświetleń i wskaźniki koncentracji na światłych lub ciemnych powierzchniach.',
			'accessibility.interaction' => 'ruch i interakcja',
			'accessibility.reduceMotion' => 'Zmniejszenie ruchu',
			'accessibility.reduceMotionHint' => 'Utrzymuj koncentrację, przejścia strony i efekty dekoracyjne.',
			'accessibility.largeTargets' => 'Większe cele dotykowe',
			'accessibility.largeTargetsHint' => 'Daj podzielone kontrolki więcej miejsca na dotyk i pomocną nawigację.',
			'accessibility.navigationHint' => 'Użyj karty Tab i Shift+Tab, aby przejść między kontrolami, wejść lub przestrzeń do aktywacji, a uciekać lub wrócić do zamknięcia.',
			'tooltips.shufflePlay' => 'Odtwarzanie losowe',
			'tooltips.playTrailer' => 'Odtwórz zwiastun',
			'tooltips.markAsWatched' => 'Oznacz jako obejrzane',
			'tooltips.markAsUnwatched' => 'Oznacz jako nieobejrzane',
			'audioTracks.track' => ({required Object n}) => 'Ścieżka audio ${n}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} klatka', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ramy wideo', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ramy wideo', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} ramy', ), 
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Napisy',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Pasy wokół obrazu',
			'videoControls.fillScreen' => 'Wypełnij ekran',
			'videoControls.stretch' => 'Rozciągnij',
			'videoControls.lockRotation' => 'Zablokuj obrót',
			'videoControls.unlockRotation' => 'Odblokuj obrót',
			'videoControls.timerActive' => 'Wyłącznik aktywny',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Odtwarzanie zatrzyma się za ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Koniec bieżącego wideo',
			'videoControls.sleepTimerStopAtHeader' => 'Zatrzymaj o',
			'videoControls.sleepTimerDurationHeader' => 'Minutnik',
			'videoControls.playbackWillPauseAtEnd' => 'Odtwarzanie zatrzyma się na końcu tego wideo',
			'videoControls.stillWatching' => 'Nadal oglądasz?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pauza za ${seconds}s',
			'videoControls.continueWatching' => 'Kontynuuj',
			'videoControls.autoPlayNext' => 'Automatycznie odtwórz następny',
			'videoControls.playNext' => 'Odtwórz następny',
			'videoControls.playButton' => 'Odtwórz',
			'videoControls.pauseButton' => 'Pauza',
			'videoControls.playbackPaused' => 'Wstrzymano',
			'videoControls.playbackResumed' => 'Odtwarzanie',
			'videoControls.loadingVideo' => 'Ładowanie wideo',
			'videoControls.showPlaybackControls' => 'Pokaż elementy sterujące odtwarzaniem',
			'videoControls.hidePlaybackControls' => 'Ukryj elementy sterujące odtwarzaniem',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Przewiń do tyłu o ${seconds} sekund',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Przewiń do przodu o ${seconds} sekund',
			'videoControls.previousButton' => 'Poprzedni odcinek',
			'videoControls.nextButton' => 'Następny odcinek',
			'videoControls.previousChapterButton' => 'Poprzedni rozdział',
			'videoControls.nextChapterButton' => 'Następny rozdział',
			'videoControls.muteButton' => 'Wycisz',
			'videoControls.unmuteButton' => 'Wyłącz wyciszenie',
			'videoControls.settingsButton' => 'Ustawienia odtwarzania',
			'videoControls.tracksButton' => 'Audio i napisy',
			'videoControls.trackSelectionTitle' => 'Wybierz ścieżki przed playbackem',
			'videoControls.trackSelectionAuto' => 'Automatyczne wybór',
			'videoControls.chaptersButton' => 'Rozdziały',
			'videoControls.versionQualityButton' => 'Wersja i jakość',
			'videoControls.versionColumnHeader' => 'Wersja',
			'videoControls.qualityColumnHeader' => 'Jakość',
			'videoControls.qualityOriginal' => 'Oryginalna',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transkodowanie niedostępne — odtwarzanie w oryginalnej jakości',
			'videoControls.subtitleUnavailableFallback' => 'Nie udało się wczytać wybranych napisów — odtwarzanie jest kontynuowane bez napisów',
			'videoControls.pipButton' => 'Tryb obraz w obrazie',
			'videoControls.aspectRatioButton' => 'Proporcje',
			'videoControls.ambientLighting' => 'Oświetlenie otoczenia',
			'videoControls.fullscreenButton' => 'Wejdź w pełny ekran',
			'videoControls.exitFullscreenButton' => 'Wyjdź z pełnego ekranu',
			'videoControls.alwaysOnTopButton' => 'Zawsze na wierzchu',
			'videoControls.rotationLockButton' => 'Blokada obrotu',
			'videoControls.lockScreen' => 'Zablokuj ekran',
			'videoControls.screenLockButton' => 'Blokada ekranu',
			'videoControls.longPressToUnlock' => 'Przytrzymaj, aby odblokować',
			'videoControls.timelineSlider' => 'Oś czasu wideo',
			'videoControls.volumeSlider' => 'Poziom głośności',
			'videoControls.endsAt' => ({required Object time}) => 'Kończy się o ${time}',
			'videoControls.pipActive' => 'Odtwarzanie w trybie obraz w obrazie',
			'videoControls.pipFailed' => 'Nie udało się uruchomić trybu obraz w obrazie',
			'videoControls.screenshotSaved' => 'Zrzut ekranu zapisany',
			'videoControls.screenshotFailed' => 'Nie udało się zrobić zrzutu ekranu',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Powiększenie ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Głośność ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Wymaga Androida 8.0 lub nowszego',
			'videoControls.pipErrors.iosVersion' => 'Wymaga iOS 15.0 lub nowszego',
			'videoControls.pipErrors.permissionDisabled' => 'Obraz w obrazie jest wyłączony. Włącz go w ustawieniach systemu.',
			'videoControls.pipErrors.notSupported' => 'Urządzenie nie obsługuje trybu obraz w obrazie',
			'videoControls.pipErrors.voSwitchFailed' => 'Nie udało się przełączyć wyjścia wideo dla trybu obraz w obrazie',
			'videoControls.pipErrors.failed' => 'Nie udało się uruchomić trybu obraz w obrazie',
			'videoControls.pipErrors.prepareFailed' => 'Nie udało się przygotować trybu obraz w obrazie',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Wystąpił błąd: ${error}',
			'videoControls.chapters' => 'Rozdziały',
			'videoControls.noChaptersAvailable' => 'Brak dostępnych rozdziałów',
			'videoControls.queue' => 'Kolejka',
			'videoControls.noQueueItems' => 'Brak elementów w kolejce',
			'videoControls.noAudioDevicesAvailable' => 'Brak dostępnych urządzeń audio',
			'videoControls.searchSubtitles' => 'Szukaj napisów',
			'videoControls.loadSubtitleFile' => 'Pobierz subtitle plik...',
			'videoControls.subtitleLoadFailed' => 'Nie udało się pobrać subtitle',
			'videoControls.language' => 'Język',
			'videoControls.noSubtitlesFound' => 'Nie znaleziono napisów',
			'videoControls.subtitleDownloaded' => 'Napisy pobrane',
			'videoControls.subtitleDownloadedNotApplied' => 'Napisy zostały pobrane, ale nie można ich było wybrać',
			'videoControls.subtitleDownloadFailed' => 'Nie udało się pobrać napisów',
			'videoControls.searchLanguages' => 'Szukaj języków...',
			'videoControls.skipIntro' => 'Pomiń intro',
			'videoControls.skipCredits' => 'Pomiń napisy końcowe',
			'videoControls.skipAds' => 'Skok reklam',
			'videoControls.nextEpisode' => 'Następny odcinek',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Ścieżka ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Napisy ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (wymuszone)',
			'videoControls.osdSubtitlesOff' => 'Napisy: wył.',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Napisy: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio: ${track}',
			'messages.markedAsWatched' => 'Oznaczono jako obejrzane',
			'messages.markedAsUnwatched' => 'Oznaczono jako nieobejrzane',
			'messages.markedAsWatchedOffline' => 'Oznaczono jako obejrzane (zsynchronizuje się po połączeniu)',
			'messages.markedAsUnwatchedOffline' => 'Oznaczono jako nieobejrzane (zsynchronizuje się po połączeniu)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatycznie usunięto: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzane pobranie', few: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzane pobrania', many: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzanych pobrań', other: 'Automatycznie usunięto ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} obejrzanego pobrania', ), 
			'messages.removedFromContinueWatching' => 'Usunięto z kontynuowania oglądania',
			'messages.errorLoading' => ({required Object error}) => 'Błąd: ${error}',
			'messages.searchPartialResults' => 'Niektórych serwerów multimediów nie udało się przeszukać. Wyświetlane są dostępne wyniki.',
			'messages.streamInterrupted' => 'Strumień został przerwany. Naciśnij odtwarzanie lub przewiń, aby spróbować ponownie.',
			'messages.liveStreamInterrupted' => 'Transmisja na żywo została przerwana. Naciśnij odtwarzanie, aby spróbować ponownie.',
			'messages.fileInfoNotAvailable' => 'Informacje o pliku niedostępne',
			'messages.playbackAuthenticationRequired' => 'Zaloguj się ponownie na serwerze multimediów, aby odtworzyć ten element.',
			'messages.playbackServerUnavailable' => 'Serwer multimediów jest niedostępny. Spróbuj ponownie później.',
			'messages.playbackDataInvalid' => 'Serwer zwrócił nieprawidłowe informacje o odtwarzaniu.',
			'messages.playbackCancelled' => 'Odtwarzanie zostało anulowane.',
			'messages.playbackFailed' => 'Nie udało się rozpocząć odtwarzania.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Nie udało się rozpocząć odtwarzania: ${error}',
			'messages.audioOutputFailed' => 'Wyjście audio przestało odpowiadać. Sprawdź połączenie audio telewizora lub amplitunera; jeśli inne aplikacje też nie mają dźwięku, uruchom urządzenie ponownie.',
			'messages.mediaUnavailable' => 'Ta treść nie jest już dostępna.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Błąd ładowania informacji o pliku: ${error}',
			'messages.errorLoadingSeries' => 'Błąd ładowania serialu',
			'messages.musicNotSupported' => 'Odtwarzanie muzyki nie jest jeszcze obsługiwane',
			'messages.noDescriptionAvailable' => 'Brak dostępnego opisu',
			'messages.noProfilesAvailable' => 'Brak dostępnych profili',
			'messages.contactAdminForProfiles' => 'Skontaktuj się z administratorem serwera, aby dodać profile',
			'messages.unableToDetermineLibrarySection' => 'Nie można określić sekcji biblioteki dla tego elementu',
			'messages.logsCleared' => 'Logi wyczyszczone',
			'messages.logsCopied' => 'Logi skopiowane do schowka',
			'messages.noLogsAvailable' => 'Brak dostępnych logów',
			'messages.libraryScanning' => ({required Object title}) => 'Skanowanie "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Rozpoczęto skanowanie biblioteki "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Nie udało się zeskanować biblioteki: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Odświeżanie metadanych "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Rozpoczęto odświeżanie metadanych "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Nie udało się odświeżyć metadanych: ${error}',
			'messages.logoutConfirm' => 'Czy na pewno chcesz się wylogować?',
			'messages.noSeasonsFound' => 'Nie znaleziono sezonów',
			'messages.seasonsLoadFailed' => 'Nie udało się załadować sezonów',
			'messages.noEpisodesFound' => 'Nie znaleziono odcinków w pierwszym sezonie',
			'messages.noEpisodesFoundGeneral' => 'Nie znaleziono odcinków',
			_ => null,
		} ?? switch (path) {
			'messages.episodesLoadFailed' => 'Nie udało się załadować odcinków',
			'messages.noResultsFound' => 'Nie znaleziono wyników',
			'messages.sleepTimerSet' => ({required Object label}) => 'Wyłącznik czasowy ustawiony na ${label}',
			'messages.noItemsAvailable' => 'Brak dostępnych elementów',
			'messages.failedToCreatePlayQueueNoItems' => 'Nie udało się utworzyć kolejki odtwarzania — brak elementów',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Nie udało się ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Przełączanie na kompatybilny odtwarzacz...',
			'messages.serverLimitTitle' => 'Odtwarzanie nie powiodło się',
			'messages.serverLimitBody' => 'Błąd serwera (HTTP 500). Limit przepustowości/transkodowania prawdopodobnie odrzucił tę sesję. Poproś właściciela o zmianę.',
			'messages.mediaUnreadableTitle' => 'Plik niedostępny',
			'messages.mediaUnreadableBody' => 'Serwer znalazł ten element, ale nie mógł odczytać jego pliku (HTTP 404). Plik został prawdopodobnie przeniesiony, usunięty albo jego pamięć masowa jest niedostępna. Poproś właściciela serwera o sprawdzenie pliku i ponowne przeskanowanie biblioteki.',
			'messages.serverBusyTitle' => 'Strumień niedostępny',
			'messages.serverBusyBody' => 'Serwer wielokrotnie odmawiał strumieniowania tego pliku (HTTP 503). Być może jest ponownie uruchamiany lub zajęty albo magazyn danych zawierający plik jest offline. Spróbuj ponownie za chwilę — jeśli problem będzie się powtarzać, poproś właściciela serwera o sprawdzenie serwera i magazynu danych zawierającego plik.',
			'messages.playbackNotAllowedTitle' => 'Odtwarzanie niedozwolone',
			'messages.playbackNotAllowedBody' => 'Serwer odmówił strumieniowania tego elementu (HTTP 403). Twoje konto może nie mieć uprawnień do jego odtwarzania albo serwer może zezwalać na odtwarzanie tylko w swojej sieci lokalnej.',
			'messages.logsUploaded' => 'Logi przesłane',
			'messages.logsUploadFailed' => 'Nie udało się przesłać logów',
			'messages.logId' => 'ID logu',
			'messages.burnedSubtitlesUseMenu' => 'Napisy są wtopione w ten strumień. Zmień je w menu napisów.',
			'messages.noVideoUrl' => 'Brak dostępnego adresu URL wideo',
			'messages.playbackNoMediaSources' => 'Serwer nie zwrócił żadnych możliwych do odtworzenia źródeł multimediów',
			'messages.playbackDataNotPrepared' => 'Odtwarzanie rozpoczęło się, zanim dane były gotowe',
			'messages.streamSelectionUnavailable' => 'Wybór strumieni nie jest dostępny dla tego źródła',
			'messages.streamSelectionFailed' => 'Nie udało się zastosować wybranych strumieni',
			'messages.trackSelectionNotRemembered' => 'Ten wybór ścieżki dotyczy tylko bieżącego odtwarzania.',
			'messages.serverUnavailableForProfile' => 'Brak dostępnego serwera dla aktywnego profilu',
			'subtitlingStyling.previewSample' => 'Szybki brązowy fox skoczy nad łagodnym psem',
			'subtitlingStyling.text' => 'Tekst',
			'subtitlingStyling.border' => 'Obramowanie',
			'subtitlingStyling.background' => 'Tło',
			'subtitlingStyling.fontSize' => 'Rozmiar czcionki',
			'subtitlingStyling.textColor' => 'Kolor tekstu',
			'subtitlingStyling.borderSize' => 'Rozmiar obramowania',
			'subtitlingStyling.borderColor' => 'Kolor obramowania',
			'subtitlingStyling.backgroundOpacity' => 'Przezroczystość tła',
			'subtitlingStyling.backgroundColor' => 'Kolor tła',
			'subtitlingStyling.position' => 'Pozycja',
			'subtitlingStyling.assOverride' => 'Nadpisywanie ASS',
			'subtitlingStyling.overrideScale' => 'Skaluj',
			'subtitlingStyling.overrideForce' => 'Wymuś',
			'subtitlingStyling.overrideStrip' => 'Usuń style',
			'subtitlingStyling.positionTop' => 'Góra',
			'subtitlingStyling.positionBottom' => 'Dół',
			'subtitlingStyling.useMargins' => 'Użyj marginesów',
			'subtitlingStyling.useMarginsDescription' => 'Pozwól napisom tekstowym pojawiać się w przestrzeni poza wideo. Napisy stylizowane mogą zachować pierwotne położenie.',
			'subtitlingStyling.anchorToScreen' => 'Zakotwicz na ekranie',
			'subtitlingStyling.anchorToScreenDescription' => 'Wyświetlaj napisy tekstowe na czarnych pasach poniżej obrazu panoramicznego',
			'subtitlingStyling.bold' => 'Pogrubienie',
			'subtitlingStyling.italic' => 'Kursywa',
			'subtitlingStyling.renderResolution' => 'Rozdzielczość renderowania',
			'subtitlingStyling.renderResolutionScreen' => 'Rozdzielczość ekranu',
			'subtitlingStyling.renderResolutionVideo' => 'Rozdzielczość wideo',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Zaawansowane ustawienia odtwarzacza wideo',
			'mpvConfig.presets' => 'Ustawienia wstępne',
			'mpvConfig.noPresets' => 'Brak zapisanych ustawień wstępnych',
			'mpvConfig.saveAsPreset' => 'Zapisz jako ustawienie wstępne...',
			'mpvConfig.presetName' => 'Nazwa ustawienia wstępnego',
			'mpvConfig.presetNameHint' => 'Wprowadź nazwę tego ustawienia wstępnego',
			'mpvConfig.loadPreset' => 'Wczytaj',
			'mpvConfig.deletePreset' => 'Usuń',
			'mpvConfig.presetSaved' => 'Zapisano ustawienie wstępne',
			'mpvConfig.presetLoaded' => 'Wczytano ustawienie wstępne',
			'mpvConfig.presetDeleted' => 'Usunięto ustawienie wstępne',
			'mpvConfig.confirmDeletePreset' => 'Czy na pewno chcesz usunąć to ustawienie wstępne?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Dodaj wiersz',
			'mpvConfig.removeLine' => 'Usuń wiersz',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context i gpu-api są ignorowane w systemie Linux: wbudowane wideo jest zawsze renderowane przez vo=libmpv na płaszczyźnie wideo, a gpu-next (wymagany przez shadery obliczeniowe takie jak ArtCNN) nie może działać w trybie wbudowanym.',
			'dialog.confirmAction' => 'Potwierdź działanie',
			'profiles.addPlezyProfile' => 'Dodaj profil PlezyNG',
			'profiles.switchingProfile' => 'Przełączanie profilu…',
			'profiles.deleteThisProfileTitle' => 'Usunąć ten profil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Usuń ${displayName}. Połączenia nie zostaną zmienione.',
			'profiles.active' => 'Aktywny',
			'profiles.manage' => 'Zarządzaj',
			'profiles.delete' => 'Usuń',
			'profiles.signOut' => 'Wyloguj się',
			'profiles.signOutPlexTitle' => 'Wylogować się z Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Usunąć ${displayName} i wszystkich użytkowników Plex Home? Możesz zalogować się ponownie w każdej chwili.',
			'profiles.signOutPlexDeleteDownloads' => 'Usuń również pobrania',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'W przeciwnym razie pozostaną na tym urządzeniu i wrócą po ponownym zalogowaniu się na to konto.',
			'profiles.signedOutPlex' => 'Wylogowano z Plex.',
			'profiles.signOutFailed' => 'Wylogowanie nie powiodło się.',
			'profiles.sectionTitle' => 'Profile',
			'profiles.summarySingle' => 'Dodaj profile, aby łączyć użytkowników zarządzanych z profilami lokalnymi',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => 'Liczba profili: ${count} · aktywny: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => 'Liczba profili: ${count}',
			'profiles.removeConnectionTitle' => 'Usunąć połączenie?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Usuń dostęp ${displayName} do ${connectionLabel}. Inne profile go zachowają.',
			'profiles.deleteProfileTitle' => 'Usunąć profil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Usuń ${displayName} i jego połączenia. Serwery pozostaną dostępne.',
			'profiles.profileNameLabel' => 'Nazwa profilu',
			'profiles.pinProtectionLabel' => 'Ochrona PIN-em',
			'profiles.copyAutomationLink' => 'Kopiowanie Android automatyzacja link',
			'profiles.copyAutomationLinkDescription' => 'Wybierz ten profil z zamiaru lub automatyzacji Android.',
			'profiles.automationLinkCopied' => 'Profil automatyzacji link kopiował.',
			'profiles.pinManagedByPlex' => 'PIN zarządzany przez Plex. Edytuj na plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Nie ustawiono PIN-u. Aby go wymagać, edytuj użytkownika Home na plex.tv.',
			'profiles.setPin' => 'Ustaw PIN',
			'profiles.setPinTitle' => 'Ustaw PIN',
			'profiles.confirmPinTitle' => 'Potwierdź PIN',
			'profiles.pinSet' => 'PIN ustawiony',
			'profiles.changePin' => 'Zmień',
			'profiles.removePin' => 'Usuń',
			'profiles.connectionsLabel' => 'Połączenia',
			'profiles.add' => 'Dodaj',
			'profiles.deleteProfileButton' => 'Usuń profil',
			'profiles.noConnectionsHint' => 'Brak połączeń — dodaj jedno, aby używać tego profilu.',
			'profiles.noConnections' => 'Brak połączeń',
			'profiles.plexHomeAccount' => 'Konto Plex Home',
			'profiles.plexAccountChip' => ({required Object account}) => 'Konto Plex: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} przez ${account}',
			'profiles.connectionDefault' => 'Domyślne',
			'profiles.connectionAs' => ({required Object displayName}) => 'jako ${displayName}',
			'profiles.makeDefault' => 'Ustaw jako domyślne',
			'profiles.removeConnection' => 'Usuń',
			'profiles.profileRenamed' => 'Zmieniono nazwę profilu.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Dodaj do ${displayName}',
			'profiles.borrowExplain' => 'Skorzystaj z połączenia innego profilu. Profile chronione PIN-em wymagają podania PIN-u.',
			'profiles.borrowEmpty' => 'Nie ma jeszcze żadnych dostępnych połączeń.',
			'profiles.borrowEmptySubtitle' => 'Najpierw połącz Plex, Jellyfin lub Emby z innym profilem.',
			'profiles.borrowLoadFailed' => 'Nie udało się wczytać dostępnych połączeń. Spróbuj ponownie.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Z profilu ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Dodano połączenie z innego profilu.',
			'profiles.borrowFailed' => 'Nie udało się dodać połączenia z innego profilu.',
			'profiles.incorrectPin' => 'Nieprawidłowy PIN.',
			'profiles.incorrectPinTryAgain' => 'Nieprawidłowy PIN. Spróbuj ponownie.',
			'profiles.sourceProfileMissingParentAccount' => 'Profil źródłowy nie ma konta nadrzędnego.',
			'profiles.failedToLoadHomeUsers' => 'Nie udało się wczytać użytkowników Plex Home. Sprawdź połączenie i spróbuj ponownie.',
			'profiles.failedToVerifyPin' => 'Nie udało się zweryfikować PIN-u.',
			'profiles.newProfile' => 'Nowy profil',
			'profiles.profileNameHint' => 'np. Goście, Dzieci, Salon',
			'profiles.pinProtectionOptional' => 'Ochrona PIN-em (opcjonalnie)',
			'profiles.pinExplain' => 'Do przełączania profili wymagany jest 4-cyfrowy PIN.',
			'profiles.continueButton' => 'Kontynuuj',
			'profiles.pinsDontMatch' => 'PIN-y nie pasują',
			'profiles.tokenIdentityMismatch' => 'Token profilu Plex został powiązany z nieoczekiwanym serwerem',
			'profiles.settingsLocked' => 'Ustawienia są zamknięte dla tego profilu.',
			'profiles.unlockSettings' => 'Odblokowanie ustawień',
			'profiles.showExploreForProfile' => 'Wyświetl przeglądarki dla tego profilu',
			'profiles.showExploreForProfileDescription' => 'Wyłącz, aby usunąć Explore z nawigacji tego profilu.',
			'connections.sectionTitle' => 'Połączenia',
			'connections.addConnection' => 'Dodaj połączenie',
			'connections.addConnectionSubtitleNoProfile' => 'Zaloguj się przez Plex lub połącz serwer Jellyfin albo Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Dodaj do ${displayName}: Plex, Jellyfin, Emby lub połączenie innego profilu',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sesja wygasła dla ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sesja wygasła dla ${count} serwerów',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} odmówił dostępu temu kontu',
			'connections.accessDeniedMany' => ({required Object count}) => 'Odmowa dostępu dla tego konta na ${count} serwerach',
			'connections.signInAgain' => 'Zaloguj się ponownie',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edytuj połączenie z ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Dodaj lub usuń adresy URL dla ${serverName}. PlezyNG będzie używać osiągalnego adresu URL o najniższym opóźnieniu.',
			'accountPreferences.sectionTitle' => 'Preferencje konta',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Opcje audio, napisów i biblioteki zapisane na koncie ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Opcje audio, napisów i biblioteki zapisane na ${count} kontach',
			'accountPreferences.pickAccount' => 'Każde konto przechowuje własne preferencje. Wybierz to, które chcesz edytować.',
			'accountPreferences.storedOnAccount' => 'Te opcje są zapisywane na samym koncie, więc używa ich każda aplikacja zalogowana na to konto — w tym PlezyNG na Twoich innych urządzeniach.',
			'accountPreferences.noAccounts' => 'Brak kont do skonfigurowania',
			'accountPreferences.noAccountsHint' => 'Zaloguj się do Plex albo połącz serwer Jellyfin lub Emby, a preferencje zapisane na tym koncie pojawią się tutaj.',
			'accountPreferences.unavailable' => 'Nie można połączyć się z tym kontem',
			'accountPreferences.loadFailed' => 'Nie udało się wczytać tych preferencji',
			'accountPreferences.noPreference' => 'Brak preferencji',
			'accountPreferences.notSet' => 'Nie ustawiono',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio i napisy',
			'accountPreferences.groups.libraryDisplay' => 'Biblioteka',
			'accountPreferences.groups.personalMedia' => 'Osobiste multimedia',
			'accountPreferences.preferredAudioLanguage' => 'Preferowany język audio',
			'accountPreferences.autoSelectAudio' => 'Wybieraj audio według języka',
			'accountPreferences.autoSelectAudioDescription' => 'Ustawienie „Wył.” pozostawia ścieżkę audio, którą plik oznacza jako domyślną.',
			'accountPreferences.preferredSubtitleLanguage' => 'Preferowany język napisów',
			'accountPreferences.subtitleMode' => 'Włączanie napisów',
			'accountPreferences.subtitleModes.none' => 'Wybór ręczny',
			'accountPreferences.subtitleModes.noneDescription' => 'Nigdy nie włączaj napisów automatycznie.',
			'accountPreferences.subtitleModes.defaultMode' => 'Kieruj się flagami ścieżki',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Używaj flag domyślna i wymuszona zapisanych na każdej ścieżce napisów.',
			'accountPreferences.subtitleModes.always' => 'Zawsze włączone',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Włączaj ścieżkę napisów w preferowanym języku, gdy tylko istnieje.',
			'accountPreferences.subtitleModes.onlyForced' => 'Tylko wymuszone napisy',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Wczytuj tylko ścieżki oznaczone jako wymuszone.',
			'accountPreferences.subtitleModes.smart' => 'Wyświetlane przy dźwięku w obcym języku',
			'accountPreferences.subtitleModes.smartDescription' => 'Włączaj napisy tylko wtedy, gdy dźwięk jest w innym języku.',
			'accountPreferences.subtitleAccessibility' => 'Napisy SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Preferuj napisy bez SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Preferuj napisy SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Tylko napisy SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Tylko napisy bez SDH',
			'accountPreferences.forcedSubtitles' => 'Wymuszone napisy',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Preferuj niewymuszone napisy',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Preferuj wymuszone napisy',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Tylko wymuszone napisy',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Tylko niewymuszone napisy',
			'accountPreferences.displayMissingEpisodes' => 'Pokaż brakujące odcinki',
			'accountPreferences.displayMissingEpisodesDescription' => 'Wyświetlaj odcinki, które serwer zna, ale dla których nie ma pliku.',
			'accountPreferences.hidePlayedInLatest' => 'Ukrywaj obejrzane pozycje w sekcji Ostatnio dodane',
			'accountPreferences.hidePlayedInLatestDescription' => 'Pomijaj pozycje, które już obejrzałeś, w wierszach „Ostatnio dodane” serwera.',
			'accountPreferences.displayCollectionsView' => 'Pokaż widok „Kolekcje”',
			'accountPreferences.displayCollectionsViewDescription' => 'Pokazuj widok kolekcji serwera obok Twoich bibliotek.',
			'accountPreferences.rewatchingInNextUp' => 'Zachowuj ponownie oglądane seriale w sekcji „Następny odcinek”',
			'accountPreferences.rewatchingInNextUpDescription' => 'Gdy skończysz serial i zaczniesz go oglądać ponownie, sekcja „Następny odcinek” podąży za ponownym oglądaniem zamiast usuwać serial.',
			'accountPreferences.watchedIndicator' => 'Wskaźniki obejrzanych',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nigdy',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmy i seriale TV',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Tylko filmy',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Tylko seriale TV',
			'accountPreferences.mediaReviewsVisibility' => 'Oceny i recenzje',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Użytkownicy i krytycy',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Tylko użytkownicy',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Tylko krytycy',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Ukryte',
			'discover.title' => 'Odkryj',
			'discover.noContentAvailable' => 'Brak dostępnych treści',
			'discover.addMediaToLibraries' => 'Dodaj multimedia do swoich bibliotek',
			'discover.continueWatching' => 'Kontynuuj oglądanie',
			'discover.continueWatchingIn' => ({required Object library}) => 'Kontynuuj oglądanie w ${library}',
			'discover.nextUp' => 'Następny odcinek',
			'discover.nextUpIn' => ({required Object library}) => 'Następny odcinek w ${library}',
			'discover.recentlyAdded' => 'Ostatnio dodane',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Ostatnio dodane w ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Najnowsze albumy w ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Ostatnio odtwarzane w ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Najczęściej odtwarzane w ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Opis',
			'discover.cast' => 'Obsada',
			'discover.findNext.title' => 'Znajdź Twój następny',
			'discover.findNext.open' => 'Znajdź Twój następny',
			'discover.findNext.anyTime' => 'W każdej chwili',
			'discover.findNext.timeAvailable' => 'Ile czasu masz?',
			'discover.findNext.filters' => 'Wybierz moment',
			'discover.findNext.watch' => 'Spójrz',
			'discover.findNext.listen' => 'Słuchaj',
			'discover.findNext.read' => 'Czytaj',
			'discover.findNext.finishable' => ({required Object duration}) => 'Zakończenie w ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'O ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Następny rozdział · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} łącznie',
			'discover.findNext.timingVaries' => 'Czas różni się',
			'discover.findNext.notNow' => 'Nie teraz',
			'discover.findNext.swipeHint' => 'Przełącz lub użyj poniższych przycisków',
			'discover.findNext.saved' => 'Oszczędne picks',
			'discover.findNext.savedCount' => ({required Object count}) => 'Zastrzeżone punkty · ${count}',
			'discover.findNext.undo' => 'i w',
			'discover.findNext.details' => 'Szczegóły',
			'discover.findNext.noPicks' => 'Nie ma jeszcze wyboru',
			'discover.findNext.noPicksHint' => 'Połączyć bibliotekę lub dodać źródło mediów, aby rozpocząć.',
			'discover.findNext.noMatches' => 'Nic nie pasuje do tego momentu',
			'discover.findNext.noMatchesHint' => 'Spróbuj innego formatu lub daj sobie więcej czasu.',
			'discover.findNext.allDone' => 'Wszyscy jesteście złapani',
			'discover.findNext.allDoneHint' => 'Rozpocznij świeżą mieszankę, aby zobaczyć te opcje ponownie.',
			'discover.findNext.refresh' => 'Znajdź inną mieszankę',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Od ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Od ${library}',
			'discover.findNext.ownedReason' => 'Z Twojej biblioteki',
			'discover.findNext.liveNow' => 'Na teraz',
			'discover.findNext.watchLive' => 'Spójrz na żywo',
			'discover.findNext.filterAnything' => 'Wszystko',
			'discover.findNext.filterWatch' => 'Spójrz',
			'discover.findNext.filterListen' => 'Słuchaj',
			'discover.findNext.filterRead' => 'Czytaj',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Aplikuj',
			'discover.findNext.openFailed' => 'Ta opcja nie jest już dostępna. odśwież, aby sprawdzić ponownie.',
			'discover.findNext.changeFailed' => 'Nie da się tego zmienić, spróbuj jeszcze raz.',
			'discover.findNext.savedLimit' => 'Zbawione punkty są pełne. usunąć jeden wybór, aby zaoszczędzić drugi.',
			'discover.extras' => 'Zwiastuny i dodatki',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Ocena',
			'discover.director' => 'Reżyser',
			'discover.directors' => 'Reżyserzy',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serial TV',
			'discover.minutesLeft' => ({required Object minutes}) => 'Pozostało ${minutes} min',
			'discover.moreLikeThis' => 'Więcej podobnych',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytuł', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytuły', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytułów', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tytułu', ), 
			'discover.person.born' => 'Data urodzenia',
			'discover.person.died' => 'Data śmierci',
			'discover.person.birthplace' => 'Miejsce urodzenia',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (wiek: ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (w wieku ${age} lat)',
			'errors.searchFailed' => ({required Object error}) => 'Wyszukiwanie nie powiodło się: ${error}',
			'errors.searchUnavailable' => 'Wyszukiwanie nie mogło połączyć się z żadnym serwerem multimediów.',
			'errors.connectionTimeout' => ({required Object context}) => 'Limit czasu połączenia przy ładowaniu ${context}',
			'errors.connectionFailed' => 'Nie można połączyć się z serwerem multimediów',
			'errors.unableToLoad' => ({required Object context}) => 'Nie udało się załadować ${context}. Spróbuj ponownie.',
			'errors.noClientAvailable' => 'Brak dostępnego klienta',
			'errors.pleaseEnterToken' => 'Wprowadź token',
			'errors.invalidToken' => 'Nieprawidłowy token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Nie udało się zweryfikować tokena: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Nie udało się przełączyć na ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Nie udało się usunąć ${displayName}',
			'errors.failedToRate' => 'Nie udało się zaktualizować oceny',
			'errors.reasonTimedOut' => 'upłynął limit czasu połączenia',
			'errors.reasonUnreachable' => 'nie można połączyć się z serwerem',
			'errors.reasonRefused' => 'serwer odrzucił żądanie',
			'errors.reasonNotFound' => 'elementu nie ma już na serwerze',
			'errors.reasonServerError' => 'serwer zgłosił błąd',
			'errors.reasonCancelled' => 'żądanie zostało anulowane',
			'errors.reasonUnexpected' => 'wystąpił nieoczekiwany błąd',
			'libraries.playRandomMovie' => 'Zagraj w filmie randomizowanym',
			'libraries.randomPickFailed' => 'Nie można wybrać filmów z tej biblioteki.',
			'libraries.title' => 'Biblioteki',
			'libraries.fallbackTitle' => 'Biblioteka',
			'libraries.scanLibraryFiles' => 'Skanuj pliki biblioteki',
			'libraries.scanLibrary' => 'Skanuj bibliotekę',
			'libraries.analyze' => 'Analizuj',
			'libraries.analyzeLibrary' => 'Analizuj bibliotekę',
			'libraries.refreshMetadata' => 'Odśwież metadane',
			'libraries.emptyTrash' => 'Opróżnij kosz',
			'libraries.emptyingTrash' => ({required Object title}) => 'Opróżnianie kosza dla "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Kosz opróżniony dla "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Nie udało się opróżnić kosza: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analizowanie "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analiza rozpoczęta dla "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Nie udało się przeanalizować biblioteki: ${error}',
			'libraries.noLibrariesFound' => 'Nie znaleziono bibliotek',
			'libraries.allLibrariesHidden' => 'Wszystkie biblioteki są ukryte',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Ukryte biblioteki (${count})',
			'libraries.thisLibraryIsEmpty' => 'Ta biblioteka jest pusta',
			'libraries.noItemsMatchFilters' => 'Żaden element nie pasuje do aktywnych filtrów',
			'libraries.resetFilters' => 'Resetuj filtry',
			'libraries.all' => 'Wszystkie',
			'libraries.clearAll' => 'Wyczyść wszystko',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Czy na pewno chcesz zeskanować "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Czy na pewno chcesz przeanalizować "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Czy na pewno chcesz odświeżyć metadane dla "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Czy na pewno chcesz opróżnić kosz dla "${title}"?',
			'libraries.manageLibraries' => 'Zarządzaj bibliotekami',
			'libraries.sort' => 'Sortuj',
			'libraries.sortBy' => 'Sortuj wg',
			'libraries.filters' => 'Filtry',
			'libraries.confirmActionMessage' => 'Czy na pewno chcesz wykonać tę operację?',
			'libraries.showLibrary' => 'Pokaż bibliotekę',
			'libraries.hideLibrary' => 'Ukryj bibliotekę',
			'libraries.libraryOptions' => 'Opcje biblioteki',
			'libraries.content' => 'zawartość biblioteki',
			'libraries.selectLibrary' => 'Wybierz bibliotekę',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtry (${count})',
			'libraries.noRecommendations' => 'Brak dostępnych rekomendacji',
			'libraries.noCollections' => 'Brak kolekcji w tej bibliotece',
			'libraries.noFoldersFound' => 'Nie znaleziono folderów',
			'libraries.folders' => 'foldery',
			'libraries.tabs.recommended' => 'Polecane',
			'libraries.tabs.browse' => 'Przeglądaj',
			'libraries.tabs.collections' => 'Kolekcje',
			'libraries.tabs.playlists' => 'Playlisty',
			'libraries.groupings.title' => 'Grupowanie',
			'libraries.groupings.all' => 'Wszystkie',
			'libraries.groupings.movies' => 'Filmy',
			'libraries.groupings.shows' => 'Seriale TV',
			'libraries.groupings.seasons' => 'Sezony',
			'libraries.groupings.episodes' => 'Odcinki',
			'libraries.groupings.artists' => 'Wykonawcy',
			'libraries.groupings.albums' => 'Albumy',
			'libraries.groupings.tracks' => 'Utwory',
			'libraries.groupings.folders' => 'Foldery',
			'libraries.filterCategories.genre' => 'Gatunek',
			'libraries.filterCategories.year' => 'Rok',
			'libraries.filterCategories.contentRating' => 'Klasyfikacja wiekowa',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Nieobejrzane',
			'libraries.filterCategories.unplayed' => 'Nieodtworzone',
			'libraries.filterCategories.favorites' => 'Ulubione',
			'libraries.filterCategories.filePath' => 'Ścieżka pliku',
			'libraries.sortLabels.title' => 'Tytuł',
			'libraries.sortLabels.dateAdded' => 'Data dodania',
			'libraries.sortLabels.releaseDate' => 'Data premiery',
			'libraries.sortLabels.rating' => 'Ocena',
			'libraries.sortLabels.communityRating' => 'Ocena społeczności',
			'libraries.sortLabels.criticRating' => 'Ocena krytyków',
			'libraries.sortLabels.userRating' => 'Ocena użytkownika',
			'libraries.sortLabels.datePlayed' => 'Data odtworzenia',
			'libraries.sortLabels.playCount' => 'Liczba odtworzeń',
			'libraries.sortLabels.productionYear' => 'Rok produkcji',
			'libraries.sortLabels.runtime' => 'Czas trwania',
			'libraries.sortLabels.officialRating' => 'Oficjalna klasyfikacja',
			'libraries.sortLabels.premiereDate' => 'Data premiery',
			'libraries.sortLabels.startDate' => 'Data rozpoczęcia',
			'libraries.sortLabels.airTime' => 'Godzina emisji',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Losowo',
			'libraries.sortLabels.dateShared' => 'Data udostępnienia',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Data emisji ostatniego odcinka',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Data dodania ostatniego odcinka',
			'libraries.sortLabels.dateDownloaded' => 'Data pobrania',
			'libraries.sortLabels.size' => 'Rozmiar',
			'libraries.sortLabels.library' => 'Biblioteka',
			'libraries.advancedFilters.include' => 'Uwzględnij',
			'libraries.advancedFilters.exclude' => 'Wyklucz',
			'libraries.advancedFilters.any' => 'Dowolne',
			'libraries.advancedFilters.yes' => 'Tak',
			'libraries.advancedFilters.no' => 'Nie',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Bez: ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => 'Wybrano: ${count}',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => 'Wykluczono: ${count}',
			'libraries.advancedFilters.searchValues' => 'Szukaj wartości',
			'libraries.advancedFilters.noValues' => 'Brak wartości',
			'libraries.advancedFilters.matchContains' => 'Zawiera',
			'libraries.advancedFilters.matchNotContains' => 'Nie zawiera',
			'libraries.advancedFilters.matchIs' => 'Jest',
			'libraries.advancedFilters.matchIsNot' => 'Nie jest',
			'libraries.advancedFilters.matchBeginsWith' => 'Zaczyna się od',
			'libraries.advancedFilters.matchEndsWith' => 'Kończy się na',
			'libraries.advancedFilters.textHint' => 'Wpisz tekst do dopasowania',
			'libraries.advancedFilters.from' => 'Od',
			'libraries.advancedFilters.to' => 'Do',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from}–${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => 'Od ${value}',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Do ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Ostatnie ${count} dni',
			'libraries.advancedFilters.dateLastYear' => 'Ostatni rok',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Starsze niż ${count} dni',
			'libraries.advancedFilters.dateOlderThanYear' => 'Starsze niż rok',
			'libraries.selection.selectItems' => 'Wybierz elementy',
			'libraries.selection.selectedCount' => ({required Object count}) => 'Wybrano: ${count}',
			'libraries.selection.actions' => 'Akcje selekcji',
			'libraries.selection.confirmDescendants' => 'To zmienia wszystkie odcinki w wybranych pokazach i sezonach.',
			'libraries.selection.confirmUnwatched' => 'To również wyjaśnia postęp odtwarzania dla wybranych elementów.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Wybrane elementy: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Aktualizowane elementy: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Aktualizacja ${succeeded}; nieudane ${failed}. nieudane elementy pozostają wybrane.',
			'about.title' => 'O aplikacji',
			'about.openSourceLicenses' => 'Licencje oprogramowania open source',
			'about.versionLabel' => ({required Object version}) => 'Wersja ${version}',
			'about.appDescription' => 'Piękny klient Plex, Jellyfin i Emby stworzony we Flutterze',
			'about.viewLicensesDescription' => 'Wyświetl licencje bibliotek innych firm',
			'about.privacyPolicy' => 'Polityka prywatności',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nie znaleziono serwerów dla ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Nie udało się załadować serwerów: ${error}',
			'serverSelection.noValidServers' => 'Nie znaleziono żadnych zdatnych serwerów na tym koncie',
			'hubDetail.title' => 'Tytuł',
			'hubDetail.releaseYear' => 'Rok premiery',
			'hubDetail.dateAdded' => 'Data dodania',
			'hubDetail.rating' => 'Ocena',
			'hubDetail.noItemsFound' => 'Nie znaleziono elementów',
			'logs.clearLogs' => 'Wyczyść logi',
			'logs.copyLogs' => 'Kopiuj logi',
			'logs.uploadLogs' => 'Prześlij logi',
			'logs.saveLogs' => 'Zapisz log do pliku',
			'logs.logsSaved' => ({required Object path}) => 'Zapisy zapisane do ${path}',
			'logs.saveLogsFailed' => 'Nie mogłem zapisać pliku logowego.',
			'detail.endsAt' => ({required Object time}) => 'Kończy się o ${time}',
			'startup.failedTitle' => 'Nie udało się uruchomić PlezyNG',
			'startup.failedBody' => 'Coś poszło nie tak podczas uruchamiania. Poniższe szczegóły wskazują, co zawiodło.',
			'startup.failedBodyRepairable' => 'Zapisany plik ustawień PlezyNG jest uszkodzony i musi zostać odbudowany, zanim PlezyNG będzie mogło się uruchomić. Ponawianie nie pomoże — wybierz Napraw pamięć.',
			'startup.phaseLabel' => 'Krok',
			'startup.showDetails' => 'Pokaż szczegóły',
			'startup.hideDetails' => 'Ukryj szczegóły',
			'startup.copyDetails' => 'Kopiuj szczegóły',
			'startup.detailsCopied' => 'Skopiowano szczegóły do schowka',
			'startup.uploadDetails' => 'Prześlij szczegóły',
			'startup.repairStorage' => 'Napraw pamięć',
			'startup.repairTitle' => 'Naprawić zapisane dane?',
			'startup.repairBodyCommon' => 'Plik ustawień PlezyNG jest uszkodzony i nie można go odczytać. Naprawa przywraca wszystkie ustawienia do wartości domyślnych.',
			'startup.repairBodyOneCredential' => 'Jedno zapisane logowanie jest uszkodzone i nie można go odczytać. Naprawa usunie tylko je; pozostałe ustawienia pozostaną nietknięte.',
			'startup.repairBodySignInsKept' => 'Twoje serwery i profile powinny pozostać zalogowane.',
			'startup.repairBodySignInsLost' => 'Klucza chroniącego zapisane logowania nie można odzyskać z tego pliku, więc będziesz musiał zalogować się ponownie na każdym serwerze i profilu. Nic na Twoim serwerze multimediów nie zostanie zmienione.',
			'startup.repairBodySessionsUncertain' => 'Usługi śledzenia (MAL, AniList, Simkl, Trakt) i Seerr są przechowywane osobno i mogą, ale nie muszą przetrwać. PlezyNG dokładnie poinformuje Cię, co zachowało.',
			'startup.repairConfirm' => 'Napraw',
			'startup.repairSucceeded' => 'Naprawiono pamięć',
			'startup.repairNeedsRestart' => 'Naprawiono pamięć — wymagany restart',
			'startup.restartRequiredBody' => 'Twoje dane zostały naprawione, ale PlezyNG musi uruchomić się od nowa, zanim będzie mogło z nich korzystać. Zamknij PlezyNG i otwórz je ponownie.',
			'startup.quitPlezy' => 'Zamknij PlezyNG',
			'startup.repairFailed' => 'Naprawa nie powiodła się',
			'startup.repairKeptSignIns' => 'Twoje serwery i profile są nadal zalogowane.',
			'startup.repairLostSignIns' => 'Nie udało się odzyskać klucza chroniącego zapisane logowania. Musisz zalogować się ponownie na każdym serwerze i profilu.',
			'startup.repairLostSessions' => 'Utracono co najmniej jedno połączenie z usługą śledzenia lub Seerr i trzeba je ponownie połączyć.',
			'startup.backupTitle' => 'Zachowano kopię uszkodzonego pliku',
			'startup.backupWarning' => 'Zawiera Twoje dane logowania. Nie przesyłaj ani nie udostępniaj jej.',
			'startup.deleteBackup' => 'Usuń kopię',
			'startup.backupDeleted' => 'Usunięto kopię.',
			'startup.previousFailureTitle' => 'Ostatnim razem nie udało się uruchomić PlezyNG',
			'licenses.relatedPackages' => 'Powiązane pakiety',
			'licenses.license' => 'Licencja',
			'licenses.licenseNumber' => ({required Object number}) => 'Licencja ${number}',
			'licenses.licensesCount' => ({required Object count}) => 'Liczba licencji: ${count}',
			'navigation.libraries' => 'Biblioteki',
			'navigation.downloads' => 'Pobrania',
			'navigation.liveTv' => 'TV na żywo',
			'navigation.explore' => 'Przeglądaj',
			'explore.mdblistShelves.manage' => 'Zarządzanie eksploracją schodów',
			'explore.mdblistShelves.manageDescription' => 'Wybierz i zorganizuj listy z konta MDBList',
			'explore.mdblistShelves.description' => 'Wybierz publiczne listy filmowe i telewizyjne z konta MDBList. utworzyć lub skopiować listy na MDBList, a następnie odświeżyć.',
			'explore.mdblistShelves.selected' => 'wybrane szkielety',
			'explore.mdblistShelves.available' => 'Dostępne listy kont',
			'explore.mdblistShelves.noLists' => 'Nie ma powrotnych list filmowych lub telewizyjnych. utworzyć lub skopiować listę na MDBList, a następnie odświeżyć.',
			'explore.mdblistShelves.displayName' => 'Nazwa Shelf Display',
			'explore.mdblistShelves.nameHint' => 'Pozostaw biały, aby użyć nazwy listy źródłowej.',
			'explore.mdblistShelves.add' => 'Dodaj Shelf',
			'explore.mdblistShelves.save' => 'Zbawienie łóżek',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Przeprowadź ${title} w górę',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Przeprowadź ${title} w dół',
			'explore.mdblistShelves.unavailable' => 'Ta lista nie jest dostępna. wycofać lub usunąć jej pudełko w ustawieniach.',
			'explore.mdblistShelves.rateLimited' => 'Osiągnięto limit żądań MDBList. Spróbuj ponownie później.',
			'explore.mdblistShelves.loadFailed' => 'Nie można ładować płyt. sprawdź połączenie i odwracać.',
			'explore.mdblistShelves.saveFailed' => 'Nie mogę się doczekać, proszę o zwrot.',
			'explore.mdblistShelves.accountChanged' => 'Zmiana konta lub profilu. ponownie otworzyć te ustawienia.',
			'explore.mdblistShelves.settingsUnreadable' => 'Nie można przeczytać zapisanych półek. Wybierz listy ponownie, aby zastąpić te ustawienia.',
			'explore.title' => 'Przeglądaj',
			'explore.selectSource' => 'Wybierz źródło',
			'explore.rows.watchlist' => 'Lista do obejrzenia',
			'explore.rows.recommendedMovies' => 'Rekomendowane filmy',
			'explore.rows.recommendedShows' => 'Rekomendowane seriale',
			'explore.rows.trendingMovies' => 'Filmy na czasie',
			'explore.rows.trendingShows' => 'Seriale na czasie',
			'explore.rows.popularMovies' => 'Popularne filmy',
			'explore.rows.popularShows' => 'Popularne seriale',
			'explore.rows.trendingAnime' => 'Anime na czasie',
			'explore.rows.suggestedAnime' => 'Sugerowane anime',
			_ => null,
		} ?? switch (path) {
			'explore.rows.airingAnime' => 'Najpopularniejsze emitowane anime',
			'explore.rows.popularAnime' => 'Najpopularniejsze anime',
			'explore.rows.trending' => 'Na czasie',
			'explore.rows.upcomingMovies' => 'Nadchodzące filmy',
			'explore.rows.upcomingShows' => 'Nadchodzące seriale',
			'explore.status.airing' => 'W emisji',
			'explore.status.ended' => 'Zakończony',
			'explore.status.canceled' => 'Anulowany',
			'explore.status.upcoming' => 'Nadchodzący',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinek', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinki', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinków', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} odcinka', ), 
			'explore.cast' => 'Obsada',
			'explore.characters' => 'Postacie',
			'explore.addToWatchlist' => 'Dodaj do listy do obejrzenia',
			'explore.removeFromWatchlist' => 'Usuń z listy do obejrzenia',
			'explore.addedToWatchlist' => 'Dodano do listy do obejrzenia',
			'explore.removedFromWatchlist' => 'Usunięto z listy do obejrzenia',
			'explore.watchlistUpdateFailed' => 'Nie udało się zaktualizować listy do obejrzenia',
			'explore.watchlistNoMatch' => 'Nie udało się dopasować tej pozycji do listy do obejrzenia',
			'explore.notInLibrary' => 'Nie ma tego w Twojej bibliotece',
			'explore.inTheseLibraries' => 'W tych bibliotekach',
			'explore.checkingLibrary' => 'Sprawdzanie Twojej biblioteki...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwera', few: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwerów', many: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwerów', other: 'Nie udało się sprawdzić ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serwerów', ), 
			'explore.emptyTitle' => 'Jeszcze nic tu nie ma',
			'explore.emptyMessage' => ({required Object source}) => 'Wiersze z ${source} pojawią się tutaj, gdy będą zawierać treści.',
			'explore.searchHint' => ({required Object source}) => 'Szukaj w ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Brak wyników dla "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Szukaj filmów i seriali w ${source}.',
			'explore.searchFailed' => 'Wyszukiwanie nie powiodło się. Sprawdź połączenie i spróbuj ponownie.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} popularne',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} emitowane',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} najwyżej oceniane',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} na czasie',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} w sezonie ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} ogląda teraz',
			'explore.badge.available' => 'Dostępne',
			'explore.badge.partiallyAvailable' => 'Częściowo dostępne',
			'explore.badge.availableIn4k' => 'Dostępne w 4K',
			'explore.badge.requested' => 'Zamówiono',
			'explore.badge.pendingApproval' => 'Oczekuje na zatwierdzenie',
			'explore.badge.processing' => 'Przetwarzanie',
			'explore.badge.declined' => 'Odrzucono',
			'explore.badge.requestFailed' => 'Żądanie nie powiodło się',
			'explore.badge.requested4k' => 'Zamówiono w 4K',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} sezonów',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Odc. ${episode} za ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Następny za ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} odc.',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/odc.',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} na listach',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} obejrzało dziś',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} obejrzało w tym tygodniu',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} obejrzało w tym miesiącu',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} obejrzało w tym roku',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} widzów',
			'explore.stats.planning' => ({required Object n}) => '${n} planuje obejrzeć',
			'explore.stats.favorited' => ({required Object n}) => '${n} w ulubionych',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} porzuciło',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarz', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarze', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarzy', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentarza', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} głosów',
			'explore.stats.watching' => ({required Object n}) => '${n} ogląda',
			'explore.stats.completed' => ({required Object n}) => '${n} ukończyło',
			'explore.stats.onHold' => ({required Object n}) => '${n} wstrzymało',
			'explore.stats.dropped' => ({required Object n}) => '${n} porzuciło',
			'explore.season.winter' => 'Zima',
			'explore.season.spring' => 'Wiosna',
			'explore.season.summer' => 'Lato',
			'explore.season.fall' => 'Jesień',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'Krótka seria TV',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Odcinek specjalny',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Muzyka',
			'explore.format.other' => 'Inne',
			'explore.sourceMaterial.original' => 'Oryginał',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Powieść',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Gra',
			'explore.sourceMaterial.webComic' => 'Komiks internetowy',
			'explore.sourceMaterial.musicRelease' => 'Muzyka',
			'explore.sourceMaterial.otherMedia' => 'Inne',
			'explore.creditRole.actor' => 'Aktor',
			'explore.creditRole.director' => 'Reżyser',
			'explore.creditRole.writer' => 'Scenarzysta',
			'explore.creditRole.producer' => 'Producent',
			'explore.creditRole.creator' => 'Twórca',
			'explore.creditRole.composer' => 'Kompozytor',
			'explore.relation.prequel' => 'Prequel',
			'explore.relation.sequel' => 'Sequel',
			'explore.relation.sideStory' => 'Poboczna historia',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Wersja alternatywna',
			'explore.relation.summary' => 'Streszczenie',
			'explore.relation.parentStory' => 'Historia pierwotna',
			'explore.relation.adaptation' => 'Adaptacja',
			'explore.relation.other' => 'Powiązane',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Emisja ${day} o ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Emisja ${day} o ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Tytuł oryginalny',
			'explore.detail.alsoKnownAs' => 'Znany również jako',
			'explore.detail.studios' => 'Studia',
			'explore.detail.country' => 'Kraj',
			'explore.detail.language' => 'Język',
			'explore.detail.released' => 'Premiera',
			'explore.detail.physicalRelease' => 'Na nośniku',
			'explore.detail.ended' => 'Zakończony',
			'explore.detail.addedOn' => ({required Object date}) => 'Dodano ${date}',
			'explore.detail.yourRating' => 'Twoja ocena',
			'explore.detail.budget' => 'Budżet',
			'explore.detail.revenue' => 'Box office',
			'explore.detail.contentAdvisory' => 'Klasyfikacja wiekowa',
			'explore.detail.tags' => 'Tagi',
			'explore.detail.revealSpoilerTags' => 'Pokaż tagi zawierające spoilery',
			'explore.detail.links' => 'Linki',
			'explore.detail.watchOn' => 'Oglądaj na',
			'explore.detail.watchTrailer' => 'Obejrzyj zwiastun',
			'explore.detail.openOn' => ({required Object site}) => 'Otwórz na ${site}',
			'explore.detail.crew' => 'Obsada i ekipa',
			'explore.detail.ratings' => 'Oceny',
			'explore.detail.schedule' => 'Harmonogram',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkownika', few: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkowników', many: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkowników', other: 'Polecany przez ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} użytkownika', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Polecany przez ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Dodany do ulubionych przez ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} jeszcze nie wyemitowano',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Polecany przez ${percent} widzów',
			'explore.detail.relatedTitles' => 'Powiązane tytuły',
			'explore.detail.background' => 'Tło',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wynik', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wyniki', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wyników', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} wyniku', ), 
			'liveTv.title' => 'TV na żywo',
			'liveTv.guide' => 'Przewodnik',
			'liveTv.noChannels' => 'Brak dostępnych kanałów',
			'liveTv.noDvr' => 'Brak skonfigurowanego DVR na żadnym serwerze',
			'liveTv.serverUnavailable' => 'Serwer telewizji na żywo jest niedostępny.',
			'liveTv.serverNotConnected' => 'Serwer telewizji na żywo nie jest połączony.',
			'liveTv.noPrograms' => 'Brak danych o programach',
			'liveTv.liveStreamFailed' => 'Transmisja na żywo nie powiodła się',
			'liveTv.unknownProgram' => 'Nieznany program',
			'liveTv.timelineLiveProgram' => 'Program na żywo (playback może być poza tym programem)',
			'liveTv.timelineBuffer' => 'Temat Buffer',
			'liveTv.timelineUnavailable' => 'Czas nie dostępny',
			'liveTv.timelineEstimated' => 'Podsumowanie Playback',
			'liveTv.timelinePending' => 'W poszukiwaniu',
			'liveTv.timelineStale' => 'Program może być przestarzały',
			'liveTv.unknownHub' => 'Nieznane',
			'liveTv.unknownError' => 'Nieznany błąd',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanał ${number}',
			'liveTv.unknownChannel' => 'Nieznany kanał',
			'liveTv.live' => 'NA ŻYWO',
			'liveTv.premiereBadge' => 'Nowy',
			'liveTv.reloadGuide' => 'Odśwież przewodnik',
			'liveTv.searchGuide' => 'Szukaj w przewodniku',
			'liveTv.searchHint' => 'Szukaj kanałów i programów',
			'liveTv.searchNoResults' => ({required Object query}) => 'Brak dopasowań dla "${query}"',
			'liveTv.channelsSection' => 'Kanały',
			'liveTv.programsSection' => 'Programy',
			'liveTv.now' => 'Teraz',
			'liveTv.today' => 'Dzisiaj',
			'liveTv.tomorrow' => 'Jutro',
			'liveTv.midnight' => 'Północ',
			'liveTv.overnight' => 'Nocą',
			'liveTv.morning' => 'Rano',
			'liveTv.daytime' => 'W ciągu dnia',
			'liveTv.evening' => 'Wieczorem',
			'liveTv.lateNight' => 'Późna noc',
			'liveTv.whatsOn' => 'Co leci',
			'liveTv.watchChannel' => 'Oglądaj kanał',
			'liveTv.favorites' => 'Ulubione',
			'liveTv.reorderFavorites' => 'Zmień kolejność ulubionych',
			'liveTv.noFavoriteChannels' => 'Brak ulubionych kanałów',
			'liveTv.noFavoriteChannelsHint' => 'Pokaż wszystkie kanały, a następnie naciśnij i przytrzymaj kanał, aby dodać go do ulubionych.',
			'liveTv.showAllChannels' => 'Pokaż wszystkie kanały',
			'liveTv.favoritesLoadFailed' => 'Nie udało się wczytać ulubionych. Sprawdź połączenie i spróbuj ponownie.',
			'liveTv.favoritesUpdateFailed' => 'Nie udało się zaktualizować ulubionych. Sprawdź połączenie i spróbuj ponownie.',
			'liveTv.joinSession' => 'Dołącz do trwającej sesji',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Oglądaj od początku (${minutes} min temu)',
			'liveTv.watchLive' => 'Oglądaj na żywo',
			'liveTv.goToLive' => 'Przejdź do transmisji na żywo',
			'liveTv.record' => 'Nagraj',
			'liveTv.recordEpisode' => 'Nagraj odcinek',
			'liveTv.recordSeries' => 'Nagraj serial',
			'liveTv.recordOptions' => 'Opcje nagrywania',
			'liveTv.saveTo' => 'Zapisz w',
			'liveTv.recordings' => 'Nagrania',
			'liveTv.scheduledRecordings' => 'Zaplanowane',
			'liveTv.recordingRules' => 'Reguły nagrywania',
			'liveTv.noScheduledRecordings' => 'Brak zaplanowanych nagrań',
			'liveTv.manageRecording' => 'Zarządzaj nagraniem',
			'liveTv.cancelRecording' => 'Anuluj nagrywanie',
			'liveTv.cancelRecordingTitle' => 'Anulować to nagrywanie?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} nie będzie już nagrywane.',
			'liveTv.deleteRule' => 'Usuń regułę',
			'liveTv.deleteRuleTitle' => 'Usunąć regułę nagrywania?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Przyszłe odcinki ${title} nie będą nagrywane.',
			'liveTv.recordingScheduled' => 'Nagrywanie zaplanowane',
			'liveTv.alreadyScheduled' => 'Ten program jest już zaplanowany',
			'liveTv.dvrAdminRequired' => 'Ustawienia DVR wymagają konta administratora',
			'liveTv.recordingFailed' => 'Nie można zaplanować nagrywania',
			'liveTv.recordingTargetMissing' => 'Nie można określić biblioteki nagrań',
			'liveTv.recordNotAvailable' => 'Nagrywanie niedostępne dla tego programu',
			'liveTv.recordingCancelled' => 'Nagrywanie anulowane',
			'liveTv.recordingRuleDeleted' => 'Reguła nagrywania usunięta',
			'liveTv.processRecordingRules' => 'Ponów ocenę reguł',
			'liveTv.recordingInProgress' => 'Trwa nagrywanie',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} zaplanowanych',
			'liveTv.editRule' => 'Edytuj regułę',
			'liveTv.editRuleAction' => 'Edytuj',
			'liveTv.recordingRuleUpdated' => 'Reguła nagrywania zaktualizowana',
			'liveTv.guideReloadRequested' => 'Zażądano odświeżenia przewodnika',
			'liveTv.guideReloadFailed' => 'Nie udało się odświeżyć przewodnika',
			'liveTv.rulesProcessRequested' => 'Zażądano ponownej oceny reguł',
			'liveTv.rulesProcessFailed' => 'Nie udało się ponownie przetworzyć reguł nagrywania',
			'liveTv.recordShow' => 'Nagraj program',
			'liveTv.recordSettings.startEarly' => 'Zacznij wcześniej (sekundy)',
			'liveTv.recordSettings.endLate' => 'Zakończ później (sekundy)',
			'liveTv.recordSettings.newOnly' => 'Tylko nowe odcinki',
			'liveTv.recordSettings.anyChannel' => 'Nagrywaj na dowolnym kanale',
			'liveTv.recordSettings.anyTime' => 'Nagrywaj o dowolnej porze',
			'liveTv.recordSettings.skipInLibrary' => 'Pomijaj odcinki już obecne w bibliotece',
			'liveTv.recordSettings.keepUpTo' => 'Odcinki do zachowania',
			'liveTv.recordSettings.keepUpToHint' => '0 zachowuje wszystkie odcinki',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Rozpocznie się za ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} o ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} zwrócił nieprawidłowe dane odtwarzania TV na żywo',
			'liveTv.failedToStartChannel' => 'Nie udało się uruchomić kanału na żywo',
			'liveTv.failedToBuildStreamUrl' => 'Nie udało się utworzyć adresu URL strumienia',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Nie udało się uruchomić kanału: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Nie udało się przełączyć kanału: ${reason}',
			'collections.title' => 'Kolekcje',
			'collections.collection' => 'Kolekcja',
			'collections.empty' => 'Kolekcja jest pusta',
			'collections.deleteCollection' => 'Usuń kolekcję',
			'collections.deleteConfirm' => ({required Object title}) => 'Usunąć "${title}"? Tego nie można cofnąć.',
			'collections.deleted' => 'Kolekcja usunięta',
			'collections.deleteFailed' => 'Nie udało się usunąć kolekcji',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Nie udało się usunąć kolekcji: ${error}',
			'collections.selectCollection' => 'Wybierz kolekcję',
			'collections.collectionName' => 'Nazwa kolekcji',
			'collections.enterCollectionName' => 'Wprowadź nazwę kolekcji',
			'collections.addedToCollection' => 'Dodano do kolekcji',
			'collections.errorAddingToCollection' => 'Nie udało się dodać do kolekcji',
			'collections.created' => 'Kolekcja utworzona',
			'collections.removeFromCollection' => 'Usuń z kolekcji',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Usunąć "${title}" z tej kolekcji?',
			'collections.removedFromCollection' => 'Usunięto z kolekcji',
			'collections.removeFromCollectionFailed' => 'Nie udało się usunąć z kolekcji',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Błąd usuwania z kolekcji: ${error}',
			'collections.searchCollections' => 'Szukaj kolekcji...',
			'playlists.title' => 'Playlisty',
			'playlists.playlist' => 'Playlista',
			'playlists.noPlaylists' => 'Nie znaleziono playlist',
			'playlists.create' => 'Utwórz playlistę',
			'playlists.playlistName' => 'Nazwa playlisty',
			'playlists.enterPlaylistName' => 'Wprowadź nazwę playlisty',
			'playlists.delete' => 'Usuń playlistę',
			'playlists.removeItem' => 'Usuń z playlisty',
			'playlists.smartPlaylist' => 'Inteligentna playlista',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} element', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementy', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementów', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementu', ), 
			'playlists.emptyPlaylist' => 'Ta playlista jest pusta',
			'playlists.deleteConfirm' => 'Usunąć playlistę?',
			'playlists.deleteMessage' => ({required Object name}) => 'Czy na pewno chcesz usunąć "${name}"?',
			'playlists.created' => 'Playlista utworzona',
			'playlists.deleted' => 'Playlista usunięta',
			'playlists.itemAdded' => 'Dodano do playlisty',
			'playlists.itemRemoved' => 'Usunięto z playlisty',
			'playlists.selectPlaylist' => 'Wybierz playlistę',
			'playlists.searchPlaylists' => 'Szukaj playlist...',
			'playlists.errorCreating' => 'Nie udało się utworzyć playlisty',
			'playlists.errorDeleting' => 'Nie udało się usunąć playlisty',
			'playlists.errorLoading' => 'Nie udało się załadować playlist',
			'playlists.errorAdding' => 'Nie udało się dodać do playlisty',
			'playlists.errorReordering' => 'Nie udało się zmienić kolejności elementu playlisty',
			'playlists.errorRemoving' => 'Nie udało się usunąć z playlisty',
			'music.goToAlbum' => 'Przejdź do albumu',
			'music.goToArtist' => 'Przejdź do wykonawcy',
			'music.instantMix' => 'Miks błyskawiczny',
			'music.playNext' => 'Odtwórz następny',
			'music.addToQueue' => 'Dodaj do kolejki',
			'music.discNumber' => ({required Object n}) => 'Płyta ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utwór', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utwory', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utworów', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utworu', ), 
			'music.nowPlaying' => 'Teraz odtwarzane',
			'music.playingFrom' => ({required Object title}) => 'Odtwarzanie z ${title}',
			'music.queue' => 'Kolejka',
			'music.clearQueue' => 'Wyczyść kolejkę',
			'music.lyrics' => 'Tekst utworu',
			'music.visualizer' => 'Wizualizator',
			'music.visualizerProfileLoading' => 'Czytaj dalej wpis Analiza ścieżki...',
			'music.visualizerAmbientMotion' => 'Ambientowe ruchy',
			'music.visualizerPlexLoudness' => 'Głośność Plex',
			'music.visualizerPreviousPreset' => 'Poprzedni artykułWizualny styl',
			'music.visualizerNextPreset' => 'Następny artykułWizualny styl',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Bloom',
			'music.visualizerPresetOrbitals' => 'orbity',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'tunel',
			'music.visualizerPresetTrackMap' => 'ścieżka mapy',
			'music.noLyrics' => 'Brak tekstu utworu',
			'music.sleepTimer' => 'Wyłącznik czasowy',
			'music.sleepTimerEndOfTrack' => 'Koniec utworu',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuta', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minut', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty', ), 
			'music.stopPlayback' => 'Zatrzymaj odtwarzanie',
			'music.previousTrack' => 'Poprzedni utwór',
			'music.nextTrack' => 'Następny utwór',
			'music.repeat' => 'Powtarzaj',
			'music.repeatAll' => 'Powtarzaj wszystko',
			'music.repeatOne' => 'Powtarzaj jeden',
			'music.instantMixNoServer' => 'Brak dostępnego serwera dla szybkiego miksu',
			'music.instantMixFailed' => 'Nie udało się wczytać miksu błyskawicznego',
			'music.instantMixEmpty' => 'Miks błyskawiczny nie zwrócił żadnych utworów',
			'music.noAudioUrl' => ({required Object track}) => 'Brak dostępnego adresu URL audio dla utworu ${track}',
			'music.discography.singlesAndEps' => 'Single i EP',
			'music.discography.live' => 'Na żywo',
			'music.discography.compilations' => 'Kompilacje',
			'watchTogether.title' => 'Oglądaj razem',
			'watchTogether.description' => 'Oglądaj treści wspólnie z rodziną i znajomymi dzięki synchronizacji odtwarzania',
			'watchTogether.createRoom' => 'Utwórz pokój',
			'watchTogether.creatingRoom' => 'Tworzenie pokoju...',
			'watchTogether.joinRoom' => 'Dołącz do pokoju',
			'watchTogether.joiningRoom' => 'Dołączanie do pokoju...',
			'watchTogether.connecting' => 'Łączenie...',
			'watchTogether.relayPublic' => 'Pokoje korzystają z publicznych serwerów pośredniczących Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Pokoje korzystają z Twojego serwera pośredniczącego: ${url}.',
			'watchTogether.recentRooms' => 'Ostatnie pokoje',
			'watchTogether.roomActions' => 'Akcje pokoju',
			'watchTogether.renameRoom' => 'Zmień nazwę pokoju',
			'watchTogether.removeRoom' => 'Usuń',
			'watchTogether.enterRoomCode' => 'Wpisz 6-znakowy kod otrzymany od gospodarza.',
			'watchTogether.roomCode' => 'Kod pokoju',
			'watchTogether.paste' => 'Wklej',
			'watchTogether.noCodeInClipboard' => 'Schowek nie zawiera kodu pokoju',
			'watchTogether.copyCode' => 'Kopiuj kod',
			'watchTogether.codeCopied' => 'Skopiowano kod pokoju',
			'watchTogether.shareInvite' => 'Udostępnij zaproszenie',
			'watchTogether.inviteCopied' => 'Skopiowano zaproszenie. Wklej je do wiadomości.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Dołącz do mojego pokoju „Oglądaj razem” w PlezyNG: otwórz „Oglądaj razem”, wybierz „Dołącz do pokoju” i wpisz kod ${code}.',
			'watchTogether.openSessionControls' => 'Otwórz sterowanie sesją „Oglądaj razem”',
			'watchTogether.reconnecting' => 'Ponowne łączenie...',
			'watchTogether.reconnectingDescription' => 'Połączenie zostało przerwane. Ponowne dołączenie do pokoju nastąpi automatycznie.',
			'watchTogether.connected' => 'Połączono',
			'watchTogether.disconnected' => 'Rozłączono',
			'watchTogether.youAreHost' => 'Jesteś gospodarzem',
			'watchTogether.hostedBy' => ({required Object name}) => 'Gospodarz: ${name}',
			'watchTogether.hostControlsPlayback' => 'Gospodarz steruje odtwarzaniem',
			'watchTogether.anyoneCanControl' => 'Każdy może sterować odtwarzaniem',
			'watchTogether.roomLocked' => 'Pokój zablokowany',
			'watchTogether.nowPlaying' => 'Teraz odtwarzane',
			'watchTogether.nothingPlaying' => 'Nic nie jest odtwarzane',
			'watchTogether.nothingPlayingHost' => 'Odtwórz coś z dowolnej biblioteki, aby udostępnić to w pokoju.',
			'watchTogether.nothingPlayingGuest' => 'Gdy gospodarz coś włączy, pojawi się to tutaj.',
			'watchTogether.notShareable' => 'To wideo nie ma odpowiednika w katalogu, więc mogą je odtworzyć tylko osoby z dostępem do tego samego serwera.',
			'watchTogether.searching' => 'Szukanie tego wideo w Twoich bibliotekach...',
			'watchTogether.yourCopy' => 'Twoja kopia',
			'watchTogether.sharingYourCopy' => 'Udostępniasz swoją kopię',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Odtwarzanie Twojej kopii · ${difference}',
			'watchTogether.mismatchTitle' => 'Twoja kopia ma inną długość',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Twoja najbliższa kopia jest ${difference} od wideo w pokoju. Może to być inna wersja montażowa lub inne wydanie.',
			'watchTogether.playAnyway' => 'Odtwórz mimo to',
			'watchTogether.chooseAnotherCopy' => 'Wybierz inną kopię',
			'watchTogether.dontPlay' => 'Nie odtwarzaj',
			'watchTogether.unavailableTitle' => 'Nie masz tego wideo',
			'watchTogether.unavailableDescription' => 'PlezyNG nie znalazło go w Twoich bibliotekach. Wybierz kopię samodzielnie lub wyszukaj ponownie.',
			'watchTogether.chooseCopy' => 'Wybierz kopię',
			'watchTogether.searchAgain' => 'Szukaj ponownie',
			'watchTogether.noCandidates' => 'Nie znaleziono żadnych kopii w Twoich bibliotekach.',
			'watchTogether.choiceFailed' => 'Nie udało się odtworzyć tej kopii w pokoju',
			'watchTogether.lengthLonger' => ({required Object duration}) => 'o ${duration} dłuższa',
			'watchTogether.lengthShorter' => ({required Object duration}) => 'o ${duration} krótsza',
			'watchTogether.lengthSame' => 'Ta sama długość',
			'watchTogether.lengthUnknown' => 'Nieznana długość',
			'watchTogether.joinCurrentPlayback' => 'Dołącz do bieżącego odtwarzania',
			'watchTogether.joinCurrentPlaybackDescription' => 'Wróć do treści oglądanej obecnie przez gospodarza',
			'watchTogether.stopMedia' => 'Zatrzymaj wideo dla wszystkich',
			'watchTogether.syncOffset' => 'Przesunięcie synchronizacji',
			'watchTogether.syncOffsetDescription' => 'Przesuń swoje wideo, jeśli wyprzedza odtwarzanie w pokoju lub za nim pozostaje.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Twoja kopia jest ${difference} od wideo w pokoju.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Zastosuj ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Uczestnicy',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestnik', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestnicy', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestników', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uczestnika', ), 
			'watchTogether.hostBadge' => 'GOSPODARZ',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (Ty)',
			'watchTogether.playerIdle' => 'Bezczynny',
			'watchTogether.playerLoading' => 'Ładowanie',
			'watchTogether.playerReady' => 'Gotowy',
			'watchTogether.playerBuffering' => 'Buforowanie',
			'watchTogether.matchSearching' => 'Wyszukiwanie',
			'watchTogether.matchMatched' => 'Ma wideo',
			'watchTogether.matchMismatched' => 'Inna długość',
			'watchTogether.matchUnavailable' => 'Nie ma wideo',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Przesunięcie ${offset}',
			'watchTogether.makeHost' => 'Uczyń gospodarzem',
			'watchTogether.makeHostQuestion' => 'Przekazać rolę gospodarza?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} będzie sterować odtwarzaniem i prowadzić sesję dla wszystkich.',
			'watchTogether.transfer' => 'Przekaż',
			'watchTogether.removeParticipant' => 'Usuń z pokoju',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Usunąć ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} opuści pokój. Ta osoba może dołączyć ponownie za pomocą kodu, chyba że zablokujesz pokój.',
			'watchTogether.remove' => 'Usuń',
			'watchTogether.roomSettings' => 'Ustawienia pokoju',
			'watchTogether.letEveryoneControl' => 'Pozwól wszystkim sterować odtwarzaniem',
			'watchTogether.lockRoom' => 'Zablokuj pokój',
			'watchTogether.lockRoomDescription' => 'Nikt nowy nie może dołączyć',
			'watchTogether.leaveRoom' => 'Opuść pokój',
			'watchTogether.leaveRoomQuestion' => 'Opuścić pokój?',
			'watchTogether.leaveRoomConfirm' => 'Możesz dołączyć ponownie, używając kodu pokoju.',
			'watchTogether.leave' => 'Opuść',
			'watchTogether.endRoom' => 'Zamknij pokój',
			'watchTogether.endRoomQuestion' => 'Zamknąć pokój?',
			'watchTogether.endRoomConfirm' => 'Pokój zostanie zamknięty dla wszystkich.',
			'watchTogether.end' => 'Zakończ',
			'watchTogether.playBlockedTitle' => 'Odtwarzanie się nie rozpoczęło',
			'watchTogether.playBlockedDescription' => 'Naciśnij Odtwórz, aby oglądać razem z innymi w pokoju.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} uruchomił odtwarzanie',
			'watchTogether.notices.playbackStarted' => 'Odtwarzanie rozpoczęte',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} wstrzymał',
			'watchTogether.notices.playbackPaused' => 'Odtwarzanie wstrzymane',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} przeskoczył do ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Przeskoczono do ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} ustawił prędkość na ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Prędkość ustawiona na ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} włączył ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Teraz odtwarzane: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} zatrzymał wideo',
			'watchTogether.notices.mediaStopped' => 'Wideo zostało zatrzymane',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Oczekiwanie na ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Oczekiwanie, aż ktoś nadąży...',
			'watchTogether.notices.finished' => 'Zakończono',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} jest teraz gospodarzem',
			'watchTogether.notices.youAreNowHost' => 'Jesteś teraz gospodarzem',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} dołączył',
			'watchTogether.notices.left' => ({required Object name}) => '${name} opuścił',
			'watchTogether.notices.controlRefused' => 'Tylko gospodarz może sterować odtwarzaniem',
			'watchTogether.notices.searchFailed' => 'Nie udało się przeszukać niektórych serwerów pod kątem wideo z pokoju',
			'watchTogether.notices.playBlocked' => 'Naciśnij Odtwórz, aby rozpocząć',
			'watchTogether.notices.shareFailed' => 'Nie udało się udostępnić tego wideo w pokoju',
			'watchTogether.notices.downloadNotShared' => 'Pobrania nie są udostępniane w pokoju, gdy ich serwer jest offline',
			'watchTogether.notices.openFailed' => 'Nie udało się otworzyć wideo z pokoju',
			'watchTogether.ended.ended' => 'Gospodarz zamknął pokój',
			'watchTogether.ended.kicked' => 'Usunięto Cię z pokoju',
			'watchTogether.ended.expired' => 'Pokój wygasł',
			'watchTogether.ended.replaced' => 'Dołączono do tego pokoju z innego urządzenia',
			'watchTogether.ended.lost' => 'Utracono połączenie z pokojem',
			'watchTogether.errors.invalidCode' => 'To nie jest kod pokoju. Kod składa się z 6 liter i cyfr, z pominięciem 0, 1, I, L i O.',
			'watchTogether.errors.roomNotFound' => 'Nie ma pokoju o tym kodzie. Mógł już zostać zamknięty.',
			'watchTogether.errors.roomFull' => 'Ten pokój jest pełny.',
			'watchTogether.errors.roomLocked' => 'Gospodarz zablokował ten pokój.',
			'watchTogether.errors.relayFull' => 'Funkcja „Oglądaj razem” jest teraz przeciążona. Spróbuj ponownie później.',
			'watchTogether.errors.unreachable' => 'Nie udało się połączyć z serwerem pośredniczącym funkcji „Oglądaj razem”. Sprawdź połączenie.',
			'watchTogether.errors.rateLimited' => 'Zbyt wiele prób. Poczekaj chwilę i spróbuj ponownie.',
			'watchTogether.errors.clientBlocked' => 'Ta wersja PlezyNG nie może korzystać z serwera pośredniczącego. Zaktualizuj aplikację.',
			'watchTogether.errors.forbidden' => 'Tylko gospodarz może to zrobić.',
			'watchTogether.errors.notInRoom' => 'Nie jesteś w pokoju.',
			'watchTogether.errors.alreadyInRoom' => 'Jesteś już w pokoju.',
			'watchTogether.errors.resumeFailed' => 'Nie udało się ponownie dołączyć do pokoju.',
			'watchTogether.errors.unsupported' => 'Serwer pośredniczący tego nie obsługuje.',
			'watchTogether.errors.generic' => 'Coś poszło nie tak. Spróbuj ponownie.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Odcinek ${number}',
			'downloads.title' => 'Pobrania',
			'downloads.manage' => 'Zarządzaj',
			'downloads.tvShows' => 'Seriale TV',
			'downloads.movies' => 'Filmy',
			'downloads.music' => 'Muzyka',
			'downloads.tracksQueued' => ({required Object count}) => '${count} utworów w kolejce do pobrania',
			'downloads.noDownloads' => 'Brak pobrań',
			'downloads.noDownloadsDescription' => 'Pobrane treści pojawią się tutaj do oglądania offline',
			'downloads.downloadNow' => 'Pobierz',
			'downloads.deleteDownload' => 'Usuń pobranie',
			'downloads.retryDownload' => 'Ponów pobieranie',
			'downloads.downloadQueued' => 'Pobranie w kolejce',
			'downloads.downloadResumed' => 'Pobieranie wznowione',
			'downloads.serverErrorBitrate' => 'Błąd serwera: plik może przekraczać zdalny limit bitrate',
			'downloads.storageFull' => 'Pobieranie zostało zatrzymane, aby chronić wolne miejsce. Zwolnij miejsce lub wybierz inną lokalizację pobierania, a następnie spróbuj ponownie.',
			'downloads.storageUnavailable' => 'Pobieranie zostało zatrzymane, ponieważ nie można sprawdzić dostępnego miejsca. Sprawdź lokalizację pobierania i spróbuj ponownie.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} odcinków w kolejce pobierania',
			'downloads.downloadDeleted' => 'Pobranie usunięte',
			'downloads.deleteConfirm' => ({required Object title}) => 'Usunąć "${title}" z tego urządzenia?',
			'downloads.deleteCollectionDownloads' => 'Usuń pobrania',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Usunąć z tego urządzenia wszystkie pobrania z „${title}”?',
			'downloads.collectionDownloadsDeleted' => 'Pobrania usunięte',
			'downloads.cancelledDownloadTitle' => 'Anulowane pobieranie',
			'downloads.cancelledDownloadMessage' => 'To pobieranie zostało anulowane. Co chcesz zrobić?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Wszystkie odcinki są już pobrane',
			'downloads.resumeDownload' => 'Wznów pobieranie',
			'downloads.cancelledDownload' => 'Anulowane pobieranie',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (synchronizowanie ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Pobrano ${file} — kliknij, aby dokończyć',
			'downloads.partialDownloadClickToComplete' => 'Pobrano częściowo — kliknij, aby dokończyć',
			'downloads.deleting' => 'Usuwanie...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Usuwanie ${title}... (${current} z ${total})',
			'downloads.queuedTooltip' => 'W kolejce',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'W kolejce: ${files}',
			'downloads.downloadingTooltip' => 'Pobieranie...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Pobieranie ${files}',
			'downloads.noDownloadsTree' => 'Brak pobrań',
			'downloads.pauseAll' => 'Wstrzymaj wszystko',
			'downloads.resumeAll' => 'Wznów wszystko',
			'downloads.retryAll' => 'Ponów wszystkie',
			'downloads.retryFailed' => 'Ponów nieudane pobrania',
			'downloads.deleteAll' => 'Usuń wszystko',
			'downloads.selectVersion' => 'Wybierz wersję',
			'downloads.allEpisodes' => 'Wszystkie odcinki',
			'downloads.unwatchedOnly' => 'Tylko nieobejrzane',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Następne ${count} nieobejrzanych',
			'downloads.customAmount' => 'Własna liczba...',
			_ => null,
		} ?? switch (path) {
			'downloads.customAmountAny' => 'Wskaźnik (w każdym z nich)',
			'downloads.randomEpisodes' => 'Randomowe epizody',
			'downloads.includeSpecials' => 'Uwzględnij odcinki specjalne',
			'downloads.howManyEpisodes' => 'Ile odcinków?',
			'downloads.invalidEpisodeCount' => 'Wprowadź prawidłową liczbę odcinków.',
			'downloads.keepSynced' => 'Synchronizuj na bieżąco',
			'downloads.downloadOnce' => 'Pobierz raz',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Zachowaj ${count} nieobejrzanych',
			'downloads.editSyncRule' => 'Edytuj regułę synchronizacji',
			'downloads.removeSyncRule' => 'Usuń regułę synchronizacji',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Zatrzymać synchronizację "${title}"? Pobrane odcinki zostaną zachowane.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Zatrzymać synchronizację "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'Usuń również powiązane pobrania',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Pobrania używane przez inną regułę synchronizacji lub profil zostaną zachowane.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Reguła synchronizacji utworzona — zachowywanie ${count} nieobejrzanych odcinków',
			'downloads.syncRuleUpdated' => 'Reguła synchronizacji zaktualizowana',
			'downloads.syncRuleRemoved' => 'Reguła synchronizacji usunięta',
			'downloads.syncRuleAndDownloadsRemoved' => 'Usunięto regułę synchronizacji i powiązane pobrania',
			'downloads.syncRuleCleanupBusy' => 'Reguły synchronizacji są aktualnie aktualizowane. Spróbuj ponownie za chwilę.',
			'downloads.syncRuleCleanupUnavailable' => 'Nie udało się bezpiecznie zidentyfikować powiązanych pobrań. Połącz się ponownie z serwerem i spróbuj ponownie albo usuń regułę bez usuwania pobrań.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Zsynchronizowano ${count} nowych odcinków dla ${title}',
			'downloads.syncNow' => 'Synchronizacja teraz',
			'downloads.downloadsUpToDate' => 'Pobieranie jest aktualne',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync komplet · ${queued} queued, ${removed} usunięte',
			'downloads.activeSyncRules' => 'Reguły synchronizacji',
			'downloads.reviewOrphanFiles' => 'Sprawdź pobrania bez wpisu',
			'downloads.orphanReviewTitle' => 'Sprawdź pobrania bez wpisu',
			'downloads.orphanReviewDescription' => 'Te oznaczone pliki znajdują się w domyślnych folderach pobierania zarządzanych przez aplikację PlezyNG, ale nie mają pasującego wpisu pobrania ani aktywnego zadania. Sprawdź listę przed ich usunięciem.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => 'Liczba plików: ${count} · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Usuń pliki: ${count}',
			'downloads.orphanCleanupNone' => 'Nie znaleziono osieroconych plików do pobrania',
			'downloads.orphanCleanupFailed' => 'PlezyNG nie może bezpiecznie przeskanować zarządzanego folderu pobierania. Żadne pliki nie zostały usunięte.',
			'downloads.orphanCleanupChanged' => 'Lista pobrań zmieniła się podczas przeglądania. Sprawdź pliki ponownie przed czyszczeniem.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Usunięto ${count} osieroconych plików · zwolniono ${size}',
			'downloads.noSyncRules' => 'Brak reguł synchronizacji',
			'downloads.manageSyncRule' => 'Zarządzaj synchronizacją',
			'downloads.editEpisodeCount' => 'Liczba odcinków',
			'downloads.editSyncFilter' => 'Filtr synchronizacji',
			'downloads.syncAllItems' => 'Synchronizacja wszystkich elementów',
			'downloads.syncUnwatchedItems' => 'Synchronizacja nieobejrzanych elementów',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Serwer: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Dostępne',
			'downloads.syncRuleOffline' => 'Brak połączenia',
			'downloads.syncRuleSignInRequired' => 'Wymagane logowanie',
			'downloads.syncRuleAccessDenied' => 'Odmowa dostępu',
			'downloads.syncRuleNotAvailableForProfile' => 'Niedostępne dla bieżącego profilu',
			'downloads.syncRuleUnknownServer' => 'Nieznany serwer',
			'downloads.syncRuleListCreated' => 'Utworzono regułę synchronizacji',
			'downloads.backgroundWarning.bannerBlocked' => 'Po opuszczeniu aplikacji pobieranie zostanie zatrzymane',
			'downloads.backgroundWarning.bannerDegraded' => 'Pobieranie w tle może być ograniczone',
			'downloads.backgroundWarning.bannerAction' => 'Szczegóły',
			'downloads.backgroundWarning.sheetTitle' => 'Pobieranie w tle jest zablokowane',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Pobieranie w tle może być ograniczone',
			'downloads.backgroundWarning.sheetIntro' => 'Android uniemożliwia PlezyNG niezawodne pobieranie plików w tle.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Twoje urządzenie ogranicza możliwość pobierania w tle przez PlezyNG.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Działanie PlezyNG w tle jest ograniczone. Ustaw użycie baterii lub działanie w tle na „Bez ograniczeń”.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android umieścił PlezyNG w ograniczonym trybie gotowości. Ustaw użycie baterii na „Bez ograniczeń”.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Powiadomienia o pobieraniu są wyłączone, więc postęp i opcje sterowania mogą być niedostępne.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Powiadomienia są wyłączone. W Android 13 lub nowszym są wymagane przy długim pobieraniu w tle.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Oszczędzanie danych jest włączone, co blokuje pobieranie w tle przez mobilną transmisję danych. Pobieranie powinno nadal działać przez Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Pobieranie wielokrotnie przerywało się, gdy PlezyNG działało w tle. Sprawdź ustawienia baterii lub działania w tle dla PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Otwórz ustawienia',
			'downloads.backgroundWarning.stillNotWorking' => 'Pomoc dla Twojego urządzenia',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Zobacz instrukcje dla swojego urządzenia lub, jeśli problem nadal występuje, wyślij log przez Ustawienia › Pokaż logi.',
			'downloads.backgroundWarning.dialogTitle' => 'Pobieranie może się nie zakończyć',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Pobierz mimo to',
			'downloads.backgroundWarning.dialogFixFirst' => 'Najpierw rozwiąż problem',
			'downloads.backgroundWarning.statusTile' => 'Pobieranie w tle',
			'downloads.backgroundWarning.statusOk' => 'Działanie w tle jest dozwolone',
			'downloads.backgroundWarning.statusBlocked' => 'Zablokowane przez ustawienia systemu',
			'downloads.backgroundWarning.statusDegraded' => 'Ograniczone przez ustawienia systemu',
			'downloads.backgroundWarning.statusUnknown' => 'Jeszcze nie sprawdzono',
			'downloads.backgroundWarning.settingsUnavailable' => 'Nie udało się otworzyć ustawień systemowych na tym urządzeniu',
			'downloads.backgroundWarning.linkUnavailable' => 'Nie udało się otworzyć dontkillmyapp.com na tym urządzeniu',
			'downloads.options' => 'Opcje pobrań',
			'downloads.groupings.library' => 'Biblioteka',
			'downloads.groupings.collections' => 'Kolekcje',
			'downloads.unknownLibrary' => 'Nieznana biblioteka',
			'downloads.unknownShow' => 'Nieznany serial',
			'downloads.unknownSeason' => 'Nieznany sezon',
			'downloads.unknownAlbum' => 'Nieznany album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => 'Ukończono ${completed}/${total}',
			'downloads.storageUsed' => ({required Object size}) => 'Używany magazyn: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobrany plik', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobrane pliki', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobranych plików', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} pobranych plików', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serial', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriale', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriali', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriali', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmy', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmów', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmów', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albumy', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albumów', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albumów', ), 
			'downloads.errorFileNotFound' => 'Nie znaleziono pliku (404)',
			'downloads.errorDownloadNotAllowed' => 'Serwer nie zezwala na pobieranie (403)',
			'downloads.errorDownloadFailed' => 'Pobieranie nie powiodło się',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Pobieranie nie powiodło się: ${reason}',
			'downloads.convertingOnServer' => 'Konwersja na serwer...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Konwersja na serwer · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Pobieranie nie powiodło się (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Przetwarzanie końcowe nie powiodło się: ${reason}',
			'downloads.reasonFileNotSaved' => 'nie udało się zapisać pliku na tym urządzeniu',
			'downloads.reasonCannotResume' => 'nie udało się wznowić częściowego pobierania',
			'downloads.reasonDeviceStorageFull' => 'na tym urządzeniu zabrakło miejsca',
			'downloads.notificationDownloading' => 'Pobieranie...',
			'downloads.notificationComplete' => 'Pobieranie zakończone',
			'downloads.notificationPaused' => 'Pobieranie wstrzymane',
			'shaders.title' => 'Shadery',
			'shaders.noShaderDescription' => 'Bez ulepszenia wideo',
			'shaders.nvscalerDescription' => 'Skalowanie obrazu NVIDIA dla ostrzejszego wideo',
			'shaders.artcnnVariantNeutral' => 'Neutralny',
			'shaders.artcnnVariantDenoise' => 'Odszumianie',
			'shaders.artcnnVariantDenoiseSharpen' => 'Odszumianie + wyostrzanie',
			'shaders.qualityFast' => 'Szybki',
			'shaders.qualityHQ' => 'Wysoka jakość',
			'shaders.mode' => 'Tryb',
			'shaders.importShader' => 'Importuj shader',
			'shaders.customShaderDescription' => 'Niestandardowy shader GLSL',
			'shaders.shaderImported' => 'Shader zaimportowany',
			'shaders.shaderImportFailed' => 'Nie udało się zaimportować shadera',
			'shaders.deleteShader' => 'Usuń shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Usunąć "${name}"?',
			'companionRemote.title' => 'Pilot',
			'companionRemote.connectedTo' => ({required Object name}) => 'Połączono z ${name}',
			'companionRemote.unknownDevice' => 'Nieznane urządzenie',
			'companionRemote.session.startingServer' => 'Uruchamianie serwera zdalnego...',
			'companionRemote.session.hostAddress' => 'Adres hosta',
			'companionRemote.session.connected' => 'Połączono',
			'companionRemote.session.serverRunning' => 'Serwer zdalny aktywny',
			'companionRemote.session.serverStopped' => 'Serwer zdalny zatrzymany',
			'companionRemote.session.serverRunningDescription' => 'Urządzenia mobilne w Twojej sieci mogą łączyć się z tą aplikacją',
			'companionRemote.session.serverStoppedDescription' => 'Uruchom serwer, aby umożliwić połączenie urządzeń mobilnych',
			'companionRemote.session.usePhoneToControl' => 'Użyj urządzenia mobilnego, aby sterować tą aplikacją',
			'companionRemote.session.startServer' => 'Uruchom serwer',
			'companionRemote.session.stopServer' => 'Zatrzymaj serwer',
			'companionRemote.session.minimize' => 'Minimalizuj',
			'companionRemote.session.manualAddressHint' => 'Ręczny adres połączenia:',
			'companionRemote.pairing.discoveryDescription' => 'Urządzenia PlezyNG z tym samym kontem Plex pojawią się tutaj',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Łączenie...',
			'companionRemote.pairing.searchingForDevices' => 'Szukanie urządzeń...',
			'companionRemote.pairing.noDevicesFound' => 'Nie znaleziono urządzeń w sieci',
			'companionRemote.pairing.noDevicesHint' => 'Otwórz PlezyNG na komputerze i połącz oba urządzenia z tą samą siecią Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dostępne urządzenia',
			'companionRemote.pairing.manualConnection' => 'Połączenie ręczne',
			'companionRemote.pairing.cryptoInitFailed' => 'Nie udało się uruchomić bezpiecznego połączenia. Najpierw zaloguj się do Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Wprowadź adres hosta',
			'companionRemote.pairing.validationHostFormat' => 'Format musi być IP:port (np. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Limit czasu połączenia. Użyj tej samej sieci na obu urządzeniach.',
			'companionRemote.pairing.sessionNotFound' => 'Nie znaleziono urządzenia. Upewnij się, że PlezyNG działa na hoście.',
			'companionRemote.pairing.authFailed' => 'Uwierzytelnianie nie powiodło się. Oba urządzenia muszą używać tego samego konta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Nie udało się połączyć: ${error}',
			'companionRemote.pairing.codeTitle' => 'Kod parowy',
			'companionRemote.pairing.codeDescription' => 'Wprowadź kod wyświetlany w programie Companion Remote na urządzeniu hostowym. Oba urządzenia muszą używać wersji, która wspiera bezpieczne parowanie.',
			'companionRemote.pairing.codeInvalid' => 'Wprowadź wszystkie 32 litery i liczby z kodu gospodarza.',
			'companionRemote.pairing.updateRequired' => 'Aktualizuj oba urządzenia do wersji, która obsługuje bezpieczne parowanie.',
			'companionRemote.pairing.hostDescription' => 'Wprowadź ten kod raz na każdym zdalnym. utrzymaj go prywatny: daje kontrolę nad tym profilem.',
			'companionRemote.pairing.resetCode' => 'Odtwarzanie kodu parowego',
			'companionRemote.pairing.resetDescription' => 'Wyłącz wszystkie odłączniki i utworz nowy kod. Każdy odłącznik będzie musiał ponownie parować.',
			'companionRemote.remote.disconnectConfirm' => 'Czy chcesz się rozłączyć od sesji zdalnej?',
			'companionRemote.remote.reconnecting' => 'Ponowne łączenie...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Próba ${current} z 5',
			'companionRemote.remote.retryNow' => 'Ponów teraz',
			'companionRemote.remote.tabRemote' => 'Pilot',
			'companionRemote.remote.tabPlay' => 'Odtwórz',
			'companionRemote.remote.tabMore' => 'Więcej',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Nawigacja',
			'companionRemote.remote.tabDiscover' => 'Odkryj',
			'companionRemote.remote.tabLibraries' => 'Biblioteki',
			'companionRemote.remote.tabSearch' => 'Szukaj',
			'companionRemote.remote.tabDownloads' => 'Pobrania',
			'companionRemote.remote.tabSettings' => 'Ustawienia',
			'companionRemote.remote.previous' => 'Poprzedni',
			'companionRemote.remote.playPause' => 'Odtwórz/wstrzymaj',
			'companionRemote.remote.next' => 'Następny',
			'companionRemote.remote.seekBack' => 'Przewiń wstecz',
			'companionRemote.remote.stop' => 'Zatrzymaj',
			'companionRemote.remote.seekForward' => 'Przewiń w przód',
			'companionRemote.remote.volume' => 'Głośność',
			'companionRemote.remote.volumeDown' => 'Ciszej',
			'companionRemote.remote.volumeUp' => 'Głośniej',
			'companionRemote.remote.fullscreen' => 'Pełny ekran',
			'companionRemote.remote.subtitles' => 'Napisy',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Szukaj na komputerze...',
			'companionRemote.errors.noNetworkInterface' => 'Nie znaleziono interfejsu sieciowego',
			'companionRemote.errors.authenticationFailed' => 'Uwierzytelnianie nie powiodło się',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Nie udało się uruchomić serwera zdalnego: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Nie udało się wysłać polecenia zdalnego: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Upłynął limit czasu dołączania do sesji',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Nie udało się połączyć z żadnym adresem',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Połączenie utracone po ${attempts} próbach',
			'companionRemote.errors.connectionLost' => 'Połączenie utracone',
			'companionRemote.closedBeforeAuth' => 'Połączenie zostało zamknięte przed uwierzytelnieniem',
			'videoSettings.playbackSpeed' => 'Prędkość odtwarzania',
			'videoSettings.normalSpeed' => 'Normalna',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktywny (${duration})',
			'videoSettings.zoom' => 'Powiększenie',
			'videoSettings.sleepTimer' => 'Wyłącznik czasowy',
			'videoSettings.audioSync' => 'Synchronizacja audio',
			'videoSettings.subtitleSync' => 'Synchronizacja napisów',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR nie jest tutaj dostępny — ten kompozytor pulpitu lub wyjście wideo nie może go przesyłać.',
			'videoSettings.hdrToneMapping' => 'Mapowanie tonów HDR',
			'videoSettings.hdrToneMappingCompositor' => 'Kompozytor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Przekazuj metadane HDR źródła bez zmian i pozwól kompozytorowi pulpitu je zmapować.',
			'videoSettings.hdrToneMappingPlayer' => 'Odtwarzacz',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Mapuj w odtwarzaczu do szczytowej jasności wyświetlacza, a następnie przekaż kompozytorowi informację o wyniku.',
			'videoSettings.hdrToneMappingFailed' => 'Nie udało się zmienić mapowania tonów HDR — poprzedni tryb nadal jest aktywny.',
			'videoSettings.audioOutput' => 'Wyjście audio',
			'videoSettings.performanceOverlay' => 'Nakładka wydajności',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Przestrzenny',
			'videoSettings.audioOutputSpatial' => 'Dźwięk przestrzenny',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio równowartość',
			'videoSettings.audioEqualizerDescription' => 'Dostępne na numerze mpv; aktywny EQ decoduje dźwięk i odłączają pasterz.',
			'videoSettings.audioEqualizerFlat' => 'płaski',
			'videoSettings.audioEqualizerActive' => 'Własny',
			'videoSettings.audioEqualizerSaveFailed' => 'Nie mogła zaoszczędzić ustawień audio równanie.',
			'videoSettings.backgroundVideoAudio' => 'Audio wideo',
			'videoSettings.backgroundVideoAudioDescription' => 'Utrzymuj odtwarzanie audio wideo, gdy opuszczasz odtwarzacza; obraz jest ukryty, aż wrócisz. Android wykorzystuje powiadomienie o odtwarzaniu mediów.',
			'videoSettings.audioNormalization' => 'Normalizacja głośności',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Dekoduje dźwięk do PCM; przekazywanie jest wyłączone, gdy ta opcja jest włączona',
			'performanceOverlay.color' => 'Kolor',
			'performanceOverlay.performance' => 'Wydajność',
			'performanceOverlay.buffer' => 'Bufor',
			'performanceOverlay.app' => 'Aplikacja',
			'performanceOverlay.decoder' => 'Dekoder',
			'performanceOverlay.rawDecoder' => 'Surowy dekoder',
			'performanceOverlay.tunneling' => 'Tunelowanie',
			'performanceOverlay.passthrough' => 'Przekazywanie',
			'performanceOverlay.aspect' => 'Proporcje',
			'performanceOverlay.rotation' => 'Obrót',
			'performanceOverlay.dvSource' => 'Źródło DV',
			'performanceOverlay.dvPath' => 'Ścieżka DV',
			'performanceOverlay.dvRouteDecoder' => 'Dekoder Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'Dekoder Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Warstwa bazowa',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'Warstwa bazowa HDR10',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Warstwa bazowa HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Warstwa bazowa SDR',
			'performanceOverlay.dvRouteReshaped' => 'Przekształcenie RPU (gpu-next)',
			'performanceOverlay.p7Conversion' => 'Konw. P7',
			'performanceOverlay.sampleRate' => 'Częstotliwość próbkowania',
			'performanceOverlay.pixelFormat' => 'Format pikseli',
			'performanceOverlay.hwFormat' => 'Format HW',
			'performanceOverlay.matrix' => 'Macierz',
			'performanceOverlay.primaries' => 'Barwy podstawowe',
			'performanceOverlay.transfer' => 'Charakterystyka przenoszenia',
			'performanceOverlay.renderFps' => 'FPS renderowania',
			'performanceOverlay.displayFps' => 'FPS ekranu',
			'performanceOverlay.avSync' => 'Synchronizacja A/V',
			'performanceOverlay.dropped' => 'Pominięte',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'Śr. DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Śr. próbki DV',
			'performanceOverlay.maxLuma' => 'Maks. luma',
			'performanceOverlay.minLuma' => 'Min. luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Użyta pamięć podręczna',
			'performanceOverlay.cacheLimit' => 'Limit pamięci podręcznej',
			'performanceOverlay.speed' => 'Szybkość',
			'performanceOverlay.player' => 'Odtwarzacz',
			'performanceOverlay.playMethod' => 'Metoda gry',
			'performanceOverlay.memory' => 'Pamięć',
			'performanceOverlay.uiFps' => 'FPS interfejsu',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android (sprzętowy)',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA (sprzętowy)',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm (sprzętowy)',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek (sprzętowy)',
			'performanceOverlay.decoderExynosHw' => 'Exynos (sprzętowy)',
			'performanceOverlay.decoderSoftware' => 'Programowy',
			'performanceOverlay.decoderHardware' => 'Sprzętowy',
			'performanceOverlay.tunnelingActive' => 'Aktywne',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (niepowodzenia: ${failures})',
			'externalPlayer.title' => 'Zewnętrzny odtwarzacz',
			'externalPlayer.useExternalPlayer' => 'Użyj zewnętrznego odtwarzacza',
			'externalPlayer.useExternalPlayerDescription' => 'Otwieraj wideo w innej aplikacji',
			'externalPlayer.selectPlayer' => 'Wybierz odtwarzacz',
			'externalPlayer.customPlayers' => 'Niestandardowe odtwarzacze',
			'externalPlayer.systemDefault' => 'Domyślny systemowy',
			'externalPlayer.addCustomPlayer' => 'Dodaj niestandardowy odtwarzacz',
			'externalPlayer.playerName' => 'Nazwa odtwarzacza',
			'externalPlayer.playerNameHint' => 'Mój odtwarzacz',
			'externalPlayer.playerCommand' => 'Polecenie',
			'externalPlayer.playerPackage' => 'Nazwa pakietu',
			'externalPlayer.playerUrlScheme' => 'Schemat URL',
			'externalPlayer.off' => 'Wyłączony',
			'externalPlayer.launchFailed' => 'Nie udało się otworzyć zewnętrznego odtwarzacza',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} nie jest zainstalowany',
			'externalPlayer.playInExternalPlayer' => 'Odtwórz w zewnętrznym odtwarzaczu',
			'metadataEdit.editMetadata' => 'Edytuj...',
			'metadataEdit.screenTitle' => 'Edytuj metadane',
			'metadataEdit.basicInfo' => 'Podstawowe informacje',
			'metadataEdit.artwork' => 'Grafika',
			'metadataEdit.advancedSettings' => 'Ustawienia zaawansowane',
			'metadataEdit.title' => 'Tytuł',
			'metadataEdit.sortTitle' => 'Tytuł do sortowania',
			'metadataEdit.originalTitle' => 'Tytuł oryginalny',
			'metadataEdit.releaseDate' => 'Data premiery',
			'metadataEdit.contentRating' => 'Klasyfikacja wiekowa',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Opis',
			'metadataEdit.poster' => 'Plakat',
			'metadataEdit.background' => 'Tło',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Kwadratowy obraz',
			'metadataEdit.selectPoster' => 'Wybierz plakat',
			'metadataEdit.selectBackground' => 'Wybierz tło',
			'metadataEdit.selectLogo' => 'Wybierz logo',
			'metadataEdit.selectSquareArt' => 'Wybierz kwadratowy obraz',
			'metadataEdit.fromUrl' => 'Z URL',
			'metadataEdit.uploadFile' => 'Prześlij plik',
			'metadataEdit.enterImageUrl' => 'Wprowadź URL obrazu',
			'metadataEdit.imageUrl' => 'URL obrazu',
			'metadataEdit.metadataUpdated' => 'Metadane zaktualizowane',
			'metadataEdit.metadataUpdateFailed' => 'Nie udało się zaktualizować metadanych',
			'metadataEdit.artworkUpdated' => 'Grafika zaktualizowana',
			'metadataEdit.artworkUpdateFailed' => 'Nie udało się zaktualizować grafiki',
			'metadataEdit.noArtworkAvailable' => 'Brak dostępnej grafiki',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opcja grafiki ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opcja grafiki ${index}, wybrana',
			'metadataEdit.notSet' => 'Nie ustawiono',
			'metadataEdit.libraryDefault' => 'Domyślne dla biblioteki',
			'metadataEdit.accountDefault' => 'Domyślne dla konta',
			'metadataEdit.seriesDefault' => 'Domyślne dla serialu',
			'metadataEdit.episodeSorting' => 'Sortowanie odcinków',
			'metadataEdit.oldestFirst' => 'Najstarsze najpierw',
			'metadataEdit.newestFirst' => 'Najnowsze najpierw',
			'metadataEdit.keep' => 'Zachowaj',
			'metadataEdit.allEpisodes' => 'Wszystkie odcinki',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} najnowszych odcinków',
			'metadataEdit.latestEpisode' => 'Najnowszy odcinek',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Odcinki dodane w ciągu ostatnich ${count} dni',
			'metadataEdit.deleteAfterPlaying' => 'Usuń odcinki po odtworzeniu',
			'metadataEdit.never' => 'Nigdy',
			'metadataEdit.afterADay' => 'Po jednym dniu',
			'metadataEdit.afterAWeek' => 'Po tygodniu',
			'metadataEdit.afterAMonth' => 'Po miesiącu',
			'metadataEdit.onNextRefresh' => 'Przy następnym odświeżeniu',
			'metadataEdit.seasons' => 'Sezony',
			'metadataEdit.show' => 'Pokaż',
			'metadataEdit.hide' => 'Ukryj',
			'metadataEdit.episodeOrdering' => 'Kolejność odcinków',
			'metadataEdit.tmdbAiring' => 'The Movie Database (kolejność emisji)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (kolejność emisji)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (numeracja bezwzględna)',
			'metadataEdit.metadataLanguage' => 'Język metadanych',
			'metadataEdit.useOriginalTitle' => 'Użyj oryginalnego tytułu',
			'metadataEdit.preferredAudioLanguage' => 'Preferowany język audio',
			'metadataEdit.preferredSubtitleLanguage' => 'Preferowany język napisów',
			'metadataEdit.subtitleMode' => 'Tryb automatycznego wyboru napisów',
			'metadataEdit.manuallySelected' => 'Wybrany ręcznie',
			'metadataEdit.shownWithForeignAudio' => 'Wyświetlane przy dźwięku w obcym języku',
			'metadataEdit.alwaysEnabled' => 'Zawsze włączone',
			'metadataEdit.tags' => 'Tagi',
			'metadataEdit.addTag' => 'Dodaj tag',
			'metadataEdit.genre' => 'Gatunek',
			'metadataEdit.director' => 'Reżyser',
			'metadataEdit.writer' => 'Scenarzysta',
			'metadataEdit.producer' => 'Producent',
			'metadataEdit.country' => 'Kraj',
			'metadataEdit.collection' => 'Kolekcja',
			'metadataEdit.label' => 'Etykieta',
			'metadataEdit.quickTag' => 'Szybki tag...',
			'matchScreen.match' => 'Dopasuj...',
			'matchScreen.fixMatch' => 'Popraw dopasowanie...',
			'matchScreen.unmatch' => 'Usuń dopasowanie',
			'matchScreen.unmatchConfirm' => 'Usunąć to dopasowanie? Plex będzie traktować element jako niedopasowany, dopóki nie zostanie dopasowany ponownie.',
			'matchScreen.unmatchSuccess' => 'Dopasowanie usunięte',
			'matchScreen.unmatchFailed' => 'Nie udało się usunąć dopasowania',
			'matchScreen.matchApplied' => 'Dopasowanie zastosowane',
			'matchScreen.matchFailed' => 'Nie udało się zastosować dopasowania',
			'matchScreen.titleHint' => 'Tytuł',
			'matchScreen.yearHint' => 'Rok',
			'matchScreen.search' => 'Szukaj',
			'matchScreen.noMatchesFound' => 'Nie znaleziono dopasowań',
			'serverTasks.title' => 'Zadania serwera',
			'serverTasks.failedToLoad' => 'Nie udało się załadować zadań',
			'serverTasks.noTasks' => 'Brak uruchomionych zadań',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Połączono',
			'trakt.connectedAs' => ({required Object username}) => 'Połączono jako @${username}',
			'trakt.disconnectConfirm' => 'Rozłączyć konto Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG przestanie wysyłać zdarzenia do serwisu Trakt. Połączenie można przywrócić w dowolnym momencie.',
			'trakt.scrobble' => 'Śledzenie odtwarzania w czasie rzeczywistym',
			'trakt.scrobbleDescription' => 'Wysyłaj do serwisu Trakt zdarzenia odtwarzania, wstrzymania i zatrzymania.',
			'trakt.watchedSync' => 'Synchronizuj stan obejrzenia',
			'trakt.watchedSyncDescription' => 'Gdy oznaczysz element jako obejrzany w PlezyNG, zostanie on również oznaczony jako obejrzany w serwisie Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Połącz Seerr',
			'seerr.serverUrl' => 'Adres URL serwera',
			'seerr.serverUrlHelper' => 'Adres Twojej instancji Seerr',
			'seerr.checkServer' => 'Kontynuuj',
			'seerr.signInWithJellyfin' => 'Zaloguj się przez Jellyfin',
			'seerr.signInWithEmby' => 'Zaloguj się przez Emby',
			'seerr.signInWithLocal' => 'Użyj konta lokalnego',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Ta instancja Seerr nie oferuje metody logowania obsługiwanej przez PlezyNG.',
			'seerr.instance' => 'Instancja',
			'seerr.disconnectConfirm' => 'Odłączyć Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG zapomni tę instancję Seerr. Połącz ponownie w dowolnym momencie.',
			'seerr.request' => 'Zamów',
			'seerr.request4k' => 'Zamów w 4K',
			'seerr.seasons' => 'Sezony',
			'seerr.allSeasons' => 'Wszystkie sezony',
			'seerr.advancedOptions' => 'Zaawansowane',
			'seerr.destinationServer' => 'Serwer docelowy',
			'seerr.qualityProfile' => 'Profil jakości',
			'seerr.rootFolder' => 'Folder główny',
			'seerr.languageProfile' => 'Profil językowy',
			'seerr.tags' => 'Tagi',
			'seerr.noTags' => 'Brak tagów',
			'seerr.defaultOption' => ({required Object name}) => '${name} (domyślny)',
			'seerr.animeNote' => 'Ten serial jest anime.',
			'seerr.requestSubmitted' => 'Zamówienie wysłane',
			'seerr.requestFailed' => ({required Object error}) => 'Zamówienie nie powiodło się: ${error}',
			'seerr.requestsLoadFailed' => 'Nie udało się wczytać opcji zamówienia',
			'seerr.nothingToRequest' => 'Wszystko jest już dostępne lub zamówione.',
			'seerr.statusAvailable' => 'Dostępne',
			'seerr.statusPartiallyAvailable' => 'Częściowo dostępne',
			'seerr.statusRequested' => 'Zamówione',
			'seerr.statusProcessing' => 'Przetwarzanie',
			'seerr.statusBlocklisted' => 'Na liście blokowanych',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Nie udało się połączyć z ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Pod adresem ${url} nie ma instancji Seerr (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Zamiast Seerr odpowiedział uwierzytelniający reverse proxy (SSO lub uwierzytelnianie HTTP). PlezyNG nie może się przez niego zalogować: pozwól, aby ścieżka /api/v1 Seerr omijała proxy dla tej aplikacji, albo użyj adresu, który dociera do Seerr bezpośrednio.',
			'seerr.invalidUrl' => 'Wprowadź adres serwera, np. https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Ta instancja Seerr nie obsługuje Quick Connect. Wymagany jest Seerr 3.4 lub nowszy.',
			'seerr.notInitialized' => 'Ta instancja Seerr nie ukończyła konfiguracji początkowej',
			'seerr.noPlexTokenForReauth' => 'Brak tokenu Plex umożliwiającego ponowne zalogowanie',
			'seerr.noStoredCredentials' => 'Brak zapisanych danych logowania umożliwiających ponowne zalogowanie',
			'seerr.signInRejected' => 'Logowanie zostało odrzucone',
			'seerr.noSessionCookie' => 'Seerr nie utworzył pliku cookie sesji',
			'seerr.freshCookieRejected' => 'Seerr odrzucił nowy plik cookie sesji',
			'seerr.noUserInformation' => 'Seerr nie zwrócił informacji o użytkowniku',
			'seerr.sessionRejectedAfterReauth' => 'Sesja została odrzucona po ponownym zalogowaniu',
			'seerr.permissionDenied' => 'Seerr odrzucił tę akcję: Twoje konto nie ma już wymaganych uprawnień',
			'seerr.permissionRevoked' => 'Nie masz już uprawnień, aby to zamówić',
			'services.title' => 'Usługi',
			'services.hubSubtitle' => 'Synchronizuj postęp oglądania i zamawiaj nowe tytuły.',
			'services.integrations' => 'Integracje',
			'services.notConnected' => 'Nie połączono',
			'services.connectedAs' => ({required Object username}) => 'Połączono jako @${username}',
			'services.scrobble' => 'Automatycznie śledź postęp',
			'services.scrobbleDescription' => 'Aktualizuj swoją listę po ukończeniu odcinka lub filmu.',
			'services.disconnectConfirm' => ({required Object service}) => 'Odłączyć ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG przestanie aktualizować ${service}. Połącz ponownie w dowolnym momencie.',
			'services.connectFailed' => ({required Object service}) => 'Nie udało się połączyć z ${service}. Spróbuj ponownie.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Połącz ponownie Simkl',
			'services.simklReconnect.subtitle' => 'Simkl wycofuje metodę logowania, z której korzysta to połączenie. Ponowne połączenie otworzy simkl.com, aby zatwierdzić PlezyNG — PlezyNG nigdy nie widzi Twojego hasła. Historia oglądania pozostanie w Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Aktywuj PlezyNG w ${service}',
			'services.deviceCode.instructions' => 'Zeskanuj kod QR albo przejdź pod poniższy adres i wprowadź ten kod:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Otwórz ${service}, aby aktywować',
			'services.deviceCode.copyCode' => 'Skopiuj kod aktywacyjny',
			'services.deviceCode.waitingForAuthorization' => 'Oczekiwanie na autoryzację…',
			'services.deviceCode.codeCopied' => 'Kod skopiowany',
			'services.oauthProxy.title' => ({required Object service}) => 'Zaloguj się do ${service}',
			'services.oauthProxy.body' => 'Zeskanuj ten kod QR lub otwórz URL na dowolnym urządzeniu.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Otwórz ${service}, aby się zalogować',
			'services.pendingAuth.copyUrl' => 'Skopiuj adres URL logowania',
			'services.pendingAuth.urlCopied' => 'URL skopiowany',
			'services.libraryFilter.title' => 'Filtr bibliotek',
			'services.libraryFilter.subtitleAllSyncing' => 'Synchronizowanie wszystkich bibliotek',
			'services.libraryFilter.subtitleNoneSyncing' => 'Brak synchronizowanych bibliotek',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} zablokowanych',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} dozwolonych',
			'services.libraryFilter.mode' => 'Tryb filtra',
			'services.libraryFilter.modeBlacklist' => 'Czarna lista',
			'services.libraryFilter.modeWhitelist' => 'Biała lista',
			'services.libraryFilter.modeHintBlacklist' => 'Synchronizuj wszystkie biblioteki oprócz zaznaczonych poniżej.',
			'services.libraryFilter.modeHintWhitelist' => 'Synchronizuj tylko biblioteki zaznaczone poniżej.',
			'services.libraryFilter.libraries' => 'Biblioteki',
			'services.libraryFilter.noLibraries' => 'Brak dostępnych bibliotek',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Dodaj serwer ${product}',
			'addServer.serverUrls' => 'Adresy URL serwera',
			'addServer.serverUrlsHelper' => 'Można podać wiele adresów URL rozdzielonych przecinkami.',
			'addServer.findServer' => 'Znajdź serwer',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Szukanie lokalnych serwerów ${product}...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Lokalne serwery ${product}',
			'addServer.username' => 'Nazwa użytkownika',
			'addServer.password' => 'Hasło',
			'addServer.signIn' => 'Zaloguj się',
			'addServer.change' => 'Zmień',
			'addServer.required' => 'Wymagane',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Nie udało się połączyć z serwerem: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Logowanie nie powiodło się: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect nie powiodło się: ${error}',
			'addServer.addPlexTitle' => 'Zaloguj się przez Plex',
			'addServer.pinExpired' => 'PIN wygasł przed zalogowaniem. Spróbuj ponownie.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Nie udało się zarejestrować konta: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Podaj adres URL serwera ${product}',
			'addServer.addConnectionTitle' => 'Dodaj połączenie',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Dodaj do ${name}',
			'addServer.signInWithPlexCard' => 'Zaloguj się przez Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autoryzuj to urządzenie. Serwery udostępnione zostaną dodane.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autoryzuj konto Plex. Użytkownicy Home staną się profilami.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Połącz z ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Podaj adres URL serwera, nazwę użytkownika i hasło.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Zaloguj się do serwera ${product}. Powiązane z ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Pożycz z innego profilu',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Użyj połączenia innego profilu. Profile chronione PIN-em wymagają podania PIN-u.',
			'addServer.invalidCredentials' => 'Nieprawidłowa nazwa użytkownika lub hasło',
			'addServer.authResponseNotJson' => 'Odpowiedź uwierzytelniania ma nieprawidłowy format JSON',
			'addServer.authResponseIncomplete' => 'Odpowiedź logowania z serwera była niekompletna',
			'addServer.quickConnectRejected' => 'Quick Connect został odrzucony przez serwer',
			'addServer.quickConnectNotJson' => 'Odpowiedź Quick Connect ma nieprawidłowy format JSON',
			_ => null,
		} ?? switch (path) {
			'addServer.quickConnectMissingFields' => 'W odpowiedzi Quick Connect brakuje kodu lub sekretu',
			'addServer.quickConnectPollRejected' => 'Odpytywanie Quick Connect zostało odrzucone przez serwer',
			'addServer.serverTimedOut' => 'Serwer nie odpowiedział w wymaganym czasie',
			'addServer.responseNotJson' => 'Odpowiedź serwera ma nieprawidłowy format JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'W odpowiedzi brakuje identyfikatora lub nazwy serwera — czy to serwer ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Nie udało się połączyć z serwerem: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Wprowadź co najmniej jeden adres URL serwera ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Nie znaleziono żadnego osiągalnego serwera ${product}',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Te adresy URL wskazują różne serwery ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Ten adres URL nie odpowiada serwerowi ${product}',
			'addServer.redirectUnsupported' => 'Serwer przekierował do nieobsługiwanego adresu URL',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Serwer przekierował do innego hosta. Wprowadź bezpośrednio docelowy adres URL serwera ${product}.',
			'addServer.redirectInsecure' => 'Serwer przekierował z HTTPS do niezabezpieczonego adresu URL',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Serwer przekierował do nieobsługiwanego adresu URL. Wprowadź bezpośrednio docelowy adres URL serwera ${product}.',
			'addServer.directPlexServerUrl' => 'Adres URL serwera Plex',
			'addServer.directPlexServerUrlHelper' => 'Wprowadź lokalny adres IP i port serwera Plex Media Server.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (opcjonalny)',
			'addServer.plexTokenHelper' => 'Pozostaw wolny, jeśli dostęp bez auth jest dozwolony na tym serwerze.',
			'addServer.plexTokenRequired' => 'Wymagane jest autentyfikacja. proszę wpisać swój token Plex (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (w bezpośrednim / lokalnym)',
			'addServer.connectDirectPlexCardSubtitle' => 'Połączyć bezpośrednio za pomocą lokalnego adresu IP lub adresu URL bez konta plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Połączyć bezpośrednio za pomocą lokalnego adresu IP lub adresu URL. Połączyć do ${name}.',
			'addServer.insecureTitle' => 'Niezakrytowane połączenie',
			'addServer.insecureDescription' => ({required Object url}) => '${url} używa HTTP. Inne osoby w sieci mogą odczytać lub zmienić Twoje hasło, tokeny i multimedia. Korzystaj z HTTPS, jeśli jest dostępny. Kontynuuj tylko wtedy, gdy ufasz tej sieci i akceptujesz ryzyko.',
			'addServer.allowHttp' => 'Pozwolenie HTTP',
			'addServer.httpsRequired' => 'Użyj HTTPS lub wyraźnie zezwala na nie szyfrowaną łączność.',
			'watchLink.serverUnavailable' => 'Nie mogłem dotrzeć do serwera Plex dla tego linku.',
			'watchLink.notFound' => 'Nie mogłem znaleźć tego pokazu lub filmu na serwerach Plex.',
			'watchLink.ambiguous' => 'Ten link odpowiada elementom na więcej niż jednym serwerze. dodać serwer do linku.',
			'watchLink.plexOnly' => 'Linky do oglądania obecnie obsługują tylko serwery Plex.',
			'watchLink.unsupportedItem' => 'Linky do oglądania mogą otwierać tylko pokaz lub film.',
			'watchLink.menuItem' => 'Zobacz link',
			'watchLink.dialogTitle' => 'Zobacz link',
			'watchLink.dialogShowHint' => 'Otwierając ten link odtwarzasz następny odcinek. Dodaj &mode=shuffle do końca, aby odtworzyć pokaz na shuffle.',
			'watchLink.dialogMovieHint' => 'Otwierając ten link, gra film.',
			'watchLink.copy' => 'Kopiowanie',
			'watchLink.copied' => 'Link kopiowany',
			'homeLayout.title' => 'Home Layout',
			'homeLayout.resetToast' => 'Home Reset do oryginalnego rozmiaru bohatera Plezy',
			'homeLayout.resetHeroTitle' => 'Znowocześnij rozkład bohatera do magazynu Plezy?',
			'homeLayout.resetHeroBody' => 'Odwróci ustawienie bohatera każdej kolejki i przywraca pojedynczą banerę rotującą na szczycie Domu, tak jak przed istnieniem kolejek bohatera.',
			'homeLayout.removeRowTitle' => 'Odstąpienie domowej kolejki?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} zostanie usunięte. Tej operacji nie można cofnąć.',
			'homeLayout.sync' => 'Synchronizacja',
			'homeLayout.syncAccountTitle' => 'Synchronizuj rozkład z Twoim kontem Plex',
			'homeLayout.syncAccountOn' => 'Na: urządzenie to dzieli się kolejnością, kolejnością, Hero i Auto-slide z innymi urządzeniami.',
			'homeLayout.syncAccountOff' => 'Wyłącz: urządzenie to utrzymuje własny layout.',
			'homeLayout.syncNow' => 'Synchronizacja teraz',
			'homeLayout.plexHomeManager' => 'Plex Zarządca domowy',
			'homeLayout.managePlexRows' => 'Zarządzanie Plex kolejkami w Plezy',
			'homeLayout.managePlexRowsDescription' => 'Otwarte do organizowania domowo wybranych kolejek',
			'homeLayout.organizeHomeRows' => 'Organizuj domowe rzędy',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} rzędy: poruszanie się, Hero, Auto-slide, usunięcie',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Zorganizuj ${library} rzędy',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Kontynuuj oglądanie + ${n} rzędy: ruch, Biblioteka, Dom, Bohater, Auto-slide',
			'homeLayout.renderAsHero' => 'Render jako karta bohatera',
			'homeLayout.heroOnlySingleCollection' => 'Dostępne tylko wtedy, gdy ta kolejka rozstrzyga się na prawdziwe tytuły jednej kolekcji',
			'homeLayout.hero' => 'bohater',
			'homeLayout.autoSlide' => 'Auto-Slide',
			'homeLayout.autoSlideDescription' => 'Wstępy (PC) i d-pad (TV) zawsze działają i ponownie uruchamiają timer.',
			'homeLayout.autoSlideEditDescription' => 'Wyłącz: porusza się tylko wtedy, gdy klikniesz strzałkę (PC) lub naciśnij lewą/prawną stronę na odległej (TV).',
			'homeLayout.enableHeroFirst' => 'Zacznij od bohatera',
			'homeLayout.showOnHome' => 'Wyświetlanie na ekranie domowym',
			'homeLayout.home' => 'Start',
			'homeLayout.removeFromHome' => 'Usuwanie z domu',
			'homeLayout.selectRowsFirst' => 'Wybierz linie domowe poniżej.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex rzędy zarządzane',
			'homeLayout.continueWatching' => 'Kontynuuj oglądanie',
			'homeLayout.continueWatchingLibraryDescription' => 'Biblioteka w tej kolejce własnej rewizji',
			'homeLayout.continueWatchingHomeDescription' => 'Równowaga postępu pokazana na Home',
			'homeLayout.nextUpHomeDescription' => 'Następny niewidziany odcinek kolejka pokazana oddzielnie na Home',
			'homeLayout.library' => 'Biblioteka',
			'homeLayout.showInRecommended' => 'W bibliotece zalecane',
			'homeLayout.customPlexRow' => 'Zestawienie Plex',
			'homeLayout.heroNeedsLibrary' => 'Przeczytaj bibliotekę najpierw – bohater musi gdzieś pokazać',
			'homeLayout.heroNeedsSurface' => 'Przeczytaj bibliotekę lub dom najpierw — Hero potrzebuje gdzieś, aby pokazać',
			'homeLayout.removeHub' => 'Usuń Hub',
			'homeLayout.noPlexRows' => 'Nr Plex rzędy zarządzane powróciły do tej biblioteki.',
			'homeLayout.openDetails' => 'Szczegóły otwarte',
			'homeLayout.heroCards' => 'Karta bohatera',
			'homeLayout.tapHeroCard' => 'Złapanie karty bohatera',
			'homeLayout.tvPlayFocus' => 'Telewizja zdalna: podniesienie przycisku Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad w dół zatrzymuje się na przycisku Play przed przejściem do następnego rzędu.',
			'homeLayout.tvWrap' => 'TV Remote: karty bohaterów',
			'homeLayout.tvWrapDescription' => 'Na ostatniej karcie wraca do pierwszej. wyłącz się na ostatniej karce. Lewa na pierwszej karcie zawsze wraca do bocznej paska.',
			'homeLayout.castOnHero' => 'Zwiastun bohaterów na bannery',
			'homeLayout.castOnHeroDescription' => 'Wyświetla wyciąg wzdłuż dolnej części banera bohatera. wyłączony zachowuje tylko tytuł i podsumowanie.',
			'homeLayout.customRows' => 'Custom Rows - rzędy',
			'homeLayout.loading' => 'Wstęp do lokalizacji domowej...',
			'homeLayout.noCustomRows' => 'Nie ma jeszcze kolejek',
			'homeLayout.addRowHint' => 'Użyj Dodaj kolejkę domową, aby utworzyć jedną.',
			'homeLayout.addHomeRow' => 'Dodaj domowy rzęs',
			'homeLayout.addHomeRowDescription' => 'Wybierz kategorię; nowy pasek zostanie automatycznie dodany do Organizator',
			'homeLayout.removeRow' => 'Usuń kolejkę',
			'homeLayout.recentlyAdded' => 'Ostatnio dodane',
			'homeLayout.recentlyReleased' => 'Niedawno wydane',
			'homeLayout.movieCollections' => 'Filmowe kolekcje',
			'homeLayout.showCollections' => 'Wyświetla kolekcje',
			'homeLayout.rowTitle' => 'Tytuł Row',
			'homeLayout.content' => 'Zawartość',
			'homeLayout.showThisRowIn' => 'Wyświetl tę kolejkę w:',
			'homeLayout.libraryRecommended' => 'Biblioteka zalecana',
			'homeLayout.heroCard' => 'Karta bohaterów',
			'homeLayout.heroCardDescription' => 'Wyświetla się jako jedna karta obrotowa w pełnej szerokości zamiast płyty plakatowej.',
			'homeLayout.heroUnavailableDescription' => 'Dostępne tylko wtedy, gdy ta kolejka rozstrzyga się na prawdziwe tytuły jednej kolekcji – z więcej niż jedną kolekcją wybraną nie ma żadnego tytułu do przechodzenia.',
			'homeLayout.librariesSelection' => 'Biblioteki (zostaw wszystkie nieprzeglądane do włączenia każdej biblioteki)',
			'homeLayout.librariesMergedDescription' => 'Każda biblioteka sprawdzona tutaj jest połączona w tę jedną kolejkę.',
			'homeLayout.movieCollectionsSelection' => 'Kolekcje filmów (zostaw wszystkie nieprzeglądane dla każdej wybranej biblioteki)',
			'homeLayout.showCollectionsSelection' => 'Wyświetlanie kolekcji (zostaw wszystkie nieprzeglądane dla każdej wybranej biblioteki)',
			'homeLayout.collectionRowsDescription' => 'Jeśli dokładnie jedna kolekcja sięga, jej tytuły są wyświetlane bezpośrednio w kolejce. Jeśli więcej niż jedna kolekcja ma miejsce, każda kolekcja jest wyświetlana jako jeden plakat - naciśnij go, aby otworzyć tę kolekcję.',
			'homeLayout.allCollections' => 'Wszystkie kolekcje',
			'homeLayout.noRowsHere' => 'Nie ma tu jeszcze kolejek.',
			'homeLayout.hideWatchedRows' => 'Ukryte przedmioty obserwowane w kolejkach',
			'homeLayout.hideWatchedRowsDescription' => 'Pełnie oglądane tytuły opuszczają Dom i biblioteka Zalecane linie.',
			'homeLayout.untitledCollection' => 'Kolekcja bez tytułu',
			'homeLayout.moveRowHint' => 'Up/Down: przełącz kolejność · Wybierz: oddaj się tutaj · Powrót: odwołanie',
			'homeLayout.organizeRowsHint' => 'Wybierz pozycję kolejką (lub trzymaj pozycję Wybierz pozycja): poruszaj · Lewica/Prawica: opcje kolejki · Powrót: wykonane',
			'homeLayout.layoutNavDescription' => 'Wybierz linie, biblioteki i kategorie kolekcji',
			'homeLayout.editHomeRow' => 'Edit Home Rw',
			'homeLayout.resetHeroButton' => 'Odtworzenie rozmiaru bohatera do magazynu Plezy',
			'homeLayout.reorderingUnlocked' => 'Odblokowanie odblokowane',
			'homeLayout.reorderingLocked' => 'Znowocześnie zamknięte',
			'homeLayout.rowsCanBeDragged' => 'Rury można wyciągnąć – naciśnij zamek, aby zapobiec',
			'homeLayout.tapLockToDrag' => 'Wciśnij zamek, aby wyciągnąć rzędy',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Wskaźnik: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Ukryj',
			'homeLayout.remove' => 'Usuń',
			'homeLayout.libraryResumeRow' => 'Ta biblioteka jest kolejna',
			'homeLayout.pressAgainToDelete' => 'Następny wpisNastępny Następny Nastąpi usunięcie',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'Na',
			'homeLayout.resetHeroButtonDescription' => 'Odwróci ustawienie bohatera każdej kolejki i przywraca pojedynczą banerę do góry, tak jak przed kolejkami bohaterów.',
			'platform.localNetworkPermission' => 'PlezyNG łączy się z serwerami mediów i urządzeniami odtwarzania w sieci lokalnej.',
			'platform.locationPermission' => 'PlezyNG korzysta z dostępu do lokalizacji, gdy iOS wymaga od niego wykrywania sieci lokalnej i połączenia z serwerami mediów.',
			'platform.photoLibraryPermission' => 'Wybierz obrazy z biblioteki zdjęć do wykorzystania jako media artwork.',
			'platform.cameraPermission' => 'Skanowanie kodów QR do pary Companion Remote.',
			'fileSources.title' => 'Archiwum i książki',
			'fileSources.subtitle' => 'Czytaj, słuchaj i obserwuj z własnych plików.',
			'fileSources.add' => 'Dodaj źródło',
			'fileSources.importFiles' => 'Importowane pliki',
			'fileSources.localFiles' => 'Na tym urządzeniu',
			'fileSources.source' => 'Źródło',
			'fileSources.name' => 'Nazwa',
			'fileSources.endpoint' => 'Adres URL serwera',
			'fileSources.root' => 'folder lub prefix',
			'fileSources.username' => 'Nazwa użytkownika',
			'fileSources.password' => 'Hasło',
			'fileSources.token' => 'API token',
			'fileSources.accessKey' => 'Kluczowe identyfikator',
			'fileSources.secretKey' => 'Sekretny klucz do dostępu',
			'fileSources.sessionToken' => 'Sessions token (opcjonalny)',
			'fileSources.region' => 'Region',
			'fileSources.clientId' => 'OAuth ID klienta',
			'fileSources.clientSecret' => 'OAuth klient sekret (tylko Google desktop)',
			'fileSources.allowHttp' => 'Zezwalaj na nieszyfrowane HTTP w zaufanej sieci',
			'fileSources.connect' => 'Połącz',
			'fileSources.cancel' => 'Anuluj',
			'fileSources.save' => 'Zapisz',
			'fileSources.close' => 'Zamknij',
			'fileSources.removeSource' => 'Źródło odłączone',
			'fileSources.disconnectMessage' => 'Pobrane pliki i historia czytania i słuchania pozostaną na tym urządzeniu.',
			'fileSources.localFolder' => 'Wybierz folder',
			'fileSources.empty' => 'Jeszcze nic tu nie ma',
			'fileSources.emptyHint' => 'Dodaj źródło lub importować książkę, audiobook, muzykę lub wideo.',
			'fileSources.search' => 'Znajdź ten folder',
			'fileSources.searchCached' => 'Szukaj uratowanej biblioteki',
			'fileSources.refresh' => 'Odśwież',
			'fileSources.loadMore' => 'Więcej ładowania',
			'fileSources.offline' => 'Dostępne offline',
			'fileSources.download' => 'Trzymaj się offline',
			'fileSources.removeDownload' => 'Usuń kopii offline',
			'fileSources.continueReading' => 'kontynuuj czytanie',
			'fileSources.continueListening' => 'kontynuuj słuchanie',
			'fileSources.continueWatching' => 'kontynuuj obserwację',
			'fileSources.read' => 'Czytaj',
			'fileSources.listen' => 'Słuchaj',
			'fileSources.play' => 'Odtwórz',
			'fileSources.pause' => 'Pauza',
			'fileSources.stop' => 'Zatrzymaj',
			'fileSources.startOver' => 'Zacznij od',
			'fileSources.finished' => 'Zakończono',
			'fileSources.markFinished' => 'Mark kończy się',
			'fileSources.markUnfinished' => 'Mark niekoniec',
			'fileSources.editions' => 'Wydawnictwa i pliki',
			'fileSources.chapters' => 'Rozdziały',
			'fileSources.bookmarks' => 'Bookmark i notatki',
			'fileSources.bookmark' => 'Dodaj Bookmark',
			'fileSources.highlight' => 'Podwyżka',
			'fileSources.note' => 'Uwaga',
			'fileSources.delete' => 'Usuń',
			'fileSources.export' => 'Notatki eksportowe',
			'fileSources.exported' => 'Notatki eksportowane',
			'fileSources.sync' => 'Synchronizacja postępów',
			'fileSources.synced' => 'Progres synchronizowany',
			'fileSources.conflict' => 'Inne urządzenie ma inną pozycję. wybierz, gdzie kontynuować.',
			'fileSources.useLocal' => 'Użyj tego urządzenia',
			'fileSources.useRemote' => 'Użyj innego urządzenia',
			'fileSources.history' => 'Historia pozycji',
			'fileSources.groupAudio' => 'Słuchaj jak audiobook',
			'fileSources.groupHint' => 'Połączyć pliki audio obecnie pobrane w tym folderze. Pobierz wszystkie strony najpierw.',
			'fileSources.order' => 'Archiwum zamówienia',
			'fileSources.moveUp' => 'Move Up',
			'fileSources.moveDown' => 'Przeprowadź się w dół',
			'fileSources.speed' => 'Prędkość Playback',
			'fileSources.sleep' => 'Wyłącznik czasowy',
			'fileSources.sleepOff' => 'Wył.',
			'fileSources.endChapter' => 'Koniec rozdziału',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuta', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minut', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty', ), 
			'fileSources.skipBack' => 'Skok powrotny',
			'fileSources.skipForward' => 'Skok do przodu',
			'fileSources.smartRewind' => 'Smart odwraca się po przerwie',
			'fileSources.playbackOptions' => 'Opcje słuchania',
			'fileSources.remaining' => ({required Object time}) => '${time} pozostałe',
			'fileSources.contents' => 'Zawartość',
			'fileSources.readerSettings' => 'Czytanie ustawień',
			'fileSources.fontSize' => 'rozmiar tekstu',
			'fileSources.lineHeight' => 'Linia przestrzeń',
			'fileSources.margin' => 'Marginy',
			'fileSources.font' => 'Typowy',
			'fileSources.serif' => 'Seryf',
			'fileSources.sans' => 'Bez serialu',
			'fileSources.mono' => 'Monopostowa',
			'fileSources.columns' => 'Kolumny',
			'fileSources.scroll' => 'Skierujmy się vertikalnie',
			'fileSources.justify' => 'uzasadnia tekst',
			'fileSources.readerTheme' => 'Pojawienie się strony',
			'fileSources.appTheme' => 'Podążaj za tematem aplikacji',
			'fileSources.paper' => 'Papier',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Noc',
			'fileSources.readAloud' => 'Przeczytaj tę stronę w głośnym',
			'fileSources.readAlong' => 'Czytaj dalej',
			'fileSources.stopReading' => 'Zatrzymaj narrację',
			'fileSources.searchBook' => 'Wyszukiwanie w książce',
			'fileSources.noMatches' => 'Żadnych meczów',
			'fileSources.previousPage' => 'Poprzedni strona',
			'fileSources.nextPage' => 'Następna strona',
			'fileSources.page' => ({required Object number}) => 'Strona ${number}',
			'fileSources.externalBlocked' => 'W czytelniku są wyłączone linki zewnętrzne do książki.',
			'fileSources.loading' => 'Otwarcie...',
			'fileSources.narrator' => 'narrator',
			'fileSources.audio' => 'Audio',
			'fileSources.video' => 'Wideo',
			'fileSources.ebooks' => 'Ebooky',
			'fileSources.all' => 'Wszystkie',
			'fileSources.downloads' => 'offline pliki',
			'fileSources.confirmDelete' => 'Usuń wybraną kopii offline? Twoja pozycja i notatki pozostaną.',
			'fileSources.errorAuthentication' => 'Zarejestruj się ponownie, aby ponownie połączyć ten źródło.',
			'fileSources.errorPermission' => 'Ten źródło nie zezwoliło na dostęp do żądanej pliku.',
			'fileSources.errorUnavailable' => 'Spróbuj ponownie lub otwórz kopię offline.',
			'fileSources.errorUnsupported' => 'Ten format lub połączenie nie jest obsługiwane na tym urządzeniu. zobacz przewodnik do ustawienia źródła.',
			'fileSources.errorInvalidData' => 'Ten plik lub odpowiedź serwera nie może być bezpiecznie odczytany.',
			'fileSources.errorCancelled' => 'Operacja została odwołana.',
			'fileSources.errorConflict' => 'Pozycja zmieniła się w kolejnej sesji. ponownie otwórz element, aby wybrać pozycję.',
			'fileSources.signIn' => 'Zaloguj się',
			'fileSources.reconnect' => 'Połącz ponownie',
			'fileSources.folderHelp' => 'Pozostaw biały, aby rozpocząć od korzenia źródłowego. URL S3 obejmuje bucket.',
			'fileSources.preferences' => 'Preferencje',
			'fileSources.timePosition' => 'Pozycja',
			'fileSources.audioTrack' => 'Audio ścieżka',
			'fileSources.subtitleTrack' => 'Podtytuł Track',
			'fileSources.none' => 'Żadne',
			'fileSources.fullscreen' => 'Pełny ekran',
			'fileSources.syncLocation' => 'folder synchronizacyjny Progress (opcjonalny)',
			'fileSources.syncLocationHint' => 'W skrócie WebDAV dla PlezyNG stany. używa warunkowych pisma; media pozostają niezmienione.',
			'fileSources.audiobooks' => 'Audiobooki',
			'fileSources.comics' => 'komiksy',
			'fileSources.scan' => 'Skanowanie książek i mediów',
			'fileSources.browserReader' => 'Otwarte czytelniki',
			'fileSources.browserReaderHelp' => 'Czytelnik jest otwarty w przeglądarce. pozostaw PlezyNG otwarty, aby zaoszczędzić swoje miejsce i notatki.',
			'fileSources.on' => 'Na',
			'fileSources.advancedSetup' => 'aplikacja rejestracja',
			'fileSources.microsoftSignIn' => 'Zarejestruj się z Microsoft',
			'fileSources.zoomIn' => 'Zoom w',
			'fileSources.zoomOut' => 'Zoom wyjść',
			'fileSources.fitPage' => 'Fit strona',
			'fileSources.fitWidth' => 'Wygodny widok',
			'fileSources.actualSize' => 'Aktualny rozmiar',
			'fileSources.goToPage' => 'Przejdź do strony',
			'fileSources.goToSection' => 'Przejdź do rozdziału',
			'fileSources.pageRange' => ({required Object count}) => 'Wprowadź numer od 1 do ${count}',
			'fileSources.pageLayout' => 'Strona layout',
			'fileSources.automatic' => 'Automatycznie',
			'fileSources.singlePage' => 'pojedyncza strona',
			'fileSources.twoPages' => '2 strony',
			'fileSources.readingDirection' => 'Czytanie kierunku',
			'fileSources.leftToRight' => 'Lewa do prawej',
			'fileSources.rightToLeft' => 'Prawo do opuszczenia',
			'fileSources.letterSpacing' => 'List przestrzeń',
			'fileSources.wordSpacing' => 'Słowo spacing',
			'fileSources.readerControlsHelp' => 'Włącz lub użyj sterowania zoomów, aby powiększyć strony. Wejdź do panelu. Ctrl/ ⁇  + lub − dostosowuje zoom; Ctrl/ ⁇  0 go ponownie ustawia.',
			'fileSources.imagePage' => 'Strona komiksowa',
			'fileSources.resetReader' => 'Recykling preferencji czytania',
			'fileSources.zoom' => 'Powiększenie',
			'fileSources.useFiles' => 'Użyj plików i książek',
			'fileSources.cancelScan' => 'Anuluj skanowanie',
			'fileSources.googleDrive' => 'Google Drive',
			'lending.title' => 'Biblioteki publiczne',
			'lending.add' => 'Dodaj bibliotekę',
			'lending.other' => 'Inna biblioteka',
			'lending.libraryName' => 'Nazwa biblioteki',
			'lending.libraryUrl' => 'Biblioteka WEB',
			'lending.libraryUrlHint' => 'Użyj katalogu biblioteki lub strony rejestracji.',
			'lending.intro' => 'Pożycz z biblioteki, trzymaj książki w pobliżu.',
			'lending.handoff' => 'Zarejestruj się, pożycz i czytaj bezpiecznie z własną usługą biblioteki.',
			'lending.openService' => 'Otwarta biblioteka',
			'lending.findLibrary' => 'Znajdź bibliotekę',
			'lending.search' => 'Szukaj książek i autorów',
			'lending.catalogue' => 'Katalog',
			'lending.loans' => 'pożyczki',
			'lending.holds' => 'Trzymaj',
			'lending.signIn' => 'Zarejestruj się w swojej bibliotece',
			'lending.waiting' => 'Zakoń rejestrację w przeglądarce, a następnie wróć tutaj.',
			'lending.cancel' => 'Anuluj',
			'lending.disconnect' => 'usunięcie biblioteki',
			'lending.disconnectMessage' => 'Usunąć tę bibliotekę z tego profilu? Twoje pożyczki i utrzymuje pobyt z biblioteką.',
			'lending.getBook' => 'Zdobądź książkę',
			'lending.checkAvailability' => 'Sprawdź dostępność',
			'lending.available' => 'Dostępne do pożyczki',
			'lending.unavailable' => 'Obecnie niedostępne',
			'lending.borrow' => 'pożyczki',
			'lending.placeHold' => 'Miejsce trzymaj',
			'lending.returnBook' => 'Wróć wcześnie',
			'lending.cancelHold' => 'Anuluj hold',
			'lending.confirmBorrow' => 'Czy pożyczasz tytuł z biblioteki?',
			'lending.confirmReturn' => 'Może trzeba pożyczyć go ponownie, aby kontynuować.',
			'lending.confirmCancelHold' => 'Czy można usunąć swój tytuł?',
			'lending.email' => 'Utrzymuj powiadomienie e-mail',
			'lending.due' => ({required Object date}) => 'Dwa ${date}',
			'lending.queue' => ({required Object position}) => 'pozycja ${position} w linii',
			'lending.empty' => 'Tutaj jeszcze nie ma tytułów.',
			'lending.openLibraryNote' => 'Odkryj katalog Open Library. opcje czytania i pożyczki są wyświetlane na stronie każdego tytułu.',
			'lending.more' => 'Więcej ładowania',
			'lending.gateway' => 'Biblioteka w serwisie',
			'lending.gatewayHint' => 'Dostarczane przez bibliotekę lub administratora PlezyNG.',
			'lending.advanced' => 'Integracja biblioteki',
			'lending.loadLibraries' => 'Wybierz swoją bibliotekę',
			'lending.expired' => 'Pożyczka ta wygasła.',
			'lending.updated' => 'Biblioteka aktualizowana',
			'lending.continueService' => 'kontynuuj służbę',
			'lending.comingSoon' => 'In-app pożyczki · Przyjdzie wkrótce',
			'lending.comingSoonDescription' => 'Możesz użyć swojej biblioteki w Libby, podczas gdy kończymy jej połączenie.',
			'lending.suspendHold' => 'zawieszenie',
			'lending.resumeHold' => 'Podsumowanie trzymaj',
			'lending.suspendMessage' => 'Czy Twoje miejsce jest w linii i pozwól następnemu czytelnikowi pożyczyć tę kopię?',
			'lending.resumeMessage' => 'Czy powtórz tę pozycję, aby Twoja biblioteka mogła zaoferować Ci następną dostępną kopię?',
			'lending.editEmail' => 'Zmiana powiadomienia e-mail',
			'audiobook.syncTitle' => 'Czytanie i słuchanie Sync',
			'audiobook.syncHelp' => 'Utrzymuj pozycje czytania, pozycje słuchania, stan zakończenia, notatki i notatki na swoich urządzeniach. Wybierz załączony konto magazynowe i użyj tego samego kodu synchronizacji na każdym urządzeniu. Czytanie i słuchanie pozostają oddzielne.',
			'audiobook.addSyncSource' => 'Dodaj Google Drive, OneDrive, Dropbox, WebDAV lub S3 do plików i książek najpierw.',
			'audiobook.syncDestination' => 'Synchronizacja konta',
			'audiobook.syncFolder' => 'Synchronizuj folder lub prefix',
			'audiobook.syncFolderHelp' => 'Użyj oddzielnej istniejącej foldery w źródle WebDAV lub dedykowanej prefiksie S3.',
			'audiobook.syncCode' => 'Kod synchronizacyjny',
			'audiobook.syncCodeHelp' => 'Stwórz kod na pierwszym urządzeniu, a następnie wprowadź ten kod na innych urządzeniach. Zachowaj prywatną kopię: jest to klucz do twojego stanu szyfrowanego.',
			'audiobook.showCode' => 'Pokaż lub ukryj kod synchronizacji',
			'audiobook.newSyncCode' => 'Tworzenie nowego kodu synchronizacyjnego',
			'audiobook.saveSync' => 'Zapisz i synchronizuj',
			'audiobook.disableSync' => 'Wyłącz synchronizację na tym urządzeniu',
			'audiobook.syncSourceDisconnect' => 'Usuwanie tego źródła wyłączy synchronizację czytania i słuchania tutaj. szyfrowane pliki synchronizacji pozostaną w dostawcy.',
			'audiobook.syncReconnect' => 'Odtwarzanie konta magazynowego',
			'audiobook.lastSynced' => ({required Object time}) => 'Ostatnia synchronizacja w ${time}',
			'audiobook.syncPrivacy' => 'Tylko szyfrowane postępy i notatki są przechowywane. pliki audio i ebook, tokeny konta i hasła nie są przesyłane. Google Drive i OneDrive wykorzystuje pamięć aplikacji; Dropbox wykorzystuje Sync PlezyNG. Umożliwiając sync może wymagać dodatkowego dostępu do pisania. Podczas gdy jest włączony, ten cel posiada sync postępów; postęp serwera pozostaje oddzielny. Odłączenie sync zachowuje lokalną historię i stan zdalny.',
			'audiobook.syncConflicts' => 'Wybierz miejsce, w którym powrócić',
			'audiobook.conflictHelp' => 'Zmiany te zostały dokonane niezależnie. wybierz pozycję lub wersję znaku, aby zachować. późniejszy czas lub wyższy odsetek nie automatycznie wygrywa.',
			'audiobook.syncDevice' => ({required Object device}) => 'Urządzenie ${device}',
			'audiobook.syncUnknownDevice' => 'Nieznane urządzenie',
			'audiobook.deletedBookmark' => 'Usunięta księgarnia',
			'audiobook.finished' => 'zakończone',
			'audiobook.readingPosition' => ({required Object percent}) => 'Czytanie · ${percent}%',
			'audiobook.chapterTimeline' => 'Rozdział postęp',
			'audiobook.bookTimeline' => 'Cała książka Progress',
			'audiobook.bookRemaining' => ({required Object time}) => 'Czas pozostający w tej książce: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Czas pozostający w tym rozdziale: ${time}',
			'audiobook.unknownRemaining' => 'Całkowity czas dostępny, gdy części są odtwarzane',
			'audiobook.undoSeek' => 'Ostatnie poszukiwania',
			'audiobook.customSpeed' => 'Szybkość odtwarzania',
			'audiobook.speedHelp' => 'Wybierz prędkość od 0,25× do 4×.',
			'audiobook.apply' => 'Aplikuj',
			'audiobook.customSleep' => 'Standardowy czas snu',
			'audiobook.sleepMinutes' => 'minuty (1 – 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Zatrzymaj się po rozdziałach ${count}',
			'audiobook.extendSleep' => 'Dodaj 5 minut',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Czas spania: ${time}',
			'audiobook.useDefaults' => 'Użyj tych sterowników słuchania dla nowych książek',
			'audiobook.librarySort' => 'Rodzaje książek',
			'audiobook.sortTitle' => 'Tytuł',
			'audiobook.sortAuthor' => 'Autorzy',
			'audiobook.sortNarrator' => 'narrator',
			'audiobook.sortSeries' => 'Seria Porządek',
			'audiobook.sortRecent' => 'Niedawno otwarte',
			'audiobook.statusFilter' => 'Status czytania',
			'audiobook.statusAll' => 'Wszystkie książki',
			'audiobook.statusNew' => 'Nie zaczął',
			'audiobook.statusProgress' => 'w postępie',
			'audiobook.statusFinished' => 'zakończone',
			'audiobook.goToTime' => 'Idź do czasu',
			'audiobook.timeHelp' => 'godziny: minuty: sekundy lub minuty: sekundy',
			_ => null,
		};
	}
}
