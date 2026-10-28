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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$app$fr app = Translations$app$fr.internal(_root);
	@override late final Translations$appIcon$fr appIcon = Translations$appIcon$fr.internal(_root);
	@override late final Translations$auth$fr auth = Translations$auth$fr.internal(_root);
	@override late final Translations$common$fr common = Translations$common$fr.internal(_root);
	@override late final Translations$screens$fr screens = Translations$screens$fr.internal(_root);
	@override late final Translations$update$fr update = Translations$update$fr.internal(_root);
	@override late final Translations$settings$fr settings = Translations$settings$fr.internal(_root);
	@override late final Translations$themeEditor$fr themeEditor = Translations$themeEditor$fr.internal(_root);
	@override late final Translations$search$fr search = Translations$search$fr.internal(_root);
	@override late final Translations$hotkeys$fr hotkeys = Translations$hotkeys$fr.internal(_root);
	@override late final Translations$fileInfo$fr fileInfo = Translations$fileInfo$fr.internal(_root);
	@override late final Translations$mediaMenu$fr mediaMenu = Translations$mediaMenu$fr.internal(_root);
	@override late final Translations$rateSheet$fr rateSheet = Translations$rateSheet$fr.internal(_root);
	@override late final Translations$accessibility$fr accessibility = Translations$accessibility$fr.internal(_root);
	@override late final Translations$tooltips$fr tooltips = Translations$tooltips$fr.internal(_root);
	@override late final Translations$audioTracks$fr audioTracks = Translations$audioTracks$fr.internal(_root);
	@override late final Translations$videoControls$fr videoControls = Translations$videoControls$fr.internal(_root);
	@override late final Translations$messages$fr messages = Translations$messages$fr.internal(_root);
	@override late final Translations$subtitlingStyling$fr subtitlingStyling = Translations$subtitlingStyling$fr.internal(_root);
	@override late final Translations$mpvConfig$fr mpvConfig = Translations$mpvConfig$fr.internal(_root);
	@override late final Translations$dialog$fr dialog = Translations$dialog$fr.internal(_root);
	@override late final Translations$profiles$fr profiles = Translations$profiles$fr.internal(_root);
	@override late final Translations$connections$fr connections = Translations$connections$fr.internal(_root);
	@override late final Translations$accountPreferences$fr accountPreferences = Translations$accountPreferences$fr.internal(_root);
	@override late final Translations$discover$fr discover = Translations$discover$fr.internal(_root);
	@override late final Translations$errors$fr errors = Translations$errors$fr.internal(_root);
	@override late final Translations$libraries$fr libraries = Translations$libraries$fr.internal(_root);
	@override late final Translations$about$fr about = Translations$about$fr.internal(_root);
	@override late final Translations$serverSelection$fr serverSelection = Translations$serverSelection$fr.internal(_root);
	@override late final Translations$hubDetail$fr hubDetail = Translations$hubDetail$fr.internal(_root);
	@override late final Translations$logs$fr logs = Translations$logs$fr.internal(_root);
	@override late final Translations$startup$fr startup = Translations$startup$fr.internal(_root);
	@override late final Translations$licenses$fr licenses = Translations$licenses$fr.internal(_root);
	@override late final Translations$navigation$fr navigation = Translations$navigation$fr.internal(_root);
	@override late final Translations$explore$fr explore = Translations$explore$fr.internal(_root);
	@override late final Translations$liveTv$fr liveTv = Translations$liveTv$fr.internal(_root);
	@override late final Translations$collections$fr collections = Translations$collections$fr.internal(_root);
	@override late final Translations$playlists$fr playlists = Translations$playlists$fr.internal(_root);
	@override late final Translations$music$fr music = Translations$music$fr.internal(_root);
	@override late final Translations$watchTogether$fr watchTogether = Translations$watchTogether$fr.internal(_root);
	@override late final Translations$downloads$fr downloads = Translations$downloads$fr.internal(_root);
	@override late final Translations$shaders$fr shaders = Translations$shaders$fr.internal(_root);
	@override late final Translations$companionRemote$fr companionRemote = Translations$companionRemote$fr.internal(_root);
	@override late final Translations$videoSettings$fr videoSettings = Translations$videoSettings$fr.internal(_root);
	@override late final Translations$performanceOverlay$fr performanceOverlay = Translations$performanceOverlay$fr.internal(_root);
	@override late final Translations$externalPlayer$fr externalPlayer = Translations$externalPlayer$fr.internal(_root);
	@override late final Translations$metadataEdit$fr metadataEdit = Translations$metadataEdit$fr.internal(_root);
	@override late final Translations$matchScreen$fr matchScreen = Translations$matchScreen$fr.internal(_root);
	@override late final Translations$serverTasks$fr serverTasks = Translations$serverTasks$fr.internal(_root);
	@override late final Translations$trakt$fr trakt = Translations$trakt$fr.internal(_root);
	@override late final Translations$seerr$fr seerr = Translations$seerr$fr.internal(_root);
	@override late final Translations$services$fr services = Translations$services$fr.internal(_root);
	@override late final Translations$addServer$fr addServer = Translations$addServer$fr.internal(_root);
	@override late final Translations$cast$fr cast = Translations$cast$fr.internal(_root);
	@override late final Translations$automation$fr automation = Translations$automation$fr.internal(_root);
	@override late final Translations$notifications$fr notifications = Translations$notifications$fr.internal(_root);
	@override late final Translations$appAccess$fr appAccess = Translations$appAccess$fr.internal(_root);
	@override late final Translations$detail$fr detail = Translations$detail$fr.internal(_root);
	@override late final Translations$watchLink$fr watchLink = Translations$watchLink$fr.internal(_root);
	@override late final Translations$homeLayout$fr homeLayout = Translations$homeLayout$fr.internal(_root);
	@override late final Translations$platform$fr platform = Translations$platform$fr.internal(_root);
	@override late final Translations$universalMedia$fr universalMedia = Translations$universalMedia$fr.internal(_root);
	@override late final Translations$fileSources$fr fileSources = Translations$fileSources$fr.internal(_root);
	@override late final Translations$lending$fr lending = Translations$lending$fr.internal(_root);
	@override late final Translations$audiobook$fr audiobook = Translations$audiobook$fr.internal(_root);
	@override late final Translations$sourceSetup$fr sourceSetup = Translations$sourceSetup$fr.internal(_root);
	@override late final Translations$comics$fr comics = Translations$comics$fr.internal(_root);
	@override late final Translations$games$fr games = Translations$games$fr.internal(_root);
	@override late final Translations$deepLinks$fr deepLinks = Translations$deepLinks$fr.internal(_root);
}

// Path: app
class Translations$app$fr extends Translations$app$en {
	Translations$app$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class Translations$appIcon$fr extends Translations$appIcon$en {
	Translations$appIcon$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icône de l’application';
	@override String get defaultIcon => 'Par défaut';
	@override String get current => 'Icône actuelle';
	@override String get locked => 'Accès à vie requis';
	@override String get lockedHint => 'Démarrez votre essai de 7 jours ou déconnectez PlezyNG pour une durée de vie pour utiliser des icônes alternatives.';
	@override String get changeFailed => 'Impossible de changer l’icône de l’application';
	@override String get launcherHint => 'La nouvelle icône apparaîtra sur votre écran d’accueil une fois que vous aurez quitté PlezyNG.';
	@override String get tvLauncherHint => 'La nouvelle bannière apparaîtra une fois que vous aurez quitté PlezyNG. Android TV peut continuer à afficher l’ancienne jusqu’au redémarrage du téléviseur.';
	@override late final Translations$appIcon$names$fr names = Translations$appIcon$names$fr.internal(_root);
	@override String get description => 'Choisissez l\'icône affichée par votre lanceur d\'appareil. Les prévisions montrent comment chaque option ressemble.';
}

// Path: auth
class Translations$auth$fr extends Translations$auth$en {
	Translations$auth$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Se connecter avec Plex';
	@override String get showQRCode => 'Afficher le code QR';
	@override String get authenticate => 'S\'authentifier';
	@override String get authenticationTimeout => 'Délai d\'authentification expiré. Veuillez réessayer.';
	@override String get scanQRToSignIn => 'Scannez ce QR code pour vous connecter';
	@override String get waitingForAuth => 'En attente d\'authentification...\nConnectez-vous depuis votre navigateur.';
	@override String get useBrowser => 'Utiliser le navigateur';
	@override String get or => 'ou';
	@override String connectToMediaBrowser({required Object product}) => 'Se connecter à ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Utiliser Quick Connect';
	@override String get quickConnectInstructions => 'Ouvrez Quick Connect dans Jellyfin et saisissez ce code.';
	@override String get quickConnectWaiting => 'En attente d\'approbation…';
	@override String get quickConnectCancel => 'Annuler';
	@override String get quickConnectExpired => 'Quick Connect a expiré. Réessayez.';
	@override String get localDataRecoveryRequired => 'PlezyNG n’a pas pu récupérer en toute sécurité les données locales de connexion et de lecture en attente. Veuillez vous reconnecter.';
	@override String get pinCheckRejected => 'La vérification du code PIN Plex a été refusée';
	@override String get connectToDirectPlex => 'Connectez-vous au serveur local Plex';
}

// Path: common
class Translations$common$fr extends Translations$common$en {
	Translations$common$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuler';
	@override String get save => 'Enregistrer';
	@override String get close => 'Fermer';
	@override String get closeMiniPlayer => 'Un mini joueur proche';
	@override String get closeWorkspaceWindow => 'fenêtre proche';
	@override String get returnToFullView => 'Retour à la vue complète';
	@override String get manageMediaSessions => 'Gérer les séances médiatiques';
	@override String get hideMediaSessions => 'Découvrir les séances médiatiques';
	@override String get mediaSessions => 'Sessions médiatiques';
	@override String get mediaSessionsHint => 'Sélectionnez pour amener une session en avant. le parc cache sa fenêtre mais la tient ouverte. le retour l\'ouvre en pleine vue; il finit à proximité.';
	@override String get sessionInWorkspace => 'dans le laboratoire';
	@override String get sessionParked => 'Parking';
	@override String get sessionFullscreen => 'écran complet';
	@override String get switchToNextWindow => 'Swap avec la fenêtre suivante';
	@override String get moveWindow => 'Mouvez la fenêtre';
	@override String get finishMovingWindow => 'Fin de fenêtre en mouvement';
	@override String get moveWindowHint => 'Long pressez et jettez la fenêtre pour le déplacer. Ce contrôle permet également le mouvement de la clé des armes.';
	@override String get movingWindowHelp => 'Mettre en mouvement · Ajuster les clés de tir · Entrer les sauvegardes · Cancler l\'échappement';
	@override String get resizeWindow => 'Récupérer la fenêtre';
	@override String get resizeWindowHint => 'Tirez ce manuel ou utilisez les clés d\'armes pour redémarrer la fenêtre.';
	@override String get workspaceWindowHint => 'Utilisez le contrôle de mouvement ou la longue pression et tirer pour se déplacer.';
	@override String get workspacePaneHint => 'Sélectionnez ce panneau pour le focaliser. Utilisez son contrôle à plein écran pour s\'élargir.';
	@override String workspaceWindowLabel({required Object title}) => 'Étiquette : ${title}';
	@override String get workspaceTitleHint => 'Tirez la barre de titre pour se déplacer; utilisez le bouton à pleine écran pour étendre.';
	@override String get moveToSessionTray => 'Mouvez-vous à la session tray';
	@override String get moveToSessionTrayHint => 'Cette session est disponible sans afficher sa fenêtre.';
	@override String get closeSessionHint => 'Fermez cette fenêtre et terminez sa session.';
	@override String get sideBySideLayout => 'Transfert vers le layout à côté';
	@override String get floatingWindows => 'Switch pour flotter les fenêtres';
	@override String get clear => 'Effacer';
	@override String get reset => 'Réinitialiser';
	@override String get later => 'Plus tard';
	@override String get submit => 'Soumettre';
	@override String get confirm => 'Confirmer';
	@override String get retry => 'Réessayer';
	@override String get logout => 'Se déconnecter';
	@override String get unknown => 'Inconnu';
	@override String get refresh => 'Rafraîchir';
	@override String get yes => 'Oui';
	@override String get no => 'Non';
	@override String get delete => 'Supprimer';
	@override String get edit => 'Modifier';
	@override String get shuffle => 'Mélanger';
	@override String get addTo => 'Ajouter à…';
	@override String get createNew => 'Créer';
	@override String get connect => 'Se connecter';
	@override String get disconnect => 'Se déconnecter';
	@override String get play => 'Lire';
	@override String get pause => 'Pause';
	@override String get resume => 'Reprendre';
	@override String get error => 'Erreur';
	@override String get search => 'Recherche';
	@override String get home => 'Accueil';
	@override String get back => 'Retour';
	@override String get settings => 'Paramètres';
	@override String get mute => 'Couper le son';
	@override String get ok => 'OK';
	@override String get off => 'Désactivé';
	@override String get options => 'Options';
	@override String seasonNumber({required Object number}) => 'Saison ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Épisode ${number} – ${title}';
	@override String chapterNumber({required Object number}) => 'Chapitre ${number}';
	@override String get reconnect => 'Se reconnecter';
	@override String get viewAll => 'Tout afficher';
	@override String get checkingNetwork => 'Vérification du réseau...';
	@override String get loadingServers => 'Chargement des serveurs...';
	@override String get connectingToServers => 'Connexion aux serveurs...';
	@override String get startingOfflineMode => 'Démarrage en mode hors ligne…';
	@override String get loading => 'Chargement...';
	@override String get fullscreen => 'Plein écran';
	@override String get exitFullscreen => 'Quitter le plein écran';
	@override String get pressBackAgainToExit => 'Appuyez à nouveau sur retour pour quitter';
	@override late final Translations$common$ratingSource$fr ratingSource = Translations$common$ratingSource$fr.internal(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final Translations$common$mediaKind$fr mediaKind = Translations$common$mediaKind$fr.internal(_root);
}

// Path: screens
class Translations$screens$fr extends Translations$screens$en {
	Translations$screens$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licences';
	@override String get switchProfile => 'Changer de profil';
	@override String get subtitleStyling => 'Configuration des sous-titres';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Journaux';
}

// Path: update
class Translations$update$fr extends Translations$update$en {
	Translations$update$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get available => 'Mise à jour disponible';
	@override String versionAvailable({required Object version}) => 'Version ${version} disponible';
	@override String currentVersion({required Object version}) => 'Actuelle : ${version}';
	@override String get skipVersion => 'Ignorer cette version';
	@override String get viewRelease => 'Voir les notes de version';
	@override String get latestVersion => 'Vous utilisez la dernière version';
	@override String get checkFailed => 'Échec de la vérification des mises à jour';
}

// Path: settings
class Translations$settings$fr extends Translations$settings$en {
	Translations$settings$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres';
	@override String get supportDeveloper => 'Soutenir PlezyNG';
	@override String get supportDeveloperDescription => 'Faites un don pour soutenir le développement';
	@override String get lifetimeAccess => 'PlezyNG accès à vie';
	@override String get language => 'Langue';
	@override String get theme => 'Thème';
	@override String get appearance => 'Apparence';
	@override String get detailPage => 'Page détaillée';
	@override String get themeSongsEnabled => 'Jouer des chansons thématiques';
	@override String get themeSongsEnabledDescription => 'Jouez à des chansons thématiques disponibles tout en regardant les détails médiatiques.';
	@override String get themeSongVolume => 'Le volume de la chanson';
	@override String get videoPlayback => 'Lecture vidéo';
	@override String get videoPlaybackDescription => 'Configurer le comportement de lecture';
	@override String get advanced => 'Avancé';
	@override String get episodePosterMode => 'Style de l’affiche de l’épisode';
	@override String get seriesPoster => 'Affiche de la série';
	@override String get seasonPoster => 'Affiche de la saison';
	@override String get episodeThumbnail => 'Miniature';
	@override String get showHeroSectionDescription => 'Afficher le carrousel de contenu en vedette sur l\'écran d\'accueil';
	@override String get secondsLabel => 'Secondes';
	@override String get minutesLabel => 'Minutes';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'min';
	@override String durationHint({required Object min, required Object max}) => 'Saisissez la durée (${min}–${max})';
	@override String get systemTheme => 'Système';
	@override String get lightTheme => 'Clair';
	@override String get darkTheme => 'Sombre';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Braise';
	@override String get glacierTheme => 'Glacier';
	@override String get forestTheme => 'Forêt';
	@override String get plumTheme => 'Prune';
	@override String get paperTheme => 'Papier';
	@override String get libraryDensity => 'Densité des bibliothèques';
	@override String get displayScale => 'Échelle d\'affichage';
	@override String get compact => 'Compact';
	@override String get comfortable => 'Confortable';
	@override String get gridSpacing => 'Espacement de la grille';
	@override String get gridSpacingTight => 'Resserré';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Aéré';
	@override String get tvCornerSpotlightBackdrop => 'Illustration en vedette dans le coin';
	@override String get tvCornerSpotlightBackdropDescription => 'Afficher l’illustration en vedette dans le coin supérieur droit plutôt qu’en plein écran';
	@override String get viewMode => 'Mode d\'affichage';
	@override String get gridView => 'Grille';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Afficher la section à la une';
	@override String get showHomeBackdrop => 'Afficher le travail d\'art de la maison backdrop';
	@override String get showHomeBackdropDescription => 'Afficher une grande œuvre d\'art derrière les rares de la maison';
	@override String get contentScreensaverEnabled => 'Screensaver de contenu';
	@override String get contentScreensaverEnabledDescription => 'Afficher l\'art à plein écran après que l\'application a été idle';
	@override String get contentScreensaverDelay => 'Démarrer l’écran après';
	@override String get contentScreensaverLibraries => 'Les bibliothèques Screensaver';
	@override String get contentScreensaverLibrariesDescription => 'Choisissez les bibliothèques qui fournissent les images de l’économiseur d’écran. Si aucune n’est sélectionnée, les images de toutes les bibliothèques sont utilisées.';
	@override String get contentScreensaverAllLibraries => 'Toutes les bibliothèques';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} bibliothèques sélectionnées';
	@override String get contentScreensaverNoLibraries => 'Aucune bibliothèque de médias connectée n’est disponible.';
	@override String get contentScreensaverDismissHint => 'Appuyez sur un bouton ou tapez pour désactiver';
	@override String get newEpisodeNotifications => 'Nouvelles notifications d\'épisode';
	@override String get newEpisodeNotificationsDescription => 'Alerte lorsque un nouvel épisode est ajouté à un spectacle que vous êtes capturé. Vérifier pendant que Plezy est ouvert.';
	@override String get continueWatchingRowSize => 'Continuez à regarder la taille de la ligne';
	@override String continueWatchingRowSizeValue({required Object label}) => 'Cartes ${label}';
	@override String get rowSizeCompact => 'Compact';
	@override String get rowSizeStandard => 'Standard';
	@override String get rowSizeLarge => 'Grand';
	@override String get continueWatchingAction => 'Action de « Continuer à regarder »';
	@override String get continueWatchingPlay => 'Lire';
	@override String get continueWatchingDetails => 'Ouvrir les détails';
	@override String get episodeAction => 'Action des épisodes';
	@override String get episodePlay => 'Lire';
	@override String get episodeDetails => 'Ouvrir les détails';
	@override String get useGlobalHubs => 'Utiliser la mise en page d\'accueil';
	@override String get useGlobalHubsDescription => 'Afficher des hubs d\'accueil unifiés. Sinon, utiliser les recommandations de bibliothèque.';
	@override String get showServerNameOnHubs => 'Afficher le nom du serveur sur les hubs';
	@override String get showServerNameOnHubsDescription => 'Toujours afficher les noms des serveurs dans les titres des hubs.';
	@override String get groupLibrariesByServer => 'Grouper les bibliothèques par serveur';
	@override String get groupLibrariesByServerDescription => 'Regrouper les bibliothèques de la barre latérale par serveur multimédia.';
	@override String get alwaysKeepSidebarOpen => 'Toujours garder la barre latérale ouverte';
	@override String get alwaysKeepSidebarOpenDescription => 'La barre latérale reste étendue et la zone de contenu s\'adapte';
	@override String get showUnwatchedCount => 'Afficher le nombre d’éléments non vus';
	@override String get showUnwatchedCountDescription => 'Afficher le nombre d’épisodes non vus pour les séries et les saisons';
	@override String get showWatchedIndicators => 'Afficher les indicateurs de visionnage';
	@override String get showWatchedIndicatorsDescription => 'Afficher une coche sur les films, séries et épisodes déjà vus';
	@override String get showEpisodeNumberOnCards => 'Afficher le numéro de l’épisode sur les cartes';
	@override String get showEpisodeNumberOnCardsDescription => 'Afficher les numéros de saison et d’épisode sur les cartes d’épisode';
	@override String get showSeasonPostersOnTabs => 'Afficher les affiches de saison sur les onglets';
	@override String get showSeasonPostersOnTabsDescription => 'Afficher l’affiche de chaque saison au-dessus de son onglet';
	@override String get tvFullCardLayout => 'Cartes TV plein format';
	@override String get tvFullCardLayoutDescription => 'Utiliser des cartes TV composées uniquement d’une image, avec le nom des acteurs en surimpression';
	@override String get focusGlow => 'Halo de sélection';
	@override String get focusGlowDescription => 'Afficher un léger halo autour de la carte sélectionnée';
	@override String get visualEffects => 'Effets visuels';
	@override String get visualEffectsAuto => 'Automatique';
	@override String get visualEffectsAutoDescription => 'Réduire automatiquement les effets sur les appareils peu puissants';
	@override String get visualEffectsFull => 'Complets';
	@override String get visualEffectsReduced => 'Réduits';
	@override String get visualEffectsReducedDescription => 'Moins d’animations et d’illustrations de plus faible résolution';
	@override String get hideSpoilers => 'Masquer les spoilers des épisodes non vus';
	@override String get hideSpoilersDescription => 'Flouter les miniatures et descriptions des épisodes non vus';
	@override String get playerBackend => 'Moteur de lecture';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Décodage matériel';
	@override String get hardwareDecodingDescription => 'Utiliser l’accélération matérielle lorsqu’elle est disponible';
	@override String get playbackBuffer => 'Tampon de lecture';
	@override String get playbackBufferAuto => 'Auto (recommandé)';
	@override String get playbackBufferLarge => 'Grand';
	@override String get playbackBufferExtraLarge => 'Très grand';
	@override String get playbackBufferDescription => 'Tampon supplémentaire contre les connexions instables. Également limité par la taille du tampon.';
	@override String get streamBufferSize => 'Le buffer';
	@override String streamBufferSizeValue({required Object size}) => '${size} Mo';
	@override String get streamBufferSizeDescription => 'Combien de vidéos à charger avant lors de la lecture directe. transcodes s\'arrêtent au buffer de transcodes du serveur. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Remplacer le Playback Buffer lors de la configuration, capté à la moitié de la limite de mémoire de l\'application';
	@override String get streamBufferMegabytes => 'Les Megabytes';
	@override String get defaultQualityTitle => 'Qualité par défaut';
	@override String get cellularQualityTitle => 'Qualité par défaut sur les données mobiles';
	@override String get remoteQualityTitle => 'Qualité de la diffusion à distance';
	@override String get remoteQualitySameAsDefault => 'La qualité défectueuse';
	@override String get cellularQualitySameAsDefault => 'Identique à la qualité par défaut';
	@override String get directPlayCoveredQuality => 'Lire les vidéos plus petites en qualité originale';
	@override String get directPlayCoveredQualityDescription => 'Lire directement les vidéos déjà dans la limite de qualité au lieu de les transcoder';
	@override String get videoCodecs => 'Codecs vidéo';
	@override String get videoCodecsDescription => 'Le serveur transcode les codecs non cochés';
	@override String get videoCodecsAlwaysAccepted => 'Toujours accepté';
	@override String get musicQualityTitle => 'Qualité de la musique';
	@override String get subtitleStyling => 'Style des sous-titres';
	@override String get subtitleStylingDescription => 'Personnaliser l’apparence des sous-titres';
	@override String get smallSkipDuration => 'Durée du saut court';
	@override String get largeSkipDuration => 'Durée du saut long';
	@override String get rewindOnResume => 'Rembobiner à la reprise';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} seconde',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes',
	);
	@override String get defaultSleepTimer => 'Minuterie de mise en veille par défaut';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minute',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes',
	);
	@override String get rememberTrackSelections => 'Mémoriser les pistes choisies pour chaque série ou film';
	@override String get chooseTracksBeforePlayback => 'Choisissez les sous-titres et les audio avant le playback';
	@override String get chooseTracksBeforePlaybackDescription => 'Choisissez les traces audio et sous-titres avant que chaque vidéo ne commence.';
	@override String get alwaysShowSubtitlesOnDevice => 'Toujours afficher les sous-titres sur ce dispositif';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Lorsque le serveur n\'a pas de sous-titre sélectionné, choisissez une piste localement.';
	@override String get autoDownloadPreferredSubtitle => 'Les sous-titres de la langue préférée manquants';
	@override String get autoDownloadPreferredSubtitleDescription => 'Sélectionnez un sous-titre disponible dans votre langue préférée localement.Si aucun n\'existe, demandez au serveur de faire un lorsqu\'il est supporté.';
	@override String get rememberTrackSelectionsDescription => 'Mémoriser les choix audio et sous-titres par titre';
	@override String get rememberTrackSelectionsBackendRule => 'Plex enregistre chaque choix sur le serveur pour chaque fichier ; Jellyfin active aussi l’option « Mémoriser les sélections » du compte ; Emby n’est pas pris en charge';
	@override String get followServerTrackSelections => 'Utiliser les pistes sélectionnées sur le serveur pour chaque épisode';
	@override String get followServerTrackSelectionsDescription => 'Au changement d\'épisode, appliquer l\'audio et les sous-titres sélectionnés sur le serveur au lieu de conserver le choix en cours';
	@override String get resumeMusicOnLaunch => 'Mémoriser la session musicale';
	@override String get resumeMusicOnLaunchDescription => 'Au lancement de l\'application, rouvrir le dernier titre en pause là où il s\'était arrêté';
	@override String get showChapterMarkersOnTimeline => 'Afficher les marqueurs de chapitres sur la barre de lecture';
	@override String get showChapterMarkersOnTimelineDescription => 'Segmenter la barre de lecture aux limites des chapitres';
	@override String get specialsOrdering => 'Épisodes spéciaux dans l’ordre des épisodes';
	@override String get specialsOrderingDescription => 'Position des épisodes spéciaux dans l’ordre de visionnage d’une série';
	@override String get specialsOrderingServer => 'Suivre l’ordre du serveur';
	@override String get specialsOrderingAirDate => 'Intercaler selon la date de diffusion';
	@override String get specialsOrderingLast => 'Après les saisons normales';
	@override String get clickVideoTogglesPlayback => 'Cliquer sur la vidéo pour alterner entre lecture et pause';
	@override String get clickVideoTogglesPlaybackDescription => 'Cliquer sur la vidéo pour lire ou mettre en pause plutôt que d’afficher les commandes';
	@override String get videoPlayerControls => 'Commandes du lecteur vidéo';
	@override String get keyboardShortcuts => 'Raccourcis clavier';
	@override String get keyboardShortcutsDescription => 'Personnaliser les raccourcis clavier';
	@override String get videoPlayerNavigation => 'Navigation dans le lecteur vidéo';
	@override String get videoPlayerNavigationDescription => 'Utiliser les touches fléchées pour parcourir les commandes du lecteur vidéo';
	@override String get watchTogetherRelay => 'Relais pour Regarder ensemble';
	@override String get watchTogetherRelayDescription => 'Relais publics Open Watch Party, sauf si vous définissez le vôtre';
	@override String get watchTogetherRelayHint => 'https://mon-relais.exemple.fr';
	@override String get watchTogetherRelayInvalid => 'Saisissez une URL de base HTTP ou HTTPS valide pour le relais.';
	@override String get crashReporting => 'Rapports de plantage';
	@override String get crashReportingDescription => 'Envoyer des rapports de plantage pour améliorer l\'application';
	@override String get debugLogging => 'Journalisation de débogage';
	@override String get debugLoggingDescription => 'Activer la journalisation détaillée pour le dépannage';
	@override String get viewLogs => 'Voir les journaux';
	@override String get viewLogsDescription => 'Voir les journaux de l’application';
	@override String get clearImageCache => 'Vider le cache d\'images';
	@override String get clearImageCacheDescription => 'Vide les affiches et vignettes en cache. Les images peuvent se charger plus lentement jusqu\'à leur prochain téléchargement.';
	@override String get clearImageCacheSuccess => 'Cache d\'images vidé avec succès';
	@override String get resetSettings => 'Réinitialiser les paramètres';
	@override String get resetSettingsDescription => 'Restaurer les paramètres par défaut. Action irréversible.';
	@override String get resetSettingsSuccess => 'Réinitialisation des paramètres réussie';
	@override String get backup => 'Sauvegarde';
	@override String get exportSettings => 'Exporter les paramètres';
	@override String get exportSettingsDescription => 'Enregistrer vos préférences dans un fichier';
	@override String get exportSettingsSuccess => 'Paramètres exportés';
	@override String get importSettings => 'Importer les paramètres';
	@override String get importSettingsDescription => 'Restaurer les préférences depuis un fichier';
	@override String get importSettingsConfirm => 'Cela remplacera vos paramètres actuels. Continuer ?';
	@override String get importSettingsSuccess => 'Paramètres importés';
	@override String get importSettingsInvalidFile => 'Ce fichier n’est pas une exportation valide des paramètres de PlezyNG';
	@override String get importSettingsNoUser => 'Connectez-vous avant d’importer les paramètres';
	@override String get cloudBackup => 'Cloud de sauvegarde';
	@override String get cloudBackupDescription => 'Sauvegardez les paramètres transférables à une adresse WebDAV via HTTPS. Les connexions aux serveurs et les identifiants restent sur cet appareil.';
	@override String get cloudBackupUrl => 'WebDAV JSON fichier URL';
	@override String get cloudBackupUsername => 'Nom d\'utilisateur';
	@override String get cloudBackupPassword => 'Mot de passe';
	@override String get cloudBackupSaved => 'Cloud Backup Destination sauvée';
	@override String get cloudBackupNow => 'Retour à présent';
	@override String get cloudBackupComplete => 'Settings Backup envoyé';
	@override String get cloudBackupRestore => 'Récupérer Backup';
	@override String get cloudBackupRestoreConfirm => 'Cela remplacera les paramètres portables correspondants sur ce dispositif.';
	@override String get cloudBackupRestored => 'Récupération de la récupération de la sauvegarde cloud';
	@override String get shortcutsReset => 'Raccourcis réinitialisés aux valeurs par défaut';
	@override String get resetShortcutsConfirm => 'Cela remplacera vos raccourcis personnalisés par les raccourcis par défaut. Continuer ?';
	@override String get about => 'À propos';
	@override String get aboutDescription => 'Informations sur l\'application et licences';
	@override String get updates => 'Mises à jour';
	@override String get updateAvailable => 'Mise à jour disponible';
	@override String get checkForUpdates => 'Vérifier les mises à jour';
	@override String get autoCheckUpdatesOnStartup => 'Vérifier automatiquement les mises à jour au démarrage';
	@override String get autoCheckUpdatesOnStartupDescription => 'Notifier au lancement quand une mise à jour est disponible';
	@override String get validationErrorEnterNumber => 'Veuillez saisir un nombre valide';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'La durée doit être comprise entre ${min} et ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Raccourci déjà attribué à ${action}';
	@override String shortcutUpdated({required Object action}) => 'Raccourci mis à jour pour ${action}';
	@override String get saveFailed => 'Impossible d’enregistrer les modifications. Réessayez.';
	@override String get autoPlayAndSkip => 'Lecture automatique et saut';
	@override String get autoPlayNextEpisode => 'Lire automatiquement l\'épisode suivant';
	@override String get autoPlayNextEpisodeDescription => 'Lancer automatiquement l\'épisode suivant lorsqu\'un épisode se termine';
	@override String get shuffleStartsFromBeginning => 'La lecture aléatoire commence au début';
	@override String get shuffleStartsFromBeginningDescription => 'Lire chaque épisode depuis le début en lecture aléatoire au lieu de le reprendre';
	@override String get plexCinemaPreRoll => 'Utiliser le serveur cinéma intros';
	@override String get plexCinemaPreRollDescription => 'Jouez configuré Plex pré-rolls ou Jellyfin et Emby entrées avant le début d\'un film.';
	@override String get playNextCountdown => 'Compte à rebours avant l\'épisode suivant';
	@override String get playNextCountdownImmediate => 'Lire immédiatement';
	@override String get skipIntroMode => 'Passer l’intro';
	@override String get skipIntroModeOffDescription => 'Lire les intros normalement sans bouton de saut';
	@override String get skipIntroModeButtonDescription => 'Afficher un bouton de saut au début d’une intro';
	@override String get skipIntroModeAutoDescription => 'Passer les intros automatiquement après le délai ci-dessous';
	@override String get skipCreditsMode => 'Passer le générique';
	@override String get skipCreditsModeOffDescription => 'Lire le générique normalement sans bouton de saut';
	@override String get skipCreditsModeButtonDescription => 'Afficher un bouton de saut au début du générique';
	@override String get skipCreditsModeAutoDescription => 'Passer le générique automatiquement et lire l’épisode suivant';
	@override String get skipAdsMode => '- les ads';
	@override String get skipAdsModeOffDescription => 'Jouer des annonces détectées normalement sans un bouton de déclenche';
	@override String get skipAdsModeButtonDescription => 'Afficher un bouton de déclenchement lorsque Plex détecte un annonce';
	@override String get skipAdsModeAutoDescription => 'Éteindre les annonces détectées automatiquement après le retard ci-dessous';
	@override String get musicPlayback => 'Musique Playback';
	@override String get musicSweetFades => 'Les fades douces';
	@override String get musicSweetFadesDescription => 'La musique est en train de se débarrasser lorsque Plex a des données de son.';
	@override String get skipMarkerModeOff => 'Désactivé';
	@override String get skipMarkerModeButton => 'Afficher le bouton';
	@override String get skipMarkerModeAuto => 'Automatique';
	@override String get forceSkipMarkerFallback => 'Forcer les marqueurs de secours';
	@override String get forceSkipMarkerFallbackDescription => 'Utiliser les motifs des titres de chapitre même lorsque Plex fournit des marqueurs';
	@override String get theIntroDbFallback => 'Utilisez TheIntroDB comme un intro fallback';
	@override String get theIntroDbFallbackDescription => 'Utilisez les horaires communautaires uniquement lorsque le serveur n\'a pas de marqueur d\'intro.';
	@override String get autoSkipDelay => 'Délai avant le saut automatique';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Attendre ${seconds} secondes avant le saut automatique';
	@override String get introPattern => 'Motif du marqueur d’introduction';
	@override String get introPatternDescription => 'Expression régulière permettant de reconnaître les marqueurs d’introduction dans les titres de chapitre';
	@override String get creditsPattern => 'Motif du marqueur de générique';
	@override String get creditsPatternDescription => 'Expression régulière permettant de reconnaître les marqueurs de générique dans les titres de chapitre';
	@override String get prerolls => 'Prérolls';
	@override String get playPrerollsBeforeMovies => 'Jouer les pré-rolls avant les films';
	@override String get playPrerollsBeforeMoviesDescription => 'Jouez un clip aléatoire de votre sélection ci-dessous avant chaque film.';
	@override String get prerollLibrary => 'Bibliothèque Preroll';
	@override String get prerollLibraryNotSet => 'Non défini';
	@override String get prerollLibraryNoneFound => 'Aucune bibliothèque n’a été trouvée sur vos serveurs.';
	@override String get prerollSelection => 'Les prérogatives sélectionnées';
	@override String get prerollSelectionPickLibraryFirst => 'Choisissez une bibliothèque d’abord';
	@override String get prerollSelectionNoneSelected => 'Pas de pré-section sélectionnée';
	@override String prerollSelectionCount({required Object count}) => '${count} sélectionné(s)';
	@override String get prerollItemPicker => 'Choisir les précautions';
	@override String get prerollItemPickerLoadFailed => 'Je ne pouvais pas charger des articles de cette bibliothèque.';
	@override String get invalidRegex => 'Expression régulière invalide';
	@override String get regex => 'Expression régulière';
	@override String get downloads => 'Téléchargements';
	@override String get downloadLocationDescription => 'Choisir où stocker le contenu téléchargé';
	@override String get downloadLocationDefault => 'Par défaut (stockage de l\'application)';
	@override String get downloadLocationCustom => 'Emplacement personnalisé';
	@override String get selectFolder => 'Sélectionner un dossier';
	@override String get resetToDefault => 'Réinitialiser les paramètres par défaut';
	@override String currentPath({required Object path}) => 'Actuel : ${path}';
	@override String get downloadLocationChanged => 'Emplacement de téléchargement modifié';
	@override String get downloadLocationReset => 'Emplacement de téléchargement réinitialisé à la valeur par défaut';
	@override String get downloadLocationInvalid => 'Le dossier sélectionné n\'est pas accessible en écriture';
	@override String get downloadLocationPickerUnavailable => 'La sélection de dossier n’est pas disponible sur cet appareil';
	@override String get downloadOnWifiOnly => 'Télécharger uniquement en Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Empêcher les téléchargements via les données mobiles';
	@override String get autoRemoveWatchedDownloads => 'Supprimer automatiquement les téléchargements vus';
	@override String get autoRemoveWatchedDownloadsDescription => 'Supprimer automatiquement les téléchargements vus';
	@override String get autoDownloadContinueWatching => 'Auto-Download Continuez à regarder';
	@override String get autoDownloadContinueWatchingDescription => 'Gardez les articles sur votre bouclier de suivi continu téléchargés, et les supprimez une fois qu\'ils quittent le bouclier';
	@override String get downloadQuality => 'Télécharger la qualité';
	@override String get downloadQualityDescription => 'Plex prépare une copie convertie dans son code de téléchargement. Jellyfin et Emby transcode pendant que le fichier téléchargera; les transferts interrompus peuvent avoir besoin de redémarrer.';
	@override String get askDownloadQualityEachTime => 'Choisissez la qualité pour chaque téléchargement';
	@override String get askDownloadQualityEachTimeDescription => 'Afficher le picker de qualité avant de couper chaque téléchargement vidéo';
	@override String get cellularDownloadBlocked => 'Les téléchargements sont bloqués sur le réseau mobile. Utilisez le Wi-Fi ou modifiez ce paramètre.';
	@override String get maxVolume => 'Volume maximal';
	@override String get maxVolumeDescription => 'Autoriser l\'augmentation du volume au-delà de 100 % pour les médias silencieux';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Afficher sur Discord ce que vous regardez';
	@override String get services => 'Services';
	@override String get servicesDescription => 'Connecter Trakt, MyAnimeList, Seerr et d’autres services';
	@override String get manageLibrariesDescription => 'Réorganiser et masquer les bibliothèques';
	@override String get companionRemoteServer => 'Serveur de télécommande';
	@override String get companionRemoteServerDescription => 'Autoriser les appareils mobiles de votre réseau à contrôler cette application';
	@override String get companionRemoteServerStartFailed => 'Impossible de démarrer le serveur de télécommande';
	@override String get companionRemoteServerStopFailed => 'Impossible d\'arrêter le serveur de télécommande';
	@override String get autoPip => 'Mode image dans l’image automatique';
	@override String get autoPipDescription => 'Passer en mode image dans l’image si vous quittez l’application pendant la lecture';
	@override String get matchContentFrameRate => 'Adapter la fréquence d’images au contenu';
	@override String get matchContentFrameRateDescription => 'Adapter la fréquence de rafraîchissement de l’écran au contenu vidéo';
	@override String get matchContentResolution => 'Adapter à la résolution du contenu';
	@override String get matchContentResolutionDescription => 'Bascule l’affichage sur la résolution native de la vidéo pour que votre téléviseur gère la mise à l’échelle. Les menus et les sous-titres sont eux aussi mis à l’échelle pendant la lecture';
	@override String get matchRefreshRate => 'Adapter la fréquence de rafraîchissement';
	@override String get matchRefreshRateDescription => 'Adapter la fréquence d\'affichage en plein écran';
	@override String get matchDynamicRange => 'Adapter la plage dynamique';
	@override String get matchDynamicRangeDescription => 'Activer HDR pour le contenu HDR, puis revenir en SDR';
	@override String get displaySwitchDelay => 'Délai de changement d\'affichage';
	@override String get tunneledPlayback => 'Lecture tunnelée';
	@override String get tunneledPlaybackDescription => 'Utiliser le tunneling vidéo. Désactivez si la lecture HDR affiche un écran noir ou si l’image saccade.';
	@override String get audioPassthrough => 'Transmission audio directe';
	@override String get audioPassthroughDescription => 'Envoyer l’audio Dolby/DTS à votre ampli ou téléviseur sans le réencoder afin de préserver le son surround. Désactivez cette option en l’absence de son.';
	@override String get audioPassthroughDescriptionApple => 'Utiliser le décodeur Dolby natif d’Apple pour le Dolby Digital Plus, y compris Atmos. Le DTS et le TrueHD sont toujours lus en PCM multicanal. Désactivez cette option en l’absence de son.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Utiliser le décodeur Dolby natif d’Apple pour le Dolby Digital Plus, y compris Atmos. Sous iOS, iPadOS et tvOS 26 ou version ultérieure, le TrueHD Atmos et le DTS:X sont lus en audio spatial. Les autres pistes DTS et TrueHD sont lues en PCM multicanal. Désactivez cette option en l’absence de son.';
	@override String get audioPassthroughOverriddenByNormalization => 'Désactivée tant que la normalisation du volume est active';
	@override String get audioChannelLimit => 'Canaux audio';
	@override String get audioChannelLimitDescription => 'Réduire le nombre de canaux de l’audio décodé pour les enceintes, casques ou installations HDMI qui ne peuvent pas restituer tous les canaux';
	@override String get audioChannelLimitOriginal => 'D’origine';
	@override String get audioChannelLimitOriginalDescription => 'Lire tous les canaux de la piste';
	@override String get audioChannelLimitSurround51 => 'Jusqu’à 5.1';
	@override String get audioChannelLimitSurround51Description => 'Convertir le 7.1 en 5.1 pour les téléviseurs et amplis qui n’acceptent que le PCM 5.1. La transmission directe n’est pas affectée.';
	@override String get audioChannelLimitStereo => 'Stéréo';
	@override String get audioChannelLimitStereoDescription => 'Convertir en deux canaux pour des enceintes stéréo ou un casque. Désactive la transmission directe.';
	@override String get downmixCenterBoost => 'Renforcement du canal central';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Renforcement (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normaliser le volume lors de la conversion en stéréo';
	@override String get audioDownmixNormalizeDescription => 'Atténuer le mixage pour éviter la saturation. Désactivez cette option pour conserver le volume d’origine, au risque de déformer les scènes bruyantes.';
	@override String get dvConversionMode => 'Conversion Dolby Vision';
	@override String get dvConversionModeDescription => 'Choisir comment les fichiers Dolby Vision de profil 7 sont gérés.';
	@override String get dvConversionAuto => 'Auto';
	@override String get dvConversionNative => 'Natif / désactivé';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Utiliser la détection des capacités de l’appareil et le comportement de repli normal';
	@override String get dvConversionNativeDescription => 'Forcer le DV7 natif et bloquer la nouvelle tentative de conversion DV';
	@override String get dvConversionDv81Description => 'Forcer la conversion RPU intégrée vers le profil 8.1 de Dolby Vision';
	@override String get dvConversionHevcStripDescription => 'Supprimer les couches RPU/EL Dolby Vision et présenter du HEVC simple';
	@override String get experimentalDolbyVision => 'Dolby Vision expérimental';
	@override String get experimentalDolbyVisionDescription => 'Utiliser le moteur de rendu FEL expérimental à la prochaine lecture. Nécessite une compilation distincte du moteur.';
	@override String get dvExperimentUnavailableDescription => 'Cette expérimentation est actuellement disponible uniquement sous Linux.';
	@override String get dvCompatibilityFallback => 'Repli de compatibilité';
	@override String get dvCompatibilityFallbackDescription => 'Utiliser le rendu standard si l’expérimentation ne démarre pas. Les données FEL peuvent être perdues.';
	@override String get dvExperimentDiagnostics => 'Journalisation de l’expérimentation vidéo';
	@override String get dvExperimentDiagnosticsDescription => 'Activer les journaux détaillés du lecteur à la prochaine lecture.';
	@override String get disableDolbyVision => 'Désactiver Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Lire la couche HDR10 ou HLG du fichier au lieu de Dolby Vision, si elle existe';
	@override String get hdrSdrConversion => 'Conversion HDR vers SDR';
	@override String get hdrSdrConversionDescription => 'Choisir ce qui convertit les vidéos HDR lorsque l’écran ne peut pas afficher le HDR.';
	@override String get hdrSdrConversionAuto => 'Auto';
	@override String get hdrSdrConversionAutoDescription => 'Appareil à partir d’Android 9, lecteur sur les versions antérieures';
	@override String get hdrSdrConversionDevice => 'Appareil';
	@override String get hdrSdrConversionDeviceDescription => 'Le matériel vidéo de l’appareil effectue la conversion. Le plus rapide, mais les couleurs dépendent de l’appareil';
	@override String get hdrSdrConversionPlayer => 'Lecteur';
	@override String get hdrSdrConversionPlayerDescription => 'Le lecteur effectue la conversion. Couleurs homogènes, mais la 4K peut saccader sur les box TV d’entrée de gamme';
	@override String get deinterlace => 'Désentrelacement';
	@override String get deinterlaceDescription => 'Supprimer les artefacts de peignage des vidéos entrelacées (lecteur mpv uniquement)';
	@override String get deinterlaceOff => 'Désactivé';
	@override String get deinterlaceOffDescription => 'Afficher la vidéo entrelacée telle qu’elle est décodée';
	@override String get deinterlaceVideo => 'Vidéo';
	@override String get deinterlaceVideoDescription => 'Transformer chaque trame en image complète. Pour les vidéos tournées pour la télévision, comme le sport, les infos et les concerts';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => 'Restaurer les images d’origine des films et animations convertis en 29,97 i/s par télécinéma, un cas fréquent sur les DVD NTSC. Les vidéos tournées pour la télévision saccadent. La TV en direct utilise le mode Vidéo';
	@override String get requireProfileSelectionOnOpen => 'Demander le profil à l\'ouverture';
	@override String get requireProfileSelectionOnOpenDescription => 'Afficher la sélection de profil à chaque ouverture de l\'application';
	@override String get forceTvMode => 'Forcer le mode TV';
	@override String get forceTvModeDescription => 'Forcer l’interface TV sur les appareils qui ne sont pas détectés automatiquement. Redémarrage requis.';
	@override String get startInFullscreen => 'Démarrer en plein écran';
	@override String get startInFullscreenDescription => 'Ouvrir PlezyNG en mode plein écran au lancement';
	@override String get exitFullscreenOnPlayerClose => 'Quitter le plein écran à la fermeture du lecteur';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Quitter automatiquement le plein écran lors de la fermeture du lecteur vidéo';
	@override String get autoHidePerformanceOverlay => 'Masquer automatiquement les données de performance';
	@override String get autoHidePerformanceOverlayDescription => 'Masquer progressivement les données de performance avec les commandes de lecture';
	@override String get showNavBarLabels => 'Afficher les libellés de la barre de navigation';
	@override String get showNavBarLabelsDescription => 'Afficher les libellés sous les icônes de la barre de navigation';
	@override String get startupSection => 'Section de démarrage';
	@override String get preferredServer => 'Le serveur préféré';
	@override String get preferredServerDescription => 'Prioriser les résultats de ce serveur tout en gardant chaque serveur connecté disponible.';
	@override String get preferredServerAutomatic => 'Automatique';
	@override String get showExploreTab => 'Afficher l’onglet Explorer';
	@override String get showExploreTabDescription => 'Afficher l’onglet Explorer avec le contenu de Plex Discover et des services de suivi connectés';
	@override String get hideEmptyLibraries => 'Écrivez des bibliothèques vides';
	@override String get hideEmptyLibrariesDescription => 'Supprimer les bibliothèques avec un nombre d\'éléments rapportés par le serveur de zéro de la navigation.';
	@override String get liveTvDefaultFavorites => 'Chaînes favorites par défaut';
	@override String get liveTvDefaultFavoritesDescription => 'Afficher uniquement les chaînes favorites à l\'ouverture de la TV en direct';
	@override String get general => 'Général';
	@override String get generalDescription => 'Langue, démarrage et comportement de la fenêtre';
	@override String get languageAndRegion => 'Langue et région';
	@override String get startup => 'Démarrage';
	@override String get display => 'Affichage';
	@override String get libraryAndCards => 'Bibliothèque et cartes';
	@override String get homeScreen => 'Écran d\'accueil';
	@override String get navigation => 'Navigation';
	@override String get window => 'Fenêtre';
	@override String get liveTv => 'TV en direct';
	@override String get player => 'Lecteur';
	@override String get videoAndDisplay => 'Vidéo et affichage';
	@override String get audio => 'Audio';
	@override String get quality => 'Qualité';
	@override String get subtitles => 'Sous-titres';
	@override String get seekAndTiming => 'Déplacement et minutage';
	@override String get behavior => 'Comportement';
	@override String get gestures => 'Gestes';
	@override String get gestureBrightnessSwipe => 'Balayage de luminosité';
	@override String get gestureBrightnessSwipeDescription => 'Balayez vers le haut ou le bas sur le bord gauche pour régler la luminosité';
	@override String get gestureVolumeSwipe => 'Balayage de volume';
	@override String get gestureVolumeSwipeDescription => 'Balayez vers le haut ou le bas sur le bord droit pour régler le volume';
	@override String get gesturePinchToZoom => 'Pincer pour zoomer';
	@override String get gesturePinchToZoomDescription => 'Pincez la vidéo pour zoomer ou dézoomer';
	@override String get gestureSeekSwipe => 'Rechercher Swipe';
	@override String get gestureSeekSwipeDescription => 'Swipe gauche ou droite n\'importe où sur la vidéo à rechercher; libérer pour sauter';
	@override String get rememberBrightnessLevel => 'Mémoriser le niveau de luminosité';
	@override String get rememberBrightnessLevelDescription => 'Démarrer la lecture à la luminosité définie par le dernier balayage';
	@override String get controls => 'Commandes';
	@override String get rememberPlayerChanges => 'Mémoriser les modifications du lecteur';
	@override String get rememberPlayerChangesDescription => 'Où une modification effectuée pendant la lecture est enregistrée et réappliquée';
	@override String get scopePlaybackSpeed => 'Vitesse de lecture';
	@override String get scopeShaderPreset => 'Préréglage du shader';
	@override String get scopeAspectRatio => 'Format d’image';
	@override String get scopeSyncOffsets => 'Synchronisation audio et sous-titres';
	@override String get playerScopeOff => 'Ne pas enregistrer';
	@override String get playerScopeGlobal => 'Partout';
	@override String get playerScopeLibrary => 'Par bibliothèque';
	@override String get playerScopeTitle => 'Par série ou film';
	@override String get exportDialogTitle => 'Exporter les paramètres de PlezyNG';
	@override String get followSystem => 'Suivre le système';
	@override String get followAppLanguage => 'Comme la langue de l’interface';
	@override String get regionFormat => 'Formats régionaux';
	@override String get regionFormatDescription => 'Choisissez le format des dates, des nombres et des unités de mesure.';
	@override String get metadataLanguage => 'Langue des métadonnées';
	@override String get metadataLanguageDescription => 'Langue préférée pour les titres et descriptions, si le serveur la prend en charge. Les préférences audio et de sous-titres restent distinctes.';
	@override String get enterFullscreenOnPlaybackStart => 'Entrer sur l\'écran complet lorsque le playback commence';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Ouvrir la vidéo à l\'écran complet lorsque le playback commence';
	@override String get extendVideoIntoDisplayCutout => 'Extendre la vidéo à l\'affichage Cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Laissez la vidéo à pleine écran utiliser le cutout de la caméra sur les téléphones Android';
	@override String get languageDescription => 'Choisissez la langue utilisée pour les contrôles et les messages PlezyNG. Suivez le système trace votre langage de l\'appareil.';
	@override String get themeDescription => 'Choisissez les couleurs et contrôles utilisés dans toute l\'application.';
	@override String get libraryDensityDescription => 'Changer le nombre de cartes de bibliothèque dans chaque ligne.';
	@override String get displayScaleDescription => 'Récupérer l\'interface sur cet écran de voiture sans modifier la taille du texte de votre appareil.';
	@override String get themeSongVolumeDescription => 'Définissez le volume des chansons thématiques par rapport à d\'autres sons.';
	@override String get viewModeDescription => 'Choisissez si les articles de la bibliothèque apparaissent comme des affiches dans un réseau ou comme une liste compacte.';
	@override String get gridViewDescription => 'Arrangez les articles de la bibliothèque dans des lignes et colonnes d\'affiches.';
	@override String get listViewDescription => 'Afficher les articles de bibliothèque dans une liste verticale avec plus de texte par article.';
	@override String get gridSpacingDescription => 'Mettez la distance entre les affiches dans les filets de bibliothèque.';
	@override String get gridSpacingTightDescription => 'Faites plus de cartes sur l\'écran avec des lacunes plus petites.';
	@override String get gridSpacingNormalDescription => 'Utilisez l’écart standard entre les dossiers.';
	@override String get gridSpacingSpaciousDescription => 'Ajoutez des lacunes plus grandes entre les dossiers pour plus de séparation.';
	@override String get episodePosterModeDescription => 'Choisissez quelle œuvre d\'art apparaît sur les cartes d\'épisode.';
	@override String get seriesPosterDescription => 'Utilisez le poster de la série pour chaque épisode.';
	@override String get seasonPosterDescription => 'Utilisez le poster de saison pour chaque épisode lorsqu’il est disponible.';
	@override String get episodeThumbnailDescription => 'Utilisez un cadre de l\'épisode quand il est disponible.';
	@override String get continueWatchingActionDescription => 'Choisissez ce qui se passe lorsque vous activez une carte de suivi continue.';
	@override String get continueWatchingPlayDescription => 'Commencez immédiatement le film ou l\'épisode.';
	@override String get continueWatchingDetailsDescription => 'Ouvrez d\'abord la page de titre afin que vous puissiez réviser les détails et choisir une action.';
	@override String get episodeActionDescription => 'Choisissez ce qui se passe lorsque vous activez une carte d\'épisode.';
	@override String get episodePlayDescription => 'Commencez immédiatement l’épisode.';
	@override String get episodeDetailsDescription => 'Ouvrez la page avant le playback.';
	@override String get contentScreensaverDelayDescription => 'Choisissez combien de temps PlezyNG attend sans entrée avant d\'afficher des œuvres d\'art.';
	@override String get continueWatchingRowSizeDescription => 'Choisissez la taille des cartes dans la ligne de suivi continue.';
	@override String get rowSizeCompactDescription => 'Affichez des cartes plus petites afin que de plus d\'objets s\'adaptent à travers la ligne.';
	@override String get rowSizeStandardDescription => 'Utilisez la taille standard de la carte.';
	@override String get rowSizeLargeDescription => 'Afficher des cartes plus grandes avec plus de détails d\'art.';
	@override String get visualEffectsDescription => 'Choisissez le budget de l\'animation et des effets d\'art pour ce dispositif.';
	@override String get visualEffectsFullDescription => 'Utilisez les effets d\'animation et d\'art sur chaque appareil.';
	@override String get startupSectionDescription => 'Choisissez la section qui s\'ouvre lorsque PlezyNG démarre.';
	@override late final Translations$settings$startupSectionOptions$fr startupSectionOptions = Translations$settings$startupSectionOptions$fr.internal(_root);
	@override String get smallSkipDurationDescription => 'Mettez la distance déplacée par le court en arrière et à l\'avant chercher les contrôles.';
	@override String get largeSkipDurationDescription => 'Mettez la distance déplacée par le long en arrière et à l\'avant chercher les contrôles.';
	@override String get rewindOnResumeDescription => 'Mouvez le replayback de cette somme lorsque vous récupérez une vidéo.';
	@override String get defaultSleepTimerDescription => 'Définissez la durée initiale utilisée lorsque vous commencez le timing du sommeil.';
	@override String get playNextCountdownDescription => 'Attendez cela longtemps avant de commencer le prochain épisode. Sélectionnez à 0 pour démarrer immédiatement.';
	@override String get autoSkipDelaySettingDescription => 'Il s\'applique lorsque un intro, crédit ou annonce est configuré pour échapper automatiquement.';
	@override String get downmixCenterBoostDescription => 'Augmentez le dialogue dans le canal central lorsque l\'audio environnante est mélangée vers le stéréo.';
	@override String get displaySwitchDelayDescription => 'Attendre avant de changer le mode d\'affichage afin que la télévision ou le récepteur puisse terminer son précédent interrupteur.';
	@override String get playerBackendDescription => 'Choisissez le moteur de lecture qui découvre et rend la vidéo sur cet appareil.';
	@override String get exoPlayerDescription => 'Utilisez le lecteur natif Media3 d\'Android et les voies matérielles soutenues.';
	@override String get mpvDescription => 'Utilisez mpv, qui expose des contrôles de lecture supplémentaires, sous-titres et traitement vidéo.';
	@override String get scopeOffDescription => 'Remplacer les changements pour la session actuelle de reprise uniquement.';
	@override String get scopeGlobalDescription => 'Réutiliser la même valeur pour chaque bibliothèque et titre.';
	@override String get scopeLibraryDescription => 'Rappelez-vous une valeur distincte pour chaque bibliothèque.';
	@override String get scopeTitleDescription => 'Rappelez-vous une valeur distincte pour chaque spectacle ou film.';
	@override String get specialsOrderingServerDescription => 'Gardez l\'ordre d\'épisode fourni par le serveur de médias.';
	@override String get specialsOrderingAirDateDescription => 'Placez des spéciales parmi les épisodes réguliers à leur date aérienne.';
	@override String get specialsOrderingLastDescription => 'Placez chaque spécial après les saisons régulières.';
	@override String get skipIntroModeDescription => 'Choisissez si les marquants intro jouent normalement, affichez un bouton d\'échappement ou échapper automatiquement.';
	@override String get skipCreditsModeDescription => 'Choisissez si les crédits jouent normalement, affichez un bouton d\'échappement ou échapper automatiquement.';
	@override String get skipAdsModeDescription => 'Choisissez si les annonces détectées se jouent normalement, affichez un bouton d\'échappement ou échapper automatiquement.';
	@override String get playbackBufferAutoDescription => 'Laissez le joueur actif choisir sa taille de buffer normale.';
	@override String get playbackBufferLargeDescription => 'Gardez plus de médias prêts avant la lecture; cela utilise plus de mémoire.';
	@override String get playbackBufferExtraLargeDescription => 'Gardez le plus grand buffer de lecture, ce qui utilise la plus grande mémoire.';
	@override String get defaultQualityDescription => 'Configurez la résolution vidéo par défaut et bitrate le plafond pour les courants que le serveur transcode.';
	@override String get cellularQualityDescription => 'Supprimer la qualité par défaut lorsque le dispositif utilise une connexion cellulaire uniquement.';
	@override String get remoteQualityDescription => 'Supprimer la qualité par défaut lors de la connexion à un serveur via une connectivité à distance.';
	@override String get qualityPresetOriginalDescription => 'Jouez la source à sa qualité disponible sans demander au serveur de la transcoder.';
	@override String get qualityPresetTranscodeOptionDescription => 'Demandez au serveur un flux converti en utilisant la résolution et la vitesse indiquées ci-dessus.';
	@override String get qualityPresetSameAsDefaultDescription => 'Utilisez la qualité sélectionnée dans la qualité par défaut.';
	@override String get musicQualityDescription => 'Configurez la vitesse audio maximale demandée du serveur; Original maintient le flux source.';
	@override String get musicQualityOriginalDescription => 'Jouez à l\'audio source sans un transcode de bitrate.';
	@override String get musicQualityTranscodeOptionDescription => 'Demandez un transcode du serveur cappé près de la vitesse indiquée ci-dessus; la sortie réelle peut varier.';
	@override String get maxVolumeInputLabel => 'Volume maximum (%)';
	@override String get checkForUpdatesDescription => 'Vérifiez maintenant si une version plus récente de PlezyNG est disponible.';
	@override String get appearanceDescription => 'Choisissez le thème de l\'application et ajustez les cartes bibliothèques, les lignes d\'accueil et la navigation.';
	@override String get prerollLibraryDescription => 'Choisissez la bibliothèque qui contient les clips disponibles en tant que pré-rolls de film.';
	@override String get prerollSelectionDescription => 'Choisissez les clips de la bibliothèque sélectionnée que vous pouvez jouer avant les films.';
	@override String get contentScreensaverDelayOptionDescription => 'Attendre de nombreuses minutes sans entrées avant d\'afficher l\'œuvre d\'art screensaver.';
	@override String get videoCodecOptionDescription => 'Permettre la reproduction directe de ce codec lorsqu\'il est supporté. les codecs non vérifiés sont transcodés par le serveur des médias.';
}

// Path: themeEditor
class Translations$themeEditor$fr extends Translations$themeEditor$en {
	Translations$themeEditor$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Intégrés';
	@override String get presets => 'Prédéfinis';
	@override String get custom => 'Personnalisé';
	@override String get customEmpty => 'Pas encore créé';
	@override String get editCustom => 'Modifier le thème personnalisé';
	@override String get editCustomDescription => 'Choisissez vous-même chaque couleur';
	@override String get locked => 'Accès à vie requis';
	@override String get savedLocked => 'Épargné - disponible avec accès à vie';
	@override String get title => 'Thème personnalisé';
	@override String get startFrom => 'Partir d’un thème';
	@override String get startFromDescription => 'Copier toutes les couleurs d’un autre thème';
	@override String get colors => 'Couleurs';
	@override String get preview => 'Aperçu';
	@override late final Translations$themeEditor$slots$fr slots = Translations$themeEditor$slots$fr.internal(_root);
	@override String get opacity => 'Opacité';
	@override String get hexHint => '#RRGGBB ou #AARRGGBB';
	@override String get fromOtherThemes => 'Dans les autres thèmes';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} du thème ${theme}';
	@override late final Translations$themeEditor$contrast$fr contrast = Translations$themeEditor$contrast$fr.internal(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair} : ${ratio}:1, sous le seuil recommandé de ${minimum}:1';
	@override String get discardTitle => 'Abandonner les modifications ?';
	@override String get discardMessage => 'Vos modifications de couleurs non enregistrées seront perdues.';
	@override String get discard => 'Abandonner';
	@override String previewCardTitle({required Object number}) => 'Épisode ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} min restantes';
	@override String get previewSwitch => 'Lecture automatique';
	@override String get previewMutedText => 'Voici à quoi ressemble le texte secondaire';
	@override String get themeSystemDescription => 'Suivez l’apparence de votre appareil et passez automatiquement entre la lumière et le noir.';
	@override String get themeLightDescription => 'Utilisez un fond lumineux avec du texte sombre.';
	@override String get themeDarkDescription => 'Utilisez un fond sombre avec un texte lumineux.';
	@override String get themeOledDescription => 'Utilisez des surfaces en noir qui réduisent la lumière sur les écrans OLED.';
	@override String get themeEmberDescription => 'Utilisez des couleurs d\'accent rouge et amber.';
	@override String get themeGlacierDescription => 'Utilisez des couleurs d’accent bleu.';
	@override String get themeForestDescription => 'Utilisez des couleurs d’accent verts et naturels.';
	@override String get themePlumDescription => 'Utilisez des couleurs d\'accent violet et plum.';
	@override String get themePaperDescription => 'Utilisez des surfaces chaudes en papier et des couleurs inspirées d\'encre.';
	@override String get themeCustomDescription => 'Utilisez la palette de couleurs que vous avez créée dans l\'éditeur thème personnalisé.';
	@override String get editorDescription => 'Choisissez une couleur de palette, ajustez son hue, sa saturation, sa luminosité ou l\'opacité et regardez la mise à jour prévisionnelle avant d\'économiser.';
}

// Path: search
class Translations$search$fr extends Translations$search$en {
	Translations$search$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Rechercher des films, des séries, de la musique...';
	@override String get tryDifferentTerm => 'Essayez un autre terme de recherche';
	@override String get searchYourMedia => 'Rechercher dans vos médias';
	@override String get enterTitleActorOrKeyword => 'Entrez un titre, un acteur ou un mot-clé';
	@override String get people => 'Personnes';
}

// Path: hotkeys
class Translations$hotkeys$fr extends Translations$hotkeys$en {
	Translations$hotkeys$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Définir un raccourci pour ${actionName}';
	@override String get clearShortcut => 'Effacer le raccourci';
	@override String get noShortcutSet => 'Aucun raccourci défini';
	@override String get currentShortcut => 'Raccourci actuel :';
	@override String get pressToRecord => 'Sélectionner pour enregistrer un raccourci';
	@override String get recordingShortcut => 'Appuyez maintenant sur le raccourci';
	@override late final Translations$hotkeys$actions$fr actions = Translations$hotkeys$actions$fr.internal(_root);
}

// Path: fileInfo
class Translations$fileInfo$fr extends Translations$fileInfo$en {
	Translations$fileInfo$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informations sur le fichier';
	@override String get overview => 'Aperçu';
	@override String get video => 'Vidéo';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Sous-titres';
	@override String get images => 'Images intégrées';
	@override String get dataStreams => 'Flux de données';
	@override String get lyrics => 'Paroles';
	@override String get file => 'Fichier';
	@override String get attachments => 'Pièces jointes';
	@override String get delivery => 'Diffusion';
	@override String versionCounter({required Object index, required Object count}) => 'Version ${index} sur ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Fichier ${index} sur ${count}';
	@override String get noStreams => 'Le serveur n\'a signalé aucun flux pour ce fichier.';
	@override String get copyPath => 'Copier le chemin';
	@override String get pathCopied => 'Chemin du fichier copié';
	@override String get codec => 'Codec';
	@override String get codecTag => 'Balise de codec';
	@override String get resolution => 'Résolution';
	@override String get codedResolution => 'Résolution codée';
	@override String get bitrate => 'Débit';
	@override String get frameRate => 'Fréquence d\'images';
	@override String get rotation => 'Rotation';
	@override String get comment => 'Commentaire';
	@override String get audioDescription => 'Audiodescription';
	@override String get headerCompression => 'Compression d\'en-tête';
	@override String get sidecarFile => 'Fichier annexe';
	@override String get transportTimestamp => 'Horodatage du transport';
	@override String get displayOffset => 'Décalage d\'affichage';
	@override String get previewFailureCode => 'Code d\'échec de l\'aperçu';
	@override String get previewRetries => 'Tentatives d\'aperçu';
	@override String get aspectRatio => 'Format d\'image';
	@override String get pixelAspectRatio => 'Rapport d\'aspect des pixels';
	@override String get profile => 'Profil';
	@override String get level => 'Niveau';
	@override String get bitDepth => 'Profondeur de bits';
	@override String get pixelFormat => 'Format de pixels';
	@override String get colorSpace => 'Espace colorimétrique';
	@override String get colorRange => 'Gamme de couleurs';
	@override String get colorPrimaries => 'Couleurs primaires';
	@override String get colorTransfer => 'Transfert de couleur';
	@override String get chromaSubsampling => 'Sous-échantillonnage chromatique';
	@override String get chromaLocation => 'Position du chroma';
	@override String get scanType => 'Type de balayage';
	@override String get interlaced => 'Entrelacé';
	@override String get anamorphic => 'Anamorphique';
	@override String get referenceFrames => 'Images de référence';
	@override String get dynamicRange => 'Plage dynamique';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Niveau Dolby Vision';
	@override String get dolbyVisionVersion => 'Version Dolby Vision';
	@override String get dolbyVisionLayers => 'Couches Dolby Vision';
	@override String get baseLayerCompatibility => 'Compatibilité de la couche de base';
	@override String get avcBitstream => 'Flux binaire AVC';
	@override String get nalLengthSize => 'Taille de longueur NAL';
	@override String get scalingMatrix => 'Matrice de mise à l\'échelle personnalisée';
	@override String get streamIdentifier => 'Identifiant de flux';
	@override String get streamIndex => 'Index de flux';
	@override String get streamId => 'ID de flux';
	@override String get language => 'Langue';
	@override String get languageCode => 'Code de langue';
	@override String get streamTitle => 'Titre de la piste';
	@override String get channels => 'Canaux';
	@override String get sampleRate => 'Fréquence d\'échantillonnage';
	@override String get spatialAudio => 'Audio spatial';
	@override String get textBased => 'Basé sur du texte';
	@override String get subtitleFormat => 'Format annexe';
	@override String get provider => 'Fournisseur';
	@override String get matchScore => 'Score de correspondance';
	@override String get externalDelivery => 'Peut être diffusé séparément';
	@override String get sidecarPath => 'Chemin du fichier annexe';
	@override String get sourceStream => 'Copié depuis';
	@override String get temporary => 'Temporaire';
	@override String get timeBase => 'Base de temps';
	@override String get overallBitrate => 'Débit global';
	@override String get path => 'Chemin';
	@override String get fileName => 'Nom du fichier';
	@override String get size => 'Taille';
	@override String get totalSize => 'Taille totale';
	@override String get container => 'Conteneur';
	@override String get duration => 'Durée';
	@override String get previewThumbnails => 'Vignettes d\'aperçu';
	@override String get previewIndex => 'Index d\'aperçu';
	@override String get packetLength => 'Longueur du paquet';
	@override String get filePresent => 'Fichier présent';
	@override String get fileReadable => 'Lisible par le serveur';
	@override String get streamPath => 'Chemin du flux';
	@override String get optimizedForStreaming => 'Optimisé pour le streaming';
	@override String get has64bitOffsets => 'Décalages 64 bits';
	@override String get protocol => 'Protocole';
	@override String get mediaType => 'Type de média';
	@override String get sourceKind => 'Type de source';
	@override String get optimizedVersion => 'Version optimisée';
	@override String get optimizationTarget => 'Cible d\'optimisation';
	@override String get deletedAt => 'Supprimé';
	@override String get remoteSource => 'Source distante';
	@override String get infiniteStream => 'Flux infini';
	@override String get directPlay => 'Lecture directe';
	@override String get directStream => 'Flux direct';
	@override String get transcoding => 'Transcodage';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID de version';
	@override String get fileId => 'ID de fichier';
	@override String get defaultAudioTrack => 'Piste audio par défaut';
	@override String get defaultSubtitleTrack => 'Piste de sous-titres par défaut';
	@override String get subtitlesOff => 'Désactivés';
	@override String get flagDefault => 'Par défaut';
	@override String get flagForced => 'Forcé';
	@override String get flagSelected => 'Sélectionné';
	@override String get flagExternal => 'Externe';
	@override String get flagHearingImpaired => 'Sourds et malentendants';
	@override String get flagDub => 'Doublage';
	@override String get flagOriginal => 'Originale';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
}

// Path: mediaMenu
class Translations$mediaMenu$fr extends Translations$mediaMenu$en {
	Translations$mediaMenu$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marquer comme vu';
	@override String get markAsUnwatched => 'Marquer comme non visionné';
	@override String get removeFromContinueWatching => 'Supprimer de la liste "Continuer à regarder"';
	@override String get viewDetails => 'Voir les détails';
	@override String get goToSeries => 'Aller à la série';
	@override String get shufflePlay => 'Lecture aléatoire';
	@override String get shuffleNotAvailableOffline => 'La lecture aléatoire n’est pas disponible hors ligne';
	@override String get fileInfo => 'Informations sur le fichier';
	@override String get deleteEpisodeFromServer => 'Supprimer l\'épisode du serveur';
	@override String get deleteSeasonFromServer => 'Supprimer la saison du serveur';
	@override String get deleteShowFromServer => 'Supprimer la série du serveur';
	@override String get deleteMovieFromServer => 'Supprimer le film du serveur';
	@override String get deleteEpisodeTitle => 'Supprimer cet épisode ?';
	@override String get deleteSeasonTitle => 'Supprimer cette saison ?';
	@override String get deleteShowTitle => 'Supprimer cette série ?';
	@override String get deleteMovieTitle => 'Supprimer ce film ?';
	@override String get deleteEpisodeConfirm => 'Supprimer l\'épisode';
	@override String get deleteSeasonConfirm => 'Supprimer la saison';
	@override String get deleteShowConfirm => 'Supprimer la série';
	@override String get deleteMovieConfirm => 'Supprimer le film';
	@override String get deleteAnyway => 'Supprimer quand même';
	@override String confirmDeleteTarget({required Object title}) => 'Supprimer définitivement ${title} de votre serveur ?';
	@override String get deleteMultipleWarning => 'Cela inclut tous les épisodes et leurs fichiers.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Cela supprime ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisode qu\'elle contient, ainsi que son fichier.',
		other: 'Cela supprime les ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisodes qu\'elle contient, ainsi que leurs fichiers.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Cet élément est stocké sous forme de ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fichier, qui sera supprimé.',
		other: 'Cet élément est stocké sur ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fichiers, et ils seront tous supprimés.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} autre épisode est stocké dans le même fichier et sera également supprimé :',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} autres épisodes sont stockés dans le même fichier et seront également supprimés :',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG n\'a pas pu vérifier quels fichiers seront supprimés ; il risque donc d\'en supprimer plus que l\'élément nommé ci-dessus. Annulez et réessayez, ou supprimez quand même.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Votre serveur n\'a pas fourni les détails du fichier pour cet élément, PlezyNG ne peut donc pas vérifier quels fichiers seront supprimés. Il risque d\'en supprimer plus que l\'élément nommé ci-dessus.';
	@override String get mediaDeletedSuccessfully => 'Élément média supprimé avec succès';
	@override String get mediaFailedToDelete => 'Échec de la suppression de l\'élément média';
	@override String get rate => 'Noter';
	@override String get playFromBeginning => 'Lire depuis le début';
	@override String get playVersion => 'Lire la version...';
}

// Path: rateSheet
class Translations$rateSheet$fr extends Translations$rateSheet$en {
	Translations$rateSheet$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Noter';
	@override String get server => 'Serveur';
	@override String get favorite => 'Favori';
	@override String get favorited => 'Ajouté aux favoris';
	@override String get saved => 'Enregistré';
	@override String get notAvailable => 'Aucune correspondance trouvée';
	@override String get noConnectedServices => 'Connectez un service dans les paramètres pour pouvoir y attribuer une note.';
}

// Path: accessibility
class Translations$accessibility$fr extends Translations$accessibility$en {
	Translations$accessibility$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, série TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visionné';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} pour cent visionné';
	@override String get mediaCardUnwatched => 'non visionné';
	@override String get tapToPlay => 'Appuyez pour lire';
	@override String get decrease => 'Diminuer';
	@override String get increase => 'Augmenter';
	@override String decreaseValue({required Object label}) => 'Diminuer ${label}';
	@override String increaseValue({required Object label}) => 'Augmenter ${label}';
	@override String get hue => 'Teinte';
	@override String get saturation => 'Saturation';
	@override String get brightness => 'Luminosité';
	@override String get hexColor => 'Couleur hexadécimale';
	@override String get expandText => 'Développer le texte';
	@override String get collapseText => 'Replier le texte';
	@override String get alphabetNavigation => 'Navigation alphabétique';
	@override String get alphabetScrollHint => 'Balayez vers le haut ou le bas pour changer de lettre';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Ligne ${row} sur ${rowCount}, colonne ${column} sur ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Ligne ${row} sur ${rowCount}';
	@override String get autoScrollPlay => 'Lancer le défilement automatique';
	@override String get autoScrollPause => 'Suspendre le défilement automatique';
	@override String get hueShort => 'T';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Rouge';
	@override String get green => 'Grèce';
	@override String get blue => 'Bleu';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Accessibilité';
	@override String get summary => 'Text, contraste, mouvement et contrôles';
	@override String get systemHint => 'Les paramètres d\'accessibilité de votre appareil s\'appliquent toujours. Ces options ajoutent des ajustements au cours de PlezyNG.';
	@override String get readability => 'Lire et visibilité';
	@override String get textSize => '- la taille du texte';
	@override String get preview => 'Découvrez votre prochain article, lisez, écoutez et regardez à votre propre rythme.';
	@override String get boldText => 'Interface courageux';
	@override String get highContrast => 'Contraste élevé';
	@override String get highContrastHint => 'Un texte plus fort, des outils et des indicateurs de concentration sur les surfaces lumineuses ou sombres.';
	@override String get interaction => 'Motion et interaction';
	@override String get reduceMotion => 'Réduire la motion';
	@override String get reduceMotionHint => 'Arrêter les animations du repère de focus, les transitions de page et les effets décoratifs.';
	@override String get largeTargets => 'Objectifs touchés';
	@override String get largeTargetsHint => 'Donnez plus de place aux contrôles partagés pour la navigation touchante et assistante.';
	@override String get navigationHint => 'Utilisez Tab et Shift+Tab pour passer d’une commande à l’autre, Enter ou la barre d’espace pour l’activer, et Escape ou Retour pour fermer. Le zoom et les préférences de lecture sont disponibles lorsqu’un livre est ouvert.';
	@override String get textSizeDescription => 'Texte de l\'interface d\'échelle dans PlezyNG en plus de la configuration de taille du texte système de votre appareil.';
	@override String get boldTextHint => 'Utilisez un poids plus lourd pour les étiquettes et les messages d’interface afin de les rendre plus faciles à distinguer.';
}

// Path: tooltips
class Translations$tooltips$fr extends Translations$tooltips$en {
	Translations$tooltips$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Lecture aléatoire';
	@override String get playTrailer => 'Lire la bande-annonce';
	@override String get markAsWatched => 'Marquer comme vu';
	@override String get markAsUnwatched => 'Marquer comme non vu';
}

// Path: audioTracks
class Translations$audioTracks$fr extends Translations$audioTracks$en {
	Translations$audioTracks$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Piste audio ${n}';
}

// Path: videoControls
class Translations$videoControls$fr extends Translations$videoControls$en {
	Translations$videoControls$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Sous-titres';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Format letterbox';
	@override String get fillScreen => 'Remplir l’écran';
	@override String get stretch => 'Étirer';
	@override String get lockRotation => 'Verrouiller la rotation';
	@override String get unlockRotation => 'Déverrouiller la rotation';
	@override String get timerActive => 'Minuterie active';
	@override String playbackWillPauseIn({required Object duration}) => 'La lecture sera mise en pause dans ${duration}';
	@override String get sleepTimerEndOfVideo => 'Fin de la vidéo actuelle';
	@override String get sleepTimerStopAtHeader => 'Arrêter à';
	@override String get sleepTimerDurationHeader => 'Minuterie';
	@override String get playbackWillPauseAtEnd => 'La lecture sera mise en pause à la fin de cette vidéo';
	@override String get stillWatching => 'Toujours en train de regarder ?';
	@override String pausingIn({required Object seconds}) => 'Pause dans ${seconds}s';
	@override String get continueWatching => 'Continuer';
	@override String get autoPlayNext => 'Lecture automatique de l’élément suivant';
	@override String get playNext => 'Lire l\'épisode suivant';
	@override String get playButton => 'Lire';
	@override String get pauseButton => 'Pause';
	@override String get playbackPaused => 'En pause';
	@override String get playbackResumed => 'En lecture';
	@override String get loadingVideo => 'Chargement de la vidéo';
	@override String get showPlaybackControls => 'Afficher les commandes de lecture';
	@override String get hidePlaybackControls => 'Masquer les commandes de lecture';
	@override String seekBackwardButton({required Object seconds}) => 'Reculer de ${seconds} secondes';
	@override String seekForwardButton({required Object seconds}) => 'Avancer de ${seconds} secondes';
	@override String get previousButton => 'Épisode précédent';
	@override String get nextButton => 'Épisode suivant';
	@override String get previousChapterButton => 'Chapitre précédent';
	@override String get nextChapterButton => 'Chapitre suivant';
	@override String get muteButton => 'Couper le son';
	@override String get unmuteButton => 'Rétablir le son';
	@override String get settingsButton => 'Paramètres de lecture';
	@override String get tracksButton => 'Audio et sous-titres';
	@override String get chaptersButton => 'Chapitres';
	@override String get versionQualityButton => 'Version et qualité';
	@override String get versionColumnHeader => 'Version';
	@override String get qualityColumnHeader => 'Qualité';
	@override String get qualityOriginal => 'Originale';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodage indisponible — lecture en qualité originale';
	@override String get subtitleUnavailableFallback => 'Impossible de charger les sous-titres sélectionnés — poursuite de la lecture sans sous-titres';
	@override String get pipButton => 'Mode image dans l’image';
	@override String get aspectRatioButton => 'Format d\'image';
	@override String get ambientLighting => 'Éclairage ambiant';
	@override String get fullscreenButton => 'Passer en mode plein écran';
	@override String get exitFullscreenButton => 'Quitter le mode plein écran';
	@override String get alwaysOnTopButton => 'Toujours au premier plan';
	@override String get rotationLockButton => 'Verrouillage de rotation';
	@override String get lockScreen => 'Verrouiller l\'écran';
	@override String get screenLockButton => 'Verrouillage de l\'écran';
	@override String get timelineSlider => 'Barre de progression vidéo';
	@override String get volumeSlider => 'Niveau du volume';
	@override String endsAt({required Object time}) => 'Se termine à ${time}';
	@override String get pipActive => 'Lecture en mode image dans l\'image';
	@override String get pipFailed => 'Échec du démarrage du mode image dans l\'image';
	@override String get screenshotSaved => 'Capture d\'écran enregistrée';
	@override String get screenshotFailed => 'Impossible de prendre une capture d’écran';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent} %';
	@override String volumePercent({required Object percent}) => 'Volume ${percent} %';
	@override late final Translations$videoControls$pipErrors$fr pipErrors = Translations$videoControls$pipErrors$fr.internal(_root);
	@override String get chapters => 'Chapitres';
	@override String get noChaptersAvailable => 'Aucun chapitre disponible';
	@override String get queue => 'File d\'attente';
	@override String get noQueueItems => 'Aucun élément dans la file d\'attente';
	@override String get noAudioDevicesAvailable => 'Aucun appareil audio disponible';
	@override String get searchSubtitles => 'Rechercher des sous-titres';
	@override String get language => 'Langue';
	@override String get noSubtitlesFound => 'Aucun sous-titre trouvé';
	@override String get subtitleDownloaded => 'Sous-titre téléchargé';
	@override String get subtitleDownloadedNotApplied => 'Le sous-titre a été téléchargé, mais n’a pas pu être sélectionné';
	@override String get subtitleDownloadFailed => 'Échec du téléchargement du sous-titre';
	@override String get searchLanguages => 'Rechercher des langues...';
	@override String get skipIntro => 'Passer l’intro';
	@override String get skipCredits => 'Passer le générique';
	@override String get nextEpisode => 'Épisode suivant';
	@override String subtitleTrack({required Object n}) => 'Piste ${n}';
	@override String subtitleFile({required Object name}) => 'Sous-titre ${name}';
	@override String forcedTrack({required Object label}) => '${label} (forcé)';
	@override String get osdSubtitlesOff => 'Sous-titres : désactivés';
	@override String osdSubtitles({required Object track}) => 'Sous-titres : ${track}';
	@override String osdAudio({required Object track}) => 'Audio : ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} en ligne',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} écrans',
	);
	@override String get trackSelectionTitle => 'Choisir les traces avant le playback';
	@override String get trackSelectionAuto => 'Sélection automatique';
	@override String get openMiniPlayer => 'Jeux mini ouverts';
	@override String get returnToFullPlayer => 'Retour au joueur complet';
	@override String get loadSubtitleFile => 'Réserver le sous-titre de fichier...';
	@override String get subtitleLoadFailed => 'Faillite de télécharger le sous-titre';
	@override String get skipAds => '- les ads';
	@override String get tapToUnlock => 'Appuyez pour déverrouiller';
	@override String get tapAgainToUnlock => 'Appuyez à nouveau pour déverrouiller';
	@override String get segmentLoopHelp => 'Mettez A, puis définissez B plus tard dans la ligne de temps.';
	@override String get setLoopStart => 'Démarrer le circuit (A)';
	@override String get setLoopEnd => 'Mise à jour de la fin (B)';
	@override String get clearSegmentLoop => 'Un segment clair';
	@override String get setLoopStartFirst => 'Sélectionnez le début (A) avant la fin (B).';
	@override String get loopEndAfterStart => 'La fin doit être plus tard que le début.';
	@override String get segmentLoopUnavailable => 'Le segment looping n\'est pas disponible pour ce playback.';
	@override String get bookmarksHelp => 'Les notes sont enregistrées sur ce appareil. Sélectionnez une pour aller à cette heure.';
	@override String get bookmarksButton => 'Les Bookmarks';
	@override String get chaptersAndBookmarks => 'Chapitres et bookmarks';
	@override String get segmentLoop => 'Le Segment Loop';
	@override String get addBookmark => 'Ajoutez le bookmark';
	@override String get bookmarkName => 'Nom de Bookmark';
	@override String get bookmarkNameHint => 'Par exemple, la scène d’ouverture';
	@override String bookmarkDefaultName({required Object n}) => 'Le Bookmark ${n}';
	@override String get bookmarkNameRequired => 'Entrez un nom pour ce livre.';
	@override String get deleteBookmark => 'Supprimer le bookmark';
	@override String get bookmarkLimitReached => 'Cet article a déjà 100 bookmarks.';
	@override String get bookmarkUnavailable => 'Je ne pouvais pas sauver ou supprimer cette note.';
	@override String get bookmarkSaved => 'Le Bookmark est sauvé.';
	@override String get bookmarkDeleted => 'Le Bookmark est supprimé.';
	@override String loopPointSet({required Object point, required Object time}) => 'Le point Loop ${point} Sélectionnez à ${time}.';
	@override String get noChaptersOrBookmarks => 'Aucun chapitre ou livre n\'est disponible.';
	@override String get loopPointNotSet => 'Pas fixé';
}

// Path: messages
class Translations$messages$fr extends Translations$messages$en {
	Translations$messages$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marqué comme vu';
	@override String get markedAsUnwatched => 'Marqué comme non vu';
	@override String get markedAsWatchedOffline => 'Marqué comme vu (se synchronisera lorsque vous serez en ligne)';
	@override String get markedAsUnwatchedOffline => 'Marqué comme non vu (sera synchronisé lorsque vous serez en ligne)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Supprimé automatiquement : ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargement vu supprimé automatiquement',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargements vus supprimés automatiquement',
	);
	@override String get removedFromContinueWatching => 'Supprimé de « Continuer à regarder »';
	@override String errorLoading({required Object error}) => 'Erreur : ${error}';
	@override String get searchPartialResults => 'Certains serveurs multimédia n\'ont pas pu être interrogés. Affichage des résultats disponibles.';
	@override String get streamInterrupted => 'La lecture a été interrompue. Appuyez sur Lecture ou avancez pour réessayer.';
	@override String get liveStreamInterrupted => 'Le direct a été interrompu. Appuyez sur Lecture pour réessayer.';
	@override String get fileInfoNotAvailable => 'Informations sur le fichier non disponibles';
	@override String get playbackAuthenticationRequired => 'Reconnectez-vous au serveur multimédia pour lire cet élément.';
	@override String get playbackServerUnavailable => 'Le serveur multimédia est indisponible. Réessayez plus tard.';
	@override String get playbackDataInvalid => 'Le serveur a renvoyé des informations de lecture non valides.';
	@override String get playbackCancelled => 'La lecture a été annulée.';
	@override String get playbackFailed => 'Impossible de démarrer la lecture.';
	@override String playbackFailedDetail({required Object error}) => 'Impossible de démarrer la lecture : ${error}';
	@override String get audioOutputFailed => 'La sortie audio a cessé de répondre. Vérifiez la connexion audio du téléviseur ou de l’ampli ; si les autres applications n’ont pas de son non plus, redémarrez l’appareil.';
	@override String get mediaUnavailable => 'Ce contenu n’est plus disponible.';
	@override String errorLoadingFileInfo({required Object error}) => 'Erreur lors du chargement des informations sur le fichier : ${error}';
	@override String get errorLoadingSeries => 'Erreur lors du chargement de la série';
	@override String get musicNotSupported => 'La lecture de musique n\'est pas encore prise en charge';
	@override String get noDescriptionAvailable => 'Aucune description disponible';
	@override String get noProfilesAvailable => 'Aucun profil disponible';
	@override String get contactAdminForProfiles => 'Contactez votre administrateur serveur pour ajouter des profils';
	@override String get unableToDetermineLibrarySection => 'Impossible de déterminer la section de la bibliothèque pour cet élément';
	@override String get logsCleared => 'Journaux effacés';
	@override String get logsCopied => 'Journaux copiés dans le presse-papiers';
	@override String get noLogsAvailable => 'Aucun journal disponible';
	@override String libraryScanning({required Object title}) => 'Analyse de « ${title} »…';
	@override String libraryScanStarted({required Object title}) => 'Analyse de la bibliothèque lancée pour « ${title} »';
	@override String libraryScanFailed({required Object error}) => 'Échec de l’analyse de la bibliothèque : ${error}';
	@override String metadataRefreshing({required Object title}) => 'Actualisation des métadonnées de « ${title} »…';
	@override String metadataRefreshStarted({required Object title}) => 'Actualisation des métadonnées lancée pour « ${title} »';
	@override String metadataRefreshFailed({required Object error}) => 'Échec de l’actualisation des métadonnées : ${error}';
	@override String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';
	@override String get noSeasonsFound => 'Aucune saison trouvée';
	@override String get seasonsLoadFailed => 'Impossible de charger les saisons';
	@override String get noEpisodesFound => 'Aucun épisode trouvé dans la première saison';
	@override String get noEpisodesFoundGeneral => 'Aucun épisode trouvé';
	@override String get episodesLoadFailed => 'Impossible de charger les épisodes';
	@override String get noResultsFound => 'Aucun résultat trouvé';
	@override String sleepTimerSet({required Object label}) => 'Minuterie de mise en veille réglée sur ${label}';
	@override String get noItemsAvailable => 'Aucun élément disponible';
	@override String get failedToCreatePlayQueueNoItems => 'Impossible de créer la file d’attente de lecture : aucun élément';
	@override String failedPlayback({required Object action, required Object error}) => 'Échec de ${action} : ${error}';
	@override String get switchingToCompatiblePlayer => 'Passage au lecteur compatible...';
	@override String get serverLimitTitle => 'Échec de la lecture';
	@override String get serverLimitBody => 'Erreur serveur (HTTP 500). Une limite de bande passante/transcodage a probablement rejeté cette session. Demandez au propriétaire de l\'ajuster.';
	@override String get mediaUnreadableTitle => 'Fichier indisponible';
	@override String get mediaUnreadableBody => 'Le serveur a trouvé cet élément mais n\'a pas pu lire son fichier (HTTP 404). Le fichier a probablement été déplacé, supprimé, ou son stockage est hors ligne. Demandez au propriétaire du serveur de vérifier le fichier et de relancer l\'analyse de la bibliothèque.';
	@override String get serverBusyTitle => 'Flux indisponible';
	@override String get serverBusyBody => 'Le serveur a refusé à plusieurs reprises de diffuser ce fichier (HTTP 503). Il est peut-être en cours de redémarrage ou occupé, ou le stockage du fichier est peut-être hors ligne. Réessayez dans un instant. Si le problème persiste, demandez au propriétaire du serveur de vérifier le serveur et le stockage du fichier.';
	@override String get playbackNotAllowedTitle => 'Lecture non autorisée';
	@override String get playbackNotAllowedBody => 'Le serveur a refusé de diffuser cet élément (HTTP 403). Votre compte n\'a peut-être pas l\'autorisation de le lire, ou le serveur n\'autorise peut-être la lecture que sur son réseau local.';
	@override String get logsUploaded => 'Journaux envoyés';
	@override String get logsUploadFailed => 'Échec de l’envoi des journaux';
	@override String get logId => 'Identifiant du journal';
	@override String get burnedSubtitlesUseMenu => 'Les sous-titres sont incrustés à l’image de ce flux. Modifiez-les depuis le menu des sous-titres.';
	@override String get noVideoUrl => 'Aucune URL vidéo disponible';
	@override String get playbackNoMediaSources => 'Le serveur n’a renvoyé aucune source multimédia lisible';
	@override String get playbackDataNotPrepared => 'La lecture a été lancée avant que les données nécessaires soient prêtes';
	@override String get streamSelectionUnavailable => 'La sélection des flux n’est pas disponible pour cette source';
	@override String get streamSelectionFailed => 'Impossible d’appliquer les flux sélectionnés';
	@override String get trackSelectionNotRemembered => 'Ce choix de piste ne s’applique qu’à la lecture en cours.';
	@override String get serverUnavailableForProfile => 'Aucun serveur n’est disponible pour le profil actif';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$fr extends Translations$subtitlingStyling$en {
	Translations$subtitlingStyling$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Le fox brune rapide saute sur le chien laïc';
	@override String get text => 'Texte';
	@override String get border => 'Bordure';
	@override String get background => 'Arrière-plan';
	@override String get fontSize => 'Taille de la police';
	@override String get textColor => 'Couleur du texte';
	@override String get borderSize => 'Taille de la bordure';
	@override String get borderColor => 'Couleur de la bordure';
	@override String get backgroundOpacity => 'Opacité d\'arrière-plan';
	@override String get backgroundColor => 'Couleur d\'arrière-plan';
	@override String get position => 'Position';
	@override String get assOverride => 'Remplacement ASS';
	@override String get overrideScale => 'Mettre à l’échelle';
	@override String get overrideForce => 'Forcer';
	@override String get overrideStrip => 'Supprimer le style';
	@override String get positionTop => 'Haut';
	@override String get positionBottom => 'Bas';
	@override String get useMargins => 'Utiliser les marges';
	@override String get useMarginsDescription => 'Autoriser les sous-titres textuels dans l’espace en dehors de la vidéo. Les sous-titres stylés peuvent conserver leur position d’origine.';
	@override String get anchorToScreen => 'Ancrer à l’écran';
	@override String get anchorToScreenDescription => 'Afficher les sous-titres textuels dans les bandes noires sous les vidéos en écran large';
	@override String get bold => 'Gras';
	@override String get italic => 'Italique';
	@override String get renderResolution => 'Résolution de rendu';
	@override String get renderResolutionScreen => 'Résolution de l\'écran';
	@override String get renderResolutionVideo => 'Résolution de la vidéo';
	@override String get fontSizeDescription => 'Mettez la taille du texte sous-titre sur cet appareil.';
	@override String get textColorDescription => 'Choisissez la couleur utilisée pour le texte sous-titre.';
	@override String get borderSizeDescription => 'Mettez la profondeur de l\'outline autour du texte sous-titre.';
	@override String get borderColorDescription => 'Choisissez la couleur utilisée pour le sous-titre.';
	@override String get backgroundColorDescription => 'Choisissez la couleur derrière le texte sous-titre.';
	@override String get backgroundOpacityDescription => 'Définissez la transparence du fond de sous-titre : 0% est clair et 100% solide.';
	@override String get positionDescription => 'Mouvez les sous-titres verticalement. 0% est le haut de la vidéo et 100% est le bas.';
	@override String get assOverrideDescription => 'Choisissez si le joueur suit, ajuste, remplace ou supprime les styles intégrés dans les sous-titres ASS.';
	@override late final Translations$subtitlingStyling$assOverrideOptions$fr assOverrideOptions = Translations$subtitlingStyling$assOverrideOptions$fr.internal(_root);
	@override String get renderResolutionDescription => 'Choisissez la résolution utilisée pour rasteriser l\'image et les sous-titres ASS. Les échelles Android inférieures peuvent réduire le travail de rendement mais ressembler plus doux.';
	@override late final Translations$subtitlingStyling$renderResolutionOptions$fr renderResolutionOptions = Translations$subtitlingStyling$renderResolutionOptions$fr.internal(_root);
	@override String get boldDescription => 'Tirez le texte sous-titre dans un poids plus lourd.';
	@override String get italicDescription => 'Téléchargez le texte sous-titre en italien.';
}

// Path: mpvConfig
class Translations$mpvConfig$fr extends Translations$mpvConfig$en {
	Translations$mpvConfig$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Paramètres avancés du lecteur vidéo';
	@override String get presets => 'Préréglages';
	@override String get noPresets => 'Aucun préréglage enregistré';
	@override String get saveAsPreset => 'Enregistrer comme préréglage...';
	@override String get presetName => 'Nom du préréglage';
	@override String get presetNameHint => 'Entrez un nom pour ce préréglage';
	@override String get loadPreset => 'Charger';
	@override String get deletePreset => 'Supprimer';
	@override String get presetSaved => 'Préréglage enregistré';
	@override String get presetLoaded => 'Préréglage chargé';
	@override String get presetDeleted => 'Préréglage supprimé';
	@override String get confirmDeletePreset => 'Êtes-vous sûr de vouloir supprimer ce préréglage ?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Ajouter une ligne';
	@override String get removeLine => 'Supprimer la ligne';
	@override String get embeddedVoHint => 'vo, gpu-context et gpu-api sont ignorés sous Linux : la vidéo intégrée est toujours rendue via vo=libmpv sur le plan vidéo, et gpu-next (dont les shaders de calcul comme ArtCNN ont besoin) ne peut pas fonctionner en mode intégré.';
}

// Path: dialog
class Translations$dialog$fr extends Translations$dialog$en {
	Translations$dialog$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmer l\'action';
}

// Path: profiles
class Translations$profiles$fr extends Translations$profiles$en {
	Translations$profiles$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Ajouter un profil PlezyNG';
	@override String get switchingProfile => 'Changement de profil…';
	@override String get deleteThisProfileTitle => 'Supprimer ce profil ?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Supprimer ${displayName}. Les connexions ne sont pas affectées.';
	@override String get active => 'Actif';
	@override String get manage => 'Gérer';
	@override String get delete => 'Supprimer';
	@override String get signOut => 'Se déconnecter';
	@override String get signOutPlexTitle => 'Se déconnecter de Plex ?';
	@override String signOutPlexMessage({required Object displayName}) => 'Supprimer ${displayName} et tous les utilisateurs Plex Home ? Reconnexion possible à tout moment.';
	@override String get signOutPlexDeleteDownloads => 'Supprimer aussi les téléchargements';
	@override String get signOutPlexDeleteDownloadsDescription => 'Sinon, ils restent sur cet appareil et réapparaissent lorsque vous vous reconnectez à ce compte.';
	@override String get signedOutPlex => 'Déconnecté de Plex.';
	@override String get signOutFailed => 'Échec de la déconnexion.';
	@override String get sectionTitle => 'Profils';
	@override String get summarySingle => 'Ajoutez des profils pour mélanger utilisateurs gérés et identités locales';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profils · actif : ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profils';
	@override String get removeConnectionTitle => 'Retirer la connexion ?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Supprimer l\'accès de ${displayName} à ${connectionLabel}. Les autres profils le conservent.';
	@override String get deleteProfileTitle => 'Supprimer le profil ?';
	@override String deleteProfileMessage({required Object displayName}) => 'Supprimer ${displayName} et ses connexions. Les serveurs restent disponibles.';
	@override String get profileNameLabel => 'Nom du profil';
	@override String get pinProtectionLabel => 'Protection par code PIN';
	@override String get copyAutomationLink => 'Copie Android liens d\'automatisation';
	@override String get copyAutomationLinkDescription => 'Sélectionnez ce profil à partir d\'une intention ou d\'automatisation Android.';
	@override String get automationLinkCopied => 'Le lien de profil automatique est copié.';
	@override String get pinManagedByPlex => 'PIN géré par Plex. Modifier sur plex.tv.';
	@override String get noPinSetEditOnPlex => 'Aucun PIN défini. Pour en exiger un, modifiez l\'utilisateur Home sur plex.tv.';
	@override String get setPin => 'Définir un PIN';
	@override String get setPinTitle => 'Définir un PIN';
	@override String get confirmPinTitle => 'Confirmer le PIN';
	@override String get pinSet => 'PIN défini';
	@override String get changePin => 'Modifier';
	@override String get removePin => 'Retirer';
	@override String get connectionsLabel => 'Connexions';
	@override String get add => 'Ajouter';
	@override String get deleteProfileButton => 'Supprimer le profil';
	@override String get noConnectionsHint => 'Aucune connexion — ajoutez-en une pour utiliser ce profil.';
	@override String get noConnections => 'Aucune connexion';
	@override String get plexHomeAccount => 'Compte Plex Home';
	@override String plexAccountChip({required Object account}) => 'Compte Plex : ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} via ${account}';
	@override String get connectionDefault => 'Par défaut';
	@override String connectionAs({required Object displayName}) => 'en tant que ${displayName}';
	@override String get makeDefault => 'Définir par défaut';
	@override String get removeConnection => 'Retirer';
	@override String get profileRenamed => 'Profil renommé.';
	@override String borrowAddTo({required Object displayName}) => 'Ajouter à ${displayName}';
	@override String get borrowExplain => 'Emprunter la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.';
	@override String get borrowEmpty => 'Rien à emprunter pour le moment.';
	@override String get borrowEmptySubtitle => 'Connectez d\'abord Plex, Jellyfin ou Emby à un autre profil.';
	@override String get borrowLoadFailed => 'Impossible de charger les connexions disponibles. Réessayez.';
	@override String borrowFromProfile({required Object displayName}) => 'De ${displayName}';
	@override String get borrowConnectionBorrowed => 'Connexion empruntée.';
	@override String get borrowFailed => 'Impossible d\'emprunter la connexion.';
	@override String get incorrectPin => 'PIN incorrect.';
	@override String get incorrectPinTryAgain => 'PIN incorrect. Veuillez réessayer.';
	@override String get sourceProfileMissingParentAccount => 'Le profil source ne possède pas de compte parent.';
	@override String get failedToLoadHomeUsers => 'Impossible de charger vos utilisateurs Plex Home. Vérifiez votre connexion et réessayez.';
	@override String get failedToVerifyPin => 'Impossible de vérifier le PIN.';
	@override String get newProfile => 'Nouveau profil';
	@override String get profileNameHint => 'ex. Invités, Enfants, Salon familial';
	@override String get pinProtectionOptional => 'Protection par PIN (optionnelle)';
	@override String get pinExplain => 'PIN à 4 chiffres requis pour changer de profil.';
	@override String get continueButton => 'Continuer';
	@override String get pinsDontMatch => 'Les PIN ne correspondent pas';
	@override String get tokenIdentityMismatch => 'Le jeton du profil Plex correspond à un serveur inattendu';
	@override String get settingsLocked => 'Les paramètres sont bloqués pour ce profil.';
	@override String get unlockSettings => 'Débarquer les paramètres';
	@override String get showExploreForProfile => 'Afficher Explorez pour ce profil';
	@override String get showExploreForProfileDescription => 'Désactivez pour supprimer Explore de la navigation de ce profil.';
}

// Path: connections
class Translations$connections$fr extends Translations$connections$en {
	Translations$connections$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Connexions';
	@override String get addConnection => 'Ajouter une connexion';
	@override String get addConnectionSubtitleNoProfile => 'Connectez-vous avec Plex ou connectez un serveur Jellyfin ou Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Ajouter à ${displayName} : Plex, Jellyfin, Emby ou une autre connexion de profil';
	@override String sessionExpiredOne({required Object name}) => 'Session expirée pour ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Session expirée pour ${count} serveurs';
	@override String accessDeniedOne({required Object name}) => '${name} a refusé l\'accès à ce compte';
	@override String accessDeniedMany({required Object count}) => '${count} serveurs ont refusé l\'accès à ce compte';
	@override String get signInAgain => 'Se reconnecter';
	@override String editMediaBrowserTitle({required Object product}) => 'Modifier la connexion ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Ajoutez ou retirez des URL pour ${serverName}. PlezyNG utilisera l\'URL joignable avec la latence la plus faible.';
}

// Path: accountPreferences
class Translations$accountPreferences$fr extends Translations$accountPreferences$en {
	Translations$accountPreferences$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Préférences du compte';
	@override String hubSubtitleSingle({required Object account}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${count} comptes';
	@override String get pickAccount => 'Chaque compte enregistre ses propres préférences. Choisissez celui à modifier.';
	@override String get storedOnAccount => 'Ces options sont enregistrées sur le compte lui-même : toutes les applications connectées les utilisent, y compris PlezyNG sur vos autres appareils.';
	@override String get noAccounts => 'Aucun compte à configurer';
	@override String get noAccountsHint => 'Connectez-vous à Plex, ou connectez un serveur Jellyfin ou Emby : les préférences enregistrées sur ce compte apparaîtront ici.';
	@override String get unavailable => 'Impossible de joindre ce compte';
	@override String get loadFailed => 'Impossible de charger ces préférences';
	@override String get noPreference => 'Aucune préférence';
	@override String get notSet => 'Non défini';
	@override late final Translations$accountPreferences$groups$fr groups = Translations$accountPreferences$groups$fr.internal(_root);
	@override String get preferredAudioLanguage => 'Langue audio préférée';
	@override String get autoSelectAudio => 'Choisir l\'audio par langue';
	@override String get autoSelectAudioDescription => 'Désactivé : la piste audio marquée par défaut dans le fichier est conservée.';
	@override String get preferredSubtitleLanguage => 'Langue de sous-titres préférée';
	@override String get subtitleMode => 'Activer les sous-titres';
	@override late final Translations$accountPreferences$subtitleModes$fr subtitleModes = Translations$accountPreferences$subtitleModes$fr.internal(_root);
	@override String get subtitleAccessibility => 'Sous-titres SDH';
	@override late final Translations$accountPreferences$subtitleAccessibilityOptions$fr subtitleAccessibilityOptions = Translations$accountPreferences$subtitleAccessibilityOptions$fr.internal(_root);
	@override String get forcedSubtitles => 'Sous-titres forcés';
	@override late final Translations$accountPreferences$forcedSubtitleOptions$fr forcedSubtitleOptions = Translations$accountPreferences$forcedSubtitleOptions$fr.internal(_root);
	@override String get displayMissingEpisodes => 'Afficher les épisodes manquants';
	@override String get displayMissingEpisodesDescription => 'Répertorier les épisodes connus du serveur mais sans fichier.';
	@override String get hidePlayedInLatest => 'Masquer les éléments vus dans « Récemment ajouté »';
	@override String get hidePlayedInLatestDescription => 'Exclure les éléments déjà vus des lignes « Récemment ajouté » du serveur.';
	@override String get displayCollectionsView => 'Afficher la vue Collections';
	@override String get displayCollectionsViewDescription => 'Proposer la vue Collections du serveur en plus de vos bibliothèques.';
	@override String get rewatchingInNextUp => 'Conserver les séries revues dans « À suivre »';
	@override String get rewatchingInNextUpDescription => 'Une fois une série terminée, si vous la recommencez, « À suivre » suit le revisionnage au lieu de la retirer.';
	@override String get watchedIndicator => 'Indicateurs de visionnage';
	@override late final Translations$accountPreferences$watchedIndicatorOptions$fr watchedIndicatorOptions = Translations$accountPreferences$watchedIndicatorOptions$fr.internal(_root);
	@override String get mediaReviewsVisibility => 'Notes et critiques';
	@override late final Translations$accountPreferences$mediaReviewsOptions$fr mediaReviewsOptions = Translations$accountPreferences$mediaReviewsOptions$fr.internal(_root);
	@override String get preferredAudioLanguageDescription => 'Préférez les traces audio dans cette langue lorsque le serveur ou le joueur sélectionne automatiquement une piste.';
	@override String get preferredSubtitleLanguageDescription => 'Préférez les traces de sous-titres dans cette langue lorsque les sous-tits sont sélectionnés automatiquement.';
	@override String get subtitleAccessibilityDescription => 'Choisissez si les captions SDH sont préférées ou requises lors de la sélection automatique des sous-titres.';
	@override String get forcedSubtitleDescription => 'Choisissez si les traces de sous-titres forcés sont préférées ou requises lors de la sélection automatique.';
	@override String get watchedIndicatorDescription => 'Choisissez quels types de médias reçoivent un signe d\'attente dans l\'interface du serveur.';
	@override String get mediaReviewsVisibilityDescription => 'Choisissez quel public et quelles notations critiques le serveur affiche sur les pages de médias.';
	@override String get subtitleModeDescription => 'Choisissez quand les sous-titres s\'affichent automatiquement pour ce compte serveur.';
	@override String get hubDescription => 'Ces préférences sont stockées sur votre compte de serveur médiatique et peuvent s\'appliquer également à d\'autres clients.';
}

// Path: discover
class Translations$discover$fr extends Translations$discover$en {
	Translations$discover$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Découvrir';
	@override String get noContentAvailable => 'Aucun contenu disponible';
	@override String get addMediaToLibraries => 'Ajoutez des médias à vos bibliothèques';
	@override String get continueWatching => 'Continuer à regarder';
	@override String continueWatchingIn({required Object library}) => 'Continuer à regarder dans ${library}';
	@override String get nextUp => 'À suivre';
	@override String nextUpIn({required Object library}) => 'À suivre dans ${library}';
	@override String get recentlyAdded => 'Récemment ajouté';
	@override String recentlyAddedIn({required Object library}) => 'Récemment ajouté dans ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Derniers albums dans ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Récemment lus dans ${library}';
	@override String mostPlayedIn({required Object library}) => 'Les plus lus dans ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Aperçu';
	@override String get cast => 'Distribution';
	@override late final Translations$discover$findNext$fr findNext = Translations$discover$findNext$fr.internal(_root);
	@override String get extras => 'Bandes-annonces et bonus';
	@override String get studio => 'Studio';
	@override String get rating => 'Évaluation';
	@override String get director => 'Réalisateur';
	@override String get directors => 'Réalisateurs';
	@override String get movie => 'Film';
	@override String get tvShow => 'Série TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min restantes';
	@override String get moreLikeThis => 'Plus de contenus similaires';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titre',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titres',
	);
	@override late final Translations$discover$person$fr person = Translations$discover$person$fr.internal(_root);
}

// Path: errors
class Translations$errors$fr extends Translations$errors$en {
	Translations$errors$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Échec de la recherche : ${error}';
	@override String get searchUnavailable => 'La recherche n\'a pu atteindre aucun serveur multimédia.';
	@override String connectionTimeout({required Object context}) => 'Délai d\'attente de connexion dépassé pendant le chargement ${context}';
	@override String get connectionFailed => 'Impossible de se connecter au serveur multimédia';
	@override String unableToLoad({required Object context}) => 'Impossible de charger ${context}. Réessayez.';
	@override String get noClientAvailable => 'Aucun client disponible';
	@override String get pleaseEnterToken => 'Veuillez saisir un jeton';
	@override String get invalidToken => 'Jeton non valide';
	@override String failedToVerifyToken({required Object error}) => 'Échec de la vérification du jeton : ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossible de changer de profil vers ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Impossible de supprimer ${displayName}';
	@override String get failedToRate => 'Impossible de mettre à jour la note';
	@override String get reasonTimedOut => 'le délai d\'attente de la connexion a été dépassé';
	@override String get reasonUnreachable => 'le serveur n\'a pas pu être atteint';
	@override String get reasonRefused => 'le serveur a refusé la requête';
	@override String get reasonNotFound => 'l\'élément ne se trouve plus sur le serveur';
	@override String get reasonServerError => 'le serveur a signalé une erreur';
	@override String get reasonCancelled => 'la requête a été annulée';
	@override String get reasonUnexpected => 'une erreur inattendue s\'est produite';
}

// Path: libraries
class Translations$libraries$fr extends Translations$libraries$en {
	Translations$libraries$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Jouer un film aléatoire';
	@override String get randomPickFailed => 'Je ne pouvais pas choisir un film de cette bibliothèque.';
	@override String get title => 'Bibliothèques';
	@override String get fallbackTitle => 'Bibliothèque';
	@override String get scanLibraryFiles => 'Scanner les fichiers de la bibliothèque';
	@override String get scanLibrary => 'Scanner la bibliothèque';
	@override String get analyze => 'Analyser';
	@override String get analyzeLibrary => 'Analyser la bibliothèque';
	@override String get refreshMetadata => 'Actualiser les métadonnées';
	@override String get emptyTrash => 'Vider la corbeille';
	@override String emptyingTrash({required Object title}) => 'Vidage de la corbeille de « ${title} »…';
	@override String trashEmptied({required Object title}) => 'Corbeille vidée pour « ${title} »';
	@override String failedToEmptyTrash({required Object error}) => 'Échec du vidage de la corbeille : ${error}';
	@override String analyzing({required Object title}) => 'Analyse de « ${title} »…';
	@override String analysisStarted({required Object title}) => 'Analyse lancée pour « ${title} »';
	@override String failedToAnalyze({required Object error}) => 'Échec de l’analyse de la bibliothèque : ${error}';
	@override String get noLibrariesFound => 'Aucune bibliothèque trouvée';
	@override String get allLibrariesHidden => 'Toutes les bibliothèques sont masquées';
	@override String hiddenLibrariesCount({required Object count}) => 'Bibliothèques masquées (${count})';
	@override String get thisLibraryIsEmpty => 'Cette bibliothèque est vide';
	@override String get noItemsMatchFilters => 'Aucun élément ne correspond aux filtres actifs';
	@override String get resetFilters => 'Réinitialiser les filtres';
	@override String get all => 'Tout';
	@override String get clearAll => 'Tout effacer';
	@override String scanLibraryConfirm({required Object title}) => 'Voulez-vous vraiment scanner « ${title} » ?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Voulez-vous vraiment analyser « ${title} » ?';
	@override String refreshMetadataConfirm({required Object title}) => 'Voulez-vous vraiment actualiser les métadonnées de « ${title} » ?';
	@override String emptyTrashConfirm({required Object title}) => 'Voulez-vous vraiment vider la corbeille de « ${title} » ?';
	@override String get manageLibraries => 'Gérer les bibliothèques';
	@override String get sort => 'Trier';
	@override String get sortBy => 'Trier par';
	@override String get filters => 'Filtres';
	@override String get confirmActionMessage => 'Êtes-vous sûr de vouloir effectuer cette action ?';
	@override String get showLibrary => 'Afficher la bibliothèque';
	@override String get hideLibrary => 'Masquer la bibliothèque';
	@override String get libraryOptions => 'Options de bibliothèque';
	@override String get content => 'contenu de la bibliothèque';
	@override String get selectLibrary => 'Sélectionner la bibliothèque';
	@override String filtersWithCount({required Object count}) => 'Filtres (${count})';
	@override String get noRecommendations => 'Aucune recommandation disponible';
	@override String get noCollections => 'Aucune collection dans cette bibliothèque';
	@override String get noFoldersFound => 'Aucun dossier trouvé';
	@override String get folders => 'dossiers';
	@override late final Translations$libraries$tabs$fr tabs = Translations$libraries$tabs$fr.internal(_root);
	@override late final Translations$libraries$groupings$fr groupings = Translations$libraries$groupings$fr.internal(_root);
	@override late final Translations$libraries$filterCategories$fr filterCategories = Translations$libraries$filterCategories$fr.internal(_root);
	@override late final Translations$libraries$sortLabels$fr sortLabels = Translations$libraries$sortLabels$fr.internal(_root);
	@override late final Translations$libraries$advancedFilters$fr advancedFilters = Translations$libraries$advancedFilters$fr.internal(_root);
	@override late final Translations$libraries$selection$fr selection = Translations$libraries$selection$fr.internal(_root);
}

// Path: about
class Translations$about$fr extends Translations$about$en {
	Translations$about$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'À propos';
	@override String get openSourceLicenses => 'Licences libres';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Un magnifique client Plex, Jellyfin et Emby pour Flutter';
	@override String get viewLicensesDescription => 'Afficher les licences des bibliothèques tierces';
	@override String get privacyPolicy => 'Politique de confidentialité';
}

// Path: serverSelection
class Translations$serverSelection$fr extends Translations$serverSelection$en {
	Translations$serverSelection$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Aucun serveur trouvé pour ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Échec du chargement des serveurs : ${error}';
	@override String get noValidServers => 'Aucun serveur utilisable n’a été trouvé sur ce compte';
}

// Path: hubDetail
class Translations$hubDetail$fr extends Translations$hubDetail$en {
	Translations$hubDetail$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get releaseYear => 'Année de sortie';
	@override String get dateAdded => 'Date d\'ajout';
	@override String get rating => 'Évaluation';
	@override String get noItemsFound => 'Aucun élément trouvé';
}

// Path: logs
class Translations$logs$fr extends Translations$logs$en {
	Translations$logs$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Effacer les journaux';
	@override String get copyLogs => 'Copier les journaux';
	@override String get uploadLogs => 'Envoyer les journaux';
	@override String get saveLogs => 'Écrivez les logs à fichier';
	@override String logsSaved({required Object path}) => 'Les logs sauvés à ${path}';
	@override String get saveLogsFailed => 'Je ne pouvais pas sauver le fichier de log.';
}

// Path: startup
class Translations$startup$fr extends Translations$startup$en {
	Translations$startup$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG n\'a pas pu démarrer';
	@override String get failedBody => 'Une erreur s\'est produite au démarrage. Les détails ci-dessous identifient la cause.';
	@override String get failedBodyRepairable => 'Le fichier de paramètres enregistré de PlezyNG est endommagé et doit être reconstruit avant que PlezyNG ne puisse démarrer. Réessayer ne servira à rien — choisissez Réparer le stockage.';
	@override String get phaseLabel => 'Étape';
	@override String get showDetails => 'Afficher les détails';
	@override String get hideDetails => 'Masquer les détails';
	@override String get copyDetails => 'Copier les détails';
	@override String get detailsCopied => 'Détails copiés dans le presse-papiers';
	@override String get uploadDetails => 'Téléverser les détails';
	@override String get repairStorage => 'Réparer le stockage';
	@override String get repairTitle => 'Réparer les données stockées ?';
	@override String get repairBodyCommon => 'Le fichier de paramètres de PlezyNG est endommagé et illisible. La réparation rétablit tous les paramètres par défaut.';
	@override String get repairBodyOneCredential => 'Une connexion enregistrée est endommagée et illisible. La réparation ne supprime que celle-ci ; vos autres paramètres sont laissés intacts.';
	@override String get repairBodySignInsKept => 'Vos serveurs et profils devraient rester connectés.';
	@override String get repairBodySignInsLost => 'La clé qui protège vos connexions enregistrées ne peut pas être récupérée à partir de ce fichier ; vous devrez donc vous reconnecter à chaque serveur et profil. Rien sur votre serveur multimédia n\'est affecté.';
	@override String get repairBodySessionsUncertain => 'Les trackers (MAL, AniList, Simkl, Trakt) et Seerr sont stockés séparément et peuvent ou non être conservés. PlezyNG vous indiquera exactement ce qu\'il a gardé.';
	@override String get repairConfirm => 'Réparer';
	@override String get repairSucceeded => 'Stockage réparé';
	@override String get repairNeedsRestart => 'Stockage réparé — redémarrage requis';
	@override String get restartRequiredBody => 'Vos données ont été réparées, mais PlezyNG doit redémarrer pour pouvoir les utiliser. Fermez PlezyNG puis rouvrez-le.';
	@override String get quitPlezy => 'Quitter PlezyNG';
	@override String get repairFailed => 'Échec de la réparation';
	@override String get repairKeptSignIns => 'Vos serveurs et profils sont toujours connectés.';
	@override String get repairLostSignIns => 'La clé qui protégeait vos connexions enregistrées n\'a pas pu être récupérée. Vous devrez vous reconnecter à chaque serveur et profil.';
	@override String get repairLostSessions => 'Au moins une connexion à un tracker ou à Seerr a été perdue et devra être rétablie.';
	@override String get backupTitle => 'Une copie du fichier endommagé a été conservée';
	@override String get backupWarning => 'Elle contient vos identifiants de connexion. Ne la téléversez pas et ne la partagez pas.';
	@override String get deleteBackup => 'Supprimer la copie';
	@override String get backupDeleted => 'Copie supprimée.';
	@override String get previousFailureTitle => 'PlezyNG n\'a pas réussi à démarrer la dernière fois';
}

// Path: licenses
class Translations$licenses$fr extends Translations$licenses$en {
	Translations$licenses$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Paquets associés';
	@override String get license => 'Licence';
	@override String licenseNumber({required Object number}) => 'Licence ${number}';
	@override String licensesCount({required Object count}) => '${count} licences';
}

// Path: navigation
class Translations$navigation$fr extends Translations$navigation$en {
	Translations$navigation$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliothèques';
	@override String get downloads => 'Téléchargements';
	@override String get liveTv => 'TV en direct';
	@override String get explore => 'Explorer';
}

// Path: explore
class Translations$explore$fr extends Translations$explore$en {
	Translations$explore$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final Translations$explore$mdblistShelves$fr mdblistShelves = Translations$explore$mdblistShelves$fr.internal(_root);
	@override String get title => 'Explorer';
	@override String get selectSource => 'Sélectionner la source';
	@override late final Translations$explore$rows$fr rows = Translations$explore$rows$fr.internal(_root);
	@override late final Translations$explore$status$fr status = Translations$explore$status$fr.internal(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisode',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisodes',
	);
	@override String get cast => 'Distribution';
	@override String get characters => 'Personnages';
	@override String get addToWatchlist => 'Ajouter à la liste de suivi';
	@override String get removeFromWatchlist => 'Retirer de la liste de suivi';
	@override String get addedToWatchlist => 'Ajouté à la liste de suivi';
	@override String get removedFromWatchlist => 'Retiré de la liste de suivi';
	@override String get watchlistUpdateFailed => 'Impossible de mettre à jour la liste de suivi';
	@override String get watchlistNoMatch => 'Impossible d’associer cet élément à une liste de suivi';
	@override String get notInLibrary => 'Absent de votre bibliothèque';
	@override String get inTheseLibraries => 'Dans ces bibliothèques';
	@override String get checkingLibrary => 'Vérification de votre bibliothèque...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Impossible de vérifier ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveur',
		other: 'Impossible de vérifier ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveurs',
	);
	@override String get emptyTitle => 'Rien ici pour l\'instant';
	@override String emptyMessage({required Object source}) => 'Les lignes de ${source} apparaîtront ici dès qu’elles contiendront des éléments.';
	@override String searchHint({required Object source}) => 'Rechercher dans ${source}';
	@override String searchEmpty({required Object query}) => 'Aucun résultat pour "${query}"';
	@override String searchPrompt({required Object source}) => 'Recherchez des films et des séries sur ${source}.';
	@override String get searchFailed => 'Échec de la recherche. Vérifiez votre connexion et réessayez.';
	@override late final Translations$explore$badge$fr badge = Translations$explore$badge$fr.internal(_root);
	@override late final Translations$explore$stats$fr stats = Translations$explore$stats$fr.internal(_root);
	@override late final Translations$explore$season$fr season = Translations$explore$season$fr.internal(_root);
	@override late final Translations$explore$format$fr format = Translations$explore$format$fr.internal(_root);
	@override late final Translations$explore$sourceMaterial$fr sourceMaterial = Translations$explore$sourceMaterial$fr.internal(_root);
	@override late final Translations$explore$creditRole$fr creditRole = Translations$explore$creditRole$fr.internal(_root);
	@override late final Translations$explore$relation$fr relation = Translations$explore$relation$fr.internal(_root);
	@override String broadcast({required Object day, required Object time}) => 'Diffusé le ${day} à ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Diffusé le ${day} à ${time} ${timezone}';
	@override late final Translations$explore$detail$fr detail = Translations$explore$detail$fr.internal(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résultat',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résultats',
	);
}

// Path: liveTv
class Translations$liveTv$fr extends Translations$liveTv$en {
	Translations$liveTv$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV en direct';
	@override String get guide => 'Guide';
	@override String get noChannels => 'Aucune chaîne disponible';
	@override String get noDvr => 'Aucun DVR configuré sur les serveurs';
	@override String get serverUnavailable => 'Le serveur de TV en direct n’est pas disponible.';
	@override String get serverNotConnected => 'Le serveur de TV en direct n’est pas connecté.';
	@override String get noPrograms => 'Aucune donnée de programme disponible';
	@override String get liveStreamFailed => 'Échec du direct';
	@override String get unknownProgram => 'Programme inconnu';
	@override String get timelineLiveProgram => 'Programme en direct (le jeu peut être hors du programme)';
	@override String get timelineBuffer => 'Le timeline de buffer';
	@override String get timelineUnavailable => 'L\'heure inexposable';
	@override String get timelineEstimated => 'Le Playback évalué';
	@override String get timelinePending => 'En attendant chercher';
	@override String get timelineStale => 'Le calendrier peut être dépassé';
	@override String get unknownHub => 'Inconnu';
	@override String get unknownError => 'Erreur inconnue';
	@override String channelNumber({required Object number}) => 'Chaîne ${number}';
	@override String get unknownChannel => 'Chaîne inconnue';
	@override String get live => 'EN DIRECT';
	@override String get premiereBadge => 'Nouveau';
	@override String get reloadGuide => 'Recharger le guide';
	@override String get searchGuide => 'Rechercher dans le guide';
	@override String get searchHint => 'Rechercher des chaînes et des programmes';
	@override String searchNoResults({required Object query}) => 'Aucune correspondance pour "${query}"';
	@override String get channelsSection => 'Chaînes';
	@override String get programsSection => 'Programmes';
	@override String get now => 'Maintenant';
	@override String get today => 'Aujourd\'hui';
	@override String get tomorrow => 'Demain';
	@override String get midnight => 'Minuit';
	@override String get overnight => 'Nuit';
	@override String get morning => 'Matin';
	@override String get daytime => 'Journée';
	@override String get evening => 'Soirée';
	@override String get lateNight => 'Fin de soirée';
	@override String get whatsOn => 'En ce moment';
	@override String get watchChannel => 'Regarder la chaîne';
	@override String get favorites => 'Favoris';
	@override String get reorderFavorites => 'Réorganiser les favoris';
	@override String get noFavoriteChannels => 'Aucune chaîne favorite';
	@override String get noFavoriteChannelsHint => 'Affichez toutes les chaînes, puis appuyez longuement sur une chaîne pour l’ajouter à vos favoris.';
	@override String get showAllChannels => 'Afficher toutes les chaînes';
	@override String get favoritesLoadFailed => 'Impossible de charger les favoris. Vérifiez votre connexion et réessayez.';
	@override String get favoritesUpdateFailed => 'Impossible de mettre à jour les favoris. Vérifiez votre connexion et réessayez.';
	@override String get joinSession => 'Rejoindre la session en cours';
	@override String watchFromStart({required Object minutes}) => 'Regarder depuis le début (il y a ${minutes} min)';
	@override String get watchLive => 'Regarder en direct';
	@override String get goToLive => 'Aller au direct';
	@override String get record => 'Enregistrer';
	@override String get recordEpisode => 'Enregistrer l\'épisode';
	@override String get recordSeries => 'Enregistrer la série';
	@override String get recordOptions => 'Options d\'enregistrement';
	@override String get saveTo => 'Enregistrer dans';
	@override String get recordings => 'Enregistrements';
	@override String get scheduledRecordings => 'Programmés';
	@override String get recordingRules => 'Règles d\'enregistrement';
	@override String get noScheduledRecordings => 'Aucun enregistrement programmé';
	@override String get manageRecording => 'Gérer l\'enregistrement';
	@override String get cancelRecording => 'Annuler l\'enregistrement';
	@override String get cancelRecordingTitle => 'Annuler cet enregistrement ?';
	@override String cancelRecordingMessage({required Object title}) => '${title} ne sera plus enregistré.';
	@override String get deleteRule => 'Supprimer la règle';
	@override String get deleteRuleTitle => 'Supprimer la règle d\'enregistrement ?';
	@override String deleteRuleMessage({required Object title}) => 'Les prochains épisodes de ${title} ne seront pas enregistrés.';
	@override String get recordingScheduled => 'Enregistrement programmé';
	@override String get alreadyScheduled => 'Ce programme est déjà programmé';
	@override String get dvrAdminRequired => 'Les paramètres DVR nécessitent un compte administrateur';
	@override String get recordingFailed => 'Impossible de programmer l\'enregistrement';
	@override String get recordingTargetMissing => 'Impossible de déterminer la bibliothèque d\'enregistrement';
	@override String get recordNotAvailable => 'Enregistrement non disponible pour ce programme';
	@override String get recordingCancelled => 'Enregistrement annulé';
	@override String get recordingRuleDeleted => 'Règle d\'enregistrement supprimée';
	@override String get processRecordingRules => 'Réévaluer les règles';
	@override String get recordingInProgress => 'Enregistrement en cours';
	@override String recordingsCount({required Object count}) => '${count} programmés';
	@override String get editRule => 'Modifier la règle';
	@override String get editRuleAction => 'Modifier';
	@override String get recordingRuleUpdated => 'Règle d\'enregistrement mise à jour';
	@override String get guideReloadRequested => 'Mise à jour du guide demandée';
	@override String get guideReloadFailed => 'Impossible d’actualiser le guide';
	@override String get rulesProcessRequested => 'Réévaluation des règles demandée';
	@override String get rulesProcessFailed => 'Impossible de réévaluer les règles d’enregistrement';
	@override String get recordShow => 'Enregistrer l\'émission';
	@override late final Translations$liveTv$recordSettings$fr recordSettings = Translations$liveTv$recordSettings$fr.internal(_root);
	@override String startingInMinutes({required Object minutes}) => 'Commence dans ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} à ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} a renvoyé des données de lecture de TV en direct non valides';
	@override String get failedToStartChannel => 'Impossible de lancer la chaîne en direct';
	@override String get failedToBuildStreamUrl => 'Impossible de générer l’URL du flux';
	@override String playbackStartFailed({required Object reason}) => 'Impossible de démarrer la chaîne : ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Impossible de changer de chaîne : ${reason}';
}

// Path: collections
class Translations$collections$fr extends Translations$collections$en {
	Translations$collections$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Collections';
	@override String get collection => 'Collection';
	@override String get empty => 'La collection est vide';
	@override String get deleteCollection => 'Supprimer la collection';
	@override String deleteConfirm({required Object title}) => 'Supprimer "${title}" ? Action irréversible.';
	@override String get deleted => 'Collection supprimée';
	@override String get deleteFailed => 'Échec de la suppression de la collection';
	@override String deleteFailedWithError({required Object error}) => 'Échec de la suppression de la collection : ${error}';
	@override String get selectCollection => 'Sélectionner une collection';
	@override String get collectionName => 'Nom de la collection';
	@override String get enterCollectionName => 'Entrez le nom de la collection';
	@override String get addedToCollection => 'Ajouté à la collection';
	@override String get errorAddingToCollection => 'Échec de l\'ajout à la collection';
	@override String get created => 'Collection créée';
	@override String get removeFromCollection => 'Supprimer de la collection';
	@override String removeFromCollectionConfirm({required Object title}) => 'Retirer "${title}" de cette collection ?';
	@override String get removedFromCollection => 'Retiré de la collection';
	@override String get removeFromCollectionFailed => 'Impossible de supprimer de la collection';
	@override String removeFromCollectionError({required Object error}) => 'Erreur lors du retrait de la collection : ${error}';
	@override String get searchCollections => 'Rechercher des collections...';
}

// Path: playlists
class Translations$playlists$fr extends Translations$playlists$en {
	Translations$playlists$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlists';
	@override String get playlist => 'Playlist';
	@override String get noPlaylists => 'Aucune playlist trouvée';
	@override String get create => 'Créer une playlist';
	@override String get playlistName => 'Nom de playlist';
	@override String get enterPlaylistName => 'Saisissez le nom de la playlist';
	@override String get delete => 'Supprimer la playlist';
	@override String get removeItem => 'Retirer de la playlist';
	@override String get smartPlaylist => 'Playlist intelligente';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} élément',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} éléments',
	);
	@override String get emptyPlaylist => 'Cette playlist est vide';
	@override String get deleteConfirm => 'Supprimer la playlist ?';
	@override String deleteMessage({required Object name}) => 'Voulez-vous vraiment supprimer « ${name} » ?';
	@override String get created => 'Playlist créée';
	@override String get deleted => 'Playlist supprimée';
	@override String get itemAdded => 'Ajouté à la playlist';
	@override String get itemRemoved => 'Retiré de la playlist';
	@override String get selectPlaylist => 'Sélectionner une playlist';
	@override String get searchPlaylists => 'Rechercher des playlists...';
	@override String get errorCreating => 'Échec de la création de la playlist';
	@override String get errorDeleting => 'Échec de la suppression de la playlist';
	@override String get errorLoading => 'Échec du chargement des playlists';
	@override String get errorAdding => 'Échec de l’ajout à la playlist';
	@override String get errorReordering => 'Échec de la réorganisation de l’élément de la playlist';
	@override String get errorRemoving => 'Échec du retrait de l’élément de la playlist';
}

// Path: music
class Translations$music$fr extends Translations$music$en {
	Translations$music$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Aller à l\'album';
	@override String get goToArtist => 'Aller à l\'artiste';
	@override String get instantMix => 'Mix instantané';
	@override String get playNext => 'Lire ensuite';
	@override String get addToQueue => 'Ajouter à la file d\'attente';
	@override String discNumber({required Object n}) => 'Disque ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titre',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titres',
	);
	@override String get nowPlaying => 'Lecture en cours';
	@override String playingFrom({required Object title}) => 'Lecture depuis ${title}';
	@override String get queue => 'File d\'attente';
	@override String get clearQueue => 'Vider la file d\'attente';
	@override String get lyrics => 'Paroles';
	@override String get visualizer => 'Visualisateur';
	@override String get visualizerProfileLoading => 'Lire la suite de Track Analysis...';
	@override String get visualizerAmbientMotion => 'Mouvement environnemental';
	@override String get visualizerPlexLoudness => 'Plex bruit';
	@override String get visualizerPreviousPreset => 'Précédent Style visuel';
	@override String get visualizerNextPreset => 'Suivant Style visuel';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Blonde';
	@override String get visualizerPresetOrbitals => 'Orbitale';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'Le tunnel';
	@override String get visualizerPresetTrackMap => 'Track de la carte';
	@override String get noLyrics => 'Aucune parole disponible';
	@override String get sleepTimer => 'Minuterie de veille';
	@override String get sleepTimerEndOfTrack => 'Fin du titre';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minute',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes',
	);
	@override String get stopPlayback => 'Arrêter la lecture';
	@override String get previousTrack => 'Titre précédent';
	@override String get nextTrack => 'Titre suivant';
	@override String get repeat => 'Répéter';
	@override String get repeatAll => 'Tout répéter';
	@override String get repeatOne => 'Répéter le titre';
	@override String get instantMixNoServer => 'Aucun serveur n’est disponible pour créer un mix instantané';
	@override String get instantMixFailed => 'Impossible de charger le mix instantané';
	@override String get instantMixEmpty => 'Le mix instantané n\'a renvoyé aucun titre';
	@override String noAudioUrl({required Object track}) => 'Aucune URL audio n’est disponible pour ${track}';
	@override late final Translations$music$discography$fr discography = Translations$music$discography$fr.internal(_root);
}

// Path: watchTogether
class Translations$watchTogether$fr extends Translations$watchTogether$en {
	Translations$watchTogether$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Regarder ensemble';
	@override String get description => 'Regarder du contenu en synchronisation avec vos proches';
	@override String get createRoom => 'Créer un salon';
	@override String get creatingRoom => 'Création du salon...';
	@override String get joinRoom => 'Rejoindre un salon';
	@override String get joiningRoom => 'Connexion au salon...';
	@override String get connecting => 'Connexion...';
	@override String get relayPublic => 'Les salons utilisent les relais publics Open Watch Party.';
	@override String relayCustom({required Object url}) => 'Les salons utilisent votre relais à l’adresse ${url}.';
	@override String get recentRooms => 'Salons récents';
	@override String get roomActions => 'Actions du salon';
	@override String get renameRoom => 'Renommer le salon';
	@override String get removeRoom => 'Supprimer';
	@override String get enterRoomCode => 'Saisissez le code à 6 caractères communiqué par l’hôte.';
	@override String get roomCode => 'Code du salon';
	@override String get paste => 'Coller';
	@override String get noCodeInClipboard => 'Le presse-papiers ne contient pas de code de salon';
	@override String get copyCode => 'Copier le code';
	@override String get codeCopied => 'Code du salon copié';
	@override String get shareInvite => 'Partager l’invitation';
	@override String get inviteCopied => 'Invitation copiée. Collez-la dans un message.';
	@override String inviteMessage({required Object code}) => 'Rejoignez mon salon Regarder ensemble dans PlezyNG : ouvrez « Regarder ensemble », choisissez « Rejoindre un salon » et saisissez ${code}.';
	@override String get openSessionControls => 'Ouvrir les commandes de la session Regarder ensemble';
	@override String get reconnecting => 'Reconnexion...';
	@override String get reconnectingDescription => 'La connexion a été interrompue. Vous rejoindrez le salon automatiquement.';
	@override String get connected => 'Connecté';
	@override String get disconnected => 'Déconnecté';
	@override String get youAreHost => 'Vous êtes l\'hôte';
	@override String hostedBy({required Object name}) => 'Hôte : ${name}';
	@override String get hostControlsPlayback => 'L\'hôte contrôle la lecture';
	@override String get anyoneCanControl => 'Tout le monde peut contrôler la lecture';
	@override String get roomLocked => 'Salon verrouillé';
	@override String get nowPlaying => 'En cours de lecture';
	@override String get nothingPlaying => 'Aucune lecture en cours';
	@override String get nothingPlayingHost => 'Lancez un contenu depuis n’importe quelle bibliothèque pour le partager avec le salon.';
	@override String get nothingPlayingGuest => 'Quand l’hôte lancera un contenu, il s’ouvrira ici.';
	@override String get notShareable => 'Cette vidéo n’a aucune correspondance dans le catalogue : seules les personnes ayant accès au même serveur peuvent la lire.';
	@override String get searching => 'Recherche de cette vidéo dans vos bibliothèques...';
	@override String get yourCopy => 'Votre copie';
	@override String get sharingYourCopy => 'Vous partagez votre copie';
	@override String playingOtherLength({required Object difference}) => 'Lecture de votre copie, ${difference}';
	@override String get mismatchTitle => 'Votre copie a une durée différente';
	@override String mismatchDescription({required Object difference}) => 'Votre copie la plus proche est ${difference} que la vidéo du salon. Il peut s’agir d’un autre montage ou d’une autre version.';
	@override String get playAnyway => 'Lire quand même';
	@override String get chooseAnotherCopy => 'Choisir une autre copie';
	@override String get dontPlay => 'Ne pas lire';
	@override String get unavailableTitle => 'Vous n’avez pas cette vidéo';
	@override String get unavailableDescription => 'PlezyNG ne l’a pas trouvée dans vos bibliothèques. Choisissez vous-même une copie ou relancez la recherche.';
	@override String get chooseCopy => 'Choisir une copie';
	@override String get searchAgain => 'Relancer la recherche';
	@override String get noCandidates => 'Aucune copie trouvée dans vos bibliothèques.';
	@override String get choiceFailed => 'Impossible de lire cette copie pour le salon';
	@override String lengthLonger({required Object duration}) => 'plus longue de ${duration}';
	@override String lengthShorter({required Object duration}) => 'plus courte de ${duration}';
	@override String get lengthSame => 'même durée';
	@override String get lengthUnknown => 'durée inconnue';
	@override String get joinCurrentPlayback => 'Rejoindre la lecture en cours';
	@override String get joinCurrentPlaybackDescription => 'Reprendre le contenu que l’hôte regarde actuellement';
	@override String get stopMedia => 'Arrêter la vidéo pour tout le monde';
	@override String get syncOffset => 'Décalage de synchronisation';
	@override String get syncOffsetDescription => 'Décalez votre vidéo si elle est en avance ou en retard sur le salon.';
	@override String offsetHint({required Object difference}) => 'Votre copie est ${difference} que la vidéo du salon.';
	@override String applyDifference({required Object offset}) => 'Appliquer ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Participants';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participant',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participants',
	);
	@override String get hostBadge => 'HÔTE';
	@override String nameYou({required Object name}) => '${name} (vous)';
	@override String get playerIdle => 'Inactif';
	@override String get playerLoading => 'Chargement';
	@override String get playerReady => 'Prêt';
	@override String get playerBuffering => 'Mise en tampon';
	@override String get matchSearching => 'Recherche en cours';
	@override String get matchMatched => 'Possède la vidéo';
	@override String get matchMismatched => 'Durée différente';
	@override String get matchUnavailable => 'Ne possède pas la vidéo';
	@override String participantOffset({required Object offset}) => 'Décalage ${offset}';
	@override String get makeHost => 'Nommer hôte';
	@override String get makeHostQuestion => 'Transférer le rôle d’hôte ?';
	@override String makeHostConfirm({required Object name}) => '${name} contrôlera la lecture et dirigera la session pour tout le monde.';
	@override String get transfer => 'Transférer';
	@override String get removeParticipant => 'Retirer du salon';
	@override String removeParticipantQuestion({required Object name}) => 'Retirer ${name} ?';
	@override String removeParticipantConfirm({required Object name}) => '${name} quittera le salon. Cette personne pourra revenir avec le code, sauf si vous verrouillez le salon.';
	@override String get remove => 'Retirer';
	@override String get roomSettings => 'Paramètres du salon';
	@override String get letEveryoneControl => 'Laisser tout le monde contrôler la lecture';
	@override String get lockRoom => 'Verrouiller le salon';
	@override String get lockRoomDescription => 'Aucun nouveau participant ne peut rejoindre le salon';
	@override String get leaveRoom => 'Quitter le salon';
	@override String get leaveRoomQuestion => 'Quitter le salon ?';
	@override String get leaveRoomConfirm => 'Vous pourrez revenir avec le code du salon.';
	@override String get leave => 'Quitter';
	@override String get endRoom => 'Fermer le salon';
	@override String get endRoomQuestion => 'Fermer le salon ?';
	@override String get endRoomConfirm => 'Le salon sera fermé pour tout le monde.';
	@override String get end => 'Terminer';
	@override String get playBlockedTitle => 'La lecture n’a pas démarré';
	@override String get playBlockedDescription => 'Appuyez sur Lecture pour commencer à regarder avec le salon.';
	@override late final Translations$watchTogether$notices$fr notices = Translations$watchTogether$notices$fr.internal(_root);
	@override late final Translations$watchTogether$ended$fr ended = Translations$watchTogether$ended$fr.internal(_root);
	@override late final Translations$watchTogether$errors$fr errors = Translations$watchTogether$errors$fr.internal(_root);
	@override String untitledEpisode({required Object number}) => 'Épisode ${number}';
}

// Path: downloads
class Translations$downloads$fr extends Translations$downloads$en {
	Translations$downloads$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Téléchargements';
	@override String get manage => 'Gérer';
	@override String get tvShows => 'Séries TV';
	@override String get movies => 'Films';
	@override String get music => 'Musique';
	@override String tracksQueued({required Object count}) => '${count} titres en file d\'attente de téléchargement';
	@override String get noDownloads => 'Aucun téléchargement pour le moment';
	@override String get noDownloadsDescription => 'Le contenu téléchargé apparaîtra ici pour être consulté hors ligne.';
	@override String get downloadNow => 'Télécharger';
	@override String get deleteDownload => 'Supprimer le téléchargement';
	@override String get retryDownload => 'Réessayer le téléchargement';
	@override String get downloadQueued => 'Téléchargement en attente';
	@override String get downloadResumed => 'Téléchargement repris';
	@override String get serverErrorBitrate => 'Erreur du serveur : le fichier peut dépasser la limite de débit distant';
	@override String get storageFull => 'Les téléchargements ont été arrêtés pour préserver l’espace de stockage disponible. Libérez de l’espace ou choisissez un autre emplacement de téléchargement, puis réessayez.';
	@override String get storageUnavailable => 'Les téléchargements ont été arrêtés car l’espace de stockage disponible n’a pas pu être vérifié. Vérifiez l’emplacement de téléchargement, puis réessayez.';
	@override String episodesQueued({required Object count}) => '${count} épisodes en attente de téléchargement';
	@override String get downloadDeleted => 'Téléchargement supprimé';
	@override String deleteConfirm({required Object title}) => 'Supprimer « ${title} » de cet appareil ?';
	@override String get deleteCollectionDownloads => 'Supprimer les téléchargements';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Supprimer de cet appareil tous les téléchargements de « ${title} » ?';
	@override String get collectionDownloadsDeleted => 'Téléchargements supprimés';
	@override String get cancelledDownloadTitle => 'Téléchargement annulé';
	@override String get cancelledDownloadMessage => 'Ce téléchargement a été annulé. Que voulez-vous faire ?';
	@override String get allEpisodesAlreadyDownloaded => 'Tous les épisodes sont déjà téléchargés';
	@override String get resumeDownload => 'Reprendre le téléchargement';
	@override String get cancelledDownload => 'Téléchargement annulé';
	@override String syncingFile({required Object file, required Object status}) => '${file} (synchronisation ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} téléchargé — cliquez pour terminer';
	@override String get partialDownloadClickToComplete => 'Téléchargement partiel — cliquez pour terminer';
	@override String get deleting => 'Suppression...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Suppression de ${title}... (${current} sur ${total})';
	@override String get queuedTooltip => 'En attente';
	@override String queuedFilesTooltip({required Object files}) => 'En attente : ${files}';
	@override String get downloadingTooltip => 'Téléchargement...';
	@override String downloadingFilesTooltip({required Object files}) => 'Téléchargement de ${files}';
	@override String get noDownloadsTree => 'Aucun téléchargement';
	@override String get pauseAll => 'Tout mettre en pause';
	@override String get resumeAll => 'Tout reprendre';
	@override String get retryAll => 'Tout réessayer';
	@override String get retryFailed => 'Réessayer les téléchargements en échec';
	@override String get deleteAll => 'Tout supprimer';
	@override String get selectVersion => 'Sélectionner la version';
	@override String get allEpisodes => 'Tous les épisodes';
	@override String get unwatchedOnly => 'Non vus uniquement';
	@override String nextNUnwatched({required Object count}) => '${count} prochains non vus';
	@override String get customAmount => 'Quantité personnalisée...';
	@override String get customAmountAny => 'Le montant (en chaque année)';
	@override String get randomEpisodes => 'Épisodes rares';
	@override String get includeSpecials => 'Inclure les spéciaux';
	@override String get howManyEpisodes => 'Combien d\'épisodes ?';
	@override String get invalidEpisodeCount => 'Saisissez un nombre d\'épisodes valide.';
	@override String get keepSynced => 'Garder synchronisé';
	@override String get downloadOnce => 'Télécharger une fois';
	@override String keepNUnwatched({required Object count}) => 'Garder ${count} non vus';
	@override String get editSyncRule => 'Modifier la règle de synchronisation';
	@override String get removeSyncRule => 'Supprimer la règle de synchronisation';
	@override String removeSyncRuleConfirm({required Object title}) => 'Arrêter la synchronisation de « ${title} » ? Les épisodes téléchargés seront conservés.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Arrêter la synchronisation de « ${title} » ?';
	@override String get deleteSyncRuleDownloads => 'Supprimer aussi les téléchargements associés';
	@override String get deleteSyncRuleDownloadsDescription => 'Les téléchargements utilisés par une autre règle de synchronisation ou un autre profil seront conservés.';
	@override String syncRuleCreated({required Object count}) => 'Règle de synchronisation créée — ${count} épisodes non vus conservés';
	@override String get syncRuleUpdated => 'Règle de synchronisation mise à jour';
	@override String get syncRuleRemoved => 'Règle de synchronisation supprimée';
	@override String get syncRuleAndDownloadsRemoved => 'Règle de synchronisation et téléchargements associés supprimés';
	@override String get syncRuleCleanupBusy => 'Les règles de synchronisation sont en cours de mise à jour. Réessayez dans un instant.';
	@override String get syncRuleCleanupUnavailable => 'Les téléchargements associés n\'ont pas pu être identifiés en toute sécurité. Reconnectez le serveur et réessayez, ou retirez la règle sans supprimer les téléchargements.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} nouveaux épisodes synchronisés pour ${title}';
	@override String get syncNow => 'Synchronisation maintenant';
	@override String get downloadsUpToDate => 'Les téléchargements sont à jour';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync complet · ${queued} queued, ${removed} supprimé';
	@override String get activeSyncRules => 'Règles de synchronisation';
	@override String get reviewOrphanFiles => 'Examiner les téléchargements orphelins';
	@override String get orphanReviewTitle => 'Examiner les téléchargements orphelins';
	@override String get orphanReviewDescription => 'Ces fichiers marqués se trouvent dans les dossiers de téléchargement par défaut gérés par PlezyNG et ne correspondent à aucun enregistrement de téléchargement ni à aucune tâche active. Vérifiez la liste avant de les supprimer.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} fichiers · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Supprimer ${count} fichiers';
	@override String get orphanCleanupNone => 'Aucun fichier de téléchargement orphelin trouvé';
	@override String get orphanCleanupFailed => 'PlezyNG n’a pas pu analyser le dossier de téléchargement géré en toute sécurité. Aucun fichier n’a été supprimé.';
	@override String get orphanCleanupChanged => 'La liste des téléchargements a changé pendant la vérification. Examinez de nouveau les fichiers avant de nettoyer.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '${count} fichiers orphelins supprimés · ${size} d’espace libéré';
	@override String get noSyncRules => 'Aucune règle de synchronisation';
	@override String get manageSyncRule => 'Gérer la synchronisation';
	@override String get editEpisodeCount => 'Nombre d’épisodes';
	@override String get editSyncFilter => 'Filtre de synchronisation';
	@override String get syncAllItems => 'Synchronisation de tous les éléments';
	@override String get syncUnwatchedItems => 'Synchronisation des éléments non vus';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Serveur : ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponible';
	@override String get syncRuleOffline => 'Hors ligne';
	@override String get syncRuleSignInRequired => 'Connexion requise';
	@override String get syncRuleAccessDenied => 'Accès refusé';
	@override String get syncRuleNotAvailableForProfile => 'Non disponible pour le profil actuel';
	@override String get syncRuleUnknownServer => 'Serveur inconnu';
	@override String get syncRuleListCreated => 'Règle de synchronisation créée';
	@override late final Translations$downloads$backgroundWarning$fr backgroundWarning = Translations$downloads$backgroundWarning$fr.internal(_root);
	@override String get options => 'Options de téléchargement';
	@override late final Translations$downloads$groupings$fr groupings = Translations$downloads$groupings$fr.internal(_root);
	@override String get unknownLibrary => 'Bibliothèque inconnue';
	@override String get unknownShow => 'Série inconnue';
	@override String get unknownSeason => 'Saison inconnue';
	@override String get unknownAlbum => 'Album inconnu';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} terminés';
	@override String storageUsed({required Object size}) => 'Équipement utilisé : ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargement',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargements',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} écriture',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} écrans',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} films',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albums',
	);
	@override String get errorFileNotFound => 'Fichier introuvable (404)';
	@override String get errorDownloadNotAllowed => 'Téléchargement non autorisé par le serveur (403)';
	@override String get errorDownloadFailed => 'Échec du téléchargement';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Échec du téléchargement : ${reason}';
	@override String get convertingOnServer => 'Convertir sur le serveur...';
	@override String convertingOnServerPercent({required Object percent}) => 'Conversion sur serveur · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Échec du téléchargement (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Échec du post-traitement : ${reason}';
	@override String get reasonFileNotSaved => 'le fichier n\'a pas pu être enregistré sur cet appareil';
	@override String get reasonCannotResume => 'le téléchargement partiel n\'a pas pu être repris';
	@override String get reasonDeviceStorageFull => 'cet appareil n\'a plus d\'espace de stockage';
	@override String get notificationDownloading => 'Téléchargement...';
	@override String get notificationComplete => 'Téléchargement terminé';
	@override String get notificationPaused => 'Téléchargement en pause';
}

// Path: shaders
class Translations$shaders$fr extends Translations$shaders$en {
	Translations$shaders$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Aucune amélioration vidéo';
	@override String get nvscalerDescription => 'Mise à l\'échelle NVIDIA pour une vidéo plus nette';
	@override String get artcnnVariantNeutral => 'Neutre';
	@override String get artcnnVariantDenoise => 'Réduction du bruit';
	@override String get artcnnVariantDenoiseSharpen => 'Réduction du bruit + netteté';
	@override String get qualityFast => 'Rapide';
	@override String get qualityHQ => 'Haute qualité';
	@override String get mode => 'Mode';
	@override String get importShader => 'Importer un shader';
	@override String get customShaderDescription => 'Shader GLSL personnalisé';
	@override String get shaderImported => 'Shader importé';
	@override String get shaderImportFailed => 'Échec de l\'importation du shader';
	@override String get deleteShader => 'Supprimer le shader';
	@override String deleteShaderConfirm({required Object name}) => 'Supprimer "${name}" ?';
}

// Path: companionRemote
class Translations$companionRemote$fr extends Translations$companionRemote$en {
	Translations$companionRemote$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Télécommande compagnon';
	@override String connectedTo({required Object name}) => 'Connecté à ${name}';
	@override String get unknownDevice => 'Appareil inconnu';
	@override late final Translations$companionRemote$session$fr session = Translations$companionRemote$session$fr.internal(_root);
	@override late final Translations$companionRemote$pairing$fr pairing = Translations$companionRemote$pairing$fr.internal(_root);
	@override late final Translations$companionRemote$remote$fr remote = Translations$companionRemote$remote$fr.internal(_root);
	@override late final Translations$companionRemote$errors$fr errors = Translations$companionRemote$errors$fr.internal(_root);
	@override String get closedBeforeAuth => 'La connexion a été fermée avant l’authentification';
}

// Path: videoSettings
class Translations$videoSettings$fr extends Translations$videoSettings$en {
	Translations$videoSettings$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Vitesse de lecture';
	@override String get normalSpeed => 'Normale';
	@override String sleepTimerActive({required Object duration}) => 'Actif (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Minuterie de mise en veille';
	@override String get audioSync => 'Synchronisation audio';
	@override String get subtitleSync => 'Synchronisation des sous-titres';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'Le HDR n’est pas disponible ici : ce compositeur de bureau ou cette sortie vidéo ne permet pas de le transmettre.';
	@override String get hdrToneMapping => 'Mappage tonal HDR';
	@override String get hdrToneMappingCompositor => 'Compositeur';
	@override String get hdrToneMappingCompositorDescription => 'Transmettre les métadonnées HDR de la source et laisser le compositeur de bureau effectuer le mappage.';
	@override String get hdrToneMappingPlayer => 'Lecteur';
	@override String get hdrToneMappingPlayerDescription => 'Effectuer dans le lecteur le mappage selon la luminosité maximale de l’écran, puis indiquer le résultat au compositeur.';
	@override String get hdrToneMappingFailed => 'Impossible de modifier le mappage tonal HDR : le mode précédent reste actif.';
	@override String get audioOutput => 'Sortie audio';
	@override String get performanceOverlay => 'Données de performance';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Audio spatial';
	@override String get audioOutputStereo => 'Stéréo';
	@override String get audioEqualizer => 'Équaliste audio';
	@override String get audioEqualizerDescription => 'Un équateur de 10 bandes pour MPVLes filtres audio utilisent l\'audio décodé et désactivent passthrough.';
	@override String get audioEqualizerFlat => 'Plateur';
	@override String get audioEqualizerActive => 'Personnalisé';
	@override String get audioEqualizerSaveFailed => 'Il ne pouvait pas économiser les paramètres d\'équalisateur audio.';
	@override String get backgroundVideoAudio => '- Audio vidéo de fond';
	@override String get backgroundVideoAudioDescription => 'Gardez la lecture audio vidéo lorsque vous quittez le lecteur; l\'image est cachée jusqu\'à ce que vous reveniez. Android utilise une notification de récupération médiatique.';
	@override String get audioNormalization => 'Normaliser le volume';
	@override String get audioNormalizationDisablesPassthrough => 'Décode l’audio en PCM ; la transmission directe est désactivée tant que cette option est active';
	@override String get audioEffectsDescription => 'Les effets utilisent l\'audio décodé, de sorte que le match se tourne. l\'ambiance de la pièce et l\'extension stéréo dépendent du MPV Construire et suivre.';
	@override String get audioStereoWidth => 'Extension Stereo';
	@override String get audioSpatializer => 'L’ambiance de la chambre';
	@override String get audioSpatializerDescription => 'Ajoutez des réflexions de la salle calme.';
	@override String get audioPitch => 'Le changement de Pitch';
	@override String get audioPitchDescription => 'Changer la piste sans changer de vitesse. MPV La construction doit inclure Rubber Band.';
	@override String get audioEffectUnavailable => 'Cet effet n\'est pas disponible pour cette piste ou MPV à construire.';
}

// Path: performanceOverlay
class Translations$performanceOverlay$fr extends Translations$performanceOverlay$en {
	Translations$performanceOverlay$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get color => 'Couleur';
	@override String get performance => 'Performances';
	@override String get buffer => 'Tampon';
	@override String get app => 'Application';
	@override String get decoder => 'Décodeur';
	@override String get rawDecoder => 'Décodeur brut';
	@override String get tunneling => 'Tunnel';
	@override String get passthrough => 'Transmission directe';
	@override String get aspect => 'Format';
	@override String get rotation => 'Rotation';
	@override String get dvSource => 'Source DV';
	@override String get dvPath => 'Chemin DV';
	@override String get dvRouteDecoder => 'Décodeur Dolby Vision';
	@override String get dvRouteDecoderP81 => 'Décodeur Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Couche de base';
	@override String get dvRouteBaseLayerHdr10 => 'Couche de base HDR10';
	@override String get dvRouteBaseLayerHlg => 'Couche de base HLG';
	@override String get dvRouteBaseLayerSdr => 'Couche de base SDR';
	@override String get dvRouteReshaped => 'Remodelage RPU (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Graphique expérimental P7 FEL (non qualifié)';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Fréquence d’échantillonnage';
	@override String get pixelFormat => 'Fmt pixel';
	@override String get hwFormat => 'Fmt HW';
	@override String get matrix => 'Matrice';
	@override String get primaries => 'Primaires';
	@override String get transfer => 'Transfert';
	@override String get renderFps => 'FPS rendu';
	@override String get displayFps => 'FPS écran';
	@override String get avSync => 'Synchro A/V';
	@override String get dropped => 'Perdues';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'Moy. DV RPU';
	@override String get dvSampleAverage => 'Moy. échant. DV';
	@override String get maxLuma => 'Luma max.';
	@override String get minLuma => 'Luma min.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache utilisé';
	@override String get cacheLimit => 'Limite du cache';
	@override String get speed => 'Vitesse';
	@override String get player => 'Lecteur';
	@override String get playMethod => 'Le jeu méthode';
	@override String get memory => 'Mémoire';
	@override String get uiFps => 'FPS UI';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Matériel Android';
	@override String get decoderNvidiaHw => 'Matériel NVIDIA';
	@override String get decoderQualcommHw => 'Matériel Qualcomm';
	@override String get decoderMediatekHw => 'Matériel MediaTek';
	@override String get decoderExynosHw => 'Matériel Exynos';
	@override String get decoderSoftware => 'Logiciel';
	@override String get decoderHardware => 'Matériel';
	@override String get tunnelingActive => 'Actif';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} échecs)';
}

// Path: externalPlayer
class Translations$externalPlayer$fr extends Translations$externalPlayer$en {
	Translations$externalPlayer$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lecteur externe';
	@override String get useExternalPlayer => 'Utiliser un lecteur externe';
	@override String get useExternalPlayerDescription => 'Ouvrir les vidéos dans une autre application';
	@override String get selectPlayer => 'Sélectionner le lecteur';
	@override String get customPlayers => 'Lecteurs personnalisés';
	@override String get systemDefault => 'Par défaut du système';
	@override String get addCustomPlayer => 'Ajouter un lecteur personnalisé';
	@override String get playerName => 'Nom du lecteur';
	@override String get playerNameHint => 'Mon lecteur';
	@override String get playerCommand => 'Commande';
	@override String get playerPackage => 'Nom du paquet';
	@override String get playerUrlScheme => 'Schéma URL';
	@override String get off => 'Désactivé';
	@override String get launchFailed => 'Impossible d\'ouvrir le lecteur externe';
	@override String appNotInstalled({required Object name}) => '${name} n\'est pas installé';
	@override String get playInExternalPlayer => 'Lire dans un lecteur externe';
	@override String get description => 'Choisissez une autre application pour ouvrir les vidéos. Les joueurs disponibles dépendent de votre appareil et des applications installées.';
	@override String get systemDefaultDescription => 'Laissez le système d\'exploitation ouvrir la vidéo avec son application par défaut.';
	@override String playerOptionDescription({required Object player}) => 'Ouvrez des vidéos avec ${player}.';
	@override String get playerNameDescription => 'L\'étiquette affichée dans la liste des joueurs.';
	@override String get playerPackageDescription => 'Entrez le nom de paquet Android de l\'application joueur, comme com.example.player.';
	@override String get playerCommandDescription => 'Entrez le commandement de joueur installé ou la voie exécutable pour ce dispositif.';
	@override String get playerUrlSchemeDescription => 'Entrez le schéma URL et le modèle URL facultatif utilisé pour lancer le lecteur.';
}

// Path: metadataEdit
class Translations$metadataEdit$fr extends Translations$metadataEdit$en {
	Translations$metadataEdit$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Modifier...';
	@override String get screenTitle => 'Modifier les métadonnées';
	@override String get basicInfo => 'Informations de base';
	@override String get artwork => 'Illustrations';
	@override String get advancedSettings => 'Paramètres avancés';
	@override String get title => 'Titre';
	@override String get sortTitle => 'Titre de tri';
	@override String get originalTitle => 'Titre original';
	@override String get releaseDate => 'Date de sortie';
	@override String get contentRating => 'Classification';
	@override String get studio => 'Studio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Résumé';
	@override String get poster => 'Affiche';
	@override String get background => 'Arrière-plan';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Image carrée';
	@override String get selectPoster => 'Sélectionner l\'affiche';
	@override String get selectBackground => 'Sélectionner l\'arrière-plan';
	@override String get selectLogo => 'Sélectionner le logo';
	@override String get selectSquareArt => 'Sélectionner l\'image carrée';
	@override String get fromUrl => 'Depuis une URL';
	@override String get uploadFile => 'Importer un fichier';
	@override String get enterImageUrl => 'Entrer l\'URL de l\'image';
	@override String get imageUrl => 'URL de l\'image';
	@override String get metadataUpdated => 'Métadonnées mises à jour';
	@override String get metadataUpdateFailed => 'Échec de la mise à jour des métadonnées';
	@override String get artworkUpdated => 'Illustrations mises à jour';
	@override String get artworkUpdateFailed => 'Échec de la mise à jour des illustrations';
	@override String get noArtworkAvailable => 'Aucune illustration disponible';
	@override String artworkOption({required Object index}) => 'Option d\'illustration ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Option d\'illustration ${index}, sélectionnée';
	@override String get notSet => 'Non défini';
	@override String get libraryDefault => 'Par défaut de la bibliothèque';
	@override String get accountDefault => 'Par défaut du compte';
	@override String get seriesDefault => 'Par défaut de la série';
	@override String get episodeSorting => 'Tri des épisodes';
	@override String get oldestFirst => 'Plus anciens en premier';
	@override String get newestFirst => 'Plus récents en premier';
	@override String get keep => 'Conserver';
	@override String get allEpisodes => 'Tous les épisodes';
	@override String latestEpisodes({required Object count}) => '${count} derniers épisodes';
	@override String get latestEpisode => 'Dernier épisode';
	@override String episodesAddedPastDays({required Object count}) => 'Épisodes ajoutés ces ${count} derniers jours';
	@override String get deleteAfterPlaying => 'Supprimer les épisodes après lecture';
	@override String get never => 'Jamais';
	@override String get afterADay => 'Après un jour';
	@override String get afterAWeek => 'Après une semaine';
	@override String get afterAMonth => 'Après un mois';
	@override String get onNextRefresh => 'Au prochain rafraîchissement';
	@override String get seasons => 'Saisons';
	@override String get show => 'Afficher';
	@override String get hide => 'Masquer';
	@override String get episodeOrdering => 'Ordre des épisodes';
	@override String get tmdbAiring => 'The Movie Database (Diffusion)';
	@override String get tvdbAiring => 'TheTVDB (Diffusion)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolu)';
	@override String get metadataLanguage => 'Langue des métadonnées';
	@override String get useOriginalTitle => 'Utiliser le titre original';
	@override String get preferredAudioLanguage => 'Langue audio préférée';
	@override String get preferredSubtitleLanguage => 'Langue de sous-titres préférée';
	@override String get subtitleMode => 'Sélection automatique des sous-titres';
	@override String get manuallySelected => 'Sélectionné manuellement';
	@override String get shownWithForeignAudio => 'Avec l’audio en langue étrangère';
	@override String get alwaysEnabled => 'Toujours activé';
	@override String get tags => 'Étiquettes';
	@override String get addTag => 'Ajouter une étiquette';
	@override String get genre => 'Genre';
	@override String get director => 'Réalisateur';
	@override String get writer => 'Scénariste';
	@override String get producer => 'Producteur';
	@override String get country => 'Pays';
	@override String get collection => 'Collection';
	@override String get label => 'Libellé';
	@override String get quickTag => 'Tag rapide...';
}

// Path: matchScreen
class Translations$matchScreen$fr extends Translations$matchScreen$en {
	Translations$matchScreen$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get match => 'Associer...';
	@override String get fixMatch => 'Corriger l\'association...';
	@override String get unmatch => 'Dissocier';
	@override String get unmatchConfirm => 'Effacer cette correspondance ? Plex la traitera comme non associée jusqu\'à réassociation.';
	@override String get unmatchSuccess => 'Association supprimée';
	@override String get unmatchFailed => 'Échec de la dissociation';
	@override String get matchApplied => 'Association appliquée';
	@override String get matchFailed => 'Échec de l\'application';
	@override String get titleHint => 'Titre';
	@override String get yearHint => 'Année';
	@override String get search => 'Rechercher';
	@override String get noMatchesFound => 'Aucune correspondance';
}

// Path: serverTasks
class Translations$serverTasks$fr extends Translations$serverTasks$en {
	Translations$serverTasks$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tâches du serveur';
	@override String get failedToLoad => 'Échec du chargement des tâches';
	@override String get noTasks => 'Aucune tâche en cours';
}

// Path: trakt
class Translations$trakt$fr extends Translations$trakt$en {
	Translations$trakt$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Connecté';
	@override String connectedAs({required Object username}) => 'Connecté en tant que @${username}';
	@override String get disconnectConfirm => 'Déconnecter le compte Trakt ?';
	@override String get disconnectConfirmBody => 'PlezyNG cessera d’envoyer des événements à Trakt. Vous pourrez vous reconnecter à tout moment.';
	@override String get scrobble => 'Scrobbling en temps réel';
	@override String get scrobbleDescription => 'Envoyer les événements de lecture, pause et arrêt à Trakt pendant la lecture.';
	@override String get watchedSync => 'Synchroniser le statut « vu »';
	@override String get watchedSyncDescription => 'Lorsque vous marquez des éléments comme vus dans PlezyNG, ils sont également marqués comme vus sur Trakt.';
}

// Path: seerr
class Translations$seerr$fr extends Translations$seerr$en {
	Translations$seerr$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Se connecter à Seerr';
	@override String get serverUrl => 'URL du serveur';
	@override String get serverUrlHelper => 'L\'adresse de votre instance Seerr';
	@override String get checkServer => 'Continuer';
	@override String get signInWithJellyfin => 'Se connecter avec Jellyfin';
	@override String get signInWithEmby => 'Se connecter avec Emby';
	@override String get signInWithLocal => 'Utiliser un compte local';
	@override String get email => 'E-mail';
	@override String get noSignInMethods => 'Cette instance Seerr ne propose aucune méthode de connexion prise en charge par PlezyNG.';
	@override String get instance => 'Instance';
	@override String get disconnectConfirm => 'Déconnecter Seerr ?';
	@override String get disconnectConfirmBody => 'PlezyNG oubliera cette instance Seerr. Vous pourrez vous reconnecter à tout moment.';
	@override String get request => 'Demander';
	@override String get request4k => 'Demander en 4K';
	@override String get seasons => 'Saisons';
	@override String get allSeasons => 'Toutes les saisons';
	@override String get advancedOptions => 'Avancé';
	@override String get destinationServer => 'Serveur de destination';
	@override String get qualityProfile => 'Profil de qualité';
	@override String get rootFolder => 'Dossier racine';
	@override String get languageProfile => 'Profil de langue';
	@override String get tags => 'Étiquettes';
	@override String get noTags => 'Aucune étiquette';
	@override String defaultOption({required Object name}) => '${name} (par défaut)';
	@override String get animeNote => 'Cette série est un anime.';
	@override String get requestSubmitted => 'Demande envoyée';
	@override String requestFailed({required Object error}) => 'Échec de la demande : ${error}';
	@override String get requestsLoadFailed => 'Impossible de charger les options de demande';
	@override String get nothingToRequest => 'Tout est déjà disponible ou demandé.';
	@override String get statusAvailable => 'Disponible';
	@override String get statusPartiallyAvailable => 'Partiellement disponible';
	@override String get statusRequested => 'Demandé';
	@override String get statusProcessing => 'En cours de traitement';
	@override String get statusBlocklisted => 'Sur la liste de blocage';
	@override String couldNotReach({required Object url, required Object error}) => 'Impossible de joindre ${url} : ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Aucune instance Seerr à l’adresse ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Un proxy inverse avec authentification (SSO ou authentification HTTP) a répondu à la place de Seerr. PlezyNG ne peut pas se connecter à travers lui : laissez le chemin /api/v1 de Seerr contourner le proxy pour cette application, ou utilisez une adresse qui atteint Seerr directement.';
	@override String get invalidUrl => 'Saisissez une adresse de serveur comme https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Cette instance Seerr ne prend pas en charge Quick Connect. Elle nécessite Seerr 3.4 ou version ultérieure.';
	@override String get notInitialized => 'La configuration initiale de cette instance Seerr n’est pas terminée';
	@override String get noPlexTokenForReauth => 'Aucun jeton Plex n’est disponible pour se reconnecter';
	@override String get noStoredCredentials => 'Aucun identifiant enregistré n’est disponible pour se reconnecter';
	@override String get signInRejected => 'La connexion a été refusée';
	@override String get noSessionCookie => 'Seerr n’a pas fourni de cookie de session';
	@override String get freshCookieRejected => 'Seerr a refusé le nouveau cookie de session';
	@override String get noUserInformation => 'Seerr n’a renvoyé aucune information sur l’utilisateur';
	@override String get sessionRejectedAfterReauth => 'La session a été refusée après la reconnexion';
	@override String get permissionDenied => 'Seerr a refusé cette action : votre compte ne dispose plus de la permission requise';
	@override String get permissionRevoked => 'Vous n’avez plus la permission de faire cette demande';
}

// Path: services
class Translations$services$fr extends Translations$services$en {
	Translations$services$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Services';
	@override String get hubSubtitle => 'Synchronisez votre progression et demandez de nouveaux titres.';
	@override String get integrations => 'Intégrations';
	@override String get notConnected => 'Non connecté';
	@override String connectedAs({required Object username}) => 'Connecté en tant que @${username}';
	@override String get scrobble => 'Suivre la progression automatiquement';
	@override String get scrobbleDescription => 'Mettre à jour votre liste lorsque vous terminez un épisode ou un film.';
	@override String disconnectConfirm({required Object service}) => 'Déconnecter ${service} ?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG cessera de mettre à jour ${service}. Vous pourrez vous reconnecter à tout moment.';
	@override String connectFailed({required Object service}) => 'Échec de la connexion à ${service}. Réessayez.';
	@override late final Translations$services$names$fr names = Translations$services$names$fr.internal(_root);
	@override late final Translations$services$simklReconnect$fr simklReconnect = Translations$services$simklReconnect$fr.internal(_root);
	@override late final Translations$services$deviceCode$fr deviceCode = Translations$services$deviceCode$fr.internal(_root);
	@override late final Translations$services$oauthProxy$fr oauthProxy = Translations$services$oauthProxy$fr.internal(_root);
	@override late final Translations$services$pendingAuth$fr pendingAuth = Translations$services$pendingAuth$fr.internal(_root);
	@override late final Translations$services$libraryFilter$fr libraryFilter = Translations$services$libraryFilter$fr.internal(_root);
	@override String get seerrDescription => 'Connectez-vous à Seerr ou Overseerr pour rechercher les titres et soumettre des demandes de médias.';
	@override late final Translations$services$trackerDescriptions$fr trackerDescriptions = Translations$services$trackerDescriptions$fr.internal(_root);
}

// Path: addServer
class Translations$addServer$fr extends Translations$addServer$en {
	Translations$addServer$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Ajouter un serveur ${product}';
	@override String get serverUrls => 'URL du serveur';
	@override String get serverUrlsHelper => 'Plusieurs URL possibles, séparées par des virgules.';
	@override String get findServer => 'Rechercher un serveur';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Recherche de serveurs ${product} locaux...';
	@override String localMediaBrowserServers({required Object product}) => 'Serveurs ${product} locaux';
	@override String get username => 'Nom d\'utilisateur';
	@override String get password => 'Mot de passe';
	@override String get signIn => 'Se connecter';
	@override String get change => 'Modifier';
	@override String get required => 'Requis';
	@override String couldNotReachServer({required Object error}) => 'Impossible de joindre le serveur : ${error}';
	@override String signInFailed({required Object error}) => 'Échec de la connexion : ${error}';
	@override String quickConnectFailed({required Object error}) => 'Échec de Quick Connect : ${error}';
	@override String get addPlexTitle => 'Se connecter avec Plex';
	@override String get pinExpired => 'Le PIN a expiré avant la connexion. Veuillez réessayer.';
	@override String failedToRegisterAccount({required Object error}) => 'Échec de l\'enregistrement du compte : ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Saisissez l\'URL de votre serveur ${product}';
	@override String get addConnectionTitle => 'Ajouter une connexion';
	@override String addConnectionTitleScoped({required Object name}) => 'Ajouter à ${name}';
	@override String get signInWithPlexCard => 'Se connecter avec Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorisez cet appareil. Les serveurs partagés sont ajoutés.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorisez un compte Plex. Les utilisateurs Home deviennent des profils.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Se connecter à ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Saisissez l\'URL de votre serveur, votre nom d\'utilisateur et votre mot de passe.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Connectez-vous à votre serveur ${product}. Sera associé à ${name}.';
	@override String get borrowFromAnotherProfile => 'Emprunter à un autre profil';
	@override String get borrowFromAnotherProfileSubtitle => 'Réutiliser la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.';
	@override String get invalidCredentials => 'Nom d’utilisateur ou mot de passe incorrect';
	@override String get authResponseNotJson => 'La réponse d’authentification n’était pas au format JSON valide';
	@override String get authResponseIncomplete => 'La réponse de connexion du serveur était incomplète';
	@override String get quickConnectRejected => 'Quick Connect a été refusé par le serveur';
	@override String get quickConnectNotJson => 'La réponse de Quick Connect n’était pas au format JSON valide';
	@override String get quickConnectMissingFields => 'Il manque un code ou un secret dans la réponse de Quick Connect';
	@override String get quickConnectPollRejected => 'L’interrogation de Quick Connect a été refusée par le serveur';
	@override String get serverTimedOut => 'Le serveur n’a pas répondu à temps';
	@override String get responseNotJson => 'La réponse du serveur n’était pas au format JSON valide';
	@override String responseMissingIdentity({required Object product}) => 'Il manque un identifiant ou un nom de serveur dans la réponse : s’agit-il d’un serveur ${product} ?';
	@override String probeFailed({required Object error}) => 'Impossible de joindre le serveur : ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Saisissez l’URL d’au moins un serveur ${product}';
	@override String noReachableServer({required Object product}) => 'Aucun serveur ${product} joignable n’a été trouvé';
	@override String urlsPointToDifferentServers({required Object product}) => 'Ces URL renvoient vers différents serveurs ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'Cette URL ne correspond pas au serveur ${product}';
	@override String get redirectUnsupported => 'Le serveur a redirigé vers une URL non prise en charge';
	@override String redirectDifferentHost({required Object product}) => 'Le serveur a redirigé vers un hôte différent. Saisissez directement l’URL finale du serveur ${product}.';
	@override String get redirectInsecure => 'Le serveur a redirigé de HTTPS vers une URL non sécurisée';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Le serveur a redirigé vers une URL non prise en charge. Saisissez directement l’URL finale du serveur ${product}.';
	@override String get directPlexServerUrl => 'URL du serveur Plex';
	@override String get directPlexServerUrlHelper => 'Entrez l\'IP local et le port de votre serveur de médias Plex.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (optionnel)';
	@override String get plexTokenHelper => 'Laissez vide si l\'accès sans auth est autorisé sur ce serveur.';
	@override String get plexTokenRequired => 'Veuillez entrer votre token Plex (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex serveur de médias (direct / local)';
	@override String get connectDirectPlexCardSubtitle => 'Connectez-vous directement en utilisant l’IP ou l’URL local sans compte plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Connectez-vous directement en utilisant l’IP ou l’URL local. Connectez à ${name}.';
	@override String get insecureTitle => 'Connexion non cryptée';
	@override String insecureDescription({required Object url}) => '${url} utilise HTTP. Des personnes sur le réseau peuvent lire ou modifier votre mot de passe, vos jetons et vos médias. Utilisez HTTPS si possible. Ne continuez que si vous faites confiance à ce réseau et acceptez le risque.';
	@override String get allowHttp => 'Autoriser HTTP';
	@override String get httpsRequired => 'Utilisez HTTPS ou autorisez explicitement une connexion non cryptée.';
}

// Path: cast
class Translations$cast$fr extends Translations$cast$en {
	Translations$cast$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Coup sur un appareil';
	@override String get searching => 'En recherche de dispositifs de châtiment...';
	@override String connectedTo({required Object device}) => 'Connectez-vous à ${device}';
	@override String get device => 'Dispositif de casting';
	@override String get readyToCast => 'Prêt à lancer';
	@override String get subtitle => 'Sous-titres';
	@override String get serverNotAvailable => 'Le serveur de médias n’est pas disponible.';
	@override String get stopCasting => 'Arrêter de casting';
	@override String get castToDevice => 'Changer à l\'appareil';
	@override String get noEpisodeAvailable => 'Il n\'y a pas d\'épisode disponible pour le lancer.';
	@override String get startFailed => 'Je ne peux pas commencer à lancer. vérifier le serveur et essayer à nouveau.';
}

// Path: automation
class Translations$automation$fr extends Translations$automation$en {
	Translations$automation$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Il n\'y a pas de session vidéo active à contrôler.';
}

// Path: notifications
class Translations$notifications$fr extends Translations$notifications$en {
	Translations$notifications$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Nouveau épisode';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class Translations$appAccess$fr extends Translations$appAccess$en {
	Translations$appAccess$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Essayez chaque fonctionnalité gratuitement pendant 7 jours';
	@override String get description => 'Démarrez un essai de sept jours avec un accès complet à chaque fonctionnalité PlezyNG. il n\'y a pas de frais pendant le essai et pas d\'abonnement. Après le essai, une achat de vie au prix de votre magasin déclenche PlezyNG pour la vie.';
	@override String get trialEndedDescription => 'Déblocage de chaque fonctionnalité dans PlezyNG pour la vie avec une achat au prix de votre magasin.';
	@override String get startTrial => 'Démarrer mon essai gratuit de 7 jours';
	@override String get trialActive => 'Votre essai de 7 jours en plein fonctionnement est actif.';
	@override String get trialEnded => 'Votre procès de 7 jours est terminé';
	@override String get trialStartFailed => 'Je ne pouvais pas sauver le test sur ce appareil. veuillez essayer à nouveau.';
	@override String get lifetimeTitle => 'PlezyNG déconnecté pour la vie';
	@override String get lifetimeBody => 'Merci ! vous avez accès à toute la vie à chaque fonctionnalité PlezyNG.';
	@override String get manageTitle => 'PlezyNG accès à vie';
	@override String get manageDescription => 'Essayez chaque fonctionnalité gratuitement pendant 7 jours, puis déverrouillez tout pour la vie avec un seul paiement au prix de votre magasin.';
	@override String buy({required Object price}) => 'Déconnecter chaque fonctionnalité pour ${price}';
	@override String get loadingPrice => 'Le prix de la boutique...';
	@override String get retryPrice => 'Retour sur le prix';
	@override String get restore => 'Restaurer l’achat de vie';
	@override String get pending => 'Votre achat attend le paiement ou l\'approbation.Lifetime accès s\'ouvrira dès que le magasin le remplit.';
	@override String get storeUnavailable => 'Vérifiez que vous êtes inscrit dans le magasin et que les achats sont autorisés sur ce dispositif.';
	@override String get productNotFound => 'Le déclin de vie PlezyNG n\'est pas encore disponible dans ce magasin.';
	@override String get productQueryFailed => 'Je ne pourrais pas charger le prix du magasin. vérifier votre connexion et essayer à nouveau.';
	@override String get purchaseFailed => 'L’achat n’a pas été effectué, essayez-le encore.';
	@override String get restoreFailed => 'Je ne pouvais pas aller au magasin pour restaurer votre achat.';
	@override String get nothingToRestore => 'Le numéro PlezyNG achat à vie a été trouvé pour ce compte de magasin.';
}

// Path: detail
class Translations$detail$fr extends Translations$detail$en {
	Translations$detail$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Se termine à ${time}';
}

// Path: watchLink
class Translations$watchLink$fr extends Translations$watchLink$en {
	Translations$watchLink$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Je ne pouvais pas accéder à un serveur Plex pour ce lien.';
	@override String get notFound => 'Je ne pouvais pas trouver ce spectacle ou le film sur vos serveurs Plex.';
	@override String get ambiguous => 'Ce lien correspond aux éléments sur plus d\'un serveur.Ajout d\'un server au lien.';
	@override String get plexOnly => 'Les liens de vision ne supportent actuellement que les serveurs Plex.';
	@override String get unsupportedItem => 'Les liens de regarder ne peuvent ouvrir qu\'un spectacle ou un film.';
	@override String get menuItem => 'Afficher le lien';
	@override String get dialogTitle => 'Voir le lien';
	@override String get dialogShowHint => 'Pour ouvrir ce lien, il est possible de jouer le prochain épisode.Add &mode=shuffle à la fin pour jouer le spectacle sur shuffle.';
	@override String get dialogMovieHint => 'En ouvrant ce lien, le film est joué.';
	@override String get copy => 'Copie';
	@override String get copied => 'Link copie';
}

// Path: homeLayout
class Translations$homeLayout$fr extends Translations$homeLayout$en {
	Translations$homeLayout$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Layout';
	@override String get resetToast => 'Réservez à la page originale Plezy';
	@override String get resetHeroTitle => 'Résetez le layout de l\'héroïne à stock Plezy ?';
	@override String get resetHeroBody => 'Il détourne l\'établissement de chaque rang et remet le seul drapeau de rotation au sommet de la maison, comme avant que les rangs de héros existent.';
	@override String get removeRowTitle => 'Réserver la ligne de maison ?';
	@override String removeRowBody({required Object title}) => '${title} sera supprimé. ceci ne peut être non.';
	@override String get sync => 'Synchroniser';
	@override String get syncAccountTitle => 'Synchroniser le layout avec votre compte Plex';
	@override String get syncAccountOn => 'Sur : ce dispositif partage la commande de la ligne, les lignes, le héros et l\'automatisation avec vos autres appareils.';
	@override String get syncAccountOff => 'Off : ce dispositif maintient son propre layout.';
	@override String get syncNow => 'Synchronisation maintenant';
	@override String get plexHomeManager => 'Plex Gestion de la maison';
	@override String get managePlexRows => 'Gérer Plex rangs dans Plezy';
	@override String get managePlexRowsDescription => 'Ouvert pour organiser les lignes sélectionnées à domicile';
	@override String get organizeHomeRows => 'Organiser les roues de maison';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} lignes: mouvement, héros, auto-slide, suppression';
	@override String organizeLibraryRows({required Object library}) => 'Résultats de la ${library}';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Continuez à regarder + ${n} lignes: mouvement, Bibliothèque, Maison, Héroe, Slide automatique';
	@override String get renderAsHero => 'Render comme une carte héros';
	@override String get heroOnlySingleCollection => 'Disponible uniquement lorsque cette ligne se résout aux titres réels d\'une seule collection';
	@override String get hero => 'Héroe';
	@override String get autoSlide => 'Autoslire';
	@override String get autoSlideDescription => 'Les arros (PC) et d-pad (TV) fonctionnent toujours et reprenent le timer.';
	@override String get autoSlideEditDescription => 'Il se décline : il ne se déplace que lorsque vous cliquez sur une armoire (PC) ou pressez la gauche/droite sur la télévision (TV).';
	@override String get enableHeroFirst => 'Un héros en premier';
	@override String get showOnHome => 'Afficher sur l\'écran de maison';
	@override String get home => 'Accueil';
	@override String get removeFromHome => 'Retirez de chez vous';
	@override String get selectRowsFirst => 'Sélectionnez les lignes de maison ci-dessous d\'abord.';
	@override String plexManagedRows({required Object n}) => '${n} Plex rangées gérées';
	@override String get continueWatching => 'Continuer à regarder';
	@override String get continueWatchingLibraryDescription => 'La suite de la bibliothèque de la suite';
	@override String get continueWatchingHomeDescription => 'Le nouveau progrès de la ligne montrée sur Home';
	@override String get nextUpHomeDescription => 'La prochaine série de l\'épisode non vu diffusée séparément sur Home';
	@override String get library => 'Bibliothèque';
	@override String get showInRecommended => 'Présentation dans la bibliothèque recommandée';
	@override String get customPlexRow => 'Résultats de la Plex';
	@override String get heroNeedsLibrary => 'Vérifier la bibliothèque d\'abord - Le héros a besoin d\'un endroit où il faut montrer';
	@override String get heroNeedsSurface => 'Vérifier la bibliothèque ou la maison d\'abord - Le héros a besoin d\'un endroit où il faut montrer';
	@override String get removeHub => 'Réserver le Hub';
	@override String get noPlexRows => 'Aucune rangée gérée par Plex n’a été renvoyée pour cette bibliothèque.';
	@override String get openDetails => 'détails ouverts';
	@override String get heroCards => 'Cartes héros';
	@override String get tapHeroCard => 'Tapeur d\'une carte héros';
	@override String get tvPlayFocus => 'Remote TV : le bouton de jeu';
	@override String get tvPlayFocusDescription => 'D-pad descendre s\'arrête sur le bouton Play avant de se déplacer à la prochaine ligne.';
	@override String get tvWrap => 'TV Remote : cartes de la bande-annonce';
	@override String get tvWrapDescription => 'Ensuite, le dernier passe à la première carte, le dernier se passe à la dernière carte, le premier passe toujours à la barre.';
	@override String get castOnHero => 'Les Banner Hero';
	@override String get castOnHeroDescription => 'Affiche le cast le long du fond d\'un banner héros. Off ne tient que le titre et le résumé.';
	@override String get customRows => 'Ronde de Custom';
	@override String get loading => 'La mise à jour de la maison...';
	@override String get noCustomRows => 'Pas de coutures encore';
	@override String get addRowHint => 'Utilisez Add Home row pour créer un.';
	@override String get addHomeRow => 'Ajouter la ligne de maison';
	@override String get addHomeRowDescription => 'Choisissez une catégorie ; la nouvelle ligne est ajoutée à l\'Organisateur automatiquement';
	@override String get removeRow => 'Réserver la ligne';
	@override String get recentlyAdded => 'Récemment ajouté';
	@override String get recentlyReleased => 'Récemment libéré';
	@override String get movieCollections => 'Film Collections';
	@override String get showCollections => 'Afficher les collections';
	@override String get rowTitle => 'Titre Row';
	@override String get content => 'contenu';
	@override String get showThisRowIn => 'Afficher cette ligne dans :';
	@override String get libraryRecommended => 'Bibliothèque recommandée';
	@override String get heroCard => 'Cartes héros';
	@override String get heroCardDescription => 'Il apparaît comme une carte de rotation à largeur entière au lieu d\'un plafond de poster.';
	@override String get heroUnavailableDescription => 'Seulement disponible lorsque cette ligne se résout aux titres réels d\'une seule collection - avec plus d\'une collection sélectionnée il n\'y a pas de titre unique à tourner.';
	@override String get librariesSelection => 'Bibliothèques (lettre toutes les bibliothèques non vérifiées pour inclure chaque bibliothèque)';
	@override String get librariesMergedDescription => 'Chaque bibliothèque qui est vérifiée ici est fusionnée dans cette ligne.';
	@override String get movieCollectionsSelection => 'Collections de films (levez toutes les livres non vérifiés pour chaque bibliothèque sélectionnée)';
	@override String get showCollectionsSelection => 'Afficher les collections (levez toutes les bibliothèques non vérifiées)';
	@override String get collectionRowsDescription => 'Si exactement une collection se rencontre, ses titres apparaissent directement dans la ligne.Si plus d\'une collection se rencontre , chaque collection apparaît comme un seul poster - tapez-le pour ouvrir cette collection.';
	@override String get allCollections => 'Toutes les collections';
	@override String get noRowsHere => 'Pas de rangs ici encore.';
	@override String get hideWatchedRows => 'Mettre des objets cachés en ligne';
	@override String get hideWatchedRowsDescription => 'Titres complètement regardés quittent la maison et la bibliothèque Les lignes recommandées.';
	@override String get untitledCollection => 'Collection sans titre';
	@override String get moveRowHint => 'Up/Down: déplacer la ligne · Sélectionnez: la débarrasser ici · Retour: annuler';
	@override String get organizeRowsHint => 'Sélectionnez sur une ligne (ou retenez Sélectionnez): déplacez-le · gauche/droite: options de ligne · Retour: fait';
	@override String get layoutNavDescription => 'Choisissez les catégories de catégories, bibliothèques et collections';
	@override String get editHomeRow => 'Edit à domicile';
	@override String get resetHeroButton => 'Résetez le layout de l\'héroïne à stock Plezy';
	@override String get reorderingUnlocked => 'Réservation déclenchée';
	@override String get reorderingLocked => 'Réservation bloquée';
	@override String get rowsCanBeDragged => 'Les rayons peuvent être tirés — tapez le verrou pour éviter que';
	@override String get tapLockToDrag => 'Tapez le lock pour tirer les lignes';
	@override String customRowLabel({required Object title}) => 'Numéro de la personne : ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Masquer';
	@override String get remove => 'Retirer';
	@override String get libraryResumeRow => 'La bibliothèque de la suite';
	@override String get pressAgainToDelete => 'Appuyez à nouveau sur le supprimant';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'sur';
	@override String get resetHeroButtonDescription => 'Il détourne la configuration de chaque rang et ramène le seul drapeau de roulement au sommet, comme avant que les rangs de héros existent.';
	@override String get tapHeroCardDescription => 'Choisissez si le tapage ou la sélection d\'une carte Hero commence à reproduire ou ouvre ses détails.';
	@override String get heroTapPlayDescription => 'Démarrez immédiatement l’élément sélectionné.';
	@override String get heroTapDetailsDescription => 'Ouvrez les détails de l\'élément sélectionné avant de choisir une action.';
}

// Path: platform
class Translations$platform$fr extends Translations$platform$en {
	Translations$platform$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG se connecte à vos serveurs multimédias et à vos appareils de lecture sur votre réseau local.';
	@override String get locationPermission => 'PlezyNG utilise l\'accès à la localisation lorsque iOS l\'exige pour détecter votre réseau local et se connecter à vos serveurs de médias.';
	@override String get photoLibraryPermission => 'Choisissez des images de votre photothèque pour illustrer vos médias.';
	@override String get cameraPermission => 'Scannez des codes QR pour associer une Companion Remote.';
}

// Path: universalMedia
class Translations$universalMedia$fr extends Translations$universalMedia$en {
	Translations$universalMedia$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Médias ouverts';
	@override String get shortcutHelp => 'Jouez à un lien, une playlist ou un fichier pour cette session.';
	@override String get intro => 'Ouvrez un lien, une liste de lecture ou un fichier. Playback utilise le lecteur standard de PlezyNG et n’ajoute pas d’historique à votre bibliothèque.';
	@override String get openWhat => 'Que voudriez-vous ouvrir ?';
	@override String get stream => 'Adresse de courant';
	@override String get playlist => 'Joueurs';
	@override String get files => 'Les fichiers de dispositif';
	@override String get favorites => 'Réservation de flux favoris';
	@override String get address => 'Adresse médiatique';
	@override String get addressHelp => 'Les URL avec des paramètres d\'accréditation ou de signature reconnus ne sont utilisés que pour cette session et ne peuvent pas être sauvegardés comme favoris.';
	@override String get displayName => 'Nom d’affichage (optionnel)';
	@override String get displayNameHelp => 'Choisissez un nom court pour le lecteur et les contrôles de médias du système.';
	@override String get allowHttp => 'Permettre une connexion HTTP non cryptée';
	@override String get allowHttpHelp => 'HTTP n\'encrypte pas la connexion. permet seulement sur un réseau fiable. Utilisez HTTPS quand c\'est possible.';
	@override String get advancedProtocols => 'MPV seulement: entrez une adresse RTSP, RTMP/RTMPS, UDP ou RTP. Ces adresses ne peuvent pas être sauvegardées comme préférées.';
	@override String get liveStream => 'Traiter comme vivant';
	@override String get liveStreamHelp => 'Utilisez ceci pour la vidéo ou la radio en direct. l\'application cache la barre du temps, les boutons de ski et l\'option go-to-time.';
	@override String get privateSession => 'Seul ce recueil utilise l’adresse.Save an eligible stream favorite to keep it in this profile.';
	@override String get saveFavorite => 'Sauvegarder les favoris';
	@override String get playNow => 'Jouer maintenant';
	@override String get favoriteSaved => 'Stream favorite a été sauvé à ce profil';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Skipped ${count} unsupported or unsafe playlist entry.',
		many: 'Skipped ${count} unsupported or unsafe playlist entries.',
		other: 'Skipped ${count} unsupported or unsafe playlist entries.',
	);
	@override String get playlistAddress => 'L’adresse de la playlist';
	@override String get playlistAddressHelp => 'Ouvrez une liste de lecture M3U, M3u8 ou PLS à partir d\'une adresse Web. Les liens en streaming directs ne sauvent pas la liste de jeu.';
	@override String get choosePlaylist => 'Choisissez le fichier playlist';
	@override String get openPlaylist => 'Ouverture playlist';
	@override String get playlistFormatsHelp => 'Une liste de lecture peut contenir jusqu\'à 1000 articles et 2 MB. HLS se manifeste comme des courants afin que le joueur puisse choisir une qualité.';
	@override String get noFavorites => 'Il n\'y a pas encore de préférés en streaming. les favoris restent dans ce profil.';
	@override String get removeFavorite => 'Supprimer les flux préférés';
	@override String get filesHelp => 'Choisissez des fichiers audio, vidéo ou ISO pour une couverture temporaire.Fichiers et URL ne sont pas ajoutés à l\'histoire de la bibliothèque.';
	@override String get chooseFiles => 'Choisir des fichiers';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '1 fichier sélectionné',
		many: '${count} fichiers sélectionnés',
		other: '${count} fichiers sélectionnés',
	);
	@override String get wifiTransfer => 'Envoyer des fichiers via Wi-Fi';
	@override String get wifiTransferHelp => 'Transfert des fichiers soutenus d\'un navigateur sur le même réseau fiable.';
	@override String get wifiTransferIntro => 'Ouvrez cette adresse dans un navigateur sur un autre appareil. Sélectionnez les fichiers pour les ajouter à la bibliothèque des Fichiers et livres de cet appareil .';
	@override String get wifiTransferPrivacy => 'Ce dispositif reçoit des fichiers sur votre réseau local.Celui qui connaît cette adresse peut envoyer des ficher jusqu\'à ce que vous arrêtez le transfert ou l\'adresse expire après 15 minutes.Maximum: 100 fichières, 4 GiB par fichier, 10 GiB total.';
	@override String get wifiTransferStarting => 'Pour un transfert privé et à temps limité...';
	@override String get wifiTransferUnavailable => 'Vous ne pouvez pas commencer le transfert. vérifier l\'accès au réseau local et essayer à nouveau.';
	@override String get openThisAddress => 'Ouvrez l\'une de ces adresses sur le dispositif d\'envoi';
	@override String get copyAddress => 'Copie de l\'adresse de transfert';
	@override String get addressCopied => 'Adresse de transfert copiée';
	@override String transferExpires({required Object time}) => 'Cette adresse expire dans ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'fichier ${count} reçu',
		many: 'Les fichiers ${count} reçus',
		other: 'Les fichiers ${count} reçus',
	);
	@override String uploadedData({required Object size}) => 'Recevoir ${size}';
	@override String get stopTransfer => 'Arrêter le transfert et invalider l’adresse';
	@override String get startTransfer => 'Démarrer le transfert';
	@override String get wifiImportedFiles => 'Transfert Wi-Fi';
	@override String get wifiBrowserTitle => 'Envoyer des fichiers à PlezyNG';
	@override String get wifiBrowserIntro => 'Choisissez les fichiers audio, vidéo, ebook ou comique pour envoyer. Les fichières sont sauvegardées dans la bibliothèque des Fichiers et livres de cet appareil. Maximum: 100 fichires, 4 GiB par fichier, 10 GiB total.';
	@override String get uploadFilesLabel => 'Les fichiers à envoyer';
	@override String get uploadSelected => 'Télécharger les fichiers sélectionnés';
	@override String get uploadSelectFirst => 'Choisissez d’abord un ou plusieurs fichiers.';
	@override String get uploading => 'Envoyer';
	@override String get uploadComplete => 'Fichiers ajoutés à PlezyNG.';
	@override String get uploadFailed => 'Le fichier ne pouvait pas être ajouté. Gardez cette page ouverte et essayez à nouveau.';
	@override String get liveCue => 'Vivre';
	@override String get liveSession => 'Stream en direct';
	@override String get liveCueHelp => 'Pour la vidéo ou la radio en direct, l\'application cache la barre de temps et les boutons échappent.';
	@override String get sessionOnly => 'Ce playback n’est qu’une session';
	@override String get sessionOnlyHelp => 'Playback ne sauve jamais le progrès ou l\'histoire.Save the stream as a favorite to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'Ajustement de l\'image';
	@override String get pictureHelp => 'Ces changements d\'image n\'affectent que ce playback. Ils sont réinitialisés lorsque le playback se termine.';
	@override String get resetPicture => 'Récupérer l\'image';
	@override String get brightness => 'Brilleur';
	@override String get contrast => 'Contraste';
	@override String get gamma => 'La gamme';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturation';
	@override String get view360 => 'Voir la vidéo à 360°';
	@override String get view360Help => 'Utilisez ceci pour la vidéo 360° équirectangulaire. MPV a besoin du filtre v360 de FFmpeg pour cette vue.';
	@override String get view360Unavailable => 'Cette configuration mpv ne pouvait pas appliquer le filtre 360°.';
	@override String get view360Yaw => 'Vue horizontale';
	@override String get view360Pitch => 'Vue verticale';
	@override String get view360FieldOfView => 'Le champ de vue';
	@override String get recordStream => 'Résumé Live Stream';
	@override String get stopRecording => 'Arrêter et sauvegarder l’enregistrement';
	@override String get recordingStarted => 'L\'enregistrement est actif. Laisser le playback s\'arrête et sauve l\'enregistration.';
	@override String get recordingSaved => 'L’enregistrement est terminé et sauvé.';
	@override String get recordingActive => 'Enregistrer sur ce dispositif. Laisser le playback s\'arrête et la sauve.';
	@override String get recordingFormatHelp => 'Pour la vidéo, choisissez MKV ou MPEG-TS. Pour l\'audio, sélectionnez MKA ou MKV.';
	@override String get replaceRecordingTitle => 'Remplacer cette enregistrement ?';
	@override String get replaceRecordingHelp => 'PlezyNG récupère le fichier existant pendant l’enregistrement.Si il ne peut pas sauvegarder la nouvelle enregistrement, Plezy NG rétablit la sauvegardation.';
	@override String get replaceRecording => 'Remplacer le fichier';
	@override String get discHelp => 'Ouvrez un disque dans le disque optique de cet ordinateur. Vous pouvez également ouvrir une image ISO des fichiers Device.';
	@override String get discs => 'Le disque optique';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Blu-ray';
	@override String get audioCd => 'CD audio';
	@override String get discAvailability => 'La lecture du disque nécessite une configuration MPV compatible, un disque supporté et la permission système d\'exploitation.';
	@override String get converterTitle => 'Convertir un fichier médiatique local';
	@override String get converterHelp => 'Convertir un fichier local ou le remuer avec FFmpeg.';
	@override String get converterIntro => 'Convertez un fichier audio ou vidéo local dans un format qui fonctionne sur plusieurs appareils.';
	@override String get converterPrivacy => 'FFmpeg doit être installé sur ce ordinateur. Conversion ne lit que les fichiers locaux. Il ne télécharge pas les courants ou supprime DRM.';
	@override String get converterChooseInput => 'Choisissez un fichier médiatique local';
	@override String get converterFormat => 'Format de sortie';
	@override String get converterMp4 => 'MP4 · H.264 et AAC';
	@override String get converterM4a => 'M4A · AAC audio';
	@override String get converterMp3 => 'MP3 et audio';
	@override String get converterSaveAs => 'Enregistrer les médias convertis comme';
	@override String get converterExtensionMismatch => 'Choisissez un nom de fichier avec l\'extension de sortie sélectionnée.';
	@override String get converterUnsupportedInput => 'Choisissez un fichier audio ou vidéo.';
	@override String get converterLocalOnly => 'Le fichier sélectionné n\'est pas disponible en tant que voie d\'appareil locale.';
	@override String get converterReplaceTitle => 'Remplacer ce fichier ?';
	@override String get converterReplaceHelp => 'PlezyNG récupère le fichier existant jusqu\'à ce que la copie convertie soit sauvée.';
	@override String get converterStarting => 'Commencez par FFmpeg...';
	@override String get converterProgress => 'Convertir sur cet ordinateur...';
	@override String get converterComplete => 'Conversion complète. le nouveau fichier est prêt.';
	@override String get converterFfmpegMissing => 'FFmpeg Il manque ou ne soutient pas ce format.';
	@override String get converterFailed => 'Vérifiez que le fichier source peut être lu et que la destination a suffisamment d\'espace gratuit.';
	@override String get converterCancelled => 'La conversion a été annulée. la sortie incomplète a été supprimée.';
	@override String get converterDesktopOnly => 'La conversion locale est disponible sur les ordinateurs de bureau avec FFmpeg installé.';
	@override String get converterStart => 'Conversion des fichiers';
	@override String get mediaToolsTitle => 'Les outils médiatiques';
	@override String get mediaToolsShortcut => 'Capture ou partage des médias, ajouter des extensions de recherche, ou utiliser la ligne de commande.';
	@override String get mediaToolsIntro => 'Choisissez un outil focalisé. capture et stream-out utilisez FFmpeg installé sur ce bureau. Extensions et les commandes CLI utilisent les requêtes HTTPS liées et le flux Open media existant.';
	@override String get mediaToolsAccessibility => 'Les choix d\'outils et les contrôles fonctionnent avec le toucher, le pointteur, le clavier et le focus D-pad. Les modifications de l\'état de l\'enregistrement, du partage et de la recherche sont annoncées.';
	@override String get mediaTool => 'Outils de médias';
	@override String get captureIntro => 'Enregistrez votre écran ou une caméra dans un fichier MP4 sur ce ordinateur. FFmpeg doit être installé et inclure le codage H.264.';
	@override String get captureNoDevices => 'Aucun écran ou une caméra n\'a été trouvée. Vérifier FFmpeg support de capture et les autorisations de confidentialité du système d\'exploitation.';
	@override String get captureSource => 'Écran ou caméra';
	@override String get captureAudioSource => 'Entrée audio (optionnelle)';
	@override String get captureAudioHelp => 'Ajouter de l\'audio à partir d\'un microphone ou d\'une entrée disponible. Les choix du dispositif dépendent de FFmpeg et des autorisations du système.';
	@override String get captureAudioNone => 'Pas d’audio';
	@override String get captureWaylandHelp => 'Wayland limite cette capture XWayland au X display. Windows hors XWayland ne peut pas apparaître.';
	@override String get captureFrameRate => 'Résultats de l’enregistrement';
	@override String get capturePrivacy => 'L\'enregistrement est enregistré uniquement au fichier que vous choisissez. capture de microphone est facultative. PlezyNG ne télécharge pas l\'enregistrement.';
	@override String get captureSaveAs => 'Enregistrer l’écran comme';
	@override String get captureExtensionMismatch => 'Choisissez un nom de fil qui se termine dans .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg ou l\'encoder vidéo H.264 n\'est pas disponible. installez une construction FFmpeg soutenue, puis essayez de nouveau.';
	@override String get captureFailed => 'Vérifiez la permission du dispositif, le stockage disponible et le support FFmpeg.';
	@override String get captureSaved => 'L’enregistrement d’écran a été sauvé.';
	@override String get captureElapsedLabel => 'Temps d\'enregistrement';
	@override String get captureStart => 'Commencer l’enregistrement';
	@override String get captureStop => 'Arrêter et sauver';
	@override String get captureMode => 'capture';
	@override String get shareMode => 'partage';
	@override String get shareIntro => 'Envoyez un fichier de médias local à un autre appareil sur votre réseau privé. PlezyNG crée un flux temporaire HLS.';
	@override String get sharePrivacy => 'Tout le monde sur votre réseau local qui reçoit le lien privé peut regarder pendant qu\'il est actif. Le lien expire après 60 minutes. Arrêter de partager pour fermer le serveur et invalider le lien.';
	@override String get shareChooseFile => 'Choisissez le fichier médiatique';
	@override String get shareChooseHelp => 'Sélectionnez un fichier audio ou vidéo local. Le fichier reste sur ce ordinateur.';
	@override String get shareFfmpegMissing => 'FFmpeg ou les codes H.264/AAC ne sont pas disponibles. Installez FFmpeg avec le support de codage H.264 et AAC.';
	@override String get shareFailed => 'Le courant ne pouvait pas commencer ou s\'arrêter inattendu. vérifier FFmpeg et l\'accès au réseau.';
	@override String get shareActive => 'Le courant est prêt sur votre réseau privé.';
	@override String get shareEnded => 'Les médias ont atteint la fin et ne sont plus partagés.';
	@override String get shareStopped => 'Le lien temporaire n\'est plus valide.';
	@override String get shareUrlCopied => 'L’adresse est copiée.';
	@override String get shareOpenUrl => 'Ouvrez cette adresse dans un joueur sur l\'autre appareil';
	@override String get shareCopyUrl => 'Copie de l’adresse Stream';
	@override String get shareExpiresLabel => 'Le lien expire à';
	@override String get shareStarting => 'Préparer le flux...';
	@override String get shareStart => 'Commencer partage';
	@override String get shareStop => 'Arrêter de partager';
	@override String get extensionsMode => 'Extensions et CLI';
	@override String get extensionsIntro => 'Ajoutez une extension de recherche uniquement pour trouver les médias. Choisissez un résultat pour le charger dans le formulaire familial Open media.';
	@override String get extensionsPrivacy => 'Un manifeste peut définir un endpoint de recherche et des champs de réponse de la carte de HTTPS. Il ne peut pas exécuter le code, ajouter des titres de requête, lire les fichiers, ou lancer les commandes shell.';
	@override String get extensionImport => 'Ajouter l’extension manifeste';
	@override String get extensionEmpty => 'Aucun service de recherche encore. Choisissez un fichier manifeste fiable JSON pour ajouter un.';
	@override String get extensionChoose => 'Service de recherche';
	@override String get extensionSearchConsent => 'Chaque recherche envoie vos mots à ce service HTTPS. Les résultats ne s\'ouvrent qu\'après que vous choisissez un.';
	@override String get extensionSearchLabel => 'Médias de recherche';
	@override String get extensionSearch => 'Recherche';
	@override String get extensionSearching => 'Rechercher...';
	@override String get extensionNoResults => 'Aucun résultat de médias sécurisés n\'a été retourné. essayez une autre recherche.';
	@override String get extensionInstallTitle => 'Ajouter ce service de recherche ?';
	@override String get extensionReplaceTitle => 'Mettre à jour ce service de recherche ?';
	@override String get extensionService => 'Service';
	@override String get extensionEndpoint => 'HTTPS point de fin';
	@override String get extensionConsent => 'Votre texte de recherche est envoyé à ce service. le manifeste ne contient pas de code exécutable. Continuez seulement si vous avez confiance à ce point de fin.';
	@override String get extensionInstall => 'Ajouter service';
	@override String get extensionReplace => 'Service de mise à jour';
	@override String get extensionRemoveTitle => 'Supprimer ce service de recherche ?';
	@override String get extensionRemoveHelp => 'Ceci supprime le service de ce profil. PlezyNG n\'a pas contact avec son endpoint.';
	@override String get extensionRemove => 'Supprimer le service';
	@override String get extensionInvalidManifest => 'Ce fichier n\'est pas un manifeste d\'extension soutenu. voir le guide Open media pour le format.';
	@override String get extensionSaveFailed => 'L’extension ne pouvait pas être sauvée au profil actif.';
	@override String get extensionSearchFailed => 'Le service de recherche n\'a pas retourné une réponse valide. vérifier le point de fin et essayer à nouveau.';
	@override String get cliTitle => 'Ligne de commande';
	@override String get cliHelp => 'Utilisez le guide plezyctl pour valider un manifeste ou rechercher la même extension. Revue son service HTTPS avant chaque recherche. Résultats ouverts dans le formulaire médiatique existant; sélectionnez le bouton de reprise pour démarrer.';
	@override String get cliCopyExample => 'Copie de l’exemple';
	@override String get cliCopied => 'Commande exemplaire copié.';
	@override String get captureScreen => 'écran';
	@override String get captureDefaultAudio => 'Introduction audio par défaut';
	@override String get shareQrLabel => 'Code QR pour l\'adresse de courant temporaire';
	@override String get shareQrHelp => 'Scanner avec un lecteur compatible connecté au même réseau privé.';
	@override String get shareHttpHint => 'Ce flux utilise HTTP non crypté. Dans PlezyNG, permettez HTTP avant de l\'ouvrir.';
	@override String get allowFtp => 'Permettre FTP';
	@override String get allowFtpHelp => 'FTP envoie les médias sans cryptage.Utilisez uniquement sur des réseaux fiables.';
}

// Path: fileSources
class Translations$fileSources$fr extends Translations$fileSources$en {
	Translations$fileSources$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fichiers et livres';
	@override String get subtitle => 'Lire, écouter et regarder de vos propres fichiers.';
	@override String get add => 'Ajouter source';
	@override String get importFiles => 'Importer des fichiers';
	@override String get localFiles => 'sur ce dispositif';
	@override String get source => 'source';
	@override String get name => 'Nom';
	@override String get endpoint => 'URL du serveur';
	@override String get smbEndpointHint => 'Exemple : smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Saisissez un serveur SMB et un dossier partagé.';
	@override String get root => 'Fiche ou préfix';
	@override String get smbFolderHelp => 'Laissez vide pour utiliser tout le dossier partagé, ou saisissez un dossier qu’il contient.';
	@override String get username => 'Nom d\'utilisateur';
	@override String get smbDomain => 'Domaine (facultatif)';
	@override String get password => 'Mot de passe';
	@override String get token => 'API Télécharger';
	@override String get accessKey => 'ID clé d\'accès';
	@override String get secretKey => 'Clé d\'accès secret';
	@override String get sessionToken => 'Le token de session (optional)';
	@override String get region => 'Région';
	@override String get clientId => 'ID client de l\'AAAUTH';
	@override String get clientSecret => 'OAuth client secret (seulement sur le bureau Google)';
	@override String get allowHttp => 'Autoriser HTTP non chiffré sur un réseau de confiance';
	@override String get smbEncryption => 'Chiffrer la connexion SMB3';
	@override String get smbEncryptionHint => 'Utiliser le chiffrement SMB3 lorsque le NAS le prend en charge.';
	@override String get connect => 'Se connecter';
	@override String get cancel => 'Annuler';
	@override String get save => 'Enregistrer';
	@override String get close => 'Fermer';
	@override String get removeSource => 'La source disconnectée';
	@override String get disconnectMessage => 'Déconnecter cette source ? Les fichiers téléchargés et votre historique de lecture et d’écoute resteront sur cet appareil.';
	@override String get localFolder => 'Choisir la carte';
	@override String get empty => 'Rien ici pour l\'instant';
	@override String get emptyHint => 'Ajouter une source ou importer un livre, un livre audio, une musique ou un vidéo.';
	@override String get search => 'Recherchez ce dossier';
	@override String get searchCached => 'Rechercher la bibliothèque sauvée';
	@override String get refresh => 'Rafraîchir';
	@override String get loadMore => 'Charger plus';
	@override String get offline => 'Disponible en offline';
	@override String get download => 'Restez hors ligne';
	@override String get removeDownload => 'Supprimer une copie offline';
	@override String get continueReading => 'Continuer la lecture';
	@override String get continueListening => 'Continuez à écouter';
	@override String get continueWatching => 'Continuez à regarder';
	@override String get read => 'Lire';
	@override String get listen => 'Écouter';
	@override String get play => 'Lire';
	@override String get pause => 'Pâques';
	@override String get stop => 'Arrêter';
	@override String get startOver => 'Démarrer par';
	@override String get finished => 'Terminé';
	@override String get markFinished => 'Marque terminé';
	@override String get markUnfinished => 'Marque infinie';
	@override String get editions => 'éditions et fichiers';
	@override String get chapters => 'Chapitres';
	@override String get bookmarks => 'Les notes et les notes';
	@override String get bookmark => 'Ajouter le bookmark';
	@override String get highlight => 'L’accent';
	@override String get note => 'Note';
	@override String get delete => 'Supprimer';
	@override String get export => 'Les notes d\'exportation';
	@override String get exported => 'Les notes exportées';
	@override String get sync => 'Sync de progrès';
	@override String get synced => 'Progrès synchronisé';
	@override String get conflict => 'Un autre appareil a une position différente. Choisissez où continuer.';
	@override String get useLocal => 'Utilisez ce dispositif';
	@override String get useRemote => 'Utiliser un autre appareil';
	@override String get history => 'Histoire de position';
	@override String get groupAudio => 'Écouter comme un livre audio';
	@override String get groupHint => 'Combine les fichiers audio actuellement chargés dans cette dossier.Contactez toutes les pages d\'abord.';
	@override String get order => 'Ordonnance fichier';
	@override String get moveUp => 'Mouvement en haut';
	@override String get moveDown => 'Mouvez-vous en bas';
	@override String get speed => 'La vitesse de la playback';
	@override String get sleep => 'Minuterie de veille';
	@override String get sleepOff => 'Désactivé';
	@override String get endChapter => 'Fin du chapitre';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minute',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes',
	);
	@override String get skipBack => 'Rappelons le ski';
	@override String get skipForward => '- Skip en avant';
	@override String get smartRewind => 'Le retour intelligent après une pause';
	@override String get playbackOptions => 'Écouter les options';
	@override String remaining({required Object time}) => '${time} Réservé';
	@override String get contents => 'contenu';
	@override String get readerSettings => 'Lire les paramètres';
	@override String get fontSize => 'Taille de texte';
	@override String get lineHeight => 'Lien de spacing';
	@override String get margin => 'Marges';
	@override String get font => 'Police';
	@override String get serif => 'sérior';
	@override String get sans => 'Sans sérifié';
	@override String get mono => 'Monoparent';
	@override String get columns => 'Colonne';
	@override String get scroll => 'Scroll verticalement';
	@override String get justify => 'Justifier le texte';
	@override String get readerTheme => 'Page Apparition';
	@override String get appTheme => 'Suivez le thème de l\'app';
	@override String get paper => 'Papier';
	@override String get sepia => 'Sépique';
	@override String get night => 'nuit';
	@override String get readAloud => 'Lire cette page à voix haute';
	@override String get readAlong => 'Lire en continu';
	@override String get stopReading => 'Arrêter la narration';
	@override String get searchBook => 'Recherche dans le livre';
	@override String get noMatches => 'Pas de match';
	@override String get previousPage => 'Page précédente';
	@override String get nextPage => 'Page suivante';
	@override String page({required Object number}) => 'Page ${number}';
	@override String get externalBlocked => 'Les liens de livre extérieurs sont désactivés dans le lecteur.';
	@override String get loading => 'ouverture...';
	@override String get narrator => 'narrateur';
	@override String get audio => 'Audio';
	@override String get video => 'Vidéo';
	@override String get ebooks => 'Livres numériques';
	@override String get all => 'Tout';
	@override String get downloads => 'Fichiers hors ligne';
	@override String get confirmDelete => 'Supprimer la copie hors ligne sélectionnée ? votre position et vos notes restent.';
	@override String get errorAuthentication => 'Signature pour revenir sur cette source.';
	@override String get errorPermission => 'Cette source n’a pas donné accès au fichier demandé.';
	@override String get errorUnavailable => 'La source n\'est pas disponible. essayez de nouveau, ou ouvrir une copie hors ligne.';
	@override String get errorUnsupported => 'Ce format ou la connexion n\'est pas supporté sur ce appareil.Voir le guide de configuration source.';
	@override String get errorInvalidData => 'Ce fichier ou réponse serveur ne pouvait pas être lu en toute sécurité.';
	@override String get errorCancelled => 'L’opération a été annulée.';
	@override String get errorConflict => 'La position a changé dans une autre session. réouverture de l\'élément pour choisir une position.';
	@override String get signIn => 'Se connecter';
	@override String get reconnect => 'Se reconnecter';
	@override String get folderHelp => 'Laissez blanche pour commencer à la racine source. les URL S3 incluent le bucket.';
	@override String get preferences => 'Préférences';
	@override String get timePosition => 'Position';
	@override String get audioTrack => 'Track audio';
	@override String get subtitleTrack => 'Trail de sous-titre';
	@override String get none => 'Nulle';
	@override String get fullscreen => 'écran complet';
	@override String get syncLocation => 'Fiche de synchronisation progressive (optionnelle)';
	@override String get syncLocationHint => 'Une dossier dédiée à WebDAV pour PlezyNG état. Utilisez les écrits conditionnels; les médias restent inchangés.';
	@override String get audiobooks => 'Les audiobooks';
	@override String get comics => 'Bandes dessinées';
	@override String get scan => 'Scanner pour les livres et les médias';
	@override String get browserReader => 'Le lecteur ouvert';
	@override String get browserReaderHelp => 'Le lecteur est ouvert dans votre navigateur. Gardez le PlezyNG ouvert pour sauver votre place et vos notes.';
	@override String get on => 'sur';
	@override String get advancedSetup => 'App enregistration';
	@override String get microsoftSignIn => 'Inscrivez-vous avec Microsoft';
	@override String get zoomIn => 'Zoom dans';
	@override String get zoomOut => 'Zoom à l\'extérieur';
	@override String get fitPage => 'Page de faveur';
	@override String get fitWidth => 'Adapter la largeur';
	@override String get actualSize => 'La taille actuelle';
	@override String get goToPage => 'Aller à page';
	@override String get goToSection => 'Aller au chapitre';
	@override String pageRange({required Object count}) => 'Entrez un numéro de 1 à ${count}';
	@override String get pageLayout => 'Page de layout';
	@override String get automatic => 'Automatique';
	@override String get singlePage => 'Une page unique';
	@override String get twoPages => '2 pages';
	@override String get readingDirection => 'La direction de la lecture';
	@override String get leftToRight => 'à gauche à droite';
	@override String get rightToLeft => 'De droite à gauche';
	@override String get letterSpacing => 'Lettre spatiale';
	@override String get wordSpacing => 'Paroles spatiales';
	@override String get readerControlsHelp => 'Écartez deux doigts ou utilisez les commandes de zoom pour agrandir les pages. Faites glisser pour déplacer la page. Ctrl/⌘ avec + ou − règle le zoom ; Ctrl/⌘ avec 0 le réinitialise. Page Up et Page Down changent de page.';
	@override String get imagePage => 'Page de bande dessinée';
	@override String get resetReader => 'Réserver les préférences de lecture';
	@override String get zoom => 'Zoom';
	@override String get useFiles => 'Utiliser des fichiers et des livres';
	@override String get cancelScan => 'Annuler le scan';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Limitation de téléchargement offline';
	@override String get offlineQuotaHelp => 'Définissez l\'espace maximum utilisé par les copies hors ligne, les fichiers importés et les téléchargements courts. La réduction de la limite ne supprime pas les exemplaires existants.';
	@override String get offlineStorageUsage => 'stockage hors ligne';
	@override String get reservedStorage => 'Réservez';
	@override String get downloadQueue => 'Télécharger Queue';
	@override String get downloadRunning => 'Téléchargement';
	@override String get downloadQueued => 'Attendre';
	@override String get downloadPaused => 'Pause';
	@override String get downloadFailed => 'besoin de retraite';
	@override String get importing => 'importation';
	@override String get importInterrupted => 'Importation interrompue · supprimer à clarifier';
	@override String get errorQuotaExceeded => 'La limite de stockage hors ligne a été atteinte. Augmentez la limite ou supprimez une copie téléchargée.';
	@override String get errorStorageLow => 'Il n\'y a pas assez de stockage gratuit pour conserver la réserve protégée.';
	@override String get errorStorageUnavailable => 'PlezyNG ne pouvait pas vérifier le stockage de dispositif gratuit, donc l\'écriture a été arrêtée.';
	@override String get removeDownloadJob => 'Supprimer le download';
	@override String get downloadAlreadyComplete => 'Ce téléchargement est terminé avant qu\'il ne puisse être supprimé. l\'article est désormais disponible hors ligne.';
	@override String get confirmRemoveDownloadJob => 'Supprimer ce téléchargement et supprimer tous les données partiellement téléchargeées ? votre position et vos notes resteront.';
}

// Path: lending
class Translations$lending$fr extends Translations$lending$en {
	Translations$lending$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliothèques publiques';
	@override String get add => 'Ajoutez une bibliothèque';
	@override String get other => 'Une autre bibliothèque';
	@override String get libraryName => 'Nom de la bibliothèque';
	@override String get libraryUrl => 'Site de la bibliothèque';
	@override String get libraryUrlHint => 'Utilisez le catalogue de votre bibliothèque ou la page de signature.';
	@override String get intro => 'Prendre un prêt à la bibliothèque, garder vos livres fermés.';
	@override String get handoff => 'Inscrivez-vous, prêtez et lisez en toute sécurité avec le service de votre bibliothèque.';
	@override String get openService => 'Bibliothèque ouverte';
	@override String get findLibrary => 'Trouvez une bibliothèque';
	@override String get search => 'Rechercher des livres et des auteurs';
	@override String get catalogue => 'Catalogue';
	@override String get loans => 'Les prêts';
	@override String get holds => 'Réservations';
	@override String get signIn => 'Inscrivez-vous avec votre bibliothèque';
	@override String get waiting => 'Réservez votre abonnement dans votre navigateur, puis revenez ici.';
	@override String get cancel => 'Annuler';
	@override String get disconnect => 'Récupérer la bibliothèque';
	@override String get disconnectMessage => 'Retirer cette bibliothèque de ce profil ? Vos emprunts et réservations resteront enregistrés auprès de la bibliothèque.';
	@override String get getBook => 'Obtenez le livre';
	@override String get checkAvailability => 'Vérifier la disponibilité';
	@override String get available => 'Disponible pour emprunter';
	@override String get unavailable => 'Actuellement inaccessible';
	@override String get borrow => 'Emprunter';
	@override String get placeHold => 'Réserver';
	@override String get returnBook => 'Retour précoce';
	@override String get cancelHold => 'Annuler la réservation';
	@override String get confirmBorrow => 'Vous prêtez ce titre de votre bibliothèque ?';
	@override String get confirmReturn => 'Rendre ce titre maintenant ? Vous devrez peut-être l’emprunter de nouveau pour continuer.';
	@override String get confirmCancelHold => 'Annuler votre réservation de ce titre ?';
	@override String get email => 'Restez en e-mail de notification';
	@override String due({required Object date}) => 'Leur résultat : ${date}';
	@override String queue({required Object position}) => 'Position ${position} en ligne';
	@override String get empty => 'Pas de titres ici encore.';
	@override String get openLibraryNote => 'Explorez le catalogue de la Bibliothèque ouverte.Les options de lecture et de prêt sont affichées sur la page de chaque titre.';
	@override String get more => 'Charger plus';
	@override String get gateway => 'Bibliothèque de service';
	@override String get gatewayHint => 'Fourni par votre bibliothèque ou par l\'administrateur PlezyNG.';
	@override String get advanced => 'Intégration bibliothèque';
	@override String get loadLibraries => 'Choisissez votre bibliothèque';
	@override String get expired => 'Ce prêt est expiré.';
	@override String get updated => 'Bibliothèque mise à jour';
	@override String get continueService => 'Continuez à service';
	@override String get comingSoon => 'Prêt en app · Bientôt';
	@override String get comingSoonDescription => 'Vous pouvez utiliser votre bibliothèque dans Libby alors que nous finissons par le connecter.';
	@override String get suspendHold => 'Suspension de la main';
	@override String get resumeHold => 'Résumé Hold';
	@override String get suspendMessage => 'Garder votre place dans la file d’attente et laisser le lecteur suivant emprunter cet exemplaire ? Vous pourrez reprendre la réservation plus tard.';
	@override String get resumeMessage => 'Reprendre cette réservation pour que la bibliothèque puisse vous proposer le prochain exemplaire disponible ?';
	@override String get editEmail => 'Changer la notification par email';
}

// Path: audiobook
class Translations$audiobook$fr extends Translations$audiobook$en {
	Translations$audiobook$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Lire et écouter Sync';
	@override String get syncHelp => 'Gardez les positions de lecture, les positions d\'écoute, l\'état de finition, les notes et les notes sur vos appareils. Choisissez un compte de stockage attaché et utilisez le même code de synchronisation sur chaque appareil. La lecture et l\'écoute restent séparées.';
	@override String get addSyncSource => 'Ajouter Google Drive, OneDrive, Dropbox, WebDAV ou S3 dans les fichiers et les livres d’abord.';
	@override String get syncDestination => 'Sync compte de stockage';
	@override String get syncFolder => 'Synchronisation des fichiers ou préfix';
	@override String get syncFolderHelp => 'Utilisez un dossier existant séparé dans votre source WebDAV, ou un préfix S3 dédié.';
	@override String get syncCode => 'Code de sync privé';
	@override String get syncCodeHelp => 'Créez un code sur votre premier appareil, puis entrez ce code sur vos autres appareils. Gardez une copie privée: c\'est la clé de votre état chiffré. Utilisez un code différent pour chaque personne.';
	@override String get showCode => 'Afficher ou cacher le code sync';
	@override String get newSyncCode => 'Créer un nouveau code synchronisé';
	@override String get saveSync => 'Réserver et synchroniser';
	@override String get disableSync => 'Déconnecter la synchronisation sur ce dispositif';
	@override String get syncSourceDisconnect => 'En supprimant cette source, la lecture et l\'écoute de synchronisation sont désactivées ici. les fichiers de synchronisation cryptés restent dans le fournisseur.';
	@override String get syncReconnect => 'Récupérer le compte de stockage';
	@override String lastSynced({required Object time}) => 'Dernière synchronisation à ${time}';
	@override String get syncPrivacy => 'Seuls les progrès et les notes cryptés sont enregistrés. Les fichiers audio et ebook, les tokens de compte et les mots de passe ne sont pas téléchargés. Google Drive et OneDrive utilisent le stockage d\'applications; Dropbox utilise PlezyNG Sync. Autoriser la synchronisation peut demander un accès écrite supplémentaire. Pendant que la synchronisation est activée, cette destination possède la synchronisation du progrès; le progrès du serveur reste séparé.';
	@override String get syncConflicts => 'Choisissez où revenir';
	@override String get conflictHelp => 'Ces modifications ont été effectuées indépendamment. Choisissez la position ou la version de la note pour garder. Un timestamp ultérieur ou un pourcentage plus élevé ne gagne pas automatiquement.';
	@override String syncDevice({required Object device}) => 'Équipement ${device}';
	@override String get syncUnknownDevice => 'Un appareil inconnu';
	@override String get deletedBookmark => 'Bookmark supprimé';
	@override String get finished => 'terminé';
	@override String readingPosition({required Object percent}) => 'Lire · ${percent}%';
	@override String get chapterTimeline => 'Chapitre Progrès';
	@override String get bookTimeline => 'L\'ensemble du livre progrès';
	@override String bookRemaining({required Object time}) => 'Le temps restant dans ce livre: ${time}';
	@override String chapterRemaining({required Object time}) => 'Le temps restant dans ce chapitre: ${time}';
	@override String get unknownRemaining => 'Temps total disponible lorsque les parties sont jouées';
	@override String get undoSeek => 'La dernière recherche';
	@override String get customSpeed => 'La vitesse de jeu personnalisée';
	@override String get speedHelp => 'Choisissez une vitesse de 0,25× à 4×.';
	@override String get apply => 'Appliquer';
	@override String get customSleep => 'Temps de sommeil personnalisé';
	@override String get sleepMinutes => 'Démonstrations (1 à 1440)';
	@override String sleepChapters({required Object count}) => 'Arrêt après ${count} chapitres';
	@override String get extendSleep => 'Ajoutez 5 minutes';
	@override String sleepRemaining({required Object time}) => 'Temps de sommeil : ${time}';
	@override String get useDefaults => 'Utilisez ces contrôles d\'écoute pour de nouveaux livres';
	@override String get librarySort => 'Les livres sortants';
	@override String get sortTitle => 'Titre';
	@override String get sortAuthor => 'Auteur';
	@override String get sortNarrator => 'Narrateur';
	@override String get sortSeries => 'Commande série';
	@override String get sortRecent => 'récemment ouvert';
	@override String get statusFilter => 'Le statut de lecture';
	@override String get statusAll => 'Tous les livres';
	@override String get statusNew => 'Pas commencé';
	@override String get statusProgress => 'Au progrès';
	@override String get statusFinished => 'terminé';
	@override String get goToTime => 'Aller dans le temps';
	@override String get timeHelp => 'Hores : minutes : secondes ou minutes : secondes';
	@override String get recoveryHelp => 'Exporter une récente copie cryptée avant de déplacer ou de réparer les données synchronisées. Les importations se fusionnent avec l\'état actuel; elles ne remplacent jamais l\'historique locale de la syncation.';
	@override String get recoveryExport => 'Export de fichiers de récupération cryptés';
	@override String get recoveryImport => 'Importer des fichiers de récupération cryptés';
	@override String get recoveryImportConfirm => 'Mélanger ce fichier de récupération crypté avec les positions et notes de lecture actuelles? l\'historique existante sera conservée. la bibliothèque partagée et les identifiants d\'objets ne sont pas inclus; définir des identifiers correspondant sur chaque appareil avant d\'importer.';
	@override String get recoveryExported => 'Les fichiers de récupération cryptés sont sauvegardés.';
	@override String get recoveryImported => 'Les données de récupération sont fusionnées.';
}

// Path: sourceSetup
class Translations$sourceSetup$fr extends Translations$sourceSetup$en {
	Translations$sourceSetup$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Certificat du serveur enregistré';
	@override String get nfsEndpointInvalid => 'Saisissez une URL NFS, par exemple nfs://nas:2049/export.';
	@override String get dlnaNone => 'Aucun serveur DLNA trouvé. Saisissez manuellement l’URL de description de l’appareil.';
	@override String get dlnaServers => 'Serveurs multimédias DLNA';
	@override String get dlnaUnavailable => 'La découverte DLNA est indisponible sur ce réseau. Saisissez manuellement l’URL de description de l’appareil.';
	@override String get dlnaSearching => 'Recherche de serveurs DLNA sur le réseau local';
	@override String get networkSearching => 'Recherche sur le réseau local…';
	@override String get dlnaDiscover => 'Découvrir les serveurs DLNA';
	@override String get dlnaHelp => 'La découverte repose sur la multidiffusion du réseau local. Si aucun serveur n’apparaît, saisissez ci-dessus son URL de description de l’appareil.';
	@override String get dlnaRoot => 'Identifiant d’objet DLNA ; laissez vide pour utiliser la racine de l’appareil.';
	@override String get passwordOrKey => 'Saisissez un mot de passe ou ajoutez une clé privée ci-dessous.';
	@override String get sshFingerprint => 'Empreinte SHA256 de la clé d’hôte SSH';
	@override String get sshFingerprintHelp => 'Vérifiez-la auprès de l’administrateur du serveur. Sur le serveur, exécutez ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub et utilisez sa valeur SHA256.';
	@override String get sshFingerprintKeep => 'Laissez vide pour conserver l’empreinte actuellement épinglée, ou saisissez une nouvelle empreinte du serveur.';
	@override String get sshAuthentication => 'Authentification SSH par clé publique';
	@override String get sshAuthenticationHelp => 'Facultative ; l’authentification par mot de passe est également prise en charge.';
	@override String get privateKey => 'Clé privée (format PEM ou OpenSSH)';
	@override String get privateKeyPassphrase => 'Phrase secrète de la clé privée';
	@override String get nfsMountPort => 'Port TCP du service de montage NFS';
	@override String get nfsMountPortHelp => 'Par défaut : 20048';
	@override String get nfsUserId => 'Identifiant utilisateur NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Par défaut : 1000. Utilisez l’identifiant autorisé par le partage NFS du NAS.';
	@override String get nfsGroupId => 'Identifiant de groupe NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Par défaut : 1000. Utilisez l’identifiant de groupe autorisé par le partage NFS du NAS.';
	@override String get nfsEncryption => 'Exiger NFS chiffré (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Exiger TLS 1.3 pour NFS et le service de montage. Si le NAS ne le prend pas en charge, la connexion est refusée.';
	@override String get nfsTrustCertificate => 'CA NFS personnalisée ou certificat du serveur (PEM, facultatif)';
	@override String get nfsTrustHelp => 'Laissez vide pour utiliser les certificats reconnus par cet appareil. Si nécessaire, ajoutez un certificat d’une CA privée ou un certificat de serveur autosigné ; ses noms doivent correspondre à l’hôte de l’URL NFS.';
	@override String get nfsTrustInvalid => 'Utilisez un certificat de CA ou de serveur au format PEM. N’incluez pas de clé privée.';
	@override String get addTrustCertificate => 'Ajouter un certificat de confiance personnalisé';
	@override String get replaceTrustCertificate => 'Remplacer le certificat personnalisé enregistré';
	@override String get nfsTlsHelp => 'RPC-with-TLS utilise les ports habituels de NFS et du service de montage et exige la prise en charge de RFC 9289 par le NAS. TLS 1.3 est obligatoire. Le nom d’hôte ou l’adresse IP doit correspondre au certificat. Les UID/GID AUTH_SYS s’appliquent toujours dans le canal chiffré.';
	@override String get clientCertificate => 'Certificat client (facultatif)';
	@override String get clientCertificateHelp => 'Permet au NAS d’authentifier ce client ; les identifiants AUTH_SYS dépendent toujours des règles du partage NFS du NAS.';
	@override String get savedIdentity => 'Une identité client enregistrée sera utilisée.';
	@override String get replaceIdentity => 'Remplacer l’identité client enregistrée';
	@override String get chooseIdentity => 'Choisir une identité client PKCS#12';
	@override String get identityPassphrase => 'Phrase secrète de l’identité client';
	@override String get identityPassphraseHelp => 'Laissez vide si le fichier n’a pas de phrase secrète.';
	@override String get removeIdentity => 'Supprimer toute identité client enregistrée';
	@override String get identityStorageHelp => 'Les identités client sont enregistrées dans le coffre chiffré des identifiants de la source. Ne modifiez pas cette section pour conserver l’identité enregistrée.';
	@override String get nfsLimitations => 'NFSv3 en lecture seule sur TCP. Sans RPC-with-TLS, le trafic NFS n’est pas chiffré. Le NAS doit autoriser les identifiants AUTH_SYS choisis et les ports client non privilégiés (souvent via l’option d’export « insecure »). NFSv4 et UDP ne sont pas pris en charge.';
	@override String get nfsSetupHelp => 'Aide à la configuration NFS';
	@override String get nfsSetupHint => 'Vérifiez ces réglages si la connexion ne s’établit pas.';
	@override String get nfsSetupDetails => 'Utilisez un partage NFSv3 sur TCP. Si le chiffrement est exigé, le service NFS et le service de montage doivent tous deux prendre en charge RPC-with-TLS. Laissez le certificat personnalisé vide pour utiliser un certificat de serveur reconnu par cet appareil, ou ajoutez le certificat de CA ou autosigné du NAS. Le nom du certificat doit correspondre à l’hôte du point de connexion. Si le NAS exige TLS mutuel, ajoutez son identité client PKCS#12. Vérifiez enfin que le partage autorise les UID/GID AUTH_SYS configurés et les règles de ports du client.';
	@override String get ftpHelp => 'FTP utilise le mode passif. Utilisez ftp:// pour FTP sans chiffrement, ftpes:// pour TLS explicite, ou ftps:// pour TLS (implicite sur le port 990 ; explicite sur les autres ports).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Recherche facultative de sous-titres pour les vidéos indépendantes.';
	@override String get apiKey => 'Clé API';
	@override String get optionalUsername => 'Nom d’utilisateur du compte (facultatif)';
	@override String get optionalPassword => 'Mot de passe du compte (facultatif)';
	@override String get subtitlePrivacy => 'Obtenez une clé API sur opensubtitles.com. La recherche envoie le titre de la vidéo et les identifiants IMDb/TMDB disponibles, jamais le fichier vidéo. La clé et les identifiants facultatifs du compte sont chiffrés avec cette source.';
	@override String get automaticMetadata => 'Métadonnées vidéo automatiques en ligne';
	@override String get metadataPrivacy => 'Envoie uniquement le titre/l’année du nom de fichier et les numéros d’épisode, ou un identifiant NFO ; jamais les médias ni les identifiants de connexion. Les champs NFO restent prioritaires.';
	@override String get nfsEncryptionFailure => 'Pour NFS chiffré, vérifiez la prise en charge de RFC 9289 et TLS 1.3 par les deux services du NAS, le nom du certificat et les UID/GID du partage. PlezyNG ne réessaiera pas cette connexion sans chiffrement.';
	@override String get sourceConnecting => 'Connexion à la source';
	@override String get metadataSearchPrivacy => 'Cette recherche de titre est envoyée à Trakt. Seul le titre saisi est transmis, pas la vidéo ni les identifiants de connexion de la source.';
	@override String get chooseMatch => 'Choisir une correspondance';
	@override String get metadataMatchHelp => 'Vérifiez le titre et l’année avant de choisir. Trakt reçoit le titre recherché ; la vidéo reste sur sa source.';
	@override String get metadataNoMatches => 'Aucun titre correspondant trouvé en ligne. Essayez un autre titre.';
	@override String get metadataSearch => 'Rechercher des métadonnées en ligne';
	@override String get metadataLoading => 'Recherche en ligne d’informations sur les films et séries…';
	@override String get metadataFromTrakt => 'Métadonnées en ligne de Trakt';
	@override String get metadataNoAutomaticMatch => 'Aucune correspondance automatique trouvée pour le titre. Recherchez le titre pour choisir une correspondance.';
	@override String get metadataFailed => 'Impossible de charger les métadonnées en ligne. La lecture et les informations locales restent disponibles.';
	@override String get videoDetailsLoading => 'Chargement des détails de la vidéo';
	@override String get subtitleKeyRequired => 'Clé API OpenSubtitles requise';
	@override String get subtitleKeyHelp => 'Modifiez cette source de fichiers et ajoutez une clé API OpenSubtitles dans ses réglages facultatifs de sous-titres.';
	@override String get subtitleSearchFailed => 'La recherche de sous-titres a échoué. Vérifiez la clé API, la connexion et l’accès au service.';
	@override String get subtitleApplyFailed => 'Impossible de télécharger ou d’appliquer ces sous-titres. Vérifiez votre connexion et essayez un autre résultat.';
	@override String get subtitleSearch => 'Rechercher sur OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'La recherche utilise le titre et les identifiants IMDb/TMDB disponibles. Le fichier vidéo reste sur sa source. Avant de choisir, vérifiez la langue, les indicateurs de sous-titres forcés ou pour sourds et malentendants, ainsi que la note.';
	@override String get movieOrShow => 'Film ou série';
	@override String get subtitleTitleHint => 'Saisissez un titre pour affiner les résultats';
	@override String get subtitleLanguage => 'Langue des sous-titres';
	@override String get subtitleSearching => 'Recherche sur OpenSubtitles';
	@override String get subtitleNoMatches => 'Aucun sous-titre correspondant trouvé. Essayez un autre titre ou une autre langue.';
	@override String get downloadSubtitle => 'Télécharger les sous-titres';
	@override String get subtitle => 'Sous-titres';
	@override String get nfsTlsRequired => 'RPC-with-TLS obligatoire';
	@override String get nfsUnencrypted => 'NFS non chiffré';
	@override String get tlsEncrypted => 'Chiffré avec TLS';
	@override String get ftpPlain => 'FTP non chiffré';
	@override String get sshPinned => 'SSH chiffré · clé d’hôte épinglée';
	@override String get smbEncrypted => 'Chiffrement SMB3 activé';
	@override String get smbUnencrypted => 'Chiffrement SMB3 désactivé';
	@override String get httpUnencrypted => 'HTTP sans chiffrement du transport';
	@override String get checkEndpointSecurity => 'Vérifier la sécurité du point de connexion';
	@override String fieldRequired({required Object label}) => '${label} est obligatoire.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Saisissez ${label} entre ${min} et ${max}.';
	@override String replaceFile({required Object name}) => 'Remplacer ${name}';
	@override String selectedIdentity({required Object name}) => 'Identité client sélectionnée : ${name}';
	@override String subtitleRating({required Object rating}) => 'Note ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Téléchargement des sous-titres : ${title}';
	@override String get sharedEntryPair => 'Couvrir cet élément';
	@override String get sharedEntryPairHelp => 'Entrez le même ID pour cet élément sur chaque appareil. Utilisez un identifiant partagé stable ou générez un et copiez-le à l\'élément correspondant. Progress paires seulement lorsque les types de fichier édition, les tailles et la commande correspondent. Blank supprime cette cartographie.';
	@override String get sharedEntryId => 'Étiquette partagée ID';
	@override String get generateSharedEntryId => 'Gérer un élément partagé ID';
	@override String get sharedLibraryId => 'ID de la bibliothèque partagée (optionnelle)';
	@override String get sharedLibraryHelp => 'Utilisez le même ID sur les appareils qui ouvrent la même bibliothèque.Cette identifiant public aide à suivre les progrès de lecture et les notes dans différentes connexions source; il n\'est pas un mot de passe.Quand les fournisseurs utilisent différents identifiants d\'objets, couvrir ces éléments de leurs écrans détaillés.';
	@override String get sharedLibraryInvalid => 'Utilisez 8 à 100 lettres, chiffres, points, sous-cores ou hyphens.';
	@override String get generateSharedLibraryId => 'Gérer un ID de bibliothèque partagé';
	@override String get nfsReadAhead => 'Les demandes de NFS read-ahead';
	@override String get nfsReadAheadHelp => 'Plus de lectures parallèles peuvent améliorer la puissance sur un NAS ou réseau rapide. Utilisez 1 si le serveur limite les demandes concurrentes.';
	@override String get nfsReadTest => 'Mesure des performances NFS';
	@override String get nfsReadTestHelp => 'Il lit jusqu\'à 64 MiB du plus grand fichier pour mesurer cette connexion NAS. Ceci utilise la bande passante réseau.';
	@override String get nfsQualificationResult => 'NFS Lire la mesure';
	@override String get nfsReadBytes => 'Les données lisées';
	@override String get nfsReadSpeed => 'vitesse mesurée';
	@override String get nfsReadRequests => 'Lire les demandes';
	@override String get sharedEntryConflict => 'Cet identifiant d\'élément partagé est déjà associé à un autre élément dans cette bibliothèque.';
}

// Path: comics
class Translations$comics$fr extends Translations$comics$en {
	Translations$comics$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Ajuster à la hauteur';
	@override String get readingMode => 'Mode de lecture';
	@override String get paged => 'Pages';
	@override String get webtoon => 'Défilement continu';
	@override String get coverAlone => 'Afficher la couverture seule';
	@override String get splitWide => 'Diviser les pages larges';
	@override String get splitWideHelp => 'Affiche chaque moitié séparément, dans l’ordre de lecture. L’affichage de deux pages côte à côte est suspendu lorsque cette option est activée.';
	@override String get thumbnails => 'Miniatures des pages';
	@override String get controlsHelp => 'Balayez pour tourner les pages. Touchez deux fois pour modifier l’ajustement. En défilement continu, balayez verticalement ou utilisez Page précédente et Page suivante.';
	@override String get savedForComic => 'Les réglages d’affichage sont mémorisés pour cette BD dans ce profil.';
	@override String get readLists => 'Listes de lecture';
	@override String get collections => 'Collections';
}

// Path: games
class Translations$games$fr extends Translations$games$en {
	Translations$games$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

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
class Translations$deepLinks$fr extends Translations$deepLinks$en {
	Translations$deepLinks$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Ce lien Plezy n’est pas valide.';
	@override String profileNotFound({required Object profile}) => 'Aucun profil ne correspond à "${profile}".';
	@override String get serverUnavailable => 'Je n\'arrive pas au serveur pour ce lien.';
	@override String get notFound => 'Je ne pourrais pas trouver ce titre dans vos bibliothèques.';
	@override String get unsupportedItem => 'Ce lien ne peut pas être joué.';
	@override String get noLiveTv => 'Aucun serveur TV en direct n\'est disponible pour ce lien.';
	@override String channelNotFound({required Object channel}) => 'Je ne pouvais pas trouver le canal "${channel}".';
	@override String get showLink => 'Afficher le lien';
	@override String get showProfileLink => 'Afficher le profil';
	@override String get dialogTitle => 'Le lien';
	@override String get showHint => 'L’ouverture de ce lien lance l’épisode suivant. Ajoutez &mode=shuffle à la fin pour lire la série en mode aléatoire.';
	@override String get movieHint => 'Ouvrir ce lien joue le film.';
	@override String get episodeHint => 'Ouvrir ce lien joue cet épisode.';
	@override String get profileHint => 'L’ouverture de ce lien change vers ce profil.';
	@override String openAsProfile({required Object name}) => 'Ouverture en ${name}';
	@override String get copy => 'Copie';
	@override String get copied => 'Le lien copié';
}

// Path: appIcon.names
class Translations$appIcon$names$fr extends Translations$appIcon$names$en {
	Translations$appIcon$names$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Minuit';
	@override String get ember => 'Braise';
	@override String get paper => 'Papier';
	@override String get oled => 'OLED';
	@override String get line => 'Trait';
	@override String get ocean => 'Océan';
	@override String get ultraviolet => 'Ultraviolet';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Crépuscule';
	@override String get gold => 'Or';
	@override String get titanium => 'Titane';
	@override String get glass => 'Verre';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Pixel';
	@override String get neon => 'Néon';
	@override String get sticker => 'Autocollant';
	@override String get ticket => 'Ticket';
	@override String get pop => 'Pop';
	@override String get strata => 'Strates';
	@override String get facet => 'Facettes';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class Translations$common$ratingSource$fr extends Translations$common$ratingSource$en {
	Translations$common$ratingSource$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

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
class Translations$common$mediaKind$fr extends Translations$common$mediaKind$en {
	Translations$common$mediaKind$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Série';
	@override String get season => 'Saison';
	@override String get episode => 'Épisode';
	@override String get artist => 'Artiste';
	@override String get album => 'Album';
	@override String get track => 'Titre';
	@override String get collection => 'Collection';
	@override String get playlist => 'Playlist';
	@override String get clip => 'Clip';
	@override String get photo => 'Photo';
	@override String get folder => 'Dossier';
}

// Path: settings.startupSectionOptions
class Translations$settings$startupSectionOptions$fr extends Translations$settings$startupSectionOptions$en {
	Translations$settings$startupSectionOptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Des recommandations ouvertes et des articles provenant de sources de découverte connectées.';
	@override String get libraries => 'Ouvrez vos bibliothèques de médias connectés.';
	@override String get liveTv => 'Ouvrez la télévision en direct lorsque un serveur la fournit; sinon le start-up tombe de retour à Home.';
	@override String get search => 'Recherche de médias ouverts.';
}

// Path: themeEditor.slots
class Translations$themeEditor$slots$fr extends Translations$themeEditor$slots$en {
	Translations$themeEditor$slots$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Arrière-plan';
	@override String get surface => 'Surface';
	@override String get outline => 'Contour';
	@override String get text => 'Texte';
	@override String get textMuted => 'Texte secondaire';
	@override String get accent => 'Accent';
}

// Path: themeEditor.contrast
class Translations$themeEditor$contrast$fr extends Translations$themeEditor$contrast$en {
	Translations$themeEditor$contrast$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Texte sur l’arrière-plan';
	@override String get textOnSurface => 'Texte sur la surface';
	@override String get textMutedOnBg => 'Texte secondaire sur l’arrière-plan';
	@override String get textMutedOnSurface => 'Texte secondaire sur la surface';
	@override String get accentOnBg => 'Accent sur l’arrière-plan';
	@override String get accentOnSurface => 'Accent sur la surface';
	@override String get labelOnAccent => 'Libellé de bouton sur l’accent';
}

// Path: hotkeys.actions
class Translations$hotkeys$actions$fr extends Translations$hotkeys$actions$en {
	Translations$hotkeys$actions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Lecture/Pause';
	@override String get volumeUp => 'Augmenter le volume';
	@override String get volumeDown => 'Baisser le volume';
	@override String seekForward({required Object seconds}) => 'Avancer (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Reculer (${seconds}s)';
	@override String get fullscreenToggle => 'Basculer en mode plein écran';
	@override String get muteToggle => 'Activer/désactiver le mode silencieux';
	@override String get subtitleToggle => 'Activer/désactiver les sous-titres';
	@override String get audioTrackNext => 'Piste audio suivante';
	@override String get subtitleTrackNext => 'Piste de sous-titres suivante';
	@override String get chapterNext => 'Chapitre suivant';
	@override String get chapterPrevious => 'Chapitre précédent';
	@override String get episodeNext => 'Épisode suivant';
	@override String get episodePrevious => 'Épisode précédent';
	@override String get speedIncrease => 'Augmenter la vitesse';
	@override String get speedDecrease => 'Réduire la vitesse';
	@override String get speedReset => 'Réinitialiser la vitesse';
	@override String get zoomIn => 'Zoom avant';
	@override String get zoomOut => 'Zoom arrière';
	@override String get zoomReset => 'Réinitialiser le zoom';
	@override String get subSeekNext => 'Rechercher le sous-titre suivant';
	@override String get subSeekPrev => 'Rechercher le sous-titre précédent';
	@override String get subtitleDelayIncrease => 'Retarder les sous-titres';
	@override String get subtitleDelayDecrease => 'Avancer les sous-titres';
	@override String get shaderToggle => 'Activer/désactiver les shaders';
	@override String get skipMarker => 'Passer l\'intro/le générique';
	@override String get screenshot => 'Prendre une capture d\'écran';
	@override String get framePrevious => 'Précédent Frame';
	@override String get frameNext => 'Le prochain cadre';
}

// Path: videoControls.pipErrors
class Translations$videoControls$pipErrors$fr extends Translations$videoControls$pipErrors$en {
	Translations$videoControls$pipErrors$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Nécessite Android 8.0 ou plus récent';
	@override String get iosVersion => 'Nécessite iOS 15.0 ou plus récent';
	@override String get permissionDisabled => 'Le mode image dans l’image est désactivé. Activez-le dans les paramètres système.';
	@override String get notSupported => 'Cet appareil ne prend pas en charge le mode image dans l\'image';
	@override String get voSwitchFailed => 'Échec du changement de sortie vidéo pour l\'image dans l\'image';
	@override String get failed => 'Échec du démarrage du mode image dans l\'image';
	@override String get prepareFailed => 'Impossible de préparer le mode image dans l\'image';
	@override String unknown({required Object error}) => 'Une erreur s\'est produite : ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class Translations$subtitlingStyling$assOverrideOptions$fr extends Translations$subtitlingStyling$assOverrideOptions$en {
	Translations$subtitlingStyling$assOverrideOptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get no => 'Gardez les lettres, couleurs, tailles et placement écrit dans le fichier sous-titre.';
	@override String get yes => 'Permettez aux paramètres de style du sous-titre du joueur d\'ajuster les sous-tits ASS.';
	@override String get scale => 'Appliquez le style de joueur et l\'échelle des tailles intégrées pour correspondre aux dimensions vidéo.';
	@override String get force => 'Remplacer les styles ASS intégrés avec le style sous-titre du joueur.';
	@override String get strip => 'Supprimer le format ASS intégré et rendre clairement le texte sous-titre.';
}

// Path: subtitlingStyling.renderResolutionOptions
class Translations$subtitlingStyling$renderResolutionOptions$fr extends Translations$subtitlingStyling$renderResolutionOptions$en {
	Translations$subtitlingStyling$renderResolutionOptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render à la résolution de surface d\'affichage complète pour le résultat le plus épais.';
	@override String get video => 'Render en utilisant la résolution vidéo comme référence, ce qui peut réduire le travail sur les écrans à haute résolution.';
	@override String get threeQuarter => 'Render à 75% de la résolution de surface d\'écran pour une économie modeste des performances.';
	@override String get half => 'Render à 50% de la résolution de surface d\'affichage pour réduire le travail, avec des bords plus doux.';
	@override String get third => 'Render à un tiers de la résolution de surface d\'affichage pour réduire le travail, avec des bords plus doux.';
	@override String get quarter => 'Render à un quart de la résolution de surface d\'affichage pour réduire le travail, avec le résultat le plus doux.';
}

// Path: accountPreferences.groups
class Translations$accountPreferences$groups$fr extends Translations$accountPreferences$groups$en {
	Translations$accountPreferences$groups$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio et sous-titres';
	@override String get libraryDisplay => 'Bibliothèque';
	@override String get personalMedia => 'Médias personnels';
}

// Path: accountPreferences.subtitleModes
class Translations$accountPreferences$subtitleModes$fr extends Translations$accountPreferences$subtitleModes$en {
	Translations$accountPreferences$subtitleModes$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Sélection manuelle';
	@override String get noneDescription => 'Ne jamais activer les sous-titres automatiquement.';
	@override String get defaultMode => 'Suivre les indicateurs des pistes';
	@override String get defaultModeDescription => 'Utiliser les indicateurs par défaut et forcés enregistrés sur chaque piste de sous-titres.';
	@override String get always => 'Toujours activé';
	@override String get alwaysDescription => 'Activer une piste de sous-titres dans la langue préférée lorsqu\'elle existe.';
	@override String get onlyForced => 'Sous-titres forcés uniquement';
	@override String get onlyForcedDescription => 'Charger uniquement les pistes marquées comme forcées.';
	@override String get smart => 'Avec l\'audio en langue étrangère';
	@override String get smartDescription => 'Activer les sous-titres uniquement lorsque l\'audio est dans une autre langue.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class Translations$accountPreferences$subtitleAccessibilityOptions$fr extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	Translations$accountPreferences$subtitleAccessibilityOptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Préférer les sous-titres non SDH';
	@override String get preferSdh => 'Préférer les sous-titres SDH';
	@override String get onlySdh => 'Sous-titres SDH uniquement';
	@override String get onlyNonSdh => 'Sous-titres non SDH uniquement';
	@override String get preferNonSdhDescription => 'Préférez les sous-titres standard lorsque les versions standard et SDH sont disponibles.';
	@override String get preferSdhDescription => 'Je préfère les sous-titres SDH quand ils sont disponibles, mais permettent des sous-tits standard en tant que fallback.';
	@override String get onlySdhDescription => 'Utilisez uniquement les sous-titres SDH ; ne retournez pas aux sous-tits standard.';
	@override String get onlyNonSdhDescription => 'Utilisez uniquement les sous-titres standard ; excluez les sous‐titres SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class Translations$accountPreferences$forcedSubtitleOptions$fr extends Translations$accountPreferences$forcedSubtitleOptions$en {
	Translations$accountPreferences$forcedSubtitleOptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Préférer les sous-titres non forcés';
	@override String get preferForced => 'Préférer les sous-titres forcés';
	@override String get onlyForced => 'Sous-titres forcés uniquement';
	@override String get onlyNonForced => 'Sous-titres non forcés uniquement';
	@override String get preferNonForcedDescription => 'Il préfère les sous-titres réguliers, mais permet des traces forcées comme une baisse.';
	@override String get preferForcedDescription => 'Préférez les traces forcées lorsqu’elles sont disponibles, mais permettez des sous-titres réguliers en tant que recul.';
	@override String get onlyForcedDescription => 'Utilisez uniquement les traces marquées comme forcées.';
	@override String get onlyNonForcedDescription => 'Éliminer les traces marquées comme forcées.';
}

// Path: accountPreferences.watchedIndicatorOptions
class Translations$accountPreferences$watchedIndicatorOptions$fr extends Translations$accountPreferences$watchedIndicatorOptions$en {
	Translations$accountPreferences$watchedIndicatorOptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Jamais';
	@override String get moviesAndShows => 'Films et séries TV';
	@override String get movies => 'Films uniquement';
	@override String get shows => 'Séries TV uniquement';
	@override String get noneDescription => 'N’affichez pas les signes de contrôle observés.';
	@override String get moviesAndShowsDescription => 'Afficher les marques de vérification pour les films et les émissions télévisées.';
	@override String get moviesDescription => 'Afficher les marques d\'attente pour les films uniquement.';
	@override String get showsDescription => 'Afficher les marques de vérification pour les émissions télévisées uniquement.';
}

// Path: accountPreferences.mediaReviewsOptions
class Translations$accountPreferences$mediaReviewsOptions$fr extends Translations$accountPreferences$mediaReviewsOptions$en {
	Translations$accountPreferences$mediaReviewsOptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Utilisateurs et critiques';
	@override String get usersOnly => 'Utilisateurs uniquement';
	@override String get criticsOnly => 'Critiques uniquement';
	@override String get nobody => 'Masquées';
	@override String get usersAndCriticsDescription => 'Afficher les notations des utilisateurs et les notes critiques.';
	@override String get usersOnlyDescription => 'Afficher les évaluations et les avis présentés par les utilisateurs.';
	@override String get criticsOnlyDescription => 'Afficher les évaluations critiques et les avis.';
	@override String get nobodyDescription => 'Cache les notes et les critiques.';
}

// Path: discover.findNext
class Translations$discover$findNext$fr extends Translations$discover$findNext$en {
	Translations$discover$findNext$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Votre prochaine découverte';
	@override String get open => 'Votre prochaine découverte';
	@override String get anyTime => 'Sans limite de temps';
	@override String get timeAvailable => 'De combien de temps disposez-vous ?';
	@override String get filters => 'Choisissez selon le moment';
	@override String get watch => 'Regarder';
	@override String get listen => 'Écouter';
	@override String get read => 'Lire';
	@override String finishable({required Object duration}) => 'Vous pouvez finir en ${duration}';
	@override String aboutDuration({required Object duration}) => 'Environ ${duration}';
	@override String nextUnit({required Object duration}) => 'Chapitre suivant · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} au total';
	@override String get timingVaries => 'La durée peut varier';
	@override String get notNow => 'Pas maintenant';
	@override String get swipeHint => 'Faites glisser la couverture vers une flèche ou utilisez les boutons ci-dessous.';
	@override String get saved => 'Suggestions enregistrées';
	@override String savedCount({required Object count}) => 'Suggestions enregistrées · ${count}';
	@override String get undo => 'Annuler';
	@override String get details => 'Détails';
	@override String get noPicks => 'Rien à choisir pour le moment';
	@override String get noPicksHint => 'Connectez une bibliothèque ou ajoutez une source de médias pour commencer.';
	@override String get noMatches => 'Rien ne convient pour le moment';
	@override String get noMatchesHint => 'Essayez un autre type de contenu ou accordez-vous plus de temps.';
	@override String get allDone => 'Vous avez vu toutes les suggestions';
	@override String get allDoneHint => 'Lancez une nouvelle sélection pour revoir ces suggestions.';
	@override String get refresh => 'Trouver une autre sélection';
	@override String sourceReason({required Object source}) => 'Depuis ${source}';
	@override String libraryReason({required Object library}) => 'Depuis ${library}';
	@override String get ownedReason => 'Dans votre bibliothèque';
	@override String get liveNow => 'En cours de diffusion';
	@override String get watchLive => 'Regarder en direct';
	@override String get filterAnything => 'Tous les types';
	@override String get filterWatch => 'Regarder';
	@override String get filterListen => 'Écouter';
	@override String get filterRead => 'Lire';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Appliquer';
	@override String get openFailed => 'Ce choix n’est plus disponible. Actualisez pour vérifier à nouveau.';
	@override String get changeFailed => 'Impossible d’enregistrer ce changement. Réessayez.';
	@override String get savedLimit => 'La liste des suggestions enregistrées est pleine. Retirez une suggestion pour en enregistrer une autre.';
	@override String get chooseHint => 'Ouvrez un titre, gardez-le pour plus tard ou passez au suivant.';
	@override String get howItWorks => 'Comment ça marche';
	@override String get notNowHelp => 'Passez ce titre pour le moment. Il reste dans votre bibliothèque.';
	@override String get saveHelp => 'Gardez-le dans les sélections enregistrées de ce profil sur cet appareil. Cela ne le télécharge pas.';
	@override String get openHelp => 'Sélectionnez la couverture pour afficher les détails. Utilisez l’action principale pour lancer, lire ou ouvrir le titre.';
	@override String get controlsHelp => 'Clavier ou télécommande : sélectionnez un bouton, puis appuyez sur Entrée ou Sélectionner. Annuler rétablit votre dernier choix.';
	@override String get artworkLoading => 'Chargement de l’illustration…';
	@override String get artworkUnavailable => 'Illustration indisponible';
	@override String get savedFeedback => 'Ajouté aux sélections enregistrées';
	@override String get skippedFeedback => 'Ignoré pour le moment';
	@override String get releaseToConfirm => 'Relâchez pour confirmer';
	@override String get remoteHint => 'Couverture sélectionnée : ← / → choisir · Sélectionner : détails · ↑ / ↓ : déplacer la sélection';
}

// Path: discover.person
class Translations$discover$person$fr extends Translations$discover$person$en {
	Translations$discover$person$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get born => 'Naissance';
	@override String get died => 'Décès';
	@override String get birthplace => 'Lieu de naissance';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} ans)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (à ${age} ans)';
}

// Path: libraries.tabs
class Translations$libraries$tabs$fr extends Translations$libraries$tabs$en {
	Translations$libraries$tabs$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recommandé';
	@override String get browse => 'Parcourir';
	@override String get collections => 'Collections';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class Translations$libraries$groupings$fr extends Translations$libraries$groupings$en {
	Translations$libraries$groupings$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Regroupement';
	@override String get all => 'Tous';
	@override String get movies => 'Films';
	@override String get shows => 'Séries TV';
	@override String get seasons => 'Saisons';
	@override String get episodes => 'Épisodes';
	@override String get artists => 'Artistes';
	@override String get albums => 'Albums';
	@override String get tracks => 'Titres';
	@override String get folders => 'Dossiers';
}

// Path: libraries.filterCategories
class Translations$libraries$filterCategories$fr extends Translations$libraries$filterCategories$en {
	Translations$libraries$filterCategories$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Genre';
	@override String get year => 'Année';
	@override String get contentRating => 'Classification';
	@override String get tag => 'Étiquette';
	@override String get unwatched => 'Non vus';
	@override String get unplayed => 'Non lus';
	@override String get favorites => 'Favoris';
	@override String get filePath => 'Chemin du fichier';
}

// Path: libraries.sortLabels
class Translations$libraries$sortLabels$fr extends Translations$libraries$sortLabels$en {
	Translations$libraries$sortLabels$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get dateAdded => 'Date d\'ajout';
	@override String get releaseDate => 'Date de sortie';
	@override String get rating => 'Note';
	@override String get communityRating => 'Note communautaire';
	@override String get criticRating => 'Note critique';
	@override String get userRating => 'Note utilisateur';
	@override String get datePlayed => 'Date de lecture';
	@override String get playCount => 'Lectures';
	@override String get productionYear => 'Année de production';
	@override String get runtime => 'Durée';
	@override String get officialRating => 'Classification officielle';
	@override String get premiereDate => 'Date de première';
	@override String get startDate => 'Date de début';
	@override String get airTime => 'Heure de diffusion';
	@override String get studio => 'Studio';
	@override String get random => 'Aléatoire';
	@override String get dateShared => 'Date de partage';
	@override String get latestEpisodeAirDate => 'Dernière date de diffusion';
	@override String get lastEpisodeDateAdded => 'Date d\'ajout du dernier épisode';
	@override String get dateDownloaded => 'Date de téléchargement';
	@override String get size => 'Taille';
	@override String get library => 'Bibliothèque';
}

// Path: libraries.advancedFilters
class Translations$libraries$advancedFilters$fr extends Translations$libraries$advancedFilters$en {
	Translations$libraries$advancedFilters$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get include => 'Inclure';
	@override String get exclude => 'Exclure';
	@override String get any => 'Indifférent';
	@override String get yes => 'Oui';
	@override String get no => 'Non';
	@override String not({required Object value}) => 'Sauf ${value}';
	@override String valueCount({required Object count}) => '${count} sélectionné(s)';
	@override String valueCountExcluded({required Object count}) => '${count} exclu(s)';
	@override String get searchValues => 'Rechercher des valeurs';
	@override String get noValues => 'Aucune valeur';
	@override String get matchContains => 'Contient';
	@override String get matchNotContains => 'Ne contient pas';
	@override String get matchIs => 'Est';
	@override String get matchIsNot => 'N’est pas';
	@override String get matchBeginsWith => 'Commence par';
	@override String get matchEndsWith => 'Se termine par';
	@override String get textHint => 'Saisissez un texte';
	@override String get from => 'De';
	@override String get to => 'À';
	@override String range({required Object from, required Object to}) => '${from} à ${to}';
	@override String atLeast({required Object value}) => '${value} et plus';
	@override String atMost({required Object value}) => 'Jusqu’à ${value}';
	@override String dateLastDays({required Object count}) => '${count} derniers jours';
	@override String get dateLastYear => '12 derniers mois';
	@override String dateOlderThanDays({required Object count}) => 'Il y a plus de ${count} jours';
	@override String get dateOlderThanYear => 'Il y a plus d’un an';
}

// Path: libraries.selection
class Translations$libraries$selection$fr extends Translations$libraries$selection$en {
	Translations$libraries$selection$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Choisir les articles';
	@override String selectedCount({required Object count}) => '${count} sélectionné(s)';
	@override String get actions => 'Actions de sélection';
	@override String get confirmDescendants => 'Cela change tous les épisodes dans les spectacles et les saisons sélectionnés.';
	@override String get confirmUnwatched => 'Cela efface aussi la progression de lecture des éléments sélectionnés.';
	@override String confirmCount({required Object count}) => 'Les articles sélectionnés : ${count}.';
	@override String completed({required Object count}) => 'Les articles mis à jour : ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Mise à jour ${succeeded}; échoué ${failed}. les articles échoués restent sélectionnés.';
}

// Path: explore.mdblistShelves
class Translations$explore$mdblistShelves$fr extends Translations$explore$mdblistShelves$en {
	Translations$explore$mdblistShelves$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Gestion des plaques d\'exploration';
	@override String get manageDescription => 'Choisissez et arrêtez des listes de votre compte MDBList';
	@override String get description => 'Choisissez les listes de films et de télévision publiques de votre compte MDBList. Créez ou copiez les listes sur MDBList, puis refroîtez.';
	@override String get selected => 'Les plaques sélectionnées';
	@override String get available => 'Liste des comptes disponibles';
	@override String get noLists => 'Aucune liste de films ou de télévision publique n\'est retournée. Créez ou copiez une liste sur MDBList, puis refaire.';
	@override String get displayName => 'Nom de l\'affichage Shelf';
	@override String get nameHint => 'Laissez blanche pour utiliser le nom de la liste source.';
	@override String get add => 'Ajouter le shelf';
	@override String get save => 'Sauver les chariots';
	@override String moveUp({required Object title}) => 'Mouvement ${title} en haut';
	@override String moveDown({required Object title}) => 'Mouvement ${title} en bas';
	@override String get unavailable => 'Cette liste n\'est pas disponible. Retire ou supprimer son fil dans les paramètres.';
	@override String get rateLimited => 'MDBList limite de demande atteint. veuillez retirer plus tard.';
	@override String get loadFailed => 'Vous ne pouvez pas charger les plaques. vérifier votre connexion et retire.';
	@override String get saveFailed => 'Je ne peux pas faire des étagères, veuillez vous retirer.';
	@override String get accountChanged => 'Le compte ou le profil a changé. réouverture de ces paramètres.';
	@override String get settingsUnreadable => 'Les panneaux sauvés ne peuvent pas être lues. Sélectionnez vos listes à nouveau pour remplacer ces paramètres.';
}

// Path: explore.rows
class Translations$explore$rows$fr extends Translations$explore$rows$en {
	Translations$explore$rows$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Liste de suivi';
	@override String get recommendedMovies => 'Films recommandés';
	@override String get recommendedShows => 'Séries recommandées';
	@override String get trendingMovies => 'Films tendance';
	@override String get trendingShows => 'Séries tendance';
	@override String get popularMovies => 'Films populaires';
	@override String get popularShows => 'Séries populaires';
	@override String get trendingAnime => 'Animes tendance';
	@override String get suggestedAnime => 'Animes suggérés';
	@override String get airingAnime => 'Meilleurs animes en diffusion';
	@override String get popularAnime => 'Animes les plus populaires';
	@override String get trending => 'Tendances';
	@override String get upcomingMovies => 'Films à venir';
	@override String get upcomingShows => 'Séries à venir';
}

// Path: explore.status
class Translations$explore$status$fr extends Translations$explore$status$en {
	Translations$explore$status$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get airing => 'En cours';
	@override String get ended => 'Terminé';
	@override String get canceled => 'Annulé';
	@override String get upcoming => 'À venir';
}

// Path: explore.badge
class Translations$explore$badge$fr extends Translations$explore$badge$en {
	Translations$explore$badge$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} populaire';
	@override String rankAiring({required Object n}) => '#${n} en diffusion';
	@override String rankRated({required Object n}) => '#${n} mieux noté';
	@override String rankTrending({required Object n}) => '#${n} tendance';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} de ${season}';
	@override String watchingNow({required Object n}) => '${n} regardent';
	@override String get available => 'Disponible';
	@override String get partiallyAvailable => 'Partiellement disponible';
	@override String get availableIn4k => '4K disponible';
	@override String get requested => 'Demandé';
	@override String get pendingApproval => 'En attente d\'approbation';
	@override String get processing => 'En cours de traitement';
	@override String get declined => 'Refusé';
	@override String get requestFailed => 'Échec de la demande';
	@override String get requested4k => '4K demandé';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} saisons';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ép ${episode} dans ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Prochain dans ${duration}';
	@override String episodesShort({required Object n}) => '${n} ép';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ép';
	@override String get adult => '18+';
}

// Path: explore.stats
class Translations$explore$stats$fr extends Translations$explore$stats$en {
	Translations$explore$stats$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} répertoriés';
	@override String viewersDay({required Object n}) => '${n} vus aujourd\'hui';
	@override String viewersWeek({required Object n}) => '${n} vus cette semaine';
	@override String viewersMonth({required Object n}) => '${n} vus ce mois-ci';
	@override String viewersYear({required Object n}) => '${n} vus cette année';
	@override String viewersAllTime({required Object n}) => '${n} spectateurs';
	@override String planning({required Object n}) => '${n} prévoient de le regarder';
	@override String favorited({required Object n}) => '${n} favoris';
	@override String dropRate({required Object percent}) => '${percent} l\'ont abandonné';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commentaire',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commentaires',
	);
	@override String votes({required Object n}) => '${n} votes';
	@override String watching({required Object n}) => '${n} le regardent';
	@override String completed({required Object n}) => '${n} l\'ont terminé';
	@override String onHold({required Object n}) => '${n} en pause';
	@override String dropped({required Object n}) => '${n} ont abandonné';
}

// Path: explore.season
class Translations$explore$season$fr extends Translations$explore$season$en {
	Translations$explore$season$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Hiver';
	@override String get spring => 'Printemps';
	@override String get summer => 'Été';
	@override String get fall => 'Automne';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class Translations$explore$format$fr extends Translations$explore$format$en {
	Translations$explore$format$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'Court TV';
	@override String get movie => 'Film';
	@override String get special => 'Spécial';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Musique';
	@override String get other => 'Autre';
}

// Path: explore.sourceMaterial
class Translations$explore$sourceMaterial$fr extends Translations$explore$sourceMaterial$en {
	Translations$explore$sourceMaterial$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get original => 'Original';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Roman';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Jeu';
	@override String get webComic => 'Webcomic';
	@override String get musicRelease => 'Musique';
	@override String get otherMedia => 'Autre';
}

// Path: explore.creditRole
class Translations$explore$creditRole$fr extends Translations$explore$creditRole$en {
	Translations$explore$creditRole$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Acteur';
	@override String get director => 'Réalisateur';
	@override String get writer => 'Scénariste';
	@override String get producer => 'Producteur';
	@override String get creator => 'Créateur';
	@override String get composer => 'Compositeur';
}

// Path: explore.relation
class Translations$explore$relation$fr extends Translations$explore$relation$en {
	Translations$explore$relation$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Préquelle';
	@override String get sequel => 'Suite';
	@override String get sideStory => 'Histoire parallèle';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Version alternative';
	@override String get summary => 'Résumé';
	@override String get parentStory => 'Histoire principale';
	@override String get adaptation => 'Adaptation';
	@override String get other => 'Lié';
}

// Path: explore.detail
class Translations$explore$detail$fr extends Translations$explore$detail$en {
	Translations$explore$detail$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Titre original';
	@override String get alsoKnownAs => 'Également connu sous';
	@override String get studios => 'Studios';
	@override String get country => 'Pays';
	@override String get language => 'Langue';
	@override String get released => 'Sorti';
	@override String get physicalRelease => 'En disque';
	@override String get ended => 'Terminé';
	@override String addedOn({required Object date}) => 'Ajouté le ${date}';
	@override String get yourRating => 'Votre note';
	@override String get budget => 'Budget';
	@override String get revenue => 'Box-office';
	@override String get contentAdvisory => 'Recommandation d\'âge';
	@override String get tags => 'Étiquettes';
	@override String get revealSpoilerTags => 'Afficher les tags spoiler';
	@override String get links => 'Liens';
	@override String get watchOn => 'Regarder sur';
	@override String get watchTrailer => 'Regarder la bande-annonce';
	@override String openOn({required Object site}) => 'Ouvrir sur ${site}';
	@override String get crew => 'Équipe';
	@override String get ratings => 'Notes';
	@override String get schedule => 'Programme';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Recommandé par ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utilisateur',
		other: 'Recommandé par ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utilisateurs',
	);
	@override String recommendedBy({required Object who}) => 'Recommandé par ${who}';
	@override String favoritedBy({required Object who}) => 'Ajouté aux favoris par ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} pas encore diffusés';
	@override String recommendedByPercent({required Object percent}) => 'Recommandé par ${percent} des spectateurs';
	@override String get relatedTitles => 'Titres liés';
	@override String get background => 'Contexte';
}

// Path: liveTv.recordSettings
class Translations$liveTv$recordSettings$fr extends Translations$liveTv$recordSettings$en {
	Translations$liveTv$recordSettings$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Démarrer en avance (secondes)';
	@override String get endLate => 'Terminer en retard (secondes)';
	@override String get newOnly => 'Uniquement les nouveaux épisodes';
	@override String get anyChannel => 'Enregistrer sur n’importe quelle chaîne';
	@override String get anyTime => 'Enregistrer à n’importe quelle heure';
	@override String get skipInLibrary => 'Ignorer les épisodes déjà présents dans la bibliothèque';
	@override String get keepUpTo => 'Épisodes à conserver';
	@override String get keepUpToHint => '0 conserve tous les épisodes';
}

// Path: music.discography
class Translations$music$discography$fr extends Translations$music$discography$en {
	Translations$music$discography$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles et EP';
	@override String get live => 'Live';
	@override String get compilations => 'Compilations';
}

// Path: watchTogether.notices
class Translations$watchTogether$notices$fr extends Translations$watchTogether$notices$en {
	Translations$watchTogether$notices$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} a lancé la lecture';
	@override String get playbackStarted => 'Lecture lancée';
	@override String paused({required Object name}) => '${name} a mis en pause';
	@override String get playbackPaused => 'Lecture en pause';
	@override String jumpedTo({required Object name, required Object position}) => '${name} a sauté à ${position}';
	@override String roomJumpedTo({required Object position}) => 'Passage à ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} a réglé la vitesse sur ${speed}';
	@override String speedChanged({required Object speed}) => 'Vitesse réglée sur ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} a lancé ${title}';
	@override String mediaStarted({required Object title}) => 'Lecture en cours : ${title}';
	@override String stoppedMedia({required Object name}) => '${name} a arrêté la vidéo';
	@override String get mediaStopped => 'La vidéo s’est arrêtée';
	@override String waitingFor({required Object name}) => 'En attente de ${name}...';
	@override String get waitingForSomeone => 'En attente d’un participant en retard...';
	@override String get finished => 'Terminé';
	@override String hostChangedTo({required Object name}) => '${name} est maintenant l’hôte';
	@override String get youAreNowHost => 'Vous êtes maintenant l’hôte';
	@override String joined({required Object name}) => '${name} a rejoint';
	@override String left({required Object name}) => '${name} est parti';
	@override String get controlRefused => 'Seul l’hôte peut contrôler la lecture';
	@override String get searchFailed => 'Impossible de rechercher la vidéo du salon sur certains serveurs';
	@override String get playBlocked => 'Appuyez sur Lecture pour commencer';
	@override String get shareFailed => 'Impossible de partager cette vidéo avec le salon';
	@override String get downloadNotShared => 'Les téléchargements ne sont pas partagés avec le salon tant que leur serveur est hors ligne';
	@override String get openFailed => 'Impossible d’ouvrir la vidéo du salon';
}

// Path: watchTogether.ended
class Translations$watchTogether$ended$fr extends Translations$watchTogether$ended$en {
	Translations$watchTogether$ended$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get ended => 'L’hôte a fermé le salon';
	@override String get kicked => 'Vous avez été retiré du salon';
	@override String get expired => 'Le salon a expiré';
	@override String get replaced => 'Vous avez rejoint ce salon sur un autre appareil';
	@override String get lost => 'Connexion au salon perdue';
}

// Path: watchTogether.errors
class Translations$watchTogether$errors$fr extends Translations$watchTogether$errors$en {
	Translations$watchTogether$errors$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Ce n’est pas un code de salon. Les codes comportent 6 lettres et chiffres, sans 0, 1, I, L ni O.';
	@override String get roomNotFound => 'Aucun salon ne correspond à ce code. Il a peut-être été fermé.';
	@override String get roomFull => 'Ce salon est complet.';
	@override String get roomLocked => 'L’hôte a verrouillé ce salon.';
	@override String get relayFull => 'Le service Regarder ensemble est saturé pour le moment. Réessayez plus tard.';
	@override String get unreachable => 'Impossible de joindre le relais Regarder ensemble. Vérifiez votre connexion.';
	@override String get rateLimited => 'Trop de tentatives. Patientez un instant, puis réessayez.';
	@override String get clientBlocked => 'Cette version de PlezyNG ne peut pas utiliser le relais. Mettez l’application à jour.';
	@override String get forbidden => 'Seul l’hôte peut faire cela.';
	@override String get notInRoom => 'Vous n’êtes pas dans un salon.';
	@override String get alreadyInRoom => 'Vous êtes déjà dans un salon.';
	@override String get resumeFailed => 'Impossible de rejoindre à nouveau le salon.';
	@override String get unsupported => 'Le relais ne prend pas en charge cette fonction.';
	@override String get generic => 'Une erreur s’est produite. Réessayez.';
}

// Path: downloads.backgroundWarning
class Translations$downloads$backgroundWarning$fr extends Translations$downloads$backgroundWarning$en {
	Translations$downloads$backgroundWarning$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Les téléchargements s’arrêteront lorsque vous quitterez l’application';
	@override String get bannerDegraded => 'Les téléchargements en arrière-plan peuvent être limités';
	@override String get bannerAction => 'Détails';
	@override String get sheetTitle => 'Les téléchargements en arrière-plan sont bloqués';
	@override String get sheetTitleDegraded => 'Les téléchargements en arrière-plan peuvent être limités';
	@override String get sheetIntro => 'Android empêche PlezyNG de télécharger de façon fiable en arrière-plan.';
	@override String get sheetIntroDegraded => 'Votre appareil limite les moments où PlezyNG peut télécharger en arrière-plan.';
	@override String get reasonBackgroundRestricted => 'L’utilisation de PlezyNG en arrière-plan est restreinte. Dans les paramètres de batterie ou d’utilisation en arrière-plan, sélectionnez « Sans restriction ».';
	@override String get reasonStandbyRestricted => 'Android a placé PlezyNG en veille restreinte. Réglez l’utilisation de la batterie sur « Sans restriction ».';
	@override String get reasonDownloadChannelBlocked => 'Les notifications de téléchargement sont désactivées. La progression et les commandes peuvent donc être indisponibles.';
	@override String get reasonNotificationsDisabled => 'Les notifications sont désactivées. Sur Android 13 ou version ultérieure, elles sont nécessaires pour les longs téléchargements en arrière-plan.';
	@override String get reasonDataSaver => 'L’Économiseur de données est activé et bloque les téléchargements en arrière-plan via les données mobiles. Ils devraient toujours fonctionner en Wi-Fi.';
	@override String get reasonOemUnknown => 'Les téléchargements se sont arrêtés plusieurs fois lorsque PlezyNG était en arrière-plan. Vérifiez les paramètres de batterie ou d’utilisation en arrière-plan de PlezyNG.';
	@override String get openSettings => 'Ouvrir les paramètres';
	@override String get stillNotWorking => 'Aide spécifique à l’appareil';
	@override String get stillNotWorkingDescription => 'Consultez les étapes adaptées à votre appareil ou, si le problème persiste, envoyez un journal depuis Paramètres › Voir les journaux.';
	@override String get dialogTitle => 'Les téléchargements risquent de ne pas aboutir';
	@override String get dialogDownloadAnyway => 'Télécharger quand même';
	@override String get dialogFixFirst => 'Corriger d’abord';
	@override String get statusTile => 'Téléchargements en arrière-plan';
	@override String get statusOk => 'Exécution en arrière-plan autorisée';
	@override String get statusBlocked => 'Bloqués par les paramètres système';
	@override String get statusDegraded => 'Limités par les paramètres système';
	@override String get statusUnknown => 'Pas encore vérifié';
	@override String get settingsUnavailable => 'Impossible d’ouvrir les paramètres système sur cet appareil';
	@override String get linkUnavailable => 'Impossible d’ouvrir dontkillmyapp.com sur cet appareil';
}

// Path: downloads.groupings
class Translations$downloads$groupings$fr extends Translations$downloads$groupings$en {
	Translations$downloads$groupings$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get library => 'Bibliothèque';
	@override String get collections => 'Collections';
}

// Path: companionRemote.session
class Translations$companionRemote$session$fr extends Translations$companionRemote$session$en {
	Translations$companionRemote$session$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Démarrage du serveur de télécommande…';
	@override String get hostAddress => 'Adresse de l’hôte';
	@override String get connected => 'Connecté';
	@override String get serverRunning => 'Serveur de télécommande actif';
	@override String get serverStopped => 'Serveur de télécommande arrêté';
	@override String get serverRunningDescription => 'Les appareils mobiles de votre réseau peuvent se connecter à cette application';
	@override String get serverStoppedDescription => 'Démarrez le serveur pour permettre aux appareils mobiles de se connecter';
	@override String get usePhoneToControl => 'Utilisez votre appareil mobile pour contrôler cette application';
	@override String get startServer => 'Démarrer le serveur';
	@override String get stopServer => 'Arrêter le serveur';
	@override String get minimize => 'Réduire';
	@override String get manualAddressHint => 'Adresse de connexion manuelle :';
}

// Path: companionRemote.pairing
class Translations$companionRemote$pairing$fr extends Translations$companionRemote$pairing$en {
	Translations$companionRemote$pairing$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Les appareils PlezyNG avec le même compte Plex apparaissent ici';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Connexion...';
	@override String get searchingForDevices => 'Recherche d\'appareils...';
	@override String get noDevicesFound => 'Aucun appareil trouvé sur votre réseau';
	@override String get noDevicesHint => 'Ouvrez PlezyNG sur votre ordinateur et utilisez le même réseau Wi-Fi';
	@override String get availableDevices => 'Appareils disponibles';
	@override String get manualConnection => 'Connexion manuelle';
	@override String get cryptoInitFailed => 'Impossible de démarrer la connexion sécurisée. Connectez-vous d\'abord à Plex.';
	@override String get validationHostRequired => 'Veuillez saisir l’adresse de l’hôte';
	@override String get validationHostFormat => 'Le format doit être IP:port (p. ex. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Délai de connexion dépassé. Utilisez le même réseau sur les deux appareils.';
	@override String get sessionNotFound => 'Appareil introuvable. Assurez-vous que PlezyNG fonctionne sur l\'hôte.';
	@override String get authFailed => 'Échec de l\'authentification. Les deux appareils doivent utiliser le même compte Plex.';
	@override String failedToConnect({required Object error}) => 'Échec de la connexion : ${error}';
	@override String get codeTitle => 'Couple code';
	@override String get codeDescription => 'Entrez le code indiqué dans Companion Remote sur l\'appareil hôte. Les deux appareils doivent utiliser une version qui soutient la paille sécurisée.';
	@override String get codeInvalid => 'Entrez toutes les 32 lettres et chiffres du code hôte.';
	@override String get updateRequired => 'Mettre à jour les deux appareils à une version qui soutient la paille sécurisée.';
	@override String get hostDescription => 'Envoyez ce code une fois sur chaque téléchargement. Gardez-le privé: il donne le contrôle de ce profil.';
	@override String get resetCode => 'Réserver le code de paille';
	@override String get resetDescription => 'Disconnectez tous les remots et créez un nouveau code. Chaque remot aura besoin de se couper à nouveau.';
}

// Path: companionRemote.remote
class Translations$companionRemote$remote$fr extends Translations$companionRemote$remote$en {
	Translations$companionRemote$remote$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Voulez-vous vous déconnecter de la session distante ?';
	@override String get reconnecting => 'Reconnexion...';
	@override String attemptOf({required Object current}) => 'Tentative ${current} sur 5';
	@override String get retryNow => 'Réessayer maintenant';
	@override String get tabRemote => 'Télécommande';
	@override String get tabPlay => 'Lecture';
	@override String get tabMore => 'Plus';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Navigation par onglets';
	@override String get tabDiscover => 'Découvrir';
	@override String get tabLibraries => 'Bibliothèques';
	@override String get tabSearch => 'Rechercher';
	@override String get tabDownloads => 'Téléchargements';
	@override String get tabSettings => 'Paramètres';
	@override String get previous => 'Précédent';
	@override String get playPause => 'Lecture/Pause';
	@override String get next => 'Suivant';
	@override String get seekBack => 'Reculer';
	@override String get stop => 'Arrêter';
	@override String get seekForward => 'Avancer';
	@override String get volume => 'Volume';
	@override String get volumeDown => 'Baisser';
	@override String get volumeUp => 'Augmenter';
	@override String get fullscreen => 'Plein écran';
	@override String get subtitles => 'Sous-titres';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Rechercher sur l’ordinateur…';
}

// Path: companionRemote.errors
class Translations$companionRemote$errors$fr extends Translations$companionRemote$errors$en {
	Translations$companionRemote$errors$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Aucune interface réseau trouvée';
	@override String get authenticationFailed => 'Échec de l’authentification';
	@override String serverStartFailed({required Object error}) => 'Impossible de démarrer le serveur de télécommande : ${error}';
	@override String commandFailed({required Object error}) => 'Impossible d’envoyer la commande à distance : ${error}';
	@override String get joinTimedOut => 'Délai dépassé lors de la connexion à la session';
	@override String get failedToConnectAnyAddress => 'Impossible de se connecter à une adresse';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Connexion perdue après ${attempts} tentatives';
	@override String get connectionLost => 'Connexion perdue';
}

// Path: services.names
class Translations$services$names$fr extends Translations$services$names$en {
	Translations$services$names$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class Translations$services$simklReconnect$fr extends Translations$services$simklReconnect$en {
	Translations$services$simklReconnect$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reconnecter Simkl';
	@override String get subtitle => 'Simkl va retirer la méthode de connexion utilisée par cette liaison. La reconnexion ouvre simkl.com pour autoriser PlezyNG — PlezyNG n’a jamais accès à votre mot de passe. Votre historique de visionnage reste sur Simkl.';
}

// Path: services.deviceCode
class Translations$services$deviceCode$fr extends Translations$services$deviceCode$en {
	Translations$services$deviceCode$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Activer PlezyNG sur ${service}';
	@override String get instructions => 'Scannez le code QR ou accédez à l’adresse ci-dessous et saisissez ce code :';
	@override String openToActivate({required Object service}) => 'Ouvrir ${service} pour activer';
	@override String get copyCode => 'Copier le code d\'activation';
	@override String get waitingForAuthorization => 'En attente d\'autorisation…';
	@override String get codeCopied => 'Code copié';
}

// Path: services.oauthProxy
class Translations$services$oauthProxy$fr extends Translations$services$oauthProxy$en {
	Translations$services$oauthProxy$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Se connecter à ${service}';
	@override String get body => 'Scannez ce code QR ou ouvrez l\'URL sur n\'importe quel appareil.';
	@override String openToSignIn({required Object service}) => 'Ouvrir ${service} pour se connecter';
}

// Path: services.pendingAuth
class Translations$services$pendingAuth$fr extends Translations$services$pendingAuth$en {
	Translations$services$pendingAuth$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Copier l\'URL de connexion';
	@override String get urlCopied => 'URL copiée';
}

// Path: services.libraryFilter
class Translations$services$libraryFilter$fr extends Translations$services$libraryFilter$en {
	Translations$services$libraryFilter$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtre de bibliothèques';
	@override String get subtitleAllSyncing => 'Synchronisation de toutes les bibliothèques';
	@override String get subtitleNoneSyncing => 'Aucune synchronisation';
	@override String subtitleBlocked({required Object count}) => '${count} bloquées';
	@override String subtitleAllowed({required Object count}) => '${count} autorisées';
	@override String get mode => 'Mode de filtrage';
	@override String get modeBlacklist => 'Liste d’exclusion';
	@override String get modeWhitelist => 'Liste d’inclusion';
	@override String get modeHintBlacklist => 'Synchroniser toutes les bibliothèques sauf celles cochées ci-dessous.';
	@override String get modeHintWhitelist => 'Synchroniser uniquement les bibliothèques cochées ci-dessous.';
	@override String get libraries => 'Bibliothèques';
	@override String get noLibraries => 'Aucune bibliothèque disponible';
	@override String get modeDescription => 'Choisissez si les bibliothèques vérifiées sont bloquées de synchroniser ou qu’elles soient les seules bibliothéques qui synchronnent.';
}

// Path: services.trackerDescriptions
class Translations$services$trackerDescriptions$fr extends Translations$services$trackerDescriptions$en {
	Translations$services$trackerDescriptions$fr.internal(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Synchroniser les épisodes et films vues avec votre compte Trakt.';
	@override String get mal => 'Synchroniser les listes d\'anime et regarder le progrès avec MyAnimeList.';
	@override String get anilist => 'Synchroniser les listes d\'anime et regarder le progrès avec AniList.';
	@override String get simkl => 'Sync a regardé des films, des émissions télévisées et de l\'anime avec Simkl.';
	@override String get mdblist => 'Afficher les notations et les listes MDBList dans les recommandations et Explore.';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Icône de l’application',
			'appIcon.defaultIcon' => 'Par défaut',
			'appIcon.current' => 'Icône actuelle',
			'appIcon.locked' => 'Accès à vie requis',
			'appIcon.lockedHint' => 'Démarrez votre essai de 7 jours ou déconnectez PlezyNG pour une durée de vie pour utiliser des icônes alternatives.',
			'appIcon.changeFailed' => 'Impossible de changer l’icône de l’application',
			'appIcon.launcherHint' => 'La nouvelle icône apparaîtra sur votre écran d’accueil une fois que vous aurez quitté PlezyNG.',
			'appIcon.tvLauncherHint' => 'La nouvelle bannière apparaîtra une fois que vous aurez quitté PlezyNG. Android TV peut continuer à afficher l’ancienne jusqu’au redémarrage du téléviseur.',
			'appIcon.names.midnight' => 'Minuit',
			'appIcon.names.ember' => 'Braise',
			'appIcon.names.paper' => 'Papier',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Trait',
			'appIcon.names.ocean' => 'Océan',
			'appIcon.names.ultraviolet' => 'Ultraviolet',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Crépuscule',
			'appIcon.names.gold' => 'Or',
			'appIcon.names.titanium' => 'Titane',
			'appIcon.names.glass' => 'Verre',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Pixel',
			'appIcon.names.neon' => 'Néon',
			'appIcon.names.sticker' => 'Autocollant',
			'appIcon.names.ticket' => 'Ticket',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Strates',
			'appIcon.names.facet' => 'Facettes',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Choisissez l\'icône affichée par votre lanceur d\'appareil. Les prévisions montrent comment chaque option ressemble.',
			'auth.signInWithPlex' => 'Se connecter avec Plex',
			'auth.showQRCode' => 'Afficher le code QR',
			'auth.authenticate' => 'S\'authentifier',
			'auth.authenticationTimeout' => 'Délai d\'authentification expiré. Veuillez réessayer.',
			'auth.scanQRToSignIn' => 'Scannez ce QR code pour vous connecter',
			'auth.waitingForAuth' => 'En attente d\'authentification...\nConnectez-vous depuis votre navigateur.',
			'auth.useBrowser' => 'Utiliser le navigateur',
			'auth.or' => 'ou',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Se connecter à ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Utiliser Quick Connect',
			'auth.quickConnectInstructions' => 'Ouvrez Quick Connect dans Jellyfin et saisissez ce code.',
			'auth.quickConnectWaiting' => 'En attente d\'approbation…',
			'auth.quickConnectCancel' => 'Annuler',
			'auth.quickConnectExpired' => 'Quick Connect a expiré. Réessayez.',
			'auth.localDataRecoveryRequired' => 'PlezyNG n’a pas pu récupérer en toute sécurité les données locales de connexion et de lecture en attente. Veuillez vous reconnecter.',
			'auth.pinCheckRejected' => 'La vérification du code PIN Plex a été refusée',
			'auth.connectToDirectPlex' => 'Connectez-vous au serveur local Plex',
			'common.cancel' => 'Annuler',
			'common.save' => 'Enregistrer',
			'common.close' => 'Fermer',
			'common.closeMiniPlayer' => 'Un mini joueur proche',
			'common.closeWorkspaceWindow' => 'fenêtre proche',
			'common.returnToFullView' => 'Retour à la vue complète',
			'common.manageMediaSessions' => 'Gérer les séances médiatiques',
			'common.hideMediaSessions' => 'Découvrir les séances médiatiques',
			'common.mediaSessions' => 'Sessions médiatiques',
			'common.mediaSessionsHint' => 'Sélectionnez pour amener une session en avant. le parc cache sa fenêtre mais la tient ouverte. le retour l\'ouvre en pleine vue; il finit à proximité.',
			'common.sessionInWorkspace' => 'dans le laboratoire',
			'common.sessionParked' => 'Parking',
			'common.sessionFullscreen' => 'écran complet',
			'common.switchToNextWindow' => 'Swap avec la fenêtre suivante',
			'common.moveWindow' => 'Mouvez la fenêtre',
			'common.finishMovingWindow' => 'Fin de fenêtre en mouvement',
			'common.moveWindowHint' => 'Long pressez et jettez la fenêtre pour le déplacer. Ce contrôle permet également le mouvement de la clé des armes.',
			'common.movingWindowHelp' => 'Mettre en mouvement · Ajuster les clés de tir · Entrer les sauvegardes · Cancler l\'échappement',
			'common.resizeWindow' => 'Récupérer la fenêtre',
			'common.resizeWindowHint' => 'Tirez ce manuel ou utilisez les clés d\'armes pour redémarrer la fenêtre.',
			'common.workspaceWindowHint' => 'Utilisez le contrôle de mouvement ou la longue pression et tirer pour se déplacer.',
			'common.workspacePaneHint' => 'Sélectionnez ce panneau pour le focaliser. Utilisez son contrôle à plein écran pour s\'élargir.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Étiquette : ${title}',
			'common.workspaceTitleHint' => 'Tirez la barre de titre pour se déplacer; utilisez le bouton à pleine écran pour étendre.',
			'common.moveToSessionTray' => 'Mouvez-vous à la session tray',
			'common.moveToSessionTrayHint' => 'Cette session est disponible sans afficher sa fenêtre.',
			'common.closeSessionHint' => 'Fermez cette fenêtre et terminez sa session.',
			'common.sideBySideLayout' => 'Transfert vers le layout à côté',
			'common.floatingWindows' => 'Switch pour flotter les fenêtres',
			'common.clear' => 'Effacer',
			'common.reset' => 'Réinitialiser',
			'common.later' => 'Plus tard',
			'common.submit' => 'Soumettre',
			'common.confirm' => 'Confirmer',
			'common.retry' => 'Réessayer',
			'common.logout' => 'Se déconnecter',
			'common.unknown' => 'Inconnu',
			'common.refresh' => 'Rafraîchir',
			'common.yes' => 'Oui',
			'common.no' => 'Non',
			'common.delete' => 'Supprimer',
			'common.edit' => 'Modifier',
			'common.shuffle' => 'Mélanger',
			'common.addTo' => 'Ajouter à…',
			'common.createNew' => 'Créer',
			'common.connect' => 'Se connecter',
			'common.disconnect' => 'Se déconnecter',
			'common.play' => 'Lire',
			'common.pause' => 'Pause',
			'common.resume' => 'Reprendre',
			'common.error' => 'Erreur',
			'common.search' => 'Recherche',
			'common.home' => 'Accueil',
			'common.back' => 'Retour',
			'common.settings' => 'Paramètres',
			'common.mute' => 'Couper le son',
			'common.ok' => 'OK',
			'common.off' => 'Désactivé',
			'common.options' => 'Options',
			'common.seasonNumber' => ({required Object number}) => 'Saison ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Épisode ${number} – ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Chapitre ${number}',
			'common.reconnect' => 'Se reconnecter',
			'common.viewAll' => 'Tout afficher',
			'common.checkingNetwork' => 'Vérification du réseau...',
			'common.loadingServers' => 'Chargement des serveurs...',
			'common.connectingToServers' => 'Connexion aux serveurs...',
			'common.startingOfflineMode' => 'Démarrage en mode hors ligne…',
			'common.loading' => 'Chargement...',
			'common.fullscreen' => 'Plein écran',
			'common.exitFullscreen' => 'Quitter le plein écran',
			'common.pressBackAgainToExit' => 'Appuyez à nouveau sur retour pour quitter',
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
			'common.mediaKind.show' => 'Série',
			'common.mediaKind.season' => 'Saison',
			'common.mediaKind.episode' => 'Épisode',
			'common.mediaKind.artist' => 'Artiste',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Titre',
			'common.mediaKind.collection' => 'Collection',
			'common.mediaKind.playlist' => 'Playlist',
			'common.mediaKind.clip' => 'Clip',
			'common.mediaKind.photo' => 'Photo',
			'common.mediaKind.folder' => 'Dossier',
			'screens.licenses' => 'Licences',
			'screens.switchProfile' => 'Changer de profil',
			'screens.subtitleStyling' => 'Configuration des sous-titres',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Journaux',
			'update.available' => 'Mise à jour disponible',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} disponible',
			'update.currentVersion' => ({required Object version}) => 'Actuelle : ${version}',
			'update.skipVersion' => 'Ignorer cette version',
			'update.viewRelease' => 'Voir les notes de version',
			'update.latestVersion' => 'Vous utilisez la dernière version',
			'update.checkFailed' => 'Échec de la vérification des mises à jour',
			'settings.title' => 'Paramètres',
			'settings.supportDeveloper' => 'Soutenir PlezyNG',
			'settings.supportDeveloperDescription' => 'Faites un don pour soutenir le développement',
			'settings.lifetimeAccess' => 'PlezyNG accès à vie',
			'settings.language' => 'Langue',
			'settings.theme' => 'Thème',
			'settings.appearance' => 'Apparence',
			'settings.detailPage' => 'Page détaillée',
			'settings.themeSongsEnabled' => 'Jouer des chansons thématiques',
			'settings.themeSongsEnabledDescription' => 'Jouez à des chansons thématiques disponibles tout en regardant les détails médiatiques.',
			'settings.themeSongVolume' => 'Le volume de la chanson',
			'settings.videoPlayback' => 'Lecture vidéo',
			'settings.videoPlaybackDescription' => 'Configurer le comportement de lecture',
			'settings.advanced' => 'Avancé',
			'settings.episodePosterMode' => 'Style de l’affiche de l’épisode',
			'settings.seriesPoster' => 'Affiche de la série',
			'settings.seasonPoster' => 'Affiche de la saison',
			'settings.episodeThumbnail' => 'Miniature',
			'settings.showHeroSectionDescription' => 'Afficher le carrousel de contenu en vedette sur l\'écran d\'accueil',
			'settings.secondsLabel' => 'Secondes',
			'settings.minutesLabel' => 'Minutes',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'min',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Saisissez la durée (${min}–${max})',
			'settings.systemTheme' => 'Système',
			'settings.lightTheme' => 'Clair',
			'settings.darkTheme' => 'Sombre',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Braise',
			'settings.glacierTheme' => 'Glacier',
			'settings.forestTheme' => 'Forêt',
			'settings.plumTheme' => 'Prune',
			'settings.paperTheme' => 'Papier',
			'settings.libraryDensity' => 'Densité des bibliothèques',
			'settings.displayScale' => 'Échelle d\'affichage',
			'settings.compact' => 'Compact',
			'settings.comfortable' => 'Confortable',
			'settings.gridSpacing' => 'Espacement de la grille',
			'settings.gridSpacingTight' => 'Resserré',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Aéré',
			'settings.tvCornerSpotlightBackdrop' => 'Illustration en vedette dans le coin',
			'settings.tvCornerSpotlightBackdropDescription' => 'Afficher l’illustration en vedette dans le coin supérieur droit plutôt qu’en plein écran',
			'settings.viewMode' => 'Mode d\'affichage',
			'settings.gridView' => 'Grille',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Afficher la section à la une',
			'settings.showHomeBackdrop' => 'Afficher le travail d\'art de la maison backdrop',
			'settings.showHomeBackdropDescription' => 'Afficher une grande œuvre d\'art derrière les rares de la maison',
			'settings.contentScreensaverEnabled' => 'Screensaver de contenu',
			'settings.contentScreensaverEnabledDescription' => 'Afficher l\'art à plein écran après que l\'application a été idle',
			'settings.contentScreensaverDelay' => 'Démarrer l’écran après',
			'settings.contentScreensaverLibraries' => 'Les bibliothèques Screensaver',
			'settings.contentScreensaverLibrariesDescription' => 'Choisissez les bibliothèques qui fournissent les images de l’économiseur d’écran. Si aucune n’est sélectionnée, les images de toutes les bibliothèques sont utilisées.',
			'settings.contentScreensaverAllLibraries' => 'Toutes les bibliothèques',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} bibliothèques sélectionnées',
			'settings.contentScreensaverNoLibraries' => 'Aucune bibliothèque de médias connectée n’est disponible.',
			'settings.contentScreensaverDismissHint' => 'Appuyez sur un bouton ou tapez pour désactiver',
			'settings.newEpisodeNotifications' => 'Nouvelles notifications d\'épisode',
			'settings.newEpisodeNotificationsDescription' => 'Alerte lorsque un nouvel épisode est ajouté à un spectacle que vous êtes capturé. Vérifier pendant que Plezy est ouvert.',
			'settings.continueWatchingRowSize' => 'Continuez à regarder la taille de la ligne',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => 'Cartes ${label}',
			'settings.rowSizeCompact' => 'Compact',
			'settings.rowSizeStandard' => 'Standard',
			'settings.rowSizeLarge' => 'Grand',
			'settings.continueWatchingAction' => 'Action de « Continuer à regarder »',
			'settings.continueWatchingPlay' => 'Lire',
			'settings.continueWatchingDetails' => 'Ouvrir les détails',
			'settings.episodeAction' => 'Action des épisodes',
			'settings.episodePlay' => 'Lire',
			'settings.episodeDetails' => 'Ouvrir les détails',
			'settings.useGlobalHubs' => 'Utiliser la mise en page d\'accueil',
			'settings.useGlobalHubsDescription' => 'Afficher des hubs d\'accueil unifiés. Sinon, utiliser les recommandations de bibliothèque.',
			'settings.showServerNameOnHubs' => 'Afficher le nom du serveur sur les hubs',
			'settings.showServerNameOnHubsDescription' => 'Toujours afficher les noms des serveurs dans les titres des hubs.',
			'settings.groupLibrariesByServer' => 'Grouper les bibliothèques par serveur',
			'settings.groupLibrariesByServerDescription' => 'Regrouper les bibliothèques de la barre latérale par serveur multimédia.',
			'settings.alwaysKeepSidebarOpen' => 'Toujours garder la barre latérale ouverte',
			'settings.alwaysKeepSidebarOpenDescription' => 'La barre latérale reste étendue et la zone de contenu s\'adapte',
			'settings.showUnwatchedCount' => 'Afficher le nombre d’éléments non vus',
			'settings.showUnwatchedCountDescription' => 'Afficher le nombre d’épisodes non vus pour les séries et les saisons',
			'settings.showWatchedIndicators' => 'Afficher les indicateurs de visionnage',
			'settings.showWatchedIndicatorsDescription' => 'Afficher une coche sur les films, séries et épisodes déjà vus',
			'settings.showEpisodeNumberOnCards' => 'Afficher le numéro de l’épisode sur les cartes',
			'settings.showEpisodeNumberOnCardsDescription' => 'Afficher les numéros de saison et d’épisode sur les cartes d’épisode',
			'settings.showSeasonPostersOnTabs' => 'Afficher les affiches de saison sur les onglets',
			'settings.showSeasonPostersOnTabsDescription' => 'Afficher l’affiche de chaque saison au-dessus de son onglet',
			'settings.tvFullCardLayout' => 'Cartes TV plein format',
			'settings.tvFullCardLayoutDescription' => 'Utiliser des cartes TV composées uniquement d’une image, avec le nom des acteurs en surimpression',
			'settings.focusGlow' => 'Halo de sélection',
			'settings.focusGlowDescription' => 'Afficher un léger halo autour de la carte sélectionnée',
			'settings.visualEffects' => 'Effets visuels',
			'settings.visualEffectsAuto' => 'Automatique',
			'settings.visualEffectsAutoDescription' => 'Réduire automatiquement les effets sur les appareils peu puissants',
			'settings.visualEffectsFull' => 'Complets',
			'settings.visualEffectsReduced' => 'Réduits',
			'settings.visualEffectsReducedDescription' => 'Moins d’animations et d’illustrations de plus faible résolution',
			'settings.hideSpoilers' => 'Masquer les spoilers des épisodes non vus',
			'settings.hideSpoilersDescription' => 'Flouter les miniatures et descriptions des épisodes non vus',
			'settings.playerBackend' => 'Moteur de lecture',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Décodage matériel',
			'settings.hardwareDecodingDescription' => 'Utiliser l’accélération matérielle lorsqu’elle est disponible',
			'settings.playbackBuffer' => 'Tampon de lecture',
			'settings.playbackBufferAuto' => 'Auto (recommandé)',
			'settings.playbackBufferLarge' => 'Grand',
			'settings.playbackBufferExtraLarge' => 'Très grand',
			'settings.playbackBufferDescription' => 'Tampon supplémentaire contre les connexions instables. Également limité par la taille du tampon.',
			'settings.streamBufferSize' => 'Le buffer',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} Mo',
			'settings.streamBufferSizeDescription' => 'Combien de vidéos à charger avant lors de la lecture directe. transcodes s\'arrêtent au buffer de transcodes du serveur. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Remplacer le Playback Buffer lors de la configuration, capté à la moitié de la limite de mémoire de l\'application',
			'settings.streamBufferMegabytes' => 'Les Megabytes',
			'settings.defaultQualityTitle' => 'Qualité par défaut',
			'settings.cellularQualityTitle' => 'Qualité par défaut sur les données mobiles',
			'settings.remoteQualityTitle' => 'Qualité de la diffusion à distance',
			'settings.remoteQualitySameAsDefault' => 'La qualité défectueuse',
			'settings.cellularQualitySameAsDefault' => 'Identique à la qualité par défaut',
			'settings.directPlayCoveredQuality' => 'Lire les vidéos plus petites en qualité originale',
			'settings.directPlayCoveredQualityDescription' => 'Lire directement les vidéos déjà dans la limite de qualité au lieu de les transcoder',
			'settings.videoCodecs' => 'Codecs vidéo',
			'settings.videoCodecsDescription' => 'Le serveur transcode les codecs non cochés',
			'settings.videoCodecsAlwaysAccepted' => 'Toujours accepté',
			'settings.musicQualityTitle' => 'Qualité de la musique',
			'settings.subtitleStyling' => 'Style des sous-titres',
			'settings.subtitleStylingDescription' => 'Personnaliser l’apparence des sous-titres',
			'settings.smallSkipDuration' => 'Durée du saut court',
			'settings.largeSkipDuration' => 'Durée du saut long',
			'settings.rewindOnResume' => 'Rembobiner à la reprise',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} seconde', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes', ), 
			'settings.defaultSleepTimer' => 'Minuterie de mise en veille par défaut',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minute', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes', ), 
			'settings.rememberTrackSelections' => 'Mémoriser les pistes choisies pour chaque série ou film',
			'settings.chooseTracksBeforePlayback' => 'Choisissez les sous-titres et les audio avant le playback',
			'settings.chooseTracksBeforePlaybackDescription' => 'Choisissez les traces audio et sous-titres avant que chaque vidéo ne commence.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Toujours afficher les sous-titres sur ce dispositif',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Lorsque le serveur n\'a pas de sous-titre sélectionné, choisissez une piste localement.',
			'settings.autoDownloadPreferredSubtitle' => 'Les sous-titres de la langue préférée manquants',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Sélectionnez un sous-titre disponible dans votre langue préférée localement.Si aucun n\'existe, demandez au serveur de faire un lorsqu\'il est supporté.',
			'settings.rememberTrackSelectionsDescription' => 'Mémoriser les choix audio et sous-titres par titre',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex enregistre chaque choix sur le serveur pour chaque fichier ; Jellyfin active aussi l’option « Mémoriser les sélections » du compte ; Emby n’est pas pris en charge',
			'settings.followServerTrackSelections' => 'Utiliser les pistes sélectionnées sur le serveur pour chaque épisode',
			'settings.followServerTrackSelectionsDescription' => 'Au changement d\'épisode, appliquer l\'audio et les sous-titres sélectionnés sur le serveur au lieu de conserver le choix en cours',
			'settings.resumeMusicOnLaunch' => 'Mémoriser la session musicale',
			'settings.resumeMusicOnLaunchDescription' => 'Au lancement de l\'application, rouvrir le dernier titre en pause là où il s\'était arrêté',
			'settings.showChapterMarkersOnTimeline' => 'Afficher les marqueurs de chapitres sur la barre de lecture',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segmenter la barre de lecture aux limites des chapitres',
			'settings.specialsOrdering' => 'Épisodes spéciaux dans l’ordre des épisodes',
			'settings.specialsOrderingDescription' => 'Position des épisodes spéciaux dans l’ordre de visionnage d’une série',
			'settings.specialsOrderingServer' => 'Suivre l’ordre du serveur',
			'settings.specialsOrderingAirDate' => 'Intercaler selon la date de diffusion',
			'settings.specialsOrderingLast' => 'Après les saisons normales',
			'settings.clickVideoTogglesPlayback' => 'Cliquer sur la vidéo pour alterner entre lecture et pause',
			'settings.clickVideoTogglesPlaybackDescription' => 'Cliquer sur la vidéo pour lire ou mettre en pause plutôt que d’afficher les commandes',
			'settings.videoPlayerControls' => 'Commandes du lecteur vidéo',
			'settings.keyboardShortcuts' => 'Raccourcis clavier',
			'settings.keyboardShortcutsDescription' => 'Personnaliser les raccourcis clavier',
			'settings.videoPlayerNavigation' => 'Navigation dans le lecteur vidéo',
			'settings.videoPlayerNavigationDescription' => 'Utiliser les touches fléchées pour parcourir les commandes du lecteur vidéo',
			'settings.watchTogetherRelay' => 'Relais pour Regarder ensemble',
			'settings.watchTogetherRelayDescription' => 'Relais publics Open Watch Party, sauf si vous définissez le vôtre',
			'settings.watchTogetherRelayHint' => 'https://mon-relais.exemple.fr',
			'settings.watchTogetherRelayInvalid' => 'Saisissez une URL de base HTTP ou HTTPS valide pour le relais.',
			'settings.crashReporting' => 'Rapports de plantage',
			'settings.crashReportingDescription' => 'Envoyer des rapports de plantage pour améliorer l\'application',
			'settings.debugLogging' => 'Journalisation de débogage',
			'settings.debugLoggingDescription' => 'Activer la journalisation détaillée pour le dépannage',
			'settings.viewLogs' => 'Voir les journaux',
			'settings.viewLogsDescription' => 'Voir les journaux de l’application',
			'settings.clearImageCache' => 'Vider le cache d\'images',
			'settings.clearImageCacheDescription' => 'Vide les affiches et vignettes en cache. Les images peuvent se charger plus lentement jusqu\'à leur prochain téléchargement.',
			'settings.clearImageCacheSuccess' => 'Cache d\'images vidé avec succès',
			'settings.resetSettings' => 'Réinitialiser les paramètres',
			'settings.resetSettingsDescription' => 'Restaurer les paramètres par défaut. Action irréversible.',
			'settings.resetSettingsSuccess' => 'Réinitialisation des paramètres réussie',
			'settings.backup' => 'Sauvegarde',
			'settings.exportSettings' => 'Exporter les paramètres',
			'settings.exportSettingsDescription' => 'Enregistrer vos préférences dans un fichier',
			'settings.exportSettingsSuccess' => 'Paramètres exportés',
			'settings.importSettings' => 'Importer les paramètres',
			'settings.importSettingsDescription' => 'Restaurer les préférences depuis un fichier',
			'settings.importSettingsConfirm' => 'Cela remplacera vos paramètres actuels. Continuer ?',
			'settings.importSettingsSuccess' => 'Paramètres importés',
			'settings.importSettingsInvalidFile' => 'Ce fichier n’est pas une exportation valide des paramètres de PlezyNG',
			'settings.importSettingsNoUser' => 'Connectez-vous avant d’importer les paramètres',
			'settings.cloudBackup' => 'Cloud de sauvegarde',
			'settings.cloudBackupDescription' => 'Sauvegardez les paramètres transférables à une adresse WebDAV via HTTPS. Les connexions aux serveurs et les identifiants restent sur cet appareil.',
			'settings.cloudBackupUrl' => 'WebDAV JSON fichier URL',
			'settings.cloudBackupUsername' => 'Nom d\'utilisateur',
			'settings.cloudBackupPassword' => 'Mot de passe',
			'settings.cloudBackupSaved' => 'Cloud Backup Destination sauvée',
			'settings.cloudBackupNow' => 'Retour à présent',
			'settings.cloudBackupComplete' => 'Settings Backup envoyé',
			'settings.cloudBackupRestore' => 'Récupérer Backup',
			'settings.cloudBackupRestoreConfirm' => 'Cela remplacera les paramètres portables correspondants sur ce dispositif.',
			'settings.cloudBackupRestored' => 'Récupération de la récupération de la sauvegarde cloud',
			'settings.shortcutsReset' => 'Raccourcis réinitialisés aux valeurs par défaut',
			'settings.resetShortcutsConfirm' => 'Cela remplacera vos raccourcis personnalisés par les raccourcis par défaut. Continuer ?',
			'settings.about' => 'À propos',
			'settings.aboutDescription' => 'Informations sur l\'application et licences',
			'settings.updates' => 'Mises à jour',
			'settings.updateAvailable' => 'Mise à jour disponible',
			'settings.checkForUpdates' => 'Vérifier les mises à jour',
			'settings.autoCheckUpdatesOnStartup' => 'Vérifier automatiquement les mises à jour au démarrage',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Notifier au lancement quand une mise à jour est disponible',
			'settings.validationErrorEnterNumber' => 'Veuillez saisir un nombre valide',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'La durée doit être comprise entre ${min} et ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Raccourci déjà attribué à ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Raccourci mis à jour pour ${action}',
			'settings.saveFailed' => 'Impossible d’enregistrer les modifications. Réessayez.',
			'settings.autoPlayAndSkip' => 'Lecture automatique et saut',
			'settings.autoPlayNextEpisode' => 'Lire automatiquement l\'épisode suivant',
			'settings.autoPlayNextEpisodeDescription' => 'Lancer automatiquement l\'épisode suivant lorsqu\'un épisode se termine',
			'settings.shuffleStartsFromBeginning' => 'La lecture aléatoire commence au début',
			'settings.shuffleStartsFromBeginningDescription' => 'Lire chaque épisode depuis le début en lecture aléatoire au lieu de le reprendre',
			'settings.plexCinemaPreRoll' => 'Utiliser le serveur cinéma intros',
			'settings.plexCinemaPreRollDescription' => 'Jouez configuré Plex pré-rolls ou Jellyfin et Emby entrées avant le début d\'un film.',
			'settings.playNextCountdown' => 'Compte à rebours avant l\'épisode suivant',
			'settings.playNextCountdownImmediate' => 'Lire immédiatement',
			'settings.skipIntroMode' => 'Passer l’intro',
			'settings.skipIntroModeOffDescription' => 'Lire les intros normalement sans bouton de saut',
			'settings.skipIntroModeButtonDescription' => 'Afficher un bouton de saut au début d’une intro',
			'settings.skipIntroModeAutoDescription' => 'Passer les intros automatiquement après le délai ci-dessous',
			'settings.skipCreditsMode' => 'Passer le générique',
			'settings.skipCreditsModeOffDescription' => 'Lire le générique normalement sans bouton de saut',
			'settings.skipCreditsModeButtonDescription' => 'Afficher un bouton de saut au début du générique',
			'settings.skipCreditsModeAutoDescription' => 'Passer le générique automatiquement et lire l’épisode suivant',
			'settings.skipAdsMode' => '- les ads',
			'settings.skipAdsModeOffDescription' => 'Jouer des annonces détectées normalement sans un bouton de déclenche',
			'settings.skipAdsModeButtonDescription' => 'Afficher un bouton de déclenchement lorsque Plex détecte un annonce',
			'settings.skipAdsModeAutoDescription' => 'Éteindre les annonces détectées automatiquement après le retard ci-dessous',
			'settings.musicPlayback' => 'Musique Playback',
			'settings.musicSweetFades' => 'Les fades douces',
			'settings.musicSweetFadesDescription' => 'La musique est en train de se débarrasser lorsque Plex a des données de son.',
			'settings.skipMarkerModeOff' => 'Désactivé',
			'settings.skipMarkerModeButton' => 'Afficher le bouton',
			'settings.skipMarkerModeAuto' => 'Automatique',
			'settings.forceSkipMarkerFallback' => 'Forcer les marqueurs de secours',
			'settings.forceSkipMarkerFallbackDescription' => 'Utiliser les motifs des titres de chapitre même lorsque Plex fournit des marqueurs',
			'settings.theIntroDbFallback' => 'Utilisez TheIntroDB comme un intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Utilisez les horaires communautaires uniquement lorsque le serveur n\'a pas de marqueur d\'intro.',
			'settings.autoSkipDelay' => 'Délai avant le saut automatique',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Attendre ${seconds} secondes avant le saut automatique',
			'settings.introPattern' => 'Motif du marqueur d’introduction',
			'settings.introPatternDescription' => 'Expression régulière permettant de reconnaître les marqueurs d’introduction dans les titres de chapitre',
			'settings.creditsPattern' => 'Motif du marqueur de générique',
			'settings.creditsPatternDescription' => 'Expression régulière permettant de reconnaître les marqueurs de générique dans les titres de chapitre',
			'settings.prerolls' => 'Prérolls',
			'settings.playPrerollsBeforeMovies' => 'Jouer les pré-rolls avant les films',
			'settings.playPrerollsBeforeMoviesDescription' => 'Jouez un clip aléatoire de votre sélection ci-dessous avant chaque film.',
			'settings.prerollLibrary' => 'Bibliothèque Preroll',
			'settings.prerollLibraryNotSet' => 'Non défini',
			'settings.prerollLibraryNoneFound' => 'Aucune bibliothèque n’a été trouvée sur vos serveurs.',
			'settings.prerollSelection' => 'Les prérogatives sélectionnées',
			'settings.prerollSelectionPickLibraryFirst' => 'Choisissez une bibliothèque d’abord',
			'settings.prerollSelectionNoneSelected' => 'Pas de pré-section sélectionnée',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} sélectionné(s)',
			'settings.prerollItemPicker' => 'Choisir les précautions',
			'settings.prerollItemPickerLoadFailed' => 'Je ne pouvais pas charger des articles de cette bibliothèque.',
			'settings.invalidRegex' => 'Expression régulière invalide',
			'settings.regex' => 'Expression régulière',
			'settings.downloads' => 'Téléchargements',
			'settings.downloadLocationDescription' => 'Choisir où stocker le contenu téléchargé',
			'settings.downloadLocationDefault' => 'Par défaut (stockage de l\'application)',
			'settings.downloadLocationCustom' => 'Emplacement personnalisé',
			'settings.selectFolder' => 'Sélectionner un dossier',
			'settings.resetToDefault' => 'Réinitialiser les paramètres par défaut',
			'settings.currentPath' => ({required Object path}) => 'Actuel : ${path}',
			'settings.downloadLocationChanged' => 'Emplacement de téléchargement modifié',
			'settings.downloadLocationReset' => 'Emplacement de téléchargement réinitialisé à la valeur par défaut',
			'settings.downloadLocationInvalid' => 'Le dossier sélectionné n\'est pas accessible en écriture',
			'settings.downloadLocationPickerUnavailable' => 'La sélection de dossier n’est pas disponible sur cet appareil',
			'settings.downloadOnWifiOnly' => 'Télécharger uniquement en Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Empêcher les téléchargements via les données mobiles',
			'settings.autoRemoveWatchedDownloads' => 'Supprimer automatiquement les téléchargements vus',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Supprimer automatiquement les téléchargements vus',
			'settings.autoDownloadContinueWatching' => 'Auto-Download Continuez à regarder',
			'settings.autoDownloadContinueWatchingDescription' => 'Gardez les articles sur votre bouclier de suivi continu téléchargés, et les supprimez une fois qu\'ils quittent le bouclier',
			'settings.downloadQuality' => 'Télécharger la qualité',
			'settings.downloadQualityDescription' => 'Plex prépare une copie convertie dans son code de téléchargement. Jellyfin et Emby transcode pendant que le fichier téléchargera; les transferts interrompus peuvent avoir besoin de redémarrer.',
			'settings.askDownloadQualityEachTime' => 'Choisissez la qualité pour chaque téléchargement',
			'settings.askDownloadQualityEachTimeDescription' => 'Afficher le picker de qualité avant de couper chaque téléchargement vidéo',
			'settings.cellularDownloadBlocked' => 'Les téléchargements sont bloqués sur le réseau mobile. Utilisez le Wi-Fi ou modifiez ce paramètre.',
			'settings.maxVolume' => 'Volume maximal',
			'settings.maxVolumeDescription' => 'Autoriser l\'augmentation du volume au-delà de 100 % pour les médias silencieux',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Afficher sur Discord ce que vous regardez',
			'settings.services' => 'Services',
			'settings.servicesDescription' => 'Connecter Trakt, MyAnimeList, Seerr et d’autres services',
			'settings.manageLibrariesDescription' => 'Réorganiser et masquer les bibliothèques',
			'settings.companionRemoteServer' => 'Serveur de télécommande',
			'settings.companionRemoteServerDescription' => 'Autoriser les appareils mobiles de votre réseau à contrôler cette application',
			'settings.companionRemoteServerStartFailed' => 'Impossible de démarrer le serveur de télécommande',
			'settings.companionRemoteServerStopFailed' => 'Impossible d\'arrêter le serveur de télécommande',
			'settings.autoPip' => 'Mode image dans l’image automatique',
			'settings.autoPipDescription' => 'Passer en mode image dans l’image si vous quittez l’application pendant la lecture',
			'settings.matchContentFrameRate' => 'Adapter la fréquence d’images au contenu',
			'settings.matchContentFrameRateDescription' => 'Adapter la fréquence de rafraîchissement de l’écran au contenu vidéo',
			'settings.matchContentResolution' => 'Adapter à la résolution du contenu',
			'settings.matchContentResolutionDescription' => 'Bascule l’affichage sur la résolution native de la vidéo pour que votre téléviseur gère la mise à l’échelle. Les menus et les sous-titres sont eux aussi mis à l’échelle pendant la lecture',
			'settings.matchRefreshRate' => 'Adapter la fréquence de rafraîchissement',
			'settings.matchRefreshRateDescription' => 'Adapter la fréquence d\'affichage en plein écran',
			'settings.matchDynamicRange' => 'Adapter la plage dynamique',
			'settings.matchDynamicRangeDescription' => 'Activer HDR pour le contenu HDR, puis revenir en SDR',
			'settings.displaySwitchDelay' => 'Délai de changement d\'affichage',
			'settings.tunneledPlayback' => 'Lecture tunnelée',
			'settings.tunneledPlaybackDescription' => 'Utiliser le tunneling vidéo. Désactivez si la lecture HDR affiche un écran noir ou si l’image saccade.',
			'settings.audioPassthrough' => 'Transmission audio directe',
			'settings.audioPassthroughDescription' => 'Envoyer l’audio Dolby/DTS à votre ampli ou téléviseur sans le réencoder afin de préserver le son surround. Désactivez cette option en l’absence de son.',
			'settings.audioPassthroughDescriptionApple' => 'Utiliser le décodeur Dolby natif d’Apple pour le Dolby Digital Plus, y compris Atmos. Le DTS et le TrueHD sont toujours lus en PCM multicanal. Désactivez cette option en l’absence de son.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Utiliser le décodeur Dolby natif d’Apple pour le Dolby Digital Plus, y compris Atmos. Sous iOS, iPadOS et tvOS 26 ou version ultérieure, le TrueHD Atmos et le DTS:X sont lus en audio spatial. Les autres pistes DTS et TrueHD sont lues en PCM multicanal. Désactivez cette option en l’absence de son.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Désactivée tant que la normalisation du volume est active',
			'settings.audioChannelLimit' => 'Canaux audio',
			'settings.audioChannelLimitDescription' => 'Réduire le nombre de canaux de l’audio décodé pour les enceintes, casques ou installations HDMI qui ne peuvent pas restituer tous les canaux',
			'settings.audioChannelLimitOriginal' => 'D’origine',
			'settings.audioChannelLimitOriginalDescription' => 'Lire tous les canaux de la piste',
			'settings.audioChannelLimitSurround51' => 'Jusqu’à 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Convertir le 7.1 en 5.1 pour les téléviseurs et amplis qui n’acceptent que le PCM 5.1. La transmission directe n’est pas affectée.',
			'settings.audioChannelLimitStereo' => 'Stéréo',
			'settings.audioChannelLimitStereoDescription' => 'Convertir en deux canaux pour des enceintes stéréo ou un casque. Désactive la transmission directe.',
			'settings.downmixCenterBoost' => 'Renforcement du canal central',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Renforcement (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normaliser le volume lors de la conversion en stéréo',
			'settings.audioDownmixNormalizeDescription' => 'Atténuer le mixage pour éviter la saturation. Désactivez cette option pour conserver le volume d’origine, au risque de déformer les scènes bruyantes.',
			'settings.dvConversionMode' => 'Conversion Dolby Vision',
			'settings.dvConversionModeDescription' => 'Choisir comment les fichiers Dolby Vision de profil 7 sont gérés.',
			'settings.dvConversionAuto' => 'Auto',
			'settings.dvConversionNative' => 'Natif / désactivé',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Utiliser la détection des capacités de l’appareil et le comportement de repli normal',
			'settings.dvConversionNativeDescription' => 'Forcer le DV7 natif et bloquer la nouvelle tentative de conversion DV',
			'settings.dvConversionDv81Description' => 'Forcer la conversion RPU intégrée vers le profil 8.1 de Dolby Vision',
			'settings.dvConversionHevcStripDescription' => 'Supprimer les couches RPU/EL Dolby Vision et présenter du HEVC simple',
			'settings.experimentalDolbyVision' => 'Dolby Vision expérimental',
			'settings.experimentalDolbyVisionDescription' => 'Utiliser le moteur de rendu FEL expérimental à la prochaine lecture. Nécessite une compilation distincte du moteur.',
			'settings.dvExperimentUnavailableDescription' => 'Cette expérimentation est actuellement disponible uniquement sous Linux.',
			'settings.dvCompatibilityFallback' => 'Repli de compatibilité',
			'settings.dvCompatibilityFallbackDescription' => 'Utiliser le rendu standard si l’expérimentation ne démarre pas. Les données FEL peuvent être perdues.',
			'settings.dvExperimentDiagnostics' => 'Journalisation de l’expérimentation vidéo',
			'settings.dvExperimentDiagnosticsDescription' => 'Activer les journaux détaillés du lecteur à la prochaine lecture.',
			'settings.disableDolbyVision' => 'Désactiver Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Lire la couche HDR10 ou HLG du fichier au lieu de Dolby Vision, si elle existe',
			'settings.hdrSdrConversion' => 'Conversion HDR vers SDR',
			'settings.hdrSdrConversionDescription' => 'Choisir ce qui convertit les vidéos HDR lorsque l’écran ne peut pas afficher le HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Auto',
			'settings.hdrSdrConversionAutoDescription' => 'Appareil à partir d’Android 9, lecteur sur les versions antérieures',
			'settings.hdrSdrConversionDevice' => 'Appareil',
			'settings.hdrSdrConversionDeviceDescription' => 'Le matériel vidéo de l’appareil effectue la conversion. Le plus rapide, mais les couleurs dépendent de l’appareil',
			'settings.hdrSdrConversionPlayer' => 'Lecteur',
			'settings.hdrSdrConversionPlayerDescription' => 'Le lecteur effectue la conversion. Couleurs homogènes, mais la 4K peut saccader sur les box TV d’entrée de gamme',
			'settings.deinterlace' => 'Désentrelacement',
			'settings.deinterlaceDescription' => 'Supprimer les artefacts de peignage des vidéos entrelacées (lecteur mpv uniquement)',
			'settings.deinterlaceOff' => 'Désactivé',
			'settings.deinterlaceOffDescription' => 'Afficher la vidéo entrelacée telle qu’elle est décodée',
			'settings.deinterlaceVideo' => 'Vidéo',
			'settings.deinterlaceVideoDescription' => 'Transformer chaque trame en image complète. Pour les vidéos tournées pour la télévision, comme le sport, les infos et les concerts',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'Restaurer les images d’origine des films et animations convertis en 29,97 i/s par télécinéma, un cas fréquent sur les DVD NTSC. Les vidéos tournées pour la télévision saccadent. La TV en direct utilise le mode Vidéo',
			'settings.requireProfileSelectionOnOpen' => 'Demander le profil à l\'ouverture',
			'settings.requireProfileSelectionOnOpenDescription' => 'Afficher la sélection de profil à chaque ouverture de l\'application',
			'settings.forceTvMode' => 'Forcer le mode TV',
			'settings.forceTvModeDescription' => 'Forcer l’interface TV sur les appareils qui ne sont pas détectés automatiquement. Redémarrage requis.',
			'settings.startInFullscreen' => 'Démarrer en plein écran',
			'settings.startInFullscreenDescription' => 'Ouvrir PlezyNG en mode plein écran au lancement',
			'settings.exitFullscreenOnPlayerClose' => 'Quitter le plein écran à la fermeture du lecteur',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Quitter automatiquement le plein écran lors de la fermeture du lecteur vidéo',
			'settings.autoHidePerformanceOverlay' => 'Masquer automatiquement les données de performance',
			'settings.autoHidePerformanceOverlayDescription' => 'Masquer progressivement les données de performance avec les commandes de lecture',
			'settings.showNavBarLabels' => 'Afficher les libellés de la barre de navigation',
			'settings.showNavBarLabelsDescription' => 'Afficher les libellés sous les icônes de la barre de navigation',
			'settings.startupSection' => 'Section de démarrage',
			'settings.preferredServer' => 'Le serveur préféré',
			'settings.preferredServerDescription' => 'Prioriser les résultats de ce serveur tout en gardant chaque serveur connecté disponible.',
			'settings.preferredServerAutomatic' => 'Automatique',
			'settings.showExploreTab' => 'Afficher l’onglet Explorer',
			'settings.showExploreTabDescription' => 'Afficher l’onglet Explorer avec le contenu de Plex Discover et des services de suivi connectés',
			'settings.hideEmptyLibraries' => 'Écrivez des bibliothèques vides',
			'settings.hideEmptyLibrariesDescription' => 'Supprimer les bibliothèques avec un nombre d\'éléments rapportés par le serveur de zéro de la navigation.',
			'settings.liveTvDefaultFavorites' => 'Chaînes favorites par défaut',
			'settings.liveTvDefaultFavoritesDescription' => 'Afficher uniquement les chaînes favorites à l\'ouverture de la TV en direct',
			'settings.general' => 'Général',
			'settings.generalDescription' => 'Langue, démarrage et comportement de la fenêtre',
			'settings.languageAndRegion' => 'Langue et région',
			'settings.startup' => 'Démarrage',
			'settings.display' => 'Affichage',
			'settings.libraryAndCards' => 'Bibliothèque et cartes',
			'settings.homeScreen' => 'Écran d\'accueil',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Fenêtre',
			'settings.liveTv' => 'TV en direct',
			'settings.player' => 'Lecteur',
			'settings.videoAndDisplay' => 'Vidéo et affichage',
			'settings.audio' => 'Audio',
			'settings.quality' => 'Qualité',
			'settings.subtitles' => 'Sous-titres',
			'settings.seekAndTiming' => 'Déplacement et minutage',
			'settings.behavior' => 'Comportement',
			'settings.gestures' => 'Gestes',
			'settings.gestureBrightnessSwipe' => 'Balayage de luminosité',
			'settings.gestureBrightnessSwipeDescription' => 'Balayez vers le haut ou le bas sur le bord gauche pour régler la luminosité',
			'settings.gestureVolumeSwipe' => 'Balayage de volume',
			'settings.gestureVolumeSwipeDescription' => 'Balayez vers le haut ou le bas sur le bord droit pour régler le volume',
			'settings.gesturePinchToZoom' => 'Pincer pour zoomer',
			'settings.gesturePinchToZoomDescription' => 'Pincez la vidéo pour zoomer ou dézoomer',
			'settings.gestureSeekSwipe' => 'Rechercher Swipe',
			'settings.gestureSeekSwipeDescription' => 'Swipe gauche ou droite n\'importe où sur la vidéo à rechercher; libérer pour sauter',
			'settings.rememberBrightnessLevel' => 'Mémoriser le niveau de luminosité',
			'settings.rememberBrightnessLevelDescription' => 'Démarrer la lecture à la luminosité définie par le dernier balayage',
			'settings.controls' => 'Commandes',
			'settings.rememberPlayerChanges' => 'Mémoriser les modifications du lecteur',
			'settings.rememberPlayerChangesDescription' => 'Où une modification effectuée pendant la lecture est enregistrée et réappliquée',
			'settings.scopePlaybackSpeed' => 'Vitesse de lecture',
			'settings.scopeShaderPreset' => 'Préréglage du shader',
			'settings.scopeAspectRatio' => 'Format d’image',
			'settings.scopeSyncOffsets' => 'Synchronisation audio et sous-titres',
			'settings.playerScopeOff' => 'Ne pas enregistrer',
			'settings.playerScopeGlobal' => 'Partout',
			'settings.playerScopeLibrary' => 'Par bibliothèque',
			'settings.playerScopeTitle' => 'Par série ou film',
			'settings.exportDialogTitle' => 'Exporter les paramètres de PlezyNG',
			'settings.followSystem' => 'Suivre le système',
			'settings.followAppLanguage' => 'Comme la langue de l’interface',
			'settings.regionFormat' => 'Formats régionaux',
			'settings.regionFormatDescription' => 'Choisissez le format des dates, des nombres et des unités de mesure.',
			'settings.metadataLanguage' => 'Langue des métadonnées',
			'settings.metadataLanguageDescription' => 'Langue préférée pour les titres et descriptions, si le serveur la prend en charge. Les préférences audio et de sous-titres restent distinctes.',
			'settings.enterFullscreenOnPlaybackStart' => 'Entrer sur l\'écran complet lorsque le playback commence',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Ouvrir la vidéo à l\'écran complet lorsque le playback commence',
			'settings.extendVideoIntoDisplayCutout' => 'Extendre la vidéo à l\'affichage Cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Laissez la vidéo à pleine écran utiliser le cutout de la caméra sur les téléphones Android',
			'settings.languageDescription' => 'Choisissez la langue utilisée pour les contrôles et les messages PlezyNG. Suivez le système trace votre langage de l\'appareil.',
			'settings.themeDescription' => 'Choisissez les couleurs et contrôles utilisés dans toute l\'application.',
			'settings.libraryDensityDescription' => 'Changer le nombre de cartes de bibliothèque dans chaque ligne.',
			'settings.displayScaleDescription' => 'Récupérer l\'interface sur cet écran de voiture sans modifier la taille du texte de votre appareil.',
			'settings.themeSongVolumeDescription' => 'Définissez le volume des chansons thématiques par rapport à d\'autres sons.',
			'settings.viewModeDescription' => 'Choisissez si les articles de la bibliothèque apparaissent comme des affiches dans un réseau ou comme une liste compacte.',
			'settings.gridViewDescription' => 'Arrangez les articles de la bibliothèque dans des lignes et colonnes d\'affiches.',
			'settings.listViewDescription' => 'Afficher les articles de bibliothèque dans une liste verticale avec plus de texte par article.',
			'settings.gridSpacingDescription' => 'Mettez la distance entre les affiches dans les filets de bibliothèque.',
			'settings.gridSpacingTightDescription' => 'Faites plus de cartes sur l\'écran avec des lacunes plus petites.',
			'settings.gridSpacingNormalDescription' => 'Utilisez l’écart standard entre les dossiers.',
			'settings.gridSpacingSpaciousDescription' => 'Ajoutez des lacunes plus grandes entre les dossiers pour plus de séparation.',
			'settings.episodePosterModeDescription' => 'Choisissez quelle œuvre d\'art apparaît sur les cartes d\'épisode.',
			'settings.seriesPosterDescription' => 'Utilisez le poster de la série pour chaque épisode.',
			'settings.seasonPosterDescription' => 'Utilisez le poster de saison pour chaque épisode lorsqu’il est disponible.',
			'settings.episodeThumbnailDescription' => 'Utilisez un cadre de l\'épisode quand il est disponible.',
			'settings.continueWatchingActionDescription' => 'Choisissez ce qui se passe lorsque vous activez une carte de suivi continue.',
			'settings.continueWatchingPlayDescription' => 'Commencez immédiatement le film ou l\'épisode.',
			'settings.continueWatchingDetailsDescription' => 'Ouvrez d\'abord la page de titre afin que vous puissiez réviser les détails et choisir une action.',
			'settings.episodeActionDescription' => 'Choisissez ce qui se passe lorsque vous activez une carte d\'épisode.',
			'settings.episodePlayDescription' => 'Commencez immédiatement l’épisode.',
			'settings.episodeDetailsDescription' => 'Ouvrez la page avant le playback.',
			'settings.contentScreensaverDelayDescription' => 'Choisissez combien de temps PlezyNG attend sans entrée avant d\'afficher des œuvres d\'art.',
			'settings.continueWatchingRowSizeDescription' => 'Choisissez la taille des cartes dans la ligne de suivi continue.',
			'settings.rowSizeCompactDescription' => 'Affichez des cartes plus petites afin que de plus d\'objets s\'adaptent à travers la ligne.',
			'settings.rowSizeStandardDescription' => 'Utilisez la taille standard de la carte.',
			'settings.rowSizeLargeDescription' => 'Afficher des cartes plus grandes avec plus de détails d\'art.',
			'settings.visualEffectsDescription' => 'Choisissez le budget de l\'animation et des effets d\'art pour ce dispositif.',
			'settings.visualEffectsFullDescription' => 'Utilisez les effets d\'animation et d\'art sur chaque appareil.',
			'settings.startupSectionDescription' => 'Choisissez la section qui s\'ouvre lorsque PlezyNG démarre.',
			'settings.startupSectionOptions.discover' => 'Des recommandations ouvertes et des articles provenant de sources de découverte connectées.',
			'settings.startupSectionOptions.libraries' => 'Ouvrez vos bibliothèques de médias connectés.',
			'settings.startupSectionOptions.liveTv' => 'Ouvrez la télévision en direct lorsque un serveur la fournit; sinon le start-up tombe de retour à Home.',
			'settings.startupSectionOptions.search' => 'Recherche de médias ouverts.',
			'settings.smallSkipDurationDescription' => 'Mettez la distance déplacée par le court en arrière et à l\'avant chercher les contrôles.',
			'settings.largeSkipDurationDescription' => 'Mettez la distance déplacée par le long en arrière et à l\'avant chercher les contrôles.',
			'settings.rewindOnResumeDescription' => 'Mouvez le replayback de cette somme lorsque vous récupérez une vidéo.',
			'settings.defaultSleepTimerDescription' => 'Définissez la durée initiale utilisée lorsque vous commencez le timing du sommeil.',
			'settings.playNextCountdownDescription' => 'Attendez cela longtemps avant de commencer le prochain épisode. Sélectionnez à 0 pour démarrer immédiatement.',
			'settings.autoSkipDelaySettingDescription' => 'Il s\'applique lorsque un intro, crédit ou annonce est configuré pour échapper automatiquement.',
			'settings.downmixCenterBoostDescription' => 'Augmentez le dialogue dans le canal central lorsque l\'audio environnante est mélangée vers le stéréo.',
			'settings.displaySwitchDelayDescription' => 'Attendre avant de changer le mode d\'affichage afin que la télévision ou le récepteur puisse terminer son précédent interrupteur.',
			'settings.playerBackendDescription' => 'Choisissez le moteur de lecture qui découvre et rend la vidéo sur cet appareil.',
			'settings.exoPlayerDescription' => 'Utilisez le lecteur natif Media3 d\'Android et les voies matérielles soutenues.',
			'settings.mpvDescription' => 'Utilisez mpv, qui expose des contrôles de lecture supplémentaires, sous-titres et traitement vidéo.',
			'settings.scopeOffDescription' => 'Remplacer les changements pour la session actuelle de reprise uniquement.',
			'settings.scopeGlobalDescription' => 'Réutiliser la même valeur pour chaque bibliothèque et titre.',
			'settings.scopeLibraryDescription' => 'Rappelez-vous une valeur distincte pour chaque bibliothèque.',
			'settings.scopeTitleDescription' => 'Rappelez-vous une valeur distincte pour chaque spectacle ou film.',
			'settings.specialsOrderingServerDescription' => 'Gardez l\'ordre d\'épisode fourni par le serveur de médias.',
			'settings.specialsOrderingAirDateDescription' => 'Placez des spéciales parmi les épisodes réguliers à leur date aérienne.',
			'settings.specialsOrderingLastDescription' => 'Placez chaque spécial après les saisons régulières.',
			'settings.skipIntroModeDescription' => 'Choisissez si les marquants intro jouent normalement, affichez un bouton d\'échappement ou échapper automatiquement.',
			'settings.skipCreditsModeDescription' => 'Choisissez si les crédits jouent normalement, affichez un bouton d\'échappement ou échapper automatiquement.',
			'settings.skipAdsModeDescription' => 'Choisissez si les annonces détectées se jouent normalement, affichez un bouton d\'échappement ou échapper automatiquement.',
			'settings.playbackBufferAutoDescription' => 'Laissez le joueur actif choisir sa taille de buffer normale.',
			'settings.playbackBufferLargeDescription' => 'Gardez plus de médias prêts avant la lecture; cela utilise plus de mémoire.',
			'settings.playbackBufferExtraLargeDescription' => 'Gardez le plus grand buffer de lecture, ce qui utilise la plus grande mémoire.',
			'settings.defaultQualityDescription' => 'Configurez la résolution vidéo par défaut et bitrate le plafond pour les courants que le serveur transcode.',
			'settings.cellularQualityDescription' => 'Supprimer la qualité par défaut lorsque le dispositif utilise une connexion cellulaire uniquement.',
			'settings.remoteQualityDescription' => 'Supprimer la qualité par défaut lors de la connexion à un serveur via une connectivité à distance.',
			'settings.qualityPresetOriginalDescription' => 'Jouez la source à sa qualité disponible sans demander au serveur de la transcoder.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Demandez au serveur un flux converti en utilisant la résolution et la vitesse indiquées ci-dessus.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Utilisez la qualité sélectionnée dans la qualité par défaut.',
			'settings.musicQualityDescription' => 'Configurez la vitesse audio maximale demandée du serveur; Original maintient le flux source.',
			'settings.musicQualityOriginalDescription' => 'Jouez à l\'audio source sans un transcode de bitrate.',
			'settings.musicQualityTranscodeOptionDescription' => 'Demandez un transcode du serveur cappé près de la vitesse indiquée ci-dessus; la sortie réelle peut varier.',
			'settings.maxVolumeInputLabel' => 'Volume maximum (%)',
			'settings.checkForUpdatesDescription' => 'Vérifiez maintenant si une version plus récente de PlezyNG est disponible.',
			'settings.appearanceDescription' => 'Choisissez le thème de l\'application et ajustez les cartes bibliothèques, les lignes d\'accueil et la navigation.',
			'settings.prerollLibraryDescription' => 'Choisissez la bibliothèque qui contient les clips disponibles en tant que pré-rolls de film.',
			'settings.prerollSelectionDescription' => 'Choisissez les clips de la bibliothèque sélectionnée que vous pouvez jouer avant les films.',
			'settings.contentScreensaverDelayOptionDescription' => 'Attendre de nombreuses minutes sans entrées avant d\'afficher l\'œuvre d\'art screensaver.',
			'settings.videoCodecOptionDescription' => 'Permettre la reproduction directe de ce codec lorsqu\'il est supporté. les codecs non vérifiés sont transcodés par le serveur des médias.',
			'themeEditor.builtIn' => 'Intégrés',
			'themeEditor.presets' => 'Prédéfinis',
			'themeEditor.custom' => 'Personnalisé',
			'themeEditor.customEmpty' => 'Pas encore créé',
			'themeEditor.editCustom' => 'Modifier le thème personnalisé',
			'themeEditor.editCustomDescription' => 'Choisissez vous-même chaque couleur',
			'themeEditor.locked' => 'Accès à vie requis',
			'themeEditor.savedLocked' => 'Épargné - disponible avec accès à vie',
			'themeEditor.title' => 'Thème personnalisé',
			'themeEditor.startFrom' => 'Partir d’un thème',
			'themeEditor.startFromDescription' => 'Copier toutes les couleurs d’un autre thème',
			'themeEditor.colors' => 'Couleurs',
			'themeEditor.preview' => 'Aperçu',
			'themeEditor.slots.bg' => 'Arrière-plan',
			'themeEditor.slots.surface' => 'Surface',
			'themeEditor.slots.outline' => 'Contour',
			'themeEditor.slots.text' => 'Texte',
			'themeEditor.slots.textMuted' => 'Texte secondaire',
			'themeEditor.slots.accent' => 'Accent',
			'themeEditor.opacity' => 'Opacité',
			'themeEditor.hexHint' => '#RRGGBB ou #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Dans les autres thèmes',
			'themeEditor.swatchLabel' => ({required Object color, required Object theme}) => '${color} du thème ${theme}',
			'themeEditor.contrast.textOnBg' => 'Texte sur l’arrière-plan',
			'themeEditor.contrast.textOnSurface' => 'Texte sur la surface',
			'themeEditor.contrast.textMutedOnBg' => 'Texte secondaire sur l’arrière-plan',
			'themeEditor.contrast.textMutedOnSurface' => 'Texte secondaire sur la surface',
			'themeEditor.contrast.accentOnBg' => 'Accent sur l’arrière-plan',
			'themeEditor.contrast.accentOnSurface' => 'Accent sur la surface',
			'themeEditor.contrast.labelOnAccent' => 'Libellé de bouton sur l’accent',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair} : ${ratio}:1, sous le seuil recommandé de ${minimum}:1',
			'themeEditor.discardTitle' => 'Abandonner les modifications ?',
			'themeEditor.discardMessage' => 'Vos modifications de couleurs non enregistrées seront perdues.',
			'themeEditor.discard' => 'Abandonner',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Épisode ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} min restantes',
			'themeEditor.previewSwitch' => 'Lecture automatique',
			'themeEditor.previewMutedText' => 'Voici à quoi ressemble le texte secondaire',
			'themeEditor.themeSystemDescription' => 'Suivez l’apparence de votre appareil et passez automatiquement entre la lumière et le noir.',
			'themeEditor.themeLightDescription' => 'Utilisez un fond lumineux avec du texte sombre.',
			'themeEditor.themeDarkDescription' => 'Utilisez un fond sombre avec un texte lumineux.',
			'themeEditor.themeOledDescription' => 'Utilisez des surfaces en noir qui réduisent la lumière sur les écrans OLED.',
			'themeEditor.themeEmberDescription' => 'Utilisez des couleurs d\'accent rouge et amber.',
			'themeEditor.themeGlacierDescription' => 'Utilisez des couleurs d’accent bleu.',
			'themeEditor.themeForestDescription' => 'Utilisez des couleurs d’accent verts et naturels.',
			'themeEditor.themePlumDescription' => 'Utilisez des couleurs d\'accent violet et plum.',
			'themeEditor.themePaperDescription' => 'Utilisez des surfaces chaudes en papier et des couleurs inspirées d\'encre.',
			'themeEditor.themeCustomDescription' => 'Utilisez la palette de couleurs que vous avez créée dans l\'éditeur thème personnalisé.',
			'themeEditor.editorDescription' => 'Choisissez une couleur de palette, ajustez son hue, sa saturation, sa luminosité ou l\'opacité et regardez la mise à jour prévisionnelle avant d\'économiser.',
			'search.hint' => 'Rechercher des films, des séries, de la musique...',
			'search.tryDifferentTerm' => 'Essayez un autre terme de recherche',
			'search.searchYourMedia' => 'Rechercher dans vos médias',
			'search.enterTitleActorOrKeyword' => 'Entrez un titre, un acteur ou un mot-clé',
			'search.people' => 'Personnes',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Définir un raccourci pour ${actionName}',
			'hotkeys.clearShortcut' => 'Effacer le raccourci',
			'hotkeys.noShortcutSet' => 'Aucun raccourci défini',
			'hotkeys.currentShortcut' => 'Raccourci actuel :',
			'hotkeys.pressToRecord' => 'Sélectionner pour enregistrer un raccourci',
			'hotkeys.recordingShortcut' => 'Appuyez maintenant sur le raccourci',
			'hotkeys.actions.playPause' => 'Lecture/Pause',
			'hotkeys.actions.volumeUp' => 'Augmenter le volume',
			'hotkeys.actions.volumeDown' => 'Baisser le volume',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avancer (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Reculer (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Basculer en mode plein écran',
			'hotkeys.actions.muteToggle' => 'Activer/désactiver le mode silencieux',
			'hotkeys.actions.subtitleToggle' => 'Activer/désactiver les sous-titres',
			'hotkeys.actions.audioTrackNext' => 'Piste audio suivante',
			'hotkeys.actions.subtitleTrackNext' => 'Piste de sous-titres suivante',
			'hotkeys.actions.chapterNext' => 'Chapitre suivant',
			'hotkeys.actions.chapterPrevious' => 'Chapitre précédent',
			'hotkeys.actions.episodeNext' => 'Épisode suivant',
			'hotkeys.actions.episodePrevious' => 'Épisode précédent',
			'hotkeys.actions.speedIncrease' => 'Augmenter la vitesse',
			'hotkeys.actions.speedDecrease' => 'Réduire la vitesse',
			'hotkeys.actions.speedReset' => 'Réinitialiser la vitesse',
			'hotkeys.actions.zoomIn' => 'Zoom avant',
			'hotkeys.actions.zoomOut' => 'Zoom arrière',
			'hotkeys.actions.zoomReset' => 'Réinitialiser le zoom',
			'hotkeys.actions.subSeekNext' => 'Rechercher le sous-titre suivant',
			'hotkeys.actions.subSeekPrev' => 'Rechercher le sous-titre précédent',
			'hotkeys.actions.subtitleDelayIncrease' => 'Retarder les sous-titres',
			'hotkeys.actions.subtitleDelayDecrease' => 'Avancer les sous-titres',
			'hotkeys.actions.shaderToggle' => 'Activer/désactiver les shaders',
			'hotkeys.actions.skipMarker' => 'Passer l\'intro/le générique',
			'hotkeys.actions.screenshot' => 'Prendre une capture d\'écran',
			'hotkeys.actions.framePrevious' => 'Précédent Frame',
			'hotkeys.actions.frameNext' => 'Le prochain cadre',
			'fileInfo.title' => 'Informations sur le fichier',
			'fileInfo.overview' => 'Aperçu',
			'fileInfo.video' => 'Vidéo',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Sous-titres',
			'fileInfo.images' => 'Images intégrées',
			'fileInfo.dataStreams' => 'Flux de données',
			'fileInfo.lyrics' => 'Paroles',
			'fileInfo.file' => 'Fichier',
			'fileInfo.attachments' => 'Pièces jointes',
			'fileInfo.delivery' => 'Diffusion',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Version ${index} sur ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Fichier ${index} sur ${count}',
			'fileInfo.noStreams' => 'Le serveur n\'a signalé aucun flux pour ce fichier.',
			'fileInfo.copyPath' => 'Copier le chemin',
			'fileInfo.pathCopied' => 'Chemin du fichier copié',
			'fileInfo.codec' => 'Codec',
			'fileInfo.codecTag' => 'Balise de codec',
			'fileInfo.resolution' => 'Résolution',
			'fileInfo.codedResolution' => 'Résolution codée',
			'fileInfo.bitrate' => 'Débit',
			'fileInfo.frameRate' => 'Fréquence d\'images',
			'fileInfo.rotation' => 'Rotation',
			'fileInfo.comment' => 'Commentaire',
			'fileInfo.audioDescription' => 'Audiodescription',
			'fileInfo.headerCompression' => 'Compression d\'en-tête',
			'fileInfo.sidecarFile' => 'Fichier annexe',
			'fileInfo.transportTimestamp' => 'Horodatage du transport',
			'fileInfo.displayOffset' => 'Décalage d\'affichage',
			'fileInfo.previewFailureCode' => 'Code d\'échec de l\'aperçu',
			'fileInfo.previewRetries' => 'Tentatives d\'aperçu',
			'fileInfo.aspectRatio' => 'Format d\'image',
			'fileInfo.pixelAspectRatio' => 'Rapport d\'aspect des pixels',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Niveau',
			'fileInfo.bitDepth' => 'Profondeur de bits',
			'fileInfo.pixelFormat' => 'Format de pixels',
			'fileInfo.colorSpace' => 'Espace colorimétrique',
			'fileInfo.colorRange' => 'Gamme de couleurs',
			'fileInfo.colorPrimaries' => 'Couleurs primaires',
			'fileInfo.colorTransfer' => 'Transfert de couleur',
			'fileInfo.chromaSubsampling' => 'Sous-échantillonnage chromatique',
			'fileInfo.chromaLocation' => 'Position du chroma',
			'fileInfo.scanType' => 'Type de balayage',
			'fileInfo.interlaced' => 'Entrelacé',
			'fileInfo.anamorphic' => 'Anamorphique',
			'fileInfo.referenceFrames' => 'Images de référence',
			'fileInfo.dynamicRange' => 'Plage dynamique',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Niveau Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Version Dolby Vision',
			'fileInfo.dolbyVisionLayers' => 'Couches Dolby Vision',
			'fileInfo.baseLayerCompatibility' => 'Compatibilité de la couche de base',
			'fileInfo.avcBitstream' => 'Flux binaire AVC',
			'fileInfo.nalLengthSize' => 'Taille de longueur NAL',
			'fileInfo.scalingMatrix' => 'Matrice de mise à l\'échelle personnalisée',
			'fileInfo.streamIdentifier' => 'Identifiant de flux',
			'fileInfo.streamIndex' => 'Index de flux',
			'fileInfo.streamId' => 'ID de flux',
			'fileInfo.language' => 'Langue',
			'fileInfo.languageCode' => 'Code de langue',
			'fileInfo.streamTitle' => 'Titre de la piste',
			'fileInfo.channels' => 'Canaux',
			'fileInfo.sampleRate' => 'Fréquence d\'échantillonnage',
			'fileInfo.spatialAudio' => 'Audio spatial',
			'fileInfo.textBased' => 'Basé sur du texte',
			'fileInfo.subtitleFormat' => 'Format annexe',
			'fileInfo.provider' => 'Fournisseur',
			'fileInfo.matchScore' => 'Score de correspondance',
			'fileInfo.externalDelivery' => 'Peut être diffusé séparément',
			'fileInfo.sidecarPath' => 'Chemin du fichier annexe',
			'fileInfo.sourceStream' => 'Copié depuis',
			'fileInfo.temporary' => 'Temporaire',
			'fileInfo.timeBase' => 'Base de temps',
			'fileInfo.overallBitrate' => 'Débit global',
			'fileInfo.path' => 'Chemin',
			'fileInfo.fileName' => 'Nom du fichier',
			'fileInfo.size' => 'Taille',
			'fileInfo.totalSize' => 'Taille totale',
			'fileInfo.container' => 'Conteneur',
			'fileInfo.duration' => 'Durée',
			'fileInfo.previewThumbnails' => 'Vignettes d\'aperçu',
			'fileInfo.previewIndex' => 'Index d\'aperçu',
			'fileInfo.packetLength' => 'Longueur du paquet',
			'fileInfo.filePresent' => 'Fichier présent',
			'fileInfo.fileReadable' => 'Lisible par le serveur',
			'fileInfo.streamPath' => 'Chemin du flux',
			'fileInfo.optimizedForStreaming' => 'Optimisé pour le streaming',
			'fileInfo.has64bitOffsets' => 'Décalages 64 bits',
			'fileInfo.protocol' => 'Protocole',
			'fileInfo.mediaType' => 'Type de média',
			'fileInfo.sourceKind' => 'Type de source',
			'fileInfo.optimizedVersion' => 'Version optimisée',
			'fileInfo.optimizationTarget' => 'Cible d\'optimisation',
			'fileInfo.deletedAt' => 'Supprimé',
			'fileInfo.remoteSource' => 'Source distante',
			'fileInfo.infiniteStream' => 'Flux infini',
			'fileInfo.directPlay' => 'Lecture directe',
			'fileInfo.directStream' => 'Flux direct',
			'fileInfo.transcoding' => 'Transcodage',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID de version',
			'fileInfo.fileId' => 'ID de fichier',
			'fileInfo.defaultAudioTrack' => 'Piste audio par défaut',
			'fileInfo.defaultSubtitleTrack' => 'Piste de sous-titres par défaut',
			'fileInfo.subtitlesOff' => 'Désactivés',
			'fileInfo.flagDefault' => 'Par défaut',
			'fileInfo.flagForced' => 'Forcé',
			'fileInfo.flagSelected' => 'Sélectionné',
			'fileInfo.flagExternal' => 'Externe',
			'fileInfo.flagHearingImpaired' => 'Sourds et malentendants',
			'fileInfo.flagDub' => 'Doublage',
			'fileInfo.flagOriginal' => 'Originale',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Marquer comme vu',
			'mediaMenu.markAsUnwatched' => 'Marquer comme non visionné',
			'mediaMenu.removeFromContinueWatching' => 'Supprimer de la liste "Continuer à regarder"',
			'mediaMenu.viewDetails' => 'Voir les détails',
			'mediaMenu.goToSeries' => 'Aller à la série',
			'mediaMenu.shufflePlay' => 'Lecture aléatoire',
			'mediaMenu.shuffleNotAvailableOffline' => 'La lecture aléatoire n’est pas disponible hors ligne',
			'mediaMenu.fileInfo' => 'Informations sur le fichier',
			'mediaMenu.deleteEpisodeFromServer' => 'Supprimer l\'épisode du serveur',
			'mediaMenu.deleteSeasonFromServer' => 'Supprimer la saison du serveur',
			'mediaMenu.deleteShowFromServer' => 'Supprimer la série du serveur',
			'mediaMenu.deleteMovieFromServer' => 'Supprimer le film du serveur',
			'mediaMenu.deleteEpisodeTitle' => 'Supprimer cet épisode ?',
			'mediaMenu.deleteSeasonTitle' => 'Supprimer cette saison ?',
			'mediaMenu.deleteShowTitle' => 'Supprimer cette série ?',
			'mediaMenu.deleteMovieTitle' => 'Supprimer ce film ?',
			'mediaMenu.deleteEpisodeConfirm' => 'Supprimer l\'épisode',
			'mediaMenu.deleteSeasonConfirm' => 'Supprimer la saison',
			'mediaMenu.deleteShowConfirm' => 'Supprimer la série',
			'mediaMenu.deleteMovieConfirm' => 'Supprimer le film',
			'mediaMenu.deleteAnyway' => 'Supprimer quand même',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Supprimer définitivement ${title} de votre serveur ?',
			'mediaMenu.deleteMultipleWarning' => 'Cela inclut tous les épisodes et leurs fichiers.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Cela supprime ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisode qu\'elle contient, ainsi que son fichier.', other: 'Cela supprime les ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisodes qu\'elle contient, ainsi que leurs fichiers.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Cet élément est stocké sous forme de ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fichier, qui sera supprimé.', other: 'Cet élément est stocké sur ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fichiers, et ils seront tous supprimés.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} autre épisode est stocké dans le même fichier et sera également supprimé :', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} autres épisodes sont stockés dans le même fichier et seront également supprimés :', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG n\'a pas pu vérifier quels fichiers seront supprimés ; il risque donc d\'en supprimer plus que l\'élément nommé ci-dessus. Annulez et réessayez, ou supprimez quand même.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Votre serveur n\'a pas fourni les détails du fichier pour cet élément, PlezyNG ne peut donc pas vérifier quels fichiers seront supprimés. Il risque d\'en supprimer plus que l\'élément nommé ci-dessus.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Élément média supprimé avec succès',
			'mediaMenu.mediaFailedToDelete' => 'Échec de la suppression de l\'élément média',
			'mediaMenu.rate' => 'Noter',
			'mediaMenu.playFromBeginning' => 'Lire depuis le début',
			'mediaMenu.playVersion' => 'Lire la version...',
			'rateSheet.title' => 'Noter',
			'rateSheet.server' => 'Serveur',
			'rateSheet.favorite' => 'Favori',
			'rateSheet.favorited' => 'Ajouté aux favoris',
			'rateSheet.saved' => 'Enregistré',
			'rateSheet.notAvailable' => 'Aucune correspondance trouvée',
			'rateSheet.noConnectedServices' => 'Connectez un service dans les paramètres pour pouvoir y attribuer une note.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, série TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visionné',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} pour cent visionné',
			'accessibility.mediaCardUnwatched' => 'non visionné',
			'accessibility.tapToPlay' => 'Appuyez pour lire',
			'accessibility.decrease' => 'Diminuer',
			'accessibility.increase' => 'Augmenter',
			'accessibility.decreaseValue' => ({required Object label}) => 'Diminuer ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Augmenter ${label}',
			'accessibility.hue' => 'Teinte',
			'accessibility.saturation' => 'Saturation',
			'accessibility.brightness' => 'Luminosité',
			'accessibility.hexColor' => 'Couleur hexadécimale',
			'accessibility.expandText' => 'Développer le texte',
			'accessibility.collapseText' => 'Replier le texte',
			'accessibility.alphabetNavigation' => 'Navigation alphabétique',
			'accessibility.alphabetScrollHint' => 'Balayez vers le haut ou le bas pour changer de lettre',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Ligne ${row} sur ${rowCount}, colonne ${column} sur ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Ligne ${row} sur ${rowCount}',
			'accessibility.autoScrollPlay' => 'Lancer le défilement automatique',
			'accessibility.autoScrollPause' => 'Suspendre le défilement automatique',
			'accessibility.hueShort' => 'T',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Rouge',
			'accessibility.green' => 'Grèce',
			'accessibility.blue' => 'Bleu',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Accessibilité',
			'accessibility.summary' => 'Text, contraste, mouvement et contrôles',
			'accessibility.systemHint' => 'Les paramètres d\'accessibilité de votre appareil s\'appliquent toujours. Ces options ajoutent des ajustements au cours de PlezyNG.',
			'accessibility.readability' => 'Lire et visibilité',
			'accessibility.textSize' => '- la taille du texte',
			'accessibility.preview' => 'Découvrez votre prochain article, lisez, écoutez et regardez à votre propre rythme.',
			'accessibility.boldText' => 'Interface courageux',
			'accessibility.highContrast' => 'Contraste élevé',
			'accessibility.highContrastHint' => 'Un texte plus fort, des outils et des indicateurs de concentration sur les surfaces lumineuses ou sombres.',
			'accessibility.interaction' => 'Motion et interaction',
			'accessibility.reduceMotion' => 'Réduire la motion',
			'accessibility.reduceMotionHint' => 'Arrêter les animations du repère de focus, les transitions de page et les effets décoratifs.',
			'accessibility.largeTargets' => 'Objectifs touchés',
			'accessibility.largeTargetsHint' => 'Donnez plus de place aux contrôles partagés pour la navigation touchante et assistante.',
			'accessibility.navigationHint' => 'Utilisez Tab et Shift+Tab pour passer d’une commande à l’autre, Enter ou la barre d’espace pour l’activer, et Escape ou Retour pour fermer. Le zoom et les préférences de lecture sont disponibles lorsqu’un livre est ouvert.',
			'accessibility.textSizeDescription' => 'Texte de l\'interface d\'échelle dans PlezyNG en plus de la configuration de taille du texte système de votre appareil.',
			'accessibility.boldTextHint' => 'Utilisez un poids plus lourd pour les étiquettes et les messages d’interface afin de les rendre plus faciles à distinguer.',
			'tooltips.shufflePlay' => 'Lecture aléatoire',
			'tooltips.playTrailer' => 'Lire la bande-annonce',
			'tooltips.markAsWatched' => 'Marquer comme vu',
			'tooltips.markAsUnwatched' => 'Marquer comme non vu',
			'audioTracks.track' => ({required Object n}) => 'Piste audio ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Sous-titres',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Format letterbox',
			'videoControls.fillScreen' => 'Remplir l’écran',
			'videoControls.stretch' => 'Étirer',
			'videoControls.lockRotation' => 'Verrouiller la rotation',
			'videoControls.unlockRotation' => 'Déverrouiller la rotation',
			'videoControls.timerActive' => 'Minuterie active',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'La lecture sera mise en pause dans ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Fin de la vidéo actuelle',
			'videoControls.sleepTimerStopAtHeader' => 'Arrêter à',
			'videoControls.sleepTimerDurationHeader' => 'Minuterie',
			'videoControls.playbackWillPauseAtEnd' => 'La lecture sera mise en pause à la fin de cette vidéo',
			'videoControls.stillWatching' => 'Toujours en train de regarder ?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pause dans ${seconds}s',
			'videoControls.continueWatching' => 'Continuer',
			'videoControls.autoPlayNext' => 'Lecture automatique de l’élément suivant',
			'videoControls.playNext' => 'Lire l\'épisode suivant',
			'videoControls.playButton' => 'Lire',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.playbackPaused' => 'En pause',
			'videoControls.playbackResumed' => 'En lecture',
			'videoControls.loadingVideo' => 'Chargement de la vidéo',
			'videoControls.showPlaybackControls' => 'Afficher les commandes de lecture',
			'videoControls.hidePlaybackControls' => 'Masquer les commandes de lecture',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Reculer de ${seconds} secondes',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avancer de ${seconds} secondes',
			'videoControls.previousButton' => 'Épisode précédent',
			'videoControls.nextButton' => 'Épisode suivant',
			'videoControls.previousChapterButton' => 'Chapitre précédent',
			'videoControls.nextChapterButton' => 'Chapitre suivant',
			'videoControls.muteButton' => 'Couper le son',
			'videoControls.unmuteButton' => 'Rétablir le son',
			'videoControls.settingsButton' => 'Paramètres de lecture',
			'videoControls.tracksButton' => 'Audio et sous-titres',
			'videoControls.chaptersButton' => 'Chapitres',
			'videoControls.versionQualityButton' => 'Version et qualité',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Qualité',
			'videoControls.qualityOriginal' => 'Originale',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodage indisponible — lecture en qualité originale',
			'videoControls.subtitleUnavailableFallback' => 'Impossible de charger les sous-titres sélectionnés — poursuite de la lecture sans sous-titres',
			'videoControls.pipButton' => 'Mode image dans l’image',
			'videoControls.aspectRatioButton' => 'Format d\'image',
			'videoControls.ambientLighting' => 'Éclairage ambiant',
			'videoControls.fullscreenButton' => 'Passer en mode plein écran',
			'videoControls.exitFullscreenButton' => 'Quitter le mode plein écran',
			'videoControls.alwaysOnTopButton' => 'Toujours au premier plan',
			'videoControls.rotationLockButton' => 'Verrouillage de rotation',
			_ => null,
		} ?? switch (path) {
			'videoControls.lockScreen' => 'Verrouiller l\'écran',
			'videoControls.screenLockButton' => 'Verrouillage de l\'écran',
			'videoControls.timelineSlider' => 'Barre de progression vidéo',
			'videoControls.volumeSlider' => 'Niveau du volume',
			'videoControls.endsAt' => ({required Object time}) => 'Se termine à ${time}',
			'videoControls.pipActive' => 'Lecture en mode image dans l\'image',
			'videoControls.pipFailed' => 'Échec du démarrage du mode image dans l\'image',
			'videoControls.screenshotSaved' => 'Capture d\'écran enregistrée',
			'videoControls.screenshotFailed' => 'Impossible de prendre une capture d’écran',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent} %',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volume ${percent} %',
			'videoControls.pipErrors.androidVersion' => 'Nécessite Android 8.0 ou plus récent',
			'videoControls.pipErrors.iosVersion' => 'Nécessite iOS 15.0 ou plus récent',
			'videoControls.pipErrors.permissionDisabled' => 'Le mode image dans l’image est désactivé. Activez-le dans les paramètres système.',
			'videoControls.pipErrors.notSupported' => 'Cet appareil ne prend pas en charge le mode image dans l\'image',
			'videoControls.pipErrors.voSwitchFailed' => 'Échec du changement de sortie vidéo pour l\'image dans l\'image',
			'videoControls.pipErrors.failed' => 'Échec du démarrage du mode image dans l\'image',
			'videoControls.pipErrors.prepareFailed' => 'Impossible de préparer le mode image dans l\'image',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Une erreur s\'est produite : ${error}',
			'videoControls.chapters' => 'Chapitres',
			'videoControls.noChaptersAvailable' => 'Aucun chapitre disponible',
			'videoControls.queue' => 'File d\'attente',
			'videoControls.noQueueItems' => 'Aucun élément dans la file d\'attente',
			'videoControls.noAudioDevicesAvailable' => 'Aucun appareil audio disponible',
			'videoControls.searchSubtitles' => 'Rechercher des sous-titres',
			'videoControls.language' => 'Langue',
			'videoControls.noSubtitlesFound' => 'Aucun sous-titre trouvé',
			'videoControls.subtitleDownloaded' => 'Sous-titre téléchargé',
			'videoControls.subtitleDownloadedNotApplied' => 'Le sous-titre a été téléchargé, mais n’a pas pu être sélectionné',
			'videoControls.subtitleDownloadFailed' => 'Échec du téléchargement du sous-titre',
			'videoControls.searchLanguages' => 'Rechercher des langues...',
			'videoControls.skipIntro' => 'Passer l’intro',
			'videoControls.skipCredits' => 'Passer le générique',
			'videoControls.nextEpisode' => 'Épisode suivant',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Piste ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Sous-titre ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (forcé)',
			'videoControls.osdSubtitlesOff' => 'Sous-titres : désactivés',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Sous-titres : ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio : ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} en ligne', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} écrans', ), 
			'videoControls.trackSelectionTitle' => 'Choisir les traces avant le playback',
			'videoControls.trackSelectionAuto' => 'Sélection automatique',
			'videoControls.openMiniPlayer' => 'Jeux mini ouverts',
			'videoControls.returnToFullPlayer' => 'Retour au joueur complet',
			'videoControls.loadSubtitleFile' => 'Réserver le sous-titre de fichier...',
			'videoControls.subtitleLoadFailed' => 'Faillite de télécharger le sous-titre',
			'videoControls.skipAds' => '- les ads',
			'videoControls.tapToUnlock' => 'Appuyez pour déverrouiller',
			'videoControls.tapAgainToUnlock' => 'Appuyez à nouveau pour déverrouiller',
			'videoControls.segmentLoopHelp' => 'Mettez A, puis définissez B plus tard dans la ligne de temps.',
			'videoControls.setLoopStart' => 'Démarrer le circuit (A)',
			'videoControls.setLoopEnd' => 'Mise à jour de la fin (B)',
			'videoControls.clearSegmentLoop' => 'Un segment clair',
			'videoControls.setLoopStartFirst' => 'Sélectionnez le début (A) avant la fin (B).',
			'videoControls.loopEndAfterStart' => 'La fin doit être plus tard que le début.',
			'videoControls.segmentLoopUnavailable' => 'Le segment looping n\'est pas disponible pour ce playback.',
			'videoControls.bookmarksHelp' => 'Les notes sont enregistrées sur ce appareil. Sélectionnez une pour aller à cette heure.',
			'videoControls.bookmarksButton' => 'Les Bookmarks',
			'videoControls.chaptersAndBookmarks' => 'Chapitres et bookmarks',
			'videoControls.segmentLoop' => 'Le Segment Loop',
			'videoControls.addBookmark' => 'Ajoutez le bookmark',
			'videoControls.bookmarkName' => 'Nom de Bookmark',
			'videoControls.bookmarkNameHint' => 'Par exemple, la scène d’ouverture',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Le Bookmark ${n}',
			'videoControls.bookmarkNameRequired' => 'Entrez un nom pour ce livre.',
			'videoControls.deleteBookmark' => 'Supprimer le bookmark',
			'videoControls.bookmarkLimitReached' => 'Cet article a déjà 100 bookmarks.',
			'videoControls.bookmarkUnavailable' => 'Je ne pouvais pas sauver ou supprimer cette note.',
			'videoControls.bookmarkSaved' => 'Le Bookmark est sauvé.',
			'videoControls.bookmarkDeleted' => 'Le Bookmark est supprimé.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Le point Loop ${point} Sélectionnez à ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'Aucun chapitre ou livre n\'est disponible.',
			'videoControls.loopPointNotSet' => 'Pas fixé',
			'messages.markedAsWatched' => 'Marqué comme vu',
			'messages.markedAsUnwatched' => 'Marqué comme non vu',
			'messages.markedAsWatchedOffline' => 'Marqué comme vu (se synchronisera lorsque vous serez en ligne)',
			'messages.markedAsUnwatchedOffline' => 'Marqué comme non vu (sera synchronisé lorsque vous serez en ligne)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Supprimé automatiquement : ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargement vu supprimé automatiquement', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargements vus supprimés automatiquement', ), 
			'messages.removedFromContinueWatching' => 'Supprimé de « Continuer à regarder »',
			'messages.errorLoading' => ({required Object error}) => 'Erreur : ${error}',
			'messages.searchPartialResults' => 'Certains serveurs multimédia n\'ont pas pu être interrogés. Affichage des résultats disponibles.',
			'messages.streamInterrupted' => 'La lecture a été interrompue. Appuyez sur Lecture ou avancez pour réessayer.',
			'messages.liveStreamInterrupted' => 'Le direct a été interrompu. Appuyez sur Lecture pour réessayer.',
			'messages.fileInfoNotAvailable' => 'Informations sur le fichier non disponibles',
			'messages.playbackAuthenticationRequired' => 'Reconnectez-vous au serveur multimédia pour lire cet élément.',
			'messages.playbackServerUnavailable' => 'Le serveur multimédia est indisponible. Réessayez plus tard.',
			'messages.playbackDataInvalid' => 'Le serveur a renvoyé des informations de lecture non valides.',
			'messages.playbackCancelled' => 'La lecture a été annulée.',
			'messages.playbackFailed' => 'Impossible de démarrer la lecture.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Impossible de démarrer la lecture : ${error}',
			'messages.audioOutputFailed' => 'La sortie audio a cessé de répondre. Vérifiez la connexion audio du téléviseur ou de l’ampli ; si les autres applications n’ont pas de son non plus, redémarrez l’appareil.',
			'messages.mediaUnavailable' => 'Ce contenu n’est plus disponible.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Erreur lors du chargement des informations sur le fichier : ${error}',
			'messages.errorLoadingSeries' => 'Erreur lors du chargement de la série',
			'messages.musicNotSupported' => 'La lecture de musique n\'est pas encore prise en charge',
			'messages.noDescriptionAvailable' => 'Aucune description disponible',
			'messages.noProfilesAvailable' => 'Aucun profil disponible',
			'messages.contactAdminForProfiles' => 'Contactez votre administrateur serveur pour ajouter des profils',
			'messages.unableToDetermineLibrarySection' => 'Impossible de déterminer la section de la bibliothèque pour cet élément',
			'messages.logsCleared' => 'Journaux effacés',
			'messages.logsCopied' => 'Journaux copiés dans le presse-papiers',
			'messages.noLogsAvailable' => 'Aucun journal disponible',
			'messages.libraryScanning' => ({required Object title}) => 'Analyse de « ${title} »…',
			'messages.libraryScanStarted' => ({required Object title}) => 'Analyse de la bibliothèque lancée pour « ${title} »',
			'messages.libraryScanFailed' => ({required Object error}) => 'Échec de l’analyse de la bibliothèque : ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Actualisation des métadonnées de « ${title} »…',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Actualisation des métadonnées lancée pour « ${title} »',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Échec de l’actualisation des métadonnées : ${error}',
			'messages.logoutConfirm' => 'Êtes-vous sûr de vouloir vous déconnecter ?',
			'messages.noSeasonsFound' => 'Aucune saison trouvée',
			'messages.seasonsLoadFailed' => 'Impossible de charger les saisons',
			'messages.noEpisodesFound' => 'Aucun épisode trouvé dans la première saison',
			'messages.noEpisodesFoundGeneral' => 'Aucun épisode trouvé',
			'messages.episodesLoadFailed' => 'Impossible de charger les épisodes',
			'messages.noResultsFound' => 'Aucun résultat trouvé',
			'messages.sleepTimerSet' => ({required Object label}) => 'Minuterie de mise en veille réglée sur ${label}',
			'messages.noItemsAvailable' => 'Aucun élément disponible',
			'messages.failedToCreatePlayQueueNoItems' => 'Impossible de créer la file d’attente de lecture : aucun élément',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Échec de ${action} : ${error}',
			'messages.switchingToCompatiblePlayer' => 'Passage au lecteur compatible...',
			'messages.serverLimitTitle' => 'Échec de la lecture',
			'messages.serverLimitBody' => 'Erreur serveur (HTTP 500). Une limite de bande passante/transcodage a probablement rejeté cette session. Demandez au propriétaire de l\'ajuster.',
			'messages.mediaUnreadableTitle' => 'Fichier indisponible',
			'messages.mediaUnreadableBody' => 'Le serveur a trouvé cet élément mais n\'a pas pu lire son fichier (HTTP 404). Le fichier a probablement été déplacé, supprimé, ou son stockage est hors ligne. Demandez au propriétaire du serveur de vérifier le fichier et de relancer l\'analyse de la bibliothèque.',
			'messages.serverBusyTitle' => 'Flux indisponible',
			'messages.serverBusyBody' => 'Le serveur a refusé à plusieurs reprises de diffuser ce fichier (HTTP 503). Il est peut-être en cours de redémarrage ou occupé, ou le stockage du fichier est peut-être hors ligne. Réessayez dans un instant. Si le problème persiste, demandez au propriétaire du serveur de vérifier le serveur et le stockage du fichier.',
			'messages.playbackNotAllowedTitle' => 'Lecture non autorisée',
			'messages.playbackNotAllowedBody' => 'Le serveur a refusé de diffuser cet élément (HTTP 403). Votre compte n\'a peut-être pas l\'autorisation de le lire, ou le serveur n\'autorise peut-être la lecture que sur son réseau local.',
			'messages.logsUploaded' => 'Journaux envoyés',
			'messages.logsUploadFailed' => 'Échec de l’envoi des journaux',
			'messages.logId' => 'Identifiant du journal',
			'messages.burnedSubtitlesUseMenu' => 'Les sous-titres sont incrustés à l’image de ce flux. Modifiez-les depuis le menu des sous-titres.',
			'messages.noVideoUrl' => 'Aucune URL vidéo disponible',
			'messages.playbackNoMediaSources' => 'Le serveur n’a renvoyé aucune source multimédia lisible',
			'messages.playbackDataNotPrepared' => 'La lecture a été lancée avant que les données nécessaires soient prêtes',
			'messages.streamSelectionUnavailable' => 'La sélection des flux n’est pas disponible pour cette source',
			'messages.streamSelectionFailed' => 'Impossible d’appliquer les flux sélectionnés',
			'messages.trackSelectionNotRemembered' => 'Ce choix de piste ne s’applique qu’à la lecture en cours.',
			'messages.serverUnavailableForProfile' => 'Aucun serveur n’est disponible pour le profil actif',
			'subtitlingStyling.previewSample' => 'Le fox brune rapide saute sur le chien laïc',
			'subtitlingStyling.text' => 'Texte',
			'subtitlingStyling.border' => 'Bordure',
			'subtitlingStyling.background' => 'Arrière-plan',
			'subtitlingStyling.fontSize' => 'Taille de la police',
			'subtitlingStyling.textColor' => 'Couleur du texte',
			'subtitlingStyling.borderSize' => 'Taille de la bordure',
			'subtitlingStyling.borderColor' => 'Couleur de la bordure',
			'subtitlingStyling.backgroundOpacity' => 'Opacité d\'arrière-plan',
			'subtitlingStyling.backgroundColor' => 'Couleur d\'arrière-plan',
			'subtitlingStyling.position' => 'Position',
			'subtitlingStyling.assOverride' => 'Remplacement ASS',
			'subtitlingStyling.overrideScale' => 'Mettre à l’échelle',
			'subtitlingStyling.overrideForce' => 'Forcer',
			'subtitlingStyling.overrideStrip' => 'Supprimer le style',
			'subtitlingStyling.positionTop' => 'Haut',
			'subtitlingStyling.positionBottom' => 'Bas',
			'subtitlingStyling.useMargins' => 'Utiliser les marges',
			'subtitlingStyling.useMarginsDescription' => 'Autoriser les sous-titres textuels dans l’espace en dehors de la vidéo. Les sous-titres stylés peuvent conserver leur position d’origine.',
			'subtitlingStyling.anchorToScreen' => 'Ancrer à l’écran',
			'subtitlingStyling.anchorToScreenDescription' => 'Afficher les sous-titres textuels dans les bandes noires sous les vidéos en écran large',
			'subtitlingStyling.bold' => 'Gras',
			'subtitlingStyling.italic' => 'Italique',
			'subtitlingStyling.renderResolution' => 'Résolution de rendu',
			'subtitlingStyling.renderResolutionScreen' => 'Résolution de l\'écran',
			'subtitlingStyling.renderResolutionVideo' => 'Résolution de la vidéo',
			'subtitlingStyling.fontSizeDescription' => 'Mettez la taille du texte sous-titre sur cet appareil.',
			'subtitlingStyling.textColorDescription' => 'Choisissez la couleur utilisée pour le texte sous-titre.',
			'subtitlingStyling.borderSizeDescription' => 'Mettez la profondeur de l\'outline autour du texte sous-titre.',
			'subtitlingStyling.borderColorDescription' => 'Choisissez la couleur utilisée pour le sous-titre.',
			'subtitlingStyling.backgroundColorDescription' => 'Choisissez la couleur derrière le texte sous-titre.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Définissez la transparence du fond de sous-titre : 0% est clair et 100% solide.',
			'subtitlingStyling.positionDescription' => 'Mouvez les sous-titres verticalement. 0% est le haut de la vidéo et 100% est le bas.',
			'subtitlingStyling.assOverrideDescription' => 'Choisissez si le joueur suit, ajuste, remplace ou supprime les styles intégrés dans les sous-titres ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Gardez les lettres, couleurs, tailles et placement écrit dans le fichier sous-titre.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Permettez aux paramètres de style du sous-titre du joueur d\'ajuster les sous-tits ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Appliquez le style de joueur et l\'échelle des tailles intégrées pour correspondre aux dimensions vidéo.',
			'subtitlingStyling.assOverrideOptions.force' => 'Remplacer les styles ASS intégrés avec le style sous-titre du joueur.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Supprimer le format ASS intégré et rendre clairement le texte sous-titre.',
			'subtitlingStyling.renderResolutionDescription' => 'Choisissez la résolution utilisée pour rasteriser l\'image et les sous-titres ASS. Les échelles Android inférieures peuvent réduire le travail de rendement mais ressembler plus doux.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render à la résolution de surface d\'affichage complète pour le résultat le plus épais.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render en utilisant la résolution vidéo comme référence, ce qui peut réduire le travail sur les écrans à haute résolution.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render à 75% de la résolution de surface d\'écran pour une économie modeste des performances.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render à 50% de la résolution de surface d\'affichage pour réduire le travail, avec des bords plus doux.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render à un tiers de la résolution de surface d\'affichage pour réduire le travail, avec des bords plus doux.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render à un quart de la résolution de surface d\'affichage pour réduire le travail, avec le résultat le plus doux.',
			'subtitlingStyling.boldDescription' => 'Tirez le texte sous-titre dans un poids plus lourd.',
			'subtitlingStyling.italicDescription' => 'Téléchargez le texte sous-titre en italien.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Paramètres avancés du lecteur vidéo',
			'mpvConfig.presets' => 'Préréglages',
			'mpvConfig.noPresets' => 'Aucun préréglage enregistré',
			'mpvConfig.saveAsPreset' => 'Enregistrer comme préréglage...',
			'mpvConfig.presetName' => 'Nom du préréglage',
			'mpvConfig.presetNameHint' => 'Entrez un nom pour ce préréglage',
			'mpvConfig.loadPreset' => 'Charger',
			'mpvConfig.deletePreset' => 'Supprimer',
			'mpvConfig.presetSaved' => 'Préréglage enregistré',
			'mpvConfig.presetLoaded' => 'Préréglage chargé',
			'mpvConfig.presetDeleted' => 'Préréglage supprimé',
			'mpvConfig.confirmDeletePreset' => 'Êtes-vous sûr de vouloir supprimer ce préréglage ?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Ajouter une ligne',
			'mpvConfig.removeLine' => 'Supprimer la ligne',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context et gpu-api sont ignorés sous Linux : la vidéo intégrée est toujours rendue via vo=libmpv sur le plan vidéo, et gpu-next (dont les shaders de calcul comme ArtCNN ont besoin) ne peut pas fonctionner en mode intégré.',
			'dialog.confirmAction' => 'Confirmer l\'action',
			'profiles.addPlezyProfile' => 'Ajouter un profil PlezyNG',
			'profiles.switchingProfile' => 'Changement de profil…',
			'profiles.deleteThisProfileTitle' => 'Supprimer ce profil ?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Supprimer ${displayName}. Les connexions ne sont pas affectées.',
			'profiles.active' => 'Actif',
			'profiles.manage' => 'Gérer',
			'profiles.delete' => 'Supprimer',
			'profiles.signOut' => 'Se déconnecter',
			'profiles.signOutPlexTitle' => 'Se déconnecter de Plex ?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Supprimer ${displayName} et tous les utilisateurs Plex Home ? Reconnexion possible à tout moment.',
			'profiles.signOutPlexDeleteDownloads' => 'Supprimer aussi les téléchargements',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Sinon, ils restent sur cet appareil et réapparaissent lorsque vous vous reconnectez à ce compte.',
			'profiles.signedOutPlex' => 'Déconnecté de Plex.',
			'profiles.signOutFailed' => 'Échec de la déconnexion.',
			'profiles.sectionTitle' => 'Profils',
			'profiles.summarySingle' => 'Ajoutez des profils pour mélanger utilisateurs gérés et identités locales',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profils · actif : ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profils',
			'profiles.removeConnectionTitle' => 'Retirer la connexion ?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Supprimer l\'accès de ${displayName} à ${connectionLabel}. Les autres profils le conservent.',
			'profiles.deleteProfileTitle' => 'Supprimer le profil ?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Supprimer ${displayName} et ses connexions. Les serveurs restent disponibles.',
			'profiles.profileNameLabel' => 'Nom du profil',
			'profiles.pinProtectionLabel' => 'Protection par code PIN',
			'profiles.copyAutomationLink' => 'Copie Android liens d\'automatisation',
			'profiles.copyAutomationLinkDescription' => 'Sélectionnez ce profil à partir d\'une intention ou d\'automatisation Android.',
			'profiles.automationLinkCopied' => 'Le lien de profil automatique est copié.',
			'profiles.pinManagedByPlex' => 'PIN géré par Plex. Modifier sur plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Aucun PIN défini. Pour en exiger un, modifiez l\'utilisateur Home sur plex.tv.',
			'profiles.setPin' => 'Définir un PIN',
			'profiles.setPinTitle' => 'Définir un PIN',
			'profiles.confirmPinTitle' => 'Confirmer le PIN',
			'profiles.pinSet' => 'PIN défini',
			'profiles.changePin' => 'Modifier',
			'profiles.removePin' => 'Retirer',
			'profiles.connectionsLabel' => 'Connexions',
			'profiles.add' => 'Ajouter',
			'profiles.deleteProfileButton' => 'Supprimer le profil',
			'profiles.noConnectionsHint' => 'Aucune connexion — ajoutez-en une pour utiliser ce profil.',
			'profiles.noConnections' => 'Aucune connexion',
			'profiles.plexHomeAccount' => 'Compte Plex Home',
			'profiles.plexAccountChip' => ({required Object account}) => 'Compte Plex : ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} via ${account}',
			'profiles.connectionDefault' => 'Par défaut',
			'profiles.connectionAs' => ({required Object displayName}) => 'en tant que ${displayName}',
			'profiles.makeDefault' => 'Définir par défaut',
			'profiles.removeConnection' => 'Retirer',
			'profiles.profileRenamed' => 'Profil renommé.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Ajouter à ${displayName}',
			'profiles.borrowExplain' => 'Emprunter la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.',
			'profiles.borrowEmpty' => 'Rien à emprunter pour le moment.',
			'profiles.borrowEmptySubtitle' => 'Connectez d\'abord Plex, Jellyfin ou Emby à un autre profil.',
			'profiles.borrowLoadFailed' => 'Impossible de charger les connexions disponibles. Réessayez.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'De ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Connexion empruntée.',
			'profiles.borrowFailed' => 'Impossible d\'emprunter la connexion.',
			'profiles.incorrectPin' => 'PIN incorrect.',
			'profiles.incorrectPinTryAgain' => 'PIN incorrect. Veuillez réessayer.',
			'profiles.sourceProfileMissingParentAccount' => 'Le profil source ne possède pas de compte parent.',
			'profiles.failedToLoadHomeUsers' => 'Impossible de charger vos utilisateurs Plex Home. Vérifiez votre connexion et réessayez.',
			'profiles.failedToVerifyPin' => 'Impossible de vérifier le PIN.',
			'profiles.newProfile' => 'Nouveau profil',
			'profiles.profileNameHint' => 'ex. Invités, Enfants, Salon familial',
			'profiles.pinProtectionOptional' => 'Protection par PIN (optionnelle)',
			'profiles.pinExplain' => 'PIN à 4 chiffres requis pour changer de profil.',
			'profiles.continueButton' => 'Continuer',
			'profiles.pinsDontMatch' => 'Les PIN ne correspondent pas',
			'profiles.tokenIdentityMismatch' => 'Le jeton du profil Plex correspond à un serveur inattendu',
			'profiles.settingsLocked' => 'Les paramètres sont bloqués pour ce profil.',
			'profiles.unlockSettings' => 'Débarquer les paramètres',
			'profiles.showExploreForProfile' => 'Afficher Explorez pour ce profil',
			'profiles.showExploreForProfileDescription' => 'Désactivez pour supprimer Explore de la navigation de ce profil.',
			'connections.sectionTitle' => 'Connexions',
			'connections.addConnection' => 'Ajouter une connexion',
			'connections.addConnectionSubtitleNoProfile' => 'Connectez-vous avec Plex ou connectez un serveur Jellyfin ou Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Ajouter à ${displayName} : Plex, Jellyfin, Emby ou une autre connexion de profil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Session expirée pour ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Session expirée pour ${count} serveurs',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} a refusé l\'accès à ce compte',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} serveurs ont refusé l\'accès à ce compte',
			'connections.signInAgain' => 'Se reconnecter',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Modifier la connexion ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Ajoutez ou retirez des URL pour ${serverName}. PlezyNG utilisera l\'URL joignable avec la latence la plus faible.',
			'accountPreferences.sectionTitle' => 'Préférences du compte',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${count} comptes',
			'accountPreferences.pickAccount' => 'Chaque compte enregistre ses propres préférences. Choisissez celui à modifier.',
			'accountPreferences.storedOnAccount' => 'Ces options sont enregistrées sur le compte lui-même : toutes les applications connectées les utilisent, y compris PlezyNG sur vos autres appareils.',
			'accountPreferences.noAccounts' => 'Aucun compte à configurer',
			'accountPreferences.noAccountsHint' => 'Connectez-vous à Plex, ou connectez un serveur Jellyfin ou Emby : les préférences enregistrées sur ce compte apparaîtront ici.',
			'accountPreferences.unavailable' => 'Impossible de joindre ce compte',
			'accountPreferences.loadFailed' => 'Impossible de charger ces préférences',
			'accountPreferences.noPreference' => 'Aucune préférence',
			'accountPreferences.notSet' => 'Non défini',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio et sous-titres',
			'accountPreferences.groups.libraryDisplay' => 'Bibliothèque',
			'accountPreferences.groups.personalMedia' => 'Médias personnels',
			'accountPreferences.preferredAudioLanguage' => 'Langue audio préférée',
			'accountPreferences.autoSelectAudio' => 'Choisir l\'audio par langue',
			'accountPreferences.autoSelectAudioDescription' => 'Désactivé : la piste audio marquée par défaut dans le fichier est conservée.',
			'accountPreferences.preferredSubtitleLanguage' => 'Langue de sous-titres préférée',
			'accountPreferences.subtitleMode' => 'Activer les sous-titres',
			'accountPreferences.subtitleModes.none' => 'Sélection manuelle',
			'accountPreferences.subtitleModes.noneDescription' => 'Ne jamais activer les sous-titres automatiquement.',
			'accountPreferences.subtitleModes.defaultMode' => 'Suivre les indicateurs des pistes',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Utiliser les indicateurs par défaut et forcés enregistrés sur chaque piste de sous-titres.',
			'accountPreferences.subtitleModes.always' => 'Toujours activé',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Activer une piste de sous-titres dans la langue préférée lorsqu\'elle existe.',
			'accountPreferences.subtitleModes.onlyForced' => 'Sous-titres forcés uniquement',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Charger uniquement les pistes marquées comme forcées.',
			'accountPreferences.subtitleModes.smart' => 'Avec l\'audio en langue étrangère',
			'accountPreferences.subtitleModes.smartDescription' => 'Activer les sous-titres uniquement lorsque l\'audio est dans une autre langue.',
			'accountPreferences.subtitleAccessibility' => 'Sous-titres SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Préférer les sous-titres non SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Préférer les sous-titres SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Sous-titres SDH uniquement',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Sous-titres non SDH uniquement',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Préférez les sous-titres standard lorsque les versions standard et SDH sont disponibles.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Je préfère les sous-titres SDH quand ils sont disponibles, mais permettent des sous-tits standard en tant que fallback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Utilisez uniquement les sous-titres SDH ; ne retournez pas aux sous-tits standard.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Utilisez uniquement les sous-titres standard ; excluez les sous‐titres SDH.',
			'accountPreferences.forcedSubtitles' => 'Sous-titres forcés',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Préférer les sous-titres non forcés',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Préférer les sous-titres forcés',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Sous-titres forcés uniquement',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Sous-titres non forcés uniquement',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Il préfère les sous-titres réguliers, mais permet des traces forcées comme une baisse.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Préférez les traces forcées lorsqu’elles sont disponibles, mais permettez des sous-titres réguliers en tant que recul.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Utilisez uniquement les traces marquées comme forcées.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Éliminer les traces marquées comme forcées.',
			'accountPreferences.displayMissingEpisodes' => 'Afficher les épisodes manquants',
			'accountPreferences.displayMissingEpisodesDescription' => 'Répertorier les épisodes connus du serveur mais sans fichier.',
			'accountPreferences.hidePlayedInLatest' => 'Masquer les éléments vus dans « Récemment ajouté »',
			'accountPreferences.hidePlayedInLatestDescription' => 'Exclure les éléments déjà vus des lignes « Récemment ajouté » du serveur.',
			'accountPreferences.displayCollectionsView' => 'Afficher la vue Collections',
			'accountPreferences.displayCollectionsViewDescription' => 'Proposer la vue Collections du serveur en plus de vos bibliothèques.',
			'accountPreferences.rewatchingInNextUp' => 'Conserver les séries revues dans « À suivre »',
			'accountPreferences.rewatchingInNextUpDescription' => 'Une fois une série terminée, si vous la recommencez, « À suivre » suit le revisionnage au lieu de la retirer.',
			'accountPreferences.watchedIndicator' => 'Indicateurs de visionnage',
			'accountPreferences.watchedIndicatorOptions.none' => 'Jamais',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Films et séries TV',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Films uniquement',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Séries TV uniquement',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'N’affichez pas les signes de contrôle observés.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Afficher les marques de vérification pour les films et les émissions télévisées.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Afficher les marques d\'attente pour les films uniquement.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Afficher les marques de vérification pour les émissions télévisées uniquement.',
			'accountPreferences.mediaReviewsVisibility' => 'Notes et critiques',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Utilisateurs et critiques',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Utilisateurs uniquement',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Critiques uniquement',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Masquées',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Afficher les notations des utilisateurs et les notes critiques.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Afficher les évaluations et les avis présentés par les utilisateurs.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Afficher les évaluations critiques et les avis.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Cache les notes et les critiques.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Préférez les traces audio dans cette langue lorsque le serveur ou le joueur sélectionne automatiquement une piste.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Préférez les traces de sous-titres dans cette langue lorsque les sous-tits sont sélectionnés automatiquement.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Choisissez si les captions SDH sont préférées ou requises lors de la sélection automatique des sous-titres.',
			'accountPreferences.forcedSubtitleDescription' => 'Choisissez si les traces de sous-titres forcés sont préférées ou requises lors de la sélection automatique.',
			'accountPreferences.watchedIndicatorDescription' => 'Choisissez quels types de médias reçoivent un signe d\'attente dans l\'interface du serveur.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Choisissez quel public et quelles notations critiques le serveur affiche sur les pages de médias.',
			'accountPreferences.subtitleModeDescription' => 'Choisissez quand les sous-titres s\'affichent automatiquement pour ce compte serveur.',
			'accountPreferences.hubDescription' => 'Ces préférences sont stockées sur votre compte de serveur médiatique et peuvent s\'appliquer également à d\'autres clients.',
			'discover.title' => 'Découvrir',
			'discover.noContentAvailable' => 'Aucun contenu disponible',
			'discover.addMediaToLibraries' => 'Ajoutez des médias à vos bibliothèques',
			'discover.continueWatching' => 'Continuer à regarder',
			'discover.continueWatchingIn' => ({required Object library}) => 'Continuer à regarder dans ${library}',
			'discover.nextUp' => 'À suivre',
			'discover.nextUpIn' => ({required Object library}) => 'À suivre dans ${library}',
			'discover.recentlyAdded' => 'Récemment ajouté',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Récemment ajouté dans ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Derniers albums dans ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Récemment lus dans ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Les plus lus dans ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Aperçu',
			'discover.cast' => 'Distribution',
			'discover.findNext.title' => 'Votre prochaine découverte',
			'discover.findNext.open' => 'Votre prochaine découverte',
			'discover.findNext.anyTime' => 'Sans limite de temps',
			'discover.findNext.timeAvailable' => 'De combien de temps disposez-vous ?',
			'discover.findNext.filters' => 'Choisissez selon le moment',
			'discover.findNext.watch' => 'Regarder',
			'discover.findNext.listen' => 'Écouter',
			'discover.findNext.read' => 'Lire',
			'discover.findNext.finishable' => ({required Object duration}) => 'Vous pouvez finir en ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Environ ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Chapitre suivant · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} au total',
			'discover.findNext.timingVaries' => 'La durée peut varier',
			'discover.findNext.notNow' => 'Pas maintenant',
			'discover.findNext.swipeHint' => 'Faites glisser la couverture vers une flèche ou utilisez les boutons ci-dessous.',
			'discover.findNext.saved' => 'Suggestions enregistrées',
			'discover.findNext.savedCount' => ({required Object count}) => 'Suggestions enregistrées · ${count}',
			'discover.findNext.undo' => 'Annuler',
			'discover.findNext.details' => 'Détails',
			'discover.findNext.noPicks' => 'Rien à choisir pour le moment',
			'discover.findNext.noPicksHint' => 'Connectez une bibliothèque ou ajoutez une source de médias pour commencer.',
			'discover.findNext.noMatches' => 'Rien ne convient pour le moment',
			'discover.findNext.noMatchesHint' => 'Essayez un autre type de contenu ou accordez-vous plus de temps.',
			'discover.findNext.allDone' => 'Vous avez vu toutes les suggestions',
			'discover.findNext.allDoneHint' => 'Lancez une nouvelle sélection pour revoir ces suggestions.',
			'discover.findNext.refresh' => 'Trouver une autre sélection',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Depuis ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Depuis ${library}',
			'discover.findNext.ownedReason' => 'Dans votre bibliothèque',
			'discover.findNext.liveNow' => 'En cours de diffusion',
			'discover.findNext.watchLive' => 'Regarder en direct',
			'discover.findNext.filterAnything' => 'Tous les types',
			'discover.findNext.filterWatch' => 'Regarder',
			'discover.findNext.filterListen' => 'Écouter',
			'discover.findNext.filterRead' => 'Lire',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Appliquer',
			'discover.findNext.openFailed' => 'Ce choix n’est plus disponible. Actualisez pour vérifier à nouveau.',
			'discover.findNext.changeFailed' => 'Impossible d’enregistrer ce changement. Réessayez.',
			'discover.findNext.savedLimit' => 'La liste des suggestions enregistrées est pleine. Retirez une suggestion pour en enregistrer une autre.',
			'discover.findNext.chooseHint' => 'Ouvrez un titre, gardez-le pour plus tard ou passez au suivant.',
			'discover.findNext.howItWorks' => 'Comment ça marche',
			'discover.findNext.notNowHelp' => 'Passez ce titre pour le moment. Il reste dans votre bibliothèque.',
			'discover.findNext.saveHelp' => 'Gardez-le dans les sélections enregistrées de ce profil sur cet appareil. Cela ne le télécharge pas.',
			'discover.findNext.openHelp' => 'Sélectionnez la couverture pour afficher les détails. Utilisez l’action principale pour lancer, lire ou ouvrir le titre.',
			'discover.findNext.controlsHelp' => 'Clavier ou télécommande : sélectionnez un bouton, puis appuyez sur Entrée ou Sélectionner. Annuler rétablit votre dernier choix.',
			'discover.findNext.artworkLoading' => 'Chargement de l’illustration…',
			'discover.findNext.artworkUnavailable' => 'Illustration indisponible',
			'discover.findNext.savedFeedback' => 'Ajouté aux sélections enregistrées',
			'discover.findNext.skippedFeedback' => 'Ignoré pour le moment',
			'discover.findNext.releaseToConfirm' => 'Relâchez pour confirmer',
			'discover.findNext.remoteHint' => 'Couverture sélectionnée : ← / → choisir · Sélectionner : détails · ↑ / ↓ : déplacer la sélection',
			'discover.extras' => 'Bandes-annonces et bonus',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Évaluation',
			'discover.director' => 'Réalisateur',
			'discover.directors' => 'Réalisateurs',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Série TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'discover.moreLikeThis' => 'Plus de contenus similaires',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titre', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titres', ), 
			'discover.person.born' => 'Naissance',
			'discover.person.died' => 'Décès',
			'discover.person.birthplace' => 'Lieu de naissance',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} ans)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (à ${age} ans)',
			'errors.searchFailed' => ({required Object error}) => 'Échec de la recherche : ${error}',
			'errors.searchUnavailable' => 'La recherche n\'a pu atteindre aucun serveur multimédia.',
			'errors.connectionTimeout' => ({required Object context}) => 'Délai d\'attente de connexion dépassé pendant le chargement ${context}',
			'errors.connectionFailed' => 'Impossible de se connecter au serveur multimédia',
			'errors.unableToLoad' => ({required Object context}) => 'Impossible de charger ${context}. Réessayez.',
			'errors.noClientAvailable' => 'Aucun client disponible',
			'errors.pleaseEnterToken' => 'Veuillez saisir un jeton',
			'errors.invalidToken' => 'Jeton non valide',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Échec de la vérification du jeton : ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Impossible de changer de profil vers ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Impossible de supprimer ${displayName}',
			'errors.failedToRate' => 'Impossible de mettre à jour la note',
			'errors.reasonTimedOut' => 'le délai d\'attente de la connexion a été dépassé',
			'errors.reasonUnreachable' => 'le serveur n\'a pas pu être atteint',
			'errors.reasonRefused' => 'le serveur a refusé la requête',
			'errors.reasonNotFound' => 'l\'élément ne se trouve plus sur le serveur',
			'errors.reasonServerError' => 'le serveur a signalé une erreur',
			'errors.reasonCancelled' => 'la requête a été annulée',
			'errors.reasonUnexpected' => 'une erreur inattendue s\'est produite',
			'libraries.playRandomMovie' => 'Jouer un film aléatoire',
			'libraries.randomPickFailed' => 'Je ne pouvais pas choisir un film de cette bibliothèque.',
			'libraries.title' => 'Bibliothèques',
			'libraries.fallbackTitle' => 'Bibliothèque',
			'libraries.scanLibraryFiles' => 'Scanner les fichiers de la bibliothèque',
			'libraries.scanLibrary' => 'Scanner la bibliothèque',
			'libraries.analyze' => 'Analyser',
			'libraries.analyzeLibrary' => 'Analyser la bibliothèque',
			'libraries.refreshMetadata' => 'Actualiser les métadonnées',
			'libraries.emptyTrash' => 'Vider la corbeille',
			'libraries.emptyingTrash' => ({required Object title}) => 'Vidage de la corbeille de « ${title} »…',
			'libraries.trashEmptied' => ({required Object title}) => 'Corbeille vidée pour « ${title} »',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Échec du vidage de la corbeille : ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyse de « ${title} »…',
			'libraries.analysisStarted' => ({required Object title}) => 'Analyse lancée pour « ${title} »',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Échec de l’analyse de la bibliothèque : ${error}',
			'libraries.noLibrariesFound' => 'Aucune bibliothèque trouvée',
			'libraries.allLibrariesHidden' => 'Toutes les bibliothèques sont masquées',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliothèques masquées (${count})',
			'libraries.thisLibraryIsEmpty' => 'Cette bibliothèque est vide',
			'libraries.noItemsMatchFilters' => 'Aucun élément ne correspond aux filtres actifs',
			'libraries.resetFilters' => 'Réinitialiser les filtres',
			'libraries.all' => 'Tout',
			'libraries.clearAll' => 'Tout effacer',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Voulez-vous vraiment scanner « ${title} » ?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Voulez-vous vraiment analyser « ${title} » ?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Voulez-vous vraiment actualiser les métadonnées de « ${title} » ?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Voulez-vous vraiment vider la corbeille de « ${title} » ?',
			'libraries.manageLibraries' => 'Gérer les bibliothèques',
			'libraries.sort' => 'Trier',
			'libraries.sortBy' => 'Trier par',
			'libraries.filters' => 'Filtres',
			'libraries.confirmActionMessage' => 'Êtes-vous sûr de vouloir effectuer cette action ?',
			'libraries.showLibrary' => 'Afficher la bibliothèque',
			'libraries.hideLibrary' => 'Masquer la bibliothèque',
			'libraries.libraryOptions' => 'Options de bibliothèque',
			'libraries.content' => 'contenu de la bibliothèque',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'Sélectionner la bibliothèque',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtres (${count})',
			'libraries.noRecommendations' => 'Aucune recommandation disponible',
			'libraries.noCollections' => 'Aucune collection dans cette bibliothèque',
			'libraries.noFoldersFound' => 'Aucun dossier trouvé',
			'libraries.folders' => 'dossiers',
			'libraries.tabs.recommended' => 'Recommandé',
			'libraries.tabs.browse' => 'Parcourir',
			'libraries.tabs.collections' => 'Collections',
			'libraries.tabs.playlists' => 'Playlists',
			'libraries.groupings.title' => 'Regroupement',
			'libraries.groupings.all' => 'Tous',
			'libraries.groupings.movies' => 'Films',
			'libraries.groupings.shows' => 'Séries TV',
			'libraries.groupings.seasons' => 'Saisons',
			'libraries.groupings.episodes' => 'Épisodes',
			'libraries.groupings.artists' => 'Artistes',
			'libraries.groupings.albums' => 'Albums',
			'libraries.groupings.tracks' => 'Titres',
			'libraries.groupings.folders' => 'Dossiers',
			'libraries.filterCategories.genre' => 'Genre',
			'libraries.filterCategories.year' => 'Année',
			'libraries.filterCategories.contentRating' => 'Classification',
			'libraries.filterCategories.tag' => 'Étiquette',
			'libraries.filterCategories.unwatched' => 'Non vus',
			'libraries.filterCategories.unplayed' => 'Non lus',
			'libraries.filterCategories.favorites' => 'Favoris',
			'libraries.filterCategories.filePath' => 'Chemin du fichier',
			'libraries.sortLabels.title' => 'Titre',
			'libraries.sortLabels.dateAdded' => 'Date d\'ajout',
			'libraries.sortLabels.releaseDate' => 'Date de sortie',
			'libraries.sortLabels.rating' => 'Note',
			'libraries.sortLabels.communityRating' => 'Note communautaire',
			'libraries.sortLabels.criticRating' => 'Note critique',
			'libraries.sortLabels.userRating' => 'Note utilisateur',
			'libraries.sortLabels.datePlayed' => 'Date de lecture',
			'libraries.sortLabels.playCount' => 'Lectures',
			'libraries.sortLabels.productionYear' => 'Année de production',
			'libraries.sortLabels.runtime' => 'Durée',
			'libraries.sortLabels.officialRating' => 'Classification officielle',
			'libraries.sortLabels.premiereDate' => 'Date de première',
			'libraries.sortLabels.startDate' => 'Date de début',
			'libraries.sortLabels.airTime' => 'Heure de diffusion',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Aléatoire',
			'libraries.sortLabels.dateShared' => 'Date de partage',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Dernière date de diffusion',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Date d\'ajout du dernier épisode',
			'libraries.sortLabels.dateDownloaded' => 'Date de téléchargement',
			'libraries.sortLabels.size' => 'Taille',
			'libraries.sortLabels.library' => 'Bibliothèque',
			'libraries.advancedFilters.include' => 'Inclure',
			'libraries.advancedFilters.exclude' => 'Exclure',
			'libraries.advancedFilters.any' => 'Indifférent',
			'libraries.advancedFilters.yes' => 'Oui',
			'libraries.advancedFilters.no' => 'Non',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Sauf ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} sélectionné(s)',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} exclu(s)',
			'libraries.advancedFilters.searchValues' => 'Rechercher des valeurs',
			'libraries.advancedFilters.noValues' => 'Aucune valeur',
			'libraries.advancedFilters.matchContains' => 'Contient',
			'libraries.advancedFilters.matchNotContains' => 'Ne contient pas',
			'libraries.advancedFilters.matchIs' => 'Est',
			'libraries.advancedFilters.matchIsNot' => 'N’est pas',
			'libraries.advancedFilters.matchBeginsWith' => 'Commence par',
			'libraries.advancedFilters.matchEndsWith' => 'Se termine par',
			'libraries.advancedFilters.textHint' => 'Saisissez un texte',
			'libraries.advancedFilters.from' => 'De',
			'libraries.advancedFilters.to' => 'À',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} à ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} et plus',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Jusqu’à ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => '${count} derniers jours',
			'libraries.advancedFilters.dateLastYear' => '12 derniers mois',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Il y a plus de ${count} jours',
			'libraries.advancedFilters.dateOlderThanYear' => 'Il y a plus d’un an',
			'libraries.selection.selectItems' => 'Choisir les articles',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} sélectionné(s)',
			'libraries.selection.actions' => 'Actions de sélection',
			'libraries.selection.confirmDescendants' => 'Cela change tous les épisodes dans les spectacles et les saisons sélectionnés.',
			'libraries.selection.confirmUnwatched' => 'Cela efface aussi la progression de lecture des éléments sélectionnés.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Les articles sélectionnés : ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Les articles mis à jour : ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Mise à jour ${succeeded}; échoué ${failed}. les articles échoués restent sélectionnés.',
			'about.title' => 'À propos',
			'about.openSourceLicenses' => 'Licences libres',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'Un magnifique client Plex, Jellyfin et Emby pour Flutter',
			'about.viewLicensesDescription' => 'Afficher les licences des bibliothèques tierces',
			'about.privacyPolicy' => 'Politique de confidentialité',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Aucun serveur trouvé pour ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Échec du chargement des serveurs : ${error}',
			'serverSelection.noValidServers' => 'Aucun serveur utilisable n’a été trouvé sur ce compte',
			'hubDetail.title' => 'Titre',
			'hubDetail.releaseYear' => 'Année de sortie',
			'hubDetail.dateAdded' => 'Date d\'ajout',
			'hubDetail.rating' => 'Évaluation',
			'hubDetail.noItemsFound' => 'Aucun élément trouvé',
			'logs.clearLogs' => 'Effacer les journaux',
			'logs.copyLogs' => 'Copier les journaux',
			'logs.uploadLogs' => 'Envoyer les journaux',
			'logs.saveLogs' => 'Écrivez les logs à fichier',
			'logs.logsSaved' => ({required Object path}) => 'Les logs sauvés à ${path}',
			'logs.saveLogsFailed' => 'Je ne pouvais pas sauver le fichier de log.',
			'startup.failedTitle' => 'PlezyNG n\'a pas pu démarrer',
			'startup.failedBody' => 'Une erreur s\'est produite au démarrage. Les détails ci-dessous identifient la cause.',
			'startup.failedBodyRepairable' => 'Le fichier de paramètres enregistré de PlezyNG est endommagé et doit être reconstruit avant que PlezyNG ne puisse démarrer. Réessayer ne servira à rien — choisissez Réparer le stockage.',
			'startup.phaseLabel' => 'Étape',
			'startup.showDetails' => 'Afficher les détails',
			'startup.hideDetails' => 'Masquer les détails',
			'startup.copyDetails' => 'Copier les détails',
			'startup.detailsCopied' => 'Détails copiés dans le presse-papiers',
			'startup.uploadDetails' => 'Téléverser les détails',
			'startup.repairStorage' => 'Réparer le stockage',
			'startup.repairTitle' => 'Réparer les données stockées ?',
			'startup.repairBodyCommon' => 'Le fichier de paramètres de PlezyNG est endommagé et illisible. La réparation rétablit tous les paramètres par défaut.',
			'startup.repairBodyOneCredential' => 'Une connexion enregistrée est endommagée et illisible. La réparation ne supprime que celle-ci ; vos autres paramètres sont laissés intacts.',
			'startup.repairBodySignInsKept' => 'Vos serveurs et profils devraient rester connectés.',
			'startup.repairBodySignInsLost' => 'La clé qui protège vos connexions enregistrées ne peut pas être récupérée à partir de ce fichier ; vous devrez donc vous reconnecter à chaque serveur et profil. Rien sur votre serveur multimédia n\'est affecté.',
			'startup.repairBodySessionsUncertain' => 'Les trackers (MAL, AniList, Simkl, Trakt) et Seerr sont stockés séparément et peuvent ou non être conservés. PlezyNG vous indiquera exactement ce qu\'il a gardé.',
			'startup.repairConfirm' => 'Réparer',
			'startup.repairSucceeded' => 'Stockage réparé',
			'startup.repairNeedsRestart' => 'Stockage réparé — redémarrage requis',
			'startup.restartRequiredBody' => 'Vos données ont été réparées, mais PlezyNG doit redémarrer pour pouvoir les utiliser. Fermez PlezyNG puis rouvrez-le.',
			'startup.quitPlezy' => 'Quitter PlezyNG',
			'startup.repairFailed' => 'Échec de la réparation',
			'startup.repairKeptSignIns' => 'Vos serveurs et profils sont toujours connectés.',
			'startup.repairLostSignIns' => 'La clé qui protégeait vos connexions enregistrées n\'a pas pu être récupérée. Vous devrez vous reconnecter à chaque serveur et profil.',
			'startup.repairLostSessions' => 'Au moins une connexion à un tracker ou à Seerr a été perdue et devra être rétablie.',
			'startup.backupTitle' => 'Une copie du fichier endommagé a été conservée',
			'startup.backupWarning' => 'Elle contient vos identifiants de connexion. Ne la téléversez pas et ne la partagez pas.',
			'startup.deleteBackup' => 'Supprimer la copie',
			'startup.backupDeleted' => 'Copie supprimée.',
			'startup.previousFailureTitle' => 'PlezyNG n\'a pas réussi à démarrer la dernière fois',
			'licenses.relatedPackages' => 'Paquets associés',
			'licenses.license' => 'Licence',
			'licenses.licenseNumber' => ({required Object number}) => 'Licence ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licences',
			'navigation.libraries' => 'Bibliothèques',
			'navigation.downloads' => 'Téléchargements',
			'navigation.liveTv' => 'TV en direct',
			'navigation.explore' => 'Explorer',
			'explore.mdblistShelves.manage' => 'Gestion des plaques d\'exploration',
			'explore.mdblistShelves.manageDescription' => 'Choisissez et arrêtez des listes de votre compte MDBList',
			'explore.mdblistShelves.description' => 'Choisissez les listes de films et de télévision publiques de votre compte MDBList. Créez ou copiez les listes sur MDBList, puis refroîtez.',
			'explore.mdblistShelves.selected' => 'Les plaques sélectionnées',
			'explore.mdblistShelves.available' => 'Liste des comptes disponibles',
			'explore.mdblistShelves.noLists' => 'Aucune liste de films ou de télévision publique n\'est retournée. Créez ou copiez une liste sur MDBList, puis refaire.',
			'explore.mdblistShelves.displayName' => 'Nom de l\'affichage Shelf',
			'explore.mdblistShelves.nameHint' => 'Laissez blanche pour utiliser le nom de la liste source.',
			'explore.mdblistShelves.add' => 'Ajouter le shelf',
			'explore.mdblistShelves.save' => 'Sauver les chariots',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Mouvement ${title} en haut',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Mouvement ${title} en bas',
			'explore.mdblistShelves.unavailable' => 'Cette liste n\'est pas disponible. Retire ou supprimer son fil dans les paramètres.',
			'explore.mdblistShelves.rateLimited' => 'MDBList limite de demande atteint. veuillez retirer plus tard.',
			'explore.mdblistShelves.loadFailed' => 'Vous ne pouvez pas charger les plaques. vérifier votre connexion et retire.',
			'explore.mdblistShelves.saveFailed' => 'Je ne peux pas faire des étagères, veuillez vous retirer.',
			'explore.mdblistShelves.accountChanged' => 'Le compte ou le profil a changé. réouverture de ces paramètres.',
			'explore.mdblistShelves.settingsUnreadable' => 'Les panneaux sauvés ne peuvent pas être lues. Sélectionnez vos listes à nouveau pour remplacer ces paramètres.',
			'explore.title' => 'Explorer',
			'explore.selectSource' => 'Sélectionner la source',
			'explore.rows.watchlist' => 'Liste de suivi',
			'explore.rows.recommendedMovies' => 'Films recommandés',
			'explore.rows.recommendedShows' => 'Séries recommandées',
			'explore.rows.trendingMovies' => 'Films tendance',
			'explore.rows.trendingShows' => 'Séries tendance',
			'explore.rows.popularMovies' => 'Films populaires',
			'explore.rows.popularShows' => 'Séries populaires',
			'explore.rows.trendingAnime' => 'Animes tendance',
			'explore.rows.suggestedAnime' => 'Animes suggérés',
			'explore.rows.airingAnime' => 'Meilleurs animes en diffusion',
			'explore.rows.popularAnime' => 'Animes les plus populaires',
			'explore.rows.trending' => 'Tendances',
			'explore.rows.upcomingMovies' => 'Films à venir',
			'explore.rows.upcomingShows' => 'Séries à venir',
			'explore.status.airing' => 'En cours',
			'explore.status.ended' => 'Terminé',
			'explore.status.canceled' => 'Annulé',
			'explore.status.upcoming' => 'À venir',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisode', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} épisodes', ), 
			'explore.cast' => 'Distribution',
			'explore.characters' => 'Personnages',
			'explore.addToWatchlist' => 'Ajouter à la liste de suivi',
			'explore.removeFromWatchlist' => 'Retirer de la liste de suivi',
			'explore.addedToWatchlist' => 'Ajouté à la liste de suivi',
			'explore.removedFromWatchlist' => 'Retiré de la liste de suivi',
			'explore.watchlistUpdateFailed' => 'Impossible de mettre à jour la liste de suivi',
			'explore.watchlistNoMatch' => 'Impossible d’associer cet élément à une liste de suivi',
			'explore.notInLibrary' => 'Absent de votre bibliothèque',
			'explore.inTheseLibraries' => 'Dans ces bibliothèques',
			'explore.checkingLibrary' => 'Vérification de votre bibliothèque...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Impossible de vérifier ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveur', other: 'Impossible de vérifier ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} serveurs', ), 
			'explore.emptyTitle' => 'Rien ici pour l\'instant',
			'explore.emptyMessage' => ({required Object source}) => 'Les lignes de ${source} apparaîtront ici dès qu’elles contiendront des éléments.',
			'explore.searchHint' => ({required Object source}) => 'Rechercher dans ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Aucun résultat pour "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Recherchez des films et des séries sur ${source}.',
			'explore.searchFailed' => 'Échec de la recherche. Vérifiez votre connexion et réessayez.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} populaire',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} en diffusion',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} mieux noté',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} tendance',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} de ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} regardent',
			'explore.badge.available' => 'Disponible',
			'explore.badge.partiallyAvailable' => 'Partiellement disponible',
			'explore.badge.availableIn4k' => '4K disponible',
			'explore.badge.requested' => 'Demandé',
			'explore.badge.pendingApproval' => 'En attente d\'approbation',
			'explore.badge.processing' => 'En cours de traitement',
			'explore.badge.declined' => 'Refusé',
			'explore.badge.requestFailed' => 'Échec de la demande',
			'explore.badge.requested4k' => '4K demandé',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} saisons',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ép ${episode} dans ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Prochain dans ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ép',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ép',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} répertoriés',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} vus aujourd\'hui',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} vus cette semaine',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} vus ce mois-ci',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} vus cette année',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} spectateurs',
			'explore.stats.planning' => ({required Object n}) => '${n} prévoient de le regarder',
			'explore.stats.favorited' => ({required Object n}) => '${n} favoris',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} l\'ont abandonné',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commentaire', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} commentaires', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} votes',
			'explore.stats.watching' => ({required Object n}) => '${n} le regardent',
			'explore.stats.completed' => ({required Object n}) => '${n} l\'ont terminé',
			'explore.stats.onHold' => ({required Object n}) => '${n} en pause',
			'explore.stats.dropped' => ({required Object n}) => '${n} ont abandonné',
			'explore.season.winter' => 'Hiver',
			'explore.season.spring' => 'Printemps',
			'explore.season.summer' => 'Été',
			'explore.season.fall' => 'Automne',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'Court TV',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Spécial',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Musique',
			'explore.format.other' => 'Autre',
			'explore.sourceMaterial.original' => 'Original',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Roman',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Jeu',
			'explore.sourceMaterial.webComic' => 'Webcomic',
			'explore.sourceMaterial.musicRelease' => 'Musique',
			'explore.sourceMaterial.otherMedia' => 'Autre',
			'explore.creditRole.actor' => 'Acteur',
			'explore.creditRole.director' => 'Réalisateur',
			'explore.creditRole.writer' => 'Scénariste',
			'explore.creditRole.producer' => 'Producteur',
			'explore.creditRole.creator' => 'Créateur',
			'explore.creditRole.composer' => 'Compositeur',
			'explore.relation.prequel' => 'Préquelle',
			'explore.relation.sequel' => 'Suite',
			'explore.relation.sideStory' => 'Histoire parallèle',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Version alternative',
			'explore.relation.summary' => 'Résumé',
			'explore.relation.parentStory' => 'Histoire principale',
			'explore.relation.adaptation' => 'Adaptation',
			'explore.relation.other' => 'Lié',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Diffusé le ${day} à ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Diffusé le ${day} à ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Titre original',
			'explore.detail.alsoKnownAs' => 'Également connu sous',
			'explore.detail.studios' => 'Studios',
			'explore.detail.country' => 'Pays',
			'explore.detail.language' => 'Langue',
			'explore.detail.released' => 'Sorti',
			'explore.detail.physicalRelease' => 'En disque',
			'explore.detail.ended' => 'Terminé',
			'explore.detail.addedOn' => ({required Object date}) => 'Ajouté le ${date}',
			'explore.detail.yourRating' => 'Votre note',
			'explore.detail.budget' => 'Budget',
			'explore.detail.revenue' => 'Box-office',
			'explore.detail.contentAdvisory' => 'Recommandation d\'âge',
			'explore.detail.tags' => 'Étiquettes',
			'explore.detail.revealSpoilerTags' => 'Afficher les tags spoiler',
			'explore.detail.links' => 'Liens',
			'explore.detail.watchOn' => 'Regarder sur',
			'explore.detail.watchTrailer' => 'Regarder la bande-annonce',
			'explore.detail.openOn' => ({required Object site}) => 'Ouvrir sur ${site}',
			'explore.detail.crew' => 'Équipe',
			'explore.detail.ratings' => 'Notes',
			'explore.detail.schedule' => 'Programme',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Recommandé par ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utilisateur', other: 'Recommandé par ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} utilisateurs', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recommandé par ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Ajouté aux favoris par ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} pas encore diffusés',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recommandé par ${percent} des spectateurs',
			'explore.detail.relatedTitles' => 'Titres liés',
			'explore.detail.background' => 'Contexte',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résultat', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résultats', ), 
			'liveTv.title' => 'TV en direct',
			'liveTv.guide' => 'Guide',
			'liveTv.noChannels' => 'Aucune chaîne disponible',
			'liveTv.noDvr' => 'Aucun DVR configuré sur les serveurs',
			'liveTv.serverUnavailable' => 'Le serveur de TV en direct n’est pas disponible.',
			'liveTv.serverNotConnected' => 'Le serveur de TV en direct n’est pas connecté.',
			'liveTv.noPrograms' => 'Aucune donnée de programme disponible',
			'liveTv.liveStreamFailed' => 'Échec du direct',
			'liveTv.unknownProgram' => 'Programme inconnu',
			'liveTv.timelineLiveProgram' => 'Programme en direct (le jeu peut être hors du programme)',
			'liveTv.timelineBuffer' => 'Le timeline de buffer',
			'liveTv.timelineUnavailable' => 'L\'heure inexposable',
			'liveTv.timelineEstimated' => 'Le Playback évalué',
			'liveTv.timelinePending' => 'En attendant chercher',
			'liveTv.timelineStale' => 'Le calendrier peut être dépassé',
			'liveTv.unknownHub' => 'Inconnu',
			'liveTv.unknownError' => 'Erreur inconnue',
			'liveTv.channelNumber' => ({required Object number}) => 'Chaîne ${number}',
			'liveTv.unknownChannel' => 'Chaîne inconnue',
			'liveTv.live' => 'EN DIRECT',
			'liveTv.premiereBadge' => 'Nouveau',
			'liveTv.reloadGuide' => 'Recharger le guide',
			'liveTv.searchGuide' => 'Rechercher dans le guide',
			'liveTv.searchHint' => 'Rechercher des chaînes et des programmes',
			'liveTv.searchNoResults' => ({required Object query}) => 'Aucune correspondance pour "${query}"',
			'liveTv.channelsSection' => 'Chaînes',
			'liveTv.programsSection' => 'Programmes',
			'liveTv.now' => 'Maintenant',
			'liveTv.today' => 'Aujourd\'hui',
			'liveTv.tomorrow' => 'Demain',
			'liveTv.midnight' => 'Minuit',
			'liveTv.overnight' => 'Nuit',
			'liveTv.morning' => 'Matin',
			'liveTv.daytime' => 'Journée',
			'liveTv.evening' => 'Soirée',
			'liveTv.lateNight' => 'Fin de soirée',
			'liveTv.whatsOn' => 'En ce moment',
			'liveTv.watchChannel' => 'Regarder la chaîne',
			'liveTv.favorites' => 'Favoris',
			'liveTv.reorderFavorites' => 'Réorganiser les favoris',
			'liveTv.noFavoriteChannels' => 'Aucune chaîne favorite',
			'liveTv.noFavoriteChannelsHint' => 'Affichez toutes les chaînes, puis appuyez longuement sur une chaîne pour l’ajouter à vos favoris.',
			'liveTv.showAllChannels' => 'Afficher toutes les chaînes',
			'liveTv.favoritesLoadFailed' => 'Impossible de charger les favoris. Vérifiez votre connexion et réessayez.',
			'liveTv.favoritesUpdateFailed' => 'Impossible de mettre à jour les favoris. Vérifiez votre connexion et réessayez.',
			'liveTv.joinSession' => 'Rejoindre la session en cours',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Regarder depuis le début (il y a ${minutes} min)',
			'liveTv.watchLive' => 'Regarder en direct',
			'liveTv.goToLive' => 'Aller au direct',
			'liveTv.record' => 'Enregistrer',
			'liveTv.recordEpisode' => 'Enregistrer l\'épisode',
			'liveTv.recordSeries' => 'Enregistrer la série',
			'liveTv.recordOptions' => 'Options d\'enregistrement',
			'liveTv.saveTo' => 'Enregistrer dans',
			'liveTv.recordings' => 'Enregistrements',
			'liveTv.scheduledRecordings' => 'Programmés',
			'liveTv.recordingRules' => 'Règles d\'enregistrement',
			'liveTv.noScheduledRecordings' => 'Aucun enregistrement programmé',
			'liveTv.manageRecording' => 'Gérer l\'enregistrement',
			'liveTv.cancelRecording' => 'Annuler l\'enregistrement',
			'liveTv.cancelRecordingTitle' => 'Annuler cet enregistrement ?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} ne sera plus enregistré.',
			'liveTv.deleteRule' => 'Supprimer la règle',
			'liveTv.deleteRuleTitle' => 'Supprimer la règle d\'enregistrement ?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Les prochains épisodes de ${title} ne seront pas enregistrés.',
			'liveTv.recordingScheduled' => 'Enregistrement programmé',
			'liveTv.alreadyScheduled' => 'Ce programme est déjà programmé',
			'liveTv.dvrAdminRequired' => 'Les paramètres DVR nécessitent un compte administrateur',
			'liveTv.recordingFailed' => 'Impossible de programmer l\'enregistrement',
			'liveTv.recordingTargetMissing' => 'Impossible de déterminer la bibliothèque d\'enregistrement',
			'liveTv.recordNotAvailable' => 'Enregistrement non disponible pour ce programme',
			'liveTv.recordingCancelled' => 'Enregistrement annulé',
			'liveTv.recordingRuleDeleted' => 'Règle d\'enregistrement supprimée',
			'liveTv.processRecordingRules' => 'Réévaluer les règles',
			'liveTv.recordingInProgress' => 'Enregistrement en cours',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} programmés',
			'liveTv.editRule' => 'Modifier la règle',
			'liveTv.editRuleAction' => 'Modifier',
			'liveTv.recordingRuleUpdated' => 'Règle d\'enregistrement mise à jour',
			'liveTv.guideReloadRequested' => 'Mise à jour du guide demandée',
			'liveTv.guideReloadFailed' => 'Impossible d’actualiser le guide',
			'liveTv.rulesProcessRequested' => 'Réévaluation des règles demandée',
			'liveTv.rulesProcessFailed' => 'Impossible de réévaluer les règles d’enregistrement',
			'liveTv.recordShow' => 'Enregistrer l\'émission',
			'liveTv.recordSettings.startEarly' => 'Démarrer en avance (secondes)',
			'liveTv.recordSettings.endLate' => 'Terminer en retard (secondes)',
			'liveTv.recordSettings.newOnly' => 'Uniquement les nouveaux épisodes',
			'liveTv.recordSettings.anyChannel' => 'Enregistrer sur n’importe quelle chaîne',
			'liveTv.recordSettings.anyTime' => 'Enregistrer à n’importe quelle heure',
			'liveTv.recordSettings.skipInLibrary' => 'Ignorer les épisodes déjà présents dans la bibliothèque',
			'liveTv.recordSettings.keepUpTo' => 'Épisodes à conserver',
			'liveTv.recordSettings.keepUpToHint' => '0 conserve tous les épisodes',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Commence dans ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} à ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} a renvoyé des données de lecture de TV en direct non valides',
			'liveTv.failedToStartChannel' => 'Impossible de lancer la chaîne en direct',
			'liveTv.failedToBuildStreamUrl' => 'Impossible de générer l’URL du flux',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Impossible de démarrer la chaîne : ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Impossible de changer de chaîne : ${reason}',
			'collections.title' => 'Collections',
			'collections.collection' => 'Collection',
			'collections.empty' => 'La collection est vide',
			'collections.deleteCollection' => 'Supprimer la collection',
			'collections.deleteConfirm' => ({required Object title}) => 'Supprimer "${title}" ? Action irréversible.',
			'collections.deleted' => 'Collection supprimée',
			'collections.deleteFailed' => 'Échec de la suppression de la collection',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Échec de la suppression de la collection : ${error}',
			'collections.selectCollection' => 'Sélectionner une collection',
			'collections.collectionName' => 'Nom de la collection',
			'collections.enterCollectionName' => 'Entrez le nom de la collection',
			'collections.addedToCollection' => 'Ajouté à la collection',
			'collections.errorAddingToCollection' => 'Échec de l\'ajout à la collection',
			'collections.created' => 'Collection créée',
			'collections.removeFromCollection' => 'Supprimer de la collection',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Retirer "${title}" de cette collection ?',
			'collections.removedFromCollection' => 'Retiré de la collection',
			'collections.removeFromCollectionFailed' => 'Impossible de supprimer de la collection',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Erreur lors du retrait de la collection : ${error}',
			'collections.searchCollections' => 'Rechercher des collections...',
			'playlists.title' => 'Playlists',
			'playlists.playlist' => 'Playlist',
			'playlists.noPlaylists' => 'Aucune playlist trouvée',
			'playlists.create' => 'Créer une playlist',
			'playlists.playlistName' => 'Nom de playlist',
			'playlists.enterPlaylistName' => 'Saisissez le nom de la playlist',
			'playlists.delete' => 'Supprimer la playlist',
			'playlists.removeItem' => 'Retirer de la playlist',
			'playlists.smartPlaylist' => 'Playlist intelligente',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} élément', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} éléments', ), 
			'playlists.emptyPlaylist' => 'Cette playlist est vide',
			'playlists.deleteConfirm' => 'Supprimer la playlist ?',
			'playlists.deleteMessage' => ({required Object name}) => 'Voulez-vous vraiment supprimer « ${name} » ?',
			'playlists.created' => 'Playlist créée',
			'playlists.deleted' => 'Playlist supprimée',
			'playlists.itemAdded' => 'Ajouté à la playlist',
			'playlists.itemRemoved' => 'Retiré de la playlist',
			'playlists.selectPlaylist' => 'Sélectionner une playlist',
			'playlists.searchPlaylists' => 'Rechercher des playlists...',
			'playlists.errorCreating' => 'Échec de la création de la playlist',
			'playlists.errorDeleting' => 'Échec de la suppression de la playlist',
			'playlists.errorLoading' => 'Échec du chargement des playlists',
			'playlists.errorAdding' => 'Échec de l’ajout à la playlist',
			'playlists.errorReordering' => 'Échec de la réorganisation de l’élément de la playlist',
			'playlists.errorRemoving' => 'Échec du retrait de l’élément de la playlist',
			'music.goToAlbum' => 'Aller à l\'album',
			'music.goToArtist' => 'Aller à l\'artiste',
			'music.instantMix' => 'Mix instantané',
			'music.playNext' => 'Lire ensuite',
			'music.addToQueue' => 'Ajouter à la file d\'attente',
			'music.discNumber' => ({required Object n}) => 'Disque ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titre', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titres', ), 
			'music.nowPlaying' => 'Lecture en cours',
			'music.playingFrom' => ({required Object title}) => 'Lecture depuis ${title}',
			'music.queue' => 'File d\'attente',
			'music.clearQueue' => 'Vider la file d\'attente',
			'music.lyrics' => 'Paroles',
			'music.visualizer' => 'Visualisateur',
			'music.visualizerProfileLoading' => 'Lire la suite de Track Analysis...',
			'music.visualizerAmbientMotion' => 'Mouvement environnemental',
			'music.visualizerPlexLoudness' => 'Plex bruit',
			'music.visualizerPreviousPreset' => 'Précédent Style visuel',
			'music.visualizerNextPreset' => 'Suivant Style visuel',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Blonde',
			'music.visualizerPresetOrbitals' => 'Orbitale',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Le tunnel',
			'music.visualizerPresetTrackMap' => 'Track de la carte',
			'music.noLyrics' => 'Aucune parole disponible',
			'music.sleepTimer' => 'Minuterie de veille',
			'music.sleepTimerEndOfTrack' => 'Fin du titre',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minute', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes', ), 
			'music.stopPlayback' => 'Arrêter la lecture',
			'music.previousTrack' => 'Titre précédent',
			'music.nextTrack' => 'Titre suivant',
			'music.repeat' => 'Répéter',
			'music.repeatAll' => 'Tout répéter',
			'music.repeatOne' => 'Répéter le titre',
			'music.instantMixNoServer' => 'Aucun serveur n’est disponible pour créer un mix instantané',
			'music.instantMixFailed' => 'Impossible de charger le mix instantané',
			'music.instantMixEmpty' => 'Le mix instantané n\'a renvoyé aucun titre',
			'music.noAudioUrl' => ({required Object track}) => 'Aucune URL audio n’est disponible pour ${track}',
			'music.discography.singlesAndEps' => 'Singles et EP',
			'music.discography.live' => 'Live',
			'music.discography.compilations' => 'Compilations',
			'watchTogether.title' => 'Regarder ensemble',
			'watchTogether.description' => 'Regarder du contenu en synchronisation avec vos proches',
			'watchTogether.createRoom' => 'Créer un salon',
			'watchTogether.creatingRoom' => 'Création du salon...',
			'watchTogether.joinRoom' => 'Rejoindre un salon',
			'watchTogether.joiningRoom' => 'Connexion au salon...',
			'watchTogether.connecting' => 'Connexion...',
			'watchTogether.relayPublic' => 'Les salons utilisent les relais publics Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Les salons utilisent votre relais à l’adresse ${url}.',
			'watchTogether.recentRooms' => 'Salons récents',
			'watchTogether.roomActions' => 'Actions du salon',
			'watchTogether.renameRoom' => 'Renommer le salon',
			'watchTogether.removeRoom' => 'Supprimer',
			'watchTogether.enterRoomCode' => 'Saisissez le code à 6 caractères communiqué par l’hôte.',
			'watchTogether.roomCode' => 'Code du salon',
			'watchTogether.paste' => 'Coller',
			'watchTogether.noCodeInClipboard' => 'Le presse-papiers ne contient pas de code de salon',
			'watchTogether.copyCode' => 'Copier le code',
			'watchTogether.codeCopied' => 'Code du salon copié',
			'watchTogether.shareInvite' => 'Partager l’invitation',
			'watchTogether.inviteCopied' => 'Invitation copiée. Collez-la dans un message.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Rejoignez mon salon Regarder ensemble dans PlezyNG : ouvrez « Regarder ensemble », choisissez « Rejoindre un salon » et saisissez ${code}.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.openSessionControls' => 'Ouvrir les commandes de la session Regarder ensemble',
			'watchTogether.reconnecting' => 'Reconnexion...',
			'watchTogether.reconnectingDescription' => 'La connexion a été interrompue. Vous rejoindrez le salon automatiquement.',
			'watchTogether.connected' => 'Connecté',
			'watchTogether.disconnected' => 'Déconnecté',
			'watchTogether.youAreHost' => 'Vous êtes l\'hôte',
			'watchTogether.hostedBy' => ({required Object name}) => 'Hôte : ${name}',
			'watchTogether.hostControlsPlayback' => 'L\'hôte contrôle la lecture',
			'watchTogether.anyoneCanControl' => 'Tout le monde peut contrôler la lecture',
			'watchTogether.roomLocked' => 'Salon verrouillé',
			'watchTogether.nowPlaying' => 'En cours de lecture',
			'watchTogether.nothingPlaying' => 'Aucune lecture en cours',
			'watchTogether.nothingPlayingHost' => 'Lancez un contenu depuis n’importe quelle bibliothèque pour le partager avec le salon.',
			'watchTogether.nothingPlayingGuest' => 'Quand l’hôte lancera un contenu, il s’ouvrira ici.',
			'watchTogether.notShareable' => 'Cette vidéo n’a aucune correspondance dans le catalogue : seules les personnes ayant accès au même serveur peuvent la lire.',
			'watchTogether.searching' => 'Recherche de cette vidéo dans vos bibliothèques...',
			'watchTogether.yourCopy' => 'Votre copie',
			'watchTogether.sharingYourCopy' => 'Vous partagez votre copie',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Lecture de votre copie, ${difference}',
			'watchTogether.mismatchTitle' => 'Votre copie a une durée différente',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Votre copie la plus proche est ${difference} que la vidéo du salon. Il peut s’agir d’un autre montage ou d’une autre version.',
			'watchTogether.playAnyway' => 'Lire quand même',
			'watchTogether.chooseAnotherCopy' => 'Choisir une autre copie',
			'watchTogether.dontPlay' => 'Ne pas lire',
			'watchTogether.unavailableTitle' => 'Vous n’avez pas cette vidéo',
			'watchTogether.unavailableDescription' => 'PlezyNG ne l’a pas trouvée dans vos bibliothèques. Choisissez vous-même une copie ou relancez la recherche.',
			'watchTogether.chooseCopy' => 'Choisir une copie',
			'watchTogether.searchAgain' => 'Relancer la recherche',
			'watchTogether.noCandidates' => 'Aucune copie trouvée dans vos bibliothèques.',
			'watchTogether.choiceFailed' => 'Impossible de lire cette copie pour le salon',
			'watchTogether.lengthLonger' => ({required Object duration}) => 'plus longue de ${duration}',
			'watchTogether.lengthShorter' => ({required Object duration}) => 'plus courte de ${duration}',
			'watchTogether.lengthSame' => 'même durée',
			'watchTogether.lengthUnknown' => 'durée inconnue',
			'watchTogether.joinCurrentPlayback' => 'Rejoindre la lecture en cours',
			'watchTogether.joinCurrentPlaybackDescription' => 'Reprendre le contenu que l’hôte regarde actuellement',
			'watchTogether.stopMedia' => 'Arrêter la vidéo pour tout le monde',
			'watchTogether.syncOffset' => 'Décalage de synchronisation',
			'watchTogether.syncOffsetDescription' => 'Décalez votre vidéo si elle est en avance ou en retard sur le salon.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Votre copie est ${difference} que la vidéo du salon.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Appliquer ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Participants',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participant', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participants', ), 
			'watchTogether.hostBadge' => 'HÔTE',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (vous)',
			'watchTogether.playerIdle' => 'Inactif',
			'watchTogether.playerLoading' => 'Chargement',
			'watchTogether.playerReady' => 'Prêt',
			'watchTogether.playerBuffering' => 'Mise en tampon',
			'watchTogether.matchSearching' => 'Recherche en cours',
			'watchTogether.matchMatched' => 'Possède la vidéo',
			'watchTogether.matchMismatched' => 'Durée différente',
			'watchTogether.matchUnavailable' => 'Ne possède pas la vidéo',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Décalage ${offset}',
			'watchTogether.makeHost' => 'Nommer hôte',
			'watchTogether.makeHostQuestion' => 'Transférer le rôle d’hôte ?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} contrôlera la lecture et dirigera la session pour tout le monde.',
			'watchTogether.transfer' => 'Transférer',
			'watchTogether.removeParticipant' => 'Retirer du salon',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Retirer ${name} ?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} quittera le salon. Cette personne pourra revenir avec le code, sauf si vous verrouillez le salon.',
			'watchTogether.remove' => 'Retirer',
			'watchTogether.roomSettings' => 'Paramètres du salon',
			'watchTogether.letEveryoneControl' => 'Laisser tout le monde contrôler la lecture',
			'watchTogether.lockRoom' => 'Verrouiller le salon',
			'watchTogether.lockRoomDescription' => 'Aucun nouveau participant ne peut rejoindre le salon',
			'watchTogether.leaveRoom' => 'Quitter le salon',
			'watchTogether.leaveRoomQuestion' => 'Quitter le salon ?',
			'watchTogether.leaveRoomConfirm' => 'Vous pourrez revenir avec le code du salon.',
			'watchTogether.leave' => 'Quitter',
			'watchTogether.endRoom' => 'Fermer le salon',
			'watchTogether.endRoomQuestion' => 'Fermer le salon ?',
			'watchTogether.endRoomConfirm' => 'Le salon sera fermé pour tout le monde.',
			'watchTogether.end' => 'Terminer',
			'watchTogether.playBlockedTitle' => 'La lecture n’a pas démarré',
			'watchTogether.playBlockedDescription' => 'Appuyez sur Lecture pour commencer à regarder avec le salon.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} a lancé la lecture',
			'watchTogether.notices.playbackStarted' => 'Lecture lancée',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} a mis en pause',
			'watchTogether.notices.playbackPaused' => 'Lecture en pause',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} a sauté à ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Passage à ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} a réglé la vitesse sur ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Vitesse réglée sur ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} a lancé ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Lecture en cours : ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} a arrêté la vidéo',
			'watchTogether.notices.mediaStopped' => 'La vidéo s’est arrêtée',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'En attente de ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'En attente d’un participant en retard...',
			'watchTogether.notices.finished' => 'Terminé',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} est maintenant l’hôte',
			'watchTogether.notices.youAreNowHost' => 'Vous êtes maintenant l’hôte',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} a rejoint',
			'watchTogether.notices.left' => ({required Object name}) => '${name} est parti',
			'watchTogether.notices.controlRefused' => 'Seul l’hôte peut contrôler la lecture',
			'watchTogether.notices.searchFailed' => 'Impossible de rechercher la vidéo du salon sur certains serveurs',
			'watchTogether.notices.playBlocked' => 'Appuyez sur Lecture pour commencer',
			'watchTogether.notices.shareFailed' => 'Impossible de partager cette vidéo avec le salon',
			'watchTogether.notices.downloadNotShared' => 'Les téléchargements ne sont pas partagés avec le salon tant que leur serveur est hors ligne',
			'watchTogether.notices.openFailed' => 'Impossible d’ouvrir la vidéo du salon',
			'watchTogether.ended.ended' => 'L’hôte a fermé le salon',
			'watchTogether.ended.kicked' => 'Vous avez été retiré du salon',
			'watchTogether.ended.expired' => 'Le salon a expiré',
			'watchTogether.ended.replaced' => 'Vous avez rejoint ce salon sur un autre appareil',
			'watchTogether.ended.lost' => 'Connexion au salon perdue',
			'watchTogether.errors.invalidCode' => 'Ce n’est pas un code de salon. Les codes comportent 6 lettres et chiffres, sans 0, 1, I, L ni O.',
			'watchTogether.errors.roomNotFound' => 'Aucun salon ne correspond à ce code. Il a peut-être été fermé.',
			'watchTogether.errors.roomFull' => 'Ce salon est complet.',
			'watchTogether.errors.roomLocked' => 'L’hôte a verrouillé ce salon.',
			'watchTogether.errors.relayFull' => 'Le service Regarder ensemble est saturé pour le moment. Réessayez plus tard.',
			'watchTogether.errors.unreachable' => 'Impossible de joindre le relais Regarder ensemble. Vérifiez votre connexion.',
			'watchTogether.errors.rateLimited' => 'Trop de tentatives. Patientez un instant, puis réessayez.',
			'watchTogether.errors.clientBlocked' => 'Cette version de PlezyNG ne peut pas utiliser le relais. Mettez l’application à jour.',
			'watchTogether.errors.forbidden' => 'Seul l’hôte peut faire cela.',
			'watchTogether.errors.notInRoom' => 'Vous n’êtes pas dans un salon.',
			'watchTogether.errors.alreadyInRoom' => 'Vous êtes déjà dans un salon.',
			'watchTogether.errors.resumeFailed' => 'Impossible de rejoindre à nouveau le salon.',
			'watchTogether.errors.unsupported' => 'Le relais ne prend pas en charge cette fonction.',
			'watchTogether.errors.generic' => 'Une erreur s’est produite. Réessayez.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Épisode ${number}',
			'downloads.title' => 'Téléchargements',
			'downloads.manage' => 'Gérer',
			'downloads.tvShows' => 'Séries TV',
			'downloads.movies' => 'Films',
			'downloads.music' => 'Musique',
			'downloads.tracksQueued' => ({required Object count}) => '${count} titres en file d\'attente de téléchargement',
			'downloads.noDownloads' => 'Aucun téléchargement pour le moment',
			'downloads.noDownloadsDescription' => 'Le contenu téléchargé apparaîtra ici pour être consulté hors ligne.',
			'downloads.downloadNow' => 'Télécharger',
			'downloads.deleteDownload' => 'Supprimer le téléchargement',
			'downloads.retryDownload' => 'Réessayer le téléchargement',
			'downloads.downloadQueued' => 'Téléchargement en attente',
			'downloads.downloadResumed' => 'Téléchargement repris',
			'downloads.serverErrorBitrate' => 'Erreur du serveur : le fichier peut dépasser la limite de débit distant',
			'downloads.storageFull' => 'Les téléchargements ont été arrêtés pour préserver l’espace de stockage disponible. Libérez de l’espace ou choisissez un autre emplacement de téléchargement, puis réessayez.',
			'downloads.storageUnavailable' => 'Les téléchargements ont été arrêtés car l’espace de stockage disponible n’a pas pu être vérifié. Vérifiez l’emplacement de téléchargement, puis réessayez.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} épisodes en attente de téléchargement',
			'downloads.downloadDeleted' => 'Téléchargement supprimé',
			'downloads.deleteConfirm' => ({required Object title}) => 'Supprimer « ${title} » de cet appareil ?',
			'downloads.deleteCollectionDownloads' => 'Supprimer les téléchargements',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Supprimer de cet appareil tous les téléchargements de « ${title} » ?',
			'downloads.collectionDownloadsDeleted' => 'Téléchargements supprimés',
			'downloads.cancelledDownloadTitle' => 'Téléchargement annulé',
			'downloads.cancelledDownloadMessage' => 'Ce téléchargement a été annulé. Que voulez-vous faire ?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Tous les épisodes sont déjà téléchargés',
			'downloads.resumeDownload' => 'Reprendre le téléchargement',
			'downloads.cancelledDownload' => 'Téléchargement annulé',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (synchronisation ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} téléchargé — cliquez pour terminer',
			'downloads.partialDownloadClickToComplete' => 'Téléchargement partiel — cliquez pour terminer',
			'downloads.deleting' => 'Suppression...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Suppression de ${title}... (${current} sur ${total})',
			'downloads.queuedTooltip' => 'En attente',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'En attente : ${files}',
			'downloads.downloadingTooltip' => 'Téléchargement...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Téléchargement de ${files}',
			'downloads.noDownloadsTree' => 'Aucun téléchargement',
			'downloads.pauseAll' => 'Tout mettre en pause',
			'downloads.resumeAll' => 'Tout reprendre',
			'downloads.retryAll' => 'Tout réessayer',
			'downloads.retryFailed' => 'Réessayer les téléchargements en échec',
			'downloads.deleteAll' => 'Tout supprimer',
			'downloads.selectVersion' => 'Sélectionner la version',
			'downloads.allEpisodes' => 'Tous les épisodes',
			'downloads.unwatchedOnly' => 'Non vus uniquement',
			'downloads.nextNUnwatched' => ({required Object count}) => '${count} prochains non vus',
			'downloads.customAmount' => 'Quantité personnalisée...',
			'downloads.customAmountAny' => 'Le montant (en chaque année)',
			'downloads.randomEpisodes' => 'Épisodes rares',
			'downloads.includeSpecials' => 'Inclure les spéciaux',
			'downloads.howManyEpisodes' => 'Combien d\'épisodes ?',
			'downloads.invalidEpisodeCount' => 'Saisissez un nombre d\'épisodes valide.',
			'downloads.keepSynced' => 'Garder synchronisé',
			'downloads.downloadOnce' => 'Télécharger une fois',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Garder ${count} non vus',
			'downloads.editSyncRule' => 'Modifier la règle de synchronisation',
			'downloads.removeSyncRule' => 'Supprimer la règle de synchronisation',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Arrêter la synchronisation de « ${title} » ? Les épisodes téléchargés seront conservés.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Arrêter la synchronisation de « ${title} » ?',
			'downloads.deleteSyncRuleDownloads' => 'Supprimer aussi les téléchargements associés',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Les téléchargements utilisés par une autre règle de synchronisation ou un autre profil seront conservés.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Règle de synchronisation créée — ${count} épisodes non vus conservés',
			'downloads.syncRuleUpdated' => 'Règle de synchronisation mise à jour',
			'downloads.syncRuleRemoved' => 'Règle de synchronisation supprimée',
			'downloads.syncRuleAndDownloadsRemoved' => 'Règle de synchronisation et téléchargements associés supprimés',
			'downloads.syncRuleCleanupBusy' => 'Les règles de synchronisation sont en cours de mise à jour. Réessayez dans un instant.',
			'downloads.syncRuleCleanupUnavailable' => 'Les téléchargements associés n\'ont pas pu être identifiés en toute sécurité. Reconnectez le serveur et réessayez, ou retirez la règle sans supprimer les téléchargements.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} nouveaux épisodes synchronisés pour ${title}',
			'downloads.syncNow' => 'Synchronisation maintenant',
			'downloads.downloadsUpToDate' => 'Les téléchargements sont à jour',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync complet · ${queued} queued, ${removed} supprimé',
			'downloads.activeSyncRules' => 'Règles de synchronisation',
			'downloads.reviewOrphanFiles' => 'Examiner les téléchargements orphelins',
			'downloads.orphanReviewTitle' => 'Examiner les téléchargements orphelins',
			'downloads.orphanReviewDescription' => 'Ces fichiers marqués se trouvent dans les dossiers de téléchargement par défaut gérés par PlezyNG et ne correspondent à aucun enregistrement de téléchargement ni à aucune tâche active. Vérifiez la liste avant de les supprimer.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} fichiers · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Supprimer ${count} fichiers',
			'downloads.orphanCleanupNone' => 'Aucun fichier de téléchargement orphelin trouvé',
			'downloads.orphanCleanupFailed' => 'PlezyNG n’a pas pu analyser le dossier de téléchargement géré en toute sécurité. Aucun fichier n’a été supprimé.',
			'downloads.orphanCleanupChanged' => 'La liste des téléchargements a changé pendant la vérification. Examinez de nouveau les fichiers avant de nettoyer.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '${count} fichiers orphelins supprimés · ${size} d’espace libéré',
			'downloads.noSyncRules' => 'Aucune règle de synchronisation',
			'downloads.manageSyncRule' => 'Gérer la synchronisation',
			'downloads.editEpisodeCount' => 'Nombre d’épisodes',
			'downloads.editSyncFilter' => 'Filtre de synchronisation',
			'downloads.syncAllItems' => 'Synchronisation de tous les éléments',
			'downloads.syncUnwatchedItems' => 'Synchronisation des éléments non vus',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Serveur : ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponible',
			'downloads.syncRuleOffline' => 'Hors ligne',
			'downloads.syncRuleSignInRequired' => 'Connexion requise',
			'downloads.syncRuleAccessDenied' => 'Accès refusé',
			'downloads.syncRuleNotAvailableForProfile' => 'Non disponible pour le profil actuel',
			'downloads.syncRuleUnknownServer' => 'Serveur inconnu',
			'downloads.syncRuleListCreated' => 'Règle de synchronisation créée',
			'downloads.backgroundWarning.bannerBlocked' => 'Les téléchargements s’arrêteront lorsque vous quitterez l’application',
			'downloads.backgroundWarning.bannerDegraded' => 'Les téléchargements en arrière-plan peuvent être limités',
			'downloads.backgroundWarning.bannerAction' => 'Détails',
			'downloads.backgroundWarning.sheetTitle' => 'Les téléchargements en arrière-plan sont bloqués',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Les téléchargements en arrière-plan peuvent être limités',
			'downloads.backgroundWarning.sheetIntro' => 'Android empêche PlezyNG de télécharger de façon fiable en arrière-plan.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Votre appareil limite les moments où PlezyNG peut télécharger en arrière-plan.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'L’utilisation de PlezyNG en arrière-plan est restreinte. Dans les paramètres de batterie ou d’utilisation en arrière-plan, sélectionnez « Sans restriction ».',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android a placé PlezyNG en veille restreinte. Réglez l’utilisation de la batterie sur « Sans restriction ».',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Les notifications de téléchargement sont désactivées. La progression et les commandes peuvent donc être indisponibles.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Les notifications sont désactivées. Sur Android 13 ou version ultérieure, elles sont nécessaires pour les longs téléchargements en arrière-plan.',
			'downloads.backgroundWarning.reasonDataSaver' => 'L’Économiseur de données est activé et bloque les téléchargements en arrière-plan via les données mobiles. Ils devraient toujours fonctionner en Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Les téléchargements se sont arrêtés plusieurs fois lorsque PlezyNG était en arrière-plan. Vérifiez les paramètres de batterie ou d’utilisation en arrière-plan de PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Ouvrir les paramètres',
			'downloads.backgroundWarning.stillNotWorking' => 'Aide spécifique à l’appareil',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Consultez les étapes adaptées à votre appareil ou, si le problème persiste, envoyez un journal depuis Paramètres › Voir les journaux.',
			'downloads.backgroundWarning.dialogTitle' => 'Les téléchargements risquent de ne pas aboutir',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Télécharger quand même',
			'downloads.backgroundWarning.dialogFixFirst' => 'Corriger d’abord',
			'downloads.backgroundWarning.statusTile' => 'Téléchargements en arrière-plan',
			'downloads.backgroundWarning.statusOk' => 'Exécution en arrière-plan autorisée',
			'downloads.backgroundWarning.statusBlocked' => 'Bloqués par les paramètres système',
			'downloads.backgroundWarning.statusDegraded' => 'Limités par les paramètres système',
			'downloads.backgroundWarning.statusUnknown' => 'Pas encore vérifié',
			'downloads.backgroundWarning.settingsUnavailable' => 'Impossible d’ouvrir les paramètres système sur cet appareil',
			'downloads.backgroundWarning.linkUnavailable' => 'Impossible d’ouvrir dontkillmyapp.com sur cet appareil',
			'downloads.options' => 'Options de téléchargement',
			'downloads.groupings.library' => 'Bibliothèque',
			'downloads.groupings.collections' => 'Collections',
			'downloads.unknownLibrary' => 'Bibliothèque inconnue',
			'downloads.unknownShow' => 'Série inconnue',
			'downloads.unknownSeason' => 'Saison inconnue',
			'downloads.unknownAlbum' => 'Album inconnu',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} terminés',
			'downloads.storageUsed' => ({required Object size}) => 'Équipement utilisé : ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargement', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} téléchargements', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} écriture', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} écrans', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} films', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} albums', ), 
			'downloads.errorFileNotFound' => 'Fichier introuvable (404)',
			'downloads.errorDownloadNotAllowed' => 'Téléchargement non autorisé par le serveur (403)',
			'downloads.errorDownloadFailed' => 'Échec du téléchargement',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Échec du téléchargement : ${reason}',
			'downloads.convertingOnServer' => 'Convertir sur le serveur...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Conversion sur serveur · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Échec du téléchargement (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Échec du post-traitement : ${reason}',
			'downloads.reasonFileNotSaved' => 'le fichier n\'a pas pu être enregistré sur cet appareil',
			'downloads.reasonCannotResume' => 'le téléchargement partiel n\'a pas pu être repris',
			'downloads.reasonDeviceStorageFull' => 'cet appareil n\'a plus d\'espace de stockage',
			'downloads.notificationDownloading' => 'Téléchargement...',
			'downloads.notificationComplete' => 'Téléchargement terminé',
			'downloads.notificationPaused' => 'Téléchargement en pause',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Aucune amélioration vidéo',
			'shaders.nvscalerDescription' => 'Mise à l\'échelle NVIDIA pour une vidéo plus nette',
			'shaders.artcnnVariantNeutral' => 'Neutre',
			'shaders.artcnnVariantDenoise' => 'Réduction du bruit',
			'shaders.artcnnVariantDenoiseSharpen' => 'Réduction du bruit + netteté',
			'shaders.qualityFast' => 'Rapide',
			'shaders.qualityHQ' => 'Haute qualité',
			'shaders.mode' => 'Mode',
			'shaders.importShader' => 'Importer un shader',
			'shaders.customShaderDescription' => 'Shader GLSL personnalisé',
			'shaders.shaderImported' => 'Shader importé',
			'shaders.shaderImportFailed' => 'Échec de l\'importation du shader',
			'shaders.deleteShader' => 'Supprimer le shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Supprimer "${name}" ?',
			'companionRemote.title' => 'Télécommande compagnon',
			'companionRemote.connectedTo' => ({required Object name}) => 'Connecté à ${name}',
			'companionRemote.unknownDevice' => 'Appareil inconnu',
			'companionRemote.session.startingServer' => 'Démarrage du serveur de télécommande…',
			'companionRemote.session.hostAddress' => 'Adresse de l’hôte',
			'companionRemote.session.connected' => 'Connecté',
			'companionRemote.session.serverRunning' => 'Serveur de télécommande actif',
			'companionRemote.session.serverStopped' => 'Serveur de télécommande arrêté',
			'companionRemote.session.serverRunningDescription' => 'Les appareils mobiles de votre réseau peuvent se connecter à cette application',
			'companionRemote.session.serverStoppedDescription' => 'Démarrez le serveur pour permettre aux appareils mobiles de se connecter',
			'companionRemote.session.usePhoneToControl' => 'Utilisez votre appareil mobile pour contrôler cette application',
			'companionRemote.session.startServer' => 'Démarrer le serveur',
			'companionRemote.session.stopServer' => 'Arrêter le serveur',
			'companionRemote.session.minimize' => 'Réduire',
			'companionRemote.session.manualAddressHint' => 'Adresse de connexion manuelle :',
			'companionRemote.pairing.discoveryDescription' => 'Les appareils PlezyNG avec le même compte Plex apparaissent ici',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Connexion...',
			'companionRemote.pairing.searchingForDevices' => 'Recherche d\'appareils...',
			'companionRemote.pairing.noDevicesFound' => 'Aucun appareil trouvé sur votre réseau',
			'companionRemote.pairing.noDevicesHint' => 'Ouvrez PlezyNG sur votre ordinateur et utilisez le même réseau Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Appareils disponibles',
			'companionRemote.pairing.manualConnection' => 'Connexion manuelle',
			'companionRemote.pairing.cryptoInitFailed' => 'Impossible de démarrer la connexion sécurisée. Connectez-vous d\'abord à Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Veuillez saisir l’adresse de l’hôte',
			'companionRemote.pairing.validationHostFormat' => 'Le format doit être IP:port (p. ex. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Délai de connexion dépassé. Utilisez le même réseau sur les deux appareils.',
			'companionRemote.pairing.sessionNotFound' => 'Appareil introuvable. Assurez-vous que PlezyNG fonctionne sur l\'hôte.',
			'companionRemote.pairing.authFailed' => 'Échec de l\'authentification. Les deux appareils doivent utiliser le même compte Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Échec de la connexion : ${error}',
			'companionRemote.pairing.codeTitle' => 'Couple code',
			'companionRemote.pairing.codeDescription' => 'Entrez le code indiqué dans Companion Remote sur l\'appareil hôte. Les deux appareils doivent utiliser une version qui soutient la paille sécurisée.',
			'companionRemote.pairing.codeInvalid' => 'Entrez toutes les 32 lettres et chiffres du code hôte.',
			'companionRemote.pairing.updateRequired' => 'Mettre à jour les deux appareils à une version qui soutient la paille sécurisée.',
			'companionRemote.pairing.hostDescription' => 'Envoyez ce code une fois sur chaque téléchargement. Gardez-le privé: il donne le contrôle de ce profil.',
			'companionRemote.pairing.resetCode' => 'Réserver le code de paille',
			'companionRemote.pairing.resetDescription' => 'Disconnectez tous les remots et créez un nouveau code. Chaque remot aura besoin de se couper à nouveau.',
			'companionRemote.remote.disconnectConfirm' => 'Voulez-vous vous déconnecter de la session distante ?',
			'companionRemote.remote.reconnecting' => 'Reconnexion...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentative ${current} sur 5',
			'companionRemote.remote.retryNow' => 'Réessayer maintenant',
			'companionRemote.remote.tabRemote' => 'Télécommande',
			'companionRemote.remote.tabPlay' => 'Lecture',
			'companionRemote.remote.tabMore' => 'Plus',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Navigation par onglets',
			'companionRemote.remote.tabDiscover' => 'Découvrir',
			'companionRemote.remote.tabLibraries' => 'Bibliothèques',
			'companionRemote.remote.tabSearch' => 'Rechercher',
			'companionRemote.remote.tabDownloads' => 'Téléchargements',
			'companionRemote.remote.tabSettings' => 'Paramètres',
			'companionRemote.remote.previous' => 'Précédent',
			'companionRemote.remote.playPause' => 'Lecture/Pause',
			'companionRemote.remote.next' => 'Suivant',
			'companionRemote.remote.seekBack' => 'Reculer',
			'companionRemote.remote.stop' => 'Arrêter',
			'companionRemote.remote.seekForward' => 'Avancer',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Baisser',
			'companionRemote.remote.volumeUp' => 'Augmenter',
			'companionRemote.remote.fullscreen' => 'Plein écran',
			'companionRemote.remote.subtitles' => 'Sous-titres',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Rechercher sur l’ordinateur…',
			'companionRemote.errors.noNetworkInterface' => 'Aucune interface réseau trouvée',
			'companionRemote.errors.authenticationFailed' => 'Échec de l’authentification',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Impossible de démarrer le serveur de télécommande : ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Impossible d’envoyer la commande à distance : ${error}',
			'companionRemote.errors.joinTimedOut' => 'Délai dépassé lors de la connexion à la session',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Impossible de se connecter à une adresse',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Connexion perdue après ${attempts} tentatives',
			'companionRemote.errors.connectionLost' => 'Connexion perdue',
			'companionRemote.closedBeforeAuth' => 'La connexion a été fermée avant l’authentification',
			'videoSettings.playbackSpeed' => 'Vitesse de lecture',
			'videoSettings.normalSpeed' => 'Normale',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Actif (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Minuterie de mise en veille',
			'videoSettings.audioSync' => 'Synchronisation audio',
			'videoSettings.subtitleSync' => 'Synchronisation des sous-titres',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'Le HDR n’est pas disponible ici : ce compositeur de bureau ou cette sortie vidéo ne permet pas de le transmettre.',
			'videoSettings.hdrToneMapping' => 'Mappage tonal HDR',
			'videoSettings.hdrToneMappingCompositor' => 'Compositeur',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Transmettre les métadonnées HDR de la source et laisser le compositeur de bureau effectuer le mappage.',
			'videoSettings.hdrToneMappingPlayer' => 'Lecteur',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Effectuer dans le lecteur le mappage selon la luminosité maximale de l’écran, puis indiquer le résultat au compositeur.',
			'videoSettings.hdrToneMappingFailed' => 'Impossible de modifier le mappage tonal HDR : le mode précédent reste actif.',
			'videoSettings.audioOutput' => 'Sortie audio',
			'videoSettings.performanceOverlay' => 'Données de performance',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Audio spatial',
			'videoSettings.audioOutputStereo' => 'Stéréo',
			'videoSettings.audioEqualizer' => 'Équaliste audio',
			'videoSettings.audioEqualizerDescription' => 'Un équateur de 10 bandes pour MPVLes filtres audio utilisent l\'audio décodé et désactivent passthrough.',
			'videoSettings.audioEqualizerFlat' => 'Plateur',
			'videoSettings.audioEqualizerActive' => 'Personnalisé',
			'videoSettings.audioEqualizerSaveFailed' => 'Il ne pouvait pas économiser les paramètres d\'équalisateur audio.',
			'videoSettings.backgroundVideoAudio' => '- Audio vidéo de fond',
			'videoSettings.backgroundVideoAudioDescription' => 'Gardez la lecture audio vidéo lorsque vous quittez le lecteur; l\'image est cachée jusqu\'à ce que vous reveniez. Android utilise une notification de récupération médiatique.',
			'videoSettings.audioNormalization' => 'Normaliser le volume',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Décode l’audio en PCM ; la transmission directe est désactivée tant que cette option est active',
			'videoSettings.audioEffectsDescription' => 'Les effets utilisent l\'audio décodé, de sorte que le match se tourne. l\'ambiance de la pièce et l\'extension stéréo dépendent du MPV Construire et suivre.',
			'videoSettings.audioStereoWidth' => 'Extension Stereo',
			'videoSettings.audioSpatializer' => 'L’ambiance de la chambre',
			'videoSettings.audioSpatializerDescription' => 'Ajoutez des réflexions de la salle calme.',
			'videoSettings.audioPitch' => 'Le changement de Pitch',
			'videoSettings.audioPitchDescription' => 'Changer la piste sans changer de vitesse. MPV La construction doit inclure Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'Cet effet n\'est pas disponible pour cette piste ou MPV à construire.',
			'performanceOverlay.color' => 'Couleur',
			'performanceOverlay.performance' => 'Performances',
			'performanceOverlay.buffer' => 'Tampon',
			'performanceOverlay.app' => 'Application',
			'performanceOverlay.decoder' => 'Décodeur',
			'performanceOverlay.rawDecoder' => 'Décodeur brut',
			'performanceOverlay.tunneling' => 'Tunnel',
			'performanceOverlay.passthrough' => 'Transmission directe',
			'performanceOverlay.aspect' => 'Format',
			'performanceOverlay.rotation' => 'Rotation',
			'performanceOverlay.dvSource' => 'Source DV',
			'performanceOverlay.dvPath' => 'Chemin DV',
			'performanceOverlay.dvRouteDecoder' => 'Décodeur Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'Décodeur Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Couche de base',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'Couche de base HDR10',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Couche de base HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Couche de base SDR',
			'performanceOverlay.dvRouteReshaped' => 'Remodelage RPU (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Graphique expérimental P7 FEL (non qualifié)',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Fréquence d’échantillonnage',
			'performanceOverlay.pixelFormat' => 'Fmt pixel',
			'performanceOverlay.hwFormat' => 'Fmt HW',
			'performanceOverlay.matrix' => 'Matrice',
			'performanceOverlay.primaries' => 'Primaires',
			'performanceOverlay.transfer' => 'Transfert',
			'performanceOverlay.renderFps' => 'FPS rendu',
			'performanceOverlay.displayFps' => 'FPS écran',
			'performanceOverlay.avSync' => 'Synchro A/V',
			'performanceOverlay.dropped' => 'Perdues',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'Moy. DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Moy. échant. DV',
			'performanceOverlay.maxLuma' => 'Luma max.',
			'performanceOverlay.minLuma' => 'Luma min.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache utilisé',
			'performanceOverlay.cacheLimit' => 'Limite du cache',
			'performanceOverlay.speed' => 'Vitesse',
			'performanceOverlay.player' => 'Lecteur',
			'performanceOverlay.playMethod' => 'Le jeu méthode',
			'performanceOverlay.memory' => 'Mémoire',
			'performanceOverlay.uiFps' => 'FPS UI',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Matériel Android',
			'performanceOverlay.decoderNvidiaHw' => 'Matériel NVIDIA',
			'performanceOverlay.decoderQualcommHw' => 'Matériel Qualcomm',
			'performanceOverlay.decoderMediatekHw' => 'Matériel MediaTek',
			'performanceOverlay.decoderExynosHw' => 'Matériel Exynos',
			'performanceOverlay.decoderSoftware' => 'Logiciel',
			'performanceOverlay.decoderHardware' => 'Matériel',
			'performanceOverlay.tunnelingActive' => 'Actif',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} échecs)',
			'externalPlayer.title' => 'Lecteur externe',
			'externalPlayer.useExternalPlayer' => 'Utiliser un lecteur externe',
			'externalPlayer.useExternalPlayerDescription' => 'Ouvrir les vidéos dans une autre application',
			'externalPlayer.selectPlayer' => 'Sélectionner le lecteur',
			'externalPlayer.customPlayers' => 'Lecteurs personnalisés',
			'externalPlayer.systemDefault' => 'Par défaut du système',
			'externalPlayer.addCustomPlayer' => 'Ajouter un lecteur personnalisé',
			'externalPlayer.playerName' => 'Nom du lecteur',
			'externalPlayer.playerNameHint' => 'Mon lecteur',
			'externalPlayer.playerCommand' => 'Commande',
			'externalPlayer.playerPackage' => 'Nom du paquet',
			'externalPlayer.playerUrlScheme' => 'Schéma URL',
			'externalPlayer.off' => 'Désactivé',
			'externalPlayer.launchFailed' => 'Impossible d\'ouvrir le lecteur externe',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} n\'est pas installé',
			'externalPlayer.playInExternalPlayer' => 'Lire dans un lecteur externe',
			'externalPlayer.description' => 'Choisissez une autre application pour ouvrir les vidéos. Les joueurs disponibles dépendent de votre appareil et des applications installées.',
			'externalPlayer.systemDefaultDescription' => 'Laissez le système d\'exploitation ouvrir la vidéo avec son application par défaut.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Ouvrez des vidéos avec ${player}.',
			'externalPlayer.playerNameDescription' => 'L\'étiquette affichée dans la liste des joueurs.',
			'externalPlayer.playerPackageDescription' => 'Entrez le nom de paquet Android de l\'application joueur, comme com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Entrez le commandement de joueur installé ou la voie exécutable pour ce dispositif.',
			'externalPlayer.playerUrlSchemeDescription' => 'Entrez le schéma URL et le modèle URL facultatif utilisé pour lancer le lecteur.',
			'metadataEdit.editMetadata' => 'Modifier...',
			'metadataEdit.screenTitle' => 'Modifier les métadonnées',
			'metadataEdit.basicInfo' => 'Informations de base',
			'metadataEdit.artwork' => 'Illustrations',
			'metadataEdit.advancedSettings' => 'Paramètres avancés',
			'metadataEdit.title' => 'Titre',
			'metadataEdit.sortTitle' => 'Titre de tri',
			'metadataEdit.originalTitle' => 'Titre original',
			'metadataEdit.releaseDate' => 'Date de sortie',
			'metadataEdit.contentRating' => 'Classification',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Résumé',
			'metadataEdit.poster' => 'Affiche',
			'metadataEdit.background' => 'Arrière-plan',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Image carrée',
			'metadataEdit.selectPoster' => 'Sélectionner l\'affiche',
			'metadataEdit.selectBackground' => 'Sélectionner l\'arrière-plan',
			'metadataEdit.selectLogo' => 'Sélectionner le logo',
			'metadataEdit.selectSquareArt' => 'Sélectionner l\'image carrée',
			'metadataEdit.fromUrl' => 'Depuis une URL',
			'metadataEdit.uploadFile' => 'Importer un fichier',
			'metadataEdit.enterImageUrl' => 'Entrer l\'URL de l\'image',
			'metadataEdit.imageUrl' => 'URL de l\'image',
			'metadataEdit.metadataUpdated' => 'Métadonnées mises à jour',
			'metadataEdit.metadataUpdateFailed' => 'Échec de la mise à jour des métadonnées',
			'metadataEdit.artworkUpdated' => 'Illustrations mises à jour',
			'metadataEdit.artworkUpdateFailed' => 'Échec de la mise à jour des illustrations',
			'metadataEdit.noArtworkAvailable' => 'Aucune illustration disponible',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Option d\'illustration ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Option d\'illustration ${index}, sélectionnée',
			'metadataEdit.notSet' => 'Non défini',
			'metadataEdit.libraryDefault' => 'Par défaut de la bibliothèque',
			'metadataEdit.accountDefault' => 'Par défaut du compte',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.seriesDefault' => 'Par défaut de la série',
			'metadataEdit.episodeSorting' => 'Tri des épisodes',
			'metadataEdit.oldestFirst' => 'Plus anciens en premier',
			'metadataEdit.newestFirst' => 'Plus récents en premier',
			'metadataEdit.keep' => 'Conserver',
			'metadataEdit.allEpisodes' => 'Tous les épisodes',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} derniers épisodes',
			'metadataEdit.latestEpisode' => 'Dernier épisode',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Épisodes ajoutés ces ${count} derniers jours',
			'metadataEdit.deleteAfterPlaying' => 'Supprimer les épisodes après lecture',
			'metadataEdit.never' => 'Jamais',
			'metadataEdit.afterADay' => 'Après un jour',
			'metadataEdit.afterAWeek' => 'Après une semaine',
			'metadataEdit.afterAMonth' => 'Après un mois',
			'metadataEdit.onNextRefresh' => 'Au prochain rafraîchissement',
			'metadataEdit.seasons' => 'Saisons',
			'metadataEdit.show' => 'Afficher',
			'metadataEdit.hide' => 'Masquer',
			'metadataEdit.episodeOrdering' => 'Ordre des épisodes',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Diffusion)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Diffusion)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolu)',
			'metadataEdit.metadataLanguage' => 'Langue des métadonnées',
			'metadataEdit.useOriginalTitle' => 'Utiliser le titre original',
			'metadataEdit.preferredAudioLanguage' => 'Langue audio préférée',
			'metadataEdit.preferredSubtitleLanguage' => 'Langue de sous-titres préférée',
			'metadataEdit.subtitleMode' => 'Sélection automatique des sous-titres',
			'metadataEdit.manuallySelected' => 'Sélectionné manuellement',
			'metadataEdit.shownWithForeignAudio' => 'Avec l’audio en langue étrangère',
			'metadataEdit.alwaysEnabled' => 'Toujours activé',
			'metadataEdit.tags' => 'Étiquettes',
			'metadataEdit.addTag' => 'Ajouter une étiquette',
			'metadataEdit.genre' => 'Genre',
			'metadataEdit.director' => 'Réalisateur',
			'metadataEdit.writer' => 'Scénariste',
			'metadataEdit.producer' => 'Producteur',
			'metadataEdit.country' => 'Pays',
			'metadataEdit.collection' => 'Collection',
			'metadataEdit.label' => 'Libellé',
			'metadataEdit.quickTag' => 'Tag rapide...',
			'matchScreen.match' => 'Associer...',
			'matchScreen.fixMatch' => 'Corriger l\'association...',
			'matchScreen.unmatch' => 'Dissocier',
			'matchScreen.unmatchConfirm' => 'Effacer cette correspondance ? Plex la traitera comme non associée jusqu\'à réassociation.',
			'matchScreen.unmatchSuccess' => 'Association supprimée',
			'matchScreen.unmatchFailed' => 'Échec de la dissociation',
			'matchScreen.matchApplied' => 'Association appliquée',
			'matchScreen.matchFailed' => 'Échec de l\'application',
			'matchScreen.titleHint' => 'Titre',
			'matchScreen.yearHint' => 'Année',
			'matchScreen.search' => 'Rechercher',
			'matchScreen.noMatchesFound' => 'Aucune correspondance',
			'serverTasks.title' => 'Tâches du serveur',
			'serverTasks.failedToLoad' => 'Échec du chargement des tâches',
			'serverTasks.noTasks' => 'Aucune tâche en cours',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Connecté',
			'trakt.connectedAs' => ({required Object username}) => 'Connecté en tant que @${username}',
			'trakt.disconnectConfirm' => 'Déconnecter le compte Trakt ?',
			'trakt.disconnectConfirmBody' => 'PlezyNG cessera d’envoyer des événements à Trakt. Vous pourrez vous reconnecter à tout moment.',
			'trakt.scrobble' => 'Scrobbling en temps réel',
			'trakt.scrobbleDescription' => 'Envoyer les événements de lecture, pause et arrêt à Trakt pendant la lecture.',
			'trakt.watchedSync' => 'Synchroniser le statut « vu »',
			'trakt.watchedSyncDescription' => 'Lorsque vous marquez des éléments comme vus dans PlezyNG, ils sont également marqués comme vus sur Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Se connecter à Seerr',
			'seerr.serverUrl' => 'URL du serveur',
			'seerr.serverUrlHelper' => 'L\'adresse de votre instance Seerr',
			'seerr.checkServer' => 'Continuer',
			'seerr.signInWithJellyfin' => 'Se connecter avec Jellyfin',
			'seerr.signInWithEmby' => 'Se connecter avec Emby',
			'seerr.signInWithLocal' => 'Utiliser un compte local',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Cette instance Seerr ne propose aucune méthode de connexion prise en charge par PlezyNG.',
			'seerr.instance' => 'Instance',
			'seerr.disconnectConfirm' => 'Déconnecter Seerr ?',
			'seerr.disconnectConfirmBody' => 'PlezyNG oubliera cette instance Seerr. Vous pourrez vous reconnecter à tout moment.',
			'seerr.request' => 'Demander',
			'seerr.request4k' => 'Demander en 4K',
			'seerr.seasons' => 'Saisons',
			'seerr.allSeasons' => 'Toutes les saisons',
			'seerr.advancedOptions' => 'Avancé',
			'seerr.destinationServer' => 'Serveur de destination',
			'seerr.qualityProfile' => 'Profil de qualité',
			'seerr.rootFolder' => 'Dossier racine',
			'seerr.languageProfile' => 'Profil de langue',
			'seerr.tags' => 'Étiquettes',
			'seerr.noTags' => 'Aucune étiquette',
			'seerr.defaultOption' => ({required Object name}) => '${name} (par défaut)',
			'seerr.animeNote' => 'Cette série est un anime.',
			'seerr.requestSubmitted' => 'Demande envoyée',
			'seerr.requestFailed' => ({required Object error}) => 'Échec de la demande : ${error}',
			'seerr.requestsLoadFailed' => 'Impossible de charger les options de demande',
			'seerr.nothingToRequest' => 'Tout est déjà disponible ou demandé.',
			'seerr.statusAvailable' => 'Disponible',
			'seerr.statusPartiallyAvailable' => 'Partiellement disponible',
			'seerr.statusRequested' => 'Demandé',
			'seerr.statusProcessing' => 'En cours de traitement',
			'seerr.statusBlocklisted' => 'Sur la liste de blocage',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Impossible de joindre ${url} : ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Aucune instance Seerr à l’adresse ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Un proxy inverse avec authentification (SSO ou authentification HTTP) a répondu à la place de Seerr. PlezyNG ne peut pas se connecter à travers lui : laissez le chemin /api/v1 de Seerr contourner le proxy pour cette application, ou utilisez une adresse qui atteint Seerr directement.',
			'seerr.invalidUrl' => 'Saisissez une adresse de serveur comme https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Cette instance Seerr ne prend pas en charge Quick Connect. Elle nécessite Seerr 3.4 ou version ultérieure.',
			'seerr.notInitialized' => 'La configuration initiale de cette instance Seerr n’est pas terminée',
			'seerr.noPlexTokenForReauth' => 'Aucun jeton Plex n’est disponible pour se reconnecter',
			'seerr.noStoredCredentials' => 'Aucun identifiant enregistré n’est disponible pour se reconnecter',
			'seerr.signInRejected' => 'La connexion a été refusée',
			'seerr.noSessionCookie' => 'Seerr n’a pas fourni de cookie de session',
			'seerr.freshCookieRejected' => 'Seerr a refusé le nouveau cookie de session',
			'seerr.noUserInformation' => 'Seerr n’a renvoyé aucune information sur l’utilisateur',
			'seerr.sessionRejectedAfterReauth' => 'La session a été refusée après la reconnexion',
			'seerr.permissionDenied' => 'Seerr a refusé cette action : votre compte ne dispose plus de la permission requise',
			'seerr.permissionRevoked' => 'Vous n’avez plus la permission de faire cette demande',
			'services.title' => 'Services',
			'services.hubSubtitle' => 'Synchronisez votre progression et demandez de nouveaux titres.',
			'services.integrations' => 'Intégrations',
			'services.notConnected' => 'Non connecté',
			'services.connectedAs' => ({required Object username}) => 'Connecté en tant que @${username}',
			'services.scrobble' => 'Suivre la progression automatiquement',
			'services.scrobbleDescription' => 'Mettre à jour votre liste lorsque vous terminez un épisode ou un film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Déconnecter ${service} ?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG cessera de mettre à jour ${service}. Vous pourrez vous reconnecter à tout moment.',
			'services.connectFailed' => ({required Object service}) => 'Échec de la connexion à ${service}. Réessayez.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Reconnecter Simkl',
			'services.simklReconnect.subtitle' => 'Simkl va retirer la méthode de connexion utilisée par cette liaison. La reconnexion ouvre simkl.com pour autoriser PlezyNG — PlezyNG n’a jamais accès à votre mot de passe. Votre historique de visionnage reste sur Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Activer PlezyNG sur ${service}',
			'services.deviceCode.instructions' => 'Scannez le code QR ou accédez à l’adresse ci-dessous et saisissez ce code :',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Ouvrir ${service} pour activer',
			'services.deviceCode.copyCode' => 'Copier le code d\'activation',
			'services.deviceCode.waitingForAuthorization' => 'En attente d\'autorisation…',
			'services.deviceCode.codeCopied' => 'Code copié',
			'services.oauthProxy.title' => ({required Object service}) => 'Se connecter à ${service}',
			'services.oauthProxy.body' => 'Scannez ce code QR ou ouvrez l\'URL sur n\'importe quel appareil.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Ouvrir ${service} pour se connecter',
			'services.pendingAuth.copyUrl' => 'Copier l\'URL de connexion',
			'services.pendingAuth.urlCopied' => 'URL copiée',
			'services.libraryFilter.title' => 'Filtre de bibliothèques',
			'services.libraryFilter.subtitleAllSyncing' => 'Synchronisation de toutes les bibliothèques',
			'services.libraryFilter.subtitleNoneSyncing' => 'Aucune synchronisation',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloquées',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} autorisées',
			'services.libraryFilter.mode' => 'Mode de filtrage',
			'services.libraryFilter.modeBlacklist' => 'Liste d’exclusion',
			'services.libraryFilter.modeWhitelist' => 'Liste d’inclusion',
			'services.libraryFilter.modeHintBlacklist' => 'Synchroniser toutes les bibliothèques sauf celles cochées ci-dessous.',
			'services.libraryFilter.modeHintWhitelist' => 'Synchroniser uniquement les bibliothèques cochées ci-dessous.',
			'services.libraryFilter.libraries' => 'Bibliothèques',
			'services.libraryFilter.noLibraries' => 'Aucune bibliothèque disponible',
			'services.libraryFilter.modeDescription' => 'Choisissez si les bibliothèques vérifiées sont bloquées de synchroniser ou qu’elles soient les seules bibliothéques qui synchronnent.',
			'services.seerrDescription' => 'Connectez-vous à Seerr ou Overseerr pour rechercher les titres et soumettre des demandes de médias.',
			'services.trackerDescriptions.trakt' => 'Synchroniser les épisodes et films vues avec votre compte Trakt.',
			'services.trackerDescriptions.mal' => 'Synchroniser les listes d\'anime et regarder le progrès avec MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Synchroniser les listes d\'anime et regarder le progrès avec AniList.',
			'services.trackerDescriptions.simkl' => 'Sync a regardé des films, des émissions télévisées et de l\'anime avec Simkl.',
			'services.trackerDescriptions.mdblist' => 'Afficher les notations et les listes MDBList dans les recommandations et Explore.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Ajouter un serveur ${product}',
			'addServer.serverUrls' => 'URL du serveur',
			'addServer.serverUrlsHelper' => 'Plusieurs URL possibles, séparées par des virgules.',
			'addServer.findServer' => 'Rechercher un serveur',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Recherche de serveurs ${product} locaux...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Serveurs ${product} locaux',
			'addServer.username' => 'Nom d\'utilisateur',
			'addServer.password' => 'Mot de passe',
			'addServer.signIn' => 'Se connecter',
			'addServer.change' => 'Modifier',
			'addServer.required' => 'Requis',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Impossible de joindre le serveur : ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Échec de la connexion : ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Échec de Quick Connect : ${error}',
			'addServer.addPlexTitle' => 'Se connecter avec Plex',
			'addServer.pinExpired' => 'Le PIN a expiré avant la connexion. Veuillez réessayer.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Échec de l\'enregistrement du compte : ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Saisissez l\'URL de votre serveur ${product}',
			'addServer.addConnectionTitle' => 'Ajouter une connexion',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Ajouter à ${name}',
			'addServer.signInWithPlexCard' => 'Se connecter avec Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorisez cet appareil. Les serveurs partagés sont ajoutés.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorisez un compte Plex. Les utilisateurs Home deviennent des profils.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Se connecter à ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Saisissez l\'URL de votre serveur, votre nom d\'utilisateur et votre mot de passe.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Connectez-vous à votre serveur ${product}. Sera associé à ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Emprunter à un autre profil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Réutiliser la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.',
			'addServer.invalidCredentials' => 'Nom d’utilisateur ou mot de passe incorrect',
			'addServer.authResponseNotJson' => 'La réponse d’authentification n’était pas au format JSON valide',
			'addServer.authResponseIncomplete' => 'La réponse de connexion du serveur était incomplète',
			'addServer.quickConnectRejected' => 'Quick Connect a été refusé par le serveur',
			'addServer.quickConnectNotJson' => 'La réponse de Quick Connect n’était pas au format JSON valide',
			'addServer.quickConnectMissingFields' => 'Il manque un code ou un secret dans la réponse de Quick Connect',
			'addServer.quickConnectPollRejected' => 'L’interrogation de Quick Connect a été refusée par le serveur',
			'addServer.serverTimedOut' => 'Le serveur n’a pas répondu à temps',
			'addServer.responseNotJson' => 'La réponse du serveur n’était pas au format JSON valide',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Il manque un identifiant ou un nom de serveur dans la réponse : s’agit-il d’un serveur ${product} ?',
			'addServer.probeFailed' => ({required Object error}) => 'Impossible de joindre le serveur : ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Saisissez l’URL d’au moins un serveur ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Aucun serveur ${product} joignable n’a été trouvé',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Ces URL renvoient vers différents serveurs ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Cette URL ne correspond pas au serveur ${product}',
			'addServer.redirectUnsupported' => 'Le serveur a redirigé vers une URL non prise en charge',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Le serveur a redirigé vers un hôte différent. Saisissez directement l’URL finale du serveur ${product}.',
			'addServer.redirectInsecure' => 'Le serveur a redirigé de HTTPS vers une URL non sécurisée',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Le serveur a redirigé vers une URL non prise en charge. Saisissez directement l’URL finale du serveur ${product}.',
			'addServer.directPlexServerUrl' => 'URL du serveur Plex',
			'addServer.directPlexServerUrlHelper' => 'Entrez l\'IP local et le port de votre serveur de médias Plex.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (optionnel)',
			'addServer.plexTokenHelper' => 'Laissez vide si l\'accès sans auth est autorisé sur ce serveur.',
			'addServer.plexTokenRequired' => 'Veuillez entrer votre token Plex (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex serveur de médias (direct / local)',
			'addServer.connectDirectPlexCardSubtitle' => 'Connectez-vous directement en utilisant l’IP ou l’URL local sans compte plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Connectez-vous directement en utilisant l’IP ou l’URL local. Connectez à ${name}.',
			'addServer.insecureTitle' => 'Connexion non cryptée',
			'addServer.insecureDescription' => ({required Object url}) => '${url} utilise HTTP. Des personnes sur le réseau peuvent lire ou modifier votre mot de passe, vos jetons et vos médias. Utilisez HTTPS si possible. Ne continuez que si vous faites confiance à ce réseau et acceptez le risque.',
			'addServer.allowHttp' => 'Autoriser HTTP',
			'addServer.httpsRequired' => 'Utilisez HTTPS ou autorisez explicitement une connexion non cryptée.',
			'cast.chooseDevice' => 'Coup sur un appareil',
			'cast.searching' => 'En recherche de dispositifs de châtiment...',
			'cast.connectedTo' => ({required Object device}) => 'Connectez-vous à ${device}',
			'cast.device' => 'Dispositif de casting',
			'cast.readyToCast' => 'Prêt à lancer',
			'cast.subtitle' => 'Sous-titres',
			'cast.serverNotAvailable' => 'Le serveur de médias n’est pas disponible.',
			'cast.stopCasting' => 'Arrêter de casting',
			'cast.castToDevice' => 'Changer à l\'appareil',
			'cast.noEpisodeAvailable' => 'Il n\'y a pas d\'épisode disponible pour le lancer.',
			'cast.startFailed' => 'Je ne peux pas commencer à lancer. vérifier le serveur et essayer à nouveau.',
			'automation.noActivePlayback' => 'Il n\'y a pas de session vidéo active à contrôler.',
			'notifications.newEpisodeTitle' => 'Nouveau épisode',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Essayez chaque fonctionnalité gratuitement pendant 7 jours',
			'appAccess.description' => 'Démarrez un essai de sept jours avec un accès complet à chaque fonctionnalité PlezyNG. il n\'y a pas de frais pendant le essai et pas d\'abonnement. Après le essai, une achat de vie au prix de votre magasin déclenche PlezyNG pour la vie.',
			'appAccess.trialEndedDescription' => 'Déblocage de chaque fonctionnalité dans PlezyNG pour la vie avec une achat au prix de votre magasin.',
			'appAccess.startTrial' => 'Démarrer mon essai gratuit de 7 jours',
			'appAccess.trialActive' => 'Votre essai de 7 jours en plein fonctionnement est actif.',
			'appAccess.trialEnded' => 'Votre procès de 7 jours est terminé',
			'appAccess.trialStartFailed' => 'Je ne pouvais pas sauver le test sur ce appareil. veuillez essayer à nouveau.',
			'appAccess.lifetimeTitle' => 'PlezyNG déconnecté pour la vie',
			'appAccess.lifetimeBody' => 'Merci ! vous avez accès à toute la vie à chaque fonctionnalité PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG accès à vie',
			'appAccess.manageDescription' => 'Essayez chaque fonctionnalité gratuitement pendant 7 jours, puis déverrouillez tout pour la vie avec un seul paiement au prix de votre magasin.',
			'appAccess.buy' => ({required Object price}) => 'Déconnecter chaque fonctionnalité pour ${price}',
			'appAccess.loadingPrice' => 'Le prix de la boutique...',
			'appAccess.retryPrice' => 'Retour sur le prix',
			'appAccess.restore' => 'Restaurer l’achat de vie',
			'appAccess.pending' => 'Votre achat attend le paiement ou l\'approbation.Lifetime accès s\'ouvrira dès que le magasin le remplit.',
			'appAccess.storeUnavailable' => 'Vérifiez que vous êtes inscrit dans le magasin et que les achats sont autorisés sur ce dispositif.',
			'appAccess.productNotFound' => 'Le déclin de vie PlezyNG n\'est pas encore disponible dans ce magasin.',
			'appAccess.productQueryFailed' => 'Je ne pourrais pas charger le prix du magasin. vérifier votre connexion et essayer à nouveau.',
			'appAccess.purchaseFailed' => 'L’achat n’a pas été effectué, essayez-le encore.',
			'appAccess.restoreFailed' => 'Je ne pouvais pas aller au magasin pour restaurer votre achat.',
			'appAccess.nothingToRestore' => 'Le numéro PlezyNG achat à vie a été trouvé pour ce compte de magasin.',
			'detail.endsAt' => ({required Object time}) => 'Se termine à ${time}',
			'watchLink.serverUnavailable' => 'Je ne pouvais pas accéder à un serveur Plex pour ce lien.',
			'watchLink.notFound' => 'Je ne pouvais pas trouver ce spectacle ou le film sur vos serveurs Plex.',
			'watchLink.ambiguous' => 'Ce lien correspond aux éléments sur plus d\'un serveur.Ajout d\'un server au lien.',
			'watchLink.plexOnly' => 'Les liens de vision ne supportent actuellement que les serveurs Plex.',
			'watchLink.unsupportedItem' => 'Les liens de regarder ne peuvent ouvrir qu\'un spectacle ou un film.',
			'watchLink.menuItem' => 'Afficher le lien',
			'watchLink.dialogTitle' => 'Voir le lien',
			'watchLink.dialogShowHint' => 'Pour ouvrir ce lien, il est possible de jouer le prochain épisode.Add &mode=shuffle à la fin pour jouer le spectacle sur shuffle.',
			'watchLink.dialogMovieHint' => 'En ouvrant ce lien, le film est joué.',
			'watchLink.copy' => 'Copie',
			'watchLink.copied' => 'Link copie',
			'homeLayout.title' => 'Home Layout',
			'homeLayout.resetToast' => 'Réservez à la page originale Plezy',
			'homeLayout.resetHeroTitle' => 'Résetez le layout de l\'héroïne à stock Plezy ?',
			'homeLayout.resetHeroBody' => 'Il détourne l\'établissement de chaque rang et remet le seul drapeau de rotation au sommet de la maison, comme avant que les rangs de héros existent.',
			'homeLayout.removeRowTitle' => 'Réserver la ligne de maison ?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} sera supprimé. ceci ne peut être non.',
			'homeLayout.sync' => 'Synchroniser',
			'homeLayout.syncAccountTitle' => 'Synchroniser le layout avec votre compte Plex',
			'homeLayout.syncAccountOn' => 'Sur : ce dispositif partage la commande de la ligne, les lignes, le héros et l\'automatisation avec vos autres appareils.',
			'homeLayout.syncAccountOff' => 'Off : ce dispositif maintient son propre layout.',
			'homeLayout.syncNow' => 'Synchronisation maintenant',
			'homeLayout.plexHomeManager' => 'Plex Gestion de la maison',
			'homeLayout.managePlexRows' => 'Gérer Plex rangs dans Plezy',
			'homeLayout.managePlexRowsDescription' => 'Ouvert pour organiser les lignes sélectionnées à domicile',
			'homeLayout.organizeHomeRows' => 'Organiser les roues de maison',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} lignes: mouvement, héros, auto-slide, suppression',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Résultats de la ${library}',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Continuez à regarder + ${n} lignes: mouvement, Bibliothèque, Maison, Héroe, Slide automatique',
			'homeLayout.renderAsHero' => 'Render comme une carte héros',
			'homeLayout.heroOnlySingleCollection' => 'Disponible uniquement lorsque cette ligne se résout aux titres réels d\'une seule collection',
			'homeLayout.hero' => 'Héroe',
			'homeLayout.autoSlide' => 'Autoslire',
			'homeLayout.autoSlideDescription' => 'Les arros (PC) et d-pad (TV) fonctionnent toujours et reprenent le timer.',
			'homeLayout.autoSlideEditDescription' => 'Il se décline : il ne se déplace que lorsque vous cliquez sur une armoire (PC) ou pressez la gauche/droite sur la télévision (TV).',
			'homeLayout.enableHeroFirst' => 'Un héros en premier',
			'homeLayout.showOnHome' => 'Afficher sur l\'écran de maison',
			'homeLayout.home' => 'Accueil',
			'homeLayout.removeFromHome' => 'Retirez de chez vous',
			'homeLayout.selectRowsFirst' => 'Sélectionnez les lignes de maison ci-dessous d\'abord.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex rangées gérées',
			'homeLayout.continueWatching' => 'Continuer à regarder',
			'homeLayout.continueWatchingLibraryDescription' => 'La suite de la bibliothèque de la suite',
			'homeLayout.continueWatchingHomeDescription' => 'Le nouveau progrès de la ligne montrée sur Home',
			'homeLayout.nextUpHomeDescription' => 'La prochaine série de l\'épisode non vu diffusée séparément sur Home',
			'homeLayout.library' => 'Bibliothèque',
			'homeLayout.showInRecommended' => 'Présentation dans la bibliothèque recommandée',
			'homeLayout.customPlexRow' => 'Résultats de la Plex',
			'homeLayout.heroNeedsLibrary' => 'Vérifier la bibliothèque d\'abord - Le héros a besoin d\'un endroit où il faut montrer',
			'homeLayout.heroNeedsSurface' => 'Vérifier la bibliothèque ou la maison d\'abord - Le héros a besoin d\'un endroit où il faut montrer',
			'homeLayout.removeHub' => 'Réserver le Hub',
			'homeLayout.noPlexRows' => 'Aucune rangée gérée par Plex n’a été renvoyée pour cette bibliothèque.',
			'homeLayout.openDetails' => 'détails ouverts',
			'homeLayout.heroCards' => 'Cartes héros',
			'homeLayout.tapHeroCard' => 'Tapeur d\'une carte héros',
			'homeLayout.tvPlayFocus' => 'Remote TV : le bouton de jeu',
			'homeLayout.tvPlayFocusDescription' => 'D-pad descendre s\'arrête sur le bouton Play avant de se déplacer à la prochaine ligne.',
			'homeLayout.tvWrap' => 'TV Remote : cartes de la bande-annonce',
			'homeLayout.tvWrapDescription' => 'Ensuite, le dernier passe à la première carte, le dernier se passe à la dernière carte, le premier passe toujours à la barre.',
			'homeLayout.castOnHero' => 'Les Banner Hero',
			'homeLayout.castOnHeroDescription' => 'Affiche le cast le long du fond d\'un banner héros. Off ne tient que le titre et le résumé.',
			'homeLayout.customRows' => 'Ronde de Custom',
			'homeLayout.loading' => 'La mise à jour de la maison...',
			'homeLayout.noCustomRows' => 'Pas de coutures encore',
			'homeLayout.addRowHint' => 'Utilisez Add Home row pour créer un.',
			'homeLayout.addHomeRow' => 'Ajouter la ligne de maison',
			'homeLayout.addHomeRowDescription' => 'Choisissez une catégorie ; la nouvelle ligne est ajoutée à l\'Organisateur automatiquement',
			'homeLayout.removeRow' => 'Réserver la ligne',
			'homeLayout.recentlyAdded' => 'Récemment ajouté',
			'homeLayout.recentlyReleased' => 'Récemment libéré',
			'homeLayout.movieCollections' => 'Film Collections',
			'homeLayout.showCollections' => 'Afficher les collections',
			'homeLayout.rowTitle' => 'Titre Row',
			'homeLayout.content' => 'contenu',
			'homeLayout.showThisRowIn' => 'Afficher cette ligne dans :',
			'homeLayout.libraryRecommended' => 'Bibliothèque recommandée',
			'homeLayout.heroCard' => 'Cartes héros',
			'homeLayout.heroCardDescription' => 'Il apparaît comme une carte de rotation à largeur entière au lieu d\'un plafond de poster.',
			'homeLayout.heroUnavailableDescription' => 'Seulement disponible lorsque cette ligne se résout aux titres réels d\'une seule collection - avec plus d\'une collection sélectionnée il n\'y a pas de titre unique à tourner.',
			'homeLayout.librariesSelection' => 'Bibliothèques (lettre toutes les bibliothèques non vérifiées pour inclure chaque bibliothèque)',
			'homeLayout.librariesMergedDescription' => 'Chaque bibliothèque qui est vérifiée ici est fusionnée dans cette ligne.',
			'homeLayout.movieCollectionsSelection' => 'Collections de films (levez toutes les livres non vérifiés pour chaque bibliothèque sélectionnée)',
			'homeLayout.showCollectionsSelection' => 'Afficher les collections (levez toutes les bibliothèques non vérifiées)',
			'homeLayout.collectionRowsDescription' => 'Si exactement une collection se rencontre, ses titres apparaissent directement dans la ligne.Si plus d\'une collection se rencontre , chaque collection apparaît comme un seul poster - tapez-le pour ouvrir cette collection.',
			'homeLayout.allCollections' => 'Toutes les collections',
			'homeLayout.noRowsHere' => 'Pas de rangs ici encore.',
			'homeLayout.hideWatchedRows' => 'Mettre des objets cachés en ligne',
			'homeLayout.hideWatchedRowsDescription' => 'Titres complètement regardés quittent la maison et la bibliothèque Les lignes recommandées.',
			'homeLayout.untitledCollection' => 'Collection sans titre',
			'homeLayout.moveRowHint' => 'Up/Down: déplacer la ligne · Sélectionnez: la débarrasser ici · Retour: annuler',
			'homeLayout.organizeRowsHint' => 'Sélectionnez sur une ligne (ou retenez Sélectionnez): déplacez-le · gauche/droite: options de ligne · Retour: fait',
			'homeLayout.layoutNavDescription' => 'Choisissez les catégories de catégories, bibliothèques et collections',
			'homeLayout.editHomeRow' => 'Edit à domicile',
			'homeLayout.resetHeroButton' => 'Résetez le layout de l\'héroïne à stock Plezy',
			'homeLayout.reorderingUnlocked' => 'Réservation déclenchée',
			'homeLayout.reorderingLocked' => 'Réservation bloquée',
			'homeLayout.rowsCanBeDragged' => 'Les rayons peuvent être tirés — tapez le verrou pour éviter que',
			'homeLayout.tapLockToDrag' => 'Tapez le lock pour tirer les lignes',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Numéro de la personne : ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Masquer',
			'homeLayout.remove' => 'Retirer',
			'homeLayout.libraryResumeRow' => 'La bibliothèque de la suite',
			'homeLayout.pressAgainToDelete' => 'Appuyez à nouveau sur le supprimant',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'sur',
			'homeLayout.resetHeroButtonDescription' => 'Il détourne la configuration de chaque rang et ramène le seul drapeau de roulement au sommet, comme avant que les rangs de héros existent.',
			'homeLayout.tapHeroCardDescription' => 'Choisissez si le tapage ou la sélection d\'une carte Hero commence à reproduire ou ouvre ses détails.',
			'homeLayout.heroTapPlayDescription' => 'Démarrez immédiatement l’élément sélectionné.',
			'homeLayout.heroTapDetailsDescription' => 'Ouvrez les détails de l\'élément sélectionné avant de choisir une action.',
			'platform.localNetworkPermission' => 'PlezyNG se connecte à vos serveurs multimédias et à vos appareils de lecture sur votre réseau local.',
			'platform.locationPermission' => 'PlezyNG utilise l\'accès à la localisation lorsque iOS l\'exige pour détecter votre réseau local et se connecter à vos serveurs de médias.',
			'platform.photoLibraryPermission' => 'Choisissez des images de votre photothèque pour illustrer vos médias.',
			'platform.cameraPermission' => 'Scannez des codes QR pour associer une Companion Remote.',
			'universalMedia.title' => 'Médias ouverts',
			'universalMedia.shortcutHelp' => 'Jouez à un lien, une playlist ou un fichier pour cette session.',
			'universalMedia.intro' => 'Ouvrez un lien, une liste de lecture ou un fichier. Playback utilise le lecteur standard de PlezyNG et n’ajoute pas d’historique à votre bibliothèque.',
			'universalMedia.openWhat' => 'Que voudriez-vous ouvrir ?',
			'universalMedia.stream' => 'Adresse de courant',
			'universalMedia.playlist' => 'Joueurs',
			'universalMedia.files' => 'Les fichiers de dispositif',
			'universalMedia.favorites' => 'Réservation de flux favoris',
			'universalMedia.address' => 'Adresse médiatique',
			'universalMedia.addressHelp' => 'Les URL avec des paramètres d\'accréditation ou de signature reconnus ne sont utilisés que pour cette session et ne peuvent pas être sauvegardés comme favoris.',
			'universalMedia.displayName' => 'Nom d’affichage (optionnel)',
			'universalMedia.displayNameHelp' => 'Choisissez un nom court pour le lecteur et les contrôles de médias du système.',
			'universalMedia.allowHttp' => 'Permettre une connexion HTTP non cryptée',
			'universalMedia.allowHttpHelp' => 'HTTP n\'encrypte pas la connexion. permet seulement sur un réseau fiable. Utilisez HTTPS quand c\'est possible.',
			'universalMedia.advancedProtocols' => 'MPV seulement: entrez une adresse RTSP, RTMP/RTMPS, UDP ou RTP. Ces adresses ne peuvent pas être sauvegardées comme préférées.',
			'universalMedia.liveStream' => 'Traiter comme vivant',
			'universalMedia.liveStreamHelp' => 'Utilisez ceci pour la vidéo ou la radio en direct. l\'application cache la barre du temps, les boutons de ski et l\'option go-to-time.',
			'universalMedia.privateSession' => 'Seul ce recueil utilise l’adresse.Save an eligible stream favorite to keep it in this profile.',
			'universalMedia.saveFavorite' => 'Sauvegarder les favoris',
			'universalMedia.playNow' => 'Jouer maintenant',
			'universalMedia.favoriteSaved' => 'Stream favorite a été sauvé à ce profil',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Skipped ${count} unsupported or unsafe playlist entry.', many: 'Skipped ${count} unsupported or unsafe playlist entries.', other: 'Skipped ${count} unsupported or unsafe playlist entries.', ), 
			'universalMedia.playlistAddress' => 'L’adresse de la playlist',
			'universalMedia.playlistAddressHelp' => 'Ouvrez une liste de lecture M3U, M3u8 ou PLS à partir d\'une adresse Web. Les liens en streaming directs ne sauvent pas la liste de jeu.',
			'universalMedia.choosePlaylist' => 'Choisissez le fichier playlist',
			'universalMedia.openPlaylist' => 'Ouverture playlist',
			'universalMedia.playlistFormatsHelp' => 'Une liste de lecture peut contenir jusqu\'à 1000 articles et 2 MB. HLS se manifeste comme des courants afin que le joueur puisse choisir une qualité.',
			'universalMedia.noFavorites' => 'Il n\'y a pas encore de préférés en streaming. les favoris restent dans ce profil.',
			'universalMedia.removeFavorite' => 'Supprimer les flux préférés',
			'universalMedia.filesHelp' => 'Choisissez des fichiers audio, vidéo ou ISO pour une couverture temporaire.Fichiers et URL ne sont pas ajoutés à l\'histoire de la bibliothèque.',
			'universalMedia.chooseFiles' => 'Choisir des fichiers',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '1 fichier sélectionné', many: '${count} fichiers sélectionnés', other: '${count} fichiers sélectionnés', ), 
			'universalMedia.wifiTransfer' => 'Envoyer des fichiers via Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Transfert des fichiers soutenus d\'un navigateur sur le même réseau fiable.',
			'universalMedia.wifiTransferIntro' => 'Ouvrez cette adresse dans un navigateur sur un autre appareil. Sélectionnez les fichiers pour les ajouter à la bibliothèque des Fichiers et livres de cet appareil .',
			'universalMedia.wifiTransferPrivacy' => 'Ce dispositif reçoit des fichiers sur votre réseau local.Celui qui connaît cette adresse peut envoyer des ficher jusqu\'à ce que vous arrêtez le transfert ou l\'adresse expire après 15 minutes.Maximum: 100 fichières, 4 GiB par fichier, 10 GiB total.',
			'universalMedia.wifiTransferStarting' => 'Pour un transfert privé et à temps limité...',
			'universalMedia.wifiTransferUnavailable' => 'Vous ne pouvez pas commencer le transfert. vérifier l\'accès au réseau local et essayer à nouveau.',
			'universalMedia.openThisAddress' => 'Ouvrez l\'une de ces adresses sur le dispositif d\'envoi',
			'universalMedia.copyAddress' => 'Copie de l\'adresse de transfert',
			'universalMedia.addressCopied' => 'Adresse de transfert copiée',
			'universalMedia.transferExpires' => ({required Object time}) => 'Cette adresse expire dans ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'fichier ${count} reçu', many: 'Les fichiers ${count} reçus', other: 'Les fichiers ${count} reçus', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Recevoir ${size}',
			'universalMedia.stopTransfer' => 'Arrêter le transfert et invalider l’adresse',
			'universalMedia.startTransfer' => 'Démarrer le transfert',
			'universalMedia.wifiImportedFiles' => 'Transfert Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Envoyer des fichiers à PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Choisissez les fichiers audio, vidéo, ebook ou comique pour envoyer. Les fichières sont sauvegardées dans la bibliothèque des Fichiers et livres de cet appareil. Maximum: 100 fichires, 4 GiB par fichier, 10 GiB total.',
			'universalMedia.uploadFilesLabel' => 'Les fichiers à envoyer',
			'universalMedia.uploadSelected' => 'Télécharger les fichiers sélectionnés',
			'universalMedia.uploadSelectFirst' => 'Choisissez d’abord un ou plusieurs fichiers.',
			'universalMedia.uploading' => 'Envoyer',
			'universalMedia.uploadComplete' => 'Fichiers ajoutés à PlezyNG.',
			'universalMedia.uploadFailed' => 'Le fichier ne pouvait pas être ajouté. Gardez cette page ouverte et essayez à nouveau.',
			'universalMedia.liveCue' => 'Vivre',
			'universalMedia.liveSession' => 'Stream en direct',
			'universalMedia.liveCueHelp' => 'Pour la vidéo ou la radio en direct, l\'application cache la barre de temps et les boutons échappent.',
			'universalMedia.sessionOnly' => 'Ce playback n’est qu’une session',
			'universalMedia.sessionOnlyHelp' => 'Playback ne sauve jamais le progrès ou l\'histoire.Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'Ajustement de l\'image',
			'universalMedia.pictureHelp' => 'Ces changements d\'image n\'affectent que ce playback. Ils sont réinitialisés lorsque le playback se termine.',
			'universalMedia.resetPicture' => 'Récupérer l\'image',
			'universalMedia.brightness' => 'Brilleur',
			'universalMedia.contrast' => 'Contraste',
			'universalMedia.gamma' => 'La gamme',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturation',
			'universalMedia.view360' => 'Voir la vidéo à 360°',
			'universalMedia.view360Help' => 'Utilisez ceci pour la vidéo 360° équirectangulaire. MPV a besoin du filtre v360 de FFmpeg pour cette vue.',
			'universalMedia.view360Unavailable' => 'Cette configuration mpv ne pouvait pas appliquer le filtre 360°.',
			'universalMedia.view360Yaw' => 'Vue horizontale',
			'universalMedia.view360Pitch' => 'Vue verticale',
			'universalMedia.view360FieldOfView' => 'Le champ de vue',
			'universalMedia.recordStream' => 'Résumé Live Stream',
			'universalMedia.stopRecording' => 'Arrêter et sauvegarder l’enregistrement',
			'universalMedia.recordingStarted' => 'L\'enregistrement est actif. Laisser le playback s\'arrête et sauve l\'enregistration.',
			'universalMedia.recordingSaved' => 'L’enregistrement est terminé et sauvé.',
			'universalMedia.recordingActive' => 'Enregistrer sur ce dispositif. Laisser le playback s\'arrête et la sauve.',
			'universalMedia.recordingFormatHelp' => 'Pour la vidéo, choisissez MKV ou MPEG-TS. Pour l\'audio, sélectionnez MKA ou MKV.',
			'universalMedia.replaceRecordingTitle' => 'Remplacer cette enregistrement ?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG récupère le fichier existant pendant l’enregistrement.Si il ne peut pas sauvegarder la nouvelle enregistrement, Plezy NG rétablit la sauvegardation.',
			'universalMedia.replaceRecording' => 'Remplacer le fichier',
			'universalMedia.discHelp' => 'Ouvrez un disque dans le disque optique de cet ordinateur. Vous pouvez également ouvrir une image ISO des fichiers Device.',
			'universalMedia.discs' => 'Le disque optique',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-ray',
			'universalMedia.audioCd' => 'CD audio',
			'universalMedia.discAvailability' => 'La lecture du disque nécessite une configuration MPV compatible, un disque supporté et la permission système d\'exploitation.',
			'universalMedia.converterTitle' => 'Convertir un fichier médiatique local',
			'universalMedia.converterHelp' => 'Convertir un fichier local ou le remuer avec FFmpeg.',
			'universalMedia.converterIntro' => 'Convertez un fichier audio ou vidéo local dans un format qui fonctionne sur plusieurs appareils.',
			'universalMedia.converterPrivacy' => 'FFmpeg doit être installé sur ce ordinateur. Conversion ne lit que les fichiers locaux. Il ne télécharge pas les courants ou supprime DRM.',
			'universalMedia.converterChooseInput' => 'Choisissez un fichier médiatique local',
			'universalMedia.converterFormat' => 'Format de sortie',
			'universalMedia.converterMp4' => 'MP4 · H.264 et AAC',
			'universalMedia.converterM4a' => 'M4A · AAC audio',
			'universalMedia.converterMp3' => 'MP3 et audio',
			'universalMedia.converterSaveAs' => 'Enregistrer les médias convertis comme',
			'universalMedia.converterExtensionMismatch' => 'Choisissez un nom de fichier avec l\'extension de sortie sélectionnée.',
			'universalMedia.converterUnsupportedInput' => 'Choisissez un fichier audio ou vidéo.',
			'universalMedia.converterLocalOnly' => 'Le fichier sélectionné n\'est pas disponible en tant que voie d\'appareil locale.',
			'universalMedia.converterReplaceTitle' => 'Remplacer ce fichier ?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG récupère le fichier existant jusqu\'à ce que la copie convertie soit sauvée.',
			'universalMedia.converterStarting' => 'Commencez par FFmpeg...',
			'universalMedia.converterProgress' => 'Convertir sur cet ordinateur...',
			'universalMedia.converterComplete' => 'Conversion complète. le nouveau fichier est prêt.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg Il manque ou ne soutient pas ce format.',
			'universalMedia.converterFailed' => 'Vérifiez que le fichier source peut être lu et que la destination a suffisamment d\'espace gratuit.',
			'universalMedia.converterCancelled' => 'La conversion a été annulée. la sortie incomplète a été supprimée.',
			'universalMedia.converterDesktopOnly' => 'La conversion locale est disponible sur les ordinateurs de bureau avec FFmpeg installé.',
			'universalMedia.converterStart' => 'Conversion des fichiers',
			'universalMedia.mediaToolsTitle' => 'Les outils médiatiques',
			'universalMedia.mediaToolsShortcut' => 'Capture ou partage des médias, ajouter des extensions de recherche, ou utiliser la ligne de commande.',
			'universalMedia.mediaToolsIntro' => 'Choisissez un outil focalisé. capture et stream-out utilisez FFmpeg installé sur ce bureau. Extensions et les commandes CLI utilisent les requêtes HTTPS liées et le flux Open media existant.',
			'universalMedia.mediaToolsAccessibility' => 'Les choix d\'outils et les contrôles fonctionnent avec le toucher, le pointteur, le clavier et le focus D-pad. Les modifications de l\'état de l\'enregistrement, du partage et de la recherche sont annoncées.',
			'universalMedia.mediaTool' => 'Outils de médias',
			'universalMedia.captureIntro' => 'Enregistrez votre écran ou une caméra dans un fichier MP4 sur ce ordinateur. FFmpeg doit être installé et inclure le codage H.264.',
			'universalMedia.captureNoDevices' => 'Aucun écran ou une caméra n\'a été trouvée. Vérifier FFmpeg support de capture et les autorisations de confidentialité du système d\'exploitation.',
			'universalMedia.captureSource' => 'Écran ou caméra',
			'universalMedia.captureAudioSource' => 'Entrée audio (optionnelle)',
			'universalMedia.captureAudioHelp' => 'Ajouter de l\'audio à partir d\'un microphone ou d\'une entrée disponible. Les choix du dispositif dépendent de FFmpeg et des autorisations du système.',
			'universalMedia.captureAudioNone' => 'Pas d’audio',
			'universalMedia.captureWaylandHelp' => 'Wayland limite cette capture XWayland au X display. Windows hors XWayland ne peut pas apparaître.',
			'universalMedia.captureFrameRate' => 'Résultats de l’enregistrement',
			'universalMedia.capturePrivacy' => 'L\'enregistrement est enregistré uniquement au fichier que vous choisissez. capture de microphone est facultative. PlezyNG ne télécharge pas l\'enregistrement.',
			'universalMedia.captureSaveAs' => 'Enregistrer l’écran comme',
			'universalMedia.captureExtensionMismatch' => 'Choisissez un nom de fil qui se termine dans .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg ou l\'encoder vidéo H.264 n\'est pas disponible. installez une construction FFmpeg soutenue, puis essayez de nouveau.',
			'universalMedia.captureFailed' => 'Vérifiez la permission du dispositif, le stockage disponible et le support FFmpeg.',
			'universalMedia.captureSaved' => 'L’enregistrement d’écran a été sauvé.',
			'universalMedia.captureElapsedLabel' => 'Temps d\'enregistrement',
			'universalMedia.captureStart' => 'Commencer l’enregistrement',
			'universalMedia.captureStop' => 'Arrêter et sauver',
			'universalMedia.captureMode' => 'capture',
			'universalMedia.shareMode' => 'partage',
			'universalMedia.shareIntro' => 'Envoyez un fichier de médias local à un autre appareil sur votre réseau privé. PlezyNG crée un flux temporaire HLS.',
			'universalMedia.sharePrivacy' => 'Tout le monde sur votre réseau local qui reçoit le lien privé peut regarder pendant qu\'il est actif. Le lien expire après 60 minutes. Arrêter de partager pour fermer le serveur et invalider le lien.',
			'universalMedia.shareChooseFile' => 'Choisissez le fichier médiatique',
			'universalMedia.shareChooseHelp' => 'Sélectionnez un fichier audio ou vidéo local. Le fichier reste sur ce ordinateur.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.shareFfmpegMissing' => 'FFmpeg ou les codes H.264/AAC ne sont pas disponibles. Installez FFmpeg avec le support de codage H.264 et AAC.',
			'universalMedia.shareFailed' => 'Le courant ne pouvait pas commencer ou s\'arrêter inattendu. vérifier FFmpeg et l\'accès au réseau.',
			'universalMedia.shareActive' => 'Le courant est prêt sur votre réseau privé.',
			'universalMedia.shareEnded' => 'Les médias ont atteint la fin et ne sont plus partagés.',
			'universalMedia.shareStopped' => 'Le lien temporaire n\'est plus valide.',
			'universalMedia.shareUrlCopied' => 'L’adresse est copiée.',
			'universalMedia.shareOpenUrl' => 'Ouvrez cette adresse dans un joueur sur l\'autre appareil',
			'universalMedia.shareCopyUrl' => 'Copie de l’adresse Stream',
			'universalMedia.shareExpiresLabel' => 'Le lien expire à',
			'universalMedia.shareStarting' => 'Préparer le flux...',
			'universalMedia.shareStart' => 'Commencer partage',
			'universalMedia.shareStop' => 'Arrêter de partager',
			'universalMedia.extensionsMode' => 'Extensions et CLI',
			'universalMedia.extensionsIntro' => 'Ajoutez une extension de recherche uniquement pour trouver les médias. Choisissez un résultat pour le charger dans le formulaire familial Open media.',
			'universalMedia.extensionsPrivacy' => 'Un manifeste peut définir un endpoint de recherche et des champs de réponse de la carte de HTTPS. Il ne peut pas exécuter le code, ajouter des titres de requête, lire les fichiers, ou lancer les commandes shell.',
			'universalMedia.extensionImport' => 'Ajouter l’extension manifeste',
			'universalMedia.extensionEmpty' => 'Aucun service de recherche encore. Choisissez un fichier manifeste fiable JSON pour ajouter un.',
			'universalMedia.extensionChoose' => 'Service de recherche',
			'universalMedia.extensionSearchConsent' => 'Chaque recherche envoie vos mots à ce service HTTPS. Les résultats ne s\'ouvrent qu\'après que vous choisissez un.',
			'universalMedia.extensionSearchLabel' => 'Médias de recherche',
			'universalMedia.extensionSearch' => 'Recherche',
			'universalMedia.extensionSearching' => 'Rechercher...',
			'universalMedia.extensionNoResults' => 'Aucun résultat de médias sécurisés n\'a été retourné. essayez une autre recherche.',
			'universalMedia.extensionInstallTitle' => 'Ajouter ce service de recherche ?',
			'universalMedia.extensionReplaceTitle' => 'Mettre à jour ce service de recherche ?',
			'universalMedia.extensionService' => 'Service',
			'universalMedia.extensionEndpoint' => 'HTTPS point de fin',
			'universalMedia.extensionConsent' => 'Votre texte de recherche est envoyé à ce service. le manifeste ne contient pas de code exécutable. Continuez seulement si vous avez confiance à ce point de fin.',
			'universalMedia.extensionInstall' => 'Ajouter service',
			'universalMedia.extensionReplace' => 'Service de mise à jour',
			'universalMedia.extensionRemoveTitle' => 'Supprimer ce service de recherche ?',
			'universalMedia.extensionRemoveHelp' => 'Ceci supprime le service de ce profil. PlezyNG n\'a pas contact avec son endpoint.',
			'universalMedia.extensionRemove' => 'Supprimer le service',
			'universalMedia.extensionInvalidManifest' => 'Ce fichier n\'est pas un manifeste d\'extension soutenu. voir le guide Open media pour le format.',
			'universalMedia.extensionSaveFailed' => 'L’extension ne pouvait pas être sauvée au profil actif.',
			'universalMedia.extensionSearchFailed' => 'Le service de recherche n\'a pas retourné une réponse valide. vérifier le point de fin et essayer à nouveau.',
			'universalMedia.cliTitle' => 'Ligne de commande',
			'universalMedia.cliHelp' => 'Utilisez le guide plezyctl pour valider un manifeste ou rechercher la même extension. Revue son service HTTPS avant chaque recherche. Résultats ouverts dans le formulaire médiatique existant; sélectionnez le bouton de reprise pour démarrer.',
			'universalMedia.cliCopyExample' => 'Copie de l’exemple',
			'universalMedia.cliCopied' => 'Commande exemplaire copié.',
			'universalMedia.captureScreen' => 'écran',
			'universalMedia.captureDefaultAudio' => 'Introduction audio par défaut',
			'universalMedia.shareQrLabel' => 'Code QR pour l\'adresse de courant temporaire',
			'universalMedia.shareQrHelp' => 'Scanner avec un lecteur compatible connecté au même réseau privé.',
			'universalMedia.shareHttpHint' => 'Ce flux utilise HTTP non crypté. Dans PlezyNG, permettez HTTP avant de l\'ouvrir.',
			'universalMedia.allowFtp' => 'Permettre FTP',
			'universalMedia.allowFtpHelp' => 'FTP envoie les médias sans cryptage.Utilisez uniquement sur des réseaux fiables.',
			'fileSources.title' => 'Fichiers et livres',
			'fileSources.subtitle' => 'Lire, écouter et regarder de vos propres fichiers.',
			'fileSources.add' => 'Ajouter source',
			'fileSources.importFiles' => 'Importer des fichiers',
			'fileSources.localFiles' => 'sur ce dispositif',
			'fileSources.source' => 'source',
			'fileSources.name' => 'Nom',
			'fileSources.endpoint' => 'URL du serveur',
			'fileSources.smbEndpointHint' => 'Exemple : smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Saisissez un serveur SMB et un dossier partagé.',
			'fileSources.root' => 'Fiche ou préfix',
			'fileSources.smbFolderHelp' => 'Laissez vide pour utiliser tout le dossier partagé, ou saisissez un dossier qu’il contient.',
			'fileSources.username' => 'Nom d\'utilisateur',
			'fileSources.smbDomain' => 'Domaine (facultatif)',
			'fileSources.password' => 'Mot de passe',
			'fileSources.token' => 'API Télécharger',
			'fileSources.accessKey' => 'ID clé d\'accès',
			'fileSources.secretKey' => 'Clé d\'accès secret',
			'fileSources.sessionToken' => 'Le token de session (optional)',
			'fileSources.region' => 'Région',
			'fileSources.clientId' => 'ID client de l\'AAAUTH',
			'fileSources.clientSecret' => 'OAuth client secret (seulement sur le bureau Google)',
			'fileSources.allowHttp' => 'Autoriser HTTP non chiffré sur un réseau de confiance',
			'fileSources.smbEncryption' => 'Chiffrer la connexion SMB3',
			'fileSources.smbEncryptionHint' => 'Utiliser le chiffrement SMB3 lorsque le NAS le prend en charge.',
			'fileSources.connect' => 'Se connecter',
			'fileSources.cancel' => 'Annuler',
			'fileSources.save' => 'Enregistrer',
			'fileSources.close' => 'Fermer',
			'fileSources.removeSource' => 'La source disconnectée',
			'fileSources.disconnectMessage' => 'Déconnecter cette source ? Les fichiers téléchargés et votre historique de lecture et d’écoute resteront sur cet appareil.',
			'fileSources.localFolder' => 'Choisir la carte',
			'fileSources.empty' => 'Rien ici pour l\'instant',
			'fileSources.emptyHint' => 'Ajouter une source ou importer un livre, un livre audio, une musique ou un vidéo.',
			'fileSources.search' => 'Recherchez ce dossier',
			'fileSources.searchCached' => 'Rechercher la bibliothèque sauvée',
			'fileSources.refresh' => 'Rafraîchir',
			'fileSources.loadMore' => 'Charger plus',
			'fileSources.offline' => 'Disponible en offline',
			'fileSources.download' => 'Restez hors ligne',
			'fileSources.removeDownload' => 'Supprimer une copie offline',
			'fileSources.continueReading' => 'Continuer la lecture',
			'fileSources.continueListening' => 'Continuez à écouter',
			'fileSources.continueWatching' => 'Continuez à regarder',
			'fileSources.read' => 'Lire',
			'fileSources.listen' => 'Écouter',
			'fileSources.play' => 'Lire',
			'fileSources.pause' => 'Pâques',
			'fileSources.stop' => 'Arrêter',
			'fileSources.startOver' => 'Démarrer par',
			'fileSources.finished' => 'Terminé',
			'fileSources.markFinished' => 'Marque terminé',
			'fileSources.markUnfinished' => 'Marque infinie',
			'fileSources.editions' => 'éditions et fichiers',
			'fileSources.chapters' => 'Chapitres',
			'fileSources.bookmarks' => 'Les notes et les notes',
			'fileSources.bookmark' => 'Ajouter le bookmark',
			'fileSources.highlight' => 'L’accent',
			'fileSources.note' => 'Note',
			'fileSources.delete' => 'Supprimer',
			'fileSources.export' => 'Les notes d\'exportation',
			'fileSources.exported' => 'Les notes exportées',
			'fileSources.sync' => 'Sync de progrès',
			'fileSources.synced' => 'Progrès synchronisé',
			'fileSources.conflict' => 'Un autre appareil a une position différente. Choisissez où continuer.',
			'fileSources.useLocal' => 'Utilisez ce dispositif',
			'fileSources.useRemote' => 'Utiliser un autre appareil',
			'fileSources.history' => 'Histoire de position',
			'fileSources.groupAudio' => 'Écouter comme un livre audio',
			'fileSources.groupHint' => 'Combine les fichiers audio actuellement chargés dans cette dossier.Contactez toutes les pages d\'abord.',
			'fileSources.order' => 'Ordonnance fichier',
			'fileSources.moveUp' => 'Mouvement en haut',
			'fileSources.moveDown' => 'Mouvez-vous en bas',
			'fileSources.speed' => 'La vitesse de la playback',
			'fileSources.sleep' => 'Minuterie de veille',
			'fileSources.sleepOff' => 'Désactivé',
			'fileSources.endChapter' => 'Fin du chapitre',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minute', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes', ), 
			'fileSources.skipBack' => 'Rappelons le ski',
			'fileSources.skipForward' => '- Skip en avant',
			'fileSources.smartRewind' => 'Le retour intelligent après une pause',
			'fileSources.playbackOptions' => 'Écouter les options',
			'fileSources.remaining' => ({required Object time}) => '${time} Réservé',
			'fileSources.contents' => 'contenu',
			'fileSources.readerSettings' => 'Lire les paramètres',
			'fileSources.fontSize' => 'Taille de texte',
			'fileSources.lineHeight' => 'Lien de spacing',
			'fileSources.margin' => 'Marges',
			'fileSources.font' => 'Police',
			'fileSources.serif' => 'sérior',
			'fileSources.sans' => 'Sans sérifié',
			'fileSources.mono' => 'Monoparent',
			'fileSources.columns' => 'Colonne',
			'fileSources.scroll' => 'Scroll verticalement',
			'fileSources.justify' => 'Justifier le texte',
			'fileSources.readerTheme' => 'Page Apparition',
			'fileSources.appTheme' => 'Suivez le thème de l\'app',
			'fileSources.paper' => 'Papier',
			'fileSources.sepia' => 'Sépique',
			'fileSources.night' => 'nuit',
			'fileSources.readAloud' => 'Lire cette page à voix haute',
			'fileSources.readAlong' => 'Lire en continu',
			'fileSources.stopReading' => 'Arrêter la narration',
			'fileSources.searchBook' => 'Recherche dans le livre',
			'fileSources.noMatches' => 'Pas de match',
			'fileSources.previousPage' => 'Page précédente',
			'fileSources.nextPage' => 'Page suivante',
			'fileSources.page' => ({required Object number}) => 'Page ${number}',
			'fileSources.externalBlocked' => 'Les liens de livre extérieurs sont désactivés dans le lecteur.',
			'fileSources.loading' => 'ouverture...',
			'fileSources.narrator' => 'narrateur',
			'fileSources.audio' => 'Audio',
			'fileSources.video' => 'Vidéo',
			'fileSources.ebooks' => 'Livres numériques',
			'fileSources.all' => 'Tout',
			'fileSources.downloads' => 'Fichiers hors ligne',
			'fileSources.confirmDelete' => 'Supprimer la copie hors ligne sélectionnée ? votre position et vos notes restent.',
			'fileSources.errorAuthentication' => 'Signature pour revenir sur cette source.',
			'fileSources.errorPermission' => 'Cette source n’a pas donné accès au fichier demandé.',
			'fileSources.errorUnavailable' => 'La source n\'est pas disponible. essayez de nouveau, ou ouvrir une copie hors ligne.',
			'fileSources.errorUnsupported' => 'Ce format ou la connexion n\'est pas supporté sur ce appareil.Voir le guide de configuration source.',
			'fileSources.errorInvalidData' => 'Ce fichier ou réponse serveur ne pouvait pas être lu en toute sécurité.',
			'fileSources.errorCancelled' => 'L’opération a été annulée.',
			'fileSources.errorConflict' => 'La position a changé dans une autre session. réouverture de l\'élément pour choisir une position.',
			'fileSources.signIn' => 'Se connecter',
			'fileSources.reconnect' => 'Se reconnecter',
			'fileSources.folderHelp' => 'Laissez blanche pour commencer à la racine source. les URL S3 incluent le bucket.',
			'fileSources.preferences' => 'Préférences',
			'fileSources.timePosition' => 'Position',
			'fileSources.audioTrack' => 'Track audio',
			'fileSources.subtitleTrack' => 'Trail de sous-titre',
			'fileSources.none' => 'Nulle',
			'fileSources.fullscreen' => 'écran complet',
			'fileSources.syncLocation' => 'Fiche de synchronisation progressive (optionnelle)',
			'fileSources.syncLocationHint' => 'Une dossier dédiée à WebDAV pour PlezyNG état. Utilisez les écrits conditionnels; les médias restent inchangés.',
			'fileSources.audiobooks' => 'Les audiobooks',
			'fileSources.comics' => 'Bandes dessinées',
			'fileSources.scan' => 'Scanner pour les livres et les médias',
			'fileSources.browserReader' => 'Le lecteur ouvert',
			'fileSources.browserReaderHelp' => 'Le lecteur est ouvert dans votre navigateur. Gardez le PlezyNG ouvert pour sauver votre place et vos notes.',
			'fileSources.on' => 'sur',
			'fileSources.advancedSetup' => 'App enregistration',
			'fileSources.microsoftSignIn' => 'Inscrivez-vous avec Microsoft',
			'fileSources.zoomIn' => 'Zoom dans',
			'fileSources.zoomOut' => 'Zoom à l\'extérieur',
			'fileSources.fitPage' => 'Page de faveur',
			'fileSources.fitWidth' => 'Adapter la largeur',
			'fileSources.actualSize' => 'La taille actuelle',
			'fileSources.goToPage' => 'Aller à page',
			'fileSources.goToSection' => 'Aller au chapitre',
			'fileSources.pageRange' => ({required Object count}) => 'Entrez un numéro de 1 à ${count}',
			'fileSources.pageLayout' => 'Page de layout',
			'fileSources.automatic' => 'Automatique',
			'fileSources.singlePage' => 'Une page unique',
			'fileSources.twoPages' => '2 pages',
			'fileSources.readingDirection' => 'La direction de la lecture',
			'fileSources.leftToRight' => 'à gauche à droite',
			'fileSources.rightToLeft' => 'De droite à gauche',
			'fileSources.letterSpacing' => 'Lettre spatiale',
			'fileSources.wordSpacing' => 'Paroles spatiales',
			'fileSources.readerControlsHelp' => 'Écartez deux doigts ou utilisez les commandes de zoom pour agrandir les pages. Faites glisser pour déplacer la page. Ctrl/⌘ avec + ou − règle le zoom ; Ctrl/⌘ avec 0 le réinitialise. Page Up et Page Down changent de page.',
			'fileSources.imagePage' => 'Page de bande dessinée',
			'fileSources.resetReader' => 'Réserver les préférences de lecture',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Utiliser des fichiers et des livres',
			'fileSources.cancelScan' => 'Annuler le scan',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Limitation de téléchargement offline',
			'fileSources.offlineQuotaHelp' => 'Définissez l\'espace maximum utilisé par les copies hors ligne, les fichiers importés et les téléchargements courts. La réduction de la limite ne supprime pas les exemplaires existants.',
			'fileSources.offlineStorageUsage' => 'stockage hors ligne',
			'fileSources.reservedStorage' => 'Réservez',
			'fileSources.downloadQueue' => 'Télécharger Queue',
			'fileSources.downloadRunning' => 'Téléchargement',
			'fileSources.downloadQueued' => 'Attendre',
			'fileSources.downloadPaused' => 'Pause',
			'fileSources.downloadFailed' => 'besoin de retraite',
			'fileSources.importing' => 'importation',
			'fileSources.importInterrupted' => 'Importation interrompue · supprimer à clarifier',
			'fileSources.errorQuotaExceeded' => 'La limite de stockage hors ligne a été atteinte. Augmentez la limite ou supprimez une copie téléchargée.',
			'fileSources.errorStorageLow' => 'Il n\'y a pas assez de stockage gratuit pour conserver la réserve protégée.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG ne pouvait pas vérifier le stockage de dispositif gratuit, donc l\'écriture a été arrêtée.',
			'fileSources.removeDownloadJob' => 'Supprimer le download',
			'fileSources.downloadAlreadyComplete' => 'Ce téléchargement est terminé avant qu\'il ne puisse être supprimé. l\'article est désormais disponible hors ligne.',
			'fileSources.confirmRemoveDownloadJob' => 'Supprimer ce téléchargement et supprimer tous les données partiellement téléchargeées ? votre position et vos notes resteront.',
			'lending.title' => 'Bibliothèques publiques',
			'lending.add' => 'Ajoutez une bibliothèque',
			'lending.other' => 'Une autre bibliothèque',
			'lending.libraryName' => 'Nom de la bibliothèque',
			'lending.libraryUrl' => 'Site de la bibliothèque',
			'lending.libraryUrlHint' => 'Utilisez le catalogue de votre bibliothèque ou la page de signature.',
			'lending.intro' => 'Prendre un prêt à la bibliothèque, garder vos livres fermés.',
			'lending.handoff' => 'Inscrivez-vous, prêtez et lisez en toute sécurité avec le service de votre bibliothèque.',
			'lending.openService' => 'Bibliothèque ouverte',
			'lending.findLibrary' => 'Trouvez une bibliothèque',
			'lending.search' => 'Rechercher des livres et des auteurs',
			'lending.catalogue' => 'Catalogue',
			'lending.loans' => 'Les prêts',
			'lending.holds' => 'Réservations',
			'lending.signIn' => 'Inscrivez-vous avec votre bibliothèque',
			'lending.waiting' => 'Réservez votre abonnement dans votre navigateur, puis revenez ici.',
			'lending.cancel' => 'Annuler',
			'lending.disconnect' => 'Récupérer la bibliothèque',
			'lending.disconnectMessage' => 'Retirer cette bibliothèque de ce profil ? Vos emprunts et réservations resteront enregistrés auprès de la bibliothèque.',
			'lending.getBook' => 'Obtenez le livre',
			'lending.checkAvailability' => 'Vérifier la disponibilité',
			'lending.available' => 'Disponible pour emprunter',
			'lending.unavailable' => 'Actuellement inaccessible',
			'lending.borrow' => 'Emprunter',
			'lending.placeHold' => 'Réserver',
			'lending.returnBook' => 'Retour précoce',
			'lending.cancelHold' => 'Annuler la réservation',
			'lending.confirmBorrow' => 'Vous prêtez ce titre de votre bibliothèque ?',
			'lending.confirmReturn' => 'Rendre ce titre maintenant ? Vous devrez peut-être l’emprunter de nouveau pour continuer.',
			'lending.confirmCancelHold' => 'Annuler votre réservation de ce titre ?',
			'lending.email' => 'Restez en e-mail de notification',
			'lending.due' => ({required Object date}) => 'Leur résultat : ${date}',
			'lending.queue' => ({required Object position}) => 'Position ${position} en ligne',
			'lending.empty' => 'Pas de titres ici encore.',
			'lending.openLibraryNote' => 'Explorez le catalogue de la Bibliothèque ouverte.Les options de lecture et de prêt sont affichées sur la page de chaque titre.',
			'lending.more' => 'Charger plus',
			'lending.gateway' => 'Bibliothèque de service',
			'lending.gatewayHint' => 'Fourni par votre bibliothèque ou par l\'administrateur PlezyNG.',
			'lending.advanced' => 'Intégration bibliothèque',
			'lending.loadLibraries' => 'Choisissez votre bibliothèque',
			'lending.expired' => 'Ce prêt est expiré.',
			'lending.updated' => 'Bibliothèque mise à jour',
			'lending.continueService' => 'Continuez à service',
			'lending.comingSoon' => 'Prêt en app · Bientôt',
			'lending.comingSoonDescription' => 'Vous pouvez utiliser votre bibliothèque dans Libby alors que nous finissons par le connecter.',
			'lending.suspendHold' => 'Suspension de la main',
			'lending.resumeHold' => 'Résumé Hold',
			'lending.suspendMessage' => 'Garder votre place dans la file d’attente et laisser le lecteur suivant emprunter cet exemplaire ? Vous pourrez reprendre la réservation plus tard.',
			'lending.resumeMessage' => 'Reprendre cette réservation pour que la bibliothèque puisse vous proposer le prochain exemplaire disponible ?',
			'lending.editEmail' => 'Changer la notification par email',
			'audiobook.syncTitle' => 'Lire et écouter Sync',
			'audiobook.syncHelp' => 'Gardez les positions de lecture, les positions d\'écoute, l\'état de finition, les notes et les notes sur vos appareils. Choisissez un compte de stockage attaché et utilisez le même code de synchronisation sur chaque appareil. La lecture et l\'écoute restent séparées.',
			'audiobook.addSyncSource' => 'Ajouter Google Drive, OneDrive, Dropbox, WebDAV ou S3 dans les fichiers et les livres d’abord.',
			'audiobook.syncDestination' => 'Sync compte de stockage',
			'audiobook.syncFolder' => 'Synchronisation des fichiers ou préfix',
			'audiobook.syncFolderHelp' => 'Utilisez un dossier existant séparé dans votre source WebDAV, ou un préfix S3 dédié.',
			'audiobook.syncCode' => 'Code de sync privé',
			'audiobook.syncCodeHelp' => 'Créez un code sur votre premier appareil, puis entrez ce code sur vos autres appareils. Gardez une copie privée: c\'est la clé de votre état chiffré. Utilisez un code différent pour chaque personne.',
			'audiobook.showCode' => 'Afficher ou cacher le code sync',
			'audiobook.newSyncCode' => 'Créer un nouveau code synchronisé',
			'audiobook.saveSync' => 'Réserver et synchroniser',
			'audiobook.disableSync' => 'Déconnecter la synchronisation sur ce dispositif',
			'audiobook.syncSourceDisconnect' => 'En supprimant cette source, la lecture et l\'écoute de synchronisation sont désactivées ici. les fichiers de synchronisation cryptés restent dans le fournisseur.',
			'audiobook.syncReconnect' => 'Récupérer le compte de stockage',
			'audiobook.lastSynced' => ({required Object time}) => 'Dernière synchronisation à ${time}',
			'audiobook.syncPrivacy' => 'Seuls les progrès et les notes cryptés sont enregistrés. Les fichiers audio et ebook, les tokens de compte et les mots de passe ne sont pas téléchargés. Google Drive et OneDrive utilisent le stockage d\'applications; Dropbox utilise PlezyNG Sync. Autoriser la synchronisation peut demander un accès écrite supplémentaire. Pendant que la synchronisation est activée, cette destination possède la synchronisation du progrès; le progrès du serveur reste séparé.',
			'audiobook.syncConflicts' => 'Choisissez où revenir',
			'audiobook.conflictHelp' => 'Ces modifications ont été effectuées indépendamment. Choisissez la position ou la version de la note pour garder. Un timestamp ultérieur ou un pourcentage plus élevé ne gagne pas automatiquement.',
			'audiobook.syncDevice' => ({required Object device}) => 'Équipement ${device}',
			'audiobook.syncUnknownDevice' => 'Un appareil inconnu',
			'audiobook.deletedBookmark' => 'Bookmark supprimé',
			'audiobook.finished' => 'terminé',
			'audiobook.readingPosition' => ({required Object percent}) => 'Lire · ${percent}%',
			'audiobook.chapterTimeline' => 'Chapitre Progrès',
			'audiobook.bookTimeline' => 'L\'ensemble du livre progrès',
			'audiobook.bookRemaining' => ({required Object time}) => 'Le temps restant dans ce livre: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Le temps restant dans ce chapitre: ${time}',
			'audiobook.unknownRemaining' => 'Temps total disponible lorsque les parties sont jouées',
			'audiobook.undoSeek' => 'La dernière recherche',
			'audiobook.customSpeed' => 'La vitesse de jeu personnalisée',
			'audiobook.speedHelp' => 'Choisissez une vitesse de 0,25× à 4×.',
			'audiobook.apply' => 'Appliquer',
			'audiobook.customSleep' => 'Temps de sommeil personnalisé',
			'audiobook.sleepMinutes' => 'Démonstrations (1 à 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Arrêt après ${count} chapitres',
			'audiobook.extendSleep' => 'Ajoutez 5 minutes',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Temps de sommeil : ${time}',
			'audiobook.useDefaults' => 'Utilisez ces contrôles d\'écoute pour de nouveaux livres',
			'audiobook.librarySort' => 'Les livres sortants',
			'audiobook.sortTitle' => 'Titre',
			'audiobook.sortAuthor' => 'Auteur',
			'audiobook.sortNarrator' => 'Narrateur',
			'audiobook.sortSeries' => 'Commande série',
			'audiobook.sortRecent' => 'récemment ouvert',
			'audiobook.statusFilter' => 'Le statut de lecture',
			'audiobook.statusAll' => 'Tous les livres',
			'audiobook.statusNew' => 'Pas commencé',
			'audiobook.statusProgress' => 'Au progrès',
			'audiobook.statusFinished' => 'terminé',
			'audiobook.goToTime' => 'Aller dans le temps',
			'audiobook.timeHelp' => 'Hores : minutes : secondes ou minutes : secondes',
			'audiobook.recoveryHelp' => 'Exporter une récente copie cryptée avant de déplacer ou de réparer les données synchronisées. Les importations se fusionnent avec l\'état actuel; elles ne remplacent jamais l\'historique locale de la syncation.',
			'audiobook.recoveryExport' => 'Export de fichiers de récupération cryptés',
			'audiobook.recoveryImport' => 'Importer des fichiers de récupération cryptés',
			'audiobook.recoveryImportConfirm' => 'Mélanger ce fichier de récupération crypté avec les positions et notes de lecture actuelles? l\'historique existante sera conservée. la bibliothèque partagée et les identifiants d\'objets ne sont pas inclus; définir des identifiers correspondant sur chaque appareil avant d\'importer.',
			'audiobook.recoveryExported' => 'Les fichiers de récupération cryptés sont sauvegardés.',
			'audiobook.recoveryImported' => 'Les données de récupération sont fusionnées.',
			'sourceSetup.savedCertificate' => 'Certificat du serveur enregistré',
			'sourceSetup.nfsEndpointInvalid' => 'Saisissez une URL NFS, par exemple nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Aucun serveur DLNA trouvé. Saisissez manuellement l’URL de description de l’appareil.',
			'sourceSetup.dlnaServers' => 'Serveurs multimédias DLNA',
			'sourceSetup.dlnaUnavailable' => 'La découverte DLNA est indisponible sur ce réseau. Saisissez manuellement l’URL de description de l’appareil.',
			'sourceSetup.dlnaSearching' => 'Recherche de serveurs DLNA sur le réseau local',
			'sourceSetup.networkSearching' => 'Recherche sur le réseau local…',
			'sourceSetup.dlnaDiscover' => 'Découvrir les serveurs DLNA',
			'sourceSetup.dlnaHelp' => 'La découverte repose sur la multidiffusion du réseau local. Si aucun serveur n’apparaît, saisissez ci-dessus son URL de description de l’appareil.',
			'sourceSetup.dlnaRoot' => 'Identifiant d’objet DLNA ; laissez vide pour utiliser la racine de l’appareil.',
			'sourceSetup.passwordOrKey' => 'Saisissez un mot de passe ou ajoutez une clé privée ci-dessous.',
			'sourceSetup.sshFingerprint' => 'Empreinte SHA256 de la clé d’hôte SSH',
			'sourceSetup.sshFingerprintHelp' => 'Vérifiez-la auprès de l’administrateur du serveur. Sur le serveur, exécutez ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub et utilisez sa valeur SHA256.',
			'sourceSetup.sshFingerprintKeep' => 'Laissez vide pour conserver l’empreinte actuellement épinglée, ou saisissez une nouvelle empreinte du serveur.',
			'sourceSetup.sshAuthentication' => 'Authentification SSH par clé publique',
			'sourceSetup.sshAuthenticationHelp' => 'Facultative ; l’authentification par mot de passe est également prise en charge.',
			'sourceSetup.privateKey' => 'Clé privée (format PEM ou OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Phrase secrète de la clé privée',
			'sourceSetup.nfsMountPort' => 'Port TCP du service de montage NFS',
			'sourceSetup.nfsMountPortHelp' => 'Par défaut : 20048',
			'sourceSetup.nfsUserId' => 'Identifiant utilisateur NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Par défaut : 1000. Utilisez l’identifiant autorisé par le partage NFS du NAS.',
			'sourceSetup.nfsGroupId' => 'Identifiant de groupe NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Par défaut : 1000. Utilisez l’identifiant de groupe autorisé par le partage NFS du NAS.',
			'sourceSetup.nfsEncryption' => 'Exiger NFS chiffré (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Exiger TLS 1.3 pour NFS et le service de montage. Si le NAS ne le prend pas en charge, la connexion est refusée.',
			'sourceSetup.nfsTrustCertificate' => 'CA NFS personnalisée ou certificat du serveur (PEM, facultatif)',
			'sourceSetup.nfsTrustHelp' => 'Laissez vide pour utiliser les certificats reconnus par cet appareil. Si nécessaire, ajoutez un certificat d’une CA privée ou un certificat de serveur autosigné ; ses noms doivent correspondre à l’hôte de l’URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Utilisez un certificat de CA ou de serveur au format PEM. N’incluez pas de clé privée.',
			'sourceSetup.addTrustCertificate' => 'Ajouter un certificat de confiance personnalisé',
			'sourceSetup.replaceTrustCertificate' => 'Remplacer le certificat personnalisé enregistré',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS utilise les ports habituels de NFS et du service de montage et exige la prise en charge de RFC 9289 par le NAS. TLS 1.3 est obligatoire. Le nom d’hôte ou l’adresse IP doit correspondre au certificat. Les UID/GID AUTH_SYS s’appliquent toujours dans le canal chiffré.',
			'sourceSetup.clientCertificate' => 'Certificat client (facultatif)',
			'sourceSetup.clientCertificateHelp' => 'Permet au NAS d’authentifier ce client ; les identifiants AUTH_SYS dépendent toujours des règles du partage NFS du NAS.',
			'sourceSetup.savedIdentity' => 'Une identité client enregistrée sera utilisée.',
			'sourceSetup.replaceIdentity' => 'Remplacer l’identité client enregistrée',
			'sourceSetup.chooseIdentity' => 'Choisir une identité client PKCS#12',
			'sourceSetup.identityPassphrase' => 'Phrase secrète de l’identité client',
			'sourceSetup.identityPassphraseHelp' => 'Laissez vide si le fichier n’a pas de phrase secrète.',
			'sourceSetup.removeIdentity' => 'Supprimer toute identité client enregistrée',
			'sourceSetup.identityStorageHelp' => 'Les identités client sont enregistrées dans le coffre chiffré des identifiants de la source. Ne modifiez pas cette section pour conserver l’identité enregistrée.',
			'sourceSetup.nfsLimitations' => 'NFSv3 en lecture seule sur TCP. Sans RPC-with-TLS, le trafic NFS n’est pas chiffré. Le NAS doit autoriser les identifiants AUTH_SYS choisis et les ports client non privilégiés (souvent via l’option d’export « insecure »). NFSv4 et UDP ne sont pas pris en charge.',
			'sourceSetup.nfsSetupHelp' => 'Aide à la configuration NFS',
			'sourceSetup.nfsSetupHint' => 'Vérifiez ces réglages si la connexion ne s’établit pas.',
			'sourceSetup.nfsSetupDetails' => 'Utilisez un partage NFSv3 sur TCP. Si le chiffrement est exigé, le service NFS et le service de montage doivent tous deux prendre en charge RPC-with-TLS. Laissez le certificat personnalisé vide pour utiliser un certificat de serveur reconnu par cet appareil, ou ajoutez le certificat de CA ou autosigné du NAS. Le nom du certificat doit correspondre à l’hôte du point de connexion. Si le NAS exige TLS mutuel, ajoutez son identité client PKCS#12. Vérifiez enfin que le partage autorise les UID/GID AUTH_SYS configurés et les règles de ports du client.',
			'sourceSetup.ftpHelp' => 'FTP utilise le mode passif. Utilisez ftp:// pour FTP sans chiffrement, ftpes:// pour TLS explicite, ou ftps:// pour TLS (implicite sur le port 990 ; explicite sur les autres ports).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Recherche facultative de sous-titres pour les vidéos indépendantes.',
			'sourceSetup.apiKey' => 'Clé API',
			'sourceSetup.optionalUsername' => 'Nom d’utilisateur du compte (facultatif)',
			'sourceSetup.optionalPassword' => 'Mot de passe du compte (facultatif)',
			'sourceSetup.subtitlePrivacy' => 'Obtenez une clé API sur opensubtitles.com. La recherche envoie le titre de la vidéo et les identifiants IMDb/TMDB disponibles, jamais le fichier vidéo. La clé et les identifiants facultatifs du compte sont chiffrés avec cette source.',
			'sourceSetup.automaticMetadata' => 'Métadonnées vidéo automatiques en ligne',
			'sourceSetup.metadataPrivacy' => 'Envoie uniquement le titre/l’année du nom de fichier et les numéros d’épisode, ou un identifiant NFO ; jamais les médias ni les identifiants de connexion. Les champs NFO restent prioritaires.',
			'sourceSetup.nfsEncryptionFailure' => 'Pour NFS chiffré, vérifiez la prise en charge de RFC 9289 et TLS 1.3 par les deux services du NAS, le nom du certificat et les UID/GID du partage. PlezyNG ne réessaiera pas cette connexion sans chiffrement.',
			'sourceSetup.sourceConnecting' => 'Connexion à la source',
			'sourceSetup.metadataSearchPrivacy' => 'Cette recherche de titre est envoyée à Trakt. Seul le titre saisi est transmis, pas la vidéo ni les identifiants de connexion de la source.',
			'sourceSetup.chooseMatch' => 'Choisir une correspondance',
			'sourceSetup.metadataMatchHelp' => 'Vérifiez le titre et l’année avant de choisir. Trakt reçoit le titre recherché ; la vidéo reste sur sa source.',
			'sourceSetup.metadataNoMatches' => 'Aucun titre correspondant trouvé en ligne. Essayez un autre titre.',
			'sourceSetup.metadataSearch' => 'Rechercher des métadonnées en ligne',
			'sourceSetup.metadataLoading' => 'Recherche en ligne d’informations sur les films et séries…',
			'sourceSetup.metadataFromTrakt' => 'Métadonnées en ligne de Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Aucune correspondance automatique trouvée pour le titre. Recherchez le titre pour choisir une correspondance.',
			'sourceSetup.metadataFailed' => 'Impossible de charger les métadonnées en ligne. La lecture et les informations locales restent disponibles.',
			'sourceSetup.videoDetailsLoading' => 'Chargement des détails de la vidéo',
			'sourceSetup.subtitleKeyRequired' => 'Clé API OpenSubtitles requise',
			'sourceSetup.subtitleKeyHelp' => 'Modifiez cette source de fichiers et ajoutez une clé API OpenSubtitles dans ses réglages facultatifs de sous-titres.',
			'sourceSetup.subtitleSearchFailed' => 'La recherche de sous-titres a échoué. Vérifiez la clé API, la connexion et l’accès au service.',
			'sourceSetup.subtitleApplyFailed' => 'Impossible de télécharger ou d’appliquer ces sous-titres. Vérifiez votre connexion et essayez un autre résultat.',
			'sourceSetup.subtitleSearch' => 'Rechercher sur OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'La recherche utilise le titre et les identifiants IMDb/TMDB disponibles. Le fichier vidéo reste sur sa source. Avant de choisir, vérifiez la langue, les indicateurs de sous-titres forcés ou pour sourds et malentendants, ainsi que la note.',
			'sourceSetup.movieOrShow' => 'Film ou série',
			'sourceSetup.subtitleTitleHint' => 'Saisissez un titre pour affiner les résultats',
			'sourceSetup.subtitleLanguage' => 'Langue des sous-titres',
			'sourceSetup.subtitleSearching' => 'Recherche sur OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Aucun sous-titre correspondant trouvé. Essayez un autre titre ou une autre langue.',
			'sourceSetup.downloadSubtitle' => 'Télécharger les sous-titres',
			'sourceSetup.subtitle' => 'Sous-titres',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS obligatoire',
			'sourceSetup.nfsUnencrypted' => 'NFS non chiffré',
			'sourceSetup.tlsEncrypted' => 'Chiffré avec TLS',
			'sourceSetup.ftpPlain' => 'FTP non chiffré',
			'sourceSetup.sshPinned' => 'SSH chiffré · clé d’hôte épinglée',
			'sourceSetup.smbEncrypted' => 'Chiffrement SMB3 activé',
			'sourceSetup.smbUnencrypted' => 'Chiffrement SMB3 désactivé',
			'sourceSetup.httpUnencrypted' => 'HTTP sans chiffrement du transport',
			'sourceSetup.checkEndpointSecurity' => 'Vérifier la sécurité du point de connexion',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} est obligatoire.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Saisissez ${label} entre ${min} et ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Remplacer ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Identité client sélectionnée : ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Note ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Téléchargement des sous-titres : ${title}',
			'sourceSetup.sharedEntryPair' => 'Couvrir cet élément',
			'sourceSetup.sharedEntryPairHelp' => 'Entrez le même ID pour cet élément sur chaque appareil. Utilisez un identifiant partagé stable ou générez un et copiez-le à l\'élément correspondant. Progress paires seulement lorsque les types de fichier édition, les tailles et la commande correspondent. Blank supprime cette cartographie.',
			'sourceSetup.sharedEntryId' => 'Étiquette partagée ID',
			'sourceSetup.generateSharedEntryId' => 'Gérer un élément partagé ID',
			'sourceSetup.sharedLibraryId' => 'ID de la bibliothèque partagée (optionnelle)',
			'sourceSetup.sharedLibraryHelp' => 'Utilisez le même ID sur les appareils qui ouvrent la même bibliothèque.Cette identifiant public aide à suivre les progrès de lecture et les notes dans différentes connexions source; il n\'est pas un mot de passe.Quand les fournisseurs utilisent différents identifiants d\'objets, couvrir ces éléments de leurs écrans détaillés.',
			'sourceSetup.sharedLibraryInvalid' => 'Utilisez 8 à 100 lettres, chiffres, points, sous-cores ou hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Gérer un ID de bibliothèque partagé',
			'sourceSetup.nfsReadAhead' => 'Les demandes de NFS read-ahead',
			'sourceSetup.nfsReadAheadHelp' => 'Plus de lectures parallèles peuvent améliorer la puissance sur un NAS ou réseau rapide. Utilisez 1 si le serveur limite les demandes concurrentes.',
			'sourceSetup.nfsReadTest' => 'Mesure des performances NFS',
			'sourceSetup.nfsReadTestHelp' => 'Il lit jusqu\'à 64 MiB du plus grand fichier pour mesurer cette connexion NAS. Ceci utilise la bande passante réseau.',
			'sourceSetup.nfsQualificationResult' => 'NFS Lire la mesure',
			'sourceSetup.nfsReadBytes' => 'Les données lisées',
			'sourceSetup.nfsReadSpeed' => 'vitesse mesurée',
			'sourceSetup.nfsReadRequests' => 'Lire les demandes',
			'sourceSetup.sharedEntryConflict' => 'Cet identifiant d\'élément partagé est déjà associé à un autre élément dans cette bibliothèque.',
			'comics.fitHeight' => 'Ajuster à la hauteur',
			'comics.readingMode' => 'Mode de lecture',
			'comics.paged' => 'Pages',
			'comics.webtoon' => 'Défilement continu',
			'comics.coverAlone' => 'Afficher la couverture seule',
			'comics.splitWide' => 'Diviser les pages larges',
			'comics.splitWideHelp' => 'Affiche chaque moitié séparément, dans l’ordre de lecture. L’affichage de deux pages côte à côte est suspendu lorsque cette option est activée.',
			'comics.thumbnails' => 'Miniatures des pages',
			'comics.controlsHelp' => 'Balayez pour tourner les pages. Touchez deux fois pour modifier l’ajustement. En défilement continu, balayez verticalement ou utilisez Page précédente et Page suivante.',
			'comics.savedForComic' => 'Les réglages d’affichage sont mémorisés pour cette BD dans ce profil.',
			'comics.readLists' => 'Listes de lecture',
			'comics.collections' => 'Collections',
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
			_ => null,
		} ?? switch (path) {
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
			'deepLinks.invalid' => 'Ce lien Plezy n’est pas valide.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Aucun profil ne correspond à "${profile}".',
			'deepLinks.serverUnavailable' => 'Je n\'arrive pas au serveur pour ce lien.',
			'deepLinks.notFound' => 'Je ne pourrais pas trouver ce titre dans vos bibliothèques.',
			'deepLinks.unsupportedItem' => 'Ce lien ne peut pas être joué.',
			'deepLinks.noLiveTv' => 'Aucun serveur TV en direct n\'est disponible pour ce lien.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Je ne pouvais pas trouver le canal "${channel}".',
			'deepLinks.showLink' => 'Afficher le lien',
			'deepLinks.showProfileLink' => 'Afficher le profil',
			'deepLinks.dialogTitle' => 'Le lien',
			'deepLinks.showHint' => 'L’ouverture de ce lien lance l’épisode suivant. Ajoutez &mode=shuffle à la fin pour lire la série en mode aléatoire.',
			'deepLinks.movieHint' => 'Ouvrir ce lien joue le film.',
			'deepLinks.episodeHint' => 'Ouvrir ce lien joue cet épisode.',
			'deepLinks.profileHint' => 'L’ouverture de ce lien change vers ce profil.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Ouverture en ${name}',
			'deepLinks.copy' => 'Copie',
			'deepLinks.copied' => 'Le lien copié',
			_ => null,
		};
	}
}
