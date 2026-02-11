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
class TranslationsIt with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsIt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsIt _root = this; // ignore: unused_field

	@override 
	TranslationsIt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsIt(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppIt app = _TranslationsAppIt._(_root);
	@override late final _TranslationsAuthIt auth = _TranslationsAuthIt._(_root);
	@override late final _TranslationsCommonIt common = _TranslationsCommonIt._(_root);
	@override late final _TranslationsScreensIt screens = _TranslationsScreensIt._(_root);
	@override late final _TranslationsUpdateIt update = _TranslationsUpdateIt._(_root);
	@override late final _TranslationsSettingsIt settings = _TranslationsSettingsIt._(_root);
	@override late final _TranslationsSearchIt search = _TranslationsSearchIt._(_root);
	@override late final _TranslationsHotkeysIt hotkeys = _TranslationsHotkeysIt._(_root);
	@override late final _TranslationsPinEntryIt pinEntry = _TranslationsPinEntryIt._(_root);
	@override late final _TranslationsFileInfoIt fileInfo = _TranslationsFileInfoIt._(_root);
	@override late final _TranslationsMediaMenuIt mediaMenu = _TranslationsMediaMenuIt._(_root);
	@override late final _TranslationsAccessibilityIt accessibility = _TranslationsAccessibilityIt._(_root);
	@override late final _TranslationsTooltipsIt tooltips = _TranslationsTooltipsIt._(_root);
	@override late final _TranslationsVideoControlsIt videoControls = _TranslationsVideoControlsIt._(_root);
	@override late final _TranslationsUserStatusIt userStatus = _TranslationsUserStatusIt._(_root);
	@override late final _TranslationsMessagesIt messages = _TranslationsMessagesIt._(_root);
	@override late final _TranslationsSubtitlingStylingIt subtitlingStyling = _TranslationsSubtitlingStylingIt._(_root);
	@override late final _TranslationsMpvConfigIt mpvConfig = _TranslationsMpvConfigIt._(_root);
	@override late final _TranslationsDialogIt dialog = _TranslationsDialogIt._(_root);
	@override late final _TranslationsDiscoverIt discover = _TranslationsDiscoverIt._(_root);
	@override late final _TranslationsErrorsIt errors = _TranslationsErrorsIt._(_root);
	@override late final _TranslationsLibrariesIt libraries = _TranslationsLibrariesIt._(_root);
	@override late final _TranslationsAboutIt about = _TranslationsAboutIt._(_root);
	@override late final _TranslationsServerSelectionIt serverSelection = _TranslationsServerSelectionIt._(_root);
	@override late final _TranslationsHubDetailIt hubDetail = _TranslationsHubDetailIt._(_root);
	@override late final _TranslationsLogsIt logs = _TranslationsLogsIt._(_root);
	@override late final _TranslationsLicensesIt licenses = _TranslationsLicensesIt._(_root);
	@override late final _TranslationsNavigationIt navigation = _TranslationsNavigationIt._(_root);
	@override late final _TranslationsLiveTvIt liveTv = _TranslationsLiveTvIt._(_root);
	@override late final _TranslationsDownloadsIt downloads = _TranslationsDownloadsIt._(_root);
	@override late final _TranslationsPlaylistsIt playlists = _TranslationsPlaylistsIt._(_root);
	@override late final _TranslationsCollectionsIt collections = _TranslationsCollectionsIt._(_root);
	@override late final _TranslationsWatchTogetherIt watchTogether = _TranslationsWatchTogetherIt._(_root);
	@override late final _TranslationsShadersIt shaders = _TranslationsShadersIt._(_root);
	@override late final _TranslationsCompanionRemoteIt companionRemote = _TranslationsCompanionRemoteIt._(_root);
	@override late final _TranslationsVideoSettingsIt videoSettings = _TranslationsVideoSettingsIt._(_root);
	@override late final _TranslationsExternalPlayerIt externalPlayer = _TranslationsExternalPlayerIt._(_root);
}

// Path: app
class _TranslationsAppIt implements TranslationsAppEn {
	_TranslationsAppIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthIt implements TranslationsAuthEn {
	_TranslationsAuthIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Accedi con Plex';
	@override String get showQRCode => 'Mostra QR Code';
	@override String get authenticate => 'Autenticazione';
	@override String get debugEnterToken => 'Debug: Inserisci Token Plex';
	@override String get plexTokenLabel => 'Token Auth Plex';
	@override String get plexTokenHint => 'Inserisci il tuo token di Plex.tv';
	@override String get authenticationTimeout => 'Autenticazione scaduta. Riprova.';
	@override String get scanQRToSignIn => 'Scansiona il QR code per accedere';
	@override String get waitingForAuth => 'In attesa di autenticazione...\nCompleta l\'accesso dal tuo browser.';
	@override String get useBrowser => 'Usa browser';
}

// Path: common
class _TranslationsCommonIt implements TranslationsCommonEn {
	_TranslationsCommonIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancella';
	@override String get save => 'Salva';
	@override String get close => 'Chiudi';
	@override String get clear => 'Pulisci';
	@override String get reset => 'Ripristina';
	@override String get later => 'Più tardi';
	@override String get submit => 'Invia';
	@override String get confirm => 'Conferma';
	@override String get retry => 'Riprova';
	@override String get logout => 'Disconnetti';
	@override String get unknown => 'Sconosciuto';
	@override String get refresh => 'Aggiorna';
	@override String get yes => 'Sì';
	@override String get no => 'No';
	@override String get delete => 'Elimina';
	@override String get shuffle => 'Casuale';
	@override String get addTo => 'Aggiungi a...';
	@override String get remove => 'Rimuovi';
	@override String get paste => 'Incolla';
	@override String get connect => 'Connetti';
	@override String get disconnect => 'Disconnetti';
	@override String get play => 'Riproduci';
	@override String get pause => 'Pausa';
	@override String get resume => 'Riprendi';
	@override String get error => 'Errore';
	@override String get search => 'Cerca';
	@override String get home => 'Home';
	@override String get back => 'Indietro';
	@override String get settings => 'Impostazioni';
	@override String get mute => 'Muto';
	@override String get ok => 'OK';
	@override String get loading => 'Caricamento...';
}

// Path: screens
class _TranslationsScreensIt implements TranslationsScreensEn {
	_TranslationsScreensIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenze';
	@override String get switchProfile => 'Cambia profilo';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get mpvConfig => 'Configurazione MPV';
	@override String get logs => 'Registro';
}

// Path: update
class _TranslationsUpdateIt implements TranslationsUpdateEn {
	_TranslationsUpdateIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Aggiornamento disponibile';
	@override String versionAvailable({required Object version}) => 'Versione ${version} disponibile';
	@override String currentVersion({required Object version}) => 'Corrente: ${version}';
	@override String get skipVersion => 'Salta questa versione';
	@override String get viewRelease => 'Visualizza dettagli release';
	@override String get latestVersion => 'La versione installata è l\'ultima disponibile';
	@override String get checkFailed => 'Impossibile controllare gli aggiornamenti';
}

// Path: settings
class _TranslationsSettingsIt implements TranslationsSettingsEn {
	_TranslationsSettingsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Impostazioni';
	@override String get language => 'Lingua';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aspetto';
	@override String get videoPlayback => 'Riproduzione video';
	@override String get advanced => 'Avanzate';
	@override String get episodePosterMode => 'Stile poster episodio';
	@override String get seriesPoster => 'Poster della serie';
	@override String get seriesPosterDescription => 'Mostra il poster della serie per tutti gli episodi';
	@override String get seasonPoster => 'Poster della stagione';
	@override String get seasonPosterDescription => 'Mostra il poster specifico della stagione per gli episodi';
	@override String get episodeThumbnail => 'Miniatura episodio';
	@override String get episodeThumbnailDescription => 'Mostra miniature 16:9 degli episodi';
	@override String get showHeroSectionDescription => 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale';
	@override String get secondsLabel => 'Secondi';
	@override String get minutesLabel => 'Minuti';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Inserisci durata (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get systemThemeDescription => 'Segui le impostazioni di sistema';
	@override String get lightTheme => 'Chiaro';
	@override String get darkTheme => 'Scuro';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Nero puro per schermi OLED';
	@override String get libraryDensity => 'Densità libreria';
	@override String get compact => 'Compatta';
	@override String get compactDescription => 'Schede più piccole, più elementi visibili';
	@override String get normal => 'Normale';
	@override String get normalDescription => 'Dimensione predefinita';
	@override String get comfortable => 'Comoda';
	@override String get comfortableDescription => 'Schede più grandi, meno elementi visibili';
	@override String get viewMode => 'Modalità di visualizzazione';
	@override String get gridView => 'Griglia';
	@override String get gridViewDescription => 'Visualizza gli elementi in un layout a griglia';
	@override String get listView => 'Elenco';
	@override String get listViewDescription => 'Visualizza gli elementi in un layout a elenco';
	@override String get showHeroSection => 'Mostra sezione principale';
	@override String get useGlobalHubs => 'Usa layout Home di Plex';
	@override String get useGlobalHubsDescription => 'Mostra gli hub della home page come il client Plex ufficiale. Se disattivato, mostra invece i suggerimenti per libreria.';
	@override String get showServerNameOnHubs => 'Mostra nome server sugli hub';
	@override String get showServerNameOnHubsDescription => 'Mostra sempre il nome del server nei titoli degli hub. Se disattivato, solo per nomi hub duplicati.';
	@override String get alwaysKeepSidebarOpen => 'Mantieni sempre aperta la barra laterale';
	@override String get alwaysKeepSidebarOpenDescription => 'La barra laterale rimane espansa e l\'area del contenuto si adatta';
	@override String get showUnwatchedCount => 'Mostra conteggio non visti';
	@override String get showUnwatchedCountDescription => 'Mostra il numero di episodi non visti per serie e stagioni';
	@override String get playerBackend => 'Motore di riproduzione';
	@override String get exoPlayer => 'ExoPlayer (Consigliato)';
	@override String get exoPlayerDescription => 'Lettore nativo Android con migliore supporto hardware';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => 'Lettore avanzato con più funzionalità e supporto sottotitoli ASS';
	@override String get hardwareDecoding => 'Decodifica Hardware';
	@override String get hardwareDecodingDescription => 'Utilizza l\'accelerazione hardware quando disponibile';
	@override String get bufferSize => 'Dimensione buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get subtitleStylingDescription => 'Personalizza l\'aspetto dei sottotitoli';
	@override String get smallSkipDuration => 'Durata skip breve';
	@override String get largeSkipDuration => 'Durata skip lungo';
	@override String secondsUnit({required Object seconds}) => '${seconds} secondi';
	@override String get defaultSleepTimer => 'Timer spegnimento predefinito';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuti';
	@override String get rememberTrackSelections => 'Ricorda selezioni tracce per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Salva automaticamente le preferenze delle lingue audio e sottotitoli quando cambi tracce durante la riproduzione';
	@override String get clickVideoTogglesPlayback => 'Fai clic sul video per avviare o mettere in pausa la riproduzione.';
	@override String get clickVideoTogglesPlaybackDescription => 'Se questa opzione è abilitata, facendo clic sul lettore video la riproduzione verrà avviata o messa in pausa. In caso contrario, facendo clic verranno mostrati o nascosti i controlli di riproduzione.';
	@override String get videoPlayerControls => 'Controlli del lettore video';
	@override String get keyboardShortcuts => 'Scorciatoie da tastiera';
	@override String get keyboardShortcutsDescription => 'Personalizza le scorciatoie da tastiera';
	@override String get videoPlayerNavigation => 'Navigazione del lettore video';
	@override String get videoPlayerNavigationDescription => 'Usa i tasti freccia per navigare nei controlli del lettore video';
	@override String get debugLogging => 'Log di debug';
	@override String get debugLoggingDescription => 'Abilita il logging dettagliato per la risoluzione dei problemi';
	@override String get viewLogs => 'Visualizza log';
	@override String get viewLogsDescription => 'Visualizza i log dell\'applicazione';
	@override String get clearCache => 'Svuota cache';
	@override String get clearCacheDescription => 'Questa opzione cancellerà tutte le immagini e i dati memorizzati nella cache. Dopo aver cancellato la cache, l\'app potrebbe impiegare più tempo per caricare i contenuti.';
	@override String get clearCacheSuccess => 'Cache cancellata correttamente';
	@override String get resetSettings => 'Ripristina impostazioni';
	@override String get resetSettingsDescription => 'Questa opzione ripristinerà tutte le impostazioni ai valori predefiniti. Non può essere annullata.';
	@override String get resetSettingsSuccess => 'Impostazioni ripristinate correttamente';
	@override String get shortcutsReset => 'Scorciatoie ripristinate alle impostazioni predefinite';
	@override String get about => 'Informazioni';
	@override String get aboutDescription => 'Informazioni sull\'app e le licenze';
	@override String get updates => 'Aggiornamenti';
	@override String get updateAvailable => 'Aggiornamento disponibile';
	@override String get checkForUpdates => 'Controlla aggiornamenti';
	@override String get validationErrorEnterNumber => 'Inserisci un numero valido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'la durata deve essere compresa tra ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Scorciatoia già assegnata a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Scorciatoia aggiornata per ${action}';
	@override String get autoSkip => 'Salto Automatico';
	@override String get autoSkipIntro => 'Salta Intro Automaticamente';
	@override String get autoSkipIntroDescription => 'Salta automaticamente i marcatori dell\'intro dopo alcuni secondi';
	@override String get autoSkipCredits => 'Salta Crediti Automaticamente';
	@override String get autoSkipCreditsDescription => 'Salta automaticamente i crediti e riproduci l\'episodio successivo';
	@override String get autoSkipDelay => 'Ritardo Salto Automatico';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Aspetta ${seconds} secondi prima del salto automatico';
	@override String get downloads => 'Download';
	@override String get downloadLocationDescription => 'Scegli dove salvare i contenuti scaricati';
	@override String get downloadLocationDefault => 'Predefinita (Archiviazione App)';
	@override String get downloadLocationCustom => 'Posizione Personalizzata';
	@override String get selectFolder => 'Seleziona Cartella';
	@override String get resetToDefault => 'Ripristina Predefinita';
	@override String currentPath({required Object path}) => 'Corrente: ${path}';
	@override String get downloadLocationChanged => 'Posizione di download modificata';
	@override String get downloadLocationReset => 'Posizione di download ripristinata a predefinita';
	@override String get downloadLocationInvalid => 'La cartella selezionata non è scrivibile';
	@override String get downloadLocationSelectError => 'Impossibile selezionare la cartella';
	@override String get downloadOnWifiOnly => 'Scarica solo con WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Impedisci i download quando si utilizza la rete dati cellulare';
	@override String get cellularDownloadBlocked => 'I download sono disabilitati sulla rete dati cellulare. Connettiti al WiFi o modifica l\'impostazione.';
	@override String get maxVolume => 'Volume massimo';
	@override String get maxVolumeDescription => 'Consenti volume superiore al 100% per contenuti audio bassi';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostra su Discord cosa stai guardando';
	@override String get matchContentFrameRate => 'Adatta frequenza fotogrammi';
	@override String get matchContentFrameRateDescription => 'Regola la frequenza di aggiornamento del display in base al contenuto video, riducendo i tremolii e risparmiando batteria';
	@override String get requireProfileSelectionOnOpen => 'Chiedi profilo all\'apertura';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostra la selezione del profilo ogni volta che l\'app viene aperta';
}

// Path: search
class _TranslationsSearchIt implements TranslationsSearchEn {
	_TranslationsSearchIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Cerca film. spettacoli, musica...';
	@override String get tryDifferentTerm => 'Prova altri termini di ricerca';
	@override String get searchYourMedia => 'Cerca nei tuoi media';
	@override String get enterTitleActorOrKeyword => 'Inserisci un titolo, attore o parola chiave';
}

// Path: hotkeys
class _TranslationsHotkeysIt implements TranslationsHotkeysEn {
	_TranslationsHotkeysIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Imposta scorciatoia per ${actionName}';
	@override String get clearShortcut => 'Elimina scorciatoia';
	@override late final _TranslationsHotkeysActionsIt actions = _TranslationsHotkeysActionsIt._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryIt implements TranslationsPinEntryEn {
	_TranslationsPinEntryIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Inserisci PIN';
	@override String get showPin => 'Mostra PIN';
	@override String get hidePin => 'Nascondi PIN';
}

// Path: fileInfo
class _TranslationsFileInfoIt implements TranslationsFileInfoEn {
	_TranslationsFileInfoIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Info sul file';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'File';
	@override String get advanced => 'Avanzate';
	@override String get codec => 'Codec';
	@override String get resolution => 'Risoluzione';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Frame Rate';
	@override String get aspectRatio => 'Aspect Ratio';
	@override String get profile => 'Profilo';
	@override String get bitDepth => 'Profondità colore';
	@override String get colorSpace => 'Spazio colore';
	@override String get colorRange => 'Gamma colori';
	@override String get colorPrimaries => 'Colori primari';
	@override String get chromaSubsampling => 'Sottocampionamento cromatico';
	@override String get channels => 'Canali';
	@override String get path => 'Percorso';
	@override String get size => 'Dimensione';
	@override String get container => 'Contenitore';
	@override String get duration => 'Durata';
	@override String get optimizedForStreaming => 'Ottimizzato per lo streaming';
	@override String get has64bitOffsets => 'Offset a 64-bit';
}

// Path: mediaMenu
class _TranslationsMediaMenuIt implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
	@override String get removeFromContinueWatching => 'Rimuovi da Continua a guardare';
	@override String get goToSeries => 'Vai alle serie';
	@override String get goToSeason => 'Vai alla stagione';
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get fileInfo => 'Info sul file';
	@override String get confirmDelete => 'Sei sicuro di voler eliminare questo elemento dal tuo filesystem?';
	@override String get deleteMultipleWarning => 'Potrebbero essere eliminati più elementi.';
	@override String get mediaDeletedSuccessfully => 'Elemento multimediale eliminato con successo';
	@override String get mediaFailedToDelete => 'Impossibile eliminare l\'elemento multimediale';
}

// Path: accessibility
class _TranslationsAccessibilityIt implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, serie TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visto';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} percento visto';
	@override String get mediaCardUnwatched => 'non visto';
	@override String get tapToPlay => 'Tocca per riprodurre';
}

// Path: tooltips
class _TranslationsTooltipsIt implements TranslationsTooltipsEn {
	_TranslationsTooltipsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
}

// Path: videoControls
class _TranslationsVideoControlsIt implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Sottotitoli';
	@override String get resetToZero => 'Riporta a 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} riprodotto dopo';
	@override String playsEarlier({required Object label}) => '${label} riprodotto prima';
	@override String get noOffset => 'Nessun offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Riempi schermo';
	@override String get stretch => 'Allunga';
	@override String get lockRotation => 'Blocca rotazione';
	@override String get unlockRotation => 'Sblocca rotazione';
	@override String get timerActive => 'Timer attivo';
	@override String playbackWillPauseIn({required Object duration}) => 'La riproduzione si interromperà tra ${duration}';
	@override String get sleepTimerCompleted => 'Timer di spegnimento completato - riproduzione in pausa';
	@override String get autoPlayNext => 'Riproduzione automatica successivo';
	@override String get playNext => 'Riproduci successivo';
	@override String get playButton => 'Riproduci';
	@override String get pauseButton => 'Pausa';
	@override String seekBackwardButton({required Object seconds}) => 'Riavvolgi di ${seconds} secondi';
	@override String seekForwardButton({required Object seconds}) => 'Avanza di ${seconds} secondi';
	@override String get previousButton => 'Episodio precedente';
	@override String get nextButton => 'Episodio successivo';
	@override String get previousChapterButton => 'Capitolo precedente';
	@override String get nextChapterButton => 'Capitolo successivo';
	@override String get muteButton => 'Silenzia';
	@override String get unmuteButton => 'Riattiva audio';
	@override String get settingsButton => 'Impostazioni video';
	@override String get audioTrackButton => 'Tracce audio';
	@override String get subtitlesButton => 'Sottotitoli';
	@override String get chaptersButton => 'Capitoli';
	@override String get versionsButton => 'Versioni video';
	@override String get pipButton => 'Modalità Picture-in-Picture';
	@override String get aspectRatioButton => 'Proporzioni';
	@override String get fullscreenButton => 'Attiva schermo intero';
	@override String get exitFullscreenButton => 'Esci da schermo intero';
	@override String get alwaysOnTopButton => 'Sempre in primo piano';
	@override String get rotationLockButton => 'Blocco rotazione';
	@override String get timelineSlider => 'Timeline video';
	@override String get volumeSlider => 'Livello volume';
	@override String endsAt({required Object time}) => 'Finisce alle ${time}';
	@override String get pipFailed => 'Impossibile avviare la modalità Picture-in-Picture';
	@override late final _TranslationsVideoControlsPipErrorsIt pipErrors = _TranslationsVideoControlsPipErrorsIt._(_root);
	@override String get chapters => 'Capitoli';
	@override String get noChaptersAvailable => 'Nessun capitolo disponibile';
}

// Path: userStatus
class _TranslationsUserStatusIt implements TranslationsUserStatusEn {
	_TranslationsUserStatusIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Limitato';
	@override String get protected => 'Protetto';
	@override String get current => 'ATTUALE';
}

// Path: messages
class _TranslationsMessagesIt implements TranslationsMessagesEn {
	_TranslationsMessagesIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Segna come visto';
	@override String get markedAsUnwatched => 'Segna come non visto';
	@override String get markedAsWatchedOffline => 'Segnato come visto (sincronizzato online)';
	@override String get markedAsUnwatchedOffline => 'Segnato come non visto (sincronizzato online)';
	@override String get removedFromContinueWatching => 'Rimosso da Continua a guardare';
	@override String errorLoading({required Object error}) => 'Errore: ${error}';
	@override String get fileInfoNotAvailable => 'Informazioni sul file non disponibili';
	@override String errorLoadingFileInfo({required Object error}) => 'Errore caricamento informazioni sul file: ${error}';
	@override String get errorLoadingSeries => 'Errore caricamento serie';
	@override String get errorLoadingSeason => 'Errore caricamento stagione';
	@override String get musicNotSupported => 'La riproduzione musicale non è ancora supportata';
	@override String get logsCleared => 'Log eliminati';
	@override String get logsCopied => 'Log copiati negli appunti';
	@override String get noLogsAvailable => 'Nessun log disponibile';
	@override String libraryScanning({required Object title}) => 'Scansione "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Scansione libreria iniziata per "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Impossibile eseguire scansione della libreria: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Aggiornamento metadati per "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Aggiornamento metadati per "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Errore aggiornamento metadati: ${error}';
	@override String get logoutConfirm => 'Sei sicuro di volerti disconnettere?';
	@override String get noSeasonsFound => 'Nessuna stagione trovata';
	@override String get noEpisodesFound => 'Nessun episodio trovato nella prima stagione';
	@override String get noEpisodesFoundGeneral => 'Nessun episodio trovato';
	@override String get noResultsFound => 'Nessun risultato';
	@override String sleepTimerSet({required Object label}) => 'Imposta timer spegnimento per ${label}';
	@override String get noItemsAvailable => 'Nessun elemento disponibile';
	@override String get failedToCreatePlayQueueNoItems => 'Impossibile creare la coda di riproduzione - nessun elemento';
	@override String failedPlayback({required Object action, required Object error}) => 'Impossibile ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Passaggio al lettore compatibile...';
	@override String get logsUploaded => 'Logs uploaded';
	@override String get logsUploadFailed => 'Failed to upload logs';
	@override String get logId => 'Log ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingIt implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opzioni stile';
	@override String get fontSize => 'Dimensione';
	@override String get textColor => 'Colore testo';
	@override String get borderSize => 'Dimensione bordo';
	@override String get borderColor => 'Colore bordo';
	@override String get backgroundOpacity => 'Opacità sfondo';
	@override String get backgroundColor => 'Colore sfondo';
	@override String get position => 'Position';
}

// Path: mpvConfig
class _TranslationsMpvConfigIt implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configurazione MPV';
	@override String get description => 'Impostazioni avanzate del lettore video';
	@override String get properties => 'Proprietà';
	@override String get presets => 'Preset';
	@override String get noProperties => 'Nessuna proprietà configurata';
	@override String get noPresets => 'Nessun preset salvato';
	@override String get addProperty => 'Aggiungi proprietà';
	@override String get editProperty => 'Modifica proprietà';
	@override String get deleteProperty => 'Elimina proprietà';
	@override String get propertyKey => 'Chiave proprietà';
	@override String get propertyKeyHint => 'es. hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Valore proprietà';
	@override String get propertyValueHint => 'es. auto, 256000000';
	@override String get saveAsPreset => 'Salva come preset...';
	@override String get presetName => 'Nome preset';
	@override String get presetNameHint => 'Inserisci un nome per questo preset';
	@override String get loadPreset => 'Carica';
	@override String get deletePreset => 'Elimina';
	@override String get presetSaved => 'Preset salvato';
	@override String get presetLoaded => 'Preset caricato';
	@override String get presetDeleted => 'Preset eliminato';
	@override String get confirmDeletePreset => 'Sei sicuro di voler eliminare questo preset?';
	@override String get confirmDeleteProperty => 'Sei sicuro di voler eliminare questa proprietà?';
	@override String entriesCount({required Object count}) => '${count} voci';
}

// Path: dialog
class _TranslationsDialogIt implements TranslationsDialogEn {
	_TranslationsDialogIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Conferma azione';
}

// Path: discover
class _TranslationsDiscoverIt implements TranslationsDiscoverEn {
	_TranslationsDiscoverIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esplora';
	@override String get switchProfile => 'Cambia profilo';
	@override String get noContentAvailable => 'Nessun contenuto disponibile';
	@override String get addMediaToLibraries => 'Aggiungi alcuni file multimediali alle tue librerie';
	@override String get continueWatching => 'Continua a guardare';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Panoramica';
	@override String get cast => 'Attori';
	@override String get seasons => 'Stagioni';
	@override String get studio => 'Studio';
	@override String get rating => 'Classificazione';
	@override String episodeCount({required Object count}) => '${count} episodi';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} guardati';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} minuti rimanenti';
}

// Path: errors
class _TranslationsErrorsIt implements TranslationsErrorsEn {
	_TranslationsErrorsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Ricerca fallita: ${error}';
	@override String connectionTimeout({required Object context}) => 'Timeout connessione durante caricamento di ${context}';
	@override String get connectionFailed => 'Impossibile connettersi al server Plex.';
	@override String failedToLoad({required Object context, required Object error}) => 'Impossibile caricare ${context}: ${error}';
	@override String get noClientAvailable => 'Nessun client disponibile';
	@override String authenticationFailed({required Object error}) => 'Autenticazione fallita: ${error}';
	@override String get couldNotLaunchUrl => 'Impossibile avviare URL di autenticazione';
	@override String get pleaseEnterToken => 'Inserisci token';
	@override String get invalidToken => 'Token non valido';
	@override String failedToVerifyToken({required Object error}) => 'Verifica token fallita: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossibile passare a ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesIt implements TranslationsLibrariesEn {
	_TranslationsLibrariesIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Librerie';
	@override String get scanLibraryFiles => 'Scansiona file libreria';
	@override String get scanLibrary => 'Scansiona libreria';
	@override String get analyze => 'Analizza';
	@override String get analyzeLibrary => 'Analizza libreria';
	@override String get refreshMetadata => 'Aggiorna metadati';
	@override String get emptyTrash => 'Svuota cestino';
	@override String emptyingTrash({required Object title}) => 'Svuotamento cestino per "${title}"...';
	@override String trashEmptied({required Object title}) => 'Cestino svuotato per "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Impossibile svuotare cestino: ${error}';
	@override String analyzing({required Object title}) => 'Analisi "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analisi iniziata per "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Impossibile analizzare libreria: ${error}';
	@override String get noLibrariesFound => 'Nessuna libreria trovata';
	@override String get thisLibraryIsEmpty => 'Questa libreria è vuota';
	@override String get all => 'Tutto';
	@override String get clearAll => 'Cancella tutto';
	@override String scanLibraryConfirm({required Object title}) => 'Sei sicuro di voler scansionare "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Sei sicuro di voler analizzare "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Sei sicuro di voler aggiornare i metadati per "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Sei sicuro di voler svuotare il cestino per "${title}"?';
	@override String get manageLibraries => 'Gestisci librerie';
	@override String get sort => 'Ordina';
	@override String get sortBy => 'Ordina per';
	@override String get filters => 'Filtri';
	@override String get confirmActionMessage => 'Sei sicuro di voler eseguire questa azione?';
	@override String get showLibrary => 'Mostra libreria';
	@override String get hideLibrary => 'Nascondi libreria';
	@override String get libraryOptions => 'Opzioni libreria';
	@override String get content => 'contenuto della libreria';
	@override String get selectLibrary => 'Seleziona libreria';
	@override String filtersWithCount({required Object count}) => 'Filtri (${count})';
	@override String get noRecommendations => 'Nessun consiglio disponibile';
	@override String get noCollections => 'Nessuna raccolta in questa libreria';
	@override String get noFoldersFound => 'Nessuna cartella trovata';
	@override String get folders => 'cartelle';
	@override late final _TranslationsLibrariesTabsIt tabs = _TranslationsLibrariesTabsIt._(_root);
	@override late final _TranslationsLibrariesGroupingsIt groupings = _TranslationsLibrariesGroupingsIt._(_root);
}

// Path: about
class _TranslationsAboutIt implements TranslationsAboutEn {
	_TranslationsAboutIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informazioni';
	@override String get openSourceLicenses => 'Licenze Open Source';
	@override String versionLabel({required Object version}) => 'Versione ${version}';
	@override String get appDescription => 'Un bellissimo client Plex per Flutter';
	@override String get viewLicensesDescription => 'Visualizza le licenze delle librerie di terze parti';
}

// Path: serverSelection
class _TranslationsServerSelectionIt implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Impossibile connettersi a nessun server. Controlla la tua rete e riprova.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Impossibile caricare i server: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailIt implements TranslationsHubDetailEn {
	_TranslationsHubDetailIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titolo';
	@override String get releaseYear => 'Anno rilascio';
	@override String get dateAdded => 'Data aggiunta';
	@override String get rating => 'Valutazione';
	@override String get noItemsFound => 'Nessun elemento trovato';
}

// Path: logs
class _TranslationsLogsIt implements TranslationsLogsEn {
	_TranslationsLogsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Cancella log';
	@override String get copyLogs => 'Copia log';
	@override String get uploadLogs => 'Upload Logs';
	@override String get error => 'Errore:';
	@override String get stackTrace => 'Traccia dello stack:';
}

// Path: licenses
class _TranslationsLicensesIt implements TranslationsLicensesEn {
	_TranslationsLicensesIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacchetti correlati';
	@override String get license => 'Licenza';
	@override String licenseNumber({required Object number}) => 'Licenza ${number}';
	@override String licensesCount({required Object count}) => '${count} licenze';
}

// Path: navigation
class _TranslationsNavigationIt implements TranslationsNavigationEn {
	_TranslationsNavigationIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Librerie';
	@override String get downloads => 'Download';
	@override String get liveTv => 'TV in diretta';
}

// Path: liveTv
class _TranslationsLiveTvIt implements TranslationsLiveTvEn {
	_TranslationsLiveTvIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV in diretta';
	@override String get channels => 'Canali';
	@override String get guide => 'Guida';
	@override String get recordings => 'Registrazioni';
	@override String get subscriptions => 'Regole di registrazione';
	@override String get scheduled => 'Programmati';
	@override String get noChannels => 'Nessun canale disponibile';
	@override String get noDvr => 'Nessun DVR configurato su nessun server';
	@override String get tuneFailed => 'Impossibile sintonizzare il canale';
	@override String get loading => 'Caricamento canali...';
	@override String get nowPlaying => 'In riproduzione';
	@override String get whatsOnNow => 'In onda adesso';
	@override String get record => 'Registra';
	@override String get recordSeries => 'Registra serie';
	@override String get cancelRecording => 'Annulla registrazione';
	@override String get deleteSubscription => 'Elimina regola di registrazione';
	@override String get deleteSubscriptionConfirm => 'Sei sicuro di voler eliminare questa regola di registrazione?';
	@override String get subscriptionDeleted => 'Regola di registrazione eliminata';
	@override String get noPrograms => 'Nessun dato di programma disponibile';
	@override String get noRecordings => 'Nessuna registrazione programmata';
	@override String get noSubscriptions => 'Nessuna regola di registrazione';
	@override String channelNumber({required Object number}) => 'Canale ${number}';
	@override String get live => 'IN DIRETTA';
	@override String get hd => 'HD';
	@override String get premiere => 'NUOVO';
	@override String get reloadGuide => 'Ricarica guida';
	@override String get guideReloaded => 'Dati della guida ricaricati';
	@override String get allChannels => 'Tutti i canali';
}

// Path: downloads
class _TranslationsDownloadsIt implements TranslationsDownloadsEn {
	_TranslationsDownloadsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Download';
	@override String get manage => 'Gestisci';
	@override String get tvShows => 'Serie TV';
	@override String get movies => 'Film';
	@override String get noDownloads => 'Nessun download';
	@override String get noDownloadsDescription => 'I contenuti scaricati appariranno qui per la visualizzazione offline';
	@override String get downloadNow => 'Scarica';
	@override String get deleteDownload => 'Elimina download';
	@override String get retryDownload => 'Riprova download';
	@override String get downloadQueued => 'Download in coda';
	@override String episodesQueued({required Object count}) => '${count} episodi in coda per il download';
	@override String get downloadDeleted => 'Download eliminato';
	@override String deleteConfirm({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Il file scaricato verrà rimosso dal tuo dispositivo.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Eliminazione di ${title}... (${current} di ${total})';
	@override String get noDownloadsTree => 'Nessun download';
	@override String get pauseAll => 'Metti tutto in pausa';
	@override String get resumeAll => 'Riprendi tutto';
	@override String get deleteAll => 'Elimina tutto';
}

// Path: playlists
class _TranslationsPlaylistsIt implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlist';
	@override String get noPlaylists => 'Nessuna playlist trovata';
	@override String get create => 'Crea playlist';
	@override String get playlistName => 'Nome playlist';
	@override String get enterPlaylistName => 'Inserisci nome playlist';
	@override String get delete => 'Elimina playlist';
	@override String get removeItem => 'Rimuovi da playlist';
	@override String get smartPlaylist => 'Playlist intelligente';
	@override String itemCount({required Object count}) => '${count} elementi';
	@override String get oneItem => '1 elemento';
	@override String get emptyPlaylist => 'Questa playlist è vuota';
	@override String get deleteConfirm => 'Eliminare playlist?';
	@override String deleteMessage({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?';
	@override String get created => 'Playlist creata';
	@override String get deleted => 'Playlist eliminata';
	@override String get itemAdded => 'Aggiunto alla playlist';
	@override String get itemRemoved => 'Rimosso dalla playlist';
	@override String get selectPlaylist => 'Seleziona playlist';
	@override String get createNewPlaylist => 'Crea nuova playlist';
	@override String get errorCreating => 'Errore durante la creazione della playlist';
	@override String get errorDeleting => 'Errore durante l\'eliminazione della playlist';
	@override String get errorLoading => 'Errore durante il caricamento delle playlist';
	@override String get errorAdding => 'Errore durante l\'aggiunta alla playlist';
	@override String get errorReordering => 'Errore durante il riordino dell\'elemento della playlist';
	@override String get errorRemoving => 'Errore durante la rimozione dalla playlist';
	@override String get playlist => 'Playlist';
}

// Path: collections
class _TranslationsCollectionsIt implements TranslationsCollectionsEn {
	_TranslationsCollectionsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Raccolte';
	@override String get collection => 'Raccolta';
	@override String get empty => 'La raccolta è vuota';
	@override String get unknownLibrarySection => 'Impossibile eliminare: sezione libreria sconosciuta';
	@override String get deleteCollection => 'Elimina raccolta';
	@override String deleteConfirm({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Questa azione non può essere annullata.';
	@override String get deleted => 'Raccolta eliminata';
	@override String get deleteFailed => 'Impossibile eliminare la raccolta';
	@override String deleteFailedWithError({required Object error}) => 'Impossibile eliminare la raccolta: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Impossibile caricare gli elementi della raccolta: ${error}';
	@override String get selectCollection => 'Seleziona raccolta';
	@override String get createNewCollection => 'Crea nuova raccolta';
	@override String get collectionName => 'Nome raccolta';
	@override String get enterCollectionName => 'Inserisci nome raccolta';
	@override String get addedToCollection => 'Aggiunto alla raccolta';
	@override String get errorAddingToCollection => 'Errore nell\'aggiunta alla raccolta';
	@override String get created => 'Raccolta creata';
	@override String get removeFromCollection => 'Rimuovi dalla raccolta';
	@override String removeFromCollectionConfirm({required Object title}) => 'Rimuovere "${title}" da questa raccolta?';
	@override String get removedFromCollection => 'Rimosso dalla raccolta';
	@override String get removeFromCollectionFailed => 'Impossibile rimuovere dalla raccolta';
	@override String removeFromCollectionError({required Object error}) => 'Errore durante la rimozione dalla raccolta: ${error}';
}

// Path: watchTogether
class _TranslationsWatchTogetherIt implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guarda Insieme';
	@override String get description => 'Guarda contenuti in sincronia con amici e familiari';
	@override String get createSession => 'Crea Sessione';
	@override String get creating => 'Creazione...';
	@override String get joinSession => 'Unisciti alla Sessione';
	@override String get joining => 'Connessione...';
	@override String get controlMode => 'Modalità di Controllo';
	@override String get controlModeQuestion => 'Chi può controllare la riproduzione?';
	@override String get hostOnly => 'Solo Host';
	@override String get anyone => 'Tutti';
	@override String get hostingSession => 'Hosting Sessione';
	@override String get inSession => 'In Sessione';
	@override String get sessionCode => 'Codice Sessione';
	@override String get hostControlsPlayback => 'L\'host controlla la riproduzione';
	@override String get anyoneCanControl => 'Tutti possono controllare la riproduzione';
	@override String get hostControls => 'Controllo host';
	@override String get anyoneControls => 'Controllo di tutti';
	@override String get participants => 'Partecipanti';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Sei l\'host';
	@override String get watchingWithOthers => 'Guardando con altri';
	@override String get endSession => 'Termina Sessione';
	@override String get leaveSession => 'Lascia Sessione';
	@override String get endSessionQuestion => 'Terminare la Sessione?';
	@override String get leaveSessionQuestion => 'Lasciare la Sessione?';
	@override String get endSessionConfirm => 'Questo terminerà la sessione per tutti i partecipanti.';
	@override String get leaveSessionConfirm => 'Sarai rimosso dalla sessione.';
	@override String get endSessionConfirmOverlay => 'Questo terminerà la sessione di visione per tutti i partecipanti.';
	@override String get leaveSessionConfirmOverlay => 'Sarai disconnesso dalla sessione di visione.';
	@override String get end => 'Termina';
	@override String get leave => 'Lascia';
	@override String get syncing => 'Sincronizzazione...';
	@override String get joinWatchSession => 'Unisciti alla Sessione di Visione';
	@override String get enterCodeHint => 'Inserisci codice di 8 caratteri';
	@override String get pasteFromClipboard => 'Incolla dagli appunti';
	@override String get pleaseEnterCode => 'Inserisci un codice sessione';
	@override String get codeMustBe8Chars => 'Il codice sessione deve essere di 8 caratteri';
	@override String get joinInstructions => 'Inserisci il codice sessione condiviso dall\'host per unirti alla loro sessione di visione.';
	@override String get failedToCreate => 'Impossibile creare la sessione';
	@override String get failedToJoin => 'Impossibile unirsi alla sessione';
	@override String get sessionCodeCopied => 'Codice sessione copiato negli appunti';
	@override String get relayUnreachable => 'Il server di inoltro non è raggiungibile. Questo potrebbe essere causato dal blocco della connessione da parte del tuo provider. Puoi comunque provare, ma Watch Together potrebbe non funzionare.';
	@override String get reconnectingToHost => 'Riconnessione all\'host...';
	@override String participantJoined({required Object name}) => '${name} si è unito';
	@override String participantLeft({required Object name}) => '${name} se ne è andato';
}

// Path: shaders
class _TranslationsShadersIt implements TranslationsShadersEn {
	_TranslationsShadersIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shader';
	@override String get noShaderDescription => 'Nessun miglioramento video';
	@override String get nvscalerDescription => 'Ridimensionamento NVIDIA per video più nitido';
	@override String get qualityFast => 'Veloce';
	@override String get qualityHQ => 'Alta qualità';
	@override String get mode => 'Modalità';
}

// Path: companionRemote
class _TranslationsCompanionRemoteIt implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Companion Remote';
	@override String get connectToDevice => 'Connetti a un dispositivo';
	@override String get hostRemoteSession => 'Ospita sessione remota';
	@override String get controlThisDevice => 'Controlla questo dispositivo con il tuo telefono';
	@override String get remoteControl => 'Telecomando';
	@override String get controlDesktop => 'Controlla un dispositivo desktop';
	@override String connectedTo({required Object name}) => 'Connesso a ${name}';
	@override late final _TranslationsCompanionRemoteSessionIt session = _TranslationsCompanionRemoteSessionIt._(_root);
	@override late final _TranslationsCompanionRemotePairingIt pairing = _TranslationsCompanionRemotePairingIt._(_root);
	@override late final _TranslationsCompanionRemoteRemoteIt remote = _TranslationsCompanionRemoteRemoteIt._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsIt implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Impostazioni di riproduzione';
	@override String get playbackSpeed => 'Velocità di riproduzione';
	@override String get sleepTimer => 'Timer di spegnimento';
	@override String get audioSync => 'Sincronizzazione audio';
	@override String get subtitleSync => 'Sincronizzazione sottotitoli';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Uscita audio';
	@override String get performanceOverlay => 'Overlay prestazioni';
}

// Path: externalPlayer
class _TranslationsExternalPlayerIt implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lettore esterno';
	@override String get useExternalPlayer => 'Usa lettore esterno';
	@override String get useExternalPlayerDescription => 'Apri i video in un\'app esterna invece del lettore integrato';
	@override String get selectPlayer => 'Seleziona lettore';
	@override String get systemDefault => 'Predefinito di sistema';
	@override String get addCustomPlayer => 'Aggiungi lettore personalizzato';
	@override String get playerName => 'Nome lettore';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nome pacchetto';
	@override String get playerUrlScheme => 'Schema URL';
	@override String get customPlayer => 'Lettore personalizzato';
	@override String get off => 'Disattivato';
	@override String get launchFailed => 'Impossibile aprire il lettore esterno';
	@override String appNotInstalled({required Object name}) => '${name} non è installato';
	@override String get playInExternalPlayer => 'Riproduci in lettore esterno';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsIt implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Riproduci/Pausa';
	@override String get volumeUp => 'Alza volume';
	@override String get volumeDown => 'Abbassa volume';
	@override String seekForward({required Object seconds}) => 'Avanti (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Indietro (${seconds}s)';
	@override String get fullscreenToggle => 'Schermo intero';
	@override String get muteToggle => 'Muto';
	@override String get subtitleToggle => 'Sottotitoli';
	@override String get audioTrackNext => 'Traccia audio successiva';
	@override String get subtitleTrackNext => 'Sottotitoli successivi';
	@override String get chapterNext => 'Capitolo successivo';
	@override String get chapterPrevious => 'Capitolo precedente';
	@override String get speedIncrease => 'Aumenta velocità';
	@override String get speedDecrease => 'Diminuisci velocità';
	@override String get speedReset => 'Ripristina velocità';
	@override String get subSeekNext => 'Vai al sottotitolo successivo';
	@override String get subSeekPrev => 'Vai al sottotitolo precedente';
	@override String get shaderToggle => 'Attiva/disattiva shader';
	@override String get skipMarker => 'Salta intro/titoli di coda';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsIt implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Richiede Android 8.0 o versioni successive';
	@override String get permissionDisabled => 'L\'autorizzazione Picture-in-Picture è disabilitata. Abilitala in Impostazioni > App > Plezy > Picture-in-Picture';
	@override String get notSupported => 'Questo dispositivo non supporta la modalità Picture-in-Picture';
	@override String get failed => 'Impossibile avviare la modalità Picture-in-Picture';
	@override String unknown({required Object error}) => 'Si è verificato un errore: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsIt implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Consigliati';
	@override String get browse => 'Esplora';
	@override String get collections => 'Raccolte';
	@override String get playlists => 'Playlist';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsIt implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get all => 'Tutti';
	@override String get movies => 'Film';
	@override String get shows => 'Serie TV';
	@override String get seasons => 'Stagioni';
	@override String get episodes => 'Episodi';
	@override String get folders => 'Cartelle';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionIt implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => 'Creazione sessione remota...';
	@override String get failedToCreate => 'Impossibile creare la sessione remota:';
	@override String get noSession => 'Nessuna sessione disponibile';
	@override String get scanQrCode => 'Scansiona QR Code';
	@override String get orEnterManually => 'Oppure inserisci manualmente';
	@override String get hostAddress => 'Indirizzo host';
	@override String get sessionId => 'ID sessione';
	@override String get pin => 'PIN';
	@override String get connected => 'Connesso';
	@override String get waitingForConnection => 'In attesa di connessione...';
	@override String get usePhoneToControl => 'Usa il tuo dispositivo mobile per controllare questa app';
	@override String copiedToClipboard({required Object label}) => '${label} copiato negli appunti';
	@override String get copyToClipboard => 'Copia negli appunti';
	@override String get newSession => 'Nuova sessione';
	@override String get minimize => 'Riduci';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingIt implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get recent => 'Recenti';
	@override String get scan => 'Scansiona';
	@override String get manual => 'Manuale';
	@override String get recentConnections => 'Connessioni recenti';
	@override String get quickReconnect => 'Riconnettiti rapidamente ai dispositivi associati in precedenza';
	@override String get pairWithDesktop => 'Associa con desktop';
	@override String get enterSessionDetails => 'Inserisci i dettagli della sessione mostrati sul tuo dispositivo desktop';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => 'Inserisci ID sessione di 8 caratteri';
	@override String get pinHint => 'Inserisci PIN di 6 cifre';
	@override String get connecting => 'Connessione...';
	@override String get tips => 'Suggerimenti';
	@override String get tipDesktop => 'Apri Plezy sul tuo desktop e abilita Companion Remote dalle impostazioni o dal menu';
	@override String get tipScan => 'Usa la scheda Scansiona per associare rapidamente scansionando il QR code sul tuo desktop';
	@override String get tipWifi => 'Assicurati che entrambi i dispositivi siano sulla stessa rete WiFi';
	@override String get cameraPermissionRequired => 'L\'autorizzazione della fotocamera è necessaria per scansionare i QR code.\nConcedi l\'accesso alla fotocamera nelle impostazioni del dispositivo.';
	@override String cameraError({required Object error}) => 'Impossibile avviare la fotocamera: ${error}';
	@override String get scanInstruction => 'Punta la fotocamera verso il QR code mostrato sul tuo desktop';
	@override String get noRecentConnections => 'Nessuna connessione recente';
	@override String get connectUsingManual => 'Connettiti a un dispositivo tramite inserimento manuale per iniziare';
	@override String get invalidQrCode => 'Formato QR code non valido';
	@override String get removeRecentConnection => 'Rimuovi connessione recente';
	@override String removeConfirm({required Object name}) => 'Rimuovere "${name}" dalle connessioni recenti?';
	@override String get validationHostRequired => 'Inserisci l\'indirizzo host';
	@override String get validationHostFormat => 'Il formato deve essere IP:porta (es. 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => 'Inserisci un ID sessione';
	@override String get validationSessionIdLength => 'L\'ID sessione deve essere di 8 caratteri';
	@override String get validationPinRequired => 'Inserisci un PIN';
	@override String get validationPinLength => 'Il PIN deve essere di 6 cifre';
	@override String get connectionTimedOut => 'Connessione scaduta. Verifica l\'ID sessione e il PIN.';
	@override String get sessionNotFound => 'Sessione non trovata. Verifica le tue credenziali.';
	@override String failedToConnect({required Object error}) => 'Connessione fallita: ${error}';
	@override String failedToLoadRecent({required Object error}) => 'Impossibile caricare le sessioni recenti: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteIt implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteIt._(this._root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Vuoi disconnetterti dalla sessione remota?';
	@override String get reconnecting => 'Riconnessione...';
	@override String attemptOf({required Object current}) => 'Tentativo ${current} di 5';
	@override String get retryNow => 'Riprova ora';
	@override String get connectionError => 'Errore di connessione';
	@override String get notConnected => 'Non connesso';
	@override String get tabRemote => 'Telecomando';
	@override String get tabPlay => 'Riproduci';
	@override String get tabMore => 'Altro';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Navigazione schede';
	@override String get tabDiscover => 'Esplora';
	@override String get tabLibraries => 'Librerie';
	@override String get tabSearch => 'Cerca';
	@override String get tabDownloads => 'Download';
	@override String get tabSettings => 'Impostazioni';
	@override String get previous => 'Precedente';
	@override String get playPause => 'Riproduci/Pausa';
	@override String get next => 'Successivo';
	@override String get seekBack => 'Riavvolgi';
	@override String get stop => 'Ferma';
	@override String get seekForward => 'Avanti';
	@override String get volume => 'Volume';
	@override String get volumeDown => 'Abbassa';
	@override String get volumeUp => 'Alza';
	@override String get fullscreen => 'Schermo intero';
	@override String get subtitles => 'Sottotitoli';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Cerca sul desktop...';
}

/// The flat map containing all translations for locale <it>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsIt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Accedi con Plex',
			'auth.showQRCode' => 'Mostra QR Code',
			'auth.authenticate' => 'Autenticazione',
			'auth.debugEnterToken' => 'Debug: Inserisci Token Plex',
			'auth.plexTokenLabel' => 'Token Auth Plex',
			'auth.plexTokenHint' => 'Inserisci il tuo token di Plex.tv',
			'auth.authenticationTimeout' => 'Autenticazione scaduta. Riprova.',
			'auth.scanQRToSignIn' => 'Scansiona il QR code per accedere',
			'auth.waitingForAuth' => 'In attesa di autenticazione...\nCompleta l\'accesso dal tuo browser.',
			'auth.useBrowser' => 'Usa browser',
			'common.cancel' => 'Cancella',
			'common.save' => 'Salva',
			'common.close' => 'Chiudi',
			'common.clear' => 'Pulisci',
			'common.reset' => 'Ripristina',
			'common.later' => 'Più tardi',
			'common.submit' => 'Invia',
			'common.confirm' => 'Conferma',
			'common.retry' => 'Riprova',
			'common.logout' => 'Disconnetti',
			'common.unknown' => 'Sconosciuto',
			'common.refresh' => 'Aggiorna',
			'common.yes' => 'Sì',
			'common.no' => 'No',
			'common.delete' => 'Elimina',
			'common.shuffle' => 'Casuale',
			'common.addTo' => 'Aggiungi a...',
			'common.remove' => 'Rimuovi',
			'common.paste' => 'Incolla',
			'common.connect' => 'Connetti',
			'common.disconnect' => 'Disconnetti',
			'common.play' => 'Riproduci',
			'common.pause' => 'Pausa',
			'common.resume' => 'Riprendi',
			'common.error' => 'Errore',
			'common.search' => 'Cerca',
			'common.home' => 'Home',
			'common.back' => 'Indietro',
			'common.settings' => 'Impostazioni',
			'common.mute' => 'Muto',
			'common.ok' => 'OK',
			'common.loading' => 'Caricamento...',
			'screens.licenses' => 'Licenze',
			'screens.switchProfile' => 'Cambia profilo',
			'screens.subtitleStyling' => 'Stile sottotitoli',
			'screens.mpvConfig' => 'Configurazione MPV',
			'screens.logs' => 'Registro',
			'update.available' => 'Aggiornamento disponibile',
			'update.versionAvailable' => ({required Object version}) => 'Versione ${version} disponibile',
			'update.currentVersion' => ({required Object version}) => 'Corrente: ${version}',
			'update.skipVersion' => 'Salta questa versione',
			'update.viewRelease' => 'Visualizza dettagli release',
			'update.latestVersion' => 'La versione installata è l\'ultima disponibile',
			'update.checkFailed' => 'Impossibile controllare gli aggiornamenti',
			'settings.title' => 'Impostazioni',
			'settings.language' => 'Lingua',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aspetto',
			'settings.videoPlayback' => 'Riproduzione video',
			'settings.advanced' => 'Avanzate',
			'settings.episodePosterMode' => 'Stile poster episodio',
			'settings.seriesPoster' => 'Poster della serie',
			'settings.seriesPosterDescription' => 'Mostra il poster della serie per tutti gli episodi',
			'settings.seasonPoster' => 'Poster della stagione',
			'settings.seasonPosterDescription' => 'Mostra il poster specifico della stagione per gli episodi',
			'settings.episodeThumbnail' => 'Miniatura episodio',
			'settings.episodeThumbnailDescription' => 'Mostra miniature 16:9 degli episodi',
			'settings.showHeroSectionDescription' => 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale',
			'settings.secondsLabel' => 'Secondi',
			'settings.minutesLabel' => 'Minuti',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Inserisci durata (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.systemThemeDescription' => 'Segui le impostazioni di sistema',
			'settings.lightTheme' => 'Chiaro',
			'settings.darkTheme' => 'Scuro',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Nero puro per schermi OLED',
			'settings.libraryDensity' => 'Densità libreria',
			'settings.compact' => 'Compatta',
			'settings.compactDescription' => 'Schede più piccole, più elementi visibili',
			'settings.normal' => 'Normale',
			'settings.normalDescription' => 'Dimensione predefinita',
			'settings.comfortable' => 'Comoda',
			'settings.comfortableDescription' => 'Schede più grandi, meno elementi visibili',
			'settings.viewMode' => 'Modalità di visualizzazione',
			'settings.gridView' => 'Griglia',
			'settings.gridViewDescription' => 'Visualizza gli elementi in un layout a griglia',
			'settings.listView' => 'Elenco',
			'settings.listViewDescription' => 'Visualizza gli elementi in un layout a elenco',
			'settings.showHeroSection' => 'Mostra sezione principale',
			'settings.useGlobalHubs' => 'Usa layout Home di Plex',
			'settings.useGlobalHubsDescription' => 'Mostra gli hub della home page come il client Plex ufficiale. Se disattivato, mostra invece i suggerimenti per libreria.',
			'settings.showServerNameOnHubs' => 'Mostra nome server sugli hub',
			'settings.showServerNameOnHubsDescription' => 'Mostra sempre il nome del server nei titoli degli hub. Se disattivato, solo per nomi hub duplicati.',
			'settings.alwaysKeepSidebarOpen' => 'Mantieni sempre aperta la barra laterale',
			'settings.alwaysKeepSidebarOpenDescription' => 'La barra laterale rimane espansa e l\'area del contenuto si adatta',
			'settings.showUnwatchedCount' => 'Mostra conteggio non visti',
			'settings.showUnwatchedCountDescription' => 'Mostra il numero di episodi non visti per serie e stagioni',
			'settings.playerBackend' => 'Motore di riproduzione',
			'settings.exoPlayer' => 'ExoPlayer (Consigliato)',
			'settings.exoPlayerDescription' => 'Lettore nativo Android con migliore supporto hardware',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => 'Lettore avanzato con più funzionalità e supporto sottotitoli ASS',
			'settings.hardwareDecoding' => 'Decodifica Hardware',
			'settings.hardwareDecodingDescription' => 'Utilizza l\'accelerazione hardware quando disponibile',
			'settings.bufferSize' => 'Dimensione buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.subtitleStyling' => 'Stile sottotitoli',
			'settings.subtitleStylingDescription' => 'Personalizza l\'aspetto dei sottotitoli',
			'settings.smallSkipDuration' => 'Durata skip breve',
			'settings.largeSkipDuration' => 'Durata skip lungo',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} secondi',
			'settings.defaultSleepTimer' => 'Timer spegnimento predefinito',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minuti',
			'settings.rememberTrackSelections' => 'Ricorda selezioni tracce per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Salva automaticamente le preferenze delle lingue audio e sottotitoli quando cambi tracce durante la riproduzione',
			'settings.clickVideoTogglesPlayback' => 'Fai clic sul video per avviare o mettere in pausa la riproduzione.',
			'settings.clickVideoTogglesPlaybackDescription' => 'Se questa opzione è abilitata, facendo clic sul lettore video la riproduzione verrà avviata o messa in pausa. In caso contrario, facendo clic verranno mostrati o nascosti i controlli di riproduzione.',
			'settings.videoPlayerControls' => 'Controlli del lettore video',
			'settings.keyboardShortcuts' => 'Scorciatoie da tastiera',
			'settings.keyboardShortcutsDescription' => 'Personalizza le scorciatoie da tastiera',
			'settings.videoPlayerNavigation' => 'Navigazione del lettore video',
			'settings.videoPlayerNavigationDescription' => 'Usa i tasti freccia per navigare nei controlli del lettore video',
			'settings.debugLogging' => 'Log di debug',
			'settings.debugLoggingDescription' => 'Abilita il logging dettagliato per la risoluzione dei problemi',
			'settings.viewLogs' => 'Visualizza log',
			'settings.viewLogsDescription' => 'Visualizza i log dell\'applicazione',
			'settings.clearCache' => 'Svuota cache',
			'settings.clearCacheDescription' => 'Questa opzione cancellerà tutte le immagini e i dati memorizzati nella cache. Dopo aver cancellato la cache, l\'app potrebbe impiegare più tempo per caricare i contenuti.',
			'settings.clearCacheSuccess' => 'Cache cancellata correttamente',
			'settings.resetSettings' => 'Ripristina impostazioni',
			'settings.resetSettingsDescription' => 'Questa opzione ripristinerà tutte le impostazioni ai valori predefiniti. Non può essere annullata.',
			'settings.resetSettingsSuccess' => 'Impostazioni ripristinate correttamente',
			'settings.shortcutsReset' => 'Scorciatoie ripristinate alle impostazioni predefinite',
			'settings.about' => 'Informazioni',
			'settings.aboutDescription' => 'Informazioni sull\'app e le licenze',
			'settings.updates' => 'Aggiornamenti',
			'settings.updateAvailable' => 'Aggiornamento disponibile',
			'settings.checkForUpdates' => 'Controlla aggiornamenti',
			'settings.validationErrorEnterNumber' => 'Inserisci un numero valido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'la durata deve essere compresa tra ${min} e ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Scorciatoia già assegnata a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Scorciatoia aggiornata per ${action}',
			'settings.autoSkip' => 'Salto Automatico',
			'settings.autoSkipIntro' => 'Salta Intro Automaticamente',
			'settings.autoSkipIntroDescription' => 'Salta automaticamente i marcatori dell\'intro dopo alcuni secondi',
			'settings.autoSkipCredits' => 'Salta Crediti Automaticamente',
			'settings.autoSkipCreditsDescription' => 'Salta automaticamente i crediti e riproduci l\'episodio successivo',
			'settings.autoSkipDelay' => 'Ritardo Salto Automatico',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Aspetta ${seconds} secondi prima del salto automatico',
			'settings.downloads' => 'Download',
			'settings.downloadLocationDescription' => 'Scegli dove salvare i contenuti scaricati',
			'settings.downloadLocationDefault' => 'Predefinita (Archiviazione App)',
			'settings.downloadLocationCustom' => 'Posizione Personalizzata',
			'settings.selectFolder' => 'Seleziona Cartella',
			'settings.resetToDefault' => 'Ripristina Predefinita',
			'settings.currentPath' => ({required Object path}) => 'Corrente: ${path}',
			'settings.downloadLocationChanged' => 'Posizione di download modificata',
			'settings.downloadLocationReset' => 'Posizione di download ripristinata a predefinita',
			'settings.downloadLocationInvalid' => 'La cartella selezionata non è scrivibile',
			'settings.downloadLocationSelectError' => 'Impossibile selezionare la cartella',
			'settings.downloadOnWifiOnly' => 'Scarica solo con WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Impedisci i download quando si utilizza la rete dati cellulare',
			'settings.cellularDownloadBlocked' => 'I download sono disabilitati sulla rete dati cellulare. Connettiti al WiFi o modifica l\'impostazione.',
			'settings.maxVolume' => 'Volume massimo',
			'settings.maxVolumeDescription' => 'Consenti volume superiore al 100% per contenuti audio bassi',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Mostra su Discord cosa stai guardando',
			'settings.matchContentFrameRate' => 'Adatta frequenza fotogrammi',
			'settings.matchContentFrameRateDescription' => 'Regola la frequenza di aggiornamento del display in base al contenuto video, riducendo i tremolii e risparmiando batteria',
			'settings.requireProfileSelectionOnOpen' => 'Chiedi profilo all\'apertura',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostra la selezione del profilo ogni volta che l\'app viene aperta',
			'search.hint' => 'Cerca film. spettacoli, musica...',
			'search.tryDifferentTerm' => 'Prova altri termini di ricerca',
			'search.searchYourMedia' => 'Cerca nei tuoi media',
			'search.enterTitleActorOrKeyword' => 'Inserisci un titolo, attore o parola chiave',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Imposta scorciatoia per ${actionName}',
			'hotkeys.clearShortcut' => 'Elimina scorciatoia',
			'hotkeys.actions.playPause' => 'Riproduci/Pausa',
			'hotkeys.actions.volumeUp' => 'Alza volume',
			'hotkeys.actions.volumeDown' => 'Abbassa volume',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avanti (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Indietro (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Schermo intero',
			'hotkeys.actions.muteToggle' => 'Muto',
			'hotkeys.actions.subtitleToggle' => 'Sottotitoli',
			'hotkeys.actions.audioTrackNext' => 'Traccia audio successiva',
			'hotkeys.actions.subtitleTrackNext' => 'Sottotitoli successivi',
			'hotkeys.actions.chapterNext' => 'Capitolo successivo',
			'hotkeys.actions.chapterPrevious' => 'Capitolo precedente',
			'hotkeys.actions.speedIncrease' => 'Aumenta velocità',
			'hotkeys.actions.speedDecrease' => 'Diminuisci velocità',
			'hotkeys.actions.speedReset' => 'Ripristina velocità',
			'hotkeys.actions.subSeekNext' => 'Vai al sottotitolo successivo',
			'hotkeys.actions.subSeekPrev' => 'Vai al sottotitolo precedente',
			'hotkeys.actions.shaderToggle' => 'Attiva/disattiva shader',
			'hotkeys.actions.skipMarker' => 'Salta intro/titoli di coda',
			'pinEntry.enterPin' => 'Inserisci PIN',
			'pinEntry.showPin' => 'Mostra PIN',
			'pinEntry.hidePin' => 'Nascondi PIN',
			'fileInfo.title' => 'Info sul file',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'File',
			'fileInfo.advanced' => 'Avanzate',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Risoluzione',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Frame Rate',
			'fileInfo.aspectRatio' => 'Aspect Ratio',
			'fileInfo.profile' => 'Profilo',
			'fileInfo.bitDepth' => 'Profondità colore',
			'fileInfo.colorSpace' => 'Spazio colore',
			'fileInfo.colorRange' => 'Gamma colori',
			'fileInfo.colorPrimaries' => 'Colori primari',
			'fileInfo.chromaSubsampling' => 'Sottocampionamento cromatico',
			'fileInfo.channels' => 'Canali',
			'fileInfo.path' => 'Percorso',
			'fileInfo.size' => 'Dimensione',
			'fileInfo.container' => 'Contenitore',
			'fileInfo.duration' => 'Durata',
			'fileInfo.optimizedForStreaming' => 'Ottimizzato per lo streaming',
			'fileInfo.has64bitOffsets' => 'Offset a 64-bit',
			'mediaMenu.markAsWatched' => 'Segna come visto',
			'mediaMenu.markAsUnwatched' => 'Segna come non visto',
			'mediaMenu.removeFromContinueWatching' => 'Rimuovi da Continua a guardare',
			'mediaMenu.goToSeries' => 'Vai alle serie',
			'mediaMenu.goToSeason' => 'Vai alla stagione',
			'mediaMenu.shufflePlay' => 'Riproduzione casuale',
			'mediaMenu.fileInfo' => 'Info sul file',
			'mediaMenu.confirmDelete' => 'Sei sicuro di voler eliminare questo elemento dal tuo filesystem?',
			'mediaMenu.deleteMultipleWarning' => 'Potrebbero essere eliminati più elementi.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Elemento multimediale eliminato con successo',
			'mediaMenu.mediaFailedToDelete' => 'Impossibile eliminare l\'elemento multimediale',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serie TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} percento visto',
			'accessibility.mediaCardUnwatched' => 'non visto',
			'accessibility.tapToPlay' => 'Tocca per riprodurre',
			'tooltips.shufflePlay' => 'Riproduzione casuale',
			'tooltips.markAsWatched' => 'Segna come visto',
			'tooltips.markAsUnwatched' => 'Segna come non visto',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Sottotitoli',
			'videoControls.resetToZero' => 'Riporta a 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} riprodotto dopo',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} riprodotto prima',
			'videoControls.noOffset' => 'Nessun offset',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Riempi schermo',
			'videoControls.stretch' => 'Allunga',
			'videoControls.lockRotation' => 'Blocca rotazione',
			'videoControls.unlockRotation' => 'Sblocca rotazione',
			'videoControls.timerActive' => 'Timer attivo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'La riproduzione si interromperà tra ${duration}',
			'videoControls.sleepTimerCompleted' => 'Timer di spegnimento completato - riproduzione in pausa',
			'videoControls.autoPlayNext' => 'Riproduzione automatica successivo',
			'videoControls.playNext' => 'Riproduci successivo',
			'videoControls.playButton' => 'Riproduci',
			'videoControls.pauseButton' => 'Pausa',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Riavvolgi di ${seconds} secondi',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avanza di ${seconds} secondi',
			'videoControls.previousButton' => 'Episodio precedente',
			'videoControls.nextButton' => 'Episodio successivo',
			'videoControls.previousChapterButton' => 'Capitolo precedente',
			'videoControls.nextChapterButton' => 'Capitolo successivo',
			'videoControls.muteButton' => 'Silenzia',
			'videoControls.unmuteButton' => 'Riattiva audio',
			'videoControls.settingsButton' => 'Impostazioni video',
			'videoControls.audioTrackButton' => 'Tracce audio',
			'videoControls.subtitlesButton' => 'Sottotitoli',
			'videoControls.chaptersButton' => 'Capitoli',
			'videoControls.versionsButton' => 'Versioni video',
			'videoControls.pipButton' => 'Modalità Picture-in-Picture',
			'videoControls.aspectRatioButton' => 'Proporzioni',
			'videoControls.fullscreenButton' => 'Attiva schermo intero',
			'videoControls.exitFullscreenButton' => 'Esci da schermo intero',
			'videoControls.alwaysOnTopButton' => 'Sempre in primo piano',
			'videoControls.rotationLockButton' => 'Blocco rotazione',
			'videoControls.timelineSlider' => 'Timeline video',
			'videoControls.volumeSlider' => 'Livello volume',
			'videoControls.endsAt' => ({required Object time}) => 'Finisce alle ${time}',
			'videoControls.pipFailed' => 'Impossibile avviare la modalità Picture-in-Picture',
			'videoControls.pipErrors.androidVersion' => 'Richiede Android 8.0 o versioni successive',
			'videoControls.pipErrors.permissionDisabled' => 'L\'autorizzazione Picture-in-Picture è disabilitata. Abilitala in Impostazioni > App > Plezy > Picture-in-Picture',
			'videoControls.pipErrors.notSupported' => 'Questo dispositivo non supporta la modalità Picture-in-Picture',
			'videoControls.pipErrors.failed' => 'Impossibile avviare la modalità Picture-in-Picture',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Si è verificato un errore: ${error}',
			'videoControls.chapters' => 'Capitoli',
			'videoControls.noChaptersAvailable' => 'Nessun capitolo disponibile',
			'userStatus.admin' => 'Admin',
			'userStatus.restricted' => 'Limitato',
			'userStatus.protected' => 'Protetto',
			'userStatus.current' => 'ATTUALE',
			'messages.markedAsWatched' => 'Segna come visto',
			'messages.markedAsUnwatched' => 'Segna come non visto',
			'messages.markedAsWatchedOffline' => 'Segnato come visto (sincronizzato online)',
			'messages.markedAsUnwatchedOffline' => 'Segnato come non visto (sincronizzato online)',
			'messages.removedFromContinueWatching' => 'Rimosso da Continua a guardare',
			'messages.errorLoading' => ({required Object error}) => 'Errore: ${error}',
			'messages.fileInfoNotAvailable' => 'Informazioni sul file non disponibili',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Errore caricamento informazioni sul file: ${error}',
			'messages.errorLoadingSeries' => 'Errore caricamento serie',
			'messages.errorLoadingSeason' => 'Errore caricamento stagione',
			'messages.musicNotSupported' => 'La riproduzione musicale non è ancora supportata',
			'messages.logsCleared' => 'Log eliminati',
			'messages.logsCopied' => 'Log copiati negli appunti',
			'messages.noLogsAvailable' => 'Nessun log disponibile',
			'messages.libraryScanning' => ({required Object title}) => 'Scansione "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Scansione libreria iniziata per "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Impossibile eseguire scansione della libreria: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Aggiornamento metadati per "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Aggiornamento metadati per "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Errore aggiornamento metadati: ${error}',
			'messages.logoutConfirm' => 'Sei sicuro di volerti disconnettere?',
			'messages.noSeasonsFound' => 'Nessuna stagione trovata',
			'messages.noEpisodesFound' => 'Nessun episodio trovato nella prima stagione',
			'messages.noEpisodesFoundGeneral' => 'Nessun episodio trovato',
			'messages.noResultsFound' => 'Nessun risultato',
			'messages.sleepTimerSet' => ({required Object label}) => 'Imposta timer spegnimento per ${label}',
			'messages.noItemsAvailable' => 'Nessun elemento disponibile',
			'messages.failedToCreatePlayQueueNoItems' => 'Impossibile creare la coda di riproduzione - nessun elemento',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Impossibile ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Passaggio al lettore compatibile...',
			'messages.logsUploaded' => 'Logs uploaded',
			'messages.logsUploadFailed' => 'Failed to upload logs',
			'messages.logId' => 'Log ID',
			'subtitlingStyling.stylingOptions' => 'Opzioni stile',
			'subtitlingStyling.fontSize' => 'Dimensione',
			'subtitlingStyling.textColor' => 'Colore testo',
			'subtitlingStyling.borderSize' => 'Dimensione bordo',
			'subtitlingStyling.borderColor' => 'Colore bordo',
			'subtitlingStyling.backgroundOpacity' => 'Opacità sfondo',
			'subtitlingStyling.backgroundColor' => 'Colore sfondo',
			'subtitlingStyling.position' => 'Position',
			'mpvConfig.title' => 'Configurazione MPV',
			'mpvConfig.description' => 'Impostazioni avanzate del lettore video',
			'mpvConfig.properties' => 'Proprietà',
			'mpvConfig.presets' => 'Preset',
			'mpvConfig.noProperties' => 'Nessuna proprietà configurata',
			'mpvConfig.noPresets' => 'Nessun preset salvato',
			'mpvConfig.addProperty' => 'Aggiungi proprietà',
			'mpvConfig.editProperty' => 'Modifica proprietà',
			'mpvConfig.deleteProperty' => 'Elimina proprietà',
			'mpvConfig.propertyKey' => 'Chiave proprietà',
			'mpvConfig.propertyKeyHint' => 'es. hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => 'Valore proprietà',
			'mpvConfig.propertyValueHint' => 'es. auto, 256000000',
			'mpvConfig.saveAsPreset' => 'Salva come preset...',
			'mpvConfig.presetName' => 'Nome preset',
			'mpvConfig.presetNameHint' => 'Inserisci un nome per questo preset',
			'mpvConfig.loadPreset' => 'Carica',
			'mpvConfig.deletePreset' => 'Elimina',
			'mpvConfig.presetSaved' => 'Preset salvato',
			'mpvConfig.presetLoaded' => 'Preset caricato',
			'mpvConfig.presetDeleted' => 'Preset eliminato',
			'mpvConfig.confirmDeletePreset' => 'Sei sicuro di voler eliminare questo preset?',
			'mpvConfig.confirmDeleteProperty' => 'Sei sicuro di voler eliminare questa proprietà?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} voci',
			'dialog.confirmAction' => 'Conferma azione',
			'discover.title' => 'Esplora',
			'discover.switchProfile' => 'Cambia profilo',
			'discover.noContentAvailable' => 'Nessun contenuto disponibile',
			'discover.addMediaToLibraries' => 'Aggiungi alcuni file multimediali alle tue librerie',
			'discover.continueWatching' => 'Continua a guardare',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Panoramica',
			'discover.cast' => 'Attori',
			'discover.seasons' => 'Stagioni',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Classificazione',
			'discover.episodeCount' => ({required Object count}) => '${count} episodi',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} guardati',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serie TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} minuti rimanenti',
			'errors.searchFailed' => ({required Object error}) => 'Ricerca fallita: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Timeout connessione durante caricamento di ${context}',
			'errors.connectionFailed' => 'Impossibile connettersi al server Plex.',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Impossibile caricare ${context}: ${error}',
			'errors.noClientAvailable' => 'Nessun client disponibile',
			'errors.authenticationFailed' => ({required Object error}) => 'Autenticazione fallita: ${error}',
			'errors.couldNotLaunchUrl' => 'Impossibile avviare URL di autenticazione',
			'errors.pleaseEnterToken' => 'Inserisci token',
			'errors.invalidToken' => 'Token non valido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Verifica token fallita: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Impossibile passare a ${displayName}',
			'libraries.title' => 'Librerie',
			'libraries.scanLibraryFiles' => 'Scansiona file libreria',
			'libraries.scanLibrary' => 'Scansiona libreria',
			'libraries.analyze' => 'Analizza',
			'libraries.analyzeLibrary' => 'Analizza libreria',
			'libraries.refreshMetadata' => 'Aggiorna metadati',
			'libraries.emptyTrash' => 'Svuota cestino',
			'libraries.emptyingTrash' => ({required Object title}) => 'Svuotamento cestino per "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Cestino svuotato per "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Impossibile svuotare cestino: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analisi "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analisi iniziata per "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Impossibile analizzare libreria: ${error}',
			'libraries.noLibrariesFound' => 'Nessuna libreria trovata',
			'libraries.thisLibraryIsEmpty' => 'Questa libreria è vuota',
			'libraries.all' => 'Tutto',
			'libraries.clearAll' => 'Cancella tutto',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Sei sicuro di voler scansionare "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Sei sicuro di voler analizzare "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Sei sicuro di voler aggiornare i metadati per "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Sei sicuro di voler svuotare il cestino per "${title}"?',
			'libraries.manageLibraries' => 'Gestisci librerie',
			'libraries.sort' => 'Ordina',
			'libraries.sortBy' => 'Ordina per',
			'libraries.filters' => 'Filtri',
			'libraries.confirmActionMessage' => 'Sei sicuro di voler eseguire questa azione?',
			'libraries.showLibrary' => 'Mostra libreria',
			'libraries.hideLibrary' => 'Nascondi libreria',
			'libraries.libraryOptions' => 'Opzioni libreria',
			'libraries.content' => 'contenuto della libreria',
			'libraries.selectLibrary' => 'Seleziona libreria',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtri (${count})',
			'libraries.noRecommendations' => 'Nessun consiglio disponibile',
			'libraries.noCollections' => 'Nessuna raccolta in questa libreria',
			'libraries.noFoldersFound' => 'Nessuna cartella trovata',
			'libraries.folders' => 'cartelle',
			'libraries.tabs.recommended' => 'Consigliati',
			'libraries.tabs.browse' => 'Esplora',
			'libraries.tabs.collections' => 'Raccolte',
			'libraries.tabs.playlists' => 'Playlist',
			'libraries.groupings.all' => 'Tutti',
			'libraries.groupings.movies' => 'Film',
			'libraries.groupings.shows' => 'Serie TV',
			'libraries.groupings.seasons' => 'Stagioni',
			'libraries.groupings.episodes' => 'Episodi',
			'libraries.groupings.folders' => 'Cartelle',
			'about.title' => 'Informazioni',
			'about.openSourceLicenses' => 'Licenze Open Source',
			'about.versionLabel' => ({required Object version}) => 'Versione ${version}',
			'about.appDescription' => 'Un bellissimo client Plex per Flutter',
			'about.viewLicensesDescription' => 'Visualizza le licenze delle librerie di terze parti',
			'serverSelection.allServerConnectionsFailed' => 'Impossibile connettersi a nessun server. Controlla la tua rete e riprova.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Impossibile caricare i server: ${error}',
			'hubDetail.title' => 'Titolo',
			'hubDetail.releaseYear' => 'Anno rilascio',
			'hubDetail.dateAdded' => 'Data aggiunta',
			'hubDetail.rating' => 'Valutazione',
			'hubDetail.noItemsFound' => 'Nessun elemento trovato',
			'logs.clearLogs' => 'Cancella log',
			'logs.copyLogs' => 'Copia log',
			'logs.uploadLogs' => 'Upload Logs',
			'logs.error' => 'Errore:',
			'logs.stackTrace' => 'Traccia dello stack:',
			'licenses.relatedPackages' => 'Pacchetti correlati',
			'licenses.license' => 'Licenza',
			'licenses.licenseNumber' => ({required Object number}) => 'Licenza ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenze',
			'navigation.libraries' => 'Librerie',
			'navigation.downloads' => 'Download',
			'navigation.liveTv' => 'TV in diretta',
			'liveTv.title' => 'TV in diretta',
			'liveTv.channels' => 'Canali',
			'liveTv.guide' => 'Guida',
			'liveTv.recordings' => 'Registrazioni',
			'liveTv.subscriptions' => 'Regole di registrazione',
			'liveTv.scheduled' => 'Programmati',
			'liveTv.noChannels' => 'Nessun canale disponibile',
			'liveTv.noDvr' => 'Nessun DVR configurato su nessun server',
			'liveTv.tuneFailed' => 'Impossibile sintonizzare il canale',
			'liveTv.loading' => 'Caricamento canali...',
			'liveTv.nowPlaying' => 'In riproduzione',
			'liveTv.whatsOnNow' => 'In onda adesso',
			'liveTv.record' => 'Registra',
			'liveTv.recordSeries' => 'Registra serie',
			'liveTv.cancelRecording' => 'Annulla registrazione',
			'liveTv.deleteSubscription' => 'Elimina regola di registrazione',
			'liveTv.deleteSubscriptionConfirm' => 'Sei sicuro di voler eliminare questa regola di registrazione?',
			'liveTv.subscriptionDeleted' => 'Regola di registrazione eliminata',
			'liveTv.noPrograms' => 'Nessun dato di programma disponibile',
			'liveTv.noRecordings' => 'Nessuna registrazione programmata',
			'liveTv.noSubscriptions' => 'Nessuna regola di registrazione',
			'liveTv.channelNumber' => ({required Object number}) => 'Canale ${number}',
			'liveTv.live' => 'IN DIRETTA',
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'NUOVO',
			'liveTv.reloadGuide' => 'Ricarica guida',
			'liveTv.guideReloaded' => 'Dati della guida ricaricati',
			'liveTv.allChannels' => 'Tutti i canali',
			'downloads.title' => 'Download',
			'downloads.manage' => 'Gestisci',
			'downloads.tvShows' => 'Serie TV',
			'downloads.movies' => 'Film',
			'downloads.noDownloads' => 'Nessun download',
			'downloads.noDownloadsDescription' => 'I contenuti scaricati appariranno qui per la visualizzazione offline',
			'downloads.downloadNow' => 'Scarica',
			'downloads.deleteDownload' => 'Elimina download',
			'downloads.retryDownload' => 'Riprova download',
			'downloads.downloadQueued' => 'Download in coda',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodi in coda per il download',
			'downloads.downloadDeleted' => 'Download eliminato',
			'downloads.deleteConfirm' => ({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Il file scaricato verrà rimosso dal tuo dispositivo.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Eliminazione di ${title}... (${current} di ${total})',
			'downloads.noDownloadsTree' => 'Nessun download',
			'downloads.pauseAll' => 'Metti tutto in pausa',
			'downloads.resumeAll' => 'Riprendi tutto',
			_ => null,
		} ?? switch (path) {
			'downloads.deleteAll' => 'Elimina tutto',
			'playlists.title' => 'Playlist',
			'playlists.noPlaylists' => 'Nessuna playlist trovata',
			'playlists.create' => 'Crea playlist',
			'playlists.playlistName' => 'Nome playlist',
			'playlists.enterPlaylistName' => 'Inserisci nome playlist',
			'playlists.delete' => 'Elimina playlist',
			'playlists.removeItem' => 'Rimuovi da playlist',
			'playlists.smartPlaylist' => 'Playlist intelligente',
			'playlists.itemCount' => ({required Object count}) => '${count} elementi',
			'playlists.oneItem' => '1 elemento',
			'playlists.emptyPlaylist' => 'Questa playlist è vuota',
			'playlists.deleteConfirm' => 'Eliminare playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?',
			'playlists.created' => 'Playlist creata',
			'playlists.deleted' => 'Playlist eliminata',
			'playlists.itemAdded' => 'Aggiunto alla playlist',
			'playlists.itemRemoved' => 'Rimosso dalla playlist',
			'playlists.selectPlaylist' => 'Seleziona playlist',
			'playlists.createNewPlaylist' => 'Crea nuova playlist',
			'playlists.errorCreating' => 'Errore durante la creazione della playlist',
			'playlists.errorDeleting' => 'Errore durante l\'eliminazione della playlist',
			'playlists.errorLoading' => 'Errore durante il caricamento delle playlist',
			'playlists.errorAdding' => 'Errore durante l\'aggiunta alla playlist',
			'playlists.errorReordering' => 'Errore durante il riordino dell\'elemento della playlist',
			'playlists.errorRemoving' => 'Errore durante la rimozione dalla playlist',
			'playlists.playlist' => 'Playlist',
			'collections.title' => 'Raccolte',
			'collections.collection' => 'Raccolta',
			'collections.empty' => 'La raccolta è vuota',
			'collections.unknownLibrarySection' => 'Impossibile eliminare: sezione libreria sconosciuta',
			'collections.deleteCollection' => 'Elimina raccolta',
			'collections.deleteConfirm' => ({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Questa azione non può essere annullata.',
			'collections.deleted' => 'Raccolta eliminata',
			'collections.deleteFailed' => 'Impossibile eliminare la raccolta',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Impossibile eliminare la raccolta: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Impossibile caricare gli elementi della raccolta: ${error}',
			'collections.selectCollection' => 'Seleziona raccolta',
			'collections.createNewCollection' => 'Crea nuova raccolta',
			'collections.collectionName' => 'Nome raccolta',
			'collections.enterCollectionName' => 'Inserisci nome raccolta',
			'collections.addedToCollection' => 'Aggiunto alla raccolta',
			'collections.errorAddingToCollection' => 'Errore nell\'aggiunta alla raccolta',
			'collections.created' => 'Raccolta creata',
			'collections.removeFromCollection' => 'Rimuovi dalla raccolta',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Rimuovere "${title}" da questa raccolta?',
			'collections.removedFromCollection' => 'Rimosso dalla raccolta',
			'collections.removeFromCollectionFailed' => 'Impossibile rimuovere dalla raccolta',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Errore durante la rimozione dalla raccolta: ${error}',
			'watchTogether.title' => 'Guarda Insieme',
			'watchTogether.description' => 'Guarda contenuti in sincronia con amici e familiari',
			'watchTogether.createSession' => 'Crea Sessione',
			'watchTogether.creating' => 'Creazione...',
			'watchTogether.joinSession' => 'Unisciti alla Sessione',
			'watchTogether.joining' => 'Connessione...',
			'watchTogether.controlMode' => 'Modalità di Controllo',
			'watchTogether.controlModeQuestion' => 'Chi può controllare la riproduzione?',
			'watchTogether.hostOnly' => 'Solo Host',
			'watchTogether.anyone' => 'Tutti',
			'watchTogether.hostingSession' => 'Hosting Sessione',
			'watchTogether.inSession' => 'In Sessione',
			'watchTogether.sessionCode' => 'Codice Sessione',
			'watchTogether.hostControlsPlayback' => 'L\'host controlla la riproduzione',
			'watchTogether.anyoneCanControl' => 'Tutti possono controllare la riproduzione',
			'watchTogether.hostControls' => 'Controllo host',
			'watchTogether.anyoneControls' => 'Controllo di tutti',
			'watchTogether.participants' => 'Partecipanti',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Sei l\'host',
			'watchTogether.watchingWithOthers' => 'Guardando con altri',
			'watchTogether.endSession' => 'Termina Sessione',
			'watchTogether.leaveSession' => 'Lascia Sessione',
			'watchTogether.endSessionQuestion' => 'Terminare la Sessione?',
			'watchTogether.leaveSessionQuestion' => 'Lasciare la Sessione?',
			'watchTogether.endSessionConfirm' => 'Questo terminerà la sessione per tutti i partecipanti.',
			'watchTogether.leaveSessionConfirm' => 'Sarai rimosso dalla sessione.',
			'watchTogether.endSessionConfirmOverlay' => 'Questo terminerà la sessione di visione per tutti i partecipanti.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Sarai disconnesso dalla sessione di visione.',
			'watchTogether.end' => 'Termina',
			'watchTogether.leave' => 'Lascia',
			'watchTogether.syncing' => 'Sincronizzazione...',
			'watchTogether.joinWatchSession' => 'Unisciti alla Sessione di Visione',
			'watchTogether.enterCodeHint' => 'Inserisci codice di 8 caratteri',
			'watchTogether.pasteFromClipboard' => 'Incolla dagli appunti',
			'watchTogether.pleaseEnterCode' => 'Inserisci un codice sessione',
			'watchTogether.codeMustBe8Chars' => 'Il codice sessione deve essere di 8 caratteri',
			'watchTogether.joinInstructions' => 'Inserisci il codice sessione condiviso dall\'host per unirti alla loro sessione di visione.',
			'watchTogether.failedToCreate' => 'Impossibile creare la sessione',
			'watchTogether.failedToJoin' => 'Impossibile unirsi alla sessione',
			'watchTogether.sessionCodeCopied' => 'Codice sessione copiato negli appunti',
			'watchTogether.relayUnreachable' => 'Il server di inoltro non è raggiungibile. Questo potrebbe essere causato dal blocco della connessione da parte del tuo provider. Puoi comunque provare, ma Watch Together potrebbe non funzionare.',
			'watchTogether.reconnectingToHost' => 'Riconnessione all\'host...',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} si è unito',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} se ne è andato',
			'shaders.title' => 'Shader',
			'shaders.noShaderDescription' => 'Nessun miglioramento video',
			'shaders.nvscalerDescription' => 'Ridimensionamento NVIDIA per video più nitido',
			'shaders.qualityFast' => 'Veloce',
			'shaders.qualityHQ' => 'Alta qualità',
			'shaders.mode' => 'Modalità',
			'companionRemote.title' => 'Companion Remote',
			'companionRemote.connectToDevice' => 'Connetti a un dispositivo',
			'companionRemote.hostRemoteSession' => 'Ospita sessione remota',
			'companionRemote.controlThisDevice' => 'Controlla questo dispositivo con il tuo telefono',
			'companionRemote.remoteControl' => 'Telecomando',
			'companionRemote.controlDesktop' => 'Controlla un dispositivo desktop',
			'companionRemote.connectedTo' => ({required Object name}) => 'Connesso a ${name}',
			'companionRemote.session.creatingSession' => 'Creazione sessione remota...',
			'companionRemote.session.failedToCreate' => 'Impossibile creare la sessione remota:',
			'companionRemote.session.noSession' => 'Nessuna sessione disponibile',
			'companionRemote.session.scanQrCode' => 'Scansiona QR Code',
			'companionRemote.session.orEnterManually' => 'Oppure inserisci manualmente',
			'companionRemote.session.hostAddress' => 'Indirizzo host',
			'companionRemote.session.sessionId' => 'ID sessione',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Connesso',
			'companionRemote.session.waitingForConnection' => 'In attesa di connessione...',
			'companionRemote.session.usePhoneToControl' => 'Usa il tuo dispositivo mobile per controllare questa app',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} copiato negli appunti',
			'companionRemote.session.copyToClipboard' => 'Copia negli appunti',
			'companionRemote.session.newSession' => 'Nuova sessione',
			'companionRemote.session.minimize' => 'Riduci',
			'companionRemote.pairing.recent' => 'Recenti',
			'companionRemote.pairing.scan' => 'Scansiona',
			'companionRemote.pairing.manual' => 'Manuale',
			'companionRemote.pairing.recentConnections' => 'Connessioni recenti',
			'companionRemote.pairing.quickReconnect' => 'Riconnettiti rapidamente ai dispositivi associati in precedenza',
			'companionRemote.pairing.pairWithDesktop' => 'Associa con desktop',
			'companionRemote.pairing.enterSessionDetails' => 'Inserisci i dettagli della sessione mostrati sul tuo dispositivo desktop',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Inserisci ID sessione di 8 caratteri',
			'companionRemote.pairing.pinHint' => 'Inserisci PIN di 6 cifre',
			'companionRemote.pairing.connecting' => 'Connessione...',
			'companionRemote.pairing.tips' => 'Suggerimenti',
			'companionRemote.pairing.tipDesktop' => 'Apri Plezy sul tuo desktop e abilita Companion Remote dalle impostazioni o dal menu',
			'companionRemote.pairing.tipScan' => 'Usa la scheda Scansiona per associare rapidamente scansionando il QR code sul tuo desktop',
			'companionRemote.pairing.tipWifi' => 'Assicurati che entrambi i dispositivi siano sulla stessa rete WiFi',
			'companionRemote.pairing.cameraPermissionRequired' => 'L\'autorizzazione della fotocamera è necessaria per scansionare i QR code.\nConcedi l\'accesso alla fotocamera nelle impostazioni del dispositivo.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Impossibile avviare la fotocamera: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Punta la fotocamera verso il QR code mostrato sul tuo desktop',
			'companionRemote.pairing.noRecentConnections' => 'Nessuna connessione recente',
			'companionRemote.pairing.connectUsingManual' => 'Connettiti a un dispositivo tramite inserimento manuale per iniziare',
			'companionRemote.pairing.invalidQrCode' => 'Formato QR code non valido',
			'companionRemote.pairing.removeRecentConnection' => 'Rimuovi connessione recente',
			'companionRemote.pairing.removeConfirm' => ({required Object name}) => 'Rimuovere "${name}" dalle connessioni recenti?',
			'companionRemote.pairing.validationHostRequired' => 'Inserisci l\'indirizzo host',
			'companionRemote.pairing.validationHostFormat' => 'Il formato deve essere IP:porta (es. 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Inserisci un ID sessione',
			'companionRemote.pairing.validationSessionIdLength' => 'L\'ID sessione deve essere di 8 caratteri',
			'companionRemote.pairing.validationPinRequired' => 'Inserisci un PIN',
			'companionRemote.pairing.validationPinLength' => 'Il PIN deve essere di 6 cifre',
			'companionRemote.pairing.connectionTimedOut' => 'Connessione scaduta. Verifica l\'ID sessione e il PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Sessione non trovata. Verifica le tue credenziali.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Connessione fallita: ${error}',
			'companionRemote.pairing.failedToLoadRecent' => ({required Object error}) => 'Impossibile caricare le sessioni recenti: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Vuoi disconnetterti dalla sessione remota?',
			'companionRemote.remote.reconnecting' => 'Riconnessione...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativo ${current} di 5',
			'companionRemote.remote.retryNow' => 'Riprova ora',
			'companionRemote.remote.connectionError' => 'Errore di connessione',
			'companionRemote.remote.notConnected' => 'Non connesso',
			'companionRemote.remote.tabRemote' => 'Telecomando',
			'companionRemote.remote.tabPlay' => 'Riproduci',
			'companionRemote.remote.tabMore' => 'Altro',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Navigazione schede',
			'companionRemote.remote.tabDiscover' => 'Esplora',
			'companionRemote.remote.tabLibraries' => 'Librerie',
			'companionRemote.remote.tabSearch' => 'Cerca',
			'companionRemote.remote.tabDownloads' => 'Download',
			'companionRemote.remote.tabSettings' => 'Impostazioni',
			'companionRemote.remote.previous' => 'Precedente',
			'companionRemote.remote.playPause' => 'Riproduci/Pausa',
			'companionRemote.remote.next' => 'Successivo',
			'companionRemote.remote.seekBack' => 'Riavvolgi',
			'companionRemote.remote.stop' => 'Ferma',
			'companionRemote.remote.seekForward' => 'Avanti',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Abbassa',
			'companionRemote.remote.volumeUp' => 'Alza',
			'companionRemote.remote.fullscreen' => 'Schermo intero',
			'companionRemote.remote.subtitles' => 'Sottotitoli',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Cerca sul desktop...',
			'videoSettings.playbackSettings' => 'Impostazioni di riproduzione',
			'videoSettings.playbackSpeed' => 'Velocità di riproduzione',
			'videoSettings.sleepTimer' => 'Timer di spegnimento',
			'videoSettings.audioSync' => 'Sincronizzazione audio',
			'videoSettings.subtitleSync' => 'Sincronizzazione sottotitoli',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Uscita audio',
			'videoSettings.performanceOverlay' => 'Overlay prestazioni',
			'externalPlayer.title' => 'Lettore esterno',
			'externalPlayer.useExternalPlayer' => 'Usa lettore esterno',
			'externalPlayer.useExternalPlayerDescription' => 'Apri i video in un\'app esterna invece del lettore integrato',
			'externalPlayer.selectPlayer' => 'Seleziona lettore',
			'externalPlayer.systemDefault' => 'Predefinito di sistema',
			'externalPlayer.addCustomPlayer' => 'Aggiungi lettore personalizzato',
			'externalPlayer.playerName' => 'Nome lettore',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nome pacchetto',
			'externalPlayer.playerUrlScheme' => 'Schema URL',
			'externalPlayer.customPlayer' => 'Lettore personalizzato',
			'externalPlayer.off' => 'Disattivato',
			'externalPlayer.launchFailed' => 'Impossibile aprire il lettore esterno',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} non è installato',
			'externalPlayer.playInExternalPlayer' => 'Riproduci in lettore esterno',
			_ => null,
		};
	}
}
