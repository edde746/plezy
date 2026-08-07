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
	@override late final _Translations$auth$pl auth = _Translations$auth$pl._(_root);
	@override late final _Translations$common$pl common = _Translations$common$pl._(_root);
	@override late final _Translations$screens$pl screens = _Translations$screens$pl._(_root);
	@override late final _Translations$update$pl update = _Translations$update$pl._(_root);
	@override late final _Translations$settings$pl settings = _Translations$settings$pl._(_root);
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
	@override late final _Translations$discover$pl discover = _Translations$discover$pl._(_root);
	@override late final _Translations$errors$pl errors = _Translations$errors$pl._(_root);
	@override late final _Translations$libraries$pl libraries = _Translations$libraries$pl._(_root);
	@override late final _Translations$about$pl about = _Translations$about$pl._(_root);
	@override late final _Translations$serverSelection$pl serverSelection = _Translations$serverSelection$pl._(_root);
	@override late final _Translations$hubDetail$pl hubDetail = _Translations$hubDetail$pl._(_root);
	@override late final _Translations$logs$pl logs = _Translations$logs$pl._(_root);
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
}

// Path: app
class _Translations$app$pl extends Translations$app$en {
	_Translations$app$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
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
	@override String get useQuickConnect => 'Użyj Quick Connect';
	@override String get quickConnectInstructions => 'Otwórz Quick Connect w Jellyfin i wpisz ten kod.';
	@override String get quickConnectWaiting => 'Oczekiwanie na zatwierdzenie…';
	@override String get quickConnectCancel => 'Anuluj';
	@override String get quickConnectExpired => 'Quick Connect wygasł. Spróbuj ponownie.';
	@override String get localDataRecoveryRequired => 'Plezy nie mogło bezpiecznie odzyskać lokalnych danych logowania ani oczekujących danych odtwarzania. Zaloguj się ponownie.';
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

// Path: settings
class _Translations$settings$pl extends Translations$settings$en {
	_Translations$settings$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ustawienia';
	@override String get supportDeveloper => 'Wesprzyj Plezy';
	@override String get supportDeveloperDescription => 'Wspomóż rozwój darowizną na Liberapay';
	@override String get language => 'Język';
	@override String get theme => 'Motyw';
	@override String get appearance => 'Wygląd';
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
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Wprowadź czas (${min}-${max})';
	@override String get systemTheme => 'Systemowy';
	@override String get lightTheme => 'Jasny';
	@override String get darkTheme => 'Ciemny';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Gęstość biblioteki';
	@override String get displayScale => 'Skalowanie';
	@override String get compact => 'Kompaktowy';
	@override String get comfortable => 'Wygodny';
	@override String get tvCornerSpotlightBackdrop => 'Tło wyróżnionej pozycji w rogu';
	@override String get tvCornerSpotlightBackdropDescription => 'Wyświetlaj grafikę wyróżnionej pozycji w prawym górnym rogu zamiast na całym ekranie';
	@override String get viewMode => 'Tryb widoku';
	@override String get gridView => 'Siatka';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Pokaż sekcję wyróżnioną';
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
	@override String get bufferSize => 'Rozmiar bufora';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Automatyczny (zalecany)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Dostępna pamięć: ${heap}MB. Bufor ${size}MB może wpłynąć na odtwarzanie.';
	@override String get playbackBuffer => 'Bufor odtwarzania';
	@override String get playbackBufferAuto => 'Auto (zalecane)';
	@override String get playbackBufferLarge => 'Duży';
	@override String get playbackBufferExtraLarge => 'Bardzo duży';
	@override String get playbackBufferDescription => 'Buforuje więcej w przypadku niestabilnych połączeń. Ograniczony również przez rozmiar bufora.';
	@override String get defaultQualityTitle => 'Domyślna jakość';
	@override String get musicQualityTitle => 'Jakość muzyki';
	@override String get subtitleStyling => 'Styl napisów';
	@override String get subtitleStylingDescription => 'Dostosuj wygląd napisów';
	@override String get smallSkipDuration => 'Krótki skok';
	@override String get largeSkipDuration => 'Długi skok';
	@override String get rewindOnResume => 'Przewiń przy wznowieniu';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekund';
	@override String get defaultSleepTimer => 'Domyślny wyłącznik czasowy';
	@override String minutesUnit({required Object minutes}) => '${minutes} minut';
	@override String get rememberTrackSelections => 'Zapamiętuj wybór ścieżek dla każdego serialu i filmu';
	@override String get rememberTrackSelectionsDescription => 'Zapamiętuj wybór ścieżki dźwiękowej i napisów dla każdego tytułu';
	@override String get followServerTrackSelections => 'Używaj wyboru ścieżek z serwera dla każdego odcinka';
	@override String get followServerTrackSelectionsDescription => 'Przy zmianie odcinka stosuj ścieżkę dźwiękową i napisy wybrane na serwerze zamiast przenosić bieżący wybór';
	@override String get showChapterMarkersOnTimeline => 'Pokaż znaczniki rozdziałów na pasku przewijania';
	@override String get showChapterMarkersOnTimelineDescription => 'Podziel pasek przewijania na granicach rozdziałów';
	@override String get clickVideoTogglesPlayback => 'Kliknięcie wideo przełącza odtwarzanie/pauzę';
	@override String get clickVideoTogglesPlaybackDescription => 'Kliknięcie wideo odtwarza/wstrzymuje zamiast pokazywać sterowanie.';
	@override String get videoPlayerControls => 'Kontrolki odtwarzacza wideo';
	@override String get keyboardShortcuts => 'Skróty klawiszowe';
	@override String get keyboardShortcutsDescription => 'Dostosuj skróty klawiszowe';
	@override String get videoPlayerNavigation => 'Nawigacja odtwarzacza wideo';
	@override String get videoPlayerNavigationDescription => 'Użyj klawiszy strzałek do nawigacji kontrolkami odtwarzacza';
	@override String get watchTogetherRelay => 'Serwer pośredniczący funkcji „Oglądaj razem”';
	@override String get watchTogetherRelayDescription => 'Ustaw własny serwer pośredniczący. Wszyscy muszą korzystać z tego samego serwera.';
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
	@override String get importSettingsInvalidFile => 'Ten plik nie jest prawidłowym eksportem Plezy';
	@override String get importSettingsNoUser => 'Zaloguj się przed importem ustawień';
	@override String get shortcutsReset => 'Skróty przywrócone do domyślnych';
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
	@override String get autoSkip => 'Automatyczne pomijanie';
	@override String get autoSkipIntro => 'Automatyczne pomijanie intro';
	@override String get autoSkipIntroDescription => 'Automatycznie pomijaj znaczniki intro po kilku sekundach';
	@override String get autoSkipCredits => 'Automatyczne pomijanie napisów końcowych';
	@override String get autoSkipCreditsDescription => 'Automatycznie pomijaj napisy końcowe i odtwórz następny odcinek';
	@override String get forceSkipMarkerFallback => 'Wymuś znaczniki awaryjne';
	@override String get forceSkipMarkerFallbackDescription => 'Używaj wzorców tytułów rozdziałów, nawet gdy Plex ma znaczniki';
	@override String get autoSkipDelay => 'Opóźnienie automatycznego pomijania';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Czekaj ${seconds} sekund przed automatycznym pominięciem';
	@override String get introPattern => 'Wzorzec znacznika intro';
	@override String get introPatternDescription => 'Wyrażenie regularne do rozpoznawania znaczników intro w tytułach rozdziałów';
	@override String get creditsPattern => 'Wzorzec znacznika napisów końcowych';
	@override String get creditsPatternDescription => 'Wyrażenie regularne do rozpoznawania znaczników napisów końcowych w tytułach rozdziałów';
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
	@override String get autoPip => 'Automatyczny obraz w obrazie';
	@override String get autoPipDescription => 'Automatycznie włączaj tryb obrazu w obrazie po opuszczeniu aplikacji podczas odtwarzania';
	@override String get matchContentFrameRate => 'Dopasuj częstotliwość klatek do treści';
	@override String get matchContentFrameRateDescription => 'Dopasuj częstotliwość odświeżania ekranu do wideo';
	@override String get matchRefreshRate => 'Dopasuj częstotliwość odświeżania';
	@override String get matchRefreshRateDescription => 'Dopasuj częstotliwość odświeżania w trybie pełnoekranowym';
	@override String get matchDynamicRange => 'Dopasuj zakres dynamiki';
	@override String get matchDynamicRangeDescription => 'Włącz HDR dla treści HDR, potem wróć do SDR';
	@override String get displaySwitchDelay => 'Opóźnienie przełączania ekranu';
	@override String get tunneledPlayback => 'Tunelowane odtwarzanie';
	@override String get tunneledPlaybackDescription => 'Użyj tunelowania wideo. Wyłącz, jeśli HDR pokazuje czarny obraz.';
	@override String get audioPassthrough => 'Przekazywanie dźwięku';
	@override String get audioPassthroughDescription => 'Przesyłaj dźwięk Dolby/DTS do amplitunera lub telewizora bez ponownego kodowania, zachowując dźwięk przestrzenny. Wyłącz tę opcję, jeśli nie słychać dźwięku.';
	@override String get audioPassthroughDescriptionAppleTv => 'Używaj natywnego dekodera Dolby firmy Apple dla Dolby Digital Plus, w tym Atmos. DTS i TrueHD nadal będą odtwarzane jako wielokanałowy dźwięk PCM. Wyłącz tę opcję, jeśli nie słychać dźwięku.';
	@override String get audioDownmix => 'Miksowanie do stereo';
	@override String get audioDownmixDescription => 'Miksuje dźwięk przestrzenny do dwóch kanałów dla głośników stereo lub słuchawek';
	@override String get downmixCenterBoost => 'Wzmocnienie kanału centralnego';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Wzmocnienie (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizacja głośności przy miksowaniu';
	@override String get audioDownmixNormalizeDescription => 'Obniża miks, aby zapobiec przesterowaniu. Wyłącz, aby zachować oryginalną głośność (głośne sceny mogą być zniekształcone).';
	@override String get atmosDiagnostics => 'Test wyjścia Atmos';
	@override String get atmosDiagnosticsDescription => 'Diagnozuj wyjście Dolby Atmos, odtwarzając sygnały testowe przez odtwarzacz systemowy';
	@override String get atmosTestHlsAtmos => 'Strumień Atmos Apple';
	@override String get atmosTestHlsAtmosDescription => 'Sprawdzony strumień Dolby Atmos. Amplituner powinien pokazać Dolby Atmos.';
	@override String get atmosTestHlsControl => 'Strumień dźwięku przestrzennego Apple';
	@override String get atmosTestHlsControlDescription => 'Strumień kontrolny bez Atmos. Amplituner powinien wskazywać dźwięk przestrzenny bez Atmos.';
	@override String get atmosTestRawStream => 'Surowy strumień EAC3';
	@override String get atmosTestRawStreamDescription => 'Przesyła strumieniowo plik testowy dokładnie tak jak podczas odtwarzania Atmos w odtwarzaczu. Wymaga adresu URL pliku testowego.';
	@override String get atmosTestRawFile => 'Surowy plik EAC3';
	@override String get atmosTestRawFileDescription => 'Odtwarza plik testowy o znanej długości. Wymaga URL pliku testowego.';
	@override String get atmosTestAsbarNative => 'Renderer bufora próbek (natywny)';
	@override String get atmosTestAsbarNativeDescription => 'Przekazuje nienaruszony skompresowany dźwięk pliku prosto do renderera systemu. Wymaga URL pliku testowego.';
	@override String get atmosTestAsbarGenerated => 'Renderer bufora próbek (odtworzony)';
	@override String get atmosTestAsbarGeneratedDescription => 'To samo, ale z opisem dźwięku budowanym tak jak przy odtwarzaniu. Wymaga URL pliku testowego.';
	@override String get atmosTestSessionMode => 'Użyj trybu odtwarzania filmów';
	@override String get atmosTestSessionModeDescription => 'Wyłączone używa trybu udokumentowanego przez Dolby. Włączone używa poprzedniego trybu.';
	@override String get atmosTestShowRoutePicker => 'Wybierz wyjście AirPlay';
	@override String get atmosTestHideRoutePicker => 'Ukryj wybór wyjścia AirPlay';
	@override String get atmosTestRoutePickerDescription => 'Wysyła test do odbiornika AirPlay. Tylko AirPlay zgłasza ustalony tryb dźwięku.';
	@override String get atmosTestStop => 'Zatrzymaj test';
	@override String get atmosTestUrl => 'Adres URL pliku testowego';
	@override String get atmosTestUrlDescription => 'Adres URL HTTP surowego pliku Dolby Atmos w formacie .ec3 (np. wyodrębnionego za pomocą ffmpeg)';
	@override String get atmosTestUrlMissing => 'Najpierw ustaw adres URL pliku testowego';
	@override String get atmosTestStatus => 'Stan';
	@override String get dvConversionMode => 'Konwersja Dolby Vision';
	@override String get dvConversionModeDescription => 'Wybierz, jak ExoPlayer obsługuje pliki Dolby Vision Profile 7.';
	@override String get dvConversionAuto => 'Automatycznie';
	@override String get dvConversionNative => 'Natywnie / wyłączone';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Wykrywaj możliwości urządzenia i stosuj standardowy mechanizm awaryjny';
	@override String get dvConversionNativeDescription => 'Wymuś natywne DV7 i wyłącz ponowną próbę konwersji DV';
	@override String get dvConversionDv81Description => 'Wymuś wbudowaną konwersję RPU do profilu Dolby Vision 8.1';
	@override String get dvConversionHevcStripDescription => 'Usuń warstwy Dolby Vision RPU/EL i przedstaw zwykłe HEVC';
	@override String get requireProfileSelectionOnOpen => 'Pytaj o profil przy otwarciu aplikacji';
	@override String get requireProfileSelectionOnOpenDescription => 'Pokaż wybór profilu za każdym razem, gdy aplikacja jest otwierana';
	@override String get forceTvMode => 'Wymuś tryb TV';
	@override String get forceTvModeDescription => 'Wymuś układ telewizyjny na urządzeniach, które nie wykrywają go automatycznie. Wymaga ponownego uruchomienia.';
	@override String get startInFullscreen => 'Uruchom na pełnym ekranie';
	@override String get startInFullscreenDescription => 'Otwiera Plezy w trybie pełnoekranowym przy uruchomieniu';
	@override String get exitFullscreenOnPlayerClose => 'Wyjdź z pełnego ekranu przy zamykaniu odtwarzacza';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Automatycznie wychodzi z trybu pełnoekranowego po zamknięciu odtwarzacza wideo';
	@override String get autoHidePerformanceOverlay => 'Automatycznie ukrywaj nakładkę wydajności';
	@override String get autoHidePerformanceOverlayDescription => 'Wygaszaj nakładkę wydajności wraz z kontrolkami odtwarzania';
	@override String get showNavBarLabels => 'Pokaż etykiety paska nawigacji';
	@override String get showNavBarLabelsDescription => 'Wyświetl tekstowe etykiety pod ikonami paska nawigacji';
	@override String get startupSection => 'Sekcja startowa';
	@override String get liveTvDefaultFavorites => 'Domyślnie ulubione kanały';
	@override String get liveTvDefaultFavoritesDescription => 'Pokaż tylko ulubione kanały po otwarciu telewizji na żywo';
	@override String get display => 'Ekran';
	@override String get homeScreen => 'Ekran główny';
	@override String get navigation => 'Nawigacja';
	@override String get window => 'Okno';
	@override String get content => 'Zawartość';
	@override String get player => 'Odtwarzacz';
	@override String get subtitlesAndConfig => 'Napisy i konfiguracja';
	@override String get seekAndTiming => 'Przewijanie i czas';
	@override String get behavior => 'Zachowanie';
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
		one: 'Usunięty zostanie ${n} odcinek w nim oraz jego plik.',
		few: 'Usunięte zostaną ${n} odcinki w nim oraz ich pliki.',
		many: 'Usuniętych zostanie ${n} odcinków w nim oraz ich pliki.',
		other: 'Usuniętych zostanie ${n} odcinka w nim oraz ich pliki.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'Ten element jest przechowywany jako ${n} plik, który zostanie usunięty.',
		few: 'Ten element jest przechowywany w ${n} plikach, które wszystkie zostaną usunięte.',
		many: 'Ten element jest przechowywany w ${n} plikach, które wszystkie zostaną usunięte.',
		other: 'Ten element jest przechowywany w ${n} pliku, który zostanie usunięty.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: 'W tym samym pliku przechowywany jest jeszcze ${n} inny odcinek, który również zostanie usunięty:',
		few: 'W tym samym pliku przechowywane są jeszcze ${n} inne odcinki, które również zostaną usunięte:',
		many: 'W tym samym pliku przechowywanych jest jeszcze ${n} innych odcinków, które również zostaną usunięte:',
		other: 'W tym samym pliku przechowywany jest jeszcze ${n} innego odcinka, który również zostanie usunięty:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy nie mogło sprawdzić, które pliki zostaną usunięte, więc może usunąć więcej niż element wymieniony powyżej. Anuluj i spróbuj ponownie albo usuń mimo to.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Twój serwer nie podał informacji o plikach tego elementu, więc Plezy nie może sprawdzić, które pliki zostaną usunięte. Może usunąć więcej niż element wymieniony powyżej.';
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
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Napisy';
	@override String get resetToZero => 'Zresetuj do 0 ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label}: później';
	@override String playsEarlier({required Object label}) => '${label}: wcześniej';
	@override String get noOffset => 'Bez przesunięcia';
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
	@override String zoomPercent({required Object percent}) => 'Powiększenie ${percent}%';
	@override late final _Translations$videoControls$pipErrors$pl pipErrors = _Translations$videoControls$pipErrors$pl._(_root);
	@override String get chapters => 'Rozdziały';
	@override String get noChaptersAvailable => 'Brak dostępnych rozdziałów';
	@override String get queue => 'Kolejka';
	@override String get noQueueItems => 'Brak elementów w kolejce';
	@override String get noAudioDevicesAvailable => 'Brak dostępnych urządzeń audio';
	@override String get searchSubtitles => 'Szukaj napisów';
	@override String get language => 'Język';
	@override String get noSubtitlesFound => 'Nie znaleziono napisów';
	@override String get subtitleDownloaded => 'Napisy pobrane';
	@override String get subtitleDownloadedNotApplied => 'Napisy zostały pobrane, ale nie można ich było wybrać';
	@override String get subtitleDownloadFailed => 'Nie udało się pobrać napisów';
	@override String get searchLanguages => 'Szukaj języków...';
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
		one: 'Automatycznie usunięto ${n} obejrzane pobranie',
		few: 'Automatycznie usunięto ${n} obejrzane pobrania',
		many: 'Automatycznie usunięto ${n} obejrzanych pobrań',
		other: 'Automatycznie usunięto ${n} obejrzanego pobrania',
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
	@override String get logsUploaded => 'Logi przesłane';
	@override String get logsUploadFailed => 'Nie udało się przesłać logów';
	@override String get logId => 'ID logu';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$pl extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
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
	@override String get addPlezyProfile => 'Dodaj profil Plezy';
	@override String get switchingProfile => 'Przełączanie profilu…';
	@override String get deleteThisProfileTitle => 'Usunąć ten profil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Usuń ${displayName}. Połączenia nie zostaną zmienione.';
	@override String get active => 'Aktywny';
	@override String get manage => 'Zarządzaj';
	@override String get delete => 'Usuń';
	@override String get signOut => 'Wyloguj się';
	@override String get signOutPlexTitle => 'Wylogować się z Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Usunąć ${displayName} i wszystkich użytkowników Plex Home? Możesz zalogować się ponownie w każdej chwili.';
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
	@override String get borrowEmptySubtitle => 'Najpierw połącz Plex lub Jellyfin z innym profilem.';
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
}

// Path: connections
class _Translations$connections$pl extends Translations$connections$en {
	_Translations$connections$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Połączenia';
	@override String get addConnection => 'Dodaj połączenie';
	@override String get addConnectionSubtitleNoProfile => 'Zaloguj się przez Plex lub połącz serwer Jellyfin';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Dodaj do ${displayName}: Plex, Jellyfin lub połączenie innego profilu';
	@override String sessionExpiredOne({required Object name}) => 'Sesja wygasła dla ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sesja wygasła dla ${count} serwerów';
	@override String get signInAgain => 'Zaloguj się ponownie';
	@override String editMediaBrowserTitle({required Object product}) => 'Edytuj połączenie z ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Dodaj lub usuń adresy URL dla ${serverName}. Plezy będzie używać osiągalnego adresu URL o najniższym opóźnieniu.';
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
	@override String get extras => 'Zwiastuny i dodatki';
	@override String get studio => 'Studio';
	@override String get rating => 'Ocena';
	@override String get director => 'Reżyser';
	@override String get directors => 'Reżyserzy';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serial TV';
	@override String minutesLeft({required Object minutes}) => 'Pozostało ${minutes} min';
	@override String get moreLikeThis => 'Więcej podobnych';
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
}

// Path: libraries
class _Translations$libraries$pl extends Translations$libraries$en {
	_Translations$libraries$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
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
}

// Path: about
class _Translations$about$pl extends Translations$about$en {
	_Translations$about$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'O aplikacji';
	@override String get openSourceLicenses => 'Licencje oprogramowania open source';
	@override String versionLabel({required Object version}) => 'Wersja ${version}';
	@override String get appDescription => 'Piękny klient Plex i Jellyfin stworzony we Flutterze';
	@override String get viewLicensesDescription => 'Wyświetl licencje bibliotek innych firm';
}

// Path: serverSelection
class _Translations$serverSelection$pl extends Translations$serverSelection$en {
	_Translations$serverSelection$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nie znaleziono serwerów dla ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Nie udało się załadować serwerów: ${error}';
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
}

// Path: startup
class _Translations$startup$pl extends Translations$startup$en {
	_Translations$startup$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Nie udało się uruchomić Plezy';
	@override String get failedBody => 'Coś poszło nie tak podczas uruchamiania. Poniższe szczegóły wskazują, co zawiodło.';
	@override String get failedBodyRepairable => 'Zapisany plik ustawień Plezy jest uszkodzony i musi zostać odbudowany, zanim Plezy będzie mogło się uruchomić. Ponawianie nie pomoże — wybierz Napraw pamięć.';
	@override String get phaseLabel => 'Krok';
	@override String get showDetails => 'Pokaż szczegóły';
	@override String get hideDetails => 'Ukryj szczegóły';
	@override String get copyDetails => 'Kopiuj szczegóły';
	@override String get detailsCopied => 'Skopiowano szczegóły do schowka';
	@override String get uploadDetails => 'Prześlij szczegóły';
	@override String get repairStorage => 'Napraw pamięć';
	@override String get repairTitle => 'Naprawić zapisane dane?';
	@override String get repairBodyCommon => 'Plik ustawień Plezy jest uszkodzony i nie można go odczytać. Naprawa przywraca wszystkie ustawienia do wartości domyślnych.';
	@override String get repairBodyOneCredential => 'Jedno zapisane logowanie jest uszkodzone i nie można go odczytać. Naprawa usunie tylko je; pozostałe ustawienia pozostaną nietknięte.';
	@override String get repairBodySignInsKept => 'Twoje serwery i profile powinny pozostać zalogowane.';
	@override String get repairBodySignInsLost => 'Klucza chroniącego zapisane logowania nie można odzyskać z tego pliku, więc będziesz musiał zalogować się ponownie na każdym serwerze i profilu. Nic na Twoim serwerze multimediów nie zostanie zmienione.';
	@override String get repairBodySessionsUncertain => 'Usługi śledzenia (MAL, AniList, Simkl, Trakt) i Seerr są przechowywane osobno i mogą, ale nie muszą przetrwać. Plezy dokładnie poinformuje Cię, co zachowało.';
	@override String get repairConfirm => 'Napraw';
	@override String get repairSucceeded => 'Naprawiono pamięć';
	@override String get repairNeedsRestart => 'Naprawiono pamięć — wymagany restart';
	@override String get restartRequiredBody => 'Twoje dane zostały naprawione, ale Plezy musi uruchomić się od nowa, zanim będzie mogło z nich korzystać. Zamknij Plezy i otwórz je ponownie.';
	@override String get quitPlezy => 'Zamknij Plezy';
	@override String get repairFailed => 'Naprawa nie powiodła się';
	@override String get repairKeptSignIns => 'Twoje serwery i profile są nadal zalogowane.';
	@override String get repairLostSignIns => 'Nie udało się odzyskać klucza chroniącego zapisane logowania. Musisz zalogować się ponownie na każdym serwerze i profilu.';
	@override String get repairLostSessions => 'Utracono co najmniej jedno połączenie z usługą śledzenia lub Seerr i trzeba je ponownie połączyć.';
	@override String get backupTitle => 'Zachowano kopię uszkodzonego pliku';
	@override String get backupWarning => 'Zawiera Twoje dane logowania. Nie przesyłaj ani nie udostępniaj jej.';
	@override String get deleteBackup => 'Usuń kopię';
	@override String get backupDeleted => 'Usunięto kopię.';
	@override String get previousFailureTitle => 'Ostatnim razem nie udało się uruchomić Plezy';
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
	@override String get title => 'Przeglądaj';
	@override String get selectSource => 'Wybierz źródło';
	@override late final _Translations$explore$rows$pl rows = _Translations$explore$rows$pl._(_root);
	@override late final _Translations$explore$status$pl status = _Translations$explore$status$pl._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n,
		one: '${n} odcinek',
		few: '${n} odcinki',
		many: '${n} odcinków',
		other: '${n} odcinka',
	);
	@override String get cast => 'Obsada';
	@override String get characters => 'Postacie';
	@override String get addToWatchlist => 'Dodaj do listy do obejrzenia';
	@override String get removeFromWatchlist => 'Usuń z listy do obejrzenia';
	@override String get watchlistUpdateFailed => 'Nie udało się zaktualizować listy do obejrzenia';
	@override String get notInLibrary => 'Nie ma tego w Twojej bibliotece';
	@override String get inTheseLibraries => 'W tych bibliotekach';
	@override String get checkingLibrary => 'Sprawdzanie Twojej biblioteki...';
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
		one: '${n} wynik',
		few: '${n} wyniki',
		many: '${n} wyników',
		other: '${n} wyniku',
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
	@override String get unknownHub => 'Nieznane';
	@override String get unknownError => 'Nieznany błąd';
	@override String channelNumber({required Object number}) => 'Kanał ${number}';
	@override String get unknownChannel => 'Nieznany kanał';
	@override String get live => 'NA ŻYWO';
	@override String get reloadGuide => 'Odśwież przewodnik';
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
	@override String get rulesProcessRequested => 'Zażądano ponownej oceny reguł';
	@override String get recordShow => 'Nagraj program';
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
	@override String itemCount({required Object count}) => '${count} elementów';
	@override String get oneItem => '1 element';
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
		one: '${n} utwór',
		few: '${n} utwory',
		many: '${n} utworów',
		other: '${n} utworu',
	);
	@override String get nowPlaying => 'Teraz odtwarzane';
	@override String playingFrom({required Object title}) => 'Odtwarzanie z ${title}';
	@override String get queue => 'Kolejka';
	@override String get clearQueue => 'Wyczyść kolejkę';
	@override String get lyrics => 'Tekst utworu';
	@override String get noLyrics => 'Brak tekstu utworu';
	@override String get sleepTimer => 'Wyłącznik czasowy';
	@override String get sleepTimerEndOfTrack => 'Koniec utworu';
	@override String sleepTimerMinutes({required Object n}) => '${n} minut';
	@override String get stopPlayback => 'Zatrzymaj odtwarzanie';
	@override String get previousTrack => 'Poprzedni utwór';
	@override String get nextTrack => 'Następny utwór';
	@override String get repeat => 'Powtarzaj';
	@override String get repeatAll => 'Powtarzaj wszystko';
	@override String get repeatOne => 'Powtarzaj jeden';
}

// Path: watchTogether
class _Translations$watchTogether$pl extends Translations$watchTogether$en {
	_Translations$watchTogether$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oglądaj razem';
	@override String get description => 'Oglądaj treści wspólnie z rodziną i znajomymi dzięki synchronizacji odtwarzania';
	@override String get createSession => 'Utwórz sesję';
	@override String get creating => 'Tworzenie...';
	@override String get joinSession => 'Dołącz do sesji';
	@override String get joining => 'Dołączanie...';
	@override String get controlMode => 'Tryb kontroli';
	@override String get controlModeQuestion => 'Kto może kontrolować odtwarzanie?';
	@override String get hostOnly => 'Tylko gospodarz';
	@override String get anyone => 'Każdy';
	@override String get hostingSession => 'Prowadzenie sesji';
	@override String get inSession => 'W sesji';
	@override String get sessionCode => 'Kod sesji';
	@override String get openSessionControls => 'Otwórz sterowanie sesją „Oglądaj razem”';
	@override String get copySessionCode => 'Skopiuj kod sesji';
	@override String get hostControlsPlayback => 'Gospodarz steruje odtwarzaniem';
	@override String get anyoneCanControl => 'Każdy może sterować odtwarzaniem';
	@override String get hostControls => 'Steruje gospodarz';
	@override String get anyoneControls => 'Steruje każdy';
	@override String get participants => 'Uczestnicy';
	@override String get host => 'Gospodarz';
	@override String get hostBadge => 'GOSPODARZ';
	@override String get youAreHost => 'Jesteś gospodarzem';
	@override String get watchingWithOthers => 'Oglądasz z innymi';
	@override String get endSession => 'Zakończ sesję';
	@override String get leaveSession => 'Opuść sesję';
	@override String get endSessionQuestion => 'Zakończyć sesję?';
	@override String get leaveSessionQuestion => 'Opuścić sesję?';
	@override String get endSessionConfirm => 'To zakończy sesję dla wszystkich uczestników.';
	@override String get leaveSessionConfirm => 'Zostaniesz usunięty z sesji.';
	@override String get endSessionConfirmOverlay => 'To zakończy sesję oglądania dla wszystkich uczestników.';
	@override String get leaveSessionConfirmOverlay => 'Zostaniesz odłączony od sesji oglądania.';
	@override String get end => 'Zakończ';
	@override String get leave => 'Opuść';
	@override String get syncing => 'Synchronizacja...';
	@override String get joinWatchSession => 'Dołącz do sesji oglądania';
	@override String get enterCodeHint => 'Wprowadź 5-znakowy kod';
	@override String get pasteFromClipboard => 'Wklej ze schowka';
	@override String get pleaseEnterCode => 'Wprowadź kod sesji';
	@override String get codeMustBe5Chars => 'Kod sesji musi mieć 5 znaków';
	@override String get joinInstructions => 'Wpisz kod sesji hosta, aby dołączyć.';
	@override String get failedToCreate => 'Nie udało się utworzyć sesji';
	@override String get failedToJoin => 'Nie udało się dołączyć do sesji';
	@override String get sessionCodeCopied => 'Kod sesji skopiowany do schowka';
	@override String get relayUnreachable => 'Serwer pośredniczący jest nieosiągalny. Blokada operatora internetowego może uniemożliwiać korzystanie z funkcji „Oglądaj razem”.';
	@override String get reconnectingToHost => 'Ponowne łączenie z gospodarzem...';
	@override String get currentPlayback => 'Bieżące odtwarzanie';
	@override String get joinCurrentPlayback => 'Dołącz do bieżącego odtwarzania';
	@override String get joinCurrentPlaybackDescription => 'Wróć do treści oglądanej obecnie przez gospodarza';
	@override String get failedToOpenCurrentPlayback => 'Nie udało się otworzyć bieżącego odtwarzania';
	@override String participantJoined({required Object name}) => '${name} dołączył';
	@override String participantLeft({required Object name}) => '${name} opuścił';
	@override String participantPaused({required Object name}) => '${name} wstrzymał';
	@override String participantResumed({required Object name}) => '${name} wznowił';
	@override String participantSeeked({required Object name}) => '${name} zmienił pozycję odtwarzania';
	@override String participantBuffering({required Object name}) => '${name} buforuje';
	@override String participantNeedsUpdate({required Object name}) => '${name} używa starszej wersji aplikacji — synchronizacja jest niedostępna';
	@override String resumingWithout({required Object name}) => 'Wznawianie bez ${name}';
	@override String get waitingForParticipants => 'Oczekiwanie na załadowanie u innych...';
	@override String waitingForName({required Object name}) => 'Oczekiwanie na ${name}...';
	@override String get recentRooms => 'Ostatnie pokoje';
	@override String get renameRoom => 'Zmień nazwę pokoju';
	@override String get removeRoom => 'Usuń';
	@override String get guestSwitchUnavailable => 'Nie można przełączyć — serwer niedostępny do synchronizacji';
	@override String get guestSwitchFailed => 'Nie można przełączyć — nie znaleziono treści na tym serwerze';
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
	@override String get storageFull => 'Pobieranie zostało zatrzymane, ponieważ pamięć urządzenia jest pełna. Zwolnij miejsce i spróbuj ponownie.';
	@override String episodesQueued({required Object count}) => '${count} odcinków w kolejce pobierania';
	@override String get downloadDeleted => 'Pobranie usunięte';
	@override String deleteConfirm({required Object title}) => 'Usunąć "${title}" z tego urządzenia?';
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
	@override String get deleteAll => 'Usuń wszystko';
	@override String get selectVersion => 'Wybierz wersję';
	@override String get allEpisodes => 'Wszystkie odcinki';
	@override String get unwatchedOnly => 'Tylko nieobejrzane';
	@override String nextNUnwatched({required Object count}) => 'Następne ${count} nieobejrzanych';
	@override String get customAmount => 'Własna liczba...';
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
	@override String get activeSyncRules => 'Reguły synchronizacji';
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
	@override String get syncRuleNotAvailableForProfile => 'Niedostępne dla bieżącego profilu';
	@override String get syncRuleUnknownServer => 'Nieznany serwer';
	@override String get syncRuleListCreated => 'Utworzono regułę synchronizacji';
	@override late final _Translations$downloads$backgroundWarning$pl backgroundWarning = _Translations$downloads$backgroundWarning$pl._(_root);
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
	@override String get audioOutput => 'Wyjście audio';
	@override String get performanceOverlay => 'Nakładka wydajności';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Przestrzenny';
	@override String get audioOutputSpatial => 'Dźwięk przestrzenny';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioNormalization => 'Normalizacja głośności';
	@override String get audioDownmix => 'Miksowanie do stereo';
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
	@override String get aspect => 'Proporcje';
	@override String get rotation => 'Obrót';
	@override String get dvSource => 'Źródło DV';
	@override String get dvPath => 'Ścieżka DV';
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
	@override String get memory => 'Pamięć';
	@override String get uiFps => 'UI FPS';
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
	@override String get style => 'Styl';
	@override String get mood => 'Nastrój';
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
	@override String get disconnectConfirmBody => 'Plezy przestanie wysyłać zdarzenia do serwisu Trakt. Połączenie można przywrócić w dowolnym momencie.';
	@override String get scrobble => 'Śledzenie odtwarzania w czasie rzeczywistym';
	@override String get scrobbleDescription => 'Wysyłaj do serwisu Trakt zdarzenia odtwarzania, wstrzymania i zatrzymania.';
	@override String get watchedSync => 'Synchronizuj stan obejrzenia';
	@override String get watchedSyncDescription => 'Gdy oznaczysz element jako obejrzany w Plezy, zostanie on również oznaczony jako obejrzany w serwisie Trakt.';
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
	@override String get noSignInMethods => 'Ta instancja Seerr nie oferuje metody logowania obsługiwanej przez Plezy.';
	@override String get instance => 'Instancja';
	@override String get disconnectConfirm => 'Odłączyć Seerr?';
	@override String get disconnectConfirmBody => 'Plezy zapomni tę instancję Seerr. Połącz ponownie w dowolnym momencie.';
	@override String get request => 'Zamów';
	@override String get request4k => 'Zamów w 4K';
	@override String get seasons => 'Sezony';
	@override String get allSeasons => 'Wszystkie sezony';
	@override String get advancedOptions => 'Zaawansowane';
	@override String get destinationServer => 'Serwer docelowy';
	@override String get qualityProfile => 'Profil jakości';
	@override String get rootFolder => 'Folder główny';
	@override String get languageProfile => 'Profil językowy';
	@override String get requestSubmitted => 'Zamówienie wysłane';
	@override String requestFailed({required Object error}) => 'Zamówienie nie powiodło się: ${error}';
	@override String get requestsLoadFailed => 'Nie udało się wczytać opcji zamówienia';
	@override String get nothingToRequest => 'Wszystko jest już dostępne lub zamówione.';
	@override String get statusAvailable => 'Dostępne';
	@override String get statusPartiallyAvailable => 'Częściowo dostępne';
	@override String get statusRequested => 'Zamówione';
	@override String get statusProcessing => 'Przetwarzanie';
}

// Path: services
class _Translations$services$pl extends Translations$services$en {
	_Translations$services$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Usługi';
	@override String get hubSubtitle => 'Synchronizuj postęp oglądania i zamawiaj nowe tytuły.';
	@override String get notConnected => 'Nie połączono';
	@override String connectedAs({required Object username}) => 'Połączono jako @${username}';
	@override String get scrobble => 'Automatycznie śledź postęp';
	@override String get scrobbleDescription => 'Aktualizuj swoją listę po ukończeniu odcinka lub filmu.';
	@override String disconnectConfirm({required Object service}) => 'Odłączyć ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy przestanie aktualizować ${service}. Połącz ponownie w dowolnym momencie.';
	@override String connectFailed({required Object service}) => 'Nie udało się połączyć z ${service}. Spróbuj ponownie.';
	@override late final _Translations$services$names$pl names = _Translations$services$names$pl._(_root);
	@override late final _Translations$services$deviceCode$pl deviceCode = _Translations$services$deviceCode$pl._(_root);
	@override late final _Translations$services$oauthProxy$pl oauthProxy = _Translations$services$oauthProxy$pl._(_root);
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
}

// Path: common.ratingSource
class _Translations$common$ratingSource$pl extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Krytycy';
	@override String get audience => 'Widzowie';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Krytycy Rotten Tomatoes';
	@override String get rottenTomatoesAudience => 'Widzowie Rotten Tomatoes';
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
	@override String get shaderToggle => 'Przełącz shadery';
	@override String get skipMarker => 'Pomiń intro/napisy końcowe';
	@override String get screenshot => 'Zrób zrzut ekranu';
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
	@override String unknown({required Object error}) => 'Wystąpił błąd: ${error}';
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
	@override String rankFavorited({required Object n}) => '#${n} w ulubionych';
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
		one: '${n} komentarz',
		few: '${n} komentarze',
		many: '${n} komentarzy',
		other: '${n} komentarza',
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
	@override String get tvShort => 'TV Short';
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
		one: 'Polecany przez ${n} użytkownika',
		few: 'Polecany przez ${n} użytkowników',
		many: 'Polecany przez ${n} użytkowników',
		other: 'Polecany przez ${n} użytkownika',
	);
	@override String recommendedBy({required Object who}) => 'Polecany przez ${who}';
	@override String favoritedBy({required Object who}) => 'Dodany do ulubionych przez ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} jeszcze nie wyemitowano';
	@override String recommendedByPercent({required Object percent}) => 'Polecany przez ${percent} widzów';
	@override String get relatedTitles => 'Powiązane tytuły';
	@override String get background => 'Tło';
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
	@override String get sheetIntro => 'Android uniemożliwia Plezy niezawodne pobieranie plików w tle.';
	@override String get sheetIntroDegraded => 'Twoje urządzenie ogranicza możliwość pobierania w tle przez Plezy.';
	@override String get reasonBackgroundRestricted => 'Działanie Plezy w tle jest ograniczone. Ustaw użycie baterii lub działanie w tle na „Bez ograniczeń”.';
	@override String get reasonStandbyRestricted => 'Android umieścił Plezy w ograniczonym trybie gotowości. Ustaw użycie baterii na „Bez ograniczeń”.';
	@override String get reasonDownloadChannelBlocked => 'Powiadomienia o pobieraniu są wyłączone, więc postęp i opcje sterowania mogą być niedostępne.';
	@override String get reasonNotificationsDisabled => 'Powiadomienia są wyłączone. W Android 13 lub nowszym są wymagane przy długim pobieraniu w tle.';
	@override String get reasonDataSaver => 'Oszczędzanie danych jest włączone, co blokuje pobieranie w tle przez mobilną transmisję danych. Pobieranie powinno nadal działać przez Wi-Fi.';
	@override String get reasonOemUnknown => 'Pobieranie wielokrotnie przerywało się, gdy Plezy działało w tle. Sprawdź ustawienia baterii lub działania w tle dla Plezy.';
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
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$pl extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Urządzenia Plezy z tym samym kontem Plex pojawią się tutaj';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Łączenie...';
	@override String get searchingForDevices => 'Szukanie urządzeń...';
	@override String get noDevicesFound => 'Nie znaleziono urządzeń w sieci';
	@override String get noDevicesHint => 'Otwórz Plezy na komputerze i połącz oba urządzenia z tą samą siecią Wi-Fi';
	@override String get availableDevices => 'Dostępne urządzenia';
	@override String get manualConnection => 'Połączenie ręczne';
	@override String get cryptoInitFailed => 'Nie udało się uruchomić bezpiecznego połączenia. Najpierw zaloguj się do Plex.';
	@override String get validationHostRequired => 'Wprowadź adres hosta';
	@override String get validationHostFormat => 'Format musi być IP:port (np. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Limit czasu połączenia. Użyj tej samej sieci na obu urządzeniach.';
	@override String get sessionNotFound => 'Nie znaleziono urządzenia. Upewnij się, że Plezy działa na hoście.';
	@override String get authFailed => 'Uwierzytelnianie nie powiodło się. Oba urządzenia muszą używać tego samego konta Plex.';
	@override String failedToConnect({required Object error}) => 'Nie udało się połączyć: ${error}';
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
	@override String get stop => 'Stop';
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

// Path: services.deviceCode
class _Translations$services$deviceCode$pl extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$pl._(TranslationsPl root) : this._root = root, super.internal(root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktywuj Plezy w ${service}';
	@override String body({required Object url}) => 'Odwiedź ${url} i wpisz ten kod:';
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
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Zaloguj się przez Plex',
			'auth.showQRCode' => 'Pokaż kod QR',
			'auth.authenticate' => 'Uwierzytelnij',
			'auth.authenticationTimeout' => 'Upłynął czas uwierzytelniania. Spróbuj ponownie.',
			'auth.scanQRToSignIn' => 'Zeskanuj ten kod QR, aby się zalogować',
			'auth.waitingForAuth' => 'Oczekiwanie na uwierzytelnienie...\nZaloguj się w przeglądarce.',
			'auth.useBrowser' => 'Użyj przeglądarki',
			'auth.or' => 'lub',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Połącz z ${product}',
			'auth.useQuickConnect' => 'Użyj Quick Connect',
			'auth.quickConnectInstructions' => 'Otwórz Quick Connect w Jellyfin i wpisz ten kod.',
			'auth.quickConnectWaiting' => 'Oczekiwanie na zatwierdzenie…',
			'auth.quickConnectCancel' => 'Anuluj',
			'auth.quickConnectExpired' => 'Quick Connect wygasł. Spróbuj ponownie.',
			'auth.localDataRecoveryRequired' => 'Plezy nie mogło bezpiecznie odzyskać lokalnych danych logowania ani oczekujących danych odtwarzania. Zaloguj się ponownie.',
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
			'common.ratingSource.critic' => 'Krytycy',
			'common.ratingSource.audience' => 'Widzowie',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Krytycy Rotten Tomatoes',
			'common.ratingSource.rottenTomatoesAudience' => 'Widzowie Rotten Tomatoes',
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
			'settings.title' => 'Ustawienia',
			'settings.supportDeveloper' => 'Wesprzyj Plezy',
			'settings.supportDeveloperDescription' => 'Wspomóż rozwój darowizną na Liberapay',
			'settings.language' => 'Język',
			'settings.theme' => 'Motyw',
			'settings.appearance' => 'Wygląd',
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
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Wprowadź czas (${min}-${max})',
			'settings.systemTheme' => 'Systemowy',
			'settings.lightTheme' => 'Jasny',
			'settings.darkTheme' => 'Ciemny',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Gęstość biblioteki',
			'settings.displayScale' => 'Skalowanie',
			'settings.compact' => 'Kompaktowy',
			'settings.comfortable' => 'Wygodny',
			'settings.tvCornerSpotlightBackdrop' => 'Tło wyróżnionej pozycji w rogu',
			'settings.tvCornerSpotlightBackdropDescription' => 'Wyświetlaj grafikę wyróżnionej pozycji w prawym górnym rogu zamiast na całym ekranie',
			'settings.viewMode' => 'Tryb widoku',
			'settings.gridView' => 'Siatka',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Pokaż sekcję wyróżnioną',
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
			'settings.bufferSize' => 'Rozmiar bufora',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Automatyczny (zalecany)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Dostępna pamięć: ${heap}MB. Bufor ${size}MB może wpłynąć na odtwarzanie.',
			'settings.playbackBuffer' => 'Bufor odtwarzania',
			'settings.playbackBufferAuto' => 'Auto (zalecane)',
			'settings.playbackBufferLarge' => 'Duży',
			'settings.playbackBufferExtraLarge' => 'Bardzo duży',
			'settings.playbackBufferDescription' => 'Buforuje więcej w przypadku niestabilnych połączeń. Ograniczony również przez rozmiar bufora.',
			'settings.defaultQualityTitle' => 'Domyślna jakość',
			'settings.musicQualityTitle' => 'Jakość muzyki',
			'settings.subtitleStyling' => 'Styl napisów',
			'settings.subtitleStylingDescription' => 'Dostosuj wygląd napisów',
			'settings.smallSkipDuration' => 'Krótki skok',
			'settings.largeSkipDuration' => 'Długi skok',
			'settings.rewindOnResume' => 'Przewiń przy wznowieniu',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekund',
			'settings.defaultSleepTimer' => 'Domyślny wyłącznik czasowy',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minut',
			'settings.rememberTrackSelections' => 'Zapamiętuj wybór ścieżek dla każdego serialu i filmu',
			'settings.rememberTrackSelectionsDescription' => 'Zapamiętuj wybór ścieżki dźwiękowej i napisów dla każdego tytułu',
			'settings.followServerTrackSelections' => 'Używaj wyboru ścieżek z serwera dla każdego odcinka',
			'settings.followServerTrackSelectionsDescription' => 'Przy zmianie odcinka stosuj ścieżkę dźwiękową i napisy wybrane na serwerze zamiast przenosić bieżący wybór',
			'settings.showChapterMarkersOnTimeline' => 'Pokaż znaczniki rozdziałów na pasku przewijania',
			'settings.showChapterMarkersOnTimelineDescription' => 'Podziel pasek przewijania na granicach rozdziałów',
			'settings.clickVideoTogglesPlayback' => 'Kliknięcie wideo przełącza odtwarzanie/pauzę',
			'settings.clickVideoTogglesPlaybackDescription' => 'Kliknięcie wideo odtwarza/wstrzymuje zamiast pokazywać sterowanie.',
			'settings.videoPlayerControls' => 'Kontrolki odtwarzacza wideo',
			'settings.keyboardShortcuts' => 'Skróty klawiszowe',
			'settings.keyboardShortcutsDescription' => 'Dostosuj skróty klawiszowe',
			'settings.videoPlayerNavigation' => 'Nawigacja odtwarzacza wideo',
			'settings.videoPlayerNavigationDescription' => 'Użyj klawiszy strzałek do nawigacji kontrolkami odtwarzacza',
			'settings.watchTogetherRelay' => 'Serwer pośredniczący funkcji „Oglądaj razem”',
			'settings.watchTogetherRelayDescription' => 'Ustaw własny serwer pośredniczący. Wszyscy muszą korzystać z tego samego serwera.',
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
			'settings.importSettingsInvalidFile' => 'Ten plik nie jest prawidłowym eksportem Plezy',
			'settings.importSettingsNoUser' => 'Zaloguj się przed importem ustawień',
			'settings.shortcutsReset' => 'Skróty przywrócone do domyślnych',
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
			'settings.autoSkip' => 'Automatyczne pomijanie',
			'settings.autoSkipIntro' => 'Automatyczne pomijanie intro',
			'settings.autoSkipIntroDescription' => 'Automatycznie pomijaj znaczniki intro po kilku sekundach',
			'settings.autoSkipCredits' => 'Automatyczne pomijanie napisów końcowych',
			'settings.autoSkipCreditsDescription' => 'Automatycznie pomijaj napisy końcowe i odtwórz następny odcinek',
			'settings.forceSkipMarkerFallback' => 'Wymuś znaczniki awaryjne',
			'settings.forceSkipMarkerFallbackDescription' => 'Używaj wzorców tytułów rozdziałów, nawet gdy Plex ma znaczniki',
			'settings.autoSkipDelay' => 'Opóźnienie automatycznego pomijania',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Czekaj ${seconds} sekund przed automatycznym pominięciem',
			'settings.introPattern' => 'Wzorzec znacznika intro',
			'settings.introPatternDescription' => 'Wyrażenie regularne do rozpoznawania znaczników intro w tytułach rozdziałów',
			'settings.creditsPattern' => 'Wzorzec znacznika napisów końcowych',
			'settings.creditsPatternDescription' => 'Wyrażenie regularne do rozpoznawania znaczników napisów końcowych w tytułach rozdziałów',
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
			'settings.autoPip' => 'Automatyczny obraz w obrazie',
			'settings.autoPipDescription' => 'Automatycznie włączaj tryb obrazu w obrazie po opuszczeniu aplikacji podczas odtwarzania',
			'settings.matchContentFrameRate' => 'Dopasuj częstotliwość klatek do treści',
			'settings.matchContentFrameRateDescription' => 'Dopasuj częstotliwość odświeżania ekranu do wideo',
			'settings.matchRefreshRate' => 'Dopasuj częstotliwość odświeżania',
			'settings.matchRefreshRateDescription' => 'Dopasuj częstotliwość odświeżania w trybie pełnoekranowym',
			'settings.matchDynamicRange' => 'Dopasuj zakres dynamiki',
			'settings.matchDynamicRangeDescription' => 'Włącz HDR dla treści HDR, potem wróć do SDR',
			'settings.displaySwitchDelay' => 'Opóźnienie przełączania ekranu',
			'settings.tunneledPlayback' => 'Tunelowane odtwarzanie',
			'settings.tunneledPlaybackDescription' => 'Użyj tunelowania wideo. Wyłącz, jeśli HDR pokazuje czarny obraz.',
			'settings.audioPassthrough' => 'Przekazywanie dźwięku',
			'settings.audioPassthroughDescription' => 'Przesyłaj dźwięk Dolby/DTS do amplitunera lub telewizora bez ponownego kodowania, zachowując dźwięk przestrzenny. Wyłącz tę opcję, jeśli nie słychać dźwięku.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Używaj natywnego dekodera Dolby firmy Apple dla Dolby Digital Plus, w tym Atmos. DTS i TrueHD nadal będą odtwarzane jako wielokanałowy dźwięk PCM. Wyłącz tę opcję, jeśli nie słychać dźwięku.',
			'settings.audioDownmix' => 'Miksowanie do stereo',
			'settings.audioDownmixDescription' => 'Miksuje dźwięk przestrzenny do dwóch kanałów dla głośników stereo lub słuchawek',
			'settings.downmixCenterBoost' => 'Wzmocnienie kanału centralnego',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Wzmocnienie (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizacja głośności przy miksowaniu',
			'settings.audioDownmixNormalizeDescription' => 'Obniża miks, aby zapobiec przesterowaniu. Wyłącz, aby zachować oryginalną głośność (głośne sceny mogą być zniekształcone).',
			'settings.atmosDiagnostics' => 'Test wyjścia Atmos',
			'settings.atmosDiagnosticsDescription' => 'Diagnozuj wyjście Dolby Atmos, odtwarzając sygnały testowe przez odtwarzacz systemowy',
			'settings.atmosTestHlsAtmos' => 'Strumień Atmos Apple',
			'settings.atmosTestHlsAtmosDescription' => 'Sprawdzony strumień Dolby Atmos. Amplituner powinien pokazać Dolby Atmos.',
			'settings.atmosTestHlsControl' => 'Strumień dźwięku przestrzennego Apple',
			'settings.atmosTestHlsControlDescription' => 'Strumień kontrolny bez Atmos. Amplituner powinien wskazywać dźwięk przestrzenny bez Atmos.',
			'settings.atmosTestRawStream' => 'Surowy strumień EAC3',
			'settings.atmosTestRawStreamDescription' => 'Przesyła strumieniowo plik testowy dokładnie tak jak podczas odtwarzania Atmos w odtwarzaczu. Wymaga adresu URL pliku testowego.',
			'settings.atmosTestRawFile' => 'Surowy plik EAC3',
			'settings.atmosTestRawFileDescription' => 'Odtwarza plik testowy o znanej długości. Wymaga URL pliku testowego.',
			'settings.atmosTestAsbarNative' => 'Renderer bufora próbek (natywny)',
			'settings.atmosTestAsbarNativeDescription' => 'Przekazuje nienaruszony skompresowany dźwięk pliku prosto do renderera systemu. Wymaga URL pliku testowego.',
			'settings.atmosTestAsbarGenerated' => 'Renderer bufora próbek (odtworzony)',
			'settings.atmosTestAsbarGeneratedDescription' => 'To samo, ale z opisem dźwięku budowanym tak jak przy odtwarzaniu. Wymaga URL pliku testowego.',
			'settings.atmosTestSessionMode' => 'Użyj trybu odtwarzania filmów',
			'settings.atmosTestSessionModeDescription' => 'Wyłączone używa trybu udokumentowanego przez Dolby. Włączone używa poprzedniego trybu.',
			'settings.atmosTestShowRoutePicker' => 'Wybierz wyjście AirPlay',
			'settings.atmosTestHideRoutePicker' => 'Ukryj wybór wyjścia AirPlay',
			'settings.atmosTestRoutePickerDescription' => 'Wysyła test do odbiornika AirPlay. Tylko AirPlay zgłasza ustalony tryb dźwięku.',
			'settings.atmosTestStop' => 'Zatrzymaj test',
			'settings.atmosTestUrl' => 'Adres URL pliku testowego',
			'settings.atmosTestUrlDescription' => 'Adres URL HTTP surowego pliku Dolby Atmos w formacie .ec3 (np. wyodrębnionego za pomocą ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Najpierw ustaw adres URL pliku testowego',
			'settings.atmosTestStatus' => 'Stan',
			'settings.dvConversionMode' => 'Konwersja Dolby Vision',
			'settings.dvConversionModeDescription' => 'Wybierz, jak ExoPlayer obsługuje pliki Dolby Vision Profile 7.',
			'settings.dvConversionAuto' => 'Automatycznie',
			'settings.dvConversionNative' => 'Natywnie / wyłączone',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Wykrywaj możliwości urządzenia i stosuj standardowy mechanizm awaryjny',
			'settings.dvConversionNativeDescription' => 'Wymuś natywne DV7 i wyłącz ponowną próbę konwersji DV',
			'settings.dvConversionDv81Description' => 'Wymuś wbudowaną konwersję RPU do profilu Dolby Vision 8.1',
			'settings.dvConversionHevcStripDescription' => 'Usuń warstwy Dolby Vision RPU/EL i przedstaw zwykłe HEVC',
			'settings.requireProfileSelectionOnOpen' => 'Pytaj o profil przy otwarciu aplikacji',
			'settings.requireProfileSelectionOnOpenDescription' => 'Pokaż wybór profilu za każdym razem, gdy aplikacja jest otwierana',
			'settings.forceTvMode' => 'Wymuś tryb TV',
			'settings.forceTvModeDescription' => 'Wymuś układ telewizyjny na urządzeniach, które nie wykrywają go automatycznie. Wymaga ponownego uruchomienia.',
			'settings.startInFullscreen' => 'Uruchom na pełnym ekranie',
			'settings.startInFullscreenDescription' => 'Otwiera Plezy w trybie pełnoekranowym przy uruchomieniu',
			'settings.exitFullscreenOnPlayerClose' => 'Wyjdź z pełnego ekranu przy zamykaniu odtwarzacza',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Automatycznie wychodzi z trybu pełnoekranowego po zamknięciu odtwarzacza wideo',
			'settings.autoHidePerformanceOverlay' => 'Automatycznie ukrywaj nakładkę wydajności',
			'settings.autoHidePerformanceOverlayDescription' => 'Wygaszaj nakładkę wydajności wraz z kontrolkami odtwarzania',
			'settings.showNavBarLabels' => 'Pokaż etykiety paska nawigacji',
			'settings.showNavBarLabelsDescription' => 'Wyświetl tekstowe etykiety pod ikonami paska nawigacji',
			'settings.startupSection' => 'Sekcja startowa',
			'settings.liveTvDefaultFavorites' => 'Domyślnie ulubione kanały',
			'settings.liveTvDefaultFavoritesDescription' => 'Pokaż tylko ulubione kanały po otwarciu telewizji na żywo',
			'settings.display' => 'Ekran',
			'settings.homeScreen' => 'Ekran główny',
			'settings.navigation' => 'Nawigacja',
			'settings.window' => 'Okno',
			'settings.content' => 'Zawartość',
			'settings.player' => 'Odtwarzacz',
			'settings.subtitlesAndConfig' => 'Napisy i konfiguracja',
			'settings.seekAndTiming' => 'Przewijanie i czas',
			'settings.behavior' => 'Zachowanie',
			'search.hint' => 'Szukaj filmów, seriali, muzyki...',
			'search.tryDifferentTerm' => 'Spróbuj innego wyszukiwania',
			'search.searchYourMedia' => 'Przeszukaj swoje media',
			'search.enterTitleActorOrKeyword' => 'Wprowadź tytuł, aktora lub słowo kluczowe',
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
			'hotkeys.actions.shaderToggle' => 'Przełącz shadery',
			'hotkeys.actions.skipMarker' => 'Pomiń intro/napisy końcowe',
			'hotkeys.actions.screenshot' => 'Zrób zrzut ekranu',
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
			_ => null,
		} ?? switch (path) {
			'mediaMenu.deleteShowConfirm' => 'Usuń serial',
			'mediaMenu.deleteMovieConfirm' => 'Usuń film',
			'mediaMenu.deleteAnyway' => 'Usuń mimo to',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Trwale usunąć ${title} z Twojego serwera?',
			'mediaMenu.deleteMultipleWarning' => 'Obejmuje to wszystkie odcinki i ich pliki.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Usunięty zostanie ${n} odcinek w nim oraz jego plik.', few: 'Usunięte zostaną ${n} odcinki w nim oraz ich pliki.', many: 'Usuniętych zostanie ${n} odcinków w nim oraz ich pliki.', other: 'Usuniętych zostanie ${n} odcinka w nim oraz ich pliki.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Ten element jest przechowywany jako ${n} plik, który zostanie usunięty.', few: 'Ten element jest przechowywany w ${n} plikach, które wszystkie zostaną usunięte.', many: 'Ten element jest przechowywany w ${n} plikach, które wszystkie zostaną usunięte.', other: 'Ten element jest przechowywany w ${n} pliku, który zostanie usunięty.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'W tym samym pliku przechowywany jest jeszcze ${n} inny odcinek, który również zostanie usunięty:', few: 'W tym samym pliku przechowywane są jeszcze ${n} inne odcinki, które również zostaną usunięte:', many: 'W tym samym pliku przechowywanych jest jeszcze ${n} innych odcinków, które również zostaną usunięte:', other: 'W tym samym pliku przechowywany jest jeszcze ${n} innego odcinka, który również zostanie usunięty:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy nie mogło sprawdzić, które pliki zostaną usunięte, więc może usunąć więcej niż element wymieniony powyżej. Anuluj i spróbuj ponownie albo usuń mimo to.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Twój serwer nie podał informacji o plikach tego elementu, więc Plezy nie może sprawdzić, które pliki zostaną usunięte. Może usunąć więcej niż element wymieniony powyżej.',
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
			'tooltips.shufflePlay' => 'Odtwarzanie losowe',
			'tooltips.playTrailer' => 'Odtwórz zwiastun',
			'tooltips.markAsWatched' => 'Oznacz jako obejrzane',
			'tooltips.markAsUnwatched' => 'Oznacz jako nieobejrzane',
			'audioTracks.track' => ({required Object n}) => 'Ścieżka audio ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Napisy',
			'videoControls.resetToZero' => 'Zresetuj do 0 ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label}: później',
			'videoControls.playsEarlier' => ({required Object label}) => '${label}: wcześniej',
			'videoControls.noOffset' => 'Bez przesunięcia',
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
			'videoControls.zoomPercent' => ({required Object percent}) => 'Powiększenie ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Wymaga Androida 8.0 lub nowszego',
			'videoControls.pipErrors.iosVersion' => 'Wymaga iOS 15.0 lub nowszego',
			'videoControls.pipErrors.permissionDisabled' => 'Obraz w obrazie jest wyłączony. Włącz go w ustawieniach systemu.',
			'videoControls.pipErrors.notSupported' => 'Urządzenie nie obsługuje trybu obraz w obrazie',
			'videoControls.pipErrors.voSwitchFailed' => 'Nie udało się przełączyć wyjścia wideo dla trybu obraz w obrazie',
			'videoControls.pipErrors.failed' => 'Nie udało się uruchomić trybu obraz w obrazie',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Wystąpił błąd: ${error}',
			'videoControls.chapters' => 'Rozdziały',
			'videoControls.noChaptersAvailable' => 'Brak dostępnych rozdziałów',
			'videoControls.queue' => 'Kolejka',
			'videoControls.noQueueItems' => 'Brak elementów w kolejce',
			'videoControls.noAudioDevicesAvailable' => 'Brak dostępnych urządzeń audio',
			'videoControls.searchSubtitles' => 'Szukaj napisów',
			'videoControls.language' => 'Język',
			'videoControls.noSubtitlesFound' => 'Nie znaleziono napisów',
			'videoControls.subtitleDownloaded' => 'Napisy pobrane',
			'videoControls.subtitleDownloadedNotApplied' => 'Napisy zostały pobrane, ale nie można ich było wybrać',
			'videoControls.subtitleDownloadFailed' => 'Nie udało się pobrać napisów',
			'videoControls.searchLanguages' => 'Szukaj języków...',
			'messages.markedAsWatched' => 'Oznaczono jako obejrzane',
			'messages.markedAsUnwatched' => 'Oznaczono jako nieobejrzane',
			'messages.markedAsWatchedOffline' => 'Oznaczono jako obejrzane (zsynchronizuje się po połączeniu)',
			'messages.markedAsUnwatchedOffline' => 'Oznaczono jako nieobejrzane (zsynchronizuje się po połączeniu)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatycznie usunięto: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Automatycznie usunięto ${n} obejrzane pobranie', few: 'Automatycznie usunięto ${n} obejrzane pobrania', many: 'Automatycznie usunięto ${n} obejrzanych pobrań', other: 'Automatycznie usunięto ${n} obejrzanego pobrania', ), 
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
			'messages.logsUploaded' => 'Logi przesłane',
			'messages.logsUploadFailed' => 'Nie udało się przesłać logów',
			'messages.logId' => 'ID logu',
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
			'dialog.confirmAction' => 'Potwierdź działanie',
			'profiles.addPlezyProfile' => 'Dodaj profil Plezy',
			'profiles.switchingProfile' => 'Przełączanie profilu…',
			'profiles.deleteThisProfileTitle' => 'Usunąć ten profil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Usuń ${displayName}. Połączenia nie zostaną zmienione.',
			'profiles.active' => 'Aktywny',
			'profiles.manage' => 'Zarządzaj',
			'profiles.delete' => 'Usuń',
			'profiles.signOut' => 'Wyloguj się',
			'profiles.signOutPlexTitle' => 'Wylogować się z Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Usunąć ${displayName} i wszystkich użytkowników Plex Home? Możesz zalogować się ponownie w każdej chwili.',
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
			'profiles.borrowEmptySubtitle' => 'Najpierw połącz Plex lub Jellyfin z innym profilem.',
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
			'connections.sectionTitle' => 'Połączenia',
			'connections.addConnection' => 'Dodaj połączenie',
			'connections.addConnectionSubtitleNoProfile' => 'Zaloguj się przez Plex lub połącz serwer Jellyfin',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Dodaj do ${displayName}: Plex, Jellyfin lub połączenie innego profilu',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sesja wygasła dla ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sesja wygasła dla ${count} serwerów',
			'connections.signInAgain' => 'Zaloguj się ponownie',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edytuj połączenie z ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Dodaj lub usuń adresy URL dla ${serverName}. Plezy będzie używać osiągalnego adresu URL o najniższym opóźnieniu.',
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
			'discover.extras' => 'Zwiastuny i dodatki',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Ocena',
			'discover.director' => 'Reżyser',
			'discover.directors' => 'Reżyserzy',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serial TV',
			'discover.minutesLeft' => ({required Object minutes}) => 'Pozostało ${minutes} min',
			'discover.moreLikeThis' => 'Więcej podobnych',
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
			'about.title' => 'O aplikacji',
			'about.openSourceLicenses' => 'Licencje oprogramowania open source',
			'about.versionLabel' => ({required Object version}) => 'Wersja ${version}',
			'about.appDescription' => 'Piękny klient Plex i Jellyfin stworzony we Flutterze',
			'about.viewLicensesDescription' => 'Wyświetl licencje bibliotek innych firm',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nie znaleziono serwerów dla ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Nie udało się załadować serwerów: ${error}',
			'hubDetail.title' => 'Tytuł',
			'hubDetail.releaseYear' => 'Rok premiery',
			'hubDetail.dateAdded' => 'Data dodania',
			'hubDetail.rating' => 'Ocena',
			'hubDetail.noItemsFound' => 'Nie znaleziono elementów',
			'logs.clearLogs' => 'Wyczyść logi',
			'logs.copyLogs' => 'Kopiuj logi',
			'logs.uploadLogs' => 'Prześlij logi',
			'startup.failedTitle' => 'Nie udało się uruchomić Plezy',
			'startup.failedBody' => 'Coś poszło nie tak podczas uruchamiania. Poniższe szczegóły wskazują, co zawiodło.',
			'startup.failedBodyRepairable' => 'Zapisany plik ustawień Plezy jest uszkodzony i musi zostać odbudowany, zanim Plezy będzie mogło się uruchomić. Ponawianie nie pomoże — wybierz Napraw pamięć.',
			'startup.phaseLabel' => 'Krok',
			'startup.showDetails' => 'Pokaż szczegóły',
			'startup.hideDetails' => 'Ukryj szczegóły',
			'startup.copyDetails' => 'Kopiuj szczegóły',
			'startup.detailsCopied' => 'Skopiowano szczegóły do schowka',
			'startup.uploadDetails' => 'Prześlij szczegóły',
			'startup.repairStorage' => 'Napraw pamięć',
			'startup.repairTitle' => 'Naprawić zapisane dane?',
			'startup.repairBodyCommon' => 'Plik ustawień Plezy jest uszkodzony i nie można go odczytać. Naprawa przywraca wszystkie ustawienia do wartości domyślnych.',
			'startup.repairBodyOneCredential' => 'Jedno zapisane logowanie jest uszkodzone i nie można go odczytać. Naprawa usunie tylko je; pozostałe ustawienia pozostaną nietknięte.',
			'startup.repairBodySignInsKept' => 'Twoje serwery i profile powinny pozostać zalogowane.',
			'startup.repairBodySignInsLost' => 'Klucza chroniącego zapisane logowania nie można odzyskać z tego pliku, więc będziesz musiał zalogować się ponownie na każdym serwerze i profilu. Nic na Twoim serwerze multimediów nie zostanie zmienione.',
			'startup.repairBodySessionsUncertain' => 'Usługi śledzenia (MAL, AniList, Simkl, Trakt) i Seerr są przechowywane osobno i mogą, ale nie muszą przetrwać. Plezy dokładnie poinformuje Cię, co zachowało.',
			'startup.repairConfirm' => 'Napraw',
			'startup.repairSucceeded' => 'Naprawiono pamięć',
			'startup.repairNeedsRestart' => 'Naprawiono pamięć — wymagany restart',
			'startup.restartRequiredBody' => 'Twoje dane zostały naprawione, ale Plezy musi uruchomić się od nowa, zanim będzie mogło z nich korzystać. Zamknij Plezy i otwórz je ponownie.',
			'startup.quitPlezy' => 'Zamknij Plezy',
			'startup.repairFailed' => 'Naprawa nie powiodła się',
			'startup.repairKeptSignIns' => 'Twoje serwery i profile są nadal zalogowane.',
			'startup.repairLostSignIns' => 'Nie udało się odzyskać klucza chroniącego zapisane logowania. Musisz zalogować się ponownie na każdym serwerze i profilu.',
			'startup.repairLostSessions' => 'Utracono co najmniej jedno połączenie z usługą śledzenia lub Seerr i trzeba je ponownie połączyć.',
			'startup.backupTitle' => 'Zachowano kopię uszkodzonego pliku',
			'startup.backupWarning' => 'Zawiera Twoje dane logowania. Nie przesyłaj ani nie udostępniaj jej.',
			'startup.deleteBackup' => 'Usuń kopię',
			'startup.backupDeleted' => 'Usunięto kopię.',
			'startup.previousFailureTitle' => 'Ostatnim razem nie udało się uruchomić Plezy',
			'licenses.relatedPackages' => 'Powiązane pakiety',
			'licenses.license' => 'Licencja',
			'licenses.licenseNumber' => ({required Object number}) => 'Licencja ${number}',
			'licenses.licensesCount' => ({required Object count}) => 'Liczba licencji: ${count}',
			'navigation.libraries' => 'Biblioteki',
			'navigation.downloads' => 'Pobrania',
			'navigation.liveTv' => 'TV na żywo',
			'navigation.explore' => 'Przeglądaj',
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
			'explore.rows.airingAnime' => 'Najpopularniejsze emitowane anime',
			'explore.rows.popularAnime' => 'Najpopularniejsze anime',
			'explore.rows.trending' => 'Na czasie',
			'explore.rows.upcomingMovies' => 'Nadchodzące filmy',
			'explore.rows.upcomingShows' => 'Nadchodzące seriale',
			'explore.status.airing' => 'W emisji',
			'explore.status.ended' => 'Zakończony',
			'explore.status.canceled' => 'Anulowany',
			'explore.status.upcoming' => 'Nadchodzący',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${n} odcinek', few: '${n} odcinki', many: '${n} odcinków', other: '${n} odcinka', ), 
			'explore.cast' => 'Obsada',
			'explore.characters' => 'Postacie',
			'explore.addToWatchlist' => 'Dodaj do listy do obejrzenia',
			'explore.removeFromWatchlist' => 'Usuń z listy do obejrzenia',
			'explore.watchlistUpdateFailed' => 'Nie udało się zaktualizować listy do obejrzenia',
			'explore.notInLibrary' => 'Nie ma tego w Twojej bibliotece',
			'explore.inTheseLibraries' => 'W tych bibliotekach',
			'explore.checkingLibrary' => 'Sprawdzanie Twojej biblioteki...',
			'explore.emptyTitle' => 'Jeszcze nic tu nie ma',
			'explore.emptyMessage' => ({required Object source}) => 'Wiersze z ${source} pojawią się tutaj, gdy będą zawierać treści.',
			'explore.searchHint' => ({required Object source}) => 'Szukaj w ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Brak wyników dla "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Szukaj filmów i seriali w ${source}.',
			'explore.searchFailed' => 'Wyszukiwanie nie powiodło się. Sprawdź połączenie i spróbuj ponownie.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} popularne',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} emitowane',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} najwyżej oceniane',
			'explore.badge.rankFavorited' => ({required Object n}) => '#${n} w ulubionych',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} na czasie',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} w sezonie ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} ogląda teraz',
			'explore.badge.available' => 'Dostępne',
			'explore.badge.partiallyAvailable' => 'Częściowo dostępne',
			'explore.badge.availableIn4k' => 'Dostępne w 4K',
			'explore.badge.requested' => 'Zamówiono',
			'explore.badge.pendingApproval' => 'Oczekuje na zatwierdzenie',
			'explore.badge.processing' => 'Przetwarzanie',
			_ => null,
		} ?? switch (path) {
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${n} komentarz', few: '${n} komentarze', many: '${n} komentarzy', other: '${n} komentarza', ), 
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
			'explore.format.tvShort' => 'TV Short',
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: 'Polecany przez ${n} użytkownika', few: 'Polecany przez ${n} użytkowników', many: 'Polecany przez ${n} użytkowników', other: 'Polecany przez ${n} użytkownika', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Polecany przez ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Dodany do ulubionych przez ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} jeszcze nie wyemitowano',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Polecany przez ${percent} widzów',
			'explore.detail.relatedTitles' => 'Powiązane tytuły',
			'explore.detail.background' => 'Tło',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${n} wynik', few: '${n} wyniki', many: '${n} wyników', other: '${n} wyniku', ), 
			'liveTv.title' => 'TV na żywo',
			'liveTv.guide' => 'Przewodnik',
			'liveTv.noChannels' => 'Brak dostępnych kanałów',
			'liveTv.noDvr' => 'Brak skonfigurowanego DVR na żadnym serwerze',
			'liveTv.serverUnavailable' => 'Serwer telewizji na żywo jest niedostępny.',
			'liveTv.serverNotConnected' => 'Serwer telewizji na żywo nie jest połączony.',
			'liveTv.noPrograms' => 'Brak danych o programach',
			'liveTv.liveStreamFailed' => 'Transmisja na żywo nie powiodła się',
			'liveTv.unknownProgram' => 'Nieznany program',
			'liveTv.unknownHub' => 'Nieznane',
			'liveTv.unknownError' => 'Nieznany błąd',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanał ${number}',
			'liveTv.unknownChannel' => 'Nieznany kanał',
			'liveTv.live' => 'NA ŻYWO',
			'liveTv.reloadGuide' => 'Odśwież przewodnik',
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
			'liveTv.rulesProcessRequested' => 'Zażądano ponownej oceny reguł',
			'liveTv.recordShow' => 'Nagraj program',
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
			'playlists.itemCount' => ({required Object count}) => '${count} elementów',
			'playlists.oneItem' => '1 element',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pl'))(n, one: '${n} utwór', few: '${n} utwory', many: '${n} utworów', other: '${n} utworu', ), 
			'music.nowPlaying' => 'Teraz odtwarzane',
			'music.playingFrom' => ({required Object title}) => 'Odtwarzanie z ${title}',
			'music.queue' => 'Kolejka',
			'music.clearQueue' => 'Wyczyść kolejkę',
			'music.lyrics' => 'Tekst utworu',
			'music.noLyrics' => 'Brak tekstu utworu',
			'music.sleepTimer' => 'Wyłącznik czasowy',
			'music.sleepTimerEndOfTrack' => 'Koniec utworu',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minut',
			'music.stopPlayback' => 'Zatrzymaj odtwarzanie',
			'music.previousTrack' => 'Poprzedni utwór',
			'music.nextTrack' => 'Następny utwór',
			'music.repeat' => 'Powtarzaj',
			'music.repeatAll' => 'Powtarzaj wszystko',
			'music.repeatOne' => 'Powtarzaj jeden',
			'watchTogether.title' => 'Oglądaj razem',
			'watchTogether.description' => 'Oglądaj treści wspólnie z rodziną i znajomymi dzięki synchronizacji odtwarzania',
			'watchTogether.createSession' => 'Utwórz sesję',
			'watchTogether.creating' => 'Tworzenie...',
			'watchTogether.joinSession' => 'Dołącz do sesji',
			'watchTogether.joining' => 'Dołączanie...',
			'watchTogether.controlMode' => 'Tryb kontroli',
			'watchTogether.controlModeQuestion' => 'Kto może kontrolować odtwarzanie?',
			'watchTogether.hostOnly' => 'Tylko gospodarz',
			'watchTogether.anyone' => 'Każdy',
			'watchTogether.hostingSession' => 'Prowadzenie sesji',
			'watchTogether.inSession' => 'W sesji',
			'watchTogether.sessionCode' => 'Kod sesji',
			'watchTogether.openSessionControls' => 'Otwórz sterowanie sesją „Oglądaj razem”',
			'watchTogether.copySessionCode' => 'Skopiuj kod sesji',
			'watchTogether.hostControlsPlayback' => 'Gospodarz steruje odtwarzaniem',
			'watchTogether.anyoneCanControl' => 'Każdy może sterować odtwarzaniem',
			'watchTogether.hostControls' => 'Steruje gospodarz',
			'watchTogether.anyoneControls' => 'Steruje każdy',
			'watchTogether.participants' => 'Uczestnicy',
			'watchTogether.host' => 'Gospodarz',
			'watchTogether.hostBadge' => 'GOSPODARZ',
			'watchTogether.youAreHost' => 'Jesteś gospodarzem',
			'watchTogether.watchingWithOthers' => 'Oglądasz z innymi',
			'watchTogether.endSession' => 'Zakończ sesję',
			'watchTogether.leaveSession' => 'Opuść sesję',
			'watchTogether.endSessionQuestion' => 'Zakończyć sesję?',
			'watchTogether.leaveSessionQuestion' => 'Opuścić sesję?',
			'watchTogether.endSessionConfirm' => 'To zakończy sesję dla wszystkich uczestników.',
			'watchTogether.leaveSessionConfirm' => 'Zostaniesz usunięty z sesji.',
			'watchTogether.endSessionConfirmOverlay' => 'To zakończy sesję oglądania dla wszystkich uczestników.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Zostaniesz odłączony od sesji oglądania.',
			'watchTogether.end' => 'Zakończ',
			'watchTogether.leave' => 'Opuść',
			'watchTogether.syncing' => 'Synchronizacja...',
			'watchTogether.joinWatchSession' => 'Dołącz do sesji oglądania',
			'watchTogether.enterCodeHint' => 'Wprowadź 5-znakowy kod',
			'watchTogether.pasteFromClipboard' => 'Wklej ze schowka',
			'watchTogether.pleaseEnterCode' => 'Wprowadź kod sesji',
			'watchTogether.codeMustBe5Chars' => 'Kod sesji musi mieć 5 znaków',
			'watchTogether.joinInstructions' => 'Wpisz kod sesji hosta, aby dołączyć.',
			'watchTogether.failedToCreate' => 'Nie udało się utworzyć sesji',
			'watchTogether.failedToJoin' => 'Nie udało się dołączyć do sesji',
			'watchTogether.sessionCodeCopied' => 'Kod sesji skopiowany do schowka',
			'watchTogether.relayUnreachable' => 'Serwer pośredniczący jest nieosiągalny. Blokada operatora internetowego może uniemożliwiać korzystanie z funkcji „Oglądaj razem”.',
			'watchTogether.reconnectingToHost' => 'Ponowne łączenie z gospodarzem...',
			'watchTogether.currentPlayback' => 'Bieżące odtwarzanie',
			'watchTogether.joinCurrentPlayback' => 'Dołącz do bieżącego odtwarzania',
			'watchTogether.joinCurrentPlaybackDescription' => 'Wróć do treści oglądanej obecnie przez gospodarza',
			'watchTogether.failedToOpenCurrentPlayback' => 'Nie udało się otworzyć bieżącego odtwarzania',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} dołączył',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} opuścił',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} wstrzymał',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} wznowił',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} zmienił pozycję odtwarzania',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} buforuje',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} używa starszej wersji aplikacji — synchronizacja jest niedostępna',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Wznawianie bez ${name}',
			'watchTogether.waitingForParticipants' => 'Oczekiwanie na załadowanie u innych...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Oczekiwanie na ${name}...',
			'watchTogether.recentRooms' => 'Ostatnie pokoje',
			'watchTogether.renameRoom' => 'Zmień nazwę pokoju',
			'watchTogether.removeRoom' => 'Usuń',
			'watchTogether.guestSwitchUnavailable' => 'Nie można przełączyć — serwer niedostępny do synchronizacji',
			'watchTogether.guestSwitchFailed' => 'Nie można przełączyć — nie znaleziono treści na tym serwerze',
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
			'downloads.storageFull' => 'Pobieranie zostało zatrzymane, ponieważ pamięć urządzenia jest pełna. Zwolnij miejsce i spróbuj ponownie.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} odcinków w kolejce pobierania',
			'downloads.downloadDeleted' => 'Pobranie usunięte',
			'downloads.deleteConfirm' => ({required Object title}) => 'Usunąć "${title}" z tego urządzenia?',
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
			'downloads.deleteAll' => 'Usuń wszystko',
			'downloads.selectVersion' => 'Wybierz wersję',
			'downloads.allEpisodes' => 'Wszystkie odcinki',
			'downloads.unwatchedOnly' => 'Tylko nieobejrzane',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Następne ${count} nieobejrzanych',
			'downloads.customAmount' => 'Własna liczba...',
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
			'downloads.activeSyncRules' => 'Reguły synchronizacji',
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
			'downloads.syncRuleNotAvailableForProfile' => 'Niedostępne dla bieżącego profilu',
			'downloads.syncRuleUnknownServer' => 'Nieznany serwer',
			'downloads.syncRuleListCreated' => 'Utworzono regułę synchronizacji',
			'downloads.backgroundWarning.bannerBlocked' => 'Po opuszczeniu aplikacji pobieranie zostanie zatrzymane',
			'downloads.backgroundWarning.bannerDegraded' => 'Pobieranie w tle może być ograniczone',
			'downloads.backgroundWarning.bannerAction' => 'Szczegóły',
			'downloads.backgroundWarning.sheetTitle' => 'Pobieranie w tle jest zablokowane',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Pobieranie w tle może być ograniczone',
			'downloads.backgroundWarning.sheetIntro' => 'Android uniemożliwia Plezy niezawodne pobieranie plików w tle.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Twoje urządzenie ogranicza możliwość pobierania w tle przez Plezy.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Działanie Plezy w tle jest ograniczone. Ustaw użycie baterii lub działanie w tle na „Bez ograniczeń”.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android umieścił Plezy w ograniczonym trybie gotowości. Ustaw użycie baterii na „Bez ograniczeń”.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Powiadomienia o pobieraniu są wyłączone, więc postęp i opcje sterowania mogą być niedostępne.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Powiadomienia są wyłączone. W Android 13 lub nowszym są wymagane przy długim pobieraniu w tle.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Oszczędzanie danych jest włączone, co blokuje pobieranie w tle przez mobilną transmisję danych. Pobieranie powinno nadal działać przez Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Pobieranie wielokrotnie przerywało się, gdy Plezy działało w tle. Sprawdź ustawienia baterii lub działania w tle dla Plezy.',
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
			'companionRemote.pairing.discoveryDescription' => 'Urządzenia Plezy z tym samym kontem Plex pojawią się tutaj',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Łączenie...',
			'companionRemote.pairing.searchingForDevices' => 'Szukanie urządzeń...',
			'companionRemote.pairing.noDevicesFound' => 'Nie znaleziono urządzeń w sieci',
			'companionRemote.pairing.noDevicesHint' => 'Otwórz Plezy na komputerze i połącz oba urządzenia z tą samą siecią Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dostępne urządzenia',
			'companionRemote.pairing.manualConnection' => 'Połączenie ręczne',
			'companionRemote.pairing.cryptoInitFailed' => 'Nie udało się uruchomić bezpiecznego połączenia. Najpierw zaloguj się do Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Wprowadź adres hosta',
			'companionRemote.pairing.validationHostFormat' => 'Format musi być IP:port (np. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Limit czasu połączenia. Użyj tej samej sieci na obu urządzeniach.',
			'companionRemote.pairing.sessionNotFound' => 'Nie znaleziono urządzenia. Upewnij się, że Plezy działa na hoście.',
			'companionRemote.pairing.authFailed' => 'Uwierzytelnianie nie powiodło się. Oba urządzenia muszą używać tego samego konta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Nie udało się połączyć: ${error}',
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
			'companionRemote.remote.stop' => 'Stop',
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
			'videoSettings.playbackSpeed' => 'Prędkość odtwarzania',
			'videoSettings.normalSpeed' => 'Normalna',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktywny (${duration})',
			'videoSettings.zoom' => 'Powiększenie',
			'videoSettings.sleepTimer' => 'Wyłącznik czasowy',
			'videoSettings.audioSync' => 'Synchronizacja audio',
			'videoSettings.subtitleSync' => 'Synchronizacja napisów',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Wyjście audio',
			'videoSettings.performanceOverlay' => 'Nakładka wydajności',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Przestrzenny',
			'videoSettings.audioOutputSpatial' => 'Dźwięk przestrzenny',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioNormalization' => 'Normalizacja głośności',
			'videoSettings.audioDownmix' => 'Miksowanie do stereo',
			'performanceOverlay.color' => 'Kolor',
			'performanceOverlay.performance' => 'Wydajność',
			'performanceOverlay.buffer' => 'Bufor',
			'performanceOverlay.app' => 'Aplikacja',
			'performanceOverlay.decoder' => 'Dekoder',
			'performanceOverlay.rawDecoder' => 'Surowy dekoder',
			'performanceOverlay.tunneling' => 'Tunelowanie',
			'performanceOverlay.aspect' => 'Proporcje',
			'performanceOverlay.rotation' => 'Obrót',
			'performanceOverlay.dvSource' => 'Źródło DV',
			'performanceOverlay.dvPath' => 'Ścieżka DV',
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
			_ => null,
		} ?? switch (path) {
			'performanceOverlay.dvSampleAverage' => 'Śr. próbki DV',
			'performanceOverlay.maxLuma' => 'Maks. luma',
			'performanceOverlay.minLuma' => 'Min. luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Użyta pamięć podręczna',
			'performanceOverlay.cacheLimit' => 'Limit pamięci podręcznej',
			'performanceOverlay.speed' => 'Szybkość',
			'performanceOverlay.player' => 'Odtwarzacz',
			'performanceOverlay.memory' => 'Pamięć',
			'performanceOverlay.uiFps' => 'UI FPS',
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
			'metadataEdit.style' => 'Styl',
			'metadataEdit.mood' => 'Nastrój',
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
			'trakt.disconnectConfirmBody' => 'Plezy przestanie wysyłać zdarzenia do serwisu Trakt. Połączenie można przywrócić w dowolnym momencie.',
			'trakt.scrobble' => 'Śledzenie odtwarzania w czasie rzeczywistym',
			'trakt.scrobbleDescription' => 'Wysyłaj do serwisu Trakt zdarzenia odtwarzania, wstrzymania i zatrzymania.',
			'trakt.watchedSync' => 'Synchronizuj stan obejrzenia',
			'trakt.watchedSyncDescription' => 'Gdy oznaczysz element jako obejrzany w Plezy, zostanie on również oznaczony jako obejrzany w serwisie Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Połącz Seerr',
			'seerr.serverUrl' => 'Adres URL serwera',
			'seerr.serverUrlHelper' => 'Adres Twojej instancji Seerr',
			'seerr.checkServer' => 'Kontynuuj',
			'seerr.signInWithJellyfin' => 'Zaloguj się przez Jellyfin',
			'seerr.signInWithEmby' => 'Zaloguj się przez Emby',
			'seerr.signInWithLocal' => 'Użyj konta lokalnego',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Ta instancja Seerr nie oferuje metody logowania obsługiwanej przez Plezy.',
			'seerr.instance' => 'Instancja',
			'seerr.disconnectConfirm' => 'Odłączyć Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy zapomni tę instancję Seerr. Połącz ponownie w dowolnym momencie.',
			'seerr.request' => 'Zamów',
			'seerr.request4k' => 'Zamów w 4K',
			'seerr.seasons' => 'Sezony',
			'seerr.allSeasons' => 'Wszystkie sezony',
			'seerr.advancedOptions' => 'Zaawansowane',
			'seerr.destinationServer' => 'Serwer docelowy',
			'seerr.qualityProfile' => 'Profil jakości',
			'seerr.rootFolder' => 'Folder główny',
			'seerr.languageProfile' => 'Profil językowy',
			'seerr.requestSubmitted' => 'Zamówienie wysłane',
			'seerr.requestFailed' => ({required Object error}) => 'Zamówienie nie powiodło się: ${error}',
			'seerr.requestsLoadFailed' => 'Nie udało się wczytać opcji zamówienia',
			'seerr.nothingToRequest' => 'Wszystko jest już dostępne lub zamówione.',
			'seerr.statusAvailable' => 'Dostępne',
			'seerr.statusPartiallyAvailable' => 'Częściowo dostępne',
			'seerr.statusRequested' => 'Zamówione',
			'seerr.statusProcessing' => 'Przetwarzanie',
			'services.title' => 'Usługi',
			'services.hubSubtitle' => 'Synchronizuj postęp oglądania i zamawiaj nowe tytuły.',
			'services.notConnected' => 'Nie połączono',
			'services.connectedAs' => ({required Object username}) => 'Połączono jako @${username}',
			'services.scrobble' => 'Automatycznie śledź postęp',
			'services.scrobbleDescription' => 'Aktualizuj swoją listę po ukończeniu odcinka lub filmu.',
			'services.disconnectConfirm' => ({required Object service}) => 'Odłączyć ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy przestanie aktualizować ${service}. Połącz ponownie w dowolnym momencie.',
			'services.connectFailed' => ({required Object service}) => 'Nie udało się połączyć z ${service}. Spróbuj ponownie.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => 'Aktywuj Plezy w ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Odwiedź ${url} i wpisz ten kod:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Otwórz ${service}, aby aktywować',
			'services.deviceCode.copyCode' => 'Skopiuj kod aktywacyjny',
			'services.deviceCode.waitingForAuthorization' => 'Oczekiwanie na autoryzację…',
			'services.deviceCode.codeCopied' => 'Kod skopiowany',
			'services.oauthProxy.title' => ({required Object service}) => 'Zaloguj się do ${service}',
			'services.oauthProxy.body' => 'Zeskanuj ten kod QR lub otwórz URL na dowolnym urządzeniu.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Otwórz ${service}, aby się zalogować',
			'services.oauthProxy.copyUrl' => 'Skopiuj adres URL logowania',
			'services.oauthProxy.urlCopied' => 'URL skopiowany',
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
			_ => null,
		};
	}
}
