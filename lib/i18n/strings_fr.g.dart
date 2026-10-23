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
	@override late final _Translations$app$fr app = _Translations$app$fr._(_root);
	@override late final _Translations$appIcon$fr appIcon = _Translations$appIcon$fr._(_root);
	@override late final _Translations$auth$fr auth = _Translations$auth$fr._(_root);
	@override late final _Translations$common$fr common = _Translations$common$fr._(_root);
	@override late final _Translations$screens$fr screens = _Translations$screens$fr._(_root);
	@override late final _Translations$update$fr update = _Translations$update$fr._(_root);
	@override late final _Translations$supporter$fr supporter = _Translations$supporter$fr._(_root);
	@override late final _Translations$settings$fr settings = _Translations$settings$fr._(_root);
	@override late final _Translations$themeEditor$fr themeEditor = _Translations$themeEditor$fr._(_root);
	@override late final _Translations$search$fr search = _Translations$search$fr._(_root);
	@override late final _Translations$hotkeys$fr hotkeys = _Translations$hotkeys$fr._(_root);
	@override late final _Translations$fileInfo$fr fileInfo = _Translations$fileInfo$fr._(_root);
	@override late final _Translations$mediaMenu$fr mediaMenu = _Translations$mediaMenu$fr._(_root);
	@override late final _Translations$rateSheet$fr rateSheet = _Translations$rateSheet$fr._(_root);
	@override late final _Translations$accessibility$fr accessibility = _Translations$accessibility$fr._(_root);
	@override late final _Translations$tooltips$fr tooltips = _Translations$tooltips$fr._(_root);
	@override late final _Translations$audioTracks$fr audioTracks = _Translations$audioTracks$fr._(_root);
	@override late final _Translations$videoControls$fr videoControls = _Translations$videoControls$fr._(_root);
	@override late final _Translations$messages$fr messages = _Translations$messages$fr._(_root);
	@override late final _Translations$subtitlingStyling$fr subtitlingStyling = _Translations$subtitlingStyling$fr._(_root);
	@override late final _Translations$mpvConfig$fr mpvConfig = _Translations$mpvConfig$fr._(_root);
	@override late final _Translations$dialog$fr dialog = _Translations$dialog$fr._(_root);
	@override late final _Translations$profiles$fr profiles = _Translations$profiles$fr._(_root);
	@override late final _Translations$connections$fr connections = _Translations$connections$fr._(_root);
	@override late final _Translations$accountPreferences$fr accountPreferences = _Translations$accountPreferences$fr._(_root);
	@override late final _Translations$discover$fr discover = _Translations$discover$fr._(_root);
	@override late final _Translations$errors$fr errors = _Translations$errors$fr._(_root);
	@override late final _Translations$libraries$fr libraries = _Translations$libraries$fr._(_root);
	@override late final _Translations$about$fr about = _Translations$about$fr._(_root);
	@override late final _Translations$serverSelection$fr serverSelection = _Translations$serverSelection$fr._(_root);
	@override late final _Translations$hubDetail$fr hubDetail = _Translations$hubDetail$fr._(_root);
	@override late final _Translations$logs$fr logs = _Translations$logs$fr._(_root);
	@override late final _Translations$startup$fr startup = _Translations$startup$fr._(_root);
	@override late final _Translations$licenses$fr licenses = _Translations$licenses$fr._(_root);
	@override late final _Translations$navigation$fr navigation = _Translations$navigation$fr._(_root);
	@override late final _Translations$explore$fr explore = _Translations$explore$fr._(_root);
	@override late final _Translations$liveTv$fr liveTv = _Translations$liveTv$fr._(_root);
	@override late final _Translations$collections$fr collections = _Translations$collections$fr._(_root);
	@override late final _Translations$playlists$fr playlists = _Translations$playlists$fr._(_root);
	@override late final _Translations$music$fr music = _Translations$music$fr._(_root);
	@override late final _Translations$watchTogether$fr watchTogether = _Translations$watchTogether$fr._(_root);
	@override late final _Translations$downloads$fr downloads = _Translations$downloads$fr._(_root);
	@override late final _Translations$shaders$fr shaders = _Translations$shaders$fr._(_root);
	@override late final _Translations$companionRemote$fr companionRemote = _Translations$companionRemote$fr._(_root);
	@override late final _Translations$videoSettings$fr videoSettings = _Translations$videoSettings$fr._(_root);
	@override late final _Translations$performanceOverlay$fr performanceOverlay = _Translations$performanceOverlay$fr._(_root);
	@override late final _Translations$externalPlayer$fr externalPlayer = _Translations$externalPlayer$fr._(_root);
	@override late final _Translations$metadataEdit$fr metadataEdit = _Translations$metadataEdit$fr._(_root);
	@override late final _Translations$matchScreen$fr matchScreen = _Translations$matchScreen$fr._(_root);
	@override late final _Translations$serverTasks$fr serverTasks = _Translations$serverTasks$fr._(_root);
	@override late final _Translations$trakt$fr trakt = _Translations$trakt$fr._(_root);
	@override late final _Translations$seerr$fr seerr = _Translations$seerr$fr._(_root);
	@override late final _Translations$services$fr services = _Translations$services$fr._(_root);
	@override late final _Translations$addServer$fr addServer = _Translations$addServer$fr._(_root);
}

// Path: app
class _Translations$app$fr extends Translations$app$en {
	_Translations$app$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: appIcon
class _Translations$appIcon$fr extends Translations$appIcon$en {
	_Translations$appIcon$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icône de l’application';
	@override String get defaultIcon => 'Par défaut';
	@override String get current => 'Icône actuelle';
	@override String get locked => 'Avantage Supporter';
	@override String get lockedHint => 'Les icônes alternatives sont un avantage Supporter.';
	@override String get changeFailed => 'Impossible de changer l’icône de l’application';
	@override String get launcherHint => 'La nouvelle icône apparaîtra sur votre écran d’accueil une fois que vous aurez quitté Plezy.';
	@override String get tvLauncherHint => 'La nouvelle bannière apparaîtra une fois que vous aurez quitté Plezy. Android TV peut continuer à afficher l’ancienne jusqu’au redémarrage du téléviseur.';
	@override late final _Translations$appIcon$names$fr names = _Translations$appIcon$names$fr._(_root);
}

// Path: auth
class _Translations$auth$fr extends Translations$auth$en {
	_Translations$auth$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get localDataRecoveryRequired => 'Plezy n’a pas pu récupérer en toute sécurité les données locales de connexion et de lecture en attente. Veuillez vous reconnecter.';
	@override String get pinCheckRejected => 'La vérification du code PIN Plex a été refusée';
}

// Path: common
class _Translations$common$fr extends Translations$common$en {
	_Translations$common$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuler';
	@override String get save => 'Enregistrer';
	@override String get close => 'Fermer';
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
	@override late final _Translations$common$ratingSource$fr ratingSource = _Translations$common$ratingSource$fr._(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$fr mediaKind = _Translations$common$mediaKind$fr._(_root);
}

// Path: screens
class _Translations$screens$fr extends Translations$screens$en {
	_Translations$screens$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licences';
	@override String get switchProfile => 'Changer de profil';
	@override String get subtitleStyling => 'Configuration des sous-titres';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Journaux';
}

// Path: update
class _Translations$update$fr extends Translations$update$en {
	_Translations$update$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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

// Path: supporter
class _Translations$supporter$fr extends Translations$supporter$en {
	_Translations$supporter$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy Supporter';
	@override String get intro => 'Un achat unique qui soutient le développement de Plezy et débloque des bonus esthétiques :';
	@override String get presetThemes => 'Thèmes prédéfinis';
	@override String get presetThemesDescription => 'Braise, Glacier, Forêt, Prune et Papier';
	@override String get customTheme => 'Thème personnalisé';
	@override String get customThemeDescription => 'Choisissez vous-même chaque couleur';
	@override String get appIcons => 'Icônes de l’application';
	@override String get appIconsDescription => 'Choisissez une autre icône Plezy';
	@override String buy({required Object price}) => 'Acheter pour ${price}';
	@override String get loadingPrice => 'Chargement du prix...';
	@override String get restore => 'Restaurer les achats';
	@override String get pending => 'Votre achat est en attente de paiement ou d’approbation. Les bonus seront débloqués dès que la boutique l’aura finalisé.';
	@override String get thankYouTitle => 'Merci de soutenir Plezy';
	@override String get thankYouBody => 'Vos bonus Supporter sont débloqués.';
	@override String get tileSubtitle => 'Débloquez des thèmes et des icônes d’application grâce à un achat unique';
	@override String get tileSubtitleThemesOnly => 'Débloquez des thèmes grâce à un achat unique';
	@override String get tileUnlocked => 'Merci pour votre soutien';
	@override late final _Translations$supporter$errors$fr errors = _Translations$supporter$errors$fr._(_root);
}

// Path: settings
class _Translations$settings$fr extends Translations$settings$en {
	_Translations$settings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres';
	@override String get supportDeveloper => 'Soutenir Plezy';
	@override String get supportDeveloperDescription => 'Faites un don via Liberapay pour financer le développement';
	@override String get language => 'Langue';
	@override String get theme => 'Thème';
	@override String get appearance => 'Apparence';
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
	@override String get defaultQualityTitle => 'Qualité par défaut';
	@override String get cellularQualityTitle => 'Qualité par défaut sur les données mobiles';
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
	@override String secondsUnit({required Object seconds}) => '${seconds} secondes';
	@override String get defaultSleepTimer => 'Minuterie de mise en veille par défaut';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutes';
	@override String get rememberTrackSelections => 'Mémoriser les pistes choisies pour chaque série ou film';
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
	@override String get importSettingsInvalidFile => 'Ce fichier n’est pas une exportation valide des paramètres de Plezy';
	@override String get importSettingsNoUser => 'Connectez-vous avant d’importer les paramètres';
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
	@override String get skipMarkerModeOff => 'Désactivé';
	@override String get skipMarkerModeButton => 'Afficher le bouton';
	@override String get skipMarkerModeAuto => 'Automatique';
	@override String get forceSkipMarkerFallback => 'Forcer les marqueurs de secours';
	@override String get forceSkipMarkerFallbackDescription => 'Utiliser les motifs des titres de chapitre même lorsque Plex fournit des marqueurs';
	@override String get autoSkipDelay => 'Délai avant le saut automatique';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Attendre ${seconds} secondes avant le saut automatique';
	@override String get introPattern => 'Motif du marqueur d’introduction';
	@override String get introPatternDescription => 'Expression régulière permettant de reconnaître les marqueurs d’introduction dans les titres de chapitre';
	@override String get creditsPattern => 'Motif du marqueur de générique';
	@override String get creditsPatternDescription => 'Expression régulière permettant de reconnaître les marqueurs de générique dans les titres de chapitre';
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
	@override String get startInFullscreenDescription => 'Ouvrir Plezy en mode plein écran au lancement';
	@override String get exitFullscreenOnPlayerClose => 'Quitter le plein écran à la fermeture du lecteur';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Quitter automatiquement le plein écran lors de la fermeture du lecteur vidéo';
	@override String get autoHidePerformanceOverlay => 'Masquer automatiquement les données de performance';
	@override String get autoHidePerformanceOverlayDescription => 'Masquer progressivement les données de performance avec les commandes de lecture';
	@override String get showNavBarLabels => 'Afficher les libellés de la barre de navigation';
	@override String get showNavBarLabelsDescription => 'Afficher les libellés sous les icônes de la barre de navigation';
	@override String get startupSection => 'Section de démarrage';
	@override String get showExploreTab => 'Afficher l’onglet Explorer';
	@override String get showExploreTabDescription => 'Afficher l’onglet Explorer avec le contenu de Plex Discover et des services de suivi connectés';
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
	@override String get exportDialogTitle => 'Exporter les paramètres de Plezy';
}

// Path: themeEditor
class _Translations$themeEditor$fr extends Translations$themeEditor$en {
	_Translations$themeEditor$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Intégrés';
	@override String get presets => 'Prédéfinis';
	@override String get custom => 'Personnalisé';
	@override String get customEmpty => 'Pas encore créé';
	@override String get editCustom => 'Modifier le thème personnalisé';
	@override String get editCustomDescription => 'Choisissez vous-même chaque couleur';
	@override String get locked => 'Débloquer avec Supporter';
	@override String get savedLocked => 'Enregistré — se débloque avec Supporter';
	@override String get title => 'Thème personnalisé';
	@override String get startFrom => 'Partir d’un thème';
	@override String get startFromDescription => 'Copier toutes les couleurs d’un autre thème';
	@override String get colors => 'Couleurs';
	@override String get preview => 'Aperçu';
	@override late final _Translations$themeEditor$slots$fr slots = _Translations$themeEditor$slots$fr._(_root);
	@override String get opacity => 'Opacité';
	@override String get hexHint => '#RRGGBB ou #AARRGGBB';
	@override String get fromOtherThemes => 'Dans les autres thèmes';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} du thème ${theme}';
	@override late final _Translations$themeEditor$contrast$fr contrast = _Translations$themeEditor$contrast$fr._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair} : ${ratio}:1, sous le seuil recommandé de ${minimum}:1';
	@override String get discardTitle => 'Abandonner les modifications ?';
	@override String get discardMessage => 'Vos modifications de couleurs non enregistrées seront perdues.';
	@override String get discard => 'Abandonner';
	@override String previewCardTitle({required Object number}) => 'Épisode ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} min restantes';
	@override String get previewSwitch => 'Lecture automatique';
	@override String get previewMutedText => 'Voici à quoi ressemble le texte secondaire';
}

// Path: search
class _Translations$search$fr extends Translations$search$en {
	_Translations$search$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Rechercher des films, des séries, de la musique...';
	@override String get tryDifferentTerm => 'Essayez un autre terme de recherche';
	@override String get searchYourMedia => 'Rechercher dans vos médias';
	@override String get enterTitleActorOrKeyword => 'Entrez un titre, un acteur ou un mot-clé';
	@override String get people => 'Personnes';
}

// Path: hotkeys
class _Translations$hotkeys$fr extends Translations$hotkeys$en {
	_Translations$hotkeys$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Définir un raccourci pour ${actionName}';
	@override String get clearShortcut => 'Effacer le raccourci';
	@override String get noShortcutSet => 'Aucun raccourci défini';
	@override String get currentShortcut => 'Raccourci actuel :';
	@override String get pressToRecord => 'Sélectionner pour enregistrer un raccourci';
	@override String get recordingShortcut => 'Appuyez maintenant sur le raccourci';
	@override late final _Translations$hotkeys$actions$fr actions = _Translations$hotkeys$actions$fr._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$fr extends Translations$fileInfo$en {
	_Translations$fileInfo$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$mediaMenu$fr extends Translations$mediaMenu$en {
	_Translations$mediaMenu$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
		one: 'Cela supprime ${n} épisode qu\'elle contient, ainsi que son fichier.',
		other: 'Cela supprime les ${n} épisodes qu\'elle contient, ainsi que leurs fichiers.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Cet élément est stocké sous forme de ${n} fichier, qui sera supprimé.',
		other: 'Cet élément est stocké sur ${n} fichiers, et ils seront tous supprimés.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} autre épisode est stocké dans le même fichier et sera également supprimé :',
		other: '${n} autres épisodes sont stockés dans le même fichier et seront également supprimés :',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy n\'a pas pu vérifier quels fichiers seront supprimés ; il risque donc d\'en supprimer plus que l\'élément nommé ci-dessus. Annulez et réessayez, ou supprimez quand même.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Votre serveur n\'a pas fourni les détails du fichier pour cet élément, Plezy ne peut donc pas vérifier quels fichiers seront supprimés. Il risque d\'en supprimer plus que l\'élément nommé ci-dessus.';
	@override String get mediaDeletedSuccessfully => 'Élément média supprimé avec succès';
	@override String get mediaFailedToDelete => 'Échec de la suppression de l\'élément média';
	@override String get rate => 'Noter';
	@override String get playFromBeginning => 'Lire depuis le début';
	@override String get playVersion => 'Lire la version...';
}

// Path: rateSheet
class _Translations$rateSheet$fr extends Translations$rateSheet$en {
	_Translations$rateSheet$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$accessibility$fr extends Translations$accessibility$en {
	_Translations$accessibility$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
}

// Path: tooltips
class _Translations$tooltips$fr extends Translations$tooltips$en {
	_Translations$tooltips$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Lecture aléatoire';
	@override String get playTrailer => 'Lire la bande-annonce';
	@override String get markAsWatched => 'Marquer comme vu';
	@override String get markAsUnwatched => 'Marquer comme non vu';
}

// Path: audioTracks
class _Translations$audioTracks$fr extends Translations$audioTracks$en {
	_Translations$audioTracks$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Piste audio ${n}';
}

// Path: videoControls
class _Translations$videoControls$fr extends Translations$videoControls$en {
	_Translations$videoControls$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get longPressToUnlock => 'Appui long pour déverrouiller';
	@override String get timelineSlider => 'Barre de progression vidéo';
	@override String get volumeSlider => 'Niveau du volume';
	@override String endsAt({required Object time}) => 'Se termine à ${time}';
	@override String get pipActive => 'Lecture en mode image dans l\'image';
	@override String get pipFailed => 'Échec du démarrage du mode image dans l\'image';
	@override String get screenshotSaved => 'Capture d\'écran enregistrée';
	@override String get screenshotFailed => 'Impossible de prendre une capture d’écran';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent} %';
	@override String volumePercent({required Object percent}) => 'Volume ${percent} %';
	@override late final _Translations$videoControls$pipErrors$fr pipErrors = _Translations$videoControls$pipErrors$fr._(_root);
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
}

// Path: messages
class _Translations$messages$fr extends Translations$messages$en {
	_Translations$messages$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marqué comme vu';
	@override String get markedAsUnwatched => 'Marqué comme non vu';
	@override String get markedAsWatchedOffline => 'Marqué comme vu (se synchronisera lorsque vous serez en ligne)';
	@override String get markedAsUnwatchedOffline => 'Marqué comme non vu (sera synchronisé lorsque vous serez en ligne)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Supprimé automatiquement : ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} téléchargement vu supprimé automatiquement',
		other: '${n} téléchargements vus supprimés automatiquement',
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
class _Translations$subtitlingStyling$fr extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
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
}

// Path: mpvConfig
class _Translations$mpvConfig$fr extends Translations$mpvConfig$en {
	_Translations$mpvConfig$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuration mpv';
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
class _Translations$dialog$fr extends Translations$dialog$en {
	_Translations$dialog$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmer l\'action';
}

// Path: profiles
class _Translations$profiles$fr extends Translations$profiles$en {
	_Translations$profiles$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Ajouter un profil Plezy';
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
}

// Path: connections
class _Translations$connections$fr extends Translations$connections$en {
	_Translations$connections$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String editMediaBrowserIntro({required Object serverName}) => 'Ajoutez ou retirez des URL pour ${serverName}. Plezy utilisera l\'URL joignable avec la latence la plus faible.';
}

// Path: accountPreferences
class _Translations$accountPreferences$fr extends Translations$accountPreferences$en {
	_Translations$accountPreferences$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Préférences du compte';
	@override String hubSubtitleSingle({required Object account}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${count} comptes';
	@override String get pickAccount => 'Chaque compte enregistre ses propres préférences. Choisissez celui à modifier.';
	@override String get storedOnAccount => 'Ces options sont enregistrées sur le compte lui-même : toutes les applications connectées les utilisent, y compris Plezy sur vos autres appareils.';
	@override String get noAccounts => 'Aucun compte à configurer';
	@override String get noAccountsHint => 'Connectez-vous à Plex, ou connectez un serveur Jellyfin ou Emby : les préférences enregistrées sur ce compte apparaîtront ici.';
	@override String get unavailable => 'Impossible de joindre ce compte';
	@override String get loadFailed => 'Impossible de charger ces préférences';
	@override String get noPreference => 'Aucune préférence';
	@override String get notSet => 'Non défini';
	@override late final _Translations$accountPreferences$groups$fr groups = _Translations$accountPreferences$groups$fr._(_root);
	@override String get preferredAudioLanguage => 'Langue audio préférée';
	@override String get autoSelectAudio => 'Choisir l\'audio par langue';
	@override String get autoSelectAudioDescription => 'Désactivé : la piste audio marquée par défaut dans le fichier est conservée.';
	@override String get preferredSubtitleLanguage => 'Langue de sous-titres préférée';
	@override String get subtitleMode => 'Activer les sous-titres';
	@override late final _Translations$accountPreferences$subtitleModes$fr subtitleModes = _Translations$accountPreferences$subtitleModes$fr._(_root);
	@override String get subtitleAccessibility => 'Sous-titres SDH';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$fr subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$fr._(_root);
	@override String get forcedSubtitles => 'Sous-titres forcés';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$fr forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$fr._(_root);
	@override String get displayMissingEpisodes => 'Afficher les épisodes manquants';
	@override String get displayMissingEpisodesDescription => 'Répertorier les épisodes connus du serveur mais sans fichier.';
	@override String get hidePlayedInLatest => 'Masquer les éléments vus dans « Récemment ajouté »';
	@override String get hidePlayedInLatestDescription => 'Exclure les éléments déjà vus des lignes « Récemment ajouté » du serveur.';
	@override String get displayCollectionsView => 'Afficher la vue Collections';
	@override String get displayCollectionsViewDescription => 'Proposer la vue Collections du serveur en plus de vos bibliothèques.';
	@override String get rewatchingInNextUp => 'Conserver les séries revues dans « À suivre »';
	@override String get rewatchingInNextUpDescription => 'Une fois une série terminée, si vous la recommencez, « À suivre » suit le revisionnage au lieu de la retirer.';
	@override String get watchedIndicator => 'Indicateurs de visionnage';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$fr watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$fr._(_root);
	@override String get mediaReviewsVisibility => 'Notes et critiques';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$fr mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$fr._(_root);
}

// Path: discover
class _Translations$discover$fr extends Translations$discover$en {
	_Translations$discover$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
		one: '${n} titre',
		other: '${n} titres',
	);
	@override late final _Translations$discover$person$fr person = _Translations$discover$person$fr._(_root);
}

// Path: errors
class _Translations$errors$fr extends Translations$errors$en {
	_Translations$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$libraries$fr extends Translations$libraries$en {
	_Translations$libraries$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
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
	@override late final _Translations$libraries$tabs$fr tabs = _Translations$libraries$tabs$fr._(_root);
	@override late final _Translations$libraries$groupings$fr groupings = _Translations$libraries$groupings$fr._(_root);
	@override late final _Translations$libraries$filterCategories$fr filterCategories = _Translations$libraries$filterCategories$fr._(_root);
	@override late final _Translations$libraries$sortLabels$fr sortLabels = _Translations$libraries$sortLabels$fr._(_root);
	@override late final _Translations$libraries$advancedFilters$fr advancedFilters = _Translations$libraries$advancedFilters$fr._(_root);
}

// Path: about
class _Translations$about$fr extends Translations$about$en {
	_Translations$about$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'À propos';
	@override String get openSourceLicenses => 'Licences libres';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Un magnifique client Plex, Jellyfin et Emby pour Flutter';
	@override String get viewLicensesDescription => 'Afficher les licences des bibliothèques tierces';
}

// Path: serverSelection
class _Translations$serverSelection$fr extends Translations$serverSelection$en {
	_Translations$serverSelection$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Aucun serveur trouvé pour ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Échec du chargement des serveurs : ${error}';
	@override String get noValidServers => 'Aucun serveur utilisable n’a été trouvé sur ce compte';
}

// Path: hubDetail
class _Translations$hubDetail$fr extends Translations$hubDetail$en {
	_Translations$hubDetail$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get releaseYear => 'Année de sortie';
	@override String get dateAdded => 'Date d\'ajout';
	@override String get rating => 'Évaluation';
	@override String get noItemsFound => 'Aucun élément trouvé';
}

// Path: logs
class _Translations$logs$fr extends Translations$logs$en {
	_Translations$logs$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Effacer les journaux';
	@override String get copyLogs => 'Copier les journaux';
	@override String get uploadLogs => 'Envoyer les journaux';
}

// Path: startup
class _Translations$startup$fr extends Translations$startup$en {
	_Translations$startup$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy n\'a pas pu démarrer';
	@override String get failedBody => 'Une erreur s\'est produite au démarrage. Les détails ci-dessous identifient la cause.';
	@override String get failedBodyRepairable => 'Le fichier de paramètres enregistré de Plezy est endommagé et doit être reconstruit avant que Plezy ne puisse démarrer. Réessayer ne servira à rien — choisissez Réparer le stockage.';
	@override String get phaseLabel => 'Étape';
	@override String get showDetails => 'Afficher les détails';
	@override String get hideDetails => 'Masquer les détails';
	@override String get copyDetails => 'Copier les détails';
	@override String get detailsCopied => 'Détails copiés dans le presse-papiers';
	@override String get uploadDetails => 'Téléverser les détails';
	@override String get repairStorage => 'Réparer le stockage';
	@override String get repairTitle => 'Réparer les données stockées ?';
	@override String get repairBodyCommon => 'Le fichier de paramètres de Plezy est endommagé et illisible. La réparation rétablit tous les paramètres par défaut.';
	@override String get repairBodyOneCredential => 'Une connexion enregistrée est endommagée et illisible. La réparation ne supprime que celle-ci ; vos autres paramètres sont laissés intacts.';
	@override String get repairBodySignInsKept => 'Vos serveurs et profils devraient rester connectés.';
	@override String get repairBodySignInsLost => 'La clé qui protège vos connexions enregistrées ne peut pas être récupérée à partir de ce fichier ; vous devrez donc vous reconnecter à chaque serveur et profil. Rien sur votre serveur multimédia n\'est affecté.';
	@override String get repairBodySessionsUncertain => 'Les trackers (MAL, AniList, Simkl, Trakt) et Seerr sont stockés séparément et peuvent ou non être conservés. Plezy vous indiquera exactement ce qu\'il a gardé.';
	@override String get repairConfirm => 'Réparer';
	@override String get repairSucceeded => 'Stockage réparé';
	@override String get repairNeedsRestart => 'Stockage réparé — redémarrage requis';
	@override String get restartRequiredBody => 'Vos données ont été réparées, mais Plezy doit redémarrer pour pouvoir les utiliser. Fermez Plezy puis rouvrez-le.';
	@override String get quitPlezy => 'Quitter Plezy';
	@override String get repairFailed => 'Échec de la réparation';
	@override String get repairKeptSignIns => 'Vos serveurs et profils sont toujours connectés.';
	@override String get repairLostSignIns => 'La clé qui protégeait vos connexions enregistrées n\'a pas pu être récupérée. Vous devrez vous reconnecter à chaque serveur et profil.';
	@override String get repairLostSessions => 'Au moins une connexion à un tracker ou à Seerr a été perdue et devra être rétablie.';
	@override String get backupTitle => 'Une copie du fichier endommagé a été conservée';
	@override String get backupWarning => 'Elle contient vos identifiants de connexion. Ne la téléversez pas et ne la partagez pas.';
	@override String get deleteBackup => 'Supprimer la copie';
	@override String get backupDeleted => 'Copie supprimée.';
	@override String get previousFailureTitle => 'Plezy n\'a pas réussi à démarrer la dernière fois';
}

// Path: licenses
class _Translations$licenses$fr extends Translations$licenses$en {
	_Translations$licenses$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Paquets associés';
	@override String get license => 'Licence';
	@override String licenseNumber({required Object number}) => 'Licence ${number}';
	@override String licensesCount({required Object count}) => '${count} licences';
}

// Path: navigation
class _Translations$navigation$fr extends Translations$navigation$en {
	_Translations$navigation$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliothèques';
	@override String get downloads => 'Téléchargements';
	@override String get liveTv => 'TV en direct';
	@override String get explore => 'Explorer';
}

// Path: explore
class _Translations$explore$fr extends Translations$explore$en {
	_Translations$explore$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Explorer';
	@override String get selectSource => 'Sélectionner la source';
	@override late final _Translations$explore$rows$fr rows = _Translations$explore$rows$fr._(_root);
	@override late final _Translations$explore$status$fr status = _Translations$explore$status$fr._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} épisode',
		other: '${n} épisodes',
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
		one: 'Impossible de vérifier ${n} serveur',
		other: 'Impossible de vérifier ${n} serveurs',
	);
	@override String get emptyTitle => 'Rien ici pour l\'instant';
	@override String emptyMessage({required Object source}) => 'Les lignes de ${source} apparaîtront ici dès qu’elles contiendront des éléments.';
	@override String searchHint({required Object source}) => 'Rechercher dans ${source}';
	@override String searchEmpty({required Object query}) => 'Aucun résultat pour "${query}"';
	@override String searchPrompt({required Object source}) => 'Recherchez des films et des séries sur ${source}.';
	@override String get searchFailed => 'Échec de la recherche. Vérifiez votre connexion et réessayez.';
	@override late final _Translations$explore$badge$fr badge = _Translations$explore$badge$fr._(_root);
	@override late final _Translations$explore$stats$fr stats = _Translations$explore$stats$fr._(_root);
	@override late final _Translations$explore$season$fr season = _Translations$explore$season$fr._(_root);
	@override late final _Translations$explore$format$fr format = _Translations$explore$format$fr._(_root);
	@override late final _Translations$explore$sourceMaterial$fr sourceMaterial = _Translations$explore$sourceMaterial$fr._(_root);
	@override late final _Translations$explore$creditRole$fr creditRole = _Translations$explore$creditRole$fr._(_root);
	@override late final _Translations$explore$relation$fr relation = _Translations$explore$relation$fr._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Diffusé le ${day} à ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Diffusé le ${day} à ${time} ${timezone}';
	@override late final _Translations$explore$detail$fr detail = _Translations$explore$detail$fr._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} résultat',
		other: '${n} résultats',
	);
}

// Path: liveTv
class _Translations$liveTv$fr extends Translations$liveTv$en {
	_Translations$liveTv$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get unknownHub => 'Inconnu';
	@override String get unknownError => 'Erreur inconnue';
	@override String channelNumber({required Object number}) => 'Chaîne ${number}';
	@override String get unknownChannel => 'Chaîne inconnue';
	@override String get live => 'EN DIRECT';
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
	@override late final _Translations$liveTv$recordSettings$fr recordSettings = _Translations$liveTv$recordSettings$fr._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Commence dans ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} à ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} a renvoyé des données de lecture de TV en direct non valides';
	@override String get failedToStartChannel => 'Impossible de lancer la chaîne en direct';
	@override String get failedToBuildStreamUrl => 'Impossible de générer l’URL du flux';
	@override String playbackStartFailed({required Object reason}) => 'Impossible de démarrer la chaîne : ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Impossible de changer de chaîne : ${reason}';
}

// Path: collections
class _Translations$collections$fr extends Translations$collections$en {
	_Translations$collections$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$playlists$fr extends Translations$playlists$en {
	_Translations$playlists$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String itemCount({required Object count}) => '${count} éléments';
	@override String get oneItem => '1 élément';
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
class _Translations$music$fr extends Translations$music$en {
	_Translations$music$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Aller à l\'album';
	@override String get goToArtist => 'Aller à l\'artiste';
	@override String get instantMix => 'Mix instantané';
	@override String get playNext => 'Lire ensuite';
	@override String get addToQueue => 'Ajouter à la file d\'attente';
	@override String discNumber({required Object n}) => 'Disque ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} titre',
		other: '${n} titres',
	);
	@override String get nowPlaying => 'Lecture en cours';
	@override String playingFrom({required Object title}) => 'Lecture depuis ${title}';
	@override String get queue => 'File d\'attente';
	@override String get clearQueue => 'Vider la file d\'attente';
	@override String get lyrics => 'Paroles';
	@override String get noLyrics => 'Aucune parole disponible';
	@override String get sleepTimer => 'Minuterie de veille';
	@override String get sleepTimerEndOfTrack => 'Fin du titre';
	@override String sleepTimerMinutes({required Object n}) => '${n} minutes';
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
	@override late final _Translations$music$discography$fr discography = _Translations$music$discography$fr._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$fr extends Translations$watchTogether$en {
	_Translations$watchTogether$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String inviteMessage({required Object code}) => 'Rejoignez mon salon Regarder ensemble dans Plezy : ouvrez « Regarder ensemble », choisissez « Rejoindre un salon » et saisissez ${code}.';
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
	@override String get unavailableDescription => 'Plezy ne l’a pas trouvée dans vos bibliothèques. Choisissez vous-même une copie ou relancez la recherche.';
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
		one: '${n} participant',
		other: '${n} participants',
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
	@override late final _Translations$watchTogether$notices$fr notices = _Translations$watchTogether$notices$fr._(_root);
	@override late final _Translations$watchTogether$ended$fr ended = _Translations$watchTogether$ended$fr._(_root);
	@override late final _Translations$watchTogether$errors$fr errors = _Translations$watchTogether$errors$fr._(_root);
	@override String untitledEpisode({required Object number}) => 'Épisode ${number}';
}

// Path: downloads
class _Translations$downloads$fr extends Translations$downloads$en {
	_Translations$downloads$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get activeSyncRules => 'Règles de synchronisation';
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
	@override late final _Translations$downloads$backgroundWarning$fr backgroundWarning = _Translations$downloads$backgroundWarning$fr._(_root);
	@override String get options => 'Options de téléchargement';
	@override late final _Translations$downloads$groupings$fr groupings = _Translations$downloads$groupings$fr._(_root);
	@override String get unknownLibrary => 'Bibliothèque inconnue';
	@override String get unknownShow => 'Série inconnue';
	@override String get unknownSeason => 'Saison inconnue';
	@override String get unknownAlbum => 'Album inconnu';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} terminés';
	@override String get errorFileNotFound => 'Fichier introuvable (404)';
	@override String get errorDownloadNotAllowed => 'Téléchargement non autorisé par le serveur (403)';
	@override String get errorDownloadFailed => 'Échec du téléchargement';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Échec du téléchargement : ${reason}';
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
class _Translations$shaders$fr extends Translations$shaders$en {
	_Translations$shaders$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$companionRemote$fr extends Translations$companionRemote$en {
	_Translations$companionRemote$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Télécommande compagnon';
	@override String connectedTo({required Object name}) => 'Connecté à ${name}';
	@override String get unknownDevice => 'Appareil inconnu';
	@override late final _Translations$companionRemote$session$fr session = _Translations$companionRemote$session$fr._(_root);
	@override late final _Translations$companionRemote$pairing$fr pairing = _Translations$companionRemote$pairing$fr._(_root);
	@override late final _Translations$companionRemote$remote$fr remote = _Translations$companionRemote$remote$fr._(_root);
	@override late final _Translations$companionRemote$errors$fr errors = _Translations$companionRemote$errors$fr._(_root);
	@override String get closedBeforeAuth => 'La connexion a été fermée avant l’authentification';
}

// Path: videoSettings
class _Translations$videoSettings$fr extends Translations$videoSettings$en {
	_Translations$videoSettings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get audioNormalization => 'Normaliser le volume';
	@override String get audioNormalizationDisablesPassthrough => 'Décode l’audio en PCM ; la transmission directe est désactivée tant que cette option est active';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$fr extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$externalPlayer$fr extends Translations$externalPlayer$en {
	_Translations$externalPlayer$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
}

// Path: metadataEdit
class _Translations$metadataEdit$fr extends Translations$metadataEdit$en {
	_Translations$metadataEdit$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$matchScreen$fr extends Translations$matchScreen$en {
	_Translations$matchScreen$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$serverTasks$fr extends Translations$serverTasks$en {
	_Translations$serverTasks$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tâches du serveur';
	@override String get failedToLoad => 'Échec du chargement des tâches';
	@override String get noTasks => 'Aucune tâche en cours';
}

// Path: trakt
class _Translations$trakt$fr extends Translations$trakt$en {
	_Translations$trakt$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Connecté';
	@override String connectedAs({required Object username}) => 'Connecté en tant que @${username}';
	@override String get disconnectConfirm => 'Déconnecter le compte Trakt ?';
	@override String get disconnectConfirmBody => 'Plezy cessera d’envoyer des événements à Trakt. Vous pourrez vous reconnecter à tout moment.';
	@override String get scrobble => 'Scrobbling en temps réel';
	@override String get scrobbleDescription => 'Envoyer les événements de lecture, pause et arrêt à Trakt pendant la lecture.';
	@override String get watchedSync => 'Synchroniser le statut « vu »';
	@override String get watchedSyncDescription => 'Lorsque vous marquez des éléments comme vus dans Plezy, ils sont également marqués comme vus sur Trakt.';
}

// Path: seerr
class _Translations$seerr$fr extends Translations$seerr$en {
	_Translations$seerr$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get noSignInMethods => 'Cette instance Seerr ne propose aucune méthode de connexion prise en charge par Plezy.';
	@override String get instance => 'Instance';
	@override String get disconnectConfirm => 'Déconnecter Seerr ?';
	@override String get disconnectConfirmBody => 'Plezy oubliera cette instance Seerr. Vous pourrez vous reconnecter à tout moment.';
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
	@override String get behindAuthProxy => 'Un proxy inverse avec authentification (SSO ou authentification HTTP) a répondu à la place de Seerr. Plezy ne peut pas se connecter à travers lui : laissez le chemin /api/v1 de Seerr contourner le proxy pour cette application, ou utilisez une adresse qui atteint Seerr directement.';
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
class _Translations$services$fr extends Translations$services$en {
	_Translations$services$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String disconnectConfirmBody({required Object service}) => 'Plezy cessera de mettre à jour ${service}. Vous pourrez vous reconnecter à tout moment.';
	@override String connectFailed({required Object service}) => 'Échec de la connexion à ${service}. Réessayez.';
	@override late final _Translations$services$names$fr names = _Translations$services$names$fr._(_root);
	@override late final _Translations$services$simklReconnect$fr simklReconnect = _Translations$services$simklReconnect$fr._(_root);
	@override late final _Translations$services$deviceCode$fr deviceCode = _Translations$services$deviceCode$fr._(_root);
	@override late final _Translations$services$oauthProxy$fr oauthProxy = _Translations$services$oauthProxy$fr._(_root);
	@override late final _Translations$services$pendingAuth$fr pendingAuth = _Translations$services$pendingAuth$fr._(_root);
	@override late final _Translations$services$libraryFilter$fr libraryFilter = _Translations$services$libraryFilter$fr._(_root);
}

// Path: addServer
class _Translations$addServer$fr extends Translations$addServer$en {
	_Translations$addServer$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
}

// Path: appIcon.names
class _Translations$appIcon$names$fr extends Translations$appIcon$names$en {
	_Translations$appIcon$names$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$common$ratingSource$fr extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Critiques';
	@override String get audience => 'Public';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Critiques Rotten Tomatoes';
	@override String get rottenTomatoesAudience => 'Public Rotten Tomatoes';
	@override String get metacritic => 'Metacritic';
	@override String get letterboxd => 'Letterboxd';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$fr extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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

// Path: supporter.errors
class _Translations$supporter$errors$fr extends Translations$supporter$errors$en {
	_Translations$supporter$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get storeUnavailable => 'Les achats ne sont pas disponibles. Vérifiez que vous êtes connecté à la boutique et que les achats sont autorisés sur cet appareil.';
	@override String get productNotFound => 'L’achat Supporter n’est pas disponible dans votre boutique pour le moment.';
	@override String get productQueryFailed => 'Impossible de charger le prix. Vérifiez votre connexion et réessayez.';
	@override String get purchaseFailed => 'L’achat n’a pas abouti. Réessayez.';
	@override String get restoreFailed => 'Impossible de joindre la boutique pour restaurer votre achat. Réessayez.';
	@override String get nothingToRestore => 'Aucun achat Supporter n’a été trouvé pour ce compte de la boutique.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$fr extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$themeEditor$contrast$fr extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$hotkeys$actions$fr extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get shaderToggle => 'Activer/désactiver les shaders';
	@override String get skipMarker => 'Passer l\'intro/le générique';
	@override String get screenshot => 'Prendre une capture d\'écran';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$fr extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$fr extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio et sous-titres';
	@override String get libraryDisplay => 'Bibliothèque';
	@override String get personalMedia => 'Médias personnels';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$fr extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$accountPreferences$subtitleAccessibilityOptions$fr extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Préférer les sous-titres non SDH';
	@override String get preferSdh => 'Préférer les sous-titres SDH';
	@override String get onlySdh => 'Sous-titres SDH uniquement';
	@override String get onlyNonSdh => 'Sous-titres non SDH uniquement';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$fr extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Préférer les sous-titres non forcés';
	@override String get preferForced => 'Préférer les sous-titres forcés';
	@override String get onlyForced => 'Sous-titres forcés uniquement';
	@override String get onlyNonForced => 'Sous-titres non forcés uniquement';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$fr extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Jamais';
	@override String get moviesAndShows => 'Films et séries TV';
	@override String get movies => 'Films uniquement';
	@override String get shows => 'Séries TV uniquement';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$fr extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Utilisateurs et critiques';
	@override String get usersOnly => 'Utilisateurs uniquement';
	@override String get criticsOnly => 'Critiques uniquement';
	@override String get nobody => 'Masquées';
}

// Path: discover.person
class _Translations$discover$person$fr extends Translations$discover$person$en {
	_Translations$discover$person$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get born => 'Naissance';
	@override String get died => 'Décès';
	@override String get birthplace => 'Lieu de naissance';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} ans)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (à ${age} ans)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$fr extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recommandé';
	@override String get browse => 'Parcourir';
	@override String get collections => 'Collections';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$fr extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$libraries$filterCategories$fr extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$libraries$sortLabels$fr extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$libraries$advancedFilters$fr extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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

// Path: explore.rows
class _Translations$explore$rows$fr extends Translations$explore$rows$en {
	_Translations$explore$rows$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$explore$status$fr extends Translations$explore$status$en {
	_Translations$explore$status$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get airing => 'En cours';
	@override String get ended => 'Terminé';
	@override String get canceled => 'Annulé';
	@override String get upcoming => 'À venir';
}

// Path: explore.badge
class _Translations$explore$badge$fr extends Translations$explore$badge$en {
	_Translations$explore$badge$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$explore$stats$fr extends Translations$explore$stats$en {
	_Translations$explore$stats$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
		one: '${n} commentaire',
		other: '${n} commentaires',
	);
	@override String votes({required Object n}) => '${n} votes';
	@override String watching({required Object n}) => '${n} le regardent';
	@override String completed({required Object n}) => '${n} l\'ont terminé';
	@override String onHold({required Object n}) => '${n} en pause';
	@override String dropped({required Object n}) => '${n} ont abandonné';
}

// Path: explore.season
class _Translations$explore$season$fr extends Translations$explore$season$en {
	_Translations$explore$season$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Hiver';
	@override String get spring => 'Printemps';
	@override String get summer => 'Été';
	@override String get fall => 'Automne';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$fr extends Translations$explore$format$en {
	_Translations$explore$format$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$explore$sourceMaterial$fr extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$explore$creditRole$fr extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$explore$relation$fr extends Translations$explore$relation$en {
	_Translations$explore$relation$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$explore$detail$fr extends Translations$explore$detail$en {
	_Translations$explore$detail$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
		one: 'Recommandé par ${n} utilisateur',
		other: 'Recommandé par ${n} utilisateurs',
	);
	@override String recommendedBy({required Object who}) => 'Recommandé par ${who}';
	@override String favoritedBy({required Object who}) => 'Ajouté aux favoris par ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} pas encore diffusés';
	@override String recommendedByPercent({required Object percent}) => 'Recommandé par ${percent} des spectateurs';
	@override String get relatedTitles => 'Titres liés';
	@override String get background => 'Contexte';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$fr extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$music$discography$fr extends Translations$music$discography$en {
	_Translations$music$discography$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles et EP';
	@override String get live => 'Live';
	@override String get compilations => 'Compilations';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$fr extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$watchTogether$ended$fr extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get ended => 'L’hôte a fermé le salon';
	@override String get kicked => 'Vous avez été retiré du salon';
	@override String get expired => 'Le salon a expiré';
	@override String get replaced => 'Vous avez rejoint ce salon sur un autre appareil';
	@override String get lost => 'Connexion au salon perdue';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$fr extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Ce n’est pas un code de salon. Les codes comportent 6 lettres et chiffres, sans 0, 1, I, L ni O.';
	@override String get roomNotFound => 'Aucun salon ne correspond à ce code. Il a peut-être été fermé.';
	@override String get roomFull => 'Ce salon est complet.';
	@override String get roomLocked => 'L’hôte a verrouillé ce salon.';
	@override String get relayFull => 'Le service Regarder ensemble est saturé pour le moment. Réessayez plus tard.';
	@override String get unreachable => 'Impossible de joindre le relais Regarder ensemble. Vérifiez votre connexion.';
	@override String get rateLimited => 'Trop de tentatives. Patientez un instant, puis réessayez.';
	@override String get clientBlocked => 'Cette version de Plezy ne peut pas utiliser le relais. Mettez l’application à jour.';
	@override String get forbidden => 'Seul l’hôte peut faire cela.';
	@override String get notInRoom => 'Vous n’êtes pas dans un salon.';
	@override String get alreadyInRoom => 'Vous êtes déjà dans un salon.';
	@override String get resumeFailed => 'Impossible de rejoindre à nouveau le salon.';
	@override String get unsupported => 'Le relais ne prend pas en charge cette fonction.';
	@override String get generic => 'Une erreur s’est produite. Réessayez.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$fr extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Les téléchargements s’arrêteront lorsque vous quitterez l’application';
	@override String get bannerDegraded => 'Les téléchargements en arrière-plan peuvent être limités';
	@override String get bannerAction => 'Détails';
	@override String get sheetTitle => 'Les téléchargements en arrière-plan sont bloqués';
	@override String get sheetTitleDegraded => 'Les téléchargements en arrière-plan peuvent être limités';
	@override String get sheetIntro => 'Android empêche Plezy de télécharger de façon fiable en arrière-plan.';
	@override String get sheetIntroDegraded => 'Votre appareil limite les moments où Plezy peut télécharger en arrière-plan.';
	@override String get reasonBackgroundRestricted => 'L’utilisation de Plezy en arrière-plan est restreinte. Dans les paramètres de batterie ou d’utilisation en arrière-plan, sélectionnez « Sans restriction ».';
	@override String get reasonStandbyRestricted => 'Android a placé Plezy en veille restreinte. Réglez l’utilisation de la batterie sur « Sans restriction ».';
	@override String get reasonDownloadChannelBlocked => 'Les notifications de téléchargement sont désactivées. La progression et les commandes peuvent donc être indisponibles.';
	@override String get reasonNotificationsDisabled => 'Les notifications sont désactivées. Sur Android 13 ou version ultérieure, elles sont nécessaires pour les longs téléchargements en arrière-plan.';
	@override String get reasonDataSaver => 'L’Économiseur de données est activé et bloque les téléchargements en arrière-plan via les données mobiles. Ils devraient toujours fonctionner en Wi-Fi.';
	@override String get reasonOemUnknown => 'Les téléchargements se sont arrêtés plusieurs fois lorsque Plezy était en arrière-plan. Vérifiez les paramètres de batterie ou d’utilisation en arrière-plan de Plezy.';
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
class _Translations$downloads$groupings$fr extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get library => 'Bibliothèque';
	@override String get collections => 'Collections';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$fr extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$companionRemote$pairing$fr extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Les appareils Plezy avec le même compte Plex apparaissent ici';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Connexion...';
	@override String get searchingForDevices => 'Recherche d\'appareils...';
	@override String get noDevicesFound => 'Aucun appareil trouvé sur votre réseau';
	@override String get noDevicesHint => 'Ouvrez Plezy sur votre ordinateur et utilisez le même réseau Wi-Fi';
	@override String get availableDevices => 'Appareils disponibles';
	@override String get manualConnection => 'Connexion manuelle';
	@override String get cryptoInitFailed => 'Impossible de démarrer la connexion sécurisée. Connectez-vous d\'abord à Plex.';
	@override String get validationHostRequired => 'Veuillez saisir l’adresse de l’hôte';
	@override String get validationHostFormat => 'Le format doit être IP:port (p. ex. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Délai de connexion dépassé. Utilisez le même réseau sur les deux appareils.';
	@override String get sessionNotFound => 'Appareil introuvable. Assurez-vous que Plezy fonctionne sur l\'hôte.';
	@override String get authFailed => 'Échec de l\'authentification. Les deux appareils doivent utiliser le même compte Plex.';
	@override String failedToConnect({required Object error}) => 'Échec de la connexion : ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$fr extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$companionRemote$errors$fr extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _Translations$services$names$fr extends Translations$services$names$en {
	_Translations$services$names$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$fr extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reconnecter Simkl';
	@override String get subtitle => 'Simkl va retirer la méthode de connexion utilisée par cette liaison. La reconnexion ouvre simkl.com pour autoriser Plezy — Plezy n’a jamais accès à votre mot de passe. Votre historique de visionnage reste sur Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$fr extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Activer Plezy sur ${service}';
	@override String get instructions => 'Scannez le code QR ou accédez à l’adresse ci-dessous et saisissez ce code :';
	@override String openToActivate({required Object service}) => 'Ouvrir ${service} pour activer';
	@override String get copyCode => 'Copier le code d\'activation';
	@override String get waitingForAuthorization => 'En attente d\'autorisation…';
	@override String get codeCopied => 'Code copié';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$fr extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Se connecter à ${service}';
	@override String get body => 'Scannez ce code QR ou ouvrez l\'URL sur n\'importe quel appareil.';
	@override String openToSignIn({required Object service}) => 'Ouvrir ${service} pour se connecter';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$fr extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Copier l\'URL de connexion';
	@override String get urlCopied => 'URL copiée';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$fr extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$fr._(TranslationsFr root) : this._root = root, super.internal(root);

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
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'appIcon.title' => 'Icône de l’application',
			'appIcon.defaultIcon' => 'Par défaut',
			'appIcon.current' => 'Icône actuelle',
			'appIcon.locked' => 'Avantage Supporter',
			'appIcon.lockedHint' => 'Les icônes alternatives sont un avantage Supporter.',
			'appIcon.changeFailed' => 'Impossible de changer l’icône de l’application',
			'appIcon.launcherHint' => 'La nouvelle icône apparaîtra sur votre écran d’accueil une fois que vous aurez quitté Plezy.',
			'appIcon.tvLauncherHint' => 'La nouvelle bannière apparaîtra une fois que vous aurez quitté Plezy. Android TV peut continuer à afficher l’ancienne jusqu’au redémarrage du téléviseur.',
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
			'auth.localDataRecoveryRequired' => 'Plezy n’a pas pu récupérer en toute sécurité les données locales de connexion et de lecture en attente. Veuillez vous reconnecter.',
			'auth.pinCheckRejected' => 'La vérification du code PIN Plex a été refusée',
			'common.cancel' => 'Annuler',
			'common.save' => 'Enregistrer',
			'common.close' => 'Fermer',
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
			'common.ratingSource.critic' => 'Critiques',
			'common.ratingSource.audience' => 'Public',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Critiques Rotten Tomatoes',
			'common.ratingSource.rottenTomatoesAudience' => 'Public Rotten Tomatoes',
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
			'supporter.title' => 'Plezy Supporter',
			'supporter.intro' => 'Un achat unique qui soutient le développement de Plezy et débloque des bonus esthétiques :',
			'supporter.presetThemes' => 'Thèmes prédéfinis',
			'supporter.presetThemesDescription' => 'Braise, Glacier, Forêt, Prune et Papier',
			'supporter.customTheme' => 'Thème personnalisé',
			'supporter.customThemeDescription' => 'Choisissez vous-même chaque couleur',
			'supporter.appIcons' => 'Icônes de l’application',
			'supporter.appIconsDescription' => 'Choisissez une autre icône Plezy',
			'supporter.buy' => ({required Object price}) => 'Acheter pour ${price}',
			'supporter.loadingPrice' => 'Chargement du prix...',
			'supporter.restore' => 'Restaurer les achats',
			'supporter.pending' => 'Votre achat est en attente de paiement ou d’approbation. Les bonus seront débloqués dès que la boutique l’aura finalisé.',
			'supporter.thankYouTitle' => 'Merci de soutenir Plezy',
			'supporter.thankYouBody' => 'Vos bonus Supporter sont débloqués.',
			'supporter.tileSubtitle' => 'Débloquez des thèmes et des icônes d’application grâce à un achat unique',
			'supporter.tileSubtitleThemesOnly' => 'Débloquez des thèmes grâce à un achat unique',
			'supporter.tileUnlocked' => 'Merci pour votre soutien',
			'supporter.errors.storeUnavailable' => 'Les achats ne sont pas disponibles. Vérifiez que vous êtes connecté à la boutique et que les achats sont autorisés sur cet appareil.',
			'supporter.errors.productNotFound' => 'L’achat Supporter n’est pas disponible dans votre boutique pour le moment.',
			'supporter.errors.productQueryFailed' => 'Impossible de charger le prix. Vérifiez votre connexion et réessayez.',
			'supporter.errors.purchaseFailed' => 'L’achat n’a pas abouti. Réessayez.',
			'supporter.errors.restoreFailed' => 'Impossible de joindre la boutique pour restaurer votre achat. Réessayez.',
			'supporter.errors.nothingToRestore' => 'Aucun achat Supporter n’a été trouvé pour ce compte de la boutique.',
			'settings.title' => 'Paramètres',
			'settings.supportDeveloper' => 'Soutenir Plezy',
			'settings.supportDeveloperDescription' => 'Faites un don via Liberapay pour financer le développement',
			'settings.language' => 'Langue',
			'settings.theme' => 'Thème',
			'settings.appearance' => 'Apparence',
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
			'settings.defaultQualityTitle' => 'Qualité par défaut',
			'settings.cellularQualityTitle' => 'Qualité par défaut sur les données mobiles',
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
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} secondes',
			'settings.defaultSleepTimer' => 'Minuterie de mise en veille par défaut',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutes',
			'settings.rememberTrackSelections' => 'Mémoriser les pistes choisies pour chaque série ou film',
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
			'settings.importSettingsInvalidFile' => 'Ce fichier n’est pas une exportation valide des paramètres de Plezy',
			'settings.importSettingsNoUser' => 'Connectez-vous avant d’importer les paramètres',
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
			'settings.skipMarkerModeOff' => 'Désactivé',
			'settings.skipMarkerModeButton' => 'Afficher le bouton',
			'settings.skipMarkerModeAuto' => 'Automatique',
			'settings.forceSkipMarkerFallback' => 'Forcer les marqueurs de secours',
			'settings.forceSkipMarkerFallbackDescription' => 'Utiliser les motifs des titres de chapitre même lorsque Plex fournit des marqueurs',
			'settings.autoSkipDelay' => 'Délai avant le saut automatique',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Attendre ${seconds} secondes avant le saut automatique',
			'settings.introPattern' => 'Motif du marqueur d’introduction',
			'settings.introPatternDescription' => 'Expression régulière permettant de reconnaître les marqueurs d’introduction dans les titres de chapitre',
			'settings.creditsPattern' => 'Motif du marqueur de générique',
			'settings.creditsPatternDescription' => 'Expression régulière permettant de reconnaître les marqueurs de générique dans les titres de chapitre',
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
			'settings.disableDolbyVision' => 'Désactiver Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Lire la couche HDR10 ou HLG du fichier au lieu de Dolby Vision, si elle existe',
			'settings.hdrSdrConversion' => 'Conversion HDR vers SDR',
			'settings.hdrSdrConversionDescription' => 'Choisir ce qui convertit les vidéos HDR lorsque l’écran ne peut pas afficher le HDR.',
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
			'settings.startInFullscreenDescription' => 'Ouvrir Plezy en mode plein écran au lancement',
			'settings.exitFullscreenOnPlayerClose' => 'Quitter le plein écran à la fermeture du lecteur',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Quitter automatiquement le plein écran lors de la fermeture du lecteur vidéo',
			'settings.autoHidePerformanceOverlay' => 'Masquer automatiquement les données de performance',
			'settings.autoHidePerformanceOverlayDescription' => 'Masquer progressivement les données de performance avec les commandes de lecture',
			'settings.showNavBarLabels' => 'Afficher les libellés de la barre de navigation',
			'settings.showNavBarLabelsDescription' => 'Afficher les libellés sous les icônes de la barre de navigation',
			'settings.startupSection' => 'Section de démarrage',
			'settings.showExploreTab' => 'Afficher l’onglet Explorer',
			'settings.showExploreTabDescription' => 'Afficher l’onglet Explorer avec le contenu de Plex Discover et des services de suivi connectés',
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
			'settings.exportDialogTitle' => 'Exporter les paramètres de Plezy',
			'themeEditor.builtIn' => 'Intégrés',
			'themeEditor.presets' => 'Prédéfinis',
			'themeEditor.custom' => 'Personnalisé',
			'themeEditor.customEmpty' => 'Pas encore créé',
			'themeEditor.editCustom' => 'Modifier le thème personnalisé',
			'themeEditor.editCustomDescription' => 'Choisissez vous-même chaque couleur',
			'themeEditor.locked' => 'Débloquer avec Supporter',
			'themeEditor.savedLocked' => 'Enregistré — se débloque avec Supporter',
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
			_ => null,
		} ?? switch (path) {
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
			'hotkeys.actions.shaderToggle' => 'Activer/désactiver les shaders',
			'hotkeys.actions.skipMarker' => 'Passer l\'intro/le générique',
			'hotkeys.actions.screenshot' => 'Prendre une capture d\'écran',
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Cela supprime ${n} épisode qu\'elle contient, ainsi que son fichier.', other: 'Cela supprime les ${n} épisodes qu\'elle contient, ainsi que leurs fichiers.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Cet élément est stocké sous forme de ${n} fichier, qui sera supprimé.', other: 'Cet élément est stocké sur ${n} fichiers, et ils seront tous supprimés.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} autre épisode est stocké dans le même fichier et sera également supprimé :', other: '${n} autres épisodes sont stockés dans le même fichier et seront également supprimés :', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy n\'a pas pu vérifier quels fichiers seront supprimés ; il risque donc d\'en supprimer plus que l\'élément nommé ci-dessus. Annulez et réessayez, ou supprimez quand même.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Votre serveur n\'a pas fourni les détails du fichier pour cet élément, Plezy ne peut donc pas vérifier quels fichiers seront supprimés. Il risque d\'en supprimer plus que l\'élément nommé ci-dessus.',
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
			'videoControls.lockScreen' => 'Verrouiller l\'écran',
			'videoControls.screenLockButton' => 'Verrouillage de l\'écran',
			'videoControls.longPressToUnlock' => 'Appui long pour déverrouiller',
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
			'messages.markedAsWatched' => 'Marqué comme vu',
			'messages.markedAsUnwatched' => 'Marqué comme non vu',
			'messages.markedAsWatchedOffline' => 'Marqué comme vu (se synchronisera lorsque vous serez en ligne)',
			'messages.markedAsUnwatchedOffline' => 'Marqué comme non vu (sera synchronisé lorsque vous serez en ligne)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Supprimé automatiquement : ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} téléchargement vu supprimé automatiquement', other: '${n} téléchargements vus supprimés automatiquement', ), 
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
			'mpvConfig.title' => 'Configuration mpv',
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
			'profiles.addPlezyProfile' => 'Ajouter un profil Plezy',
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
			'connections.sectionTitle' => 'Connexions',
			'connections.addConnection' => 'Ajouter une connexion',
			_ => null,
		} ?? switch (path) {
			'connections.addConnectionSubtitleNoProfile' => 'Connectez-vous avec Plex ou connectez un serveur Jellyfin ou Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Ajouter à ${displayName} : Plex, Jellyfin, Emby ou une autre connexion de profil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Session expirée pour ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Session expirée pour ${count} serveurs',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} a refusé l\'accès à ce compte',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} serveurs ont refusé l\'accès à ce compte',
			'connections.signInAgain' => 'Se reconnecter',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Modifier la connexion ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Ajoutez ou retirez des URL pour ${serverName}. Plezy utilisera l\'URL joignable avec la latence la plus faible.',
			'accountPreferences.sectionTitle' => 'Préférences du compte',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Options audio, sous-titres et bibliothèque enregistrées sur ${count} comptes',
			'accountPreferences.pickAccount' => 'Chaque compte enregistre ses propres préférences. Choisissez celui à modifier.',
			'accountPreferences.storedOnAccount' => 'Ces options sont enregistrées sur le compte lui-même : toutes les applications connectées les utilisent, y compris Plezy sur vos autres appareils.',
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
			'accountPreferences.forcedSubtitles' => 'Sous-titres forcés',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Préférer les sous-titres non forcés',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Préférer les sous-titres forcés',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Sous-titres forcés uniquement',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Sous-titres non forcés uniquement',
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
			'accountPreferences.mediaReviewsVisibility' => 'Notes et critiques',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Utilisateurs et critiques',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Utilisateurs uniquement',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Critiques uniquement',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Masquées',
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
			'discover.extras' => 'Bandes-annonces et bonus',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Évaluation',
			'discover.director' => 'Réalisateur',
			'discover.directors' => 'Réalisateurs',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Série TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'discover.moreLikeThis' => 'Plus de contenus similaires',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} titre', other: '${n} titres', ), 
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
			'about.title' => 'À propos',
			'about.openSourceLicenses' => 'Licences libres',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'Un magnifique client Plex, Jellyfin et Emby pour Flutter',
			'about.viewLicensesDescription' => 'Afficher les licences des bibliothèques tierces',
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
			'startup.failedTitle' => 'Plezy n\'a pas pu démarrer',
			'startup.failedBody' => 'Une erreur s\'est produite au démarrage. Les détails ci-dessous identifient la cause.',
			'startup.failedBodyRepairable' => 'Le fichier de paramètres enregistré de Plezy est endommagé et doit être reconstruit avant que Plezy ne puisse démarrer. Réessayer ne servira à rien — choisissez Réparer le stockage.',
			'startup.phaseLabel' => 'Étape',
			'startup.showDetails' => 'Afficher les détails',
			'startup.hideDetails' => 'Masquer les détails',
			'startup.copyDetails' => 'Copier les détails',
			'startup.detailsCopied' => 'Détails copiés dans le presse-papiers',
			'startup.uploadDetails' => 'Téléverser les détails',
			'startup.repairStorage' => 'Réparer le stockage',
			'startup.repairTitle' => 'Réparer les données stockées ?',
			'startup.repairBodyCommon' => 'Le fichier de paramètres de Plezy est endommagé et illisible. La réparation rétablit tous les paramètres par défaut.',
			'startup.repairBodyOneCredential' => 'Une connexion enregistrée est endommagée et illisible. La réparation ne supprime que celle-ci ; vos autres paramètres sont laissés intacts.',
			'startup.repairBodySignInsKept' => 'Vos serveurs et profils devraient rester connectés.',
			'startup.repairBodySignInsLost' => 'La clé qui protège vos connexions enregistrées ne peut pas être récupérée à partir de ce fichier ; vous devrez donc vous reconnecter à chaque serveur et profil. Rien sur votre serveur multimédia n\'est affecté.',
			'startup.repairBodySessionsUncertain' => 'Les trackers (MAL, AniList, Simkl, Trakt) et Seerr sont stockés séparément et peuvent ou non être conservés. Plezy vous indiquera exactement ce qu\'il a gardé.',
			'startup.repairConfirm' => 'Réparer',
			'startup.repairSucceeded' => 'Stockage réparé',
			'startup.repairNeedsRestart' => 'Stockage réparé — redémarrage requis',
			'startup.restartRequiredBody' => 'Vos données ont été réparées, mais Plezy doit redémarrer pour pouvoir les utiliser. Fermez Plezy puis rouvrez-le.',
			'startup.quitPlezy' => 'Quitter Plezy',
			'startup.repairFailed' => 'Échec de la réparation',
			'startup.repairKeptSignIns' => 'Vos serveurs et profils sont toujours connectés.',
			'startup.repairLostSignIns' => 'La clé qui protégeait vos connexions enregistrées n\'a pas pu être récupérée. Vous devrez vous reconnecter à chaque serveur et profil.',
			'startup.repairLostSessions' => 'Au moins une connexion à un tracker ou à Seerr a été perdue et devra être rétablie.',
			'startup.backupTitle' => 'Une copie du fichier endommagé a été conservée',
			'startup.backupWarning' => 'Elle contient vos identifiants de connexion. Ne la téléversez pas et ne la partagez pas.',
			'startup.deleteBackup' => 'Supprimer la copie',
			'startup.backupDeleted' => 'Copie supprimée.',
			'startup.previousFailureTitle' => 'Plezy n\'a pas réussi à démarrer la dernière fois',
			'licenses.relatedPackages' => 'Paquets associés',
			'licenses.license' => 'Licence',
			'licenses.licenseNumber' => ({required Object number}) => 'Licence ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licences',
			'navigation.libraries' => 'Bibliothèques',
			'navigation.downloads' => 'Téléchargements',
			'navigation.liveTv' => 'TV en direct',
			'navigation.explore' => 'Explorer',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} épisode', other: '${n} épisodes', ), 
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
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Impossible de vérifier ${n} serveur', other: 'Impossible de vérifier ${n} serveurs', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} commentaire', other: '${n} commentaires', ), 
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Recommandé par ${n} utilisateur', other: 'Recommandé par ${n} utilisateurs', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recommandé par ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Ajouté aux favoris par ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} pas encore diffusés',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recommandé par ${percent} des spectateurs',
			'explore.detail.relatedTitles' => 'Titres liés',
			'explore.detail.background' => 'Contexte',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} résultat', other: '${n} résultats', ), 
			'liveTv.title' => 'TV en direct',
			'liveTv.guide' => 'Guide',
			'liveTv.noChannels' => 'Aucune chaîne disponible',
			'liveTv.noDvr' => 'Aucun DVR configuré sur les serveurs',
			'liveTv.serverUnavailable' => 'Le serveur de TV en direct n’est pas disponible.',
			'liveTv.serverNotConnected' => 'Le serveur de TV en direct n’est pas connecté.',
			'liveTv.noPrograms' => 'Aucune donnée de programme disponible',
			'liveTv.liveStreamFailed' => 'Échec du direct',
			'liveTv.unknownProgram' => 'Programme inconnu',
			'liveTv.unknownHub' => 'Inconnu',
			'liveTv.unknownError' => 'Erreur inconnue',
			'liveTv.channelNumber' => ({required Object number}) => 'Chaîne ${number}',
			'liveTv.unknownChannel' => 'Chaîne inconnue',
			'liveTv.live' => 'EN DIRECT',
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
			_ => null,
		} ?? switch (path) {
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
			'playlists.itemCount' => ({required Object count}) => '${count} éléments',
			'playlists.oneItem' => '1 élément',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} titre', other: '${n} titres', ), 
			'music.nowPlaying' => 'Lecture en cours',
			'music.playingFrom' => ({required Object title}) => 'Lecture depuis ${title}',
			'music.queue' => 'File d\'attente',
			'music.clearQueue' => 'Vider la file d\'attente',
			'music.lyrics' => 'Paroles',
			'music.noLyrics' => 'Aucune parole disponible',
			'music.sleepTimer' => 'Minuterie de veille',
			'music.sleepTimerEndOfTrack' => 'Fin du titre',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minutes',
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
			'watchTogether.inviteMessage' => ({required Object code}) => 'Rejoignez mon salon Regarder ensemble dans Plezy : ouvrez « Regarder ensemble », choisissez « Rejoindre un salon » et saisissez ${code}.',
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
			'watchTogether.unavailableDescription' => 'Plezy ne l’a pas trouvée dans vos bibliothèques. Choisissez vous-même une copie ou relancez la recherche.',
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
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} participant', other: '${n} participants', ), 
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
			'watchTogether.errors.clientBlocked' => 'Cette version de Plezy ne peut pas utiliser le relais. Mettez l’application à jour.',
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
			'downloads.activeSyncRules' => 'Règles de synchronisation',
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
			'downloads.backgroundWarning.sheetIntro' => 'Android empêche Plezy de télécharger de façon fiable en arrière-plan.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Votre appareil limite les moments où Plezy peut télécharger en arrière-plan.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'L’utilisation de Plezy en arrière-plan est restreinte. Dans les paramètres de batterie ou d’utilisation en arrière-plan, sélectionnez « Sans restriction ».',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android a placé Plezy en veille restreinte. Réglez l’utilisation de la batterie sur « Sans restriction ».',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Les notifications de téléchargement sont désactivées. La progression et les commandes peuvent donc être indisponibles.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Les notifications sont désactivées. Sur Android 13 ou version ultérieure, elles sont nécessaires pour les longs téléchargements en arrière-plan.',
			'downloads.backgroundWarning.reasonDataSaver' => 'L’Économiseur de données est activé et bloque les téléchargements en arrière-plan via les données mobiles. Ils devraient toujours fonctionner en Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Les téléchargements se sont arrêtés plusieurs fois lorsque Plezy était en arrière-plan. Vérifiez les paramètres de batterie ou d’utilisation en arrière-plan de Plezy.',
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
			'downloads.errorFileNotFound' => 'Fichier introuvable (404)',
			'downloads.errorDownloadNotAllowed' => 'Téléchargement non autorisé par le serveur (403)',
			'downloads.errorDownloadFailed' => 'Échec du téléchargement',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Échec du téléchargement : ${reason}',
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
			'companionRemote.pairing.discoveryDescription' => 'Les appareils Plezy avec le même compte Plex apparaissent ici',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Connexion...',
			'companionRemote.pairing.searchingForDevices' => 'Recherche d\'appareils...',
			'companionRemote.pairing.noDevicesFound' => 'Aucun appareil trouvé sur votre réseau',
			'companionRemote.pairing.noDevicesHint' => 'Ouvrez Plezy sur votre ordinateur et utilisez le même réseau Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Appareils disponibles',
			'companionRemote.pairing.manualConnection' => 'Connexion manuelle',
			'companionRemote.pairing.cryptoInitFailed' => 'Impossible de démarrer la connexion sécurisée. Connectez-vous d\'abord à Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Veuillez saisir l’adresse de l’hôte',
			'companionRemote.pairing.validationHostFormat' => 'Le format doit être IP:port (p. ex. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Délai de connexion dépassé. Utilisez le même réseau sur les deux appareils.',
			'companionRemote.pairing.sessionNotFound' => 'Appareil introuvable. Assurez-vous que Plezy fonctionne sur l\'hôte.',
			'companionRemote.pairing.authFailed' => 'Échec de l\'authentification. Les deux appareils doivent utiliser le même compte Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Échec de la connexion : ${error}',
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
			'videoSettings.audioNormalization' => 'Normaliser le volume',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Décode l’audio en PCM ; la transmission directe est désactivée tant que cette option est active',
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
			_ => null,
		} ?? switch (path) {
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
			'trakt.disconnectConfirmBody' => 'Plezy cessera d’envoyer des événements à Trakt. Vous pourrez vous reconnecter à tout moment.',
			'trakt.scrobble' => 'Scrobbling en temps réel',
			'trakt.scrobbleDescription' => 'Envoyer les événements de lecture, pause et arrêt à Trakt pendant la lecture.',
			'trakt.watchedSync' => 'Synchroniser le statut « vu »',
			'trakt.watchedSyncDescription' => 'Lorsque vous marquez des éléments comme vus dans Plezy, ils sont également marqués comme vus sur Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Se connecter à Seerr',
			'seerr.serverUrl' => 'URL du serveur',
			'seerr.serverUrlHelper' => 'L\'adresse de votre instance Seerr',
			'seerr.checkServer' => 'Continuer',
			'seerr.signInWithJellyfin' => 'Se connecter avec Jellyfin',
			'seerr.signInWithEmby' => 'Se connecter avec Emby',
			'seerr.signInWithLocal' => 'Utiliser un compte local',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Cette instance Seerr ne propose aucune méthode de connexion prise en charge par Plezy.',
			'seerr.instance' => 'Instance',
			'seerr.disconnectConfirm' => 'Déconnecter Seerr ?',
			'seerr.disconnectConfirmBody' => 'Plezy oubliera cette instance Seerr. Vous pourrez vous reconnecter à tout moment.',
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
			'seerr.behindAuthProxy' => 'Un proxy inverse avec authentification (SSO ou authentification HTTP) a répondu à la place de Seerr. Plezy ne peut pas se connecter à travers lui : laissez le chemin /api/v1 de Seerr contourner le proxy pour cette application, ou utilisez une adresse qui atteint Seerr directement.',
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
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy cessera de mettre à jour ${service}. Vous pourrez vous reconnecter à tout moment.',
			'services.connectFailed' => ({required Object service}) => 'Échec de la connexion à ${service}. Réessayez.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Reconnecter Simkl',
			'services.simklReconnect.subtitle' => 'Simkl va retirer la méthode de connexion utilisée par cette liaison. La reconnexion ouvre simkl.com pour autoriser Plezy — Plezy n’a jamais accès à votre mot de passe. Votre historique de visionnage reste sur Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Activer Plezy sur ${service}',
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
			_ => null,
		};
	}
}
