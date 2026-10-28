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
	@override late final _Translations$appIcon$it appIcon = _Translations$appIcon$it._(_root);
	@override late final _Translations$auth$it auth = _Translations$auth$it._(_root);
	@override late final _Translations$common$it common = _Translations$common$it._(_root);
	@override late final _Translations$screens$it screens = _Translations$screens$it._(_root);
	@override late final _Translations$update$it update = _Translations$update$it._(_root);
	@override late final _Translations$settings$it settings = _Translations$settings$it._(_root);
	@override late final _Translations$themeEditor$it themeEditor = _Translations$themeEditor$it._(_root);
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
	@override late final _Translations$accountPreferences$it accountPreferences = _Translations$accountPreferences$it._(_root);
	@override late final _Translations$discover$it discover = _Translations$discover$it._(_root);
	@override late final _Translations$errors$it errors = _Translations$errors$it._(_root);
	@override late final _Translations$libraries$it libraries = _Translations$libraries$it._(_root);
	@override late final _Translations$about$it about = _Translations$about$it._(_root);
	@override late final _Translations$serverSelection$it serverSelection = _Translations$serverSelection$it._(_root);
	@override late final _Translations$hubDetail$it hubDetail = _Translations$hubDetail$it._(_root);
	@override late final _Translations$logs$it logs = _Translations$logs$it._(_root);
	@override late final _Translations$startup$it startup = _Translations$startup$it._(_root);
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
	@override late final _Translations$cast$it cast = _Translations$cast$it._(_root);
	@override late final _Translations$automation$it automation = _Translations$automation$it._(_root);
	@override late final _Translations$notifications$it notifications = _Translations$notifications$it._(_root);
	@override late final _Translations$appAccess$it appAccess = _Translations$appAccess$it._(_root);
	@override late final _Translations$detail$it detail = _Translations$detail$it._(_root);
	@override late final _Translations$watchLink$it watchLink = _Translations$watchLink$it._(_root);
	@override late final _Translations$homeLayout$it homeLayout = _Translations$homeLayout$it._(_root);
	@override late final _Translations$platform$it platform = _Translations$platform$it._(_root);
	@override late final _Translations$universalMedia$it universalMedia = _Translations$universalMedia$it._(_root);
	@override late final _Translations$fileSources$it fileSources = _Translations$fileSources$it._(_root);
	@override late final _Translations$lending$it lending = _Translations$lending$it._(_root);
	@override late final _Translations$audiobook$it audiobook = _Translations$audiobook$it._(_root);
	@override late final _Translations$sourceSetup$it sourceSetup = _Translations$sourceSetup$it._(_root);
	@override late final _Translations$comics$it comics = _Translations$comics$it._(_root);
	@override late final _Translations$games$it games = _Translations$games$it._(_root);
	@override late final _Translations$deepLinks$it deepLinks = _Translations$deepLinks$it._(_root);
}

// Path: app
class _Translations$app$it extends Translations$app$en {
	_Translations$app$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$it extends Translations$appIcon$en {
	_Translations$appIcon$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icona dell\'app';
	@override String get defaultIcon => 'Predefinita';
	@override String get current => 'Icona attuale';
	@override String get locked => 'L’accesso a vita richiesto';
	@override String get lockedHint => 'Inizia il tuo tentativo di 7 giorni o disattivare PlezyNG per tutta la vita per utilizzare icone alternative.';
	@override String get changeFailed => 'Impossibile cambiare l\'icona dell\'app';
	@override String get launcherHint => 'La nuova icona appare nella schermata Home quando esci da PlezyNG.';
	@override String get tvLauncherHint => 'Il nuovo banner appare quando esci da PlezyNG. Android TV potrebbe continuare a mostrare quello precedente fino al riavvio del televisore.';
	@override late final _Translations$appIcon$names$it names = _Translations$appIcon$names$it._(_root);
	@override String get description => 'Scegli l\'icona mostrata dal lanciatore del dispositivo. le previsioni mostrano come appare ogni opzione.';
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
	@override String connectToMediaBrowser({required Object product}) => 'Connettiti a ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Usa Quick Connect';
	@override String get quickConnectInstructions => 'Apri Quick Connect in Jellyfin e inserisci questo codice.';
	@override String get quickConnectWaiting => 'In attesa di approvazione…';
	@override String get quickConnectCancel => 'Annulla';
	@override String get quickConnectExpired => 'Quick Connect scaduto. Riprova.';
	@override String get localDataRecoveryRequired => 'PlezyNG non è riuscito a recuperare in sicurezza i dati locali di accesso e delle riproduzioni in sospeso. Accedi di nuovo.';
	@override String get pinCheckRejected => 'La verifica del PIN Plex è stata rifiutata';
	@override String get connectToDirectPlex => 'Connessione al server locale Plex';
}

// Path: common
class _Translations$common$it extends Translations$common$en {
	_Translations$common$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annulla';
	@override String get save => 'Salva';
	@override String get close => 'Chiudi';
	@override String get closeMiniPlayer => 'Mini giocatore vicino';
	@override String get closeWorkspaceWindow => 'Finestra vicina';
	@override String get returnToFullView => 'Il ritorno alla vista completa';
	@override String get manageMediaSessions => 'Gestione delle sessioni di media';
	@override String get hideMediaSessions => 'Sessioni di media nascosti';
	@override String get mediaSessions => 'Sessioni di Media';
	@override String get mediaSessionsHint => 'Selezionare per portare una sessione in avanti.Parco nasconde la sua finestra ma la mantiene aperta.Ritorno lo apre in vista completa; vicino si conclude.';
	@override String get sessionInWorkspace => 'nel laboratorio';
	@override String get sessionParked => 'Parcheggiato';
	@override String get sessionFullscreen => 'schermo completo';
	@override String get switchToNextWindow => 'Swap con la finestra successiva';
	@override String get moveWindow => 'Move la finestra';
	@override String get finishMovingWindow => 'Finita la finestra in movimento';
	@override String get moveWindowHint => 'Long-press e tirare la finestra per spostarla. Questo controllo consente anche il movimento della chiave di pistola.';
	@override String get movingWindowHelp => 'Tracciare per muoversi · Aggiungere le chiavi · Entrare i salvatori · Cancelli di escape';
	@override String get resizeWindow => 'Ristrutturare la finestra';
	@override String get resizeWindowHint => 'Rimuovere questo manuale o utilizzare le chiavi della pistola per ripristinare la finestra.';
	@override String get workspaceWindowHint => 'Utilizzare il controllo di movimento o lunghi pressioni e tirare per muoversi.';
	@override String get workspacePaneHint => 'Selezionare questo pannello per focalizzarlo. utilizzare il suo controllo a schermo pieno per espandere.';
	@override String workspaceWindowLabel({required Object title}) => 'Finestra di sessione: ${title}';
	@override String get workspaceTitleHint => 'Selezionare per concentrarsi. spostare la barra di titolo per muoversi; utilizzare il pulsante a schermo pieno per espandere.';
	@override String get moveToSessionTray => 'Trasferimento alla sessione tray';
	@override String get moveToSessionTrayHint => 'La sessione è disponibile senza mostrare la sua finestra.';
	@override String get closeSessionHint => 'Chiude questa finestra e conclude la sua sessione.';
	@override String get sideBySideLayout => 'Conversione a layout laterale';
	@override String get floatingWindows => 'Switch per fluttuare le finestre';
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
	@override String get options => 'Opzioni';
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
	@override late final _Translations$common$ratingSource$it ratingSource = _Translations$common$ratingSource$it._(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$it mediaKind = _Translations$common$mediaKind$it._(_root);
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
	@override String get supportDeveloper => 'Supporta PlezyNG';
	@override String get supportDeveloperDescription => 'Fai una donazione per sostenere lo sviluppo';
	@override String get lifetimeAccess => 'PlezyNG accesso a vita';
	@override String get language => 'Lingua';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aspetto';
	@override String get detailPage => 'Pagina dettagliata';
	@override String get themeSongsEnabled => 'Gioca canzoni di tema';
	@override String get themeSongsEnabledDescription => 'Gioca canzoni di tema disponibili mentre guarda i dettagli dei media.';
	@override String get themeSongVolume => 'Il volume della canzone';
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
	@override String get emberTheme => 'Brace';
	@override String get glacierTheme => 'Ghiacciaio';
	@override String get forestTheme => 'Foresta';
	@override String get plumTheme => 'Prugna';
	@override String get paperTheme => 'Carta';
	@override String get libraryDensity => 'Densità della libreria';
	@override String get displayScale => 'Scala di visualizzazione';
	@override String get compact => 'Compatta';
	@override String get comfortable => 'Comoda';
	@override String get gridSpacing => 'Spaziatura della griglia';
	@override String get gridSpacingTight => 'Ristretta';
	@override String get gridSpacingNormal => 'Normale';
	@override String get gridSpacingSpacious => 'Ampia';
	@override String get tvCornerSpotlightBackdrop => 'Sfondo in evidenza nell\'angolo';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostra l\'immagine in evidenza nell\'angolo in alto a destra anziché a schermo intero';
	@override String get viewMode => 'Modalità di visualizzazione';
	@override String get gridView => 'Griglia';
	@override String get listView => 'Elenco';
	@override String get showHeroSection => 'Mostra sezione in evidenza';
	@override String get showHomeBackdrop => 'Home Artica Artica Artico Artica Arta';
	@override String get showHomeBackdropDescription => 'Mostra grandi opere d\'arte dietro le linee di casa';
	@override String get contentScreensaverEnabled => 'ScreenSaver di contenuti';
	@override String get contentScreensaverEnabledDescription => 'Mostra l\'arte a schermo pieno dopo che l\'app è stata idle';
	@override String get contentScreensaverDelay => 'Inizia il screensaver dopo';
	@override String get contentScreensaverLibraries => 'Screensaver biblioteche';
	@override String get contentScreensaverLibrariesDescription => 'Scegli quali librerie forniscono le immagini per lo screensaver. Se non ne selezioni nessuna, verranno usate le immagini di tutte le librerie.';
	@override String get contentScreensaverAllLibraries => 'Tutte le biblioteche';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} biblioteche selezionate';
	@override String get contentScreensaverNoLibraries => 'Non sono disponibili biblioteche multimediali collegate.';
	@override String get contentScreensaverDismissHint => 'Premere qualsiasi pulsante o tappa per rimuovere';
	@override String get newEpisodeNotifications => 'Nuove notizie di episodio';
	@override String get newEpisodeNotificationsDescription => 'Allarme quando un nuovo episodio viene aggiunto a un show che si è catturato. controlla mentre Plezy è aperto.';
	@override String get continueWatchingRowSize => 'Continua a guardare la dimensione della linea';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} carte';
	@override String get rowSizeCompact => 'Compatta';
	@override String get rowSizeStandard => 'Standard';
	@override String get rowSizeLarge => 'Grande';
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
	@override String get showWatchedIndicators => 'Mostra indicatori di visione';
	@override String get showWatchedIndicatorsDescription => 'Mostra un segno di spunta su film, serie TV ed episodi già visti';
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
	@override String get playbackBuffer => 'Buffer di riproduzione';
	@override String get playbackBufferAuto => 'Auto (consigliato)';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extra grande';
	@override String get playbackBufferDescription => 'Bufferizza di più contro connessioni instabili. Limitato anche dalla dimensione del buffer.';
	@override String get streamBufferSize => 'Dimensioni Buffer';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Quanto video da caricare in avanti quando si gioca direttamente. i transcodi si fermeranno al buffer transcodico del server. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Rimpiazzare Playback Buffer quando impostato, cappellato a metà del limite di memoria dell\'app';
	@override String get streamBufferMegabytes => 'Megabiti';
	@override String get defaultQualityTitle => 'Qualità predefinita';
	@override String get cellularQualityTitle => 'Qualità predefinita sulla rete mobile';
	@override String get remoteQualityTitle => 'Qualità di Remote Streaming';
	@override String get remoteQualitySameAsDefault => 'Come la qualità default';
	@override String get cellularQualitySameAsDefault => 'Come la qualità predefinita';
	@override String get directPlayCoveredQuality => 'Riproduci i video più piccoli in qualità originale';
	@override String get directPlayCoveredQualityDescription => 'Riproduci direttamente i video già entro il limite di qualità invece di transcodificarli';
	@override String get videoCodecs => 'Codec video';
	@override String get videoCodecsDescription => 'Il server transcodifica i codec non selezionati';
	@override String get videoCodecsAlwaysAccepted => 'Sempre accettato';
	@override String get musicQualityTitle => 'Qualità musicale';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get subtitleStylingDescription => 'Personalizza l\'aspetto dei sottotitoli';
	@override String get smallSkipDuration => 'Salto breve';
	@override String get largeSkipDuration => 'Salto lungo';
	@override String get rewindOnResume => 'Riavvolgimento alla ripresa';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondo',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondi',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondi',
	);
	@override String get defaultSleepTimer => 'Timer spegnimento predefinito';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuti',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuti',
	);
	@override String get rememberTrackSelections => 'Ricorda la selezione delle tracce per ogni serie o film';
	@override String get chooseTracksBeforePlayback => 'Scegli audio e sottotitoli prima di riprodurre';
	@override String get chooseTracksBeforePlaybackDescription => 'Selezionare le tracce audio e sottotitoli prima che ogni video inizia.';
	@override String get alwaysShowSubtitlesOnDevice => 'Mostra sempre i sottotitoli su questo dispositivo';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Quando il server non ha alcun sottotitolo selezionato, selezionare una traccia localmente.';
	@override String get autoDownloadPreferredSubtitle => 'Il libro di Fethch mantiene i sottotitoli preferiti';
	@override String get autoDownloadPreferredSubtitleDescription => 'Selezionare un sottotitolo disponibile nella lingua preferita localmente. se non esiste, chiedi al server di ottenere uno quando supportato.';
	@override String get rememberTrackSelectionsDescription => 'Ricorda le scelte di audio e sottotitoli per ogni titolo';
	@override String get rememberTrackSelectionsBackendRule => 'Plex salva ogni scelta sul server per ogni file; Jellyfin attiva anche l\'opzione Ricorda selezioni dell\'account; Emby non è supportato';
	@override String get followServerTrackSelections => 'Usa le tracce selezionate sul server per ogni episodio';
	@override String get followServerTrackSelectionsDescription => 'Al cambio di episodio applica l\'audio e i sottotitoli selezionati sul server invece di mantenere la scelta corrente';
	@override String get resumeMusicOnLaunch => 'Ricorda la sessione musicale';
	@override String get resumeMusicOnLaunchDescription => 'All\'avvio dell\'app riapri l\'ultimo brano in pausa dal punto in cui era rimasto';
	@override String get showChapterMarkersOnTimeline => 'Mostra i marcatori dei capitoli sulla barra di avanzamento';
	@override String get showChapterMarkersOnTimelineDescription => 'Segmenta la barra di avanzamento ai confini dei capitoli';
	@override String get specialsOrdering => 'Speciali nell\'ordine degli episodi';
	@override String get specialsOrderingDescription => 'Dove vengono riprodotti gli speciali nell\'ordine di visione di una serie';
	@override String get specialsOrderingServer => 'Segui l\'ordine del server';
	@override String get specialsOrderingAirDate => 'Intercalati per data di trasmissione';
	@override String get specialsOrderingLast => 'Dopo le stagioni normali';
	@override String get clickVideoTogglesPlayback => 'Fai clic sul video per alternare riproduzione e pausa';
	@override String get clickVideoTogglesPlaybackDescription => 'Fai clic sul video per riprodurre o mettere in pausa anziché mostrare i controlli.';
	@override String get videoPlayerControls => 'Controlli del lettore video';
	@override String get keyboardShortcuts => 'Scorciatoie da tastiera';
	@override String get keyboardShortcutsDescription => 'Personalizza le scorciatoie da tastiera';
	@override String get videoPlayerNavigation => 'Navigazione del lettore video';
	@override String get videoPlayerNavigationDescription => 'Usa i tasti freccia per navigare nei controlli del lettore video';
	@override String get watchTogetherRelay => 'Relay di Guarda insieme';
	@override String get watchTogetherRelayDescription => 'Relay pubblici di Open Watch Party, se non ne imposti uno tuo';
	@override String get watchTogetherRelayHint => 'https://mio-relay.esempio.it';
	@override String get watchTogetherRelayInvalid => 'Inserisci un URL di base HTTP o HTTPS valido per il relay.';
	@override String get crashReporting => 'Segnalazione degli arresti anomali';
	@override String get crashReportingDescription => 'Invia segnalazioni sugli arresti anomali per contribuire a migliorare l\'app';
	@override String get debugLogging => 'Registrazione di debug';
	@override String get debugLoggingDescription => 'Abilita una registrazione dettagliata per la risoluzione dei problemi';
	@override String get viewLogs => 'Visualizza i log';
	@override String get viewLogsDescription => 'Visualizza i log dell\'applicazione';
	@override String get clearImageCache => 'Svuota cache immagini';
	@override String get clearImageCacheDescription => 'Svuota le immagini e le miniature memorizzate nella cache. Le immagini potrebbero caricarsi più lentamente finché non vengono scaricate di nuovo.';
	@override String get clearImageCacheSuccess => 'Cache immagini svuotata correttamente';
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
	@override String get importSettingsInvalidFile => 'Questo file non è un\'esportazione PlezyNG valida';
	@override String get importSettingsNoUser => 'Accedi prima di importare le impostazioni';
	@override String get cloudBackup => 'Cloud Backup di sicurezza';
	@override String get cloudBackupDescription => 'Esegui il backup delle impostazioni trasferibili a un indirizzo WebDAV tramite HTTPS. Le connessioni ai server e le credenziali restano su questo dispositivo.';
	@override String get cloudBackupUrl => 'WebDAV URL del file JSON';
	@override String get cloudBackupUsername => 'Nome utente';
	@override String get cloudBackupPassword => 'Password';
	@override String get cloudBackupSaved => 'Cloud backup destinazione salvata';
	@override String get cloudBackupNow => 'Ritorno adesso';
	@override String get cloudBackupComplete => 'Settings Backup upload';
	@override String get cloudBackupRestore => 'Ristrutturazione Backup';
	@override String get cloudBackupRestoreConfirm => 'Questo sostituirà le impostazioni portatili in questo dispositivo.';
	@override String get cloudBackupRestored => 'Impostazioni ripristinate dal cloud backup';
	@override String get shortcutsReset => 'Scorciatoie ripristinate alle impostazioni predefinite';
	@override String get resetShortcutsConfirm => 'Le scorciatoie personalizzate verranno sostituite con quelle predefinite. Continuare?';
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
	@override String get autoPlayAndSkip => 'Riproduzione automatica e salti';
	@override String get autoPlayNextEpisode => 'Riproduci automaticamente l\'episodio successivo';
	@override String get autoPlayNextEpisodeDescription => 'Avvia automaticamente l\'episodio successivo quando termina quello in riproduzione';
	@override String get shuffleStartsFromBeginning => 'La riproduzione casuale inizia dall\'inizio';
	@override String get shuffleStartsFromBeginningDescription => 'Avvia ogni episodio dall\'inizio durante la riproduzione casuale invece di riprenderlo';
	@override String get plexCinemaPreRoll => 'Utilizzare il server cinema intros';
	@override String get plexCinemaPreRollDescription => 'Gioca configurati Plex pre-roll o Jellyfin e Emby intros prima che un film inizia.';
	@override String get playNextCountdown => 'Conto alla rovescia del successivo';
	@override String get playNextCountdownImmediate => 'Riproduci subito';
	@override String get skipIntroMode => 'Salta intro';
	@override String get skipIntroModeOffDescription => 'Riproduci le intro normalmente senza pulsante di salto';
	@override String get skipIntroModeButtonDescription => 'Mostra un pulsante di salto quando inizia un\'intro';
	@override String get skipIntroModeAutoDescription => 'Salta automaticamente le intro dopo il ritardo indicato sotto';
	@override String get skipCreditsMode => 'Salta titoli di coda';
	@override String get skipCreditsModeOffDescription => 'Riproduci i titoli di coda normalmente senza pulsante di salto';
	@override String get skipCreditsModeButtonDescription => 'Mostra un pulsante di salto quando iniziano i titoli di coda';
	@override String get skipCreditsModeAutoDescription => 'Salta automaticamente i titoli di coda e riproduci l\'episodio successivo';
	@override String get skipAdsMode => 'Scopri gli annunci';
	@override String get skipAdsModeOffDescription => 'Gioca gli annunci rilevati normalmente senza un pulsante di scappamento';
	@override String get skipAdsModeButtonDescription => 'Mostra un pulsante di scappamento quando Plex rileva un annuncio';
	@override String get skipAdsModeAutoDescription => 'Scarica gli annunci rilevati automaticamente dopo il ritardo di seguito';
	@override String get musicPlayback => 'Il musicale playback';
	@override String get musicSweetFades => 'dolci fati';
	@override String get musicSweetFadesDescription => 'La musica è in arrivo quando Plex ha dati di rumore.';
	@override String get skipMarkerModeOff => 'Disattivato';
	@override String get skipMarkerModeButton => 'Mostra pulsante';
	@override String get skipMarkerModeAuto => 'Automatico';
	@override String get forceSkipMarkerFallback => 'Forza i marcatori di ripiego';
	@override String get forceSkipMarkerFallbackDescription => 'Usa i modelli dei titoli dei capitoli anche quando Plex dispone di marcatori';
	@override String get theIntroDbFallback => 'Utilizzare TheIntroDB come un fallback intro';
	@override String get theIntroDbFallbackDescription => 'Utilizzare le date della comunità solo quando il server non ha un intro marker.';
	@override String get autoSkipDelay => 'Ritardo del salto automatico';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Attendi ${seconds} secondi prima del salto automatico';
	@override String get introPattern => 'Modello del marcatore della sigla iniziale';
	@override String get introPatternDescription => 'Espressione regolare per individuare i marcatori della sigla iniziale nei titoli dei capitoli';
	@override String get creditsPattern => 'Modello del marcatore dei titoli di coda';
	@override String get creditsPatternDescription => 'Espressione regolare per individuare i marcatori dei titoli di coda nei titoli dei capitoli';
	@override String get prerolls => 'Prerotti';
	@override String get playPrerollsBeforeMovies => 'Gioca i preloli prima dei film';
	@override String get playPrerollsBeforeMoviesDescription => 'Gioca un clip casuale dalla tua selezione qui sotto prima di ogni film.';
	@override String get prerollLibrary => 'Libreria di Preroll';
	@override String get prerollLibraryNotSet => 'Non impostato';
	@override String get prerollLibraryNoneFound => 'Non sono state trovate biblioteche sui tuoi server.';
	@override String get prerollSelection => 'I preloni selezionati';
	@override String get prerollSelectionPickLibraryFirst => 'Scegli una biblioteca prima';
	@override String get prerollSelectionNoneSelected => 'Nessun preludio selezionato';
	@override String prerollSelectionCount({required Object count}) => '${count} selezionati';
	@override String get prerollItemPicker => 'Selezionare i preroli';
	@override String get prerollItemPickerLoadFailed => 'Non potevo caricare gli articoli da questa biblioteca.';
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
	@override String get autoDownloadContinueWatching => 'Auto-Download Continua a guardare';
	@override String get autoDownloadContinueWatchingDescription => 'Mantenere gli articoli sul vostro foglio di guardare continuo scaricati, e rimuoverli una volta che lasciano il foglio';
	@override String get downloadQuality => 'Scarica la qualità';
	@override String get downloadQualityDescription => 'Plex prepara una copia convertita nella sua scatola di download. Jellyfin e Emby transcode mentre il file scarica; trasferimenti interrotti potrebbero essere necessari per riavviare.';
	@override String get askDownloadQualityEachTime => 'Scegliere la qualità per ogni download';
	@override String get askDownloadQualityEachTimeDescription => 'Mostra il picker di qualità prima di scorrere ogni download video';
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
	@override String get companionRemoteServerStartFailed => 'Impossibile avviare il server del telecomando';
	@override String get companionRemoteServerStopFailed => 'Impossibile arrestare il server del telecomando';
	@override String get autoPip => 'Picture-in-Picture automatica';
	@override String get autoPipDescription => 'Attiva automaticamente la modalità Picture-in-Picture quando esci dall\'app durante la riproduzione';
	@override String get matchContentFrameRate => 'Adatta la frequenza dei fotogrammi';
	@override String get matchContentFrameRateDescription => 'Adatta la frequenza di aggiornamento dello schermo al contenuto video';
	@override String get matchContentResolution => 'Adatta alla risoluzione del contenuto';
	@override String get matchContentResolutionDescription => 'Passa lo schermo alla risoluzione nativa del video, così è la TV a occuparsi dell\'upscaling. Durante la riproduzione vengono ridimensionati anche menu e sottotitoli';
	@override String get matchRefreshRate => 'Adatta la frequenza di aggiornamento';
	@override String get matchRefreshRateDescription => 'Adatta la frequenza di aggiornamento dello schermo in modalità a schermo intero';
	@override String get matchDynamicRange => 'Adatta la gamma dinamica';
	@override String get matchDynamicRangeDescription => 'Attiva l\'HDR per i contenuti HDR, quindi torna all\'SDR';
	@override String get displaySwitchDelay => 'Ritardo del cambio di modalità dello schermo';
	@override String get tunneledPlayback => 'Riproduzione con tunneling';
	@override String get tunneledPlaybackDescription => 'Usa il tunneling video. Disattivalo se durante la riproduzione HDR lo schermo rimane nero o il movimento scatta.';
	@override String get audioPassthrough => 'Passthrough audio';
	@override String get audioPassthroughDescription => 'Invia l\'audio Dolby/DTS al ricevitore o al televisore senza ricodificarlo, preservando l\'audio surround. Disattiva questa opzione se non senti alcun suono.';
	@override String get audioPassthroughDescriptionApple => 'Usa il decoder Dolby nativo di Apple per Dolby Digital Plus, incluso Atmos. DTS e TrueHD vengono comunque riprodotti come PCM multicanale. Disattiva questa opzione se non senti alcun suono.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Usa il decoder Dolby nativo di Apple per Dolby Digital Plus, incluso Atmos. Su iOS, iPadOS e tvOS 26 o versioni successive, TrueHD Atmos e DTS:X vengono riprodotti come audio spaziale. Le altre tracce DTS e TrueHD vengono riprodotte come PCM multicanale. Disattiva questa opzione se non senti alcun suono.';
	@override String get audioPassthroughOverriddenByNormalization => 'Disattivato mentre la normalizzazione del volume è attiva';
	@override String get audioChannelLimit => 'Canali audio';
	@override String get audioChannelLimitDescription => 'Esegui il downmix dell\'audio decodificato per altoparlanti, cuffie o configurazioni HDMI che non possono riprodurre tutti i canali';
	@override String get audioChannelLimitOriginal => 'Originale';
	@override String get audioChannelLimitOriginalDescription => 'Riproduci tutti i canali della traccia';
	@override String get audioChannelLimitSurround51 => 'Fino a 5.1';
	@override String get audioChannelLimitSurround51Description => 'Esegui il downmix da 7.1 a 5.1 per televisori e ricevitori che accettano solo PCM 5.1. Il passthrough non viene modificato.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Esegui il downmix a due canali per altoparlanti stereo o cuffie. Disattiva il passthrough.';
	@override String get downmixCenterBoost => 'Amplificazione canale centrale';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Amplificazione (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizza il volume durante il downmix';
	@override String get audioDownmixNormalizeDescription => 'Riduce il volume del mix per evitare il clipping. Disattiva questa opzione per mantenere il volume originale (le scene più rumorose potrebbero risultare distorte).';
	@override String get dvConversionMode => 'Conversione Dolby Vision';
	@override String get dvConversionModeDescription => 'Scegli come gestire i file Dolby Vision con profilo 7.';
	@override String get dvConversionAuto => 'Auto';
	@override String get dvConversionNative => 'Nativa / disattivata';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Rileva le capacità del dispositivo e usa il normale meccanismo di ripiego';
	@override String get dvConversionNativeDescription => 'Forza il DV7 nativo e impedisce nuovi tentativi di conversione DV';
	@override String get dvConversionDv81Description => 'Forza la conversione RPU diretta al profilo Dolby Vision 8.1';
	@override String get dvConversionHevcStripDescription => 'Rimuove i livelli RPU/EL di Dolby Vision e riproduce il video come semplice HEVC';
	@override String get experimentalDolbyVision => 'Dolby Vision sperimentale';
	@override String get experimentalDolbyVisionDescription => 'Usa il renderer FEL sperimentale alla prossima riproduzione. Richiede una compilazione separata del motore.';
	@override String get dvExperimentUnavailableDescription => 'Questo esperimento è attualmente disponibile solo su Linux.';
	@override String get dvCompatibilityFallback => 'Alternativa di compatibilità';
	@override String get dvCompatibilityFallbackDescription => 'Usa il renderer standard se l’esperimento non si avvia. I dati FEL potrebbero andare persi.';
	@override String get dvExperimentDiagnostics => 'Registro dell’esperimento video';
	@override String get dvExperimentDiagnosticsDescription => 'Attiva i log dettagliati del lettore alla prossima riproduzione.';
	@override String get disableDolbyVision => 'Disattiva Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Riproduci il livello HDR10 o HLG del file al posto di Dolby Vision, se presente';
	@override String get hdrSdrConversion => 'Conversione da HDR a SDR';
	@override String get hdrSdrConversionDescription => 'Scegli cosa converte i video HDR quando lo schermo non può mostrare l\'HDR.';
	@override String get hdrSdrConversionAuto => 'Auto';
	@override String get hdrSdrConversionAutoDescription => 'Dispositivo da Android 9 in poi, lettore nelle versioni precedenti';
	@override String get hdrSdrConversionDevice => 'Dispositivo';
	@override String get hdrSdrConversionDeviceDescription => 'La conversione è affidata all\'hardware video del dispositivo. La più veloce, ma i colori dipendono dal dispositivo';
	@override String get hdrSdrConversionPlayer => 'Lettore';
	@override String get hdrSdrConversionPlayerDescription => 'La conversione avviene nel lettore. Colori uniformi, ma il 4K può scattare sui TV box di fascia bassa';
	@override String get deinterlace => 'Deinterlacciamento';
	@override String get deinterlaceDescription => 'Rimuove gli artefatti a pettine dai video interlacciati (solo lettore mpv)';
	@override String get deinterlaceOff => 'Disattivato';
	@override String get deinterlaceOffDescription => 'Mostra il video interlacciato così come viene decodificato';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Trasforma ogni semiquadro in un fotogramma completo. Per video girati per la TV, come sport, notiziari e concerti';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => 'Ripristina i fotogrammi originali di film e animazioni sottoposti a telecine a 29,97 fps, frequenti nei DVD NTSC. I video girati per la TV scattano. La TV in diretta usa Video';
	@override String get requireProfileSelectionOnOpen => 'Chiedi di scegliere il profilo all\'apertura';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostra la selezione del profilo ogni volta che l\'app viene aperta';
	@override String get forceTvMode => 'Forza modalità TV';
	@override String get forceTvModeDescription => 'Forza il layout TV sui dispositivi che non vengono rilevati automaticamente. Richiede il riavvio.';
	@override String get startInFullscreen => 'Avvia a schermo intero';
	@override String get startInFullscreenDescription => 'Apri PlezyNG a schermo intero all\'avvio';
	@override String get exitFullscreenOnPlayerClose => 'Esci dalla modalità a schermo intero alla chiusura del lettore';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Esce automaticamente dalla modalità a schermo intero quando chiudi il lettore video';
	@override String get autoHidePerformanceOverlay => 'Nascondi automaticamente il riquadro delle prestazioni';
	@override String get autoHidePerformanceOverlayDescription => 'Dissolvi il riquadro delle prestazioni insieme ai controlli di riproduzione';
	@override String get showNavBarLabels => 'Mostra le etichette della barra di navigazione';
	@override String get showNavBarLabelsDescription => 'Mostra le etichette di testo sotto le icone della barra di navigazione';
	@override String get startupSection => 'Sezione di avvio';
	@override String get preferredServer => 'Servizio preferito';
	@override String get preferredServerDescription => 'Priorizzare i risultati di questo server, mantenendo a disposizione ogni server collegato.';
	@override String get preferredServerAutomatic => 'Automatico';
	@override String get showExploreTab => 'Mostra la scheda Esplora';
	@override String get showExploreTabDescription => 'Visualizza la scheda Esplora con contenuti di Esplora di Plex e dei tracker collegati';
	@override String get hideEmptyLibraries => 'Chiudere le librerie vuote';
	@override String get hideEmptyLibrariesDescription => 'Rimuovere le biblioteche con un numero di elementi riportati dal server di zero dalla navigazione.';
	@override String get liveTvDefaultFavorites => 'Apri sui canali preferiti';
	@override String get liveTvDefaultFavoritesDescription => 'Mostra solo i canali preferiti quando apri la TV in diretta';
	@override String get general => 'Generali';
	@override String get generalDescription => 'Lingua, avvio e comportamento della finestra';
	@override String get languageAndRegion => 'Lingua e regione';
	@override String get startup => 'Avvio';
	@override String get display => 'Schermo';
	@override String get libraryAndCards => 'Libreria e schede';
	@override String get homeScreen => 'Schermata iniziale';
	@override String get navigation => 'Navigazione';
	@override String get window => 'Finestra';
	@override String get liveTv => 'TV in diretta';
	@override String get player => 'Lettore';
	@override String get videoAndDisplay => 'Video e schermo';
	@override String get audio => 'Audio';
	@override String get quality => 'Qualità';
	@override String get subtitles => 'Sottotitoli';
	@override String get seekAndTiming => 'Avanzamento e tempi';
	@override String get behavior => 'Comportamento';
	@override String get gestures => 'Gesti';
	@override String get gestureBrightnessSwipe => 'Scorrimento per la luminosità';
	@override String get gestureBrightnessSwipeDescription => 'Scorri verso l\'alto o il basso sul bordo sinistro per regolare la luminosità';
	@override String get gestureVolumeSwipe => 'Scorrimento per il volume';
	@override String get gestureVolumeSwipeDescription => 'Scorri verso l\'alto o il basso sul bordo destro per regolare il volume';
	@override String get gesturePinchToZoom => 'Pizzica per lo zoom';
	@override String get gesturePinchToZoomDescription => 'Pizzica il video per ingrandire o ridurre';
	@override String get gestureSeekSwipe => 'Cerca il Swipe';
	@override String get gestureSeekSwipeDescription => 'Spostare a sinistra o a destra ovunque nel video per cercare; rilasciare per saltare';
	@override String get rememberBrightnessLevel => 'Ricorda il livello di luminosità';
	@override String get rememberBrightnessLevelDescription => 'Avvia la riproduzione con la luminosità impostata dall\'ultimo scorrimento';
	@override String get controls => 'Controlli';
	@override String get rememberPlayerChanges => 'Ricorda le modifiche del lettore';
	@override String get rememberPlayerChangesDescription => 'Dove viene salvata e riapplicata una modifica effettuata durante la riproduzione';
	@override String get scopePlaybackSpeed => 'Velocità di riproduzione';
	@override String get scopeShaderPreset => 'Preimpostazione shader';
	@override String get scopeAspectRatio => 'Proporzioni';
	@override String get scopeSyncOffsets => 'Sincronizzazione audio e sottotitoli';
	@override String get playerScopeOff => 'Non salvare';
	@override String get playerScopeGlobal => 'Ovunque';
	@override String get playerScopeLibrary => 'Per libreria';
	@override String get playerScopeTitle => 'Per serie o film';
	@override String get exportDialogTitle => 'Esporta le impostazioni di PlezyNG';
	@override String get followSystem => 'Usa la lingua di sistema';
	@override String get followAppLanguage => 'Come la lingua dell’interfaccia';
	@override String get regionFormat => 'Formati regionali';
	@override String get regionFormatDescription => 'Scegli come visualizzare date, numeri e unità di misura.';
	@override String get metadataLanguage => 'Lingua dei metadati';
	@override String get metadataLanguageDescription => 'Lingua preferita per titoli e descrizioni, se supportata dal server. Le preferenze audio e sottotitoli si impostano separatamente.';
	@override String get enterFullscreenOnPlaybackStart => 'Inserisci la schermata completa quando si inizia il playback';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Aprire video desktop in schermo pieno quando si avvia il playback';
	@override String get extendVideoIntoDisplayCutout => 'Estendere il video in display cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Lascia che il video a schermo pieno utilizzi la cutout della fotocamera sui telefoni Android';
	@override String get languageDescription => 'Selezionare il linguaggio utilizzato per i controlli e i messaggi PlezyNG. Seguire il sistema traccia la lingua del dispositivo.';
	@override String get themeDescription => 'Scegliere i colori e il contrasto utilizzati in tutta l\'app.';
	@override String get libraryDensityDescription => 'Cambiare quante carte di libreria si adatta in ogni riga.';
	@override String get displayScaleDescription => 'Ristrutturare l\'interfaccia su questo display auto senza cambiare la dimensione del testo in tutto il dispositivo.';
	@override String get themeSongVolumeDescription => 'Imposta il volume delle canzoni di tema relativamente ad altri audio.';
	@override String get viewModeDescription => 'Scegli se gli articoli della biblioteca vengono visualizzati come poster in una rete o come elenco compatto.';
	@override String get gridViewDescription => 'Ordina gli articoli della biblioteca in righe e colonne di poster.';
	@override String get listViewDescription => 'Mostra gli articoli della biblioteca in una lista verticale con più testo per oggetto.';
	@override String get gridSpacingDescription => 'Imposta la distanza tra i poster nelle reti della biblioteca.';
	@override String get gridSpacingTightDescription => 'Pianificare più poster sullo schermo con piccole lacune.';
	@override String get gridSpacingNormalDescription => 'Utilizzare la differenza standard tra i poster.';
	@override String get gridSpacingSpaciousDescription => 'Aggiungi più grandi lacune tra i poster per una maggiore separazione.';
	@override String get episodePosterModeDescription => 'Scegliere quale opera d\'arte appare sulle carte di episodio.';
	@override String get seriesPosterDescription => 'Utilizzare il poster della serie dello show per ogni episodio.';
	@override String get seasonPosterDescription => 'Utilizzare il poster di stagione per ogni episodio quando disponibile.';
	@override String get episodeThumbnailDescription => 'Utilizzare un quadro dell\'episodio quando disponibile.';
	@override String get continueWatchingActionDescription => 'Scegli ciò che accade quando si attiva una scheda di Continuing Watching.';
	@override String get continueWatchingPlayDescription => 'Inizia subito il film o l’episodio.';
	@override String get continueWatchingDetailsDescription => 'Apri prima la pagina titolo in modo da poter rivedere i dettagli e scegliere una azione.';
	@override String get episodeActionDescription => 'Scegli ciò che accade quando si attiva una scheda di episodio.';
	@override String get episodePlayDescription => 'Inizia subito l’episodio.';
	@override String get episodeDetailsDescription => 'Apri la pagina dell\'episodio prima del playback.';
	@override String get contentScreensaverDelayDescription => 'Scegli quanto tempo PlezyNG aspetta senza input prima di mostrare opere d\'arte.';
	@override String get continueWatchingRowSizeDescription => 'Scegliamo quanto sono grandi le carte nella riga Continuing Watching.';
	@override String get rowSizeCompactDescription => 'Mostra carte più piccole in modo che più articoli si adattino per tutta la riga.';
	@override String get rowSizeStandardDescription => 'Utilizzare la dimensione standard della scheda.';
	@override String get rowSizeLargeDescription => 'Mostra mappe più grandi con maggiori dettagli artwork.';
	@override String get visualEffectsDescription => 'Scegli il budget di animazione e effetti artificiali per questo dispositivo.';
	@override String get visualEffectsFullDescription => 'Utilizzare tutti gli effetti di animazione e arte su ogni dispositivo.';
	@override String get startupSectionDescription => 'Selezionare quale sezione si apre quando PlezyNG inizia.';
	@override late final _Translations$settings$startupSectionOptions$it startupSectionOptions = _Translations$settings$startupSectionOptions$it._(_root);
	@override String get smallSkipDurationDescription => 'Imposta la distanza spostata dal breve ritorno e avanti cerca controlli.';
	@override String get largeSkipDurationDescription => 'Imposta la distanza spostata dal lungo ritorno e avanti cerca controlli.';
	@override String get rewindOnResumeDescription => 'Spostare il ripristino di questo importo quando si riprende un video.';
	@override String get defaultSleepTimerDescription => 'Imposta la durata iniziale utilizzata quando si inizia il timer del sonno.';
	@override String get playNextCountdownDescription => 'Attendere molto prima di iniziare il prossimo episodio. impostare a 0 per iniziare immediatamente.';
	@override String get autoSkipDelaySettingDescription => 'Si applica quando un intro, credito o annuncio è impostato per scappare automaticamente.';
	@override String get downmixCenterBoostDescription => 'Aumentare il dialogo nel canale centrale quando l\'audio circostante viene mescolato in stereo.';
	@override String get displaySwitchDelayDescription => 'Aspettate prima di cambiare il modo di visualizzazione in modo che la TV o il ricevitore possa completare il suo precedente switch.';
	@override String get playerBackendDescription => 'Selezionare quale motore di riproduzione decodifica e renderà il video su questo dispositivo.';
	@override String get exoPlayerDescription => 'Utilizzare il player basato su Media3 nativo di Android e i percorsi hardware supportati.';
	@override String get mpvDescription => 'Utilizzare mpv, che esprime ulteriori controlli di riproduzione, sottotitoli e video processing.';
	@override String get scopeOffDescription => 'Mantenere i cambiamenti per l\'attuale sessione di riproduzione solo.';
	@override String get scopeGlobalDescription => 'Ripristinare lo stesso valore per ogni biblioteca e titolo.';
	@override String get scopeLibraryDescription => 'Ricordate un valore separato per ciascuna biblioteca.';
	@override String get scopeTitleDescription => 'Ricorda un valore separato per ogni spettacolo o film.';
	@override String get specialsOrderingServerDescription => 'Mantenere l\'ordine dell\'episodio fornito dal server media.';
	@override String get specialsOrderingAirDateDescription => 'Posizionare speciali tra episodi regolari per la loro data aerea.';
	@override String get specialsOrderingLastDescription => 'Posizionare ogni speciale dopo le stagioni regolari.';
	@override String get skipIntroModeDescription => 'Scegli se i marcatori intro giocano normalmente, mostrano un pulsante di salto o scappano automaticamente.';
	@override String get skipCreditsModeDescription => 'Selezionare se i crediti giocano normalmente, mostrare un pulsante di salto o saltare automaticamente.';
	@override String get skipAdsModeDescription => 'Scegli se gli annunci rilevati si svolgono normalmente, visualizzano un pulsante di salto o scappano automaticamente.';
	@override String get playbackBufferAutoDescription => 'Lascia che il giocatore attivo sceglie la sua dimensione normale del buffer.';
	@override String get playbackBufferLargeDescription => 'Mantenere più media pronti prima della riproduzione; questo utilizza più memoria.';
	@override String get playbackBufferExtraLargeDescription => 'Mantenere il più grande buffer di lettura; questo utilizza la maggior parte della memoria.';
	@override String get defaultQualityDescription => 'Configurare la risoluzione video predefinita e il tetto bitrate per i flussi che il server trascoda.';
	@override String get cellularQualityDescription => 'Superare la qualità predefinita quando il dispositivo utilizza una connessione solo cellulare.';
	@override String get remoteQualityDescription => 'Superare la qualità predefinita quando si connette a un server tramite una connessione remota.';
	@override String get qualityPresetOriginalDescription => 'Gioca la fonte alla sua qualità disponibile senza chiedere al server di trascodirla.';
	@override String get qualityPresetTranscodeOptionDescription => 'Chiedi al server un flusso convertito utilizzando la risoluzione e il bitrate mostrato sopra.';
	@override String get qualityPresetSameAsDefaultDescription => 'Utilizzare la qualità selezionata in Qualità predefinita.';
	@override String get musicQualityDescription => 'Imposta la bitrate audio massima richiesta dal server; originale mantiene il flusso di sorgente.';
	@override String get musicQualityOriginalDescription => 'Gioca l\'audio sorgente senza un transcode cappato a bitrate.';
	@override String get musicQualityTranscodeOptionDescription => 'Richiedi un codice trans server capped vicino alla bitrate mostrata sopra; la produzione effettiva può variare.';
	@override String get maxVolumeInputLabel => 'Il volume massimo (%)';
	@override String get checkForUpdatesDescription => 'Scopri ora se è disponibile una versione più recente di PlezyNG.';
	@override String get appearanceDescription => 'Selezionare il tema dell\'app e personalizzare le schede della biblioteca, le righe di casa e la navigazione.';
	@override String get prerollLibraryDescription => 'Scegli la libreria che contiene i clip disponibili come pre-roll di film.';
	@override String get prerollSelectionDescription => 'Scegli i clip dalla biblioteca selezionata che puoi giocare prima dei film.';
	@override String get contentScreensaverDelayOptionDescription => 'Aspettate questi molti minuti senza input prima di mostrare screensaver artwork.';
	@override String get videoCodecOptionDescription => 'Permettere la riproduzione diretta di questo codec quando supportato. i codec non controllati sono trascoditi dal server dei media.';
}

// Path: themeEditor
class _Translations$themeEditor$it extends Translations$themeEditor$en {
	_Translations$themeEditor$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Integrati';
	@override String get presets => 'Preimpostati';
	@override String get custom => 'Personalizzato';
	@override String get customEmpty => 'Non ancora creato';
	@override String get editCustom => 'Modifica tema personalizzato';
	@override String get editCustomDescription => 'Scegli tu ogni colore';
	@override String get locked => 'L’accesso a vita richiesto';
	@override String get savedLocked => 'Salvataggio - disponibile con accesso a vita';
	@override String get title => 'Tema personalizzato';
	@override String get startFrom => 'Parti da';
	@override String get startFromDescription => 'Copia tutti i colori da un altro tema';
	@override String get colors => 'Colori';
	@override String get preview => 'Anteprima';
	@override late final _Translations$themeEditor$slots$it slots = _Translations$themeEditor$slots$it._(_root);
	@override String get opacity => 'Opacità';
	@override String get hexHint => '#RRGGBB o #AARRGGBB';
	@override String get fromOtherThemes => 'Da altri temi';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} ${theme}';
	@override late final _Translations$themeEditor$contrast$it contrast = _Translations$themeEditor$contrast$it._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, sotto il valore consigliato di ${minimum}:1';
	@override String get discardTitle => 'Scartare le modifiche?';
	@override String get discardMessage => 'Le modifiche ai colori non salvate andranno perse.';
	@override String get discard => 'Scarta';
	@override String previewCardTitle({required Object number}) => 'Episodio ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} min rimanenti';
	@override String get previewSwitch => 'Riproduzione automatica';
	@override String get previewMutedText => 'Così appare il testo secondario';
	@override String get themeSystemDescription => 'Seguire l\'aspetto del dispositivo e scorrere tra luce e buio automaticamente.';
	@override String get themeLightDescription => 'Utilizzare un background luminoso con testo scuro.';
	@override String get themeDarkDescription => 'Utilizzare un background scuro con testo leggero.';
	@override String get themeOledDescription => 'Utilizzare superfici di colore nero che riducono la luce su schermi OLED.';
	@override String get themeEmberDescription => 'Utilizzare colori di accento rosso e amber.';
	@override String get themeGlacierDescription => 'Utilizzare colori accenti blu freddi.';
	@override String get themeForestDescription => 'Utilizzare i colori di accento verde e naturale.';
	@override String get themePlumDescription => 'Utilizzare i colori di accento violetto e plum.';
	@override String get themePaperDescription => 'Utilizzare superfici calde come carta e colori ispirati all\'ingrosso.';
	@override String get themeCustomDescription => 'Utilizzare la paletta dei colori che hai creato nell\'editor di tema personalizzato.';
	@override String get editorDescription => 'Scegli un colore di palette, regolare la sua tonalità, saturazione, luminosità o opacità e vedere l\'aggiornamento preview prima di risparmiare.';
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
	@override String get people => 'Persone';
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
	@override String get overview => 'Panoramica';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Sottotitoli';
	@override String get images => 'Immagini incorporate';
	@override String get dataStreams => 'Flussi di dati';
	@override String get lyrics => 'Testi';
	@override String get file => 'File';
	@override String get attachments => 'Allegati';
	@override String get delivery => 'Distribuzione';
	@override String versionCounter({required Object index, required Object count}) => 'Versione ${index} di ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'File ${index} di ${count}';
	@override String get noStreams => 'Il server non ha segnalato flussi per questo file.';
	@override String get copyPath => 'Copia percorso';
	@override String get pathCopied => 'Percorso del file copiato';
	@override String get codec => 'Codec';
	@override String get codecTag => 'Tag codec';
	@override String get resolution => 'Risoluzione';
	@override String get codedResolution => 'Risoluzione codificata';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Frequenza fotogrammi';
	@override String get rotation => 'Rotazione';
	@override String get comment => 'Commento';
	@override String get audioDescription => 'Descrizione audio';
	@override String get headerCompression => 'Compressione header';
	@override String get sidecarFile => 'File sidecar';
	@override String get transportTimestamp => 'Timestamp di trasporto';
	@override String get displayOffset => 'Offset di visualizzazione';
	@override String get previewFailureCode => 'Codice errore anteprima';
	@override String get previewRetries => 'Riprova anteprima';
	@override String get aspectRatio => 'Proporzioni';
	@override String get pixelAspectRatio => 'Aspect ratio pixel';
	@override String get profile => 'Profilo';
	@override String get level => 'Livello';
	@override String get bitDepth => 'Profondità in bit';
	@override String get pixelFormat => 'Formato pixel';
	@override String get colorSpace => 'Spazio colore';
	@override String get colorRange => 'Gamma colori';
	@override String get colorPrimaries => 'Colori primari';
	@override String get colorTransfer => 'Trasferimento colore';
	@override String get chromaSubsampling => 'Sottocampionamento cromatico';
	@override String get chromaLocation => 'Posizione crominanza';
	@override String get scanType => 'Tipo di scansione';
	@override String get interlaced => 'Interlacciato';
	@override String get anamorphic => 'Anamorfico';
	@override String get referenceFrames => 'Frame di riferimento';
	@override String get dynamicRange => 'Gamma dinamica';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Livello Dolby Vision';
	@override String get dolbyVisionVersion => 'Versione Dolby Vision';
	@override String get dolbyVisionLayers => 'Layer Dolby Vision';
	@override String get baseLayerCompatibility => 'Compatibilità layer di base';
	@override String get avcBitstream => 'Bitstream AVC';
	@override String get nalLengthSize => 'Dimensione lunghezza NAL';
	@override String get scalingMatrix => 'Matrice di scaling personalizzata';
	@override String get streamIdentifier => 'Identificatore flusso';
	@override String get streamIndex => 'Indice flusso';
	@override String get streamId => 'ID flusso';
	@override String get language => 'Lingua';
	@override String get languageCode => 'Codice lingua';
	@override String get streamTitle => 'Titolo traccia';
	@override String get channels => 'Canali';
	@override String get sampleRate => 'Frequenza di campionamento';
	@override String get spatialAudio => 'Audio spaziale';
	@override String get textBased => 'Testuale';
	@override String get subtitleFormat => 'Formato sidecar';
	@override String get provider => 'Provider';
	@override String get matchScore => 'Punteggio corrispondenza';
	@override String get externalDelivery => 'Può essere servito separatamente';
	@override String get sidecarPath => 'Percorso sidecar';
	@override String get sourceStream => 'Copiato da';
	@override String get temporary => 'Temporaneo';
	@override String get timeBase => 'Base temporale';
	@override String get overallBitrate => 'Bitrate complessivo';
	@override String get path => 'Percorso';
	@override String get fileName => 'Nome file';
	@override String get size => 'Dimensione';
	@override String get totalSize => 'Dimensione totale';
	@override String get container => 'Contenitore';
	@override String get duration => 'Durata';
	@override String get previewThumbnails => 'Miniature anteprima';
	@override String get previewIndex => 'Indice anteprima';
	@override String get packetLength => 'Lunghezza pacchetto';
	@override String get filePresent => 'File presente';
	@override String get fileReadable => 'Leggibile dal server';
	@override String get streamPath => 'Percorso flusso';
	@override String get optimizedForStreaming => 'Ottimizzato per lo streaming';
	@override String get has64bitOffsets => 'Offset a 64 bit';
	@override String get protocol => 'Protocollo';
	@override String get mediaType => 'Tipo di supporto';
	@override String get sourceKind => 'Tipo di origine';
	@override String get optimizedVersion => 'Versione ottimizzata';
	@override String get optimizationTarget => 'Obiettivo ottimizzazione';
	@override String get deletedAt => 'Eliminato';
	@override String get remoteSource => 'Origine remota';
	@override String get infiniteStream => 'Flusso infinito';
	@override String get directPlay => 'Riproduzione diretta';
	@override String get directStream => 'Streaming diretto';
	@override String get transcoding => 'Transcodifica';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID versione';
	@override String get fileId => 'ID file';
	@override String get defaultAudioTrack => 'Traccia audio predefinita';
	@override String get defaultSubtitleTrack => 'Traccia sottotitoli predefinita';
	@override String get subtitlesOff => 'Disattivati';
	@override String get flagDefault => 'Predefinito';
	@override String get flagForced => 'Forzato';
	@override String get flagSelected => 'Selezionato';
	@override String get flagExternal => 'Esterno';
	@override String get flagHearingImpaired => 'Non udenti';
	@override String get flagDub => 'Doppiato';
	@override String get flagOriginal => 'Originale';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profilo ${profile}';
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
	@override String get deleteEpisodeFromServer => 'Elimina episodio dal server';
	@override String get deleteSeasonFromServer => 'Elimina stagione dal server';
	@override String get deleteShowFromServer => 'Elimina serie dal server';
	@override String get deleteMovieFromServer => 'Elimina film dal server';
	@override String get deleteEpisodeTitle => 'Eliminare questo episodio?';
	@override String get deleteSeasonTitle => 'Eliminare questa stagione?';
	@override String get deleteShowTitle => 'Eliminare questa serie?';
	@override String get deleteMovieTitle => 'Eliminare questo film?';
	@override String get deleteEpisodeConfirm => 'Elimina episodio';
	@override String get deleteSeasonConfirm => 'Elimina stagione';
	@override String get deleteShowConfirm => 'Elimina serie';
	@override String get deleteMovieConfirm => 'Elimina film';
	@override String get deleteAnyway => 'Elimina comunque';
	@override String confirmDeleteTarget({required Object title}) => 'Eliminare definitivamente ${title} dal tuo server?';
	@override String get deleteMultipleWarning => 'Sono inclusi tutti gli episodi e i relativi file.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: 'Questo elimina il ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio in essa contenuto e il relativo file.',
		other: 'Questo elimina tutti i ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodi in essa contenuti e i relativi file.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: 'Questo elemento è archiviato in ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} file, che verrà eliminato.',
		other: 'Questo elemento è archiviato in ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} file, e tutti verranno eliminati.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} altro episodio è archiviato nello stesso file e verrà eliminato anche lui:',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} altri episodi sono archiviati nello stesso file e verranno eliminati anche loro:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG non ha potuto verificare quali file rimuoverà, quindi potrebbe eliminare più di quanto indicato sopra. Annulla e riprova, oppure elimina comunque.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Il tuo server non ha fornito i dettagli del file per questo elemento, quindi PlezyNG non può verificare quali file rimuoverà. Potrebbe eliminare più di quanto indicato sopra.';
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
	@override String get autoScrollPlay => 'Avvia scorrimento automatico';
	@override String get autoScrollPause => 'Sospendi scorrimento automatico';
	@override String get hueShort => 'T';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Il rosso';
	@override String get green => 'verde';
	@override String get blue => 'blu';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'Il HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'accessibilità';
	@override String get summary => 'testo, contrasto, movimento e controlli';
	@override String get systemHint => 'Le impostazioni di accessibilità del dispositivo si applicano sempre.Queste opzioni aggiungono ajustamenti nel corso di PlezyNG.';
	@override String get readability => 'Leggi e visibilità';
	@override String get textSize => 'Dimensioni aggiuntive del testo';
	@override String get preview => 'Leggi, ascolta e guarda al tuo ritmo.';
	@override String get boldText => 'Interfaccia testo';
	@override String get highContrast => 'Il contrasto elevato';
	@override String get highContrastHint => 'Testo più forte, indicatori di rilievo e di focalizzazione sulle superfici luminose o scuri.';
	@override String get interaction => 'Movimento e interazione';
	@override String get reduceMotion => 'Ridurre il movimento';
	@override String get reduceMotionHint => 'Fermare le animazioni dell’indicatore di focus, le transizioni delle pagine e gli effetti decorativi.';
	@override String get largeTargets => 'obiettivi touch più grandi';
	@override String get largeTargetsHint => 'Gioca i controlli condivisi più spazio per la navigazione a touch e assistive.';
	@override String get navigationHint => 'Usa Tab e Shift+Tab per spostarti tra i controlli, Enter o la barra spaziatrice per attivarli ed Escape o Indietro per chiudere. Quando un libro è aperto, puoi regolare lo zoom e le preferenze di lettura.';
	@override String get textSizeDescription => 'Scala il testo dell\'interfaccia in PlezyNG oltre alla configurazione di dimensioni del testo del sistema del dispositivo.';
	@override String get boldTextHint => 'Utilizzare un peso più pesante per le etichette e i messaggi di interfaccia per renderli più facili da distinguere.';
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
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
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
	@override String get playbackPaused => 'In pausa';
	@override String get playbackResumed => 'Riproduzione';
	@override String get loadingVideo => 'Caricamento video';
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
	@override String get segmentLoopHelp => 'Scorrere una sezione durante questa riproduzione. impostare A, quindi impostate B in seguito nella linea di tempo.';
	@override String get setLoopStart => 'Set loop inizio (A)';
	@override String get setLoopEnd => 'Set loop fine (B)';
	@override String get clearSegmentLoop => 'Il segmento chiaro';
	@override String get setLoopStartFirst => 'Set loop inizio (A) prima della fine (B).';
	@override String get loopEndAfterStart => 'La fine del loop deve essere più tardi dell\'inizio.';
	@override String get segmentLoopUnavailable => 'Il segmento looping non è disponibile per questo playback.';
	@override String get loopPointNotSet => 'Non impostare';
	@override String get bookmarksHelp => 'I biglietti sono salvati su questo dispositivo. selezionare uno per andare a quel momento.';
	@override String get bookmarksButton => 'Il libromarchio';
	@override String get chaptersAndBookmarks => 'Capitoli e bookmark';
	@override String get segmentLoop => 'Segmento Loop';
	@override String get addBookmark => 'Aggiungi Bookmark';
	@override String get bookmarkName => 'Nome di Bookmark';
	@override String get bookmarkNameHint => 'Ad esempio, la scena di apertura';
	@override String bookmarkDefaultName({required Object n}) => 'Il Bookmark ${n}';
	@override String get bookmarkNameRequired => 'Inserisci un nome per questo bookmark.';
	@override String get deleteBookmark => 'Rimuovere il bookmark';
	@override String get bookmarkLimitReached => 'Questo articolo ha già 100 bookmark.';
	@override String get bookmarkUnavailable => 'Non potevo salvare o rimuovere questo bookmark.';
	@override String get bookmarkSaved => 'Il Bookmark è stato salvato.';
	@override String get bookmarkDeleted => 'Il Bookmark è cancellato.';
	@override String loopPointSet({required Object point, required Object time}) => 'Il punto Loop ${point} Set a ${time}e il';
	@override String get noChaptersOrBookmarks => 'Nessun capitolo o carattere disponibile.';
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
	@override String get timelineSlider => 'Timeline video';
	@override String get volumeSlider => 'Livello volume';
	@override String endsAt({required Object time}) => 'Termina alle ${time}';
	@override String get pipActive => 'Riproduzione in Picture-in-Picture';
	@override String get pipFailed => 'Impossibile avviare la modalità Picture-in-Picture';
	@override String get screenshotSaved => 'Schermata salvata';
	@override String get screenshotFailed => 'Impossibile catturare la schermata';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override String volumePercent({required Object percent}) => 'Volume ${percent}%';
	@override late final _Translations$videoControls$pipErrors$it pipErrors = _Translations$videoControls$pipErrors$it._(_root);
	@override String get chapters => 'Capitoli';
	@override String get noChaptersAvailable => 'Nessun capitolo disponibile';
	@override String get queue => 'Coda';
	@override String get noQueueItems => 'Nessun elemento in coda';
	@override String get noAudioDevicesAvailable => 'Nessun dispositivo audio disponibile';
	@override String get searchSubtitles => 'Cerca sottotitoli';
	@override String get language => 'Lingua';
	@override String get noSubtitlesFound => 'Nessun sottotitolo trovato';
	@override String get subtitleDownloaded => 'Sottotitolo scaricato';
	@override String get subtitleDownloadedNotApplied => 'Il sottotitolo è stato scaricato, ma non è stato possibile selezionarlo';
	@override String get subtitleDownloadFailed => 'Impossibile scaricare il sottotitolo';
	@override String get searchLanguages => 'Cerca lingue...';
	@override String get skipIntro => 'Salta intro';
	@override String get skipCredits => 'Salta titoli';
	@override String get nextEpisode => 'Episodio successivo';
	@override String subtitleTrack({required Object n}) => 'Traccia ${n}';
	@override String subtitleFile({required Object name}) => 'Sottotitolo ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Forzato)';
	@override String get osdSubtitlesOff => 'Sottotitoli: Disattivati';
	@override String osdSubtitles({required Object track}) => 'Sottotitoli: ${track}';
	@override String osdAudio({required Object track}) => 'Audio: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} strati',
	);
	@override String get trackSelectionTitle => 'Scegliere le tracce prima del playback';
	@override String get trackSelectionAuto => 'Selezione automatica';
	@override String get openMiniPlayer => 'Mini giocatore aperto';
	@override String get returnToFullPlayer => 'Il ritorno al giocatore completo';
	@override String get loadSubtitleFile => 'Il file subtitle è ...';
	@override String get subtitleLoadFailed => 'Non è stato possibile caricare il file subtitle';
	@override String get skipAds => 'Scopri gli annunci';
	@override String get tapToUnlock => 'Tocca per sbloccare';
	@override String get tapAgainToUnlock => 'Tocca di nuovo per sbloccare';
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
		one: 'Rimosso automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download già visto',
		other: 'Rimossi automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download già visti',
	);
	@override String get removedFromContinueWatching => 'Rimosso da Continua a guardare';
	@override String errorLoading({required Object error}) => 'Errore: ${error}';
	@override String get searchPartialResults => 'Non è stato possibile cercare in alcuni server multimediali. Vengono mostrati i risultati disponibili.';
	@override String get streamInterrupted => 'La riproduzione si è interrotta. Premi Riproduci o vai a un altro punto per riprovare.';
	@override String get liveStreamInterrupted => 'La diretta si è interrotta. Premi Riproduci per riprovare.';
	@override String get fileInfoNotAvailable => 'Informazioni sul file non disponibili';
	@override String get playbackAuthenticationRequired => 'Accedi di nuovo al server multimediale per riprodurre questo elemento.';
	@override String get playbackServerUnavailable => 'Il server multimediale non è disponibile. Riprova più tardi.';
	@override String get playbackDataInvalid => 'Il server ha restituito informazioni di riproduzione non valide.';
	@override String get playbackCancelled => 'Riproduzione annullata.';
	@override String get playbackFailed => 'Impossibile avviare la riproduzione.';
	@override String playbackFailedDetail({required Object error}) => 'Impossibile avviare la riproduzione: ${error}';
	@override String get audioOutputFailed => 'L\'uscita audio ha smesso di rispondere. Controlla la connessione audio del televisore o del ricevitore; se anche le altre app non hanno audio, riavvia il dispositivo.';
	@override String get mediaUnavailable => 'Questo contenuto non è più disponibile.';
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
	@override String get mediaUnreadableTitle => 'File non disponibile';
	@override String get mediaUnreadableBody => 'Il server ha trovato questo elemento ma non ha potuto leggere il suo file (HTTP 404). Il file è stato probabilmente spostato o eliminato, oppure il suo storage è offline. Chiedi al proprietario del server di controllare il file e di riscansionare la libreria.';
	@override String get serverBusyTitle => 'Streaming non disponibile';
	@override String get serverBusyBody => 'Il server ha continuato a rifiutare la riproduzione in streaming di questo file (HTTP 503). Potrebbe essere in fase di riavvio, occupato oppure l\'unità in cui si trova il file potrebbe essere offline. Riprova tra qualche istante. Se il problema persiste, chiedi al proprietario del server di controllare il server e l\'unità di archiviazione del file.';
	@override String get playbackNotAllowedTitle => 'Riproduzione non consentita';
	@override String get playbackNotAllowedBody => 'Il server ha rifiutato lo streaming di questo elemento (HTTP 403). Il tuo account potrebbe non avere l\'autorizzazione per riprodurlo, oppure il server potrebbe consentire la riproduzione solo sulla sua rete locale.';
	@override String get logsUploaded => 'Log caricati';
	@override String get logsUploadFailed => 'Impossibile caricare i log';
	@override String get logId => 'ID log';
	@override String get burnedSubtitlesUseMenu => 'I sottotitoli sono incorporati in questo stream. Cambiali dal menu dei sottotitoli.';
	@override String get noVideoUrl => 'Nessun URL video disponibile';
	@override String get playbackNoMediaSources => 'Il server non ha restituito sorgenti multimediali riproducibili';
	@override String get playbackDataNotPrepared => 'La riproduzione è stata avviata prima che i relativi dati fossero pronti';
	@override String get streamSelectionUnavailable => 'La selezione dei flussi non è disponibile per questa sorgente';
	@override String get streamSelectionFailed => 'Impossibile applicare i flussi selezionati';
	@override String get trackSelectionNotRemembered => 'Questa scelta di traccia vale solo per la riproduzione corrente.';
	@override String get serverUnavailableForProfile => 'Nessun server disponibile per il profilo attivo';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$it extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Il rapido fucile marrone salta sopra il cane lazo';
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
	@override String get useMargins => 'Usa i margini';
	@override String get useMarginsDescription => 'Consenti i sottotitoli testuali nello spazio esterno al video. I sottotitoli con stile possono mantenere la loro posizione originale.';
	@override String get anchorToScreen => 'Fissa allo schermo';
	@override String get anchorToScreenDescription => 'Mostra i sottotitoli testuali nelle bande nere sotto i video in formato panoramico';
	@override String get bold => 'Grassetto';
	@override String get italic => 'Corsivo';
	@override String get renderResolution => 'Risoluzione di rendering';
	@override String get renderResolutionScreen => 'Risoluzione dello schermo';
	@override String get renderResolutionVideo => 'Risoluzione del video';
	@override String get fontSizeDescription => 'Imposta la dimensione del testo di sottotitolo su questo dispositivo.';
	@override String get textColorDescription => 'Selezionare il colore utilizzato per il testo sottotitolo.';
	@override String get borderSizeDescription => 'Imposta la spessore dell\'outline intorno al testo sottotitolo.';
	@override String get borderColorDescription => 'Scegliere il colore utilizzato per l\'outline del sottotitolo.';
	@override String get backgroundColorDescription => 'Selezionare il colore dietro il testo sottotitolo.';
	@override String get backgroundOpacityDescription => 'Imposta quanto sia trasparente il background del sottotitolo: 0% è chiaro e 100% solido.';
	@override String get positionDescription => 'Movi i sottotitoli verticalmente. 0% è la parte superiore del video e 100% è il fondo.';
	@override String get assOverrideDescription => 'Scegli se il giocatore segue, adatta, sostituisce o rimuove lo stile inserito nei sottotitoli ASS.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$it assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$it._(_root);
	@override String get renderResolutionDescription => 'Scegli la risoluzione utilizzata per rasterizzare l\'immagine e i sottotitoli ASS. Le scale Android inferiori possono ridurre il lavoro di rendering ma sembrano più sottili.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$it renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$it._(_root);
	@override String get boldDescription => 'Tracciare il sottotitolo in un peso più pesante.';
	@override String get italicDescription => 'Tracciare il sottotitolo in italiano.';
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
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Aggiungi riga';
	@override String get removeLine => 'Rimuovi riga';
	@override String get embeddedVoHint => 'vo, gpu-context e gpu-api vengono ignorati su Linux: il video incorporato viene sempre renderizzato tramite vo=libmpv sul piano video e gpu-next (che gli shader di calcolo come ArtCNN richiedono) non può essere eseguito in modalità incorporata.';
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
	@override String get addPlezyProfile => 'Aggiungi profilo PlezyNG';
	@override String get switchingProfile => 'Cambio profilo…';
	@override String get deleteThisProfileTitle => 'Eliminare questo profilo?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Rimuovi ${displayName}. Le connessioni resteranno invariate.';
	@override String get active => 'Attivo';
	@override String get manage => 'Gestisci';
	@override String get delete => 'Elimina';
	@override String get signOut => 'Esci';
	@override String get signOutPlexTitle => 'Uscire da Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Verranno rimossi ${displayName} e tutti gli utenti Plex Home. Potrai accedere di nuovo in qualsiasi momento.';
	@override String get signOutPlexDeleteDownloads => 'Elimina anche i download';
	@override String get signOutPlexDeleteDownloadsDescription => 'Altrimenti restano su questo dispositivo e tornano disponibili quando accedi di nuovo a questo account.';
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
	@override String get copyAutomationLink => 'Copia il link di automatizzazione Android';
	@override String get copyAutomationLinkDescription => 'Selezionare questo profilo da un\'intenzione o automatizzazione Android.';
	@override String get automationLinkCopied => 'Il link di automatizzazione del profilo è copiato.';
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
	@override String plexAccountChip({required Object account}) => 'Account Plex: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} tramite ${account}';
	@override String get connectionDefault => 'Predefinita';
	@override String connectionAs({required Object displayName}) => 'come ${displayName}';
	@override String get makeDefault => 'Imposta come predefinita';
	@override String get removeConnection => 'Rimuovi';
	@override String get profileRenamed => 'Profilo rinominato.';
	@override String borrowAddTo({required Object displayName}) => 'Aggiungi a ${displayName}';
	@override String get borrowExplain => 'Prendi in prestito la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.';
	@override String get borrowEmpty => 'Nulla da prendere in prestito al momento.';
	@override String get borrowEmptySubtitle => 'Collega prima Plex, Jellyfin o Emby a un altro profilo.';
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
	@override String get tokenIdentityMismatch => 'Il token del profilo Plex è stato associato a un server imprevisto';
	@override String get settingsLocked => 'Le impostazioni sono bloccate per questo profilo.';
	@override String get unlockSettings => 'Sviluppo di disattivazione';
	@override String get showExploreForProfile => 'Mostra Scopri per questo profilo';
	@override String get showExploreForProfileDescription => 'Aprire per rimuovere Explore dalla navigazione di questo profilo.';
}

// Path: connections
class _Translations$connections$it extends Translations$connections$en {
	_Translations$connections$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Connessioni';
	@override String get addConnection => 'Aggiungi connessione';
	@override String get addConnectionSubtitleNoProfile => 'Accedi con Plex o collega un server Jellyfin o Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Aggiungi a ${displayName}: Plex, Jellyfin, Emby o la connessione di un altro profilo';
	@override String sessionExpiredOne({required Object name}) => 'Sessione scaduta per ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sessione scaduta per ${count} server';
	@override String accessDeniedOne({required Object name}) => '${name} ha negato l\'accesso a questo account';
	@override String accessDeniedMany({required Object count}) => '${count} server hanno negato l\'accesso a questo account';
	@override String get signInAgain => 'Accedi di nuovo';
	@override String editMediaBrowserTitle({required Object product}) => 'Modifica connessione ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Aggiungi o rimuovi gli URL per ${serverName}. PlezyNG userà l\'URL raggiungibile con la latenza più bassa.';
}

// Path: accountPreferences
class _Translations$accountPreferences$it extends Translations$accountPreferences$en {
	_Translations$accountPreferences$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Preferenze dell\'account';
	@override String hubSubtitleSingle({required Object account}) => 'Opzioni di audio, sottotitoli e libreria salvate su ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Opzioni di audio, sottotitoli e libreria salvate su ${count} account';
	@override String get pickAccount => 'Ogni account conserva le proprie preferenze. Scegli quale modificare.';
	@override String get storedOnAccount => 'Queste opzioni vengono salvate sull\'account stesso, quindi ogni app che vi accede le usa — inclusa PlezyNG sugli altri tuoi dispositivi.';
	@override String get noAccounts => 'Nessun account da configurare';
	@override String get noAccountsHint => 'Accedi a Plex oppure connetti un server Jellyfin o Emby: le preferenze salvate su quell\'account appariranno qui.';
	@override String get unavailable => 'Impossibile raggiungere questo account';
	@override String get loadFailed => 'Impossibile caricare queste preferenze';
	@override String get noPreference => 'Nessuna preferenza';
	@override String get notSet => 'Non impostato';
	@override late final _Translations$accountPreferences$groups$it groups = _Translations$accountPreferences$groups$it._(_root);
	@override String get preferredAudioLanguage => 'Lingua audio preferita';
	@override String get autoSelectAudio => 'Scegli l\'audio in base alla lingua';
	@override String get autoSelectAudioDescription => 'Se disattivata, viene mantenuta la traccia audio che il file indica come predefinita.';
	@override String get preferredSubtitleLanguage => 'Lingua dei sottotitoli preferita';
	@override String get subtitleMode => 'Attiva i sottotitoli';
	@override late final _Translations$accountPreferences$subtitleModes$it subtitleModes = _Translations$accountPreferences$subtitleModes$it._(_root);
	@override String get subtitleAccessibility => 'Sottotitoli SDH';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$it subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$it._(_root);
	@override String get forcedSubtitles => 'Sottotitoli forzati';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$it forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$it._(_root);
	@override String get displayMissingEpisodes => 'Mostra gli episodi mancanti';
	@override String get displayMissingEpisodesDescription => 'Elenca gli episodi noti al server ma senza un file associato.';
	@override String get hidePlayedInLatest => 'Nascondi gli elementi visti da Aggiunti di recente';
	@override String get hidePlayedInLatestDescription => 'Esclude dagli Aggiunti di recente del server gli elementi che hai già visto.';
	@override String get displayCollectionsView => 'Mostra la vista Raccolte';
	@override String get displayCollectionsViewDescription => 'Mostra la vista Raccolte del server insieme alle tue librerie.';
	@override String get rewatchingInNextUp => 'Mantieni le serie riviste in Prossimi episodi';
	@override String get rewatchingInNextUpDescription => 'Quando finisci una serie e la ricominci, Prossimi episodi segue la nuova visione invece di rimuovere la serie.';
	@override String get watchedIndicator => 'Indicatori di visione';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$it watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$it._(_root);
	@override String get mediaReviewsVisibility => 'Valutazioni e recensioni';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$it mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$it._(_root);
	@override String get preferredAudioLanguageDescription => 'Preferisce le tracce audio in questo linguaggio quando il server o giocatore seleziona automaticamente una traccia.';
	@override String get preferredSubtitleLanguageDescription => 'Preferisci le tracce di sottotitoli in questo linguaggio quando i subtitoli sono selezionati automaticamente.';
	@override String get subtitleAccessibilityDescription => 'Selezionare se le capzioni SDH sono preferite o richieste durante la selezione automatica dei sottotitoli.';
	@override String get forcedSubtitleDescription => 'Scegli se le tracce di sottotitoli forzati sono preferite o richieste durante la selezione automatica.';
	@override String get watchedIndicatorDescription => 'Selezionare quali tipi di media ricevono un checkmark osservato nell\'interfaccia del server.';
	@override String get mediaReviewsVisibilityDescription => 'Scegliere quale pubblico e quali valutazioni critiche il server mostra sulle pagine dei media.';
	@override String get subtitleModeDescription => 'Selezionare quando i sottotitoli si attivano automaticamente per questo account server.';
	@override String get hubDescription => 'Queste preferenze sono memorizzate sul tuo account media-server e possono applicarsi anche ad altri clienti.';
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
	@override late final _Translations$discover$findNext$it findNext = _Translations$discover$findNext$it._(_root);
	@override String get extras => 'Trailer ed extra';
	@override String get studio => 'Studio';
	@override String get rating => 'Valutazione';
	@override String get director => 'Regista';
	@override String get directors => 'Registi';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} minuti rimanenti';
	@override String get moreLikeThis => 'Altri contenuti simili';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titolo',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titoli',
	);
	@override late final _Translations$discover$person$it person = _Translations$discover$person$it._(_root);
}

// Path: errors
class _Translations$errors$it extends Translations$errors$en {
	_Translations$errors$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Ricerca non riuscita: ${error}';
	@override String get searchUnavailable => 'La ricerca non ha potuto raggiungere alcun server multimediale.';
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
	@override String get reasonTimedOut => 'il tempo di connessione è scaduto';
	@override String get reasonUnreachable => 'non è stato possibile raggiungere il server';
	@override String get reasonRefused => 'il server ha rifiutato la richiesta';
	@override String get reasonNotFound => 'l\'elemento non è più presente sul server';
	@override String get reasonServerError => 'il server ha segnalato un errore';
	@override String get reasonCancelled => 'la richiesta è stata annullata';
	@override String get reasonUnexpected => 'si è verificato un errore imprevisto';
}

// Path: libraries
class _Translations$libraries$it extends Translations$libraries$en {
	_Translations$libraries$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Gioca un film casuale';
	@override String get randomPickFailed => 'Non si può scegliere un film casuale da questa biblioteca.';
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
	@override late final _Translations$libraries$advancedFilters$it advancedFilters = _Translations$libraries$advancedFilters$it._(_root);
	@override late final _Translations$libraries$selection$it selection = _Translations$libraries$selection$it._(_root);
}

// Path: about
class _Translations$about$it extends Translations$about$en {
	_Translations$about$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informazioni';
	@override String get openSourceLicenses => 'Licenze open source';
	@override String versionLabel({required Object version}) => 'Versione ${version}';
	@override String get appDescription => 'Un elegante client Plex, Jellyfin ed Emby per Flutter';
	@override String get viewLicensesDescription => 'Visualizza le licenze delle librerie di terze parti';
	@override String get privacyPolicy => 'Informativa sulla privacy';
}

// Path: serverSelection
class _Translations$serverSelection$it extends Translations$serverSelection$en {
	_Translations$serverSelection$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Impossibile caricare i server: ${error}';
	@override String get noValidServers => 'Nessun server utilizzabile trovato per questo account';
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
	@override String get saveLogs => 'Salva i file in file';
	@override String logsSaved({required Object path}) => 'I registri salvati a ${path}';
	@override String get saveLogsFailed => 'Non poteva salvare il file di log.';
}

// Path: startup
class _Translations$startup$it extends Translations$startup$en {
	_Translations$startup$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG non ha potuto avviarsi';
	@override String get failedBody => 'Si è verificato un errore durante l\'avvio. I dettagli seguenti indicano cosa non ha funzionato.';
	@override String get failedBodyRepairable => 'Il file delle impostazioni salvate di PlezyNG è danneggiato e deve essere ricostruito prima che PlezyNG possa avviarsi. Riprovare non servirà: scegli Ripara storage.';
	@override String get phaseLabel => 'Passaggio';
	@override String get showDetails => 'Mostra dettagli';
	@override String get hideDetails => 'Nascondi dettagli';
	@override String get copyDetails => 'Copia dettagli';
	@override String get detailsCopied => 'Dettagli copiati negli appunti';
	@override String get uploadDetails => 'Carica dettagli';
	@override String get repairStorage => 'Ripara storage';
	@override String get repairTitle => 'Riparare i dati archiviati?';
	@override String get repairBodyCommon => 'Il file delle impostazioni di PlezyNG è danneggiato e non può essere letto. La riparazione ripristina ogni impostazione al suo valore predefinito.';
	@override String get repairBodyOneCredential => 'Un accesso salvato è danneggiato e non può essere letto. La riparazione rimuove solo quello; le altre impostazioni restano intatte.';
	@override String get repairBodySignInsKept => 'I tuoi server e profili dovrebbero rimanere con accesso effettuato.';
	@override String get repairBodySignInsLost => 'La chiave che protegge i tuoi accessi salvati non può essere recuperata da questo file, quindi dovrai effettuare di nuovo l\'accesso a ogni server e profilo. Nulla sul tuo server multimediale è interessato.';
	@override String get repairBodySessionsUncertain => 'I tracker (MAL, AniList, Simkl, Trakt) e Seerr sono archiviati separatamente e potrebbero sopravvivere o meno. PlezyNG ti dirà esattamente cosa ha conservato.';
	@override String get repairConfirm => 'Ripara';
	@override String get repairSucceeded => 'Storage riparato';
	@override String get repairNeedsRestart => 'Storage riparato — riavvio richiesto';
	@override String get restartRequiredBody => 'I tuoi dati sono stati riparati, ma PlezyNG deve ripartire da zero prima di poterli usare. Chiudi PlezyNG e riaprilo.';
	@override String get quitPlezy => 'Esci da PlezyNG';
	@override String get repairFailed => 'Riparazione non riuscita';
	@override String get repairKeptSignIns => 'I tuoi server e profili hanno ancora l\'accesso effettuato.';
	@override String get repairLostSignIns => 'La chiave che protegge i tuoi accessi salvati non ha potuto essere recuperata. Dovrai effettuare di nuovo l\'accesso a ogni server e profilo.';
	@override String get repairLostSessions => 'Almeno una connessione a un tracker o a Seerr è andata persa e deve essere riconnessa.';
	@override String get backupTitle => 'È stata conservata una copia del file danneggiato';
	@override String get backupWarning => 'Contiene le tue credenziali di accesso. Non caricarla né condividerla.';
	@override String get deleteBackup => 'Elimina copia';
	@override String get backupDeleted => 'Copia eliminata.';
	@override String get previousFailureTitle => 'PlezyNG non è riuscito ad avviarsi l\'ultima volta';
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
	@override String get liveTv => 'Diretta';
	@override String get explore => 'Esplora';
}

// Path: explore
class _Translations$explore$it extends Translations$explore$en {
	_Translations$explore$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$it mdblistShelves = _Translations$explore$mdblistShelves$it._(_root);
	@override String get title => 'Esplora';
	@override String get selectSource => 'Seleziona fonte';
	@override late final _Translations$explore$rows$it rows = _Translations$explore$rows$it._(_root);
	@override late final _Translations$explore$status$it status = _Translations$explore$status$it._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodi',
	);
	@override String get cast => 'Attori';
	@override String get characters => 'Personaggi';
	@override String get addToWatchlist => 'Aggiungi alla lista da guardare';
	@override String get removeFromWatchlist => 'Rimuovi dalla lista da guardare';
	@override String get addedToWatchlist => 'Aggiunto alla lista titoli';
	@override String get removedFromWatchlist => 'Rimosso dalla lista titoli';
	@override String get watchlistUpdateFailed => 'Impossibile aggiornare la lista da guardare';
	@override String get watchlistNoMatch => 'Impossibile associare questo elemento a una lista titoli';
	@override String get notInLibrary => 'Non è nella tua libreria';
	@override String get inTheseLibraries => 'In queste librerie';
	@override String get checkingLibrary => 'Ricerca nella tua libreria...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: 'Impossibile controllare ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server',
		other: 'Impossibile controllare ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server',
	);
	@override String get emptyTitle => 'Ancora niente qui';
	@override String emptyMessage({required Object source}) => 'Le sezioni di ${source} appariranno qui quando saranno disponibili dei contenuti.';
	@override String searchHint({required Object source}) => 'Cerca su ${source}';
	@override String searchEmpty({required Object query}) => 'Nessun risultato per "${query}"';
	@override String searchPrompt({required Object source}) => 'Cerca film e serie TV su ${source}.';
	@override String get searchFailed => 'Ricerca fallita. Controlla la connessione e riprova.';
	@override late final _Translations$explore$badge$it badge = _Translations$explore$badge$it._(_root);
	@override late final _Translations$explore$stats$it stats = _Translations$explore$stats$it._(_root);
	@override late final _Translations$explore$season$it season = _Translations$explore$season$it._(_root);
	@override late final _Translations$explore$format$it format = _Translations$explore$format$it._(_root);
	@override late final _Translations$explore$sourceMaterial$it sourceMaterial = _Translations$explore$sourceMaterial$it._(_root);
	@override late final _Translations$explore$creditRole$it creditRole = _Translations$explore$creditRole$it._(_root);
	@override late final _Translations$explore$relation$it relation = _Translations$explore$relation$it._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Va in onda ${day} alle ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Va in onda ${day} alle ${time} ${timezone}';
	@override late final _Translations$explore$detail$it detail = _Translations$explore$detail$it._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} risultato',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} risultati',
	);
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
	@override String get timelineLiveProgram => 'Programma dal vivo (il ripristino può essere fuori dal programma)';
	@override String get timelineBuffer => 'TIME TIME di Buffer';
	@override String get timelineUnavailable => 'TIME INCOSPOSIBILE';
	@override String get timelineEstimated => 'Il Playback stimato';
	@override String get timelinePending => 'Per la ricerca';
	@override String get timelineStale => 'Il calendario può essere esaurito';
	@override String get unknownHub => 'Sconosciuto';
	@override String get unknownError => 'Errore sconosciuto';
	@override String channelNumber({required Object number}) => 'Canale ${number}';
	@override String get unknownChannel => 'Canale sconosciuto';
	@override String get live => 'IN DIRETTA';
	@override String get premiereBadge => 'Nuovo';
	@override String get reloadGuide => 'Ricarica la guida';
	@override String get searchGuide => 'Cerca nella guida';
	@override String get searchHint => 'Cerca canali e programmi';
	@override String searchNoResults({required Object query}) => 'Nessuna corrispondenza per "${query}"';
	@override String get channelsSection => 'Canali';
	@override String get programsSection => 'Programmi';
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
	@override String get noFavoriteChannels => 'Nessun canale preferito';
	@override String get noFavoriteChannelsHint => 'Mostra tutti i canali, quindi tieni premuto un canale per aggiungerlo ai preferiti.';
	@override String get showAllChannels => 'Mostra tutti i canali';
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
	@override String get guideReloadFailed => 'Impossibile aggiornare la guida';
	@override String get rulesProcessRequested => 'Rielaborazione delle regole richiesta';
	@override String get rulesProcessFailed => 'Impossibile rielaborare le regole di registrazione';
	@override String get recordShow => 'Registra programma';
	@override late final _Translations$liveTv$recordSettings$it recordSettings = _Translations$liveTv$recordSettings$it._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Inizia tra ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} alle ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} ha restituito dati di riproduzione della TV in diretta non validi';
	@override String get failedToStartChannel => 'Impossibile avviare il canale in diretta';
	@override String get failedToBuildStreamUrl => 'Impossibile creare l\'URL dello stream';
	@override String playbackStartFailed({required Object reason}) => 'Impossibile avviare il canale: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Impossibile cambiare canale: ${reason}';
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
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elemento',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementi',
	);
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
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} brano',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} brani',
	);
	@override String get nowPlaying => 'In riproduzione';
	@override String playingFrom({required Object title}) => 'Riproduzione da ${title}';
	@override String get queue => 'Coda';
	@override String get clearQueue => 'Svuota la coda';
	@override String get lyrics => 'Testo';
	@override String get visualizer => 'Visualizzatore';
	@override String get visualizerProfileLoading => 'Leggi il track analysis...';
	@override String get visualizerAmbientMotion => 'Movimento Ambientale';
	@override String get visualizerPlexLoudness => 'Plex suono';
	@override String get visualizerPreviousPreset => 'Articolo precedenteStyle visivo';
	@override String get visualizerNextPreset => 'Next Stile visivo';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Il blu';
	@override String get visualizerPresetOrbitals => 'orbitali';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'Il tunnel';
	@override String get visualizerPresetTrackMap => 'Mappa di traccia';
	@override String get noLyrics => 'Nessun testo disponibile';
	@override String get sleepTimer => 'Timer di spegnimento';
	@override String get sleepTimerEndOfTrack => 'Fine del brano';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuti',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuti',
	);
	@override String get stopPlayback => 'Interrompi riproduzione';
	@override String get previousTrack => 'Brano precedente';
	@override String get nextTrack => 'Brano successivo';
	@override String get repeat => 'Ripeti';
	@override String get repeatAll => 'Ripeti tutto';
	@override String get repeatOne => 'Ripeti il brano';
	@override String get instantMixNoServer => 'Nessun server disponibile per un mix istantaneo';
	@override String get instantMixFailed => 'Impossibile caricare il mix istantaneo';
	@override String get instantMixEmpty => 'Il mix istantaneo non ha prodotto alcun brano';
	@override String noAudioUrl({required Object track}) => 'Nessun URL audio disponibile per ${track}';
	@override late final _Translations$music$discography$it discography = _Translations$music$discography$it._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$it extends Translations$watchTogether$en {
	_Translations$watchTogether$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guarda insieme';
	@override String get description => 'Guarda contenuti in sincronia con amici e familiari';
	@override String get createRoom => 'Crea stanza';
	@override String get creatingRoom => 'Creazione della stanza...';
	@override String get joinRoom => 'Unisciti a una stanza';
	@override String get joiningRoom => 'Ingresso nella stanza...';
	@override String get connecting => 'Connessione in corso...';
	@override String get relayPublic => 'Le stanze usano i relay pubblici di Open Watch Party.';
	@override String relayCustom({required Object url}) => 'Le stanze usano il tuo relay all\'indirizzo ${url}.';
	@override String get recentRooms => 'Stanze usate di recente';
	@override String get roomActions => 'Azioni della stanza';
	@override String get renameRoom => 'Rinomina stanza';
	@override String get removeRoom => 'Rimuovi';
	@override String get enterRoomCode => 'Inserisci il codice di 6 caratteri ricevuto dall\'host.';
	@override String get roomCode => 'Codice stanza';
	@override String get paste => 'Incolla';
	@override String get noCodeInClipboard => 'Gli appunti non contengono un codice stanza';
	@override String get copyCode => 'Copia codice';
	@override String get codeCopied => 'Codice stanza copiato';
	@override String get shareInvite => 'Condividi invito';
	@override String get inviteCopied => 'Invito copiato. Incollalo in un messaggio.';
	@override String inviteMessage({required Object code}) => 'Unisciti alla mia stanza di Guarda insieme su PlezyNG: apri «Guarda insieme», scegli «Unisciti a una stanza» e inserisci ${code}.';
	@override String get openSessionControls => 'Apri i controlli della sessione di Guarda insieme';
	@override String get reconnecting => 'Riconnessione...';
	@override String get reconnectingDescription => 'La connessione si è interrotta. Rientrerai automaticamente nella stanza.';
	@override String get connected => 'Connesso';
	@override String get disconnected => 'Disconnesso';
	@override String get youAreHost => 'Sei l\'host';
	@override String hostedBy({required Object name}) => 'Ospitata da ${name}';
	@override String get hostControlsPlayback => 'L\'host controlla la riproduzione';
	@override String get anyoneCanControl => 'Tutti possono controllare la riproduzione';
	@override String get roomLocked => 'Stanza bloccata';
	@override String get nowPlaying => 'In riproduzione';
	@override String get nothingPlaying => 'Nessuna riproduzione in corso';
	@override String get nothingPlayingHost => 'Riproduci qualcosa da una qualsiasi libreria per condividerlo con la stanza.';
	@override String get nothingPlayingGuest => 'Quando l\'host avvia qualcosa, si aprirà qui.';
	@override String get notShareable => 'Questo video non ha corrispondenze nel catalogo, quindi può riprodurlo solo chi ha accesso allo stesso server.';
	@override String get searching => 'Ricerca di questo video nelle tue librerie...';
	@override String get yourCopy => 'La tua copia';
	@override String get sharingYourCopy => 'Stai condividendo la tua copia';
	@override String playingOtherLength({required Object difference}) => 'Riproduzione della tua copia, ${difference}';
	@override String get mismatchTitle => 'La tua copia ha una durata diversa';
	@override String mismatchDescription({required Object difference}) => 'La tua copia più simile dura ${difference} rispetto al video della stanza. Potrebbe trattarsi di un altro montaggio o di un\'altra versione.';
	@override String get playAnyway => 'Riproduci comunque';
	@override String get chooseAnotherCopy => 'Scegli un\'altra copia';
	@override String get dontPlay => 'Non riprodurre';
	@override String get unavailableTitle => 'Non hai questo video';
	@override String get unavailableDescription => 'PlezyNG non l\'ha trovato nelle tue librerie. Scegli tu una copia o cerca di nuovo.';
	@override String get chooseCopy => 'Scegli una copia';
	@override String get searchAgain => 'Cerca di nuovo';
	@override String get noCandidates => 'Nessuna copia trovata nelle tue librerie.';
	@override String get choiceFailed => 'Impossibile riprodurre questa copia per la stanza';
	@override String lengthLonger({required Object duration}) => '${duration} in più';
	@override String lengthShorter({required Object duration}) => '${duration} in meno';
	@override String get lengthSame => 'Stessa durata';
	@override String get lengthUnknown => 'Durata sconosciuta';
	@override String get joinCurrentPlayback => 'Unisciti alla riproduzione corrente';
	@override String get joinCurrentPlaybackDescription => 'Torna a ciò che l\'host sta guardando in questo momento';
	@override String get stopMedia => 'Interrompi il video per tutti';
	@override String get syncOffset => 'Offset di sincronizzazione';
	@override String get syncOffsetDescription => 'Sposta il tuo video se è in anticipo o in ritardo rispetto alla stanza.';
	@override String offsetHint({required Object difference}) => 'La tua copia dura ${difference} rispetto al video della stanza.';
	@override String applyDifference({required Object offset}) => 'Usa ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Partecipanti';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} partecipante',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} partecipanti',
	);
	@override String get hostBadge => 'HOST';
	@override String nameYou({required Object name}) => '${name} (tu)';
	@override String get playerIdle => 'Inattivo';
	@override String get playerLoading => 'Caricamento';
	@override String get playerReady => 'Pronto';
	@override String get playerBuffering => 'Buffering';
	@override String get matchSearching => 'Ricerca in corso';
	@override String get matchMatched => 'Ha il video';
	@override String get matchMismatched => 'Durata diversa';
	@override String get matchUnavailable => 'Non ha il video';
	@override String participantOffset({required Object offset}) => 'Offset ${offset}';
	@override String get makeHost => 'Rendi host';
	@override String get makeHostQuestion => 'Trasferire il ruolo di host?';
	@override String makeHostConfirm({required Object name}) => '${name} controllerà la riproduzione e guiderà la sessione per tutti.';
	@override String get transfer => 'Trasferisci';
	@override String get removeParticipant => 'Rimuovi dalla stanza';
	@override String removeParticipantQuestion({required Object name}) => 'Rimuovere ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} uscirà dalla stanza. Potrà rientrare con il codice, a meno che tu non blocchi la stanza.';
	@override String get remove => 'Rimuovi';
	@override String get roomSettings => 'Impostazioni della stanza';
	@override String get letEveryoneControl => 'Consenti a tutti di controllare la riproduzione';
	@override String get lockRoom => 'Blocca stanza';
	@override String get lockRoomDescription => 'Nessun nuovo partecipante può entrare';
	@override String get leaveRoom => 'Abbandona stanza';
	@override String get leaveRoomQuestion => 'Abbandonare la stanza?';
	@override String get leaveRoomConfirm => 'Potrai rientrare con il codice della stanza.';
	@override String get leave => 'Abbandona';
	@override String get endRoom => 'Chiudi stanza';
	@override String get endRoomQuestion => 'Chiudere la stanza?';
	@override String get endRoomConfirm => 'La stanza verrà chiusa per tutti.';
	@override String get end => 'Termina';
	@override String get playBlockedTitle => 'La riproduzione non è partita';
	@override String get playBlockedDescription => 'Premi Riproduci per iniziare a guardare con la stanza.';
	@override late final _Translations$watchTogether$notices$it notices = _Translations$watchTogether$notices$it._(_root);
	@override late final _Translations$watchTogether$ended$it ended = _Translations$watchTogether$ended$it._(_root);
	@override late final _Translations$watchTogether$errors$it errors = _Translations$watchTogether$errors$it._(_root);
	@override String untitledEpisode({required Object number}) => 'Episodio ${number}';
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
	@override String get storageFull => 'I download sono stati interrotti per preservare lo spazio disponibile. Libera spazio o scegli un’altra posizione di download, quindi riprova.';
	@override String get storageUnavailable => 'I download sono stati interrotti perché non è stato possibile verificare lo spazio di archiviazione disponibile. Controlla la posizione di download e riprova.';
	@override String episodesQueued({required Object count}) => '${count} episodi in coda per il download';
	@override String get downloadDeleted => 'Download eliminato';
	@override String deleteConfirm({required Object title}) => 'Eliminare "${title}" da questo dispositivo?';
	@override String get deleteCollectionDownloads => 'Elimina i download';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Eliminare tutti i download di "${title}" da questo dispositivo?';
	@override String get collectionDownloadsDeleted => 'Download eliminati';
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
	@override String get retryAll => 'Riprova tutti';
	@override String get retryFailed => 'Riprova i download non riusciti';
	@override String get deleteAll => 'Elimina tutto';
	@override String get selectVersion => 'Seleziona la versione';
	@override String get allEpisodes => 'Tutti gli episodi';
	@override String get unwatchedOnly => 'Solo non visti';
	@override String nextNUnwatched({required Object count}) => 'Prossimi ${count} episodi non visti';
	@override String get customAmount => 'Quantità personalizzata...';
	@override String get customAmountAny => 'Quanti sono i vari (quanti sono i)';
	@override String get randomEpisodes => 'Episodi casuali';
	@override String get includeSpecials => 'Includi gli speciali';
	@override String get howManyEpisodes => 'Quanti episodi?';
	@override String get invalidEpisodeCount => 'Inserisci un numero di episodi valido.';
	@override String get keepSynced => 'Mantieni sincronizzato';
	@override String get downloadOnce => 'Scarica una volta';
	@override String keepNUnwatched({required Object count}) => 'Mantieni ${count} episodi non visti';
	@override String get editSyncRule => 'Modifica regola di sincronizzazione';
	@override String get removeSyncRule => 'Rimuovi regola di sincronizzazione';
	@override String removeSyncRuleConfirm({required Object title}) => 'Interrompere la sincronizzazione di "${title}"? Gli episodi scaricati verranno mantenuti.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Interrompere la sincronizzazione di "${title}"?';
	@override String get deleteSyncRuleDownloads => 'Elimina anche i download associati';
	@override String get deleteSyncRuleDownloadsDescription => 'I download usati da un\'altra regola di sincronizzazione o da un altro profilo verranno conservati.';
	@override String syncRuleCreated({required Object count}) => 'Regola di sincronizzazione creata — ${count} episodi non visti mantenuti';
	@override String get syncRuleUpdated => 'Regola di sincronizzazione aggiornata';
	@override String get syncRuleRemoved => 'Regola di sincronizzazione rimossa';
	@override String get syncRuleAndDownloadsRemoved => 'Regola di sincronizzazione e download associati rimossi';
	@override String get syncRuleCleanupBusy => 'Le regole di sincronizzazione sono in fase di aggiornamento. Riprova tra un momento.';
	@override String get syncRuleCleanupUnavailable => 'Non è stato possibile identificare in sicurezza i download associati. Riconnetti il server e riprova, oppure rimuovi la regola senza eliminare i download.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} nuovi episodi sincronizzati per ${title}';
	@override String get syncNow => 'Sincolo ora';
	@override String get downloadsUpToDate => 'Le scaricazioni sono aggiornate';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sincronizzazione completa · ${queued} quued, ${removed} rimosso';
	@override String get activeSyncRules => 'Regole di sincronizzazione';
	@override String get reviewOrphanFiles => 'Rivedi i download orfani';
	@override String get orphanReviewTitle => 'Rivedi i download orfani';
	@override String get orphanReviewDescription => 'Questi file contrassegnati si trovano nelle cartelle di download predefinite gestite da PlezyNG e non hanno una voce di download corrispondente né un’attività in corso. Controlla l’elenco prima di eliminarli.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} file · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Elimina ${count} file';
	@override String get orphanCleanupNone => 'Nessun file di download orfano trovato';
	@override String get orphanCleanupFailed => 'PlezyNG non è riuscito a eseguire una scansione sicura della cartella di download gestita. Non è stato eliminato alcun file.';
	@override String get orphanCleanupChanged => 'L’elenco dei download è cambiato durante la revisione. Controlla di nuovo i file prima di ripulire.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Eliminati ${count} file di download orfani · liberati ${size}';
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
	@override String get syncRuleAccessDenied => 'Accesso negato';
	@override String get syncRuleNotAvailableForProfile => 'Non disponibile per il profilo attuale';
	@override String get syncRuleUnknownServer => 'Server sconosciuto';
	@override String get syncRuleListCreated => 'Regola di sincronizzazione creata';
	@override late final _Translations$downloads$backgroundWarning$it backgroundWarning = _Translations$downloads$backgroundWarning$it._(_root);
	@override String get options => 'Opzioni download';
	@override late final _Translations$downloads$groupings$it groupings = _Translations$downloads$groupings$it._(_root);
	@override String get unknownLibrary => 'Libreria sconosciuta';
	@override String get unknownShow => 'Serie sconosciuta';
	@override String get unknownSeason => 'Stagione sconosciuta';
	@override String get unknownAlbum => 'Album sconosciuto';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} completati';
	@override String storageUsed({required Object size}) => 'Storage utilizzato: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mostra',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mostri',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
	);
	@override String get errorFileNotFound => 'File non trovato (404)';
	@override String get errorDownloadNotAllowed => 'Download non consentito dal server (403)';
	@override String get errorDownloadFailed => 'Download non riuscito';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Download non riuscito: ${reason}';
	@override String get convertingOnServer => 'Convertire il server...';
	@override String convertingOnServerPercent({required Object percent}) => 'Conversione sul server · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Download non riuscito (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Post-elaborazione non riuscita: ${reason}';
	@override String get reasonFileNotSaved => 'non è stato possibile salvare il file su questo dispositivo';
	@override String get reasonCannotResume => 'non è stato possibile riprendere il download parziale';
	@override String get reasonDeviceStorageFull => 'lo spazio di archiviazione di questo dispositivo è esaurito';
	@override String get notificationDownloading => 'Download in corso...';
	@override String get notificationComplete => 'Download completato';
	@override String get notificationPaused => 'Download in pausa';
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
	@override String get closedBeforeAuth => 'La connessione si è chiusa prima dell\'autenticazione';
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
	@override String get hdrUnsupported => 'HDR non è disponibile qui: questo compositore desktop o questa uscita video non possono gestirlo.';
	@override String get hdrToneMapping => 'Mappatura dei toni HDR';
	@override String get hdrToneMappingCompositor => 'Compositore';
	@override String get hdrToneMappingCompositorDescription => 'Trasmette i metadati HDR della sorgente e lascia che il compositore desktop esegua la mappatura.';
	@override String get hdrToneMappingPlayer => 'Lettore';
	@override String get hdrToneMappingPlayerDescription => 'Esegue nel lettore la mappatura in base alla luminosità di picco dello schermo, quindi comunica il risultato al compositore.';
	@override String get hdrToneMappingFailed => 'Impossibile modificare la mappatura dei toni HDR: la modalità precedente è ancora attiva.';
	@override String get audioOutput => 'Uscita audio';
	@override String get videoTrack => 'Traccia video';
	@override String get videoTrackDescription => 'Scegli quale flusso video mostrare. Disponibile con la riproduzione MPV quando il file contiene tracce video alternative.';
	@override String get videoTrackDefault => 'Predefinita';
	@override String get videoTrackUnavailable => 'Non sono disponibili tracce video alternative.';
	@override String get videoTrackFailed => 'Impossibile cambiare la traccia video.';
	@override String videoTrackNumber({required Object id}) => 'Traccia ${id}';
	@override String get performanceOverlay => 'Overlay prestazioni';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Audio spaziale';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Audio equalizzatore';
	@override String get audioEqualizerDescription => 'equalizzatore di 10 bandi per MPVI filtri audio utilizzano l\'audio decodito e disattivano passthrough.';
	@override String get audioEqualizerFlat => 'Neutro';
	@override String get audioEqualizerActive => 'Personalizzato';
	@override String get audioEqualizerSaveFailed => 'Non poteva salvare le impostazioni di equalizzatore audio.';
	@override String get audioEffectsDescription => 'Effetti utilizzano audio decodato, quindi passthrough si spegne. ambiente in camera e estensione stereo dipendono dal MPV costruire e tracciare.';
	@override String get audioStereoWidth => 'Stereo ampliamento';
	@override String get audioSpatializer => 'ambienti di camera';
	@override String get audioSpatializerDescription => 'Aggiungi riflessioni silenziose.';
	@override String get audioPitch => 'Cambiamento di Pitch';
	@override String get audioPitchDescription => 'Cambiare la pista senza cambiare velocità. MPV La costruzione deve includere Rubber Bande il';
	@override String get audioEffectUnavailable => 'Questo effetto non è disponibile per questo percorso o MPV di costruire.';
	@override String get backgroundVideoAudio => 'Video audio di background';
	@override String get backgroundVideoAudioDescription => 'Mantenere il video audio riprodotto quando si lascia il lettore; l\'immagine è nascosta fino a quando non si ritorna. Android utilizza una notifica di riproduzione dei media.';
	@override String get audioNormalization => 'Normalizza il volume';
	@override String get audioNormalizationDisablesPassthrough => 'Decodifica l\'audio in PCM; il passthrough è disattivato mentre questa opzione è attiva';
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
	@override String get passthrough => 'Passthrough';
	@override String get aspect => 'Proporzioni';
	@override String get rotation => 'Rotazione';
	@override String get dvSource => 'Sorgente DV';
	@override String get dvPath => 'Percorso DV';
	@override String get dvRouteDecoder => 'Decoder Dolby Vision';
	@override String get dvRouteDecoderP81 => 'Decoder Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Livello base';
	@override String get dvRouteBaseLayerHdr10 => 'Livello base HDR10';
	@override String get dvRouteBaseLayerHlg => 'Livello base HLG';
	@override String get dvRouteBaseLayerSdr => 'Livello base SDR';
	@override String get dvRouteReshaped => 'Rimodellato con RPU (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Il grafico sperimentale P7 FEL (non qualificato)';
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
	@override String get playMethod => 'Metodo di gioco';
	@override String get memory => 'Memoria';
	@override String get uiFps => 'FPS UI';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Software';
	@override String get decoderHardware => 'Hardware';
	@override String get tunnelingActive => 'Attivo';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} errori)';
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
	@override String get description => 'Scegli un\'altra app per aprire i video in. I giocatori disponibili dipendono dal tuo dispositivo e dalle applicazioni installate.';
	@override String get systemDefaultDescription => 'Lascia che il sistema operativo apri il video con la sua app predefinita.';
	@override String playerOptionDescription({required Object player}) => 'Apri i video con ${player}.';
	@override String get playerNameDescription => 'L\'etichetta visualizzata nella lista dei giocatori.';
	@override String get playerPackageDescription => 'Inserisci il nome del pacchetto Android dell\'app giocatore, come com.example.player.';
	@override String get playerCommandDescription => 'Inserisci il comando del giocatore installato o la strada eseguibile per questo dispositivo.';
	@override String get playerUrlSchemeDescription => 'Inserisci lo schema URL e il modello URL opzionale utilizzato per lanciare il giocatore.';
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
	@override String get quickTag => 'Tag rapido...';
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
	@override String get disconnectConfirmBody => 'PlezyNG smetterà di inviare eventi a Trakt. Puoi riconnetterti quando vuoi.';
	@override String get scrobble => 'Scrobbling in tempo reale';
	@override String get scrobbleDescription => 'Invia eventi di riproduzione, pausa e arresto a Trakt durante la riproduzione.';
	@override String get watchedSync => 'Sincronizza lo stato di visione';
	@override String get watchedSyncDescription => 'Quando contrassegni un elemento come visto in PlezyNG, viene contrassegnato come visto anche su Trakt.';
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
	@override String get noSignInMethods => 'Questa istanza Seerr non offre alcun metodo di accesso supportato da PlezyNG.';
	@override String get instance => 'Istanza';
	@override String get disconnectConfirm => 'Disconnettere Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG rimuoverà questa istanza Seerr. Potrai riconnetterla in qualsiasi momento.';
	@override String get request => 'Richiedi';
	@override String get request4k => 'Richiedi in 4K';
	@override String get seasons => 'Stagioni';
	@override String get allSeasons => 'Tutte le stagioni';
	@override String get advancedOptions => 'Avanzate';
	@override String get destinationServer => 'Server di destinazione';
	@override String get qualityProfile => 'Profilo di qualità';
	@override String get rootFolder => 'Cartella radice';
	@override String get languageProfile => 'Profilo della lingua';
	@override String get tags => 'Tag';
	@override String get noTags => 'Nessun tag';
	@override String defaultOption({required Object name}) => '${name} (predefinito)';
	@override String get animeNote => 'Questa serie è un anime.';
	@override String get requestSubmitted => 'Richiesta inviata';
	@override String requestFailed({required Object error}) => 'Richiesta non riuscita: ${error}';
	@override String get requestsLoadFailed => 'Impossibile caricare le opzioni di richiesta';
	@override String get nothingToRequest => 'Tutto è già disponibile o richiesto.';
	@override String get statusAvailable => 'Disponibile';
	@override String get statusPartiallyAvailable => 'Disponibile in parte';
	@override String get statusRequested => 'Richiesto';
	@override String get statusProcessing => 'In elaborazione';
	@override String get statusBlocklisted => 'Nella lista di blocco';
	@override String couldNotReach({required Object url, required Object error}) => 'Impossibile raggiungere ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Nessuna istanza Seerr all\'indirizzo ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Un reverse proxy con autenticazione (SSO o autenticazione HTTP) ha risposto al posto di Seerr. PlezyNG non può accedere attraverso di esso: consenti al percorso /api/v1 di Seerr di bypassare il proxy per questa app, oppure usa un indirizzo che raggiunga Seerr direttamente.';
	@override String get invalidUrl => 'Inserisci un indirizzo del server come https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Questa istanza Seerr non supporta Quick Connect. È necessaria la versione 3.4 o successiva di Seerr.';
	@override String get notInitialized => 'Questa istanza Seerr non ha completato la configurazione iniziale';
	@override String get noPlexTokenForReauth => 'Nessun token Plex disponibile per effettuare nuovamente l\'accesso';
	@override String get noStoredCredentials => 'Nessuna credenziale salvata disponibile per effettuare nuovamente l\'accesso';
	@override String get signInRejected => 'L\'accesso è stato rifiutato';
	@override String get noSessionCookie => 'Seerr non ha generato un cookie di sessione';
	@override String get freshCookieRejected => 'Seerr ha rifiutato il nuovo cookie di sessione';
	@override String get noUserInformation => 'Seerr non ha restituito le informazioni sull\'utente';
	@override String get sessionRejectedAfterReauth => 'La sessione è stata rifiutata dopo aver effettuato nuovamente l\'accesso';
	@override String get permissionDenied => 'Seerr ha negato questa azione: il tuo account non dispone più dell\'autorizzazione richiesta';
	@override String get permissionRevoked => 'Non hai più l\'autorizzazione per richiederlo';
}

// Path: services
class _Translations$services$it extends Translations$services$en {
	_Translations$services$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Servizi';
	@override String get hubSubtitle => 'Sincronizza i progressi di visione e richiedi nuovi titoli.';
	@override String get integrations => 'Integrazioni';
	@override String get notConnected => 'Non connesso';
	@override String connectedAs({required Object username}) => 'Connesso come @${username}';
	@override String get scrobble => 'Registra automaticamente i progressi';
	@override String get scrobbleDescription => 'Aggiorna la tua lista quando termini un episodio o un film.';
	@override String disconnectConfirm({required Object service}) => 'Disconnettere ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG smetterà di aggiornare ${service}. Riconnetti quando vuoi.';
	@override String connectFailed({required Object service}) => 'Impossibile connettersi a ${service}. Riprova.';
	@override late final _Translations$services$names$it names = _Translations$services$names$it._(_root);
	@override late final _Translations$services$simklReconnect$it simklReconnect = _Translations$services$simklReconnect$it._(_root);
	@override late final _Translations$services$deviceCode$it deviceCode = _Translations$services$deviceCode$it._(_root);
	@override late final _Translations$services$oauthProxy$it oauthProxy = _Translations$services$oauthProxy$it._(_root);
	@override late final _Translations$services$pendingAuth$it pendingAuth = _Translations$services$pendingAuth$it._(_root);
	@override late final _Translations$services$libraryFilter$it libraryFilter = _Translations$services$libraryFilter$it._(_root);
	@override String get seerrDescription => 'Connettiti a Seerr o Overseerr per cercare titoli e inviare richieste di media.';
	@override late final _Translations$services$trackerDescriptions$it trackerDescriptions = _Translations$services$trackerDescriptions$it._(_root);
}

// Path: addServer
class _Translations$addServer$it extends Translations$addServer$en {
	_Translations$addServer$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Aggiungi server ${product}';
	@override String get serverUrls => 'URL del server';
	@override String get serverUrlsHelper => 'Sono consentiti più URL, separati da virgole.';
	@override String get findServer => 'Trova il server';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Ricerca di server ${product} locali...';
	@override String localMediaBrowserServers({required Object product}) => 'Server ${product} locali';
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
	@override String enterMediaBrowserUrlError({required Object product}) => 'Inserisci l\'URL del server ${product}';
	@override String get addConnectionTitle => 'Aggiungi connessione';
	@override String addConnectionTitleScoped({required Object name}) => 'Aggiungi a ${name}';
	@override String get signInWithPlexCard => 'Accedi con Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorizza questo dispositivo. I server condivisi vengono aggiunti.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorizza un account Plex. Gli utenti Home diventano profili.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Connettiti a ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Inserisci l\'URL del server, il nome utente e la password.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Accedi al tuo server ${product}. Associato a ${name}.';
	@override String get borrowFromAnotherProfile => 'Prendi in prestito da un altro profilo';
	@override String get borrowFromAnotherProfileSubtitle => 'Riutilizza la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.';
	@override String get invalidCredentials => 'Nome utente o password non validi';
	@override String get authResponseNotJson => 'La risposta di autenticazione non era un JSON valido';
	@override String get authResponseIncomplete => 'La risposta di accesso del server era incompleta';
	@override String get quickConnectRejected => 'Quick Connect è stato rifiutato dal server';
	@override String get quickConnectNotJson => 'La risposta di Quick Connect non era un JSON valido';
	@override String get quickConnectMissingFields => 'Nella risposta di Quick Connect manca un codice o un segreto';
	@override String get quickConnectPollRejected => 'Il polling di Quick Connect è stato rifiutato dal server';
	@override String get serverTimedOut => 'Il server non ha risposto in tempo';
	@override String get responseNotJson => 'La risposta del server non era un JSON valido';
	@override String responseMissingIdentity({required Object product}) => 'Nella risposta manca un ID o il nome del server: è un server ${product}?';
	@override String probeFailed({required Object error}) => 'Impossibile raggiungere il server: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Inserisci almeno un URL di un server ${product}';
	@override String noReachableServer({required Object product}) => 'Non è stato trovato alcun server ${product} raggiungibile';
	@override String urlsPointToDifferentServers({required Object product}) => 'Questi URL rimandano a server ${product} diversi';
	@override String urlDoesNotMatchServer({required Object product}) => 'Questo URL non corrisponde al server ${product}';
	@override String get redirectUnsupported => 'Il server ha reindirizzato a un URL non supportato';
	@override String redirectDifferentHost({required Object product}) => 'Il server ha reindirizzato a un host diverso. Inserisci direttamente l\'URL finale del server ${product}.';
	@override String get redirectInsecure => 'Il server ha reindirizzato da HTTPS a un URL non sicuro';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Il server ha reindirizzato a un URL non supportato. Inserisci direttamente l\'URL finale del server ${product}.';
	@override String get directPlexServerUrl => 'URL del server Plex';
	@override String get directPlexServerUrlHelper => 'Inserisci l\'IP locale e il port del tuo server di media Plex .';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (opzionale)';
	@override String get plexTokenHelper => 'Lascia vuoto se l\'accesso senza auth è consentito su questo server.';
	@override String get plexTokenRequired => 'Si prega di inserire il tuo token Plex (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Media Server (diretto / locale)';
	@override String get connectDirectPlexCardSubtitle => 'Connettiti direttamente utilizzando IP o URL locali senza account plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Connettiti direttamente utilizzando IP locale o URL. Connettiti a ${name}.';
	@override String get insecureTitle => 'Connessione non crittografata';
	@override String insecureDescription({required Object url}) => '${url} usa HTTP. Altre persone sulla rete potrebbero leggere o modificare la password, i token e i contenuti multimediali. Usa HTTPS quando disponibile. Continua solo se ti fidi di questa rete e accetti il rischio.';
	@override String get allowHttp => 'Consenti HTTP';
	@override String get httpsRequired => 'Utilizzare HTTPS o consentere esplicitamente una connessione non crittografata.';
}

// Path: cast
class _Translations$cast$it extends Translations$cast$en {
	_Translations$cast$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Cattura a un dispositivo';
	@override String get searching => 'Cercare i dispositivi di cast...';
	@override String connectedTo({required Object device}) => 'Connetto a ${device}';
	@override String get device => 'Dispositivi di Cast';
	@override String get readyToCast => 'Pronte a lanciare';
	@override String get subtitle => 'Sottotitoli';
	@override String get serverNotAvailable => 'Il server dei media non è disponibile.';
	@override String get stopCasting => 'smettere di casting';
	@override String get castToDevice => 'Cattura per il dispositivo';
	@override String get noEpisodeAvailable => 'Non ci sono episodi disponibili per essere lanciati.';
	@override String get startFailed => 'Non è possibile iniziare la casta. controllare il server e provare di nuovo.';
}

// Path: automation
class _Translations$automation$it extends Translations$automation$en {
	_Translations$automation$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Non c’è sessione video attiva da controllare.';
}

// Path: notifications
class _Translations$notifications$it extends Translations$notifications$en {
	_Translations$notifications$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Nuovo episodio';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$it extends Translations$appAccess$en {
	_Translations$appAccess$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Prova ogni funzione gratuita per 7 giorni';
	@override String get description => 'Inizia un test di sette giorni con accesso completo a ogni funzione PlezyNG. non ci sono costi durante il test e non ci sono abbonamenti. Dopo il test, un acquisto di vita al prezzo del tuo negozio rilascia PlezyNG per tutta la vita.';
	@override String get trialEndedDescription => 'Rimuovere ogni funzionalità in PlezyNG per tutta la vita con un acquisto al prezzo del tuo negozio.';
	@override String get startTrial => 'Inizia il mio trial gratuito di 7 giorni';
	@override String get trialActive => 'Il tuo test di 7 giorni è attivo.';
	@override String get trialEnded => 'Il processo di 7 giorni è finito';
	@override String get trialStartFailed => 'Non potevo salvare il test su questo dispositivo. si prega di provare di nuovo.';
	@override String get lifetimeTitle => 'PlezyNG disattivato per la vita';
	@override String get lifetimeBody => 'Grazie! avete accesso a tutti i PlezyNG funzionalità.';
	@override String get manageTitle => 'PlezyNG accesso a vita';
	@override String get manageDescription => 'Prova ogni funzionalità gratuita per 7 giorni, poi disattivare tutto per tutta la vita con un solo pagamento al prezzo del tuo negozio.';
	@override String buy({required Object price}) => 'Rimuovere ogni funzionalità per ${price}';
	@override String get loadingPrice => 'Il prezzo del negozio...';
	@override String get retryPrice => 'Il prezzo di ritorno';
	@override String get restore => 'Ristrutturazione acquisto per tutta la vita';
	@override String get pending => 'L\'acquisto è in attesa di pagamento o approvazione.L\'accesso a tempo pieno si distacca non appena il negozio lo completa.';
	@override String get storeUnavailable => 'Verificare che si è iscritti al negozio e gli acquisti sono consentiti su questo dispositivo.';
	@override String get productNotFound => 'Il disattivatore di vita PlezyNG non è ancora disponibile in questo negozio.';
	@override String get productQueryFailed => 'Non poteva caricare il prezzo del negozio. verificare la connessione e provare di nuovo.';
	@override String get purchaseFailed => 'L’acquisto non è andato via, prova di nuovo.';
	@override String get restoreFailed => 'Non potevo raggiungere il negozio per ripristinare l\'acquisto. prova di nuovo.';
	@override String get nothingToRestore => 'N. PlezyNG acquisto a vita è stato trovato per questo account del negozio.';
}

// Path: detail
class _Translations$detail$it extends Translations$detail$en {
	_Translations$detail$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Termina alle ${time}';
}

// Path: watchLink
class _Translations$watchLink$it extends Translations$watchLink$en {
	_Translations$watchLink$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Non potevo raggiungere un server Plex per questo link.';
	@override String get notFound => 'Non potevo trovare questo spettacolo o film sui tuoi server Plex.';
	@override String get ambiguous => 'Questo link corrisponde agli elementi su più di un server. Aggiungi un server al link.';
	@override String get plexOnly => 'I link di monitoraggio supportano attualmente solo i server Plex.';
	@override String get unsupportedItem => 'I link di guardare possono aprire solo un programma o un film.';
	@override String get menuItem => 'Visualizza il link';
	@override String get dialogTitle => 'Guarda il link';
	@override String get dialogShowHint => 'Aprire questo link gioca il prossimo episodio. Aggiungi &mode=shuffle alla fine per giocare lo spettacolo su shuffle.';
	@override String get dialogMovieHint => 'Aprire questo link gioca il film.';
	@override String get copy => 'Copia';
	@override String get copied => 'Link copia';
}

// Path: homeLayout
class _Translations$homeLayout$it extends Translations$homeLayout$en {
	_Translations$homeLayout$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Layout';
	@override String get resetToast => 'Home Ristrutturazione all\'originale layout Plezy';
	@override String get resetHeroTitle => 'Ristrutturare il layout del eroe al stock Plezy?';
	@override String get resetHeroBody => 'Ritorna il set di eroe di ogni riga e riporta il singolo banner rotativo al top di Home, come prima che le riga eroe esistessero.';
	@override String get removeRowTitle => 'Rimuovere la linea di casa?';
	@override String removeRowBody({required Object title}) => '${title} sarà cancellato. non può essere negato.';
	@override String get sync => 'Sincolo';
	@override String get syncAccountTitle => 'Sincronti il layout con il tuo account Plex';
	@override String get syncAccountOn => 'In: questo dispositivo condivide ordine di ordine, righe, Hero e Auto-slide con gli altri dispositivi.';
	@override String get syncAccountOff => 'Off: questo dispositivo mantiene il suo layout.';
	@override String get syncNow => 'Sincolo ora';
	@override String get plexHomeManager => 'Plex Direttore di casa';
	@override String get managePlexRows => 'Gestione Plex righe in Plezy';
	@override String get managePlexRowsDescription => 'Aperto per organizzare le righe selezionate in casa';
	@override String get organizeHomeRows => 'Organizzare le linee di casa';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} righe: movimento, eroe, auto-slide, rimozione';
	@override String organizeLibraryRows({required Object library}) => 'Organizzare ${library} righe';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Continua a guardare + ${n} righe: movimento, Biblioteca, Home, Eroe, Auto-slide';
	@override String get renderAsHero => 'Render come carta di eroe';
	@override String get heroOnlySingleCollection => 'Disponibile solo quando questa fila si risolve ai titoli reali di una singola collezione';
	@override String get hero => 'Eroe';
	@override String get autoSlide => 'Auto-Slide';
	@override String get autoSlideDescription => 'Arrows (PC) e d-pad (TV) sempre funzionano e riavviano il timer.';
	@override String get autoSlideEditDescription => 'Spegne: si muove solo quando si fa clic su una pistola (PC) o premere sinistra/diretta sul remote (TV).';
	@override String get enableHeroFirst => 'Permettere il primo eroe';
	@override String get showOnHome => 'Mostra su Home Screen';
	@override String get home => 'Home';
	@override String get removeFromHome => 'Rimuovere da casa';
	@override String get selectRowsFirst => 'Selezionare le linee di casa sotto prima.';
	@override String plexManagedRows({required Object n}) => '${n} Plex righe gestite';
	@override String get continueWatching => 'Continua a guardare';
	@override String get continueWatchingLibraryDescription => 'La linea di ritorno di questa biblioteca';
	@override String get continueWatchingHomeDescription => 'La riga di progresso di ritorno mostrata a casa';
	@override String get nextUpHomeDescription => 'La prossima sequenza di episodi non osservati mostrata separatamente su Home';
	@override String get library => 'Libreria';
	@override String get showInRecommended => 'Mostra in Biblioteca raccomandata';
	@override String get customPlexRow => 'Modello di guida Plex';
	@override String get heroNeedsLibrary => 'Scopri la biblioteca prima - Hero ha bisogno di qualche parte per mostrare';
	@override String get heroNeedsSurface => 'Scopri la biblioteca o la casa prima - il protagonista ha bisogno di qualche parte per mostrare';
	@override String get removeHub => 'Rimuovere Hub';
	@override String get noPlexRows => 'N. Plex rami gestiti restituiti per questa biblioteca.';
	@override String get openDetails => 'Dettagli aperti';
	@override String get heroCards => 'Carte di eroe';
	@override String get tapHeroCard => 'Scopri una carta di eroe';
	@override String get tvPlayFocus => 'Remote TV: il pulsante di gioco';
	@override String get tvPlayFocusDescription => 'D-pad down si ferma sul pulsante Play prima di muoversi alla prossima riga.';
	@override String get tvWrap => 'Remote TV: carte di eroe di loop';
	@override String get tvWrapDescription => 'Direttamente sulla ultima carta va di nuovo alla prima. Off si ferma alla ultima carta. La sinistra sulla prima carta va sempre alla barra laterale.';
	@override String get castOnHero => 'Il cast su banner';
	@override String get castOnHeroDescription => 'Mostra il cast lungo il fondo di un banner eroico. fuori conserva solo il titolo e il sintesi.';
	@override String get customRows => 'Riflessioni personalizzate';
	@override String get loading => 'Il layout di casa...';
	@override String get noCustomRows => 'Non ci sono ancora linee';
	@override String get addRowHint => 'Utilizzare Add Home row per creare uno.';
	@override String get addHomeRow => 'Aggiungi Home Rue';
	@override String get addHomeRowDescription => 'Selezionare una categoria; la nuova linea viene aggiunta automaticamente all\'Organizzatore';
	@override String get removeRow => 'Rimuovere la linea';
	@override String get recentlyAdded => 'Aggiunti di recente';
	@override String get recentlyReleased => 'Rilasciato di recente';
	@override String get movieCollections => 'Film Collezioni';
	@override String get showCollections => 'Mostra le collezioni';
	@override String get rowTitle => 'Titolo Row';
	@override String get content => 'contenuto';
	@override String get showThisRowIn => 'Mostra questa riga in:';
	@override String get libraryRecommended => 'Biblioteca raccomandata';
	@override String get heroCard => 'Carta di eroe';
	@override String get heroCardDescription => 'Mostra come una carta di rotazione a larghezza completa invece di un poster shelf.';
	@override String get heroUnavailableDescription => 'Disponibile solo quando questa fila si risolve ai titoli reali di una singola collezione - con più di una collezione selezionata non c\'è nessun titolo da girare.';
	@override String get librariesSelection => 'Librerie (solo non controllate per includere ogni biblioteca)';
	@override String get librariesMergedDescription => 'Ogni biblioteca che si verifica qui è unita in questa una fila.';
	@override String get movieCollectionsSelection => 'Collezioni di film (solo non controllate per ogni biblioteca selezionata)';
	@override String get showCollectionsSelection => 'Mostra collezioni (solo non controllate per ogni biblioteca selezionata)';
	@override String get collectionRowsDescription => 'Se esattamente una collezione si compie, i suoi titoli si mostrano direttamente nella fila.Se più di una collezione, ogni collezione si mostra come un unico poster - premere per aprire quella collezione.';
	@override String get allCollections => 'Tutte le collezioni';
	@override String get noRowsHere => 'Non ci sono ancora linee.';
	@override String get hideWatchedRows => 'Scopri gli oggetti osservati in serie';
	@override String get hideWatchedRowsDescription => 'Titoli completamente guardati lasciare Home e biblioteca Raggiunta raccomandata.';
	@override String get untitledCollection => 'Collezione senza titolo';
	@override String get moveRowHint => 'Up/Down: spostare la linea · Selezionare: lasciarlo qui · Ritorno: cancellare';
	@override String get organizeRowsHint => 'Selezionare una riga (o tenere Selezionare): spostarlo · Sinistra/Destra: opzioni di riga · Ritorno: fatto';
	@override String get layoutNavDescription => 'Scegliere le righe, le biblioteche e le categorie di raccolta';
	@override String get editHomeRow => 'Edit Home Ronde';
	@override String get resetHeroButton => 'Ristrutturare il layout del eroe in stock Plezy';
	@override String get reorderingUnlocked => 'Ristrutturazione disattivata';
	@override String get reorderingLocked => 'Ristrutturazione chiusa';
	@override String get rowsCanBeDragged => 'Le corde possono essere tracciate - tappa il blocco per evitare che';
	@override String get tapLockToDrag => 'Toccare il blocco per tirare le righe';
	@override String customRowLabel({required Object title}) => 'Numero di lavoro: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Nascondi';
	@override String get remove => 'Rimuovi';
	@override String get libraryResumeRow => 'La rivista della biblioteca è';
	@override String get pressAgainToDelete => 'Premere di nuovo per cancellare';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'di';
	@override String get resetHeroButtonDescription => 'Ritorna il set di eroe di ogni riga e riporta il singolo banner rotante in cima, come prima che le riga eroe esistessero.';
	@override String get tapHeroCardDescription => 'Selezionare se tappando o selezionando una carta Hero inizia la riproduzione o si aprono i suoi dettagli.';
	@override String get heroTapPlayDescription => 'Inizia subito l’oggetto selezionato.';
	@override String get heroTapDetailsDescription => 'Apri i dettagli dell\'oggetto selezionato prima di scegliere un\'azione.';
}

// Path: platform
class _Translations$platform$it extends Translations$platform$en {
	_Translations$platform$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG connette ai tuoi server multimediali e dispositivi di riproduzione sulla tua rete locale.';
	@override String get locationPermission => 'PlezyNG utilizza l\'accesso alla localizzazione quando iOS lo richiede per rilevare la tua rete locale e connetterti ai tuoi server multimediali.';
	@override String get photoLibraryPermission => 'Scegli immagini dalla tua libreria fotografica da usare come copertine e illustrazioni dei contenuti multimediali.';
	@override String get cameraPermission => 'Scansione QR per unirsi a un Companion Remote.';
}

// Path: universalMedia
class _Translations$universalMedia$it extends Translations$universalMedia$en {
	_Translations$universalMedia$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Media aperte';
	@override String get shortcutHelp => 'Gioca un link, playlist o file per questa sessione.';
	@override String get intro => 'Apri un link, playlist o file. Playback utilizza il lettore standard di PlezyNG e non aggiunge storia alla tua biblioteca.';
	@override String get openWhat => 'Cosa vorresti aprire?';
	@override String get stream => 'Indirizzo Stream';
	@override String get playlist => 'giocattoli';
	@override String get files => 'Dispositivi di file';
	@override String get favorites => 'Salva i tuoi preferiti';
	@override String get address => 'Indirizzo Media';
	@override String get addressHelp => 'Gli URL con parametri di credenziale o di firma riconosciuti sono utilizzati solo per questa sessione e non possono essere salvati come preferiti.';
	@override String get displayName => 'Nome di visualizzazione (opzionale)';
	@override String get displayNameHelp => 'Scegli un nome corto per il giocatore e i controlli dei media del sistema.';
	@override String get allowHttp => 'Permettere una connessione HTTP non crittografata';
	@override String get allowHttpHelp => 'HTTP non crittografa la connessione. permetterla solo su una rete affidata. utilizzare HTTPS quando possibile.';
	@override String get advancedProtocols => 'MPV solo: inserisci un indirizzo RTSP, RTMP/RTMPS, UDP o RTP. Questi indirizzi non possono essere salvati come preferiti.';
	@override String get liveStream => 'trattare come vivo';
	@override String get liveStreamHelp => 'Utilizzare questo per video o radio dal vivo.L\'app nasconde la barra del tempo, i pulsanti di scoppio e l\'opzione go-to-time.';
	@override String get privateSession => 'Solo questa riproduzione utilizza l\'indirizzo. Salva un streaming idoneo preferito per tenerlo in questo profilo.';
	@override String get saveFavorite => 'Salva i tuoi preferiti';
	@override String get playNow => 'Gioca ora';
	@override String get favoriteSaved => 'Stream preferito salvato a questo profilo';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: 'Scappato ${count} ingresso di playlist non supportato o insicuro.',
		many: 'Scappato ${count} ingressi di playlist non supportati o insicuri.',
		other: 'Scappato ${count} ingressi di playlist non supportati o insicuri.',
	);
	@override String get playlistAddress => 'Indirizzo Playlist';
	@override String get playlistAddressHelp => 'Apri una playlist M3U, M3u8, o PLS da un indirizzo web. link di streaming diretto non salvi la playlist.';
	@override String get choosePlaylist => 'Scegli il file di playlist';
	@override String get openPlaylist => 'L\'apertura del playlist';
	@override String get playlistFormatsHelp => 'Una playlist può contenere fino a 1.000 articoli e 2 MB. HLS si manifesta aperto come flussi in modo che il giocatore possa scegliere una qualità.';
	@override String get saveQueuePlaylist => 'Salva la coda come playlist';
	@override String get queuePlaylistSaved => 'La playlist è stata salvata accanto ai file multimediali.';
	@override String get queuePlaylistUnavailable => 'Questa coda non può essere salvata come playlist locale riutilizzabile.';
	@override String get queuePlaylistFolderRequired => 'Scegli una posizione nella stessa cartella dei file in coda.';
	@override String get noFavorites => 'Non è stato ancora salvato il flusso dei preferiti. i preferiti rimangono in questo profilo.';
	@override String get removeFavorite => 'Rimuovere streaming preferito';
	@override String get filesHelp => 'Selezionare file audio, video o ISO per una coppia temporanea. File e URL non vengono aggiunti alla storia della biblioteca.';
	@override String get chooseFiles => 'Scegli i file';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '1 file selezionati',
		many: '${count} file selezionati',
		other: '${count} file selezionati',
	);
	@override String get wifiTransfer => 'Invia file tramite Wi-Fi';
	@override String get wifiTransferHelp => 'Trasferire i file supportati da un browser sulla stessa rete affidata.';
	@override String get wifiTransferIntro => 'Apri questo indirizzo in un browser su un altro dispositivo. Scegli i file per aggiungerli alla libreria dei file e dei libri di questo dispositivo.';
	@override String get wifiTransferPrivacy => 'Questo dispositivo riceve file attraverso la tua rete locale. chiunque conosce questo indirizzo può inviare file fino a quando non si ferma il trasferimento o l\'indirizzo scade dopo 15 minuti. massimo: 100 file, 4 GiB per file, 10 GiB totale.';
	@override String get wifiTransferStarting => 'La preparazione di un trasferimento privato, a tempo limitato ...';
	@override String get wifiTransferUnavailable => 'Non è possibile avviare il trasferimento. verificare l\'accesso alla rete locale e provare di nuovo.';
	@override String get openThisAddress => 'Apri uno di questi indirizzi sul dispositivo di spedizione';
	@override String get copyAddress => 'Indirizzo di trasferimento';
	@override String get addressCopied => 'Indirizzo di trasferimento copiato';
	@override String transferExpires({required Object time}) => 'Questo indirizzo scade in ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: 'Il file ${count} ricevuto',
		many: 'I file ${count} ricevuti',
		other: 'I file ${count} ricevuti',
	);
	@override String uploadedData({required Object size}) => 'Ricevuto ${size}';
	@override String get stopTransfer => 'Smettere di trasferire e invalidare l\'indirizzo';
	@override String get startTransfer => 'Inizia il trasferimento';
	@override String get wifiImportedFiles => 'Trasferimento Wi-Fi';
	@override String get wifiBrowserTitle => 'Invia file a PlezyNG';
	@override String get wifiBrowserIntro => 'Selezionare file audio, video, ebook o comic per inviare. i file vengono salvati nella libreria dei file e dei libri di questo dispositivo. massimo: 100 file, 4 GiB per file, 10 GiB totale.';
	@override String get uploadFilesLabel => 'I file da inviare';
	@override String get uploadSelected => 'Scarica i file selezionati';
	@override String get uploadSelectFirst => 'Selezionare uno o più file prima.';
	@override String get uploading => 'Inviare';
	@override String get uploadComplete => 'Il file è stato aggiunto a PlezyNG.';
	@override String get uploadFailed => 'Il file non può essere aggiunto. tenere aperta questa pagina e provare di nuovo.';
	@override String get liveCue => 'Il vivo';
	@override String get liveSession => 'Il Live Stream';
	@override String get liveCueHelp => 'Per video o radio dal vivo, l\'app nasconde la barra del tempo e scapa i pulsanti. non salva l\'indirizzo o la storia di visualizzazione.';
	@override String get sessionOnly => 'Questo playback è solo sessione';
	@override String get sessionOnlyHelp => 'Playback non salva mai progresso o storia.Salva il flusso come preferito per tenerlo in questo profilo se è idoneo.';
	@override String get pictureAdjustments => 'Immagini adattamenti';
	@override String get pictureHelp => 'Questi cambiamenti di immagine influenzano solo questa riproduzione. si riavviano quando la ripresa finisce.';
	@override String get resetPicture => 'Ristrutturazione immagine';
	@override String get brightness => 'Il brillo';
	@override String get contrast => 'Contrasto';
	@override String get gamma => 'Il Gamma';
	@override String get hue => 'di Hue';
	@override String get saturation => 'Saturazione';
	@override String get view360 => 'Visualizzazione a 360° video';
	@override String get view360Help => 'Utilizzare questo per il video 360° equidirezionale. MPV ha bisogno del filtro v360 di FFmpeg per questa visualizzazione.';
	@override String get view360Unavailable => 'Questa configurazione MPV non potrebbe applicare il filtro a 360°.';
	@override String get view360Yaw => 'Visione orizzontale';
	@override String get view360Pitch => 'Vista verticale';
	@override String get view360FieldOfView => 'campo di visione';
	@override String get recordStream => 'Recensione di Live Stream';
	@override String get stopRecording => 'Smettere e salvare la registrazione';
	@override String get recordingStarted => 'La registrazione è attiva. Lasciare il riproduzione si ferma e salva la registrazione.';
	@override String get recordingSaved => 'La registrazione è finita e salvata.';
	@override String get recordingActive => 'Lasciare il riproduzione si ferma e lo salva.';
	@override String get recordingFormatHelp => 'Per video, scegliere MKV o MPEG-TS. per audio, scegliere MKA o MKV.';
	@override String get replaceRecordingTitle => 'Sostituisci questa registrazione?';
	@override String get replaceRecordingHelp => 'PlezyNG ripara il file esistente durante la registrazione. se non riesce a salvare la nuova registrazione, Plezy NG ripristina il backup.';
	@override String get replaceRecording => 'sostituire il file';
	@override String get discHelp => 'Apri un disco in questa scheda ottica del computer. Puoi anche aprire un\'immagine ISO dai file Device.';
	@override String get discs => 'Il disco ottico';
	@override String get editionOrTitle => 'Edizione o titolo del disco';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Il Blu-ray';
	@override String get audioCd => 'CD audio';
	@override String get discAvailability => 'La riproduzione dei dischi richiede un compost MPV compatibile, una scheda supportata e un permesso del sistema operativo. non può superare la protezione del disco commerciale.';
	@override String get converterTitle => 'Convertire un file di media locale';
	@override String get converterHelp => 'Convertire un file locale o rimuoverlo con FFmpege il';
	@override String get converterIntro => 'Convertire un file audio o video locale in un formato che funziona su più dispositivi.';
	@override String get converterPrivacy => 'FFmpeg deve essere installato su questo computer. Conversione legge solo i file locali. Non scarica i flussi o rimuove DRM.';
	@override String get converterChooseInput => 'Scegli un file di media locale';
	@override String get converterFormat => 'Formato di uscita';
	@override String get converterMp4 => 'MP4 · H.264 e AAC';
	@override String get converterM4a => 'M4A · AAC audio';
	@override String get converterMp3 => 'MP3 e audio';
	@override String get allowFtp => 'Permesso FTP';
	@override String get allowFtpHelp => 'FTP trasmette i media senza crittografia. utilizza solo su reti affidate.';
	@override String get converterSaveAs => 'Conservare i media convertiti come';
	@override String get converterExtensionMismatch => 'Scegli un nome di file con l\'estensione di uscita selezionata.';
	@override String get converterUnsupportedInput => 'Scegli un file audio o video.';
	@override String get converterLocalOnly => 'Il file selezionato non è disponibile come percorso di dispositivo locale.';
	@override String get converterReplaceTitle => 'Sostituisci questo file?';
	@override String get converterReplaceHelp => 'PlezyNG rimborserà il file esistente fino a quando la copia convertita non sarà salvata.';
	@override String get converterStarting => 'A partire da FFmpeg...';
	@override String get converterProgress => 'Conversione su questo computer...';
	@override String get converterComplete => 'Conversione completa: il nuovo file è pronto.';
	@override String get converterFfmpegMissing => 'FFmpeg è mancato o non supporta questo formato.';
	@override String get converterFailed => 'Verificare che il file sorgente può essere letto e la destinazione ha abbastanza spazio gratuito.';
	@override String get converterCancelled => 'La conversione è stata cancellata. il risultato incompleto è stato rimosso.';
	@override String get converterDesktopOnly => 'La conversione locale è disponibile su computer desktop con FFmpeg installato.';
	@override String get converterStart => 'Convertire file';
	@override String get mediaToolsTitle => 'Strumenti di Media';
	@override String get mediaToolsShortcut => 'Raccogliere o condividere i media, aggiungere estensioni di ricerca o utilizzare la linea di comando.';
	@override String get mediaToolsIntro => 'Scegli un strumento focalizzato. cattura e usare il flusso di FFmpeg installato su questo desktop. estensioni e comandi CLI utilizzano richieste HTTPS limitate e il flusso Open media esistente.';
	@override String get mediaToolsAccessibility => 'Le scelte degli strumenti e i controlli funzionano con touch, indicatore, tastiera e focalizzazione D-pad. I cambiamenti dello stato di registrazione, condivisione e ricerca sono annunciati.';
	@override String get mediaTool => 'Strumento Media';
	@override String get captureIntro => 'Inserisci lo schermo o la fotocamera in un file MP4 su questo computer. FFmpeg deve essere installato e include il codice H.264.';
	@override String get captureNoDevices => 'Nessun schermo o fotocamera è stato trovato. verificare FFmpeg supporto per la cattura e le autorizzazioni per la privacy del sistema operativo.';
	@override String get captureSource => 'schermo o fotocamera';
	@override String get captureScreen => 'schermo';
	@override String get captureAudioSource => 'Introduzione audio (opzionale)';
	@override String get captureAudioHelp => 'Aggiungi audio da un microfono o input disponibili. le scelte del dispositivo dipendono da FFmpeg e le autorizzazioni del sistema.';
	@override String get captureAudioNone => 'Nessun audio';
	@override String get captureDefaultAudio => 'Introduzione audio';
	@override String get captureWaylandHelp => 'Wayland limita questa cattura XWayland al X display. Windows al di fuori di XWayland non può apparire.';
	@override String get captureFrameRate => 'Tasso di registrazione frame rate';
	@override String get capturePrivacy => 'La registrazione viene salvata solo al file che scegli. la registrazione del microfono è facoltativa. PlezyNG non carica la registrazione.';
	@override String get captureSaveAs => 'Salva la registrazione dello schermo come';
	@override String get captureExtensionMismatch => 'Scegli un nome di file che finisce in .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg o il codificatore video H.264 non è disponibile. Installare una costruzione FFmpeg supportata, poi provare di nuovo.';
	@override String get captureFailed => 'Controlla il permesso del dispositivo, il storage disponibile e il supporto FFmpeg.';
	@override String get captureSaved => 'Screen record salvato.';
	@override String get captureElapsedLabel => 'Tempo di registrazione';
	@override String get captureStart => 'Inizia la registrazione';
	@override String get capturePreview => 'Anteprima nel lettore';
	@override String get capturePreviewHelp => 'Visualizza un’anteprima della sorgente selezionata nel lettore standard. È limitata a questa sessione e non salva una registrazione. Il supporto dei dispositivi e le autorizzazioni dipendono da MPV e dal sistema operativo. L’anteprima usa solo il video; le registrazioni salvate possono includere audio facoltativo.';
	@override String get capturePreviewActive => 'Anteprima in diretta · nessuna registrazione';
	@override String get captureStop => 'Stop e salvare';
	@override String get captureMode => 'cattura';
	@override String get shareMode => 'Condividi';
	@override String get shareIntro => 'Invia un file di media locale ad un altro dispositivo sulla tua rete privata. PlezyNG crea un flusso temporaneo HLS.';
	@override String get sharePrivacy => 'Chiunque nella tua rete locale che riceve il link privato può guardare mentre è attivo. il link scade dopo 60 minuti. smettere di condividere per chiudere il server e annullare il link.';
	@override String get shareChooseFile => 'Selezionare file di media';
	@override String get shareChooseHelp => 'Selezionare un file audio o video locale. il file rimane su questo computer.';
	@override String get shareFfmpegMissing => 'FFmpeg o i codificatori H.264/AAC non sono disponibili. Installare FFmpeg con H.264 e AAC codifica supporto.';
	@override String get shareFailed => 'Il flusso non poteva iniziare o fermarsi inaspettatamente. controllare FFmpeg e l\'accesso alla rete.';
	@override String get shareActive => 'Il flusso è pronto sulla tua rete privata.';
	@override String get shareEnded => 'I media hanno raggiunto la fine e non vengono più condivisi.';
	@override String get shareStopped => 'La condivisione è sospesa. il link temporaneo non è più valido.';
	@override String get shareUrlCopied => 'L’indirizzo di posta elettronica è copiato.';
	@override String get shareOpenUrl => 'Aprire questo indirizzo in un giocatore sull\'altro dispositivo';
	@override String get shareQrLabel => 'Il codice QR per l’indirizzo temporaneo';
	@override String get shareQrHelp => 'Scansione con un giocatore compatibile connesso alla stessa rete privata.';
	@override String get shareHttpHint => 'Questo flusso utilizza HTTP non crittografato. in PlezyNG, permettere HTTP prima di aprire.';
	@override String get shareCopyUrl => 'Indirizzo Stream';
	@override String get shareExpiresLabel => 'Il link scade a';
	@override String get shareStarting => 'Preparando il flusso...';
	@override String get shareStart => 'Inizia la condivisione';
	@override String get shareStop => 'smettere di condividere';
	@override String get extensionsMode => 'L\'estensione e CLI';
	@override String get extensionsIntro => 'Aggiungi un\'estensione di ricerca dati solo per trovare i media. Scegli un risultato per caricarlo nel familiare modulo Open media.';
	@override String get extensionsPrivacy => 'Un manifesto può definire uno HTTPS campo di ricerca e mappa risposta. non può eseguire il codice, aggiungere titoli di richiesta, leggere i file, o lanciare comandi shell.';
	@override String get extensionImport => 'Aggiungi manifesto di estensione';
	@override String get extensionEmpty => 'Non ci sono ancora servizi di ricerca. Scegli un file manifesto JSON affidabile per aggiungere uno.';
	@override String get extensionChoose => 'Servizio di ricerca';
	@override String get extensionSearchConsent => 'Ogni ricerca invia le tue parole a questo servizio HTTPS. i risultati si aprono solo dopo aver selezionato uno.';
	@override String get extensionSearchLabel => 'Media di ricerca';
	@override String get extensionSearch => 'La ricerca';
	@override String get extensionSearching => 'La ricerca...';
	@override String get extensionNoResults => 'Non sono stati riportati risultati di media sicuri. prova un\'altra ricerca.';
	@override String get extensionInstallTitle => 'Aggiungi questo servizio di ricerca?';
	@override String get extensionReplaceTitle => 'Aggiornare questo servizio di ricerca?';
	@override String get extensionService => 'Servizio';
	@override String get extensionEndpoint => 'HTTPS punto finale';
	@override String get extensionConsent => 'Il testo di ricerca viene inviato a questo servizio. il manifesto non contiene codice eseguibile. Continua solo se ti confidi questo punto finale.';
	@override String get extensionInstall => 'Aggiungi servizio';
	@override String get extensionReplace => 'Aggiornamento servizio';
	@override String get extensionRemoveTitle => 'Rimuovere questo servizio di ricerca?';
	@override String get extensionRemoveHelp => 'Questo rimuove il servizio da questo profilo. PlezyNG non contatta il suo punto finale.';
	@override String get extensionRemove => 'Rimuovere il servizio';
	@override String get extensionInvalidManifest => 'Questo file non è un manifesto di estensione supportato. vedi la guida Open media per il formato.';
	@override String get extensionSaveFailed => 'L\'estensione non poteva essere salvata al profilo attivo.';
	@override String get extensionSearchFailed => 'Il servizio di ricerca non ha restituito una risposta valida. verificare il punto di fine e provare di nuovo.';
	@override String get cliTitle => 'linea di comando';
	@override String get cliHelp => 'Utilizzare la guida plezyctl per valutare un manifesto o cercare la stessa estensione. rivedere il suo servizio HTTPS prima di ogni ricerca. Risultati aperti nel modulo media esistente; selezionare il pulsante ripresa per iniziare.';
	@override String get cliCopyExample => 'Copia il comando esempio';
	@override String get cliCopied => 'Esempio di comando copiato.';
}

// Path: fileSources
class _Translations$fileSources$it extends Translations$fileSources$en {
	_Translations$fileSources$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fili e libri';
	@override String get subtitle => 'Leggi, ascolta e guarda dai tuoi file.';
	@override String get add => 'Aggiungi fonte';
	@override String get importFiles => 'Importazione file';
	@override String get localFiles => 'su questo dispositivo';
	@override String get source => 'Fonte';
	@override String get name => 'Nome';
	@override String get endpoint => 'URL del server';
	@override String get smbEndpointHint => 'Esempio: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Inserisci un server SMB e una cartella condivisa.';
	@override String get root => 'Foldere o prefix';
	@override String get smbFolderHelp => 'Lascia vuoto per usare l’intera cartella condivisa, oppure inserisci una cartella al suo interno.';
	@override String get username => 'Nome utente';
	@override String get smbDomain => 'Dominio (facoltativo)';
	@override String get password => 'Password';
	@override String get token => 'API Toccano';
	@override String get accessKey => 'ID chiave di accesso';
	@override String get secretKey => 'Key di accesso segreto';
	@override String get sessionToken => 'Il token sessione (opzionale)';
	@override String get region => 'Regione';
	@override String get clientId => 'ID client di OAuth';
	@override String get clientSecret => 'OAuth client secret (solo Google desktop)';
	@override String get allowHttp => 'Consenti HTTP non crittografato su una rete attendibile';
	@override String get smbEncryption => 'Crittografa la connessione SMB3';
	@override String get smbEncryptionHint => 'Usa la crittografia SMB3 quando il NAS la supporta.';
	@override String get connect => 'Connetti';
	@override String get cancel => 'Annulla';
	@override String get save => 'Salva';
	@override String get close => 'Chiudi';
	@override String get removeSource => 'Sconnetti fonte';
	@override String get disconnectMessage => 'Disconnettere questa fonte? I file scaricati e la cronologia di lettura e ascolto resteranno su questo dispositivo.';
	@override String get localFolder => 'Scegliamo la cartella';
	@override String get empty => 'Ancora niente qui';
	@override String get emptyHint => 'Aggiungi una fonte o importare un libro, un libro audio, musica o video.';
	@override String get search => 'Cerca questo folder';
	@override String get searchCached => 'La ricerca della biblioteca salvata';
	@override String get refresh => 'Aggiorna';
	@override String get loadMore => 'Carica di più';
	@override String get offline => 'Disponibile offline';
	@override String get download => 'Rimanere offline';
	@override String get removeDownload => 'Rimuovere offline copia';
	@override String get continueReading => 'Continua a leggere';
	@override String get continueListening => 'Continua ad ascoltare';
	@override String get continueWatching => 'Continua a guardare';
	@override String get read => 'Leggi';
	@override String get listen => 'Ascolta';
	@override String get play => 'Riproduci';
	@override String get pause => 'Pausa';
	@override String get stop => 'Interrompi';
	@override String get startOver => 'Inizia il';
	@override String get finished => 'Terminato';
	@override String get markFinished => 'Marco finito';
	@override String get markUnfinished => 'Marchio Infinito';
	@override String get editions => 'Edizioni e file';
	@override String get chapters => 'Capitoli';
	@override String get bookmarks => 'Note e note';
	@override String get bookmark => 'Aggiungi Bookmark';
	@override String get highlight => 'L’accento';
	@override String get note => 'Nota';
	@override String get delete => 'Elimina';
	@override String get export => 'Notizie di esportazione';
	@override String get exported => 'Notizie esportate';
	@override String get sync => 'Sincolo Progresso';
	@override String get synced => 'Progresso sintetizzato';
	@override String get conflict => 'Un altro dispositivo ha una posizione diversa. scegliere dove continuare.';
	@override String get useLocal => 'Utilizzare questo dispositivo';
	@override String get useRemote => 'Utilizzare altri dispositivi';
	@override String get history => 'Storia della posizione';
	@override String get groupAudio => 'Ascoltare come un libro audio';
	@override String get groupHint => 'Combina i file audio attualmente caricati in questa cartella. caricare tutte le pagine prima.';
	@override String get order => 'Ordine di file';
	@override String get moveUp => 'Move in alto';
	@override String get moveDown => 'Move verso il basso';
	@override String get speed => 'velocità di playback';
	@override String get sleep => 'Timer di spegnimento';
	@override String get sleepOff => 'Disattivato';
	@override String get endChapter => 'La fine del capitolo';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuti',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuti',
	);
	@override String get skipBack => 'Scoppia indietro';
	@override String get skipForward => 'Scomparsa in avanti';
	@override String get smartRewind => 'Il ritorno intelligente dopo una pausa';
	@override String get playbackOptions => 'Opzioni di ascolto';
	@override String remaining({required Object time}) => '${time} rimanente';
	@override String get contents => 'contenuto';
	@override String get readerSettings => 'Leggi le impostazioni';
	@override String get fontSize => 'Testo di dimensioni';
	@override String get lineHeight => 'Linee di spazzatura';
	@override String get margin => 'Margini';
	@override String get font => 'Tipo di faccia';
	@override String get serif => 'serif';
	@override String get sans => 'Senza serif';
	@override String get mono => 'Monospacio';
	@override String get columns => 'Colonne';
	@override String get scroll => 'Scorrere verticalmente';
	@override String get justify => 'giustificare il testo';
	@override String get readerTheme => 'Apparire pagina';
	@override String get appTheme => 'Seguire app tema';
	@override String get paper => 'Carta';
	@override String get sepia => 'Setti';
	@override String get night => 'Notte';
	@override String get readAloud => 'Leggi questa pagina ad alta voce';
	@override String get readAlong => 'Leggi tutto';
	@override String get stopReading => 'smettere di narrazione';
	@override String get searchBook => 'La ricerca nel libro';
	@override String get noMatches => 'Nessun match';
	@override String get previousPage => 'Pagina precedente';
	@override String get nextPage => 'Pagina successiva';
	@override String page({required Object number}) => 'Pagina ${number}';
	@override String get externalBlocked => 'I link esterni del libro sono disabilitati nel lettore.';
	@override String get loading => 'Apertura...';
	@override String get narrator => 'narratore';
	@override String get audio => 'Audio';
	@override String get video => 'Video';
	@override String get ebooks => 'ebook';
	@override String get all => 'Tutto';
	@override String get downloads => 'Fili di Offline';
	@override String get confirmDelete => 'Rimuovere la copia offline selezionata? la tua posizione e le note rimarranno.';
	@override String get errorAuthentication => 'Iscriviti di nuovo per riconnettere questa fonte.';
	@override String get errorPermission => 'Questa fonte non ha fornito accesso al file richiesto.';
	@override String get errorUnavailable => 'La fonte non è disponibile. prova di nuovo, o apri una copia offline.';
	@override String get errorUnsupported => 'Questo formato o connessione non è supportato su questo dispositivo.Vedi la guida di impostazione della fonte.';
	@override String get errorInvalidData => 'Questo file o risposta del server non può essere letto in modo sicuro.';
	@override String get errorCancelled => 'L’operazione è stata annullata.';
	@override String get errorConflict => 'La posizione è cambiata in un\'altra sessione. riaprirlo per selezionare una posizione.';
	@override String get signIn => 'Accedi';
	@override String get reconnect => 'Riconnetti';
	@override String get folderHelp => 'Lascia la riga per iniziare alla radice sorgente. URL S3 includono il bucket.';
	@override String get preferences => 'Preferenze';
	@override String get timePosition => 'Posizione';
	@override String get audioTrack => 'Audio trazione';
	@override String get subtitleTrack => 'Il sottotitolo traggio';
	@override String get none => 'Nessuno';
	@override String get fullscreen => 'schermo completo';
	@override String get syncLocation => 'Fornitura di Progress Sync (opzionale)';
	@override String get syncLocationHint => 'Una cartella dedicata WebDAV per PlezyNG stato. utilizza scrittura condizionale; i media rimangono invariati.';
	@override String get audiobooks => 'Audiolibri';
	@override String get comics => 'Fumetti';
	@override String get scan => 'Scansione dei libri e dei media';
	@override String get browserReader => 'Il lettore aperto';
	@override String get browserReaderHelp => 'Il lettore è aperto nel tuo browser. Mantenere aperto PlezyNG per salvare il tuo posto e note.';
	@override String get on => 'di';
	@override String get advancedSetup => 'App di registrazione';
	@override String get microsoftSignIn => 'Iscriviti con Microsoft';
	@override String get zoomIn => 'Ingrandisci';
	@override String get zoomOut => 'Zoom fuori';
	@override String get fitPage => 'Pagina adeguata';
	@override String get fitWidth => 'adeguato larghezza';
	@override String get actualSize => 'Dimensioni attuali';
	@override String get goToPage => 'Vai alla pagina';
	@override String get goToSection => 'Vai al capitolo';
	@override String pageRange({required Object count}) => 'Inserisci un numero da 1 a ${count}';
	@override String get pageLayout => 'Il layout della pagina';
	@override String get automatic => 'Automatico';
	@override String get singlePage => 'Una pagina unica';
	@override String get twoPages => 'Due pagine';
	@override String get readingDirection => 'La direzione di lettura';
	@override String get leftToRight => 'A sinistra a destra';
	@override String get rightToLeft => 'Da destra a sinistra';
	@override String get letterSpacing => 'Lettera spazzatura';
	@override String get wordSpacing => 'Parola spazzatura';
	@override String get readerControlsHelp => 'Allontana due dita o usa i controlli dello zoom per ingrandire le pagine. Trascina per spostare la pagina. Ctrl/⌘ con + o − regola lo zoom; Ctrl/⌘ con 0 lo reimposta. Page Up e Page Down cambiano pagina.';
	@override String get imagePage => 'Pagina di fumetto';
	@override String get resetReader => 'Ristrutturare le preferenze di lettura';
	@override String get zoom => 'Zoom';
	@override String get useFiles => 'Utilizzare file e libri';
	@override String get cancelScan => 'Cancelare la scansione';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Limiti di download offline';
	@override String get offlineQuotaHelp => 'Configurare lo spazio massimo utilizzato da copie offline, file importati e download corrotti. La riduzione del limite non rimuove le copie esistenti.';
	@override String get offlineStorageUsage => 'Storaggio Offline';
	@override String get reservedStorage => 'riservato';
	@override String get downloadQueue => 'Scarica il Queue';
	@override String get downloadRunning => 'Scarica';
	@override String get downloadQueued => 'Aspettando';
	@override String get downloadPaused => 'Pausa';
	@override String get downloadFailed => 'La necessità di ritorno';
	@override String get importing => 'Importazione';
	@override String get importInterrupted => 'Importazione interrotta · rimuovere a chiarire';
	@override String get errorQuotaExceeded => 'Il limite di archiviazione offline è stato raggiunto. Aumentare il limite o rimuovere una copia scaricata.';
	@override String get errorStorageLow => 'Non c\'è sufficiente archiviazione gratuita per mantenere la riserva protetta.';
	@override String get errorStorageUnavailable => 'PlezyNG non poteva controllare lo storage del dispositivo gratuito, quindi la scrittura è stata interrotta.';
	@override String get removeDownloadJob => 'Rimuovere download';
	@override String get downloadAlreadyComplete => 'Questo download è finito prima che possa essere rimosso. l\'articolo è ora disponibile offline.';
	@override String get confirmRemoveDownloadJob => 'Rimuovere questo download e rimuovere tutti i dati parzialmente scaricati? la tua posizione e le note rimarranno.';
}

// Path: lending
class _Translations$lending$it extends Translations$lending$en {
	_Translations$lending$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteche pubbliche';
	@override String get add => 'Aggiungi una biblioteca';
	@override String get other => 'Un’altra biblioteca';
	@override String get libraryName => 'Nome della biblioteca';
	@override String get libraryUrl => 'Sito della biblioteca';
	@override String get libraryUrlHint => 'Usa il catalogo della tua biblioteca o la pagina di accesso.';
	@override String get intro => 'Prendi in prestito dalla tua biblioteca. Tieni i tuoi libri a portata di mano.';
	@override String get handoff => 'Accedi, prendi in prestito e leggi in sicurezza con il servizio della tua biblioteca.';
	@override String get openService => 'Apri biblioteca';
	@override String get findLibrary => 'Trova una biblioteca';
	@override String get search => 'Cerca libri e autori';
	@override String get catalogue => 'Catalogo';
	@override String get loans => 'Prestiti';
	@override String get holds => 'Prenotazioni';
	@override String get signIn => 'Accedi tramite la tua biblioteca';
	@override String get waiting => 'Completa l’accesso nel browser, poi torna qui.';
	@override String get cancel => 'Annulla';
	@override String get disconnect => 'Rimuovi biblioteca';
	@override String get disconnectMessage => 'Rimuovere questa biblioteca da questo profilo? I prestiti e le prenotazioni resteranno registrati presso la biblioteca.';
	@override String get getBook => 'Ottieni il libro';
	@override String get checkAvailability => 'Verifica disponibilità';
	@override String get available => 'Disponibile per il prestito';
	@override String get unavailable => 'Al momento non disponibile';
	@override String get borrow => 'Prendi in prestito';
	@override String get placeHold => 'Prenota';
	@override String get returnBook => 'Restituisci in anticipo';
	@override String get cancelHold => 'Annulla prenotazione';
	@override String get confirmBorrow => 'Prendere in prestito questo titolo dalla tua biblioteca?';
	@override String get confirmReturn => 'Restituire questo titolo adesso? Potresti doverlo prendere di nuovo in prestito per continuare.';
	@override String get confirmCancelHold => 'Annullare la prenotazione di questo titolo?';
	@override String get email => 'Email per le notifiche sulle prenotazioni';
	@override String due({required Object date}) => 'Scadenza: ${date}';
	@override String queue({required Object position}) => 'Posizione in coda: ${position}';
	@override String get empty => 'Non ci sono ancora titoli.';
	@override String get openLibraryNote => 'Esplora il catalogo di Open Library. Le opzioni di lettura e prestito sono indicate nella pagina di ciascun titolo.';
	@override String get more => 'Carica di più';
	@override String get gateway => 'Servizio di accesso alla biblioteca';
	@override String get gatewayHint => 'Fornito dalla tua biblioteca o dall’amministratore di PlezyNG.';
	@override String get advanced => 'Integrazione della biblioteca';
	@override String get loadLibraries => 'Scegli la tua biblioteca';
	@override String get expired => 'Il prestito è scaduto.';
	@override String get updated => 'Biblioteca aggiornata';
	@override String get continueService => 'Continua nel servizio';
	@override String get comingSoon => 'Prestiti nell’app · In arrivo';
	@override String get comingSoonDescription => 'L’integrazione con Libby è in arrivo. Puoi usare la tua biblioteca in Libby mentre completiamo il collegamento.';
	@override String get suspendHold => 'Sospendi prenotazione';
	@override String get resumeHold => 'Riprendi prenotazione';
	@override String get suspendMessage => 'Mantenere il tuo posto in coda e lasciare che il prossimo lettore prenda in prestito questa copia? Puoi riprendere la prenotazione in seguito.';
	@override String get resumeMessage => 'Riprendere questa prenotazione per consentire alla biblioteca di offrirti la prossima copia disponibile?';
	@override String get editEmail => 'Modifica l’email per le notifiche';
}

// Path: audiobook
class _Translations$audiobook$it extends Translations$audiobook$en {
	_Translations$audiobook$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Sincronizzazione di lettura e ascolto';
	@override String get syncHelp => 'Sincronizza tra i tuoi dispositivi le posizioni di lettura e ascolto, lo stato di completamento, i segnalibri e le note. Scegli un account di archiviazione collegato e usa lo stesso codice di sincronizzazione su ogni dispositivo. Lettura e ascolto restano separati.';
	@override String get addSyncSource => 'Aggiungi prima Google Drive, OneDrive, Dropbox, WebDAV o S3 in File e libri.';
	@override String get syncDestination => 'Account di archiviazione per la sincronizzazione';
	@override String get syncFolder => 'Cartella o prefisso di sincronizzazione';
	@override String get syncFolderHelp => 'Usa una cartella separata già esistente nella tua fonte WebDAV oppure un prefisso S3 dedicato. I file dei libri non vengono mai modificati.';
	@override String get syncCode => 'Codice privato di sincronizzazione';
	@override String get syncCodeHelp => 'Crea un codice sul primo dispositivo, poi inseriscilo sugli altri dispositivi. Conservane una copia privata: è la chiave dei dati di sincronizzazione crittografati. Usa un codice diverso per ogni persona.';
	@override String get showCode => 'Mostra o nascondi il codice di sincronizzazione';
	@override String get newSyncCode => 'Crea un nuovo codice di sincronizzazione';
	@override String get saveSync => 'Salva e sincronizza';
	@override String get disableSync => 'Disattiva la sincronizzazione su questo dispositivo';
	@override String get syncSourceDisconnect => 'Rimuovendo questa fonte, disattiverai la sincronizzazione di lettura e ascolto su questo dispositivo. I file di sincronizzazione crittografati resteranno presso il fornitore del servizio.';
	@override String get syncReconnect => 'Ricollega l’account di archiviazione';
	@override String lastSynced({required Object time}) => 'Ultima sincronizzazione: ${time}';
	@override String get syncPrivacy => 'Vengono memorizzati solo i progressi e le note, in forma crittografata. I file audio e degli ebook, i token degli account e le password non vengono caricati. Google Drive e OneDrive usano lo spazio riservato all’app; Dropbox usa PlezyNG Sync. L’attivazione della sincronizzazione può richiedere ulteriori permessi di scrittura. Quando è attiva, questa destinazione gestisce la sincronizzazione dei progressi; i progressi sul server restano separati. Disattivandola, la cronologia locale e lo stato remoto vengono conservati.';
	@override String get syncConflicts => 'Scegli da dove riprendere';
	@override String get conflictHelp => 'Queste modifiche sono state apportate indipendentemente. Scegli quale posizione o versione del segnalibro conservare. Una data e ora più recente o una percentuale più alta non hanno automaticamente la precedenza.';
	@override String syncDevice({required Object device}) => 'Dispositivo ${device}';
	@override String get syncUnknownDevice => 'dispositivo sconosciuto';
	@override String get deletedBookmark => 'Segnalibro eliminato';
	@override String get finished => 'Completato';
	@override String readingPosition({required Object percent}) => 'Lettura · ${percent}%';
	@override String get chapterTimeline => 'Avanzamento del capitolo';
	@override String get bookTimeline => 'Avanzamento dell’intero libro';
	@override String bookRemaining({required Object time}) => 'Il tempo rimanente in questo libro: ${time}';
	@override String chapterRemaining({required Object time}) => 'Il tempo rimanente in questo capitolo: ${time}';
	@override String get unknownRemaining => 'Il tempo totale sarà disponibile man mano che vengono riprodotte le parti';
	@override String get undoSeek => 'Annulla l’ultimo salto di riproduzione';
	@override String get customSpeed => 'Velocità di riproduzione personalizzata';
	@override String get speedHelp => 'Scegli una velocità da 0,25× a 4×.';
	@override String get apply => 'Applica';
	@override String get customSleep => 'Timer di arresto personalizzato';
	@override String get sleepMinutes => 'Minuti (1–1440)';
	@override String sleepChapters({required Object count}) => 'Capitoli prima dell’arresto: ${count}';
	@override String get extendSleep => 'Aggiungi 5 minuti';
	@override String sleepRemaining({required Object time}) => 'Timer di arresto: ${time}';
	@override String get useDefaults => 'Usa questi controlli di ascolto per i nuovi libri';
	@override String get librarySort => 'Ordina i libri';
	@override String get sortTitle => 'Titolo';
	@override String get sortAuthor => 'Autore';
	@override String get sortNarrator => 'Narratore';
	@override String get sortSeries => 'Ordine della serie';
	@override String get sortRecent => 'Aperti di recente';
	@override String get statusFilter => 'Stato di lettura';
	@override String get statusAll => 'Tutti i libri';
	@override String get statusNew => 'Non iniziato';
	@override String get statusProgress => 'In corso';
	@override String get statusFinished => 'Completato';
	@override String get goToTime => 'Vai al tempo indicato';
	@override String get timeHelp => 'ore:minuti:secondi oppure minuti:secondi';
	@override String get recoveryHelp => 'Esportare una copia recentemente crittografata prima di spostare o riparare i dati di sincronizzazione. Le importazioni si uniscono allo stato corrente; non sostituiscono mai la storia locale della sincronizzazione.';
	@override String get recoveryExport => 'Esporta il file di recupero crittografato';
	@override String get recoveryImport => 'Importa il file di recupero crittografato';
	@override String get recoveryImportConfirm => 'Combinare questo file di recupero crittografato con posizioni di lettura corrente e note? Storia esistente sarà conservata. ID della biblioteca condivisa e degli articoli non sono inclusi; impostare ID corrispondenti su ogni dispositivo prima dell\'importazione.';
	@override String get recoveryExported => 'Il file di recupero crittografato salvato.';
	@override String get recoveryImported => 'I dati di recupero sono misti.';
}

// Path: sourceSetup
class _Translations$sourceSetup$it extends Translations$sourceSetup$en {
	_Translations$sourceSetup$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Certificato del server salvato';
	@override String get nfsEndpointInvalid => 'Inserisci un URL NFS, ad esempio nfs://nas:2049/export.';
	@override String get dlnaNone => 'Nessun server DLNA trovato. Inserisci manualmente l’URL della descrizione del dispositivo.';
	@override String get dlnaServers => 'Server multimediali DLNA';
	@override String get dlnaUnavailable => 'Il rilevamento DLNA non è disponibile su questa rete. Inserisci manualmente l’URL della descrizione del dispositivo.';
	@override String get dlnaSearching => 'Ricerca di server DLNA nella rete locale';
	@override String get networkSearching => 'Ricerca nella rete locale…';
	@override String get dlnaDiscover => 'Rileva server DLNA';
	@override String get dlnaHelp => 'Il rilevamento dipende dal multicast sulla rete locale. Se non compare alcun server, inserisci qui sopra l’URL della sua descrizione del dispositivo.';
	@override String get dlnaRoot => 'ID dell’oggetto DLNA; lascia vuoto per usare la radice del dispositivo.';
	@override String get passwordOrKey => 'Inserisci una password oppure aggiungi una chiave privata qui sotto.';
	@override String get sshFingerprint => 'Impronta SHA256 della chiave host SSH';
	@override String get sshFingerprintHelp => 'Verificala con l’amministratore del server. Sul server, esegui ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub e usa il valore SHA256.';
	@override String get sshFingerprintKeep => 'Lascia vuoto per mantenere l’impronta attualmente fissata oppure inserisci una nuova impronta del server.';
	@override String get sshAuthentication => 'Autenticazione SSH con chiave pubblica';
	@override String get sshAuthenticationHelp => 'Facoltativa; è supportata anche l’autenticazione con password.';
	@override String get privateKey => 'Chiave privata (formato PEM o OpenSSH)';
	@override String get privateKeyPassphrase => 'Passphrase della chiave privata';
	@override String get nfsMountPort => 'Porta TCP del servizio di montaggio NFS';
	@override String get nfsMountPortHelp => 'Predefinita: 20048';
	@override String get nfsUserId => 'ID utente NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Predefinito: 1000. Usa l’ID consentito dalla condivisione NFS del NAS.';
	@override String get nfsGroupId => 'ID gruppo NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Predefinito: 1000. Usa l’ID gruppo consentito dalla condivisione NFS del NAS.';
	@override String get nfsEncryption => 'Richiedi NFS crittografato (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Richiedi TLS 1.3 per NFS e il servizio di montaggio. Se il NAS non lo supporta, la connessione viene rifiutata.';
	@override String get nfsTrustCertificate => 'CA NFS personalizzata o certificato del server (PEM, facoltativo)';
	@override String get nfsTrustHelp => 'Lascia vuoto per usare i certificati considerati attendibili da questo dispositivo. Se necessario, aggiungi un certificato di una CA privata o un certificato del server autofirmato; i nomi indicati devono corrispondere all’host nell’URL NFS.';
	@override String get nfsTrustInvalid => 'Usa un certificato di una CA o del server in formato PEM. Non includere una chiave privata.';
	@override String get addTrustCertificate => 'Aggiungi un certificato attendibile personalizzato';
	@override String get replaceTrustCertificate => 'Sostituisci il certificato personalizzato salvato';
	@override String get nfsTlsHelp => 'RPC-with-TLS usa le normali porte NFS e del servizio di montaggio e richiede che il NAS supporti RFC 9289. È necessario TLS 1.3. Il nome host o l’indirizzo IP deve corrispondere al certificato. Gli UID/GID AUTH_SYS restano validi anche nel canale crittografato.';
	@override String get clientCertificate => 'Certificato client (facoltativo)';
	@override String get clientCertificateHelp => 'Consente al NAS di autenticare questo client; gli ID AUTH_SYS dipendono comunque dai criteri della condivisione NFS del NAS.';
	@override String get savedIdentity => 'Verrà usata un’identità client salvata.';
	@override String get replaceIdentity => 'Sostituisci l’identità client salvata';
	@override String get chooseIdentity => 'Scegli un’identità client PKCS#12';
	@override String get identityPassphrase => 'Passphrase dell’identità client';
	@override String get identityPassphraseHelp => 'Lascia vuoto se il file non ha una passphrase.';
	@override String get removeIdentity => 'Rimuovi qualsiasi identità client salvata';
	@override String get identityStorageHelp => 'Le identità client vengono salvate nell’archivio crittografato delle credenziali della fonte. Lascia invariata questa sezione per mantenere l’identità salvata.';
	@override String get nfsLimitations => 'NFSv3 in sola lettura su TCP. Senza RPC-with-TLS, il traffico NFS non è crittografato. Il NAS deve consentire gli ID AUTH_SYS selezionati e le porte client non privilegiate (spesso tramite l’opzione di esportazione “insecure”). NFSv4 e UDP non sono supportati.';
	@override String get nfsSetupHelp => 'Guida alla configurazione NFS';
	@override String get nfsSetupHint => 'Controlla queste impostazioni se la connessione non si apre.';
	@override String get nfsSetupDetails => 'Usa una condivisione NFSv3 su TCP. Quando è richiesta la crittografia, sia il servizio NFS sia quello di montaggio devono supportare RPC-with-TLS. Lascia vuoto il certificato personalizzato per usare un certificato del server attendibile per questo dispositivo, oppure aggiungi il certificato della CA del NAS o quello autofirmato. Il nome nel certificato deve corrispondere all’host dell’endpoint. Se il NAS richiede TLS reciproco, aggiungi la sua identità client PKCS#12. Infine, verifica che la condivisione consenta gli UID/GID AUTH_SYS configurati e i criteri delle porte client.';
	@override String get ftpHelp => 'FTP usa la modalità passiva. Usa ftp:// per FTP non crittografato, ftpes:// per TLS esplicito oppure ftps:// per TLS (implicito sulla porta 990, esplicito sulle altre porte).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Ricerca facoltativa di sottotitoli per video indipendenti.';
	@override String get apiKey => 'Chiave API';
	@override String get optionalUsername => 'Nome utente dell’account (facoltativo)';
	@override String get optionalPassword => 'Password dell’account (facoltativa)';
	@override String get subtitlePrivacy => 'Ottieni una chiave API da opensubtitles.com. La ricerca invia il titolo del video e gli ID IMDb/TMDB disponibili, mai il file video. La chiave e le credenziali facoltative dell’account vengono crittografate insieme a questa fonte.';
	@override String get automaticMetadata => 'Metadati video online automatici';
	@override String get metadataPrivacy => 'Invia solo titolo/anno ricavati dal nome del file e numeri degli episodi, oppure un ID NFO; non invia mai contenuti multimediali o credenziali. I campi NFO mantengono la precedenza.';
	@override String get nfsEncryptionFailure => 'Per NFS crittografato, verifica il supporto di RFC 9289 e TLS 1.3 su entrambi i servizi del NAS, il nome nel certificato e gli UID/GID della condivisione. PlezyNG non riproverà questa connessione senza crittografia.';
	@override String get sourceConnecting => 'Connessione alla fonte';
	@override String get metadataSearchPrivacy => 'Questa ricerca di titoli viene inviata a Trakt. Viene trasmesso il titolo inserito, non il video né le credenziali della fonte.';
	@override String get chooseMatch => 'Scegli una corrispondenza';
	@override String get metadataMatchHelp => 'Controlla titolo e anno prima di scegliere. Trakt riceve il titolo cercato; il video rimane nella sua fonte.';
	@override String get metadataNoMatches => 'Nessun titolo corrispondente trovato online. Prova un titolo diverso.';
	@override String get metadataSearch => 'Cerca metadati online';
	@override String get metadataLoading => 'Ricerca online dei dettagli di film e serie TV…';
	@override String get metadataFromTrakt => 'Metadati online da Trakt';
	@override String get metadataNoAutomaticMatch => 'Nessuna corrispondenza automatica trovata per il titolo. Cerca il titolo per scegliere una corrispondenza.';
	@override String get metadataFailed => 'Impossibile caricare i metadati online. La riproduzione e i dettagli locali restano disponibili.';
	@override String get videoDetailsLoading => 'Caricamento dei dettagli del video';
	@override String get subtitleKeyRequired => 'È necessaria una chiave API OpenSubtitles';
	@override String get subtitleKeyHelp => 'Modifica questa fonte di file e aggiungi una chiave API OpenSubtitles nelle impostazioni facoltative dei sottotitoli.';
	@override String get subtitleSearchFailed => 'Ricerca dei sottotitoli non riuscita. Controlla la chiave API, la connessione e l’accesso al servizio.';
	@override String get subtitleApplyFailed => 'Impossibile scaricare o applicare questi sottotitoli. Controlla la connessione e prova un altro risultato.';
	@override String get subtitleSearch => 'Cerca su OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'La ricerca usa il titolo e gli ID IMDb/TMDB disponibili. Il file video rimane nella sua fonte. Prima di scegliere, controlla lingua, indicazioni di sottotitoli forzati o per non udenti e valutazione.';
	@override String get movieOrShow => 'Film o serie';
	@override String get subtitleTitleHint => 'Inserisci un titolo per affinare i risultati';
	@override String get subtitleLanguage => 'Lingua dei sottotitoli';
	@override String get subtitleSearching => 'Ricerca su OpenSubtitles';
	@override String get subtitleNoMatches => 'Nessun sottotitolo corrispondente trovato. Prova un titolo o una lingua diversi.';
	@override String get downloadSubtitle => 'Scarica sottotitoli';
	@override String get subtitle => 'Sottotitoli';
	@override String get nfsTlsRequired => 'RPC-with-TLS obbligatorio';
	@override String get nfsUnencrypted => 'NFS non crittografato';
	@override String get tlsEncrypted => 'Crittografato con TLS';
	@override String get ftpPlain => 'FTP non crittografato';
	@override String get sshPinned => 'SSH crittografato · chiave host fissata';
	@override String get smbEncrypted => 'Crittografia SMB3 attiva';
	@override String get smbUnencrypted => 'Crittografia SMB3 disattivata';
	@override String get httpUnencrypted => 'HTTP senza crittografia del trasporto';
	@override String get checkEndpointSecurity => 'Controlla la sicurezza dell’endpoint';
	@override String fieldRequired({required Object label}) => 'Campo obbligatorio: ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Inserisci ${label} tra ${min} e ${max}.';
	@override String replaceFile({required Object name}) => 'Sostituisci ${name}';
	@override String selectedIdentity({required Object name}) => 'Identità client selezionata: ${name}';
	@override String subtitleRating({required Object rating}) => 'Valutazione ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Download dei sottotitoli: ${title}';
	@override String get sharedEntryPair => 'Coppia questo articolo';
	@override String get sharedEntryPairHelp => 'Inserisci lo stesso ID per questo elemento su ciascun dispositivo. Utilizzare un identificatore condiviso stabile o generare uno e copiarlo all\'oggetto che corrisponde. Progress coppia solo quando i tipi di file edizioni, le dimensioni e l\'ordine corrispondono. Blank rimuove questa mappatura.';
	@override String get sharedEntryId => 'ID di oggetto condiviso';
	@override String get generateSharedEntryId => 'Generare un ID di oggetto condiviso';
	@override String get sharedLibraryId => 'ID della biblioteca condivisa (opzionale)';
	@override String get sharedLibraryHelp => 'Utilizzare lo stesso ID su dispositivi che aprono la stessa biblioteca.Questo ID pubblico aiuta a portare il progresso della lettura e delle note attraverso diverse connessioni sorgente; non è una password.Quando i fornitori utilizzano diversi ID di oggetto, coppia questi elementi dalle loro schermi dettagliati.';
	@override String get sharedLibraryInvalid => 'Utilizzare 8-100 lettere, numeri, punti, sottoscori o hyphens.';
	@override String get generateSharedLibraryId => 'Generare un ID della biblioteca condivisa';
	@override String get nfsReadAhead => 'Le richieste di read-ahead della NFS';
	@override String get nfsReadAheadHelp => 'Più letture parallele possono migliorare la capacità di passaggio su un NAS o una rete veloce. Utilizzare 1 se il server limita le richieste concorrenti.';
	@override String get nfsReadTest => 'Misurare le prestazioni di NFS';
	@override String get nfsReadTestHelp => 'Legge fino a 64 MiB dal file più grande per misurare questa connessione NAS. Questo utilizza la larghezza di banda della rete.';
	@override String get nfsQualificationResult => 'NFS Leggi la misura';
	@override String get nfsReadBytes => 'Dati di lettura';
	@override String get nfsReadSpeed => 'velocità misurata';
	@override String get nfsReadRequests => 'Leggi le richieste';
	@override String get sharedEntryConflict => 'Questo ID di oggetto condiviso è già associato ad un altro elemento in questa biblioteca.';
}

// Path: comics
class _Translations$comics$it extends Translations$comics$en {
	_Translations$comics$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Adatta all’altezza';
	@override String get readingMode => 'Modalità di lettura';
	@override String get paged => 'Pagine';
	@override String get webtoon => 'Scorrimento continuo';
	@override String get coverAlone => 'Mostra la copertina da sola';
	@override String get splitWide => 'Dividi le pagine larghe';
	@override String get splitWideHelp => 'Mostra ogni metà separatamente, nell’ordine di lettura. La visualizzazione di due pagine affiancate viene sospesa quando questa opzione è attiva.';
	@override String get thumbnails => 'Miniature delle pagine';
	@override String get controlsHelp => 'Scorri con il dito per voltare pagina. Tocca due volte per cambiare l’adattamento. Nello scorrimento continuo, scorri verticalmente o usa Pagina su e Pagina giù.';
	@override String get savedForComic => 'Le impostazioni di visualizzazione vengono memorizzate per questo fumetto in questo profilo.';
	@override String get readLists => 'Liste di lettura';
	@override String get collections => 'Raccolte';
}

// Path: games
class _Translations$games$it extends Translations$games$en {
	_Translations$games$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamAppId => 'Steam App ID';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
	@override String get steamLibraryHint => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.';
}

// Path: deepLinks
class _Translations$deepLinks$it extends Translations$deepLinks$en {
	_Translations$deepLinks$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Questo link Plezy non è valido.';
	@override String profileNotFound({required Object profile}) => 'Nessun profilo corrisponde a "${profile}".';
	@override String get serverUnavailable => 'Non riuscivo a raggiungere il server per questo link.';
	@override String get notFound => 'Non riesco a trovare questo titolo nelle tue biblioteche.';
	@override String get unsupportedItem => 'Questo link non può essere giocato.';
	@override String get noLiveTv => 'Nessun server TV Live è disponibile per questo link.';
	@override String channelNotFound({required Object channel}) => 'Non potevo trovare il canale "${channel}".';
	@override String get showLink => 'Mostra il link';
	@override String get showProfileLink => 'Mostra il profilo link';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'Aprendo questo link verrà riprodotto il prossimo episodio. Aggiungi &mode=shuffle alla fine per riprodurre la serie in ordine casuale.';
	@override String get movieHint => 'Aprire questo link gioca il film.';
	@override String get episodeHint => 'Aprire questo link gioca questo episodio.';
	@override String get profileHint => 'Aprire questo link scorre a questo profilo.';
	@override String openAsProfile({required Object name}) => 'Apri come ${name}';
	@override String get copy => 'Copia';
	@override String get copied => 'Link copiato';
}

// Path: appIcon.names
class _Translations$appIcon$names$it extends Translations$appIcon$names$en {
	_Translations$appIcon$names$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Mezzanotte';
	@override String get ember => 'Brace';
	@override String get paper => 'Carta';
	@override String get oled => 'OLED';
	@override String get line => 'Linea';
	@override String get ocean => 'Oceano';
	@override String get ultraviolet => 'Ultravioletto';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Tramonto';
	@override String get gold => 'Oro';
	@override String get titanium => 'Titanio';
	@override String get glass => 'Vetro';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Pixel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Adesivo';
	@override String get ticket => 'Biglietto';
	@override String get pop => 'Pop';
	@override String get strata => 'Strati';
	@override String get facet => 'Sfaccettature';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$it extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
class _Translations$common$mediaKind$it extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Serie';
	@override String get season => 'Stagione';
	@override String get episode => 'Episodio';
	@override String get artist => 'Artista';
	@override String get album => 'Album';
	@override String get track => 'Traccia';
	@override String get collection => 'Raccolta';
	@override String get playlist => 'Playlist';
	@override String get clip => 'Clip';
	@override String get photo => 'Foto';
	@override String get folder => 'Cartella';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$it extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Apri raccomandazioni e articoli da fonti di scoperta collegate.';
	@override String get libraries => 'Apri le tue biblioteche multimediali connesse.';
	@override String get liveTv => 'Apri Live TV quando un server lo fornisce; altrimenti la startup ritorna a Home.';
	@override String get search => 'La ricerca dei media aperti.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$it extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Sfondo';
	@override String get surface => 'Superficie';
	@override String get outline => 'Contorno';
	@override String get text => 'Testo';
	@override String get textMuted => 'Testo secondario';
	@override String get accent => 'Accento';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$it extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Testo sullo sfondo';
	@override String get textOnSurface => 'Testo sulla superficie';
	@override String get textMutedOnBg => 'Testo secondario sullo sfondo';
	@override String get textMutedOnSurface => 'Testo secondario sulla superficie';
	@override String get accentOnBg => 'Accento sullo sfondo';
	@override String get accentOnSurface => 'Accento sulla superficie';
	@override String get labelOnAccent => 'Etichetta dei pulsanti sull\'accento';
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
	@override String get subtitleDelayIncrease => 'Ritarda sottotitoli';
	@override String get subtitleDelayDecrease => 'Anticipa sottotitoli';
	@override String get shaderToggle => 'Attiva/disattiva shader';
	@override String get skipMarker => 'Salta intro/titoli di coda';
	@override String get screenshot => 'Cattura schermata';
	@override String get framePrevious => 'Precedente Frame';
	@override String get frameNext => 'Prossimo Frame';
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
	@override String get prepareFailed => 'Impossibile preparare la modalità Picture-in-Picture';
	@override String unknown({required Object error}) => 'Si è verificato un errore: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$it extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get no => 'Mantenere le lettere, i colori, le dimensioni e la posizione scritte nel file sottotitolo.';
	@override String get yes => 'Permettere che le impostazioni di stile del sottotitolo del giocatore adattino i sottotitoli ASS.';
	@override String get scale => 'Applicare lo stile del giocatore e scalare le dimensioni incorporate per corrispondere alle dimensioni video.';
	@override String get force => 'Sostituisci gli stili ASS incorporati con lo stile di sottotitolo del giocatore.';
	@override String get strip => 'Rimuovere il formato ASS incorporato e rendere chiaro il testo sottotitolo.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$it extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render alla piena risoluzione della superficie dello schermo per il risultato più acuto.';
	@override String get video => 'Render utilizzando la risoluzione video come riferimento, che può ridurre il lavoro su display ad alta risoluzione.';
	@override String get threeQuarter => 'Render al 75% della risoluzione superficiale dello schermo per un modesto risparmio di prestazioni.';
	@override String get half => 'Render al 50% della risoluzione superficiale dello schermo per ridurre il lavoro, con margini più sottili.';
	@override String get third => 'Render a un terzo della risoluzione superficiale dello schermo per ridurre il lavoro, con margini più sottili.';
	@override String get quarter => 'Render a un quarto della risoluzione superficie dello schermo per ridurre il lavoro, con il risultato più morbido.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$it extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio e sottotitoli';
	@override String get libraryDisplay => 'Libreria';
	@override String get personalMedia => 'Media personali';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$it extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Selezionati manualmente';
	@override String get noneDescription => 'Non attivare mai i sottotitoli automaticamente.';
	@override String get defaultMode => 'Segui le flag della traccia';
	@override String get defaultModeDescription => 'Usa le flag predefinite e forzate salvate su ogni traccia di sottotitoli.';
	@override String get always => 'Sempre attivi';
	@override String get alwaysDescription => 'Attiva una traccia di sottotitoli nella lingua preferita quando disponibile.';
	@override String get onlyForced => 'Solo sottotitoli forzati';
	@override String get onlyForcedDescription => 'Carica solo le tracce contrassegnate come forzate.';
	@override String get smart => 'Mostrati con audio straniero';
	@override String get smartDescription => 'Attiva i sottotitoli solo quando l\'audio è in un\'altra lingua.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$it extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Preferisci i sottotitoli non SDH';
	@override String get preferSdh => 'Preferisci i sottotitoli SDH';
	@override String get onlySdh => 'Solo sottotitoli SDH';
	@override String get onlyNonSdh => 'Solo sottotitoli non SDH';
	@override String get preferNonSdhDescription => 'Preferisce i sottotitoli standard quando sono disponibili sia le versioni standard che SDH.';
	@override String get preferSdhDescription => 'Preferisce i sottotitoli SDH quando disponibili, ma consente sottotitole standard come un fallback.';
	@override String get onlySdhDescription => 'Utilizzare solo i sottotitoli SDH; non cadere indietro ai subtitoli standard.';
	@override String get onlyNonSdhDescription => 'Utilizzare solo i sottotitoli standard; escludere i sottotiti SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$it extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Preferisci i sottotitoli non forzati';
	@override String get preferForced => 'Preferisci i sottotitoli forzati';
	@override String get onlyForced => 'Solo sottotitoli forzati';
	@override String get onlyNonForced => 'Solo sottotitoli non forzati';
	@override String get preferNonForcedDescription => 'Preferisce sottotitoli regolari, ma consente tracce forzate come una caduta.';
	@override String get preferForcedDescription => 'Preferisce tracce forzate quando disponibili, ma consente sottotitoli regolari come ritorno.';
	@override String get onlyForcedDescription => 'Utilizzare solo tracce segnalate come forzate.';
	@override String get onlyNonForcedDescription => 'Escluse le tracce segnalate come forzate.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$it extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Mai';
	@override String get moviesAndShows => 'Film e serie TV';
	@override String get movies => 'Solo film';
	@override String get shows => 'Solo serie TV';
	@override String get noneDescription => 'Non mostrare segni di controllo osservati.';
	@override String get moviesAndShowsDescription => 'Mostra segnalazioni guardate per film e spettacoli televisivi.';
	@override String get moviesDescription => 'Mostra segnalazioni visualizzate solo per i film.';
	@override String get showsDescription => 'Mostra segnalazioni guardate solo per i programmi televisivi.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$it extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Utenti e critici';
	@override String get usersOnly => 'Solo utenti';
	@override String get criticsOnly => 'Solo critici';
	@override String get nobody => 'Nascoste';
	@override String get usersAndCriticsDescription => 'Visualizza entrambe le valutazioni degli utenti e le valutazione critica.';
	@override String get usersOnlyDescription => 'Mostra le valutazioni e le recensioni presentate dagli utenti.';
	@override String get criticsOnlyDescription => 'Mostra valutazioni critiche e recensioni.';
	@override String get nobodyDescription => 'Scopri le valutazioni e le recensioni.';
}

// Path: discover.findNext
class _Translations$discover$findNext$it extends Translations$discover$findNext$en {
	_Translations$discover$findNext$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'La tua prossima scoperta';
	@override String get open => 'La tua prossima scoperta';
	@override String get anyTime => 'Senza limiti di tempo';
	@override String get timeAvailable => 'Quanto tempo hai?';
	@override String get filters => 'Scegli per questo momento';
	@override String get watch => 'Guarda';
	@override String get listen => 'Ascolta';
	@override String get read => 'Leggi';
	@override String finishable({required Object duration}) => 'Puoi finire in ${duration}';
	@override String aboutDuration({required Object duration}) => 'Circa ${duration}';
	@override String nextUnit({required Object duration}) => 'Prossimo capitolo · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} in totale';
	@override String get timingVaries => 'La durata può variare';
	@override String get notNow => 'Non ora';
	@override String get swipeHint => 'Scorri la copertina verso una freccia oppure usa i pulsanti qui sotto.';
	@override String get saved => 'Suggerimenti salvati';
	@override String savedCount({required Object count}) => 'Suggerimenti salvati · ${count}';
	@override String get undo => 'Annulla';
	@override String get details => 'Dettagli';
	@override String get noPicks => 'Non c’è ancora nulla da scegliere';
	@override String get noPicksHint => 'Collega una libreria o aggiungi una fonte multimediale per iniziare.';
	@override String get noMatches => 'Nulla di adatto a questo momento';
	@override String get noMatchesHint => 'Prova un altro tipo di contenuto o concediti più tempo.';
	@override String get allDone => 'Hai visto tutti i suggerimenti';
	@override String get allDoneHint => 'Avvia una nuova selezione per rivedere queste proposte.';
	@override String get refresh => 'Trova un’altra selezione';
	@override String sourceReason({required Object source}) => 'Da ${source}';
	@override String libraryReason({required Object library}) => 'Da ${library}';
	@override String get ownedReason => 'Dalla tua libreria';
	@override String get liveNow => 'In onda ora';
	@override String get watchLive => 'Guarda in diretta';
	@override String get filterAnything => 'Qualsiasi tipo';
	@override String get filterWatch => 'Guarda';
	@override String get filterListen => 'Ascolta';
	@override String get filterRead => 'Leggi';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Applica';
	@override String get openFailed => 'Questa scelta non è più disponibile. Aggiorna per verificare di nuovo.';
	@override String get changeFailed => 'Impossibile salvare la modifica. Riprova.';
	@override String get savedLimit => 'L’elenco dei suggerimenti salvati è pieno. Rimuovine uno per salvarne un altro.';
	@override String get chooseHint => 'Apri un titolo, salvalo per dopo o passa al successivo.';
	@override String get howItWorks => 'Come funziona';
	@override String get notNowHelp => 'Salta questo titolo per ora. Rimane nella tua libreria.';
	@override String get saveHelp => 'Conservalo tra le scelte salvate di questo profilo su questo dispositivo. Il salvataggio non lo scarica.';
	@override String get openHelp => 'Seleziona la copertina per i dettagli. Usa l’azione principale per riprodurre, leggere o aprire il titolo.';
	@override String get controlsHelp => 'Tastiera o telecomando: seleziona un pulsante, poi premi Invio o Seleziona. Annulla ripristina la tua ultima scelta.';
	@override String get artworkLoading => 'Caricamento immagine…';
	@override String get artworkUnavailable => 'Immagine non disponibile';
	@override String get savedFeedback => 'Aggiunto alle scelte salvate';
	@override String get skippedFeedback => 'Saltato per ora';
	@override String get releaseToConfirm => 'Rilascia per confermare';
	@override String get remoteHint => 'Copertina selezionata: ← / → scegli · Seleziona: dettagli · ↑ / ↓ sposta il focus';
}

// Path: discover.person
class _Translations$discover$person$it extends Translations$discover$person$en {
	_Translations$discover$person$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get born => 'Data di nascita';
	@override String get died => 'Data di morte';
	@override String get birthplace => 'Luogo di nascita';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} anni)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (a ${age} anni)';
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
	@override String get filePath => 'Percorso del file';
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
	@override String get dateDownloaded => 'Data di download';
	@override String get size => 'Dimensione';
	@override String get library => 'Libreria';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$it extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get include => 'Includi';
	@override String get exclude => 'Escludi';
	@override String get any => 'Qualsiasi';
	@override String get yes => 'Sì';
	@override String get no => 'No';
	@override String not({required Object value}) => 'Tranne ${value}';
	@override String valueCount({required Object count}) => '${count} selezionati';
	@override String valueCountExcluded({required Object count}) => '${count} esclusi';
	@override String get searchValues => 'Cerca valori';
	@override String get noValues => 'Nessun valore';
	@override String get matchContains => 'Contiene';
	@override String get matchNotContains => 'Non contiene';
	@override String get matchIs => 'È';
	@override String get matchIsNot => 'Non è';
	@override String get matchBeginsWith => 'Inizia con';
	@override String get matchEndsWith => 'Finisce con';
	@override String get textHint => 'Digita il testo da cercare';
	@override String get from => 'Da';
	@override String get to => 'A';
	@override String range({required Object from, required Object to}) => 'Da ${from} a ${to}';
	@override String atLeast({required Object value}) => '${value} e oltre';
	@override String atMost({required Object value}) => 'Fino a ${value}';
	@override String dateLastDays({required Object count}) => 'Ultimi ${count} giorni';
	@override String get dateLastYear => 'Ultimo anno';
	@override String dateOlderThanDays({required Object count}) => 'Più di ${count} giorni fa';
	@override String get dateOlderThanYear => 'Più di un anno fa';
}

// Path: libraries.selection
class _Translations$libraries$selection$it extends Translations$libraries$selection$en {
	_Translations$libraries$selection$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Selezionare gli oggetti';
	@override String selectedCount({required Object count}) => '${count} selezionati';
	@override String get actions => 'azioni di selezione';
	@override String get confirmDescendants => 'Questo cambia tutti gli episodi nei spettacoli e nelle stagioni selezionate.';
	@override String get confirmUnwatched => 'Verrà azzerato anche l’avanzamento della riproduzione degli elementi selezionati.';
	@override String confirmCount({required Object count}) => 'I prodotti selezionati: ${count}.';
	@override String completed({required Object count}) => 'Articoli aggiornati: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Aggiornato ${succeeded}; fallito ${failed}. gli articoli falliti rimangono selezionati.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$it extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Gestione esplora le scale';
	@override String get manageDescription => 'Scegli e organizzi elenchi dal tuo account MDBList';
	@override String get description => 'Scegli le liste di film e TV pubbliche dal tuo account MDBList. Crea o copia le liste su MDBList, poi ristrutturare.';
	@override String get selected => 'Le scale selezionate';
	@override String get available => 'Elenco dei conti disponibili';
	@override String get noLists => 'Non sono stati restituiti film pubblici o elenchi televisivi. Creare o copiare un elenco su MDBList, poi rinfrescare.';
	@override String get displayName => 'Nome di display Shelf';
	@override String get nameHint => 'Lascia la lista di fonti per utilizzare il nome della lista di fondi.';
	@override String get add => 'Aggiungi Shelf';
	@override String get save => 'Salva le scale';
	@override String moveUp({required Object title}) => 'Move ${title} in alto';
	@override String moveDown({required Object title}) => 'Rimuovere ${title}';
	@override String get unavailable => 'Questo elenco non è disponibile. rimuovere o rimuovere la sua scheda nelle impostazioni.';
	@override String get rateLimited => 'Il limite di richiesta MDBList è stato raggiunto. si prega di ritirarsi in seguito.';
	@override String get loadFailed => 'Non si possono caricare le strisce. controllare la connessione e ritorno.';
	@override String get saveFailed => 'Non riesco a salvare le scale, per favore, ritiro.';
	@override String get accountChanged => 'Il profilo o l\'account è cambiato.Riavvi queste impostazioni.';
	@override String get settingsUnreadable => 'Le schede salvate non possono essere lette. selezionare nuovamente le liste per sostituire queste impostazioni.';
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

// Path: explore.badge
class _Translations$explore$badge$it extends Translations$explore$badge$en {
	_Translations$explore$badge$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} popolari';
	@override String rankAiring({required Object n}) => '#${n} in onda';
	@override String rankRated({required Object n}) => '#${n} valutati';
	@override String rankTrending({required Object n}) => '#${n} di tendenza';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} in ${season}';
	@override String watchingNow({required Object n}) => '${n} in visione';
	@override String get available => 'Disponibile';
	@override String get partiallyAvailable => 'Parzialmente disponibile';
	@override String get availableIn4k => 'Disponibile in 4K';
	@override String get requested => 'Richiesto';
	@override String get pendingApproval => 'In attesa di approvazione';
	@override String get processing => 'In elaborazione';
	@override String get declined => 'Rifiutato';
	@override String get requestFailed => 'Richiesta non riuscita';
	@override String get requested4k => 'Richiesto in 4K';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} stagioni';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} tra ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Prossimo tra ${duration}';
	@override String episodesShort({required Object n}) => '${n} ep';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$it extends Translations$explore$stats$en {
	_Translations$explore$stats$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} in elenco';
	@override String viewersDay({required Object n}) => '${n} guardati oggi';
	@override String viewersWeek({required Object n}) => '${n} guardati questa settimana';
	@override String viewersMonth({required Object n}) => '${n} guardati questo mese';
	@override String viewersYear({required Object n}) => '${n} guardati quest\'anno';
	@override String viewersAllTime({required Object n}) => '${n} spettatori';
	@override String planning({required Object n}) => '${n} hanno in programma di guardarlo';
	@override String favorited({required Object n}) => '${n} preferiti';
	@override String dropRate({required Object percent}) => '${percent} lo ha abbandonato';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commento',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commenti',
	);
	@override String votes({required Object n}) => '${n} voti';
	@override String watching({required Object n}) => '${n} lo stanno guardando';
	@override String completed({required Object n}) => '${n} completati';
	@override String onHold({required Object n}) => '${n} in pausa';
	@override String dropped({required Object n}) => '${n} abbandonati';
}

// Path: explore.season
class _Translations$explore$season$it extends Translations$explore$season$en {
	_Translations$explore$season$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Inverno';
	@override String get spring => 'Primavera';
	@override String get summer => 'Estate';
	@override String get fall => 'Autunno';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$it extends Translations$explore$format$en {
	_Translations$explore$format$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV Short';
	@override String get movie => 'Film';
	@override String get special => 'Speciale';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Musica';
	@override String get other => 'Altro';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$it extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get original => 'Originale';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Romanzo';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Videogioco';
	@override String get webComic => 'Web comic';
	@override String get musicRelease => 'Musica';
	@override String get otherMedia => 'Altro';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$it extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Attore';
	@override String get director => 'Regista';
	@override String get writer => 'Sceneggiatore';
	@override String get producer => 'Produttore';
	@override String get creator => 'Creatore';
	@override String get composer => 'Compositore';
}

// Path: explore.relation
class _Translations$explore$relation$it extends Translations$explore$relation$en {
	_Translations$explore$relation$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prequel';
	@override String get sequel => 'Sequel';
	@override String get sideStory => 'Storia secondaria';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Versione alternativa';
	@override String get summary => 'Riepilogo';
	@override String get parentStory => 'Storia originale';
	@override String get adaptation => 'Adattamento';
	@override String get other => 'Correlati';
}

// Path: explore.detail
class _Translations$explore$detail$it extends Translations$explore$detail$en {
	_Translations$explore$detail$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Titolo originale';
	@override String get alsoKnownAs => 'Conosciuto anche come';
	@override String get studios => 'Studi';
	@override String get country => 'Paese';
	@override String get language => 'Lingua';
	@override String get released => 'Uscito';
	@override String get physicalRelease => 'Su disco';
	@override String get ended => 'Concluso';
	@override String addedOn({required Object date}) => 'Aggiunto ${date}';
	@override String get yourRating => 'La tua valutazione';
	@override String get budget => 'Budget';
	@override String get revenue => 'Incassi';
	@override String get contentAdvisory => 'Guida all\'età';
	@override String get tags => 'Tag';
	@override String get revealSpoilerTags => 'Mostra tag spoiler';
	@override String get links => 'Link';
	@override String get watchOn => 'Guarda su';
	@override String get watchTrailer => 'Guarda trailer';
	@override String openOn({required Object site}) => 'Apri su ${site}';
	@override String get crew => 'Cast tecnico';
	@override String get ratings => 'Valutazioni';
	@override String get schedule => 'Programmazione';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n,
		one: 'Consigliato da ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utente',
		other: 'Consigliato da ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utenti',
	);
	@override String recommendedBy({required Object who}) => 'Consigliato da ${who}';
	@override String favoritedBy({required Object who}) => 'Preferito da ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} non ancora in onda';
	@override String recommendedByPercent({required Object percent}) => 'Consigliato dal ${percent} degli spettatori';
	@override String get relatedTitles => 'Titoli correlati';
	@override String get background => 'Contesto';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$it extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Inizia in anticipo (secondi)';
	@override String get endLate => 'Termina in ritardo (secondi)';
	@override String get newOnly => 'Solo nuovi episodi';
	@override String get anyChannel => 'Registra su qualsiasi canale';
	@override String get anyTime => 'Registra a qualsiasi ora';
	@override String get skipInLibrary => 'Salta gli episodi già presenti nella libreria';
	@override String get keepUpTo => 'Episodi da conservare';
	@override String get keepUpToHint => '0 conserva tutti gli episodi';
}

// Path: music.discography
class _Translations$music$discography$it extends Translations$music$discography$en {
	_Translations$music$discography$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singoli ed EP';
	@override String get live => 'Dal vivo';
	@override String get compilations => 'Compilation';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$it extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} ha premuto Riproduci';
	@override String get playbackStarted => 'Riproduzione avviata';
	@override String paused({required Object name}) => '${name} ha messo in pausa';
	@override String get playbackPaused => 'Riproduzione in pausa';
	@override String jumpedTo({required Object name, required Object position}) => '${name} è passato a ${position}';
	@override String roomJumpedTo({required Object position}) => 'Riproduzione spostata a ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} ha impostato la velocità a ${speed}';
	@override String speedChanged({required Object speed}) => 'Velocità impostata a ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} ha avviato ${title}';
	@override String mediaStarted({required Object title}) => 'In riproduzione: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} ha interrotto il video';
	@override String get mediaStopped => 'Il video è stato interrotto';
	@override String waitingFor({required Object name}) => 'In attesa di ${name}...';
	@override String get waitingForSomeone => 'In attesa che qualcuno si metta in pari...';
	@override String get finished => 'Terminato';
	@override String hostChangedTo({required Object name}) => '${name} è ora l\'host';
	@override String get youAreNowHost => 'Ora sei l\'host';
	@override String joined({required Object name}) => '${name} si è unito';
	@override String left({required Object name}) => '${name} se ne è andato';
	@override String get controlRefused => 'Solo l\'host può controllare la riproduzione';
	@override String get searchFailed => 'Su alcuni server non è stato possibile cercare il video della stanza';
	@override String get playBlocked => 'Premi Riproduci per iniziare';
	@override String get shareFailed => 'Impossibile condividere questo video con la stanza';
	@override String get downloadNotShared => 'I download non vengono condivisi con la stanza mentre il loro server è offline';
	@override String get openFailed => 'Impossibile aprire il video della stanza';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$it extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get ended => 'L\'host ha chiuso la stanza';
	@override String get kicked => 'Sei stato rimosso dalla stanza';
	@override String get expired => 'La stanza è scaduta';
	@override String get replaced => 'Sei entrato in questa stanza da un altro dispositivo';
	@override String get lost => 'Connessione alla stanza persa';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$it extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Questo non è un codice stanza. I codici sono composti da 6 lettere e cifre, senza 0, 1, I, L o O.';
	@override String get roomNotFound => 'Nessuna stanza ha questo codice. Potrebbe essere stata chiusa.';
	@override String get roomFull => 'La stanza è piena.';
	@override String get roomLocked => 'L\'host ha bloccato la stanza.';
	@override String get relayFull => 'Guarda insieme è momentaneamente sovraccarico. Riprova più tardi.';
	@override String get unreachable => 'Impossibile raggiungere il relay di Guarda insieme. Controlla la connessione.';
	@override String get rateLimited => 'Troppi tentativi. Attendi un momento e riprova.';
	@override String get clientBlocked => 'Questa versione di PlezyNG non può usare il relay. Aggiorna l\'app.';
	@override String get forbidden => 'Solo l\'host può farlo.';
	@override String get notInRoom => 'Non sei in una stanza.';
	@override String get alreadyInRoom => 'Sei già in una stanza.';
	@override String get resumeFailed => 'Impossibile rientrare nella stanza.';
	@override String get unsupported => 'Il relay non supporta questa funzione.';
	@override String get generic => 'Si è verificato un problema. Riprova.';
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
	@override String get sheetIntro => 'Android impedisce a PlezyNG di scaricare in modo affidabile in background.';
	@override String get sheetIntroDegraded => 'Il dispositivo limita i momenti in cui PlezyNG può scaricare in background.';
	@override String get reasonBackgroundRestricted => 'L’uso in background di PlezyNG è limitato. Nelle impostazioni della batteria o dell’uso in background, seleziona «Senza restrizioni».';
	@override String get reasonStandbyRestricted => 'Android ha messo PlezyNG in uno stato di standby con restrizioni. Imposta l’uso della batteria su «Senza restrizioni».';
	@override String get reasonDownloadChannelBlocked => 'Le notifiche dei download sono disattivate, quindi l’avanzamento e i controlli potrebbero non essere disponibili.';
	@override String get reasonNotificationsDisabled => 'Le notifiche sono disattivate. Su Android 13 o versioni successive sono necessarie per i download prolungati in background.';
	@override String get reasonDataSaver => 'Il Risparmio dati è attivo e blocca i download in background tramite dati mobili. I download dovrebbero comunque funzionare su Wi-Fi.';
	@override String get reasonOemUnknown => 'I download si sono interrotti più volte mentre PlezyNG era in background. Controlla le impostazioni della batteria o dell’uso in background di PlezyNG.';
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

// Path: downloads.groupings
class _Translations$downloads$groupings$it extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get library => 'Libreria';
	@override String get collections => 'Raccolte';
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
	@override String get manualAddressHint => 'Indirizzo di connessione manuale:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$it extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'I dispositivi PlezyNG con lo stesso account Plex appaiono qui';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Connessione...';
	@override String get searchingForDevices => 'Ricerca dispositivi...';
	@override String get noDevicesFound => 'Nessun dispositivo trovato nella tua rete';
	@override String get noDevicesHint => 'Apri PlezyNG sul computer e usa la stessa rete Wi-Fi';
	@override String get availableDevices => 'Dispositivi disponibili';
	@override String get manualConnection => 'Connessione manuale';
	@override String get cryptoInitFailed => 'Impossibile avviare la connessione sicura. Accedi prima a Plex.';
	@override String get validationHostRequired => 'Inserisci l\'indirizzo host';
	@override String get validationHostFormat => 'Il formato deve essere IP:porta (es. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tempo scaduto per la connessione. Usa la stessa rete su entrambi i dispositivi.';
	@override String get sessionNotFound => 'Dispositivo non trovato. Assicurati che PlezyNG sia in esecuzione sull\'host.';
	@override String get authFailed => 'Autenticazione non riuscita. Entrambi i dispositivi devono usare lo stesso account Plex.';
	@override String failedToConnect({required Object error}) => 'Connessione non riuscita: ${error}';
	@override String get codeTitle => 'Codice di coppia';
	@override String get codeDescription => 'Inserisci il codice mostrato nella Companion Remote sul dispositivo ospitante. entrambi i dispositivi devono utilizzare una versione che supporta la coppia sicura.';
	@override String get codeInvalid => 'Inserisci tutte le 32 lettere e i numeri dal codice ospitante.';
	@override String get updateRequired => 'Aggiornare entrambi i dispositivi a una versione che supporta la coppia sicura.';
	@override String get hostDescription => 'Inserisci questo codice una volta su ogni remote.Mantenere privato: consente il controllo di questo profilo.';
	@override String get resetCode => 'Ristrutturazione di codice di coppia';
	@override String get resetDescription => 'Disconnetti tutti i remoti e crea un nuovo codice. Ogni remote dovrà coppia di nuovo.';
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
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$it extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Riconnetti Simkl';
	@override String get subtitle => 'Simkl sta dismettendo il metodo di accesso usato da questa connessione. La riconnessione apre simkl.com per autorizzare PlezyNG — PlezyNG non vede mai la tua password. La tua cronologia di visione resta su Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$it extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Attiva PlezyNG su ${service}';
	@override String get instructions => 'Scansiona il codice QR oppure visita l\'indirizzo qui sotto e inserisci questo codice:';
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
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$it extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
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
	@override String get modeDescription => 'Scegli se le biblioteche controllate sono bloccate dalla sincronizzazione o sono le uniche biblioteche che sincronizzano.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$it extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Sincronare episodi e film guardati con il tuo account Trakt.';
	@override String get mal => 'Sync anime elenchi e guardare il progresso con MyAnimeList.';
	@override String get anilist => 'Sync anime elenchi e guardare il progresso con AniList.';
	@override String get simkl => 'Sync ha guardato film, programmi televisivi e anime con Simkl.';
	@override String get mdblist => 'Mostra valutazioni e elenchi MDBList nelle raccomandazioni e esplora.';
}

/// The flat map containing all translations for locale <it>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsIt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Icona dell\'app',
			'appIcon.defaultIcon' => 'Predefinita',
			'appIcon.current' => 'Icona attuale',
			'appIcon.locked' => 'L’accesso a vita richiesto',
			'appIcon.lockedHint' => 'Inizia il tuo tentativo di 7 giorni o disattivare PlezyNG per tutta la vita per utilizzare icone alternative.',
			'appIcon.changeFailed' => 'Impossibile cambiare l\'icona dell\'app',
			'appIcon.launcherHint' => 'La nuova icona appare nella schermata Home quando esci da PlezyNG.',
			'appIcon.tvLauncherHint' => 'Il nuovo banner appare quando esci da PlezyNG. Android TV potrebbe continuare a mostrare quello precedente fino al riavvio del televisore.',
			'appIcon.names.midnight' => 'Mezzanotte',
			'appIcon.names.ember' => 'Brace',
			'appIcon.names.paper' => 'Carta',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Linea',
			'appIcon.names.ocean' => 'Oceano',
			'appIcon.names.ultraviolet' => 'Ultravioletto',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Tramonto',
			'appIcon.names.gold' => 'Oro',
			'appIcon.names.titanium' => 'Titanio',
			'appIcon.names.glass' => 'Vetro',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Pixel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Adesivo',
			'appIcon.names.ticket' => 'Biglietto',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Strati',
			'appIcon.names.facet' => 'Sfaccettature',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Scegli l\'icona mostrata dal lanciatore del dispositivo. le previsioni mostrano come appare ogni opzione.',
			'auth.signInWithPlex' => 'Accedi con Plex',
			'auth.showQRCode' => 'Mostra codice QR',
			'auth.authenticate' => 'Autenticati',
			'auth.authenticationTimeout' => 'Tempo scaduto per l\'autenticazione. Riprova.',
			'auth.scanQRToSignIn' => 'Scansiona questo codice QR per accedere',
			'auth.waitingForAuth' => 'In attesa di autenticazione...\nAccedi dal browser.',
			'auth.useBrowser' => 'Usa il browser',
			'auth.or' => 'o',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Connettiti a ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Usa Quick Connect',
			'auth.quickConnectInstructions' => 'Apri Quick Connect in Jellyfin e inserisci questo codice.',
			'auth.quickConnectWaiting' => 'In attesa di approvazione…',
			'auth.quickConnectCancel' => 'Annulla',
			'auth.quickConnectExpired' => 'Quick Connect scaduto. Riprova.',
			'auth.localDataRecoveryRequired' => 'PlezyNG non è riuscito a recuperare in sicurezza i dati locali di accesso e delle riproduzioni in sospeso. Accedi di nuovo.',
			'auth.pinCheckRejected' => 'La verifica del PIN Plex è stata rifiutata',
			'auth.connectToDirectPlex' => 'Connessione al server locale Plex',
			'common.cancel' => 'Annulla',
			'common.save' => 'Salva',
			'common.close' => 'Chiudi',
			'common.closeMiniPlayer' => 'Mini giocatore vicino',
			'common.closeWorkspaceWindow' => 'Finestra vicina',
			'common.returnToFullView' => 'Il ritorno alla vista completa',
			'common.manageMediaSessions' => 'Gestione delle sessioni di media',
			'common.hideMediaSessions' => 'Sessioni di media nascosti',
			'common.mediaSessions' => 'Sessioni di Media',
			'common.mediaSessionsHint' => 'Selezionare per portare una sessione in avanti.Parco nasconde la sua finestra ma la mantiene aperta.Ritorno lo apre in vista completa; vicino si conclude.',
			'common.sessionInWorkspace' => 'nel laboratorio',
			'common.sessionParked' => 'Parcheggiato',
			'common.sessionFullscreen' => 'schermo completo',
			'common.switchToNextWindow' => 'Swap con la finestra successiva',
			'common.moveWindow' => 'Move la finestra',
			'common.finishMovingWindow' => 'Finita la finestra in movimento',
			'common.moveWindowHint' => 'Long-press e tirare la finestra per spostarla. Questo controllo consente anche il movimento della chiave di pistola.',
			'common.movingWindowHelp' => 'Tracciare per muoversi · Aggiungere le chiavi · Entrare i salvatori · Cancelli di escape',
			'common.resizeWindow' => 'Ristrutturare la finestra',
			'common.resizeWindowHint' => 'Rimuovere questo manuale o utilizzare le chiavi della pistola per ripristinare la finestra.',
			'common.workspaceWindowHint' => 'Utilizzare il controllo di movimento o lunghi pressioni e tirare per muoversi.',
			'common.workspacePaneHint' => 'Selezionare questo pannello per focalizzarlo. utilizzare il suo controllo a schermo pieno per espandere.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Finestra di sessione: ${title}',
			'common.workspaceTitleHint' => 'Selezionare per concentrarsi. spostare la barra di titolo per muoversi; utilizzare il pulsante a schermo pieno per espandere.',
			'common.moveToSessionTray' => 'Trasferimento alla sessione tray',
			'common.moveToSessionTrayHint' => 'La sessione è disponibile senza mostrare la sua finestra.',
			'common.closeSessionHint' => 'Chiude questa finestra e conclude la sua sessione.',
			'common.sideBySideLayout' => 'Conversione a layout laterale',
			'common.floatingWindows' => 'Switch per fluttuare le finestre',
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
			'common.options' => 'Opzioni',
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
			'common.mediaKind.show' => 'Serie',
			'common.mediaKind.season' => 'Stagione',
			'common.mediaKind.episode' => 'Episodio',
			'common.mediaKind.artist' => 'Artista',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Traccia',
			'common.mediaKind.collection' => 'Raccolta',
			'common.mediaKind.playlist' => 'Playlist',
			'common.mediaKind.clip' => 'Clip',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Cartella',
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
			'settings.supportDeveloper' => 'Supporta PlezyNG',
			'settings.supportDeveloperDescription' => 'Fai una donazione per sostenere lo sviluppo',
			'settings.lifetimeAccess' => 'PlezyNG accesso a vita',
			'settings.language' => 'Lingua',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aspetto',
			'settings.detailPage' => 'Pagina dettagliata',
			'settings.themeSongsEnabled' => 'Gioca canzoni di tema',
			'settings.themeSongsEnabledDescription' => 'Gioca canzoni di tema disponibili mentre guarda i dettagli dei media.',
			'settings.themeSongVolume' => 'Il volume della canzone',
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
			'settings.emberTheme' => 'Brace',
			'settings.glacierTheme' => 'Ghiacciaio',
			'settings.forestTheme' => 'Foresta',
			'settings.plumTheme' => 'Prugna',
			'settings.paperTheme' => 'Carta',
			'settings.libraryDensity' => 'Densità della libreria',
			'settings.displayScale' => 'Scala di visualizzazione',
			'settings.compact' => 'Compatta',
			'settings.comfortable' => 'Comoda',
			'settings.gridSpacing' => 'Spaziatura della griglia',
			'settings.gridSpacingTight' => 'Ristretta',
			'settings.gridSpacingNormal' => 'Normale',
			'settings.gridSpacingSpacious' => 'Ampia',
			'settings.tvCornerSpotlightBackdrop' => 'Sfondo in evidenza nell\'angolo',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostra l\'immagine in evidenza nell\'angolo in alto a destra anziché a schermo intero',
			'settings.viewMode' => 'Modalità di visualizzazione',
			'settings.gridView' => 'Griglia',
			'settings.listView' => 'Elenco',
			'settings.showHeroSection' => 'Mostra sezione in evidenza',
			'settings.showHomeBackdrop' => 'Home Artica Artica Artico Artica Arta',
			'settings.showHomeBackdropDescription' => 'Mostra grandi opere d\'arte dietro le linee di casa',
			'settings.contentScreensaverEnabled' => 'ScreenSaver di contenuti',
			'settings.contentScreensaverEnabledDescription' => 'Mostra l\'arte a schermo pieno dopo che l\'app è stata idle',
			'settings.contentScreensaverDelay' => 'Inizia il screensaver dopo',
			'settings.contentScreensaverLibraries' => 'Screensaver biblioteche',
			'settings.contentScreensaverLibrariesDescription' => 'Scegli quali librerie forniscono le immagini per lo screensaver. Se non ne selezioni nessuna, verranno usate le immagini di tutte le librerie.',
			'settings.contentScreensaverAllLibraries' => 'Tutte le biblioteche',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} biblioteche selezionate',
			'settings.contentScreensaverNoLibraries' => 'Non sono disponibili biblioteche multimediali collegate.',
			'settings.contentScreensaverDismissHint' => 'Premere qualsiasi pulsante o tappa per rimuovere',
			'settings.newEpisodeNotifications' => 'Nuove notizie di episodio',
			'settings.newEpisodeNotificationsDescription' => 'Allarme quando un nuovo episodio viene aggiunto a un show che si è catturato. controlla mentre Plezy è aperto.',
			'settings.continueWatchingRowSize' => 'Continua a guardare la dimensione della linea',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} carte',
			'settings.rowSizeCompact' => 'Compatta',
			'settings.rowSizeStandard' => 'Standard',
			'settings.rowSizeLarge' => 'Grande',
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
			'settings.showWatchedIndicators' => 'Mostra indicatori di visione',
			'settings.showWatchedIndicatorsDescription' => 'Mostra un segno di spunta su film, serie TV ed episodi già visti',
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
			'settings.playbackBuffer' => 'Buffer di riproduzione',
			'settings.playbackBufferAuto' => 'Auto (consigliato)',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extra grande',
			'settings.playbackBufferDescription' => 'Bufferizza di più contro connessioni instabili. Limitato anche dalla dimensione del buffer.',
			'settings.streamBufferSize' => 'Dimensioni Buffer',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Quanto video da caricare in avanti quando si gioca direttamente. i transcodi si fermeranno al buffer transcodico del server. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Rimpiazzare Playback Buffer quando impostato, cappellato a metà del limite di memoria dell\'app',
			'settings.streamBufferMegabytes' => 'Megabiti',
			'settings.defaultQualityTitle' => 'Qualità predefinita',
			'settings.cellularQualityTitle' => 'Qualità predefinita sulla rete mobile',
			'settings.remoteQualityTitle' => 'Qualità di Remote Streaming',
			'settings.remoteQualitySameAsDefault' => 'Come la qualità default',
			'settings.cellularQualitySameAsDefault' => 'Come la qualità predefinita',
			'settings.directPlayCoveredQuality' => 'Riproduci i video più piccoli in qualità originale',
			'settings.directPlayCoveredQualityDescription' => 'Riproduci direttamente i video già entro il limite di qualità invece di transcodificarli',
			'settings.videoCodecs' => 'Codec video',
			'settings.videoCodecsDescription' => 'Il server transcodifica i codec non selezionati',
			'settings.videoCodecsAlwaysAccepted' => 'Sempre accettato',
			'settings.musicQualityTitle' => 'Qualità musicale',
			'settings.subtitleStyling' => 'Stile sottotitoli',
			'settings.subtitleStylingDescription' => 'Personalizza l\'aspetto dei sottotitoli',
			'settings.smallSkipDuration' => 'Salto breve',
			'settings.largeSkipDuration' => 'Salto lungo',
			'settings.rewindOnResume' => 'Riavvolgimento alla ripresa',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondo', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondi', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondi', ), 
			'settings.defaultSleepTimer' => 'Timer spegnimento predefinito',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuti', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuti', ), 
			'settings.rememberTrackSelections' => 'Ricorda la selezione delle tracce per ogni serie o film',
			'settings.chooseTracksBeforePlayback' => 'Scegli audio e sottotitoli prima di riprodurre',
			'settings.chooseTracksBeforePlaybackDescription' => 'Selezionare le tracce audio e sottotitoli prima che ogni video inizia.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Mostra sempre i sottotitoli su questo dispositivo',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Quando il server non ha alcun sottotitolo selezionato, selezionare una traccia localmente.',
			'settings.autoDownloadPreferredSubtitle' => 'Il libro di Fethch mantiene i sottotitoli preferiti',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Selezionare un sottotitolo disponibile nella lingua preferita localmente. se non esiste, chiedi al server di ottenere uno quando supportato.',
			'settings.rememberTrackSelectionsDescription' => 'Ricorda le scelte di audio e sottotitoli per ogni titolo',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex salva ogni scelta sul server per ogni file; Jellyfin attiva anche l\'opzione Ricorda selezioni dell\'account; Emby non è supportato',
			'settings.followServerTrackSelections' => 'Usa le tracce selezionate sul server per ogni episodio',
			'settings.followServerTrackSelectionsDescription' => 'Al cambio di episodio applica l\'audio e i sottotitoli selezionati sul server invece di mantenere la scelta corrente',
			'settings.resumeMusicOnLaunch' => 'Ricorda la sessione musicale',
			'settings.resumeMusicOnLaunchDescription' => 'All\'avvio dell\'app riapri l\'ultimo brano in pausa dal punto in cui era rimasto',
			'settings.showChapterMarkersOnTimeline' => 'Mostra i marcatori dei capitoli sulla barra di avanzamento',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segmenta la barra di avanzamento ai confini dei capitoli',
			'settings.specialsOrdering' => 'Speciali nell\'ordine degli episodi',
			'settings.specialsOrderingDescription' => 'Dove vengono riprodotti gli speciali nell\'ordine di visione di una serie',
			'settings.specialsOrderingServer' => 'Segui l\'ordine del server',
			'settings.specialsOrderingAirDate' => 'Intercalati per data di trasmissione',
			'settings.specialsOrderingLast' => 'Dopo le stagioni normali',
			'settings.clickVideoTogglesPlayback' => 'Fai clic sul video per alternare riproduzione e pausa',
			'settings.clickVideoTogglesPlaybackDescription' => 'Fai clic sul video per riprodurre o mettere in pausa anziché mostrare i controlli.',
			'settings.videoPlayerControls' => 'Controlli del lettore video',
			'settings.keyboardShortcuts' => 'Scorciatoie da tastiera',
			'settings.keyboardShortcutsDescription' => 'Personalizza le scorciatoie da tastiera',
			'settings.videoPlayerNavigation' => 'Navigazione del lettore video',
			'settings.videoPlayerNavigationDescription' => 'Usa i tasti freccia per navigare nei controlli del lettore video',
			'settings.watchTogetherRelay' => 'Relay di Guarda insieme',
			'settings.watchTogetherRelayDescription' => 'Relay pubblici di Open Watch Party, se non ne imposti uno tuo',
			'settings.watchTogetherRelayHint' => 'https://mio-relay.esempio.it',
			'settings.watchTogetherRelayInvalid' => 'Inserisci un URL di base HTTP o HTTPS valido per il relay.',
			'settings.crashReporting' => 'Segnalazione degli arresti anomali',
			'settings.crashReportingDescription' => 'Invia segnalazioni sugli arresti anomali per contribuire a migliorare l\'app',
			'settings.debugLogging' => 'Registrazione di debug',
			'settings.debugLoggingDescription' => 'Abilita una registrazione dettagliata per la risoluzione dei problemi',
			'settings.viewLogs' => 'Visualizza i log',
			'settings.viewLogsDescription' => 'Visualizza i log dell\'applicazione',
			'settings.clearImageCache' => 'Svuota cache immagini',
			'settings.clearImageCacheDescription' => 'Svuota le immagini e le miniature memorizzate nella cache. Le immagini potrebbero caricarsi più lentamente finché non vengono scaricate di nuovo.',
			'settings.clearImageCacheSuccess' => 'Cache immagini svuotata correttamente',
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
			'settings.importSettingsInvalidFile' => 'Questo file non è un\'esportazione PlezyNG valida',
			'settings.importSettingsNoUser' => 'Accedi prima di importare le impostazioni',
			'settings.cloudBackup' => 'Cloud Backup di sicurezza',
			'settings.cloudBackupDescription' => 'Esegui il backup delle impostazioni trasferibili a un indirizzo WebDAV tramite HTTPS. Le connessioni ai server e le credenziali restano su questo dispositivo.',
			'settings.cloudBackupUrl' => 'WebDAV URL del file JSON',
			'settings.cloudBackupUsername' => 'Nome utente',
			'settings.cloudBackupPassword' => 'Password',
			'settings.cloudBackupSaved' => 'Cloud backup destinazione salvata',
			'settings.cloudBackupNow' => 'Ritorno adesso',
			'settings.cloudBackupComplete' => 'Settings Backup upload',
			'settings.cloudBackupRestore' => 'Ristrutturazione Backup',
			'settings.cloudBackupRestoreConfirm' => 'Questo sostituirà le impostazioni portatili in questo dispositivo.',
			'settings.cloudBackupRestored' => 'Impostazioni ripristinate dal cloud backup',
			'settings.shortcutsReset' => 'Scorciatoie ripristinate alle impostazioni predefinite',
			'settings.resetShortcutsConfirm' => 'Le scorciatoie personalizzate verranno sostituite con quelle predefinite. Continuare?',
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
			'settings.autoPlayAndSkip' => 'Riproduzione automatica e salti',
			'settings.autoPlayNextEpisode' => 'Riproduci automaticamente l\'episodio successivo',
			'settings.autoPlayNextEpisodeDescription' => 'Avvia automaticamente l\'episodio successivo quando termina quello in riproduzione',
			'settings.shuffleStartsFromBeginning' => 'La riproduzione casuale inizia dall\'inizio',
			'settings.shuffleStartsFromBeginningDescription' => 'Avvia ogni episodio dall\'inizio durante la riproduzione casuale invece di riprenderlo',
			'settings.plexCinemaPreRoll' => 'Utilizzare il server cinema intros',
			'settings.plexCinemaPreRollDescription' => 'Gioca configurati Plex pre-roll o Jellyfin e Emby intros prima che un film inizia.',
			'settings.playNextCountdown' => 'Conto alla rovescia del successivo',
			'settings.playNextCountdownImmediate' => 'Riproduci subito',
			'settings.skipIntroMode' => 'Salta intro',
			'settings.skipIntroModeOffDescription' => 'Riproduci le intro normalmente senza pulsante di salto',
			'settings.skipIntroModeButtonDescription' => 'Mostra un pulsante di salto quando inizia un\'intro',
			'settings.skipIntroModeAutoDescription' => 'Salta automaticamente le intro dopo il ritardo indicato sotto',
			'settings.skipCreditsMode' => 'Salta titoli di coda',
			'settings.skipCreditsModeOffDescription' => 'Riproduci i titoli di coda normalmente senza pulsante di salto',
			'settings.skipCreditsModeButtonDescription' => 'Mostra un pulsante di salto quando iniziano i titoli di coda',
			'settings.skipCreditsModeAutoDescription' => 'Salta automaticamente i titoli di coda e riproduci l\'episodio successivo',
			'settings.skipAdsMode' => 'Scopri gli annunci',
			'settings.skipAdsModeOffDescription' => 'Gioca gli annunci rilevati normalmente senza un pulsante di scappamento',
			'settings.skipAdsModeButtonDescription' => 'Mostra un pulsante di scappamento quando Plex rileva un annuncio',
			'settings.skipAdsModeAutoDescription' => 'Scarica gli annunci rilevati automaticamente dopo il ritardo di seguito',
			'settings.musicPlayback' => 'Il musicale playback',
			'settings.musicSweetFades' => 'dolci fati',
			'settings.musicSweetFadesDescription' => 'La musica è in arrivo quando Plex ha dati di rumore.',
			'settings.skipMarkerModeOff' => 'Disattivato',
			'settings.skipMarkerModeButton' => 'Mostra pulsante',
			'settings.skipMarkerModeAuto' => 'Automatico',
			'settings.forceSkipMarkerFallback' => 'Forza i marcatori di ripiego',
			'settings.forceSkipMarkerFallbackDescription' => 'Usa i modelli dei titoli dei capitoli anche quando Plex dispone di marcatori',
			'settings.theIntroDbFallback' => 'Utilizzare TheIntroDB come un fallback intro',
			'settings.theIntroDbFallbackDescription' => 'Utilizzare le date della comunità solo quando il server non ha un intro marker.',
			'settings.autoSkipDelay' => 'Ritardo del salto automatico',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Attendi ${seconds} secondi prima del salto automatico',
			'settings.introPattern' => 'Modello del marcatore della sigla iniziale',
			'settings.introPatternDescription' => 'Espressione regolare per individuare i marcatori della sigla iniziale nei titoli dei capitoli',
			'settings.creditsPattern' => 'Modello del marcatore dei titoli di coda',
			'settings.creditsPatternDescription' => 'Espressione regolare per individuare i marcatori dei titoli di coda nei titoli dei capitoli',
			'settings.prerolls' => 'Prerotti',
			'settings.playPrerollsBeforeMovies' => 'Gioca i preloli prima dei film',
			'settings.playPrerollsBeforeMoviesDescription' => 'Gioca un clip casuale dalla tua selezione qui sotto prima di ogni film.',
			'settings.prerollLibrary' => 'Libreria di Preroll',
			'settings.prerollLibraryNotSet' => 'Non impostato',
			'settings.prerollLibraryNoneFound' => 'Non sono state trovate biblioteche sui tuoi server.',
			'settings.prerollSelection' => 'I preloni selezionati',
			'settings.prerollSelectionPickLibraryFirst' => 'Scegli una biblioteca prima',
			'settings.prerollSelectionNoneSelected' => 'Nessun preludio selezionato',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} selezionati',
			'settings.prerollItemPicker' => 'Selezionare i preroli',
			'settings.prerollItemPickerLoadFailed' => 'Non potevo caricare gli articoli da questa biblioteca.',
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
			'settings.autoDownloadContinueWatching' => 'Auto-Download Continua a guardare',
			'settings.autoDownloadContinueWatchingDescription' => 'Mantenere gli articoli sul vostro foglio di guardare continuo scaricati, e rimuoverli una volta che lasciano il foglio',
			'settings.downloadQuality' => 'Scarica la qualità',
			'settings.downloadQualityDescription' => 'Plex prepara una copia convertita nella sua scatola di download. Jellyfin e Emby transcode mentre il file scarica; trasferimenti interrotti potrebbero essere necessari per riavviare.',
			'settings.askDownloadQualityEachTime' => 'Scegliere la qualità per ogni download',
			'settings.askDownloadQualityEachTimeDescription' => 'Mostra il picker di qualità prima di scorrere ogni download video',
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
			'settings.companionRemoteServerStartFailed' => 'Impossibile avviare il server del telecomando',
			'settings.companionRemoteServerStopFailed' => 'Impossibile arrestare il server del telecomando',
			'settings.autoPip' => 'Picture-in-Picture automatica',
			'settings.autoPipDescription' => 'Attiva automaticamente la modalità Picture-in-Picture quando esci dall\'app durante la riproduzione',
			'settings.matchContentFrameRate' => 'Adatta la frequenza dei fotogrammi',
			'settings.matchContentFrameRateDescription' => 'Adatta la frequenza di aggiornamento dello schermo al contenuto video',
			'settings.matchContentResolution' => 'Adatta alla risoluzione del contenuto',
			'settings.matchContentResolutionDescription' => 'Passa lo schermo alla risoluzione nativa del video, così è la TV a occuparsi dell\'upscaling. Durante la riproduzione vengono ridimensionati anche menu e sottotitoli',
			'settings.matchRefreshRate' => 'Adatta la frequenza di aggiornamento',
			'settings.matchRefreshRateDescription' => 'Adatta la frequenza di aggiornamento dello schermo in modalità a schermo intero',
			'settings.matchDynamicRange' => 'Adatta la gamma dinamica',
			'settings.matchDynamicRangeDescription' => 'Attiva l\'HDR per i contenuti HDR, quindi torna all\'SDR',
			'settings.displaySwitchDelay' => 'Ritardo del cambio di modalità dello schermo',
			'settings.tunneledPlayback' => 'Riproduzione con tunneling',
			'settings.tunneledPlaybackDescription' => 'Usa il tunneling video. Disattivalo se durante la riproduzione HDR lo schermo rimane nero o il movimento scatta.',
			'settings.audioPassthrough' => 'Passthrough audio',
			'settings.audioPassthroughDescription' => 'Invia l\'audio Dolby/DTS al ricevitore o al televisore senza ricodificarlo, preservando l\'audio surround. Disattiva questa opzione se non senti alcun suono.',
			'settings.audioPassthroughDescriptionApple' => 'Usa il decoder Dolby nativo di Apple per Dolby Digital Plus, incluso Atmos. DTS e TrueHD vengono comunque riprodotti come PCM multicanale. Disattiva questa opzione se non senti alcun suono.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Usa il decoder Dolby nativo di Apple per Dolby Digital Plus, incluso Atmos. Su iOS, iPadOS e tvOS 26 o versioni successive, TrueHD Atmos e DTS:X vengono riprodotti come audio spaziale. Le altre tracce DTS e TrueHD vengono riprodotte come PCM multicanale. Disattiva questa opzione se non senti alcun suono.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Disattivato mentre la normalizzazione del volume è attiva',
			'settings.audioChannelLimit' => 'Canali audio',
			'settings.audioChannelLimitDescription' => 'Esegui il downmix dell\'audio decodificato per altoparlanti, cuffie o configurazioni HDMI che non possono riprodurre tutti i canali',
			'settings.audioChannelLimitOriginal' => 'Originale',
			'settings.audioChannelLimitOriginalDescription' => 'Riproduci tutti i canali della traccia',
			'settings.audioChannelLimitSurround51' => 'Fino a 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Esegui il downmix da 7.1 a 5.1 per televisori e ricevitori che accettano solo PCM 5.1. Il passthrough non viene modificato.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Esegui il downmix a due canali per altoparlanti stereo o cuffie. Disattiva il passthrough.',
			'settings.downmixCenterBoost' => 'Amplificazione canale centrale',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Amplificazione (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizza il volume durante il downmix',
			'settings.audioDownmixNormalizeDescription' => 'Riduce il volume del mix per evitare il clipping. Disattiva questa opzione per mantenere il volume originale (le scene più rumorose potrebbero risultare distorte).',
			'settings.dvConversionMode' => 'Conversione Dolby Vision',
			'settings.dvConversionModeDescription' => 'Scegli come gestire i file Dolby Vision con profilo 7.',
			'settings.dvConversionAuto' => 'Auto',
			'settings.dvConversionNative' => 'Nativa / disattivata',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Rileva le capacità del dispositivo e usa il normale meccanismo di ripiego',
			'settings.dvConversionNativeDescription' => 'Forza il DV7 nativo e impedisce nuovi tentativi di conversione DV',
			'settings.dvConversionDv81Description' => 'Forza la conversione RPU diretta al profilo Dolby Vision 8.1',
			'settings.dvConversionHevcStripDescription' => 'Rimuove i livelli RPU/EL di Dolby Vision e riproduce il video come semplice HEVC',
			'settings.experimentalDolbyVision' => 'Dolby Vision sperimentale',
			'settings.experimentalDolbyVisionDescription' => 'Usa il renderer FEL sperimentale alla prossima riproduzione. Richiede una compilazione separata del motore.',
			'settings.dvExperimentUnavailableDescription' => 'Questo esperimento è attualmente disponibile solo su Linux.',
			'settings.dvCompatibilityFallback' => 'Alternativa di compatibilità',
			'settings.dvCompatibilityFallbackDescription' => 'Usa il renderer standard se l’esperimento non si avvia. I dati FEL potrebbero andare persi.',
			'settings.dvExperimentDiagnostics' => 'Registro dell’esperimento video',
			'settings.dvExperimentDiagnosticsDescription' => 'Attiva i log dettagliati del lettore alla prossima riproduzione.',
			'settings.disableDolbyVision' => 'Disattiva Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Riproduci il livello HDR10 o HLG del file al posto di Dolby Vision, se presente',
			'settings.hdrSdrConversion' => 'Conversione da HDR a SDR',
			'settings.hdrSdrConversionDescription' => 'Scegli cosa converte i video HDR quando lo schermo non può mostrare l\'HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Auto',
			'settings.hdrSdrConversionAutoDescription' => 'Dispositivo da Android 9 in poi, lettore nelle versioni precedenti',
			'settings.hdrSdrConversionDevice' => 'Dispositivo',
			'settings.hdrSdrConversionDeviceDescription' => 'La conversione è affidata all\'hardware video del dispositivo. La più veloce, ma i colori dipendono dal dispositivo',
			'settings.hdrSdrConversionPlayer' => 'Lettore',
			'settings.hdrSdrConversionPlayerDescription' => 'La conversione avviene nel lettore. Colori uniformi, ma il 4K può scattare sui TV box di fascia bassa',
			'settings.deinterlace' => 'Deinterlacciamento',
			'settings.deinterlaceDescription' => 'Rimuove gli artefatti a pettine dai video interlacciati (solo lettore mpv)',
			'settings.deinterlaceOff' => 'Disattivato',
			'settings.deinterlaceOffDescription' => 'Mostra il video interlacciato così come viene decodificato',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Trasforma ogni semiquadro in un fotogramma completo. Per video girati per la TV, come sport, notiziari e concerti',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'Ripristina i fotogrammi originali di film e animazioni sottoposti a telecine a 29,97 fps, frequenti nei DVD NTSC. I video girati per la TV scattano. La TV in diretta usa Video',
			'settings.requireProfileSelectionOnOpen' => 'Chiedi di scegliere il profilo all\'apertura',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostra la selezione del profilo ogni volta che l\'app viene aperta',
			'settings.forceTvMode' => 'Forza modalità TV',
			'settings.forceTvModeDescription' => 'Forza il layout TV sui dispositivi che non vengono rilevati automaticamente. Richiede il riavvio.',
			'settings.startInFullscreen' => 'Avvia a schermo intero',
			'settings.startInFullscreenDescription' => 'Apri PlezyNG a schermo intero all\'avvio',
			'settings.exitFullscreenOnPlayerClose' => 'Esci dalla modalità a schermo intero alla chiusura del lettore',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Esce automaticamente dalla modalità a schermo intero quando chiudi il lettore video',
			'settings.autoHidePerformanceOverlay' => 'Nascondi automaticamente il riquadro delle prestazioni',
			'settings.autoHidePerformanceOverlayDescription' => 'Dissolvi il riquadro delle prestazioni insieme ai controlli di riproduzione',
			'settings.showNavBarLabels' => 'Mostra le etichette della barra di navigazione',
			'settings.showNavBarLabelsDescription' => 'Mostra le etichette di testo sotto le icone della barra di navigazione',
			'settings.startupSection' => 'Sezione di avvio',
			'settings.preferredServer' => 'Servizio preferito',
			'settings.preferredServerDescription' => 'Priorizzare i risultati di questo server, mantenendo a disposizione ogni server collegato.',
			'settings.preferredServerAutomatic' => 'Automatico',
			'settings.showExploreTab' => 'Mostra la scheda Esplora',
			'settings.showExploreTabDescription' => 'Visualizza la scheda Esplora con contenuti di Esplora di Plex e dei tracker collegati',
			'settings.hideEmptyLibraries' => 'Chiudere le librerie vuote',
			'settings.hideEmptyLibrariesDescription' => 'Rimuovere le biblioteche con un numero di elementi riportati dal server di zero dalla navigazione.',
			'settings.liveTvDefaultFavorites' => 'Apri sui canali preferiti',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostra solo i canali preferiti quando apri la TV in diretta',
			'settings.general' => 'Generali',
			'settings.generalDescription' => 'Lingua, avvio e comportamento della finestra',
			'settings.languageAndRegion' => 'Lingua e regione',
			'settings.startup' => 'Avvio',
			'settings.display' => 'Schermo',
			'settings.libraryAndCards' => 'Libreria e schede',
			'settings.homeScreen' => 'Schermata iniziale',
			'settings.navigation' => 'Navigazione',
			'settings.window' => 'Finestra',
			'settings.liveTv' => 'TV in diretta',
			'settings.player' => 'Lettore',
			'settings.videoAndDisplay' => 'Video e schermo',
			'settings.audio' => 'Audio',
			'settings.quality' => 'Qualità',
			'settings.subtitles' => 'Sottotitoli',
			'settings.seekAndTiming' => 'Avanzamento e tempi',
			'settings.behavior' => 'Comportamento',
			'settings.gestures' => 'Gesti',
			'settings.gestureBrightnessSwipe' => 'Scorrimento per la luminosità',
			'settings.gestureBrightnessSwipeDescription' => 'Scorri verso l\'alto o il basso sul bordo sinistro per regolare la luminosità',
			'settings.gestureVolumeSwipe' => 'Scorrimento per il volume',
			'settings.gestureVolumeSwipeDescription' => 'Scorri verso l\'alto o il basso sul bordo destro per regolare il volume',
			'settings.gesturePinchToZoom' => 'Pizzica per lo zoom',
			'settings.gesturePinchToZoomDescription' => 'Pizzica il video per ingrandire o ridurre',
			'settings.gestureSeekSwipe' => 'Cerca il Swipe',
			'settings.gestureSeekSwipeDescription' => 'Spostare a sinistra o a destra ovunque nel video per cercare; rilasciare per saltare',
			'settings.rememberBrightnessLevel' => 'Ricorda il livello di luminosità',
			'settings.rememberBrightnessLevelDescription' => 'Avvia la riproduzione con la luminosità impostata dall\'ultimo scorrimento',
			'settings.controls' => 'Controlli',
			'settings.rememberPlayerChanges' => 'Ricorda le modifiche del lettore',
			'settings.rememberPlayerChangesDescription' => 'Dove viene salvata e riapplicata una modifica effettuata durante la riproduzione',
			'settings.scopePlaybackSpeed' => 'Velocità di riproduzione',
			'settings.scopeShaderPreset' => 'Preimpostazione shader',
			'settings.scopeAspectRatio' => 'Proporzioni',
			'settings.scopeSyncOffsets' => 'Sincronizzazione audio e sottotitoli',
			'settings.playerScopeOff' => 'Non salvare',
			'settings.playerScopeGlobal' => 'Ovunque',
			'settings.playerScopeLibrary' => 'Per libreria',
			'settings.playerScopeTitle' => 'Per serie o film',
			'settings.exportDialogTitle' => 'Esporta le impostazioni di PlezyNG',
			'settings.followSystem' => 'Usa la lingua di sistema',
			'settings.followAppLanguage' => 'Come la lingua dell’interfaccia',
			'settings.regionFormat' => 'Formati regionali',
			'settings.regionFormatDescription' => 'Scegli come visualizzare date, numeri e unità di misura.',
			'settings.metadataLanguage' => 'Lingua dei metadati',
			'settings.metadataLanguageDescription' => 'Lingua preferita per titoli e descrizioni, se supportata dal server. Le preferenze audio e sottotitoli si impostano separatamente.',
			'settings.enterFullscreenOnPlaybackStart' => 'Inserisci la schermata completa quando si inizia il playback',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Aprire video desktop in schermo pieno quando si avvia il playback',
			'settings.extendVideoIntoDisplayCutout' => 'Estendere il video in display cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Lascia che il video a schermo pieno utilizzi la cutout della fotocamera sui telefoni Android',
			'settings.languageDescription' => 'Selezionare il linguaggio utilizzato per i controlli e i messaggi PlezyNG. Seguire il sistema traccia la lingua del dispositivo.',
			'settings.themeDescription' => 'Scegliere i colori e il contrasto utilizzati in tutta l\'app.',
			'settings.libraryDensityDescription' => 'Cambiare quante carte di libreria si adatta in ogni riga.',
			'settings.displayScaleDescription' => 'Ristrutturare l\'interfaccia su questo display auto senza cambiare la dimensione del testo in tutto il dispositivo.',
			'settings.themeSongVolumeDescription' => 'Imposta il volume delle canzoni di tema relativamente ad altri audio.',
			'settings.viewModeDescription' => 'Scegli se gli articoli della biblioteca vengono visualizzati come poster in una rete o come elenco compatto.',
			'settings.gridViewDescription' => 'Ordina gli articoli della biblioteca in righe e colonne di poster.',
			'settings.listViewDescription' => 'Mostra gli articoli della biblioteca in una lista verticale con più testo per oggetto.',
			'settings.gridSpacingDescription' => 'Imposta la distanza tra i poster nelle reti della biblioteca.',
			'settings.gridSpacingTightDescription' => 'Pianificare più poster sullo schermo con piccole lacune.',
			'settings.gridSpacingNormalDescription' => 'Utilizzare la differenza standard tra i poster.',
			'settings.gridSpacingSpaciousDescription' => 'Aggiungi più grandi lacune tra i poster per una maggiore separazione.',
			'settings.episodePosterModeDescription' => 'Scegliere quale opera d\'arte appare sulle carte di episodio.',
			'settings.seriesPosterDescription' => 'Utilizzare il poster della serie dello show per ogni episodio.',
			'settings.seasonPosterDescription' => 'Utilizzare il poster di stagione per ogni episodio quando disponibile.',
			'settings.episodeThumbnailDescription' => 'Utilizzare un quadro dell\'episodio quando disponibile.',
			'settings.continueWatchingActionDescription' => 'Scegli ciò che accade quando si attiva una scheda di Continuing Watching.',
			'settings.continueWatchingPlayDescription' => 'Inizia subito il film o l’episodio.',
			'settings.continueWatchingDetailsDescription' => 'Apri prima la pagina titolo in modo da poter rivedere i dettagli e scegliere una azione.',
			'settings.episodeActionDescription' => 'Scegli ciò che accade quando si attiva una scheda di episodio.',
			'settings.episodePlayDescription' => 'Inizia subito l’episodio.',
			'settings.episodeDetailsDescription' => 'Apri la pagina dell\'episodio prima del playback.',
			'settings.contentScreensaverDelayDescription' => 'Scegli quanto tempo PlezyNG aspetta senza input prima di mostrare opere d\'arte.',
			'settings.continueWatchingRowSizeDescription' => 'Scegliamo quanto sono grandi le carte nella riga Continuing Watching.',
			'settings.rowSizeCompactDescription' => 'Mostra carte più piccole in modo che più articoli si adattino per tutta la riga.',
			'settings.rowSizeStandardDescription' => 'Utilizzare la dimensione standard della scheda.',
			'settings.rowSizeLargeDescription' => 'Mostra mappe più grandi con maggiori dettagli artwork.',
			'settings.visualEffectsDescription' => 'Scegli il budget di animazione e effetti artificiali per questo dispositivo.',
			'settings.visualEffectsFullDescription' => 'Utilizzare tutti gli effetti di animazione e arte su ogni dispositivo.',
			'settings.startupSectionDescription' => 'Selezionare quale sezione si apre quando PlezyNG inizia.',
			'settings.startupSectionOptions.discover' => 'Apri raccomandazioni e articoli da fonti di scoperta collegate.',
			'settings.startupSectionOptions.libraries' => 'Apri le tue biblioteche multimediali connesse.',
			'settings.startupSectionOptions.liveTv' => 'Apri Live TV quando un server lo fornisce; altrimenti la startup ritorna a Home.',
			'settings.startupSectionOptions.search' => 'La ricerca dei media aperti.',
			'settings.smallSkipDurationDescription' => 'Imposta la distanza spostata dal breve ritorno e avanti cerca controlli.',
			'settings.largeSkipDurationDescription' => 'Imposta la distanza spostata dal lungo ritorno e avanti cerca controlli.',
			'settings.rewindOnResumeDescription' => 'Spostare il ripristino di questo importo quando si riprende un video.',
			'settings.defaultSleepTimerDescription' => 'Imposta la durata iniziale utilizzata quando si inizia il timer del sonno.',
			'settings.playNextCountdownDescription' => 'Attendere molto prima di iniziare il prossimo episodio. impostare a 0 per iniziare immediatamente.',
			'settings.autoSkipDelaySettingDescription' => 'Si applica quando un intro, credito o annuncio è impostato per scappare automaticamente.',
			'settings.downmixCenterBoostDescription' => 'Aumentare il dialogo nel canale centrale quando l\'audio circostante viene mescolato in stereo.',
			'settings.displaySwitchDelayDescription' => 'Aspettate prima di cambiare il modo di visualizzazione in modo che la TV o il ricevitore possa completare il suo precedente switch.',
			'settings.playerBackendDescription' => 'Selezionare quale motore di riproduzione decodifica e renderà il video su questo dispositivo.',
			'settings.exoPlayerDescription' => 'Utilizzare il player basato su Media3 nativo di Android e i percorsi hardware supportati.',
			'settings.mpvDescription' => 'Utilizzare mpv, che esprime ulteriori controlli di riproduzione, sottotitoli e video processing.',
			'settings.scopeOffDescription' => 'Mantenere i cambiamenti per l\'attuale sessione di riproduzione solo.',
			'settings.scopeGlobalDescription' => 'Ripristinare lo stesso valore per ogni biblioteca e titolo.',
			'settings.scopeLibraryDescription' => 'Ricordate un valore separato per ciascuna biblioteca.',
			'settings.scopeTitleDescription' => 'Ricorda un valore separato per ogni spettacolo o film.',
			'settings.specialsOrderingServerDescription' => 'Mantenere l\'ordine dell\'episodio fornito dal server media.',
			'settings.specialsOrderingAirDateDescription' => 'Posizionare speciali tra episodi regolari per la loro data aerea.',
			'settings.specialsOrderingLastDescription' => 'Posizionare ogni speciale dopo le stagioni regolari.',
			'settings.skipIntroModeDescription' => 'Scegli se i marcatori intro giocano normalmente, mostrano un pulsante di salto o scappano automaticamente.',
			'settings.skipCreditsModeDescription' => 'Selezionare se i crediti giocano normalmente, mostrare un pulsante di salto o saltare automaticamente.',
			'settings.skipAdsModeDescription' => 'Scegli se gli annunci rilevati si svolgono normalmente, visualizzano un pulsante di salto o scappano automaticamente.',
			'settings.playbackBufferAutoDescription' => 'Lascia che il giocatore attivo sceglie la sua dimensione normale del buffer.',
			'settings.playbackBufferLargeDescription' => 'Mantenere più media pronti prima della riproduzione; questo utilizza più memoria.',
			'settings.playbackBufferExtraLargeDescription' => 'Mantenere il più grande buffer di lettura; questo utilizza la maggior parte della memoria.',
			'settings.defaultQualityDescription' => 'Configurare la risoluzione video predefinita e il tetto bitrate per i flussi che il server trascoda.',
			'settings.cellularQualityDescription' => 'Superare la qualità predefinita quando il dispositivo utilizza una connessione solo cellulare.',
			'settings.remoteQualityDescription' => 'Superare la qualità predefinita quando si connette a un server tramite una connessione remota.',
			'settings.qualityPresetOriginalDescription' => 'Gioca la fonte alla sua qualità disponibile senza chiedere al server di trascodirla.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Chiedi al server un flusso convertito utilizzando la risoluzione e il bitrate mostrato sopra.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Utilizzare la qualità selezionata in Qualità predefinita.',
			'settings.musicQualityDescription' => 'Imposta la bitrate audio massima richiesta dal server; originale mantiene il flusso di sorgente.',
			'settings.musicQualityOriginalDescription' => 'Gioca l\'audio sorgente senza un transcode cappato a bitrate.',
			'settings.musicQualityTranscodeOptionDescription' => 'Richiedi un codice trans server capped vicino alla bitrate mostrata sopra; la produzione effettiva può variare.',
			'settings.maxVolumeInputLabel' => 'Il volume massimo (%)',
			'settings.checkForUpdatesDescription' => 'Scopri ora se è disponibile una versione più recente di PlezyNG.',
			'settings.appearanceDescription' => 'Selezionare il tema dell\'app e personalizzare le schede della biblioteca, le righe di casa e la navigazione.',
			'settings.prerollLibraryDescription' => 'Scegli la libreria che contiene i clip disponibili come pre-roll di film.',
			'settings.prerollSelectionDescription' => 'Scegli i clip dalla biblioteca selezionata che puoi giocare prima dei film.',
			'settings.contentScreensaverDelayOptionDescription' => 'Aspettate questi molti minuti senza input prima di mostrare screensaver artwork.',
			'settings.videoCodecOptionDescription' => 'Permettere la riproduzione diretta di questo codec quando supportato. i codec non controllati sono trascoditi dal server dei media.',
			'themeEditor.builtIn' => 'Integrati',
			'themeEditor.presets' => 'Preimpostati',
			'themeEditor.custom' => 'Personalizzato',
			'themeEditor.customEmpty' => 'Non ancora creato',
			'themeEditor.editCustom' => 'Modifica tema personalizzato',
			'themeEditor.editCustomDescription' => 'Scegli tu ogni colore',
			'themeEditor.locked' => 'L’accesso a vita richiesto',
			'themeEditor.savedLocked' => 'Salvataggio - disponibile con accesso a vita',
			'themeEditor.title' => 'Tema personalizzato',
			'themeEditor.startFrom' => 'Parti da',
			'themeEditor.startFromDescription' => 'Copia tutti i colori da un altro tema',
			'themeEditor.colors' => 'Colori',
			'themeEditor.preview' => 'Anteprima',
			'themeEditor.slots.bg' => 'Sfondo',
			'themeEditor.slots.surface' => 'Superficie',
			'themeEditor.slots.outline' => 'Contorno',
			'themeEditor.slots.text' => 'Testo',
			'themeEditor.slots.textMuted' => 'Testo secondario',
			'themeEditor.slots.accent' => 'Accento',
			'themeEditor.opacity' => 'Opacità',
			'themeEditor.hexHint' => '#RRGGBB o #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Da altri temi',
			'themeEditor.swatchLabel' => ({required Object color, required Object theme}) => '${color} ${theme}',
			'themeEditor.contrast.textOnBg' => 'Testo sullo sfondo',
			'themeEditor.contrast.textOnSurface' => 'Testo sulla superficie',
			'themeEditor.contrast.textMutedOnBg' => 'Testo secondario sullo sfondo',
			'themeEditor.contrast.textMutedOnSurface' => 'Testo secondario sulla superficie',
			'themeEditor.contrast.accentOnBg' => 'Accento sullo sfondo',
			'themeEditor.contrast.accentOnSurface' => 'Accento sulla superficie',
			'themeEditor.contrast.labelOnAccent' => 'Etichetta dei pulsanti sull\'accento',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, sotto il valore consigliato di ${minimum}:1',
			'themeEditor.discardTitle' => 'Scartare le modifiche?',
			'themeEditor.discardMessage' => 'Le modifiche ai colori non salvate andranno perse.',
			'themeEditor.discard' => 'Scarta',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Episodio ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} min rimanenti',
			'themeEditor.previewSwitch' => 'Riproduzione automatica',
			'themeEditor.previewMutedText' => 'Così appare il testo secondario',
			'themeEditor.themeSystemDescription' => 'Seguire l\'aspetto del dispositivo e scorrere tra luce e buio automaticamente.',
			'themeEditor.themeLightDescription' => 'Utilizzare un background luminoso con testo scuro.',
			'themeEditor.themeDarkDescription' => 'Utilizzare un background scuro con testo leggero.',
			'themeEditor.themeOledDescription' => 'Utilizzare superfici di colore nero che riducono la luce su schermi OLED.',
			'themeEditor.themeEmberDescription' => 'Utilizzare colori di accento rosso e amber.',
			'themeEditor.themeGlacierDescription' => 'Utilizzare colori accenti blu freddi.',
			'themeEditor.themeForestDescription' => 'Utilizzare i colori di accento verde e naturale.',
			'themeEditor.themePlumDescription' => 'Utilizzare i colori di accento violetto e plum.',
			'themeEditor.themePaperDescription' => 'Utilizzare superfici calde come carta e colori ispirati all\'ingrosso.',
			'themeEditor.themeCustomDescription' => 'Utilizzare la paletta dei colori che hai creato nell\'editor di tema personalizzato.',
			'themeEditor.editorDescription' => 'Scegli un colore di palette, regolare la sua tonalità, saturazione, luminosità o opacità e vedere l\'aggiornamento preview prima di risparmiare.',
			'search.hint' => 'Cerca film, serie TV e musica...',
			'search.tryDifferentTerm' => 'Prova altri termini di ricerca',
			'search.searchYourMedia' => 'Cerca nei tuoi media',
			'search.enterTitleActorOrKeyword' => 'Inserisci un titolo, attore o parola chiave',
			'search.people' => 'Persone',
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
			'hotkeys.actions.subtitleDelayIncrease' => 'Ritarda sottotitoli',
			'hotkeys.actions.subtitleDelayDecrease' => 'Anticipa sottotitoli',
			'hotkeys.actions.shaderToggle' => 'Attiva/disattiva shader',
			'hotkeys.actions.skipMarker' => 'Salta intro/titoli di coda',
			'hotkeys.actions.screenshot' => 'Cattura schermata',
			'hotkeys.actions.framePrevious' => 'Precedente Frame',
			'hotkeys.actions.frameNext' => 'Prossimo Frame',
			'fileInfo.title' => 'Info sul file',
			'fileInfo.overview' => 'Panoramica',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Sottotitoli',
			'fileInfo.images' => 'Immagini incorporate',
			'fileInfo.dataStreams' => 'Flussi di dati',
			'fileInfo.lyrics' => 'Testi',
			'fileInfo.file' => 'File',
			'fileInfo.attachments' => 'Allegati',
			'fileInfo.delivery' => 'Distribuzione',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versione ${index} di ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'File ${index} di ${count}',
			'fileInfo.noStreams' => 'Il server non ha segnalato flussi per questo file.',
			'fileInfo.copyPath' => 'Copia percorso',
			'fileInfo.pathCopied' => 'Percorso del file copiato',
			'fileInfo.codec' => 'Codec',
			'fileInfo.codecTag' => 'Tag codec',
			'fileInfo.resolution' => 'Risoluzione',
			'fileInfo.codedResolution' => 'Risoluzione codificata',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Frequenza fotogrammi',
			'fileInfo.rotation' => 'Rotazione',
			'fileInfo.comment' => 'Commento',
			'fileInfo.audioDescription' => 'Descrizione audio',
			'fileInfo.headerCompression' => 'Compressione header',
			'fileInfo.sidecarFile' => 'File sidecar',
			'fileInfo.transportTimestamp' => 'Timestamp di trasporto',
			'fileInfo.displayOffset' => 'Offset di visualizzazione',
			'fileInfo.previewFailureCode' => 'Codice errore anteprima',
			'fileInfo.previewRetries' => 'Riprova anteprima',
			'fileInfo.aspectRatio' => 'Proporzioni',
			'fileInfo.pixelAspectRatio' => 'Aspect ratio pixel',
			'fileInfo.profile' => 'Profilo',
			'fileInfo.level' => 'Livello',
			'fileInfo.bitDepth' => 'Profondità in bit',
			'fileInfo.pixelFormat' => 'Formato pixel',
			'fileInfo.colorSpace' => 'Spazio colore',
			'fileInfo.colorRange' => 'Gamma colori',
			'fileInfo.colorPrimaries' => 'Colori primari',
			'fileInfo.colorTransfer' => 'Trasferimento colore',
			'fileInfo.chromaSubsampling' => 'Sottocampionamento cromatico',
			'fileInfo.chromaLocation' => 'Posizione crominanza',
			'fileInfo.scanType' => 'Tipo di scansione',
			'fileInfo.interlaced' => 'Interlacciato',
			'fileInfo.anamorphic' => 'Anamorfico',
			'fileInfo.referenceFrames' => 'Frame di riferimento',
			'fileInfo.dynamicRange' => 'Gamma dinamica',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Livello Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Versione Dolby Vision',
			'fileInfo.dolbyVisionLayers' => 'Layer Dolby Vision',
			'fileInfo.baseLayerCompatibility' => 'Compatibilità layer di base',
			'fileInfo.avcBitstream' => 'Bitstream AVC',
			'fileInfo.nalLengthSize' => 'Dimensione lunghezza NAL',
			'fileInfo.scalingMatrix' => 'Matrice di scaling personalizzata',
			'fileInfo.streamIdentifier' => 'Identificatore flusso',
			'fileInfo.streamIndex' => 'Indice flusso',
			'fileInfo.streamId' => 'ID flusso',
			'fileInfo.language' => 'Lingua',
			'fileInfo.languageCode' => 'Codice lingua',
			'fileInfo.streamTitle' => 'Titolo traccia',
			'fileInfo.channels' => 'Canali',
			'fileInfo.sampleRate' => 'Frequenza di campionamento',
			'fileInfo.spatialAudio' => 'Audio spaziale',
			'fileInfo.textBased' => 'Testuale',
			'fileInfo.subtitleFormat' => 'Formato sidecar',
			'fileInfo.provider' => 'Provider',
			'fileInfo.matchScore' => 'Punteggio corrispondenza',
			'fileInfo.externalDelivery' => 'Può essere servito separatamente',
			'fileInfo.sidecarPath' => 'Percorso sidecar',
			'fileInfo.sourceStream' => 'Copiato da',
			'fileInfo.temporary' => 'Temporaneo',
			'fileInfo.timeBase' => 'Base temporale',
			'fileInfo.overallBitrate' => 'Bitrate complessivo',
			'fileInfo.path' => 'Percorso',
			'fileInfo.fileName' => 'Nome file',
			'fileInfo.size' => 'Dimensione',
			'fileInfo.totalSize' => 'Dimensione totale',
			'fileInfo.container' => 'Contenitore',
			'fileInfo.duration' => 'Durata',
			'fileInfo.previewThumbnails' => 'Miniature anteprima',
			'fileInfo.previewIndex' => 'Indice anteprima',
			'fileInfo.packetLength' => 'Lunghezza pacchetto',
			'fileInfo.filePresent' => 'File presente',
			'fileInfo.fileReadable' => 'Leggibile dal server',
			'fileInfo.streamPath' => 'Percorso flusso',
			'fileInfo.optimizedForStreaming' => 'Ottimizzato per lo streaming',
			'fileInfo.has64bitOffsets' => 'Offset a 64 bit',
			'fileInfo.protocol' => 'Protocollo',
			'fileInfo.mediaType' => 'Tipo di supporto',
			'fileInfo.sourceKind' => 'Tipo di origine',
			'fileInfo.optimizedVersion' => 'Versione ottimizzata',
			'fileInfo.optimizationTarget' => 'Obiettivo ottimizzazione',
			'fileInfo.deletedAt' => 'Eliminato',
			'fileInfo.remoteSource' => 'Origine remota',
			'fileInfo.infiniteStream' => 'Flusso infinito',
			'fileInfo.directPlay' => 'Riproduzione diretta',
			'fileInfo.directStream' => 'Streaming diretto',
			'fileInfo.transcoding' => 'Transcodifica',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID versione',
			'fileInfo.fileId' => 'ID file',
			'fileInfo.defaultAudioTrack' => 'Traccia audio predefinita',
			'fileInfo.defaultSubtitleTrack' => 'Traccia sottotitoli predefinita',
			'fileInfo.subtitlesOff' => 'Disattivati',
			'fileInfo.flagDefault' => 'Predefinito',
			'fileInfo.flagForced' => 'Forzato',
			'fileInfo.flagSelected' => 'Selezionato',
			'fileInfo.flagExternal' => 'Esterno',
			'fileInfo.flagHearingImpaired' => 'Non udenti',
			'fileInfo.flagDub' => 'Doppiato',
			'fileInfo.flagOriginal' => 'Originale',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profilo ${profile}',
			'mediaMenu.markAsWatched' => 'Segna come visto',
			'mediaMenu.markAsUnwatched' => 'Segna come non visto',
			'mediaMenu.removeFromContinueWatching' => 'Rimuovi da Continua a guardare',
			'mediaMenu.viewDetails' => 'Visualizza dettagli',
			'mediaMenu.goToSeries' => 'Vai alla serie',
			'mediaMenu.shufflePlay' => 'Riproduzione casuale',
			'mediaMenu.shuffleNotAvailableOffline' => 'Riproduzione casuale non disponibile offline',
			'mediaMenu.fileInfo' => 'Info sul file',
			'mediaMenu.deleteEpisodeFromServer' => 'Elimina episodio dal server',
			'mediaMenu.deleteSeasonFromServer' => 'Elimina stagione dal server',
			'mediaMenu.deleteShowFromServer' => 'Elimina serie dal server',
			'mediaMenu.deleteMovieFromServer' => 'Elimina film dal server',
			'mediaMenu.deleteEpisodeTitle' => 'Eliminare questo episodio?',
			'mediaMenu.deleteSeasonTitle' => 'Eliminare questa stagione?',
			'mediaMenu.deleteShowTitle' => 'Eliminare questa serie?',
			'mediaMenu.deleteMovieTitle' => 'Eliminare questo film?',
			'mediaMenu.deleteEpisodeConfirm' => 'Elimina episodio',
			'mediaMenu.deleteSeasonConfirm' => 'Elimina stagione',
			'mediaMenu.deleteShowConfirm' => 'Elimina serie',
			'mediaMenu.deleteMovieConfirm' => 'Elimina film',
			'mediaMenu.deleteAnyway' => 'Elimina comunque',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Eliminare definitivamente ${title} dal tuo server?',
			'mediaMenu.deleteMultipleWarning' => 'Sono inclusi tutti gli episodi e i relativi file.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Questo elimina il ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio in essa contenuto e il relativo file.', other: 'Questo elimina tutti i ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodi in essa contenuti e i relativi file.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Questo elemento è archiviato in ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} file, che verrà eliminato.', other: 'Questo elemento è archiviato in ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} file, e tutti verranno eliminati.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} altro episodio è archiviato nello stesso file e verrà eliminato anche lui:', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} altri episodi sono archiviati nello stesso file e verranno eliminati anche loro:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG non ha potuto verificare quali file rimuoverà, quindi potrebbe eliminare più di quanto indicato sopra. Annulla e riprova, oppure elimina comunque.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Il tuo server non ha fornito i dettagli del file per questo elemento, quindi PlezyNG non può verificare quali file rimuoverà. Potrebbe eliminare più di quanto indicato sopra.',
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
			'accessibility.autoScrollPlay' => 'Avvia scorrimento automatico',
			'accessibility.autoScrollPause' => 'Sospendi scorrimento automatico',
			'accessibility.hueShort' => 'T',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Il rosso',
			'accessibility.green' => 'verde',
			'accessibility.blue' => 'blu',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'Il HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'accessibilità',
			'accessibility.summary' => 'testo, contrasto, movimento e controlli',
			'accessibility.systemHint' => 'Le impostazioni di accessibilità del dispositivo si applicano sempre.Queste opzioni aggiungono ajustamenti nel corso di PlezyNG.',
			'accessibility.readability' => 'Leggi e visibilità',
			'accessibility.textSize' => 'Dimensioni aggiuntive del testo',
			'accessibility.preview' => 'Leggi, ascolta e guarda al tuo ritmo.',
			'accessibility.boldText' => 'Interfaccia testo',
			'accessibility.highContrast' => 'Il contrasto elevato',
			'accessibility.highContrastHint' => 'Testo più forte, indicatori di rilievo e di focalizzazione sulle superfici luminose o scuri.',
			'accessibility.interaction' => 'Movimento e interazione',
			'accessibility.reduceMotion' => 'Ridurre il movimento',
			'accessibility.reduceMotionHint' => 'Fermare le animazioni dell’indicatore di focus, le transizioni delle pagine e gli effetti decorativi.',
			'accessibility.largeTargets' => 'obiettivi touch più grandi',
			'accessibility.largeTargetsHint' => 'Gioca i controlli condivisi più spazio per la navigazione a touch e assistive.',
			'accessibility.navigationHint' => 'Usa Tab e Shift+Tab per spostarti tra i controlli, Enter o la barra spaziatrice per attivarli ed Escape o Indietro per chiudere. Quando un libro è aperto, puoi regolare lo zoom e le preferenze di lettura.',
			'accessibility.textSizeDescription' => 'Scala il testo dell\'interfaccia in PlezyNG oltre alla configurazione di dimensioni del testo del sistema del dispositivo.',
			'accessibility.boldTextHint' => 'Utilizzare un peso più pesante per le etichette e i messaggi di interfaccia per renderli più facili da distinguere.',
			'tooltips.shufflePlay' => 'Riproduzione casuale',
			'tooltips.playTrailer' => 'Riproduci trailer',
			'tooltips.markAsWatched' => 'Segna come visto',
			'tooltips.markAsUnwatched' => 'Segna come non visto',
			'audioTracks.track' => ({required Object n}) => 'Traccia audio ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Sottotitoli',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
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
			'videoControls.playbackPaused' => 'In pausa',
			'videoControls.playbackResumed' => 'Riproduzione',
			'videoControls.loadingVideo' => 'Caricamento video',
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
			'videoControls.segmentLoopHelp' => 'Scorrere una sezione durante questa riproduzione. impostare A, quindi impostate B in seguito nella linea di tempo.',
			'videoControls.setLoopStart' => 'Set loop inizio (A)',
			'videoControls.setLoopEnd' => 'Set loop fine (B)',
			'videoControls.clearSegmentLoop' => 'Il segmento chiaro',
			'videoControls.setLoopStartFirst' => 'Set loop inizio (A) prima della fine (B).',
			'videoControls.loopEndAfterStart' => 'La fine del loop deve essere più tardi dell\'inizio.',
			'videoControls.segmentLoopUnavailable' => 'Il segmento looping non è disponibile per questo playback.',
			'videoControls.loopPointNotSet' => 'Non impostare',
			'videoControls.bookmarksHelp' => 'I biglietti sono salvati su questo dispositivo. selezionare uno per andare a quel momento.',
			'videoControls.bookmarksButton' => 'Il libromarchio',
			'videoControls.chaptersAndBookmarks' => 'Capitoli e bookmark',
			'videoControls.segmentLoop' => 'Segmento Loop',
			'videoControls.addBookmark' => 'Aggiungi Bookmark',
			'videoControls.bookmarkName' => 'Nome di Bookmark',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'Ad esempio, la scena di apertura',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Il Bookmark ${n}',
			'videoControls.bookmarkNameRequired' => 'Inserisci un nome per questo bookmark.',
			'videoControls.deleteBookmark' => 'Rimuovere il bookmark',
			'videoControls.bookmarkLimitReached' => 'Questo articolo ha già 100 bookmark.',
			'videoControls.bookmarkUnavailable' => 'Non potevo salvare o rimuovere questo bookmark.',
			'videoControls.bookmarkSaved' => 'Il Bookmark è stato salvato.',
			'videoControls.bookmarkDeleted' => 'Il Bookmark è cancellato.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Il punto Loop ${point} Set a ${time}e il',
			'videoControls.noChaptersOrBookmarks' => 'Nessun capitolo o carattere disponibile.',
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
			'videoControls.timelineSlider' => 'Timeline video',
			'videoControls.volumeSlider' => 'Livello volume',
			'videoControls.endsAt' => ({required Object time}) => 'Termina alle ${time}',
			'videoControls.pipActive' => 'Riproduzione in Picture-in-Picture',
			'videoControls.pipFailed' => 'Impossibile avviare la modalità Picture-in-Picture',
			'videoControls.screenshotSaved' => 'Schermata salvata',
			'videoControls.screenshotFailed' => 'Impossibile catturare la schermata',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volume ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Richiede Android 8.0 o versioni successive',
			'videoControls.pipErrors.iosVersion' => 'Richiede iOS 15.0 o versioni successive',
			'videoControls.pipErrors.permissionDisabled' => 'La modalità Picture-in-Picture è disattivata. Attivala nelle impostazioni di sistema.',
			'videoControls.pipErrors.notSupported' => 'Questo dispositivo non supporta la modalità Picture-in-Picture',
			'videoControls.pipErrors.voSwitchFailed' => 'Impossibile cambiare l\'uscita video per Picture-in-Picture',
			'videoControls.pipErrors.failed' => 'Impossibile avviare la modalità Picture-in-Picture',
			'videoControls.pipErrors.prepareFailed' => 'Impossibile preparare la modalità Picture-in-Picture',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Si è verificato un errore: ${error}',
			'videoControls.chapters' => 'Capitoli',
			'videoControls.noChaptersAvailable' => 'Nessun capitolo disponibile',
			'videoControls.queue' => 'Coda',
			'videoControls.noQueueItems' => 'Nessun elemento in coda',
			'videoControls.noAudioDevicesAvailable' => 'Nessun dispositivo audio disponibile',
			'videoControls.searchSubtitles' => 'Cerca sottotitoli',
			'videoControls.language' => 'Lingua',
			'videoControls.noSubtitlesFound' => 'Nessun sottotitolo trovato',
			'videoControls.subtitleDownloaded' => 'Sottotitolo scaricato',
			'videoControls.subtitleDownloadedNotApplied' => 'Il sottotitolo è stato scaricato, ma non è stato possibile selezionarlo',
			'videoControls.subtitleDownloadFailed' => 'Impossibile scaricare il sottotitolo',
			'videoControls.searchLanguages' => 'Cerca lingue...',
			'videoControls.skipIntro' => 'Salta intro',
			'videoControls.skipCredits' => 'Salta titoli',
			'videoControls.nextEpisode' => 'Episodio successivo',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Traccia ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Sottotitolo ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Forzato)',
			'videoControls.osdSubtitlesOff' => 'Sottotitoli: Disattivati',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Sottotitoli: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} strati', ), 
			'videoControls.trackSelectionTitle' => 'Scegliere le tracce prima del playback',
			'videoControls.trackSelectionAuto' => 'Selezione automatica',
			'videoControls.openMiniPlayer' => 'Mini giocatore aperto',
			'videoControls.returnToFullPlayer' => 'Il ritorno al giocatore completo',
			'videoControls.loadSubtitleFile' => 'Il file subtitle è ...',
			'videoControls.subtitleLoadFailed' => 'Non è stato possibile caricare il file subtitle',
			'videoControls.skipAds' => 'Scopri gli annunci',
			'videoControls.tapToUnlock' => 'Tocca per sbloccare',
			'videoControls.tapAgainToUnlock' => 'Tocca di nuovo per sbloccare',
			'messages.markedAsWatched' => 'Segnato come visto',
			'messages.markedAsUnwatched' => 'Segnato come non visto',
			'messages.markedAsWatchedOffline' => 'Segnato come visto (verrà sincronizzato quando torni online)',
			'messages.markedAsUnwatchedOffline' => 'Segnato come non visto (verrà sincronizzato quando torni online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Rimosso automaticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Rimosso automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download già visto', other: 'Rimossi automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download già visti', ), 
			'messages.removedFromContinueWatching' => 'Rimosso da Continua a guardare',
			'messages.errorLoading' => ({required Object error}) => 'Errore: ${error}',
			'messages.searchPartialResults' => 'Non è stato possibile cercare in alcuni server multimediali. Vengono mostrati i risultati disponibili.',
			'messages.streamInterrupted' => 'La riproduzione si è interrotta. Premi Riproduci o vai a un altro punto per riprovare.',
			'messages.liveStreamInterrupted' => 'La diretta si è interrotta. Premi Riproduci per riprovare.',
			'messages.fileInfoNotAvailable' => 'Informazioni sul file non disponibili',
			'messages.playbackAuthenticationRequired' => 'Accedi di nuovo al server multimediale per riprodurre questo elemento.',
			'messages.playbackServerUnavailable' => 'Il server multimediale non è disponibile. Riprova più tardi.',
			'messages.playbackDataInvalid' => 'Il server ha restituito informazioni di riproduzione non valide.',
			'messages.playbackCancelled' => 'Riproduzione annullata.',
			'messages.playbackFailed' => 'Impossibile avviare la riproduzione.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Impossibile avviare la riproduzione: ${error}',
			'messages.audioOutputFailed' => 'L\'uscita audio ha smesso di rispondere. Controlla la connessione audio del televisore o del ricevitore; se anche le altre app non hanno audio, riavvia il dispositivo.',
			'messages.mediaUnavailable' => 'Questo contenuto non è più disponibile.',
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
			'messages.mediaUnreadableTitle' => 'File non disponibile',
			'messages.mediaUnreadableBody' => 'Il server ha trovato questo elemento ma non ha potuto leggere il suo file (HTTP 404). Il file è stato probabilmente spostato o eliminato, oppure il suo storage è offline. Chiedi al proprietario del server di controllare il file e di riscansionare la libreria.',
			'messages.serverBusyTitle' => 'Streaming non disponibile',
			'messages.serverBusyBody' => 'Il server ha continuato a rifiutare la riproduzione in streaming di questo file (HTTP 503). Potrebbe essere in fase di riavvio, occupato oppure l\'unità in cui si trova il file potrebbe essere offline. Riprova tra qualche istante. Se il problema persiste, chiedi al proprietario del server di controllare il server e l\'unità di archiviazione del file.',
			'messages.playbackNotAllowedTitle' => 'Riproduzione non consentita',
			'messages.playbackNotAllowedBody' => 'Il server ha rifiutato lo streaming di questo elemento (HTTP 403). Il tuo account potrebbe non avere l\'autorizzazione per riprodurlo, oppure il server potrebbe consentire la riproduzione solo sulla sua rete locale.',
			'messages.logsUploaded' => 'Log caricati',
			'messages.logsUploadFailed' => 'Impossibile caricare i log',
			'messages.logId' => 'ID log',
			'messages.burnedSubtitlesUseMenu' => 'I sottotitoli sono incorporati in questo stream. Cambiali dal menu dei sottotitoli.',
			'messages.noVideoUrl' => 'Nessun URL video disponibile',
			'messages.playbackNoMediaSources' => 'Il server non ha restituito sorgenti multimediali riproducibili',
			'messages.playbackDataNotPrepared' => 'La riproduzione è stata avviata prima che i relativi dati fossero pronti',
			'messages.streamSelectionUnavailable' => 'La selezione dei flussi non è disponibile per questa sorgente',
			'messages.streamSelectionFailed' => 'Impossibile applicare i flussi selezionati',
			'messages.trackSelectionNotRemembered' => 'Questa scelta di traccia vale solo per la riproduzione corrente.',
			'messages.serverUnavailableForProfile' => 'Nessun server disponibile per il profilo attivo',
			'subtitlingStyling.previewSample' => 'Il rapido fucile marrone salta sopra il cane lazo',
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
			'subtitlingStyling.useMargins' => 'Usa i margini',
			'subtitlingStyling.useMarginsDescription' => 'Consenti i sottotitoli testuali nello spazio esterno al video. I sottotitoli con stile possono mantenere la loro posizione originale.',
			'subtitlingStyling.anchorToScreen' => 'Fissa allo schermo',
			'subtitlingStyling.anchorToScreenDescription' => 'Mostra i sottotitoli testuali nelle bande nere sotto i video in formato panoramico',
			'subtitlingStyling.bold' => 'Grassetto',
			'subtitlingStyling.italic' => 'Corsivo',
			'subtitlingStyling.renderResolution' => 'Risoluzione di rendering',
			'subtitlingStyling.renderResolutionScreen' => 'Risoluzione dello schermo',
			'subtitlingStyling.renderResolutionVideo' => 'Risoluzione del video',
			'subtitlingStyling.fontSizeDescription' => 'Imposta la dimensione del testo di sottotitolo su questo dispositivo.',
			'subtitlingStyling.textColorDescription' => 'Selezionare il colore utilizzato per il testo sottotitolo.',
			'subtitlingStyling.borderSizeDescription' => 'Imposta la spessore dell\'outline intorno al testo sottotitolo.',
			'subtitlingStyling.borderColorDescription' => 'Scegliere il colore utilizzato per l\'outline del sottotitolo.',
			'subtitlingStyling.backgroundColorDescription' => 'Selezionare il colore dietro il testo sottotitolo.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Imposta quanto sia trasparente il background del sottotitolo: 0% è chiaro e 100% solido.',
			'subtitlingStyling.positionDescription' => 'Movi i sottotitoli verticalmente. 0% è la parte superiore del video e 100% è il fondo.',
			'subtitlingStyling.assOverrideDescription' => 'Scegli se il giocatore segue, adatta, sostituisce o rimuove lo stile inserito nei sottotitoli ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Mantenere le lettere, i colori, le dimensioni e la posizione scritte nel file sottotitolo.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Permettere che le impostazioni di stile del sottotitolo del giocatore adattino i sottotitoli ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Applicare lo stile del giocatore e scalare le dimensioni incorporate per corrispondere alle dimensioni video.',
			'subtitlingStyling.assOverrideOptions.force' => 'Sostituisci gli stili ASS incorporati con lo stile di sottotitolo del giocatore.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Rimuovere il formato ASS incorporato e rendere chiaro il testo sottotitolo.',
			'subtitlingStyling.renderResolutionDescription' => 'Scegli la risoluzione utilizzata per rasterizzare l\'immagine e i sottotitoli ASS. Le scale Android inferiori possono ridurre il lavoro di rendering ma sembrano più sottili.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render alla piena risoluzione della superficie dello schermo per il risultato più acuto.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render utilizzando la risoluzione video come riferimento, che può ridurre il lavoro su display ad alta risoluzione.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render al 75% della risoluzione superficiale dello schermo per un modesto risparmio di prestazioni.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render al 50% della risoluzione superficiale dello schermo per ridurre il lavoro, con margini più sottili.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render a un terzo della risoluzione superficiale dello schermo per ridurre il lavoro, con margini più sottili.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render a un quarto della risoluzione superficie dello schermo per ridurre il lavoro, con il risultato più morbido.',
			'subtitlingStyling.boldDescription' => 'Tracciare il sottotitolo in un peso più pesante.',
			'subtitlingStyling.italicDescription' => 'Tracciare il sottotitolo in italiano.',
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
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Aggiungi riga',
			'mpvConfig.removeLine' => 'Rimuovi riga',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context e gpu-api vengono ignorati su Linux: il video incorporato viene sempre renderizzato tramite vo=libmpv sul piano video e gpu-next (che gli shader di calcolo come ArtCNN richiedono) non può essere eseguito in modalità incorporata.',
			'dialog.confirmAction' => 'Conferma azione',
			'profiles.addPlezyProfile' => 'Aggiungi profilo PlezyNG',
			'profiles.switchingProfile' => 'Cambio profilo…',
			'profiles.deleteThisProfileTitle' => 'Eliminare questo profilo?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Rimuovi ${displayName}. Le connessioni resteranno invariate.',
			'profiles.active' => 'Attivo',
			'profiles.manage' => 'Gestisci',
			'profiles.delete' => 'Elimina',
			'profiles.signOut' => 'Esci',
			'profiles.signOutPlexTitle' => 'Uscire da Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Verranno rimossi ${displayName} e tutti gli utenti Plex Home. Potrai accedere di nuovo in qualsiasi momento.',
			'profiles.signOutPlexDeleteDownloads' => 'Elimina anche i download',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Altrimenti restano su questo dispositivo e tornano disponibili quando accedi di nuovo a questo account.',
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
			'profiles.copyAutomationLink' => 'Copia il link di automatizzazione Android',
			'profiles.copyAutomationLinkDescription' => 'Selezionare questo profilo da un\'intenzione o automatizzazione Android.',
			'profiles.automationLinkCopied' => 'Il link di automatizzazione del profilo è copiato.',
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
			'profiles.plexAccountChip' => ({required Object account}) => 'Account Plex: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} tramite ${account}',
			'profiles.connectionDefault' => 'Predefinita',
			'profiles.connectionAs' => ({required Object displayName}) => 'come ${displayName}',
			'profiles.makeDefault' => 'Imposta come predefinita',
			'profiles.removeConnection' => 'Rimuovi',
			'profiles.profileRenamed' => 'Profilo rinominato.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Aggiungi a ${displayName}',
			'profiles.borrowExplain' => 'Prendi in prestito la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.',
			'profiles.borrowEmpty' => 'Nulla da prendere in prestito al momento.',
			'profiles.borrowEmptySubtitle' => 'Collega prima Plex, Jellyfin o Emby a un altro profilo.',
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
			'profiles.tokenIdentityMismatch' => 'Il token del profilo Plex è stato associato a un server imprevisto',
			'profiles.settingsLocked' => 'Le impostazioni sono bloccate per questo profilo.',
			'profiles.unlockSettings' => 'Sviluppo di disattivazione',
			'profiles.showExploreForProfile' => 'Mostra Scopri per questo profilo',
			'profiles.showExploreForProfileDescription' => 'Aprire per rimuovere Explore dalla navigazione di questo profilo.',
			'connections.sectionTitle' => 'Connessioni',
			'connections.addConnection' => 'Aggiungi connessione',
			'connections.addConnectionSubtitleNoProfile' => 'Accedi con Plex o collega un server Jellyfin o Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Aggiungi a ${displayName}: Plex, Jellyfin, Emby o la connessione di un altro profilo',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessione scaduta per ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessione scaduta per ${count} server',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} ha negato l\'accesso a questo account',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} server hanno negato l\'accesso a questo account',
			'connections.signInAgain' => 'Accedi di nuovo',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Modifica connessione ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Aggiungi o rimuovi gli URL per ${serverName}. PlezyNG userà l\'URL raggiungibile con la latenza più bassa.',
			'accountPreferences.sectionTitle' => 'Preferenze dell\'account',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Opzioni di audio, sottotitoli e libreria salvate su ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Opzioni di audio, sottotitoli e libreria salvate su ${count} account',
			'accountPreferences.pickAccount' => 'Ogni account conserva le proprie preferenze. Scegli quale modificare.',
			'accountPreferences.storedOnAccount' => 'Queste opzioni vengono salvate sull\'account stesso, quindi ogni app che vi accede le usa — inclusa PlezyNG sugli altri tuoi dispositivi.',
			'accountPreferences.noAccounts' => 'Nessun account da configurare',
			'accountPreferences.noAccountsHint' => 'Accedi a Plex oppure connetti un server Jellyfin o Emby: le preferenze salvate su quell\'account appariranno qui.',
			'accountPreferences.unavailable' => 'Impossibile raggiungere questo account',
			'accountPreferences.loadFailed' => 'Impossibile caricare queste preferenze',
			'accountPreferences.noPreference' => 'Nessuna preferenza',
			'accountPreferences.notSet' => 'Non impostato',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio e sottotitoli',
			'accountPreferences.groups.libraryDisplay' => 'Libreria',
			'accountPreferences.groups.personalMedia' => 'Media personali',
			'accountPreferences.preferredAudioLanguage' => 'Lingua audio preferita',
			'accountPreferences.autoSelectAudio' => 'Scegli l\'audio in base alla lingua',
			'accountPreferences.autoSelectAudioDescription' => 'Se disattivata, viene mantenuta la traccia audio che il file indica come predefinita.',
			'accountPreferences.preferredSubtitleLanguage' => 'Lingua dei sottotitoli preferita',
			'accountPreferences.subtitleMode' => 'Attiva i sottotitoli',
			'accountPreferences.subtitleModes.none' => 'Selezionati manualmente',
			'accountPreferences.subtitleModes.noneDescription' => 'Non attivare mai i sottotitoli automaticamente.',
			'accountPreferences.subtitleModes.defaultMode' => 'Segui le flag della traccia',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Usa le flag predefinite e forzate salvate su ogni traccia di sottotitoli.',
			'accountPreferences.subtitleModes.always' => 'Sempre attivi',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Attiva una traccia di sottotitoli nella lingua preferita quando disponibile.',
			'accountPreferences.subtitleModes.onlyForced' => 'Solo sottotitoli forzati',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Carica solo le tracce contrassegnate come forzate.',
			'accountPreferences.subtitleModes.smart' => 'Mostrati con audio straniero',
			'accountPreferences.subtitleModes.smartDescription' => 'Attiva i sottotitoli solo quando l\'audio è in un\'altra lingua.',
			'accountPreferences.subtitleAccessibility' => 'Sottotitoli SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Preferisci i sottotitoli non SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Preferisci i sottotitoli SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Solo sottotitoli SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Solo sottotitoli non SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Preferisce i sottotitoli standard quando sono disponibili sia le versioni standard che SDH.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Preferisce i sottotitoli SDH quando disponibili, ma consente sottotitole standard come un fallback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Utilizzare solo i sottotitoli SDH; non cadere indietro ai subtitoli standard.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Utilizzare solo i sottotitoli standard; escludere i sottotiti SDH.',
			'accountPreferences.forcedSubtitles' => 'Sottotitoli forzati',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Preferisci i sottotitoli non forzati',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Preferisci i sottotitoli forzati',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Solo sottotitoli forzati',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Solo sottotitoli non forzati',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Preferisce sottotitoli regolari, ma consente tracce forzate come una caduta.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Preferisce tracce forzate quando disponibili, ma consente sottotitoli regolari come ritorno.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Utilizzare solo tracce segnalate come forzate.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Escluse le tracce segnalate come forzate.',
			'accountPreferences.displayMissingEpisodes' => 'Mostra gli episodi mancanti',
			'accountPreferences.displayMissingEpisodesDescription' => 'Elenca gli episodi noti al server ma senza un file associato.',
			'accountPreferences.hidePlayedInLatest' => 'Nascondi gli elementi visti da Aggiunti di recente',
			'accountPreferences.hidePlayedInLatestDescription' => 'Esclude dagli Aggiunti di recente del server gli elementi che hai già visto.',
			'accountPreferences.displayCollectionsView' => 'Mostra la vista Raccolte',
			'accountPreferences.displayCollectionsViewDescription' => 'Mostra la vista Raccolte del server insieme alle tue librerie.',
			'accountPreferences.rewatchingInNextUp' => 'Mantieni le serie riviste in Prossimi episodi',
			'accountPreferences.rewatchingInNextUpDescription' => 'Quando finisci una serie e la ricominci, Prossimi episodi segue la nuova visione invece di rimuovere la serie.',
			'accountPreferences.watchedIndicator' => 'Indicatori di visione',
			'accountPreferences.watchedIndicatorOptions.none' => 'Mai',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Film e serie TV',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Solo film',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Solo serie TV',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Non mostrare segni di controllo osservati.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Mostra segnalazioni guardate per film e spettacoli televisivi.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Mostra segnalazioni visualizzate solo per i film.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Mostra segnalazioni guardate solo per i programmi televisivi.',
			'accountPreferences.mediaReviewsVisibility' => 'Valutazioni e recensioni',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Utenti e critici',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Solo utenti',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Solo critici',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Nascoste',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Visualizza entrambe le valutazioni degli utenti e le valutazione critica.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Mostra le valutazioni e le recensioni presentate dagli utenti.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Mostra valutazioni critiche e recensioni.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Scopri le valutazioni e le recensioni.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Preferisce le tracce audio in questo linguaggio quando il server o giocatore seleziona automaticamente una traccia.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Preferisci le tracce di sottotitoli in questo linguaggio quando i subtitoli sono selezionati automaticamente.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Selezionare se le capzioni SDH sono preferite o richieste durante la selezione automatica dei sottotitoli.',
			'accountPreferences.forcedSubtitleDescription' => 'Scegli se le tracce di sottotitoli forzati sono preferite o richieste durante la selezione automatica.',
			'accountPreferences.watchedIndicatorDescription' => 'Selezionare quali tipi di media ricevono un checkmark osservato nell\'interfaccia del server.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Scegliere quale pubblico e quali valutazioni critiche il server mostra sulle pagine dei media.',
			'accountPreferences.subtitleModeDescription' => 'Selezionare quando i sottotitoli si attivano automaticamente per questo account server.',
			'accountPreferences.hubDescription' => 'Queste preferenze sono memorizzate sul tuo account media-server e possono applicarsi anche ad altri clienti.',
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
			'discover.findNext.title' => 'La tua prossima scoperta',
			'discover.findNext.open' => 'La tua prossima scoperta',
			'discover.findNext.anyTime' => 'Senza limiti di tempo',
			'discover.findNext.timeAvailable' => 'Quanto tempo hai?',
			'discover.findNext.filters' => 'Scegli per questo momento',
			'discover.findNext.watch' => 'Guarda',
			'discover.findNext.listen' => 'Ascolta',
			'discover.findNext.read' => 'Leggi',
			'discover.findNext.finishable' => ({required Object duration}) => 'Puoi finire in ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Circa ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Prossimo capitolo · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} in totale',
			'discover.findNext.timingVaries' => 'La durata può variare',
			'discover.findNext.notNow' => 'Non ora',
			'discover.findNext.swipeHint' => 'Scorri la copertina verso una freccia oppure usa i pulsanti qui sotto.',
			'discover.findNext.saved' => 'Suggerimenti salvati',
			'discover.findNext.savedCount' => ({required Object count}) => 'Suggerimenti salvati · ${count}',
			'discover.findNext.undo' => 'Annulla',
			'discover.findNext.details' => 'Dettagli',
			'discover.findNext.noPicks' => 'Non c’è ancora nulla da scegliere',
			'discover.findNext.noPicksHint' => 'Collega una libreria o aggiungi una fonte multimediale per iniziare.',
			'discover.findNext.noMatches' => 'Nulla di adatto a questo momento',
			'discover.findNext.noMatchesHint' => 'Prova un altro tipo di contenuto o concediti più tempo.',
			'discover.findNext.allDone' => 'Hai visto tutti i suggerimenti',
			'discover.findNext.allDoneHint' => 'Avvia una nuova selezione per rivedere queste proposte.',
			'discover.findNext.refresh' => 'Trova un’altra selezione',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Da ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Da ${library}',
			'discover.findNext.ownedReason' => 'Dalla tua libreria',
			'discover.findNext.liveNow' => 'In onda ora',
			'discover.findNext.watchLive' => 'Guarda in diretta',
			'discover.findNext.filterAnything' => 'Qualsiasi tipo',
			'discover.findNext.filterWatch' => 'Guarda',
			'discover.findNext.filterListen' => 'Ascolta',
			'discover.findNext.filterRead' => 'Leggi',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Applica',
			'discover.findNext.openFailed' => 'Questa scelta non è più disponibile. Aggiorna per verificare di nuovo.',
			'discover.findNext.changeFailed' => 'Impossibile salvare la modifica. Riprova.',
			'discover.findNext.savedLimit' => 'L’elenco dei suggerimenti salvati è pieno. Rimuovine uno per salvarne un altro.',
			'discover.findNext.chooseHint' => 'Apri un titolo, salvalo per dopo o passa al successivo.',
			'discover.findNext.howItWorks' => 'Come funziona',
			'discover.findNext.notNowHelp' => 'Salta questo titolo per ora. Rimane nella tua libreria.',
			'discover.findNext.saveHelp' => 'Conservalo tra le scelte salvate di questo profilo su questo dispositivo. Il salvataggio non lo scarica.',
			'discover.findNext.openHelp' => 'Seleziona la copertina per i dettagli. Usa l’azione principale per riprodurre, leggere o aprire il titolo.',
			'discover.findNext.controlsHelp' => 'Tastiera o telecomando: seleziona un pulsante, poi premi Invio o Seleziona. Annulla ripristina la tua ultima scelta.',
			'discover.findNext.artworkLoading' => 'Caricamento immagine…',
			'discover.findNext.artworkUnavailable' => 'Immagine non disponibile',
			'discover.findNext.savedFeedback' => 'Aggiunto alle scelte salvate',
			'discover.findNext.skippedFeedback' => 'Saltato per ora',
			'discover.findNext.releaseToConfirm' => 'Rilascia per confermare',
			'discover.findNext.remoteHint' => 'Copertina selezionata: ← / → scegli · Seleziona: dettagli · ↑ / ↓ sposta il focus',
			'discover.extras' => 'Trailer ed extra',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Valutazione',
			'discover.director' => 'Regista',
			'discover.directors' => 'Registi',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serie TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} minuti rimanenti',
			'discover.moreLikeThis' => 'Altri contenuti simili',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titolo', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titoli', ), 
			'discover.person.born' => 'Data di nascita',
			'discover.person.died' => 'Data di morte',
			'discover.person.birthplace' => 'Luogo di nascita',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} anni)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (a ${age} anni)',
			'errors.searchFailed' => ({required Object error}) => 'Ricerca non riuscita: ${error}',
			'errors.searchUnavailable' => 'La ricerca non ha potuto raggiungere alcun server multimediale.',
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
			'errors.reasonTimedOut' => 'il tempo di connessione è scaduto',
			'errors.reasonUnreachable' => 'non è stato possibile raggiungere il server',
			'errors.reasonRefused' => 'il server ha rifiutato la richiesta',
			'errors.reasonNotFound' => 'l\'elemento non è più presente sul server',
			'errors.reasonServerError' => 'il server ha segnalato un errore',
			'errors.reasonCancelled' => 'la richiesta è stata annullata',
			'errors.reasonUnexpected' => 'si è verificato un errore imprevisto',
			'libraries.playRandomMovie' => 'Gioca un film casuale',
			'libraries.randomPickFailed' => 'Non si può scegliere un film casuale da questa biblioteca.',
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
			_ => null,
		} ?? switch (path) {
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
			'libraries.filterCategories.filePath' => 'Percorso del file',
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
			'libraries.sortLabels.dateDownloaded' => 'Data di download',
			'libraries.sortLabels.size' => 'Dimensione',
			'libraries.sortLabels.library' => 'Libreria',
			'libraries.advancedFilters.include' => 'Includi',
			'libraries.advancedFilters.exclude' => 'Escludi',
			'libraries.advancedFilters.any' => 'Qualsiasi',
			'libraries.advancedFilters.yes' => 'Sì',
			'libraries.advancedFilters.no' => 'No',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Tranne ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} selezionati',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} esclusi',
			'libraries.advancedFilters.searchValues' => 'Cerca valori',
			'libraries.advancedFilters.noValues' => 'Nessun valore',
			'libraries.advancedFilters.matchContains' => 'Contiene',
			'libraries.advancedFilters.matchNotContains' => 'Non contiene',
			'libraries.advancedFilters.matchIs' => 'È',
			'libraries.advancedFilters.matchIsNot' => 'Non è',
			'libraries.advancedFilters.matchBeginsWith' => 'Inizia con',
			'libraries.advancedFilters.matchEndsWith' => 'Finisce con',
			'libraries.advancedFilters.textHint' => 'Digita il testo da cercare',
			'libraries.advancedFilters.from' => 'Da',
			'libraries.advancedFilters.to' => 'A',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => 'Da ${from} a ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} e oltre',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Fino a ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Ultimi ${count} giorni',
			'libraries.advancedFilters.dateLastYear' => 'Ultimo anno',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Più di ${count} giorni fa',
			'libraries.advancedFilters.dateOlderThanYear' => 'Più di un anno fa',
			'libraries.selection.selectItems' => 'Selezionare gli oggetti',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} selezionati',
			'libraries.selection.actions' => 'azioni di selezione',
			'libraries.selection.confirmDescendants' => 'Questo cambia tutti gli episodi nei spettacoli e nelle stagioni selezionate.',
			'libraries.selection.confirmUnwatched' => 'Verrà azzerato anche l’avanzamento della riproduzione degli elementi selezionati.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'I prodotti selezionati: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Articoli aggiornati: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Aggiornato ${succeeded}; fallito ${failed}. gli articoli falliti rimangono selezionati.',
			'about.title' => 'Informazioni',
			'about.openSourceLicenses' => 'Licenze open source',
			'about.versionLabel' => ({required Object version}) => 'Versione ${version}',
			'about.appDescription' => 'Un elegante client Plex, Jellyfin ed Emby per Flutter',
			'about.viewLicensesDescription' => 'Visualizza le licenze delle librerie di terze parti',
			'about.privacyPolicy' => 'Informativa sulla privacy',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nessun server trovato per ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Impossibile caricare i server: ${error}',
			'serverSelection.noValidServers' => 'Nessun server utilizzabile trovato per questo account',
			'hubDetail.title' => 'Titolo',
			'hubDetail.releaseYear' => 'Anno di uscita',
			'hubDetail.dateAdded' => 'Data di aggiunta',
			'hubDetail.rating' => 'Valutazione',
			'hubDetail.noItemsFound' => 'Nessun elemento trovato',
			'logs.clearLogs' => 'Cancella log',
			'logs.copyLogs' => 'Copia log',
			'logs.uploadLogs' => 'Carica log',
			'logs.saveLogs' => 'Salva i file in file',
			'logs.logsSaved' => ({required Object path}) => 'I registri salvati a ${path}',
			'logs.saveLogsFailed' => 'Non poteva salvare il file di log.',
			'startup.failedTitle' => 'PlezyNG non ha potuto avviarsi',
			'startup.failedBody' => 'Si è verificato un errore durante l\'avvio. I dettagli seguenti indicano cosa non ha funzionato.',
			'startup.failedBodyRepairable' => 'Il file delle impostazioni salvate di PlezyNG è danneggiato e deve essere ricostruito prima che PlezyNG possa avviarsi. Riprovare non servirà: scegli Ripara storage.',
			'startup.phaseLabel' => 'Passaggio',
			'startup.showDetails' => 'Mostra dettagli',
			'startup.hideDetails' => 'Nascondi dettagli',
			'startup.copyDetails' => 'Copia dettagli',
			'startup.detailsCopied' => 'Dettagli copiati negli appunti',
			'startup.uploadDetails' => 'Carica dettagli',
			'startup.repairStorage' => 'Ripara storage',
			'startup.repairTitle' => 'Riparare i dati archiviati?',
			'startup.repairBodyCommon' => 'Il file delle impostazioni di PlezyNG è danneggiato e non può essere letto. La riparazione ripristina ogni impostazione al suo valore predefinito.',
			'startup.repairBodyOneCredential' => 'Un accesso salvato è danneggiato e non può essere letto. La riparazione rimuove solo quello; le altre impostazioni restano intatte.',
			'startup.repairBodySignInsKept' => 'I tuoi server e profili dovrebbero rimanere con accesso effettuato.',
			'startup.repairBodySignInsLost' => 'La chiave che protegge i tuoi accessi salvati non può essere recuperata da questo file, quindi dovrai effettuare di nuovo l\'accesso a ogni server e profilo. Nulla sul tuo server multimediale è interessato.',
			'startup.repairBodySessionsUncertain' => 'I tracker (MAL, AniList, Simkl, Trakt) e Seerr sono archiviati separatamente e potrebbero sopravvivere o meno. PlezyNG ti dirà esattamente cosa ha conservato.',
			'startup.repairConfirm' => 'Ripara',
			'startup.repairSucceeded' => 'Storage riparato',
			'startup.repairNeedsRestart' => 'Storage riparato — riavvio richiesto',
			'startup.restartRequiredBody' => 'I tuoi dati sono stati riparati, ma PlezyNG deve ripartire da zero prima di poterli usare. Chiudi PlezyNG e riaprilo.',
			'startup.quitPlezy' => 'Esci da PlezyNG',
			'startup.repairFailed' => 'Riparazione non riuscita',
			'startup.repairKeptSignIns' => 'I tuoi server e profili hanno ancora l\'accesso effettuato.',
			'startup.repairLostSignIns' => 'La chiave che protegge i tuoi accessi salvati non ha potuto essere recuperata. Dovrai effettuare di nuovo l\'accesso a ogni server e profilo.',
			'startup.repairLostSessions' => 'Almeno una connessione a un tracker o a Seerr è andata persa e deve essere riconnessa.',
			'startup.backupTitle' => 'È stata conservata una copia del file danneggiato',
			'startup.backupWarning' => 'Contiene le tue credenziali di accesso. Non caricarla né condividerla.',
			'startup.deleteBackup' => 'Elimina copia',
			'startup.backupDeleted' => 'Copia eliminata.',
			'startup.previousFailureTitle' => 'PlezyNG non è riuscito ad avviarsi l\'ultima volta',
			'licenses.relatedPackages' => 'Pacchetti correlati',
			'licenses.license' => 'Licenza',
			'licenses.licenseNumber' => ({required Object number}) => 'Licenza ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenze',
			'navigation.libraries' => 'Librerie',
			'navigation.downloads' => 'Download',
			'navigation.liveTv' => 'Diretta',
			'navigation.explore' => 'Esplora',
			'explore.mdblistShelves.manage' => 'Gestione esplora le scale',
			'explore.mdblistShelves.manageDescription' => 'Scegli e organizzi elenchi dal tuo account MDBList',
			'explore.mdblistShelves.description' => 'Scegli le liste di film e TV pubbliche dal tuo account MDBList. Crea o copia le liste su MDBList, poi ristrutturare.',
			'explore.mdblistShelves.selected' => 'Le scale selezionate',
			'explore.mdblistShelves.available' => 'Elenco dei conti disponibili',
			'explore.mdblistShelves.noLists' => 'Non sono stati restituiti film pubblici o elenchi televisivi. Creare o copiare un elenco su MDBList, poi rinfrescare.',
			'explore.mdblistShelves.displayName' => 'Nome di display Shelf',
			'explore.mdblistShelves.nameHint' => 'Lascia la lista di fonti per utilizzare il nome della lista di fondi.',
			'explore.mdblistShelves.add' => 'Aggiungi Shelf',
			'explore.mdblistShelves.save' => 'Salva le scale',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Move ${title} in alto',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Rimuovere ${title}',
			'explore.mdblistShelves.unavailable' => 'Questo elenco non è disponibile. rimuovere o rimuovere la sua scheda nelle impostazioni.',
			'explore.mdblistShelves.rateLimited' => 'Il limite di richiesta MDBList è stato raggiunto. si prega di ritirarsi in seguito.',
			'explore.mdblistShelves.loadFailed' => 'Non si possono caricare le strisce. controllare la connessione e ritorno.',
			'explore.mdblistShelves.saveFailed' => 'Non riesco a salvare le scale, per favore, ritiro.',
			'explore.mdblistShelves.accountChanged' => 'Il profilo o l\'account è cambiato.Riavvi queste impostazioni.',
			'explore.mdblistShelves.settingsUnreadable' => 'Le schede salvate non possono essere lette. selezionare nuovamente le liste per sostituire queste impostazioni.',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodi', ), 
			'explore.cast' => 'Attori',
			'explore.characters' => 'Personaggi',
			'explore.addToWatchlist' => 'Aggiungi alla lista da guardare',
			'explore.removeFromWatchlist' => 'Rimuovi dalla lista da guardare',
			'explore.addedToWatchlist' => 'Aggiunto alla lista titoli',
			'explore.removedFromWatchlist' => 'Rimosso dalla lista titoli',
			'explore.watchlistUpdateFailed' => 'Impossibile aggiornare la lista da guardare',
			'explore.watchlistNoMatch' => 'Impossibile associare questo elemento a una lista titoli',
			'explore.notInLibrary' => 'Non è nella tua libreria',
			'explore.inTheseLibraries' => 'In queste librerie',
			'explore.checkingLibrary' => 'Ricerca nella tua libreria...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Impossibile controllare ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server', other: 'Impossibile controllare ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} server', ), 
			'explore.emptyTitle' => 'Ancora niente qui',
			'explore.emptyMessage' => ({required Object source}) => 'Le sezioni di ${source} appariranno qui quando saranno disponibili dei contenuti.',
			'explore.searchHint' => ({required Object source}) => 'Cerca su ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Nessun risultato per "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Cerca film e serie TV su ${source}.',
			'explore.searchFailed' => 'Ricerca fallita. Controlla la connessione e riprova.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} popolari',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} in onda',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} valutati',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} di tendenza',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} in ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} in visione',
			'explore.badge.available' => 'Disponibile',
			'explore.badge.partiallyAvailable' => 'Parzialmente disponibile',
			'explore.badge.availableIn4k' => 'Disponibile in 4K',
			'explore.badge.requested' => 'Richiesto',
			'explore.badge.pendingApproval' => 'In attesa di approvazione',
			'explore.badge.processing' => 'In elaborazione',
			'explore.badge.declined' => 'Rifiutato',
			'explore.badge.requestFailed' => 'Richiesta non riuscita',
			'explore.badge.requested4k' => 'Richiesto in 4K',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} stagioni',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} tra ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Prossimo tra ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ep',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} in elenco',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} guardati oggi',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} guardati questa settimana',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} guardati questo mese',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} guardati quest\'anno',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} spettatori',
			'explore.stats.planning' => ({required Object n}) => '${n} hanno in programma di guardarlo',
			'explore.stats.favorited' => ({required Object n}) => '${n} preferiti',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} lo ha abbandonato',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commento', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commenti', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} voti',
			'explore.stats.watching' => ({required Object n}) => '${n} lo stanno guardando',
			'explore.stats.completed' => ({required Object n}) => '${n} completati',
			'explore.stats.onHold' => ({required Object n}) => '${n} in pausa',
			'explore.stats.dropped' => ({required Object n}) => '${n} abbandonati',
			'explore.season.winter' => 'Inverno',
			'explore.season.spring' => 'Primavera',
			'explore.season.summer' => 'Estate',
			'explore.season.fall' => 'Autunno',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV Short',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Speciale',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Musica',
			'explore.format.other' => 'Altro',
			'explore.sourceMaterial.original' => 'Originale',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Romanzo',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Videogioco',
			'explore.sourceMaterial.webComic' => 'Web comic',
			'explore.sourceMaterial.musicRelease' => 'Musica',
			'explore.sourceMaterial.otherMedia' => 'Altro',
			'explore.creditRole.actor' => 'Attore',
			'explore.creditRole.director' => 'Regista',
			'explore.creditRole.writer' => 'Sceneggiatore',
			'explore.creditRole.producer' => 'Produttore',
			'explore.creditRole.creator' => 'Creatore',
			'explore.creditRole.composer' => 'Compositore',
			'explore.relation.prequel' => 'Prequel',
			'explore.relation.sequel' => 'Sequel',
			'explore.relation.sideStory' => 'Storia secondaria',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Versione alternativa',
			'explore.relation.summary' => 'Riepilogo',
			'explore.relation.parentStory' => 'Storia originale',
			'explore.relation.adaptation' => 'Adattamento',
			'explore.relation.other' => 'Correlati',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Va in onda ${day} alle ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Va in onda ${day} alle ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Titolo originale',
			'explore.detail.alsoKnownAs' => 'Conosciuto anche come',
			'explore.detail.studios' => 'Studi',
			'explore.detail.country' => 'Paese',
			'explore.detail.language' => 'Lingua',
			'explore.detail.released' => 'Uscito',
			'explore.detail.physicalRelease' => 'Su disco',
			'explore.detail.ended' => 'Concluso',
			'explore.detail.addedOn' => ({required Object date}) => 'Aggiunto ${date}',
			'explore.detail.yourRating' => 'La tua valutazione',
			'explore.detail.budget' => 'Budget',
			'explore.detail.revenue' => 'Incassi',
			'explore.detail.contentAdvisory' => 'Guida all\'età',
			'explore.detail.tags' => 'Tag',
			'explore.detail.revealSpoilerTags' => 'Mostra tag spoiler',
			'explore.detail.links' => 'Link',
			'explore.detail.watchOn' => 'Guarda su',
			'explore.detail.watchTrailer' => 'Guarda trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Apri su ${site}',
			'explore.detail.crew' => 'Cast tecnico',
			'explore.detail.ratings' => 'Valutazioni',
			'explore.detail.schedule' => 'Programmazione',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Consigliato da ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utente', other: 'Consigliato da ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utenti', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Consigliato da ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Preferito da ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} non ancora in onda',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Consigliato dal ${percent} degli spettatori',
			'explore.detail.relatedTitles' => 'Titoli correlati',
			'explore.detail.background' => 'Contesto',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} risultato', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} risultati', ), 
			'liveTv.title' => 'TV in diretta',
			'liveTv.guide' => 'Guida',
			'liveTv.noChannels' => 'Nessun canale disponibile',
			'liveTv.noDvr' => 'Nessun DVR configurato su alcun server',
			'liveTv.serverUnavailable' => 'Il server TV in diretta non è disponibile.',
			'liveTv.serverNotConnected' => 'Il server TV in diretta non è connesso.',
			'liveTv.noPrograms' => 'Nessun dato di programma disponibile',
			'liveTv.liveStreamFailed' => 'Streaming in diretta non riuscito',
			'liveTv.unknownProgram' => 'Programma sconosciuto',
			'liveTv.timelineLiveProgram' => 'Programma dal vivo (il ripristino può essere fuori dal programma)',
			'liveTv.timelineBuffer' => 'TIME TIME di Buffer',
			'liveTv.timelineUnavailable' => 'TIME INCOSPOSIBILE',
			'liveTv.timelineEstimated' => 'Il Playback stimato',
			'liveTv.timelinePending' => 'Per la ricerca',
			'liveTv.timelineStale' => 'Il calendario può essere esaurito',
			'liveTv.unknownHub' => 'Sconosciuto',
			'liveTv.unknownError' => 'Errore sconosciuto',
			'liveTv.channelNumber' => ({required Object number}) => 'Canale ${number}',
			'liveTv.unknownChannel' => 'Canale sconosciuto',
			'liveTv.live' => 'IN DIRETTA',
			'liveTv.premiereBadge' => 'Nuovo',
			'liveTv.reloadGuide' => 'Ricarica la guida',
			'liveTv.searchGuide' => 'Cerca nella guida',
			'liveTv.searchHint' => 'Cerca canali e programmi',
			'liveTv.searchNoResults' => ({required Object query}) => 'Nessuna corrispondenza per "${query}"',
			'liveTv.channelsSection' => 'Canali',
			'liveTv.programsSection' => 'Programmi',
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
			'liveTv.noFavoriteChannels' => 'Nessun canale preferito',
			'liveTv.noFavoriteChannelsHint' => 'Mostra tutti i canali, quindi tieni premuto un canale per aggiungerlo ai preferiti.',
			'liveTv.showAllChannels' => 'Mostra tutti i canali',
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
			'liveTv.guideReloadFailed' => 'Impossibile aggiornare la guida',
			'liveTv.rulesProcessRequested' => 'Rielaborazione delle regole richiesta',
			'liveTv.rulesProcessFailed' => 'Impossibile rielaborare le regole di registrazione',
			'liveTv.recordShow' => 'Registra programma',
			'liveTv.recordSettings.startEarly' => 'Inizia in anticipo (secondi)',
			'liveTv.recordSettings.endLate' => 'Termina in ritardo (secondi)',
			'liveTv.recordSettings.newOnly' => 'Solo nuovi episodi',
			'liveTv.recordSettings.anyChannel' => 'Registra su qualsiasi canale',
			'liveTv.recordSettings.anyTime' => 'Registra a qualsiasi ora',
			'liveTv.recordSettings.skipInLibrary' => 'Salta gli episodi già presenti nella libreria',
			'liveTv.recordSettings.keepUpTo' => 'Episodi da conservare',
			'liveTv.recordSettings.keepUpToHint' => '0 conserva tutti gli episodi',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Inizia tra ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} alle ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} ha restituito dati di riproduzione della TV in diretta non validi',
			'liveTv.failedToStartChannel' => 'Impossibile avviare il canale in diretta',
			'liveTv.failedToBuildStreamUrl' => 'Impossibile creare l\'URL dello stream',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Impossibile avviare il canale: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Impossibile cambiare canale: ${reason}',
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
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elemento', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementi', ), 
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} brano', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} brani', ), 
			'music.nowPlaying' => 'In riproduzione',
			'music.playingFrom' => ({required Object title}) => 'Riproduzione da ${title}',
			'music.queue' => 'Coda',
			'music.clearQueue' => 'Svuota la coda',
			'music.lyrics' => 'Testo',
			'music.visualizer' => 'Visualizzatore',
			'music.visualizerProfileLoading' => 'Leggi il track analysis...',
			'music.visualizerAmbientMotion' => 'Movimento Ambientale',
			'music.visualizerPlexLoudness' => 'Plex suono',
			'music.visualizerPreviousPreset' => 'Articolo precedenteStyle visivo',
			'music.visualizerNextPreset' => 'Next Stile visivo',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Il blu',
			'music.visualizerPresetOrbitals' => 'orbitali',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Il tunnel',
			'music.visualizerPresetTrackMap' => 'Mappa di traccia',
			'music.noLyrics' => 'Nessun testo disponibile',
			'music.sleepTimer' => 'Timer di spegnimento',
			'music.sleepTimerEndOfTrack' => 'Fine del brano',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuti', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuti', ), 
			'music.stopPlayback' => 'Interrompi riproduzione',
			'music.previousTrack' => 'Brano precedente',
			'music.nextTrack' => 'Brano successivo',
			'music.repeat' => 'Ripeti',
			'music.repeatAll' => 'Ripeti tutto',
			'music.repeatOne' => 'Ripeti il brano',
			'music.instantMixNoServer' => 'Nessun server disponibile per un mix istantaneo',
			'music.instantMixFailed' => 'Impossibile caricare il mix istantaneo',
			'music.instantMixEmpty' => 'Il mix istantaneo non ha prodotto alcun brano',
			'music.noAudioUrl' => ({required Object track}) => 'Nessun URL audio disponibile per ${track}',
			'music.discography.singlesAndEps' => 'Singoli ed EP',
			'music.discography.live' => 'Dal vivo',
			'music.discography.compilations' => 'Compilation',
			'watchTogether.title' => 'Guarda insieme',
			'watchTogether.description' => 'Guarda contenuti in sincronia con amici e familiari',
			'watchTogether.createRoom' => 'Crea stanza',
			'watchTogether.creatingRoom' => 'Creazione della stanza...',
			'watchTogether.joinRoom' => 'Unisciti a una stanza',
			'watchTogether.joiningRoom' => 'Ingresso nella stanza...',
			'watchTogether.connecting' => 'Connessione in corso...',
			'watchTogether.relayPublic' => 'Le stanze usano i relay pubblici di Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Le stanze usano il tuo relay all\'indirizzo ${url}.',
			'watchTogether.recentRooms' => 'Stanze usate di recente',
			'watchTogether.roomActions' => 'Azioni della stanza',
			'watchTogether.renameRoom' => 'Rinomina stanza',
			'watchTogether.removeRoom' => 'Rimuovi',
			'watchTogether.enterRoomCode' => 'Inserisci il codice di 6 caratteri ricevuto dall\'host.',
			'watchTogether.roomCode' => 'Codice stanza',
			'watchTogether.paste' => 'Incolla',
			'watchTogether.noCodeInClipboard' => 'Gli appunti non contengono un codice stanza',
			'watchTogether.copyCode' => 'Copia codice',
			'watchTogether.codeCopied' => 'Codice stanza copiato',
			'watchTogether.shareInvite' => 'Condividi invito',
			'watchTogether.inviteCopied' => 'Invito copiato. Incollalo in un messaggio.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Unisciti alla mia stanza di Guarda insieme su PlezyNG: apri «Guarda insieme», scegli «Unisciti a una stanza» e inserisci ${code}.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.openSessionControls' => 'Apri i controlli della sessione di Guarda insieme',
			'watchTogether.reconnecting' => 'Riconnessione...',
			'watchTogether.reconnectingDescription' => 'La connessione si è interrotta. Rientrerai automaticamente nella stanza.',
			'watchTogether.connected' => 'Connesso',
			'watchTogether.disconnected' => 'Disconnesso',
			'watchTogether.youAreHost' => 'Sei l\'host',
			'watchTogether.hostedBy' => ({required Object name}) => 'Ospitata da ${name}',
			'watchTogether.hostControlsPlayback' => 'L\'host controlla la riproduzione',
			'watchTogether.anyoneCanControl' => 'Tutti possono controllare la riproduzione',
			'watchTogether.roomLocked' => 'Stanza bloccata',
			'watchTogether.nowPlaying' => 'In riproduzione',
			'watchTogether.nothingPlaying' => 'Nessuna riproduzione in corso',
			'watchTogether.nothingPlayingHost' => 'Riproduci qualcosa da una qualsiasi libreria per condividerlo con la stanza.',
			'watchTogether.nothingPlayingGuest' => 'Quando l\'host avvia qualcosa, si aprirà qui.',
			'watchTogether.notShareable' => 'Questo video non ha corrispondenze nel catalogo, quindi può riprodurlo solo chi ha accesso allo stesso server.',
			'watchTogether.searching' => 'Ricerca di questo video nelle tue librerie...',
			'watchTogether.yourCopy' => 'La tua copia',
			'watchTogether.sharingYourCopy' => 'Stai condividendo la tua copia',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Riproduzione della tua copia, ${difference}',
			'watchTogether.mismatchTitle' => 'La tua copia ha una durata diversa',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'La tua copia più simile dura ${difference} rispetto al video della stanza. Potrebbe trattarsi di un altro montaggio o di un\'altra versione.',
			'watchTogether.playAnyway' => 'Riproduci comunque',
			'watchTogether.chooseAnotherCopy' => 'Scegli un\'altra copia',
			'watchTogether.dontPlay' => 'Non riprodurre',
			'watchTogether.unavailableTitle' => 'Non hai questo video',
			'watchTogether.unavailableDescription' => 'PlezyNG non l\'ha trovato nelle tue librerie. Scegli tu una copia o cerca di nuovo.',
			'watchTogether.chooseCopy' => 'Scegli una copia',
			'watchTogether.searchAgain' => 'Cerca di nuovo',
			'watchTogether.noCandidates' => 'Nessuna copia trovata nelle tue librerie.',
			'watchTogether.choiceFailed' => 'Impossibile riprodurre questa copia per la stanza',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} in più',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} in meno',
			'watchTogether.lengthSame' => 'Stessa durata',
			'watchTogether.lengthUnknown' => 'Durata sconosciuta',
			'watchTogether.joinCurrentPlayback' => 'Unisciti alla riproduzione corrente',
			'watchTogether.joinCurrentPlaybackDescription' => 'Torna a ciò che l\'host sta guardando in questo momento',
			'watchTogether.stopMedia' => 'Interrompi il video per tutti',
			'watchTogether.syncOffset' => 'Offset di sincronizzazione',
			'watchTogether.syncOffsetDescription' => 'Sposta il tuo video se è in anticipo o in ritardo rispetto alla stanza.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'La tua copia dura ${difference} rispetto al video della stanza.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Usa ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Partecipanti',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} partecipante', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} partecipanti', ), 
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (tu)',
			'watchTogether.playerIdle' => 'Inattivo',
			'watchTogether.playerLoading' => 'Caricamento',
			'watchTogether.playerReady' => 'Pronto',
			'watchTogether.playerBuffering' => 'Buffering',
			'watchTogether.matchSearching' => 'Ricerca in corso',
			'watchTogether.matchMatched' => 'Ha il video',
			'watchTogether.matchMismatched' => 'Durata diversa',
			'watchTogether.matchUnavailable' => 'Non ha il video',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Offset ${offset}',
			'watchTogether.makeHost' => 'Rendi host',
			'watchTogether.makeHostQuestion' => 'Trasferire il ruolo di host?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} controllerà la riproduzione e guiderà la sessione per tutti.',
			'watchTogether.transfer' => 'Trasferisci',
			'watchTogether.removeParticipant' => 'Rimuovi dalla stanza',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Rimuovere ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} uscirà dalla stanza. Potrà rientrare con il codice, a meno che tu non blocchi la stanza.',
			'watchTogether.remove' => 'Rimuovi',
			'watchTogether.roomSettings' => 'Impostazioni della stanza',
			'watchTogether.letEveryoneControl' => 'Consenti a tutti di controllare la riproduzione',
			'watchTogether.lockRoom' => 'Blocca stanza',
			'watchTogether.lockRoomDescription' => 'Nessun nuovo partecipante può entrare',
			'watchTogether.leaveRoom' => 'Abbandona stanza',
			'watchTogether.leaveRoomQuestion' => 'Abbandonare la stanza?',
			'watchTogether.leaveRoomConfirm' => 'Potrai rientrare con il codice della stanza.',
			'watchTogether.leave' => 'Abbandona',
			'watchTogether.endRoom' => 'Chiudi stanza',
			'watchTogether.endRoomQuestion' => 'Chiudere la stanza?',
			'watchTogether.endRoomConfirm' => 'La stanza verrà chiusa per tutti.',
			'watchTogether.end' => 'Termina',
			'watchTogether.playBlockedTitle' => 'La riproduzione non è partita',
			'watchTogether.playBlockedDescription' => 'Premi Riproduci per iniziare a guardare con la stanza.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} ha premuto Riproduci',
			'watchTogether.notices.playbackStarted' => 'Riproduzione avviata',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} ha messo in pausa',
			'watchTogether.notices.playbackPaused' => 'Riproduzione in pausa',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} è passato a ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Riproduzione spostata a ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} ha impostato la velocità a ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Velocità impostata a ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} ha avviato ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'In riproduzione: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} ha interrotto il video',
			'watchTogether.notices.mediaStopped' => 'Il video è stato interrotto',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'In attesa di ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'In attesa che qualcuno si metta in pari...',
			'watchTogether.notices.finished' => 'Terminato',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} è ora l\'host',
			'watchTogether.notices.youAreNowHost' => 'Ora sei l\'host',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} si è unito',
			'watchTogether.notices.left' => ({required Object name}) => '${name} se ne è andato',
			'watchTogether.notices.controlRefused' => 'Solo l\'host può controllare la riproduzione',
			'watchTogether.notices.searchFailed' => 'Su alcuni server non è stato possibile cercare il video della stanza',
			'watchTogether.notices.playBlocked' => 'Premi Riproduci per iniziare',
			'watchTogether.notices.shareFailed' => 'Impossibile condividere questo video con la stanza',
			'watchTogether.notices.downloadNotShared' => 'I download non vengono condivisi con la stanza mentre il loro server è offline',
			'watchTogether.notices.openFailed' => 'Impossibile aprire il video della stanza',
			'watchTogether.ended.ended' => 'L\'host ha chiuso la stanza',
			'watchTogether.ended.kicked' => 'Sei stato rimosso dalla stanza',
			'watchTogether.ended.expired' => 'La stanza è scaduta',
			'watchTogether.ended.replaced' => 'Sei entrato in questa stanza da un altro dispositivo',
			'watchTogether.ended.lost' => 'Connessione alla stanza persa',
			'watchTogether.errors.invalidCode' => 'Questo non è un codice stanza. I codici sono composti da 6 lettere e cifre, senza 0, 1, I, L o O.',
			'watchTogether.errors.roomNotFound' => 'Nessuna stanza ha questo codice. Potrebbe essere stata chiusa.',
			'watchTogether.errors.roomFull' => 'La stanza è piena.',
			'watchTogether.errors.roomLocked' => 'L\'host ha bloccato la stanza.',
			'watchTogether.errors.relayFull' => 'Guarda insieme è momentaneamente sovraccarico. Riprova più tardi.',
			'watchTogether.errors.unreachable' => 'Impossibile raggiungere il relay di Guarda insieme. Controlla la connessione.',
			'watchTogether.errors.rateLimited' => 'Troppi tentativi. Attendi un momento e riprova.',
			'watchTogether.errors.clientBlocked' => 'Questa versione di PlezyNG non può usare il relay. Aggiorna l\'app.',
			'watchTogether.errors.forbidden' => 'Solo l\'host può farlo.',
			'watchTogether.errors.notInRoom' => 'Non sei in una stanza.',
			'watchTogether.errors.alreadyInRoom' => 'Sei già in una stanza.',
			'watchTogether.errors.resumeFailed' => 'Impossibile rientrare nella stanza.',
			'watchTogether.errors.unsupported' => 'Il relay non supporta questa funzione.',
			'watchTogether.errors.generic' => 'Si è verificato un problema. Riprova.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Episodio ${number}',
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
			'downloads.storageFull' => 'I download sono stati interrotti per preservare lo spazio disponibile. Libera spazio o scegli un’altra posizione di download, quindi riprova.',
			'downloads.storageUnavailable' => 'I download sono stati interrotti perché non è stato possibile verificare lo spazio di archiviazione disponibile. Controlla la posizione di download e riprova.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodi in coda per il download',
			'downloads.downloadDeleted' => 'Download eliminato',
			'downloads.deleteConfirm' => ({required Object title}) => 'Eliminare "${title}" da questo dispositivo?',
			'downloads.deleteCollectionDownloads' => 'Elimina i download',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Eliminare tutti i download di "${title}" da questo dispositivo?',
			'downloads.collectionDownloadsDeleted' => 'Download eliminati',
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
			'downloads.retryAll' => 'Riprova tutti',
			'downloads.retryFailed' => 'Riprova i download non riusciti',
			'downloads.deleteAll' => 'Elimina tutto',
			'downloads.selectVersion' => 'Seleziona la versione',
			'downloads.allEpisodes' => 'Tutti gli episodi',
			'downloads.unwatchedOnly' => 'Solo non visti',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Prossimi ${count} episodi non visti',
			'downloads.customAmount' => 'Quantità personalizzata...',
			'downloads.customAmountAny' => 'Quanti sono i vari (quanti sono i)',
			'downloads.randomEpisodes' => 'Episodi casuali',
			'downloads.includeSpecials' => 'Includi gli speciali',
			'downloads.howManyEpisodes' => 'Quanti episodi?',
			'downloads.invalidEpisodeCount' => 'Inserisci un numero di episodi valido.',
			'downloads.keepSynced' => 'Mantieni sincronizzato',
			'downloads.downloadOnce' => 'Scarica una volta',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Mantieni ${count} episodi non visti',
			'downloads.editSyncRule' => 'Modifica regola di sincronizzazione',
			'downloads.removeSyncRule' => 'Rimuovi regola di sincronizzazione',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Interrompere la sincronizzazione di "${title}"? Gli episodi scaricati verranno mantenuti.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Interrompere la sincronizzazione di "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'Elimina anche i download associati',
			'downloads.deleteSyncRuleDownloadsDescription' => 'I download usati da un\'altra regola di sincronizzazione o da un altro profilo verranno conservati.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regola di sincronizzazione creata — ${count} episodi non visti mantenuti',
			'downloads.syncRuleUpdated' => 'Regola di sincronizzazione aggiornata',
			'downloads.syncRuleRemoved' => 'Regola di sincronizzazione rimossa',
			'downloads.syncRuleAndDownloadsRemoved' => 'Regola di sincronizzazione e download associati rimossi',
			'downloads.syncRuleCleanupBusy' => 'Le regole di sincronizzazione sono in fase di aggiornamento. Riprova tra un momento.',
			'downloads.syncRuleCleanupUnavailable' => 'Non è stato possibile identificare in sicurezza i download associati. Riconnetti il server e riprova, oppure rimuovi la regola senza eliminare i download.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} nuovi episodi sincronizzati per ${title}',
			'downloads.syncNow' => 'Sincolo ora',
			'downloads.downloadsUpToDate' => 'Le scaricazioni sono aggiornate',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sincronizzazione completa · ${queued} quued, ${removed} rimosso',
			'downloads.activeSyncRules' => 'Regole di sincronizzazione',
			'downloads.reviewOrphanFiles' => 'Rivedi i download orfani',
			'downloads.orphanReviewTitle' => 'Rivedi i download orfani',
			'downloads.orphanReviewDescription' => 'Questi file contrassegnati si trovano nelle cartelle di download predefinite gestite da PlezyNG e non hanno una voce di download corrispondente né un’attività in corso. Controlla l’elenco prima di eliminarli.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} file · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Elimina ${count} file',
			'downloads.orphanCleanupNone' => 'Nessun file di download orfano trovato',
			'downloads.orphanCleanupFailed' => 'PlezyNG non è riuscito a eseguire una scansione sicura della cartella di download gestita. Non è stato eliminato alcun file.',
			'downloads.orphanCleanupChanged' => 'L’elenco dei download è cambiato durante la revisione. Controlla di nuovo i file prima di ripulire.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Eliminati ${count} file di download orfani · liberati ${size}',
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
			'downloads.syncRuleAccessDenied' => 'Accesso negato',
			'downloads.syncRuleNotAvailableForProfile' => 'Non disponibile per il profilo attuale',
			'downloads.syncRuleUnknownServer' => 'Server sconosciuto',
			'downloads.syncRuleListCreated' => 'Regola di sincronizzazione creata',
			'downloads.backgroundWarning.bannerBlocked' => 'I download si interromperanno quando esci dall’app',
			'downloads.backgroundWarning.bannerDegraded' => 'I download in background potrebbero essere limitati',
			'downloads.backgroundWarning.bannerAction' => 'Dettagli',
			'downloads.backgroundWarning.sheetTitle' => 'I download in background sono bloccati',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'I download in background potrebbero essere limitati',
			'downloads.backgroundWarning.sheetIntro' => 'Android impedisce a PlezyNG di scaricare in modo affidabile in background.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Il dispositivo limita i momenti in cui PlezyNG può scaricare in background.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'L’uso in background di PlezyNG è limitato. Nelle impostazioni della batteria o dell’uso in background, seleziona «Senza restrizioni».',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android ha messo PlezyNG in uno stato di standby con restrizioni. Imposta l’uso della batteria su «Senza restrizioni».',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Le notifiche dei download sono disattivate, quindi l’avanzamento e i controlli potrebbero non essere disponibili.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Le notifiche sono disattivate. Su Android 13 o versioni successive sono necessarie per i download prolungati in background.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Il Risparmio dati è attivo e blocca i download in background tramite dati mobili. I download dovrebbero comunque funzionare su Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'I download si sono interrotti più volte mentre PlezyNG era in background. Controlla le impostazioni della batteria o dell’uso in background di PlezyNG.',
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
			'downloads.options' => 'Opzioni download',
			'downloads.groupings.library' => 'Libreria',
			'downloads.groupings.collections' => 'Raccolte',
			'downloads.unknownLibrary' => 'Libreria sconosciuta',
			'downloads.unknownShow' => 'Serie sconosciuta',
			'downloads.unknownSeason' => 'Stagione sconosciuta',
			'downloads.unknownAlbum' => 'Album sconosciuto',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} completati',
			'downloads.storageUsed' => ({required Object size}) => 'Storage utilizzato: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mostra', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} mostri', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', ), 
			'downloads.errorFileNotFound' => 'File non trovato (404)',
			'downloads.errorDownloadNotAllowed' => 'Download non consentito dal server (403)',
			'downloads.errorDownloadFailed' => 'Download non riuscito',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Download non riuscito: ${reason}',
			'downloads.convertingOnServer' => 'Convertire il server...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Conversione sul server · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Download non riuscito (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Post-elaborazione non riuscita: ${reason}',
			'downloads.reasonFileNotSaved' => 'non è stato possibile salvare il file su questo dispositivo',
			'downloads.reasonCannotResume' => 'non è stato possibile riprendere il download parziale',
			'downloads.reasonDeviceStorageFull' => 'lo spazio di archiviazione di questo dispositivo è esaurito',
			'downloads.notificationDownloading' => 'Download in corso...',
			'downloads.notificationComplete' => 'Download completato',
			'downloads.notificationPaused' => 'Download in pausa',
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
			'companionRemote.session.manualAddressHint' => 'Indirizzo di connessione manuale:',
			'companionRemote.pairing.discoveryDescription' => 'I dispositivi PlezyNG con lo stesso account Plex appaiono qui',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Connessione...',
			'companionRemote.pairing.searchingForDevices' => 'Ricerca dispositivi...',
			'companionRemote.pairing.noDevicesFound' => 'Nessun dispositivo trovato nella tua rete',
			'companionRemote.pairing.noDevicesHint' => 'Apri PlezyNG sul computer e usa la stessa rete Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dispositivi disponibili',
			'companionRemote.pairing.manualConnection' => 'Connessione manuale',
			'companionRemote.pairing.cryptoInitFailed' => 'Impossibile avviare la connessione sicura. Accedi prima a Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Inserisci l\'indirizzo host',
			'companionRemote.pairing.validationHostFormat' => 'Il formato deve essere IP:porta (es. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tempo scaduto per la connessione. Usa la stessa rete su entrambi i dispositivi.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo non trovato. Assicurati che PlezyNG sia in esecuzione sull\'host.',
			'companionRemote.pairing.authFailed' => 'Autenticazione non riuscita. Entrambi i dispositivi devono usare lo stesso account Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Connessione non riuscita: ${error}',
			'companionRemote.pairing.codeTitle' => 'Codice di coppia',
			'companionRemote.pairing.codeDescription' => 'Inserisci il codice mostrato nella Companion Remote sul dispositivo ospitante. entrambi i dispositivi devono utilizzare una versione che supporta la coppia sicura.',
			'companionRemote.pairing.codeInvalid' => 'Inserisci tutte le 32 lettere e i numeri dal codice ospitante.',
			'companionRemote.pairing.updateRequired' => 'Aggiornare entrambi i dispositivi a una versione che supporta la coppia sicura.',
			'companionRemote.pairing.hostDescription' => 'Inserisci questo codice una volta su ogni remote.Mantenere privato: consente il controllo di questo profilo.',
			'companionRemote.pairing.resetCode' => 'Ristrutturazione di codice di coppia',
			'companionRemote.pairing.resetDescription' => 'Disconnetti tutti i remoti e crea un nuovo codice. Ogni remote dovrà coppia di nuovo.',
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
			'companionRemote.closedBeforeAuth' => 'La connessione si è chiusa prima dell\'autenticazione',
			'videoSettings.playbackSpeed' => 'Velocità di riproduzione',
			'videoSettings.normalSpeed' => 'Normale',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Attivo (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Timer di spegnimento',
			'videoSettings.audioSync' => 'Sincronizzazione audio',
			'videoSettings.subtitleSync' => 'Sincronizzazione sottotitoli',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR non è disponibile qui: questo compositore desktop o questa uscita video non possono gestirlo.',
			'videoSettings.hdrToneMapping' => 'Mappatura dei toni HDR',
			'videoSettings.hdrToneMappingCompositor' => 'Compositore',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Trasmette i metadati HDR della sorgente e lascia che il compositore desktop esegua la mappatura.',
			'videoSettings.hdrToneMappingPlayer' => 'Lettore',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Esegue nel lettore la mappatura in base alla luminosità di picco dello schermo, quindi comunica il risultato al compositore.',
			'videoSettings.hdrToneMappingFailed' => 'Impossibile modificare la mappatura dei toni HDR: la modalità precedente è ancora attiva.',
			'videoSettings.audioOutput' => 'Uscita audio',
			'videoSettings.videoTrack' => 'Traccia video',
			'videoSettings.videoTrackDescription' => 'Scegli quale flusso video mostrare. Disponibile con la riproduzione MPV quando il file contiene tracce video alternative.',
			'videoSettings.videoTrackDefault' => 'Predefinita',
			'videoSettings.videoTrackUnavailable' => 'Non sono disponibili tracce video alternative.',
			'videoSettings.videoTrackFailed' => 'Impossibile cambiare la traccia video.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'Traccia ${id}',
			'videoSettings.performanceOverlay' => 'Overlay prestazioni',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Audio spaziale',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio equalizzatore',
			'videoSettings.audioEqualizerDescription' => 'equalizzatore di 10 bandi per MPVI filtri audio utilizzano l\'audio decodito e disattivano passthrough.',
			'videoSettings.audioEqualizerFlat' => 'Neutro',
			'videoSettings.audioEqualizerActive' => 'Personalizzato',
			'videoSettings.audioEqualizerSaveFailed' => 'Non poteva salvare le impostazioni di equalizzatore audio.',
			'videoSettings.audioEffectsDescription' => 'Effetti utilizzano audio decodato, quindi passthrough si spegne. ambiente in camera e estensione stereo dipendono dal MPV costruire e tracciare.',
			'videoSettings.audioStereoWidth' => 'Stereo ampliamento',
			'videoSettings.audioSpatializer' => 'ambienti di camera',
			'videoSettings.audioSpatializerDescription' => 'Aggiungi riflessioni silenziose.',
			'videoSettings.audioPitch' => 'Cambiamento di Pitch',
			'videoSettings.audioPitchDescription' => 'Cambiare la pista senza cambiare velocità. MPV La costruzione deve includere Rubber Bande il',
			'videoSettings.audioEffectUnavailable' => 'Questo effetto non è disponibile per questo percorso o MPV di costruire.',
			'videoSettings.backgroundVideoAudio' => 'Video audio di background',
			'videoSettings.backgroundVideoAudioDescription' => 'Mantenere il video audio riprodotto quando si lascia il lettore; l\'immagine è nascosta fino a quando non si ritorna. Android utilizza una notifica di riproduzione dei media.',
			'videoSettings.audioNormalization' => 'Normalizza il volume',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Decodifica l\'audio in PCM; il passthrough è disattivato mentre questa opzione è attiva',
			'performanceOverlay.color' => 'Colore',
			'performanceOverlay.performance' => 'Prestazioni',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decoder',
			'performanceOverlay.rawDecoder' => 'Decoder raw',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.passthrough' => 'Passthrough',
			'performanceOverlay.aspect' => 'Proporzioni',
			'performanceOverlay.rotation' => 'Rotazione',
			'performanceOverlay.dvSource' => 'Sorgente DV',
			'performanceOverlay.dvPath' => 'Percorso DV',
			'performanceOverlay.dvRouteDecoder' => 'Decoder Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'Decoder Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Livello base',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'Livello base HDR10',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Livello base HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Livello base SDR',
			'performanceOverlay.dvRouteReshaped' => 'Rimodellato con RPU (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Il grafico sperimentale P7 FEL (non qualificato)',
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
			'performanceOverlay.playMethod' => 'Metodo di gioco',
			'performanceOverlay.memory' => 'Memoria',
			'performanceOverlay.uiFps' => 'FPS UI',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Software',
			'performanceOverlay.decoderHardware' => 'Hardware',
			'performanceOverlay.tunnelingActive' => 'Attivo',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} errori)',
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
			'externalPlayer.description' => 'Scegli un\'altra app per aprire i video in. I giocatori disponibili dipendono dal tuo dispositivo e dalle applicazioni installate.',
			'externalPlayer.systemDefaultDescription' => 'Lascia che il sistema operativo apri il video con la sua app predefinita.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Apri i video con ${player}.',
			'externalPlayer.playerNameDescription' => 'L\'etichetta visualizzata nella lista dei giocatori.',
			'externalPlayer.playerPackageDescription' => 'Inserisci il nome del pacchetto Android dell\'app giocatore, come com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Inserisci il comando del giocatore installato o la strada eseguibile per questo dispositivo.',
			'externalPlayer.playerUrlSchemeDescription' => 'Inserisci lo schema URL e il modello URL opzionale utilizzato per lanciare il giocatore.',
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
			_ => null,
		} ?? switch (path) {
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
			'metadataEdit.quickTag' => 'Tag rapido...',
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
			'trakt.disconnectConfirmBody' => 'PlezyNG smetterà di inviare eventi a Trakt. Puoi riconnetterti quando vuoi.',
			'trakt.scrobble' => 'Scrobbling in tempo reale',
			'trakt.scrobbleDescription' => 'Invia eventi di riproduzione, pausa e arresto a Trakt durante la riproduzione.',
			'trakt.watchedSync' => 'Sincronizza lo stato di visione',
			'trakt.watchedSyncDescription' => 'Quando contrassegni un elemento come visto in PlezyNG, viene contrassegnato come visto anche su Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Connetti Seerr',
			'seerr.serverUrl' => 'URL del server',
			'seerr.serverUrlHelper' => 'L\'indirizzo della tua istanza Seerr',
			'seerr.checkServer' => 'Continua',
			'seerr.signInWithJellyfin' => 'Accedi con Jellyfin',
			'seerr.signInWithEmby' => 'Accedi con Emby',
			'seerr.signInWithLocal' => 'Usa un account locale',
			'seerr.email' => 'Email',
			'seerr.noSignInMethods' => 'Questa istanza Seerr non offre alcun metodo di accesso supportato da PlezyNG.',
			'seerr.instance' => 'Istanza',
			'seerr.disconnectConfirm' => 'Disconnettere Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG rimuoverà questa istanza Seerr. Potrai riconnetterla in qualsiasi momento.',
			'seerr.request' => 'Richiedi',
			'seerr.request4k' => 'Richiedi in 4K',
			'seerr.seasons' => 'Stagioni',
			'seerr.allSeasons' => 'Tutte le stagioni',
			'seerr.advancedOptions' => 'Avanzate',
			'seerr.destinationServer' => 'Server di destinazione',
			'seerr.qualityProfile' => 'Profilo di qualità',
			'seerr.rootFolder' => 'Cartella radice',
			'seerr.languageProfile' => 'Profilo della lingua',
			'seerr.tags' => 'Tag',
			'seerr.noTags' => 'Nessun tag',
			'seerr.defaultOption' => ({required Object name}) => '${name} (predefinito)',
			'seerr.animeNote' => 'Questa serie è un anime.',
			'seerr.requestSubmitted' => 'Richiesta inviata',
			'seerr.requestFailed' => ({required Object error}) => 'Richiesta non riuscita: ${error}',
			'seerr.requestsLoadFailed' => 'Impossibile caricare le opzioni di richiesta',
			'seerr.nothingToRequest' => 'Tutto è già disponibile o richiesto.',
			'seerr.statusAvailable' => 'Disponibile',
			'seerr.statusPartiallyAvailable' => 'Disponibile in parte',
			'seerr.statusRequested' => 'Richiesto',
			'seerr.statusProcessing' => 'In elaborazione',
			'seerr.statusBlocklisted' => 'Nella lista di blocco',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Impossibile raggiungere ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Nessuna istanza Seerr all\'indirizzo ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Un reverse proxy con autenticazione (SSO o autenticazione HTTP) ha risposto al posto di Seerr. PlezyNG non può accedere attraverso di esso: consenti al percorso /api/v1 di Seerr di bypassare il proxy per questa app, oppure usa un indirizzo che raggiunga Seerr direttamente.',
			'seerr.invalidUrl' => 'Inserisci un indirizzo del server come https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Questa istanza Seerr non supporta Quick Connect. È necessaria la versione 3.4 o successiva di Seerr.',
			'seerr.notInitialized' => 'Questa istanza Seerr non ha completato la configurazione iniziale',
			'seerr.noPlexTokenForReauth' => 'Nessun token Plex disponibile per effettuare nuovamente l\'accesso',
			'seerr.noStoredCredentials' => 'Nessuna credenziale salvata disponibile per effettuare nuovamente l\'accesso',
			'seerr.signInRejected' => 'L\'accesso è stato rifiutato',
			'seerr.noSessionCookie' => 'Seerr non ha generato un cookie di sessione',
			'seerr.freshCookieRejected' => 'Seerr ha rifiutato il nuovo cookie di sessione',
			'seerr.noUserInformation' => 'Seerr non ha restituito le informazioni sull\'utente',
			'seerr.sessionRejectedAfterReauth' => 'La sessione è stata rifiutata dopo aver effettuato nuovamente l\'accesso',
			'seerr.permissionDenied' => 'Seerr ha negato questa azione: il tuo account non dispone più dell\'autorizzazione richiesta',
			'seerr.permissionRevoked' => 'Non hai più l\'autorizzazione per richiederlo',
			'services.title' => 'Servizi',
			'services.hubSubtitle' => 'Sincronizza i progressi di visione e richiedi nuovi titoli.',
			'services.integrations' => 'Integrazioni',
			'services.notConnected' => 'Non connesso',
			'services.connectedAs' => ({required Object username}) => 'Connesso come @${username}',
			'services.scrobble' => 'Registra automaticamente i progressi',
			'services.scrobbleDescription' => 'Aggiorna la tua lista quando termini un episodio o un film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Disconnettere ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG smetterà di aggiornare ${service}. Riconnetti quando vuoi.',
			'services.connectFailed' => ({required Object service}) => 'Impossibile connettersi a ${service}. Riprova.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Riconnetti Simkl',
			'services.simklReconnect.subtitle' => 'Simkl sta dismettendo il metodo di accesso usato da questa connessione. La riconnessione apre simkl.com per autorizzare PlezyNG — PlezyNG non vede mai la tua password. La tua cronologia di visione resta su Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Attiva PlezyNG su ${service}',
			'services.deviceCode.instructions' => 'Scansiona il codice QR oppure visita l\'indirizzo qui sotto e inserisci questo codice:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Apri ${service} per attivare',
			'services.deviceCode.copyCode' => 'Copia il codice di attivazione',
			'services.deviceCode.waitingForAuthorization' => 'In attesa di autorizzazione…',
			'services.deviceCode.codeCopied' => 'Codice copiato',
			'services.oauthProxy.title' => ({required Object service}) => 'Accedi a ${service}',
			'services.oauthProxy.body' => 'Scansiona questo codice QR o apri l\'URL su qualsiasi dispositivo.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Apri ${service} per accedere',
			'services.pendingAuth.copyUrl' => 'Copia l\'URL di accesso',
			'services.pendingAuth.urlCopied' => 'URL copiato',
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
			'services.libraryFilter.modeDescription' => 'Scegli se le biblioteche controllate sono bloccate dalla sincronizzazione o sono le uniche biblioteche che sincronizzano.',
			'services.seerrDescription' => 'Connettiti a Seerr o Overseerr per cercare titoli e inviare richieste di media.',
			'services.trackerDescriptions.trakt' => 'Sincronare episodi e film guardati con il tuo account Trakt.',
			'services.trackerDescriptions.mal' => 'Sync anime elenchi e guardare il progresso con MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Sync anime elenchi e guardare il progresso con AniList.',
			'services.trackerDescriptions.simkl' => 'Sync ha guardato film, programmi televisivi e anime con Simkl.',
			'services.trackerDescriptions.mdblist' => 'Mostra valutazioni e elenchi MDBList nelle raccomandazioni e esplora.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Aggiungi server ${product}',
			'addServer.serverUrls' => 'URL del server',
			'addServer.serverUrlsHelper' => 'Sono consentiti più URL, separati da virgole.',
			'addServer.findServer' => 'Trova il server',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Ricerca di server ${product} locali...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Server ${product} locali',
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
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Inserisci l\'URL del server ${product}',
			'addServer.addConnectionTitle' => 'Aggiungi connessione',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Aggiungi a ${name}',
			'addServer.signInWithPlexCard' => 'Accedi con Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorizza questo dispositivo. I server condivisi vengono aggiunti.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorizza un account Plex. Gli utenti Home diventano profili.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Connettiti a ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Inserisci l\'URL del server, il nome utente e la password.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Accedi al tuo server ${product}. Associato a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Prendi in prestito da un altro profilo',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Riutilizza la connessione di un altro profilo. I profili protetti da PIN richiedono un PIN.',
			'addServer.invalidCredentials' => 'Nome utente o password non validi',
			'addServer.authResponseNotJson' => 'La risposta di autenticazione non era un JSON valido',
			'addServer.authResponseIncomplete' => 'La risposta di accesso del server era incompleta',
			'addServer.quickConnectRejected' => 'Quick Connect è stato rifiutato dal server',
			'addServer.quickConnectNotJson' => 'La risposta di Quick Connect non era un JSON valido',
			'addServer.quickConnectMissingFields' => 'Nella risposta di Quick Connect manca un codice o un segreto',
			'addServer.quickConnectPollRejected' => 'Il polling di Quick Connect è stato rifiutato dal server',
			'addServer.serverTimedOut' => 'Il server non ha risposto in tempo',
			'addServer.responseNotJson' => 'La risposta del server non era un JSON valido',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Nella risposta manca un ID o il nome del server: è un server ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Impossibile raggiungere il server: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Inserisci almeno un URL di un server ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Non è stato trovato alcun server ${product} raggiungibile',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Questi URL rimandano a server ${product} diversi',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Questo URL non corrisponde al server ${product}',
			'addServer.redirectUnsupported' => 'Il server ha reindirizzato a un URL non supportato',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Il server ha reindirizzato a un host diverso. Inserisci direttamente l\'URL finale del server ${product}.',
			'addServer.redirectInsecure' => 'Il server ha reindirizzato da HTTPS a un URL non sicuro',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Il server ha reindirizzato a un URL non supportato. Inserisci direttamente l\'URL finale del server ${product}.',
			'addServer.directPlexServerUrl' => 'URL del server Plex',
			'addServer.directPlexServerUrlHelper' => 'Inserisci l\'IP locale e il port del tuo server di media Plex .',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (opzionale)',
			'addServer.plexTokenHelper' => 'Lascia vuoto se l\'accesso senza auth è consentito su questo server.',
			'addServer.plexTokenRequired' => 'Si prega di inserire il tuo token Plex (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (diretto / locale)',
			'addServer.connectDirectPlexCardSubtitle' => 'Connettiti direttamente utilizzando IP o URL locali senza account plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Connettiti direttamente utilizzando IP locale o URL. Connettiti a ${name}.',
			'addServer.insecureTitle' => 'Connessione non crittografata',
			'addServer.insecureDescription' => ({required Object url}) => '${url} usa HTTP. Altre persone sulla rete potrebbero leggere o modificare la password, i token e i contenuti multimediali. Usa HTTPS quando disponibile. Continua solo se ti fidi di questa rete e accetti il rischio.',
			'addServer.allowHttp' => 'Consenti HTTP',
			'addServer.httpsRequired' => 'Utilizzare HTTPS o consentere esplicitamente una connessione non crittografata.',
			'cast.chooseDevice' => 'Cattura a un dispositivo',
			'cast.searching' => 'Cercare i dispositivi di cast...',
			'cast.connectedTo' => ({required Object device}) => 'Connetto a ${device}',
			'cast.device' => 'Dispositivi di Cast',
			'cast.readyToCast' => 'Pronte a lanciare',
			'cast.subtitle' => 'Sottotitoli',
			'cast.serverNotAvailable' => 'Il server dei media non è disponibile.',
			'cast.stopCasting' => 'smettere di casting',
			'cast.castToDevice' => 'Cattura per il dispositivo',
			'cast.noEpisodeAvailable' => 'Non ci sono episodi disponibili per essere lanciati.',
			'cast.startFailed' => 'Non è possibile iniziare la casta. controllare il server e provare di nuovo.',
			'automation.noActivePlayback' => 'Non c’è sessione video attiva da controllare.',
			'notifications.newEpisodeTitle' => 'Nuovo episodio',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Prova ogni funzione gratuita per 7 giorni',
			'appAccess.description' => 'Inizia un test di sette giorni con accesso completo a ogni funzione PlezyNG. non ci sono costi durante il test e non ci sono abbonamenti. Dopo il test, un acquisto di vita al prezzo del tuo negozio rilascia PlezyNG per tutta la vita.',
			'appAccess.trialEndedDescription' => 'Rimuovere ogni funzionalità in PlezyNG per tutta la vita con un acquisto al prezzo del tuo negozio.',
			'appAccess.startTrial' => 'Inizia il mio trial gratuito di 7 giorni',
			'appAccess.trialActive' => 'Il tuo test di 7 giorni è attivo.',
			'appAccess.trialEnded' => 'Il processo di 7 giorni è finito',
			'appAccess.trialStartFailed' => 'Non potevo salvare il test su questo dispositivo. si prega di provare di nuovo.',
			'appAccess.lifetimeTitle' => 'PlezyNG disattivato per la vita',
			'appAccess.lifetimeBody' => 'Grazie! avete accesso a tutti i PlezyNG funzionalità.',
			'appAccess.manageTitle' => 'PlezyNG accesso a vita',
			'appAccess.manageDescription' => 'Prova ogni funzionalità gratuita per 7 giorni, poi disattivare tutto per tutta la vita con un solo pagamento al prezzo del tuo negozio.',
			'appAccess.buy' => ({required Object price}) => 'Rimuovere ogni funzionalità per ${price}',
			'appAccess.loadingPrice' => 'Il prezzo del negozio...',
			'appAccess.retryPrice' => 'Il prezzo di ritorno',
			'appAccess.restore' => 'Ristrutturazione acquisto per tutta la vita',
			'appAccess.pending' => 'L\'acquisto è in attesa di pagamento o approvazione.L\'accesso a tempo pieno si distacca non appena il negozio lo completa.',
			'appAccess.storeUnavailable' => 'Verificare che si è iscritti al negozio e gli acquisti sono consentiti su questo dispositivo.',
			'appAccess.productNotFound' => 'Il disattivatore di vita PlezyNG non è ancora disponibile in questo negozio.',
			'appAccess.productQueryFailed' => 'Non poteva caricare il prezzo del negozio. verificare la connessione e provare di nuovo.',
			'appAccess.purchaseFailed' => 'L’acquisto non è andato via, prova di nuovo.',
			'appAccess.restoreFailed' => 'Non potevo raggiungere il negozio per ripristinare l\'acquisto. prova di nuovo.',
			'appAccess.nothingToRestore' => 'N. PlezyNG acquisto a vita è stato trovato per questo account del negozio.',
			'detail.endsAt' => ({required Object time}) => 'Termina alle ${time}',
			'watchLink.serverUnavailable' => 'Non potevo raggiungere un server Plex per questo link.',
			'watchLink.notFound' => 'Non potevo trovare questo spettacolo o film sui tuoi server Plex.',
			'watchLink.ambiguous' => 'Questo link corrisponde agli elementi su più di un server. Aggiungi un server al link.',
			'watchLink.plexOnly' => 'I link di monitoraggio supportano attualmente solo i server Plex.',
			'watchLink.unsupportedItem' => 'I link di guardare possono aprire solo un programma o un film.',
			'watchLink.menuItem' => 'Visualizza il link',
			'watchLink.dialogTitle' => 'Guarda il link',
			'watchLink.dialogShowHint' => 'Aprire questo link gioca il prossimo episodio. Aggiungi &mode=shuffle alla fine per giocare lo spettacolo su shuffle.',
			'watchLink.dialogMovieHint' => 'Aprire questo link gioca il film.',
			'watchLink.copy' => 'Copia',
			'watchLink.copied' => 'Link copia',
			'homeLayout.title' => 'Home Layout',
			'homeLayout.resetToast' => 'Home Ristrutturazione all\'originale layout Plezy',
			'homeLayout.resetHeroTitle' => 'Ristrutturare il layout del eroe al stock Plezy?',
			'homeLayout.resetHeroBody' => 'Ritorna il set di eroe di ogni riga e riporta il singolo banner rotativo al top di Home, come prima che le riga eroe esistessero.',
			'homeLayout.removeRowTitle' => 'Rimuovere la linea di casa?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} sarà cancellato. non può essere negato.',
			'homeLayout.sync' => 'Sincolo',
			'homeLayout.syncAccountTitle' => 'Sincronti il layout con il tuo account Plex',
			'homeLayout.syncAccountOn' => 'In: questo dispositivo condivide ordine di ordine, righe, Hero e Auto-slide con gli altri dispositivi.',
			'homeLayout.syncAccountOff' => 'Off: questo dispositivo mantiene il suo layout.',
			'homeLayout.syncNow' => 'Sincolo ora',
			'homeLayout.plexHomeManager' => 'Plex Direttore di casa',
			'homeLayout.managePlexRows' => 'Gestione Plex righe in Plezy',
			'homeLayout.managePlexRowsDescription' => 'Aperto per organizzare le righe selezionate in casa',
			'homeLayout.organizeHomeRows' => 'Organizzare le linee di casa',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} righe: movimento, eroe, auto-slide, rimozione',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Organizzare ${library} righe',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Continua a guardare + ${n} righe: movimento, Biblioteca, Home, Eroe, Auto-slide',
			'homeLayout.renderAsHero' => 'Render come carta di eroe',
			'homeLayout.heroOnlySingleCollection' => 'Disponibile solo quando questa fila si risolve ai titoli reali di una singola collezione',
			'homeLayout.hero' => 'Eroe',
			'homeLayout.autoSlide' => 'Auto-Slide',
			'homeLayout.autoSlideDescription' => 'Arrows (PC) e d-pad (TV) sempre funzionano e riavviano il timer.',
			'homeLayout.autoSlideEditDescription' => 'Spegne: si muove solo quando si fa clic su una pistola (PC) o premere sinistra/diretta sul remote (TV).',
			'homeLayout.enableHeroFirst' => 'Permettere il primo eroe',
			'homeLayout.showOnHome' => 'Mostra su Home Screen',
			'homeLayout.home' => 'Home',
			'homeLayout.removeFromHome' => 'Rimuovere da casa',
			'homeLayout.selectRowsFirst' => 'Selezionare le linee di casa sotto prima.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex righe gestite',
			'homeLayout.continueWatching' => 'Continua a guardare',
			'homeLayout.continueWatchingLibraryDescription' => 'La linea di ritorno di questa biblioteca',
			'homeLayout.continueWatchingHomeDescription' => 'La riga di progresso di ritorno mostrata a casa',
			'homeLayout.nextUpHomeDescription' => 'La prossima sequenza di episodi non osservati mostrata separatamente su Home',
			'homeLayout.library' => 'Libreria',
			'homeLayout.showInRecommended' => 'Mostra in Biblioteca raccomandata',
			'homeLayout.customPlexRow' => 'Modello di guida Plex',
			'homeLayout.heroNeedsLibrary' => 'Scopri la biblioteca prima - Hero ha bisogno di qualche parte per mostrare',
			'homeLayout.heroNeedsSurface' => 'Scopri la biblioteca o la casa prima - il protagonista ha bisogno di qualche parte per mostrare',
			'homeLayout.removeHub' => 'Rimuovere Hub',
			'homeLayout.noPlexRows' => 'N. Plex rami gestiti restituiti per questa biblioteca.',
			'homeLayout.openDetails' => 'Dettagli aperti',
			'homeLayout.heroCards' => 'Carte di eroe',
			'homeLayout.tapHeroCard' => 'Scopri una carta di eroe',
			'homeLayout.tvPlayFocus' => 'Remote TV: il pulsante di gioco',
			'homeLayout.tvPlayFocusDescription' => 'D-pad down si ferma sul pulsante Play prima di muoversi alla prossima riga.',
			'homeLayout.tvWrap' => 'Remote TV: carte di eroe di loop',
			'homeLayout.tvWrapDescription' => 'Direttamente sulla ultima carta va di nuovo alla prima. Off si ferma alla ultima carta. La sinistra sulla prima carta va sempre alla barra laterale.',
			'homeLayout.castOnHero' => 'Il cast su banner',
			'homeLayout.castOnHeroDescription' => 'Mostra il cast lungo il fondo di un banner eroico. fuori conserva solo il titolo e il sintesi.',
			'homeLayout.customRows' => 'Riflessioni personalizzate',
			'homeLayout.loading' => 'Il layout di casa...',
			'homeLayout.noCustomRows' => 'Non ci sono ancora linee',
			'homeLayout.addRowHint' => 'Utilizzare Add Home row per creare uno.',
			'homeLayout.addHomeRow' => 'Aggiungi Home Rue',
			'homeLayout.addHomeRowDescription' => 'Selezionare una categoria; la nuova linea viene aggiunta automaticamente all\'Organizzatore',
			'homeLayout.removeRow' => 'Rimuovere la linea',
			'homeLayout.recentlyAdded' => 'Aggiunti di recente',
			'homeLayout.recentlyReleased' => 'Rilasciato di recente',
			'homeLayout.movieCollections' => 'Film Collezioni',
			'homeLayout.showCollections' => 'Mostra le collezioni',
			'homeLayout.rowTitle' => 'Titolo Row',
			'homeLayout.content' => 'contenuto',
			'homeLayout.showThisRowIn' => 'Mostra questa riga in:',
			'homeLayout.libraryRecommended' => 'Biblioteca raccomandata',
			'homeLayout.heroCard' => 'Carta di eroe',
			'homeLayout.heroCardDescription' => 'Mostra come una carta di rotazione a larghezza completa invece di un poster shelf.',
			'homeLayout.heroUnavailableDescription' => 'Disponibile solo quando questa fila si risolve ai titoli reali di una singola collezione - con più di una collezione selezionata non c\'è nessun titolo da girare.',
			'homeLayout.librariesSelection' => 'Librerie (solo non controllate per includere ogni biblioteca)',
			'homeLayout.librariesMergedDescription' => 'Ogni biblioteca che si verifica qui è unita in questa una fila.',
			'homeLayout.movieCollectionsSelection' => 'Collezioni di film (solo non controllate per ogni biblioteca selezionata)',
			'homeLayout.showCollectionsSelection' => 'Mostra collezioni (solo non controllate per ogni biblioteca selezionata)',
			'homeLayout.collectionRowsDescription' => 'Se esattamente una collezione si compie, i suoi titoli si mostrano direttamente nella fila.Se più di una collezione, ogni collezione si mostra come un unico poster - premere per aprire quella collezione.',
			'homeLayout.allCollections' => 'Tutte le collezioni',
			'homeLayout.noRowsHere' => 'Non ci sono ancora linee.',
			'homeLayout.hideWatchedRows' => 'Scopri gli oggetti osservati in serie',
			'homeLayout.hideWatchedRowsDescription' => 'Titoli completamente guardati lasciare Home e biblioteca Raggiunta raccomandata.',
			'homeLayout.untitledCollection' => 'Collezione senza titolo',
			'homeLayout.moveRowHint' => 'Up/Down: spostare la linea · Selezionare: lasciarlo qui · Ritorno: cancellare',
			'homeLayout.organizeRowsHint' => 'Selezionare una riga (o tenere Selezionare): spostarlo · Sinistra/Destra: opzioni di riga · Ritorno: fatto',
			'homeLayout.layoutNavDescription' => 'Scegliere le righe, le biblioteche e le categorie di raccolta',
			'homeLayout.editHomeRow' => 'Edit Home Ronde',
			'homeLayout.resetHeroButton' => 'Ristrutturare il layout del eroe in stock Plezy',
			'homeLayout.reorderingUnlocked' => 'Ristrutturazione disattivata',
			'homeLayout.reorderingLocked' => 'Ristrutturazione chiusa',
			'homeLayout.rowsCanBeDragged' => 'Le corde possono essere tracciate - tappa il blocco per evitare che',
			'homeLayout.tapLockToDrag' => 'Toccare il blocco per tirare le righe',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Numero di lavoro: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Nascondi',
			'homeLayout.remove' => 'Rimuovi',
			'homeLayout.libraryResumeRow' => 'La rivista della biblioteca è',
			'homeLayout.pressAgainToDelete' => 'Premere di nuovo per cancellare',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'di',
			'homeLayout.resetHeroButtonDescription' => 'Ritorna il set di eroe di ogni riga e riporta il singolo banner rotante in cima, come prima che le riga eroe esistessero.',
			'homeLayout.tapHeroCardDescription' => 'Selezionare se tappando o selezionando una carta Hero inizia la riproduzione o si aprono i suoi dettagli.',
			'homeLayout.heroTapPlayDescription' => 'Inizia subito l’oggetto selezionato.',
			'homeLayout.heroTapDetailsDescription' => 'Apri i dettagli dell\'oggetto selezionato prima di scegliere un\'azione.',
			'platform.localNetworkPermission' => 'PlezyNG connette ai tuoi server multimediali e dispositivi di riproduzione sulla tua rete locale.',
			'platform.locationPermission' => 'PlezyNG utilizza l\'accesso alla localizzazione quando iOS lo richiede per rilevare la tua rete locale e connetterti ai tuoi server multimediali.',
			'platform.photoLibraryPermission' => 'Scegli immagini dalla tua libreria fotografica da usare come copertine e illustrazioni dei contenuti multimediali.',
			'platform.cameraPermission' => 'Scansione QR per unirsi a un Companion Remote.',
			'universalMedia.title' => 'Media aperte',
			'universalMedia.shortcutHelp' => 'Gioca un link, playlist o file per questa sessione.',
			'universalMedia.intro' => 'Apri un link, playlist o file. Playback utilizza il lettore standard di PlezyNG e non aggiunge storia alla tua biblioteca.',
			'universalMedia.openWhat' => 'Cosa vorresti aprire?',
			'universalMedia.stream' => 'Indirizzo Stream',
			'universalMedia.playlist' => 'giocattoli',
			'universalMedia.files' => 'Dispositivi di file',
			'universalMedia.favorites' => 'Salva i tuoi preferiti',
			'universalMedia.address' => 'Indirizzo Media',
			'universalMedia.addressHelp' => 'Gli URL con parametri di credenziale o di firma riconosciuti sono utilizzati solo per questa sessione e non possono essere salvati come preferiti.',
			'universalMedia.displayName' => 'Nome di visualizzazione (opzionale)',
			'universalMedia.displayNameHelp' => 'Scegli un nome corto per il giocatore e i controlli dei media del sistema.',
			'universalMedia.allowHttp' => 'Permettere una connessione HTTP non crittografata',
			'universalMedia.allowHttpHelp' => 'HTTP non crittografa la connessione. permetterla solo su una rete affidata. utilizzare HTTPS quando possibile.',
			'universalMedia.advancedProtocols' => 'MPV solo: inserisci un indirizzo RTSP, RTMP/RTMPS, UDP o RTP. Questi indirizzi non possono essere salvati come preferiti.',
			'universalMedia.liveStream' => 'trattare come vivo',
			'universalMedia.liveStreamHelp' => 'Utilizzare questo per video o radio dal vivo.L\'app nasconde la barra del tempo, i pulsanti di scoppio e l\'opzione go-to-time.',
			'universalMedia.privateSession' => 'Solo questa riproduzione utilizza l\'indirizzo. Salva un streaming idoneo preferito per tenerlo in questo profilo.',
			'universalMedia.saveFavorite' => 'Salva i tuoi preferiti',
			'universalMedia.playNow' => 'Gioca ora',
			'universalMedia.favoriteSaved' => 'Stream preferito salvato a questo profilo',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Scappato ${count} ingresso di playlist non supportato o insicuro.', many: 'Scappato ${count} ingressi di playlist non supportati o insicuri.', other: 'Scappato ${count} ingressi di playlist non supportati o insicuri.', ), 
			'universalMedia.playlistAddress' => 'Indirizzo Playlist',
			'universalMedia.playlistAddressHelp' => 'Apri una playlist M3U, M3u8, o PLS da un indirizzo web. link di streaming diretto non salvi la playlist.',
			'universalMedia.choosePlaylist' => 'Scegli il file di playlist',
			'universalMedia.openPlaylist' => 'L\'apertura del playlist',
			'universalMedia.playlistFormatsHelp' => 'Una playlist può contenere fino a 1.000 articoli e 2 MB. HLS si manifesta aperto come flussi in modo che il giocatore possa scegliere una qualità.',
			'universalMedia.saveQueuePlaylist' => 'Salva la coda come playlist',
			'universalMedia.queuePlaylistSaved' => 'La playlist è stata salvata accanto ai file multimediali.',
			'universalMedia.queuePlaylistUnavailable' => 'Questa coda non può essere salvata come playlist locale riutilizzabile.',
			'universalMedia.queuePlaylistFolderRequired' => 'Scegli una posizione nella stessa cartella dei file in coda.',
			'universalMedia.noFavorites' => 'Non è stato ancora salvato il flusso dei preferiti. i preferiti rimangono in questo profilo.',
			'universalMedia.removeFavorite' => 'Rimuovere streaming preferito',
			'universalMedia.filesHelp' => 'Selezionare file audio, video o ISO per una coppia temporanea. File e URL non vengono aggiunti alla storia della biblioteca.',
			'universalMedia.chooseFiles' => 'Scegli i file',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: '1 file selezionati', many: '${count} file selezionati', other: '${count} file selezionati', ), 
			'universalMedia.wifiTransfer' => 'Invia file tramite Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Trasferire i file supportati da un browser sulla stessa rete affidata.',
			'universalMedia.wifiTransferIntro' => 'Apri questo indirizzo in un browser su un altro dispositivo. Scegli i file per aggiungerli alla libreria dei file e dei libri di questo dispositivo.',
			'universalMedia.wifiTransferPrivacy' => 'Questo dispositivo riceve file attraverso la tua rete locale. chiunque conosce questo indirizzo può inviare file fino a quando non si ferma il trasferimento o l\'indirizzo scade dopo 15 minuti. massimo: 100 file, 4 GiB per file, 10 GiB totale.',
			'universalMedia.wifiTransferStarting' => 'La preparazione di un trasferimento privato, a tempo limitato ...',
			'universalMedia.wifiTransferUnavailable' => 'Non è possibile avviare il trasferimento. verificare l\'accesso alla rete locale e provare di nuovo.',
			'universalMedia.openThisAddress' => 'Apri uno di questi indirizzi sul dispositivo di spedizione',
			'universalMedia.copyAddress' => 'Indirizzo di trasferimento',
			'universalMedia.addressCopied' => 'Indirizzo di trasferimento copiato',
			'universalMedia.transferExpires' => ({required Object time}) => 'Questo indirizzo scade in ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(n, one: 'Il file ${count} ricevuto', many: 'I file ${count} ricevuti', other: 'I file ${count} ricevuti', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Ricevuto ${size}',
			'universalMedia.stopTransfer' => 'Smettere di trasferire e invalidare l\'indirizzo',
			'universalMedia.startTransfer' => 'Inizia il trasferimento',
			'universalMedia.wifiImportedFiles' => 'Trasferimento Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Invia file a PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Selezionare file audio, video, ebook o comic per inviare. i file vengono salvati nella libreria dei file e dei libri di questo dispositivo. massimo: 100 file, 4 GiB per file, 10 GiB totale.',
			'universalMedia.uploadFilesLabel' => 'I file da inviare',
			'universalMedia.uploadSelected' => 'Scarica i file selezionati',
			'universalMedia.uploadSelectFirst' => 'Selezionare uno o più file prima.',
			'universalMedia.uploading' => 'Inviare',
			'universalMedia.uploadComplete' => 'Il file è stato aggiunto a PlezyNG.',
			'universalMedia.uploadFailed' => 'Il file non può essere aggiunto. tenere aperta questa pagina e provare di nuovo.',
			'universalMedia.liveCue' => 'Il vivo',
			'universalMedia.liveSession' => 'Il Live Stream',
			'universalMedia.liveCueHelp' => 'Per video o radio dal vivo, l\'app nasconde la barra del tempo e scapa i pulsanti. non salva l\'indirizzo o la storia di visualizzazione.',
			'universalMedia.sessionOnly' => 'Questo playback è solo sessione',
			'universalMedia.sessionOnlyHelp' => 'Playback non salva mai progresso o storia.Salva il flusso come preferito per tenerlo in questo profilo se è idoneo.',
			'universalMedia.pictureAdjustments' => 'Immagini adattamenti',
			'universalMedia.pictureHelp' => 'Questi cambiamenti di immagine influenzano solo questa riproduzione. si riavviano quando la ripresa finisce.',
			'universalMedia.resetPicture' => 'Ristrutturazione immagine',
			'universalMedia.brightness' => 'Il brillo',
			'universalMedia.contrast' => 'Contrasto',
			'universalMedia.gamma' => 'Il Gamma',
			'universalMedia.hue' => 'di Hue',
			'universalMedia.saturation' => 'Saturazione',
			'universalMedia.view360' => 'Visualizzazione a 360° video',
			'universalMedia.view360Help' => 'Utilizzare questo per il video 360° equidirezionale. MPV ha bisogno del filtro v360 di FFmpeg per questa visualizzazione.',
			'universalMedia.view360Unavailable' => 'Questa configurazione MPV non potrebbe applicare il filtro a 360°.',
			'universalMedia.view360Yaw' => 'Visione orizzontale',
			'universalMedia.view360Pitch' => 'Vista verticale',
			'universalMedia.view360FieldOfView' => 'campo di visione',
			'universalMedia.recordStream' => 'Recensione di Live Stream',
			'universalMedia.stopRecording' => 'Smettere e salvare la registrazione',
			'universalMedia.recordingStarted' => 'La registrazione è attiva. Lasciare il riproduzione si ferma e salva la registrazione.',
			'universalMedia.recordingSaved' => 'La registrazione è finita e salvata.',
			'universalMedia.recordingActive' => 'Lasciare il riproduzione si ferma e lo salva.',
			'universalMedia.recordingFormatHelp' => 'Per video, scegliere MKV o MPEG-TS. per audio, scegliere MKA o MKV.',
			'universalMedia.replaceRecordingTitle' => 'Sostituisci questa registrazione?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG ripara il file esistente durante la registrazione. se non riesce a salvare la nuova registrazione, Plezy NG ripristina il backup.',
			'universalMedia.replaceRecording' => 'sostituire il file',
			'universalMedia.discHelp' => 'Apri un disco in questa scheda ottica del computer. Puoi anche aprire un\'immagine ISO dai file Device.',
			'universalMedia.discs' => 'Il disco ottico',
			'universalMedia.editionOrTitle' => 'Edizione o titolo del disco',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Il Blu-ray',
			'universalMedia.audioCd' => 'CD audio',
			'universalMedia.discAvailability' => 'La riproduzione dei dischi richiede un compost MPV compatibile, una scheda supportata e un permesso del sistema operativo. non può superare la protezione del disco commerciale.',
			'universalMedia.converterTitle' => 'Convertire un file di media locale',
			'universalMedia.converterHelp' => 'Convertire un file locale o rimuoverlo con FFmpege il',
			'universalMedia.converterIntro' => 'Convertire un file audio o video locale in un formato che funziona su più dispositivi.',
			'universalMedia.converterPrivacy' => 'FFmpeg deve essere installato su questo computer. Conversione legge solo i file locali. Non scarica i flussi o rimuove DRM.',
			'universalMedia.converterChooseInput' => 'Scegli un file di media locale',
			'universalMedia.converterFormat' => 'Formato di uscita',
			'universalMedia.converterMp4' => 'MP4 · H.264 e AAC',
			'universalMedia.converterM4a' => 'M4A · AAC audio',
			'universalMedia.converterMp3' => 'MP3 e audio',
			'universalMedia.allowFtp' => 'Permesso FTP',
			'universalMedia.allowFtpHelp' => 'FTP trasmette i media senza crittografia. utilizza solo su reti affidate.',
			'universalMedia.converterSaveAs' => 'Conservare i media convertiti come',
			'universalMedia.converterExtensionMismatch' => 'Scegli un nome di file con l\'estensione di uscita selezionata.',
			'universalMedia.converterUnsupportedInput' => 'Scegli un file audio o video.',
			'universalMedia.converterLocalOnly' => 'Il file selezionato non è disponibile come percorso di dispositivo locale.',
			'universalMedia.converterReplaceTitle' => 'Sostituisci questo file?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG rimborserà il file esistente fino a quando la copia convertita non sarà salvata.',
			'universalMedia.converterStarting' => 'A partire da FFmpeg...',
			'universalMedia.converterProgress' => 'Conversione su questo computer...',
			'universalMedia.converterComplete' => 'Conversione completa: il nuovo file è pronto.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg è mancato o non supporta questo formato.',
			'universalMedia.converterFailed' => 'Verificare che il file sorgente può essere letto e la destinazione ha abbastanza spazio gratuito.',
			'universalMedia.converterCancelled' => 'La conversione è stata cancellata. il risultato incompleto è stato rimosso.',
			'universalMedia.converterDesktopOnly' => 'La conversione locale è disponibile su computer desktop con FFmpeg installato.',
			'universalMedia.converterStart' => 'Convertire file',
			'universalMedia.mediaToolsTitle' => 'Strumenti di Media',
			'universalMedia.mediaToolsShortcut' => 'Raccogliere o condividere i media, aggiungere estensioni di ricerca o utilizzare la linea di comando.',
			'universalMedia.mediaToolsIntro' => 'Scegli un strumento focalizzato. cattura e usare il flusso di FFmpeg installato su questo desktop. estensioni e comandi CLI utilizzano richieste HTTPS limitate e il flusso Open media esistente.',
			'universalMedia.mediaToolsAccessibility' => 'Le scelte degli strumenti e i controlli funzionano con touch, indicatore, tastiera e focalizzazione D-pad. I cambiamenti dello stato di registrazione, condivisione e ricerca sono annunciati.',
			'universalMedia.mediaTool' => 'Strumento Media',
			'universalMedia.captureIntro' => 'Inserisci lo schermo o la fotocamera in un file MP4 su questo computer. FFmpeg deve essere installato e include il codice H.264.',
			'universalMedia.captureNoDevices' => 'Nessun schermo o fotocamera è stato trovato. verificare FFmpeg supporto per la cattura e le autorizzazioni per la privacy del sistema operativo.',
			'universalMedia.captureSource' => 'schermo o fotocamera',
			'universalMedia.captureScreen' => 'schermo',
			'universalMedia.captureAudioSource' => 'Introduzione audio (opzionale)',
			'universalMedia.captureAudioHelp' => 'Aggiungi audio da un microfono o input disponibili. le scelte del dispositivo dipendono da FFmpeg e le autorizzazioni del sistema.',
			'universalMedia.captureAudioNone' => 'Nessun audio',
			'universalMedia.captureDefaultAudio' => 'Introduzione audio',
			'universalMedia.captureWaylandHelp' => 'Wayland limita questa cattura XWayland al X display. Windows al di fuori di XWayland non può apparire.',
			'universalMedia.captureFrameRate' => 'Tasso di registrazione frame rate',
			_ => null,
		} ?? switch (path) {
			'universalMedia.capturePrivacy' => 'La registrazione viene salvata solo al file che scegli. la registrazione del microfono è facoltativa. PlezyNG non carica la registrazione.',
			'universalMedia.captureSaveAs' => 'Salva la registrazione dello schermo come',
			'universalMedia.captureExtensionMismatch' => 'Scegli un nome di file che finisce in .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg o il codificatore video H.264 non è disponibile. Installare una costruzione FFmpeg supportata, poi provare di nuovo.',
			'universalMedia.captureFailed' => 'Controlla il permesso del dispositivo, il storage disponibile e il supporto FFmpeg.',
			'universalMedia.captureSaved' => 'Screen record salvato.',
			'universalMedia.captureElapsedLabel' => 'Tempo di registrazione',
			'universalMedia.captureStart' => 'Inizia la registrazione',
			'universalMedia.capturePreview' => 'Anteprima nel lettore',
			'universalMedia.capturePreviewHelp' => 'Visualizza un’anteprima della sorgente selezionata nel lettore standard. È limitata a questa sessione e non salva una registrazione. Il supporto dei dispositivi e le autorizzazioni dipendono da MPV e dal sistema operativo. L’anteprima usa solo il video; le registrazioni salvate possono includere audio facoltativo.',
			'universalMedia.capturePreviewActive' => 'Anteprima in diretta · nessuna registrazione',
			'universalMedia.captureStop' => 'Stop e salvare',
			'universalMedia.captureMode' => 'cattura',
			'universalMedia.shareMode' => 'Condividi',
			'universalMedia.shareIntro' => 'Invia un file di media locale ad un altro dispositivo sulla tua rete privata. PlezyNG crea un flusso temporaneo HLS.',
			'universalMedia.sharePrivacy' => 'Chiunque nella tua rete locale che riceve il link privato può guardare mentre è attivo. il link scade dopo 60 minuti. smettere di condividere per chiudere il server e annullare il link.',
			'universalMedia.shareChooseFile' => 'Selezionare file di media',
			'universalMedia.shareChooseHelp' => 'Selezionare un file audio o video locale. il file rimane su questo computer.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg o i codificatori H.264/AAC non sono disponibili. Installare FFmpeg con H.264 e AAC codifica supporto.',
			'universalMedia.shareFailed' => 'Il flusso non poteva iniziare o fermarsi inaspettatamente. controllare FFmpeg e l\'accesso alla rete.',
			'universalMedia.shareActive' => 'Il flusso è pronto sulla tua rete privata.',
			'universalMedia.shareEnded' => 'I media hanno raggiunto la fine e non vengono più condivisi.',
			'universalMedia.shareStopped' => 'La condivisione è sospesa. il link temporaneo non è più valido.',
			'universalMedia.shareUrlCopied' => 'L’indirizzo di posta elettronica è copiato.',
			'universalMedia.shareOpenUrl' => 'Aprire questo indirizzo in un giocatore sull\'altro dispositivo',
			'universalMedia.shareQrLabel' => 'Il codice QR per l’indirizzo temporaneo',
			'universalMedia.shareQrHelp' => 'Scansione con un giocatore compatibile connesso alla stessa rete privata.',
			'universalMedia.shareHttpHint' => 'Questo flusso utilizza HTTP non crittografato. in PlezyNG, permettere HTTP prima di aprire.',
			'universalMedia.shareCopyUrl' => 'Indirizzo Stream',
			'universalMedia.shareExpiresLabel' => 'Il link scade a',
			'universalMedia.shareStarting' => 'Preparando il flusso...',
			'universalMedia.shareStart' => 'Inizia la condivisione',
			'universalMedia.shareStop' => 'smettere di condividere',
			'universalMedia.extensionsMode' => 'L\'estensione e CLI',
			'universalMedia.extensionsIntro' => 'Aggiungi un\'estensione di ricerca dati solo per trovare i media. Scegli un risultato per caricarlo nel familiare modulo Open media.',
			'universalMedia.extensionsPrivacy' => 'Un manifesto può definire uno HTTPS campo di ricerca e mappa risposta. non può eseguire il codice, aggiungere titoli di richiesta, leggere i file, o lanciare comandi shell.',
			'universalMedia.extensionImport' => 'Aggiungi manifesto di estensione',
			'universalMedia.extensionEmpty' => 'Non ci sono ancora servizi di ricerca. Scegli un file manifesto JSON affidabile per aggiungere uno.',
			'universalMedia.extensionChoose' => 'Servizio di ricerca',
			'universalMedia.extensionSearchConsent' => 'Ogni ricerca invia le tue parole a questo servizio HTTPS. i risultati si aprono solo dopo aver selezionato uno.',
			'universalMedia.extensionSearchLabel' => 'Media di ricerca',
			'universalMedia.extensionSearch' => 'La ricerca',
			'universalMedia.extensionSearching' => 'La ricerca...',
			'universalMedia.extensionNoResults' => 'Non sono stati riportati risultati di media sicuri. prova un\'altra ricerca.',
			'universalMedia.extensionInstallTitle' => 'Aggiungi questo servizio di ricerca?',
			'universalMedia.extensionReplaceTitle' => 'Aggiornare questo servizio di ricerca?',
			'universalMedia.extensionService' => 'Servizio',
			'universalMedia.extensionEndpoint' => 'HTTPS punto finale',
			'universalMedia.extensionConsent' => 'Il testo di ricerca viene inviato a questo servizio. il manifesto non contiene codice eseguibile. Continua solo se ti confidi questo punto finale.',
			'universalMedia.extensionInstall' => 'Aggiungi servizio',
			'universalMedia.extensionReplace' => 'Aggiornamento servizio',
			'universalMedia.extensionRemoveTitle' => 'Rimuovere questo servizio di ricerca?',
			'universalMedia.extensionRemoveHelp' => 'Questo rimuove il servizio da questo profilo. PlezyNG non contatta il suo punto finale.',
			'universalMedia.extensionRemove' => 'Rimuovere il servizio',
			'universalMedia.extensionInvalidManifest' => 'Questo file non è un manifesto di estensione supportato. vedi la guida Open media per il formato.',
			'universalMedia.extensionSaveFailed' => 'L\'estensione non poteva essere salvata al profilo attivo.',
			'universalMedia.extensionSearchFailed' => 'Il servizio di ricerca non ha restituito una risposta valida. verificare il punto di fine e provare di nuovo.',
			'universalMedia.cliTitle' => 'linea di comando',
			'universalMedia.cliHelp' => 'Utilizzare la guida plezyctl per valutare un manifesto o cercare la stessa estensione. rivedere il suo servizio HTTPS prima di ogni ricerca. Risultati aperti nel modulo media esistente; selezionare il pulsante ripresa per iniziare.',
			'universalMedia.cliCopyExample' => 'Copia il comando esempio',
			'universalMedia.cliCopied' => 'Esempio di comando copiato.',
			'fileSources.title' => 'Fili e libri',
			'fileSources.subtitle' => 'Leggi, ascolta e guarda dai tuoi file.',
			'fileSources.add' => 'Aggiungi fonte',
			'fileSources.importFiles' => 'Importazione file',
			'fileSources.localFiles' => 'su questo dispositivo',
			'fileSources.source' => 'Fonte',
			'fileSources.name' => 'Nome',
			'fileSources.endpoint' => 'URL del server',
			'fileSources.smbEndpointHint' => 'Esempio: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Inserisci un server SMB e una cartella condivisa.',
			'fileSources.root' => 'Foldere o prefix',
			'fileSources.smbFolderHelp' => 'Lascia vuoto per usare l’intera cartella condivisa, oppure inserisci una cartella al suo interno.',
			'fileSources.username' => 'Nome utente',
			'fileSources.smbDomain' => 'Dominio (facoltativo)',
			'fileSources.password' => 'Password',
			'fileSources.token' => 'API Toccano',
			'fileSources.accessKey' => 'ID chiave di accesso',
			'fileSources.secretKey' => 'Key di accesso segreto',
			'fileSources.sessionToken' => 'Il token sessione (opzionale)',
			'fileSources.region' => 'Regione',
			'fileSources.clientId' => 'ID client di OAuth',
			'fileSources.clientSecret' => 'OAuth client secret (solo Google desktop)',
			'fileSources.allowHttp' => 'Consenti HTTP non crittografato su una rete attendibile',
			'fileSources.smbEncryption' => 'Crittografa la connessione SMB3',
			'fileSources.smbEncryptionHint' => 'Usa la crittografia SMB3 quando il NAS la supporta.',
			'fileSources.connect' => 'Connetti',
			'fileSources.cancel' => 'Annulla',
			'fileSources.save' => 'Salva',
			'fileSources.close' => 'Chiudi',
			'fileSources.removeSource' => 'Sconnetti fonte',
			'fileSources.disconnectMessage' => 'Disconnettere questa fonte? I file scaricati e la cronologia di lettura e ascolto resteranno su questo dispositivo.',
			'fileSources.localFolder' => 'Scegliamo la cartella',
			'fileSources.empty' => 'Ancora niente qui',
			'fileSources.emptyHint' => 'Aggiungi una fonte o importare un libro, un libro audio, musica o video.',
			'fileSources.search' => 'Cerca questo folder',
			'fileSources.searchCached' => 'La ricerca della biblioteca salvata',
			'fileSources.refresh' => 'Aggiorna',
			'fileSources.loadMore' => 'Carica di più',
			'fileSources.offline' => 'Disponibile offline',
			'fileSources.download' => 'Rimanere offline',
			'fileSources.removeDownload' => 'Rimuovere offline copia',
			'fileSources.continueReading' => 'Continua a leggere',
			'fileSources.continueListening' => 'Continua ad ascoltare',
			'fileSources.continueWatching' => 'Continua a guardare',
			'fileSources.read' => 'Leggi',
			'fileSources.listen' => 'Ascolta',
			'fileSources.play' => 'Riproduci',
			'fileSources.pause' => 'Pausa',
			'fileSources.stop' => 'Interrompi',
			'fileSources.startOver' => 'Inizia il',
			'fileSources.finished' => 'Terminato',
			'fileSources.markFinished' => 'Marco finito',
			'fileSources.markUnfinished' => 'Marchio Infinito',
			'fileSources.editions' => 'Edizioni e file',
			'fileSources.chapters' => 'Capitoli',
			'fileSources.bookmarks' => 'Note e note',
			'fileSources.bookmark' => 'Aggiungi Bookmark',
			'fileSources.highlight' => 'L’accento',
			'fileSources.note' => 'Nota',
			'fileSources.delete' => 'Elimina',
			'fileSources.export' => 'Notizie di esportazione',
			'fileSources.exported' => 'Notizie esportate',
			'fileSources.sync' => 'Sincolo Progresso',
			'fileSources.synced' => 'Progresso sintetizzato',
			'fileSources.conflict' => 'Un altro dispositivo ha una posizione diversa. scegliere dove continuare.',
			'fileSources.useLocal' => 'Utilizzare questo dispositivo',
			'fileSources.useRemote' => 'Utilizzare altri dispositivi',
			'fileSources.history' => 'Storia della posizione',
			'fileSources.groupAudio' => 'Ascoltare come un libro audio',
			'fileSources.groupHint' => 'Combina i file audio attualmente caricati in questa cartella. caricare tutte le pagine prima.',
			'fileSources.order' => 'Ordine di file',
			'fileSources.moveUp' => 'Move in alto',
			'fileSources.moveDown' => 'Move verso il basso',
			'fileSources.speed' => 'velocità di playback',
			'fileSources.sleep' => 'Timer di spegnimento',
			'fileSources.sleepOff' => 'Disattivato',
			'fileSources.endChapter' => 'La fine del capitolo',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('it'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuti', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuti', ), 
			'fileSources.skipBack' => 'Scoppia indietro',
			'fileSources.skipForward' => 'Scomparsa in avanti',
			'fileSources.smartRewind' => 'Il ritorno intelligente dopo una pausa',
			'fileSources.playbackOptions' => 'Opzioni di ascolto',
			'fileSources.remaining' => ({required Object time}) => '${time} rimanente',
			'fileSources.contents' => 'contenuto',
			'fileSources.readerSettings' => 'Leggi le impostazioni',
			'fileSources.fontSize' => 'Testo di dimensioni',
			'fileSources.lineHeight' => 'Linee di spazzatura',
			'fileSources.margin' => 'Margini',
			'fileSources.font' => 'Tipo di faccia',
			'fileSources.serif' => 'serif',
			'fileSources.sans' => 'Senza serif',
			'fileSources.mono' => 'Monospacio',
			'fileSources.columns' => 'Colonne',
			'fileSources.scroll' => 'Scorrere verticalmente',
			'fileSources.justify' => 'giustificare il testo',
			'fileSources.readerTheme' => 'Apparire pagina',
			'fileSources.appTheme' => 'Seguire app tema',
			'fileSources.paper' => 'Carta',
			'fileSources.sepia' => 'Setti',
			'fileSources.night' => 'Notte',
			'fileSources.readAloud' => 'Leggi questa pagina ad alta voce',
			'fileSources.readAlong' => 'Leggi tutto',
			'fileSources.stopReading' => 'smettere di narrazione',
			'fileSources.searchBook' => 'La ricerca nel libro',
			'fileSources.noMatches' => 'Nessun match',
			'fileSources.previousPage' => 'Pagina precedente',
			'fileSources.nextPage' => 'Pagina successiva',
			'fileSources.page' => ({required Object number}) => 'Pagina ${number}',
			'fileSources.externalBlocked' => 'I link esterni del libro sono disabilitati nel lettore.',
			'fileSources.loading' => 'Apertura...',
			'fileSources.narrator' => 'narratore',
			'fileSources.audio' => 'Audio',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'ebook',
			'fileSources.all' => 'Tutto',
			'fileSources.downloads' => 'Fili di Offline',
			'fileSources.confirmDelete' => 'Rimuovere la copia offline selezionata? la tua posizione e le note rimarranno.',
			'fileSources.errorAuthentication' => 'Iscriviti di nuovo per riconnettere questa fonte.',
			'fileSources.errorPermission' => 'Questa fonte non ha fornito accesso al file richiesto.',
			'fileSources.errorUnavailable' => 'La fonte non è disponibile. prova di nuovo, o apri una copia offline.',
			'fileSources.errorUnsupported' => 'Questo formato o connessione non è supportato su questo dispositivo.Vedi la guida di impostazione della fonte.',
			'fileSources.errorInvalidData' => 'Questo file o risposta del server non può essere letto in modo sicuro.',
			'fileSources.errorCancelled' => 'L’operazione è stata annullata.',
			'fileSources.errorConflict' => 'La posizione è cambiata in un\'altra sessione. riaprirlo per selezionare una posizione.',
			'fileSources.signIn' => 'Accedi',
			'fileSources.reconnect' => 'Riconnetti',
			'fileSources.folderHelp' => 'Lascia la riga per iniziare alla radice sorgente. URL S3 includono il bucket.',
			'fileSources.preferences' => 'Preferenze',
			'fileSources.timePosition' => 'Posizione',
			'fileSources.audioTrack' => 'Audio trazione',
			'fileSources.subtitleTrack' => 'Il sottotitolo traggio',
			'fileSources.none' => 'Nessuno',
			'fileSources.fullscreen' => 'schermo completo',
			'fileSources.syncLocation' => 'Fornitura di Progress Sync (opzionale)',
			'fileSources.syncLocationHint' => 'Una cartella dedicata WebDAV per PlezyNG stato. utilizza scrittura condizionale; i media rimangono invariati.',
			'fileSources.audiobooks' => 'Audiolibri',
			'fileSources.comics' => 'Fumetti',
			'fileSources.scan' => 'Scansione dei libri e dei media',
			'fileSources.browserReader' => 'Il lettore aperto',
			'fileSources.browserReaderHelp' => 'Il lettore è aperto nel tuo browser. Mantenere aperto PlezyNG per salvare il tuo posto e note.',
			'fileSources.on' => 'di',
			'fileSources.advancedSetup' => 'App di registrazione',
			'fileSources.microsoftSignIn' => 'Iscriviti con Microsoft',
			'fileSources.zoomIn' => 'Ingrandisci',
			'fileSources.zoomOut' => 'Zoom fuori',
			'fileSources.fitPage' => 'Pagina adeguata',
			'fileSources.fitWidth' => 'adeguato larghezza',
			'fileSources.actualSize' => 'Dimensioni attuali',
			'fileSources.goToPage' => 'Vai alla pagina',
			'fileSources.goToSection' => 'Vai al capitolo',
			'fileSources.pageRange' => ({required Object count}) => 'Inserisci un numero da 1 a ${count}',
			'fileSources.pageLayout' => 'Il layout della pagina',
			'fileSources.automatic' => 'Automatico',
			'fileSources.singlePage' => 'Una pagina unica',
			'fileSources.twoPages' => 'Due pagine',
			'fileSources.readingDirection' => 'La direzione di lettura',
			'fileSources.leftToRight' => 'A sinistra a destra',
			'fileSources.rightToLeft' => 'Da destra a sinistra',
			'fileSources.letterSpacing' => 'Lettera spazzatura',
			'fileSources.wordSpacing' => 'Parola spazzatura',
			'fileSources.readerControlsHelp' => 'Allontana due dita o usa i controlli dello zoom per ingrandire le pagine. Trascina per spostare la pagina. Ctrl/⌘ con + o − regola lo zoom; Ctrl/⌘ con 0 lo reimposta. Page Up e Page Down cambiano pagina.',
			'fileSources.imagePage' => 'Pagina di fumetto',
			'fileSources.resetReader' => 'Ristrutturare le preferenze di lettura',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Utilizzare file e libri',
			'fileSources.cancelScan' => 'Cancelare la scansione',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Limiti di download offline',
			'fileSources.offlineQuotaHelp' => 'Configurare lo spazio massimo utilizzato da copie offline, file importati e download corrotti. La riduzione del limite non rimuove le copie esistenti.',
			'fileSources.offlineStorageUsage' => 'Storaggio Offline',
			'fileSources.reservedStorage' => 'riservato',
			'fileSources.downloadQueue' => 'Scarica il Queue',
			'fileSources.downloadRunning' => 'Scarica',
			'fileSources.downloadQueued' => 'Aspettando',
			'fileSources.downloadPaused' => 'Pausa',
			'fileSources.downloadFailed' => 'La necessità di ritorno',
			'fileSources.importing' => 'Importazione',
			'fileSources.importInterrupted' => 'Importazione interrotta · rimuovere a chiarire',
			'fileSources.errorQuotaExceeded' => 'Il limite di archiviazione offline è stato raggiunto. Aumentare il limite o rimuovere una copia scaricata.',
			'fileSources.errorStorageLow' => 'Non c\'è sufficiente archiviazione gratuita per mantenere la riserva protetta.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG non poteva controllare lo storage del dispositivo gratuito, quindi la scrittura è stata interrotta.',
			'fileSources.removeDownloadJob' => 'Rimuovere download',
			'fileSources.downloadAlreadyComplete' => 'Questo download è finito prima che possa essere rimosso. l\'articolo è ora disponibile offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Rimuovere questo download e rimuovere tutti i dati parzialmente scaricati? la tua posizione e le note rimarranno.',
			'lending.title' => 'Biblioteche pubbliche',
			'lending.add' => 'Aggiungi una biblioteca',
			'lending.other' => 'Un’altra biblioteca',
			'lending.libraryName' => 'Nome della biblioteca',
			'lending.libraryUrl' => 'Sito della biblioteca',
			'lending.libraryUrlHint' => 'Usa il catalogo della tua biblioteca o la pagina di accesso.',
			'lending.intro' => 'Prendi in prestito dalla tua biblioteca. Tieni i tuoi libri a portata di mano.',
			'lending.handoff' => 'Accedi, prendi in prestito e leggi in sicurezza con il servizio della tua biblioteca.',
			'lending.openService' => 'Apri biblioteca',
			'lending.findLibrary' => 'Trova una biblioteca',
			'lending.search' => 'Cerca libri e autori',
			'lending.catalogue' => 'Catalogo',
			'lending.loans' => 'Prestiti',
			'lending.holds' => 'Prenotazioni',
			'lending.signIn' => 'Accedi tramite la tua biblioteca',
			'lending.waiting' => 'Completa l’accesso nel browser, poi torna qui.',
			'lending.cancel' => 'Annulla',
			'lending.disconnect' => 'Rimuovi biblioteca',
			'lending.disconnectMessage' => 'Rimuovere questa biblioteca da questo profilo? I prestiti e le prenotazioni resteranno registrati presso la biblioteca.',
			'lending.getBook' => 'Ottieni il libro',
			'lending.checkAvailability' => 'Verifica disponibilità',
			'lending.available' => 'Disponibile per il prestito',
			'lending.unavailable' => 'Al momento non disponibile',
			'lending.borrow' => 'Prendi in prestito',
			'lending.placeHold' => 'Prenota',
			'lending.returnBook' => 'Restituisci in anticipo',
			'lending.cancelHold' => 'Annulla prenotazione',
			'lending.confirmBorrow' => 'Prendere in prestito questo titolo dalla tua biblioteca?',
			'lending.confirmReturn' => 'Restituire questo titolo adesso? Potresti doverlo prendere di nuovo in prestito per continuare.',
			'lending.confirmCancelHold' => 'Annullare la prenotazione di questo titolo?',
			'lending.email' => 'Email per le notifiche sulle prenotazioni',
			'lending.due' => ({required Object date}) => 'Scadenza: ${date}',
			'lending.queue' => ({required Object position}) => 'Posizione in coda: ${position}',
			'lending.empty' => 'Non ci sono ancora titoli.',
			'lending.openLibraryNote' => 'Esplora il catalogo di Open Library. Le opzioni di lettura e prestito sono indicate nella pagina di ciascun titolo.',
			'lending.more' => 'Carica di più',
			'lending.gateway' => 'Servizio di accesso alla biblioteca',
			'lending.gatewayHint' => 'Fornito dalla tua biblioteca o dall’amministratore di PlezyNG.',
			'lending.advanced' => 'Integrazione della biblioteca',
			'lending.loadLibraries' => 'Scegli la tua biblioteca',
			'lending.expired' => 'Il prestito è scaduto.',
			'lending.updated' => 'Biblioteca aggiornata',
			'lending.continueService' => 'Continua nel servizio',
			'lending.comingSoon' => 'Prestiti nell’app · In arrivo',
			'lending.comingSoonDescription' => 'L’integrazione con Libby è in arrivo. Puoi usare la tua biblioteca in Libby mentre completiamo il collegamento.',
			'lending.suspendHold' => 'Sospendi prenotazione',
			'lending.resumeHold' => 'Riprendi prenotazione',
			'lending.suspendMessage' => 'Mantenere il tuo posto in coda e lasciare che il prossimo lettore prenda in prestito questa copia? Puoi riprendere la prenotazione in seguito.',
			'lending.resumeMessage' => 'Riprendere questa prenotazione per consentire alla biblioteca di offrirti la prossima copia disponibile?',
			'lending.editEmail' => 'Modifica l’email per le notifiche',
			'audiobook.syncTitle' => 'Sincronizzazione di lettura e ascolto',
			'audiobook.syncHelp' => 'Sincronizza tra i tuoi dispositivi le posizioni di lettura e ascolto, lo stato di completamento, i segnalibri e le note. Scegli un account di archiviazione collegato e usa lo stesso codice di sincronizzazione su ogni dispositivo. Lettura e ascolto restano separati.',
			'audiobook.addSyncSource' => 'Aggiungi prima Google Drive, OneDrive, Dropbox, WebDAV o S3 in File e libri.',
			'audiobook.syncDestination' => 'Account di archiviazione per la sincronizzazione',
			'audiobook.syncFolder' => 'Cartella o prefisso di sincronizzazione',
			'audiobook.syncFolderHelp' => 'Usa una cartella separata già esistente nella tua fonte WebDAV oppure un prefisso S3 dedicato. I file dei libri non vengono mai modificati.',
			'audiobook.syncCode' => 'Codice privato di sincronizzazione',
			'audiobook.syncCodeHelp' => 'Crea un codice sul primo dispositivo, poi inseriscilo sugli altri dispositivi. Conservane una copia privata: è la chiave dei dati di sincronizzazione crittografati. Usa un codice diverso per ogni persona.',
			'audiobook.showCode' => 'Mostra o nascondi il codice di sincronizzazione',
			'audiobook.newSyncCode' => 'Crea un nuovo codice di sincronizzazione',
			'audiobook.saveSync' => 'Salva e sincronizza',
			'audiobook.disableSync' => 'Disattiva la sincronizzazione su questo dispositivo',
			'audiobook.syncSourceDisconnect' => 'Rimuovendo questa fonte, disattiverai la sincronizzazione di lettura e ascolto su questo dispositivo. I file di sincronizzazione crittografati resteranno presso il fornitore del servizio.',
			'audiobook.syncReconnect' => 'Ricollega l’account di archiviazione',
			'audiobook.lastSynced' => ({required Object time}) => 'Ultima sincronizzazione: ${time}',
			'audiobook.syncPrivacy' => 'Vengono memorizzati solo i progressi e le note, in forma crittografata. I file audio e degli ebook, i token degli account e le password non vengono caricati. Google Drive e OneDrive usano lo spazio riservato all’app; Dropbox usa PlezyNG Sync. L’attivazione della sincronizzazione può richiedere ulteriori permessi di scrittura. Quando è attiva, questa destinazione gestisce la sincronizzazione dei progressi; i progressi sul server restano separati. Disattivandola, la cronologia locale e lo stato remoto vengono conservati.',
			'audiobook.syncConflicts' => 'Scegli da dove riprendere',
			'audiobook.conflictHelp' => 'Queste modifiche sono state apportate indipendentemente. Scegli quale posizione o versione del segnalibro conservare. Una data e ora più recente o una percentuale più alta non hanno automaticamente la precedenza.',
			'audiobook.syncDevice' => ({required Object device}) => 'Dispositivo ${device}',
			'audiobook.syncUnknownDevice' => 'dispositivo sconosciuto',
			'audiobook.deletedBookmark' => 'Segnalibro eliminato',
			'audiobook.finished' => 'Completato',
			'audiobook.readingPosition' => ({required Object percent}) => 'Lettura · ${percent}%',
			'audiobook.chapterTimeline' => 'Avanzamento del capitolo',
			'audiobook.bookTimeline' => 'Avanzamento dell’intero libro',
			'audiobook.bookRemaining' => ({required Object time}) => 'Il tempo rimanente in questo libro: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Il tempo rimanente in questo capitolo: ${time}',
			'audiobook.unknownRemaining' => 'Il tempo totale sarà disponibile man mano che vengono riprodotte le parti',
			'audiobook.undoSeek' => 'Annulla l’ultimo salto di riproduzione',
			'audiobook.customSpeed' => 'Velocità di riproduzione personalizzata',
			'audiobook.speedHelp' => 'Scegli una velocità da 0,25× a 4×.',
			'audiobook.apply' => 'Applica',
			'audiobook.customSleep' => 'Timer di arresto personalizzato',
			'audiobook.sleepMinutes' => 'Minuti (1–1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Capitoli prima dell’arresto: ${count}',
			'audiobook.extendSleep' => 'Aggiungi 5 minuti',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Timer di arresto: ${time}',
			'audiobook.useDefaults' => 'Usa questi controlli di ascolto per i nuovi libri',
			'audiobook.librarySort' => 'Ordina i libri',
			'audiobook.sortTitle' => 'Titolo',
			'audiobook.sortAuthor' => 'Autore',
			'audiobook.sortNarrator' => 'Narratore',
			'audiobook.sortSeries' => 'Ordine della serie',
			'audiobook.sortRecent' => 'Aperti di recente',
			'audiobook.statusFilter' => 'Stato di lettura',
			'audiobook.statusAll' => 'Tutti i libri',
			'audiobook.statusNew' => 'Non iniziato',
			'audiobook.statusProgress' => 'In corso',
			'audiobook.statusFinished' => 'Completato',
			'audiobook.goToTime' => 'Vai al tempo indicato',
			'audiobook.timeHelp' => 'ore:minuti:secondi oppure minuti:secondi',
			'audiobook.recoveryHelp' => 'Esportare una copia recentemente crittografata prima di spostare o riparare i dati di sincronizzazione. Le importazioni si uniscono allo stato corrente; non sostituiscono mai la storia locale della sincronizzazione.',
			'audiobook.recoveryExport' => 'Esporta il file di recupero crittografato',
			'audiobook.recoveryImport' => 'Importa il file di recupero crittografato',
			'audiobook.recoveryImportConfirm' => 'Combinare questo file di recupero crittografato con posizioni di lettura corrente e note? Storia esistente sarà conservata. ID della biblioteca condivisa e degli articoli non sono inclusi; impostare ID corrispondenti su ogni dispositivo prima dell\'importazione.',
			'audiobook.recoveryExported' => 'Il file di recupero crittografato salvato.',
			'audiobook.recoveryImported' => 'I dati di recupero sono misti.',
			'sourceSetup.savedCertificate' => 'Certificato del server salvato',
			'sourceSetup.nfsEndpointInvalid' => 'Inserisci un URL NFS, ad esempio nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Nessun server DLNA trovato. Inserisci manualmente l’URL della descrizione del dispositivo.',
			'sourceSetup.dlnaServers' => 'Server multimediali DLNA',
			'sourceSetup.dlnaUnavailable' => 'Il rilevamento DLNA non è disponibile su questa rete. Inserisci manualmente l’URL della descrizione del dispositivo.',
			'sourceSetup.dlnaSearching' => 'Ricerca di server DLNA nella rete locale',
			'sourceSetup.networkSearching' => 'Ricerca nella rete locale…',
			'sourceSetup.dlnaDiscover' => 'Rileva server DLNA',
			'sourceSetup.dlnaHelp' => 'Il rilevamento dipende dal multicast sulla rete locale. Se non compare alcun server, inserisci qui sopra l’URL della sua descrizione del dispositivo.',
			'sourceSetup.dlnaRoot' => 'ID dell’oggetto DLNA; lascia vuoto per usare la radice del dispositivo.',
			'sourceSetup.passwordOrKey' => 'Inserisci una password oppure aggiungi una chiave privata qui sotto.',
			'sourceSetup.sshFingerprint' => 'Impronta SHA256 della chiave host SSH',
			'sourceSetup.sshFingerprintHelp' => 'Verificala con l’amministratore del server. Sul server, esegui ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub e usa il valore SHA256.',
			'sourceSetup.sshFingerprintKeep' => 'Lascia vuoto per mantenere l’impronta attualmente fissata oppure inserisci una nuova impronta del server.',
			'sourceSetup.sshAuthentication' => 'Autenticazione SSH con chiave pubblica',
			'sourceSetup.sshAuthenticationHelp' => 'Facoltativa; è supportata anche l’autenticazione con password.',
			'sourceSetup.privateKey' => 'Chiave privata (formato PEM o OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Passphrase della chiave privata',
			'sourceSetup.nfsMountPort' => 'Porta TCP del servizio di montaggio NFS',
			'sourceSetup.nfsMountPortHelp' => 'Predefinita: 20048',
			'sourceSetup.nfsUserId' => 'ID utente NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Predefinito: 1000. Usa l’ID consentito dalla condivisione NFS del NAS.',
			'sourceSetup.nfsGroupId' => 'ID gruppo NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Predefinito: 1000. Usa l’ID gruppo consentito dalla condivisione NFS del NAS.',
			'sourceSetup.nfsEncryption' => 'Richiedi NFS crittografato (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Richiedi TLS 1.3 per NFS e il servizio di montaggio. Se il NAS non lo supporta, la connessione viene rifiutata.',
			'sourceSetup.nfsTrustCertificate' => 'CA NFS personalizzata o certificato del server (PEM, facoltativo)',
			'sourceSetup.nfsTrustHelp' => 'Lascia vuoto per usare i certificati considerati attendibili da questo dispositivo. Se necessario, aggiungi un certificato di una CA privata o un certificato del server autofirmato; i nomi indicati devono corrispondere all’host nell’URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Usa un certificato di una CA o del server in formato PEM. Non includere una chiave privata.',
			'sourceSetup.addTrustCertificate' => 'Aggiungi un certificato attendibile personalizzato',
			'sourceSetup.replaceTrustCertificate' => 'Sostituisci il certificato personalizzato salvato',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS usa le normali porte NFS e del servizio di montaggio e richiede che il NAS supporti RFC 9289. È necessario TLS 1.3. Il nome host o l’indirizzo IP deve corrispondere al certificato. Gli UID/GID AUTH_SYS restano validi anche nel canale crittografato.',
			'sourceSetup.clientCertificate' => 'Certificato client (facoltativo)',
			'sourceSetup.clientCertificateHelp' => 'Consente al NAS di autenticare questo client; gli ID AUTH_SYS dipendono comunque dai criteri della condivisione NFS del NAS.',
			'sourceSetup.savedIdentity' => 'Verrà usata un’identità client salvata.',
			'sourceSetup.replaceIdentity' => 'Sostituisci l’identità client salvata',
			'sourceSetup.chooseIdentity' => 'Scegli un’identità client PKCS#12',
			'sourceSetup.identityPassphrase' => 'Passphrase dell’identità client',
			'sourceSetup.identityPassphraseHelp' => 'Lascia vuoto se il file non ha una passphrase.',
			'sourceSetup.removeIdentity' => 'Rimuovi qualsiasi identità client salvata',
			'sourceSetup.identityStorageHelp' => 'Le identità client vengono salvate nell’archivio crittografato delle credenziali della fonte. Lascia invariata questa sezione per mantenere l’identità salvata.',
			'sourceSetup.nfsLimitations' => 'NFSv3 in sola lettura su TCP. Senza RPC-with-TLS, il traffico NFS non è crittografato. Il NAS deve consentire gli ID AUTH_SYS selezionati e le porte client non privilegiate (spesso tramite l’opzione di esportazione “insecure”). NFSv4 e UDP non sono supportati.',
			'sourceSetup.nfsSetupHelp' => 'Guida alla configurazione NFS',
			'sourceSetup.nfsSetupHint' => 'Controlla queste impostazioni se la connessione non si apre.',
			'sourceSetup.nfsSetupDetails' => 'Usa una condivisione NFSv3 su TCP. Quando è richiesta la crittografia, sia il servizio NFS sia quello di montaggio devono supportare RPC-with-TLS. Lascia vuoto il certificato personalizzato per usare un certificato del server attendibile per questo dispositivo, oppure aggiungi il certificato della CA del NAS o quello autofirmato. Il nome nel certificato deve corrispondere all’host dell’endpoint. Se il NAS richiede TLS reciproco, aggiungi la sua identità client PKCS#12. Infine, verifica che la condivisione consenta gli UID/GID AUTH_SYS configurati e i criteri delle porte client.',
			'sourceSetup.ftpHelp' => 'FTP usa la modalità passiva. Usa ftp:// per FTP non crittografato, ftpes:// per TLS esplicito oppure ftps:// per TLS (implicito sulla porta 990, esplicito sulle altre porte).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Ricerca facoltativa di sottotitoli per video indipendenti.',
			'sourceSetup.apiKey' => 'Chiave API',
			'sourceSetup.optionalUsername' => 'Nome utente dell’account (facoltativo)',
			'sourceSetup.optionalPassword' => 'Password dell’account (facoltativa)',
			'sourceSetup.subtitlePrivacy' => 'Ottieni una chiave API da opensubtitles.com. La ricerca invia il titolo del video e gli ID IMDb/TMDB disponibili, mai il file video. La chiave e le credenziali facoltative dell’account vengono crittografate insieme a questa fonte.',
			'sourceSetup.automaticMetadata' => 'Metadati video online automatici',
			'sourceSetup.metadataPrivacy' => 'Invia solo titolo/anno ricavati dal nome del file e numeri degli episodi, oppure un ID NFO; non invia mai contenuti multimediali o credenziali. I campi NFO mantengono la precedenza.',
			'sourceSetup.nfsEncryptionFailure' => 'Per NFS crittografato, verifica il supporto di RFC 9289 e TLS 1.3 su entrambi i servizi del NAS, il nome nel certificato e gli UID/GID della condivisione. PlezyNG non riproverà questa connessione senza crittografia.',
			'sourceSetup.sourceConnecting' => 'Connessione alla fonte',
			'sourceSetup.metadataSearchPrivacy' => 'Questa ricerca di titoli viene inviata a Trakt. Viene trasmesso il titolo inserito, non il video né le credenziali della fonte.',
			'sourceSetup.chooseMatch' => 'Scegli una corrispondenza',
			'sourceSetup.metadataMatchHelp' => 'Controlla titolo e anno prima di scegliere. Trakt riceve il titolo cercato; il video rimane nella sua fonte.',
			'sourceSetup.metadataNoMatches' => 'Nessun titolo corrispondente trovato online. Prova un titolo diverso.',
			'sourceSetup.metadataSearch' => 'Cerca metadati online',
			'sourceSetup.metadataLoading' => 'Ricerca online dei dettagli di film e serie TV…',
			'sourceSetup.metadataFromTrakt' => 'Metadati online da Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Nessuna corrispondenza automatica trovata per il titolo. Cerca il titolo per scegliere una corrispondenza.',
			'sourceSetup.metadataFailed' => 'Impossibile caricare i metadati online. La riproduzione e i dettagli locali restano disponibili.',
			'sourceSetup.videoDetailsLoading' => 'Caricamento dei dettagli del video',
			'sourceSetup.subtitleKeyRequired' => 'È necessaria una chiave API OpenSubtitles',
			'sourceSetup.subtitleKeyHelp' => 'Modifica questa fonte di file e aggiungi una chiave API OpenSubtitles nelle impostazioni facoltative dei sottotitoli.',
			'sourceSetup.subtitleSearchFailed' => 'Ricerca dei sottotitoli non riuscita. Controlla la chiave API, la connessione e l’accesso al servizio.',
			'sourceSetup.subtitleApplyFailed' => 'Impossibile scaricare o applicare questi sottotitoli. Controlla la connessione e prova un altro risultato.',
			'sourceSetup.subtitleSearch' => 'Cerca su OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'La ricerca usa il titolo e gli ID IMDb/TMDB disponibili. Il file video rimane nella sua fonte. Prima di scegliere, controlla lingua, indicazioni di sottotitoli forzati o per non udenti e valutazione.',
			'sourceSetup.movieOrShow' => 'Film o serie',
			'sourceSetup.subtitleTitleHint' => 'Inserisci un titolo per affinare i risultati',
			'sourceSetup.subtitleLanguage' => 'Lingua dei sottotitoli',
			'sourceSetup.subtitleSearching' => 'Ricerca su OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Nessun sottotitolo corrispondente trovato. Prova un titolo o una lingua diversi.',
			'sourceSetup.downloadSubtitle' => 'Scarica sottotitoli',
			'sourceSetup.subtitle' => 'Sottotitoli',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS obbligatorio',
			'sourceSetup.nfsUnencrypted' => 'NFS non crittografato',
			'sourceSetup.tlsEncrypted' => 'Crittografato con TLS',
			'sourceSetup.ftpPlain' => 'FTP non crittografato',
			'sourceSetup.sshPinned' => 'SSH crittografato · chiave host fissata',
			'sourceSetup.smbEncrypted' => 'Crittografia SMB3 attiva',
			'sourceSetup.smbUnencrypted' => 'Crittografia SMB3 disattivata',
			'sourceSetup.httpUnencrypted' => 'HTTP senza crittografia del trasporto',
			'sourceSetup.checkEndpointSecurity' => 'Controlla la sicurezza dell’endpoint',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'Campo obbligatorio: ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Inserisci ${label} tra ${min} e ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Sostituisci ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Identità client selezionata: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Valutazione ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Download dei sottotitoli: ${title}',
			'sourceSetup.sharedEntryPair' => 'Coppia questo articolo',
			'sourceSetup.sharedEntryPairHelp' => 'Inserisci lo stesso ID per questo elemento su ciascun dispositivo. Utilizzare un identificatore condiviso stabile o generare uno e copiarlo all\'oggetto che corrisponde. Progress coppia solo quando i tipi di file edizioni, le dimensioni e l\'ordine corrispondono. Blank rimuove questa mappatura.',
			'sourceSetup.sharedEntryId' => 'ID di oggetto condiviso',
			'sourceSetup.generateSharedEntryId' => 'Generare un ID di oggetto condiviso',
			'sourceSetup.sharedLibraryId' => 'ID della biblioteca condivisa (opzionale)',
			'sourceSetup.sharedLibraryHelp' => 'Utilizzare lo stesso ID su dispositivi che aprono la stessa biblioteca.Questo ID pubblico aiuta a portare il progresso della lettura e delle note attraverso diverse connessioni sorgente; non è una password.Quando i fornitori utilizzano diversi ID di oggetto, coppia questi elementi dalle loro schermi dettagliati.',
			'sourceSetup.sharedLibraryInvalid' => 'Utilizzare 8-100 lettere, numeri, punti, sottoscori o hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Generare un ID della biblioteca condivisa',
			'sourceSetup.nfsReadAhead' => 'Le richieste di read-ahead della NFS',
			'sourceSetup.nfsReadAheadHelp' => 'Più letture parallele possono migliorare la capacità di passaggio su un NAS o una rete veloce. Utilizzare 1 se il server limita le richieste concorrenti.',
			'sourceSetup.nfsReadTest' => 'Misurare le prestazioni di NFS',
			'sourceSetup.nfsReadTestHelp' => 'Legge fino a 64 MiB dal file più grande per misurare questa connessione NAS. Questo utilizza la larghezza di banda della rete.',
			'sourceSetup.nfsQualificationResult' => 'NFS Leggi la misura',
			'sourceSetup.nfsReadBytes' => 'Dati di lettura',
			'sourceSetup.nfsReadSpeed' => 'velocità misurata',
			'sourceSetup.nfsReadRequests' => 'Leggi le richieste',
			'sourceSetup.sharedEntryConflict' => 'Questo ID di oggetto condiviso è già associato ad un altro elemento in questa biblioteca.',
			'comics.fitHeight' => 'Adatta all’altezza',
			'comics.readingMode' => 'Modalità di lettura',
			'comics.paged' => 'Pagine',
			'comics.webtoon' => 'Scorrimento continuo',
			'comics.coverAlone' => 'Mostra la copertina da sola',
			'comics.splitWide' => 'Dividi le pagine larghe',
			'comics.splitWideHelp' => 'Mostra ogni metà separatamente, nell’ordine di lettura. La visualizzazione di due pagine affiancate viene sospesa quando questa opzione è attiva.',
			'comics.thumbnails' => 'Miniature delle pagine',
			'comics.controlsHelp' => 'Scorri con il dito per voltare pagina. Tocca due volte per cambiare l’adattamento. Nello scorrimento continuo, scorri verticalmente o usa Pagina su e Pagina giù.',
			'comics.savedForComic' => 'Le impostazioni di visualizzazione vengono memorizzate per questo fumetto in questo profilo.',
			'comics.readLists' => 'Liste di lettura',
			'comics.collections' => 'Raccolte',
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
			_ => null,
		} ?? switch (path) {
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
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamAppId' => 'Steam App ID',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.steamLibraryHint' => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.',
			'deepLinks.invalid' => 'Questo link Plezy non è valido.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Nessun profilo corrisponde a "${profile}".',
			'deepLinks.serverUnavailable' => 'Non riuscivo a raggiungere il server per questo link.',
			'deepLinks.notFound' => 'Non riesco a trovare questo titolo nelle tue biblioteche.',
			'deepLinks.unsupportedItem' => 'Questo link non può essere giocato.',
			'deepLinks.noLiveTv' => 'Nessun server TV Live è disponibile per questo link.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Non potevo trovare il canale "${channel}".',
			'deepLinks.showLink' => 'Mostra il link',
			'deepLinks.showProfileLink' => 'Mostra il profilo link',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Aprendo questo link verrà riprodotto il prossimo episodio. Aggiungi &mode=shuffle alla fine per riprodurre la serie in ordine casuale.',
			'deepLinks.movieHint' => 'Aprire questo link gioca il film.',
			'deepLinks.episodeHint' => 'Aprire questo link gioca questo episodio.',
			'deepLinks.profileHint' => 'Aprire questo link scorre a questo profilo.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Apri come ${name}',
			'deepLinks.copy' => 'Copia',
			'deepLinks.copied' => 'Link copiato',
			_ => null,
		};
	}
}
