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
class TranslationsPl with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPl({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pl,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pl>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsPl _root = this; // ignore: unused_field

	@override 
	TranslationsPl $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPl(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppPl app = _TranslationsAppPl._(_root);
	@override late final _TranslationsAuthPl auth = _TranslationsAuthPl._(_root);
	@override late final _TranslationsCommonPl common = _TranslationsCommonPl._(_root);
	@override late final _TranslationsScreensPl screens = _TranslationsScreensPl._(_root);
	@override late final _TranslationsUpdatePl update = _TranslationsUpdatePl._(_root);
	@override late final _TranslationsSettingsPl settings = _TranslationsSettingsPl._(_root);
	@override late final _TranslationsSearchPl search = _TranslationsSearchPl._(_root);
	@override late final _TranslationsHotkeysPl hotkeys = _TranslationsHotkeysPl._(_root);
	@override late final _TranslationsPinEntryPl pinEntry = _TranslationsPinEntryPl._(_root);
	@override late final _TranslationsFileInfoPl fileInfo = _TranslationsFileInfoPl._(_root);
	@override late final _TranslationsMediaMenuPl mediaMenu = _TranslationsMediaMenuPl._(_root);
	@override late final _TranslationsAccessibilityPl accessibility = _TranslationsAccessibilityPl._(_root);
	@override late final _TranslationsTooltipsPl tooltips = _TranslationsTooltipsPl._(_root);
	@override late final _TranslationsVideoControlsPl videoControls = _TranslationsVideoControlsPl._(_root);
	@override late final _TranslationsUserStatusPl userStatus = _TranslationsUserStatusPl._(_root);
	@override late final _TranslationsMessagesPl messages = _TranslationsMessagesPl._(_root);
	@override late final _TranslationsSubtitlingStylingPl subtitlingStyling = _TranslationsSubtitlingStylingPl._(_root);
	@override late final _TranslationsMpvConfigPl mpvConfig = _TranslationsMpvConfigPl._(_root);
	@override late final _TranslationsDialogPl dialog = _TranslationsDialogPl._(_root);
	@override late final _TranslationsDiscoverPl discover = _TranslationsDiscoverPl._(_root);
	@override late final _TranslationsErrorsPl errors = _TranslationsErrorsPl._(_root);
	@override late final _TranslationsLibrariesPl libraries = _TranslationsLibrariesPl._(_root);
	@override late final _TranslationsAboutPl about = _TranslationsAboutPl._(_root);
	@override late final _TranslationsServerSelectionPl serverSelection = _TranslationsServerSelectionPl._(_root);
	@override late final _TranslationsHubDetailPl hubDetail = _TranslationsHubDetailPl._(_root);
	@override late final _TranslationsLogsPl logs = _TranslationsLogsPl._(_root);
	@override late final _TranslationsLicensesPl licenses = _TranslationsLicensesPl._(_root);
	@override late final _TranslationsNavigationPl navigation = _TranslationsNavigationPl._(_root);
	@override late final _TranslationsLiveTvPl liveTv = _TranslationsLiveTvPl._(_root);
	@override late final _TranslationsCollectionsPl collections = _TranslationsCollectionsPl._(_root);
	@override late final _TranslationsPlaylistsPl playlists = _TranslationsPlaylistsPl._(_root);
	@override late final _TranslationsWatchTogetherPl watchTogether = _TranslationsWatchTogetherPl._(_root);
	@override late final _TranslationsDownloadsPl downloads = _TranslationsDownloadsPl._(_root);
	@override late final _TranslationsShadersPl shaders = _TranslationsShadersPl._(_root);
	@override late final _TranslationsCompanionRemotePl companionRemote = _TranslationsCompanionRemotePl._(_root);
	@override late final _TranslationsVideoSettingsPl videoSettings = _TranslationsVideoSettingsPl._(_root);
	@override late final _TranslationsExternalPlayerPl externalPlayer = _TranslationsExternalPlayerPl._(_root);
	@override late final _TranslationsMetadataEditPl metadataEdit = _TranslationsMetadataEditPl._(_root);
}

// Path: app
class _TranslationsAppPl implements TranslationsAppEn {
	_TranslationsAppPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthPl implements TranslationsAuthEn {
	_TranslationsAuthPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Zaloguj się przez Plex';
	@override String get showQRCode => 'Pokaż kod QR';
	@override String get authenticate => 'Uwierzytelnienie';
	@override String get authenticationTimeout => 'Upłynął czas uwierzytelniania. Spróbuj ponownie.';
	@override String get scanQRToSignIn => 'Zeskanuj ten kod QR, aby się zalogować';
	@override String get waitingForAuth => 'Oczekiwanie na uwierzytelnienie...\nDokończ logowanie w przeglądarce.';
	@override String get useBrowser => 'Użyj przeglądarki';
}

// Path: common
class _TranslationsCommonPl implements TranslationsCommonEn {
	_TranslationsCommonPl._(this._root);

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
	@override String get shuffle => 'Losowo';
	@override String get addTo => 'Dodaj do...';
	@override String get createNew => 'Utwórz nowy';
	@override String get remove => 'Usuń';
	@override String get paste => 'Wklej';
	@override String get connect => 'Połącz';
	@override String get disconnect => 'Rozłącz';
	@override String get play => 'Odtwórz';
	@override String get pause => 'Pauza';
	@override String get resume => 'Wznów';
	@override String get error => 'Błąd';
	@override String get search => 'Szukaj';
	@override String get home => 'Strona główna';
	@override String get back => 'Wstecz';
	@override String get settings => 'Ustawienia';
	@override String get mute => 'Wycisz';
	@override String get ok => 'OK';
	@override String get loading => 'Ładowanie...';
	@override String get reconnect => 'Połącz ponownie';
	@override String get exitConfirmTitle => 'Zamknąć aplikację?';
	@override String get exitConfirmMessage => 'Czy na pewno chcesz wyjść?';
	@override String get dontAskAgain => 'Nie pytaj ponownie';
	@override String get exit => 'Wyjdź';
	@override String get viewAll => 'Pokaż wszystko';
	@override String get checkingNetwork => 'Sprawdzanie sieci...';
	@override String get refreshingServers => 'Odświeżanie serwerów...';
	@override String get loadingServers => 'Ładowanie serwerów...';
	@override String get connectingToServers => 'Łączenie z serwerami...';
	@override String get startingOfflineMode => 'Uruchamianie trybu offline...';
}

// Path: screens
class _TranslationsScreensPl implements TranslationsScreensEn {
	_TranslationsScreensPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licencje';
	@override String get switchProfile => 'Zmień profil';
	@override String get subtitleStyling => 'Styl napisów';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logi';
}

// Path: update
class _TranslationsUpdatePl implements TranslationsUpdateEn {
	_TranslationsUpdatePl._(this._root);

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
class _TranslationsSettingsPl implements TranslationsSettingsEn {
	_TranslationsSettingsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ustawienia';
	@override String get language => 'Język';
	@override String get theme => 'Motyw';
	@override String get appearance => 'Wygląd';
	@override String get videoPlayback => 'Odtwarzanie wideo';
	@override String get advanced => 'Zaawansowane';
	@override String get episodePosterMode => 'Styl plakatu odcinka';
	@override String get seriesPoster => 'Plakat serialu';
	@override String get seriesPosterDescription => 'Pokaż plakat serialu dla wszystkich odcinków';
	@override String get seasonPoster => 'Plakat sezonu';
	@override String get seasonPosterDescription => 'Pokaż plakat odpowiedniego sezonu dla odcinków';
	@override String get episodeThumbnail => 'Miniatura odcinka';
	@override String get episodeThumbnailDescription => 'Pokaż miniatury zrzutów ekranu odcinków w formacie 16:9';
	@override String get showHeroSectionDescription => 'Wyświetl karuzelę wyróżnionych treści na ekranie głównym';
	@override String get secondsLabel => 'Sekundy';
	@override String get minutesLabel => 'Minuty';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Wprowadź czas (${min}-${max})';
	@override String get systemTheme => 'Systemowy';
	@override String get systemThemeDescription => 'Podążaj za ustawieniami systemu';
	@override String get lightTheme => 'Jasny';
	@override String get darkTheme => 'Ciemny';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Czysta czerń dla ekranów OLED';
	@override String get libraryDensity => 'Gęstość biblioteki';
	@override String get compact => 'Kompaktowy';
	@override String get compactDescription => 'Mniejsze karty, więcej widocznych elementów';
	@override String get normal => 'Normalny';
	@override String get normalDescription => 'Domyślny rozmiar';
	@override String get comfortable => 'Wygodny';
	@override String get comfortableDescription => 'Większe karty, mniej widocznych elementów';
	@override String get viewMode => 'Tryb widoku';
	@override String get gridView => 'Siatka';
	@override String get gridViewDescription => 'Wyświetl elementy w układzie siatki';
	@override String get listView => 'Lista';
	@override String get listViewDescription => 'Wyświetl elementy w układzie listy';
	@override String get showHeroSection => 'Pokaż sekcję wyróżnioną';
	@override String get useGlobalHubs => 'Użyj układu Plex Home';
	@override String get useGlobalHubsDescription => 'Pokaż huby strony głównej jak w oficjalnym kliencie Plex. Gdy wyłączone, pokazuje rekomendacje per biblioteka.';
	@override String get showServerNameOnHubs => 'Pokaż nazwę serwera w hubach';
	@override String get showServerNameOnHubsDescription => 'Zawsze wyświetlaj nazwę serwera w tytułach hubów. Gdy wyłączone, pokazuje tylko dla zduplikowanych nazw.';
	@override String get alwaysKeepSidebarOpen => 'Zawsze utrzymuj panel boczny otwarty';
	@override String get alwaysKeepSidebarOpenDescription => 'Panel boczny jest rozwinięty, a obszar treści dostosowuje się';
	@override String get showUnwatchedCount => 'Pokaż liczbę nieobejrzanych';
	@override String get showUnwatchedCountDescription => 'Wyświetl liczbę nieobejrzanych odcinków w serialach i sezonach';
	@override String get hideSpoilers => 'Ukryj spoilery nieobejrzanych odcinków';
	@override String get hideSpoilersDescription => 'Rozmyj miniatury i ukryj opisy odcinków, których jeszcze nie obejrzałeś';
	@override String get playerBackend => 'Backend odtwarzacza';
	@override String get exoPlayer => 'ExoPlayer (Zalecany)';
	@override String get exoPlayerDescription => 'Natywny odtwarzacz Android z lepszą obsługą sprzętową';
	@override String get mpv => 'mpv';
	@override String get mpvDescription => 'Zaawansowany odtwarzacz z większą liczbą funkcji i obsługą napisów ASS';
	@override String get hardwareDecoding => 'Dekodowanie sprzętowe';
	@override String get hardwareDecodingDescription => 'Użyj akceleracji sprzętowej, gdy dostępna';
	@override String get bufferSize => 'Rozmiar bufora';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Automatyczny (Zalecany)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Twoje urządzenie ma ${heap}MB pamięci. Bufor ${size}MB może powodować problemy z odtwarzaniem.';
	@override String get subtitleStyling => 'Styl napisów';
	@override String get subtitleStylingDescription => 'Dostosuj wygląd napisów';
	@override String get smallSkipDuration => 'Krótki skok';
	@override String get largeSkipDuration => 'Długi skok';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekund';
	@override String get defaultSleepTimer => 'Domyślny wyłącznik czasowy';
	@override String minutesUnit({required Object minutes}) => '${minutes} minut';
	@override String get rememberTrackSelections => 'Zapamiętaj wybór ścieżek per serial/film';
	@override String get rememberTrackSelectionsDescription => 'Automatycznie zapisuj preferencje języka audio i napisów przy zmianie ścieżek podczas odtwarzania';
	@override String get clickVideoTogglesPlayback => 'Kliknięcie wideo przełącza odtwarzanie/pauzę';
	@override String get clickVideoTogglesPlaybackDescription => 'Gdy włączone, kliknięcie na odtwarzacz wideo odtwarza/wstrzymuje. W przeciwnym razie pokazuje/ukrywa kontrolki.';
	@override String get videoPlayerControls => 'Kontrolki odtwarzacza wideo';
	@override String get keyboardShortcuts => 'Skróty klawiszowe';
	@override String get keyboardShortcutsDescription => 'Dostosuj skróty klawiszowe';
	@override String get videoPlayerNavigation => 'Nawigacja odtwarzacza wideo';
	@override String get videoPlayerNavigationDescription => 'Użyj klawiszy strzałek do nawigacji kontrolkami odtwarzacza';
	@override String get crashReporting => 'Raportowanie błędów';
	@override String get crashReportingDescription => 'Wysyłaj raporty o błędach, aby pomóc ulepszyć aplikację';
	@override String get debugLogging => 'Logowanie debugowania';
	@override String get debugLoggingDescription => 'Włącz szczegółowe logowanie do rozwiązywania problemów';
	@override String get viewLogs => 'Pokaż logi';
	@override String get viewLogsDescription => 'Pokaż logi aplikacji';
	@override String get clearCache => 'Wyczyść pamięć podręczną';
	@override String get clearCacheDescription => 'Spowoduje to wyczyszczenie wszystkich zapisanych obrazów i danych. Po wyczyszczeniu aplikacja może ładować treści wolniej.';
	@override String get clearCacheSuccess => 'Pamięć podręczna wyczyszczona';
	@override String get resetSettings => 'Zresetuj ustawienia';
	@override String get resetSettingsDescription => 'Wszystkie ustawienia zostaną przywrócone do wartości domyślnych. Tej operacji nie można cofnąć.';
	@override String get resetSettingsSuccess => 'Ustawienia zresetowane pomyślnie';
	@override String get shortcutsReset => 'Skróty przywrócone do domyślnych';
	@override String get about => 'O aplikacji';
	@override String get aboutDescription => 'Informacje o aplikacji i licencje';
	@override String get updates => 'Aktualizacje';
	@override String get updateAvailable => 'Dostępna aktualizacja';
	@override String get checkForUpdates => 'Sprawdź aktualizacje';
	@override String get validationErrorEnterNumber => 'Wprowadź prawidłową liczbę';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Czas musi być między ${min} a ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Skrót jest już przypisany do ${action}';
	@override String shortcutUpdated({required Object action}) => 'Skrót zaktualizowany dla ${action}';
	@override String get autoSkip => 'Automatyczne pomijanie';
	@override String get autoSkipIntro => 'Automatyczne pomijanie intro';
	@override String get autoSkipIntroDescription => 'Automatycznie pomijaj znaczniki intro po kilku sekundach';
	@override String get autoSkipCredits => 'Automatyczne pomijanie napisów końcowych';
	@override String get autoSkipCreditsDescription => 'Automatycznie pomijaj napisy końcowe i odtwórz następny odcinek';
	@override String get autoSkipDelay => 'Opóźnienie automatycznego pomijania';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Czekaj ${seconds} sekund przed automatycznym pominięciem';
	@override String get introPattern => 'Wzorzec znacznika intro';
	@override String get introPatternDescription => 'Wyrażenie regularne do rozpoznawania znaczników intro w tytułach rozdziałów';
	@override String get creditsPattern => 'Wzorzec znacznika napisów końcowych';
	@override String get creditsPatternDescription => 'Wyrażenie regularne do rozpoznawania znaczników napisów końcowych w tytułach rozdziałów';
	@override String get invalidRegex => 'Nieprawidłowe wyrażenie regularne';
	@override String get downloads => 'Pobrania';
	@override String get downloadLocationDescription => 'Wybierz miejsce przechowywania pobranych treści';
	@override String get downloadLocationDefault => 'Domyślne (Pamięć aplikacji)';
	@override String get downloadLocationCustom => 'Niestandardowa lokalizacja';
	@override String get selectFolder => 'Wybierz folder';
	@override String get resetToDefault => 'Przywróć domyślne';
	@override String currentPath({required Object path}) => 'Bieżąca: ${path}';
	@override String get downloadLocationChanged => 'Lokalizacja pobierania zmieniona';
	@override String get downloadLocationReset => 'Lokalizacja pobierania przywrócona do domyślnej';
	@override String get downloadLocationInvalid => 'Wybrany folder nie jest zapisywalny';
	@override String get downloadLocationSelectError => 'Nie udało się wybrać folderu';
	@override String get downloadOnWifiOnly => 'Pobieraj tylko przez WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Blokuj pobieranie na danych komórkowych';
	@override String get cellularDownloadBlocked => 'Pobieranie na danych komórkowych jest wyłączone. Połącz się z WiFi lub zmień ustawienie.';
	@override String get maxVolume => 'Maksymalna głośność';
	@override String get maxVolumeDescription => 'Pozwól na wzmocnienie głośności powyżej 100% dla cichych multimediów';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Pokaż, co oglądasz na Discordzie';
	@override String get autoPip => 'Automatyczny obraz w obrazie';
	@override String get autoPipDescription => 'Automatycznie przejdź do trybu obraz w obrazie przy wyjściu z aplikacji podczas odtwarzania';
	@override String get matchContentFrameRate => 'Dopasuj częstotliwość klatek do treści';
	@override String get matchContentFrameRateDescription => 'Dostosuj częstotliwość odświeżania ekranu do treści wideo, zmniejszając drgania i oszczędzając baterię';
	@override String get tunneledPlayback => 'Tunelowane odtwarzanie';
	@override String get tunneledPlaybackDescription => 'Użyj sprzętowo przyspieszonego tunelowania wideo. Wyłącz, jeśli widzisz czarny ekran z dźwiękiem przy treściach HDR';
	@override String get requireProfileSelectionOnOpen => 'Pytaj o profil przy otwarciu aplikacji';
	@override String get requireProfileSelectionOnOpenDescription => 'Pokaż wybór profilu za każdym razem, gdy aplikacja jest otwierana';
	@override String get confirmExitOnBack => 'Potwierdź przed wyjściem';
	@override String get confirmExitOnBackDescription => 'Pokaż dialog potwierdzenia przy naciśnięciu wstecz, aby wyjść z aplikacji';
	@override String get showNavBarLabels => 'Pokaż etykiety paska nawigacji';
	@override String get showNavBarLabelsDescription => 'Wyświetl tekstowe etykiety pod ikonami paska nawigacji';
}

// Path: search
class _TranslationsSearchPl implements TranslationsSearchEn {
	_TranslationsSearchPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Szukaj filmów, seriali, muzyki...';
	@override String get tryDifferentTerm => 'Spróbuj innego wyszukiwania';
	@override String get searchYourMedia => 'Przeszukaj swoje media';
	@override String get enterTitleActorOrKeyword => 'Wprowadź tytuł, aktora lub słowo kluczowe';
}

// Path: hotkeys
class _TranslationsHotkeysPl implements TranslationsHotkeysEn {
	_TranslationsHotkeysPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Ustaw skrót dla ${actionName}';
	@override String get clearShortcut => 'Wyczyść skrót';
	@override late final _TranslationsHotkeysActionsPl actions = _TranslationsHotkeysActionsPl._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryPl implements TranslationsPinEntryEn {
	_TranslationsPinEntryPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Wprowadź PIN';
	@override String get showPin => 'Pokaż PIN';
	@override String get hidePin => 'Ukryj PIN';
}

// Path: fileInfo
class _TranslationsFileInfoPl implements TranslationsFileInfoEn {
	_TranslationsFileInfoPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informacje o pliku';
	@override String get video => 'Wideo';
	@override String get audio => 'Audio';
	@override String get file => 'Plik';
	@override String get advanced => 'Zaawansowane';
	@override String get codec => 'Kodek';
	@override String get resolution => 'Rozdzielczość';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Klatki na sekundę';
	@override String get aspectRatio => 'Proporcje';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Głębia bitowa';
	@override String get colorSpace => 'Przestrzeń kolorów';
	@override String get colorRange => 'Zakres kolorów';
	@override String get colorPrimaries => 'Kolory podstawowe';
	@override String get chromaSubsampling => 'Subsampling chrominancji';
	@override String get channels => 'Kanały';
	@override String get path => 'Ścieżka';
	@override String get size => 'Rozmiar';
	@override String get container => 'Kontener';
	@override String get duration => 'Czas trwania';
	@override String get optimizedForStreaming => 'Zoptymalizowane do strumieniowania';
	@override String get has64bitOffsets => '64-bitowe offsety';
}

// Path: mediaMenu
class _TranslationsMediaMenuPl implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Oznacz jako obejrzane';
	@override String get markAsUnwatched => 'Oznacz jako nieobejrzane';
	@override String get removeFromContinueWatching => 'Usuń z kontynuowania oglądania';
	@override String get goToSeries => 'Przejdź do serialu';
	@override String get goToSeason => 'Przejdź do sezonu';
	@override String get shufflePlay => 'Odtwarzanie losowe';
	@override String get fileInfo => 'Informacje o pliku';
	@override String get deleteFromServer => 'Usuń z serwera';
	@override String get confirmDelete => 'To trwale usunie te multimedia i ich pliki z twojego serwera. Tej operacji nie można cofnąć.';
	@override String get deleteMultipleWarning => 'Obejmuje to wszystkie odcinki i ich pliki.';
	@override String get mediaDeletedSuccessfully => 'Element multimedialny usunięty pomyślnie';
	@override String get mediaFailedToDelete => 'Nie udało się usunąć elementu multimedialnego';
	@override String get rate => 'Oceń';
}

// Path: accessibility
class _TranslationsAccessibilityPl implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, serial TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'obejrzane';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} procent obejrzane';
	@override String get mediaCardUnwatched => 'nieobejrzane';
	@override String get tapToPlay => 'Dotknij, aby odtworzyć';
}

// Path: tooltips
class _TranslationsTooltipsPl implements TranslationsTooltipsEn {
	_TranslationsTooltipsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Odtwarzanie losowe';
	@override String get playTrailer => 'Odtwórz zwiastun';
	@override String get markAsWatched => 'Oznacz jako obejrzane';
	@override String get markAsUnwatched => 'Oznacz jako nieobejrzane';
}

// Path: videoControls
class _TranslationsVideoControlsPl implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Napisy';
	@override String get resetToZero => 'Zresetuj do 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} odtwarza później';
	@override String playsEarlier({required Object label}) => '${label} odtwarza wcześniej';
	@override String get noOffset => 'Bez przesunięcia';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Wypełnij ekran';
	@override String get stretch => 'Rozciągnij';
	@override String get lockRotation => 'Zablokuj obrót';
	@override String get unlockRotation => 'Odblokuj obrót';
	@override String get timerActive => 'Wyłącznik aktywny';
	@override String playbackWillPauseIn({required Object duration}) => 'Odtwarzanie zatrzyma się za ${duration}';
	@override String get sleepTimerCompleted => 'Wyłącznik czasowy zakończony — odtwarzanie wstrzymane';
	@override String get stillWatching => 'Nadal oglądasz?';
	@override String pausingIn({required Object seconds}) => 'Pauza za ${seconds}s';
	@override String get continueWatching => 'Kontynuuj';
	@override String get autoPlayNext => 'Automatycznie odtwórz następny';
	@override String get playNext => 'Odtwórz następny';
	@override String get playButton => 'Odtwórz';
	@override String get pauseButton => 'Pauza';
	@override String seekBackwardButton({required Object seconds}) => 'Przewiń do tyłu o ${seconds} sekund';
	@override String seekForwardButton({required Object seconds}) => 'Przewiń do przodu o ${seconds} sekund';
	@override String get previousButton => 'Poprzedni odcinek';
	@override String get nextButton => 'Następny odcinek';
	@override String get previousChapterButton => 'Poprzedni rozdział';
	@override String get nextChapterButton => 'Następny rozdział';
	@override String get muteButton => 'Wycisz';
	@override String get unmuteButton => 'Wyłącz wyciszenie';
	@override String get settingsButton => 'Ustawienia wideo';
	@override String get audioTrackButton => 'Ścieżki audio';
	@override String get subtitlesButton => 'Napisy';
	@override String get tracksButton => 'Audio i napisy';
	@override String get chaptersButton => 'Rozdziały';
	@override String get versionsButton => 'Wersje wideo';
	@override String get pipButton => 'Tryb obraz w obrazie';
	@override String get aspectRatioButton => 'Proporcje';
	@override String get ambientLighting => 'Oświetlenie otoczenia';
	@override String get ambientLightingOn => 'Włącz oświetlenie otoczenia';
	@override String get ambientLightingOff => 'Wyłącz oświetlenie otoczenia';
	@override String get fullscreenButton => 'Wejdź w pełny ekran';
	@override String get exitFullscreenButton => 'Wyjdź z pełnego ekranu';
	@override String get alwaysOnTopButton => 'Zawsze na wierzchu';
	@override String get rotationLockButton => 'Blokada obrotu';
	@override String get timelineSlider => 'Oś czasu wideo';
	@override String get volumeSlider => 'Poziom głośności';
	@override String endsAt({required Object time}) => 'Kończy się o ${time}';
	@override String get pipActive => 'Odtwarzanie w trybie obraz w obrazie';
	@override String get pipFailed => 'Nie udało się uruchomić trybu obraz w obrazie';
	@override late final _TranslationsVideoControlsPipErrorsPl pipErrors = _TranslationsVideoControlsPipErrorsPl._(_root);
	@override String get chapters => 'Rozdziały';
	@override String get noChaptersAvailable => 'Brak dostępnych rozdziałów';
	@override String get queue => 'Kolejka';
	@override String get noQueueItems => 'Brak elementów w kolejce';
}

// Path: userStatus
class _TranslationsUserStatusPl implements TranslationsUserStatusEn {
	_TranslationsUserStatusPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Administrator';
	@override String get restricted => 'Ograniczony';
	@override String get protected => 'Chroniony';
	@override String get current => 'BIEŻĄCY';
}

// Path: messages
class _TranslationsMessagesPl implements TranslationsMessagesEn {
	_TranslationsMessagesPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Oznaczono jako obejrzane';
	@override String get markedAsUnwatched => 'Oznaczono jako nieobejrzane';
	@override String get markedAsWatchedOffline => 'Oznaczono jako obejrzane (zsynchronizuje się po połączeniu)';
	@override String get markedAsUnwatchedOffline => 'Oznaczono jako nieobejrzane (zsynchronizuje się po połączeniu)';
	@override String get removedFromContinueWatching => 'Usunięto z kontynuowania oglądania';
	@override String errorLoading({required Object error}) => 'Błąd: ${error}';
	@override String get fileInfoNotAvailable => 'Informacje o pliku niedostępne';
	@override String errorLoadingFileInfo({required Object error}) => 'Błąd ładowania informacji o pliku: ${error}';
	@override String get errorLoadingSeries => 'Błąd ładowania serialu';
	@override String get errorLoadingSeason => 'Błąd ładowania sezonu';
	@override String get musicNotSupported => 'Odtwarzanie muzyki nie jest jeszcze obsługiwane';
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
	@override String get noEpisodesFound => 'Nie znaleziono odcinków w pierwszym sezonie';
	@override String get noEpisodesFoundGeneral => 'Nie znaleziono odcinków';
	@override String get noResultsFound => 'Nie znaleziono wyników';
	@override String sleepTimerSet({required Object label}) => 'Wyłącznik czasowy ustawiony na ${label}';
	@override String get noItemsAvailable => 'Brak dostępnych elementów';
	@override String get failedToCreatePlayQueueNoItems => 'Nie udało się utworzyć kolejki odtwarzania — brak elementów';
	@override String failedPlayback({required Object action, required Object error}) => 'Nie udało się ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Przełączanie na kompatybilny odtwarzacz...';
	@override String get logsUploaded => 'Logi przesłane';
	@override String get logsUploadFailed => 'Nie udało się przesłać logów';
	@override String get logId => 'ID logu';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingPl implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opcje stylu';
	@override String get fontSize => 'Rozmiar czcionki';
	@override String get textColor => 'Kolor tekstu';
	@override String get borderSize => 'Rozmiar obramowania';
	@override String get borderColor => 'Kolor obramowania';
	@override String get backgroundOpacity => 'Przezroczystość tła';
	@override String get backgroundColor => 'Kolor tła';
	@override String get position => 'Pozycja';
}

// Path: mpvConfig
class _TranslationsMpvConfigPl implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Zaawansowane ustawienia odtwarzacza wideo';
	@override String get presets => 'Presety';
	@override String get noPresets => 'Brak zapisanych presetów';
	@override String get saveAsPreset => 'Zapisz jako preset...';
	@override String get presetName => 'Nazwa presetu';
	@override String get presetNameHint => 'Wprowadź nazwę dla tego presetu';
	@override String get loadPreset => 'Załaduj';
	@override String get deletePreset => 'Usuń';
	@override String get presetSaved => 'Preset zapisany';
	@override String get presetLoaded => 'Preset załadowany';
	@override String get presetDeleted => 'Preset usunięty';
	@override String get confirmDeletePreset => 'Czy na pewno chcesz usunąć ten preset?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogPl implements TranslationsDialogEn {
	_TranslationsDialogPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Potwierdź działanie';
}

// Path: discover
class _TranslationsDiscoverPl implements TranslationsDiscoverEn {
	_TranslationsDiscoverPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Odkryj';
	@override String get switchProfile => 'Zmień profil';
	@override String get noContentAvailable => 'Brak dostępnych treści';
	@override String get addMediaToLibraries => 'Dodaj multimedia do swoich bibliotek';
	@override String get continueWatching => 'Kontynuuj oglądanie';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Opis';
	@override String get cast => 'Obsada';
	@override String get extras => 'Zwiastuny i dodatki';
	@override String get seasons => 'Sezony';
	@override String get studio => 'Studio';
	@override String get rating => 'Ocena';
	@override String episodeCount({required Object count}) => '${count} odcinków';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} obejrzanych';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serial TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min pozostało';
}

// Path: errors
class _TranslationsErrorsPl implements TranslationsErrorsEn {
	_TranslationsErrorsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Wyszukiwanie nie powiodło się: ${error}';
	@override String connectionTimeout({required Object context}) => 'Limit czasu połączenia przy ładowaniu ${context}';
	@override String get connectionFailed => 'Nie można połączyć z serwerem Plex';
	@override String failedToLoad({required Object context, required Object error}) => 'Nie udało się załadować ${context}: ${error}';
	@override String get noClientAvailable => 'Brak dostępnego klienta';
	@override String authenticationFailed({required Object error}) => 'Uwierzytelnienie nie powiodło się: ${error}';
	@override String get couldNotLaunchUrl => 'Nie można otworzyć URL uwierzytelniania';
	@override String get pleaseEnterToken => 'Wprowadź token';
	@override String get invalidToken => 'Nieprawidłowy token';
	@override String failedToVerifyToken({required Object error}) => 'Nie udało się zweryfikować tokena: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Nie udało się przełączyć na ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesPl implements TranslationsLibrariesEn {
	_TranslationsLibrariesPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteki';
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
	@override String get thisLibraryIsEmpty => 'Ta biblioteka jest pusta';
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
	@override late final _TranslationsLibrariesTabsPl tabs = _TranslationsLibrariesTabsPl._(_root);
	@override late final _TranslationsLibrariesGroupingsPl groupings = _TranslationsLibrariesGroupingsPl._(_root);
}

// Path: about
class _TranslationsAboutPl implements TranslationsAboutEn {
	_TranslationsAboutPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'O aplikacji';
	@override String get openSourceLicenses => 'Licencje open source';
	@override String versionLabel({required Object version}) => 'Wersja ${version}';
	@override String get appDescription => 'Piękny klient Plex na Flutter';
	@override String get viewLicensesDescription => 'Zobacz licencje bibliotek zewnętrznych';
}

// Path: serverSelection
class _TranslationsServerSelectionPl implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Nie udało się połączyć z żadnym serwerem. Sprawdź sieć i spróbuj ponownie.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nie znaleziono serwerów dla ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Nie udało się załadować serwerów: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailPl implements TranslationsHubDetailEn {
	_TranslationsHubDetailPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tytuł';
	@override String get releaseYear => 'Rok premiery';
	@override String get dateAdded => 'Data dodania';
	@override String get rating => 'Ocena';
	@override String get noItemsFound => 'Nie znaleziono elementów';
}

// Path: logs
class _TranslationsLogsPl implements TranslationsLogsEn {
	_TranslationsLogsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Wyczyść logi';
	@override String get copyLogs => 'Kopiuj logi';
	@override String get uploadLogs => 'Prześlij logi';
	@override String get error => 'Błąd:';
	@override String get stackTrace => 'Ślad stosu:';
}

// Path: licenses
class _TranslationsLicensesPl implements TranslationsLicensesEn {
	_TranslationsLicensesPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Powiązane pakiety';
	@override String get license => 'Licencja';
	@override String licenseNumber({required Object number}) => 'Licencja ${number}';
	@override String licensesCount({required Object count}) => '${count} licencji';
}

// Path: navigation
class _TranslationsNavigationPl implements TranslationsNavigationEn {
	_TranslationsNavigationPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Biblioteki';
	@override String get downloads => 'Pobrania';
	@override String get liveTv => 'TV na żywo';
}

// Path: liveTv
class _TranslationsLiveTvPl implements TranslationsLiveTvEn {
	_TranslationsLiveTvPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV na żywo';
	@override String get channels => 'Kanały';
	@override String get guide => 'Przewodnik';
	@override String get noChannels => 'Brak dostępnych kanałów';
	@override String get noDvr => 'Brak skonfigurowanego DVR na żadnym serwerze';
	@override String get tuneFailed => 'Nie udało się dostroić kanału';
	@override String get loading => 'Ładowanie kanałów...';
	@override String get nowPlaying => 'Teraz odtwarzane';
	@override String get noPrograms => 'Brak danych o programach';
	@override String channelNumber({required Object number}) => 'Kn. ${number}';
	@override String get live => 'NA ŻYWO';
	@override String get hd => 'HD';
	@override String get premiere => 'NOWE';
	@override String get reloadGuide => 'Odśwież przewodnik';
	@override String get allChannels => 'Wszystkie kanały';
	@override String get now => 'Teraz';
	@override String get today => 'Dzisiaj';
	@override String get midnight => 'Północ';
	@override String get overnight => 'Nocą';
	@override String get morning => 'Rano';
	@override String get daytime => 'W ciągu dnia';
	@override String get evening => 'Wieczorem';
	@override String get lateNight => 'Późna noc';
	@override String get whatsOn => 'Co leci';
	@override String get watchChannel => 'Oglądaj kanał';
}

// Path: collections
class _TranslationsCollectionsPl implements TranslationsCollectionsEn {
	_TranslationsCollectionsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kolekcje';
	@override String get collection => 'Kolekcja';
	@override String get empty => 'Kolekcja jest pusta';
	@override String get unknownLibrarySection => 'Nie można usunąć: Nieznana sekcja biblioteki';
	@override String get deleteCollection => 'Usuń kolekcję';
	@override String deleteConfirm({required Object title}) => 'Czy na pewno chcesz usunąć "${title}"? Tej operacji nie można cofnąć.';
	@override String get deleted => 'Kolekcja usunięta';
	@override String get deleteFailed => 'Nie udało się usunąć kolekcji';
	@override String deleteFailedWithError({required Object error}) => 'Nie udało się usunąć kolekcji: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Nie udało się załadować elementów kolekcji: ${error}';
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
}

// Path: playlists
class _TranslationsPlaylistsPl implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsPl._(this._root);

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
	@override String get errorCreating => 'Nie udało się utworzyć playlisty';
	@override String get errorDeleting => 'Nie udało się usunąć playlisty';
	@override String get errorLoading => 'Nie udało się załadować playlist';
	@override String get errorAdding => 'Nie udało się dodać do playlisty';
	@override String get errorReordering => 'Nie udało się zmienić kolejności elementu playlisty';
	@override String get errorRemoving => 'Nie udało się usunąć z playlisty';
}

// Path: watchTogether
class _TranslationsWatchTogetherPl implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oglądaj razem';
	@override String get description => 'Oglądaj treści zsynchronizowane z przyjaciółmi i rodziną';
	@override String get createSession => 'Utwórz sesję';
	@override String get creating => 'Tworzenie...';
	@override String get joinSession => 'Dołącz do sesji';
	@override String get joining => 'Dołączanie...';
	@override String get controlMode => 'Tryb kontroli';
	@override String get controlModeQuestion => 'Kto może kontrolować odtwarzanie?';
	@override String get hostOnly => 'Tylko host';
	@override String get anyone => 'Każdy';
	@override String get hostingSession => 'Hostowanie sesji';
	@override String get inSession => 'W sesji';
	@override String get sessionCode => 'Kod sesji';
	@override String get hostControlsPlayback => 'Host kontroluje odtwarzanie';
	@override String get anyoneCanControl => 'Każdy może kontrolować odtwarzanie';
	@override String get hostControls => 'Kontrola hosta';
	@override String get anyoneControls => 'Kontrola każdego';
	@override String get participants => 'Uczestnicy';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Jesteś hostem';
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
	@override String get enterCodeHint => 'Wprowadź 8-znakowy kod';
	@override String get pasteFromClipboard => 'Wklej ze schowka';
	@override String get pleaseEnterCode => 'Wprowadź kod sesji';
	@override String get codeMustBe8Chars => 'Kod sesji musi mieć 8 znaków';
	@override String get joinInstructions => 'Wprowadź kod sesji udostępniony przez hosta, aby dołączyć do sesji oglądania.';
	@override String get failedToCreate => 'Nie udało się utworzyć sesji';
	@override String get failedToJoin => 'Nie udało się dołączyć do sesji';
	@override String get sessionCodeCopied => 'Kod sesji skopiowany do schowka';
	@override String get relayUnreachable => 'Serwer przekaźnika jest nieosiągalny. Może to być spowodowane blokadą przez twojego dostawcę internetu. Możesz spróbować, ale Oglądaj razem może nie działać.';
	@override String get reconnectingToHost => 'Ponowne łączenie z hostem...';
	@override String get currentPlayback => 'Bieżące odtwarzanie';
	@override String get joinCurrentPlayback => 'Dołącz do bieżącego odtwarzania';
	@override String get joinCurrentPlaybackDescription => 'Wróć do tego, co host aktualnie ogląda';
	@override String get failedToOpenCurrentPlayback => 'Nie udało się otworzyć bieżącego odtwarzania';
	@override String participantJoined({required Object name}) => '${name} dołączył';
	@override String participantLeft({required Object name}) => '${name} opuścił';
}

// Path: downloads
class _TranslationsDownloadsPl implements TranslationsDownloadsEn {
	_TranslationsDownloadsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pobrania';
	@override String get manage => 'Zarządzaj';
	@override String get tvShows => 'Seriale TV';
	@override String get movies => 'Filmy';
	@override String get noDownloads => 'Brak pobrań';
	@override String get noDownloadsDescription => 'Pobrane treści pojawią się tutaj do oglądania offline';
	@override String get downloadNow => 'Pobierz';
	@override String get deleteDownload => 'Usuń pobranie';
	@override String get retryDownload => 'Ponów pobieranie';
	@override String get downloadQueued => 'Pobranie w kolejce';
	@override String episodesQueued({required Object count}) => '${count} odcinków w kolejce pobierania';
	@override String get downloadDeleted => 'Pobranie usunięte';
	@override String deleteConfirm({required Object title}) => 'Czy na pewno chcesz usunąć "${title}"? Spowoduje to usunięcie pobranego pliku z urządzenia.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Usuwanie ${title}... (${current} z ${total})';
	@override String get noDownloadsTree => 'Brak pobrań';
	@override String get pauseAll => 'Wstrzymaj wszystko';
	@override String get resumeAll => 'Wznów wszystko';
	@override String get deleteAll => 'Usuń wszystko';
}

// Path: shaders
class _TranslationsShadersPl implements TranslationsShadersEn {
	_TranslationsShadersPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shadery';
	@override String get noShaderDescription => 'Bez ulepszenia wideo';
	@override String get nvscalerDescription => 'Skalowanie obrazu NVIDIA dla ostrzejszego wideo';
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
class _TranslationsCompanionRemotePl implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemotePl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pilot zdalny';
	@override String get connectToDevice => 'Połącz z urządzeniem';
	@override String get hostRemoteSession => 'Hostuj sesję zdalną';
	@override String get controlThisDevice => 'Steruj tym urządzeniem ze swojego telefonu';
	@override String get remoteControl => 'Pilot zdalny';
	@override String get controlDesktop => 'Steruj urządzeniem desktop';
	@override String connectedTo({required Object name}) => 'Połączono z ${name}';
	@override late final _TranslationsCompanionRemoteSessionPl session = _TranslationsCompanionRemoteSessionPl._(_root);
	@override late final _TranslationsCompanionRemotePairingPl pairing = _TranslationsCompanionRemotePairingPl._(_root);
	@override late final _TranslationsCompanionRemoteRemotePl remote = _TranslationsCompanionRemoteRemotePl._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsPl implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Ustawienia odtwarzania';
	@override String get playbackSpeed => 'Prędkość odtwarzania';
	@override String get sleepTimer => 'Wyłącznik czasowy';
	@override String get audioSync => 'Synchronizacja audio';
	@override String get subtitleSync => 'Synchronizacja napisów';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Wyjście audio';
	@override String get performanceOverlay => 'Nakładka wydajności';
	@override String get audioPassthrough => 'Bezpośrednie audio';
	@override String get audioNormalization => 'Normalizacja audio';
}

// Path: externalPlayer
class _TranslationsExternalPlayerPl implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zewnętrzny odtwarzacz';
	@override String get useExternalPlayer => 'Użyj zewnętrznego odtwarzacza';
	@override String get useExternalPlayerDescription => 'Otwieraj wideo w zewnętrznej aplikacji zamiast wbudowanego odtwarzacza';
	@override String get selectPlayer => 'Wybierz odtwarzacz';
	@override String get systemDefault => 'Domyślny systemowy';
	@override String get addCustomPlayer => 'Dodaj niestandardowy odtwarzacz';
	@override String get playerName => 'Nazwa odtwarzacza';
	@override String get playerCommand => 'Polecenie';
	@override String get playerPackage => 'Nazwa pakietu';
	@override String get playerUrlScheme => 'Schemat URL';
	@override String get customPlayer => 'Niestandardowy odtwarzacz';
	@override String get off => 'Wyłączony';
	@override String get launchFailed => 'Nie udało się otworzyć zewnętrznego odtwarzacza';
	@override String appNotInstalled({required Object name}) => '${name} nie jest zainstalowany';
	@override String get playInExternalPlayer => 'Odtwórz w zewnętrznym odtwarzaczu';
}

// Path: metadataEdit
class _TranslationsMetadataEditPl implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditPl._(this._root);

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
	@override String get tagline => 'Tagline';
	@override String get summary => 'Opis';
	@override String get poster => 'Plakat';
	@override String get background => 'Tło';
	@override String get selectPoster => 'Wybierz plakat';
	@override String get selectBackground => 'Wybierz tło';
	@override String get fromUrl => 'Z URL';
	@override String get uploadFile => 'Prześlij plik';
	@override String get enterImageUrl => 'Wprowadź URL obrazu';
	@override String get imageUrl => 'URL obrazu';
	@override String get metadataUpdated => 'Metadane zaktualizowane';
	@override String get metadataUpdateFailed => 'Nie udało się zaktualizować metadanych';
	@override String get artworkUpdated => 'Grafika zaktualizowana';
	@override String get artworkUpdateFailed => 'Nie udało się zaktualizować grafiki';
	@override String get noArtworkAvailable => 'Brak dostępnej grafiki';
	@override String get notSet => 'Nie ustawiono';
	@override String get libraryDefault => 'Domyślne biblioteki';
	@override String get accountDefault => 'Domyślne konta';
	@override String get seriesDefault => 'Domyślne serialu';
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
	@override String get tmdbAiring => 'The Movie Database (Emisja)';
	@override String get tvdbAiring => 'TheTVDB (Emisja)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolutna)';
	@override String get metadataLanguage => 'Język metadanych';
	@override String get useOriginalTitle => 'Użyj oryginalnego tytułu';
	@override String get preferredAudioLanguage => 'Preferowany język audio';
	@override String get preferredSubtitleLanguage => 'Preferowany język napisów';
	@override String get subtitleMode => 'Tryb automatycznego wyboru napisów';
	@override String get manuallySelected => 'Wybrany ręcznie';
	@override String get shownWithForeignAudio => 'Wyświetlane przy obcojęzycznym audio';
	@override String get alwaysEnabled => 'Zawsze włączone';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsPl implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsPl._(this._root);

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
	@override String get speedIncrease => 'Zwiększ prędkość';
	@override String get speedDecrease => 'Zmniejsz prędkość';
	@override String get speedReset => 'Zresetuj prędkość';
	@override String get subSeekNext => 'Przewiń do następnego napisu';
	@override String get subSeekPrev => 'Przewiń do poprzedniego napisu';
	@override String get shaderToggle => 'Przełącz shadery';
	@override String get skipMarker => 'Pomiń intro/napisy końcowe';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsPl implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Wymaga Androida 8.0 lub nowszego';
	@override String get iosVersion => 'Wymaga iOS 15.0 lub nowszego';
	@override String get permissionDisabled => 'Uprawnienie obraz w obrazie jest wyłączone. Włącz w Ustawienia > Aplikacje > Plezy > Obraz w obrazie';
	@override String get notSupported => 'Urządzenie nie obsługuje trybu obraz w obrazie';
	@override String get voSwitchFailed => 'Nie udało się przełączyć wyjścia wideo dla trybu obraz w obrazie';
	@override String get failed => 'Nie udało się uruchomić trybu obraz w obrazie';
	@override String unknown({required Object error}) => 'Wystąpił błąd: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsPl implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Rekomendowane';
	@override String get browse => 'Przeglądaj';
	@override String get collections => 'Kolekcje';
	@override String get playlists => 'Playlisty';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsPl implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get all => 'Wszystkie';
	@override String get movies => 'Filmy';
	@override String get shows => 'Seriale TV';
	@override String get seasons => 'Sezony';
	@override String get episodes => 'Odcinki';
	@override String get folders => 'Foldery';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionPl implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => 'Tworzenie sesji zdalnej...';
	@override String get failedToCreate => 'Nie udało się utworzyć sesji zdalnej:';
	@override String get noSession => 'Brak dostępnej sesji';
	@override String get scanQrCode => 'Zeskanuj kod QR';
	@override String get orEnterManually => 'Lub wprowadź ręcznie';
	@override String get hostAddress => 'Adres hosta';
	@override String get sessionId => 'ID sesji';
	@override String get pin => 'PIN';
	@override String get connected => 'Połączono';
	@override String get waitingForConnection => 'Oczekiwanie na połączenie...';
	@override String get usePhoneToControl => 'Użyj urządzenia mobilnego do sterowania tą aplikacją';
	@override String copiedToClipboard({required Object label}) => '${label} skopiowane do schowka';
	@override String get copyToClipboard => 'Kopiuj do schowka';
	@override String get newSession => 'Nowa sesja';
	@override String get minimize => 'Minimalizuj';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingPl implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingPl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get scan => 'Skanuj';
	@override String get manual => 'Ręcznie';
	@override String get pairWithDesktop => 'Sparuj z komputerem';
	@override String get enterSessionDetails => 'Wprowadź dane sesji wyświetlone na urządzeniu desktop';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => 'Wprowadź 8-znakowe ID sesji';
	@override String get pinHint => 'Wprowadź 6-cyfrowy PIN';
	@override String get connecting => 'Łączenie...';
	@override String get tips => 'Wskazówki';
	@override String get tipDesktop => 'Otwórz Plezy na komputerze i włącz Pilota zdalnego w ustawieniach lub menu';
	@override String get tipScan => 'Użyj zakładki Skanuj, aby szybko sparować skanując kod QR na komputerze';
	@override String get tipWifi => 'Upewnij się, że oba urządzenia są w tej samej sieci WiFi';
	@override String get cameraPermissionRequired => 'Uprawnienie do kamery jest wymagane do skanowania kodów QR.\nPrzyznaj dostęp do kamery w ustawieniach urządzenia.';
	@override String cameraError({required Object error}) => 'Nie udało się uruchomić kamery: ${error}';
	@override String get scanInstruction => 'Skieruj kamerę na kod QR wyświetlony na komputerze';
	@override String get invalidQrCode => 'Nieprawidłowy format kodu QR';
	@override String get validationHostRequired => 'Wprowadź adres hosta';
	@override String get validationHostFormat => 'Format musi być IP:port (np. 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => 'Wprowadź ID sesji';
	@override String get validationSessionIdLength => 'ID sesji musi mieć 8 znaków';
	@override String get validationPinRequired => 'Wprowadź PIN';
	@override String get validationPinLength => 'PIN musi mieć 6 cyfr';
	@override String get connectionTimedOut => 'Upłynął czas połączenia. Sprawdź ID sesji i PIN.';
	@override String get sessionNotFound => 'Nie znaleziono sesji. Sprawdź swoje dane.';
	@override String failedToConnect({required Object error}) => 'Nie udało się połączyć: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemotePl implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemotePl._(this._root);

	final TranslationsPl _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Czy chcesz się rozłączyć od sesji zdalnej?';
	@override String get reconnecting => 'Ponowne łączenie...';
	@override String attemptOf({required Object current}) => 'Próba ${current} z 5';
	@override String get retryNow => 'Ponów teraz';
	@override String get connectionError => 'Błąd połączenia';
	@override String get notConnected => 'Niepołączono';
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
	@override String get playPause => 'Odtwórz/Pauza';
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
			'auth.authenticate' => 'Uwierzytelnienie',
			'auth.authenticationTimeout' => 'Upłynął czas uwierzytelniania. Spróbuj ponownie.',
			'auth.scanQRToSignIn' => 'Zeskanuj ten kod QR, aby się zalogować',
			'auth.waitingForAuth' => 'Oczekiwanie na uwierzytelnienie...\nDokończ logowanie w przeglądarce.',
			'auth.useBrowser' => 'Użyj przeglądarki',
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
			'common.shuffle' => 'Losowo',
			'common.addTo' => 'Dodaj do...',
			'common.createNew' => 'Utwórz nowy',
			'common.remove' => 'Usuń',
			'common.paste' => 'Wklej',
			'common.connect' => 'Połącz',
			'common.disconnect' => 'Rozłącz',
			'common.play' => 'Odtwórz',
			'common.pause' => 'Pauza',
			'common.resume' => 'Wznów',
			'common.error' => 'Błąd',
			'common.search' => 'Szukaj',
			'common.home' => 'Strona główna',
			'common.back' => 'Wstecz',
			'common.settings' => 'Ustawienia',
			'common.mute' => 'Wycisz',
			'common.ok' => 'OK',
			'common.loading' => 'Ładowanie...',
			'common.reconnect' => 'Połącz ponownie',
			'common.exitConfirmTitle' => 'Zamknąć aplikację?',
			'common.exitConfirmMessage' => 'Czy na pewno chcesz wyjść?',
			'common.dontAskAgain' => 'Nie pytaj ponownie',
			'common.exit' => 'Wyjdź',
			'common.viewAll' => 'Pokaż wszystko',
			'common.checkingNetwork' => 'Sprawdzanie sieci...',
			'common.refreshingServers' => 'Odświeżanie serwerów...',
			'common.loadingServers' => 'Ładowanie serwerów...',
			'common.connectingToServers' => 'Łączenie z serwerami...',
			'common.startingOfflineMode' => 'Uruchamianie trybu offline...',
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
			'settings.language' => 'Język',
			'settings.theme' => 'Motyw',
			'settings.appearance' => 'Wygląd',
			'settings.videoPlayback' => 'Odtwarzanie wideo',
			'settings.advanced' => 'Zaawansowane',
			'settings.episodePosterMode' => 'Styl plakatu odcinka',
			'settings.seriesPoster' => 'Plakat serialu',
			'settings.seriesPosterDescription' => 'Pokaż plakat serialu dla wszystkich odcinków',
			'settings.seasonPoster' => 'Plakat sezonu',
			'settings.seasonPosterDescription' => 'Pokaż plakat odpowiedniego sezonu dla odcinków',
			'settings.episodeThumbnail' => 'Miniatura odcinka',
			'settings.episodeThumbnailDescription' => 'Pokaż miniatury zrzutów ekranu odcinków w formacie 16:9',
			'settings.showHeroSectionDescription' => 'Wyświetl karuzelę wyróżnionych treści na ekranie głównym',
			'settings.secondsLabel' => 'Sekundy',
			'settings.minutesLabel' => 'Minuty',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Wprowadź czas (${min}-${max})',
			'settings.systemTheme' => 'Systemowy',
			'settings.systemThemeDescription' => 'Podążaj za ustawieniami systemu',
			'settings.lightTheme' => 'Jasny',
			'settings.darkTheme' => 'Ciemny',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Czysta czerń dla ekranów OLED',
			'settings.libraryDensity' => 'Gęstość biblioteki',
			'settings.compact' => 'Kompaktowy',
			'settings.compactDescription' => 'Mniejsze karty, więcej widocznych elementów',
			'settings.normal' => 'Normalny',
			'settings.normalDescription' => 'Domyślny rozmiar',
			'settings.comfortable' => 'Wygodny',
			'settings.comfortableDescription' => 'Większe karty, mniej widocznych elementów',
			'settings.viewMode' => 'Tryb widoku',
			'settings.gridView' => 'Siatka',
			'settings.gridViewDescription' => 'Wyświetl elementy w układzie siatki',
			'settings.listView' => 'Lista',
			'settings.listViewDescription' => 'Wyświetl elementy w układzie listy',
			'settings.showHeroSection' => 'Pokaż sekcję wyróżnioną',
			'settings.useGlobalHubs' => 'Użyj układu Plex Home',
			'settings.useGlobalHubsDescription' => 'Pokaż huby strony głównej jak w oficjalnym kliencie Plex. Gdy wyłączone, pokazuje rekomendacje per biblioteka.',
			'settings.showServerNameOnHubs' => 'Pokaż nazwę serwera w hubach',
			'settings.showServerNameOnHubsDescription' => 'Zawsze wyświetlaj nazwę serwera w tytułach hubów. Gdy wyłączone, pokazuje tylko dla zduplikowanych nazw.',
			'settings.alwaysKeepSidebarOpen' => 'Zawsze utrzymuj panel boczny otwarty',
			'settings.alwaysKeepSidebarOpenDescription' => 'Panel boczny jest rozwinięty, a obszar treści dostosowuje się',
			'settings.showUnwatchedCount' => 'Pokaż liczbę nieobejrzanych',
			'settings.showUnwatchedCountDescription' => 'Wyświetl liczbę nieobejrzanych odcinków w serialach i sezonach',
			'settings.hideSpoilers' => 'Ukryj spoilery nieobejrzanych odcinków',
			'settings.hideSpoilersDescription' => 'Rozmyj miniatury i ukryj opisy odcinków, których jeszcze nie obejrzałeś',
			'settings.playerBackend' => 'Backend odtwarzacza',
			'settings.exoPlayer' => 'ExoPlayer (Zalecany)',
			'settings.exoPlayerDescription' => 'Natywny odtwarzacz Android z lepszą obsługą sprzętową',
			'settings.mpv' => 'mpv',
			'settings.mpvDescription' => 'Zaawansowany odtwarzacz z większą liczbą funkcji i obsługą napisów ASS',
			'settings.hardwareDecoding' => 'Dekodowanie sprzętowe',
			'settings.hardwareDecodingDescription' => 'Użyj akceleracji sprzętowej, gdy dostępna',
			'settings.bufferSize' => 'Rozmiar bufora',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Automatyczny (Zalecany)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Twoje urządzenie ma ${heap}MB pamięci. Bufor ${size}MB może powodować problemy z odtwarzaniem.',
			'settings.subtitleStyling' => 'Styl napisów',
			'settings.subtitleStylingDescription' => 'Dostosuj wygląd napisów',
			'settings.smallSkipDuration' => 'Krótki skok',
			'settings.largeSkipDuration' => 'Długi skok',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekund',
			'settings.defaultSleepTimer' => 'Domyślny wyłącznik czasowy',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minut',
			'settings.rememberTrackSelections' => 'Zapamiętaj wybór ścieżek per serial/film',
			'settings.rememberTrackSelectionsDescription' => 'Automatycznie zapisuj preferencje języka audio i napisów przy zmianie ścieżek podczas odtwarzania',
			'settings.clickVideoTogglesPlayback' => 'Kliknięcie wideo przełącza odtwarzanie/pauzę',
			'settings.clickVideoTogglesPlaybackDescription' => 'Gdy włączone, kliknięcie na odtwarzacz wideo odtwarza/wstrzymuje. W przeciwnym razie pokazuje/ukrywa kontrolki.',
			'settings.videoPlayerControls' => 'Kontrolki odtwarzacza wideo',
			'settings.keyboardShortcuts' => 'Skróty klawiszowe',
			'settings.keyboardShortcutsDescription' => 'Dostosuj skróty klawiszowe',
			'settings.videoPlayerNavigation' => 'Nawigacja odtwarzacza wideo',
			'settings.videoPlayerNavigationDescription' => 'Użyj klawiszy strzałek do nawigacji kontrolkami odtwarzacza',
			'settings.crashReporting' => 'Raportowanie błędów',
			'settings.crashReportingDescription' => 'Wysyłaj raporty o błędach, aby pomóc ulepszyć aplikację',
			'settings.debugLogging' => 'Logowanie debugowania',
			'settings.debugLoggingDescription' => 'Włącz szczegółowe logowanie do rozwiązywania problemów',
			'settings.viewLogs' => 'Pokaż logi',
			'settings.viewLogsDescription' => 'Pokaż logi aplikacji',
			'settings.clearCache' => 'Wyczyść pamięć podręczną',
			'settings.clearCacheDescription' => 'Spowoduje to wyczyszczenie wszystkich zapisanych obrazów i danych. Po wyczyszczeniu aplikacja może ładować treści wolniej.',
			'settings.clearCacheSuccess' => 'Pamięć podręczna wyczyszczona',
			'settings.resetSettings' => 'Zresetuj ustawienia',
			'settings.resetSettingsDescription' => 'Wszystkie ustawienia zostaną przywrócone do wartości domyślnych. Tej operacji nie można cofnąć.',
			'settings.resetSettingsSuccess' => 'Ustawienia zresetowane pomyślnie',
			'settings.shortcutsReset' => 'Skróty przywrócone do domyślnych',
			'settings.about' => 'O aplikacji',
			'settings.aboutDescription' => 'Informacje o aplikacji i licencje',
			'settings.updates' => 'Aktualizacje',
			'settings.updateAvailable' => 'Dostępna aktualizacja',
			'settings.checkForUpdates' => 'Sprawdź aktualizacje',
			'settings.validationErrorEnterNumber' => 'Wprowadź prawidłową liczbę',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Czas musi być między ${min} a ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Skrót jest już przypisany do ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Skrót zaktualizowany dla ${action}',
			'settings.autoSkip' => 'Automatyczne pomijanie',
			'settings.autoSkipIntro' => 'Automatyczne pomijanie intro',
			'settings.autoSkipIntroDescription' => 'Automatycznie pomijaj znaczniki intro po kilku sekundach',
			'settings.autoSkipCredits' => 'Automatyczne pomijanie napisów końcowych',
			'settings.autoSkipCreditsDescription' => 'Automatycznie pomijaj napisy końcowe i odtwórz następny odcinek',
			'settings.autoSkipDelay' => 'Opóźnienie automatycznego pomijania',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Czekaj ${seconds} sekund przed automatycznym pominięciem',
			'settings.introPattern' => 'Wzorzec znacznika intro',
			'settings.introPatternDescription' => 'Wyrażenie regularne do rozpoznawania znaczników intro w tytułach rozdziałów',
			'settings.creditsPattern' => 'Wzorzec znacznika napisów końcowych',
			'settings.creditsPatternDescription' => 'Wyrażenie regularne do rozpoznawania znaczników napisów końcowych w tytułach rozdziałów',
			'settings.invalidRegex' => 'Nieprawidłowe wyrażenie regularne',
			'settings.downloads' => 'Pobrania',
			'settings.downloadLocationDescription' => 'Wybierz miejsce przechowywania pobranych treści',
			'settings.downloadLocationDefault' => 'Domyślne (Pamięć aplikacji)',
			'settings.downloadLocationCustom' => 'Niestandardowa lokalizacja',
			'settings.selectFolder' => 'Wybierz folder',
			'settings.resetToDefault' => 'Przywróć domyślne',
			'settings.currentPath' => ({required Object path}) => 'Bieżąca: ${path}',
			'settings.downloadLocationChanged' => 'Lokalizacja pobierania zmieniona',
			'settings.downloadLocationReset' => 'Lokalizacja pobierania przywrócona do domyślnej',
			'settings.downloadLocationInvalid' => 'Wybrany folder nie jest zapisywalny',
			'settings.downloadLocationSelectError' => 'Nie udało się wybrać folderu',
			'settings.downloadOnWifiOnly' => 'Pobieraj tylko przez WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Blokuj pobieranie na danych komórkowych',
			'settings.cellularDownloadBlocked' => 'Pobieranie na danych komórkowych jest wyłączone. Połącz się z WiFi lub zmień ustawienie.',
			'settings.maxVolume' => 'Maksymalna głośność',
			'settings.maxVolumeDescription' => 'Pozwól na wzmocnienie głośności powyżej 100% dla cichych multimediów',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Pokaż, co oglądasz na Discordzie',
			'settings.autoPip' => 'Automatyczny obraz w obrazie',
			'settings.autoPipDescription' => 'Automatycznie przejdź do trybu obraz w obrazie przy wyjściu z aplikacji podczas odtwarzania',
			'settings.matchContentFrameRate' => 'Dopasuj częstotliwość klatek do treści',
			'settings.matchContentFrameRateDescription' => 'Dostosuj częstotliwość odświeżania ekranu do treści wideo, zmniejszając drgania i oszczędzając baterię',
			'settings.tunneledPlayback' => 'Tunelowane odtwarzanie',
			'settings.tunneledPlaybackDescription' => 'Użyj sprzętowo przyspieszonego tunelowania wideo. Wyłącz, jeśli widzisz czarny ekran z dźwiękiem przy treściach HDR',
			'settings.requireProfileSelectionOnOpen' => 'Pytaj o profil przy otwarciu aplikacji',
			'settings.requireProfileSelectionOnOpenDescription' => 'Pokaż wybór profilu za każdym razem, gdy aplikacja jest otwierana',
			'settings.confirmExitOnBack' => 'Potwierdź przed wyjściem',
			'settings.confirmExitOnBackDescription' => 'Pokaż dialog potwierdzenia przy naciśnięciu wstecz, aby wyjść z aplikacji',
			'settings.showNavBarLabels' => 'Pokaż etykiety paska nawigacji',
			'settings.showNavBarLabelsDescription' => 'Wyświetl tekstowe etykiety pod ikonami paska nawigacji',
			'search.hint' => 'Szukaj filmów, seriali, muzyki...',
			'search.tryDifferentTerm' => 'Spróbuj innego wyszukiwania',
			'search.searchYourMedia' => 'Przeszukaj swoje media',
			'search.enterTitleActorOrKeyword' => 'Wprowadź tytuł, aktora lub słowo kluczowe',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Ustaw skrót dla ${actionName}',
			'hotkeys.clearShortcut' => 'Wyczyść skrót',
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
			'hotkeys.actions.speedIncrease' => 'Zwiększ prędkość',
			'hotkeys.actions.speedDecrease' => 'Zmniejsz prędkość',
			'hotkeys.actions.speedReset' => 'Zresetuj prędkość',
			'hotkeys.actions.subSeekNext' => 'Przewiń do następnego napisu',
			'hotkeys.actions.subSeekPrev' => 'Przewiń do poprzedniego napisu',
			'hotkeys.actions.shaderToggle' => 'Przełącz shadery',
			'hotkeys.actions.skipMarker' => 'Pomiń intro/napisy końcowe',
			'pinEntry.enterPin' => 'Wprowadź PIN',
			'pinEntry.showPin' => 'Pokaż PIN',
			'pinEntry.hidePin' => 'Ukryj PIN',
			'fileInfo.title' => 'Informacje o pliku',
			'fileInfo.video' => 'Wideo',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'Plik',
			'fileInfo.advanced' => 'Zaawansowane',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.resolution' => 'Rozdzielczość',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Klatki na sekundę',
			'fileInfo.aspectRatio' => 'Proporcje',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Głębia bitowa',
			'fileInfo.colorSpace' => 'Przestrzeń kolorów',
			'fileInfo.colorRange' => 'Zakres kolorów',
			'fileInfo.colorPrimaries' => 'Kolory podstawowe',
			'fileInfo.chromaSubsampling' => 'Subsampling chrominancji',
			'fileInfo.channels' => 'Kanały',
			'fileInfo.path' => 'Ścieżka',
			'fileInfo.size' => 'Rozmiar',
			'fileInfo.container' => 'Kontener',
			'fileInfo.duration' => 'Czas trwania',
			'fileInfo.optimizedForStreaming' => 'Zoptymalizowane do strumieniowania',
			'fileInfo.has64bitOffsets' => '64-bitowe offsety',
			'mediaMenu.markAsWatched' => 'Oznacz jako obejrzane',
			'mediaMenu.markAsUnwatched' => 'Oznacz jako nieobejrzane',
			'mediaMenu.removeFromContinueWatching' => 'Usuń z kontynuowania oglądania',
			'mediaMenu.goToSeries' => 'Przejdź do serialu',
			'mediaMenu.goToSeason' => 'Przejdź do sezonu',
			'mediaMenu.shufflePlay' => 'Odtwarzanie losowe',
			'mediaMenu.fileInfo' => 'Informacje o pliku',
			'mediaMenu.deleteFromServer' => 'Usuń z serwera',
			'mediaMenu.confirmDelete' => 'To trwale usunie te multimedia i ich pliki z twojego serwera. Tej operacji nie można cofnąć.',
			'mediaMenu.deleteMultipleWarning' => 'Obejmuje to wszystkie odcinki i ich pliki.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Element multimedialny usunięty pomyślnie',
			'mediaMenu.mediaFailedToDelete' => 'Nie udało się usunąć elementu multimedialnego',
			'mediaMenu.rate' => 'Oceń',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serial TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'obejrzane',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} procent obejrzane',
			'accessibility.mediaCardUnwatched' => 'nieobejrzane',
			'accessibility.tapToPlay' => 'Dotknij, aby odtworzyć',
			'tooltips.shufflePlay' => 'Odtwarzanie losowe',
			'tooltips.playTrailer' => 'Odtwórz zwiastun',
			'tooltips.markAsWatched' => 'Oznacz jako obejrzane',
			'tooltips.markAsUnwatched' => 'Oznacz jako nieobejrzane',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Napisy',
			'videoControls.resetToZero' => 'Zresetuj do 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} odtwarza później',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} odtwarza wcześniej',
			'videoControls.noOffset' => 'Bez przesunięcia',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Wypełnij ekran',
			'videoControls.stretch' => 'Rozciągnij',
			'videoControls.lockRotation' => 'Zablokuj obrót',
			'videoControls.unlockRotation' => 'Odblokuj obrót',
			'videoControls.timerActive' => 'Wyłącznik aktywny',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Odtwarzanie zatrzyma się za ${duration}',
			'videoControls.sleepTimerCompleted' => 'Wyłącznik czasowy zakończony — odtwarzanie wstrzymane',
			'videoControls.stillWatching' => 'Nadal oglądasz?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pauza za ${seconds}s',
			'videoControls.continueWatching' => 'Kontynuuj',
			'videoControls.autoPlayNext' => 'Automatycznie odtwórz następny',
			'videoControls.playNext' => 'Odtwórz następny',
			'videoControls.playButton' => 'Odtwórz',
			'videoControls.pauseButton' => 'Pauza',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Przewiń do tyłu o ${seconds} sekund',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Przewiń do przodu o ${seconds} sekund',
			'videoControls.previousButton' => 'Poprzedni odcinek',
			'videoControls.nextButton' => 'Następny odcinek',
			'videoControls.previousChapterButton' => 'Poprzedni rozdział',
			'videoControls.nextChapterButton' => 'Następny rozdział',
			'videoControls.muteButton' => 'Wycisz',
			'videoControls.unmuteButton' => 'Wyłącz wyciszenie',
			'videoControls.settingsButton' => 'Ustawienia wideo',
			'videoControls.audioTrackButton' => 'Ścieżki audio',
			'videoControls.subtitlesButton' => 'Napisy',
			'videoControls.tracksButton' => 'Audio i napisy',
			'videoControls.chaptersButton' => 'Rozdziały',
			'videoControls.versionsButton' => 'Wersje wideo',
			'videoControls.pipButton' => 'Tryb obraz w obrazie',
			'videoControls.aspectRatioButton' => 'Proporcje',
			'videoControls.ambientLighting' => 'Oświetlenie otoczenia',
			'videoControls.ambientLightingOn' => 'Włącz oświetlenie otoczenia',
			'videoControls.ambientLightingOff' => 'Wyłącz oświetlenie otoczenia',
			'videoControls.fullscreenButton' => 'Wejdź w pełny ekran',
			'videoControls.exitFullscreenButton' => 'Wyjdź z pełnego ekranu',
			'videoControls.alwaysOnTopButton' => 'Zawsze na wierzchu',
			'videoControls.rotationLockButton' => 'Blokada obrotu',
			'videoControls.timelineSlider' => 'Oś czasu wideo',
			'videoControls.volumeSlider' => 'Poziom głośności',
			'videoControls.endsAt' => ({required Object time}) => 'Kończy się o ${time}',
			'videoControls.pipActive' => 'Odtwarzanie w trybie obraz w obrazie',
			'videoControls.pipFailed' => 'Nie udało się uruchomić trybu obraz w obrazie',
			'videoControls.pipErrors.androidVersion' => 'Wymaga Androida 8.0 lub nowszego',
			'videoControls.pipErrors.iosVersion' => 'Wymaga iOS 15.0 lub nowszego',
			'videoControls.pipErrors.permissionDisabled' => 'Uprawnienie obraz w obrazie jest wyłączone. Włącz w Ustawienia > Aplikacje > Plezy > Obraz w obrazie',
			'videoControls.pipErrors.notSupported' => 'Urządzenie nie obsługuje trybu obraz w obrazie',
			'videoControls.pipErrors.voSwitchFailed' => 'Nie udało się przełączyć wyjścia wideo dla trybu obraz w obrazie',
			'videoControls.pipErrors.failed' => 'Nie udało się uruchomić trybu obraz w obrazie',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Wystąpił błąd: ${error}',
			'videoControls.chapters' => 'Rozdziały',
			'videoControls.noChaptersAvailable' => 'Brak dostępnych rozdziałów',
			'videoControls.queue' => 'Kolejka',
			'videoControls.noQueueItems' => 'Brak elementów w kolejce',
			'userStatus.admin' => 'Administrator',
			'userStatus.restricted' => 'Ograniczony',
			'userStatus.protected' => 'Chroniony',
			'userStatus.current' => 'BIEŻĄCY',
			'messages.markedAsWatched' => 'Oznaczono jako obejrzane',
			'messages.markedAsUnwatched' => 'Oznaczono jako nieobejrzane',
			'messages.markedAsWatchedOffline' => 'Oznaczono jako obejrzane (zsynchronizuje się po połączeniu)',
			'messages.markedAsUnwatchedOffline' => 'Oznaczono jako nieobejrzane (zsynchronizuje się po połączeniu)',
			'messages.removedFromContinueWatching' => 'Usunięto z kontynuowania oglądania',
			'messages.errorLoading' => ({required Object error}) => 'Błąd: ${error}',
			'messages.fileInfoNotAvailable' => 'Informacje o pliku niedostępne',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Błąd ładowania informacji o pliku: ${error}',
			'messages.errorLoadingSeries' => 'Błąd ładowania serialu',
			'messages.errorLoadingSeason' => 'Błąd ładowania sezonu',
			'messages.musicNotSupported' => 'Odtwarzanie muzyki nie jest jeszcze obsługiwane',
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
			'messages.noEpisodesFound' => 'Nie znaleziono odcinków w pierwszym sezonie',
			'messages.noEpisodesFoundGeneral' => 'Nie znaleziono odcinków',
			'messages.noResultsFound' => 'Nie znaleziono wyników',
			'messages.sleepTimerSet' => ({required Object label}) => 'Wyłącznik czasowy ustawiony na ${label}',
			'messages.noItemsAvailable' => 'Brak dostępnych elementów',
			'messages.failedToCreatePlayQueueNoItems' => 'Nie udało się utworzyć kolejki odtwarzania — brak elementów',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Nie udało się ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Przełączanie na kompatybilny odtwarzacz...',
			'messages.logsUploaded' => 'Logi przesłane',
			'messages.logsUploadFailed' => 'Nie udało się przesłać logów',
			'messages.logId' => 'ID logu',
			'subtitlingStyling.stylingOptions' => 'Opcje stylu',
			'subtitlingStyling.fontSize' => 'Rozmiar czcionki',
			'subtitlingStyling.textColor' => 'Kolor tekstu',
			'subtitlingStyling.borderSize' => 'Rozmiar obramowania',
			'subtitlingStyling.borderColor' => 'Kolor obramowania',
			'subtitlingStyling.backgroundOpacity' => 'Przezroczystość tła',
			'subtitlingStyling.backgroundColor' => 'Kolor tła',
			'subtitlingStyling.position' => 'Pozycja',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Zaawansowane ustawienia odtwarzacza wideo',
			'mpvConfig.presets' => 'Presety',
			'mpvConfig.noPresets' => 'Brak zapisanych presetów',
			'mpvConfig.saveAsPreset' => 'Zapisz jako preset...',
			'mpvConfig.presetName' => 'Nazwa presetu',
			'mpvConfig.presetNameHint' => 'Wprowadź nazwę dla tego presetu',
			'mpvConfig.loadPreset' => 'Załaduj',
			'mpvConfig.deletePreset' => 'Usuń',
			'mpvConfig.presetSaved' => 'Preset zapisany',
			'mpvConfig.presetLoaded' => 'Preset załadowany',
			'mpvConfig.presetDeleted' => 'Preset usunięty',
			'mpvConfig.confirmDeletePreset' => 'Czy na pewno chcesz usunąć ten preset?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Potwierdź działanie',
			'discover.title' => 'Odkryj',
			'discover.switchProfile' => 'Zmień profil',
			'discover.noContentAvailable' => 'Brak dostępnych treści',
			'discover.addMediaToLibraries' => 'Dodaj multimedia do swoich bibliotek',
			'discover.continueWatching' => 'Kontynuuj oglądanie',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Opis',
			'discover.cast' => 'Obsada',
			'discover.extras' => 'Zwiastuny i dodatki',
			'discover.seasons' => 'Sezony',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Ocena',
			'discover.episodeCount' => ({required Object count}) => '${count} odcinków',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} obejrzanych',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serial TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min pozostało',
			'errors.searchFailed' => ({required Object error}) => 'Wyszukiwanie nie powiodło się: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Limit czasu połączenia przy ładowaniu ${context}',
			'errors.connectionFailed' => 'Nie można połączyć z serwerem Plex',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Nie udało się załadować ${context}: ${error}',
			'errors.noClientAvailable' => 'Brak dostępnego klienta',
			'errors.authenticationFailed' => ({required Object error}) => 'Uwierzytelnienie nie powiodło się: ${error}',
			'errors.couldNotLaunchUrl' => 'Nie można otworzyć URL uwierzytelniania',
			'errors.pleaseEnterToken' => 'Wprowadź token',
			'errors.invalidToken' => 'Nieprawidłowy token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Nie udało się zweryfikować tokena: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Nie udało się przełączyć na ${displayName}',
			'libraries.title' => 'Biblioteki',
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
			'libraries.thisLibraryIsEmpty' => 'Ta biblioteka jest pusta',
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
			'libraries.tabs.recommended' => 'Rekomendowane',
			'libraries.tabs.browse' => 'Przeglądaj',
			'libraries.tabs.collections' => 'Kolekcje',
			'libraries.tabs.playlists' => 'Playlisty',
			'libraries.groupings.all' => 'Wszystkie',
			'libraries.groupings.movies' => 'Filmy',
			'libraries.groupings.shows' => 'Seriale TV',
			'libraries.groupings.seasons' => 'Sezony',
			'libraries.groupings.episodes' => 'Odcinki',
			'libraries.groupings.folders' => 'Foldery',
			'about.title' => 'O aplikacji',
			'about.openSourceLicenses' => 'Licencje open source',
			'about.versionLabel' => ({required Object version}) => 'Wersja ${version}',
			'about.appDescription' => 'Piękny klient Plex na Flutter',
			'about.viewLicensesDescription' => 'Zobacz licencje bibliotek zewnętrznych',
			'serverSelection.allServerConnectionsFailed' => 'Nie udało się połączyć z żadnym serwerem. Sprawdź sieć i spróbuj ponownie.',
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
			'logs.error' => 'Błąd:',
			'logs.stackTrace' => 'Ślad stosu:',
			'licenses.relatedPackages' => 'Powiązane pakiety',
			'licenses.license' => 'Licencja',
			'licenses.licenseNumber' => ({required Object number}) => 'Licencja ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licencji',
			'navigation.libraries' => 'Biblioteki',
			'navigation.downloads' => 'Pobrania',
			'navigation.liveTv' => 'TV na żywo',
			'liveTv.title' => 'TV na żywo',
			'liveTv.channels' => 'Kanały',
			'liveTv.guide' => 'Przewodnik',
			'liveTv.noChannels' => 'Brak dostępnych kanałów',
			'liveTv.noDvr' => 'Brak skonfigurowanego DVR na żadnym serwerze',
			'liveTv.tuneFailed' => 'Nie udało się dostroić kanału',
			'liveTv.loading' => 'Ładowanie kanałów...',
			'liveTv.nowPlaying' => 'Teraz odtwarzane',
			'liveTv.noPrograms' => 'Brak danych o programach',
			'liveTv.channelNumber' => ({required Object number}) => 'Kn. ${number}',
			'liveTv.live' => 'NA ŻYWO',
			_ => null,
		} ?? switch (path) {
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'NOWE',
			'liveTv.reloadGuide' => 'Odśwież przewodnik',
			'liveTv.allChannels' => 'Wszystkie kanały',
			'liveTv.now' => 'Teraz',
			'liveTv.today' => 'Dzisiaj',
			'liveTv.midnight' => 'Północ',
			'liveTv.overnight' => 'Nocą',
			'liveTv.morning' => 'Rano',
			'liveTv.daytime' => 'W ciągu dnia',
			'liveTv.evening' => 'Wieczorem',
			'liveTv.lateNight' => 'Późna noc',
			'liveTv.whatsOn' => 'Co leci',
			'liveTv.watchChannel' => 'Oglądaj kanał',
			'collections.title' => 'Kolekcje',
			'collections.collection' => 'Kolekcja',
			'collections.empty' => 'Kolekcja jest pusta',
			'collections.unknownLibrarySection' => 'Nie można usunąć: Nieznana sekcja biblioteki',
			'collections.deleteCollection' => 'Usuń kolekcję',
			'collections.deleteConfirm' => ({required Object title}) => 'Czy na pewno chcesz usunąć "${title}"? Tej operacji nie można cofnąć.',
			'collections.deleted' => 'Kolekcja usunięta',
			'collections.deleteFailed' => 'Nie udało się usunąć kolekcji',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Nie udało się usunąć kolekcji: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Nie udało się załadować elementów kolekcji: ${error}',
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
			'playlists.errorCreating' => 'Nie udało się utworzyć playlisty',
			'playlists.errorDeleting' => 'Nie udało się usunąć playlisty',
			'playlists.errorLoading' => 'Nie udało się załadować playlist',
			'playlists.errorAdding' => 'Nie udało się dodać do playlisty',
			'playlists.errorReordering' => 'Nie udało się zmienić kolejności elementu playlisty',
			'playlists.errorRemoving' => 'Nie udało się usunąć z playlisty',
			'watchTogether.title' => 'Oglądaj razem',
			'watchTogether.description' => 'Oglądaj treści zsynchronizowane z przyjaciółmi i rodziną',
			'watchTogether.createSession' => 'Utwórz sesję',
			'watchTogether.creating' => 'Tworzenie...',
			'watchTogether.joinSession' => 'Dołącz do sesji',
			'watchTogether.joining' => 'Dołączanie...',
			'watchTogether.controlMode' => 'Tryb kontroli',
			'watchTogether.controlModeQuestion' => 'Kto może kontrolować odtwarzanie?',
			'watchTogether.hostOnly' => 'Tylko host',
			'watchTogether.anyone' => 'Każdy',
			'watchTogether.hostingSession' => 'Hostowanie sesji',
			'watchTogether.inSession' => 'W sesji',
			'watchTogether.sessionCode' => 'Kod sesji',
			'watchTogether.hostControlsPlayback' => 'Host kontroluje odtwarzanie',
			'watchTogether.anyoneCanControl' => 'Każdy może kontrolować odtwarzanie',
			'watchTogether.hostControls' => 'Kontrola hosta',
			'watchTogether.anyoneControls' => 'Kontrola każdego',
			'watchTogether.participants' => 'Uczestnicy',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Jesteś hostem',
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
			'watchTogether.enterCodeHint' => 'Wprowadź 8-znakowy kod',
			'watchTogether.pasteFromClipboard' => 'Wklej ze schowka',
			'watchTogether.pleaseEnterCode' => 'Wprowadź kod sesji',
			'watchTogether.codeMustBe8Chars' => 'Kod sesji musi mieć 8 znaków',
			'watchTogether.joinInstructions' => 'Wprowadź kod sesji udostępniony przez hosta, aby dołączyć do sesji oglądania.',
			'watchTogether.failedToCreate' => 'Nie udało się utworzyć sesji',
			'watchTogether.failedToJoin' => 'Nie udało się dołączyć do sesji',
			'watchTogether.sessionCodeCopied' => 'Kod sesji skopiowany do schowka',
			'watchTogether.relayUnreachable' => 'Serwer przekaźnika jest nieosiągalny. Może to być spowodowane blokadą przez twojego dostawcę internetu. Możesz spróbować, ale Oglądaj razem może nie działać.',
			'watchTogether.reconnectingToHost' => 'Ponowne łączenie z hostem...',
			'watchTogether.currentPlayback' => 'Bieżące odtwarzanie',
			'watchTogether.joinCurrentPlayback' => 'Dołącz do bieżącego odtwarzania',
			'watchTogether.joinCurrentPlaybackDescription' => 'Wróć do tego, co host aktualnie ogląda',
			'watchTogether.failedToOpenCurrentPlayback' => 'Nie udało się otworzyć bieżącego odtwarzania',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} dołączył',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} opuścił',
			'downloads.title' => 'Pobrania',
			'downloads.manage' => 'Zarządzaj',
			'downloads.tvShows' => 'Seriale TV',
			'downloads.movies' => 'Filmy',
			'downloads.noDownloads' => 'Brak pobrań',
			'downloads.noDownloadsDescription' => 'Pobrane treści pojawią się tutaj do oglądania offline',
			'downloads.downloadNow' => 'Pobierz',
			'downloads.deleteDownload' => 'Usuń pobranie',
			'downloads.retryDownload' => 'Ponów pobieranie',
			'downloads.downloadQueued' => 'Pobranie w kolejce',
			'downloads.episodesQueued' => ({required Object count}) => '${count} odcinków w kolejce pobierania',
			'downloads.downloadDeleted' => 'Pobranie usunięte',
			'downloads.deleteConfirm' => ({required Object title}) => 'Czy na pewno chcesz usunąć "${title}"? Spowoduje to usunięcie pobranego pliku z urządzenia.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Usuwanie ${title}... (${current} z ${total})',
			'downloads.noDownloadsTree' => 'Brak pobrań',
			'downloads.pauseAll' => 'Wstrzymaj wszystko',
			'downloads.resumeAll' => 'Wznów wszystko',
			'downloads.deleteAll' => 'Usuń wszystko',
			'shaders.title' => 'Shadery',
			'shaders.noShaderDescription' => 'Bez ulepszenia wideo',
			'shaders.nvscalerDescription' => 'Skalowanie obrazu NVIDIA dla ostrzejszego wideo',
			'shaders.qualityFast' => 'Szybki',
			'shaders.qualityHQ' => 'Wysoka jakość',
			'shaders.mode' => 'Tryb',
			'shaders.importShader' => 'Importuj shader',
			'shaders.customShaderDescription' => 'Niestandardowy shader GLSL',
			'shaders.shaderImported' => 'Shader zaimportowany',
			'shaders.shaderImportFailed' => 'Nie udało się zaimportować shadera',
			'shaders.deleteShader' => 'Usuń shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Usunąć "${name}"?',
			'companionRemote.title' => 'Pilot zdalny',
			'companionRemote.connectToDevice' => 'Połącz z urządzeniem',
			'companionRemote.hostRemoteSession' => 'Hostuj sesję zdalną',
			'companionRemote.controlThisDevice' => 'Steruj tym urządzeniem ze swojego telefonu',
			'companionRemote.remoteControl' => 'Pilot zdalny',
			'companionRemote.controlDesktop' => 'Steruj urządzeniem desktop',
			'companionRemote.connectedTo' => ({required Object name}) => 'Połączono z ${name}',
			'companionRemote.session.creatingSession' => 'Tworzenie sesji zdalnej...',
			'companionRemote.session.failedToCreate' => 'Nie udało się utworzyć sesji zdalnej:',
			'companionRemote.session.noSession' => 'Brak dostępnej sesji',
			'companionRemote.session.scanQrCode' => 'Zeskanuj kod QR',
			'companionRemote.session.orEnterManually' => 'Lub wprowadź ręcznie',
			'companionRemote.session.hostAddress' => 'Adres hosta',
			'companionRemote.session.sessionId' => 'ID sesji',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Połączono',
			'companionRemote.session.waitingForConnection' => 'Oczekiwanie na połączenie...',
			'companionRemote.session.usePhoneToControl' => 'Użyj urządzenia mobilnego do sterowania tą aplikacją',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} skopiowane do schowka',
			'companionRemote.session.copyToClipboard' => 'Kopiuj do schowka',
			'companionRemote.session.newSession' => 'Nowa sesja',
			'companionRemote.session.minimize' => 'Minimalizuj',
			'companionRemote.pairing.scan' => 'Skanuj',
			'companionRemote.pairing.manual' => 'Ręcznie',
			'companionRemote.pairing.pairWithDesktop' => 'Sparuj z komputerem',
			'companionRemote.pairing.enterSessionDetails' => 'Wprowadź dane sesji wyświetlone na urządzeniu desktop',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Wprowadź 8-znakowe ID sesji',
			'companionRemote.pairing.pinHint' => 'Wprowadź 6-cyfrowy PIN',
			'companionRemote.pairing.connecting' => 'Łączenie...',
			'companionRemote.pairing.tips' => 'Wskazówki',
			'companionRemote.pairing.tipDesktop' => 'Otwórz Plezy na komputerze i włącz Pilota zdalnego w ustawieniach lub menu',
			'companionRemote.pairing.tipScan' => 'Użyj zakładki Skanuj, aby szybko sparować skanując kod QR na komputerze',
			'companionRemote.pairing.tipWifi' => 'Upewnij się, że oba urządzenia są w tej samej sieci WiFi',
			'companionRemote.pairing.cameraPermissionRequired' => 'Uprawnienie do kamery jest wymagane do skanowania kodów QR.\nPrzyznaj dostęp do kamery w ustawieniach urządzenia.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Nie udało się uruchomić kamery: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Skieruj kamerę na kod QR wyświetlony na komputerze',
			'companionRemote.pairing.invalidQrCode' => 'Nieprawidłowy format kodu QR',
			'companionRemote.pairing.validationHostRequired' => 'Wprowadź adres hosta',
			'companionRemote.pairing.validationHostFormat' => 'Format musi być IP:port (np. 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Wprowadź ID sesji',
			'companionRemote.pairing.validationSessionIdLength' => 'ID sesji musi mieć 8 znaków',
			'companionRemote.pairing.validationPinRequired' => 'Wprowadź PIN',
			'companionRemote.pairing.validationPinLength' => 'PIN musi mieć 6 cyfr',
			'companionRemote.pairing.connectionTimedOut' => 'Upłynął czas połączenia. Sprawdź ID sesji i PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Nie znaleziono sesji. Sprawdź swoje dane.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Nie udało się połączyć: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Czy chcesz się rozłączyć od sesji zdalnej?',
			'companionRemote.remote.reconnecting' => 'Ponowne łączenie...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Próba ${current} z 5',
			'companionRemote.remote.retryNow' => 'Ponów teraz',
			'companionRemote.remote.connectionError' => 'Błąd połączenia',
			'companionRemote.remote.notConnected' => 'Niepołączono',
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
			'companionRemote.remote.playPause' => 'Odtwórz/Pauza',
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
			'videoSettings.playbackSettings' => 'Ustawienia odtwarzania',
			'videoSettings.playbackSpeed' => 'Prędkość odtwarzania',
			'videoSettings.sleepTimer' => 'Wyłącznik czasowy',
			'videoSettings.audioSync' => 'Synchronizacja audio',
			'videoSettings.subtitleSync' => 'Synchronizacja napisów',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Wyjście audio',
			'videoSettings.performanceOverlay' => 'Nakładka wydajności',
			'videoSettings.audioPassthrough' => 'Bezpośrednie audio',
			'videoSettings.audioNormalization' => 'Normalizacja audio',
			'externalPlayer.title' => 'Zewnętrzny odtwarzacz',
			'externalPlayer.useExternalPlayer' => 'Użyj zewnętrznego odtwarzacza',
			'externalPlayer.useExternalPlayerDescription' => 'Otwieraj wideo w zewnętrznej aplikacji zamiast wbudowanego odtwarzacza',
			'externalPlayer.selectPlayer' => 'Wybierz odtwarzacz',
			'externalPlayer.systemDefault' => 'Domyślny systemowy',
			'externalPlayer.addCustomPlayer' => 'Dodaj niestandardowy odtwarzacz',
			'externalPlayer.playerName' => 'Nazwa odtwarzacza',
			'externalPlayer.playerCommand' => 'Polecenie',
			'externalPlayer.playerPackage' => 'Nazwa pakietu',
			'externalPlayer.playerUrlScheme' => 'Schemat URL',
			'externalPlayer.customPlayer' => 'Niestandardowy odtwarzacz',
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
			'metadataEdit.tagline' => 'Tagline',
			'metadataEdit.summary' => 'Opis',
			'metadataEdit.poster' => 'Plakat',
			'metadataEdit.background' => 'Tło',
			'metadataEdit.selectPoster' => 'Wybierz plakat',
			'metadataEdit.selectBackground' => 'Wybierz tło',
			'metadataEdit.fromUrl' => 'Z URL',
			'metadataEdit.uploadFile' => 'Prześlij plik',
			'metadataEdit.enterImageUrl' => 'Wprowadź URL obrazu',
			'metadataEdit.imageUrl' => 'URL obrazu',
			'metadataEdit.metadataUpdated' => 'Metadane zaktualizowane',
			'metadataEdit.metadataUpdateFailed' => 'Nie udało się zaktualizować metadanych',
			'metadataEdit.artworkUpdated' => 'Grafika zaktualizowana',
			'metadataEdit.artworkUpdateFailed' => 'Nie udało się zaktualizować grafiki',
			'metadataEdit.noArtworkAvailable' => 'Brak dostępnej grafiki',
			'metadataEdit.notSet' => 'Nie ustawiono',
			'metadataEdit.libraryDefault' => 'Domyślne biblioteki',
			'metadataEdit.accountDefault' => 'Domyślne konta',
			'metadataEdit.seriesDefault' => 'Domyślne serialu',
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
			'metadataEdit.tmdbAiring' => 'The Movie Database (Emisja)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Emisja)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolutna)',
			'metadataEdit.metadataLanguage' => 'Język metadanych',
			'metadataEdit.useOriginalTitle' => 'Użyj oryginalnego tytułu',
			'metadataEdit.preferredAudioLanguage' => 'Preferowany język audio',
			'metadataEdit.preferredSubtitleLanguage' => 'Preferowany język napisów',
			'metadataEdit.subtitleMode' => 'Tryb automatycznego wyboru napisów',
			'metadataEdit.manuallySelected' => 'Wybrany ręcznie',
			'metadataEdit.shownWithForeignAudio' => 'Wyświetlane przy obcojęzycznym audio',
			'metadataEdit.alwaysEnabled' => 'Zawsze włączone',
			_ => null,
		};
	}
}
