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
class TranslationsIt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsIt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsIt _root = this; // ignore: unused_field

	@override 
	TranslationsIt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsIt(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$it app = _Translations$app$it._(_root);
	@override late final _Translations$auth$it auth = _Translations$auth$it._(_root);
	@override late final _Translations$common$it common = _Translations$common$it._(_root);
	@override late final _Translations$screens$it screens = _Translations$screens$it._(_root);
	@override late final _Translations$update$it update = _Translations$update$it._(_root);
	@override late final _Translations$settings$it settings = _Translations$settings$it._(_root);
	@override late final _Translations$search$it search = _Translations$search$it._(_root);
	@override late final _Translations$hotkeys$it hotkeys = _Translations$hotkeys$it._(_root);
	@override late final _Translations$fileInfo$it fileInfo = _Translations$fileInfo$it._(_root);
	@override late final _Translations$mediaMenu$it mediaMenu = _Translations$mediaMenu$it._(_root);
	@override late final _Translations$rateSheet$it rateSheet = _Translations$rateSheet$it._(_root);
	@override late final _Translations$accessibility$it accessibility = _Translations$accessibility$it._(_root);
	@override late final _Translations$tooltips$it tooltips = _Translations$tooltips$it._(_root);
	@override late final _Translations$audioTracks$it audioTracks = _Translations$audioTracks$it._(_root);
	@override late final _Translations$videoControls$it videoControls = _Translations$videoControls$it._(_root);
	@override late final _Translations$messages$it messages = _Translations$messages$it._(_root);
	@override late final _Translations$subtitlingStyling$it subtitlingStyling = _Translations$subtitlingStyling$it._(_root);
	@override late final _Translations$mpvConfig$it mpvConfig = _Translations$mpvConfig$it._(_root);
	@override late final _Translations$dialog$it dialog = _Translations$dialog$it._(_root);
	@override late final _Translations$profiles$it profiles = _Translations$profiles$it._(_root);
	@override late final _Translations$connections$it connections = _Translations$connections$it._(_root);
	@override late final _Translations$discover$it discover = _Translations$discover$it._(_root);
	@override late final _Translations$errors$it errors = _Translations$errors$it._(_root);
	@override late final _Translations$libraries$it libraries = _Translations$libraries$it._(_root);
	@override late final _Translations$about$it about = _Translations$about$it._(_root);
	@override late final _Translations$serverSelection$it serverSelection = _Translations$serverSelection$it._(_root);
	@override late final _Translations$hubDetail$it hubDetail = _Translations$hubDetail$it._(_root);
	@override late final _Translations$logs$it logs = _Translations$logs$it._(_root);
	@override late final _Translations$licenses$it licenses = _Translations$licenses$it._(_root);
	@override late final _Translations$navigation$it navigation = _Translations$navigation$it._(_root);
	@override late final _Translations$explore$it explore = _Translations$explore$it._(_root);
	@override late final _Translations$liveTv$it liveTv = _Translations$liveTv$it._(_root);
	@override late final _Translations$collections$it collections = _Translations$collections$it._(_root);
	@override late final _Translations$playlists$it playlists = _Translations$playlists$it._(_root);
	@override late final _Translations$music$it music = _Translations$music$it._(_root);
	@override late final _Translations$watchTogether$it watchTogether = _Translations$watchTogether$it._(_root);
	@override late final _Translations$downloads$it downloads = _Translations$downloads$it._(_root);
	@override late final _Translations$shaders$it shaders = _Translations$shaders$it._(_root);
	@override late final _Translations$companionRemote$it companionRemote = _Translations$companionRemote$it._(_root);
	@override late final _Translations$videoSettings$it videoSettings = _Translations$videoSettings$it._(_root);
	@override late final _Translations$performanceOverlay$it performanceOverlay = _Translations$performanceOverlay$it._(_root);
	@override late final _Translations$externalPlayer$it externalPlayer = _Translations$externalPlayer$it._(_root);
	@override late final _Translations$metadataEdit$it metadataEdit = _Translations$metadataEdit$it._(_root);
	@override late final _Translations$matchScreen$it matchScreen = _Translations$matchScreen$it._(_root);
	@override late final _Translations$serverTasks$it serverTasks = _Translations$serverTasks$it._(_root);
	@override late final _Translations$trakt$it trakt = _Translations$trakt$it._(_root);
	@override late final _Translations$seerr$it seerr = _Translations$seerr$it._(_root);
	@override late final _Translations$services$it services = _Translations$services$it._(_root);
	@override late final _Translations$addServer$it addServer = _Translations$addServer$it._(_root);
}

// Path: app
class _Translations$app$it extends Translations$app$en {
	_Translations$app$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$it extends Translations$auth$en {
	_Translations$auth$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Accedi con Plex';
	@override String get showQRCode => 'Mostra codice QR';
	@override String get authenticate => 'Autenticati';
	@override String get authenticationTimeout => 'Tempo scaduto per l\'autenticazione. Riprova.';
	@override String get scanQRToSignIn => 'Scansiona questo codice QR per accedere';
	@override String get waitingForAuth => 'In attesa di autenticazione...\nAccedi dal browser.';
	@override String get useBrowser => 'Usa il browser';
	@override String get or => 'o';
	@override String get connectToJellyfin => 'Connettiti a Jellyfin';
	@override String get useQuickConnect => 'Usa Quick Connect';
	@override String get quickConnectInstructions => 'Apri Quick Connect in Jellyfin e inserisci questo codice.';
	@override String get quickConnectWaiting => 'In attesa di approvazione…';
	@override String get quickConnectCancel => 'Annulla';
	@override String get quickConnectExpired => 'Quick Connect scaduto. Riprova.';
	@override String get localDataRecoveryRequired => 'Plezy non è riuscito a recuperare in sicurezza i dati locali di accesso e delle riproduzioni in sospeso. Accedi di nuovo.';
}

// Path: common
class _Translations$common$it extends Translations$common$en {
	_Translations$common$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annulla';
	@override String get save => 'Salva';
	@override String get close => 'Chiudi';
	@override String get clear => 'Cancella';
	@override String get reset => 'Ripristina';
	@override String get later => 'Più tardi';
	@override String get submit => 'Invia';
	@override String get confirm => 'Conferma';
	@override String get retry => 'Riprova';
	@override String get logout => 'Esci';
	@override String get unknown => 'Sconosciuto';
	@override String get refresh => 'Aggiorna';
	@override String get yes => 'Sì';
	@override String get no => 'No';
	@override String get delete => 'Elimina';
	@override String get edit => 'Modifica';
	@override String get shuffle => 'Riproduzione casuale';
	@override String get addTo => 'Aggiungi a...';
	@override String get createNew => 'Crea nuovo';
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
	@override String get mute => 'Disattiva audio';
	@override String get ok => 'OK';
	@override String get off => 'Disattivato';
	@override String seasonNumber({required Object number}) => 'Stagione ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episodio ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Capitolo ${number}';
	@override String get reconnect => 'Riconnetti';
	@override String get viewAll => 'Mostra tutto';
	@override String get checkingNetwork => 'Controllo della rete...';
	@override String get loadingServers => 'Caricamento server...';
	@override String get connectingToServers => 'Connessione ai server...';
	@override String get startingOfflineMode => 'Avvio modalità offline...';
	@override String get loading => 'Caricamento...';
	@override String get fullscreen => 'Schermo intero';
	@override String get exitFullscreen => 'Esci dalla modalità a schermo intero';
	@override String get pressBackAgainToExit => 'Premi di nuovo Indietro per uscire';
}

// Path: screens
class _Translations$screens$it extends Translations$screens$en {
	_Translations$screens$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenze';
	@override String get switchProfile => 'Cambia profilo';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Log';
}

// Path: update
class _Translations$update$it extends Translations$update$en {
	_Translations$update$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Aggiornamento disponibile';
	@override String versionAvailable({required Object version}) => 'Versione ${version} disponibile';
	@override String currentVersion({required Object version}) => 'Attuale: ${version}';
	@override String get skipVersion => 'Salta questa versione';
	@override String get viewRelease => 'Visualizza note di rilascio';
	@override String get latestVersion => 'La versione installata è l\'ultima disponibile';
	@override String get checkFailed => 'Impossibile controllare gli aggiornamenti';
}

// Path: settings
class _Translations$settings$it extends Translations$settings$en {
	_Translations$settings$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Impostazioni';
	@override String get supportDeveloper => 'Supporta Plezy';
	@override String get supportDeveloperDescription => 'Dona tramite Liberapay per finanziare lo sviluppo';
	@override String get language => 'Lingua';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aspetto';
	@override String get videoPlayback => 'Riproduzione video';
	@override String get videoPlaybackDescription => 'Configura il comportamento di riproduzione';
	@override String get advanced => 'Avanzate';
	@override String get episodePosterMode => 'Stile poster episodio';
	@override String get seriesPoster => 'Poster della serie';
	@override String get seasonPoster => 'Poster della stagione';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale';
	@override String get secondsLabel => 'Secondi';
	@override String get minutesLabel => 'Minuti';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Inserisci una durata (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get lightTheme => 'Chiaro';
	@override String get darkTheme => 'Scuro';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Densità della libreria';
	@override String get compact => 'Compatta';
	@override String get comfortable => 'Comoda';
	@override String get tvCornerSpotlightBackdrop => 'Sfondo in evidenza nell\'angolo';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostra l\'immagine in evidenza nell\'angolo in alto a destra anziché a schermo intero';
	@override String get viewMode => 'Modalità di visualizzazione';
	@override String get gridView => 'Griglia';
	@override String get listView => 'Elenco';
	@override String get showHeroSection => 'Mostra sezione in evidenza';
	@override String get continueWatchingAction => 'Azione per Continua a guardare';
	@override String get continueWatchingPlay => 'Riproduci';
	@override String get continueWatchingDetails => 'Apri dettagli';
	@override String get episodeAction => 'Azione episodio';
	@override String get episodePlay => 'Riproduci';
	@override String get episodeDetails => 'Apri dettagli';
	@override String get useGlobalHubs => 'Usa il layout della Home';
	@override String get useGlobalHubsDescription => 'Mostra sezioni Home unificate. In caso contrario, usa i consigli della libreria.';
	@override String get showServerNameOnHubs => 'Mostra il nome del server nelle sezioni';
	@override String get showServerNameOnHubsDescription => 'Mostra sempre i nomi dei server nei titoli delle sezioni.';
	@override String get groupLibrariesByServer => 'Raggruppa le librerie per server';
	@override String get groupLibrariesByServerDescription => 'Raggruppa le librerie della barra laterale sotto ciascun server multimediale.';
	@override String get alwaysKeepSidebarOpen => 'Mantieni sempre aperta la barra laterale';
	@override String get alwaysKeepSidebarOpenDescription => 'La barra laterale rimane espansa e l\'area del contenuto si adatta';
	@override String get showUnwatchedCount => 'Mostra il numero di episodi non visti';
	@override String get showUnwatchedCountDescription => 'Mostra il numero di episodi non visti per serie e stagioni';
	@override String get showEpisodeNumberOnCards => 'Mostra il numero dell\'episodio sulle schede';
	@override String get showEpisodeNumberOnCardsDescription => 'Mostra il numero della stagione e dell\'episodio sulle schede degli episodi';
	@override String get showSeasonPostersOnTabs => 'Mostra i poster delle stagioni nelle schede';
	@override String get showSeasonPostersOnTabsDescription => 'Mostra il poster di ogni stagione sopra la sua scheda';
	@override String get tvFullCardLayout => 'Schede TV a tutta immagine';
	@override String get tvFullCardLayoutDescription => 'Usa schede TV con la sola immagine e i nomi degli attori sovrapposti';
	@override String get focusGlow => 'Bagliore di selezione';
	@override String get focusGlowDescription => 'Mostra un leggero bagliore attorno alla scheda selezionata';
	@override String get visualEffects => 'Effetti visivi';
	@override String get visualEffectsAuto => 'Automatico';
	@override String get visualEffectsAutoDescription => 'Riduci automaticamente gli effetti sui dispositivi a basso consumo';
	@override String get visualEffectsFull => 'Completi';
	@override String get visualEffectsReduced => 'Ridotti';
	@override String get visualEffectsReducedDescription => 'Meno animazioni e immagini a risoluzione inferiore';
	@override String get hideSpoilers => 'Nascondi spoiler per episodi non visti';
	@override String get hideSpoilersDescription => 'Sfoca miniature e descrizioni degli episodi non visti';
	@override String get playerBackend => 'Motore di riproduzione';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Decodifica hardware';
	@override String get hardwareDecodingDescription => 'Utilizza l\'accelerazione hardware quando disponibile';
	@override String get bufferSize => 'Dimensione buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Automatica (consigliata)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB di memoria disponibile. Un buffer di ${size}MB può influire sulla riproduzione.';
	@override String get defaultQualityTitle => 'Qualità predefinita';
	@override String get musicQualityTitle => 'Qualità musicale';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get subtitleStylingDescription => 'Personalizza l\'aspetto dei sottotitoli';
	@override String get smallSkipDuration => 'Salto breve';
	@override String get largeSkipDuration => 'Salto lungo';
	@override String get rewindOnResume => 'Riavvolgimento alla ripresa';
	@override String secondsUnit({required Object seconds}) => '${seconds} secondi';
	@override String get defaultSleepTimer => 'Timer spegnimento predefinito';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuti';
	@override String get rememberTrackSelections => 'Ricorda la selezione delle tracce per ogni serie o film';
	@override String get rememberTrackSelectionsDescription => 'Ricorda le scelte di audio e sottotitoli per ogni titolo';
	@override String get showChapterMarkersOnTimeline => 'Mostra i marcatori dei capitoli sulla barra di avanzamento';
	@override String get showChapterMarkersOnTimelineDescription => 'Segmenta la barra di avanzamento ai confini dei capitoli';
	@override String get clickVideoTogglesPlayback => 'Fai clic sul video per alternare riproduzione e pausa';
	@override String get clickVideoTogglesPlaybackDescription => 'Fai clic sul video per riprodurre o mettere in pausa anziché mostrare i controlli.';
	@override String get videoPlayerControls => 'Controlli del lettore video';
	@override String get keyboardShortcuts => 'Scorciatoie da tastiera';
	@override String get keyboardShortcutsDescription => 'Personalizza le scorciatoie da tastiera';
	@override String get videoPlayerNavigation => 'Navigazione del lettore video';
	@override String get videoPlayerNavigationDescription => 'Usa i tasti freccia per navigare nei controlli del lettore video';
	@override String get watchTogetherRelay => 'Relay di Guarda insieme';
	@override String get watchTogetherRelayDescription => 'Imposta un relay personalizzato. Tutti devono usare lo stesso server.';
	@override String get watchTogetherRelayHint => 'https://mio-relay.esempio.it';
	@override String get watchTogetherRelayInvalid => 'Inserisci un URL di base HTTP o HTTPS valido per il relay.';
	@override String get crashReporting => 'Segnalazione degli arresti anomali';
	@override String get crashReportingDescription => 'Invia segnalazioni sugli arresti anomali per contribuire a migliorare l\'app';
	@override String get debugLogging => 'Registrazione di debug';
	@override String get debugLoggingDescription => 'Abilita una registrazione dettagliata per la risoluzione dei problemi';
	@override String get viewLogs => 'Visualizza i log';
	@override String get viewLogsDescription => 'Visualizza i log dell\'applicazione';
	@override String get resetSettings => 'Ripristina impostazioni';
	@override String get resetSettingsDescription => 'Ripristina le impostazioni predefinite. Questa operazione non può essere annullata.';
	@override String get resetSettingsSuccess => 'Impostazioni ripristinate correttamente';
	@override String get backup => 'Backup';
	@override String get exportSettings => 'Esporta impostazioni';
	@override String get exportSettingsDescription => 'Salva le tue preferenze in un file';
	@override String get exportSettingsSuccess => 'Impostazioni esportate';
	@override String get importSettings => 'Importa impostazioni';
	@override String get importSettingsDescription => 'Ripristina le preferenze da un file';
	@override String get importSettingsConfirm => 'Questa azione sostituirà le impostazioni attuali. Continuare?';
	@override String get importSettingsSuccess => 'Impostazioni importate';
	@override String get importSettingsInvalidFile => 'Questo file non è un\'esportazione Plezy valida';
	@override String get importSettingsNoUser => 'Accedi prima di importare le impostazioni';
	@override String get shortcutsReset => 'Scorciatoie ripristinate alle impostazioni predefinite';
	@override String get about => 'Informazioni';
	@override String get aboutDescription => 'Informazioni sull\'app e le licenze';
	@override String get updates => 'Aggiornamenti';
	@override String get updateAvailable => 'Aggiornamento disponibile';
	@override String get checkForUpdates => 'Controlla aggiornamenti';
	@override String get autoCheckUpdatesOnStartup => 'Controlla automaticamente gli aggiornamenti all\'avvio';
	@override String get autoCheckUpdatesOnStartupDescription => 'Avvisa all\'avvio quando è disponibile un aggiornamento';
	@override String get validationErrorEnterNumber => 'Inserisci un numero valido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'La durata deve essere compresa tra ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Scorciatoia già assegnata a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Scorciatoia aggiornata per ${action}';
	@override String get saveFailed => 'Impossibile salvare le modifiche. Riprova.';
	@override String get autoSkip => 'Salto automatico';
	@override String get autoSkipIntro => 'Salta automaticamente la sigla iniziale';
	@override String get autoSkipIntroDescription => 'Salta automaticamente i marcatori della sigla iniziale dopo alcuni secondi';
	@override String get autoSkipCredits => 'Salta automaticamente i titoli di coda';
	@override String get autoSkipCreditsDescription => 'Salta automaticamente i titoli di coda e riproduce l\'episodio successivo';
	@override String get forceSkipMarkerFallback => 'Forza i marcatori di ripiego';
	@override String get forceSkipMarkerFallbackDescription => 'Usa i modelli dei titoli dei capitoli anche quando Plex dispone di marcatori';
	@override String get autoSkipDelay => 'Ritardo del salto automatico';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Attendi ${seconds} secondi prima del salto automatico';
	@override String get introPattern => 'Modello del marcatore della sigla iniziale';
	@override String get introPatternDescription => 'Espressione regolare per individuare i marcatori della sigla iniziale nei titoli dei capitoli';
	@override String get creditsPattern => 'Modello del marcatore dei titoli di coda';
	@override String get creditsPatternDescription => 'Espressione regolare per individuare i marcatori dei titoli di coda nei titoli dei capitoli';
	@override String get invalidRegex => 'Espressione regolare non valida';
	@override String get regex => 'Espressione regolare';
	@override String get downloads => 'Download';
	@override String get downloadLocationDescription => 'Scegli dove archiviare i contenuti scaricati';
	@override String get downloadLocationDefault => 'Predefinita (archivio dell\'app)';
	@override String get downloadLocationCustom => 'Posizione personalizzata';
	@override String get selectFolder => 'Seleziona cartella';
	@override String get resetToDefault => 'Ripristina posizione predefinita';
	@override String currentPath({required Object path}) => 'Attuale: ${path}';
	@override String get downloadLocationChanged => 'Posizione di download modificata';
	@override String get downloadLocationReset => 'Posizione di download ripristinata a predefinita';
	@override String get downloadLocationInvalid => 'La cartella selezionata non è scrivibile';
	@override String get downloadLocationPickerUnavailable => 'La selezione della cartella non è disponibile su questo dispositivo';
	@override String get downloadOnWifiOnly => 'Scarica solo tramite Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Impedisci i download quando si utilizza la rete dati cellulare';
	@override String get autoRemoveWatchedDownloads => 'Rimuovi automaticamente i download visti';
	@override String get autoRemoveWatchedDownloadsDescription => 'Elimina automaticamente i download già visti';
	@override String get cellularDownloadBlocked => 'I download sono bloccati sulla rete mobile. Usa il Wi-Fi o modifica l\'impostazione.';
	@override String get maxVolume => 'Volume massimo consentito';
	@override String get maxVolumeDescription => 'Consenti di aumentare il volume oltre il 100% per i contenuti con audio basso';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostra su Discord cosa stai guardando';
	@override String get services => 'Servizi';
	@override String get servicesDescription => 'Connetti Trakt, MyAnimeList, Seerr e altro';
	@override String get manageLibrariesDescription => 'Riordina e nascondi le librerie';
	@override String get companionRemoteServer => 'Server del telecomando';
	@override String get companionRemoteServerDescription => 'Consenti ai dispositivi mobili della tua rete di controllare questa app';
	@override String get autoPip => 'Picture-in-Picture automatica';
	@override String get autoPipDescription => 'Attiva automaticamente la modalità Picture-in-Picture quando esci dall\'app durante la riproduzione';
	@override String get matchContentFrameRate => 'Adatta la frequenza dei fotogrammi';
	@override String get matchContentFrameRateDescription => 'Adatta la frequenza di aggiornamento dello schermo al contenuto video';
	@override String get matchRefreshRate => 'Adatta la frequenza di aggiornamento';
	@override String get matchRefreshRateDescription => 'Adatta la frequenza di aggiornamento dello schermo in modalità a schermo intero';
	@override String get matchDynamicRange => 'Adatta la gamma dinamica';
	@override String get matchDynamicRangeDescription => 'Attiva l\'HDR per i contenuti HDR, quindi torna all\'SDR';
	@override String get displaySwitchDelay => 'Ritardo del cambio di modalità dello schermo';
	@override String get tunneledPlayback => 'Riproduzione con tunneling';
	@override String get tunneledPlaybackDescription => 'Usa il tunneling video. Disattivalo se durante la riproduzione HDR lo schermo rimane nero.';
	@override String get audioPassthrough => 'Passthrough audio';
	@override String get audioPassthroughDescription => 'Invia l\'audio Dolby/DTS al ricevitore o al televisore senza ricodificarlo, preservando l\'audio surround. Disattiva questa opzione se non senti alcun suono.';
	@override String get audioPassthroughDescriptionAppleTv => 'Usa il decoder Dolby nativo di Apple per Dolby Digital Plus, incluso Atmos. DTS e TrueHD vengono comunque riprodotti come PCM multicanale. Disattiva questa opzione se non senti alcun suono.';
	@override String get audioDownmix => 'Downmix in stereo';
	@override String get audioDownmixDescription => 'Riduce l\'audio surround a due canali per altoparlanti stereo o cuffie';
	@override String get downmixCenterBoost => 'Amplificazione canale centrale';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Amplificazione (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizza il volume durante il downmix';
	@override String get audioDownmixNormalizeDescription => 'Riduce il volume del mix per evitare il clipping. Disattiva questa opzione per mantenere il volume originale (le scene più rumorose potrebbero risultare distorte).';
	@override String get atmosDiagnostics => 'Test uscita Atmos';
	@override String get atmosDiagnosticsDescription => 'Diagnostica l\'uscita Dolby Atmos riproducendo segnali di prova con il lettore di sistema';
	@override String get atmosTestHlsAtmos => 'Stream Atmos di Apple';
	@override String get atmosTestHlsAtmosDescription => 'Stream Dolby Atmos di riferimento. Il ricevitore dovrebbe mostrare Dolby Atmos.';
	@override String get atmosTestHlsControl => 'Stream surround di Apple';
	@override String get atmosTestHlsControlDescription => 'Stream di controllo senza Atmos. Il ricevitore dovrebbe mostrare surround senza Atmos.';
	@override String get atmosTestRawStream => 'Stream EAC3 grezzo';
	@override String get atmosTestRawStreamDescription => 'Trasmette il file di prova esattamente come la riproduzione Atmos del lettore. Richiede l\'URL del file di prova.';
	@override String get atmosTestRawFile => 'File EAC3 grezzo';
	@override String get atmosTestRawFileDescription => 'Riproduce il file di prova con lunghezza nota. Richiede l\'URL del file di prova.';
	@override String get atmosTestAsbarNative => 'Renderer con buffer di campioni (nativo)';
	@override String get atmosTestAsbarNativeDescription => 'Invia l\'audio compresso intatto del file direttamente al renderer di sistema. Richiede l\'URL del file di test.';
	@override String get atmosTestAsbarGenerated => 'Renderer con buffer di campioni (ricostruito)';
	@override String get atmosTestAsbarGeneratedDescription => 'Come sopra, ma con la descrizione audio costruita come nella riproduzione. Richiede l\'URL del file di test.';
	@override String get atmosTestSessionMode => 'Usa la modalità riproduzione film';
	@override String get atmosTestSessionModeDescription => 'Disattivato usa la modalità documentata da Dolby. Attivato usa la modalità precedente.';
	@override String get atmosTestShowRoutePicker => 'Scegli uscita AirPlay';
	@override String get atmosTestHideRoutePicker => 'Nascondi selettore uscita AirPlay';
	@override String get atmosTestRoutePickerDescription => 'Invia il test a un ricevitore AirPlay. Solo AirPlay riporta la modalità audio risolta.';
	@override String get atmosTestStop => 'Interrompi test';
	@override String get atmosTestUrl => 'URL del file di prova';
	@override String get atmosTestUrlDescription => 'URL HTTP di un file .ec3 Dolby Atmos grezzo (ad es. estratto con ffmpeg)';
	@override String get atmosTestUrlMissing => 'Imposta prima l\'URL del file di prova';
	@override String get atmosTestStatus => 'Stato';
	@override String get dvConversionMode => 'Conversione Dolby Vision';
	@override String get dvConversionModeDescription => 'Scegli come ExoPlayer gestisce i file Dolby Vision con profilo 7.';
	@override String get dvConversionAuto => 'Auto';
	@override String get dvConversionNative => 'Nativa / disattivata';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Rileva le capacità del dispositivo e usa il normale meccanismo di ripiego';
	@override String get dvConversionNativeDescription => 'Forza il DV7 nativo e impedisce nuovi tentativi di conversione DV';
	@override String get dvConversionDv81Description => 'Forza la conversione RPU diretta al profilo Dolby Vision 8.1';
	@override String get dvConversionHevcStripDescription => 'Rimuove i livelli RPU/EL di Dolby Vision e riproduce il video come semplice HEVC';
	@override String get requireProfileSelectionOnOpen => 'Chiedi di scegliere il profilo all\'apertura';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostra la selezione del profilo ogni volta che l\'app viene aperta';
	@override String get forceTvMode => 'Forza modalità TV';
	@override String get forceTvModeDescription => 'Forza il layout TV sui dispositivi che non vengono rilevati automaticamente. Richiede il riavvio.';
	@override String get startInFullscreen => 'Avvia a schermo intero';
	@override String get startInFullscreenDescription => 'Apri Plezy a schermo intero all\'avvio';
	@override String get exitFullscreenOnPlayerClose => 'Esci dalla modalità a schermo intero alla chiusura del lettore';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Esce automaticamente dalla modalità a schermo intero quando chiudi il lettore video';
	@override String get autoHidePerformanceOverlay => 'Nascondi automaticamente il riquadro delle prestazioni';
	@override String get autoHidePerformanceOverlayDescription => 'Dissolvi il riquadro delle prestazioni insieme ai controlli di riproduzione';
	@override String get showNavBarLabels => 'Mostra le etichette della barra di navigazione';
	@override String get showNavBarLabelsDescription => 'Mostra le etichette di testo sotto le icone della barra di navigazione';
	@override String get startupSection => 'Sezione di avvio';
	@override String get liveTvDefaultFavorites => 'Apri sui canali preferiti';
	@override String get liveTvDefaultFavoritesDescription => 'Mostra solo i canali preferiti quando apri la TV in diretta';
	@override String get display => 'Schermo';
	@override String get homeScreen => 'Schermata iniziale';
	@override String get navigation => 'Navigazione';
	@override String get window => 'Finestra';
	@override String get content => 'Contenuti';
	@override String get player => 'Lettore';
	@override String get subtitlesAndConfig => 'Sottotitoli e impostazioni';
	@override String get seekAndTiming => 'Avanzamento e tempi';
	@override String get behavior => 'Comportamento';
}

// Path: search
class _Translations$search$it extends Translations$search$en {
	_Translations$search$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Cerca film, serie TV e musica...';
	@override String get tryDifferentTerm => 'Prova altri termini di ricerca';
	@override String get searchYourMedia => 'Cerca nei tuoi media';
	@override String get enterTitleActorOrKeyword => 'Inserisci un titolo, attore o parola chiave';
}

// Path: hotkeys
class _Translations$hotkeys$it extends Translations$hotkeys$en {
	_Translations$hotkeys$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Imposta una scorciatoia per ${actionName}';
	@override String get clearShortcut => 'Elimina scorciatoia';
	@override String get noShortcutSet => 'Nessuna scorciatoia impostata';
	@override String get currentShortcut => 'Scorciatoia attuale:';
	@override String get pressToRecord => 'Seleziona per registrare una scorciatoia';
	@override String get recordingShortcut => 'Premi ora la scorciatoia';
	@override late final _Translations$hotkeys$actions$it actions = _Translations$hotkeys$actions$it._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$it extends Translations$fileInfo$en {
	_Translations$fileInfo$it._(TranslationsIt root) : this._root = root, super.internal(root);

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
	@override String get frameRate => 'Frequenza fotogrammi';
	@override String get aspectRatio => 'Proporzioni';
	@override String get profile => 'Profilo';
	@override String get bitDepth => 'Profondità in bit';
	@override String get colorSpace => 'Spazio colore';
	@override String get colorRange => 'Gamma colori';
	@override String get colorPrimaries => 'Colori primari';
	@override String get chromaSubsampling => 'Sottocampionamento cromatico';
	@override String get channels => 'Canali';
	@override String get subtitles => 'Sottotitoli';
	@override String get overallBitrate => 'Bitrate complessivo';
	@override String get path => 'Percorso';
	@override String get size => 'Dimensione';
	@override String get container => 'Contenitore';
	@override String get duration => 'Durata';
	@override String get optimizedForStreaming => 'Ottimizzato per lo streaming';
	@override String get has64bitOffsets => 'Offset a 64 bit';
}

// Path: mediaMenu
class _Translations$mediaMenu$it extends Translations$mediaMenu$en {
	_Translations$mediaMenu$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
	@override String get removeFromContinueWatching => 'Rimuovi da Continua a guardare';
	@override String get viewDetails => 'Visualizza dettagli';
	@override String get goToSeries => 'Vai alla serie';
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get shuffleNotAvailableOffline => 'Riproduzione casuale non disponibile offline';
	@override String get fileInfo => 'Info sul file';
	@override String get deleteFromServer => 'Elimina dal server';
	@override String get confirmDelete => 'Eliminare questo media e i suoi file dal server?';
	@override String get deleteMultipleWarning => 'Sono inclusi tutti gli episodi e i relativi file.';
	@override String get mediaDeletedSuccessfully => 'Elemento multimediale eliminato correttamente';
	@override String get mediaFailedToDelete => 'Impossibile eliminare l\'elemento multimediale';
	@override String get rate => 'Valuta';
	@override String get playFromBeginning => 'Riproduci dall\'inizio';
	@override String get playVersion => 'Riproduci versione...';
}

// Path: rateSheet
class _Translations$rateSheet$it extends Translations$rateSheet$en {
	_Translations$rateSheet$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Valuta';
	@override String get server => 'Server';
	@override String get favorite => 'Preferito';
	@override String get favorited => 'Aggiunto ai preferiti';
	@override String get saved => 'Salvato';
	@override String get notAvailable => 'Nessuna corrispondenza trovata';
	@override String get noConnectedServices => 'Collega un servizio nelle Impostazioni per assegnare valutazioni anche su quel servizio.';
}

// Path: accessibility
class _Translations$accessibility$it extends Translations$accessibility$en {
	_Translations$accessibility$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, serie TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visto';
	@override String mediaCardPartiallyWatched({required Object percent}) => 'visto al ${percent}%';
	@override String get mediaCardUnwatched => 'non visto';
	@override String get tapToPlay => 'Tocca per riprodurre';
	@override String get decrease => 'Diminuisci';
	@override String get increase => 'Aumenta';
	@override String decreaseValue({required Object label}) => 'Diminuisci ${label}';
	@override String increaseValue({required Object label}) => 'Aumenta ${label}';
	@override String get hue => 'Tonalità';
	@override String get saturation => 'Saturazione';
	@override String get brightness => 'Luminosità';
	@override String get hexColor => 'Colore esadecimale';
	@override String get expandText => 'Espandi il testo';
	@override String get collapseText => 'Comprimi il testo';
	@override String get alphabetNavigation => 'Navigazione alfabetica';
	@override String get alphabetScrollHint => 'Scorri verso l\'alto o il basso per cambiare lettera';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Riga ${row} di ${rowCount}, colonna ${column} di ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Riga ${row} di ${rowCount}';
}

// Path: tooltips
class _Translations$tooltips$it extends Translations$tooltips$en {
	_Translations$tooltips$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get playTrailer => 'Riproduci trailer';
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
}

// Path: audioTracks
class _Translations$audioTracks$it extends Translations$audioTracks$en {
	_Translations$audioTracks$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Traccia audio ${n}';
}

// Path: videoControls
class _Translations$videoControls$it extends Translations$videoControls$en {
	_Translations$videoControls$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Sottotitoli';
	@override String get resetToZero => 'Ripristina a 0 ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label}: riproduzione ritardata';
	@override String playsEarlier({required Object label}) => '${label}: riproduzione anticipata';
	@override String get noOffset => 'Nessun ritardo';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Riempi lo schermo';
	@override String get stretch => 'Allunga';
	@override String get lockRotation => 'Blocca rotazione';
	@override String get unlockRotation => 'Sblocca rotazione';
	@override String get timerActive => 'Timer attivo';
	@override String playbackWillPauseIn({required Object duration}) => 'La riproduzione verrà messa in pausa tra ${duration}';
	@override String get sleepTimerEndOfVideo => 'Fine del video corrente';
	@override String get sleepTimerStopAtHeader => 'Interrompi alle';
	@override String get sleepTimerDurationHeader => 'Timer';
	@override String get playbackWillPauseAtEnd => 'La riproduzione verrà messa in pausa alla fine di questo video';
	@override String get stillWatching => 'Stai ancora guardando?';
	@override String pausingIn({required Object seconds}) => 'Pausa tra ${seconds}s';
	@override String get continueWatching => 'Continua';
	@override String get autoPlayNext => 'Riproduci automaticamente il successivo';
	@override String get playNext => 'Riproduci il successivo';
	@override String get playButton => 'Riproduci';
	@override String get pauseButton => 'Pausa';
	@override String get showPlaybackControls => 'Mostra i controlli di riproduzione';
	@override String get hidePlaybackControls => 'Nascondi i controlli di riproduzione';
	@override String seekBackwardButton({required Object seconds}) => 'Riavvolgi di ${seconds} secondi';
	@override String seekForwardButton({required Object seconds}) => 'Avanza di ${seconds} secondi';
	@override String get previousButton => 'Episodio precedente';
	@override String get nextButton => 'Episodio successivo';
	@override String get previousChapterButton => 'Capitolo precedente';
	@override String get nextChapterButton => 'Capitolo successivo';
	@override String get muteButton => 'Silenzia';
	@override String get unmuteButton => 'Riattiva audio';
	@override String get settingsButton => 'Impostazioni di riproduzione';
	@override String get tracksButton => 'Audio e sottotitoli';
	@override String get chaptersButton => 'Capitoli';
	@override String get versionQualityButton => 'Versione e qualità';
	@override String get versionColumnHeader => 'Versione';
	@override String get qualityColumnHeader => 'Qualità';
	@override String get qualityOriginal => 'Originale';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodifica non disponibile — riproduzione in qualità originale';
	@override String get subtitleUnavailableFallback => 'Impossibile caricare i sottotitoli selezionati — la riproduzione continua senza sottotitoli';
	@override String get pipButton => 'Modalità Picture-in-Picture';
	@override String get aspectRatioButton => 'Proporzioni';
	@override String get ambientLighting => 'Illuminazione ambientale';
	@override String get fullscreenButton => 'Attiva schermo intero';
	@override String get exitFullscreenButton => 'Esci da schermo intero';
	@override String get alwaysOnTopButton => 'Sempre in primo piano';
	@override String get rotationLockButton => 'Blocco rotazione';
	@override String get lockScreen => 'Blocca schermo';
	@override String get screenLockButton => 'Blocco schermo';
	@override String get longPressToUnlock => 'Premi a lungo per sbloccare';
	@override String get timelineSlider => 'Timeline video';
	@override String get volumeSlider => 'Livello volume';
	@override String endsAt({required Object time}) => 'Termina alle ${time}';
	@override String get pipActive => 'Riproduzione in Picture-in-Picture';
	@override String get pipFailed => 'Impossibile avviare la modalità Picture-in-Picture';
	@override String get screenshotSaved => 'Schermata salvata';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override late final _Translations$videoControls$pipErrors$it pipErrors = _Translations$videoControls$pipErrors$it._(_root);
	@override String get chapters => 'Capitoli';
	@override String get noChaptersAvailable => 'Nessun capitolo disponibile';
	@override String get queue => 'Coda';
	@override String get noQueueItems => 'Nessun elemento in coda';
	@override String get searchSubtitles => 'Cerca sottotitoli';
	@override String get language => 'Lingua';
	@override String get noSubtitlesFound => 'Nessun sottotitolo trovato';
	@override String get subtitleDownloaded => 'Sottotitolo scaricato';
	@override String get subtitleDownloadedNotApplied => 'Il sottotitolo è stato scaricato, ma non è stato possibile selezionarlo';
	@override String get subtitleDownloadFailed => 'Impossibile scaricare il sottotitolo';
	@override String get searchLanguages => 'Cerca lingue...';
}

// Path: messages
class _Translations$messages$it extends Translations$messages$en {
	_Translations$messages$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Segnato come visto';
	@override String get markedAsUnwatched => 'Segnato come non visto';
	@override String get markedAsWatchedOffline => 'Segnato come visto (verrà sincronizzato quando torni online)';
	@override String get markedAsUnwatchedOffline => 'Segnato come non visto (verrà sincronizzato quando torni online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Rimosso automaticamente: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: 'Rimosso automaticamente ${n} download già visto',
		other: 'Rimossi automaticamente ${n} download già visti',
	);
	@override String get removedFromContinueWatching => 'Rimosso da Continua a guardare';
	@override String errorLoading({required Object error}) => 'Errore: ${error}';
	@override String get streamInterrupted => 'La riproduzione si è interrotta. Premi Riproduci o vai a un altro punto per riprovare.';
	@override String get liveStreamInterrupted => 'La diretta si è interrotta. Premi Riproduci per riprovare.';
	@override String get fileInfoNotAvailable => 'Informazioni sul file non disponibili';
	@override String get playbackAuthenticationRequired => 'Accedi di nuovo al server multimediale per riprodurre questo elemento.';
	@override String get playbackServerUnavailable => 'Il server multimediale non è disponibile. Riprova più tardi.';
	@override String get playbackDataInvalid => 'Il server ha restituito informazioni di riproduzione non valide.';
	@override String get playbackCancelled => 'Riproduzione annullata.';
	@override String get playbackFailed => 'Impossibile avviare la riproduzione.';
	@override String errorLoadingFileInfo({required Object error}) => 'Errore durante il caricamento delle informazioni sul file: ${error}';
	@override String get errorLoadingSeries => 'Errore durante il caricamento della serie';
	@override String get musicNotSupported => 'La riproduzione musicale non è ancora supportata';
	@override String get noDescriptionAvailable => 'Nessuna descrizione disponibile';
	@override String get noProfilesAvailable => 'Nessun profilo disponibile';
	@override String get contactAdminForProfiles => 'Contatta l\'amministratore del server per aggiungere profili';
	@override String get unableToDetermineLibrarySection => 'Impossibile determinare la sezione della libreria per questo elemento';
	@override String get logsCleared => 'Log eliminati';
	@override String get logsCopied => 'Log copiati negli appunti';
	@override String get noLogsAvailable => 'Nessun log disponibile';
	@override String libraryScanning({required Object title}) => 'Scansione di "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Scansione della libreria avviata per "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Impossibile eseguire la scansione della libreria: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Aggiornamento dei metadati di "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Aggiornamento dei metadati avviato per "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Impossibile aggiornare i metadati: ${error}';
	@override String get logoutConfirm => 'Vuoi uscire dall\'account?';
	@override String get noSeasonsFound => 'Nessuna stagione trovata';
	@override String get seasonsLoadFailed => 'Impossibile caricare le stagioni';
	@override String get noEpisodesFound => 'Nessun episodio trovato nella prima stagione';
	@override String get noEpisodesFoundGeneral => 'Nessun episodio trovato';
	@override String get episodesLoadFailed => 'Impossibile caricare gli episodi';
	@override String get noResultsFound => 'Nessun risultato';
	@override String sleepTimerSet({required Object label}) => 'Timer di spegnimento impostato su ${label}';
	@override String get noItemsAvailable => 'Nessun elemento disponibile';
	@override String get failedToCreatePlayQueueNoItems => 'Impossibile creare una coda di riproduzione: nessun elemento';
	@override String failedPlayback({required Object action, required Object error}) => 'Impossibile eseguire l\'azione «${action}»: ${error}';
	@override String get switchingToCompatiblePlayer => 'Passaggio al lettore compatibile...';
	@override String get serverLimitTitle => 'Riproduzione non riuscita';
	@override String get serverLimitBody => 'Errore del server (HTTP 500). È probabile che un limite di banda o transcodifica abbia impedito questa sessione. Chiedi al proprietario di modificare il limite.';
	@override String get logsUploaded => 'Log caricati';
	@override String get logsUploadFailed => 'Impossibile caricare i log';
	@override String get logId => 'ID log';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$it extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get text => 'Testo';
	@override String get border => 'Bordo';
	@override String get background => 'Sfondo';
	@override String get fontSize => 'Dimensione carattere';
	@override String get textColor => 'Colore del testo';
	@override String get borderSize => 'Dimensione del bordo';
	@override String get borderColor => 'Colore del bordo';
	@override String get backgroundOpacity => 'Opacità dello sfondo';
	@override String get backgroundColor => 'Colore dello sfondo';
	@override String get position => 'Posizione';
	@override String get assOverride => 'Sovrascrittura ASS';
	@override String get overrideScale => 'Ridimensiona';
	@override String get overrideForce => 'Forza';
	@override String get overrideStrip => 'Rimuovi stile';
	@override String get positionTop => 'In alto';
	@override String get positionBottom => 'In basso';
	@override String get bold => 'Grassetto';
	@override String get italic => 'Corsivo';
	@override String get renderResolution => 'Risoluzione di rendering';
	@override String get renderResolutionScreen => 'Risoluzione dello schermo';
	@override String get renderResolutionVideo => 'Risoluzione del video';
}

// Path: mpvConfig
class _Translations$mpvConfig$it extends Translations$mpvConfig$en {
	_Translations$mpvConfig$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Impostazioni avanzate del lettore video';
	@override String get presets => 'Preset';
	@override String get noPresets => 'Nessun preset salvato';
	@override String get saveAsPreset => 'Salva come preset...';
	@override String get presetName => 'Nome preset';
	@override String get presetNameHint => 'Inserisci un nome per questo preset';
	@override String get loadPreset => 'Carica';
	@override String get deletePreset => 'Elimina';
	@override String get presetSaved => 'Preset salvato';
	@override String get presetLoaded => 'Preset caricato';
	@override String get presetDeleted => 'Preset eliminato';
	@override String get confirmDeletePreset => 'Sei sicuro di voler eliminare questo preset?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _Translations$dialog$it extends Translations$dialog$en {
	_Translations$dialog$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Conferma azione';
}

// Path: profiles
class _Translations$profiles$it extends Translations$profiles$en {
	_Translations$profiles$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Aggiungi profilo Plezy';
	@override String get switchingProfile => 'Cambio profilo…';
	@override String get deleteThisProfileTitle => 'Eliminare questo profilo?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Rimuovi ${displayName}. Le connessioni resteranno invariate.';
	@override String get active => 'Attivo';
	@override String get manage => 'Gestisci';
	@override String get delete => 'Elimina';
	@override String get signOut => 'Esci';
	@override String get signOutPlexTitle => 'Uscire da Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Verranno rimossi ${displayName} e tutti gli utenti Plex Home. Potrai accedere di nuovo in qualsiasi momento.';
	@override String get signedOutPlex => 'Disconnessione da Plex completata.';
	@override String get signOutFailed => 'Disconnessione non riuscita.';
	@override String get sectionTitle => 'Profili';
	@override String get summarySingle => 'Aggiungi profili per combinare utenti gestiti e identità locali';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profili · attivo: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profili';
	@override String get removeConnectionTitle => 'Rimuovere la connessione?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Rimuovi da ${displayName} l\'accesso a ${connectionLabel}. Gli altri profili continueranno ad avervi accesso.';
	@override String get deleteProfileTitle => 'Eliminare il profilo?';
	@override String deleteProfileMessage({required Object displayName}) => 'Rimuovi ${displayName} e le relative connessioni. I server resteranno disponibili.';
	@override String get profileNameLabel => 'Nome profilo';
	@override String get pinProtectionLabel => 'Protezione PIN';
	@override String get pinManagedByPlex => 'PIN gestito da Plex. Modifica su plex.tv.';
	@override String get noPinSetEditOnPlex => 'Nessun PIN impostato. Per richiederne uno, modifica l\'utente Home su plex.tv.';
	@override String get setPin => 'Imposta PIN';
	@override String get setPinTitle => 'Imposta PIN';
	@override String get confirmPinTitle => 'Conferma PIN';
	@override String get pinSet => 'PIN impostato';
	@override String get changePin => 'Cambia';
	@override String get removePin => 'Rimuovi';
	@override String get connectionsLabel => 'Connessioni';
	@override String get add => 'Aggiungi';
	@override String get deleteProfileButton => 'Elimina profilo';
	@override String get noConnectionsHint => 'Nessuna connessione — aggiungine una per usare questo profilo.';
	@override String get noConnections => 'Nessuna connessione';
	@override String get plexHomeAccount => 'Account Plex Home';
	@override String get connectionDefault => 'Predefinita';
	@override String connectionAs({required Object displayName}) => 'come ${displayName}';
	@override String get makeDefault => 'Imposta come predefinita';
	@override String get removeConnection => 'Rimuovi';
	@override String get profileRenamed => 'Profilo rinominato.';
	@override String borrowAddTo({required Object displayName}) => 'Aggiungi a ${displayName}';
	@override String get borrowExplain => 'Prendi in prestito la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.';
	@override String get borrowEmpty => 'Nulla da prendere in prestito al momento.';
	@override String get borrowEmptySubtitle => 'Collega prima Plex o Jellyfin a un altro profilo.';
	@override String get borrowLoadFailed => 'Impossibile caricare le connessioni disponibili. Riprova.';
	@override String borrowFromProfile({required Object displayName}) => 'Da ${displayName}';
	@override String get borrowConnectionBorrowed => 'Connessione presa in prestito.';
	@override String get borrowFailed => 'Impossibile prendere in prestito la connessione.';
	@override String get incorrectPin => 'PIN errato.';
	@override String get incorrectPinTryAgain => 'PIN errato. Riprova.';
	@override String get sourceProfileMissingParentAccount => 'Al profilo di origine manca l\'account principale.';
	@override String get failedToLoadHomeUsers => 'Impossibile caricare gli utenti Plex Home. Controlla la connessione e riprova.';
	@override String get failedToVerifyPin => 'Impossibile verificare il PIN.';
	@override String get newProfile => 'Nuovo profilo';
	@override String get profileNameHint => 'es. Ospiti, Bambini, Soggiorno';
	@override String get pinProtectionOptional => 'Protezione PIN (opzionale)';
	@override String get pinExplain => 'PIN a 4 cifre richiesto per cambiare profilo.';
	@override String get continueButton => 'Continua';
	@override String get pinsDontMatch => 'I PIN non corrispondono';
}

// Path: connections
class _Translations$connections$it extends Translations$connections$en {
	_Translations$connections$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Connessioni';
	@override String get addConnection => 'Aggiungi connessione';
	@override String get addConnectionSubtitleNoProfile => 'Accedi con Plex o collega un server Jellyfin';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Aggiungi a ${displayName}: Plex, Jellyfin o la connessione di un altro profilo';
	@override String sessionExpiredOne({required Object name}) => 'Sessione scaduta per ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sessione scaduta per ${count} server';
	@override String get signInAgain => 'Accedi di nuovo';
	@override String get editJellyfinTitle => 'Modifica connessione Jellyfin';
	@override String editJellyfinIntro({required Object serverName}) => 'Aggiungi o rimuovi URL per ${serverName}. Plezy userà l\'URL raggiungibile con la latenza più bassa.';
}

// Path: discover
class _Translations$discover$it extends Translations$discover$en {
	_Translations$discover$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esplora';
	@override String get noContentAvailable => 'Nessun contenuto disponibile';
	@override String get addMediaToLibraries => 'Aggiungi contenuti multimediali alle tue librerie';
	@override String get continueWatching => 'Continua a guardare';
	@override String continueWatchingIn({required Object library}) => 'Continua a guardare in ${library}';
	@override String get nextUp => 'Prossimi episodi';
	@override String nextUpIn({required Object library}) => 'Prossimi episodi in ${library}';
	@override String get recentlyAdded => 'Aggiunti di recente';
	@override String recentlyAddedIn({required Object library}) => 'Aggiunti di recente in ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Ultimi album in ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Riprodotti di recente in ${library}';
	@override String mostPlayedIn({required Object library}) => 'Più riprodotti in ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Panoramica';
	@override String get cast => 'Attori';
	@override String get extras => 'Trailer ed extra';
	@override String get studio => 'Studio';
	@override String get rating => 'Valutazione';
	@override String get director => 'Regista';
	@override String get directors => 'Registi';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} minuti rimanenti';
	@override String get moreLikeThis => 'Altri contenuti simili';
}

// Path: errors
class _Translations$errors$it extends Translations$errors$en {
	_Translations$errors$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Ricerca non riuscita: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tempo scaduto per la connessione durante il caricamento di ${context}';
	@override String get connectionFailed => 'Impossibile connettersi al server multimediale';
	@override String unableToLoad({required Object context}) => 'Impossibile caricare ${context}. Riprova.';
	@override String get noClientAvailable => 'Nessun client disponibile';
	@override String get pleaseEnterToken => 'Inserisci un token';
	@override String get invalidToken => 'Token non valido';
	@override String failedToVerifyToken({required Object error}) => 'Impossibile verificare il token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossibile passare a ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Impossibile eliminare ${displayName}';
	@override String get failedToRate => 'Impossibile aggiornare la valutazione';
}

// Path: libraries
class _Translations$libraries$it extends Translations$libraries$en {
	_Translations$libraries$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Librerie';
	@override String get fallbackTitle => 'Libreria';
	@override String get scanLibraryFiles => 'Scansiona i file della libreria';
	@override String get scanLibrary => 'Scansiona libreria';
	@override String get analyze => 'Analizza';
	@override String get analyzeLibrary => 'Analizza libreria';
	@override String get refreshMetadata => 'Aggiorna metadati';
	@override String get emptyTrash => 'Svuota cestino';
	@override String emptyingTrash({required Object title}) => 'Svuotamento del cestino di "${title}"...';
	@override String trashEmptied({required Object title}) => 'Cestino di "${title}" svuotato';
	@override String failedToEmptyTrash({required Object error}) => 'Impossibile svuotare il cestino: ${error}';
	@override String analyzing({required Object title}) => 'Analisi di "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analisi avviata per "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Impossibile analizzare la libreria: ${error}';
	@override String get noLibrariesFound => 'Nessuna libreria trovata';
	@override String get allLibrariesHidden => 'Tutte le librerie sono nascoste';
	@override String hiddenLibrariesCount({required Object count}) => 'Librerie nascoste (${count})';
	@override String get thisLibraryIsEmpty => 'Questa libreria è vuota';
	@override String get noItemsMatchFilters => 'Nessun elemento corrisponde ai filtri attivi';
	@override String get resetFilters => 'Reimposta filtri';
	@override String get all => 'Tutto';
	@override String get clearAll => 'Azzera tutto';
	@override String scanLibraryConfirm({required Object title}) => 'Vuoi scansionare "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Vuoi analizzare "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Vuoi aggiornare i metadati di "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Vuoi svuotare il cestino di "${title}"?';
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
	@override late final _Translations$libraries$tabs$it tabs = _Translations$libraries$tabs$it._(_root);
	@override late final _Translations$libraries$groupings$it groupings = _Translations$libraries$groupings$it._(_root);
	@override late final _Translations$libraries$filterCategories$it filterCategories = _Translations$libraries$filterCategories$it._(_root);
	@override late final _Translations$libraries$sortLabels$it sortLabels = _Translations$libraries$sortLabels$it._(_root);
}

// Path: about
class _Translations$about$it extends Translations$about$en {
	_Translations$about$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informazioni';
	@override String get openSourceLicenses => 'Licenze open source';
	@override String versionLabel({required Object version}) => 'Versione ${version}';
	@override String get appDescription => 'Un elegante client Plex e Jellyfin per Flutter';
	@override String get viewLicensesDescription => 'Visualizza le licenze delle librerie di terze parti';
}

// Path: serverSelection
class _Translations$serverSelection$it extends Translations$serverSelection$en {
	_Translations$serverSelection$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Impossibile caricare i server: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$it extends Translations$hubDetail$en {
	_Translations$hubDetail$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titolo';
	@override String get releaseYear => 'Anno di uscita';
	@override String get dateAdded => 'Data di aggiunta';
	@override String get rating => 'Valutazione';
	@override String get noItemsFound => 'Nessun elemento trovato';
}

// Path: logs
class _Translations$logs$it extends Translations$logs$en {
	_Translations$logs$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Cancella log';
	@override String get copyLogs => 'Copia log';
	@override String get uploadLogs => 'Carica log';
}

// Path: licenses
class _Translations$licenses$it extends Translations$licenses$en {
	_Translations$licenses$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacchetti correlati';
	@override String get license => 'Licenza';
	@override String licenseNumber({required Object number}) => 'Licenza ${number}';
	@override String licensesCount({required Object count}) => '${count} licenze';
}

// Path: navigation
class _Translations$navigation$it extends Translations$navigation$en {
	_Translations$navigation$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Librerie';
	@override String get downloads => 'Download';
	@override String get liveTv => 'TV in diretta';
	@override String get explore => 'Esplora';
}

// Path: explore
class _Translations$explore$it extends Translations$explore$en {
	_Translations$explore$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esplora';
	@override String get selectSource => 'Seleziona fonte';
	@override late final _Translations$explore$rows$it rows = _Translations$explore$rows$it._(_root);
	@override late final _Translations$explore$status$it status = _Translations$explore$status$it._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${n} episodio',
		other: '${n} episodi',
	);
	@override String get cast => 'Attori';
	@override String get characters => 'Personaggi';
	@override String get addToWatchlist => 'Aggiungi alla lista da guardare';
	@override String get removeFromWatchlist => 'Rimuovi dalla lista da guardare';
	@override String get watchlistUpdateFailed => 'Impossibile aggiornare la lista da guardare';
	@override String get notInLibrary => 'Non è nella tua libreria';
	@override String get inTheseLibraries => 'In queste librerie';
	@override String get checkingLibrary => 'Ricerca nella tua libreria...';
	@override String get emptyTitle => 'Ancora niente qui';
	@override String emptyMessage({required Object source}) => 'Le sezioni di ${source} appariranno qui quando saranno disponibili dei contenuti.';
	@override String searchHint({required Object source}) => 'Cerca su ${source}';
	@override String searchEmpty({required Object query}) => 'Nessun risultato per "${query}"';
	@override String searchPrompt({required Object source}) => 'Cerca film e serie TV su ${source}.';
	@override String get searchFailed => 'Ricerca fallita. Controlla la connessione e riprova.';
}

// Path: liveTv
class _Translations$liveTv$it extends Translations$liveTv$en {
	_Translations$liveTv$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV in diretta';
	@override String get guide => 'Guida';
	@override String get noChannels => 'Nessun canale disponibile';
	@override String get noDvr => 'Nessun DVR configurato su alcun server';
	@override String get serverUnavailable => 'Il server TV in diretta non è disponibile.';
	@override String get serverNotConnected => 'Il server TV in diretta non è connesso.';
	@override String get noPrograms => 'Nessun dato di programma disponibile';
	@override String get liveStreamFailed => 'Streaming in diretta non riuscito';
	@override String get unknownProgram => 'Programma sconosciuto';
	@override String get unknownHub => 'Sconosciuto';
	@override String get unknownError => 'Errore sconosciuto';
	@override String channelNumber({required Object number}) => 'Canale ${number}';
	@override String get unknownChannel => 'Canale sconosciuto';
	@override String get live => 'IN DIRETTA';
	@override String get reloadGuide => 'Ricarica la guida';
	@override String get now => 'Ora';
	@override String get today => 'Oggi';
	@override String get tomorrow => 'Domani';
	@override String get midnight => 'Mezzanotte';
	@override String get overnight => 'Durante la notte';
	@override String get morning => 'Mattina';
	@override String get daytime => 'Giornata';
	@override String get evening => 'Sera';
	@override String get lateNight => 'Tarda notte';
	@override String get whatsOn => 'In onda ora';
	@override String get watchChannel => 'Guarda il canale';
	@override String get favorites => 'Preferiti';
	@override String get reorderFavorites => 'Riordina i preferiti';
	@override String get favoritesLoadFailed => 'Impossibile caricare i preferiti. Controlla la connessione e riprova.';
	@override String get favoritesUpdateFailed => 'Impossibile aggiornare i preferiti. Controlla la connessione e riprova.';
	@override String get joinSession => 'Partecipa alla sessione in corso';
	@override String watchFromStart({required Object minutes}) => 'Guarda dall\'inizio (${minutes} min fa)';
	@override String get watchLive => 'Guarda in diretta';
	@override String get goToLive => 'Vai alla diretta';
	@override String get record => 'Registra';
	@override String get recordEpisode => 'Registra episodio';
	@override String get recordSeries => 'Registra serie';
	@override String get recordOptions => 'Opzioni di registrazione';
	@override String get saveTo => 'Salva in';
	@override String get recordings => 'Registrazioni';
	@override String get scheduledRecordings => 'Programmate';
	@override String get recordingRules => 'Regole di registrazione';
	@override String get noScheduledRecordings => 'Nessuna registrazione in programma';
	@override String get manageRecording => 'Gestisci registrazione';
	@override String get cancelRecording => 'Annulla registrazione';
	@override String get cancelRecordingTitle => 'Annullare questa registrazione?';
	@override String cancelRecordingMessage({required Object title}) => '${title} non sarà più registrato.';
	@override String get deleteRule => 'Elimina regola';
	@override String get deleteRuleTitle => 'Eliminare la regola di registrazione?';
	@override String deleteRuleMessage({required Object title}) => 'I prossimi episodi di ${title} non saranno registrati.';
	@override String get recordingScheduled => 'Registrazione programmata';
	@override String get alreadyScheduled => 'La registrazione di questo programma è già pianificata';
	@override String get dvrAdminRequired => 'Le impostazioni DVR richiedono un account amministratore';
	@override String get recordingFailed => 'Impossibile programmare la registrazione';
	@override String get recordingTargetMissing => 'Impossibile determinare la libreria di registrazione';
	@override String get recordNotAvailable => 'Registrazione non disponibile per questo programma';
	@override String get recordingCancelled => 'Registrazione annullata';
	@override String get recordingRuleDeleted => 'Regola di registrazione eliminata';
	@override String get processRecordingRules => 'Rielabora le regole';
	@override String get recordingInProgress => 'Registrazione in corso';
	@override String recordingsCount({required Object count}) => '${count} programmate';
	@override String get editRule => 'Modifica regola';
	@override String get editRuleAction => 'Modifica';
	@override String get recordingRuleUpdated => 'Regola di registrazione aggiornata';
	@override String get guideReloadRequested => 'Aggiornamento della guida richiesto';
	@override String get rulesProcessRequested => 'Rielaborazione delle regole richiesta';
	@override String get recordShow => 'Registra programma';
}

// Path: collections
class _Translations$collections$it extends Translations$collections$en {
	_Translations$collections$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Raccolte';
	@override String get collection => 'Raccolta';
	@override String get empty => 'La raccolta è vuota';
	@override String get deleteCollection => 'Elimina raccolta';
	@override String deleteConfirm({required Object title}) => 'Eliminare "${title}"? Non si può annullare.';
	@override String get deleted => 'Raccolta eliminata';
	@override String get deleteFailed => 'Impossibile eliminare la raccolta';
	@override String deleteFailedWithError({required Object error}) => 'Impossibile eliminare la raccolta: ${error}';
	@override String get selectCollection => 'Seleziona raccolta';
	@override String get collectionName => 'Nome raccolta';
	@override String get enterCollectionName => 'Inserisci nome raccolta';
	@override String get addedToCollection => 'Elemento aggiunto alla raccolta';
	@override String get errorAddingToCollection => 'Impossibile aggiungere l\'elemento alla raccolta';
	@override String get created => 'Raccolta creata';
	@override String get removeFromCollection => 'Rimuovi dalla raccolta';
	@override String removeFromCollectionConfirm({required Object title}) => 'Rimuovere "${title}" da questa raccolta?';
	@override String get removedFromCollection => 'Elemento rimosso dalla raccolta';
	@override String get removeFromCollectionFailed => 'Impossibile rimuovere dalla raccolta';
	@override String removeFromCollectionError({required Object error}) => 'Errore durante la rimozione dell\'elemento dalla raccolta: ${error}';
	@override String get searchCollections => 'Cerca raccolte...';
}

// Path: playlists
class _Translations$playlists$it extends Translations$playlists$en {
	_Translations$playlists$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlist';
	@override String get playlist => 'Playlist';
	@override String get noPlaylists => 'Nessuna playlist trovata';
	@override String get create => 'Crea playlist';
	@override String get playlistName => 'Nome playlist';
	@override String get enterPlaylistName => 'Inserisci nome playlist';
	@override String get delete => 'Elimina playlist';
	@override String get removeItem => 'Rimuovi dalla playlist';
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
	@override String get searchPlaylists => 'Cerca playlist...';
	@override String get errorCreating => 'Impossibile creare la playlist';
	@override String get errorDeleting => 'Impossibile eliminare la playlist';
	@override String get errorLoading => 'Impossibile caricare le playlist';
	@override String get errorAdding => 'Impossibile aggiungere l\'elemento alla playlist';
	@override String get errorReordering => 'Impossibile riordinare l\'elemento della playlist';
	@override String get errorRemoving => 'Impossibile rimuovere l\'elemento dalla playlist';
}

// Path: music
class _Translations$music$it extends Translations$music$en {
	_Translations$music$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Vai all\'album';
	@override String get goToArtist => 'Vai all\'artista';
	@override String get instantMix => 'Mix istantaneo';
	@override String get playNext => 'Riproduci come prossimo';
	@override String get addToQueue => 'Aggiungi alla coda';
	@override String discNumber({required Object n}) => 'Disco ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${n} brano',
		other: '${n} brani',
	);
	@override String get nowPlaying => 'In riproduzione';
	@override String playingFrom({required Object title}) => 'Riproduzione da ${title}';
	@override String get queue => 'Coda';
	@override String get clearQueue => 'Svuota la coda';
	@override String get lyrics => 'Testo';
	@override String get noLyrics => 'Nessun testo disponibile';
	@override String get sleepTimer => 'Timer di spegnimento';
	@override String get sleepTimerEndOfTrack => 'Fine del brano';
	@override String sleepTimerMinutes({required Object n}) => '${n} minuti';
	@override String get stopPlayback => 'Interrompi riproduzione';
	@override String get previousTrack => 'Brano precedente';
	@override String get nextTrack => 'Brano successivo';
	@override String get repeat => 'Ripeti';
	@override String get repeatAll => 'Ripeti tutto';
	@override String get repeatOne => 'Ripeti il brano';
}

// Path: watchTogether
class _Translations$watchTogether$it extends Translations$watchTogether$en {
	_Translations$watchTogether$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guarda insieme';
	@override String get description => 'Guarda contenuti in sincronia con amici e familiari';
	@override String get createSession => 'Crea sessione';
	@override String get creating => 'Creazione...';
	@override String get joinSession => 'Partecipa a una sessione';
	@override String get joining => 'Connessione...';
	@override String get controlMode => 'Modalità di controllo';
	@override String get controlModeQuestion => 'Chi può controllare la riproduzione?';
	@override String get hostOnly => 'Solo l\'host';
	@override String get anyone => 'Tutti';
	@override String get hostingSession => 'Stai ospitando la sessione';
	@override String get inSession => 'Sessione in corso';
	@override String get sessionCode => 'Codice della sessione';
	@override String get openSessionControls => 'Apri i controlli della sessione di Guarda insieme';
	@override String get copySessionCode => 'Copia il codice della sessione';
	@override String get hostControlsPlayback => 'L\'host controlla la riproduzione';
	@override String get anyoneCanControl => 'Tutti possono controllare la riproduzione';
	@override String get hostControls => 'L\'host controlla';
	@override String get anyoneControls => 'Tutti possono controllare';
	@override String get participants => 'Partecipanti';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Sei l\'host';
	@override String get watchingWithOthers => 'In visione con altri partecipanti';
	@override String get endSession => 'Termina la sessione';
	@override String get leaveSession => 'Abbandona la sessione';
	@override String get endSessionQuestion => 'Terminare la sessione?';
	@override String get leaveSessionQuestion => 'Abbandonare la sessione?';
	@override String get endSessionConfirm => 'Questo terminerà la sessione per tutti i partecipanti.';
	@override String get leaveSessionConfirm => 'Sarai rimosso dalla sessione.';
	@override String get endSessionConfirmOverlay => 'Questo terminerà la sessione di visione per tutti i partecipanti.';
	@override String get leaveSessionConfirmOverlay => 'Sarai disconnesso dalla sessione di visione.';
	@override String get end => 'Termina';
	@override String get leave => 'Abbandona';
	@override String get syncing => 'Sincronizzazione...';
	@override String get joinWatchSession => 'Partecipa alla sessione di visione';
	@override String get enterCodeHint => 'Inserisci codice di 5 caratteri';
	@override String get pasteFromClipboard => 'Incolla dagli appunti';
	@override String get pleaseEnterCode => 'Inserisci un codice della sessione';
	@override String get codeMustBe5Chars => 'Il codice della sessione deve contenere 5 caratteri';
	@override String get joinInstructions => 'Inserisci il codice della sessione dell\'host per partecipare.';
	@override String get failedToCreate => 'Impossibile creare la sessione';
	@override String get failedToJoin => 'Impossibile unirsi alla sessione';
	@override String get sessionCodeCopied => 'Codice della sessione copiato negli appunti';
	@override String get relayUnreachable => 'Il server relay non è raggiungibile. Eventuali blocchi dell\'ISP potrebbero impedire l\'uso di Guarda insieme.';
	@override String get reconnectingToHost => 'Riconnessione all\'host...';
	@override String get currentPlayback => 'Riproduzione corrente';
	@override String get joinCurrentPlayback => 'Unisciti alla riproduzione corrente';
	@override String get joinCurrentPlaybackDescription => 'Torna a ciò che l\'host sta guardando in questo momento';
	@override String get failedToOpenCurrentPlayback => 'Impossibile aprire la riproduzione corrente';
	@override String participantJoined({required Object name}) => '${name} si è unito';
	@override String participantLeft({required Object name}) => '${name} se ne è andato';
	@override String participantPaused({required Object name}) => '${name} ha messo in pausa';
	@override String participantResumed({required Object name}) => '${name} ha ripreso';
	@override String participantSeeked({required Object name}) => '${name} ha cambiato la posizione di riproduzione';
	@override String participantBuffering({required Object name}) => '${name} è in buffering';
	@override String participantNeedsUpdate({required Object name}) => '${name} usa una versione precedente dell\'app — sincronizzazione non disponibile';
	@override String resumingWithout({required Object name}) => 'Ripresa senza ${name}';
	@override String get waitingForParticipants => 'In attesa che gli altri carichino...';
	@override String waitingForName({required Object name}) => 'In attesa di ${name}...';
	@override String get recentRooms => 'Stanze usate di recente';
	@override String get renameRoom => 'Rinomina stanza';
	@override String get removeRoom => 'Rimuovi';
	@override String get guestSwitchUnavailable => 'Impossibile cambiare — server non disponibile per la sincronizzazione';
	@override String get guestSwitchFailed => 'Impossibile cambiare — contenuto non trovato su questo server';
}

// Path: downloads
class _Translations$downloads$it extends Translations$downloads$en {
	_Translations$downloads$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Download';
	@override String get manage => 'Gestisci';
	@override String get tvShows => 'Serie TV';
	@override String get movies => 'Film';
	@override String get music => 'Musica';
	@override String tracksQueued({required Object count}) => '${count} brani in coda per il download';
	@override String get noDownloads => 'Ancora nessun download';
	@override String get noDownloadsDescription => 'I contenuti scaricati appariranno qui per la visualizzazione offline';
	@override String get downloadNow => 'Scarica';
	@override String get deleteDownload => 'Elimina il download';
	@override String get retryDownload => 'Riprova il download';
	@override String get downloadQueued => 'Download in coda';
	@override String get downloadResumed => 'Download ripreso';
	@override String get serverErrorBitrate => 'Errore server: il file può superare il limite di bitrate remoto';
	@override String get storageFull => 'I download sono stati interrotti perché lo spazio di archiviazione del dispositivo è esaurito. Libera spazio e riprova.';
	@override String episodesQueued({required Object count}) => '${count} episodi in coda per il download';
	@override String get downloadDeleted => 'Download eliminato';
	@override String deleteConfirm({required Object title}) => 'Eliminare "${title}" da questo dispositivo?';
	@override String get cancelledDownloadTitle => 'Download annullato';
	@override String get cancelledDownloadMessage => 'Questo download è stato annullato. Cosa vuoi fare?';
	@override String get allEpisodesAlreadyDownloaded => 'Tutti gli episodi sono già stati scaricati';
	@override String get resumeDownload => 'Riprendi il download';
	@override String get cancelledDownload => 'Download annullato';
	@override String syncingFile({required Object file, required Object status}) => '${file} (sincronizzazione ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} scaricato — fai clic per completare';
	@override String get partialDownloadClickToComplete => 'Scaricato parzialmente — fai clic per completare';
	@override String get deleting => 'Eliminazione...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Eliminazione di ${title}... (${current} di ${total})';
	@override String get queuedTooltip => 'In coda';
	@override String queuedFilesTooltip({required Object files}) => 'In coda: ${files}';
	@override String get downloadingTooltip => 'Download in corso...';
	@override String downloadingFilesTooltip({required Object files}) => 'Download di ${files}';
	@override String get noDownloadsTree => 'Nessun download';
	@override String get pauseAll => 'Metti tutto in pausa';
	@override String get resumeAll => 'Riprendi tutto';
	@override String get deleteAll => 'Elimina tutto';
	@override String get selectVersion => 'Seleziona la versione';
	@override String get allEpisodes => 'Tutti gli episodi';
	@override String get unwatchedOnly => 'Solo non visti';
	@override String nextNUnwatched({required Object count}) => 'Prossimi ${count} episodi non visti';
	@override String get customAmount => 'Quantità personalizzata...';
	@override String get includeSpecials => 'Includi gli speciali';
	@override String get howManyEpisodes => 'Quanti episodi?';
	@override String get invalidEpisodeCount => 'Inserisci un numero di episodi valido.';
	@override String get keepSynced => 'Mantieni sincronizzato';
	@override String get downloadOnce => 'Scarica una volta';
	@override String keepNUnwatched({required Object count}) => 'Mantieni ${count} episodi non visti';
	@override String get editSyncRule => 'Modifica regola di sincronizzazione';
	@override String get removeSyncRule => 'Rimuovi regola di sincronizzazione';
	@override String removeSyncRuleConfirm({required Object title}) => 'Interrompere la sincronizzazione di "${title}"? Gli episodi scaricati verranno mantenuti.';
	@override String syncRuleCreated({required Object count}) => 'Regola di sincronizzazione creata — ${count} episodi non visti mantenuti';
	@override String get syncRuleUpdated => 'Regola di sincronizzazione aggiornata';
	@override String get syncRuleRemoved => 'Regola di sincronizzazione rimossa';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} nuovi episodi sincronizzati per ${title}';
	@override String get activeSyncRules => 'Regole di sincronizzazione';
	@override String get noSyncRules => 'Nessuna regola di sincronizzazione';
	@override String get manageSyncRule => 'Gestisci sincronizzazione';
	@override String get editEpisodeCount => 'Numero di episodi';
	@override String get editSyncFilter => 'Filtro di sincronizzazione';
	@override String get syncAllItems => 'Sincronizzazione di tutti gli elementi';
	@override String get syncUnwatchedItems => 'Sincronizzazione degli elementi non visti';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponibile';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'Accesso richiesto';
	@override String get syncRuleNotAvailableForProfile => 'Non disponibile per il profilo attuale';
	@override String get syncRuleUnknownServer => 'Server sconosciuto';
	@override String get syncRuleListCreated => 'Regola di sincronizzazione creata';
	@override late final _Translations$downloads$backgroundWarning$it backgroundWarning = _Translations$downloads$backgroundWarning$it._(_root);
}

// Path: shaders
class _Translations$shaders$it extends Translations$shaders$en {
	_Translations$shaders$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shader';
	@override String get noShaderDescription => 'Nessun miglioramento video';
	@override String get nvscalerDescription => 'Ridimensionamento NVIDIA per video più nitido';
	@override String get artcnnVariantNeutral => 'Neutro';
	@override String get artcnnVariantDenoise => 'Riduzione rumore';
	@override String get artcnnVariantDenoiseSharpen => 'Riduzione rumore + nitidezza';
	@override String get qualityFast => 'Veloce';
	@override String get qualityHQ => 'Alta qualità';
	@override String get mode => 'Modalità';
	@override String get importShader => 'Importa shader';
	@override String get customShaderDescription => 'Shader GLSL personalizzato';
	@override String get shaderImported => 'Shader importato';
	@override String get shaderImportFailed => 'Impossibile importare lo shader';
	@override String get deleteShader => 'Elimina shader';
	@override String deleteShaderConfirm({required Object name}) => 'Eliminare "${name}"?';
}

// Path: companionRemote
class _Translations$companionRemote$it extends Translations$companionRemote$en {
	_Translations$companionRemote$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Telecomando';
	@override String connectedTo({required Object name}) => 'Connesso a ${name}';
	@override String get unknownDevice => 'Dispositivo sconosciuto';
	@override late final _Translations$companionRemote$session$it session = _Translations$companionRemote$session$it._(_root);
	@override late final _Translations$companionRemote$pairing$it pairing = _Translations$companionRemote$pairing$it._(_root);
	@override late final _Translations$companionRemote$remote$it remote = _Translations$companionRemote$remote$it._(_root);
	@override late final _Translations$companionRemote$errors$it errors = _Translations$companionRemote$errors$it._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$it extends Translations$videoSettings$en {
	_Translations$videoSettings$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocità di riproduzione';
	@override String get normalSpeed => 'Normale';
	@override String sleepTimerActive({required Object duration}) => 'Attivo (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Timer di spegnimento';
	@override String get audioSync => 'Sincronizzazione audio';
	@override String get subtitleSync => 'Sincronizzazione sottotitoli';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Uscita audio';
	@override String get performanceOverlay => 'Overlay prestazioni';
	@override String get audioPassthrough => 'Passthrough audio';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Audio spaziale';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioNormalization => 'Normalizza il volume';
	@override String get audioDownmix => 'Downmix in stereo';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$it extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get color => 'Colore';
	@override String get performance => 'Prestazioni';
	@override String get buffer => 'Buffer';
	@override String get app => 'App';
	@override String get decoder => 'Decoder';
	@override String get rawDecoder => 'Decoder raw';
	@override String get tunneling => 'Tunneling';
	@override String get aspect => 'Proporzioni';
	@override String get rotation => 'Rotazione';
	@override String get dvSource => 'Sorgente DV';
	@override String get dvPath => 'Percorso DV';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Frequenza camp.';
	@override String get pixelFormat => 'Formato pixel';
	@override String get hwFormat => 'Formato HW';
	@override String get matrix => 'Matrice';
	@override String get primaries => 'Colori primari';
	@override String get transfer => 'Trasferimento';
	@override String get renderFps => 'FPS rendering';
	@override String get displayFps => 'FPS display';
	@override String get avSync => 'Sync A/V';
	@override String get dropped => 'Scartati';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'Media DV RPU';
	@override String get dvSampleAverage => 'Media camp. DV';
	@override String get maxLuma => 'Luma max';
	@override String get minLuma => 'Luma min';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache usata';
	@override String get cacheLimit => 'Limite cache';
	@override String get speed => 'Velocità';
	@override String get player => 'Lettore';
	@override String get memory => 'Memoria';
	@override String get uiFps => 'FPS UI';
}

// Path: externalPlayer
class _Translations$externalPlayer$it extends Translations$externalPlayer$en {
	_Translations$externalPlayer$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lettore esterno';
	@override String get useExternalPlayer => 'Usa un lettore esterno';
	@override String get useExternalPlayerDescription => 'Apri i video in un\'altra app';
	@override String get selectPlayer => 'Seleziona il lettore';
	@override String get customPlayers => 'Lettori personalizzati';
	@override String get systemDefault => 'Predefinito di sistema';
	@override String get addCustomPlayer => 'Aggiungi lettore personalizzato';
	@override String get playerName => 'Nome del lettore';
	@override String get playerNameHint => 'Il mio lettore';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nome pacchetto';
	@override String get playerUrlScheme => 'Schema URL';
	@override String get off => 'Disattivato';
	@override String get launchFailed => 'Impossibile aprire il lettore esterno';
	@override String appNotInstalled({required Object name}) => '${name} non è installato';
	@override String get playInExternalPlayer => 'Riproduci nel lettore esterno';
}

// Path: metadataEdit
class _Translations$metadataEdit$it extends Translations$metadataEdit$en {
	_Translations$metadataEdit$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Modifica...';
	@override String get screenTitle => 'Modifica metadati';
	@override String get basicInfo => 'Informazioni di base';
	@override String get artwork => 'Immagini';
	@override String get advancedSettings => 'Impostazioni avanzate';
	@override String get title => 'Titolo';
	@override String get sortTitle => 'Titolo di ordinamento';
	@override String get originalTitle => 'Titolo originale';
	@override String get releaseDate => 'Data di uscita';
	@override String get contentRating => 'Classificazione per età';
	@override String get studio => 'Studio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Trama';
	@override String get poster => 'Poster';
	@override String get background => 'Sfondo';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Immagine quadrata';
	@override String get selectPoster => 'Seleziona poster';
	@override String get selectBackground => 'Seleziona sfondo';
	@override String get selectLogo => 'Seleziona logo';
	@override String get selectSquareArt => 'Seleziona immagine quadrata';
	@override String get fromUrl => 'Da URL';
	@override String get uploadFile => 'Carica file';
	@override String get enterImageUrl => 'Inserisci URL immagine';
	@override String get imageUrl => 'URL immagine';
	@override String get metadataUpdated => 'Metadati aggiornati correttamente';
	@override String get metadataUpdateFailed => 'Impossibile aggiornare i metadati';
	@override String get artworkUpdated => 'Immagini aggiornate';
	@override String get artworkUpdateFailed => 'Impossibile aggiornare le immagini';
	@override String get noArtworkAvailable => 'Nessuna immagine disponibile';
	@override String artworkOption({required Object index}) => 'Opzione immagine ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opzione immagine ${index}, selezionata';
	@override String get notSet => 'Non impostato';
	@override String get libraryDefault => 'Predefinito della libreria';
	@override String get accountDefault => 'Predefinito dell\'account';
	@override String get seriesDefault => 'Predefinito della serie';
	@override String get episodeSorting => 'Ordinamento episodi';
	@override String get oldestFirst => 'Più vecchi prima';
	@override String get newestFirst => 'Più recenti prima';
	@override String get keep => 'Conserva';
	@override String get allEpisodes => 'Tutti gli episodi';
	@override String latestEpisodes({required Object count}) => '${count} episodi più recenti';
	@override String get latestEpisode => 'Episodio più recente';
	@override String episodesAddedPastDays({required Object count}) => 'Episodi aggiunti negli ultimi ${count} giorni';
	@override String get deleteAfterPlaying => 'Elimina episodi dopo la riproduzione';
	@override String get never => 'Mai';
	@override String get afterADay => 'Dopo un giorno';
	@override String get afterAWeek => 'Dopo una settimana';
	@override String get afterAMonth => 'Dopo un mese';
	@override String get onNextRefresh => 'Al prossimo aggiornamento';
	@override String get seasons => 'Stagioni';
	@override String get show => 'Mostra';
	@override String get hide => 'Nascondi';
	@override String get episodeOrdering => 'Ordine episodi';
	@override String get tmdbAiring => 'The Movie Database (ordine di trasmissione)';
	@override String get tvdbAiring => 'TheTVDB (ordine di trasmissione)';
	@override String get tvdbAbsolute => 'TheTVDB (ordine assoluto)';
	@override String get metadataLanguage => 'Lingua dei metadati';
	@override String get useOriginalTitle => 'Usa il titolo originale';
	@override String get preferredAudioLanguage => 'Lingua audio preferita';
	@override String get preferredSubtitleLanguage => 'Lingua dei sottotitoli preferita';
	@override String get subtitleMode => 'Modalità di selezione automatica dei sottotitoli';
	@override String get manuallySelected => 'Selezionato manualmente';
	@override String get shownWithForeignAudio => 'Mostrati con audio straniero';
	@override String get alwaysEnabled => 'Sempre attivo';
	@override String get tags => 'Tag';
	@override String get addTag => 'Aggiungi tag';
	@override String get genre => 'Genere';
	@override String get director => 'Regista';
	@override String get writer => 'Sceneggiatore';
	@override String get producer => 'Produttore';
	@override String get country => 'Paese';
	@override String get collection => 'Raccolta';
	@override String get label => 'Etichetta';
	@override String get style => 'Stile';
	@override String get mood => 'Atmosfera';
}

// Path: matchScreen
class _Translations$matchScreen$it extends Translations$matchScreen$en {
	_Translations$matchScreen$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get match => 'Abbina...';
	@override String get fixMatch => 'Correggi abbinamento...';
	@override String get unmatch => 'Rimuovi abbinamento';
	@override String get unmatchConfirm => 'Rimuovere questo abbinamento? Plex considererà l\'elemento non abbinato finché non verrà eseguito un nuovo abbinamento.';
	@override String get unmatchSuccess => 'Abbinamento rimosso';
	@override String get unmatchFailed => 'Rimozione dell\'abbinamento non riuscita';
	@override String get matchApplied => 'Abbinamento applicato';
	@override String get matchFailed => 'Applicazione dell\'abbinamento non riuscita';
	@override String get titleHint => 'Titolo';
	@override String get yearHint => 'Anno';
	@override String get search => 'Cerca';
	@override String get noMatchesFound => 'Nessun risultato';
}

// Path: serverTasks
class _Translations$serverTasks$it extends Translations$serverTasks$en {
	_Translations$serverTasks$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Attività del server';
	@override String get failedToLoad => 'Impossibile caricare le attività';
	@override String get noTasks => 'Nessuna attività in corso';
}

// Path: trakt
class _Translations$trakt$it extends Translations$trakt$en {
	_Translations$trakt$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Connesso';
	@override String connectedAs({required Object username}) => 'Connesso come @${username}';
	@override String get disconnectConfirm => 'Disconnettere l\'account Trakt?';
	@override String get disconnectConfirmBody => 'Plezy smetterà di inviare eventi a Trakt. Puoi riconnetterti quando vuoi.';
	@override String get scrobble => 'Scrobbling in tempo reale';
	@override String get scrobbleDescription => 'Invia eventi di riproduzione, pausa e arresto a Trakt durante la riproduzione.';
	@override String get watchedSync => 'Sincronizza lo stato di visione';
	@override String get watchedSyncDescription => 'Quando contrassegni un elemento come visto in Plezy, viene contrassegnato come visto anche su Trakt.';
}

// Path: seerr
class _Translations$seerr$it extends Translations$seerr$en {
	_Translations$seerr$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Connetti Seerr';
	@override String get serverUrl => 'URL del server';
	@override String get serverUrlHelper => 'L\'indirizzo della tua istanza Seerr';
	@override String get checkServer => 'Continua';
	@override String get signInWithJellyfin => 'Accedi con Jellyfin';
	@override String get signInWithEmby => 'Accedi con Emby';
	@override String get signInWithLocal => 'Usa un account locale';
	@override String get email => 'Email';
	@override String get noSignInMethods => 'Questa istanza Seerr non offre alcun metodo di accesso supportato da Plezy.';
	@override String get instance => 'Istanza';
	@override String get disconnectConfirm => 'Disconnettere Seerr?';
	@override String get disconnectConfirmBody => 'Plezy rimuoverà questa istanza Seerr. Potrai riconnetterla in qualsiasi momento.';
	@override String get request => 'Richiedi';
	@override String get request4k => 'Richiedi in 4K';
	@override String get seasons => 'Stagioni';
	@override String get allSeasons => 'Tutte le stagioni';
	@override String get advancedOptions => 'Avanzate';
	@override String get destinationServer => 'Server di destinazione';
	@override String get qualityProfile => 'Profilo di qualità';
	@override String get rootFolder => 'Cartella radice';
	@override String get languageProfile => 'Profilo della lingua';
	@override String get requestSubmitted => 'Richiesta inviata';
	@override String requestFailed({required Object error}) => 'Richiesta non riuscita: ${error}';
	@override String get requestsLoadFailed => 'Impossibile caricare le opzioni di richiesta';
	@override String get nothingToRequest => 'Tutto è già disponibile o richiesto.';
	@override String get statusAvailable => 'Disponibile';
	@override String get statusPartiallyAvailable => 'Disponibile in parte';
	@override String get statusRequested => 'Richiesto';
	@override String get statusProcessing => 'In elaborazione';
}

// Path: services
class _Translations$services$it extends Translations$services$en {
	_Translations$services$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Servizi';
	@override String get hubSubtitle => 'Sincronizza i progressi di visione e richiedi nuovi titoli.';
	@override String get notConnected => 'Non connesso';
	@override String connectedAs({required Object username}) => 'Connesso come @${username}';
	@override String get scrobble => 'Registra automaticamente i progressi';
	@override String get scrobbleDescription => 'Aggiorna la tua lista quando termini un episodio o un film.';
	@override String disconnectConfirm({required Object service}) => 'Disconnettere ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy smetterà di aggiornare ${service}. Riconnetti quando vuoi.';
	@override String connectFailed({required Object service}) => 'Impossibile connettersi a ${service}. Riprova.';
	@override late final _Translations$services$names$it names = _Translations$services$names$it._(_root);
	@override late final _Translations$services$deviceCode$it deviceCode = _Translations$services$deviceCode$it._(_root);
	@override late final _Translations$services$oauthProxy$it oauthProxy = _Translations$services$oauthProxy$it._(_root);
	@override late final _Translations$services$libraryFilter$it libraryFilter = _Translations$services$libraryFilter$it._(_root);
}

// Path: addServer
class _Translations$addServer$it extends Translations$addServer$en {
	_Translations$addServer$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Aggiungi server Jellyfin';
	@override String get serverUrls => 'URL del server';
	@override String get serverUrlsHelper => 'Sono consentiti più URL, separati da virgole.';
	@override String get findServer => 'Trova il server';
	@override String get searchingLocalServers => 'Ricerca dei server Jellyfin locali...';
	@override String get localServers => 'Server Jellyfin locali';
	@override String get username => 'Nome utente';
	@override String get password => 'Password';
	@override String get signIn => 'Accedi';
	@override String get change => 'Modifica';
	@override String get required => 'Obbligatorio';
	@override String couldNotReachServer({required Object error}) => 'Impossibile raggiungere il server: ${error}';
	@override String signInFailed({required Object error}) => 'Accesso non riuscito: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect non riuscito: ${error}';
	@override String get addPlexTitle => 'Accedi con Plex';
	@override String get pinExpired => 'PIN scaduto prima dell\'accesso. Riprova.';
	@override String failedToRegisterAccount({required Object error}) => 'Registrazione account non riuscita: ${error}';
	@override String get enterJellyfinUrlError => 'Inserisci l\'URL del tuo server Jellyfin';
	@override String get addConnectionTitle => 'Aggiungi connessione';
	@override String addConnectionTitleScoped({required Object name}) => 'Aggiungi a ${name}';
	@override String get signInWithPlexCard => 'Accedi con Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorizza questo dispositivo. I server condivisi vengono aggiunti.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorizza un account Plex. Gli utenti Home diventano profili.';
	@override String get connectToJellyfinCard => 'Connettiti a Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Inserisci l\'URL del server, il nome utente e la password.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Accedi a un server Jellyfin. Verrà associato a ${name}.';
	@override String get borrowFromAnotherProfile => 'Prendi in prestito da un altro profilo';
	@override String get borrowFromAnotherProfileSubtitle => 'Riutilizza la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$it extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Riproduci/Pausa';
	@override String get volumeUp => 'Alza volume';
	@override String get volumeDown => 'Abbassa volume';
	@override String seekForward({required Object seconds}) => 'Avanti (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Indietro (${seconds}s)';
	@override String get fullscreenToggle => 'Attiva/disattiva schermo intero';
	@override String get muteToggle => 'Attiva/disattiva audio';
	@override String get subtitleToggle => 'Attiva/disattiva sottotitoli';
	@override String get audioTrackNext => 'Traccia audio successiva';
	@override String get subtitleTrackNext => 'Sottotitoli successivi';
	@override String get chapterNext => 'Capitolo successivo';
	@override String get chapterPrevious => 'Capitolo precedente';
	@override String get episodeNext => 'Episodio successivo';
	@override String get episodePrevious => 'Episodio precedente';
	@override String get speedIncrease => 'Aumenta velocità';
	@override String get speedDecrease => 'Diminuisci velocità';
	@override String get speedReset => 'Ripristina velocità';
	@override String get zoomIn => 'Aumenta zoom';
	@override String get zoomOut => 'Riduci zoom';
	@override String get zoomReset => 'Ripristina zoom';
	@override String get subSeekNext => 'Vai al sottotitolo successivo';
	@override String get subSeekPrev => 'Vai al sottotitolo precedente';
	@override String get shaderToggle => 'Attiva/disattiva shader';
	@override String get skipMarker => 'Salta intro/titoli di coda';
	@override String get screenshot => 'Cattura schermata';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$it extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Richiede Android 8.0 o versioni successive';
	@override String get iosVersion => 'Richiede iOS 15.0 o versioni successive';
	@override String get permissionDisabled => 'La modalità Picture-in-Picture è disattivata. Attivala nelle impostazioni di sistema.';
	@override String get notSupported => 'Questo dispositivo non supporta la modalità Picture-in-Picture';
	@override String get voSwitchFailed => 'Impossibile cambiare l\'uscita video per Picture-in-Picture';
	@override String get failed => 'Impossibile avviare la modalità Picture-in-Picture';
	@override String unknown({required Object error}) => 'Si è verificato un errore: ${error}';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$it extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Consigliati';
	@override String get browse => 'Esplora';
	@override String get collections => 'Raccolte';
	@override String get playlists => 'Playlist';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$it extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Raggruppa per';
	@override String get all => 'Tutti';
	@override String get movies => 'Film';
	@override String get shows => 'Serie TV';
	@override String get seasons => 'Stagioni';
	@override String get episodes => 'Episodi';
	@override String get artists => 'Artisti';
	@override String get albums => 'Album';
	@override String get tracks => 'Brani';
	@override String get folders => 'Cartelle';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$it extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Genere';
	@override String get year => 'Anno';
	@override String get contentRating => 'Classificazione per età';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Non visti';
	@override String get unplayed => 'Non riprodotti';
	@override String get favorites => 'Preferiti';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$it extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titolo';
	@override String get dateAdded => 'Data di aggiunta';
	@override String get releaseDate => 'Data di uscita';
	@override String get rating => 'Valutazione';
	@override String get communityRating => 'Valutazione della comunità';
	@override String get criticRating => 'Valutazione critica';
	@override String get userRating => 'Valutazione utente';
	@override String get datePlayed => 'Data di riproduzione';
	@override String get playCount => 'Riproduzioni';
	@override String get productionYear => 'Anno di produzione';
	@override String get runtime => 'Durata';
	@override String get officialRating => 'Classificazione ufficiale';
	@override String get premiereDate => 'Data di première';
	@override String get startDate => 'Data di inizio';
	@override String get airTime => 'Orario di messa in onda';
	@override String get studio => 'Studio';
	@override String get random => 'Casuale';
	@override String get dateShared => 'Data di condivisione';
	@override String get latestEpisodeAirDate => 'Data di trasmissione dell\'ultimo episodio';
	@override String get lastEpisodeDateAdded => 'Data di aggiunta dell\'ultimo episodio';
}

// Path: explore.rows
class _Translations$explore$rows$it extends Translations$explore$rows$en {
	_Translations$explore$rows$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Lista da guardare';
	@override String get recommendedMovies => 'Film consigliati';
	@override String get recommendedShows => 'Serie TV consigliate';
	@override String get trendingMovies => 'Film di tendenza';
	@override String get trendingShows => 'Serie TV di tendenza';
	@override String get popularMovies => 'Film popolari';
	@override String get popularShows => 'Serie TV popolari';
	@override String get trendingAnime => 'Anime di tendenza';
	@override String get suggestedAnime => 'Anime suggeriti';
	@override String get airingAnime => 'Migliori anime in onda';
	@override String get popularAnime => 'Anime più popolari';
	@override String get trending => 'Di tendenza';
	@override String get upcomingMovies => 'Film in arrivo';
	@override String get upcomingShows => 'Serie TV in arrivo';
}

// Path: explore.status
class _Translations$explore$status$it extends Translations$explore$status$en {
	_Translations$explore$status$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get airing => 'In onda';
	@override String get ended => 'Conclusa';
	@override String get canceled => 'Cancellata';
	@override String get upcoming => 'In arrivo';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$it extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'I download si interromperanno quando esci dall’app';
	@override String get bannerDegraded => 'I download in background potrebbero essere limitati';
	@override String get bannerAction => 'Dettagli';
	@override String get sheetTitle => 'I download in background sono bloccati';
	@override String get sheetTitleDegraded => 'I download in background potrebbero essere limitati';
	@override String get sheetIntro => 'Android impedisce a Plezy di scaricare in modo affidabile in background.';
	@override String get sheetIntroDegraded => 'Il dispositivo limita i momenti in cui Plezy può scaricare in background.';
	@override String get reasonBackgroundRestricted => 'L’uso in background di Plezy è limitato. Nelle impostazioni della batteria o dell’uso in background, seleziona «Senza restrizioni».';
	@override String get reasonStandbyRestricted => 'Android ha messo Plezy in uno stato di standby con restrizioni. Imposta l’uso della batteria su «Senza restrizioni».';
	@override String get reasonDownloadChannelBlocked => 'Le notifiche dei download sono disattivate, quindi l’avanzamento e i controlli potrebbero non essere disponibili.';
	@override String get reasonNotificationsDisabled => 'Le notifiche sono disattivate. Su Android 13 o versioni successive sono necessarie per i download prolungati in background.';
	@override String get reasonDataSaver => 'Il Risparmio dati è attivo e blocca i download in background tramite dati mobili. I download dovrebbero comunque funzionare su Wi-Fi.';
	@override String get reasonOemUnknown => 'I download si sono interrotti più volte mentre Plezy era in background. Controlla le impostazioni della batteria o dell’uso in background di Plezy.';
	@override String get openSettings => 'Apri le impostazioni';
	@override String get stillNotWorking => 'Guida specifica per il dispositivo';
	@override String get stillNotWorkingDescription => 'Consulta la procedura per il tuo dispositivo oppure invia un log da Impostazioni › Visualizza i log se il problema persiste.';
	@override String get dialogTitle => 'I download potrebbero non terminare';
	@override String get dialogDownloadAnyway => 'Scarica comunque';
	@override String get dialogFixFirst => 'Risolvi prima';
	@override String get statusTile => 'Download in background';
	@override String get statusOk => 'Esecuzione in background consentita';
	@override String get statusBlocked => 'Bloccati dalle impostazioni di sistema';
	@override String get statusDegraded => 'Limitati dalle impostazioni di sistema';
	@override String get statusUnknown => 'Non ancora verificato';
	@override String get settingsUnavailable => 'Impossibile aprire le impostazioni di sistema su questo dispositivo';
	@override String get linkUnavailable => 'Impossibile aprire dontkillmyapp.com su questo dispositivo';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$it extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Avvio del server remoto...';
	@override String get hostAddress => 'Indirizzo host';
	@override String get connected => 'Connesso';
	@override String get serverRunning => 'Server remoto attivo';
	@override String get serverStopped => 'Server remoto arrestato';
	@override String get serverRunningDescription => 'I dispositivi mobili della tua rete possono connettersi a questa app';
	@override String get serverStoppedDescription => 'Avvia il server per consentire ai dispositivi mobili di connettersi';
	@override String get usePhoneToControl => 'Usa il tuo dispositivo mobile per controllare questa app';
	@override String get startServer => 'Avvia server';
	@override String get stopServer => 'Arresta server';
	@override String get minimize => 'Riduci';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$it extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'I dispositivi Plezy con lo stesso account Plex appaiono qui';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Connessione...';
	@override String get searchingForDevices => 'Ricerca dispositivi...';
	@override String get noDevicesFound => 'Nessun dispositivo trovato nella tua rete';
	@override String get noDevicesHint => 'Apri Plezy sul computer e usa la stessa rete Wi-Fi';
	@override String get availableDevices => 'Dispositivi disponibili';
	@override String get manualConnection => 'Connessione manuale';
	@override String get cryptoInitFailed => 'Impossibile avviare la connessione sicura. Accedi prima a Plex.';
	@override String get validationHostRequired => 'Inserisci l\'indirizzo host';
	@override String get validationHostFormat => 'Il formato deve essere IP:porta (es. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tempo scaduto per la connessione. Usa la stessa rete su entrambi i dispositivi.';
	@override String get sessionNotFound => 'Dispositivo non trovato. Assicurati che Plezy sia in esecuzione sull\'host.';
	@override String get authFailed => 'Autenticazione non riuscita. Entrambi i dispositivi devono usare lo stesso account Plex.';
	@override String failedToConnect({required Object error}) => 'Connessione non riuscita: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$it extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Vuoi disconnetterti dalla sessione remota?';
	@override String get reconnecting => 'Riconnessione...';
	@override String attemptOf({required Object current}) => 'Tentativo ${current} di 5';
	@override String get retryNow => 'Riprova ora';
	@override String get tabRemote => 'Telecomando';
	@override String get tabPlay => 'Riproduci';
	@override String get tabMore => 'Altro';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Navigazione';
	@override String get tabDiscover => 'Esplora';
	@override String get tabLibraries => 'Librerie';
	@override String get tabSearch => 'Cerca';
	@override String get tabDownloads => 'Download';
	@override String get tabSettings => 'Impostazioni';
	@override String get previous => 'Precedente';
	@override String get playPause => 'Riproduci/Pausa';
	@override String get next => 'Successivo';
	@override String get seekBack => 'Indietro';
	@override String get stop => 'Interrompi';
	@override String get seekForward => 'Avanti';
	@override String get volume => 'Volume';
	@override String get volumeDown => 'Abbassa';
	@override String get volumeUp => 'Alza';
	@override String get fullscreen => 'Schermo intero';
	@override String get subtitles => 'Sottotitoli';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Cerca sul computer...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$it extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Nessuna interfaccia di rete trovata';
	@override String get authenticationFailed => 'Autenticazione non riuscita';
	@override String serverStartFailed({required Object error}) => 'Impossibile avviare il server remoto: ${error}';
	@override String commandFailed({required Object error}) => 'Impossibile inviare il comando remoto: ${error}';
	@override String get joinTimedOut => 'Tempo scaduto durante la partecipazione alla sessione';
	@override String get failedToConnectAnyAddress => 'Impossibile connettersi a qualsiasi indirizzo';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Connessione persa dopo ${attempts} tentativi';
	@override String get connectionLost => 'Connessione persa';
}

// Path: services.names
class _Translations$services$names$it extends Translations$services$names$en {
	_Translations$services$names$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$it extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Attiva Plezy su ${service}';
	@override String body({required Object url}) => 'Visita ${url} e inserisci questo codice:';
	@override String openToActivate({required Object service}) => 'Apri ${service} per attivare';
	@override String get copyCode => 'Copia il codice di attivazione';
	@override String get waitingForAuthorization => 'In attesa di autorizzazione…';
	@override String get codeCopied => 'Codice copiato';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$it extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Accedi a ${service}';
	@override String get body => 'Scansiona questo codice QR o apri l\'URL su qualsiasi dispositivo.';
	@override String openToSignIn({required Object service}) => 'Apri ${service} per accedere';
	@override String get copyUrl => 'Copia l\'URL di accesso';
	@override String get urlCopied => 'URL copiato';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$it extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro delle librerie';
	@override String get subtitleAllSyncing => 'Sincronizzazione di tutte le librerie';
	@override String get subtitleNoneSyncing => 'Nessuna sincronizzazione';
	@override String subtitleBlocked({required Object count}) => '${count} bloccate';
	@override String subtitleAllowed({required Object count}) => '${count} consentite';
	@override String get mode => 'Modalità filtro';
	@override String get modeBlacklist => 'Lista nera';
	@override String get modeWhitelist => 'Lista bianca';
	@override String get modeHintBlacklist => 'Sincronizza tutte le librerie tranne quelle selezionate qui sotto.';
	@override String get modeHintWhitelist => 'Sincronizza solo le librerie selezionate qui sotto.';
	@override String get libraries => 'Librerie';
	@override String get noLibraries => 'Nessuna libreria disponibile';
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
			'auth.showQRCode' => 'Mostra codice QR',
			'auth.authenticate' => 'Autenticati',
			'auth.authenticationTimeout' => 'Tempo scaduto per l\'autenticazione. Riprova.',
			'auth.scanQRToSignIn' => 'Scansiona questo codice QR per accedere',
			'auth.waitingForAuth' => 'In attesa di autenticazione...\nAccedi dal browser.',
			'auth.useBrowser' => 'Usa il browser',
			'auth.or' => 'o',
			'auth.connectToJellyfin' => 'Connettiti a Jellyfin',
			'auth.useQuickConnect' => 'Usa Quick Connect',
			'auth.quickConnectInstructions' => 'Apri Quick Connect in Jellyfin e inserisci questo codice.',
			'auth.quickConnectWaiting' => 'In attesa di approvazione…',
			'auth.quickConnectCancel' => 'Annulla',
			'auth.quickConnectExpired' => 'Quick Connect scaduto. Riprova.',
			'auth.localDataRecoveryRequired' => 'Plezy non è riuscito a recuperare in sicurezza i dati locali di accesso e delle riproduzioni in sospeso. Accedi di nuovo.',
			'common.cancel' => 'Annulla',
			'common.save' => 'Salva',
			'common.close' => 'Chiudi',
			'common.clear' => 'Cancella',
			'common.reset' => 'Ripristina',
			'common.later' => 'Più tardi',
			'common.submit' => 'Invia',
			'common.confirm' => 'Conferma',
			'common.retry' => 'Riprova',
			'common.logout' => 'Esci',
			'common.unknown' => 'Sconosciuto',
			'common.refresh' => 'Aggiorna',
			'common.yes' => 'Sì',
			'common.no' => 'No',
			'common.delete' => 'Elimina',
			'common.edit' => 'Modifica',
			'common.shuffle' => 'Riproduzione casuale',
			'common.addTo' => 'Aggiungi a...',
			'common.createNew' => 'Crea nuovo',
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
			'common.mute' => 'Disattiva audio',
			'common.ok' => 'OK',
			'common.off' => 'Disattivato',
			'common.seasonNumber' => ({required Object number}) => 'Stagione ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episodio ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Capitolo ${number}',
			'common.reconnect' => 'Riconnetti',
			'common.viewAll' => 'Mostra tutto',
			'common.checkingNetwork' => 'Controllo della rete...',
			'common.loadingServers' => 'Caricamento server...',
			'common.connectingToServers' => 'Connessione ai server...',
			'common.startingOfflineMode' => 'Avvio modalità offline...',
			'common.loading' => 'Caricamento...',
			'common.fullscreen' => 'Schermo intero',
			'common.exitFullscreen' => 'Esci dalla modalità a schermo intero',
			'common.pressBackAgainToExit' => 'Premi di nuovo Indietro per uscire',
			'screens.licenses' => 'Licenze',
			'screens.switchProfile' => 'Cambia profilo',
			'screens.subtitleStyling' => 'Stile sottotitoli',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Log',
			'update.available' => 'Aggiornamento disponibile',
			'update.versionAvailable' => ({required Object version}) => 'Versione ${version} disponibile',
			'update.currentVersion' => ({required Object version}) => 'Attuale: ${version}',
			'update.skipVersion' => 'Salta questa versione',
			'update.viewRelease' => 'Visualizza note di rilascio',
			'update.latestVersion' => 'La versione installata è l\'ultima disponibile',
			'update.checkFailed' => 'Impossibile controllare gli aggiornamenti',
			'settings.title' => 'Impostazioni',
			'settings.supportDeveloper' => 'Supporta Plezy',
			'settings.supportDeveloperDescription' => 'Dona tramite Liberapay per finanziare lo sviluppo',
			'settings.language' => 'Lingua',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aspetto',
			'settings.videoPlayback' => 'Riproduzione video',
			'settings.videoPlaybackDescription' => 'Configura il comportamento di riproduzione',
			'settings.advanced' => 'Avanzate',
			'settings.episodePosterMode' => 'Stile poster episodio',
			'settings.seriesPoster' => 'Poster della serie',
			'settings.seasonPoster' => 'Poster della stagione',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale',
			'settings.secondsLabel' => 'Secondi',
			'settings.minutesLabel' => 'Minuti',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Inserisci una durata (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.lightTheme' => 'Chiaro',
			'settings.darkTheme' => 'Scuro',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Densità della libreria',
			'settings.compact' => 'Compatta',
			'settings.comfortable' => 'Comoda',
			'settings.tvCornerSpotlightBackdrop' => 'Sfondo in evidenza nell\'angolo',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostra l\'immagine in evidenza nell\'angolo in alto a destra anziché a schermo intero',
			'settings.viewMode' => 'Modalità di visualizzazione',
			'settings.gridView' => 'Griglia',
			'settings.listView' => 'Elenco',
			'settings.showHeroSection' => 'Mostra sezione in evidenza',
			'settings.continueWatchingAction' => 'Azione per Continua a guardare',
			'settings.continueWatchingPlay' => 'Riproduci',
			'settings.continueWatchingDetails' => 'Apri dettagli',
			'settings.episodeAction' => 'Azione episodio',
			'settings.episodePlay' => 'Riproduci',
			'settings.episodeDetails' => 'Apri dettagli',
			'settings.useGlobalHubs' => 'Usa il layout della Home',
			'settings.useGlobalHubsDescription' => 'Mostra sezioni Home unificate. In caso contrario, usa i consigli della libreria.',
			'settings.showServerNameOnHubs' => 'Mostra il nome del server nelle sezioni',
			'settings.showServerNameOnHubsDescription' => 'Mostra sempre i nomi dei server nei titoli delle sezioni.',
			'settings.groupLibrariesByServer' => 'Raggruppa le librerie per server',
			'settings.groupLibrariesByServerDescription' => 'Raggruppa le librerie della barra laterale sotto ciascun server multimediale.',
			'settings.alwaysKeepSidebarOpen' => 'Mantieni sempre aperta la barra laterale',
			'settings.alwaysKeepSidebarOpenDescription' => 'La barra laterale rimane espansa e l\'area del contenuto si adatta',
			'settings.showUnwatchedCount' => 'Mostra il numero di episodi non visti',
			'settings.showUnwatchedCountDescription' => 'Mostra il numero di episodi non visti per serie e stagioni',
			'settings.showEpisodeNumberOnCards' => 'Mostra il numero dell\'episodio sulle schede',
			'settings.showEpisodeNumberOnCardsDescription' => 'Mostra il numero della stagione e dell\'episodio sulle schede degli episodi',
			'settings.showSeasonPostersOnTabs' => 'Mostra i poster delle stagioni nelle schede',
			'settings.showSeasonPostersOnTabsDescription' => 'Mostra il poster di ogni stagione sopra la sua scheda',
			'settings.tvFullCardLayout' => 'Schede TV a tutta immagine',
			'settings.tvFullCardLayoutDescription' => 'Usa schede TV con la sola immagine e i nomi degli attori sovrapposti',
			'settings.focusGlow' => 'Bagliore di selezione',
			'settings.focusGlowDescription' => 'Mostra un leggero bagliore attorno alla scheda selezionata',
			'settings.visualEffects' => 'Effetti visivi',
			'settings.visualEffectsAuto' => 'Automatico',
			'settings.visualEffectsAutoDescription' => 'Riduci automaticamente gli effetti sui dispositivi a basso consumo',
			'settings.visualEffectsFull' => 'Completi',
			'settings.visualEffectsReduced' => 'Ridotti',
			'settings.visualEffectsReducedDescription' => 'Meno animazioni e immagini a risoluzione inferiore',
			'settings.hideSpoilers' => 'Nascondi spoiler per episodi non visti',
			'settings.hideSpoilersDescription' => 'Sfoca miniature e descrizioni degli episodi non visti',
			'settings.playerBackend' => 'Motore di riproduzione',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Decodifica hardware',
			'settings.hardwareDecodingDescription' => 'Utilizza l\'accelerazione hardware quando disponibile',
			'settings.bufferSize' => 'Dimensione buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Automatica (consigliata)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB di memoria disponibile. Un buffer di ${size}MB può influire sulla riproduzione.',
			'settings.defaultQualityTitle' => 'Qualità predefinita',
			'settings.musicQualityTitle' => 'Qualità musicale',
			'settings.subtitleStyling' => 'Stile sottotitoli',
			'settings.subtitleStylingDescription' => 'Personalizza l\'aspetto dei sottotitoli',
			'settings.smallSkipDuration' => 'Salto breve',
			'settings.largeSkipDuration' => 'Salto lungo',
			'settings.rewindOnResume' => 'Riavvolgimento alla ripresa',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} secondi',
			'settings.defaultSleepTimer' => 'Timer spegnimento predefinito',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minuti',
			'settings.rememberTrackSelections' => 'Ricorda la selezione delle tracce per ogni serie o film',
			'settings.rememberTrackSelectionsDescription' => 'Ricorda le scelte di audio e sottotitoli per ogni titolo',
			'settings.showChapterMarkersOnTimeline' => 'Mostra i marcatori dei capitoli sulla barra di avanzamento',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segmenta la barra di avanzamento ai confini dei capitoli',
			'settings.clickVideoTogglesPlayback' => 'Fai clic sul video per alternare riproduzione e pausa',
			'settings.clickVideoTogglesPlaybackDescription' => 'Fai clic sul video per riprodurre o mettere in pausa anziché mostrare i controlli.',
			'settings.videoPlayerControls' => 'Controlli del lettore video',
			'settings.keyboardShortcuts' => 'Scorciatoie da tastiera',
			'settings.keyboardShortcutsDescription' => 'Personalizza le scorciatoie da tastiera',
			'settings.videoPlayerNavigation' => 'Navigazione del lettore video',
			'settings.videoPlayerNavigationDescription' => 'Usa i tasti freccia per navigare nei controlli del lettore video',
			'settings.watchTogetherRelay' => 'Relay di Guarda insieme',
			'settings.watchTogetherRelayDescription' => 'Imposta un relay personalizzato. Tutti devono usare lo stesso server.',
			'settings.watchTogetherRelayHint' => 'https://mio-relay.esempio.it',
			'settings.watchTogetherRelayInvalid' => 'Inserisci un URL di base HTTP o HTTPS valido per il relay.',
			'settings.crashReporting' => 'Segnalazione degli arresti anomali',
			'settings.crashReportingDescription' => 'Invia segnalazioni sugli arresti anomali per contribuire a migliorare l\'app',
			'settings.debugLogging' => 'Registrazione di debug',
			'settings.debugLoggingDescription' => 'Abilita una registrazione dettagliata per la risoluzione dei problemi',
			'settings.viewLogs' => 'Visualizza i log',
			'settings.viewLogsDescription' => 'Visualizza i log dell\'applicazione',
			'settings.resetSettings' => 'Ripristina impostazioni',
			'settings.resetSettingsDescription' => 'Ripristina le impostazioni predefinite. Questa operazione non può essere annullata.',
			'settings.resetSettingsSuccess' => 'Impostazioni ripristinate correttamente',
			'settings.backup' => 'Backup',
			'settings.exportSettings' => 'Esporta impostazioni',
			'settings.exportSettingsDescription' => 'Salva le tue preferenze in un file',
			'settings.exportSettingsSuccess' => 'Impostazioni esportate',
			'settings.importSettings' => 'Importa impostazioni',
			'settings.importSettingsDescription' => 'Ripristina le preferenze da un file',
			'settings.importSettingsConfirm' => 'Questa azione sostituirà le impostazioni attuali. Continuare?',
			'settings.importSettingsSuccess' => 'Impostazioni importate',
			'settings.importSettingsInvalidFile' => 'Questo file non è un\'esportazione Plezy valida',
			'settings.importSettingsNoUser' => 'Accedi prima di importare le impostazioni',
			'settings.shortcutsReset' => 'Scorciatoie ripristinate alle impostazioni predefinite',
			'settings.about' => 'Informazioni',
			'settings.aboutDescription' => 'Informazioni sull\'app e le licenze',
			'settings.updates' => 'Aggiornamenti',
			'settings.updateAvailable' => 'Aggiornamento disponibile',
			'settings.checkForUpdates' => 'Controlla aggiornamenti',
			'settings.autoCheckUpdatesOnStartup' => 'Controlla automaticamente gli aggiornamenti all\'avvio',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Avvisa all\'avvio quando è disponibile un aggiornamento',
			'settings.validationErrorEnterNumber' => 'Inserisci un numero valido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'La durata deve essere compresa tra ${min} e ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Scorciatoia già assegnata a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Scorciatoia aggiornata per ${action}',
			'settings.saveFailed' => 'Impossibile salvare le modifiche. Riprova.',
			'settings.autoSkip' => 'Salto automatico',
			'settings.autoSkipIntro' => 'Salta automaticamente la sigla iniziale',
			'settings.autoSkipIntroDescription' => 'Salta automaticamente i marcatori della sigla iniziale dopo alcuni secondi',
			'settings.autoSkipCredits' => 'Salta automaticamente i titoli di coda',
			'settings.autoSkipCreditsDescription' => 'Salta automaticamente i titoli di coda e riproduce l\'episodio successivo',
			'settings.forceSkipMarkerFallback' => 'Forza i marcatori di ripiego',
			'settings.forceSkipMarkerFallbackDescription' => 'Usa i modelli dei titoli dei capitoli anche quando Plex dispone di marcatori',
			'settings.autoSkipDelay' => 'Ritardo del salto automatico',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Attendi ${seconds} secondi prima del salto automatico',
			'settings.introPattern' => 'Modello del marcatore della sigla iniziale',
			'settings.introPatternDescription' => 'Espressione regolare per individuare i marcatori della sigla iniziale nei titoli dei capitoli',
			'settings.creditsPattern' => 'Modello del marcatore dei titoli di coda',
			'settings.creditsPatternDescription' => 'Espressione regolare per individuare i marcatori dei titoli di coda nei titoli dei capitoli',
			'settings.invalidRegex' => 'Espressione regolare non valida',
			'settings.regex' => 'Espressione regolare',
			'settings.downloads' => 'Download',
			'settings.downloadLocationDescription' => 'Scegli dove archiviare i contenuti scaricati',
			'settings.downloadLocationDefault' => 'Predefinita (archivio dell\'app)',
			'settings.downloadLocationCustom' => 'Posizione personalizzata',
			'settings.selectFolder' => 'Seleziona cartella',
			'settings.resetToDefault' => 'Ripristina posizione predefinita',
			'settings.currentPath' => ({required Object path}) => 'Attuale: ${path}',
			'settings.downloadLocationChanged' => 'Posizione di download modificata',
			'settings.downloadLocationReset' => 'Posizione di download ripristinata a predefinita',
			'settings.downloadLocationInvalid' => 'La cartella selezionata non è scrivibile',
			'settings.downloadLocationPickerUnavailable' => 'La selezione della cartella non è disponibile su questo dispositivo',
			'settings.downloadOnWifiOnly' => 'Scarica solo tramite Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Impedisci i download quando si utilizza la rete dati cellulare',
			'settings.autoRemoveWatchedDownloads' => 'Rimuovi automaticamente i download visti',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Elimina automaticamente i download già visti',
			'settings.cellularDownloadBlocked' => 'I download sono bloccati sulla rete mobile. Usa il Wi-Fi o modifica l\'impostazione.',
			'settings.maxVolume' => 'Volume massimo consentito',
			'settings.maxVolumeDescription' => 'Consenti di aumentare il volume oltre il 100% per i contenuti con audio basso',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Mostra su Discord cosa stai guardando',
			'settings.services' => 'Servizi',
			'settings.servicesDescription' => 'Connetti Trakt, MyAnimeList, Seerr e altro',
			'settings.manageLibrariesDescription' => 'Riordina e nascondi le librerie',
			'settings.companionRemoteServer' => 'Server del telecomando',
			'settings.companionRemoteServerDescription' => 'Consenti ai dispositivi mobili della tua rete di controllare questa app',
			'settings.autoPip' => 'Picture-in-Picture automatica',
			'settings.autoPipDescription' => 'Attiva automaticamente la modalità Picture-in-Picture quando esci dall\'app durante la riproduzione',
			'settings.matchContentFrameRate' => 'Adatta la frequenza dei fotogrammi',
			'settings.matchContentFrameRateDescription' => 'Adatta la frequenza di aggiornamento dello schermo al contenuto video',
			'settings.matchRefreshRate' => 'Adatta la frequenza di aggiornamento',
			'settings.matchRefreshRateDescription' => 'Adatta la frequenza di aggiornamento dello schermo in modalità a schermo intero',
			'settings.matchDynamicRange' => 'Adatta la gamma dinamica',
			'settings.matchDynamicRangeDescription' => 'Attiva l\'HDR per i contenuti HDR, quindi torna all\'SDR',
			'settings.displaySwitchDelay' => 'Ritardo del cambio di modalità dello schermo',
			'settings.tunneledPlayback' => 'Riproduzione con tunneling',
			'settings.tunneledPlaybackDescription' => 'Usa il tunneling video. Disattivalo se durante la riproduzione HDR lo schermo rimane nero.',
			'settings.audioPassthrough' => 'Passthrough audio',
			'settings.audioPassthroughDescription' => 'Invia l\'audio Dolby/DTS al ricevitore o al televisore senza ricodificarlo, preservando l\'audio surround. Disattiva questa opzione se non senti alcun suono.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Usa il decoder Dolby nativo di Apple per Dolby Digital Plus, incluso Atmos. DTS e TrueHD vengono comunque riprodotti come PCM multicanale. Disattiva questa opzione se non senti alcun suono.',
			'settings.audioDownmix' => 'Downmix in stereo',
			'settings.audioDownmixDescription' => 'Riduce l\'audio surround a due canali per altoparlanti stereo o cuffie',
			'settings.downmixCenterBoost' => 'Amplificazione canale centrale',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Amplificazione (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizza il volume durante il downmix',
			'settings.audioDownmixNormalizeDescription' => 'Riduce il volume del mix per evitare il clipping. Disattiva questa opzione per mantenere il volume originale (le scene più rumorose potrebbero risultare distorte).',
			'settings.atmosDiagnostics' => 'Test uscita Atmos',
			'settings.atmosDiagnosticsDescription' => 'Diagnostica l\'uscita Dolby Atmos riproducendo segnali di prova con il lettore di sistema',
			'settings.atmosTestHlsAtmos' => 'Stream Atmos di Apple',
			'settings.atmosTestHlsAtmosDescription' => 'Stream Dolby Atmos di riferimento. Il ricevitore dovrebbe mostrare Dolby Atmos.',
			'settings.atmosTestHlsControl' => 'Stream surround di Apple',
			'settings.atmosTestHlsControlDescription' => 'Stream di controllo senza Atmos. Il ricevitore dovrebbe mostrare surround senza Atmos.',
			'settings.atmosTestRawStream' => 'Stream EAC3 grezzo',
			'settings.atmosTestRawStreamDescription' => 'Trasmette il file di prova esattamente come la riproduzione Atmos del lettore. Richiede l\'URL del file di prova.',
			'settings.atmosTestRawFile' => 'File EAC3 grezzo',
			'settings.atmosTestRawFileDescription' => 'Riproduce il file di prova con lunghezza nota. Richiede l\'URL del file di prova.',
			'settings.atmosTestAsbarNative' => 'Renderer con buffer di campioni (nativo)',
			'settings.atmosTestAsbarNativeDescription' => 'Invia l\'audio compresso intatto del file direttamente al renderer di sistema. Richiede l\'URL del file di test.',
			'settings.atmosTestAsbarGenerated' => 'Renderer con buffer di campioni (ricostruito)',
			'settings.atmosTestAsbarGeneratedDescription' => 'Come sopra, ma con la descrizione audio costruita come nella riproduzione. Richiede l\'URL del file di test.',
			'settings.atmosTestSessionMode' => 'Usa la modalità riproduzione film',
			'settings.atmosTestSessionModeDescription' => 'Disattivato usa la modalità documentata da Dolby. Attivato usa la modalità precedente.',
			'settings.atmosTestShowRoutePicker' => 'Scegli uscita AirPlay',
			'settings.atmosTestHideRoutePicker' => 'Nascondi selettore uscita AirPlay',
			'settings.atmosTestRoutePickerDescription' => 'Invia il test a un ricevitore AirPlay. Solo AirPlay riporta la modalità audio risolta.',
			'settings.atmosTestStop' => 'Interrompi test',
			'settings.atmosTestUrl' => 'URL del file di prova',
			'settings.atmosTestUrlDescription' => 'URL HTTP di un file .ec3 Dolby Atmos grezzo (ad es. estratto con ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Imposta prima l\'URL del file di prova',
			'settings.atmosTestStatus' => 'Stato',
			'settings.dvConversionMode' => 'Conversione Dolby Vision',
			'settings.dvConversionModeDescription' => 'Scegli come ExoPlayer gestisce i file Dolby Vision con profilo 7.',
			'settings.dvConversionAuto' => 'Auto',
			'settings.dvConversionNative' => 'Nativa / disattivata',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Rileva le capacità del dispositivo e usa il normale meccanismo di ripiego',
			'settings.dvConversionNativeDescription' => 'Forza il DV7 nativo e impedisce nuovi tentativi di conversione DV',
			'settings.dvConversionDv81Description' => 'Forza la conversione RPU diretta al profilo Dolby Vision 8.1',
			'settings.dvConversionHevcStripDescription' => 'Rimuove i livelli RPU/EL di Dolby Vision e riproduce il video come semplice HEVC',
			'settings.requireProfileSelectionOnOpen' => 'Chiedi di scegliere il profilo all\'apertura',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostra la selezione del profilo ogni volta che l\'app viene aperta',
			'settings.forceTvMode' => 'Forza modalità TV',
			'settings.forceTvModeDescription' => 'Forza il layout TV sui dispositivi che non vengono rilevati automaticamente. Richiede il riavvio.',
			'settings.startInFullscreen' => 'Avvia a schermo intero',
			'settings.startInFullscreenDescription' => 'Apri Plezy a schermo intero all\'avvio',
			'settings.exitFullscreenOnPlayerClose' => 'Esci dalla modalità a schermo intero alla chiusura del lettore',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Esce automaticamente dalla modalità a schermo intero quando chiudi il lettore video',
			'settings.autoHidePerformanceOverlay' => 'Nascondi automaticamente il riquadro delle prestazioni',
			'settings.autoHidePerformanceOverlayDescription' => 'Dissolvi il riquadro delle prestazioni insieme ai controlli di riproduzione',
			'settings.showNavBarLabels' => 'Mostra le etichette della barra di navigazione',
			'settings.showNavBarLabelsDescription' => 'Mostra le etichette di testo sotto le icone della barra di navigazione',
			'settings.startupSection' => 'Sezione di avvio',
			'settings.liveTvDefaultFavorites' => 'Apri sui canali preferiti',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostra solo i canali preferiti quando apri la TV in diretta',
			'settings.display' => 'Schermo',
			'settings.homeScreen' => 'Schermata iniziale',
			'settings.navigation' => 'Navigazione',
			'settings.window' => 'Finestra',
			'settings.content' => 'Contenuti',
			'settings.player' => 'Lettore',
			'settings.subtitlesAndConfig' => 'Sottotitoli e impostazioni',
			'settings.seekAndTiming' => 'Avanzamento e tempi',
			'settings.behavior' => 'Comportamento',
			'search.hint' => 'Cerca film, serie TV e musica...',
			'search.tryDifferentTerm' => 'Prova altri termini di ricerca',
			'search.searchYourMedia' => 'Cerca nei tuoi media',
			'search.enterTitleActorOrKeyword' => 'Inserisci un titolo, attore o parola chiave',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Imposta una scorciatoia per ${actionName}',
			'hotkeys.clearShortcut' => 'Elimina scorciatoia',
			'hotkeys.noShortcutSet' => 'Nessuna scorciatoia impostata',
			'hotkeys.currentShortcut' => 'Scorciatoia attuale:',
			'hotkeys.pressToRecord' => 'Seleziona per registrare una scorciatoia',
			'hotkeys.recordingShortcut' => 'Premi ora la scorciatoia',
			'hotkeys.actions.playPause' => 'Riproduci/Pausa',
			'hotkeys.actions.volumeUp' => 'Alza volume',
			'hotkeys.actions.volumeDown' => 'Abbassa volume',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avanti (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Indietro (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Attiva/disattiva schermo intero',
			'hotkeys.actions.muteToggle' => 'Attiva/disattiva audio',
			'hotkeys.actions.subtitleToggle' => 'Attiva/disattiva sottotitoli',
			'hotkeys.actions.audioTrackNext' => 'Traccia audio successiva',
			'hotkeys.actions.subtitleTrackNext' => 'Sottotitoli successivi',
			'hotkeys.actions.chapterNext' => 'Capitolo successivo',
			'hotkeys.actions.chapterPrevious' => 'Capitolo precedente',
			'hotkeys.actions.episodeNext' => 'Episodio successivo',
			'hotkeys.actions.episodePrevious' => 'Episodio precedente',
			'hotkeys.actions.speedIncrease' => 'Aumenta velocità',
			'hotkeys.actions.speedDecrease' => 'Diminuisci velocità',
			'hotkeys.actions.speedReset' => 'Ripristina velocità',
			'hotkeys.actions.zoomIn' => 'Aumenta zoom',
			'hotkeys.actions.zoomOut' => 'Riduci zoom',
			'hotkeys.actions.zoomReset' => 'Ripristina zoom',
			'hotkeys.actions.subSeekNext' => 'Vai al sottotitolo successivo',
			'hotkeys.actions.subSeekPrev' => 'Vai al sottotitolo precedente',
			'hotkeys.actions.shaderToggle' => 'Attiva/disattiva shader',
			'hotkeys.actions.skipMarker' => 'Salta intro/titoli di coda',
			'hotkeys.actions.screenshot' => 'Cattura schermata',
			'fileInfo.title' => 'Info sul file',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'File',
			'fileInfo.advanced' => 'Avanzate',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Risoluzione',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Frequenza fotogrammi',
			'fileInfo.aspectRatio' => 'Proporzioni',
			'fileInfo.profile' => 'Profilo',
			'fileInfo.bitDepth' => 'Profondità in bit',
			'fileInfo.colorSpace' => 'Spazio colore',
			'fileInfo.colorRange' => 'Gamma colori',
			'fileInfo.colorPrimaries' => 'Colori primari',
			'fileInfo.chromaSubsampling' => 'Sottocampionamento cromatico',
			'fileInfo.channels' => 'Canali',
			'fileInfo.subtitles' => 'Sottotitoli',
			'fileInfo.overallBitrate' => 'Bitrate complessivo',
			'fileInfo.path' => 'Percorso',
			'fileInfo.size' => 'Dimensione',
			'fileInfo.container' => 'Contenitore',
			'fileInfo.duration' => 'Durata',
			'fileInfo.optimizedForStreaming' => 'Ottimizzato per lo streaming',
			'fileInfo.has64bitOffsets' => 'Offset a 64 bit',
			'mediaMenu.markAsWatched' => 'Segna come visto',
			'mediaMenu.markAsUnwatched' => 'Segna come non visto',
			'mediaMenu.removeFromContinueWatching' => 'Rimuovi da Continua a guardare',
			'mediaMenu.viewDetails' => 'Visualizza dettagli',
			'mediaMenu.goToSeries' => 'Vai alla serie',
			'mediaMenu.shufflePlay' => 'Riproduzione casuale',
			'mediaMenu.shuffleNotAvailableOffline' => 'Riproduzione casuale non disponibile offline',
			'mediaMenu.fileInfo' => 'Info sul file',
			'mediaMenu.deleteFromServer' => 'Elimina dal server',
			'mediaMenu.confirmDelete' => 'Eliminare questo media e i suoi file dal server?',
			'mediaMenu.deleteMultipleWarning' => 'Sono inclusi tutti gli episodi e i relativi file.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Elemento multimediale eliminato correttamente',
			'mediaMenu.mediaFailedToDelete' => 'Impossibile eliminare l\'elemento multimediale',
			'mediaMenu.rate' => 'Valuta',
			'mediaMenu.playFromBeginning' => 'Riproduci dall\'inizio',
			'mediaMenu.playVersion' => 'Riproduci versione...',
			'rateSheet.title' => 'Valuta',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Preferito',
			'rateSheet.favorited' => 'Aggiunto ai preferiti',
			'rateSheet.saved' => 'Salvato',
			'rateSheet.notAvailable' => 'Nessuna corrispondenza trovata',
			'rateSheet.noConnectedServices' => 'Collega un servizio nelle Impostazioni per assegnare valutazioni anche su quel servizio.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serie TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => 'visto al ${percent}%',
			'accessibility.mediaCardUnwatched' => 'non visto',
			'accessibility.tapToPlay' => 'Tocca per riprodurre',
			'accessibility.decrease' => 'Diminuisci',
			'accessibility.increase' => 'Aumenta',
			'accessibility.decreaseValue' => ({required Object label}) => 'Diminuisci ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Aumenta ${label}',
			'accessibility.hue' => 'Tonalità',
			'accessibility.saturation' => 'Saturazione',
			'accessibility.brightness' => 'Luminosità',
			'accessibility.hexColor' => 'Colore esadecimale',
			'accessibility.expandText' => 'Espandi il testo',
			'accessibility.collapseText' => 'Comprimi il testo',
			'accessibility.alphabetNavigation' => 'Navigazione alfabetica',
			'accessibility.alphabetScrollHint' => 'Scorri verso l\'alto o il basso per cambiare lettera',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Riga ${row} di ${rowCount}, colonna ${column} di ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Riga ${row} di ${rowCount}',
			'tooltips.shufflePlay' => 'Riproduzione casuale',
			'tooltips.playTrailer' => 'Riproduci trailer',
			'tooltips.markAsWatched' => 'Segna come visto',
			'tooltips.markAsUnwatched' => 'Segna come non visto',
			'audioTracks.track' => ({required Object n}) => 'Traccia audio ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Sottotitoli',
			'videoControls.resetToZero' => 'Ripristina a 0 ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label}: riproduzione ritardata',
			'videoControls.playsEarlier' => ({required Object label}) => '${label}: riproduzione anticipata',
			'videoControls.noOffset' => 'Nessun ritardo',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Riempi lo schermo',
			'videoControls.stretch' => 'Allunga',
			'videoControls.lockRotation' => 'Blocca rotazione',
			'videoControls.unlockRotation' => 'Sblocca rotazione',
			'videoControls.timerActive' => 'Timer attivo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'La riproduzione verrà messa in pausa tra ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Fine del video corrente',
			'videoControls.sleepTimerStopAtHeader' => 'Interrompi alle',
			'videoControls.sleepTimerDurationHeader' => 'Timer',
			'videoControls.playbackWillPauseAtEnd' => 'La riproduzione verrà messa in pausa alla fine di questo video',
			'videoControls.stillWatching' => 'Stai ancora guardando?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausa tra ${seconds}s',
			'videoControls.continueWatching' => 'Continua',
			'videoControls.autoPlayNext' => 'Riproduci automaticamente il successivo',
			'videoControls.playNext' => 'Riproduci il successivo',
			'videoControls.playButton' => 'Riproduci',
			'videoControls.pauseButton' => 'Pausa',
			'videoControls.showPlaybackControls' => 'Mostra i controlli di riproduzione',
			'videoControls.hidePlaybackControls' => 'Nascondi i controlli di riproduzione',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Riavvolgi di ${seconds} secondi',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avanza di ${seconds} secondi',
			'videoControls.previousButton' => 'Episodio precedente',
			'videoControls.nextButton' => 'Episodio successivo',
			'videoControls.previousChapterButton' => 'Capitolo precedente',
			'videoControls.nextChapterButton' => 'Capitolo successivo',
			'videoControls.muteButton' => 'Silenzia',
			'videoControls.unmuteButton' => 'Riattiva audio',
			'videoControls.settingsButton' => 'Impostazioni di riproduzione',
			'videoControls.tracksButton' => 'Audio e sottotitoli',
			'videoControls.chaptersButton' => 'Capitoli',
			'videoControls.versionQualityButton' => 'Versione e qualità',
			'videoControls.versionColumnHeader' => 'Versione',
			'videoControls.qualityColumnHeader' => 'Qualità',
			'videoControls.qualityOriginal' => 'Originale',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodifica non disponibile — riproduzione in qualità originale',
			'videoControls.subtitleUnavailableFallback' => 'Impossibile caricare i sottotitoli selezionati — la riproduzione continua senza sottotitoli',
			'videoControls.pipButton' => 'Modalità Picture-in-Picture',
			'videoControls.aspectRatioButton' => 'Proporzioni',
			'videoControls.ambientLighting' => 'Illuminazione ambientale',
			'videoControls.fullscreenButton' => 'Attiva schermo intero',
			'videoControls.exitFullscreenButton' => 'Esci da schermo intero',
			'videoControls.alwaysOnTopButton' => 'Sempre in primo piano',
			'videoControls.rotationLockButton' => 'Blocco rotazione',
			'videoControls.lockScreen' => 'Blocca schermo',
			'videoControls.screenLockButton' => 'Blocco schermo',
			'videoControls.longPressToUnlock' => 'Premi a lungo per sbloccare',
			'videoControls.timelineSlider' => 'Timeline video',
			'videoControls.volumeSlider' => 'Livello volume',
			'videoControls.endsAt' => ({required Object time}) => 'Termina alle ${time}',
			'videoControls.pipActive' => 'Riproduzione in Picture-in-Picture',
			'videoControls.pipFailed' => 'Impossibile avviare la modalità Picture-in-Picture',
			'videoControls.screenshotSaved' => 'Schermata salvata',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Richiede Android 8.0 o versioni successive',
			'videoControls.pipErrors.iosVersion' => 'Richiede iOS 15.0 o versioni successive',
			'videoControls.pipErrors.permissionDisabled' => 'La modalità Picture-in-Picture è disattivata. Attivala nelle impostazioni di sistema.',
			'videoControls.pipErrors.notSupported' => 'Questo dispositivo non supporta la modalità Picture-in-Picture',
			'videoControls.pipErrors.voSwitchFailed' => 'Impossibile cambiare l\'uscita video per Picture-in-Picture',
			'videoControls.pipErrors.failed' => 'Impossibile avviare la modalità Picture-in-Picture',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Si è verificato un errore: ${error}',
			'videoControls.chapters' => 'Capitoli',
			'videoControls.noChaptersAvailable' => 'Nessun capitolo disponibile',
			'videoControls.queue' => 'Coda',
			'videoControls.noQueueItems' => 'Nessun elemento in coda',
			'videoControls.searchSubtitles' => 'Cerca sottotitoli',
			'videoControls.language' => 'Lingua',
			'videoControls.noSubtitlesFound' => 'Nessun sottotitolo trovato',
			'videoControls.subtitleDownloaded' => 'Sottotitolo scaricato',
			_ => null,
		} ?? switch (path) {
			'videoControls.subtitleDownloadedNotApplied' => 'Il sottotitolo è stato scaricato, ma non è stato possibile selezionarlo',
			'videoControls.subtitleDownloadFailed' => 'Impossibile scaricare il sottotitolo',
			'videoControls.searchLanguages' => 'Cerca lingue...',
			'messages.markedAsWatched' => 'Segnato come visto',
			'messages.markedAsUnwatched' => 'Segnato come non visto',
			'messages.markedAsWatchedOffline' => 'Segnato come visto (verrà sincronizzato quando torni online)',
			'messages.markedAsUnwatchedOffline' => 'Segnato come non visto (verrà sincronizzato quando torni online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Rimosso automaticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Rimosso automaticamente ${n} download già visto', other: 'Rimossi automaticamente ${n} download già visti', ), 
			'messages.removedFromContinueWatching' => 'Rimosso da Continua a guardare',
			'messages.errorLoading' => ({required Object error}) => 'Errore: ${error}',
			'messages.streamInterrupted' => 'La riproduzione si è interrotta. Premi Riproduci o vai a un altro punto per riprovare.',
			'messages.liveStreamInterrupted' => 'La diretta si è interrotta. Premi Riproduci per riprovare.',
			'messages.fileInfoNotAvailable' => 'Informazioni sul file non disponibili',
			'messages.playbackAuthenticationRequired' => 'Accedi di nuovo al server multimediale per riprodurre questo elemento.',
			'messages.playbackServerUnavailable' => 'Il server multimediale non è disponibile. Riprova più tardi.',
			'messages.playbackDataInvalid' => 'Il server ha restituito informazioni di riproduzione non valide.',
			'messages.playbackCancelled' => 'Riproduzione annullata.',
			'messages.playbackFailed' => 'Impossibile avviare la riproduzione.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Errore durante il caricamento delle informazioni sul file: ${error}',
			'messages.errorLoadingSeries' => 'Errore durante il caricamento della serie',
			'messages.musicNotSupported' => 'La riproduzione musicale non è ancora supportata',
			'messages.noDescriptionAvailable' => 'Nessuna descrizione disponibile',
			'messages.noProfilesAvailable' => 'Nessun profilo disponibile',
			'messages.contactAdminForProfiles' => 'Contatta l\'amministratore del server per aggiungere profili',
			'messages.unableToDetermineLibrarySection' => 'Impossibile determinare la sezione della libreria per questo elemento',
			'messages.logsCleared' => 'Log eliminati',
			'messages.logsCopied' => 'Log copiati negli appunti',
			'messages.noLogsAvailable' => 'Nessun log disponibile',
			'messages.libraryScanning' => ({required Object title}) => 'Scansione di "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Scansione della libreria avviata per "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Impossibile eseguire la scansione della libreria: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Aggiornamento dei metadati di "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Aggiornamento dei metadati avviato per "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Impossibile aggiornare i metadati: ${error}',
			'messages.logoutConfirm' => 'Vuoi uscire dall\'account?',
			'messages.noSeasonsFound' => 'Nessuna stagione trovata',
			'messages.seasonsLoadFailed' => 'Impossibile caricare le stagioni',
			'messages.noEpisodesFound' => 'Nessun episodio trovato nella prima stagione',
			'messages.noEpisodesFoundGeneral' => 'Nessun episodio trovato',
			'messages.episodesLoadFailed' => 'Impossibile caricare gli episodi',
			'messages.noResultsFound' => 'Nessun risultato',
			'messages.sleepTimerSet' => ({required Object label}) => 'Timer di spegnimento impostato su ${label}',
			'messages.noItemsAvailable' => 'Nessun elemento disponibile',
			'messages.failedToCreatePlayQueueNoItems' => 'Impossibile creare una coda di riproduzione: nessun elemento',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Impossibile eseguire l\'azione «${action}»: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Passaggio al lettore compatibile...',
			'messages.serverLimitTitle' => 'Riproduzione non riuscita',
			'messages.serverLimitBody' => 'Errore del server (HTTP 500). È probabile che un limite di banda o transcodifica abbia impedito questa sessione. Chiedi al proprietario di modificare il limite.',
			'messages.logsUploaded' => 'Log caricati',
			'messages.logsUploadFailed' => 'Impossibile caricare i log',
			'messages.logId' => 'ID log',
			'subtitlingStyling.text' => 'Testo',
			'subtitlingStyling.border' => 'Bordo',
			'subtitlingStyling.background' => 'Sfondo',
			'subtitlingStyling.fontSize' => 'Dimensione carattere',
			'subtitlingStyling.textColor' => 'Colore del testo',
			'subtitlingStyling.borderSize' => 'Dimensione del bordo',
			'subtitlingStyling.borderColor' => 'Colore del bordo',
			'subtitlingStyling.backgroundOpacity' => 'Opacità dello sfondo',
			'subtitlingStyling.backgroundColor' => 'Colore dello sfondo',
			'subtitlingStyling.position' => 'Posizione',
			'subtitlingStyling.assOverride' => 'Sovrascrittura ASS',
			'subtitlingStyling.overrideScale' => 'Ridimensiona',
			'subtitlingStyling.overrideForce' => 'Forza',
			'subtitlingStyling.overrideStrip' => 'Rimuovi stile',
			'subtitlingStyling.positionTop' => 'In alto',
			'subtitlingStyling.positionBottom' => 'In basso',
			'subtitlingStyling.bold' => 'Grassetto',
			'subtitlingStyling.italic' => 'Corsivo',
			'subtitlingStyling.renderResolution' => 'Risoluzione di rendering',
			'subtitlingStyling.renderResolutionScreen' => 'Risoluzione dello schermo',
			'subtitlingStyling.renderResolutionVideo' => 'Risoluzione del video',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Impostazioni avanzate del lettore video',
			'mpvConfig.presets' => 'Preset',
			'mpvConfig.noPresets' => 'Nessun preset salvato',
			'mpvConfig.saveAsPreset' => 'Salva come preset...',
			'mpvConfig.presetName' => 'Nome preset',
			'mpvConfig.presetNameHint' => 'Inserisci un nome per questo preset',
			'mpvConfig.loadPreset' => 'Carica',
			'mpvConfig.deletePreset' => 'Elimina',
			'mpvConfig.presetSaved' => 'Preset salvato',
			'mpvConfig.presetLoaded' => 'Preset caricato',
			'mpvConfig.presetDeleted' => 'Preset eliminato',
			'mpvConfig.confirmDeletePreset' => 'Sei sicuro di voler eliminare questo preset?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Conferma azione',
			'profiles.addPlezyProfile' => 'Aggiungi profilo Plezy',
			'profiles.switchingProfile' => 'Cambio profilo…',
			'profiles.deleteThisProfileTitle' => 'Eliminare questo profilo?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Rimuovi ${displayName}. Le connessioni resteranno invariate.',
			'profiles.active' => 'Attivo',
			'profiles.manage' => 'Gestisci',
			'profiles.delete' => 'Elimina',
			'profiles.signOut' => 'Esci',
			'profiles.signOutPlexTitle' => 'Uscire da Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Verranno rimossi ${displayName} e tutti gli utenti Plex Home. Potrai accedere di nuovo in qualsiasi momento.',
			'profiles.signedOutPlex' => 'Disconnessione da Plex completata.',
			'profiles.signOutFailed' => 'Disconnessione non riuscita.',
			'profiles.sectionTitle' => 'Profili',
			'profiles.summarySingle' => 'Aggiungi profili per combinare utenti gestiti e identità locali',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profili · attivo: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profili',
			'profiles.removeConnectionTitle' => 'Rimuovere la connessione?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Rimuovi da ${displayName} l\'accesso a ${connectionLabel}. Gli altri profili continueranno ad avervi accesso.',
			'profiles.deleteProfileTitle' => 'Eliminare il profilo?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Rimuovi ${displayName} e le relative connessioni. I server resteranno disponibili.',
			'profiles.profileNameLabel' => 'Nome profilo',
			'profiles.pinProtectionLabel' => 'Protezione PIN',
			'profiles.pinManagedByPlex' => 'PIN gestito da Plex. Modifica su plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Nessun PIN impostato. Per richiederne uno, modifica l\'utente Home su plex.tv.',
			'profiles.setPin' => 'Imposta PIN',
			'profiles.setPinTitle' => 'Imposta PIN',
			'profiles.confirmPinTitle' => 'Conferma PIN',
			'profiles.pinSet' => 'PIN impostato',
			'profiles.changePin' => 'Cambia',
			'profiles.removePin' => 'Rimuovi',
			'profiles.connectionsLabel' => 'Connessioni',
			'profiles.add' => 'Aggiungi',
			'profiles.deleteProfileButton' => 'Elimina profilo',
			'profiles.noConnectionsHint' => 'Nessuna connessione — aggiungine una per usare questo profilo.',
			'profiles.noConnections' => 'Nessuna connessione',
			'profiles.plexHomeAccount' => 'Account Plex Home',
			'profiles.connectionDefault' => 'Predefinita',
			'profiles.connectionAs' => ({required Object displayName}) => 'come ${displayName}',
			'profiles.makeDefault' => 'Imposta come predefinita',
			'profiles.removeConnection' => 'Rimuovi',
			'profiles.profileRenamed' => 'Profilo rinominato.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Aggiungi a ${displayName}',
			'profiles.borrowExplain' => 'Prendi in prestito la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.',
			'profiles.borrowEmpty' => 'Nulla da prendere in prestito al momento.',
			'profiles.borrowEmptySubtitle' => 'Collega prima Plex o Jellyfin a un altro profilo.',
			'profiles.borrowLoadFailed' => 'Impossibile caricare le connessioni disponibili. Riprova.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Da ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Connessione presa in prestito.',
			'profiles.borrowFailed' => 'Impossibile prendere in prestito la connessione.',
			'profiles.incorrectPin' => 'PIN errato.',
			'profiles.incorrectPinTryAgain' => 'PIN errato. Riprova.',
			'profiles.sourceProfileMissingParentAccount' => 'Al profilo di origine manca l\'account principale.',
			'profiles.failedToLoadHomeUsers' => 'Impossibile caricare gli utenti Plex Home. Controlla la connessione e riprova.',
			'profiles.failedToVerifyPin' => 'Impossibile verificare il PIN.',
			'profiles.newProfile' => 'Nuovo profilo',
			'profiles.profileNameHint' => 'es. Ospiti, Bambini, Soggiorno',
			'profiles.pinProtectionOptional' => 'Protezione PIN (opzionale)',
			'profiles.pinExplain' => 'PIN a 4 cifre richiesto per cambiare profilo.',
			'profiles.continueButton' => 'Continua',
			'profiles.pinsDontMatch' => 'I PIN non corrispondono',
			'connections.sectionTitle' => 'Connessioni',
			'connections.addConnection' => 'Aggiungi connessione',
			'connections.addConnectionSubtitleNoProfile' => 'Accedi con Plex o collega un server Jellyfin',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Aggiungi a ${displayName}: Plex, Jellyfin o la connessione di un altro profilo',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessione scaduta per ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessione scaduta per ${count} server',
			'connections.signInAgain' => 'Accedi di nuovo',
			'connections.editJellyfinTitle' => 'Modifica connessione Jellyfin',
			'connections.editJellyfinIntro' => ({required Object serverName}) => 'Aggiungi o rimuovi URL per ${serverName}. Plezy userà l\'URL raggiungibile con la latenza più bassa.',
			'discover.title' => 'Esplora',
			'discover.noContentAvailable' => 'Nessun contenuto disponibile',
			'discover.addMediaToLibraries' => 'Aggiungi contenuti multimediali alle tue librerie',
			'discover.continueWatching' => 'Continua a guardare',
			'discover.continueWatchingIn' => ({required Object library}) => 'Continua a guardare in ${library}',
			'discover.nextUp' => 'Prossimi episodi',
			'discover.nextUpIn' => ({required Object library}) => 'Prossimi episodi in ${library}',
			'discover.recentlyAdded' => 'Aggiunti di recente',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Aggiunti di recente in ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Ultimi album in ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Riprodotti di recente in ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Più riprodotti in ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Panoramica',
			'discover.cast' => 'Attori',
			'discover.extras' => 'Trailer ed extra',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Valutazione',
			'discover.director' => 'Regista',
			'discover.directors' => 'Registi',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serie TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} minuti rimanenti',
			'discover.moreLikeThis' => 'Altri contenuti simili',
			'errors.searchFailed' => ({required Object error}) => 'Ricerca non riuscita: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tempo scaduto per la connessione durante il caricamento di ${context}',
			'errors.connectionFailed' => 'Impossibile connettersi al server multimediale',
			'errors.unableToLoad' => ({required Object context}) => 'Impossibile caricare ${context}. Riprova.',
			'errors.noClientAvailable' => 'Nessun client disponibile',
			'errors.pleaseEnterToken' => 'Inserisci un token',
			'errors.invalidToken' => 'Token non valido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Impossibile verificare il token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Impossibile passare a ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Impossibile eliminare ${displayName}',
			'errors.failedToRate' => 'Impossibile aggiornare la valutazione',
			'libraries.title' => 'Librerie',
			'libraries.fallbackTitle' => 'Libreria',
			'libraries.scanLibraryFiles' => 'Scansiona i file della libreria',
			'libraries.scanLibrary' => 'Scansiona libreria',
			'libraries.analyze' => 'Analizza',
			'libraries.analyzeLibrary' => 'Analizza libreria',
			'libraries.refreshMetadata' => 'Aggiorna metadati',
			'libraries.emptyTrash' => 'Svuota cestino',
			'libraries.emptyingTrash' => ({required Object title}) => 'Svuotamento del cestino di "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Cestino di "${title}" svuotato',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Impossibile svuotare il cestino: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analisi di "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analisi avviata per "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Impossibile analizzare la libreria: ${error}',
			'libraries.noLibrariesFound' => 'Nessuna libreria trovata',
			'libraries.allLibrariesHidden' => 'Tutte le librerie sono nascoste',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Librerie nascoste (${count})',
			'libraries.thisLibraryIsEmpty' => 'Questa libreria è vuota',
			'libraries.noItemsMatchFilters' => 'Nessun elemento corrisponde ai filtri attivi',
			'libraries.resetFilters' => 'Reimposta filtri',
			'libraries.all' => 'Tutto',
			'libraries.clearAll' => 'Azzera tutto',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Vuoi scansionare "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Vuoi analizzare "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Vuoi aggiornare i metadati di "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Vuoi svuotare il cestino di "${title}"?',
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
			'libraries.groupings.title' => 'Raggruppa per',
			'libraries.groupings.all' => 'Tutti',
			'libraries.groupings.movies' => 'Film',
			'libraries.groupings.shows' => 'Serie TV',
			'libraries.groupings.seasons' => 'Stagioni',
			'libraries.groupings.episodes' => 'Episodi',
			'libraries.groupings.artists' => 'Artisti',
			'libraries.groupings.albums' => 'Album',
			'libraries.groupings.tracks' => 'Brani',
			'libraries.groupings.folders' => 'Cartelle',
			'libraries.filterCategories.genre' => 'Genere',
			'libraries.filterCategories.year' => 'Anno',
			'libraries.filterCategories.contentRating' => 'Classificazione per età',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Non visti',
			'libraries.filterCategories.unplayed' => 'Non riprodotti',
			'libraries.filterCategories.favorites' => 'Preferiti',
			'libraries.sortLabels.title' => 'Titolo',
			'libraries.sortLabels.dateAdded' => 'Data di aggiunta',
			'libraries.sortLabels.releaseDate' => 'Data di uscita',
			'libraries.sortLabels.rating' => 'Valutazione',
			'libraries.sortLabels.communityRating' => 'Valutazione della comunità',
			'libraries.sortLabels.criticRating' => 'Valutazione critica',
			'libraries.sortLabels.userRating' => 'Valutazione utente',
			'libraries.sortLabels.datePlayed' => 'Data di riproduzione',
			'libraries.sortLabels.playCount' => 'Riproduzioni',
			'libraries.sortLabels.productionYear' => 'Anno di produzione',
			'libraries.sortLabels.runtime' => 'Durata',
			'libraries.sortLabels.officialRating' => 'Classificazione ufficiale',
			'libraries.sortLabels.premiereDate' => 'Data di première',
			'libraries.sortLabels.startDate' => 'Data di inizio',
			'libraries.sortLabels.airTime' => 'Orario di messa in onda',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Casuale',
			'libraries.sortLabels.dateShared' => 'Data di condivisione',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Data di trasmissione dell\'ultimo episodio',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Data di aggiunta dell\'ultimo episodio',
			'about.title' => 'Informazioni',
			'about.openSourceLicenses' => 'Licenze open source',
			'about.versionLabel' => ({required Object version}) => 'Versione ${version}',
			'about.appDescription' => 'Un elegante client Plex e Jellyfin per Flutter',
			'about.viewLicensesDescription' => 'Visualizza le licenze delle librerie di terze parti',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Impossibile caricare i server: ${error}',
			'hubDetail.title' => 'Titolo',
			'hubDetail.releaseYear' => 'Anno di uscita',
			'hubDetail.dateAdded' => 'Data di aggiunta',
			'hubDetail.rating' => 'Valutazione',
			'hubDetail.noItemsFound' => 'Nessun elemento trovato',
			'logs.clearLogs' => 'Cancella log',
			'logs.copyLogs' => 'Copia log',
			'logs.uploadLogs' => 'Carica log',
			'licenses.relatedPackages' => 'Pacchetti correlati',
			'licenses.license' => 'Licenza',
			'licenses.licenseNumber' => ({required Object number}) => 'Licenza ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenze',
			'navigation.libraries' => 'Librerie',
			'navigation.downloads' => 'Download',
			'navigation.liveTv' => 'TV in diretta',
			'navigation.explore' => 'Esplora',
			'explore.title' => 'Esplora',
			'explore.selectSource' => 'Seleziona fonte',
			'explore.rows.watchlist' => 'Lista da guardare',
			'explore.rows.recommendedMovies' => 'Film consigliati',
			'explore.rows.recommendedShows' => 'Serie TV consigliate',
			'explore.rows.trendingMovies' => 'Film di tendenza',
			'explore.rows.trendingShows' => 'Serie TV di tendenza',
			'explore.rows.popularMovies' => 'Film popolari',
			'explore.rows.popularShows' => 'Serie TV popolari',
			'explore.rows.trendingAnime' => 'Anime di tendenza',
			'explore.rows.suggestedAnime' => 'Anime suggeriti',
			'explore.rows.airingAnime' => 'Migliori anime in onda',
			'explore.rows.popularAnime' => 'Anime più popolari',
			'explore.rows.trending' => 'Di tendenza',
			'explore.rows.upcomingMovies' => 'Film in arrivo',
			'explore.rows.upcomingShows' => 'Serie TV in arrivo',
			'explore.status.airing' => 'In onda',
			'explore.status.ended' => 'Conclusa',
			'explore.status.canceled' => 'Cancellata',
			'explore.status.upcoming' => 'In arrivo',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${n} episodio', other: '${n} episodi', ), 
			'explore.cast' => 'Attori',
			'explore.characters' => 'Personaggi',
			'explore.addToWatchlist' => 'Aggiungi alla lista da guardare',
			'explore.removeFromWatchlist' => 'Rimuovi dalla lista da guardare',
			'explore.watchlistUpdateFailed' => 'Impossibile aggiornare la lista da guardare',
			'explore.notInLibrary' => 'Non è nella tua libreria',
			'explore.inTheseLibraries' => 'In queste librerie',
			'explore.checkingLibrary' => 'Ricerca nella tua libreria...',
			'explore.emptyTitle' => 'Ancora niente qui',
			'explore.emptyMessage' => ({required Object source}) => 'Le sezioni di ${source} appariranno qui quando saranno disponibili dei contenuti.',
			'explore.searchHint' => ({required Object source}) => 'Cerca su ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Nessun risultato per "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Cerca film e serie TV su ${source}.',
			'explore.searchFailed' => 'Ricerca fallita. Controlla la connessione e riprova.',
			'liveTv.title' => 'TV in diretta',
			'liveTv.guide' => 'Guida',
			'liveTv.noChannels' => 'Nessun canale disponibile',
			'liveTv.noDvr' => 'Nessun DVR configurato su alcun server',
			'liveTv.serverUnavailable' => 'Il server TV in diretta non è disponibile.',
			'liveTv.serverNotConnected' => 'Il server TV in diretta non è connesso.',
			'liveTv.noPrograms' => 'Nessun dato di programma disponibile',
			'liveTv.liveStreamFailed' => 'Streaming in diretta non riuscito',
			'liveTv.unknownProgram' => 'Programma sconosciuto',
			'liveTv.unknownHub' => 'Sconosciuto',
			'liveTv.unknownError' => 'Errore sconosciuto',
			'liveTv.channelNumber' => ({required Object number}) => 'Canale ${number}',
			'liveTv.unknownChannel' => 'Canale sconosciuto',
			'liveTv.live' => 'IN DIRETTA',
			'liveTv.reloadGuide' => 'Ricarica la guida',
			'liveTv.now' => 'Ora',
			'liveTv.today' => 'Oggi',
			'liveTv.tomorrow' => 'Domani',
			'liveTv.midnight' => 'Mezzanotte',
			'liveTv.overnight' => 'Durante la notte',
			'liveTv.morning' => 'Mattina',
			'liveTv.daytime' => 'Giornata',
			'liveTv.evening' => 'Sera',
			'liveTv.lateNight' => 'Tarda notte',
			'liveTv.whatsOn' => 'In onda ora',
			'liveTv.watchChannel' => 'Guarda il canale',
			'liveTv.favorites' => 'Preferiti',
			'liveTv.reorderFavorites' => 'Riordina i preferiti',
			'liveTv.favoritesLoadFailed' => 'Impossibile caricare i preferiti. Controlla la connessione e riprova.',
			'liveTv.favoritesUpdateFailed' => 'Impossibile aggiornare i preferiti. Controlla la connessione e riprova.',
			'liveTv.joinSession' => 'Partecipa alla sessione in corso',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Guarda dall\'inizio (${minutes} min fa)',
			'liveTv.watchLive' => 'Guarda in diretta',
			'liveTv.goToLive' => 'Vai alla diretta',
			'liveTv.record' => 'Registra',
			'liveTv.recordEpisode' => 'Registra episodio',
			'liveTv.recordSeries' => 'Registra serie',
			'liveTv.recordOptions' => 'Opzioni di registrazione',
			'liveTv.saveTo' => 'Salva in',
			'liveTv.recordings' => 'Registrazioni',
			'liveTv.scheduledRecordings' => 'Programmate',
			'liveTv.recordingRules' => 'Regole di registrazione',
			'liveTv.noScheduledRecordings' => 'Nessuna registrazione in programma',
			'liveTv.manageRecording' => 'Gestisci registrazione',
			'liveTv.cancelRecording' => 'Annulla registrazione',
			'liveTv.cancelRecordingTitle' => 'Annullare questa registrazione?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} non sarà più registrato.',
			'liveTv.deleteRule' => 'Elimina regola',
			'liveTv.deleteRuleTitle' => 'Eliminare la regola di registrazione?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'I prossimi episodi di ${title} non saranno registrati.',
			'liveTv.recordingScheduled' => 'Registrazione programmata',
			'liveTv.alreadyScheduled' => 'La registrazione di questo programma è già pianificata',
			'liveTv.dvrAdminRequired' => 'Le impostazioni DVR richiedono un account amministratore',
			'liveTv.recordingFailed' => 'Impossibile programmare la registrazione',
			'liveTv.recordingTargetMissing' => 'Impossibile determinare la libreria di registrazione',
			'liveTv.recordNotAvailable' => 'Registrazione non disponibile per questo programma',
			'liveTv.recordingCancelled' => 'Registrazione annullata',
			'liveTv.recordingRuleDeleted' => 'Regola di registrazione eliminata',
			'liveTv.processRecordingRules' => 'Rielabora le regole',
			'liveTv.recordingInProgress' => 'Registrazione in corso',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} programmate',
			'liveTv.editRule' => 'Modifica regola',
			'liveTv.editRuleAction' => 'Modifica',
			'liveTv.recordingRuleUpdated' => 'Regola di registrazione aggiornata',
			'liveTv.guideReloadRequested' => 'Aggiornamento della guida richiesto',
			'liveTv.rulesProcessRequested' => 'Rielaborazione delle regole richiesta',
			'liveTv.recordShow' => 'Registra programma',
			'collections.title' => 'Raccolte',
			'collections.collection' => 'Raccolta',
			'collections.empty' => 'La raccolta è vuota',
			'collections.deleteCollection' => 'Elimina raccolta',
			'collections.deleteConfirm' => ({required Object title}) => 'Eliminare "${title}"? Non si può annullare.',
			'collections.deleted' => 'Raccolta eliminata',
			'collections.deleteFailed' => 'Impossibile eliminare la raccolta',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Impossibile eliminare la raccolta: ${error}',
			'collections.selectCollection' => 'Seleziona raccolta',
			'collections.collectionName' => 'Nome raccolta',
			'collections.enterCollectionName' => 'Inserisci nome raccolta',
			'collections.addedToCollection' => 'Elemento aggiunto alla raccolta',
			'collections.errorAddingToCollection' => 'Impossibile aggiungere l\'elemento alla raccolta',
			'collections.created' => 'Raccolta creata',
			'collections.removeFromCollection' => 'Rimuovi dalla raccolta',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Rimuovere "${title}" da questa raccolta?',
			'collections.removedFromCollection' => 'Elemento rimosso dalla raccolta',
			'collections.removeFromCollectionFailed' => 'Impossibile rimuovere dalla raccolta',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Errore durante la rimozione dell\'elemento dalla raccolta: ${error}',
			'collections.searchCollections' => 'Cerca raccolte...',
			'playlists.title' => 'Playlist',
			'playlists.playlist' => 'Playlist',
			'playlists.noPlaylists' => 'Nessuna playlist trovata',
			'playlists.create' => 'Crea playlist',
			'playlists.playlistName' => 'Nome playlist',
			'playlists.enterPlaylistName' => 'Inserisci nome playlist',
			'playlists.delete' => 'Elimina playlist',
			'playlists.removeItem' => 'Rimuovi dalla playlist',
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
			'playlists.searchPlaylists' => 'Cerca playlist...',
			'playlists.errorCreating' => 'Impossibile creare la playlist',
			'playlists.errorDeleting' => 'Impossibile eliminare la playlist',
			'playlists.errorLoading' => 'Impossibile caricare le playlist',
			'playlists.errorAdding' => 'Impossibile aggiungere l\'elemento alla playlist',
			'playlists.errorReordering' => 'Impossibile riordinare l\'elemento della playlist',
			'playlists.errorRemoving' => 'Impossibile rimuovere l\'elemento dalla playlist',
			'music.goToAlbum' => 'Vai all\'album',
			'music.goToArtist' => 'Vai all\'artista',
			'music.instantMix' => 'Mix istantaneo',
			'music.playNext' => 'Riproduci come prossimo',
			'music.addToQueue' => 'Aggiungi alla coda',
			'music.discNumber' => ({required Object n}) => 'Disco ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${n} brano', other: '${n} brani', ), 
			'music.nowPlaying' => 'In riproduzione',
			'music.playingFrom' => ({required Object title}) => 'Riproduzione da ${title}',
			'music.queue' => 'Coda',
			'music.clearQueue' => 'Svuota la coda',
			'music.lyrics' => 'Testo',
			'music.noLyrics' => 'Nessun testo disponibile',
			'music.sleepTimer' => 'Timer di spegnimento',
			'music.sleepTimerEndOfTrack' => 'Fine del brano',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minuti',
			'music.stopPlayback' => 'Interrompi riproduzione',
			'music.previousTrack' => 'Brano precedente',
			'music.nextTrack' => 'Brano successivo',
			'music.repeat' => 'Ripeti',
			'music.repeatAll' => 'Ripeti tutto',
			'music.repeatOne' => 'Ripeti il brano',
			'watchTogether.title' => 'Guarda insieme',
			'watchTogether.description' => 'Guarda contenuti in sincronia con amici e familiari',
			'watchTogether.createSession' => 'Crea sessione',
			'watchTogether.creating' => 'Creazione...',
			'watchTogether.joinSession' => 'Partecipa a una sessione',
			'watchTogether.joining' => 'Connessione...',
			'watchTogether.controlMode' => 'Modalità di controllo',
			'watchTogether.controlModeQuestion' => 'Chi può controllare la riproduzione?',
			'watchTogether.hostOnly' => 'Solo l\'host',
			'watchTogether.anyone' => 'Tutti',
			'watchTogether.hostingSession' => 'Stai ospitando la sessione',
			'watchTogether.inSession' => 'Sessione in corso',
			'watchTogether.sessionCode' => 'Codice della sessione',
			'watchTogether.openSessionControls' => 'Apri i controlli della sessione di Guarda insieme',
			'watchTogether.copySessionCode' => 'Copia il codice della sessione',
			'watchTogether.hostControlsPlayback' => 'L\'host controlla la riproduzione',
			'watchTogether.anyoneCanControl' => 'Tutti possono controllare la riproduzione',
			'watchTogether.hostControls' => 'L\'host controlla',
			'watchTogether.anyoneControls' => 'Tutti possono controllare',
			'watchTogether.participants' => 'Partecipanti',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Sei l\'host',
			'watchTogether.watchingWithOthers' => 'In visione con altri partecipanti',
			'watchTogether.endSession' => 'Termina la sessione',
			'watchTogether.leaveSession' => 'Abbandona la sessione',
			'watchTogether.endSessionQuestion' => 'Terminare la sessione?',
			'watchTogether.leaveSessionQuestion' => 'Abbandonare la sessione?',
			'watchTogether.endSessionConfirm' => 'Questo terminerà la sessione per tutti i partecipanti.',
			'watchTogether.leaveSessionConfirm' => 'Sarai rimosso dalla sessione.',
			'watchTogether.endSessionConfirmOverlay' => 'Questo terminerà la sessione di visione per tutti i partecipanti.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Sarai disconnesso dalla sessione di visione.',
			'watchTogether.end' => 'Termina',
			'watchTogether.leave' => 'Abbandona',
			'watchTogether.syncing' => 'Sincronizzazione...',
			'watchTogether.joinWatchSession' => 'Partecipa alla sessione di visione',
			'watchTogether.enterCodeHint' => 'Inserisci codice di 5 caratteri',
			'watchTogether.pasteFromClipboard' => 'Incolla dagli appunti',
			'watchTogether.pleaseEnterCode' => 'Inserisci un codice della sessione',
			'watchTogether.codeMustBe5Chars' => 'Il codice della sessione deve contenere 5 caratteri',
			'watchTogether.joinInstructions' => 'Inserisci il codice della sessione dell\'host per partecipare.',
			'watchTogether.failedToCreate' => 'Impossibile creare la sessione',
			'watchTogether.failedToJoin' => 'Impossibile unirsi alla sessione',
			'watchTogether.sessionCodeCopied' => 'Codice della sessione copiato negli appunti',
			'watchTogether.relayUnreachable' => 'Il server relay non è raggiungibile. Eventuali blocchi dell\'ISP potrebbero impedire l\'uso di Guarda insieme.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.reconnectingToHost' => 'Riconnessione all\'host...',
			'watchTogether.currentPlayback' => 'Riproduzione corrente',
			'watchTogether.joinCurrentPlayback' => 'Unisciti alla riproduzione corrente',
			'watchTogether.joinCurrentPlaybackDescription' => 'Torna a ciò che l\'host sta guardando in questo momento',
			'watchTogether.failedToOpenCurrentPlayback' => 'Impossibile aprire la riproduzione corrente',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} si è unito',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} se ne è andato',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} ha messo in pausa',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} ha ripreso',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} ha cambiato la posizione di riproduzione',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} è in buffering',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} usa una versione precedente dell\'app — sincronizzazione non disponibile',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Ripresa senza ${name}',
			'watchTogether.waitingForParticipants' => 'In attesa che gli altri carichino...',
			'watchTogether.waitingForName' => ({required Object name}) => 'In attesa di ${name}...',
			'watchTogether.recentRooms' => 'Stanze usate di recente',
			'watchTogether.renameRoom' => 'Rinomina stanza',
			'watchTogether.removeRoom' => 'Rimuovi',
			'watchTogether.guestSwitchUnavailable' => 'Impossibile cambiare — server non disponibile per la sincronizzazione',
			'watchTogether.guestSwitchFailed' => 'Impossibile cambiare — contenuto non trovato su questo server',
			'downloads.title' => 'Download',
			'downloads.manage' => 'Gestisci',
			'downloads.tvShows' => 'Serie TV',
			'downloads.movies' => 'Film',
			'downloads.music' => 'Musica',
			'downloads.tracksQueued' => ({required Object count}) => '${count} brani in coda per il download',
			'downloads.noDownloads' => 'Ancora nessun download',
			'downloads.noDownloadsDescription' => 'I contenuti scaricati appariranno qui per la visualizzazione offline',
			'downloads.downloadNow' => 'Scarica',
			'downloads.deleteDownload' => 'Elimina il download',
			'downloads.retryDownload' => 'Riprova il download',
			'downloads.downloadQueued' => 'Download in coda',
			'downloads.downloadResumed' => 'Download ripreso',
			'downloads.serverErrorBitrate' => 'Errore server: il file può superare il limite di bitrate remoto',
			'downloads.storageFull' => 'I download sono stati interrotti perché lo spazio di archiviazione del dispositivo è esaurito. Libera spazio e riprova.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodi in coda per il download',
			'downloads.downloadDeleted' => 'Download eliminato',
			'downloads.deleteConfirm' => ({required Object title}) => 'Eliminare "${title}" da questo dispositivo?',
			'downloads.cancelledDownloadTitle' => 'Download annullato',
			'downloads.cancelledDownloadMessage' => 'Questo download è stato annullato. Cosa vuoi fare?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Tutti gli episodi sono già stati scaricati',
			'downloads.resumeDownload' => 'Riprendi il download',
			'downloads.cancelledDownload' => 'Download annullato',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (sincronizzazione ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} scaricato — fai clic per completare',
			'downloads.partialDownloadClickToComplete' => 'Scaricato parzialmente — fai clic per completare',
			'downloads.deleting' => 'Eliminazione...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Eliminazione di ${title}... (${current} di ${total})',
			'downloads.queuedTooltip' => 'In coda',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'In coda: ${files}',
			'downloads.downloadingTooltip' => 'Download in corso...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Download di ${files}',
			'downloads.noDownloadsTree' => 'Nessun download',
			'downloads.pauseAll' => 'Metti tutto in pausa',
			'downloads.resumeAll' => 'Riprendi tutto',
			'downloads.deleteAll' => 'Elimina tutto',
			'downloads.selectVersion' => 'Seleziona la versione',
			'downloads.allEpisodes' => 'Tutti gli episodi',
			'downloads.unwatchedOnly' => 'Solo non visti',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Prossimi ${count} episodi non visti',
			'downloads.customAmount' => 'Quantità personalizzata...',
			'downloads.includeSpecials' => 'Includi gli speciali',
			'downloads.howManyEpisodes' => 'Quanti episodi?',
			'downloads.invalidEpisodeCount' => 'Inserisci un numero di episodi valido.',
			'downloads.keepSynced' => 'Mantieni sincronizzato',
			'downloads.downloadOnce' => 'Scarica una volta',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Mantieni ${count} episodi non visti',
			'downloads.editSyncRule' => 'Modifica regola di sincronizzazione',
			'downloads.removeSyncRule' => 'Rimuovi regola di sincronizzazione',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Interrompere la sincronizzazione di "${title}"? Gli episodi scaricati verranno mantenuti.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regola di sincronizzazione creata — ${count} episodi non visti mantenuti',
			'downloads.syncRuleUpdated' => 'Regola di sincronizzazione aggiornata',
			'downloads.syncRuleRemoved' => 'Regola di sincronizzazione rimossa',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} nuovi episodi sincronizzati per ${title}',
			'downloads.activeSyncRules' => 'Regole di sincronizzazione',
			'downloads.noSyncRules' => 'Nessuna regola di sincronizzazione',
			'downloads.manageSyncRule' => 'Gestisci sincronizzazione',
			'downloads.editEpisodeCount' => 'Numero di episodi',
			'downloads.editSyncFilter' => 'Filtro di sincronizzazione',
			'downloads.syncAllItems' => 'Sincronizzazione di tutti gli elementi',
			'downloads.syncUnwatchedItems' => 'Sincronizzazione degli elementi non visti',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponibile',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Accesso richiesto',
			'downloads.syncRuleNotAvailableForProfile' => 'Non disponibile per il profilo attuale',
			'downloads.syncRuleUnknownServer' => 'Server sconosciuto',
			'downloads.syncRuleListCreated' => 'Regola di sincronizzazione creata',
			'downloads.backgroundWarning.bannerBlocked' => 'I download si interromperanno quando esci dall’app',
			'downloads.backgroundWarning.bannerDegraded' => 'I download in background potrebbero essere limitati',
			'downloads.backgroundWarning.bannerAction' => 'Dettagli',
			'downloads.backgroundWarning.sheetTitle' => 'I download in background sono bloccati',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'I download in background potrebbero essere limitati',
			'downloads.backgroundWarning.sheetIntro' => 'Android impedisce a Plezy di scaricare in modo affidabile in background.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Il dispositivo limita i momenti in cui Plezy può scaricare in background.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'L’uso in background di Plezy è limitato. Nelle impostazioni della batteria o dell’uso in background, seleziona «Senza restrizioni».',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android ha messo Plezy in uno stato di standby con restrizioni. Imposta l’uso della batteria su «Senza restrizioni».',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Le notifiche dei download sono disattivate, quindi l’avanzamento e i controlli potrebbero non essere disponibili.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Le notifiche sono disattivate. Su Android 13 o versioni successive sono necessarie per i download prolungati in background.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Il Risparmio dati è attivo e blocca i download in background tramite dati mobili. I download dovrebbero comunque funzionare su Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'I download si sono interrotti più volte mentre Plezy era in background. Controlla le impostazioni della batteria o dell’uso in background di Plezy.',
			'downloads.backgroundWarning.openSettings' => 'Apri le impostazioni',
			'downloads.backgroundWarning.stillNotWorking' => 'Guida specifica per il dispositivo',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Consulta la procedura per il tuo dispositivo oppure invia un log da Impostazioni › Visualizza i log se il problema persiste.',
			'downloads.backgroundWarning.dialogTitle' => 'I download potrebbero non terminare',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Scarica comunque',
			'downloads.backgroundWarning.dialogFixFirst' => 'Risolvi prima',
			'downloads.backgroundWarning.statusTile' => 'Download in background',
			'downloads.backgroundWarning.statusOk' => 'Esecuzione in background consentita',
			'downloads.backgroundWarning.statusBlocked' => 'Bloccati dalle impostazioni di sistema',
			'downloads.backgroundWarning.statusDegraded' => 'Limitati dalle impostazioni di sistema',
			'downloads.backgroundWarning.statusUnknown' => 'Non ancora verificato',
			'downloads.backgroundWarning.settingsUnavailable' => 'Impossibile aprire le impostazioni di sistema su questo dispositivo',
			'downloads.backgroundWarning.linkUnavailable' => 'Impossibile aprire dontkillmyapp.com su questo dispositivo',
			'shaders.title' => 'Shader',
			'shaders.noShaderDescription' => 'Nessun miglioramento video',
			'shaders.nvscalerDescription' => 'Ridimensionamento NVIDIA per video più nitido',
			'shaders.artcnnVariantNeutral' => 'Neutro',
			'shaders.artcnnVariantDenoise' => 'Riduzione rumore',
			'shaders.artcnnVariantDenoiseSharpen' => 'Riduzione rumore + nitidezza',
			'shaders.qualityFast' => 'Veloce',
			'shaders.qualityHQ' => 'Alta qualità',
			'shaders.mode' => 'Modalità',
			'shaders.importShader' => 'Importa shader',
			'shaders.customShaderDescription' => 'Shader GLSL personalizzato',
			'shaders.shaderImported' => 'Shader importato',
			'shaders.shaderImportFailed' => 'Impossibile importare lo shader',
			'shaders.deleteShader' => 'Elimina shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Eliminare "${name}"?',
			'companionRemote.title' => 'Telecomando',
			'companionRemote.connectedTo' => ({required Object name}) => 'Connesso a ${name}',
			'companionRemote.unknownDevice' => 'Dispositivo sconosciuto',
			'companionRemote.session.startingServer' => 'Avvio del server remoto...',
			'companionRemote.session.hostAddress' => 'Indirizzo host',
			'companionRemote.session.connected' => 'Connesso',
			'companionRemote.session.serverRunning' => 'Server remoto attivo',
			'companionRemote.session.serverStopped' => 'Server remoto arrestato',
			'companionRemote.session.serverRunningDescription' => 'I dispositivi mobili della tua rete possono connettersi a questa app',
			'companionRemote.session.serverStoppedDescription' => 'Avvia il server per consentire ai dispositivi mobili di connettersi',
			'companionRemote.session.usePhoneToControl' => 'Usa il tuo dispositivo mobile per controllare questa app',
			'companionRemote.session.startServer' => 'Avvia server',
			'companionRemote.session.stopServer' => 'Arresta server',
			'companionRemote.session.minimize' => 'Riduci',
			'companionRemote.pairing.discoveryDescription' => 'I dispositivi Plezy con lo stesso account Plex appaiono qui',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Connessione...',
			'companionRemote.pairing.searchingForDevices' => 'Ricerca dispositivi...',
			'companionRemote.pairing.noDevicesFound' => 'Nessun dispositivo trovato nella tua rete',
			'companionRemote.pairing.noDevicesHint' => 'Apri Plezy sul computer e usa la stessa rete Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dispositivi disponibili',
			'companionRemote.pairing.manualConnection' => 'Connessione manuale',
			'companionRemote.pairing.cryptoInitFailed' => 'Impossibile avviare la connessione sicura. Accedi prima a Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Inserisci l\'indirizzo host',
			'companionRemote.pairing.validationHostFormat' => 'Il formato deve essere IP:porta (es. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tempo scaduto per la connessione. Usa la stessa rete su entrambi i dispositivi.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo non trovato. Assicurati che Plezy sia in esecuzione sull\'host.',
			'companionRemote.pairing.authFailed' => 'Autenticazione non riuscita. Entrambi i dispositivi devono usare lo stesso account Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Connessione non riuscita: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Vuoi disconnetterti dalla sessione remota?',
			'companionRemote.remote.reconnecting' => 'Riconnessione...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativo ${current} di 5',
			'companionRemote.remote.retryNow' => 'Riprova ora',
			'companionRemote.remote.tabRemote' => 'Telecomando',
			'companionRemote.remote.tabPlay' => 'Riproduci',
			'companionRemote.remote.tabMore' => 'Altro',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Navigazione',
			'companionRemote.remote.tabDiscover' => 'Esplora',
			'companionRemote.remote.tabLibraries' => 'Librerie',
			'companionRemote.remote.tabSearch' => 'Cerca',
			'companionRemote.remote.tabDownloads' => 'Download',
			'companionRemote.remote.tabSettings' => 'Impostazioni',
			'companionRemote.remote.previous' => 'Precedente',
			'companionRemote.remote.playPause' => 'Riproduci/Pausa',
			'companionRemote.remote.next' => 'Successivo',
			'companionRemote.remote.seekBack' => 'Indietro',
			'companionRemote.remote.stop' => 'Interrompi',
			'companionRemote.remote.seekForward' => 'Avanti',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Abbassa',
			'companionRemote.remote.volumeUp' => 'Alza',
			'companionRemote.remote.fullscreen' => 'Schermo intero',
			'companionRemote.remote.subtitles' => 'Sottotitoli',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Cerca sul computer...',
			'companionRemote.errors.noNetworkInterface' => 'Nessuna interfaccia di rete trovata',
			'companionRemote.errors.authenticationFailed' => 'Autenticazione non riuscita',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Impossibile avviare il server remoto: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Impossibile inviare il comando remoto: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Tempo scaduto durante la partecipazione alla sessione',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Impossibile connettersi a qualsiasi indirizzo',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Connessione persa dopo ${attempts} tentativi',
			'companionRemote.errors.connectionLost' => 'Connessione persa',
			'videoSettings.playbackSpeed' => 'Velocità di riproduzione',
			'videoSettings.normalSpeed' => 'Normale',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Attivo (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Timer di spegnimento',
			'videoSettings.audioSync' => 'Sincronizzazione audio',
			'videoSettings.subtitleSync' => 'Sincronizzazione sottotitoli',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Uscita audio',
			'videoSettings.performanceOverlay' => 'Overlay prestazioni',
			'videoSettings.audioPassthrough' => 'Passthrough audio',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Audio spaziale',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioNormalization' => 'Normalizza il volume',
			'videoSettings.audioDownmix' => 'Downmix in stereo',
			'performanceOverlay.color' => 'Colore',
			'performanceOverlay.performance' => 'Prestazioni',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decoder',
			'performanceOverlay.rawDecoder' => 'Decoder raw',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.aspect' => 'Proporzioni',
			'performanceOverlay.rotation' => 'Rotazione',
			'performanceOverlay.dvSource' => 'Sorgente DV',
			'performanceOverlay.dvPath' => 'Percorso DV',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Frequenza camp.',
			'performanceOverlay.pixelFormat' => 'Formato pixel',
			'performanceOverlay.hwFormat' => 'Formato HW',
			'performanceOverlay.matrix' => 'Matrice',
			'performanceOverlay.primaries' => 'Colori primari',
			'performanceOverlay.transfer' => 'Trasferimento',
			'performanceOverlay.renderFps' => 'FPS rendering',
			'performanceOverlay.displayFps' => 'FPS display',
			'performanceOverlay.avSync' => 'Sync A/V',
			'performanceOverlay.dropped' => 'Scartati',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'Media DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Media camp. DV',
			'performanceOverlay.maxLuma' => 'Luma max',
			'performanceOverlay.minLuma' => 'Luma min',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache usata',
			'performanceOverlay.cacheLimit' => 'Limite cache',
			'performanceOverlay.speed' => 'Velocità',
			'performanceOverlay.player' => 'Lettore',
			'performanceOverlay.memory' => 'Memoria',
			'performanceOverlay.uiFps' => 'FPS UI',
			'externalPlayer.title' => 'Lettore esterno',
			'externalPlayer.useExternalPlayer' => 'Usa un lettore esterno',
			'externalPlayer.useExternalPlayerDescription' => 'Apri i video in un\'altra app',
			'externalPlayer.selectPlayer' => 'Seleziona il lettore',
			'externalPlayer.customPlayers' => 'Lettori personalizzati',
			'externalPlayer.systemDefault' => 'Predefinito di sistema',
			'externalPlayer.addCustomPlayer' => 'Aggiungi lettore personalizzato',
			'externalPlayer.playerName' => 'Nome del lettore',
			'externalPlayer.playerNameHint' => 'Il mio lettore',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nome pacchetto',
			'externalPlayer.playerUrlScheme' => 'Schema URL',
			'externalPlayer.off' => 'Disattivato',
			'externalPlayer.launchFailed' => 'Impossibile aprire il lettore esterno',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} non è installato',
			'externalPlayer.playInExternalPlayer' => 'Riproduci nel lettore esterno',
			'metadataEdit.editMetadata' => 'Modifica...',
			'metadataEdit.screenTitle' => 'Modifica metadati',
			'metadataEdit.basicInfo' => 'Informazioni di base',
			'metadataEdit.artwork' => 'Immagini',
			'metadataEdit.advancedSettings' => 'Impostazioni avanzate',
			'metadataEdit.title' => 'Titolo',
			'metadataEdit.sortTitle' => 'Titolo di ordinamento',
			'metadataEdit.originalTitle' => 'Titolo originale',
			'metadataEdit.releaseDate' => 'Data di uscita',
			'metadataEdit.contentRating' => 'Classificazione per età',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Trama',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Sfondo',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Immagine quadrata',
			'metadataEdit.selectPoster' => 'Seleziona poster',
			'metadataEdit.selectBackground' => 'Seleziona sfondo',
			'metadataEdit.selectLogo' => 'Seleziona logo',
			'metadataEdit.selectSquareArt' => 'Seleziona immagine quadrata',
			'metadataEdit.fromUrl' => 'Da URL',
			'metadataEdit.uploadFile' => 'Carica file',
			'metadataEdit.enterImageUrl' => 'Inserisci URL immagine',
			'metadataEdit.imageUrl' => 'URL immagine',
			'metadataEdit.metadataUpdated' => 'Metadati aggiornati correttamente',
			'metadataEdit.metadataUpdateFailed' => 'Impossibile aggiornare i metadati',
			'metadataEdit.artworkUpdated' => 'Immagini aggiornate',
			'metadataEdit.artworkUpdateFailed' => 'Impossibile aggiornare le immagini',
			'metadataEdit.noArtworkAvailable' => 'Nessuna immagine disponibile',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opzione immagine ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opzione immagine ${index}, selezionata',
			'metadataEdit.notSet' => 'Non impostato',
			'metadataEdit.libraryDefault' => 'Predefinito della libreria',
			'metadataEdit.accountDefault' => 'Predefinito dell\'account',
			'metadataEdit.seriesDefault' => 'Predefinito della serie',
			'metadataEdit.episodeSorting' => 'Ordinamento episodi',
			'metadataEdit.oldestFirst' => 'Più vecchi prima',
			'metadataEdit.newestFirst' => 'Più recenti prima',
			'metadataEdit.keep' => 'Conserva',
			'metadataEdit.allEpisodes' => 'Tutti gli episodi',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episodi più recenti',
			'metadataEdit.latestEpisode' => 'Episodio più recente',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episodi aggiunti negli ultimi ${count} giorni',
			'metadataEdit.deleteAfterPlaying' => 'Elimina episodi dopo la riproduzione',
			'metadataEdit.never' => 'Mai',
			'metadataEdit.afterADay' => 'Dopo un giorno',
			'metadataEdit.afterAWeek' => 'Dopo una settimana',
			'metadataEdit.afterAMonth' => 'Dopo un mese',
			'metadataEdit.onNextRefresh' => 'Al prossimo aggiornamento',
			'metadataEdit.seasons' => 'Stagioni',
			'metadataEdit.show' => 'Mostra',
			'metadataEdit.hide' => 'Nascondi',
			'metadataEdit.episodeOrdering' => 'Ordine episodi',
			'metadataEdit.tmdbAiring' => 'The Movie Database (ordine di trasmissione)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (ordine di trasmissione)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (ordine assoluto)',
			'metadataEdit.metadataLanguage' => 'Lingua dei metadati',
			'metadataEdit.useOriginalTitle' => 'Usa il titolo originale',
			'metadataEdit.preferredAudioLanguage' => 'Lingua audio preferita',
			'metadataEdit.preferredSubtitleLanguage' => 'Lingua dei sottotitoli preferita',
			'metadataEdit.subtitleMode' => 'Modalità di selezione automatica dei sottotitoli',
			'metadataEdit.manuallySelected' => 'Selezionato manualmente',
			'metadataEdit.shownWithForeignAudio' => 'Mostrati con audio straniero',
			'metadataEdit.alwaysEnabled' => 'Sempre attivo',
			'metadataEdit.tags' => 'Tag',
			'metadataEdit.addTag' => 'Aggiungi tag',
			'metadataEdit.genre' => 'Genere',
			'metadataEdit.director' => 'Regista',
			'metadataEdit.writer' => 'Sceneggiatore',
			'metadataEdit.producer' => 'Produttore',
			'metadataEdit.country' => 'Paese',
			'metadataEdit.collection' => 'Raccolta',
			'metadataEdit.label' => 'Etichetta',
			'metadataEdit.style' => 'Stile',
			'metadataEdit.mood' => 'Atmosfera',
			'matchScreen.match' => 'Abbina...',
			'matchScreen.fixMatch' => 'Correggi abbinamento...',
			'matchScreen.unmatch' => 'Rimuovi abbinamento',
			'matchScreen.unmatchConfirm' => 'Rimuovere questo abbinamento? Plex considererà l\'elemento non abbinato finché non verrà eseguito un nuovo abbinamento.',
			'matchScreen.unmatchSuccess' => 'Abbinamento rimosso',
			'matchScreen.unmatchFailed' => 'Rimozione dell\'abbinamento non riuscita',
			'matchScreen.matchApplied' => 'Abbinamento applicato',
			'matchScreen.matchFailed' => 'Applicazione dell\'abbinamento non riuscita',
			'matchScreen.titleHint' => 'Titolo',
			'matchScreen.yearHint' => 'Anno',
			'matchScreen.search' => 'Cerca',
			'matchScreen.noMatchesFound' => 'Nessun risultato',
			'serverTasks.title' => 'Attività del server',
			'serverTasks.failedToLoad' => 'Impossibile caricare le attività',
			'serverTasks.noTasks' => 'Nessuna attività in corso',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Connesso',
			'trakt.connectedAs' => ({required Object username}) => 'Connesso come @${username}',
			'trakt.disconnectConfirm' => 'Disconnettere l\'account Trakt?',
			'trakt.disconnectConfirmBody' => 'Plezy smetterà di inviare eventi a Trakt. Puoi riconnetterti quando vuoi.',
			'trakt.scrobble' => 'Scrobbling in tempo reale',
			'trakt.scrobbleDescription' => 'Invia eventi di riproduzione, pausa e arresto a Trakt durante la riproduzione.',
			'trakt.watchedSync' => 'Sincronizza lo stato di visione',
			'trakt.watchedSyncDescription' => 'Quando contrassegni un elemento come visto in Plezy, viene contrassegnato come visto anche su Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Connetti Seerr',
			'seerr.serverUrl' => 'URL del server',
			'seerr.serverUrlHelper' => 'L\'indirizzo della tua istanza Seerr',
			'seerr.checkServer' => 'Continua',
			'seerr.signInWithJellyfin' => 'Accedi con Jellyfin',
			'seerr.signInWithEmby' => 'Accedi con Emby',
			'seerr.signInWithLocal' => 'Usa un account locale',
			'seerr.email' => 'Email',
			'seerr.noSignInMethods' => 'Questa istanza Seerr non offre alcun metodo di accesso supportato da Plezy.',
			'seerr.instance' => 'Istanza',
			'seerr.disconnectConfirm' => 'Disconnettere Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy rimuoverà questa istanza Seerr. Potrai riconnetterla in qualsiasi momento.',
			'seerr.request' => 'Richiedi',
			'seerr.request4k' => 'Richiedi in 4K',
			'seerr.seasons' => 'Stagioni',
			'seerr.allSeasons' => 'Tutte le stagioni',
			'seerr.advancedOptions' => 'Avanzate',
			'seerr.destinationServer' => 'Server di destinazione',
			'seerr.qualityProfile' => 'Profilo di qualità',
			'seerr.rootFolder' => 'Cartella radice',
			'seerr.languageProfile' => 'Profilo della lingua',
			'seerr.requestSubmitted' => 'Richiesta inviata',
			'seerr.requestFailed' => ({required Object error}) => 'Richiesta non riuscita: ${error}',
			'seerr.requestsLoadFailed' => 'Impossibile caricare le opzioni di richiesta',
			'seerr.nothingToRequest' => 'Tutto è già disponibile o richiesto.',
			'seerr.statusAvailable' => 'Disponibile',
			'seerr.statusPartiallyAvailable' => 'Disponibile in parte',
			'seerr.statusRequested' => 'Richiesto',
			'seerr.statusProcessing' => 'In elaborazione',
			'services.title' => 'Servizi',
			'services.hubSubtitle' => 'Sincronizza i progressi di visione e richiedi nuovi titoli.',
			'services.notConnected' => 'Non connesso',
			'services.connectedAs' => ({required Object username}) => 'Connesso come @${username}',
			'services.scrobble' => 'Registra automaticamente i progressi',
			'services.scrobbleDescription' => 'Aggiorna la tua lista quando termini un episodio o un film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Disconnettere ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy smetterà di aggiornare ${service}. Riconnetti quando vuoi.',
			'services.connectFailed' => ({required Object service}) => 'Impossibile connettersi a ${service}. Riprova.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Attiva Plezy su ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Visita ${url} e inserisci questo codice:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Apri ${service} per attivare',
			'services.deviceCode.copyCode' => 'Copia il codice di attivazione',
			'services.deviceCode.waitingForAuthorization' => 'In attesa di autorizzazione…',
			'services.deviceCode.codeCopied' => 'Codice copiato',
			'services.oauthProxy.title' => ({required Object service}) => 'Accedi a ${service}',
			'services.oauthProxy.body' => 'Scansiona questo codice QR o apri l\'URL su qualsiasi dispositivo.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Apri ${service} per accedere',
			'services.oauthProxy.copyUrl' => 'Copia l\'URL di accesso',
			'services.oauthProxy.urlCopied' => 'URL copiato',
			'services.libraryFilter.title' => 'Filtro delle librerie',
			'services.libraryFilter.subtitleAllSyncing' => 'Sincronizzazione di tutte le librerie',
			'services.libraryFilter.subtitleNoneSyncing' => 'Nessuna sincronizzazione',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloccate',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} consentite',
			'services.libraryFilter.mode' => 'Modalità filtro',
			'services.libraryFilter.modeBlacklist' => 'Lista nera',
			'services.libraryFilter.modeWhitelist' => 'Lista bianca',
			'services.libraryFilter.modeHintBlacklist' => 'Sincronizza tutte le librerie tranne quelle selezionate qui sotto.',
			'services.libraryFilter.modeHintWhitelist' => 'Sincronizza solo le librerie selezionate qui sotto.',
			'services.libraryFilter.libraries' => 'Librerie',
			'services.libraryFilter.noLibraries' => 'Nessuna libreria disponibile',
			'addServer.addJellyfinTitle' => 'Aggiungi server Jellyfin',
			'addServer.serverUrls' => 'URL del server',
			'addServer.serverUrlsHelper' => 'Sono consentiti più URL, separati da virgole.',
			'addServer.findServer' => 'Trova il server',
			'addServer.searchingLocalServers' => 'Ricerca dei server Jellyfin locali...',
			'addServer.localServers' => 'Server Jellyfin locali',
			'addServer.username' => 'Nome utente',
			'addServer.password' => 'Password',
			'addServer.signIn' => 'Accedi',
			'addServer.change' => 'Modifica',
			'addServer.required' => 'Obbligatorio',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Impossibile raggiungere il server: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Accesso non riuscito: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect non riuscito: ${error}',
			'addServer.addPlexTitle' => 'Accedi con Plex',
			'addServer.pinExpired' => 'PIN scaduto prima dell\'accesso. Riprova.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Registrazione account non riuscita: ${error}',
			'addServer.enterJellyfinUrlError' => 'Inserisci l\'URL del tuo server Jellyfin',
			'addServer.addConnectionTitle' => 'Aggiungi connessione',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Aggiungi a ${name}',
			'addServer.signInWithPlexCard' => 'Accedi con Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorizza questo dispositivo. I server condivisi vengono aggiunti.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorizza un account Plex. Gli utenti Home diventano profili.',
			'addServer.connectToJellyfinCard' => 'Connettiti a Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Inserisci l\'URL del server, il nome utente e la password.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Accedi a un server Jellyfin. Verrà associato a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Prendi in prestito da un altro profilo',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Riutilizza la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.',
			_ => null,
		};
	}
}
